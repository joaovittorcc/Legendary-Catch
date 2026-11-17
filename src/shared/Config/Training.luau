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

-- Instinct: multiplies the weight of a rarity by rank (1 = Common ... 5 = Legendary).
-- Max level: Uncommon x1.25, Rare x1.5, Epic x1.75, Legendary x2.
function Training.luckMultiplier(level: number, rank: number): number
	return 1 + 0.01 * math.clamp(level, 0, Training.MAX_LEVEL) * (rank - 1)
end

function Training.levelAttribute(stat: string): string
	return "Train_" .. stat .. "_Level"
end

function Training.xpAttribute(stat: string): string
	return "Train_" .. stat .. "_XP"
end

-- Player attribute holding the stat being trained ("" when idle).
Training.ACTIVE_ATTRIBUTE = "TrainingStat"

return Training
