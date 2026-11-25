--!strict
--[[
	CastFlightFx.luau
	Suggested Studio path: StarterPlayer/StarterPlayerScripts/Client/Features/Vfx/CastFlightFx
	Rojo path: src/client/Features/Vfx/CastFlightFx.luau

	Integration:
	- Visualizes the bobber/line flying through the air and landing on water with a
	  power-scaled splash and expanding water ripples.
	- Mode A (your fishing script moves the real bobber):
	    local flight = CastFlightFx.attach(bobberPart, power01, skinTier, rodTipAttachment?)
	    -- When bobber hits water:
	    flight.splash(waterHitPosition) -- or flight.stop()
	- Mode B (standalone parabolic flight preview / client visual cast):
	    CastFlightFx.flyArc(startPos, waterPos, power01, skinTier, duration?, rodTip?)
	- Direct splash trigger:
	    CastFlightFx.onSplash(waterPos, power01, skinTier)
	- Uses pooled flight rigs and a single shared Heartbeat ONLY while flights are active.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VfxFolder = Shared:WaitForChild("Vfx")
local Palette = require(VfxFolder:WaitForChild("Palette"))
local SfxKit = require(VfxFolder:WaitForChild("SfxKit"))
local VfxKit = require(VfxFolder:WaitForChild("VfxKit"))

export type FlightHandle = {
	splash: (impactPos: Vector3?) -> (),
	stop: () -> (),
}

type RigUnit = {
	proxy: Part,
	attTop: Attachment,
	attBot: Attachment,
	trail: Trail,
	sparks: ParticleEmitter,
	lineBeam: Beam,
	lineStartHost: Part,
	lineStartAtt: Attachment,
}

type ActiveFlight = {
	unit: RigUnit,
	targetBobber: BasePart?,
	rodTip: (BasePart | Attachment)?,
	power: number,
	tier: number,
	-- Optional arc motion state (used by flyArc)
	isArc: boolean,
	startPos: Vector3,
	endPos: Vector3,
	arcHeight: number,
	elapsed: number,
	duration: number,
	onLandCallback: ((Vector3) -> ())?,
	finished: boolean,
}

local CastFlightFx = {
	order = 126,
}

-- ============================================================================
-- STATE & POOLING
-- ============================================================================

local MAX_RIG_POOL = 8

local started = false
local rigFolder: Folder? = nil
local rigPool: { RigUnit } = {}
local activeFlights: { ActiveFlight } = {}
local heartbeatConn: RBXScriptConnection? = nil

local function ensureFolder(): Folder
	if rigFolder and rigFolder.Parent then
		return rigFolder
	end
	local existing = Workspace:FindFirstChild("_LegendaryCatch_CastFlightPool")
	if existing and existing:IsA("Folder") then
		rigFolder = existing
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = "_LegendaryCatch_CastFlightPool"
	f.Parent = Workspace
	rigFolder = f
	return f
end

local function acquireRig(): RigUnit
	local unit = table.remove(rigPool)
	if unit and unit.proxy.Parent then
		unit.trail.Enabled = true
		return unit
	end

	local folder = ensureFolder()

	local proxy = Instance.new("Part")
	proxy.Name = "FlightFxProxy"
	proxy.Anchored = true
	proxy.CanCollide = false
	proxy.CanTouch = false
	proxy.CanQuery = false
	proxy.CastShadow = false
	proxy.Shape = Enum.PartType.Ball
	proxy.Material = Enum.Material.Neon
	proxy.Size = Vector3.new(0.45, 0.45, 0.45)
	proxy.Transparency = 1
	proxy.CFrame = CFrame.new(0, -5000, 0)

	local attTop = Instance.new("Attachment")
	attTop.Position = Vector3.new(0, 0.25, 0)
	attTop.Parent = proxy

	local attBot = Instance.new("Attachment")
	attBot.Position = Vector3.new(0, -0.25, 0)
	attBot.Parent = proxy

	local trail = Instance.new("Trail")
	trail.Name = "CastPowerTrail"
	trail.Attachment0 = attTop
	trail.Attachment1 = attBot
	trail.FaceCamera = true
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Lifetime = 0.35
	trail.MinLength = 0.08
	trail.Enabled = false
	trail.Parent = proxy

	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "FlightSparks"
	sparks.Enabled = false
	sparks.Rate = 0
	sparks.Texture = VfxKit.TEXTURES.sparkles
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Drag = 2.0
	sparks.Acceleration = Vector3.new(0, -14, 0)
	sparks.Lifetime = NumberRange.new(0.25, 0.55)
	sparks.Speed = NumberRange.new(1, 3.5)
	sparks.SpreadAngle = Vector2.new(120, 120)
	sparks.Parent = proxy

	local lineStartHost = Instance.new("Part")
	lineStartHost.Name = "FlightLineStart"
	lineStartHost.Anchored = true
	lineStartHost.CanCollide = false
	lineStartHost.CanTouch = false
	lineStartHost.CanQuery = false
	lineStartHost.CastShadow = false
	lineStartHost.Transparency = 1
	lineStartHost.Size = Vector3.new(0.2, 0.2, 0.2)
	lineStartHost.CFrame = CFrame.new(0, -5000, 0)

	local lineStartAtt = Instance.new("Attachment")
	lineStartAtt.Parent = lineStartHost

	local lineBeam = Instance.new("Beam")
	lineBeam.Name = "CastLineBeam"
	lineBeam.Attachment0 = lineStartAtt
	lineBeam.Attachment1 = attTop
	lineBeam.FaceCamera = true
	lineBeam.LightEmission = 0.65
	lineBeam.LightInfluence = 0
	lineBeam.Width0 = 0.06
	lineBeam.Width1 = 0.08
	lineBeam.Enabled = false
	lineBeam.Parent = lineStartHost

	proxy.Parent = folder
	lineStartHost.Parent = folder

	return {
		proxy = proxy,
		attTop = attTop,
		attBot = attBot,
		trail = trail,
		sparks = sparks,
		lineBeam = lineBeam,
		lineStartHost = lineStartHost,
		lineStartAtt = lineStartAtt,
	}
end

local function releaseRig(unit: RigUnit)
	if not unit.proxy.Parent then
		return
	end
	unit.trail.Enabled = false
	unit.sparks.Enabled = false
	unit.sparks.Rate = 0
	unit.lineBeam.Enabled = false
	unit.proxy.Transparency = 1

	-- Keep proxy parked briefly so existing Trail/Sparks fade naturally before teleporting
	task.delay(0.45, function()
		if not unit.proxy.Parent then
			return
		end
		-- Only recycle if not re-acquired
		if unit.trail.Enabled then
			return
		end
		unit.proxy.CFrame = CFrame.new(0, -5000, 0)
		unit.lineStartHost.CFrame = CFrame.new(0, -5000, 0)
		if #rigPool < MAX_RIG_POOL then
			table.insert(rigPool, unit)
		else
			unit.proxy:Destroy()
			unit.lineStartHost:Destroy()
		end
	end)
end

local function configureRigVisuals(unit: RigUnit, power: number, tier: number, showOrb: boolean)
	local reduced = VfxKit.isReducedEffects()
	local color = Palette.colorForCharge(power, tier)
	local bright = color:Lerp(Color3.new(1, 1, 1), 0.6)

	unit.proxy.Color = color
	unit.proxy.Transparency = if showOrb then 0.1 else 1

	local halfWidth = 0.16 + power * 0.22
	unit.attTop.Position = Vector3.new(0, halfWidth, 0)
	unit.attBot.Position = Vector3.new(0, -halfWidth, 0)

	unit.trail.Color = Palette.toColorSequence(bright, color)
	unit.trail.Lifetime = if reduced then 0.2 else (0.28 + power * 0.22)
	unit.trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	unit.trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	unit.trail:Clear()
	unit.trail.Enabled = true

	if not reduced and power >= 0.2 then
		unit.sparks.Color = Palette.toColorSequence(bright, color)
		unit.sparks.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.22 + power * 0.24),
			NumberSequenceKeypoint.new(1, 0),
		})
		unit.sparks.Rate = math.floor(4 + power * 12)
		unit.sparks.Enabled = true
	else
		unit.sparks.Enabled = false
		unit.sparks.Rate = 0
	end

	unit.lineBeam.Color = Palette.toColorSequence(Color3.fromRGB(232, 248, 255), color)
	unit.lineBeam.Transparency = NumberSequence.new(0.28)
