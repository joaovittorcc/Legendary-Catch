--!strict
-- Catch roulette (docs/PLANO-ROLETA.md): replays the spins the SERVER already rolled (payload
-- `spins`) as a "case opening" reel: a strip of big coloured cards slides fast and brakes with
-- suspense on the result card, which pops. Size / shrink / mutation open their own reel; "spin
-- again" spins the main one again. A footer adds up the effect. Tap = speed up.
--
-- play(update) yields until done. Detailed first, optimise later; "ReduceEffects" removes the
-- shake and the sparkles.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RouletteConfig = require(Shared:WaitForChild("Config"):WaitForChild("Roulette"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))

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
local CARDS = 42 -- cards on the strip
local TARGET = 36 -- index of the result card
local CARD_W = 0.25 -- fraction of the window width per card
local SPIN_TIME = { main = 2.0, size = 2.4, worse = 1.8, mutation = 2.8 }
local WHEEL_COLOR = {
	main = Color3.fromRGB(255, 205, 60),
	size = Color3.fromRGB(70, 170, 255),
	worse = Color3.fromRGB(240, 80, 90),
	mutation = Color3.fromRGB(196, 104, 255),
}
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 120)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 70)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 230, 140)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 190, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 110, 255)),
})

local function num(n: number): string
	local text = if n == math.floor(n) then tostring(n) else string.format("%.1f", n)
	return (text:gsub("%.", Strings.decimalSep))
end

local function cardLabel(wheel: string, id: string): (string, string)
	local r = Strings.roulette
	if wheel == "size" or wheel == "worse" then
		local e = nil
		for _, entry in RouletteConfig.wheel(wheel) do
			if entry.id == id then
				e = entry
			end
		end
		return "x" .. num(if e then e.mult else 1),
			if wheel == "size" then r.card.size else r.card.worse
	elseif wheel == "mutation" then
		local m = RouletteConfig.mutation(id)
		return r.card[id] or id, string.format(r.coins, num(if m then m.mult else 1))
	end
	return r.card[id] or id, ""
end

