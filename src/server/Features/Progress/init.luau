--!strict
-- Player progression around the core loop:
--   * tutorial: steps advanced by real events (first cast, first catch, panels opened...)
--   * daily challenges: 3 per day from Config/Missions, progress fed by gameplay hooks
--   * collection milestones from Config/Milestones, claimed for coins
--   * settings (music, sfx, reduce effects) saved in the profile
-- Other features call the on* hooks; the client only reads the snapshot and asks to claim.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Creatures = require(Config:WaitForChild("Creatures"))
local Milestones = require(Config:WaitForChild("Milestones"))
local Missions = require(Config:WaitForChild("Missions"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("Types"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

local Progress = {}
Progress.order = 45

local TUTORIAL_ORDER = { "goToPier", "fight", "collection", "workshop", "training", "done" }
local CLIENT_TUTORIAL_EVENTS = { openedCollection = "collection", openedWorkshop = "workshop" }

local rng = Random.new()
local claimResult: RemoteEvent
local lastCaught: { [Player]: { castId: number, at: number } } = {}

-- Tutorial -----------------------------------------------------------------------------

-- Moves the tutorial past `fromStep` (only if the player is exactly there).
local function advanceTutorial(player: Player, fromStep: string)
	local profile = PlayerData.get(player)
	if not profile or profile.tutorial.done or profile.tutorial.step ~= fromStep then
		return
	end
	local index = table.find(TUTORIAL_ORDER, fromStep) or #TUTORIAL_ORDER
	local nextStep = TUTORIAL_ORDER[math.min(index + 1, #TUTORIAL_ORDER)]
	PlayerData.update(player, function(p)
		p.tutorial.step = nextStep
		p.tutorial.done = nextStep == "done"
	end)
end

-- Daily challenges -----------------------------------------------------------------------

local function rollMissions(): { Types.Mission }
	local pool = table.clone(Missions.POOL)
	local list: { Types.Mission } = {}
	local usedKinds: { [string]: boolean } = {}
	while #list < Missions.DAILY_COUNT and #pool > 0 do
		local def = table.remove(pool, rng:NextInteger(1, #pool)) :: Missions.MissionDef
		local family = string.split(def.kind, ":")[1]
		if not usedKinds[family] then
			usedKinds[family] = true
			table.insert(list, {
				id = def.id,
				kind = def.kind,
				target = rng:NextInteger(def.targetMin, def.targetMax),
				progress = 0,
				reward = def.reward,
				claimed = false,
			})
		end
	end
	return list
end

-- New day (UTC) = new challenges. Called before any read or write of missions.
local function refreshMissions(player: Player)
	local profile = PlayerData.get(player)
	local today = Missions.today()
	if profile and profile.missions.day ~= today then
		PlayerData.update(player, function(p)
			p.missions = { day = today, list = rollMissions() }
		end)
	end
end

local function addMissionProgress(player: Player, matches: (string) -> boolean, amount: number)
	refreshMissions(player)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local changed = false
	for _, m in profile.missions.list do
		if not m.claimed and m.progress < m.target and matches(m.kind) then
			changed = true
		end
	end
	if not changed then
		return
	end
	PlayerData.update(player, function(p)
		for _, m in p.missions.list do
			if not m.claimed and m.progress < m.target and matches(m.kind) then
				m.progress = math.min(m.target, m.progress + amount)
			end
		end
	end)
end

-- Daily gift -----------------------------------------------------------------------------

-- First join of the UTC day: coins, growing with the days visited (Config/Missions).
local function grantDailyGift(player: Player)
	local profile = PlayerData.get(player)
	local today = Missions.today()
	if not profile or profile.daily.lastDay == today then
		return
	end
	local days = profile.daily.days + 1
	local gift = Missions.dailyGift(days)
	PlayerData.update(player, function(p)
		p.daily = { lastDay = today, days = days, lastGift = gift, grantedAt = os.time() }
		p.coins += gift
	end)
	Analytics.coins(player, true, gift, "DailyGift", tostring(days))
end

-- Milestones -----------------------------------------------------------------------------

local function milestoneReady(profile: PlayerData.Profile, m: Milestones.Milestone): boolean
	if m.kind == "species" then
		local species = 0
		for _ in profile.collection do
			species += 1
		end
		return species >= m.count
	elseif m.kind == "rarity" then
		for _, c in Creatures.LIST do
			if c.rarity == m.rarity and not profile.collection[c.id] then
				return false
			end
		end
		return true
	end
	return false
end

-- Hooks (called by other features) ------------------------------------------------------

function Progress.onCast(player: Player)
	advanceTutorial(player, "goToPier")
end

function Progress.onCatch(
	player: Player,
	creature: Creatures.Creature,
	value: number,
	castId: number
)
	lastCaught[player] = { castId = castId, at = os.clock() }
	advanceTutorial(player, "fight")
	addMissionProgress(player, function(kind)
		return kind == "catch" or kind == "catchRarity:" .. creature.rarity
	end, 1)
	addMissionProgress(player, function(kind)
		return kind == "earn"
	end, value)
end

function Progress.onTrainSecond(player: Player)
	addMissionProgress(player, function(kind)
		return kind == "train"
	end, 1)
end

function Progress.onTrainingStarted(player: Player)
	advanceTutorial(player, "training")
end

function Progress.onRodBought(player: Player)
	advanceTutorial(player, "workshop")
end

-- Remotes ------------------------------------------------------------------------------

local function reply(player: Player, result: Net.ClaimResult)
	claimResult:FireClient(player, result)
end

local function onClaimMission(player: Player, index: unknown)
	if typeof(index) ~= "number" then
		return
	end
	refreshMissions(player)
	local profile = PlayerData.get(player)
	local m = profile and profile.missions.list[math.floor(index)]
	if not m then
		reply(player, { ok = false, kind = "mission", id = tostring(index), reason = "unknown" })
		return
	end
	if m.claimed then
		reply(player, { ok = false, kind = "mission", id = m.id, reason = "claimed" })
		return
	end
	if m.progress < m.target then
		reply(player, { ok = false, kind = "mission", id = m.id, reason = "notReady" })
		return
	end
	PlayerData.update(player, function(p)
		local target = p.missions.list[math.floor(index)]
		target.claimed = true
		p.coins += target.reward
	end)
	Analytics.coins(player, true, m.reward, "Mission", m.id)
	reply(player, { ok = true, kind = "mission", id = m.id, reward = m.reward })
end

local function onClaimMilestone(player: Player, id: unknown)
	if typeof(id) ~= "string" then
		return
	end
	local milestone = Milestones.get(id)
	local profile = PlayerData.get(player)
	if not milestone or not profile then
		reply(player, { ok = false, kind = "milestone", id = id, reason = "unknown" })
		return
	end
	if profile.milestones[id] then
		reply(player, { ok = false, kind = "milestone", id = id, reason = "claimed" })
		return
	end
	if not milestoneReady(profile, milestone) then
		reply(player, { ok = false, kind = "milestone", id = id, reason = "notReady" })
		return
	end
	PlayerData.update(player, function(p)
		p.milestones[id] = true
		p.coins += milestone.reward
	end)
	Analytics.coins(player, true, milestone.reward, "Milestone", id)
	reply(player, { ok = true, kind = "milestone", id = id, reward = milestone.reward })
end

local function onTutorialEvent(player: Player, name: unknown)
	if typeof(name) ~= "string" then
		return
	end
	local step = CLIENT_TUTORIAL_EVENTS[name]
	if step then
		advanceTutorial(player, step)
	end
end

local function onSkipTutorial(player: Player)
	PlayerData.update(player, function(p)
		p.tutorial.step = "done"
		p.tutorial.done = true
	end)
end

local function onSaveSettings(player: Player, settings: unknown)
	if typeof(settings) ~= "table" then
		return
	end
	local s = settings :: { [any]: any }
	local function volume(v: unknown, fallback: number): number
		-- NaN fails the comparison, so it falls back too.
		if typeof(v) == "number" and v >= 0 and v <= 1 then
			return v
		end
		return fallback
	end
	PlayerData.update(player, function(p)
		p.settings.music = volume(s.music, p.settings.music)
		p.settings.sfx = volume(s.sfx, p.settings.sfx)
		if typeof(s.reduceEffects) == "boolean" then
			p.settings.reduceEffects = s.reduceEffects
		end
	end)
end

-- "Perfect" = the client finished the minigame without a mistake. Only counts for the
-- player's most recent catch, once, within a few seconds of it.
local function onReportPerfect(player: Player, castId: unknown)
	local last = lastCaught[player]
	if
		typeof(castId) ~= "number"
		or not last
		or last.castId ~= castId
		or os.clock() - last.at > 15
	then
		return
	end
	lastCaught[player] = nil
	addMissionProgress(player, function(kind)
		return kind == "perfect"
	end, 1)
end

function Progress.start()
	claimResult = Remotes.event(Net.CLAIM_RESULT)
	Remotes.onServerEvent(Net.CLAIM_MISSION, 2, 4, onClaimMission)
	Remotes.onServerEvent(Net.CLAIM_MILESTONE, 2, 4, onClaimMilestone)
	Remotes.onServerEvent(Net.TUTORIAL_EVENT, 2, 4, onTutorialEvent)
	Remotes.onServerEvent(Net.SKIP_TUTORIAL, 1, 2, onSkipTutorial)
	Remotes.onServerEvent(Net.SAVE_SETTINGS, 1, 3, onSaveSettings)
	Remotes.onServerEvent(Net.REPORT_PERFECT, 2, 3, onReportPerfect)

	PlayerData.Loaded:Connect(function(player: Player)
		refreshMissions(player)
		grantDailyGift(player)
	end)
	for _, player in Players:GetPlayers() do
		if PlayerData.get(player) then
			refreshMissions(player)
			grantDailyGift(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		lastCaught[player] = nil
	end)
end

return Progress
