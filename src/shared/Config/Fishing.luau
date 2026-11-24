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
	-- Mystic (above Legendary): the whole tier is about 1 in 5,000 casts before luck.
	Mystic = 0.02,
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

-- Real "1 in N" of one roll: chance of the rarity (from the weights actually used, luck
-- included) times the creature's share of its pool. `poolTotal` and `weight` are the pool's
-- total weight and this creature's weight in it (Creatures.pick). 0 when it cannot roll.
function Fishing.oddsOf(
	rarityWeights: { [string]: number },
	rarity: string,
	poolTotal: number,
	weight: number
): number
	local total = 0
	for _, r in Fishing.RARITY_ORDER do
		total += rarityWeights[r] or 0
	end
	local rw = rarityWeights[rarity] or 0
	if rw <= 0 or weight <= 0 or poolTotal <= 0 or total <= 0 then
		return 0
	end
	local chance = (rw / total) * (weight / poolTotal)
	return math.max(1, math.floor(1 / chance + 0.5))
end

---------------------------------------------------------------------------------------------
-- Power bar on the cast (docs/PLANO-PESCA-FORCA-ODDS.md §2). Behind the ReplicatedStorage
-- attribute "FishingPower" (off by default). The server owns the clock: the pointer position is
-- a function of server time since aimStart, so the client only reports when it tapped.
---------------------------------------------------------------------------------------------

Fishing.POWER_FLAG = "FishingPower"
Fishing.AIM = {
	fillSeconds = 1.6, -- the gauge fills from 0 to full in this long (progressive, not ping-pong)
	holdSeconds = 0.4, -- stays full this long, then snaps back to empty and fills again
	sweepSeconds = 1.6, -- kept for older readers: same as fillSeconds
	segments = 10, -- "gominhos" (cells) in the vertical gauge
	timeoutSeconds = 3.5, -- no tap: casts in "red"
	-- The cast cutscene (pull-back hold) plays first: the bar starts this long after the press.
	windupSeconds = 0.9,
	maxLagSeconds = 0.2, -- a reported tap time may be at most this much before it arrived
	suspectPurpleShare = 0.6, -- above this share of purple in the last `suspectWindow` casts,
	suspectWindow = 20, -- the client's tap time stops being trusted (server time only)
}

-- Luck per band: factor = 1 + b x (rank - 1), only from Uncommon (rank 2) up, floor 0.2.
Fishing.POWER_BAND_B = {
	red = -0.08,
	yellow = -0.04,
	neutral = 0,
	green = 0.1,
	purple = 0.25,
} :: { [string]: number }

-- With the bar on, every luck source together is capped per rank (Common .. Mystic).
Fishing.LUCK_CAP = { 1, 2.5, 3.5, 4.5, 6, 8 }

-- Band widths by aim level (0..1): red, yellow, neutral, green, purple. Interpolated.
local AIM_ROWS = {
	{ at = 0, w = { 0.24, 0.24, 0.40, 0.12, 0 } },
	{ at = 0.35, w = { 0.18, 0.20, 0.34, 0.28, 0 } },
	{ at = 0.60, w = { 0.12, 0.16, 0.30, 0.36, 0.06 } },
	{ at = 0.85, w = { 0.08, 0.12, 0.24, 0.40, 0.16 } },
	{ at = 1, w = { 0.04, 0.08, 0.20, 0.44, 0.24 } },
}
export type AimSegment = { band: string, from: number, to: number }

function Fishing.powerEnabled(): boolean
	return game:GetService("ReplicatedStorage"):GetAttribute(Fishing.POWER_FLAG) == true
end

-- Aim level 0..1 from training progress (0..1) and the rod's controlBonus (0..0.32).
function Fishing.aimLevel(trainingProgress: number, rodControlBonus: number): number
	local t = math.clamp(if trainingProgress == trainingProgress then trainingProgress else 0, 0, 1)
	local r =
		math.clamp(if rodControlBonus == rodControlBonus then rodControlBonus / 0.32 else 0, 0, 1)
	return math.clamp(0.7 * t + 0.3 * r, 0, 1)
end

