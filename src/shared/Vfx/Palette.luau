--!strict
--[[
	Palette.luau
	Suggested Studio path: ReplicatedStorage/Shared/Vfx/Palette
	Rojo path: src/shared/Vfx/Palette.luau

	Integration:
	- Required by VfxKit and all fishing/world/UI FX modules.
	- Provides canonical rarity palettes, fishing charge band colors,
	  power-bar skin tier accents (1..6), and revealStyle palettes
	  ("electric", "cosmic", "magma", "abyss", "celestial", "default").
	- Assumption: "Mystic" rarity is also included as an optional tier above
	  "Legendary" to match the game's 6-rarity catalog; unknown rarities fall back to Common.
]]

export type RarityKey = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mystic"
export type ChargeBand = "Neutral" | "Green" | "Yellow" | "Perfect"
export type RevealStyle = "default" | "electric" | "cosmic" | "magma" | "abyss" | "celestial"

export type RarityTheme = {
	primary: Color3,
	secondary: Color3,
	glow: Color3,
	text: Color3,
	tier: number,
	labelPt: string,
}

export type StyleTheme = {
	primary: Color3,
	secondary: Color3,
	accent: Color3,
	flash: Color3,
	skyTint: Color3,
	particlePreset: string,
	soundKey: string,
}

export type ChargeTierTheme = {
	name: string,
	accent: Color3,
	perfectAccent: Color3,
	motif: "spark" | "ring" | "star" | "crystal" | "feather" | "rune",
}

local Palette = {}

-- Core world identity accents (Legendary Catch stylized candy-adventure palette)
Palette.World = {
	CrystalCyan = Color3.fromRGB(64, 224, 255),
	CrystalBlue = Color3.fromRGB(58, 152, 255),
	BlossomPink = Color3.fromRGB(255, 146, 218),
	BlossomLilac = Color3.fromRGB(196, 128, 255),
	Gold = Color3.fromRGB(255, 206, 68),
	WarmGold = Color3.fromRGB(255, 232, 132),
	WarmWood = Color3.fromRGB(182, 120, 68),
	AmberLantern = Color3.fromRGB(255, 188, 66),
	PureWhite = Color3.fromRGB(255, 255, 255),
	SoftAqua = Color3.fromRGB(140, 246, 255),
}

-- Canonical rarity themes
Palette.Rarities = {
	Common = {
		primary = Color3.fromRGB(0, 200, 170),
		secondary = Color3.fromRGB(128, 244, 222),
		glow = Color3.fromRGB(170, 255, 240),
		text = Color3.fromRGB(196, 255, 244),
		tier = 1,
		labelPt = "Comum",
	},
	Uncommon = {
		primary = Color3.fromRGB(52, 156, 255),
		secondary = Color3.fromRGB(120, 214, 255),
		glow = Color3.fromRGB(168, 232, 255),
		text = Color3.fromRGB(186, 234, 255),
		tier = 2,
		labelPt = "Incomum",
	},
	Rare = {
		primary = Color3.fromRGB(154, 78, 255),
		secondary = Color3.fromRGB(204, 144, 255),
		glow = Color3.fromRGB(222, 180, 255),
		text = Color3.fromRGB(228, 194, 255),
		tier = 3,
		labelPt = "Raro",
	},
	Epic = {
		primary = Color3.fromRGB(255, 76, 176),
		secondary = Color3.fromRGB(255, 154, 218),
		glow = Color3.fromRGB(255, 196, 236),
		text = Color3.fromRGB(255, 204, 238),
		tier = 4,
		labelPt = "Épico",
	},
	Legendary = {
		primary = Color3.fromRGB(255, 198, 42),
		secondary = Color3.fromRGB(255, 236, 126),
		glow = Color3.fromRGB(255, 248, 192),
		text = Color3.fromRGB(255, 242, 166),
		tier = 5,
		labelPt = "Lendário",
	},
	Mystic = {
		primary = Color3.fromRGB(255, 118, 246),
		secondary = Color3.fromRGB(98, 236, 255),
		glow = Color3.fromRGB(255, 242, 168),
		text = Color3.fromRGB(255, 232, 255),
		tier = 5,
		labelPt = "Místico",
	},
} :: { [string]: RarityTheme }

