--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Hud = require(script.Parent)
local Motion = require(script.Parent:WaitForChild("Motion"))

local Panel = {}
local player = Players.LocalPlayer
local panelBlur: BlurEffect? = nil
local activeScreens: { [ScreenGui]: Frame } = {}
local ICONS = {
	Collection = "🐠",
	Shop = "🎣",
	Robux = "💎",
	Missions = "📜",
	Milestones = "🏆",
	Settings = "⚙️",
}

function Panel.label(parent: Instance, content: string, size: number, color: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, size * 2)
	label.BackgroundTransparency = 1
	label.Text = content
	label.TextWrapped = true
	label.TextColor3 = color or Theme.ink
	label.TextSize = size
	label.TextStrokeColor3 = Theme.outline
	label.TextStrokeTransparency = 0.4
	label.Font = Theme.font
	label.Parent = parent
	return label
end

function Panel.button(parent: Instance, content: string, accent: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 46)
	button.Text = content
	button.TextColor3 = Theme.sand
	button.TextSize = 17
	button.TextStrokeColor3 = Theme.outline
	button.TextStrokeTransparency = 0.06
	button.Font = Theme.font
	button.AutoButtonColor = false
	button.TextTransparency = 1
	Theme.surface(button, accent, 14)
	local stroke = button:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Thickness = 3
	end
	local lip = Instance.new("Frame")
	lip.Name = "CandyLip"
	lip.AnchorPoint = Vector2.new(0, 1)
	lip.Position = UDim2.new(0, 2, 1, -2)
	lip.Size = UDim2.new(1, -4, 0, 7)
	lip.BackgroundColor3 = accent:Lerp(Theme.outline, 0.34)
	lip.BorderSizePixel = 0
	lip.ZIndex = button.ZIndex
	Theme.corner(lip, 9)
	lip.Parent = button
	local shine = Instance.new("Frame")
	shine.Name = "CandyShine"
	shine.Position = UDim2.new(0, 8, 0, 4)
	shine.Size = UDim2.new(1, -16, 0, 5)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.56
	shine.BorderSizePixel = 0
	shine.ZIndex = button.ZIndex + 1
	Theme.corner(shine, 5)
	shine.Parent = button
	local caption = Instance.new("TextLabel")
	caption.Name = "ButtonCaption"
	caption.AnchorPoint = Vector2.new(0.5, 0.5)
	caption.Position = UDim2.fromScale(0.5, 0.46)
	caption.Size = UDim2.new(1, -10, 1, -10)
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
	button:GetPropertyChangedSignal("Text"):Connect(function()
		caption.Text = button.Text
	end)
	button:GetPropertyChangedSignal("TextSize"):Connect(function()
		caption.TextSize = button.TextSize
	end)
	button:GetPropertyChangedSignal("TextScaled"):Connect(function()
		caption.TextScaled = button.TextScaled
	end)
	button:GetPropertyChangedSignal("TextWrapped"):Connect(function()
		caption.TextWrapped = button.TextWrapped
	end)
	button:GetPropertyChangedSignal("TextColor3"):Connect(function()
		caption.TextColor3 = button.TextColor3
	end)
	button:GetPropertyChangedSignal("TextStrokeColor3"):Connect(function()
		caption.TextStrokeColor3 = button.TextStrokeColor3
	end)
	button:GetPropertyChangedSignal("TextStrokeTransparency"):Connect(function()
		caption.TextStrokeTransparency = button.TextStrokeTransparency
	end)
	button:GetPropertyChangedSignal("Font"):Connect(function()
		caption.Font = button.Font
	end)
	Motion.mount(button)
	button.Parent = parent
	return button
end

