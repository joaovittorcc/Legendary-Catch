--!strict
-- PondAnimator.luau
-- Client-side ambient and reactive animations for the Legendary Catch training island ponds.
-- Place at: src/client/Features/PondAnimator.luau

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TRAINING_ISLANDS_NAME = "TrainingIslands"
local TRAINING_SPOT_TAG = "TrainingSpot"
local ACTIVE_RADIUS = 160
local TRAIN_SPOT_RADIUS = 16
local RESCAN_INTERVAL = 1.5
local AWAKEN_DURATION = 1.5
local COMBO_PULSE_DURATION = 1.25
local MAX_BULK_PARTS_PER_POND = 440

local TWO_PI = math.pi * 2

-- ============================================================================
-- Types
-- ============================================================================

type PartOrig = {
	cframe: CFrame,
	size: Vector3,
	transparency: number,
	color: Color3,
}

type BeamOrig = {
	width0: number,
	width1: number,
	brightness: number,
}

type LightOrig = {
	brightness: number,
	range: number,
}

type EmitterOrig = {
	rate: number,
	enabled: boolean,
}

type PartRel = {
	part: BasePart,
	relCF: CFrame,
	orig: PartOrig,
}

type RingGroup = {
	coreModel: Model,
	haloModel: Model?,
	centerCF: CFrame,
	ringIndex: number,
	baseY: number,
	parts: { PartRel },
	isRipple: boolean,
}

type FishSubPart = {
	part: BasePart,
	relCF: CFrame,
	hingeLocal: Vector3,
	kind: string, -- "TailL" | "TailR" | "FinL" | "FinR" | "Body"
}

type OrbitCreature = {
	model: Model,
	primary: BasePart,
	origCF: CFrame,
	orbitRadius: number,
	orbitSpeed: number,
	orbitPhase: number,
	baseY: number,
	isJellyfish: boolean,
	forwardFixCF: CFrame,
	parts: { FishSubPart },
	tentacles: { PartRel },
	trailEmitter: ParticleEmitter?,
}

type BuoyData = {
	model: Model,
	centerCF: CFrame,
	buoyIndex: number,
	parts: { PartRel },
	ripples: { BasePart },
}

type SwayGroup = {
	pivotCF: CFrame,
	phase: number,
	parts: { PartRel },
}

type ClamData = {
	hingeCF: CFrame,
	lidParts: { PartRel },
	pearlParts: { PartRel },
	pearlCenterCF: CFrame,
	glowParts: { BasePart },
	lights: { PointLight },
}

type CrystalPillarData = {
	model: Instance,
	centerCF: CFrame,
	phase: number,
	parts: { PartRel },
	beams: { Beam },
	emitters: { ParticleEmitter },
	lights: { PointLight },
}

type ConstellationData = {
	nodes: { BasePart },
	halos: { BasePart },
	lines: { BasePart },
}

type ShootingStarPool = {
	part: BasePart,
	active: boolean,
	elapsed: number,
	duration: number,
	startPos: Vector3,
	endPos: Vector3,
	nextTriggerTime: number,
}

type JumpState = {
	active: boolean,
	creatureIndex: number,
	elapsed: number,
	duration: number,
	nextTriggerTime: number,
	splashedOut: boolean,
	splashedIn: boolean,
}

type ComboRingPool = {
	part: BasePart,
	origSize: Vector3,
	emitter: ParticleEmitter,
}

type PondProfile = {
	islandName: string,
	islandIndex: number,
	pondName: string,
	statName: string,
	scan: (state: PondState) -> (),
	update: (
		state: PondState,
		t: number,
		dt: number,
		frame: number,
		partsOut: { BasePart },
		cframesOut: { CFrame }
	) -> (),
}

type PondState = {
	key: string,
	profile: PondProfile,
	model: Model,
	waterSurface: BasePart?,
	centerPos: Vector3,
	waterY: number,
	radiusX: number,
	radiusZ: number,

	-- Runtime animation state
	active: boolean,
	awake: number,
	animTime: number,
	comboPulse: number,
	dirty: boolean,
	lastScanTime: number,

	-- Pooled / created client-only effects (max 6 emitters per pond)
	createdInstances: { Instance },
	createdEmitters: { ParticleEmitter },
	comboRing: ComboRingPool?,
	splashRing: BasePart?,
	splashEmitter: ParticleEmitter?,
	splashTimer: number,
	shootingStar: ShootingStarPool?,
	jumpState: JumpState,

	-- Profile-populated caches (rebuilt safely on scan)
	rings: { RingGroup },
	creatures: { OrbitCreature },
	buoys: { BuoyData },
	hexCells: { BasePart },
	pillars: { CrystalPillarData },
	verticalBeams: { Beam },
	existingEmitters: { ParticleEmitter },
	stars: { BasePart },
	petals: { BasePart },
	runes: { BasePart },
	swayGroups: { SwayGroup },
	lanterns: { SwayGroup },
	targetShells: { BasePart },
	clam: ClamData?,
	constellation: ConstellationData?,
	mirrorGlow: BasePart?,
	deckCrystals: { CrystalPillarData },
	spiralArms: { PartRel },
	galaxyCoreParts: { BasePart },
	galaxyStars: { BasePart },
	canopyCrystals: { BasePart },
	fireflyParts: { BasePart },
	fireflyEmitters: { ParticleEmitter },
	pondLights: { PointLight },
	rippleParts: { BasePart },
	causticParts: { BasePart },

	-- Reusable per-frame buffers
	partsBuf: { BasePart },
	cframesBuf: { CFrame },
}

-- ============================================================================
-- Global Caches (Originals & Runtime)
-- ============================================================================

local partOrigMap: { [BasePart]: PartOrig } = {}
local beamOrigMap: { [Beam]: BeamOrig } = {}
local lightOrigMap: { [PointLight]: LightOrig } = {}
local emitterOrigMap: { [ParticleEmitter]: EmitterOrig } = {}

local ponds: { [string]: PondState } = {}
local trainingSpots: { [BasePart]: boolean } = {}

local reduceEffects = false
local lastLocalCombo = 0
local started = false
local frameCounter = 0
local elapsedGlobal = 0
local nextRescanTime = 0

-- ============================================================================
-- Safe Attribute & Original-State Helpers
-- ============================================================================

local function getNumberAttr(inst: Instance, name: string, fallback: number): number
	local v = inst:GetAttribute(name)
	if type(v) == "number" then
		return v
	end
	return fallback
end

local function getStringAttr(inst: Instance, name: string, fallback: string): string
	local v = inst:GetAttribute(name)
	if type(v) == "string" then
		return v
	end
	return fallback
end

local function getPartOrig(part: BasePart): PartOrig
	local cached = partOrigMap[part]
	if cached then
		return cached
	end
	local orig: PartOrig = {
		cframe = part.CFrame,
		size = part.Size,
		transparency = part.Transparency,
		color = part.Color,
	}
	partOrigMap[part] = orig
	part.Destroying:Once(function()
		partOrigMap[part] = nil
	end)
	return orig
end

local function getBeamOrig(beam: Beam): BeamOrig
	local cached = beamOrigMap[beam]
	if cached then
		return cached
	end
	local orig: BeamOrig = {
		width0 = beam.Width0,
		width1 = beam.Width1,
		brightness = beam.Brightness,
	}
	beamOrigMap[beam] = orig
	beam.Destroying:Once(function()
		beamOrigMap[beam] = nil
	end)
	return orig
end

local function getLightOrig(light: PointLight): LightOrig
	local cached = lightOrigMap[light]
	if cached then
		return cached
	end
	local orig: LightOrig = {
		brightness = light.Brightness,
		range = light.Range,
	}
	lightOrigMap[light] = orig
	light.Destroying:Once(function()
		lightOrigMap[light] = nil
	end)
	return orig
end

local function getEmitterOrig(emitter: ParticleEmitter): EmitterOrig
	local cached = emitterOrigMap[emitter]
	if cached then
		return cached
	end
	local orig: EmitterOrig = {
		rate = emitter.Rate,
		enabled = emitter.Enabled,
	}
	emitterOrigMap[emitter] = orig
	emitter.Destroying:Once(function()
		emitterOrigMap[emitter] = nil
	end)
	return orig
end

local function pushMove(
	partsOut: { BasePart },
	cframesOut: { CFrame },
	part: BasePart,
	cf: CFrame
): ()
	if #partsOut >= MAX_BULK_PARTS_PER_POND then
		return
	end
	if part.Parent == nil then
		return
	end
	table.insert(partsOut, part)
	table.insert(cframesOut, cf)
end

local function computeModelCenterCF(model: Instance, filterPrefix: string?): CFrame?
	local sumPos = Vector3.zero
	local count = 0
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			if filterPrefix == nil or string.sub(desc.Name, 1, #filterPrefix) == filterPrefix then
				local orig = getPartOrig(desc)
				sumPos += orig.cframe.Position
				count += 1
			end
		end
	end
	if count == 0 and filterPrefix ~= nil then
		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") then
				local orig = getPartOrig(desc)
				sumPos += orig.cframe.Position
				count += 1
			end
		end
	end
	if count == 0 then
		return nil
	end
	return CFrame.new(sumPos / count)
end

local function collectPartRels(root: Instance, pivotCF: CFrame, out: { PartRel }): ()
	for _, desc in root:GetDescendants() do
		if desc:IsA("BasePart") then
			local orig = getPartOrig(desc)
			table.insert(out, {
				part = desc,
				relCF = pivotCF:ToObjectSpace(orig.cframe),
				orig = orig,
			})
		end
	end
end

local function getAmpScale(): number
	return if reduceEffects then 0.35 else 1.0
end

-- ============================================================================
-- Pooled Client-Only Effects (Reused, Never Created Per Frame)
-- ============================================================================

local function ensureComboRing(state: PondState): ComboRingPool?
	if state.comboRing and state.comboRing.part.Parent ~= nil then
		return state.comboRing
	end
	if #state.createdEmitters >= 6 then
		return nil
	end

	local ring = Instance.new("Part")
	ring.Name = "_PondComboRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.CastShadow = false
	ring.Transparency = 1
	ring.Size = Vector3.new(0.18, 6, 6)
	if state.profile.statName == "Control" then
		ring.Color = Color3.fromRGB(115, 240, 255)
	else
		ring.Color = Color3.fromRGB(225, 130, 255)
	end
	ring.CFrame = CFrame.new(state.centerPos.X, state.waterY + 0.12, state.centerPos.Z)
		* CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = state.model

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "_PondComboBurst"
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.6, 1.1)
	emitter.Speed = NumberRange.new(2.5, 5.5)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 0.85
	emitter.Color = ColorSequence.new(ring.Color)
	emitter.Parent = ring

	table.insert(state.createdInstances, ring)
	table.insert(state.createdEmitters, emitter)

	local pool: ComboRingPool = {
		part = ring,
		origSize = ring.Size,
		emitter = emitter,
	}
	state.comboRing = pool
	return pool
end

local function ensureSplashPool(state: PondState): ()
	if state.splashRing and state.splashRing.Parent ~= nil then
		return
	end
	if #state.createdEmitters >= 6 then
		return
	end

	local ring = Instance.new("Part")
	ring.Name = "_PondSplashRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(215, 245, 255)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.CanQuery = false
	ring.CastShadow = false
	ring.Transparency = 1
	ring.Size = Vector3.new(0.12, 2.2, 2.2)
	ring.CFrame = CFrame.new(state.centerPos.X, state.waterY + 0.08, state.centerPos.Z)
		* CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = state.model

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "_PondSplashDrops"
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.35, 0.7)
	emitter.Speed = NumberRange.new(4, 8)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Acceleration = Vector3.new(0, -18, 0)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 0.5
	emitter.Color = ColorSequence.new(Color3.fromRGB(220, 248, 255))
	emitter.Parent = ring

	table.insert(state.createdInstances, ring)
	table.insert(state.createdEmitters, emitter)
	state.splashRing = ring
	state.splashEmitter = emitter
end

local function triggerSplash(state: PondState, pos: Vector3): ()
	if reduceEffects then
		return
	end
	ensureSplashPool(state)
	local ring = state.splashRing
	local emitter = state.splashEmitter
	if ring and ring.Parent ~= nil then
		ring.CFrame = CFrame.new(pos.X, state.waterY + 0.08, pos.Z)
			* CFrame.Angles(0, 0, math.rad(90))
		state.splashTimer = 0.75
		if emitter then
			emitter:Emit(8)
		end
	end
end

local function ensureAmbientEmitter(
	state: PondState,
	name: string,
	color: Color3,
	rate: number,
	speedMin: number,
	speedMax: number,
	sizeVal: number,
	offsetY: number
): ParticleEmitter?
	for _, em in state.createdEmitters do
		if em.Name == name and em.Parent ~= nil then
			return em
		end
	end
	if #state.createdEmitters >= 6 then
		return nil
	end
	local host = state.waterSurface
	if not host or host.Parent == nil then
		return nil
	end

	local att = Instance.new("Attachment")
	att.Name = name .. "_Att"
	att.Position = Vector3.new(0, offsetY, 0)
	att.Parent = host

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Enabled = not reduceEffects
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(2.2, 4.0)
	emitter.Speed = NumberRange.new(speedMin, speedMax)
	emitter.SpreadAngle = Vector2.new(18, 18)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.25, sizeVal),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 0.75
	emitter.Color = ColorSequence.new(color)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = att

	table.insert(state.createdInstances, att)
	table.insert(state.createdEmitters, emitter)
	getEmitterOrig(emitter)
	return emitter
