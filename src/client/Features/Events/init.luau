--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Events"))
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
}
local icons: { [string]: string } = {
	starTide = "🌟",
	thunderStorm = "⚡",
	goldenHour = "☀️",
}

function Events.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "OceanEventHud"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 3

	local banner = Instance.new("Frame")
	banner.Name = "EventBanner"
	banner.AnchorPoint = Vector2.new(1, 0)
	banner.Position = UDim2.new(0.97, 0, 0, 80)
	banner.Size = UDim2.fromOffset(250, 50)
	banner.BackgroundColor3 = Theme.crystal
	banner.BorderSizePixel = 0
	banner.Visible = false
	Art.panel(banner, Theme.crystal)
	local rim = banner:FindFirstChildWhichIsA("UIStroke")
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(210, 48)
	bounds.MaxSize = Vector2.new(300, 66)
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

	local timer = Panel.label(banner, "", 14, Theme.muted)
	timer.Name = "EventTimer"
	timer.Position = UDim2.fromOffset(54, 26)
	timer.Size = UDim2.new(1, -64, 0, 16)
	timer.TextScaled = true
	timer.TextStrokeTransparency = 1
	timer.TextXAlignment = Enum.TextXAlignment.Left
	local timerLimit = Instance.new("UITextSizeConstraint")
	timerLimit.MaxTextSize = 14
	timerLimit.Parent = timer

	Motion.mount(banner, 0.75, 7)
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
		local height = if portrait then 56 else 50
		banner.Size = UDim2.fromOffset(width, height)
		ratio.AspectRatio = width / height
		local cardBottom = math.max(Tutorial.cardBottom(), Training.cardBottom())
		local top = if cardBottom > 0 then cardBottom + 10 else math.clamp(size.Y * 0.2, 76, 190)
		banner.Position = UDim2.new(0.97, 0, 0, top)
		iconHolder.Position = UDim2.fromOffset(8, height / 2)
	end

	local function refresh()
		local id = ReplicatedStorage:GetAttribute(Config.ACTIVE_ATTRIBUTE)
		local ends = ReplicatedStorage:GetAttribute(Config.ENDS_AT_ATTRIBUTE)
		local remaining = if typeof(ends) == "number"
			then math.ceil(ends - workspace:GetServerTimeNow())
			else 0
		local active = typeof(id) == "string" and id ~= "" and remaining > 0
		setBannerVisible(active)
		local tint = if typeof(id) == "string" then colors[id] or Theme.crystal else Theme.crystal
		local decorations = active and player:GetAttribute("ReduceEffects") ~= true
		atmosphere.Enabled = decorations
		if emitter.Enabled and not decorations then
			emitter:Clear()
		end
		emitter.Enabled = decorations
		if active and typeof(id) == "string" then
			layout()
			if rim then
				rim.Color = tint
			end
			banner.BackgroundColor3 = tint
			icon.Text = icons[id] or "🌊"
			title.Text = Strings.eventName[id] or id
			timer.Text = string.format("%d:%02d", math.floor(remaining / 60), remaining % 60)
			atmosphere.TintColor = Color3.new(1, 1, 1):Lerp(tint, 0.28)
			atmosphere.Brightness = if id == "thunderStorm" then -0.11 else 0.025
			emitter.Color = ColorSequence.new(tint)
			anchor.Parent = workspace.CurrentCamera
		elseif anchor.Parent then
			emitter:Clear()
			anchor.Parent = nil
		end
	end

	local elapsed = 0
	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.25 then
			elapsed = 0
			refresh()
		end
	end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	Tutorial.layoutChanged:Connect(layout)
	gui.Destroying:Once(function()
		heartbeat:Disconnect()
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
