--!strict
local Panel = require(script.Parent.Parent.Hud.Panel)

local Candy = {}

Candy.ink = Color3.fromRGB(13, 34, 70)
Candy.pearl = Color3.fromRGB(255, 247, 228)
Candy.cyan = Color3.fromRGB(28, 213, 239)
Candy.cobalt = Color3.fromRGB(51, 101, 227)
Candy.violet = Color3.fromRGB(142, 79, 229)
Candy.coral = Color3.fromRGB(211, 41, 112)
Candy.gold = Color3.fromRGB(255, 200, 50)
Candy.muted = Color3.fromRGB(178, 190, 216)

local function darkText(tone: Color3): boolean
	return tone == Candy.cyan or tone == Candy.gold or tone == Candy.pearl or tone == Candy.muted
end

local function glaze(object: GuiObject, tone: Color3)
	local gradient = object:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	local bright = tone:Lerp(Color3.new(1, 1, 1), if darkText(tone) then 0.21 else 0.12)
	local shade = tone:Lerp(Candy.ink, if tone == Candy.pearl then 0.02 else 0.25)
	object.BackgroundColor3 = Color3.new(1, 1, 1)
	gradient.Color = ColorSequence.new(bright, shade)
	gradient.Rotation = 90
	gradient.Parent = object
end

function Candy.button(parent: Instance, caption: string, tone: Color3): TextButton
	local button = Panel.button(parent, caption, tone)
	button.TextColor3 = Color3.fromRGB(255, 253, 240)
	button.TextStrokeTransparency = 0.06
	return button
end

function Candy.card(parent: Instance, tone: Color3, height: number): Frame
	local card = Panel.card(parent, tone, height)
	if tone ~= Candy.pearl then
		local cardArt = card:FindFirstChild("CardArt")
		if not (cardArt and cardArt:IsA("ImageLabel") and cardArt.Visible) then
			glaze(card, tone)
		end
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = tone:Lerp(Candy.ink, 0.50)
		end
	end
	return card
end

function Candy.metric(parent: Instance, caption: string, value: string, tone: Color3): TextLabel
	local card = Candy.card(parent, tone, 63)
	local color = if darkText(tone) then Candy.ink else Candy.pearl
	local name = Panel.label(card, caption, 13, color)
	name.TextStrokeTransparency = 1
	name.Size = UDim2.new(1, -16, 0, 23)
	name.Position = UDim2.fromOffset(8, 4)
	local number = Panel.label(card, value, 20, color)
	number.TextStrokeTransparency = 1
	number.Size = UDim2.new(1, -16, 0, 30)
	number.Position = UDim2.fromOffset(8, 26)
	number.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 11
	limit.MaxTextSize = 20
	limit.Parent = number
	return number
end

function Candy.row(parent: Instance, height: number, columns: number, gap: number): Frame
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, height)
	local grid = Instance.new("UIGridLayout")
	grid.FillDirectionMaxCells = columns
	grid.CellSize = UDim2.new(1 / columns, -gap * (columns - 1) / columns - 1, 1, 0)
	grid.CellPadding = UDim2.fromOffset(gap, 0)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = row
	row.Parent = parent
	return row
end

function Candy.styleShell(gui: ScreenGui, heading: TextLabel)
	local shell = gui:FindFirstChild("CandyPanel")
	if not shell or not shell:IsA("Frame") then
		return
	end
	local bounds = shell:FindFirstChildOfClass("UISizeConstraint")
	if bounds then
		bounds.MaxSize = Vector2.new(1000, bounds.MaxSize.Y)
	end
	heading.TextStrokeTransparency = 0
end

return Candy
