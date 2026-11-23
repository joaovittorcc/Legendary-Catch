--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared.Config.Creatures)
local Theme = require(Shared.UiTheme)
local Candy = require(script.Parent.AquariumCandy)

local Tank = {}
export type Display = {
	slot: number,
	creatureId: string,
	rarity: string,
	large: boolean,
	gold: boolean?,
	linked: boolean,
}

local function part(world: WorldModel, name: string, color: Color3, transparency: number): Part
	local layer = Instance.new("Part")
	layer.Name = name
	layer.Anchored = true
	layer.CanCollide = false
	layer.CanQuery = false
	layer.CanTouch = false
	layer.Color = color
	layer.Transparency = transparency
	layer.Material = Enum.Material.SmoothPlastic
	layer.Parent = world
	return layer
end

local function volume(capacity: number): Vector3
	return Vector3.new(6.3 + capacity * 0.72, 3.4 + capacity * 0.17, 3.1 + capacity * 0.28)
end

-- The viewport uses a local volume. The same pose can be placed in a world volume
-- by multiplying by the habitat's CFrame.
local function swimPose(
	bounds: Vector3,
	slot: number,
	speed: number,
	radius: number,
	time: number,
	reaction: number
): CFrame
	local phase = slot * 2.37 + time * speed + math.sin(time * speed * 1.7 + slot) * 0.54
	local x = math.max(0, bounds.X / 2 - radius - 0.25)
	local y = math.max(0, bounds.Y / 2 - radius - 0.22)
	local z = math.max(0, bounds.Z / 2 - radius - 0.25)
	local center = Vector3.new(
		math.cos(phase) * x * (0.72 + reaction * 0.2),
		math.sin(phase + slot * 0.4) * y * 0.78,
		math.sin(phase) * z * 0.76
	)
	local tangent =
		Vector3.new(-math.sin(phase) * x, math.cos(phase) * y * 0.25, math.cos(phase) * z)
	return if tangent.Magnitude > 0.05
		then CFrame.lookAt(center, center - tangent)
		else CFrame.new(center)
end

export type Controller = {
	expand: (number, string?) -> (),
	react: () -> (),
	preview: (number?, string?) -> (),
}