end

local function getRodTipPos(rodTip: (BasePart | Attachment)?): Vector3?
	if not rodTip or not rodTip.Parent then
		return nil
	end
	if rodTip:IsA("Attachment") then
		return rodTip.WorldPosition
	end
	return rodTip.Position
end

local function finishFlight(flight: ActiveFlight, doSplash: boolean, overridePos: Vector3?)
	if flight.finished then
		return
	end
	flight.finished = true

	local finalPos = overridePos or flight.unit.proxy.Position
	releaseRig(flight.unit)

	if doSplash then
		CastFlightFx.onSplash(finalPos, flight.power, flight.tier)
		if flight.onLandCallback then
			task.spawn(flight.onLandCallback, finalPos)
		end
	end
end

local function stopHeartbeatIfIdle()
	if #activeFlights == 0 and heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
end

local function stepFlights(dt: number)
	for i = #activeFlights, 1, -1 do
		local f = activeFlights[i]
		if f.finished then
			table.remove(activeFlights, i)
			continue
		end

		if f.isArc then
			f.elapsed += dt
			local alpha = math.clamp(f.elapsed / f.duration, 0, 1)
			local flatPos = f.startPos:Lerp(f.endPos, alpha)
			local arcY = 4 * f.arcHeight * alpha * (1 - alpha)
			f.unit.proxy.CFrame = CFrame.new(flatPos + Vector3.new(0, arcY, 0))

			if alpha >= 1 then
				finishFlight(f, true, f.endPos)
				table.remove(activeFlights, i)
				continue
			end
		else
			local bobber = f.targetBobber
			if not bobber or not bobber.Parent then
				finishFlight(f, false, nil)
				table.remove(activeFlights, i)
				continue
			end
			f.unit.proxy.CFrame = bobber.CFrame
		end

		-- Update optional fishing line Beam
		local tipPos = getRodTipPos(f.rodTip)
		if tipPos then
			f.unit.lineStartHost.CFrame = CFrame.new(tipPos)
			local dist = (f.unit.proxy.Position - tipPos).Magnitude
			f.unit.lineBeam.CurveSize0 = -math.min(3.5, dist * 0.08)
			f.unit.lineBeam.Enabled = true
		else
			f.unit.lineBeam.Enabled = false
		end
	end

	stopHeartbeatIfIdle()
