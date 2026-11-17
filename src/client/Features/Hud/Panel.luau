--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Hud = require(script.Parent)

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

function Panel.create(id: string, title: string, accent: Color3): (ScreenGui, ScrollingFrame)
	local gui = Instance.new("ScreenGui")
	gui.Name = id .. "Screen"
	gui.Enabled = false
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 8
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local shell = Instance.new("Frame")
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.53)
	shell.Size = UDim2.fromScale(0.84, 0.73)
	Theme.surface(shell, accent, 16)
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(680, 530)
	bounds.Parent = shell
	shell.Parent = gui

	local heading = Panel.label(shell, title, 22, accent)
	heading.Size = UDim2.new(1, -120, 0, 48)
	local close = Panel.button(shell, Text.close, accent)
	close.Size = UDim2.fromOffset(86, 44)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -8, 0, 6)
	close.Activated:Connect(function()
		Hud.showPanel("")
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(10, 58)
	scroll.Size = UDim2.new(1, -20, 1, -66)
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = accent
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
	return gui, scroll
end

function Panel.stack(parent: Instance)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
end

return Panel