end

local function ensureShootingStar(state: PondState): ShootingStarPool?
	if state.shootingStar and state.shootingStar.part.Parent ~= nil then
		return state.shootingStar
	end

	local part = Instance.new("Part")
	part.Name = "_PondShootingStar"
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(205, 245, 255)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(0.18, 0.18, 3.6)
	part.CFrame = CFrame.new(state.centerPos.X, state.waterY + 0.18, state.centerPos.Z)
	part.Parent = state.model

	table.insert(state.createdInstances, part)

	local pool: ShootingStarPool = {
		part = part,
		active = false,
		elapsed = 0,
		duration = 0.85,
		startPos = state.centerPos,
		endPos = state.centerPos,
		nextTriggerTime = elapsedGlobal + 8 + math.random() * 7,
	}
	state.shootingStar = pool
	return pool
end

-- ============================================================================
-- Orbit Creature Registration & Update (Safe for All 3 Instinct Ponds)
-- ============================================================================

local function registerOrbitCreature(
	state: PondState,
	model: Model,
	isJellyfish: boolean,
	addCosmicTrail: boolean
): ()
	local primary = model.PrimaryPart
	if not primary then
		local fallbackName = if isJellyfish then "BellOuter" else "Body"
		local found = model:FindFirstChild(fallbackName, true)
		if found and found:IsA("BasePart") then
			primary = found
		end
	end
	if not primary then
		return
	end

	local orig = getPartOrig(primary)
	local origCF = orig.cframe
	local origPos = origCF.Position

	local rawRadius = getNumberAttr(model, "OrbitRadius", -1)
	local orbitSpeed = getNumberAttr(model, "OrbitSpeed", if isJellyfish then 0.18 else 0.35)
	if math.abs(orbitSpeed) < 0.02 then
		orbitSpeed = if orbitSpeed < 0 then -0.2 else 0.2
	end
	-- Keep orbit speeds calm and elegant
	orbitSpeed = math.clamp(orbitSpeed, -0.75, 0.75)

	local orbitCenter = state.centerPos
	local centerAttr = model:GetAttribute("OrbitCenter")
	if typeof(centerAttr) == "Vector3" then
		orbitCenter = centerAttr
	end
	local dx = origPos.X - orbitCenter.X
	local dz = origPos.Z - orbitCenter.Z
	local actualDist = math.sqrt(dx * dx + dz * dz)

	-- Safe elliptical margin so creatures never leave the water or clip the deck
	local safeMaxR = math.max(2.0, math.min(state.radiusX, state.radiusZ) - 3.6)
	local effectiveRadius: number
	if rawRadius > 0.5 then
		-- Trust the authored radius unless the creature was clearly placed elsewhere.
		if actualDist > 0.5 and math.abs(actualDist - rawRadius) > 3.5 then
			effectiveRadius = math.min(actualDist, safeMaxR)
		else
			effectiveRadius = math.min(rawRadius, safeMaxR)
		end
	else
		effectiveRadius = math.clamp(actualDist, 2.0, safeMaxR)
	end

	-- Use actual placed angle if OrbitPhase disagrees significantly to prevent teleporting
	local actualAngle = if actualDist > 0.2 then math.atan2(dz, dx) else 0
	local attrPhase = model:GetAttribute("OrbitPhase")
	local orbitPhase = actualAngle
	if type(attrPhase) == "number" then
		local testX = orbitCenter.X + math.cos(attrPhase) * effectiveRadius
		local testZ = orbitCenter.Z + math.sin(attrPhase) * effectiveRadius
		local diff = Vector2.new(testX - origPos.X, testZ - origPos.Z).Magnitude
		if diff <= 2.5 then
			orbitPhase = attrPhase
		end
	end

	-- DepthY rule: < 5 means relative to WaterSurface.Y; >= 5 means absolute Y; missing keeps current Y
	local baseY = origPos.Y
	local depthAttr = model:GetAttribute("DepthY")
	if type(depthAttr) == "number" then
		if depthAttr < 5 then
			baseY = state.waterY + depthAttr
		else
			baseY = depthAttr
		end
	end

	-- Collect subparts and determine local forward direction
	local parts: { FishSubPart } = {}
	local tentacles: { PartRel } = {}
	local tailSumLocal = Vector3.zero
	local tailCount = 0

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			local pOrig = getPartOrig(desc)
			local relCF = origCF:ToObjectSpace(pOrig.cframe)
			local name = desc.Name

			if isJellyfish and string.sub(name, 1, 5) == "Tent_" then
				table.insert(tentacles, {
					part = desc,
					relCF = relCF,
					orig = pOrig,
				})
			else
				local kind = "Body"
				if name == "TailL" or name == "TailR" or string.find(name, "Tail") then
					kind = if name == "TailR" then "TailR" else "TailL"
					tailSumLocal += relCF.Position
					tailCount += 1
				elseif name == "FinL" then
					kind = "FinL"
				elseif name == "FinR" then
					kind = "FinR"
				elseif string.find(name, "Fin") then
					kind = if relCF.Position.X < 0 then "FinL" else "FinR"
				end

				-- Hinge point halfway between body center and appendage keeps parts attached
				local hingeLocal = relCF.Position * 0.5
				table.insert(parts, {
					part = desc,
					relCF = relCF,
					hingeLocal = hingeLocal,
					kind = kind,
				})
			end
		end
	end

	-- Compute forward alignment offset so the creature always swims nose-first
	local forwardFixCF = CFrame.identity
	if not isJellyfish then
		if tailCount > 0 then
			local avgTail = tailSumLocal / tailCount
			local localFwd = -avgTail
			if localFwd.Magnitude > 0.05 then
				local ax = math.abs(localFwd.X)
				local az = math.abs(localFwd.Z)
				if ax > az then
					-- Local +X or -X is nose; map standard -Z forward onto it
					if localFwd.X > 0 then
						forwardFixCF = CFrame.Angles(0, math.rad(90), 0)
					else
						forwardFixCF = CFrame.Angles(0, math.rad(-90), 0)
					end
				else
					if localFwd.Z > 0 then
						forwardFixCF = CFrame.Angles(0, math.rad(180), 0)
					else
						forwardFixCF = CFrame.identity
					end
				end
			end
		else
			-- Fallback: preserve placed yaw relative to initial orbit tangent
			local dirSign = if orbitSpeed >= 0 then 1 else -1
			local tanX = -math.sin(orbitPhase) * dirSign
			local tanZ = math.cos(orbitPhase) * dirSign
			local tanVec = Vector3.new(tanX, 0, tanZ)
			if tanVec.Magnitude > 0.01 then
				local idealCF = CFrame.lookAt(origPos, origPos + tanVec)
				local delta = idealCF:ToObjectSpace(origCF)
				local _, ry, _ = delta:ToEulerAnglesYXZ()
				forwardFixCF = CFrame.Angles(0, ry, 0)
			end
		end
	end

	local trailEmitter: ParticleEmitter? = nil
	if addCosmicTrail and #state.createdEmitters < 6 then
		local existing = primary:FindFirstChild("_CosmicFishTrail")
		if existing and existing:IsA("ParticleEmitter") then
			trailEmitter = existing
		else
			local em = Instance.new("ParticleEmitter")
			em.Name = "_CosmicFishTrail"
			em.Enabled = not reduceEffects
			em.Rate = 5
			em.Lifetime = NumberRange.new(0.7, 1.3)
			em.Speed = NumberRange.new(0.1, 0.4)
			em.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.25),
				NumberSequenceKeypoint.new(1, 0),
			})
			em.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.25),
				NumberSequenceKeypoint.new(1, 1),
			})
			em.LightEmission = 0.9
			em.Color = ColorSequence.new(orig.color)
			em.Parent = primary
			table.insert(state.createdInstances, em)
			table.insert(state.createdEmitters, em)
			getEmitterOrig(em)
			trailEmitter = em
		end
	end

	table.insert(state.creatures, {
		model = model,
		primary = primary,
		origCF = origCF,
		orbitRadius = effectiveRadius,
		orbitSpeed = orbitSpeed,
		orbitPhase = orbitPhase,
		baseY = baseY,
		isJellyfish = isJellyfish,
		forwardFixCF = forwardFixCF,
		parts = parts,
		tentacles = tentacles,
		trailEmitter = trailEmitter,
	})
end

