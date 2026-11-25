--!strict
-- Overlapping cues use seconds from the confirmed catch, independent of frame rate.
export type Cue = { kind: string, at: number, duration: number, count: number, strength: number }
export type PoseKey = {
	offset: Vector2,
	yaw: number,
	pitch: number,
	roll: number,
	pullback: number,
}
export type Shot = { settle: number, entry: PoseKey, apex: PoseKey, hold: PoseKey }
export type Recipe = {
	duration: number,
	entrance: number,
	mysticShot: string?,
	shot: Shot?,
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

local function angle(
	x: number,
	y: number,
	yaw: number,
	pitch: number,
	roll: number,
	pullback: number
): PoseKey
	return {
		offset = Vector2.new(x, y),
		yaw = math.rad(yaw),
		pitch = math.rad(pitch),
		roll = math.rad(roll),
		pullback = pullback,
	}
end

local function legendary(
	duration: number,
	entrance: number,
	accent: string,
	light: string,
	cues: { Cue },
	shot: Shot
): Recipe
	return {
		duration = duration,
		entrance = entrance,
		accent = Color3.fromHex(accent),
		light = Color3.fromHex(light),
		cues = cues,
		shot = shot,
	}
end

local recipes: { [string]: Recipe } = {
	C10_Leviata_Astral = legendary(8, 2.75, "725DDD", "CDE8FF", {
		cue("waves", 0, 2.1, 2),
		cue("orbit", 0.42, 3.25, 9),
		cue("meteors", 1.05, 2.9, 6),
		cue("portal", 1.95, 2.9, 1),
		cue("shockwave", 2.6, 1.15, 1),
	}, {
		settle = 1.9,
		entry = angle(-0.19, 0.12, -62, -4, 8, 0.4),
		apex = angle(0.07, -0.07, 34, 7, -4, 0.08),
		hold = angle(0, 0, -10, 0, 0, 0),
	}),
	C23_Kraken_Trovejante = legendary(8.1, 3, "7670FF", "B8F8FF", {
		cue("waves", 0, 2.85, 3),
		cue("lightning", 0.25, 2.44, 4),
		cue("surge", 0.9, 2.65, 3),
		cue("portal", 2.14, 2.95, 1),
		cue("shockwave", 2.71, 1.14, 1),
		cue("tear", 2.95, 1.2, 6),
	}, {
		settle = 1.75,
		entry = angle(0, 0.25, -31, 16, 4, 0.46),
		apex = angle(-0.07, -0.08, 26, -5, -4, 0.06),
		hold = angle(0, 0, -8, 0, 0, 0),
	}),
	C24_Fenix_das_Mares = legendary(8.1, 2.62, "2E9FED", "FFE0A4", {
		cue("waves", 0, 2.2, 2),
		cue("eruption", 0.5, 2.75, 9),
		cue("pillar", 0.98, 2.01, 1),
		cue("portal", 1.73, 2.9, 1),
		cue("wings", 2.8, 2.19, 10),
		cue("mist", 3.09, 2.28, 4),
	}, {
		settle = 2.12,
		entry = angle(-0.2, 0.17, -63, -11, -14, 0.48),
		apex = angle(0.14, -0.18, 40, -7, 13, 0.14),
		hold = angle(0, 0, -12, 0, 0, 0),
	}),
	C30_Tartaruga_Ilha = legendary(7.75, 2.53, "3CB48C", "E7EA9C", {
		cue("mist", 0, 2.55, 4),
		cue("waves", 0.5, 2.7, 2),
		cue("vortex", 1.01, 2.13, 6),
		cue("portal", 1.82, 2.57, 1),
		cue("bubbles", 2.51, 2, 8),
	}, {
		settle = 1.95,
		entry = angle(0.21, 0.09, 65, 8, 0, 0.49),
		apex = angle(-0.15, 0.05, 39, 4, 0, 0.12),
		hold = angle(0, 0, -12, 0, 0, 0),
	}),
	C34_Serpente_Arco_Iris = legendary(7.85, 2.47, "F36DBE", "B8FAF6", {
		cue("waves", 0, 1.9, 2),
		cue("aurora", 0.5, 3.8, 5),
		cue("orbit", 0.95, 3.35, 8),
		cue("portal", 1.72, 2.5, 1),
		cue("shockwave", 2.44, 1.08, 1),
	}, {
		settle = 2.12,
		entry = angle(-0.2, 0.04, -52, -7, -18, 0.42),
		apex = angle(0.13, -0.1, 32, 9, 13, 0.14),
		hold = angle(0, 0, 8, 0, 0, 0),
	}),
	C60_Hidra_das_Profundezas = legendary(8.05, 2.85, "5685DB", "8EFBE6", {
		cue("waves", 0, 3.12, 3),
		cue("mist", 0.26, 2.8, 4),
		cue("portal", 2.02, 2.62, 1),
		cue("eruption", 2.54, 1.45, 7),
		cue("shockwave", 3.48, 1.12, 1),
	}, {
		settle = 1.95,
		entry = angle(0, 0.18, 49, 14, 5, 0.43),
		apex = angle(0, -0.08, -34, -6, -5, 0.12),
		hold = angle(0, 0, -14, 0, 0, 0),
	}),
	C61_Baleia_Celestial = legendary(7.95, 2.56, "665BE1", "F1D899", {
		cue("waves", 0, 2.05, 2),
		cue("orbit", 0.48, 3.16, 11),
		cue("aurora", 0.85, 3.45, 4),
		cue("portal", 1.87, 2.72, 1),
		cue("slowMotion", 2.68, 1.74, 1, 0.22),
	}, {
		settle = 2.21,
		entry = angle(-0.22, 0.11, -73, -6, -9, 0.53),
		apex = angle(0.14, -0.1, -30, 5, 5, 0.15),
		hold = angle(0, 0, -13, 0, 0, 0),
	}),
	C62_Dragao_Dourado = legendary(8.05, 2.67, "C7983B", "FFE7A3", {
		cue("vortex", 0, 2.95, 7),
		cue("lightning", 0.42, 2.22, 3),
		cue("portal", 1.75, 2.62, 1),
		cue("shockwave", 2.44, 1.05, 1),
		cue("meteors", 3.01, 1.91, 7),
	}, {
		settle = 2.05,
		entry = angle(0.2, 0.14, 56, 5, 14, 0.49),
		apex = angle(-0.15, -0.16, -38, -8, -15, 0.14),
		hold = angle(0, 0, -10, 0, 0, 0),
	}),
	C63_Grifo_Marinho = legendary(7.82, 2.43, "4DAAB9", "FFDB9B", {
		cue("waves", 0, 2.02, 2),
		cue("mist", 0.32, 2.62, 4),
		cue("portal", 1.64, 2.56, 1),
		cue("eruption", 2.11, 1.72, 7),
		cue("wings", 2.74, 1.79, 9),
	}, {
		settle = 2.07,
		entry = angle(-0.23, 0.13, -76, -4, -10, 0.46),
		apex = angle(0.17, -0.05, 32, -10, 15, 0.12),
		hold = angle(0, 0, -9, 0, 0, 0),
	}),
	C64_Guardiao_Abissal = legendary(7.92, 2.63, "E27C3F", "FFEAC0", {
		cue("waves", 0, 2.36, 2),
		cue("mist", 0.1, 3.15, 5),
		cue("lantern", 0.78, 3.94, 1),
		cue("portal", 1.79, 2.43, 1),
		cue("orbit", 2.79, 2.28, 7),
	}, {
		settle = 1.8,
		entry = angle(0.13, 0.23, 37, 10, 3, 0.44),
		apex = angle(-0.06, -0.055, -22, -4, -3, 0.09),
		hold = angle(0, 0, -15, 0, 0, 0),
	}),
	C88_Rei_Tritao_Colossal = legendary(8.03, 2.65, "328FCC", "F6D684", {
		cue("waves", 0, 2.24, 2),
		cue("pillar", 0.52, 2.63, 1),
		cue("portal", 1.79, 2.7, 1),
		cue("eruption", 2.18, 1.56, 7),
		cue("shockwave", 3.94, 1.08, 1),
	}, {
		settle = 1.88,
		entry = angle(0, 0.24, 55, 8, -2, 0.42),
		apex = angle(0.08, -0.14, -28, -4, 3, 0.1),
		hold = angle(0, 0, -12, 0, 0, 0),
	}),
	C89_Dragao_de_Jade = legendary(7.91, 2.43, "3AB889", "C5F7CB", {
		cue("mist", 0, 2.53, 4),
		cue("vortex", 0.26, 3.12, 7),
		cue("portal", 1.55, 2.72, 1),
		cue("orbit", 2.02, 2.97, 9),
		cue("waves", 3.41, 1.38, 1),
	}, {
		settle = 2.17,
		entry = angle(0.19, 0.16, 68, 13, 15, 0.48),
		apex = angle(-0.12, -0.11, -37, -8, -11, 0.12),
		hold = angle(0, 0, -9, 0, 0, 0),
	}),
	C90_Tartaruga_Mundo = legendary(8.12, 2.65, "88A65A", "D8FFE8", {
		cue("waves", 0, 2.43, 2),
		cue("mist", 0.32, 2.82, 4),
		cue("portal", 1.92, 2.84, 1),
		cue("bubbles", 2.51, 2.98, 8),
		cue("slowMotion", 3.06, 1.5, 1, 0.24),
	}, {
		settle = 2.15,
		entry = angle(-0.17, -0.15, -60, 19, 3, 0.47),
		apex = angle(0.12, 0.065, 38, 9, -5, 0.18),
		hold = angle(0, 0, -14, 0, 0, 0),
	}),
	C91_Hipocampo_Imperial = legendary(7.87, 2.3, "4C8CD3", "FFD78B", {
		cue("waves", 0, 3.06, 3),
		cue("portal", 1.62, 2.49, 1),
		cue("eruption", 2.05, 2.15, 9),
		cue("orbit", 2.88, 1.9, 8),
		cue("shockwave", 3.46, 1.12, 1),
	}, {
		settle = 2.05,
		entry = angle(-0.19, 0.13, -53, -10, -8, 0.4),
		apex = angle(0.12, -0.21, 29, -13, 8, 0.07),
		hold = angle(0, 0, 1, 0, 0, 0),
	}),
	C92_Serafim_do_Mar = legendary(8.1, 2.65, "C195EF", "FFF2CD", {
		cue("vortex", 0, 2.36, 7),
		cue("aurora", 0.42, 3.25, 5),
		cue("portal", 1.88, 2.79, 1),
		cue("wings", 2.44, 2.73, 12),
		cue("orbit", 3.15, 2.57, 9),
	}, {
		settle = 2.14,
		entry = angle(0.12, 0.16, 44, 12, -9, 0.51),
		apex = angle(-0.11, -0.1, -41, -9, 11, 0.14),
		hold = angle(0, 0, -17, 0, 0, 0),
	}),
	C99_Baleia_Fantasma = legendary(7.89, 2.66, "718AB5", "B8F3FF", {
		cue("mist", 0, 3.66, 5),
		cue("waves", 0.55, 2.07, 2),
		cue("bubbles", 1.52, 3.34, 8),
		cue("portal", 1.91, 2.56, 1),
		cue("orbit", 2.65, 2.55, 7),
	}, {
		settle = 2.1,
		entry = angle(0.21, 0.09, 65, 2, 4, 0.53),
		apex = angle(-0.15, -0.04, 27, 3, -6, 0.16),
		hold = angle(0, 0, -11, 0, 0, 0),
	}),
	C100_Aurora_Boreal_Viva = legendary(7.98, 2.54, "55C9B5", "D3B9FF", {
		cue("aurora", 0, 4.86, 5),
		cue("waves", 0.38, 2.21, 2),
		cue("portal", 1.67, 2.55, 1),
		cue("orbit", 2.41, 2.88, 8),
		cue("bubbles", 3.18, 1.88, 7),
	}, {
		settle = 2.19,
		entry = angle(-0.18, 0.15, -62, -6, -14, 0.46),
		apex = angle(0.14, -0.15, 38, 11, 9, 0.11),
		hold = angle(0, 0, -7, 0, 0, 0),
	}),
	C106_Rei_do_Gelo_Natalino = legendary(7.94, 2.59, "63BAED", "F8F3DD", {
		cue("freeze", 0, 3.1, 6),
		cue("mist", 0.61, 2.55, 4),
		cue("portal", 1.74, 2.64, 1),
		cue("shockwave", 2.43, 1.09, 1),
		cue("orbit", 2.79, 2.45, 10),
	}, {
		settle = 1.79,
		entry = angle(0.1, 0.2, 46, 9, 1, 0.37),
		apex = angle(-0.07, -0.095, -27, -5, 1, 0.09),
		hold = angle(0, 0, -12, 0, 0, 0),
	}),
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
