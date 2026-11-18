--!strict
-- Presents rewards and combo state already granted by the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi")).adventure

local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Ui = require(script.Parent.Fishing:WaitForChild("Ui"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local Juice = { order = 120 }

local player = Players.LocalPlayer
local gui: ScreenGui
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
			if
				target.Parent
				and not reduceEffects()
				and not target:FindFirstChild("MotionScale")
			then
				pulse(target)
			end
		end)
		tween:Play()
	end
end

type Reward = Net.AdventureReward

local function showReward(reward: Reward)
	local coins = reward.coins or 0
	if reward.kind == "tutorial" and coins > 0 then
		Hud.toast(string.format(Text.tutorialReward, coins), Theme.gold)
	elseif reward.kind == "level" and reward.level then
		local title = string.format(Text.levelUp, reward.level)
		if coins > 0 then
			title ..= " · " .. string.format(Text.chestCoins, coins)
		end
		Hud.toast(title, Theme.gold)
		Audio.play("level", 0.26, 1)
	elseif reward.kind == "chest" and coins > 0 then
		local card = Ui.frame(
			gui,
			"CatchChest",
			UDim2.new(0.76, 0, 0, 92),
			UDim2.fromScale(0.5, 0.52),
			Theme.ink
		)
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		Theme.surface(card, Theme.gold, 19, Theme.ink)
		local size = Instance.new("UISizeConstraint")
		size.MaxSize = Vector2.new(300, 92)
		size.Parent = card
		local icon = Ui.frame(
			card,
			"Chest",
			UDim2.fromOffset(44, 42),
			UDim2.fromScale(0.15, 0.5),
			Theme.ink,
			1
		)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		local box =
			Ui.frame(icon, "Box", UDim2.fromScale(1, 0.55), UDim2.fromScale(0, 0.45), Theme.gold)
		Theme.surface(box, Theme.gold, 6, Theme.wood)
		local lid =
			Ui.frame(icon, "Lid", UDim2.fromScale(1, 0.38), UDim2.fromScale(0, 0.51), Theme.gold)
		lid.AnchorPoint = Vector2.new(0, 1)
		lid.ZIndex = 2
		Theme.surface(lid, Theme.gold, 6, Theme.wood)
		local clasp = Ui.frame(
			box,
			"Clasp",
			UDim2.fromOffset(10, 10),
			UDim2.fromScale(0.5, 0.33),
			Theme.crystal
		)
		clasp.AnchorPoint = Vector2.new(0.5, 0.5)
		clasp.Rotation = 45
		clasp.ZIndex = 3
		Ui.corner(clasp, 0.24)
		Ui.label(
			card,
			"Title",
			UDim2.fromScale(0.69, 0.28),
			UDim2.fromScale(0.26, 0.18),
			Text.chest,
			Theme.sand
		)
		local amount = Ui.label(
			card,
			"Amount",
			UDim2.fromScale(0.69, 0.29),
			UDim2.fromScale(0.26, 0.51),
			string.format(Text.chestCoins, coins),
			Theme.gold
		)
		if not reduceEffects() then
			amount.Visible = false
			Ui.bounce(card)
			task.delay(0.36, function()
				if card.Parent then
					TweenService:Create(lid, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
						Rotation = -19,
						Position = UDim2.fromScale(0, 0.33),
					}):Play()
					amount.Visible = true
					Ui.bounce(amount)
					Audio.play("coins", 0.3, 1.15)
					Juice.flyCoins(coins, icon.AbsolutePosition + icon.AbsoluteSize / 2)
				end
			end)
		end
		task.delay(2.4, function()
			card:Destroy()
		end)
	end
end

function Juice.start()
	gui = Instance.new("ScreenGui")
	gui.Name = "Juice"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 11
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
	local queue: { Reward } = {}
	local showing = false
	local function watch(remote: Instance)
		if remote.Name ~= Net.ADVENTURE_REWARD or not remote:IsA("RemoteEvent") then
			return
		end
		remote.OnClientEvent:Connect(function(reward: Reward)
			local last = queue[#queue]
			if last and last.kind == "level" and reward.kind == "level" then
				queue[#queue] = {
					kind = "level",
					level = reward.level,
					coins = (last.coins or 0) + (reward.coins or 0),
				}
			else
				table.insert(queue, reward)
			end
			if showing then
				return
			end
			showing = true
			while #queue > 0 do
				repeat
					task.wait(0.2)
				until not Hud.isFishingActive()
					and Hud.panel() == ""
					and player:GetAttribute("CatchRevealActive") ~= true
				local nextReward = table.remove(queue, 1)
				if nextReward then
					showReward(nextReward)
					task.wait(2.5)
				end
			end
			showing = false
		end)
	end
	local existing = remotes:FindFirstChild(Net.ADVENTURE_REWARD)
	if existing then
		watch(existing)
	end
	remotes.ChildAdded:Connect(watch)
end

return Juice
