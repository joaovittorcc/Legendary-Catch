--!strict
-- Player level ("Journey"): XP for every catch, coins on every level-up. The level lives in the
-- profile (stats.level / stats.levelXp); attributes mirror it for the HUD:
--   PlayerLevel, PlayerLevelXP (xp into this level), PlayerLevelXPTotal (xp needed for the next).
-- Level-ups are announced on the AdventureReward remote (the client only displays them).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Net = require(Shared:WaitForChild("Net"))
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

local Journey = {}
Journey.order = 45

local MAX_LEVEL = 100
-- XP per catch by rarity rank (Common ... Mystic); a first discovery doubles it, a giant adds half.
local XP_BY_RANK = { 5, 8, 15, 30, 80, 200 }

local reward: RemoteEvent

function Journey.xpToNext(level: number): number
	return 30 + level * 20
end

function Journey.levelUpCoins(level: number): number
	return 25 * level
end

local function mirror(player: Player)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local level = profile.stats.level
	player:SetAttribute("PlayerLevel", level)
	player:SetAttribute("PlayerLevelXP", profile.stats.levelXp)
	player:SetAttribute("PlayerLevelXPTotal", Journey.xpToNext(level))
end

-- Called by Fishing after a paid catch.
function Journey.onCatch(
	player: Player,
	creature: Creatures.Creature,
	isNew: boolean,
	isGiant: boolean
)
	local rank = table.find(FishingConfig.RARITY_ORDER, creature.rarity) or 1
	local xp = XP_BY_RANK[math.clamp(rank, 1, #XP_BY_RANK)]
	if isNew then
		xp *= 2
	end
	if isGiant then
		xp = math.floor(xp * 1.5)
	end
	local gained: { { level: number, coins: number } } = {}
	PlayerData.update(player, function(p)
		local stats = p.stats
		stats.levelXp += xp
		while stats.level < MAX_LEVEL and stats.levelXp >= Journey.xpToNext(stats.level) do
			stats.levelXp -= Journey.xpToNext(stats.level)
			stats.level += 1
			local coins = Journey.levelUpCoins(stats.level)
			p.coins += coins
			table.insert(gained, { level = stats.level, coins = coins })
		end
		if stats.level >= MAX_LEVEL then
			stats.levelXp = 0
		end
	end)
	mirror(player)
	-- Every 10th catch opens a surprise chest.
	local profile = PlayerData.get(player)
	if profile and profile.stats.catches % 10 == 0 then
		local level = profile.stats.level
		local coins = math.random(100, 300) + level * 10
		PlayerData.update(player, function(p)
			p.coins += coins
		end)
		reward:FireClient(
			player,
			{ kind = "chest", coins = coins, level = level } :: Net.AdventureReward
		)
	end
	for _, g in gained do
		reward:FireClient(
			player,
			{ kind = "level", level = g.level, coins = g.coins } :: Net.AdventureReward
		)
	end
end

function Journey.start()
	reward = Remotes.event(Net.ADVENTURE_REWARD)
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
end

return Journey
