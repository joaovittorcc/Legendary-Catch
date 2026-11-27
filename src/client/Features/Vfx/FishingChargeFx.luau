--!strict
--[[
	FishingChargeFx.luau
	Suggested Studio path: StarterPlayer/StarterPlayerScripts/Client/Features/Vfx/FishingChargeFx
	Rojo path: src/client/Features/Vfx/FishingChargeFx.luau

	Integration:
	- Client-only VFX for the cast-charging phase and release burst.
	- Hook into your Fishing client controller:
	    * When player begins holding cast:  FishingChargeFx.begin(rodTipOrHand?, skinTier)
	    * Every frame while holding:        FishingChargeFx.update(charge01, skinTier)
	    * When player releases to cast:     FishingChargeFx.release(charge01, skinTier, targetPos?)
	    * If cast is cancelled/interrupted: FishingChargeFx.cancel()
	- Assumption: If `anchor` is omitted in `begin()`, the module looks for an Attachment
	  named "RodTip" / "Tip" inside the equipped Tool, falling back to RightHand / Right Arm / HumanoidRootPart.
	- Respects ReduceEffects live via VfxKit, uses zero extra dynamic lights outside VfxKit's cap,
	  and runs a single Heartbeat ONLY while charging.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StringsUi = require(Shared:WaitForChild("StringsUi"))
local VfxFolder = Shared:WaitForChild("Vfx")
local Palette = require(VfxFolder:WaitForChild("Palette"))
local SfxKit = require(VfxFolder:WaitForChild("SfxKit"))
local VfxKit = require(VfxFolder:WaitForChild("VfxKit"))

export type AnchorTarget = BasePart | Attachment

local FishingChargeFx = {
	order = 125,
}

-- ============================================================================
-- CONSTANTS & STATE
-- ============================================================================

local RING_SEGMENTS = 10
local ORBIT_MOTIF_COUNT = 4
local PERFECT_THRESHOLD = 0.90
local PERFECT_RESET_THRESHOLD = 0.84 -- Hysteresis prevents ding spam near the boundary
local PERFECT_FLASH_COOLDOWN = 0.45

local started = false
local isCharging = false
local currentCharge = 0
local currentTier = 1
local enteredPerfect = false
local lastPerfectDingAt = 0
local elapsed = 0

local anchorTarget: AnchorTarget? = nil
local rodBasePart: BasePart? = nil

-- Reusable rig instances (created lazily, hidden when idle, destroyed on destroy())
local rigFolder: Folder? = nil
local emitterHost: Part? = nil
local sparkEmitter: ParticleEmitter? = nil
local spiralEmitter: ParticleEmitter? = nil
local auraBillboard: BillboardGui? = nil
local auraFrame: Frame? = nil
local ringSegments: { Part } = {}
local motifParts: { Part } = {}
local rodBeamStart: Part? = nil
local rodBeamEnd: Part? = nil
local rodBeam: Beam? = nil

local chargeLoopSound: Sound? = nil
local heartbeatConn: RBXScriptConnection? = nil
local reduceHandle: VfxKit.StopHandle? = nil

-- ============================================================================
-- HELPERS
-- ============================================================================

local function resolveAnchorPosition(): Vector3?
	if anchorTarget then
		if anchorTarget:IsA("Attachment") and anchorTarget.Parent then
			return anchorTarget.WorldPosition
		elseif anchorTarget:IsA("BasePart") and anchorTarget.Parent then
			return anchorTarget.Position
		end
	end

	local lp = Players.LocalPlayer
	local char = if lp then lp.Character else nil
	if not char then
		return nil
	end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		local tipAtt = tool:FindFirstChild("RodTip", true) or tool:FindFirstChild("Tip", true)
		if tipAtt and tipAtt:IsA("Attachment") then
			anchorTarget = tipAtt
			local handle = tool:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				rodBasePart = handle
			end
			return tipAtt.WorldPosition
		end
		local handle = tool:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			anchorTarget = handle
			rodBasePart = handle
			return handle.Position + handle.CFrame.UpVector * 2.5
		end
	end

	local hand = char:FindFirstChild("RightHand")
		or char:FindFirstChild("Right Arm")
		or char:FindFirstChild("HumanoidRootPart")
	if hand and hand:IsA("BasePart") then
		anchorTarget = hand
		rodBasePart = hand
		return hand.Position
	end

	return nil
end

local function resolveRodBasePosition(tipPos: Vector3): Vector3
	if rodBasePart and rodBasePart.Parent then
		return rodBasePart.Position
	end
	local lp = Players.LocalPlayer
	local char = if lp then lp.Character else nil
	if char then
		local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
		if hand and hand:IsA("BasePart") then
			return hand.Position
		end
	end
	return tipPos - Vector3.new(0, 2.2, 0)
end

local function textureForMotif(motif: string): string
	local t = VfxKit.TEXTURES
	if motif == "star" then
		return t.sparkles
	elseif motif == "rune" then
		return t.sparkles
	elseif motif == "feather" or motif == "crystal" then
		return t.softGlow
	end
	return t.sparkles
end

local function ensureRig()
	if rigFolder and rigFolder.Parent then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "_LegendaryCatch_ChargeFxRig"

	-- Central invisible anchor part carrying emitters + fake bloom aura
	local host = Instance.new("Part")
	host.Name = "ChargeEmitterHost"
	host.Anchored = true
	host.CanCollide = false
	host.CanTouch = false
	host.CanQuery = false
	host.CastShadow = false
	host.Transparency = 1
	host.Size = Vector3.new(0.25, 0.25, 0.25)
	host.CFrame = CFrame.new(0, -5000, 0)

	local sp = Instance.new("ParticleEmitter")
	sp.Name = "ChargeSparks"
	sp.Enabled = false
	sp.Rate = 0
	sp.Texture = VfxKit.TEXTURES.sparkles
	sp.LightEmission = 1
	sp.LightInfluence = 0
	sp.Drag = 3
	sp.Lifetime = NumberRange.new(0.3, 0.6)
	sp.Speed = NumberRange.new(2, 6)
	sp.SpreadAngle = Vector2.new(180, 180)
	sp.RotSpeed = NumberRange.new(-150, 150)
	sp.Parent = host

	local spiral = Instance.new("ParticleEmitter")
	spiral.Name = "ChargeSpiral"
	spiral.Enabled = false
	spiral.Rate = 0
	spiral.Texture = VfxKit.TEXTURES.softGlow
	spiral.LightEmission = 1
	spiral.LightInfluence = 0
	spiral.Drag = 1.6
	spiral.Acceleration = Vector3.new(0, 5.5, 0)
	spiral.Lifetime = NumberRange.new(0.45, 0.85)
	spiral.Speed = NumberRange.new(1.5, 4.5)
	spiral.SpreadAngle = Vector2.new(35, 35)
	spiral.EmissionDirection = Enum.NormalId.Top
	spiral.Parent = host

	local bGui = Instance.new("BillboardGui")
	bGui.Name = "ChargeAuraGlow"
	bGui.Enabled = false
	bGui.AlwaysOnTop = false
	bGui.LightInfluence = 0
	bGui.Size = UDim2.fromScale(2.5, 2.5)
	bGui.Adornee = host

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 0.65
	frame.BorderSizePixel = 0
	frame.Parent = bGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	bGui.Parent = host
	host.Parent = folder

	-- Spinning charge ring segments (shown at >= 25% charge)
	table.clear(ringSegments)
	for i = 1, RING_SEGMENTS do
		local seg = Instance.new("Part")
		seg.Name = "ChargeRingSeg_" .. tostring(i)
		seg.Anchored = true
		seg.CanCollide = false
		seg.CanTouch = false
		seg.CanQuery = false
		seg.CastShadow = false
		seg.Material = Enum.Material.Neon
		seg.Transparency = 1
		seg.Size = Vector3.new(0.1, 0.1, 0.4)
		seg.CFrame = CFrame.new(0, -5000, 0)
		seg.Parent = folder
		table.insert(ringSegments, seg)
	end

	-- Orbiting tier motif accents (stars / crystals / feathers / runes for tiers 3..6)
	table.clear(motifParts)
	for i = 1, ORBIT_MOTIF_COUNT do
		local mp = Instance.new("Part")
		mp.Name = "ChargeMotif_" .. tostring(i)
		mp.Anchored = true
		mp.CanCollide = false
		mp.CanTouch = false
		mp.CanQuery = false
		mp.CastShadow = false
		mp.Material = Enum.Material.Neon
		mp.Transparency = 1
		mp.Size = Vector3.new(0.25, 0.25, 0.25)
		mp.CFrame = CFrame.new(0, -5000, 0)
		mp.Parent = folder
		table.insert(motifParts, mp)
	end

	-- Rod light trail beam (active at >= 60% charge)
	local bStart = Instance.new("Part")
	bStart.Name = "RodBeamStart"
	bStart.Anchored = true
	bStart.CanCollide = false
	bStart.CanTouch = false
	bStart.CanQuery = false
	bStart.CastShadow = false
	bStart.Transparency = 1
	bStart.Size = Vector3.new(0.2, 0.2, 0.2)
	bStart.CFrame = CFrame.new(0, -5000, 0)

	local bEnd = bStart:Clone()
	bEnd.Name = "RodBeamEnd"

	local att0 = Instance.new("Attachment")
	att0.Parent = bStart
	local att1 = Instance.new("Attachment")
	att1.Parent = bEnd

	local beam = Instance.new("Beam")
	beam.Name = "RodChargeBeam"
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Enabled = false
	beam.Width0 = 0.14
	beam.Width1 = 0.42
	beam.Parent = bStart

	bStart.Parent = folder
	bEnd.Parent = folder
	folder.Parent = Workspace

	rigFolder = folder
	emitterHost = host
	sparkEmitter = sp
	spiralEmitter = spiral
	auraBillboard = bGui
	auraFrame = frame
	rodBeamStart = bStart
	rodBeamEnd = bEnd
	rodBeam = beam
end

local function hideRig()
	if sparkEmitter then
		sparkEmitter.Enabled = false
		sparkEmitter.Rate = 0
	end
	if spiralEmitter then
		spiralEmitter.Enabled = false
		spiralEmitter.Rate = 0
	end
	if auraBillboard then
		auraBillboard.Enabled = false
	end
	if rodBeam then
		rodBeam.Enabled = false
	end
	for _, seg in ipairs(ringSegments) do
		seg.Transparency = 1
		seg.CFrame = CFrame.new(0, -5000, 0)
	end
	for _, mp in ipairs(motifParts) do
		mp.Transparency = 1
		mp.CFrame = CFrame.new(0, -5000, 0)
	end
	if emitterHost then
		emitterHost.CFrame = CFrame.new(0, -5000, 0)
	end
end

local function stopChargeLoopSound()
	if chargeLoopSound then
		SfxKit.stopSound(chargeLoopSound)
		chargeLoopSound = nil
	end
end

local function stopHeartbeat()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
end

local function applyMotifGeometry(
	mp: Part,
	motif: string,
	scale: number,
	baseCf: CFrame,
	t: number,
	idx: number
)
	if motif == "crystal" then
		mp.Shape = Enum.PartType.Block
		mp.Size = Vector3.new(0.22, 0.58, 0.22) * scale
		mp.CFrame = baseCf * CFrame.Angles(math.rad(35), t * 2.5 + idx, math.rad(45))
	elseif motif == "feather" then
		mp.Shape = Enum.PartType.Block
		mp.Size = Vector3.new(0.14, 0.55, 0.34) * scale
		mp.CFrame = baseCf * CFrame.Angles(math.sin(t * 3 + idx) * 0.4, t * 1.8 + idx, math.rad(22))
	elseif motif == "rune" then
		mp.Shape = Enum.PartType.Block
		mp.Size = Vector3.new(0.42, 0.42, 0.08) * scale
		mp.CFrame = baseCf * CFrame.Angles(0, t * 2.2 + idx * 1.5, math.rad(45))
	else
		-- "star" / "ring" / "spark"
		mp.Shape = Enum.PartType.Ball
		mp.Size = Vector3.new(0.28, 0.28, 0.28) * scale
		mp.CFrame = baseCf
	end
end

local function triggerPerfectEntry(pos: Vector3, tier: number)
	local now = os.clock()
	if (now - lastPerfectDingAt) < PERFECT_FLASH_COOLDOWN then
		return
	end
	lastPerfectDingAt = now

	local tierTheme = Palette.getChargeTier(tier)
	SfxKit.play("charge_perfect_ding", { pitch = 1.0 + (tier - 1) * 0.03 })

	-- Rainbow/gold pop burst on the hand/rod tip
	VfxKit.burst(pos, "stars", 0.85, math.clamp(tier, 1, 5), tierTheme.perfectAccent)
	VfxKit.ring(pos, Palette.ChargeBands.PerfectGold, 2.8, 0.38, 0.9, math.clamp(tier, 1, 5))
	if not VfxKit.isReducedEffects() then
		VfxKit.burst(pos, "sparks", 0.6, math.clamp(tier, 1, 5), Palette.rainbowAt(elapsed * 0.8))
	end
end

local function stepCharge(dt: number)
	if not isCharging then
		stopHeartbeat()
		return
	end

	elapsed += dt
	local pos = resolveAnchorPosition()
	if not pos then
		hideRig()
		return
	end

	local reduced = VfxKit.isReducedEffects()
	local charge = currentCharge
	local tier = currentTier
	local tierTheme = Palette.getChargeTier(tier)
	local band = Palette.bandForCharge(charge)

	-- Compute vivid color (rainbow-gold shimmer when in Perfect band!)
	local primaryColor: Color3
	local secondaryColor: Color3
	if band == "Perfect" then
		local rainbow = Palette.rainbowAt(elapsed * 1.6)
		primaryColor = Palette.ChargeBands.PerfectGold:Lerp(rainbow, 0.45)
		secondaryColor = tierTheme.perfectAccent
	else
		primaryColor = Palette.colorForCharge(charge, tier)
		secondaryColor = primaryColor:Lerp(Color3.new(1, 1, 1), 0.45)
	end

	-- Fire Perfect ding + pop once per entry into the perfect zone
	if charge >= PERFECT_THRESHOLD and not enteredPerfect then
		enteredPerfect = true
		triggerPerfectEntry(pos, tier)
	elseif charge < PERFECT_RESET_THRESHOLD then
		enteredPerfect = false
	end

	-- Position emitter host
	if emitterHost then
		emitterHost.CFrame = CFrame.new(pos)
	end

	-- 1) Sparks emitter (0..100%, grows gently with charge while respecting mobile budget)
	if sparkEmitter then
		local maxRate = if reduced then 6 else 18
		local rate = if charge <= 0.02 then 0 else math.floor(3 + (charge ^ 1.3) * (maxRate - 3))
		sparkEmitter.Enabled = rate > 0
		sparkEmitter.Rate = rate
		sparkEmitter.Texture = textureForMotif(tierTheme.motif)
		sparkEmitter.Color = Palette.toColorSequence(primaryColor, secondaryColor)
		local sz = 0.22 + charge * 0.34
		sparkEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, sz),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkEmitter.Speed = NumberRange.new(1.5 + charge * 3.0, 3.5 + charge * 6.5)
	end

	-- 2) Spiral rising particles + spinning hand ring (active >= 25%)
	local showRing = charge >= 0.25
	if spiralEmitter then
		if showRing and not reduced then
			local spiralRate = math.floor(4 + ((charge - 0.25) / 0.75) * 12)
			spiralEmitter.Enabled = true
			spiralEmitter.Rate = spiralRate
			spiralEmitter.Color = Palette.toColorSequence(primaryColor, tierTheme.accent)
			spiralEmitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.18 + charge * 0.24),
				NumberSequenceKeypoint.new(1, 0),
			})
		else
			spiralEmitter.Enabled = false
			spiralEmitter.Rate = 0
		end
	end

	if showRing then
		local ringAlpha = math.clamp((charge - 0.25) / 0.75, 0, 1)
		local ringR = 0.75
			+ ringAlpha * 0.95
			+ (if band == "Perfect" then math.sin(elapsed * 16) * 0.12 else 0)
		local spinSpeed = 2.4 + ringAlpha * 4.8
		local segLen = 2 * ringR * math.tan(math.pi / RING_SEGMENTS) * 1.12
		local thick = 0.06 + ringAlpha * 0.09
		local ringTrans = if reduced then 0.55 else (0.38 - ringAlpha * 0.28)
		local tilt = CFrame.Angles(
			math.sin(elapsed * 2.1) * 0.25,
			elapsed * spinSpeed,
			math.cos(elapsed * 1.7) * 0.25
		)

		for i, seg in ipairs(ringSegments) do
			local ang = (i / RING_SEGMENTS) * math.pi * 2
			local localOff = Vector3.new(math.cos(ang) * ringR, 0, math.sin(ang) * ringR)
			local tangent = Vector3.new(-math.sin(ang), 0, math.cos(ang))
			local localCf = CFrame.lookAt(localOff, localOff + tangent)
			seg.Color = if band == "Perfect"
				then Palette.rainbowAt(elapsed * 1.4 + i / RING_SEGMENTS)
				else primaryColor
			seg.Size = Vector3.new(thick, thick, segLen)
			seg.Transparency = math.clamp(ringTrans, 0.05, 0.9)
			seg.CFrame = CFrame.new(pos) * tilt * localCf
		end
	else
		for _, seg in ipairs(ringSegments) do
			seg.Transparency = 1
		end
	end

	-- 3) Tier 3..6 orbiting geometric motifs (richer silhouettes without extra particles!)
	local showMotifs = tier >= 3 and charge >= 0.35 and not reduced
	if showMotifs then
		local motifCount = math.min(ORBIT_MOTIF_COUNT, tier - 1)
		local orbitR = 1.2 + charge * 0.7
		local scale = 0.7 + charge * 0.55
		for i, mp in ipairs(motifParts) do
			if i <= motifCount then
				local ang = elapsed * (2.2 + tier * 0.25) + (i / motifCount) * math.pi * 2
				local bob = math.sin(elapsed * 4.0 + i * 1.3) * 0.35
				local mPos = pos + Vector3.new(math.cos(ang) * orbitR, bob, math.sin(ang) * orbitR)
				mp.Color = if band == "Perfect" then tierTheme.perfectAccent else tierTheme.accent
				mp.Transparency = 0.15
				applyMotifGeometry(mp, tierTheme.motif, scale, CFrame.new(mPos), elapsed, i)
			else
				mp.Transparency = 1
			end
		end
	else
		for _, mp in ipairs(motifParts) do
			mp.Transparency = 1
		end
	end

	-- 4) Rod light trail & fake aura bloom (>= 60% charge)
	local showHighCharge = charge >= 0.60
	if rodBeam and rodBeamStart and rodBeamEnd then
		if showHighCharge and not reduced then
			local basePos = resolveRodBasePosition(pos)
			rodBeamStart.CFrame = CFrame.new(basePos)
			rodBeamEnd.CFrame = CFrame.new(pos)
			rodBeam.Enabled = true
			rodBeam.Color =
				Palette.toColorSequence(tierTheme.accent, primaryColor, Color3.new(1, 1, 1))
			local highT = (charge - 0.60) / 0.40
			rodBeam.Width0 = 0.12 + highT * 0.18
			rodBeam.Width1 = 0.32 + highT * 0.38
			rodBeam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.7),
				NumberSequenceKeypoint.new(0.5, 0.25 - highT * 0.15),
				NumberSequenceKeypoint.new(1, 0.05),
			})
		else
			rodBeam.Enabled = false
		end
	end

	if auraBillboard and auraFrame then
		if showHighCharge then
			local highT = (charge - 0.60) / 0.40
			local pulse = if band == "Perfect" then (1 + math.sin(elapsed * 14) * 0.16) else 1
			local sz = (2.0 + highT * 2.2) * pulse * (if reduced then 0.65 else 1.0)
			auraBillboard.Enabled = true
			auraBillboard.Size = UDim2.fromScale(sz, sz)
			auraFrame.BackgroundColor3 = primaryColor
			auraFrame.BackgroundTransparency = if reduced then 0.72 else (0.62 - highT * 0.28)
		else
			auraBillboard.Enabled = false
		end
	end

	-- 5) Charge pitch escalation audio (>= 60% audible ramp, silent safely if ID == 0)
	if charge >= 0.15 then
		if not chargeLoopSound then
			chargeLoopSound = SfxKit.play("charge_loop", {
				looped = true,
				volume = 0.25,
				pitch = 0.85,
				pitchJitter = 0,
				cooldown = 0,
			})
		end
		if chargeLoopSound then
			chargeLoopSound.PlaybackSpeed = 0.8 + charge * 0.75
			chargeLoopSound.Volume = 0.2 + charge * 0.45
		end
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function FishingChargeFx.start()
	if started then
		return
	end
	started = true
	VfxKit.init()
	SfxKit.init()
	reduceHandle = VfxKit.onReduceEffectsChanged(function(isReduced: boolean)
		if isReduced and rodBeam then
			rodBeam.Enabled = false
		end
	end)