end

local function ensureHeartbeat()
	if not heartbeatConn then
		heartbeatConn = RunService.Heartbeat:Connect(stepFlights)
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function CastFlightFx.start()
	if started then
		return
	end
	started = true
	VfxKit.init()
	SfxKit.init()
end

-- Power-scaled water splash + staggered expanding ripples
function CastFlightFx.onSplash(position: Vector3, power: number?, tier: number?)
	CastFlightFx.start()
	local p = math.clamp(power or 0.5, 0, 1)
	local tVal = math.clamp(math.floor((tier or 1) + 0.5), 1, 5)
	local reduced = VfxKit.isReducedEffects()
	local accentColor = Palette.colorForCharge(p, tier)

	-- Sound scales between small plop and big energetic splash
	local soundName = if p >= 0.65 then "water_splash_big" else "water_splash_small"
	SfxKit.playAt(soundName, position, {
		volume = 0.45 + p * 0.45,
		pitch = 1.12 - p * 0.22,
	})

	-- Primary droplet burst + water mist
	local waterColor = Color3.fromRGB(168, 242, 255):Lerp(accentColor, p * 0.35)
	VfxKit.burst(position + Vector3.new(0, 0.25, 0), "splash", 0.35 + p * 0.65, tVal, waterColor)

	-- Expanding concentric ripples (1 in ReduceEffects, up to 3 on strong cast)
	local baseRadius = 3.2 + p * 5.8
	VfxKit.ring(
		position + Vector3.new(0, 0.08, 0),
		Color3.fromRGB(224, 252, 255),
		baseRadius,
		0.65 + p * 0.3,
		0.45 + p * 0.55,
		tVal
	)

	if not reduced then
		task.delay(0.14, function()
			VfxKit.ring(
				position + Vector3.new(0, 0.08, 0),
				waterColor,
				baseRadius * 1.28,
				0.85,
				0.35 + p * 0.45,
				tVal
			)
		end)
		if p >= 0.65 then
			VfxKit.burst(position + Vector3.new(0, 0.4, 0), "sparks", p * 0.75, tVal, accentColor)
			task.delay(0.28, function()
				VfxKit.ring(
					position + Vector3.new(0, 0.08, 0),
					accentColor,
					baseRadius * 1.5,
					0.95,
					0.35,
					tVal
				)
			end)
		end
	end

	-- Extra celebratory shimmer for Perfect casts hitting the water
	if p >= 0.90 then
		VfxKit.fakeGlow(
			position + Vector3.new(0, 0.4, 0),
			Palette.ChargeBands.PerfectGold,
			5.5,
			0.65
		)
	end
