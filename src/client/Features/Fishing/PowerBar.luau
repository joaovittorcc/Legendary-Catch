--!strict
-- Power bar on the cast (flag FishingPower): a tall, chunky VERTICAL gauge on the right made of
-- one smooth pill (thick black outline, glossy shine, thin dividers per cell), bottom to top:
-- grey, red, yellow, green, purple. The pill is ALWAYS fully coloured; a fat white bar sweeps up over it (holds at the top, snaps back to
-- the bottom, repeats) and the tap confirms whichever cell it is over. The server owns the
-- clock: the marker follows workspace:GetServerTimeNow() - aimStart through
-- FishingConfig.aimPosition, exactly like the server reads the band.
--
-- API (kept stable): show(layout, aimStart), result(band, luck?), hide().
-- "ReduceEffects" (player attribute) drops the pulses, the burst and the shake.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))

local PowerBar = {}

local BAND_COLORS: { [string]: Color3 } = {
	neutral = Color3.fromRGB(70, 175, 255),
	red = Color3.fromRGB(255, 56, 84),
	yellow = Color3.fromRGB(255, 226, 40),
	green = Color3.fromRGB(70, 255, 96),
	purple = Color3.fromRGB(206, 76, 255),
}
-- Bottom tint of each band's blend: shifts the hue a little so the gauge reads as a rainbow.
local BAND_DEEP: { [string]: Color3 } = {
	neutral = Color3.fromRGB(110, 90, 255),
	red = Color3.fromRGB(255, 120, 40),
	yellow = Color3.fromRGB(255, 150, 30),
	green = Color3.fromRGB(20, 215, 170),
	purple = Color3.fromRGB(255, 70, 200),
}
local INK = Theme.ink
local WHITE = Color3.new(1, 1, 1)

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local beat: RBXScriptConnection? = nil
local token = 0

local function calm(): boolean
	return player:GetAttribute("ReduceEffects") == true
end

