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

Fishing.RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

-- Test weights only; real drop rates need the economy pass.
Fishing.RARITY_WEIGHTS = {
	Common = 55,
	Uncommon = 27,
	Rare = 12,
	Epic = 5,
	Legendary = 1,
} :: { [string]: number }

Fishing.RARITY_COLORS = {
	Common = Color3.fromRGB(120, 230, 170),
	Uncommon = Color3.fromRGB(80, 200, 255),
	Rare = Color3.fromRGB(190, 120, 255),
	Epic = Color3.fromRGB(255, 100, 220),
	Legendary = Color3.fromRGB(255, 205, 70),
} :: { [string]: Color3 }

-- Reel bar (hold to push the zone right, release and it drifts left).
Fishing.REEL = {
	zoneWidth = { 0.34, 0.3, 0.26, 0.23, 0.2 },
	fishSpeed = { 0.32, 0.42, 0.52, 0.64, 0.78 },
	fishRetarget = { 0.9, 0.75, 0.6, 0.48, 0.38 },
	gain = { 0.3, 0.26, 0.22, 0.18, 0.15 },
	drain = 0.1,
	failRise = { 0.28, 0.3, 0.33, 0.36, 0.4 },
	failRecover = 0.18,
	zoneAccel = 2.4,
	zoneMaxSpeed = 1.1,
}

-- Precision bar: tap when the marker crosses the zone; 3 hits wins, 2 misses loses.
Fishing.PRECISION = {
	hitsNeeded = 3,
	missesAllowed = 2,
	markerSpeed = { 0.55, 0.68, 0.8, 0.92, 1.05 },
	zoneWidth = { 0.24, 0.21, 0.18, 0.16, 0.14 },
}

-- Rhythm rings: tap when the shrinking ring meets the circle.
Fishing.RHYTHM = {
	missesAllowed = 2,
	rings = { 3, 4, 4, 5, 6 },
	shrinkSeconds = { 1.5, 1.35, 1.2, 1.05, 0.95 },
	window = 0.3,
	gapSeconds = 0.35,
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
