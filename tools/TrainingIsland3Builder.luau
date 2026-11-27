--!strict
-- TrainingIsland3Builder.luau
-- Builds "TrainingIsland_Abyss" (Ilha de Treino 3: Abismo Estelar) for Legendary Catch.
-- Idempotent: destroys and recreates Workspace.TrainingIslands.TrainingIsland_Abyss.
-- Usage (Studio Edit Command Bar, test origin):
--   local m = game.ServerStorage.DevTools.TrainingIsland3Builder:Clone()
--   local B = require(m)
--   B.build(Vector3.new(-520, 12, 1500))
--   print(table.concat(B.selfTest(Vector3.new(-520, 12, 1500)), "\n"))

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Builder = {}

-- ============================================================================
-- CONSTANTS & PALETTE (rich midnight-indigo, violet, cyan & gold — works day & night)
-- ============================================================================

local DEFAULT_ORIGIN = Vector3.new(-520, 12, 420)
local ISLAND_NAME = "TrainingIsland_Abyss"
local FOLDER_NAME = "TrainingIslands"
local SEED = 20261125

-- Pond ellipses (local X, Z)
local FOCUS_CENTER = Vector2.new(-20.5, 0.5)
local FOCUS_RX = 16.0
local FOCUS_RZ = 13.0

local INSTINCT_CENTER = Vector2.new(19.5, 7.0)
local INSTINCT_RX = 16.2
local INSTINCT_RZ = 12.8

-- Key landmark positions (local)
local PORTAL_POS = Vector3.new(16.5, 0, -24.5)
local PORTAL_YAW_DEG = -18
local OBS_POS = Vector3.new(-4.8, 0, -23.5)
local BRIDGE_POS = Vector3.new(-1.5, 0, 5.2)
local BRIDGE_YAW_DEG = 17
local FOCUS_DECK_POS = Vector3.new(-32.2, 0.55, 13.8)
local FOCUS_DECK_YAW_DEG = -28
local INSTINCT_DECK_POS = Vector3.new(27.8, 0.55, -3.2)
local INSTINCT_DECK_YAW_DEG = -15
local TREE_POS = Vector3.new(35.8, 0, -13.2)

-- Waterfall rim angles (radians, atan2(z, x))
local WATERFALL_LEFT_ANG = 2.02
local WATERFALL_RIGHT_ANG = 0.90

local PALETTE = {
	-- Midnight grass (rich moonlit indigo-blue — vivid & readable both night and day)
	GrassMain = Color3.fromRGB(50, 66, 114),
	GrassMid = Color3.fromRGB(64, 84, 138),
	GrassDeep = Color3.fromRGB(38, 50, 92),
	GrassRimLip = Color3.fromRGB(44, 58, 102),
	GrassTuftA = Color3.fromRGB(72, 96, 156),
	GrassTuftB = Color3.fromRGB(54, 74, 128),

	-- Tall layered abyssal cliff rock (moonlit indigo / violet / deep shadow crevices)
	RockUpper = Color3.fromRGB(68, 76, 126),
	RockMid = Color3.fromRGB(82, 74, 136),
	RockViolet = Color3.fromRGB(94, 76, 146),
	RockDeep = Color3.fromRGB(48, 48, 92),
	RockShadow = Color3.fromRGB(26, 26, 56),
	RootDark = Color3.fromRGB(42, 34, 68),

	-- Carved moonlit blue-grey stonework (portal, observatory, bridge curbs, monoliths, path)
	StoneDark = Color3.fromRGB(78, 92, 132),
	StoneMid = Color3.fromRGB(98, 114, 156),
	StoneLight = Color3.fromRGB(118, 136, 178),
	StoneJoint = Color3.fromRGB(30, 36, 62),
	StoneSlabA = Color3.fromRGB(84, 98, 138),
	StoneSlabB = Color3.fromRGB(66, 78, 116),

	-- Aged dark plum-brown wood & warm rope (reads clearly under moonlight)
	WoodDark = Color3.fromRGB(88, 70, 86),
	WoodPlank1 = Color3.fromRGB(128, 104, 114),
	WoodPlank2 = Color3.fromRGB(110, 88, 100),
	WoodPlank3 = Color3.fromRGB(146, 120, 128),
	WoodCarved = Color3.fromRGB(196, 176, 188),
	Rope = Color3.fromRGB(190, 162, 128),
	RopeKnot = Color3.fromRGB(154, 128, 98),
	IronDark = Color3.fromRGB(54, 60, 80),

	-- Gold & brass (telescope, lantern trim)
	GoldBright = Color3.fromRGB(252, 212, 104),
	GoldMid = Color3.fromRGB(218, 172, 70),
	GoldDark = Color3.fromRGB(164, 124, 48),

	-- Focus mirror pond (near-black starry sky reflection)
	FocusBed = Color3.fromRGB(10, 18, 46),
	FocusGlow = Color3.fromRGB(24, 58, 132),
	FocusWater = Color3.fromRGB(18, 36, 86),
	FocusRingCore = Color3.fromRGB(196, 250, 255),
	FocusRingCyan = Color3.fromRGB(74, 228, 255),
	FocusRingBlue = Color3.fromRGB(48, 166, 255),

	-- Instinct galaxy pond (deep abyss purple + spiral nebula)
	GalaxyBed = Color3.fromRGB(18, 10, 46),
	GalaxyWater = Color3.fromRGB(38, 18, 84),
	GalaxyOuter = Color3.fromRGB(86, 36, 164),
	GalaxyMid = Color3.fromRGB(142, 66, 224),
	GalaxyPink = Color3.fromRGB(224, 108, 244),
	GalaxyCore = Color3.fromRGB(248, 236, 255),

	-- Cyan crystals & runes
	CrystalCyan = Color3.fromRGB(76, 230, 255),
	CrystalBlue = Color3.fromRGB(52, 168, 255),
	CrystalDeep = Color3.fromRGB(42, 122, 238),
	CrystalCore = Color3.fromRGB(204, 252, 255),
	RuneCyan = Color3.fromRGB(92, 238, 255),

	-- Crystal tree (rich saturated violet -> vibrant magenta -> rose pink; never blows out to white!)
	TreeTrunk = Color3.fromRGB(110, 72, 156),
	TreeBarkDark = Color3.fromRGB(78, 48, 118),
	CrystalViolet = Color3.fromRGB(122, 48, 214),
	CrystalMagenta = Color3.fromRGB(192, 58, 214),
	CrystalPink = Color3.fromRGB(232, 92, 208),
	CrystalPinkCore = Color3.fromRGB(252, 166, 236),

	-- Warm lights, stars & moon
	AmberGlow = Color3.fromRGB(255, 198, 82),
	AmberCore = Color3.fromRGB(255, 238, 158),
	FireflyGold = Color3.fromRGB(255, 230, 124),
	StarWhite = Color3.fromRGB(236, 248, 255),
	MoonCream = Color3.fromRGB(228, 240, 255),
	MoonCrater = Color3.fromRGB(188, 208, 238),

	-- Cosmic fish
	FishGoldBody = Color3.fromRGB(255, 192, 68),
	FishGoldGlow = Color3.fromRGB(255, 238, 150),
	FishRainbowHead = Color3.fromRGB(255, 196, 92),
	FishRainbowMid = Color3.fromRGB(255, 112, 204),
	FishRainbowTail = Color3.fromRGB(96, 240, 255),
	FishNebulaBody = Color3.fromRGB(32, 26, 82),
	FishNebulaTrim = Color3.fromRGB(128, 196, 255),
	FishNebulaPink = Color3.fromRGB(234, 112, 244),
	FishAzureBody = Color3.fromRGB(118, 136, 252),
	FishAzureGlow = Color3.fromRGB(182, 214, 255),

	-- Waterfalls of light
	FallBlue = Color3.fromRGB(58, 192, 255),
	FallCyan = Color3.fromRGB(102, 242, 255),
	FallWhite = Color3.fromRGB(220, 252, 255),
}

local SAVED_STATE_NAME = "AbyssRefPreview_SavedState"

-- ============================================================================
-- SHAPE & GEOMETRY HELPERS
-- ============================================================================

local function jitterColor(base: Color3, rng: Random, amount: number): Color3
	local h, s, v = base:ToHSV()
	h = (h + rng:NextNumber(-amount * 0.22, amount * 0.22)) % 1
	s = math.clamp(s + rng:NextNumber(-amount, amount), 0, 1)
	v = math.clamp(v + rng:NextNumber(-amount, amount), 0, 1)
	return Color3.fromHSV(h, s, v)
end

local function angleDiff(a: number, b: number): number
	local d = (a - b + math.pi) % (math.pi * 2) - math.pi
	return math.abs(d)
end

-- Organic wide oval cliff silhouette matching the reference image
local function getIslandRadiiAt(theta: number): (number, number)
	local wave = 1.6 * math.sin(theta * 3 + 0.45)
		+ 1.1 * math.cos(theta * 5 - 0.65)
		+ 0.65 * math.sin(theta * 7 + 1.1)
	local frontBulge = math.max(0, math.sin(theta)) * 1.6
	local rx = 48.2 + wave + frontBulge * 0.6
	local rz = 39.8 + wave * 0.85 + frontBulge
	return rx, rz
end

local function getIslandRimPoint(origin: Vector3, theta: number, scale: number?): Vector3
	local s = scale or 1.0
	local rx, rz = getIslandRadiiAt(theta)
	return origin + Vector3.new(math.cos(theta) * rx * s, 0, math.sin(theta) * rz * s)
end

local function isInsideIsland(x: number, z: number, inset: number): boolean
	local theta = math.atan2(z, x)
	local rx, rz = getIslandRadiiAt(theta)
	local ax = math.max(1, rx - inset)
	local az = math.max(1, rz - inset)
	return (x * x) / (ax * ax) + (z * z) / (az * az) <= 1.0
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
	p.CFrame = cf
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = canCollide
	p.CanTouch = false
	p.CanQuery = canCollide
	p.Transparency = transparency or 0
	p.CastShadow = if castShadow ~= nil then castShadow else canCollide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
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
	transparency: number?,
	castShadow: boolean?
): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.CFrame = cf
	w.Size = size
	w.Color = color
	w.Material = material
	w.CanCollide = canCollide
	w.CanTouch = false
	w.CanQuery = canCollide
	w.Transparency = transparency or 0
	w.CastShadow = if castShadow ~= nil then castShadow else canCollide
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
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
	p.CFrame = cf * CFrame.Angles(0, 0, math.rad(90))
	p.Size = Vector3.new(height, diameter, diameter)
	p.Color = color
	p.Material = material
	p.CanCollide = canCollide
	p.CanTouch = false
	p.CanQuery = canCollide
	p.Transparency = transparency or 0
	p.CastShadow = if castShadow ~= nil then castShadow else canCollide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
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
	p.CFrame = cf
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = canCollide
	p.CanTouch = false
	p.CanQuery = canCollide
	p.Transparency = transparency or 0
	p.CastShadow = if castShadow ~= nil then castShadow else false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
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
	canCollide: boolean,
	transparency: number?,
	castShadow: boolean?,
	isCylinder: boolean?
): Part?
	local dist = (p2 - p1).Magnitude
	if dist < 0.03 then
		return nil
	end
	local mid = (p1 + p2) * 0.5
	local cf = CFrame.lookAt(mid, p2)
	if isCylinder then
		local p = makePart(
			parent,
			name,
			cf * CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(dist, thickness, thickness),
			color,
			material,
			canCollide,
			transparency or 0,
			castShadow
		)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	return makePart(
		parent,
		name,
		cf,
		Vector3.new(thickness, thickness, dist),
		color,
		material,
		canCollide,
		transparency or 0,
		castShadow
	)
end

local function makeNeonRing(
	parent: Instance,
	name: string,
	centerCf: CFrame,
	radius: number,
	tubeWidth: number,
	tubeHeight: number,
	segments: number,
	color: Color3,
	transparency: number?
): Model
	local ring = makeModel(parent, name)
	local step = (math.pi * 2) / segments
	local chord = 2 * radius * math.sin(step * 0.5) + tubeWidth * 0.45
	for i = 1, segments do
		local a = (i - 0.5) * step
		local localPos = Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
		local segCf = centerCf * CFrame.new(localPos) * CFrame.Angles(0, -a, 0)
		local seg = makePart(
			ring,
			"Seg_" .. tostring(i),
			segCf,
			Vector3.new(tubeWidth, tubeHeight, chord),
			color,
			Enum.Material.Neon,
			false,
			transparency or 0,
			false
		)
		seg.CanQuery = false
		seg.CanTouch = false
	end
	return ring
end

-- Dual-layer glowing ring (crisp bright core + wider translucent outer aura)
local function makeGlowingRing(
	parent: Instance,
	name: string,
	centerCf: CFrame,
	radius: number,
	coreThick: number,
	segments: number,
	coreColor: Color3,
	haloColor: Color3,
	coreTrans: number?,
	haloTrans: number?
)
	makeNeonRing(
		parent,
		name .. "_Core",
		centerCf,
		radius,
		coreThick,
		coreThick * 0.55,
		segments,
		coreColor,
		coreTrans or 0.08
	)
	makeNeonRing(
		parent,
		name .. "_Halo",
		centerCf * CFrame.new(0, -0.02, 0),
		radius,
		coreThick * 2.4,
		coreThick * 0.35,
		segments,
		haloColor,
		haloTrans or 0.64
	)
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
	local col = color or PALETTE.Rope
	local prev = p1
	for i = 1, segments do
		local t = i / segments
		local pos = p1:Lerp(p2, t) - Vector3.new(0, math.sin(t * math.pi) * sag, 0)
		makeSegment(
			rope,
			"Rope_" .. tostring(i),
			prev,
			pos,
			thickness,
			col,
			Enum.Material.Fabric,
			false,
			0,
			false,
			true
		)
		prev = pos
	end
	return rope
end

local function addRopeCoil(
	parent: Instance,
	name: string,
	centerPos: Vector3,
	postDiameter: number,
	coils: number
)
	local coilDiam = postDiameter + 0.2
	for c = 1, coils do
		local yOff = (c - (coils + 1) * 0.5) * 0.22
		makeCylinderY(
			parent,
			name .. "_" .. tostring(c),
			CFrame.new(centerPos + Vector3.new(0, yOff, 0))
				* CFrame.Angles(math.rad(if c % 2 == 0 then 3 else -3), 0, 0),
			coilDiam,
			0.18,
			if c % 2 == 0 then PALETTE.Rope else PALETTE.RopeKnot,
			Enum.Material.Fabric,
			false,
			0,
			false
		)
	end
end

-- ============================================================================
-- 3D NEON RUNE GLYPHS (crisp geometric strokes — always legible at any distance)
-- ============================================================================

local RUNE_PATTERNS: { { { Vector2 } } } = {
	-- 1: Algiz (trident rune)
	{
		{ Vector2.new(0, -1), Vector2.new(0, 1) },
		{ Vector2.new(0, 0.15), Vector2.new(-0.85, 0.9) },
		{ Vector2.new(0, 0.15), Vector2.new(0.85, 0.9) },
	},
	-- 2: Raido (R rune)
	{
		{ Vector2.new(-0.6, -1), Vector2.new(-0.6, 1) },
		{ Vector2.new(-0.6, 1), Vector2.new(0.7, 0.35) },
		{ Vector2.new(0.7, 0.35), Vector2.new(-0.55, -0.05) },
		{ Vector2.new(-0.45, -0.05), Vector2.new(0.78, -1) },
	},
	-- 3: Othala (diamond with legs)
	{
		{ Vector2.new(0, 1), Vector2.new(-0.78, 0.12) },
		{ Vector2.new(0, 1), Vector2.new(0.78, 0.12) },
		{ Vector2.new(-0.78, 0.12), Vector2.new(0.68, -1) },
		{ Vector2.new(0.78, 0.12), Vector2.new(-0.68, -1) },
	},
	-- 4: Ansuz (F-like astral rune)
	{
		{ Vector2.new(-0.55, -1), Vector2.new(-0.55, 1) },
		{ Vector2.new(-0.55, 0.92), Vector2.new(0.75, 0.35) },
		{ Vector2.new(-0.55, 0.18), Vector2.new(0.65, -0.35) },
	},
	-- 5: Dagaz / hourglass rune
	{
		{ Vector2.new(-0.7, -0.9), Vector2.new(-0.7, 0.9) },
		{ Vector2.new(0.7, -0.9), Vector2.new(0.7, 0.9) },
		{ Vector2.new(-0.7, 0.9), Vector2.new(0.7, -0.9) },
		{ Vector2.new(-0.7, -0.9), Vector2.new(0.7, 0.9) },
	},
	-- 6: Sowilo / lightning Z rune
	{
		{ Vector2.new(-0.65, 0.95), Vector2.new(0.65, 0.25) },
		{ Vector2.new(0.65, 0.25), Vector2.new(-0.65, -0.25) },
		{ Vector2.new(-0.65, -0.25), Vector2.new(0.65, -0.95) },
	},
}