local function corner(parent: Instance, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function label(
	parent: Instance,
	text: string,
	color: Color3,
	size: UDim2,
	pos: UDim2
): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Theme.font
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	t.Size = size
	t.Position = pos
	local s = Instance.new("UIStroke")
	s.Color = INK
	s.Thickness = 2.5
	s.Parent = t
	t.Parent = parent
	return t
end

function PowerBar.hide()
	token += 1
	if beat then
		beat:Disconnect()
		beat = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
end

-- Builds the gauge from the server layout (one segment per cell, bottom to top).
function PowerBar.show(layout: { FishingConfig.AimSegment }, aimStart: number)
	PowerBar.hide()
	local myToken = token
	local reduce = calm()

	local screen = Instance.new("ScreenGui")
	screen.Name = "PowerBar"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 7
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Root on the right edge (thumb side); slides in from off-screen.
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.AnchorPoint = Vector2.new(1, 0.5)
	root.Position = UDim2.fromScale(1.3, 0.56)
	root.Size = UDim2.fromScale(0.23, 0.6)
	root.BackgroundTransparency = 1
	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(190, 320)
	limit.MaxSize = Vector2.new(290, 520)
	limit.Parent = root
	root.Parent = screen

	local title =
		label(root, Strings.powerTitle, WHITE, UDim2.fromScale(1, 0.08), UDim2.fromScale(0, -0.02))
	local tg = Instance.new("UIGradient")
	tg.Color = ColorSequence.new(Theme.gold, Color3.fromRGB(255, 120, 80))
	tg.Rotation = 90
	tg.Parent = title

	-- Frame: thick black pill outline (the glossy colourful look), one smooth gradient fill inside.
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.fromScale(0.95, 0.08)
	frame.Size = UDim2.fromScale(0.74, 0.86)
	frame.BackgroundColor3 = INK
	frame.BorderSizePixel = 0
	corner(frame, 0.3)
	frame.Parent = root

	local well = Instance.new("Frame")
	well.Name = "Well"
	well.AnchorPoint = Vector2.new(0.5, 0.5)
	well.Position = UDim2.fromScale(0.5, 0.5)
	well.Size = UDim2.new(1, -18, 1, -18)
	well.BackgroundColor3 = WHITE
	well.BorderSizePixel = 0
	corner(well, 0.27)
	well.Parent = frame

	-- One gradient for the whole fill: each run of equal bands blends from a lighter top to a
	-- deeper bottom, with a hairline step between runs (ColorSequence time 0 = top).
	local n = #layout
	local keys: { ColorSequenceKeypoint } = {}
	local runTop = n
	local i = n
	while i >= 1 do
		local band = layout[i].band
		local runBottom = i
		while runBottom > 1 and layout[runBottom - 1].band == band do
			runBottom -= 1
		end
		local color = BAND_COLORS[band] or WHITE
		local t0 = (n - runTop) / n
		local t1 = (n - runBottom + 1) / n
		table.insert(
			keys,
			ColorSequenceKeypoint.new(
				math.max(t0, if #keys == 0 then 0 else t0 + 0.0008),
				color:Lerp(WHITE, 0.1)
			)
		)
		table.insert(
			keys,
			ColorSequenceKeypoint.new(math.min(t1 - 0.0008, 1), (BAND_DEEP[band] or color))
		)
		runTop = runBottom - 1
		i = runBottom - 1
	end
	keys[1] = ColorSequenceKeypoint.new(0, keys[1].Value)
	keys[#keys] = ColorSequenceKeypoint.new(1, keys[#keys].Value)
	local fill = Instance.new("UIGradient")
	fill.Rotation = 90
	fill.Color = ColorSequence.new(keys)
	fill.Parent = well

	-- Hairline dividers between cells (like the reference), dark and thin.
	for k = 1, n - 1 do
		local d = Instance.new("Frame")
		d.Name = "Divider" .. k
		d.AnchorPoint = Vector2.new(0.5, 0.5)
		d.Position = UDim2.fromScale(0.5, 1 - k / n)
		d.Size = UDim2.new(if k == 1 or k == n - 1 then 0.88 else 1, 0, 0, 3)
		d.BackgroundColor3 = INK
		d.BackgroundTransparency = 0.15
		d.BorderSizePixel = 0
		d.ZIndex = 2
		d.Parent = well
	end

	-- Glossy shine strip down the left side.
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.AnchorPoint = Vector2.new(0, 0.5)
	gloss.Position = UDim2.fromScale(0.1, 0.5)
	gloss.Size = UDim2.fromScale(0.16, 0.94)
	gloss.BackgroundColor3 = WHITE
	gloss.BackgroundTransparency = 0.7
	gloss.BorderSizePixel = 0
	gloss.ZIndex = 3
	corner(gloss, 0.5)
	gloss.Parent = well

	-- Band side labels (topmost cell of each labelled band).
	local labelsDone: { [string]: boolean } = {}
	for idx, seg in layout do
		local isTopOfBand = layout[idx + 1] == nil or layout[idx + 1].band ~= seg.band
		local text = Strings.powerLabel[seg.band]
		if text and isTopOfBand and not labelsDone[seg.band] then
			labelsDone[seg.band] = true
			local tag = label(
				root,
				text,
				(BAND_COLORS[seg.band] or WHITE):Lerp(WHITE, 0.2),
				UDim2.fromScale(0.5, 0.05),
				UDim2.fromScale(-0.36, 0.08 + 0.86 * (1 - (idx - 0.5) * (1 / n)) - 0.025)
			)
			tag.TextXAlignment = Enum.TextXAlignment.Right
			tag.Rotation = -6
		end
	end

	-- The fat white pill that sweeps over the fill, wider than the bar so it reads at a glance.
	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.new(1.2, 0, 0, 26)
	marker.Position = UDim2.fromScale(0.5, 1)
	marker.BackgroundColor3 = WHITE
	marker.BorderSizePixel = 0
	marker.ZIndex = 6
	corner(marker, 0.5)
	stroke(marker, INK, 4)
	marker.Parent = well
	local markerGlow = Instance.new("Frame")
	markerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	markerGlow.Position = UDim2.fromScale(0.5, 0.5)
	markerGlow.Size = UDim2.fromScale(0.9, 2.2)
	markerGlow.BackgroundColor3 = WHITE
	markerGlow.BackgroundTransparency = 0.75
	markerGlow.BorderSizePixel = 0
	markerGlow.ZIndex = 5
	corner(markerGlow, 0.5)
	markerGlow.Parent = marker

	-- Tap hint bubble under the gauge.
	local bubble = Instance.new("Frame")
	bubble.Name = "Hint"
	bubble.AnchorPoint = Vector2.new(0.5, 0)
	bubble.Position = UDim2.fromScale(0.45, 0.96)
	bubble.Size = UDim2.fromScale(1.25, 0.075)
	bubble.BackgroundColor3 = WHITE
	bubble.BorderSizePixel = 0
	corner(bubble, 0.5)
	stroke(bubble, INK, 3)
	bubble.Parent = root
	local hint =
		label(bubble, Strings.powerTap, INK, UDim2.new(1, -10, 0.8, 0), UDim2.new(0, 5, 0.1, 0))
	local hs = hint:FindFirstChildOfClass("UIStroke")
	if hs then
		hs.Enabled = false
	end

	screen.Parent = player:WaitForChild("PlayerGui")
	gui = screen
	TweenService:Create(
		root,
		TweenInfo.new(0.35, Enum.EasingStyle.Back),
		{ Position = UDim2.fromScale(0.985, 0.56) }
	):Play()

	local t0 = os.clock()
	local lastCell = 0
	beat = RunService.RenderStepped:Connect(function()
		if token ~= myToken then
			return
		end
		local pos = FishingConfig.aimPosition(Workspace:GetServerTimeNow() - aimStart)
		local t = os.clock() - t0
		-- marker rides the position; a soft tick per cell, higher as it climbs
		marker.Position = UDim2.fromScale(0.5, 1 - pos)
		local under = math.clamp(math.floor(pos * n) + 1, 1, n)
		if under ~= lastCell then
			if under > lastCell and Workspace:GetServerTimeNow() >= aimStart then
				Audio.play("click", 0.12, 0.8 + under * 0.07)
			end
			lastCell = under
		end
		if not reduce then
			markerGlow.BackgroundTransparency = 0.7 + math.abs(math.sin(t * 10)) * 0.15
			bubble.Rotation = math.sin(t * 6) * 4
			local sc = 1 + math.abs(math.sin(t * 4)) * 0.06
			bubble.Size = UDim2.fromScale(1.25 * sc, 0.075 * sc)
		end
	end)
end

-- Sparkles flying out of a point (UI only, short-lived).
local function burst(parent: Instance, at: UDim2, color: Color3, count: number)
	for _ = 1, count do
		local p = Instance.new("Frame")
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = at
		p.Size = UDim2.fromOffset(10, 10)
		p.Rotation = math.random(0, 90)
		p.BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), math.random() * 0.5)
		p.BorderSizePixel = 0
		p.ZIndex = 20
		p.Parent = parent
		local angle = math.random() * math.pi * 2
		local dist = 0.08 + math.random() * 0.12
		local goal = UDim2.new(
			at.X.Scale + math.cos(angle) * dist,
			at.X.Offset,
			at.Y.Scale + math.sin(angle) * dist * 1.6,
			at.Y.Offset
		)
		local tween = TweenService:Create(
			p,
			TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = goal,
				Rotation = p.Rotation + 180,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(4, 4),
			}
		)
		tween:Play()
		tween.Completed:Once(function()
			p:Destroy()
		end)
	end
