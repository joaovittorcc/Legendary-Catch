--!strict
--[[
	Panel.luau
	Native 3D cartoon candy UI kit for Legendary Catch panels & controls.
	Uses 9-slice art from Shared/Ui/UiAssets when uploaded, and a lush multi-layer glossy
	cartoon Luau fallback (thick plum outline #2C0A4D, saturated gradients, specular top gloss,
	golden inner molding rim, chunky 3D bottom bevels, warm cream #FFF8E6 interior) until IDs
	are pasted into UiAssets.

	Preserves all existing signatures and instance names:
	  Panel.create, Panel.button, Panel.tintButton, Panel.card, Panel.label, Panel.stack
	Plus native controls:
	  Panel.themeColor, Panel.setCardState, Panel.progressBar, Panel.toggle, Panel.slider,
	  Panel.badge, Panel.rarityCard, Panel.tabButton
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local UiAssets = require(Shared:WaitForChild("Ui"):WaitForChild("UiAssets"))
local Hud = require(script.Parent)
local Motion = require(script.Parent:WaitForChild("Motion"))

local Panel = {}
local player = Players.LocalPlayer

local ICONS: { [string]: string } = {
	Collection = "🐠",
	Aquarium = "🐟",
	Shop = "🎣",
	Robux = "💎",
	Missions = "📜",
	Milestones = "🏆",
	Achievements = "🏅",
	Prestige = "🌊",
	Leaderboard = "👑",
	Settings = "⚙️",
	TrainingField = "⚡",
}

local PANEL_ICON_KEYS: { [string]: string } = {
	Collection = "book",
	Aquarium = "aquarium",
	Shop = "rod",
	Robux = "gem",
	Missions = "star",
	Milestones = "trophy",
	Achievements = "trophy",
	Prestige = "sparkle",
	Leaderboard = "crown",
	Settings = "gear",
	TrainingField = "xp",
}

local function makeGradient(parent: Instance, top: Color3, mid: Color3, bot: Color3): UIGradient
	local existing = parent:FindFirstChildOfClass("UIGradient")
	local gradient = existing or Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(0.48, mid),
		ColorSequenceKeypoint.new(1, bot),
	})
	gradient.Parent = parent
	return gradient
end

local function applyButtonVisual(button: TextButton, tone: string, pressed: boolean)
	button:SetAttribute("CandyTone", tone)
	local palette = UiAssets.BUTTONS[tone] or UiAssets.BUTTONS.blue
	local state = if tone == "disabled" then "disabled" elseif pressed then "pressed" else "normal"

	local art = button:FindFirstChild("ButtonArt")
	local hasArt = false
	if art and art:IsA("ImageLabel") then
		hasArt = UiAssets.applySpec(art, UiAssets.buttonSpec(tone, state))
	end

	local stroke = button:FindFirstChildOfClass("UIStroke")
	local lip = button:FindFirstChild("CandyLip")
	local shine = button:FindFirstChild("CandyShine")
	local dot = button:FindFirstChild("CandyGlint")
	local caption = button:FindFirstChild("ButtonCaption")

	if hasArt then
		button.BackgroundTransparency = 1
		if stroke then
			stroke.Enabled = false
		end
		if lip and lip:IsA("GuiObject") then
			lip.Visible = false
		end
		if shine and shine:IsA("GuiObject") then
			shine.Visible = false
		end
		if dot and dot:IsA("GuiObject") then
			dot.Visible = false
		end
	else
		button.BackgroundTransparency = 0
		button.BackgroundColor3 = Color3.new(1, 1, 1)
		local topCol = if pressed then palette.pressedTop else palette.top
		local midCol = if pressed then palette.pressedMid else palette.mid
		local botCol = if pressed then palette.pressedBot else palette.bot
		makeGradient(button, topCol, midCol, botCol)
		if stroke then
			stroke.Enabled = true
			stroke.Color = if tone == "disabled"
				then Color3.fromRGB(67, 53, 94)
				else UiAssets.OUTLINE
			stroke.Thickness = 3.5
		end
		if lip and lip:IsA("Frame") then
			lip.Visible = true
			lip.BackgroundColor3 = palette.lip
			lip.Size = UDim2.new(1, -6, 0, if pressed then 4 else 8)
		end
		if shine and shine:IsA("Frame") then
			shine.Visible = true
			shine.BackgroundColor3 = palette.rim
			shine.BackgroundTransparency = if tone == "disabled"
				then 0.65
				elseif pressed then 0.56
				else 0.32
		end
		if dot and dot:IsA("Frame") then
			dot.Visible = tone ~= "disabled"
		end
	end

	if caption and caption:IsA("TextLabel") then
		caption.Position = UDim2.fromScale(0.5, if pressed then 0.50 else 0.45)
	end
end

function Panel.themeColor(id: string): Color3
	return UiAssets.themeForPanel(id).mid
end

function Panel.label(parent: Instance, content: string, size: number, color: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, size * 2)
	label.BackgroundTransparency = 1
	label.Text = content
	label.TextWrapped = true
	label.TextColor3 = color or Theme.ink
	label.TextSize = size
	label.TextStrokeColor3 = UiAssets.OUTLINE
	label.TextStrokeTransparency = 0.35
	label.Font = Theme.font
	label.Parent = parent
	return label
end

function Panel.button(parent: Instance, content: string, accent: Color3): TextButton
	local tone = UiAssets.buttonToneFromColor(accent)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 48)
	button.Text = content
	button.TextColor3 = Color3.fromRGB(255, 253, 240)
	button.TextSize = 18
	button.TextStrokeColor3 = UiAssets.OUTLINE
	button.TextStrokeTransparency = 0.04
	button.Font = Theme.font
	button.AutoButtonColor = false
	button.TextTransparency = 1
	button.BorderSizePixel = 0
	Theme.corner(button, 18)

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = UiAssets.OUTLINE
	stroke.Thickness = 3.5
	stroke.Parent = button

	-- Native 9-slice art layer (automatically shown when uploaded PNG exists)
	local art = Instance.new("ImageLabel")
	art.Name = "ButtonArt"
	art.Size = UDim2.fromScale(1, 1)
	art.BackgroundTransparency = 1
	art.ZIndex = button.ZIndex
	art.Parent = button

	-- Chunky 3D bottom pedestal lip (fallback)
	local lip = Instance.new("Frame")
	lip.Name = "CandyLip"
	lip.AnchorPoint = Vector2.new(0.5, 1)
	lip.Position = UDim2.new(0.5, 0, 1, -2)
	lip.Size = UDim2.new(1, -6, 0, 8)
	lip.BorderSizePixel = 0
	lip.ZIndex = button.ZIndex
	Theme.corner(lip, 11)
	lip.Parent = button

	-- Top glossy candy glass dome (fallback)
	local shine = Instance.new("Frame")
	shine.Name = "CandyShine"
	shine.AnchorPoint = Vector2.new(0.5, 0)
	shine.Position = UDim2.new(0.5, 0, 0, 3)
	shine.Size = UDim2.new(1, -14, 0.36, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.35
	shine.BorderSizePixel = 0
	shine.ZIndex = button.ZIndex + 1
	Theme.corner(shine, 12)
	local shineGrad = Instance.new("UIGradient")
	shineGrad.Rotation = 90
	shineGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 0.92),
	})
	shineGrad.Parent = shine
	shine.Parent = button

	-- Signature crisp top-left candy specular pill
	local glint = Instance.new("Frame")
	glint.Name = "CandyGlint"
	glint.Position = UDim2.fromOffset(10, 5)
	glint.Size = UDim2.fromOffset(22, 6)
	glint.BackgroundColor3 = Color3.new(1, 1, 1)
	glint.BackgroundTransparency = 0.14
	glint.BorderSizePixel = 0
	glint.ZIndex = button.ZIndex + 2
	Theme.corner(glint, 6)
	glint.Parent = button

	-- Crisp centered caption (synced with button Text* properties)
	local caption = Instance.new("TextLabel")
	caption.Name = "ButtonCaption"
	caption.AnchorPoint = Vector2.new(0.5, 0.5)
	caption.Position = UDim2.fromScale(0.5, 0.45)
	caption.Size = UDim2.new(1, -14, 1, -12)
	caption.BackgroundTransparency = 1
	caption.Text = content
	caption.TextColor3 = button.TextColor3
	caption.TextSize = button.TextSize
	caption.TextStrokeColor3 = button.TextStrokeColor3
	caption.TextStrokeTransparency = button.TextStrokeTransparency
	caption.TextScaled = button.TextScaled
	caption.TextWrapped = true
	caption.Font = button.Font
	caption.ZIndex = button.ZIndex + 5
	caption.Parent = button

	local conns: { RBXScriptConnection } = {
		button:GetPropertyChangedSignal("Text"):Connect(function()
			caption.Text = button.Text
		end),
		button:GetPropertyChangedSignal("TextSize"):Connect(function()
			caption.TextSize = button.TextSize
		end),
		button:GetPropertyChangedSignal("TextScaled"):Connect(function()
			caption.TextScaled = button.TextScaled
		end),
		button:GetPropertyChangedSignal("TextWrapped"):Connect(function()
			caption.TextWrapped = button.TextWrapped
		end),
		button:GetPropertyChangedSignal("TextColor3"):Connect(function()
			caption.TextColor3 = button.TextColor3
		end),
		button:GetPropertyChangedSignal("TextStrokeColor3"):Connect(function()
			caption.TextStrokeColor3 = button.TextStrokeColor3
		end),
		button:GetPropertyChangedSignal("TextStrokeTransparency"):Connect(function()
			caption.TextStrokeTransparency = button.TextStrokeTransparency
		end),
		button:GetPropertyChangedSignal("Font"):Connect(function()
			caption.Font = button.Font
		end),
	}
	button.Destroying:Once(function()
		for _, c in conns do
			c:Disconnect()
		end
	end)

	applyButtonVisual(button, tone, false)

	Motion.mount(button, nil, 6.8, {
		shimmer = tone ~= "disabled",
		shimmerInterval = 6.8,
		onPressChange = function(pressed: boolean)
			local currentTone = button:GetAttribute("CandyTone")
			applyButtonVisual(
				button,
				if typeof(currentTone) == "string" then currentTone else tone,
				pressed
			)
		end,
	})

	button.Parent = parent
	return button
