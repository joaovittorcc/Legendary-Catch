--!strict
-- Test catalog: prototype part models from batch 01 (ReplicatedStorage.Creatures).
-- Final models and drop rates come later; ids must match the model names.

export type Creature = {
	id: string,
	rarity: string,
	tier: number,
}

local LIST: { Creature } = {
	{ id = "C01_Bolhinha_Azul", rarity = "Common", tier = 1 },
	{ id = "C02_Sardinha_Solar", rarity = "Common", tier = 1 },
	{ id = "C03_Siri_Pipoca", rarity = "Common", tier = 1 },
	{ id = "C04_Baiacu_Nuvem", rarity = "Uncommon", tier = 2 },
	{ id = "C05_Medusinha_Estelar", rarity = "Uncommon", tier = 2 },
	{ id = "C06_Cavalo_Marinho_Coral", rarity = "Uncommon", tier = 2 },
	{ id = "C07_Arraia_Prisma", rarity = "Rare", tier = 3 },
	{ id = "C08_Enguia_Trovao", rarity = "Rare", tier = 3 },
	{ id = "C09_Guardiao_Cristal", rarity = "Epic", tier = 4 },
	{ id = "C10_Leviata_Astral", rarity = "Legendary", tier = 5 },
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

return Creatures
