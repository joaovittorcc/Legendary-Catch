--!strict
-- "Odds moment" (docs/PLANO-VISUAL-REFERENCIA.md §3): between winning the fight and the reveal,
-- the real "1 in N" of the catch (server payload `odds`) counts up through tiers. Each tier
-- changes the word, the background colour and the energy (spinning rays, confetti, flash,
-- shake), while the creature's black silhouette grows and its name fills in letter by letter.
--
-- play(info) yields until the moment ends (or is skipped with a tap). Detailed first,
-- optimise later; "ReduceEffects" removes flash and shake, freezes the rays and thins confetti.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local OddsMoment = {}

export type Info = {
	creatureId: string,
	odds: number,
	short: boolean?, -- true when a long reveal cinematic follows (Legendary/Mystic): cap the time
}

-- Tier thresholds ("1 in N" up to and including) and per-tier look.
local THRESHOLDS = { 50, 150, 500, 2000, 10000, 50000, math.huge }
local BG = {
	Color3.fromRGB(32, 196, 168),
	Color3.fromRGB(42, 118, 232),
	Color3.fromRGB(118, 58, 214),
	Color3.fromRGB(226, 58, 168),
	Color3.fromRGB(236, 150, 28),
	Color3.fromRGB(196, 28, 84),
	Color3.fromRGB(14, 8, 34),
}
local ACCENT = {
	Color3.fromRGB(190, 255, 230),
	Color3.fromRGB(160, 220, 255),
	Color3.fromRGB(220, 180, 255),
	Color3.fromRGB(255, 190, 235),
	Color3.fromRGB(255, 236, 140),
	Color3.fromRGB(255, 150, 120),
	Color3.fromRGB(120, 255, 250),
}
local DURATION = { 0.9, 1.4, 2.0, 2.8, 3.8, 5.0, 8.0 }
local SHORT_CAP = 4
local SILHOUETTE_SCALE = { 0.55, 0.65, 0.75, 0.88, 1.0, 1.15, 1.35 }
local CONFETTI_RATE = { 0, 8, 16, 26, 38, 52, 72 } -- pieces per second
local CONFETTI_MAX = 110
local RAY_COUNT = 12
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 90, 120),
	Color3.fromRGB(255, 210, 70),
	Color3.fromRGB(90, 230, 140),
	Color3.fromRGB(80, 190, 255),
	Color3.fromRGB(190, 110, 255),
	Color3.fromRGB(255, 255, 255),
}

local player = Players.LocalPlayer
local INK = Theme.ink
local WHITE = Color3.new(1, 1, 1)

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

-- "Bolhinha Azul" with k letters shown -> "Bol_____ ____" (spaces kept).
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

local function text(
	parent: Instance,
	value: string,
	color: Color3,
	size: UDim2,
	pos: UDim2,
	z: number
): TextLabel
	local t = Instance.new("TextLabel")
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.BackgroundTransparency = 1
	t.Font = Theme.font
	t.TextScaled = true
	t.Text = value
	t.TextColor3 = color
	t.Size = size
	t.Position = pos
	t.ZIndex = z
	local s = Instance.new("UIStroke")
	s.Color = INK
	s.Thickness = 4
	s.Parent = t
	t.Parent = parent
	return t
end

local function pop(target: Instance, from: number, to: number, time: number)
	local found = target:FindFirstChildOfClass("UIScale")
	local s: UIScale
	if found then
		s = found
	else
		s = Instance.new("UIScale")
		s.Parent = target
	end
	s.Scale = from
	TweenService
		:Create(
			s,
			TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = to }
		)
		:Play()
end

-- Silhouette: the real creature model in a ViewportFrame tinted black, facing the camera (+Z).
local function buildSilhouette(parent: Instance, creatureId: string): (ViewportFrame, Model?)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Silhouette"
	vp.AnchorPoint = Vector2.new(0.5, 0.5)
	vp.Position = UDim2.fromScale(0.5, 0.5)
	vp.Size = UDim2.fromScale(0.62, 0.36)
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

