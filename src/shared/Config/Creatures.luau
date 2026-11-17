--!strict
-- Creature catalog. Test models are the batch 01 part prototypes (ReplicatedStorage.Creatures);
-- ids must match the model names. Values and weights are first guesses for the economy.
--   baseValue          coins for an average-weight catch
--   weightMin/Max      kg; heavier = worth more (value scales 0.75x..1.25x across the range)
--   revealStyle        hint for the reveal VFX: "splash" | "bubbles" | "spark" | "prism"
--                      | "storm" | "crystal" | "cosmic"

export type Creature = {
	id: string,
	rarity: string,
	tier: number,
	baseValue: number,
	weightMin: number,
	weightMax: number,
	revealStyle: string,
}

local LIST: { Creature } = {
	{
		id = "C01_Bolhinha_Azul",
		rarity = "Common",
		tier = 1,
		baseValue = 10,
		weightMin = 0.2,
		weightMax = 0.8,
		revealStyle = "bubbles",
	},
	{
		id = "C02_Sardinha_Solar",
		rarity = "Common",
		tier = 1,
		baseValue = 12,
		weightMin = 0.1,
		weightMax = 0.5,
		revealStyle = "splash",
	},
	{
		id = "C03_Siri_Pipoca",
		rarity = "Common",
		tier = 1,
		baseValue = 14,
		weightMin = 0.3,
		weightMax = 1.2,
		revealStyle = "splash",
	},
	{
		id = "C04_Baiacu_Nuvem",
		rarity = "Uncommon",
		tier = 2,
		baseValue = 35,
		weightMin = 0.8,
		weightMax = 3,
		revealStyle = "bubbles",
	},
	{
		id = "C05_Medusinha_Estelar",
		rarity = "Uncommon",
		tier = 2,
		baseValue = 40,
		weightMin = 0.4,
		weightMax = 1.6,
		revealStyle = "spark",
	},
	{
		id = "C06_Cavalo_Marinho_Coral",
		rarity = "Uncommon",
		tier = 2,
		baseValue = 45,
		weightMin = 0.2,
		weightMax = 0.9,
		revealStyle = "prism",
	},
	{
		id = "C07_Arraia_Prisma",
		rarity = "Rare",
		tier = 3,
		baseValue = 110,
		weightMin = 6,
		weightMax = 24,
		revealStyle = "prism",
	},
	{
		id = "C08_Enguia_Trovao",
		rarity = "Rare",
		tier = 3,
		baseValue = 125,
		weightMin = 4,
		weightMax = 18,
		revealStyle = "storm",
	},
	{
		id = "C09_Guardiao_Cristal",
		rarity = "Epic",
		tier = 4,
		baseValue = 350,
		weightMin = 40,
		weightMax = 140,
		revealStyle = "crystal",
	},
	{
		id = "C10_Leviata_Astral",
		rarity = "Legendary",
		tier = 5,
		baseValue = 1500,
		weightMin = 400,
		weightMax = 1800,
		revealStyle = "cosmic",
	},
	-- Batch 02 (2026-11-17): fills the catalog to 24. Models come from Antigravity (A2).
	{
		id = "C11_Pingo_Lanterna",
		rarity = "Common",
		tier = 1,
		baseValue = 13,
		weightMin = 0.1,
		weightMax = 0.4,
		revealStyle = "spark",
	},
	{
		id = "C12_Camarao_Confete",
		rarity = "Common",
		tier = 1,
		baseValue = 11,
		weightMin = 0.05,
		weightMax = 0.2,
		revealStyle = "splash",
	},
	{
		id = "C13_Linguado_Sonolento",
		rarity = "Common",
		tier = 1,
		baseValue = 15,
		weightMin = 0.5,
		weightMax = 2,
		revealStyle = "bubbles",
	},
	{
		id = "C14_Polvinho_Aquarela",
		rarity = "Uncommon",
		tier = 2,
		baseValue = 42,
		weightMin = 0.6,
		weightMax = 2.5,
		revealStyle = "prism",
	},
	{
		id = "C15_Tartaruga_Musgo",
		rarity = "Uncommon",
		tier = 2,
		baseValue = 48,
		weightMin = 2,
		weightMax = 9,
		revealStyle = "bubbles",
	},
	{
		id = "C16_Voador_Brisa",
		rarity = "Uncommon",
		tier = 2,
		baseValue = 38,
		weightMin = 0.3,
		weightMax = 1.2,
		revealStyle = "splash",
	},
	{
		id = "C17_Martelo_Coral",
		rarity = "Rare",
		tier = 3,
		baseValue = 140,
		weightMin = 30,
		weightMax = 120,
		revealStyle = "prism",
	},
	{
		id = "C18_Lula_Neon",
		rarity = "Rare",
		tier = 3,
		baseValue = 120,
		weightMin = 3,
		weightMax = 14,
		revealStyle = "spark",
	},
	{
		id = "C19_Peixe_Lua_Dourado",
		rarity = "Rare",
		tier = 3,
		baseValue = 160,
		weightMin = 60,
		weightMax = 250,
		revealStyle = "cosmic",
	},
	{
		id = "C20_Raia_Vulcanica",
		rarity = "Epic",
		tier = 4,
		baseValue = 380,
		weightMin = 50,
		weightMax = 160,
		revealStyle = "magma",
	},
	{
		id = "C21_Baleia_Nebulosa",
		rarity = "Epic",
		tier = 4,
		baseValue = 420,
		weightMin = 900,
		weightMax = 3000,
		revealStyle = "cloud",
	},
	{
		id = "C22_Serpente_Glacial",
		rarity = "Epic",
		tier = 4,
		baseValue = 400,
		weightMin = 120,
		weightMax = 400,
		revealStyle = "frost",
	},
	{
		id = "C23_Kraken_Trovejante",
		rarity = "Legendary",
		tier = 5,
		baseValue = 1700,
		weightMin = 2000,
		weightMax = 6000,
		revealStyle = "storm",
	},
	{
		id = "C24_Fenix_das_Mares",
		rarity = "Legendary",
		tier = 5,
		baseValue = 1600,
		weightMin = 80,
		weightMax = 300,
		revealStyle = "magma",
	},
}

local byId: { [string]: Creature } = {}
for _, c in LIST do
	byId[c.id] = c
end

local Creatures = {}

Creatures.LIST = LIST
Creatures.MODELS_FOLDER = "Creatures"

function Creatures.get(id: string): Creature?
	return byId[id]
end

function Creatures.ofRarity(rarity: string): { Creature }
	local out = {}
	for _, c in LIST do
		if c.rarity == rarity then
			table.insert(out, c)
		end
	end
	return out
end

-- Coins for a catch of `weight` kg (0.75x at the minimum weight, 1.25x at the maximum).
function Creatures.valueFor(creature: Creature, weight: number): number
	local span = creature.weightMax - creature.weightMin
	local t = if span > 0 then math.clamp((weight - creature.weightMin) / span, 0, 1) else 0.5
	return math.floor(creature.baseValue * (0.75 + 0.5 * t) + 0.5)
end

return Creatures
