--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local CreatureAura = require(script.Parent:WaitForChild("CreatureAura"))

-- A segmented creature part (named by the convention below) and how it moves.
type Limb = {
	part: BasePart,
	kind: string,
	rest: CFrame, -- part CFrame in model-pivot space at bind time
	joint: Vector3, -- hinge point in model-pivot space (edge of the part facing the body)
	side: number, -- +1 / -1 for left/right pairs, so they flap in opposition
}

export type Motion = {
	model: Model,
	static: boolean,
	center: Vector3,
	amplitude: number,
	tempo: number,
	neon: { { part: BasePart, color: Color3 } },
	limbs: { Limb },
	spineBones: { Bone },
	orbitCore: Bone?,
}

-- Part names produced by the segmentation pass (docs/NOITE.md, "Pedido do João ~12:10").
-- Each entry: function(phase) -> rotation around the hinge, in pivot space.
-- Claude, 2026-11-17: limb animation added on top of the whole-body motion.
local LIMB_MOTION: { [string]: (phase: number, side: number) -> CFrame } = {
	Tail = function(phase)
		return CFrame.Angles(0, math.sin(phase * 2) * 0.38, 0)
	end,
	FinL = function(phase, side)
		return CFrame.Angles(0, 0, math.sin(phase * 2.4) * 0.42 * side)
	end,
	FinR = function(phase, side)
		return CFrame.Angles(0, 0, math.sin(phase * 2.4) * 0.42 * side)
	end,
	Fins = function(phase)
		return CFrame.Angles(math.sin(phase * 2.2) * 0.18, 0, math.sin(phase * 2.2) * 0.22)
	end,
	Wings = function(phase)
		return CFrame.Angles(math.sin(phase * 1.6) * 0.2, 0, 0)
	end,
	Tentacles = function(phase)
		return CFrame.Angles(math.sin(phase * 1.3) * 0.22, math.sin(phase * 0.9) * 0.12, 0)
	end,
	Head = function(phase)
		return CFrame.Angles(math.sin(phase * 0.8) * 0.1, math.sin(phase * 0.5) * 0.12, 0)
	end,
	Legs = function(phase)
		return CFrame.Angles(math.sin(phase * 2.6) * 0.3, 0, 0)
	end,
	Claws = function(phase)
		return CFrame.Angles(math.max(0, math.sin(phase * 1.8)) * 0.32, 0, 0)
	end,
	Shell = function(phase)
		return CFrame.Angles(math.sin(phase * 0.7) * 0.045, 0, math.sin(phase * 0.5) * 0.03)
	end,
	Extra = function(phase)
		return CFrame.Angles(math.sin(phase * 1.3) * 0.07, 0, math.sin(phase * 1.0) * 0.05)
	end,
}

local PRIMARY_LIMBS: { [string]: boolean } = {
	Tail = true,
	FinL = true,
	FinR = true,
	Fins = true,
	Wings = true,
	Tentacles = true,
	Head = true,
	Legs = true,
	Claws = true,
	Shell = true,
}

-- Closest distance from a world point to a BasePart's oriented bounding box (0 if inside).
local function surfaceDistance(host: BasePart, worldPos: Vector3): number
	local localPos = host.CFrame:PointToObjectSpace(worldPos)
	local half = host.Size * 0.5
	local clamped = Vector3.new(
		math.clamp(localPos.X, -half.X, half.X),
		math.clamp(localPos.Y, -half.Y, half.Y),
		math.clamp(localPos.Z, -half.Z, half.Z)
	)
	return (localPos - clamped).Magnitude
end

local function computeHinge(pivot: CFrame, part: BasePart, hostCenter: Vector3): Vector3
	local rest = pivot:ToObjectSpace(part.CFrame)
	local toHost = hostCenter - rest.Position
	local dist = toHost.Magnitude
	if dist <= 0.01 then
		return rest.Position
	end
	local dir = toHost / dist
	local localDir = rest:VectorToObjectSpace(dir)
	local halfExtent = 0.5
		* (
			math.abs(localDir.X) * part.Size.X
			+ math.abs(localDir.Y) * part.Size.Y
			+ math.abs(localDir.Z) * part.Size.Z
		)
	local reach = math.min(dist, math.max(halfExtent * 0.85, 0.05))
	return rest.Position + dir * reach
end

local TEMPO: { [string]: number } = {
	bubbles = 0.92,
	splash = 1.15,
	spark = 1.2,
	prism = 0.9,
	storm = 1.35,
	crystal = 0.77,
	cosmic = 0.62,
	magma = 0.83,
	cloud = 0.57,
	frost = 0.72,
}

