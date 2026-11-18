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
}

return {}
