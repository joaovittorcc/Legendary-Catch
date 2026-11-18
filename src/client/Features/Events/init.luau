--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi")).adventure
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Events"))
local Creatures = require(Shared.Config:WaitForChild("Creatures"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Motion = require(script.Parent.Hud:WaitForChild("Motion"))

local Training = require(script.Parent:WaitForChild("Training"))
local Tutorial = require(script.Parent:WaitForChild("Tutorial"))
local Hud = require(script.Parent:WaitForChild("Hud"))

local Events = {}
local player = Players.LocalPlayer
local colors: { [string]: Color3 } = {
	starTide = Theme.rose,
	thunderStorm = Theme.crystal,
	goldenHour = Theme.gold,
	shimmerShoal = Color3.fromRGB(133, 255, 187),
}
local icons: { [string]: string } = {
	starTide = "🌟",
	thunderStorm = "⚡",
	goldenHour = "☀️",
	shimmerShoal = "🐟",
}

function Events.start()
	local exclusives: { [string]: number } = {}
	for _, creature in Creatures.LIST do
		if creature.event then
			exclusives[creature.event] = (exclusives[creature.event] or 0) + 1
		end
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "OceanEventHud"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 3

	local banner = Instance.new("Frame")
	banner.Name = "EventBanner"
	banner.AnchorPoint = Vector2.new(0, 0)
	banner.Position = UDim2.new(0.03, 0, 0, 80)
	banner.Size = UDim2.fromOffset(250, 50)
	banner.BackgroundColor3 = Theme.crystal
	banner.BorderSizePixel = 0
	banner.Visible = false
	Art.panel(banner, Theme.crystal)
	local rim = banner:FindFirstChildWhichIsA("UIStroke")
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(210, 48)
	bounds.MaxSize = Vector2.new(300, 70)
	bounds.Parent = banner
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 5
	ratio.DominantAxis = Enum.DominantAxis.Width
	ratio.Parent = banner

	local iconHolder = Instance.new("Frame")
	iconHolder.Name = "EventIcon"
	iconHolder.AnchorPoint = Vector2.new(0, 0.5)
	iconHolder.Position = UDim2.fromOffset(8, 25)
	iconHolder.Size = UDim2.fromOffset(38, 38)
	iconHolder.BackgroundColor3 = Theme.cream
	iconHolder.BorderSizePixel = 0
	iconHolder.ZIndex = 3
	Theme.corner(iconHolder, 19)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Theme.outline
	iconStroke.Thickness = 2
	iconStroke.Parent = iconHolder
	local icon = Panel.label(iconHolder, "🌊", 23)
	icon.TextScaled = true
	icon.TextStrokeTransparency = 1
	icon.Size = UDim2.fromScale(1, 1)
	icon.ZIndex = 4
	iconHolder.Parent = banner

	local title = Panel.label(banner, "", 16, Theme.ink)
	title.Name = "EventName"
	title.Position = UDim2.fromOffset(54, 6)
	title.Size = UDim2.new(1, -64, 0, 20)
	title.TextScaled = true
	title.TextStrokeTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	local titleLimit = Instance.new("UITextSizeConstraint")
	titleLimit.MinTextSize = 11
	titleLimit.MaxTextSize = 17
	titleLimit.Parent = title

	local timer = Panel.label(banner, "", 14, Theme.wood)
	timer.Name = "EventTimer"
	timer.Position = UDim2.fromOffset(54, 24)
	timer.Size = UDim2.new(1, -64, 0, 16)
	timer.TextScaled = true
	timer.TextStrokeTransparency = 1
	timer.TextXAlignment = Enum.TextXAlignment.Left
	local timerLimit = Instance.new("UITextSizeConstraint")
	timerLimit.MaxTextSize = 14
	timerLimit.Parent = timer
	local exclusive = Panel.label(banner, "", 12, Theme.ink)
	exclusive.Name = "EventExclusives"
	exclusive.Position = UDim2.fromOffset(54, 39)
	exclusive.Size = UDim2.new(1, -64, 0, 15)
	exclusive.TextStrokeTransparency = 1
	exclusive.TextXAlignment = Enum.TextXAlignment.Left
	exclusive.Visible = false

	local track = Instance.new("Frame")
	track.Name = "EventTrack"
	track.Size = UDim2.new(1, -66, 0, 4)
	track.Position = UDim2.new(0, 54, 1, -11)
	track.BackgroundColor3 = Theme.outline
	track.BackgroundTransparency = 0.2
	track.BorderSizePixel = 0
	Theme.corner(track, 3)
	local fill = Instance.new("Frame")
	fill.Name = "Remaining"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BorderSizePixel = 0
	Theme.corner(fill, 3)
	fill.Parent = track
	track.Parent = banner
	local motion = Motion.mount(banner)
	banner.Parent = gui
	local setBannerVisible = Hud.bindFishingVisibility(banner, false)
	gui.Parent = player:WaitForChild("PlayerGui")

	local atmosphere = Instance.new("ColorCorrectionEffect")
	atmosphere.Name = "OceanEventVisual"
	atmosphere.Enabled = false
	atmosphere.Parent = Lighting

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "OceanEventMotes"
	emitter.Enabled = false
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 4
	emitter.Lifetime = NumberRange.new(2, 4)
	emitter.Speed = NumberRange.new(0.4, 1.2)
	emitter.SpreadAngle = Vector2.new(70, 70)
	emitter.Size = NumberSequence.new(0.17)
	emitter.LightEmission = 0.8
	local anchor = Instance.new("Attachment")
	anchor.Position = Vector3.new(0, 1, -10)
	emitter.Parent = anchor

	local function layout()
		local size = gui.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		local portrait = size.Y > size.X
		local width = math.clamp(size.X * (if portrait then 0.62 else 0.36), 210, 300)
		local height = if exclusive.Visible
			then (if portrait then 68 else 64)
			else (if portrait then 56 else 50)
		banner.Size = UDim2.fromOffset(width, height)
		ratio.AspectRatio = width / height
		local cardBottom = math.max(Tutorial.cardBottom(), Training.cardBottom())
		local top = if cardBottom > 0 then cardBottom + 10 else math.clamp(size.Y * 0.2, 76, 190)
		banner.Position = UDim2.new(0.03, 0, 0, top)
		iconHolder.Position = UDim2.fromOffset(8, height / 2)
	end

	local lastId = ""
	local lastRemaining = -1
	local wasActive = false
	local function updateVisibility()
		setBannerVisible(wasActive and Hud.panel() == "")
	end
	local function refresh()
		local id = ReplicatedStorage:GetAttribute(Config.ACTIVE_ATTRIBUTE)
		local ends = ReplicatedStorage:GetAttribute(Config.ENDS_AT_ATTRIBUTE)
		local remaining = if typeof(ends) == "number"
			then math.ceil(ends - workspace:GetServerTimeNow())
			else 0
		local event = if typeof(id) == "string" then Config.get(id) else nil
		local active = event ~= nil and remaining > 0
		if active ~= wasActive then
			wasActive = active
			updateVisibility()
		end
		local tint = if typeof(id) == "string" then colors[id] or Theme.crystal else Theme.crystal
		local decorations = active and player:GetAttribute("ReduceEffects") ~= true
		if atmosphere.Enabled ~= decorations then
			atmosphere.Enabled = decorations
			emitter.Enabled = decorations
			if not decorations then
				emitter:Clear()
			end
		end
		if active and event then
			if lastId ~= event.id then
				lastId = event.id
				lastRemaining = -1
				if rim then
					rim.Color = tint
				end
				icon.Text = icons[event.id] or "🌊"
				title.Text = Strings.eventName[event.id] or event.id
				local count = exclusives[event.id] or 0
				exclusive.Visible = count > 0
				exclusive.Text = if count == 1
					then Text.eventExclusiveOne
					else string.format(Text.eventExclusiveMany, count)
				fill.BackgroundColor3 = tint
				atmosphere.TintColor = Color3.new(1, 1, 1):Lerp(tint, 0.28)
				atmosphere.Brightness = if event.id == "thunderStorm" then -0.11 else 0.025
				emitter.Color = ColorSequence.new(tint)
				motion.pulse(0.94)
			end
			layout()
			if lastRemaining ~= remaining then
				lastRemaining = remaining
				local clock = string.format("%d:%02d", math.floor(remaining / 60), remaining % 60)
				timer.Text = string.format(Text.eventEnds, clock)
				fill.Size = UDim2.fromScale(math.clamp(remaining / event.durationSeconds, 0, 1), 1)
			end
			anchor.Parent = if decorations then workspace.CurrentCamera else nil
		else
			lastId = ""
			if anchor.Parent then
				emitter:Clear()
				anchor.Parent = nil
			end
		end
	end

	task.spawn(function()
		while gui.Parent do
			task.wait(0.5)
			if not gui.Parent then
				break
			end
			refresh()
		end
	end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Tutorial.layoutChanged:Connect(layout)
	Hud.layoutChanged:Connect(layout)
	Hud.panelChanged:Connect(updateVisibility)
	gui.Destroying:Once(function()
		atmosphere:Destroy()
		anchor:Destroy()
	end)
	ReplicatedStorage:GetAttributeChangedSignal(Config.ACTIVE_ATTRIBUTE):Connect(refresh)
	ReplicatedStorage:GetAttributeChangedSignal(Config.ENDS_AT_ATTRIBUTE):Connect(refresh)
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(refresh)
	layout()
	refresh()
end

return Events
