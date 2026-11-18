--!strict
-- Lightweight ambient environment effects (client-only, mobile-friendly):
--   * Distant seagulls circling and gliding over the open ocean
--   * Open-sea fish leaping in arcs far from the fishing pier, with splash rings
--   * Occasional shimmering shoal surfacing near the outer reef
--   * Gentle tide ripples expanding around the pier pilings
--   * Nighttime fireflies and subtle crystal pulsing (no new dynamic lights)
-- Everything cleanly disables and frees frame work when Player attribute ReduceEffects = true.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Ambient = {}
Ambient.order = 310

local SEA_Y = 0.0

type SeaGull = {
	body: BasePart,
	beak: BasePart,
	leftWing: BasePart,
	rightWing: BasePart,
	center: Vector3,
	radius: number,
	speed: number,
	phase: number,
	flapSpeed: number,
}

type SeaJumper = {
	body: BasePart,
	tail: BasePart,
	ring: BasePart,
	center: Vector3,
	heading: number,
	period: number,
	duration: number,
	height: number,
	span: number,
	phase: number,
}

type ShoalMember = {
	part: BasePart,
	offsetAngle: number,
	radial: number,
	depth: number,
	bobPhase: number,
}

type PilingRipple = {
	ring: BasePart,
	pos: Vector3,
	phase: number,
	period: number,
	baseRadius: number,
}

type Firefly = {
	part: BasePart,
	anchor: Vector3,
	rx: number,
	ry: number,
	rz: number,
	speed: number,
	phase: number,
}

type CrystalLightTarget = {
	light: PointLight,
	baseBrightness: number,
	phase: number,
}

type CrystalPartTarget = {
	part: BasePart,
	baseColor: Color3,
	phase: number,
}

type EmberMote = {
	part: BasePart,
	phase: number,
	speed: number,
	driftX: number,
	driftZ: number,
}

