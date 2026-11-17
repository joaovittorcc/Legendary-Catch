--!strict
-- Small rewards for the eye (X18, written by Claude while Codex was rate-limited):
--   * coins fly from the middle of the screen into the HUD coin counter, which pulses
--   * a catch streak badge ("x3!") for catches in a row without an escape
-- Respects the "reduce effects" setting. Visual only: nothing here touches game state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local Data = require(script.Parent.Parent:WaitForChild("Data"))

local Juice = { order = 120 }

local player = Players.LocalPlayer
local gui: ScreenGui
local streak = 0
local lastCoins: number? = nil

local function reduceEffects(): boolean
	local snapshot = Data.get()
	return player:GetAttribute("ReduceEffects") == true
		or (
			snapshot ~= nil
			and snapshot.settings ~= nil
			and snapshot.settings.reduceEffects == true
		)
end

local function coinLabel(): GuiObject?
	local hud = player.PlayerGui:FindFirstChild("AdventureHud")
	local coins = hud and hud:FindFirstChild("Coins", true)
	return if coins and coins:IsA("GuiObject") then coins else nil
end

local function pulse(target: GuiObject)
	local scale = target:FindFirstChild("JuicePulse")
	if not scale then
		local s = Instance.new("UIScale")
		s.Name = "JuicePulse"
		s.Parent = target
		scale = s
	end
	local s = scale :: UIScale
	s.Scale = 1.18
	TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

function Juice.flyCoins(amount: number, origin: Vector2?)
	if not gui or reduceEffects() then
		return
	end
	local target = coinLabel()
	if not target then
		return
	end
	local goal = target.AbsolutePosition + target.AbsoluteSize / 2
	local view = gui.AbsoluteSize
	local source = origin or Vector2.new(view.X * 0.5, view.Y * 0.55)
	local count = math.clamp(math.floor(math.log10(math.max(amount, 1)) * 3), 3, 10)
	for i = 1, count do
		local coin = Instance.new("TextLabel")
		coin.Name = "FlyingCoin"
		coin.AnchorPoint = Vector2.new(0.5, 0.5)
		coin.Size = UDim2.fromOffset(26, 26)
		coin.BackgroundTransparency = 1
		coin.Text = "◆"
		coin.TextScaled = true
		coin.Font = Theme.font
		coin.TextColor3 = Theme.gold
		coin.TextStrokeTransparency = 0.3
		local start = source + Vector2.new(math.random(-20, 20), math.random(-12, 12))
		coin.Position = UDim2.fromOffset(start.X, start.Y)
		coin.Parent = gui
		local delay = (i - 1) * 0.05
		local tween = TweenService:Create(
			coin,
			TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, delay),
			{ Position = UDim2.fromOffset(goal.X, goal.Y), TextTransparency = 0.2 }
		)
		tween.Completed:Once(function()
			coin:Destroy()
			pulse(target)
		end)
		tween:Play()
	end
end

local function showStreak(n: number)
	local badge = Instance.new("TextLabel")
	badge.Name = "Streak"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.84, 0.68)
	badge.Size = UDim2.fromScale(0.2, 0.08)
	badge.BackgroundTransparency = 1
	badge.Text = `x{n}!`
	badge.TextScaled = true
	badge.Font = Theme.font
	badge.TextColor3 = Theme.gold
	badge.TextStrokeTransparency = 0
	badge.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0.4
	scale.Parent = badge
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(
		badge,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1),
		{
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			Position = UDim2.fromScale(0.84, 0.62),
		}
	):Play()
	task.delay(1.6, function()
		badge:Destroy()
	end)
end

function Juice.start()
	gui = Instance.new("ScreenGui")
	gui.Name = "Juice"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 11
	local playerGui = player:WaitForChild("PlayerGui")
	gui.Parent = playerGui

	player:GetAttributeChangedSignal("Coins"):Connect(function()
		local coins = player:GetAttribute("Coins")
		if typeof(coins) ~= "number" then
			return
		end
		local previous = lastCoins
		lastCoins = coins
		if previous and coins > previous and not playerGui:FindFirstChild("IslandArrival") then
			Juice.flyCoins(coins - previous)
		end
	end)
	local initial = player:GetAttribute("Coins")
	lastCoins = if typeof(initial) == "number" then initial else nil

	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local update = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent
	update.OnClientEvent:Connect(function(u: Net.FishingUpdate)
		if u.event == "caught" then
			streak += 1
			if streak >= 2 and not reduceEffects() then
				-- Show after the reveal has had its moment.
				task.delay(2.5, showStreak, streak)
			end
		elseif u.event == "escaped" then
			streak = 0
		end
	end)
end

return Juice
