--!strict
-- Ambient island life (client-only, lightweight for mobile):
--   * Swimming fish schools in the training lagoon and beside the fishing pier
--   * Stylized seagulls circling lazily overhead
--   * Subtle water sparkles and rising bubbles (disabled when ReduceEffects is active)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local IslandLife = {}
IslandLife.order = 300

type Swimmer = {
	model: Model,
	center: Vector3,
	rx: number,
	rz: number,
	speed: number,
	phase: number,
	bobAmp: number,
	wagSpeed: number,
}

type Gull = {
	body: BasePart,
	leftWing: BasePart,
	rightWing: BasePart,
	center: Vector3,
	radius: number,
	speed: number,
	phase: number,
	flapSpeed: number,
}

local function makePart(
	name: string,
	parent: Instance,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function spawnFish(parent: Instance, color: Color3, scale: number): Model
	local m = Instance.new("Model")
	m.Name = "AmbientFish"

	local body = makePart(
		"Body",
		m,
		Vector3.new(0.42, 0.3, 1.05) * scale,
		color,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)

	local tail = Instance.new("WedgePart")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.12, 0.42, 0.48) * scale
	tail.Color = color
	tail.Material = Enum.Material.SmoothPlastic
	tail.Anchored = true
	tail.CanCollide = false
	tail.CanQuery = false
	tail.CanTouch = false
	tail.CastShadow = false
	tail.TopSurface = Enum.SurfaceType.Smooth
	tail.BottomSurface = Enum.SurfaceType.Smooth
	tail.CFrame = CFrame.new(0, 0, 0.58 * scale) * CFrame.Angles(0, 0, math.rad(90))
	tail.Parent = m

	m.PrimaryPart = body
	m.Parent = parent
	return m
end