end

function Panel.tintButton(button: TextButton, accent: Color3)
	local disabled = not button.Active or not button.Interactable
	local tone = UiAssets.buttonToneFromColor(accent, disabled and accent == Theme.muted)
	if not disabled then
		tone = UiAssets.buttonToneFromColor(accent, false)
	end
	applyButtonVisual(button, tone, false)
end

-- Set card visual state ("normal" | "selected" | "locked")
function Panel.setCardState(card: Frame, state: string, accent: Color3?)
	local art = card:FindFirstChild("CardArt")
	local spec = if state == "selected"
		then UiAssets.controls.cardSelected
		elseif state == "locked" then UiAssets.controls.cardLocked
		else UiAssets.controls.cardNormal

	local hasArt = false
	if art and art:IsA("ImageLabel") then
		hasArt = UiAssets.applySpec(art, spec)
	end

	local stroke = card:FindFirstChildOfClass("UIStroke")
	local lip = card:FindFirstChild("CardLip")
	local rim = card:FindFirstChild("CardTopRim")
	local shadow = card:FindFirstChild("CardShadow")

	if hasArt then
		card.BackgroundTransparency = 1
		if stroke then
			stroke.Enabled = false
		end
		if lip and lip:IsA("GuiObject") then
			lip.Visible = false
		end
		if rim and rim:IsA("GuiObject") then
			rim.Visible = false
		end
		if shadow and shadow:IsA("GuiObject") then
			shadow.Visible = false
		end
		return
	end

	card.BackgroundTransparency = 0
	if state == "selected" then
		card.BackgroundColor3 = Color3.fromRGB(255, 252, 224)
		if stroke then
			stroke.Enabled = true
			stroke.Color = UiAssets.GOLD_MID
			stroke.Thickness = 4
		end
		if lip and lip:IsA("Frame") then
			lip.Visible = true
			lip.BackgroundColor3 = Color3.fromRGB(245, 206, 112)
		end
	elseif state == "locked" then
		card.BackgroundColor3 = Color3.fromRGB(178, 187, 224)
		if stroke then
			stroke.Enabled = true
			stroke.Color = Color3.fromRGB(61, 46, 94)
			stroke.Thickness = 3
		end
		if lip and lip:IsA("Frame") then
			lip.Visible = true
			lip.BackgroundColor3 = Color3.fromRGB(132, 142, 186)
		end
	else
		card.BackgroundColor3 = UiAssets.CREAM_CARD
		if stroke then
			stroke.Enabled = true
			stroke.Color = if accent
				then accent:Lerp(UiAssets.OUTLINE_SOFT, 0.35)
				else UiAssets.OUTLINE_SOFT
			stroke.Thickness = 3
		end
		if lip and lip:IsA("Frame") then
			lip.Visible = true
			lip.BackgroundColor3 = UiAssets.CREAM_LIP
		end
	end
	if rim and rim:IsA("GuiObject") then
		rim.Visible = state ~= "locked"
	end
	if shadow and shadow:IsA("GuiObject") then
		shadow.Visible = true
	end
