--!strict
-- Pure-logic checks for the aquarium (S1 + S2). Needs the Rojo-synced place, no Play.
-- Run in Studio (Edit) via execute_luau; returns "ALL OK" or the first failure.
-- Uses the REAL modules: ReplicatedStorage.Shared.AquariumState and Config.Aquarium.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local S = require(Shared:WaitForChild("AquariumState"))
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Aquarium"))

local function eq(a: any, b: any, msg: string)
	if a ~= b then
		error(`{msg}: got {tostring(a)} expected {tostring(b)}`)
	end
end

local ok, err = pcall(function()
	-- every catalog creature has a rate and a family
	local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
	for _, c in Creatures.LIST do
		assert(Config.RATES_CPM[c.id], "no rate for " .. c.id)
		assert(Config.FAMILY[c.id], "no family for " .. c.id)
		eq(Config.RATES_CPM[c.id] % 10, 0, "cpm multiple of 10 " .. c.id)
	end

	-- migration idempotence
	local data: { [string]: any } =
		{ collection = { C01_Bolhinha_Azul = { count = 5, shiny = 2 } } }
	S.migrate(data)
	S.sanitize(data.aquarium)
	eq(data.aquarium.owned.C01_Bolhinha_Azul.base, 3, "base")
	eq(data.aquarium.owned.C01_Bolhinha_Azul.gold, 2, "gold")
	data.aquarium.owned.C01_Bolhinha_Azul.base = 99
	S.migrate(data)
	eq(data.aquarium.owned.C01_Bolhinha_Azul.base, 99, "second migrate keeps state")

	-- synergy: two distinct reef species = +5%, same species twice = nothing
	local aq = S.new()
	for _, id in { "C01_Bolhinha_Azul", "C02_Sardinha_Solar", "C03_Siri_Pipoca" } do
		S.addOwned(aq, id, "base")
	end
	S.addOwned(aq, "C01_Bolhinha_Azul", "base")
	local function place(slot: number, id: string)
		local plan = S.plan(
			aq,
			{
				op = "place",
				slot = slot,
				creatureId = id,
				variant = "base",
				expectedVersion = aq.version,
			}
		)
		assert(plan.ok, plan.reason)
		S.apply(aq, plan)
	end
	place(1, "C01_Bolhinha_Azul")
	place(2, "C01_Bolhinha_Azul")
	eq((S.rates(aq)), 360, "same species twice: no bonus")
	eq(#S.activeFamilies(aq), 0, "no active family")
	place(3, "C02_Sardinha_Solar")
	local total = S.rates(aq)
	eq(total, (180 + 180 + 230) * 105 // 100 - 0, "two species +5% (per slot rounding aside)")
	S.recordBest(aq)
	eq(aq.bestCpm, total, "best recorded")

	-- preview reports gained/lost families
	local swapPlan = S.plan(aq, { op = "remove", slot = 3, expectedVersion = aq.version })
	assert(swapPlan.ok, "remove plan")
	local pv = S.preview(aq, swapPlan)
	eq(#pv.synergiesLost, 1, "lost a family")

	-- goals: claim once, cosmetic granted, repeat is idempotent
	aq.bestCpm = 1000
	local first = S.claim(aq, "income:income_1", 20000)
	eq(first.ok, true, "claim ok")
	eq(aq.cosmetics.aqdeco_plaque, true, "cosmetic")
	eq(S.claim(aq, "income:income_1", 20000).already, true, "repeat claim")
	eq(S.claim(aq, "income:income_2", 20000).reason, "notReady", "not reached")

	-- session goals: progress, claim, daily cap
	S.beginSession(aq, 1000)
	S.recordCatch(aq, "reel", true, 1001)
	S.recordCatch(aq, "precision", false, 1002)
	S.recordCatch(aq, "reel", false, 1003)
	local c1 = S.claim(aq, "session:catch3", 20000)
	eq(c1.coins, 40, "catch3 pays")
	eq(S.claim(aq, "session:kinds2", 20000).coins, 60, "kinds2 pays")
	eq(S.claim(aq, "session:discover1", 20000).coins, 100, "discover1 pays")
	S.beginSession(aq, 1500) -- inside the window: same session
	eq(aq.session.catches, 3, "quick reentry keeps progress")
	S.beginSession(aq, 1500 + Config.SESSION_REENTRY_SECONDS + 10)
	eq(aq.session.catches, 0, "late reentry starts a new session")

	-- exact income
	local a = S.new()
	eq(S.accrue(a, 180, 60000), 1, "1 min Common = 1 coin")
	eq(a.cents, 80, "80 cents left")
end)

return if ok then "ALL OK" else "FAIL: " .. tostring(err)
