--!strict
-- Prestige ("Maré Nova") server handler: resets progression for permanent bonuses.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local PrestigeConfig = require(Shared:WaitForChild("Config"):WaitForChild("Prestige"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))

local Features = script.Parent
local Analytics = require(Features:WaitForChild("Analytics"))
local PlayerData = require(Features:WaitForChild("PlayerData"))
local Rod = require(Features:WaitForChild("Rod"))
local Remotes = require(Features.Parent:WaitForChild("Remotes"))

local Prestige = {
	order = 35,
}

function Prestige.level(player: Player): number
	local profile = PlayerData.get(player)
	return if profile
		then math.clamp(math.floor(profile.prestige or 0), 0, PrestigeConfig.MAX_LEVEL)
		else 0
end

local function mirror(player: Player)
	player:SetAttribute(PrestigeConfig.ATTRIBUTE, Prestige.level(player))
end

local function onPrestige(player: Player)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end

	local current = math.clamp(math.floor(profile.prestige or 0), 0, PrestigeConfig.MAX_LEVEL)
	local species = PrestigeConfig.speciesCount(profile.collection)
	if not PrestigeConfig.canPrestige(current, profile.coins, species) then
		return
	end

	local nextLevel = 0
	local gift = 0
	local applied = false

	PlayerData.update(player, function(p)
		local recheckCurrent = math.clamp(math.floor(p.prestige or 0), 0, PrestigeConfig.MAX_LEVEL)
		local recheckSpecies = PrestigeConfig.speciesCount(p.collection)
		if not PrestigeConfig.canPrestige(recheckCurrent, p.coins, recheckSpecies) then
			return
		end

		nextLevel = recheckCurrent + 1
		gift = PrestigeConfig.giftCoins(nextLevel)
		p.prestige = nextLevel
		p.coins = gift
		p.rodsOwned = { Rods.STARTER }
		p.equippedRod = Rods.STARTER
		for _, stat in TrainingConfig.STATS do
			p.training[stat] = { level = 0, xp = 0 }
		end
		applied = true
	end)

	if not applied then
		return
	end

	Rod.refresh(player)
	mirror(player)
	Analytics.coins(player, true, gift, "Prestige", "prestige_" .. tostring(nextLevel))
	Analytics.step(player, "firstPrestige")

	local reward: Net.AdventureReward = {
		kind = "prestige",
		level = nextLevel,
		coins = gift,
	}
	Remotes.event(Net.ADVENTURE_REWARD):FireClient(player, reward)
end

function Prestige.start()
	local function watch(player: Player)
		if player:GetAttribute("DataLoaded") then
			mirror(player)
		end
		player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
			mirror(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Remotes.onServerEvent(Net.DO_PRESTIGE, 1, 2, onPrestige)
end

return Prestige
