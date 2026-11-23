--!strict
-- Pure aquarium rules: profile shape, migration, validation, rates, previews and the client
-- view. No Roblox services, so the server (PlayerData, Aquarium feature) and tests share it.
-- Every number comes from Config/Aquarium. All money here is integer: coins are whole coins,
-- income is cpm (hundredths of a coin per minute), cents are hundredths of a coin.

local Config = require(script.Parent:WaitForChild("Config"):WaitForChild("Aquarium"))
local Types = require(script.Parent:WaitForChild("Types"))

export type Counts = { base: number, giant: number, gold: number, both: number }
export type Occupant = { creatureId: string, variant: string }

export type Request = {
	op: string, -- "place" | "swap" | "remove"
	slot: number,
	creatureId: string?,
	variant: string?,
	expectedVersion: number,
}

export type Plan = {
	ok: boolean,
	reason: string?,
	slot: number?,
	current: Occupant?,
	candidate: Occupant?,
}

local AquariumState = {}

local function emptyCounts(): Counts
	return { base = 0, giant = 0, gold = 0, both = 0 }
end

local function wholeNumber(value: any, fallback: number, minimum: number, maximum: number): number
	if typeof(value) ~= "number" or value ~= value or math.abs(value) >= math.huge then
		return fallback
	end
	return math.clamp(math.floor(value), minimum, maximum)
end

local function newSession(now: number): Types.AquariumSession
	return {
		startedAt = now,
		lastSeen = now,
		catches = 0,
		kinds = {},
		discoveries = 0,
		claimed = {},
	}
end

function AquariumState.new(): Types.AquariumProfile
	return {
		migrated = Config.MIGRATION_VERSION,
		level = 1,
		version = 0,
		slots = {},
		owned = {},
		bestCpm = 0,
		claimed = {},
		cosmetics = {},
		session = newSession(0),
		sessionDay = 0,
		sessionCoins = 0,
		exitCpm = 0,
		exitAt = 0,
		offlineLast = { coins = 0, seconds = 0 },
		cents = 0,
		frac = 0,
		cursor = 0,
	}
end

-- Old profiles: counts per species only. count - shiny becomes base, shiny becomes gold
-- (decision in docs/ECONOMIA-AQUARIO-S0.md section 5.3). Giants cannot be rebuilt from a
-- best weight, so they start at zero. Idempotent: runs only while `migrated` is behind.
function AquariumState.migrate(data: { [string]: any })
	local aq = data.aquarium
	if
		typeof(aq) == "table"
		and typeof(aq.migrated) == "number"
		and aq.migrated >= Config.MIGRATION_VERSION
	then
		return
	end
	local fresh = AquariumState.new()
	if typeof(data.collection) == "table" then
		for id, entry in data.collection do
			if typeof(id) == "string" and typeof(entry) == "table" then
				local rawCount = if entry.count ~= nil then entry.count else entry.catches
				local count = wholeNumber(rawCount, 1, 0, 1_000_000_000)
				local gold = wholeNumber(entry.shiny, 0, 0, count)
				local counts = emptyCounts()
				counts.base = count - gold
				counts.gold = gold
				fresh.owned[id] = counts
			end
		end
	end
	data.aquarium = fresh
end

