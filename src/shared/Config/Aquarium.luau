--!strict
-- Aquarium economy parameters (pilot, paramsVersion 1). Source of truth for passive income.
-- Numbers come from docs/ECONOMIA-AQUARIO-S0.md (tools/aquarium-sim.js): the plan's bands x0.2.
--   cpm  = hundredths of a coin per MINUTE, integer, multiple of 10 (so the variant factors
--          below stay integers). 180 = 1.80 coins/min. UI shows cpm / 100 per minute.
-- Re-tune here only; the server reads these and the client may read them for labels, never to decide.

export type Level = {
	id: string,
	level: number,
	slots: number,
	cost: number, -- coins, paid once when moving to this level
	minSpecies: number, -- distinct species discovered to unlock (veteran gate, to be confirmed)
}

local Aquarium = {}

Aquarium.PARAMS_VERSION = 1
Aquarium.MIGRATION_VERSION = 1

-- Level ids follow the Antigravity geometry ids (aquarium_lv1_nursery already exists in A0;
-- levels 2-4 are proposals until Antigravity confirms on the Mural).
Aquarium.LEVELS = {
	{ id = "aquarium_lv1_nursery", level = 1, slots = 3, cost = 0, minSpecies = 0 },
	{ id = "aquarium_lv2_reef", level = 2, slots = 5, cost = 3000, minSpecies = 15 },
	{ id = "aquarium_lv3_gallery", level = 3, slots = 8, cost = 12000, minSpecies = 40 },
	{ id = "aquarium_lv4_sanctuary", level = 4, slots = 12, cost = 50000, minSpecies = 70 },
} :: { Level }

Aquarium.VARIANTS = { "base", "giant", "gold", "both" }

-- Rate factor per variant, in hundredths (x1.30 = 130) so integer math stays exact.
Aquarium.VARIANT_PERCENT =
	{ base = 100, giant = 130, gold = 160, both = 190 } :: { [string]: number }

-- Synergy bonus percent applied to participants (S2 fills the families; 0 until then).
Aquarium.MAX_SYNERGY_PERCENT = 10

-- Payout cadence (seconds) for the online batch, and request-id memory per session.
Aquarium.PAY_INTERVAL = 5
Aquarium.REQUEST_MEMORY = 20

-- Flags (live, read from ReplicatedStorage attributes so they can be flipped without a deploy).
--   AquariumUI      false hides the feature from clients (snapshot status "disabled")
--   AquariumCredit  false pauses passive income (rights and progress are kept)
Aquarium.UI_ATTRIBUTE = "AquariumUI"
Aquarium.CREDIT_ATTRIBUTE = "AquariumCredit"

