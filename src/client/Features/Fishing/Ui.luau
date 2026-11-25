--!strict
-- Shared safe-area canvas and feedback for fishing and training.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))
local FishingCamera = require(script.Parent:WaitForChild("Camera"))
local Line = require(script.Parent:WaitForChild("Line"))
local Ui = {}
local gui: ScreenGui
local area: Frame
local toastLabel: TextLabel
local activeToast: Tween? = nil
local edgeBars: { Frame } = {}
local edgeTweens: { Tween } = {}
local edgePulseTimes: { number } = {}
type Feedback = {
	badge: TextLabel,
	badgeScale: UIScale,
	ring: Frame,
	ringStroke: UIStroke,
	sparks: { Frame },
	tweens: { Tween },
	sequence: number,
}
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
		if Theme.rarityRank(rarity) >= 4 then
			Ui.edgeGlow(color, 0.55)
		end
	end
	return area
end

function Ui.hidePanel()
	area.Visible = false
	area:ClearAllChildren()
	for _, tween in edgeTweens do
		tween:Cancel()
	end
	table.clear(edgeTweens)
	for _, bar in edgeBars do
		bar.BackgroundTransparency = 1
	end
end

function Ui.reduced(): boolean
	return Players.LocalPlayer:GetAttribute("ReduceEffects") == true
end

