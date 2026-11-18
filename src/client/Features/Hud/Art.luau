--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(shared:WaitForChild("Strings"))
local Theme = require(shared:WaitForChild("UiTheme"))
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

function Art.slice(image: ImageLabel, center: Rect, scale: number)
	image.ScaleType = Enum.ScaleType.Slice
	image.SliceCenter = center
	image.SliceScale = scale
end

function Art.panel(parent: GuiObject, accent: Color3)
	parent.BackgroundColor3 = accent
	parent.BackgroundTransparency = 0
	parent.BorderSizePixel = 0
	Theme.corner(parent, 23)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.outline
	stroke.Thickness = 5
	stroke.Parent = parent
	local shadow = Instance.new("Frame")
	shadow.Name = "SoftShadow"
	shadow.Position = UDim2.fromOffset(0, 7)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.BackgroundColor3 = Theme.outline
	shadow.BackgroundTransparency = 0.58
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 0
	Theme.corner(shadow, 23)
	shadow.Parent = parent
	local fill = Instance.new("Frame")
	fill.Name = "CreamFill"
	fill.Position = UDim2.fromOffset(8, 8)
	fill.Size = UDim2.new(1, -16, 1, -16)
	fill.BackgroundColor3 = Theme.cream
	fill.BorderSizePixel = 0
	fill.ZIndex = 0
	Theme.corner(fill, 17)
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
	label.TextStrokeColor3 = Color3.fromRGB(27, 13, 60)
	label.TextStrokeTransparency = 0.18
	label.Font = Theme.font
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.Parent = label
	label.Parent = parent
	return label
end

function Art.rarity(parent: GuiObject): (ImageLabel, TextLabel)
	local badge = Art.image(parent, "", "RarityBadge")
	local label = Art.caption(badge, "Rarity", "", 23)
	label.Size = UDim2.fromScale(0.51, 0.66)
	label.Position = UDim2.fromScale(0.44, 0.17)
	return badge, label
end

function Art.setRarity(badge: ImageLabel, label: TextLabel, rarity: string)
	badge.Image = Assets.rarity[rarity] or Assets.rarity.Common
	label.Text = Strings.rarity[rarity] or rarity
end

return Art
