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
}

export type TrainingUpdate = {
	event: string, -- "ring" | "levelUp" | "stopped"
	ringId: number?,
	rings: number?,
	stat: string?,
	level: number?,
	reason: string?,
}

local Net = {
	FOLDER = "Remotes",
	CAST_LINE = "CastLine",
	CANCEL_FISHING = "CancelFishing",
	SUBMIT_CATCH = "SubmitCatch",
	FISHING_UPDATE = "FishingUpdate",
	STOP_TRAINING = "StopTraining",
	TRAINING_RING_RESULT = "TrainingRingResult",
	TRAINING_UPDATE = "TrainingUpdate",
}

return Net
