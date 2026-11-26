--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local UiAssets = require(Shared:WaitForChild("Ui"):WaitForChild("UiAssets"))
local Panel = require(script.Parent.Parent.Hud:WaitForChild("Panel"))
local CreatureMotion = require(script.Parent.Parent:WaitForChild("CreatureMotion"))
local Framing = require(script.Parent:WaitForChild("RevealFraming"))
local Mutation = require(script.Parent.RevealMutation)
local Data = require(script.Parent.Parent.Parent.Data)
local AquariumIncome = require(script.Parent.Parent.Collection.AquariumIncome)

local RevealCard = {}
local CARD_TWEEN = 0.26
local PREVIEW_FOV = 34
local PREVIEW_SPEED = math.rad(15)
local REWARD_FORMAT = Text.captureReward:gsub("%%%.2f", "%%s")
local RECORD_FORMAT = Text.newRecord:gsub("%%%.2f", "%%s")

export type CatchInfo = {
	fromShow: boolean?,
	weight: number?,
	sizeMult: number?,
	mutation: string?,
	odds: number?,
	value: number?,
	isNew: boolean?,
	variant: string?,
	isRecord: boolean?,
	isGiant: boolean?,
	previousBest: number?,
	combo: number?,
	comboBonus: number?,
	comboMilestone: number?,
	rewardCoins: number?,
	potentialCpm: number?,
	variantId: string?,
	newVariant: boolean?,
}

type Row = { label: TextLabel, height: number, pixels: number }
export type Card = {
	preview: (number) -> (),
	close: (boolean) -> (),
}

local function formatOdds(odds: number): string
	local digits = string.format("%.0f", odds)
	local separator = Strings.thousandsSep
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1" .. separator)
	if grouped:sub(-#separator) == separator then
		grouped = grouped:sub(1, -#separator - 1)
	end
	return grouped:reverse()
end

local function formatWeight(weight: number): string
	if weight < 1e3 then
		return (string.format("%.2f", weight):gsub("%.", Strings.decimalSep))
	end
	local millions = math.round(weight / 100) >= 10000
	local short = string.format("%.1f", weight / (if millions then 1e6 else 1e3))
	short = short:gsub("%.0$", ""):gsub("%.", Strings.decimalSep)
	return short .. (if millions then "M" else "K")
end

function RevealCard.action(gui: ScreenGui, name: string, caption: string, tint: Color3): TextButton
	local button = Panel.button(gui, caption, tint)
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 0)
	button.Size = UDim2.fromScale(0.18, 0.12)
	local size = Instance.new("UISizeConstraint")
	size.MinSize = Vector2.new(100, 44)
	size.MaxSize = Vector2.new(125, 52)
	size.Parent = button
	local function layoutAction()
		local canvas = gui.AbsoluteSize
		local besideSkip = name == "TakePhoto" and gui:FindFirstChild("SkipReveal") ~= nil
		if not besideSkip or canvas.X <= 0 or canvas.Y <= 0 then
			button.Position = UDim2.fromScale(0.98, 0.02)
		elseif canvas.X < canvas.Y then
			button.Position = UDim2.fromScale(0.98, 0.02 + 58 / canvas.Y)
		else
			button.Position =
				UDim2.fromScale(0.98 - (math.clamp(canvas.X * 0.18, 100, 125) + 8) / canvas.X, 0.02)
		end
	end
	layoutAction()
	local resized = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutAction)
	button.Destroying:Once(function()
		resized:Disconnect()
	end)
	return button
end

function RevealCard.subjectRegion(viewport: Vector2): Rect
	return if viewport.X < viewport.Y
		then Rect.new(0.07, 0.22, 0.93, 0.51)
		else Rect.new(0.40, 0.22, 0.95, 0.86)
end

