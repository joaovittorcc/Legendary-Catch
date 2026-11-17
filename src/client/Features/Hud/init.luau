--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))

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
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 4

	local bar = Instance.new("Frame")
	bar.Name = "Navigation"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.fromScale(0.5, 0.025)
	bar.Size = UDim2.fromScale(0.8, 0.085)
	bar.BackgroundTransparency = 1
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(272, 44)
	bounds.MaxSize = Vector2.new(520, 56)
	bounds.Parent = bar
	bar.Parent = gui

	local coins = Instance.new("TextLabel")
	coins.Name = "Coins"
	coins.Size = UDim2.fromScale(0.23, 1)
	coins.TextColor3 = Theme.gold
	coins.TextScaled = true
	coins.Font = Theme.font
	Theme.surface(coins, Theme.gold, 12)
	coins.Parent = bar
	local counted = Instance.new("NumberValue")
	counted.Parent = coins
	counted.Changed:Connect(function(value)
		coins.Text = `◆ {math.round(value)}`
	end)
	local coinTween: Tween? = nil
	local function updateCoins()
		local amount = player:GetAttribute("Coins")
		if typeof(amount) ~= "number" then
			coins.Text = "◆ —"
			return
		end
		if coinTween then
			coinTween:Cancel()
		end
		coins.Text = `◆ {math.round(counted.Value)}`
		local tween = TweenService:Create(
			counted,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad),
			{ Value = amount }
		)
		coinTween = tween
		tween:Play()
	end
	player:GetAttributeChangedSignal("Coins"):Connect(updateCoins)
	updateCoins()

	local entries = {
		{ id = "Collection", title = Text.collection, tint = Theme.crystal },
		{ id = "Shop", title = Text.shop, tint = Theme.gold },
		{ id = "Settings", title = Text.settings, tint = Theme.rose },
	}
	for i, entry in entries do
		local button = Instance.new("TextButton")
		button.Name = entry.id
		button.Position = UDim2.fromScale(0.25 + (i - 1) * 0.255, 0)
		button.Size = UDim2.fromScale(0.24, 1)
		button.Text = entry.title
		button.TextSize = 16
		button.Font = Theme.font
		button.TextColor3 = Theme.sand
		Theme.surface(button, entry.tint, 12)
		button.Activated:Connect(function()
			Hud.showPanel(if currentPanel == entry.id then "" else entry.id)
		end)
		button.Parent = bar
	end

	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.fromScale(0.5, 0.15)
	toast.Size = UDim2.fromScale(0.55, 0.065)
	toast.BackgroundColor3 = Theme.ink
	toast.BackgroundTransparency = 1
	toast.TextTransparency = 1
	toast.TextScaled = true
	toast.Font = Theme.font
	Theme.corner(toast, 10)
	toast.Parent = gui
	toastLabel = toast
	gui.Parent = player:WaitForChild("PlayerGui")
end

return Hud
