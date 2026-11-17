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
	{ id = "allCommon", kind = "rarity", rarity = "Common", count = 0, reward = 150 },
	{ id = "allUncommon", kind = "rarity", rarity = "Uncommon", count = 0, reward = 300 },
	{ id = "allRare", kind = "rarity", rarity = "Rare", count = 0, reward = 600 },
	{ id = "allEpic", kind = "rarity", rarity = "Epic", count = 0, reward = 1200 },
	{ id = "allLegendary", kind = "rarity", rarity = "Legendary", count = 0, reward = 5000 },
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