end

function Panel.card(parent: Instance, accent: Color3, height: number): Frame
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, height)
	card.BackgroundColor3 = UiAssets.CREAM_CARD
	card.BorderSizePixel = 0
	Theme.corner(card, 18)

	local art = Instance.new("ImageLabel")
	art.Name = "CardArt"
	art.Size = UDim2.fromScale(1, 1)
	art.BackgroundTransparency = 1
	art.ZIndex = 0
	art.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = accent:Lerp(UiAssets.OUTLINE_SOFT, 0.35)
	stroke.Thickness = 3
	stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	stroke.Parent = card

	local lip = Instance.new("Frame")
	lip.Name = "CardLip"
	lip.AnchorPoint = Vector2.new(0.5, 1)
	lip.Position = UDim2.new(0.5, 0, 1, -2)
	lip.Size = UDim2.new(1, -6, 0, 6)
	lip.BackgroundColor3 = UiAssets.CREAM_LIP
	lip.BorderSizePixel = 0
	lip.ZIndex = 0
	Theme.corner(lip, 10)
	lip.Parent = card

	local rim = Instance.new("Frame")
	rim.Name = "CardTopRim"
	rim.AnchorPoint = Vector2.new(0.5, 0)
	rim.Position = UDim2.new(0.5, 0, 0, 3)
	rim.Size = UDim2.new(1, -20, 0, 4)
	rim.BackgroundColor3 = Color3.new(1, 1, 1)
	rim.BackgroundTransparency = 0.28
	rim.BorderSizePixel = 0
	rim.ZIndex = 0
	Theme.corner(rim, 4)
	rim.Parent = card

	local shade = Instance.new("Frame")
	shade.Name = "CardShadow"
	shade.Position = UDim2.new(0.03, 0, 1, -1)
	shade.Size = UDim2.new(0.94, 0, 0, 5)
	shade.BackgroundColor3 = UiAssets.OUTLINE
	shade.BackgroundTransparency = 0.78
	shade.BorderSizePixel = 0
	shade.ZIndex = 0
	Theme.corner(shade, 14)
	shade.Parent = card

	Panel.setCardState(card, "normal", accent)
	card.Parent = parent
	return card
end

