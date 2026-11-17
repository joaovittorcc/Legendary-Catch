--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fishing = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Strings = require(Shared:WaitForChild("Strings"))

local Theme = {
	ink = Color3.fromRGB(21, 16, 36),
	wood = Color3.fromRGB(86, 48, 41),
	sand = Color3.fromRGB(255, 239, 212),
	muted = Color3.fromRGB(223, 232, 255),
	track = Color3.fromRGB(44, 109, 195),
	viewport = Color3.fromRGB(94, 161, 227),
	gold = Color3.fromRGB(255, 193, 105),
	crystal = Color3.fromRGB(117, 234, 255),
	rose = Color3.fromRGB(255, 157, 217),
	font = Enum.Font.FredokaOne,
	rarity = Fishing.RARITY_COLORS,
}

function Theme.rarityRank(rarity: string): number
	return table.find(Fishing.RARITY_ORDER, rarity) or 0
end

function Theme.rarityLabel(rarity: string): string
	local name = Strings.rarity[rarity] or rarity
	local rank = Theme.rarityRank(rarity)
	return if rank > 0 then string.rep("★", rank) .. "  " .. name else name
end

function Theme.corner(object: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
end

function Theme.surface(object: GuiObject, accent: Color3, radius: number, fill: Color3?)
	local hue = select(1, accent:ToHSV())
	local top = fill or Color3.fromHSV(hue, 0.58, 0.95)
	local bottom = if fill
		then fill:Lerp(Color3.fromRGB(69, 44, 137), 0.24)
		else Color3.fromHSV(hue, 0.83, 0.78)
	object.BackgroundColor3 = if object:IsA("TextButton") or object:IsA("TextLabel")
		then top
		else Color3.new(1, 1, 1)
	object.BorderSizePixel = 0
	Theme.corner(object, math.max(radius, 18))
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, top:Lerp(Color3.new(1, 1, 1), 0.22)),
		ColorSequenceKeypoint.new(0.15, top),
		ColorSequenceKeypoint.new(1, bottom),
	})
	gradient.Rotation = 90
	if not object:IsA("TextButton") and not object:IsA("TextLabel") then
		gradient.Parent = object
	else
		gradient:Destroy()
	end
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(55, 31, 108)
	stroke.Thickness = 3
	stroke.Parent = object
end

return Theme