-- Subtle rarity screen-edge glow (4 soft gradient strips, 3/sec comfort cap, no full-screen flash).
function Ui.edgeGlow(color: Color3, duration: number?)
	if not gui or Ui.reduced() then
		return
	end
	local now = os.clock()
	for i = #edgePulseTimes, 1, -1 do
		if now - edgePulseTimes[i] > 1 then
			table.remove(edgePulseTimes, i)
		end
	end
	if #edgePulseTimes >= 3 then
		return
	end
	table.insert(edgePulseTimes, now)

	if #edgeBars == 0 then
		local specs = {
			{
				name = "EdgeTop",
				size = UDim2.new(1, 0, 0, 26),
				pos = UDim2.fromScale(0, 0),
				rot = 90,
			},
			{
				name = "EdgeBottom",
				size = UDim2.new(1, 0, 0, 26),
				pos = UDim2.new(0, 0, 1, -26),
				rot = -90,
			},
			{
				name = "EdgeLeft",
				size = UDim2.new(0, 26, 1, 0),
				pos = UDim2.fromScale(0, 0),
				rot = 0,
			},
			{
				name = "EdgeRight",
				size = UDim2.new(0, 26, 1, 0),
				pos = UDim2.new(1, -26, 0, 0),
				rot = 180,
			},
		}
		for _, spec in specs do
			local bar = Instance.new("Frame")
			bar.Name = spec.name
			bar.Size = spec.size
			bar.Position = spec.pos
			bar.BackgroundColor3 = color
			bar.BackgroundTransparency = 1
			bar.BorderSizePixel = 0
			bar.ZIndex = 4
			local grad = Instance.new("UIGradient")
			grad.Rotation = spec.rot
			grad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			})
			grad.Parent = bar
			bar.Parent = gui
			table.insert(edgeBars, bar)
		end
	end

	for _, t in edgeTweens do
		t:Cancel()
	end
	table.clear(edgeTweens)

	local len = duration or 0.42
	local info = TweenInfo.new(len, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, bar in edgeBars do
		bar.BackgroundColor3 = color
		bar.BackgroundTransparency = 0.25
		local tw = TweenService:Create(bar, info, { BackgroundTransparency = 1 })
		table.insert(edgeTweens, tw)
		tw:Play()
	end
end

function Ui.bounce(target: GuiObject)
	if Ui.reduced() then
		return
	end
	local scale = target:FindFirstChild("BounceScale")
	if not scale then
		local created = Instance.new("UIScale")
		created.Name = "BounceScale"
		created.Parent = target
		scale = created
	end
	local s = scale :: UIScale
	s.Scale = 0.9
	TweenService:Create(s, TweenInfo.new(0.24, Enum.EasingStyle.Back), { Scale = 1 }):Play()
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
	combo: number?,
	messageOverride: string?
)
	if area and area.Visible and (target == area or target:IsDescendantOf(area)) then
		Line.feedback(success, perfect)
	end
	local streak = combo or 0
	local reduced = Ui.reduced()
	if success then
		Audio.play("click", 0.14, if perfect then 1.3 else 1.1)
	end
	Audio.play(
		if success then "hit" else "miss",
		0.2,
		if success then 1 + math.min(streak, 6) * 0.04 + (if perfect then 0.16 else 0) else 1
	)
	local text = Text.minigames
	local message = messageOverride
		or (if perfect then text.perfect elseif success then text.good else text.miss)
	local symbol = if perfect then "◆" elseif success then "✓" else "×"
	local accent = if perfect
		then Theme.gold:Lerp(Color3.new(1, 1, 1), 0.22)
		elseif success then color:Lerp(Theme.sand, 0.28)
		else Color3.fromRGB(255, 125, 148)
	local state = feedbackByTarget[target]
	if not state or not state.badge.Parent then
		local badge = Ui.label(target, "TimingFeedback", UDim2.fromOffset(168, 28), at, "", accent)
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.ZIndex = 7
		local badgeScale = Instance.new("UIScale")
		badgeScale.Parent = badge

		local ring = Ui.frame(target, "ImpactRing", UDim2.fromOffset(26, 26), at, accent, 1)
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.ZIndex = 5
		ring.Visible = false
		Ui.corner(ring, 0.5)
		local ringStroke = Instance.new("UIStroke")
		ringStroke.Color = accent
		ringStroke.Thickness = 3
		ringStroke.Parent = ring

		local mounted: Feedback = {
			badge = badge,
			badgeScale = badgeScale,
			ring = ring,
			ringStroke = ringStroke,
			sparks = {},
			tweens = {},
			sequence = 0,
		}
		feedbackByTarget[target] = mounted
		state = mounted
		badge.Destroying:Once(function()
			local current = feedbackByTarget[target]
			if current and current.badge == badge then
				feedbackByTarget[target] = nil
				for _, tween in current.tweens do
					tween:Cancel()
				end
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
	state.ring.Visible = false
	local badge = state.badge
	badge.Text = symbol
		.. "  "
		.. string.upper(message)
		.. (if streak > 1 then string.format(text.combo, streak) else "")
	badge.TextColor3 = accent
	badge.Position = at
	badge.Rotation = 0
	badge.TextTransparency = 0
	badge.TextStrokeTransparency = 0.2
	badge.Visible = true
	state.badgeScale.Scale = 1
	state.sequence += 1
	local sequence = state.sequence
	if not reduced then
		if not success then
			badge.Rotation = -3
			local shake = TweenService:Create(
				badge,
				TweenInfo.new(0.044, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true),
				{ Rotation = 3 }
			)
			table.insert(state.tweens, shake)
			shake.Completed:Once(function()
				if state.sequence == sequence and badge.Parent then
					badge.Rotation = 0
				end
			end)
			shake:Play()
		end
		-- Instant pop-in overshoot on the badge without distorting font aspect ratio.
		state.badgeScale.Scale = if perfect then 1.32 else 1.18
		local popTween = TweenService:Create(
			state.badgeScale,
			TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		table.insert(state.tweens, popTween)
		popTween:Play()

		local tween = TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local labelTween = TweenService:Create(badge, tween, {
			Position = at + (if success then UDim2.fromOffset(0, -18) else UDim2.fromOffset(8, 0)),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		table.insert(state.tweens, labelTween)
		labelTween:Play()

		if success then
			-- Expanding impact shockwave ring at the hit point.
			state.ring.Position = at
			state.ring.Size = UDim2.fromOffset(22, 22)
			state.ring.Visible = true
			state.ringStroke.Color = accent
			state.ringStroke.Thickness = if perfect then 4 else 2.5
			state.ringStroke.Transparency = 0.1
			local ringGoal = if perfect then 104 else 72
			local ringTween = TweenService:Create(
				state.ring,
				TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Size = UDim2.fromOffset(ringGoal, ringGoal) }
			)
			local strokeTween = TweenService:Create(
				state.ringStroke,
				TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = 1 }
			)
			table.insert(state.tweens, ringTween)
			table.insert(state.tweens, strokeTween)
			ringTween:Play()
			strokeTween:Play()

			if #state.sparks == 0 then
				for _ = 1, 8 do
					local particle = Ui.frame(target, "Spark", UDim2.fromOffset(7, 7), at, accent)
					particle.AnchorPoint = Vector2.new(0.5, 0.5)
					particle.Rotation = 45
					particle.ZIndex = 6
					table.insert(state.sparks, particle)
				end
			end
			local sparkCount = if perfect then 8 else 6
			local radiusX = if perfect then 56 else 42
			local radiusY = if perfect then 38 else 27
			for index = 1, sparkCount do
				local spark = state.sparks[index]
				local angle = index * math.pi * 2 / sparkCount
				spark.Position = at
				spark.BackgroundColor3 = if perfect and index % 2 == 0
					then Color3.new(1, 1, 1)
					else accent
				spark.BackgroundTransparency = 0
				spark.Visible = true
				local sparkTween = TweenService:Create(spark, tween, {
					Position = at
						+ UDim2.fromOffset(math.cos(angle) * radiusX, math.sin(angle) * radiusY),
					BackgroundTransparency = 1,
				})
				table.insert(state.tweens, sparkTween)
				sparkTween:Play()
			end
			if perfect then
				FishingCamera.impulse(0.14)
				if streak >= 2 then
					Ui.edgeGlow(Theme.gold, 0.32)
				end
			end
		else
			FishingCamera.impulse(0.18)
			badge.Rotation = -6
			local tilt = TweenService:Create(
				badge,
				TweenInfo.new(0.16, Enum.EasingStyle.Elastic),
				{ Rotation = 0 }
			)
			table.insert(state.tweens, tilt)
			tilt:Play()
		end
	end
	task.delay(0.38, function()
		local current = feedbackByTarget[target]
		if current and current.badge == badge and current.sequence == sequence then
			badge.Visible = false
			current.ring.Visible = false
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
