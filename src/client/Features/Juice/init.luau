--!strict
-- Presents rewards and combo state already granted by the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Labels = require(Shared:WaitForChild("StringsUi"))
local Text = Labels.adventure

local Hud = require(script.Parent:WaitForChild("Hud"))
local Ui = require(script.Parent.Fishing:WaitForChild("Ui"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local Juice = { order = 120 }

local player = Players.LocalPlayer
local gui: ScreenGui
local lastCoins: number? = nil

type CoinFlight = {
	image: TextLabel,
	scale: UIScale,
	startPos: Vector2,
	controlPos: Vector2,
	goalPos: Vector2,
	startRot: number,
	startedAt: number,
	duration: number,
	index: number,
	target: GuiObject,
	active: boolean,
}
local coinPool: { CoinFlight } = {}
local coinStep: RBXScriptConnection? = nil

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
	s.Scale = 1.2
	TweenService:Create(s, TweenInfo.new(0.32, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function stopCoinLoop()
	if coinStep then
		coinStep:Disconnect()
		coinStep = nil
	end
end

local function ensureCoinLoop()
	if coinStep then
		return
	end
	coinStep = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local anyActive = false
		for _, slot in coinPool do
			if not slot.active then
				continue
			end
			local elapsed = now - slot.startedAt
			if elapsed < 0 then
				anyActive = true
				continue
			end
			local a = math.min(elapsed / slot.duration, 1)
			-- Ease-in-out cubic along a quadratic Bezier arc for lively scatter -> swoop.
			local t = if a < 0.5 then 2 * a * a else 1 - (-2 * a + 2) ^ 2 / 2
			local inv = 1 - t
			local pos = slot.startPos * (inv * inv)
				+ slot.controlPos * (2 * inv * t)
				+ slot.goalPos * (t * t)
			slot.image.Visible = true
			slot.image.Position = UDim2.fromOffset(pos.X, pos.Y)
			slot.image.Rotation = slot.startRot * (1 - t)
			-- Pop bigger at launch, settle crisply into the counter.
			local pop = 0.65 + math.sin(a * math.pi) * 0.55
			slot.scale.Scale = pop
			if a >= 1 then
				slot.active = false
				slot.image.Visible = false
				slot.scale.Scale = 1
				if
					slot.target.Parent
					and not Ui.reduced()
					and not slot.target:FindFirstChild("MotionScale")
				then
					if slot.index == 1 or slot.index % 3 == 0 then
						pulse(slot.target)
					end
				end
				if slot.index <= 4 then
					Audio.play("hit", 0.07, 1.25 + slot.index * 0.05)
				end
			else
				anyActive = true
			end
		end
		if not anyActive then
			stopCoinLoop()
		end
	end)
end

function Juice.flyCoins(amount: number, origin: Vector2?)
	if not gui or Ui.reduced() then
		return
	end
	local target = coinLabel()
	if not target then
		return
	end
	local inset = gui.AbsolutePosition
	local goal = target.AbsolutePosition + target.AbsoluteSize / 2 - inset
	local view = gui.AbsoluteSize
	local source = if origin then origin - inset else Vector2.new(view.X * 0.5, view.Y * 0.55)
	local count = math.clamp(math.floor(math.log10(math.max(amount, 1)) * 3), 3, 10)
	local now = os.clock()
	local launched = 0
	for i = 1, count do
		local slot = coinPool[i]
		if slot.active then
			continue
		end
		local scatterX = math.random(-56, 56)
		local scatterY = math.random(-36, 26)
		local mid = source:Lerp(goal, 0.38)
		slot.startPos = source + Vector2.new(math.random(-14, 14), math.random(-10, 10))
		slot.controlPos = mid + Vector2.new(scatterX * 1.4, -55 + scatterY)
		slot.goalPos = goal
		slot.startRot = math.random(-70, 70)
		slot.startedAt = now + (i - 1) * 0.045
		slot.duration = 0.52 + math.random() * 0.1
		slot.index = i
		slot.target = target
		slot.active = true
		slot.image.Visible = false
		launched += 1
	end
	if launched > 0 then
		ensureCoinLoop()
	end
end

type Reward = Net.AdventureReward

local function formatNumber(n: number): string
	local s = tostring(math.floor(n))
	return s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
end

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
		Audio.play("level")
	elseif reward.kind == "achievement" and reward.id then
		local copy = Labels.achievements[reward.id]
		if copy then
			Hud.toast(string.format(Labels.achievementUi.notice, copy.name, coins), Theme.ink)
		end
	elseif reward.kind == "prestige" and reward.level then
		local banner = Ui.frame(
			gui,
			"PrestigeBanner",
			UDim2.new(0.84, 0, 0, 102),
			UDim2.fromScale(0.5, 0.42),
			Theme.ink
		)
		banner.AnchorPoint = Vector2.new(0.5, 0.5)
		Theme.surface(banner, Theme.rose, 20, Theme.gold)
		local constraint = Instance.new("UISizeConstraint")
		constraint.MaxSize = Vector2.new(340, 102)
		constraint.Parent = banner
		local title = Ui.label(
			banner,
			"Title",
			UDim2.new(1, -24, 0, 34),
			UDim2.fromOffset(12, 16),
			string.format(Labels.prestigeUi.bannerTitle, reward.level),
			Theme.gold
		)
		title.TextXAlignment = Enum.TextXAlignment.Center
		local sub = Ui.label(
			banner,
			"Gift",
			UDim2.new(1, -24, 0, 28),
			UDim2.fromOffset(12, 54),
			string.format(Text.chestCoins, coins),
			Theme.cream
		)
		sub.TextXAlignment = Enum.TextXAlignment.Center
		Hud.toast(
			string.format(Labels.prestigeUi.toast, reward.level, formatNumber(coins)),
			Theme.gold
		)
		Audio.play("level")
		if coins > 0 then
			Juice.flyCoins(coins)
		end
		if not Ui.reduced() then
			Ui.bounce(banner)
		end
		task.delay(3.0, function()
			if banner.Parent then
				banner:Destroy()
			end
		end)
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
		if not Ui.reduced() then
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
					Audio.play("chest")
				end
			end)
		else
			Audio.play("chest")
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
	for _ = 1, 10 do
		local coin = Instance.new("TextLabel")
		coin.Name = "FlyingCoin"
		coin.AnchorPoint = Vector2.new(0.5, 0.5)
		coin.Size = UDim2.fromOffset(24, 24)
		coin.Font = Theme.font
		coin.Text = "✦"
		coin.TextSize = 16
		coin.TextColor3 = Theme.wood
		Theme.surface(coin, Theme.gold, 12, Theme.gold)
		local scale = Instance.new("UIScale")
		scale.Parent = coin
		coin.Visible = false
		coin.Parent = gui
		local flight: CoinFlight = {
			image = coin,
			scale = scale,
			startPos = Vector2.zero,
			controlPos = Vector2.zero,
			goalPos = Vector2.zero,
			startRot = 0,
			startedAt = 0,
			duration = 0.55,
			index = 1,
			target = coin :: GuiObject,
			active = false,
		}
		table.insert(coinPool, flight)
	end
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(function()
		if Ui.reduced() then
			stopCoinLoop()
			for _, slot in coinPool do
				slot.active = false
				slot.image.Visible = false
				slot.scale.Scale = 1
			end
		end
	end)

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
			local kind = reward.kind
			if
				kind ~= "level"
				and kind ~= "chest"
				and kind ~= "tutorial"
				and kind ~= "achievement"
				and kind ~= "prestige"
			then
				return
			end
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
