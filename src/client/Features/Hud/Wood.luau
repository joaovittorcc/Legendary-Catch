--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UiTheme"))

local Wood = {}
local brass = Color3.fromRGB(230, 156, 63)
local dark = Color3.fromRGB(73, 35, 17)
local plank = Color3.fromRGB(117, 63, 33)
local paper = Color3.fromRGB(255, 220, 151)
local cyan = Color3.fromRGB(58, 215, 237)
local steel = Color3.fromRGB(167, 201, 223)

local function piece(
	parent: GuiObject,
	position: UDim2,
	size: UDim2,
	color: Color3,
	round: number?,
	rotation: number?
): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Position = position
	frame.Size = size
	frame.Rotation = rotation or 0
	if round then
		Theme.corner(frame, round)
	end
	frame.Parent = parent
	return frame
end

local function gradient(parent: GuiObject, top: Color3, bottom: Color3, rotation: number)
	local shader = Instance.new("UIGradient")
	shader.Color = ColorSequence.new(top, bottom)
	shader.Rotation = rotation
	shader.Parent = parent
end

local function stroke(parent: GuiObject, color: Color3, thickness: number): UIStroke
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = color
	edge.Thickness = thickness
	edge.Parent = parent
	return edge
end

local function crystal(parent: GuiObject, position: UDim2, size: number): Frame
	local gem = piece(parent, position, UDim2.fromOffset(size, size), Color3.new(1, 1, 1), 1, 45)
	gem.AnchorPoint = Vector2.new(0.5, 0.5)
	gradient(gem, Color3.fromRGB(182, 254, 255), Color3.fromRGB(2, 153, 205), 36)
	stroke(gem, Color3.fromRGB(10, 84, 110), 1)
	local facet = piece(gem, UDim2.fromScale(0.1, 0.1), UDim2.fromScale(0.75, 0.26), Theme.crystal)
	facet.BackgroundTransparency = 0.25
	return gem
end

-- The face is separate so the trim and grain never tint the text on TextLabels or TextButtons.
function Wood.mount(target: GuiObject, gems: boolean?, insetColor: Color3?): UIStroke
	target.Active = target:IsA("GuiButton")
	target.BackgroundTransparency = 1
	if target:IsA("GuiButton") then
		target.AutoButtonColor = false
	end
	local backing =
		piece(target, UDim2.fromOffset(0, 4), UDim2.fromScale(1, 1), Color3.fromRGB(34, 17, 12), 13)
	backing.Name = "WoodBacking"
	local face =
		piece(backing, UDim2.fromOffset(3, -4), UDim2.new(1, -6, 1, -1), Color3.new(1, 1, 1), 13)
	face.Name = "WoodFace"
	gradient(
		face,
		insetColor or plank,
		if insetColor then insetColor:Lerp(dark, 0.55) else dark,
		90
	)
	local trim = stroke(face, brass, 2)
	local inner =
		piece(face, UDim2.fromScale(0.031, 0.065), UDim2.fromScale(0.938, 0.87), paper, 11)
	inner.BackgroundTransparency = 1
	stroke(inner, Color3.fromRGB(155, 91, 39), 1.5)
	for i = 1, 7 do
		local shift = i % 3
		local grain = piece(
			face,
			UDim2.fromScale(0.06 + shift * 0.055, 0.07 + i * 0.116),
			UDim2.new(0.82 - shift * 0.11, 0, 0, 1),
			paper,
			1
		)
		grain.BackgroundTransparency = if i % 2 == 0 then 0.89 else 0.93
	end

	local rivets: { Frame } = {}
	for _, x in { 8, -8 } do
		for _, y in { 8, -8 } do
			local pin = piece(
				face,
				UDim2.new(if x > 0 then 0 else 1, x, if y > 0 then 0 else 1, y),
				UDim2.fromOffset(4, 4),
				brass,
				1,
				45
			)
			pin.AnchorPoint = Vector2.new(0.5, 0.5)
			stroke(pin, paper, 1)
			table.insert(rivets, pin)
		end
	end
	local left = if gems then crystal(face, UDim2.new(0, 2, 0.5, 0), 10) else nil
	local right = if gems then crystal(face, UDim2.new(1, -2, 0.5, 0), 10) else nil
	local function resize()
		local height = target.AbsoluteSize.Y
		trim.Thickness = math.clamp(math.round(height * 0.047), 2, 7)
		local pin = math.clamp(math.round(height * 0.07), 4, 9)
		for _, rivet in rivets do
			rivet.Size = UDim2.fromOffset(pin, pin)
		end
		if left and right then
			local gem = math.clamp(math.round(height * 0.19), 8, 29)
			left.Size = UDim2.fromOffset(gem, gem)
			right.Size = left.Size
		end
	end
	target:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
	return trim
end

local function book(root: Frame)
	piece(root, UDim2.fromScale(0.08, 0.2), UDim2.fromScale(0.84, 0.68), dark, 3)
	for i = 0, 1 do
		local page = piece(
			root,
			UDim2.fromScale(0.11 + i * 0.4, 0.17),
			UDim2.fromScale(0.39, 0.6),
			paper,
			3,
			if i == 0 then -9 else 9
		)
		for y = 1, 3 do
			piece(page, UDim2.fromScale(0.17, y * 0.22), UDim2.fromScale(0.66, 0.06), brass, 1)
		end
	end
	crystal(root, UDim2.fromScale(0.55, 0.43), 8)
end

