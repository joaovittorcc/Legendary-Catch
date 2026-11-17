--!strict

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
	center: Vector3,
	amplitude: number,
	tempo: number,
	neon: { { part: BasePart, color: Color3 } },
	limbs: { Limb },
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
		return CFrame.Angles(math.sin(phase * 1.6) * 0.28, 0, 0)
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
		return CFrame.Angles(math.max(0, math.sin(phase * 1.8)) * 0.35, 0, 0)
	end,
}

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
	-- Segmented parts: find the hinge of each limb (the point of the part closest to the
	-- body), so it rotates from where it attaches instead of spinning around its center.
	local pivot = model:GetPivot()
	local body = model:FindFirstChild("Body")
	local bodyCenter = if body and body:IsA("BasePart")
		then pivot:PointToObjectSpace(body.Position)
		else pivot:PointToObjectSpace(box.Position)
	local limbs: { Limb } = {}
	for _, item in model:GetChildren() do
		if item:IsA("BasePart") and LIMB_MOTION[item.Name] then
			local rest = pivot:ToObjectSpace(item.CFrame)
			local toBody = bodyCenter - rest.Position
			local reach = math.max(item.Size.X, item.Size.Y, item.Size.Z) * 0.4
			local joint = if toBody.Magnitude > 0.01
				then rest.Position + toBody.Unit * math.min(reach, toBody.Magnitude)
				else rest.Position
			table.insert(limbs, {
				part = item,
				kind = item.Name,
				rest = rest,
				joint = joint,
				side = if item.Name == "FinR" then -1 else 1,
			})
		end
	end
	-- Epic/Legendary aura (skips ViewportFrames by itself). Deferred so callers can parent
	-- the model right after binding.
	task.defer(CreatureAura.attach, model)
	return {
		model = model,
		center = pivot:PointToObjectSpace(box.Position),
		amplitude = math.clamp(math.max(size.X, size.Y, size.Z) * 0.075, 0.12, 0.55),
		tempo = TEMPO[style or ""] or 1,
		neon = neon,
		limbs = limbs,
	}
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
	for _, item in motion.neon do
		item.part.Color = item.color
	end
end

function CreatureMotion.pose(motion: Motion, base: CFrame, elapsed: number, showTurn: boolean)
	local phase = elapsed * math.pi * 2 * motion.tempo
	local sway = math.sin(phase * 0.55)
	local wave = math.sin(phase)
	local offset = Vector3.new(sway * motion.amplitude * 0.35, wave * motion.amplitude, 0)
	local turn = if showTurn then elapsed * 0.66 else sway * 0.15
	local rotation = CFrame.Angles(wave * 0.065, turn, sway * 0.09)
	local center = CFrame.new(motion.center)
	motion.model:PivotTo(CFrame.new(offset) * base * center * rotation * center:Inverse())
	poseLimbs(motion, phase)
	local glow = 0.15 + math.sin(phase * 0.42) * 0.11
	for _, item in motion.neon do
		item.part.Color = item.color:Lerp(Color3.new(1, 1, 1), glow)
	end
end

return CreatureMotion
