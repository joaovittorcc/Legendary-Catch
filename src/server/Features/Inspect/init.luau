--!strict
-- Public player album inspection: serves another online player's public collection stats
-- on demand without ever exposing private fields (coins, rods, purchases, telemetry).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local Net = require(Shared:WaitForChild("Net"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

local Inspect = {}
Inspect.order = 90

local resultRemote: RemoteEvent

local function onInspect(player: Player, userId: unknown)
	if
		typeof(userId) ~= "number"
		or userId ~= userId
		or userId ~= math.floor(userId)
		or userId <= 0
		or userId == math.huge
	then
		return
	end

	local target = Players:GetPlayerByUserId(userId)
	if not target then
		return
	end

	local profile = PlayerData.get(target)
	if not profile then
		return
	end

	local discovered: { string } = {}
	local bestWeights: { [string]: number } = {}
	local shinyCounts: { [string]: number } = {}
	local species = 0
	local shinies = 0

	for creatureId, entry in profile.collection do
		if Creatures.get(creatureId) then
			species += 1
			table.insert(discovered, creatureId)
			bestWeights[creatureId] = entry.bestWeight
			local s = entry.shiny
			if typeof(s) == "number" and s > 0 then
				shinies += s
				shinyCounts[creatureId] = s
			end
		end
	end
	table.sort(discovered)

	local payload: Net.InspectResult = {
		userId = target.UserId,
		displayName = target.DisplayName,
		level = profile.stats.level,
		prestige = profile.prestige or 0,
		species = species,
		catches = profile.stats.catches,
		shinies = shinies,
		discovered = discovered,
		bestWeights = bestWeights,
		shinyCounts = shinyCounts,
	}
	resultRemote:FireClient(player, payload)
end

function Inspect.start()
	resultRemote = Remotes.event(Net.INSPECT_RESULT)
	Remotes.onServerEvent(Net.INSPECT_PLAYER, 1, 1, onInspect)
end

return Inspect