-- Glossy 9-slice progress bar (gold-rimmed dark indigo groove + luminous candy fill)
function Panel.progressBar(parent: Instance, fillVariant: string?, height: number?): (Frame, Frame)
	local barH = height or 18
	local track = Instance.new("Frame")
	track.Name = "ProgressTrack"
	track.Size = UDim2.new(1, 0, 0, barH)
	track.BackgroundColor3 = Color3.fromRGB(38, 20, 74)
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	Theme.corner(track, math.ceil(barH * 0.5))

	local trackArt = Instance.new("ImageLabel")
	trackArt.Name = "TrackArt"
	trackArt.Size = UDim2.fromScale(1, 1)
	trackArt.BackgroundTransparency = 1
	trackArt.ZIndex = 1
	-- The bar art has thick transparent margins: below 24 px it collapses and the fill
	-- disappears, so thin bars keep the drawn version.
	local useArt = barH >= 24
	local hasTrackArt = useArt and UiAssets.applySpec(trackArt, UiAssets.controls.progressTrack)
	trackArt.Parent = track

	if hasTrackArt then
		track.BackgroundTransparency = 1
	else
		local outerStroke = Instance.new("UIStroke")
		outerStroke.Color = UiAssets.OUTLINE
		outerStroke.Thickness = 2.5
		outerStroke.Parent = track
	end

	local inset = Instance.new("Frame")
	inset.Name = "FillInset"
	inset.Position = UDim2.fromOffset(3, 3)
	inset.Size = UDim2.new(1, -6, 1, -6)
	inset.BackgroundTransparency = 1
	inset.ClipsDescendants = true
	inset.ZIndex = 2
	inset.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	Theme.corner(fill, math.ceil(barH * 0.5))

	local variant = fillVariant or "lime"
	local fillSpec = if variant == "gold"
		then UiAssets.controls.progressFillGold
		elseif variant == "cyan" then UiAssets.controls.progressFillCyan
		else UiAssets.controls.progressFillLime

	local fillArt = Instance.new("ImageLabel")
	fillArt.Name = "FillArt"
	fillArt.Size = UDim2.fromScale(1, 1)
	fillArt.BackgroundTransparency = 1
	fillArt.ZIndex = 2
	local hasFillArt = useArt and UiAssets.applySpec(fillArt, fillSpec)
	fillArt.Parent = fill

	if hasFillArt then
		fill.BackgroundTransparency = 1
	else
		local pal = if variant == "gold"
			then UiAssets.THEMES.gold
			elseif variant == "cyan" then UiAssets.THEMES.cyan
			else UiAssets.THEMES.lime
		makeGradient(fill, pal.top, pal.mid, pal.bot)
		local gloss = Instance.new("Frame")
		gloss.Name = "BarGloss"
		gloss.Position = UDim2.fromOffset(4, 2)
		gloss.Size = UDim2.new(1, -8, 0.38, 0)
		gloss.BackgroundColor3 = Color3.new(1, 1, 1)
		gloss.BackgroundTransparency = 0.45
		gloss.BorderSizePixel = 0
		gloss.ZIndex = 3
		Theme.corner(gloss, 6)
		gloss.Parent = fill
	end

	fill.Parent = inset
	track.Parent = parent
	return track, fill
end

-- Glossy cartoon toggle switch (44px+ touch target, animated cream thumb)
function Panel.toggle(
	parent: Instance,
	initial: boolean,
	onChanged: (boolean) -> ()
): (TextButton, (boolean) -> ())
	local value = initial
	local hit = Instance.new("TextButton")
	hit.Name = "CandyToggle"
	hit.Size = UDim2.fromOffset(76, 44)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false

	local pill = Instance.new("Frame")
	pill.Name = "Track"
	pill.AnchorPoint = Vector2.new(0.5, 0.5)
	pill.Position = UDim2.fromScale(0.5, 0.5)
	pill.Size = UDim2.fromOffset(72, 38)
	pill.BorderSizePixel = 0
	Theme.corner(pill, 19)
	local pillStroke = Instance.new("UIStroke")
	pillStroke.Color = UiAssets.OUTLINE
	pillStroke.Thickness = 3.5
	pillStroke.Parent = pill
	pill.Parent = hit

	local trackArt = Instance.new("ImageLabel")
	trackArt.Name = "TrackArt"
	trackArt.Size = UDim2.fromScale(1, 1)
	trackArt.BackgroundTransparency = 1
	trackArt.ZIndex = 1
	trackArt.Parent = pill

	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Size = UDim2.fromOffset(30, 30)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 252, 242)
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 3
	Theme.corner(thumb, 15)
	local thumbStroke = Instance.new("UIStroke")
	thumbStroke.Color = UiAssets.OUTLINE
	thumbStroke.Thickness = 3
	thumbStroke.Parent = thumb

	local thumbArt = Instance.new("ImageLabel")
	thumbArt.Name = "ThumbArt"
	thumbArt.Size = UDim2.fromScale(1, 1)
	thumbArt.BackgroundTransparency = 1
	thumbArt.ZIndex = 4
	if UiAssets.applySpec(thumbArt, UiAssets.controls.toggleThumb) then
		thumb.BackgroundTransparency = 1
		thumbStroke.Enabled = false
	end
	thumbArt.Parent = thumb
	thumb.Parent = pill

	local function apply(nextVal: boolean, animate: boolean)
		value = nextVal
		local hasArt = UiAssets.applySpec(
			trackArt,
			if value then UiAssets.controls.toggleOn else UiAssets.controls.toggleOff
		)
		if hasArt then
			pill.BackgroundTransparency = 1
			pillStroke.Enabled = false
		else
			pill.BackgroundTransparency = 0
			pillStroke.Enabled = true
			if value then
				local p = UiAssets.THEMES.lime
				pill.BackgroundColor3 = Color3.new(1, 1, 1)
				makeGradient(pill, p.top, p.mid, p.bot)
			else
				pill.BackgroundColor3 = Color3.new(1, 1, 1)
				makeGradient(
					pill,
					Color3.fromRGB(142, 132, 173),
					Color3.fromRGB(102, 92, 136),
					Color3.fromRGB(74, 65, 105)
				)
			end
		end
		local targetPos = if value then UDim2.fromScale(0.74, 0.5) else UDim2.fromScale(0.26, 0.5)
		if animate and player:GetAttribute("ReduceEffects") ~= true then
			TweenService:Create(
				thumb,
				TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Position = targetPos }
			):Play()
		else
			thumb.Position = targetPos
		end
	end

	Motion.mount(hit)
	hit.Activated:Connect(function()
		apply(not value, true)
		onChanged(value)
	end)
	apply(initial, false)
	hit.Parent = parent
	return hit, function(v: boolean)
		apply(v, false)
	end
