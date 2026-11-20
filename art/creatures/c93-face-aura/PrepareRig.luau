--!strict

local function prepareRig(model: Model): Animator
	local root = model:FindFirstChild("RootPart")
	assert(root and root:IsA("BasePart"), "Import the FBX as a Custom rig with its root bone")
	local body = model:FindFirstChild("Body")
	local core = model:FindFirstChild("Core")
	assert(body and body:IsA("MeshPart"), "Body MeshPart is missing")
	assert(core and core:IsA("MeshPart"), "Core MeshPart is missing")
	assert(math.abs(body.Size.Y - 3.5) <= 0.1, "Import the FBX at its original size")

	local neck = model:FindFirstChild("Spine01", true)
	local nextBone = model:FindFirstChild("Spine02", true)
	local orbitCore = model:FindFirstChild("OrbitCore", true)
	assert(
		neck and neck:IsA("Bone") and nextBone and nextBone:IsA("Bone"),
		"Spine bones are missing"
	)
	assert(orbitCore and orbitCore:IsA("Bone"), "OrbitCore bone is missing")
	local count = 0
	for _, item in model:GetDescendants() do
		if item:IsA("Bone") then
			count += 1
		end
	end
	assert(count == 20, "Expected the complete 20 bone rig")

	local direction =
		model:GetPivot():VectorToObjectSpace(neck.WorldPosition - nextBone.WorldPosition)
	assert(
		direction.Z > 0 and math.abs(direction.X) < direction.Z,
		"Import with the head facing local +Z"
	)

	model.PrimaryPart = root
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = item == root
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
		end
	end
	root.Transparency = 1

	local controller = model:FindFirstChildWhichIsA("AnimationController")
	if not controller then
		controller = Instance.new("AnimationController")
		controller.Parent = model
	end
	local animator = controller:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end
	model:SetAttribute("C93SkinnedRig", true)
	return animator
end

return prepareRig
