--!strict
-- Fishing zones along the island and beyond. Higher-level zones boost rarer
-- catches on top of rod, instinct, prestige and ocean event luck multipliers.

local CollectionService = game:GetService("CollectionService")

local FishingConfig = require(script.Parent:WaitForChild("Fishing"))

export type FishingZone = {
	id: string,
	order: number,
	minLevel: number,
	rarityBoost: { [string]: number },
	color: Color3,
	icon: string,
}

local LIST: { FishingZone } = {
	{
		id = "lagoon",
		order = 1,
		minLevel = 1,
		rarityBoost = {},
		color = Color3.fromRGB(92, 224, 210),
		icon = "🏖️",
	},
	{
		id = "coral",
		order = 2,
		minLevel = 5,
		rarityBoost = { Rare = 1.4, Epic = 1.3 },
		color = Color3.fromRGB(255, 130, 175),
		icon = "🪸",
	},
	{
		id = "abyss",
		order = 3,
		minLevel = 15,
		rarityBoost = { Epic = 1.5, Legendary = 1.6, Mystic = 1.3 },
		color = Color3.fromRGB(115, 225, 255),
		icon = "🌌",
	},
}

local byId: { [string]: FishingZone } = {}
for _, zone in LIST do
	byId[zone.id] = zone
end

local Zones = {}

Zones.LIST = LIST
Zones.DEFAULT_ID = "lagoon"
Zones.ID_ATTRIBUTE = "ZoneId"
Zones.PLAYER_ATTRIBUTE = "FishingZone"

function Zones.get(id: string): FishingZone?
	return byId[id]
end

function Zones.boostFor(id: string?, rarity: string): number
	local zone = if id then byId[id] else nil
	return if zone then zone.rarityBoost[rarity] or 1 else 1
end

function Zones.zoneIdOfPart(part: BasePart): string
	local attr = part:GetAttribute(Zones.ID_ATTRIBUTE)
	if typeof(attr) == "string" and byId[attr] then
		return attr
	end
	return Zones.DEFAULT_ID
end

function Zones.findAt(position: Vector3): FishingZone?
	local best: FishingZone? = nil
	for _, zonePart in CollectionService:GetTagged(FishingConfig.ZONE_TAG) do
		if zonePart:IsA("BasePart") then
			local localPos = zonePart.CFrame:PointToObjectSpace(position)
			local half = zonePart.Size * 0.5
			if
				math.abs(localPos.X) <= half.X
				and math.abs(localPos.Y) <= half.Y
				and math.abs(localPos.Z) <= half.Z
			then
				local zone = byId[Zones.zoneIdOfPart(zonePart)]
				if zone and (not best or zone.order > best.order) then
					best = zone
				end
			end
		end
	end
	return best
end

return Zones
