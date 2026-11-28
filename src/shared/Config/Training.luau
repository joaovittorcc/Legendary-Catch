--!strict
-- Semi-idle training at the lagoon. Two stats:
--   Control  -> fishing minigames get a little more forgiving
--   Instinct -> a little more luck toward rarer creatures
-- Bonuses are capped so training helps but never makes a legendary automatic.
-- All numbers are first-test guesses.

local Training = {}

Training.SPOT_TAG = "TrainingSpot"
Training.STATS = { "Control", "Instinct" }

Training.MAX_LEVEL = 25
Training.XP_PER_SECOND = 1
Training.SPOT_RADIUS = 16 -- leave this distance and training stops

-- Rhythm ring events while training (tap in time for bonus XP).
Training.RING_INTERVAL_MIN = 10
Training.RING_INTERVAL_MAX = 18
Training.RING_TIMEOUT = 10
Training.RING_BONUS_BASE = 8

function Training.xpToNext(level: number): number
	return 15 + level * 10
end

function Training.ringBonus(level: number): number
	return Training.RING_BONUS_BASE + level
end

-- Control: zones and timing windows scale by this (1.0 at level 0, 1.3 at max).
function Training.controlEase(level: number): number
	return 1 + 0.012 * math.clamp(level, 0, Training.MAX_LEVEL)
end

-- Instinct: multiplies the weight of a rarity by rank (1 = Common ... 6 = Mystic).
-- Scales steeper on higher tiers so late-game Fishing Power noticeably shifts catches
-- toward Epic, Legendary and Mystic creatures.
local LUCK_PER_LEVEL = { 0, 0.01, 0.035, 0.08, 0.18, 0.36 }

function Training.luckMultiplier(level: number, rank: number): number
	local slope = LUCK_PER_LEVEL[rank] or 0
	return 1 + slope * math.clamp(level, 0, Training.MAX_LEVEL)
end

function Training.levelAttribute(stat: string): string
	return "Train_" .. stat .. "_Level"
end

function Training.xpAttribute(stat: string): string
	return "Train_" .. stat .. "_XP"
end

-- Player attribute holding the stat being trained ("" when idle).
Training.ACTIVE_ATTRIBUTE = "TrainingStat"

---------------------------------------------------------------------------------------------
-- Fishing Power (Poder de Pesca), v2 of training. docs/PLANO-TREINO-PODER.md.
-- Each stat holds a power from 1 to 1e15 (1 Qa). The HUD shows the sum. Gameplay effects use
-- p = log10(power) / 15, mapped onto the old 0..25 level scale, so the luck/ease balance stays
-- exactly what it was at both ends. Behind the ReplicatedStorage attribute "TrainingPower"
-- (off by default): while off, the level/XP system above runs unchanged.
-- Pacing sim: node tools/training-sim.js (cap reached in ~116 play-hours at 50% training).
---------------------------------------------------------------------------------------------

Training.POWER_FLAG = "TrainingPower"
Training.POWER_CAP = 1e15 -- below 2^53, so a double still holds it exactly enough
Training.POWER_R0 = 8e-6 -- compounding rate: gain = M + power * R0 * M^0.3
Training.POWER_COMPOUND_EXP = 0.3
Training.RING_GAIN_SECONDS = 30 -- a hit ring pays this many seconds of the current gain
Training.DAILY_GAIN_SECONDS = 60 -- first training of the day
Training.PRESTIGE_GAIN_STEP = 0.25 -- gain x(1 + 0.25 x prestige); prestige never resets power
Training.FIELD_ATTRIBUTE = "TrainField"
Training.ISLAND_ATTRIBUTE = "TrainingIsland" -- on a TrainingSpot part: which island (1..4)
Training.STAT_ATTRIBUTE = "TrainingStat" -- on a TrainingSpot part: only this stat (optional)

export type FieldLevel = { mult: number, cost: number, gate: number }

-- Training field levels 1..10: gain multiplier, coins to BUY that level, power (sum) required.
Training.FIELD = {
	{ mult = 1, cost = 0, gate = 0 },
	{ mult = 2.5, cost = 1500, gate = 1e3 },
	{ mult = 6, cost = 6000, gate = 1e4 },
	{ mult = 15, cost = 20000, gate = 1e5 },
	{ mult = 38, cost = 60000, gate = 1e6 },
	{ mult = 95, cost = 180000, gate = 1e7 },
	{ mult = 240, cost = 500000, gate = 1e8 },
	{ mult = 600, cost = 1400000, gate = 1e9 },
	{ mult = 1500, cost = 3000000, gate = 1e10 },
	{ mult = 4000, cost = 5000000, gate = 1e12 },
} :: { FieldLevel }

export type Island = { mult: number, gate: number }

-- Training islands 1..4 (1 = the hub lagoon). Unlocked by power (sum) alone.
Training.ISLANDS = {
	{ mult = 1, gate = 0 },
	{ mult = 3, gate = 1e5 },
	{ mult = 12, gate = 1e8 },
	{ mult = 50, gate = 1e12 },
} :: { Island }

-- Colour tiers of the power number (index by Training.tier). UI may restyle; keep the order.
Training.TIER_COLORS = {
	Color3.fromRGB(255, 246, 228), -- 1..999 cream
	Color3.fromRGB(120, 230, 170), -- K   teal (Common)
	Color3.fromRGB(80, 200, 255), -- M   crystal blue (Uncommon)
	Color3.fromRGB(190, 120, 255), -- B   purple (Rare)
	Color3.fromRGB(255, 100, 220), -- T   neon pink (Epic)
	Color3.fromRGB(255, 205, 70), -- 1e13+ gold (Legendary)
	Color3.fromRGB(255, 255, 255), -- 1e15 cap: animated rainbow + gold (UI draws the gradient)
} :: { Color3 }