function Panel.card(parent: Instance, accent: Color3, height: number): Frame
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, height)
	card.BackgroundColor3 = Theme.cream
	card.BorderSizePixel = 0
	Theme.corner(card, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Color = accent
	stroke.Thickness = 3
	stroke.Parent = card
	local shade = Instance.new("Frame")
	shade.Name = "CardShadow"
	shade.Position = UDim2.fromOffset(0, 4)
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Theme.outline
	shade.BackgroundTransparency = 0.82
	shade.BorderSizePixel = 0
	shade.ZIndex = 0
	Theme.corner(shade, 14)
	shade.Parent = card
	card.Parent = parent
	return card
end

function Panel.tintButton(button: TextButton, accent: Color3)
	local hue, saturation, value = accent:ToHSV()
	button.BackgroundColor3 = accent
	local gradient = button:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(
				0,
				Color3.fromHSV(hue, saturation * 0.8, math.min(value * 1.22, 1))
			),
			ColorSequenceKeypoint.new(0.2, accent),
			ColorSequenceKeypoint.new(
				1,
				Color3.fromHSV(hue, math.min(saturation * 1.08, 1), value * 0.78)
			),
		})
	end
	local lip = button:FindFirstChild("CandyLip")
	if lip and lip:IsA("Frame") then
		lip.BackgroundColor3 = accent:Lerp(Theme.outline, 0.34)
	end
end

local function buttonIcon(parent: Instance, icon: string, size: number, color: Color3)
	local label = Panel.label(parent, icon, size, color)
	label.TextStrokeTransparency = 1
	label.TextScaled = true
	label.Size = UDim2.fromScale(1, 1)
	return label
end

