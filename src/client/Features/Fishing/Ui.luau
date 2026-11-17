--!strict
-- Fishing HUD: the minigame panel (hint + play area + instruction) and short toasts.
-- Everything is Scale-based so it fits phones in landscape and PC.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Art = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("Art"))
local Ui = {}
local rarityByHint: { [string]: string } = {}
for rarity, text in Strings.hint do
	rarityByHint[text] = rarity
end

local gui: ScreenGui
local panel: Frame
local hint: TextLabel
local rarityBadge: ImageLabel
local rarityName: TextLabel
local instruction: TextLabel
local area: Frame
local toastLabel: TextLabel
local activeToast: Tween? = nil
local panelTween: Tween? = nil

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

function Ui.gloss(target: Frame, color: Color3)
	Theme.surface(target, color, 18)
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
	l.Font = Theme.font
	l.TextStrokeTransparency = 0.2
	l.TextStrokeColor3 = Color3.fromRGB(40, 21, 83)
	l.Parent = parent
	return l
end

function Ui.init()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = Instance.new("ScreenGui")
	gui.Name = "FishingUI"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 5
	gui.Parent = playerGui

	panel = Ui.frame(
		gui,
		"Panel",
		UDim2.fromScale(0.86, 0.42),
		UDim2.fromScale(0.5, 0.75),
		Color3.fromRGB(14, 18, 40),
		0.25
	)
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Visible = false
	Art.panel(panel, Theme.crystal)
	local band = Ui.frame(
		panel,
		"CrystalTrim",
		UDim2.fromScale(0.82, 0.025),
		UDim2.fromScale(0.09, 0.205),
		Theme.crystal
	)
	Theme.corner(band, 3)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 2.9
	ratio.Parent = panel
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(620, 260)
	size.MinSize = Vector2.new(228, 96)
	size.Parent = panel

	rarityBadge, rarityName = Art.rarity(panel)
	rarityBadge.AnchorPoint = Vector2.new(0.5, 0)
	rarityBadge.Position = UDim2.fromScale(0.5, 0.025)
	rarityBadge.Size = UDim2.fromScale(0.43, 0.19)
	rarityBadge.Visible = false
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
		UDim2.fromScale(0.86, 0.53),
		UDim2.fromScale(0.07, 0.26),
		Color3.new(0, 0, 0),
		1
	)
	instruction = Ui.label(
		panel,
		"Instruction",
		UDim2.fromScale(0.86, 0.105),
		UDim2.fromScale(0.07, 0.81),
		"",
		Theme.sand
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
	if panelTween then
		panelTween:Cancel()
		panelTween = nil
	end
	local ratio = panel:FindFirstChildOfClass("UIAspectRatioConstraint")
	local bounds = panel:FindFirstChildOfClass("UISizeConstraint")
	if ratio then
		ratio.AspectRatio = 2.9
	end
	if bounds then
		bounds.MinSize = Vector2.new(228, 96)
		bounds.MaxSize = Vector2.new(620, 260)
	end
	panel.Size = UDim2.fromScale(0.86, 0.42)
	area.Size = UDim2.fromScale(0.86, 0.53)
	area.Position = UDim2.fromScale(0.07, 0.26)
	instruction.Size = UDim2.fromScale(0.86, 0.105)
	instruction.Position = UDim2.fromScale(0.07, 0.81)
	if activeToast then
		activeToast:Cancel()
		activeToast = nil
	end
	toastLabel.TextTransparency = 1
	toastLabel.TextStrokeTransparency = 1
	for _, child in area:GetChildren() do
		child:Destroy()
	end
	local rarity = rarityByHint[hintText]
	hint.Text = hintText
	hint.TextColor3 = color
	hint.Visible = rarity == nil
	rarityBadge.Visible = rarity ~= nil
	if rarity then
		Art.setRarity(rarityBadge, rarityName, rarity)
	end
	instruction.Text = instructionText
	panel.Visible = true
	if Players.LocalPlayer:GetAttribute("ReduceEffects") == true then
		panel.Position = UDim2.fromScale(0.5, 0.75)
	else
		panel.Position = UDim2.fromScale(0.5, 1.2)
		local tween = TweenService:Create(
			panel,
			TweenInfo.new(0.25, Enum.EasingStyle.Back),
			{ Position = UDim2.fromScale(0.5, 0.75) }
		)
		panelTween = tween
		tween:Play()
	end
	return area
end

function Ui.hidePanel()
	if panelTween then
		panelTween:Cancel()
		panelTween = nil
	end
	panel.Visible = false
	for _, child in area:GetChildren() do
		child:Destroy()
	end
end

function Ui.reelLayout()
	if panelTween then
		panelTween:Cancel()
		panelTween = nil
	end
	local ratio = panel:FindFirstChildOfClass("UIAspectRatioConstraint")
	local bounds = panel:FindFirstChildOfClass("UISizeConstraint")
	if ratio then
		ratio.AspectRatio = 1.5
	end
	if bounds then
		bounds.MinSize = Vector2.new(250, 167)
		bounds.MaxSize = Vector2.new(420, 280)
	end
	panel.Size = UDim2.fromScale(0.54, 0.68)
	panel.Position = UDim2.fromScale(0.5, 0.94)
	area.Size = UDim2.fromScale(0.86, 0.61)
	area.Position = UDim2.fromScale(0.07, 0.25)
	instruction.Size = UDim2.fromScale(0.9, 0.065)
	instruction.Position = UDim2.fromScale(0.05, 0.885)
	local controls = Text.minigames
	instruction.Text = if UserInputService.TouchEnabled
		then controls.reelControls
		else controls.reelKeyboard
end

function Ui.feedback(target: Frame, success: boolean, perfect: boolean?)
	Audio.play(if success then "hit" else "miss", 0.2, if perfect then 1.28 else 1)
	local color = if success then Theme.crystal else Color3.fromRGB(255, 123, 123)
	local message = if perfect then Text.perfect elseif success then Text.hit else Text.miss
	local badge = Ui.label(
		target,
		"TimingFeedback",
		UDim2.fromScale(0.46, 0.25),
		UDim2.fromScale(0.27, -0.04),
		message,
		color
	)
	badge.ZIndex = 5
	TweenService:Create(badge, TweenInfo.new(0.38), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Position = UDim2.fromScale(0.27, -0.2),
	}):Play()
	task.delay(0.4, function()
		badge:Destroy()
	end)
	if not success then
		Effects.shake(0.18, 0.45)
	end
	if success and Players.LocalPlayer:GetAttribute("ReduceEffects") ~= true then
		for index = 1, 6 do
			local angle = index * math.pi / 3
			local spark =
				Ui.frame(target, "Spark", UDim2.fromOffset(5, 5), UDim2.fromScale(0.5, 0.3), color)
			spark.Rotation = 45
			TweenService:Create(spark, TweenInfo.new(0.3), {
				Position = UDim2.fromScale(
					0.5 + math.cos(angle) * 0.23,
					0.3 + math.sin(angle) * 0.35
				),
				BackgroundTransparency = 1,
			}):Play()
			task.delay(0.32, function()
				spark:Destroy()
			end)
		end
	end
end

function Ui.toast(text: string, color: Color3?)
	if activeToast then
		activeToast:Cancel()
	end
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
	activeToast = fade
	fade:Play()
end

return Ui
