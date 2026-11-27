--!strict
--[[
	VfxKit.luau
	Suggested Studio path: ReplicatedStorage/Shared/Vfx/VfxKit
	Rojo path: src/shared/Vfx/VfxKit.luau

	Integration:
	- Core client VFX engine with instance pooling (Parts, Attachments, ParticleEmitters,
	  Beams, Billboard fake-bloom glows, and a strictly capped pool of 4 dynamic PointLights).
	- Automatically listens to Players.LocalPlayer:GetAttributeChangedSignal("ReduceEffects").
	- Enforces mobile particle budgets (~120 normal, ~250 peak for tier 5 events) and
	  kid-friendly accessibility limits (max 3 screen flashes/sec, max alpha 0.6, max
	  flash duration 0.15s, max camera shake 0.6 studs).
	- Uses a single central RunService.Heartbeat loop for all active animations/releases.

	Quick usage:
	  local VfxKit = require(ReplicatedStorage.Shared.Vfx.VfxKit)
	  VfxKit.burst(pos, "stars", 0.8, 4)
	  VfxKit.ring(pos, Color3.fromRGB(0, 200, 170), 6, 0.7, 0.8, 2)
	  VfxKit.pillarOfLight(pos, Color3.fromRGB(255, 206, 68), 32, 3.5, 2.2, 1, 5)
	  VfxKit.floatingText(pos, "PERFEITO!", Color3.fromRGB(255, 232, 92))
	  VfxKit.screenFlash(Color3.fromRGB(255, 244, 196), 0.45, 0.12)
	  VfxKit.cameraShake(0.35, 0.25)
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Palette = require(script.Parent.Palette)

export type BurstPreset =
	"sparks"
	| "stars"
	| "splash"
	| "bubbles"
	| "petals"
	| "electric"
	| "cosmic"
	| "magma"
	| "abyss"
	| "celestial"
	| "confetti"
	| "coins"
	| "smoke"

export type StopHandle = {
	stop: () -> (),
}

export type VfxStats = {
	estimatedLiveParticles: number,
	activeDynamicLights: number,
	activeTasks: number,
	pooledParts: number,
	pooledEmitters: number,
	pooledBeams: number,
	reducedEffects: boolean,
}

type PresetConfig = {
	texture: string,
	colorA: Color3,
	colorB: Color3,
	baseCount: number,
	sizeStart: number,
	sizeEnd: number,
	speedMin: number,
	speedMax: number,
	lifeMin: number,
	lifeMax: number,
	drag: number,
	accel: Vector3,
	lightEmission: number,
	spread: Vector2,
	rotSpeed: number,
}

type ActiveTask = {
	elapsed: number,
	duration: number,
	update: (alpha: number, dt: number) -> (),
	cleanup: () -> (),
	done: boolean,
}

type ActiveLight = {
	light: PointLight,
	part: Part,
	expiresAt: number,
	baseBrightness: number,
}

type ActiveShake = {
	amount: number,
	elapsed: number,
	duration: number,
	seed: number,
}

local VfxKit = {}

-- ============================================================================
-- TEXTURES (built-in Roblox textures + optional custom slots with safe fallback)
-- NOTE: Roblox built-in particle textures use .dds (empty "" also falls back
-- cleanly to Roblox's default soft glow particle).
-- ============================================================================

local TEXTURES = {
	sparkles = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	softGlow = "", -- Native soft circular particle fallback
	-- Optional custom textures (works cleanly without replacing)
	customStar = "rbxassetid://0 -- TROCAR: estrela 4 pontas suave branca (256x256)",
	customRing = "rbxassetid://0 -- TROCAR: anel circular fino branco com glow (256x256)",
	customPetal = "rbxassetid://0 -- TROCAR: pétala de flor branca estilizada (128x128)",
	customRune = "rbxassetid://0 -- TROCAR: runa mágica simples branca (128x128)",
}

VfxKit.TEXTURES = TEXTURES

local function resolveTexture(tex: string, fallback: string): string
	if tex == "" then
		return ""
	end
	if string.sub(tex, 1, 11) == "rbxasset://" then
		return tex
	end
	local digits = string.match(tex, "rbxassetid://(%d+)")
	if digits and digits ~= "0" then
		return "rbxassetid://" .. digits
	end
	return fallback
end

-- ============================================================================
-- BUDGETS & ACCESSIBILITY CONSTANTS
-- ============================================================================

local NORMAL_PARTICLE_BUDGET = 120
local PEAK_PARTICLE_BUDGET = 250
local MAX_DYNAMIC_LIGHTS = 4
local MAX_FLASHES_PER_SECOND = 3
local MAX_FLASH_ALPHA = 0.60
local MAX_FLASH_DURATION = 0.15
local MAX_CAMERA_SHAKE = 0.60
local CULL_DISTANCE_SQ = 160 * 160

local MAX_PART_POOL = 90
local MAX_EMITTER_POOL = 36
local MAX_BEAM_POOL = 24
local MAX_BILLBOARD_POOL = 24

local PRESETS: { [string]: PresetConfig } = {
	sparks = {
		texture = TEXTURES.sparkles,
		colorA = Palette.World.CrystalCyan,
		colorB = Palette.World.PureWhite,
		baseCount = 14,
		sizeStart = 0.45,
		sizeEnd = 0.0,
		speedMin = 6,
		speedMax = 15,
		lifeMin = 0.35,
		lifeMax = 0.75,
		drag = 3.5,
		accel = Vector3.new(0, -10, 0),
		lightEmission = 1,
		spread = Vector2.new(180, 180),
		rotSpeed = 140,
	},
	stars = {
		texture = TEXTURES.customStar,
		colorA = Palette.World.Gold,
		colorB = Palette.World.WarmGold,
		baseCount = 16,
		sizeStart = 0.65,
		sizeEnd = 0.05,
		speedMin = 5,
		speedMax = 14,
		lifeMin = 0.5,
		lifeMax = 1.0,
		drag = 2.5,
		accel = Vector3.new(0, 2, 0),
		lightEmission = 1,
		spread = Vector2.new(180, 180),
		rotSpeed = 180,
	},
	splash = {
		texture = TEXTURES.smoke,
		colorA = Color3.fromRGB(168, 244, 255),
		colorB = Color3.fromRGB(240, 252, 255),
		baseCount = 16,
		sizeStart = 0.75,
		sizeEnd = 1.45,
		speedMin = 8,
		speedMax = 17,
		lifeMin = 0.35,
		lifeMax = 0.7,
		drag = 1.2,
		accel = Vector3.new(0, -34, 0),
		lightEmission = 0.2,
		spread = Vector2.new(55, 55),
		rotSpeed = 90,
	},
	bubbles = {
		texture = TEXTURES.softGlow,
		colorA = Color3.fromRGB(142, 240, 255),
		colorB = Color3.fromRGB(235, 252, 255),
		baseCount = 12,
		sizeStart = 0.38,
		sizeEnd = 0.55,
		speedMin = 2,
		speedMax = 6,
		lifeMin = 0.6,
		lifeMax = 1.3,
		drag = 1.8,
		accel = Vector3.new(0, 6, 0),
		lightEmission = 0.45,
		spread = Vector2.new(45, 45),
		rotSpeed = 0,
	},
	petals = {
		texture = TEXTURES.customPetal,
		colorA = Palette.World.BlossomPink,
		colorB = Palette.World.BlossomLilac,
		baseCount = 14,
		sizeStart = 0.42,
		sizeEnd = 0.25,
		speedMin = 2,
		speedMax = 7,
		lifeMin = 0.9,
		lifeMax = 1.8,
		drag = 2.2,
		accel = Vector3.new(0.8, -3.5, 0.5),
		lightEmission = 0.35,
		spread = Vector2.new(140, 140),
		rotSpeed = 120,
	},
	electric = {
		texture = TEXTURES.sparkles,
		colorA = Color3.fromRGB(82, 224, 255),
		colorB = Color3.fromRGB(255, 238, 96),
		baseCount = 18,
		sizeStart = 0.58,
		sizeEnd = 0.0,
		speedMin = 10,
		speedMax = 22,
		lifeMin = 0.25,
		lifeMax = 0.55,
		drag = 5.0,
		accel = Vector3.new(0, 2, 0),
		lightEmission = 1,
		spread = Vector2.new(180, 180),
		rotSpeed = 240,
	},
	cosmic = {
		texture = TEXTURES.sparkles,
		colorA = Color3.fromRGB(168, 96, 255),
		colorB = Color3.fromRGB(112, 238, 255),
		baseCount = 18,
		sizeStart = 0.62,
		sizeEnd = 0.08,
		speedMin = 4,
		speedMax = 12,
		lifeMin = 0.7,
		lifeMax = 1.4,
		drag = 1.8,
		accel = Vector3.new(0, 3.5, 0),
		lightEmission = 1,
		spread = Vector2.new(180, 180),
		rotSpeed = 150,
	},
	magma = {
		texture = TEXTURES.fire,
		colorA = Color3.fromRGB(255, 118, 42),
		colorB = Color3.fromRGB(255, 224, 82),
		baseCount = 18,
		sizeStart = 0.85,
		sizeEnd = 0.1,
		speedMin = 6,
		speedMax = 16,
		lifeMin = 0.45,
		lifeMax = 0.95,
		drag = 1.6,
		accel = Vector3.new(0, 8, 0),
		lightEmission = 1,
		spread = Vector2.new(95, 95),
		rotSpeed = 110,
	},
	abyss = {
		texture = TEXTURES.softGlow,
		colorA = Color3.fromRGB(56, 134, 255),
		colorB = Color3.fromRGB(48, 236, 214),
		baseCount = 16,
		sizeStart = 0.65,
		sizeEnd = 0.15,
		speedMin = 3,
		speedMax = 10,
		lifeMin = 0.65,
		lifeMax = 1.3,
		drag = 2.0,
		accel = Vector3.new(0, 4.5, 0),
		lightEmission = 0.9,
		spread = Vector2.new(140, 140),
		rotSpeed = 80,
	},
	celestial = {
		texture = TEXTURES.sparkles,
		colorA = Color3.fromRGB(255, 224, 110),
		colorB = Color3.fromRGB(255, 174, 234),
		baseCount = 20,
		sizeStart = 0.72,
		sizeEnd = 0.05,
		speedMin = 4,
		speedMax = 13,
		lifeMin = 0.75,
		lifeMax = 1.45,
		drag = 2.0,
		accel = Vector3.new(0, 5, 0),
		lightEmission = 1,
		spread = Vector2.new(180, 180),
		rotSpeed = 160,
	},
	confetti = {
		texture = TEXTURES.softGlow,
		colorA = Palette.World.Gold,
		colorB = Palette.World.BlossomPink,
		baseCount = 20,
		sizeStart = 0.48,
		sizeEnd = 0.36,
		speedMin = 10,
		speedMax = 20,
		lifeMin = 0.9,
		lifeMax = 1.7,
		drag = 2.4,
		accel = Vector3.new(0, -18, 0),
		lightEmission = 0.5,
		spread = Vector2.new(75, 75),
		rotSpeed = 220,
	},
	coins = {
		texture = TEXTURES.sparkles,
		colorA = Palette.World.Gold,
		colorB = Palette.World.WarmGold,
		baseCount = 10,
		sizeStart = 0.5,
		sizeEnd = 0.15,
		speedMin = 6,
		speedMax = 13,
		lifeMin = 0.5,
		lifeMax = 0.9,
		drag = 1.4,
		accel = Vector3.new(0, -24, 0),
		lightEmission = 0.85,
		spread = Vector2.new(55, 55),
		rotSpeed = 200,
	},
	smoke = {
		texture = TEXTURES.smoke,
		colorA = Color3.fromRGB(230, 246, 255),
		colorB = Color3.fromRGB(190, 220, 238),
		baseCount = 10,
		sizeStart = 1.1,
		sizeEnd = 2.6,
		speedMin = 2,
		speedMax = 6,
		lifeMin = 0.6,
		lifeMax = 1.2,
		drag = 2.2,
		accel = Vector3.new(0, 3, 0),
		lightEmission = 0.15,
		spread = Vector2.new(120, 120),
		rotSpeed = 40,
	},
}

-- ============================================================================
-- INTERNAL STATE, POOLING & CENTRAL LOOP
-- ============================================================================

local initialized = false
local reducedEffects = false
local reduceCallbacks: { (boolean) -> () } = {}

local vfxFolder: Folder? = nil
local flashGui: ScreenGui? = nil
local flashFrame: Frame? = nil
local flashTween: Tween? = nil
local flashTimestamps: { number } = {}

local partPool: { Part } = {}
local emitterPool: { { part: Part, att: Attachment, emitter: ParticleEmitter } } = {}
local beamPool: { { partA: Part, partB: Part, attA: Attachment, attB: Attachment, beam: Beam } } =
	{}
local billboardPool: { { part: Part, gui: BillboardGui, frame: Frame, label: TextLabel } } = {}

local activeTasks: { ActiveTask } = {}
local activeLights: { ActiveLight } = {}
local activeShakes: { ActiveShake } = {}
local estimatedParticles = 0
local particleRecords: { { count: number, expiresAt: number } } = {}

local heartbeatConn: RBXScriptConnection? = nil
local reduceConn: RBXScriptConnection? = nil
local shakeRenderBound = false
local lastHumanoidShakeOffset = Vector3.zero
local lastCameraShakeOffset = CFrame.identity
local lastAppliedCamCf: CFrame? = nil
local rng = Random.new()

-- Temporary post-processing tracking (never leaves permanent FX behind)
local activeTempPostFx: { Instance } = {}

local function refreshReduceEffects()
	local lp = Players.LocalPlayer
	local nextState = if lp then (lp:GetAttribute("ReduceEffects") == true) else false
	if nextState == reducedEffects then
		return
	end
	reducedEffects = nextState

	if reducedEffects then
		-- Immediately clear shakes, active flash, and temporary post-FX when user turns on ReduceEffects
		table.clear(activeShakes)
		if flashFrame then
			flashFrame.BackgroundTransparency = 1
		end
		for i = #activeTempPostFx, 1, -1 do
			local fx = activeTempPostFx[i]
			if fx and fx.Parent then
				fx:Destroy()
			end
			table.remove(activeTempPostFx, i)
		end
	end

	for _, cb in ipairs(reduceCallbacks) do
		task.spawn(cb, reducedEffects)
	end
end

local function isWithinCameraDistance(pos: Vector3): boolean
	local cam = Workspace.CurrentCamera
	if not cam then
		return true
	end
	local diff = pos - cam.CFrame.Position
	return diff:Dot(diff) <= CULL_DISTANCE_SQ
end

local function reserveParticles(requested: number, allowPeak: boolean): number
	local now = os.clock()
	-- Prune expired particle estimates
	for i = #particleRecords, 1, -1 do
		if particleRecords[i].expiresAt <= now then
			estimatedParticles = math.max(0, estimatedParticles - particleRecords[i].count)
			table.remove(particleRecords, i)
		end
	end

	local budget = if allowPeak then PEAK_PARTICLE_BUDGET else NORMAL_PARTICLE_BUDGET
	if reducedEffects then
		budget = math.floor(budget * 0.35)
	end
	local available = math.max(0, budget - estimatedParticles)
	local granted = math.min(math.max(0, math.floor(requested)), available)
	return granted
end

local function commitParticles(count: number, lifetime: number)
	if count <= 0 then
		return
	end
	estimatedParticles += count
	table.insert(particleRecords, {
		count = count,
		expiresAt = os.clock() + math.max(0.2, lifetime),
	})
end

local function acquirePart(): Part
	local p = table.remove(partPool)
	if p and p.Parent then
		p.Transparency = 0
		p.Shape = Enum.PartType.Block
		p.Material = Enum.Material.Neon
		p.Reflectance = 0
		return p
	end
	local created = Instance.new("Part")
	created.Name = "VfxPooledPart"
	created.Anchored = true
	created.CanCollide = false
	created.CanTouch = false
	created.CanQuery = false
	created.CastShadow = false
	created.TopSurface = Enum.SurfaceType.Smooth
	created.BottomSurface = Enum.SurfaceType.Smooth
	created.Material = Enum.Material.Neon
	created.Size = Vector3.new(1, 1, 1)
	created.Parent = vfxFolder
	return created
end

local function releasePart(p: Part)
	if not p.Parent then
		return
	end
	-- Clear any temporary SpecialMesh if added
	local mesh = p:FindFirstChildOfClass("SpecialMesh")
	if mesh then
		mesh:Destroy()
	end
	p.Transparency = 1
	p.CFrame = CFrame.new(0, -5000, 0)
	if #partPool < MAX_PART_POOL then
		p.Parent = vfxFolder
		table.insert(partPool, p)
	else
		p:Destroy()
	end
end

local function acquireEmitterUnit(): { part: Part, att: Attachment, emitter: ParticleEmitter }
	local unit = table.remove(emitterPool)
	if unit and unit.part.Parent and unit.emitter.Parent then
		unit.emitter.Enabled = false
		return unit
	end
	local p = Instance.new("Part")
	p.Name = "VfxEmitterHost"
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)

	local att = Instance.new("Attachment")
	att.Parent = p

	local em = Instance.new("ParticleEmitter")
	em.Enabled = false
	em.Rate = 0
	em.Parent = att

	p.Parent = vfxFolder
	return { part = p, att = att, emitter = em }
end

local function releaseEmitterUnit(unit: { part: Part, att: Attachment, emitter: ParticleEmitter })
	if not unit.part.Parent then
		return
	end
	unit.emitter.Enabled = false
	unit.emitter.Rate = 0
	unit.emitter.Parent = unit.att
	unit.part.CFrame = CFrame.new(0, -5000, 0)
	if #emitterPool < MAX_EMITTER_POOL then
		table.insert(emitterPool, unit)
	else
		unit.part:Destroy()
	end
end

local function acquireBeamUnit(): {
	partA: Part,
	partB: Part,
	attA: Attachment,
	attB: Attachment,
	beam: Beam,
}
	local unit = table.remove(beamPool)
	if unit and unit.partA.Parent and unit.partB.Parent and unit.beam.Parent then
		unit.beam.Enabled = true
		return unit
	end
	local pA = Instance.new("Part")
	pA.Name = "VfxBeamA"
	pA.Anchored = true
	pA.CanCollide = false
	pA.CanTouch = false
	pA.CanQuery = false
	pA.CastShadow = false
	pA.Transparency = 1
	pA.Size = Vector3.new(0.2, 0.2, 0.2)

	local pB = pA:Clone()
	pB.Name = "VfxBeamB"

	local attA = Instance.new("Attachment")
	attA.Parent = pA
	local attB = Instance.new("Attachment")
	attB.Parent = pB

	local b = Instance.new("Beam")
	b.Attachment0 = attA
	b.Attachment1 = attB
	b.FaceCamera = true
	b.LightEmission = 1
	b.LightInfluence = 0
	b.Parent = pA

	pA.Parent = vfxFolder
	pB.Parent = vfxFolder
	return { partA = pA, partB = pB, attA = attA, attB = attB, beam = b }
end

local function releaseBeamUnit(unit: {
	partA: Part,
	partB: Part,
	attA: Attachment,
	attB: Attachment,
	beam: Beam,
})
	if not unit.partA.Parent then
		return
	end
	unit.beam.Enabled = false
	unit.partA.CFrame = CFrame.new(0, -5000, 0)
	unit.partB.CFrame = CFrame.new(0, -5000, 0)
	if #beamPool < MAX_BEAM_POOL then
		table.insert(beamPool, unit)
	else
		unit.partA:Destroy()
		unit.partB:Destroy()
	end
end

local function acquireBillboardUnit(): { part: Part, gui: BillboardGui, frame: Frame, label: TextLabel }
	local unit = table.remove(billboardPool)
	if unit and unit.part.Parent and unit.gui.Parent then
		unit.gui.Enabled = true
		return unit
	end

	local p = Instance.new("Part")
	p.Name = "VfxBillboardHost"
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)

	local gui = Instance.new("BillboardGui")
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.fromScale(4, 4)
	gui.Adornee = p

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = ""
	label.TextStrokeTransparency = 0.25
	label.TextStrokeColor3 = Color3.fromRGB(18, 22, 36)
	label.Parent = frame

	gui.Parent = p
	p.Parent = vfxFolder
	return { part = p, gui = gui, frame = frame, label = label }
end

local function releaseBillboardUnit(unit: {
	part: Part,
	gui: BillboardGui,
	frame: Frame,
	label: TextLabel,
})
	if not unit.part.Parent then
		return
	end
	unit.gui.Enabled = false
	unit.gui.Adornee = unit.part
	unit.label.Text = ""
	unit.frame.BackgroundTransparency = 1
	unit.part.CFrame = CFrame.new(0, -5000, 0)
	if #billboardPool < MAX_BILLBOARD_POOL then
		table.insert(billboardPool, unit)
	else
		unit.part:Destroy()
	end
end

local function registerTask(
	duration: number,
	updateFn: (number, number) -> (),
	cleanupFn: () -> ()
): ActiveTask
	local t: ActiveTask = {
		elapsed = 0,
		duration = math.max(0.02, duration),
		update = updateFn,
		cleanup = cleanupFn,
		done = false,
	}
	table.insert(activeTasks, t)
	return t
end

-- Camera shake runner bound at Camera.Value + 1 ONLY while active
local function getLocalHumanoid(): Humanoid?
	local lp = Players.LocalPlayer
	if not lp or not lp.Character then
		return nil
	end
	return lp.Character:FindFirstChildOfClass("Humanoid")
end

local function clearAppliedShakeOffsets()
	local hum = getLocalHumanoid()
	if hum and lastHumanoidShakeOffset ~= Vector3.zero then
		hum.CameraOffset -= lastHumanoidShakeOffset
	end
	lastHumanoidShakeOffset = Vector3.zero

	local cam = Workspace.CurrentCamera
	if
		cam
		and lastCameraShakeOffset ~= CFrame.identity
		and lastAppliedCamCf ~= nil
		and cam.CFrame:FuzzyEq(lastAppliedCamCf, 1e-3)
	then
		cam.CFrame = cam.CFrame * lastCameraShakeOffset:Inverse()
	end
	lastCameraShakeOffset = CFrame.identity
	lastAppliedCamCf = nil
end

local function unbindShakeIfIdle()
	if shakeRenderBound and (#activeShakes == 0 or reducedEffects) then
		clearAppliedShakeOffsets()
		RunService:UnbindFromRenderStep("LegendaryCatch_VfxCameraShake")
		shakeRenderBound = false
	end
end

local function ensureShakeRenderStep()
	if shakeRenderBound then
		return
	end
	shakeRenderBound = true
	RunService:BindToRenderStep(
		"LegendaryCatch_VfxCameraShake",
		Enum.RenderPriority.Camera.Value + 1,
		function(dt: number)
			if reducedEffects or #activeShakes == 0 then
				unbindShakeIfIdle()
				return
			end

			local totalOffset = Vector3.zero
			local now = os.clock()
			for i = #activeShakes, 1, -1 do
				local sh = activeShakes[i]
				sh.elapsed += dt
				if sh.elapsed >= sh.duration then
					table.remove(activeShakes, i)
				else
					local decay = 1 - (sh.elapsed / sh.duration)
					local mag = sh.amount * decay * decay
					local nx = math.noise(now * 24, sh.seed, 0.1)
					local ny = math.noise(now * 24, sh.seed + 7.3, 0.2)
					local nz = math.noise(now * 24, sh.seed + 13.7, 0.3)
					totalOffset += Vector3.new(nx, ny, nz) * mag * 2
				end
			end

			-- Strict accessibility clamp: never exceed 0.6 studs
			if totalOffset.Magnitude > MAX_CAMERA_SHAKE then
				totalOffset = totalOffset.Unit * MAX_CAMERA_SHAKE
			end

			local cam = Workspace.CurrentCamera
			if cam and cam.CameraType == Enum.CameraType.Scriptable then
				-- Restore any lingering Humanoid offset when transitioning from Custom -> Scriptable
				if lastHumanoidShakeOffset ~= Vector3.zero then
					local hum = getLocalHumanoid()
					if hum then
						hum.CameraOffset -= lastHumanoidShakeOffset
					end
					lastHumanoidShakeOffset = Vector3.zero
				end
				-- Only undo previous scriptable offset if nothing else overwrote cam.CFrame
				if
					lastCameraShakeOffset ~= CFrame.identity
					and lastAppliedCamCf ~= nil
					and cam.CFrame:FuzzyEq(lastAppliedCamCf, 1e-3)
				then
					cam.CFrame = cam.CFrame * lastCameraShakeOffset:Inverse()
				end
				local nextCf = CFrame.new(totalOffset)
				local applied = cam.CFrame * nextCf
				cam.CFrame = applied
				lastCameraShakeOffset = nextCf
				lastAppliedCamCf = applied
			else
				lastCameraShakeOffset = CFrame.identity
				lastAppliedCamCf = nil
				local hum = getLocalHumanoid()
				if hum then
					hum.CameraOffset = (hum.CameraOffset - lastHumanoidShakeOffset) + totalOffset
					lastHumanoidShakeOffset = totalOffset
				end
			end

			if #activeShakes == 0 then
				unbindShakeIfIdle()
			end
		end
	)
end

local function ensureFlashGui()
	if flashGui and flashGui.Parent and flashFrame then
		return
	end
	local lp = Players.LocalPlayer
	if not lp then
		return
	end
	local pg = lp:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "LegendaryCatch_VfxFlashGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 900

	local frame = Instance.new("Frame")
	frame.Name = "FlashOverlay"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ZIndex = 100
	frame.Parent = gui

	gui.Parent = pg
	flashGui = gui
	flashFrame = frame
end

local function stepHeartbeat(dt: number)
	local now = os.clock()

	-- Expire dynamic lights cleanly
	for i = #activeLights, 1, -1 do
		local entry = activeLights[i]
		if now >= entry.expiresAt or not entry.part.Parent then
			entry.light:Destroy()
			releasePart(entry.part)
			table.remove(activeLights, i)
		else
			local rem = entry.expiresAt - now
			if rem < 0.25 then
				entry.light.Brightness = entry.baseBrightness * math.clamp(rem / 0.25, 0, 1)
			end
		end
	end

	-- Update active procedural VFX tasks
	for i = #activeTasks, 1, -1 do
		local t = activeTasks[i]
		if t.done then
			t.cleanup()
			table.remove(activeTasks, i)
		else
			t.elapsed += dt
			local alpha = math.clamp(t.elapsed / t.duration, 0, 1)
			t.update(alpha, dt)
			if t.elapsed >= t.duration then
				t.done = true
				t.cleanup()
				table.remove(activeTasks, i)
			end
		end
	end
end

local function ensureInit()
	if initialized then
		return
	end
	initialized = true

	local existing = Workspace:FindFirstChild("_LegendaryCatch_VfxPool")
	if existing and existing:IsA("Folder") then
		vfxFolder = existing
	else
		local f = Instance.new("Folder")
		f.Name = "_LegendaryCatch_VfxPool"
		f.Parent = Workspace
		vfxFolder = f
	end

	local lp = Players.LocalPlayer
	if lp then
		reducedEffects = lp:GetAttribute("ReduceEffects") == true
		reduceConn = lp:GetAttributeChangedSignal("ReduceEffects"):Connect(refreshReduceEffects)
	end

	heartbeatConn = RunService.Heartbeat:Connect(stepHeartbeat)
end

-- ============================================================================
-- PUBLIC HELPERS
-- ============================================================================

function VfxKit.init()
	ensureInit()
end

function VfxKit.isReducedEffects(): boolean
	ensureInit()
	return reducedEffects
end

function VfxKit.onReduceEffectsChanged(callback: (boolean) -> ()): StopHandle
	ensureInit()
	table.insert(reduceCallbacks, callback)
	return {
		stop = function()
			local idx = table.find(reduceCallbacks, callback)
			if idx then
				table.remove(reduceCallbacks, idx)
			end
		end,
	}
end

-- Strict dynamic PointLight allocator (max 4 live; falls back to fake billboard glow if reduced or full)
function VfxKit.acquireLight(
	position: Vector3,
	color: Color3,
	brightness: number,
	range: number,
	duration: number?
)
	ensureInit()
	if reducedEffects or not isWithinCameraDistance(position) then
		return
	end

	local dur = math.max(0.1, duration or 0.6)
	if #activeLights >= MAX_DYNAMIC_LIGHTS then
		-- Evict oldest light to respect strict mobile cap of 4
		local oldest = table.remove(activeLights, 1)
		if oldest then
			oldest.light:Destroy()
			releasePart(oldest.part)
		end
	end

	local host = acquirePart()
	host.Transparency = 1
	host.Size = Vector3.new(0.2, 0.2, 0.2)
	host.CFrame = CFrame.new(position)

	local pl = Instance.new("PointLight")
	pl.Color = color
	pl.Brightness = brightness
	pl.Range = range
	pl.Parent = host

	table.insert(activeLights, {
		light = pl,
		part = host,
		expiresAt = os.clock() + dur,
		baseBrightness = brightness,
	})
end

-- Fake billboard bloom glow (zero dynamic light cost, ideal for mobile)
function VfxKit.fakeGlow(
	target: Vector3 | BasePart,
	color: Color3,
	size: number?,
	duration: number?
)
	ensureInit()
	local worldPos = if typeof(target) == "Vector3" then target else target.Position
	if not isWithinCameraDistance(worldPos) then
		return
	end

	local unit = acquireBillboardUnit()
	local baseSize = (size or 5) * (if reducedEffects then 0.65 else 1.0)
	local dur = math.max(0.15, duration or 0.75)

	if typeof(target) == "Vector3" then
		unit.part.CFrame = CFrame.new(target)
		unit.gui.Adornee = unit.part
	else
		unit.gui.Adornee = target
	end

	unit.gui.AlwaysOnTop = false
	unit.gui.Size = UDim2.fromScale(baseSize, baseSize)
	unit.frame.BackgroundColor3 = color
	unit.frame.BackgroundTransparency = 0.45
	unit.label.Text = ""

	registerTask(dur, function(alpha: number)
		local s = baseSize * (0.7 + 0.55 * alpha)
		unit.gui.Size = UDim2.fromScale(s, s)
		unit.frame.BackgroundTransparency = 0.45 + 0.55 * alpha
	end, function()
		releaseBillboardUnit(unit)
	end)
end

-- 1. burst(position | attachment, preset, intensity 0..1, tier 1..5, overrideColor?)
function VfxKit.burst(
	target: Vector3 | Attachment,
	presetName: BurstPreset | string,
	intensity: number?,
	tier: number?,
	overrideColor: Color3?
)
	ensureInit()
	local pos = if typeof(target) == "Vector3" then target else target.WorldPosition
	if not isWithinCameraDistance(pos) then
		return
	end

	local preset = PRESETS[presetName] or PRESETS.sparks
	local inten = math.clamp(intensity or 0.7, 0.05, 1.0)
	local tierClamped = math.clamp(math.floor((tier or 1) + 0.5), 1, 5)
	local tierMult = 0.65 + (tierClamped - 1) * 0.35
	local requestedCount = math.max(2, math.floor(preset.baseCount * inten * tierMult))

	local count = reserveParticles(requestedCount, tierClamped >= 5)
	if count <= 0 then
		return
	end

	local unit = acquireEmitterUnit()
	local em = unit.emitter
	if typeof(target) == "Vector3" then
		unit.part.CFrame = CFrame.new(target)
		em.Parent = unit.att
	else
		em.Parent = target
	end

	local cA = overrideColor or preset.colorA
	local cB = if overrideColor then overrideColor:Lerp(Color3.new(1, 1, 1), 0.5) else preset.colorB
	em.Texture = resolveTexture(preset.texture, TEXTURES.sparkles)
	em.Color = Palette.toColorSequence(cA, cB)
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, preset.sizeStart * (0.8 + 0.35 * inten)),
		NumberSequenceKeypoint.new(1, preset.sizeEnd),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.75, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Speed = NumberRange.new(
		preset.speedMin * (0.75 + 0.4 * inten),
		preset.speedMax * (0.75 + 0.45 * inten)
	)
	em.Lifetime = NumberRange.new(preset.lifeMin, preset.lifeMax)
	em.Drag = preset.drag
	em.Acceleration = preset.accel
	em.LightEmission = preset.lightEmission
	em.LightInfluence = 0
	em.SpreadAngle = preset.spread
	em.RotSpeed = NumberRange.new(-preset.rotSpeed, preset.rotSpeed)
	em.EmissionDirection = Enum.NormalId.Top

	em:Emit(count)
	commitParticles(count, preset.lifeMax)

	-- Keep emitter alive until particles finish, then return to pool
	registerTask(preset.lifeMax + 0.15, function() end, function()
		releaseEmitterUnit(unit)
	end)
end

-- 2. ring(position, color, radius, duration, intensity 0..1, tier 1..5)
function VfxKit.ring(
	position: Vector3,
	color: Color3,
	radius: number?,
	duration: number?,
	intensity: number?,
	tier: number?
)
	ensureInit()
	if not isWithinCameraDistance(position) then
		return
	end

	local inten = math.clamp(intensity or 0.75, 0.1, 1.0)
	local tVal = math.clamp(tier or 1, 1, 5)
	local maxR = (radius or 6) * (0.8 + 0.25 * inten)
	local dur = math.max(0.18, duration or 0.65)
	local segCount = if reducedEffects then 8 else (if tVal >= 4 then 14 else 10)
	local thickness = 0.18 + 0.14 * inten

	local segments: { Part } = {}
	for _ = 1, segCount do
		local p = acquirePart()
		p.Color = color
		p.Material = Enum.Material.Neon
		p.Transparency = 0.1
		table.insert(segments, p)
	end

	registerTask(dur, function(alpha: number)
		local eased = 1 - ((1 - alpha) ^ 3)
		local curR = math.max(0.35, maxR * (0.18 + 0.82 * eased))
		local segLen = 2 * curR * math.tan(math.pi / segCount) * 1.08
		local curThick = thickness * (1 - alpha * 0.65)
		local trans = 0.1 + 0.9 * (alpha ^ 1.4)

		for i, seg in ipairs(segments) do
			local ang = (i / segCount) * math.pi * 2 + alpha * 0.45
			local offset = Vector3.new(math.cos(ang) * curR, 0, math.sin(ang) * curR)
			local tangent = Vector3.new(-math.sin(ang), 0, math.cos(ang))
			seg.Size = Vector3.new(curThick, curThick, segLen)
			seg.CFrame = CFrame.lookAt(position + offset, position + offset + tangent)
			seg.Transparency = trans
		end
	end, function()
		for _, seg in ipairs(segments) do
			releasePart(seg)
		end
	end)
end

-- 3. pillarOfLight(position, color, height, radius, duration, intensity 0..1, tier 1..5)
function VfxKit.pillarOfLight(
	position: Vector3,
	color: Color3,
	height: number?,
	radius: number?,
	duration: number?,
	intensity: number?,
	tier: number?
)
	ensureInit()
	if not isWithinCameraDistance(position) then
		return
	end

	local inten = math.clamp(intensity or 0.85, 0.1, 1.0)
	local tVal = math.clamp(tier or 3, 1, 5)
	local h = (height or 28) * (if reducedEffects then 0.65 else 1.0)
	local r = (radius or 2.8) * (0.75 + 0.35 * inten)
	local dur = math.max(0.35, duration or 1.8)

	local outer = acquirePart()
	outer.Shape = Enum.PartType.Cylinder
	outer.Material = Enum.Material.Neon
	outer.Color = color

	local core = acquirePart()
	core.Shape = Enum.PartType.Cylinder
	core.Material = Enum.Material.Neon
	core.Color = color:Lerp(Color3.new(1, 1, 1), 0.72)

	if tVal >= 3 and not reducedEffects then
		VfxKit.acquireLight(position + Vector3.new(0, 4, 0), color, 1.8 * inten, 24 + tVal * 4, dur)
	end
	VfxKit.fakeGlow(position + Vector3.new(0, 1.5, 0), color, r * 3.2, dur)

	local centerPos = position + Vector3.new(0, h * 0.5, 0)
	local upright = CFrame.new(centerPos) * CFrame.Angles(0, 0, math.rad(90))

	registerTask(dur, function(alpha: number)
		local env: number
		if alpha < 0.18 then
			env = alpha / 0.18
		elseif alpha > 0.65 then
			env = (1 - alpha) / 0.35
		else
			env = 1
		end
		local pulse = 1 + math.sin(alpha * math.pi * 6) * 0.08
		local curD = math.max(0.2, r * 2 * env * pulse)
		outer.Size = Vector3.new(h, curD, curD)
		outer.CFrame = upright
		outer.Transparency = 1 - 0.52 * env

		local coreD = curD * 0.45
		core.Size = Vector3.new(h, coreD, coreD)
		core.CFrame = upright
		core.Transparency = 1 - 0.82 * env
	end, function()
		releasePart(outer)
		releasePart(core)
	end)
end

-- 4. sparkTrail(startPos, endPos, color, duration, intensity 0..1, tier 1..5)
function VfxKit.sparkTrail(
	startPos: Vector3,
	endPos: Vector3,
	color: Color3,
	duration: number?,
	intensity: number?,
	tier: number?
)
	ensureInit()
	local mid = (startPos + endPos) * 0.5
	if not isWithinCameraDistance(mid) then
		return
	end

	local inten = math.clamp(intensity or 0.8, 0.1, 1.0)
	local tVal = math.clamp(tier or 2, 1, 5)
	local dur = math.max(0.15, duration or 0.45)

	local unit = acquireBeamUnit()
	unit.partA.CFrame = CFrame.new(startPos)
	unit.partB.CFrame = CFrame.new(endPos)

	local b = unit.beam
	b.Color = Palette.toColorSequence(color, color:Lerp(Color3.new(1, 1, 1), 0.7))
	b.Width0 = 0.25 + 0.35 * inten
	b.Width1 = 0.08 + 0.15 * inten
	b.CurveSize0 = (endPos - startPos).Magnitude * 0.15
	b.CurveSize1 = -(endPos - startPos).Magnitude * 0.12
	b.Transparency = NumberSequence.new(0.15)

	-- Burst a few sparks along the midpoint on higher tiers
	if tVal >= 3 and not reducedEffects then
		VfxKit.burst(mid, "sparks", inten * 0.6, tVal, color)
	end

	registerTask(dur, function(alpha: number)
		local fade = math.clamp(alpha ^ 1.2, 0, 1)
		b.Transparency = NumberSequence.new(0.15 + 0.85 * fade)
		b.Width0 = (0.25 + 0.35 * inten) * (1 - fade * 0.6)
	end, function()
		releaseBeamUnit(unit)
	end)
end

-- 5. shockwave(position, color, maxRadius, duration, intensity 0..1, tier 1..5)
function VfxKit.shockwave(
	position: Vector3,
	color: Color3,
	maxRadius: number?,
	duration: number?,
	intensity: number?,
	tier: number?
)
	ensureInit()
	if not isWithinCameraDistance(position) then
		return
	end

	local inten = math.clamp(intensity or 0.85, 0.1, 1.0)
	local tVal = math.clamp(tier or 3, 1, 5)
	local targetR = (maxRadius or 14) * (if reducedEffects then 0.65 else 1.0)
	local dur = math.max(0.25, duration or 0.65)

	-- Primary expanding ring + flat energy disc
	VfxKit.ring(position + Vector3.new(0, 0.2, 0), color, targetR, dur, inten, tVal)
	if not reducedEffects and tVal >= 3 then
		VfxKit.ring(
			position + Vector3.new(0, 0.55, 0),
			color:Lerp(Color3.new(1, 1, 1), 0.55),
			targetR * 0.78,
			dur * 0.85,
			inten * 0.8,
			tVal
		)
	end

	local disc = acquirePart()
	disc.Shape = Enum.PartType.Cylinder
	disc.Material = Enum.Material.Neon
	disc.Color = color
	local flatCf = CFrame.new(position + Vector3.new(0, 0.12, 0))
		* CFrame.Angles(0, 0, math.rad(90))

	registerTask(dur, function(alpha: number)
		local eased = 1 - ((1 - alpha) ^ 2.5)
		local d = math.max(0.5, targetR * 2 * (0.1 + 0.9 * eased))
		disc.Size = Vector3.new(0.18, d, d)
		disc.CFrame = flatCf
		disc.Transparency = 0.52 + 0.48 * alpha
	end, function()
		releasePart(disc)
	end)
end

-- 6. confettiBurst(position, colors?, intensity 0..1, tier 1..5)
function VfxKit.confettiBurst(
	position: Vector3,
	colors: { Color3 }?,
	intensity: number?,
	tier: number?
)
	ensureInit()
	if not isWithinCameraDistance(position) then
		return
	end

	local palette = colors
		or {
			Palette.World.Gold,
			Palette.World.CrystalCyan,
			Palette.World.BlossomPink,
			Color3.fromRGB(116, 244, 152),
		}
	local inten = math.clamp(intensity or 0.85, 0.15, 1.0)
	local tVal = math.clamp(tier or 3, 1, 5)
	local passes = if reducedEffects then 1 else math.min(#palette, 3)

	for i = 1, passes do
		local c = palette[((i - 1) % #palette) + 1]
		VfxKit.burst(position, "confetti", inten / math.max(1, passes * 0.65), tVal, c)
	end
end

-- 7. glowPulse(part, color?, duration?, intensity 0..1, tier 1..5) -> StopHandle
function VfxKit.glowPulse(
	part: BasePart,
	color: Color3?,
	duration: number?,
	intensity: number?,
	tier: number?
): StopHandle
	ensureInit()
	local inten = math.clamp(intensity or 0.8, 0.1, 1.0)
	local tVal = math.clamp(tier or 2, 1, 5)
	local dur = math.max(0.3, duration or 1.5)
	local pulseColor = color or part.Color

	local highlight = Instance.new("Highlight")
	highlight.Name = "VfxGlowPulse"
	highlight.Adornee = part
	highlight.FillColor = pulseColor
	highlight.OutlineColor = pulseColor:Lerp(Color3.new(1, 1, 1), 0.5)
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = part

	local maxFillVis = (if reducedEffects then 0.25 else 0.45) * inten
	local freq = 2.0 + tVal * 0.45

	local taskObj = registerTask(dur, function(alpha: number)
		if not part.Parent or not highlight.Parent then
			return
		end
		local wave = 0.5 + 0.5 * math.sin(alpha * math.pi * 2 * freq)
		local env = math.sin(alpha * math.pi)
		local strength = wave * env
		highlight.FillTransparency = 1 - maxFillVis * strength
		highlight.OutlineTransparency = 1 - math.min(0.95, (0.4 + 0.5 * inten) * env)
	end, function()
		if highlight.Parent then
			highlight:Destroy()
		end
	end)

	return {
		stop = function()
			taskObj.done = true
		end,
	}
end

-- 8. floatingText(position, text, color?, duration?, scale?)
function VfxKit.floatingText(
	position: Vector3,
	text: string,
	color: Color3?,
	duration: number?,
	scale: number?
)
	ensureInit()
	if not isWithinCameraDistance(position) then
		return
	end

	local unit = acquireBillboardUnit()
	local dur = math.max(0.35, duration or 1.1)
	local baseScale = scale or 1.0
	local w = 5.8 * baseScale
	local h = 1.8 * baseScale

	unit.part.CFrame = CFrame.new(position)
	unit.gui.Adornee = unit.part
	unit.gui.AlwaysOnTop = true
	unit.gui.Size = UDim2.fromScale(w * 0.6, h * 0.6)
	unit.frame.BackgroundTransparency = 1
	unit.label.Text = text
	unit.label.TextColor3 = color or Palette.World.WarmGold
	unit.label.TextTransparency = 0
	unit.label.TextStrokeTransparency = 0.2

	local driftX = rng:NextNumber(-0.6, 0.6)
	registerTask(dur, function(alpha: number)
		-- Elastic pop-in followed by gentle float upward and fade out
		local pop = if alpha < 0.18
			then (0.6 + 0.55 * (alpha / 0.18))
			else (1.15 - 0.15 * math.min(1, (alpha - 0.18) / 0.2))
		unit.gui.Size = UDim2.fromScale(w * pop, h * pop)
		unit.part.CFrame = CFrame.new(position + Vector3.new(driftX * alpha, 2.8 * alpha, 0))

		if alpha > 0.55 then
			local fade = (alpha - 0.55) / 0.45
			unit.label.TextTransparency = fade
			unit.label.TextStrokeTransparency = 0.2 + 0.8 * fade
		end
	end, function()
		releaseBillboardUnit(unit)
	end)
end

-- 9. screenFlash(color, alpha?, duration?) — strict kid-friendly safety limits
function VfxKit.screenFlash(color: Color3, alpha: number?, duration: number?)
	ensureInit()
	if reducedEffects then
		return
	end

	local now = os.clock()
	for i = #flashTimestamps, 1, -1 do
		if (now - flashTimestamps[i]) > 1.0 then
			table.remove(flashTimestamps, i)
		end
	end
	if #flashTimestamps >= MAX_FLASHES_PER_SECOND then
		return
	end
	table.insert(flashTimestamps, now)

	ensureFlashGui()
	if not flashFrame then
		return
	end

	local clampedAlpha = math.clamp(alpha or 0.35, 0.05, MAX_FLASH_ALPHA)
	local clampedDur = math.clamp(duration or 0.12, 0.04, MAX_FLASH_DURATION)

	if flashTween then
		flashTween:Cancel()
		flashTween = nil
	end

	flashFrame.BackgroundColor3 = color
	flashFrame.BackgroundTransparency = 1 - clampedAlpha

	local tw = TweenService:Create(
		flashFrame,
		TweenInfo.new(clampedDur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	flashTween = tw
	tw:Play()
end

-- 10. cameraShake(amount, duration?) — subtle (< 0.6 stud), disabled by ReduceEffects
function VfxKit.cameraShake(amount: number, duration: number?)
	ensureInit()
	if reducedEffects then
		return
	end

	local clampedAmount = math.clamp(amount, 0.02, MAX_CAMERA_SHAKE)
	local clampedDur = math.clamp(duration or 0.22, 0.05, 1.2)
	table.insert(activeShakes, {
		amount = clampedAmount,
		elapsed = 0,
		duration = clampedDur,
		seed = rng:NextNumber(1, 500),
	})
	ensureShakeRenderStep()
end

-- Temporary post-processing helper (for Epics/Legendaries/OceanEvents; always fades out & destroys)
function VfxKit.pulseColorCorrection(
	tintColor: Color3,
	brightness: number,
	saturation: number,
	holdTime: number,
	fadeTime: number?
): StopHandle
	ensureInit()
	if reducedEffects then
		return { stop = function() end }
	end

	local fade = math.max(0.15, fadeTime or 0.45)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "VfxTempColorCorrection"
	cc.TintColor = Color3.new(1, 1, 1)
	cc.Brightness = 0
	cc.Saturation = 0
	cc.Parent = Lighting
	table.insert(activeTempPostFx, cc)

	local inTw = TweenService:Create(
		cc,
		TweenInfo.new(fade, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			TintColor = tintColor,
			Brightness = brightness,
			Saturation = saturation,
		}
	)

	local cleaned = false
	local function cleanup()
		if cleaned then
			return
		end
		cleaned = true
		inTw:Cancel()
		local idx = table.find(activeTempPostFx, cc)
		if idx then
			table.remove(activeTempPostFx, idx)
		end
		if cc.Parent then
			local outTw = TweenService:Create(
				cc,
				TweenInfo.new(fade, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{
					TintColor = Color3.new(1, 1, 1),
					Brightness = 0,
					Saturation = 0,
				}
			)
			outTw.Completed:Connect(function()
				cc:Destroy()
			end)
			outTw:Play()
		end
	end

	inTw:Play()

	task.delay(fade + math.max(0.1, holdTime), cleanup)
	return { stop = cleanup }
end

function VfxKit.getStats(): VfxStats
	ensureInit()
	return {
		estimatedLiveParticles = estimatedParticles,
		activeDynamicLights = #activeLights,
		activeTasks = #activeTasks,
		pooledParts = #partPool,
		pooledEmitters = #emitterPool,
		pooledBeams = #beamPool,
		reducedEffects = reducedEffects,
	}
end

function VfxKit.destroy()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	if reduceConn then
		reduceConn:Disconnect()
		reduceConn = nil
	end
	table.clear(activeShakes)
	unbindShakeIfIdle()

	for _, t in ipairs(activeTasks) do
		t.cleanup()
	end
	table.clear(activeTasks)

	for _, l in ipairs(activeLights) do
		l.light:Destroy()
		releasePart(l.part)
	end
	table.clear(activeLights)

	for _, fx in ipairs(activeTempPostFx) do
		if fx.Parent then
			fx:Destroy()
		end
	end
	table.clear(activeTempPostFx)

	if vfxFolder then
		vfxFolder:Destroy()
		vfxFolder = nil
	end
	if flashGui then
		flashGui:Destroy()
		flashGui = nil
		flashFrame = nil
	end

	table.clear(partPool)
	table.clear(emitterPool)
	table.clear(beamPool)
	table.clear(billboardPool)
	table.clear(particleRecords)
	estimatedParticles = 0
	initialized = false
end

return VfxKit