end

-- Freezes the fill, pops the word in the middle of the screen (plus the luck multiplier when
-- given, e.g. 2.0) and slides the gauge out.
function PowerBar.result(band: string, luck: number?)
	local screen = gui
	if not screen then
		return
	end
	if beat then
		beat:Disconnect()
		beat = nil
	end
	local myToken = token
	local reduce = calm()
	local color = BAND_COLORS[band] or WHITE
	local root = screen:FindFirstChild("Root") :: Frame?
	-- Hit-stop: the frozen gauge holds a beat before the word, so the tap feels heavy.
	if not reduce and (band == "purple" or band == "green") then
		task.wait(0.08)
		if token ~= myToken then
			return
		end
	end
	if band == "purple" then
		Audio.play("level", 0.45, 1.15)
	elseif band == "green" then
		Audio.play("hit", 0.5, 1.1)
	elseif band == "yellow" then
		Audio.play("hit", 0.4, 0.9)
	else
		Audio.play("miss", 0.35, 1)
	end

	local word = label(
		screen,
		Strings.powerBand[band] or "",
		color,
		UDim2.fromScale(0.7, 0.12),
		UDim2.fromScale(0.15, 0.3)
	)
	word.AnchorPoint = Vector2.new(0, 0)
	word.ZIndex = 15
	local ws = word:FindFirstChildOfClass("UIStroke")
	if ws then
		ws.Thickness = 5
	end
	if band == "purple" then
		local rg = Instance.new("UIGradient")
		rg.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 220)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 120, 255)),
		})
		rg.Parent = word
		if not reduce then
			task.spawn(function()
				local t = 0
				while word.Parent and token == myToken do
					t += task.wait()
					rg.Rotation = (t * 180) % 360
				end
			end)
		end
	end
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 96
	cap.Parent = word
	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = word
	TweenService:Create(scale, TweenInfo.new(0.28, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	if luck and luck ~= 1 then
		local text = string.format(
			Strings.powerLuck,
			(string.format("%.1f", luck):gsub("%.", Strings.decimalSep))
		)
		local l = label(
			screen,
			text,
			if luck > 1 then Theme.gold else Color3.fromRGB(255, 160, 160),
			UDim2.fromScale(0.5, 0.05),
			UDim2.fromScale(0.25, 0.43)
		)
		l.ZIndex = 15
	end

	-- Freeze: the marker stays where it was and flashes in the stopped band's colour.
	if root then
		local gauge = root:FindFirstChild("Frame")
		local well = if gauge then gauge:FindFirstChild("Well") else nil
		local marker = if well then well:FindFirstChild("Marker") else nil
		if marker and marker:IsA("Frame") then
			marker.BackgroundColor3 = color:Lerp(WHITE, 0.35)
			local sc = Instance.new("UIScale")
			sc.Parent = marker
			TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1.25 })
				:Play()
		end
	end

	if not reduce then
		burst(
			screen,
			UDim2.fromScale(0.5, 0.36),
			color,
			if band == "purple" then 26 elseif band == "green" then 14 else 6
		)
		if band == "red" and root then
			task.spawn(function()
				local base = root.Position
				for i = 1, 8 do
					root.Position = base + UDim2.fromOffset(if i % 2 == 0 then 6 else -6, 0)
					task.wait(0.03)
				end
				root.Position = base
			end)
		end
	end

	task.delay(0.9, function()
		if token ~= myToken or gui ~= screen then
			return
		end
		if root then
			TweenService
				:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
					Position = UDim2.fromScale(1.3, 0.56),
				})
				:Play()
		end
		TweenService:Create(word, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		if ws then
			TweenService:Create(ws, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		end
		task.delay(0.35, function()
			if token == myToken and gui == screen then
				PowerBar.hide()
			end
		end)
	end)
end

return PowerBar