local function spawnGull(parent: Instance): (BasePart, BasePart, BasePart)
	local m = Instance.new("Model")
	m.Name = "Seagull"

	local body = makePart(
		"Body",
		m,
		Vector3.new(0.6, 0.45, 1.7),
		Color3.fromRGB(246, 246, 250),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	local wingSize = Vector3.new(1.8, 0.1, 0.65)
	local leftWing = makePart(
		"LeftWing",
		m,
		wingSize,
		Color3.fromRGB(235, 240, 248),
		Enum.Material.SmoothPlastic
	)
	local rightWing = makePart(
		"RightWing",
		m,
		wingSize,
		Color3.fromRGB(235, 240, 248),
		Enum.Material.SmoothPlastic
	)

	m.Parent = parent
	return body, leftWing, rightWing
end

local function makeEmitterPart(
	parent: Instance,
	name: string,
	pos: Vector3,
	size: Vector3,
	texture: string,
	color: ColorSequence,
	particleSize: NumberSequence,
	rate: number,
	speed: NumberRange,
	lifetime: NumberRange
): ParticleEmitter
	local p = makePart(name, parent, size, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	p.Transparency = 1
	p.CFrame = CFrame.new(pos)

	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = color
	e.Size = particleSize
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.4, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.LightEmission = 0.8
	e.Lifetime = lifetime
	e.Rate = rate
	e.Speed = speed
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = p
	return e
end

function IslandLife.start()
	local container = Instance.new("Folder")
	container.Name = "IslandLife"
	container.Parent = Workspace

	local swimmers: { Swimmer } = {}
	local gulls: { Gull } = {}
	local emitters: { { emitter: ParticleEmitter, baseRate: number } } = {}

	local fishPalette = {
		Color3.fromRGB(70, 210, 255),
		Color3.fromRGB(255, 178, 82),
		Color3.fromRGB(255, 130, 196),
		Color3.fromRGB(110, 232, 180),
	}

	-- Lagoon fish (under the translucent cyan surface at y = 7.75).
	for i = 1, 5 do
		local color = fishPalette[1 + (i % #fishPalette)]
		local model = spawnFish(container, color, 0.85)
		table.insert(swimmers, {
			model = model,
			center = Vector3.new(-44, 7.65, 2),
			rx = 5 + (i % 3) * 2.4,
			rz = 4.5 + ((i + 1) % 3) * 2.1,
			speed = 0.36 + (i % 3) * 0.08,
			phase = i * 1.25,
			bobAmp = 0.08,
			wagSpeed = 6.5,
		})
	end

	-- Pier fish schools swimming visibly in the shallow turquoise water.
	local pierCenters = {
		Vector3.new(46, -1.2, 19),
		Vector3.new(68, -1.4, -3),
	}
	for sIdx, c in pierCenters do
		for i = 1, 5 do
			local color = fishPalette[1 + ((sIdx + i) % #fishPalette)]
			local model = spawnFish(container, color, 1.05)
			table.insert(swimmers, {
				model = model,
				center = c + Vector3.new((i - 3) * 0.7, (i % 2) * 0.25, 0),
				rx = 6.5 + (i % 3) * 1.8,
				rz = 4.2 + ((i + 1) % 2) * 1.8,
				speed = 0.42 + (i % 2) * 0.1,
				phase = i * 1.1 + sIdx * 2.0,
				bobAmp = 0.14,
				wagSpeed = 7.5,
			})
		end
	end

	-- Overhead seagulls circling above the island and pier.
	for i = 1, 4 do
		local body, leftWing, rightWing = spawnGull(container)
		table.insert(gulls, {
			body = body,
			leftWing = leftWing,
			rightWing = rightWing,
			center = Vector3.new(8, 44 + i * 3.2, 0),
			radius = 44 + i * 7,
			speed = 0.18 + (i % 2) * 0.04,
			phase = i * 1.57,
			flapSpeed = 4.4 + (i % 3) * 0.5,
		})
	end

	-- Water surface sparkles near the pier and stairs.
	local sparkleTex = "rbxasset://textures/particles/sparkles_main.dds"
	local bubbleTex = "rbxasset://textures/particles/smoke_main.dds"
	local sparkleColor = ColorSequence.new(Color3.fromRGB(220, 252, 255))
	local bubbleColor = ColorSequence.new(Color3.fromRGB(165, 240, 255))

	local sparkleSize = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, 0.75),
		NumberSequenceKeypoint.new(1, 0),
	})
	local bubbleSize = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.5),
	})

	table.insert(emitters, {
		emitter = makeEmitterPart(
			container,
			"PierWaterSparkle",
			Vector3.new(52, 0.2, 18),
			Vector3.new(26, 0.2, 20),
			sparkleTex,
			sparkleColor,
			sparkleSize,
			4,
			NumberRange.new(0.2, 0.6),
			NumberRange.new(0.9, 1.6)
		),
		baseRate = 4,
	})
	table.insert(emitters, {
		emitter = makeEmitterPart(
			container,
			"StairsWaterSparkle",
			Vector3.new(-6, 0.2, 56),
			Vector3.new(18, 0.2, 12),
			sparkleTex,
			sparkleColor,
			sparkleSize,
			3,
			NumberRange.new(0.2, 0.6),
			NumberRange.new(0.9, 1.6)
		),
		baseRate = 3,
	})
	table.insert(emitters, {
		emitter = makeEmitterPart(
			container,
			"LagoonBubbles",
			Vector3.new(-44, 6.8, 2),
			Vector3.new(10, 0.2, 10),
			bubbleTex,
			bubbleColor,
			bubbleSize,
			3,
			NumberRange.new(0.8, 1.5),
			NumberRange.new(0.8, 1.3)
		),
		baseRate = 3,
	})
	table.insert(emitters, {
		emitter = makeEmitterPart(
			container,
			"PierCrystalBubbles",
			Vector3.new(56, -1.2, 22),
			Vector3.new(5, 0.2, 5),
			bubbleTex,
			bubbleColor,
			bubbleSize,
			3,
			NumberRange.new(0.8, 1.6),
			NumberRange.new(1.0, 1.6)
		),
		baseRate = 3,
	})

	local player = Players.LocalPlayer
	local function syncEffects()
		local reduced = player:GetAttribute("ReduceEffects") == true
		for _, item in emitters do
			item.emitter.Rate = if reduced then 0 else item.baseRate
		end
	end
	syncEffects()
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(syncEffects)

	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for _, f in swimmers do
			local angle = t * f.speed + f.phase
			local x = f.center.X + math.cos(angle) * f.rx
			local z = f.center.Z + math.sin(angle) * f.rz
			local y = f.center.Y + math.sin(t * 2 + f.phase) * f.bobAmp

			local vx = -math.sin(angle) * f.rx
			local vz = math.cos(angle) * f.rz
			local wag = math.sin(t * f.wagSpeed + f.phase) * 0.14
			local cf = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(x + vx, y, z + vz))
				* CFrame.Angles(0, wag, 0)
			f.model:PivotTo(cf)
		end

		for _, g in gulls do
			local angle = t * g.speed + g.phase
			local x = g.center.X + math.cos(angle) * g.radius
			local z = g.center.Z + math.sin(angle) * g.radius
			local y = g.center.Y + math.sin(t * 1.1 + g.phase) * 1.2

			local vx = -math.sin(angle)
			local vz = math.cos(angle)
			local cf = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(x + vx, y, z + vz))
				* CFrame.Angles(0, 0, math.rad(8))
			g.body.CFrame = cf

			local flap = math.sin(t * g.flapSpeed + g.phase) * 0.45
			g.leftWing.CFrame = cf * CFrame.new(-0.95, 0.12, 0) * CFrame.Angles(0, 0, -flap)
			g.rightWing.CFrame = cf * CFrame.new(0.95, 0.12, 0) * CFrame.Angles(0, 0, flap)
		end
	end)
end

return IslandLife
