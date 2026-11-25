--!strict
--[[
	BobberFx.luau
	Suggested Studio path: StarterPlayer/StarterPlayerScripts/Client/Features/Vfx/BobberFx
	Rojo path: src/client/Features/Vfx/BobberFx.luau

	Integration:
	- Drives the floating bobber waiting state, anticipation glow buildup, teaser dips,
	  and rarity-scaled bite alerts (without revealing the creature itself!).
	- Usage:
	    local handle = BobberFx.attach(bobberPart, { animateBobbing = true })
	    handle.setAnticipation(0.75) -- 0..1 as bite approaches
	    handle.dip()                 -- subtle teaser tug
	    handle.onBite("Rare")        -- rarity from server ("Common".."Legendary"|"Mystic")
	    handle.stop()                -- cleanup when fight ends or cast retracts
	- Also exposes single-player convenience shortcuts (BobberFx.setAnticipation,
	  BobberFx.dip, BobberFx.onBite, BobberFx.detach) bound to the latest attached bobber.
	- Follows the Intensity Map strictly: Common = droplet + green "!", Uncommon = + blue ring,
	  Rare = + purple zigzag lightning, Epic = + pink pillar, Legendary = + golden pillar + shake.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VfxFolder = Shared:WaitForChild("Vfx")
local Palette = require(VfxFolder:WaitForChild("Palette"))
local SfxKit = require(VfxFolder:WaitForChild("SfxKit"))
local VfxKit = require(VfxFolder:WaitForChild("VfxKit"))

export type BobberOptions = {
	animateBobbing: boolean?,
	waterY: number?,
}

export type BobberHandle = {
	setAnticipation: (level: number) -> (),
	dip: () -> (),
	onBite: (rarity: string?) -> (),
	stop: () -> (),
}

type BobberEntry = {
	bobber: BasePart,
	baseCFrame: CFrame,
	waterY: number,
	animateBobbing: boolean,
	anticipation: number,
	elapsed: number,
	nextRippleAt: number,
	dipTimer: number,
	dipDepth: number,
	glowGui: BillboardGui,
	glowFrame: Frame,
	stopped: boolean,
}

local BobberFx = {
	order = 127,
}

-- ============================================================================
-- STATE & HELPERS
-- ============================================================================

local CULL_DIST_SQ = 120 * 120

local started = false
local entries: { BobberEntry } = {}
local activePrimaryHandle: BobberHandle? = nil
local heartbeatConn: RBXScriptConnection? = nil
local rng = Random.new()

local function isNearCamera(pos: Vector3): boolean
	local cam = Workspace.CurrentCamera
	if not cam then
		return true
	end
	local d = pos - cam.CFrame.Position
	return d:Dot(d) <= CULL_DIST_SQ
end

-- Stylized zigzag bolt above water using pooled VfxKit.sparkTrail segments (Rare/Legendary bites)
local function spawnWaterLightning(
	origin: Vector3,
	color: Color3,
	segments: number,
	height: number,
	tier: number
)
	local reduced = VfxKit.isReducedEffects()
	local segCount = if reduced then 2 else math.clamp(segments, 2, 5)
	local cur = origin + Vector3.new(rng:NextNumber(-1.5, 1.5), height, rng:NextNumber(-1.5, 1.5))

	for i = 1, segCount do
		local t = i / segCount
		local jitter = (1 - t) * 1.9
		local nextPt = if i == segCount
			then origin
			else Vector3.new(
				origin.X + rng:NextNumber(-jitter, jitter),
				origin.Y + height * (1 - t),
				origin.Z + rng:NextNumber(-jitter, jitter)
			)
		VfxKit.sparkTrail(cur, nextPt, color, 0.28, 0.85, tier)
		cur = nextPt
	end
end

local function biteSoundKeyForRarity(rarityKey: string): string
	local lower = string.lower(rarityKey)
	if lower == "uncommon" or lower == "incomum" then
		return "bite_uncommon"
	elseif lower == "rare" or lower == "raro" then
		return "bite_rare"
	elseif lower == "epic" or lower == "epico" or lower == "épico" then
		return "bite_epic"
	elseif
		lower == "legendary"
		or lower == "lendario"
		or lower == "lendário"
		or lower == "mystic"
		or lower == "mistico"
		or lower == "místico"
	then
		return "bite_legendary"
	end
	return "bite_common"
end

local function createAnticipationGlow(bobber: BasePart): (BillboardGui, Frame)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BobberAnticipationGlow"
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Size = UDim2.fromScale(2.0, 2.0)
	gui.Enabled = false
	gui.Adornee = bobber

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Palette.World.SoftAqua
	frame.BackgroundTransparency = 0.85
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	gui.Parent = bobber
	return gui, frame
end

local function stopEntry(entry: BobberEntry)
	if entry.stopped then
		return
	end
	entry.stopped = true
	if entry.glowGui.Parent then
		entry.glowGui:Destroy()
	end
	if entry.animateBobbing and entry.bobber.Parent then
		entry.bobber.CFrame = entry.baseCFrame
	end
end

local function stopHeartbeatIfIdle()
	if #entries == 0 and heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
end

local function triggerBiteFx(entry: BobberEntry, rarity: string?)
	local pos = if entry.bobber.Parent then entry.bobber.Position else entry.baseCFrame.Position
	local waterPos = Vector3.new(pos.X, entry.waterY, pos.Z)
	local theme = Palette.getRarity(rarity)
	local tier = theme.tier
	local reduced = VfxKit.isReducedEffects()

	-- Plunge bobber sharply underwater
	entry.dipTimer = 0.42
	entry.dipDepth = 1.15 + tier * 0.12

	-- Audio cue matching rarity tier
	SfxKit.playAt(biteSoundKeyForRarity(rarity or "Common"), waterPos, {
		volume = 0.65 + tier * 0.07,
	})

	-- Every rarity gets splash + floating "!" in rarity color (never reveals creature name)
	VfxKit.burst(
		waterPos + Vector3.new(0, 0.25, 0),
		"splash",
		0.45 + tier * 0.11,
		tier,
		theme.secondary
	)
	VfxKit.floatingText(
		waterPos + Vector3.new(0, 2.4, 0),
		"!",
		theme.primary,
		0.95,
		1.1 + tier * 0.14
	)

	-- Intensity ladder strictly per design table:
	if tier == 1 then
		-- Common: droplet + green-aqua "!"
		VfxKit.ring(waterPos + Vector3.new(0, 0.08, 0), theme.primary, 3.6, 0.55, 0.45, 1)
	elseif tier == 2 then
		-- Uncommon: + blue ring + light sparks
		VfxKit.ring(waterPos + Vector3.new(0, 0.08, 0), theme.primary, 5.2, 0.65, 0.7, 2)
		VfxKit.burst(waterPos + Vector3.new(0, 0.4, 0), "sparks", 0.55, 2, theme.primary)
	elseif tier == 3 then
		-- Rare: + light purple zigzag lightning + expanding rings
		VfxKit.ring(waterPos + Vector3.new(0, 0.08, 0), theme.primary, 6.8, 0.72, 0.85, 3)
		spawnWaterLightning(waterPos + Vector3.new(0, 0.2, 0), theme.primary, 4, 11, 3)
		VfxKit.burst(waterPos + Vector3.new(0, 0.5, 0), "sparks", 0.75, 3, theme.primary)
		VfxKit.fakeGlow(waterPos + Vector3.new(0, 0.6, 0), theme.primary, 6.5, 0.65)
	elseif tier == 4 then
		-- Epic: + pink light column + shockwave + gentle camera nudge
		VfxKit.pillarOfLight(waterPos, theme.primary, 24, 2.4, 1.25, 0.85, 4)
		VfxKit.shockwave(waterPos, theme.primary, 9.5, 0.65, 0.85, 4)
		VfxKit.burst(waterPos + Vector3.new(0, 0.8, 0), "stars", 0.8, 4, theme.primary)
		VfxKit.cameraShake(0.22, 0.20)
	else
		-- Legendary / Mystic: + giant golden pillar + shockwave + lightning + subtle shake & accessible flash
		VfxKit.pillarOfLight(waterPos, theme.primary, 34, 3.4, 1.75, 1.0, 5)
		VfxKit.shockwave(waterPos, theme.primary, 13.5, 0.75, 1.0, 5)
		spawnWaterLightning(waterPos + Vector3.new(0, 0.2, 0), theme.secondary, 4, 15, 5)
		VfxKit.burst(waterPos + Vector3.new(0, 1.0, 0), "stars", 1.0, 5, theme.primary)
		VfxKit.cameraShake(0.42, 0.32)
		if not reduced then
			VfxKit.screenFlash(theme.glow, 0.30, 0.11)
		end
	end
end

local function stepBobbers(dt: number)
	local reduced = VfxKit.isReducedEffects()

	for i = #entries, 1, -1 do
		local e = entries[i]
		if e.stopped or not e.bobber.Parent then
			stopEntry(e)
			table.remove(entries, i)
			continue
		end

		e.elapsed += dt
		local t = e.elapsed
		local ant = e.anticipation

		-- Decay dip impulse smoothly
		local dipOffset = 0
		if e.dipTimer > 0 then
			e.dipTimer = math.max(0, e.dipTimer - dt)
			dipOffset = -math.sin((e.dipTimer / 0.42) * math.pi) * e.dipDepth
		end

		-- Gentle buoyant bobbing & micro-tremble when anticipation is high (computed from baseCFrame, zero drift)
		if e.animateBobbing then
			local bobAmp = (if reduced then 0.08 else 0.18) + ant * 0.06
			local bobSpeed = 2.6 + ant * 4.5
			local yOff = math.sin(t * bobSpeed) * bobAmp + dipOffset
			local tiltScale = if reduced then 0.03 else (0.08 + ant * 0.12)
			local rx = math.sin(t * (2.1 + ant * 3.0)) * tiltScale
			local rz = math.cos(t * (1.8 + ant * 2.8)) * tiltScale
			e.bobber.CFrame = (e.baseCFrame + Vector3.new(0, yOff, 0)) * CFrame.Angles(rx, 0, rz)
		end

		local curPos = e.bobber.Position
		if not isNearCamera(curPos) then
			e.glowGui.Enabled = false
			continue
		end

		-- Periodic subtle water ripples (faster when fish is about to bite)
		if t >= e.nextRippleAt then
			local baseInterval = if reduced then 2.4 else 1.45
			e.nextRippleAt = t + math.max(0.45, baseInterval * (1 - ant * 0.62))
			local rippleColor = Color3.fromRGB(206, 248, 255):Lerp(Palette.World.Gold, ant * 0.6)
			VfxKit.ring(
				Vector3.new(curPos.X, e.waterY + 0.06, curPos.Z),
				rippleColor,
				2.4 + ant * 1.8,
				0.85,
				0.28 + ant * 0.4,
				1
			)
		end

		-- Anticipation glow buildup (fake bloom billboard = zero dynamic light cost)
		if ant > 0.05 then
			local pulse = 1 + math.sin(t * (5 + ant * 10)) * 0.16
			local sz = (1.6 + ant * 2.8) * pulse * (if reduced then 0.65 else 1.0)
			e.glowGui.Enabled = true
			e.glowGui.Size = UDim2.fromScale(sz, sz)
			e.glowFrame.BackgroundColor3 =
				Palette.World.CrystalCyan:Lerp(Palette.World.WarmGold, ant)
			e.glowFrame.BackgroundTransparency = math.clamp(0.88 - ant * 0.52, 0.3, 0.92)
		else
			e.glowGui.Enabled = false
		end
	end

	stopHeartbeatIfIdle()
end

local function ensureHeartbeat()
	if not heartbeatConn then
		heartbeatConn = RunService.Heartbeat:Connect(stepBobbers)
	end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function BobberFx.start()
	if started then
		return
	end
	started = true
	VfxKit.init()
	SfxKit.init()
end

function BobberFx.attach(bobber: BasePart, options: BobberOptions?): BobberHandle
	BobberFx.start()

	local opts = options or {} :: BobberOptions
	local glowGui, glowFrame = createAnticipationGlow(bobber)
	local waterY = if opts.waterY ~= nil then opts.waterY else bobber.Position.Y

	local entry: BobberEntry = {
		bobber = bobber,
		baseCFrame = bobber.CFrame,
		waterY = waterY,
		animateBobbing = if opts.animateBobbing == nil then true else opts.animateBobbing,
		anticipation = 0,
		elapsed = 0,
		nextRippleAt = 0.35,
		dipTimer = 0,
		dipDepth = 0,
		glowGui = glowGui,
		glowFrame = glowFrame,
		stopped = false,
	}
	table.insert(entries, entry)
	ensureHeartbeat()

	local handle: BobberHandle = {
		setAnticipation = function(level: number)
			entry.anticipation = math.clamp(level, 0, 1)
		end,
		dip = function()
			if entry.stopped or not entry.bobber.Parent then
				return
			end
			entry.dipTimer = 0.42
			entry.dipDepth = 0.55
			local p = entry.bobber.Position
			local wPos = Vector3.new(p.X, entry.waterY, p.Z)
			SfxKit.playAt("bobber_dip", wPos, { volume = 0.45 })
			VfxKit.ring(
				wPos + Vector3.new(0, 0.08, 0),
				Color3.fromRGB(220, 250, 255),
				3.2,
				0.55,
				0.45,
				1
			)
			VfxKit.burst(wPos + Vector3.new(0, 0.15, 0), "bubbles", 0.35, 1)
		end,
		onBite = function(rarity: string?)
			if entry.stopped then
				return
			end
			triggerBiteFx(entry, rarity)
		end,
		stop = function()
			stopEntry(entry)
			if activePrimaryHandle and entries[#entries] == entry then
				activePrimaryHandle = nil
			end
		end,
	}

	activePrimaryHandle = handle
	return handle
end

-- Single-bobber convenience shortcuts for local player integration / Studio tests
function BobberFx.setAnticipation(level: number)
	if activePrimaryHandle then
		activePrimaryHandle.setAnticipation(level)
	end
end

function BobberFx.dip()
	if activePrimaryHandle then
		activePrimaryHandle.dip()
	end
end

function BobberFx.onBite(rarity: string?)
	if activePrimaryHandle then
		activePrimaryHandle.onBite(rarity)
	end
end

function BobberFx.detach()
	if activePrimaryHandle then
		activePrimaryHandle.stop()
		activePrimaryHandle = nil
	end
end

function BobberFx.destroy()
	for i = #entries, 1, -1 do
		stopEntry(entries[i])
		table.remove(entries, i)
	end
	activePrimaryHandle = nil
	stopHeartbeatIfIdle()
	started = false
end

return BobberFx
