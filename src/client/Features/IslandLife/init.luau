--!strict
-- Ambient island life (client-only, lightweight for mobile):
--   * Swimming fish schools in the training lagoon and beside the fishing pier (with periodic jumps)
--   * Stylized seagulls circling lazily overhead
--   * Subtle water sparkles, bubbles, and lantern fireflies (disabled when ReduceEffects is active)

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
	jumpPeriod: number?,
	jumpDuration: number?,
	jumpHeight: number?,
	surfaceY: number?,
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

	-- Lagoon fish (under the translucent cyan surface at y = 7.75; 2 hop playfully out of water).
	for i = 1, 5 do
		local color = fishPalette[1 + (i % #fishPalette)]
		local model = spawnFish(container, color, 0.85)
		local canJump = i == 2 or i == 5
		table.insert(swimmers, {
			model = model,
			center = Vector3.new(-44, 7.65, 2),
			rx = 5 + (i % 3) * 2.4,
			rz = 4.5 + ((i + 1) % 3) * 2.1,
			speed = 0.36 + (i % 3) * 0.08,
			phase = i * 1.25,
			bobAmp = 0.08,
			wagSpeed = 6.5,
			jumpPeriod = if canJump then (8.5 + i * 1.3) else nil,
			jumpDuration = 0.9,
			jumpHeight = 2.1,
			surfaceY = 7.85,
		})
	end

	-- Pier fish schools swimming visibly in the shallow turquoise water (3 jump occasionally).
	local pierCenters = {
		Vector3.new(46, -1.2, 19),
		Vector3.new(68, -1.4, -3),
	}
	for sIdx, c in pierCenters do
		for i = 1, 5 do
			local color = fishPalette[1 + ((sIdx + i) % #fishPalette)]
			local model = spawnFish(container, color, 1.05)
			local canJump = (sIdx == 1 and (i == 1 or i == 4)) or (sIdx == 2 and i == 3)
			table.insert(swimmers, {
				model = model,
				center = c + Vector3.new((i - 3) * 0.7, (i % 2) * 0.25, 0),
				rx = 6.5 + (i % 3) * 1.8,
				rz = 4.2 + ((i + 1) % 2) * 1.8,
				speed = 0.42 + (i % 2) * 0.1,
				phase = i * 1.1 + sIdx * 2.0,
				bobAmp = 0.14,
				wagSpeed = 7.5,
				jumpPeriod = if canJump then (9.0 + sIdx * 1.7 + i * 1.1) else nil,
				jumpDuration = 1.05,
				jumpHeight = 2.8,
				surfaceY = 0.0,
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

	-- Soft fireflies around plaza and lagoon lanterns (2 lightweight emitters, 0 dynamic lights).
	local fireflySize = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.35),
		NumberSequenceKeypoint.new(0.7, 0.28),
		NumberSequenceKeypoint.new(1, 0),
	})
	local plazaFireflies = makeEmitterPart(
		container,
		"PlazaFireflies",
		Vector3.new(-8, 14.5, 4),
		Vector3.new(36, 4.5, 36),
		sparkleTex,
		ColorSequence.new(Color3.fromRGB(255, 224, 130), Color3.fromRGB(165, 245, 255)),
		fireflySize,
		4,
		NumberRange.new(0.35, 1.0),
		NumberRange.new(1.8, 3.0)
	)
	plazaFireflies.SpreadAngle = Vector2.new(180, 180)
	plazaFireflies.LightEmission = 1
	table.insert(emitters, { emitter = plazaFireflies, baseRate = 4 })

	local lagoonFireflies = makeEmitterPart(
		container,
		"LagoonFireflies",
		Vector3.new(-38, 13.5, -2),
		Vector3.new(24, 4.5, 24),
		sparkleTex,
		ColorSequence.new(Color3.fromRGB(255, 215, 135), Color3.fromRGB(220, 175, 255)),
		fireflySize,
		3,
		NumberRange.new(0.3, 0.9),
		NumberRange.new(1.8, 3.0)
	)
	lagoonFireflies.SpreadAngle = Vector2.new(180, 180)
	lagoonFireflies.LightEmission = 1
	table.insert(emitters, { emitter = lagoonFireflies, baseRate = 3 })

	local player = Players.LocalPlayer
	local reduceEffects = player:GetAttribute("ReduceEffects") == true
	local function syncEffects()
		reduceEffects = player:GetAttribute("ReduceEffects") == true
		for _, item in emitters do
			item.emitter.Rate = if reduceEffects then 0 else item.baseRate
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
			local pitch = 0

			local period = f.jumpPeriod
			local dur = f.jumpDuration
			local h = f.jumpHeight
			local sy = f.surfaceY
			if not reduceEffects and period and dur and h and sy then
				local cycle = (t + f.phase * 1.9) % period
				if cycle < dur then
					local u = cycle / dur
					local arc = 4 * u * (1 - u)
					local jumpY = sy + h * arc - 0.35
					if jumpY > y then
						y = jumpY
					end
					-- Tilt nose up on ascent and down on dive.
					local slope = 4 * h * (1 - 2 * u) / dur
					pitch = math.clamp(math.atan2(slope, 6.5), -0.95, 0.95)
				end
			end

			local vx = -math.sin(angle) * f.rx
			local vz = math.cos(angle) * f.rz
			local wag = math.sin(t * f.wagSpeed + f.phase) * 0.14
			local cf = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(x + vx, y, z + vz))
				* CFrame.Angles(pitch, wag, 0)
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
