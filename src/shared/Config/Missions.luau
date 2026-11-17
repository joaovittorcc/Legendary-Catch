--!strict
-- Daily challenges: every day (00:00 UTC) each player gets DAILY_COUNT challenges drawn
-- from the pool, each with a different kind. Rewards are coins. First guesses.
--   kind: "catch" | "catchRarity:<Rarity>" | "earn" | "train" (seconds) | "perfect"

export type MissionDef = {
	id: string,
	kind: string,
	targetMin: number,
	targetMax: number,
	reward: number,
}

local Missions = {}

Missions.DAILY_COUNT = 3

Missions.POOL = {
	{ id = "catchAny", kind = "catch", targetMin = 10, targetMax = 20, reward = 150 },
	{
		id = "catchUncommon",
		kind = "catchRarity:Uncommon",
		targetMin = 3,
		targetMax = 5,
		reward = 200,
	},
	{ id = "catchRare", kind = "catchRarity:Rare", targetMin = 1, targetMax = 2, reward = 350 },
	{ id = "earnCoins", kind = "earn", targetMin = 500, targetMax = 1500, reward = 250 },
	{ id = "trainLagoon", kind = "train", targetMin = 120, targetMax = 300, reward = 200 },
	{ id = "perfectFights", kind = "perfect", targetMin = 3, targetMax = 5, reward = 250 },
	-- Variety (same kinds, so the client already describes them).
	{
		id = "catchCommon",
		kind = "catchRarity:Common",
		targetMin = 8,
		targetMax = 12,
		reward = 150,
	},
	{ id = "catchEpic", kind = "catchRarity:Epic", targetMin = 1, targetMax = 1, reward = 450 },
	{ id = "catchMany", kind = "catch", targetMin = 25, targetMax = 35, reward = 300 },
	{ id = "earnBig", kind = "earn", targetMin = 2000, targetMax = 3500, reward = 400 },
	{ id = "trainLong", kind = "train", targetMin = 360, targetMax = 600, reward = 300 },
} :: { MissionDef }

function Missions.today(): number
	return math.floor(os.time() / 86400)
end

-- Daily gift: coins on the first join of each UTC day. Grows with the number of days the
-- player has visited (cumulative, never resets, so missing a day costs nothing), capped.
Missions.DAILY_GIFT_BASE = 100
Missions.DAILY_GIFT_STEP = 50
Missions.DAILY_GIFT_MAX_STEPS = 6 -- day 7 and later: 100 + 6 * 50 = 400

function Missions.dailyGift(daysVisited: number): number
	local steps = math.clamp(daysVisited - 1, 0, Missions.DAILY_GIFT_MAX_STEPS)
	return Missions.DAILY_GIFT_BASE + steps * Missions.DAILY_GIFT_STEP
end

return Missions