end

-- Glossy pulsing notification badge dot
function Panel.badge(parent: Instance, text: string?): Frame
	local dot = Instance.new("Frame")
	dot.Name = "NotificationBadge"
	dot.Size = UDim2.fromOffset(24, 24)
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.BorderSizePixel = 0
	dot.ZIndex = 12
	Theme.corner(dot, 12)

	local art = Instance.new("ImageLabel")
	art.Name = "BadgeArt"
	art.Size = UDim2.fromScale(1, 1)
	art.BackgroundTransparency = 1
	art.ZIndex = 12
	if UiAssets.applySpec(art, UiAssets.controls.badgeDot) then
		dot.BackgroundTransparency = 1
	else
		local p = UiAssets.BUTTONS.red
		makeGradient(dot, p.top, p.mid, p.bot)
		local s = Instance.new("UIStroke")
		s.Color = UiAssets.OUTLINE
		s.Thickness = 2.5
		s.Parent = dot
		local glint = Instance.new("Frame")
		glint.Position = UDim2.fromOffset(4, 3)
		glint.Size = UDim2.fromOffset(6, 4)
		glint.BackgroundColor3 = Color3.new(1, 1, 1)
		glint.BackgroundTransparency = 0.15
		glint.BorderSizePixel = 0
		glint.ZIndex = 13
		Theme.corner(glint, 3)
		glint.Parent = dot
	end
	art.Parent = dot

	if text and text ~= "" then
		local lbl = Panel.label(dot, text, 13, Color3.new(1, 1, 1))
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.TextScaled = true
		lbl.TextStrokeTransparency = 0.1
		lbl.ZIndex = 14
	end

	Motion.pulseBadge(dot)
	dot.Parent = parent
	return dot
end

-- Escalating rarity creature card container (Common -> Mythic)
function Panel.rarityCard(parent: Instance, rarity: string): Frame
	local rank = math.max(1, Theme.rarityRank(rarity))
	local rarityColor = Theme.rarity[rarity] or Theme.crystal
	local card = Instance.new("Frame")
	card.Name = "RarityCard_" .. rarity
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.BorderSizePixel = 0
	Theme.corner(card, 18)

	local art = Instance.new("ImageLabel")
	art.Name = "RarityFrameArt"
	art.Size = UDim2.fromScale(1, 1)
	art.BackgroundTransparency = 1
	art.ZIndex = 0
	local hasArt = UiAssets.applySpec(art, UiAssets.rarityCards[rarity])
	art.Parent = card

	if hasArt then
		card.BackgroundTransparency = 1
	else
		local topCol = rarityColor:Lerp(Color3.new(1, 1, 1), 0.34)
		local botCol = rarityColor:Lerp(UiAssets.OUTLINE, 0.30)
		if rank >= 6 then
			Theme.iridescent(card)
		else
			makeGradient(card, topCol, rarityColor, botCol)
		end
		local stroke = Instance.new("UIStroke")
		stroke.Color = UiAssets.OUTLINE
		stroke.Thickness = if rank >= 5 then 4.5 elseif rank >= 3 then 3.5 else 3
		stroke.Parent = card

		local trim = Instance.new("Frame")
		trim.Name = "InnerTrim"
		trim.Position = UDim2.fromOffset(5, 5)
		trim.Size = UDim2.new(1, -10, 1, -10)
		trim.BackgroundColor3 = if rank >= 3 then UiAssets.GOLD_MID else UiAssets.CREAM_CARD
		trim.BorderSizePixel = 0
		trim.ZIndex = 0
		Theme.corner(trim, 14)
		trim.Parent = card

		local field = Instance.new("Frame")
		field.Name = "CardField"
		field.Position = UDim2.fromOffset(if rank >= 3 then 8 else 6, if rank >= 3 then 8 else 6)
		field.Size = UDim2.new(1, if rank >= 3 then -16 else -12, 1, if rank >= 3 then -16 else -12)
		field.BackgroundColor3 = UiAssets.CREAM_CARD
		field.BorderSizePixel = 0
		field.ZIndex = 0
		Theme.corner(field, 12)
		field.Parent = card
	end

	if rank >= 4 then
		Motion.shimmer(card, if rank >= 5 then 3.6 else 5.2)
	end
	card.Parent = parent
	return card
end

local function makeTitleIconGlyph(
	parent: Instance,
	icon: string,
	size: number,
	color: Color3
): TextLabel
	local label = Panel.label(parent, icon, size, color)
	label.TextStrokeTransparency = 1
	label.TextScaled = true
	label.Size = UDim2.fromScale(1, 1)
	return label
end

