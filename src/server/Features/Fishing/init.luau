--!strict
-- Server authority for fishing: validates the cast spot, waits for the bite, rolls the
-- creature (kept secret until the catch), picks one minigame and judges the result.
-- On a catch it rolls the weight, pays coins and records the collection entry.
-- Other players see the line through Character attributes (FishingState/Target/Rarity).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Net = require(Shared:WaitForChild("Net"))
local Products = require(Shared:WaitForChild("Config"):WaitForChild("Products"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))

local Features = script.Parent
local Analytics = require(Features:WaitForChild("Analytics"))
local Monetization = require(Features:WaitForChild("Monetization"))
local OceanEvents = require(Features:WaitForChild("OceanEvents"))
local PlayerData = require(Features:WaitForChild("PlayerData"))
local Progress = require(Features:WaitForChild("Progress"))
local Social = require(Features:WaitForChild("Social"))
local Training = require(Features:WaitForChild("Training"))
local Remotes = require(Features.Parent:WaitForChild("Remotes"))

type Session = {
	phase: string, -- "idle" | "waiting" | "fighting"
	castId: number,
	lastCast: number,
	fightStart: number,
	kind: string,
	creatureId: string,
}

local Fishing = {}
Fishing.order = 50

local sessions: { [Player]: Session } = {}
local rng = Random.new()
local update: RemoteEvent

local function session(player: Player): Session
	local s = sessions[player]
	if not s then
		s = { phase = "idle", castId = 0, lastCast = 0, fightStart = 0, kind = "", creatureId = "" }
		sessions[player] = s
	end
	return s
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

local function inFishingZone(root: BasePart): boolean
	for _, zone in CollectionService:GetTagged(FishingConfig.ZONE_TAG) do
		if zone:IsA("BasePart") then
			local localPos = zone.CFrame:PointToObjectSpace(root.Position)
			local half = zone.Size / 2
			if
				math.abs(localPos.X) <= half.X
				and math.abs(localPos.Y) <= half.Y
				and math.abs(localPos.Z) <= half.Z
			then
				return true
			end
		end
	end
	return false
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

-- Instinct training, the equipped rod and the active ocean event all tilt the odds
-- toward rarer creatures (each capped in its own config).
local function luckyWeights(player: Player): { [string]: number }
	local instinct = Training.level(player, "Instinct")
	local rod = equippedRod(player)
	local event = OceanEvents.current()
	local boosted = Monetization.luckBoostActive(player)
	local weights: { [string]: number } = {}
	for rank, rarity in FishingConfig.RARITY_ORDER do
		local w = (FishingConfig.RARITY_WEIGHTS[rarity] or 0)
			* TrainingConfig.luckMultiplier(instinct, rank)
			* Rods.luckMultiplier(rod, rank)
		if event then
			w *= event.rarityBoost[rarity] or 1
		end
		-- Paid luck boost only lifts Rare and above; it never guarantees anything.
		if boosted and rank >= 3 then
			w *= Products.LUCK_BOOST_MULTIPLIER
		end
		weights[rarity] = w
	end
	return weights
end

