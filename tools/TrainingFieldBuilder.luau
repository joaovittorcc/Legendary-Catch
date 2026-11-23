--!strict
-- TrainingFieldBuilder.luau
-- Builds the 10 visual Training Field levels inside ReplicatedStorage.TrainingLevels.Levels
-- (training_lv01 .. training_lv10). Follows Legendary Catch art direction & fwjelaa vault rules:
--   * Idempotent: rebuilds cleanly from scratch (GeneratedBy = "TrainingFieldBuilder")
--   * Shared TrainingOrigin pivot across all 10 levels (aligned to hub TrainingSpot)
--   * Local frame: +Z = open player approach, -Z = scenic focal backdrop, +Y = up
--   * Zero scripts, zero CollectionService tags, collision ONLY on walkable Layer_00_Floor
--   * Strict per-level mobile budgets (parts, lights, particle emitters)
--   * SmoothPlastic water/aurora/rays (never Enum.Material.Glass which hides particles/beams)
--   * Non-coplanar stacked surfaces (>= 0.05 stud offset), verified with tools/ZFightFixer.luau

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TAG_BUILT = "TrainingFieldBuilder"

-- Exact measured hub TrainingSpot deck top (Workspace.Island.TrainingLagoon.TrainingDeckOverhaul.DeckCollider = 10.61; +0.04 clears coplanar faces).
local HUB_DECK_Y = 10.65
local DEFAULT_ORIGIN = CFrame.lookAt(
	Vector3.new(-30, HUB_DECK_Y, -6),
	Vector3.new(-30, HUB_DECK_Y, -6) - Vector3.new(24, 0, 10).Unit
)

local PALETTE = {
	grass = Color3.fromRGB(96, 178, 86),
	grassLight = Color3.fromRGB(122, 202, 102),
	grassDark = Color3.fromRGB(72, 146, 68),
	woodWarm = Color3.fromRGB(154, 104, 62),
	woodLight = Color3.fromRGB(182, 130, 82),
	woodDark = Color3.fromRGB(96, 62, 38),
	rope = Color3.fromRGB(214, 186, 132),
	iron = Color3.fromRGB(72, 80, 92),
	stoneLight = Color3.fromRGB(194, 202, 212),
	stoneMid = Color3.fromRGB(142, 152, 166),
	stoneDark = Color3.fromRGB(82, 92, 110),
	basalt = Color3.fromRGB(52, 58, 76),
	marble = Color3.fromRGB(242, 240, 246),
	slateRoof = Color3.fromRGB(64, 126, 198),
	slateRoofDark = Color3.fromRGB(46, 92, 158),
	cyan = Color3.fromRGB(82, 228, 255),
	cyanDeep = Color3.fromRGB(44, 156, 224),
	pink = Color3.fromRGB(255, 118, 196),
	lilac = Color3.fromRGB(184, 124, 255),
	purple = Color3.fromRGB(142, 86, 232),
	gold = Color3.fromRGB(248, 198, 76),
	goldBright = Color3.fromRGB(255, 226, 118),
	amber = Color3.fromRGB(255, 196, 98),
	coralRed = Color3.fromRGB(244, 96, 108),
	white = Color3.fromRGB(248, 250, 255),
	cream = Color3.fromRGB(255, 244, 224),
	waterGlow = Color3.fromRGB(84, 222, 238),
	teal = Color3.fromRGB(72, 216, 174),
}

-- Matches Config/Training TIER_COLORS for the Lv10 legendary rainbow floor.
local RAINBOW = {
	Color3.fromRGB(255, 244, 220), -- cream
	Color3.fromRGB(108, 232, 178), -- teal
	Color3.fromRGB(82, 206, 255), -- crystal blue
	Color3.fromRGB(186, 118, 255), -- purple
	Color3.fromRGB(255, 108, 214), -- neon pink
	Color3.fromRGB(255, 208, 74), -- legendary gold
}

export type LevelMeta = {
	index: number,
	id: string,
	name: string,
	radius: number,
	maxParts: number,
	maxLights: number,
	maxEmitters: number,
	camOffset: Vector3,
	camTargetY: number,
	boardPos: Vector3,
	anchorRadius: number,
}

local LEVELS: { LevelMeta } = {
	{
		index = 1,
		id = "training_lv01",
		name = "Clareira",
		radius = 16,
		maxParts = 25,
		maxLights = 0,
		maxEmitters = 0,
		camOffset = Vector3.new(12, 9.5, 16),
		camTargetY = 1.8,
		boardPos = Vector3.new(6.8, 0, 6.2),
		anchorRadius = 7.5,
	},
	{
		index = 2,
		id = "training_lv02",
		name = "Deck simples",
		radius = 17,
		maxParts = 50,
		maxLights = 0,
		maxEmitters = 0,
		camOffset = Vector3.new(14, 10.5, 18),
		camTargetY = 2.2,
		boardPos = Vector3.new(8.2, 0.35, 7.2),
		anchorRadius = 9.0,
	},
	{
		index = 3,
		id = "training_lv03",
		name = "Cais de treino",
		radius = 18,
		maxParts = 80,
		maxLights = 1,
		maxEmitters = 0,
		camOffset = Vector3.new(16, 11.5, 20),
		camTargetY = 2.8,
		boardPos = Vector3.new(9.5, 0.45, 8.2),
		anchorRadius = 10.5,
	},
	{
		index = 4,
		id = "training_lv04",
		name = "Cercado de pedra",
		radius = 19,
		maxParts = 110,
		maxLights = 1,
		maxEmitters = 0,
		camOffset = Vector3.new(18, 12.5, 22),
		camTargetY = 3.2,
		boardPos = Vector3.new(10.8, 0.45, 9.2),
		anchorRadius = 11.8,
	},
	{
		index = 5,
		id = "training_lv05",
		name = "Torre pequena",
		radius = 20,
		maxParts = 140,
		maxLights = 2,
		maxEmitters = 1,
		camOffset = Vector3.new(21, 15.5, 25),
		camTargetY = 5.2,
		boardPos = Vector3.new(11.6, 0.9, 10.2),
		anchorRadius = 13.0,
	},
	{
		index = 6,
		id = "training_lv06",
		name = "Arena runica",
		radius = 22,
		maxParts = 170,
		maxLights = 2,
		maxEmitters = 2,
		camOffset = Vector3.new(22, 16.5, 26),
		camTargetY = 5.0,
		boardPos = Vector3.new(12.6, 0.55, 11.0),
		anchorRadius = 14.2,
	},
	{
		index = 7,
		id = "training_lv07",
		name = "Jardim das fontes",
		radius = 24,
		maxParts = 200,
		maxLights = 2,
		maxEmitters = 3,
		camOffset = Vector3.new(24, 17.0, 28),
		camTargetY = 5.2,
		boardPos = Vector3.new(13.6, 0.65, 11.8),
		anchorRadius = 15.4,
	},
	{
		index = 8,
		id = "training_lv08",
		name = "Arcos de cristal",
		radius = 25,
		maxParts = 220,
		maxLights = 2,
		maxEmitters = 4,
		camOffset = Vector3.new(26, 18.5, 31),
		camTargetY = 6.8,
		boardPos = Vector3.new(14.5, 0.7, 12.6),
		anchorRadius = 16.5,
	},
	{
		index = 9,
		id = "training_lv09",
		name = "Plataforma flutuante",
		radius = 26,
		maxParts = 240,
		maxLights = 2,
		maxEmitters = 5,
		camOffset = Vector3.new(28, 21.0, 34),
		camTargetY = 8.4,
		boardPos = Vector3.new(15.2, 2.8, 13.2),
		anchorRadius = 17.5,
	},
	{
		index = 10,
		id = "training_lv10",
		name = "Santuario do Pescador Lendario",
		radius = 28,
		maxParts = 250,
		maxLights = 2,
		maxEmitters = 5,
		camOffset = Vector3.new(30, 22.5, 37),
		camTargetY = 9.5,
		boardPos = Vector3.new(16.2, 1.35, 14.0),
		anchorRadius = 18.8,
	},
}

type BuildCtx = {
	origin: CFrame,
	floor: Model,
	structure: Model,
	decor: Model,
	light: Model,
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
		reflectance: number?,
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
		if opts.reflectance then
			p.Reflectance = opts.reflectance
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

local function addWedge(
	parent: Instance,
	origin: CFrame,
	name: string,
	size: Vector3,
	localCF: CFrame,
	color: Color3,
	material: Enum.Material?,
	opts: { transparency: number?, canCollide: boolean?, castShadow: boolean? }?
): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.Size = size
	w.CFrame = origin * localCF
	w.Color = color
	w.Material = material or Enum.Material.SmoothPlastic
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	if opts and opts.transparency then
		w.Transparency = opts.transparency
	end
	local collide = opts ~= nil and opts.canCollide == true
	w.CanCollide = collide
	w.CanQuery = collide
	w.CanTouch = false
	w.CastShadow = opts ~= nil and opts.castShadow == true
	w.Parent = parent
	return w
end

-- Vertical cylinder centered at (x, centerY, z) with given height & diameter.
local function cylCF(x: number, centerY: number, z: number): CFrame
	return CFrame.new(x, centerY, z) * CFrame.Angles(0, 0, math.rad(90))
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
		cylCF(x, centerY, z),
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

-- Straight beam/rope between two local points.
local function addSpan(
	parent: Instance,
	origin: CFrame,
	name: string,
	a: Vector3,
	b: Vector3,
	thickness: number,
	height: number,
	color: Color3,
	material: Enum.Material?,
	opts: { transparency: number?, canCollide: boolean?, castShadow: boolean? }?
): Part
	local delta = b - a
	local len = math.max(delta.Magnitude, 0.1)
	local mid = (a + b) * 0.5
	local cf = CFrame.lookAt(mid, b)
	return addPart(
		parent,
		origin,
		name,
		Vector3.new(thickness, height, len),
		cf,
		color,
		material,
		opts
	)
end

local function addLight(
	parent: BasePart,
	color: Color3,
	brightness: number,
	range: number
): PointLight
	local l = Instance.new("PointLight")
	l.Name = "FieldLight"
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
		NumberSequenceKeypoint.new(0.5, (sizeStart + sizeEnd) * 0.55),
		NumberSequenceKeypoint.new(1, sizeEnd),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.75, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Lifetime = NumberRange.new(lifeMin, lifeMax)
	e.SpreadAngle = Vector2.new(spread or 35, spread or 35)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = parent
	return e
end

local function makeMarker(
	parent: Instance,
	origin: CFrame,
	name: string,
	size: Vector3,
	localCF: CFrame
): Part
	return addPart(
		parent,
		origin,
		name,
		size,
		localCF,
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		{ transparency = 1, canCollide = false, castShadow = false }
	)
end

-- Reusable sculptural helpers (low part count, distinct stylized silhouette) ------------

local function buildBuoy(
	ctx: BuildCtx,
	pos: Vector3,
	scale: number,
	stripeColor: Color3,
	withRing: boolean
)
	local s = scale
	addPart(
		ctx.decor,
		ctx.origin,
		"BuoyBody",
		Vector3.new(1.5 * s, 1.5 * s, 1.5 * s),
		CFrame.new(pos + Vector3.new(0, 0.75 * s, 0)),
		PALETTE.coralRed,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Ball }
	)
	addCyl(
		ctx.decor,
		ctx.origin,
		"BuoyStripe",
		0.36 * s,
		1.62 * s,
		pos.X,
		pos.Y + 0.78 * s,
		pos.Z,
		stripeColor,
		Enum.Material.SmoothPlastic
	)
	addCyl(
		ctx.decor,
		ctx.origin,
		"BuoyStem",
		0.75 * s,
		0.24 * s,
		pos.X,
		pos.Y + 1.65 * s,
		pos.Z,
		PALETTE.woodWarm,
		Enum.Material.Wood
	)
	if withRing then
		addPart(
			ctx.decor,
			ctx.origin,
			"BuoyTop",
			Vector3.new(0.42 * s, 0.42 * s, 0.42 * s),
			CFrame.new(pos + Vector3.new(0, 2.08 * s, 0)),
			PALETTE.gold,
			Enum.Material.Neon,
			{ shape = Enum.PartType.Ball }
		)
	end
end

