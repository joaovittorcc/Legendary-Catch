--!strict
-- Rods sold at the upgrade workshop. Bonuses stack with training:
--   controlBonus  extra fraction on minigame zones/windows (0.2 = +20%)
--   luckBonus     extra weight per rarity rank above Common (0.32 = Legendary x2.28)
-- Prices from a simulated pace (2026-11-17, ~13 s per catch): starter ~310 coins/min,
-- Astral ~450. Coral ~2 min, Crystal ~9 min, Storm ~40 min, Astral ~2.5 h of fishing.
-- Re-tune with real Analytics data after launch.

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
	-- Late game (added 2026-11-18): priced for hours of play; luck now reaches the Mystic rank.
	{
		id = "celestial",
		order = 6,
		price = 200000,
		controlBonus = 0.24,
		luckBonus = 0.42,
		color = Color3.fromRGB(150, 210, 255),
		tipColor = Color3.fromRGB(255, 255, 255),
	},
	{
		id = "abyss",
		order = 7,
		price = 600000,
		controlBonus = 0.28,
		luckBonus = 0.55,
		color = Color3.fromRGB(20, 30, 70),
		tipColor = Color3.fromRGB(90, 255, 220),
	},
	{
		id = "mystic",
		order = 8,
		price = 2000000,
		controlBonus = 0.32,
		luckBonus = 0.75,
		color = Color3.fromRGB(120, 20, 70),
		tipColor = Color3.fromRGB(255, 64, 110),
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

-- Weight multiplier for a rarity rank (1 = Common ... 5 = Legendary). Grows with the rank so
-- better rods shift catches toward rarer creatures. Simulated 2026-11-17: Astral earns ~45%
-- more coins/min than the starter and Legendary goes from 1% to ~1.9%.
function Rods.luckMultiplier(rod: Rod?, rank: number): number
	return 1 + (if rod then rod.luckBonus else 0) * (rank - 1)
end

return Rods
