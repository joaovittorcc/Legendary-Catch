--!strict
-- Player profile: single source of truth for coins, rods, collection, training and stats.
-- Features change it only through PlayerData.update, which pushes a fresh snapshot to the
-- client (debounced) and mirrors hot values as Player attributes for the HUD.
--
-- Storage: ProfileStore (session-locked, autosaves, saves on leave and on shutdown).
-- Rules that keep saves safe:
--   * migrate BEFORE reconciling (reconcile hides the "field is missing" a migration looks for)
--   * a load that fails kicks the player; never start them on a blank profile that would
--     overwrite their real save
--   * new fields are additive: add them to the template with a default
-- Studio uses its own store ("PlayerData_Studio") so tests never touch live saves. Without
-- "Enable Studio Access to API Services" ProfileStore runs as a mock (nothing persists).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))
local Types = require(Shared:WaitForChild("Types"))

local ProfileStore =
	require(ServerScriptService:WaitForChild("ServerPackages"):WaitForChild("ProfileStore"))

local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

export type Profile = {
	version: number,
	coins: number,
	equippedRod: string,
	rodsOwned: { string },
	collection: { [string]: Types.CollectionEntry },
	training: { [string]: Types.TrainingStat },
	stats: Types.Stats,
	funnel: { [string]: boolean }, -- analytics onboarding steps already logged
	tutorial: Types.Tutorial,
	missions: Types.Missions,
	milestones: { [string]: boolean },
	settings: Types.Settings,
	purchases: { [string]: boolean }, -- Robux receipt ids already granted
	purchaseOrder: { string }, -- same ids, oldest first (bounds the record)
	boosts: { luckUntil: number }, -- os.time() when each paid boost ends
	daily: Types.Daily,
}

-- The Wally shim does not re-export ProfileStore's types; only the members used here.
type Session = {
	Data: any,
	OnSessionEnd: { Connect: (self: any, listener: () -> ()) -> any },
	IsActive: (self: any) -> boolean,
	Reconcile: (self: any) -> (),
	EndSession: (self: any) -> (),
	Save: (self: any) -> (),
	AddUserId: (self: any, userId: number) -> (),
}

local SCHEMA_VERSION = 1
local STARTER_ROD = "starter"
local STORE_NAME = if RunService:IsStudio() then "PlayerData_Studio" else "PlayerData"

local PlayerData = {}
PlayerData.order = 10

local profiles: { [Player]: Profile } = {}
local sessions: { [Player]: Session } = {}
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
		stats = { catches = 0, legendaries = 0, level = 1, levelXp = 0, bestCombo = 0 },
		funnel = {},
		tutorial = { step = "goToPier", done = false },
		missions = { day = 0, list = {} },
		milestones = {},
		settings = { music = 0.6, sfx = 0.8, reduceEffects = false },
		purchases = {},
		purchaseOrder = {},
		boosts = { luckUntil = 0 },
		daily = { lastDay = 0, days = 0, lastGift = 0, grantedAt = 0 },
	}
end

local store = ProfileStore.New(STORE_NAME, template())

-- Version steps go here (v1 -> v2 ...). Each returns nil on success or an error string.
-- Runs before reconcile. There are none yet: v1 is the first schema.
local function migrate(data: { [string]: any }): string?
	if typeof(data.version) ~= "number" then
		data.version = SCHEMA_VERSION
	end
	if data.version > SCHEMA_VERSION then
		return `save is from a newer version ({data.version})`
	end
	return nil
end

-- Fills fields missing from older saves (nested too), in place; never overwrites values.
local function reconcile(data: { [string]: any })
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
	for key, value in defaults.boosts do
		if data.boosts[key] == nil then
			data.boosts[key] = value
		end
	end
	for key, value in defaults.settings do
		if data.settings[key] == nil then
			data.settings[key] = value
		end
	end
	for key, value in defaults.daily do
		if data.daily[key] == nil then
			data.daily[key] = value
		end
	end
	if not table.find(data.rodsOwned, STARTER_ROD) then
		table.insert(data.rodsOwned, STARTER_ROD)
	end
	data.version = SCHEMA_VERSION
