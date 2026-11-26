--!strict
-- Roulette logic checks (stacking spin + exact odds). Needs the Rojo-synced place, no Play.
-- Run in Studio (Edit) via execute_luau; returns "ALL OK ..." or the first failure.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local R = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Roulette")
)

local report = {}
local ok, err = pcall(function()
	-- scripted rolls: main size (0.55 is inside "size"), size wheel x10, then nothing
	local function scripted(values: { number }): () -> number
		local i = 0
		return function()
			i += 1
			return values[i] or 0
		end
	end
	-- main weights at spin 1: nothing 50, worse 20, size 18, again 8, mutation 4 (total 100)
	-- nothing [0,.5) worse [.5,.7) size [.7,.88) again [.88,.96) mutation [.96,1)
	local out = R.spin(scripted({ 0.75, 0.9, 0.0 })) -- size, x10 (62+20+10=92 -> .9 lands on x10), nothing
	assert(out.spins[1].result == "size" and out.spins[2].wheel == "size", "size first")
	assert(out.spins[#out.spins].result == "nothing", "ends on nothing")
	assert(out.sizeMult >= 2, "size applied")

	-- main weights at spin 2: nothing 90, worse 20, size 18, again 8, mutation 4 (total 140)
	-- stacking: size then mutation then nothing => both effects kept
	local both = R.spin(scripted({ 0.75, 0.0, 0.99, 0.0, 0.0 }))
	assert(both.sizeMult == 2 and both.mutation ~= nil, "size and mutation stack")
	assert(both.coinMult > math.sqrt(2), "coin includes the mutation")

	-- worse then size multiplies
	local mix = R.spin(scripted({ 0.6, 0.0, 0.82, 0.0, 0.0 }))
	assert(math.abs(mix.sizeMult - 0.8 * 2) < 1e-9, "worse x size stack")

	-- the best mutation is kept
	local muts = R.spin(scripted({ 0.97, 0.0, 0.99, 0.9999, 0.0 })) -- neon then cosmic
	assert(muts.mutation == "cosmic", "best mutation kept")

	-- limit: never more than MAX_MAIN main spins, whatever the rolls
	local forever = R.spin(function()
		return 0.75
	end)
	local mains = 0
	for _, s in forever.spins do
		if s.wheel == "main" then
			mains += 1
		end
	end
	assert(mains <= R.MAX_MAIN, "spin limit")

	-- random runs: always finite, bounded, consistent coinMult
	local rng = Random.new(5)
	local sum, runs = 0, 20000
	for _ = 1, runs do
		local o = R.spin(function()
			return rng:NextNumber()
		end)
		assert(o.coinMult > 0 and o.coinMult < 1e6, "coin sane")
		assert(o.sizeMult > 0 and o.sizeMult <= 100 ^ R.MAX_MAIN, "size sane")
		local mut = R.mutation(o.mutation)
		local expect = (o.sizeMult ^ R.SIZE_VALUE_EXP) * (if mut then mut.mult else 1)
		assert(math.abs(o.coinMult - expect) < 1e-9, "coin matches size and mutation")
		sum += o.coinMult
	end
	table.insert(report, string.format("avg coin x%.3f", sum / runs))

	-- exact tail: monotonic, 1 for no bonus, small for jackpots, combined odds only grow
	assert(R.tailProbability(1) == 1 and R.tailProbability(0.5) == 1, "no bonus = 1")
	local last = 1
	for _, c in { 1.5, 2, 3, 5, 10, 25, 50, 100 } do
		local t = R.tailProbability(c)
		assert(t <= last + 1e-12 and t > 0, "tail monotonic " .. c)
		last = t
	end
	assert(R.tailProbability(25) < 0.002 and R.tailProbability(25) > 0.0003, "x25 about 1 in 700")
	assert(R.combinedOdds(1000, 1) == 1000, "no bonus keeps the odds")
	assert(R.combinedOdds(1000, 0.7) == 1000, "worse keeps the odds")
	assert(R.combinedOdds(1000, 10) > 1000, "bonus makes it rarer")
	assert(R.combinedOdds(3900, 31.6) > 1000000, "legendary + big combo passes 1 in a million")
	assert(R.combinedOdds(0, 10) == 0, "no base odds, no result")
	table.insert(report, "combo 3.9k -> " .. R.combinedOdds(3900, 31.6))

	-- exact outcome odds: every reachable result sums to 1
	local sizes: { [number]: boolean } = { [1] = true }
	for _ = 1, R.MAX_MAIN do
		local nextSizes: { [number]: boolean } = {}
		for s in sizes do
			nextSizes[s] = true
			for _, e in R.SIZE do
				nextSizes[s * e.mult] = true
			end
			for _, e in R.WORSE do
				nextSizes[s * e.mult] = true
			end
		end
		sizes = nextSizes
	end
	local exactSum = 0
	local seen: { [string]: boolean } = {}
	for s in sizes do
		for i = 0, #R.MUTATIONS do
			local m = if i == 0 then nil else R.MUTATIONS[i].id
			local key = string.format("%.6f|%s", s, m or "")
			if not seen[key] then
				seen[key] = true
				exactSum += R.exactProbability(s, m)
			end
		end
	end
	assert(math.abs(exactSum - 1) < 1e-9, "exact outcomes sum to 1, got " .. exactSum)
	assert(R.exactProbability(1, nil) > 0.4, "plain result is the common one")
	assert(R.exactOdds(50, 1, nil, nil) == 50, "plain catch keeps creature odds")
	assert(R.exactOdds(50, 0.8, nil, nil) == 50, "shrunk catch keeps creature odds")
	assert(R.exactOdds(50, 1, nil, 1 / 40) == 2000, "shiny x40")
	local star = R.exactOdds(50, 10, "rainbow", 1 / 40)
	assert(star > R.exactOdds(50, 10, "rainbow", nil), "shiny makes it rarer")
	assert(R.exactOdds(50, 10, nil, nil) > 50, "growth makes it rarer")
	table.insert(report, "star x10 rainbow shiny -> 1 in " .. star)
	table.insert(report, "star x10 -> 1 in " .. R.exactOdds(50, 10, nil, nil))
	table.insert(report, "star neon -> 1 in " .. R.exactOdds(50, 1, "neon", nil))
	table.insert(
		report,
		"legend 3.9k x100 cosmic -> 1 in " .. R.exactOdds(3900, 100, "cosmic", nil)
	)
end)

return if ok then "ALL OK | " .. table.concat(report, " | ") else "FAIL: " .. tostring(err)
