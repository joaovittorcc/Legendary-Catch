--!strict
-- Prestige ("Maré Nova") configuration and shared progression helpers.

local Prestige = {
	MIN_COINS = 1_000_000,
	MIN_SPECIES = 60,
	MAX_LEVEL = 10,
	COIN_BONUS_PER_LEVEL = 0.10, -- +10% coins per catch per prestige level
	LUCK_BONUS_PER_LEVEL = 0.04, -- +4% luck per rank above Common per prestige level
	GIFT_COINS_PER_LEVEL = 25_000, -- immediate gift = 25,000 * P
	ATTRIBUTE = "Prestige",
}

function Prestige.coinMultiplier(level: number): number
	local p = math.clamp(math.floor(level), 0, Prestige.MAX_LEVEL)
	return 1 + Prestige.COIN_BONUS_PER_LEVEL * p
end

local LUCK_PER_PRESTIGE = { 0, 0.02, 0.05, 0.10, 0.22, 0.45 }

function Prestige.luckMultiplier(level: number, rank: number): number
	local p = math.clamp(math.floor(level), 0, Prestige.MAX_LEVEL)
	local slope = LUCK_PER_PRESTIGE[rank] or 0
	return 1 + slope * p
end

function Prestige.giftCoins(level: number): number
	local p = math.clamp(math.floor(level), 0, Prestige.MAX_LEVEL)
	return Prestige.GIFT_COINS_PER_LEVEL * p
end

function Prestige.speciesCount(collection: { [string]: any }?): number
	if not collection then
		return 0
	end
	local count = 0
	for _ in collection do
		count += 1
	end
	return count
end

function Prestige.canPrestige(level: number, coins: number, species: number): boolean
	return level < Prestige.MAX_LEVEL
		and coins >= Prestige.MIN_COINS
		and species >= Prestige.MIN_SPECIES
end

return Prestige