-- The game's own rarity colors (Config.Fishing.RARITY_COLORS) win over the hardcoded
-- ones above, so VFX, UI and the collection always agree. Mystic keeps its custom
-- secondary/glow because it is a two-tone rarity.
do
	local ok, fishing = pcall(function()
		local config = script.Parent.Parent:FindFirstChild("Config")
		local module = config and config:FindFirstChild("Fishing")
		return if module and module:IsA("ModuleScript") then (require :: any)(module) else nil
	end)
	local colors = if ok and fishing then (fishing :: any).RARITY_COLORS else nil
	if colors then
		for name, color in colors :: { [string]: Color3 } do
			local theme = Palette.Rarities[name]
			if theme then
				theme.primary = color
				if name ~= "Mystic" then
					theme.secondary = color:Lerp(Color3.new(1, 1, 1), 0.35)
					theme.glow = color:Lerp(Color3.new(1, 1, 1), 0.6)
					theme.text = color:Lerp(Color3.new(1, 1, 1), 0.75)
				end
			end
		end
	end
end

-- Fishing charge band thresholds & base colors
Palette.ChargeBands = {
	Neutral = Color3.fromRGB(158, 224, 242),
	Green = Color3.fromRGB(68, 232, 142),
	Yellow = Color3.fromRGB(255, 206, 56),
	Perfect = Color3.fromRGB(255, 78, 108),
	PerfectGold = Color3.fromRGB(255, 228, 92),
}

-- 6 power-bar skins unlocked by Fishing Power (tier 1..6)
Palette.ChargeTiers = {
	[1] = {
		name = "Apprentice",
		accent = Color3.fromRGB(118, 234, 255),
		perfectAccent = Color3.fromRGB(255, 216, 84),
		motif = "spark",
	},
	[2] = {
		name = "Tide",
		accent = Color3.fromRGB(64, 210, 255),
		perfectAccent = Color3.fromRGB(255, 184, 72),
		motif = "ring",
	},
	[3] = {
		name = "Coral",
		accent = Color3.fromRGB(255, 128, 184),
		perfectAccent = Color3.fromRGB(255, 224, 96),
		motif = "star",
	},
	[4] = {
		name = "Crystal",
		accent = Color3.fromRGB(108, 174, 255),
		perfectAccent = Color3.fromRGB(186, 248, 255),
		motif = "crystal",
	},
	[5] = {
		name = "Celestial",
		accent = Color3.fromRGB(255, 184, 236),
		perfectAccent = Color3.fromRGB(255, 240, 148),
		motif = "feather",
	},
	[6] = {
		name = "Astral",
		accent = Color3.fromRGB(184, 118, 255),
		perfectAccent = Color3.fromRGB(255, 224, 112),
		motif = "rune",
	},
} :: { [number]: ChargeTierTheme }

-- Reveal styles for CatchRevealFx
Palette.RevealStyles = {
	default = {
		primary = Color3.fromRGB(255, 206, 68),
		secondary = Color3.fromRGB(102, 236, 255),
		accent = Color3.fromRGB(255, 244, 196),
		flash = Color3.fromRGB(255, 248, 220),
		skyTint = Color3.fromRGB(255, 244, 218),
		particlePreset = "stars",
		soundKey = "reveal_legendary",
	},
	electric = {
		primary = Color3.fromRGB(82, 224, 255),
		secondary = Color3.fromRGB(255, 232, 86),
		accent = Color3.fromRGB(236, 252, 255),
		flash = Color3.fromRGB(200, 246, 255),
		skyTint = Color3.fromRGB(178, 226, 255),
		particlePreset = "electric",
		soundKey = "reveal_electric",
	},
	cosmic = {
		primary = Color3.fromRGB(164, 92, 255),
		secondary = Color3.fromRGB(255, 118, 222),
		accent = Color3.fromRGB(116, 238, 255),
		flash = Color3.fromRGB(232, 198, 255),
		skyTint = Color3.fromRGB(196, 170, 255),
		particlePreset = "cosmic",
		soundKey = "reveal_cosmic",
	},
	magma = {
		primary = Color3.fromRGB(255, 108, 42),
		secondary = Color3.fromRGB(255, 206, 62),
		accent = Color3.fromRGB(255, 240, 178),
		flash = Color3.fromRGB(255, 214, 152),
		skyTint = Color3.fromRGB(255, 186, 148),
		particlePreset = "magma",
		soundKey = "reveal_magma",
	},
	abyss = {
		primary = Color3.fromRGB(58, 128, 255),
		secondary = Color3.fromRGB(48, 232, 212),
		accent = Color3.fromRGB(186, 248, 255),
		flash = Color3.fromRGB(168, 226, 255),
		skyTint = Color3.fromRGB(142, 186, 246),
		particlePreset = "abyss",
		soundKey = "reveal_abyss",
	},
	celestial = {
		primary = Color3.fromRGB(255, 216, 102),
		secondary = Color3.fromRGB(255, 168, 226),
		accent = Color3.fromRGB(174, 248, 255),
		flash = Color3.fromRGB(255, 250, 232),
		skyTint = Color3.fromRGB(255, 236, 214),
		particlePreset = "celestial",
		soundKey = "reveal_celestial",
	},
} :: { [string]: StyleTheme }