local CreatureMotion = {}

function CreatureMotion.bind(model: Model, style: string?): Motion
	local box, size = model:GetBoundingBox()
	local neon = {}
	for _, item in model:GetDescendants() do
		if #neon >= 8 then
			break
		end
		if
			item:IsA("BasePart")
			and item.Material == Enum.Material.Neon
			and item.Transparency < 0.95
		then
			table.insert(neon, { part = item, color = item.Color })
		end
	end
	-- Segmented parts: find the hinge of each limb along the part's surface facing its host,
	-- so it rotates from where it attaches instead of swinging off-center or clipping.
	local pivot = model:GetPivot()
	local bodyInst = model:FindFirstChild("Body")
	local body = if bodyInst and bodyInst:IsA("BasePart") then bodyInst else nil
	local headInst = model:FindFirstChild("Head")
	local head = if headInst and headInst:IsA("BasePart") then headInst else nil
	local bodyCenter = if body
		then pivot:PointToObjectSpace(body.Position)
		else pivot:PointToObjectSpace(box.Position)

	local limbs: { Limb } = {}
	local extras: { BasePart } = {}
	for _, item in model:GetChildren() do
		if item:IsA("BasePart") then
			if PRIMARY_LIMBS[item.Name] then
				local hostCenter = bodyCenter
				if item.Name == "Claws" and body and head then
					if
						(item.Position - head.Position).Magnitude
						< (item.Position - body.Position).Magnitude
					then
						hostCenter = pivot:PointToObjectSpace(head.Position)
					end
				end
				table.insert(limbs, {
					part = item,
					kind = item.Name,
					rest = pivot:ToObjectSpace(item.CFrame),
					joint = computeHinge(pivot, item, hostCenter),
					side = if item.Name == "FinR" then -1 else 1,
				})
			elseif item.Name == "Extra" then
				table.insert(extras, item)
			end
		end
	end

	-- Extra parts (eyes, wing crystals, crowns, ribbons): if attached to an animated limb
	-- (closer to that limb than to Body), inherit that limb's exact hinge + motion so eyes
	-- and accents never detach from Head/Wings/Tail/Shell. Large Body ornaments sway gently.
	local primaryCount = #limbs
	for _, item in extras do
		local bodyDist = if body then surfaceDistance(body, item.Position) else math.huge
		local bestLimb: Limb? = nil
		local bestDist = math.huge
		local bestCenterDist = math.huge
		for i = 1, primaryCount do
			local limb = limbs[i]
			local sd = surfaceDistance(limb.part, item.Position)
			local cd = (limb.part.Position - item.Position).Magnitude
			if
				sd < bestDist - 0.01 or (math.abs(sd - bestDist) <= 0.01 and cd < bestCenterDist)
			then
				bestDist = sd
				bestCenterDist = cd
				bestLimb = limb
			end
		end
		local maxDim = math.max(item.Size.X, item.Size.Y, item.Size.Z)
		if
			bestLimb
			and bestDist <= 1.0
			and (bestDist + 0.04 < bodyDist or (bestDist <= 0.02 and maxDim <= 0.35))
		then
			table.insert(limbs, {
				part = item,
				kind = bestLimb.kind,
				rest = pivot:ToObjectSpace(item.CFrame),
				joint = bestLimb.joint,
				side = bestLimb.side,
			})
		elseif
			maxDim > 0.28
			and (pivot:PointToObjectSpace(item.Position) - bodyCenter).Magnitude > 0.35
		then
			table.insert(limbs, {
				part = item,
				kind = "Extra",
				rest = pivot:ToObjectSpace(item.CFrame),
				joint = computeHinge(pivot, item, bodyCenter),
				side = 1,
			})
		end
	end

	local spineBones: { Bone } = {}
	for index = 1, 18 do
		local boneInst = model:FindFirstChild(string.format("Spine%02d", index), true)
		if boneInst and boneInst:IsA("Bone") then
			table.insert(spineBones, boneInst)
		end
	end
	local orbitInst = model:FindFirstChild("OrbitCore", true)
	local orbitCore = if orbitInst and orbitInst:IsA("Bone") then orbitInst else nil

	-- Only Mystic creatures animate (C94 stays intentionally static); all Common..Legendary
	-- creatures remain rigid while still allowing gentle turntable rotation when showTurn is true.
	local cfg = Creatures.get(model.Name)
	local isAnimated = cfg ~= nil and cfg.rarity == "Mystic" and model.Name ~= "C94_Mare_Primordial"

	-- Epic/Legendary aura (skips ViewportFrames by itself). Deferred so callers can parent
	-- the model right after binding.
	task.defer(CreatureAura.attach, model)
	return {
		model = model,
		static = not isAnimated,
		center = pivot:PointToObjectSpace(box.Position),
		amplitude = math.clamp(math.max(size.X, size.Y, size.Z) * 0.075, 0.12, 0.55),
		tempo = TEMPO[style or ""] or 1,
		neon = neon,
		limbs = if isAnimated then limbs else {},
		spineBones = if isAnimated then spineBones else {},
		orbitCore = if isAnimated then orbitCore else nil,
	}
