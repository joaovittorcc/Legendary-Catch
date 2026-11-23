--!strict
-- Catch roulette (docs/PLANO-ROLETA.md). After every catch the SERVER spins a chain of wheels
-- that can grow the creature (size), shrink it (worse), give a mutation, spin again or do
-- nothing. The client only animates the recorded spins. Behind the ReplicatedStorage
-- attribute "FishingRoulette" (off by default). Economy sim: node tools/roulette-sim.js
-- (keep the tables in sync with it): about x1.18 coins per catch on average.

local Roulette = {}

Roulette.FLAG = "FishingRoulette"
Roulette.MAX_AGAIN = 3 -- at most 3 "spin again" in a row
Roulette.AGAIN_NOTHING_BONUS = 25 -- each re-spin adds this much weight to "nothing"
Roulette.SIZE_VALUE_EXP = 0.5 -- coins grow with sqrt(size): x100 size = x10 coins

export type Entry = { id: string, weight: number, mult: number }

-- Main wheel. `mult` is unused here (the sub-wheels decide).
Roulette.MAIN = {
	{ id = "nothing", weight = 50, mult = 1 },
	{ id = "worse", weight = 20, mult = 1 },
	{ id = "size", weight = 18, mult = 1 },
	{ id = "again", weight = 8, mult = 1 },
	{ id = "mutation", weight = 4, mult = 1 },
} :: { Entry }

-- Size: multiplies the weight in kg.
Roulette.SIZE = {
	{ id = "x2", weight = 62, mult = 2 },
	{ id = "x3", weight = 20, mult = 3 },
	{ id = "x5", weight = 10, mult = 5 },
	{ id = "x10", weight = 5, mult = 10 },
	{ id = "x25", weight = 2, mult = 25 },
	{ id = "x50", weight = 0.8, mult = 50 },
	{ id = "x100", weight = 0.2, mult = 100 },
} :: { Entry }

-- Worse: shrinks the weight.
Roulette.WORSE = {
	{ id = "x0.8", weight = 50, mult = 0.8 },
	{ id = "x0.6", weight = 35, mult = 0.6 },
	{ id = "x0.4", weight = 15, mult = 0.4 },
} :: { Entry }

-- Mutations, most common first: `mult` multiplies the coins.
Roulette.MUTATIONS = {
	{ id = "neon", weight = 40, mult = 1.5 },
	{ id = "frost", weight = 24, mult = 2 },
	{ id = "magma", weight = 15, mult = 2.5 },
	{ id = "storm", weight = 10, mult = 3 },
	{ id = "rainbow", weight = 7, mult = 5 },
	{ id = "diamond", weight = 3, mult = 10 },
	{ id = "cosmic", weight = 1, mult = 25 },
} :: { Entry }

-- Display colours per card id (UI may restyle).
Roulette.COLORS = {
	nothing = Color3.fromRGB(120, 128, 150),
	worse = Color3.fromRGB(240, 80, 90),
	size = Color3.fromRGB(70, 170, 255),
	again = Color3.fromRGB(255, 205, 60),
	mutation = Color3.fromRGB(196, 104, 255),
	neon = Color3.fromRGB(150, 255, 90),
	frost = Color3.fromRGB(150, 225, 255),
	magma = Color3.fromRGB(255, 120, 40),
	storm = Color3.fromRGB(150, 90, 255),
	rainbow = Color3.fromRGB(255, 110, 200),
	diamond = Color3.fromRGB(200, 250, 255),
	cosmic = Color3.fromRGB(40, 20, 80),
} :: { [string]: Color3 }

export type Spin = { wheel: string, result: string }
export type Outcome = {
	spins: { Spin },
	sizeMult: number,
	mutation: string?,
	coinMult: number,
}

function Roulette.enabled(): boolean
	return game:GetService("ReplicatedStorage"):GetAttribute(Roulette.FLAG) == true
end

-- Weighted pick with `roll` in [0, 1).
function Roulette.pick(list: { Entry }, roll: number, weightOf: ((Entry) -> number)?): Entry
	local total = 0
	for _, e in list do
		total += if weightOf then weightOf(e) else e.weight
	end
	local left = math.clamp(roll, 0, 1) * total
	for _, e in list do
		left -= if weightOf then weightOf(e) else e.weight
		if left < 0 then
			return e
		end
	end
	return list[#list]
end

function Roulette.mutation(id: string?): Entry?
	if not id then
		return nil
	end
	for _, e in Roulette.MUTATIONS do
		if e.id == id then
			return e
		end
	end
	return nil
end

-- Rank of a mutation (1 = Neon .. 7 = Cosmic), 0 for none. Used for "best mutation".
function Roulette.mutationRank(id: string?): number
	for i, e in Roulette.MUTATIONS do
		if e.id == id then
			return i
		end
	end
	return 0
end

-- Spins the whole chain. `nextRoll` returns numbers in [0, 1) (server: Random:NextNumber).
function Roulette.spin(nextRoll: () -> number): Outcome
	local spins: { Spin } = {}
	local size = 1
	local mutation: string? = nil
	local again = 0
	while true do
		local main = Roulette.pick(Roulette.MAIN, nextRoll(), function(e)
			if e.id == "nothing" then
				return e.weight + again * Roulette.AGAIN_NOTHING_BONUS
			elseif e.id == "again" and again >= Roulette.MAX_AGAIN then
				return 0
			end
			return e.weight
		end)
		table.insert(spins, { wheel = "main", result = main.id })
		if main.id == "again" then
			again += 1
			continue
		end
		if main.id == "size" then
			local s = Roulette.pick(Roulette.SIZE, nextRoll())
			table.insert(spins, { wheel = "size", result = s.id })
			size *= s.mult
		elseif main.id == "worse" then
			local w = Roulette.pick(Roulette.WORSE, nextRoll())
			table.insert(spins, { wheel = "worse", result = w.id })
			size *= w.mult
		elseif main.id == "mutation" then
			local m = Roulette.pick(Roulette.MUTATIONS, nextRoll())
			table.insert(spins, { wheel = "mutation", result = m.id })
			mutation = m.id
		end
		break
	end
	local mut = Roulette.mutation(mutation)
	return {
		spins = spins,
		sizeMult = size,
		mutation = mutation,
		coinMult = (size ^ Roulette.SIZE_VALUE_EXP) * (if mut then mut.mult else 1),
	}
end

-- The table of a wheel name (for the UI to draw the cards).
function Roulette.wheel(name: string): { Entry }
	if name == "size" then
		return Roulette.SIZE
	elseif name == "worse" then
		return Roulette.WORSE
	elseif name == "mutation" then
		return Roulette.MUTATIONS
	end
	return Roulette.MAIN
end

return Roulette
