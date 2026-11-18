--!strict
-- Collection milestones, claimed once each for coins.
--   kind "species": at least `count` different creatures caught
--   kind "rarity":  every creature of `rarity` caught at least once

export type Milestone = {
	id: string,
	kind: string,
	rarity: string?,
	count: number,
	reward: number,
}

local LIST: { Milestone } = {
	{ id = "species5", kind = "species", count = 5, reward = 100 },
	{ id = "species10", kind = "species", count = 10, reward = 300 },
	{ id = "species15", kind = "species", count = 15, reward = 600 },
	{ id = "species20", kind = "species", count = 20, reward = 1200 },
	{ id = "species24", kind = "species", count = 24, reward = 3000 },
	{ id = "species30", kind = "species", count = 30, reward = 5000 },
	{ id = "species34", kind = "species", count = 34, reward = 8000 },
	{ id = "species39", kind = "species", count = 39, reward = 12000 },
	{ id = "species44", kind = "species", count = 44, reward = 15000 },
	{ id = "species49", kind = "species", count = 49, reward = 20000 },
	{ id = "species54", kind = "species", count = 54, reward = 25000 },
	{ id = "species59", kind = "species", count = 59, reward = 32000 },
	{ id = "species64", kind = "species", count = 64, reward = 50000 },
	{ id = "species69", kind = "species", count = 69, reward = 45000 },
	{ id = "species73", kind = "species", count = 73, reward = 60000 },
	{ id = "species83", kind = "species", count = 83, reward = 80000 },
	{ id = "species94", kind = "species", count = 94, reward = 150000 },
	{ id = "species100", kind = "species", count = 100, reward = 250000 },
	{ id = "allCommon", kind = "rarity", rarity = "Common", count = 0, reward = 150 },
	{ id = "allUncommon", kind = "rarity", rarity = "Uncommon", count = 0, reward = 300 },
	{ id = "allRare", kind = "rarity", rarity = "Rare", count = 0, reward = 600 },
	{ id = "allEpic", kind = "rarity", rarity = "Epic", count = 0, reward = 1200 },
	{ id = "allLegendary", kind = "rarity", rarity = "Legendary", count = 0, reward = 5000 },
	{ id = "allMystic", kind = "rarity", rarity = "Mystic", count = 0, reward = 25000 },
}

local byId: { [string]: Milestone } = {}
for _, m in LIST do
	byId[m.id] = m
end

local Milestones = {}

Milestones.LIST = LIST

function Milestones.get(id: string): Milestone?
	return byId[id]
end

return Milestones
