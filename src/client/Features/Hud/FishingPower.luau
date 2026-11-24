--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Training = require(Shared.Config.Training)
local Strings = require(Shared.Strings)
local Text = require(Shared.StringsUi).fishingPower
local Theme = require(Shared.UiTheme)
local Art = require(script.Parent.Art)

local FishingPower = {}

local function fullPower(power: number): string
	local digits = string.format("%.0f", power):reverse()
	local grouped = digits:gsub("(%d%d%d)", "%1" .. Strings.thousandsSep)
	return (grouped:reverse():gsub("^%D", ""))
end

function FishingPower.mount(screen: ScreenGui, bar: Frame, menuChanged: RBXScriptSignal)
	local player = Players.LocalPlayer
	local controlAttribute = Training.powerAttribute("Control")
	local instinctAttribute = Training.powerAttribute("Instinct")

	local chip = Instance.new("TextButton")
	chip.Name = "FishingPower"
	chip.AnchorPoint = Vector2.new(1, 0)
	chip.Size = UDim2.fromScale(0.38, 0.7)
	chip.Text = ""
	chip.AutoButtonColor = false
	chip.Visible = false
	Theme.surface(chip, Theme.crystal, 12, Theme.ink)
	local stroke = chip:FindFirstChildOfClass("UIStroke")
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(112, 44)
	bounds.MaxSize = Vector2.new(202, 54)
	bounds.Parent = chip

	local title = Art.caption(chip, "Title", Text.title, 13, Theme.cream)
	title.Position = UDim2.fromScale(0.06, 0.09)
	title.Size = UDim2.fromScale(0.88, 0.33)
	local value = Art.caption(chip, "Value", "", 23, Theme.cream)
	value.Position = UDim2.fromScale(0.06, 0.42)
	value.Size = UDim2.fromScale(0.88, 0.48)

	local expanded = false
	local menuOpen = false
	local function layout()
		local viewport = screen.AbsoluteSize
		-- The zone indicator occupies the first row below navigation in portrait.
		chip.Position = UDim2.new(1, 0, 1, if viewport.Y > viewport.X then 52 else 8)
	end
	local function refresh()
		local control = player:GetAttribute(controlAttribute)
		local instinct = player:GetAttribute(instinctAttribute)
		if typeof(control) ~= "number" or typeof(instinct) ~= "number" then
			chip.Visible = false
			return
		end
		local total = control + instinct
		local tint = Training.TIER_COLORS[Training.tier(total)]
		value.Text = if expanded
			then fullPower(total)
			else Training.formatPower(total, Strings.decimalSep)
		value.TextColor3 = tint
		if stroke then
			stroke.Color = tint:Lerp(Theme.outline, 0.45)
		end
		chip.Visible = not menuOpen
	end
	chip.Activated:Connect(function()
		expanded = not expanded
		refresh()
	end)
	local controlChanged = player:GetAttributeChangedSignal(controlAttribute):Connect(refresh)
	local instinctChanged = player:GetAttributeChangedSignal(instinctAttribute):Connect(refresh)
	local resized = screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	local menuConnection = menuChanged:Connect(function(open: boolean)
		menuOpen = open
		refresh()
	end)
	chip.Destroying:Once(function()
		controlChanged:Disconnect()
		instinctChanged:Disconnect()
		resized:Disconnect()
		menuConnection:Disconnect()
	end)
	layout()
	chip.Parent = bar
	refresh()
end

return FishingPower
