--!strict
-- T1 checks for Fishing Power (Config/Training v2). Needs the Rojo-synced place, no Play.
-- Run in Studio (Edit) via execute_luau; returns "ALL OK" or the first failure.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local T = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Training")
)

local function eq(a: any, b: any, msg: string)
	if a ~= b then
		error(`{msg}: got {tostring(a)} expected {tostring(b)}`)
	end
end

local function near(a: number, b: number, tol: number, msg: string)
	if math.abs(a - b) > tol then
		error(`{msg}: got {a} expected {b}`)
	end
end

local ok, err = pcall(function()
	-- clamp: junk, NaN, inf, negatives, over cap
	eq(T.clampPower(nil), 1, "nil")
	eq(T.clampPower(0 / 0), 1, "nan")
	eq(T.clampPower(-5), 1, "negative")
	eq(T.clampPower(math.huge), T.POWER_CAP, "inf to cap")
	eq(T.clampPower(1e20), T.POWER_CAP, "over cap")

	-- progress and the level scale: same balance at both ends as the old system
	eq(T.progress(1), 0, "p at 1")
	eq(T.progress(T.POWER_CAP), 1, "p at cap")
	near(T.equivalentLevel(1e6), 10, 1e-9, "1M = level 10")
	near(T.luckMultiplier(T.equivalentLevel(T.POWER_CAP), 5), 5.5, 1e-9, "legendary x5.5 at cap")
	near(T.controlEase(T.equivalentLevel(T.POWER_CAP)), 1.3, 1e-9, "ease x1.3 at cap")

	-- migration both ways
	eq(T.powerFromLevel(0, 0), 1, "level 0")
	near(T.powerFromLevel(10, 0), 1e6, 1e-3, "level 10")
	eq(T.powerFromLevel(25, 0), T.POWER_CAP, "level 25")
	assert(T.powerFromLevel(3, 20) > T.powerFromLevel(3, 0), "xp counts")
	assert(T.powerFromLevel(3, 1e9) < T.powerFromLevel(4, 0), "xp never reaches next level")
	local lvl, xp = T.legacyLevel(T.powerFromLevel(7, 0))
	eq(lvl, 7, "legacy level round trip")
	eq(xp, 0, "legacy xp round trip")
	eq((T.legacyLevel(T.POWER_CAP)), 25, "legacy at cap")

	-- gain: grows with the multiplier and with power, and the field matters
	local base = T.gainPerSecond(1, T.multiplier(1, 1, 0))
	near(base, 1 + 8e-6, 1e-9, "base gain")
	assert(T.gainPerSecond(1e9, 1) > T.gainPerSecond(1e6, 1), "compounds")
	assert(T.multiplier(10, 4, 0) == 4000 * 50, "max multiplier")
	near(T.multiplier(1, 1, 4), 2, 1e-9, "prestige 4 = x2")
	eq(T.addPower(T.POWER_CAP - 1, 100), T.POWER_CAP, "add clamps at cap")
	eq(T.addPower(10, 0 / 0), 10, "nan gain ignored")
	eq(T.addPower(10, -5), 10, "negative gain ignored")

	-- field purchase rules
	local okBuy, reason, cost = T.canBuyField(1, 1e3, 1500)
	assert(okBuy and reason == nil and cost == 1500, "buy level 2")
	eq(select(2, T.canBuyField(1, 999, 1e9)), "power", "power gate")
	eq(select(2, T.canBuyField(1, 1e3, 1499)), "coins", "coins gate")
	eq(select(2, T.canBuyField(10, 1e15, 1e12)), "max", "max level")
	eq(T.fieldLevel(0 / 0), 1, "field nan")
	eq(T.fieldLevel(99), 10, "field clamp")
	eq(T.islandAllowed(2, 99999), false, "island 2 locked")
	eq(T.islandAllowed(2, 1e5), true, "island 2 open")

	-- tiers and formatting
	eq(T.tier(999), 1, "tier 1")
	eq(T.tier(1e3), 2, "tier K")
	eq(T.tier(1e6), 3, "tier M")
	eq(T.tier(1e9), 4, "tier B")
	eq(T.tier(1e12), 5, "tier T")
	eq(T.tier(1e13), 6, "tier gold")
	eq(T.tier(T.POWER_CAP), 7, "tier rainbow")
	eq(T.formatPower(999), "999", "plain")
	eq(T.formatPower(1000), "1K", "1K")
	eq(T.formatPower(12345), "12.3K", "12.3K")
	eq(T.formatPower(12345, ","), "12,3K", "PT comma")
	eq(T.formatPower(999950), "1M", "no 1000K")
	eq(T.formatPower(1234567), "1.23M", "1.23M")
	eq(T.formatPower(T.POWER_CAP), "1Qa", "cap")
	eq(T.formatPower(0 / 0), "0", "nan shows 0")
	eq(#T.FIELD, 10, "10 field levels")
	eq(#T.TIER_COLORS, 7, "7 tiers")
end)

return if ok then "ALL OK" else "FAIL: " .. tostring(err)
