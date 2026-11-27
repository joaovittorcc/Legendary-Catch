--!strict
-- TrainingIsland2Builder.luau
-- Builds "TrainingIsland_Reef" (Ilha de Treino 2: Recife) for Legendary Catch.
-- Idempotent: destroys and recreates Workspace.TrainingIslands.TrainingIsland_Reef.

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Builder = {}

local DEFAULT_ORIGIN = Vector3.new(480, 12, 420)
local ISLAND_NAME = "TrainingIsland_Reef"
local FOLDER_NAME = "TrainingIslands"
local SEED = 20261125

-- Elliptical island footprint (slightly wider in X for 16:9 composition matching reference)
local ISLAND_RX = 48.0
local ISLAND_RZ = 40.5

local FOCUS_CENTER = Vector2.new(-21.2, 2.2)
local FOCUS_RX = 16.4
local FOCUS_RZ = 13.6

local INSTINCT_CENTER = Vector2.new(21.2, 2.2)
local INSTINCT_RX = 16.4
local INSTINCT_RZ = 13.6

local PORTAL_LOCAL = Vector3.new(0, 0, -29.8)

local PALETTE = {
	-- Top terrain (vibrant tropical grass + warm golden sand, avoiding white blowouts)
	GrassMain = Color3.fromRGB(120, 194, 68),
	GrassWarm = Color3.fromRGB(144, 212, 78),
	GrassDeep = Color3.fromRGB(86, 156, 52),
	Moss = Color3.fromRGB(76, 148, 86),

	SandMain = Color3.fromRGB(238, 206, 140),
	SandWarm = Color3.fromRGB(224, 186, 118),
	SandLight = Color3.fromRGB(244, 222, 168),
	SandPondBed = Color3.fromRGB(226, 232, 222),
	DirtLip = Color3.fromRGB(126, 112, 98),

	-- Sculpted dark reef cliff rock (rich charcoal/blue-slate tones in Concrete/Sandstone)
	RockLight = Color3.fromRGB(116, 124, 138),
	RockMid = Color3.fromRGB(86, 94, 108),
	RockDark = Color3.fromRGB(62, 68, 82),
	RockDeep = Color3.fromRGB(46, 52, 64),
	RockShadow = Color3.fromRGB(34, 38, 48),

	-- Portal & rune stone (neutral warm gray stone with dark mortar joints)
	StoneLight = Color3.fromRGB(168, 174, 182),
	StoneMid = Color3.fromRGB(136, 144, 154),
	StoneDark = Color3.fromRGB(98, 106, 118),
	StoneJoint = Color3.fromRGB(66, 72, 84),
	StoneRune = Color3.fromRGB(122, 132, 146),

	-- Warm wood, thatch, rope & iron
	WoodWarm1 = Color3.fromRGB(184, 118, 64),
	WoodWarm2 = Color3.fromRGB(162, 100, 52),
	WoodWarm3 = Color3.fromRGB(204, 140, 78),
	WoodWeathered = Color3.fromRGB(144, 90, 48),
	WoodDark = Color3.fromRGB(108, 66, 36),
	WoodCarved = Color3.fromRGB(242, 220, 178),
	StrawMain = Color3.fromRGB(222, 184, 88),
	StrawDark = Color3.fromRGB(188, 146, 62),
	StrawLight = Color3.fromRGB(238, 206, 116),
	RopeTan = Color3.fromRGB(214, 178, 118),
	RopeKnot = Color3.fromRGB(188, 150, 92),
	HammockCloth = Color3.fromRGB(236, 214, 168),
	HammockStripe = Color3.fromRGB(212, 182, 134),
	IronDark = Color3.fromRGB(58, 64, 76),

	-- Focus pond & aqua crystals
	WaterFocus = Color3.fromRGB(102, 224, 236),
	WaterFocusDeep = Color3.fromRGB(72, 202, 224),
	CrystalIce = Color3.fromRGB(78, 220, 248),
	CrystalCyan = Color3.fromRGB(64, 238, 255),
	CrystalCore = Color3.fromRGB(206, 252, 255),
	FocusRing = Color3.fromRGB(218, 254, 255),

	-- Instinct pond & bioluminescence
	InstinctDeep = Color3.fromRGB(88, 34, 172),
	InstinctOuter = Color3.fromRGB(128, 56, 212),
	InstinctMid = Color3.fromRGB(98, 78, 222),
	InstinctTeal = Color3.fromRGB(54, 168, 224),
	InstinctCore = Color3.fromRGB(72, 218, 238),
	InstinctRimGlow = Color3.fromRGB(186, 86, 255),
	InstinctWater = Color3.fromRGB(122, 66, 208),

	PortalWhite = Color3.fromRGB(234, 255, 255),
	AmberGlow = Color3.fromRGB(255, 194, 72),
	AmberCore = Color3.fromRGB(255, 236, 148),
	PurpleGlow = Color3.fromRGB(198, 118, 255),
	PinkGlow = Color3.fromRGB(255, 116, 214),
	CyanGlow = Color3.fromRGB(92, 244, 255),

	-- Vibrant reef corals
	CoralPink = Color3.fromRGB(246, 108, 152),
	CoralRose = Color3.fromRGB(252, 144, 178),
	CoralPeach = Color3.fromRGB(252, 164, 128),
	CoralOrange = Color3.fromRGB(246, 128, 64),
	CoralRed = Color3.fromRGB(234, 76, 84),
	CoralPurple = Color3.fromRGB(168, 92, 224),
	CoralLavender = Color3.fromRGB(196, 136, 238),
	CoralYellow = Color3.fromRGB(248, 202, 74),
	CoralTeal = Color3.fromRGB(88, 214, 186),

	-- Shells & giant clam
	ShellPink = Color3.fromRGB(244, 176, 204),
	ShellCream = Color3.fromRGB(246, 228, 198),
	ClamOuter = Color3.fromRGB(178, 134, 210),
	ClamInner = Color3.fromRGB(244, 184, 216),
	PearlGlow = Color3.fromRGB(224, 250, 255),

	-- Palm trees & coral tree
	PalmTrunk1 = Color3.fromRGB(154, 104, 62),
	PalmTrunk2 = Color3.fromRGB(132, 86, 48),
	PalmLeaf1 = Color3.fromRGB(92, 182, 62),
	PalmLeaf2 = Color3.fromRGB(126, 204, 72),
	PalmLeaf3 = Color3.fromRGB(68, 148, 48),
	CoralTreeBark = Color3.fromRGB(118, 68, 66),
	CoralTreeBarkDark = Color3.fromRGB(86, 48, 48),

	-- Props & fish
	BuoyRed = Color3.fromRGB(232, 68, 68),
	BuoyBlue = Color3.fromRGB(62, 148, 234),
	BuoyYellow = Color3.fromRGB(246, 198, 56),
	BuoyOrange = Color3.fromRGB(246, 128, 48),
	BuoyWhite = Color3.fromRGB(242, 244, 248),
	FishOrange = Color3.fromRGB(255, 162, 48),
	FishBlue = Color3.fromRGB(78, 182, 252),
	OceanFish = Color3.fromRGB(32, 92, 118),
}

type SavedLightingState = {
	ClockTime: number,
	GeographicLatitude: number,
	Brightness: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	EnvironmentDiffuseScale: number,
	EnvironmentSpecularScale: number,
}

local savedLighting: SavedLightingState? = nil

-- ============================================================================
-- GEOMETRY & SHAPE HELPERS
-- ============================================================================

local function jitterColor(base: Color3, rng: Random, amount: number): Color3
	local h, s, v = base:ToHSV()
	h = (h + rng:NextNumber(-amount * 0.25, amount * 0.25)) % 1
	s = math.clamp(s + rng:NextNumber(-amount, amount), 0, 1)
	v = math.clamp(v + rng:NextNumber(-amount, amount), 0, 1)
	return Color3.fromHSV(h, s, v)
end

local function islandEdgeAtAngle(angle: number): (number, number)
	local wobble = 1.0
		+ 0.022 * math.sin(angle * 3 + 0.4)
		+ 0.014 * math.cos(angle * 5 - 0.6)
		+ 0.018 * math.max(0, math.sin(angle))
	return math.cos(angle) * ISLAND_RX * wobble, math.sin(angle) * ISLAND_RZ * wobble
end

local function islandRadiusAtAngle(angle: number): number
	local ex, ez = islandEdgeAtAngle(angle)
	return math.sqrt(ex * ex + ez * ez)
end

local function getBeachWidth(angle: number): number
	-- Wider golden sand rim along front (+Z), slender natural sand border on sides/back
	local front = math.max(0, math.sin(angle))
	local side = math.abs(math.cos(angle))
	return 3.4 + (front ^ 1.6) * 5.6 + (side ^ 2) * 1.4
end

local function isInsideEllipse(
	x: number,
	z: number,
	center: Vector2,
	rx: number,
	rz: number,
	pad: number
): boolean
	local dx = (x - center.X) / (rx + pad)
	local dz = (z - center.Y) / (rz + pad)
	return (dx * dx + dz * dz) < 1.0
end

local function isOnCentralSandPath(x: number, z: number): boolean
	if z >= -26.5 and z <= -8.0 then
		local halfW = 3.8 + math.sin((z + 26.5) * 0.16) * 0.6
		return math.abs(x) < halfW
	end
	if z >= 13.0 and z <= 36.5 then
		local t = math.clamp((z - 13.0) / 23.5, 0, 1)
		local halfW = 3.9 + t * 2.2
		return math.abs(x) < halfW
	end
	return false
end