local function tools(root: Frame)
	local hammer =
		piece(root, UDim2.fromScale(0.1, 0.06), UDim2.fromScale(0.8, 0.88), dark, nil, 41)
	local wrench =
		piece(root, UDim2.fromScale(0.1, 0.06), UDim2.fromScale(0.8, 0.88), dark, nil, -42)
	hammer.BackgroundTransparency = 1
	wrench.BackgroundTransparency = 1
	piece(wrench, UDim2.fromScale(0.42, 0.26), UDim2.fromScale(0.18, 0.71), steel, 2)
	piece(wrench, UDim2.fromScale(0.31, 0.09), UDim2.fromScale(0.38, 0.28), Theme.crystal, 4)
	piece(wrench, UDim2.fromScale(0.44, 0.06), UDim2.fromScale(0.12, 0.16), dark, 1)
	piece(hammer, UDim2.fromScale(0.43, 0.27), UDim2.fromScale(0.2, 0.7), brass, 2)
	piece(hammer, UDim2.fromScale(0.1, 0.13), UDim2.fromScale(0.78, 0.28), steel, 3)
end

local function scroll(root: Frame)
	piece(root, UDim2.fromScale(0.21, 0.13), UDim2.fromScale(0.59, 0.75), paper, 3, -8)
	piece(root, UDim2.fromScale(0.17, 0.1), UDim2.fromScale(0.68, 0.16), brass, 3, -8)
	piece(root, UDim2.fromScale(0.17, 0.77), UDim2.fromScale(0.68, 0.13), brass, 3, -8)
	piece(root, UDim2.fromScale(0.33, 0.51), UDim2.fromScale(0.23, 0.11), dark, 1, 47)
	piece(root, UDim2.fromScale(0.45, 0.44), UDim2.fromScale(0.29, 0.11), dark, 1, -43)
end

local function gear(root: Frame)
	for i = 0, 3 do
		piece(root, UDim2.fromScale(0.08, 0.4), UDim2.fromScale(0.84, 0.2), steel, 2, 45 * i)
	end
	piece(root, UDim2.fromScale(0.2, 0.2), UDim2.fromScale(0.6, 0.6), steel, 100)
	piece(root, UDim2.fromScale(0.3, 0.3), UDim2.fromScale(0.4, 0.4), dark, 100)
	crystal(root, UDim2.fromScale(0.5, 0.5), 8)
end

local function coin(root: Frame)
	local rim = piece(root, UDim2.fromScale(0.05, 0.05), UDim2.fromScale(0.9, 0.9), brass, 100)
	stroke(rim, dark, 1.5)
	local face = piece(
		root,
		UDim2.fromScale(0.17, 0.17),
		UDim2.fromScale(0.66, 0.66),
		Color3.new(1, 1, 1),
		100
	)
	gradient(face, Color3.fromRGB(255, 236, 141), Color3.fromRGB(247, 157, 18), 90)
	piece(face, UDim2.fromScale(0.34, 0.34), UDim2.fromScale(0.32, 0.32), paper, 1, 45)
end

local function rod(root: Frame, accent: Color3)
	piece(root, UDim2.fromScale(0.13, 0.61), UDim2.fromScale(0.52, 0.15), brass, 2, -54)
	piece(root, UDim2.fromScale(0.35, 0.34), UDim2.fromScale(0.58, 0.09), accent, 2, -48)
	piece(root, UDim2.fromScale(0.48, 0.16), UDim2.fromScale(0.42, 0.07), accent, 2, -22)
	piece(root, UDim2.fromScale(0.87, 0.12), UDim2.fromScale(0.035, 0.48), paper, 1)
	piece(root, UDim2.fromScale(0.79, 0.53), UDim2.fromScale(0.19, 0.21), Theme.rose, 100)
	local reel = piece(root, UDim2.fromScale(0.35, 0.57), UDim2.fromScale(0.22, 0.22), steel, 100)
	stroke(reel, dark, 1)
end

local function chest(root: Frame)
	piece(root, UDim2.fromScale(0.12, 0.46), UDim2.fromScale(0.76, 0.43), dark, 5)
	piece(root, UDim2.fromScale(0.13, 0.43), UDim2.fromScale(0.74, 0.16), brass, 3)
	for _, x in { 0.23, 0.68 } do
		piece(root, UDim2.fromScale(x, 0.46), UDim2.fromScale(0.09, 0.41), brass, 1)
	end
	piece(root, UDim2.fromScale(0.46, 0.5), UDim2.fromScale(0.12, 0.2), paper, 1)
	for i = 1, 3 do
		local shard = piece(
			root,
			UDim2.fromScale(0.21 + i * 0.12, 0.15 + math.abs(2 - i) * 0.09),
			UDim2.fromScale(0.15, 0.33),
			cyan,
			2,
			(i - 2) * 20
		)
		stroke(shard, Theme.crystal, 1)
	end
end

function Wood.icon(parent: GuiObject, name: string, size: number, accent: Color3?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name .. "Icon"
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundTransparency = 1
	if name == "Collection" then
		book(frame)
	elseif name == "Shop" then
		tools(frame)
	elseif name == "Missions" then
		scroll(frame)
	elseif name == "Settings" then
		gear(frame)
	elseif name == "Coin" then
		coin(frame)
	elseif name == "Chest" then
		chest(frame)
	else
		rod(frame, accent or Theme.rose)
	end
	frame.Parent = parent
	return frame
end

function Wood.caption(
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
	label.TextStrokeColor3 = dark
	label.TextStrokeTransparency = 0.52
	label.Font = Theme.font
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.Parent = label
	label.Parent = parent
	return label
end

function Wood.rarityBadge(parent: GuiObject, tint: Color3): Frame
	local badge = Instance.new("Frame")
	badge.Name = "RarityBadge"
	badge.AnchorPoint = Vector2.new(0.5, 0)
	badge.Size = UDim2.fromScale(0.44, 0.18)
	Wood.mount(badge, false, Color3.fromRGB(44, 33, 25)).Color = tint:Lerp(brass, 0.45)
	badge.Parent = parent
	return badge
end

return Wood
