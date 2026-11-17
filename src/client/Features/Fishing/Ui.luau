--!strict
-- Fishing HUD: the minigame panel (hint + play area + instruction) and short toasts.
-- Everything is Scale-based so it fits phones in landscape and PC.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Ui = {}

local gui: ScreenGui
local panel: Frame
local hint: TextLabel
local instruction: TextLabel
local area: Frame
local toastLabel: TextLabel

function Ui.corner(target: GuiObject, scale: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale or 0.25, 0)
	c.Parent = target
end

function Ui.stroke(target: GuiObject, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = target
end

function Ui.frame(
	parent: Instance,
	name: string,
	size: UDim2,
	position: UDim2,
	color: Color3,
	transparency: number?
): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = color
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

function Ui.label(
	parent: Instance,
	name: string,
	size: UDim2,
	position: UDim2,
	text: string,
	color: Color3
): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = position
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextStrokeTransparency = 0.4
	l.Parent = parent
	return l
end

function Ui.init()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = Instance.new("ScreenGui")
	gui.Name = "FishingUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 5
	gui.Parent = playerGui

	panel = Ui.frame(
		gui,
		"Panel",
		UDim2.fromScale(0.46, 0.3),
		UDim2.fromScale(0.5, 0.86),
		Color3.fromRGB(14, 18, 40),
		0.25
	)
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Visible = false
	Ui.corner(panel, 0.12)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 2.6
	ratio.Parent = panel
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(620, 260)
	size.MinSize = Vector2.new(320, 120)
	size.Parent = panel

	hint = Ui.label(
		panel,
		"Hint",
		UDim2.fromScale(0.9, 0.18),
		UDim2.fromScale(0.05, 0.03),
		"",
		Color3.new(1, 1, 1)
	)
	area = Ui.frame(
		panel,
		"Area",
		UDim2.fromScale(0.9, 0.6),
		UDim2.fromScale(0.05, 0.23),
		Color3.new(0, 0, 0),
		1
	)
	instruction = Ui.label(
		panel,
		"Instruction",
		UDim2.fromScale(0.9, 0.12),
		UDim2.fromScale(0.05, 0.85),
		"",
		Color3.fromRGB(200, 210, 240)
	)

	toastLabel = Ui.label(
		gui,
		"Toast",
		UDim2.fromScale(0.6, 0.07),
		UDim2.fromScale(0.2, 0.18),
		"",
		Color3.new(1, 1, 1)
	)
	toastLabel.TextTransparency = 1
	toastLabel.TextStrokeTransparency = 1
end

function Ui.screen(): ScreenGui
	return gui
end

-- Shows the panel and returns the empty play area for the minigame to fill.
function Ui.showPanel(hintText: string, color: Color3, instructionText: string): Frame
	for _, child in area:GetChildren() do
		child:Destroy()
	end
	hint.Text = hintText
	hint.TextColor3 = color
	instruction.Text = instructionText
	panel.Visible = true
	panel.Position = UDim2.fromScale(0.5, 1.2)
	TweenService:Create(
		panel,
		TweenInfo.new(0.25, Enum.EasingStyle.Back),
		{ Position = UDim2.fromScale(0.5, 0.86) }
	):Play()
	return area
end

function Ui.hidePanel()
	panel.Visible = false
	for _, child in area:GetChildren() do
		child:Destroy()
	end
end

function Ui.toast(text: string, color: Color3?)
	toastLabel.Text = text
	toastLabel.TextColor3 = color or Color3.new(1, 1, 1)
	toastLabel.TextTransparency = 0
	toastLabel.TextStrokeTransparency = 0.4
	local fade = TweenService:Create(
		toastLabel,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.4),
		{
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)
	fade:Play()
end

return Ui
