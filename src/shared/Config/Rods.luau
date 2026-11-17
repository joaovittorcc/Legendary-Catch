--!strict
-- Rods sold at the upgrade workshop. Bonuses stack with training:
--   controlBonus  extra fraction on minigame zones/windows (0.2 = +20%)
--   luckBonus     extra weight per rarity rank above Common (0.3 = Legendary x1.3)
-- Prices from a rough pacing estimate (2026-11-17): ~13 s per catch, ~62 coins per catch at
-- base luck = ~285 coins/min. Coral ~2 min, Crystal ~10 min, Storm ~50 min, Astral ~3.5 h of
-- fishing. Re-tune with real Analytics data after launch.

export type Rod = {
	id: string,
	order: number,
	price: number,
	controlBonus: number,
	luckBonus: number,
	color: Color3, -- blank color
	tipColor: Color3,
}

local LIST: { Rod } = {
	{
		id = "starter",
		order = 1,
		price = 0,
		controlBonus = 0,
		luckBonus = 0,
		color = Color3.fromRGB(28, 26, 40),
		tipColor = Color3.fromRGB(150, 230, 255),
	},
	{
		id = "coral",
		order = 2,
		price = 500,
		controlBonus = 0.05,
		luckBonus = 0.05,
		color = Color3.fromRGB(230, 110, 120),
		tipColor = Color3.fromRGB(255, 200, 160),
	},
	{
		id = "crystal",
		order = 3,
		price = 3000,
		controlBonus = 0.1,
		luckBonus = 0.12,
		color = Color3.fromRGB(80, 170, 230),
		tipColor = Color3.fromRGB(120, 240, 255),
	},
	{
		id = "storm",
		order = 4,
		price = 15000,
		controlBonus = 0.15,
		luckBonus = 0.2,
		color = Color3.fromRGB(60, 60, 110),
		tipColor = Color3.fromRGB(200, 190, 255),
	},
	{
		id = "astral",
		order = 5,
		price = 60000,
		controlBonus = 0.2,
		luckBonus = 0.32,
		color = Color3.fromRGB(80, 40, 140),
		tipColor = Color3.fromRGB(255, 210, 90),
	},
}

local byId: { [string]: Rod } = {}
for _, r in LIST do
	byId[r.id] = r
end

local Rods = {}

Rods.LIST = LIST
Rods.STARTER = "starter"

function Rods.get(id: string): Rod?
	return byId[id]
end

function Rods.luckMultiplier(rod: Rod?, rank: number): number
	return 1 + (if rod then rod.luckBonus else 0) * (rank - 1) / 4
end

return Rods
