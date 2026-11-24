--!strict
-- Network contract. The server creates every remote inside its feature's start().

export type FishingUpdate = {
	event: string, -- "cast" | "rejected" | "bite" | "caught" | "escaped" | "cancelled"
	castId: number?,
	kind: string?,
	tier: number?,
	rarity: string?,
	creatureId: string?,
	reason: string?,
	weight: number?, -- kg, on "caught"
	value: number?, -- coins earned, on "caught"
	isNew: boolean?, -- first time this creature was caught
	count: number?, -- total caught of this creature, including this one
	variant: string?, -- "" or "Shiny", on "caught"
	isRecord: boolean?, -- heavier than this player's previous best of the species (not on first catch)
	previousBest: number?, -- kg, the beaten record (only when isRecord)
	isGiant: boolean?, -- weight in the top 15% of the species range
	combo: number?, -- consecutive catches including this one
	comboBonus: number?, -- coin multiplier bonus from the combo (0.09 = +9%)
	comboMilestone: number?, -- 3 | 5 | 8 when this catch reached a celebrated streak, on "caught"
	comboLost: number?, -- length of the streak (>= 3) that just ended, on "escaped" / "cancelled"
	eventId: string?, -- ocean event whose bonus applied to this catch ("" or nil = none), on "caught"
	auto: boolean?, -- true when resolved by the server Auto-Fish loop
	variantId: string?, -- "base" | "giant" | "gold" | "both", on "caught" (variant/isGiant stay as they were)
	newVariant: boolean?, -- first time this species+variant combination is caught, on "caught"
	potentialCpm: number?, -- individual aquarium rate of this catch in cpm (no synergy), on "caught"
	rewardCoins: number?, -- same as value, on "caught"
	aquariumVersion: number?, -- aquarium version after this catch, on "caught"
	odds: number?, -- real "1 in N" of this catch incl. the roulette bonus, on "caught"; nil = don't show
	oddsBase: number?, -- "1 in N" of the creature alone (rarity luck x dropWeight share), on "caught"
	-- Power bar (flag FishingPower; docs/PESCA-FORCA-CONTRATO.md):
	aimStart: number?, -- "aim": workspace:GetServerTimeNow() when the pointer left 0
	aimSweep: number?, -- "aim": seconds for the gauge to fill 0 -> 1 (then holds, snaps back, repeats)
	aimHold: number?, -- "aim": seconds the gauge stays full before it snaps back
	aimLevel: number?, -- "aim": 0..1, how trained the aim is (wider green/purple)
	aimLayout: { { band: string, from: number, to: number } }?, -- "aim": bar segments 0..1
	powerBand: string?, -- "cast": "red" | "yellow" | "neutral" | "green" | "purple"
	-- Catch roulette (flag FishingRoulette; docs/PLANO-ROLETA.md), on "caught":
	spins: { { wheel: string, result: string } }?, -- in order; the UI replays them
	sizeMult: number?, -- applied to the weight (weight already final)
	mutation: string?, -- mutation id, nil = none
	coinMult: number?, -- applied to the coins (value already final)
	zoneId: string?, -- fishing zone id ("lagoon" | "coral" | "abyss")
	minLevel: number?, -- minimum PlayerLevel required by the zone (when reason = "levelLocked")
}

export type LeaderboardEntry = {
	rank: number,
	userId: number,
	name: string,
	score: number,
}

export type LeaderboardResult = {
	board: string, -- "Catches" | "Species" | "Level"
	entries: { LeaderboardEntry },
	mine: number, -- the requesting player's own score
}

-- Announcements that are not part of a fishing cast (level-ups, chests, tutorial gifts).
export type AdventureReward = {
	kind: string, -- "level" | "chest" | "tutorial" | "achievement" | "code" | "codeInvalid" | "codeUsed" | "prestige"
	coins: number?,
	level: number?,
	id: string?, -- achievement id
}

export type TrainingUpdate = {
	event: string, -- "ring" | "levelUp" | "stopped" | "dailyBonus" | "power" | "powerMilestone" | "fieldResult" | "islandLocked"
	ringId: number?,
	rings: number?,
	stat: string?,
	level: number?,
	reason: string?,
	bonusXp: number?, -- "dailyBonus": first training of the day
	rewardCoins: number?, -- "levelUp" on every 5th level
	combo: number?, -- "ringResult": consecutive successful rings
	-- Fishing Power v2 (flag TrainingPower; see docs/TREINO-PP-CONTRATO.md):
	power: number?, -- "power" (every second while training) / "powerMilestone": the stat's power
	gain: number?, -- "power": power per second right now; "dailyBonus"/ring: amount added
	milestone: number?, -- "powerMilestone": the power of ten just crossed (1e3, 1e4, ...)
	field: number?, -- "fieldResult": field level after the request
	ok: boolean?, -- "fieldResult"
	requestId: number?, -- "fieldResult": echo of the client's id
	island: number?, -- "islandLocked": island index of the spot
	gate: number?, -- "islandLocked" / "fieldResult" (reason "power"): power sum required
}