end

-- Snapshot -----------------------------------------------------------------------------

local function snapshot(profile: Profile): Types.Snapshot
	return {
		coins = profile.coins,
		equippedRod = profile.equippedRod,
		rodsOwned = table.clone(profile.rodsOwned),
		collection = table.clone(profile.collection),
		training = table.clone(profile.training),
		stats = table.clone(profile.stats),
		tutorial = table.clone(profile.tutorial),
		missions = { day = profile.missions.day, list = table.clone(profile.missions.list) },
		milestones = table.clone(profile.milestones),
		settings = table.clone(profile.settings),
		daily = table.clone(profile.daily),
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
-- It edits ProfileStore's own Data table in place, which is what gets saved.
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

-- Requests an immediate save (used before granting Robux purchases). False when the
-- session is gone, so the caller can tell Roblox to retry the receipt later.
function PlayerData.saveNow(player: Player): boolean
	local session = sessions[player]
	if not session or not session:IsActive() then
		return false
	end
	session:Save()
	return true
end

PlayerData.Loaded = loadedEvent.Event

-- Lifecycle ----------------------------------------------------------------------------

local function startSession(player: Player): Session?
	-- Cancel keeps the load retrying until the player leaves instead of a fixed timeout
	-- (the runtime supports it; the exported param type omits it).
	local params: any = {
		Cancel = function()
			return player.Parent ~= Players
		end,
	}
	return (store :: any):StartSessionAsync(`{player.UserId}`, params)
end

local function activate(player: Player, session: Session)
	local profile = session.Data :: Profile
	session.OnSessionEnd:Connect(function()
		profiles[player] = nil
		sessions[player] = nil
		player:Kick(Strings.forLocale(player.LocaleId).dataSessionEnded)
	end)
	sessions[player] = session
	profiles[player] = profile
	mirrorAttributes(player, profile)
	player:SetAttribute("DataLoaded", true)
	push(player)
	loadedEvent:Fire(player)

	-- Studio only: set the player's DevGrantCoins attribute to a number to receive coins.
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DevGrantCoins"):Connect(function()
			local amount = player:GetAttribute("DevGrantCoins")
			if typeof(amount) == "number" and amount > 0 then
				player:SetAttribute("DevGrantCoins", 0)
				PlayerData.addCoins(player, amount)
			end
		end)
	end
end

local function onPlayerAdded(player: Player)
	local session = startSession(player)
	if not session then
		-- nil also means the player left mid-load, which is not a failure.
		if player.Parent == Players then
			warn(`[PlayerData] profile load failed for {player.Name}`)
			player:Kick(Strings.forLocale(player.LocaleId).dataLoadFailed)
		end
		return
	end

	session:AddUserId(player.UserId) -- lets Roblox data deletion requests find this profile

	-- Migrate BEFORE reconciling. Never fall back to a fresh profile on failure.
	local ok, failure = pcall(migrate, session.Data)
	if not ok or failure ~= nil then
		warn(`[PlayerData] migration failed for {player.Name}: {failure}`)
		session:EndSession()
		player:Kick(Strings.forLocale(player.LocaleId).dataLoadFailed)
		return
	end
	session:Reconcile()
	reconcile(session.Data)

	if player.Parent ~= Players then
		session:EndSession()
		return
	end
	activate(player, session)
end

local function onPlayerRemoving(player: Player)
	local session = sessions[player]
	profiles[player] = nil
	sessions[player] = nil
	dirty[player] = nil
	if session and session:IsActive() then
		session:EndSession()
	end
end

-- ProfileStore autosaves and saves every active session on shutdown by itself.
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
end

return PlayerData