function Training.powerEnabled(): boolean
	return game:GetService("ReplicatedStorage"):GetAttribute(Training.POWER_FLAG) == true
end

function Training.powerAttribute(stat: string): string
	return "Train_" .. stat .. "_PP"
end

-- Any input to a clean power in [1, cap] (NaN, inf, negatives and junk become 1).
function Training.clampPower(value: any): number
	if typeof(value) ~= "number" or value ~= value or value < 1 then
		return 1
	end
	return math.min(value, Training.POWER_CAP)
end

-- 0 at power 1, 1 at the cap.
function Training.progress(power: number): number
	return math.clamp(math.log10(Training.clampPower(power)) / 15, 0, 1)
end

-- Power on the old 0..25 level scale (continuous). Feeds controlEase/luckMultiplier unchanged.
function Training.equivalentLevel(power: number): number
	return Training.progress(power) * Training.MAX_LEVEL
end

-- Migration and the flag-off mirror: level L (plus a fraction of the next) <-> power 10^(0.6 L).
function Training.powerFromLevel(level: number, xp: number?): number
	local lvl = math.clamp(if level == level then level else 0, 0, Training.MAX_LEVEL)
	local frac = 0
	if lvl < Training.MAX_LEVEL and xp and xp == xp and xp > 0 then
		frac = math.clamp(xp / Training.xpToNext(math.floor(lvl)), 0, 0.999)
	end
	return Training.clampPower(10 ^ ((15 / Training.MAX_LEVEL) * (math.floor(lvl) + frac)))
end

-- Old UI fields derived from power: whole level and XP inside it (so the bar still moves).
function Training.legacyLevel(power: number): (number, number)
	local eq = Training.equivalentLevel(power)
	local lvl = math.floor(eq + 1e-9)
	if lvl >= Training.MAX_LEVEL then
		return Training.MAX_LEVEL, 0
	end
	return lvl, math.floor((eq - lvl) * Training.xpToNext(lvl))
end

function Training.fieldLevel(level: any): number
	return if typeof(level) == "number" and level == level
		then math.clamp(math.floor(level), 1, #Training.FIELD)
		else 1
end

function Training.islandIndex(index: any): number
	return if typeof(index) == "number" and index == index
		then math.clamp(math.floor(index), 1, #Training.ISLANDS)
		else 1
end

-- Gain multiplier M from field, island and prestige.
function Training.multiplier(field: number, island: number, prestige: number): number
	return Training.FIELD[Training.fieldLevel(field)].mult
		* Training.ISLANDS[Training.islandIndex(island)].mult
		* (1 + Training.PRESTIGE_GAIN_STEP * math.max(0, prestige))
end

-- Power gained per second of training at `power` with multiplier M.
function Training.gainPerSecond(power: number, mult: number): number
	local m = math.max(mult, 0)
	return m + Training.clampPower(power) * Training.POWER_R0 * m ^ Training.POWER_COMPOUND_EXP
end

-- Adds `amount` to `power`, capped and finite.
function Training.addPower(power: number, amount: number): number
	if amount ~= amount or amount <= 0 then
		return Training.clampPower(power)
	end
	return Training.clampPower(Training.clampPower(power) + amount)
end

-- Buying field level `current + 1`. Returns ok, reason ("max" | "power" | "coins"), cost.
function Training.canBuyField(
	current: number,
	powerSum: number,
	coins: number
): (boolean, string?, number)
	local nextLevel = Training.fieldLevel(current) + 1
	local def = Training.FIELD[nextLevel]
	if not def then
		return false, "max", 0
	end
	if powerSum < def.gate then
		return false, "power", def.cost
	end
	if coins < def.cost then
		return false, "coins", def.cost
	end
	return true, nil, def.cost
end

function Training.islandAllowed(index: number, powerSum: number): boolean
	return powerSum >= Training.ISLANDS[Training.islandIndex(index)].gate
end

-- Colour tier 1..7 of a power value (see TIER_COLORS).
function Training.tier(power: number): number
	local e = math.floor(math.log10(Training.clampPower(power)) + 1e-9)
	if power >= Training.POWER_CAP then
		return 7
	elseif e >= 13 then
		return 6
	elseif e >= 11 then
		return 5
	elseif e >= 9 then
		return 4
	elseif e >= 6 then
		return 3
	elseif e >= 3 then
		return 2
	end
	return 1
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa" }

-- Short form with 3 significant digits, rounded BEFORE picking the suffix (999.950 -> "1M",
-- never "1000K"). `decimal` is the separator ("," in PT, "." in EN). fwjelaa vault:
-- "Big Numbers Precision and Formatting" §8.
function Training.formatPower(value: number, decimal: string?): string
	local n = if value == value then math.max(value, 0) else 0
	if n < 1000 then
		return tostring(math.floor(n + 1e-9))
	end
	local e = math.floor(math.log10(n))
	local m = n / 10 ^ e
	m = math.round(m * 100) / 100
	if m >= 10 then
		m /= 10
		e += 1
	end
	local t = e // 3
	if t + 1 > #SUFFIXES then
		t = #SUFFIXES - 1
	end
	local scaled = m * 10 ^ (e - t * 3)
	local intDigits = #tostring(math.floor(scaled))
	local decimals = math.max(0, 3 - intDigits)
	local text = string.format("%." .. decimals .. "f", scaled)
	if decimals > 0 then
		text = (text:gsub("0+$", ""):gsub("%.$", ""))
	end
	if decimal and decimal ~= "." then
		text = text:gsub("%.", decimal)
	end
	return text .. SUFFIXES[t + 1]
end

return Training