local function rollCreature(player: Player): Creatures.Creature
	local rarity = devOverride(player, "DevForceRarity")
		or weightedPick(luckyWeights(player), FishingConfig.RARITY_ORDER)
	local pool = Creatures.ofRarity(rarity)
	if #pool == 0 then
		pool = Creatures.LIST
	end
	return pool[rng:NextInteger(1, #pool)]
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

local function reset(player: Player, s: Session)
	s.phase = "idle"
	s.kind = ""
	s.creatureId = ""
	publish(player, "", nil, nil)
end

local function onCast(player: Player)
	local s = session(player)
	local now = os.clock()
	if s.phase ~= "idle" or now - s.lastCast < FishingConfig.CAST_COOLDOWN then
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
	if not inFishingZone(root) then
		send(player, { event = "rejected", reason = "notInZone" })
		return
	end
	s.lastCast = now
	s.castId += 1
	s.phase = "waiting"
	local castId = s.castId
	local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local target = root.Position
		+ (if flat.Magnitude > 0 then flat.Unit else Vector3.zAxis)
			* FishingConfig.CAST_DISTANCE
	publish(player, "waiting", Vector3.new(target.X, 0, target.Z), nil)
	send(player, { event = "cast", castId = castId })
	Analytics.step(player, "firstCast")
	Progress.onCast(player)

	task.delay(
		rng:NextNumber(FishingConfig.BITE_DELAY_MIN, FishingConfig.BITE_DELAY_MAX),
		function()
			if sessions[player] ~= s or s.castId ~= castId or s.phase ~= "waiting" then
				return
			end
			local creature = rollCreature(player)
			s.phase = "fighting"
			s.kind = rollMinigame(player)
			s.creatureId = creature.id
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
					reset(player, s)
					send(player, { event = "escaped", castId = castId })
				end
			end)
		end
	)
end

local function payCatch(player: Player, creature: Creatures.Creature, castId: number)
	local weight = rollWeight(creature)
	local event = OceanEvents.current()
	local forced = devOverride(player, "DevForceVariant")
	local shiny = forced == "Shiny"
		or (forced == nil and rng:NextNumber() < FishingConfig.SHINY_CHANCE)
	local value = math.floor(
		Creatures.valueFor(creature, weight)
			* (if event then event.valueMultiplier else 1)
			* (if shiny then FishingConfig.SHINY_VALUE_MULTIPLIER else 1)
			* Monetization.coinMultiplier(player)
	)
	local isNew, count = false, 1
	PlayerData.update(player, function(p)
		local entry = p.collection[creature.id]
		if entry then
			entry.count += 1
			entry.bestWeight = math.max(entry.bestWeight, weight)
		else
			isNew = true
			entry = { count = 1, bestWeight = weight, firstAt = os.time(), shiny = 0 }
			p.collection[creature.id] = entry
		end
		if shiny then
			entry.shiny = (entry.shiny or 0) + 1
		end
		count = entry.count
		p.coins += value
		p.stats.catches += 1
		if creature.rarity == "Legendary" then
			p.stats.legendaries += 1
		end
	end)
	Analytics.coins(player, true, value, "Catch", creature.id)
	Analytics.step(player, "firstCatch")
	if (table.find(FishingConfig.RARITY_ORDER, creature.rarity) or 0) >= 3 then
		Analytics.step(player, "firstRare")
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
	})
	Progress.onCatch(player, creature, value, castId)
	Social.onCatch(player, creature, if shiny then "Shiny" else "")
end

local function onSubmit(player: Player, castId: unknown, success: unknown)
	if typeof(castId) ~= "number" or typeof(success) ~= "boolean" then
		return
	end
	local s = sessions[player]
	if not s or s.phase ~= "fighting" or s.castId ~= castId then
		return
	end
	local elapsed = os.clock() - s.fightStart
	local minimum = FishingConfig.MIN_FIGHT_SECONDS[s.kind] or 1
	local creature = Creatures.get(s.creatureId)
	reset(player, s)
	if success and elapsed >= minimum and creature then
		payCatch(player, creature, castId)
	else
		send(player, { event = "escaped", castId = castId })
	end
end

local function onCancel(player: Player)
	local s = sessions[player]
	if s and s.phase ~= "idle" then
		reset(player, s)
		send(player, { event = "cancelled", castId = s.castId })
	end
end

function Fishing.start()
	update = Remotes.event(Net.FISHING_UPDATE)
	Remotes.onServerEvent(Net.CAST_LINE, 2, 3, onCast)
	Remotes.onServerEvent(Net.CANCEL_FISHING, 2, 3, onCancel)
	Remotes.onServerEvent(Net.SUBMIT_CATCH, 2, 3, onSubmit)
	local function watch(player: Player)
		player.CharacterRemoving:Connect(function()
			local s = sessions[player]
			if s and s.phase ~= "idle" then
				s.phase = "idle"
				s.kind = ""
				s.creatureId = ""
				send(player, { event = "cancelled", castId = s.castId })
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
end

return Fishing