local function buildLanternPost(
	ctx: BuildCtx,
	basePos: Vector3,
	height: number,
	armDir: Vector3,
	glowColor: Color3,
	withLight: boolean,
	lightRange: number?
)
	local d = Vector3.new(armDir.X, 0, armDir.Z)
	if d.Magnitude < 0.01 then
		d = Vector3.new(0, 0, 1)
	else
		d = d.Unit
	end
	local yaw = math.atan2(d.X, d.Z)
	addCyl(
		ctx.structure,
		ctx.origin,
		"LanternPost",
		height,
		0.52,
		basePos.X,
		basePos.Y + height * 0.5,
		basePos.Z,
		PALETTE.woodDark,
		Enum.Material.Wood,
		{ castShadow = true }
	)
	local armPos = basePos + Vector3.new(0, height - 0.35, 0) + d * 0.72
	addPart(
		ctx.structure,
		ctx.origin,
		"LanternArm",
		Vector3.new(0.32, 0.32, 1.55),
		CFrame.new(armPos) * CFrame.Angles(0, yaw, 0),
		PALETTE.woodWarm,
		Enum.Material.Wood
	)
	local bulbPos = basePos + Vector3.new(0, height - 1.15, 0) + d * 1.32
	addPart(
		ctx.light,
		ctx.origin,
		"LanternCap",
		Vector3.new(0.95, 0.24, 0.95),
		CFrame.new(bulbPos + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, yaw, 0),
		PALETTE.iron,
		Enum.Material.Metal
	)
	local core = addPart(
		ctx.light,
		ctx.origin,
		"LanternGlow",
		Vector3.new(0.68, 0.85, 0.68),
		CFrame.new(bulbPos) * CFrame.Angles(0, yaw, 0),
		glowColor,
		Enum.Material.Neon
	)
	if withLight then
		addLight(core, glowColor, 1.55, lightRange or 24)
	end
end

local function buildCrystalCluster(
	ctx: BuildCtx,
	basePos: Vector3,
	scale: number,
	primary: Color3,
	secondary: Color3,
	spires: number
)
	local s = scale
	-- Main central spire
	addPart(
		ctx.decor,
		ctx.origin,
		"CrystalMain",
		Vector3.new(0.9 * s, 3.1 * s, 0.9 * s),
		CFrame.new(basePos + Vector3.new(0, 1.35 * s, 0))
			* CFrame.Angles(math.rad(5), math.rad(18), math.rad(-6)),
		primary,
		Enum.Material.Neon
	)
	if spires >= 2 then
		addPart(
			ctx.decor,
			ctx.origin,
			"CrystalSideA",
			Vector3.new(0.65 * s, 2.0 * s, 0.65 * s),
			CFrame.new(basePos + Vector3.new(0.68 * s, 0.85 * s, 0.22 * s))
				* CFrame.Angles(math.rad(14), math.rad(35), math.rad(-24)),
			secondary,
			Enum.Material.SmoothPlastic
		)
	end
	if spires >= 3 then
		addPart(
			ctx.decor,
			ctx.origin,
			"CrystalSideB",
			Vector3.new(0.58 * s, 1.7 * s, 0.58 * s),
			CFrame.new(basePos + Vector3.new(-0.62 * s, 0.72 * s, -0.25 * s))
				* CFrame.Angles(math.rad(-16), math.rad(10), math.rad(22)),
			primary,
			Enum.Material.Neon
		)
	end
end

-- Segmented circular ring in XZ (horizontal) or tilted plane, zero coplanar overlaps.
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
	material: Enum.Material,
	arcStartDeg: number?,
	arcEndDeg: number?
)
	local a0 = math.rad(arcStartDeg or 0)
	local a1 = math.rad(arcEndDeg or 360)
	local full = math.abs((arcEndDeg or 360) - (arcStartDeg or 0)) >= 359.5
	local step = (a1 - a0) / segments
	local segLen = 2 * radius * math.sin(math.abs(step) * 0.5) * 0.94
	for i = 0, segments - 1 do
		local ang = a0 + (i + 0.5) * step
		local x = math.sin(ang) * radius
		local z = math.cos(ang) * radius
		local yOff = (i % 2) * 0.04 -- prevents adjacent end-caps from coplanar z-fighting
		local localCF = centerCF * CFrame.new(x, yOff, z) * CFrame.Angles(0, ang, 0)
		local col = if i % 2 == 0 then colorA else colorB
		addPart(
			parent,
			origin,
			name .. "_" .. tostring(i + 1),
			Vector3.new(segLen, height, thickness),
			localCF,
			col,
			material
		)
	end
	if not full then
		return
	end
end