function RevealCard.open(
	gui: ScreenGui,
	model: Model,
	id: string,
	name: string,
	rarity: string,
	color: Color3,
	info: CatchInfo?,
	reduced: boolean
): Card
	local card = Instance.new("CanvasGroup")
	card.Name = "RevealCard"
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.BorderSizePixel = 0
	card.AnchorPoint = Vector2.new(0, 0.5)
	Theme.corner(card, 22)

	local rank = math.max(1, Theme.rarityRank(rarity))
	-- Native 9-slice rarity card frame (A.5: Common -> Mythic) with glossy 3D candy fallback!
	local rarityFrameArt = Instance.new("ImageLabel")
	rarityFrameArt.Name = "RarityCardArt"
	rarityFrameArt.Size = UDim2.fromScale(1, 1)
	rarityFrameArt.BackgroundTransparency = 1
	rarityFrameArt.ZIndex = 0
	local hasRarityArt = UiAssets.applySpec(rarityFrameArt, UiAssets.rarityCards[rarity])
	rarityFrameArt.Parent = card

	if hasRarityArt then
		card.BackgroundTransparency = 1
	else
		local outerGrad = Instance.new("UIGradient")
		outerGrad.Rotation = 90
		if rank >= 6 then
			Theme.iridescent(card)
		else
			outerGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, color:Lerp(Color3.new(1, 1, 1), 0.35)),
				ColorSequenceKeypoint.new(0.5, color),
				ColorSequenceKeypoint.new(1, color:Lerp(UiAssets.OUTLINE, 0.32)),
			})
			outerGrad.Parent = card
		end
		local outline = Instance.new("UIStroke")
		outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		outline.Color = UiAssets.OUTLINE
		outline.Thickness = if rank >= 5 then 5 elseif rank >= 3 then 4 else 3.5
		outline.Parent = card

		local innerTrim = Instance.new("Frame")
		innerTrim.Name = "RarityInnerTrim"
		innerTrim.Position = UDim2.fromOffset(6, 6)
		innerTrim.Size = UDim2.new(1, -12, 1, -12)
		innerTrim.BackgroundColor3 = if rank >= 3 then UiAssets.GOLD_MID else UiAssets.CREAM_CARD
		innerTrim.BorderSizePixel = 0
		innerTrim.ZIndex = 0
		Theme.corner(innerTrim, 17)
		if rank >= 3 then
			local gg = Instance.new("UIGradient")
			gg.Rotation = 90
			gg.Color = ColorSequence.new(UiAssets.GOLD_TOP, UiAssets.GOLD_BOT)
			gg.Parent = innerTrim
		end
		innerTrim.Parent = card

		local innerField = Instance.new("Frame")
		innerField.Name = "RarityField"
		local pad = if rank >= 3 then 9 else 7
		innerField.Position = UDim2.fromOffset(pad, pad)
		innerField.Size = UDim2.new(1, -(pad * 2), 1, -(pad * 2))
		innerField.BackgroundColor3 = UiAssets.CREAM_CARD
		innerField.BorderSizePixel = 0
		innerField.ZIndex = 0
		Theme.corner(innerField, 14)
		innerField.Parent = card
	end

	local preview = Instance.new("ViewportFrame")
	preview.Name = "CreaturePreview"
	preview.BackgroundColor3 = Color3.new(1, 1, 1)
	preview.BorderSizePixel = 0
	preview.Ambient = Color3.fromRGB(168, 168, 185)
	preview.LightColor = Color3.fromRGB(255, 246, 227)
	preview.LightDirection = Vector3.new(-1, -0.8, -1)
	Theme.corner(preview, 11)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 34
	gradient.Color = ColorSequence.new(color:Lerp(Theme.cream, 0.76), color:Lerp(Theme.ink, 0.36))
	-- Keep the gradient on a background layer so it doesn't tint the model.
	local backdrop = Instance.new("Frame")
	backdrop.Name = "PreviewBackdrop"
	backdrop.BackgroundColor3 = Color3.new(1, 1, 1)
	backdrop.BorderSizePixel = 0
	backdrop.ClipsDescendants = true
	Theme.corner(backdrop, 11)
	gradient.Parent = backdrop
	preview.BackgroundTransparency = 1

	-- Collectible foil sheen that sweeps diagonally across Rare+ cards.
	local foilGradient: UIGradient? = nil
	if not reduced and rank >= 3 then
		local foil = Instance.new("Frame")
		foil.Name = "FoilSheen"
		foil.Size = UDim2.fromScale(1, 1)
		foil.BackgroundColor3 = Color3.new(1, 1, 1)
		foil.BackgroundTransparency = 0.56
		foil.BorderSizePixel = 0
		foil.ZIndex = 3
		local fg = Instance.new("UIGradient")
		fg.Rotation = 25
		fg.Color = ColorSequence.new(Color3.new(1, 1, 1), color:Lerp(Color3.new(1, 1, 1), 0.65))
		fg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 1),
			NumberSequenceKeypoint.new(0.5, 0.28),
			NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		fg.Offset = Vector2.new(-1.2, 0)
		fg.Parent = foil
		foil.Parent = backdrop
		foilGradient = fg
	end

	local camera = Instance.new("Camera")
	camera.FieldOfView = PREVIEW_FOV
	camera.Parent = preview
	preview.CurrentCamera = camera
	local world = Instance.new("WorldModel")
	local bounds = Framing.measure(model)
	local previewMotion = CreatureMotion.bind(model)
	model.Parent = world
	world.Parent = preview
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectType = Enum.AspectType.FitWithinMaxSize
	aspect.Parent = preview
	preview.Parent = backdrop
	backdrop.Parent = card

	local rows: { Row } = {}
	local function row(key: string, value: string, pixels: number, height: number, tint: Color3?)
		local label = Instance.new("TextLabel")
		label.Name = key
		label.BackgroundTransparency = 1
		label.Font = Theme.font
		label.TextColor3 = tint or Theme.ink
		label.TextSize = pixels
		label.TextWrapped = true
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Text = value
		label.Parent = card
		table.insert(rows, { label = label, height = height, pixels = pixels })
		return label
	end

	row("CreatureName", name, 18, 24)
	local tag = row(
		"Rarity",
		Theme.rarityLabel(rarity) .. "  " .. string.rep("★", rank),
		14,
		21,
		Theme.cream
	)
	tag.BackgroundTransparency = 0
	tag.BackgroundColor3 = Theme.ink:Lerp(color, 0.23)
	Theme.corner(tag, 8)
	local rewardLabel: TextLabel? = nil
	local rewardWeight: string? = nil
	local rewardTarget: number? = nil
	local rewardPopped = false
	local reward = info and (info.rewardCoins or info.value)
	if info and info.weight then
		local weight = formatWeight(info.weight)
		local caption = if reward
			then string.format(REWARD_FORMAT, weight, if reduced then reward else 0)
			else weight .. " kg"
		rewardLabel = row("Reward", caption, 15, 19)
		rewardWeight = weight
		rewardTarget = reward
	end
	if info and info.odds then
		row("Odds", string.format(Strings.odds, formatOdds(info.odds)), 14, 18)
	end
	local mutation = info and info.mutation
	local mutationColor = Mutation.color(mutation)
	local mutationName = mutation and Strings.roulette.card[mutation]
	if mutationColor and mutationName then
		local badge = row(
			"Mutation",
			string.format(Strings.roulette.mutation, mutationName),
			14,
			22,
			Theme.cream
		)
		badge.BackgroundTransparency = 0
		badge.BackgroundColor3 = Theme.ink:Lerp(mutationColor, 0.37)
		Theme.corner(badge, 8)
	end
	local profile = Data.get()
	local aquarium = profile and profile.aquarium
	if info and info.potentialCpm and aquarium and aquarium.status == "ready" then
		row(
			"PotentialIncome",
			string.format(
				Text.aquariumPreview.capturePotential,
				AquariumIncome.rate(info.potentialCpm)
			),
			14,
			19
		)
	end
	local combo = info and info.combo
	if combo and combo >= 2 then
		local bonus = info and info.comboBonus
		local caption = if bonus and bonus > 0
			then string.format(Text.minigames.catchCombo, combo, math.round(bonus * 100))
			else string.format(Text.minigames.catchComboCount, combo)
		local milestone = info and info.comboMilestone ~= nil
		local streak =
			row("FishingCombo", caption, 14, 20, if milestone then Theme.sand else Theme.wood)
		if milestone then
			streak.BackgroundTransparency = 0
			streak.BackgroundColor3 = Theme.ink:Lerp(Theme.gold, 0.22)
			Theme.corner(streak, 7)
		end
	end
	local badges = {}
	if info then
		if info.isNew then
			table.insert(badges, Text.discovery)
		end
		local copy = Text.aquariumPreview
		if info.variantId == "both" then
			table.insert(badges, copy.combined)
		elseif info.variantId == "gold" then
			table.insert(badges, copy.golden)
		elseif info.variant == "Shiny" then
			table.insert(badges, Text.shiny)
		end
		if info.variantId ~= "both" and info.isGiant then
			table.insert(badges, Text.adventure.giant)
		end
		if info.newVariant and info.variantId ~= "base" then
			table.insert(badges, Text.discoveries.newAquariumVariant)
		end
		if info.isRecord and not info.previousBest then
			table.insert(badges, Text.adventure.catchRecord)
		end
	end
	if #badges > 0 then
		row("Discovery", table.concat(badges, " · "), 14, if #badges > 1 then 34 else 18)
	end
	local lore = Strings.creatureLore[id] or Text.revealLore[rarity] or Text.revealLore.Common
	local cutoff = utf8.offset(lore, 91)
	local loreLabel =
		row("Lore", if cutoff then string.sub(lore, 1, cutoff - 1) .. "…" else lore, 14, 36)
	if info and info.isRecord and info.previousBest and info.weight then
		row(
			"Record",
			string.format(RECORD_FORMAT, formatWeight(info.previousBest), formatWeight(info.weight)),
			14,
			19
		)
	end

	local height = 0
	for _, item in rows do
		height += item.height
	end
	local enter: Tween? = nil
	local target = UDim2.fromScale(0.04, 0.49)
	local portrait = false
	local function layout()
		local size = gui.AbsoluteSize
		if size.X <= 1 or size.Y <= 1 then
			return
		end
		portrait = size.Y > size.X
		local width = if portrait then size.X * 0.92 else math.min(size.X * 0.34, 326)
		local compact = size.Y < 420
		local cardHeight = math.min(size.Y * (if portrait then 0.41 else 0.76), height + 185)
		loreLabel.Visible = cardHeight >= height + 56
		local rowsHeight = if loreLabel.Visible then height else height - 36
		local previewMin = math.min(48, cardHeight * 0.2)
		local rowScale = math.min(1, math.max(1, cardHeight - previewMin - 16) / rowsHeight)
		local previewHeight = math.max(cardHeight - rowsHeight * rowScale - 16, 1)
		card.Size = UDim2.fromScale(width / size.X, cardHeight / size.Y)
		target = UDim2.fromScale(
			if portrait then 0.04 else 0.035,
			if portrait then 0.73 elseif compact then 0.58 else 0.49
		)
		if enter then
			enter:Cancel()
			enter = nil
			card.GroupTransparency = 0
		end
		card.Position = target
		backdrop.Size = UDim2.fromScale(0.94, previewHeight / cardHeight)
		backdrop.Position = UDim2.fromScale(0.03, 7 / cardHeight)
		preview.Size = UDim2.fromScale(1, 1)
		aspect.AspectRatio = width * 0.94 / previewHeight
		local y = previewHeight + 9
		for _, item in rows do
			if item.label.Visible then
				item.label.TextSize = math.max(10, math.floor(item.pixels * rowScale))
				item.label.Position = UDim2.fromScale(0.035, y / cardHeight)
				item.label.Size = UDim2.fromScale(0.93, item.height * rowScale / cardHeight)
				y += item.height * rowScale
			end
		end
	end
	card.Parent = gui
	layout()
	if not reduced then
		card.GroupTransparency = 1
		card.Position = target
			+ (if portrait then UDim2.fromScale(0, 0.055) else UDim2.fromScale(-0.05, 0))
		local tween = TweenService:Create(card, TweenInfo.new(CARD_TWEEN, Enum.EasingStyle.Quad), {
			Position = target,
			GroupTransparency = 0,
		})
		enter = tween
		tween:Play()
	end
	local resized = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	local viewer = Vector3.new(0, 0.20, 1)
	local cameraAxes = CFrame.lookAt(Vector3.zero, -viewer)
	local region = Rect.new(0.06, 0.07, 0.94, 0.93)

	local function framePreview(pose: CFrame)
		local viewport = preview.AbsoluteSize
		if viewport.X > 0 and viewport.Y > 0 then
			camera.CFrame = Framing.camera(
				bounds,
				pose,
				cameraAxes,
				Vector3.zero,
				viewport,
				PREVIEW_FOV,
				region,
				1.08
			)
		end
	end

	local function rotate(elapsed: number)
		local turn = math.rad(-48)
			+ (if reduced or previewMotion.static then 0 else elapsed * PREVIEW_SPEED)
		local pose = Framing.pose(bounds, Vector3.zero, viewer, turn)
		model:PivotTo(pose)
		if not reduced then
			CreatureMotion.poseBones(previewMotion, elapsed)
			if foilGradient then
				local cycle = elapsed % 2.6
				if cycle < 0.72 then
					foilGradient.Offset = Vector2.new(-1.1 + (cycle / 0.72) * 2.2, 0)
				else
					foilGradient.Offset = Vector2.new(-1.2, 0)
				end
			end
			if rewardLabel and rewardWeight and rewardTarget and not rewardPopped then
				local progress = math.clamp(elapsed / 0.55, 0, 1)
				local eased = 1 - (1 - progress) * (1 - progress)
				local shown = math.floor(rewardTarget * eased + 0.5)
				rewardLabel.Text = string.format(REWARD_FORMAT, rewardWeight, shown)
				if progress >= 1 then
					rewardPopped = true
					local pop = Instance.new("UIScale")
					pop.Scale = 1.16
					pop.Parent = rewardLabel
					TweenService:Create(
						pop,
						TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Scale = 1 }
					):Play()
				end
			end
		end
		framePreview(pose)
	end

	local previewResized = preview:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		framePreview(model:GetPivot())
	end)
	rotate(0)

	return {
		preview = rotate,
		close = function(instant: boolean)
			previewResized:Disconnect()
			resized:Disconnect()
			if enter then
				enter:Cancel()
			end
			if instant or reduced then
				card:Destroy()
				return
			end
			local tween =
				TweenService:Create(card, TweenInfo.new(CARD_TWEEN, Enum.EasingStyle.Quad), {
					Position = target + (if portrait
						then UDim2.fromScale(0, 0.055)
						else UDim2.fromScale(-0.05, 0)),
					GroupTransparency = 1,
				})
			tween.Completed:Once(function()
				card:Destroy()
			end)
			tween:Play()
		end,
	}
end

return RevealCard
