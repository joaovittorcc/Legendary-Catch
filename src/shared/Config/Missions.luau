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

-- Daily login streak: 7-day escalating coin rewards + special Day 7 treasure chest.
-- Days 8+ continue incrementing `streak` while cycling slots 1..7 on the reward ladder.
Missions.STREAK_DAYS = 7
Missions.STREAK_SHIELD_COOLDOWN_DAYS = 7 -- 1 grace day (gap == 2) allowed once per 7 days
Missions.STREAK_REWARDS = { 100, 150, 225, 350, 500, 750, 1000 }
Missions.DAY7_CHEST_MIN = 500
Missions.DAY7_CHEST_MAX = 1000

-- Kept for compatibility with callers passing day count; maps 1..N onto the 7-day ladder.
function Missions.streakDaySlot(streak: number): number
	local s = math.max(1, math.floor(streak))
	return ((s - 1) % Missions.STREAK_DAYS) + 1
end

function Missions.dailyGift(streak: number): number
	local slot = Missions.streakDaySlot(streak)
	return Missions.STREAK_REWARDS[slot] or Missions.STREAK_REWARDS[1]
end

return Missions
