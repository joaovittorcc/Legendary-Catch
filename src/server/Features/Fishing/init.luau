--!strict
-- Server authority for fishing: validates the cast spot, waits for the bite, rolls the
-- creature (kept secret until the catch), picks one minigame and judges the result.
-- On a catch it rolls the weight, pays coins and records the collection entry.
-- Other players see the line through Character attributes (FishingState/Target/Rarity).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AquariumConfig = require(Shared:WaitForChild("Config"):WaitForChild("Aquarium"))
local AquariumState = require(Shared:WaitForChild("AquariumState"))
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local RouletteConfig = require(Shared:WaitForChild("Config"):WaitForChild("Roulette"))
local EventsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Events"))
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Net = require(Shared:WaitForChild("Net"))
local PrestigeConfig = require(Shared:WaitForChild("Config"):WaitForChild("Prestige"))
local Products = require(Shared:WaitForChild("Config"):WaitForChild("Products"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local SeasonsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Seasons"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))
local Zones = require(Shared:WaitForChild("Config"):WaitForChild("Zones"))

local Features = script.Parent
local Analytics = require(Features:WaitForChild("Analytics"))
local Aquarium = require(Features:WaitForChild("Aquarium"))
local Monetization = require(Features:WaitForChild("Monetization"))
local OceanEvents = require(Features:WaitForChild("OceanEvents"))
local PlayerData = require(Features:WaitForChild("PlayerData"))
local Prestige = require(Features:WaitForChild("Prestige"))
local Journey = require(script.Parent:WaitForChild("Journey"))
local Progress = require(Features:WaitForChild("Progress"))
local Social = require(Features:WaitForChild("Social"))
local Trophy = require(Features:WaitForChild("Trophy"))
local Training = require(Features:WaitForChild("Training"))
local Remotes = require(Features.Parent:WaitForChild("Remotes"))

type Session = {
	phase: string, -- "idle" | "waiting" | "fighting"
	castId: number,
	lastCast: number,
	fightStart: number,
	lastCatchAt: number?, -- os.clock() of last paid catch (rate-limited to <= 1 per 3s)
	wonCasts: { [number]: boolean }, -- castIds already rewarded (blocks duplicate wins)
	suspectTimes: { number }, -- timestamps of suspicious submits in the 10-min window
	penaltyUntil: number, -- os.clock() until which minimum fight time increases by 50%
	kind: string,
	creatureId: string,
	odds: number, -- real "1 in N" of the hooked creature (0 = not shown, e.g. tutorial catch)
	powerBand: string, -- power bar band of the current cast ("neutral" when the bar is off)
	aimStart: number, -- workspace:GetServerTimeNow() when the bar started (phase "aiming")
	aimLayout: { FishingConfig.AimSegment },
	aimHistory: { string }, -- last bands (anti-cheat: too many purples stops trusting tap times)
	eventId: string, -- ocean event in force at the bite ("" none); locks the value bonus
	zoneId: string,
	castPos: Vector3, -- root position when the line was cast
	isAuto: boolean, -- current cast is running on the server Auto-Fish loop
	autoEnabled: boolean,
	autoToken: number,
	autoRodId: string,
	autoAnchor: Vector3,
}

local Fishing = {}
Fishing.order = 50

local MAX_FIGHT_DRIFT = 20 -- studs the player may move from the cast spot during a fight
local CATCH_RATE_LIMIT = 3 -- minimum seconds between rewarded catches per player
local SUSPICIOUS_WINDOW = 600 -- 10 minutes sliding window for anti-cheat telemetry
local SUSPICIOUS_THRESHOLD = 20 -- > 20 suspicious submits in 10 min triggers penalty
local PENALTY_DURATION = 600 -- 10 minutes of +50% minimum fight seconds
local PENALTY_MULTIPLIER = 1.5
local AUTO_MAX_RARITY_RANK = 4 -- Epic cap for Auto-Fish (ranks 5-6 reroll)
local AUTO_BASE_SUCCESS = 0.85
local AUTO_TIER_PENALTY = 0.05 -- -5% per tier above 3
local AUTO_FIGHT_MULTIPLIER = 1.5
-- Extra wait per Auto-Fish cycle so it earns ~60% of manual play (docs/PESCA-S3.md section 3).
local AUTO_EXTRA_DELAY = 6
local AUTO_MAX_DRIFT = 3
local AUTO_MAX_SPEED = 2

local sessions: { [Player]: Session } = {}
local rng = Random.new()
local update: RemoteEvent

local function session(player: Player): Session
	local s = sessions[player]
	if not s then
		s = {
			phase = "idle",
			castId = 0,
			lastCast = 0,
			fightStart = 0,
			lastCatchAt = nil,
			wonCasts = {},
			suspectTimes = {},
			penaltyUntil = 0,
			kind = "",
			creatureId = "",
			odds = 0,
			powerBand = "neutral",
			aimStart = 0,
			aimLayout = {},
			aimHistory = {},
			eventId = "",
			zoneId = "",
			castPos = Vector3.zero,
			isAuto = false,
			autoEnabled = false,
			autoToken = 0,
			autoRodId = "",
			autoAnchor = Vector3.zero,
		}
		sessions[player] = s
	end
	return s
end

local function recordSuspicious(player: Player, s: Session, now: number)
	local kept: { number } = {}
	for _, at in s.suspectTimes do
		if now - at <= SUSPICIOUS_WINDOW then
			table.insert(kept, at)
		end
	end
	table.insert(kept, now)
	s.suspectTimes = kept
	if #kept > SUSPICIOUS_THRESHOLD then
		s.penaltyUntil = math.max(s.penaltyUntil, now + PENALTY_DURATION)
	end
	PlayerData.update(player, function(p)
		p.stats.suspicious = (p.stats.suspicious or 0) + 1
	end)
end

local function send(player: Player, payload: Net.FishingUpdate)
	update:FireClient(player, payload)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Mirrors the session on the character so other clients can draw this player's line.
local function publish(player: Player, state: string, target: Vector3?, rarity: string?)
	local character = player.Character
	if not character then
		return
	end
	character:SetAttribute("FishingState", state)
	character:SetAttribute("FishingTarget", target)
	character:SetAttribute("FishingRarity", rarity or "")
end

local function inFishingZone(root: BasePart): string?
	local zone = Zones.findAt(root.Position)
	return if zone then zone.id else nil
end

local function playerLevel(player: Player): number
	local profile = PlayerData.get(player)
	if profile then
		return profile.stats.level
	end
	local attr = player:GetAttribute("PlayerLevel")
	return if typeof(attr) == "number" then attr else 1
end

local function syncPlayerZone(player: Player): string
	local root = rootOf(player)
	local zoneId = if root then inFishingZone(root) or "" else ""
	if player:GetAttribute(Zones.PLAYER_ATTRIBUTE) ~= zoneId then
		player:SetAttribute(Zones.PLAYER_ATTRIBUTE, zoneId)
	end
	return zoneId
end

local function weightedPick(weights: { [string]: number }, order: { string }): string
	local total = 0
	for _, key in order do
		total += weights[key] or 0
	end
	local roll = rng:NextNumber(0, total)
	for _, key in order do
		roll -= weights[key] or 0
		if roll <= 0 then
			return key
		end
	end
	return order[1]
end

-- Studio-only overrides so rare reveals and each minigame can be tested on demand.
local function devOverride(player: Player, attribute: string): string?
	if not RunService:IsStudio() then
		return nil
	end
	local value = player:GetAttribute(attribute)
	return if typeof(value) == "string" and value ~= "" then value else nil
end

local function equippedRod(player: Player): Rods.Rod?
	local profile = PlayerData.get(player)
	return if profile then Rods.get(profile.equippedRod) else nil
end

-- Instinct training, the equipped rod, zone, prestige and ocean event all tilt the odds
-- toward rarer creatures (each capped in its own config).
local function luckyWeights(player: Player, zoneId: string?, band: string?): { [string]: number }
	local instinct = Training.level(player, "Instinct")
	local rod = equippedRod(player)
	local prestige = Prestige.level(player)
	local event = OceanEvents.current()
	local boosted = Monetization.luckBoostActive(player)
	local activeZoneId = zoneId or player:GetAttribute(Zones.PLAYER_ATTRIBUTE)
	local zone = if typeof(activeZoneId) == "string" and activeZoneId ~= ""
		then Zones.get(activeZoneId)
		else nil
	local weights: { [string]: number } = {}
	for rank, rarity in FishingConfig.RARITY_ORDER do
		-- A rarity with no creatures released yet never rolls (Mystic stays dormant until then).
		local released = #Creatures.ofRarity(rarity) > 0
		local w = (if released then FishingConfig.RARITY_WEIGHTS[rarity] or 0 else 0)
			* TrainingConfig.luckMultiplier(instinct, rank)
			* Rods.luckMultiplier(rod, rank)
			* PrestigeConfig.luckMultiplier(prestige, rank)
		if event then
			w *= event.rarityBoost[rarity] or 1
		end
		if zone then
			w *= zone.rarityBoost[rarity] or 1
		end
		-- Paid luck boost only lifts Rare and above; it never guarantees anything.
		if boosted and rank >= 3 then
			w *= Products.LUCK_BOOST_MULTIPLIER
		end
		-- Power bar (flag FishingPower): the band tilts luck, then every source together is
		-- capped per rank so stacking never runs away.
		if band and FishingConfig.powerEnabled() then
			w *= FishingConfig.powerFactor(band, rank)
			local base = if released then FishingConfig.RARITY_WEIGHTS[rarity] or 0 else 0
			w = math.min(w, base * (FishingConfig.LUCK_CAP[rank] or 1))
		end
		weights[rarity] = w
	end
	return weights
end

-- Returns the creature and its real "1 in N" for this roll (luck included).
local function rollCreature(
	player: Player,
	maxRank: number?,
	zoneId: string?
): (Creatures.Creature, number)
	local s = sessions[player]
	local effectiveZone = zoneId or (if s and s.zoneId ~= "" then s.zoneId else nil)
	local weights = luckyWeights(player, effectiveZone, if s then s.powerBand else nil)
	local rarity = devOverride(player, "DevForceRarity")
		or weightedPick(weights, FishingConfig.RARITY_ORDER)
	local rank = table.find(FishingConfig.RARITY_ORDER, rarity) or 1
	if maxRank and rank > maxRank then
		local cappedOrder: { string } = {}
		for i = 1, math.min(maxRank, #FishingConfig.RARITY_ORDER) do
			table.insert(cappedOrder, FishingConfig.RARITY_ORDER[i])
		end
		rarity = weightedPick(weights, cappedOrder)
	end
	-- Each creature weighs its dropWeight; event and seasonal ones join (3x) only while active.
	local current = OceanEvents.current()
	local pool: { Creatures.PoolEntry } = {}
	for _, c in Creatures.ofRarity(rarity) do
		local w = Creatures.dropWeight(c)
		if c.event then
			if current and current.id == c.event then
				table.insert(pool, { creature = c, weight = w * 3 })
			end
		elseif c.season then
			if SeasonsConfig.isActive(c.season, player) then
				table.insert(pool, { creature = c, weight = w * 3 })
			end
		else
			table.insert(pool, { creature = c, weight = w })
		end
	end
	local picked, poolTotal = Creatures.pick(pool, rng:NextNumber())
	if not picked then
		return Creatures.LIST[rng:NextInteger(1, #Creatures.LIST)], 0
	end
	return picked.creature, FishingConfig.oddsOf(weights, rarity, poolTotal, picked.weight)
end

local function rollMinigame(player: Player): string
	local forced = devOverride(player, "DevForceMinigame")
	if forced and FishingConfig.MIN_FIGHT_SECONDS[forced] then
		return forced
	end
	return FishingConfig.MINIGAMES[rng:NextInteger(1, #FishingConfig.MINIGAMES)]
end

-- Most catches are near the light end; trophy weights are rare.
local function rollWeight(creature: Creatures.Creature): number
	local t = rng:NextNumber() ^ 1.8
	local kg = creature.weightMin + (creature.weightMax - creature.weightMin) * t
	return math.floor(kg * 100 + 0.5) / 100
end

local COMBO_STEP = 0.03 -- +3% coins per consecutive catch
local COMBO_MAX_STEPS = 10 -- capped at +30%
-- Streak lengths the client celebrates with a stronger effect (3 / 5 / 8 manual catches).
-- Only juice: the coin bonus stays on COMBO_STEP up to COMBO_MAX_STEPS.
local COMBO_MILESTONES: { [number]: boolean } = { [3] = true, [5] = true, [8] = true }
local COMBO_LOST_MIN = 3 -- the client only mourns a streak of at least this length

-- Ends the streak (escape, failed fight, timeout, cancel). Returns the length that was lost
-- when it was worth announcing, else nil. Auto-Fish never moves the combo either way.
local function breakCombo(player: Player): number?
	local previous = (player:GetAttribute("FishingCombo") or 0) :: number
	if previous ~= 0 then
		player:SetAttribute("FishingCombo", 0)
	end
	return if previous >= COMBO_LOST_MIN then previous else nil
end

local function currentEventId(): string
	local event = OceanEvents.current()
	return if event then event.id else ""
end

local function reset(player: Player, s: Session)
	s.phase = "idle"
	s.isAuto = false
	s.kind = ""
	s.creatureId = ""
	s.odds = 0
	s.powerBand = "neutral"
	s.aimStart = 0
	s.zoneId = ""
	publish(player, "", nil, nil)
end

local beginWaiting: (Player, Session, number, BasePart, boolean) -> ()
local startAim: (Player, Session, number) -> ()

-- Resolves the power bar once: from the tap time (trusted within maxLagSeconds, unless the
-- player's recent purple share is suspicious) or "red" on timeout. Then the cast goes on.
local function resolveAim(player: Player, s: Session, castId: number, tapTime: number?)
	if sessions[player] ~= s or s.castId ~= castId or s.phase ~= "aiming" then
		return
	end
	local band = "red"
	if tapTime then
		band = FishingConfig.bandAt(s.aimLayout, FishingConfig.aimPosition(tapTime - s.aimStart))
	end
	s.powerBand = band
	table.insert(s.aimHistory, band)
	if #s.aimHistory > FishingConfig.AIM.suspectWindow then
		table.remove(s.aimHistory, 1)
	end
	Analytics.custom(player, "PowerBand", 1, band)
	local root = rootOf(player)
	-- The player must still be at the cast spot (same rule as the fight).
	if not root or (root.Position - s.castPos).Magnitude > MAX_FIGHT_DRIFT then
		reset(player, s)
		send(player, { event = "cancelled", castId = castId })
		return
	end
	beginWaiting(player, s, castId, root, false)
end

local function purpleShare(s: Session): number
	if #s.aimHistory < FishingConfig.AIM.suspectWindow then
		return 0
	end
	local n = 0
	for _, b in s.aimHistory do
		if b == "purple" then
			n += 1
		end
	end
	return n / #s.aimHistory
end

-- Phase "aiming": the server clock drives the bar; the client gets the layout and start time.
function startAim(player: Player, s: Session, castId: number)
	s.phase = "aiming"
	s.aimStart = workspace:GetServerTimeNow()
	local rod = equippedRod(player)
	local progress = Training.level(player, "Control") / TrainingConfig.MAX_LEVEL
	local aim = FishingConfig.aimLevel(progress, if rod then rod.controlBonus else 0)
	s.aimLayout = FishingConfig.aimLayout(aim)
	send(player, {
		event = "aim",
		castId = castId,
		aimStart = s.aimStart,
		aimSweep = FishingConfig.AIM.sweepSeconds,
		aimLevel = aim,
		aimLayout = s.aimLayout,
	})
	task.delay(FishingConfig.AIM.timeoutSeconds, function()
		resolveAim(player, s, castId, nil)
	end)
end

local function onPowerTap(player: Player, castId: unknown, clientTime: unknown)
	local s = sessions[player]
	if not s or typeof(castId) ~= "number" or s.castId ~= castId or s.phase ~= "aiming" then
		return
	end
	local now = workspace:GetServerTimeNow()
	local tapTime = now
	if
		typeof(clientTime) == "number"
		and clientTime == clientTime
		and purpleShare(s) <= FishingConfig.AIM.suspectPurpleShare
	then
		-- Forgive latency, but never accept a time from the future or too far in the past.
		tapTime = math.clamp(clientTime, now - FishingConfig.AIM.maxLagSeconds, now)
	elseif purpleShare(s) > FishingConfig.AIM.suspectPurpleShare then
		recordSuspicious(player, s, os.clock())
	end
	resolveAim(player, s, castId, math.max(tapTime, s.aimStart))
end

local function onCast(player: Player)
	local s = session(player)
	local now = os.clock()
	if s.autoEnabled or s.phase ~= "idle" or now - s.lastCast < FishingConfig.CAST_COOLDOWN then
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	if not PlayerData.get(player) then
		send(player, { event = "rejected", reason = "loading" })
		return
	end
	local zoneId = syncPlayerZone(player)
	if zoneId == "" then
		send(player, { event = "rejected", reason = "notInZone" })
		return
	end
	local zone = Zones.get(zoneId)
	if zone and playerLevel(player) < zone.minLevel then
		send(player, {
			event = "rejected",
			reason = "levelLocked",
			zoneId = zone.id,
			minLevel = zone.minLevel,
		})
		return
	end
	s.lastCast = now
	s.castPos = root.Position
	s.zoneId = zoneId
	s.castId += 1
	if s.castId > 200 then
		s.wonCasts[s.castId - 200] = nil
	end
	local castId = s.castId
	local profile = PlayerData.get(player)
	-- The very first catch is quick and friendly: a bite in 2-3.5 s, an Uncommon, the easy reel.
	local firstEver = profile ~= nil and profile.stats.catches == 0
	s.powerBand = "neutral"
	if FishingConfig.powerEnabled() and not firstEver then
		startAim(player, s, castId)
		return
	end
	beginWaiting(player, s, castId, root, firstEver)
end

-- After the cast (and the power bar, when on): line in the water, bite timer running.
function beginWaiting(
	player: Player,
	s: Session,
	castId: number,
	root: BasePart,
	firstEver: boolean
)
	s.phase = "waiting"
	local castZone = s.zoneId
	local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local target = root.Position
		+ (if flat.Magnitude > 0 then flat.Unit else Vector3.zAxis)
			* FishingConfig.CAST_DISTANCE
	publish(player, "waiting", Vector3.new(target.X, 0, target.Z), nil)
	send(player, {
		event = "cast",
		castId = castId,
		powerBand = if FishingConfig.powerEnabled() then s.powerBand else nil,
	})
	Analytics.step(player, "firstCast")
	Progress.onCast(player)

	task.delay(
		if firstEver
			then rng:NextNumber(2, 3.5)
			else rng:NextNumber(FishingConfig.BITE_DELAY_MIN, FishingConfig.BITE_DELAY_MAX),
		function()
			if sessions[player] ~= s or s.castId ~= castId or s.phase ~= "waiting" then
				return
			end
			local creature, odds = rollCreature(player, nil, castZone)
			if firstEver then
				local friendly = Creatures.ofRarity("Uncommon")
				if #friendly > 0 then
					creature = friendly[rng:NextInteger(1, #friendly)]
					odds = 0 -- scripted tutorial catch: no honest odds to show
				end
			end
			s.odds = odds
			s.phase = "fighting"
			s.kind = if firstEver then "reel" else rollMinigame(player)
			s.creatureId = creature.id
			s.eventId = currentEventId()
			s.fightStart = os.clock()
			local character = player.Character
			publish(
				player,
				"fighting",
				character and character:GetAttribute("FishingTarget") :: Vector3?,
				creature.rarity
			)
			Analytics.step(player, "firstBite")
			-- Only the rarity goes to the client: the creature stays hidden until the catch.
			send(player, {
				event = "bite",
				castId = castId,
				kind = s.kind,
				tier = creature.tier,
				rarity = creature.rarity,
			})

			task.delay(FishingConfig.FIGHT_TIMEOUT, function()
				if sessions[player] == s and s.castId == castId and s.phase == "fighting" then
					local kind = s.kind -- reset() clears it
					reset(player, s)
					Analytics.fight(
						player,
						kind,
						creature.tier,
						"timeout",
						FishingConfig.FIGHT_TIMEOUT
					)
					send(player, {
						event = "escaped",
						castId = castId,
						comboLost = breakCombo(player),
					})
				end
			end)
		end
	)
end

local function payCatch(
	player: Player,
	creature: Creatures.Creature,
	castId: number,
	isAuto: boolean?,
	minigame: string?,
	lockedEventId: string?,
	odds: number?
)
	local weight = rollWeight(creature)
	local isGiant = weight >= creature.weightMin + (creature.weightMax - creature.weightMin) * 0.85
	-- Catch roulette (flag FishingRoulette): size, shrink or mutation, rolled here on the server.
	-- The aquarium variant (isGiant above) keeps using the base weight on purpose.
	local baseWeight = weight
	local roulette: RouletteConfig.Outcome? = nil
	if RouletteConfig.enabled() then
		roulette = RouletteConfig.spin(function()
			return rng:NextNumber()
		end)
		local spun = roulette :: RouletteConfig.Outcome
		weight = math.floor(baseWeight * spun.sizeMult * 100 + 0.5) / 100
	end
	local previousCombo = (player:GetAttribute("FishingCombo") or 0) :: number
	local combo = if isAuto then previousCombo else previousCombo + 1
	local comboBonus = if isAuto then 0 else math.min(combo - 1, COMBO_MAX_STEPS) * COMBO_STEP
	if not isAuto then
		player:SetAttribute("FishingCombo", combo)
	end
	-- The event that was active at the BITE decides the bonus, so a catch in progress when the
	-- event ends still pays what the player saw (and one that began mid-fight does not).
	local event = if lockedEventId ~= nil
		then EventsConfig.get(lockedEventId)
		else OceanEvents.current()
	local forced = devOverride(player, "DevForceVariant")
	local shiny = forced == "Shiny"
		or (forced == nil and rng:NextNumber() < FishingConfig.SHINY_CHANCE)
	local value = math.floor(
		Creatures.valueFor(creature, baseWeight)
			* (if roulette then roulette.coinMult else 1)
			* (if event then event.valueMultiplier else 1)
			* (if shiny then FishingConfig.SHINY_VALUE_MULTIPLIER else 1)
			* Monetization.coinMultiplier(player)
			* PrestigeConfig.coinMultiplier(Prestige.level(player))
			* (1 + comboBonus)
	)
	local isNew, count, isRecord, previousBest = false, 1, false, 0
	-- Aquarium variant of this catch (Gigante and Dourada; Dourada = the old Cintilante).
	local variantId = AquariumConfig.variantId(isGiant, shiny)
	local newVariant, aquariumVersion = false, 0
	PlayerData.update(player, function(p)
		local entry = p.collection[creature.id]
		if entry then
			entry.count = (entry.count or 0) + 1
			if weight > (entry.bestWeight or 0) then
				isRecord = true
				previousBest = entry.bestWeight or 0
				entry.bestWeight = weight
			end
		else
			isNew = true
			entry = { count = 1, bestWeight = weight, firstAt = os.time(), shiny = 0 }
			p.collection[creature.id] = entry
		end
		if shiny then
			entry.shiny = (entry.shiny or 0) + 1
		end
		if
			roulette
			and roulette.mutation
			and RouletteConfig.mutationRank(roulette.mutation)
				> RouletteConfig.mutationRank(entry.bestMutation)
		then
			entry.bestMutation = roulette.mutation
		end
		count = entry.count
		p.coins += value
		-- Same mutation as the collection and the prize: one catch, one record.
		newVariant = AquariumState.addOwned(p.aquarium, creature.id, variantId)
		aquariumVersion = p.aquarium.version
		p.stats.catches = (p.stats.catches or 0) + 1
		if creature.rarity == "Legendary" or creature.rarity == "Mystic" then
			p.stats.legendaries = (p.stats.legendaries or 0) + 1
		end
		if not isAuto and combo > (p.stats.bestCombo or 0) then
			p.stats.bestCombo = combo
		end
	end)
	Analytics.coins(player, true, value, "Catch", creature.id)
	Analytics.step(player, "firstCatch")
	if (table.find(FishingConfig.RARITY_ORDER, creature.rarity) or 0) >= 3 then
		Analytics.step(player, "firstRare")
	end
	if creature.rarity == "Legendary" then
		Analytics.step(player, "firstLegendary")
	elseif creature.rarity == "Mystic" then
		Analytics.step(player, "firstMystic")
	end
	send(player, {
		event = "caught",
		castId = castId,
		creatureId = creature.id,
		weight = weight,
		value = value,
		isNew = isNew,
		count = count,
		variant = if shiny then "Shiny" else "",
		isRecord = isRecord,
		previousBest = if isRecord then previousBest else nil,
		isGiant = isGiant,
		variantId = variantId,
		newVariant = newVariant,
		potentialCpm = AquariumConfig.rateCpm(creature.id, variantId) or 0,
		rewardCoins = value,
		aquariumVersion = aquariumVersion,
		combo = combo,
		comboBonus = comboBonus,
		comboMilestone = if not isAuto and COMBO_MILESTONES[combo] then combo else nil,
		eventId = if event then event.id else nil,
		auto = if isAuto then true else nil,
		odds = if odds and odds > 0 then odds else nil,
		spins = if roulette then roulette.spins else nil,
		sizeMult = if roulette then roulette.sizeMult else nil,
		mutation = if roulette then roulette.mutation else nil,
		coinMult = if roulette then roulette.coinMult else nil,
	})
	if not isAuto then
		Aquarium.onCatch(player, minigame or "", isNew)
	end
	Journey.onCatch(player, creature, isNew, isGiant)
	Progress.onCatch(player, creature, value, castId)
	Social.onCatch(player, creature, if shiny then "Shiny" else "")
	Trophy.onCatch(player, creature, weight, shiny)
end

local function onSubmit(player: Player, castId: unknown, success: unknown)
	if typeof(castId) ~= "number" or castId ~= castId or typeof(success) ~= "boolean" then
		return
	end
	local s = sessions[player]
	if not s then
		return
	end
	local now = os.clock()
	if success and s.wonCasts[castId] then
		recordSuspicious(player, s, now)
		return
	end
	if s.isAuto or s.phase ~= "fighting" or s.castId ~= castId then
		return
	end
	local elapsed = now - s.fightStart
	local baseMinimum = FishingConfig.MIN_FIGHT_SECONDS[s.kind] or 1
	local minimum = if now < s.penaltyUntil then baseMinimum * PENALTY_MULTIPLIER else baseMinimum
	local rateLimited = s.lastCatchAt ~= nil and (now - s.lastCatchAt) < CATCH_RATE_LIMIT
	local creature = Creatures.get(s.creatureId)
	local wonKind = s.kind -- reset() below clears it
	local wonEvent = s.eventId
	local wonOdds = s.odds
	-- The fight happens where the line was cast: walking (or teleporting) away loses the
	-- catch. Lenient radius so a small step near the zone edge never costs a real player.
	local root = rootOf(player)
	local stayed = root ~= nil and (root.Position - s.castPos).Magnitude <= MAX_FIGHT_DRIFT
	reset(player, s)
	if success then
		if elapsed < minimum or rateLimited then
			recordSuspicious(player, s, now)
		end
		if stayed and elapsed >= minimum and not rateLimited and creature then
			s.wonCasts[castId] = true
			s.lastCatchAt = now
			Analytics.fight(player, wonKind, creature.tier, "win", elapsed)
			payCatch(player, creature, castId, nil, wonKind, wonEvent, wonOdds)
			return
		end
	end
	if not success and creature and stayed and elapsed >= minimum then
		Analytics.fight(player, wonKind, creature.tier, "lose", elapsed)
	end
	send(player, { event = "escaped", castId = castId, comboLost = breakCombo(player) })
end

local function onCancel(player: Player)
	local s = sessions[player]
	if s and not s.isAuto and s.phase ~= "idle" then
		reset(player, s)
		send(player, { event = "cancelled", castId = s.castId, comboLost = breakCombo(player) })
	end
end

local function stopAuto(player: Player, s: Session, reason: string?, lockedZone: Zones.FishingZone?)
	local wasEnabled = s.autoEnabled
	s.autoEnabled = false
	s.autoToken += 1
	player:SetAttribute(Products.AUTO_FISH_ACTIVE_ATTRIBUTE, false)
	if s.isAuto and s.phase ~= "idle" then
		reset(player, s)
	end
	if wasEnabled and reason then
		send(player, {
			event = "rejected",
			reason = reason,
			auto = true,
			zoneId = if lockedZone then lockedZone.id else nil,
			minLevel = if lockedZone then lockedZone.minLevel else nil,
		})
	end
end

local function autoCanRun(player: Player, s: Session): (boolean, string?, Zones.FishingZone?)
	if not Monetization.ownsAutoFish(player) then
		return false, nil, nil
	end
	if not PlayerData.get(player) then
		return false, "loading", nil
	end
	local character = player.Character
	local root = rootOf(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (character and root and humanoid and humanoid.Health > 0) then
		return false, nil, nil
	end
	if (player:GetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE) or "") ~= "" then
		return false, "training", nil
	end
	local zoneId = syncPlayerZone(player)
	if zoneId == "" then
		return false, "notInZone", nil
	end
	local zone = Zones.get(zoneId)
	if zone and playerLevel(player) < zone.minLevel then
		return false, "levelLocked", zone
	end
	local rodTool = character:FindFirstChild("Rod")
	if not (rodTool and rodTool:IsA("Tool")) then
		return false, nil, nil
	end
	local currentRodId = (player:GetAttribute("EquippedRod") :: string?) or ""
	if s.autoRodId ~= "" and currentRodId ~= s.autoRodId then
		return false, nil, nil
	end
	local vel = root.AssemblyLinearVelocity
	local horizSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	if horizSpeed > AUTO_MAX_SPEED or (s.autoAnchor - root.Position).Magnitude > AUTO_MAX_DRIFT then
		return false, "moved", nil
	end
	return true, nil, zone
end

local function waitAutoSlice(player: Player, s: Session, token: number, duration: number): boolean
	local finish = os.clock() + duration
	while os.clock() < finish do
		if sessions[player] ~= s or not s.autoEnabled or s.autoToken ~= token then
			return false
		end
		local ok, reason, lockedZone = autoCanRun(player, s)
		if not ok then
			stopAuto(player, s, reason, lockedZone)
			return false
		end
		task.wait(math.min(0.2, math.max(0.05, finish - os.clock())))
	end
	if sessions[player] ~= s or not s.autoEnabled or s.autoToken ~= token then
		return false
	end
	local ok, reason, lockedZone = autoCanRun(player, s)
	if not ok then
		stopAuto(player, s, reason, lockedZone)
		return false
	end
	return true
end

local function runAutoLoop(player: Player, s: Session, token: number)
	while sessions[player] == s and s.autoEnabled and s.autoToken == token do
		local ok, reason, zone = autoCanRun(player, s)
		if not ok then
			stopAuto(player, s, reason, zone)
			break
		end
		local root = rootOf(player)
		if not root then
			stopAuto(player, s, nil)
			break
		end

		s.lastCast = os.clock()
		s.castPos = root.Position
		s.zoneId = if zone then zone.id else Zones.DEFAULT_ID
		s.castId += 1
		if s.castId > 200 then
			s.wonCasts[s.castId - 200] = nil
		end
		local castId = s.castId
		local castZone = s.zoneId
		s.phase = "waiting"
		s.isAuto = true

		local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
		local target = root.Position
			+ (if flat.Magnitude > 0 then flat.Unit else Vector3.zAxis)
				* FishingConfig.CAST_DISTANCE
		publish(player, "waiting", Vector3.new(target.X, 0, target.Z), nil)
		Progress.onCast(player)

		local biteDelay = rng:NextNumber(FishingConfig.BITE_DELAY_MIN, FishingConfig.BITE_DELAY_MAX)
		if not waitAutoSlice(player, s, token, biteDelay) then
			break
		end
		if s.castId ~= castId then
			break
		end

		local creature, odds = rollCreature(player, AUTO_MAX_RARITY_RANK, castZone)
		s.odds = odds
		local kind = rollMinigame(player)
		s.phase = "fighting"
		s.kind = kind
		s.creatureId = creature.id
		s.eventId = currentEventId()
		s.fightStart = os.clock()
		local character = player.Character
		publish(
			player,
			"fighting",
			character and character:GetAttribute("FishingTarget") :: Vector3?,
			creature.rarity
		)

		local fightTime = (FishingConfig.MIN_FIGHT_SECONDS[kind] or 1.5) * AUTO_FIGHT_MULTIPLIER
		if not waitAutoSlice(player, s, token, fightTime) then
			break
		end
		if s.castId ~= castId then
			break
		end

		local autoOdds = s.odds -- reset() clears it
		reset(player, s)
		local tierPenalty = math.max(0, creature.tier - 3) * AUTO_TIER_PENALTY
		local chance = math.clamp(AUTO_BASE_SUCCESS - tierPenalty, 0.10, AUTO_BASE_SUCCESS)
		if rng:NextNumber() < chance then
			s.wonCasts[castId] = true
			s.lastCatchAt = os.clock()
			payCatch(player, creature, castId, true, nil, s.eventId, autoOdds)
		else
			send(player, { event = "escaped", castId = castId, auto = true })
		end

		if not waitAutoSlice(player, s, token, FishingConfig.CAST_COOLDOWN + AUTO_EXTRA_DELAY) then
			break
		end
	end
end

local function onSetAutoFish(player: Player, enabled: unknown)
	if typeof(enabled) ~= "boolean" or not Monetization.ownsAutoFish(player) then
		return
	end
	local s = session(player)
	if not enabled then
		stopAuto(player, s, nil)
		return
	end
	if s.autoEnabled or s.phase ~= "idle" then
		return
	end
	local character = player.Character
	local root = rootOf(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (character and root and humanoid and humanoid.Health > 0) then
		return
	end
	if (player:GetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE) or "") ~= "" then
		send(player, { event = "rejected", reason = "training", auto = true })
		return
	end
	local zoneId = syncPlayerZone(player)
	if zoneId == "" then
		send(player, { event = "rejected", reason = "notInZone", auto = true })
		return
	end
	local zone = Zones.get(zoneId)
	if zone and playerLevel(player) < zone.minLevel then
		send(player, {
			event = "rejected",
			reason = "levelLocked",
			zoneId = zone.id,
			minLevel = zone.minLevel,
			auto = true,
		})
		return
	end
	local vel = root.AssemblyLinearVelocity
	if Vector3.new(vel.X, 0, vel.Z).Magnitude > AUTO_MAX_SPEED then
		send(player, { event = "rejected", reason = "moved", auto = true })
		return
	end
	if not character:FindFirstChild("Rod") then
		local backpack = player:FindFirstChildOfClass("Backpack")
		local bpRod = backpack and backpack:FindFirstChild("Rod")
		if bpRod and bpRod:IsA("Tool") then
			humanoid:EquipTool(bpRod)
		else
			return
		end
	end

	s.autoRodId = (player:GetAttribute("EquippedRod") :: string?) or ""
	s.autoAnchor = root.Position
	s.autoEnabled = true
	s.autoToken += 1
	local token = s.autoToken
	player:SetAttribute(Products.AUTO_FISH_ACTIVE_ATTRIBUTE, true)
	task.spawn(runAutoLoop, player, s, token)
end

-- Used by portals: cancels active manual or auto fishing cleanly before teleporting.
function Fishing.cancelFor(player: Player)
	local s = sessions[player]
	if not s then
		return
	end
	if s.autoEnabled then
		stopAuto(player, s, nil)
	elseif s.phase ~= "idle" then
		reset(player, s)
		send(player, { event = "cancelled", castId = s.castId })
	end
end

function Fishing.start()
	update = Remotes.event(Net.FISHING_UPDATE)
	Remotes.onServerEvent(Net.CAST_LINE, 2, 3, onCast)
	Remotes.onServerEvent(Net.CANCEL_FISHING, 2, 3, onCancel)
	Remotes.onServerEvent(Net.POWER_TAP, 3, 3, onPowerTap)
	Remotes.onServerEvent(Net.SUBMIT_CATCH, 2, 3, onSubmit)
	Remotes.onServerEvent(Net.SET_AUTO_FISH, 1, 2, onSetAutoFish)
	local function watchCharacter(player: Player, character: Model)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				local s = sessions[player]
				if not s then
					return
				end
				if s.autoEnabled then
					stopAuto(player, s, nil)
				elseif s.phase ~= "idle" then
					reset(player, s)
					send(player, { event = "cancelled", castId = s.castId })
				end
			end)
		end
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child.Name == "Rod" then
				local s = sessions[player]
				if s and s.autoEnabled then
					stopAuto(player, s, nil)
				end
			end
		end)
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child.Name ~= "Rod" then
				local s = sessions[player]
				if s and s.autoEnabled then
					stopAuto(player, s, nil)
				end
			end
		end)
	end
	local function watch(player: Player)
		player:SetAttribute(Products.AUTO_FISH_ACTIVE_ATTRIBUTE, false)
		player:SetAttribute(Zones.PLAYER_ATTRIBUTE, "")
		player:GetAttributeChangedSignal("EquippedRod"):Connect(function()
			local s = sessions[player]
			if s and s.autoEnabled then
				stopAuto(player, s, nil)
			end
		end)
		player:GetAttributeChangedSignal(TrainingConfig.ACTIVE_ATTRIBUTE):Connect(function()
			local s = sessions[player]
			if
				s
				and s.autoEnabled
				and (player:GetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE) or "") ~= ""
			then
				stopAuto(player, s, "training")
			end
		end)
		player:GetAttributeChangedSignal(Products.AUTO_FISH_OWNED_ATTRIBUTE):Connect(function()
			local s = sessions[player]
			if s and s.autoEnabled and not Monetization.ownsAutoFish(player) then
				stopAuto(player, s, nil)
			end
		end)
		if player.Character then
			watchCharacter(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			watchCharacter(player, character)
		end)
		player.CharacterRemoving:Connect(function()
			local s = sessions[player]
			if s then
				if s.autoEnabled then
					stopAuto(player, s, nil)
				elseif s.phase ~= "idle" then
					s.phase = "idle"
					s.kind = ""
					s.creatureId = ""
					send(player, { event = "cancelled", castId = s.castId })
				end
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				syncPlayerZone(player)
			end
			task.wait(0.25)
		end
	end)
end

return Fishing
