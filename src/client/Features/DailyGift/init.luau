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
local Panel = require(script.Parent.Hud:WaitForChild("Panel"))
local Juice = require(script.Parent:WaitForChild("Juice"))

local DailyGift = { order = 130 }
local player = Players.LocalPlayer

local function crystalChest(parent: Frame): Frame
	local chest = Instance.new("Frame")
	chest.Name = "CrystalChest"
	chest.Position = UDim2.fromOffset(14, 20)
	chest.Size = UDim2.fromOffset(52, 42)
	Theme.surface(chest, Theme.crystal, 8, Color3.fromRGB(49, 107, 142))
	local lid = Instance.new("Frame")
	lid.Size = UDim2.new(1, 0, 0, 15)
	Theme.surface(lid, Theme.crystal, 5, Color3.fromRGB(70, 140, 162))
	lid.Parent = chest
	local clasp = Instance.new("Frame")
	clasp.AnchorPoint = Vector2.new(0.5, 0.5)
	clasp.Position = UDim2.new(0.5, 0, 0, 18)
	clasp.Size = UDim2.fromOffset(12, 12)
	clasp.Rotation = 45
	Theme.surface(clasp, Theme.sand, 3, Theme.gold)
	clasp.Parent = chest
	chest.Parent = parent
	return chest
end

local function show(playerGui: PlayerGui, gift: Types.Daily)
	local gui = Instance.new("ScreenGui")
	gui.Name = "DailyGift"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local card = Instance.new("Frame")
	card.Name = "GiftCard"
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -14)
	card.Size = UDim2.new(0.62, 0, 0, 78)
	Theme.surface(card, Theme.gold, 14, Theme.ink)
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(248, 78)
	bounds.MaxSize = Vector2.new(334, 78)
	bounds.Parent = card
	local chest = crystalChest(card)

	local heading = Panel.label(card, string.format(Text.dailyGift, gift.days), 17)
	heading.Name = "GiftTitle"
	heading.Size = UDim2.new(1, -86, 0, 23)
	heading.Position = UDim2.fromOffset(80, 12)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	local amount = Panel.label(card, string.format(Text.dailyCoins, gift.lastGift), 23, Theme.gold)
	amount.Name = "GiftAmount"
	amount.Size = UDim2.new(1, -86, 0, 34)
	amount.Position = UDim2.fromOffset(80, 32)
	amount.TextXAlignment = Enum.TextXAlignment.Left

	card.Parent = gui
	gui.Parent = playerGui

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

function DailyGift.start()
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	-- Arrival stays mounted through the title and the optional panorama.
	local arrival = playerGui:FindFirstChild("IslandArrival")
	while arrival and arrival.Parent do
		arrival.AncestryChanged:Wait()
	end
	local function tryShow(snapshot: Types.Snapshot): boolean
		local daily = snapshot.daily
		if not daily or daily.days < 1 or daily.lastGift < 1 then
			return false
		end
		local age = os.time() - daily.grantedAt
		if age < 0 or age >= 120 then
			return false
		end
		task.spawn(function()
			local function busy(): boolean
				local fishing = playerGui:FindFirstChild("FishingUI")
				local minigame = fishing and fishing:FindFirstChild("Panel")
				return Hud.panel() ~= ""
					or player:GetAttribute("CatchRevealActive") == true
					or (minigame ~= nil and minigame:IsA("GuiObject") and minigame.Visible)
			end
			while busy() and os.time() - daily.grantedAt < 120 do
				task.wait(0.2)
			end
			if os.time() - daily.grantedAt < 120 then
				show(playerGui, daily)
			end
		end)
		return true
	end

	local latest = Data.get()
	if latest and tryShow(latest) then
		return
	end
	local connection: RBXScriptConnection
	connection = Data.changed:Connect(function(snapshot)
		if tryShow(snapshot) then
			connection:Disconnect()
		end
	end)
end

return DailyGift