local function makePart(
	parent: Instance,
	name: string,
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

local function createSeagull(
	parent: Instance,
	index: number,
	center: Vector3,
	radius: number
): SeaGull
	local body = makePart(
		parent,
		"AmbientGullBody" .. index,
		Vector3.new(0.55, 0.42, 1.55),
		Color3.fromRGB(246, 248, 252),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	local beak = makePart(
		parent,
		"AmbientGullBeak" .. index,
		Vector3.new(0.14, 0.12, 0.36),
		Color3.fromRGB(248, 178, 66),
		Enum.Material.SmoothPlastic
	)
	local wingSize = Vector3.new(1.75, 0.08, 0.56)
	local leftWing = makePart(
		parent,
		"AmbientGullWingL" .. index,
		wingSize,
		Color3.fromRGB(232, 238, 248),
		Enum.Material.SmoothPlastic
	)
	local rightWing = makePart(
		parent,
		"AmbientGullWingR" .. index,
		wingSize,
		Color3.fromRGB(232, 238, 248),
		Enum.Material.SmoothPlastic
	)
	return {
		body = body,
		beak = beak,
		leftWing = leftWing,
		rightWing = rightWing,
		center = center,
		radius = radius,
		speed = 0.17 + index * 0.03,
		phase = index * 2.1,
		flapSpeed = 4.6 + index * 0.4,
	}
end

local function createJumper(
	parent: Instance,
	index: number,
	center: Vector3,
	heading: number,
	color: Color3,
	period: number
): SeaJumper
	local body = makePart(
		parent,
		"SeaJumperBody" .. index,
		Vector3.new(0.48, 0.36, 1.28),
		color,
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	local tail = Instance.new("WedgePart")
	tail.Name = "SeaJumperTail" .. index
	tail.Size = Vector3.new(0.14, 0.48, 0.54)
	tail.Color = color
	tail.Material = Enum.Material.SmoothPlastic
	tail.Anchored = true
	tail.CanCollide = false
	tail.CanQuery = false
	tail.CanTouch = false
	tail.CastShadow = false
	tail.TopSurface = Enum.SurfaceType.Smooth
	tail.BottomSurface = Enum.SurfaceType.Smooth
	tail.Parent = parent

	local ring = makePart(
		parent,
		"SeaJumperSplash" .. index,
		Vector3.new(0.06, 1.2, 1.2),
		Color3.fromRGB(224, 248, 255),
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
	ring.Transparency = 1

	return {
		body = body,
		tail = tail,
		ring = ring,
		center = center,
		heading = heading,
		period = period,
		duration = 1.15,
		height = 4.2 + (index % 2) * 0.8,
		span = 8.0 + index * 0.8,
		phase = index * 2.7,
	}
end

local function findPierPilings(): { Vector3 }
	local positions: { Vector3 } = {}
	local island = Workspace:FindFirstChild("Island")
	local pier = island and island:FindFirstChild("FishingPier")
	if pier then
		for _, inst in pier:GetChildren() do
			if inst:IsA("BasePart") and inst.Name == "Piling" then
				table.insert(positions, Vector3.new(inst.Position.X, SEA_Y + 0.05, inst.Position.Z))
			end
		end
	end
	if #positions == 0 then
		-- Fallback matching IslandGenerator.buildPier coordinates
		for x = 22.2, 84, 8 do
			for _, z in { 1.45, 14.55 } do
				table.insert(positions, Vector3.new(x, SEA_Y + 0.05, z))
			end
		end
	end
	table.sort(positions, function(a, b)
		if math.abs(a.X - b.X) > 0.1 then
			return a.X < b.X
		end
		return a.Z < b.Z
	end)
	-- Keep up to 8 evenly spaced pilings so mobile stays ultra-light
	local selected: { Vector3 } = {}
	local step = math.max(1, math.floor(#positions / 8))
	for i = 1, #positions, step do
		if #selected >= 8 then
			break
		end
		table.insert(selected, positions[i])
	end
	return selected
end

local function collectCrystals(lightsOut: { CrystalLightTarget }, partsOut: { CrystalPartTarget })
	table.clear(lightsOut)
	table.clear(partsOut)
	local island = Workspace:FindFirstChild("Island")
	if not island then
		return
	end
	local idx = 0
	for _, d in island:GetDescendants() do
		if
			d:IsA("PointLight")
			and d.Parent
			and (d.Parent.Name == "CrystalGlow" or d.Parent.Name == "UpgradeCrystalLight")
		then
			idx += 1
			table.insert(lightsOut, {
				light = d,
				baseBrightness = d.Brightness,
				phase = idx * 0.9,
			})
		elseif
			d:IsA("BasePart")
			and (d.Name == "Crystal" or d.Name == "UpgradeCrystal" or d.Name == "CrystalCluster")
		then
			if d.Material == Enum.Material.Neon or d.Material == Enum.Material.Glass then
				idx += 1
				table.insert(partsOut, {
					part = d,
					baseColor = d.Color,
					phase = idx * 0.7,
				})
			end
		end
	end
end

local function isNightOrDarkEvent(): boolean
	local clock = Lighting.ClockTime
	if clock < 6.2 or clock >= 17.8 then
		return true
	end
	local eventId = ReplicatedStorage:GetAttribute("OceanEvent")
	return eventId == "starTide" or eventId == "thunderStorm"
end

function Ambient.start()
	local container = Instance.new("Folder")
	container.Name = "IslandAmbient"

	-- 1. Two distant circling seagulls far out from the pier and plaza
	local gulls: { SeaGull } = {
		createSeagull(container, 1, Vector3.new(118, 35, -34), 28),
		createSeagull(container, 2, Vector3.new(-64, 39, 64), 26),
	}

	-- 2. Three open-sea jumping fish well away from the pier (pier is x=18..84, z=8)
	local jumpers: { SeaJumper } = {
		createJumper(
			container,
			1,
			Vector3.new(122, 0, -24),
			math.rad(30),
			Color3.fromRGB(82, 218, 255),
			8.2
		),
		createJumper(
			container,
			2,
			Vector3.new(130, 0, 42),
			math.rad(-140),
			Color3.fromRGB(255, 192, 92),
			9.6
		),
		createJumper(
			container,
			3,
			Vector3.new(-26, 0, 74),
			math.rad(15),
			Color3.fromRGB(145, 238, 200),
			10.8
		),
	}

	-- 3. Occasional shimmering shoal (7 neon fish + 1 surface shimmer ring)
	local shoalColors = {
		Color3.fromRGB(90, 240, 255),
		Color3.fromRGB(255, 224, 120),
		Color3.fromRGB(190, 155, 255),
	}
	local shoalMembers: { ShoalMember } = {}
	for i = 1, 7 do
		local p = makePart(
			container,
			"ShimmerFish" .. i,
			Vector3.new(0.32, 0.24, 0.86),
			shoalColors[1 + (i % #shoalColors)],
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		p.Transparency = 1
		table.insert(shoalMembers, {
			part = p,
			offsetAngle = (i / 7) * math.pi * 2,
			radial = 1.6 + (i % 3) * 0.95,
			depth = -0.35 - (i % 2) * 0.22,
			bobPhase = i * 0.85,
		})
	end
	local shoalRing = makePart(
		container,
		"ShimmerShoalRing",
		Vector3.new(0.05, 8, 8),
		Color3.fromRGB(135, 248, 255),
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
	shoalRing.Transparency = 1
	local shoalSpots = {
		Vector3.new(104, 0, -18),
		Vector3.new(98, 0, 34),
	}

	-- 4. Tide ripples expanding around the pier pilings
	local pilingRipples: { PilingRipple } = {}
	for i, pos in ipairs(findPierPilings()) do
		local ring = makePart(
			container,
			"PilingRipple" .. i,
			Vector3.new(0.04, 1.4, 1.4),
			Color3.fromRGB(215, 246, 255),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Cylinder
		)
		ring.Transparency = 0.65
		table.insert(pilingRipples, {
			ring = ring,
			pos = pos,
			phase = i * 0.55,
			period = 2.6 + (i % 3) * 0.35,
			baseRadius = 1.15,
		})
	end

	-- 5. Nighttime fireflies & crystal pulse targets
	local fireflies: { Firefly } = {}
	local fireflyAnchors = {
		Vector3.new(-14, 13.5, 8),
		Vector3.new(-36, 12.6, 1),
		Vector3.new(-22, 14.4, -20),
		Vector3.new(10, 12.8, 16),
		Vector3.new(-4, 13.2, -10),
	}
	for i = 1, 10 do
		local anchor = fireflyAnchors[1 + ((i - 1) % #fireflyAnchors)]
		local color = if i % 3 == 0
			then Color3.fromRGB(145, 245, 255)
			else Color3.fromRGB(255, 224, 120)
		local p = makePart(
			container,
			"NightFirefly" .. i,
			Vector3.new(0.18, 0.18, 0.18),
			color,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		p.Transparency = 1
		table.insert(fireflies, {
			part = p,
			anchor = anchor
				+ Vector3.new(((i % 3) - 1) * 3.5, (i % 2) * 1.4, ((i % 4) - 1.5) * 2.5),
			rx = 2.2 + (i % 3) * 0.9,
			ry = 0.7 + (i % 2) * 0.4,
			rz = 2.0 + ((i + 1) % 3) * 0.8,
			speed = 0.65 + (i % 3) * 0.18,
			phase = i * 1.37,
		})
	end

	local crystalLights: { CrystalLightTarget } = {}
	local crystalParts: { CrystalPartTarget } = {}
	collectCrystals(crystalLights, crystalParts)

	-- 6. Campfire embers & subtle warmth flicker (reuses existing Campfire PointLight)
	local campfireCenter = Vector3.new(-18, 10.7, 9)
	local embers: { EmberMote } = {}
	for i = 1, 5 do
		local color = if i % 2 == 0
			then Color3.fromRGB(255, 210, 90)
			else Color3.fromRGB(255, 130, 50)
		local p = makePart(
			container,
			"CampfireEmber" .. i,
			Vector3.new(0.14, 0.14, 0.14),
			color,
			Enum.Material.Neon,
			Enum.PartType.Ball
		)
		table.insert(embers, {
			part = p,
			phase = i * 0.43,
			speed = 0.55 + (i % 3) * 0.12,
			driftX = (i - 3) * 0.35,
			driftZ = ((i % 3) - 1) * 0.4,
		})
	end

	local campfireLight: PointLight? = nil
	local campfireBaseBrightness = 2.2
	local function findCampfireLight()
		local island = Workspace:FindFirstChild("Island")
		local campfire = island and island:FindFirstChild("Campfire")
		local emberPart = campfire and campfire:FindFirstChild("Embers")
		local pl = emberPart and emberPart:FindFirstChildOfClass("PointLight")
		if pl then
			campfireLight = pl
			campfireBaseBrightness = pl.Brightness
		end
	end
	findCampfireLight()

	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Island" then
			task.defer(function()
				collectCrystals(crystalLights, crystalParts)
				findCampfireLight()
			end)
		end
	end)

	local function restoreLightingAndCrystals()
		for _, item in crystalLights do
			if item.light.Parent then
				item.light.Brightness = item.baseBrightness
			end
		end
		for _, item in crystalParts do
			if item.part.Parent then
				item.part.Color = item.baseColor
			end
		end
		if campfireLight and campfireLight.Parent then
			campfireLight.Brightness = campfireBaseBrightness
		end
	end

	local function step()
		local t = os.clock()
		local night = isNightOrDarkEvent()

		-- Seagulls: alternate rhythmic wingbeats with brief coastal glides
		for _, g in gulls do
			local angle = t * g.speed + g.phase
			local x = g.center.X + math.cos(angle) * g.radius
			local z = g.center.Z + math.sin(angle) * g.radius
			local y = g.center.Y + math.sin(t * 0.9 + g.phase) * 1.4
			local vx = -math.sin(angle)
			local vz = math.cos(angle)
			local cf = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(x + vx, y, z + vz))
				* CFrame.Angles(0, 0, math.rad(10))
			g.body.CFrame = cf
			g.beak.CFrame = cf * CFrame.new(0, -0.02, -0.88)
			local glideBlend = 0.5 + 0.5 * math.sin(t * 0.75 + g.phase)
			local flap = math.sin(t * g.flapSpeed + g.phase) * (0.14 + 0.36 * glideBlend)
			g.leftWing.CFrame = cf * CFrame.new(-0.92, 0.1, 0) * CFrame.Angles(0, 0, -flap)
			g.rightWing.CFrame = cf * CFrame.new(0.92, 0.1, 0) * CFrame.Angles(0, 0, flap)
		end

		-- Open-sea jumping fish
		for _, j in jumpers do
			local cycle = (t + j.phase) % j.period
			if cycle < j.duration then
				local u = cycle / j.duration
				local arc = 4 * u * (1 - u)
				local along = (u - 0.5) * j.span
				local dir = Vector3.new(math.cos(j.heading), 0, math.sin(j.heading))
				local y = SEA_Y + j.height * arc - 0.65
				local pos = j.center + dir * along + Vector3.new(0, y, 0)
				local slope = 4 * j.height * (1 - 2 * u) / j.duration
				local pitch = math.clamp(math.atan2(slope, j.span / j.duration), -1.05, 1.05)
				local cf = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(pitch, 0, 0)
				j.body.Transparency = 0
				j.tail.Transparency = 0
				j.body.CFrame = cf
				j.tail.CFrame = cf * CFrame.new(0, 0, 0.72) * CFrame.Angles(0, 0, math.rad(90))

				-- Splash ring at breach (u ~ 0.1) and dive (u ~ 0.9)
				local splashAge: number? = nil
				local splashPos: Vector3? = nil
				if u < 0.38 then
					splashAge = u / 0.38
					splashPos = j.center + dir * (-0.36 * j.span)
				elseif u > 0.72 then
					splashAge = (u - 0.72) / 0.28
					splashPos = j.center + dir * (0.36 * j.span)
				end
				if splashAge and splashPos then
					local diam = 1.1 + splashAge * 3.2
					j.ring.Size = Vector3.new(0.05, diam, diam)
					j.ring.CFrame = CFrame.new(splashPos.X, SEA_Y + 0.05, splashPos.Z)
						* CFrame.Angles(0, 0, math.rad(90))
					j.ring.Transparency = 0.25 + splashAge * 0.75
				else
					j.ring.Transparency = 1
				end
			else
				j.body.Transparency = 1
				j.tail.Transparency = 1
				j.ring.Transparency = 1
			end
		end

		-- Occasional shimmering shoal (appears 9 s every 22 s)
		local shoalPeriod = 22
		local shoalDuration = 9
		local shoalIndex = math.floor(t / shoalPeriod)
		local shoalTime = t % shoalPeriod
		if shoalTime < shoalDuration then
			local spot = shoalSpots[1 + (shoalIndex % #shoalSpots)]
			local env = math.sin((shoalTime / shoalDuration) * math.pi)
			local fade = math.clamp(env * 2.4, 0, 1)
			local centerAngle = shoalTime * 0.55
			local centerPos = spot
				+ Vector3.new(math.cos(centerAngle) * 3.5, 0, math.sin(centerAngle) * 2.5)
			for _, m in shoalMembers do
				local a = centerAngle * 1.4 + m.offsetAngle
				local px = centerPos.X + math.cos(a) * m.radial
				local pz = centerPos.Z + math.sin(a) * m.radial
				local py = m.depth + math.sin(t * 3.2 + m.bobPhase) * 0.18
				local vx = -math.sin(a)
				local vz = math.cos(a)
				m.part.Transparency = 1 - fade * 0.92
				m.part.CFrame =
					CFrame.lookAt(Vector3.new(px, py, pz), Vector3.new(px + vx, py, pz + vz))
			end
			local ringPulse = 6.5 + math.sin(t * 2.2) * 1.1
			shoalRing.Size = Vector3.new(0.04, ringPulse, ringPulse)
			shoalRing.CFrame = CFrame.new(centerPos.X, SEA_Y + 0.04, centerPos.Z)
				* CFrame.Angles(0, 0, math.rad(90))
			shoalRing.Transparency = 1 - fade * 0.38
		else
			for _, m in shoalMembers do
				m.part.Transparency = 1
			end
			shoalRing.Transparency = 1
		end

		-- Pier piling water ripples
		for _, r in pilingRipples do
			local u = ((t + r.phase) % r.period) / r.period
			local diam = r.baseRadius + u * 1.75
			r.ring.Size = Vector3.new(0.04, diam, diam)
			r.ring.CFrame = CFrame.new(r.pos) * CFrame.Angles(0, 0, math.rad(90))
			r.ring.Transparency = 0.45 + u * 0.55
		end

		-- Night fireflies
		local fireflyAlpha = if night then 1 else 0
		for _, f in fireflies do
			if fireflyAlpha > 0 then
				local px = f.anchor.X + math.sin(t * f.speed + f.phase) * f.rx
				local py = f.anchor.Y + math.sin(t * f.speed * 1.7 + f.phase) * f.ry
				local pz = f.anchor.Z + math.cos(t * f.speed * 0.9 + f.phase) * f.rz
				local twinkle = 0.5 + 0.5 * math.sin(t * 3.5 + f.phase * 2)
				f.part.CFrame = CFrame.new(px, py, pz)
				f.part.Transparency = 0.15 + (1 - twinkle) * 0.65
			else
				f.part.Transparency = 1
			end
		end

		-- Crystal pulse (gentle shimmer by day, deeper breath at night)
		local pulseAmp = if night then 0.28 else 0.08
		for _, item in crystalLights do
			if item.light.Parent then
				item.light.Brightness = item.baseBrightness
					* (1 + math.sin(t * 1.6 + item.phase) * pulseAmp)
			end
		end
		local colorShift = if night then 0.22 else 0.07
		for _, item in crystalParts do
			if item.part.Parent then
				local w = 0.5 + 0.5 * math.sin(t * 1.5 + item.phase)
				item.part.Color = item.baseColor:Lerp(Color3.new(1, 1, 1), w * colorShift)
			end
		end

		-- Campfire ember motes & gentle flame light pulse
		for _, e in embers do
			local u = ((t * e.speed + e.phase) % 1)
			local py = campfireCenter.Y + 0.4 + u * 3.8
			local px = campfireCenter.X + e.driftX * u + math.sin(t * 2.4 + e.phase * 6) * 0.28
			local pz = campfireCenter.Z + e.driftZ * u + math.cos(t * 2.1 + e.phase * 5) * 0.28
			e.part.CFrame = CFrame.new(px, py, pz)
			e.part.Transparency = if u < 0.2 then (1 - u / 0.2) * 0.8 else (u - 0.2) / 0.8
		end
		if campfireLight and campfireLight.Parent then
			local boost = if night then 1.25 else 1.0
			campfireLight.Brightness = campfireBaseBrightness
				* boost
				* (0.9 + 0.14 * math.sin(t * 7.5) + 0.08 * math.cos(t * 13.1))
		end
	end

	local player = Players.LocalPlayer
	local conn: RBXScriptConnection? = nil

	local function syncEffects()
		local reduced = player:GetAttribute("ReduceEffects") == true
		if reduced then
			if conn then
				conn:Disconnect()
				conn = nil
			end
			container.Parent = nil
			restoreLightingAndCrystals()
		else
			container.Parent = Workspace
			if not conn then
				conn = RunService.Heartbeat:Connect(step)
			end
		end
	end

	syncEffects()
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(syncEffects)
end

return Ambient
