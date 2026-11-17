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

local Training = require(script.Parent:WaitForChild("Training"))
local Tutorial = require(script.Parent:WaitForChild("Tutorial"))

local Events = {}
local player = Players.LocalPlayer
local colors: { [string]: Color3 } = {
	starTide = Theme.rose,
	thunderStorm = Theme.crystal,
	goldenHour = Theme.gold,
}

function Events.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "OceanEventHud"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 3

	local banner = Instance.new("Frame")
	banner.Name = "EventBanner"
	banner.AnchorPoint = Vector2.new(1, 0)
	banner.Position = UDim2.fromScale(0.97, 0.23)
	banner.Size = UDim2.fromScale(0.25, 0.065)
	banner.BackgroundTransparency = 0
	Theme.surface(banner, Theme.crystal, 10, Theme.ink)
	local rim = banner:FindFirstChildWhichIsA("UIStroke")
	local caption = Panel.label(banner, "", 16, Theme.sand)
	caption.Name = "EventNameAndTime"
	caption.Size = UDim2.new(1, -16, 1, 0)
	caption.Position = UDim2.fromOffset(8, 0)
	caption.TextScaled = true
	caption.TextStrokeColor3 = Color3.new(0, 0, 0)
	caption.TextStrokeTransparency = 0.48
	local typeSize = Instance.new("UITextSizeConstraint")
	typeSize.MaxTextSize = 16
	typeSize.Parent = caption
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(124, 32)
	bounds.MaxSize = Vector2.new(240, 44)
	bounds.Parent = banner
	banner.Parent = gui
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

	local function refresh()
		local id = ReplicatedStorage:GetAttribute(Config.ACTIVE_ATTRIBUTE)
		local ends = ReplicatedStorage:GetAttribute(Config.ENDS_AT_ATTRIBUTE)
		local remaining = if typeof(ends) == "number"
			then math.ceil(ends - workspace:GetServerTimeNow())
			else 0
		local active = typeof(id) == "string" and id ~= "" and remaining > 0
		banner.Visible = active
		local tint = if typeof(id) == "string" then colors[id] or Theme.crystal else Theme.crystal
		local decorations = active and player:GetAttribute("ReduceEffects") ~= true
		atmosphere.Enabled = decorations
		if emitter.Enabled and not decorations then
			emitter:Clear()
		end
		emitter.Enabled = decorations
		if active and typeof(id) == "string" then
			local cardBottom = math.max(Tutorial.cardBottom(), Training.cardBottom())
			banner.Position = if cardBottom > 0
				then UDim2.new(0.97, 0, 0, cardBottom + 10)
				else UDim2.fromScale(0.97, 0.23)
			if rim then
				rim.Color = tint
			end
			caption.Text = string.format(
				"%s  %d:%02d",
				Strings.eventName[id] or id,
				math.floor(remaining / 60),
				remaining % 60
			)
			atmosphere.TintColor = Color3.new(1, 1, 1):Lerp(tint, 0.28)
			atmosphere.Brightness = if id == "thunderStorm" then -0.11 else 0.025
			emitter.Color = ColorSequence.new(tint)
			anchor.Parent = workspace.CurrentCamera
		elseif anchor.Parent then
			emitter:Clear()
			anchor.Parent = nil
		end
	end

	ReplicatedStorage:GetAttributeChangedSignal(Config.ACTIVE_ATTRIBUTE):Connect(refresh)
	ReplicatedStorage:GetAttributeChangedSignal(Config.ENDS_AT_ATTRIBUTE):Connect(refresh)
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(refresh)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= 0.25 then
			elapsed = 0
			refresh()
		end
	end)
	refresh()
end

return Events
