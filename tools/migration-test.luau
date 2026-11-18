--!strict
-- Migration & data-safety verification script for PlayerData.
-- Run in Studio Server DataModel during Play via execute_luau:
--   require/loadstring against ReplicatedStorage/ServerScriptService PlayerData.

local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local PlayerData = require(SSS.Server.Features.PlayerData)

local function assertType(cond: boolean, msg: string)
	if not cond then
		error("MIGRATION_ASSERT_FAILED: " .. msg)
	end
end

local function isFinite(n: any): boolean
	return typeof(n) == "number" and n == n and math.abs(n) < math.huge
end

-- 1. v0 ancient profile (missing new stats, daily streak/shield, achievements, redeemed, prestige, etc.)
local v0: { [string]: any } = {
	coins = 420,
	equippedRod = "coral",
	rodsOwned = { "coral" },
	collection = {
		C01_Bolhinha_Azul = { count = 3, bestWeight = 0.5, firstAt = 1700000000 },
	},
	training = {
		Control = { level = 2, xp = 5 },
	},
	stats = {
		catches = 3,
		legendaries = 0,
	},
	tutorial = { step = "collection", done = false },
	missions = { day = 20000 },
	settings = { music = 0.5, sfx = 0.5, reduceEffects = false },
	daily = { lastDay = 20000, days = 1, lastGift = 100, grantedAt = 1700000000 },
}

assertType(PlayerData.reconcileProfile(v0) == nil, "v0 reconcile returned error")
assertType(v0.coins == 420, "v0 coins preserved")
assertType(
	table.find(v0.rodsOwned, "starter") ~= nil and table.find(v0.rodsOwned, "coral") ~= nil,
	"v0 rodsOwned starter+coral"
)
assertType(v0.equippedRod == "coral", "v0 equippedRod preserved")
assertType(
	v0.training.Control.level == 2 and v0.training.Instinct.level == 0,
	"v0 training migrated"
)
assertType(
	v0.stats.level == 1
		and v0.stats.levelXp == 0
		and v0.stats.bestCombo == 0
		and v0.stats.trainDay == 0
		and v0.stats.suspicious == 0,
	"v0 stats defaults"
)
assertType(typeof(v0.missions.list) == "table", "v0 missions.list created")
assertType(
	typeof(v0.milestones) == "table"
		and typeof(v0.achievements) == "table"
		and typeof(v0.redeemed) == "table",
	"v0 tables created"
)
assertType(v0.prestige == 0, "v0 prestige default 0")
assertType(
	v0.daily.streak == 0
		and v0.daily.shieldUsedAt == 0
		and v0.daily.shieldProtected == false
		and v0.daily.lastChest == 0,
	"v0 daily streak defaults"
)
assertType(v0.collection.C01_Bolhinha_Azul.shiny == 0, "v0 collection.shiny default 0")

-- 2. v-mid intermediate profile (some new fields, partial daily/stats, invalid equippedRod)
local vMid: { [string]: any } = {
	version = 1,
	coins = 5000,
	equippedRod = "nonexistent_rod",
	rodsOwned = { "starter", "astral" },
	collection = {
		C10_Garopa_Rubi = { count = 2, bestWeight = 4.2, firstAt = 1700001000, shiny = 1 },
	},
	training = { Control = { level = 5, xp = 10 }, Instinct = { level = 3, xp = 4 } },
	stats = { catches = 50, legendaries = 2, level = 6, levelXp = 12 },
	tutorial = { step = "done", done = true },
	missions = {
		day = 20005,
		list = {
			{
				id = "m1",
				kind = "catch:any",
				target = 5,
				progress = 2,
				reward = 50,
				claimed = false,
			},
		},
	},
	achievements = { firstCatch = 1700000100 },
	prestige = 2,
	daily = { lastDay = 20005, days = 4, streak = 3 },
}

assertType(PlayerData.reconcileProfile(vMid) == nil, "vMid reconcile returned error")
assertType(vMid.equippedRod == "starter", "vMid invalid equippedRod resets to starter")
assertType(
	vMid.prestige == 2 and vMid.achievements.firstCatch == 1700000100,
	"vMid kept prestige+achievements"
)
assertType(
	vMid.stats.level == 6 and vMid.stats.bestCombo == 0 and vMid.stats.suspicious == 0,
	"vMid stats partial merge"
)
assertType(
	vMid.daily.streak == 3 and vMid.daily.shieldUsedAt == 0 and vMid.daily.lastChest == 0,
	"vMid daily partial merge"
)
assertType(
	typeof(vMid.redeemed) == "table" and typeof(vMid.funnel) == "table",
	"vMid missing maps created"
)

-- 3. Corrupt NaN/out-of-bounds profile sanitization
local vCorrupt: { [string]: any } = {
	coins = 0 / 0,
	stats = { level = 0, catches = -5 },
	settings = { music = 99, sfx = -3 },
	collection = {
		C02_Sardinha_Solar = { catches = 2 },
	},
}
assertType(PlayerData.reconcileProfile(vCorrupt) == nil, "vCorrupt reconcile returned error")
assertType(isFinite(vCorrupt.coins) and vCorrupt.coins == 0, "vCorrupt NaN coins sanitized")
assertType(vCorrupt.stats.level == 1 and vCorrupt.stats.catches == 0, "vCorrupt stats clamped")
assertType(vCorrupt.settings.music == 1 and vCorrupt.settings.sfx == 0, "vCorrupt settings clamped")
assertType(
	vCorrupt.collection.C02_Sardinha_Solar.count == 2,
	"vCorrupt legacy catches field normalized"
)

-- 4. Future schema rejection (must NOT overwrite)
local vFuture: { [string]: any } = { version = 99, coins = 999 }
assertType(PlayerData.reconcileProfile(vFuture) ~= nil, "vFuture must reject")

-- 5. Snapshot deep-clone isolation
local snap = PlayerData.buildSnapshot(v0 :: any)
snap.collection.C01_Bolhinha_Azul.count = 999
snap.training.Control.level = 99
snap.stats.catches = 999
assertType(v0.collection.C01_Bolhinha_Azul.count == 3, "snapshot collection mutated live profile")
assertType(v0.training.Control.level == 2, "snapshot training mutated live profile")
assertType(v0.stats.catches == 3, "snapshot stats mutated live profile")

return {
	ok = true,
	v0Coins = v0.coins,
	v0Prestige = v0.prestige,
	vMidRod = vMid.equippedRod,
	vMidStreak = vMid.daily.streak,
	vCorruptCoins = vCorrupt.coins,
	livePlayer = Players:GetPlayers()[1] and Players:GetPlayers()[1].Name,
}
