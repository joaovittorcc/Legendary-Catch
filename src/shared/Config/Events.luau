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
