--!strict
-- Fishing balance for the first playable test. Every number here is a starting guess,
-- tuned for kids on phones: wide zones, forgiving windows, difficulty rises with tier (1-5).

local Fishing = {}

Fishing.CAST_DISTANCE = 24
Fishing.BITE_DELAY_MIN = 2
Fishing.BITE_DELAY_MAX = 5
Fishing.CAST_COOLDOWN = 1
Fishing.FIGHT_TIMEOUT = 45
Fishing.ZONE_TAG = "FishingZone"

-- Shortest legit fight per minigame; the server refuses faster results.
Fishing.MIN_FIGHT_SECONDS = {
	reel = 2,
	precision = 1.2,
	rhythm = 1.5,
} :: { [string]: number }

Fishing.MINIGAMES = { "reel", "precision", "rhythm" }

-- Shiny ("Cintilante") variant: rare sparkly version of any creature, worth more.
Fishing.SHINY_CHANCE = 1 / 40
Fishing.SHINY_VALUE_MULTIPLIER = 3

Fishing.RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mystic" }

-- Test weights only; real drop rates need the economy pass.
Fishing.RARITY_WEIGHTS = {
	Common = 55,
	Uncommon = 27,
	Rare = 12,
	Epic = 5,
	Legendary = 1,
	-- Mystic (above Legendary): the whole tier is about 1 in 2,500 casts before luck.
	Mystic = 0.04,
} :: { [string]: number }

Fishing.RARITY_COLORS = {
	Common = Color3.fromRGB(120, 230, 170),
	Uncommon = Color3.fromRGB(80, 200, 255),
	Rare = Color3.fromRGB(190, 120, 255),
	Epic = Color3.fromRGB(255, 100, 220),
	Legendary = Color3.fromRGB(255, 205, 70),
	Mystic = Color3.fromRGB(255, 64, 110),
} :: { [string]: Color3 }

-- Reel bar (hold to push the zone right, release and it drifts left).
Fishing.REEL = {
	zoneWidth = { 0.34, 0.3, 0.26, 0.23, 0.2, 0.17 },
	fishSpeed = { 0.32, 0.42, 0.52, 0.64, 0.78, 0.9 },
	fishRetarget = { 0.9, 0.75, 0.6, 0.48, 0.38, 0.32 },
	gain = { 0.3, 0.26, 0.22, 0.18, 0.15, 0.13 },
	drain = 0.1,
	failRise = { 0.28, 0.3, 0.33, 0.36, 0.4, 0.43 },
	failRecover = 0.18,
	zoneAccel = 2.4,
	zoneMaxSpeed = 1.1,
}

-- Precision bar: tap when the marker crosses the zone; 3 hits wins, 2 misses loses.
-- The marker is erratic: it fakes direction changes ("goes, doesn't, comes back"), more
-- often and more randomly at higher tiers. Each hit must happen within decisionSeconds
-- of the previous one (or of the start); waiting too long counts as a miss.
Fishing.PRECISION = {
	hitsNeeded = 3,
	missesAllowed = 2,
	decisionSeconds = 5,
	markerSpeed = { 0.7, 0.85, 1.0, 1.15, 1.3, 1.4 },
	zoneWidth = { 0.22, 0.19, 0.17, 0.15, 0.13, 0.115 },
	-- Chance per second that the marker reverses or fakes a reversal.
	reverseRate = { 0.5, 0.8, 1.1, 1.4, 1.8, 2.1 },
	-- Random speed swing (fraction of markerSpeed) at each change.
	speedJitter = { 0.1, 0.2, 0.3, 0.4, 0.5, 0.55 },
}

-- Rhythm ("osu"): full-screen circles, no background; tap each one as its ring closes.
-- More circles and faster rings the rarer the creature (Legendary: 15, quick but fair).
Fishing.RHYTHM = {
	missesAllowed = 2,
	rings = { 3, 5, 8, 12, 15, 18 },
	shrinkSeconds = { 1.4, 1.2, 1.05, 0.9, 0.78, 0.72 },
	window = 0.28,
	gapSeconds = 0.35, -- old single value, kept until the minigame reads gapByTier
	gapByTier = { 0.45, 0.4, 0.35, 0.3, 0.26, 0.24 },
}

-- Base odds of one specific creature of `rarity` (pool of `poolSize` creatures), as N in
-- "1 in N": no rod, training, event or boost luck. Shown on the reveal card.
function Fishing.baseOdds(rarity: string, poolSize: number): number
	local total = 0
	for _, r in Fishing.RARITY_ORDER do
		total += Fishing.RARITY_WEIGHTS[r] or 0
	end
	local weight = Fishing.RARITY_WEIGHTS[rarity] or 0
	if weight <= 0 or poolSize <= 0 then
		return 0
	end
	return math.floor(total / weight * poolSize + 0.5)
end

function Fishing.tierValue(list: { number }, tier: number): number
	return list[math.clamp(tier, 1, #list)]
end

return Fishing