-- Stylized jumping fish statue on a fountain plinth (5 parts).
local function buildFishStatue(ctx: BuildCtx, basePos: Vector3, yawDeg: number, scale: number)
	local cf = CFrame.new(basePos) * CFrame.Angles(0, math.rad(yawDeg), 0)
	local s = scale
	addPart(
		ctx.decor,
		ctx.origin,
		"FishStatueBody",
		Vector3.new(1.1 * s, 2.2 * s, 1.3 * s),
		cf * CFrame.new(0, 1.55 * s, 0) * CFrame.Angles(math.rad(-22), 0, 0),
		PALETTE.marble,
		Enum.Material.Marble
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"FishStatueHead",
		Vector3.new(0.95 * s, 1.0 * s, 1.05 * s),
		cf * CFrame.new(0, 2.55 * s, 0.45 * s) * CFrame.Angles(math.rad(18), 0, 0),
		PALETTE.marble,
		Enum.Material.Marble,
		{ shape = Enum.PartType.Ball }
	)
	addWedge(
		ctx.decor,
		ctx.origin,
		"FishStatueTail",
		Vector3.new(0.32 * s, 1.15 * s, 1.1 * s),
		cf * CFrame.new(0, 0.55 * s, -0.55 * s) * CFrame.Angles(math.rad(-35), 0, 0),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	addWedge(
		ctx.decor,
		ctx.origin,
		"FishStatueCrest",
		Vector3.new(0.24 * s, 1.2 * s, 0.75 * s),
		cf * CFrame.new(0, 1.85 * s, -0.52 * s) * CFrame.Angles(math.rad(-15), 0, 0),
		PALETTE.goldBright,
		Enum.Material.Neon
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"FishStatueCrown",
		Vector3.new(0.55 * s, 0.35 * s, 0.55 * s),
		cf * CFrame.new(0, 3.12 * s, 0.55 * s),
		PALETTE.cyan,
		Enum.Material.Neon
	)
end

-- Stylized faceted crystal arch spanning between two angles around the arena (5 parts).
local function buildCrystalArch(
	ctx: BuildCtx,
	centerPos: Vector3,
	yawDeg: number,
	spanWidth: number,
	archHeight: number,
	primary: Color3,
	secondary: Color3
)
	local cf = CFrame.new(centerPos) * CFrame.Angles(0, math.rad(yawDeg), 0)
	local halfW = spanWidth * 0.5
	local legH = archHeight * 0.62
	-- Left & right angled legs
	addPart(
		ctx.structure,
		ctx.origin,
		"ArchLegL",
		Vector3.new(1.25, legH, 1.25),
		cf * CFrame.new(-halfW * 0.86, legH * 0.48, 0) * CFrame.Angles(0, 0, math.rad(-12)),
		secondary,
		Enum.Material.SmoothPlastic,
		{ castShadow = true }
	)
	addPart(
		ctx.structure,
		ctx.origin,
		"ArchLegR",
		Vector3.new(1.25, legH, 1.25),
		cf * CFrame.new(halfW * 0.86, legH * 0.48, 0) * CFrame.Angles(0, 0, math.rad(12)),
		secondary,
		Enum.Material.SmoothPlastic,
		{ castShadow = true }
	)
	-- Upper angled crystal ribs meeting at the apex
	local ribLen = math.sqrt((halfW * 0.82) ^ 2 + (archHeight * 0.44) ^ 2)
	addPart(
		ctx.structure,
		ctx.origin,
		"ArchRibL",
		Vector3.new(1.05, ribLen, 1.05),
		cf * CFrame.new(-halfW * 0.36, archHeight * 0.76, 0.04) * CFrame.Angles(0, 0, math.rad(-44)),
		primary,
		Enum.Material.Neon
	)
	addPart(
		ctx.structure,
		ctx.origin,
		"ArchRibR",
		Vector3.new(1.05, ribLen, 1.05),
		cf * CFrame.new(halfW * 0.36, archHeight * 0.76, -0.04) * CFrame.Angles(0, 0, math.rad(44)),
		primary,
		Enum.Material.Neon
	)
	-- Apex diamond keystone
	addPart(
		ctx.decor,
		ctx.origin,
		"ArchKeystone",
		Vector3.new(1.55, 1.95, 1.25),
		cf * CFrame.new(0, archHeight * 0.98, 0) * CFrame.Angles(0, math.rad(45), 0),
		PALETTE.goldBright,
		Enum.Material.Neon
	)
end

-- Level Builders (1 .. 10) --------------------------------------------------------------

-- Level 1: Clareira (<= 25 parts total incl. 9 anchors, 0 lights, 0 emitters)
local function buildLevel01(ctx: BuildCtx)
	-- Layer_00_Floor (3 walkable parts)
	addCyl(
		ctx.floor,
		ctx.origin,
		"GrassClearing",
		0.32,
		13.2,
		0,
		-0.12,
		0,
		PALETTE.grass,
		Enum.Material.Grass,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"InnerTurf",
		0.22,
		7.6,
		0,
		0.01,
		0.4,
		PALETTE.grassLight,
		Enum.Material.Grass,
		{ canCollide = true }
	)
	addPart(
		ctx.floor,
		ctx.origin,
		"EntryStepStone",
		Vector3.new(4.2, 0.28, 2.2),
		CFrame.new(0, -0.05, 6.2),
		PALETTE.stoneMid,
		Enum.Material.Cobblestone,
		{ canCollide = true }
	)

	-- Layer_01_Structure (4 parts: single rustic wooden mooring post)
	addCyl(
		ctx.structure,
		ctx.origin,
		"RusticPost",
		4.6,
		0.72,
		-4.6,
		2.2,
		-3.8,
		PALETTE.woodWarm,
		Enum.Material.Wood,
		{ castShadow = true }
	)
	addCyl(
		ctx.structure,
		ctx.origin,
		"PostCap",
		0.28,
		0.92,
		-4.6,
		4.55,
		-3.8,
		PALETTE.woodDark,
		Enum.Material.Wood
	)
	addCyl(
		ctx.structure,
		ctx.origin,
		"PostRopeWrap",
		0.55,
		0.84,
		-4.6,
		3.15,
		-3.8,
		PALETTE.rope,
		Enum.Material.Fabric
	)
	addPart(
		ctx.structure,
		ctx.origin,
		"PostPeg",
		Vector3.new(1.3, 0.24, 0.24),
		CFrame.new(-4.1, 3.65, -3.8) * CFrame.Angles(0, 0, math.rad(8)),
		PALETTE.woodLight,
		Enum.Material.Wood
	)

	-- Layer_02_Decor (6 parts: training buoy + 2 pebbles + grass tuft)
	buildBuoy(ctx, Vector3.new(4.4, 0.02, -4.4), 1.0, PALETTE.white, false) -- 3 parts
	addPart(
		ctx.decor,
		ctx.origin,
		"ClearingStoneA",
		Vector3.new(1.5, 0.75, 1.2),
		CFrame.new(-5.4, 0.32, -2.5) * CFrame.Angles(0, math.rad(28), 0),
		PALETTE.stoneMid,
		Enum.Material.Rock
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"ClearingStoneB",
		Vector3.new(1.1, 0.55, 0.95),
		CFrame.new(5.1, 0.25, -2.9) * CFrame.Angles(0, math.rad(-22), 0),
		PALETTE.stoneLight,
		Enum.Material.Rock
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"GrassTuft",
		Vector3.new(1.6, 0.55, 1.4),
		CFrame.new(-3.2, 0.24, -5.2) * CFrame.Angles(0, math.rad(15), 0),
		PALETTE.grassDark,
		Enum.Material.Grass
	)
end

-- Level 2: Deck simples (<= 50 parts total, 0 lights, 0 emitters)
local function buildLevel02(ctx: BuildCtx)
	-- Layer_00_Floor: wooden plank deck + entry board
	addPart(
		ctx.floor,
		ctx.origin,
		"DeckMain",
		Vector3.new(13.6, 0.52, 11.4),
		CFrame.new(0, 0.08, -0.4),
		PALETTE.woodWarm,
		Enum.Material.WoodPlanks,
		{ canCollide = true }
	)
	addPart(
		ctx.floor,
		ctx.origin,
		"DeckFrontStep",
		Vector3.new(6.8, 0.34, 2.2),
		CFrame.new(0, -0.02, 6.2),
		PALETTE.woodLight,
		Enum.Material.WoodPlanks,
		{ canCollide = true }
	)
	-- Non-coplanar perimeter trim boards
	addPart(
		ctx.structure,
		ctx.origin,
		"RimBack",
		Vector3.new(14.2, 0.42, 0.55),
		CFrame.new(0, 0.26, -6.3),
		PALETTE.woodDark,
		Enum.Material.Wood
	)
	addPart(
		ctx.structure,
		ctx.origin,
		"RimLeft",
		Vector3.new(0.55, 0.42, 11.2),
		CFrame.new(-7.0, 0.26, -0.4),
		PALETTE.woodDark,
		Enum.Material.Wood
	)
	addPart(
		ctx.structure,
		ctx.origin,
		"RimRight",
		Vector3.new(0.55, 0.42, 11.2),
		CFrame.new(7.0, 0.26, -0.4),
		PALETTE.woodDark,
		Enum.Material.Wood
	)
	-- 4 corner pilings
	for i, pt in
		{
			Vector3.new(-6.6, -1.3, -5.8),
			Vector3.new(6.6, -1.3, -5.8),
			Vector3.new(-6.6, -1.3, 4.9),
			Vector3.new(6.6, -1.3, 4.9),
		}
	do
		addCyl(
			ctx.structure,
			ctx.origin,
			"Piling_" .. tostring(i),
			3.0,
			0.85,
			pt.X,
			pt.Y,
			pt.Z,
			PALETTE.woodDark,
			Enum.Material.Wood
		)
	end

	-- Two rear posts with sagging rope between them
	for _, sgn in { -1, 1 } do
		local x = sgn * 5.8
		addCyl(
			ctx.structure,
			ctx.origin,
			"RopePost_" .. tostring(sgn),
			4.8,
			0.68,
			x,
			2.6,
			-5.6,
			PALETTE.woodWarm,
			Enum.Material.Wood,
			{ castShadow = true }
		)
		addCyl(
			ctx.structure,
			ctx.origin,
			"RopePostCap_" .. tostring(sgn),
			0.26,
			0.88,
			x,
			5.05,
			-5.6,
			PALETTE.woodDark,
			Enum.Material.Wood
		)
	end
	local ropePts = {
		Vector3.new(-5.6, 3.85, -5.6),
		Vector3.new(-2.0, 3.25, -5.6),
		Vector3.new(2.0, 3.25, -5.6),
		Vector3.new(5.6, 3.85, -5.6),
	}
	for i = 1, #ropePts - 1 do
		addSpan(
			ctx.decor,
			ctx.origin,
			"RopeSeg_" .. tostring(i),
			ropePts[i],
			ropePts[i + 1],
			0.22,
			0.22,
			PALETTE.rope,
			Enum.Material.Fabric
		)
	end

	-- Wooden bench / stool on left flank
	local bx, bz = -5.2, 0.8
	addPart(
		ctx.decor,
		ctx.origin,
		"BenchTop",
		Vector3.new(1.55, 0.28, 3.6),
		CFrame.new(bx, 1.52, bz),
		PALETTE.woodLight,
		Enum.Material.WoodPlanks
	)
	for i, dz in { -1.25, 1.25 } do
		addPart(
			ctx.decor,
			ctx.origin,
			"BenchLeg_" .. tostring(i),
			Vector3.new(1.25, 1.15, 0.34),
			CFrame.new(bx, 0.85, bz + dz),
			PALETTE.woodDark,
			Enum.Material.Wood
		)
	end
	addPart(
		ctx.decor,
		ctx.origin,
		"BenchBrace",
		Vector3.new(0.28, 0.24, 2.5),
		CFrame.new(bx, 0.72, bz),
		PALETTE.woodWarm,
		Enum.Material.Wood
	)

	-- Striped training buoy & small wooden bucket on right flank
	buildBuoy(ctx, Vector3.new(5.2, 0.34, -3.6), 1.08, PALETTE.cream, true)
	addCyl(
		ctx.decor,
		ctx.origin,
		"TackleBucket",
		1.25,
		1.25,
		5.4,
		0.96,
		1.2,
		PALETTE.woodWarm,
		Enum.Material.Wood
	)
	addCyl(
		ctx.decor,
		ctx.origin,
		"BucketHoop",
		0.18,
		1.32,
		5.4,
		1.28,
		1.2,
		PALETTE.iron,
		Enum.Material.Metal
	)
end

-- Level 3: Cais de treino (<= 80 parts total, 1 light, 0 emitters)
local function buildLevel03(ctx: BuildCtx)
	-- Expanded dock deck + side wings + front step
	addPart(
		ctx.floor,
		ctx.origin,
		"PierDeckCore",
		Vector3.new(16.8, 0.56, 13.8),
		CFrame.new(0, 0.14, -0.6),
		PALETTE.woodWarm,
		Enum.Material.WoodPlanks,
		{ canCollide = true }
	)
	addPart(
		ctx.floor,
		ctx.origin,
		"PierDeckCenterInlay",
		Vector3.new(8.2, 0.12, 7.6),
		CFrame.new(0, 0.44, -0.3),
		PALETTE.woodLight,
		Enum.Material.WoodPlanks,
		{ canCollide = true }
	)
	addPart(
		ctx.floor,
		ctx.origin,
		"PierApproachStep",
		Vector3.new(8.4, 0.36, 2.4),
		CFrame.new(0, -0.01, 7.2),
		PALETTE.woodLight,
		Enum.Material.WoodPlanks,
		{ canCollide = true }
	)

	-- Perimeter curbs & 6 sturdy pilings
	addPart(
		ctx.structure,
		ctx.origin,
		"CurbBack",
		Vector3.new(17.4, 0.48, 0.65),
		CFrame.new(0, 0.34, -7.75),
		PALETTE.woodDark,
		Enum.Material.Wood
	)
	for _, sgn in { -1, 1 } do
		addPart(
			ctx.structure,
			ctx.origin,
			"CurbSide_" .. tostring(sgn),
			Vector3.new(0.65, 0.48, 13.6),
			CFrame.new(sgn * 8.6, 0.34, -0.6),
			PALETTE.woodDark,
			Enum.Material.Wood
		)
	end
	for i, pt in
		{
			Vector3.new(-8.2, -1.4, -7.2),
			Vector3.new(0, -1.4, -7.2),
			Vector3.new(8.2, -1.4, -7.2),
			Vector3.new(-8.2, -1.4, 5.9),
			Vector3.new(8.2, -1.4, 5.9),
		}
	do
		addCyl(
			ctx.structure,
			ctx.origin,
			"PierPiling_" .. tostring(i),
			3.4,
			0.95,
			pt.X,
			pt.Y,
			pt.Z,
			PALETTE.woodDark,
			Enum.Material.Wood
		)
	end

	-- Rear & side timber rails with rope segments
	local posts = {
		Vector3.new(-8.0, 0.42, 4.4),
		Vector3.new(-8.0, 0.42, -1.8),
		Vector3.new(-8.0, 0.42, -7.1),
		Vector3.new(0, 0.42, -7.1),
		Vector3.new(8.0, 0.42, -7.1),
		Vector3.new(8.0, 0.42, -1.8),
		Vector3.new(8.0, 0.42, 4.4),
	}
	for i, pt in posts do
		addCyl(
			ctx.structure,
			ctx.origin,
			"DockPost_" .. tostring(i),
			3.8,
			0.56,
			pt.X,
			pt.Y + 1.9,
			pt.Z,
			PALETTE.woodWarm,
			Enum.Material.Wood
		)
		if i < #posts then
			addSpan(
				ctx.decor,
				ctx.origin,
				"DockRope_" .. tostring(i),
				pt + Vector3.new(0, 3.1, 0),
				posts[i + 1] + Vector3.new(0, 3.1, 0),
				0.2,
				0.2,
				PALETTE.rope,
				Enum.Material.Fabric
			)
		end
	end

	-- 2 Amber Lantern Posts (1 shared PointLight total to respect Lv3 budget)
	buildLanternPost(
		ctx,
		Vector3.new(-7.4, 0.42, -6.5),
		7.0,
		Vector3.new(1, 0, 1),
		PALETTE.amber,
		true,
		26
	)
	buildLanternPost(
		ctx,
		Vector3.new(7.4, 0.42, -6.5),
		7.0,
		Vector3.new(-1, 0, 1),
		PALETTE.amber,
		false
	)

	-- Bait barrel + iron hoops + crate
	addCyl(
		ctx.decor,
		ctx.origin,
		"BaitBarrel",
		2.3,
		1.85,
		-6.2,
		1.57,
		-4.2,
		PALETTE.woodWarm,
		Enum.Material.Wood
	)
	addCyl(
		ctx.decor,
		ctx.origin,
		"BarrelHoopLow",
		0.18,
		1.94,
		-6.2,
		0.95,
		-4.2,
		PALETTE.iron,
		Enum.Material.Metal
	)
	addCyl(
		ctx.decor,
		ctx.origin,
		"BarrelHoopHigh",
		0.18,
		1.94,
		-6.2,
		2.15,
		-4.2,
		PALETTE.iron,
		Enum.Material.Metal
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"BaitCrate",
		Vector3.new(1.85, 1.4, 1.85),
		CFrame.new(-6.4, 1.12, -1.7) * CFrame.Angles(0, math.rad(14), 0),
		PALETTE.woodLight,
		Enum.Material.WoodPlanks
	)

	-- Wooden decorative sign stand on right-rear flank (no text, stylized banner emblem)
	local sx, sz = 6.4, -3.5
	addCyl(
		ctx.structure,
		ctx.origin,
		"SignPostL",
		4.2,
		0.36,
		sx - 1.1,
		2.5,
		sz,
		PALETTE.woodDark,
		Enum.Material.Wood
	)
	addCyl(
		ctx.structure,
		ctx.origin,
		"SignPostR",
		4.2,
		0.36,
		sx + 1.1,
		2.5,
		sz,
		PALETTE.woodDark,
		Enum.Material.Wood
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"SignPlank",
		Vector3.new(3.2, 1.65, 0.34),
		CFrame.new(sx, 3.6, sz) * CFrame.Angles(0, math.rad(-24), 0),
		PALETTE.woodLight,
		Enum.Material.WoodPlanks
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"SignEmblem",
		Vector3.new(0.85, 0.85, 0.42),
		CFrame.new(sx, 3.6, sz) * CFrame.Angles(0, math.rad(-24), math.rad(45)),
		PALETTE.cyan,
		Enum.Material.Neon
	)

	-- Upgraded buoy + wooden bench
	buildBuoy(ctx, Vector3.new(6.1, 0.42, 1.4), 1.15, PALETTE.cyan, true)
	addPart(
		ctx.decor,
		ctx.origin,
		"PierBenchTop",
		Vector3.new(1.5, 0.28, 3.8),
		CFrame.new(-6.4, 1.6, 1.8),
		PALETTE.woodLight,
		Enum.Material.WoodPlanks
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"PierBenchLegs",
		Vector3.new(1.2, 1.1, 3.0),
		CFrame.new(-6.4, 0.96, 1.8),
		PALETTE.woodDark,
		Enum.Material.Wood
	)
end

-- Level 4: Cercado de pedra (<= 110 parts total, 1 light, 0 emitters)
local function buildLevel04(ctx: BuildCtx)
	-- Circular cobblestone floor + wooden center inlay + front steps
	addCyl(
		ctx.floor,
		ctx.origin,
		"StoneArenaFloor",
		0.58,
		21.2,
		0,
		0.14,
		-0.6,
		PALETTE.stoneLight,
		Enum.Material.Cobblestone,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"InnerTimberPad",
		0.14,
		11.4,
		0,
		0.45,
		-0.6,
		PALETTE.woodWarm,
		Enum.Material.WoodPlanks,
		{ canCollide = true }
	)
	addPart(
		ctx.floor,
		ctx.origin,
		"StoneEntrySlab",
		Vector3.new(8.8, 0.36, 3.2),
		CFrame.new(0, 0.0, 9.4),
		PALETTE.stoneMid,
		Enum.Material.Cobblestone,
		{ canCollide = true }
	)

	-- Low curved stone wall around rear & flanks (open front +Z from -42 deg to +42 deg)
	local wallSegments = 10
	local wallStart = math.rad(46)
	local wallEnd = math.rad(314)
	local wallR = 10.2
	local step = (wallEnd - wallStart) / wallSegments
	local segLen = 2 * wallR * math.sin(step * 0.5) * 0.96
	for i = 0, wallSegments - 1 do
		local ang = wallStart + (i + 0.5) * step
		local x = math.sin(ang) * wallR
		local z = math.cos(ang) * wallR - 0.6
		local yOff = (i % 2) * 0.04
		addPart(
			ctx.structure,
			ctx.origin,
			"StoneWall_" .. tostring(i + 1),
			Vector3.new(segLen, 2.2, 1.35),
			CFrame.new(x, 1.52 + yOff, z) * CFrame.Angles(0, ang, 0),
			if i % 2 == 0 then PALETTE.stoneMid else PALETTE.stoneLight,
			Enum.Material.Cobblestone,
			{ castShadow = true }
		)
		addPart(
			ctx.structure,
			ctx.origin,
			"StoneWallCap_" .. tostring(i + 1),
			Vector3.new(segLen + 0.14, 0.32, 1.65),
			CFrame.new(x, 2.74 + yOff, z) * CFrame.Angles(0, ang, 0),
			PALETTE.stoneDark,
			Enum.Material.Slate
		)
	end

	-- 6 Tall festival poles around the stone enclosure with colorful pennant banners
	local poleAngles = { 50, 98, 148, 212, 262, 310 }
	local poleTops: { Vector3 } = {}
	for i, deg in poleAngles do
		local ang = math.rad(deg)
		local p = Vector3.new(math.sin(ang) * 10.3, 0.42, math.cos(ang) * 10.3 - 0.6)
		addPart(
			ctx.structure,
			ctx.origin,
			"PierBase_" .. tostring(i),
			Vector3.new(1.85, 2.8, 1.85),
			CFrame.new(p + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, ang, 0),
			PALETTE.stoneDark,
			Enum.Material.Rock
		)
		addCyl(
			ctx.structure,
			ctx.origin,
			"BannerPole_" .. tostring(i),
			6.6,
			0.44,
			p.X,
			p.Y + 5.1,
			p.Z,
			PALETTE.woodDark,
			Enum.Material.Wood
		)
		addPart(
			ctx.decor,
			ctx.origin,
			"PoleFinial_" .. tostring(i),
			Vector3.new(0.62, 0.62, 0.62),
			CFrame.new(p + Vector3.new(0, 8.55, 0)),
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Ball }
		)
		table.insert(poleTops, p + Vector3.new(0, 7.6, 0))
	end

	-- Pennant lines + colorful triangular flags between poles
	local flagColors = { PALETTE.cyan, PALETTE.pink, PALETTE.gold, PALETTE.lilac }
	for i = 1, #poleTops - 1 do
		local a, b = poleTops[i], poleTops[i + 1]
		addSpan(
			ctx.decor,
			ctx.origin,
			"BannerString_" .. tostring(i),
			a,
			b,
			0.14,
			0.14,
			PALETTE.rope,
			Enum.Material.Fabric
		)
		local dir = (b - a)
		local yaw = math.atan2(dir.X, dir.Z)
		for k = 1, 3 do
			local t = k / 4
			local pos = a:Lerp(b, t) - Vector3.new(0, 0.58, 0)
			local col = flagColors[((i + k) % #flagColors) + 1]
			addWedge(
				ctx.decor,
				ctx.origin,
				"Pennant_" .. tostring(i) .. "_" .. tostring(k),
				Vector3.new(0.12, 0.95, 0.92),
				CFrame.new(pos) * CFrame.Angles(0, yaw, math.rad(180)),
				col,
				Enum.Material.SmoothPlastic
			)
		end
	end

	-- 2 Amber entrance lanterns (1 PointLight total)
	buildLanternPost(
		ctx,
		Vector3.new(-6.2, 0.42, 7.6),
		6.2,
		Vector3.new(1, 0, -0.4),
		PALETTE.amber,
		true,
		28
	)
	buildLanternPost(
		ctx,
		Vector3.new(6.2, 0.42, 7.6),
		6.2,
		Vector3.new(-1, 0, -0.4),
		PALETTE.amber,
		false
	)

	-- Floating concentric target buoy behind the rear wall
	local tx, ty, tz = 0, 1.4, -12.8
	addCyl(
		ctx.decor,
		ctx.origin,
		"TargetOuter",
		0.45,
		4.6,
		tx,
		ty,
		tz,
		PALETTE.coralRed,
		Enum.Material.SmoothPlastic
	)
	addCyl(
		ctx.decor,
		ctx.origin,
		"TargetMid",
		0.54,
		3.1,
		tx,
		ty + 0.05,
		tz,
		PALETTE.white,
		Enum.Material.SmoothPlastic
	)
	addCyl(
		ctx.decor,
		ctx.origin,
		"TargetCenter",
		0.62,
		1.55,
		tx,
		ty + 0.1,
		tz,
		PALETTE.goldBright,
		Enum.Material.Neon
	)
	addCyl(
		ctx.decor,
		ctx.origin,
		"TargetMast",
		2.8,
		0.22,
		tx,
		ty + 1.6,
		tz,
		PALETTE.woodDark,
		Enum.Material.Wood
	)
	addWedge(
		ctx.decor,
		ctx.origin,
		"TargetFlag",
		Vector3.new(0.14, 0.85, 1.35),
		CFrame.new(tx + 0.65, ty + 2.55, tz) * CFrame.Angles(0, math.rad(90), 0),
		PALETTE.cyan,
		Enum.Material.Neon
	)

	-- Bait barrel + stone bench inside the enclosure
	addCyl(
		ctx.decor,
		ctx.origin,
		"StoneEnclosureBarrel",
		2.2,
		1.8,
		-7.6,
		1.52,
		-3.2,
		PALETTE.woodWarm,
		Enum.Material.Wood
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"StoneBenchSeat",
		Vector3.new(1.7, 0.36, 4.2),
		CFrame.new(7.6, 1.68, -2.0),
		PALETTE.stoneLight,
		Enum.Material.Cobblestone
	)
end

-- Level 5: Torre pequena (<= 140 parts total, 2 lights, 1 emitter) — BIG MILESTONE!
local function buildLevel05(ctx: BuildCtx)
	-- Elevated stepped stone & timber dais (top at Y = +1.05, front steps climb cleanly from Y = 0)
	addCyl(
		ctx.floor,
		ctx.origin,
		"LowerStonePlinth",
		0.65,
		24.4,
		0,
		0.22,
		-1.0,
		PALETTE.stoneMid,
		Enum.Material.Cobblestone,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"ElevatedTimberDeck",
		0.56,
		20.6,
		0,
		0.80,
		-1.0,
		PALETTE.woodWarm,
		Enum.Material.WoodPlanks,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"CenterStoneMedallion",
		0.12,
		9.6,
		0,
		1.11,
		-1.0,
		PALETTE.stoneLight,
		Enum.Material.Cobblestone,
		{ canCollide = true }
	)
	-- 3 wide front steps leading up to the elevated platform
	for k = 1, 3 do
		local yTop = 0.36 * k
		local zPos = 12.2 - (k - 1) * 1.45
		addPart(
			ctx.floor,
			ctx.origin,
			"ApproachStep_" .. tostring(k),
			Vector3.new(8.6 - k * 0.25, 0.36, 1.85),
			CFrame.new(0, yTop - 0.18, zPos),
			if k % 2 == 0 then PALETTE.stoneLight else PALETTE.stoneMid,
			Enum.Material.Cobblestone,
			{ canCollide = true }
		)
	end

	-- Low decorative wooden railing framing back-right & flanks
	local railAngles = { 54, 92, 132, 172, 248, 294 }
	for i, deg in railAngles do
		local ang = math.rad(deg)
		local px = math.sin(ang) * 9.9
		local pz = math.cos(ang) * 9.9 - 1.0
		addCyl(
			ctx.structure,
			ctx.origin,
			"DaisPost_" .. tostring(i),
			3.2,
			0.58,
			px,
			2.65,
			pz,
			PALETTE.woodDark,
			Enum.Material.Wood
		)
		addPart(
			ctx.decor,
			ctx.origin,
			"DaisPostCrystal_" .. tostring(i),
			Vector3.new(0.45, 0.72, 0.45),
			CFrame.new(px, 4.55, pz) * CFrame.Angles(0, math.rad(45), 0),
			PALETTE.cyan,
			Enum.Material.Neon
		)
	end

	-- Iconic 2-story Wooden Watchtower on the back-left (-X, -Z) so the center stays 100% open!
	local tx, ty, tz = -8.4, 1.08, -8.8
	local tw = 5.4
	-- Tower stone foundation
	addPart(
		ctx.structure,
		ctx.origin,
		"TowerBase",
		Vector3.new(tw + 1.2, 2.6, tw + 1.2),
		CFrame.new(tx, ty + 1.2, tz),
		PALETTE.stoneDark,
		Enum.Material.Cobblestone,
		{ castShadow = true }
	)
	-- 4 tall timber legs + diagonal X braces
	for i, corner in
		{
			Vector3.new(-2.3, 0, -2.3),
			Vector3.new(2.3, 0, -2.3),
			Vector3.new(-2.3, 0, 2.3),
			Vector3.new(2.3, 0, 2.3),
		}
	do
		addPart(
			ctx.structure,
			ctx.origin,
			"TowerLeg_" .. tostring(i),
			Vector3.new(0.75, 11.2, 0.75),
			CFrame.new(tx + corner.X, ty + 7.2, tz + corner.Z),
			PALETTE.woodDark,
			Enum.Material.Wood,
			{ castShadow = true }
		)
	end
	-- Mid-level timber framing + lookout balcony deck
	addPart(
		ctx.structure,
		ctx.origin,
		"TowerMidBeam",
		Vector3.new(tw + 0.2, 0.55, tw + 0.2),
		CFrame.new(tx, ty + 6.4, tz),
		PALETTE.woodWarm,
		Enum.Material.WoodPlanks
	)
	addPart(
		ctx.structure,
		ctx.origin,
		"TowerLookoutFloor",
		Vector3.new(tw + 1.8, 0.65, tw + 1.8),
		CFrame.new(tx, ty + 10.6, tz),
		PALETTE.woodLight,
		Enum.Material.WoodPlanks,
		{ castShadow = true }
	)
	-- Lookout railings (4 sides, non-coplanar)
	for i, side in
		{
			{ Vector3.new(tw + 1.6, 0.38, 0.38), Vector3.new(0, 12.2, -3.4) },
			{ Vector3.new(tw + 1.6, 0.38, 0.38), Vector3.new(0, 12.2, 3.4) },
			{ Vector3.new(0.38, 0.38, tw + 0.9), Vector3.new(-3.4, 12.2, 0) },
			{ Vector3.new(0.38, 0.38, tw + 0.9), Vector3.new(3.4, 12.2, 0) },
		}
	do
		addPart(
			ctx.structure,
			ctx.origin,
			"TowerRail_" .. tostring(i),
			side[1],
			CFrame.new(tx + side[2].X, ty + side[2].Y, tz + side[2].Z),
			PALETTE.woodWarm,
			Enum.Material.Wood
		)
	end
	-- Roof posts & pitched blue-slate pyramid roof (4 wedges + ridge cap + finial flag)
	for i, c in
		{
			Vector3.new(-2.8, 0, -2.8),
			Vector3.new(2.8, 0, -2.8),
			Vector3.new(-2.8, 0, 2.8),
			Vector3.new(2.8, 0, 2.8),
		}
	do
		addPart(
			ctx.structure,
			ctx.origin,
			"RoofPost_" .. tostring(i),
			Vector3.new(0.45, 4.4, 0.45),
			CFrame.new(tx + c.X, ty + 13.0, tz + c.Z),
			PALETTE.woodDark,
			Enum.Material.Wood
		)
	end
	addPart(
		ctx.structure,
		ctx.origin,
		"TowerRoofBase",
		Vector3.new(tw + 2.8, 0.52, tw + 2.8),
		CFrame.new(tx, ty + 15.35, tz),
		PALETTE.slateRoofDark,
		Enum.Material.Slate,
		{ castShadow = true }
	)
	addPart(
		ctx.structure,
		ctx.origin,
		"TowerRoofMid",
		Vector3.new(tw + 0.8, 1.35, tw + 0.8),
		CFrame.new(tx, ty + 16.28, tz),
		PALETTE.slateRoof,
		Enum.Material.Slate,
		{ castShadow = true }
	)
	addPart(
		ctx.structure,
		ctx.origin,
		"TowerRoofPeak",
		Vector3.new(tw - 1.6, 1.45, tw - 1.6),
		CFrame.new(tx, ty + 17.68, tz),
		PALETTE.slateRoof,
		Enum.Material.Slate
	)
	addPart(
		ctx.structure,
		ctx.origin,
		"TowerRoofCap",
		Vector3.new(1.8, 0.95, 1.8),
		CFrame.new(tx, ty + 18.88, tz),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	-- Tower beacon crystal & flag spire
	addCyl(
		ctx.decor,
		ctx.origin,
		"TowerSpire",
		3.6,
		0.24,
		tx,
		ty + 20.8,
		tz,
		PALETTE.gold,
		Enum.Material.Metal
	)
	addWedge(
		ctx.decor,
		ctx.origin,
		"TowerFlag",
		Vector3.new(0.16, 1.25, 2.4),
		CFrame.new(tx + 1.2, ty + 21.8, tz) * CFrame.Angles(0, math.rad(90), 0),
		PALETTE.pink,
		Enum.Material.SmoothPlastic
	)
	local towerBeacon = addPart(
		ctx.light,
		ctx.origin,
		"TowerBeaconCrystal",
		Vector3.new(1.5, 2.2, 1.5),
		CFrame.new(tx, ty + 12.6, tz) * CFrame.Angles(0, math.rad(45), 0),
		PALETTE.cyan,
		Enum.Material.Neon
	)
	addLight(towerBeacon, PALETTE.cyan, 1.75, 36)
	addEmitter(
		towerBeacon,
		"CrystalMotes",
		PALETTE.cyan,
		PALETTE.white,
		9,
		1.2,
		2.8,
		0.35,
		0.05,
		1.4,
		2.4,
		45
	)

	-- 4 Corner Blue Crystal Clusters (signature visual of Level 5!)
	local crystalCorners = {
		{ Vector3.new(-10.2, 0.55, 6.2), 1.35 },
		{ Vector3.new(10.2, 0.55, 6.2), 1.35 },
		{ Vector3.new(10.4, 0.55, -7.8), 1.65 },
		{ Vector3.new(2.2, 0.55, -11.4), 1.5 },
	}
	for _, c in crystalCorners do
		buildCrystalCluster(ctx, c[1], c[2], PALETTE.cyan, PALETTE.cyanDeep, 3)
	end

	-- Second warm amber lantern on right flank (2nd PointLight total)
	buildLanternPost(
		ctx,
		Vector3.new(8.8, 1.08, 3.2),
		7.2,
		Vector3.new(-1, 0, 0.3),
		PALETTE.amber,
		true,
		28
	)

	-- Back-right trophy target & wooden supply cluster
	buildBuoy(ctx, Vector3.new(7.4, 1.08, -7.4), 1.25, PALETTE.gold, true)
	addCyl(
		ctx.decor,
		ctx.origin,
		"TowerBarrelA",
		2.2,
		1.8,
		-7.6,
		2.18,
		-3.2,
		PALETTE.woodWarm,
		Enum.Material.Wood
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"TowerCrate",
		Vector3.new(2.0, 1.5, 2.0),
		CFrame.new(-7.9, 1.83, -0.8) * CFrame.Angles(0, math.rad(20), 0),
		PALETTE.woodLight,
		Enum.Material.WoodPlanks
	)
end

-- Level 6: Arena runica (<= 170 parts total, 2 lights, 2 emitters)
local function buildLevel06(ctx: BuildCtx)
	-- Grand cut-stone circular arena with inlaid glowing Cyan Neon rune rings & cardinal rays
	addCyl(
		ctx.floor,
		ctx.origin,
		"RunicOuterBase",
		0.65,
		26.4,
		0,
		0.18,
		-1.0,
		PALETTE.basalt,
		Enum.Material.Slate,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"RunicInnerStone",
		0.18,
		23.2,
		0,
		0.56,
		-1.0,
		PALETTE.stoneDark,
		Enum.Material.Cobblestone,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"RunicCenterDisc",
		0.10,
		9.2,
		0,
		0.68,
		-1.0,
		PALETTE.basalt,
		Enum.Material.Slate,
		{ canCollide = true }
	)
	-- Wide stepped approach
	for k = 1, 2 do
		addPart(
			ctx.floor,
			ctx.origin,
			"RunicStep_" .. tostring(k),
			Vector3.new(9.6 - k * 0.4, 0.34, 2.2),
			CFrame.new(0, 0.17 + (k - 1) * 0.32, 13.4 - (k - 1) * 1.8),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			{ canCollide = true }
		)
	end

	-- Glowing Cyan Neon rune rings inlaid cleanly ABOVE floor (Y = 0.72 & 0.78, zero z-fight)
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"InnerRuneRing",
		CFrame.new(0, 0.74, -1.0),
		5.4,
		12,
		0.42,
		0.08,
		PALETTE.cyan,
		PALETTE.cyanDeep,
		Enum.Material.Neon
	)
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"OuterRuneRing",
		CFrame.new(0, 0.71, -1.0),
		10.2,
		16,
		0.52,
		0.08,
		PALETTE.cyan,
		PALETTE.lilac,
		Enum.Material.Neon
	)
	-- 8 Radial rune bars connecting inner & outer rings
	for i = 0, 7 do
		local ang = math.rad(i * 45)
		local rMid = 7.8
		addPart(
			ctx.decor,
			ctx.origin,
			"RuneRay_" .. tostring(i + 1),
			Vector3.new(0.45, 0.08, 3.8),
			CFrame.new(math.sin(ang) * rMid, 0.75 + (i % 2) * 0.02, math.cos(ang) * rMid - 1.0)
				* CFrame.Angles(0, ang, 0),
			if i % 2 == 0 then PALETTE.cyan else PALETTE.lilac,
			Enum.Material.Neon
		)
	end

	-- 6 Carved Rune Obelisks ringing the arena (open front approach)
	local obeliskAngles = { 52, 98, 148, 212, 262, 308 }
	for i, deg in obeliskAngles do
		local ang = math.rad(deg)
		local r = 12.2
		local px = math.sin(ang) * r
		local pz = math.cos(ang) * r - 1.0
		local isTall = (i == 3 or i == 4)
		local h = if isTall then 11.4 else 8.2
		addPart(
			ctx.structure,
			ctx.origin,
			"ObeliskPlinth_" .. tostring(i),
			Vector3.new(2.8, 1.4, 2.8),
			CFrame.new(px, 1.25, pz) * CFrame.Angles(0, ang, 0),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			{ castShadow = true }
		)
		addPart(
			ctx.structure,
			ctx.origin,
			"ObeliskShaft_" .. tostring(i),
			Vector3.new(1.85, h, 1.85),
			CFrame.new(px, 1.9 + h * 0.5, pz) * CFrame.Angles(0, ang, 0),
			PALETTE.basalt,
			Enum.Material.Slate,
			{ castShadow = true }
		)
		-- Glowing rune strip inlaid on the inward face
		local inDir = Vector3.new(-math.sin(ang), 0, -math.cos(ang))
		addPart(
			ctx.decor,
			ctx.origin,
			"ObeliskRune_" .. tostring(i),
			Vector3.new(0.48, h * 0.65, 0.16),
			CFrame.new(px + inDir.X * 0.96, 1.9 + h * 0.52, pz + inDir.Z * 0.96)
				* CFrame.Angles(0, ang, 0),
			PALETTE.cyan,
			Enum.Material.Neon
		)
		-- Floating crystal shard hovering over each obelisk
		local cap = addPart(
			ctx.decor,
			ctx.origin,
			"ObeliskShard_" .. tostring(i),
			Vector3.new(1.15, 2.1, 1.15),
			CFrame.new(px, 3.3 + h, pz) * CFrame.Angles(math.rad(12), ang + math.rad(45), 0),
			if isTall then PALETTE.lilac else PALETTE.cyan,
			Enum.Material.Neon
		)
		if i == 3 or i == 4 then
			addLight(cap, PALETTE.cyan, 1.7, 38)
		end
	end

	-- 2 Levitating Tilted Crystal Rings hovering high above the rear focal arc!
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"FloatCrystalRingA",
		CFrame.new(0, 12.2, -9.8) * CFrame.Angles(math.rad(68), math.rad(16), math.rad(-14)),
		5.4,
		12,
		0.58,
		0.58,
		PALETTE.cyan,
		PALETTE.goldBright,
		Enum.Material.Neon
	)
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"FloatCrystalRingB",
		CFrame.new(0, 12.2, -9.8) * CFrame.Angles(math.rad(-62), math.rad(-22), math.rad(20)),
		3.6,
		10,
		0.45,
		0.45,
		PALETTE.lilac,
		PALETTE.cyan,
		Enum.Material.Neon
	)
	-- Central floating runic core + 2 ParticleEmitters
	local coreOrb = addPart(
		ctx.light,
		ctx.origin,
		"RunicHaloCore",
		Vector3.new(2.2, 2.2, 2.2),
		CFrame.new(0, 12.2, -9.8),
		PALETTE.cyan,
		Enum.Material.Neon,
		{ shape = Enum.PartType.Ball }
	)
	addEmitter(
		coreOrb,
		"RunicHaloSparks",
		PALETTE.cyan,
		PALETTE.lilac,
		12,
		1.5,
		3.5,
		0.42,
		0.05,
		1.5,
		2.6,
		70
	)
	local floorEmitterHost = addPart(
		ctx.light,
		ctx.origin,
		"FloorRuneMist",
		Vector3.new(10, 0.2, 10),
		CFrame.new(0, 0.9, -1.0),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		{ transparency = 1 }
	)
	addEmitter(
		floorEmitterHost,
		"FloorRuneMotes",
		PALETTE.cyan,
		PALETTE.white,
		8,
		0.8,
		2.0,
		0.3,
		0.04,
		1.8,
		3.0,
		20
	)

	-- 4 Corner crystal accents
	buildCrystalCluster(ctx, Vector3.new(-11.8, 0.55, 5.4), 1.3, PALETTE.cyan, PALETTE.lilac, 2)
	buildCrystalCluster(ctx, Vector3.new(11.8, 0.55, 5.4), 1.3, PALETTE.cyan, PALETTE.lilac, 2)