function Tank.mount(
	parent: Frame,
	scroll: ScrollingFrame,
	displays: { Display },
	capacity: number,
	levelId: string?,
	immersive: boolean?
): Controller
	local player = Players.LocalPlayer
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "AquariumTankViewport"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundColor3 = Candy.cobalt
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(155, 221, 255)
	viewport.LightColor = Color3.fromRGB(255, 243, 208)
	viewport.LightDirection = Vector3.new(-0.5, -1, -0.6)
	Theme.corner(viewport, 14)
	local rim = Instance.new("UIStroke")
	rim.Color = Candy.cyan
	rim.Thickness = 2
	rim.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	rim.Parent = viewport

	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 42
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local base = part(world, "Timber", Theme.wood, 0)
	local sand = part(world, "Sand", Theme.gold, 0)
	local glass = part(world, "BackGlass", Color3.fromRGB(39, 133, 158), 0.24)
	local glassLeft = part(world, "LeftGlass", Theme.crystal, 0.68)
	local glassRight = part(world, "RightGlass", Theme.crystal, 0.68)
	local trim = part(world, "TopTrim", Color3.fromRGB(76, 200, 208), 0)
	local leftPreview = part(world, "LeftExpansion", Theme.gold, 1)
	local rightPreview = part(world, "RightExpansion", Theme.gold, 1)
	local previewBounds: Vector3? = nil
	local architecture: Model? = nil
	local swimOrigin = CFrame.identity
	local viewAnchor: CFrame? = nil
	local coral = {}
	local coralColors = { Candy.coral, Candy.violet, Candy.cyan, Candy.gold }
	for index = 1, if immersive then 12 else 5 do
		local color = coralColors[(index - 1) % #coralColors + 1]
		coral[index] = part(world, "Coral" .. index, color, 0)
		if immersive then
			coral[index].Shape = Enum.PartType.Ball
		end
	end
	local bubbles: { Part } = {}
	if immersive then
		base.Color = Candy.cobalt
		glass.Color = Color3.fromRGB(15, 138, 248)
		glass.Transparency = 0.1
		sand.Color = Color3.fromRGB(255, 188, 96)
		for index = 1, 8 do
			local bubble = part(world, "Bubble" .. index, Candy.cyan, 0.35)
			bubble.Shape = Enum.PartType.Ball
			bubble.Material = Enum.Material.Neon
			bubble.Size = Vector3.one * (0.09 + index % 3 * 0.046)
			table.insert(bubbles, bubble)
		end
	end
	local function levelTemplate(id: string?): Model?
		local kit = ReplicatedStorage:FindFirstChild("AquariumLevels")
		local levels = kit and kit:FindFirstChild("Levels")
		local source = if id and levels then levels:FindFirstChild(id) else nil
		return if source and source:IsA("Model") then source else nil
	end
	local function mountLevel(id: string?): Vector3?
		if immersive then
			return nil
		end
		local source = levelTemplate(id)
		if not source then
			return nil
		end
		local model = source:Clone()
		local swim = model:FindFirstChild("SwimVolume", true)
		local inspect = model:FindFirstChild("InspectCamera", true)
		if not swim or not swim:IsA("BasePart") or not inspect or not inspect:IsA("BasePart") then
			model:Destroy()
			return nil
		end
		for _, child in model:GetDescendants() do
			if
				child:IsA("BaseScript")
				or child:IsA("ParticleEmitter")
				or child:IsA("SurfaceGui")
				or child:IsA("ProximityPrompt")
			then
				child:Destroy()
			end
		end
		model:PivotTo(swim.CFrame:Inverse() * model:GetPivot())
		swimOrigin = swim.CFrame
		viewAnchor = CFrame.lookAt(inspect.Position, swim.Position)
		if architecture then
			architecture:Destroy()
		end
		architecture = model
		for _, fallback in { base, sand, glass, glassLeft, glassRight, trim, table.unpack(coral) } do
			fallback.Transparency = 1
		end
		model.Parent = world
		return swim.Size
	end

	local shoal = {}
	local pool = ReplicatedStorage:FindFirstChild(Creatures.MODELS_FOLDER)
	for _, display in displays do
		local original = pool and pool:FindFirstChild(display.creatureId)
		if not original or not original:IsA("Model") then
			continue
		end
		local model = original:Clone()
		model.Name = "Swimmer" .. display.slot
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then
				item.Anchored = true
				if display.gold then
					item.Color = item.Color:Lerp(Color3.fromRGB(255, 198, 76), 0.65)
				end
				item.CanCollide = false
				item.CanQuery = false
				item.CanTouch = false
			elseif item:IsA("BaseScript") or item:IsA("ParticleEmitter") or item:IsA("Light") then
				item:Destroy()
			end
		end
		local _, oldSize = model:GetBoundingBox()
		local maxSize = if display.large
			then (if immersive then 3.05 else 2.4)
			elseif immersive then 2.2
			else 1.62
		model:ScaleTo(model:GetScale() * maxSize / math.max(0.1, oldSize.X, oldSize.Y, oldSize.Z))
		local box, size = model:GetBoundingBox()
		local offset = box:ToObjectSpace(model:GetPivot())
		local ring = if display.linked
			then part(
				world,
				"Synergy" .. display.slot,
				Theme.rarity[display.rarity] or Theme.crystal,
				1
			)
			else nil
		if ring then
			ring.Shape = Enum.PartType.Ball
			ring.Material = Enum.Material.Neon
			ring.Size = Vector3.one * 0.18
		end
		table.insert(shoal, {
			display = display,
			model = model,
			offset = offset,
			radius = size.Magnitude / 2,
			speed = if display.large then 0.42 else 0.58 + (display.slot % 3) * 0.06,
			spark = ring,
		})
		model.Parent = world
	end

	local dimensions = Instance.new("Vector3Value")
	dimensions.Value = mountLevel(levelId) or volume(capacity)
	dimensions.Parent = viewport
	local targetBounds = dimensions.Value
	local lastBounds = Vector3.zero
	local swimTime = 0
	local lastReaction = -math.huge
	local lastSynergy = -math.huge
	local reducedLast = false
	local elapsed = 0
	local expansion: Tween? = nil

	local function layout(size: Vector3)
		local x, y, z = size.X, size.Y, size.Z
		local previewSize = previewBounds or size
		local distance = math.max(previewSize.X * 0.94, y * 1.8) + 3.7
		leftPreview.Size = Vector3.new(0.10, previewSize.Y, 0.10)
		rightPreview.Size = leftPreview.Size
		leftPreview.Position = Vector3.new(-previewSize.X / 2, 0, 0)
		rightPreview.Position = Vector3.new(previewSize.X / 2, 0, 0)
		leftPreview.Transparency = if previewBounds then 0.14 else 1
		rightPreview.Transparency = leftPreview.Transparency
		local anchor = viewAnchor
		camera.CFrame = if anchor
			then CFrame.lookAt(
				anchor.Position * math.max(1, previewSize.X / math.max(1, x)),
				swimOrigin.Position
			)
			elseif immersive then CFrame.lookAt(
				Vector3.new(0, y * 0.18, math.max(y * 1.42, x * 0.51) + z * 0.5),
				Vector3.zero
			)
			else CFrame.lookAt(Vector3.new(x * 0.11, y * 0.58, distance), Vector3.zero)
		base.Size = Vector3.new(x + 0.42, 0.36, z + 0.42)
		base.Position = Vector3.new(0, -y / 2 - 0.22, 0)
		sand.Size = Vector3.new(x, 0.12, z)
		sand.Position = Vector3.new(0, -y / 2, 0)
		glass.Size = Vector3.new(x, y, 0.08)
		glass.Position = Vector3.new(0, 0, -z / 2)
		glassLeft.Size = Vector3.new(0.10, y, z)
		glassLeft.Position = Vector3.new(-x / 2, 0, 0)
		glassRight.Size = Vector3.new(0.10, y, z)
		glassRight.Position = Vector3.new(x / 2, 0, 0)
		trim.Size = Vector3.new(x, 0.12, 0.22)
		trim.Position = Vector3.new(0, y / 2, -z / 2)
		for index, stem in coral do
			local height = 0.5 + index % 3 * y * 0.15
			local side = if index % 2 == 0 then -1 else 1
			local edge = if immersive then side * (0.24 + index % 5 * 0.045) else index / 6 - 0.5
			local width = if immersive then 0.25 + index % 4 * 0.13 else 0.2 + index % 2 * 0.22
			stem.Size = Vector3.new(width, height, width)
			stem.CFrame = CFrame.new(edge * x, -y / 2 + height / 2, -z * (0.39 - index % 3 * 0.08))
				* CFrame.Angles(0, 0, (index - 3) * 0.14)
		end
	end

	local function draw(time: number, reduced: boolean)
		local size = dimensions.Value
		if size ~= lastBounds then
			lastBounds = size
			layout(size)
		end
		local reaction = if reduced then 0 else math.max(0, 1 - (time - lastReaction) / 1.2)
		local synergy = if reduced then 0 else math.max(0, 1 - (time - lastSynergy) / 1.25)
		for index, bubble in bubbles do
			local offset = (index * 0.168 + swimTime * 0.11) % 1
			local side = if index % 2 == 0 then -1 else 1
			bubble.Position = Vector3.new(
				side * size.X * (0.24 + 0.05 * math.sin(offset * math.pi * 2 + index)),
				(offset - 0.5) * size.Y,
				-size.Z * 0.27
			)
			bubble.Transparency = 1 - 0.56 * math.sin(math.pi * offset)
		end
		for _, fish in shoal do
			local pose = swimOrigin
				* swimPose(size, fish.display.slot, fish.speed, fish.radius, swimTime, reaction)
			fish.model:PivotTo(pose * fish.offset)
			local spark = fish.spark
			if spark then
				spark.Position = pose.Position + Vector3.new(0, fish.radius * 0.75, 0)
				spark.Transparency = 1 - synergy * 0.85
			end
		end
	end

	local frames = RunService.RenderStepped:Connect(function(dt)
		if
			viewport.AbsoluteSize.Y == 0
			or viewport.AbsolutePosition.Y > scroll.AbsolutePosition.Y + scroll.AbsoluteWindowSize.Y
			or viewport.AbsolutePosition.Y + viewport.AbsoluteSize.Y < scroll.AbsolutePosition.Y
		then
			return
		end
		elapsed += dt
		if elapsed < 1 / 30 then
			return
		end
		local reduced = player:GetAttribute("ReduceEffects") == true
		if reduced then
			if expansion then
				expansion:Cancel()
				expansion = nil
				dimensions.Value = targetBounds
			end
		else
			swimTime += math.min(elapsed, 0.065)
		end
		elapsed = 0
		if not reduced or reduced ~= reducedLast or dimensions.Value ~= lastBounds then
			draw(os.clock(), reduced)
		end
		reducedLast = reduced
	end)
	viewport.Destroying:Once(function()
		frames:Disconnect()
		if expansion then
			expansion:Cancel()
		end
	end)
	viewport.Parent = parent
	draw(os.clock(), player:GetAttribute("ReduceEffects") == true)

	local function expand(nextCapacity: number, nextLevelId: string?)
		previewBounds = nil
		if expansion then
			expansion:Cancel()
			expansion = nil
		end
		targetBounds = mountLevel(nextLevelId) or volume(nextCapacity)
		if player:GetAttribute("ReduceEffects") == true then
			dimensions.Value = targetBounds
			draw(os.clock(), true)
		else
			local tween = TweenService:Create(
				dimensions,
				TweenInfo.new(0.82, Enum.EasingStyle.Quart),
				{ Value = targetBounds }
			)
			expansion = tween
			tween:Play()
		end
		lastSynergy = os.clock()
	end
	return {
		expand = expand,
		react = function()
			lastReaction = os.clock()
			lastSynergy = lastReaction
		end,
		preview = function(nextCapacity: number?, nextLevelId: string?)
			local source = levelTemplate(nextLevelId)
			local target = source and source:FindFirstChild("SwimVolume", true)
			previewBounds = if target and target:IsA("BasePart")
				then target.Size
				elseif nextCapacity then volume(nextCapacity)
				else nil
			layout(dimensions.Value)
		end,
	}
end

return Tank
