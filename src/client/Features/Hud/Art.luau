--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
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