local function cardColor(wheel: string, id: string, index: number): Color3
	if wheel == "size" then
		-- deeper blue -> gold as the multiplier grows
		local list = RouletteConfig.SIZE
		for i, e in list do
			if e.id == id then
				return Color3.fromRGB(70, 170, 255)
					:Lerp(Color3.fromRGB(255, 200, 60), (i - 1) / (#list - 1))
			end
		end
	elseif wheel == "worse" then
		return Color3.fromRGB(240, 80, 90):Lerp(Color3.fromRGB(120, 40, 60), (index % 3) / 3)
	end
	return RouletteConfig.COLORS[id] or WHITE
end

local function label(
	parent: Instance,
	text: string,
	color: Color3,
	size: UDim2,
	pos: UDim2,
	stroke: number
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
	t.ZIndex = 8
	local s = Instance.new("UIStroke")
	s.Color = INK
	s.Thickness = stroke
	s.Parent = t
	t.Parent = parent
	return t
end

local function makeCard(parent: Instance, wheel: string, id: string, index: number): Frame
	local card = Instance.new("Frame")
	card.Name = id
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.new(CARD_W * 0.9, 0, 0.86, 0)
	card.Position = UDim2.new(CARD_W * (index - 0.5), 0, 0.5, 0)
	local color = cardColor(wheel, id, index)
	card.BackgroundColor3 = color
	card.BorderSizePixel = 0
	card.ZIndex = 5
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.14, 0)
	c.Parent = card
	local s = Instance.new("UIStroke")
	s.Color = WHITE
	s.Thickness = 3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = card
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	if id == "rainbow" then
		g.Color = RAINBOW
	elseif id == "cosmic" then
		g.Color = ColorSequence.new(Color3.fromRGB(110, 60, 200), Color3.fromRGB(10, 5, 30))
	else
		g.Color = ColorSequence.new(color:Lerp(WHITE, 0.3), color:Lerp(INK, 0.25))
	end
	g.Parent = card
	local main, sub = cardLabel(wheel, id)
	label(
		card,
		main,
		WHITE,
		UDim2.fromScale(0.9, 0.38),
		UDim2.fromScale(0.5, if sub ~= "" then 0.42 else 0.5),
		3
	).ZIndex =
		6
	if sub ~= "" then
		local st =
			label(card, sub, WHITE, UDim2.fromScale(0.85, 0.18), UDim2.fromScale(0.5, 0.75), 2)
		st.ZIndex = 6
	end
	card.Parent = parent
	return card
end

local function sparkles(parent: Instance, color: Color3, count: number)
	for _ = 1, count do
		local p = Instance.new("Frame")
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = UDim2.fromScale(0.5, 0.5)
		p.Size = UDim2.fromOffset(12, 12)
		p.Rotation = math.random(0, 90)
		p.BackgroundColor3 = color:Lerp(WHITE, math.random() * 0.6)
		p.BorderSizePixel = 0
		p.ZIndex = 12
		p.Parent = parent
		local a = math.random() * math.pi * 2
		local d = 0.2 + math.random() * 0.25
		local tw = TweenService:Create(
			p,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromScale(0.5 + math.cos(a) * d, 0.5 + math.sin(a) * d * 1.4),
				Rotation = p.Rotation + 200,
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

-- Plays one reel ending on `result`. Returns after the card popped.
local function runReel(
	screen: ScreenGui,
	window: Frame,
	title: TextLabel,
	wheel: string,
	result: string,
	state: { fast: boolean }
)
	local reduce = player:GetAttribute("ReduceEffects") == true
	title.Text = Strings.roulette.title[wheel] or ""
	title.TextColor3 = WHEEL_COLOR[wheel] or WHITE
	local ts = title:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	ts.Parent = title
	ts.Scale = 0.4
	TweenService:Create(ts, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	local strip = Instance.new("Frame")
	strip.Name = "Strip"
	strip.BackgroundTransparency = 1
	strip.Size = UDim2.fromScale(1, 1)
	strip.ZIndex = 5
	strip.Parent = window
	-- Fill with weighted random cards, the result at TARGET.
	local entries = RouletteConfig.wheel(wheel)
	local cards: { Frame } = {}
	for i = 1, CARDS do
		local id = if i == TARGET then result else RouletteConfig.pick(entries, math.random()).id
		table.insert(cards, makeCard(strip, wheel, id, i))
	end
	-- Centre of the window is at 0.5; card i centre is at CARD_W * (i - 0.5) + offset.
	local jitter = (math.random() - 0.5) * CARD_W * 0.6 -- land a bit off-centre: more natural
	local finalX = 0.5 - CARD_W * (TARGET - 0.5) + jitter
	strip.Position = UDim2.fromScale(0.5 - CARD_W * 2.5, 0)
	local time = if state.fast then 0.35 else (SPIN_TIME :: any)[wheel] or 2
	local tween = TweenService:Create(
		strip,
		TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Position = UDim2.fromScale(finalX, 0),
		}
	)
	tween:Play()
	local t0 = os.clock()
	while tween.PlaybackState == Enum.PlaybackState.Playing do
		if state.fast and os.clock() - t0 < time - 0.05 then
			tween:Cancel()
			strip.Position = UDim2.fromScale(finalX, 0)
			break
		end
		task.wait()
	end
	-- settle exactly on centre
	TweenService:Create(strip, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
		Position = UDim2.fromScale(0.5 - CARD_W * (TARGET - 0.5), 0),
	}):Play()
	task.wait(0.18)
	-- pop the result card and dim the others
	local card = cards[TARGET]
	for i, other in cards do
		if i ~= TARGET then
			TweenService:Create(other, TweenInfo.new(0.2), { BackgroundTransparency = 0.6 }):Play()
		end
	end
	local scale = Instance.new("UIScale")
	scale.Parent = card
	scale.Scale = 1
	card.ZIndex = 7
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1.22 }):Play()
	local color = cardColor(wheel, result, TARGET)
	if not reduce then
		local rare = wheel == "mutation" or (wheel == "size" and result ~= "x2")
		sparkles(screen, color, if rare then 26 else 10)
		if wheel == "mutation" and RouletteConfig.mutationRank(result) >= 5 then
			local base = window.Position
			for i = 1, 10 do
				window.Position = base + UDim2.fromOffset(if i % 2 == 0 then 7 else -7, 0)
				task.wait(0.025)
			end
			window.Position = base
		end
	end
	if result == "again" then
		title.Text = Strings.roulette.again
	end
	task.wait(if state.fast then 0.25 else 0.6)
	strip:Destroy()
end