-- Plays the moment and returns when it is over.
function OddsMoment.play(info: Info)
	local odds = math.max(1, math.floor(info.odds))
	local finalTier = tierOf(odds)
	local reduce = player:GetAttribute("ReduceEffects") == true
	local duration = DURATION[finalTier]
	if info.short then
		duration = math.min(duration, SHORT_CAP)
	end
	local name = (Strings.creatureName :: any)[info.creatureId] or info.creatureId
	local letters = letterCount(name)

	local screen = Instance.new("ScreenGui")
	screen.Name = "OddsMoment"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 20
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	-- Slightly oversized and centred so the shake never shows the world at the edges.
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.fromScale(0.5, 0.5)
	bg.Size = UDim2.fromScale(1.08, 1.08)
	bg.BackgroundColor3 = BG[1]
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.ZIndex = 1
	bg.Parent = screen
	-- Soft top/bottom shade so the text pops.
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.55, 0.55, 0.55)),
		ColorSequenceKeypoint.new(0.45, WHITE),
		ColorSequenceKeypoint.new(1, Color3.new(0.45, 0.45, 0.45)),
	})
	shade.Parent = bg

	-- Spinning rays: thin bars through the centre, soft at the ends.
	local rayHolder = Instance.new("Frame")
	rayHolder.Name = "Rays"
	rayHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	rayHolder.Position = UDim2.fromScale(0.5, 0.47)
	rayHolder.Size = UDim2.fromScale(2.4, 2.4)
	rayHolder.BackgroundTransparency = 1
	rayHolder.ZIndex = 2
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.DominantAxis = Enum.DominantAxis.Height
	square.Parent = rayHolder
	rayHolder.Parent = screen
	local rays: { Frame } = {}
	for i = 1, RAY_COUNT do
		local ray = Instance.new("Frame")
		ray.AnchorPoint = Vector2.new(0.5, 0.5)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.Size = UDim2.fromScale(0.07, 1)
		ray.Rotation = (i - 1) * (180 / RAY_COUNT)
		ray.BackgroundColor3 = WHITE
		ray.BackgroundTransparency = 1
		ray.BorderSizePixel = 0
		ray.ZIndex = 2
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 0.55),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(0.58, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = ray
		ray.Parent = rayHolder
		table.insert(rays, ray)
	end

	-- Glow disc behind the silhouette.
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(0.5, 0.5)
	glow.BackgroundColor3 = ACCENT[1]
	glow.BackgroundTransparency = 0.55
	glow.BorderSizePixel = 0
	glow.ZIndex = 4
	local glowAspect = Instance.new("UIAspectRatioConstraint")
	glowAspect.Parent = glow
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0.5, 0)
	glowCorner.Parent = glow
	local glowGradient = Instance.new("UIGradient")
	glowGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowGradient.Parent = glow
	glow.Parent = screen

	local vp, model = buildSilhouette(screen, info.creatureId)
	local vpScale = Instance.new("UIScale")
	vpScale.Scale = SILHOUETTE_SCALE[1] * 0.6
	vpScale.Parent = vp
	if not model then
		text(vp, "?", WHITE, UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.5, 0.5), 7)
	end

	-- Texts.
	local word = text(
		screen,
		Strings.oddsTier[1],
		ACCENT[1],
		UDim2.fromScale(0.8, 0.07),
		UDim2.fromScale(0.5, 0.13),
		10
	)
	local wordGradient = Instance.new("UIGradient")
	wordGradient.Rotation = 90
	wordGradient.Parent = word
	local counter = text(
		screen,
		string.format(Strings.oddsOneIn, "1"),
		WHITE,
		UDim2.fromScale(0.9, 0.09),
		UDim2.fromScale(0.5, 0.215),
		10
	)
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 110
	cap.Parent = counter
	local growing = text(
		screen,
		Strings.oddsGrowing,
		WHITE,
		UDim2.fromScale(0.5, 0.035),
		UDim2.fromScale(0.5, 0.7),
		10
	)
	local nameLabel = text(
		screen,
		partialName(name, 0),
		WHITE,
		UDim2.fromScale(0.85, 0.075),
		UDim2.fromScale(0.5, 0.79),
		10
	)
	local skipLabel = text(
		screen,
		Strings.oddsSkip,
		WHITE,
		UDim2.fromScale(0.4, 0.028),
		UDim2.fromScale(0.5, 0.95),
		10
	)
	skipLabel.TextTransparency = 0.35

	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = WHITE
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 30
	flash.Parent = screen

	local skipped = false
	local tap = Instance.new("TextButton")
	tap.Size = UDim2.fromScale(1, 1)
	tap.BackgroundTransparency = 1
	tap.Text = ""
	tap.ZIndex = 40
	tap.Parent = screen
	tap.Activated:Connect(function()
		skipped = true
	end)

	screen.Parent = player:WaitForChild("PlayerGui")
	TweenService:Create(bg, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
	pop(vp, 0.3, 1, 0.4)
	TweenService
		:Create(vpScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = SILHOUETTE_SCALE[1] })
		:Play()
	pop(word, 0.2, 1, 0.35)

	-- Per-frame life: rays spin, confetti falls, silhouette sways, "GROWING..." blinks.
	local tier = 1
	local rayAlpha = 0.85
	local raySpeed = 10
	type Piece = {
		frame: Frame,
		x: number,
		y: number,
		vy: number,
		sway: number,
		phase: number,
		spin: number,
	}
	local pieces: { Piece } = {}
	local spawnDebt = 0
	local t0 = os.clock()
	local shakeUntil = 0
	local function spawnPiece(burstMode: boolean)
		if #pieces >= CONFETTI_MAX then
			return
		end
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromOffset(math.random(8, 15), math.random(4, 8))
		f.BackgroundColor3 = CONFETTI_COLORS[math.random(1, #CONFETTI_COLORS)]
		f.BorderSizePixel = 0
		f.ZIndex = 12
		f.Parent = screen
		table.insert(pieces, {
			frame = f,
			x = if burstMode then 0.5 + (math.random() - 0.5) * 0.3 else math.random(),
			y = if burstMode then 0.45 else -0.05,
			vy = if burstMode then -0.6 - math.random() * 0.5 else 0.22 + math.random() * 0.28,
			sway = 0.02 + math.random() * 0.04,
			phase = math.random() * 6,
			spin = (math.random() - 0.5) * 600,
		})
	end
	local fading = false
	local beat = RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - t0
		if not reduce then
			for i, ray in rays do
				ray.Rotation = (i - 1) * (180 / RAY_COUNT) + t * raySpeed
			end
		end
		if not fading then
			for _, ray in rays do
				ray.BackgroundTransparency = rayAlpha
			end
			growing.TextTransparency = 0.25 + math.abs(math.sin(t * 3)) * 0.5
		end
		if model then
			model:PivotTo(CFrame.Angles(0, math.sin(t * 0.9) * 0.45, math.sin(t * 1.7) * 0.05))
		end
		-- confetti
		local rate = CONFETTI_RATE[tier] * (if reduce then 0.3 else 1)
		spawnDebt += rate * dt
		while spawnDebt >= 1 do
			spawnDebt -= 1
			spawnPiece(false)
		end
		for i = #pieces, 1, -1 do
			local p = pieces[i]
			p.vy = math.min(p.vy + dt * 0.9, 0.55)
			p.y += p.vy * dt
			p.x += math.sin(t * 3 + p.phase) * p.sway * dt * 6
			p.frame.Position = UDim2.fromScale(p.x, p.y)
			p.frame.Rotation += p.spin * dt
			if p.y > 1.1 then
				p.frame:Destroy()
				table.remove(pieces, i)
			end
		end
		-- shake
		if not reduce and os.clock() < shakeUntil then
			local m = 6
			bg.Position = UDim2.new(0.5, math.random(-m, m), 0.5, math.random(-m, m))
			vp.Position = UDim2.new(0.5, math.random(-m, m), 0.5, math.random(-m, m))
		else
			bg.Position = UDim2.fromScale(0.5, 0.5)
			vp.Position = UDim2.fromScale(0.5, 0.5)
		end
	end)

	local function enterTier(newTier: number)
		tier = newTier
		TweenService:Create(bg, TweenInfo.new(0.3), { BackgroundColor3 = BG[newTier] }):Play()
		TweenService:Create(glow, TweenInfo.new(0.3), { BackgroundColor3 = ACCENT[newTier] }):Play()
		TweenService:Create(
			vpScale,
			TweenInfo.new(0.35, Enum.EasingStyle.Back),
			{ Scale = SILHOUETTE_SCALE[newTier] }
		):Play()
		word.Text = Strings.oddsTier[newTier]
		word.TextColor3 = WHITE
		wordGradient.Color = ColorSequence.new(WHITE, ACCENT[newTier])
		if newTier == 7 then
			wordGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 110, 200)),
				ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 230, 120)),
				ColorSequenceKeypoint.new(0.7, Color3.fromRGB(120, 255, 240)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 130, 255)),
			})
		end
		pop(word, 0.3, 1, 0.35)
		rayAlpha = math.max(0.35, 0.85 - newTier * 0.07)
		raySpeed = 10 + newTier * 9
		if not reduce then
			if newTier >= 4 then
				flash.BackgroundTransparency = 0.45
				TweenService:Create(flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
					:Play()
			end
			if newTier >= 5 then
				shakeUntil = os.clock() + 0.25 + (newTier - 5) * 0.15
			end
			for _ = 1, 6 + newTier * 3 do
				spawnPiece(true)
			end
		end
	end

	-- Ticks: log-spaced values from 1 to the real odds, always landing on every tier border.
	local ticks: { number } = {}
	local baseCount = 6 + finalTier * 4
	for i = 1, baseCount do
		table.insert(ticks, odds ^ (i / baseCount))
	end
	-- Land on the first value of every tier below the final one, so each word gets its moment.
	for i = 1, finalTier - 1 do
		table.insert(ticks, THRESHOLDS[i] + 1)
	end
	table.sort(ticks)
	ticks[#ticks] = odds
	local tickCount = #ticks
	local shown = 1
	local startClock = os.clock()
	for i, value in ticks do
		if skipped then
			break
		end
		-- slightly slower towards the end (suspense)
		local at = startClock + duration * (i / tickCount) ^ 0.85
		while os.clock() < at and not skipped do
			task.wait()
		end
		shown = value
		counter.Text = string.format(Strings.oddsOneIn, grouped(value))
		pop(counter, 1.22, 1, 0.18)
		local newTier = tierOf(value)
		if newTier > tier then
			enterTier(newTier)
		end
		nameLabel.Text = partialName(name, math.floor(letters * (i / tickCount) * 0.85))
	end

	-- Final: exact odds, whole name, last burst.
	if tierOf(odds) > tier then
		enterTier(tierOf(odds))
	end
	if shown ~= odds or skipped then
		counter.Text = string.format(Strings.oddsOneIn, grouped(odds))
	end
	nameLabel.Text = name
	growing.Visible = false
	pop(counter, 1.45, 1, 0.3)
	pop(nameLabel, 1.3, 1, 0.3)
	if not reduce then
		for _ = 1, 16 + finalTier * 4 do
			spawnPiece(true)
		end
	end
	local hold = if skipped then 0.4 else 0.75
	task.wait(hold)

	-- Fade out (the reveal follows).
	fading = true
	local fade = TweenInfo.new(0.3)
	TweenService:Create(bg, fade, { BackgroundTransparency = 1 }):Play()
	for _, d in screen:GetDescendants() do
		if d:IsA("TextLabel") then
			TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, fade, { Transparency = 1 }):Play()
		elseif d:IsA("Frame") and d ~= bg then
			TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
		elseif d:IsA("ViewportFrame") then
			TweenService:Create(d, fade, { ImageTransparency = 1 }):Play()
		end
	end
	task.wait(0.32)
	beat:Disconnect()
	screen:Destroy()
end

return OddsMoment
