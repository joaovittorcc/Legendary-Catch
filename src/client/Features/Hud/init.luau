--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Products = require(Shared:WaitForChild("Config"):WaitForChild("Products"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Wood = require(script:WaitForChild("Wood"))
local RodHotbar = require(script:WaitForChild("RodHotbar"))

local Hud = { order = 10 }
local player = Players.LocalPlayer
local panelChanged = Instance.new("BindableEvent")
Hud.panelChanged = panelChanged.Event
local currentPanel = ""
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
	bar.Size = UDim2.new(0.96, 0, 0, 54)
	bar.BackgroundTransparency = 1
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(720, 54)
	bounds.Parent = bar
	bar.Parent = gui

	local coins = Instance.new("Frame")
	coins.Name = "Coins"
	coins.Size = UDim2.fromScale(0.195, 1)
	Wood.mount(coins, true)
	local moneyIcon = Wood.icon(coins, "Coin", 30)
	moneyIcon.AnchorPoint = Vector2.new(0, 0.5)
	local balance = Wood.caption(coins, "Balance", "—", 26)
	balance.TextXAlignment = Enum.TextXAlignment.Center
	local function placeBalance()
		local small = coins.AbsoluteSize.X < 86
		local iconSize = if small then 19 else 30
		local offset = if small then 6 else 12
		moneyIcon.Size = UDim2.fromOffset(iconSize, iconSize)
		moneyIcon.Position = UDim2.new(0, offset, 0.5, 0)
		balance.Size = UDim2.new(1, -(iconSize + offset + 8), 1, -6)
		balance.Position = UDim2.fromOffset(iconSize + offset + 2, 3)
	end
	coins:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeBalance)
	coins.Parent = bar
	placeBalance()
	local counted = Instance.new("NumberValue")
	counted.Parent = coins
	counted.Changed:Connect(function(value)
		balance.Text = tostring(math.round(value))
	end)
	local coinTween: Tween? = nil
	local function updateCoins()
		local amount = player:GetAttribute("Coins")
		if typeof(amount) ~= "number" then
			balance.Text = "—"
			return
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
		local button = Instance.new("TextButton")
		button.Name = entry.id
		button.Position = UDim2.fromScale(0.207 + (i - 1) * 0.2, 0)
		button.Size = UDim2.fromScale(0.19, 1)
		button.Text = ""
		local edge = Wood.mount(button)
		local idle = edge.Color
		local icon = Wood.icon(button, entry.id, 29)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 3)
		local label = Wood.caption(button, "Label", entry.title, 14)
		label.Position = UDim2.fromOffset(5, 32)
		label.Size = UDim2.new(1, -10, 0, 18)
		Hud.panelChanged:Connect(function(name)
			local selected = name == entry.id
				or (entry.id == "Collection" and name == "Milestones")
				or (entry.id == "Shop" and name == "Robux")
			edge.Color = if selected then Theme.crystal else idle
			edge.Thickness = if selected then 3 else 2
		end)
		button.Activated:Connect(function()
			Hud.showPanel(if currentPanel == entry.id then "" else entry.id)
		end)
		button.Parent = bar
	end

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