Aquarium.RATES_CPM = {
	C01_Bolhinha_Azul = 180,
	C02_Sardinha_Solar = 230,
	C03_Siri_Pipoca = 320,
	C04_Baiacu_Nuvem = 420,
	C05_Medusinha_Estelar = 510,
	C06_Cavalo_Marinho_Coral = 670,
	C07_Arraia_Prisma = 840,
	C08_Enguia_Trovao = 950,
	C09_Guardiao_Cristal = 1560,
	C10_Leviata_Astral = 2880,
	C11_Pingo_Lanterna = 280,
	C12_Camarao_Confete = 200,
	C13_Linguado_Sonolento = 350,
	C14_Polvinho_Aquarela = 560,
	C15_Tartaruga_Musgo = 760,
	C16_Voador_Brisa = 460,
	C17_Martelo_Coral = 1180,
	C18_Lula_Neon = 870,
	C19_Peixe_Lua_Dourado = 1350,
	C20_Raia_Vulcanica = 1670,
	C21_Baleia_Nebulosa = 2260,
	C22_Serpente_Glacial = 1880,
	C23_Kraken_Trovejante = 3220,
	C24_Fenix_das_Mares = 2990,
	C25_Ourico_Gelatina = 240,
	C26_Peixe_Pipa = 290,
	C27_Ermitao_Cristal = 640,
	C28_Nautilo_Aurora = 1100,
	C29_Dragao_Folha = 1780,
	C30_Tartaruga_Ilha = 3110,
	C31_Carpa_Celeste = 730,
	C32_Espadarte_Relampago = 1270,
	C33_Orca_Aurora = 2100,
	C34_Serpente_Arco_Iris = 3330,
	C60_Hidra_das_Profundezas = 3560,
	C61_Baleia_Celestial = 3780,
	C62_Dragao_Dourado = 4010,
	C63_Grifo_Marinho = 3440,
	C64_Guardiao_Abissal = 4690,
	C50_Tubarao_Baleia_Estrelado = 1410,
	C51_Lanterna_Abissal = 1040,
	C52_Cavalo_Marinho_Real = 900,
	C53_Moreia_Voltaica = 1210,
	C54_Peixe_Vela_Solar = 1300,
	C55_Caranguejo_Rei_Gelo = 1130,
	C56_Dragao_de_Coral = 1940,
	C57_Manta_Galactica = 2480,
	C58_Tubarao_Fantasma = 2150,
	C59_Narval_Unicornio = 2320,
	C35_Bagre_Bigodudo = 250,
	C36_Peixe_Bolha_Rosa = 210,
	C37_Caramujo_Doce = 190,
	C38_Estrela_Sonolenta = 260,
	C39_Lambari_Prata = 210,
	C40_Caranguejo_Bolacha = 300,
	C41_Palhaco_Neon = 330,
	C42_Lulinha_Gota = 270,
	C43_Baiacu_Algodao_Doce = 530,
	C44_Arraia_Pintada = 650,
	C45_Tartaruguinha_Coral = 580,
	C46_Peixe_Leque = 470,
	C47_Medusa_Lanterna = 740,
	C48_Peixe_Anjo_Real = 780,
	C49_Polvo_Bolinhas = 690,
	C75_Leao_Marinho_Dourado = 1240,
	C76_Raia_Aurora = 980,
	C77_Cavalo_Marinho_Relogio = 930,
	C78_Lagosta_Armadura = 1150,
	C79_Mantarraia_Vitral = 1380,
	C80_Peixe_Pavao_Eletrico = 1070,
	C81_Enguia_Fita_de_Seda = 1010,
	C93_Ouroboros_Cosmico = 5040,
	C94_Mare_Primordial = 7200,
	C65_Tilapia_Moranguinho = 270,
	C66_Ourico_Pompom = 310,
	C67_Lesma_do_Mar_Arco_iris = 340,
	C68_Peixe_Biscoito = 220,
	C69_Ermitao_Xicara = 360,
	C70_Agua_viva_Lanterna = 490,
	C71_Peixe_Espada_Neon = 710,
	C72_Tartaruga_Pergaminho = 600,
	C73_Polvo_Origami = 550,
	C74_Baiacu_Balao_de_Festa = 440,
	C82_Kitsune_Aquatica = 2370,
	C83_Golfinho_Trovao = 1990,
	C84_Tubarao_Martelo_de_Cristal = 2210,
	C85_Lula_Galaxia = 1720,
	C86_Cervo_Coral = 1830,
	C87_Salamandra_de_Lava = 1610,
	C88_Rei_Tritao_Colossal = 4120,
	C89_Dragao_de_Jade = 3900,
	C90_Tartaruga_Mundo = 4800,
	C91_Hipocampo_Imperial = 3670,
	C92_Serafim_do_Mar = 4240,
	C95_Peixe_Vagalume_Real = 1440,
	C96_Lua_Dourada = 2530,
	C97_Raia_Tempestade = 2420,
	C98_Coral_Ancestral_Vivo = 2640,
	C99_Baleia_Fantasma = 4350,
	C100_Aurora_Boreal_Viva = 4570,
	C101_Rena_do_Mar = 330,
	C102_Peixe_Arvore_de_Natal = 620,
	C103_Boneco_de_Gelo_Marinho = 1330,
	C104_Polvo_Presente = 2050,
	C105_Estrela_do_Natal = 2590,
	C106_Rei_do_Gelo_Natalino = 4460,
} :: { [string]: number }

local levelsById: { [string]: Level } = {}
for _, l in Aquarium.LEVELS do
	levelsById[l.id] = l
end

function Aquarium.level(level: number): Level?
	return Aquarium.LEVELS[level]
end

function Aquarium.levelById(id: string): Level?
	return levelsById[id]
end

function Aquarium.variantId(isGiant: boolean, isGold: boolean): string
	if isGiant and isGold then
		return "both"
	elseif isGiant then
		return "giant"
	elseif isGold then
		return "gold"
	end
	return "base"
end

-- Individual rate of one creature variant, in cpm (nil for an unknown creature or variant).
function Aquarium.rateCpm(creatureId: string, variant: string): number?
	local base = Aquarium.RATES_CPM[creatureId]
	local percent = Aquarium.VARIANT_PERCENT[variant]
	if base == nil or percent == nil then
		return nil
	end
	return base * percent // 100
end

return Aquarium