end

-- Attach flight trail & sparks to an existing bobber Part moved by your fishing code
function CastFlightFx.attach(
	bobber: BasePart,
	power: number?,
	tier: number?,
	rodTip: (BasePart | Attachment)?
): FlightHandle
	CastFlightFx.start()
	local p = math.clamp(power or 0.5, 0, 1)
	local tVal = math.clamp(math.floor((tier or 1) + 0.5), 1, 6)

	local unit = acquireRig()
	unit.proxy.CFrame = bobber.CFrame
	configureRigVisuals(unit, p, tVal, false)

	local flight: ActiveFlight = {
		unit = unit,
		targetBobber = bobber,
		rodTip = rodTip,
		power = p,
		tier = tVal,
		isArc = false,
		startPos = bobber.Position,
		endPos = bobber.Position,
		arcHeight = 0,
		elapsed = 0,
		duration = 1,
		onLandCallback = nil,
		finished = false,
	}
	table.insert(activeFlights, flight)
	ensureHeartbeat()

	return {
		splash = function(impactPos: Vector3?)
			finishFlight(flight, true, impactPos)
		end,
		stop = function()
			finishFlight(flight, false, nil)
		end,
	}
end

-- Standalone parabolic flight visual (useful when the client animates cast travel or for Studio tests)
function CastFlightFx.flyArc(
	startPos: Vector3,
	endPos: Vector3,
	power: number?,
	tier: number?,
	duration: number?,
	rodTip: (BasePart | Attachment)?,
	onLand: ((Vector3) -> ())?
): FlightHandle
	CastFlightFx.start()
	local p = math.clamp(power or 0.6, 0, 1)
	local tVal = math.clamp(math.floor((tier or 1) + 0.5), 1, 6)
	local dist = (endPos - startPos).Magnitude
	local dur = math.max(0.18, duration or math.clamp(dist / 42, 0.35, 1.15))

	local unit = acquireRig()
	unit.proxy.CFrame = CFrame.new(startPos)
	configureRigVisuals(unit, p, tVal, true)

	local flight: ActiveFlight = {
		unit = unit,
		targetBobber = nil,
		rodTip = rodTip,
		power = p,
		tier = tVal,
		isArc = true,
		startPos = startPos,
		endPos = endPos,
		arcHeight = math.clamp(dist * 0.22 + 2.5, 3.0, 16.0),
		elapsed = 0,
		duration = dur,
		onLandCallback = onLand,
		finished = false,
	}
	table.insert(activeFlights, flight)
	ensureHeartbeat()

	return {
		splash = function(impactPos: Vector3?)
			finishFlight(flight, true, impactPos)
		end,
		stop = function()
			finishFlight(flight, false, nil)
		end,
	}
end

function CastFlightFx.stopAll()
	for i = #activeFlights, 1, -1 do
		finishFlight(activeFlights[i], false, nil)
		table.remove(activeFlights, i)
	end
	stopHeartbeatIfIdle()
end

function CastFlightFx.destroy()
	CastFlightFx.stopAll()
	for _, unit in ipairs(rigPool) do
		unit.proxy:Destroy()
		unit.lineStartHost:Destroy()
	end
	table.clear(rigPool)
	if rigFolder then
		rigFolder:Destroy()
		rigFolder = nil
	end
	started = false
end

return CastFlightFx
