--!strict
-- Catch show (flag FishingRoulette): the whole "what did I catch" sequence on one screen.
--   1. The creature's BLACK SILHOUETTE appears and floats to the top.
--   2. The roulette reels run below it (the spins the SERVER already rolled): every size result
--      really grows or shrinks the silhouette, every mutation tints it and lights a glow, and a
--      chip adds up the effects.
--   3. The reels leave and the "1 in N" counter flashes upward through the tiers (word,
--      colour, rays, confetti) up to the final odds, which already include the roulette bonus
--      (payload `odds`), while the name fills in letter by letter.
-- Tap = speed up. "ReduceEffects" drops blur, flash, shake and confetti but keeps the reels.
--
-- play(update, info) yields until the show ends. Detailed first, optimise later.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RouletteConfig = require(Shared:WaitForChild("Config"):WaitForChild("Roulette"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local UiAssets = require(Shared:WaitForChild("Ui"):WaitForChild("UiAssets"))
local Roulette = require(script.Parent:WaitForChild("Roulette"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))

local CatchShow = {}

export type Update = Roulette.Update & {
	potentialCpm: number?, -- aquarium income of this catch in hundredths of a coin per minute
	variantId: string?, -- "base" | "giant" | "gold" | "both"
	variant: string?, -- "" | "Shiny"
}
export type Info = {
	creatureId: string,
	rarity: string?, -- "Common" .. "Mystic": styles the income number
	odds: number?, -- final "1 in N" (payload `odds`); nil = skip the counter
	short: boolean?, -- true when a long reveal cinematic follows (Legendary/Mystic)
}

local K = Roulette.kit
local player = Players.LocalPlayer
local INK = Theme.ink
local WHITE = Color3.new(1, 1, 1)

-- "1 in N" tiers (same thresholds and look as OddsMoment).
local THRESHOLDS = { 50, 150, 500, 2000, 10000, 50000, math.huge }
local TIER_BG = {
	Color3.fromRGB(32, 196, 168),
	Color3.fromRGB(42, 118, 232),
	Color3.fromRGB(118, 58, 214),
	Color3.fromRGB(226, 58, 168),
	Color3.fromRGB(236, 150, 28),
	Color3.fromRGB(196, 28, 84),
	Color3.fromRGB(14, 8, 34),
}
local TIER_ACCENT = {
	Color3.fromRGB(190, 255, 230),
	Color3.fromRGB(160, 220, 255),
	Color3.fromRGB(220, 180, 255),
	Color3.fromRGB(255, 190, 235),
	Color3.fromRGB(255, 236, 140),
	Color3.fromRGB(255, 150, 120),
	Color3.fromRGB(120, 255, 250),
}
local TIER_TIME = { 1.0, 1.5, 2.1, 2.9, 3.9, 5.0, 7.0 }
local TIER_CONFETTI = { 0, 8, 16, 26, 38, 52, 72 }
local SHORT_CAP = 3.5
local MUTATION_COLORS: { [string]: Color3 } = {
	neon = Color3.fromRGB(150, 255, 90),
	frost = Color3.fromRGB(150, 225, 255),
	magma = Color3.fromRGB(255, 120, 40),
	storm = Color3.fromRGB(170, 110, 255),
	rainbow = Color3.fromRGB(255, 110, 200),
	diamond = Color3.fromRGB(210, 250, 255),
	cosmic = Color3.fromRGB(150, 90, 255),
}

local function tierOf(n: number): number
	for i, limit in THRESHOLDS do
		if n <= limit then
			return i
		end
	end
	return #THRESHOLDS
end

-- 1234567 -> "1.234.567" (PT) / "1,234,567" (EN).
local function grouped(n: number): string
	return Theme.formatInt(math.max(1, math.floor(n + 0.5)))
end

local function partialName(name: string, shown: number): string
	local out = {}
	local count = 0
	for _, code in utf8.codes(name) do
		local ch = utf8.char(code)
		if ch == " " then
			table.insert(out, " ")
		else
			count += 1
			table.insert(out, if count <= shown then ch else "_")
		end
	end
	return table.concat(out)
end

local function letterCount(name: string): number
	local n = 0
	for _, code in utf8.codes(name) do
		if utf8.char(code) ~= " " then
			n += 1
		end
	end
	return n
end

-- Silhouette: the real creature model in a ViewportFrame tinted black.
local function buildSilhouette(parent: Instance, creatureId: string): (ViewportFrame, Model?)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Silhouette"
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromScale(0.5, 0.45)
	vp.Size = UDim2.fromScale(0.52, 0.3)
	vp.BackgroundTransparency = 1
	vp.ImageColor3 = Color3.new(0, 0, 0)
	vp.Ambient = Color3.new(1, 1, 1)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.ZIndex = 6
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1.4
	aspect.Parent = vp
	vp.Parent = parent
	local folder = ReplicatedStorage:FindFirstChild("Creatures")
	local source = folder and folder:FindFirstChild(creatureId)
	if not (source and source:IsA("Model")) then
		return vp, nil
	end
	local model = source:Clone()
	for _, d in model:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	model:PivotTo(CFrame.new())
	model.Parent = vp
	local _, size = model:GetBoundingBox()
	local radius = math.max(size.X, size.Y, size.Z)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame =
		CFrame.lookAt(Vector3.new(radius * 0.25, radius * 0.15, radius * 1.9), Vector3.zero)
	camera.Parent = vp
	vp.CurrentCamera = camera
	return vp, model
end

-- Coins per minute from hundredths: 2100 -> "21", 1850 -> "18,5", 123456 -> "1.234".
local function coinsText(cpm: number): string
	local perMin = cpm / 100
	if perMin >= 100 then
		return grouped(perMin)
	end
	local text = if perMin == math.floor(perMin)
		then tostring(perMin)
		else string.format("%.1f", perMin)
	return (text:gsub("%.", Strings.decimalSep))
end

local NUMBER_BASE: { [string]: Color3 } = {
	Common = Color3.fromRGB(255, 246, 228),
	Uncommon = Color3.fromRGB(120, 235, 170),
	Rare = Color3.fromRGB(90, 190, 255),
	Epic = Color3.fromRGB(190, 120, 255),
}
local GOLD_SHIMMER = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 40)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 215, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 230)),
	ColorSequenceKeypoint.new(0.65, Color3.fromRGB(255, 215, 80)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 40)),
})

