--!strict
-- Extra fishing VFX/SFX layered on top of the existing fishing flow without touching it.
-- Everything here is presentation only: it listens to what the server already sends
-- (FishingUpdate events + the Character's FishingState / FishingTarget / FishingRarity)
-- and draws particles with VfxKit.
--
--   aim   -> the rod tip charges up. Particle rate, orb size and ring count grow with the
--            gauge position, the colour follows the band under the gauge (grey, red, yellow,
--            green, purple); reaching a better band pops a burst, purple is rainbow.
--   cast  -> launch burst at the tip, scaled by the band the player hit.
--   waiting -> soft ripples around the bobber; the glow grows as the bite gets close.
--   bite  -> "!" + ring + splash in the colour of the (already known) rarity.
--   escaped / caught -> little bubble puff where the bobber was.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))
local Vfx = Shared:WaitForChild("Vfx")
local Palette = require(Vfx:WaitForChild("Palette"))
local VfxKit = require(Vfx:WaitForChild("VfxKit"))
local SfxKit = require(Vfx:WaitForChild("SfxKit"))
local Fx = script.Parent:WaitForChild("Vfx")
local BobberFx = require(Fx:WaitForChild("BobberFx"))
local CastFlightFx = require(Fx:WaitForChild("CastFlightFx"))
local MinigameFx = require(Fx:WaitForChild("MinigameFx"))

local FishingVfx = {}
FishingVfx.order = 185

local ROD_NAME = "Rod"
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

-- Bands of the power gauge. Rank only decides how special the pop feels.
local BAND_COLORS: { [string]: Color3 } = {
	neutral = Color3.fromRGB(176, 204, 224),
	red = Color3.fromRGB(255, 96, 104),
	yellow = Color3.fromRGB(255, 208, 64),
	green = Color3.fromRGB(80, 232, 150),
	purple = Color3.fromRGB(190, 112, 255),
}
local BAND_RANK: { [string]: number } = {
	red = 1,
	neutral = 2,
	yellow = 3,
	green = 4,
	purple = 5,
}

local player = Players.LocalPlayer

type Charge = {
	tip: Attachment,
	tipPart: BasePart,
	sparks: ParticleEmitter,
	orb: ParticleEmitter,
	layout: { FishingConfig.AimSegment },
	aimStart: number,
	band: string,
	conn: RBXScriptConnection,
	level: number,
	light: PointLight?,
}

local charge: Charge? = nil
local lastBand = "red"
local waitingConn: RBXScriptConnection? = nil
local lastBobberPos: Vector3? = nil

local function reduced(): boolean
	return player:GetAttribute("ReduceEffects") == true
end

local function skinTier(): number
	local forced = player:GetAttribute("DevPowerBarSkin")
	if typeof(forced) == "number" then
		return math.clamp(math.floor(forced), 1, 6)
	end
	local sum = 0
	for _, stat in TrainingConfig.STATS do
		local v = player:GetAttribute(TrainingConfig.powerAttribute(stat))
		if typeof(v) == "number" then
			sum += v
		end
	end
	return math.clamp(TrainingConfig.tier(sum), 1, 6)
end

local function findTip(): (Attachment?, BasePart?)
	local character = player.Character
	local tool = character and character:FindFirstChild(ROD_NAME)
	local tip = tool and tool:FindFirstChild("Tip")
	if tip and tip:IsA("BasePart") then
		local att = tip:FindFirstChild("LineAttachment")
		if att and att:IsA("Attachment") then
			return att, tip
		end
	end
	return nil, nil
end

local function makeEmitter(parent: Attachment, name: string): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = SPARKLE
	e.LightEmission = 1
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.RotSpeed = NumberRange.new(-120, 120)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.25, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Parent = parent
	return e
end

local function stopCharge()
	local c = charge
	if not c then
		return
	end
	charge = nil
	c.conn:Disconnect()
	c.sparks.Enabled = false
	c.orb.Enabled = false
	if c.light then
		c.light:Destroy()
	end
	-- Let the last particles fade out before removing the emitters.
	task.delay(1, function()
		c.sparks:Destroy()
		c.orb:Destroy()
	end)
end

local function bandColor(band: string, t: number): Color3
	if band == "purple" then
		return Palette.rainbowAt(t * 0.7)
	end
	return BAND_COLORS[band] or BAND_COLORS.neutral