end

local SWIM_CYCLE = 8.0

local function poseSkinnedRig(motion: Motion, elapsed: number)
	local count = #motion.spineBones
	if count == 0 and not motion.orbitCore then
		return
	end
	local cyclePhase = (elapsed % SWIM_CYCLE) / SWIM_CYCLE
	local uncoil = math.sin(cyclePhase * math.pi) ^ 2
	local wave = elapsed * math.pi * 2 * 0.55
	for index, bone in motion.spineBones do
		if index == 1 then
			bone.Transform = CFrame.Angles(
				math.sin(wave) * (0.07 + 0.09 * uncoil),
				math.cos(wave * 0.5) * 0.05,
				math.sin(wave * 0.5) * 0.05 - uncoil * 0.14
			)
		else
			local t = (index - 1) / math.max(count - 1, 1)
			local travel = wave - index * 0.42
			local lateral = math.sin(travel) * (0.045 + 0.085 * uncoil) * (0.35 + 0.65 * t)
			local twist = math.cos(travel) * 0.022 * uncoil
			local uncoilCurl = uncoil * 0.115 * (1 - 0.35 * t)
				+ math.sin(wave - index * 0.36) * (0.022 + 0.045 * uncoil)
			bone.Transform = CFrame.Angles(lateral, twist, uncoilCurl)
		end
	end
	local core = motion.orbitCore
	if core then
		core.Transform = CFrame.new(0, math.sin(wave) * 0.055, 0)
			* CFrame.Angles(elapsed * 0.65, elapsed * 1.25, math.sin(elapsed * 0.9) * 0.22)
	end
end

function CreatureMotion.poseBones(motion: Motion, elapsed: number)
	if not motion.static then
		poseSkinnedRig(motion, elapsed)
	end
end

-- Moves each segmented limb around its hinge (call after the model is pivoted).
local function poseLimbs(motion: Motion, phase: number)
	if #motion.limbs == 0 then
		return
	end
	local pivot = motion.model:GetPivot()
	for _, limb in motion.limbs do
		local rotate = LIMB_MOTION[limb.kind](phase, limb.side)
		local hinge = CFrame.new(limb.joint)
		limb.part.CFrame = pivot * hinge * rotate * hinge:Inverse() * limb.rest
	end
end

function CreatureMotion.reset(motion: Motion, base: CFrame)
	motion.model:PivotTo(base)
	local pivot = motion.model:GetPivot()
	for _, limb in motion.limbs do
		limb.part.CFrame = pivot * limb.rest
	end
	for _, bone in motion.spineBones do
		bone.Transform = CFrame.identity
	end
	if motion.orbitCore then
		motion.orbitCore.Transform = CFrame.identity
	end
	for _, item in motion.neon do
		item.part.Color = item.color
	end
end

function CreatureMotion.pose(motion: Motion, base: CFrame, elapsed: number, showTurn: boolean)
	if motion.static then
		if showTurn then
			local center = CFrame.new(motion.center)
			motion.model:PivotTo(
				base * center * CFrame.Angles(0, elapsed * 0.66, 0) * center:Inverse()
			)
		else
			motion.model:PivotTo(base)
		end
		return
	end
	local phase = elapsed * math.pi * 2 * motion.tempo
	local sway = math.sin(phase * 0.55)
	local wave = math.sin(phase)
	local offset = Vector3.new(sway * motion.amplitude * 0.35, wave * motion.amplitude, 0)
	local turn = if showTurn then elapsed * 0.66 else sway * 0.15
	local rotation = CFrame.Angles(wave * 0.065, turn, sway * 0.09)
	local center = CFrame.new(motion.center)
	motion.model:PivotTo(CFrame.new(offset) * base * center * rotation * center:Inverse())
	poseLimbs(motion, phase)
	poseSkinnedRig(motion, elapsed)
	local glow = 0.15 + math.sin(phase * 0.42) * 0.11
	for _, item in motion.neon do
		item.part.Color = item.color:Lerp(Color3.new(1, 1, 1), glow)
	end
end

return CreatureMotion