end

-- Level 7: Jardim das fontes (<= 200 parts total, 2 lights, 3 emitters)
local function buildLevel07(ctx: BuildCtx)
	-- Polished pale-marble & turquoise-inlaid garden terrace
	addCyl(
		ctx.floor,
		ctx.origin,
		"GardenBase",
		0.72,
		28.4,
		0,
		0.22,
		-1.2,
		PALETTE.stoneLight,
		Enum.Material.Cobblestone,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"GardenMarbleDeck",
		0.18,
		25.2,
		0,
		0.64,
		-1.2,
		PALETTE.marble,
		Enum.Material.Marble,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"GardenTealInlay",
		0.10,
		12.6,
		0,
		0.75,
		-1.2,
		PALETTE.teal,
		Enum.Material.SmoothPlastic,
		{ canCollide = true }
	)
	-- Wide marble entry steps
	for k = 1, 2 do
		addPart(
			ctx.floor,
			ctx.origin,
			"GardenStep_" .. tostring(k),
			Vector3.new(10.2 - k * 0.4, 0.36, 2.2),
			CFrame.new(0, 0.18 + (k - 1) * 0.34, 14.2 - (k - 1) * 1.8),
			PALETTE.marble,
			Enum.Material.Marble,
			{ canCollide = true }
		)
	end

	-- Two Symmetrical Luminous Water Fountains + Jumping Fish Statues on rear flanks!
	for idx, sgn in { -1, 1 } do
		local fx, fy, fz = sgn * 8.6, 0.72, -8.8
		-- Tiered marble basin
		addCyl(
			ctx.structure,
			ctx.origin,
			"FountainBasinOuter_" .. tostring(idx),
			1.5,
			7.8,
			fx,
			fy + 0.75,
			fz,
			PALETTE.marble,
			Enum.Material.Marble,
			{ castShadow = true }
		)
		addCyl(
			ctx.structure,
			ctx.origin,
			"FountainRimGold_" .. tostring(idx),
			0.28,
			8.1,
			fx,
			fy + 1.56,
			fz,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		-- Luminous turquoise water pool (SmoothPlastic translucent, never Glass)
		addCyl(
			ctx.decor,
			ctx.origin,
			"FountainWater_" .. tostring(idx),
			0.35,
			6.8,
			fx,
			fy + 1.38,
			fz,
			PALETTE.waterGlow,
			Enum.Material.Neon,
			{ transparency = 0.22 }
		)
		-- Pedestal + upper tier bowl
		addCyl(
			ctx.structure,
			ctx.origin,
			"FountainStem_" .. tostring(idx),
			3.2,
			2.1,
			fx,
			fy + 3.0,
			fz,
			PALETTE.marble,
			Enum.Material.Marble
		)
		addCyl(
			ctx.structure,
			ctx.origin,
			"FountainUpperBowl_" .. tostring(idx),
			0.75,
			4.2,
			fx,
			fy + 4.75,
			fz,
			PALETTE.marble,
			Enum.Material.Marble
		)
		addCyl(
			ctx.decor,
			ctx.origin,
			"FountainUpperWater_" .. tostring(idx),
			0.26,
			3.5,
			fx,
			fy + 5.12,
			fz,
			PALETTE.cyan,
			Enum.Material.Neon,
			{ transparency = 0.15 }
		)
		-- 4 Falling water curtain ribbons
		for k = 0, 3 do
			local a = math.rad(k * 90 + 45)
			addPart(
				ctx.decor,
				ctx.origin,
				"FountainStream_" .. tostring(idx) .. "_" .. tostring(k),
				Vector3.new(0.45, 3.2, 0.22),
				CFrame.new(fx + math.sin(a) * 1.9, fy + 3.15, fz + math.cos(a) * 1.9)
					* CFrame.Angles(0, a, 0),
				PALETTE.waterGlow,
				Enum.Material.Neon,
				{ transparency = 0.35 }
			)
		end
		-- Jumping Marble & Gold Fish Statue crowning each fountain!
		buildFishStatue(ctx, Vector3.new(fx, fy + 5.2, fz), if sgn < 0 then 32 else -32, 1.32)
		-- Light + luminous spray emitter per fountain (2 lights, 2 emitters)
		local sprayHost = addPart(
			ctx.light,
			ctx.origin,
			"FountainGlow_" .. tostring(idx),
			Vector3.new(1.2, 1.2, 1.2),
			CFrame.new(fx, fy + 5.6, fz),
			PALETTE.cyan,
			Enum.Material.SmoothPlastic,
			{ transparency = 1 }
		)
		addLight(sprayHost, PALETTE.cyan, 1.65, 38)
		addEmitter(
			sprayHost,
			"FountainMist_" .. tostring(idx),
			PALETTE.cyan,
			PALETTE.pink,
			11,
			2.2,
			4.6,
			0.48,
			0.08,
			1.4,
			2.4,
			55
		)
	end

	-- Rear ceremonial floral archway connecting the two fountains
	for _, sgn in { -1, 1 } do
		addCyl(
			ctx.structure,
			ctx.origin,
			"GardenPillar_" .. tostring(sgn),
			9.4,
			1.2,
			sgn * 3.8,
			5.4,
			-12.4,
			PALETTE.marble,
			Enum.Material.Marble,
			{ castShadow = true }
		)
	end
	addPart(
		ctx.structure,
		ctx.origin,
		"GardenArchBeam",
		Vector3.new(9.6, 0.95, 1.45),
		CFrame.new(0, 10.4, -12.4),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	addPart(
		ctx.decor,
		ctx.origin,
		"GardenArchCrest",
		Vector3.new(2.2, 2.2, 0.8),
		CFrame.new(0, 11.7, -12.4) * CFrame.Angles(0, 0, math.rad(45)),
		PALETTE.pink,
		Enum.Material.Neon
	)

	-- Vibrant Pink & Lilac Flower Beds + Blossom Bushes curving around flanks
	local flowerAngles = { 48, 72, 96, 120, 240, 264, 288, 312 }
	for i, deg in flowerAngles do
		local ang = math.rad(deg)
		local r = 12.6
		local fx = math.sin(ang) * r
		local fz = math.cos(ang) * r - 1.2
		-- Stone planter + lush turf + 2 pink/lilac blossoms
		addPart(
			ctx.structure,
			ctx.origin,
			"Planter_" .. tostring(i),
			Vector3.new(3.2, 1.15, 2.0),
			CFrame.new(fx, 1.18, fz) * CFrame.Angles(0, ang, 0),
			PALETTE.stoneLight,
			Enum.Material.Cobblestone
		)
		addPart(
			ctx.decor,
			ctx.origin,
			"Bush_" .. tostring(i),
			Vector3.new(2.6, 1.25, 1.65),
			CFrame.new(fx, 2.15, fz) * CFrame.Angles(0, ang, 0),
			PALETTE.grass,
			Enum.Material.Grass
		)
		addPart(
			ctx.decor,
			ctx.origin,
			"BlossomA_" .. tostring(i),
			Vector3.new(0.95, 0.95, 0.95),
			CFrame.new(fx, 2.85, fz) * CFrame.Angles(0, ang, 0),
			if i % 2 == 0 then PALETTE.pink else PALETTE.lilac,
			Enum.Material.Neon,
			{ shape = Enum.PartType.Ball }
		)
		addPart(
			ctx.decor,
			ctx.origin,
			"BlossomB_" .. tostring(i),
			Vector3.new(0.68, 0.68, 0.68),
			CFrame.new(fx + math.cos(ang) * 0.85, 2.6, fz - math.sin(ang) * 0.85),
			if i % 2 == 0 then PALETTE.goldBright else PALETTE.pink,
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Ball }
		)
	end

	-- Soft garden petal aura emitter (3rd emitter total)
	local auraHost = addPart(
		ctx.light,
		ctx.origin,
		"GardenAuraHost",
		Vector3.new(16, 0.2, 14),
		CFrame.new(0, 1.5, -2.0),
		PALETTE.pink,
		Enum.Material.SmoothPlastic,
		{ transparency = 1 }
	)
	addEmitter(
		auraHost,
		"BlossomAura",
		PALETTE.pink,
		PALETTE.cyan,
		10,
		0.7,
		1.8,
		0.36,
		0.08,
		2.2,
		3.6,
		35
	)

	-- Luminous perimeter inlay ring
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"GardenGlowRing",
		CFrame.new(0, 0.78, -1.2),
		8.8,
		14,
		0.36,
		0.07,
		PALETTE.cyan,
		PALETTE.pink,
		Enum.Material.Neon
	)
