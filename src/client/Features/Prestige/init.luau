--!strict
-- Prestige ("Maré Nova") client screen in the QuickMenu ("Mais").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local PrestigeConfig = require(Shared:WaitForChild("Config"):WaitForChild("Prestige"))
local Labels = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Types = require(Shared:WaitForChild("Types"))

local Features = script.Parent
local Client = Features.Parent
local Data = require(Client:WaitForChild("Data"))
local Hud = require(Features:WaitForChild("Hud"))
local Panel = require(Features:WaitForChild("Hud"):WaitForChild("Panel"))

local Screen = {}

local function formatNumber(n: number): string
	return Theme.formatInt(math.floor(n))
end

local function makeBar(parent: Instance, order: number, variant: string): (TextLabel, Frame)
	local wrap = Instance.new("Frame")
	wrap.Name = "Requirement_" .. tostring(order)
	wrap.LayoutOrder = order
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.new(1, 0, 0, 44)
	wrap.Parent = parent

	local caption = Panel.label(wrap, "", 15, Theme.ink)
	caption.Name = "Caption"
	caption.Position = UDim2.fromOffset(0, 0)
	caption.Size = UDim2.new(1, 0, 0, 22)
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.TextStrokeTransparency = 1

	local track, fill = Panel.progressBar(wrap, variant, 14)
	track.Name = "Track"
	track.Position = UDim2.fromOffset(0, 26)
	track.Size = UDim2.new(1, 0, 0, 14)

	return caption, fill
end

local function paddedCard(parent: Instance, accent: Color3, order: number, height: number): Frame
	local card = Panel.card(parent, accent, height)
	card.LayoutOrder = order
	card.AutomaticSize = Enum.AutomaticSize.Y
	-- Put UIListLayout inside an inner frame so Panel.card's CardShadow stays anchored at bottom.
	local inner = Instance.new("Frame")
	inner.Name = "Content"
	inner.BackgroundTransparency = 1
	inner.Size = UDim2.fromScale(1, 0)
	inner.AutomaticSize = Enum.AutomaticSize.Y
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = inner
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = inner
	inner.Parent = card
	return inner
end

local function cardLine(parent: Instance, order: number, size: number, color: Color3): TextLabel
	local lbl = Panel.label(parent, "", size, color)
	lbl.LayoutOrder = order
	lbl.Size = UDim2.new(1, 0, 0, size + 5)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextStrokeTransparency = 1
	return lbl
end

