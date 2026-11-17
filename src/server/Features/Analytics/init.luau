--!strict
-- Thin wrapper over AnalyticsService: onboarding funnel (each step once per profile) and
-- coin sources/sinks. Events only reach the Creator Hub from a published game; in Studio
-- the calls are harmless. Every call is pcall'd so analytics can never break gameplay.

local AnalyticsService = game:GetService("AnalyticsService")

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Analytics = {}
Analytics.order = 15

-- Funnel steps in order; numbers must stay stable once the game is live.
local STEPS: { [string]: { index: number, name: string } } = {
	firstCast = { index = 1, name = "First cast" },
	firstBite = { index = 2, name = "First bite" },
	firstCatch = { index = 3, name = "First catch" },
	firstRare = { index = 4, name = "First rare or better" },
	firstRodBought = { index = 5, name = "First rod bought" },
	firstTraining = { index = 6, name = "First training" },
}
Analytics.STEPS = STEPS

function Analytics.step(player: Player, key: string)
	local step = Analytics.STEPS[key]
	local profile = PlayerData.get(player)
	if not step or not profile or profile.funnel[key] then
		return
	end
	PlayerData.update(player, function(p)
		p.funnel[key] = true
	end)
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step.index, step.name)
	end)
end

-- source = coins in, sink = coins out. `transaction` is a short label like "Catch" or "Rod".
function Analytics.coins(
	player: Player,
	isSource: boolean,
	amount: number,
	transaction: string,
	sku: string?
)
	local profile = PlayerData.get(player)
	if not profile or amount <= 0 then
		return
	end
	pcall(function()
		AnalyticsService:LogEconomyEvent(
			player,
			if isSource
				then Enum.AnalyticsEconomyFlowType.Source
				else Enum.AnalyticsEconomyFlowType.Sink,
			"Coins",
			amount,
			profile.coins,
			if isSource
				then Enum.AnalyticsEconomyTransactionType.Gameplay.Name
				else Enum.AnalyticsEconomyTransactionType.Shop.Name,
			sku or transaction
		)
	end)
end

function Analytics.start() end

return Analytics
