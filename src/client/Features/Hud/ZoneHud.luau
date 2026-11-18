--!strict
-- Shows a brief zone banner when stepping onto a fishing zone, a level warning toast
-- if locked, and a discreet HUD chip while standing in a higher-tier zone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Zones = require(Shared:WaitForChild("Config"):WaitForChild("Zones"))

local ZoneHud = {}

local BANNER_SECONDS = 2.5

local function createText(parent: Instance, name: string, size: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Theme.font
	label.TextSize = size
	label.TextColor3 = color
	label.TextStrokeTransparency = 1
	label.Parent = parent
	return label
end

function ZoneHud.mount(
	gui: ScreenGui,
	bar: Frame,
	levelChip: Frame,
	panelChanged: RBXScriptSignal,
	currentPanel: () -> string,
	bindFishingVisibility: (GuiObject, boolean?) -> (boolean) -> (),
	toast: (string, Color3?) -> ()
)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local chip = Instance.new("Frame")
	chip.Name = "ZoneIndicator"
	chip.AnchorPoint = Vector2.new(0, 0.5)
	chip.Size = UDim2.fromOffset(172, 34)
	chip.Visible = false
	chip.ZIndex = 6
	Theme.surface(chip, Theme.cream, 14, Theme.crystal)
	local chipIcon = createText(chip, "Icon", 16, Theme.ink)
	chipIcon.Size = UDim2.fromOffset(26, 26)
	chipIcon.Position = UDim2.fromOffset(8, 4)
	chipIcon.ZIndex = 7
	local chipLabel = createText(chip, "ZoneName", 14, Theme.ink)
	chipLabel.Size = UDim2.new(1, -40, 1, -4)
	chipLabel.Position = UDim2.fromOffset(34, 2)
	chipLabel.TextXAlignment = Enum.TextXAlignment.Left
	chipLabel.TextScaled = true
	chipLabel.ZIndex = 7
	local chipLimit = Instance.new("UITextSizeConstraint")
	chipLimit.MinTextSize = 14
	chipLimit.MaxTextSize = 15
	chipLimit.Parent = chipLabel
	chip.Parent = bar
	local setChipVisible = bindFishingVisibility(chip, true)

	local banner = Instance.new("Frame")
	banner.Name = "ZoneBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.fromScale(0.5, 0.19)
	banner.Size = UDim2.new(0.78, 0, 0, 74)
	banner.Visible = false
	banner.ZIndex = 28
	Theme.surface(banner, Theme.crystal, 20, Theme.ink)
	local bannerStroke = banner:FindFirstChildWhichIsA("UIStroke")
	local bannerBounds = Instance.new("UISizeConstraint")
	bannerBounds.MinSize = Vector2.new(220, 68)
	bannerBounds.MaxSize = Vector2.new(330, 78)
	bannerBounds.Parent = banner
	local bannerScale = Instance.new("UIScale")
	bannerScale.Scale = 1
	bannerScale.Parent = banner

	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.Position = UDim2.fromOffset(12, 37)
	badge.Size = UDim2.fromOffset(44, 44)
	badge.BackgroundColor3 = Theme.cream
	badge.BorderSizePixel = 0
	badge.ZIndex = 29
	Theme.corner(badge, 22)
	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = Theme.outline
	badgeStroke.Thickness = 2
	badgeStroke.Parent = badge
	local badgeIcon = createText(badge, "Icon", 24, Theme.ink)
	badgeIcon.Size = UDim2.fromScale(1, 1)
	badgeIcon.TextScaled = true
	badgeIcon.ZIndex = 30
	badge.Parent = banner

	local bannerTitle = createText(banner, "Title", 20, Theme.cream)
	bannerTitle.Position = UDim2.fromOffset(66, 10)
	bannerTitle.Size = UDim2.new(1, -78, 0, 26)
	bannerTitle.TextXAlignment = Enum.TextXAlignment.Left
	bannerTitle.TextScaled = true
	bannerTitle.ZIndex = 29
	local titleLimit = Instance.new("UITextSizeConstraint")
	titleLimit.MinTextSize = 14
	titleLimit.MaxTextSize = 22
	titleLimit.Parent = bannerTitle

	local bannerSub = createText(banner, "Subtitle", 14, Theme.gold)
	bannerSub.Position = UDim2.fromOffset(66, 38)
	bannerSub.Size = UDim2.new(1, -78, 0, 22)
	bannerSub.TextXAlignment = Enum.TextXAlignment.Left
	bannerSub.TextScaled = true
	bannerSub.ZIndex = 29
	local subLimit = Instance.new("UITextSizeConstraint")
	subLimit.MinTextSize = 14
	subLimit.MaxTextSize = 15
	subLimit.Parent = bannerSub
	banner.Parent = gui

	local function layoutChip()
		local size = gui.AbsoluteSize
		local portrait = size.Y > size.X
		local barHeight = bar.AbsoluteSize.Y
		local rightStart = levelChip.Position.X.Offset + levelChip.Size.X.Offset + 10
		local chipHeight = math.clamp(math.round(barHeight * 0.64), 30, 38)
		local chipWidth = math.clamp(math.round(size.X * 0.24), 152, 210)
		if portrait then
			chip.AnchorPoint = Vector2.new(1, 0)
			chip.Position = UDim2.new(1, 0, 0, barHeight + 8)
		else
			chip.AnchorPoint = Vector2.new(0, 0.5)
			chip.Position = UDim2.fromOffset(rightStart, math.round(barHeight / 2))
		end
		chip.Size = UDim2.fromOffset(chipWidth, chipHeight)
	end

	local bannerToken = 0
	local bannerTween: Tween? = nil
	local lastZone = ""

	local function hideBanner()
		if bannerTween then
			bannerTween:Cancel()
			bannerTween = nil
		end
		banner.Visible = false
	end

	local function showZoneBanner(zone: Zones.FishingZone, level: number)
		local locked = level < zone.minLevel
		local name = Strings.zoneName[zone.id] or zone.id
		if bannerStroke then
			bannerStroke.Color = zone.color
		end
		badgeStroke.Color = zone.color
		badgeIcon.Text = if locked then "🔒" else zone.icon
		bannerTitle.Text = name
		bannerSub.TextColor3 = if locked then Color3.fromRGB(255, 195, 120) else Theme.gold
		bannerSub.Text = if locked
			then string.format(Strings.zoneLockedHint, zone.minLevel)
			else Strings.zoneBonusHint[zone.id] or ""

		if bannerTween then
			bannerTween:Cancel()
			bannerTween = nil
		end
		bannerToken += 1
		local token = bannerToken
		banner.Visible = currentPanel() == ""
		if player:GetAttribute("ReduceEffects") ~= true then
			bannerScale.Scale = 0.84
			local tween = TweenService:Create(
				bannerScale,
				TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			bannerTween = tween
			tween:Play()
		else
			bannerScale.Scale = 1
		end
		task.delay(BANNER_SECONDS, function()
			if bannerToken == token then
				banner.Visible = false
			end
		end)
	end

	local function updateZone(suppressAnnouncement: boolean)
		local raw = player:GetAttribute(Zones.PLAYER_ATTRIBUTE)
		local zoneId = if typeof(raw) == "string" then raw else ""
		local zone = if zoneId ~= "" then Zones.get(zoneId) else nil
		local rawLevel = player:GetAttribute("PlayerLevel")
		local level = if typeof(rawLevel) == "number" then rawLevel else 1

		local showChip = zone ~= nil and zone.id ~= Zones.DEFAULT_ID and currentPanel() == ""
		if zone and zone.id ~= Zones.DEFAULT_ID then
			local locked = level < zone.minLevel
			local name = Strings.zoneName[zone.id] or zone.id
			chipIcon.Text = if locked then "🔒" else zone.icon
			chipLabel.Text = if locked then `{name} ({zone.minLevel}+)` else name
			local chipStroke = chip:FindFirstChildWhichIsA("UIStroke")
			if chipStroke then
				chipStroke.Color = zone.color
			end
		end
		setChipVisible(showChip)
		layoutChip()

		if zone == nil then
			lastZone = ""
			return
		end
		if not suppressAnnouncement and zone.id ~= lastZone then
			lastZone = zone.id
			if playerGui:FindFirstChild("IslandArrival") == nil then
				showZoneBanner(zone, level)
				if level < zone.minLevel then
					toast(
						string.format(Strings.zoneRequiredLevel, zone.minLevel),
						Color3.fromRGB(255, 195, 120)
					)
				end
			end
		end
	end

	player:GetAttributeChangedSignal(Zones.PLAYER_ATTRIBUTE):Connect(function()
		updateZone(false)
	end)
	player:GetAttributeChangedSignal("PlayerLevel"):Connect(function()
		updateZone(true)
	end)
	panelChanged:Connect(function(name: string)
		if name ~= "" then
			hideBanner()
		end
		updateZone(true)
	end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutChip)
	levelChip:GetPropertyChangedSignal("Size"):Connect(layoutChip)
	layoutChip()
	updateZone(true)
end

return ZoneHud