local function setOpen(gui: ScreenGui, shell: Frame, opened: boolean)
	if opened then
		gui.Enabled = true
		local scale = shell:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = if player:GetAttribute("ReduceEffects") == true then 1 else 0.85
			TweenService:Create(
				scale,
				TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end
		if player:GetAttribute("ReduceEffects") ~= true then
			if not panelBlur or panelBlur.Parent ~= Lighting then
				panelBlur = Instance.new("BlurEffect")
				panelBlur.Name = "CandyPanelBlur"
				panelBlur.Size = 0
				panelBlur.Parent = Lighting
			end
			TweenService:Create(panelBlur, TweenInfo.new(0.18), { Size = 9 }):Play()
		end
	elseif gui.Enabled then
		gui.Enabled = false
	end
	local anyOpen = false
	for screen in activeScreens do
		anyOpen = anyOpen or screen.Enabled
	end
	if not anyOpen and panelBlur then
		TweenService:Create(panelBlur, TweenInfo.new(0.16), { Size = 0 }):Play()
		task.delay(0.2, function()
			if panelBlur and panelBlur.Parent and panelBlur.Size < 0.1 then
				panelBlur:Destroy()
				panelBlur = nil
			end
		end)
	end
end

player:GetAttributeChangedSignal("ReduceEffects"):Connect(function()
	if not panelBlur then
		return
	end
	local target = if player:GetAttribute("ReduceEffects") == true then 0 else 9
	TweenService:Create(panelBlur, TweenInfo.new(0.16), { Size = target }):Play()
end)

function Panel.create(
	id: string,
	title: string,
	accent: Color3,
	heightScale: number?,
	maxHeight: number?
): (ScreenGui, ScrollingFrame, TextLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = id .. "Screen"
	gui.Enabled = false
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 8
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local shell = Instance.new("Frame")
	shell.Name = "CandyPanel"
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.53)
	shell.BackgroundColor3 = accent
	shell.BorderSizePixel = 0
	shell.ClipsDescendants = false
	Theme.corner(shell, 28)
	local outline = Instance.new("UIStroke")
	outline.Color = Theme.outline
	outline.Thickness = 6
	outline.Parent = shell
	local shadow = Instance.new("Frame")
	shadow.Name = "SoftShadow"
	shadow.Position = UDim2.fromOffset(0, 8)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.BackgroundColor3 = Theme.outline
	shadow.BackgroundTransparency = 0.58
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 0
	Theme.corner(shadow, 28)
	shadow.Parent = shell
	local inner = Instance.new("Frame")
	inner.Name = "CreamInterior"
	inner.Position = UDim2.fromOffset(9, 9)
	inner.Size = UDim2.new(1, -18, 1, -18)
	inner.BackgroundColor3 = Theme.cream
	inner.BorderSizePixel = 0
	inner.ZIndex = 1
	Theme.corner(inner, 21)
	inner.Parent = shell
	local scale = Instance.new("UIScale")
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
	local heading = Panel.label(shell, title, 26, Theme.sand)
	heading.Name = "PanelTitle"
	heading.AnchorPoint = Vector2.new(0.5, 0.5)
	heading.Position = UDim2.new(0.56, 0, 0, 3)
	heading.Size = UDim2.new(0.58, 0, 0, 44)
	heading.TextScaled = true
	heading.TextStrokeTransparency = 0.05
	heading.ZIndex = 5
	local headingSize = Instance.new("UITextSizeConstraint")
	headingSize.MaxTextSize = 26
	headingSize.MinTextSize = 15
	headingSize.Parent = heading
	local tab = Instance.new("Frame")
	tab.Name = "TitleRibbon"
	tab.AnchorPoint = Vector2.new(0.5, 0.5)
	tab.Position = UDim2.new(0.5, 0, 0, 7)
	tab.Size = UDim2.new(0.69, 0, 0, 48)
	tab.BackgroundColor3 = accent
	tab.BorderSizePixel = 0
	tab.ZIndex = 4
	Theme.corner(tab, 17)
	local tabStroke = Instance.new("UIStroke")
	tabStroke.Color = Theme.outline
	tabStroke.Thickness = 4
	tabStroke.Parent = tab
	local iconHolder = Instance.new("Frame")
	iconHolder.Name = "TitleIcon"
	iconHolder.AnchorPoint = Vector2.new(0, 0.5)
	iconHolder.Position = UDim2.new(0, 13, 0.5, 0)
	iconHolder.Size = UDim2.fromOffset(43, 43)
	iconHolder.BackgroundColor3 = Theme.cream
	iconHolder.BorderSizePixel = 0
	iconHolder.ZIndex = 6
	Theme.corner(iconHolder, 22)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Theme.outline
	iconStroke.Thickness = 3
	iconStroke.Parent = iconHolder
	buttonIcon(iconHolder, ICONS[id] or "✨", 29, Theme.ink).ZIndex = 7
	iconHolder.Parent = tab
	tab.Parent = shell

	local close = Instance.new("TextButton")
	close.Name = "CloseButton"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, 5, 0, -12)
	close.Size = UDim2.fromOffset(48, 48)
	close.Text = "×"
	close.TextSize = 36
	close.Font = Theme.font
	close.TextColor3 = Color3.new(1, 1, 1)
	close.TextStrokeColor3 = Theme.outline
	close.TextStrokeTransparency = 0
	close.BackgroundColor3 = Color3.fromRGB(247, 75, 91)
	close.AutoButtonColor = false
	close.ZIndex = 8
	Theme.corner(close, 24)
	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Theme.outline
	closeStroke.Thickness = 4
	closeStroke.Parent = close
	Motion.mount(close)
	close.Activated:Connect(function()
		Hud.showPanel("")
	end)
	close.Parent = shell

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Content"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(20, 44)
	scroll.Size = UDim2.new(1, -40, 1, -60)
	scroll.ZIndex = 2
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = accent
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = scroll
	scroll.Parent = inner

	local function fit()
		local size = gui.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		local width = math.min(size.X * 0.91, 760)
		local height = math.min(size.Y * (heightScale or 0.88), maxHeight or 570)
		local viewRatio = math.clamp(width / math.max(height, 1), 0.68, 2.8)
		if width / math.max(height, 1) > viewRatio then
			width = height * viewRatio
		else
			height = width / viewRatio
		end
		ratio.AspectRatio = viewRatio
		shell.Size = UDim2.fromOffset(width, height)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	shell.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	fit()
	activeScreens[gui] = shell
	Hud.panelChanged:Connect(function(name: string)
		setOpen(gui, shell, name == id or (id == "Collection" and name == "Milestones"))
	end)
	gui.Destroying:Once(function()
		activeScreens[gui] = nil
		if panelBlur and next(activeScreens) == nil then
			panelBlur:Destroy()
			panelBlur = nil
		end
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