-- Repairs an aquarium record in place (called after migrate, on every load).
function AquariumState.sanitize(aq: { [string]: any })
	aq.migrated = wholeNumber(aq.migrated, Config.MIGRATION_VERSION, 0, 1_000_000)
	aq.level = wholeNumber(aq.level, 1, 1, #Config.LEVELS)
	aq.version = wholeNumber(aq.version, 0, 0, 2 ^ 52)
	aq.cents = wholeNumber(aq.cents, 0, 0, 99)
	aq.frac = wholeNumber(aq.frac, 0, 0, 59999)
	aq.cursor = wholeNumber(aq.cursor, 0, 0, 2 ^ 52)
	aq.bestCpm = wholeNumber(aq.bestCpm, 0, 0, 2 ^ 52)
	aq.sessionDay = wholeNumber(aq.sessionDay, 0, 0, 2 ^ 52)
	aq.sessionCoins = wholeNumber(aq.sessionCoins, 0, 0, 1_000_000_000)
	aq.exitCpm = wholeNumber(aq.exitCpm, 0, 0, 2 ^ 40)
	aq.exitAt = wholeNumber(aq.exitAt, 0, 0, 2 ^ 52)
	local last = if typeof(aq.offlineLast) == "table" then aq.offlineLast else {}
	aq.offlineLast = {
		coins = wholeNumber(last.coins, 0, 0, 1_000_000_000),
		seconds = wholeNumber(last.seconds, 0, 0, 1_000_000),
	}
	for _, key in { "claimed", "cosmetics" } do
		local clean: { [string]: boolean } = {}
		if typeof(aq[key]) == "table" then
			for id, value in aq[key] do
				if typeof(id) == "string" and value == true then
					clean[id] = true
				end
			end
		end
		aq[key] = clean
	end
	local session = if typeof(aq.session) == "table" then aq.session else {}
	local cleanKinds: { [string]: boolean } = {}
	local cleanClaimed: { [string]: boolean } = {}
	if typeof(session.kinds) == "table" then
		for kind, value in session.kinds do
			if typeof(kind) == "string" and value == true then
				cleanKinds[kind] = true
			end
		end
	end
	if typeof(session.claimed) == "table" then
		for id, value in session.claimed do
			if typeof(id) == "string" and value == true then
				cleanClaimed[id] = true
			end
		end
	end
	aq.session = {
		startedAt = wholeNumber(session.startedAt, 0, 0, 2 ^ 52),
		lastSeen = wholeNumber(session.lastSeen, 0, 0, 2 ^ 52),
		catches = wholeNumber(session.catches, 0, 0, 1_000_000_000),
		kinds = cleanKinds,
		discoveries = wholeNumber(session.discoveries, 0, 0, 1_000_000_000),
		claimed = cleanClaimed,
	}
	if typeof(aq.owned) ~= "table" then
		aq.owned = {}
	end
	if typeof(aq.slots) ~= "table" then
		aq.slots = {}
	end
	for id, counts in aq.owned do
		if typeof(id) ~= "string" or typeof(counts) ~= "table" then
			aq.owned[id] = nil
		else
			for _, variant in Config.VARIANTS do
				counts[variant] = wholeNumber(counts[variant], 0, 0, 1_000_000_000)
			end
		end
	end
	-- Drop slots that point outside the level, to unknown things or past what is owned.
	local capacity = (Config.LEVELS[aq.level] :: Config.Level).slots
	local used: { [string]: number } = {}
	local clean: { [string]: Occupant } = {}
	for key, occupant in aq.slots do
		local index = tonumber(key)
		if
			index ~= nil
			and index == math.floor(index)
			and index >= 1
			and index <= capacity
			and typeof(occupant) == "table"
			and typeof(occupant.creatureId) == "string"
			and typeof(occupant.variant) == "string"
			and Config.VARIANT_PERCENT[occupant.variant] ~= nil
			and Config.RATES_CPM[occupant.creatureId] ~= nil
		then
			local usedKey = occupant.creatureId .. "|" .. occupant.variant
			local counts = aq.owned[occupant.creatureId]
			local have = if counts then counts[occupant.variant] else 0
			if (used[usedKey] or 0) < have then
				used[usedKey] = (used[usedKey] or 0) + 1
				clean[tostring(index)] =
					{ creatureId = occupant.creatureId, variant = occupant.variant }
			end
		end
	end
	aq.slots = clean
end

function AquariumState.capacity(aq: Types.AquariumProfile): number
	return (Config.LEVELS[aq.level] :: Config.Level).slots
end

local function occupantAt(aq: Types.AquariumProfile, slot: number): Occupant?
	return aq.slots[tostring(slot)]
end

function AquariumState.placedCount(
	aq: Types.AquariumProfile,
	creatureId: string,
	variant: string
): number
	local n = 0
	for _, occupant in aq.slots do
		if occupant.creatureId == creatureId and occupant.variant == variant then
			n += 1
		end
	end
	return n
end

function AquariumState.available(
	aq: Types.AquariumProfile,
	creatureId: string,
	variant: string
): number
	local counts = aq.owned[creatureId]
	if not counts then
		return 0
	end
	return math.max(
		0,
		(counts :: any)[variant] - AquariumState.placedCount(aq, creatureId, variant)
	)
end

-- Distinct species per family among occupied slots, plus the bonus percent of each count.
local function tierPercent(species: number): number
	for _, tier in Config.SYNERGY_TIERS do
		if species >= tier.species then
			return tier.percent
		end
	end
	return 0
end

local function familyCounts(aq: Types.AquariumProfile): { [string]: { [string]: boolean } }
	local families: { [string]: { [string]: boolean } } = {}
	for _, occupant in aq.slots do
		local family = Config.FAMILY[occupant.creatureId]
		if family then
			local set = families[family] or {}
			set[occupant.creatureId] = true
			families[family] = set
		end
	end
	return families
end

local function countOf(set: { [string]: boolean }): number
	local n = 0
	for _ in set do
		n += 1
	end
	return n
end

-- Active family ids (2+ distinct species), sorted, for previews and the view.
function AquariumState.activeFamilies(aq: Types.AquariumProfile): { string }
	local list: { string } = {}
	for family, set in familyCounts(aq) do
		if tierPercent(countOf(set)) > 0 then
			table.insert(list, family)
		end
	end
	table.sort(list)
	return list
end

-- Synergy percent of one slot: its creature's family bonus (one family per creature, so
-- "highest bonus wins" is trivially that one), capped by MAX_SYNERGY_PERCENT.
local function synergyPercent(aq: Types.AquariumProfile, slot: number): number
	local occupant = occupantAt(aq, slot)
	if not occupant then
		return 0
	end
	local family = Config.FAMILY[occupant.creatureId]
	if not family then
		return 0
	end
	local set = familyCounts(aq)[family]
	return if set then tierPercent(countOf(set)) else 0
