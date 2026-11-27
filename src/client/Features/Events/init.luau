--!strict
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi")).adventure
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Events"))
local Creatures = require(Shared.Config:WaitForChild("Creatures"))
local Seasons = require(Shared.Config:WaitForChild("Seasons"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Motion = require(script.Parent.Hud:WaitForChild("Motion"))

local Training = require(script.Parent:WaitForChild("Training"))
local Tutorial = require(script.Parent:WaitForChild("Tutorial"))
local Hud = require(script.Parent:WaitForChild("Hud"))

local Scenery = require(script.Scenery)

local Events = {}
local player = Players.LocalPlayer
local colors: { [string]: Color3 } = {
	starTide = Theme.rose,
	thunderStorm = Theme.crystal,
	goldenHour = Theme.gold,
	shimmerShoal = Color3.fromRGB(133, 255, 187),
	fogBank = Color3.fromRGB(165, 205, 232),
	aurora = Color3.fromRGB(108, 255, 214),
}
local icons: { [string]: string } = {
	starTide = "🌟",
	thunderStorm = "⚡",
	goldenHour = "☀️",
	shimmerShoal = "🐟",
	fogBank = "🌫️",
	aurora = "🌌",
}

local function buildAuroraRibbon(parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "OceanEventAurora"

	local holder = Instance.new("Part")
	holder.Name = "Anchor"
	holder.Size = Vector3.new(1, 1, 1)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CastShadow = false
	holder.CFrame = CFrame.new(0, 125, -40)
	holder.Parent = model

	local specs = {
		{
			a = Vector3.new(-220, 0, -90),
			b = Vector3.new(220, 16, -60),
			c0 = Color3.fromRGB(95, 255, 205),
			c1 = Color3.fromRGB(165, 125, 255),
			width = 36,
			curve = 85,
		},
		{
			a = Vector3.new(-180, 14, 70),
			b = Vector3.new(190, 26, 95),
			c0 = Color3.fromRGB(115, 225, 255),
			c1 = Color3.fromRGB(130, 255, 185),
			width = 28,
			curve = -70,
		},
	}

	for index, spec in specs do
		local a0 = Instance.new("Attachment")
		a0.Position = spec.a
		a0.Parent = holder
		local a1 = Instance.new("Attachment")
		a1.Position = spec.b
		a1.Parent = holder
		local beam = Instance.new("Beam")
		beam.Name = "Ribbon" .. tostring(index)
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = spec.width
		beam.Width1 = spec.width * 0.75
		beam.CurveSize0 = spec.curve
		beam.CurveSize1 = -spec.curve * 0.8
		beam.Segments = 18
		beam.LightEmission = 0.9
		beam.LightInfluence = 0
		beam.FaceCamera = false
		beam.Color = ColorSequence.new(spec.c0, spec.c1)
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0.52),
			NumberSequenceKeypoint.new(0.75, 0.48),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.Parent = holder
	end

	model.Parent = parent
	return model
end

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
	bounds.MinSize = Vector2.new(210, 56)
	bounds.MaxSize = Vector2.new(300, 82)
	bounds.Parent = banner
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 4.4
	ratio.DominantAxis = Enum.DominantAxis.Width
	ratio.Parent = banner

	local iconHolder = Instance.new("Frame")
	iconHolder.Name = "EventIcon"
	iconHolder.AnchorPoint = Vector2.new(0, 0.5)
	iconHolder.Position = UDim2.fromOffset(12, 28)
	iconHolder.Size = UDim2.fromOffset(34, 34)
	iconHolder.BackgroundColor3 = Theme.cream
	iconHolder.BorderSizePixel = 0
	iconHolder.ZIndex = 3
	Theme.corner(iconHolder, 17)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Theme.outline
	iconStroke.Thickness = 2
	iconStroke.Parent = iconHolder
	local icon = Panel.label(iconHolder, "🌊", 21)
	icon.TextScaled = true
	icon.TextStrokeTransparency = 1
	icon.Size = UDim2.fromScale(1, 1)
	icon.ZIndex = 4
	iconHolder.Parent = banner

	local title = Panel.label(banner, "", 16, Theme.ink)
	title.Name = "EventName"
	title.Position = UDim2.fromOffset(52, 8)
	title.Size = UDim2.new(1, -64, 0, 18)
	title.TextScaled = true
	title.TextStrokeTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	local titleLimit = Instance.new("UITextSizeConstraint")
	titleLimit.MinTextSize = 11
	titleLimit.MaxTextSize = 16
	titleLimit.Parent = title

	local timer = Panel.label(banner, "", 14, Theme.wood)
	timer.Name = "EventTimer"
	timer.Position = UDim2.fromOffset(52, 26)
	timer.Size = UDim2.new(1, -64, 0, 15)
	timer.TextScaled = true
	timer.TextStrokeTransparency = 1
	timer.TextXAlignment = Enum.TextXAlignment.Left
	local timerLimit = Instance.new("UITextSizeConstraint")
	timerLimit.MinTextSize = 10
	timerLimit.MaxTextSize = 13
	timerLimit.Parent = timer
	local exclusive = Panel.label(banner, "", 14, Theme.ink)
	exclusive.Name = "EventExclusives"
	exclusive.Position = UDim2.fromOffset(52, 41)
	exclusive.Size = UDim2.new(1, -64, 0, 15)
	exclusive.TextScaled = true
	exclusive.TextStrokeTransparency = 1
	exclusive.TextXAlignment = Enum.TextXAlignment.Left
	exclusive.Visible = false
	local exclLimit = Instance.new("UITextSizeConstraint")
	exclLimit.MinTextSize = 10
	exclLimit.MaxTextSize = 13
	exclLimit.Parent = exclusive

	local track = Instance.new("Frame")
	track.Name = "EventTrack"
	track.Size = UDim2.new(1, -64, 0, 4)
	track.Position = UDim2.new(0, 52, 1, -12)
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

	local seasonBanner = Instance.new("Frame")
	seasonBanner.Name = "SeasonBanner"
	seasonBanner.AnchorPoint = Vector2.new(0, 0)
	seasonBanner.Position = UDim2.new(0.03, 0, 0, 80)
	seasonBanner.Size = UDim2.fromOffset(250, 56)
	seasonBanner.BackgroundColor3 = Color3.fromRGB(228, 78, 96)
	seasonBanner.BorderSizePixel = 0
	seasonBanner.Visible = false
	Art.panel(seasonBanner, Color3.fromRGB(228, 78, 96))
	local seasonBounds = Instance.new("UISizeConstraint")
	seasonBounds.MinSize = Vector2.new(210, 56)
	seasonBounds.MaxSize = Vector2.new(300, 74)
	seasonBounds.Parent = seasonBanner
	local seasonRatio = Instance.new("UIAspectRatioConstraint")
	seasonRatio.AspectRatio = 4.4
	seasonRatio.DominantAxis = Enum.DominantAxis.Width
	seasonRatio.Parent = seasonBanner

	local sIconHolder = Instance.new("Frame")
	sIconHolder.Name = "SeasonIcon"
	sIconHolder.AnchorPoint = Vector2.new(0, 0.5)
	sIconHolder.Position = UDim2.fromOffset(12, 28)
	sIconHolder.Size = UDim2.fromOffset(34, 34)
	sIconHolder.BackgroundColor3 = Theme.cream
	sIconHolder.BorderSizePixel = 0
	sIconHolder.ZIndex = 3
	Theme.corner(sIconHolder, 17)
	local sIconStroke = Instance.new("UIStroke")
	sIconStroke.Color = Theme.outline
	sIconStroke.Thickness = 2
	sIconStroke.Parent = sIconHolder
	local sIcon = Panel.label(sIconHolder, "🎄", 20)
	sIcon.TextScaled = true
	sIcon.TextStrokeTransparency = 1
	sIcon.Size = UDim2.fromScale(1, 1)
	sIcon.ZIndex = 4
	sIconHolder.Parent = seasonBanner

	local sTitle = Panel.label(seasonBanner, Text.seasonBannerTitle, 16, Theme.ink)
	sTitle.Name = "SeasonName"
	sTitle.Position = UDim2.fromOffset(52, 9)
	sTitle.Size = UDim2.new(1, -64, 0, 18)
	sTitle.TextScaled = true
	sTitle.TextStrokeTransparency = 1
	sTitle.TextXAlignment = Enum.TextXAlignment.Left
	local sTitleLimit = Instance.new("UITextSizeConstraint")
	sTitleLimit.MinTextSize = 11
	sTitleLimit.MaxTextSize = 16
	sTitleLimit.Parent = sTitle

	local sSub = Panel.label(seasonBanner, Text.seasonBannerSub, 14, Theme.wood)
	sSub.Name = "SeasonSub"
	sSub.Position = UDim2.fromOffset(52, 29)
	sSub.Size = UDim2.new(1, -64, 0, 16)
	sSub.TextScaled = true
	sSub.TextStrokeTransparency = 1
	sSub.TextXAlignment = Enum.TextXAlignment.Left
	local sSubLimit = Instance.new("UITextSizeConstraint")
	sSubLimit.MaxTextSize = 14
	sSubLimit.Parent = sSub

	Motion.mount(seasonBanner)
	seasonBanner.Parent = gui
	local setSeasonVisible = Hud.bindFishingVisibility(seasonBanner, false)

	gui.Parent = player:WaitForChild("PlayerGui")

	local atmosphere = Instance.new("ColorCorrectionEffect")
	atmosphere.Name = "OceanEventVisual"
	atmosphere.Enabled = false
	atmosphere.Parent = Lighting

	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	local baseWaterColor = if terrain then terrain.WaterColor else Color3.fromRGB(38, 128, 184)
	local waterTinted = false

	local auroraModel: Model? = nil
	local sceneryModel: Model? = nil
	local sceneryAnchor: Instance? = nil
	local sceneryId: string? = nil
	local sceneryReduced: boolean? = nil
	local function clearScenery(immediate: boolean?)
		if sceneryModel then
			Scenery.remove(
				sceneryModel,
				immediate == true or player:GetAttribute("ReduceEffects") == true
			)
			sceneryModel = nil
		end
		sceneryAnchor = nil
		sceneryId = nil
	end

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

	local function clearVisualExtras()
		if waterTinted and terrain then
			terrain.WaterColor = baseWaterColor
			waterTinted = false
		end
		if auroraModel then
			auroraModel:Destroy()
			auroraModel = nil
		end
	end

	local function layout()
		local size = gui.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		local portrait = size.Y > size.X
		local width = math.clamp(size.X * (if portrait then 0.62 else 0.36), 210, 300)
		local height = if exclusive.Visible
			then (if portrait then 76 else 72)
			else (if portrait then 60 else 56)
		banner.Size = UDim2.fromOffset(width, height)
		ratio.AspectRatio = width / height
		local hudGui = player.PlayerGui:FindFirstChild("AdventureHud")
		local ng = hudGui and hudGui:FindFirstChild("NextGoal")
		local ngBottom = if ng
				and ng:IsA("GuiObject")
				and ng.Visible
			then ng.AbsolutePosition.Y + ng.AbsoluteSize.Y - gui.AbsolutePosition.Y
			else 0
		local cardBottom = math.max(Tutorial.cardBottom(), Training.cardBottom(), ngBottom)
		local top = if cardBottom > 0 then cardBottom + 8 else math.clamp(size.Y * 0.2, 76, 190)
		banner.Position = UDim2.new(0.03, 0, 0, top)
		iconHolder.Position = UDim2.fromOffset(12, height / 2)

		local sHeight = if portrait then 60 else 56
		seasonBanner.Size = UDim2.fromOffset(width, sHeight)
		seasonRatio.AspectRatio = width / sHeight
		local seasonTop = if banner.Visible then top + height + 8 else top
		seasonBanner.Position = UDim2.new(0.03, 0, 0, seasonTop)
		sIconHolder.Position = UDim2.fromOffset(12, sHeight / 2)
	end

	local lastId = ""
	local lastRemaining = -1
	local wasActive = false
	local seasonActive = false
	local function updateVisibility()
		setBannerVisible(wasActive and Hud.panel() == "")
		setSeasonVisible(seasonActive and Hud.panel() == "")
		layout()
	end
	local function refresh()
		local id = ReplicatedStorage:GetAttribute(Config.ACTIVE_ATTRIBUTE)
		local ends = ReplicatedStorage:GetAttribute(Config.ENDS_AT_ATTRIBUTE)
		local remaining = if typeof(ends) == "number"
			then math.ceil(ends - workspace:GetServerTimeNow())
			else 0
		local event = if typeof(id) == "string" then Config.get(id) else nil
		local active = event ~= nil and remaining > 0
		local isXmas = Seasons.isActive("xmas", player, workspace:GetServerTimeNow())
		if active ~= wasActive or isXmas ~= seasonActive then
			wasActive = active
			seasonActive = isXmas
			updateVisibility()
		end
		local tint = if typeof(id) == "string" then colors[id] or Theme.crystal else Theme.crystal
		local decorations = active and player:GetAttribute("ReduceEffects") ~= true
		if atmosphere.Enabled ~= decorations then
			atmosphere.Enabled = decorations
			emitter.Enabled = decorations
			if not decorations then
				emitter:Clear()
				clearVisualExtras()
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
				local perks = {}
				if count > 0 then
					table.insert(
						perks,
						if count == 1
							then Text.eventExclusiveOne
							else string.format(Text.eventExclusiveMany, count)
					)
				end
				if event.valueMultiplier > 1 then
					table.insert(
						perks,
						string.format(
							Text.eventCoinBonus,
							math.round((event.valueMultiplier - 1) * 100)
						)
					)
				end
				exclusive.Visible = #perks > 0
				exclusive.Text = table.concat(perks, "  ·  ")
				layout()
				fill.BackgroundColor3 = tint
				clearVisualExtras()
				if event.id == "thunderStorm" then
					atmosphere.TintColor = Color3.new(1, 1, 1):Lerp(tint, 0.28)
					atmosphere.Brightness = -0.11
					atmosphere.Saturation = 0
					emitter.Rate = 4
					emitter.Size = NumberSequence.new(0.17)
					emitter.Speed = NumberRange.new(0.4, 1.2)
				elseif event.id == "fogBank" then
					atmosphere.TintColor = Color3.new(1, 1, 1):Lerp(tint, 0.34)
					atmosphere.Brightness = -0.05
					atmosphere.Saturation = -0.22
					emitter.Rate = 5
					emitter.Size = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.9),
						NumberSequenceKeypoint.new(0.5, 1.4),
						NumberSequenceKeypoint.new(1, 1.8),
					})
					emitter.Speed = NumberRange.new(0.15, 0.45)
				elseif event.id == "aurora" then
					atmosphere.TintColor = Color3.new(1, 1, 1):Lerp(tint, 0.3)
					atmosphere.Brightness = 0.03
					atmosphere.Saturation = 0.14
					emitter.Rate = 5
					emitter.Size = NumberSequence.new(0.22)
					emitter.Speed = NumberRange.new(0.5, 1.4)
				else
					atmosphere.TintColor = Color3.new(1, 1, 1):Lerp(tint, 0.28)
					atmosphere.Brightness = 0.025
					atmosphere.Saturation = 0
					emitter.Rate = 4
					emitter.Size = NumberSequence.new(0.17)
					emitter.Speed = NumberRange.new(0.4, 1.2)
				end
				emitter.Color = ColorSequence.new(tint)
				motion.pulse(0.94)
			end
			if decorations then
				if terrain and not waterTinted then
					baseWaterColor = terrain.WaterColor
					terrain.WaterColor = baseWaterColor:Lerp(tint, 0.35)
					waterTinted = true
				end
				if event.id == "aurora" and not auroraModel then
					auroraModel = buildAuroraRibbon(Workspace)
				elseif event.id ~= "aurora" and auroraModel then
					auroraModel:Destroy()
					auroraModel = nil
				end
			end
			layout()
			if lastRemaining ~= remaining then
				lastRemaining = remaining
				local clock = string.format("%d:%02d", math.floor(remaining / 60), remaining % 60)
				timer.Text = string.format(Text.eventEnds, clock)
				fill.Size = UDim2.fromScale(math.clamp(remaining / event.durationSeconds, 0, 1), 1)
			end
			anchor.Parent = if decorations then workspace.CurrentCamera else nil
			local marker, pose = Scenery.anchor(event.id)
			local reduced = player:GetAttribute("ReduceEffects") == true
			if marker ~= sceneryAnchor or sceneryId ~= event.id or sceneryReduced ~= reduced then
				clearScenery(sceneryId == event.id)
				sceneryReduced = reduced
				if marker and pose then
					sceneryAnchor = marker
					sceneryId = event.id
					sceneryModel = Scenery.create(
						pose,
						title.Text,
						Text.eventSceneryCaption,
						tint,
						event.id,
						reduced
					)
				end
			end
		else
			lastId = ""
			clearScenery()
			clearVisualExtras()
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
	local connections = {
		gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout),
		Tutorial.layoutChanged:Connect(layout),
		Hud.layoutChanged:Connect(layout),
		Hud.panelChanged:Connect(updateVisibility),
		ReplicatedStorage:GetAttributeChangedSignal(Config.ACTIVE_ATTRIBUTE):Connect(refresh),
		ReplicatedStorage:GetAttributeChangedSignal(Config.ENDS_AT_ATTRIBUTE):Connect(refresh),
		player:GetAttributeChangedSignal(Seasons.DEV_ATTRIBUTE):Connect(refresh),
		player:GetAttributeChangedSignal("ReduceEffects"):Connect(refresh),
	}
	gui.Destroying:Once(function()
		for _, connection in connections do
			connection:Disconnect()
		end
		clearScenery(true)
		clearVisualExtras()
		atmosphere:Destroy()
		anchor:Destroy()
	end)
	task.spawn(function()
		local hudGui = player:WaitForChild("PlayerGui"):WaitForChild("AdventureHud", 5)
		local ng = hudGui and hudGui:WaitForChild("NextGoal", 5)
		if gui.Parent and ng and ng:IsA("GuiObject") then
			for _, property in { "Visible", "AbsolutePosition", "AbsoluteSize" } do
				table.insert(connections, ng:GetPropertyChangedSignal(property):Connect(layout))
			end
			layout()
		end
	end)
	layout()
	refresh()
end

return Events
