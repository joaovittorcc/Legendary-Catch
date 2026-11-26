--!strict
-- Catch roulette (docs/PLANO-ROLETA.md): replays the spins the SERVER already rolled (payload
-- `spins`) as a "case opening" reel of big, vivid cards that slides fast and brakes with
-- suspense on the result. Size / shrink / mutation open their own reel; "spin again" spins the
-- main one again. A gold chip at the bottom adds up the effect. Tap = speed up.
--
-- Screen effects (all restored at the end): soft blur + saturated colour correction while it
-- runs, a coloured backdrop with spinning rays per wheel, flash + FOV punch + shockwave ring on
-- big results, confetti on good ones, grey drop on bad ones. A glowing selector box pulses
-- each time a card passes the centre. "ReduceEffects" keeps colours and the reel but drops
-- blur, flash, shake, FOV punch and confetti.
--
-- play(update) yields until done. Detailed first, optimise later.

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

local Roulette = {}

export type Update = {
	spins: { { wheel: string, result: string } }?,
	sizeMult: number?,
	mutation: string?,
	coinMult: number?,
}

local player = Players.LocalPlayer
local INK = Theme.ink
local WHITE = Color3.new(1, 1, 1)
local CARDS = 44
local TARGET = 38
local CARD_W = 0.25 -- fraction of the window width per card
local SPIN_TIME = { main = 2.1, size = 2.5, worse = 1.8, mutation = 3.0 }
local RAY_COUNT = 10
local CONFETTI_MAX = 90

-- Backdrop / title colour per wheel.
local WHEEL_COLOR: { [string]: Color3 } = {
	main = Color3.fromRGB(255, 196, 40),
	size = Color3.fromRGB(40, 170, 255),
	worse = Color3.fromRGB(235, 60, 80),
	mutation = Color3.fromRGB(190, 80, 255),
}
local BACKDROP: { [string]: Color3 } = {
	main = Color3.fromRGB(255, 120, 40),
	size = Color3.fromRGB(20, 90, 220),
	worse = Color3.fromRGB(90, 20, 40),
	mutation = Color3.fromRGB(110, 30, 200),
}
-- Size cards: a vivid ladder (blue, cyan, green, yellow, orange, magenta, rainbow).
local SIZE_COLORS: { [string]: Color3 } = {
	x2 = Color3.fromRGB(60, 150, 255),
	x3 = Color3.fromRGB(30, 215, 235),
	x5 = Color3.fromRGB(70, 225, 110),
	x10 = Color3.fromRGB(255, 215, 40),
	x25 = Color3.fromRGB(255, 140, 30),
	x50 = Color3.fromRGB(255, 70, 190),
	x100 = Color3.fromRGB(255, 255, 255),
}
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 120)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(80, 235, 130)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(60, 190, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(170, 100, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 200)),
})
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 80, 120),
	Color3.fromRGB(255, 210, 60),
	Color3.fromRGB(80, 235, 130),
	Color3.fromRGB(60, 190, 255),
	Color3.fromRGB(180, 100, 255),
	WHITE,
}

local function num(n: number): string
	local text = if n == math.floor(n) then tostring(n) else string.format("%.1f", n)
	return (text:gsub("%.", Strings.decimalSep))
end

local function entryOf(wheel: string, id: string): RouletteConfig.Entry?
	for _, e in RouletteConfig.wheel(wheel) do
		if e.id == id then
			return e
		end
	end
	return nil
end

local function cardLabel(wheel: string, id: string): (string, string)
	local r = Strings.roulette
	if wheel == "size" or wheel == "worse" then
		local e = entryOf(wheel, id)
		return "x" .. num(if e then e.mult else 1),
			if wheel == "size" then r.card.size else r.card.worse
	elseif wheel == "mutation" then
		local e = entryOf(wheel, id)
		return r.card[id] or id, string.format(r.coins, num(if e then e.mult else 1))
	end
	return r.card[id] or id, ""
end

