--!strict
-- Legendary omen: when a Legendary bites, the world changes for this player while they
-- fight (the creature itself stays hidden until the reveal). Dusky violet tint, heavier
-- atmosphere, slow "heartbeat" pulses and a banner: "THE SEA IS STIRRING...".
-- Client-only and fully restored on stop. "Reduce effects" keeps the banner and a softer
-- tint, without pulses.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local Omen = {}

local TINT = Color3.fromRGB(196, 170, 255)
local FADE_IN = TweenInfo.new(1.6, Enum.EasingStyle.Sine)
local PULSE_EVERY = 2.2

local player = Players.LocalPlayer
local active = false
local token = 0
local correction: ColorCorrectionEffect? = nil
local banner: ScreenGui? = nil
local saved: { [Instance]: { [string]: any } } = {}
local tweens: { Tween } = {}

-- Plays a tween and keeps it so stop() can cancel it before restoring.
local function play(instance: Instance, info: TweenInfo, goal: { [string]: any })
	local tween = TweenService:Create(instance, info, goal)
	table.insert(tweens, tween)
	tween:Play()
end

local function remember(instance: Instance, props: { string })
	local values: { [string]: any } = {}
	for _, prop in props do
		values[prop] = (instance :: any)[prop]
	end
	saved[instance] = values
end

local function makeBanner(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "LegendaryOmen"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 6
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.35) -- below the tutorial card, above the minigame
	title.Size = UDim2.fromScale(0.8, 0.08)
	title.BackgroundTransparency = 1
	title.Font = Theme.font
	title.TextScaled = true
	title.Text = Strings.omenLegendary
	title.TextColor3 = Theme.gold
	title.TextStrokeColor3 = Theme.ink
	title.TextStrokeTransparency = 0.2
	title.TextTransparency = 1
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 46
	cap.Parent = title
	title.Parent = gui

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.AnchorPoint = Vector2.new(0.5, 0.5)
	sub.Position = UDim2.fromScale(0.5, 0.41)
	sub.Size = UDim2.fromScale(0.7, 0.045)
	sub.BackgroundTransparency = 1
	sub.Font = Theme.font
	sub.TextScaled = true
	sub.Text = Strings.omenLegendarySub
	sub.TextColor3 = Color3.new(1, 1, 1)
	sub.TextStrokeColor3 = Theme.ink
	sub.TextStrokeTransparency = 0.3
	sub.TextTransparency = 1
	local subCap = Instance.new("UITextSizeConstraint")
	subCap.MaxTextSize = 26
	subCap.Parent = sub
	sub.Parent = gui

	gui.Parent = player:WaitForChild("PlayerGui")
	-- Fade in, hold, then fade out so it doesn't sit over the minigame.
	local show = TweenInfo.new(0.5, Enum.EasingStyle.Back)
	title.Size = UDim2.fromScale(0.5, 0.05)
	TweenService:Create(title, show, { TextTransparency = 0, Size = UDim2.fromScale(0.8, 0.08) })
		:Play()
	task.delay(0.4, function()
		TweenService:Create(sub, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
	end)
	task.delay(3.2, function()
		if gui.Parent then
			local hide = TweenInfo.new(0.8)
			TweenService:Create(title, hide, { TextTransparency = 1, TextStrokeTransparency = 1 })
				:Play()
			TweenService:Create(sub, hide, { TextTransparency = 1, TextStrokeTransparency = 1 })
				:Play()
		end
	end)
	return gui
end

-- Starts the omen (no-op if already running).
function Omen.start()
	if active then
		return
	end
	active = true
	token += 1
	local myToken = token
	local calm = player:GetAttribute("ReduceEffects") == true

	remember(Lighting, { "Ambient", "OutdoorAmbient", "ExposureCompensation" })
	play(Lighting, FADE_IN, {
		Ambient = Color3.fromRGB(70, 50, 120),
		OutdoorAmbient = Color3.fromRGB(90, 70, 150),
		ExposureCompensation = Lighting.ExposureCompensation - (if calm then 0.15 else 0.35),
	})
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		remember(atmosphere, { "Color", "Decay", "Density", "Haze" })
		play(atmosphere, FADE_IN, {
			Color = Color3.fromRGB(150, 120, 230),
			Decay = Color3.fromRGB(70, 40, 140),
			Density = math.min(atmosphere.Density + 0.12, 0.6),
			Haze = atmosphere.Haze + 1,
		})
	end

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "LegendaryOmen"
	cc.TintColor = Color3.new(1, 1, 1)
	cc.Parent = Lighting
	correction = cc
	play(cc, FADE_IN, {
		TintColor = TINT,
		Saturation = if calm then 0.05 else 0.2,
		Contrast = if calm then 0.04 else 0.12,
	})

	banner = makeBanner()

	if not calm then
		-- Slow "heartbeat": a brief bright pulse, like something huge moving below.
		task.spawn(function()
			task.wait(1.6)
			while active and token == myToken and cc.Parent do
				TweenService:Create(cc, TweenInfo.new(0.12), { Brightness = 0.12 }):Play()
				task.wait(0.14)
				TweenService:Create(cc, TweenInfo.new(0.5), { Brightness = 0 }):Play()
				task.wait(PULSE_EVERY)
			end
		end)
	end
end

-- Restores everything at once (call before the reveal and on any cleanup).
function Omen.stop()
	if not active then
		return
	end
	active = false
	token += 1
	-- Cancel the fades first, or they keep writing over the restored values.
	for _, tween in tweens do
		tween:Cancel()
	end
	table.clear(tweens)
	for instance, values in saved do
		for prop, value in values do
			(instance :: any)[prop] = value
		end
	end
	table.clear(saved)
	if correction then
		correction:Destroy()
		correction = nil
	end
	if banner then
		banner:Destroy()
		banner = nil
	end
end

return Omen
