--!strict
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local Missions = require(Shared:WaitForChild("Config"):WaitForChild("Missions"))
local Products = require(Shared:WaitForChild("Config"):WaitForChild("Products"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Types = require(Shared:WaitForChild("Types"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Art = require(script:WaitForChild("Art"))
local Assets = require(script:WaitForChild("Assets"))
local Motion = require(script:WaitForChild("Motion"))
local RodHotbar = require(script:WaitForChild("RodHotbar"))
local StarterOffer = require(script.Parent.Shop:WaitForChild("StarterOffer"))

-- Width / height of the uploaded HUD art (art/hud-v2): containers must keep these.
local COIN_RATIO = 1024 / 386
local NAV_RATIO = 1024 / 819
local RARITY_RATIO = 1024 / 341

local Hud = { order = 10 }
local player = Players.LocalPlayer
local panelChanged = Instance.new("BindableEvent")
Hud.panelChanged = panelChanged.Event
local currentPanel = ""
local menuChanged = Instance.new("BindableEvent")
Hud.menuChanged = menuChanged.Event
local menuIsOpen = false
local fishingChanged = Instance.new("BindableEvent")
Hud.fishingChanged = fishingChanged.Event
local fishingActive = false
local localFishingEvent = false
local revealWasActive = false
local localFishingRevision = 0
local navigation: Frame? = nil
local resized = Instance.new("BindableEvent")
Hud.layoutChanged = resized.Event

function Hud.navBottom(): number
	local bar = navigation
	return if bar then bar.Position.Y.Offset + bar.Size.Y.Offset else 64
end
local activeToast: Tween? = nil
local toastLabel: TextLabel? = nil
local toastStroke: UIStroke? = nil
local setToastVisible: ((boolean) -> ())? = nil

function Hud.panel(): string
	return currentPanel
end

function Hud.isMenuOpen(): boolean
	return menuIsOpen
end

function Hud.isFishingActive(): boolean
	return fishingActive
end

local function publishFishingState()
	local character = player.Character
	local state = character and character:GetAttribute("FishingState")
	local serverFishing = typeof(state) == "string" and state ~= ""
	local reveal = player:GetAttribute("CatchRevealActive") == true
	if reveal then
		revealWasActive = true
	elseif revealWasActive then
		revealWasActive = false
		localFishingEvent = false
	end
	local active = serverFishing or localFishingEvent or reveal
	if active ~= fishingActive then
		fishingActive = active
		fishingChanged:Fire(active)
	end
end

type FadeProperty = { instance: Instance, property: string, shown: number }

function Hud.bindFishingVisibility(
	target: GuiObject,
	visibleDuringFishing: boolean?
): (boolean) -> ()
	local properties: { FadeProperty } = {}
	local function save(instance: Instance, property: string)
		local ok, value = pcall(function()
			return (instance :: any)[property]
		end)
		if ok and typeof(value) == "number" then
			table.insert(properties, { instance = instance, property = property, shown = value })
		end
	end
	local function collect(instance: Instance)
		if instance:IsA("GuiObject") then
			save(instance, "BackgroundTransparency")
		end
		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			save(instance, "TextTransparency")
			save(instance, "TextStrokeTransparency")
		end
		if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			save(instance, "ImageTransparency")
		end
		if instance:IsA("UIStroke") then
			save(instance, "Transparency")
		end
	end
	collect(target)
	for _, descendant in target:GetDescendants() do
		collect(descendant)
	end
	local desired = target.Visible
	local revision = 0
	local activeTweens: { Tween } = {}
	local oldActive = target.Active
	local oldInteractable = if target:IsA("GuiButton") then target.Interactable else nil
	local function apply()
		revision += 1
		local token = revision
		for _, tween in activeTweens do
			tween:Cancel()
		end
		table.clear(activeTweens)
		local shown = desired and (visibleDuringFishing == true or not fishingActive)
		if shown then
			target.Visible = true
			target.Active = oldActive
			if target:IsA("GuiButton") and oldInteractable ~= nil then
				target.Interactable = oldInteractable
			end
		else
			target.Active = false
			if target:IsA("GuiButton") then
				target.Interactable = false
			end
		end
		local immediate = player:GetAttribute("ReduceEffects") == true
		for _, entry in properties do
			local value = if shown then entry.shown else 1
			if immediate then
				(entry.instance :: any)[entry.property] = value
			else
				local tween = TweenService:Create(
					entry.instance,
					TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ [entry.property] = value }
				)
				table.insert(activeTweens, tween)
				tween:Play()
			end
		end
		if not shown then
			if immediate then
				target.Visible = false
			else
				task.delay(0.2, function()
					if revision == token and target.Parent then
						target.Visible = false
					end
				end)
			end
		end
	end
	local fishingConnection = fishingChanged.Event:Connect(apply)
	local effectsConnection = player:GetAttributeChangedSignal("ReduceEffects"):Connect(apply)
	target.Destroying:Once(function()
		fishingConnection:Disconnect()
		effectsConnection:Disconnect()
		for _, tween in activeTweens do
			tween:Cancel()
		end
	end)
	apply()
	return function(visible: boolean)
		desired = visible
		apply()
	end
end

function Hud.showPanel(name: string)
	currentPanel = name
	panelChanged:Fire(name)
end

function Hud.toast(message: string, tint: Color3?)
	local label = toastLabel
	if not label or fishingActive then
		return
	end
	if setToastVisible then
		setToastVisible(currentPanel == "")
	end
	if activeToast then
		activeToast:Cancel()
	end
	label.Text = message
	label.TextColor3 = tint or Theme.ink
	label.TextTransparency = 0
	label.BackgroundTransparency = 0.04
	if toastStroke then
		toastStroke.Transparency = 0
	end
	local tween = TweenService:Create(
		label,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1.8),
		{
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}
	)
	if toastStroke then
		tween.Completed:Once(function()
			if toastStroke then
				toastStroke.Transparency = 1
			end
		end)
	end
	activeToast = tween
	tween:Play()
end

function Hud.start()
	local characterStateConnection: RBXScriptConnection? = nil
	local function watchCharacter(character: Model?)
		if characterStateConnection then
			characterStateConnection:Disconnect()
			characterStateConnection = nil
		end
		if character then
			characterStateConnection =
				character:GetAttributeChangedSignal("FishingState"):Connect(publishFishingState)
		end
		publishFishingState()
	end
	player.CharacterAdded:Connect(watchCharacter)
	player.CharacterRemoving:Connect(function()
		watchCharacter(nil)
		localFishingEvent = false
		publishFishingState()
	end)
	player:GetAttributeChangedSignal("CatchRevealActive"):Connect(publishFishingState)
	watchCharacter(player.Character)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
		local update = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent
		update.OnClientEvent:Connect(function(payload: Net.FishingUpdate)
			if payload.event == "cast" or payload.event == "bite" or payload.event == "caught" then
				localFishingEvent = true
				if payload.event == "caught" then
					localFishingRevision += 1
					local revision = localFishingRevision
					task.delay(12, function()
						if
							localFishingRevision == revision
							and player:GetAttribute("CatchRevealActive") ~= true
						then
							localFishingEvent = false
							publishFishingState()
						end
					end)
				end
			elseif
				payload.event == "escaped"
				or payload.event == "cancelled"
				or payload.event == "rejected"
			then
				localFishingEvent = false
				localFishingRevision += 1
			end
			publishFishingState()
		end)
	end)
	task.spawn(function()
		local images =
			{ Assets.coins, Assets.gift, Assets.goal, Assets.progress, Assets.rod, Assets.panel }
		for _, set in { Assets.navigation, Assets.rarity } do
			for _, id in set do
				table.insert(images, id)
			end
		end
		ContentProvider:PreloadAsync(images)
	end)
	local gui = Instance.new("ScreenGui")
	gui.Name = "AdventureHud"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 4

	local bar = Instance.new("Frame")
	bar.Name = "Navigation"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 6)
	bar.Size = UDim2.new(0.966, 0, 0, 54)
	bar.BackgroundTransparency = 1
	bar.Parent = gui
	navigation = bar
	local setBarVisible = Hud.bindFishingVisibility(bar, true)
	Hud.panelChanged:Connect(function(name)
		setBarVisible(name == "")
	end)

	local coins = Instance.new("Frame")
	coins.Name = "Coins"
	coins.BackgroundTransparency = 1
	Art.image(coins, Assets.coins)
	local balance = Art.caption(coins, "Balance", "—", 48)
	balance.Size = UDim2.fromScale(0.57, 0.64)
	balance.Position = UDim2.fromScale(0.37, 0.17)
	coins.Parent = bar
	local coinMotion = Motion.mount(coins, 0, 8)
	local counted = Instance.new("NumberValue")
	counted.Parent = coins
	counted.Changed:Connect(function(value)
		balance.Text = tostring(math.round(value))
	end)
	local coinTween: Tween? = nil
	local previousAmount: number? = nil
	local deltaLabel = Art.caption(coins, "CoinDelta", "", 20, Theme.gold)
	deltaLabel.AnchorPoint = Vector2.new(0.5, 1)
	deltaLabel.Position = UDim2.fromScale(0.76, 0.18)
	deltaLabel.Size = UDim2.fromScale(0.5, 0.38)
	deltaLabel.Visible = false
	local deltaStroke = Instance.new("UIStroke")
	deltaStroke.Color = Theme.outline
	deltaStroke.Thickness = 2
	deltaStroke.Parent = deltaLabel
	local deltaTween: Tween? = nil
	local deltaRevision = 0
	local function updateCoins()
		local amount = player:GetAttribute("Coins")
		if typeof(amount) ~= "number" then
			balance.Text = "—"
			return
		end
		local before = previousAmount
		previousAmount = amount
		if before and amount > before then
			coinMotion.pulse(0.9)
			deltaRevision += 1
			local revision = deltaRevision
			if deltaTween then
				deltaTween:Cancel()
			end
			deltaLabel.Text = `+{math.round(amount - before)}`
			deltaLabel.Position = UDim2.fromScale(0.76, 0.22)
			deltaLabel.TextTransparency = 0
			deltaStroke.Transparency = 0
			deltaLabel.Visible = true
			if player:GetAttribute("ReduceEffects") ~= true then
				local delta = TweenService:Create(
					deltaLabel,
					TweenInfo.new(0.72, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = UDim2.fromScale(0.76, -0.08), TextTransparency = 1 }
				)
				local strokeFade = TweenService:Create(
					deltaStroke,
					TweenInfo.new(0.72, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				)
				deltaTween = delta
				delta.Completed:Once(function()
					if deltaRevision == revision then
						deltaLabel.Visible = false
					end
				end)
				delta:Play()
				strokeFade:Play()
			else
				task.delay(0.6, function()
					if deltaRevision == revision then
						deltaLabel.Visible = false
					end
				end)
			end
		end
		if coinTween then
			coinTween:Cancel()
			coinTween = nil
		end
		if player:GetAttribute("ReduceEffects") == true then
			counted.Value = amount
			balance.Text = tostring(math.round(amount))
			return
		end
		balance.Text = tostring(math.round(counted.Value))
		local tween = TweenService:Create(
			counted,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad),
			{ Value = amount }
		)
		coinTween = tween
		tween:Play()
	end
	player:GetAttributeChangedSignal("Coins"):Connect(updateCoins)
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(updateCoins)
	updateCoins()

	local entries = {
		{ id = "Collection", title = Text.collection, tint = Theme.crystal, icon = "📖" },
		{ id = "Shop", title = Text.shop, tint = Theme.gold, icon = "🎣" },
		{ id = "Missions", title = Text.missions.nav, tint = Theme.rose, icon = "🏆" },
		{ id = "Achievements", title = Text.achievementUi.title, tint = Theme.gold, icon = "🏅" },
		{ id = "Leaderboard", title = Text.leaderboard.title, tint = Theme.crystal, icon = "👑" },
		{
			id = "Settings",
			title = Text.settings,
			tint = Color3.fromRGB(188, 151, 255),
			icon = "⚙️",
		},
	}
	local navBadges: { [string]: TextLabel } = {}
	local function makeNavBadge(button: GuiButton, name: string, tint: Color3): TextLabel
		local badge = Instance.new("TextLabel")
		badge.Name = name
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.Position = UDim2.new(1, 4, 0, -4)
		badge.Size = UDim2.fromOffset(28, 28)
		badge.BackgroundColor3 = tint
		badge.BorderSizePixel = 0
		badge.TextColor3 = Color3.new(1, 1, 1)
		badge.TextStrokeColor3 = Theme.outline
		badge.TextStrokeTransparency = 0
		badge.TextSize = 17
		badge.Font = Theme.font
		badge.Visible = false
		badge.ZIndex = 20
		Theme.corner(badge, 14)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Theme.outline
		stroke.Thickness = 2
		stroke.Parent = badge
		badge.Parent = button
		return badge
	end
	local levelChip = Instance.new("Frame")
	levelChip.Name = "FishingLevel"
	levelChip.AnchorPoint = Vector2.new(0, 0.5)
	levelChip.BackgroundColor3 = Theme.gold
	levelChip.BorderSizePixel = 0
	Theme.corner(levelChip, 16)
	local levelStroke = Instance.new("UIStroke")
	levelStroke.Color = Theme.outline
	levelStroke.Thickness = 3
	levelStroke.Parent = levelChip
	local levelIcon = Art.caption(levelChip, "LevelIcon", "⭐", 22, Theme.ink)
	levelIcon.Position = UDim2.fromScale(0.05, 0.12)
	levelIcon.Size = UDim2.fromScale(0.25, 0.76)
	levelIcon.TextStrokeTransparency = 1
	local levelLabel = Art.caption(levelChip, "LevelText", "", 18, Theme.ink)
	levelLabel.Position = UDim2.fromScale(0.29, 0.05)
	levelLabel.Size = UDim2.fromScale(0.67, 0.41)
	levelLabel.TextStrokeTransparency = 1
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	local levelTrack = Instance.new("Frame")
	levelTrack.Name = "LevelTrack"
	levelTrack.Position = UDim2.fromScale(0.29, 0.84)
	levelTrack.Size = UDim2.fromScale(0.63, 0.09)
	levelTrack.BackgroundColor3 = Theme.track
	levelTrack.BorderSizePixel = 0
	Theme.corner(levelTrack, 5)
	local levelFill = Instance.new("Frame")
	levelFill.Name = "LevelFill"
	levelFill.Size = UDim2.fromScale(0, 1)
	levelFill.BackgroundColor3 = Theme.crystal
	levelFill.BorderSizePixel = 0
	Theme.corner(levelFill, 5)
	levelFill.Parent = levelTrack
	levelTrack.Parent = levelChip
	local xpLabel = Art.caption(levelChip, "LevelXP", "", 11, Theme.ink)
	xpLabel.Position = UDim2.fromScale(0.29, 0.46)
	xpLabel.Size = UDim2.fromScale(0.67, 0.34)
	xpLabel.TextXAlignment = Enum.TextXAlignment.Left
	xpLabel.TextStrokeTransparency = 1
	levelChip.Parent = bar
	local levelTween: Tween? = nil
	local function updateLevel()
		local level = player:GetAttribute("PlayerLevel")
		local xp = player:GetAttribute("PlayerLevelXP")
		local total = player:GetAttribute("PlayerLevelXPTotal")
		local combo = player:GetAttribute("FishingCombo")
		local streak = if typeof(combo) == "number" then combo else 0
		local hasLevel = typeof(level) == "number"
		levelChip.Visible = hasLevel
		levelTrack.Visible = typeof(xp) == "number" and typeof(total) == "number" and total > 0
		if typeof(xp) == "number" and typeof(total) == "number" and total > 0 then
			local target = UDim2.fromScale(math.clamp(xp / total, 0, 1), 1)
			if levelTween then
				levelTween:Cancel()
			end
			if player:GetAttribute("ReduceEffects") == true then
				levelFill.Size = target
			else
				local tween = TweenService:Create(levelFill, TweenInfo.new(0.2), { Size = target })
				levelTween = tween
				tween:Play()
			end
			xpLabel.Text = string.format("%d / %d XP", xp, total)
		end
		xpLabel.Visible = levelTrack.Visible
		local title = if typeof(level) == "number"
			then string.format(Text.adventure.level, level)
			else ""
		levelLabel.Text = if streak >= 2
			then title .. " · " .. string.format(Text.adventure.combo, streak)
			else title
	end
	for _, attribute in
		{
			"PlayerLevel",
			"PlayerLevelXP",
			"PlayerLevelXPTotal",
			"FishingCombo",
			"ReduceEffects",
		}
	do
		player:GetAttributeChangedSignal(attribute):Connect(updateLevel)
	end
	updateLevel()

	local moreButton = Instance.new("TextButton")
	moreButton.Name = "MoreButton"
	moreButton.AnchorPoint = Vector2.new(1, 0.5)
	moreButton.BackgroundColor3 = Theme.crystal
	moreButton.BorderSizePixel = 0
	moreButton.Text = ""
	moreButton.TextColor3 = Theme.ink
	moreButton.TextSize = 27
	moreButton.TextStrokeColor3 = Theme.outline
	moreButton.TextStrokeTransparency = 0.8
	moreButton.Font = Theme.font
	moreButton.AutoButtonColor = false
	Theme.surface(moreButton, Theme.crystal, 16)
	moreButton.BackgroundTransparency = 0.08
	local moreGradient = moreButton:FindFirstChildWhichIsA("UIGradient")
	if moreGradient then
		moreGradient.Transparency = NumberSequence.new(0.12)
	end
	Motion.mount(moreButton)
	moreButton.Parent = bar
	local menuIcon = Instance.new("Frame")
	menuIcon.Name = "MoreIcon"
	menuIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	menuIcon.Position = UDim2.fromScale(0.5, 0.5)
	menuIcon.Size = UDim2.fromScale(0.5, 0.42)
	menuIcon.BackgroundTransparency = 1
	menuIcon.Active = false
	menuIcon.ZIndex = moreButton.ZIndex + 2
	menuIcon.Parent = moreButton
	for index = 1, 3 do
		local line = Instance.new("Frame")
		line.Name = `Line{index}`
		line.Position = UDim2.fromScale(0, (index - 1) * 0.4)
		line.Size = UDim2.fromScale(1, 0.2)
		line.BackgroundColor3 = Theme.ink
		line.BorderSizePixel = 0
		line.ZIndex = menuIcon.ZIndex
		Theme.corner(line, 4)
		line.Parent = menuIcon
	end
	local setMoreButtonVisible = Hud.bindFishingVisibility(moreButton, false)
	setMoreButtonVisible(true)
	Hud.panelChanged:Connect(function(name)
		setMoreButtonVisible(name == "")
	end)

	local menu = Instance.new("Frame")
	menu.Name = "QuickMenu"
	menu.AnchorPoint = Vector2.new(0.5, 0)
	menu.BackgroundColor3 = Theme.crystal
	menu.BorderSizePixel = 0
	menu.Visible = false
	Art.panel(menu, Theme.crystal)
	local menuMotion = Motion.mount(menu)
	menu.Parent = gui
	local setMenuVisible = Hud.bindFishingVisibility(menu, false)
	local menuOpen = false
	local moreBadge = Instance.new("TextLabel")
	moreBadge.Name = "NotificationBadge"
	moreBadge.AnchorPoint = Vector2.new(1, 0)
	moreBadge.Position = UDim2.new(1, 4, 0, -4)
	moreBadge.Size = UDim2.fromOffset(26, 26)
	moreBadge.BackgroundColor3 = Theme.rose
	moreBadge.BorderSizePixel = 0
	moreBadge.TextColor3 = Color3.new(1, 1, 1)
	moreBadge.TextStrokeColor3 = Theme.outline
	moreBadge.TextStrokeTransparency = 0
	moreBadge.TextSize = 17
	moreBadge.Font = Theme.font
	moreBadge.Visible = false
	Theme.corner(moreBadge, 13)
	local moreBadgeStroke = Instance.new("UIStroke")
	moreBadgeStroke.Color = Theme.outline
	moreBadgeStroke.Thickness = 2
	moreBadgeStroke.Parent = moreBadge
	moreBadge.Parent = moreButton
	local newCatch = false
	local readyMissionCount = 0
	local refreshMoreBadge: () -> ()
	local function openMenu(open: boolean)
		local wasOpen = menuOpen
		menuOpen = open and not fishingActive
		if menuOpen ~= wasOpen then
			menuIsOpen = menuOpen
			menuChanged:Fire(menuOpen)
		end
		setMenuVisible(menuOpen and currentPanel == "")
		if menuOpen and not wasOpen then
			menuMotion.pulse(0.94)
		end
		local missionBadge = navBadges.Missions
		if missionBadge then
			missionBadge.Visible = menuOpen and readyMissionCount > 0
		end
		local collectionBadge = navBadges.Collection
		if collectionBadge then
			collectionBadge.Visible = menuOpen and newCatch
		end
		refreshMoreBadge()
	end
	refreshMoreBadge = function()
		local count = math.min(9, readyMissionCount)
		moreBadge.Text = if newCatch then "!" else tostring(count)
		moreBadge.Visible = (newCatch or count > 0) and not menuOpen and not fishingActive
	end
	moreButton.Activated:Connect(function()
		openMenu(not menuOpen)
	end)
	Hud.fishingChanged:Connect(function(active)
		if active then
			openMenu(false)
			if currentPanel ~= "" then
				Hud.showPanel("")
			end
		end
		refreshMoreBadge()
	end)

	for i, entry in entries do
		local asset = Assets.navigation[entry.id]
		local button = Instance.new("TextButton")
		button.BackgroundTransparency = 1
		button.AutoButtonColor = false
		button.Text = ""
		local fallback = Instance.new("Frame")
		fallback.Name = "Fallback"
		fallback.Size = UDim2.fromScale(1, 1)
		Theme.surface(fallback, entry.tint, 14)
		local icon = Art.caption(fallback, "Icon", entry.icon, 42)
		icon.Size = UDim2.fromScale(0.72, 0.58)
		icon.Position = UDim2.fromScale(0.14, 0.08)
		fallback.Parent = button
		local art: ImageLabel? = nil
		if asset then
			art = Art.image(button, asset)
		end
		button.Name = entry.id
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		local label = Art.caption(button, "Label", entry.title, 24)
		label.ZIndex = 2
		local function layoutArt()
			local loaded = if art then art.IsLoaded else false
			fallback.Visible = not loaded
			label.Position = if loaded
				then UDim2.fromScale(0.1, 0.731)
				else UDim2.fromScale(0.04, 0.68)
			label.Size = if loaded then UDim2.fromScale(0.8, 0.19) else UDim2.fromScale(0.92, 0.24)
		end
		if art then
			art:GetPropertyChangedSignal("IsLoaded"):Connect(layoutArt)
		end
		layoutArt()
		local badge = makeNavBadge(button, "NotificationBadge", entry.tint)
		if entry.id == "Missions" then
			navBadges.Missions = badge
		elseif entry.id == "Collection" then
			navBadges.Collection = badge
		end
		Motion.mount(button, 0.3, 7 + i * 0.42)
		Hud.panelChanged:Connect(function(name)
			local selected = name == entry.id
				or (entry.id == "Collection" and name == "Milestones")
				or (entry.id == "Shop" and name == "Robux")
			if art then
				art.ImageColor3 = if selected
					then Color3.fromRGB(235, 217, 255)
					else Color3.new(1, 1, 1)
			end
			if name == "Collection" or name == "Milestones" then
				newCatch = false
				if navBadges.Collection then
					navBadges.Collection.Visible = false
				end
				refreshMoreBadge()
			end
		end)
		button.Activated:Connect(function()
			openMenu(false)
			Hud.showPanel(if currentPanel == entry.id then "" else entry.id)
		end)
		button.Parent = menu
	end
	Hud.panelChanged:Connect(function(name)
		if name ~= "" then
			openMenu(false)
		end
	end)

	local function updateMissionBadge(snapshot: Types.Snapshot?)
		local badge = navBadges.Missions
		if not badge then
			return
		end
		local missions = snapshot and snapshot.missions
		local ready = 0
		if missions and missions.day == Missions.today() then
			for _, mission in missions.list do
				if not mission.claimed and mission.progress >= mission.target then
					ready += 1
				end
			end
		end
		readyMissionCount = ready
		badge.Text = if ready > 9 then "9+" else tostring(ready)
		badge.Visible = ready > 0 and menuOpen and not fishingActive
		refreshMoreBadge()
	end
	Data.changed:Connect(updateMissionBadge)
	Hud.panelChanged:Connect(function(name)
		if name == "Missions" then
			local badge = navBadges.Missions
			if badge then
				badge.Visible = false
			end
		else
			updateMissionBadge(Data.get())
		end
	end)
	updateMissionBadge(Data.get())
	local collectionBadge = navBadges.Collection
	if collectionBadge then
		local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
		local update = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent
		update.OnClientEvent:Connect(function(payload: Net.FishingUpdate)
			if payload.event == "caught" and payload.isNew == true and Hud.panel() == "" then
				newCatch = true
				collectionBadge.Text = "!"
				collectionBadge.Visible = menuOpen and not fishingActive
				refreshMoreBadge()
			end
		end)
	end
	local function layout()
		local size = gui.AbsoluteSize
		local width = size.X * 0.966
		local portrait = size.Y > size.X
		local height = if portrait
			then math.clamp(math.round(size.Y * 0.065), 50, 60)
			else math.clamp(math.round(size.Y * 0.12), 50, 76)
		bar.Size = UDim2.new(0.966, 0, 0, height)
		-- Art keeps its own proportions (moedas.png is 1024x386): never stretch it.
		local coinHeight = math.round(height * 0.84)
		local coinWidth = math.round(coinHeight * COIN_RATIO)
		coins.Size = UDim2.fromOffset(coinWidth, coinHeight)
		coins.Position = UDim2.fromOffset(0, math.round(height * 0.08))
		local levelWidth =
			math.round(math.clamp(width * (if portrait then 0.34 else 0.14), 104, 150))
		levelChip.Size = UDim2.fromOffset(levelWidth, math.round(height * 0.72))
		levelChip.Position = UDim2.fromOffset(coinWidth + 8, height / 2)
		local menuSize = math.clamp(height * 0.82, 46, 60)
		moreButton.Size = UDim2.fromOffset(menuSize, menuSize)
		moreButton.Position = UDim2.fromScale(1, 0.5)
		-- Use fewer rows on short screens while keeping the original art proportions.
		local columns = if portrait then 2 else 3
		local rows = math.ceil(#entries / columns)
		local gap = 8
		local inset = 16
		local preferredWidth =
			math.clamp(math.round(size.Y * (if portrait then 0.15 else 0.24)), 92, 150)
		local fitWidth = (width - inset * 2 - (columns - 1) * gap) / columns
		local fitHeight = (size.Y - height - 24 - inset * 2 - (rows - 1) * gap) / rows
		local cellWidth = math.max(
			math.ceil(44 * NAV_RATIO),
			math.floor(math.min(preferredWidth, fitWidth, fitHeight * NAV_RATIO))
		)
		local cellHeight = math.round(cellWidth / NAV_RATIO)
		local popupWidth = columns * cellWidth + (columns - 1) * gap + inset * 2
		local popupHeight = rows * cellHeight + (rows - 1) * gap + inset * 2
		menu.Size = UDim2.fromOffset(popupWidth, popupHeight)
		menu.AnchorPoint = Vector2.new(1, 0)
		menu.Position = UDim2.new(0.983, 0, 0, height + 12)
		for index, entry in entries do
			local button = menu:FindFirstChild(entry.id) :: GuiButton
			local row = math.floor((index - 1) / columns)
			local column = (index - 1) % columns
			button.AnchorPoint = Vector2.zero
			button.Size = UDim2.fromOffset(cellWidth, cellHeight)
			button.Position = UDim2.fromOffset(
				inset + column * (cellWidth + gap),
				inset + row * (cellHeight + gap)
			)
		end
		resized:Fire()
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)

	local badge = Instance.new("Frame")
	badge.Name = "RecentRarity"
	badge.AnchorPoint = Vector2.new(0, 0)
	badge.Position = UDim2.fromScale(0.027, 0.32)
	badge.Size = UDim2.fromScale(0.16, 0.16)
	badge.Visible = false
	local badgeRatio = Instance.new("UIAspectRatioConstraint")
	badgeRatio.AspectRatio = RARITY_RATIO
	badgeRatio.DominantAxis = Enum.DominantAxis.Width
	badgeRatio.Parent = badge
	local badgeBounds = Instance.new("UISizeConstraint")
	badgeBounds.MinSize = Vector2.new(120, 40)
	badgeBounds.MaxSize = Vector2.new(240, 80)
	badgeBounds.Parent = badge
	badge.BackgroundTransparency = 1
	local badgeArt, rarityText = Art.rarity(badge)
	badge.Parent = gui
	local setRarityBadgeVisible = Hud.bindFishingVisibility(badge, false)
	local hasRecent = false
	local rarityRevision = 0
	local function refreshRarity()
		setRarityBadgeVisible(hasRecent and currentPanel == "")
	end
	local function expireRarity()
		if not hasRecent then
			return
		end
		rarityRevision += 1
		local revision = rarityRevision
		task.delay(8, function()
			if rarityRevision == revision then
				hasRecent = false
				refreshRarity()
			end
		end)
	end
	Hud.panelChanged:Connect(function(name)
		setRarityBadgeVisible(hasRecent and name == "")
	end)
	Hud.fishingChanged:Connect(function(active)
		if active then
			rarityRevision += 1
		else
			expireRarity()
		end
	end)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
		local update = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent
		update.OnClientEvent:Connect(function(payload: Net.FishingUpdate)
			local creature = if payload.creatureId then Creatures.get(payload.creatureId) else nil
			if payload.event == "caught" and creature then
				Art.setRarity(badgeArt, rarityText, creature.rarity)
				hasRecent = true
				refreshRarity()
				if not fishingActive then
					expireRarity()
				end
			elseif payload.event == "cast" or payload.event == "bite" then
				rarityRevision += 1
				hasRecent = false
				refreshRarity()
			end
		end)
	end)

	local perks = Instance.new("TextLabel")
	perks.Name = "Perks"
	perks.AnchorPoint = Vector2.new(1, 0.5)
	perks.Position = UDim2.fromScale(0.97, 0.5)
	perks.Size = UDim2.fromOffset(134, 28)
	perks.TextColor3 = Theme.gold
	perks.Font = Theme.font
	perks.TextSize = 13
	perks.TextWrapped = true
	Theme.surface(perks, Theme.gold, 8, Theme.ink)
	perks.Parent = gui
	local setPerksVisible = Hud.bindFishingVisibility(perks, false)
	local vip = Products.passAttribute("vip")
	local function updatePerks()
		local names = {}
		if player:GetAttribute(vip) == true then
			table.insert(names, Text.robux.vipBadge)
		end
		local ends = player:GetAttribute(Products.LUCK_BOOST_ATTRIBUTE)
		local remaining = if typeof(ends) == "number"
			then math.max(0, math.ceil(ends - os.time()))
			else 0
		if remaining > 0 then
			table.insert(
				names,
				string.format(Text.robux.luckTimer, math.floor(remaining / 60), remaining % 60)
			)
		end
		local starterTime = StarterOffer.remaining()
		local perkText = table.concat(names, "  ·  ")
		if starterTime > 0 then
			local starterText = Text.robux.starterPack .. " · " .. StarterOffer.clock(starterTime)
			perks.Text = if #names > 0 then perkText .. "\n" .. starterText else starterText
			perks.Size = UDim2.fromOffset(176, if #names > 0 then 44 else 28)
		else
			perks.Text = perkText
			perks.Size = UDim2.fromOffset(134, 28)
		end
		setPerksVisible((#names > 0 or starterTime > 0) and currentPanel == "")
	end
	player:GetAttributeChangedSignal(vip):Connect(updatePerks)
	player:GetAttributeChangedSignal(Products.LUCK_BOOST_ATTRIBUTE):Connect(updatePerks)
	for _, attribute in
		{
			StarterOffer.availableAttribute,
			StarterOffer.ownedAttribute,
			StarterOffer.endsAtAttribute,
		}
	do
		player:GetAttributeChangedSignal(attribute):Connect(updatePerks)
	end
	Hud.panelChanged:Connect(updatePerks)
	updatePerks()

	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0.5, 1)
	toast.Position = UDim2.fromScale(0.5, 0.94)
	toast.Size = UDim2.new(0.62, 0, 0, 46)
	toast.BackgroundColor3 = Theme.cream
	toast.BackgroundTransparency = 1
	toast.TextTransparency = 1
	toast.TextScaled = true
	toast.TextWrapped = true
	local toastTextSize = Instance.new("UITextSizeConstraint")
	toastTextSize.MaxTextSize = 18
	toastTextSize.Parent = toast
	toast.Font = Theme.font
	Theme.corner(toast, 10)
	local outline = Instance.new("UIStroke")
	outline.Color = Theme.outline
	outline.Thickness = 3
	outline.Transparency = 1
	outline.Parent = toast
	local notifications = Instance.new("ScreenGui")
	notifications.Name = "AdventureNotifications"
	notifications.ResetOnSpawn = false
	notifications.DisplayOrder = 12
	toast.Parent = notifications
	toastLabel = toast
	toastStroke = outline
	local showToast = Hud.bindFishingVisibility(toast, false)
	setToastVisible = showToast
	showToast(true)
	Hud.panelChanged:Connect(function(name)
		showToast(name == "")
	end)
	local playerGui = player:WaitForChild("PlayerGui")
	gui.Parent = playerGui
	layout()
	notifications.Parent = playerGui
	task.spawn(RodHotbar.mount, gui, Hud.panelChanged, Hud.panel, Hud.bindFishingVisibility)
	task.spawn(function()
		while gui.Parent do
			task.wait(1)
			updatePerks()
		end
	end)
end

return Hud
