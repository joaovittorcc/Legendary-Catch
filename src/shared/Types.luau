--!strict
-- Shared data shapes (server profile, client snapshot). Fields are additive only:
-- new fields go to the profile template with a default, never rename or retype.

export type CollectionEntry = {
	count: number,
	bestWeight: number,
	firstAt: number, -- os.time() of the first catch
	shiny: number?, -- shiny variants caught (added 2026-11-17; nil on older entries)
}

export type TrainingStat = {
	level: number,
	xp: number,
}

export type Stats = {
	catches: number,
	legendaries: number,
	level: number,
	levelXp: number,
	bestCombo: number,
	trainDay: number, -- os.time() // 86400 of the last daily training bonus
	suspicious: number?, -- count of suspicious catch submissions (anti-cheat telemetry)
}

export type Tutorial = {
	-- "goToPier" -> "fight" -> "collection" -> "workshop" -> "training" -> "done"
	-- (the client shows "tap to cast" while step is goToPier and the player is at the pier)
	step: string,
	done: boolean,
}

export type Mission = {
	id: string,
	kind: string,
	target: number,
	progress: number,
	reward: number,
	claimed: boolean,
}

export type Missions = {
	day: number,
	list: { Mission },
}

export type Settings = {
	music: number,
	sfx: number,
	reduceEffects: boolean,
}

-- Daily gift (Config/Missions). `grantedAt` is the os.time() of the last grant:
-- the client shows the welcome card only if it is recent (granted on this join).
export type Daily = {
	lastDay: number, -- Missions.today() of the last grant
	days: number, -- days visited (cumulative)
	streak: number, -- consecutive login days (protected once per week by streak shield)
	shieldUsedAt: number, -- Missions.today() when the 1-day grace shield was last consumed (0 = never)
	shieldProtected: boolean, -- true when the latest grant kept the streak alive via shield
	lastChest: number, -- bonus coins from the Day 7 special chest (0 on days 1..6)
	lastGift: number, -- coins granted on lastDay (base streak tier reward)
	grantedAt: number,
}

export type AquariumSession = {
	startedAt: number,
	lastSeen: number, -- os.time(); a return within the reentry window keeps this session
	catches: number,
	kinds: { [string]: boolean }, -- minigame modes won this session
	discoveries: number,
	claimed: { [string]: boolean }, -- session goal ids claimed
}

-- Aquarium (docs/AQUARIO-CONTRATO.md). Profile side: slots keyed by slot number as a string.
export type AquariumProfile = {
	migrated: number, -- migration version applied (idempotence guard)
	level: number,
	version: number, -- +1 on every accepted change (placement, purchase, new catch)
	slots: { [string]: { creatureId: string, variant: string } },
	owned: { [string]: { base: number, giant: number, gold: number, both: number } }, -- TOTAL caught per variant
	bestCpm: number, -- highest confirmed tank income ever (income goals read this)
	claimed: { [string]: boolean }, -- income goal ids already claimed
	cosmetics: { [string]: boolean }, -- decoration ids unlocked by goals
	session: AquariumSession,
	sessionDay: number, -- UTC day of sessionCoins
	sessionCoins: number, -- coins paid by session goals on sessionDay (daily cap)
	exitCpm: number, -- tank rate when the player last left (offline pilot); never retroactive
	exitAt: number, -- os.time() of that exit, 0 = none pending
	offlineLast: { coins: number, seconds: number }, -- last offline payout, for the welcome-back card
	cents: number, -- 0..99 hundredths of a coin not yet paid
	frac: number, -- 0..59999 remainder of cpm*ms/60000 (exact integer carry)
	cursor: number, -- os.time() of the last settlement
}

export type AquariumSlot = {
	index: number,
	occupant: { creatureId: string, variant: string }?,
}

export type AquariumOccupantRate = { creatureId: string, variant: string, cpm: number }

export type AquariumPreview = {
	slot: number,
	current: AquariumOccupantRate?,
	candidate: AquariumOccupantRate?,
	slotBeforeCpm: number,
	slotAfterCpm: number,
	totalBeforeCpm: number,
	totalAfterCpm: number,
	deltaCpm: number,
	synergiesGained: { string },
	synergiesLost: { string },
	usedVersion: number,
}

export type AquariumGoals = {
	income: {
		bestCpm: number,
		list: { { id: string, cpm: number, cosmetic: string, reached: boolean, claimed: boolean } },
		nextId: string?, -- first goal not reached yet
		remainingCpm: number?,
	},
	session: {
		list: {
			{
				id: string,
				kind: string,
				target: number,
				progress: number,
				coins: number,
				claimed: boolean,
			}
		},
		coinsLeftToday: number,
	},
}

export type AquariumSnapshot = {
	status: string, -- "disabled" | "ready"
	paramsVersion: number?,
	levelId: string?,
	level: number?,
	version: number?,
	slots: { AquariumSlot }?,
	inventory: { [string]: { base: number, giant: number, gold: number, both: number } }?, -- AVAILABLE (outside slots)
	totalCpm: number?,
	slotCpm: { number }?, -- index = slot, 0 when empty
	synergies: {
		{
			id: string,
			members: { string },
			bonusPct: number,
			active: boolean,
			count: number, -- distinct species of the family in the tank
			nextAt: number?, -- species needed for the next bonus tier
		}
	}?,
	goals: AquariumGoals?,
	cosmetics: { string }?,
	offline: { coins: number, seconds: number }?, -- present only when an offline payout happened
	fractionCents: number?,
	nextLevel: {
		levelId: string,
		slots: number,
		cost: number,
		requirement: string?,
		canBuy: boolean,
		reason: string?,
	}?,
}

export type Snapshot = {
	coins: number,
	equippedRod: string,
	rodsOwned: { string },
	collection: { [string]: CollectionEntry },
	training: { [string]: TrainingStat },
	stats: Stats,
	tutorial: Tutorial,
	missions: Missions,
	milestones: { [string]: boolean },
	settings: Settings,
	daily: Daily,
	achievements: { [string]: number }, -- id -> os.time() unlocked
	redeemed: { [string]: boolean }, -- promo codes already used
	prestige: number,
	aquarium: AquariumSnapshot?, -- nil = server without the feature (treat as disabled)
}

return {}