local Net = {
	FOLDER = "Remotes",
	CAST_LINE = "CastLine",
	CANCEL_FISHING = "CancelFishing",
	POWER_TAP = "PowerTap", -- client -> server: (castId: number, tapServerTime: number)
	SUBMIT_CATCH = "SubmitCatch",
	FISHING_UPDATE = "FishingUpdate",
	ADVENTURE_REWARD = "AdventureReward",
	REDEEM_CODE = "RedeemCode",
	REQUEST_LEADERBOARD = "RequestLeaderboard",
	LEADERBOARD_RESULT = "LeaderboardResult",
	STOP_TRAINING = "StopTraining",
	TRAINING_RING_RESULT = "TrainingRingResult",
	TRAINING_UPDATE = "TrainingUpdate",
	TRAINING_BUY_FIELD = "TrainingBuyField", -- client -> server: (requestId: number)
	PROFILE_SNAPSHOT = "ProfileSnapshot",
	REQUEST_PROFILE = "RequestProfile",
	BUY_ROD = "BuyRod",
	EQUIP_ROD = "EquipRod",
	SHOP_RESULT = "ShopResult",
	CLAIM_MISSION = "ClaimMission",
	CLAIM_MILESTONE = "ClaimMilestone",
	CLAIM_RESULT = "ClaimResult",
	SKIP_TUTORIAL = "SkipTutorial",
	TUTORIAL_EVENT = "TutorialEvent",
	SAVE_SETTINGS = "SaveSettings",
	REPORT_PERFECT = "ReportPerfect",
	CATCH_ANNOUNCE = "CatchAnnounce",
	DO_PRESTIGE = "DoPrestige",
	SET_AUTO_FISH = "SetAutoFish",
	INSPECT_PLAYER = "InspectPlayer",
	INSPECT_RESULT = "InspectResult",
	AQUARIUM_PREVIEW = "AquariumPreview",
	AQUARIUM_APPLY = "AquariumApply",
	AQUARIUM_BUY_LEVEL = "AquariumBuyLevel",
	AQUARIUM_RESULT = "AquariumResult",
	AQUARIUM_CLAIM_GOAL = "AquariumClaimGoal",
}

-- goalId: "income:<id>" or "session:<id>" (ids in Config/Aquarium). A repeated claim answers
-- ok = true with already = true and grants nothing.
export type AquariumClaimRequest = {
	requestId: string,
	goalId: string,
}

-- Client to server (AquariumPreview / AquariumApply share the shape). `requestId` is unique
-- per request (max 36 chars); repeating one returns the stored result without reapplying.
export type AquariumRequest = {
	requestId: string,
	op: string, -- "place" | "swap" | "remove"
	slot: number,
	creatureId: string?,
	variant: string?,
	expectedVersion: number,
}

export type AquariumBuyRequest = {
	requestId: string,
	levelId: string,
	expectedVersion: number,
}

-- Server to client. The state with the higher `version` always wins.
export type AquariumResult = {
	requestId: string,
	kind: string, -- "preview" | "apply" | "buy" | "claim"
	ok: boolean,
	reason: string?, -- see docs/AQUARIO-CONTRATO.md section 5
	version: number,
	preview: any?, -- Types.AquariumPreview on kind "preview"
	snapshot: any?, -- Types.AquariumSnapshot after "apply"/"buy" or on staleVersion
	needed: number?, -- noCoins: missing coins
	coins: number?, -- buy/claim: balance after
	already: boolean?, -- claim: it had been claimed before
	reward: any?, -- claim: { coins: number?, cosmetic: string? }
}

export type InspectResult = {
	userId: number,
	displayName: string,
	level: number,
	prestige: number,
	species: number,
	catches: number,
	shinies: number,
	discovered: { string },
	bestWeights: { [string]: number },
	shinyCounts: { [string]: number },
}

-- Sent to every player when someone catches a Legendary (or a Shiny Epic+).
export type CatchAnnounce = {
	userId: number,
	displayName: string,
	creatureId: string,
	rarity: string,
	variant: string,
}

export type ClaimResult = {
	ok: boolean,
	kind: string, -- "mission" | "milestone"
	id: string,
	reward: number?,
	reason: string?, -- "notReady" | "claimed" | "unknown"
}

export type ShopResult = {
	ok: boolean,
	action: string, -- "buy" | "equip"
	rodId: string,
	reason: string?, -- "noCoins" | "owned" | "notOwned" | "unknown"
}

return Net
