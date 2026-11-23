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
local AquariumConfig = require(Shared:WaitForChild("Config"):WaitForChild("Aquarium"))
local AquariumState = require(Shared:WaitForChild("AquariumState"))
local Net = require(Shared:WaitForChild("Net"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
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
	achievements: { [string]: number },
	redeemed: { [string]: boolean },
	prestige: number,
	settings: Types.Settings,
	purchases: { [string]: boolean }, -- Robux receipt ids already granted
	purchaseOrder: { string }, -- same ids, oldest first (bounds the record)
	boosts: { luckUntil: number }, -- os.time() when each paid boost ends
	daily: Types.Daily,
	aquarium: Types.AquariumProfile, -- schema v2: owned counts per variant, slots, income carry
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

local SCHEMA_VERSION = 2
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
		stats = {
			catches = 0,
			legendaries = 0,
			level = 1,
			levelXp = 0,
			bestCombo = 0,
			trainDay = 0,
			suspicious = 0,
		},
		funnel = {},
		tutorial = { step = "goToPier", done = false },
		missions = { day = 0, list = {} },
		milestones = {},
		achievements = {},
		redeemed = {},
		prestige = 0,
		settings = { music = 0.6, sfx = 0.8, reduceEffects = false },
		purchases = {},
		purchaseOrder = {},
		boosts = { luckUntil = 0 },
		aquarium = AquariumState.new(),
		daily = {
			lastDay = 0,
			days = 0,
			streak = 0,
			shieldUsedAt = 0,
			shieldProtected = false,
			lastChest = 0,
			lastGift = 0,
			grantedAt = 0,
		},
	}
end

local store = ProfileStore.New(STORE_NAME, template())

local function deepClone(value: any): any
	if typeof(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		out[deepClone(k)] = deepClone(v)
	end
	return out
end

local function finiteNumber(value: any, fallback: number, minimum: number?): number
	if typeof(value) ~= "number" or value ~= value or math.abs(value) >= math.huge then
		return fallback
	end
	if minimum and value < minimum then
		return minimum
	end
	return value
end

-- Version steps go here (v1 -> v2 ...). Each returns nil on success or an error string.
-- Runs before reconcile. v1 -> v2: aquarium counts are rebuilt from the collection (idempotent).
local function migrate(data: { [string]: any }): string?
	if typeof(data.version) ~= "number" or data.version ~= data.version then
		data.version = SCHEMA_VERSION
	end
	if data.version > SCHEMA_VERSION then
		return `save is from a newer version ({data.version})`
	end
	AquariumState.migrate(data)
	return nil
end

local function mergeTable(
	target: { [string]: any },
	defaults: { [string]: any },
	mins: { [string]: number }?
)
	for key, defaultVal in defaults do
		local cur = target[key]
		if typeof(defaultVal) == "number" then
			local minVal = if mins and mins[key] ~= nil then mins[key] else 0
			target[key] = finiteNumber(cur, defaultVal, minVal)
		elseif typeof(defaultVal) == "boolean" then
			if typeof(cur) ~= "boolean" then
				target[key] = defaultVal
			end
		elseif typeof(defaultVal) == "string" then
			if typeof(cur) ~= "string" then
				target[key] = defaultVal
			end
		elseif cur == nil then
			target[key] = deepClone(defaultVal)
		end
	end
end

-- Fills fields missing from older saves (nested too), in place; never overwrites valid values.
local function reconcile(data: { [string]: any })
	local defaults = template() :: any
	for key, value in defaults do
		if typeof(value) == "table" then
			if typeof(data[key]) ~= "table" then
				data[key] = deepClone(value)
			end
		elseif typeof(value) == "number" then
			data[key] = finiteNumber(data[key], value, 0)
		elseif typeof(value) == "string" then
			if typeof(data[key]) ~= "string" then
				data[key] = value
			end
		elseif data[key] == nil then
			data[key] = value
		end
	end

	for stat, value in defaults.training do
		if typeof(data.training[stat]) ~= "table" then
			data.training[stat] = deepClone(value)
		else
			data.training[stat].level = finiteNumber(data.training[stat].level, 0, 0)
			data.training[stat].xp = finiteNumber(data.training[stat].xp, 0, 0)
		end
	end

	mergeTable(data.stats, defaults.stats, { level = 1 })
	mergeTable(data.boosts, defaults.boosts)
	mergeTable(data.settings, defaults.settings)
	data.settings.music = math.clamp(data.settings.music, 0, 1)
	data.settings.sfx = math.clamp(data.settings.sfx, 0, 1)
	mergeTable(data.daily, defaults.daily)
	mergeTable(data.tutorial, defaults.tutorial)

	data.missions.day = finiteNumber(data.missions.day, 0, 0)
	if typeof(data.missions.list) ~= "table" then
		data.missions.list = {}
	else
		local cleanMissions = {}
		for _, m in data.missions.list do
			if typeof(m) == "table" and typeof(m.id) == "string" and typeof(m.kind) == "string" then
				table.insert(cleanMissions, {
					id = m.id,
					kind = m.kind,
					target = finiteNumber(m.target, 1, 1),
					progress = finiteNumber(m.progress, 0, 0),
					reward = finiteNumber(m.reward, 0, 0),
					claimed = m.claimed == true,
				})
			end
		end
		data.missions.list = cleanMissions
	end

	for id, entry in data.collection do
		if typeof(id) ~= "string" or typeof(entry) ~= "table" then
			data.collection[id] = nil
		else
			local rawCount = if entry.count ~= nil then entry.count else entry.catches
			entry.count = finiteNumber(rawCount, 1, 1)
			entry.bestWeight = finiteNumber(entry.bestWeight, 0.1, 0)
			entry.firstAt = finiteNumber(entry.firstAt, 0, 0)
			entry.shiny = finiteNumber(entry.shiny, 0, 0)
		end
	end

	local cleanRods: { string } = {}
	local seenRods: { [string]: boolean } = {}
	for _, rodId in data.rodsOwned do
		if typeof(rodId) == "string" and Rods.get(rodId) and not seenRods[rodId] then
			seenRods[rodId] = true
			table.insert(cleanRods, rodId)
		end
	end
	if not seenRods[STARTER_ROD] then
		table.insert(cleanRods, 1, STARTER_ROD)
	end
	data.rodsOwned = cleanRods
	if not table.find(cleanRods, data.equippedRod) or not Rods.get(data.equippedRod) then
		data.equippedRod = STARTER_ROD
	end

	AquariumState.sanitize(data.aquarium)

	data.version = SCHEMA_VERSION
end

-- Exposed so tests and migration checks run the exact same pipeline as onPlayerAdded.
function PlayerData.reconcileProfile(data: { [string]: any }): string?
	local ok, failure = pcall(migrate, data)
	if not ok or failure ~= nil then
		return if ok then failure :: string? else tostring(failure)
	end
	reconcile(data)
	return nil
end

-- Snapshot -----------------------------------------------------------------------------

local function aquariumEnabled(): boolean
	return AquariumConfig.flag(AquariumConfig.UI_ATTRIBUTE)
end

local function snapshot(profile: Profile): Types.Snapshot
	local speciesCount = 0
	for _ in profile.collection do
		speciesCount += 1
	end
	return {
		coins = profile.coins,
		equippedRod = profile.equippedRod,
		rodsOwned = deepClone(profile.rodsOwned),
		collection = deepClone(profile.collection),
		training = deepClone(profile.training),
		stats = deepClone(profile.stats),
		tutorial = deepClone(profile.tutorial),
		missions = {
			day = profile.missions.day,
			list = deepClone(profile.missions.list),
		},
		milestones = deepClone(profile.milestones),
		achievements = deepClone(profile.achievements),
		redeemed = deepClone(profile.redeemed),
		prestige = profile.prestige,
		settings = deepClone(profile.settings),
		daily = deepClone(profile.daily),
		aquarium = AquariumState.view(
			profile.aquarium,
			profile.coins,
			speciesCount,
			aquariumEnabled()
		),
	}
end

function PlayerData.buildSnapshot(profile: Profile): Types.Snapshot
	return snapshot(profile)
end

local function mirrorAttributes(player: Player, profile: Profile)
	player:SetAttribute("Coins", profile.coins)
	player:SetAttribute("EquippedRod", profile.equippedRod)
	player:SetAttribute("Prestige", profile.prestige)
	player:SetAttribute("LoginStreak", (profile.daily and profile.daily.streak) or 0)
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

-- The only way to change a profile. `mutate` runs synchronously against a deep copy so a
-- runtime error mid-mutation never leaves ProfileStore's live session.Data half-written.
function PlayerData.update(player: Player, mutate: (Profile) -> ()): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	local draft = deepClone(profile) :: Profile
	local ok, err = pcall(mutate, draft)
	if not ok then
		warn(`[PlayerData] update failed for {player.Name}: {err}`)
		return false
	end
	for key, value in draft :: any do
		(profile :: any)[key] = value
	end
	for key in profile :: any do
		if (draft :: any)[key] == nil then
			(profile :: any)[key] = nil
		end
	end
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

-- Callbacks that must run while the profile still exists (leave or session end). They run
-- synchronously, before the profile is released, so a last settlement is never lost.
local beforeRelease: { (Player) -> () } = {}
function PlayerData.onBeforeRelease(callback: (Player) -> ())
	table.insert(beforeRelease, callback)
end

local function runBeforeRelease(player: Player)
	for _, callback in beforeRelease do
		local ok, err = (pcall :: any)(callback, player)
		if not ok then
			warn(`[PlayerData] beforeRelease failed for {player.Name}: {err}`)
		end
	end
end

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
		runBeforeRelease(player)
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

	-- Studio only: set DevGrantCoins / DevGrantSpecies attributes to test progression cleanly.
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DevGrantCoins"):Connect(function()
			local amount = player:GetAttribute("DevGrantCoins")
			if typeof(amount) == "number" and amount > 0 then
				player:SetAttribute("DevGrantCoins", 0)
				PlayerData.addCoins(player, amount)
			end
		end)
		player:GetAttributeChangedSignal("DevGrantSpecies"):Connect(function()
			local targetCount = player:GetAttribute("DevGrantSpecies")
			if typeof(targetCount) == "number" and targetCount > 0 then
				player:SetAttribute("DevGrantSpecies", 0)
				local creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
				PlayerData.update(player, function(p)
					local total = 0
					for _ in p.collection do
						total += 1
					end
					for _, creature in creatures.LIST do
						if total >= targetCount then
							break
						end
						if not p.collection[creature.id] then
							p.collection[creature.id] = {
								count = 1,
								bestWeight = creature.weightMin,
								firstAt = os.time(),
								shiny = 0,
							}
							total += 1
						end
					end
				end)
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
	local failure = PlayerData.reconcileProfile(session.Data)
	if failure ~= nil then
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
	if profiles[player] then
		runBeforeRelease(player)
	end
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