end

function FishingChargeFx.begin(anchor: AnchorTarget?, tier: number?)
	FishingChargeFx.start()
	ensureRig()

	anchorTarget = anchor
	rodBasePart = if anchor and anchor:IsA("BasePart") then anchor else nil
	currentCharge = 0
	currentTier = math.clamp(math.floor((tier or 1) + 0.5), 1, 6)
	enteredPerfect = false
	elapsed = 0
	isCharging = true

	if not heartbeatConn then
		heartbeatConn = RunService.Heartbeat:Connect(stepCharge)
	end
end

function FishingChargeFx.update(charge: number, tier: number?)
	if not isCharging then
		FishingChargeFx.begin(anchorTarget, tier)
	end
	currentCharge = math.clamp(charge, 0, 1)
	if tier ~= nil then
		currentTier = math.clamp(math.floor(tier + 0.5), 1, 6)
	end
end

-- Release cast: launch burst proportional to power + whoosh + launch light trail
function FishingChargeFx.release(charge: number?, tier: number?, targetPosition: Vector3?)
	local finalCharge = math.clamp(if charge ~= nil then charge else currentCharge, 0, 1)
	local finalTier = math.clamp(math.floor((tier or currentTier) + 0.5), 1, 6)
	local pos = resolveAnchorPosition()

	isCharging = false
	stopHeartbeat()
	stopChargeLoopSound()
	hideRig()

	if not pos then
		return
	end

	local band = Palette.bandForCharge(finalCharge)
	local vfxTier = math.clamp(math.ceil(finalTier * 0.85), 1, 5)
	local releaseColor = Palette.colorForCharge(finalCharge, finalTier)

	-- Whoosh scaled in pitch/volume by charge power
	SfxKit.play("cast_whoosh", {
		volume = 0.45 + finalCharge * 0.45,
		pitch = 0.9 + finalCharge * 0.32,
	})

	-- Launch burst
	local preset: VfxKit.BurstPreset = if band == "Perfect" then "stars" else "sparks"
	VfxKit.burst(pos, preset, 0.35 + finalCharge * 0.65, vfxTier, releaseColor)
	VfxKit.ring(pos, releaseColor, 1.8 + finalCharge * 3.0, 0.38, 0.4 + finalCharge * 0.6, vfxTier)

	if band == "Perfect" then
		VfxKit.floatingText(
			pos + Vector3.new(0, 1.8, 0),
			StringsUi.perfect,
			Palette.ChargeBands.PerfectGold,
			0.9,
			0.95
		)
		VfxKit.acquireLight(pos, Palette.ChargeBands.PerfectGold, 1.6, 16, 0.35)
		VfxKit.cameraShake(0.16, 0.14)
	end

	-- Launch light trail along initial cast vector
	local trailEnd: Vector3
	if targetPosition then
		trailEnd = pos:Lerp(targetPosition, 0.45) + Vector3.new(0, 2.5, 0)
	else
		local lp = Players.LocalPlayer
		local hrp = if lp and lp.Character
			then lp.Character:FindFirstChild("HumanoidRootPart")
			else nil
		local forward = if hrp and hrp:IsA("BasePart")
			then hrp.CFrame.LookVector
			else Vector3.new(0, 0, -1)
		trailEnd = pos + forward * (6 + finalCharge * 10) + Vector3.new(0, 2.5, 0)
	end
	VfxKit.sparkTrail(pos, trailEnd, releaseColor, 0.35, 0.45 + finalCharge * 0.55, vfxTier)
end

function FishingChargeFx.cancel()
	isCharging = false
	currentCharge = 0
	enteredPerfect = false
	stopHeartbeat()
	stopChargeLoopSound()
	hideRig()
end

function FishingChargeFx.destroy()
	FishingChargeFx.cancel()
	if reduceHandle then
		reduceHandle.stop()
		reduceHandle = nil
	end
	if rigFolder then
		rigFolder:Destroy()
		rigFolder = nil
	end
	emitterHost = nil
	sparkEmitter = nil
	spiralEmitter = nil
	auraBillboard = nil
	auraFrame = nil
	rodBeamStart = nil
	rodBeamEnd = nil
	rodBeam = nil
	table.clear(ringSegments)
	table.clear(motifParts)
	started = false
end

return FishingChargeFx