-- Training attribute themes (Control vs Instinct)
Palette.Training = {
	Control = {
		primary = Color3.fromRGB(64, 224, 255),
		secondary = Color3.fromRGB(176, 248, 255),
		labelPt = "Controle",
	},
	Instinct = {
		primary = Color3.fromRGB(204, 108, 255),
		secondary = Color3.fromRGB(255, 208, 86),
		labelPt = "Instinto",
	},
}

-- Normalize arbitrary rarity string (case-insensitive / PT-BR aliases)
local RARITY_ALIASES: { [string]: string } = {
	common = "Common",
	comum = "Common",
	uncommon = "Uncommon",
	incomum = "Uncommon",
	rare = "Rare",
	raro = "Rare",
	epic = "Epic",
	epico = "Epic",
	["épico"] = "Epic",
	legendary = "Legendary",
	lendario = "Legendary",
	["lendário"] = "Legendary",
	mystic = "Mystic",
	mistico = "Mystic",
	["místico"] = "Mystic",
}

function Palette.getRarity(rarity: string?): RarityTheme
	if typeof(rarity) ~= "string" then
		return Palette.Rarities.Common
	end
	local direct = Palette.Rarities[rarity]
	if direct then
		return direct
	end
	local normalized = RARITY_ALIASES[string.lower(rarity)]
	if normalized and Palette.Rarities[normalized] then
		return Palette.Rarities[normalized]
	end
	return Palette.Rarities.Common
end

function Palette.getRarityColor(rarity: string?): Color3
	return Palette.getRarity(rarity).primary
end

function Palette.getRarityTier(rarity: string?): number
	return Palette.getRarity(rarity).tier
end

function Palette.getStyle(styleName: string?): StyleTheme
	if typeof(styleName) == "string" then
		local key = string.lower(styleName)
		local found = Palette.RevealStyles[key]
		if found then
			return found
		end
	end
	return Palette.RevealStyles.default
end

function Palette.getChargeTier(tier: number?): ChargeTierTheme
	local idx = math.clamp(math.floor((tier or 1) + 0.5), 1, 6)
	return Palette.ChargeTiers[idx] or Palette.ChargeTiers[1]
end

-- Returns the discrete power band for a normalized charge (0..1)
function Palette.bandForCharge(charge: number): ChargeBand
	local c = math.clamp(charge, 0, 1)
	if c >= 0.90 then
		return "Perfect"
	elseif c >= 0.60 then
		return "Yellow"
	elseif c >= 0.25 then
		return "Green"
	end
	return "Neutral"
end

-- Smoothly computes the charge color blending band readability with tier skin accent
function Palette.colorForCharge(charge: number, tier: number?): Color3
	local c = math.clamp(charge, 0, 1)
	local tierTheme = Palette.getChargeTier(tier)
	local tierInfluence = math.clamp(((tier or 1) - 1) / 5, 0, 1) * 0.28

	local baseColor: Color3
	if c < 0.25 then
		local t = c / 0.25
		baseColor = Palette.ChargeBands.Neutral:Lerp(Palette.ChargeBands.Green, t * 0.35)
	elseif c < 0.60 then
		local t = (c - 0.25) / 0.35
		baseColor = Palette.ChargeBands.Green:Lerp(Palette.ChargeBands.Yellow, t)
	elseif c < 0.90 then
		local t = (c - 0.60) / 0.30
		baseColor = Palette.ChargeBands.Yellow:Lerp(Palette.ChargeBands.Perfect, t)
	else
		-- Perfect band: shimmering warm-gold / rainbow-kissed accent
		local t = (c - 0.90) / 0.10
		local perfectMix =
			Palette.ChargeBands.Perfect:Lerp(Palette.ChargeBands.PerfectGold, 0.55 + 0.45 * t)
		return perfectMix:Lerp(tierTheme.perfectAccent, 0.35)
	end

	return baseColor:Lerp(tierTheme.accent, tierInfluence)
end

-- Rainbow cycle helper (used in Perfect charge / Legendary / Mystic accents)
function Palette.rainbowAt(phase: number): Color3
	return Color3.fromHSV(phase % 1, 0.78, 1)
end

-- Build a 2- or 3-stop ColorSequence safely
function Palette.toColorSequence(
	primary: Color3,
	secondary: Color3?,
	tertiary: Color3?
): ColorSequence
	if secondary and tertiary then
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, primary),
			ColorSequenceKeypoint.new(0.5, secondary),
			ColorSequenceKeypoint.new(1, tertiary),
		})
	elseif secondary then
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, primary),
			ColorSequenceKeypoint.new(1, secondary),
		})
	end
	return ColorSequence.new(primary)
end

return Palette