-- Replays the server's spins; returns when finished.
function Roulette.play(update: Update)
	local spins = update.spins
	if not spins or #spins == 0 then
		return
	end
	local state = { fast = false }

	local screen = Instance.new("ScreenGui")
	screen.Name = "Roulette"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 21
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.fromRGB(20, 12, 40)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.ZIndex = 1
	dim.Parent = screen
	local dg = Instance.new("UIGradient")
	dg.Rotation = 90
	dg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.5, 0.45),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	dg.Parent = dim

	-- Window with a wooden/gold frame; the strip slides inside it.
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.48)
	frame.Size = UDim2.fromScale(0.92, 0.26)
	frame.BackgroundColor3 = Theme.wood
	frame.BorderSizePixel = 0
	frame.ZIndex = 3
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0.12, 0)
	fc.Parent = frame
	local fs = Instance.new("UIStroke")
	fs.Color = Theme.gold
	fs.Thickness = 5
	fs.Parent = frame
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(820, 240)
	limit.Parent = frame
	frame.Parent = screen
	local window = Instance.new("Frame")
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.new(1, -14, 1, -14)
	window.BackgroundColor3 = INK
	window.BorderSizePixel = 0
	window.ClipsDescendants = true
	window.ZIndex = 4
	local wc = Instance.new("UICorner")
	wc.CornerRadius = UDim.new(0.1, 0)
	wc.Parent = window
	window.Parent = frame
	-- Edge fades so cards appear/disappear softly.
	for _, side in { 0, 1 } do
		local fade = Instance.new("Frame")
		fade.AnchorPoint = Vector2.new(side, 0)
		fade.Position = UDim2.fromScale(side, 0)
		fade.Size = UDim2.fromScale(0.16, 1)
		fade.BackgroundColor3 = INK
		fade.BorderSizePixel = 0
		fade.ZIndex = 9
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new(if side == 0 then 0 else 1, if side == 0 then 1 else 0)
		g.Parent = fade
		fade.Parent = window
	end
	-- Golden marker (centre line + two arrows).
	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Size = UDim2.new(0, 4, 1.1, 0)
	line.BackgroundColor3 = Theme.gold
	line.BorderSizePixel = 0
	line.ZIndex = 10
	line.Parent = frame
	for _, y in { 0, 1 } do
		local arrow = Instance.new("Frame")
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		arrow.Position = UDim2.fromScale(0.5, y)
		arrow.Size = UDim2.fromOffset(26, 26)
		arrow.Rotation = 45
		arrow.BackgroundColor3 = Theme.gold
		arrow.BorderSizePixel = 0
		arrow.ZIndex = 11
		local as = Instance.new("UIStroke")
		as.Color = INK
		as.Thickness = 3
		as.Parent = arrow
		arrow.Parent = frame
	end

	local title = label(
		screen,
		Strings.roulette.title.main,
		WHEEL_COLOR.main,
		UDim2.fromScale(0.8, 0.08),
		UDim2.fromScale(0.5, 0.28),
		4
	)
	local footer =
		label(screen, "", WHITE, UDim2.fromScale(0.85, 0.05), UDim2.fromScale(0.5, 0.67), 3)
	local hint = label(
		screen,
		Strings.roulette.skip,
		WHITE,
		UDim2.fromScale(0.4, 0.03),
		UDim2.fromScale(0.5, 0.93),
		2
	)
	hint.TextTransparency = 0.35

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
	TweenService:Create(dim, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
	local fscale = Instance.new("UIScale")
	fscale.Scale = 0.6
	fscale.Parent = frame
	TweenService:Create(fscale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.wait(0.25)

	-- Replay every spin; build the footer as effects land.
	local size, mutationName = 1, nil :: string?
	for _, spin in spins do
		runReel(screen, window, title, spin.wheel, spin.result, state)
		if spin.wheel == "size" or spin.wheel == "worse" then
			for _, e in RouletteConfig.wheel(spin.wheel) do
				if e.id == spin.result then
					size *= e.mult
				end
			end
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
		footer.Text = if #parts > 0 then table.concat(parts, "  ·  ") else ""
	end

	-- Final line: total coins multiplier (or "nothing happened").
	local coin = update.coinMult or 1
	if math.abs(coin - 1) < 0.001 then
		footer.Text = Strings.roulette.nothing
		footer.TextColor3 = Color3.fromRGB(200, 205, 220)
	else
		footer.Text = footer.Text
			.. "  ·  "
			.. string.format(Strings.roulette.coins, num(math.floor(coin * 10 + 0.5) / 10))
		footer.TextColor3 = if coin > 1 then Theme.gold else Color3.fromRGB(255, 150, 150)
	end
	local fsc = Instance.new("UIScale")
	fsc.Parent = footer
	fsc.Scale = 0.6
	TweenService:Create(fsc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1.1 }):Play()
	task.wait(if state.fast then 0.5 else 1.0)

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
	task.wait(0.27)
	screen:Destroy()
end

return Roulette
