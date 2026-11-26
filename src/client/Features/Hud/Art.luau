--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local UiAssets = require(Shared:WaitForChild("Ui"):WaitForChild("UiAssets"))
local Assets = require(script.Parent:WaitForChild("Assets"))

local Art = {}

function Art.image(parent: GuiObject, id: string, name: string?): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name = name or "Art"
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.Image = id
	image.ScaleType = Enum.ScaleType.Fit -- safety net: art is never stretched
	image.Parent = parent
	return image
end

function Art.button(id: string): ImageButton
	local button = Instance.new("ImageButton")
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.Image = id
	button.ScaleType = Enum.ScaleType.Fit
	return button
end

-- Renders a glossy 3D cartoon icon from UiAssets (uploaded PNG when available, crisp emoji fallback otherwise).
function Art.icon(
	parent: Instance,
	iconKey: string,
	emojiFallback: string,
	textSize: number?
): GuiObject
	local assetId = UiAssets.iconId(iconKey)
	if assetId then
		local img = Instance.new("ImageLabel")
		img.Name = "IconArt"
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = assetId
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = parent
		return img
	end
	local lbl = Instance.new("TextLabel")
	lbl.Name = "IconGlyph"
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = emojiFallback
	lbl.Font = Theme.font
	lbl.TextSize = textSize or 22
	lbl.TextScaled = true
	lbl.TextColor3 = Theme.ink
	lbl.TextStrokeTransparency = 1
	lbl.Parent = parent
	return lbl
end

-- Native 3D cartoon mini-panel (9-slice panel_body_* when uploaded + glossy golden-trimmed fallback).
function Art.panel(parent: GuiObject, accent: Color3, themeName: string?)
	local theme = if themeName and UiAssets.THEMES[themeName]
		then UiAssets.THEMES[themeName]
		else UiAssets.themeFromColor(accent)

	local bodyArt = Instance.new("ImageLabel")
	bodyArt.Name = "PanelSliceArt"
	bodyArt.Size = UDim2.fromScale(1, 1)
	bodyArt.BackgroundTransparency = 1
	bodyArt.ZIndex = 0
	local hasArt = UiAssets.applySpec(bodyArt, UiAssets.panelBodies[theme.name])
	bodyArt.Parent = parent

	if hasArt then
		parent.BackgroundTransparency = 1
		parent.BorderSizePixel = 0
		return
	end

	-- Lush 3D cartoon candy fallback matching panel_body_*.png
	parent.BackgroundColor3 = Color3.new(1, 1, 1)
	parent.BackgroundTransparency = 0
	parent.BorderSizePixel = 0
	Theme.corner(parent, 22)

	local grad = parent:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.top),
		ColorSequenceKeypoint.new(0.45, theme.mid),
		ColorSequenceKeypoint.new(1, theme.bot),
	})
	grad.Parent = parent

	local stroke = parent:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = UiAssets.OUTLINE
	stroke.Thickness = 4.5
	stroke.Parent = parent

	local shadow = Instance.new("Frame")
	shadow.Name = "SoftShadow"
	shadow.Position = UDim2.fromOffset(0, 6)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.BackgroundColor3 = UiAssets.OUTLINE
	shadow.BackgroundTransparency = 0.62
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 0
	Theme.corner(shadow, 22)
	shadow.Parent = parent

	local topGloss = Instance.new("Frame")
	topGloss.Name = "TopGloss"
	topGloss.Position = UDim2.fromOffset(10, 2)
	topGloss.Size = UDim2.new(1, -20, 0, 4)
	topGloss.BackgroundColor3 = theme.rim
	topGloss.BackgroundTransparency = 0.25
	topGloss.BorderSizePixel = 0
	topGloss.ZIndex = 0
	Theme.corner(topGloss, 4)
	topGloss.Parent = parent

	-- Metallic gold inner molding ring
	local goldTrim = Instance.new("Frame")
	goldTrim.Name = "GoldTrim"
	goldTrim.Position = UDim2.fromOffset(6, 6)
	goldTrim.Size = UDim2.new(1, -12, 1, -12)
	goldTrim.BackgroundColor3 = Color3.new(1, 1, 1)
	goldTrim.BorderSizePixel = 0
	goldTrim.ZIndex = 0
	Theme.corner(goldTrim, 17)
	local goldGrad = Instance.new("UIGradient")
	goldGrad.Rotation = 90
	goldGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UiAssets.GOLD_TOP),
		ColorSequenceKeypoint.new(0.5, UiAssets.GOLD_MID),
		ColorSequenceKeypoint.new(1, UiAssets.GOLD_BOT),
	})
	goldGrad.Parent = goldTrim
	local goldStroke = Instance.new("UIStroke")
	goldStroke.Color = UiAssets.OUTLINE_SOFT
	goldStroke.Thickness = 1.5
	goldStroke.Parent = goldTrim
	goldTrim.Parent = parent

	local fill = Instance.new("Frame")
	fill.Name = "CreamFill"
	fill.Position = UDim2.fromOffset(9, 9)
	fill.Size = UDim2.new(1, -18, 1, -18)
	fill.BackgroundColor3 = UiAssets.CREAM
	fill.BorderSizePixel = 0
	fill.ZIndex = 0
	Theme.corner(fill, 14)
	local fillStroke = Instance.new("UIStroke")
	fillStroke.Color = UiAssets.OUTLINE_SOFT
	fillStroke.Thickness = 1.2
	fillStroke.Transparency = 0.25
	fillStroke.Parent = fill
	fill.Parent = parent
