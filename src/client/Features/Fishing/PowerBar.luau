--!strict
-- Power bar on the cast (flag FishingPower): a tall VERTICAL gauge on the right (thumb side),
-- in the spirit of docs/PLANO-VISUAL-REFERENCIA.md. The pointer follows SERVER time
-- (workspace:GetServerTimeNow() - aimStart) through FishingConfig.aimPosition, exactly like the
-- server reads the band, so what the player sees is what they get.
--
-- API (kept stable for the Codex): show(layout, aimStart), result(band, luck?), hide().
-- Detailed first, optimise later: per-frame shimmer, pointer trail, bouncing hint, sparkle burst.
-- "ReduceEffects" (player attribute) drops the shake, the burst and the shimmer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local PowerBar = {}

local BAND_COLORS: { [string]: Color3 } = {
	red = Color3.fromRGB(255, 72, 92),
	yellow = Color3.fromRGB(255, 208, 64),
	neutral = Color3.fromRGB(78, 92, 134),
	green = Color3.fromRGB(88, 236, 128),
	purple = Color3.fromRGB(196, 104, 255),
}
local INK = Theme.ink
local WHITE = Color3.new(1, 1, 1)
local TRAIL = 5

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

-- Builds the gauge. Bottom of the gauge = position 0, top = 1 (the layout is symmetric, so the
-- purple sits in the middle and red at both ends).
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

	-- Root on the right edge, vertically centred; slides in from off-screen.
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.AnchorPoint = Vector2.new(1, 0.5)
	root.Position = UDim2.fromScale(1.3, 0.56)
	root.Size = UDim2.fromScale(0.16, 0.56)
	root.BackgroundTransparency = 1
	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(110, 280)
	limit.MaxSize = Vector2.new(170, 520)
	limit.Parent = root
	root.Parent = screen

	-- Title "FORÇA" with a warm gradient.
	local title =
		label(root, Strings.powerTitle, WHITE, UDim2.fromScale(1, 0.08), UDim2.fromScale(0, -0.02))
	local tg = Instance.new("UIGradient")
	tg.Color = ColorSequence.new(Theme.gold, Color3.fromRGB(255, 120, 80))
	tg.Rotation = 90
	tg.Parent = title

	-- Gauge body: wooden frame + gold rim + inner well.
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.fromScale(0.78, 0.08)
	frame.Size = UDim2.fromScale(0.46, 0.86)
	frame.BackgroundColor3 = Theme.wood
	frame.BorderSizePixel = 0
	corner(frame, 0.25)
	stroke(frame, Theme.gold, 4)
	frame.Parent = root
	local wood = Instance.new("UIGradient")
	wood.Color = ColorSequence.new(Color3.fromRGB(150, 92, 62), Color3.fromRGB(86, 48, 41))
	wood.Rotation = 0
	wood.Parent = frame

	local well = Instance.new("Frame")
	well.Name = "Well"
	well.AnchorPoint = Vector2.new(0.5, 0.5)
	well.Position = UDim2.fromScale(0.5, 0.5)
	well.Size = UDim2.new(1, -12, 1, -12)
	well.BackgroundColor3 = INK
	well.BorderSizePixel = 0
	well.ClipsDescendants = true
	corner(well, 0.22)
	well.Parent = frame

	local shimmerGradients: { UIGradient } = {}
	local labelsDone: { [string]: boolean } = {}
	for _, seg in layout do
		local color = BAND_COLORS[seg.band] or WHITE
		local f = Instance.new("Frame")
		f.Name = seg.band
		f.BorderSizePixel = 0
		f.Position = UDim2.fromScale(0, 1 - seg.to)
		f.Size = UDim2.fromScale(1, seg.to - seg.from)
		f.BackgroundColor3 = color
		f.Parent = well
		-- Rounded "candy" look: lighter in the middle column.
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color:Lerp(INK, 0.35)),
			ColorSequenceKeypoint.new(0.5, color:Lerp(WHITE, 0.25)),
			ColorSequenceKeypoint.new(1, color:Lerp(INK, 0.35)),
		})
		g.Parent = f
		if seg.band == "purple" or seg.band == "green" then
			-- Moving sheen (a bright stripe sliding up), stronger on purple.
			local sheen = Instance.new("Frame")
			sheen.Name = "Sheen"
			sheen.Size = UDim2.fromScale(1, 1)
			sheen.BackgroundColor3 = WHITE
			sheen.BorderSizePixel = 0
			sheen.BackgroundTransparency = 0
			sheen.Parent = f
			local sg = Instance.new("UIGradient")
			sg.Rotation = 90
			sg.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.45, 1),
				NumberSequenceKeypoint.new(0.5, if seg.band == "purple" then 0.35 else 0.65),
				NumberSequenceKeypoint.new(0.55, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
			sg.Parent = sheen
			table.insert(shimmerGradients, sg)
		end
		-- Side label once per kind ("PERFEITO" / "ÓTIMO" / "BOM"), pointing at the topmost one.
		local text = Strings.powerLabel[seg.band]
		if text and not labelsDone[seg.band] then
			labelsDone[seg.band] = true
			local mid = 1 - (seg.from + seg.to) / 2
			local tag = label(
				root,
				text,
				color:Lerp(WHITE, 0.2),
				UDim2.fromScale(0.5, 0.05),
				UDim2.fromScale(-0.46, 0.08 + 0.86 * mid - 0.025)
			)
			tag.TextXAlignment = Enum.TextXAlignment.Right
			tag.Rotation = -6
		end
	end

	-- Glass highlight over the well.
	local glass = Instance.new("Frame")
	glass.Name = "Glass"
	glass.Size = UDim2.fromScale(0.28, 1)
	glass.Position = UDim2.fromScale(0.12, 0)
	glass.BackgroundColor3 = WHITE
	glass.BackgroundTransparency = 0.82
	glass.BorderSizePixel = 0
	glass.ZIndex = 2
	glass.Parent = well

	-- Pointer: a bright bar across the gauge + an arrow outside + a fading trail.
	local function makeLine(alpha: number): Frame
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0, 0.5)
		line.Size = UDim2.new(1, 0, 0, 5)
		line.BackgroundColor3 = WHITE
		line.BackgroundTransparency = alpha
		line.BorderSizePixel = 0
		line.ZIndex = 4
		line.Parent = well
		return line
	end
	local trail: { Frame } = {}
	for i = 1, TRAIL do
		table.insert(trail, makeLine(0.45 + i * 0.1))
	end
	local pointer = makeLine(0)
	pointer.Name = "Pointer"
	stroke(pointer, INK, 1.5)

	local arrow = Instance.new("Frame")
	arrow.Name = "Arrow"
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(22, 22)
	arrow.Rotation = 45
	arrow.BackgroundColor3 = WHITE
	arrow.BorderSizePixel = 0
	arrow.ZIndex = 5
	stroke(arrow, INK, 3)
	arrow.Parent = frame

	-- Tap hint bubble (bouncing) under the gauge.
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

	local history: { number } = {}
	local t0 = os.clock()
	beat = RunService.RenderStepped:Connect(function()
		if token ~= myToken then
			return
		end
		local pos = FishingConfig.aimPosition(Workspace:GetServerTimeNow() - aimStart)
		local y = 1 - pos
		pointer.Position = UDim2.fromScale(0, y)
		arrow.Position = UDim2.new(0, -2, y, 0)
		table.insert(history, 1, y)
		if #history > TRAIL * 2 then
			table.remove(history)
		end
		for i, line in trail do
			local hy = history[i * 2] or y
			line.Position = UDim2.fromScale(0, hy)
		end
		-- Pointer takes the colour of the band it is over.
		local band = FishingConfig.bandAt(layout, pos)
		local c = BAND_COLORS[band] or WHITE
		arrow.BackgroundColor3 = c:Lerp(WHITE, 0.35)
		local t = os.clock() - t0
		if not reduce then
			for _, sg in shimmerGradients do
				sg.Offset = Vector2.new(0, ((t * 0.9) % 2) - 1)
			end
			bubble.Rotation = math.sin(t * 6) * 4
			local s = 1 + math.abs(math.sin(t * 4)) * 0.06
			bubble.Size = UDim2.fromScale(1.25 * s, 0.075 * s)
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

-- Freezes the pointer, flashes the band, pops the word in the middle of the screen (plus the
-- luck multiplier when given, e.g. "2,0") and slides the gauge out.
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

	-- Big word.
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