local function widths(aim: number): { number }
	local a = math.clamp(aim, 0, 1)
	for i = 1, #AIM_ROWS - 1 do
		local lo, hi = AIM_ROWS[i], AIM_ROWS[i + 1]
		if a <= hi.at then
			local k = (a - lo.at) / (hi.at - lo.at)
			local out = {}
			for j = 1, 5 do
				out[j] = lo.w[j] + (hi.w[j] - lo.w[j]) * k
			end
			return out
		end
	end
	return table.clone(AIM_ROWS[#AIM_ROWS].w)
end

-- Cell order in the gauge, bottom to top: grey (neutral), red, yellow, green, purple.
local CELL_ORDER = { "neutral", "red", "yellow", "green", "purple" }

-- How many of the `segments` cells each band gets at aim level `aim`: the interpolated band
-- widths scaled to the cell count with largest-remainder rounding (always sums to `segments`).
function Fishing.aimCounts(aim: number): { [string]: number }
	local w = widths(aim) -- red, yellow, neutral, green, purple
	local share: { [string]: number } = {
		neutral = w[3],
		red = w[1],
		yellow = w[2],
		green = w[4],
		purple = w[5],
	}
	local n = Fishing.AIM.segments
	local counts: { [string]: number } = {}
	local used = 0
	local remainders: { { band: string, rem: number } } = {}
	for _, band in CELL_ORDER do
		local exact = share[band] * n
		local whole = math.floor(exact + 1e-9)
		counts[band] = whole
		used += whole
		table.insert(remainders, { band = band, rem = exact - whole })
	end
	table.sort(remainders, function(a, b)
		if math.abs(a.rem - b.rem) > 1e-9 then
			return a.rem > b.rem
		end
		return a.band < b.band
	end)
	local i = 1
	while used < n do
		local entry = remainders[((i - 1) % #remainders) + 1]
		counts[entry.band] += 1
		used += 1
		i += 1
	end
	return counts
end

-- Gauge layout: one segment per cell, bottom (0) to top (1), in CELL_ORDER.
function Fishing.aimLayout(aim: number): { AimSegment }
	local counts = Fishing.aimCounts(aim)
	local n = Fishing.AIM.segments
	local out: { AimSegment } = {}
	local cell = 0
	for _, band in CELL_ORDER do
		for _ = 1, counts[band] do
			table.insert(out, { band = band, from = cell / n, to = (cell + 1) / n })
			cell += 1
		end
	end
	return out
end

-- Gauge fill 0..1 after `elapsed` seconds: rises linearly, holds full, snaps back, repeats.
function Fishing.aimPosition(elapsed: number): number
	local fill = Fishing.AIM.fillSeconds
	local cycle = fill + Fishing.AIM.holdSeconds
	local t = math.max(0, if elapsed == elapsed then elapsed else 0) % cycle
	return math.min(1, t / fill)
end

-- Band of the cell the fill is in (the top edge belongs to the top cell).
function Fishing.bandAt(layout: { AimSegment }, position: number): string
	local n = #layout
	if n == 0 then
		return "red"
	end
	local index = math.clamp(math.floor(math.clamp(position, 0, 1) * n) + 1, 1, n)
	return layout[index].band
end

-- Luck factor of a band for a rarity rank (1 = Common .. 6 = Mystic).
function Fishing.powerFactor(band: string, rank: number): number
	if rank < 2 then
		return 1
	end
	local b = Fishing.POWER_BAND_B[band] or 0
	return math.max(0.2, 1 + b * (rank - 1))
end

function Fishing.tierValue(list: { number }, tier: number): number
	return list[math.clamp(tier, 1, #list)]
end

-- Cast spots: in a zone listed here you may only fish standing on its spot (the glowing ring
-- at the end of the hub pier), and the character turns to face `facing` (out to sea) on the
-- press. Zones not listed keep the whole zone. Positions are world space (studs).
export type CastSpot = { center: Vector3, radius: number, facing: Vector3 }
Fishing.CAST_SPOTS = {
	lagoon = { center = Vector3.new(81, 10.1, 8), radius = 5.5, facing = Vector3.new(1, 0, 0) },
} :: { [string]: CastSpot }

-- The spot rule for `zoneId` at `position`: (allowed, spot or nil).
function Fishing.castSpotCheck(zoneId: string, position: Vector3): (boolean, CastSpot?)
	local spot = Fishing.CAST_SPOTS[zoneId]
	if not spot then
		return true, nil
	end
	local flat = (position - spot.center) * Vector3.new(1, 0, 1)
	return flat.Magnitude <= spot.radius, spot
end

return Fishing
