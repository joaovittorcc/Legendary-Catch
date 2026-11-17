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
