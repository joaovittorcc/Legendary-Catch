--!strict
-- TrainingIslandsBuilder.luau
-- Builds Training Islands 2, 3, and 4 far from the hub + clean outbound hub portals:
--   * Island 2: TrainingIsland_Reef      (x3,  100K PP) at (480, 12, 420)
--   * Island 3: TrainingIsland_Abyss     (x12, 100M PP) at (-520, 12, 420)
--   * Island 4: TrainingIsland_Celestial (x50, 1T PP)   at (0, 160, -680)
--   * Hub outbound portals in Workspace.TrainingPortalsHub (self-contained, non-intrusive)
--
-- Follows docs/prompts-antigravity/CAMPO-TREINO-E-ILHAS.md §5 & fwjelaa worldbuilding rules:
--   * Each island leaves a flat, walkable ~34-stud radius around TrainingSpot so all 10 levels
--     of ReplicatedStorage.TrainingLevels fit cleanly without clipping.
--   * Anchored TrainingSpot part with Tag = "TrainingSpot" and TrainingIsland = 2 | 3 | 4.
--   * ModelStreamingMode = Persistent ONLY on PersistentTrainingSpot and PersistentSpawn.
--   * Round-trip portals using existing ZonePortal / ZoneSpawn system (no src/** edits needed).
--   * SmoothPlastic water/aurora (never Glass), CastShadow=false on decor/Neon, zero z-fighting.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local TAG_BUILT = "TrainingIslandsBuilder"

local PALETTE = {
	sand = Color3.fromRGB(242, 220, 168),
	sandWarm = Color3.fromRGB(228, 198, 142),
	turquoise = Color3.fromRGB(64, 214, 218),
	turquoiseLight = Color3.fromRGB(118, 238, 240),
	coralPink = Color3.fromRGB(255, 118, 164),
	coralOrange = Color3.fromRGB(255, 148, 86),
	coralMagenta = Color3.fromRGB(226, 94, 206),
	anemoneTeal = Color3.fromRGB(72, 224, 178),
	pearl = Color3.fromRGB(248, 242, 255),
	shellPink = Color3.fromRGB(248, 186, 206),
	limestone = Color3.fromRGB(224, 216, 196),

	basalt = Color3.fromRGB(40, 44, 62),
	obsidian = Color3.fromRGB(28, 32, 48),
	slate = Color3.fromRGB(66, 74, 98),
	abyssSea = Color3.fromRGB(26, 52, 98),
	cyan = Color3.fromRGB(82, 228, 255),
	cyanDeep = Color3.fromRGB(44, 152, 232),
	violet = Color3.fromRGB(168, 108, 255),
	starWhite = Color3.fromRGB(238, 246, 255),

	marble = Color3.fromRGB(244, 242, 250),
	gold = Color3.fromRGB(248, 198, 76),
	goldBright = Color3.fromRGB(255, 228, 124),
	cloudWhite = Color3.fromRGB(246, 248, 255),
	cloudTint = Color3.fromRGB(216, 232, 255),
	pink = Color3.fromRGB(255, 126, 202),
	teal = Color3.fromRGB(88, 232, 196),
	woodWarm = Color3.fromRGB(154, 104, 62),
	woodDark = Color3.fromRGB(94, 60, 36),
}

local ISLAND_CENTERS = {
	reef = Vector3.new(480, 12, 420),
	abyss = Vector3.new(-520, 12, 420),
	celestial = Vector3.new(0, 160, -680),
}

local function addPart(
	parent: Instance,
	origin: CFrame,
	name: string,
	size: Vector3,
	localCF: CFrame,
	color: Color3,
	material: Enum.Material?,
	opts: {
		shape: Enum.PartType?,
		transparency: number?,
		canCollide: boolean?,
		castShadow: boolean?,
	}?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = origin * localCF
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts then
		if opts.shape then
			p.Shape = opts.shape
		end
		if opts.transparency then
			p.Transparency = opts.transparency
		end
	end
	local collide = opts ~= nil and opts.canCollide == true
	p.CanCollide = collide
	p.CanQuery = collide
	p.CanTouch = false
	p.CastShadow = opts ~= nil and opts.castShadow == true
	p.Parent = parent
	return p
end

local function addCyl(
	parent: Instance,
	origin: CFrame,
	name: string,
	height: number,
	diameter: number,
	x: number,
	centerY: number,
	z: number,
	color: Color3,
	material: Enum.Material?,
	opts: { transparency: number?, canCollide: boolean?, castShadow: boolean? }?
): Part
	return addPart(
		parent,
		origin,
		name,
		Vector3.new(height, diameter, diameter),
		CFrame.new(x, centerY, z) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material,
		{
			shape = Enum.PartType.Cylinder,
			transparency = if opts then opts.transparency else nil,
			canCollide = if opts then opts.canCollide else nil,
			castShadow = if opts then opts.castShadow else nil,
		}
	)
end

local function addLight(
	parent: BasePart,
	color: Color3,
	brightness: number,
	range: number
): PointLight
	local l = Instance.new("PointLight")
	l.Name = "IslandLight"
	l.Color = color
	l.Brightness = brightness
	l.Range = math.min(range, 60)
	l.Shadows = false
	l.Parent = parent
	return l
end

local function addEmitter(
	parent: BasePart,
	name: string,
	colorA: Color3,
	colorB: Color3,
	rate: number,
	speedMin: number,
	speedMax: number,
	sizeStart: number,
	sizeEnd: number,
	lifeMin: number,
	lifeMax: number,
	spread: number?
): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Color = ColorSequence.new(colorA, colorB)
	e.LightEmission = 0.75
	e.Rate = rate
	e.Speed = NumberRange.new(speedMin, speedMax)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sizeStart),
		NumberSequenceKeypoint.new(1, sizeEnd),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Lifetime = NumberRange.new(lifeMin, lifeMax)
	e.SpreadAngle = Vector2.new(spread or 35, spread or 35)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = parent
	return e
end

local function buildRingSegments(
	parent: Instance,
	origin: CFrame,
	name: string,
	centerCF: CFrame,
	radius: number,
	segments: number,
	thickness: number,
	height: number,
	colorA: Color3,
	colorB: Color3,
	material: Enum.Material
)
	local step = (math.pi * 2) / segments
	local segLen = 2 * radius * math.sin(step * 0.5) * 0.94
	for i = 0, segments - 1 do
		local ang = (i + 0.5) * step
		local x = math.sin(ang) * radius
		local z = math.cos(ang) * radius
		local yOff = (i % 2) * 0.05
		addPart(
			parent,
			origin,
			name .. "_" .. tostring(i + 1),
			Vector3.new(segLen, height, thickness),
			centerCF * CFrame.new(x, yOff, z) * CFrame.Angles(0, ang, 0),
			if i % 2 == 0 then colorA else colorB,
			material
		)
	end
end

-- Stylized ZonePortal model matching src/server/Features/Portals & src/client/Features/Portals.
-- Uses "Subtitle" (not "Status") on the sign so client Portals doesn't overwrite PP labels.
local function buildPortal(
	parent: Instance,
	worldCF: CFrame,
	spec: {
		modelName: string,
		portalId: string,
		destination: string,
		zoneId: string,
		title: string,
		subtitle: string,
		primaryColor: Color3,
		accentColor: Color3,
		frameColor: Color3,
		frameMat: Enum.Material,
		trainingIsland: number?,
	}
): Model
	local m = Instance.new("Model")
	m.Name = spec.modelName
	m:SetAttribute("GeneratedBy", TAG_BUILT)

	-- Low walkable threshold plinth
	addPart(
		m,
		worldCF,
		"PortalBase",
		Vector3.new(10.6, 0.36, 4.2),
		CFrame.new(0, 0.18, 0),
		spec.frameColor,
		spec.frameMat,
		{ canCollide = true, castShadow = true }
	)
	-- Left & right sculpted pillars + top arch bar + crystal keystone
	for _, sgn in { -1, 1 } do
		addPart(
			m,
			worldCF,
			if sgn < 0 then "PillarL" else "PillarR",
			Vector3.new(1.55, 10.6, 1.85),
			CFrame.new(sgn * 4.4, 6.1, 0),
			spec.frameColor,
			spec.frameMat,
			{ castShadow = true }
		)
		addPart(
			m,
			worldCF,
			if sgn < 0 then "TrimL" else "TrimR",
			Vector3.new(0.45, 8.6, 2.05),
			CFrame.new(sgn * 3.55, 6.1, 0),
			spec.primaryColor,
			Enum.Material.Neon
		)
	end
	addPart(
		m,
		worldCF,
		"ArchTop",
		Vector3.new(11.4, 1.55, 2.2),
		CFrame.new(0, 11.9, 0),
		spec.frameColor,
		spec.frameMat,
		{ castShadow = true }
	)
	addPart(
		m,
		worldCF,
		"ArchKeystone",
		Vector3.new(1.8, 2.2, 1.8),
		CFrame.new(0, 13.4, 0) * CFrame.Angles(0, math.rad(45), 0),
		spec.accentColor,
		Enum.Material.Neon
	)

	-- Spinning PortalRing (animated by client Features/Portals when unlocked)
	local ring = Instance.new("Model")
	ring.Name = "PortalRing"
	ring.Parent = m
	local ringPivot = addPart(
		ring,
		worldCF,
		"RingPivot",
		Vector3.new(0.5, 0.5, 0.5),
		CFrame.new(0, 6.2, 0),
		spec.primaryColor,
		Enum.Material.SmoothPlastic,
		{ transparency = 1 }
	)
	ring.PrimaryPart = ringPivot
	ring.WorldPivot = ringPivot.CFrame
	local segs = 12
	local r = 3.65
	for i = 0, segs - 1 do
		local ang = (i / segs) * math.pi * 2
		local x = math.cos(ang) * r
		local y = math.sin(ang) * r
		addPart(
			ring,
			worldCF,
			"RingSeg_" .. tostring(i + 1),
			Vector3.new(1.35, 0.34, 0.34),
			CFrame.new(x, 6.2 + y, (i % 2) * 0.05) * CFrame.Angles(0, 0, ang + math.rad(90)),
			if i % 2 == 0 then spec.primaryColor else spec.accentColor,
			Enum.Material.Neon
		)
	end

	-- PortalCore vortex + PointLight + ParticleEmitter
	local core = addPart(
		m,
		worldCF,
		"PortalCore",
		Vector3.new(6.8, 9.6, 0.35),
		CFrame.new(0, 6.1, 0),
		spec.primaryColor,
		Enum.Material.Neon,
		{ transparency = 0.42 }
	)
	addLight(core, spec.primaryColor, 1.4, 28)
	addEmitter(
		core,
		"PortalParticles",
		spec.primaryColor,
		spec.accentColor,
		8,
		1.0,
		2.5,
		0.38,
		0.06,
		1.2,
		2.0,
		50
	)

	-- PortalTrigger (tagged ZonePortal!)
	local trigger = addPart(
		m,
		worldCF,
		"PortalTrigger",
		Vector3.new(7.2, 9.4, 4.8),
		CFrame.new(0, 5.4, 0),
		spec.primaryColor,
		Enum.Material.SmoothPlastic,
		{ transparency = 1 }
	)
	trigger.CanTouch = true
	trigger.CanQuery = true
	trigger:SetAttribute("PortalId", spec.portalId)
	trigger:SetAttribute("ZoneId", spec.zoneId)
	trigger:SetAttribute("Destination", spec.destination)
	trigger:SetAttribute("PrimaryColor", spec.primaryColor)
	trigger:SetAttribute("AccentColor", spec.accentColor)
	if spec.trainingIsland then
		trigger:SetAttribute("TrainingIsland", spec.trainingIsland)
	end
	CollectionService:AddTag(trigger, "ZonePortal")

	-- Double-sided overhead PortalSignBoard
	local board = addPart(
		m,
		worldCF,
		"PortalSignBoard",
		Vector3.new(9.6, 2.5, 0.45),
		CFrame.new(0, 15.6, 0),
		PALETTE.obsidian,
		Enum.Material.SmoothPlastic
	)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local sg = Instance.new("SurfaceGui")
		sg.Name = if face == Enum.NormalId.Front then "PortalSignGui" else "PortalSignGuiBack"
		sg.Face = face
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 50
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent = board

		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(18, 26, 46)
		bg.BorderSizePixel = 0
		bg.Parent = sg

		local stroke = Instance.new("UIStroke")
		stroke.Name = "SignStroke"
		stroke.Thickness = 4
		stroke.Color = spec.primaryColor
		stroke.Parent = bg

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.fromScale(0.94, 0.54)
		title.Position = UDim2.fromScale(0.03, 0.06)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.FredokaOne
		title.Text = spec.title
		title.TextColor3 = Color3.fromRGB(255, 255, 255)
		title.TextScaled = true
		title.Parent = bg

		local sub = Instance.new("TextLabel")
		sub.Name = "Subtitle"
		sub.Size = UDim2.fromScale(0.92, 0.36)
		sub.Position = UDim2.fromScale(0.04, 0.58)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.FredokaOne
		sub.Text = spec.subtitle
		sub.TextColor3 = spec.accentColor
		sub.TextScaled = true
		sub.Parent = bg
	end

	m.WorldPivot = worldCF
	m.Parent = parent
	return m
end

-- Creates PersistentTrainingSpot (with TrainingSpot tag + TrainingIsland attr)
-- and PersistentSpawn (with 2 ZoneSpawn pads + safe persistent floor pad).
local function buildPersistentCore(
	islandModel: Model,
	origin: CFrame,
	islandIndex: number,
	destination: string,
	padColor: Color3,
	padMat: Enum.Material,
	ringColor: Color3
)
	-- 1. Persistent TrainingSpot
	local spotModel = Instance.new("Model")
	spotModel.Name = "PersistentTrainingSpot"
	spotModel.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	spotModel.Parent = islandModel

	local spot = addPart(
		spotModel,
		origin,
		"TrainingSpot",
		Vector3.new(8, 1.0, 8),
		CFrame.new(0, 0.5, 0),
		ringColor,
		Enum.Material.SmoothPlastic,
		{ transparency = 1 }
	)
	spot:SetAttribute("TrainingIsland", islandIndex)
	CollectionService:AddTag(spot, "TrainingSpot")

	-- Subtle non-collidable ring marker showing exact spot center
	addCyl(
		spotModel,
		origin,
		"TrainingSpotRing",
		0.12,
		7.2,
		0,
		0.07,
		0,
		ringColor,
		Enum.Material.Neon,
		{ transparency = 0.35 }
	)
	-- Small persistent walkable disc right under the spot
	addCyl(
		spotModel,
		origin,
		"TrainingSpotPad",
		0.6,
		10.0,
		0,
		-0.31,
		0,
		padColor,
		padMat,
		{ canCollide = true }
	)
	spotModel.PrimaryPart = spot
	spotModel.WorldPivot = spot.CFrame

	-- 2. Persistent Spawn + Landing Pad (at local Z = +42 facing -Z toward TrainingSpot!)
	local spawnModel = Instance.new("Model")
	spawnModel.Name = "PersistentSpawn"
	spawnModel.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	spawnModel.Parent = islandModel

	addPart(
		spawnModel,
		origin,
		"SpawnLandingPad",
		Vector3.new(16, 1.2, 12),
		CFrame.new(0, -0.62, 42),
		padColor,
		padMat,
		{ canCollide = true }
	)
	for i, xOff in { -3.2, 3.2 } do
		local sp = addPart(
			spawnModel,
			origin,
			"ZoneSpawn_" .. destination .. "_" .. tostring(i),
			Vector3.new(3.5, 0.5, 3.5),
			CFrame.lookAt(Vector3.new(xOff, 0.25, 42), Vector3.new(xOff, 0.25, 0)),
			ringColor,
			Enum.Material.SmoothPlastic,
			{ transparency = 1 }
		)
		sp:SetAttribute("Destination", destination)
		sp:SetAttribute("TrainingIsland", islandIndex)
		CollectionService:AddTag(sp, "ZoneSpawn")
	end
	spawnModel.WorldPivot = origin * CFrame.new(0, 0, 42)
end

-- Invisible safety barrier polygon around an island edge so players never fall into void.
-- Optional `openFrontDeg` skips segments near +Z (where the arrival promenade connects).
local function buildSafetyBarrier(
	parent: Instance,
	origin: CFrame,
	radius: number,
	sides: number,
	height: number,
	openFrontDeg: number?
)
	local step = (math.pi * 2) / sides
	local len = 2 * radius * math.sin(step * 0.5) + 1.5
	local skipRad = if openFrontDeg then math.rad(openFrontDeg) else 0
	for i = 0, sides - 1 do
		local ang = (i + 0.5) * step
		-- Distance from +Z axis (ang = 0 or 2*pi)
		local frontDelta = math.min(ang, math.pi * 2 - ang)
		if skipRad > 0 and frontDelta < skipRad then
			continue
		end
		local x = math.sin(ang) * radius
		local z = math.cos(ang) * radius
		addPart(
			parent,
			origin,
			"SafetyWall_" .. tostring(i + 1),
			Vector3.new(len, height, 1.5),
			CFrame.new(x, height * 0.45, z) * CFrame.Angles(0, ang, 0),
			PALETTE.cyan,
			Enum.Material.SmoothPlastic,
			{ transparency = 1, canCollide = true }
		)
	end
end

-- Island 2: Ilha do Recife (x3, 100K PP) ------------------------------------------------
local function buildReefIsland(): Model
	local origin = CFrame.new(ISLAND_CENTERS.reef)
	local model = Instance.new("Model")
	model.Name = "TrainingIsland_Reef"
	model:SetAttribute("GeneratedBy", TAG_BUILT)
	model:SetAttribute("TrainingIsland", 2)

	local ground = Instance.new("Model")
	ground.Name = "IslandGround"
	ground.Parent = model
	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = model

	-- Shallow turquoise lagoon shelf + sandy seabed + flat 35-stud walkable atoll arena
	addCyl(
		ground,
		origin,
		"ReefSeabed",
		2.4,
		136,
		0,
		-4.6,
		10,
		PALETTE.sandWarm,
		Enum.Material.Sand,
		{ canCollide = true }
	)
	addCyl(
		ground,
		origin,
		"ShallowTurquoiseWater",
		1.2,
		130,
		0,
		-1.9,
		10,
		PALETTE.turquoise,
		Enum.Material.SmoothPlastic,
		{ transparency = 0.28 }
	)
	addCyl(
		ground,
		origin,
		"ReefBeachOuter",
		2.2,
		82,
		0,
		-1.35,
		4,
		PALETTE.sandWarm,
		Enum.Material.Sand,
		{ canCollide = true }
	)
	-- Main flat 34-stud radius training plateau (Y top = 0.0)
	addCyl(
		ground,
		origin,
		"TrainingPlateau",
		1.6,
		69.0,
		0,
		-0.8,
		0,
		PALETTE.sand,
		Enum.Material.Sand,
		{ canCollide = true }
	)
	-- Limestone decorative border ring outside the 30-stud training radius
	buildRingSegments(
		decor,
		origin,
		"ReefStoneRim",
		CFrame.new(0, 0.14, 0),
		33.8,
		20,
		1.3,
		0.28,
		PALETTE.limestone,
		PALETTE.shellPink,
		Enum.Material.Limestone
	)
	-- Wide walkable arrival promenade from Z = +30 to Z = +54
	addPart(
		ground,
		origin,
		"ArrivalPromenade",
		Vector3.new(26, 1.6, 26),
		CFrame.new(0, -0.82, 41),
		PALETTE.sand,
		Enum.Material.Sand,
		{ canCollide = true }
	)
	addPart(
		ground,
		origin,
		"PromenadeTimberWalk",
		Vector3.new(10.5, 0.22, 18.0),
		CFrame.new(0, -0.02, 33),
		PALETTE.woodWarm,
		Enum.Material.WoodPlanks,
		{ canCollide = true }
	)

	-- Persistent TrainingSpot (TrainingIsland = 2) + Persistent Spawn
	buildPersistentCore(
		model,
		origin,
		2,
		"training_reef",
		PALETTE.sand,
		Enum.Material.Sand,
		PALETTE.turquoiseLight
	)

	-- Hero Landmark behind -Z: Giant Fluted Scallop Shell Monument + Glowing Iridescent Pearl!
	local hx, hz = 0, -40.5
	addCyl(
		decor,
		origin,
		"HeroShellPlinth",
		3.6,
		20.0,
		hx,
		1.4,
		hz,
		PALETTE.limestone,
		Enum.Material.Limestone,
		{ castShadow = true }
	)
	-- 7 Fan-arranged fluted shell ribs rising 24 studs high
	for i = -3, 3 do
		local fanAng = math.rad(i * 15)
		local ribH = 22.0 - math.abs(i) * 2.2
		addPart(
			decor,
			origin,
			"HeroShellRib_" .. tostring(i + 4),
			Vector3.new(2.8, ribH, 2.2),
			CFrame.new(hx + math.sin(fanAng) * 5.2, 3.0 + ribH * 0.45, hz - 3.0)
				* CFrame.Angles(math.rad(-14), 0, -fanAng),
			if i % 2 == 0 then PALETTE.shellPink else PALETTE.coralPink,
			Enum.Material.SmoothPlastic,
			{ castShadow = true }
		)
	end
	local heroPearl = addPart(
		decor,
		origin,
		"HeroGiantPearl",
		Vector3.new(7.4, 7.4, 7.4),
		CFrame.new(hx, 8.2, hz + 1.2),
		PALETTE.pearl,
		Enum.Material.Neon,
		{ shape = Enum.PartType.Ball }
	)
	addLight(heroPearl, PALETTE.turquoiseLight, 1.9, 55)
	addEmitter(
		heroPearl,
		"PearlBubbles",
		PALETTE.turquoiseLight,
		PALETTE.coralPink,
		10,
		1.4,
		3.2,
		0.55,
		0.1,
		2.0,
		3.4,
		60
	)

	-- 2 Flanking Giant Conch / Shell Alcoves at (-36, -24) and (+36, -24)
	for idx, sgn in { -1, 1 } do
		local sx, sz = sgn * 36.5, -21.0
		addPart(
			decor,
			origin,
			"GiantShell_" .. tostring(idx),
			Vector3.new(9.5, 8.5, 7.5),
			CFrame.new(sx, 3.8, sz) * CFrame.Angles(math.rad(-18), math.rad(sgn * -36), 0),
			PALETTE.shellPink,
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Ball }
		)
		addPart(
			decor,
			origin,
			"SidePearl_" .. tostring(idx),
			Vector3.new(3.4, 3.4, 3.4),
			CFrame.new(sx - sgn * 1.4, 3.2, sz + 2.2),
			PALETTE.pearl,
			Enum.Material.Neon,
			{ shape = Enum.PartType.Ball }
		)
	end

	-- 10 Giant Stylized Branching Coral Formations around outer rim (r = 38..48, zero arena clipping!)
	local coralColors = {
		PALETTE.coralPink,
		PALETTE.coralOrange,
		PALETTE.coralMagenta,
		PALETTE.turquoiseLight,
	}
	local coralAngles = { 54, 82, 112, 146, 166, 194, 214, 248, 278, 306 }
	for i, deg in coralAngles do
		local ang = math.rad(deg)
		local r = 39.5 + (i % 3) * 3.2
		local cx = math.sin(ang) * r
		local cz = math.cos(ang) * r
		local col = coralColors[(i % #coralColors) + 1]
		local h = 8.5 + (i % 3) * 3.4
		addCyl(
			decor,
			origin,
			"CoralTrunk_" .. tostring(i),
			h,
			2.6,
			cx,
			h * 0.42 - 0.8,
			cz,
			col,
			Enum.Material.SmoothPlastic
		)
		-- Two coral branches
		addPart(
			decor,
			origin,
			"CoralBranchA_" .. tostring(i),
			Vector3.new(1.5, h * 0.62, 1.5),
			CFrame.new(cx + 1.8, h * 0.56, cz) * CFrame.Angles(math.rad(12), ang, math.rad(-32)),
			col,
			Enum.Material.SmoothPlastic
		)
		addPart(
			decor,
			origin,
			"CoralBranchB_" .. tostring(i),
			Vector3.new(1.4, h * 0.55, 1.4),
			CFrame.new(cx - 1.6, h * 0.48, cz + 0.8)
				* CFrame.Angles(math.rad(-14), ang, math.rad(28)),
			PALETTE.coralPink,
			Enum.Material.SmoothPlastic
		)
	end

	-- 8 Glowing Anemone Carpets nestled in the shallow turquoise rim
	for i = 0, 7 do
		local ang = math.rad(i * 42 + 34)
		local r = 35.8
		local ax, az = math.sin(ang) * r, math.cos(ang) * r
		addCyl(
			decor,
			origin,
			"AnemoneCarpet_" .. tostring(i + 1),
			0.55,
			5.4,
			ax,
			-0.25,
			az,
			if i % 2 == 0 then PALETTE.anemoneTeal else PALETTE.coralMagenta,
			Enum.Material.Neon,
			{ transparency = 0.25 }
		)
	end

	-- Return Portal to Main Hub on the right side of the arrival promenade
	buildPortal(model, origin * CFrame.new(11.5, 0, 44) * CFrame.Angles(0, math.rad(-26), 0), {
		modelName = "Portal_Return_Main",
		portalId = "training_reef_to_main",
		destination = "main",
		zoneId = "lagoon",
		title = "VOLTAR AO HUB",
		subtitle = "Ilha Principal",
		primaryColor = PALETTE.turquoiseLight,
		accentColor = PALETTE.coralPink,
		frameColor = PALETTE.limestone,
		frameMat = Enum.Material.Limestone,
	})

	buildSafetyBarrier(ground, origin, 58, 16, 18)

	model.WorldPivot = origin
	model.Parent = Workspace
	return model
end

-- Island 3: Ilha Abismo Estelar (x12, 100M PP) -----------------------------------------
local function buildAbyssIsland(): Model
	local origin = CFrame.new(ISLAND_CENTERS.abyss)
	local model = Instance.new("Model")
	model.Name = "TrainingIsland_Abyss"
	model:SetAttribute("GeneratedBy", TAG_BUILT)
	model:SetAttribute("TrainingIsland", 3)

	local ground = Instance.new("Model")
	ground.Name = "IslandGround"
	ground.Parent = model
	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = model

	-- Deep luminous astral sea collar + dark volcanic basalt shelf + flat 34-stud obsidian arena
	addCyl(
		ground,
		origin,
		"AbyssAstralSea",
		1.4,
		136,
		0,
		-2.4,
		10,
		PALETTE.abyssSea,
		Enum.Material.SmoothPlastic,
		{ transparency = 0.18 }
	)
	addCyl(
		ground,
		origin,
		"AbyssVolcanicBase",
		2.8,
		84,
		0,
		-1.7,
		4,
		PALETTE.basalt,
		Enum.Material.Rock,
		{ canCollide = true }
	)
	addCyl(
		ground,
		origin,
		"TrainingPlateau",
		1.6,
		69.0,
		0,
		-0.8,
		0,
		PALETTE.obsidian,
		Enum.Material.Slate,
		{ canCollide = true }
	)
	-- Glowing star-constellation ring around outer perimeter (r = 33.8)
	buildRingSegments(
		decor,
		origin,
		"AbyssStarRing",
		CFrame.new(0, 0.12, 0),
		33.8,
		20,
		0.72,
		0.14,
		PALETTE.cyan,
		PALETTE.violet,
		Enum.Material.Neon
	)
	-- Arrival obsidian causeway
	addPart(
		ground,
		origin,
		"ArrivalPromenade",
		Vector3.new(26, 1.6, 26),
		CFrame.new(0, -0.82, 41),
		PALETTE.basalt,
		Enum.Material.Slate,
		{ canCollide = true }
	)
	addPart(
		ground,
		origin,
		"StarWalkInlay",
		Vector3.new(9.2, 0.18, 18.0),
		CFrame.new(0, 0.01, 33),
		PALETTE.slate,
		Enum.Material.SmoothPlastic,
		{ canCollide = true }
	)

	-- Persistent TrainingSpot (TrainingIsland = 3) + Persistent Spawn
	buildPersistentCore(
		model,
		origin,
		3,
		"training_abyss",
		PALETTE.obsidian,
		Enum.Material.Slate,
		PALETTE.cyan
	)

	-- Hero Landmark behind -Z: Twin Giant Blue Crystal Cathedrals + Levitating Astral Star Orb!
	for idx, sgn in { -1, 1 } do
		local sx, sz = sgn * 12.5, -41.0
		-- Craggy dark basalt mountain base
		addPart(
			decor,
			origin,
			"AbyssCrag_" .. tostring(idx),
			Vector3.new(16, 14, 14),
			CFrame.new(sx, 5.2, sz) * CFrame.Angles(0, math.rad(sgn * 22), math.rad(sgn * -6)),
			PALETTE.basalt,
			Enum.Material.Rock,
			{ castShadow = true }
		)
		-- Soaring primary crystal spire (~34 studs tall)
		addPart(
			decor,
			origin,
			"HeroCrystalSpire_" .. tostring(idx),
			Vector3.new(4.8, 32.0, 4.8),
			CFrame.new(sx - sgn * 1.2, 18.5, sz + 1.5)
				* CFrame.Angles(math.rad(8), math.rad(45), math.rad(sgn * 14)),
			PALETTE.cyan,
			Enum.Material.Neon
		)
		-- Flanking deep-blue & violet sub-spires
		addPart(
			decor,
			origin,
			"HeroCrystalSub_" .. tostring(idx),
			Vector3.new(3.2, 20.0, 3.2),
			CFrame.new(sx + sgn * 4.6, 12.0, sz + 3.2)
				* CFrame.Angles(math.rad(14), math.rad(20), math.rad(sgn * -24)),
			PALETTE.violet,
			Enum.Material.Neon
		)
	end
	-- Levitating Astral Star Core + Orbital Halo between the Twin Spires!
	local starOrb = addPart(
		decor,
		origin,
		"AbyssStarCore",
		Vector3.new(6.8, 6.8, 6.8),
		CFrame.new(0, 24.5, -39.5),
		PALETTE.cyan,
		Enum.Material.Neon,
		{ shape = Enum.PartType.Ball }
	)
	addLight(starOrb, PALETTE.cyan, 2.0, 60)
	addEmitter(
		starOrb,
		"StarlightMist",
		PALETTE.cyan,
		PALETTE.violet,
		14,
		1.2,
		3.6,
		0.72,
		0.1,
		2.0,
		3.6,
		75
	)
	buildRingSegments(
		decor,
		origin,
		"AbyssStarHalo",
		CFrame.new(0, 24.5, -39.5) * CFrame.Angles(math.rad(68), math.rad(12), 0),
		10.5,
		14,
		0.65,
		0.65,
		PALETTE.goldBright,
		PALETTE.cyan,
		Enum.Material.Neon
	)

	-- 10 Perimeter Dark Crags + Giant Blue Crystal Clusters (r = 39..47)
	local cragAngles = { 50, 82, 114, 146, 214, 246, 278, 310 }
	for i, deg in cragAngles do
		local ang = math.rad(deg)
		local r = 40.5 + (i % 2) * 3.0
		local rx, rz = math.sin(ang) * r, math.cos(ang) * r
		addPart(
			decor,
			origin,
			"OuterRock_" .. tostring(i),
			Vector3.new(9.5, 6.5 + (i % 3) * 2.2, 8.5),
			CFrame.new(rx, 2.5, rz) * CFrame.Angles(0, ang, math.rad((i % 2 == 0) and 6 or -6)),
			PALETTE.basalt,
			Enum.Material.Rock
		)
		addPart(
			decor,
			origin,
			"OuterCrystalA_" .. tostring(i),
			Vector3.new(2.4, 12.5 + (i % 3) * 3.2, 2.4),
			CFrame.new(rx, 8.2, rz) * CFrame.Angles(math.rad(10), ang + math.rad(45), math.rad(-14)),
			if i % 2 == 0 then PALETTE.cyan else PALETTE.cyanDeep,
			Enum.Material.Neon
		)
		addPart(
			decor,
			origin,
			"OuterCrystalB_" .. tostring(i),
			Vector3.new(1.6, 8.0, 1.6),
			CFrame.new(rx + math.cos(ang) * 2.8, 5.8, rz - math.sin(ang) * 2.8)
				* CFrame.Angles(math.rad(-12), ang, math.rad(22)),
			PALETTE.violet,
			Enum.Material.Neon
		)
	end

	-- Starry Canopy Motes + Soft Low-Lying Abyssal Mist Emitter
	for i = 1, 14 do
		local ang = math.rad(i * 25.7)
		local r = 24 + (i % 4) * 7.5
		local sy = 26 + (i % 5) * 4.5
		addPart(
			decor,
			origin,
			"CanopyStar_" .. tostring(i),
			Vector3.new(1.1, 1.1, 1.1),
			CFrame.new(math.sin(ang) * r, sy, math.cos(ang) * r - 6)
				* CFrame.Angles(math.rad(45), math.rad(45), 0),
			if i % 3 == 0 then PALETTE.goldBright else PALETTE.starWhite,
			Enum.Material.Neon
		)
	end
	local mistHost = addPart(
		decor,
		origin,
		"AbyssMistHost",
		Vector3.new(54, 0.4, 54),
		CFrame.new(0, 0.8, -4),
		PALETTE.cyanDeep,
		Enum.Material.SmoothPlastic,
		{ transparency = 1 }
	)
	addEmitter(
		mistHost,
		"AbyssSoftMist",
		PALETTE.cyanDeep,
		PALETTE.violet,
		10,
		0.6,
		1.8,
		2.4,
		0.6,
		3.2,
		5.0,
		25
	)

	-- Return Portal to Main Hub
	buildPortal(model, origin * CFrame.new(11.5, 0, 44) * CFrame.Angles(0, math.rad(-26), 0), {
		modelName = "Portal_Return_Main",
		portalId = "training_abyss_to_main",
		destination = "main",
		zoneId = "lagoon",
		title = "VOLTAR AO HUB",
		subtitle = "Ilha Principal",
		primaryColor = PALETTE.cyan,
		accentColor = PALETTE.violet,
		frameColor = PALETTE.basalt,
		frameMat = Enum.Material.Slate,
	})

	buildSafetyBarrier(ground, origin, 58, 16, 18)

	model.WorldPivot = origin
	model.Parent = Workspace
	return model
end

-- Island 4: Ilha Celestial (x50, 1T PP) — Floating Sanctuary in the Clouds! -------------
local function buildCelestialIsland(): Model
	local origin = CFrame.new(ISLAND_CENTERS.celestial)
	local model = Instance.new("Model")
	model.Name = "TrainingIsland_Celestial"
	model:SetAttribute("GeneratedBy", TAG_BUILT)
	model:SetAttribute("TrainingIsland", 4)

	local ground = Instance.new("Model")
	ground.Name = "IslandGround"
	ground.Parent = model
	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = model

	-- Floating white-marble & gleaming gold sky-island disk (r = 35 flat walkable plateau)
	addCyl(
		ground,
		origin,
		"CelestialGoldRim",
		2.2,
		73.0,
		0,
		-1.3,
		0,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		{ canCollide = true }
	)
	addCyl(
		ground,
		origin,
		"TrainingPlateau",
		1.6,
		69.0,
		0,
		-0.8,
		0,
		PALETTE.marble,
		Enum.Material.Marble,
		{ canCollide = true }
	)
	-- Tapered floating crystalline underbelly beneath the platform
	addCyl(
		decor,
		origin,
		"SkyIslandUnderbase",
		6.5,
		42.0,
		0,
		-5.4,
		0,
		PALETTE.marble,
		Enum.Material.Marble
	)
	addCyl(
		decor,
		origin,
		"SkyIslandUnderCore",
		8.0,
		18.0,
		0,
		-10.2,
		0,
		PALETTE.cyan,
		Enum.Material.Neon
	)
	-- Gilded Skywalk arrival bridge from Z = +30 to Z = +54
	addPart(
		ground,
		origin,
		"ArrivalPromenade",
		Vector3.new(26, 1.6, 26),
		CFrame.new(0, -0.82, 41),
		PALETTE.marble,
		Enum.Material.Marble,
		{ canCollide = true }
	)
	addPart(
		ground,
		origin,
		"CelestialGoldRunner",
		Vector3.new(8.6, 0.14, 18.0),
		CFrame.new(0, 0.02, 33),
		PALETTE.goldBright,
		Enum.Material.SmoothPlastic,
		{ canCollide = true }
	)

	-- Persistent TrainingSpot (TrainingIsland = 4) + Persistent Spawn
	buildPersistentCore(
		model,
		origin,
		4,
		"training_celestial",
		PALETTE.marble,
		Enum.Material.Marble,
		PALETTE.goldBright
	)

	-- Billowing Sculpted Cloud Banks cradling the entire floating island!
	for i = 0, 15 do
		local ang = math.rad(i * 22.5)
		local r = 41.0 + (i % 3) * 5.2
		local cx, cz = math.sin(ang) * r, math.cos(ang) * r
		local cy = -3.5 + (i % 3) * 1.4
		local sx = 18.0 + (i % 3) * 5.0
		local sy = 8.5 + (i % 2) * 3.0
		addPart(
			decor,
			origin,
			"CloudPuff_" .. tostring(i + 1),
			Vector3.new(sx, sy, sx * 0.85),
			CFrame.new(cx, cy, cz) * CFrame.Angles(0, ang, 0),
			if i % 2 == 0 then PALETTE.cloudWhite else PALETTE.cloudTint,
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Ball }
		)
	end

	-- 10 Soaring White-Marble & Gold Classical Columns ringing the outer rim (r = 35.5)
	local colAngles = { 54, 82, 110, 138, 166, 194, 222, 250, 278, 306 }
	for i, deg in colAngles do
		local ang = math.rad(deg)
		local r = 35.6
		local px, pz = math.sin(ang) * r, math.cos(ang) * r
		local h = if i == 5 or i == 6 then 22.0 else 16.5
		addPart(
			decor,
			origin,
			"CelestialColBase_" .. tostring(i),
			Vector3.new(3.4, 1.8, 3.4),
			CFrame.new(px, 0.9, pz) * CFrame.Angles(0, ang, 0),
			PALETTE.marble,
			Enum.Material.Marble
		)
		addCyl(
			decor,
			origin,
			"CelestialColShaft_" .. tostring(i),
			h,
			2.2,
			px,
			1.8 + h * 0.5,
			pz,
			PALETTE.marble,
			Enum.Material.Marble,
			{ castShadow = true }
		)
		addPart(
			decor,
			origin,
			"CelestialColCap_" .. tostring(i),
			Vector3.new(3.6, 1.25, 3.6),
			CFrame.new(px, 1.8 + h + 0.6, pz) * CFrame.Angles(0, ang, 0),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		addPart(
			decor,
			origin,
			"CelestialColOrb_" .. tostring(i),
			Vector3.new(1.5, 1.5, 1.5),
			CFrame.new(px, 1.8 + h + 2.2, pz),
			if i % 2 == 0 then PALETTE.goldBright else PALETTE.cyan,
			Enum.Material.Neon,
			{ shape = Enum.PartType.Ball }
		)
	end

	-- Hero Landmark: Monumental Golden Rings of Light + Sweeping Sky Aurora Curtain!
	local heroCenter = Vector3.new(0, 32.0, -34.0)
	buildRingSegments(
		decor,
		origin,
		"CelestialSunRingOuter",
		CFrame.new(heroCenter) * CFrame.Angles(math.rad(76), 0, math.rad(8)),
		16.5,
		18,
		1.15,
		1.15,
		PALETTE.goldBright,
		PALETTE.cyan,
		Enum.Material.Neon
	)
	buildRingSegments(
		decor,
		origin,
		"CelestialSunRingInner",
		CFrame.new(heroCenter) * CFrame.Angles(math.rad(-68), math.rad(16), math.rad(-14)),
		11.2,
		14,
		0.85,
		0.85,
		PALETTE.pink,
		PALETTE.goldBright,
		Enum.Material.Neon
	)
	-- Island-wide soaring halo ring encircling the entire cloud temple!
	buildRingSegments(
		decor,
		origin,
		"SkyHorizonRing",
		CFrame.new(0, 26.0, 0) * CFrame.Angles(math.rad(12), 0, math.rad(-10)),
		46.0,
		22,
		0.95,
		0.65,
		PALETTE.goldBright,
		PALETTE.cyan,
		Enum.Material.Neon
	)
	local sunCore = addPart(
		decor,
		origin,
		"CelestialSunCore",
		Vector3.new(7.5, 7.5, 7.5),
		CFrame.new(heroCenter),
		PALETTE.goldBright,
		Enum.Material.Neon,
		{ shape = Enum.PartType.Ball }
	)
	addLight(sunCore, PALETTE.goldBright, 2.2, 60)
	addEmitter(
		sunCore,
		"CelestialRadiance",
		PALETTE.goldBright,
		PALETTE.cyan,
		14,
		2.0,
		5.2,
		0.85,
		0.1,
		2.2,
		3.6,
		85
	)

	-- Sweeping Celestial Aurora Curtains across the rear skyline (-Z)
	local auroraCols = {
		PALETTE.teal,
		PALETTE.cyan,
		PALETTE.violet,
		PALETTE.pink,
		PALETTE.goldBright,
		PALETTE.cyan,
	}
	for i = 1, 6 do
		local t = (i - 3.5) / 2.5
		addPart(
			decor,
			origin,
			"CelestialAurora_" .. tostring(i),
			Vector3.new(12.5, 22.0, 0.55),
			CFrame.new(t * 24.0, 34.0 + math.cos(t * 1.3) * 5.0, -48.0 + (t * t) * 7.5)
				* CFrame.Angles(math.rad(-8), math.rad(-t * 22), math.rad(t * 7)),
			auroraCols[i],
			Enum.Material.Neon,
			{ transparency = 0.52 }
		)
	end

	-- Soft rising golden stardust across the cloud sanctuary
	local dustHost = addPart(
		decor,
		origin,
		"CelestialDustHost",
		Vector3.new(54, 0.4, 54),
		CFrame.new(0, 1.5, 0),
		PALETTE.goldBright,
		Enum.Material.SmoothPlastic,
		{ transparency = 1 }
	)
	addEmitter(
		dustHost,
		"CelestialStardust",
		PALETTE.goldBright,
		PALETTE.pink,
		10,
		1.0,
		2.8,
		0.52,
		0.08,
		2.6,
		4.2,
		30
	)

	-- Return Portal to Main Hub
	buildPortal(model, origin * CFrame.new(11.5, 0, 44) * CFrame.Angles(0, math.rad(-26), 0), {
		modelName = "Portal_Return_Main",
		portalId = "training_celestial_to_main",
		destination = "main",
		zoneId = "lagoon",
		title = "VOLTAR AO HUB",
		subtitle = "Ilha Principal",
		primaryColor = PALETTE.goldBright,
		accentColor = PALETTE.cyan,
		frameColor = PALETTE.marble,
		frameMat = Enum.Material.Marble,
	})

	-- Tall invisible safety wall right outside the walkable rim, leaving +Z promenade open!
	buildSafetyBarrier(ground, origin, 37.5, 20, 22, 24)
	-- Extra invisible guardrails along the arrival promenade flanks & back
	addPart(
		ground,
		origin,
		"PromenadeGuardL",
		Vector3.new(1.5, 18, 28),
		CFrame.new(-13.5, 8.5, 41),
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		{ transparency = 1, canCollide = true }
	)
	addPart(
		ground,
		origin,
		"PromenadeGuardR",
		Vector3.new(1.5, 18, 28),
		CFrame.new(13.5, 8.5, 41),
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		{ transparency = 1, canCollide = true }
	)
	addPart(
		ground,
		origin,
		"PromenadeGuardBack",
		Vector3.new(28, 18, 1.5),
		CFrame.new(0, 8.5, 54.5),
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		{ transparency = 1, canCollide = true }
	)

	model.WorldPivot = origin
	model.Parent = Workspace
	return model
end

-- Outbound Training Island Portals in the Hub (self-contained dock connected to PortalPlaza)
local function buildHubTrainingPortals(hubDeckCF: CFrame): Model
	local old = Workspace:FindFirstChild("TrainingPortalsHub")
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "TrainingPortalsHub"
	model:SetAttribute("GeneratedBy", TAG_BUILT)

	-- Clean wooden-and-stone extension terrace off PortalPlaza (never modifies Workspace.Island!)
	addPart(
		model,
		hubDeckCF,
		"TrainingPortalDeck",
		Vector3.new(38.0, 1.2, 16.0),
		CFrame.new(0, -0.6, 0),
		PALETTE.limestone,
		Enum.Material.Cobblestone,
		{ canCollide = true }
	)
	addPart(
		model,
		hubDeckCF,
		"TrainingPortalBridge",
		Vector3.new(10.0, 1.0, 16.0),
		CFrame.new(0, -0.56, -14.5),
		PALETTE.woodWarm,
		Enum.Material.WoodPlanks,
		{ canCollide = true }
	)
	-- Pilings beneath the terrace
	for i, pt in
		{
			Vector3.new(-17, -7, -6),
			Vector3.new(0, -7, -6),
			Vector3.new(17, -7, -6),
			Vector3.new(-17, -7, 6),
			Vector3.new(17, -7, 6),
		}
	do
		addCyl(
			model,
			hubDeckCF,
			"DeckPiling_" .. tostring(i),
			14.0,
			1.5,
			pt.X,
			pt.Y,
			pt.Z,
			PALETTE.woodDark,
			Enum.Material.Wood
		)
	end

	-- 3 Outbound Portals arranged in a grand fan facing the approaching player (-Z)
	buildPortal(model, hubDeckCF * CFrame.new(-12.5, 0, 2.5) * CFrame.Angles(0, math.rad(14), 0), {
		modelName = "Portal_Training_Reef",
		portalId = "main_to_training_reef",
		destination = "training_reef",
		zoneId = "lagoon",
		title = "ILHA DO RECIFE",
		subtitle = "Treino x3 · 100K Poder",
		primaryColor = PALETTE.turquoiseLight,
		accentColor = PALETTE.coralPink,
		frameColor = PALETTE.limestone,
		frameMat = Enum.Material.Limestone,
		trainingIsland = 2,
	})
	buildPortal(model, hubDeckCF * CFrame.new(0, 0, 4.2), {
		modelName = "Portal_Training_Abyss",
		portalId = "main_to_training_abyss",
		destination = "training_abyss",
		zoneId = "lagoon",
		title = "ABISMO ESTELAR",
		subtitle = "Treino x12 · 100M Poder",
		primaryColor = PALETTE.cyan,
		accentColor = PALETTE.violet,
		frameColor = PALETTE.basalt,
		frameMat = Enum.Material.Slate,
		trainingIsland = 3,
	})
	buildPortal(model, hubDeckCF * CFrame.new(12.5, 0, 2.5) * CFrame.Angles(0, math.rad(-14), 0), {
		modelName = "Portal_Training_Celestial",
		portalId = "main_to_training_celestial",
		destination = "training_celestial",
		zoneId = "lagoon",
		title = "ILHA CELESTIAL",
		subtitle = "Treino x50 · 1T Poder",
		primaryColor = PALETTE.goldBright,
		accentColor = PALETTE.pink,
		frameColor = PALETTE.marble,
		frameMat = Enum.Material.Marble,
		trainingIsland = 4,
	})

	model.WorldPivot = hubDeckCF
	model.Parent = Workspace
	return model
end

local Builder = {}

Builder.ISLAND_CENTERS = ISLAND_CENTERS

function Builder.clear()
	for _, name in
		{
			"TrainingIsland_Reef",
			"TrainingIsland_Abyss",
			"TrainingIsland_Celestial",
			"TrainingPortalsHub",
		}
	do
		local existing = Workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
end

function Builder.run(hubDeckCF: CFrame?): { string }
	Builder.clear()
	local built: { string } = {}
	table.insert(built, buildReefIsland().Name)
	task.wait()
	table.insert(built, buildAbyssIsland().Name)
	task.wait()
	table.insert(built, buildCelestialIsland().Name)
	task.wait()
	-- Default hub terrace right south-east of PortalSanctuary (center 31,10.35,38 r=15.4),
	-- connecting cleanly between Portal_Coral and Portal_Abyss without touching Workspace.Island.
	local defaultDeck = CFrame.lookAt(Vector3.new(56, 10.37, 63), Vector3.new(31, 10.37, 38))
	table.insert(built, buildHubTrainingPortals(hubDeckCF or defaultDeck).Name)
	return built
end

return Builder
