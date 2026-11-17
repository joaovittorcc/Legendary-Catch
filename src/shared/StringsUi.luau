--!strict
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PT = {
	dailyGift = "Presente do dia #%d",
	dailyCoins = "+%d moedas",
	photo = "Foto",
	photoHint = "Arraste para girar · Toque, clique ou Esc para sair",
	catchAnnouncement = "%s pescou %s!",
	robux = {
		title = "Loja de Robux",
		workshop = "Voltar à oficina",
		price = "Ver preço em Robux",
		unavailable = "Fora de venda",
		promptFailed = "Não foi possível abrir a compra.",
		coins = "%d moedas",
		coinsDescription = "Moedas para comprar varas na oficina.",
		luck = "Bônus de sorte",
		luckDescription = "Por %d min, multiplica por %g o peso no sorteio de Raros, Épicos e Lendários.",
		luckTimer = "Sorte %02d:%02d",
		vip = "Passe VIP",
		vipBadge = "VIP",
		vipDescription = "+%d%% de moedas por captura e selo VIP.",
		owned = "Adquirido",
	},
	arrival = {
		title = "Legendary Catch",
		play = "Jogar",
		loading = "Preparando a ilha…",
		ready = "Bem-vindo à ilha!",
	},
	tutorial = {
		skip = "Pular",
		earn = "Pesque mais um pouco para comprar a Vara de Coral.",
		steps = {
			goToPier = "Siga a seta até o píer de pesca.",
			cast = "Equipe a vara e toque ou clique para lançar.",
			fight = "Siga a instrução do minigame para fisgar a criatura.",
			collection = "Abra a Coleção para ver sua primeira descoberta.",
			workshop = "Visite a Oficina para comprar a Vara de Coral.",
			training = "Vá à lagoa e comece a treinar.",
		} :: { [string]: string },
		destinations = {
			FishingZone = "Píer de pesca",
			WorkshopSpot = "Oficina",
			TrainingSpot = "Lagoa de treino",
		} :: { [string]: string },
	},
	missions = {
		title = "Desafios diários",
		nav = "Desafios",
		claim = "Resgatar",
		claimed = "Resgatado",
		ongoing = "Em curso",
		complete = "Desafio concluído! Abra Desafios para resgatar.",
		reset = "Renovam em %02d:%02d:%02d",
		reward = "+%d ◆ resgatados!",
		failed = "Não foi possível resgatar agora.",
		rarity = "Capture %d de raridade %s",
		kinds = {
			catch = "Capture %d criaturas",
			earn = "Ganhe %d moedas",
			train = "Treine por %d segundos",
			perfect = "Vença %d minigames sem errar",
		} :: { [string]: string },
	},
	captureReward = "%.2f kg   ·   +%d ◆",
	collectionStats = "%s: %d   ·   %s: %.2f kg",
	coins = "Moedas",
	collection = "Coleção",
	shop = "Oficina",
	settings = "Ajustes",
	close = "Fechar",
	perfect = "PERFEITO!",
	hit = "ACERTOU!",
	miss = "ERROU!",
	undiscovered = "Não descoberta",
	bestWeight = "Maior peso",
	captures = "Capturas",
	loading = "Carregando…",
	buy = "Comprar",
	equip = "Equipar",
	equipped = "Equipada",
	control = "Controle",
	luck = "Sorte",
	skip = "Pular",
	milestones = {
		title = "Marcos da coleção",
		species = "Descubra %d espécies",
		rarity = "Complete a coleção %s",
		missing = "Seu progresso ainda está carregando.",
	},
	shiny = "CINTILANTE",
	shinyCount = "%d cintilante(s)",
	discovery = "NOVA DESCOBERTA",
	reduced = "Reduzir efeitos",
	on = "Sim",
	off = "Não",
	music = "Música",
	effects = "Efeitos",
	shopErrors = {
		noCoins = "Moedas insuficientes",
		owned = "Você já tem essa vara",
		notOwned = "Compre a vara primeiro",
		unknown = "Vara indisponível",
	} :: { [string]: string },
	unavailable = "Indisponível por enquanto",
}

type Labels = typeof(PT)

