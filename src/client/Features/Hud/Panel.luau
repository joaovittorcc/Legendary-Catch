--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Hud = require(script.Parent)
local Art = require(script.Parent:WaitForChild("Art"))
local Assets = require(script.Parent:WaitForChild("Assets"))

local Panel = {}

function Panel.label(parent: Instance, content: string, size: number, color: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, size * 2)
	label.BackgroundTransparency = 1
	label.Text = content
	label.TextWrapped = true
	label.TextColor3 = color or Theme.sand
	label.TextSize = size
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
	button.Font = Theme.font
	Theme.surface(button, accent, 10)
	button.Parent = parent
	return button
end

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
	gui.DisplayOrder = 8
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local shell = Instance.new("Frame")
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, if heightScale then 0.53 else 0.55)
	shell.Size = UDim2.fromScale(0.85, heightScale or 0.72)
	shell.BackgroundTransparency = 1
	local background = Art.image(shell, Assets.panel, "PanelArt")
	Art.slice(background, Rect.new(95, 93, 929, 510), 0.18)
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(680, maxHeight or 530)
	bounds.Parent = shell
	shell.Parent = gui

	local trim = Instance.new("Frame")
	trim.Name = "HeaderTrim"
	trim.BackgroundColor3 = accent
	trim.BackgroundTransparency = 0.42
	trim.BorderSizePixel = 0
	trim.Position = UDim2.fromOffset(14, 53)
	trim.Size = UDim2.new(1, -28, 0, 1)
	trim.Parent = shell

	local heading = Panel.label(shell, title, 22, accent)
	heading.Size = UDim2.new(1, -112, 0, 48)
	heading.TextScaled = true
	local headingSize = Instance.new("UITextSizeConstraint")
	headingSize.MaxTextSize = 22
	headingSize.Parent = heading
	local close = Panel.button(shell, Text.close, accent)
	close.Size = UDim2.fromOffset(86, 44)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -16, 0, 9)
	close.Activated:Connect(function()
		Hud.showPanel("")
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(16, 58)
	scroll.Size = UDim2.new(1, -32, 1, -73)
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = accent
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = shell

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = scroll
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui, scroll, heading
end

function Panel.stack(parent: Instance)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
end

return Panel
