--!strict
-- Achievements: unlock automatically when a counter reaches `target` (coins paid by the
-- server, announced on the AdventureReward remote). Names/descriptions live in the UI strings
-- under `achievements.<id>`.
--   metric: "catches" | "species" | "legendaries" | "level" | "combo" | "training" | "mystic"
--           (mystic: number of Mystic species discovered)

export type Achievement = {
	id: string,
	metric: string,
	target: number,
	reward: number,
}

local LIST: { Achievement } = {
	{ id = "firstCatch", metric = "catches", target = 1, reward = 50 },
	{ id = "catches10", metric = "catches", target = 10, reward = 100 },
	{ id = "catches50", metric = "catches", target = 50, reward = 300 },
	{ id = "catches100", metric = "catches", target = 100, reward = 600 },
	{ id = "catches500", metric = "catches", target = 500, reward = 3000 },
	{ id = "species5", metric = "species", target = 5, reward = 150 },
	{ id = "species25", metric = "species", target = 25, reward = 1000 },
	{ id = "species50", metric = "species", target = 50, reward = 4000 },
	{ id = "species100", metric = "species", target = 100, reward = 20000 },
	{ id = "legendary1", metric = "legendaries", target = 1, reward = 1000 },
	{ id = "legendary5", metric = "legendaries", target = 5, reward = 5000 },
	{ id = "mystic1", metric = "mystic", target = 1, reward = 25000 },
	{ id = "level5", metric = "level", target = 5, reward = 250 },
	{ id = "level10", metric = "level", target = 10, reward = 800 },
	{ id = "level25", metric = "level", target = 25, reward = 5000 },
	{ id = "combo5", metric = "combo", target = 5, reward = 300 },
	{ id = "combo10", metric = "combo", target = 10, reward = 1500 },
	{ id = "training10", metric = "training", target = 10, reward = 600 },
	{ id = "training25", metric = "training", target = 25, reward = 6000 },
}

local Achievements = {}

Achievements.LIST = LIST

return Achievements