end

local function startCharge(layout: { FishingConfig.AimSegment }, aimStart: number)
	stopCharge()
	local att, tipPart = findTip()
	if not att or not tipPart then
		return
	end
	local sparks = makeEmitter(att, "ChargeSparks")
	sparks.Speed = NumberRange.new(2, 6)
	local orb = makeEmitter(att, "ChargeOrb")
	orb.Lifetime = NumberRange.new(0.25, 0.35)
	orb.Speed = NumberRange.new(0, 0)
	orb.RotSpeed = NumberRange.new(0, 0)
	orb.Rate = 8

	local tier = skinTier()
	local calm = reduced()
	local light: PointLight? = nil
	if not calm then
		local l = Instance.new("PointLight")
		l.Name = "ChargeLight"
		l.Range = 8
		l.Brightness = 0
		l.Shadows = false
		l.Parent = att
		light = l
	end
	local nextRing = 0
	lastBand = "red"
	local start = os.clock()

	local current: Charge
	local conn = RunService.Heartbeat:Connect(function()
		-- Unequipped or respawned mid-aim: the tip left the character.
		if not tipPart:IsDescendantOf(player.Character or Workspace) or tipPart.Parent == nil then
			stopCharge()
			return
		end
		local now = Workspace:GetServerTimeNow()
		local active = now >= aimStart
		sparks.Enabled = active
		orb.Enabled = active
		if not active then
			return
		end
		local pos = FishingConfig.aimPosition(now - aimStart)
		local band = FishingConfig.bandAt(layout, pos)
		local t = os.clock() - start
		local color = bandColor(band, t)
		local seq = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.5))
		sparks.Color = seq
		orb.Color = ColorSequence.new(color)

		local rank = BAND_RANK[band] or 1
		local strength = pos * 0.7 + (rank / 5) * 0.3
		local rateScale = if calm then 0.35 else 1
		sparks.Rate = (14 + strength * 70) * rateScale
		sparks.Speed = NumberRange.new(2 + strength * 4, 5 + strength * 12)
		local sparkSize = 0.55 + strength * 1.3
		sparks.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.2, sparkSize),
			NumberSequenceKeypoint.new(1, 0),
		})
		local orbSize = 1.6 + strength * 4.2
		orb.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, orbSize * 0.7),
			NumberSequenceKeypoint.new(1, orbSize),
		})
		orb.Transparency = NumberSequence.new(0.5 - strength * 0.3, 1)
		if light then
			light.Color = color
			light.Range = 8 + strength * 12
			light.Brightness = 0.8 + strength * 2
		end
		if not calm and os.clock() >= nextRing then
			nextRing = os.clock() + 0.95 - strength * 0.6
			VfxKit.ring(
				tipPart.Position,
				color,
				2 + strength * 3.5,
				0.55,
				0.5 + strength * 0.5,
				tier
			)
		end

		if band ~= lastBand then
			local previous = BAND_RANK[lastBand] or 1
			lastBand = band
			current.band = band
			if rank > previous then
				local tip = tipPart.Position
				if band == "purple" then
					VfxKit.burst(tip, "stars", 0.9, tier)
					VfxKit.ring(tip, color, 4, 0.6, 0.8, tier)
					SfxKit.play("charge_perfect_ding")
				else
					VfxKit.burst(tip, "sparks", 0.35 + rank * 0.1, tier, color)
				end
			end
		end
	end)
	current = {
		tip = att,
		tipPart = tipPart,
		sparks = sparks,
		orb = orb,
		layout = layout,
		aimStart = aimStart,
		band = "red",
		conn = conn,
		level = tier,
		light = light,
	}
	charge = current
end

local function stopWaiting()
	if waitingConn then
		waitingConn:Disconnect()
		waitingConn = nil
	end
end

local function targetPosition(): Vector3?
	local character = player.Character
	local target = character and character:GetAttribute("FishingTarget")
	if typeof(target) == "Vector3" then
		return target
	end
	return nil
end

