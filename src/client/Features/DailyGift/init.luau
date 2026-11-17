--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Types = require(Shared:WaitForChild("Types"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Assets = require(script.Parent.Hud:WaitForChild("Assets"))
local Motion = require(script.Parent.Hud:WaitForChild("Motion"))
local Juice = require(script.Parent:WaitForChild("Juice"))

local DailyGift = { order = 130 }
local player = Players.LocalPlayer

local function show(playerGui: PlayerGui, gift: Types.Daily, busy: () -> boolean)
	local gui = Instance.new("ScreenGui")
	gui.Name = "DailyGift"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 6
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local card = Art.button(Assets.gift)
	card.Name = "GiftCard"
	card.AnchorPoint = Vector2.new(1, 0)
	local heading = Art.caption(card, "GiftTitle", string.format(Text.dailyGift, gift.days), 25)
	heading.Position = UDim2.fromScale(0.43, 0.19)
	heading.Size = UDim2.fromScale(0.51, 0.27)
	local action = Art.caption(card, "GiftAmount", Text.openDailyGift, 24, Theme.gold)
	action.Position = UDim2.fromScale(0.43, 0.51)
	action.Size = UDim2.fromScale(0.51, 0.26)
	local motion = Motion.mount(card, 1.6, 4.5)

	local adventure = playerGui:FindFirstChild("AdventureHud")
	local navigation = adventure and adventure:FindFirstChild("Navigation")
	local lastButton = navigation and navigation:FindFirstChild("Settings")
	local function place()
		local screen = gui.AbsoluteSize
		local width = math.clamp(math.round(screen.X * 0.24), 146, 302)
		local height = math.clamp(math.round(width / 2.45), 54, 120)
		local hasSideRoom = lastButton
			and lastButton:IsA("GuiObject")
			and lastButton.AbsolutePosition.X + lastButton.AbsoluteSize.X + width + 20
				<= screen.X
		local right = if not hasSideRoom and screen.Y < 305
			then math.max(82, math.floor(screen.X * 0.14))
			else 12
		card.Size = UDim2.fromOffset(width, height)
		local goalHeight = math.clamp(math.round(screen.Y * 0.108), 50, 88)
		card.Position =
			UDim2.new(1, -right, 0, if hasSideRoom then 6 else Hud.navBottom() + goalHeight + 15)
	end
	card.Parent = gui
	gui.Parent = playerGui
	place()
	local resize = Hud.layoutChanged:Connect(place)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

	local function refresh()
		card.Visible = not busy()
	end
	local panel = Hud.panelChanged:Connect(refresh)
	local reveal = player:GetAttributeChangedSignal("CatchRevealActive"):Connect(refresh)
	local training = player:GetAttributeChangedSignal("TrainingStat"):Connect(refresh)
	local fishing = playerGui:WaitForChild("FishingUI")
	local minigame = fishing:WaitForChild("Panel") :: GuiObject
	local mode = minigame:GetPropertyChangedSignal("Visible"):Connect(refresh)
	gui.Destroying:Once(function()
		for _, connection in { resize, panel, reveal, training, mode } do
			connection:Disconnect()
		end
	end)
	refresh()

	local opened = false
	card.Activated:Connect(function()
		if opened or busy() then
			return
		end
		opened = true
		card.Interactable = false
		motion.finishIdle()
		action.Text = string.format(Text.dailyCoins, gift.lastGift)
		Juice.flyCoins(
			gift.lastGift,
			card.AbsolutePosition + card.AbsoluteSize * Vector2.new(0.23, 0.5)
		)
		task.delay(6, function()
			if gui.Parent then
				gui:Destroy()
			end
		end)
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
		-- The gift waits until the island panorama clears.
		return playerGui:FindFirstChild("IslandArrival") ~= nil
			or Hud.panel() ~= ""
			or player:GetAttribute("CatchRevealActive") == true
			or (typeof(training) == "string" and training ~= "")
			or (minigame ~= nil and minigame:IsA("GuiObject") and minigame.Visible)
	end
	while busy() do
		task.wait(0.2)
	end
	show(playerGui, daily, busy)
end

return DailyGift