end

-- Level 8: Arcos de cristal (<= 220 parts total, 2 lights, 4 emitters)
local function buildLevel08(ctx: BuildCtx)
	-- Expansive dark-slate & gold octagonal sanctuary terrace
	addCyl(
		ctx.floor,
		ctx.origin,
		"CrystalFloorBase",
		0.78,
		30.8,
		0,
		0.24,
		-1.4,
		PALETTE.basalt,
		Enum.Material.Slate,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"CrystalFloorTop",
		0.18,
		27.6,
		0,
		0.68,
		-1.4,
		PALETTE.stoneDark,
		Enum.Material.SmoothPlastic,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"CrystalInnerSanctum",
		0.10,
		14.0,
		0,
		0.80,
		-1.4,
		PALETTE.basalt,
		Enum.Material.Slate,
		{ canCollide = true }
	)
	for k = 1, 2 do
		addPart(
			ctx.floor,
			ctx.origin,
			"CrystalStep_" .. tostring(k),
			Vector3.new(11.0 - k * 0.4, 0.38, 2.2),
			CFrame.new(0, 0.19 + (k - 1) * 0.36, 15.6 - (k - 1) * 1.9),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			{ canCollide = true }
		)
	end

	-- Dual golden + cyan floor rings
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"SanctumGoldRing",
		CFrame.new(0, 0.84, -1.4),
		7.4,
		14,
		0.38,
		0.08,
		PALETTE.gold,
		PALETTE.goldBright,
		Enum.Material.SmoothPlastic
	)
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"SanctumCyanRing",
		CFrame.new(0, 0.82, -1.4),
		12.6,
		16,
		0.46,
		0.08,
		PALETTE.cyan,
		PALETTE.lilac,
		Enum.Material.Neon
	)

	-- 5 Soaring Faceted Crystal Arches sweeping around the amphitheater curve!
	local archSpecs = {
		{ deg = 66, h = 13.5, span = 8.4, colA = PALETTE.cyan, colB = PALETTE.cyanDeep },
		{ deg = 122, h = 16.5, span = 9.4, colA = PALETTE.lilac, colB = PALETTE.purple },
		{ deg = 180, h = 20.5, span = 11.2, colA = PALETTE.cyan, colB = PALETTE.cyanDeep },
		{ deg = 238, h = 16.5, span = 9.4, colA = PALETTE.lilac, colB = PALETTE.purple },
		{ deg = 294, h = 13.5, span = 8.4, colA = PALETTE.cyan, colB = PALETTE.cyanDeep },
	}
	for _, spec in archSpecs do
		local ang = math.rad(spec.deg)
		local r = 13.6
		local pos = Vector3.new(math.sin(ang) * r, 0.72, math.cos(ang) * r - 1.4)
		buildCrystalArch(ctx, pos, spec.deg, spec.span, spec.h, spec.colA, spec.colB)
	end

	-- 4 Tall Stone & Gold Brazier Pillars with Blue Neon Flames + 4 ParticleEmitters!
	local brazierAngles = { 42, 148, 212, 318 }
	for i, deg in brazierAngles do
		local ang = math.rad(deg)
		local r = 11.4
		local px = math.sin(ang) * r
		local pz = math.cos(ang) * r - 1.4
		addPart(
			ctx.structure,
			ctx.origin,
			"BrazierBase_" .. tostring(i),
			Vector3.new(2.4, 1.3, 2.4),
			CFrame.new(px, 1.35, pz) * CFrame.Angles(0, ang, 0),
			PALETTE.stoneMid,
			Enum.Material.Slate
		)
		addCyl(
			ctx.structure,
			ctx.origin,
			"BrazierShaft_" .. tostring(i),
			6.2,
			1.45,
			px,
			5.05,
			pz,
			PALETTE.basalt,
			Enum.Material.Slate,
			{ castShadow = true }
		)
		addCyl(
			ctx.structure,
			ctx.origin,
			"BrazierBowl_" .. tostring(i),
			0.95,
			2.6,
			px,
			8.45,
			pz,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		local flame = addPart(
			ctx.light,
			ctx.origin,
			"BlueFlameCore_" .. tostring(i),
			Vector3.new(1.5, 2.4, 1.5),
			CFrame.new(px, 10.1, pz) * CFrame.Angles(0, math.rad(45), 0),
			PALETTE.cyan,
			Enum.Material.Neon
		)
		addPart(
			ctx.light,
			ctx.origin,
			"BlueFlameTip_" .. tostring(i),
			Vector3.new(0.85, 1.6, 0.85),
			CFrame.new(px, 11.45, pz) * CFrame.Angles(math.rad(10), math.rad(20), math.rad(-8)),
			PALETTE.white,
			Enum.Material.Neon
		)
		if i == 2 or i == 3 then
			addLight(flame, PALETTE.cyan, 1.85, 44)
		end
		addEmitter(
			flame,
			"BlueFlameEmitter_" .. tostring(i),
			PALETTE.cyan,
			PALETTE.lilac,
			13,
			3.0,
			6.0,
			0.65,
			0.06,
			0.9,
			1.6,
			22
		)
	end

	-- Flanking crystal clusters between the arches
	for i, deg in { 94, 152, 208, 266 } do
		local ang = math.rad(deg)
		local r = 14.8
		buildCrystalCluster(
			ctx,
			Vector3.new(math.sin(ang) * r, 0.62, math.cos(ang) * r - 1.4),
			1.55,
			if i % 2 == 0 then PALETTE.lilac else PALETTE.cyan,
			PALETTE.cyanDeep,
			3
		)
	end
end

-- Level 9: Plataforma flutuante (<= 240 parts total, 2 lights, 5 emitters)
local function buildLevel09(ctx: BuildCtx)
	local LIFT = 3.0 -- entire sanctuary levitates 3 studs above ground!

	-- Floating stepped stone-and-gold arena floor at Y = LIFT
	addCyl(
		ctx.floor,
		ctx.origin,
		"FloatingArenaRim",
		0.72,
		31.6,
		0,
		LIFT - 0.36,
		-1.6,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"FloatingArenaDeck",
		0.44,
		29.2,
		0,
		LIFT - 0.14,
		-1.6,
		PALETTE.marble,
		Enum.Material.Marble,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"FloatingCenterSlate",
		0.12,
		15.2,
		0,
		LIFT + 0.12,
		-1.6,
		PALETTE.basalt,
		Enum.Material.Slate,
		{ canCollide = true }
	)

	-- Graceful Glowing Crystal Bridge Steps on +Z so the player walks right up from Y = 0 to LIFT!
	local stepCount = 6
	for k = 1, stepCount do
		local t = k / stepCount
		local yTop = LIFT * t
		local zPos = 19.2 - (k - 1) * 1.18
		addPart(
			ctx.floor,
			ctx.origin,
			"FloatStep_" .. tostring(k),
			Vector3.new(9.2 - k * 0.2, 0.44, 1.45),
			CFrame.new(0, yTop - 0.22, zPos),
			if k % 2 == 0 then PALETTE.marble else PALETTE.cyan,
			if k % 2 == 0 then Enum.Material.Marble else Enum.Material.Neon,
			{ canCollide = true }
		)
	end

	-- Underside sculpted levitating bedrock cone + 6 hovering rock shards with cyan glow cores!
	addCyl(
		ctx.structure,
		ctx.origin,
		"UndersideRockCore",
		1.8,
		18.5,
		0,
		LIFT - 1.65,
		-1.6,
		PALETTE.basalt,
		Enum.Material.Rock
	)
	addCyl(
		ctx.structure,
		ctx.origin,
		"UndersideCrystalCore",
		1.2,
		10.2,
		0,
		LIFT - 2.35,
		-1.6,
		PALETTE.cyan,
		Enum.Material.Neon
	)
	for i = 0, 5 do
		local ang = math.rad(i * 60 + 25)
		local r = 13.4 + (i % 2) * 2.2
		local rx = math.sin(ang) * r
		local rz = math.cos(ang) * r - 1.6
		local ry = 0.95 + (i % 3) * 0.48
		addPart(
			ctx.structure,
			ctx.origin,
			"FloatRock_" .. tostring(i + 1),
			Vector3.new(3.8, 1.85, 3.4),
			CFrame.new(rx, ry, rz) * CFrame.Angles(math.rad(8), ang, math.rad(-6)),
			PALETTE.basalt,
			Enum.Material.Rock
		)
		addPart(
			ctx.decor,
			ctx.origin,
			"FloatRockCrystal_" .. tostring(i + 1),
			Vector3.new(1.4, 1.15, 1.4),
			CFrame.new(rx, ry - 1.05, rz) * CFrame.Angles(0, ang + math.rad(45), 0),
			PALETTE.cyan,
			Enum.Material.Neon
		)
	end

	-- 6 Floating perimeter crystal pylons around the levitating edge
	local pylonAngles = { 56, 106, 154, 206, 254, 304 }
	for i, deg in pylonAngles do
		local ang = math.rad(deg)
		local r = 14.4
		local px = math.sin(ang) * r
		local pz = math.cos(ang) * r - 1.6
		addPart(
			ctx.structure,
			ctx.origin,
			"SkyPylon_" .. tostring(i),
			Vector3.new(1.65, 8.8, 1.65),
			CFrame.new(px, LIFT + 4.4, pz) * CFrame.Angles(0, ang, 0),
			PALETTE.marble,
			Enum.Material.Marble,
			{ castShadow = true }
		)
		local tip = addPart(
			ctx.decor,
			ctx.origin,
			"SkyPylonGem_" .. tostring(i),
			Vector3.new(1.3, 2.3, 1.3),
			CFrame.new(px, LIFT + 10.6, pz) * CFrame.Angles(math.rad(15), ang + math.rad(45), 0),
			if i % 2 == 0 then PALETTE.pink else PALETTE.cyan,
			Enum.Material.Neon
		)
		if i == 3 or i == 4 then
			addLight(tip, PALETTE.cyan, 1.9, 48)
		end
	end

	-- 3 Massive Tilted Orbiting Rings encircling the levitating arena!
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"OrbitRingOuter",
		CFrame.new(0, LIFT + 9.8, -1.6) * CFrame.Angles(math.rad(18), 0, math.rad(14)),
		19.4,
		18,
		0.72,
		0.52,
		PALETTE.goldBright,
		PALETTE.cyan,
		Enum.Material.Neon
	)
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"OrbitRingMid",
		CFrame.new(0, LIFT + 12.6, -1.6) * CFrame.Angles(math.rad(-22), math.rad(25), math.rad(-18)),
		15.2,
		14,
		0.58,
		0.48,
		PALETTE.lilac,
		PALETTE.pink,
		Enum.Material.Neon
	)
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"OrbitRingHalo",
		CFrame.new(0, LIFT + 18.2, -10.5) * CFrame.Angles(math.rad(72), 0, 0),
		6.8,
		12,
		0.54,
		0.54,
		PALETTE.cyan,
		PALETTE.goldBright,
		Enum.Material.Neon
	)

	-- Sweeping Translucent Aurora Borealis Curtain arching high in the backdrop (-Z)!
	local auroraColors = {
		PALETTE.teal,
		PALETTE.cyan,
		PALETTE.lilac,
		PALETTE.pink,
		PALETTE.cyan,
		PALETTE.teal,
	}
	for i = 1, 6 do
		local t = (i - 3.5) / 2.5
		local ax = t * 14.5
		local az = -17.5 + (t * t) * 4.2
		local ay = LIFT + 16.5 + math.cos(t * 1.4) * 3.2
		addPart(
			ctx.light,
			ctx.origin,
			"AuroraCurtain_" .. tostring(i),
			Vector3.new(6.8, 12.8, 0.35),
			CFrame.new(ax, ay, az)
				* CFrame.Angles(math.rad(-10), math.rad(-t * 24), math.rad(t * 8)),
			auroraColors[i],
			Enum.Material.Neon,
			{ transparency = 0.56 }
		)
	end

	-- 5 ParticleEmitters (2 antigrav rise under platform, 2 aurora shimmer, 1 central stardust)
	for i, pos in
		{
			Vector3.new(-8.5, LIFT - 1.2, -1.6),
			Vector3.new(8.5, LIFT - 1.2, -1.6),
			Vector3.new(-7.5, LIFT + 15.0, -15.5),
			Vector3.new(7.5, LIFT + 15.0, -15.5),
			Vector3.new(0, LIFT + 1.2, -1.6),
		}
	do
		local host = addPart(
			ctx.light,
			ctx.origin,
			"FloatVfxHost_" .. tostring(i),
			Vector3.new(4, 0.4, 4),
			CFrame.new(pos),
			PALETTE.cyan,
			Enum.Material.SmoothPlastic,
			{ transparency = 1 }
		)
		addEmitter(
			host,
			"SkyMotes_" .. tostring(i),
			if i <= 2 then PALETTE.cyan else PALETTE.pink,
			if i <= 2 then PALETTE.white else PALETTE.cyan,
			10,
			1.4,
			3.8,
			0.45,
			0.06,
			1.6,
			2.8,
			40
		)
	end