-- Draws a 3D glowing rune on the local XY plane of `planeCf`
local function addRuneGlyph(
	parent: Instance,
	name: string,
	planeCf: CFrame,
	patternIndex: number,
	halfW: number,
	halfH: number,
	thickness: number,
	color: Color3
)
	local strokes = RUNE_PATTERNS[((patternIndex - 1) % #RUNE_PATTERNS) + 1]
	for idx, seg in ipairs(strokes) do
		local pA = (planeCf * CFrame.new(seg[1].X * halfW, seg[1].Y * halfH, 0)).Position
		local pB = (planeCf * CFrame.new(seg[2].X * halfW, seg[2].Y * halfH, 0)).Position
		local part = makeSegment(
			parent,
			name .. "_" .. tostring(idx),
			pA,
			pB,
			thickness,
			color,
			Enum.Material.Neon,
			false,
			0.08,
			false,
			true
		)
		if part then
			part.CanQuery = false
		end
	end
end

-- ============================================================================
-- FACETED HEXAGONAL CRYSTAL (glossy translucent shell + inner neon gem core)
-- ============================================================================

local function buildHexShard(
	parent: Instance,
	name: string,
	baseCf: CFrame,
	radius: number,
	height: number,
	outerColor: Color3,
	coreColor: Color3,
	addLight: boolean?
): Model
	local shard = makeModel(parent, name)
	local shaftH = height * 0.68
	local tipH = height * 0.32
	local flatW = radius * 1.155
	local depthSpan = radius * 2.0

	-- Luminous translucent hexagonal outer shell (even gem glow both day & night, crisp facets!)
	for k = 0, 2 do
		local rot = CFrame.Angles(0, math.rad(k * 60), 0)
		local p = makePart(
			shard,
			"Shaft_" .. tostring(k + 1),
			baseCf * rot * CFrame.new(0, shaftH * 0.5, 0),
			Vector3.new(flatW, shaftH, depthSpan),
			outerColor,
			Enum.Material.SmoothPlastic,
			false,
			0.38,
			false
		)
		p.Reflectance = 0.14
		if k == 0 then
			shard.PrimaryPart = p
		end
	end

	-- Pointed 6-faceted pyramidal glossy crystal tip (shows sharp gem facets without blooming white!)
	local tipCol = outerColor:Lerp(coreColor, 0.25)
	for s = 0, 5 do
		local ang = math.rad(s * 60)
		local tip = makeWedge(
			shard,
			"Tip_" .. tostring(s + 1),
			baseCf * CFrame.Angles(0, ang, 0) * CFrame.new(0, shaftH + tipH * 0.5, -radius * 0.44),
			Vector3.new(flatW * 0.96, tipH, radius * 0.92),
			tipCol,
			Enum.Material.SmoothPlastic,
			false,
			0.24,
			false
		)
		tip.Reflectance = 0.20
		tip.CastShadow = false
	end

	-- Saturated luminous inner neon gem body (rich glowing hue inside faceted crystal shell)
	local coreR = radius * 0.60
	local coreFlat = coreR * 1.155
	local coreDepth = coreR * 2.0
	local coreCol = outerColor:Lerp(coreColor, 0.22)
	for k = 0, 2 do
		local rot = CFrame.Angles(0, math.rad(k * 60 + 30), 0)
		makePart(
			shard,
			"Core_" .. tostring(k + 1),
			baseCf * rot * CFrame.new(0, shaftH * 0.52, 0),
			Vector3.new(coreFlat, shaftH * 0.92, coreDepth),
			coreCol,
			Enum.Material.Neon,
			false,
			0.34,
			false
		)
	end
	for s = 0, 2 do
		local ang = math.rad(s * 120)
		makeWedge(
			shard,
			"CoreTip_" .. tostring(s + 1),
			baseCf * CFrame.Angles(0, ang, 0) * CFrame.new(0, shaftH + tipH * 0.44, -coreR * 0.40),
			Vector3.new(coreFlat, tipH * 0.86, coreR * 0.88),
			outerColor:Lerp(coreColor, 0.42),
			Enum.Material.Neon,
			false,
			0.28,
			false
		)
	end

	if addLight then
		local anchor = makePart(
			shard,
			"CrystalLightAnchor",
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
		pl.Range = math.clamp(height * 2.2, 10, 20)
		pl.Parent = anchor
	end

	return shard
end

local function buildCrystalCluster(
	parent: Instance,
	name: string,
	baseCf: CFrame,
	radius: number,
	height: number,
	outerColor: Color3,
	coreColor: Color3,
	subCount: number,
	addLight: boolean,
	rng: Random
): Model
	local m = makeModel(parent, name)
	buildHexShard(m, "Main", baseCf, radius, height, outerColor, coreColor, addLight)

	for i = 1, subCount do
		local a = (i / math.max(1, subCount)) * math.pi * 2 + rng:NextNumber(-0.35, 0.35)
		local tilt = rng:NextNumber(0.24, 0.55)
		local offsetR = radius * rng:NextNumber(0.55, 1.05)
		local subCf = baseCf
			* CFrame.new(math.cos(a) * offsetR, -height * 0.04, math.sin(a) * offsetR)
			* CFrame.Angles(0, a, tilt)
		local subCol = if i % 2 == 0 then outerColor:Lerp(PALETTE.CrystalBlue, 0.45) else outerColor
		buildHexShard(
			m,
			"Sub_" .. tostring(i),
			subCf,
			radius * rng:NextNumber(0.48, 0.68),
			height * rng:NextNumber(0.42, 0.66),
			subCol,
			coreColor,
			false
		)
	end
	return m
end

-- ============================================================================
-- 1. TOP TERRAIN (CARVED PONDS, 3-TONE MIDNIGHT GRASS, OVERHANGING RIM)
-- ============================================================================

local function buildTopTerrain(root: Model, origin: Vector3, rng: Random)
	local folder = makeFolder(root, "TerrainBase")

	-- Build top walkable ground in clean X-strips, carving out both pond basins cleanly
	-- Recessed slightly inside the rim so smooth curved rim pieces create an organic edge
	local step = 1.4
	local halfX = 51.0
	local halfZ = 44.0
	local rows = math.floor((halfZ * 2) / step)
	local cols = math.floor((halfX * 2) / step)

	for iz = 0, rows do
		local z = -halfZ + iz * step
		local inRun = false
		local runStartX = 0.0

		local function flushRun(endX: number)
			if not inRun then
				return
			end
			local w = endX - runStartX
			if w >= 0.2 then
				local midX = (runStartX + endX) * 0.5
				local p = makePart(
					folder,
					"GroundStrip",
					CFrame.new(origin + Vector3.new(midX, -1.1, z)),
					Vector3.new(w + 0.06, 2.2, step + 0.06),
					PALETTE.GrassMain,
					Enum.Material.SmoothPlastic,
					true,
					0,
					true
				)
				p.Name = "GroundStrip_" .. tostring(iz)
			end
			inRun = false
		end

		for ix = 0, cols do
			local x = -halfX + ix * step
			local inside = isInsideIsland(x, z, 2.5)
				and not isInsideEllipse(x, z, FOCUS_CENTER, FOCUS_RX, FOCUS_RZ, -0.4)
				and not isInsideEllipse(x, z, INSTINCT_CENTER, INSTINCT_RX, INSTINCT_RZ, -0.4)

			if inside and not inRun then
				inRun = true
				runStartX = x - step * 0.5
			elseif not inside and inRun then
				flushRun(x - step * 0.5)
			end
		end
		flushRun(halfX + step * 0.5)
	end

	-- Smooth organic perimeter rim + grass lip that slightly "drips" over the cliff edge
	local rimFolder = makeFolder(folder, "GrassRimOverhang")
	local segs = 68
	for i = 1, segs do
		local a1 = (i / segs) * math.pi * 2
		local a2 = ((i + 1) / segs) * math.pi * 2
		local aMid = (a1 + a2) * 0.5

		-- Open subtle spillway notches at the 2 waterfall outlets
		local inFallNotch = angleDiff(aMid, WATERFALL_LEFT_ANG) < 0.065
			or angleDiff(aMid, WATERFALL_RIGHT_ANG) < 0.065

		local p1 = getIslandRimPoint(origin, a1, 1.0)
		local p2 = getIslandRimPoint(origin, a2, 1.0)
		local mid = (p1 + p2) * 0.5
		local segLen = (p2 - p1).Magnitude + 1.15
		local cf = CFrame.lookAt(mid, p2)
		-- Note: CFrame.lookAt(mid, p2) has +X pointing INWARD toward origin (CCW angle order)

		if not inFallNotch then
			-- Walkable outer grass band seamlessly meeting GroundStrip (0.02 lower to prevent z-fighting)
			makePart(
				rimFolder,
				"GrassRim_" .. tostring(i),
				cf * CFrame.new(2.6, -0.97, 0),
				Vector3.new(5.6, 1.9, segLen),
				PALETTE.GrassMain,
				Enum.Material.SmoothPlastic,
				true,
				0,
				true
			)

			-- Rounded midnight-grass overhang lip draping cleanly over the cliff crest
			local lipH = rng:NextNumber(1.3, 2.2)
			local lip = makeEllipsoid(
				rimFolder,
				"GrassLip_" .. tostring(i),
				cf * CFrame.new(0.45, -0.72 - lipH * 0.16, 0) * CFrame.Angles(0, 0, math.rad(14)),
				Vector3.new(2.8, lipH, segLen * 1.14),
				if i % 3 == 0 then PALETTE.GrassDeep else PALETTE.GrassRimLip,
				Enum.Material.SmoothPlastic,
				false,
				0,
				false
			)
			lip.CanQuery = false
		else
			-- Lower recessed spillway stone bed so the waterfall exits cleanly from the rim
			makePart(
				rimFolder,
				"SpillwayBed_" .. tostring(i),
				cf * CFrame.new(2.8, -1.65, 0),
				Vector3.new(5.8, 1.6, segLen),
				PALETTE.RockDeep,
				Enum.Material.Concrete,
				true,
				0,
				true
			)
		end
	end

	-- Organic 3-tone nocturnal grass patches across the top (breaks flatness, rich color even in daylight)
	local patchFolder = makeFolder(folder, "GroundVariation")
	local grassTones = { PALETTE.GrassMid, PALETTE.GrassDeep, PALETTE.GrassMain }
	for i = 1, 56 do
		local a = rng:NextNumber(0, math.pi * 2)
		local rx, rz = getIslandRadiiAt(a)
		local frac = math.sqrt(rng:NextNumber(0.08, 0.90))
		local x = math.cos(a) * rx * frac
		local z = math.sin(a) * rz * frac
		if
			not isInsideEllipse(x, z, FOCUS_CENTER, FOCUS_RX, FOCUS_RZ, 1.6)
			and not isInsideEllipse(x, z, INSTINCT_CENTER, INSTINCT_RX, INSTINCT_RZ, 1.6)
		then
			local szX = rng:NextNumber(4.0, 9.5)
			local szZ = rng:NextNumber(3.5, 8.5)
			local patch = makeEllipsoid(
				patchFolder,
				"GrassPatch_" .. tostring(i),
				CFrame.new(origin + Vector3.new(x, -0.02, z))
					* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
				Vector3.new(szX, 0.14, szZ),
				grassTones[(i % #grassTones) + 1],
				Enum.Material.SmoothPlastic,
				false,
				0,
				false
			)
			patch.CanQuery = false
		end
	end
end

-- ============================================================================
-- 2. TALL LAYERED CLIFF WALLS, EMBEDDED CRYSTALS, ROOTS, WATERFALLS & FLOATERS
-- ============================================================================

local function buildCliffAndWaterfalls(root: Model, origin: Vector3, rng: Random)
	local cliffFolder = makeFolder(root, "CliffMass")
	local cliffDecor = makeFolder(root, "CliffDecor")

	-- Dark recessed inner rock core (strictly below pond beds Y=-2.1 so it never pokes into ponds)
	local coreLayers = {
		{ y = -6.6, h = 6.2, s = 0.92 },
		{ y = -11.6, h = 7.4, s = 0.83 },
		{ y = -17.8, h = 7.8, s = 0.66 },
		{ y = -23.6, h = 6.8, s = 0.44 },
	}
	for idx, cl in ipairs(coreLayers) do
		makeEllipsoid(
			cliffFolder,
			"CliffInnerCore_" .. tostring(idx),
			CFrame.new(origin + Vector3.new(0, cl.y, 0)),
			Vector3.new(94 * cl.s, cl.h * 1.35, 78 * cl.s),
			PALETTE.RockShadow,
			Enum.Material.Concrete,
			false,
			0,
			true
		)
	end

	-- 5 tall dramatic cliff strata: vertical upper cliffs (same radius as rim — NO saucer!),
	-- stepping and tapering organically into jagged spires toward the bottom keel
	local strata = {
		{
			count = 32,
			rScale = 1.00,
			yMin = -5.4,
			yMax = -4.6,
			h = 6.2,
			d = 8.8,
			wScale = 1.08,
			inTilt = 4,
			cols = { PALETTE.RockUpper, PALETTE.RockMid },
		},
		{
			count = 28,
			rScale = 0.96,
			yMin = -10.4,
			yMax = -9.0,
			h = 7.6,
			d = 9.4,
			wScale = 1.12,
			inTilt = 10,
			cols = { PALETTE.RockMid, PALETTE.RockViolet },
		},
		{
			count = 24,
			rScale = 0.84,
			yMin = -16.2,
			yMax = -14.6,
			h = 7.8,
			d = 9.6,
			wScale = 1.16,
			inTilt = 19,
			cols = { PALETTE.RockViolet, PALETTE.RockDeep },
		},
		{
			count = 18,
			rScale = 0.65,
			yMin = -21.6,
			yMax = -20.0,
			h = 7.4,
			d = 9.2,
			wScale = 1.22,
			inTilt = 29,
			cols = { PALETTE.RockDeep, PALETTE.RockShadow },
		},
		{
			count = 12,
			rScale = 0.42,
			yMin = -26.2,
			yMax = -24.6,
			h = 6.4,
			d = 8.2,
			wScale = 1.28,
			inTilt = 40,
			cols = { PALETTE.RockShadow, PALETTE.RockDeep },
		},
	}

	for sIdx, st in ipairs(strata) do
		local arcStep = (math.pi * 2) / st.count
		for i = 1, st.count do
			local ang = (i / st.count) * math.pi * 2 + sIdx * 0.21 + rng:NextNumber(-0.04, 0.04)

			-- Leave clean sculpted notches for the 2 waterfalls in upper cliff layers
			if
				sIdx <= 2
				and (
					angleDiff(ang, WATERFALL_LEFT_ANG) < 0.085
					or angleDiff(ang, WATERFALL_RIGHT_ANG) < 0.085
				)
			then
				continue
			end

			local rx, rz = getIslandRadiiAt(ang)
			local rimVec = Vector3.new(math.cos(ang) * rx, 0, math.sin(ang) * rz)
			local distR = rimVec.Magnitude * st.rScale + rng:NextNumber(-0.7, 0.7)
			local dirOut = rimVec.Unit
			local y = rng:NextNumber(st.yMin, st.yMax)
			local pos = origin + dirOut * (distR - st.d * 0.42) + Vector3.new(0, y, 0)

			local chordW = distR * arcStep * st.wScale * rng:NextNumber(0.86, 1.08)
			local blkH = st.h * rng:NextNumber(0.88, 1.18)
			local blkD = st.d * rng:NextNumber(0.88, 1.14)
			local col = jitterColor(st.cols[((i + sIdx) % #st.cols) + 1], rng, 0.05)
			local mat = if (i + sIdx) % 3 == 0 then Enum.Material.Basalt else Enum.Material.Concrete

			local baseCf = CFrame.lookAt(pos, pos + dirOut)
				* CFrame.Angles(
					math.rad(-st.inTilt + rng:NextNumber(-5, 5)),
					math.rad(rng:NextNumber(-6, 6)),
					math.rad(rng:NextNumber(-6, 6))
				)

			-- Vertical chiseled crag pilaster (angular layered cliff faces matching the reference!)
			makePart(
				cliffFolder,
				"CliffSlab_" .. tostring(sIdx) .. "_" .. tostring(i),
				baseCf * CFrame.new(0, 0, blkD * 0.08),
				Vector3.new(chordW * 0.94, blkH * 1.04, blkD * 0.80),
				col,
				mat,
				false,
				0,
				true
			)

			-- Stepping angular rock rib protruding forward (strictly below Y=-0.5 so nothing pokes through grass!)
			makePart(
				cliffFolder,
				"CliffRib_" .. tostring(sIdx) .. "_" .. tostring(i),
				baseCf
					* CFrame.new(rng:NextNumber(-0.6, 0.6), -blkH * 0.04, -blkD * 0.20)
					* CFrame.Angles(
						math.rad(rng:NextNumber(-3, 3)),
						math.rad(rng:NextNumber(-14, 14)),
						math.rad(rng:NextNumber(-4, 4))
					),
				Vector3.new(chordW * 0.68, blkH * 0.90, blkD * 0.54),
				jitterColor(col, rng, 0.06),
				if i % 2 == 0 then Enum.Material.Slate else Enum.Material.Concrete,
				false,
				0,
				false
			)

			-- Angular cracked bevel wedge underneath
			makeWedge(
				cliffFolder,
				"CliffCrag_" .. tostring(sIdx) .. "_" .. tostring(i),
				baseCf
					* CFrame.new(rng:NextNumber(-0.5, 0.5), -blkH * 0.24, -blkD * 0.34)
					* CFrame.Angles(math.rad(180), 0, math.rad(rng:NextNumber(-8, 8))),
				Vector3.new(chordW * 0.76, blkH * 0.74, blkD * 0.48),
				PALETTE.RockDeep,
				mat,
				false,
				0,
				false
			)
		end
	end

	-- Jagged tapered bottom keel spires
	local keelSpikes = {
		{
			off = Vector3.new(0, -29.2, 0),
			sz = Vector3.new(16, 7.5, 14),
			rot = Vector3.new(5, 18, -4),
		},
		{
			off = Vector3.new(-7, -27.5, 4),
			sz = Vector3.new(10, 6.5, 9),
			rot = Vector3.new(-8, 42, 9),
		},
		{
			off = Vector3.new(8, -27.8, 3),
			sz = Vector3.new(11, 6.8, 10),
			rot = Vector3.new(7, -34, -8),
		},
		{
			off = Vector3.new(1, -28.0, -7),
			sz = Vector3.new(10, 6.2, 10),
			rot = Vector3.new(-6, 70, 5),
		},
	}
	for idx, ks in ipairs(keelSpikes) do
		makeWedge(
			cliffFolder,
			"KeelSpire_" .. tostring(idx),
			CFrame.new(origin + ks.off)
				* CFrame.Angles(math.rad(180 + ks.rot.X), math.rad(ks.rot.Y), math.rad(ks.rot.Z)),
			ks.sz,
			PALETTE.RockShadow,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
	end

	-- Rich embedded cyan crystal clusters along cliff walls & front rim (just like reference!)
	local cliffCrystalSpecs = {
		-- Front-left wall & beside left waterfall
		{
			ang = 2.66,
			y = -6.2,
			rF = 1.00,
			rad = 1.45,
			h = 5.6,
			subs = 3,
			upTilt = 38,
			light = true,
		},
		{
			ang = 2.34,
			y = -11.5,
			rF = 0.94,
			rad = 1.35,
			h = 5.2,
			subs = 3,
			upTilt = 48,
			light = false,
		},
		{
			ang = 1.88,
			y = -0.2,
			rF = 0.96,
			rad = 1.55,
			h = 6.2,
			subs = 4,
			upTilt = 8,
			light = true,
		},
		{
			ang = 1.80,
			y = -10.5,
			rF = 0.94,
			rad = 1.25,
			h = 4.6,
			subs = 2,
			upTilt = 56,
			light = false,
		},
		-- Front-center cliff wall
		{
			ang = 1.54,
			y = -15.5,
			rF = 0.85,
			rad = 1.35,
			h = 5.0,
			subs = 3,
			upTilt = 62,
			light = false,
		},
		{
			ang = 1.32,
			y = -19.5,
			rF = 0.72,
			rad = 1.25,
			h = 4.5,
			subs = 3,
			upTilt = 65,
			light = false,
		},
		-- Front-right rim & beside right waterfall (prominent cluster in art!)
		{
			ang = 1.02,
			y = -0.3,
			rF = 0.96,
			rad = 1.65,
			h = 6.4,
			subs = 4,
			upTilt = 10,
			light = true,
		},
		{
			ang = 1.06,
			y = -14.8,
			rF = 0.86,
			rad = 1.40,
			h = 5.2,
			subs = 3,
			upTilt = 58,
			light = false,
		},
		{
			ang = 0.84,
			y = -18.5,
			rF = 0.76,
			rad = 1.55,
			h = 5.6,
			subs = 4,
			upTilt = 52,
			light = false,
		},
		{
			ang = 0.48,
			y = -8.5,
			rF = 0.97,
			rad = 1.45,
			h = 5.4,
			subs = 3,
			upTilt = 44,
			light = true,
		},
		{
			ang = 0.28,
			y = -13.5,
			rF = 0.88,
			rad = 1.25,
			h = 4.6,
			subs = 2,
			upTilt = 56,
			light = false,
		},
		-- Back & side walls for full 360 silhouette
		{
			ang = 3.35,
			y = -7.8,
			rF = 0.98,
			rad = 1.35,
			h = 5.2,
			subs = 3,
			upTilt = 46,
			light = false,
		},
		{
			ang = 4.25,
			y = -8.5,
			rF = 0.96,
			rad = 1.30,
			h = 4.8,
			subs = 2,
			upTilt = 48,
			light = false,
		},
		{
			ang = 5.55,
			y = -7.2,
			rF = 0.98,
			rad = 1.40,
			h = 5.2,
			subs = 3,
			upTilt = 45,
			light = false,
		},
	}
	for idx, cs in ipairs(cliffCrystalSpecs) do
		local rimPt = getIslandRimPoint(origin, cs.ang, cs.rF)
		local pos = Vector3.new(rimPt.X, origin.Y + cs.y, rimPt.Z)
		local outDir = Vector3.new(rimPt.X - origin.X, 0, rimPt.Z - origin.Z).Unit
		local cf = CFrame.lookAt(pos - outDir * 0.6, pos + outDir)
			* CFrame.Angles(math.rad(-cs.upTilt), 0, 0)
		buildCrystalCluster(
			cliffDecor,
			"CliffCrystal_" .. tostring(idx),
			cf,
			cs.rad,
			cs.h,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			cs.subs,
			cs.light,
			rng
		)
	end

	-- Hanging dark twisted roots along the lower cliff crevices
	local rootAngles = { 2.52, 2.22, 1.66, 1.42, 1.16, 0.56, 0.34 }
	for rIdx, ang in ipairs(rootAngles) do
		local rimPt = getIslandRimPoint(origin, ang, 0.94)
		local cur = Vector3.new(rimPt.X, origin.Y - rng:NextNumber(8.5, 13.0), rimPt.Z)
		for s = 1, 5 do
			local nxt = cur
				+ Vector3.new(
					rng:NextNumber(-0.8, 0.8),
					-rng:NextNumber(1.6, 2.3),
					rng:NextNumber(-0.8, 0.8)
				)
			makeSegment(
				cliffDecor,
				"CliffRoot_" .. tostring(rIdx) .. "_" .. tostring(s),
				cur,
				nxt,
				0.48 * (1 - s * 0.14),
				PALETTE.RootDark,
				Enum.Material.Wood,
				false,
				0,
				false,
				true
			)
			cur = nxt
		end
	end

	-- 2 Luminous Cyan Waterfalls spilling gracefully over sculpted rock lips at the rim
	-- (Layered translucent flowing ribbons + luminous foam + falling starlight mist — ZERO rigid tubes or sea discs!)
	local waterfallSpecs = {
		{ name = "LightWaterfall_Left", ang = WATERFALL_LEFT_ANG, width = 5.6, drop = 31.0 },
		{ name = "LightWaterfall_Right", ang = WATERFALL_RIGHT_ANG, width = 5.0, drop = 31.0 },
	}
	for _, wf in ipairs(waterfallSpecs) do
		local wfModel = makeModel(cliffDecor, wf.name)
		local rimPt = getIslandRimPoint(origin, wf.ang, 0.98)
		local radialDir = Vector3.new(rimPt.X - origin.X, 0, rimPt.Z - origin.Z).Unit
		-- Blend facing slightly toward +Z so both waterfalls present their wide shimmering face to CameraShot
		local dir = (radialDir * 0.65 + Vector3.new(0, 0, 1) * 0.35).Unit
		local spoutPos = Vector3.new(rimPt.X, origin.Y - 0.35, rimPt.Z)
		local cf = CFrame.lookAt(spoutPos, spoutPos + dir)

		-- Sculpted dark cliff rocks framing the waterfall spillway lip
		for side = -1, 1, 2 do
			makeEllipsoid(
				wfModel,
				"NotchBoulder_" .. tostring(side),
				cf
					* CFrame.new(side * (wf.width * 0.62), -1.1, 0.4)
					* CFrame.Angles(0, 0, math.rad(side * -14)),
				Vector3.new(3.2, 4.4, 3.8),
				PALETTE.RockDeep,
				Enum.Material.Concrete,
				false,
				0,
				false
			)
		end

		-- Luminous foaming crest curling over the rim edge
		local crest = makeEllipsoid(
			wfModel,
			"SpoutCrest",
			cf * CFrame.new(0, -0.25, -0.95),
			Vector3.new(wf.width * 1.08, 1.55, 2.9),
			PALETTE.FallCyan,
			Enum.Material.Neon,
			false,
			0.28,
			false
		)
		makeEllipsoid(
			wfModel,
			"SpoutCoreWhite",
			cf * CFrame.new(0, -0.15, -1.15),
			Vector3.new(wf.width * 0.72, 0.95, 2.2),
			PALETTE.FallWhite,
			Enum.Material.Neon,
			false,
			0.18,
			false
		)

		-- 7 layered cascading ribbons (wide translucent water veil + bright glowing inner streams)
		local ribbons = {
			{
				x = 0.0,
				z = -1.65,
				w = 1.00,
				col = PALETTE.FallBlue,
				mat = Enum.Material.SmoothPlastic,
				tr = 0.38,
				ph = 0.0,
			},
			{
				x = -0.32,
				z = -1.85,
				w = 0.36,
				col = PALETTE.FallCyan,
				mat = Enum.Material.Neon,
				tr = 0.34,
				ph = 0.8,
			},
			{
				x = 0.30,
				z = -1.84,
				w = 0.34,
				col = PALETTE.FallCyan,
				mat = Enum.Material.Neon,
				tr = 0.36,
				ph = 2.0,
			},
			{
				x = -0.10,
				z = -1.98,
				w = 0.22,
				col = PALETTE.FallWhite,
				mat = Enum.Material.Neon,
				tr = 0.24,
				ph = 3.2,
			},
			{
				x = 0.14,
				z = -1.96,
				w = 0.18,
				col = PALETTE.FallWhite,
				mat = Enum.Material.Neon,
				tr = 0.28,
				ph = 4.4,
			},
			{
				x = -0.44,
				z = -1.78,
				w = 0.16,
				col = PALETTE.FallCyan,
				mat = Enum.Material.Neon,
				tr = 0.56,
				ph = 1.5,
			},
			{
				x = 0.43,
				z = -1.78,
				w = 0.16,
				col = PALETTE.FallCyan,
				mat = Enum.Material.Neon,
				tr = 0.56,
				ph = 5.1,
			},
		}
		local segs = 9
		for rIdx, rib in ipairs(ribbons) do
			-- Stagger each ribbon's bottom drop so the waterfall dissolves naturally into glowing wisps
			local ribDrop = wf.drop * (0.86 + ((rIdx * 37) % 10) * 0.028)
			for s = 1, segs do
				local tMid = (s - 0.5) / segs
				local segH = (ribDrop / segs) + 0.48
				-- Parabolic arch leaving the cliff lip, then flowing straight down with gentle undulation
				local archOut = math.sin(math.min(tMid * 2.8, 1.0) * math.pi * 0.5) * 1.55
				local waveZ = math.sin(tMid * math.pi * 3.4 + rib.ph) * 0.16
				local waveX = math.cos(tMid * math.pi * 2.6 + rib.ph) * 0.10
				-- Wide at top, tapering smoothly to narrow wisps at the bottom
				local widthTaper = math.max(0.18, 1.05 - (tMid ^ 1.35) * 0.68)
				local tilt = if s == 1 then math.rad(28) elseif s == 2 then math.rad(10) else 0
				local fadeTr = math.clamp(rib.tr + (tMid ^ 1.9) * 0.68, 0, 0.96)

				local p = makePart(
					wfModel,
					"FallRibbon_" .. tostring(rIdx) .. "_" .. tostring(s),
					cf
						* CFrame.new(
							wf.width * rib.x + waveX,
							-tMid * ribDrop - 0.2,
							rib.z - archOut + waveZ
						)
						* CFrame.Angles(tilt, 0, 0),
					Vector3.new(wf.width * rib.w * widthTaper, segH, 0.32),
					rib.col,
					rib.mat,
					false,
					fadeTr,
					false
				)
				if rib.mat == Enum.Material.SmoothPlastic then
					p.Reflectance = 0.18
				end
			end
		end

		-- Invisible lower mist emitter anchor (pure particles, zero floating sphere artifact!)
		local mistAnchor = makePart(
			wfModel,
			"FallMistAnchor",
			cf * CFrame.new(0, -wf.drop * 0.72, -3.1),
			Vector3.new(wf.width * 1.1, 3.0, 1.5),
			PALETTE.FallCyan,
			Enum.Material.SmoothPlastic,
			false,
			1,
			false
		)
		mistAnchor.CanQuery = false

		local spray = Instance.new("ParticleEmitter")
		spray.Name = "LightWaterfallSpray"
		spray.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, PALETTE.FallWhite),
			ColorSequenceKeypoint.new(0.5, PALETTE.FallCyan),
			ColorSequenceKeypoint.new(1, PALETTE.FallBlue),
		})
		spray.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.42),
			NumberSequenceKeypoint.new(0.6, 0.75),
			NumberSequenceKeypoint.new(1, 0),
		})
		spray.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
		spray.Lifetime = NumberRange.new(1.2, 2.0)
		spray.Speed = NumberRange.new(10, 15)
		spray.EmissionDirection = Enum.NormalId.Bottom
		spray.SpreadAngle = Vector2.new(14, 14)
		spray.Rate = 11
		spray.LightEmission = 1
		spray.Parent = crest

		local lowerMist = Instance.new("ParticleEmitter")
		lowerMist.Name = "LightFallMist"
		lowerMist.Color = ColorSequence.new(PALETTE.FallCyan, PALETTE.FallWhite)
		lowerMist.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.65),
			NumberSequenceKeypoint.new(1, 2.2),
		})
		lowerMist.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 1),
		})
		lowerMist.Lifetime = NumberRange.new(1.0, 1.7)
		lowerMist.Speed = NumberRange.new(1.0, 2.4)
		lowerMist.SpreadAngle = Vector2.new(60, 60)
		lowerMist.Rate = 7
		lowerMist.LightEmission = 1
		lowerMist.Parent = mistAnchor
	end

	-- 6 Sculptural Multi-Facet Floating Rock Fragments with Crystals (matches reference positions!)
	local function buildFloatingRockChunk(
		name: string,
		pos: Vector3,
		scale: number,
		bottomCrystals: boolean
	)
		local m = makeModel(cliffDecor, name)
		local cf = CFrame.new(pos)
			* CFrame.Angles(
				rng:NextNumber(-0.16, 0.16),
				rng:NextNumber(0, math.pi * 2),
				rng:NextNumber(-0.16, 0.16)
			)

		-- Irregular multi-block rock body (top grass cap + upper crag + tapered jagged point)
		makeEllipsoid(
			m,
			"RockBodyMain",
			cf * CFrame.new(0, 0.2 * scale, 0),
			Vector3.new(4.8 * scale, 3.2 * scale, 4.2 * scale),
			jitterColor(PALETTE.RockUpper, rng, 0.05),
			Enum.Material.Concrete,
			false,
			0,
			false
		)
		makePart(
			m,
			"RockFacetA",
			cf * CFrame.new(1.1 * scale, -0.3 * scale, 0.5 * scale) * CFrame.Angles(0.2, 0.5, -0.25),
			Vector3.new(3.2 * scale, 2.8 * scale, 2.9 * scale),
			PALETTE.RockMid,
			Enum.Material.Basalt,
			false,
			0,
			false
		)
		makePart(
			m,
			"RockFacetB",
			cf
				* CFrame.new(-1.0 * scale, -0.5 * scale, -0.4 * scale)
				* CFrame.Angles(-0.22, -0.6, 0.28),
			Vector3.new(2.9 * scale, 2.6 * scale, 2.8 * scale),
			PALETTE.RockViolet,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
		makeWedge(
			m,
			"RockSpireBottom",
			cf
				* CFrame.new(0, -2.8 * scale, 0)
				* CFrame.Angles(math.rad(180), rng:NextNumber(0, 3), 0),
			Vector3.new(3.8 * scale, 4.4 * scale, 3.4 * scale),
			PALETTE.RockDeep,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
		-- Tiny companion pebble orbiting close by
		makeEllipsoid(
			m,
			"CompanionPebble",
			cf * CFrame.new(3.4 * scale, -1.2 * scale, 1.4 * scale),
			Vector3.new(1.2 * scale, 1.1 * scale, 1.0 * scale),
			PALETTE.RockDeep,
			Enum.Material.Concrete,
			false,
			0,
			false
		)

		-- Glowing cyan crystal cluster on top
		buildCrystalCluster(
			m,
			"TopCrystals",
			CFrame.new(pos + Vector3.new(0, 1.3 * scale, 0))
				* CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			0.62 * scale,
			3.4 * scale,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			2,
			false,
			rng
		)
		-- Optional hanging crystal protruding from side/bottom
		if bottomCrystals then
			buildHexShard(
				m,
				"SideCrystal",
				cf
					* CFrame.new(1.5 * scale, -1.2 * scale, 1.1 * scale)
					* CFrame.Angles(math.rad(135), 0.4, 0.3),
				0.42 * scale,
				2.3 * scale,
				PALETTE.CrystalBlue,
				PALETTE.CrystalCore,
				false
			)
		end
	end

	local floaterSpecs = {
		{ pos = Vector3.new(-52.5, -13.5, 18.0), s = 1.25, bc = true }, -- front-left prominent
		{ pos = Vector3.new(-46.0, -21.5, 25.0), s = 0.72, bc = false }, -- lower-left companion
		{ pos = Vector3.new(52.5, -17.5, 16.5), s = 1.12, bc = true }, -- front-right lower
		{ pos = Vector3.new(-11.5, 13.5, -34.5), s = 0.92, bc = true }, -- sky behind observatory left
		{ pos = Vector3.new(-1.5, 9.8, -33.0), s = 0.62, bc = false }, -- sky behind observatory right
		{ pos = Vector3.new(-45.5, -9.5, -16.0), s = 0.85, bc = false }, -- back-left balance
	}
	for i, fl in ipairs(floaterSpecs) do
		buildFloatingRockChunk("FloatingRock_" .. tostring(i), origin + fl.pos, fl.s, fl.bc)
	end
end

-- ============================================================================
-- SHARED ARTISAN PROPS (WOODEN DECK, STOOL, BARREL, LANTERN, SIGNPOST)
-- ============================================================================

local function buildWoodenDeck(
	parent: Instance,
	name: string,
	deckCf: CFrame,
	width: number,
	depth: number,
	colliderName: string,
	rng: Random
): Model
	local deck = makeModel(parent, name)
	local plankCount = 7
	local stepZ = depth / plankCount
	local woodTones = { PALETTE.WoodPlank1, PALETTE.WoodPlank2, PALETTE.WoodPlank3 }

	-- Solid smooth invisible walk collider matching the exact deck footprint
	makePart(
		deck,
		colliderName,
		deckCf,
		Vector3.new(width, 0.42, depth),
		PALETTE.WoodPlank1,
		Enum.Material.WoodPlanks,
		true,
		1,
		false
	)

	-- Longitudinal dark support beams
	for side = -1, 1, 2 do
		makePart(
			deck,
			"Beam_" .. tostring(side),
			deckCf * CFrame.new(side * width * 0.36, -0.34, 0),
			Vector3.new(0.58, 0.48, depth * 0.95),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			true
		)
	end

	-- 7 slightly varied artisan planks with natural gaps
	for i = 1, plankCount do
		local zOff = -depth * 0.5 + (i - 0.5) * stepZ
		local wVar = width + rng:NextNumber(-0.22, 0.28)
		local yaw = math.rad(rng:NextNumber(-1.0, 1.0))
		local plank = makePart(
			deck,
			"Plank_" .. tostring(i),
			deckCf * CFrame.new(rng:NextNumber(-0.08, 0.08), 0, zOff) * CFrame.Angles(0, yaw, 0),
			Vector3.new(wVar, 0.34, stepZ - 0.12),
			woodTones[((i - 1) % #woodTones) + 1],
			Enum.Material.WoodPlanks,
			false,
			0,
			true
		)
		if i == 4 then
			deck.PrimaryPart = plank
		end
	end

	-- 4 corner wooden pilings reaching down into the pond/bank
	local postOffs = {
		Vector3.new(-width * 0.44, -1.2, -depth * 0.43),
		Vector3.new(width * 0.44, -1.2, -depth * 0.43),
		Vector3.new(-width * 0.44, -1.2, depth * 0.43),
		Vector3.new(width * 0.44, -1.2, depth * 0.43),
	}
	for idx, off in ipairs(postOffs) do
		local pCf = deckCf * CFrame.new(off)
		makeCylinderY(
			deck,
			"Piling_" .. tostring(idx),
			pCf,
			0.78,
			3.5,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			true
		)
		addRopeCoil(
			deck,
			"PilingRope_" .. tostring(idx),
			(pCf * CFrame.new(0, 1.35, 0)).Position,
			0.78,
			2
		)
	end

	return deck
end

local function buildStool(parent: Instance, name: string, baseCf: CFrame): Model
	local m = makeModel(parent, name)
	local top = makeCylinderY(
		m,
		"SeatTop",
		baseCf * CFrame.new(0, 1.5, 0),
		2.0,
		0.34,
		PALETTE.WoodPlank3,
		Enum.Material.Wood,
		false,
		0,
		true
	)
	m.PrimaryPart = top
	makeCylinderY(
		m,
		"SeatRim",
		baseCf * CFrame.new(0, 1.32, 0),
		1.72,
		0.14,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	for i = 1, 3 do
		local a = (i / 3) * math.pi * 2 + 0.4
		local legCf = baseCf
			* CFrame.new(math.cos(a) * 0.56, 0.72, math.sin(a) * 0.56)
			* CFrame.Angles(math.sin(a) * 0.16, 0, -math.cos(a) * 0.16)
		makeCylinderY(
			m,
			"Leg_" .. tostring(i),
			legCf,
			0.26,
			1.56,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			false
		)
	end
	return m
end

local function buildBarrel(parent: Instance, name: string, baseCf: CFrame, scale: number): Model
	local m = makeModel(parent, name)
	local body = makeCylinderY(
		m,
		"BarrelBody",
		baseCf * CFrame.new(0, 1.35 * scale, 0),
		2.05 * scale,
		2.7 * scale,
		PALETTE.WoodPlank1,
		Enum.Material.WoodPlanks,
		false,
		0,
		true
	)
	m.PrimaryPart = body
	makeEllipsoid(
		m,
		"BarrelBelly",
		baseCf * CFrame.new(0, 1.35 * scale, 0),
		Vector3.new(2.28 * scale, 2.4 * scale, 2.28 * scale),
		PALETTE.WoodPlank2,
		Enum.Material.WoodPlanks,
		false,
		0,
		false
	)
	for idx, hFrac in ipairs({ 0.28, 0.50, 0.74 }) do
		makeCylinderY(
			m,
			"IronBand_" .. tostring(idx),
			baseCf * CFrame.new(0, hFrac * 2.7 * scale, 0),
			(if idx == 2 then 2.30 else 2.16) * scale,
			0.20 * scale,
			PALETTE.IronDark,
			Enum.Material.Metal,
			false,
			0,
			false
		)
	end
	makeCylinderY(
		m,
		"LidRim",
		baseCf * CFrame.new(0, 2.72 * scale, 0),
		1.96 * scale,
		0.14 * scale,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	return m
end

local function buildAmberLantern(
	parent: Instance,
	name: string,
	pos: Vector3,
	addLight: boolean
): Model
	local m = makeModel(parent, name)
	local baseCf = CFrame.new(pos)
	-- Dark iron pedestal base
	local base = makePart(
		m,
		"Base",
		baseCf * CFrame.new(0, 0.14, 0),
		Vector3.new(1.18, 0.28, 1.18),
		PALETTE.IronDark,
		Enum.Material.Metal,
		false,
		0,
		false
	)
	m.PrimaryPart = base
	-- Warm glowing amber glass chamber
	local glass = makePart(
		m,
		"AmberGlass",
		baseCf * CFrame.new(0, 0.85, 0),
		Vector3.new(0.84, 1.16, 0.84),
		PALETTE.AmberGlow,
		Enum.Material.Neon,
		false,
		0.12,
		false
	)
	makeEllipsoid(
		m,
		"InnerFlame",
		baseCf * CFrame.new(0, 0.84, 0),
		Vector3.new(0.46, 0.68, 0.46),
		PALETTE.AmberCore,
		Enum.Material.Neon,
		false,
		0,
		false
	)
	-- 4 iron corner struts
	for sx = -1, 1, 2 do
		for sz = -1, 1, 2 do
			makePart(
				m,
				"Strut_" .. tostring(sx) .. "_" .. tostring(sz),
				baseCf * CFrame.new(sx * 0.44, 0.85, sz * 0.44),
				Vector3.new(0.10, 1.24, 0.10),
				PALETTE.IronDark,
				Enum.Material.Metal,
				false,
				0,
				false
			)
		end
	end
	-- Stepped peaked roof cap + finial
	makePart(
		m,
		"RoofBase",
		baseCf * CFrame.new(0, 1.52, 0),
		Vector3.new(1.24, 0.18, 1.24),
		PALETTE.IronDark,
		Enum.Material.Metal,
		false,
		0,
		false
	)
	makeEllipsoid(
		m,
		"RoofDome",
		baseCf * CFrame.new(0, 1.72, 0),
		Vector3.new(0.86, 0.36, 0.86),
		PALETTE.IronDark,
		Enum.Material.Metal,
		false,
		0,
		false
	)
	makeEllipsoid(
		m,
		"Finial",
		baseCf * CFrame.new(0, 1.98, 0),
		Vector3.new(0.24, 0.24, 0.24),
		PALETTE.GoldMid,
		Enum.Material.Metal,
		false,
		0,
		false
	)

	if addLight then
		local pl = Instance.new("PointLight")
		pl.Color = PALETTE.AmberGlow
		pl.Brightness = 0.95
		pl.Range = 12
		pl.Parent = glass
	end
	return m
end

local function buildOrnateFishSign(parent: Instance, name: string, baseCf: CFrame): Model
	local m = makeModel(parent, name)
	local post = makeCylinderY(
		m,
		"Post",
		baseCf * CFrame.new(0, 2.35, 0),
		0.62,
		4.7,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		true
	)
	m.PrimaryPart = post
	makeEllipsoid(
		m,
		"PostFinial",
		baseCf * CFrame.new(0, 4.82, 0),
		Vector3.new(0.76, 0.42, 0.76),
		PALETTE.WoodPlank3,
		Enum.Material.Wood,
		false,
		0,
		false
	)

	local boardCf = baseCf * CFrame.new(0, 3.65, 0.28)
	makePart(
		m,
		"Board",
		boardCf,
		Vector3.new(3.9, 2.25, 0.36),
		PALETTE.WoodPlank2,
		Enum.Material.WoodPlanks,
		false,
		0,
		true
	)
	-- Carved dark wood frame
	makePart(
		m,
		"FrameT",
		boardCf * CFrame.new(0, 1.14, 0),
		Vector3.new(4.18, 0.24, 0.46),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		m,
		"FrameB",
		boardCf * CFrame.new(0, -1.14, 0),
		Vector3.new(4.12, 0.22, 0.46),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		m,
		"FrameL",
		boardCf * CFrame.new(-1.96, 0, 0),
		Vector3.new(0.24, 2.42, 0.46),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		m,
		"FrameR",
		boardCf * CFrame.new(1.96, 0, 0),
		Vector3.new(0.24, 2.42, 0.46),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)

	-- Sculpted 3D relief fish emblem (visible from front +Z)
	local iconCf = boardCf * CFrame.new(0, 0, 0.22)
	makeEllipsoid(
		m,
		"FishShadow",
		iconCf * CFrame.new(-0.22, -0.04, -0.04),
		Vector3.new(2.0, 1.05, 0.08),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makeEllipsoid(
		m,
		"FishBody",
		iconCf * CFrame.new(-0.26, 0, 0),
		Vector3.new(1.85, 0.92, 0.14),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		m,
		"FishTailTop",
		iconCf * CFrame.new(0.86, 0.26, 0) * CFrame.Angles(0, 0, math.rad(28)),
		Vector3.new(0.82, 0.32, 0.12),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makePart(
		m,
		"FishTailBot",
		iconCf * CFrame.new(0.86, -0.26, 0) * CFrame.Angles(0, 0, math.rad(-28)),
		Vector3.new(0.82, 0.32, 0.12),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0,
		false
	)
	makeEllipsoid(
		m,
		"FishEye",
		iconCf * CFrame.new(-0.78, 0.14, 0.07),
		Vector3.new(0.18, 0.18, 0.08),
		PALETTE.WoodDark,
		Enum.Material.SmoothPlastic,
		false,
		0,
		false
	)
	return m
end

-- ============================================================================
-- 3. FOCUS POND (LEFT — STARRY NIGHT MIRROR, DUAL RINGS, CONSTELLATION, 4 PILLARS)
-- ============================================================================

local function buildFocusPond(root: Model, origin: Vector3, rng: Random): Model
	local pond = makeModel(root, "FocusPond")
	local center = origin + Vector3.new(FOCUS_CENTER.X, 0, FOCUS_CENTER.Y)

	-- Sculpted dark rocky pond rim hugging the carved ellipse cleanly
	local rimSegs = 40
	for i = 1, rimSegs do
		local a1 = (i / rimSegs) * math.pi * 2
		local a2 = ((i + 1) / rimSegs) * math.pi * 2
		local p1 = center
			+ Vector3.new(math.cos(a1) * (FOCUS_RX + 0.3), -0.1, math.sin(a1) * (FOCUS_RZ + 0.3))
		local p2 = center
			+ Vector3.new(math.cos(a2) * (FOCUS_RX + 0.3), -0.1, math.sin(a2) * (FOCUS_RZ + 0.3))
		local mid = (p1 + p2) * 0.5
		local segLen = (p2 - p1).Magnitude + 0.55
		local cf = CFrame.lookAt(mid, p2)
		makeEllipsoid(
			pond,
			"PondRim_" .. tostring(i),
			cf * CFrame.new(0, 0.06, 0),
			Vector3.new(2.2, 1.05, segLen * 1.15),
			if i % 3 == 0 then PALETTE.RockUpper else PALETTE.RockDeep,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
	end

	-- Deep abyssal starry night bed (collidable so players who wade in never fall through the island!)
	makeCylinderY(
		pond,
		"WaterBed",
		CFrame.new(center + Vector3.new(0, -1.85, 0)),
		math.max(FOCUS_RX, FOCUS_RZ) * 2.08,
		0.6,
		PALETTE.FocusBed,
		Enum.Material.SmoothPlastic,
		true,
		0,
		false
	)
	-- Soft midnight-blue center reflection glow under the rings
	makeEllipsoid(
		pond,
		"MirrorCenterGlow",
		CFrame.new(center + Vector3.new(-0.4, -1.25, 0.2)),
		Vector3.new(FOCUS_RX * 1.25, 0.25, FOCUS_RZ * 1.25),
		PALETTE.FocusGlow,
		Enum.Material.Neon,
		false,
		0.76,
		false
	)

	-- 92 reflected starlight dots + 4-point sparkles inside the dark mirror pond
	for i = 1, 92 do
		local a = rng:NextNumber(0, math.pi * 2)
		local rFrac = math.sqrt(rng:NextNumber(0.02, 0.90))
		local sx = math.cos(a) * FOCUS_RX * rFrac
		local sz = math.sin(a) * FOCUS_RZ * rFrac
		local sy = rng:NextNumber(-1.05, -0.45)
		local szDot = if i % 8 == 0 then rng:NextNumber(0.36, 0.52) else rng:NextNumber(0.20, 0.34)
		local sCol = if i % 4 == 0 then PALETTE.FocusRingCyan else PALETTE.StarWhite
		makeEllipsoid(
			pond,
			"MirrorStar_" .. tostring(i),
			CFrame.new(center + Vector3.new(sx, sy, sz)),
			Vector3.new(szDot, 0.08, szDot),
			sCol,
			Enum.Material.Neon,
			false,
			0.04,
			false
		)
		-- 4-point cross glints on the brightest stars
		if i % 8 == 0 then
			makePart(
				pond,
				"StarCrossA_" .. tostring(i),
				CFrame.new(center + Vector3.new(sx, sy + 0.02, sz)),
				Vector3.new(szDot * 3.0, 0.04, 0.08),
				PALETTE.StarWhite,
				Enum.Material.Neon,
				false,
				0.22,
				false
			)
			makePart(
				pond,
				"StarCrossB_" .. tostring(i),
				CFrame.new(center + Vector3.new(sx, sy + 0.02, sz)),
				Vector3.new(0.08, 0.04, szDot * 3.0),
				PALETTE.StarWhite,
				Enum.Material.Neon,
				false,
				0.22,
				false
			)
		end
	end

	-- Translucent dark-navy water surface (SmoothPlastic so ALL stars & rings underneath stay crisp!)
	local waterSurface = makeEllipsoid(
		pond,
		"WaterSurface",
		CFrame.new(center + Vector3.new(0, -0.28, 0)),
		Vector3.new(FOCUS_RX * 1.98, 0.16, FOCUS_RZ * 1.98),
		PALETTE.FocusWater,
		Enum.Material.SmoothPlastic,
		false,
		0.54,
		false
	)
	waterSurface.Reflectance = 0.25

	-- Concentric luminous glowing rings on the water + 2 floating upper rings (signature reference look!)
	local ringAnchor = center + Vector3.new(-0.6, -0.14, 0.4)
	makeGlowingRing(
		pond,
		"FocusWaterRingOuter",
		CFrame.new(ringAnchor),
		8.2,
		0.34,
		34,
		PALETTE.FocusRingCore,
		PALETTE.FocusRingBlue,
		0.08,
		0.62
	)
	makeGlowingRing(
		pond,
		"FocusWaterRingMid",
		CFrame.new(ringAnchor + Vector3.new(0, 0.04, 0)),
		5.8,
		0.28,
		30,
		PALETTE.FocusRingCore,
		PALETTE.FocusRingCyan,
		0.06,
		0.56
	)
	makeGlowingRing(
		pond,
		"FocusWaterRingInner",
		CFrame.new(ringAnchor + Vector3.new(0, 0.08, 0)),
		3.6,
		0.22,
		24,
		PALETTE.FocusRingCore,
		PALETTE.FocusRingCyan,
		0.08,
		0.60
	)

	-- Floating upper concentric target rings hovering gracefully above the mirror
	makeGlowingRing(
		pond,
		"FocusFloatRingLower",
		CFrame.new(center + Vector3.new(-0.8, 2.8, -1.2)),
		6.2,
		0.32,
		32,
		PALETTE.FocusRingCore,
		PALETTE.FocusRingCyan,
		0.06,
		0.58
	)
	makeGlowingRing(
		pond,
		"FocusFloatRingUpper",
		CFrame.new(center + Vector3.new(-0.8, 4.9, -2.0)),
		5.3,
		0.28,
		30,
		PALETTE.FocusRingCore,
		PALETTE.FocusRingCyan,
		0.08,
		0.62
	)

	-- Crisp glowing constellation above the pond (star orbs with halo rings + thin bright lines)
	local constNodes = {
		center + Vector3.new(-11.2, 5.2, -3.5),
		center + Vector3.new(-12.4, 10.6, -6.2),
		center + Vector3.new(-3.2, 8.2, -6.8),
		center + Vector3.new(5.8, 10.0, -5.0),
		center + Vector3.new(11.4, 5.6, -0.6),
		center + Vector3.new(3.2, 6.0, 2.2),
		center + Vector3.new(-6.8, 6.4, 1.4),
	}
	local constEdges = {
		{ 1, 2 },
		{ 2, 3 },
		{ 3, 4 },
		{ 4, 5 },
		{ 5, 6 },
		{ 6, 3 },
		{ 2, 7 },
		{ 7, 1 },
	}
	local constModel = makeModel(pond, "FocusConstellation")
	for idx, pt in ipairs(constNodes) do
		local big = (idx == 2 or idx == 4 or idx == 5)
		local coreSz = if big then 0.72 else 0.48
		makeEllipsoid(
			constModel,
			"NodeCore_" .. tostring(idx),
			CFrame.new(pt),
			Vector3.new(coreSz, coreSz, coreSz),
			PALETTE.StarWhite,
			Enum.Material.Neon,
			false,
			0.04,
			false
		)
		makeEllipsoid(
			constModel,
			"NodeHalo_" .. tostring(idx),
			CFrame.new(pt),
			Vector3.new(coreSz * 2.1, coreSz * 2.1, coreSz * 2.1),
			PALETTE.FocusRingCyan,
			Enum.Material.Neon,
			false,
			0.72,
			false
		)
	end
	for idx, edge in ipairs(constEdges) do
		makeSegment(
			constModel,
			"ConstLine_" .. tostring(idx),
			constNodes[edge[1]],
			constNodes[edge[2]],
			0.09,
			PALETTE.FocusRingCore,
			Enum.Material.Neon,
			false,
			0.18,
			false,
			true
		)
	end

	-- 4 Tall Hexagonal Crystal Pillars around the Focus Pond + seamless ultra-delicate vertical light beams
	-- (Beams <= 1.05 studs wide, transparency >= 0.86, smooth zero-seam vertical rays!)
	local pillarSpecs = {
		{
			pos = origin + Vector3.new(-42.5, -0.1, 7.2),
			rad = 1.45,
			h = 7.6,
			light = true,
			beamH = 38,
		},
		{
			pos = origin + Vector3.new(-35.2, -0.1, -9.8),
			rad = 1.50,
			h = 8.0,
			light = true,
			beamH = 40,
		},
		{
			pos = origin + Vector3.new(-21.8, -0.1, -15.2),
			rad = 1.60,
			h = 8.6,
			light = true,
			beamH = 42,
		},
		{
			pos = origin + Vector3.new(-14.2, -0.1, -14.2),
			rad = 1.15,
			h = 5.6,
			light = false,
			beamH = 26,
		},
	}
	for i, pl in ipairs(pillarSpecs) do
		buildCrystalCluster(
			pond,
			"FocusCrystalPillar_" .. tostring(i),
			CFrame.new(pl.pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			pl.rad,
			pl.h,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			4,
			pl.light,
			rng
		)

		-- Seamless full-height ultra-thin vertical beam + soft base glow (zero horizontal seam lines!)
		local beamBaseY = pl.pos.Y + pl.h * 0.70
		makeCylinderY(
			pond,
			"BeamCore_" .. tostring(i),
			CFrame.new(pl.pos.X, beamBaseY + pl.beamH * 0.5, pl.pos.Z),
			0.38,
			pl.beamH,
			PALETTE.CrystalCore,
			Enum.Material.Neon,
			false,
			0.87,
			false
		)
		makeCylinderY(
			pond,
			"BeamHalo_" .. tostring(i),
			CFrame.new(pl.pos.X, beamBaseY + pl.beamH * 0.5, pl.pos.Z),
			1.02,
			pl.beamH,
			PALETTE.CrystalCyan,
			Enum.Material.Neon,
			false,
			0.93,
			false
		)
		-- Brighter lower flare right above the crystal tip
		makeCylinderY(
			pond,
			"BeamBaseFlare_" .. tostring(i),
			CFrame.new(pl.pos.X, beamBaseY + 4.5, pl.pos.Z),
			0.74,
			9.0,
			PALETTE.CrystalCyan,
			Enum.Material.Neon,
			false,
			0.88,
			false
		)
	end

	-- Focus Deck (front-left) with 3-legged stool, iron-banded barrel & 3 corner crystals
	local deckCf = CFrame.new(origin + FOCUS_DECK_POS)
		* CFrame.Angles(0, math.rad(FOCUS_DECK_YAW_DEG), 0)
	buildWoodenDeck(pond, "FocusDeckModel", deckCf, 11.4, 7.6, "FocusDeck", rng)
	buildStool(pond, "FocusStool", deckCf * CFrame.new(-0.9, 0.18, -0.5))
	buildBarrel(pond, "FocusBarrel", deckCf * CFrame.new(4.1, 0.18, 1.8), 0.96)

	local deckCrystals = {
		{ off = Vector3.new(-5.1, 0.18, 3.2), r = 0.42, h = 2.1 },
		{ off = Vector3.new(-5.1, 0.18, -3.2), r = 0.40, h = 2.0 },
		{ off = Vector3.new(5.1, 0.18, -3.2), r = 0.42, h = 2.2 },
	}
	for idx, dc in ipairs(deckCrystals) do
		buildHexShard(
			pond,
			"FocusDeckCrystal_" .. tostring(idx),
			deckCf * CFrame.new(dc.off),
			dc.r,
			dc.h,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			idx == 1
		)
	end

	return pond
end

-- ============================================================================
-- 4. INSTINCT POND (RIGHT — SPIRAL GALAXY, 4 SCULPTURAL COSMIC FISH, CRYSTAL TREE)
-- ============================================================================

local function buildCosmicFish(
	parent: Instance,
	name: string,
	cf: CFrame,
	scale: number,
	kind: string,
	rng: Random
): Model
	local fish = makeModel(parent, name)
	local bodyCol = PALETTE.FishGoldBody
	local headCol = PALETTE.FishGoldBody
	local finCol = PALETTE.FishGoldGlow
	local tailCol = PALETTE.FishGoldGlow
	local accentCol = PALETTE.FishGoldGlow
	local bodyMat = Enum.Material.Neon
	local bodyTr = 0.08

	if kind == "rainbow" then
		headCol = PALETTE.FishRainbowHead
		bodyCol = PALETTE.FishRainbowMid
		finCol = PALETTE.FishRainbowTail
		tailCol = PALETTE.FishRainbowTail
		accentCol = PALETTE.GalaxyCore
		bodyMat = Enum.Material.Neon
		bodyTr = 0.08
	elseif kind == "nebula" then
		headCol = PALETTE.FishNebulaBody
		bodyCol = PALETTE.FishNebulaBody
		finCol = PALETTE.FishNebulaTrim
		tailCol = PALETTE.FishNebulaPink
		accentCol = PALETTE.FishNebulaPink
		bodyMat = Enum.Material.SmoothPlastic
		bodyTr = 0.02
	elseif kind == "azure" then
		headCol = PALETTE.FishAzureBody
		bodyCol = PALETTE.FishAzureBody
		finCol = PALETTE.FishAzureGlow
		tailCol = PALETTE.FishAzureGlow
		accentCol = PALETTE.StarWhite
		bodyMat = Enum.Material.Neon
		bodyTr = 0.22
	end

	-- Articulated graceful curved body (Head + MidBody + RearBody -> natural swimming S-curve!)
	local body = makeEllipsoid(
		fish,
		"Body",
		cf,
		Vector3.new(1.85 * scale, 0.72 * scale, 3.6 * scale),
		bodyCol,
		bodyMat,
		false,
		bodyTr,
		false
	)
	fish.PrimaryPart = body

	makeEllipsoid(
		fish,
		"Head",
		cf
			* CFrame.new(0.18 * scale, 0.02 * scale, -1.85 * scale)
			* CFrame.Angles(0, math.rad(-10), 0),
		Vector3.new(1.55 * scale, 0.66 * scale, 2.15 * scale),
		headCol,
		bodyMat,
		false,
		bodyTr,
		false
	)
	makeEllipsoid(
		fish,
		"RearBody",
		cf * CFrame.new(-0.34 * scale, 0, 1.95 * scale) * CFrame.Angles(0, math.rad(16), 0),
		Vector3.new(1.18 * scale, 0.52 * scale, 2.35 * scale),
		if kind == "rainbow" then PALETTE.FishRainbowTail else bodyCol,
		bodyMat,
		false,
		bodyTr,
		false
	)

	-- Glowing dorsal ridge / spine highlight
	makeEllipsoid(
		fish,
		"SpineGlow",
		cf * CFrame.new(0.05 * scale, 0.26 * scale, -0.15 * scale),
		Vector3.new(0.86 * scale, 0.22 * scale, 3.3 * scale),
		accentCol,
		Enum.Material.Neon,
		false,
		if kind == "nebula" then 0.28 else 0.14,
		false
	)

	-- Sleek swept-back pectoral fins
	makeEllipsoid(
		fish,
		"FinL",
		cf
			* CFrame.new(-1.32 * scale, -0.02 * scale, -0.15 * scale)
			* CFrame.Angles(0, math.rad(54), 0),
		Vector3.new(1.85 * scale, 0.14 * scale, 0.82 * scale),
		finCol,
		Enum.Material.Neon,
		false,
		0.22,
		false
	)
	makeEllipsoid(
		fish,
		"FinR",
		cf
			* CFrame.new(1.38 * scale, -0.02 * scale, -0.35 * scale)
			* CFrame.Angles(0, math.rad(-48), 0),
		Vector3.new(1.85 * scale, 0.14 * scale, 0.82 * scale),
		finCol,
		Enum.Material.Neon,
		false,
		0.22,
		false
	)

	-- Flowing forked crescent / veil tail
	local tailBaseCf = cf
		* CFrame.new(-0.78 * scale, 0, 3.25 * scale)
		* CFrame.Angles(0, math.rad(22), 0)
	makeEllipsoid(
		fish,
		"TailLobeL",
		tailBaseCf * CFrame.new(-0.72 * scale, 0, 0.95 * scale) * CFrame.Angles(0, math.rad(-32), 0),
		Vector3.new(0.66 * scale, 0.16 * scale, 2.55 * scale),
		tailCol,
		Enum.Material.Neon,
		false,
		0.16,
		false
	)
	makeEllipsoid(
		fish,
		"TailLobeR",
		tailBaseCf * CFrame.new(0.76 * scale, 0, 0.85 * scale) * CFrame.Angles(0, math.rad(34), 0),
		Vector3.new(0.66 * scale, 0.16 * scale, 2.45 * scale),
		if kind == "rainbow" then PALETTE.GalaxyPink else tailCol,
		Enum.Material.Neon,
		false,
		0.18,
		false
	)

	-- Extra starry constellation dots embedded on the dark Nebula whale-fish!
	if kind == "nebula" then
		for s = 1, 10 do
			local sx = rng:NextNumber(-0.65, 0.65) * scale
			local sz = rng:NextNumber(-2.0, 2.1) * scale
			local dotCol = if s % 3 == 0
				then PALETTE.FishNebulaPink
				elseif s % 2 == 0 then PALETTE.CrystalCyan
				else PALETTE.StarWhite
			makeEllipsoid(
				fish,
				"BodyStar_" .. tostring(s),
				cf * CFrame.new(sx, 0.36 * scale, sz),
				Vector3.new(0.24 * scale, 0.10 * scale, 0.24 * scale),
				dotCol,
				Enum.Material.Neon,
				false,
				0.04,
				false
			)
		end
	end

	return fish
end

local function buildCrystalTree(parent: Instance, basePos: Vector3, rng: Random): Model
	local tree = makeModel(parent, "CrystalTree")

	-- 5 gnarled dark-violet surface roots clutching the midnight grass
	for r = 1, 5 do
		local a = (r / 5) * math.pi * 2 + 0.3
		local p1 = basePos + Vector3.new(0, 1.35, 0)
		local pMid = basePos + Vector3.new(math.cos(a) * 1.9, 0.45, math.sin(a) * 1.9)
		local pEnd = basePos
			+ Vector3.new(math.cos(a + 0.25) * 3.8, -0.05, math.sin(a + 0.25) * 3.8)
		makeSegment(
			tree,
			"RootA_" .. tostring(r),
			p1,
			pMid,
			1.15,
			PALETTE.TreeBarkDark,
			Enum.Material.Wood,
			false,
			0,
			true,
			true
		)
		makeSegment(
			tree,
			"RootB_" .. tostring(r),
			pMid,
			pEnd,
			0.68,
			PALETTE.TreeBarkDark,
			Enum.Material.Wood,
			false,
			0,
			false,
			true
		)
	end

	-- Twisted organic trunk rising in 5 curved tapering segments
	local trunkPts = {
		basePos + Vector3.new(0, 0.0, 0),
		basePos + Vector3.new(-0.55, 2.2, 0.35),
		basePos + Vector3.new(-0.15, 4.4, -0.25),
		basePos + Vector3.new(0.45, 6.4, 0.15),
		basePos + Vector3.new(0.25, 8.2, -0.1),
	}
	for i = 1, #trunkPts - 1 do
		local thick = 2.45 - (i - 1) * 0.34
		makeSegment(
			tree,
			"Trunk_" .. tostring(i),
			trunkPts[i],
			trunkPts[i + 1],
			thick,
			if i % 2 == 0 then PALETTE.TreeTrunk else PALETTE.TreeBarkDark,
			Enum.Material.Wood,
			false,
			0,
			true,
			true
		)
	end

	-- 5 thick sweeping branches fanning out into a lush crystal crown
	local forkOrigin = trunkPts[4]
	local crownOrigin = trunkPts[5]
	local branchSpecs = {
		{
			start = forkOrigin,
			mid = basePos + Vector3.new(-3.2, 8.4, 1.6),
			tip = basePos + Vector3.new(-5.8, 10.2, 2.8),
		},
		{
			start = forkOrigin,
			mid = basePos + Vector3.new(3.4, 8.6, 1.8),
			tip = basePos + Vector3.new(6.0, 10.6, 2.6),
		},
		{
			start = crownOrigin,
			mid = basePos + Vector3.new(-2.8, 10.2, -2.4),
			tip = basePos + Vector3.new(-5.0, 12.2, -3.6),
		},
		{
			start = crownOrigin,
			mid = basePos + Vector3.new(3.0, 10.4, -2.2),
			tip = basePos + Vector3.new(5.4, 12.4, -3.4),
		},
		{
			start = crownOrigin,
			mid = basePos + Vector3.new(0.2, 10.8, 0.4),
			tip = basePos + Vector3.new(0.4, 13.0, 0.2),
		},
	}
	for bIdx, br in ipairs(branchSpecs) do
		makeSegment(
			tree,
			"BranchA_" .. tostring(bIdx),
			br.start,
			br.mid,
			1.12,
			PALETTE.TreeTrunk,
			Enum.Material.Wood,
			false,
			0,
			true,
			true
		)
		makeSegment(
			tree,
			"BranchB_" .. tostring(bIdx),
			br.mid,
			br.tip,
			0.72,
			PALETTE.TreeTrunk,
			Enum.Material.Wood,
			false,
			0,
			false,
			true
		)

		-- 8 dense faceted pink/magenta/violet hexagonal crystals blooming from each branch!
		local crystalCols = {
			PALETTE.CrystalViolet,
			PALETTE.CrystalMagenta,
			PALETTE.CrystalPink,
			PALETTE.CrystalPink,
		}
		for c = 1, 8 do
			local a = (c / 8) * math.pi * 2 + bIdx * 0.65
			local tilt = rng:NextNumber(0.28, 1.02)
			local anchorPos = if c <= 3 then br.mid:Lerp(br.tip, 0.55) else br.tip
			local cCf = CFrame.new(anchorPos) * CFrame.Angles(0, a, tilt)
			local col = crystalCols[((c + bIdx) % #crystalCols) + 1]
			buildHexShard(
				tree,
				"CanopyCrystal_" .. tostring(bIdx) .. "_" .. tostring(c),
				cCf,
				rng:NextNumber(0.74, 1.12),
				rng:NextNumber(4.0, 6.4),
				col,
				PALETTE.CrystalPinkCore,
				false
			)
		end
	end

	-- Extra lush inner crown fan crystals bridging the branches into a full glowing tree crown!
	for k = 1, 6 do
		local a = (k / 6) * math.pi * 2 + 0.3
		local cf = CFrame.new(basePos + Vector3.new(math.cos(a) * 2.2, 10.6, math.sin(a) * 1.8))
			* CFrame.Angles(0, a, rng:NextNumber(0.30, 0.62))
		buildHexShard(
			tree,
			"CrownBridgeCrystal_" .. tostring(k),
			cf,
			rng:NextNumber(0.85, 1.15),
			rng:NextNumber(4.6, 6.2),
			if k % 2 == 0 then PALETTE.CrystalPink else PALETTE.CrystalMagenta,
			PALETTE.CrystalPinkCore,
			false
		)
	end

	-- Central crown hero crystal + warm violet-pink glow light
	buildHexShard(
		tree,
		"CrownHeroCrystal",
		CFrame.new(basePos + Vector3.new(0.2, 12.2, 0.1)) * CFrame.Angles(0.08, 0.5, -0.06),
		1.25,
		6.0,
		PALETTE.CrystalPink,
		PALETTE.CrystalPinkCore,
		true
	)

	-- Fallen glowing pink/lilac petals & tiny shards scattered on the ground around the roots
	for p = 1, 20 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(2.6, 8.2)
		local pPos = basePos + Vector3.new(math.cos(a) * r, 0.08, math.sin(a) * r)
		makeEllipsoid(
			tree,
			"FallenPetal_" .. tostring(p),
			CFrame.new(pPos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			Vector3.new(rng:NextNumber(0.35, 0.65), 0.10, rng:NextNumber(0.22, 0.42)),
			if p % 2 == 0 then PALETTE.CrystalPink else PALETTE.CrystalMagenta,
			Enum.Material.Neon,
			false,
			0.14,
			false
		)
	end

	-- Gentle falling crystal petals & golden fireflies emitter
	local fxBox = makePart(
		tree,
		"TreeFxAnchor",
		CFrame.new(basePos + Vector3.new(0, 10.5, 0)),
		Vector3.new(12, 4, 12),
		PALETTE.CrystalPink,
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	fxBox.CanQuery = false

	local petals = Instance.new("ParticleEmitter")
	petals.Name = "FallingCrystalPetals"
	petals.Color = ColorSequence.new(PALETTE.CrystalPink, PALETTE.CrystalViolet)
	petals.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.28),
		NumberSequenceKeypoint.new(0.7, 0.24),
		NumberSequenceKeypoint.new(1, 0),
	})
	petals.Lifetime = NumberRange.new(2.8, 4.4)
	petals.Rate = 8
	petals.Speed = NumberRange.new(0.4, 1.1)
	petals.Acceleration = Vector3.new(-0.3, -1.3, 0.2)
	petals.LightEmission = 1
	petals.Parent = fxBox

	local fireflies = Instance.new("ParticleEmitter")
	fireflies.Name = "GoldenFireflies"
	fireflies.Color = ColorSequence.new(PALETTE.FireflyGold, PALETTE.AmberGlow)
	fireflies.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(0.5, 0.30),
		NumberSequenceKeypoint.new(1, 0),
	})
	fireflies.Lifetime = NumberRange.new(2.2, 3.8)
	fireflies.Rate = 8
	fireflies.Speed = NumberRange.new(0.5, 1.4)
	fireflies.SpreadAngle = Vector2.new(180, 180)
	fireflies.LightEmission = 1
	fireflies.Parent = fxBox

	return tree
end

local function buildInstinctPond(root: Model, origin: Vector3, rng: Random): Model
	local pond = makeModel(root, "InstinctPond")
	local center = origin + Vector3.new(INSTINCT_CENTER.X, 0, INSTINCT_CENTER.Y)

	-- Sculpted dark violet-indigo rocky rim hugging the Instinct basin
	local rimSegs = 40
	for i = 1, rimSegs do
		local a1 = (i / rimSegs) * math.pi * 2
		local a2 = ((i + 1) / rimSegs) * math.pi * 2
		local aMid = (a1 + a2) * 0.5
		-- Leave slight visual outlet toward the front-right waterfall
		if angleDiff(aMid, 0.78) < 0.12 then
			continue
		end
		local p1 = center
			+ Vector3.new(
				math.cos(a1) * (INSTINCT_RX + 0.3),
				-0.1,
				math.sin(a1) * (INSTINCT_RZ + 0.3)
			)
		local p2 = center
			+ Vector3.new(
				math.cos(a2) * (INSTINCT_RX + 0.3),
				-0.1,
				math.sin(a2) * (INSTINCT_RZ + 0.3)
			)
		local mid = (p1 + p2) * 0.5
		local segLen = (p2 - p1).Magnitude + 0.55
		local cf = CFrame.lookAt(mid, p2)
		makeEllipsoid(
			pond,
			"PondRim_" .. tostring(i),
			cf * CFrame.new(0, 0.06, 0),
			Vector3.new(2.2, 1.05, segLen * 1.15),
			if i % 3 == 0 then PALETTE.RockViolet else PALETTE.RockDeep,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
	end

	-- Deep abyssal purple bed (collidable so players who wade in never fall through the island!)
	makeCylinderY(
		pond,
		"WaterBed",
		CFrame.new(center + Vector3.new(0, -1.85, 0)),
		math.max(INSTINCT_RX, INSTINCT_RZ) * 2.08,
		0.6,
		PALETTE.GalaxyBed,
		Enum.Material.SmoothPlastic,
		true,
		0,
		false
	)
	makeEllipsoid(
		pond,
		"NebulaOuter",
		CFrame.new(center + Vector3.new(0, -1.35, 0)),
		Vector3.new(INSTINCT_RX * 1.62, 0.20, INSTINCT_RZ * 1.62),
		PALETTE.GalaxyOuter,
		Enum.Material.Neon,
		false,
		0.70,
		false
	)
	makeEllipsoid(
		pond,
		"NebulaMid",
		CFrame.new(center + Vector3.new(0, -1.24, 0)),
		Vector3.new(INSTINCT_RX * 1.08, 0.18, INSTINCT_RZ * 1.08),
		PALETTE.GalaxyMid,
		Enum.Material.Neon,
		false,
		0.56,
		false
	)
	-- Bright white-lavender galactic core (3 soft nested glowing layers — luminous without hiding fish)
	makeEllipsoid(
		pond,
		"GalaxyCoreOuter",
		CFrame.new(center + Vector3.new(0, -1.16, 0)),
		Vector3.new(6.4, 0.16, 5.2),
		PALETTE.GalaxyPink,
		Enum.Material.Neon,
		false,
		0.56,
		false
	)
	makeEllipsoid(
		pond,
		"GalaxyCoreMid",
		CFrame.new(center + Vector3.new(0, -1.10, 0)),
		Vector3.new(3.4, 0.16, 2.9),
		PALETTE.GalaxyCore,
		Enum.Material.Neon,
		false,
		0.32,
		false
	)
	local coreEye = makeEllipsoid(
		pond,
		"GalaxyCoreEye",
		CFrame.new(center + Vector3.new(0, -1.04, 0)),
		Vector3.new(1.6, 0.16, 1.4),
		PALETTE.StarWhite,
		Enum.Material.Neon,
		false,
		0.12,
		false
	)

	local coreLight = Instance.new("PointLight")
	coreLight.Color = PALETTE.GalaxyPink
	coreLight.Brightness = 1.15
	coreLight.Range = 18
	coreLight.Parent = coreEye

	-- 4 silky curved spiral galaxy arms (24 overlapping translucent nebula wisps per arm!)
	for arm = 0, 3 do
		local baseAng = arm * (math.pi * 0.5) + 0.35
		local isMajor = (arm % 2 == 0)
		local steps = 24
		for s = 1, steps do
			local t = s / steps
			local ang = baseAng + t * 3.35
			local rx = 1.2 + t * (INSTINCT_RX * 0.80)
			local rz = 1.0 + t * (INSTINCT_RZ * 0.80)
			local px = math.cos(ang) * rx
			local pz = math.sin(ang) * rz
			local nextAng = baseAng + (t + 0.06) * 3.35
			local nx = math.cos(nextAng) * (rx + 0.45)
			local nz = math.sin(nextAng) * (rz + 0.38)
			local segPos = center + Vector3.new(px, -1.12 + (1 - t) * 0.14, pz)
			local segCf = CFrame.lookAt(segPos, Vector3.new(center.X + nx, segPos.Y, center.Z + nz))

			local col = if t < 0.24
				then PALETTE.GalaxyCore
				elseif t < 0.56 then (if isMajor then PALETTE.GalaxyPink else PALETTE.GalaxyMid)
				else (if isMajor then PALETTE.GalaxyMid else PALETTE.CrystalBlue)
			local w = (if isMajor then 2.1 else 1.45) * (1.1 - t * 0.48)
			local len = (if isMajor then 2.8 else 2.2) * (0.85 + t * 0.45)
			local tr = math.clamp((if isMajor then 0.48 else 0.62) + t * 0.36, 0.38, 0.92)

			makeEllipsoid(
				pond,
				"SpiralArm_" .. tostring(arm) .. "_" .. tostring(s),
				segCf,
				Vector3.new(w, 0.12, len),
				col,
				Enum.Material.Neon,
				false,
				tr,
				false
			)
		end
	end

	-- 75+ cosmic stars & dust specks across the galaxy pond
	for i = 1, 75 do
		local a = rng:NextNumber(0, math.pi * 2)
		local rFrac = math.sqrt(rng:NextNumber(0.05, 0.90))
		local sx = math.cos(a) * INSTINCT_RX * rFrac
		local sz = math.sin(a) * INSTINCT_RZ * rFrac
		local sy = rng:NextNumber(-0.98, -0.52)
		local dotSz = rng:NextNumber(0.14, 0.34)
		local col = if i % 5 == 0
			then PALETTE.GalaxyPink
			elseif i % 4 == 0 then PALETTE.CrystalCyan
			elseif i % 7 == 0 then PALETTE.FireflyGold
			else PALETTE.StarWhite
		makeEllipsoid(
			pond,
			"GalaxyStar_" .. tostring(i),
			CFrame.new(center + Vector3.new(sx, sy, sz)),
			Vector3.new(dotSz, 0.08, dotSz),
			col,
			Enum.Material.Neon,
			false,
			0.06,
			false
		)
	end

	-- 4 Sculptural Cosmic Fish (Golden, Rainbow, Nebula Whale-Fish, small Azure)
	-- Positioned clearly above the galaxy bed and right under the translucent water!
	local fishSpecs = {
		{
			name = "CosmicFish_Gold",
			kind = "gold",
			off = Vector3.new(-4.8, -0.52, -4.4),
			yaw = 42,
			scale = 1.18,
			r = 6.5,
			speed = 0.58,
			phase = 0.2,
		},
		{
			name = "CosmicFish_Rainbow",
			kind = "rainbow",
			off = Vector3.new(-3.4, -0.50, 5.6),
			yaw = -112,
			scale = 1.24,
			r = 6.8,
			speed = 0.50,
			phase = 2.1,
		},
		{
			name = "CosmicFish_Nebula",
			kind = "nebula",
			off = Vector3.new(6.8, -0.48, 4.6),
			yaw = -38,
			scale = 1.38,
			r = 8.2,
			speed = 0.42,
			phase = 4.3,
		},
		{
			name = "CosmicFish_Azure",
			kind = "azure",
			off = Vector3.new(-10.4, -0.54, 0.6),
			yaw = 158,
			scale = 0.74,
			r = 10.4,
			speed = 0.66,
			phase = 3.2,
		},
	}
	for _, fd in ipairs(fishSpecs) do
		local fCf = CFrame.new(center + fd.off) * CFrame.Angles(0, math.rad(fd.yaw), 0)
		local fm = buildCosmicFish(pond, fd.name, fCf, fd.scale, fd.kind, rng)
		fm:SetAttribute("OrbitRadius", fd.r)
		fm:SetAttribute("OrbitSpeed", fd.speed)
		fm:SetAttribute("OrbitPhase", fd.phase)
		fm:SetAttribute("DepthY", fd.off.Y)
	end

	-- Translucent royal-purple water surface (SmoothPlastic reveals the entire spiral galaxy & fish!)
	local waterSurface = makeEllipsoid(
		pond,
		"WaterSurface",
		CFrame.new(center + Vector3.new(0, -0.28, 0)),
		Vector3.new(INSTINCT_RX * 1.98, 0.16, INSTINCT_RZ * 1.98),
		PALETTE.GalaxyWater,
		Enum.Material.SmoothPlastic,
		false,
		0.56,
		false
	)
	waterSurface.Reflectance = 0.22

	-- Subtle cosmic mist sparkles rising gently from the galaxy center
	local dust = Instance.new("ParticleEmitter")
	dust.Name = "GalaxySparkles"
	dust.Color = ColorSequence.new(PALETTE.GalaxyCore, PALETTE.GalaxyPink)
	dust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.20),
		NumberSequenceKeypoint.new(1, 0),
	})
	dust.Lifetime = NumberRange.new(1.8, 3.0)
	dust.Rate = 7
	dust.Speed = NumberRange.new(0.4, 1.0)
	dust.EmissionDirection = Enum.NormalId.Top
	dust.LightEmission = 1
	dust.Parent = coreEye

	-- Instinct Deck (upper-right bank) with 3-legged stool
	local deckCf = CFrame.new(origin + INSTINCT_DECK_POS)
		* CFrame.Angles(0, math.rad(INSTINCT_DECK_YAW_DEG), 0)
	buildWoodenDeck(pond, "InstinctDeckModel", deckCf, 10.4, 6.8, "InstinctDeck", rng)
	buildStool(pond, "InstinctStool", deckCf * CFrame.new(-0.4, 0.18, -0.3))

	-- Violet-Pink Crystal Tree behind-right of Instinct Pond
	buildCrystalTree(pond, origin + TREE_POS, rng)

	-- 3 Tall Faceted Rune Monoliths with crisp 3D Neon cyan glyphs (NOT invisible SurfaceGui!)
	local monolithSpecs = {
		{ pos = origin + Vector3.new(26.5, 0, -12.6), yaw = -22, h = 5.4, runes = { 3, 2 } },
		{ pos = origin + Vector3.new(40.2, 0, -3.4), yaw = -54, h = 6.0, runes = { 1, 5 } },
		{ pos = origin + Vector3.new(40.8, 0, 5.4), yaw = -74, h = 5.2, runes = { 4, 6 } },
	}
	for i, ml in ipairs(monolithSpecs) do
		local mModel = makeModel(pond, "RuneMonolith_" .. tostring(i))
		local mCf = CFrame.new(ml.pos) * CFrame.Angles(0, math.rad(ml.yaw), 0)
		makePart(
			mModel,
			"Base",
			mCf * CFrame.new(0, 0.4, 0),
			Vector3.new(2.7, 0.8, 2.2),
			PALETTE.RockDeep,
			Enum.Material.Concrete,
			false,
			0,
			true
		)
		local body = makePart(
			mModel,
			"Shaft",
			mCf
				* CFrame.new(0, ml.h * 0.5, 0)
				* CFrame.Angles(math.rad(-2), 0, math.rad(if i == 2 then 2 else -2)),
			Vector3.new(2.2, ml.h, 1.6),
			PALETTE.StoneDark,
			Enum.Material.Concrete,
			false,
			0,
			true
		)
		mModel.PrimaryPart = body
		makeWedge(
			mModel,
			"BevelTop",
			mCf * CFrame.new(0, ml.h + 0.55, 0) * CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(1.58, 1.15, 2.15),
			PALETTE.StoneMid,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
		-- 2 stacked glowing 3D cyan rune glyphs on front face (+Z)
		for rIdx, pattern in ipairs(ml.runes) do
			local yPos = ml.h * (if rIdx == 1 then 0.66 else 0.34)
			addRuneGlyph(
				mModel,
				"MonolithRune_" .. tostring(rIdx),
				mCf * CFrame.new(0, yPos, 0.86),
				pattern,
				0.54,
				0.66,
				0.14,
				PALETTE.RuneCyan
			)
		end
	end

	return pond
end

-- ============================================================================
-- 5. OBSERVATORY (BACK-CENTER — STEPPED STONE DAIS, PARAPET, HERO GOLDEN TELESCOPE)
-- ============================================================================

local function buildObservatory(root: Model, origin: Vector3, rng: Random)
	local obs = makeFolder(root, "Observatory")
	local center = origin + OBS_POS

	-- 2-tier circular dark stone dais with carved blocks around the perimeter
	makeCylinderY(
		obs,
		"DaisLower",
		CFrame.new(center + Vector3.new(0, 0.6, 0)),
		16.4,
		1.2,
		PALETTE.StoneDark,
		Enum.Material.Concrete,
		true,
		0,
		true
	)
	makeCylinderY(
		obs,
		"DaisUpper",
		CFrame.new(center + Vector3.new(0, 1.55, 0)),
		13.0,
		0.8,
		PALETTE.StoneMid,
		Enum.Material.Concrete,
		true,
		0,
		true
	)

	-- Carved stone trim blocks around the circular base
	for i = 1, 16 do
		local a = (i / 16) * math.pi * 2
		local bCf = CFrame.new(center + Vector3.new(math.cos(a) * 7.85, 0.65, math.sin(a) * 7.85))
			* CFrame.Angles(0, -a, 0)
		makePart(
			obs,
			"DaisBlock_" .. tostring(i),
			bCf,
			Vector3.new(1.1, 1.25, 2.9),
			jitterColor(PALETTE.StoneDark, rng, 0.05),
			Enum.Material.Concrete,
			false,
			0,
			true
		)
	end

	-- Low curved stone parapet wall (mureta) wrapping the back half of the observatory
	for i = 1, 8 do
		local t = (i - 1) / 7
		local a = math.rad(195 + t * 150) -- back arc (-Z)
		local pCf = CFrame.new(center + Vector3.new(math.cos(a) * 6.0, 2.75, math.sin(a) * 6.0))
			* CFrame.Angles(0, -a, 0)
		makePart(
			obs,
			"Parapet_" .. tostring(i),
			pCf,
			Vector3.new(1.35, 1.7 + rng:NextNumber(-0.15, 0.15), 2.35),
			jitterColor(PALETTE.StoneDark, rng, 0.04),
			Enum.Material.Concrete,
			false,
			0,
			true
		)
		makePart(
			obs,
			"ParapetCap_" .. tostring(i),
			pCf * CFrame.new(0, 0.92, 0),
			Vector3.new(1.52, 0.24, 2.52),
			PALETTE.StoneLight,
			Enum.Material.Concrete,
			false,
			0,
			false
		)
	end

	-- 3 wide curved front-right stone steps leading down to the rune path
	for s = 1, 3 do
		makePart(
			obs,
			"ObsStep_" .. tostring(s),
			CFrame.new(
				center + Vector3.new(2.8 + (3 - s) * 0.55, s * 0.52 - 0.15, 6.2 + (3 - s) * 0.95)
			) * CFrame.Angles(0, math.rad(-26), 0),
			Vector3.new(5.4 - s * 0.3, 0.56, 1.55),
			if s % 2 == 0 then PALETTE.StoneMid else PALETTE.StoneDark,
			Enum.Material.Concrete,
			true,
			0,
			true
		)
	end

	-- Luminous glowing cyan floor ring around the telescope
	makeGlowingRing(
		obs,
		"ObsFloorRing",
		CFrame.new(center + Vector3.new(0, 2.02, 0)),
		4.1,
		0.22,
		28,
		PALETTE.FocusRingCore,
		PALETTE.RuneCyan,
		0.06,
		0.54
	)
	makeNeonRing(
		obs,
		"ObsInnerRing",
		CFrame.new(center + Vector3.new(0, 2.00, 0)),
		2.5,
		0.12,
		0.08,
		22,
		PALETTE.RuneCyan,
		0.32
	)

	-- Hero Golden Telescope (scaled ~1.45x, detailed tripod + brass collars + finder + glowing lens)
	local scope = makeModel(obs, "GoldenTelescope")
	local baseCf = CFrame.new(center + Vector3.new(0, 1.98, 0))
	for i = 1, 3 do
		local a = (i / 3) * math.pi * 2 + 0.35
		local legCf = baseCf
			* CFrame.new(math.cos(a) * 1.25, 2.0, math.sin(a) * 1.25)
			* CFrame.Angles(math.sin(a) * 0.32, 0, -math.cos(a) * 0.32)
		makeCylinderY(
			scope,
			"TripodLeg_" .. tostring(i),
			legCf,
			0.32,
			4.4,
			PALETTE.GoldDark,
			Enum.Material.Metal,
			false,
			0,
			true
		)
		makeEllipsoid(
			scope,
			"TripodFoot_" .. tostring(i),
			baseCf * CFrame.new(math.cos(a) * 1.95, 0.16, math.sin(a) * 1.95),
			Vector3.new(0.56, 0.32, 0.56),
			PALETTE.GoldMid,
			Enum.Material.Metal,
			false,
			0,
			false
		)
	end
	-- Tripod center brace ring + equatorial mount head
	makeNeonRing(
		scope,
		"TripodBrace",
		baseCf * CFrame.new(0, 1.5, 0),
		1.25,
		0.16,
		0.16,
		12,
		PALETTE.GoldDark,
		0
	)
	makeCylinderY(
		scope,
		"CenterShaft",
		baseCf * CFrame.new(0, 2.75, 0),
		0.44,
		2.5,
		PALETTE.GoldMid,
		Enum.Material.Metal,
		false,
		0,
		true
	)
	makeEllipsoid(
		scope,
		"EquatorialMount",
		baseCf * CFrame.new(0, 4.1, 0),
		Vector3.new(1.25, 1.15, 1.25),
		PALETTE.GoldBright,
		Enum.Material.Metal,
		false,
		0,
		true
	)

	-- Long ornate golden telescope tube aimed upward-right into the starry night
	local tubeCf = baseCf * CFrame.new(0, 4.9, 0) * CFrame.Angles(math.rad(-32), math.rad(-34), 0)
	local tubeAxis = tubeCf * CFrame.Angles(math.rad(90), 0, 0)
	makeCylinderY(
		scope,
		"Eyepiece",
		tubeAxis * CFrame.new(0, -3.55, 0),
		0.58,
		1.1,
		PALETTE.GoldDark,
		Enum.Material.Metal,
		false,
		0,
		false
	)
	makeCylinderY(
		scope,
		"TubeRear",
		tubeAxis * CFrame.new(0, -2.0, 0),
		1.02,
		2.4,
		PALETTE.GoldMid,
		Enum.Material.Metal,
		false,
		0,
		true
	)
	makeCylinderY(
		scope,
		"TubeMid",
		tubeAxis * CFrame.new(0, 0.4, 0),
		1.38,
		2.8,
		PALETTE.GoldBright,
		Enum.Material.Metal,
		false,
		0,
		true
	)
	makeCylinderY(
		scope,
		"TubeFront",
		tubeAxis * CFrame.new(0, 2.6, 0),
		1.76,
		2.0,
		PALETTE.GoldBright,
		Enum.Material.Metal,
		false,
		0,
		true
	)
	-- Brass collar rings along the barrel
	for idx, yRing in ipairs({ -0.8, 1.6, 3.55 }) do
		makeCylinderY(
			scope,
			"BrassRing_" .. tostring(idx),
			tubeAxis * CFrame.new(0, yRing, 0),
			(1.16 + idx * 0.24),
			0.24,
			PALETTE.GoldDark,
			Enum.Material.Metal,
			false,
			0,
			false
		)
	end
	-- Side finder scope
	makeCylinderY(
		scope,
		"FinderScope",
		tubeAxis * CFrame.new(0.85, 0.5, 0.4),
		0.34,
		2.4,
		PALETTE.GoldDark,
		Enum.Material.Metal,
		false,
		0,
		false
	)
	-- Luminous sapphire-cyan objective lens
	makeCylinderY(
		scope,
		"ObjectiveLens",
		tubeAxis * CFrame.new(0, 3.65, 0),
		1.54,
		0.16,
		PALETTE.CrystalCyan,
		Enum.Material.Neon,
		false,
		0.12,
		false
	)

	-- Ornate dark stone pillar topped with glowing cyan crystal right of Observatory (matches reference!)
	local lampBase = origin + Vector3.new(5.4, 0, -21.2)
	makeCylinderY(
		obs,
		"LampBase",
		CFrame.new(lampBase + Vector3.new(0, 0.45, 0)),
		1.9,
		0.9,
		PALETTE.StoneDark,
		Enum.Material.Concrete,
		false,
		0,
		true
	)
	makeCylinderY(
		obs,
		"LampShaft",
		CFrame.new(lampBase + Vector3.new(0, 3.9, 0)),
		1.05,
		6.4,
		PALETTE.StoneMid,
		Enum.Material.Concrete,
		false,
		0,
		true
	)
	makeCylinderY(
		obs,
		"LampCap",
		CFrame.new(lampBase + Vector3.new(0, 7.25, 0)),
		1.75,
		0.55,
		PALETTE.StoneLight,
		Enum.Material.Concrete,
		false,
		0,
		true
	)
	buildCrystalCluster(
		obs,
		"LampTopCrystal",
		CFrame.new(lampBase + Vector3.new(0, 7.45, 0)),
		0.72,
		3.2,
		PALETTE.CrystalCyan,
		PALETTE.CrystalCore,
		2,
		true,
		rng
	)
end

-- ============================================================================
-- 6. STARRY STONE PORTAL (BACK-RIGHT — DARK CARVED STONE, 3D RUNES, SPIRAL VORTEX)
-- ============================================================================

local function buildPortal(root: Model, origin: Vector3, rng: Random)
	local portalFolder = makeFolder(root, "StonePortal")
	local base = origin + PORTAL_POS
	local portalCf = CFrame.new(base) * CFrame.Angles(0, math.rad(PORTAL_YAW_DEG), 0)

	-- Semi-circular stepped dark stone base
	makeCylinderY(
		portalFolder,
		"PortalDaisBase",
		portalCf * CFrame.new(0, 0.32, 0.9),
		13.6,
		0.64,
		PALETTE.StoneDark,
		Enum.Material.Concrete,
		true,
		0,
		true
	)
	makeCylinderY(
		portalFolder,
		"PortalDaisTop",
		portalCf * CFrame.new(0, 0.84, 0.4),
		11.4,
		0.48,
		PALETTE.StoneMid,
		Enum.Material.Concrete,
		true,
		0,
		true
	)

	-- Dark carved stone pillars with deep mortar joints & 3D glowing cyan runes
	local leftRunes = { 1, 2, 3 }
	local rightRunes = { 4, 5, 6 }
	for side = -1, 1, 2 do
		-- Wide plinth block at pillar foot
		makePart(
			portalFolder,
			"Plinth_" .. tostring(side),
			portalCf * CFrame.new(side * 4.75, 1.4, 0),
			Vector3.new(3.4, 1.3, 3.6),
			PALETTE.StoneDark,
			Enum.Material.Concrete,
			false,
			0,
			true
		)
		for b = 1, 5 do
			local cf = portalCf
				* CFrame.new(side * 4.7, 2.35 + (b - 1) * 2.15, 0)
				* CFrame.Angles(0, rng:NextNumber(-0.04, 0.04), 0)
			makePart(
				portalFolder,
				"Pillar_" .. tostring(side) .. "_" .. tostring(b),
				cf,
				Vector3.new(2.95, 2.02, 3.2),
				jitterColor(PALETTE.StoneDark, rng, 0.04),
				Enum.Material.Concrete,
				false,
				0,
				true
			)
			-- Dark recessed stone mortar joint
			makePart(
				portalFolder,
				"Joint_" .. tostring(side) .. "_" .. tostring(b),
				cf * CFrame.new(0, -1.06, 0),
				Vector3.new(2.75, 0.14, 3.0),
				PALETTE.StoneJoint,
				Enum.Material.Concrete,
				false,
				0,
				false
			)
		end

		-- 3 crisp glowing 3D cyan rune glyphs down the front face of each pillar
		local rList = if side < 0 then leftRunes else rightRunes
		for rIdx, pat in ipairs(rList) do
			local yPos = 3.2 + (rIdx - 1) * 2.95
			addRuneGlyph(
				portalFolder,
				"PortalRune_" .. tostring(side) .. "_" .. tostring(rIdx),
				portalCf * CFrame.new(side * 4.7, yPos, 1.68),
				pat,
				0.56,
				0.72,
				0.14,
				PALETTE.RuneCyan
			)
		end

		-- Large rich crystal clusters flanking both feet of the portal (just like the reference!)
		buildCrystalCluster(
			portalFolder,
			"PortalFootCrystals_" .. tostring(side),
			portalCf
				* CFrame.new(side * 7.2, 0.25, 1.6)
				* CFrame.Angles(0, math.rad(side * -22), math.rad(side * -14)),
			1.25,
			5.4,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			4,
			true,
			rng
		)
	end

	-- Sculpted dark stone arch blocks + crown frame holding the diamond keystone crystal
	for i = 1, 9 do
		local t = (i - 1) / 8
		local angle = math.rad(170 - t * 160)
		local ax = math.cos(angle) * 5.25
		local ay = 11.4 + math.sin(angle) * 4.75
		local isKeystone = (i == 5)
		local cf = portalCf * CFrame.new(ax, ay, 0) * CFrame.Angles(0, 0, angle - math.rad(90))
		makePart(
			portalFolder,
			"Arch_" .. tostring(i),
			cf,
			if isKeystone then Vector3.new(3.5, 3.0, 3.6) else Vector3.new(2.55, 2.35, 3.25),
			jitterColor(if isKeystone then PALETTE.StoneMid else PALETTE.StoneDark, rng, 0.04),
			Enum.Material.Concrete,
			false,
			0,
			true
		)
		-- Shoulder runes on blocks 3 and 7
		if i == 3 or i == 7 then
			addRuneGlyph(
				portalFolder,
				"ArchRune_" .. tostring(i),
				cf * CFrame.new(0, 0, 1.70),
				i,
				0.42,
				0.52,
				0.12,
				PALETTE.RuneCyan
			)
		end
	end

	-- Large faceted diamond-blue keystone crystal mounted at the top of the arch
	buildHexShard(
		portalFolder,
		"PortalKeystoneCrystal",
		portalCf * CFrame.new(0, 15.2, 0.55),
		1.35,
		5.2,
		PALETTE.CrystalCyan,
		PALETTE.CrystalCore,
		true
	)

	-- Deep Starry Spiral Vortex Interior (dark cosmos backing + glowing cyan rim + 4 spiral arms + stars!)
	local vortexCenter = portalCf * CFrame.new(0, 8.1, 0.05)
	makeEllipsoid(
		portalFolder,
		"VortexBack",
		vortexCenter,
		Vector3.new(7.4, 12.2, 0.55),
		PALETTE.FocusBed,
		Enum.Material.SmoothPlastic,
		false,
		0.02,
		false
	)
	makeEllipsoid(
		portalFolder,
		"VortexDeepBlue",
		vortexCenter * CFrame.new(0, 0, 0.22),
		Vector3.new(6.8, 11.4, 0.25),
		PALETTE.CrystalDeep,
		Enum.Material.Neon,
		false,
		0.68,
		false
	)

	-- Bright luminous cyan oval rim framing the portal interior
	local rimPts = 32
	for i = 1, rimPts do
		local a1 = (i / rimPts) * math.pi * 2
		local a2 = ((i + 1) / rimPts) * math.pi * 2
		local p1 = (vortexCenter * CFrame.new(math.cos(a1) * 3.55, math.sin(a1) * 5.85, 0.36)).Position
		local p2 = (vortexCenter * CFrame.new(math.cos(a2) * 3.55, math.sin(a2) * 5.85, 0.36)).Position
		makeSegment(
			portalFolder,
			"VortexRim_" .. tostring(i),
			p1,
			p2,
			0.44,
			PALETTE.CrystalCyan,
			Enum.Material.Neon,
			false,
			0.08,
			false,
			true
		)
	end

	-- Rotating spiral vortex arms + embedded stars
	local vortexSpinner = makeModel(portalFolder, "VortexSpiral")
	vortexSpinner:SetAttribute("SpinSpeed", 0.9)
	local spinPivot = makePart(
		vortexSpinner,
		"Pivot",
		vortexCenter * CFrame.new(0, 0, 0.4),
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.CrystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	vortexSpinner.PrimaryPart = spinPivot

	for arm = 0, 3 do
		local baseAng = arm * (math.pi * 0.5)
		local prev = (vortexCenter * CFrame.new(0, 0, 0.42)).Position
		for step = 1, 12 do
			local t = step / 12
			local ang = baseAng + t * 3.6
			local rx = t * 3.15
			local ry = t * 5.15
			local pt = (vortexCenter * CFrame.new(math.cos(ang) * rx, math.sin(ang) * ry, 0.42)).Position
			local col = if t < 0.35
				then PALETTE.CrystalDeep
				elseif t < 0.72 then PALETTE.CrystalBlue
				else PALETTE.CrystalCyan
			makeSegment(
				vortexSpinner,
				"VortexArm_" .. tostring(arm) .. "_" .. tostring(step),
				prev,
				pt,
				0.34 * (0.4 + t * 0.75),
				col,
				Enum.Material.Neon,
				false,
				0.22 + (1 - t) * 0.35,
				false,
				true
			)
			prev = pt
		end
	end
	for s = 1, 24 do
		local a = rng:NextNumber(0, math.pi * 2)
		local rf = math.sqrt(rng:NextNumber(0.08, 0.92))
		makeEllipsoid(
			vortexSpinner,
			"VortexStar_" .. tostring(s),
			vortexCenter * CFrame.new(math.cos(a) * 3.1 * rf, math.sin(a) * 5.2 * rf, 0.46),
			Vector3.new(0.22, 0.22, 0.10),
			PALETTE.StarWhite,
			Enum.Material.Neon,
			false,
			0.05,
			false
		)
	end

	-- Contained portal glow light + rising stardust particles (does NOT wash out the dark stone!)
	local emitterPart = makePart(
		portalFolder,
		"VortexEmitter",
		vortexCenter * CFrame.new(0, 0, 0.5),
		Vector3.new(5.6, 9.2, 0.4),
		PALETTE.CrystalBlue,
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	emitterPart.CanQuery = false
	local pLight = Instance.new("PointLight")
	pLight.Color = PALETTE.CrystalBlue
	pLight.Brightness = 1.05
	pLight.Range = 14
	pLight.Parent = emitterPart

	local stars = Instance.new("ParticleEmitter")
	stars.Name = "PortalStardust"
	stars.Color = ColorSequence.new(PALETTE.StarWhite, PALETTE.CrystalCyan)
	stars.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.26),
		NumberSequenceKeypoint.new(1, 0),
	})
	stars.Lifetime = NumberRange.new(1.4, 2.5)
	stars.Rate = 10
	stars.Speed = NumberRange.new(0.6, 1.5)
	stars.LightEmission = 1
	stars.Parent = emitterPart
end

-- ============================================================================
-- 7. ARCHED STONE & WOOD BRIDGE, RUNE STONE PATHS & CURVED FRONT ROPE FENCE
-- ============================================================================

local function buildBridgeAndPaths(root: Model, origin: Vector3, rng: Random)
	local folder = makeFolder(root, "BridgeAndPaths")

	-- Helper: place organic dark polygonal stone path slabs with 3D Neon cyan runes
	local function placeRuneSlabTrail(points: { Vector3 }, tag: string)
		for i, pt in ipairs(points) do
			local cf = CFrame.new(pt + Vector3.new(0, 0.08, 0))
				* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			local szX = rng:NextNumber(2.3, 3.6)
			local szZ = rng:NextNumber(1.8, 2.9)
			makePart(
				folder,
				"RuneSlab_" .. tag .. "_" .. tostring(i),
				cf,
				Vector3.new(szX, 0.18, szZ),
				jitterColor(
					if i % 2 == 0 then PALETTE.StoneSlabA else PALETTE.StoneSlabB,
					rng,
					0.05
				),
				Enum.Material.Concrete,
				true,
				0,
				false
			)
			-- Small companion stepping stone beside larger slabs
			if i % 2 == 1 then
				makeEllipsoid(
					folder,
					"PathPebble_" .. tag .. "_" .. tostring(i),
					cf * CFrame.new(szX * 0.52, -0.02, rng:NextNumber(-0.7, 0.7)),
					Vector3.new(1.25, 0.20, 1.05),
					PALETTE.StoneSlabB,
					Enum.Material.Concrete,
					false,
					0,
					false
				)
			end
			-- Crisp 3D cyan rune glyph laid flat onto the top face of alternate slabs!
			if i % 2 == 0 or i == 1 then
				local topCf = cf * CFrame.new(0, 0.11, 0) * CFrame.Angles(math.rad(-90), 0, 0)
				addRuneGlyph(
					folder,
					"SlabRune_" .. tag .. "_" .. tostring(i),
					topCf,
					i,
					0.48,
					0.56,
					0.10,
					PALETTE.RuneCyan
				)
			end
		end
	end

	-- North rune path: Portal steps -> Bridge north entrance (plus spur toward Observatory)
	local northPath = {
		origin + Vector3.new(13.5, 0, -17.8),
		origin + Vector3.new(11.4, 0, -15.4),
		origin + Vector3.new(9.2, 0, -13.0),
		origin + Vector3.new(7.4, 0, -10.5),
		origin + Vector3.new(5.6, 0, -8.2),
		origin + Vector3.new(3.8, 0, -6.2),
		origin + Vector3.new(1.8, 0, -4.4),
		-- Spur curving left to Observatory steps
		origin + Vector3.new(4.8, 0, -13.5),
		origin + Vector3.new(2.2, 0, -15.6),
		origin + Vector3.new(-0.4, 0, -17.2),
	}
	placeRuneSlabTrail(northPath, "N")

	-- South rune path: Bridge south exit spreading into a stone courtyard in front of the fence
	local southPath = {
		origin + Vector3.new(-4.8, 0, 15.8),
		origin + Vector3.new(-6.6, 0, 18.2),
		origin + Vector3.new(-3.2, 0, 18.8),
		origin + Vector3.new(-8.2, 0, 21.0),
		origin + Vector3.new(-4.8, 0, 22.0),
		origin + Vector3.new(-10.2, 0, 23.6),
		origin + Vector3.new(-6.8, 0, 24.8),
		origin + Vector3.new(-3.0, 0, 24.4),
		origin + Vector3.new(-8.8, 0, 26.8),
	}
	placeRuneSlabTrail(southPath, "S")

	-- Central Arched Stone-Curbed Wooden Bridge (walkable smooth 5-segment ramp collider!)
	local bridgeCf = CFrame.new(origin + BRIDGE_POS) * CFrame.Angles(0, math.rad(BRIDGE_YAW_DEG), 0)
	local bridgeLen = 18.8
	local bridgeW = 7.4
	local archMaxY = 1.35

	local function archHeightAt(t: number): number
		return math.sin(t * math.pi) * archMaxY
	end

	-- Smooth invisible 5-ramp walkable collider (zero steps > 0.25 studs!)
	local rampCount = 5
	for r = 1, rampCount do
		local t0 = (r - 1) / rampCount
		local t1 = r / rampCount
		local z0 = (t0 - 0.5) * bridgeLen
		local z1 = (t1 - 0.5) * bridgeLen
		local y0 = archHeightAt(t0)
		local y1 = archHeightAt(t1)
		local p0 = (bridgeCf * CFrame.new(0, y0, z0)).Position
		local p1 = (bridgeCf * CFrame.new(0, y1, z1)).Position
		local segLen = (p1 - p0).Magnitude + 0.35
		local segCf = CFrame.lookAt((p0 + p1) * 0.5, p1)
		makePart(
			folder,
			if r == 3 then "BridgeCollider" else "BridgeCollider_" .. tostring(r),
			segCf * CFrame.new(0, -0.18, 0),
			Vector3.new(bridgeW, 0.42, segLen),
			PALETTE.WoodPlank1,
			Enum.Material.WoodPlanks,
			true,
			1,
			false
		)
	end

	-- 18 varied dark wooden planks following the bridge arch & slope
	local plankCount = 18
	local plankTones = { PALETTE.WoodPlank1, PALETTE.WoodPlank2, PALETTE.WoodPlank3 }
	for i = 1, plankCount do
		local t = (i - 0.5) / plankCount
		local z = (t - 0.5) * bridgeLen
		local y = archHeightAt(t)
		local slope = math.cos(t * math.pi) * math.pi * (archMaxY / bridgeLen)
		local pitch = math.atan(slope)
		makePart(
			folder,
			"BridgePlank_" .. tostring(i),
			bridgeCf * CFrame.new(0, y + 0.08, z) * CFrame.Angles(-pitch, 0, 0),
			Vector3.new(bridgeW - 0.7, 0.28, (bridgeLen / plankCount) * 0.84),
			plankTones[((i - 1) % #plankTones) + 1],
			Enum.Material.WoodPlanks,
			false,
			0,
			true
		)
	end

	-- Sculpted arched dark stone side curbs along both edges of the bridge (matches reference!)
	local curbSegs = 10
	local bridgeEndPosts: { [number]: { Vector3 } } = { [-1] = {}, [1] = {} }
	for side = -1, 1, 2 do
		for c = 1, curbSegs do
			local t0 = (c - 1) / curbSegs
			local t1 = c / curbSegs
			local tMid = (t0 + t1) * 0.5
			local z = (tMid - 0.5) * bridgeLen
			local y = archHeightAt(tMid)
			local slope = math.cos(tMid * math.pi) * math.pi * (archMaxY / bridgeLen)
			local pitch = math.atan(slope)
			makePart(
				folder,
				"StoneCurb_" .. tostring(side) .. "_" .. tostring(c),
				bridgeCf
					* CFrame.new(side * (bridgeW * 0.5 - 0.25), y - 0.12, z)
					* CFrame.Angles(-pitch, 0, 0),
				Vector3.new(0.82, 1.05, (bridgeLen / curbSegs) + 0.18),
				jitterColor(PALETTE.StoneDark, rng, 0.04),
				Enum.Material.Concrete,
				false,
				0,
				true
			)
		end

		-- 5 arched railing posts + sagging catenary ropes + rope coils
		local posts: { Vector3 } = {}
		for p = 0, 4 do
			local t = p / 4
			local z = (t - 0.5) * bridgeLen
			local y = archHeightAt(t)
			local pCf = bridgeCf * CFrame.new(side * (bridgeW * 0.5 - 0.22), y, z)
			makeCylinderY(
				folder,
				"BridgePost_" .. tostring(side) .. "_" .. tostring(p),
				pCf * CFrame.new(0, 1.55, 0),
				0.64,
				3.4,
				PALETTE.WoodDark,
				Enum.Material.Wood,
				false,
				0,
				true
			)
			makeEllipsoid(
				folder,
				"PostCap_" .. tostring(side) .. "_" .. tostring(p),
				pCf * CFrame.new(0, 3.28, 0),
				Vector3.new(0.72, 0.30, 0.72),
				PALETTE.WoodPlank3,
				Enum.Material.Wood,
				false,
				0,
				false
			)
			local ropeAttach = (pCf * CFrame.new(0, 2.55, 0)).Position
			addRopeCoil(
				folder,
				"BridgeCoil_" .. tostring(side) .. "_" .. tostring(p),
				ropeAttach,
				0.64,
				2
			)
			table.insert(posts, ropeAttach)
		end
		bridgeEndPosts[side] = posts
		for p = 1, #posts - 1 do
			makeRope(
				folder,
				"BridgeRope_" .. tostring(side) .. "_" .. tostring(p),
				posts[p],
				posts[p + 1],
				0.48,
				6,
				0.20,
				PALETTE.Rope
			)
		end
	end

	-- Flanking wing ropes curving outward from the south end of the bridge toward the two ponds
	local leftWingPost = origin + Vector3.new(-14.5, 0, 16.5)
	makeCylinderY(
		folder,
		"WingPostL",
		CFrame.new(leftWingPost + Vector3.new(0, 1.45, 0)),
		0.60,
		3.0,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		true
	)
	makeRope(
		folder,
		"WingRopeL",
		bridgeEndPosts[-1][5],
		leftWingPost + Vector3.new(0, 2.35, 0),
		0.75,
		7,
		0.20,
		PALETTE.Rope
	)

	local rightWingPost = origin + Vector3.new(5.5, 0, 18.8)
	makeCylinderY(
		folder,
		"WingPostR",
		CFrame.new(rightWingPost + Vector3.new(0, 1.45, 0)),
		0.60,
		3.0,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0,
		true
	)
	makeRope(
		folder,
		"WingRopeR",
		bridgeEndPosts[1][5],
		rightWingPost + Vector3.new(0, 2.35, 0),
		0.72,
		7,
		0.20,
		PALETTE.Rope
	)

	-- Curved foreground rope fence framing the front cliff rim (matches reference!)
	local frontFencePts = {
		origin + Vector3.new(-15.5, 0, 29.8),
		origin + Vector3.new(-9.6, 0, 32.8),
		origin + Vector3.new(-3.0, 0, 34.4),
		origin + Vector3.new(3.8, 0, 34.2),
		origin + Vector3.new(10.4, 0, 32.6),
		origin + Vector3.new(16.4, 0, 29.8),
	}
	for i, fp in ipairs(frontFencePts) do
		makeCylinderY(
			folder,
			"FrontFencePost_" .. tostring(i),
			CFrame.new(fp + Vector3.new(0, 1.45, 0)),
			0.58,
			3.0,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0,
			true
		)
		local attach = fp + Vector3.new(0, 2.35, 0)
		addRopeCoil(folder, "FrontCoil_" .. tostring(i), attach, 0.58, 2)
		if i > 1 then
			makeRope(
				folder,
				"FrontFenceRope_" .. tostring(i),
				frontFencePts[i - 1] + Vector3.new(0, 2.35, 0),
				attach,
				0.52,
				6,
				0.19,
				PALETTE.Rope
			)
		end
	end

	-- 2 Ornate carved wooden fish signs matching the exact reference locations
	buildOrnateFishSign(
		folder,
		"SignFocus",
		CFrame.new(origin + Vector3.new(-14.8, 0, -21.8)) * CFrame.Angles(0, math.rad(16), 0)
	)
	buildOrnateFishSign(
		folder,
		"SignInstinct",
		CFrame.new(origin + Vector3.new(19.2, 0, -10.8)) * CFrame.Angles(0, math.rad(-12), 0)
	)
end

-- ============================================================================
-- 8. ABYSS PROPS (LANTERNS, FIREFLIES, GRASS TUFTS, PEBBLES, CRYSTAL SHARDS, MOON)
-- ============================================================================

local function buildProps(root: Model, origin: Vector3, rng: Random)
	local propFolder = makeFolder(root, "AbyssProps")

	-- 5 Detailed Warm Amber Lanterns around the crystal tree & monoliths
	local lanternPositions = {
		{ pos = origin + Vector3.new(28.5, 0, -15.8), light = true },
		{ pos = origin + Vector3.new(31.2, 0, -12.6), light = false },
		{ pos = origin + Vector3.new(39.4, 0, -9.2), light = true },
		{ pos = origin + Vector3.new(38.6, 0, 0.5), light = false },
		{ pos = origin + Vector3.new(37.5, 0, 11.2), light = false },
	}
	for i, lp in ipairs(lanternPositions) do
		buildAmberLantern(propFolder, "AmberLantern_" .. tostring(i), lp.pos, lp.light)
	end

	-- Floating golden fireflies with soft halos (clearly visible even in static renders!)
	local fireflySpots = {
		Vector3.new(25.5, 2.4, -14.5),
		Vector3.new(30.0, 3.2, -16.8),
		Vector3.new(33.4, 4.6, -9.4),
		Vector3.new(38.2, 2.8, -6.6),
		Vector3.new(41.8, 3.6, -1.2),
		Vector3.new(43.2, 2.6, 3.4),
		Vector3.new(39.6, 2.2, 8.8),
		Vector3.new(36.4, 3.4, 13.4),
		Vector3.new(29.8, 2.5, -8.5),
		Vector3.new(34.8, 5.8, -15.6),
		Vector3.new(22.4, 2.8, -13.2),
		Vector3.new(42.5, 4.4, -7.8),
	}
	for i, off in ipairs(fireflySpots) do
		local pos = origin + off
		makeEllipsoid(
			propFolder,
			"FireflyCore_" .. tostring(i),
			CFrame.new(pos),
			Vector3.new(0.28, 0.28, 0.28),
			PALETTE.AmberCore,
			Enum.Material.Neon,
			false,
			0,
			false
		)
		makeEllipsoid(
			propFolder,
			"FireflyHalo_" .. tostring(i),
			CFrame.new(pos),
			Vector3.new(0.75, 0.75, 0.75),
			PALETTE.FireflyGold,
			Enum.Material.Neon,
			false,
			0.68,
			false
		)
	end

	-- Small glowing starlight blossoms/clusters near observatory, bridge & path edges
	local starBlossomSpots = {
		Vector3.new(-0.8, 0.22, -11.5),
		Vector3.new(-2.4, 0.22, -10.2),
		Vector3.new(-1.5, 0.22, -9.2),
		Vector3.new(9.5, 0.22, -5.8),
		Vector3.new(10.8, 0.22, -4.6),
		Vector3.new(-11.2, 0.22, 26.5),
		Vector3.new(13.8, 0.22, 27.2),
	}
	for i, off in ipairs(starBlossomSpots) do
		local pos = origin + off
		makeEllipsoid(
			propFolder,
			"StarSparkle_" .. tostring(i),
			CFrame.new(pos),
			Vector3.new(0.42, 0.22, 0.42),
			PALETTE.RuneCyan,
			Enum.Material.Neon,
			false,
			0.14,
			false
		)
	end

	-- 95 Lush midnight-blue 3D grass tufts & scattered flat dark stones across the island top
	for i = 1, 95 do
		local a = rng:NextNumber(0, math.pi * 2)
		local rx, rz = getIslandRadiiAt(a)
		local frac = math.sqrt(rng:NextNumber(0.10, 0.94))
		local x = math.cos(a) * rx * frac
		local z = math.sin(a) * rz * frac

		local clearFocus = not isInsideEllipse(x, z, FOCUS_CENTER, FOCUS_RX, FOCUS_RZ, 1.9)
		local clearInstinct =
			not isInsideEllipse(x, z, INSTINCT_CENTER, INSTINCT_RX, INSTINCT_RZ, 1.9)
		local clearObs = (Vector2.new(x, z) - Vector2.new(OBS_POS.X, OBS_POS.Z)).Magnitude > 9.5
		local clearPortal = (Vector2.new(x, z) - Vector2.new(PORTAL_POS.X, PORTAL_POS.Z)).Magnitude
			> 8.5
		local clearBridge = math.abs(x - BRIDGE_POS.X) > 6.5 or math.abs(z - BRIDGE_POS.Z) > 10.5

		if clearFocus and clearInstinct and clearObs and clearPortal and clearBridge then
			local basePos = origin + Vector3.new(x, 0.0, z)
			local tCol = if i % 2 == 0 then PALETTE.GrassTuftA else PALETTE.GrassTuftB
			for b = 1, 3 do
				local yaw = rng:NextNumber(0, math.pi * 2)
				local tilt = math.rad(rng:NextNumber(14, 30))
				local h = rng:NextNumber(0.55, 1.15)
				makeWedge(
					propFolder,
					"GrassBlade_" .. tostring(i) .. "_" .. tostring(b),
					CFrame.new(
						basePos
							+ Vector3.new(
								rng:NextNumber(-0.26, 0.26),
								h * 0.42,
								rng:NextNumber(-0.26, 0.26)
							)
					)
						* CFrame.Angles(0, yaw, 0)
						* CFrame.Angles(tilt, 0, 0),
					Vector3.new(0.18, h, 0.42),
					tCol,
					Enum.Material.SmoothPlastic,
					false,
					0,
					false
				)
			end
			if i % 6 == 0 then
				makeEllipsoid(
					propFolder,
					"GroundStone_" .. tostring(i),
					CFrame.new(basePos + Vector3.new(0.5, 0.14, -0.3))
						* CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
					Vector3.new(rng:NextNumber(0.9, 1.7), 0.34, rng:NextNumber(0.7, 1.4)),
					PALETTE.StoneDark,
					Enum.Material.Concrete,
					false,
					0,
					false
				)
			end
		end
	end

	-- Lightweight celestial Full Moon cleanly inside upper-right sky of CameraShot
	local moonPos = origin + Vector3.new(47.0, 40.5, -96.0)
	makeEllipsoid(
		propFolder,
		"AbyssFullMoon",
		CFrame.new(moonPos),
		Vector3.new(16.5, 16.5, 16.5),
		PALETTE.MoonCream,
		Enum.Material.Neon,
		false,
		0.04,
		false
	)
	makeEllipsoid(
		propFolder,
		"AbyssMoonHalo",
		CFrame.new(moonPos),
		Vector3.new(22.5, 22.5, 22.5),
		PALETTE.StarWhite,
		Enum.Material.Neon,
		false,
		0.90,
		false
	)
	-- Subtle moon craters facing camera (+Z, -X)
	local craters = {
		{ off = Vector3.new(-2.6, 2.0, 7.6), sz = Vector3.new(3.6, 3.3, 1.1) },
		{ off = Vector3.new(2.3, -1.6, 7.7), sz = Vector3.new(4.3, 3.8, 1.1) },
		{ off = Vector3.new(-0.8, -3.7, 7.3), sz = Vector3.new(2.6, 2.3, 1.0) },
	}
	for idx, cr in ipairs(craters) do
		makeEllipsoid(
			propFolder,
			"MoonCrater_" .. tostring(idx),
			CFrame.new(moonPos + cr.off),
			cr.sz,
			PALETTE.MoonCrater,
			Enum.Material.SmoothPlastic,
			false,
			0.55,
			false
		)
	end
end

-- ============================================================================
-- 9. SERVER CONTRACT PARTS (EXACT NAMES, TAGS & ATTRIBUTES)
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
	root.PrimaryPart = center

	-- ArrivalSpawn (in front of portal on the rune path, facing island center)
	local arrival = makePart(
		root,
		"ArrivalSpawn",
		CFrame.lookAt(origin + Vector3.new(13.2, 0.5, -16.8), origin + Vector3.new(0, 0.5, 0)),
		Vector3.new(4, 1, 4),
		Color3.new(0, 1, 0),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	CollectionService:AddTag(arrival, "ZoneSpawn")
	arrival:SetAttribute("Destination", "training_abyss")

	-- ReturnPortal (inside stone portal arch)
	local portalCf = CFrame.new(origin + PORTAL_POS + Vector3.new(0, 5.4, 0))
		* CFrame.Angles(0, math.rad(PORTAL_YAW_DEG), 0)
	local portal = makePart(
		root,
		"ReturnPortal",
		portalCf,
		Vector3.new(6.2, 8.6, 2.8),
		Color3.new(0, 1, 1),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	portal.CanTouch = true
	portal.CanQuery = true
	CollectionService:AddTag(portal, "ZonePortal")
	portal:SetAttribute("PortalId", "training_abyss_to_main")
	portal:SetAttribute("ZoneId", "lagoon")
	portal:SetAttribute("Destination", "main")

	-- FocusSpot (over Focus deck near stool)
	local focusSpot = makePart(
		root,
		"FocusSpot",
		CFrame.new(origin + FOCUS_DECK_POS + Vector3.new(0, 1.45, 0)),
		Vector3.new(5.5, 2, 5.5),
		Color3.new(0, 0.8, 1),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	CollectionService:AddTag(focusSpot, "TrainingSpot")
	focusSpot:SetAttribute("TrainingIsland", 3)
	focusSpot:SetAttribute("TrainingStat", "Control")

	-- InstinctSpot (over Instinct deck near stool)
	local instinctSpot = makePart(
		root,
		"InstinctSpot",
		CFrame.new(origin + INSTINCT_DECK_POS + Vector3.new(0, 1.45, 0)),
		Vector3.new(5.5, 2, 5.5),
		Color3.new(0.8, 0.3, 1),
		Enum.Material.SmoothPlastic,
		false,
		1,
		false
	)
	CollectionService:AddTag(instinctSpot, "TrainingSpot")
	instinctSpot:SetAttribute("TrainingIsland", 3)
	instinctSpot:SetAttribute("TrainingStat", "Instinct")

	-- CameraShot (matches reference angle: origin + (0, 48, 100) looking at origin, FOV 55)
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
	camShot:SetAttribute("FieldOfView", 55)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function Builder.build(origin: Vector3?): Model
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

	buildTopTerrain(root, baseOrigin, rng)
	task.wait()
	buildCliffAndWaterfalls(root, baseOrigin, rng)
	task.wait()
	buildObservatory(root, baseOrigin, rng)
	buildPortal(root, baseOrigin, rng)
	buildBridgeAndPaths(root, baseOrigin, rng)
	task.wait()
	buildFocusPond(root, baseOrigin, rng)
	buildInstinctPond(root, baseOrigin, rng)
	task.wait()
	buildProps(root, baseOrigin, rng)
	buildContractParts(root, baseOrigin)

	local parts = 0
	local lights = 0
	local emitters = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		elseif d:IsA("PointLight") or d:IsA("SpotLight") then
			lights += 1
		elseif d:IsA("ParticleEmitter") then
			emitters += 1
		end
	end
	print(
		string.format(
			"[TrainingIsland3Builder] Built %s: %d BaseParts, %d Lights, %d ParticleEmitters.",
			ISLAND_NAME,
			parts,
			lights,
			emitters
		)
	)
	return root
end

function Builder.selfTest(origin: Vector3?): { string }
	local baseOrigin = origin or DEFAULT_ORIGIN
	local failures: { string } = {}
	local folder = Workspace:FindFirstChild(FOLDER_NAME)
	local root = if folder then folder:FindFirstChild(ISLAND_NAME) else nil
	if not root or not root:IsA("Model") then
		table.insert(failures, "Model TrainingIsland_Abyss not found in Workspace.TrainingIslands")
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
	local focusPond = checkChild("FocusPond", "Model")
	local instinctPond = checkChild("InstinctPond", "Model")

	if root.PrimaryPart ~= center then
		table.insert(failures, "PrimaryPart is not IslandCenter")
	end

	-- ArrivalSpawn contract + ground check
	if arrival and arrival:IsA("BasePart") then
		if not CollectionService:HasTag(arrival, "ZoneSpawn") then
			table.insert(failures, "ArrivalSpawn missing tag ZoneSpawn")
		end
		if arrival:GetAttribute("Destination") ~= "training_abyss" then
			table.insert(failures, "ArrivalSpawn Destination ~= 'training_abyss'")
		end
		local rcParams = RaycastParams.new()
		rcParams.FilterType = Enum.RaycastFilterType.Exclude
		rcParams.FilterDescendantsInstances = { arrival }
		local hit = Workspace:Raycast(
			arrival.Position + Vector3.new(0, 2, 0),
			Vector3.new(0, -8, 0),
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
			portal:GetAttribute("PortalId") ~= "training_abyss_to_main"
			or portal:GetAttribute("ZoneId") ~= "lagoon"
			or portal:GetAttribute("Destination") ~= "main"
		then
			table.insert(failures, "ReturnPortal attributes mismatch")
		end
		if not portal.CanTouch or not portal.CanQuery then
			table.insert(failures, "ReturnPortal requires CanTouch=true and CanQuery=true")
		end
	end

	local function checkSpot(spot: Instance?, expectedStat: string, stoolName: string)
		if not spot or not spot:IsA("BasePart") then
			return
		end
		if not CollectionService:HasTag(spot, "TrainingSpot") then
			table.insert(failures, spot.Name .. " missing tag TrainingSpot")
		end
		local ti = spot:GetAttribute("TrainingIsland")
		if type(ti) ~= "number" or ti ~= 3 then
			table.insert(failures, spot.Name .. " TrainingIsland must be number 3")
		end
		if spot:GetAttribute("TrainingStat") ~= expectedStat then
			table.insert(failures, spot.Name .. " TrainingStat ~= " .. expectedStat)
		end
		local stool = root:FindFirstChild(stoolName, true)
		if stool and stool:IsA("Model") and stool.PrimaryPart then
			local d = (spot.Position - stool.PrimaryPart.Position).Magnitude
			if d > 16 then
				table.insert(
					failures,
					string.format("%s is %.1f studs from %s (>16)", spot.Name, d, stoolName)
				)
			end
		else
			table.insert(failures, "Missing stool model " .. stoolName)
		end
	end
	checkSpot(focusSpot, "Control", "FocusStool")
	checkSpot(instinctSpot, "Instinct", "InstinctStool")

	if camShot and camShot:GetAttribute("FieldOfView") ~= 55 then
		table.insert(failures, "CameraShot FieldOfView ~= 55")
	end

	-- Both pond surfaces must be unobstructed when raycasted straight down from above
	local rcPond = RaycastParams.new()
	rcPond.FilterType = Enum.RaycastFilterType.Include
	rcPond.FilterDescendantsInstances = { root }
	local pondChecks = {
		{ model = focusPond, offset = Vector3.new(FOCUS_CENTER.X, 0, FOCUS_CENTER.Y) },
		{ model = instinctPond, offset = Vector3.new(INSTINCT_CENTER.X, 0, INSTINCT_CENTER.Y) },
	}
	for _, pc in ipairs(pondChecks) do
		if pc.model then
			local water = pc.model:FindFirstChild("WaterSurface")
			if not water or not water:IsA("BasePart") then
				table.insert(failures, pc.model.Name .. " missing WaterSurface")
			else
				local hit = Workspace:Raycast(
					baseOrigin + pc.offset + Vector3.new(0, 1.5, 0),
					Vector3.new(0, -6, 0),
					rcPond
				)
				if not hit or not hit.Instance:IsDescendantOf(pc.model) then
					table.insert(
						failures,
						string.format(
							"%s water obstructed from above by %s",
							pc.model.Name,
							if hit then hit.Instance.Name else "nothing"
						)
					)
				end
			end
		end
	end

	-- Cosmic fish Orbit attributes check
	if instinctPond then
		for _, fishName in ipairs({ "CosmicFish_Gold", "CosmicFish_Rainbow", "CosmicFish_Nebula" }) do
			local fm = instinctPond:FindFirstChild(fishName)
			if
				not fm
				or type(fm:GetAttribute("OrbitRadius")) ~= "number"
				or type(fm:GetAttribute("OrbitSpeed")) ~= "number"
				or type(fm:GetAttribute("OrbitPhase")) ~= "number"
			then
				table.insert(failures, fishName .. " missing Orbit attributes")
			end
		end
	end

	-- Waterfalls connected cleanly near the cliff rim
	for _, wfSpec in ipairs({
		{ name = "LightWaterfall_Left", ang = WATERFALL_LEFT_ANG },
		{ name = "LightWaterfall_Right", ang = WATERFALL_RIGHT_ANG },
	}) do
		local wf = root:FindFirstChild(wfSpec.name, true)
		local crest = if wf then wf:FindFirstChild("SpoutCrest") else nil
		if not crest or not crest:IsA("BasePart") then
			table.insert(failures, wfSpec.name .. " missing SpoutCrest")
		else
			local expectedRim = getIslandRimPoint(baseOrigin, wfSpec.ang, 1.0)
			local dist = (Vector3.new(crest.Position.X, 0, crest.Position.Z) - Vector3.new(
				expectedRim.X,
				0,
				expectedRim.Z
			)).Magnitude
			if dist > 4.5 then
				table.insert(
					failures,
					string.format("%s SpoutCrest %.1f studs away from cliff rim", wfSpec.name, dist)
				)
			end
		end
	end

	-- Walkable collision on bridge & decks
	for _, name in ipairs({ "BridgeCollider", "FocusDeck", "InstinctDeck" }) do
		local p = root:FindFirstChild(name, true)
		if not p or not p:IsA("BasePart") or not p.CanCollide then
			table.insert(failures, "Walkable part missing or CanCollide=false: " .. name)
		end
	end

	-- No forbidden instances and no collidable decorations
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") or d:IsA("Seat") then
			table.insert(failures, "Forbidden instance found: " .. d:GetFullName())
		end
	end
	for _, fname in ipairs({ "CliffDecor", "AbyssProps" }) do
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

	-- Path clearance check from ArrivalSpawn to Portal, Bridge, FocusSpot & InstinctSpot
	if arrival and arrival:IsA("BasePart") then
		local ovParams = OverlapParams.new()
		ovParams.FilterType = Enum.RaycastFilterType.Include
		ovParams.FilterDescendantsInstances = { root }
		local bridgeMid = baseOrigin + BRIDGE_POS + Vector3.new(0, 1.4, 0)
		local waypoints = {
			{
				name = "ReturnPortal",
				pos = if portal and portal:IsA("BasePart") then portal.Position else baseOrigin,
			},
			{ name = "BridgeMid", pos = bridgeMid },
			{
				name = "FocusSpot",
				pos = if focusSpot and focusSpot:IsA("BasePart")
					then focusSpot.Position
					else baseOrigin,
			},
			{
				name = "InstinctSpot",
				pos = if instinctSpot and instinctSpot:IsA("BasePart")
					then instinctSpot.Position
					else baseOrigin,
			},
		}
		for _, wp in ipairs(waypoints) do
			local mid = arrival.Position:Lerp(wp.pos, 0.5) + Vector3.new(0, 3.6, 0)
			local blocked =
				Workspace:GetPartBoundsInBox(CFrame.new(mid), Vector3.new(2.2, 2.8, 2.2), ovParams)
			for _, b in ipairs(blocked) do
				if b.CanCollide then
					table.insert(
						failures,
						string.format("Path from ArrivalSpawn to %s blocked by %s", wp.name, b.Name)
					)
					break
				end
			end
		end
	end

	return failures
end

-- ============================================================================
-- OPTIONAL NIGHT REFERENCE LIGHTING (ONLY FOR PRINTS — NEVER CALLED BY build())
-- Saves state onto Lighting so applyReferenceLighting/restoreLighting work across :Clone() calls!
-- ============================================================================

function Builder.applyReferenceLighting()
	local saved = Lighting:FindFirstChild(SAVED_STATE_NAME)
	if not saved then
		local cfg = Instance.new("Configuration")
		cfg.Name = SAVED_STATE_NAME
		cfg:SetAttribute("ClockTime", Lighting.ClockTime)
		cfg:SetAttribute("GeographicLatitude", Lighting.GeographicLatitude)
		cfg:SetAttribute("Brightness", Lighting.Brightness)
		cfg:SetAttribute("Ambient", Lighting.Ambient)
		cfg:SetAttribute("OutdoorAmbient", Lighting.OutdoorAmbient)
		cfg:SetAttribute("EnvironmentDiffuseScale", Lighting.EnvironmentDiffuseScale)
		cfg:SetAttribute("EnvironmentSpecularScale", Lighting.EnvironmentSpecularScale)
		cfg:SetAttribute("FogColor", Lighting.FogColor)
		cfg:SetAttribute("FogEnd", Lighting.FogEnd)
		cfg:SetAttribute("FogStart", Lighting.FogStart)
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmo then
			cfg:SetAttribute("HasAtmo", true)
			cfg:SetAttribute("AtmoDensity", atmo.Density)
			cfg:SetAttribute("AtmoOffset", atmo.Offset)
			cfg:SetAttribute("AtmoColor", atmo.Color)
			cfg:SetAttribute("AtmoDecay", atmo.Decay)
			cfg:SetAttribute("AtmoHaze", atmo.Haze)
		end
		cfg.Parent = Lighting
	end

	Lighting.ClockTime = 22.8
	Lighting.GeographicLatitude = 24
	Lighting.Brightness = 1.95
	Lighting.Ambient = Color3.fromRGB(82, 94, 148)
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 126, 184)
	Lighting.EnvironmentDiffuseScale = 0.72
	Lighting.EnvironmentSpecularScale = 0.56

	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmo.Density = 0.28
		atmo.Offset = 0.12
		atmo.Color = Color3.fromRGB(32, 46, 94)
		atmo.Decay = Color3.fromRGB(16, 22, 54)
		atmo.Haze = 0.75
	end

	local bloom = Lighting:FindFirstChild("AbyssRefPreview_Bloom") :: BloomEffect?
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "AbyssRefPreview_Bloom"
		bloom.Parent = Lighting
	end
	if bloom then
		bloom.Intensity = 0.44
		bloom.Size = 22
		bloom.Threshold = 1.04
	end

	local cc = Lighting:FindFirstChild("AbyssRefPreview_ColorCorrection") :: ColorCorrectionEffect?
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "AbyssRefPreview_ColorCorrection"
		cc.Parent = Lighting
	end
	if cc then
		cc.TintColor = Color3.fromRGB(232, 238, 255)
		cc.Saturation = 0.16
		cc.Contrast = 0.08
		cc.Brightness = 0.03
	end
end

function Builder.restoreLighting()
	local saved = Lighting:FindFirstChild(SAVED_STATE_NAME)
	if saved then
		local ct = saved:GetAttribute("ClockTime")
		if type(ct) == "number" then
			Lighting.ClockTime = ct
		end
		local gl = saved:GetAttribute("GeographicLatitude")
		if type(gl) == "number" then
			Lighting.GeographicLatitude = gl
		end
		local br = saved:GetAttribute("Brightness")
		if type(br) == "number" then
			Lighting.Brightness = br
		end
		local amb = saved:GetAttribute("Ambient")
		if typeof(amb) == "Color3" then
			Lighting.Ambient = amb
		end
		local oamb = saved:GetAttribute("OutdoorAmbient")
		if typeof(oamb) == "Color3" then
			Lighting.OutdoorAmbient = oamb
		end
		local eds = saved:GetAttribute("EnvironmentDiffuseScale")
		if type(eds) == "number" then
			Lighting.EnvironmentDiffuseScale = eds
		end
		local ess = saved:GetAttribute("EnvironmentSpecularScale")
		if type(ess) == "number" then
			Lighting.EnvironmentSpecularScale = ess
		end
		local fc = saved:GetAttribute("FogColor")
		if typeof(fc) == "Color3" then
			Lighting.FogColor = fc
		end
		local fe = saved:GetAttribute("FogEnd")
		if type(fe) == "number" then
			Lighting.FogEnd = fe
		end
		local fs = saved:GetAttribute("FogStart")
		if type(fs) == "number" then
			Lighting.FogStart = fs
		end
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmo and saved:GetAttribute("HasAtmo") == true then
			local ad = saved:GetAttribute("AtmoDensity")
			if type(ad) == "number" then
				atmo.Density = ad
			end
			local ao = saved:GetAttribute("AtmoOffset")
			if type(ao) == "number" then
				atmo.Offset = ao
			end
			local ac = saved:GetAttribute("AtmoColor")
			if typeof(ac) == "Color3" then
				atmo.Color = ac
			end
			local adec = saved:GetAttribute("AtmoDecay")
			if typeof(adec) == "Color3" then
				atmo.Decay = adec
			end
			local ah = saved:GetAttribute("AtmoHaze")
			if type(ah) == "number" then
				atmo.Haze = ah
			end
		end
		saved:Destroy()
	end

	for _, name in ipairs({ "AbyssRefPreview_Bloom", "AbyssRefPreview_ColorCorrection" }) do
		local inst = Lighting:FindFirstChild(name)
		if inst then
			inst:Destroy()
		end
	end
end

return Builder
