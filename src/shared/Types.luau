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

-- Daily gift (Config/Missions.dailyGift). `grantedAt` is the os.time() of the last grant:
-- the client shows the welcome card only if it is recent (granted on this join).
export type Daily = {
	lastDay: number, -- Missions.today() of the last grant
	days: number, -- days visited (cumulative)
	lastGift: number, -- coins granted on lastDay
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
}

return {}