function Panel.create(
	id: string,
	title: string,
	accent: Color3,
	heightScale: number?,
	maxHeight: number?,
	wide: boolean?
): (ScreenGui, ScrollingFrame, TextLabel)
	-- Resolve official screen theme (cyan=Collection, orange=Shop, lime=Missions, gold=Achievements,
	-- purple=Prestige, pink=Leaderboard, steel=Settings)
	local theme = UiAssets.themeForPanel(id, accent)

	local gui = Instance.new("ScreenGui")
	gui.Name = id .. "Screen"
	gui.Enabled = false
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 8
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(22, 10, 44)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Active = true
	backdrop.Parent = gui

	-- Shell (CandyPanel)
	local shell = Instance.new("Frame")
	shell.Name = "CandyPanel"
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.53)
	shell.BackgroundColor3 = Color3.new(1, 1, 1)
	shell.BorderSizePixel = 0
	shell.ZIndex = 2
	shell.ClipsDescendants = false
	Theme.corner(shell, 30)

	-- Native 9-slice panel body image (activates automatically when uploaded!)
	local bodyArt = Instance.new("ImageLabel")
	bodyArt.Name = "PanelBodyArt"
	bodyArt.Size = UDim2.fromScale(1, 1)
	bodyArt.BackgroundTransparency = 1
	bodyArt.ZIndex = 1
	local hasBodyArt = UiAssets.applySpec(bodyArt, UiAssets.panelBodies[theme.name])
	bodyArt.Parent = shell

	local outline = Instance.new("UIStroke")
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Color = UiAssets.OUTLINE
	outline.Thickness = 6
	outline.Enabled = not hasBodyArt
	outline.Parent = shell

	local shadow = Instance.new("Frame")
	shadow.Name = "SoftShadow"
	shadow.Position = UDim2.fromOffset(0, 9)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.BackgroundColor3 = UiAssets.OUTLINE
	shadow.BackgroundTransparency = 0.56
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 0
	shadow.Visible = not hasBodyArt
	Theme.corner(shadow, 30)
	shadow.Parent = shell

	if hasBodyArt then
		shell.BackgroundTransparency = 1
	else
		makeGradient(shell, theme.top, theme.mid, theme.bot)

		-- Top glossy rim highlight on the plump outer tube
		local topGloss = Instance.new("Frame")
		topGloss.Name = "FrameTopGloss"
		topGloss.AnchorPoint = Vector2.new(0.5, 0)
		topGloss.Position = UDim2.new(0.5, 0, 0, 3)
		topGloss.Size = UDim2.new(1, -36, 0, 6)
		topGloss.BackgroundColor3 = theme.rim
		topGloss.BackgroundTransparency = 0.18
		topGloss.BorderSizePixel = 0
		topGloss.ZIndex = 1
		Theme.corner(topGloss, 6)
		topGloss.Parent = shell

		-- Bottom 3D shaded tube cushion
		local botLip = Instance.new("Frame")
		botLip.Name = "FrameBottomLip"
		botLip.AnchorPoint = Vector2.new(0.5, 1)
		botLip.Position = UDim2.new(0.5, 0, 1, -2)
		botLip.Size = UDim2.new(1, -10, 0, 14)
		botLip.BackgroundColor3 = theme.lip
		botLip.BackgroundTransparency = 0.25
		botLip.BorderSizePixel = 0
		botLip.ZIndex = 1
		Theme.corner(botLip, 22)
		botLip.Parent = shell

		-- Shiny metallic-gold inner molding ring (matching painel.png & panel_body_*.png!)
		local goldRing = Instance.new("Frame")
		goldRing.Name = "GoldMolding"
		goldRing.Position = UDim2.fromOffset(10, 10)
		goldRing.Size = UDim2.new(1, -20, 1, -20)
		goldRing.BackgroundColor3 = Color3.new(1, 1, 1)
		goldRing.BorderSizePixel = 0
		goldRing.ZIndex = 1
		Theme.corner(goldRing, 24)
		makeGradient(goldRing, UiAssets.GOLD_TOP, UiAssets.GOLD_MID, UiAssets.GOLD_BOT)
		local goldStroke = Instance.new("UIStroke")
		goldStroke.Color = UiAssets.OUTLINE_SOFT
		goldStroke.Thickness = 2
		goldStroke.Parent = goldRing
		goldRing.Parent = shell
	end

	-- Cream interior container (always present so scroll & children have exact padding/name!)
	local inner = Instance.new("Frame")
	inner.Name = "CreamInterior"
	inner.Position = UDim2.fromOffset(15, 15)
	inner.Size = UDim2.new(1, -30, 1, -30)
	inner.BackgroundColor3 = UiAssets.CREAM
	inner.BackgroundTransparency = if hasBodyArt then 1 else 0
	inner.BorderSizePixel = 0
	inner.ZIndex = 2
	Theme.corner(inner, 20)
	if not hasBodyArt then
		local innerStroke = Instance.new("UIStroke")
		innerStroke.Color = UiAssets.OUTLINE_SOFT
		innerStroke.Thickness = 2
		innerStroke.Transparency = 0.15
		innerStroke.Parent = inner
	end
	inner.Parent = shell

	local scale = Instance.new("UIScale")
	scale.Name = "PanelScale"
	scale.Scale = 1
	scale.Parent = shell
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1.28
	ratio.DominantAxis = Enum.DominantAxis.Width
	ratio.Parent = shell
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(300, 250)
	bounds.MaxSize = Vector2.new(760, maxHeight or 570)
	bounds.Parent = shell

	-- Floating glossy 3D Title Ribbon
	local tab = Instance.new("Frame")
	tab.Name = "TitleRibbon"
	tab.AnchorPoint = Vector2.new(0.5, 0.5)
	tab.Position = UDim2.new(0.5, 0, 0, 6)
	tab.Size = UDim2.new(0.69, 0, 0, 54)
	tab.BackgroundColor3 = Color3.new(1, 1, 1)
	tab.BorderSizePixel = 0
	tab.ZIndex = 4
	Theme.corner(tab, 26)

	local headerArt = Instance.new("ImageLabel")
	headerArt.Name = "HeaderArt"
	headerArt.Size = UDim2.fromScale(1, 1)
	headerArt.BackgroundTransparency = 1
	headerArt.ZIndex = 4
	local hasHeaderArt = UiAssets.applySpec(headerArt, UiAssets.panelHeaders[theme.name])
	headerArt.Parent = tab

	local tabStroke = Instance.new("UIStroke")
	tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tabStroke.Color = UiAssets.OUTLINE
	tabStroke.Thickness = 4.5
	tabStroke.Enabled = not hasHeaderArt
	tabStroke.Parent = tab

	if hasHeaderArt then
		tab.BackgroundTransparency = 1
	else
		makeGradient(tab, theme.top, theme.mid, theme.bot)
		local tabLip = Instance.new("Frame")
		tabLip.Name = "RibbonLip"
		tabLip.AnchorPoint = Vector2.new(0.5, 1)
		tabLip.Position = UDim2.new(0.5, 0, 1, -2)
		tabLip.Size = UDim2.new(1, -10, 0, 9)
		tabLip.BackgroundColor3 = theme.lip
		tabLip.BackgroundTransparency = 0.2
		tabLip.BorderSizePixel = 0
		tabLip.ZIndex = 4
		Theme.corner(tabLip, 14)
		tabLip.Parent = tab

		local tabGloss = Instance.new("Frame")
		tabGloss.Name = "RibbonGloss"
		tabGloss.AnchorPoint = Vector2.new(0.5, 0)
		tabGloss.Position = UDim2.new(0.5, 0, 0, 3)
		tabGloss.Size = UDim2.new(1, -24, 0.36, 0)
		tabGloss.BackgroundColor3 = Color3.new(1, 1, 1)
		tabGloss.BackgroundTransparency = 0.34
		tabGloss.BorderSizePixel = 0
		tabGloss.ZIndex = 4
		Theme.corner(tabGloss, 14)
		local tg = Instance.new("UIGradient")
		tg.Rotation = 90
		tg.Transparency = NumberSequence.new(0.05, 0.92)
		tg.Parent = tabGloss
		tabGloss.Parent = tab
	end
	Motion.shimmer(tab, 7.5)

	-- Title Icon Medallion (uses real uploaded menu icon / UiAssets icon / emoji fallback + gentle breathe!)
	local iconHolder = Instance.new("Frame")
	iconHolder.Name = "TitleIcon"
	iconHolder.AnchorPoint = Vector2.new(0, 0.5)
	iconHolder.Position = UDim2.new(0, 10, 0.5, -1)
	iconHolder.Size = UDim2.fromOffset(44, 44)
	iconHolder.BackgroundColor3 = UiAssets.CREAM_CARD
	iconHolder.BorderSizePixel = 0
	iconHolder.ZIndex = 6
	Theme.corner(iconHolder, 22)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = UiAssets.OUTLINE
	iconStroke.Thickness = 3.2
	iconStroke.Parent = iconHolder

	local defaultGlyph = ICONS[id] or "✨"
	local glyphLabel = makeTitleIconGlyph(iconHolder, defaultGlyph, 26, Theme.ink)
	glyphLabel.ZIndex = 7

	local iconKey = PANEL_ICON_KEYS[id]
	local artIconId = (if iconKey then UiAssets.iconId(iconKey) else nil)
		or UiAssets.UPLOADED_NAV_ICONS[id]
	if artIconId then
		local iconImg = Instance.new("ImageLabel")
		iconImg.Name = "TitleIconArt"
		iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
		iconImg.Position = UDim2.fromScale(0.5, 0.5)
		iconImg.Size = UDim2.fromScale(0.96, 0.96)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = artIconId
		iconImg.ScaleType = Enum.ScaleType.Fit
		iconImg.ZIndex = 7
		iconImg.Parent = iconHolder
		glyphLabel.Visible = false
		-- If a panel (e.g. Collection->Milestones or Leaderboard->Album) changes glyphLabel.Text,
		-- show the emoji seamlessly and restore the image when it returns to default!
		local textConn = glyphLabel:GetPropertyChangedSignal("Text"):Connect(function()
			local isDefault = glyphLabel.Text == defaultGlyph
			iconImg.Visible = isDefault
			glyphLabel.Visible = not isDefault
		end)
		iconHolder.Destroying:Once(function()
			textConn:Disconnect()
		end)
	end
	Motion.breathe(iconHolder, 0.04, 2.6)
	iconHolder.Parent = tab

	local heading = Panel.label(tab, title, 26, Color3.fromRGB(255, 253, 240))
	heading.Name = "PanelTitle"
	heading.AnchorPoint = Vector2.new(0, 0.5)
	heading.Position = UDim2.new(0, 60, 0.5, -2)
	heading.Size = UDim2.new(1, -72, 0, 38)
	heading.TextWrapped = true
	heading.TextScaled = true
	heading.TextStrokeColor3 = UiAssets.OUTLINE
	heading.TextStrokeTransparency = 0
	heading.ZIndex = 6
	local headingSize = Instance.new("UITextSizeConstraint")
	headingSize.MaxTextSize = 26
	headingSize.MinTextSize = 12
	headingSize.Parent = heading
	tab.Parent = shell

	-- Glossy Red Circular Close X Button (48x48 >= 44px touch target!)
	local close = Instance.new("TextButton")
	close.Name = "CloseButton"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, 4, 0, -10)
	close.Size = UDim2.fromOffset(48, 48)
	close.Text = "X"
	close.TextSize = 26
	close.Font = Theme.font
	close.TextColor3 = Color3.new(1, 1, 1)
	close.TextStrokeColor3 = UiAssets.OUTLINE
	close.TextStrokeTransparency = 0.15
	close.BackgroundColor3 = Color3.new(1, 1, 1)
	close.AutoButtonColor = false
	close.BorderSizePixel = 0
	close.ZIndex = 9
	Theme.corner(close, 24)

	local closeArt = Instance.new("ImageLabel")
	closeArt.Name = "CloseArt"
	closeArt.Size = UDim2.fromScale(1, 1)
	closeArt.BackgroundTransparency = 1
	closeArt.ZIndex = 9
	local hasCloseArt = UiAssets.applySpec(closeArt, UiAssets.controls.closeX)
	closeArt.Parent = close

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = UiAssets.OUTLINE
	closeStroke.Thickness = 4
	closeStroke.Enabled = not hasCloseArt
	-- Border, not Contextual: on a TextButton the default outlines the glyph and blobs the X.
	closeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	closeStroke.Parent = close

	if hasCloseArt then
		close.BackgroundTransparency = 1
		close.TextTransparency = 1
		close.TextStrokeTransparency = 1
	else
		local redPal = UiAssets.BUTTONS.red
		makeGradient(close, redPal.top, redPal.mid, redPal.bot)
		local closeGloss = Instance.new("Frame")
		closeGloss.Name = "CloseGloss"
		closeGloss.AnchorPoint = Vector2.new(0.5, 0)
		closeGloss.Position = UDim2.new(0.5, 0, 0, 3)
		closeGloss.Size = UDim2.fromScale(0.68, 0.32)
		closeGloss.BackgroundColor3 = Color3.new(1, 1, 1)
		closeGloss.BackgroundTransparency = 0.32
		closeGloss.BorderSizePixel = 0
		closeGloss.ZIndex = 9
		Theme.corner(closeGloss, 12)
		closeGloss.Parent = close
	end

	Motion.mount(close, nil, nil, {
		onPressChange = function(pressed: boolean)
			if hasCloseArt then
				UiAssets.applySpec(
					closeArt,
					if pressed then UiAssets.controls.closeXPressed else UiAssets.controls.closeX
				)
			else
				local redPal = UiAssets.BUTTONS.red
				makeGradient(
					close,
					if pressed then redPal.pressedTop else redPal.top,
					if pressed then redPal.pressedMid else redPal.mid,
					if pressed then redPal.pressedBot else redPal.bot
				)
			end
		end,
	})
	close.Activated:Connect(function()
		Hud.showPanel("")
	end)
	close.Parent = shell

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Content"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(22, 56)
	scroll.Size = UDim2.new(1, -44, 1, -70)
	scroll.ZIndex = 2
	scroll.ScrollBarThickness = 6
	scroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
	scroll.ScrollBarImageColor3 = theme.mid
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = inner

	local function fit()
		local size = gui.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		local insetTop = GuiService:GetGuiInset()
		-- Short landscape screens (phones) give every panel the compact frame, so the content
		-- gets the height instead of the margins and header gap.
		local compact = size.X > size.Y and (wide == true or size.Y < 450)
		local topSafe = if compact then 21 else math.max(math.round(insetTop.Y) + 18, 66)
		local availHeight = if compact
			then math.max(1, size.Y - topSafe - 12)
			else math.max(240, size.Y - topSafe - 16)
		local width =
			math.min(size.X * (if compact then 0.94 else 0.88), if wide then 1120 else 760)
		local height = math.min(availHeight * (heightScale or 0.92), maxHeight or 570)
		local viewRatio = math.clamp(width / math.max(height, 1), if wide then 0.52 else 0.68, 2.8)
		if width / math.max(height, 1) > viewRatio then
			width = height * viewRatio
		else
			height = width / viewRatio
		end
		ratio.AspectRatio = viewRatio
		shell.Size = UDim2.fromOffset(width, height)
		shell.Position = UDim2.new(0.5, 0, 0, topSafe + math.floor((size.Y - topSafe) * 0.5))
		local narrow = width <= 420
		tab.Size = UDim2.new(if compact then 0.50 elseif narrow then 0.80 else 0.69, 0, 0, 52)
		tab.Position = UDim2.new(if compact then 0.27 elseif narrow then 0.44 else 0.5, 0, 0, 6)
		local sidePad = if compact then 12 elseif narrow then 14 else 22
		local topPad = if compact then 34 else 56
		local bottomPad = if compact then 10 else 14
		if hasBodyArt then
			-- The art's frame is about 83 source pixels thick: thin it on compact screens and
			-- keep the content clear of it on every side.
			local frameScale = if compact then 0.24 else 0.34
			bodyArt.SliceScale = frameScale
			local frame = math.ceil(83 * frameScale) + 4
			local innerInset = inner.Position.X.Offset
			sidePad = math.max(sidePad, frame - innerInset)
			bottomPad = math.max(bottomPad, frame - innerInset)
		end
		scroll.Position = UDim2.fromOffset(sidePad, topPad)
		scroll.Size = UDim2.new(1, -(sidePad * 2), 1, -topPad - bottomPad)
	end

	local resizeConn = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	shell.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	fit()

	local panelConn = Hud.panelChanged:Connect(function(name: string)
		local opened = name == id or (id == "Collection" and name == "Milestones")
		if opened and not gui.Enabled then
			Motion.popOpen(shell, backdrop)
		end
		gui.Enabled = opened
	end)
	gui.Destroying:Once(function()
		resizeConn:Disconnect()
		panelConn:Disconnect()
	end)
	return gui, scroll, heading
end

function Panel.stack(parent: Instance)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
end

return Panel