local function cardColor(wheel: string, id: string): Color3
	if wheel == "size" then
		return SIZE_COLORS[id] or WHITE
	elseif wheel == "worse" then
		return if id == "x0.4"
			then Color3.fromRGB(150, 30, 50)
			elseif id == "x0.6" then Color3.fromRGB(205, 45, 70)
			else Color3.fromRGB(245, 85, 95)
	end
	return RouletteConfig.COLORS[id] or WHITE
end

-- "Big" results get the full show (flash, FOV punch, shockwave, confetti).
local function isBig(wheel: string, id: string): boolean
	if wheel == "size" then
		local e = entryOf(wheel, id)
		return e ~= nil and e.mult >= 10
	elseif wheel == "mutation" then
		return RouletteConfig.mutationRank(id) >= 4
	end
	return false
end

local function isGood(wheel: string, id: string): boolean
	return wheel == "size"
		or wheel == "mutation"
		or id == "size"
		or id == "mutation"
		or id == "again"
end

local function label(
	parent: Instance,
	text: string,
	color: Color3,
	size: UDim2,
	pos: UDim2,
	stroke: number,
	z: number
): TextLabel
	local t = Instance.new("TextLabel")
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.BackgroundTransparency = 1
	t.Font = Theme.font
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	t.Size = size
	t.Position = pos
	t.ZIndex = z
	local s = Instance.new("UIStroke")
	s.Color = INK
	s.Thickness = stroke
	s.Parent = t
	t.Parent = parent
	return t
end

local function scaleOf(target: Instance): UIScale
	local found = target:FindFirstChildOfClass("UIScale")
	if found then
		return found
	end
	local s = Instance.new("UIScale")
	s.Parent = target
	return s
end

local function pop(target: Instance, from: number, to: number, time: number)
	local s = scaleOf(target)
	s.Scale = from
	TweenService
		:Create(
			s,
			TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = to }
		)
		:Play()
end

export type Card = { frame: Frame, shine: UIGradient, spin: UIGradient?, phase: number }

local function makeCard(parent: Instance, wheel: string, id: string, index: number): Card
	local card = Instance.new("Frame")
	card.Name = id
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.fromScale(CARD_W * 0.9, 0.84)
	card.Position = UDim2.fromScale(CARD_W * (index - 0.5), 0.5)
	local color = cardColor(wheel, id)
	card.BackgroundColor3 = color
	card.BorderSizePixel = 0
	card.ZIndex = 5
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.16, 0)
	c.Parent = card
	local s = Instance.new("UIStroke")
	s.Color = UiAssets.OUTLINE
	s.Thickness = 4
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = card
	local glossTop = Instance.new("Frame")
	glossTop.Name = "CandyDome"
	glossTop.AnchorPoint = Vector2.new(0.5, 0)
	glossTop.Position = UDim2.new(0.5, 0, 0, 4)
	glossTop.Size = UDim2.fromScale(0.86, 0.28)
	glossTop.BackgroundColor3 = WHITE
	glossTop.BackgroundTransparency = 0.56
	glossTop.BorderSizePixel = 0
	glossTop.ZIndex = 5
	local gc = Instance.new("UICorner")
	gc.CornerRadius = UDim.new(0.45, 0)
	gc.Parent = glossTop
	glossTop.Parent = card
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	local spin: UIGradient? = nil
	if id == "rainbow" or id == "x100" then
		g.Color = RAINBOW
		g.Rotation = 0
		spin = g
	elseif id == "cosmic" then
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 80, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 10, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 220, 255)),
		})
		spin = g
	elseif id == "diamond" then
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 235, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 190, 255)),
		})
		spin = g
	else
		g.Color = ColorSequence.new(color:Lerp(WHITE, 0.35), color:Lerp(INK, 0.15))
	end
	g.Parent = card
	-- Moving shine stripe across the card.
	local shineFrame = Instance.new("Frame")
	shineFrame.Size = UDim2.fromScale(1, 1)
	shineFrame.BackgroundColor3 = WHITE
	shineFrame.BorderSizePixel = 0
	shineFrame.ZIndex = 5
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0.16, 0)
	sc.Parent = shineFrame
	local shine = Instance.new("UIGradient")
	shine.Rotation = 25
	shine.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	shine.Parent = shineFrame
	shineFrame.Parent = card
	local main, sub = cardLabel(wheel, id)
	local textColor = if id == "x100" or id == "diamond" then INK else WHITE
	local mainLabel = label(
		card,
		main,
		textColor,
		UDim2.fromScale(0.9, 0.38),
		UDim2.fromScale(0.5, if sub ~= "" then 0.42 else 0.5),
		3,
		6
	)
	if textColor == INK then
		local st = mainLabel:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = WHITE
		end
	end
	if sub ~= "" then
		label(card, sub, WHITE, UDim2.fromScale(0.85, 0.18), UDim2.fromScale(0.5, 0.76), 2, 6)
	end
	card.Parent = parent
	return { frame = card, shine = shine, spin = spin, phase = (index % 5) * 0.4 }
