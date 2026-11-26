--!strict
-- Achievements and promo codes (server authority). `Achievements.check(player)` is called after
-- anything that moves a counter (a catch, a training level). Unlocks pay coins and are announced
-- on the AdventureReward remote (kind = "achievement"). Codes arrive on RedeemCode and answer on
-- the same remote (kind = "code" | "codeInvalid" | "codeUsed").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local AchievementConfig = require(Config:WaitForChild("Achievements"))
local CodeConfig = require(Config:WaitForChild("Codes"))
local Creatures = require(Config:WaitForChild("Creatures"))
local Net = require(Shared:WaitForChild("Net"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

local Achievements = {}
Achievements.order = 46

local reward: RemoteEvent
local lastRedeem: { [Player]: number } = {}

local function metrics(profile: PlayerData.Profile): { [string]: number }
	local species, mystic = 0, 0
	local collection: { [string]: any } = profile.collection or {}
	for id in collection do
		species += 1
		local creature = Creatures.get(id)
		if creature and creature.rarity == "Mystic" then
			mystic += 1
		end
	end
	local training = 0
	local trainingStats: { [string]: any } = profile.training or {}
	for _, t in trainingStats do
		training = math.max(training, t.level or 0)
	end
	local stats = profile.stats
	return {
		catches = if stats then stats.catches or 0 else 0,
		species = species,
		legendaries = if stats then stats.legendaries or 0 else 0,
		level = if stats then stats.level or 1 else 1,
		combo = if stats then stats.bestCombo or 0 else 0,
		training = training,
		mystic = mystic,
	}
end

function Achievements.check(player: Player)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local values = metrics(profile)
	local unlocked: { { id: string, coins: number } } = {}
	for _, a in AchievementConfig.LIST do
		if not profile.achievements[a.id] and (values[a.metric] or 0) >= a.target then
			table.insert(unlocked, { id = a.id, coins = a.reward })
		end
	end
	if #unlocked == 0 then
		return
	end
	PlayerData.update(player, function(p)
		for _, u in unlocked do
			if not p.achievements[u.id] then
				p.achievements[u.id] = os.time()
				p.coins += u.coins
			end
		end
	end)
	Analytics.step(player, "firstAchievement")
	for _, u in unlocked do
		reward:FireClient(
			player,
			{ kind = "achievement", id = u.id, coins = u.coins } :: Net.AdventureReward
		)
	end
end

local function onRedeem(player: Player, text: unknown)
	if typeof(text) ~= "string" or #text > 40 then
		return
	end
	-- Light throttle on top of the remote rate limit: one try every 2 seconds.
	local now = os.clock()
	if now - (lastRedeem[player] or -10) < 2 then
		return
	end
	lastRedeem[player] = now
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local code = CodeConfig.find(text)
	if not code then
		reward:FireClient(player, { kind = "codeInvalid" } :: Net.AdventureReward)
		return
	end
	if profile.redeemed[code.code] then
		reward:FireClient(player, { kind = "codeUsed" } :: Net.AdventureReward)
		return
	end
	PlayerData.update(player, function(p)
		p.redeemed[code.code] = true
		p.coins += code.coins
	end)
	Analytics.coins(player, true, code.coins, "Code", code.code)
	Analytics.step(player, "firstCodeRedeemed")
	reward:FireClient(player, { kind = "code", coins = code.coins } :: Net.AdventureReward)
end

function Achievements.start()
	reward = Remotes.event(Net.ADVENTURE_REWARD)
	Remotes.onServerEvent(Net.REDEEM_CODE, 1, 2, onRedeem)
	Players.PlayerRemoving:Connect(function(player)
		lastRedeem[player] = nil
	end)
end

return Achievements
