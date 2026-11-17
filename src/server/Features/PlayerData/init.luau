--!strict
-- Player profile: single source of truth for coins, rods, collection, training and stats.
-- Features change it only through PlayerData.update, which pushes a fresh snapshot to the
-- client (debounced) and mirrors hot values as Player attributes for the HUD.
--
-- Storage: in memory for now (data resets on leave). The Store section is the only place
-- that changes when real persistence lands (ProfileStore pending João's OK).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))
local Types = require(Shared:WaitForChild("Types"))

local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

export type Profile = {
	version: number,
	coins: number,
	equippedRod: string,
	rodsOwned: { string },
	collection: { [string]: Types.CollectionEntry },
	training: { [string]: Types.TrainingStat },
	stats: Types.Stats,
}

local SCHEMA_VERSION = 1
local STARTER_ROD = "starter"

local PlayerData = {}
PlayerData.order = 10

local profiles: { [Player]: Profile } = {}
local dirty: { [Player]: boolean } = {}
local loadedEvent = Instance.new("BindableEvent")
local snapshotRemote: RemoteEvent

-- Template -------------------------------------------------------------------------------

local function template(): Profile
	local training: { [string]: Types.TrainingStat } = {}
	for _, stat in TrainingConfig.STATS do
		training[stat] = { level = 0, xp = 0 }
	end
	return {
		version = SCHEMA_VERSION,
		coins = 0,
		equippedRod = STARTER_ROD,
		rodsOwned = { STARTER_ROD },
		collection = {},
		training = training,
		stats = { catches = 0, legendaries = 0 },
	}
end

-- Fills fields missing from older saves; never overwrites existing values.
local function reconcile(data: { [string]: any }): Profile
	local defaults = template() :: any
	for key, value in defaults do
		if data[key] == nil then
			data[key] = value
		end
	end
	for stat, value in defaults.training do
		if data.training[stat] == nil then
			data.training[stat] = value
		end
	end
	for key, value in defaults.stats do
		if data.stats[key] == nil then
			data.stats[key] = value
		end
	end
	if not table.find(data.rodsOwned, STARTER_ROD) then
		table.insert(data.rodsOwned, STARTER_ROD)
	end
	data.version = SCHEMA_VERSION
	return data :: Profile
end

-- Store (in memory) ----------------------------------------------------------------------

local Store = {}

function Store.load(_userId: number): { [string]: any }?
	return nil
end

function Store.save(_userId: number, _data: Profile) end

-- Snapshot -----------------------------------------------------------------------------

local function snapshot(profile: Profile): Types.Snapshot
	return {
		coins = profile.coins,
		equippedRod = profile.equippedRod,
		rodsOwned = table.clone(profile.rodsOwned),
		collection = table.clone(profile.collection),
		training = table.clone(profile.training),
		stats = table.clone(profile.stats),
	}
end

local function mirrorAttributes(player: Player, profile: Profile)
	player:SetAttribute("Coins", profile.coins)
	player:SetAttribute("EquippedRod", profile.equippedRod)
	for stat, t in profile.training do
		player:SetAttribute(TrainingConfig.levelAttribute(stat), t.level)
		player:SetAttribute(TrainingConfig.xpAttribute(stat), t.xp)
	end
end

local function push(player: Player)
	local profile = profiles[player]
	if profile then
		snapshotRemote:FireClient(player, snapshot(profile))
	end
end

-- Coalesces several updates in the same frame into one snapshot.
local function markDirty(player: Player)
	if dirty[player] then
		return
	end
	dirty[player] = true
	task.defer(function()
		dirty[player] = nil
		push(player)
	end)
end

-- API ---------------------------------------------------------------------------------

function PlayerData.get(player: Player): Profile?
	return profiles[player]
end

-- Yields until the player's profile is loaded (nil if they leave first).
function PlayerData.wait(player: Player): Profile?
	while player.Parent and not profiles[player] do
		loadedEvent.Event:Wait()
	end
	return profiles[player]
end

-- The only way to change a profile. `mutate` runs synchronously and must not yield.
function PlayerData.update(player: Player, mutate: (Profile) -> ()): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	mutate(profile)
	mirrorAttributes(player, profile)
	markDirty(player)
	return true
end

-- Atomic spend: true and deducted when the player can afford it.
function PlayerData.trySpend(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or amount < 0 or profile.coins < amount then
		return false
	end
	PlayerData.update(player, function(p)
		p.coins -= amount
	end)
	return true
end

function PlayerData.addCoins(player: Player, amount: number)
	PlayerData.update(player, function(p)
		p.coins += math.max(0, math.floor(amount))
	end)
end

PlayerData.Loaded = loadedEvent.Event

-- Lifecycle ----------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	local stored = Store.load(player.UserId)
	if not player.Parent then
		return
	end
	local profile = reconcile(stored or (template() :: any))
	profiles[player] = profile
	mirrorAttributes(player, profile)
	player:SetAttribute("DataLoaded", true)
	push(player)
	loadedEvent:Fire(player)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile then
		Store.save(player.UserId, profile)
	end
	profiles[player] = nil
	dirty[player] = nil
end

function PlayerData.start()
	snapshotRemote = Remotes.event(Net.PROFILE_SNAPSHOT)
	Remotes.onServerEvent(Net.REQUEST_PROFILE, 1, 3, function(player)
		push(player)
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	game:BindToClose(function()
		for player, profile in profiles do
			Store.save(player.UserId, profile)
		end
	end)
end

return PlayerData
