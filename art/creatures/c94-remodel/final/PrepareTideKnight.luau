--!strict

local REQUIRED = { "Body", "Head", "FinL", "FinR", "Wings", "Tail", "Extra" }

local function getMesh(model: Model, name: string): MeshPart
	local item = model:FindFirstChild(name)
	assert(item and item:IsA("MeshPart"), "Missing direct MeshPart: " .. name)
	return item
end

-- Run on a new, rigid FBX import before replacing any existing creature.
local function prepareTideKnight(model: Model)
	local pivot = model:GetPivot()
	for _, name in REQUIRED do
		getMesh(model, name)
	end
	local body = getMesh(model, "Body")
	local head = getMesh(model, "Head")
	local tail = getMesh(model, "Tail")
	local left = getMesh(model, "FinL")
	local right = getMesh(model, "FinR")
	local wings = getMesh(model, "Wings")
	local wave = getMesh(model, "Extra")
	local halo = getMesh(model, "Halo")
	local sword = model:FindFirstChild("Sword")
	assert(sword == nil or sword:IsA("MeshPart"), "Sword must be a separate direct MeshPart")
	assert(#model:GetChildren() == (if sword then 9 else 8), "Unexpected imports under the Model")
	assert(
		pivot:VectorToObjectSpace(head.Position - tail.Position).Z > 0.35,
		"Head must be in front of the cloak on local +Z"
	)
	local children = model:GetChildren()
	local minY, maxY = math.huge, -math.huge
	for _, item in children do
		assert(item:IsA("MeshPart"), "Only rigid MeshParts are supported")
		local part = pivot:ToObjectSpace(item.CFrame)
		local half = item.Size * 0.5
		local extentY = math.abs(part.RightVector.Y) * half.X
			+ math.abs(part.UpVector.Y) * half.Y
			+ math.abs(part.LookVector.Y) * half.Z
		minY = math.min(minY, part.Position.Y - extentY)
		maxY = math.max(maxY, part.Position.Y + extentY)
	end
	local height = maxY - minY
	assert(height >= 3.2 and height <= 3.6, "Unexpected height in studs")

	if pivot:PointToObjectSpace(left.Position).X < pivot:PointToObjectSpace(right.Position).X then
		left.Name = "FinR"
		right.Name = "FinL"
	end
	halo.Name = "Extra"
	halo:SetAttribute("C94Role", "Halo")
	wave:SetAttribute("C94Role", "Wave")
	wave.Transparency = 0.06
	wings.Transparency = 0.10
	if sword then
		sword:SetAttribute("C94Role", "Sword")
	end
	for _, item in children do
		if item:IsA("MeshPart") then
			item.Anchored = true
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
		end
	end

	local center = pivot * CFrame.new(0, (minY + maxY) * 0.5, 0)
	model.PrimaryPart = body
	body.PivotOffset = body.CFrame:ToObjectSpace(center)
	return height
end

return prepareTideKnight
