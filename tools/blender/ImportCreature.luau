--!strict

local REQUIRED = { "Body", "Head", "Tail" }
local ALLOWED: { [string]: boolean } = {
	Body = true,
	Head = true,
	Tail = true,
	FinL = true,
	FinR = true,
	Fins = true,
	Wings = true,
	Tentacles = true,
	Legs = true,
	Claws = true,
	Shell = true,
	Extra = true,
}

-- Validate on a fresh import before it enters the pool. This never moves or renames the existing model.
local function prepareCreature(
	model: Model,
	id: string,
	rarity: string,
	neonExtras: boolean?
): Vector3
	assert(string.match(id, "^C%d+_[%w_]+$"), "Expected the exact creature ID from Config")
	local small = rarity == "Common" or rarity == "Uncommon" or rarity == "Rare"
	assert(small or rarity == "Epic" or rarity == "Legendary", "Unsupported creature budget")

	local parts: { MeshPart } = {}
	local byName: { [string]: MeshPart } = {}
	for _, child in model:GetChildren() do
		assert(child:IsA("MeshPart"), "Expected direct rigid MeshParts")
		local name = if string.match(child.Name, "^Extra[%. _]%d+$") then "Extra" else child.Name
		assert(ALLOWED[name], "Unexpected MeshPart " .. child.Name)
		assert(name == "Extra" or not byName[name], "Duplicate MeshPart " .. name)
		byName[name] = child
		table.insert(parts, child)
	end
	for _, name in REQUIRED do
		assert(byName[name], "Missing MeshPart " .. name)
	end
	local head, body, tail = byName.Head, byName.Body, byName.Tail
	assert(head.Position.Z - tail.Position.Z > 0.1, "Head must be in front of Tail along world +Z")
	local left, right = byName.FinL, byName.FinR
	if left and right then
		assert(left.Position.X > right.Position.X, "FinL must be on world +X")
	end

	-- Ignore any rotation on the imported model pivot when measuring the Roblox axes.
	local low = Vector3.new(math.huge, math.huge, math.huge)
	local high = -low
	for _, part in parts do
		for x = -1, 1, 2 do
			for y = -1, 1, 2 do
				for z = -1, 1, 2 do
					local localCorner = part.Size * Vector3.new(x, y, z) * 0.5
					local corner = part.CFrame:PointToWorldSpace(localCorner)
					low = Vector3.new(
						math.min(low.X, corner.X),
						math.min(low.Y, corner.Y),
						math.min(low.Z, corner.Z)
					)
					high = Vector3.new(
						math.max(high.X, corner.X),
						math.max(high.Y, corner.Y),
						math.max(high.Z, corner.Z)
					)
				end
			end
		end
	end
	local size = high - low
	local span = math.max(size.X, size.Y, size.Z)
	local minSize = if small then 2.7 elseif rarity == "Epic" then 3.0 else 3.2
	local maxSize = if small then 2.95 elseif rarity == "Epic" then 3.2 else 3.6
	assert(span >= minSize - 0.005 and span <= maxSize + 0.005, "Unexpected scale in studs")

	for _, part in parts do
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		if string.match(part.Name, "^Extra[%. _]%d+$") then
			part.Name = "Extra"
		end
		if neonExtras and part.Name == "Extra" then
			part.Material = Enum.Material.Neon
		end
	end
	model.Name = id
	model.PrimaryPart = body
	body.PivotOffset = body.CFrame:ToObjectSpace(CFrame.new((low + high) * 0.5))
	return size
end

return prepareCreature