-- Styles the income number by rarity and runs its animation until `alive()` turns false:
-- Common/Uncommon/Rare plain colour, Epic purple with a pulsing outline, Legendary (and the gold
-- variant) a gold gradient with a shine sweeping across, Mystic a rotating rainbow; Legendary and
-- Mystic also throw sparkles around the number.
local function styleIncome(
	lbl: TextLabel,
	rarity: string,
	gold: boolean,
	reduce: boolean,
	alive: () -> boolean
)
	local stroke = lbl:FindFirstChildOfClass("UIStroke")
	local mystic = rarity == "Mystic"
	local shimmer = (rarity == "Legendary" or gold) and not mystic
	local base = NUMBER_BASE[rarity] or NUMBER_BASE.Common
	lbl.TextColor3 = WHITE
	local gradient = Instance.new("UIGradient")
	if mystic then
		gradient.Color = K.RAINBOW
	elseif shimmer then
		gradient.Color = GOLD_SHIMMER
	else
		gradient.Color = ColorSequence.new(base:Lerp(WHITE, 0.4), base)
		gradient.Rotation = 90
	end
	gradient.Parent = lbl
	if stroke and rarity == "Epic" then
		stroke.Color = Color3.fromRGB(70, 30, 130)
	end
	if reduce then
		return
	end
	task.spawn(function()
		local t = 0
		local last = 0
		while alive() and lbl.Parent do
			t += task.wait()
			if mystic then
				gradient.Rotation = (t * 150) % 360
			elseif shimmer then
				gradient.Offset = Vector2.new(((t * 0.9) % 2) - 1, 0)
			elseif stroke and rarity == "Epic" then
				stroke.Thickness = 4 + math.sin(t * 6) * 1.5
			end
			local screenGui = lbl:FindFirstAncestorOfClass("ScreenGui")
			if (mystic or shimmer) and t - last > 0.14 and screenGui then
				last = t
				local sp = Instance.new("Frame")
				sp.AnchorPoint = Vector2.new(0.5, 0.5)
				sp.Size = UDim2.fromOffset(math.random(6, 11), math.random(6, 11))
				sp.Rotation = 45
				sp.BackgroundColor3 = if mystic
					then Color3.fromHSV(math.random(), 0.5, 1)
					else Color3.fromRGB(255, 240, 160)
				sp.BorderSizePixel = 0
				sp.ZIndex = lbl.ZIndex + 1
				local px = lbl.AbsolutePosition.X + lbl.AbsoluteSize.X * math.random()
				local py = lbl.AbsolutePosition.Y + lbl.AbsoluteSize.Y * math.random()
				local origin = screenGui.AbsolutePosition
				sp.Position = UDim2.fromOffset(px - origin.X, py - origin.Y)
				sp.Parent = screenGui
				local tw = TweenService:Create(sp, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {
					Position = sp.Position - UDim2.fromOffset(0, 30),
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(2, 2),
					Rotation = 225,
				})
				tw:Play()
				tw.Completed:Once(function()
					sp:Destroy()
				end)
			end
		end
	end)
end

-- Screen point of the player's right hand (falls back to the lower middle of the screen).
local function handPoint(): UDim2
	local camera = Workspace.CurrentCamera
	local char = player.Character
	local hand = char
		and (
			char:FindFirstChild("RightHand")
			or char:FindFirstChild("Right Arm")
			or char:FindFirstChild("HumanoidRootPart")
		)
	if camera and hand and hand:IsA("BasePart") then
		local point, onScreen = camera:WorldToViewportPoint(hand.Position)
		if onScreen and point.Z > 0 then
			return UDim2.fromOffset(point.X, point.Y)
		end
	end
	return UDim2.fromScale(0.5, 0.86)
end

-- How big the silhouette looks for a size multiplier (the real model grows in the reveal).
local function visualScale(sizeMult: number): number
	return math.clamp(sizeMult ^ 0.5, 0.45, 2.0)
end

