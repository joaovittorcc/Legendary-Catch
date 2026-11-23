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
Aquarium.OFFLINE_ATTRIBUTE = "AquariumOffline"

-- Default of the UI and credit flags when no attribute is set: ON in Studio, and in a live
-- server only when this constant is true. Ship it false, verify on a test server, then flip
-- it here and publish (there is no live config channel yet). The offline flag is OFF
-- everywhere unless its attribute is explicitly true.
Aquarium.LIVE_ENABLED = false

-- Offline pilot (flag off): a quarter of the rate the tank had when the player left, for at
-- most two hours, paid once on the next join.
Aquarium.OFFLINE_PERCENT = 25
Aquarium.OFFLINE_MAX_SECONDS = 7200

-- Synergy families (one per creature). Derived from the reveal style so every species is
-- covered; the family names are working names to confirm with João:
--   reef (bubbles/splash/prism), tempest (storm/cloud), abyss (spark/crystal/magma/frost),
--   celestial (cosmic), festival (Christmas season).
-- 2 distinct species of one family in the tank = +5%, 3 or more = +10% to those participants.
-- A variant of the same species never counts as another species.
Aquarium.SYNERGY_TIERS = { { species = 3, percent = 10 }, { species = 2, percent = 5 } }

Aquarium.FAMILY = {
	C01_Bolhinha_Azul = "reef",
	C02_Sardinha_Solar = "reef",
	C03_Siri_Pipoca = "reef",
	C04_Baiacu_Nuvem = "reef",
	C05_Medusinha_Estelar = "abyss",
	C06_Cavalo_Marinho_Coral = "reef",
	C07_Arraia_Prisma = "reef",
	C08_Enguia_Trovao = "tempest",
	C09_Guardiao_Cristal = "abyss",
	C10_Leviata_Astral = "celestial",
	C11_Pingo_Lanterna = "abyss",
	C12_Camarao_Confete = "reef",
	C13_Linguado_Sonolento = "reef",
	C14_Polvinho_Aquarela = "reef",
	C15_Tartaruga_Musgo = "reef",
	C16_Voador_Brisa = "reef",
	C17_Martelo_Coral = "reef",
	C18_Lula_Neon = "abyss",
	C19_Peixe_Lua_Dourado = "celestial",
	C20_Raia_Vulcanica = "abyss",
	C21_Baleia_Nebulosa = "tempest",
	C22_Serpente_Glacial = "abyss",
	C23_Kraken_Trovejante = "tempest",
	C24_Fenix_das_Mares = "abyss",
	C25_Ourico_Gelatina = "reef",
	C26_Peixe_Pipa = "reef",
	C27_Ermitao_Cristal = "abyss",
	C28_Nautilo_Aurora = "reef",
	C29_Dragao_Folha = "abyss",
	C30_Tartaruga_Ilha = "abyss",
	C31_Carpa_Celeste = "tempest",
	C32_Espadarte_Relampago = "tempest",
	C33_Orca_Aurora = "abyss",
	C34_Serpente_Arco_Iris = "reef",
	C60_Hidra_das_Profundezas = "tempest",
	C61_Baleia_Celestial = "celestial",
	C62_Dragao_Dourado = "tempest",
	C63_Grifo_Marinho = "tempest",
	C64_Guardiao_Abissal = "abyss",
	C50_Tubarao_Baleia_Estrelado = "celestial",
	C51_Lanterna_Abissal = "abyss",
	C52_Cavalo_Marinho_Real = "abyss",
	C53_Moreia_Voltaica = "tempest",
	C54_Peixe_Vela_Solar = "abyss",
	C55_Caranguejo_Rei_Gelo = "abyss",
	C56_Dragao_de_Coral = "reef",
	C57_Manta_Galactica = "celestial",
	C58_Tubarao_Fantasma = "abyss",
	C59_Narval_Unicornio = "abyss",
	C35_Bagre_Bigodudo = "reef",
	C36_Peixe_Bolha_Rosa = "reef",
	C37_Caramujo_Doce = "reef",
	C38_Estrela_Sonolenta = "abyss",
	C39_Lambari_Prata = "reef",
	C40_Caranguejo_Bolacha = "reef",
	C41_Palhaco_Neon = "abyss",
	C42_Lulinha_Gota = "reef",
	C43_Baiacu_Algodao_Doce = "tempest",
	C44_Arraia_Pintada = "reef",
	C45_Tartaruguinha_Coral = "reef",
	C46_Peixe_Leque = "reef",
	C47_Medusa_Lanterna = "abyss",
	C48_Peixe_Anjo_Real = "reef",
	C49_Polvo_Bolinhas = "reef",
	C75_Leao_Marinho_Dourado = "abyss",
	C76_Raia_Aurora = "reef",
	C77_Cavalo_Marinho_Relogio = "abyss",
	C78_Lagosta_Armadura = "abyss",
	C79_Mantarraia_Vitral = "reef",
	C80_Peixe_Pavao_Eletrico = "tempest",
	C81_Enguia_Fita_de_Seda = "tempest",
	C93_Ouroboros_Cosmico = "celestial",
	C94_Mare_Primordial = "celestial",
	C65_Tilapia_Moranguinho = "reef",
	C66_Ourico_Pompom = "abyss",
	C67_Lesma_do_Mar_Arco_iris = "reef",
	C68_Peixe_Biscoito = "reef",
	C69_Ermitao_Xicara = "reef",
	C70_Agua_viva_Lanterna = "abyss",
	C71_Peixe_Espada_Neon = "tempest",
	C72_Tartaruga_Pergaminho = "abyss",
	C73_Polvo_Origami = "tempest",
	C74_Baiacu_Balao_de_Festa = "reef",
	C82_Kitsune_Aquatica = "abyss",
	C83_Golfinho_Trovao = "tempest",
	C84_Tubarao_Martelo_de_Cristal = "abyss",
	C85_Lula_Galaxia = "celestial",
	C86_Cervo_Coral = "reef",
	C87_Salamandra_de_Lava = "abyss",
	C88_Rei_Tritao_Colossal = "tempest",
	C89_Dragao_de_Jade = "tempest",
	C90_Tartaruga_Mundo = "abyss",
	C91_Hipocampo_Imperial = "reef",
	C92_Serafim_do_Mar = "celestial",
	C95_Peixe_Vagalume_Real = "abyss",
	C96_Lua_Dourada = "celestial",
	C97_Raia_Tempestade = "tempest",
	C98_Coral_Ancestral_Vivo = "abyss",
	C99_Baleia_Fantasma = "tempest",
	C100_Aurora_Boreal_Viva = "abyss",
	C101_Rena_do_Mar = "festival",
	C102_Peixe_Arvore_de_Natal = "festival",
	C103_Boneco_de_Gelo_Marinho = "festival",
	C104_Polvo_Presente = "festival",
	C105_Estrela_do_Natal = "festival",
	C106_Rei_do_Gelo_Natalino = "festival",
} :: { [string]: string }

