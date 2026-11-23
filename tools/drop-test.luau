--!strict
-- P1 checks for per-creature drop weights and the real "1 in N" odds. Needs the Rojo-synced place,
-- no Play. Run in Studio (Edit) via execute_luau; returns "ALL OK ..." or the first failure.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Creatures = require(Config:WaitForChild("Creatures"))
local Fishing = require(Config:WaitForChild("Fishing"))

local report = {}
local ok, err = pcall(function()
	-- every released creature has a positive weight
	for _, c in Creatures.LIST do
		assert(Creatures.dropWeight(c) > 0, "weight " .. c.id)
	end

	-- pick() follows the weights (500k rolls, deterministic seed)
	local rng = Random.new(7)
	local pool: { Creatures.PoolEntry } = {}
	for _, c in Creatures.ofRarity("Common") do
		if not c.event and not c.season then
			table.insert(pool, { creature = c, weight = Creatures.dropWeight(c) })
		end
	end
	local hits: { [string]: number } = {}
	local total = 0
	local N = 500000
	for _ = 1, N do
		local entry, t = Creatures.pick(pool, rng:NextNumber())
		assert(entry, "empty pick")
		total = t
		hits[entry.creature.id] = (hits[entry.creature.id] or 0) + 1
	end
	for _, entry in pool do
		local expected = entry.weight / total
		local got = (hits[entry.creature.id] or 0) / N
		assert(
			math.abs(got - expected) < 0.004,
			string.format("%s got %.4f expected %.4f", entry.creature.id, got, expected)
		)
	end

	-- edge cases
	local none, zero = Creatures.pick({}, 0.5)
	assert(none == nil and zero == 0, "empty pool")
	local one = Creatures.pick({ { creature = Creatures.LIST[1], weight = 2 } }, 0.999999)
	assert(one and one.creature == Creatures.LIST[1], "single entry")

	-- odds add up: sum of 1/N over a rarity's pool = chance of that rarity
	local weights = Fishing.RARITY_WEIGHTS
	local sumAll = 0
	for _, r in Fishing.RARITY_ORDER do
		sumAll += weights[r] or 0
	end
	for _, rarity in Fishing.RARITY_ORDER do
		local list: { Creatures.PoolEntry } = {}
		local poolTotal = 0
		for _, c in Creatures.ofRarity(rarity) do
			if not c.event and not c.season then
				local w = Creatures.dropWeight(c)
				table.insert(list, { creature = c, weight = w })
				poolTotal += w
			end
		end
		if #list > 0 then
			local sumChance, minN, maxN = 0, math.huge, 0
			for _, entry in list do
				local n = Fishing.oddsOf(weights, rarity, poolTotal, entry.weight)
				assert(n >= 1, "odds " .. entry.creature.id)
				sumChance += 1 / n
				minN, maxN = math.min(minN, n), math.max(maxN, n)
			end
			local expected = (weights[rarity] or 0) / sumAll
			assert(
				math.abs(sumChance - expected) / expected < 0.02,
				string.format("%s sum %.6f expected %.6f", rarity, sumChance, expected)
			)
			table.insert(report, string.format("%s %d: 1/%d..1/%d", rarity, #list, minN, maxN))
		end
	end
	assert(Fishing.oddsOf(weights, "Common", 0, 1) == 0, "no pool, no odds")
end)

return if ok then "ALL OK | " .. table.concat(report, " | ") else "FAIL: " .. tostring(err)
