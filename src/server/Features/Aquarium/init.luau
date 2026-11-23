--!strict
-- Aquarium (S1): server authority for slots, upgrades and passive income.
--   * Preview / apply / buy come from the client as requests; every check and every change
--     runs inside one PlayerData.update, so a double click or an old version never charges
--     twice or half-applies.
--   * Income is paid online only (offline is off in the pilot), in one batch loop for every
--     player. It settles with the OLD rate before any change of rate, keeps the remainder in
--     integers (cpm * ms / 60000) and saves coins, cents and remainder in the same profile.
--   * Flags (ReplicatedStorage attributes, see Config/Aquarium): AquariumUI hides the feature,
--     AquariumCredit pauses income. Neither removes anything the player already owns.
-- Contract: docs/AQUARIO-CONTRATO.md

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Aquarium"))
local AquariumState = require(Shared:WaitForChild("AquariumState"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("Types"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

type Session = {
	lastClock: number,
	results: { [string]: Net.AquariumResult },
	order: { string },
}

local Aquarium = {}
Aquarium.order = 60

local sessions: { [Player]: Session } = {}
local resultRemote: RemoteEvent

local MAX_SETTLE_MS = 60_000 -- a long stall never pays more than a minute at once

local function uiEnabled(): boolean
	return Config.flag(Config.UI_ATTRIBUTE)
end

local function creditEnabled(): boolean
	return Config.flag(Config.CREDIT_ATTRIBUTE)
end

local function offlineEnabled(): boolean
	return Config.flag(Config.OFFLINE_ATTRIBUTE, true) and creditEnabled()
end

local function snapshotOf(player: Player): Types.AquariumSnapshot?
	local profile = PlayerData.get(player)
	if not profile then
		return nil
	end
	return PlayerData.buildSnapshot(profile).aquarium
end

-- Income -------------------------------------------------------------------------------

-- Pays what the current rate earned since the last settlement. Call it BEFORE anything that
-- changes the rate, so the interval is paid with the rate that was in force.
local function settle(player: Player)
	local session = sessions[player]
	local profile = PlayerData.get(player)
	if not session or not profile then
		return
	end
	local now = os.clock()
	local ms = math.floor((now - session.lastClock) * 1000)
	if ms <= 0 then
		return
	end
	session.lastClock += ms / 1000
	if not creditEnabled() then
		return -- paused: the interval is dropped, never paid later
	end
	ms = math.min(ms, MAX_SETTLE_MS)
	local earned = 0
	PlayerData.update(player, function(p)
		local cpm = AquariumState.rates(p.aquarium)
		if cpm <= 0 then
			return
		end
		earned = AquariumState.accrue(p.aquarium, cpm, ms)
		p.aquarium.cursor = os.time()
		if earned > 0 then
			p.coins += earned
		end
	end)
	if earned > 0 then
		Analytics.coins(player, true, earned, "Aquarium", "tank")
	end
end

-- Requests ------------------------------------------------------------------------------

local function remember(session: Session, result: Net.AquariumResult)
	if session.results[result.requestId] == nil then
		table.insert(session.order, result.requestId)
		if #session.order > Config.REQUEST_MEMORY then
			local oldest = table.remove(session.order, 1)
			if oldest then
				session.results[oldest] = nil
			end
		end
	end
	session.results[result.requestId] = result
end

local function reply(player: Player, result: Net.AquariumResult)
	resultRemote:FireClient(player, result)
end

local function fail(
	requestId: string,
	kind: string,
	reason: string,
	version: number,
	snapshot: Types.AquariumSnapshot?
): Net.AquariumResult
	return {
		requestId = requestId,
		kind = kind,
		ok = false,
		reason = reason,
		version = version,
		snapshot = snapshot,
	}
end

local function readString(value: any, maxLength: number): string?
	if typeof(value) == "string" and #value >= 1 and #value <= maxLength then
		return value
	end
	return nil
end

local function readRequest(raw: any): AquariumState.Request?
	if typeof(raw) ~= "table" then
		return nil
	end
	local slot, version = raw.slot, raw.expectedVersion
	if
		typeof(slot) ~= "number"
		or slot ~= slot
		or typeof(version) ~= "number"
		or version ~= version
		or typeof(raw.op) ~= "string"
	then
		return nil
	end
	local creatureId = if raw.creatureId ~= nil then readString(raw.creatureId, 64) else nil
	local variant = if raw.variant ~= nil then readString(raw.variant, 16) else nil
	return {
		op = raw.op,
		slot = slot,
		creatureId = creatureId,
		variant = variant,
		expectedVersion = version,
	}
end

local function gate(
	player: Player,
	requestId: string,
	kind: string
): (Types.AquariumProfile?, Net.AquariumResult?)
	local profile = PlayerData.get(player)
	if not profile then
		return nil, fail(requestId, kind, "notReady", 0, nil)
	end
	if not uiEnabled() then
		return nil, fail(requestId, kind, "disabled", profile.aquarium.version, snapshotOf(player))
	end
	return profile.aquarium, nil
end

local function onPreview(player: Player, raw: unknown)
	local rawTable = raw :: any
	local requestId = if typeof(rawTable) == "table"
		then readString(rawTable.requestId, 36)
		else nil
	local request = readRequest(raw)
	if not requestId or not request then
		return
	end
	local aq, failed = gate(player, requestId, "preview")
	if failed then
		reply(player, failed)
		return
	end
	local current = aq :: Types.AquariumProfile
	local plan = AquariumState.plan(current, request)
	if not plan.ok then
		local snapshot = if plan.reason == "staleVersion" then snapshotOf(player) else nil
		reply(
			player,
			fail(requestId, "preview", plan.reason or "badRequest", current.version, snapshot)
		)
		return
	end
	reply(player, {
		requestId = requestId,
		kind = "preview",
		ok = true,
		version = current.version,
		preview = AquariumState.preview(current, plan),
	})
end

local function onApply(player: Player, raw: unknown)
	local session = sessions[player]
	local rawTable = raw :: any
	local requestId = if typeof(rawTable) == "table"
		then readString(rawTable.requestId, 36)
		else nil
	local request = readRequest(raw)
	if not session or not requestId or not request then
		return
	end
	local stored = session.results[requestId]
	if stored then
		reply(player, stored) -- repeated request: same answer, nothing applied twice
		return
	end
	local aq, failed = gate(player, requestId, "apply")
	if failed then
		reply(player, failed)
		return
	end
	settle(player)
	local reason: string? = nil
	PlayerData.update(player, function(p)
		local plan = AquariumState.plan(p.aquarium, request)
		if not plan.ok then
			reason = plan.reason or "badRequest"
			return
		end
		AquariumState.apply(p.aquarium, plan)
		AquariumState.recordBest(p.aquarium)
	end)
	local snapshot = snapshotOf(player)
	local version = if snapshot and snapshot.version
		then snapshot.version
		else (aq :: Types.AquariumProfile).version
	local result: Net.AquariumResult
	if reason then
		result = fail(requestId, "apply", reason, version, snapshot)
	else
		result = {
			requestId = requestId,
			kind = "apply",
			ok = true,
			version = version,
			snapshot = snapshot,
		}
		if request.op ~= "remove" then
			Analytics.step(player, "firstTankPlace")
		end
		Analytics.custom(
			player,
			"AquariumChange",
			if snapshot and snapshot.totalCpm then snapshot.totalCpm else 0,
			request.op,
			`lv{if snapshot and snapshot.level then snapshot.level else 0}`,
			`syn{if snapshot and snapshot.synergies then #snapshot.synergies else 0}`
		)
	end
	remember(session, result)
	reply(player, result)
end

local function onBuy(player: Player, raw: unknown)
	local session = sessions[player]
	if not session or typeof(raw) ~= "table" then
		return
	end
	local rawTable = raw :: any
	local requestId = readString(rawTable.requestId, 36)
	local levelId = readString(rawTable.levelId, 64)
	local expected = rawTable.expectedVersion
	if not requestId or not levelId or typeof(expected) ~= "number" or expected ~= expected then
		return
	end
	local stored = session.results[requestId]
	if stored then
		reply(player, stored)
		return
	end
	local aq, failed = gate(player, requestId, "buy")
	if failed then
		reply(player, failed)
		return
	end
	settle(player)
	local reason: string? = nil
	local needed: number? = nil
	local spent, boughtId = 0, ""
	PlayerData.update(player, function(p)
		local a = p.aquarium
		if expected ~= a.version then
			reason = "staleVersion"
			return
		end
		local nextInfo = Config.LEVELS[a.level + 1]
		if not nextInfo then
			reason = "maxLevel"
			return
		end
		if nextInfo.id ~= levelId then
			reason = "badRequest"
			return
		end
		local species = 0
		for _ in p.collection do
			species += 1
		end
		if species < nextInfo.minSpecies then
			reason = "levelLocked"
			return
		end
		if p.coins < nextInfo.cost then
			reason = "noCoins"
			needed = nextInfo.cost - p.coins
			return
		end
		p.coins -= nextInfo.cost
		a.level += 1
		a.version += 1
		spent, boughtId = nextInfo.cost, nextInfo.id
	end)
	local snapshot = snapshotOf(player)
	local profile = PlayerData.get(player)
	local version = if snapshot and snapshot.version
		then snapshot.version
		else (aq :: Types.AquariumProfile).version
	local result: Net.AquariumResult
	if reason then
		result = fail(requestId, "buy", reason, version, snapshot)
		result.needed = needed
	else
		result = {
			requestId = requestId,
			kind = "buy",
			ok = true,
			version = version,
			snapshot = snapshot,
			coins = if profile then profile.coins else nil,
		}
		Analytics.coins(player, false, spent, "AquariumLevel", boughtId)
		Analytics.step(player, "firstTankUpgrade")
		Analytics.custom(player, "AquariumUpgrade", spent, boughtId, nil, nil)
	end
	remember(session, result)
	reply(player, result)
end

local function onClaim(player: Player, raw: unknown)
	local session = sessions[player]
	if not session or typeof(raw) ~= "table" then
		return
	end
	local rawTable = raw :: any
	local requestId = readString(rawTable.requestId, 36)
	local goalId = readString(rawTable.goalId, 64)
	if not requestId or not goalId then
		return
	end
	local stored = session.results[requestId]
	if stored then
		reply(player, stored)
		return
	end
	local aq, failed = gate(player, requestId, "claim")
	if failed then
		reply(player, failed)
		return
	end
	local outcome: AquariumState.ClaimOutcome = { ok = false, reason = "badRequest" }
	local today = os.time() // 86400
	PlayerData.update(player, function(p)
		outcome = AquariumState.claim(p.aquarium, goalId, today)
		if outcome.ok and outcome.coins and outcome.coins > 0 then
			p.coins += outcome.coins
		end
	end)
	local snapshot = snapshotOf(player)
	local profile = PlayerData.get(player)
	local version = if snapshot and snapshot.version
		then snapshot.version
		else (aq :: Types.AquariumProfile).version
	local result: Net.AquariumResult
	if outcome.ok then
		result = {
			requestId = requestId,
			kind = "claim",
			ok = true,
			version = version,
			snapshot = snapshot,
			already = outcome.already,
			reward = { coins = outcome.coins, cosmetic = outcome.cosmetic },
			coins = if profile then profile.coins else nil,
		}
		if outcome.coins and outcome.coins > 0 then
			Analytics.coins(player, true, outcome.coins, "AquariumSessionGoal", goalId)
		end
	else
		result = fail(requestId, "claim", outcome.reason or "badRequest", version, snapshot)
	end
	remember(session, result)
	reply(player, result)
end

-- A confirmed manual catch (Fishing calls this): advances the session goals.
function Aquarium.onCatch(player: Player, minigame: string, isNewSpecies: boolean)
	if not sessions[player] then
		return
	end
	PlayerData.update(player, function(p)
		AquariumState.recordCatch(p.aquarium, minigame, isNewSpecies, os.time())
	end)
end

-- Lifecycle -------------------------------------------------------------------------------

local function begin(player: Player)
	if sessions[player] then
		return
	end
	sessions[player] = { lastClock = os.clock(), results = {}, order = {} }
	-- New cursor on every activation. Time offline is paid only when the offline flag is on,
	-- once, at the rate saved on exit; otherwise the gap is dropped.
	local offlinePaid = 0
	local allow = offlineEnabled()
	PlayerData.update(player, function(p)
		local now = os.time()
		p.aquarium.cursor = now
		offlinePaid = AquariumState.settleOffline(p.aquarium, now, allow)
		p.coins += offlinePaid
		AquariumState.beginSession(p.aquarium, now)
		AquariumState.recordBest(p.aquarium)
	end)
	if offlinePaid > 0 then
		Analytics.coins(player, true, offlinePaid, "AquariumOffline", "welcomeBack")
	end
end

function Aquarium.start()
	resultRemote = Remotes.event(Net.AQUARIUM_RESULT)
	Remotes.onServerEvent(Net.AQUARIUM_PREVIEW, 6, 10, onPreview)
	Remotes.onServerEvent(Net.AQUARIUM_APPLY, 4, 8, onApply)
	Remotes.onServerEvent(Net.AQUARIUM_BUY_LEVEL, 2, 4, onBuy)
	Remotes.onServerEvent(Net.AQUARIUM_CLAIM_GOAL, 3, 6, onClaim)

	PlayerData.Loaded:Connect(begin)
	for _, player in Players:GetPlayers() do
		if PlayerData.get(player) then
			begin(player)
		end
	end
	-- Runs while the profile still exists: pay the last interval, remember rate and time.
	PlayerData.onBeforeRelease(function(player)
		settle(player)
		PlayerData.update(player, function(p)
			AquariumState.markExit(p.aquarium, os.time())
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(Config.PAY_INTERVAL)
			for _, player in Players:GetPlayers() do
				settle(player)
			end
		end
	end)
end

-- Test hook (execute_luau): settle now.
Aquarium.settle = settle

return Aquarium
