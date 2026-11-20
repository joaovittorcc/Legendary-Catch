--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fishing = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Panel = require(script.Parent.Parent.Hud:WaitForChild("Panel"))
local Framing = require(script.Parent:WaitForChild("RevealFraming"))

local RevealCard = {}
local CARD_TWEEN = 0.26
local PREVIEW_FOV = 34
local PREVIEW_SPEED = math.rad(15)

export type CatchInfo = {
	weight: number?,
	value: number?,
	isNew: boolean?,
	variant: string?,
	isRecord: boolean?,
	isGiant: boolean?,
	previousBest: number?,
}

type Row = { label: TextLabel, height: number }
export type Card = {
	preview: (number) -> (),
	close: (boolean) -> (),
}

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
	card.BackgroundColor3 = Theme.cream
	card.BorderSizePixel = 0
	card.AnchorPoint = Vector2.new(0, 0.5)
	Theme.corner(card, 17)
	local outline = Instance.new("UIStroke")
	outline.Color = Theme.outline
	outline.Thickness = 3
	outline.Parent = card

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
	Theme.corner(backdrop, 11)
	gradient.Parent = backdrop
	preview.BackgroundTransparency = 1

	local camera = Instance.new("Camera")
	camera.FieldOfView = PREVIEW_FOV
	camera.Parent = preview
	preview.CurrentCamera = camera
	local world = Instance.new("WorldModel")
	local bounds = Framing.measure(model)
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
		table.insert(rows, { label = label, height = height })
		return label
	end

	row("CreatureName", name, 18, 24)
	local rank = math.max(1, Theme.rarityRank(rarity))
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
	if info and info.weight and info.value then
		row("Reward", string.format(Text.captureReward, info.weight, info.value), 15, 19)
	end
	local badges = {}
	if info then
		if info.isNew then
			table.insert(badges, Text.discovery)
		end
		if info.variant == "Shiny" then
			table.insert(badges, Text.shiny)
		end
		if info.isGiant then
			table.insert(badges, Text.adventure.giant)
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
	row("Lore", if cutoff then string.sub(lore, 1, cutoff - 1) .. "…" else lore, 14, 36)
	if info and info.isRecord and info.previousBest and info.weight then
		row("Record", string.format(Text.newRecord, info.previousBest, info.weight), 14, 19)
	elseif rank >= 4 then
		local odds = Fishing.baseOdds(rarity, #Creatures.ofRarity(rarity))
		if odds > 0 then
			row("Odds", string.format(Strings.odds, tostring(odds)), 14, 18)
		end
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
		local previewHeight = math.max(cardHeight - height - 16, 1)
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
			item.label.Position = UDim2.fromScale(0.035, y / cardHeight)
			item.label.Size = UDim2.fromScale(0.93, item.height / cardHeight)
			y += item.height
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

	local function rotate(elapsed: number)
		local turn = math.rad(-48) + (if reduced then 0 else elapsed * PREVIEW_SPEED)
		local pose = Framing.pose(bounds, Vector3.zero, viewer, turn)
		model:PivotTo(pose)
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
	rotate(0)

	return {
		preview = rotate,
		close = function(instant: boolean)
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
