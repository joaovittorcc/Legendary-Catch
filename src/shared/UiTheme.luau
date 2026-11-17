--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fishing =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Fishing"))

local Theme = {
	ink = Color3.fromRGB(21, 16, 36),
	wood = Color3.fromRGB(86, 48, 41),
	sand = Color3.fromRGB(255, 239, 212),
	muted = Color3.fromRGB(207, 188, 201),
	gold = Color3.fromRGB(255, 193, 105),
	crystal = Color3.fromRGB(117, 234, 255),
	rose = Color3.fromRGB(255, 157, 217),
	font = Enum.Font.FredokaOne,
	rarity = Fishing.RARITY_COLORS,
}

function Theme.corner(object: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

function Theme.surface(object: GuiObject, accent: Color3, radius: number, fill: Color3?)
	object.BackgroundColor3 = fill or Theme.wood
	object.BorderSizePixel = 0
	Theme.corner(object, radius)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(123, 102, 123))
	gradient.Rotation = 90
	gradient.Parent = object
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = accent
	stroke.Thickness = 2
	stroke.Parent = object
end

return Theme
