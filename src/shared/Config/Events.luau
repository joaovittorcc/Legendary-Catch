--!strict
-- Ocean events: random, server-wide, temporary. During an event rarer creatures are more
-- likely (rarityBoost multiplies the rarity's weight) and catches can be worth more.
-- Events come back on rotation: nothing is lost forever (no FOMO).

export type OceanEvent = {
	id: string,
	durationSeconds: number,
	rarityBoost: { [string]: number },
	valueMultiplier: number,
}

local LIST: { OceanEvent } = {
	{
		id = "starTide",
		durationSeconds = 180,
		rarityBoost = { Rare = 1.5, Epic = 2, Legendary = 2.5 },
		valueMultiplier = 1.25,
	},
	{
		id = "thunderStorm",
		durationSeconds = 150,
		rarityBoost = { Rare = 2, Epic = 1.5 },
		valueMultiplier = 1.15,
	},
	{
		id = "goldenHour",
		durationSeconds = 120,
		rarityBoost = { Uncommon = 1.5 },
		valueMultiplier = 2,
	},
	{
		-- Friendly event for new players: more Uncommon/Rare, nothing extreme.
		id = "shimmerShoal",
		durationSeconds = 150,
		rarityBoost = { Uncommon = 1.8, Rare = 1.4 },
		valueMultiplier = 1.3,
	},
	{
		id = "fogBank",
		durationSeconds = 150,
		rarityBoost = { Epic = 1.8, Legendary = 2 },
		valueMultiplier = 1.35,
	},
	{
		id = "aurora",
		durationSeconds = 180,
		rarityBoost = { Legendary = 2.2, Mystic = 1.5 },
		valueMultiplier = 1.5,
	},
}

local byId: { [string]: OceanEvent } = {}
for _, e in LIST do
	byId[e.id] = e
end

local Events = {}

Events.LIST = LIST
Events.INTERVAL_MIN = 12 * 60
Events.INTERVAL_MAX = 20 * 60
Events.ACTIVE_ATTRIBUTE = "OceanEvent"
Events.ENDS_AT_ATTRIBUTE = "OceanEventEndsAt"

function Events.get(id: string): OceanEvent?
	return byId[id]
end

return Events
