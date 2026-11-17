--!strict
-- Robux products. IDs are 0 until João creates them in the Creator Hub
-- (Creator Hub > experience > Monetization > Passes / Developer Products) — a 0 id means
-- "not on sale yet" and the UI must hide the buy button. Never put a fake id here.
-- Fairness rules: no paid random items, no power that makes skill irrelevant.

export type Product = {
	key: string,
	id: number, -- developer product id
	coins: number?, -- coin pack
	boost: string?, -- "luck"
	boostSeconds: number?,
}

export type Pass = {
	key: string,
	id: number, -- game pass id
	coinMultiplier: number?,
}

local PRODUCTS: { Product } = {
	{ key = "coins1k", id = 0, coins = 1000 }, -- TODO: real id
	{ key = "coins6k", id = 0, coins = 6000 }, -- TODO: real id
	{ key = "luckBoost", id = 0, boost = "luck", boostSeconds = 15 * 60 }, -- TODO: real id
}

local PASSES: { Pass } = {
	{ key = "vip", id = 0, coinMultiplier = 1.25 }, -- TODO: real id
}

local Products = {}

Products.PRODUCTS = PRODUCTS
Products.PASSES = PASSES

-- Luck boost: multiplies Rare/Epic/Legendary weights while active.
Products.LUCK_BOOST_MULTIPLIER = 2

function Products.byProductId(id: number): Product?
	if id == 0 then
		return nil
	end
	for _, p in PRODUCTS do
		if p.id == id then
			return p
		end
	end
	return nil
end

function Products.product(key: string): Product?
	for _, p in PRODUCTS do
		if p.key == key then
			return p
		end
	end
	return nil
end

function Products.pass(key: string): Pass?
	for _, p in PASSES do
		if p.key == key then
			return p
		end
	end
	return nil
end

function Products.passAttribute(key: string): string
	return "Pass_" .. key
end

-- Player attribute: os.time() when the luck boost ends (0 = none).
Products.LUCK_BOOST_ATTRIBUTE = "LuckBoostEndsAt"

return Products