local function makeFolder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function makeModel(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function makePart(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean,
	transparency: number?,
	castShadow: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material
	p.CanCollide = canCollide
	p.CanTouch = false
	p.CanQuery = canCollide
	p.Transparency = transparency or 0
	p.CastShadow = if castShadow ~= nil then castShadow else canCollide
	p.Size = size
	p.CFrame = cf
	p.Parent = parent
	return p
end

local function makeWedge(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean,
	castShadow: boolean?,
	transparency: number?
): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Color = color
	w.Material = material
	w.CanCollide = canCollide
	w.CanTouch = false
	w.CanQuery = canCollide
	w.Transparency = transparency or 0
	w.CastShadow = if castShadow ~= nil then castShadow else canCollide
	w.Size = size
	w.CFrame = cf
	w.Parent = parent
	return w
end

local function makeCylinderY(
	parent: Instance,
	name: string,
	cf: CFrame,
	diameter: number,
	height: number,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean,
	transparency: number?,
	castShadow: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material
	p.CanCollide = canCollide
	p.CanTouch = false
	p.CanQuery = canCollide
	p.Transparency = transparency or 0
	p.CastShadow = if castShadow ~= nil then castShadow else canCollide
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = parent
	return p
end

local function makeEllipsoid(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean,
	transparency: number?,
	castShadow: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material
	p.CanCollide = canCollide
	p.CanTouch = false
	p.CanQuery = canCollide
	p.Transparency = transparency or 0
	p.CastShadow = if castShadow ~= nil then castShadow else false
	p.Size = size
	p.CFrame = cf
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	p.Parent = parent
	return p
end

local function makeSegment(
	parent: Instance,
	name: string,
	p1: Vector3,
	p2: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material,
	isCylinder: boolean?,
	canCollide: boolean?,
	castShadow: boolean?,
	transparency: number?
): Part?
	local diff = p2 - p1
	local dist = diff.Magnitude
	if dist < 0.02 then
		return nil
	end
	local mid = (p1 + p2) * 0.5
	local look = CFrame.lookAt(mid, p2)
	local colFlag = if canCollide == nil then false else canCollide
	local shadowFlag = if castShadow == nil then false else castShadow
	if isCylinder then
		local p = makePart(
			parent,
			name,
			look * CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(dist, thickness, thickness),
			color,
			material,
			colFlag,
			transparency or 0,
			shadowFlag
		)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	return makePart(
		parent,
		name,
		look,
		Vector3.new(thickness, thickness, dist),
		color,
		material,
		colFlag,
		transparency or 0,
		shadowFlag
	)
end

local function makeNeonRing(
	parent: Instance,
	name: string,
	centerCf: CFrame,
	radius: number,
	thickness: number,
	height: number,
	segments: number,
	color: Color3,
	transparency: number?
): Model
	local ringModel = makeModel(parent, name)
	local hub = makePart(
		ringModel,
		"Center",
		centerCf,
		Vector3.new(0.2, 0.2, 0.2),
		color,
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	hub.CanQuery = false
	hub.CanTouch = false
	ringModel.PrimaryPart = hub

	local segLen = 2 * radius * math.tan(math.pi / segments) * 1.12
	for i = 1, segments do
		local theta = (i / segments) * math.pi * 2
		local localPos = Vector3.new(math.cos(theta) * radius, 0, math.sin(theta) * radius)
		local tangent = Vector3.new(-math.sin(theta), 0, math.cos(theta))
		local localCf = CFrame.lookAt(localPos, localPos + tangent)
		local seg = makePart(
			ringModel,
			"Seg_" .. tostring(i),
			centerCf * localCf,
			Vector3.new(thickness, height, segLen),
			color,
			Enum.Material.Neon,
			false,
			transparency or 0,
			false
		)
		seg.CanQuery = false
		seg.CanTouch = false
	end
	return ringModel
end

local function addRopeCoil(
	parent: Instance,
	name: string,
	centerPos: Vector3,
	postDiameter: number,
	coils: number
)
	local coilDiameter = postDiameter + 0.22
	for c = 1, coils do
		local yOff = (c - (coils + 1) * 0.5) * 0.22
		makeCylinderY(
			parent,
			name .. "_" .. tostring(c),
			CFrame.new(centerPos + Vector3.new(0, yOff, 0))
				* CFrame.Angles(math.rad(if c % 2 == 0 then 3 else -3), 0, 0),
			coilDiameter,
			0.20,
			if c % 2 == 0 then PALETTE.RopeTan else PALETTE.RopeKnot,
			Enum.Material.Fabric,
			false,
			0,
			false
		)
	end
end

local function makeRope(
	parent: Instance,
	name: string,
	p1: Vector3,
	p2: Vector3,
	sag: number,
	segments: number,
	thickness: number,
	color: Color3?
): Model
	local rope = makeModel(parent, name)
	local col = color or PALETTE.RopeTan
	local prev = p1
	for i = 1, segments do
		local t = i / segments
		local pos = p1:Lerp(p2, t) - Vector3.new(0, 4 * sag * t * (1 - t), 0)
		makeSegment(
			rope,
			"Rope_" .. tostring(i),
			prev,
			pos,
			thickness,
			col,
			Enum.Material.Fabric,
			true,
			false,
			false
		)
		prev = pos
	end
	return rope
end

-- ============================================================================
-- CRYSTAL, CORAL, SHELL & PROP BUILDERS
-- ============================================================================

-- Faceted hexagonal crystal with pyramidal tip (optionally double-ended for floating crystals)
local function buildHexCrystal(
	parent: Instance,
	name: string,
	baseCf: CFrame,
	radius: number,
	height: number,
	outerColor: Color3,
	coreColor: Color3,
	doublePointed: boolean?,
	withLight: boolean?
): Model
	local shard = makeModel(parent, name)
	local hasBottomTip = doublePointed == true
	local botTipH = if hasBottomTip then height * 0.24 else 0
	local topTipH = height * 0.30
	local shaftH = height - topTipH - botTipH
	local flatWidth = radius * 1.1547
	local depthSpan = radius * 2.0

	-- Hexagonal shaft (3 rotated slabs at 0, 60, 120 deg)
	for k = 0, 2 do
		local rot = CFrame.Angles(0, math.rad(k * 60), 0)
		local p = makePart(
			shard,
			"HexShaft_" .. tostring(k + 1),
			baseCf * rot * CFrame.new(0, botTipH + shaftH * 0.5, 0),
			Vector3.new(flatWidth, shaftH, depthSpan),
			outerColor,
			Enum.Material.SmoothPlastic,
			false,
			0.30,
			false
		)
		p.Reflectance = 0.28
		if k == 0 then
			shard.PrimaryPart = p
		end
	end

	-- Top hexagonal pyramid (6 wedges with vertical +Z backs meeting at exact center r = 0 apex!)
	for s = 0, 5 do
		local ang = math.rad(s * 60)
		local tipW = makeWedge(
			shard,
			"HexTip_" .. tostring(s + 1),
			baseCf
				* CFrame.Angles(0, ang, 0)
				* CFrame.new(0, botTipH + shaftH + topTipH * 0.5, -radius * 0.50),
			Vector3.new(flatWidth * 1.00, topTipH, radius * 1.00),
			outerColor,
			Enum.Material.SmoothPlastic,
			false,
			false,
			0.28
		)
		tipW.Reflectance = 0.28
	end

	-- Optional lower inverted pyramid (for floating crystals in Focus Pond: +Z stays at center r = 0!)
	if hasBottomTip then
		for s = 0, 5 do
			local ang = math.rad(s * 60)
			local botW = makeWedge(
				shard,
				"HexBotTip_" .. tostring(s + 1),
				baseCf
					* CFrame.Angles(0, ang, 0)
					* CFrame.new(0, botTipH * 0.5, -radius * 0.50)
					* CFrame.Angles(0, 0, math.rad(180)),
				Vector3.new(flatWidth * 1.00, botTipH, radius * 1.00),
				outerColor,
				Enum.Material.SmoothPlastic,
				false,
				false,
				0.30
			)
			botW.Reflectance = 0.28
		end
	end

	-- Translucent Neon inner gem core (glowing heart without white blowout)
	local coreR = radius * 0.40
	local coreFlat = coreR * 1.1547
	local coreDepth = coreR * 2.0
	local gemCoreCol = outerColor:Lerp(coreColor, 0.42)
	for k = 0, 2 do
		local rot = CFrame.Angles(0, math.rad(k * 60 + 30), 0)
		makePart(
			shard,
			"CoreShaft_" .. tostring(k + 1),
			baseCf * rot * CFrame.new(0, botTipH + shaftH * 0.52, 0),
			Vector3.new(coreFlat, shaftH * 0.88, coreDepth),
			gemCoreCol,
			Enum.Material.Neon,
			false,
			0.38,
			false
		)
	end
	for s = 0, 2 do
		local ang = math.rad(s * 120)
		makeWedge(
			shard,
			"CoreTip_" .. tostring(s + 1),
			baseCf
				* CFrame.Angles(0, ang, 0)
				* CFrame.new(0, botTipH + shaftH + topTipH * 0.38, -coreR * 0.50),
			Vector3.new(coreFlat, topTipH * 0.80, coreR * 1.00),
			gemCoreCol,
			Enum.Material.Neon,
			false,
			false,
			0.38
		)
	end

	if withLight then
		local anchor = makePart(
			shard,
			"LightAnchor",
			baseCf * CFrame.new(0, height * 0.55, 0),
			Vector3.new(0.3, 0.3, 0.3),
			outerColor,
			Enum.Material.SmoothPlastic,
			false,
			1,
			false
		)
		anchor.CanQuery = false
		local pl = Instance.new("PointLight")
		pl.Color = outerColor
		pl.Brightness = 1.15
		pl.Range = math.clamp(height * 2.0, 10, 20)
		pl.Parent = anchor
	end

	return shard
end

-- Branching staghorn coral (organic curved multi-tier branches with rounded tips)
local function makeBranchCoral(
	parent: Instance,
	name: string,
	baseCf: CFrame,
	scale: number,
	color: Color3,
	rng: Random
): Model
	local coral = makeModel(parent, name)
	local branches = rng:NextInteger(5, 7)
	for i = 1, branches do
		local yaw = (i / branches) * math.pi * 2 + rng:NextNumber(-0.32, 0.32)
		local tilt = rng:NextNumber(0.24, 0.72)
		local len = rng:NextNumber(1.9, 3.2) * scale
		local thick = rng:NextNumber(0.38, 0.56) * scale
		local bColor = jitterColor(color, rng, 0.08)

		local p0 = baseCf.Position
		local bDirCf = baseCf * CFrame.Angles(0, yaw, tilt)
		local pMid = (bDirCf * CFrame.new(0, len * 0.52, 0)).Position
		local pTip = (
			bDirCf
			* CFrame.new(0, len * 0.52, 0)
			* CFrame.Angles(0, 0, -tilt * 0.32)
			* CFrame.new(0, len * 0.5, 0)
		).Position

		makeSegment(
			coral,
			"B1_" .. i,
			p0,
			pMid,
			thick,
			bColor,
			Enum.Material.SmoothPlastic,
			true,
			false,
			false
		)
		makeSegment(
			coral,
			"B2_" .. i,
			pMid,
			pTip,
			thick * 0.80,
			bColor,
			Enum.Material.SmoothPlastic,
			true,
			false,
			false
		)
		makeEllipsoid(
			coral,
			"Tip_" .. i,
			CFrame.new(pTip),
			Vector3.new(thick * 0.96, thick * 0.96, thick * 0.96),
			bColor:Lerp(PALETTE.ShellCream, 0.18),
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)

		-- Sub-fork branch
		if i % 2 == 1 then
			local subLen = len * rng:NextNumber(0.42, 0.62)
			local subEnd = (CFrame.new(pMid) * bDirCf.Rotation * CFrame.Angles(
				rng:NextNumber(-0.4, 0.4),
				rng:NextNumber(-0.9, 0.9),
				0.65
			) * CFrame.new(0, subLen, 0)).Position
			makeSegment(
				coral,
				"Sub_" .. i,
				pMid,
				subEnd,
				thick * 0.64,
				bColor,
				Enum.Material.SmoothPlastic,
				true,
				false,
				false
			)
			makeEllipsoid(
				coral,
				"SubTip_" .. i,
				CFrame.new(subEnd),
				Vector3.new(thick * 0.74, thick * 0.74, thick * 0.74),
				bColor:Lerp(PALETTE.ShellCream, 0.22),
				Enum.Material.SmoothPlastic,
				false,
				0,
				false
			)
		end
	end
	return coral
end

-- Large pleated fan / plate coral with ribs (signature front-cliff feature in reference!)
local function makeFanCoral(
	parent: Instance,
	name: string,
	baseCf: CFrame,
	scale: number,
	color: Color3,
	rng: Random
): Model
	local fan = makeModel(parent, name)
	local lobes = 7
	local rimColor = color:Lerp(PALETTE.ShellCream, 0.28)
	local ribColor = color:Lerp(PALETTE.RockDark, 0.16)

	for i = 1, lobes do
		local t = (i - 1) / (lobes - 1) - 0.5
		local angle = t * 1.48
		local len = (3.4 - math.abs(t) * 1.15) * scale
		local wid = 1.28 * scale
		local zWave = math.sin(i * 1.4) * 0.16 * scale
		local lobeCf = baseCf * CFrame.Angles(0, 0, angle) * CFrame.new(0, len * 0.52, zWave)

		makeEllipsoid(
			fan,
			"Lobe_" .. i,
			lobeCf,
			Vector3.new(wid, len, 0.36 * scale),
			jitterColor(color, rng, 0.06),
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
		-- Raised lighter vein/rib down each lobe
		makeEllipsoid(
			fan,
			"Rib_" .. i,
			lobeCf * CFrame.new(0, -0.05 * scale, 0.14 * scale),
			Vector3.new(0.24 * scale, len * 0.86, 0.20 * scale),
			ribColor,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
		-- Scalloped bright outer tip
		makeEllipsoid(
			fan,
			"Fringe_" .. i,
			baseCf * CFrame.Angles(0, 0, angle) * CFrame.new(0, len * 0.96, zWave),
			Vector3.new(wid * 0.82, 0.45 * scale, 0.34 * scale),
			rimColor,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
	end
	return fan
end

-- Tube sponge cluster (orange/gold tubular reef sponges visible on front-left rock wall)
local function makeTubeCoral(
	parent: Instance,
	name: string,
	baseCf: CFrame,
	scale: number,
	color: Color3,
	rng: Random
): Model
	local m = makeModel(parent, name)
	local tubes = 6
	for i = 1, tubes do
		local a = (i / tubes) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local r = rng:NextNumber(0.3, 1.05) * scale
		local h = rng:NextNumber(1.5, 2.8) * scale
		local d = rng:NextNumber(0.62, 0.92) * scale
		local tCf = baseCf
			* CFrame.new(math.cos(a) * r, 0, math.sin(a) * r)
			* CFrame.Angles(rng:NextNumber(-0.25, 0.25), 0, rng:NextNumber(-0.25, 0.25))
		local col = jitterColor(color, rng, 0.08)
		makeCylinderY(
			m,
			"Tube_" .. i,
			tCf * CFrame.new(0, h * 0.5, 0),
			d,
			h,
			col,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
		-- Dark hollow mouth rim at top
		makeCylinderY(
			m,
			"Hole_" .. i,
			tCf * CFrame.new(0, h + 0.04 * scale, 0),
			d * 0.60,
			0.14 * scale,
			col:Lerp(PALETTE.RockDeep, 0.55),
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
	end
	return m
end

-- Fluffy reef anemone with radiating tentacles & bright tips
local function makeAnemone(
	parent: Instance,
	name: string,
	baseCf: CFrame,
	scale: number,
	color: Color3,
	tipColor: Color3,
	rng: Random
): Model
	local m = makeModel(parent, name)
	makeEllipsoid(
		m,
		"Base",
		baseCf * CFrame.new(0, 0.4 * scale, 0),
		Vector3.new(2.2 * scale, 1.0 * scale, 2.2 * scale),
		jitterColor(color, rng, 0.08),
		Enum.Material.SmoothPlastic,
		false,
		0,
		false
	)
	local count = 10
	for i = 1, count do
		local a = (i / count) * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local r = rng:NextNumber(0.42, 0.92) * scale
		local h = rng:NextNumber(0.85, 1.45) * scale
		local tCf = baseCf
			* CFrame.new(math.cos(a) * r, 0.65 * scale, math.sin(a) * r)
			* CFrame.Angles(math.sin(a) * 0.45, 0, -math.cos(a) * 0.45)
		makeCylinderY(
			m,
			"Tent_" .. i,
			tCf,
			0.26 * scale,
			h,
			color,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
		makeEllipsoid(
			m,
			"Bulb_" .. i,
			tCf * CFrame.new(0, h * 0.5, 0),
			Vector3.new(0.38 * scale, 0.38 * scale, 0.38 * scale),
			tipColor,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
	end
	return m
end

-- Scalloped seashell with radiating ribs
local function makeShell(
	parent: Instance,
	name: string,
	baseCf: CFrame,
	scale: number,
	color: Color3
): Model
	local m = makeModel(parent, name)
	makeEllipsoid(
		m,
		"Main",
		baseCf,
		Vector3.new(1.55 * scale, 0.52 * scale, 1.38 * scale),
		color,
		Enum.Material.SmoothPlastic,
		false,
		0,
		false
	)
	for i = -2, 2 do
		local ribCf = baseCf
			* CFrame.Angles(0, i * 0.24, 0)
			* CFrame.new(0, 0.08 * scale, 0.12 * scale)
		makeEllipsoid(
			m,
			"Rib_" .. i,
			ribCf,
			Vector3.new(0.34 * scale, 0.44 * scale, 1.32 * scale),
			if i % 2 == 0 then PALETTE.ShellCream else color:Lerp(PALETTE.ShellCream, 0.35),
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
	end
	return m
end

-- Lush curved tropical palm tree with tapered ringed trunk, coconuts, and true arched V-leaflet fronds
local function makePalm(
	parent: Instance,
	name: string,
	basePos: Vector3,
	leanYaw: number,
	scale: number,
	curveAmount: number,
	rng: Random
): (Model, Vector3)
	local m = makeModel(parent, name)
	local curCf = CFrame.new(basePos) * CFrame.Angles(0, leanYaw, 0)
	local segs = 8
	local segH = 2.05 * scale
	local midPoint = basePos + Vector3.new(0, 4.5 * scale, 0)

	for i = 1, segs do
		local t = (i - 1) / (segs - 1)
		local dBot = (1.85 - t * 0.85) * scale
		local segCf = curCf * CFrame.new(0, segH * 0.5, 0)
		local col = if i % 2 == 0 then PALETTE.PalmTrunk1 else PALETTE.PalmTrunk2
		makeCylinderY(
			m,
			"Trunk_" .. i,
			segCf,
			dBot,
			segH * 1.12,
			jitterColor(col, rng, 0.04),
			Enum.Material.Wood,
			false,
			0,
			true
		)
		-- Bark ridge ring at each segment joint
		makeCylinderY(
			m,
			"BarkRing_" .. i,
			curCf * CFrame.new(0, segH * 0.92, 0),
			dBot * 1.07,
			0.22 * scale,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			false
		)
		if i == 3 then
			midPoint = (curCf * CFrame.new(0, segH * 0.6, 0)).Position
		end
		curCf = curCf
			* CFrame.new(0, segH * 0.92, 0)
			* CFrame.Angles(curveAmount * (0.75 + t * 0.55), 0, rng:NextNumber(-0.025, 0.025))
	end

	-- Crown collar & cluster of 4 coconuts
	makeEllipsoid(
		m,
		"CrownBulb",
		curCf * CFrame.new(0, 0.2 * scale, 0),
		Vector3.new(1.55 * scale, 1.15 * scale, 1.55 * scale),
		PALETTE.PalmLeaf3,
		Enum.Material.SmoothPlastic,
		false,
		0,
		false
	)
	for i = 1, 4 do
		local a = (i / 4) * math.pi * 2 + 0.4
		makeEllipsoid(
			m,
			"Coconut_" .. i,
			curCf
				* CFrame.new(math.cos(a) * 0.72 * scale, -0.45 * scale, math.sin(a) * 0.72 * scale),
			Vector3.new(0.86 * scale, 0.96 * scale, 0.86 * scale),
			PALETTE.WoodDark,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
	end

	-- 10 gracefully arching lush fanned palm fronds (curved rib + overlapping smooth tropical leaflets in 3 greens)
	local leafColors = { PALETTE.PalmLeaf2, PALETTE.PalmLeaf1, PALETTE.PalmLeaf3 }
	local fronds = 10
	for i = 1, fronds do
		local a = (i / fronds) * math.pi * 2 + rng:NextNumber(-0.10, 0.10)
		local col = leafColors[((i - 1) % #leafColors) + 1]
		local startPitch = if i % 3 == 0 then math.rad(-36) else math.rad(-14)
		local fCf = curCf * CFrame.Angles(0, a, 0) * CFrame.Angles(startPitch, 0, 0)

		for s = 1, 4 do
			local segLen = (2.65 - s * 0.30) * scale
			local leafW = (1.58 - s * 0.24) * scale
			local nextCf = fCf
				* CFrame.new(0, 0, segLen)
				* CFrame.Angles(math.rad(18 + s * 4), 0, 0)

			-- Central stem rib
			makeSegment(
				m,
				"FrondStem_" .. i .. "_" .. s,
				fCf.Position,
				nextCf.Position,
				(0.24 - s * 0.03) * scale,
				PALETTE.PalmLeaf3,
				Enum.Material.SmoothPlastic,
				true,
				false,
				false
			)
			-- Smooth arched overlapping leaflet pair forming a lush tropical fan
			local midCf = fCf * CFrame.new(0, 0, segLen * 0.5)
			for side = -1, 1, 2 do
				makeEllipsoid(
					m,
					"FrondBlade_" .. i .. "_" .. s .. "_" .. side,
					midCf
						* CFrame.new(side * leafW * 0.38, -0.05 * scale, 0)
						* CFrame.Angles(0, side * math.rad(16), side * math.rad(-22)),
					Vector3.new(leafW * 0.96, 0.18 * scale, segLen * 1.24),
					jitterColor(col, rng, 0.04),
					Enum.Material.SmoothPlastic,
					false,
					0,
					false
				)
			end
			fCf = nextCf
		end
	end

	return m, midPoint
end

-- Detailed wooden stool (3 angled cylindrical legs + thick plank seat)
local function makeStool(parent: Instance, name: string, baseCf: CFrame): Model
	local m = makeModel(parent, name)
	makeCylinderY(
		m,
		"SeatTop",
		baseCf * CFrame.new(0, 1.52, 0),
		2.15,
		0.32,
		PALETTE.WoodWarm3,
		Enum.Material.WoodPlanks,
		false,
		0,
		true
	)
	makeCylinderY(
		m,
		"SeatRim",
		baseCf * CFrame.new(0, 1.32, 0),
		1.85,
		0.14,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	for i = 1, 3 do
		local a = (i / 3) * math.pi * 2 + 0.35
		local topPt = (baseCf * CFrame.new(math.cos(a) * 0.54, 1.36, math.sin(a) * 0.54)).Position
		local botPt = (baseCf * CFrame.new(math.cos(a) * 0.88, 0.0, math.sin(a) * 0.88)).Position
		makeSegment(
			m,
			"Leg_" .. i,
			topPt,
			botPt,
			0.25,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			true,
			false,
			false
		)
	end
	return m
end

-- Detailed wooden barrel with metal bands & rim
local function makeBarrel(parent: Instance, name: string, baseCf: CFrame, scale: number): Model
	local m = makeModel(parent, name)
	makeCylinderY(
		m,
		"Body",
		baseCf * CFrame.new(0, 1.35 * scale, 0),
		2.2 * scale,
		2.7 * scale,
		PALETTE.WoodWarm2,
		Enum.Material.WoodPlanks,
		false,
		0,
		true
	)
	makeCylinderY(
		m,
		"RimTop",
		baseCf * CFrame.new(0, 2.68 * scale, 0),
		2.28 * scale,
		0.18 * scale,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	for idx, yFrac in ipairs({ 0.62, 2.05 }) do
		makeCylinderY(
			m,
			"Band_" .. idx,
			baseCf * CFrame.new(0, yFrac * scale, 0),
			2.32 * scale,
			0.24 * scale,
			PALETTE.IronDark,
			Enum.Material.Metal,
			false,
			0,
			false
		)
	end
	return m
end

-- Framed slatted wooden crate
local function makeCrate(parent: Instance, name: string, cf: CFrame, sz: number, rng: Random): Model
	local m = makeModel(parent, name)
	makePart(
		m,
		"Core",
		cf,
		Vector3.new(sz * 0.90, sz * 0.90, sz * 0.90),
		jitterColor(PALETTE.WoodWarm1, rng, 0.05),
		Enum.Material.WoodPlanks,
		false,
		0,
		true
	)
	local frameThick = sz * 0.14
	local half = sz * 0.45
	-- 4 vertical corner posts + top/bottom border rails
	for sx = -1, 1, 2 do
		for szSign = -1, 1, 2 do
			makePart(
				m,
				"Corner_" .. sx .. "_" .. szSign,
				cf * CFrame.new(sx * half, 0, szSign * half),
				Vector3.new(frameThick, sz, frameThick),
				PALETTE.WoodDark,
				Enum.Material.Wood,
				false,
				0,
				false
			)
		end
		makePart(
			m,
			"RailTopX_" .. sx,
			cf * CFrame.new(sx * half, half, 0),
			Vector3.new(frameThick, frameThick, sz),
			PALETTE.WoodWarm3,
			Enum.Material.Wood,
			false,
			0,
			false
		)
		makePart(
			m,
			"RailBotX_" .. sx,
			cf * CFrame.new(sx * half, -half, 0),
			Vector3.new(frameThick, frameThick, sz),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			false
		)
		makePart(
			m,
			"RailTopZ_" .. sx,
			cf * CFrame.new(0, half, sx * half),
			Vector3.new(sz, frameThick, frameThick),
			PALETTE.WoodWarm3,
			Enum.Material.Wood,
			false,
			0,
			false
		)
		makePart(
			m,
			"RailBotZ_" .. sx,
			cf * CFrame.new(0, -half, sx * half),
			Vector3.new(sz, frameThick, frameThick),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			false
		)
	end
	return m
end

-- Detailed hanging amber lantern (iron cage + glowing core + warm PointLight)
local function buildLanternUnit(
	parent: Instance,
	name: string,
	centerPos: Vector3,
	scale: number
): Model
	local lantern = makeModel(parent, name)
	makePart(
		lantern,
		"TopCap",
		CFrame.new(centerPos + Vector3.new(0, 0.85 * scale, 0)),
		Vector3.new(1.24 * scale, 0.24 * scale, 1.24 * scale),
		PALETTE.IronDark,
		Enum.Material.Metal,
		false,
		0,
		false
	)
	makePart(
		lantern,
		"RoofPeak",
		CFrame.new(centerPos + Vector3.new(0, 1.06 * scale, 0)),
		Vector3.new(0.76 * scale, 0.22 * scale, 0.76 * scale),
		PALETTE.IronDark,
		Enum.Material.Metal,
		false,
		0,
		false
	)
	makePart(
		lantern,
		"BottomCap",
		CFrame.new(centerPos + Vector3.new(0, -0.85 * scale, 0)),
		Vector3.new(1.14 * scale, 0.24 * scale, 1.14 * scale),
		PALETTE.IronDark,
		Enum.Material.Metal,
		false,
		0,
		false
	)
	local core = makePart(
		lantern,
		"AmberCore",
		CFrame.new(centerPos),
		Vector3.new(0.88 * scale, 1.42 * scale, 0.88 * scale),
		PALETTE.AmberGlow,
		Enum.Material.Neon,
		false,
		0.05,
		false
	)
	for sx = -1, 1, 2 do
		for sz = -1, 1, 2 do
			makePart(
				lantern,
				"Cage_" .. sx .. "_" .. sz,
				CFrame.new(centerPos + Vector3.new(sx * 0.48 * scale, 0, sz * 0.48 * scale)),
				Vector3.new(0.13 * scale, 1.62 * scale, 0.13 * scale),
				PALETTE.IronDark,
				Enum.Material.Metal,
				false,
				0,
				false
			)
		end
	end
	local light = Instance.new("PointLight")
	light.Color = PALETTE.AmberGlow
	light.Brightness = 1.45
	light.Range = 16 * scale
	light.Parent = core
	return lantern
end

-- Carved wooden fish signpost (Island 1 premium carved cream-wood fish with shadow groove + frame)
local function buildFishSignpost(
	parent: Instance,
	name: string,
	pos: Vector3,
	faceTarget: Vector3,
	arrowPointRight: boolean
): Model
	local sign = makeModel(parent, name)
	local cf = CFrame.lookAt(pos, Vector3.new(faceTarget.X, pos.Y, faceTarget.Z))

	local post = makeCylinderY(
		sign,
		"Post",
		cf * CFrame.new(0, 2.35, 0),
		0.76,
		4.8,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		true
	)
	sign.PrimaryPart = post
	makeEllipsoid(
		sign,
		"PostCap",
		cf * CFrame.new(0, 4.78, 0),
		Vector3.new(0.84, 0.38, 0.84),
		PALETTE.WoodWarm2,
		Enum.Material.Wood,
		false,
		0,
		false
	)

	local boardCf = cf * CFrame.new(0, 3.65, -0.38) * CFrame.Angles(0, 0, math.rad(1.5))
	local bw = if arrowPointRight then 3.55 else 4.25
	local bh = if arrowPointRight then 2.10 else 2.45
	makePart(
		sign,
		"BoardMain",
		boardCf,
		Vector3.new(bw, bh, 0.38),
		PALETTE.WoodWarm1,
		Enum.Material.WoodPlanks,
		false,
		0,
		true
	)

	-- Dark wood border frame
	makePart(
		sign,
		"FrameTop",
		boardCf * CFrame.new(0, bh * 0.5, 0),
		Vector3.new(bw + 0.2, 0.22, 0.46),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		sign,
		"FrameBot",
		boardCf * CFrame.new(0, -bh * 0.5, 0),
		Vector3.new(bw + 0.2, 0.22, 0.46),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		sign,
		"FrameL",
		boardCf * CFrame.new(-bw * 0.5, 0, 0),
		Vector3.new(0.22, bh + 0.14, 0.46),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	if arrowPointRight then
		-- Pointed wooden arrow tip on the right (-X in lookAt facing +Z is right on screen!)
		makeWedge(
			sign,
			"ArrowTop",
			boardCf * CFrame.new(-bw * 0.5 - 0.58, bh * 0.26, 0) * CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(0.38, bh * 0.52, 1.15),
			PALETTE.WoodWarm1,
			Enum.Material.WoodPlanks,
			false,
			true
		)
		makeWedge(
			sign,
			"ArrowBot",
			boardCf
				* CFrame.new(-bw * 0.5 - 0.58, -bh * 0.26, 0)
				* CFrame.Angles(0, math.rad(90), math.rad(180)),
			Vector3.new(0.38, bh * 0.52, 1.15),
			PALETTE.WoodWarm1,
			Enum.Material.WoodPlanks,
			false,
			true
		)
	else
		makePart(
			sign,
			"FrameR",
			boardCf * CFrame.new(bw * 0.5, 0, 0),
			Vector3.new(0.22, bh + 0.14, 0.46),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			false
		)
	end

	-- Carved cream-wood fish with recessed shadow groove on front face (-Z of boardCf)
	local iconCf = boardCf * CFrame.new(0, 0, -0.22)
	makeEllipsoid(
		sign,
		"FishShadow",
		iconCf * CFrame.new(0.22, -0.05, 0.04),
		Vector3.new(1.98, 1.04, 0.10),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makeEllipsoid(
		sign,
		"FishBody",
		iconCf * CFrame.new(0.24, 0, 0),
		Vector3.new(1.85, 0.94, 0.14),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		sign,
		"FishTailTop",
		iconCf * CFrame.new(-0.88, 0.25, 0) * CFrame.Angles(0, 0, math.rad(-28)),
		Vector3.new(0.76, 0.25, 0.12),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		sign,
		"FishTailBot",
		iconCf * CFrame.new(-0.88, -0.25, 0) * CFrame.Angles(0, 0, math.rad(28)),
		Vector3.new(0.76, 0.25, 0.12),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makeEllipsoid(
		sign,
		"FishFinTop",
		iconCf * CFrame.new(0.10, 0.50, 0) * CFrame.Angles(0, 0, math.rad(16)),
		Vector3.new(0.56, 0.25, 0.10),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makeEllipsoid(
		sign,
		"FishEye",
		iconCf * CFrame.new(0.82, 0.10, -0.04),
		Vector3.new(0.20, 0.20, 0.10),
		PALETTE.WoodDark,
		Enum.Material.SmoothPlastic,
		false,
		0,
		false
	)

	return sign
end

-- Planked wooden deck with pilings, rope coils & smooth walkable surface
local function buildPlankedDeck(
	parent: Instance,
	name: string,
	colliderName: string,
	deckCf: CFrame,
	width: number,
	depth: number,
	plankCount: number,
	pilingCols: number,
	rng: Random
): Model
	local deck = makeModel(parent, name)
	local woodTones =
		{ PALETTE.WoodWarm1, PALETTE.WoodWarm2, PALETTE.WoodWarm3, PALETTE.WoodWeathered }

	-- Continuous invisible collider matching top of deck (verified by selfTest)
	local collider = makePart(
		deck,
		colliderName,
		deckCf * CFrame.new(0, -0.02, 0),
		Vector3.new(width, 0.42, depth),
		PALETTE.WoodWarm1,
		Enum.Material.WoodPlanks,
		true,
		1,
		false
	)
	deck.PrimaryPart = collider

	-- Structural beams underneath
	for _, zOff in ipairs({ -depth * 0.34, depth * 0.34 }) do
		makePart(
			deck,
			"Beam_" .. tostring(zOff),
			deckCf * CFrame.new(0, -0.34, zOff),
			Vector3.new(width * 0.96, 0.46, 0.58),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			true
		)
	end

	-- Individual planks with subtle length, yaw & tone variation
	local stepX = width / plankCount
	for i = 1, plankCount do
		local xOff = -width * 0.5 + (i - 0.5) * stepX
		local dVar = depth + rng:NextNumber(-0.18, 0.24)
		local yaw = math.rad(rng:NextNumber(-0.8, 0.8))
		makePart(
			deck,
			"Plank_" .. i,
			deckCf * CFrame.new(xOff, 0.04, rng:NextNumber(-0.06, 0.06)) * CFrame.Angles(0, yaw, 0),
			Vector3.new(stepX - 0.11, 0.30, dVar),
			woodTones[((i - 1) % #woodTones) + 1],
			Enum.Material.WoodPlanks,
			false,
			0,
			true
		)
	end

	-- Thick wooden pilings with rounded caps & rope coils
	for c = 0, pilingCols - 1 do
		local t = if pilingCols == 1 then 0.5 else c / (pilingCols - 1)
		local px = -width * 0.45 + t * (width * 0.90)
		for _, pz in ipairs({ -depth * 0.44, depth * 0.44 }) do
			local postCf = deckCf * CFrame.new(px, -1.15, pz)
			makeCylinderY(
				deck,
				"Piling_" .. c .. "_" .. tostring(pz),
				postCf,
				0.82,
				3.6,
				PALETTE.WoodDark,
				Enum.Material.Wood,
				false,
				0,
				true
			)
			makeEllipsoid(
				deck,
				"PilingCap_" .. c .. "_" .. tostring(pz),
				postCf * CFrame.new(0, 1.82, 0),
				Vector3.new(0.86, 0.34, 0.86),
				PALETTE.WoodWarm3,
				Enum.Material.Wood,
				false,
				0,
				false
			)
			if pz > 0 then
				addRopeCoil(
					deck,
					"PilingRope_" .. c,
					(postCf * CFrame.new(0, 1.38, 0)).Position,
					0.82,
					2
				)
			end
		end
	end

	return deck
end

-- ============================================================================
-- 1. ISLAND TOP TERRAIN (SMOOTH GRASS + GOLDEN SAND RIM, CARVED POND BASINS)
-- ============================================================================

local function buildIslandTopTerrain(root: Model, origin: Vector3)
	local folder = makeFolder(root, "TerrainBase")
	local step = 1.4
	local halfX = ISLAND_RX + 2.0
	local halfZ = ISLAND_RZ + 2.0
	local colsX = math.floor((halfX * 2) / step)
	local colsZ = math.floor((halfZ * 2) / step)

	-- Scanline strips recessed 2.2 studs from outer edge so smooth curved rim hides any stair-step
	for iz = 0, colsZ do
		local z = -halfZ + iz * step
		local runKind: string? = nil
		local runStartX = 0.0

		local function flushRun(endX: number)
			if not runKind then
				return
			end
			local width = endX - runStartX
			if width < 0.1 then
				runKind = nil
				return
			end
			local midX = (runStartX + endX) * 0.5
			if runKind == "Grass" then
				makePart(
					folder,
					"GrassStrip",
					CFrame.new(origin + Vector3.new(midX, -0.90, z)),
					Vector3.new(width, 1.80, step + 0.06),
					PALETTE.GrassMain,
					Enum.Material.Grass,
					true,
					0,
					true
				)
			elseif runKind == "Sand" then
				makePart(
					folder,
					"SandStrip",
					CFrame.new(origin + Vector3.new(midX, -1.00, z)),
					Vector3.new(width, 1.66, step + 0.06),
					PALETTE.SandMain,
					Enum.Material.Sand,
					true,
					0,
					true
				)
			end
			runKind = nil
		end

		for ix = 0, colsX do
			local x = -halfX + ix * step
			local angle = math.atan2(z, x)
			local r = math.sqrt(x * x + z * z)
			local edgeR = islandRadiusAtAngle(angle)
			local beachW = getBeachWidth(angle)

			local cellKind: string? = nil
			if r <= edgeR - 2.2 then
				local inFocus = isInsideEllipse(x, z, FOCUS_CENTER, FOCUS_RX, FOCUS_RZ, -0.45)
				local inInstinct =
					isInsideEllipse(x, z, INSTINCT_CENTER, INSTINCT_RX, INSTINCT_RZ, -0.45)
				if not inFocus and not inInstinct then
					-- Pull grass strips inward 1.6 studs from beach border so smooth curved GrassEdge covers 100% of stair-steps!
					if r <= edgeR - beachW - 1.6 and not isOnCentralSandPath(x, z) then
						cellKind = "Grass"
					else
						cellKind = "Sand"
					end
				end
			end

			if cellKind ~= runKind then
				flushRun(x - step * 0.5)
				if cellKind then
					runKind = cellKind
					runStartX = x - step * 0.5
				end
			end
		end
		flushRun(halfX + step * 0.5)
	end

	-- Continuous curved outer sand rim + rounded sand bevel + rock-lip seam (exact same radius as cliff!)
	local rimFolder = makeFolder(folder, "SmoothCurvedRims")
	local segCount = 72
	for i = 1, segCount do
		local a1 = (i / segCount) * math.pi * 2
		local a2 = ((i + 1) / segCount) * math.pi * 2
		local x1, z1 = islandEdgeAtAngle(a1)
		local x2, z2 = islandEdgeAtAngle(a2)

		local p1 = origin + Vector3.new(x1, -0.17, z1)
		local p2 = origin + Vector3.new(x2, -0.17, z2)
		local segLen = (p2 - p1).Magnitude + 1.15
		local mid = (p1 + p2) * 0.5
		local cf = CFrame.lookAt(mid, p2)

		-- Outer golden sand rim (+X points inward)
		makePart(
			rimFolder,
			"SandRim_" .. i,
			cf * CFrame.new(2.75, -0.72, 0),
			Vector3.new(5.8, 1.44, segLen),
			PALETTE.SandMain,
			Enum.Material.Sand,
			true,
			0,
			true
		)
		-- Rounded sand bevel descending smoothly into upper rock edge (zero dish overhang)
		makePart(
			rimFolder,
			"SandBevel_" .. i,
			cf * CFrame.new(0.30, -0.90, 0) * CFrame.Angles(0, 0, math.rad(26)),
			Vector3.new(1.55, 1.38, segLen * 1.06),
			PALETTE.SandWarm,
			Enum.Material.Sand,
			false,
			0,
			false
		)
		-- Upper dark stone collar flush under the sand bevel
		makePart(
			rimFolder,
			"RockLip_" .. i,
			cf * CFrame.new(1.25, -1.90, 0) * CFrame.Angles(0, 0, math.rad(14)),
			Vector3.new(3.3, 1.85, segLen * 1.08),
			PALETTE.RockMid,
			Enum.Material.Concrete,
			false,
			0,
			true
		)

		-- Smooth curved grass-over-sand border inside the beach
		local bw1 = getBeachWidth(a1)
		local bw2 = getBeachWidth(a2)
		local r1 = math.sqrt(x1 * x1 + z1 * z1)
		local r2 = math.sqrt(x2 * x2 + z2 * z2)
		local gx1, gz1 = x1 * ((r1 - bw1) / r1), z1 * ((r1 - bw1) / r1)
		local gx2, gz2 = x2 * ((r2 - bw2) / r2), z2 * ((r2 - bw2) / r2)
		local g1 = origin + Vector3.new(gx1, -0.02, gz1)
		local g2 = origin + Vector3.new(gx2, -0.02, gz2)
		local gMid = (g1 + g2) * 0.5
		local gLen = (g2 - g1).Magnitude + 1.25
		local gCf = CFrame.lookAt(gMid, g2)
		local localMidX = gMid.X - origin.X
		local localMidZ = gMid.Z - origin.Z
		if
			not isOnCentralSandPath(localMidX, localMidZ)
			and not isInsideEllipse(localMidX, localMidZ, FOCUS_CENTER, FOCUS_RX, FOCUS_RZ, 0.6)
			and not isInsideEllipse(
				localMidX,
				localMidZ,
				INSTINCT_CENTER,
				INSTINCT_RX,
				INSTINCT_RZ,
				0.6
			)
		then
			makePart(
				rimFolder,
				"GrassEdge_" .. i,
				gCf * CFrame.new(2.55, -0.18, 0) * CFrame.Angles(0, 0, math.rad(4)),
				Vector3.new(5.8, 0.36, gLen * 1.15),
				if i % 3 == 0 then PALETTE.GrassWarm else PALETTE.GrassMain,
				Enum.Material.Grass,
				false,
				0,
				false
			)
		end
	end

	-- Organic sand path pads north & south of central bridge (guaranteeing solid floor under ArrivalSpawn!)
	local pathPads = makeFolder(folder, "CentralSandPads")
	for s = 0, 7 do
		local t = s / 7
		local pz = -25.5 + t * 17.5
		makeCylinderY(
			pathPads,
			"NorthSandPad_" .. s,
			CFrame.new(origin + Vector3.new(math.sin(t * math.pi) * 0.4, -0.22, pz)),
			7.8,
			0.36,
			if s % 2 == 0 then PALETTE.SandMain else PALETTE.SandLight,
			Enum.Material.Sand,
			true,
			0,
			false
		)
	end
	for s = 0, 8 do
		local t = s / 8
		local pz = 14.0 + t * 21.0
		makeCylinderY(
			pathPads,
			"SouthSandPad_" .. s,
			CFrame.new(origin + Vector3.new(math.sin(t * math.pi) * 0.5, -0.22, pz)),
			8.0 + t * 3.8,
			0.36,
			if s % 2 == 0 then PALETTE.SandMain else PALETTE.SandLight,
			Enum.Material.Sand,
			true,
			0,
			false
		)
	end

	-- Solid safety sub-slab right under ArrivalSpawn & portal approach
	makePart(
		folder,
		"ArrivalSolidFloor",
		CFrame.new(origin + Vector3.new(0, -0.55, -20.5)),
		Vector3.new(16.0, 1.0, 16.0),
		PALETTE.SandMain,
		Enum.Material.Sand,
		true,
		0,
		false
	)
end

-- ============================================================================
-- 2. SCULPTED REEF ROCK UNDERSIDE + DENSE COLORFUL CORAL & CRYSTAL WALL
-- ============================================================================

local function buildRockAndReefWall(root: Model, origin: Vector3, rng: Random)
	local rockFolder = makeFolder(root, "RockUnderside")
	local coralFolder = makeFolder(root, "RockWallCorals")

	-- Dark recessed elliptical rock core tiers (zero gaps, creates dark crevices between boulders!)
	local coreTiers = {
		{ y = -3.4, h = 4.2, sx = ISLAND_RX * 1.90, sz = ISLAND_RZ * 1.90 },
		{ y = -6.8, h = 4.2, sx = ISLAND_RX * 1.62, sz = ISLAND_RZ * 1.62 },
		{ y = -9.8, h = 3.8, sx = ISLAND_RX * 1.24, sz = ISLAND_RZ * 1.24 },
		{ y = -11.9, h = 2.8, sx = ISLAND_RX * 0.78, sz = ISLAND_RZ * 0.78 },
	}
	for idx, ct in ipairs(coreTiers) do
		makeEllipsoid(
			rockFolder,
			"RockCore_" .. idx,
			CFrame.new(origin + Vector3.new(0, ct.y, 0)),
			Vector3.new(ct.sx, ct.h, ct.sz),
			PALETTE.RockShadow,
			Enum.Material.Concrete,
			false,
			0,
			true
		)
	end

	-- 4 sculpted boulder tiers descending from exact edge radius down to irregular keel
	local tiers = {
		{
			count = 30,
			rScale = 1.015,
			yMin = -4.2,
			yMax = -3.6,
			widthScale = 1.08,
			height = 4.4,
			depth = 7.8,
			inwardTilt = 10,
			colors = { PALETTE.RockLight, PALETTE.RockMid },
		},
		{
			count = 24,
			rScale = 0.915,
			yMin = -7.3,
			yMax = -6.4,
			widthScale = 1.14,
			height = 4.9,
			depth = 8.6,
			inwardTilt = 22,
			colors = { PALETTE.RockMid, PALETTE.RockDark },
		},
		{
			count = 18,
			rScale = 0.74,
			yMin = -10.3,
			yMax = -9.4,
			widthScale = 1.20,
			height = 4.4,
			depth = 8.4,
			inwardTilt = 35,
			colors = { PALETTE.RockDark, PALETTE.RockDeep },
		},
		{
			count = 10,
			rScale = 0.48,
			yMin = -12.1,
			yMax = -11.2,
			widthScale = 1.26,
			height = 3.4,
			depth = 7.2,
			inwardTilt = 48,
			colors = { PALETTE.RockDeep, PALETTE.RockShadow },
		},
	}

	for tIdx, tier in ipairs(tiers) do
		local arcStep = (math.pi * 2) / tier.count
		for i = 1, tier.count do
			local ang = (i / tier.count) * math.pi * 2 + tIdx * 0.21 + rng:NextNumber(-0.04, 0.04)
			local ex, ez = islandEdgeAtAngle(ang)
			local edgeVec = Vector3.new(ex, 0, ez)
			local baseR = edgeVec.Magnitude * tier.rScale
			local dirOut = edgeVec.Unit
			local r = baseR + rng:NextNumber(-0.6, 0.55)
			local y = rng:NextNumber(tier.yMin, tier.yMax)
			local pos = origin + dirOut * (r - tier.depth * 0.44) + Vector3.new(0, y, 0)

			local chordW = baseR * arcStep * tier.widthScale * rng:NextNumber(0.90, 1.08)
			local blkH = tier.height * rng:NextNumber(0.88, 1.14)
			local blkD = tier.depth * rng:NextNumber(0.90, 1.10)
			local col = tier.colors[((i + tIdx) % #tier.colors) + 1]
			local useMat = if i % 4 == 0 then Enum.Material.Sandstone else Enum.Material.Concrete

			local baseCf = CFrame.lookAt(pos, pos + dirOut)
				* CFrame.Angles(
					math.rad(-tier.inwardTilt + rng:NextNumber(-5, 5)),
					math.rad(rng:NextNumber(-6, 6)),
					math.rad(rng:NextNumber(-5, 5))
				)

			-- Structural rock body
			makePart(
				rockFolder,
				"CliffBlock_" .. tIdx .. "_" .. i,
				baseCf * CFrame.new(0, 0, blkD * 0.14),
				Vector3.new(chordW * 0.82, blkH * 0.90, blkD * 0.74),
				jitterColor(col, rng, 0.04),
				useMat,
				false,
				0,
				true
			)
			-- Rounded sculpted boulder belly
			makeEllipsoid(
				rockFolder,
				"CliffBelly_" .. tIdx .. "_" .. i,
				baseCf * CFrame.new(rng:NextNumber(-0.3, 0.3), 0.06 * blkH, -blkD * 0.14),
				Vector3.new(chordW * 1.10, blkH * 1.08, blkD * 0.96),
				if tIdx == 1 then PALETTE.RockMid else PALETTE.RockDark,
				useMat,
				false,
				0,
				true
			)
			-- Angular cracked facet bevel
			makeWedge(
				rockFolder,
				"CliffBevel_" .. tIdx .. "_" .. i,
				baseCf
					* CFrame.new(rng:NextNumber(-0.35, 0.35), -blkH * 0.16, -blkD * 0.32)
					* CFrame.Angles(math.rad(180), 0, math.rad(rng:NextNumber(-7, 7))),
				Vector3.new(chordW * 0.72, blkH * 0.64, blkD * 0.44),
				if tIdx == 1 then PALETTE.RockDark else PALETTE.RockDeep,
				useMat,
				false,
				false
			)
		end
	end

	-- Irregular bottom rock keel
	local apexSpecs = {
		{
			off = Vector3.new(0, -12.4, 0),
			sz = Vector3.new(22.0, 3.0, 18.0),
			rot = Vector3.new(4, 18, -3),
		},
		{
			off = Vector3.new(-5.2, -12.6, 2.6),
			sz = Vector3.new(12.0, 2.6, 10.0),
			rot = Vector3.new(-7, 42, 6),
		},
		{
			off = Vector3.new(5.5, -12.5, -2.2),
			sz = Vector3.new(11.5, 2.5, 10.5),
			rot = Vector3.new(6, -28, -7),
		},
	}
	for idx, ap in ipairs(apexSpecs) do
		makeEllipsoid(
			rockFolder,
			"BottomApex_" .. idx,
			CFrame.new(origin + ap.off)
				* CFrame.Angles(math.rad(ap.rot.X), math.rad(ap.rot.Y), math.rad(ap.rot.Z)),
			ap.sz,
			PALETTE.RockDeep,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
	end

	-- ========================================================================
	-- MASSIVE REEF CORAL & CRYSTAL COVERAGE ON ROCK CLIFF (reference showcase!)
	-- ========================================================================
	local function cliffOutCf(
		ang: number,
		rScale: number,
		y: number,
		pitchDeg: number,
		rollDeg: number
	): CFrame
		local ex, ez = islandEdgeAtAngle(ang)
		local p = origin + Vector3.new(ex * rScale, y, ez * rScale)
		local dir = Vector3.new(ex, 0, ez).Unit
		return CFrame.lookAt(p, p + dir) * CFrame.Angles(math.rad(-pitchDeg), 0, math.rad(rollDeg))
	end

	-- 1. Hero Large Pleated Fan Corals oriented UPWARD/OUTWARD against the cliff face so their broad veined fans showcase brightly!
	local function cliffFanCf(
		ang: number,
		rScale: number,
		y: number,
		tiltBackDeg: number,
		rollDeg: number
	): CFrame
		local ex, ez = islandEdgeAtAngle(ang)
		local p = origin + Vector3.new(ex * rScale, y, ez * rScale)
		local dir = Vector3.new(ex, 0, ez).Unit
		-- Face fan (+Z of fan) outward along dir, standing mostly upright with gentle natural outward tilt
		return CFrame.lookAt(p, p - dir)
			* CFrame.Angles(math.rad(-tiltBackDeg), 0, math.rad(rollDeg))
	end

	local heroFans = {
		{
			ang = 2.06,
			rS = 1.01,
			y = -8.2,
			s = 2.25,
			col = PALETTE.CoralPink,
			tilt = 22,
			roll = -14,
		},
		{
			ang = 1.88,
			rS = 0.99,
			y = -10.2,
			s = 2.15,
			col = PALETTE.CoralOrange,
			tilt = 26,
			roll = 10,
		},
		{
			ang = 1.69,
			rS = 1.01,
			y = -8.4,
			s = 2.45,
			col = PALETTE.CoralPeach,
			tilt = 20,
			roll = 4,
		},
		{
			ang = 1.48,
			rS = 0.97,
			y = -10.5,
			s = 2.25,
			col = PALETTE.CoralPurple,
			tilt = 28,
			roll = -8,
		},
		{
			ang = 1.28,
			rS = 0.99,
			y = -9.6,
			s = 2.40,
			col = PALETTE.CoralLavender,
			tilt = 24,
			roll = 12,
		},
		{
			ang = 1.06,
			rS = 1.01,
			y = -8.0,
			s = 2.10,
			col = PALETTE.CoralPink,
			tilt = 20,
			roll = -12,
		},
		{
			ang = 2.44,
			rS = 1.02,
			y = -7.6,
			s = 1.95,
			col = PALETTE.CoralRose,
			tilt = 24,
			roll = -16,
		},
		{
			ang = 0.66,
			rS = 1.02,
			y = -7.8,
			s = 2.00,
			col = PALETTE.CoralOrange,
			tilt = 22,
			roll = 16,
		},
		-- Upper overlapping smaller fan corals for lush reef layering
		{
			ang = 1.80,
			rS = 1.03,
			y = -6.2,
			s = 1.65,
			col = PALETTE.CoralRose,
			tilt = 18,
			roll = -6,
		},
		{
			ang = 1.18,
			rS = 1.03,
			y = -6.4,
			s = 1.65,
			col = PALETTE.CoralOrange,
			tilt = 18,
			roll = 8,
		},
		-- Side/back accents for 360 views
		{ ang = 3.55, rS = 1.01, y = -8.0, s = 1.85, col = PALETTE.CoralPink, tilt = 24, roll = 0 },
		{
			ang = 4.65,
			rS = 1.01,
			y = -8.2,
			s = 1.90,
			col = PALETTE.CoralPurple,
			tilt = 24,
			roll = 6,
		},
		{
			ang = 5.65,
			rS = 1.01,
			y = -7.8,
			s = 1.85,
			col = PALETTE.CoralOrange,
			tilt = 22,
			roll = -6,
		},
	}
	for idx, f in ipairs(heroFans) do
		makeFanCoral(
			coralFolder,
			"HeroFanCoral_" .. idx,
			cliffFanCf(f.ang, f.rS, f.y, f.tilt, f.roll),
			f.s,
			f.col,
			rng
		)
	end

	-- 2. Tube Sponge Clusters (signature orange/coral tube clusters on front-left & front-right)
	local tubeSpecs = {
		{ ang = 2.22, rS = 1.02, y = -5.2, s = 1.65, col = PALETTE.CoralOrange },
		{ ang = 2.12, rS = 0.98, y = -7.8, s = 1.50, col = PALETTE.CoralYellow },
		{ ang = 0.86, rS = 1.01, y = -6.0, s = 1.60, col = PALETTE.CoralOrange },
		{ ang = 1.72, rS = 0.96, y = -9.6, s = 1.40, col = PALETTE.CoralPeach },
	}
	for idx, ts in ipairs(tubeSpecs) do
		makeTubeCoral(
			coralFolder,
			"CliffTubeCoral_" .. idx,
			cliffOutCf(ts.ang, ts.rS, ts.y, 72, 0),
			ts.s,
			ts.col,
			rng
		)
	end

	-- 3. Dense Branching Coral Clusters wrapping the entire front hemisphere + sides + back
	local branchColors = {
		PALETTE.CoralPink,
		PALETTE.CoralOrange,
		PALETTE.CoralRed,
		PALETTE.CoralPurple,
		PALETTE.CoralYellow,
		PALETTE.CoralRose,
	}
	local branchCount = 28
	for i = 1, branchCount do
		-- Concentrate heavily on visible front/sides (-0.15 to pi + 0.15) plus 6 around back
		local ang: number
		if i <= 22 then
			ang = -0.18 + ((i - 1) / 21) * (math.pi + 0.36)
		else
			ang = math.pi + 0.45 + ((i - 23) / 6) * (math.pi - 0.9)
		end
		local yTier = if i % 3 == 0 then rng:NextNumber(-9.5, -7.2) else rng:NextNumber(-6.4, -3.4)
		local rScale = if yTier < -7.0 then 0.96 else 1.03
		local col = branchColors[((i - 1) % #branchColors) + 1]
		makeBranchCoral(
			coralFolder,
			"CliffBranch_" .. i,
			cliffOutCf(ang, rScale, yTier, rng:NextNumber(58, 78), rng:NextNumber(-20, 20)),
			rng:NextNumber(1.30, 1.95),
			col,
			rng
		)
	end

	-- 4. Fluffy Reef Anemones nestled prominently ON the front rock surface (never buried inside boulders!)
	local anemoneSpecs = {
		{
			ang = 1.54,
			rS = 1.03,
			y = -6.0,
			s = 1.75,
			col = PALETTE.CoralPink,
			tip = PALETTE.ShellCream,
		},
		{
			ang = 1.36,
			rS = 1.04,
			y = -4.8,
			s = 1.50,
			col = PALETTE.CoralYellow,
			tip = PALETTE.CoralOrange,
		},
		{
			ang = 1.42,
			rS = 1.00,
			y = -7.6,
			s = 1.50,
			col = PALETTE.CoralTeal,
			tip = PALETTE.CoralYellow,
		},
		{
			ang = 1.96,
			rS = 1.01,
			y = -7.2,
			s = 1.45,
			col = PALETTE.CoralPurple,
			tip = PALETTE.CoralPink,
		},
		{
			ang = 1.12,
			rS = 1.01,
			y = -7.6,
			s = 1.45,
			col = PALETTE.CoralOrange,
			tip = PALETTE.CoralYellow,
		},
		{
			ang = 2.38,
			rS = 1.02,
			y = -6.6,
			s = 1.40,
			col = PALETTE.CoralPink,
			tip = PALETTE.CoralYellow,
		},
		{
			ang = 0.76,
			rS = 1.03,
			y = -6.4,
			s = 1.45,
			col = PALETTE.CoralLavender,
			tip = PALETTE.ShellCream,
		},
		{
			ang = 2.66,
			rS = 1.03,
			y = -4.2,
			s = 1.30,
			col = PALETTE.CoralOrange,
			tip = PALETTE.CoralYellow,
		},
	}
	for idx, an in ipairs(anemoneSpecs) do
		makeAnemone(
			coralFolder,
			"CliffAnemone_" .. idx,
			cliffOutCf(an.ang, an.rS, an.y, 74, 0),
			an.s,
			an.col,
			an.tip,
			rng
		)
	end

	-- 5. Hero Glowing Aqua Hex Crystals embedded in the cliff (crisp pointed spikes on flanks + front accents!)
	local crystalSpecs = {
		-- Prominent Left Flank Hero Crystal Cluster (jutting out just like the reference!)
		{ ang = 2.86, rS = 1.03, y = -3.8, rad = 1.65, h = 6.8, pitch = 74, light = true },
		{ ang = 2.64, rS = 1.01, y = -5.6, rad = 1.25, h = 4.8, pitch = 78, light = false },
		-- Prominent Right Flank Hero Crystal Cluster (jutting out just like the reference!)
		{ ang = 0.26, rS = 1.03, y = -3.6, rad = 1.70, h = 7.0, pitch = 74, light = true },
		{ ang = 0.44, rS = 1.01, y = -5.5, rad = 1.25, h = 4.9, pitch = 76, light = false },
		-- Front glowing aqua gems peeking brightly between colorful corals
		{ ang = 2.28, rS = 1.02, y = -4.6, rad = 1.15, h = 4.2, pitch = 72, light = false },
		{ ang = 1.76, rS = 0.99, y = -8.4, rad = 1.25, h = 4.6, pitch = 80, light = true },
		{ ang = 1.22, rS = 1.02, y = -5.2, rad = 1.35, h = 5.0, pitch = 74, light = true },
		{ ang = 0.98, rS = 0.98, y = -8.4, rad = 1.10, h = 4.2, pitch = 80, light = false },
		-- Back accents
		{ ang = 3.90, rS = 1.01, y = -4.8, rad = 1.25, h = 4.6, pitch = 74, light = false },
		{ ang = 5.40, rS = 1.01, y = -4.8, rad = 1.25, h = 4.6, pitch = 74, light = false },
	}
	for idx, cs in ipairs(crystalSpecs) do
		local cCf = cliffOutCf(cs.ang, cs.rS - 0.04, cs.y, cs.pitch, 0)
		buildHexCrystal(
			coralFolder,
			"CliffCrystal_" .. idx,
			cCf,
			cs.rad,
			cs.h,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			false,
			cs.light
		)
		-- Companion smaller crystal shard beside each main cliff crystal
		buildHexCrystal(
			coralFolder,
			"CliffCrystalSub_" .. idx,
			cliffOutCf(cs.ang + 0.06, cs.rS - 0.03, cs.y - 0.9, cs.pitch + 6, 14),
			cs.rad * 0.56,
			cs.h * 0.56,
			PALETTE.CrystalIce,
			PALETTE.CrystalCore,
			false,
			false
		)
	end

	-- 6. Small ambient fish schools swimming in the shallow sea just outside the island
	local schools = {
		{ center = Vector3.new(-54, -11.4, 24), yaw = math.rad(35), count = 11 },
		{ center = Vector3.new(-58, -11.4, -12), yaw = math.rad(-20), count = 9 },
		{ center = Vector3.new(54, -11.4, 16), yaw = math.rad(145), count = 11 },
		{ center = Vector3.new(56, -11.4, -14), yaw = math.rad(200), count = 8 },
	}
	for sIdx, sc in ipairs(schools) do
		local scCf = CFrame.new(origin + sc.center) * CFrame.Angles(0, sc.yaw, 0)
		for f = 1, sc.count do
			local fOff = Vector3.new(
				rng:NextNumber(-5.5, 5.5),
				rng:NextNumber(-0.3, 0.2),
				rng:NextNumber(-7.0, 7.0)
			)
			makeEllipsoid(
				coralFolder,
				"SeaFish_" .. sIdx .. "_" .. f,
				scCf * CFrame.new(fOff),
				Vector3.new(0.45, 0.22, 1.35),
				PALETTE.OceanFish,
				Enum.Material.SmoothPlastic,
				false,
				0.28,
				false
			)
		end
	end
end

-- ============================================================================
-- 3. STONE REEF PORTAL (CORAL-CROWNED ARCH + SPIRAL VORTEX + 3 STEPS)
-- ============================================================================

local function buildPortal(root: Model, origin: Vector3, rng: Random)
	local portalFolder = makeFolder(root, "StonePortal")
	local base = origin + PORTAL_LOCAL

	-- 3 wide rounded stone steps descending in front of the portal (walkable!)
	for s = 1, 3 do
		local y = (s - 1) * 0.52 + 0.26
		local zOff = 5.6 - (s - 1) * 1.55
		local w = 11.4 - (s - 1) * 1.1
		makePart(
			portalFolder,
			"Step_" .. s,
			CFrame.new(base + Vector3.new(0, y, zOff)),
			Vector3.new(w, 0.56, 2.0),
			if s % 2 == 0 then PALETTE.StoneMid else PALETTE.StoneLight,
			Enum.Material.Concrete,
			true,
			0,
			true
		)
		-- Rounded side shoulders on each step
		for side = -1, 1, 2 do
			makeCylinderY(
				portalFolder,
				"StepEnd_" .. s .. "_" .. side,
				CFrame.new(base + Vector3.new(side * (w * 0.5), y, zOff)),
				2.0,
				0.56,
				PALETTE.StoneMid,
				Enum.Material.Concrete,
				true,
				0,
				false
			)
		end
	end

	-- Solid stacked vertical stone pillar bases supporting the arch down to ground Y = 0!
	for side = -1, 1, 2 do
		for b = 1, 3 do
			local by = 1.05 + (b - 1) * 2.05
			local bx = side * (5.35 + rng:NextNumber(-0.12, 0.12))
			local bw = if b == 1 then 3.55 else 3.10 + rng:NextNumber(-0.12, 0.14)
			local bd = if b == 1 then 3.85 else 3.45
			local pCf = CFrame.new(base + Vector3.new(bx, by, rng:NextNumber(-0.08, 0.08)))
				* CFrame.Angles(0, rng:NextNumber(-0.04, 0.04), rng:NextNumber(-0.03, 0.03))
			makePart(
				portalFolder,
				"PillarBase_" .. side .. "_" .. b,
				pCf,
				Vector3.new(bw, 2.00, bd),
				if b % 2 == 0 then PALETTE.StoneLight else PALETTE.StoneMid,
				Enum.Material.Concrete,
				false,
				0,
				true
			)
			makeEllipsoid(
				portalFolder,
				"PillarBevel_" .. side .. "_" .. b,
				pCf * CFrame.new(0, 0, 0.18),
				Vector3.new(bw * 1.05, 2.15, bd * 0.90),
				if b % 2 == 0 then PALETTE.StoneMid else PALETTE.StoneLight,
				Enum.Material.Concrete,
				false,
				0,
				false
			)
			makePart(
				portalFolder,
				"PillarJoint_" .. side .. "_" .. b,
				pCf * CFrame.new(0, 1.02, 0),
				Vector3.new(bw * 0.90, 0.18, bd * 0.88),
				PALETTE.StoneJoint,
				Enum.Material.Concrete,
				false,
				0,
				false
			)
		end
	end

	-- Thick horseshoe stone arch (13 sculpted blocks curving seamlessly from the pillar bases)
	local archSteps = 13
	for i = 1, archSteps do
		local t = (i - 1) / (archSteps - 1)
		local theta = math.rad(185 - t * 190)
		local rx = 5.45
		local ry = 7.45
		local cx = math.cos(theta) * rx
		local cy = 7.25 + math.sin(theta) * ry
		local isKey = (i == 7)
		local isFoot = (i == 1 or i == archSteps)

		local blockCf = CFrame.new(base + Vector3.new(cx, cy, rng:NextNumber(-0.10, 0.10)))
			* CFrame.Angles(0, rng:NextNumber(-0.04, 0.04), theta - math.rad(90))
		local bw = if isKey then 3.25 elseif isFoot then 3.35 else 2.75 + rng:NextNumber(-0.12, 0.18)
		local bh = if isKey then 3.15 else 2.55 + rng:NextNumber(-0.10, 0.14)
		local bd = if isKey then 3.65 else 3.35

		makePart(
			portalFolder,
			"ArchStone_" .. i,
			blockCf,
			Vector3.new(bw, bh, bd),
			if i % 2 == 0 then PALETTE.StoneLight else PALETTE.StoneMid,
			Enum.Material.Concrete,
			false,
			0,
			true
		)
		-- Rounded stone bevel cap for organic hand-carved look
		makeEllipsoid(
			portalFolder,
			"ArchBevel_" .. i,
			blockCf * CFrame.new(0, 0, 0.22),
			Vector3.new(bw * 1.06, bh * 1.02, bd * 0.88),
			if i % 3 == 0 then PALETTE.StoneMid else PALETTE.StoneLight,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
		-- Dark mortar joint
		if i < archSteps then
			makePart(
				portalFolder,
				"Joint_" .. i,
				blockCf * CFrame.new(bw * 0.48, 0, 0),
				Vector3.new(0.22, bh * 0.90, bd * 0.86),
				PALETTE.StoneJoint,
				Enum.Material.Concrete,
				false,
				0,
				false
			)
		end

		-- 3 Upright Glowing Aqua Diamond Gems embedded on Left Pillar (i=2), Keystone (i=7), Right Pillar (i=12)
		if i == 2 or i == 7 or i == 12 then
			local gemWorldPos = (blockCf * CFrame.new(0, 0, bd * 0.54)).Position
			local uprightCf = CFrame.new(gemWorldPos) -- always vertical upright diamond!
			local gScale = if i == 7 then 1.15 else 0.94
			-- Dark carved diamond socket
			makePart(
				portalFolder,
				"GemSocket_" .. i,
				uprightCf * CFrame.Angles(0, 0, math.rad(45)),
				Vector3.new(1.32 * gScale, 1.32 * gScale, 0.28),
				PALETTE.StoneJoint,
				Enum.Material.Concrete,
				false,
				0,
				false
			)
			-- Faceted glowing aqua diamond gem standing upright
			buildHexCrystal(
				portalFolder,
				"ArchGem_" .. i,
				uprightCf * CFrame.new(0, -1.0 * gScale, 0.14),
				0.58 * gScale,
				2.05 * gScale,
				PALETTE.CrystalCyan,
				PALETTE.CrystalCore,
				true,
				false
			)
		end
	end

	-- Rich Corals, Shells & Aqua Crystals crowning and framing the Portal Arch (faithful to reference!)
	-- Top-right orange branching coral
	makeBranchCoral(
		portalFolder,
		"CrownCoralTopR",
		CFrame.new(base + Vector3.new(2.2, 15.6, 0.5)) * CFrame.Angles(0.1, 0, -0.22),
		1.15,
		PALETTE.CoralOrange,
		rng
	)
	-- Top-left coral & pink fan
	makeBranchCoral(
		portalFolder,
		"CrownCoralTopL",
		CFrame.new(base + Vector3.new(-2.4, 15.1, 0.6)) * CFrame.Angles(0.1, 0, 0.28),
		1.05,
		PALETTE.CoralPink,
		rng
	)
	makeFanCoral(
		portalFolder,
		"CrownFanL",
		CFrame.new(base + Vector3.new(-4.4, 13.6, 1.1)) * CFrame.Angles(0.25, 0.2, 0.55),
		0.85,
		PALETTE.CoralPeach,
		rng
	)
	-- Shells embedded on arch shoulders
	makeShell(
		portalFolder,
		"ArchShellL",
		CFrame.new(base + Vector3.new(-4.8, 12.2, 1.65)) * CFrame.Angles(math.rad(72), 0.2, 0.4),
		1.15,
		PALETTE.ShellPink
	)
	makeShell(
		portalFolder,
		"ArchShellR",
		CFrame.new(base + Vector3.new(4.8, 12.6, 1.65)) * CFrame.Angles(math.rad(72), -0.2, -0.45),
		1.05,
		PALETTE.ShellCream
	)
	-- Side mid-arch corals
	makeBranchCoral(
		portalFolder,
		"MidCoralR",
		CFrame.new(base + Vector3.new(6.6, 5.4, 1.2)) * CFrame.Angles(0.2, 0, -0.58),
		1.18,
		PALETTE.CoralPurple,
		rng
	)
	makeBranchCoral(
		portalFolder,
		"MidCoralL",
		CFrame.new(base + Vector3.new(-6.6, 4.4, 1.4)) * CFrame.Angles(0.2, 0, 0.55),
		1.05,
		PALETTE.CoralOrange,
		rng
	)

	-- Base feet: rich coral clusters + aqua crystal clusters + scattered pastel shells
	for side = -1, 1, 2 do
		makeBranchCoral(
			portalFolder,
			"FootCoral_" .. side,
			CFrame.new(base + Vector3.new(side * 6.8, 0.3, 1.8))
				* CFrame.Angles(0.15, 0, -side * 0.28),
			1.25,
			if side < 0 then PALETTE.CoralOrange else PALETTE.CoralPurple,
			rng
		)
		makeFanCoral(
			portalFolder,
			"FootFan_" .. side,
			CFrame.new(base + Vector3.new(side * 5.8, 0.4, 2.5))
				* CFrame.Angles(0.3, 0, -side * 0.22),
			0.95,
			if side < 0 then PALETTE.CoralPink else PALETTE.CoralLavender,
			rng
		)
		buildHexCrystal(
			portalFolder,
			"FootCrystalMain_" .. side,
			CFrame.new(base + Vector3.new(side * 5.6, 0.2, 3.0))
				* CFrame.Angles(0.18, 0, -side * 0.22),
			0.74,
			3.3,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			false,
			false
		)
		buildHexCrystal(
			portalFolder,
			"FootCrystalSub_" .. side,
			CFrame.new(base + Vector3.new(side * 6.5, 0.2, 3.3))
				* CFrame.Angles(0.24, 0.2, -side * 0.38),
			0.48,
			2.1,
			PALETTE.CrystalIce,
			PALETTE.CrystalCore,
			false,
			false
		)
		makeShell(
			portalFolder,
			"FootShell_" .. side,
			CFrame.new(base + Vector3.new(side * 6.1, 0.28, 4.5)) * CFrame.Angles(0, side * 0.6, 0),
			1.10,
			if side < 0 then PALETTE.CoralLavender else PALETTE.ShellPink
		)
	end
	makeShell(
		portalFolder,
		"StepShellExtra",
		CFrame.new(base + Vector3.new(7.4, 0.24, 3.8)) * CFrame.Angles(0, 1.2, 0),
		0.95,
		PALETTE.ShellCream
	)

	-- Glowing Aqua-White Spiral Vortex Interior (crisp radiant spiral visible straight-on AND from angles!)
	local vortexCf = CFrame.new(base + Vector3.new(0, 7.2, 0))
	makeEllipsoid(
		portalFolder,
		"PortalBackdrop",
		vortexCf * CFrame.new(0, 0, -0.25),
		Vector3.new(8.6, 12.6, 0.22),
		Color3.fromRGB(36, 198, 236),
		Enum.Material.SmoothPlastic,
		false,
		0.36,
		false
	)
	makeEllipsoid(
		portalFolder,
		"PortalInnerGlow",
		vortexCf * CFrame.new(0, 0, -0.14),
		Vector3.new(7.2, 10.8, 0.26),
		PALETTE.CrystalCyan,
		Enum.Material.Neon,
		false,
		0.48,
		false
	)
	makeEllipsoid(
		portalFolder,
		"PortalWhiteCore",
		vortexCf * CFrame.new(0, 0, -0.06),
		Vector3.new(3.4, 5.6, 0.24),
		PALETTE.PortalWhite,
		Enum.Material.Neon,
		false,
		0.42,
		false
	)

	-- 2 luminous swirling spiral arms placed cleanly IN FRONT of the backdrop so they always pop!
	for arm = 0, 1 do
		local armModel = makeModel(portalFolder, "PortalSpiralArm_" .. (arm + 1))
		local hub = makePart(
			armModel,
			"Center",
			vortexCf,
			Vector3.new(0.2, 0.2, 0.2),
			PALETTE.CrystalCyan,
			Enum.Material.SmoothPlastic,
			false,
			1,
			false
		)
		hub.CanQuery = false
		armModel.PrimaryPart = hub
		armModel:SetAttribute("VortexIndex", arm + 1)

		local steps = 28
		local prevPt: Vector3? = nil
		for sIdx = 0, steps do
			local t = sIdx / steps
			local ang = t * math.pi * 4.0 + arm * math.pi
			local rx = 0.22 + t * 3.55
			local ry = 0.30 + t * 5.25
			local curPt = (vortexCf * CFrame.new(math.cos(ang) * rx, math.sin(ang) * ry, 0.22)).Position
			if prevPt then
				local col = if t < 0.34
					then PALETTE.PortalWhite
					elseif t < 0.70 then PALETTE.CrystalCore
					else PALETTE.CrystalCyan
				makeSegment(
					armModel,
					"Swirl_" .. sIdx,
					prevPt,
					curPt,
					0.34 + (1 - t) * 0.22,
					col,
					Enum.Material.Neon,
					true,
					false,
					false,
					0.04 + t * 0.16
				)
			end
			prevPt = curPt
		end
	end

	-- Spinning concentric neon rings framing the vortex
	local spinRing = makeNeonRing(
		portalFolder,
		"PortalSpinningRing",
		vortexCf * CFrame.new(0, 0, 0.28) * CFrame.Angles(math.rad(90), 0, 0),
		3.65,
		0.24,
		0.30,
		32,
		PALETTE.CrystalCore,
		0.16
	)
	spinRing:SetAttribute("SpinSpeed", 0.85)
	makeNeonRing(
		portalFolder,
		"PortalOuterRing",
		vortexCf * CFrame.new(0, 0, 0.24) * CFrame.Angles(math.rad(90), 0, 0),
		4.05,
		0.18,
		0.22,
		32,
		PALETTE.CrystalCyan,
		0.42
	)

	-- Contained portal light (illuminates steps without washing out gray stone!) + rising sparkles
	local lightAnchor = makePart(
		portalFolder,
		"PortalLightAnchor",
		vortexCf * CFrame.new(0, 0, 0.4),
		Vector3.new(5.5, 8.5, 0.6),
		PALETTE.CrystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	lightAnchor.CanQuery = false
	local pLight = Instance.new("PointLight")
	pLight.Color = PALETTE.CrystalCyan
	pLight.Brightness = 0.85
	pLight.Range = 12
	pLight.Parent = lightAnchor

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "PortalSparkles"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.PortalWhite),
		ColorSequenceKeypoint.new(1, PALETTE.CrystalCyan),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.30),
		NumberSequenceKeypoint.new(0.5, 0.38),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(1.4, 2.6)
	emitter.Speed = NumberRange.new(1.0, 2.4)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.Rate = 12
	emitter.LightEmission = 1
	emitter.Parent = lightAnchor
end

-- ============================================================================
-- 4. CENTRAL WOODEN BRIDGE, STEPPING-STONE PATHS & CARVED FISH SIGNS
-- ============================================================================

local function buildCentralBridgeAndPaths(root: Model, origin: Vector3, rng: Random)
	local pathFolder = makeFolder(root, "BridgeAndPaths")
	local woodTones =
		{ PALETTE.WoodWarm1, PALETTE.WoodWarm2, PALETTE.WoodWarm3, PALETTE.WoodWeathered }

	-- Flat stepping stones & pastel shells along north (portal -> bridge) and south (bridge -> beach) paths
	local function placePathStones(zStart: number, zEnd: number, stoneCount: number)
		for i = 1, stoneCount do
			local t = (i - 0.5) / stoneCount
			local z = zStart + (zEnd - zStart) * t
			local x = rng:NextNumber(-2.9, 2.9)
			makeEllipsoid(
				pathFolder,
				"PathStone_" .. zStart .. "_" .. i,
				CFrame.new(origin + Vector3.new(x, -0.02, z))
					* CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
				Vector3.new(rng:NextNumber(1.75, 2.95), 0.22, rng:NextNumber(1.30, 2.15)),
				if i % 2 == 0 then PALETTE.StoneLight else PALETTE.StoneMid,
				Enum.Material.Concrete,
				false,
				0,
				false
			)
			if i % 2 == 0 then
				local sx = x
					+ (if x > 0 then -rng:NextNumber(1.2, 2.2) else rng:NextNumber(1.2, 2.2))
				makeShell(
					pathFolder,
					"PathShell_" .. zStart .. "_" .. i,
					CFrame.new(origin + Vector3.new(sx, 0.04, z + rng:NextNumber(-0.6, 0.6)))
						* CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
					rng:NextNumber(0.60, 0.92),
					if i % 4 == 0 then PALETTE.ShellPink else PALETTE.ShellCream
				)
			end
		end
	end
	placePathStones(-22.5, -10.5, 11)
	placePathStones(15.0, 32.5, 14)

	-- Central wooden rope-rail bridge (walkable, continuous smooth collider)
	local zNorth, zSouth = -9.5, 13.8
	local bridgeLen = zSouth - zNorth
	local bridgeW = 8.6
	local bridgeY = 0.36

	makePart(
		pathFolder,
		"BridgeCollider",
		CFrame.new(origin + Vector3.new(0, bridgeY - 0.04, (zNorth + zSouth) * 0.5)),
		Vector3.new(bridgeW, 0.44, bridgeLen + 1.4),
		PALETTE.WoodWarm1,
		Enum.Material.WoodPlanks,
		true,
		1,
		false
	)

	-- Side beams underneath
	for side = -1, 1, 2 do
		makePart(
			pathFolder,
			"BridgeBeam_" .. side,
			CFrame.new(
				origin
					+ Vector3.new(side * (bridgeW * 0.42), bridgeY - 0.22, (zNorth + zSouth) * 0.5)
			),
			Vector3.new(0.60, 0.48, bridgeLen + 0.6),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			true
		)
	end

	-- 20 individual wooden planks with slight arch & artisan variation
	local plankCount = 20
	for i = 1, plankCount do
		local t = (i - 0.5) / plankCount
		local z = zNorth + bridgeLen * t
		local archY = math.sin(t * math.pi) * 0.32
		makePart(
			pathFolder,
			"Plank_" .. i,
			CFrame.new(origin + Vector3.new(rng:NextNumber(-0.08, 0.08), bridgeY + archY, z))
				* CFrame.Angles(0, rng:NextNumber(-0.016, 0.016), 0),
			Vector3.new(
				bridgeW + rng:NextNumber(-0.22, 0.28),
				0.30,
				(bridgeLen / plankCount) - 0.13
			),
			woodTones[((i - 1) % #woodTones) + 1],
			Enum.Material.WoodPlanks,
			false,
			0,
			true
		)
	end

	-- 4 pairs of rounded posts with rope coils & sagging cylindrical ropes on both sides
	for side = -1, 1, 2 do
		local postTops: { Vector3 } = {}
		for p = 0, 3 do
			local t = p / 3
			local z = zNorth + 0.4 + (bridgeLen - 0.8) * t
			local archY = math.sin(t * math.pi) * 0.32
			local basePos = origin + Vector3.new(side * (bridgeW * 0.5 - 0.28), bridgeY + archY, z)
			makeCylinderY(
				pathFolder,
				"BridgePost_" .. side .. "_" .. p,
				CFrame.new(basePos + Vector3.new(0, 1.55, 0)),
				0.82,
				3.45,
				PALETTE.WoodDark,
				Enum.Material.Wood,
				false,
				0,
				true
			)
			makeEllipsoid(
				pathFolder,
				"PostCap_" .. side .. "_" .. p,
				CFrame.new(basePos + Vector3.new(0, 3.30, 0)),
				Vector3.new(0.94, 0.48, 0.94),
				PALETTE.WoodWarm3,
				Enum.Material.Wood,
				false,
				0,
				false
			)
			addRopeCoil(
				pathFolder,
				"PostRope_" .. side .. "_" .. p,
				basePos + Vector3.new(0, 2.55, 0),
				0.82,
				3
			)
			table.insert(postTops, basePos + Vector3.new(0, 2.55, 0))
		end
		for p = 1, #postTops - 1 do
			makeRope(
				pathFolder,
				"BridgeRope_" .. side .. "_" .. p,
				postTops[p],
				postTops[p + 1],
				0.58,
				7,
				0.28,
				PALETTE.RopeTan
			)
		end
	end

	-- 2 Carved Wooden Fish Signs matching reference positions (north arrow-sign + south square-sign)
	buildFishSignpost(
		pathFolder,
		"SignNorth",
		origin + Vector3.new(-7.4, 0, -14.2),
		origin + Vector3.new(-5.5, 0, 30.0),
		true
	)
	buildFishSignpost(
		pathFolder,
		"SignSouth",
		origin + Vector3.new(-9.6, 0, 20.8),
		origin + Vector3.new(-7.2, 0, 60.0),
		false
	)
end

-- ============================================================================
-- 5. FOCUS POND (LEFT: CRYSTAL WATER, REEF ISLETS, 3 RINGS, 3 HEX CRYSTALS)
-- ============================================================================

local function buildFocusPond(root: Model, origin: Vector3, rng: Random): Model
	local pond = makeModel(root, "FocusPond")
	local center = origin + Vector3.new(FOCUS_CENTER.X, 0, FOCUS_CENTER.Y)

	-- Bright pale-sand floor carved below Y = 0 (not pure white blowout!)
	local floor = makeEllipsoid(
		pond,
		"PondSandFloor",
		CFrame.new(center + Vector3.new(0, -1.70, 0)),
		Vector3.new(FOCUS_RX * 2.02, 0.72, FOCUS_RZ * 2.02),
		PALETTE.SandPondBed,
		Enum.Material.Sand,
		true,
		0,
		false
	)
	pond.PrimaryPart = floor

	-- Gentle turquoise shallow tint layer + concentric water caustics rings under the floating rings
	makeEllipsoid(
		pond,
		"ShallowTurquoiseGlow",
		CFrame.new(center + Vector3.new(-1.2, -1.25, -0.8)),
		Vector3.new(FOCUS_RX * 1.35, 0.24, FOCUS_RZ * 1.35),
		PALETTE.WaterFocus,
		Enum.Material.SmoothPlastic,
		false,
		0.52,
		false
	)
	local ringCenter = center + Vector3.new(-1.6, 0, -1.2)
	for i, rad in ipairs({ 2.4, 4.4, 6.5 }) do
		makeNeonRing(
			pond,
			"WaterRipple_" .. i,
			CFrame.new(ringCenter + Vector3.new(0, -0.22, 0)),
			rad,
			0.16,
			0.05,
			28,
			PALETTE.FocusRing,
			0.36 + i * 0.14
		)
	end

	-- Smooth curved shore edge + sandy inner slope + grass collar (eliminates stair-step!)
	local bankCount = 56
	for i = 1, bankCount do
		local a1 = (i / bankCount) * math.pi * 2
		local a2 = ((i + 1) / bankCount) * math.pi * 2
		local p1 = center + Vector3.new(math.cos(a1) * FOCUS_RX, -0.08, math.sin(a1) * FOCUS_RZ)
		local p2 = center + Vector3.new(math.cos(a2) * FOCUS_RX, -0.08, math.sin(a2) * FOCUS_RZ)
		local mid = (p1 + p2) * 0.5
		local segLen = (p2 - p1).Magnitude + 0.68
		local cf = CFrame.lookAt(mid, p2)

		-- Outer grass collar flush with terrain (-X = outside)
		local outX = mid.X - origin.X
		local outZ = mid.Z - origin.Z
		if not isOnCentralSandPath(outX, outZ) then
			makePart(
				pond,
				"GrassCollar_" .. i,
				cf * CFrame.new(-1.45, -0.10, 0),
				Vector3.new(3.2, 0.22, segLen * 1.12),
				PALETTE.GrassMain,
				Enum.Material.Grass,
				true,
				0,
				false
			)
		end
		-- Warm golden sand lip & inner slope (+X = inside)
		makePart(
			pond,
			"ShoreLip_" .. i,
			cf * CFrame.new(0.22, -0.06, 0),
			Vector3.new(1.45, 0.22, segLen * 1.10),
			PALETTE.SandLight,
			Enum.Material.Sand,
			false,
			0,
			false
		)
		makePart(
			pond,
			"BankSlope_" .. i,
			cf * CFrame.new(0.65, -1.15, 0) * CFrame.Angles(0, 0, math.rad(-18)),
			Vector3.new(2.0, 2.3, segLen),
			PALETTE.SandLight,
			Enum.Material.Sand,
			true,
			0,
			false
		)
	end

	-- Crystal-clear translucent Caribbean aqua water surface (SmoothPlastic reveals islets, coral rings & sand floor!)
	local water = makeEllipsoid(
		pond,
		"WaterSurface",
		CFrame.new(center + Vector3.new(0, -0.32, 0)),
		Vector3.new(FOCUS_RX * 2.02, 0.20, FOCUS_RZ * 2.02),
		Color3.fromRGB(116, 234, 240),
		Enum.Material.SmoothPlastic,
		false,
		0.62,
		false
	)
	water.Reflectance = 0.08

	-- 3 Lush Coral/Anemone Reef Islets + Coral Rings inside the clear water (exact reference detail!)
	local islets = {
		{
			off = Vector3.new(-6.6, -1.05, 4.4),
			sz = Vector3.new(6.8, 1.45, 4.8),
			colA = PALETTE.CoralPink,
			colB = PALETTE.CoralPurple,
		},
		{
			off = Vector3.new(4.2, -1.05, 6.0),
			sz = Vector3.new(5.4, 1.30, 4.2),
			colA = PALETTE.CoralOrange,
			colB = PALETTE.CoralYellow,
		},
		{
			off = Vector3.new(7.4, -1.05, -0.4),
			sz = Vector3.new(5.6, 1.30, 4.0),
			colA = PALETTE.CoralPurple,
			colB = PALETTE.CoralPink,
		},
	}
	for i, isl in ipairs(islets) do
		local pos = center + isl.off
		makeEllipsoid(
			pond,
			"IsletRock_" .. i,
			CFrame.new(pos),
			isl.sz,
			PALETTE.RockLight,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
		makeEllipsoid(
			pond,
			"IsletMoss_" .. i,
			CFrame.new(pos + Vector3.new(0, 0.45, 0)),
			isl.sz * Vector3.new(0.84, 0.55, 0.84),
			PALETTE.Moss,
			Enum.Material.Grass,
			false,
			0,
			false
		)
		makeAnemone(
			pond,
			"IsletAnemone_" .. i,
			CFrame.new(pos + Vector3.new(0.8, 0.58, 0.2)),
			0.85,
			isl.colA,
			PALETTE.ShellCream,
			rng
		)
		makeBranchCoral(
			pond,
			"IsletCoral_" .. i,
			CFrame.new(pos + Vector3.new(-1.1, 0.52, -0.3)),
			0.72,
			isl.colB,
			rng
		)
		makeFanCoral(
			pond,
			"IsletFan_" .. i,
			CFrame.new(pos + Vector3.new(0.2, 0.55, -0.8)) * CFrame.Angles(0.3, 0.4, 0),
			0.55,
			PALETTE.CoralPeach,
			rng
		)
	end

	-- 3 Coral-Ring Targets inside the pond (orange/coral rings on water floor just like reference!)
	local coralRingPositions = {
		Vector3.new(-3.8, -0.85, 6.2),
		Vector3.new(2.8, -0.85, 5.2),
		Vector3.new(5.4, -0.85, 1.4),
	}
	for idx, off in ipairs(coralRingPositions) do
		local rPos = center + off
		local segs = 12
		local rad = 1.45
		for s = 1, segs do
			local a = (s / segs) * math.pi * 2
			makeEllipsoid(
				pond,
				"CoralRing_" .. idx .. "_" .. s,
				CFrame.new(rPos + Vector3.new(math.cos(a) * rad, 0.28, math.sin(a) * rad)),
				Vector3.new(0.78, 0.60, 0.78),
				if s % 2 == 0 then Color3.fromRGB(238, 86, 54) else PALETTE.CoralOrange,
				Enum.Material.SmoothPlastic,
				false,
				0,
				false
			)
		end
	end

	-- Floating Pastel Target Shells on the clear water surface
	local shellOffsets = {
		{ off = Vector3.new(-10.2, -0.18, -3.0), col = PALETTE.ShellPink, s = 1.35 },
		{ off = Vector3.new(7.0, -0.18, -4.4), col = PALETTE.ShellCream, s = 1.30 },
		{ off = Vector3.new(-1.8, -0.18, -1.0), col = PALETTE.CoralLavender, s = 1.15 },
		{ off = Vector3.new(1.0, -0.18, 8.2), col = PALETTE.ShellPink, s = 1.05 },
	}
	for i, sh in ipairs(shellOffsets) do
		makeShell(
			pond,
			"TargetShell_" .. i,
			CFrame.new(center + sh.off) * CFrame.Angles(0, i * 1.15, 0),
			sh.s,
			sh.col
		)
	end

	-- 3 THICK, LUMINOUS STACKED AQUA RINGS floating above the Focus Pond (with soft outer halos!)
	local ringsFolder = makeFolder(pond, "FocusLightRings")
	local ringSpecs = {
		{ y = 2.0, r = 5.6, thick = 0.62, h = 0.38 },
		{ y = 5.4, r = 5.4, thick = 0.60, h = 0.36 },
		{ y = 8.8, r = 5.2, thick = 0.58, h = 0.34 },
	}
	for idx, rs in ipairs(ringSpecs) do
		local rCf = CFrame.new(ringCenter + Vector3.new(0, rs.y, 0))
		local ring = makeNeonRing(
			ringsFolder,
			"FocusRing_" .. idx,
			rCf,
			rs.r,
			rs.thick,
			rs.h,
			36,
			PALETTE.FocusRing,
			0.02
		)
		ring:SetAttribute("RingIndex", idx)
		ring:SetAttribute("BaseY", (ringCenter + Vector3.new(0, rs.y, 0)).Y)
		-- Soft aqua outer halo around each ring
		makeNeonRing(
			ringsFolder,
			"FocusRingHalo_" .. idx,
			rCf,
			rs.r + 0.24,
			rs.thick * 1.15,
			rs.h * 0.72,
			36,
			PALETTE.CrystalCyan,
			0.46
		)
	end

	-- 3 Tall Faceted Double-Pointed Aqua Hex Crystals floating above the rings (middle tallest!)
	local crystalBase = ringCenter + Vector3.new(0, 12.0, -0.8)
	local crystalDefs = {
		{
			name = "TallCrystalLeft",
			off = Vector3.new(-4.3, -0.8, 0.5),
			rad = 1.30,
			h = 7.4,
			light = false,
		},
		{
			name = "TallCrystalMid",
			off = Vector3.new(0.0, 0.6, 0.0),
			rad = 1.72,
			h = 10.6,
			light = true,
		},
		{
			name = "TallCrystalRight",
			off = Vector3.new(4.3, -1.1, 0.5),
			rad = 1.24,
			h = 6.8,
			light = false,
		},
	}
	for _, cd in ipairs(crystalDefs) do
		local cPos = crystalBase + cd.off
		buildHexCrystal(
			pond,
			cd.name,
			CFrame.new(cPos),
			cd.rad,
			cd.h,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			true,
			cd.light
		)
		-- Subtle translucent downward light beam from each floating crystal to the rings
		local bTop = makePart(
			pond,
			cd.name .. "_BeamTop",
			CFrame.new(cPos + Vector3.new(0, cd.h * 0.18, 0)),
			Vector3.new(0.2, 0.2, 0.2),
			PALETTE.CrystalCyan,
			Enum.Material.SmoothPlastic,
			false,
			1,
			false
		)
		bTop.CanQuery = false
		local bBot = makePart(
			pond,
			cd.name .. "_BeamBot",
			CFrame.new(cPos.X, center.Y + 0.2, cPos.Z),
			Vector3.new(0.2, 0.2, 0.2),
			PALETTE.CrystalCyan,
			Enum.Material.SmoothPlastic,
			false,
			1,
			false
		)
		bBot.CanQuery = false
		local att0 = Instance.new("Attachment")
		att0.Parent = bTop
		local att1 = Instance.new("Attachment")
		att1.Parent = bBot
		local beam = Instance.new("Beam")
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.FaceCamera = true
		beam.Width0 = cd.rad * 2.1
		beam.Width1 = cd.rad * 3.0
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Color = ColorSequence.new(PALETTE.CrystalCore, PALETTE.CrystalCyan)
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.68),
			NumberSequenceKeypoint.new(0.55, 0.84),
			NumberSequenceKeypoint.new(1, 1.0),
		})
		beam.Parent = bTop
	end

	-- Gentle rising aqua light motes in Focus Pond
	local moteAnchor = makePart(
		pond,
		"FocusMoteAnchor",
		CFrame.new(ringCenter + Vector3.new(0, 0.4, 0)),
		Vector3.new(7.5, 0.2, 7.5),
		PALETTE.FocusRing,
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	moteAnchor.CanQuery = false
	local motes = Instance.new("ParticleEmitter")
	motes.Color = ColorSequence.new(PALETTE.FocusRing, PALETTE.CrystalCyan)
	motes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	motes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(1, 1),
	})
	motes.Lifetime = NumberRange.new(2.0, 3.4)
	motes.Speed = NumberRange.new(1.2, 2.4)
	motes.Rate = 9
	motes.LightEmission = 1
	motes.Parent = moteAnchor

	-- Long planked wooden deck along back-left shore of Focus Pond (with 2 stools, barrel & fishing post!)
	local deckCf = CFrame.new(origin + Vector3.new(-22.5, 0.62, -10.8))
		* CFrame.Angles(0, math.rad(14), 0)
	buildPlankedDeck(pond, "FocusDeckModel", "FocusDeck", deckCf, 22.5, 7.0, 15, 4, rng)
	makeStool(pond, "FocusStool1", deckCf * CFrame.new(-5.8, 0.20, 0.6))
	makeStool(pond, "FocusStool2", deckCf * CFrame.new(5.2, 0.20, 0.8))
	makeBarrel(pond, "FocusBarrel", deckCf * CFrame.new(-9.2, 0.20, -0.4), 0.96)

	-- Mooring fishing post with hanging rope & fish gear on far-left end of Focus Deck (visible in reference!)
	local gearPostBase = (deckCf * CFrame.new(-12.2, -0.62, 1.4)).Position
	makeCylinderY(
		pond,
		"FishingGearPost",
		CFrame.new(gearPostBase + Vector3.new(0, 2.3, 0)),
		0.68,
		4.8,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		true
	)
	makePart(
		pond,
		"FishingGearCrossbar",
		CFrame.new(gearPostBase + Vector3.new(0, 3.7, 0)) * CFrame.Angles(0, math.rad(15), 0),
		Vector3.new(2.6, 0.34, 0.34),
		PALETTE.WoodWarm2,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	addRopeCoil(pond, "GearPostCoil", gearPostBase + Vector3.new(0, 3.3, 0), 0.68, 3)
	-- Hanging rope & wooden float/bag
	makeSegment(
		pond,
		"HangRope",
		gearPostBase + Vector3.new(0.85, 3.6, 0.2),
		gearPostBase + Vector3.new(0.85, 1.6, 0.2),
		0.14,
		PALETTE.RopeTan,
		Enum.Material.Fabric,
		true,
		false,
		false
	)
	makeEllipsoid(
		pond,
		"HangPouch",
		CFrame.new(gearPostBase + Vector3.new(0.85, 1.35, 0.2)),
		Vector3.new(0.85, 1.15, 0.72),
		PALETTE.WoodWarm1,
		Enum.Material.Fabric,
		false,
		0,
		false
	)

	return pond
end

-- ============================================================================
-- 6. INSTINCT POND (RIGHT: PURPLE-TEAL GRADIENT, JELLYFISH, RUNES, GIANT CLAM)
-- ============================================================================

local function buildRuneStone(
	parent: Instance,
	name: string,
	pos: Vector3,
	faceTarget: Vector3,
	size: Vector3,
	glyphKind: string
): Model
	local stone = makeModel(parent, name)
	local cf = CFrame.lookAt(pos, Vector3.new(faceTarget.X, pos.Y, faceTarget.Z))

	-- Organic sculpted standing rune monolith (chunky tapered stone boulder + angled cap, no boxy corners!)
	local body = makeEllipsoid(
		stone,
		"StoneBody",
		cf * CFrame.new(0, size.Y * 0.42, 0) * CFrame.Angles(math.rad(-4), 0, math.rad(3)),
		Vector3.new(size.X * 1.06, size.Y * 1.02, size.Z * 0.92),
		PALETTE.StoneRune,
		Enum.Material.Concrete,
		false,
		0,
		true
	)
	stone.PrimaryPart = body
	makeEllipsoid(
		stone,
		"StoneShoulderL",
		cf * CFrame.new(-size.X * 0.24, size.Y * 0.28, 0.08),
		Vector3.new(size.X * 0.78, size.Y * 0.68, size.Z * 0.84),
		PALETTE.StoneMid,
		Enum.Material.Concrete,
		false,
		0,
		false
	)
	makeEllipsoid(
		stone,
		"StonePeak",
		cf * CFrame.new(size.X * 0.08, size.Y * 0.78, -0.04) * CFrame.Angles(0, 0, math.rad(-10)),
		Vector3.new(size.X * 0.72, size.Y * 0.48, size.Z * 0.76),
		PALETTE.StoneLight,
		Enum.Material.Concrete,
		false,
		0,
		false
	)

	-- Glowing 3D Neon cyan rune strokes carved on front face (-Z of cf; note +X in lookAt is viewer-left, so negate X for viewer-right!)
	local faceCf = cf * CFrame.new(0, size.Y * 0.46, -size.Z * 0.46)
	local rw = size.X * 0.23
	local rh = size.Y * 0.23
	local strokes: { { Vector2 } }
	if glyphKind == "R" then
		-- Properly oriented "R" facing viewer (+X = viewer-left, -X = viewer-right)
		strokes = {
			{ Vector2.new(rw * 0.60, -rh), Vector2.new(rw * 0.60, rh) },
			{ Vector2.new(rw * 0.60, rh), Vector2.new(-rw * 0.72, rh * 0.34) },
			{ Vector2.new(-rw * 0.72, rh * 0.34), Vector2.new(rw * 0.54, -rh * 0.04) },
			{ Vector2.new(rw * 0.36, -rh * 0.04), Vector2.new(-rw * 0.74, -rh) },
		}
	elseif glyphKind == "TRI" then
		strokes = {
			{ Vector2.new(-rw * 0.72, rh * 0.78), Vector2.new(rw * 0.72, rh * 0.78) },
			{ Vector2.new(rw * 0.72, rh * 0.78), Vector2.new(0, -rh * 0.88) },
			{ Vector2.new(0, -rh * 0.88), Vector2.new(-rw * 0.72, rh * 0.78) },
			{ Vector2.new(0, rh * 0.42), Vector2.new(0, -rh * 0.25) },
		}
	else
		-- Diamond/algiz rune on back stone between decks
		strokes = {
			{ Vector2.new(0, rh), Vector2.new(-rw * 0.68, 0) },
			{ Vector2.new(0, rh), Vector2.new(rw * 0.68, 0) },
			{ Vector2.new(-rw * 0.68, 0), Vector2.new(0, -rh) },
			{ Vector2.new(rw * 0.68, 0), Vector2.new(0, -rh) },
			{ Vector2.new(0, rh * 0.42), Vector2.new(0, -rh * 0.42) },
		}
	end

	for sIdx, segPts in ipairs(strokes) do
		local pA = (faceCf * CFrame.new(segPts[1].X, segPts[1].Y, 0)).Position
		local pB = (faceCf * CFrame.new(segPts[2].X, segPts[2].Y, 0)).Position
		makeSegment(
			stone,
			"RuneStroke_" .. sIdx,
			pA,
			pB,
			0.16,
			PALETTE.CrystalCyan,
			Enum.Material.Neon,
			true,
			false,
			false
		)
	end

	local lightPt = makePart(
		stone,
		"RuneLight",
		faceCf * CFrame.new(0, 0, -0.3),
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.CrystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	lightPt.CanQuery = false
	local pl = Instance.new("PointLight")
	pl.Color = PALETTE.CrystalCyan
	pl.Brightness = 0.85
	pl.Range = 7.5
	pl.Parent = lightPt

	return stone
end

-- Detailed bioluminescent Jellyfish (translucent dome + glowing core + scalloped rim + curved wavy tentacles)
local function buildJellyfish(
	parent: Instance,
	name: string,
	pos: Vector3,
	scale: number,
	outerColor: Color3,
	coreColor: Color3,
	orbitR: number,
	orbitS: number,
	orbitPh: number
): Model
	local jm = makeModel(parent, name)
	jm:SetAttribute("OrbitRadius", orbitR)
	jm:SetAttribute("OrbitSpeed", orbitS)
	jm:SetAttribute("OrbitPhase", orbitPh)

	-- Outer translucent bell
	local bell = makeEllipsoid(
		jm,
		"BellOuter",
		CFrame.new(pos),
		Vector3.new(2.7 * scale, 1.85 * scale, 2.7 * scale),
		outerColor,
		Enum.Material.SmoothPlastic,
		false,
		0.40,
		false
	)
	jm.PrimaryPart = bell
	-- Inner bright Neon core
	makeEllipsoid(
		jm,
		"BellCore",
		CFrame.new(pos + Vector3.new(0, 0.12 * scale, 0)),
		Vector3.new(1.85 * scale, 1.25 * scale, 1.85 * scale),
		coreColor,
		Enum.Material.Neon,
		false,
		0.14,
		false
	)
	-- Glowing rim ring
	makeNeonRing(
		jm,
		"BellRim",
		CFrame.new(pos + Vector3.new(0, -0.45 * scale, 0)),
		1.15 * scale,
		0.16 * scale,
		0.14 * scale,
		16,
		coreColor,
		0.18
	)

	-- 7 wavy multi-segment curved tentacles trailing gently downward
	for t = 1, 7 do
		local a = (t / 7) * math.pi * 2
		local r = (if t == 1 then 0.15 else 0.72) * scale
		local prev = pos + Vector3.new(math.cos(a) * r, -0.55 * scale, math.sin(a) * r)
		local segs = 4
		for s = 1, segs do
			local frac = s / segs
			local wave = math.sin(frac * math.pi * 1.8 + t) * 0.28 * scale
			local nxt = pos
				+ Vector3.new(
					math.cos(a) * (r + wave),
					(-0.55 - frac * 2.55) * scale,
					math.sin(a) * (r + wave)
				)
			makeSegment(
				jm,
				"Tent_" .. t .. "_" .. s,
				prev,
				nxt,
				(0.14 - frac * 0.05) * scale,
				if s % 2 == 0 then outerColor else coreColor,
				Enum.Material.Neon,
				true,
				false,
				false,
				0.22 + frac * 0.22
			)
			prev = nxt
		end
	end

	return jm
end

-- Detailed Giant Open Scalloped Clam Shell with Luminous Pearl
local function buildGiantClam(parent: Instance, cf: CFrame): Model
	local clam = makeModel(parent, "GiantClam")

	-- Helper to build one scalloped multi-ribbed clam valve (prominent lilac outer ribs + soft pink inner shell!)
	local function buildValve(prefix: string, valveCf: CFrame, isTop: boolean)
		local signY = if isTop then -1 else 1
		local ribs = 7
		local baseLen = if isTop then 5.8 else 5.2
		for i = 1, ribs do
			local t = (i - 1) / (ribs - 1) - 0.5
			local yaw = t * 1.28
			local len = (baseLen - math.abs(t) * 1.15)
			local rCf = valveCf * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, len * 0.48)
			-- Outer lilac ribbed shell
			makeEllipsoid(
				clam,
				prefix .. "_Outer_" .. i,
				rCf * CFrame.new(0, -0.22 * signY, 0),
				Vector3.new(1.65, 0.88, len),
				PALETTE.ClamOuter,
				Enum.Material.SmoothPlastic,
				false,
				0,
				true
			)
			-- Inner soft pearlescent pink lining
			makeEllipsoid(
				clam,
				prefix .. "_Inner_" .. i,
				rCf * CFrame.new(0, 0.20 * signY, 0.14),
				Vector3.new(1.36, 0.54, len * 0.90),
				PALETTE.ClamInner,
				Enum.Material.SmoothPlastic,
				false,
				0,
				false
			)
		end
	end

	buildValve("Bottom", cf * CFrame.new(0, 0.45, -1.9) * CFrame.Angles(math.rad(6), 0, 0), false)
	buildValve("Top", cf * CFrame.new(0, 1.15, -2.0) * CFrame.Angles(math.rad(-64), 0, 0), true)

	-- Soft cushion bed & crisp radiant Pearl (never blown out into a blinding white cloud!)
	makeEllipsoid(
		clam,
		"PearlCushion",
		cf * CFrame.new(0, 0.88, 0.2),
		Vector3.new(3.4, 0.65, 3.0),
		PALETTE.ShellPink,
		Enum.Material.SmoothPlastic,
		false,
		0,
		false
	)
	local pearl = makeEllipsoid(
		clam,
		"GiantPearl",
		cf * CFrame.new(0, 1.92, 0.35),
		Vector3.new(1.88, 1.88, 1.88),
		Color3.fromRGB(228, 246, 252),
		Enum.Material.SmoothPlastic,
		false,
		0,
		false
	)
	pearl.Reflectance = 0.25
	clam.PrimaryPart = pearl
	-- Inner subtle pearlescent glow core + soft thin aqua aura
	makeEllipsoid(
		clam,
		"PearlInnerGlow",
		cf * CFrame.new(0, 1.92, 0.35),
		Vector3.new(1.96, 1.96, 1.96),
		PALETTE.PearlGlow,
		Enum.Material.Neon,
		false,
		0.72,
		false
	)
	makeEllipsoid(
		clam,
		"PearlHalo",
		cf * CFrame.new(0, 1.92, 0.35),
		Vector3.new(2.45, 2.45, 2.45),
		PALETTE.CrystalCyan,
		Enum.Material.Neon,
		false,
		0.88,
		false
	)

	local pearlLight = Instance.new("PointLight")
	pearlLight.Color = PALETTE.CrystalCore
	pearlLight.Brightness = 0.95
	pearlLight.Range = 11
	pearlLight.Parent = pearl

	return clam
end

local function buildInstinctPond(root: Model, origin: Vector3, rng: Random): Model
	local pond = makeModel(root, "InstinctPond")
	local center = origin + Vector3.new(INSTINCT_CENTER.X, 0, INSTINCT_CENTER.Y)

	-- 7-layer dreamy nebula gradient: deep violet -> royal purple -> magenta-indigo -> ocean blue -> soft turquoise glow!
	local outerFloor = makeEllipsoid(
		pond,
		"PondFloorOuter",
		CFrame.new(center + Vector3.new(0, -1.95, 0)),
		Vector3.new(INSTINCT_RX * 2.02, 0.76, INSTINCT_RZ * 2.02),
		PALETTE.InstinctDeep,
		Enum.Material.SmoothPlastic,
		true,
		0,
		false
	)
	pond.PrimaryPart = outerFloor

	makeEllipsoid(
		pond,
		"PondFloorViolet",
		CFrame.new(center + Vector3.new(0, -1.62, 0)),
		Vector3.new(INSTINCT_RX * 1.90, 0.42, INSTINCT_RZ * 1.90),
		PALETTE.InstinctOuter,
		Enum.Material.Neon,
		false,
		0.50,
		false
	)
	makeEllipsoid(
		pond,
		"PondFloorIndigo",
		CFrame.new(center + Vector3.new(0.4, -1.46, -0.3)),
		Vector3.new(INSTINCT_RX * 1.62, 0.36, INSTINCT_RZ * 1.62),
		PALETTE.InstinctMid,
		Enum.Material.SmoothPlastic,
		false,
		0.32,
		false
	)
	makeEllipsoid(
		pond,
		"PondFloorBlueViolet",
		CFrame.new(center + Vector3.new(0.8, -1.32, -0.5)),
		Vector3.new(INSTINCT_RX * 1.32, 0.30, INSTINCT_RZ * 1.32),
		Color3.fromRGB(72, 118, 224),
		Enum.Material.SmoothPlastic,
		false,
		0.36,
		false
	)
	makeEllipsoid(
		pond,
		"PondFloorTeal",
		CFrame.new(center + Vector3.new(1.0, -1.18, -0.6)),
		Vector3.new(INSTINCT_RX * 1.04, 0.26, INSTINCT_RZ * 1.04),
		PALETTE.InstinctTeal,
		Enum.Material.SmoothPlastic,
		false,
		0.40,
		false
	)
	local coreGlow = makeEllipsoid(
		pond,
		"PondFloorTurquoise",
		CFrame.new(center + Vector3.new(1.1, -1.04, -0.6)),
		Vector3.new(INSTINCT_RX * 0.72, 0.22, INSTINCT_RZ * 0.72),
		PALETTE.InstinctCore,
		Enum.Material.Neon,
		false,
		0.44,
		false
	)
	makeEllipsoid(
		pond,
		"PondFloorCyanHeart",
		CFrame.new(center + Vector3.new(1.1, -0.96, -0.6)),
		Vector3.new(INSTINCT_RX * 0.42, 0.18, INSTINCT_RZ * 0.42),
		PALETTE.CrystalCyan,
		Enum.Material.Neon,
		false,
		0.48,
		false
	)

	local cLight = Instance.new("PointLight")
	cLight.Color = PALETTE.InstinctCore
	cLight.Brightness = 1.45
	cLight.Range = 17
	cLight.Parent = coreGlow

	-- Smooth curved shore edge + glowing purple rim inside the water
	local bankCount = 56
	for i = 1, bankCount do
		local a1 = (i / bankCount) * math.pi * 2
		local a2 = ((i + 1) / bankCount) * math.pi * 2
		local p1 = center
			+ Vector3.new(math.cos(a1) * INSTINCT_RX, -0.08, math.sin(a1) * INSTINCT_RZ)
		local p2 = center
			+ Vector3.new(math.cos(a2) * INSTINCT_RX, -0.08, math.sin(a2) * INSTINCT_RZ)
		local mid = (p1 + p2) * 0.5
		local segLen = (p2 - p1).Magnitude + 0.68
		local cf = CFrame.lookAt(mid, p2)

		local outX = mid.X - origin.X
		local outZ = mid.Z - origin.Z
		if not isOnCentralSandPath(outX, outZ) then
			makePart(
				pond,
				"GrassCollar_" .. i,
				cf * CFrame.new(-1.45, -0.10, 0),
				Vector3.new(3.2, 0.22, segLen * 1.12),
				PALETTE.GrassMain,
				Enum.Material.Grass,
				true,
				0,
				false
			)
		end
		makePart(
			pond,
			"ShoreLip_" .. i,
			cf * CFrame.new(0.20, -0.06, 0),
			Vector3.new(1.35, 0.22, segLen * 1.10),
			PALETTE.SandWarm,
			Enum.Material.Sand,
			false,
			0,
			false
		)
		makePart(
			pond,
			"BankSlope_" .. i,
			cf * CFrame.new(0.65, -1.25, 0) * CFrame.Angles(0, 0, math.rad(-16)),
			Vector3.new(1.8, 2.4, segLen),
			Color3.fromRGB(68, 44, 114),
			Enum.Material.Concrete,
			true,
			0,
			false
		)
		-- Bioluminescent violet glow inside the rim (+X = inward)
		makePart(
			pond,
			"VioletRimGlow_" .. i,
			cf * CFrame.new(1.05, -0.42, 0),
			Vector3.new(1.95, 0.14, segLen * 1.12),
			PALETTE.InstinctRimGlow,
			Enum.Material.Neon,
			false,
			0.42,
			false
		)
	end

	-- Translucent purple water surface (SmoothPlastic reveals gradient, jellyfish & fish!)
	local water = makeEllipsoid(
		pond,
		"WaterSurface",
		CFrame.new(center + Vector3.new(0, -0.32, 0)),
		Vector3.new(INSTINCT_RX * 2.02, 0.20, INSTINCT_RZ * 2.02),
		PALETTE.InstinctWater,
		Enum.Material.SmoothPlastic,
		false,
		0.68,
		false
	)
	water.Reflectance = 0.08

	-- Floating 4-point sparkles & glowing stars on surface
	local starColors = { PALETTE.AmberCore, PALETTE.PinkGlow, PALETTE.CrystalCore }
	for s = 1, 28 do
		local ang = rng:NextNumber(0, math.pi * 2)
		local rad = math.sqrt(rng:NextNumber(0.06, 0.90))
		local sx = math.cos(ang) * (INSTINCT_RX - 2.0) * rad
		local sz = math.sin(ang) * (INSTINCT_RZ - 2.0) * rad
		local starPos = center + Vector3.new(sx, -0.24, sz)
		local col = starColors[(s % #starColors) + 1]
		makeEllipsoid(
			pond,
			"WaterStar_" .. s,
			CFrame.new(starPos),
			Vector3.new(0.40, 0.10, 0.40),
			col,
			Enum.Material.Neon,
			false,
			0.06,
			false
		)
		if s % 3 == 0 then
			makePart(
				pond,
				"StarCrossA_" .. s,
				CFrame.new(starPos),
				Vector3.new(0.95, 0.05, 0.13),
				col,
				Enum.Material.Neon,
				false,
				0.22,
				false
			)
			makePart(
				pond,
				"StarCrossB_" .. s,
				CFrame.new(starPos),
				Vector3.new(0.13, 0.05, 0.95),
				col,
				Enum.Material.Neon,
				false,
				0.22,
				false
			)
		end
	end

	-- Floating rising starlight particles
	local starPart = makePart(
		pond,
		"StarEmitter",
		CFrame.new(center + Vector3.new(0, 0.3, 0)),
		Vector3.new(20, 0.2, 16),
		PALETTE.PurpleGlow,
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	starPart.CanQuery = false
	local stars = Instance.new("ParticleEmitter")
	stars.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.AmberCore),
		ColorSequenceKeypoint.new(0.5, PALETTE.PinkGlow),
		ColorSequenceKeypoint.new(1, PALETTE.CyanGlow),
	})
	stars.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.24),
		NumberSequenceKeypoint.new(0.5, 0.34),
		NumberSequenceKeypoint.new(1, 0),
	})
	stars.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(1, 1),
	})
	stars.Lifetime = NumberRange.new(2.0, 3.6)
	stars.Rate = 10
	stars.Speed = NumberRange.new(0.5, 1.4)
	stars.LightEmission = 1
	stars.Parent = starPart

	-- 3 Detailed Bioluminescent Jellyfish (purple-lavender left, vibrant pink mid, glowing cyan right!)
	buildJellyfish(
		pond,
		"Jellyfish_1",
		center + Vector3.new(-7.4, 1.7, -2.0),
		0.95,
		PALETTE.PurpleGlow,
		PALETTE.PinkGlow,
		4.4,
		0.52,
		0.0
	)
	buildJellyfish(
		pond,
		"Jellyfish_2",
		center + Vector3.new(-0.8, 2.3, -1.0),
		1.12,
		PALETTE.PinkGlow,
		PALETTE.PortalWhite,
		5.2,
		0.46,
		2.1
	)
	buildJellyfish(
		pond,
		"Jellyfish_3",
		center + Vector3.new(6.6, 1.8, 0.2),
		0.98,
		PALETTE.CyanGlow,
		PALETTE.PortalWhite,
		4.2,
		0.60,
		4.2
	)

	-- 2 Bright Colorful Fish clearly visible from above (orange-gold + blue-yellow)
	local fishes = {
		{
			off = Vector3.new(0.8, -0.52, 4.2),
			yaw = math.rad(-25),
			body = PALETTE.FishOrange,
			fin = PALETTE.CoralYellow,
			r = 5.8,
			s = 0.80,
			ph = 0.7,
		},
		{
			off = Vector3.new(4.4, -0.56, 6.2),
			yaw = math.rad(145),
			body = PALETTE.FishBlue,
			fin = PALETTE.CoralYellow,
			r = 5.2,
			s = -0.72,
			ph = 3.4,
		},
	}
	for i, f in ipairs(fishes) do
		local fm = makeModel(pond, "PondFish_" .. i)
		fm:SetAttribute("OrbitRadius", f.r)
		fm:SetAttribute("OrbitSpeed", f.s)
		fm:SetAttribute("OrbitPhase", f.ph)
		fm:SetAttribute("DepthY", center.Y + f.off.Y)
		local fCf = CFrame.new(center + f.off) * CFrame.Angles(0, f.yaw, 0)
		local body = makeEllipsoid(
			fm,
			"Body",
			fCf,
			Vector3.new(1.30, 0.72, 2.85),
			f.body,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
		fm.PrimaryPart = body
		makeEllipsoid(
			fm,
			"SpineGlow",
			fCf * CFrame.new(0, 0.26, -0.1),
			Vector3.new(0.52, 0.18, 1.95),
			f.fin,
			Enum.Material.Neon,
			false,
			0.22,
			false
		)
		makeEllipsoid(
			fm,
			"FinL",
			fCf * CFrame.new(-0.95, 0, -0.2) * CFrame.Angles(0, math.rad(28), 0),
			Vector3.new(1.15, 0.14, 0.62),
			f.fin,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
		makeEllipsoid(
			fm,
			"FinR",
			fCf * CFrame.new(0.95, 0, -0.2) * CFrame.Angles(0, math.rad(-28), 0),
			Vector3.new(1.15, 0.14, 0.62),
			f.fin,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
		makeEllipsoid(
			fm,
			"TailL",
			fCf * CFrame.new(-0.42, 0, 1.65) * CFrame.Angles(0, math.rad(-32), 0),
			Vector3.new(0.36, 0.16, 1.20),
			f.fin,
			Enum.Material.Neon,
			false,
			0.18,
			false
		)
		makeEllipsoid(
			fm,
			"TailR",
			fCf * CFrame.new(0.42, 0, 1.65) * CFrame.Angles(0, math.rad(32), 0),
			Vector3.new(0.36, 0.16, 1.20),
			f.fin,
			Enum.Material.Neon,
			false,
			0.18,
			false
		)
	end

	-- 2 Planked Wooden Decks with Round Stools on the north shore
	local deck1Cf = CFrame.new(origin + Vector3.new(13.8, 0.62, -10.5))
		* CFrame.Angles(0, math.rad(-10), 0)
	buildPlankedDeck(pond, "InstinctDeck1Model", "InstinctDeck1", deck1Cf, 10.6, 6.4, 8, 2, rng)
	makeStool(pond, "InstinctStool1", deck1Cf * CFrame.new(0.6, 0.20, -0.3))

	local deck2Cf = CFrame.new(origin + Vector3.new(29.8, 0.62, -7.0))
		* CFrame.Angles(0, math.rad(-24), 0)
	buildPlankedDeck(pond, "InstinctDeck2Model", "InstinctDeck2", deck2Cf, 10.4, 6.4, 8, 2, rng)
	makeStool(pond, "InstinctStool2", deck2Cf * CFrame.new(0.2, 0.20, -0.2))

	-- 3 Sculpted Rune Stones with 3D Neon Cyan Glyphs (2 front-left + 1 back between decks)
	buildRuneStone(
		pond,
		"RuneStone_FrontL",
		origin + Vector3.new(10.6, 0, 17.6),
		origin + Vector3.new(8.0, 0, 50.0),
		Vector3.new(3.2, 4.4, 2.4),
		"R"
	)
	buildRuneStone(
		pond,
		"RuneStone_FrontR",
		origin + Vector3.new(15.6, 0, 19.2),
		origin + Vector3.new(13.0, 0, 52.0),
		Vector3.new(3.1, 3.8, 2.3),
		"TRI"
	)
	buildRuneStone(
		pond,
		"RuneStone_Back",
		origin + Vector3.new(21.8, 0, -11.4),
		origin + Vector3.new(19.0, 0, 30.0),
		Vector3.new(3.2, 4.5, 2.4),
		"DIA"
	)

	-- Giant Open Scalloped Clam Shell with Glowing Pearl on right shore!
	local clamCf = CFrame.new(origin + Vector3.new(37.2, 0.15, 6.6))
		* CFrame.Angles(0, math.rad(-34), 0)
	buildGiantClam(pond, clamCf)

	return pond
end

-- ============================================================================
-- 7. VEGETATION, PALMS, HAMMOCK, THATCHED HUT, CORAL TREE & COASTAL PROPS
-- ============================================================================

local function buildThatchedHut(parent: Instance, hutCf: CFrame, rng: Random): Model
	local hut = makeModel(parent, "ThatchedHut")

	-- 4 dark timber corner stilts (tucked cleanly under the thatched roof eaves — never poking through!)
	for sx = -1, 1, 2 do
		for sz = -1, 1, 2 do
			makeCylinderY(
				hut,
				"HutPost_" .. sx .. "_" .. sz,
				hutCf * CFrame.new(sx * 3.1, 3.0, sz * 2.5),
				0.64,
				6.0,
				PALETTE.WoodDark,
				Enum.Material.Wood,
				false,
				0,
				true
			)
		end
	end

	-- Elevated plank floor + side railing + little front-right wooden ladder (matching reference!)
	makePart(
		hut,
		"HutFloor",
		hutCf * CFrame.new(0, 2.15, 0),
		Vector3.new(6.8, 0.42, 5.6),
		PALETTE.WoodWarm1,
		Enum.Material.WoodPlanks,
		false,
		0,
		true
	)
	makePart(
		hut,
		"HutBackWall",
		hutCf * CFrame.new(0, 4.2, -2.5),
		Vector3.new(6.4, 3.8, 0.34),
		PALETTE.WoodWarm2,
		Enum.Material.WoodPlanks,
		false,
		0,
		true
	)
	makePart(
		hut,
		"HutSideRailL",
		hutCf * CFrame.new(-3.1, 3.2, 0),
		Vector3.new(0.28, 0.28, 5.2),
		PALETTE.WoodWarm3,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		hut,
		"HutSideRailR",
		hutCf * CFrame.new(3.1, 3.2, 0),
		Vector3.new(0.28, 0.28, 5.2),
		PALETTE.WoodWarm3,
		Enum.Material.Wood,
		false,
		0,
		false
	)

	-- Little 3-step wooden ladder on front-right
	local ladderCf = hutCf * CFrame.new(1.9, 0, 2.85) * CFrame.Angles(math.rad(-22), 0, 0)
	for sx = -1, 1, 2 do
		makeCylinderY(
			hut,
			"LadderRail_" .. sx,
			ladderCf * CFrame.new(sx * 0.58, 1.2, 0),
			0.20,
			2.5,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			false
		)
	end
	for rung = 1, 3 do
		makePart(
			hut,
			"LadderRung_" .. rung,
			ladderCf * CFrame.new(0, rung * 0.65, 0),
			Vector3.new(1.3, 0.16, 0.24),
			PALETTE.WoodWarm3,
			Enum.Material.Wood,
			false,
			0,
			false
		)
	end

	-- Layered golden thatched gabled roof with fringed straw eaves (warm golden straw Sand/Fabric, not green Grass!)
	makeWedge(
		hut,
		"RoofSlopeFront",
		hutCf * CFrame.new(0, 7.65, 1.85) * CFrame.Angles(0, math.rad(180), 0),
		Vector3.new(8.2, 3.3, 3.9),
		PALETTE.StrawMain,
		Enum.Material.Sand,
		false,
		true
	)
	makeWedge(
		hut,
		"RoofSlopeBack",
		hutCf * CFrame.new(0, 7.65, -1.85),
		Vector3.new(8.2, 3.3, 3.9),
		PALETTE.StrawMain,
		Enum.Material.Sand,
		false,
		true
	)
	-- Ridge cap log
	makeCylinderY(
		hut,
		"RoofRidge",
		hutCf * CFrame.new(0, 9.25, 0) * CFrame.Angles(0, 0, math.rad(90)),
		0.72,
		8.6,
		PALETTE.StrawDark,
		Enum.Material.Sand,
		false,
		0,
		false
	)
	-- Irregular straw fringe tufts along front & back eaves
	for side = -1, 1, 2 do
		for i = 0, 9 do
			local xOff = -3.8 + i * 0.84
			makeWedge(
				hut,
				"ThatchFringe_" .. side .. "_" .. i,
				hutCf
					* CFrame.new(xOff, 5.85 + rng:NextNumber(-0.15, 0.1), side * 3.72)
					* CFrame.Angles(
						side * math.rad(35),
						if side > 0 then math.rad(180) else 0,
						rng:NextNumber(-0.08, 0.08)
					),
				Vector3.new(0.88, rng:NextNumber(0.85, 1.25), 0.42),
				if i % 2 == 0 then PALETTE.StrawLight else PALETTE.StrawDark,
				Enum.Material.Sand,
				false,
				false
			)
		end
	end

	-- Small wooden barrel next to hut
	makeBarrel(hut, "HutBarrel", hutCf * CFrame.new(4.3, 0, 1.3), 0.84)
	return hut
end

-- Lush Organic Pink Coral Tree (gnarled trunk + fairy lights on trunk + 3-tier pink coral branches + petals!)
local function buildPinkCoralTree(parent: Instance, basePos: Vector3, rng: Random): Model
	local tree = makeModel(parent, "PinkCoralTree")

	-- Curved roots embracing the grass
	for r = 1, 5 do
		local a = (r / 5) * math.pi * 2 + 0.3
		makeSegment(
			tree,
			"Root_" .. r,
			basePos + Vector3.new(0, 1.2, 0),
			basePos + Vector3.new(math.cos(a) * 2.8, -0.05, math.sin(a) * 2.8),
			0.95,
			PALETTE.CoralTreeBarkDark,
			Enum.Material.Wood,
			true,
			false,
			true
		)
	end

	-- Slightly curved organic dark-wood trunk
	local tPts = {
		basePos,
		basePos + Vector3.new(-0.5, 2.4, 0.3),
		basePos + Vector3.new(0.2, 5.0, -0.1),
		basePos + Vector3.new(0.0, 6.8, 0.0),
	}
	local tThick = { 2.25, 1.85, 1.55 }
	for i = 1, #tPts - 1 do
		makeSegment(
			tree,
			"Trunk_" .. i,
			tPts[i],
			tPts[i + 1],
			tThick[i],
			PALETTE.CoralTreeBark,
			Enum.Material.Wood,
			true,
			false,
			true
		)
	end

	-- Warm golden fairy lights spiraling gently up the trunk (direct reference detail!)
	for i = 1, 10 do
		local frac = i / 10
		local ang = frac * math.pi * 3.4
		local rad = 1.15 - frac * 0.25
		local p = basePos + Vector3.new(math.cos(ang) * rad, 1.0 + frac * 5.2, math.sin(ang) * rad)
		makeEllipsoid(
			tree,
			"TrunkFairy_" .. i,
			CFrame.new(p),
			Vector3.new(0.30, 0.30, 0.30),
			PALETTE.AmberGlow,
			Enum.Material.Neon,
			false,
			0,
			false
		)
	end

	-- Recursive 3-tier organic branching Pink Coral Canopy (rich saturated coral-pink & full sculpted crown!)
	local canopyOrigin = tPts[#tPts]
	local coralShades = {
		PALETTE.CoralPink,
		Color3.fromRGB(240, 88, 134),
		PALETTE.CoralRose,
		Color3.fromRGB(246, 126, 152),
	}

	local function growBranch(
		startPos: Vector3,
		dir: Vector3,
		len: number,
		thick: number,
		depth: number,
		tag: string
	)
		local endPos = startPos + dir.Unit * len
		local col = coralShades[((depth + math.floor(math.abs(startPos.X * 3))) % #coralShades) + 1]
		makeSegment(
			tree,
			"CoralBr_" .. tag,
			startPos,
			endPos,
			thick,
			jitterColor(col, rng, 0.05),
			Enum.Material.SmoothPlastic,
			true,
			false,
			depth <= 1
		)
		makeEllipsoid(
			tree,
			"CoralNode_" .. tag,
			CFrame.new(endPos),
			Vector3.new(thick * 1.22, thick * 1.22, thick * 1.22),
			col:Lerp(PALETTE.CoralRose, 0.20),
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)

		if depth < 3 then
			local children = if depth == 1 then 3 else 2
			for c = 1, children do
				local spreadYaw = ((c - (children + 1) * 0.5) * 1.15) + rng:NextNumber(-0.32, 0.32)
				local lift = rng:NextNumber(0.45, 0.92)
				local baseHoriz = Vector3.new(dir.X, 0, dir.Z)
				if baseHoriz.Magnitude < 0.08 then
					baseHoriz = Vector3.new(math.cos(c * 2.1), 0, math.sin(c * 2.1))
				end
				local rotated = (
					CFrame.Angles(0, spreadYaw, 0):VectorToWorldSpace(baseHoriz.Unit) * 0.92
					+ Vector3.new(0, lift, 0)
				).Unit
				growBranch(
					endPos,
					rotated,
					len * rng:NextNumber(0.65, 0.80),
					thick * 0.68,
					depth + 1,
					tag .. "_" .. c
				)
			end
		end
	end

	-- 8 primary coral boughs radiating smoothly for a full, iconic branching coral tree silhouette!
	for b = 1, 8 do
		local a = (b / 8) * math.pi * 2 + 0.15
		local horiz = if b % 2 == 0 then 0.95 else 0.68
		local lift = if b % 2 == 0 then rng:NextNumber(0.55, 0.85) else rng:NextNumber(0.85, 1.20)
		local bDir = Vector3.new(math.cos(a) * horiz, lift, math.sin(a) * horiz).Unit
		growBranch(canopyOrigin, bDir, rng:NextNumber(3.3, 4.4), 1.18, 1, tostring(b))
	end

	-- Falling pink petals + golden fireflies around the coral tree
	local emitterAnchor = makePart(
		tree,
		"PetalEmitter",
		CFrame.new(basePos + Vector3.new(0, 12.2, 0)),
		Vector3.new(10, 1, 10),
		PALETTE.CoralPink,
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	emitterAnchor.CanQuery = false
	local petals = Instance.new("ParticleEmitter")
	petals.Name = "FallingPetals"
	petals.Color = ColorSequence.new(PALETTE.ShellPink, PALETTE.CoralPink)
	petals.Size = NumberSequence.new(0.28)
	petals.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	petals.Lifetime = NumberRange.new(2.8, 4.6)
	petals.Rate = 9
	petals.Speed = NumberRange.new(0.6, 1.5)
	petals.EmissionDirection = Enum.NormalId.Bottom
	petals.SpreadAngle = Vector2.new(36, 36)
	petals.Acceleration = Vector3.new(0.5, -0.6, 0.3)
	petals.RotSpeed = NumberRange.new(-90, 90)
	petals.Parent = emitterAnchor

	local fireflies = Instance.new("ParticleEmitter")
	fireflies.Name = "GoldenFireflies"
	fireflies.Color = ColorSequence.new(PALETTE.AmberCore, PALETTE.AmberGlow)
	fireflies.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.5, 0.28),
		NumberSequenceKeypoint.new(1, 0.04),
	})
	fireflies.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0),
		NumberSequenceKeypoint.new(0.75, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	fireflies.Lifetime = NumberRange.new(2.6, 4.4)
	fireflies.Speed = NumberRange.new(0.4, 1.1)
	fireflies.SpreadAngle = Vector2.new(180, 180)
	fireflies.Rate = 10
	fireflies.LightEmission = 1
	fireflies.Parent = emitterAnchor

	-- Fallen pink petals scattered around base
	for p = 1, 18 do
		local pa = rng:NextNumber(0, math.pi * 2)
		local pr = rng:NextNumber(1.6, 7.2)
		makeEllipsoid(
			tree,
			"GroundPetal_" .. p,
			CFrame.new(basePos + Vector3.new(math.cos(pa) * pr, 0.08, math.sin(pa) * pr))
				* CFrame.Angles(0, rng:NextNumber(0, 6), 0),
			Vector3.new(0.54, 0.07, 0.34),
			if p % 2 == 0 then PALETTE.ShellPink else PALETTE.CoralRose,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
	end

	return tree
end

local function buildVegetationAndProps(root: Model, origin: Vector3, rng: Random)
	local propFolder = makeFolder(root, "VegetationAndProps")

	-- 7 Curved Tropical Palm Trees matching reference framing
	local palmSpecs = {
		{ pos = Vector3.new(-39.5, 0, -2.0), yaw = math.rad(-108), s = 1.05, curve = 0.14 }, -- 1: far left leaning out
		{ pos = Vector3.new(-34.2, 0, -13.5), yaw = math.rad(-55), s = 1.18, curve = 0.11 }, -- 2: hammock left anchor
		{ pos = Vector3.new(-25.2, 0, -19.8), yaw = math.rad(-12), s = 1.02, curve = 0.10 }, -- 3: hammock right anchor
		{ pos = Vector3.new(-13.8, 0, -31.8), yaw = math.rad(165), s = 1.14, curve = 0.12 }, -- 4: back-left behind hut
		{ pos = Vector3.new(12.8, 0, -31.8), yaw = math.rad(-145), s = 1.24, curve = 0.12 }, -- 5: back-right tall palm
		{ pos = Vector3.new(20.6, 0, -26.8), yaw = math.rad(-115), s = 0.96, curve = 0.11 }, -- 6: behind crates
		{ pos = Vector3.new(40.2, 0, -3.5), yaw = math.rad(98), s = 1.12, curve = 0.14 }, -- 7: far right leaning out
	}
	local hammockAnchor1 = origin + Vector3.new(-34.0, 4.6, -13.2)
	local hammockAnchor2 = origin + Vector3.new(-25.4, 4.6, -19.4)

	for i, p in ipairs(palmSpecs) do
		local _, midPt =
			makePalm(propFolder, "Palm_" .. i, origin + p.pos, p.yaw, p.s, p.curve, rng)
		if i == 2 then
			hammockAnchor1 = midPt
		elseif i == 3 then
			hammockAnchor2 = midPt
		end
	end

	-- Woven Curved Hammock strung naturally between Palm #2 and Palm #3!
	local hammockModel = makeModel(propFolder, "BeachHammock")
	local hamSegs = 7
	local hamSag = 2.05
	local hamPrev: Vector3? = nil
	for s = 0, hamSegs do
		local t = s / hamSegs
		local pt = hammockAnchor1:Lerp(hammockAnchor2, t)
			- Vector3.new(0, 4 * hamSag * t * (1 - t), 0)
		if hamPrev then
			local mid = (hamPrev + pt) * 0.5
			local segLen = (pt - hamPrev).Magnitude + 0.12
			local cf = CFrame.lookAt(mid, pt)
			if s == 1 or s == hamSegs then
				-- Tie ropes at each end
				makeSegment(
					hammockModel,
					"HammockRope_" .. s,
					hamPrev,
					pt,
					0.18,
					PALETTE.RopeTan,
					Enum.Material.Fabric,
					true,
					false,
					false
				)
			else
				local width = 2.55 * math.sin(t * math.pi) + 0.65
				makePart(
					hammockModel,
					"HammockSlats_" .. s,
					cf,
					Vector3.new(width, 0.20, segLen),
					if s % 2 == 0 then PALETTE.HammockCloth else PALETTE.HammockStripe,
					Enum.Material.Fabric,
					false,
					0,
					false
				)
			end
		end
		hamPrev = pt
	end

	-- Thatched Hut behind Focus Pond (left of Portal)
	buildThatchedHut(
		propFolder,
		CFrame.new(origin + Vector3.new(-15.2, 0, -23.8)) * CFrame.Angles(0, math.rad(18), 0),
		rng
	)

	-- Wooden Buoy Rack with 5 Striped Colorful Hanging Buoys (right of Portal)
	local rackCf = CFrame.new(origin + Vector3.new(10.8, 0, -23.4))
		* CFrame.Angles(0, math.rad(-14), 0)
	local rack = makeModel(propFolder, "BuoyRack")
	for sx = -1, 1, 2 do
		makeCylinderY(
			rack,
			"Post_" .. sx,
			rackCf * CFrame.new(sx * 2.8, 3.1, 0),
			0.52,
			6.2,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			true
		)
		makeSegment(
			rack,
			"Brace_" .. sx,
			(rackCf * CFrame.new(sx * 2.8, 0.2, 1.3)).Position,
			(rackCf * CFrame.new(sx * 2.8, 2.2, 0)).Position,
			0.34,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			true,
			false,
			false
		)
	end
	makeCylinderY(
		rack,
		"Crossbar",
		rackCf * CFrame.new(0, 5.7, 0) * CFrame.Angles(0, 0, math.rad(90)),
		0.44,
		6.5,
		PALETTE.WoodWarm2,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	local buoyColors = {
		PALETTE.BuoyOrange,
		PALETTE.BuoyBlue,
		PALETTE.BuoyRed,
		PALETTE.BuoyYellow,
		PALETTE.BuoyBlue,
	}
	for i, col in ipairs(buoyColors) do
		local bx = -2.1 + (i - 1) * 1.05
		local dropY = 3.25 + (i % 2) * 0.65
		local topPt = (rackCf * CFrame.new(bx, 5.65, 0)).Position
		local buoyPt = (rackCf * CFrame.new(bx, dropY, 0)).Position
		makeSegment(
			rack,
			"BuoyCord_" .. i,
			topPt,
			buoyPt + Vector3.new(0, 0.85, 0),
			0.10,
			PALETTE.RopeTan,
			Enum.Material.Fabric,
			true,
			false,
			false
		)
		makeEllipsoid(
			rack,
			"BuoyBody_" .. i,
			CFrame.new(buoyPt),
			Vector3.new(0.95, 1.62, 0.95),
			col,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
		makeCylinderY(
			rack,
			"BuoyStripe_" .. i,
			CFrame.new(buoyPt),
			0.98,
			0.34,
			PALETTE.BuoyWhite,
			Enum.Material.SmoothPlastic,
			false,
			0,
			false
		)
	end

	-- Stack of 6 Framed Wooden Crates (between Buoy Rack and Coral Tree)
	local crateBase = origin + Vector3.new(17.0, 0, -21.2)
	local crateSpecs = {
		{ off = Vector3.new(0.0, 1.15, 0.0), sz = 2.30, yaw = 0.08 },
		{ off = Vector3.new(2.45, 1.15, 0.35), sz = 2.25, yaw = -0.14 },
		{ off = Vector3.new(1.15, 1.15, 2.35), sz = 2.20, yaw = 0.18 },
		{ off = Vector3.new(-1.1, 0.95, 2.15), sz = 1.90, yaw = -0.22 },
		{ off = Vector3.new(0.45, 3.35, 0.25), sz = 2.05, yaw = -0.12 },
		{ off = Vector3.new(2.35, 3.25, 1.10), sz = 1.95, yaw = 0.22 },
	}
	for i, cs in ipairs(crateSpecs) do
		makeCrate(
			propFolder,
			"Crate_" .. i,
			CFrame.new(crateBase + cs.off) * CFrame.Angles(0, cs.yaw, 0),
			cs.sz,
			rng
		)
	end

	-- Lush Pink Coral Tree behind Instinct Pond
	buildPinkCoralTree(propFolder, origin + Vector3.new(24.8, 0, -18.6), rng)

	-- Fairy-Light String & 2 Detailed Hanging Amber Lanterns (right of Coral Tree)
	local lp1 = origin + Vector3.new(28.6, 0, -13.6)
	local lp2 = origin + Vector3.new(36.8, 0, -9.2)
	for idx, lp in ipairs({ lp1, lp2 }) do
		makeCylinderY(
			propFolder,
			"LanternPost_" .. idx,
			CFrame.new(lp + Vector3.new(0, 4.1, 0)),
			0.72,
			8.2,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			true
		)
		makeEllipsoid(
			propFolder,
			"LanternPostCap_" .. idx,
			CFrame.new(lp + Vector3.new(0, 8.22, 0)),
			Vector3.new(0.84, 0.38, 0.84),
			PALETTE.WoodWarm3,
			Enum.Material.Wood,
			false,
			0,
			false
		)
		addRopeCoil(propFolder, "LanternPostRope_" .. idx, lp + Vector3.new(0, 7.1, 0), 0.72, 2)
		-- Curved arm & iron hanging lantern facing forward (+Z)
		local armEnd = lp + Vector3.new(0, 7.35, 1.75)
		makeSegment(
			propFolder,
			"LanternArm_" .. idx,
			lp + Vector3.new(0, 7.55, 0),
			armEnd,
			0.36,
			PALETTE.WoodWarm2,
			Enum.Material.Wood,
			true,
			false,
			false
		)
		makeSegment(
			propFolder,
			"LanternChain_" .. idx,
			armEnd,
			lp + Vector3.new(0, 6.25, 1.75),
			0.12,
			PALETTE.IronDark,
			Enum.Material.Metal,
			true,
			false,
			false
		)
		buildLanternUnit(propFolder, "AmberLantern_" .. idx, lp + Vector3.new(0, 5.45, 1.75), 0.92)
	end
	makeRope(
		propFolder,
		"FairyWire",
		lp1 + Vector3.new(0, 7.4, 0),
		lp2 + Vector3.new(0, 7.4, 0),
		1.55,
		10,
		0.12,
		PALETTE.WoodDark
	)
	for i = 1, 6 do
		local t = i / 7
		local pos = (lp1 + Vector3.new(0, 7.4, 0)):Lerp(lp2 + Vector3.new(0, 7.4, 0), t)
			- Vector3.new(0, 4 * 1.55 * t * (1 - t) + 0.36, 0)
		makeEllipsoid(
			propFolder,
			"FairyBulb_" .. i,
			CFrame.new(pos),
			Vector3.new(0.46, 0.52, 0.46),
			PALETTE.AmberGlow,
			Enum.Material.Neon,
			false,
			0,
			false
		)
	end

	-- Coiled ropes & small draped fishing net near the Focus Deck / beach
	for idx, coilPos in ipairs({ Vector3.new(-32.5, 0.14, 14.5), Vector3.new(-10.5, 0.14, -17.5) }) do
		for ring = 1, 3 do
			makeNeonRing(
				propFolder,
				"FloorRope_" .. idx .. "_" .. ring,
				CFrame.new(origin + coilPos + Vector3.new(0, (ring - 1) * 0.16, 0)),
				0.75 + ring * 0.26,
				0.22,
				0.18,
				14,
				PALETTE.RopeTan,
				0
			)
			-- Swap material from Neon to Fabric so coiled rope stays matte
			local rm = propFolder:FindFirstChild("FloorRope_" .. idx .. "_" .. ring)
			if rm then
				for _, d in ipairs(rm:GetChildren()) do
					if d:IsA("BasePart") then
						d.Material = Enum.Material.Fabric
					end
				end
			end
		end
	end

	-- Lush Grass Blade Tufts, Wildflowers, Beach Shells, Pebbles & Starfish (Island 1 richness!)
	local flowerCols =
		{ PALETTE.CoralYellow, PALETTE.ShellPink, PALETTE.ShellCream, PALETTE.CrystalIce }
	for i = 1, 130 do
		local ang = rng:NextNumber(0, math.pi * 2)
		local edgeR = islandRadiusAtAngle(ang)
		local grassMaxR = edgeR - getBeachWidth(ang) - 0.8
		local rad = math.sqrt(rng:NextNumber(0.08, 1.0)) * grassMaxR
		local x = math.cos(ang) * rad
		local z = math.sin(ang) * rad

		local nearFocus = isInsideEllipse(x, z, FOCUS_CENTER, FOCUS_RX, FOCUS_RZ, 1.5)
		local nearInstinct = isInsideEllipse(x, z, INSTINCT_CENTER, INSTINCT_RX, INSTINCT_RZ, 1.5)
		local nearBridge = math.abs(x) < 5.6 and z > -11.0 and z < 15.0
		local nearPortal = math.abs(x) < 8.5 and z < -23.0

		if
			not nearFocus
			and not nearInstinct
			and not nearBridge
			and not nearPortal
			and not isOnCentralSandPath(x, z)
		then
			local basePos = origin + Vector3.new(x, 0.02, z)
			local tuftCol = if rng:NextNumber() > 0.45 then PALETTE.GrassWarm else PALETTE.GrassDeep
			for b = 1, 3 do
				local yaw = rng:NextNumber(0, math.pi * 2)
				local tilt = math.rad(rng:NextNumber(14, 28))
				local h = rng:NextNumber(0.52, 1.12)
				makeWedge(
					propFolder,
					"GrassBlade_" .. i .. "_" .. b,
					CFrame.new(
						basePos
							+ Vector3.new(
								rng:NextNumber(-0.24, 0.24),
								h * 0.42,
								rng:NextNumber(-0.24, 0.24)
							)
					)
						* CFrame.Angles(0, yaw, 0)
						* CFrame.Angles(tilt, 0, 0),
					Vector3.new(0.16, h, 0.38),
					tuftCol,
					Enum.Material.SmoothPlastic,
					false,
					false
				)
			end
			if i % 6 == 0 then
				local fc = flowerCols[(i % #flowerCols) + 1]
				makeEllipsoid(
					propFolder,
					"Flower_" .. i,
					CFrame.new(basePos + Vector3.new(0.32, 0.24, -0.2)),
					Vector3.new(0.44, 0.18, 0.44),
					fc,
					Enum.Material.SmoothPlastic,
					false,
					0,
					false
				)
			end
		end
	end

	-- Scattered shells, starfish & pebbles along the golden sand beach
	for i = 1, 30 do
		local ang = rng:NextNumber(0.12, math.pi - 0.12)
		local edgeR = islandRadiusAtAngle(ang)
		local bw = getBeachWidth(ang)
		local rad = rng:NextNumber(edgeR - bw + 1.2, edgeR - 1.4)
		local x = math.cos(ang) * rad
		local z = math.sin(ang) * rad
		local kind = i % 3
		if kind == 0 then
			-- 5-armed coral starfish on the sand
			local starPos = origin + Vector3.new(x, -0.10, z)
			for arm = 0, 4 do
				local armAng = math.rad(arm * 72) + rng:NextNumber(-0.1, 0.1)
				makeEllipsoid(
					propFolder,
					"Starfish_" .. i .. "_" .. arm,
					CFrame.new(starPos) * CFrame.Angles(0, armAng, 0) * CFrame.new(0, 0, 0.28),
					Vector3.new(0.24, 0.14, 0.66),
					if i % 6 == 0 then PALETTE.CoralOrange else PALETTE.CoralPink,
					Enum.Material.SmoothPlastic,
					false,
					0,
					false
				)
			end
		elseif kind == 1 then
			makeShell(
				propFolder,
				"BeachShell_" .. i,
				CFrame.new(origin + Vector3.new(x, -0.06, z))
					* CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
				rng:NextNumber(0.62, 0.96),
				if i % 2 == 0 then PALETTE.ShellPink else PALETTE.ShellCream
			)
		else
			makeEllipsoid(
				propFolder,
				"SandPebble_" .. i,
				CFrame.new(origin + Vector3.new(x, -0.10, z))
					* CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
				Vector3.new(rng:NextNumber(0.75, 1.35), 0.28, rng:NextNumber(0.65, 1.15)),
				if i % 2 == 0 then PALETTE.StoneLight else PALETTE.StoneMid,
				Enum.Material.Concrete,
				false,
				0,
				false
			)
		end
	end
end

-- ============================================================================
-- 8. SERVER CONTRACT ANCHORS (EXACT NAMES, TAGS & ATTRIBUTES)
-- ============================================================================

local function buildContractParts(root: Model, origin: Vector3)
	-- IslandCenter (PrimaryPart)
	local center = makePart(
		root,
		"IslandCenter",
		CFrame.new(origin),
		Vector3.new(2, 2, 2),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	center.CanQuery = false
	center.CanTouch = false
	root.PrimaryPart = center

	-- ArrivalSpawn (on the solid stepping-stone sand path facing central bridge)
	local arrival = makePart(
		root,
		"ArrivalSpawn",
		CFrame.lookAt(origin + Vector3.new(0, 0.5, -18.5), origin + Vector3.new(0, 0.5, 0)),
		Vector3.new(4, 1, 4),
		Color3.new(0, 1, 0),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	arrival.CanQuery = false
	arrival.CanTouch = false
	CollectionService:AddTag(arrival, "ZoneSpawn")
	arrival:SetAttribute("Destination", "training_reef")

	-- ReturnPortal (inside the stone portal arch)
	local portal = makePart(
		root,
		"ReturnPortal",
		CFrame.new(origin + Vector3.new(0, 5.2, -29.8)),
		Vector3.new(6.2, 8.2, 2.6),
		Color3.new(0, 1, 1),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	portal.CanTouch = true
	portal.CanQuery = true
	portal.CanTouch = true
	portal.CanQuery = true
	CollectionService:AddTag(portal, "ZonePortal")
	portal:SetAttribute("PortalId", "training_reef_to_main")
	portal:SetAttribute("ZoneId", "lagoon")
	portal:SetAttribute("Destination", "main")

	-- FocusSpot (over Focus Deck)
	local focusSpot = makePart(
		root,
		"FocusSpot",
		CFrame.new(origin + Vector3.new(-22.5, 1.9, -10.8)),
		Vector3.new(5.5, 2, 5.5),
		Color3.new(0, 0.8, 1),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	focusSpot.CanQuery = false
	CollectionService:AddTag(focusSpot, "TrainingSpot")
	focusSpot:SetAttribute("TrainingIsland", 2)
	focusSpot:SetAttribute("TrainingStat", "Control")

	-- InstinctSpot (over Instinct Deck 1)
	local instinctSpot = makePart(
		root,
		"InstinctSpot",
		CFrame.new(origin + Vector3.new(13.8, 1.9, -10.5)),
		Vector3.new(5.5, 2, 5.5),
		Color3.new(0.8, 0.3, 1),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	instinctSpot.CanQuery = false
	CollectionService:AddTag(instinctSpot, "TrainingSpot")
	instinctSpot:SetAttribute("TrainingIsland", 2)
	instinctSpot:SetAttribute("TrainingStat", "Instinct")

	-- CameraShot (exact reference framing)
	local camShot = makePart(
		root,
		"CameraShot",
		CFrame.lookAt(origin + Vector3.new(0, 48, 100), origin),
		Vector3.new(1, 1, 1),
		Color3.new(1, 1, 0),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	camShot.CanQuery = false
	camShot.CanTouch = false
	camShot:SetAttribute("FieldOfView", 55)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function Builder.build(origin: Vector3?): Model
	local t0 = os.clock()
	local baseOrigin = origin or DEFAULT_ORIGIN
	local rng = Random.new(SEED)

	local folder = Workspace:FindFirstChild(FOLDER_NAME)
	if not folder or not folder:IsA("Folder") then
		folder = makeFolder(Workspace, FOLDER_NAME)
	end

	local existing = folder:FindFirstChild(ISLAND_NAME)
	if existing then
		existing:Destroy()
	end

	local root = makeModel(folder, ISLAND_NAME)
	root:SetAttribute("IslandTier", 2)
	root:SetAttribute("IslandName", "Ilha do Recife")

	buildIslandTopTerrain(root, baseOrigin)
	task.wait()
	buildRockAndReefWall(root, baseOrigin, rng)
	task.wait()
	buildPortal(root, baseOrigin, rng)
	buildCentralBridgeAndPaths(root, baseOrigin, rng)
	task.wait()
	buildFocusPond(root, baseOrigin, rng)
	task.wait()
	buildInstinctPond(root, baseOrigin, rng)
	task.wait()
	buildVegetationAndProps(root, baseOrigin, rng)
	buildContractParts(root, baseOrigin)

	local count = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			count += 1
		end
	end
	print(
		string.format(
			"[TrainingIsland2Builder] Built %s at %s with %d BaseParts in %.2fs.",
			ISLAND_NAME,
			tostring(baseOrigin),
			count,
			os.clock() - t0
		)
	)
	return root
end

function Builder.selfTest(_origin: Vector3?): { string }
	local failures: { string } = {}
	local folder = Workspace:FindFirstChild(FOLDER_NAME)
	local root = if folder then folder:FindFirstChild(ISLAND_NAME) else nil
	if not root or not root:IsA("Model") then
		table.insert(failures, "Model TrainingIsland_Reef not found in Workspace.TrainingIslands")
		return failures
	end

	local function checkChild(name: string, className: string): Instance?
		local c = root:FindFirstChild(name)
		if not c or not c:IsA(className) then
			table.insert(failures, string.format("Missing direct child %s (%s)", name, className))
			return nil
		end
		return c
	end

	local center = checkChild("IslandCenter", "BasePart")
	local arrival = checkChild("ArrivalSpawn", "BasePart")
	local portal = checkChild("ReturnPortal", "BasePart")
	local focusSpot = checkChild("FocusSpot", "BasePart")
	local instinctSpot = checkChild("InstinctSpot", "BasePart")
	local camShot = checkChild("CameraShot", "BasePart")
	checkChild("FocusPond", "Model")
	checkChild("InstinctPond", "Model")

	if root.PrimaryPart ~= center then
		table.insert(failures, "PrimaryPart is not IslandCenter")
	end

	if arrival and arrival:IsA("BasePart") then
		if not CollectionService:HasTag(arrival, "ZoneSpawn") then
			table.insert(failures, "ArrivalSpawn missing tag ZoneSpawn")
		end
		if arrival:GetAttribute("Destination") ~= "training_reef" then
			table.insert(failures, "ArrivalSpawn Destination ~= 'training_reef'")
		end
		-- Exclude ArrivalSpawn itself from the downward ground check so we truly verify solid collidable terrain below it
		local excludeList: { Instance } = { arrival }
		for _, ch in ipairs(root:GetChildren()) do
			if ch:IsA("BasePart") and ch.Transparency >= 0.99 and not ch.CanCollide then
				table.insert(excludeList, ch)
			end
		end
		local rcParams = RaycastParams.new()
		rcParams.FilterType = Enum.RaycastFilterType.Exclude
		rcParams.FilterDescendantsInstances = excludeList
		local hit = Workspace:Raycast(
			arrival.Position + Vector3.new(0, 2.0, 0),
			Vector3.new(0, -8.0, 0),
			rcParams
		)
		if not hit or not hit.Instance:IsDescendantOf(root) or not hit.Instance.CanCollide then
			table.insert(failures, "ArrivalSpawn is not over solid collidable ground")
		end
	end

	if portal and portal:IsA("BasePart") then
		if not CollectionService:HasTag(portal, "ZonePortal") then
			table.insert(failures, "ReturnPortal missing tag ZonePortal")
		end
		if
			portal:GetAttribute("PortalId") ~= "training_reef_to_main"
			or portal:GetAttribute("ZoneId") ~= "lagoon"
			or portal:GetAttribute("Destination") ~= "main"
		then
			table.insert(failures, "ReturnPortal attributes mismatch")
		end
		if not portal.CanTouch or not portal.CanQuery then
			table.insert(failures, "ReturnPortal requires CanTouch=true and CanQuery=true")
		end
	end

	local function checkSpot(spot: Instance?, expectedStat: string)
		if not spot or not spot:IsA("BasePart") then
			return
		end
		if not CollectionService:HasTag(spot, "TrainingSpot") then
			table.insert(failures, spot.Name .. " missing tag TrainingSpot")
		end
		local ti = spot:GetAttribute("TrainingIsland")
		if type(ti) ~= "number" or ti ~= 2 then
			table.insert(failures, spot.Name .. " TrainingIsland must be number 2")
		end
		if spot:GetAttribute("TrainingStat") ~= expectedStat then
			table.insert(failures, spot.Name .. " TrainingStat ~= " .. expectedStat)
		end
	end
	checkSpot(focusSpot, "Control")
	checkSpot(instinctSpot, "Instinct")

	if camShot and camShot:GetAttribute("FieldOfView") ~= 55 then
		table.insert(failures, "CameraShot FieldOfView ~= 55")
	end

	-- Verify walkable collision on bridge & decks
	local bridge = root:FindFirstChild("BridgeCollider", true)
	local fDeck = root:FindFirstChild("FocusDeck", true)
	local iDeck1 = root:FindFirstChild("InstinctDeck1", true)
	local iDeck2 = root:FindFirstChild("InstinctDeck2", true)
	for _, p in ipairs({ bridge, fDeck, iDeck1, iDeck2 }) do
		if not p or not p:IsA("BasePart") or not p.CanCollide then
			table.insert(
				failures,
				"Walkable structure missing or CanCollide=false: " .. tostring(p)
			)
		end
	end

	-- Verify no forbidden instances and no collidable decorations
	local decorFolders = { "RockWallCorals", "VegetationAndProps", "RockUnderside" }
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") or d:IsA("Seat") then
			table.insert(failures, "Forbidden instance found: " .. d:GetFullName())
		end
	end
	for _, fname in ipairs(decorFolders) do
		local f = root:FindFirstChild(fname)
		if f then
			for _, d in ipairs(f:GetDescendants()) do
				if d:IsA("BasePart") and d.CanCollide then
					table.insert(failures, "Decoration has CanCollide=true: " .. d:GetFullName())
					break
				end
			end
		end
	end

	-- Path clearance check from ArrivalSpawn to Portal, FocusSpot, InstinctSpot
	if arrival and arrival:IsA("BasePart") then
		local targets = { portal, focusSpot, instinctSpot }
		local ovParams = OverlapParams.new()
		ovParams.FilterType = Enum.RaycastFilterType.Include
		ovParams.FilterDescendantsInstances = { root }
		for _, tgt in ipairs(targets) do
			if tgt and tgt:IsA("BasePart") then
				local mid = arrival.Position:Lerp(tgt.Position, 0.5) + Vector3.new(0, 3.0, 0)
				local blocked = Workspace:GetPartBoundsInBox(
					CFrame.new(mid),
					Vector3.new(2.5, 3.0, 2.5),
					ovParams
				)
				for _, b in ipairs(blocked) do
					if b.CanCollide then
						table.insert(
							failures,
							string.format(
								"Path from ArrivalSpawn to %s blocked by %s",
								tgt.Name,
								b.Name
							)
						)
						break
					end
				end
			end
		end
	end

	return failures
end

function Builder.applyReferenceLighting()
	if not savedLighting then
		savedLighting = {
			ClockTime = Lighting.ClockTime,
			GeographicLatitude = Lighting.GeographicLatitude,
			Brightness = Lighting.Brightness,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
			EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		}
	end
	Lighting.ClockTime = 11.2
	Lighting.GeographicLatitude = 22
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(122, 146, 162)
	Lighting.OutdoorAmbient = Color3.fromRGB(138, 164, 182)
	Lighting.EnvironmentDiffuseScale = 0.85
	Lighting.EnvironmentSpecularScale = 0.55
end

function Builder.restoreLighting()
	if not savedLighting then
		return
	end
	Lighting.ClockTime = savedLighting.ClockTime
	Lighting.GeographicLatitude = savedLighting.GeographicLatitude
	Lighting.Brightness = savedLighting.Brightness
	Lighting.Ambient = savedLighting.Ambient
	Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
	Lighting.EnvironmentDiffuseScale = savedLighting.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = savedLighting.EnvironmentSpecularScale
	savedLighting = nil
end

return Builder