end

function Art.caption(
	parent: GuiObject,
	name: string,
	text: string,
	maxSize: number,
	tint: Color3?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = tint or Theme.sand
	label.TextScaled = true
	label.TextStrokeColor3 = UiAssets.OUTLINE
	label.TextStrokeTransparency = 0.08
	label.Font = Theme.font
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.Parent = label
	label.Parent = parent
	return label
end

local function updateRarityLabel(badge: ImageLabel, label: TextLabel, rarity: string)
	local fallback = Theme.rarityRank(rarity) == 6 and (badge.Image == "" or not badge.IsLoaded)
	local mystic = badge:FindFirstChild("MysticBadge")
	if mystic and mystic:IsA("Frame") then
		mystic.Visible = fallback
	end
	label.Position = if fallback then UDim2.fromScale(0.04, 0.17) else UDim2.fromScale(0.44, 0.17)
	label.Size = if fallback then UDim2.fromScale(0.92, 0.66) else UDim2.fromScale(0.51, 0.66)
	label.Text = Theme.rarityLabel(rarity)
end

function Art.rarity(parent: GuiObject): (ImageLabel, TextLabel)
	local badge = Art.image(parent, "", "RarityBadge")
	local fallback = Instance.new("Frame")
	fallback.Name = "MysticBadge"
	fallback.Size = UDim2.fromScale(1, 1)
	fallback.Visible = false
	Theme.corner(fallback, 12)
	Theme.iridescent(fallback)
	fallback.Parent = badge
	local label = Art.caption(badge, "Rarity", "", 23)
	label.Size = UDim2.fromScale(0.51, 0.66)
	label.Position = UDim2.fromScale(0.44, 0.17)
	return badge, label
end

function Art.setRarity(badge: ImageLabel, label: TextLabel, rarity: string)
	local asset = Assets.rarity[rarity]
	badge:SetAttribute("Rarity", rarity)
	badge.Image = asset or (if Theme.rarityRank(rarity) == 6 then "" else Assets.rarity.Common)
	updateRarityLabel(badge, label, rarity)
	if Theme.rarityRank(rarity) == 6 and asset and not badge.IsLoaded then
		task.spawn(function()
			local deadline = os.clock() + 5
			while badge.Parent and badge:GetAttribute("Rarity") == rarity do
				if badge.IsLoaded or os.clock() >= deadline then
					updateRarityLabel(badge, label, rarity)
					return
				end
				task.wait(0.12)
			end
		end)
	end
end

return Art
