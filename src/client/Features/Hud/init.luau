--!strict
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local Products = require(Shared:WaitForChild("Config"):WaitForChild("Products"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Art = require(script:WaitForChild("Art"))
local Assets = require(script:WaitForChild("Assets"))
local Motion = require(script:WaitForChild("Motion"))
local RodHotbar = require(script:WaitForChild("RodHotbar"))

local Hud = { order = 10 }
local player = Players.LocalPlayer
local panelChanged = Instance.new("BindableEvent")
Hud.panelChanged = panelChanged.Event
local currentPanel = ""
local navigation: Frame? = nil
local resized = Instance.new("BindableEvent")
Hud.layoutChanged = resized.Event

function Hud.navBottom(): number
	local bar = navigation
	return if bar then bar.Position.Y.Offset + bar.Size.Y.Offset else 64
end
local activeToast: Tween? = nil
local toastLabel: TextLabel? = nil

function Hud.panel(): string
	return currentPanel
end

function Hud.showPanel(name: string)
	currentPanel = name
	panelChanged:Fire(name)
end

function Hud.toast(message: string, tint: Color3?)
	local label = toastLabel
	if not label then
		return
	end
	if activeToast then
		activeToast:Cancel()
	end
	label.Text = message
	label.TextColor3 = tint or Theme.sand
	label.TextTransparency = 0
	label.BackgroundTransparency = 0.12
	local tween = TweenService:Create(
		label,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1.8),
		{
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}
	)
	activeToast = tween
	tween:Play()
end

function Hud.start()
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
	local function updateCoins()
		local amount = player:GetAttribute("Coins")
		if typeof(amount) ~= "number" then
			balance.Text = "—"
			return
		end
		local before = previousAmount
		previousAmount = amount
		if before and amount > before then
			coinMotion.pulse(0.96)
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
		{ id = "Collection", title = Text.collection },
		{ id = "Shop", title = Text.shop },
		{ id = "Missions", title = Text.missions.nav },
		{ id = "Settings", title = Text.settings },
	}
	for i, entry in entries do
		local button = Art.button(Assets.navigation[entry.id])
		button.Name = entry.id
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		local label = Art.caption(button, "Label", entry.title, 29)
		label.Position = UDim2.fromScale(0.1, 0.731)
		label.Size = UDim2.fromScale(0.8, 0.19)
		Motion.mount(button, 0.65, 6 + i * 0.42)
		Hud.panelChanged:Connect(function(name)
			local selected = name == entry.id
				or (entry.id == "Collection" and name == "Milestones")
				or (entry.id == "Shop" and name == "Robux")
			button.ImageColor3 = if selected
				then Color3.fromRGB(235, 217, 255)
				else Color3.new(1, 1, 1)
		end)
		button.Activated:Connect(function()
			Hud.showPanel(if currentPanel == entry.id then "" else entry.id)
		end)
		button.Parent = bar
	end
	local function layout()
		local size = gui.AbsoluteSize
		local width = size.X * 0.966
		local height = math.clamp(math.round(size.Y * 0.14), 50, 123)
		bar.Size = UDim2.new(0.966, 0, 0, height)
		local coinWidth = math.round(math.min(width * 0.205, height * 2.05))
		coins.Size = UDim2.fromOffset(coinWidth, math.round(height * 0.84))
		coins.Position = UDim2.fromOffset(0, math.round(height * 0.08))
		local gap = math.clamp(width * 0.008, 4, 12)
		local buttonWidth =
			math.floor(math.min(height * 1.30, (width - coinWidth - gap * 4) / #entries))
		local groupWidth = buttonWidth * #entries + gap * (#entries - 1)
		local left = math.max(coinWidth + gap, (width - groupWidth) / 2)
		for i, entry in entries do
			local button = bar:FindFirstChild(entry.id) :: ImageButton
			button.Size = UDim2.fromOffset(buttonWidth, height)
			button.Position = UDim2.fromOffset(
				math.round(left + buttonWidth / 2 + (i - 1) * (buttonWidth + gap)),
				height / 2
			)
		end
		resized:Fire()
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)

	local badge = Instance.new("Frame")
	badge.Name = "RecentRarity"
	badge.AnchorPoint = Vector2.new(0, 0)
	badge.Position = UDim2.fromScale(0.027, 0.32)
	badge.Size = UDim2.fromScale(0.16, 0.053)
	badge.Visible = false
	local badgeBounds = Instance.new("UISizeConstraint")
	badgeBounds.MinSize = Vector2.new(106, 25)
	badgeBounds.MaxSize = Vector2.new(222, 55)
	badgeBounds.Parent = badge
	badge.BackgroundTransparency = 1
	local badgeArt, rarityText = Art.rarity(badge)
	badge.Parent = gui
	local recent = 0
	Hud.panelChanged:Connect(function(name)
		badge.Visible = name == "" and os.clock() < recent
	end)
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
		local update = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent
		update.OnClientEvent:Connect(function(payload: Net.FishingUpdate)
			local creature = if payload.creatureId then Creatures.get(payload.creatureId) else nil
			if payload.event == "caught" and creature then
				Art.setRarity(badgeArt, rarityText, creature.rarity)
				recent = os.clock() + 8
				local deadline = recent
				badge.Visible = currentPanel == ""
				task.delay(8, function()
					if recent == deadline then
						badge.Visible = false
					end
				end)
			elseif payload.event == "bite" then
				recent = 0
				badge.Visible = false
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
	Theme.surface(perks, Theme.gold, 8, Theme.ink)
	perks.Parent = gui
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
		perks.Text = table.concat(names, "  ·  ")
		perks.Visible = #names > 0 and currentPanel == ""
	end
	player:GetAttributeChangedSignal(vip):Connect(updatePerks)
	player:GetAttributeChangedSignal(Products.LUCK_BOOST_ATTRIBUTE):Connect(updatePerks)
	Hud.panelChanged:Connect(updatePerks)
	updatePerks()

	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0.5, 1)
	toast.Position = UDim2.fromScale(0.5, 0.94)
	toast.Size = UDim2.new(0.58, 0, 0, 40)
	toast.BackgroundColor3 = Theme.ink
	toast.BackgroundTransparency = 1
	toast.TextTransparency = 1
	toast.TextScaled = true
	toast.TextWrapped = true
	local toastTextSize = Instance.new("UITextSizeConstraint")
	toastTextSize.MaxTextSize = 18
	toastTextSize.Parent = toast
	toast.Font = Theme.font
	Theme.corner(toast, 10)
	local notifications = Instance.new("ScreenGui")
	notifications.Name = "AdventureNotifications"
	notifications.ResetOnSpawn = false
	notifications.DisplayOrder = 12
	toast.Parent = notifications
	toastLabel = toast
	local playerGui = player:WaitForChild("PlayerGui")
	gui.Parent = playerGui
	layout()
	notifications.Parent = playerGui
	task.spawn(RodHotbar.mount, gui, Hud.panelChanged, Hud.panel)
	task.spawn(function()
		while gui.Parent do
			task.wait(1)
			updatePerks()
		end
	end)
end

return Hud
