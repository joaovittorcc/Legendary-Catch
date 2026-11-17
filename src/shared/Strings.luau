--!strict
-- UI text (PT-BR for the test build; EN goes in a sibling table later).

local Strings = {
	rarity = {
		Common = "Comum",
		Uncommon = "Incomum",
		Rare = "Raro",
		Epic = "Épico",
		Legendary = "Lendário",
	} :: { [string]: string },
	hint = {
		Common = "Fisgou algo...",
		Uncommon = "Algo diferente...",
		Rare = "Algo raro!",
		Epic = "ALGO ÉPICO!",
		Legendary = "LENDÁRIO...",
	} :: { [string]: string },
	creatureName = {
		C01_Bolhinha_Azul = "Bolhinha Azul",
		C02_Sardinha_Solar = "Sardinha Solar",
		C03_Siri_Pipoca = "Siri Pipoca",
		C04_Baiacu_Nuvem = "Baiacu Nuvem",
		C05_Medusinha_Estelar = "Medusinha Estelar",
		C06_Cavalo_Marinho_Coral = "Cavalo-Marinho Coral",
		C07_Arraia_Prisma = "Arraia Prisma",
		C08_Enguia_Trovao = "Enguia Trovão",
		C09_Guardiao_Cristal = "Guardião de Cristal",
		C10_Leviata_Astral = "Leviatã Astral",
	} :: { [string]: string },
	instructions = {
		reel = "Segure para manter o peixe na zona",
		precision = "Toque quando o marcador estiver na zona",
		rhythm = "Toque quando o anel fechar no círculo",
	} :: { [string]: string },
	stat = {
		Control = "Controle",
		Instinct = "Instinto",
	} :: { [string]: string },
	statHelp = {
		Control = "Minigames mais fáceis",
		Instinct = "Mais sorte com raros",
	} :: { [string]: string },
	trainAction = "Treinar",
	trainingSpot = "Lagoa de Treino",
	training = "Treinando",
	level = "Nível",
	stop = "Parar",
	levelUp = "subiu para o nível",
	ringHint = "Bônus de treino!",
	ringBonus = "Bônus!",
	maxLevel = "Nível máximo",
	escaped = "Escapou!",
	notInZone = "Vá até o fim do píer para pescar",
	waiting = "Esperando a fisgada...",
	caught = "Pegou!",
	newRecord = "NOVA DESCOBERTA!",
}

return Strings