end

function AquariumState.slotRate(aq: Types.AquariumProfile, slot: number): number
	local occupant = occupantAt(aq, slot)
	if not occupant then
		return 0
	end
	local rate = Config.rateCpm(occupant.creatureId, occupant.variant) or 0
	local bonus = math.min(synergyPercent(aq, slot), Config.MAX_SYNERGY_PERCENT)
	return rate * (100 + bonus) // 100
end

-- Total income in cpm, plus the per-slot list (index = slot, 0 when empty).
function AquariumState.rates(aq: Types.AquariumProfile): (number, { number })
	local total = 0
	local perSlot: { number } = {}
	for slot = 1, AquariumState.capacity(aq) do
		local rate = AquariumState.slotRate(aq, slot)
		perSlot[slot] = rate
		total += rate
	end
	return total, perSlot
end

-- Validates a placement request against the current state, without changing anything.
function AquariumState.plan(aq: Types.AquariumProfile, request: Request): Plan
	if request.expectedVersion ~= aq.version then
		return { ok = false, reason = "staleVersion" }
	end
	local slot = request.slot
	if slot ~= math.floor(slot) or slot < 1 then
		return { ok = false, reason = "badSlot" }
	end
	local maxSlots = (Config.LEVELS[#Config.LEVELS] :: Config.Level).slots
	if slot > maxSlots then
		return { ok = false, reason = "badSlot" }
	end
	if slot > AquariumState.capacity(aq) then
		return { ok = false, reason = "slotLocked" }
	end
	local current = occupantAt(aq, slot)
	if request.op == "remove" then
		if not current then
			return { ok = false, reason = "emptySlot" }
		end
		return { ok = true, slot = slot, current = current }
	elseif request.op ~= "place" and request.op ~= "swap" then
		return { ok = false, reason = "badRequest" }
	end
	local creatureId, variant = request.creatureId, request.variant
	if typeof(creatureId) ~= "string" or typeof(variant) ~= "string" then
		return { ok = false, reason = "badRequest" }
	end
	if Config.rateCpm(creatureId, variant) == nil then
		return { ok = false, reason = "badRequest" }
	end
	if current and current.creatureId == creatureId and current.variant == variant then
		return { ok = false, reason = "sameOccupant" }
	end
	if AquariumState.available(aq, creatureId, variant) < 1 then
		return { ok = false, reason = "notOwned" }
	end
	return {
		ok = true,
		slot = slot,
		current = current,
		candidate = { creatureId = creatureId, variant = variant },
	}
end

local function copyAq(aq: Types.AquariumProfile): Types.AquariumProfile
	local slots: { [string]: Occupant } = {}
	for key, occupant in aq.slots do
		slots[key] = { creatureId = occupant.creatureId, variant = occupant.variant }
	end
	return {
		migrated = aq.migrated,
		level = aq.level,
		version = aq.version,
		slots = slots,
		owned = aq.owned, -- read only here
		bestCpm = aq.bestCpm,
		claimed = aq.claimed,
		cosmetics = aq.cosmetics,
		session = aq.session,
		sessionDay = aq.sessionDay,
		sessionCoins = aq.sessionCoins,
		exitCpm = aq.exitCpm,
		exitAt = aq.exitAt,
		offlineLast = aq.offlineLast,
		cents = aq.cents,
		frac = aq.frac,
		cursor = aq.cursor,
	}
end

-- Applies a validated plan to `aq` in place and bumps the version.
function AquariumState.apply(aq: Types.AquariumProfile, plan: Plan)
	local slot = plan.slot :: number
	local candidate = plan.candidate
	if candidate then
		aq.slots[tostring(slot)] =
			{ creatureId = candidate.creatureId, variant = candidate.variant }
	else
		aq.slots[tostring(slot)] = nil
	end
	aq.version += 1
end

-- Credits one more owned creature (a catch). Always bumps the version.
function AquariumState.addOwned(
	aq: Types.AquariumProfile,
	creatureId: string,
	variant: string
): boolean
	local counts = aq.owned[creatureId]
	local isNewVariant = counts == nil or (counts :: any)[variant] == 0
	if not counts then
		counts = emptyCounts()
		aq.owned[creatureId] = counts
	end
	(counts :: any)[variant] += 1
	aq.version += 1
	return isNewVariant
end

function AquariumState.preview(aq: Types.AquariumProfile, plan: Plan): Types.AquariumPreview
	local totalBefore, perSlotBefore = AquariumState.rates(aq)
	local after = copyAq(aq)
	AquariumState.apply(after, plan)
	local totalAfter, perSlotAfter = AquariumState.rates(after)
	local slot = plan.slot :: number
	local before = AquariumState.activeFamilies(aq)
	local afterFamilies = AquariumState.activeFamilies(after)
	local gained: { string } = {}
	local lost: { string } = {}
	for _, family in afterFamilies do
		if not table.find(before, family) then
			table.insert(gained, family)
		end
	end
	for _, family in before do
		if not table.find(afterFamilies, family) then
			table.insert(lost, family)
		end
	end
	local function describe(o: Occupant?): Types.AquariumOccupantRate?
		if not o then
			return nil
		end
		return {
			creatureId = o.creatureId,
			variant = o.variant,
			cpm = Config.rateCpm(o.creatureId, o.variant) or 0,
		}
	end
	return {
		slot = slot,
		current = describe(plan.current),
		candidate = describe(plan.candidate),
		slotBeforeCpm = perSlotBefore[slot] or 0,
		slotAfterCpm = perSlotAfter[slot] or 0,
		totalBeforeCpm = totalBefore,
		totalAfterCpm = totalAfter,
		deltaCpm = totalAfter - totalBefore,
		synergiesGained = gained,
		synergiesLost = lost,
		usedVersion = aq.version,
	}
end

-- Families that have at least one species in the tank, with progress to the next tier.
function AquariumState.synergyList(aq: Types.AquariumProfile): { any }
	local list = {}
	for family, set in familyCounts(aq) do
		local count = countOf(set)
		local members: { string } = {}
		for id in set do
			table.insert(members, id)
		end
		table.sort(members)
		local percent = tierPercent(count)
		local nextAt: number? = nil
		for i = #Config.SYNERGY_TIERS, 1, -1 do
			local tier = Config.SYNERGY_TIERS[i]
			if count < tier.species then
				nextAt = tier.species
				break
			end
		end
		table.insert(list, {
			id = family,
			members = members,
			bonusPct = percent,
			active = percent > 0,
			count = count,
			nextAt = nextAt,
		})
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return list
end

local function cosmeticList(aq: Types.AquariumProfile): { string }
	local list: { string } = {}
	for id in aq.cosmetics do
		table.insert(list, id)
	end
	table.sort(list)
	return list
end

local function sessionProgress(session: Types.AquariumSession, kind: string): number
	if kind == "catches" then
		return session.catches
	elseif kind == "discoveries" then
		return session.discoveries
	elseif kind == "minigames" then
		local n = 0
		for _ in session.kinds do
			n += 1
		end
		return n
	end
	return 0
end

local function coinsLeftToday(aq: Types.AquariumProfile, today: number): number
	local used = if aq.sessionDay == today then aq.sessionCoins else 0
	return math.max(0, Config.SESSION_COINS_DAILY_CAP - used)
end

function AquariumState.goals(aq: Types.AquariumProfile, today: number?): Types.AquariumGoals
	local day = today or (os.time() // 86400)
	local income = {}
	local nextId: string? = nil
	local remaining: number? = nil
	for _, goal in Config.INCOME_GOALS do
		local reached = aq.bestCpm >= goal.cpm
		table.insert(income, {
			id = goal.id,
			cpm = goal.cpm,
			cosmetic = goal.cosmetic,
			reached = reached,
			claimed = aq.claimed[goal.id] == true,
		})
		if not reached and nextId == nil then
			nextId, remaining = goal.id, goal.cpm - aq.bestCpm
		end
	end
	local sessionList = {}
	for _, goal in Config.SESSION_GOALS do
		table.insert(sessionList, {
			id = goal.id,
			kind = goal.kind,
			target = goal.target,
			progress = math.min(sessionProgress(aq.session, goal.kind), goal.target),
			coins = goal.coins,
			claimed = aq.session.claimed[goal.id] == true,
		})
	end
	return {
		income = { bestCpm = aq.bestCpm, list = income, nextId = nextId, remainingCpm = remaining },
		session = { list = sessionList, coinsLeftToday = coinsLeftToday(aq, day) },
	}
end

-- Records the best confirmed income (call after any change of the tank). True when it grew.
function AquariumState.recordBest(aq: Types.AquariumProfile): boolean
	local total = AquariumState.rates(aq)
	if total > aq.bestCpm then
		aq.bestCpm = total
		return true
	end
	return false
end

-- Starts a fresh session unless the last one ended within the reentry window.
function AquariumState.beginSession(aq: Types.AquariumProfile, now: number)
	local session = aq.session
	if session.startedAt == 0 or now - session.lastSeen > Config.SESSION_REENTRY_SECONDS then
		aq.session = newSession(now)
	else
		session.lastSeen = now
	end
end

-- A confirmed manual catch. `minigame` is the mode that was won.
function AquariumState.recordCatch(
	aq: Types.AquariumProfile,
	minigame: string,
	isNewSpecies: boolean,
	now: number
)
	local session = aq.session
	session.lastSeen = now
	session.catches += 1
	if minigame ~= "" then
		session.kinds[minigame] = true
	end
	if isNewSpecies then
		session.discoveries += 1
	end
end

export type ClaimOutcome = {
	ok: boolean,
	reason: string?,
	already: boolean?,
	coins: number?,
	cosmetic: string?,
}

-- Claims an income ("income:<id>") or session ("session:<id>") goal in place.
function AquariumState.claim(aq: Types.AquariumProfile, goalId: string, today: number): ClaimOutcome
	local scope, id = string.match(goalId, "^(%a+):([%w_]+)$")
	if scope == "income" and id then
		local goal = Config.incomeGoal(id)
		if not goal then
			return { ok = false, reason = "unknown" }
		end
		if aq.claimed[id] then
			return { ok = true, already = true, cosmetic = goal.cosmetic }
		end
		if aq.bestCpm < goal.cpm then
			return { ok = false, reason = "notReady" }
		end
		aq.claimed[id] = true
		aq.cosmetics[goal.cosmetic] = true
		aq.version += 1
		return { ok = true, cosmetic = goal.cosmetic }
	elseif scope == "session" and id then
		local goal = Config.sessionGoal(id)
		if not goal then
			return { ok = false, reason = "unknown" }
		end
		if aq.session.claimed[id] then
			return { ok = true, already = true }
		end
		if sessionProgress(aq.session, goal.kind) < goal.target then
			return { ok = false, reason = "notReady" }
		end
		if aq.sessionDay ~= today then
			aq.sessionDay, aq.sessionCoins = today, 0
		end
		local pay =
			math.min(goal.coins, math.max(0, Config.SESSION_COINS_DAILY_CAP - aq.sessionCoins))
		if pay <= 0 then
			return { ok = false, reason = "dailyCap" }
		end
		aq.sessionCoins += pay
		aq.session.claimed[id] = true
		aq.version += 1
		return { ok = true, coins = pay }
	end
	return { ok = false, reason = "badRequest" }
end

-- What the client receives. `status` "disabled" hides everything else.
function AquariumState.view(
	aq: Types.AquariumProfile,
	coins: number,
	speciesCount: number,
	uiEnabled: boolean
): Types.AquariumSnapshot
	if not uiEnabled then
		return { status = "disabled" }
	end
	local levelInfo = Config.LEVELS[aq.level] :: Config.Level
	local slots: { Types.AquariumSlot } = {}
	for i = 1, levelInfo.slots do
		slots[i] = { index = i, occupant = occupantAt(aq, i) }
	end
	local inventory: { [string]: Counts } = {}
	for id in aq.owned do
		local counts = emptyCounts()
		local any = false
		for _, variant in Config.VARIANTS do
			local n = AquariumState.available(aq, id, variant);
			(counts :: any)[variant] = n
			if n > 0 then
				any = true
			end
		end
		if any then
			inventory[id] = counts
		end
	end
	local total, perSlot = AquariumState.rates(aq)
	local nextLevel = nil
	local nextInfo = Config.LEVELS[aq.level + 1]
	if nextInfo then
		local canBuy, reason = true, nil
		local requirement = if nextInfo.minSpecies > 0 then `species:{nextInfo.minSpecies}` else nil
		if speciesCount < nextInfo.minSpecies then
			canBuy, reason = false, "levelLocked"
		elseif coins < nextInfo.cost then
			canBuy, reason = false, "noCoins"
		end
		nextLevel = {
			levelId = nextInfo.id,
			slots = nextInfo.slots,
			cost = nextInfo.cost,
			requirement = requirement,
			canBuy = canBuy,
			reason = reason,
		}
	end
	return {
		status = "ready",
		paramsVersion = Config.PARAMS_VERSION,
		levelId = levelInfo.id,
		level = aq.level,
		version = aq.version,
		slots = slots,
		inventory = inventory,
		totalCpm = total,
		slotCpm = perSlot,
		synergies = AquariumState.synergyList(aq),
		goals = AquariumState.goals(aq),
		cosmetics = cosmeticList(aq),
		offline = if aq.offlineLast.coins > 0 then aq.offlineLast else nil,
		fractionCents = aq.cents,
		nextLevel = nextLevel,
	}
end

-- Offline pilot. Called when the player leaves: remembers the rate and the time.
function AquariumState.markExit(aq: Types.AquariumProfile, now: number)
	aq.exitCpm = (AquariumState.rates(aq))
	aq.exitAt = now
end

-- Called on join. Advances the cursor first (exitAt = 0) so a gap is paid at most once, and
-- pays only when `enabled`. Rate is the one saved at exit, never today's. Returns the coins.
function AquariumState.settleOffline(
	aq: Types.AquariumProfile,
	now: number,
	enabled: boolean
): number
	local exitAt, exitCpm = aq.exitAt, aq.exitCpm
	aq.exitAt, aq.exitCpm = 0, 0
	aq.offlineLast = { coins = 0, seconds = 0 }
	if not enabled or exitAt <= 0 or exitCpm <= 0 or now <= exitAt then
		return 0
	end
	local seconds = math.min(now - exitAt, Config.OFFLINE_MAX_SECONDS)
	local cpm = exitCpm * Config.OFFLINE_PERCENT // 100
	local coins = AquariumState.accrue(aq, cpm, seconds * 1000)
	if coins > 0 then
		aq.offlineLast = { coins = coins, seconds = seconds }
	end
	return coins
end

-- Income accounting, all integers. `ms` of play at `cpm` earns cpm*ms/60000 cents; the
-- remainder (0..59999) carries in `frac`. Returns whole coins earned and updates cents/frac.
function AquariumState.accrue(aq: Types.AquariumProfile, cpm: number, ms: number): number
	if cpm <= 0 or ms <= 0 then
		return 0
	end
	local numerator = cpm * ms + aq.frac
	local newCents = numerator // 60000
	aq.frac = numerator % 60000
	local totalCents = aq.cents + newCents
	aq.cents = totalCents % 100
	return totalCents // 100
end

return AquariumState
