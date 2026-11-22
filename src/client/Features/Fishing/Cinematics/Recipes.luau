--!strict
-- Overlapping cues use seconds from the confirmed catch, independent of frame rate.
export type Cue = { kind: string, at: number, duration: number, count: number, strength: number }
export type Recipe = {
	duration: number,
	entrance: number,
	mysticShot: string?,
	handoff: number?,
	accent: Color3,
	light: Color3,
	cues: { Cue },
}

local function cue(
	kind: string,
	at: number,
	duration: number,
	count: number?,
	strength: number?
): Cue
	return {
		kind = kind,
		at = at,
		duration = duration,
		count = count or 1,
		strength = strength or 1,
	}
end

local recipes: { [string]: Recipe } = {
	C23_Kraken_Trovejante = {
		duration = 8.3,
		entrance = 3.85,
		accent = Color3.fromHex("7670FF"),
		light = Color3.fromHex("B8F8FF"),
		cues = {
			cue("waves", 0, 2.05, 3),
			cue("lightning", 0.25, 1.8, 4),
			cue("shockwave", 1.6, 1.15),
			cue("tear", 1.8, 2.05, 9),
			cue("shake", 2.35, 0.45, 1, 0.55),
			cue("portal", 2.85, 2.7),
			cue("flash", 3.5, 0.65, 1, 0.15),
		},
	},
	C24_Fenix_das_Mares = {
		duration = 8.6,
		entrance = 4.05,
		accent = Color3.fromHex("F26751"),
		light = Color3.fromHex("FFE39A"),
		cues = {
			cue("waves", 0, 1.8, 2),
			cue("eruption", 0.4, 2.45, 12),
			cue("zoom", 0.85, 2.75, 1, 3.2),
			cue("pillar", 1.1, 2.15),
			cue("wings", 2.0, 2.65, 14),
			cue("portal", 3.15, 2.65),
			cue("flash", 3.85, 0.75, 1, 0.12),
		},
	},
	C93_Ouroboros_Cosmico = {
		duration = 16.9,
		entrance = 1.55,
		mysticShot = "orbit",
		handoff = 12.9,
		accent = Color3.fromHex("A861FF"),
		light = Color3.fromHex("F9DFA3"),
		cues = {
			cue("aurora", 0, 6.2, 4),
			cue("orbit", 0.2, 7.35, 12),
			cue("meteors", 1.9, 3.9, 7),
			cue("portal", 5.1, 2.45),
		},
	},
	C94_Mare_Primordial = {
		duration = 16.4,
		entrance = 3.22,
		mysticShot = "tide",
		handoff = 12.4,
		accent = Color3.fromHex("31E8FF"),
		light = Color3.fromHex("FFC552"),
		cues = {
			cue("mist", 1.65, 3.25, 5),
			cue("bubbles", 2.25, 4.9, 14),
			cue("wings", 3.05, 3.15, 12),
			cue("orbit", 4.35, 2.95, 9),
		},
	},
}

return recipes