local EN = {
	dailyGift = "Daily gift #%d",
	dailyCoins = "+%d coins",
	photo = "Photo",
	photoHint = "Drag to orbit · Tap, click or press Esc to exit",
	catchAnnouncement = "%s caught %s!",
	robux = {
		title = "Robux Shop",
		workshop = "Back to Workshop",
		price = "See Robux price",
		unavailable = "Not for sale",
		promptFailed = "Couldn't open the purchase prompt.",
		coins = "%d coins",
		coinsDescription = "Coins to buy rods at the Workshop.",
		luck = "Luck Boost",
		luckDescription = "For %d min, multiplies Rare, Epic and Legendary catch weights by %g.",
		luckTimer = "Luck %02d:%02d",
		vip = "VIP Pass",
		vipBadge = "VIP",
		vipDescription = "+%d%% coins per catch and a VIP badge.",
		owned = "Owned",
	},
	arrival = {
		title = "Legendary Catch",
		play = "Play",
		loading = "Getting the island ready…",
		ready = "Welcome to the island!",
	},
	tutorial = {
		skip = "Skip",
		earn = "Keep fishing to afford the Coral Rod.",
		steps = {
			goToPier = "Follow the arrow to the fishing pier.",
			cast = "Equip your rod, then tap or click to cast.",
			fight = "Follow the minigame instructions to land your catch.",
			collection = "Open Collection to see your first discovery.",
			workshop = "Visit the Workshop to buy the Coral Rod.",
			training = "Go to the lagoon and start training.",
		} :: { [string]: string },
		destinations = {
			FishingZone = "Fishing Pier",
			WorkshopSpot = "Workshop",
			TrainingSpot = "Training Lagoon",
		} :: { [string]: string },
	},
	missions = {
		title = "Daily Challenges",
		nav = "Dailies",
		claim = "Claim",
		claimed = "Claimed",
		ongoing = "In progress",
		complete = "Challenge complete! Open Dailies to claim it.",
		reset = "Reset in %02d:%02d:%02d",
		reward = "Claimed +%d ◆!",
		failed = "Couldn't claim the reward.",
		rarity = "Land %d %s catches",
		kinds = {
			catch = "Catch %d creatures",
			earn = "Earn %d coins",
			train = "Train for %d seconds",
			perfect = "Win %d minigames without a miss",
		} :: { [string]: string },
	},
	captureReward = "%.2f kg   ·   +%d ◆",
	collectionStats = "%s: %d   ·   %s: %.2f kg",
	coins = "Coins",
	collection = "Collection",
	shop = "Workshop",
	settings = "Settings",
	close = "Close",
	perfect = "PERFECT!",
	hit = "HIT!",
	miss = "MISS!",
	undiscovered = "Undiscovered",
	bestWeight = "Best weight",
	captures = "Catches",
	loading = "Loading…",
	buy = "Buy",
	equip = "Equip",
	equipped = "Equipped",
	control = "Control",
	luck = "Luck",
	skip = "Skip",
	milestones = {
		title = "Collection Milestones",
		species = "Discover %d species",
		rarity = "Complete the %s collection",
		missing = "Your progress is still loading.",
	},
	shiny = "SHINY",
	shinyCount = "%d Shiny",
	discovery = "NEW DISCOVERY",
	reduced = "Reduce effects",
	on = "On",
	off = "Off",
	music = "Music",
	effects = "Effects",
	shopErrors = {
		noCoins = "Not enough coins",
		owned = "You already own this rod",
		notOwned = "Buy this rod first",
		unknown = "Rod unavailable",
	} :: { [string]: string },
	unavailable = "Unavailable for now",
}

local function forLocale(locale: string): Labels
	return if string.lower(string.sub(locale, 1, 2)) == "pt" then PT else EN
end

local selected = EN
if RunService:IsClient() then
	local ok, locale = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	local player = Players.LocalPlayer
	selected = forLocale(
		if ok and typeof(locale) == "string" then locale else (player and player.LocaleId or "en")
	)
end

local StringsUi = table.clone(selected) :: any
StringsUi.forLocale = forLocale
return StringsUi :: Labels & { forLocale: (locale: string) -> Labels }
