--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Missions = require(Shared:WaitForChild("Config"):WaitForChild("Missions"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Types = require(Shared:WaitForChild("Types"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Assets = require(script.Parent.Hud:WaitForChild("Assets"))
local Motion = require(script.Parent.Hud:WaitForChild("Motion"))
local Juice = require(script.Parent:WaitForChild("Juice"))
local Tutorial = require(script.Parent:WaitForChild("Tutorial"))

local DailyGift = { order = 130 }
local player = Players.LocalPlayer

local activeGui: ScreenGui? = nil

local function makeLabel(
	parent: Instance,
	content: string,
	size: number,
	color: Color3,
	strokeAlpha: number?
): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Text = content
	lbl.Font = Theme.font
	lbl.TextSize = size
	lbl.TextColor3 = color
	lbl.TextStrokeColor3 = Theme.outline
	lbl.TextStrokeTransparency = strokeAlpha or 0.35
	lbl.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = size
	limit.MinTextSize = 13
	limit.Parent = lbl
	lbl.Parent = parent
	return lbl
end

local function showStreakModal(gui: ScreenGui, gift: Types.Daily)
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.IgnoreGuiInset = true
	local reduced = player:GetAttribute("ReduceEffects") == true
	local streak = math.max(1, gift.streak or gift.days or 1)
	local currentSlot = Missions.streakDaySlot(streak)
	local chestBonus = gift.lastChest or 0

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "StreakBackdrop"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Theme.ink
	backdrop.BackgroundTransparency = if reduced then 0.55 else 1
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 20
	backdrop.Parent = gui

	local height = 236
		+ (if gift.shieldProtected then 28 else 0)
		+ (if chestBonus > 0 then 42 else 0)
	local panel = Instance.new("Frame")
	panel.Name = "StreakPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.92, 0, 0, height)
	panel.BackgroundColor3 = Theme.gold
	panel.BorderSizePixel = 0
	panel.ZIndex = 22
	Theme.corner(panel, 24)
	local outline = Instance.new("UIStroke")
	outline.Color = Theme.outline
	outline.Thickness = 5
	outline.Parent = panel
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(290, 210)
	bounds.MaxSize = Vector2.new(620, 340)
	bounds.Parent = panel

	local cream = Instance.new("Frame")
	cream.Name = "Cream"
	cream.Position = UDim2.fromOffset(7, 7)
	cream.Size = UDim2.new(1, -14, 1, -14)
	cream.BackgroundColor3 = Theme.cream
	cream.BorderSizePixel = 0
	cream.ZIndex = 23
	Theme.corner(cream, 18)
	cream.Parent = panel

	local titleText = if streak == 1 and (gift.days or 1) == 1
		then Text.streak.welcome
		else string.format(Text.streak.title, streak)
	local title = makeLabel(cream, titleText, 24, Theme.ink, 1)
	title.Name = "Title"
	title.Position = UDim2.fromOffset(14, 10)
	title.Size = UDim2.new(1, -28, 0, 30)
	title.ZIndex = 24

	local yCursor = 44
	if gift.shieldProtected then
		local shield = makeLabel(cream, Text.streak.shieldSaved, 15, Theme.wood, 1)
		shield.Name = "ShieldBanner"
		shield.Position = UDim2.fromOffset(14, yCursor)
		shield.Size = UDim2.new(1, -28, 0, 22)
		shield.ZIndex = 24
		yCursor += 26
	end

	local row = Instance.new("Frame")
	row.Name = "DaysRow"
	row.Position = UDim2.fromOffset(12, yCursor)
	row.Size = UDim2.new(1, -24, 0, 96)
	row.BackgroundTransparency = 1
	row.ZIndex = 24
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = row
	row.Parent = cream

	local totalDays = Missions.STREAK_DAYS
	for day = 1, totalDays do
		local reward = Missions.STREAK_REWARDS[day] or 100
		local done = day < currentSlot
		local active = day == currentSlot
		local isNext = day == currentSlot + 1
		local isDay7 = day == totalDays

		local cardBg = if active
			then Color3.fromRGB(255, 240, 175)
			elseif done then Color3.fromRGB(220, 248, 225)
			elseif isNext then Color3.fromRGB(225, 244, 255)
			else Color3.fromRGB(242, 236, 224)
		local borderColor = if active
			then Theme.gold
			elseif done then Color3.fromRGB(70, 190, 110)
			elseif isNext then Theme.crystal
			else Theme.muted

		local slot = Instance.new("Frame")
		slot.Name = "Day_" .. tostring(day)
		slot.LayoutOrder = day
		slot.Size = UDim2.new(1 / totalDays, -6, 1, 0)
		slot.BackgroundColor3 = cardBg
		slot.BorderSizePixel = 0
		slot.ZIndex = 25
		Theme.corner(slot, 12)
		local slotStroke = Instance.new("UIStroke")
		slotStroke.Color = borderColor
		slotStroke.Thickness = if active then 3 else 2
		slotStroke.Parent = slot

		local dayLbl = makeLabel(
			slot,
			string.format(Text.streak.dayShort, day),
			14,
			if active then Theme.wood else Theme.ink,
			1
		)
		dayLbl.Position = UDim2.fromOffset(2, 4)
		dayLbl.Size = UDim2.new(1, -4, 0, 18)
		dayLbl.ZIndex = 26

		local iconText = if done or active
			then "✓"
			elseif isDay7 then "🎁"
			elseif isNext then "✨"
			else "◆"
		local iconColor = if done or active
			then Color3.fromRGB(45, 165, 85)
			elseif isNext then Theme.crystal
			else Theme.wood
		local iconLbl = makeLabel(slot, iconText, 24, iconColor, 1)
		iconLbl.Name = "StatusIcon"
		iconLbl.Position = UDim2.fromScale(0, 0.25)
		iconLbl.Size = UDim2.fromScale(1, 0.38)
		iconLbl.ZIndex = 26

		local footerText = if isNext
			then Text.streak.nextBadge .. "\n" .. tostring(reward)
			elseif isDay7 then "🎁 " .. tostring(reward)
			else tostring(reward)
		local amtLbl = makeLabel(slot, footerText, 14, Theme.wood, 1)
		amtLbl.Name = "Reward"
		amtLbl.Position = UDim2.fromScale(0.05, 0.63)
		amtLbl.Size = UDim2.fromScale(0.9, 0.33)
		amtLbl.ZIndex = 26

		if active and not reduced then
			local slotScale = Instance.new("UIScale")
			slotScale.Scale = 0.72
			slotScale.Parent = slot
			iconLbl.Text = if isDay7 then "🎁" else "✦"
			task.delay(0.18, function()
				if slot.Parent then
					iconLbl.Text = "✓"
					TweenService:Create(
						slotScale,
						TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Scale = 1.06 }
					):Play()
				end
			end)
		end

		slot.Parent = row
	end

	yCursor += 104
	if chestBonus > 0 then
		local chestCard = Instance.new("Frame")
		chestCard.Name = "Day7Chest"
		chestCard.Position = UDim2.fromOffset(14, yCursor)
		chestCard.Size = UDim2.new(1, -28, 0, 34)
		chestCard.BackgroundColor3 = Color3.fromRGB(255, 236, 170)
		chestCard.BorderSizePixel = 0
		chestCard.ZIndex = 24
		Theme.corner(chestCard, 12)
		local chestStroke = Instance.new("UIStroke")
		chestStroke.Color = Theme.gold
		chestStroke.Thickness = 2
		chestStroke.Parent = chestCard
		local chestLbl = makeLabel(
			chestCard,
			string.format(Text.streak.chestBonus, chestBonus),
			15,
			Theme.wood,
			1
		)
		chestLbl.Position = UDim2.fromOffset(8, 2)
		chestLbl.Size = UDim2.new(1, -16, 1, -4)
		chestLbl.ZIndex = 25
		chestCard.Parent = cream
		yCursor += 42
	end

	local okBtn = Instance.new("TextButton")
	okBtn.Name = "CollectClose"
	okBtn.AnchorPoint = Vector2.new(0.5, 1)
	okBtn.Position = UDim2.new(0.5, 0, 1, -10)
	okBtn.Size = UDim2.new(0.46, 0, 0, 44)
	okBtn.Text = Text.streak.collectOk
	okBtn.Font = Theme.font
	okBtn.TextSize = 18
	okBtn.TextColor3 = Theme.sand
	okBtn.TextStrokeColor3 = Theme.outline
	okBtn.TextStrokeTransparency = 0.06
	okBtn.AutoButtonColor = false
	okBtn.ZIndex = 25
	Theme.surface(okBtn, Theme.crystal, 14)
	Motion.mount(okBtn)
	okBtn.Parent = cream

	panel.Parent = gui
	if not reduced then
		local panelScale = Instance.new("UIScale")
		panelScale.Scale = 0.86
		panelScale.Parent = panel
		TweenService:Create(backdrop, TweenInfo.new(0.18), { BackgroundTransparency = 0.55 }):Play()
		TweenService:Create(
			panelScale,
			TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
	end

	local closed = false
	local function dismiss()
		if closed then
			return
		end
		closed = true
		if gui.Parent then
			gui:Destroy()
		end
		if activeGui == gui then
			activeGui = nil
		end
	end
	okBtn.Activated:Connect(dismiss)
	backdrop.Activated:Connect(dismiss)
	task.delay(8, dismiss)
end

local function show(playerGui: PlayerGui, gift: Types.Daily, busy: () -> boolean)
	if activeGui and activeGui.Parent then
		activeGui:Destroy()
		activeGui = nil
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "DailyGift"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 9
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	activeGui = gui

	local card = Art.button(Assets.gift)
	card.Name = "GiftCard"
	card.AnchorPoint = Vector2.new(1, 0)
	local streak = math.max(1, gift.streak or gift.days or 1)
	local title = if streak == 1 and gift.days == 1
		then Text.welcomeGift
		else string.format(Text.dailyGift, streak)
	local heading = Art.caption(card, "GiftTitle", title, 25)
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
		local top = if screen.Y > screen.X
			then math.max(Hud.navBottom(), Tutorial.cardBottom())
			else Hud.navBottom()
		card.Position = UDim2.new(0.983, 0, 0, top + 12)
	end
	card.Parent = gui
	gui.Parent = playerGui
	place()
	local setCardVisible = Hud.bindFishingVisibility(card, false)
	local resize = Hud.layoutChanged:Connect(place)
	local tutorialLayout = Tutorial.layoutChanged:Connect(place)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

	local opened = false
	local function refresh()
		if opened then
			setCardVisible(false)
			return
		end
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
		if activeGui == gui then
			activeGui = nil
		end
		for _, connection in
			{ resize, tutorialLayout, panel, menu, fishingConnection, reveal, training, mode }
		do
			connection:Disconnect()
		end
	end)
	refresh()

	card.Activated:Connect(function()
		if opened or busy() then
			return
		end
		opened = true
		card.Interactable = false
		motion.finishIdle()
		local totalCoins = gift.lastGift + (gift.lastChest or 0)
		action.Text = string.format(Text.dailyCoins, totalCoins)
		local reduced = player:GetAttribute("ReduceEffects") == true
		local origin = card.AbsolutePosition + card.AbsoluteSize * Vector2.new(0.23, 0.5)
		Juice.flyCoins(totalCoins, origin)
		Audio.play(if (gift.lastChest or 0) > 0 then "chest" else "coins")
		if not reduced then
			local pop = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
			pop.Parent = card
			TweenService:Create(
				pop,
				TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1.18 }
			):Play()
			task.delay(0.16, function()
				if gui.Parent then
					setCardVisible(false)
					showStreakModal(gui, gift)
				end
			end)
		else
			setCardVisible(false)
			showStreakModal(gui, gift)
		end
	end)
end

function DailyGift.start()
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

	local lastShownKey = ""
	local pendingToken = 0
	local function tryPresent(snapshot: Types.Snapshot?)
		if not snapshot or not snapshot.daily then
			return
		end
		local daily = snapshot.daily
		local today = math.floor(workspace:GetServerTimeNow() / 86400)
		local age = workspace:GetServerTimeNow() - daily.grantedAt
		local key = string.format(
			"%d:%d:%d:%d",
			daily.grantedAt,
			daily.streak or 0,
			daily.days or 0,
			daily.lastChest or 0
		)
		if
			daily.lastDay ~= today
			or key == lastShownKey
			or daily.days < 1
			or daily.lastGift < 1
			or age < -2
			or age >= 120
		then
			return
		end
		pendingToken += 1
		local myToken = pendingToken
		task.spawn(function()
			while busy() do
				if pendingToken ~= myToken then
					return
				end
				task.wait(0.2)
			end
			if pendingToken ~= myToken then
				return
			end
			lastShownKey = key
			show(playerGui, daily, busy)
		end)
	end

	local initial = Data.waitLoaded()
	tryPresent(initial)
	Data.changed:Connect(function(snapshot)
		tryPresent(snapshot)
	end)
end

return DailyGift