end

-- Level 10: Santuario do Pescador Lendario (<= 250 parts total, 2 lights, 5 emitters)
local function buildLevel10(ctx: BuildCtx)
	-- Monumental raised sanctuary podium + RAINBOW GRADIENT MOSAIC FLOOR (12 radial wedges!)
	addCyl(
		ctx.floor,
		ctx.origin,
		"SanctuaryOuterPlinth",
		0.92,
		34.8,
		0,
		0.36,
		-1.6,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		{ canCollide = true }
	)
	addCyl(
		ctx.floor,
		ctx.origin,
		"SanctuaryMarbleDeck",
		0.48,
		32.0,
		0,
		1.02,
		-1.6,
		PALETTE.marble,
		Enum.Material.Marble,
		{ canCollide = true }
	)

	-- Concentric stepped Rainbow Mosaic Floor (6 tiers of Config/Training TIER_COLORS, zero z-fight)
	for i = 1, 6 do
		local dia = 25.4 - (i - 1) * 3.4
		local yPos = 1.26 + i * 0.045
		addCyl(
			ctx.floor,
			ctx.origin,
			"RainbowFloorTier_" .. tostring(i),
			0.08,
			dia,
			0,
			yPos,
			-1.6,
			RAINBOW[i],
			if i == 6 then Enum.Material.Neon else Enum.Material.SmoothPlastic,
			{ canCollide = true }
		)
	end
	-- Grand golden front steps (3 tiers)
	for k = 1, 3 do
		addPart(
			ctx.floor,
			ctx.origin,
			"SanctuaryStep_" .. tostring(k),
			Vector3.new(12.2 - k * 0.45, 0.42, 1.9),
			CFrame.new(0, 0.21 + (k - 1) * 0.4, 18.2 - (k - 1) * 1.65),
			if k == 2 then PALETTE.gold else PALETTE.marble,
			if k == 2 then Enum.Material.SmoothPlastic else Enum.Material.Marble,
			{ canCollide = true }
		)
	end

	-- 8 Monumental Fluted White-Marble & Gleaming Gold Classical Columns!
	local colAngles = { 46, 82, 118, 156, 204, 242, 278, 314 }
	local colR = 15.2
	local colH = 16.5
	local colTops: { Vector3 } = {}
	for i, deg in colAngles do
		local ang = math.rad(deg)
		local px = math.sin(ang) * colR
		local pz = math.cos(ang) * colR - 1.6
		-- Pedestal
		addPart(
			ctx.structure,
			ctx.origin,
			"ColumnPlinth_" .. tostring(i),
			Vector3.new(3.0, 1.5, 3.0),
			CFrame.new(px, 2.0, pz) * CFrame.Angles(0, ang, 0),
			PALETTE.marble,
			Enum.Material.Marble,
			{ castShadow = true }
		)
		-- Golden collar low
		addCyl(
			ctx.structure,
			ctx.origin,
			"ColumnBaseRing_" .. tostring(i),
			0.45,
			2.45,
			px,
			2.98,
			pz,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		-- Tall white marble shaft
		addCyl(
			ctx.structure,
			ctx.origin,
			"ColumnShaft_" .. tostring(i),
			colH,
			1.95,
			px,
			3.2 + colH * 0.5,
			pz,
			PALETTE.marble,
			Enum.Material.Marble,
			{ castShadow = true }
		)
		-- Glowing gold/cyan energy ring mid-column
		addCyl(
			ctx.decor,
			ctx.origin,
			"ColumnGlowBand_" .. tostring(i),
			0.42,
			2.12,
			px,
			3.2 + colH * 0.52,
			pz,
			if i % 2 == 0 then PALETTE.goldBright else PALETTE.cyan,
			Enum.Material.Neon
		)
		-- Lotus Golden Capital
		addPart(
			ctx.structure,
			ctx.origin,
			"ColumnCapital_" .. tostring(i),
			Vector3.new(3.1, 1.15, 3.1),
			CFrame.new(px, 3.2 + colH + 0.55, pz) * CFrame.Angles(0, ang, 0),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		table.insert(colTops, Vector3.new(px, 3.2 + colH + 1.35, pz))
	end

	-- Sweeping Golden Architrave beams linking the columns around the rear arc
	for i = 1, #colTops - 1 do
		addSpan(
			ctx.structure,
			ctx.origin,
			"Architrave_" .. tostring(i),
			colTops[i],
			colTops[i + 1],
			1.65,
			1.15,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end

	-- GIANT LEVITATING CRYSTAL & GOLD CROWN suspended high at the Sanctuary Apex!
	local crownCenter = Vector3.new(0, 26.8, -5.8)
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"CrownBaseBand",
		CFrame.new(crownCenter),
		6.4,
		12,
		1.05,
		1.85,
		PALETTE.gold,
		PALETTE.goldBright,
		Enum.Material.SmoothPlastic
	)
	buildRingSegments(
		ctx.decor,
		ctx.origin,
		"CrownNeonRim",
		CFrame.new(crownCenter + Vector3.new(0, 1.15, 0)),
		6.45,
		12,
		0.45,
		0.38,
		PALETTE.cyan,
		PALETTE.pink,
		Enum.Material.Neon
	)
	-- 8 Tall Crown Spires (alternating giant prismatic cyan & gold crystal points!)
	for i = 0, 7 do
		local ang = math.rad(i * 45)
		local isMajor = (i % 2 == 0)
		local spireH = if isMajor then 7.6 else 4.8
		local sx = crownCenter.X + math.sin(ang) * 6.3
		local sz = crownCenter.Z + math.cos(ang) * 6.3
		addPart(
			ctx.decor,
			ctx.origin,
			"CrownSpire_" .. tostring(i + 1),
			Vector3.new(if isMajor then 1.55 else 1.1, spireH, if isMajor then 1.55 else 1.1),
			CFrame.new(sx, crownCenter.Y + 1.4 + spireH * 0.48, sz)
				* CFrame.Angles(math.rad(-10 * math.cos(ang)), ang, math.rad(10 * math.sin(ang))),
			if isMajor then PALETTE.cyan else PALETTE.goldBright,
			Enum.Material.Neon
		)
		if isMajor then
			addPart(
				ctx.decor,
				ctx.origin,
				"CrownJewel_" .. tostring(i + 1),
				Vector3.new(1.5, 1.5, 1.5),
				CFrame.new(
					crownCenter.X + math.sin(ang) * 7.0,
					crownCenter.Y + 1.8 + spireH,
					crownCenter.Z + math.cos(ang) * 7.0
				),
				PALETTE.pink,
				Enum.Material.Neon,
				{ shape = Enum.PartType.Ball }
			)
		end
	end
	-- Colossal floating prismatic heart crystal in the center of the crown
	local crownHeart = addPart(
		ctx.light,
		ctx.origin,
		"CrownHeartCrystal",
		Vector3.new(3.2, 6.2, 3.2),
		CFrame.new(crownCenter + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, math.rad(45), 0),
		PALETTE.goldBright,
		Enum.Material.Neon
	)
	addLight(crownHeart, PALETTE.goldBright, 2.1, 60)

	-- 5 Dramatic Angled Golden/Prismatic Light-Ray Shafts fanning down from the Crown!
	local raySpecs = {
		{ x = 0, z = -3.8, yaw = 0, tilt = 6, col = PALETTE.goldBright },
		{ x = -5.8, z = -5.2, yaw = 18, tilt = 16, col = PALETTE.cyan },
		{ x = 5.8, z = -5.2, yaw = -18, tilt = -16, col = PALETTE.pink },
		{ x = -3.2, z = -9.6, yaw = 10, tilt = 12, col = PALETTE.lilac },
		{ x = 3.2, z = -9.6, yaw = -10, tilt = -12, col = PALETTE.teal },
	}
	for i, r in raySpecs do
		addPart(
			ctx.light,
			ctx.origin,
			"SunbeamRay_" .. tostring(i),
			Vector3.new(2.2, 24.5, 2.2),
			CFrame.new(r.x, 14.5, r.z) * CFrame.Angles(0, math.rad(r.yaw), math.rad(r.tilt)),
			r.col,
			Enum.Material.Neon,
			{ transparency = 0.78 }
		)
	end

	-- Second PointLight at the rear sanctuary altar + twin grand royal banners
	local altarGem = addPart(
		ctx.light,
		ctx.origin,
		"SanctuaryAltarOrb",
		Vector3.new(2.2, 2.2, 2.2),
		CFrame.new(0, 6.4, -14.2),
		PALETTE.cyan,
		Enum.Material.Neon,
		{ shape = Enum.PartType.Ball }
	)
	addLight(altarGem, PALETTE.cyan, 1.85, 48)
	addCyl(
		ctx.structure,
		ctx.origin,
		"AltarPedestal",
		4.2,
		2.8,
		0,
		3.35,
		-14.2,
		PALETTE.marble,
		Enum.Material.Marble
	)

	-- 4 Entrance golden crystal torches flanking the grand steps
	for i, pt in
		{
			Vector3.new(-7.6, 1.25, 13.4),
			Vector3.new(7.6, 1.25, 13.4),
			Vector3.new(-12.2, 1.25, 8.8),
			Vector3.new(12.2, 1.25, 8.8),
		}
	do
		addCyl(
			ctx.structure,
			ctx.origin,
			"RoyalTorchBase_" .. tostring(i),
			4.6,
			1.1,
			pt.X,
			pt.Y + 2.3,
			pt.Z,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		addPart(
			ctx.decor,
			ctx.origin,
			"RoyalTorchFlame_" .. tostring(i),
			Vector3.new(1.2, 1.8, 1.2),
			CFrame.new(pt + Vector3.new(0, 5.4, 0)) * CFrame.Angles(0, math.rad(45), 0),
			if i <= 2 then PALETTE.goldBright else PALETTE.cyan,
			Enum.Material.Neon
		)
	end

	-- 5 Dazzling ParticleEmitters (crown stardust, prismatic rain, altar radiance, 2 floor arcs)
	addEmitter(
		crownHeart,
		"CrownStardust",
		PALETTE.goldBright,
		PALETTE.cyan,
		15,
		2.0,
		5.0,
		0.62,
		0.08,
		1.8,
		3.2,
		75
	)
	addEmitter(
		altarGem,
		"AltarRadiance",
		PALETTE.cyan,
		PALETTE.pink,
		12,
		1.6,
		3.8,
		0.48,
		0.06,
		1.6,
		2.8,
		60
	)
	for i, pos in
		{
			Vector3.new(-8.0, 2.2, -1.6),
			Vector3.new(8.0, 2.2, -1.6),
			Vector3.new(0, 2.2, -1.6),
		}
	do
		local host = addPart(
			ctx.light,
			ctx.origin,
			"SanctuaryVfx_" .. tostring(i),
			Vector3.new(6, 0.3, 6),
			CFrame.new(pos),
			PALETTE.goldBright,
			Enum.Material.SmoothPlastic,
			{ transparency = 1 }
		)
		addEmitter(
			host,
			"PrismaticAscent_" .. tostring(i),
			if i == 3 then PALETTE.goldBright else PALETTE.pink,
			if i == 3 then PALETTE.white else PALETTE.cyan,
			9,
			1.5,
			4.2,
			0.42,
			0.05,
			1.8,
			3.0,
			25
		)
	end
end

local BUILDERS: { [number]: (BuildCtx) -> () } = {
	[1] = buildLevel01,
	[2] = buildLevel02,
	[3] = buildLevel03,
	[4] = buildLevel04,
	[5] = buildLevel05,
	[6] = buildLevel06,
	[7] = buildLevel07,
	[8] = buildLevel08,
	[9] = buildLevel09,
	[10] = buildLevel10,
}

local function buildOneLevel(meta: LevelMeta, origin: CFrame): Model
	local levelModel = Instance.new("Model")
	levelModel.Name = meta.id
	levelModel:SetAttribute("LevelIndex", meta.index)
	levelModel:SetAttribute("LevelId", meta.id)
	levelModel:SetAttribute("LevelName", meta.name)
	levelModel:SetAttribute("PlayableRadius", meta.radius)
	levelModel:SetAttribute("GeneratedBy", TAG_BUILT)

	local originPart = makeMarker(
		levelModel,
		origin,
		"TrainingOrigin",
		Vector3.new(2, 0.5, 2),
		CFrame.new(0, 0, 0)
	)
	levelModel.PrimaryPart = originPart
	levelModel.WorldPivot = origin

	local anchors = Instance.new("Folder")
	anchors.Name = "Anchors"
	anchors.Parent = levelModel

	-- InspectCamera looking back at the arena from front-right 3/4 view
	local camLocalCF = CFrame.lookAt(meta.camOffset, Vector3.new(0, meta.camTargetY, -1.5))
	makeMarker(anchors, origin, "InspectCamera", Vector3.new(1.5, 1.5, 1.5), camLocalCF)

	-- UpgradeBoard facing inward toward approaching player
	local boardCF = CFrame.lookAt(
		meta.boardPos + Vector3.new(0, 2.8, 0),
		Vector3.new(0, meta.boardPos.Y + 2.8, meta.boardPos.Z + 8)
	)
	makeMarker(anchors, origin, "UpgradeBoard", Vector3.new(4, 5, 0.5), boardCF)

	-- 6 DecorAnchors spaced around the horseshoe perimeter (leaving +Z approach open)
	local decorAngles = { 55, 105, 152, 208, 255, 305 }
	for i, deg in decorAngles do
		local ang = math.rad(deg)
		local pos = Vector3.new(
			math.sin(ang) * meta.anchorRadius,
			meta.boardPos.Y,
			math.cos(ang) * meta.anchorRadius - 1.0
		)
		local dCF = CFrame.lookAt(pos, Vector3.new(0, meta.boardPos.Y, -1.0))
		makeMarker(
			anchors,
			origin,
			string.format("DecorAnchor_%02d", i),
			Vector3.new(2, 0.5, 2),
			dCF
		)
	end

	local floor = Instance.new("Model")
	floor.Name = "Layer_00_Floor"
	floor.Parent = levelModel

	local structure = Instance.new("Model")
	structure.Name = "Layer_01_Structure"
	structure.Parent = levelModel

	local decor = Instance.new("Model")
	decor.Name = "Layer_02_Decor"
	decor.Parent = levelModel

	local light = Instance.new("Model")
	light.Name = "Layer_03_Light"
	light.Parent = levelModel

	local ctx: BuildCtx = {
		origin = origin,
		floor = floor,
		structure = structure,
		decor = decor,
		light = light,
	}
	BUILDERS[meta.index](ctx)

	return levelModel
end

-- Detects the hub's TrainingSpot CFrame, oriented with +Z pointing toward the CentralPlaza.
local function detectHubOrigin(): CFrame
	local island = Workspace:FindFirstChild("Island")
	local lagoon = island and island:FindFirstChild("TrainingLagoon")
	local spot: BasePart? = nil
	if lagoon then
		local found = lagoon:FindFirstChild("TrainingSpot", true)
		if found and found:IsA("BasePart") then
			spot = found
		end
	end
	if not spot then
		for _, inst in CollectionService:GetTagged("TrainingSpot") do
			if
				inst:IsA("BasePart")
				and (
					inst:GetAttribute("TrainingIsland") == nil
					or inst:GetAttribute("TrainingIsland") == 1
				)
			then
				spot = inst
				break
			end
		end
	end
	if not spot then
		return DEFAULT_ORIGIN
	end
	-- Face +Z toward CentralPlaza (-6, y, 4) so the open approach faces the plaza!
	-- Raycast down to seat TrainingOrigin cleanly (+0.04 studs) on the walkable deck.
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { spot }
	local hit = Workspace:Raycast(spot.Position + Vector3.new(0, 4, 0), Vector3.new(0, -18, 0), rp)
	local baseY = if hit then hit.Position.Y + 0.04 else HUB_DECK_Y
	local p = Vector3.new(spot.Position.X, baseY, spot.Position.Z)
	local plazaTarget = Vector3.new(-6, p.Y, 4)
	local toPlaza = plazaTarget - p
	if toPlaza.Magnitude < 0.1 then
		toPlaza = Vector3.new(1, 0, 0)
	end
	-- CFrame.lookAt faces -Z toward target; looking AWAY from plaza makes +Z point AT plaza!
	return CFrame.lookAt(p, p - toPlaza.Unit)
end

local function auditLevel(
	levelModel: Model,
	meta: LevelMeta
): {
	id: string,
	parts: number,
	visibleParts: number,
	lights: number,
	emitters: number,
	scripts: number,
	tags: number,
	badColliders: number,
	ok: boolean,
}
	local parts, visibleParts, lights, emitters, scripts, tags, badColliders = 0, 0, 0, 0, 0, 0, 0
	local floor = levelModel:FindFirstChild("Layer_00_Floor")
	for _, d in levelModel:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
			if d.Transparency < 0.95 then
				visibleParts += 1
			end
			local inFloor = floor ~= nil and d:IsDescendantOf(floor)
			if d.CanCollide and not inFloor then
				badColliders += 1
			end
		elseif d:IsA("Light") then
			lights += 1
		elseif d:IsA("ParticleEmitter") then
			emitters += 1
		elseif d:IsA("BaseScript") then
			scripts += 1
		end
		if #CollectionService:GetTags(d) > 0 then
			tags += #CollectionService:GetTags(d)
		end
	end
	local ok = parts <= meta.maxParts
		and lights <= meta.maxLights
		and emitters <= meta.maxEmitters
		and scripts == 0
		and tags == 0
		and badColliders == 0
	return {
		id = meta.id,
		parts = parts,
		visibleParts = visibleParts,
		lights = lights,
		emitters = emitters,
		scripts = scripts,
		tags = tags,
		badColliders = badColliders,
		ok = ok,
	}
end

local Builder = {}

Builder.LEVELS = LEVELS
Builder.detectHubOrigin = detectHubOrigin
Builder.auditLevel = auditLevel

function Builder.ensureRoot(): Folder
	local root = ReplicatedStorage:FindFirstChild("TrainingLevels")
	if not root then
		local f = Instance.new("Folder")
		f.Name = "TrainingLevels"
		f.Parent = ReplicatedStorage
		root = f
	end
	local levels = (root :: Instance):FindFirstChild("Levels")
	if not levels then
		local f = Instance.new("Folder")
		f.Name = "Levels"
		f.Parent = root
		levels = f
	end
	return levels :: Folder
end

function Builder.run(originOverride: CFrame?, onlyLevels: { number }?): ({ any }, CFrame)
	local origin = originOverride or detectHubOrigin()
	local levelsFolder = Builder.ensureRoot()

	local filter: { [number]: boolean }? = nil
	if onlyLevels then
		filter = {}
		for _, idx in onlyLevels do
			(filter :: { [number]: boolean })[idx] = true
		end
	end

	local reports = {}
	for _, meta in LEVELS do
		if not filter or filter[meta.index] then
			local existing = levelsFolder:FindFirstChild(meta.id)
			if existing then
				existing:Destroy()
			end
			local built = buildOneLevel(meta, origin)
			built.Parent = levelsFolder
			table.insert(reports, auditLevel(built, meta))
			task.wait()
		end
	end
	return reports, origin
end

function Builder.clearPreview()
	local old = Workspace:FindFirstChild("_TrainingFieldPreview")
	if old then
		old:Destroy()
	end
end

function Builder.preview(levelIndex: number, targetOrigin: CFrame?): Model?
	Builder.clearPreview()
	local levelsFolder = Builder.ensureRoot()
	local id = string.format("training_lv%02d", levelIndex)
	local src = levelsFolder:FindFirstChild(id)
	if not (src and src:IsA("Model")) then
		return nil
	end
	local clone = src:Clone()
	clone.Name = "_TrainingFieldPreview"
	if targetOrigin then
		clone:PivotTo(targetOrigin)
	end
	clone.Parent = Workspace
	return clone
end

return Builder
