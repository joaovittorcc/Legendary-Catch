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

local Net = {
	FOLDER = "Remotes",
	CAST_LINE = "CastLine",
	CANCEL_FISHING = "CancelFishing",
	SUBMIT_CATCH = "SubmitCatch",
	FISHING_UPDATE = "FishingUpdate",
}

return Net