local function updateOrbitCreatures(
	state: PondState,
	t: number,
	dt: number,
	allowJump: boolean,
	partsOut: { BasePart },
	cframesOut: { CFrame }
): ()
	local amp = getAmpScale()
	local comboSpeedBoost = 1 + state.comboPulse * 1.15
	local awakeBoost = 1 + state.awake * 0.4
	local animT = state.animTime

	-- Manage rare graceful fish jump
	local js = state.jumpState
	if allowJump and not reduceEffects and #state.creatures > 0 then
		if not js.active and elapsedGlobal >= js.nextTriggerTime then
			-- Pick a non-jellyfish creature
			local candidates: { number } = {}
			for idx, c in state.creatures do
				if not c.isJellyfish and c.primary.Parent ~= nil then
					table.insert(candidates, idx)
				end
			end
			if #candidates > 0 then
				js.active = true
				js.creatureIndex = candidates[math.random(1, #candidates)]
				js.elapsed = 0
				js.duration = 1.15
				js.splashedOut = false
				js.splashedIn = false
			else
				js.nextTriggerTime = elapsedGlobal + 10
			end
		elseif js.active then
			js.elapsed += dt
			if js.elapsed >= js.duration then
				js.active = false
				js.nextTriggerTime = elapsedGlobal + 13 + math.random() * 10
			end
		end
	elseif js.active and reduceEffects then
		js.active = false
	end

	for idx, c in state.creatures do
		if c.primary.Parent == nil then
			continue
		end

		local angle = c.orbitPhase + animT * c.orbitSpeed
		if state.comboPulse > 0.01 then
			angle += (if c.orbitSpeed >= 0 then 1 else -1) * state.comboPulse * 0.25
		end

		-- Elliptical scaling keeps orbits naturally shaped to the pond
		local ratioZ = if state.radiusX > 1
			then math.clamp(state.radiusZ / state.radiusX, 0.78, 1.0)
			else 0.9
		local ox = state.centerPos.X + math.cos(angle) * c.orbitRadius
		local oz = state.centerPos.Z + math.sin(angle) * c.orbitRadius * ratioZ

		if c.isJellyfish then
			-- Jellyfish propulsion pulse: smooth asymmetric rise & glide
			local pulsePhase = t * (TWO_PI / 2.8) * awakeBoost + idx * 1.9
			local pulseRaw = math.sin(pulsePhase)
			local lift = (0.5 + 0.5 * pulseRaw) * 0.45 * amp
			local oy = c.baseY + lift

			local tiltX = math.rad(5 * amp) * math.sin(pulsePhase * 0.5)
			local tiltZ = math.rad(4 * amp) * math.cos(pulsePhase * 0.5)
			local yaw = c.orbitPhase + animT * 0.15
			local baseCF = CFrame.new(ox, oy, oz) * CFrame.Angles(tiltX, yaw, tiltZ)

			-- Bell slight contraction effect via gentle vertical offset on non-tentacle parts
			local bellSquash = math.sin(pulsePhase) * 0.08 * amp
			for _, sub in c.parts do
				if sub.part.Parent ~= nil then
					local localCF = sub.relCF
					if sub.part == c.primary then
						local orig = getPartOrig(sub.part)
						local scaleXZ = 1 - bellSquash
						local scaleY = 1 + bellSquash * 1.15
						sub.part.Size = Vector3.new(
							orig.size.X * scaleXZ,
							orig.size.Y * scaleY,
							orig.size.Z * scaleXZ
						)
					end
					pushMove(partsOut, cframesOut, sub.part, baseCF * localCF)
				end
			end

			-- Trailing tentacles with phase-delayed wave
			for tIdx, tent in c.tentacles do
				if tent.part.Parent ~= nil then
					local wave = math.sin(pulsePhase - 0.7 - tIdx * 0.45) * math.rad(10 * amp)
					local sway = math.cos(pulsePhase * 0.7 + tIdx * 0.8) * math.rad(7 * amp)
					local tentCF = baseCF * tent.relCF * CFrame.Angles(wave, 0, sway)
					pushMove(partsOut, cframesOut, tent.part, tentCF)
				end
			end
		else
			-- Fish swimming smoothly along elliptical tangent
			local dirSign = if c.orbitSpeed >= 0 then 1 else -1
			local tanX = -math.sin(angle) * dirSign
			local tanZ = math.cos(angle) * ratioZ * dirSign
			local tanVec = Vector3.new(tanX, 0, tanZ)

			local bobY = math.sin(t * (TWO_PI / 3.2) + idx * 1.7) * 0.14 * amp
			local jumpY = 0
			local jumpPitch = 0

			if js.active and js.creatureIndex == idx then
				local u = math.clamp(js.elapsed / js.duration, 0, 1)
				jumpY = 4 * u * (1 - u) * 2.1
				jumpPitch = (1 - 2 * u) * math.rad(28)
				if not js.splashedOut and u > 0.08 then
					js.splashedOut = true
					triggerSplash(state, Vector3.new(ox, state.waterY, oz))
				elseif not js.splashedIn and u > 0.90 then
					js.splashedIn = true
					triggerSplash(state, Vector3.new(ox, state.waterY, oz))
				end
			end

			local pos = Vector3.new(ox, c.baseY + bobY + jumpY, oz)
			local lookCF: CFrame
			if tanVec.Magnitude > 0.001 then
				lookCF = CFrame.lookAt(pos, pos + tanVec)
			else
				lookCF = CFrame.new(pos)
			end

			local swimFreq = (2.2 + math.abs(c.orbitSpeed) * 2.5) * awakeBoost * comboSpeedBoost
			local swimPhase = t * swimFreq + idx * 2.1
			local bodyYawSway = math.sin(swimPhase) * math.rad(4.5 * amp)
			local bodyRoll = math.sin(swimPhase * 0.5) * math.rad(3 * amp)

			local baseCF = lookCF * CFrame.Angles(jumpPitch, bodyYawSway, bodyRoll) * c.forwardFixCF

			for _, sub in c.parts do
				if sub.part.Parent ~= nil then
					local partRel = sub.relCF
					if sub.kind == "TailL" or sub.kind == "TailR" then
						local wag = math.sin(swimPhase - 0.6) * math.rad(16 * amp)
						local hinge = CFrame.new(sub.hingeLocal)
						local localOffset = hinge:ToObjectSpace(partRel)
						partRel = hinge * CFrame.Angles(0, wag, 0) * localOffset
					elseif sub.kind == "FinL" or sub.kind == "FinR" then
						local sign = if sub.kind == "FinL" then 1 else -1
						local flutter = math.sin(swimPhase * 1.15 + 0.5) * math.rad(10 * amp) * sign
						local hinge = CFrame.new(sub.hingeLocal)
						local localOffset = hinge:ToObjectSpace(partRel)
						partRel = hinge * CFrame.Angles(0, flutter, flutter * 0.4) * localOffset
					end
					pushMove(partsOut, cframesOut, sub.part, baseCF * partRel)
				end
			end

			if c.trailEmitter and c.trailEmitter.Parent ~= nil then
				local origEm = getEmitterOrig(c.trailEmitter)
				c.trailEmitter.Enabled = not reduceEffects
				c.trailEmitter.Rate = origEm.rate * (1 + state.awake * 0.7 + state.comboPulse * 1.2)
			end
		end
	end
end

-- ============================================================================
-- Shared Visual Helpers
-- ============================================================================

local function updateTwinkleStars(
	stars: { BasePart },
	t: number,
	awake: number,
	frame: number,
	splitHalf: boolean
): ()
	local count = #stars
	if count == 0 then
		return
	end
	local startIdx = 1
	local step = 1
	if splitHalf and count > 24 then
		startIdx = (frame % 2) + 1
		step = 2
	end
	local freq = if reduceEffects then 0.55 else (1.35 + awake * 0.55)
	local depth = if reduceEffects then 0.12 else (0.35 + awake * 0.12)

	for i = startIdx, count, step do
		local p = stars[i]
		if p.Parent ~= nil then
			local orig = getPartOrig(p)
			local wave = 0.5 + 0.5 * math.sin(t * freq + i * 1.37)
			p.Transparency = math.clamp(orig.transparency + (1 - wave) * depth, 0, 0.96)
		end
	end
end

local function updateRuneSequence(runes: { BasePart }, t: number, awake: number): ()
	local count = #runes
	if count == 0 then
		return
	end
	local speed = 0.55 + awake * 0.45
	local wavePos = (t * speed) % count
	local depth = if reduceEffects then 0.18 else 0.48

	for i = 1, count do
		local p = runes[i]
		if p.Parent ~= nil then
			local orig = getPartOrig(p)
			local dist = math.abs((i - 1) - wavePos)
			if dist > count * 0.5 then
				dist = count - dist
			end
			local glow = math.max(0, 1 - dist * 0.75)
			local targetTransp =
				math.clamp(orig.transparency + (1 - glow) * depth - awake * 0.08, 0, 0.92)
			p.Transparency = targetTransp
		end
	end
end

local function updateSwayGroups(
	groups: { SwayGroup },
	t: number,
	cycleSec: number,
	maxDeg: number,
	partsOut: { BasePart },
	cframesOut: { CFrame }
): ()
	local amp = getAmpScale()
	local omega = TWO_PI / cycleSec
	local radMax = math.rad(maxDeg * amp)

	for _, g in groups do
		local swayX = math.sin(t * omega + g.phase) * radMax
		local swayZ = math.cos(t * omega * 0.77 + g.phase) * radMax * 0.7
		local newPivot = g.pivotCF * CFrame.Angles(swayX, 0, swayZ)
		for _, pr in g.parts do
			if pr.part.Parent ~= nil then
				pushMove(partsOut, cframesOut, pr.part, newPivot * pr.relCF)
			end
		end
	end
end

local function updateCrystalPillars(
	pillars: { CrystalPillarData },
	t: number,
	awake: number,
	bobAmp: number,
	bobPeriod: number,
	partsOut: { BasePart },
	cframesOut: { CFrame }
): ()
	local amp = getAmpScale()
	local omega = TWO_PI / bobPeriod
	local glowOmega = TWO_PI / 3.8

	for _, pil in pillars do
		local breath = 0.5 + 0.5 * math.sin(t * glowOmega + pil.phase)
		if bobAmp > 0.001 then
			local dy = math.sin(t * omega + pil.phase) * bobAmp * amp
			local newPivot = pil.centerCF + Vector3.new(0, dy, 0)
			for _, pr in pil.parts do
				if pr.part.Parent ~= nil then
					pushMove(partsOut, cframesOut, pr.part, newPivot * pr.relCF)
				end
			end
		end

		for _, beam in pil.beams do
			if beam.Parent ~= nil then
				local orig = getBeamOrig(beam)
				local pulse = 1 + (breath - 0.5) * 0.22 * amp + awake * 0.25
				beam.Brightness = orig.brightness * pulse
				beam.Width0 = orig.width0 * (1 + (breath - 0.5) * 0.1 * amp)
				beam.Width1 = orig.width1 * (1 + (breath - 0.5) * 0.1 * amp)
			end
		end

		for _, em in pil.emitters do
			if em.Parent ~= nil then
				local orig = getEmitterOrig(em)
				em.Rate = orig.rate * (1 + awake * 0.6)
			end
		end

		for _, light in pil.lights do
			if light.Parent ~= nil then
				local orig = getLightOrig(light)
				light.Brightness = orig.brightness
					* (1 + (breath - 0.5) * 0.25 * amp + awake * 0.35)
			end
		end
	end
end

-- ============================================================================
-- Pond Profiles (Island 1, 2, 3 — Ready for Island 4 Celestial)
-- ============================================================================

local function buildRingGroup(
	coreModel: Model,
	haloModel: Model?,
	defaultIndex: number,
	isRipple: boolean,
	segPrefix: string?
): RingGroup?
	local centerCF: CFrame? = nil
	if coreModel.PrimaryPart then
		centerCF = getPartOrig(coreModel.PrimaryPart).cframe
	else
		local centerChild = coreModel:FindFirstChild("Center")
		if centerChild and centerChild:IsA("BasePart") then
			centerCF = getPartOrig(centerChild).cframe
		else
			centerCF = computeModelCenterCF(coreModel, segPrefix)
		end
	end
	if not centerCF then
		return nil
	end

	local parts: { PartRel } = {}
	collectPartRels(coreModel, centerCF, parts)
	if haloModel then
		collectPartRels(haloModel, centerCF, parts)
	end

	local ringIndex = getNumberAttr(coreModel, "RingIndex", defaultIndex)
	local baseY = getNumberAttr(coreModel, "BaseY", centerCF.Position.Y)

	return {
		coreModel = coreModel,
		haloModel = haloModel,
		centerCF = centerCF,
		ringIndex = ringIndex,
		baseY = baseY,
		parts = parts,
		isRipple = isRipple,
	}
end

local function clearScanCaches(state: PondState): ()
	table.clear(state.rings)
	table.clear(state.creatures)
	table.clear(state.buoys)
	table.clear(state.hexCells)
	table.clear(state.pillars)
	table.clear(state.verticalBeams)
	table.clear(state.existingEmitters)
	table.clear(state.stars)
	table.clear(state.petals)
	table.clear(state.runes)
	table.clear(state.swayGroups)
	table.clear(state.lanterns)
	table.clear(state.targetShells)
	state.clam = nil
	state.constellation = nil
	state.mirrorGlow = nil
	table.clear(state.deckCrystals)
	table.clear(state.spiralArms)
	table.clear(state.galaxyCoreParts)
	table.clear(state.galaxyStars)
	table.clear(state.canopyCrystals)
	table.clear(state.fireflyParts)
	table.clear(state.fireflyEmitters)
	table.clear(state.pondLights)
end

-- ----------------------------------------------------------------------------
-- Island 1: Apprentice — FocusPond
-- ----------------------------------------------------------------------------
local ApprenticeFocusProfile: PondProfile = {
	islandName = "TrainingIsland_Apprentice",
	islandIndex = 1,
	pondName = "FocusPond",
	statName = "Control",

	scan = function(state: PondState)
		clearScanCaches(state)
		local root = state.model

		local lightRings = root:FindFirstChild("FocusLightRings")
		if lightRings then
			for i = 1, 3 do
				local core = lightRings:FindFirstChild("FocusRing_" .. i)
				if core and core:IsA("Model") then
					local halo = lightRings:FindFirstChild("FocusRing_" .. i .. "_Halo")
					local haloModel = if halo and halo:IsA("Model") then halo else nil
					local rg = buildRingGroup(core, haloModel, i, false, nil)
					if rg then
						table.insert(state.rings, rg)
					end
				end
			end
			for idx, rName in { "FocusRing_Ripple", "FocusRing_OuterWave" } do
				local ripple = lightRings:FindFirstChild(rName)
				if ripple and ripple:IsA("Model") then
					local rg = buildRingGroup(ripple, nil, 3 + idx, true, nil)
					if rg then
						table.insert(state.rings, rg)
					end
				end
			end
		end

		local vertCol = root:FindFirstChild("FocusVerticalColumn", true)
		if vertCol then
			if vertCol:IsA("Beam") then
				getBeamOrig(vertCol)
				table.insert(state.verticalBeams, vertCol)
			else
				for _, d in vertCol:GetDescendants() do
					if d:IsA("Beam") then
						getBeamOrig(d)
						table.insert(state.verticalBeams, d)
					end
				end
			end
		end

		local buoysFolder = root:FindFirstChild("FocusBuoys")
		if buoysFolder then
			for i = 1, 3 do
				local bm = buoysFolder:FindFirstChild("FocusBuoy_" .. i)
				if bm and bm:IsA("Model") then
					local prim = bm.PrimaryPart or bm:FindFirstChild("FloatBase")
					local centerCF = if prim and prim:IsA("BasePart")
						then getPartOrig(prim).cframe
						else computeModelCenterCF(bm, nil)
					if centerCF then
						local bParts: { PartRel } = {}
						local bRipples: { BasePart } = {}
						for _, d in bm:GetDescendants() do
							if d:IsA("BasePart") then
								local orig = getPartOrig(d)
								if d.Name == "RippleInner" or d.Name == "RippleOuter" then
									table.insert(bRipples, d)
								else
									table.insert(bParts, {
										part = d,
										relCF = centerCF:ToObjectSpace(orig.cframe),
										orig = orig,
									})
								end
							end
						end
						table.insert(state.buoys, {
							model = bm,
							centerCF = centerCF,
							buoyIndex = getNumberAttr(bm, "BuoyIndex", i),
							parts = bParts,
							ripples = bRipples,
						})
					end
				end
			end
		end

		local hexFolder = root:FindFirstChild("WaterCellPattern")
		if hexFolder then
			for _, d in hexFolder:GetDescendants() do
				if d:IsA("BasePart") then
					getPartOrig(d)
					table.insert(state.hexCells, d)
				end
			end
		end

		local pillarsFolder = root:FindFirstChild("CrystalPillars")
		if pillarsFolder then
			local idx = 0
			for _, child in pillarsFolder:GetChildren() do
				idx += 1
				local beams: { Beam } = {}
				local emitters: { ParticleEmitter } = {}
				local lights: { PointLight } = {}
				for _, d in child:GetDescendants() do
					if d:IsA("Beam") then
						getBeamOrig(d)
						table.insert(beams, d)
					elseif d:IsA("ParticleEmitter") then
						getEmitterOrig(d)
						table.insert(emitters, d)
					elseif d:IsA("PointLight") then
						getLightOrig(d)
						table.insert(lights, d)
					end
				end
				local cCF = computeModelCenterCF(child, nil) or CFrame.new(state.centerPos)
				table.insert(state.pillars, {
					model = child,
					centerCF = cCF,
					phase = idx * 1.4,
					parts = {},
					beams = beams,
					emitters = emitters,
					lights = lights,
				})
			end
		end

		ensureAmbientEmitter(
			state,
			"_ApprenticeFocusMotes",
			Color3.fromRGB(160, 245, 255),
			3,
			0.6,
			1.4,
			0.22,
			0.3
		)
	end,

	update = function(state, t, _dt, frame, partsOut, cframesOut)
		local amp = getAmpScale()
		local animT = state.animTime
		local awake = state.awake

		-- Stacked rings bobbing & rotating calmly; water ripples expanding & fading
		for _, rg in state.rings do
			if rg.isRipple then
				local cycle = 3.6 + (rg.ringIndex - 4) * 0.8
				local u = ((t + rg.ringIndex * 1.3) % cycle) / cycle
				local scale = 0.88 + u * 0.32 * amp
				local fade = math.sin(u * math.pi)
				for _, pr in rg.parts do
					if pr.part.Parent ~= nil then
						local p = pr.relCF.Position
						local scaledRel = CFrame.new(p.X * scale, p.Y, p.Z * scale)
							* pr.relCF.Rotation
						pushMove(partsOut, cframesOut, pr.part, rg.centerCF * scaledRel)
						pr.part.Transparency =
							math.clamp(1 - fade * (1 - pr.orig.transparency), 0, 1)
					end
				end
			else
				-- RingIndex 1..3: calm rotation 12..22 deg/s, gentle wave bob
				local degPerSec = (10 + rg.ringIndex * 5)
					* (if rg.ringIndex % 2 == 0 then -1 else 1)
				local yaw = animT * math.rad(degPerSec)
				local bob = math.sin(t * (TWO_PI / 3.6) + rg.ringIndex * 1.15) * 0.28 * amp
				local basePos =
					Vector3.new(rg.centerCF.Position.X, rg.baseY + bob, rg.centerCF.Position.Z)
				local newPivot = CFrame.new(basePos) * CFrame.Angles(0, yaw, 0)
				for _, pr in rg.parts do
					if pr.part.Parent ~= nil then
						pushMove(partsOut, cframesOut, pr.part, newPivot * pr.relCF)
					end
				end
			end
		end

		-- Vertical beam gentle breathing
		for _, beam in state.verticalBeams do
			if beam.Parent ~= nil then
				local orig = getBeamOrig(beam)
				local wave = 0.5 + 0.5 * math.sin(t * (TWO_PI / 4.2))
				beam.Brightness = orig.brightness * (0.9 + wave * 0.25 * amp + awake * 0.3)
				beam.Width0 = orig.width0 * (1 + (wave - 0.5) * 0.1 * amp)
				beam.Width1 = orig.width1 * (1 + (wave - 0.5) * 0.1 * amp)
			end
		end

		-- Buoys gently bobbing & rocking + local ripples
		for _, b in state.buoys do
			local phase = b.buoyIndex * 2.1
			local bob = math.sin(t * (TWO_PI / 2.9) + phase) * 0.14 * amp
			local pitch = math.sin(t * (TWO_PI / 3.4) + phase) * math.rad(4 * amp)
			local roll = math.cos(t * (TWO_PI / 3.9) + phase) * math.rad(3.5 * amp)
			local newPivot = (b.centerCF + Vector3.new(0, bob, 0)) * CFrame.Angles(pitch, 0, roll)
			for _, pr in b.parts do
				if pr.part.Parent ~= nil then
					pushMove(partsOut, cframesOut, pr.part, newPivot * pr.relCF)
				end
			end
			for rIdx, rip in b.ripples do
				if rip.Parent ~= nil then
					local orig = getPartOrig(rip)
					local u = ((t * 0.55 + phase + rIdx * 0.5) % 1)
					local sc = 0.85 + u * 0.35 * amp
					rip.Size = Vector3.new(orig.size.X * sc, orig.size.Y, orig.size.Z * sc)
					rip.Transparency = math.clamp(orig.transparency + u * 0.55, 0, 0.96)
				end
			end
		end

		-- Hexagon water cell pattern: radial light pulse (30 Hz)
		if frame % 2 == 0 then
			local waveSpeed = 4.5 + awake * 2.5
			local wavePos = (t * waveSpeed) % 18
			for _, cell in state.hexCells do
				if cell.Parent ~= nil then
					local orig = getPartOrig(cell)
					local dist = Vector2.new(
						orig.cframe.Position.X - state.centerPos.X,
						orig.cframe.Position.Z - state.centerPos.Z
					).Magnitude
					local band = math.max(0, 1 - math.abs(dist - wavePos) / 4.2)
					local shift = (0.28 * (1 - band) - awake * 0.08) * amp
					cell.Transparency = math.clamp(orig.transparency + shift, 0, 0.92)
				end
			end
		end

		updateCrystalPillars(state.pillars, t, awake, 0, 4.0, partsOut, cframesOut)
	end,
}

-- ----------------------------------------------------------------------------
-- Island 1: Apprentice — InstinctPond
-- ----------------------------------------------------------------------------
local ApprenticeInstinctProfile: PondProfile = {
	islandName = "TrainingIsland_Apprentice",
	islandIndex = 1,
	pondName = "InstinctPond",
	statName = "Instinct",

	scan = function(state: PondState)
		clearScanCaches(state)
		local root = state.model

		for _, fishName in { "InstinctFish_Whale", "InstinctFish_Gold", "InstinctFish_Rainbow" } do
			-- Island 1 keeps its fish inside the MysteryFish folder.
			local fm = root:FindFirstChild(fishName, true)
			if fm and fm:IsA("Model") then
				registerOrbitCreature(state, fm, false, false)
			end
		end

		local arc = root:FindFirstChild("InstinctRainbowArc")
		if arc then
			for _, d in arc:GetDescendants() do
				if d:IsA("BasePart") then
					getPartOrig(d)
					if d.Name == "WaterPetal" then
						table.insert(state.petals, d)
					elseif
						d.Name == "WaterStar"
						or d.Name == "StarCrossA"
						or d.Name == "StarCrossB"
					then
						table.insert(state.stars, d)
					end
				end
			end
		end

		for _, emName in { "InstinctSparkles", "FallingPetals" } do
			local found = root:FindFirstChild(emName, true)
			if found then
				if found:IsA("ParticleEmitter") then
					getEmitterOrig(found)
					table.insert(state.existingEmitters, found)
				else
					for _, d in found:GetDescendants() do
						if d:IsA("ParticleEmitter") then
							getEmitterOrig(d)
							table.insert(state.existingEmitters, d)
						end
					end
				end
			end
		end

		-- PinkLilacBlossomTree gentle canopy sway
		local tree = root:FindFirstChild("PinkLilacBlossomTree")
		if tree then
			local minY = math.huge
			local maxY = -math.huge
			local allParts: { BasePart } = {}
			for _, d in tree:GetDescendants() do
				if d:IsA("BasePart") then
					local orig = getPartOrig(d)
					minY = math.min(minY, orig.cframe.Position.Y)
					maxY = math.max(maxY, orig.cframe.Position.Y)
					table.insert(allParts, d)
				end
			end
			if #allParts > 0 then
				local cutoffY = minY + (maxY - minY) * 0.45
				local canopyParts: { BasePart } = {}
				local sumPos = Vector3.zero
				for _, p in allParts do
					local pos = getPartOrig(p).cframe.Position
					if pos.Y >= cutoffY then
						table.insert(canopyParts, p)
						sumPos += pos
					end
				end
				if #canopyParts > 0 then
					local center = sumPos / #canopyParts
					local pivotCF = CFrame.new(center.X, cutoffY, center.Z)
					local rels: { PartRel } = {}
					for _, p in canopyParts do
						local orig = getPartOrig(p)
						table.insert(rels, {
							part = p,
							relCF = pivotCF:ToObjectSpace(orig.cframe),
							orig = orig,
						})
					end
					table.insert(state.swayGroups, {
						pivotCF = pivotCF,
						phase = 0.6,
						parts = rels,
					})
				end
			end
		end

		-- Lantern posts with HangingLantern
		for idx, postName in { "LanternPost_Left", "LanternPost_Right" } do
			local post = root:FindFirstChild(postName)
			if post then
				local lantern = post:FindFirstChild("HangingLantern", true)
				if lantern then
					local maxY = -math.huge
					local sumX = 0
					local sumZ = 0
					local cnt = 0
					local lParts: { BasePart } = {}
					if lantern:IsA("BasePart") then
						local orig = getPartOrig(lantern)
						maxY = orig.cframe.Position.Y + orig.size.Y * 0.5
						sumX = orig.cframe.Position.X
						sumZ = orig.cframe.Position.Z
						cnt = 1
						table.insert(lParts, lantern)
					end
					for _, d in lantern:GetDescendants() do
						if d:IsA("BasePart") then
							local orig = getPartOrig(d)
							maxY = math.max(maxY, orig.cframe.Position.Y + orig.size.Y * 0.5)
							sumX += orig.cframe.Position.X
							sumZ += orig.cframe.Position.Z
							cnt += 1
							table.insert(lParts, d)
						elseif d:IsA("PointLight") then
							getLightOrig(d)
							table.insert(state.pondLights, d)
						end
					end
					if cnt > 0 then
						local pivotCF = CFrame.new(sumX / cnt, maxY, sumZ / cnt)
						local rels: { PartRel } = {}
						for _, p in lParts do
							local orig = getPartOrig(p)
							table.insert(rels, {
								part = p,
								relCF = pivotCF:ToObjectSpace(orig.cframe),
								orig = orig,
							})
						end
						table.insert(state.lanterns, {
							pivotCF = pivotCF,
							phase = idx * 1.8,
							parts = rels,
						})
					end
				end
			end
		end

		-- RuneStones with Neon RuneStroke
		local runeFolder = root:FindFirstChild("RuneStones")
		if runeFolder then
			for _, d in runeFolder:GetDescendants() do
				if
					d:IsA("BasePart")
					and (d.Name == "RuneStroke" or d.Material == Enum.Material.Neon)
				then
					getPartOrig(d)
					table.insert(state.runes, d)
				end
			end
		end

		-- GoldenFireflies
		local fireflies = root:FindFirstChild("GoldenFireflies", true)
		if fireflies then
			if fireflies:IsA("ParticleEmitter") then
				getEmitterOrig(fireflies)
				table.insert(state.fireflyEmitters, fireflies)
			else
				for _, d in fireflies:GetDescendants() do
					if d:IsA("ParticleEmitter") then
						getEmitterOrig(d)
						table.insert(state.fireflyEmitters, d)
					elseif d:IsA("BasePart") then
						getPartOrig(d)
						table.insert(state.fireflyParts, d)
					end
				end
			end
		end
	end,

	update = function(state, t, dt, frame, partsOut, cframesOut)
		local amp = getAmpScale()
		local awake = state.awake

		updateOrbitCreatures(state, t, dt, true, partsOut, cframesOut)

		-- Petals gently spinning and bobbing on water
		for i, petal in state.petals do
			if petal.Parent ~= nil then
				local orig = getPartOrig(petal)
				local spin = state.animTime * math.rad(14) * (if i % 2 == 0 then 1 else -1)
				local bob = math.sin(t * 1.4 + i) * 0.05 * amp
				pushMove(
					partsOut,
					cframesOut,
					petal,
					(orig.cframe + Vector3.new(0, bob, 0)) * CFrame.Angles(0, spin, 0)
				)
			end
		end

		updateTwinkleStars(state.stars, t, awake, frame, false)
		updateSwayGroups(state.swayGroups, t, 4.8, 1.8, partsOut, cframesOut)
		updateSwayGroups(state.lanterns, t, 3.6, 4.2, partsOut, cframesOut)
		updateRuneSequence(state.runes, t, awake)

		-- Lantern warm lights
		for i, light in state.pondLights do
			if light.Parent ~= nil then
				local orig = getLightOrig(light)
				local flicker = math.sin(t * 2.1 + i * 2.3) * 0.12 * amp
				light.Brightness = orig.brightness * (1 + flicker + awake * 0.25)
			end
		end

		-- Existing sparkles, petals & fireflies
		for _, em in state.existingEmitters do
			if em.Parent ~= nil then
				local orig = getEmitterOrig(em)
				em.Rate = orig.rate * (1 + awake * 0.65)
			end
		end
		for _, em in state.fireflyEmitters do
			if em.Parent ~= nil then
				local orig = getEmitterOrig(em)
				em.Rate = orig.rate * (1 + awake * 0.6)
			end
		end
		for i, ff in state.fireflyParts do
			if ff.Parent ~= nil then
				local orig = getPartOrig(ff)
				local dx = math.sin(t * 0.9 + i * 1.7) * 0.35 * amp
				local dy = math.sin(t * 1.3 + i * 2.3) * 0.25 * amp
				local dz = math.cos(t * 0.8 + i * 1.1) * 0.35 * amp
				pushMove(partsOut, cframesOut, ff, orig.cframe + Vector3.new(dx, dy, dz))
			end
		end
	end,
}

-- ----------------------------------------------------------------------------
-- Island 2: Reef — FocusPond
-- ----------------------------------------------------------------------------
local ReefFocusProfile: PondProfile = {
	islandName = "TrainingIsland_Reef",
	islandIndex = 2,
	pondName = "FocusPond",
	statName = "Control",

	scan = function(state: PondState)
		clearScanCaches(state)
		local root = state.model

		local lightRings = root:FindFirstChild("FocusLightRings")
		if lightRings then
			for i = 1, 3 do
				local core = lightRings:FindFirstChild("FocusRing_" .. i)
				if core and core:IsA("Model") then
					local halo = lightRings:FindFirstChild("FocusRingHalo_" .. i)
						or lightRings:FindFirstChild("FocusRing_" .. i .. "_Halo")
					local haloModel = if halo and halo:IsA("Model") then halo else nil
					local rg = buildRingGroup(core, haloModel, i, false, nil)
					if rg then
						table.insert(state.rings, rg)
					end
				end
			end
		end

		for i = 1, 3 do
			local rip = root:FindFirstChild("WaterRipple_" .. i, true)
			if rip and rip:IsA("Model") then
				local rg = buildRingGroup(rip, nil, i, true, nil)
				if rg then
					table.insert(state.rings, rg)
				end
			elseif rip and rip:IsA("BasePart") then
				getPartOrig(rip)
				table.insert(state.petals, rip)
			end
		end

		-- Tall floating crystals with beams
		for idx, cname in { "TallCrystalLeft", "TallCrystalMid", "TallCrystalRight" } do
			local cm = root:FindFirstChild(cname, true)
			if cm then
				local cCF = computeModelCenterCF(cm, nil)
				if cCF then
					local rels: { PartRel } = {}
					local beams: { Beam } = {}
					local emitters: { ParticleEmitter } = {}
					local lights: { PointLight } = {}
					collectPartRels(cm, cCF, rels)
					for _, d in cm:GetDescendants() do
						if d:IsA("Beam") then
							getBeamOrig(d)
							table.insert(beams, d)
						elseif d:IsA("ParticleEmitter") then
							getEmitterOrig(d)
							table.insert(emitters, d)
						elseif d:IsA("PointLight") then
							getLightOrig(d)
							table.insert(lights, d)
						end
					end
					table.insert(state.pillars, {
						model = cm,
						centerCF = cCF,
						phase = idx * 2.05,
						parts = rels,
						beams = beams,
						emitters = emitters,
						lights = lights,
					})
				end
			end
		end

		-- Anemone tentacles, corals, and fans
		for i = 1, 3 do
			local anemone = root:FindFirstChild("IsletAnemone_" .. i, true)
			if anemone then
				local tIdx = 0
				for _, d in anemone:GetDescendants() do
					if d:IsA("BasePart") and string.sub(d.Name, 1, 4) == "Tent" then
						tIdx += 1
						local orig = getPartOrig(d)
						local basePos = orig.cframe.Position - Vector3.new(0, orig.size.Y * 0.45, 0)
						local pivotCF = CFrame.new(basePos)
						table.insert(state.swayGroups, {
							pivotCF = pivotCF,
							phase = i * 1.9 + tIdx * 0.65,
							parts = {
								{
									part = d,
									relCF = pivotCF:ToObjectSpace(orig.cframe),
									orig = orig,
								},
							},
						})
					end
				end
			end

			for _, prefix in { "IsletCoral_", "IsletFan_" } do
				local flora = root:FindFirstChild(prefix .. i, true)
				if flora then
					local minY = math.huge
					local sumX = 0
					local sumZ = 0
					local cnt = 0
					local fParts: { BasePart } = {}
					for _, d in flora:GetDescendants() do
						if d:IsA("BasePart") then
							local orig = getPartOrig(d)
							minY = math.min(minY, orig.cframe.Position.Y - orig.size.Y * 0.45)
							sumX += orig.cframe.Position.X
							sumZ += orig.cframe.Position.Z
							cnt += 1
							table.insert(fParts, d)
						end
					end
					if cnt > 0 then
						local pivotCF = CFrame.new(sumX / cnt, minY, sumZ / cnt)
						local rels: { PartRel } = {}
						for _, p in fParts do
							local orig = getPartOrig(p)
							table.insert(rels, {
								part = p,
								relCF = pivotCF:ToObjectSpace(orig.cframe),
								orig = orig,
							})
						end
						table.insert(state.lanterns, {
							pivotCF = pivotCF,
							phase = i * 2.1 + (if prefix == "IsletFan_" then 1.0 else 0),
							parts = rels,
						})
					end
				end
			end
		end

		-- Target shells blinking in sequence
		for i = 1, 4 do
			local shell = root:FindFirstChild("TargetShell_" .. i, true)
			if shell then
				if shell:IsA("BasePart") then
					getPartOrig(shell)
					table.insert(state.targetShells, shell)
				else
					local picked: BasePart? = nil
					for _, d in shell:GetDescendants() do
						if d:IsA("BasePart") then
							getPartOrig(d)
							if d.Material == Enum.Material.Neon then
								picked = d
								break
							elseif not picked then
								picked = d
							end
						end
					end
					if picked then
						table.insert(state.targetShells, picked)
					end
				end
			end
		end

		ensureAmbientEmitter(
			state,
			"_ReefFocusBubbles",
			Color3.fromRGB(165, 250, 255),
			3,
			1.0,
			2.2,
			0.2,
			0.2
		)
	end,

	update = function(state, t, _dt, frame, partsOut, cframesOut)
		local amp = getAmpScale()
		local animT = state.animTime
		local awake = state.awake

		-- Spiral rising rings + water ripples
		for _, rg in state.rings do
			if rg.isRipple then
				local cycle = 3.2
				local u = ((t + rg.ringIndex * 1.05) % cycle) / cycle
				local scale = 0.85 + u * 0.35 * amp
				local fade = math.sin(u * math.pi)
				for _, pr in rg.parts do
					if pr.part.Parent ~= nil then
						local p = pr.relCF.Position
						local scaledRel = CFrame.new(p.X * scale, p.Y, p.Z * scale)
							* pr.relCF.Rotation
						pushMove(partsOut, cframesOut, pr.part, rg.centerCF * scaledRel)
						pr.part.Transparency =
							math.clamp(1 - fade * (1 - pr.orig.transparency), 0, 1)
					end
				end
			else
				-- Calm spiral rotation 16..28 deg/s with graceful bob and subtle tilt
				local degPerSec = 14 + rg.ringIndex * 5
				local yaw = animT * math.rad(degPerSec)
				local bob = math.sin(t * (TWO_PI / 3.8) - rg.ringIndex * 0.9) * 0.36 * amp
				local tiltX = math.sin(t * 0.9 + rg.ringIndex) * math.rad(2.5 * amp)
				local tiltZ = math.cos(t * 0.9 + rg.ringIndex) * math.rad(2.5 * amp)
				local basePos =
					Vector3.new(rg.centerCF.Position.X, rg.baseY + bob, rg.centerCF.Position.Z)
				local newPivot = CFrame.new(basePos) * CFrame.Angles(tiltX, yaw, tiltZ)
				for _, pr in rg.parts do
					if pr.part.Parent ~= nil then
						pushMove(partsOut, cframesOut, pr.part, newPivot * pr.relCF)
					end
				end
			end
		end

		-- Part-based water ripples fallback
		for i, rip in state.petals do
			if rip.Parent ~= nil then
				local orig = getPartOrig(rip)
				local u = ((t * 0.4 + i * 0.33) % 1)
				local sc = 0.88 + u * 0.28 * amp
				rip.Size = Vector3.new(orig.size.X * sc, orig.size.Y, orig.size.Z * sc)
				rip.Transparency = math.clamp(orig.transparency + u * 0.6, 0, 0.96)
			end
		end

		-- Tall crystals floating in staggered phases with beams following
		updateCrystalPillars(state.pillars, t, awake, 0.48, 4.4, partsOut, cframesOut)

		-- Anemone tentacles (30 Hz to keep part budget lean) & coral/fan sway
		if frame % 2 == 0 then
			updateSwayGroups(state.swayGroups, t, 2.6, 8.5, partsOut, cframesOut)
		else
			updateSwayGroups(state.lanterns, t, 3.8, 3.2, partsOut, cframesOut)
		end

		-- Target shells pulsing sequentially like focus targets
		local shellCount = #state.targetShells
		if shellCount > 0 then
			local stepRate = 0.8 + awake * 0.55
			local activeIdx = math.floor(t * stepRate) % shellCount + 1
			local localFrac = (t * stepRate) % 1
			local pulse = math.sin(localFrac * math.pi)
			for i, shell in state.targetShells do
				if shell.Parent ~= nil then
					local orig = getPartOrig(shell)
					if i == activeIdx then
						local boost = pulse * (0.28 * amp)
						shell.Transparency = math.clamp(orig.transparency - boost * 0.5, 0, 0.9)
						local sc = 1 + pulse * 0.08 * amp
						shell.Size = orig.size * sc
					else
						shell.Transparency = math.clamp(orig.transparency + 0.12 * amp, 0, 0.92)
						shell.Size = orig.size
					end
				end
			end
		end
	end,
}

-- ----------------------------------------------------------------------------
-- Island 2: Reef — InstinctPond
-- ----------------------------------------------------------------------------
local ReefInstinctProfile: PondProfile = {
	islandName = "TrainingIsland_Reef",
	islandIndex = 2,
	pondName = "InstinctPond",
	statName = "Instinct",

	scan = function(state: PondState)
		clearScanCaches(state)
		local root = state.model

		for i = 1, 3 do
			local jf = root:FindFirstChild("Jellyfish_" .. i)
			if jf and jf:IsA("Model") then
				registerOrbitCreature(state, jf, true, false)
			end
		end

		for i = 1, 2 do
			local pf = root:FindFirstChild("PondFish_" .. i)
			if pf and pf:IsA("Model") then
				registerOrbitCreature(state, pf, false, false)
			end
		end

		-- GiantClam: Top_Outer / Top_Inner lid, GiantPearl, PearlInnerGlow, PearlHalo
		local clam = root:FindFirstChild("GiantClam")
		if clam then
			local lidRaw: { BasePart } = {}
			local pearlRaw: { BasePart } = {}
			local glowParts: { BasePart } = {}
			local lights: { PointLight } = {}
			local topOuter: BasePart? = nil

			for _, d in clam:GetDescendants() do
				if d:IsA("BasePart") then
					getPartOrig(d)
					if d.Name == "Top_Outer" or d.Name == "Top_Inner" then
						table.insert(lidRaw, d)
						if d.Name == "Top_Outer" then
							topOuter = d
						end
					elseif
						d.Name == "GiantPearl"
						or d.Name == "PearlInnerGlow"
						or d.Name == "PearlHalo"
					then
						table.insert(pearlRaw, d)
						if d.Name == "PearlInnerGlow" or d.Name == "PearlHalo" then
							table.insert(glowParts, d)
						end
					end
				elseif d:IsA("PointLight") then
					getLightOrig(d)
					table.insert(lights, d)
				end
			end

			if #lidRaw > 0 then
				local ref = topOuter or lidRaw[1]
				local refOrig = getPartOrig(ref)
				local refPos = refOrig.cframe.Position
				local away =
					Vector3.new(refPos.X - state.centerPos.X, 0, refPos.Z - state.centerPos.Z)
				if away.Magnitude < 0.01 then
					away = Vector3.new(1, 0, 0)
				else
					away = away.Unit
				end
				local hingeOffset = math.max(refOrig.size.X, refOrig.size.Z) * 0.42
				local hingePos = refPos
					+ away * hingeOffset
					- Vector3.new(0, refOrig.size.Y * 0.35, 0)
				-- Look toward pond center so +X local axis is the hinge axis
				local hingeCF = CFrame.lookAt(hingePos, hingePos - away)

				local lidParts: { PartRel } = {}
				for _, p in lidRaw do
					local o = getPartOrig(p)
					table.insert(lidParts, {
						part = p,
						relCF = hingeCF:ToObjectSpace(o.cframe),
						orig = o,
					})
				end

				local pearlCenter = refPos
				if #pearlRaw > 0 then
					local sumP = Vector3.zero
					for _, p in pearlRaw do
						sumP += getPartOrig(p).cframe.Position
					end
					pearlCenter = sumP / #pearlRaw
				end
				local pearlCF = CFrame.new(pearlCenter)
				local pearlParts: { PartRel } = {}
				for _, p in pearlRaw do
					local o = getPartOrig(p)
					table.insert(pearlParts, {
						part = p,
						relCF = pearlCF:ToObjectSpace(o.cframe),
						orig = o,
					})
				end

				state.clam = {
					hingeCF = hingeCF,
					lidParts = lidParts,
					pearlParts = pearlParts,
					pearlCenterCF = pearlCF,
					glowParts = glowParts,
					lights = lights,
				}
			end
		end

		-- Water stars & crosses
		for _, d in root:GetDescendants() do
			if d:IsA("BasePart") then
				if d.Name == "WaterStar" or d.Name == "StarCrossA" or d.Name == "StarCrossB" then
					getPartOrig(d)
					table.insert(state.stars, d)
				end
			end
		end

		-- Rune stones
		for _, rName in { "RuneStone_FrontL", "RuneStone_FrontR", "RuneStone_Back" } do
			local rs = root:FindFirstChild(rName, true)
			if rs then
				for _, d in rs:GetDescendants() do
					if
						d:IsA("BasePart")
						and (d.Material == Enum.Material.Neon or string.find(d.Name, "Rune"))
					then
						getPartOrig(d)
						table.insert(state.runes, d)
					end
				end
			end
		end

		-- Rising bubbles
		ensureAmbientEmitter(
			state,
			"_ReefInstinctBubbles",
			Color3.fromRGB(220, 200, 255),
			4,
			1.2,
			2.6,
			0.24,
			0.15
		)
	end,

	update = function(state, t, dt, frame, partsOut, cframesOut)
		local amp = getAmpScale()
		local awake = state.awake

		updateOrbitCreatures(state, t, dt, true, partsOut, cframesOut)

		-- Giant clam slowly opening & closing to reveal glowing pearl
		local clam = state.clam
		if clam then
			local openWave = 0.5 + 0.5 * math.sin(t * (TWO_PI / 7.2))
			local openDeg = (18 + awake * 8) * openWave * amp
			-- Positive X rotation around lookAt-toward-pond hinge lifts the pond-facing edge upward
			local lidPivot = clam.hingeCF * CFrame.Angles(math.rad(openDeg), 0, 0)
			for _, pr in clam.lidParts do
				if pr.part.Parent ~= nil then
					pushMove(partsOut, cframesOut, pr.part, lidPivot * pr.relCF)
				end
			end

			local pearlBob = openWave * 0.22 * amp
			local pearlSpin = state.animTime * math.rad(16)
			local pearlPivot = (clam.pearlCenterCF + Vector3.new(0, pearlBob, 0))
				* CFrame.Angles(0, pearlSpin, 0)
			for _, pr in clam.pearlParts do
				if pr.part.Parent ~= nil then
					pushMove(partsOut, cframesOut, pr.part, pearlPivot * pr.relCF)
				end
			end

			for _, gp in clam.glowParts do
				if gp.Parent ~= nil then
					local orig = getPartOrig(gp)
					gp.Transparency = math.clamp(
						orig.transparency + (1 - openWave) * 0.35 - awake * 0.08,
						0,
						0.95
					)
				end
			end
			for _, lt in clam.lights do
				if lt.Parent ~= nil then
					local orig = getLightOrig(lt)
					lt.Brightness = orig.brightness * (0.75 + openWave * 0.55 + awake * 0.3)
				end
			end
		end

		updateTwinkleStars(state.stars, t, awake, frame, false)
		updateRuneSequence(state.runes, t, awake)
	end,
}

-- ----------------------------------------------------------------------------
-- Island 3: Abyss — FocusPond
-- ----------------------------------------------------------------------------
local AbyssFocusProfile: PondProfile = {
	islandName = "TrainingIsland_Abyss",
	islandIndex = 3,
	pondName = "FocusPond",
	statName = "Control",

	scan = function(state: PondState)
		clearScanCaches(state)
		local root = state.model

		-- Water rings & floating rings (no PrimaryPart, compute center from Seg_ parts)
		local ringSpecs = {
			{
				core = "FocusWaterRingOuter_Core",
				halo = "FocusWaterRingOuter_Halo",
				idx = 1,
				isFloat = false,
			},
			{
				core = "FocusWaterRingMid_Core",
				halo = "FocusWaterRingMid_Halo",
				idx = 2,
				isFloat = false,
			},
			{
				core = "FocusWaterRingInner_Core",
				halo = "FocusWaterRingInner_Halo",
				idx = 3,
				isFloat = false,
			},
			{
				core = "FocusFloatRingLower_Core",
				halo = "FocusFloatRingLower_Halo",
				idx = 4,
				isFloat = true,
			},
			{
				core = "FocusFloatRingUpper_Core",
				halo = "FocusFloatRingUpper_Halo",
				idx = 5,
				isFloat = true,
			},
		}
		for _, spec in ringSpecs do
			local core = root:FindFirstChild(spec.core, true)
			if core and core:IsA("Model") then
				local halo = root:FindFirstChild(spec.halo, true)
				local haloModel = if halo and halo:IsA("Model") then halo else nil
				local rg = buildRingGroup(core, haloModel, spec.idx, not spec.isFloat, "Seg_")
				if rg then
					table.insert(state.rings, rg)
				end
			end
		end

		-- FocusConstellation (brightness/pulse only — no displacement so lines stay attached)
		local constFolder = root:FindFirstChild("FocusConstellation", true)
		if constFolder then
			local nodes: { BasePart } = {}
			local halos: { BasePart } = {}
			local lines: { BasePart } = {}
			for _, d in constFolder:GetDescendants() do
				if d:IsA("BasePart") then
					getPartOrig(d)
					if d.Name == "NodeCore" or string.find(d.Name, "NodeCore") then
						table.insert(nodes, d)
					elseif d.Name == "NodeHalo" or string.find(d.Name, "NodeHalo") then
						table.insert(halos, d)
					elseif d.Name == "ConstLine" or string.find(d.Name, "ConstLine") then
						table.insert(lines, d)
					end
				end
			end
			state.constellation = {
				nodes = nodes,
				halos = halos,
				lines = lines,
			}
		end

		-- FocusCrystalPillar_1..4 with BeamCore / BeamHalo
		for i = 1, 4 do
			local pil = root:FindFirstChild("FocusCrystalPillar_" .. i, true)
			if pil then
				local beams: { Beam } = {}
				local emitters: { ParticleEmitter } = {}
				local lights: { PointLight } = {}
				for _, d in pil:GetDescendants() do
					if d:IsA("Beam") then
						getBeamOrig(d)
						table.insert(beams, d)
					elseif d:IsA("ParticleEmitter") then
						getEmitterOrig(d)
						table.insert(emitters, d)
					elseif d:IsA("PointLight") then
						getLightOrig(d)
						table.insert(lights, d)
					end
				end
				local cCF = computeModelCenterCF(pil, nil) or CFrame.new(state.centerPos)
				table.insert(state.pillars, {
					model = pil,
					centerCF = cCF,
					phase = i * 1.55,
					parts = {},
					beams = beams,
					emitters = emitters,
					lights = lights,
				})
			end
		end

		-- MirrorStar (92), MirrorCenterGlow, StarCrossA/B
		for _, d in root:GetDescendants() do
			if d:IsA("BasePart") then
				if d.Name == "MirrorStar" or d.Name == "StarCrossA" or d.Name == "StarCrossB" then
					getPartOrig(d)
					table.insert(state.stars, d)
				elseif d.Name == "MirrorCenterGlow" then
					getPartOrig(d)
					state.mirrorGlow = d
				end
			end
		end

		-- FocusDeckCrystal_1..3
		for i = 1, 3 do
			local dc = root:FindFirstChild("FocusDeckCrystal_" .. i, true)
			if dc then
				local cCF = computeModelCenterCF(dc, nil)
				if cCF then
					local rels: { PartRel } = {}
					local lights: { PointLight } = {}
					collectPartRels(dc, cCF, rels)
					for _, d in dc:GetDescendants() do
						if d:IsA("PointLight") then
							getLightOrig(d)
							table.insert(lights, d)
						end
					end
					table.insert(state.deckCrystals, {
						model = dc,
						centerCF = cCF,
						phase = i * 2.1,
						parts = rels,
						beams = {},
						emitters = {},
						lights = lights,
					})
				end
			end
		end

		ensureShootingStar(state)
		ensureAmbientEmitter(
			state,
			"_AbyssFocusStardust",
			Color3.fromRGB(130, 225, 255),
			3,
			0.5,
			1.5,
			0.2,
			0.35
		)
	end,

	update = function(state, t, dt, frame, partsOut, cframesOut)
		local amp = getAmpScale()
		local animT = state.animTime
		local awake = state.awake

		-- Counter-rotating rings; alternate water rings (even frames) & floating rings (odd frames)
		-- to keep BulkMoveTo comfortably under 450 parts/frame.
		local ringSpeedsDeg = { 10, -16, 24, -18, 30 }
		for _, rg in state.rings do
			local isWaterRing = rg.isRipple
			if (isWaterRing and frame % 2 == 0) or (not isWaterRing and frame % 2 == 1) then
				local degPerSec = ringSpeedsDeg[rg.ringIndex] or 15
				local yaw = animT * math.rad(degPerSec)
				local newPivot: CFrame
				if isWaterRing then
					newPivot = rg.centerCF * CFrame.Angles(0, yaw, 0)
				else
					local bob = math.sin(t * (TWO_PI / 4.2) + rg.ringIndex * 1.4) * 0.34 * amp
					local tilt = math.rad(2.5 * amp)
					local tx = math.sin(t * 0.8 + rg.ringIndex) * tilt
					local tz = math.cos(t * 0.8 + rg.ringIndex) * tilt
					newPivot = (rg.centerCF + Vector3.new(0, bob, 0)) * CFrame.Angles(tx, yaw, tz)
				end
				for _, pr in rg.parts do
					if pr.part.Parent ~= nil then
						pushMove(partsOut, cframesOut, pr.part, newPivot * pr.relCF)
					end
				end
			end
		end

		-- Constellation sequential drawing & breathing
		local const = state.constellation
		if const then
			local nCount = #const.nodes
			if nCount > 0 then
				local cycle = 6.5
				local prog = ((t % cycle) / cycle) * (nCount + 2)
				local depth = if reduceEffects then 0.2 else 0.6
				for i = 1, nCount do
					local lit = math.clamp(prog - (i - 1), 0, 1)
					local holdFade = if prog > nCount + 1 then (1 - (prog - (nCount + 1))) else 1
					local intensity = lit * math.clamp(holdFade, 0.25, 1)
					local node = const.nodes[i]
					if node and node.Parent ~= nil then
						local orig = getPartOrig(node)
						node.Transparency =
							math.clamp(orig.transparency + (1 - intensity) * depth, 0, 0.92)
					end
					local halo = const.halos[i]
					if halo and halo.Parent ~= nil then
						local orig = getPartOrig(halo)
						halo.Transparency = math.clamp(
							orig.transparency + (1 - intensity) * (depth + 0.12),
							0,
							0.96
						)
					end
				end
			end
			local lCount = #const.lines
			if lCount > 0 then
				local cycle = 6.5
				local prog = ((t % cycle) / cycle) * (lCount + 2)
				local depth = if reduceEffects then 0.2 else 0.55
				for i = 1, lCount do
					local line = const.lines[i]
					if line and line.Parent ~= nil then
						local orig = getPartOrig(line)
						local lit = math.clamp(prog - (i - 0.5), 0, 1)
						line.Transparency = math.clamp(
							orig.transparency + (1 - lit) * depth - awake * 0.08,
							0,
							0.95
						)
					end
				end
			end
		end

		-- Mirror stars twinkling (staggered halves at 30 Hz) & center glow
		updateTwinkleStars(state.stars, t, awake, frame, true)
		if state.mirrorGlow and state.mirrorGlow.Parent ~= nil then
			local orig = getPartOrig(state.mirrorGlow)
			local breath = 0.5 + 0.5 * math.sin(t * (TWO_PI / 4.5))
			state.mirrorGlow.Transparency =
				math.clamp(orig.transparency + (0.22 * (1 - breath) - awake * 0.08) * amp, 0, 0.95)
		end

		updateCrystalPillars(state.pillars, t, awake, 0, 4.5, partsOut, cframesOut)
		updateCrystalPillars(state.deckCrystals, t, awake, 0.14, 3.6, partsOut, cframesOut)

		-- Rare shooting star streaking across the water mirror
		local ss = state.shootingStar
		if ss and ss.part.Parent ~= nil then
			if reduceEffects then
				ss.active = false
				ss.part.Transparency = 1
			elseif not ss.active and elapsedGlobal >= ss.nextTriggerTime then
				ss.active = true
				ss.elapsed = 0
				ss.duration = 0.85
				local ang = math.random() * TWO_PI
				local r = math.min(state.radiusX, state.radiusZ) * 0.65
				local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
				local perp = Vector3.new(-dir.Z, 0, dir.X) * ((math.random() - 0.5) * r * 0.5)
				local y = state.waterY + 0.18
				ss.startPos = Vector3.new(state.centerPos.X, y, state.centerPos.Z) - dir * r + perp
				ss.endPos = Vector3.new(state.centerPos.X, y, state.centerPos.Z) + dir * r + perp
			elseif ss.active then
				ss.elapsed += dt
				local u = math.clamp(ss.elapsed / ss.duration, 0, 1)
				local pos = ss.startPos:Lerp(ss.endPos, u)
				local fade = math.sin(u * math.pi)
				ss.part.Transparency = 1 - fade * 0.85
				if (ss.endPos - ss.startPos).Magnitude > 0.1 then
					pushMove(partsOut, cframesOut, ss.part, CFrame.lookAt(pos, ss.endPos))
				end
				if u >= 1 then
					ss.active = false
					ss.part.Transparency = 1
					ss.nextTriggerTime = elapsedGlobal + 11 + math.random() * 9
				end
			end
		end
	end,
}

-- ----------------------------------------------------------------------------
-- Island 3: Abyss — InstinctPond
-- ----------------------------------------------------------------------------
local AbyssInstinctProfile: PondProfile = {
	islandName = "TrainingIsland_Abyss",
	islandIndex = 3,
	pondName = "InstinctPond",
	statName = "Instinct",

	scan = function(state: PondState)
		clearScanCaches(state)
		local root = state.model

		for _, fishName in
			{ "CosmicFish_Gold", "CosmicFish_Rainbow", "CosmicFish_Nebula", "CosmicFish_Azure" }
		do
			local fm = root:FindFirstChild(fishName)
			if fm and fm:IsA("Model") then
				registerOrbitCreature(state, fm, false, true)
			end
		end

		local centerCF = CFrame.new(state.centerPos.X, state.waterY, state.centerPos.Z)

		for _, d in root:GetDescendants() do
			if d:IsA("BasePart") then
				local name = d.Name
				if string.sub(name, 1, 10) == "SpiralArm_" then
					local orig = getPartOrig(d)
					table.insert(state.spiralArms, {
						part = d,
						relCF = centerCF:ToObjectSpace(orig.cframe),
						orig = orig,
					})
				elseif
					name == "GalaxyCoreOuter"
					or name == "GalaxyCoreMid"
					or name == "GalaxyCoreEye"
					or name == "NebulaOuter"
					or name == "NebulaMid"
				then
					getPartOrig(d)
					table.insert(state.galaxyCoreParts, d)
				elseif name == "GalaxyStar" then
					getPartOrig(d)
					table.insert(state.galaxyStars, d)
				elseif string.sub(name, 1, 14) == "CanopyCrystal_" then
					getPartOrig(d)
					table.insert(state.canopyCrystals, d)
				elseif name == "FallenPetal" then
					getPartOrig(d)
					table.insert(state.petals, d)
				elseif string.sub(name, 1, 13) == "MonolithRune_" then
					getPartOrig(d)
					table.insert(state.runes, d)
				end
			end
		end

		ensureAmbientEmitter(
			state,
			"_AbyssInstinctNebula",
			Color3.fromRGB(220, 125, 255),
			3,
			0.4,
			1.2,
			0.25,
			0.25
		)
	end,

	update = function(state, t, dt, frame, partsOut, cframesOut)
		local amp = getAmpScale()
		local animT = state.animTime
		local awake = state.awake

		updateOrbitCreatures(state, t, dt, false, partsOut, cframesOut)

		local centerCF = CFrame.new(state.centerPos.X, state.waterY, state.centerPos.Z)

		-- Slow cosmic galaxy rotation (~9 deg/s at rest, ~13 deg/s awakened), updated on even frames (30 Hz)
		if frame % 2 == 0 then
			local galaxyYaw = animT * math.rad(9.5)
			local rotCenter = centerCF * CFrame.Angles(0, galaxyYaw, 0)
			for _, pr in state.spiralArms do
				if pr.part.Parent ~= nil then
					pushMove(partsOut, cframesOut, pr.part, rotCenter * pr.relCF)
				end
			end
		end

		-- Galaxy core & nebula pulsing and gentle counter-rotation
		for i, corePart in state.galaxyCoreParts do
			if corePart.Parent ~= nil then
				local orig = getPartOrig(corePart)
				local pulse = 0.5 + 0.5 * math.sin(t * (TWO_PI / 4.2) + i * 0.9)
				corePart.Transparency = math.clamp(
					orig.transparency + (0.2 * (1 - pulse) - awake * 0.08) * amp,
					0,
					0.94
				)
				local deg = if i % 2 == 0 then 12 else -8
				pushMove(
					partsOut,
					cframesOut,
					corePart,
					orig.cframe * CFrame.Angles(0, animT * math.rad(deg), 0)
				)
			end
		end

		-- Galaxy stars twinkling on odd frames (30 Hz)
		if frame % 2 == 1 then
			updateTwinkleStars(state.galaxyStars, t, awake, frame, false)
		end

		-- CrystalTree canopy shimmering in traveling waves
		if frame % 2 == 0 then
			local cCount = #state.canopyCrystals
			for i = 1, cCount do
				local cr = state.canopyCrystals[i]
				if cr.Parent ~= nil then
					local orig = getPartOrig(cr)
					local wave = 0.5
						+ 0.5
							* math.sin(
								t * 1.4
									+ orig.cframe.Position.X * 0.35
									+ orig.cframe.Position.Z * 0.35
							)
					cr.Transparency =
						math.clamp(orig.transparency + (1 - wave) * 0.28 * amp, 0, 0.9)
				end
			end
		end

		-- Fallen petals gentle glow pulse
		for i, petal in state.petals do
			if petal.Parent ~= nil then
				local orig = getPartOrig(petal)
				local wave = 0.5 + 0.5 * math.sin(t * 1.2 + i * 1.3)
				petal.Transparency =
					math.clamp(orig.transparency + (1 - wave) * 0.25 * amp, 0, 0.92)
			end
		end

		-- RuneMonolith_1..3 runes illuminating in sequence
		updateRuneSequence(state.runes, t, awake)
	end,
}

-- ============================================================================
-- Island 4: Celestial — FocusPond & InstinctPond
-- Note: FocusHalos (HubBob), FocusConstellation (HubSpin), FocusBedGlow (HubPulse),
-- WaterGlowAura (HubPulse), and Fireflies (HubBob) are already animated by HubAnimator,
-- so PondAnimator intentionally leaves them untouched to prevent transform fights.
-- ============================================================================

local CelestialFocusProfile: PondProfile = {
	islandName = "TrainingIsland_Celestial",
	islandIndex = 4,
	pondName = "FocusPond",
	statName = "Control",

	scan = function(state: PondState)
		table.clear(state.rippleParts)
		table.clear(state.existingEmitters)
		table.clear(state.pondLights)

		for _, desc in state.model:GetDescendants() do
			if desc:IsA("BasePart") then
				if desc.Name == "Ripple" then
					getPartOrig(desc)
					table.insert(state.rippleParts, desc)
				end
			elseif desc:IsA("ParticleEmitter") then
				if string.sub(desc.Name, 1, 1) ~= "_" then
					getEmitterOrig(desc)
					table.insert(state.existingEmitters, desc)
				end
			elseif desc:IsA("PointLight") then
				getLightOrig(desc)
				table.insert(state.pondLights, desc)
			end
		end

		ensureAmbientEmitter(
			state,
			"_CelestialFocusMotes",
			Color3.fromRGB(255, 224, 152),
			4,
			0.5,
			1.4,
			0.28,
			0.35
		)
	end,

	update = function(state, t, _dt, frame, _partsOut, _cframesOut)
		local amp = getAmpScale()
		local awake = state.awake

		-- Gentle champagne-gold surface ripple breathing (30 Hz on even frames)
		if frame % 2 == 0 then
			local freq = (TWO_PI / 3.4) * (1 + awake * 0.45)
			for i, rp in state.rippleParts do
				if rp.Parent ~= nil then
					local orig = getPartOrig(rp)
					local distFromCenter = (orig.cframe.Position - state.centerPos).Magnitude
					local wave = 0.5 + 0.5 * math.sin(t * freq - distFromCenter * 0.65 + i * 0.08)
					rp.Transparency = math.clamp(
						orig.transparency + (0.24 * (1 - wave) - awake * 0.10) * amp,
						0.08,
						0.94
					)
				end
			end
		end

		-- Existing sparkle emitter ramps smoothly when someone trains Focus
		for _, em in state.existingEmitters do
			if em.Parent ~= nil then
				local orig = getEmitterOrig(em)
				em.Enabled = not reduceEffects
				em.Rate = orig.rate * (1 + awake * 0.85 + state.comboPulse * 1.2)
			end
		end

		-- Pond glow light breathes warmly
		for i, light in state.pondLights do
			if light.Parent ~= nil then
				local orig = getLightOrig(light)
				local pulse = 0.5 + 0.5 * math.sin(t * 1.4 + i)
				light.Brightness = orig.brightness
					* (1 + (pulse * 0.22 + awake * 0.35 + state.comboPulse * 0.4) * amp)
			end
		end
	end,
}

local CelestialInstinctProfile: PondProfile = {
	islandName = "TrainingIsland_Celestial",
	islandIndex = 4,
	pondName = "InstinctPond",
	statName = "Instinct",

	scan = function(state: PondState)
		table.clear(state.creatures)
		table.clear(state.causticParts)
		table.clear(state.pondLights)

		local fishFolder = state.model:FindFirstChild("LegendaryFish")
		if fishFolder then
			for _, child in fishFolder:GetChildren() do
				if child:IsA("Model") and string.sub(child.Name, 1, 13) == "LegendaryFish" then
					registerOrbitCreature(state, child, false, true)
				end
			end
		end

		for _, desc in state.model:GetDescendants() do
			if desc:IsA("BasePart") and desc.Name == "WaterCaustic" then
				getPartOrig(desc)
				table.insert(state.causticParts, desc)
			elseif desc:IsA("PointLight") then
				getLightOrig(desc)
				table.insert(state.pondLights, desc)
			end
		end

		ensureAmbientEmitter(
			state,
			"_CelestialInstinctMotes",
			Color3.fromRGB(246, 178, 214),
			3,
			0.4,
			1.2,
			0.26,
			0.35
		)
	end,

	update = function(state, t, dt, frame, partsOut, cframesOut)
		local amp = getAmpScale()
		local awake = state.awake

		-- 4 legendary fish swimming gracefully inside the Instinct pond (no jump so they stay underwater)
		updateOrbitCreatures(state, t, dt, false, partsOut, cframesOut)

		-- Shimmering surface caustics (30 Hz on odd frames)
		if frame % 2 == 1 then
			local freq = (TWO_PI / 3.8) * (1 + awake * 0.4)
			for i, ca in state.causticParts do
				if ca.Parent ~= nil then
					local orig = getPartOrig(ca)
					local wave = 0.5 + 0.5 * math.sin(t * freq + i * 0.55)
					ca.Transparency = math.clamp(
						orig.transparency + (0.26 * (1 - wave) - awake * 0.08) * amp,
						0.25,
						0.94
					)
				end
			end
		end

		for i, light in state.pondLights do
			if light.Parent ~= nil then
				local orig = getLightOrig(light)
				local pulse = 0.5 + 0.5 * math.sin(t * 1.25 + i * 1.1)
				light.Brightness = orig.brightness
					* (1 + (pulse * 0.24 + awake * 0.35 + state.comboPulse * 0.4) * amp)
			end
		end
	end,
}

-- Profile Registry
local POND_PROFILES: { PondProfile } = {
	ApprenticeFocusProfile,
	ApprenticeInstinctProfile,
	ReefFocusProfile,
	ReefInstinctProfile,
	AbyssFocusProfile,
	AbyssInstinctProfile,
	CelestialFocusProfile,
	CelestialInstinctProfile,
}

local PROFILE_LOOKUP: { [string]: PondProfile } = {}
for _, profile in POND_PROFILES do
	PROFILE_LOOKUP[profile.islandName .. "/" .. profile.pondName] = profile
end

-- ============================================================================
-- Pond Lifecycle, Restoration & Streaming Support
-- ============================================================================

local function updatePondGeometry(state: PondState): ()
	local ws = state.model:FindFirstChild("WaterSurface", true)
		or state.model:FindFirstChild("Water", true)
	if ws and ws:IsA("BasePart") then
		state.waterSurface = ws
		local orig = getPartOrig(ws)
		state.centerPos = orig.cframe.Position
		-- Cylinders laid flat (rotated 90 deg on Z) store height in Size.X and diameter in Size.Y/Z.
		local isFlatCylinder = ws:IsA("Part")
			and (ws :: Part).Shape == Enum.PartType.Cylinder
			and math.abs(orig.cframe.RightVector.Y) > 0.7
		if isFlatCylinder then
			state.waterY = orig.cframe.Position.Y + orig.size.X * 0.5
			state.radiusX = math.max(10, orig.size.Y * 0.5)
			state.radiusZ = math.max(10, orig.size.Z * 0.5)
		else
			state.waterY = orig.cframe.Position.Y
			state.radiusX = math.max(10, orig.size.X * 0.5)
			state.radiusZ = math.max(10, orig.size.Z * 0.5)
		end
	else
		local pivot = state.model:GetPivot()
		state.centerPos = pivot.Position
		state.waterY = pivot.Position.Y
		state.radiusX = 14
		state.radiusZ = 12
	end
end

local function restorePondOriginals(state: PondState): ()
	local parts = state.partsBuf
	local cframes = state.cframesBuf
	table.clear(parts)
	table.clear(cframes)

	for _, desc in state.model:GetDescendants() do
		if desc:IsA("BasePart") then
			local orig = partOrigMap[desc]
			if orig then
				table.insert(parts, desc)
				table.insert(cframes, orig.cframe)
				desc.Size = orig.size
				desc.Transparency = orig.transparency
			end
		elseif desc:IsA("Beam") then
			local orig = beamOrigMap[desc]
			if orig then
				desc.Width0 = orig.width0
				desc.Width1 = orig.width1
				desc.Brightness = orig.brightness
			end
		elseif desc:IsA("PointLight") then
			local orig = lightOrigMap[desc]
			if orig then
				desc.Brightness = orig.brightness
				desc.Range = orig.range
			end
		elseif desc:IsA("ParticleEmitter") then
			local orig = emitterOrigMap[desc]
			if orig then
				desc.Rate = orig.rate
				desc.Enabled = orig.enabled
			end
		end
	end

	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end

	for _, em in state.createdEmitters do
		if em.Parent ~= nil then
			em.Enabled = false
		end
	end
	if state.comboRing and state.comboRing.part.Parent ~= nil then
		state.comboRing.part.Transparency = 1
	end
	if state.splashRing and state.splashRing.Parent ~= nil then
		state.splashRing.Transparency = 1
	end
	if state.shootingStar and state.shootingStar.part.Parent ~= nil then
		state.shootingStar.part.Transparency = 1
		state.shootingStar.active = false
	end
end

local function cleanupPond(key: string): ()
	local state = ponds[key]
	if not state then
		return
	end
	for _, inst in state.createdInstances do
		if inst.Parent ~= nil then
			inst:Destroy()
		end
	end
	ponds[key] = nil
end

local function registerPond(islandModel: Instance, pondModel: Model): ()
	local key = islandModel.Name .. "/" .. pondModel.Name
	local profile = PROFILE_LOOKUP[key]
	if not profile then
		return
	end

	local existing = ponds[key]
	if existing then
		if existing.model == pondModel then
			existing.dirty = true
			return
		else
			cleanupPond(key)
		end
	end

	local state: PondState = {
		key = key,
		profile = profile,
		model = pondModel,
		waterSurface = nil,
		centerPos = Vector3.zero,
		waterY = 11.5,
		radiusX = 14,
		radiusZ = 12,

		active = false,
		awake = 0,
		animTime = 0,
		comboPulse = 0,
		dirty = true,
		lastScanTime = 0,

		createdInstances = {},
		createdEmitters = {},
		comboRing = nil,
		splashRing = nil,
		splashEmitter = nil,
		splashTimer = 0,
		shootingStar = nil,
		jumpState = {
			active = false,
			creatureIndex = 1,
			elapsed = 0,
			duration = 1.15,
			nextTriggerTime = elapsedGlobal + 10 + math.random() * 10,
			splashedOut = false,
			splashedIn = false,
		},

		rings = {},
		creatures = {},
		buoys = {},
		hexCells = {},
		pillars = {},
		verticalBeams = {},
		existingEmitters = {},
		stars = {},
		petals = {},
		runes = {},
		swayGroups = {},
		lanterns = {},
		targetShells = {},
		clam = nil,
		constellation = nil,
		mirrorGlow = nil,
		deckCrystals = {},
		spiralArms = {},
		galaxyCoreParts = {},
		galaxyStars = {},
		canopyCrystals = {},
		fireflyParts = {},
		fireflyEmitters = {},
		pondLights = {},
		rippleParts = {},
		causticParts = {},

		partsBuf = {},
		cframesBuf = {},
	}

	updatePondGeometry(state)
	ponds[key] = state

	pondModel.DescendantAdded:Connect(function(desc: Instance)
		if string.sub(desc.Name, 1, 5) == "_Pond" or desc.Name == "_CosmicFishTrail" then
			return
		end
		if ponds[key] == state then
			state.dirty = true
		end
	end)

	pondModel.DescendantRemoving:Connect(function(desc: Instance)
		if string.sub(desc.Name, 1, 5) == "_Pond" or desc.Name == "_CosmicFishTrail" then
			return
		end
		if ponds[key] == state then
			state.dirty = true
		end
	end)

	pondModel.AncestryChanged:Connect(function(_, parent: Instance?)
		if parent == nil and ponds[key] == state then
			cleanupPond(key)
		end
	end)
end

local function scanTrainingIslandsFolder(folder: Instance): ()
	for _, island in folder:GetChildren() do
		for _, child in island:GetChildren() do
			if
				child:IsA("Model") and (child.Name == "FocusPond" or child.Name == "InstinctPond")
			then
				registerPond(island, child)
			end
		end
	end
end

local function hookTrainingIslands(folder: Instance): ()
	scanTrainingIslandsFolder(folder)

	folder.ChildAdded:Connect(function(island: Instance)
		for _, child in island:GetChildren() do
			if
				child:IsA("Model") and (child.Name == "FocusPond" or child.Name == "InstinctPond")
			then
				registerPond(island, child)
			end
		end
		island.ChildAdded:Connect(function(child: Instance)
			if
				child:IsA("Model") and (child.Name == "FocusPond" or child.Name == "InstinctPond")
			then
				registerPond(island, child)
			end
		end)
	end)

	for _, island in folder:GetChildren() do
		island.ChildAdded:Connect(function(child: Instance)
			if
				child:IsA("Model") and (child.Name == "FocusPond" or child.Name == "InstinctPond")
			then
				registerPond(island, child)
			end
		end)
	end
end

-- ============================================================================
-- Training Spot Reactivity & Local Combo Pulse
-- ============================================================================

local function isPlayerTrainingAtPond(player: Player, profile: PondProfile): boolean
	local pStat = getStringAttr(player, "TrainingStat", "")
	if pStat ~= profile.statName then
		return false
	end
	local char = player.Character
	if not char then
		return false
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return false
	end
	local hrpPos = hrp.Position

	for spot in trainingSpots do
		if spot.Parent ~= nil then
			local spotIsland = getNumberAttr(spot, "TrainingIsland", -1)
			local spotStat = getStringAttr(spot, "TrainingStat", "")
			if spotIsland == profile.islandIndex and spotStat == profile.statName then
				if (spot.Position - hrpPos).Magnitude <= TRAIN_SPOT_RADIUS then
					return true
				end
			end
		end
	end

	return false
end

local function isAnyoneTrainingAtPond(profile: PondProfile): boolean
	for _, player in Players:GetPlayers() do
		if isPlayerTrainingAtPond(player, profile) then
			return true
		end
	end
	return false
end

local function triggerComboPulseForLocalPlayer(): ()
	if reduceEffects then
		return
	end
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	for _, state in ponds do
		if state.active and isPlayerTrainingAtPond(localPlayer, state.profile) then
			state.comboPulse = 1.0
			local pool = ensureComboRing(state)
			if pool then
				pool.emitter:Emit(10)
			end
			break
		end
	end
end

local function updateComboAndSplashVisuals(state: PondState, dt: number): ()
	-- Combo ring expansion
	if state.comboPulse > 0 then
		state.comboPulse = math.max(0, state.comboPulse - dt / COMBO_PULSE_DURATION)
		local pool = state.comboRing
		if pool and pool.part.Parent ~= nil then
			if reduceEffects or state.comboPulse <= 0.001 then
				pool.part.Transparency = 1
			else
				local u = 1 - state.comboPulse
				local maxDiam = math.min(state.radiusX, state.radiusZ) * 1.5
				local diam = 4 + u * (maxDiam - 4)
				pool.part.Size = Vector3.new(0.16, diam, diam)
				pool.part.CFrame = CFrame.new(
					state.centerPos.X,
					state.waterY + 0.14,
					state.centerPos.Z
				) * CFrame.Angles(0, 0, math.rad(90))
				pool.part.Transparency = math.clamp(0.2 + u * 0.8, 0, 1)
			end
		end
	end

	-- Jump splash ring expansion
	if state.splashTimer > 0 then
		state.splashTimer = math.max(0, state.splashTimer - dt)
		local ring = state.splashRing
		if ring and ring.Parent ~= nil then
			if reduceEffects or state.splashTimer <= 0.001 then
				ring.Transparency = 1
			else
				local u = 1 - (state.splashTimer / 0.75)
				local diam = 1.6 + u * 4.2
				ring.Size = Vector3.new(0.12, diam, diam)
				ring.Transparency = math.clamp(0.25 + u * 0.75, 0, 1)
			end
		end
	end
end

local function applyReduceEffectsToCreatedEmitters(): ()
	for _, state in ponds do
		for _, em in state.createdEmitters do
			if em.Parent ~= nil then
				if em.Name ~= "_PondComboBurst" and em.Name ~= "_PondSplashDrops" then
					em.Enabled = state.active and not reduceEffects
				end
			end
		end
	end
end

-- ============================================================================
-- Main Heartbeat Loop (Single Loop for Entire Module)
-- ============================================================================

local function onHeartbeat(dt: number): ()
	local clampedDt = math.min(dt, 0.1)
	elapsedGlobal += clampedDt
	frameCounter += 1

	-- Light periodic rescan for StreamingEnabled safety
	if elapsedGlobal >= nextRescanTime then
		nextRescanTime = elapsedGlobal + RESCAN_INTERVAL
		local ti = workspace:FindFirstChild(TRAINING_ISLANDS_NAME)
		if ti then
			scanTrainingIslandsFolder(ti)
		end
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local camPos = camera.CFrame.Position

	for key, state in ponds do
		if state.model.Parent == nil then
			cleanupPond(key)
			continue
		end

		-- Refresh geometry if WaterSurface streamed in late
		if state.waterSurface == nil or state.waterSurface.Parent == nil then
			updatePondGeometry(state)
		end

		local dist = (state.centerPos - camPos).Magnitude
		if dist > ACTIVE_RADIUS then
			if state.active then
				state.active = false
				state.awake = 0
				state.comboPulse = 0
				restorePondOriginals(state)
			end
			continue
		end

		if not state.active then
			state.active = true
			state.dirty = true
			applyReduceEffectsToCreatedEmitters()
		end

		-- Re-scan pond contents if dirty (debounced to at most once every 0.4s)
		if state.dirty and (elapsedGlobal - state.lastScanTime) >= 0.4 then
			state.dirty = false
			state.lastScanTime = elapsedGlobal
			updatePondGeometry(state)
			state.profile.scan(state)
			applyReduceEffectsToCreatedEmitters()
		end

		-- Training reactivity: smooth 1.5s transition when anyone trains here
		local someoneTraining = isAnyoneTrainingAtPond(state.profile)
		local targetAwake = if someoneTraining then 1 else 0
		local step = clampedDt / AWAKEN_DURATION
		if state.awake < targetAwake then
			state.awake = math.min(targetAwake, state.awake + step)
		elseif state.awake > targetAwake then
			state.awake = math.max(targetAwake, state.awake - step)
		end

		-- Integrated animation time prevents phase jumps when waking/sleeping
		local speedMult = 1 + state.awake * 0.45
		if reduceEffects then
			speedMult = 1 + state.awake * 0.2
		end
		state.animTime += clampedDt * speedMult

		-- Update created ambient emitter rates
		for _, em in state.createdEmitters do
			if
				em.Parent ~= nil
				and em.Name ~= "_PondComboBurst"
				and em.Name ~= "_PondSplashDrops"
			then
				em.Enabled = not reduceEffects
				local orig = getEmitterOrig(em)
				em.Rate = orig.rate * (1 + state.awake * 0.7)
			end
		end

		-- Run pond-specific animation profile
		table.clear(state.partsBuf)
		table.clear(state.cframesBuf)

		state.profile.update(
			state,
			elapsedGlobal,
			clampedDt,
			frameCounter,
			state.partsBuf,
			state.cframesBuf
		)
		updateComboAndSplashVisuals(state, clampedDt)

		if #state.partsBuf > 0 then
			workspace:BulkMoveTo(
				state.partsBuf,
				state.cframesBuf,
				Enum.BulkMoveMode.FireCFrameChanged
			)
		end
	end
end

-- ============================================================================
-- Feature Module Entry Point
-- ============================================================================

local PondAnimator = {
	order = 115,
}

function PondAnimator.start(): ()
	if started then
		return
	end
	started = true

	-- Track local player's ReduceEffects and TrainingCombo
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		reduceEffects = localPlayer:GetAttribute("ReduceEffects") == true
		lastLocalCombo = getNumberAttr(localPlayer, "TrainingCombo", 0)

		localPlayer:GetAttributeChangedSignal("ReduceEffects"):Connect(function()
			reduceEffects = localPlayer:GetAttribute("ReduceEffects") == true
			applyReduceEffectsToCreatedEmitters()
		end)

		localPlayer:GetAttributeChangedSignal("TrainingCombo"):Connect(function()
			local current = getNumberAttr(localPlayer, "TrainingCombo", 0)
			if current > lastLocalCombo then
				triggerComboPulseForLocalPlayer()
			end
			lastLocalCombo = current
		end)
	end

	-- Track TrainingSpot tags
	for _, inst in CollectionService:GetTagged(TRAINING_SPOT_TAG) do
		if inst:IsA("BasePart") then
			trainingSpots[inst] = true
		end
	end
	CollectionService:GetInstanceAddedSignal(TRAINING_SPOT_TAG):Connect(function(inst: Instance)
		if inst:IsA("BasePart") then
			trainingSpots[inst] = true
		end
	end)
	CollectionService:GetInstanceRemovedSignal(TRAINING_SPOT_TAG):Connect(function(inst: Instance)
		if inst:IsA("BasePart") then
			trainingSpots[inst] = nil
		end
	end)

	-- Hook TrainingIslands (streaming-safe, no blocking WaitForChild)
	local ti = workspace:FindFirstChild(TRAINING_ISLANDS_NAME)
	if ti then
		hookTrainingIslands(ti)
	end
	workspace.ChildAdded:Connect(function(child: Instance)
		if child.Name == TRAINING_ISLANDS_NAME then
			hookTrainingIslands(child)
		end
	end)

	RunService.Heartbeat:Connect(onHeartbeat)
end

return PondAnimator
