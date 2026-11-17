--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Types = require(Shared:WaitForChild("Types"))
local Missions = require(Shared:WaitForChild("Config"):WaitForChild("Missions"))
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
	local function place()
		local width = math.clamp(gui.AbsoluteSize.X * 0.36, 182, 248)
		local hasSideRoom = navigation
			and navigation:IsA("GuiObject")
			and navigation.AbsolutePosition.X + navigation.AbsoluteSize.X + width + 23
				<= gui.AbsoluteSize.X
		card.Size = UDim2.fromOffset(width, 66)
		card.Position = UDim2.new(1, -12, 0, if hasSideRoom then 6 else 135)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

	local heading = Wood.caption(card, "GiftTitle", string.format(Text.dailyGift, gift.days), 16)
	heading.Size = UDim2.new(1, -64, 0, 21)
	heading.Position = UDim2.fromOffset(57, 8)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	local amount = Wood.caption(
		card,
		"GiftAmount",
		string.format(Text.dailyCoins, gift.lastGift),
		20,
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
	task.delay(5.5, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

local function waitForTodaysGift(): Types.Daily
	local today = Missions.today()
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
	local age = os.time() - daily.grantedAt
	if daily.days < 1 or daily.lastGift < 1 or age < 0 or age >= 120 then
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