function CatchShow.play(update: Update, info: Info)
	local spins: { { wheel: string, result: string } } = update.spins or {}
	local reduce = player:GetAttribute("ReduceEffects") == true
	-- Pace: plain catches are most catches, so a Common/Uncommon where the roulette gave nothing
	-- runs at about half the time; anything special keeps the full show.
	local plain = true
	local spinList: { { wheel: string, result: string } } = update.spins or {}
	for _, spin in spinList do
		if spin.result ~= "nothing" then
			plain = false
		end
	end
	local pace = if plain
			and (info.rarity == "Common" or info.rarity == "Uncommon" or info.rarity == nil)
		then 0.55
		else 1
	local state = { fast = false }
	local camera = Workspace.CurrentCamera
	local name = (Strings.creatureName :: any)[info.creatureId] or info.creatureId
	local letters = letterCount(name)

	------------------------------------------------------------------ screen effects
	local blur: BlurEffect? = nil
	if not reduce then
		local b = Instance.new("BlurEffect")
		b.Name = "CatchShowBlur"
		b.Size = 0
		b.Parent = Lighting
		TweenService:Create(b, TweenInfo.new(0.35), { Size = 9 }):Play()
		blur = b
	end
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "CatchShowGrade"
	grade.Parent = Lighting
	TweenService:Create(grade, TweenInfo.new(0.35), { Saturation = 0.3, Contrast = 0.08 }):Play()

	------------------------------------------------------------------ layout
	local screen = Instance.new("ScreenGui")
	screen.Name = "CatchShow"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 21
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local backdrop = Instance.new("Frame")
	backdrop.AnchorPoint = Vector2.new(0.5, 0.5)
	backdrop.Position = UDim2.fromScale(0.5, 0.5)
	backdrop.Size = UDim2.fromScale(1.08, 1.08)
	backdrop.BackgroundColor3 = K.BACKDROP.main
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 1
	backdrop.Parent = screen
	local bdg = Instance.new("UIGradient")
	bdg.Rotation = 90
	bdg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	bdg.Parent = backdrop

	local rayHolder = Instance.new("Frame")
	rayHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	rayHolder.Position = UDim2.fromScale(0.5, 0.32)
	rayHolder.Size = UDim2.fromScale(2.2, 2.2)
	rayHolder.BackgroundTransparency = 1
	rayHolder.ZIndex = 2
	local sq = Instance.new("UIAspectRatioConstraint")
	sq.DominantAxis = Enum.DominantAxis.Height
	sq.Parent = rayHolder
	rayHolder.Parent = screen
	local rays: { Frame } = {}
	for _ = 1, K.RAY_COUNT do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.Size = UDim2.fromScale(0.08, 1)
		ray.BackgroundColor3 = WHITE
		ray.BackgroundTransparency = 0.84
		ray.BorderSizePixel = 0
		ray.ZIndex = 2
		local rg = Instance.new("UIGradient")
		rg.Rotation = 90
		rg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.4, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(0.6, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		rg.Parent = ray
		ray.Parent = rayHolder
		table.insert(rays, ray)
	end

	-- Glow disc behind the silhouette (mutation colour / tier accent).
	local glow = Instance.new("Frame")
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.45)
	glow.Size = UDim2.fromScale(0.62, 0.62)
	glow.BackgroundColor3 = WHITE
	glow.BackgroundTransparency = 0.7
	glow.BorderSizePixel = 0
	glow.ZIndex = 4
	local glowAspect = Instance.new("UIAspectRatioConstraint")
	glowAspect.Parent = glow
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0.5, 0)
	glowCorner.Parent = glow
	local gg = Instance.new("UIGradient")
	gg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	gg.Parent = glow
	glow.Parent = screen
	local glowScale = Instance.new("UIScale")
	glowScale.Parent = glow

	local vp, model = buildSilhouette(screen, info.creatureId)
	local vpScale = Instance.new("UIScale")
	vpScale.Scale = 0.3
	vpScale.Parent = vp

	-- Reel frame: plump 3D cartoon gold/plum candy frame + inner window, matching Roulette.
	local reelY = 0.63
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 1.4)
	frame.Size = UDim2.fromScale(0.94, 0.25)
	frame.BackgroundColor3 = WHITE
	frame.BorderSizePixel = 0
	frame.ZIndex = 3
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0.18, 0)
	fc.Parent = frame
	local frameGrad = Instance.new("UIGradient")
	frameGrad.Rotation = 90
	frameGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UiAssets.GOLD_TOP),
		ColorSequenceKeypoint.new(0.45, UiAssets.GOLD_MID),
		ColorSequenceKeypoint.new(1, UiAssets.GOLD_BOT),
	})
	frameGrad.Parent = frame
	local rim = Instance.new("UIStroke")
	rim.Color = UiAssets.OUTLINE
	rim.Thickness = 6
	rim.Parent = frame
	local rimGradient = Instance.new("UIGradient")
	rimGradient.Color = ColorSequence.new(UiAssets.OUTLINE, Color3.fromRGB(84, 34, 130))
	rimGradient.Parent = rim
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(840, 240)
	limit.Parent = frame
	frame.Parent = screen
	local window = Instance.new("Frame")
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.new(1, -16, 1, -16)
	window.BackgroundColor3 = Color3.fromRGB(16, 10, 32)
	window.BorderSizePixel = 0
	window.ClipsDescendants = true
	window.ZIndex = 4
	local wc = Instance.new("UICorner")
	wc.CornerRadius = UDim.new(0.12, 0)
	wc.Parent = window
	window.Parent = frame
	for _, side in { 0, 1 } do
		local fade = Instance.new("Frame")
		fade.AnchorPoint = Vector2.new(side, 0)
		fade.Position = UDim2.fromScale(side, 0)
		fade.Size = UDim2.fromScale(0.18, 1)
		fade.BackgroundColor3 = Color3.fromRGB(16, 10, 32)
		fade.BorderSizePixel = 0
		fade.ZIndex = 9
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new(if side == 0 then 0 else 1, if side == 0 then 1 else 0)
		g.Parent = fade
		fade.Parent = window
	end
	local selector = Instance.new("Frame")
	selector.AnchorPoint = Vector2.new(0.5, 0.5)
	selector.Position = UDim2.fromScale(0.5, 0.5)
	selector.Size = UDim2.fromScale(K.CARD_W * 0.98, 0.98)
	selector.BackgroundTransparency = 1
	selector.ZIndex = 10
	local selCorner = Instance.new("UICorner")
	selCorner.CornerRadius = UDim.new(0.16, 0)
	selCorner.Parent = selector
	local selStroke = Instance.new("UIStroke")
	selStroke.Color = Theme.gold
	selStroke.Thickness = 4
	selStroke.Parent = selector
	selector.Parent = frame
	local arrows: { Frame } = {}
	for _, y in { 0, 1 } do
		local arrow = Instance.new("Frame")
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		arrow.Position = UDim2.fromScale(0.5, y)
		arrow.Size = UDim2.fromOffset(28, 28)
		arrow.Rotation = 45
		arrow.BackgroundColor3 = Theme.gold
		arrow.BorderSizePixel = 0
		arrow.ZIndex = 11
		local as = Instance.new("UIStroke")
		as.Color = INK
		as.Thickness = 3
		as.Parent = arrow
		arrow.Parent = frame
		table.insert(arrows, arrow)
	end

	local title =
		K.label(screen, "", WHITE, UDim2.fromScale(0.86, 0.075), UDim2.fromScale(0.5, 0.47), 5, 12)
	local titleGradient = Instance.new("UIGradient")
	titleGradient.Rotation = 90
	titleGradient.Parent = title
	title.TextTransparency = 1

	local chip = Instance.new("Frame")
	chip.AnchorPoint = Vector2.new(0.5, 0.5)
	chip.Position = UDim2.fromScale(0.5, 0.81)
	chip.Size = UDim2.fromScale(0.74, 0.07)
	chip.BackgroundColor3 = Color3.fromRGB(40, 22, 70)
	chip.BackgroundTransparency = 1
	chip.BorderSizePixel = 0
	chip.ZIndex = 11
	local chc = Instance.new("UICorner")
	chc.CornerRadius = UDim.new(0.5, 0)
	chc.Parent = chip
	local chs = Instance.new("UIStroke")
	chs.Color = Theme.gold
	chs.Thickness = 3
	chs.Transparency = 1
	chs.Parent = chip
	local chipLimit = Instance.new("UISizeConstraint")
	chipLimit.MaxSize = Vector2.new(660, 70)
	chipLimit.Parent = chip
	chip.Parent = screen
	local footer =
		K.label(chip, "", WHITE, UDim2.new(1, -24, 0.8, 0), UDim2.fromScale(0.5, 0.5), 3, 12)

	-- Counter block (hidden until phase 3).
	local word = K.label(
		screen,
		Strings.oddsTier[1],
		TIER_ACCENT[1],
		UDim2.fromScale(0.8, 0.07),
		UDim2.fromScale(0.5, 0.075),
		4,
		14
	)
	local wordGradient = Instance.new("UIGradient")
	wordGradient.Rotation = 90
	wordGradient.Parent = word
	word.TextTransparency = 1
	local wordStroke = word:FindFirstChildOfClass("UIStroke")
	if wordStroke then
		wordStroke.Transparency = 1
	end
	local counter = K.label(
		screen,
		string.format(Strings.oddsOneIn, "1"),
		WHITE,
		UDim2.fromScale(0.92, 0.09),
		UDim2.fromScale(0.5, 0.17),
		4,
		14
	)
	local counterCap = Instance.new("UITextSizeConstraint")
	counterCap.MaxTextSize = 110
	counterCap.Parent = counter
	counter.TextTransparency = 1
	local counterStroke = counter:FindFirstChildOfClass("UIStroke")
	if counterStroke then
		counterStroke.Transparency = 1
	end
	local nameLabel = K.label(
		screen,
		partialName(name, 0),
		WHITE,
		UDim2.fromScale(0.86, 0.075),
		UDim2.fromScale(0.5, 0.76),
		4,
		14
	)
	nameLabel.TextTransparency = 1
	local nameStroke = nameLabel:FindFirstChildOfClass("UIStroke")
	if nameStroke then
		nameStroke.Transparency = 1
	end
	local hint = K.label(
		screen,
		Strings.roulette.skip,
		WHITE,
		UDim2.fromScale(0.42, 0.032),
		UDim2.fromScale(0.5, 0.94),
		2,
		14
	)
	hint.TextTransparency = 0.3

	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = WHITE
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 30
	flash.Parent = screen

	local tap = Instance.new("TextButton")
	tap.Size = UDim2.fromScale(1, 1)
	tap.BackgroundTransparency = 1
	tap.Text = ""
	tap.ZIndex = 40
	tap.Parent = screen
	tap.Activated:Connect(function()
		state.fast = true
	end)

	screen.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(backdrop, TweenInfo.new(0.25), { BackgroundTransparency = 0.2 }):Play()

	------------------------------------------------------------------ per-frame life
	type Piece = { frame: Frame, x: number, y: number, vy: number, vx: number, spin: number }
	local pieces: { Piece } = {}
	local cards: { Roulette.Card } = {}
	local strip: Frame? = nil
	local lastCenter = 0
	local raySpeed = 14
	local confettiRate = 0
	local debt = 0
	local shakeUntil = 0
	local tier = 1
	local t0 = os.clock()
	local function confetti(count: number, fromCentre: boolean)
		if reduce then
			return
		end
		for _ = 1, count do
			if #pieces >= K.CONFETTI_MAX then
				return
			end
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Size = UDim2.fromOffset(math.random(8, 16), math.random(4, 9))
			f.BackgroundColor3 = K.CONFETTI_COLORS[math.random(1, #K.CONFETTI_COLORS)]
			f.BorderSizePixel = 0
			f.ZIndex = 20
			f.Parent = screen
			table.insert(pieces, {
				frame = f,
				x = if fromCentre then 0.5 else math.random(),
				y = if fromCentre then 0.4 else -0.05,
				vx = if fromCentre then (math.random() - 0.5) * 1.2 else 0,
				vy = if fromCentre then -0.5 - math.random() * 0.7 else 0.2 + math.random() * 0.3,
				spin = (math.random() - 0.5) * 700,
			})
		end
	end
	local beat = RunService.RenderStepped:Connect(function(dt: number)
		local t = os.clock() - t0
		for i, ray in rays do
			ray.Rotation = (i - 1) * (180 / K.RAY_COUNT) + (if reduce then 0 else t * raySpeed)
		end
		if not reduce then
			selStroke.Thickness = 4 + math.abs(math.sin(t * 5)) * 2
			rimGradient.Rotation = (t * 60) % 360
			for _, card in cards do
				card.shine.Offset = Vector2.new(((t * 0.8 + card.phase) % 2) - 1, 0)
				if card.spin then
					card.spin.Rotation = (t * 90) % 360
				end
			end
			glowScale.Scale = 1 + math.sin(t * 2.4) * 0.05
		else
			selStroke.Thickness = 4
			glowScale.Scale = 1
		end
		if model then
			model:PivotTo(CFrame.Angles(0, math.sin(t * 0.9) * 0.45, math.sin(t * 1.7) * 0.05))
		end
		local s = strip
		if s then
			local centre = math.floor((0.5 - s.Position.X.Scale) / K.CARD_W + 0.5)
			if centre ~= lastCenter then
				lastCenter = centre
				for _, arrow in arrows do
					K.pop(arrow, 1.35, 1, 0.12)
				end
			end
		end
		if confettiRate > 0 then
			debt += confettiRate * (if reduce then 0.3 else 1) * dt
			while debt >= 1 do
				debt -= 1
				confetti(1, false)
			end
		end
		for i = #pieces, 1, -1 do
			local p = pieces[i]
			p.vy = math.min(p.vy + dt * 1.1, 0.6)
			p.vx *= 0.98
			p.x += p.vx * dt
			p.y += p.vy * dt
			p.frame.Position = UDim2.fromScale(p.x, p.y)
			p.frame.Rotation += p.spin * dt
			if p.y > 1.1 then
				p.frame:Destroy()
				table.remove(pieces, i)
			end
		end
		if not reduce and os.clock() < shakeUntil then
			backdrop.Position = UDim2.new(0.5, math.random(-6, 6), 0.5, math.random(-6, 6))
		else
			backdrop.Position = UDim2.fromScale(0.5, 0.5)
		end
	end)

	local function punch(color: Color3, big: boolean)
		if reduce then
			return
		end
		flash.BackgroundColor3 = color:Lerp(WHITE, 0.5)
		flash.BackgroundTransparency = if big then 0.35 else 0.72
		TweenService
			:Create(flash, TweenInfo.new(if big then 0.4 else 0.25), { BackgroundTransparency = 1 })
			:Play()
		if big and camera then
			local fov = camera.FieldOfView
			camera.FieldOfView = fov - 7
			TweenService
				:Create(camera, TweenInfo.new(0.45, Enum.EasingStyle.Back), { FieldOfView = fov })
				:Play()
		end
		if big then
			local ring = Instance.new("Frame")
			ring.AnchorPoint = Vector2.new(0.5, 0.5)
			ring.Position = vp.Position
			ring.Size = UDim2.fromScale(0.15, 0.15)
			ring.BackgroundTransparency = 1
			ring.ZIndex = 19
			local ra = Instance.new("UIAspectRatioConstraint")
			ra.Parent = ring
			local rc = Instance.new("UICorner")
			rc.CornerRadius = UDim.new(0.5, 0)
			rc.Parent = ring
			local rs = Instance.new("UIStroke")
			rs.Color = color:Lerp(WHITE, 0.3)
			rs.Thickness = 10
			rs.Parent = ring
			ring.Parent = screen
			TweenService:Create(
				ring,
				TweenInfo.new(0.6, Enum.EasingStyle.Quad),
				{ Size = UDim2.fromScale(1.6, 1.6) }
			):Play()
			local fadeRing =
				TweenService:Create(rs, TweenInfo.new(0.6), { Transparency = 1, Thickness = 2 })
			fadeRing:Play()
			fadeRing.Completed:Once(function()
				ring:Destroy()
			end)
			shakeUntil = os.clock() + 0.3
		end
	end

	local function sparkles(color: Color3, count: number, at: UDim2)
		if reduce then
			return
		end
		for _ = 1, count do
			local p = Instance.new("Frame")
			p.AnchorPoint = Vector2.new(0.5, 0.5)
			p.Position = at
			p.Size = UDim2.fromOffset(14, 14)
			p.Rotation = math.random(0, 90)
			p.BackgroundColor3 = color:Lerp(WHITE, math.random() * 0.6)
			p.BorderSizePixel = 0
			p.ZIndex = 21
			p.Parent = screen
			local a = math.random() * math.pi * 2
			local d = 0.14 + math.random() * 0.26
			local tw = TweenService:Create(
				p,
				TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = UDim2.fromScale(
						at.X.Scale + math.cos(a) * d,
						at.Y.Scale + math.sin(a) * d * 1.4
					),
					Rotation = p.Rotation + 220,
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(4, 4),
				}
			)
			tw:Play()
			tw.Completed:Once(function()
				p:Destroy()
			end)
		end
	end

	------------------------------------------------------------------ silhouette state
	local sizeAcc = 1
	local mutationId: string? = nil
	local function applySilhouette(animate: boolean)
		local target = visualScale(sizeAcc)
		local info2 = TweenInfo.new(if animate then 0.5 else 0, Enum.EasingStyle.Back)
		TweenService:Create(vpScale, info2, { Scale = target }):Play()
		if mutationId then
			local c = MUTATION_COLORS[mutationId] or WHITE
			TweenService
				:Create(vp, TweenInfo.new(0.4), { ImageColor3 = Color3.new(0, 0, 0):Lerp(c, 0.28) })
				:Play()
			TweenService:Create(
				glow,
				TweenInfo.new(0.4),
				{ BackgroundColor3 = c, BackgroundTransparency = 0.45 }
			):Play()
		end
	end

	------------------------------------------------------------------ one reel
	local function runReel(wheel: string, result: string)
		local color = K.WHEEL_COLOR[wheel] or WHITE
		title.Text = Strings.roulette.title[wheel] or ""
		titleGradient.Color = if wheel == "mutation"
			then K.RAINBOW
			else ColorSequence.new(WHITE, color)
		TweenService:Create(title, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
		TweenService:Create(
			backdrop,
			TweenInfo.new(0.35),
			{ BackgroundColor3 = K.BACKDROP[wheel] or K.BACKDROP.main }
		):Play()
		selStroke.Color = color:Lerp(WHITE, 0.3)
		for _, arrow in arrows do
			arrow.BackgroundColor3 = color:Lerp(WHITE, 0.2)
		end
		raySpeed = if wheel == "mutation" then 40 elseif wheel == "size" then 28 else 14
		K.pop(title, 0.4, 1, 0.3)

		local s = Instance.new("Frame")
		s.Name = "Strip"
		s.BackgroundTransparency = 1
		s.Size = UDim2.fromScale(1, 1)
		s.ZIndex = 5
		s.Parent = window
		table.clear(cards)
		local entries = RouletteConfig.wheel(wheel)
		for i = 1, K.CARDS do
			local id = if i == K.TARGET
				then result
				else RouletteConfig.pick(entries, math.random()).id
			table.insert(cards, K.makeCard(s, wheel, id, i))
		end
		local finalX = 0.5 - K.CARD_W * (K.TARGET - 0.5)
		local landX = finalX + (math.random() - 0.5) * K.CARD_W * 0.6
		-- Near miss (suspense): a good result sometimes stops just short, on the edge of the
		-- card before it, and creeps over; a "nothing" next to a good card sometimes overshoots
		-- onto that card's edge and falls back. Only the path changes, never the result.
		local tease = "none"
		local nextCard = cards[K.TARGET + 1]
		if not state.fast and not reduce then
			if K.isGood(wheel, result) and math.random() < 0.6 then
				tease = "creep"
				landX = finalX + K.CARD_W * 0.47
			elseif
				result == "nothing"
				and nextCard
				and K.isGood(wheel, nextCard.frame.Name)
				and math.random() < 0.45
			then
				tease = "back"
				landX = finalX - K.CARD_W * 0.47
			end
		end
		s.Position = UDim2.fromScale(0.5 - K.CARD_W * 2.5, 0)
		strip = s
		local time = if state.fast then 0.35 else ((K.SPIN_TIME :: any)[wheel] or 2) * pace
		local tween = TweenService:Create(
			s,
			TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromScale(landX, 0),
			}
		)
		tween:Play()
		local started = os.clock()
		local lastIndex = -1
		local function tick()
			-- a click each time a card passes the marker, like a real wheel
			local index = math.floor((0.5 - s.Position.X.Scale) / K.CARD_W)
			if index ~= lastIndex then
				if lastIndex >= 0 then
					Audio.play("click", 0.16, 1.05)
				end
				lastIndex = index
			end
		end
		while tween.PlaybackState == Enum.PlaybackState.Playing do
			if state.fast and os.clock() - started < time - 0.05 then
				tween:Cancel()
				s.Position = UDim2.fromScale(landX, 0)
				break
			end
			tick()
			task.wait()
		end
		if tease ~= "none" and not state.fast then
			-- hold on the edge for a breath, trembling, then fall onto the result
			local edge = s.Position
			local holdUntil = os.clock() + 0.42
			while os.clock() < holdUntil and not state.fast do
				s.Position = edge + UDim2.fromScale((math.random() - 0.5) * 0.004, 0)
				task.wait()
			end
			s.Position = edge
			local fall = TweenService:Create(
				s,
				TweenInfo.new(
					if tease == "creep" then 0.5 else 0.35,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.InOut
				),
				{ Position = UDim2.fromScale(finalX, 0) }
			)
			fall:Play()
			while fall.PlaybackState == Enum.PlaybackState.Playing do
				tick()
				task.wait()
			end
		else
			TweenService:Create(
				s,
				TweenInfo.new(0.2, Enum.EasingStyle.Back),
				{ Position = UDim2.fromScale(finalX, 0) }
			):Play()
			task.wait(0.2)
		end
		strip = nil

		local card = cards[K.TARGET].frame
		for i, other in cards do
			if i ~= K.TARGET then
				TweenService
					:Create(other.frame, TweenInfo.new(0.2), { BackgroundTransparency = 0.65 })
					:Play()
			end
		end
		card.ZIndex = 7
		K.pop(card, 1, 1.26, 0.3)
		local cardColor = K.cardColor(wheel, result)
		local big = K.isBig(wheel, result)
		local bad = wheel == "worse" or result == "worse" or result == "nothing"
		if bad then
			Audio.play("miss", 0.3, 0.9)
			TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Bounce), {
				Position = card.Position + UDim2.fromScale(0, 0.06),
			}):Play()
			TweenService:Create(grade, TweenInfo.new(0.3), { Saturation = -0.1 }):Play()
			task.delay(0.6, function()
				if grade.Parent then
					TweenService:Create(grade, TweenInfo.new(0.3), { Saturation = 0.3 }):Play()
				end
			end)
		else
			if big then
				Audio.play("chest", 0.5, 1)
			else
				Audio.play("hit", 0.45, if K.isGood(wheel, result) then 1.15 else 1)
			end
			punch(cardColor, big)
			sparkles(
				cardColor,
				if big then 34 elseif K.isGood(wheel, result) then 18 else 8,
				vp.Position
			)
			if wheel ~= "main" then
				confetti(if big then 50 else 16, true)
			end
		end
		-- The silhouette reacts to the result.
		if wheel == "size" or wheel == "worse" then
			local e = K.entryOf(wheel, result)
			sizeAcc *= if e then e.mult else 1
			applySilhouette(true)
		elseif wheel == "mutation" then
			mutationId = result
			applySilhouette(true)
		end
		if result == "again" then
			title.Text = Strings.roulette.again
			K.pop(title, 0.5, 1.15, 0.3)
		end
		task.wait(if state.fast then 0.25 else 0.65 * pace)
		s:Destroy()
		table.clear(cards)
	end

	------------------------------------------------------------------ phase 1: silhouette in
	K.pop(vp, 0.3, 1, 0.45)
	TweenService:Create(vpScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.wait(if state.fast then 0.3 else 0.7 * pace)
	-- ...then it floats to the top while the reel frame rises from below.
	local topPos = UDim2.fromScale(0.5, 0.3)
	TweenService:Create(vp, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Position = topPos }):Play()
	TweenService:Create(glow, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Position = topPos })
		:Play()
	TweenService:Create(
		frame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back),
		{ Position = UDim2.fromScale(0.5, reelY) }
	):Play()
	task.wait(0.5 * pace)

	------------------------------------------------------------------ phase 2: the reels
	local mutationName: string? = nil
	local sizeShown = 1
	for _, spin in spins do
		runReel(spin.wheel, spin.result)
		if spin.wheel == "size" or spin.wheel == "worse" then
			local e = K.entryOf(spin.wheel, spin.result)
			sizeShown *= if e then e.mult else 1
		elseif spin.wheel == "mutation" then
			mutationName = Strings.roulette.card[spin.result] or spin.result
		end
		local parts = {}
		if sizeShown ~= 1 then
			table.insert(parts, string.format(Strings.roulette.size, K.num(sizeShown)))
		end
		if mutationName then
			table.insert(parts, string.format(Strings.roulette.mutation, mutationName))
		end
		if #parts > 0 then
			footer.Text = table.concat(parts, "  ·  ")
			chip.BackgroundTransparency = 0.15
			chs.Transparency = 0
			K.pop(chip, 0.7, 1, 0.25)
		end
	end

	-- Totals chip.
	local coin = update.coinMult or 1
	chip.BackgroundTransparency = 0.15
	chs.Transparency = 0
	if math.abs(coin - 1) < 0.001 then
		footer.Text = Strings.roulette.nothing
		footer.TextColor3 = Color3.fromRGB(205, 210, 225)
		K.pop(chip, 0.7, 1, 0.25)
		task.wait(if state.fast then 0.3 else 0.6 * pace)
	else
		local prefix = if footer.Text ~= "" then footer.Text .. "  ·  " else ""
		footer.TextColor3 = if coin > 1 then Theme.gold else Color3.fromRGB(255, 150, 150)
		chs.Color = if coin > 1 then Theme.gold else Color3.fromRGB(255, 110, 120)
		local steps = if state.fast then 1 else 12
		for i = 1, steps do
			local v = 1 + (coin - 1) * (i / steps)
			footer.Text = prefix
				.. string.format(Strings.roulette.coins, K.num(math.floor(v * 10 + 0.5) / 10))
			K.pop(chip, 1.08, 1, 0.08)
			task.wait(0.035)
		end
		K.pop(chip, 1.3, 1.08, 0.3)
		task.wait(if state.fast then 0.4 else 0.8 * pace)
	end

	------------------------------------------------------------------ phase 3: the odds
	local odds = if info.odds then math.max(1, math.floor(info.odds)) else nil
	if odds then
		local finalTier = tierOf(odds)
		local duration = TIER_TIME[finalTier] * pace
		if info.short then
			duration = math.min(duration, SHORT_CAP)
		end
		-- reels leave, the silhouette moves to the middle and the counter appears
		TweenService:Create(
			frame,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Position = UDim2.fromScale(0.5, 1.4) }
		):Play()
		-- title and chip text fade out together with their outlines (a bare stroke would stay)
		for _, gone in { title, footer } do
			TweenService:Create(gone, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
			local gs = gone:FindFirstChildOfClass("UIStroke")
			if gs then
				TweenService:Create(gs, TweenInfo.new(0.2), { Transparency = 1 }):Play()
			end
		end
		TweenService:Create(chip, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(chs, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		local midPos = UDim2.fromScale(0.5, 0.5)
		TweenService:Create(vp, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Position = midPos })
			:Play()
		TweenService:Create(glow, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Position = midPos })
			:Play()
		for _, label in { word, counter, nameLabel } do
			TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
			local st = label:FindFirstChildOfClass("UIStroke")
			if st then
				TweenService:Create(st, TweenInfo.new(0.3), { Transparency = 0 }):Play()
			end
		end
		task.wait(0.45 * pace)

		local function enterTier(newTier: number)
			tier = newTier
			confettiRate = TIER_CONFETTI[newTier]
			TweenService
				:Create(backdrop, TweenInfo.new(0.3), { BackgroundColor3 = TIER_BG[newTier] })
				:Play()
			if not mutationId then
				TweenService:Create(
					glow,
					TweenInfo.new(0.3),
					{ BackgroundColor3 = TIER_ACCENT[newTier], BackgroundTransparency = 0.5 }
				):Play()
			end
			word.Text = Strings.oddsTier[newTier]
			word.TextColor3 = WHITE
			wordGradient.Color = ColorSequence.new(WHITE, TIER_ACCENT[newTier])
			if newTier == 7 then
				wordGradient.Color = K.RAINBOW
			end
			K.pop(word, 0.3, 1, 0.35)
			if newTier >= 4 then
				Audio.play("legendary", 0.3, 0.8 + newTier * 0.05)
			end
			raySpeed = 10 + newTier * 9
			if not reduce then
				if newTier >= 4 then
					flash.BackgroundColor3 = WHITE
					flash.BackgroundTransparency = 0.5
					TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
						:Play()
				end
				if newTier >= 5 then
					shakeUntil = os.clock() + 0.25 + (newTier - 5) * 0.15
				end
				confetti(6 + newTier * 3, true)
			end
		end

		-- Ticks: log-spaced values from 1 to the real odds, landing on every tier border.
		local ticks: { number } = {}
		local baseCount = 6 + finalTier * 4
		for i = 1, baseCount do
			table.insert(ticks, odds ^ (i / baseCount))
		end
		for i = 1, finalTier - 1 do
			table.insert(ticks, THRESHOLDS[i] + 1)
		end
		table.sort(ticks)
		ticks[#ticks] = odds
		local tickCount = #ticks
		local startClock = os.clock()
		state.fast = false -- the counter gets its own full run unless tapped again
		for i, value in ticks do
			if state.fast then
				break
			end
			local at = startClock + duration * (i / tickCount) ^ 0.85
			-- Slow motion on the last numbers of a huge catch (IRREAL! and up): each of the final
			-- ticks waits a little longer, so the final figure lands like a drum hit.
			if finalTier >= 5 and not reduce then
				local fromEnd = tickCount - i
				if fromEnd < 3 then
					at += (3 - fromEnd) * 0.22
				end
			end
			while os.clock() < at and not state.fast do
				task.wait()
			end
			counter.Text = string.format(Strings.oddsOneIn, grouped(value))
			K.pop(counter, 1.22, 1, 0.18)
			Audio.play("click", 0.14, 0.85 + (i / tickCount) * 0.8)
			local newTier = tierOf(value)
			if newTier > tier then
				enterTier(newTier)
			end
			nameLabel.Text = partialName(name, math.floor(letters * (i / tickCount) * 0.85))
		end
		if tierOf(odds) > tier then
			enterTier(tierOf(odds))
		end
		counter.Text = string.format(Strings.oddsOneIn, grouped(odds))
		nameLabel.Text = name
		K.pop(counter, 1.45, 1, 0.3)
		K.pop(nameLabel, 1.3, 1, 0.3)
		punch(TIER_ACCENT[tier], tier >= 4)
		confetti(16 + finalTier * 4, true)
		task.wait(if state.fast then 0.4 else 0.9 * pace)
	end

	------------------------------------------------------------------ phase 4: it becomes the fish
	do
		state.fast = false
		local rarityName = info.rarity or "Common"
		local goldVariant = update.variantId == "gold"
			or update.variantId == "both"
			or update.variant == "Shiny"
		local cpm = update.potentialCpm
		-- the black silhouette takes its real colours (a mutation keeps a hint of its tint)
		local finalTint = WHITE
		if mutationId then
			finalTint = WHITE:Lerp(MUTATION_COLORS[mutationId] or WHITE, 0.22)
		end
		TweenService:Create(vp, TweenInfo.new(0.55), {
			ImageColor3 = finalTint,
			Ambient = Color3.fromRGB(165, 165, 175),
		}):Play()
		TweenService:Create(glow, TweenInfo.new(0.5), { BackgroundTransparency = 0.35 }):Play()
		-- the fish grows into the middle of the screen so it can be admired (flies off below)
		local revealScale = 1.5
		TweenService
			:Create(vpScale, TweenInfo.new(0.55, Enum.EasingStyle.Back), { Scale = revealScale })
			:Play()
		punch(TIER_ACCENT[tier], true)
		confetti(26, true)
		Audio.play("level", 0.45, 1)
		nameLabel.Text = name
		for _, label in { word, counter } do
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 0.55 }):Play()
		end
		task.wait(0.5 * pace)

		-- coins per minute above the creature, styled by rarity
		local showing = true
		if cpm and cpm > 0 then
			local pill = Instance.new("Frame")
			pill.Name = "IncomePill"
			pill.AnchorPoint = Vector2.new(0.5, 0.5)
			pill.Position = UDim2.fromScale(0.5, 0.265)
			pill.Size = UDim2.fromScale(0.78, 0.085)
			pill.BackgroundColor3 = Color3.fromRGB(24, 14, 44)
			pill.BackgroundTransparency = 0.25
			pill.BorderSizePixel = 0
			pill.ZIndex = 14
			local pillCorner = Instance.new("UICorner")
			pillCorner.CornerRadius = UDim.new(0.5, 0)
			pillCorner.Parent = pill
			local pillStroke = Instance.new("UIStroke")
			pillStroke.Thickness = 3
			pillStroke.Color = (NUMBER_BASE[rarityName] or Color3.fromRGB(255, 205, 70)):Lerp(
				WHITE,
				0.15
			)
			if rarityName == "Legendary" or goldVariant then
				pillStroke.Color = Color3.fromRGB(255, 205, 70)
			elseif rarityName == "Mystic" then
				pillStroke.Color = Color3.fromRGB(255, 120, 220)
			end
			pillStroke.Parent = pill
			local pillLimit = Instance.new("UISizeConstraint")
			pillLimit.MaxSize = Vector2.new(620, 92)
			pillLimit.Parent = pill
			pill.Parent = screen
			K.pop(pill, 0.4, 1, 0.4)
			local income = K.label(
				pill,
				"",
				WHITE,
				UDim2.new(1, -28, 0.82, 0),
				UDim2.fromScale(0.5, 0.5),
				4,
				15
			)
			local incomeCap = Instance.new("UITextSizeConstraint")
			incomeCap.MaxTextSize = 84
			incomeCap.Parent = income
			styleIncome(income, rarityName, goldVariant, reduce, function()
				return showing
			end)
			K.pop(income, 0.4, 1, 0.4)
			local steps = if state.fast then 1 elseif pace < 1 then 8 else 16
			for i = 1, steps do
				income.Text = string.format(Strings.incomePerMin, coinsText(cpm * (i / steps)))
				task.wait(0.03)
			end
			K.pop(income, 1.35, 1, 0.3)
			Audio.play("coins", 0.4, 1.1)
			sparkles(TIER_ACCENT[tier], 14, UDim2.fromScale(0.5, 0.265))
			task.wait(if state.fast then 0.5 else 1.2 * pace)
		else
			task.wait(if state.fast then 0.3 else 0.7 * pace)
		end
		showing = false

		-- everything fades except the fish, which flies to the hand and shrinks
		local gone = TweenInfo.new(0.3)
		for _, d in screen:GetChildren() do
			if d ~= vp and d:IsA("GuiObject") then
				if d:IsA("TextLabel") then
					TweenService:Create(d, gone, { TextTransparency = 1 }):Play()
					local st = d:FindFirstChildOfClass("UIStroke")
					if st then
						TweenService:Create(st, gone, { Transparency = 1 }):Play()
					end
				elseif d:IsA("Frame") and d ~= glow then
					TweenService:Create(d, gone, { BackgroundTransparency = 1 }):Play()
				end
			end
		end
		if blur then
			TweenService:Create(blur, gone, { Size = 0 }):Play()
		end
		TweenService:Create(grade, gone, { Saturation = 0, Contrast = 0 }):Play()
		local target = handPoint()
		local flight = TweenService:Create(
			vp,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = target,
				Rotation = 25,
			}
		)
		TweenService:Create(
			vpScale,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Scale = 0.12 }
		):Play()
		TweenService
			:Create(glow, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = target,
				BackgroundTransparency = 1,
			})
			:Play()
		flight:Play()
		flight.Completed:Wait()
		sparkles(
			TIER_ACCENT[tier],
			16,
			UDim2.fromScale(
				target.X.Offset / screen.AbsoluteSize.X,
				target.Y.Offset / screen.AbsoluteSize.Y
			)
		)
		TweenService:Create(vp, TweenInfo.new(0.15), { ImageTransparency = 1 }):Play()
		task.wait(0.15)
	end

	------------------------------------------------------------------ fade out + restore
	local fade = TweenInfo.new(0.25)
	for _, d in screen:GetDescendants() do
		if d:IsA("TextLabel") then
			TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, fade, { Transparency = 1 }):Play()
		elseif d:IsA("Frame") then
			TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
		elseif d:IsA("ViewportFrame") then
			TweenService:Create(d, fade, { ImageTransparency = 1 }):Play()
		end
	end
	if blur then
		TweenService:Create(blur, fade, { Size = 0 }):Play()
	end
	TweenService:Create(grade, fade, { Saturation = 0, Contrast = 0 }):Play()
	task.wait(0.28)
	beat:Disconnect()
	screen:Destroy()
	if blur then
		blur:Destroy()
	end
	grade:Destroy()
end

return CatchShow
