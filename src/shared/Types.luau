--!strict
-- Shared data shapes (server profile, client snapshot). Fields are additive only:
-- new fields go to the profile template with a default, never rename or retype.

export type CollectionEntry = {
	count: number,
	bestWeight: number,
	firstAt: number, -- os.time() of the first catch
}

export type TrainingStat = {
	level: number,
	xp: number,
}

export type Stats = {
	catches: number,
	legendaries: number,
}

export type Snapshot = {
	coins: number,
	equippedRod: string,
	rodsOwned: { string },
	collection: { [string]: CollectionEntry },
	training: { [string]: TrainingStat },
	stats: Stats,
}

return {}
