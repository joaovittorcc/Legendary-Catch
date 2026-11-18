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

	local function place()
		-- gift.png is 1024x402; tucked under the menu button on the right, clear of the left column.
		local screen = gui.AbsoluteSize
		local width = math.clamp(math.round(screen.X * 0.16), 120, 200)
		local height = math.round(width * 402 / 1024)
		card.Size = UDim2.fromOffset(width, height)
		card.Position = UDim2.new(0.983, 0, 0, Hud.navBottom() + 12)
	end
	card.Parent = gui
	gui.Parent = playerGui
	place()
	local setCardVisible = Hud.bindFishingVisibility(card, false)
	local resize = Hud.layoutChanged:Connect(place)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

	local function refresh()
		setCardVisible(not busy() and not Hud.isMenuOpen())
	end
	local panel = Hud.panelChanged:Connect(refresh)
	local menu = Hud.menuChanged:Connect(refresh)
	local fishingConnection = Hud.fishingChanged:Connect(refresh)
	local reveal = player:GetAttributeChangedSignal("CatchRevealActive"):Connect(refresh)
	local training = player:GetAttributeChangedSignal("TrainingStat"):Connect(refresh)
	local fishing = playerGui:WaitForChild("FishingUI")
	local minigame = fishing:WaitForChild("Panel") :: GuiObject
	local mode = minigame:GetPropertyChangedSignal("Visible"):Connect(refresh)
	gui.Destroying:Once(function()
		for _, connection in { resize, panel, menu, fishingConnection, reveal, training, mode } do
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
			or Hud.isFishingActive()
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