local function onCast(update: any)
	local c = charge
	local band = if typeof(update.powerBand) == "string" then update.powerBand else "neutral"
	local rank = BAND_RANK[band] or 2
	local color = bandColor(band, os.clock())
	local tier = skinTier()
	local tipPos: Vector3? = if c then c.tipPart.Position else nil
	stopCharge()
	if tipPos then
		VfxKit.burst(
			tipPos,
			if rank >= 4 then "stars" else "sparks",
			0.4 + rank * 0.12,
			tier,
			color
		)
		VfxKit.ring(tipPos, color, 3 + rank, 0.5, 0.5 + rank * 0.1, tier)
		SfxKit.play("cast_whoosh", { pitch = 0.9 + rank * 0.05 })
	end
	-- Splash where the bobber lands (the server publishes the target a moment later).
	task.delay(0.9, function()
		local pos = targetPosition()
		if pos then
			CastFlightFx.onSplash(pos, math.clamp(rank / 5, 0.2, 1), tier)
		end
	end)
end

-- The local line's Bobber is a Workspace child created by Fishing/Line: pick the one at the target.
local function findBobber(target: Vector3): BasePart?
	local best: BasePart? = nil
	local bestDist = 8
	for _, child in Workspace:GetChildren() do
		if child.Name == "Bobber" and child:IsA("BasePart") then
			local d = (child.Position - target).Magnitude
			if d < bestDist then
				bestDist = d
				best = child
			end
		end
	end
	return best
end

local bobberHandle: BobberFx.BobberHandle? = nil

local function detachBobber()
	if bobberHandle then
		bobberHandle.stop()
		bobberHandle = nil
	end
end

local function startWaiting()
	stopWaiting()
	detachBobber()
	local elapsed = 0
	local nextDip = 3 + math.random() * 3
	local attached = false
	waitingConn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local pos = targetPosition()
		if not pos then
			return
		end
		lastBobberPos = pos
		if not attached and elapsed > 1 then
			local bobber = findBobber(pos)
			if bobber then
				-- Line already moves the bobber; BobberFx only adds the glow, dips and bite alert.
				bobberHandle = BobberFx.attach(bobber, { animateBobbing = false })
			end
			attached = true
		end
		local handle = bobberHandle
		if handle then
			handle.setAnticipation(math.clamp(elapsed / 18, 0, 0.85))
			if elapsed > nextDip and not reduced() then
				nextDip = elapsed + 4 + math.random() * 4
				handle.dip()
			end
		end
	end)
end

local function onBite(update: any)
	stopWaiting()
	local rarity = if typeof(update.rarity) == "string" then update.rarity else "Common"
	local handle = bobberHandle
	if handle then
		-- Rarity-scaled alert: droplet + "!" up to a golden pillar and shake for Legendary.
		handle.onBite(rarity)
		return
	end
	-- No bobber part found: fall back to a plain burst at the target.
	local pos = targetPosition() or lastBobberPos
	if pos then
		local theme = Palette.getRarity(rarity)
		VfxKit.ring(pos, theme.primary, 4 + theme.tier, 0.8, 0.5 + theme.tier * 0.1, theme.tier)
		VfxKit.floatingText(pos + Vector3.new(0, 4, 0), "!", theme.primary, 1.1, 1.2)
	end
end

local function onEnd(update: any)
	stopWaiting()
	local pos = lastBobberPos or targetPosition()
	detachBobber()
	if pos and update.event == "escaped" then
		MinigameFx.onLose(pos)
	end
end

local function onUpdate(update: any)
	if typeof(update) ~= "table" then
		return
	end
	local event = update.event
	if event == "aim" then
		local layout = update.aimLayout
		local aimStart = update.aimStart
		if typeof(layout) == "table" and typeof(aimStart) == "number" then
			startCharge(layout, aimStart)
		end
	elseif event == "cast" then
		onCast(update)
		startWaiting()
	elseif event == "bite" then
		onBite(update)
	elseif event == "caught" or event == "escaped" or event == "cancelled" then
		stopCharge()
		onEnd(update)
	end
end

function FishingVfx.start()
	VfxKit.init()
	SfxKit.init()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local updateRemote = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent
	updateRemote.OnClientEvent:Connect(onUpdate)

	-- A respawn or unequip must never leave the charge glowing.
	player.CharacterRemoving:Connect(function()
		stopCharge()
		stopWaiting()
		detachBobber()
	end)
end

return FishingVfx
