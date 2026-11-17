--!strict
-- Server authority for fishing: validates the cast spot, waits for the bite, rolls the
-- creature (kept secret until the catch), picks one minigame and judges the result.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Net = require(Shared:WaitForChild("Net"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))

local Training = require(script.Parent:WaitForChild("Training"))

type Session = {
	phase: string, -- "idle" | "waiting" | "fighting"
	castId: number,
	lastCast: number,
	fightStart: number,
	kind: string,
	creatureId: string,
}

local Fishing = {}

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

local function inFishingZone(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return false
	end
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

-- Instinct training tilts the odds toward rarer creatures (capped in Config/Training).
local function luckyWeights(player: Player): { [string]: number }
	local instinct = Training.level(player, "Instinct")
	local weights: { [string]: number } = {}
	for rank, rarity in FishingConfig.RARITY_ORDER do
		weights[rarity] = (FishingConfig.RARITY_WEIGHTS[rarity] or 0)
			* TrainingConfig.luckMultiplier(instinct, rank)
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

local function reset(s: Session)
	s.phase = "idle"
	s.kind = ""
	s.creatureId = ""
end

local function onCast(player: Player)
	local s = session(player)
	local now = os.clock()
	if s.phase ~= "idle" or now - s.lastCast < FishingConfig.CAST_COOLDOWN then
		return
	end
	if not inFishingZone(player) then
		send(player, { event = "rejected", reason = "notInZone" })
		return
	end
	s.lastCast = now
	s.castId += 1
	s.phase = "waiting"
	local castId = s.castId
	send(player, { event = "cast", castId = castId })

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
					reset(s)
					send(player, { event = "escaped", castId = castId })
				end
			end)
		end
	)
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
	local caught = success and elapsed >= minimum
	local creatureId = s.creatureId
	reset(s)
	if caught then
		send(player, { event = "caught", castId = castId, creatureId = creatureId })
	else
		send(player, { event = "escaped", castId = castId })
	end
end

local function onCancel(player: Player)
	local s = sessions[player]
	if s and s.phase ~= "idle" then
		reset(s)
		send(player, { event = "cancelled", castId = s.castId })
	end
end

function Fishing.start()
	local folder = ReplicatedStorage:FindFirstChild(Net.FOLDER) or Instance.new("Folder")
	folder.Name = Net.FOLDER
	folder.Parent = ReplicatedStorage

	local function remote(name: string): RemoteEvent
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = folder
		return r
	end

	local cast = remote(Net.CAST_LINE)
	local cancel = remote(Net.CANCEL_FISHING)
	local submit = remote(Net.SUBMIT_CATCH)
	update = remote(Net.FISHING_UPDATE)

	cast.OnServerEvent:Connect(onCast)
	cancel.OnServerEvent:Connect(onCancel)
	submit.OnServerEvent:Connect(onSubmit)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

return Fishing