-- Income goals: best CONFIRMED tank income reached (cpm). Claimed once by id, kept forever.
-- Thresholds are the plan's 0.5/1/2/4/8/15 coins/s scaled x0.2 and shown per minute.
-- Cosmetic ids are proposals until Antigravity confirms the decoration catalog.
Aquarium.INCOME_GOALS = {
	{ id = "income_1", cpm = 1000, cosmetic = "aqdeco_plaque" },
	{ id = "income_2", cpm = 2500, cosmetic = "aqdeco_lamp" },
	{ id = "income_3", cpm = 6000, cosmetic = "aqdeco_coral" },
	{ id = "income_4", cpm = 12000, cosmetic = "aqdeco_fountain" },
	{ id = "income_5", cpm = 25000, cosmetic = "aqdeco_frame" },
	{ id = "income_6", cpm = 50000, cosmetic = "aqdeco_trophy" },
} :: { { id: string, cpm: number, cosmetic: string } }

-- Session goals: confirmed actions only (never auto-fish). A quick return inside
-- SESSION_REENTRY_SECONDS keeps the same session. Coins are capped per UTC day.
--   kind: "catches" | "minigames" (distinct modes) | "discoveries" (new species)
Aquarium.SESSION_GOALS = {
	{ id = "catch3", kind = "catches", target = 3, coins = 40 },
	{ id = "kinds2", kind = "minigames", target = 2, coins = 60 },
	{ id = "discover1", kind = "discoveries", target = 1, coins = 100 },
} :: { { id: string, kind: string, target: number, coins: number } }
Aquarium.SESSION_REENTRY_SECONDS = 600
Aquarium.SESSION_COINS_DAILY_CAP = 600

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

-- Reads a live flag: an explicit boolean attribute on ReplicatedStorage wins; otherwise Studio
-- is on and live follows LIVE_ENABLED. Pass offline = true for the offline flag (default off).
function Aquarium.flag(attribute: string, offline: boolean?): boolean
	local value = game:GetService("ReplicatedStorage"):GetAttribute(attribute)
	if typeof(value) == "boolean" then
		return value
	end
	if offline then
		return false
	end
	return game:GetService("RunService"):IsStudio() or Aquarium.LIVE_ENABLED
end

function Aquarium.incomeGoal(id: string): { id: string, cpm: number, cosmetic: string }?
	for _, goal in Aquarium.INCOME_GOALS do
		if goal.id == id then
			return goal
		end
	end
	return nil
end

function Aquarium.sessionGoal(
	id: string
): { id: string, kind: string, target: number, coins: number }?
	for _, goal in Aquarium.SESSION_GOALS do
		if goal.id == id then
			return goal
		end
	end
	return nil
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
