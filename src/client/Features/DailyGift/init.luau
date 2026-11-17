--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Types = require(Shared:WaitForChild("Types"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Wood = require(script.Parent.Hud:WaitForChild("Wood"))
local Juice = require(script.Parent:WaitForChild("Juice"))

local DailyGift = { order = 130 }
local player = Players.LocalPlayer

local function show(playerGui: PlayerGui, gift: Types.Daily)
	local gui = Instance.new("ScreenGui")
	gui.Name = "DailyGift"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 6
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local card = Instance.new("Frame")
	card.Name = "GiftCard"
	card.AnchorPoint = Vector2.new(1, 0)
	Wood.mount(card)
	local chest = Wood.icon(card, "Chest", 49)
	chest.Position = UDim2.fromOffset(7, 8)
	local adventure = playerGui:FindFirstChild("AdventureHud")
	local navigation = adventure and adventure:FindFirstChild("Navigation")
	local lastButton = navigation and navigation:FindFirstChild("Settings")
	local function place()
		local width = math.clamp(gui.AbsoluteSize.X * 0.193, 120, 344)
		local hasSideRoom = lastButton
			and lastButton:IsA("GuiObject")
			and lastButton.AbsolutePosition.X + lastButton.AbsoluteSize.X + width + 16
				<= gui.AbsoluteSize.X
		local right = if not hasSideRoom and gui.AbsoluteSize.Y < 305
			then math.max(84, math.floor(gui.AbsoluteSize.X * 0.17))
			else 12
		local height = math.clamp(math.round(gui.AbsoluteSize.Y * 0.148), 50, 132)
		local iconSize = math.floor(math.min(height * 0.83, width * 0.34))
		card.Size = UDim2.fromOffset(width, height)
		card.Position = UDim2.new(1, -right, 0, if hasSideRoom then 6 else Hud.navBottom() + 68)
		chest.Size = UDim2.fromOffset(iconSize, iconSize)
		chest.Position = UDim2.new(0, 7, 0.5, -iconSize / 2)
		for _, label in card:GetChildren() do
			if label:IsA("TextLabel") then
				label.Size = UDim2.new(1, -(iconSize + 18), 0.36, 0)
				label.Position =
					UDim2.new(0, iconSize + 11, if label.Name == "GiftTitle" then 0.12 else 0.52, 0)
			end
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	local resize = Hud.layoutChanged:Connect(place)
	gui.Destroying:Once(function()
		resize:Disconnect()
	end)

	local heading = Wood.caption(card, "GiftTitle", string.format(Text.dailyGift, gift.days), 26)
	heading.Size = UDim2.new(1, -64, 0, 21)
	heading.Position = UDim2.fromOffset(57, 8)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	local amount = Wood.caption(
		card,
		"GiftAmount",
		string.format(Text.dailyCoins, gift.lastGift),
		30,
		Theme.gold
	)
	amount.Size = UDim2.new(1, -64, 0, 25)
	amount.Position = UDim2.fromOffset(57, 31)
	amount.TextXAlignment = Enum.TextXAlignment.Left

	card.Parent = gui
	gui.Parent = playerGui
	place()

	local connection = Hud.panelChanged:Connect(function(panel: string)
		if panel ~= "" then
			gui:Destroy()
		end
	end)
	local fishing = playerGui:FindFirstChild("FishingUI")
	local minigame = fishing and fishing:FindFirstChild("Panel")
	local mode = if minigame and minigame:IsA("GuiObject")
		then minigame:GetPropertyChangedSignal("Visible"):Connect(function()
			if minigame.Visible then
				gui:Destroy()
			end
		end)
		else nil
	gui.Destroying:Once(function()
		connection:Disconnect()
		if mode then
			mode:Disconnect()
		end
	end)
	RunService.RenderStepped:Wait()
	if gui.Parent then
		Juice.flyCoins(gift.lastGift, chest.AbsolutePosition + chest.AbsoluteSize / 2)
	end
	task.delay(9.5, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

local function waitForTodaysGift(): Types.Daily
	local today = math.floor(workspace:GetServerTimeNow() / 86400)
	local snapshot = Data.waitLoaded()
	-- The profile can arrive before Progress grants today's gift and sends its update.
	while not snapshot.daily or snapshot.daily.lastDay ~= today do
		Data.changed:Wait()
		snapshot = Data.get() or snapshot
	end
	return snapshot.daily
end

function DailyGift.start()
	local daily = waitForTodaysGift()
	local age = workspace:GetServerTimeNow() - daily.grantedAt
	if daily.days < 1 or daily.lastGift < 1 or age < -2 or age >= 120 then
		return
	end

	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local function busy(): boolean
		local fishing = playerGui:FindFirstChild("FishingUI")
		local minigame = fishing and fishing:FindFirstChild("Panel")
		local training = player:GetAttribute("TrainingStat")
		-- Arrival stays mounted through the title and the optional panorama.
		return playerGui:FindFirstChild("IslandArrival") ~= nil
			or Hud.panel() ~= ""
			or player:GetAttribute("CatchRevealActive") == true
			or (typeof(training) == "string" and training ~= "")
			or (minigame ~= nil and minigame:IsA("GuiObject") and minigame.Visible)
	end
	while busy() do
		task.wait(0.2)
	end
	show(playerGui, daily)
end

return DailyGift
