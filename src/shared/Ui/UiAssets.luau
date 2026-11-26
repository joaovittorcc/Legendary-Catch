--!strict
--[[
	UiAssets.luau
	Central catalog of generated 3D cartoon UI art (art/ui-generated/*.png) with exact
	9-slice coordinates, theme palettes, and safe Luau fallback detection.

	How to activate uploaded images:
	- Upload the PNGs from art/ui-generated/ in Roblox Studio / Creator Dashboard.
	- Replace each "" marked with "-- TROCAR:" by its "rbxassetid://<id>".
	- Until replaced, every Panel.*, Art.*, and control renders its glossy 3D cartoon Luau
	  fallback automatically with zero errors or missing-image warnings.
]]

export type SliceSpec = {
	id: string,
	scaleType: Enum.ScaleType,
	sliceCenter: Rect?,
	sliceScale: number?,
}

export type ThemePalette = {
	name: string,
	top: Color3,
	mid: Color3,
	bot: Color3,
	lip: Color3,
	rim: Color3,
	glow: Color3,
}

export type ButtonPalette = {
	top: Color3,
	mid: Color3,
	bot: Color3,
	lip: Color3,
	rim: Color3,
	pressedTop: Color3,
	pressedMid: Color3,
	pressedBot: Color3,
	textColor: Color3,
}

local UiAssets = {}

UiAssets.OUTLINE = Color3.fromRGB(44, 10, 77) -- #2C0A4D deep plum cartoon outline
UiAssets.OUTLINE_SOFT = Color3.fromRGB(59, 27, 94) -- #3B1B5E
UiAssets.GOLD_TOP = Color3.fromRGB(255, 245, 158)
UiAssets.GOLD_MID = Color3.fromRGB(255, 184, 0)
UiAssets.GOLD_BOT = Color3.fromRGB(201, 106, 0)
UiAssets.CREAM = Color3.fromRGB(255, 248, 230) -- #FFF8E6 warm readable interior
UiAssets.CREAM_CARD = Color3.fromRGB(255, 253, 245)
UiAssets.CREAM_LIP = Color3.fromRGB(235, 212, 165)

-- Official 7 theme palettes matching art/ui-generated/panel_*_{theme}.png
UiAssets.THEMES = {
	cyan = {
		name = "cyan",
		top = Color3.fromRGB(59, 246, 255),
		mid = Color3.fromRGB(0, 178, 255),
		bot = Color3.fromRGB(0, 106, 232),
		lip = Color3.fromRGB(0, 72, 184),
		rim = Color3.fromRGB(196, 252, 255),
		glow = Color3.fromRGB(92, 230, 255),
	},
	orange = {
		name = "orange",
		top = Color3.fromRGB(255, 216, 66),
		mid = Color3.fromRGB(255, 141, 20),
		bot = Color3.fromRGB(222, 73, 0),
		lip = Color3.fromRGB(168, 50, 0),
		rim = Color3.fromRGB(255, 242, 168),
		glow = Color3.fromRGB(255, 190, 77),
	},
	lime = {
		name = "lime",
		top = Color3.fromRGB(149, 255, 74),
		mid = Color3.fromRGB(46, 212, 58),
		bot = Color3.fromRGB(12, 155, 52),
		lip = Color3.fromRGB(7, 110, 38),
		rim = Color3.fromRGB(216, 255, 184),
		glow = Color3.fromRGB(120, 255, 122),
	},
	gold = {
		name = "gold",
		top = Color3.fromRGB(255, 243, 99),
		mid = Color3.fromRGB(255, 193, 10),
		bot = Color3.fromRGB(224, 121, 0),
		lip = Color3.fromRGB(173, 83, 0),
		rim = Color3.fromRGB(255, 251, 194),
		glow = Color3.fromRGB(255, 226, 102),
	},
	purple = {
		name = "purple",
		top = Color3.fromRGB(229, 148, 255),
		mid = Color3.fromRGB(166, 66, 255),
		bot = Color3.fromRGB(106, 26, 214),
		lip = Color3.fromRGB(72, 13, 158),
		rim = Color3.fromRGB(246, 214, 255),
		glow = Color3.fromRGB(214, 140, 255),
	},
	pink = {
		name = "pink",
		top = Color3.fromRGB(255, 140, 201),
		mid = Color3.fromRGB(255, 58, 154),
		bot = Color3.fromRGB(201, 18, 110),
		lip = Color3.fromRGB(145, 10, 79),
		rim = Color3.fromRGB(255, 212, 236),
		glow = Color3.fromRGB(255, 130, 196),
	},
	steel = {
		name = "steel",
		top = Color3.fromRGB(148, 206, 255),
		mid = Color3.fromRGB(71, 138, 232),
		bot = Color3.fromRGB(37, 82, 168),
		lip = Color3.fromRGB(23, 55, 122),
		rim = Color3.fromRGB(214, 238, 255),
		glow = Color3.fromRGB(126, 196, 255),
	},
} :: { [string]: ThemePalette }

-- Official theme per screen ID
UiAssets.PANEL_THEMES = {
	Collection = "cyan",
	Aquarium = "cyan",
	Shop = "orange",
	Missions = "lime",
	Achievements = "gold",
	Milestones = "gold",
	Robux = "gold",
	Prestige = "purple",
	Leaderboard = "pink",
	Settings = "steel",
	TrainingField = "lime",
} :: { [string]: string }

-- 5 glossy candy button palettes + disabled
UiAssets.BUTTONS = {
	green = {
		top = Color3.fromRGB(132, 255, 71),
		mid = Color3.fromRGB(36, 204, 57),
		bot = Color3.fromRGB(11, 143, 44),
		lip = Color3.fromRGB(6, 102, 32),
		rim = Color3.fromRGB(214, 255, 181),
		pressedTop = Color3.fromRGB(92, 224, 49),
		pressedMid = Color3.fromRGB(27, 176, 48),
		pressedBot = Color3.fromRGB(9, 117, 36),
		textColor = Color3.fromRGB(255, 253, 240),
	},
	blue = {
		top = Color3.fromRGB(79, 227, 255),
		mid = Color3.fromRGB(18, 158, 255),
		bot = Color3.fromRGB(0, 92, 214),
		lip = Color3.fromRGB(0, 63, 163),
		rim = Color3.fromRGB(199, 246, 255),
		pressedTop = Color3.fromRGB(46, 199, 240),
		pressedMid = Color3.fromRGB(10, 133, 230),
		pressedBot = Color3.fromRGB(0, 76, 179),
		textColor = Color3.fromRGB(255, 253, 240),
	},
	orange = {
		top = Color3.fromRGB(255, 212, 59),
		mid = Color3.fromRGB(255, 132, 20),
		bot = Color3.fromRGB(217, 69, 0),
		lip = Color3.fromRGB(163, 48, 0),
		rim = Color3.fromRGB(255, 240, 168),
		pressedTop = Color3.fromRGB(240, 182, 36),
		pressedMid = Color3.fromRGB(230, 110, 8),
		pressedBot = Color3.fromRGB(184, 56, 0),
		textColor = Color3.fromRGB(255, 253, 240),
	},
	pink = {
		top = Color3.fromRGB(255, 133, 200),
		mid = Color3.fromRGB(255, 51, 150),
		bot = Color3.fromRGB(196, 16, 107),
		lip = Color3.fromRGB(143, 9, 77),
		rim = Color3.fromRGB(255, 209, 234),
		pressedTop = Color3.fromRGB(235, 102, 176),
		pressedMid = Color3.fromRGB(224, 36, 130),
		pressedBot = Color3.fromRGB(163, 11, 87),
		textColor = Color3.fromRGB(255, 253, 240),
	},
	red = {
		top = Color3.fromRGB(255, 128, 138),
		mid = Color3.fromRGB(255, 43, 75),
		bot = Color3.fromRGB(191, 12, 46),
		lip = Color3.fromRGB(140, 7, 32),
		rim = Color3.fromRGB(255, 209, 214),
		pressedTop = Color3.fromRGB(235, 94, 107),
		pressedMid = Color3.fromRGB(224, 30, 61),
		pressedBot = Color3.fromRGB(158, 8, 36),
		textColor = Color3.fromRGB(255, 253, 240),
	},
	disabled = {
		top = Color3.fromRGB(213, 208, 230),
		mid = Color3.fromRGB(171, 164, 196),
		bot = Color3.fromRGB(135, 127, 163),
		lip = Color3.fromRGB(104, 96, 133),
		rim = Color3.fromRGB(235, 232, 247),
		pressedTop = Color3.fromRGB(196, 190, 214),
		pressedMid = Color3.fromRGB(158, 151, 184),
		pressedBot = Color3.fromRGB(124, 116, 150),
		textColor = Color3.fromRGB(244, 241, 252),
	},
} :: { [string]: ButtonPalette }

-- ============================================================================
-- UPLOADED / PLACEHOLDER ASSET IDS (replace "" with "rbxassetid://<id>")
-- ============================================================================

local PANEL_BODY_SLICE = Rect.new(128, 128, 384, 384)
local PANEL_HEADER_SLICE = Rect.new(96, 48, 416, 80)
local BUTTON_SLICE = Rect.new(72, 48, 184, 80)
local TAB_SLICE = Rect.new(68, 48, 188, 80)
local CARD_SLICE = Rect.new(64, 64, 192, 192)
local RARITY_CARD_SLICE = Rect.new(96, 112, 288, 400)
local PROGRESS_TRACK_SLICE = Rect.new(44, 24, 212, 40)
local PROGRESS_FILL_SLICE = Rect.new(36, 20, 220, 44)
local TOGGLE_SLICE = Rect.new(56, 36, 136, 60)
local SLIDER_TRACK_SLICE = Rect.new(32, 18, 224, 30)
local SLIDER_FILL_SLICE = Rect.new(28, 16, 228, 32)

local function sliceSpec(id: string, rect: Rect, scale: number): SliceSpec
	return {
		id = id,
		scaleType = Enum.ScaleType.Slice,
		sliceCenter = rect,
		sliceScale = scale,
	}
end

local function fitSpec(id: string): SliceSpec
	return {
		id = id,
		scaleType = Enum.ScaleType.Fit,
		sliceCenter = nil,
		sliceScale = nil,
	}
end

-- A.1 — Panel Bodies & Headers
UiAssets.panelBodies = {
	cyan = sliceSpec("", PANEL_BODY_SLICE, 0.52), -- TROCAR: art/ui-generated/panel_body_cyan.png
	orange = sliceSpec("", PANEL_BODY_SLICE, 0.52), -- TROCAR: art/ui-generated/panel_body_orange.png
	lime = sliceSpec("", PANEL_BODY_SLICE, 0.52), -- TROCAR: art/ui-generated/panel_body_lime.png
	gold = sliceSpec("", PANEL_BODY_SLICE, 0.52), -- TROCAR: art/ui-generated/panel_body_gold.png
	purple = sliceSpec("", PANEL_BODY_SLICE, 0.52), -- TROCAR: art/ui-generated/panel_body_purple.png
	pink = sliceSpec("", PANEL_BODY_SLICE, 0.52), -- TROCAR: art/ui-generated/panel_body_pink.png
	steel = sliceSpec("", PANEL_BODY_SLICE, 0.52), -- TROCAR: art/ui-generated/panel_body_steel.png
} :: { [string]: SliceSpec }

UiAssets.panelHeaders = {
	cyan = sliceSpec("", PANEL_HEADER_SLICE, 0.54), -- TROCAR: art/ui-generated/panel_header_cyan.png
	orange = sliceSpec("", PANEL_HEADER_SLICE, 0.54), -- TROCAR: art/ui-generated/panel_header_orange.png
	lime = sliceSpec("", PANEL_HEADER_SLICE, 0.54), -- TROCAR: art/ui-generated/panel_header_lime.png
	gold = sliceSpec("", PANEL_HEADER_SLICE, 0.54), -- TROCAR: art/ui-generated/panel_header_gold.png
	purple = sliceSpec("", PANEL_HEADER_SLICE, 0.54), -- TROCAR: art/ui-generated/panel_header_purple.png
	pink = sliceSpec("", PANEL_HEADER_SLICE, 0.54), -- TROCAR: art/ui-generated/panel_header_pink.png
	steel = sliceSpec("", PANEL_HEADER_SLICE, 0.54), -- TROCAR: art/ui-generated/panel_header_steel.png
} :: { [string]: SliceSpec }

-- A.2 — Plump 9-Slice Buttons (normal / pressed / disabled)
UiAssets.buttons = {
	green_normal = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_green_normal.png
	green_pressed = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_green_pressed.png
	green_disabled = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_green_disabled.png
	blue_normal = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_blue_normal.png
	blue_pressed = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_blue_pressed.png
	blue_disabled = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_blue_disabled.png
	orange_normal = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_orange_normal.png
	orange_pressed = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_orange_pressed.png
	orange_disabled = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_orange_disabled.png
	pink_normal = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_pink_normal.png
	pink_pressed = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_pink_pressed.png
	pink_disabled = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_pink_disabled.png
	red_normal = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_red_normal.png
	red_pressed = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_red_pressed.png
	red_disabled = sliceSpec("", BUTTON_SLICE, 0.52), -- TROCAR: art/ui-generated/btn_red_disabled.png
} :: { [string]: SliceSpec }

-- A.3 — Controls & Components
UiAssets.controls = {
	closeX = fitSpec(""), -- TROCAR: art/ui-generated/btn_close_x.png
	closeXPressed = fitSpec(""), -- TROCAR: art/ui-generated/btn_close_x_pressed.png
	tabActive = sliceSpec("", TAB_SLICE, 0.52), -- TROCAR: art/ui-generated/tab_active.png
	tabInactive = sliceSpec("", TAB_SLICE, 0.52), -- TROCAR: art/ui-generated/tab_inactive.png
	cardNormal = sliceSpec("", CARD_SLICE, 0.48), -- TROCAR: art/ui-generated/card_normal.png
	cardSelected = sliceSpec("", CARD_SLICE, 0.48), -- TROCAR: art/ui-generated/card_selected.png
	cardLocked = sliceSpec("", CARD_SLICE, 0.48), -- TROCAR: art/ui-generated/card_locked.png
	progressTrack = sliceSpec("", PROGRESS_TRACK_SLICE, 0.58), -- TROCAR: art/ui-generated/progress_track.png
	progressFillLime = sliceSpec("", PROGRESS_FILL_SLICE, 0.58), -- TROCAR: art/ui-generated/progress_fill.png
	progressFillGold = sliceSpec("", PROGRESS_FILL_SLICE, 0.58), -- TROCAR: art/ui-generated/progress_fill_gold.png
	progressFillCyan = sliceSpec("", PROGRESS_FILL_SLICE, 0.58), -- TROCAR: art/ui-generated/progress_fill_cyan.png
	toggleOn = sliceSpec("", TOGGLE_SLICE, 0.52), -- TROCAR: art/ui-generated/toggle_on.png
	toggleOff = sliceSpec("", TOGGLE_SLICE, 0.52), -- TROCAR: art/ui-generated/toggle_off.png
	toggleThumb = fitSpec(""), -- TROCAR: art/ui-generated/toggle_thumb.png
	sliderTrack = sliceSpec("", SLIDER_TRACK_SLICE, 0.60), -- TROCAR: art/ui-generated/slider_track.png
	sliderFill = sliceSpec("", SLIDER_FILL_SLICE, 0.60), -- TROCAR: art/ui-generated/slider_fill.png
	sliderThumb = fitSpec(""), -- TROCAR: art/ui-generated/slider_thumb.png
	badgeDot = fitSpec(""), -- TROCAR: art/ui-generated/badge_dot.png
} :: { [string]: SliceSpec }

-- A.5 — Rarity Creature Card Frames
UiAssets.rarityCards = {
	Common = sliceSpec("", RARITY_CARD_SLICE, 0.48), -- TROCAR: art/ui-generated/card_rarity_common.png
	Uncommon = sliceSpec("", RARITY_CARD_SLICE, 0.48), -- TROCAR: art/ui-generated/card_rarity_uncommon.png
	Rare = sliceSpec("", RARITY_CARD_SLICE, 0.48), -- TROCAR: art/ui-generated/card_rarity_rare.png
	Epic = sliceSpec("", RARITY_CARD_SLICE, 0.48), -- TROCAR: art/ui-generated/card_rarity_epic.png
	Legendary = sliceSpec("", RARITY_CARD_SLICE, 0.48), -- TROCAR: art/ui-generated/card_rarity_legendary.png
	Mystic = sliceSpec("", RARITY_CARD_SLICE, 0.48), -- TROCAR: art/ui-generated/card_rarity_mythic.png
} :: { [string]: SliceSpec }

-- A.4 — Cartoon 3D Icons (already-uploaded menu icons from art/hud-v2 can serve as fallback too)
UiAssets.icons = {
	aquarium = "", -- TROCAR: art/ui-generated/icon_aquarium.png
	arrow_right = "", -- TROCAR: art/ui-generated/icon_arrow_right.png
	book = "", -- TROCAR: art/ui-generated/icon_book.png
	check = "", -- TROCAR: art/ui-generated/icon_check.png
	chest = "", -- TROCAR: art/ui-generated/icon_chest.png
	clock = "", -- TROCAR: art/ui-generated/icon_clock.png
	coin = "", -- TROCAR: art/ui-generated/icon_coin.png
	crown = "", -- TROCAR: art/ui-generated/icon_crown.png
	fish = "", -- TROCAR: art/ui-generated/icon_fish.png
	gear = "", -- TROCAR: art/ui-generated/icon_gear.png
	gem = "", -- TROCAR: art/ui-generated/icon_gem.png
	gift = "", -- TROCAR: art/ui-generated/icon_gift.png
	lock = "", -- TROCAR: art/ui-generated/icon_lock.png
	reduce_effects = "", -- TROCAR: art/ui-generated/icon_reduce_effects.png
	rod = "", -- TROCAR: art/ui-generated/icon_rod.png
	sound_off = "", -- TROCAR: art/ui-generated/icon_sound_off.png
	sound_on = "", -- TROCAR: art/ui-generated/icon_sound_on.png
	sparkle = "", -- TROCAR: art/ui-generated/icon_sparkle.png
	star = "", -- TROCAR: art/ui-generated/icon_star.png
	trophy = "", -- TROCAR: art/ui-generated/icon_trophy.png
	wheel = "", -- TROCAR: art/ui-generated/icon_wheel.png
	xp = "", -- TROCAR: art/ui-generated/icon_xp.png
} :: { [string]: string }

-- Existing already-uploaded Roblox menu icons (art/hud-v2/ASSET_IDS.md) so panels get real art immediately!
UiAssets.UPLOADED_NAV_ICONS = {
	Collection = "rbxassetid://101833560701410",
	Shop = "rbxassetid://82809934642642",
	Missions = "rbxassetid://128671791707576",
	Achievements = "rbxassetid://96908080698179",
	Prestige = "rbxassetid://79184483677272",
	Leaderboard = "rbxassetid://83034467342671",
	Settings = "rbxassetid://106598839342643",
} :: { [string]: string }

-- ============================================================================
-- HELPERS
-- ============================================================================

function UiAssets.resolveId(raw: string?): string?
	if typeof(raw) ~= "string" or raw == "" then
		return nil
	end
	local digits = string.match(raw, "rbxassetid://(%d+)")
	if digits and digits ~= "0" then
		return "rbxassetid://" .. digits
	end
	if string.sub(raw, 1, 11) == "rbxasset://" then
		return raw
	end
	return nil
end

function UiAssets.hasSpec(spec: SliceSpec?): boolean
	return spec ~= nil and UiAssets.resolveId(spec.id) ~= nil
end

function UiAssets.applySpec(target: ImageLabel, spec: SliceSpec?): boolean
	if not spec then
		target.Image = ""
		target.Visible = false
		return false
	end
	local resolved = UiAssets.resolveId(spec.id)
	if not resolved then
		target.Image = ""
		target.Visible = false
		return false
	end
	target.Image = resolved
	target.ScaleType = spec.scaleType
	if spec.scaleType == Enum.ScaleType.Slice and spec.sliceCenter then
		target.SliceCenter = spec.sliceCenter
		target.SliceScale = spec.sliceScale or 0.5
	end
	target.Visible = true
	return true
end

function UiAssets.themeForPanel(panelId: string, fallbackAccent: Color3?): ThemePalette
	local mapped = UiAssets.PANEL_THEMES[panelId]
	if mapped and UiAssets.THEMES[mapped] then
		return UiAssets.THEMES[mapped]
	end
	if fallbackAccent then
		return UiAssets.themeFromColor(fallbackAccent)
	end
	return UiAssets.THEMES.cyan
end

function UiAssets.themeFromColor(accent: Color3): ThemePalette
	local h, s, _ = accent:ToHSV()
	if s < 0.24 then
		return UiAssets.THEMES.steel
	end
	if h < 0.09 or h >= 0.94 then
		return UiAssets.THEMES.orange
	elseif h < 0.17 then
		return UiAssets.THEMES.gold
	elseif h < 0.42 then
		return UiAssets.THEMES.lime
	elseif h < 0.58 then
		return UiAssets.THEMES.cyan
	elseif h < 0.70 then
		return UiAssets.THEMES.steel
	elseif h < 0.82 then
		return UiAssets.THEMES.purple
	end
	return UiAssets.THEMES.pink
end

-- Maps any Color3 accent to one of the 5 glossy button asset tones (or "disabled").
function UiAssets.buttonToneFromColor(accent: Color3, disabled: boolean?): string
	if disabled then
		return "disabled"
	end
	local h, s, v = accent:ToHSV()
	if s < 0.22 or (s < 0.32 and v < 0.72) then
		return "disabled"
	end
	if h < 0.04 or h >= 0.94 then
		return "red"
	elseif h < 0.17 then
		return "orange"
	elseif h < 0.44 then
		return "green"
	elseif h < 0.68 then
		return "blue"
	end
	return "pink"
end

function UiAssets.buttonSpec(tone: string, state: string): SliceSpec?
	local key = if tone == "disabled" then "blue_disabled" else tone .. "_" .. state
	return UiAssets.buttons[key]
end

function UiAssets.iconId(key: string): string?
	return UiAssets.resolveId(UiAssets.icons[key])
end

return UiAssets