function Screen.start()
	local prestigeAccent = Panel.themeColor("Prestige")
	local gui, body = Panel.create("Prestige", Labels.prestigeUi.title, prestigeAccent)
	Panel.stack(body)

	-- 1. Hero & Bonuses Card
	local heroCard = paddedCard(body, prestigeAccent, 1, 0)
	local levelLabel = cardLine(heroCard, 1, 22, Color3.fromRGB(106, 26, 214))
	local bonusTitle = cardLine(heroCard, 2, 15, Theme.wood)
	bonusTitle.Text = Labels.prestigeUi.bonusesTitle
	local coinsBonusLabel = cardLine(heroCard, 3, 16, Theme.ink)
	local luckBonusLabel = cardLine(heroCard, 4, 16, Theme.ink)
	local nextBonusBox = Instance.new("Frame")
	nextBonusBox.Name = "NextBonusCallout"
	nextBonusBox.LayoutOrder = 5
	nextBonusBox.Size = UDim2.new(1, 0, 0, 32)
	nextBonusBox.AutomaticSize = Enum.AutomaticSize.Y
	nextBonusBox.BackgroundColor3 = Color3.fromRGB(224, 246, 255)
	nextBonusBox.BorderSizePixel = 0
	Theme.corner(nextBonusBox, 10)
	local nextStroke = Instance.new("UIStroke")
	nextStroke.Color = Color3.fromRGB(58, 174, 214)
	nextStroke.Thickness = 2
	nextStroke.Parent = nextBonusBox
	local nextPad = Instance.new("UIPadding")
	nextPad.PaddingTop = UDim.new(0, 6)
	nextPad.PaddingBottom = UDim.new(0, 6)
	nextPad.PaddingLeft = UDim.new(0, 10)
	nextPad.PaddingRight = UDim.new(0, 10)
	nextPad.Parent = nextBonusBox
	nextBonusBox.Parent = heroCard
	local nextBonusLabel = cardLine(nextBonusBox, 1, 15, Color3.fromRGB(14, 86, 124))

	-- 2. Requirements Card
	local reqCard = paddedCard(body, Theme.crystal, 2, 0)
	local reqTitle = cardLine(reqCard, 1, 17, Theme.ink)
	reqTitle.Text = Labels.prestigeUi.reqTitle
	local coinsCaption, coinsFill = makeBar(reqCard, 2, "gold")
	local speciesCaption, speciesFill = makeBar(reqCard, 3, "cyan")

	-- 3. Reset vs Keep Card
	local infoCard = paddedCard(body, Theme.gold, 3, 0)
	local infoTitle = cardLine(infoCard, 1, 17, Theme.ink)
	infoTitle.Text = Labels.prestigeUi.summaryTitle
	local resetsLabel = cardLine(infoCard, 2, 15, Color3.fromRGB(154, 26, 44))
	resetsLabel.Size = UDim2.new(1, 0, 0, 24)
	resetsLabel.Text = Labels.prestigeUi.resets
	local keepsLabel = cardLine(infoCard, 3, 15, Color3.fromRGB(16, 108, 66))
	keepsLabel.Size = UDim2.new(1, 0, 0, 24)
	keepsLabel.Text = Labels.prestigeUi.keeps

	-- 4. Two-step Confirm Action Button
	local action = Panel.button(body, Labels.prestigeUi.locked, Theme.rose)
	action.Name = "PrestigeAction"
	action.LayoutOrder = 4
	action.Size = UDim2.new(1, 0, 0, 52)

	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local armed = false
	local armToken = 0
	local busy = false

	local function updateButton(snapshot: Types.Snapshot?)
		if not snapshot then
			action.Text = Labels.loading
			action.Active = false
			Panel.tintButton(action, Color3.fromRGB(165, 175, 190))
			return
		end

		local level = math.clamp(math.floor(snapshot.prestige or 0), 0, PrestigeConfig.MAX_LEVEL)
		local coins = snapshot.coins or 0
		local species = PrestigeConfig.speciesCount(snapshot.collection)

		if level >= PrestigeConfig.MAX_LEVEL then
			action.Text = Labels.prestigeUi.maxLevel
			action.Active = false
			Panel.tintButton(action, Theme.gold)
		elseif not PrestigeConfig.canPrestige(level, coins, species) then
			action.Text = Labels.prestigeUi.locked
			action.Active = false
			Panel.tintButton(action, Color3.fromRGB(165, 175, 190))
		elseif armed then
			action.Text = Labels.prestigeUi.confirm
			action.Active = true
			Panel.tintButton(action, Color3.fromRGB(235, 92, 66))
		else
			local gift = PrestigeConfig.giftCoins(level + 1)
			action.Text = string.format(Labels.prestigeUi.button, formatNumber(gift))
			action.Active = true
			Panel.tintButton(action, Theme.rose)
		end
	end

	local function refresh(snapshot: Types.Snapshot?)
		if not gui.Enabled or not snapshot then
			return
		end
		local level = math.clamp(math.floor(snapshot.prestige or 0), 0, PrestigeConfig.MAX_LEVEL)
		local coins = snapshot.coins or 0
		local species = PrestigeConfig.speciesCount(snapshot.collection)

		levelLabel.Text =
			string.format(Labels.prestigeUi.levelBadge, level, PrestigeConfig.MAX_LEVEL)
		coinsBonusLabel.Text = string.format(
			Labels.prestigeUi.bonusCoins,
			math.round(level * PrestigeConfig.COIN_BONUS_PER_LEVEL * 100)
		)
		luckBonusLabel.Text = string.format(
			Labels.prestigeUi.bonusLuck,
			math.round(level * PrestigeConfig.LUCK_BONUS_PER_LEVEL * 100)
		)

		if level < PrestigeConfig.MAX_LEVEL then
			local nextLevel = level + 1
			nextBonusBox.Visible = true
			nextBonusLabel.Text = string.format(
				Labels.prestigeUi.nextBonus,
				math.round(nextLevel * PrestigeConfig.COIN_BONUS_PER_LEVEL * 100),
				math.round(nextLevel * PrestigeConfig.LUCK_BONUS_PER_LEVEL * 100),
				formatNumber(PrestigeConfig.giftCoins(nextLevel))
			)
		else
			nextBonusBox.Visible = false
		end

		coinsCaption.Text = string.format(
			Labels.prestigeUi.reqCoins,
			formatNumber(coins),
			formatNumber(PrestigeConfig.MIN_COINS)
		)
		local coinsRatio = math.clamp(coins / PrestigeConfig.MIN_COINS, 0, 1)
		coinsFill.Size = UDim2.fromScale(coinsRatio, 1)
		coinsFill.BackgroundColor3 = if coinsRatio >= 1
			then Theme.gold
			else Color3.fromRGB(240, 198, 92)

		speciesCaption.Text =
			string.format(Labels.prestigeUi.reqSpecies, species, PrestigeConfig.MIN_SPECIES)
		local speciesRatio = math.clamp(species / PrestigeConfig.MIN_SPECIES, 0, 1)
		speciesFill.Size = UDim2.fromScale(speciesRatio, 1)
		speciesFill.BackgroundColor3 = if speciesRatio >= 1
			then Theme.crystal
			else Color3.fromRGB(120, 196, 224)

		updateButton(snapshot)
	end

	action.Activated:Connect(function()
		local snapshot = Data.get()
		if not snapshot or busy then
			return
		end
		local level = math.clamp(math.floor(snapshot.prestige or 0), 0, PrestigeConfig.MAX_LEVEL)
		local coins = snapshot.coins or 0
		local species = PrestigeConfig.speciesCount(snapshot.collection)
		if not PrestigeConfig.canPrestige(level, coins, species) then
			return
		end

		if not armed then
			armed = true
			armToken += 1
			local token = armToken
			updateButton(snapshot)
			task.delay(4, function()
				if armed and armToken == token then
					armed = false
					updateButton(Data.get())
				end
			end)
			return
		end

		armed = false
		busy = true
		local remote = remotes:FindFirstChild(Net.DO_PRESTIGE)
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer()
		end
		task.delay(1.2, function()
			busy = false
		end)
		updateButton(snapshot)
	end)

	local function watchReward(remote: Instance)
		if remote.Name ~= Net.ADVENTURE_REWARD or not remote:IsA("RemoteEvent") then
			return
		end
		remote.OnClientEvent:Connect(function(reward: Net.AdventureReward)
			if typeof(reward) == "table" and reward.kind == "prestige" then
				busy = false
				armed = false
				Hud.showPanel("")
			end
		end)
	end

	local existing = remotes:FindFirstChild(Net.ADVENTURE_REWARD)
	if existing then
		watchReward(existing)
	end
	remotes.ChildAdded:Connect(watchReward)

	Data.changed:Connect(function(snapshot)
		armed = false
		busy = false
		refresh(snapshot)
	end)

	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		armed = false
		if gui.Enabled then
			refresh(Data.get())
		end
	end)
end

return Screen
