--!strict
-- Shared safe-area canvas and feedback for fishing and training.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))
local Ui = {}
local gui: ScreenGui
local area: Frame
local toastLabel: TextLabel
local activeToast: Tween? = nil
type Feedback = { badge: TextLabel, sparks: { Frame }, tweens: { Tween }, sequence: number }
local feedbackByTarget: { [Frame]: Feedback } = {}

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

	-- HUD features observe FishingUI.Panel.Visible to hide competing controls.
	area = Ui.frame(gui, "Panel", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Theme.ink, 1)
	area.Visible = false

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

local function rarityFromColor(color: Color3): string
	for _, rarity in FishingConfig.RARITY_ORDER do
		local c = FishingConfig.RARITY_COLORS[rarity]
		if
			c
			and math.abs(c.R - color.R) < 0.02
			and math.abs(c.G - color.G) < 0.02
			and math.abs(c.B - color.B) < 0.02
		then
			return rarity
		end
	end
	return "Common"
end

-- Controller entry point. Minigames place their controls directly on this transparent canvas.
function Ui.showPanel(hintText: string, color: Color3, _instructionText: string): Frame
	Ui.hidePanel()
	if activeToast then
		activeToast:Cancel()
		activeToast = nil
	end
	toastLabel.TextTransparency = 1
	toastLabel.TextStrokeTransparency = 1
	area.Visible = true
	if hintText ~= "" then
		local rarity = rarityFromColor(color)
		local glyph = Theme.rarityGlyph(rarity)
		local labelText = if glyph ~= "" then glyph .. "  " .. hintText else hintText
		local pill = Ui.frame(
			area,
			"RarityHint",
			UDim2.new(0.68, 0, 0, 32),
			UDim2.fromScale(0.5, 0.04),
			Theme.ink
		)
		pill.AnchorPoint = Vector2.new(0.5, 0)
		pill.ZIndex = 3
		Theme.surface(pill, color, 12, Theme.ink)
		local cap = Instance.new("UISizeConstraint")
		cap.MaxSize = Vector2.new(300, 32)
		cap.Parent = pill
		local txt = Ui.label(
			pill,
			"Label",
			UDim2.new(1, -16, 1, -4),
			UDim2.fromOffset(8, 2),
			labelText,
			color
		)
		txt.TextStrokeTransparency = 0.3
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize = 14
		limit.MaxTextSize = 16
		limit.Parent = txt
	end
	return area
end

function Ui.hidePanel()
	area.Visible = false
	area:ClearAllChildren()
end

function Ui.reduced(): boolean
	return Players.LocalPlayer:GetAttribute("ReduceEffects") == true
end

function Ui.bounce(target: GuiObject)
	if Ui.reduced() then
		return
	end
	local scale = Instance.new("UIScale")
	scale.Scale = 0.94
	scale.Parent = target
	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

function Ui.exitPulse(target: GuiObject, color: Color3)
	if Ui.reduced() then
		return
	end
	local pulse = Instance.new("UIStroke")
	pulse.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pulse.Color = color:Lerp(Theme.sand, 0.5)
	pulse.Thickness = 3
	pulse.Transparency = 0.35
	pulse.Parent = target
	local fade = TweenService:Create(pulse, TweenInfo.new(0.18), { Transparency = 1 })
	fade.Completed:Once(function()
		pulse:Destroy()
	end)
	fade:Play()
end

function Ui.feedback(
	target: Frame,
	at: UDim2,
	color: Color3,
	success: boolean,
	perfect: boolean?,
	combo: number?
)
	local streak = combo or 0
	local reduced = Ui.reduced()
	Audio.play(
		if success then "hit" else "miss",
		0.2,
		if success then 1 + math.min(streak, 6) * 0.04 + (if perfect then 0.16 else 0) else 1
	)
	local text = Text.minigames
	local message = if perfect then text.perfect elseif success then text.good else text.miss
	local accent = if success then color:Lerp(Theme.sand, 0.28) else Color3.fromRGB(255, 125, 148)
	local state = feedbackByTarget[target]
	if not state or not state.badge.Parent then
		local badge = Ui.label(target, "TimingFeedback", UDim2.fromOffset(156, 26), at, "", accent)
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.ZIndex = 7
		local mounted: Feedback = { badge = badge, sparks = {}, tweens = {}, sequence = 0 }
		feedbackByTarget[target] = mounted
		state = mounted
		badge.Destroying:Once(function()
			local current = feedbackByTarget[target]
			if current and current.badge == badge then
				feedbackByTarget[target] = nil
			end
		end)
	end
	for _, tween in state.tweens do
		tween:Cancel()
	end
	table.clear(state.tweens)
	for _, spark in state.sparks do
		spark.Visible = false
	end
	local badge = state.badge
	badge.Text = string.upper(message)
		.. (if streak > 1 then string.format(text.combo, streak) else "")
	badge.TextColor3 = accent
	badge.Position = at
	badge.Rotation = 0
	badge.TextTransparency = 0
	badge.TextStrokeTransparency = 0.2
	badge.Visible = true
	state.sequence += 1
	local sequence = state.sequence
	if not reduced then
		local tween = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local labelTween = TweenService:Create(badge, tween, {
			Position = at + (if success then UDim2.fromOffset(0, -14) else UDim2.fromOffset(7, 0)),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		table.insert(state.tweens, labelTween)
		labelTween:Play()
		if success then
			if #state.sparks == 0 then
				for _ = 1, 6 do
					local particle = Ui.frame(target, "Spark", UDim2.fromOffset(6, 6), at, accent)
					particle.AnchorPoint = Vector2.new(0.5, 0.5)
					particle.Rotation = 45
					particle.ZIndex = 6
					table.insert(state.sparks, particle)
				end
			end
			for index, spark in state.sparks do
				local angle = index * math.pi / 3
				spark.Position = at
				spark.BackgroundColor3 = accent
				spark.BackgroundTransparency = 0
				spark.Visible = true
				local sparkTween = TweenService:Create(spark, tween, {
					Position = at + UDim2.fromOffset(math.cos(angle) * 43, math.sin(angle) * 27),
					BackgroundTransparency = 1,
				})
				table.insert(state.tweens, sparkTween)
				sparkTween:Play()
			end
		else
			badge.Rotation = -5
			local tilt = TweenService:Create(
				badge,
				TweenInfo.new(0.14, Enum.EasingStyle.Elastic),
				{ Rotation = 0 }
			)
			table.insert(state.tweens, tilt)
			tilt:Play()
		end
	end
	task.delay(0.34, function()
		local current = feedbackByTarget[target]
		if current and current.badge == badge and current.sequence == sequence then
			badge.Visible = false
			for _, spark in current.sparks do
				spark.Visible = false
			end
			table.clear(current.tweens)
		end
	end)
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
