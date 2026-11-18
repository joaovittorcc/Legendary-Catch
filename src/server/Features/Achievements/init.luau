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

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

local Achievements = {}
Achievements.order = 46

local reward: RemoteEvent
local lastRedeem: { [Player]: number } = {}

local function metrics(profile: PlayerData.Profile): { [string]: number }
	local species, mystic = 0, 0
	for id in profile.collection do
		species += 1
		local creature = Creatures.get(id)
		if creature and creature.rarity == "Mystic" then
			mystic += 1
		end
	end
	local training = 0
	for _, t in profile.training do
		training = math.max(training, t.level)
	end
	return {
		catches = profile.stats.catches,
		species = species,
		legendaries = profile.stats.legendaries,
		level = profile.stats.level,
		combo = profile.stats.bestCombo,
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