end

-- Plays the whole roulette and returns when finished.
function Roulette.play(update: Update)
	local spins = update.spins
	if not spins or #spins == 0 then
		return
	end
	local reduce = player:GetAttribute("ReduceEffects") == true
	local state = { fast = false }
	local camera = Workspace.CurrentCamera

	------------------------------------------------------------------ screen effects
	local blur: BlurEffect? = nil
	local grade: ColorCorrectionEffect? = nil
	if not reduce then
		local b = Instance.new("BlurEffect")
		b.Name = "RouletteBlur"
		b.Size = 0
		b.Parent = Lighting
		TweenService:Create(b, TweenInfo.new(0.35), { Size = 10 }):Play()
		blur = b
	end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "RouletteGrade"
	cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(0.35), { Saturation = 0.35, Contrast = 0.08 }):Play()
	grade = cc

	------------------------------------------------------------------ layout
	local screen = Instance.new("ScreenGui")
	screen.Name = "Roulette"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 21
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = BACKDROP.main
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

	-- Spinning rays behind the reel.
	local rayHolder = Instance.new("Frame")
	rayHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	rayHolder.Position = UDim2.fromScale(0.5, 0.47)
	rayHolder.Size = UDim2.fromScale(2.2, 2.2)
	rayHolder.BackgroundTransparency = 1
	rayHolder.ZIndex = 2
	local sq = Instance.new("UIAspectRatioConstraint")
	sq.DominantAxis = Enum.DominantAxis.Height
	sq.Parent = rayHolder
	rayHolder.Parent = screen
	local rays: { Frame } = {}
	for _ = 1, RAY_COUNT do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.Size = UDim2.fromScale(0.08, 1)
		ray.BackgroundColor3 = WHITE
		ray.BackgroundTransparency = 0.82
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

	-- Coloured glow behind the frame.
	local glow = Instance.new("Frame")
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.48)
	glow.Size = UDim2.fromScale(1.05, 0.5)
	glow.BackgroundColor3 = WHEEL_COLOR.main
	glow.BackgroundTransparency = 0.35
	glow.BorderSizePixel = 0
	glow.ZIndex = 2
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0.5, 0)
	glowCorner.Parent = glow
	local gg = Instance.new("UIGradient")
	gg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	gg.Parent = glow
	glow.Parent = screen

	-- Reel frame: plump 3D cartoon gold/plum candy frame + inner window.
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.48)
	frame.Size = UDim2.fromScale(0.94, 0.27)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
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
	limit.MaxSize = Vector2.new(840, 250)
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

	-- Selector: glowing box in the centre (no line over the text) + two arrows.
	local selector = Instance.new("Frame")
	selector.Name = "Selector"
	selector.AnchorPoint = Vector2.new(0.5, 0.5)
	selector.Position = UDim2.fromScale(0.5, 0.5)
	selector.Size = UDim2.fromScale(CARD_W * 0.98, 0.98)
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

	-- Title, chip footer, hint.
	local title = label(
		screen,
		Strings.roulette.title.main,
		WHITE,
		UDim2.fromScale(0.86, 0.09),
		UDim2.fromScale(0.5, 0.27),
		5,
		12
	)
	local titleGradient = Instance.new("UIGradient")
	titleGradient.Rotation = 90
	titleGradient.Color = ColorSequence.new(WHITE, WHEEL_COLOR.main)
	titleGradient.Parent = title
	local chip = Instance.new("Frame")
	chip.AnchorPoint = Vector2.new(0.5, 0.5)
	chip.Position = UDim2.fromScale(0.5, 0.685)
	chip.Size = UDim2.fromScale(0.7, 0.07)
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
	chipLimit.MaxSize = Vector2.new(640, 70)
	chipLimit.Parent = chip
	chip.Parent = screen
	local footer =
		label(chip, "", WHITE, UDim2.new(1, -24, 0.8, 0), UDim2.fromScale(0.5, 0.5), 3, 12)
	local hint = label(
		screen,
		Strings.roulette.skip,
		WHITE,
		UDim2.fromScale(0.42, 0.032),
		UDim2.fromScale(0.5, 0.93),
		2,
		12
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
	TweenService:Create(backdrop, TweenInfo.new(0.25), { BackgroundTransparency = 0.25 }):Play()
	pop(frame, 0.55, 1, 0.4)
	pop(title, 0.3, 1, 0.4)

	------------------------------------------------------------------ per-frame life
	type Piece = { frame: Frame, x: number, y: number, vy: number, vx: number, spin: number }
	local pieces: { Piece } = {}
	local cards: { Card } = {}
	local strip: Frame? = nil
	local lastCenter = 0
	local raySpeed = 14
	local t0 = os.clock()
	local function confetti(count: number, fromCentre: boolean)
		if reduce then
			return
		end
		for _ = 1, count do
			if #pieces >= CONFETTI_MAX then
				return
			end
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Size = UDim2.fromOffset(math.random(8, 16), math.random(4, 9))
			f.BackgroundColor3 = CONFETTI_COLORS[math.random(1, #CONFETTI_COLORS)]
			f.BorderSizePixel = 0
			f.ZIndex = 20
			f.Parent = screen
			table.insert(pieces, {
				frame = f,
				x = if fromCentre then 0.5 else math.random(),
				y = if fromCentre then 0.47 else -0.05,
				vx = if fromCentre then (math.random() - 0.5) * 1.2 else 0,
				vy = if fromCentre then -0.5 - math.random() * 0.7 else 0.2 + math.random() * 0.3,
				spin = (math.random() - 0.5) * 700,
			})
		end
	end
	local beat = RunService.RenderStepped:Connect(function(dt: number)
		local t = os.clock() - t0
		for i, ray in rays do
			ray.Rotation = (i - 1) * (180 / RAY_COUNT) + (if reduce then 0 else t * raySpeed)
		end
		-- selector glow pulse
		selStroke.Thickness = 4 + math.abs(math.sin(t * 5)) * 2
		rimGradient.Rotation = (t * 60) % 360
		-- card shine + animated gradients
		for _, card in cards do
			card.shine.Offset = Vector2.new(((t * 0.8 + card.phase) % 2) - 1, 0)
			if card.spin then
				card.spin.Rotation = (t * 90) % 360
			end
		end
		-- tick: the card under the selector changed -> arrows bump
		local s = strip
		if s then
			local x = s.Position.X.Scale
			local centre = math.floor((0.5 - x) / CARD_W + 0.5)
			if centre ~= lastCenter then
				lastCenter = centre
				for _, arrow in arrows do
					pop(arrow, 1.35, 1, 0.12)
				end
			end
		end
		-- confetti
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
	end)

	local function setWheel(wheel: string)
		local color = WHEEL_COLOR[wheel] or WHITE
		title.Text = Strings.roulette.title[wheel] or ""
		titleGradient.Color = if wheel == "mutation"
			then RAINBOW
			else ColorSequence.new(WHITE, color)
		TweenService:Create(
			backdrop,
			TweenInfo.new(0.35),
			{ BackgroundColor3 = BACKDROP[wheel] or BACKDROP.main }
		):Play()
		TweenService:Create(glow, TweenInfo.new(0.35), { BackgroundColor3 = color }):Play()
		selStroke.Color = color:Lerp(WHITE, 0.3)
		for _, arrow in arrows do
			arrow.BackgroundColor3 = color:Lerp(WHITE, 0.2)
		end
		raySpeed = if wheel == "mutation" then 40 elseif wheel == "size" then 28 else 14
		pop(title, 0.4, 1, 0.3)
	end

	local function punch(color: Color3, big: boolean)
		if reduce then
			return
		end
		flash.BackgroundColor3 = color:Lerp(WHITE, 0.5)
		flash.BackgroundTransparency = if big then 0.35 else 0.7
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
			-- Shockwave ring.
			local ring = Instance.new("Frame")
			ring.AnchorPoint = Vector2.new(0.5, 0.5)
			ring.Position = UDim2.fromScale(0.5, 0.48)
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
			-- Shake the reel.
			task.spawn(function()
				local base = frame.Position
				for i = 1, 12 do
					local m = math.max(1, math.floor(8 * (1 - i / 12)))
					frame.Position = base + UDim2.fromOffset(math.random(-m, m), math.random(-m, m))
					task.wait(0.02)
				end
				frame.Position = base
			end)
		end
	end

	local function sparkles(color: Color3, count: number)
		if reduce then
			return
		end
		for _ = 1, count do
			local p = Instance.new("Frame")
			p.AnchorPoint = Vector2.new(0.5, 0.5)
			p.Position = UDim2.fromScale(0.5, 0.48)
			p.Size = UDim2.fromOffset(14, 14)
			p.Rotation = math.random(0, 90)
			p.BackgroundColor3 = color:Lerp(WHITE, math.random() * 0.6)
			p.BorderSizePixel = 0
			p.ZIndex = 21
			p.Parent = screen
			local a = math.random() * math.pi * 2
			local d = 0.18 + math.random() * 0.3
			local tw = TweenService:Create(
				p,
				TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = UDim2.fromScale(0.5 + math.cos(a) * d, 0.48 + math.sin(a) * d * 1.4),
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

	------------------------------------------------------------------ one reel
	local function runReel(wheel: string, result: string)
		setWheel(wheel)
		local s = Instance.new("Frame")
		s.Name = "Strip"
		s.BackgroundTransparency = 1
		s.Size = UDim2.fromScale(1, 1)
		s.ZIndex = 5
		s.Parent = window
		table.clear(cards)
		local entries = RouletteConfig.wheel(wheel)
		for i = 1, CARDS do
			local id = if i == TARGET
				then result
				else RouletteConfig.pick(entries, math.random()).id
			table.insert(cards, makeCard(s, wheel, id, i))
		end
		local finalX = 0.5 - CARD_W * (TARGET - 0.5)
		local landX = finalX + (math.random() - 0.5) * CARD_W * 0.6
		s.Position = UDim2.fromScale(0.5 - CARD_W * 2.5, 0)
		strip = s
		local time = if state.fast then 0.35 else (SPIN_TIME :: any)[wheel] or 2
		local tween = TweenService:Create(
			s,
			TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromScale(landX, 0),
			}
		)
		tween:Play()
		local started = os.clock()
		while tween.PlaybackState == Enum.PlaybackState.Playing do
			if state.fast and os.clock() - started < time - 0.05 then
				tween:Cancel()
				s.Position = UDim2.fromScale(landX, 0)
				break
			end
			task.wait()
		end
		TweenService:Create(
			s,
			TweenInfo.new(0.2, Enum.EasingStyle.Back),
			{ Position = UDim2.fromScale(finalX, 0) }
		):Play()
		task.wait(0.2)
		strip = nil

		-- Result: pop the card, dim the others, effects by outcome.
		local card = cards[TARGET].frame
		for i, other in cards do
			if i ~= TARGET then
				TweenService
					:Create(other.frame, TweenInfo.new(0.2), { BackgroundTransparency = 0.65 })
					:Play()
			end
		end
		card.ZIndex = 7
		pop(card, 1, 1.26, 0.3)
		local color = cardColor(wheel, result)
		local big = isBig(wheel, result)
		local bad = wheel == "worse" or result == "worse" or result == "nothing"
		if bad then
			-- Grey/red drop: card sinks a little, cooler grade for a moment.
			TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Bounce), {
				Position = card.Position + UDim2.fromScale(0, 0.06),
			}):Play()
			if grade then
				TweenService:Create(grade, TweenInfo.new(0.3), { Saturation = -0.1 }):Play()
				task.delay(0.6, function()
					if grade and grade.Parent then
						TweenService:Create(grade, TweenInfo.new(0.3), { Saturation = 0.35 }):Play()
					end
				end)
			end
		else
			punch(color, big)
			sparkles(color, if big then 34 elseif isGood(wheel, result) then 18 else 8)
			if wheel ~= "main" then
				confetti(if big then 50 else 16, true)
			end
		end
		if result == "again" then
			title.Text = Strings.roulette.again
			pop(title, 0.5, 1.15, 0.3)
		end
		task.wait(if state.fast then 0.25 else 0.65)
		s:Destroy()
		table.clear(cards)
	end

	task.wait(0.25)
	local size, mutationName = 1, nil :: string?
	for _, spin in spins do
		runReel(spin.wheel, spin.result)
		if spin.wheel == "size" or spin.wheel == "worse" then
			local e = entryOf(spin.wheel, spin.result)
			size *= if e then e.mult else 1
		elseif spin.wheel == "mutation" then
			mutationName = Strings.roulette.card[spin.result] or spin.result
		end
		local parts = {}
		if size ~= 1 then
			table.insert(parts, string.format(Strings.roulette.size, num(size)))
		end
		if mutationName then
			table.insert(parts, string.format(Strings.roulette.mutation, mutationName))
		end
		if #parts > 0 then
			footer.Text = table.concat(parts, "  ·  ")
			chip.BackgroundTransparency = 0.15
			chs.Transparency = 0
			pop(chip, 0.7, 1, 0.25)
		end
	end

	-- Final chip: total coins (counts up) or "nothing happened".
	local coin = update.coinMult or 1
	chip.BackgroundTransparency = 0.15
	chs.Transparency = 0
	if math.abs(coin - 1) < 0.001 then
		footer.Text = Strings.roulette.nothing
		footer.TextColor3 = Color3.fromRGB(205, 210, 225)
		pop(chip, 0.7, 1, 0.25)
		task.wait(if state.fast then 0.4 else 0.8)
	else
		local prefix = if footer.Text ~= "" then footer.Text .. "  ·  " else ""
		footer.TextColor3 = if coin > 1 then Theme.gold else Color3.fromRGB(255, 150, 150)
		chs.Color = if coin > 1 then Theme.gold else Color3.fromRGB(255, 110, 120)
		local steps = if state.fast then 1 else 14
		for i = 1, steps do
			local v = 1 + (coin - 1) * (i / steps)
			footer.Text = prefix
				.. string.format(Strings.roulette.coins, num(math.floor(v * 10 + 0.5) / 10))
			pop(chip, 1.08, 1, 0.08)
			task.wait(0.035)
		end
		pop(chip, 1.3, 1.08, 0.3)
		if coin >= 5 then
			confetti(40, true)
			punch(Theme.gold, true)
		end
		task.wait(if state.fast then 0.5 else 1.1)
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
		end
	end
	if blur then
		TweenService:Create(blur, fade, { Size = 0 }):Play()
	end
	if grade then
		TweenService:Create(grade, fade, { Saturation = 0, Contrast = 0 }):Play()
	end
	task.wait(0.28)
	beat:Disconnect()
	screen:Destroy()
	if blur then
		blur:Destroy()
	end
	if grade then
		grade:Destroy()
	end
end

-- Building blocks shared with CatchShow (silhouette + reels + final odds in one screen).
Roulette.kit = {
	makeCard = makeCard,
	cardColor = cardColor,
	entryOf = entryOf,
	num = num,
	label = label,
	pop = pop,
	scaleOf = scaleOf,
	isBig = isBig,
	isGood = isGood,
	WHEEL_COLOR = WHEEL_COLOR,
	BACKDROP = BACKDROP,
	SPIN_TIME = SPIN_TIME,
	CARD_W = CARD_W,
	CARDS = CARDS,
	TARGET = TARGET,
	RAINBOW = RAINBOW,
	CONFETTI_COLORS = CONFETTI_COLORS,
	CONFETTI_MAX = CONFETTI_MAX,
	RAY_COUNT = RAY_COUNT,
}

return Roulette
