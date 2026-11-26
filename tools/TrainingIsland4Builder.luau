--!strict
-- TrainingIsland4Builder.luau
-- Training Island 4 "Celestial" (x50 training, needs 1T Fishing Power) for Legendary Catch.
-- Floating sky island over a sea of clouds: grass top, cream marble rim with two gold trims,
-- sculpted light rock with gold/cyan crystals, light waterfalls, a double golden orbit ring,
-- floating islets, a winged marble/gold portal and two light ponds (Focus / Instinct).
-- Everything is built by code, relative to `origin`. No scripts are created.
--
-- Usage (command bar / dev tool):
--   local B = require(game.ServerStorage.DevTools.TrainingIsland4Builder)
--   B.build()
--   print(table.concat(B.selfTest(), "\n"))

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Builder = {}

-- ============================================================================
-- Config
-- ============================================================================
local MODEL_NAME = "TrainingIsland_Celestial"
local FOLDER_NAME = "TrainingIslands"
local DEFAULT_ORIGIN = Vector3.new(0, 160, -680)
local SEED = 40404
local RX = 50 -- island half width (X)
local RZ = 42 -- island half depth (Z)
local EDGE_SEGMENTS = 72
local PART_LIMIT = 9000
local SQRT3 = math.sqrt(3)
local TAU = math.pi * 2

local PALETTE = {
	-- Warm, saturated palette tuned to look rich under normal game Lighting (Brightness=3, cool OutdoorAmbient)
	grass = Color3.fromRGB(78, 174, 48),
	grassDark = Color3.fromRGB(54, 138, 40),
	grassLight = Color3.fromRGB(116, 202, 58),
	grassBlade = Color3.fromRGB(66, 156, 44),
	marble = Color3.fromRGB(248, 236, 214),
	marbleShade = Color3.fromRGB(224, 206, 180),
	marbleDark = Color3.fromRGB(186, 164, 138),
	gold = Color3.fromRGB(234, 168, 36),
	goldLight = Color3.fromRGB(255, 212, 78),
	goldDeep = Color3.fromRGB(178, 112, 20),
	goldGlow = Color3.fromRGB(255, 194, 62),
	rockTop = Color3.fromRGB(182, 146, 122),
	rockHighlight = Color3.fromRGB(214, 178, 150),
	rockBottom = Color3.fromRGB(108, 82, 98),
	rockCore = Color3.fromRGB(80, 58, 74),
	rockCrack = Color3.fromRGB(70, 50, 64),
	crystalGold = Color3.fromRGB(255, 184, 34),
	crystalCyan = Color3.fromRGB(48, 214, 255),
	crystalPale = Color3.fromRGB(152, 232, 255),
	crystalPink = Color3.fromRGB(255, 132, 214),
	focusWater = Color3.fromRGB(122, 224, 240),
	focusDeep = Color3.fromRGB(58, 176, 212),
	focusGlow = Color3.fromRGB(186, 246, 252),
	focusCore = Color3.fromRGB(255, 242, 194),
	instinctWater = Color3.fromRGB(118, 42, 186),
	instinctDeep = Color3.fromRGB(64, 20, 136),
	instinctMid = Color3.fromRGB(182, 54, 170),
	instinctGlow = Color3.fromRGB(238, 102, 152),
	instinctGold = Color3.fromRGB(255, 196, 92),
	canalWater = Color3.fromRGB(118, 226, 246),
	falls = Color3.fromRGB(178, 240, 255),
	wood = Color3.fromRGB(174, 114, 58),
	woodLight = Color3.fromRGB(216, 170, 112),
	woodDark = Color3.fromRGB(124, 76, 38),
	goldWood = Color3.fromRGB(214, 146, 54),
	rope = Color3.fromRGB(224, 184, 102),
	lantern = Color3.fromRGB(255, 154, 38),
	lanternGlass = Color3.fromRGB(255, 196, 94),
	blossom = Color3.fromRGB(248, 134, 184),
	blossomLight = Color3.fromRGB(255, 192, 220),
	blossomDeep = Color3.fromRGB(214, 88, 148),
	cloudCream = Color3.fromRGB(252, 224, 204),
	cloudPink = Color3.fromRGB(240, 174, 202),
	cloudLilac = Color3.fromRGB(178, 156, 218),
	cloudBlue = Color3.fromRGB(142, 156, 214),
	cloudSunset = Color3.fromRGB(255, 206, 168),
	pastelPink = Color3.fromRGB(255, 106, 182),
	pastelPeach = Color3.fromRGB(255, 154, 88),
	pastelLemon = Color3.fromRGB(255, 218, 76),
	pastelMint = Color3.fromRGB(76, 228, 168),
	pastelAqua = Color3.fromRGB(66, 204, 255),
	pastelLilac = Color3.fromRGB(164, 118, 255),
	fabric = Color3.fromRGB(246, 236, 218),
	stone = Color3.fromRGB(172, 164, 166),
	stoneDark = Color3.fromRGB(132, 124, 130),
	runeInk = Color3.fromRGB(98, 52, 20),
	eye = Color3.fromRGB(48, 28, 44),
}

-- Island layout (local coordinates, playable ground at Y = 0)
local FOCUS_C = Vector3.new(-22.5, 0, 2)
local FOCUS_R = 14.2
local INSTINCT_C = Vector3.new(22.5, 0, 2)
local INSTINCT_R = 14.6
local PORTAL_Z = -34.8
local STEP_TOP = 1.8
local SPAWN_POS = Vector3.new(0, 0.75, -22) -- sits on a path tile (top 0.25)
local BRIDGE_Z0 = -6
local BRIDGE_Z1 = 10
local BRIDGE_RISE = 2.6
local BRIDGE_W = 5.4
local BRIDGE_BASE = 0.3
local DECK_TOP = 0.85
local DECK_LEN_OUT = 4.2
local DECK_LEN_IN = 5.2
local DECK_W = 6.6
local FOCUS_DECK_ANGLE = 122
local INSTINCT_DECK_ANGLE = -48
local RING_Y = -4.8
local TREE_BASE = Vector3.new(38.5, 0, -16.5)
local CROWN_BASE = Vector3.new(-6.2, 0, 23.8)
local CAMERA_POS = Vector3.new(0, 48, 100)

-- Animation tags (consumed by the game's existing animator)
local TAG_SPIN = "HubSpin"
local TAG_BOB = "HubBob"
local TAG_PULSE = "HubPulse"
local TAG_FLICKER = "HubFlicker"
local TAG_SWAY = "HubSway"

-- ============================================================================
-- Runtime state (reset on every build)
-- ============================================================================
type Zone = { a: Vector3, b: Vector3, r: number }

local rng = Random.new(SEED)
local ORIGIN_CF = CFrame.new()
local zones: { Zone } = {}
local animatedCount = 0

local function rand(a: number, b: number): number
	return rng:NextNumber(a, b)
end

local function randInt(a: number, b: number): number
	return rng:NextInteger(a, b)
end

local function pickColor(list: { Color3 }): Color3
	return list[rng:NextInteger(1, #list)]
end

local function jitter(c: Color3, amount: number): Color3
	local r = math.clamp(c.R + rng:NextNumber(-amount, amount), 0, 1)
	local g = math.clamp(c.G + rng:NextNumber(-amount, amount), 0, 1)
	local b = math.clamp(c.B + rng:NextNumber(-amount, amount), 0, 1)
	return Color3.new(r, g, b)
end

local function v3(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

-- ============================================================================
-- Generic helpers
-- ============================================================================
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

local function finishPart(
	p: BasePart,
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean?,
	transparency: number?
)
	local collide = canCollide == true
	local t = transparency or 0
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = ORIGIN_CF * cf
	p.Color = color
	p.Material = material
	p.Transparency = t
	p.CanCollide = collide
	p.CanTouch = false
	p.CanQuery = collide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = collide
		or (
			t < 0.05
			and material ~= Enum.Material.Neon
			and material ~= Enum.Material.Glass
			and size.X * size.Y * size.Z > 40
		)
	p.Parent = parent
end

local function makePart(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean?,
	transparency: number?
): Part
	local p = Instance.new("Part")
	finishPart(p, parent, name, cf, size, color, material, canCollide, transparency)
	return p
end

local function makeWedge(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean?,
	transparency: number?
): WedgePart
	local p = Instance.new("WedgePart")
	finishPart(p, parent, name, cf, size, color, material, canCollide, transparency)
	return p
end

local function makeBall(
	parent: Instance,
	name: string,
	pos: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	finishPart(
		p,
		parent,
		name,
		CFrame.new(pos),
		v3(diameter, diameter, diameter),
		color,
		material,
		false,
		transparency
	)
	return p
end

-- Cylinder whose round axis is local Y of `cf` (cf is the center).
local function makeCylinderY(
	parent: Instance,
	name: string,
	cf: CFrame,
	height: number,
	diameter: number,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean?,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	finishPart(
		p,
		parent,
		name,
		cf * CFrame.Angles(0, 0, math.pi / 2),
		v3(height, diameter, diameter),
		color,
		material,
		canCollide,
		transparency
	)
	return p
end

-- Cylinder whose round axis is local Z of `cf`.
local function makeCylinderZ(
	parent: Instance,
	name: string,
	cf: CFrame,
	length: number,
	diameter: number,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	finishPart(
		p,
		parent,
		name,
		cf * CFrame.Angles(0, math.pi / 2, 0),
		v3(length, diameter, diameter),
		color,
		material,
		false,
		transparency
	)
	return p
end

local function makeEllipsoid(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): Part
	local p = Instance.new("Part")
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	finishPart(p, parent, name, cf, size, color, material, false, transparency)
	return p
end

-- Frame whose local Z runs from p1 to p2 (X stays horizontal when possible).
local function frameAlong(p1: Vector3, p2: Vector3): CFrame
	local dir = p2 - p1
	local mid = (p1 + p2) / 2
	if dir.Magnitude < 1e-4 then
		return CFrame.new(mid)
	end
	local up = if math.abs(dir.Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	return CFrame.lookAt(mid, p2, up)
end

-- Frame whose local Y points along `up`, optionally spun around it.
local function cfFromUp(pos: Vector3, up: Vector3, spin: number?): CFrame
	local u = up.Unit
	local ref = if math.abs(u.Y) < 0.95 then Vector3.yAxis else Vector3.xAxis
	local right = ref:Cross(u).Unit
	local back = right:Cross(u).Unit
	return CFrame.fromMatrix(pos, right, u, back) * CFrame.Angles(0, spin or 0, 0)
end

-- Horizontal frame: local X along `tangent`, local -Z pointing out of the island.
local function edgeFrame(pos: Vector3, tangent: Vector3): CFrame
	local up = v3(0, 1, 0)
	return CFrame.fromMatrix(pos, tangent, up, tangent:Cross(up))
end

local function makeSegment(
	parent: Instance,
	name: string,
	p1: Vector3,
	p2: Vector3,
	width: number,
	height: number,
	color: Color3,
	material: Enum.Material,
	transparency: number?,
	round: boolean?
): BasePart
	local len = (p2 - p1).Magnitude
	local cf = frameAlong(p1, p2)
	if round then
		return makeCylinderZ(parent, name, cf, len, width, color, material, transparency)
	end
	return makePart(parent, name, cf, v3(width, height, len), color, material, false, transparency)
end

-- Flat triangle (two wedges), top face on the plane a-b-c (horizontal planes only).
local function makeTriangle(
	parent: Instance,
	name: string,
	a0: Vector3,
	b0: Vector3,
	c0: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean?
)
	local a, b, c = a0, b0, c0
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local shift = v3(0, -thickness / 2, 0)
	makeWedge(
		parent,
		name,
		CFrame.fromMatrix((a + b) / 2 + shift, right, up, back),
		v3(thickness, height, math.abs(ab:Dot(back))),
		color,
		material,
		canCollide
	)
	makeWedge(
		parent,
		name,
		CFrame.fromMatrix((a + c) / 2 + shift, -right, up, -back),
		v3(thickness, height, math.abs(ac:Dot(back))),
		color,
		material,
		canCollide
	)
end

-- Ring of blocks in the XZ plane of centerCF. Returns the number of parts.
local function makeRingBand(
	parent: Instance,
	name: string,
	centerCF: CFrame,
	radius: number,
	radialWidth: number,
	height: number,
	color: Color3,
	material: Enum.Material,
	canCollide: boolean?,
	transparency: number?,
	segLen: number?,
	skip: ((number) -> boolean)?,
	colorJitter: number?
): number
	local n = math.max(10, math.floor(TAU * radius / (segLen or 1.6) + 0.5))
	local chord = 2 * radius * math.sin(math.pi / n) * 1.06
	local made = 0
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * TAU
		if skip == nil or not skip(a) then
			local cf = centerCF * CFrame.Angles(0, -a, 0) * CFrame.new(radius, 0, 0)
			local col = if colorJitter then jitter(color, colorJitter) else color
			makePart(
				parent,
				name,
				cf,
				v3(radialWidth, height, chord),
				col,
				material,
				canCollide,
				transparency
			)
			made += 1
		end
	end
	return made
end

local function makeNeonRing(
	parent: Instance,
	name: string,
	centerCF: CFrame,
	radius: number,
	thickness: number,
	color: Color3,
	transparency: number?
): number
	return makeRingBand(
		parent,
		name,
		centerCF,
		radius,
		thickness,
		thickness,
		color,
		Enum.Material.Neon,
		false,
		transparency,
		1.6
	)
end

-- Sagging rope between two points.
local function makeRope(
	parent: Instance,
	p1: Vector3,
	p2: Vector3,
	sag: number,
	thickness: number,
	color: Color3
)
	local steps = 4
	local prev = p1
	for i = 1, steps do
		local t = i / steps
		local p = p1:Lerp(p2, t) - v3(0, sag * 4 * t * (1 - t), 0)
		makeSegment(
			parent,
			"Rope",
			prev,
			p,
			thickness,
			thickness,
			color,
			Enum.Material.Fabric,
			0,
			true
		)
		prev = p
	end
end

local function addTag(inst: Instance, tag: string, attrs: { [string]: any }?)
	CollectionService:AddTag(inst, tag)
	if attrs then
		for k, v in attrs do
			inst:SetAttribute(k, v)
		end
	end
	animatedCount += 1
end

-- Model with an invisible pivot part as PrimaryPart (for spin/bob/sway).
local function makePivotModel(parent: Instance, name: string, pivotCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = name
	local pivot = makePart(
		m,
		"Pivot",
		pivotCF,
		v3(0.4, 0.4, 0.4),
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	pivot.CastShadow = false
	m.PrimaryPart = pivot
	m.Parent = parent
	return m
end

local function addLight(
	part: BasePart,
	color: Color3,
	range: number,
	brightness: number
): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = part
	return l
end

local function makeSparkles(
	part: BasePart,
	color: Color3,
	rate: number,
	size: number,
	lifetime: number,
	speed: number
): ParticleEmitter
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Sparkles"
	pe.Color = ColorSequence.new(color)
	pe.LightEmission = 0.9
	pe.LightInfluence = 0
	pe.Rate = rate
	pe.Lifetime = NumberRange.new(lifetime * 0.7, lifetime * 1.3)
	pe.Speed = NumberRange.new(speed * 0.4, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-60, 60)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.25, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Parent = part
	return pe
end

-- Island outline -------------------------------------------------------------
local function edgeScale(theta: number): number
	return 1
		+ 0.025 * math.sin(3 * theta + 0.4)
		+ 0.018 * math.sin(5 * theta + 1.9)
		+ 0.01 * math.sin(7 * theta + 0.3)
end

local function edgePoint(theta: number, s: number?): Vector3
	local k = edgeScale(theta) * (s or 1)
	return v3(math.cos(theta) * RX * k, 0, math.sin(theta) * RZ * k)
end

local function edgeNormal(theta: number): Vector3
	local t = edgePoint(theta + 0.002) - edgePoint(theta - 0.002)
	return v3(t.Z, 0, -t.X).Unit
end

local function insideIsland(p: Vector3, margin: number): boolean
	local theta = math.atan2(p.Z, p.X)
	return v3(p.X, 0, p.Z).Magnitude <= edgePoint(theta).Magnitude - margin
end

-- Placement zones (keep scatter off paths, ponds and props) -----------------
local function distToSegmentXZ(p: Vector3, a: Vector3, b: Vector3): number
	local ab = v3(b.X - a.X, 0, b.Z - a.Z)
	local ap = v3(p.X - a.X, 0, p.Z - a.Z)
	local len2 = ab:Dot(ab)
	local t = if len2 > 0 then math.clamp(ap:Dot(ab) / len2, 0, 1) else 0
	local q = v3(a.X + ab.X * t, 0, a.Z + ab.Z * t)
	return (v3(p.X, 0, p.Z) - q).Magnitude
end

local function addZone(a: Vector3, b: Vector3?, r: number)
	table.insert(zones, { a = a, b = b or a, r = r })
end

local function isFree(p: Vector3, r: number): boolean
	for _, z in zones do
		if distToSegmentXZ(p, z.a, z.b) < z.r + r then
			return false
		end
	end
	return true
end

-- ============================================================================
-- Prop helpers (reusable)
-- ============================================================================
local CORNER_UP = CFrame.Angles(0, 0, math.atan(math.sqrt(2))) * CFrame.Angles(0, math.rad(45), 0)

-- Hexagonal pointed crystal: 3 crossed slabs (hex prism) + corner-up cube tip + neon core.
local function makeCrystal(
	parent: Instance,
	name: string,
	baseCF: CFrame,
	length: number,
	radius: number,
	color: Color3,
	glow: boolean?
): BasePart
	local mid = baseCF * CFrame.new(0, length / 2, 0)
	local first: BasePart? = nil
	for k = 0, 2 do
		local p = makePart(
			parent,
			name,
			mid * CFrame.Angles(0, k * math.pi / 3, 0),
			v3(radius, length, radius * SQRT3),
			color,
			Enum.Material.Glass,
			false,
			0.28
		)
		if first == nil then
			first = p
		end
	end
	local edge = radius * 1.2247
	makePart(
		parent,
		name .. "Tip",
		baseCF * CFrame.new(0, length, 0) * CFrame.Angles(0, math.pi / 6, 0) * CORNER_UP,
		v3(edge, edge, edge),
		color,
		Enum.Material.Glass,
		false,
		0.22
	)
	if glow ~= false then
		return makePart(
			parent,
			name .. "Core",
			baseCF * CFrame.new(0, length * 0.47, 0),
			v3(radius * 0.75, length * 0.9, radius * 0.75),
			color:Lerp(Color3.new(1, 1, 1), 0.2),
			Enum.Material.Neon,
			false,
			0.12
		)
	end
	return first :: BasePart
end

local function makeCrystalCluster(
	parent: Instance,
	baseCF: CFrame,
	scale: number,
	color: Color3,
	count: number
)
	makeCrystal(
		parent,
		"Crystal",
		baseCF,
		3.0 * scale * rand(0.85, 1.15),
		0.55 * scale,
		color,
		true
	)
	for i = 1, count - 1 do
		local a = (i / math.max(1, count - 1)) * TAU + rand(-0.4, 0.4)
		local tilt = rand(0.35, 0.75)
		local cf = baseCF
			* CFrame.Angles(0, a, 0)
			* CFrame.new(0.5 * scale, -0.1 * scale, 0)
			* CFrame.Angles(0, 0, -tilt)
		makeCrystal(
			parent,
			"Crystal",
			cf,
			rand(1.2, 2.1) * scale,
			rand(0.26, 0.4) * scale,
			color,
			i % 2 == 0
		)
	end
end

local function makeCushion(parent: Instance, cf: CFrame, size: Vector3, color: Color3)
	makeEllipsoid(parent, "Cushion", cf, size, color, Enum.Material.Fabric)
	makeBall(
		parent,
		"CushionButton",
		(cf * CFrame.new(0, size.Y * 0.45, 0)).Position,
		size.Y * 0.35,
		PALETTE.goldDeep,
		Enum.Material.SmoothPlastic
	)
	for sx = -1, 1, 2 do
		makeBall(
			parent,
			"CushionTassel",
			(cf * CFrame.new(sx * size.X * 0.5, 0, size.Z * 0.42)).Position,
			size.Y * 0.4,
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
	end
end

local function makeCloud(
	parent: Instance,
	center: Vector3,
	scale: number,
	puffs: number,
	tint: Color3
)
	local under = tint:Lerp(PALETTE.cloudBlue, 0.5)
	local midCol = tint:Lerp(PALETTE.cloudPink, 0.35)
	-- Broad soft cloud belly
	makeEllipsoid(
		parent,
		"CloudUnder",
		CFrame.new(center + v3(0, -0.06 * scale, 0)) * CFrame.Angles(0, rand(0, TAU), 0),
		v3(scale * 1.6, scale * 0.24, scale * 1.25),
		jitter(under, 0.015),
		Enum.Material.SmoothPlastic
	)
	-- Warm rose-lilac mid cushion
	makeEllipsoid(
		parent,
		"CloudMid",
		CFrame.new(center + v3(0, 0.03 * scale, 0)) * CFrame.Angles(0, rand(0, TAU), 0),
		v3(scale * 1.38, scale * 0.26, scale * 1.08),
		jitter(midCol, 0.015),
		Enum.Material.SmoothPlastic
	)
	-- Soft pillowy sunlit warm cream/peach billowing puffs (wider, lower so never egg-like)
	for i = 1, puffs do
		local a = (i / math.max(1, puffs)) * TAU + rand(-0.35, 0.35)
		local d = if i == 1 then rand(0, 0.14) * scale else rand(0.22, 0.54) * scale
		local s = if i == 1 then rand(0.58, 0.72) * scale else rand(0.38, 0.56) * scale
		local pos = center
			+ v3(
				math.cos(a) * d,
				(if i == 1 then 0.12 else rand(0.04, 0.12)) * scale,
				math.sin(a) * d * 0.85
			)
		local col = jitter(tint:Lerp(PALETTE.cloudCream, rand(0.35, 0.85)), 0.015)
		makeEllipsoid(
			parent,
			"CloudPuff",
			CFrame.new(pos),
			v3(s * 1.32, s * rand(0.38, 0.52), s * rand(1.0, 1.22)),
			col,
			Enum.Material.SmoothPlastic
		)
	end
end

-- Constellation: delicate bright golden orbs (with hero ringed solar node) linked by starlight lines.
local function makeConstellation(
	parent: Instance,
	name: string,
	pivotCF: CFrame,
	points: { Vector3 },
	links: { { number } }
): Model
	local m = makePivotModel(parent, name, pivotCF)
	local world: { Vector3 } = {}
	for i, off in points do
		local p = (pivotCF * CFrame.new(off)).Position
		world[i] = p
		local isHero = i == 2 or i == 5
		local orbSize = if isHero then 1.35 else if i % 2 == 0 then 0.85 else 0.65
		makeBall(m, "Star", p, orbSize, PALETTE.goldGlow, Enum.Material.Neon)
		makeBall(m, "StarHalo", p, orbSize * 1.65, PALETTE.goldLight, Enum.Material.Neon, 0.78)
		if isHero then
			makeNeonRing(
				m,
				"StarRing",
				CFrame.new(p) * CFrame.Angles(math.pi / 2, 0, 0),
				orbSize * 0.88,
				0.13,
				PALETTE.goldLight,
				0.08
			)
			makeNeonRing(
				m,
				"StarRingOuter",
				CFrame.new(p) * CFrame.Angles(math.pi / 2, 0, 0),
				orbSize * 1.28,
				0.08,
				PALETTE.goldGlow,
				0.34
			)
		elseif i % 2 == 0 then
			makeNeonRing(
				m,
				"StarRing",
				CFrame.new(p) * CFrame.Angles(math.pi / 2, 0, 0),
				0.82,
				0.08,
				PALETTE.goldLight,
				0.22
			)
		end
	end
	for _, link in links do
		makeSegment(
			m,
			"StarLine",
			world[link[1]],
			world[link[2]],
			0.1,
			0.1,
			PALETTE.goldLight,
			Enum.Material.Neon,
			0.22,
			true
		)
	end
	return m
end

-- Graceful sculpted angelic feathered wing in XY plane of rootCF (side = 1 right, -1 left).
local function makeWing(parent: Instance, rootCF: CFrame, side: number, scale: number)
	local rows = {
		{ count = 7, length = 7.4, width = 1.55, from = 4, to = 82, z = -0.22, r = 0.9 },
		{ count = 6, length = 5.4, width = 1.38, from = 10, to = 76, z = 0.14, r = 0.78 },
		{ count = 4, length = 3.4, width = 1.18, from = 16, to = 68, z = 0.44, r = 0.6 },
	}
	for ri, row in rows do
		for i = 0, row.count - 1 do
			local t = i / (row.count - 1)
			local ang = math.rad(row.from + (row.to - row.from) * t)
			local dir = v3(math.cos(ang) * side, math.sin(ang), 0)
			local sweep = 0.62 + 0.48 * math.sin((t ^ 0.85) * math.pi) + 0.14 * t
			local len = row.length * scale * sweep
			local base = v3(dir.X * row.r * scale, dir.Y * row.r * scale, row.z * scale)
			local right = dir:Cross(Vector3.zAxis)
			local col = if ri == 1
				then PALETTE.fabric
				elseif ri == 2 then PALETTE.marble
				else PALETTE.marbleShade
			makeEllipsoid(
				parent,
				"Feather",
				rootCF * CFrame.fromMatrix(base + dir * (len / 2), right, dir, Vector3.zAxis),
				v3(row.width * scale, len, 0.42 * scale),
				col,
				Enum.Material.SmoothPlastic
			)
			if ri == 1 then
				makePart(
					parent,
					"FeatherQuill",
					rootCF
						* CFrame.fromMatrix(
							base + dir * (len * 0.42) + v3(0, 0, 0.18 * scale),
							right,
							dir,
							Vector3.zAxis
						),
					v3(0.12 * scale, len * 0.7, 0.08 * scale),
					PALETTE.gold,
					Enum.Material.SmoothPlastic
				)
			elseif ri == 3 then
				makeEllipsoid(
					parent,
					"FeatherGold",
					rootCF
						* CFrame.fromMatrix(
							base + dir * (len * 0.24) + v3(0, 0, 0.18 * scale),
							right,
							dir,
							Vector3.zAxis
						),
					v3(row.width * scale * 0.86, len * 0.42, 0.26 * scale),
					PALETTE.gold,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end
	-- Sculpted golden winged shoulder clasp hugging the arch side cleanly
	makeEllipsoid(
		parent,
		"WingShoulder",
		rootCF * CFrame.new(-side * 0.2 * scale, 0.1 * scale, 0.6 * scale),
		v3(2.2, 2.8, 1.3) * scale,
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	makeEllipsoid(
		parent,
		"WingShoulderRim",
		rootCF * CFrame.new(-side * 0.1 * scale, 0.35 * scale, 0.72 * scale),
		v3(1.5, 2.0, 0.9) * scale,
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic
	)
	local prev = (rootCF * CFrame.new(0, 0.15 * scale, 0.66 * scale)).Position
	for i = 1, 4 do
		local ang = math.rad(16 + i * 16)
		local p = (rootCF * CFrame.new(
			math.cos(ang) * side * (1.0 + i * 0.68) * scale,
			math.sin(ang) * (1.0 + i * 0.68) * scale,
			0.62 * scale
		)).Position
		makeSegment(
			parent,
			"WingBone",
			prev,
			p,
			0.38 * scale,
			0.38 * scale,
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic,
			0,
			true
		)
		prev = p
	end
end

local RUNES: { { { number } } } = {
	{ { -0.6, -0.8, -0.6, 0.8 }, { -0.6, 0.1, 0.6, 0.8 }, { -0.6, 0.1, 0.6, -0.6 } },
	{ { 0, -0.8, 0, 0.8 }, { -0.6, 0.3, 0, 0.8 }, { 0.6, 0.3, 0, 0.8 } },
	{ { -0.6, -0.8, 0.6, 0.8 }, { -0.6, 0.8, 0.6, -0.8 } },
	{ { -0.6, -0.8, -0.6, 0.8 }, { 0.6, -0.8, 0.6, 0.8 }, { -0.6, 0.6, 0.6, -0.2 } },
	{ { 0, -0.8, 0, 0.8 }, { -0.7, -0.2, 0.7, 0.4 } },
	{ { -0.7, 0.8, 0.7, 0.8 }, { 0.7, 0.8, -0.5, -0.8 }, { -0.5, -0.8, 0.6, -0.8 } },
	{ { -0.5, -0.8, 0.5, 0 }, { 0.5, 0, -0.5, 0.8 }, { -0.5, -0.8, -0.5, 0.8 } },
}

-- Draws a rune glyph on a plane: `planeCF` local X/Z span the glyph, Y is the normal.
local function drawRune(
	parent: Instance,
	planeCF: CFrame,
	size: number,
	glyph: { { number } },
	width: number,
	color: Color3,
	material: Enum.Material
)
	for _, s in glyph do
		local p1 = (planeCF * CFrame.new(s[1] * size, 0, s[2] * size)).Position
		local p2 = (planeCF * CFrame.new(s[3] * size, 0, s[4] * size)).Position
		local len = (p2 - p1).Magnitude + width
		local mid = (p1 + p2) / 2
		local dir = (p2 - p1).Unit
		local nrm = planeCF.UpVector
		local x = nrm:Cross(dir).Unit
		makePart(
			parent,
			"Rune",
			CFrame.fromMatrix(mid, x, nrm, x:Cross(nrm)),
			v3(width, 0.05, len),
			color,
			material,
			false,
			0
		)
	end
end

-- Wooden sign with a text label and a bold golden fish relief. Faces `facing`.
local function makeSign(parent: Instance, pos: Vector3, facing: Vector3, text: string)
	local f = v3(facing.X, 0, facing.Z).Unit
	local cf = CFrame.lookAt(pos, pos + f)
	local sc = 1.25
	for sx = -1, 1, 2 do
		makePart(
			parent,
			"SignPost",
			cf * CFrame.new(sx * 1.45 * sc, 1.55 * sc, 0.06),
			v3(0.36 * sc, 3.1 * sc, 0.36 * sc),
			PALETTE.woodDark,
			Enum.Material.Wood
		)
		makeBall(
			parent,
			"SignPostCap",
			(cf * CFrame.new(sx * 1.45 * sc, 3.12 * sc, 0.06)).Position,
			0.48 * sc,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end
	local board = makePart(
		parent,
		"SignBoard",
		cf * CFrame.new(0, 2.75 * sc, 0),
		v3(3.5 * sc, 2.1 * sc, 0.28),
		PALETTE.woodLight,
		Enum.Material.Wood
	)
	board.CastShadow = true
	-- chunky gold frame
	makePart(
		parent,
		"SignFrame",
		cf * CFrame.new(0, 3.8 * sc, -0.08),
		v3(3.75 * sc, 0.2 * sc, 0.26),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	makePart(
		parent,
		"SignFrame",
		cf * CFrame.new(0, 1.7 * sc, -0.08),
		v3(3.75 * sc, 0.2 * sc, 0.26),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	makePart(
		parent,
		"SignFrame",
		cf * CFrame.new(-1.82 * sc, 2.75 * sc, -0.08),
		v3(0.2 * sc, 2.2 * sc, 0.26),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	makePart(
		parent,
		"SignFrame",
		cf * CFrame.new(1.82 * sc, 2.75 * sc, -0.08),
		v3(0.2 * sc, 2.2 * sc, 0.26),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	-- bold carved fish emblem
	local fishCF = cf * CFrame.new(0, 2.28 * sc, -0.16)
	makeEllipsoid(
		parent,
		"SignFish",
		fishCF,
		v3(1.55 * sc, 0.68 * sc, 0.1),
		PALETTE.woodDark,
		Enum.Material.SmoothPlastic
	)
	makeEllipsoid(
		parent,
		"SignFishTail",
		fishCF * CFrame.new(0.92 * sc, 0.16 * sc, 0) * CFrame.Angles(0, 0, 0.6),
		v3(0.62 * sc, 0.32 * sc, 0.08),
		PALETTE.woodDark,
		Enum.Material.SmoothPlastic
	)
	makeEllipsoid(
		parent,
		"SignFishTail",
		fishCF * CFrame.new(0.92 * sc, -0.16 * sc, 0) * CFrame.Angles(0, 0, -0.6),
		v3(0.62 * sc, 0.32 * sc, 0.08),
		PALETTE.woodDark,
		Enum.Material.SmoothPlastic
	)
	makeBall(
		parent,
		"SignFishEye",
		(fishCF * CFrame.new(-0.46 * sc, 0.08 * sc, -0.05)).Position,
		0.14 * sc,
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic
	)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0.5
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.88, 0.42)
	label.Position = UDim2.fromScale(0.06, 0.06)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = PALETTE.runeInk
	label.TextStrokeColor3 = PALETTE.goldLight
	label.TextStrokeTransparency = 0.35
	label.Parent = gui
	gui.Parent = board
	addZone(pos, nil, 2.2)
end

local function makeBarrel(parent: Instance, pos: Vector3)
	local sc = 1.38
	local spin = rand(0, TAU)
	local base = CFrame.new(pos) * CFrame.Angles(0, spin, 0)
	makeCylinderY(
		parent,
		"BarrelBody",
		base * CFrame.new(0, 0.95 * sc, 0),
		1.9 * sc,
		1.75 * sc,
		PALETTE.wood,
		Enum.Material.Wood
	)
	makeCylinderY(
		parent,
		"BarrelBulge",
		base * CFrame.new(0, 0.95 * sc, 0),
		0.95 * sc,
		1.95 * sc,
		PALETTE.goldWood,
		Enum.Material.Wood
	)
	for _, y in { 0.32, 1.56 } do
		makeCylinderY(
			parent,
			"BarrelHoop",
			base * CFrame.new(0, y * sc, 0),
			0.2 * sc,
			1.94 * sc,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end
	makeCylinderY(
		parent,
		"BarrelLid",
		base * CFrame.new(0, 1.88 * sc, 0),
		0.08 * sc,
		1.6 * sc,
		PALETTE.goldGlow,
		Enum.Material.SmoothPlastic
	)
	-- overflowing gold coin mound
	makeEllipsoid(
		parent,
		"BarrelGoldMound",
		base * CFrame.new(0, 1.98 * sc, 0),
		v3(1.55, 0.65, 1.55) * sc,
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic
	)
	for i = 1, 4 do
		local a = i * 1.55
		makeCylinderY(
			parent,
			"BarrelCoin",
			base
				* CFrame.new(
					math.cos(a) * 0.42 * sc,
					(2.06 + i * 0.05) * sc,
					math.sin(a) * 0.42 * sc
				)
				* CFrame.Angles(rand(-0.2, 0.2), 0, rand(-0.2, 0.2)),
			0.1 * sc,
			0.62 * sc,
			PALETTE.goldGlow,
			Enum.Material.Neon,
			false,
			0.18
		)
	end
	addZone(pos, nil, 1.8)
end

-- Lantern on a taller warm wooden post with golden glowing lantern; flickers gently.
local function makeLanternPost(parent: Instance, pos: Vector3, armDir: Vector3)
	local sc = 1.32
	local d = v3(armDir.X, 0, armDir.Z).Unit
	local cf = CFrame.lookAt(pos, pos + d)
	makeCylinderY(
		parent,
		"LanternBase",
		cf * CFrame.new(0, 0.26 * sc, 0),
		0.52 * sc,
		1.25 * sc,
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		parent,
		"LanternPost",
		cf * CFrame.new(0, 2.9 * sc, 0),
		5.2 * sc,
		0.52 * sc,
		PALETTE.wood,
		Enum.Material.Wood
	)
	makeBall(
		parent,
		"LanternPostCap",
		(cf * CFrame.new(0, 5.6 * sc, 0)).Position,
		0.68 * sc,
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	makePart(
		parent,
		"LanternArm",
		cf * CFrame.new(0, 5.15 * sc, -0.95 * sc),
		v3(0.28 * sc, 0.3 * sc, 2.1 * sc),
		PALETTE.wood,
		Enum.Material.Wood
	)
	makePart(
		parent,
		"LanternChain",
		cf * CFrame.new(0, 4.75 * sc, -1.85 * sc),
		v3(0.1 * sc, 0.72 * sc, 0.1 * sc),
		PALETTE.goldDeep,
		Enum.Material.SmoothPlastic
	)
	local lcf = cf * CFrame.new(0, 3.85 * sc, -1.85 * sc)
	makePart(
		parent,
		"LanternCap",
		lcf * CFrame.new(0, 0.75 * sc, 0) * CFrame.Angles(0, math.pi / 4, 0),
		v3(1.22 * sc, 0.28 * sc, 1.22 * sc),
		PALETTE.goldDeep,
		Enum.Material.SmoothPlastic
	)
	makePart(
		parent,
		"LanternBottom",
		lcf * CFrame.new(0, -0.72 * sc, 0) * CFrame.Angles(0, math.pi / 4, 0),
		v3(1.04 * sc, 0.22 * sc, 1.04 * sc),
		PALETTE.goldDeep,
		Enum.Material.SmoothPlastic
	)
	makePart(
		parent,
		"LanternGlass",
		lcf,
		v3(0.98 * sc, 1.26 * sc, 0.98 * sc),
		PALETTE.lanternGlass,
		Enum.Material.SmoothPlastic,
		false,
		0.32
	)
	local core = makePart(
		parent,
		"LanternGlow",
		lcf,
		v3(0.62 * sc, 0.94 * sc, 0.62 * sc),
		PALETTE.lantern,
		Enum.Material.Neon,
		false,
		0
	)
	addLight(core, PALETTE.lantern, 14, 1.25)
	addTag(core, TAG_FLICKER, { Intensity = 0.32 })
	addZone(pos, nil, 1.5)
end

-- Tall white-cream celestial banner with bold gold chevrons & cyan crystal finial; sways.
local function makeBanner(parent: Instance, pos: Vector3, facing: Vector3)
	local sc = 1.32
	local f = v3(facing.X, 0, facing.Z).Unit
	local cf = CFrame.lookAt(pos, pos + f)
	makeCylinderY(
		parent,
		"BannerFoot",
		cf * CFrame.new(0, 0.25 * sc, 0),
		0.5 * sc,
		1.25 * sc,
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		parent,
		"BannerPole",
		cf * CFrame.new(0, 3.25 * sc, 0),
		6.4 * sc,
		0.34 * sc,
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	makeCrystal(
		parent,
		"BannerCrystal",
		cf * CFrame.new(0, 6.45 * sc, 0),
		1.15 * sc,
		0.32 * sc,
		PALETTE.crystalCyan,
		true
	)
	local barCF = cf * CFrame.new(0, 5.85 * sc, -0.22 * sc)
	makeSegment(
		parent,
		"BannerBar",
		(barCF * CFrame.new(-1.4 * sc, 0, 0)).Position,
		(barCF * CFrame.new(1.4 * sc, 0, 0)).Position,
		0.26 * sc,
		0.26 * sc,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		0,
		true
	)
	for sx = -1, 1, 2 do
		makeBall(
			parent,
			"BannerBarEnd",
			(barCF * CFrame.new(sx * 1.45 * sc, 0, 0)).Position,
			0.38 * sc,
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
	end
	local cloth = makePivotModel(parent, "BannerCloth", barCF)
	local clothCF = barCF * CFrame.new(0, -1.85 * sc, -0.02)
	makePart(
		cloth,
		"Cloth",
		clothCF,
		v3(2.2 * sc, 3.7 * sc, 0.12),
		PALETTE.fabric,
		Enum.Material.Fabric
	)
	for sx = -1, 1, 2 do
		makePart(
			cloth,
			"ClothTrim",
			clothCF * CFrame.new(sx * 1.04 * sc, 0, -0.05),
			v3(0.16 * sc, 3.7 * sc, 0.08),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end
	makePart(
		cloth,
		"ClothTrim",
		clothCF * CFrame.new(0, -1.8 * sc, -0.05),
		v3(2.24 * sc, 0.16 * sc, 0.08),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	for i = 0, 1 do
		local y = (0.38 - i * 0.82) * sc
		for sx = -1, 1, 2 do
			makePart(
				cloth,
				"ClothChevron",
				clothCF * CFrame.new(sx * 0.4 * sc, y, -0.07) * CFrame.Angles(0, 0, sx * 0.62),
				v3(1.08 * sc, 0.18 * sc, 0.06),
				PALETTE.gold,
				Enum.Material.SmoothPlastic
			)
		end
	end
	makeCrystal(
		cloth,
		"ClothGem",
		clothCF * CFrame.new(0, 1.15 * sc, -0.09) * CFrame.Angles(-math.pi / 2, 0, 0),
		0.32 * sc,
		0.22 * sc,
		PALETTE.crystalCyan,
		true
	)
	addTag(cloth, TAG_SWAY, { Angle = 5, Speed = 1.2, Phase = rand(0, TAU) })
	addZone(pos, nil, 1.8)
end

local function makeStool(parent: Instance, cf: CFrame)
	makeCylinderY(
		parent,
		"StoolSeat",
		cf * CFrame.new(0, 1.35, 0),
		0.32,
		1.7,
		PALETTE.wood,
		Enum.Material.Wood
	)
	makeCylinderY(
		parent,
		"StoolSeatTrim",
		cf * CFrame.new(0, 1.18, 0),
		0.08,
		1.74,
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	for i = 0, 2 do
		local a = i / 3 * TAU
		local top = (cf * CFrame.new(math.cos(a) * 0.5, 1.2, math.sin(a) * 0.5)).Position
		local bottom = (cf * CFrame.new(math.cos(a) * 0.72, 0, math.sin(a) * 0.72)).Position
		makeSegment(
			parent,
			"StoolLeg",
			bottom,
			top,
			0.22,
			0.22,
			PALETTE.woodDark,
			Enum.Material.Wood,
			0,
			true
		)
	end
end

local function makeRuneStone(parent: Instance, pos: Vector3, facing: Vector3)
	local f = v3(facing.X, 0, facing.Z).Unit
	local w, h, d = rand(1.4, 2.1), rand(1.6, 2.6), rand(1.1, 1.5)
	local cf = CFrame.lookAt(pos + v3(0, h * 0.38, 0), pos + v3(0, h * 0.38, 0) + f)
		* CFrame.Angles(rand(-0.12, 0.12), 0, rand(-0.12, 0.12))
	makeEllipsoid(
		parent,
		"RuneStone",
		cf,
		v3(w, h, d),
		jitter(PALETTE.stone, 0.03),
		Enum.Material.SmoothPlastic
	)
	makeEllipsoid(
		parent,
		"RuneStoneBase",
		CFrame.new(pos + v3(0, 0.12, 0)),
		v3(w * 1.2, 0.4, d * 1.3),
		PALETTE.stoneDark,
		Enum.Material.SmoothPlastic
	)
	local face = cf * CFrame.new(0, 0.05 * h, -d * 0.47) * CFrame.Angles(math.pi / 2, 0, 0)
	drawRune(
		parent,
		face,
		math.min(w, h) * 0.26,
		RUNES[randInt(1, #RUNES)],
		0.12,
		PALETTE.goldGlow,
		Enum.Material.Neon
	)
	addZone(pos, nil, 1.3)
end

local function makeGrassTuft(parent: Instance, pos: Vector3, scale: number)
	local blades = randInt(3, 4)
	for _ = 1, blades do
		local h = rand(0.8, 1.5) * scale
		local a = rand(0, TAU)
		local tilt = rand(-0.25, 0.25)
		local cf = CFrame.new(pos + v3(math.cos(a) * 0.18, h / 2 - 0.05, math.sin(a) * 0.18))
			* CFrame.Angles(0, a, 0)
			* CFrame.Angles(tilt, 0, rand(-0.2, 0.2))
		local col = pickColor({ PALETTE.grassBlade, PALETTE.grassDark, PALETTE.grassLight })
		makeWedge(
			parent,
			"GrassBlade",
			cf,
			v3(0.16, h, rand(0.35, 0.55) * scale),
			col,
			Enum.Material.SmoothPlastic
		)
	end
end

local function makeBush(parent: Instance, pos: Vector3, s: number)
	local shades = { PALETTE.grassDark, PALETTE.grassBlade, PALETTE.grassLight }
	for i = 1, 3 do
		local a = i / 3 * TAU + rand(-0.4, 0.4)
		local r = rand(0.9, 1.3) * s
		local p = pos + v3(math.cos(a) * 0.55 * s, r * 0.55, math.sin(a) * 0.55 * s)
		makeEllipsoid(
			parent,
			"Bush",
			CFrame.new(p) * CFrame.Angles(0, rand(0, TAU), 0),
			v3(r * 1.6, r * 1.3, r * 1.5),
			jitter(pickColor(shades), 0.02),
			Enum.Material.SmoothPlastic
		)
	end
	for _ = 1, 3 do
		local dir = v3(rand(-1, 1), rand(0.3, 1), rand(-1, 1)).Unit
		makeBall(
			parent,
			"BushFlower",
			pos + v3(0, 0.9 * s, 0) + dir * 1.15 * s,
			0.38 * s,
			pickColor({ PALETTE.blossomLight, PALETTE.pastelLemon, PALETTE.fabric }),
			Enum.Material.SmoothPlastic
		)
	end
end

local function makeFlower(parent: Instance, pos: Vector3)
	local col = pickColor({
		PALETTE.blossomLight,
		PALETTE.pastelPink,
		PALETTE.fabric,
		PALETTE.pastelLemon,
		PALETTE.pastelLilac,
	})
	makeEllipsoid(
		parent,
		"FlowerPetals",
		CFrame.new(pos + v3(0, 0.42, 0))
			* CFrame.Angles(rand(-0.2, 0.2), rand(0, TAU), rand(-0.2, 0.2)),
		v3(0.8, 0.26, 0.8),
		col,
		Enum.Material.SmoothPlastic
	)
	makeBall(
		parent,
		"FlowerHeart",
		pos + v3(0, 0.55, 0),
		0.26,
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic
	)
	makePart(
		parent,
		"FlowerStem",
		CFrame.new(pos + v3(0, 0.2, 0)),
		v3(0.08, 0.4, 0.08),
		PALETTE.grassDark,
		Enum.Material.SmoothPlastic
	)
end

-- Crystal crown monument on a marble plinth.
local function makeCrown(parent: Instance, base: Vector3, s: number): BasePart
	makeCylinderY(
		parent,
		"CrownBase",
		CFrame.new(base + v3(0, 0.52 * s, 0)),
		1.04 * s,
		6.6 * s,
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		parent,
		"CrownBaseTrim",
		CFrame.new(base + v3(0, 1.06 * s, 0)),
		0.22 * s,
		6.85 * s,
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		parent,
		"CrownPlinth",
		CFrame.new(base + v3(0, 1.56 * s, 0)),
		0.95 * s,
		5.4 * s,
		PALETTE.marbleShade,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		parent,
		"CrownPlinthTrim",
		CFrame.new(base + v3(0, 2.06 * s, 0)),
		0.2 * s,
		5.65 * s,
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic
	)
	local bandY = 2.85 * s
	local bandCF = CFrame.new(base + v3(0, bandY, 0))
	makeRingBand(
		parent,
		"CrownBand",
		bandCF,
		2.2 * s,
		0.52 * s,
		1.35 * s,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false,
		0,
		0.95 * s
	)
	makeRingBand(
		parent,
		"CrownBandTrim",
		bandCF * CFrame.new(0, 0.7 * s, 0),
		2.28 * s,
		0.62 * s,
		0.22 * s,
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic,
		false,
		0,
		0.95 * s
	)
	makeRingBand(
		parent,
		"CrownBandTrim",
		bandCF * CFrame.new(0, -0.7 * s, 0),
		2.28 * s,
		0.62 * s,
		0.22 * s,
		PALETTE.goldDeep,
		Enum.Material.SmoothPlastic,
		false,
		0,
		0.95 * s
	)
	-- Glowing warm gold inner bowl
	makeCylinderY(
		parent,
		"CrownBowlGlow",
		CFrame.new(base + v3(0, bandY - 0.1 * s, 0)),
		0.45 * s,
		3.8 * s,
		PALETTE.goldGlow,
		Enum.Material.Neon,
		false,
		0.2
	)
	local upVec = v3(0, 1, 0)
	for i = 0, 6 do
		local a = i / 7 * TAU + 0.25
		local dir = v3(math.cos(a), 0, math.sin(a))
		local p = base + v3(0, bandY + 0.62 * s, 0) + dir * 2.2 * s
		local spikeH = (if i % 2 == 0 then 2.0 else 1.45) * s
		local frame = CFrame.fromMatrix(p, dir, upVec, dir:Cross(upVec))
		makeWedge(
			parent,
			"CrownSpike",
			frame * CFrame.new(0, spikeH / 2, -0.36 * s),
			v3(0.46 * s, spikeH, 0.72 * s),
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
		makeWedge(
			parent,
			"CrownSpike",
			frame * CFrame.new(0, spikeH / 2, 0.36 * s) * CFrame.Angles(0, math.pi, 0),
			v3(0.46 * s, spikeH, 0.72 * s),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		makeCrystal(
			parent,
			"CrownCrystal",
			cfFromUp(p + v3(0, spikeH * 0.55, 0) + dir * 0.14 * s, (dir * 0.3 + upVec).Unit, a),
			(if i % 2 == 0 then 2.8 else 2.0) * s,
			0.48 * s,
			if i % 2 == 0 then PALETTE.crystalCyan else PALETTE.crystalPink,
			i % 2 == 0
		)
		-- Faceted glowing cyan diamond inlaid on the crown band
		makePart(
			parent,
			"CrownGem",
			frame * CFrame.new(0.28 * s, -0.58 * s, 0) * CFrame.Angles(math.pi / 4, 0, 0),
			v3(0.26 * s, 0.72 * s, 0.72 * s),
			if i % 2 == 0 then PALETTE.crystalCyan else PALETTE.crystalPink,
			Enum.Material.Neon
		)
	end
	local heart = makeCrystal(
		parent,
		"CrownHeart",
		CFrame.new(base + v3(0, 2.2 * s, 0)),
		4.8 * s,
		1.0 * s,
		PALETTE.crystalCyan,
		true
	)
	addLight(heart, PALETTE.goldLight, 18, 1.0)
	return heart
end

-- Small floating islet with crystals; bobs.
local function makeIslet(parent: Instance, name: string, center: Vector3, s: number, phase: number)
	local m = makePivotModel(parent, name, CFrame.new(center))
	makeCylinderY(
		m,
		"IsletGrass",
		CFrame.new(center + v3(0, -0.4 * s, 0)),
		0.8 * s,
		8 * s,
		PALETTE.grass,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		m,
		"IsletTrim",
		CFrame.new(center + v3(0, -0.86 * s, 0)),
		0.16 * s,
		8.3 * s,
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		m,
		"IsletRim",
		CFrame.new(center + v3(0, -1.25 * s, 0)),
		0.65 * s,
		8.1 * s,
		PALETTE.marbleShade,
		Enum.Material.SmoothPlastic
	)
	makeEllipsoid(
		m,
		"IsletRock",
		CFrame.new(center + v3(0, -3.0 * s, 0)),
		v3(7.6, 5.0, 7.6) * s,
		PALETTE.rockTop,
		Enum.Material.SmoothPlastic
	)
	makeEllipsoid(
		m,
		"IsletRock",
		CFrame.new(center + v3(0.3, -5.4 * s, 0.2)),
		v3(4.4, 4.4, 4.4) * s,
		PALETTE.rockBottom,
		Enum.Material.SmoothPlastic
	)
	for i = 0, 6 do
		local a = i / 7 * TAU + rand(-0.2, 0.2)
		local p = center
			+ v3(math.cos(a) * 3.1 * s, -2.8 * s + rand(-0.4, 0.4) * s, math.sin(a) * 3.1 * s)
		local cf = CFrame.lookAt(p, p + v3(math.cos(a), 0, math.sin(a)))
			* CFrame.Angles(math.pi + rand(-0.2, 0.25), rand(-0.25, 0.25), rand(-0.2, 0.2))
		makeWedge(
			m,
			"IsletChunk",
			cf,
			v3(3.1, 3.6, 2.4) * s * rand(0.88, 1.15),
			jitter(PALETTE.rockTop:Lerp(PALETTE.rockBottom, 0.35), 0.03),
			Enum.Material.SmoothPlastic
		)
	end
	makeCrystalCluster(
		m,
		CFrame.new(center + v3(0.9 * s, -0.05 * s, -0.7 * s)),
		1.15 * s,
		PALETTE.crystalCyan,
		5
	)
	makeCrystalCluster(
		m,
		CFrame.new(center + v3(-1.6 * s, -0.05 * s, 1.0 * s)) * CFrame.Angles(0, 0, 0.25),
		0.5 * s,
		PALETTE.crystalGold,
		3
	)
	makeCrystalCluster(
		m,
		cfFromUp(center + v3(0, -6.6 * s, 0), -Vector3.yAxis),
		0.7 * s,
		PALETTE.crystalCyan,
		3
	)
	for _ = 1, 3 do
		local a = rand(0, TAU)
		makeGrassTuft(m, center + v3(math.cos(a) * 2.6 * s, 0, math.sin(a) * 2.6 * s), 0.8)
	end
	addTag(m, TAG_BOB, { Amplitude = 1.2, Speed = 1.0, Phase = phase })
end

-- Translucent silky water veil waterfall (curved Beams + fine aqua ribbons + foam lip,
-- fading gracefully into sparkling mist before the clouds — never solid white bars!).
local function makeFalls(parent: Instance, e: Vector3, n: Vector3, width: number, length: number)
	local tangent = v3(-n.Z, 0, n.X)
	local top = 0.32
	-- Smooth aqua spill crest curving over the marble rim
	local s0 = e - n * 1.1 + v3(0, 0.44, 0)
	local s1 = e + n * 1.4 + v3(0, 0.28, 0)
	makePart(
		parent,
		"FallSpill",
		frameAlong(s0, s1),
		v3(width * 1.04, 0.24, (s1 - s0).Magnitude),
		PALETTE.canalWater,
		Enum.Material.SmoothPlastic,
		false,
		0.28
	)
	-- Frothy foam crest puffs hugging the rim lip
	for i = -2, 2 do
		local off = (i / 2.2) * width * 0.45
		makeEllipsoid(
			parent,
			"FallLipFoam",
			edgeFrame(e + n * 1.45 + tangent * off + v3(0, 0.16, 0), tangent),
			v3(width * 0.38, 0.65, 0.72),
			PALETTE.falls:Lerp(Color3.new(1, 1, 1), 0.45),
			Enum.Material.SmoothPlastic,
			0.18
		)
	end

	-- Silky layered Beam veils curving down and dissolving smoothly before the clouds
	local anchor = makePart(
		parent,
		"FallVeilAnchor",
		edgeFrame(e + n * 1.55 + v3(0, top, 0), tangent),
		v3(0.4, 0.4, 0.4),
		PALETTE.canalWater,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	local veilSpecs = {
		{
			x = 0,
			z = 0,
			w0 = width * 1.08,
			w1 = width * 1.48,
			len = length * 0.9,
			colA = PALETTE.canalWater,
			colB = PALETTE.falls,
			tMid = 0.28,
			em = 0.45,
			faceCam = true,
		},
		{
			x = -width * 0.26,
			z = 0.25,
			w0 = width * 0.4,
			w1 = width * 0.6,
			len = length * 0.84,
			colA = PALETTE.falls,
			colB = Color3.new(1, 1, 1),
			tMid = 0.34,
			em = 0.62,
			faceCam = true,
		},
		{
			x = width * 0.26,
			z = 0.25,
			w0 = width * 0.4,
			w1 = width * 0.6,
			len = length * 0.8,
			colA = PALETTE.falls,
			colB = Color3.new(1, 1, 1),
			tMid = 0.36,
			em = 0.62,
			faceCam = true,
		},
		{
			x = -width * 0.08,
			z = 0.42,
			w0 = width * 0.2,
			w1 = width * 0.28,
			len = length * 0.72,
			colA = Color3.new(1, 1, 1),
			colB = PALETTE.falls,
			tMid = 0.26,
			em = 0.72,
			faceCam = true,
		},
		{
			x = width * 0.12,
			z = 0.42,
			w0 = width * 0.18,
			w1 = width * 0.26,
			len = length * 0.68,
			colA = Color3.new(1, 1, 1),
			colB = PALETTE.falls,
			tMid = 0.3,
			em = 0.72,
			faceCam = true,
		},
	}
	for idx, vs in veilSpecs do
		local a0 = Instance.new("Attachment")
		a0.Name = "FallA0_" .. idx
		a0.Position = v3(vs.x, 0, -vs.z)
		a0.Axis = Vector3.new(0, 0, -1)
		a0.SecondaryAxis = Vector3.new(1, 0, 0)
		a0.Parent = anchor

		local a1 = Instance.new("Attachment")
		a1.Name = "FallA1_" .. idx
		a1.Position = v3(vs.x * 1.15, -vs.len, -(vs.z + 2.6))
		a1.Axis = Vector3.new(0, -1, 0)
		a1.SecondaryAxis = Vector3.new(1, 0, 0)
		a1.Parent = anchor

		local beam = Instance.new("Beam")
		beam.Name = "FallVeil_" .. idx
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = vs.w0
		beam.Width1 = vs.w1
		beam.CurveSize0 = 2.6
		beam.CurveSize1 = 2.0
		beam.Segments = 14
		beam.FaceCamera = vs.faceCam
		beam.LightEmission = vs.em
		beam.LightInfluence = 0.35
		beam.Color = ColorSequence.new(vs.colA, vs.colB)
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, vs.tMid * 0.65),
			NumberSequenceKeypoint.new(0.25, vs.tMid),
			NumberSequenceKeypoint.new(0.65, math.min(0.82, vs.tMid + 0.36)),
			NumberSequenceKeypoint.new(0.92, 0.96),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.Parent = anchor
	end

	-- Soft translucent mist cushion where water dissolves into sparkles
	local mistY = top - length * 0.76
	for _ = 1, 3 do
		local p = e
			+ n * (3.2 + rand(-0.6, 1.2))
			+ tangent * rand(-width * 0.65, width * 0.65)
			+ v3(0, mistY + rand(-2, 3), 0)
		makeEllipsoid(
			parent,
			"FallMist",
			CFrame.new(p),
			v3(rand(4.5, 6.8), rand(2.4, 3.6), rand(4.0, 5.8)),
			PALETTE.falls:Lerp(PALETTE.cloudCream, 0.55),
			Enum.Material.SmoothPlastic,
			0.55
		)
	end
	local fx = makePart(
		parent,
		"FallSparkleEmitter",
		edgeFrame(e + n * 2.5 + v3(0, -14, 0), tangent),
		v3(width * 1.4, 24, 1.2),
		PALETTE.falls,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	makeSparkles(fx, PALETTE.falls, 6, 0.45, 2.4, 1.6)
end

-- Light canal from p1 to p2 (top just under the pond surface).
local function makeCanal(
	parent: Instance,
	p1: Vector3,
	p2: Vector3,
	width: number,
	curbFrom: number
)
	local cf = frameAlong(v3(p1.X, 0, p1.Z), v3(p2.X, 0, p2.Z))
	local len = (v3(p2.X, 0, p2.Z) - v3(p1.X, 0, p1.Z)).Magnitude
	makePart(
		parent,
		"CanalGlow",
		cf * CFrame.new(0, 0.06, 0),
		v3(width * 0.85, 0.08, len),
		PALETTE.focusDeep,
		Enum.Material.SmoothPlastic,
		false,
		0
	)
	makePart(
		parent,
		"CanalWater",
		cf * CFrame.new(0, 0.3, 0),
		v3(width, 0.2, len),
		PALETTE.canalWater,
		Enum.Material.SmoothPlastic,
		false,
		0.32
	)
	for sx = -1, 1, 2 do
		makePart(
			parent,
			"CanalStreak",
			cf * CFrame.new(sx * width * 0.22, 0.16, rand(-0.4, 0.4)),
			v3(0.24, 0.06, len * 0.88),
			PALETTE.falls,
			Enum.Material.Neon,
			false,
			0.18
		)
	end
	-- marble curbs (skip the part inside the pond)
	local curbLen = len - curbFrom
	if curbLen > 0.5 then
		for sx = -1, 1, 2 do
			local ccf = cf * CFrame.new(sx * (width / 2 + 0.32), 0.22, curbFrom / 2)
			makePart(
				parent,
				"CanalCurb",
				ccf,
				v3(0.64, 0.58, curbLen),
				jitter(PALETTE.marble, 0.01),
				Enum.Material.SmoothPlastic
			)
			makePart(
				parent,
				"CanalCurbTrim",
				ccf * CFrame.new(-sx * 0.24, 0.31, 0),
				v3(0.18, 0.1, curbLen),
				PALETTE.gold,
				Enum.Material.SmoothPlastic
			)
		end
	end
end

-- ============================================================================
-- Sections
-- ============================================================================
local function buildGround(walk: Instance, decor: Instance)
	local center = v3(0, 0, 0)
	for i = 0, EDGE_SEGMENTS - 1 do
		local a0 = i / EDGE_SEGMENTS * TAU
		local a1 = (i + 1) / EDGE_SEGMENTS * TAU
		makeTriangle(
			walk,
			"Grass",
			center,
			edgePoint(a0),
			edgePoint(a1),
			1.6,
			PALETTE.grass,
			Enum.Material.SmoothPlastic,
			true
		)
	end
	-- soft grass patches (tone variation)
	local patchF = makeFolder(decor, "GrassPatches")
	local made = 0
	local tries = 0
	while made < 26 and tries < 400 do
		tries += 1
		local p = v3(rand(-RX, RX), 0, rand(-RZ, RZ))
		if insideIsland(p, 6) and isFree(p, 2.5) then
			local s = rand(3.5, 8)
			makeEllipsoid(
				patchF,
				"GrassPatch",
				CFrame.new(p + v3(0, 0.02, 0)) * CFrame.Angles(0, rand(0, TAU), 0),
				v3(s, 0.12, s * rand(0.6, 0.9)),
				pickColor({ PALETTE.grassDark, PALETTE.grassLight }),
				Enum.Material.SmoothPlastic
			)
			made += 1
		end
	end
end

local function buildRim(walk: Instance, decor: Instance)
	for i = 0, EDGE_SEGMENTS - 1 do
		local a0 = i / EDGE_SEGMENTS * TAU
		local a1 = (i + 1) / EDGE_SEGMENTS * TAU
		local p0, p1 = edgePoint(a0), edgePoint(a1)
		local t = p1 - p0
		local len = t.Magnitude * 1.05
		local tangent = t.Unit
		local n = v3(tangent.Z, 0, -tangent.X)
		local mid = (p0 + p1) / 2
		local function seg(radial: number, y: number): CFrame
			return edgeFrame(mid + n * radial + v3(0, y, 0), tangent)
		end
		makePart(
			walk,
			"RimCurb",
			seg(-0.32, -0.02),
			v3(len, 0.82, 1.9),
			jitter(PALETTE.marble, 0.008),
			Enum.Material.SmoothPlastic,
			true
		)
		-- Top lustrous gold molding along the outer curb lip
		makePart(
			decor,
			"RimTrimTop",
			seg(0.54, 0.45),
			v3(len, 0.24, 0.52),
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
		-- Main warm ivory marble fascia wall (SmoothPlastic avoids gray Roblox Marble blotches!)
		makePart(
			decor,
			"RimBand",
			seg(-0.85, -1.98),
			v3(len, 3.16, 2.5),
			jitter(PALETTE.marbleShade, 0.008),
			Enum.Material.SmoothPlastic
		)
		-- Mid gold relief band
		makePart(
			decor,
			"RimTrimMid",
			seg(0.46, -1.45),
			v3(len, 0.42, 0.42),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		-- Bold bottom gold cornice separating marble rim from underside rock
		makePart(
			decor,
			"RimTrimBot",
			seg(0.44, -3.42),
			v3(len, 0.44, 0.48),
			PALETTE.goldDeep:Lerp(PALETTE.gold, 0.72),
			Enum.Material.SmoothPlastic
		)
		makePart(
			decor,
			"RimLip",
			seg(-0.75, -3.88),
			v3(len, 0.52, 2.6),
			jitter(PALETTE.marbleDark, 0.008),
			Enum.Material.SmoothPlastic
		)
	end
end

type RockLayer = { y: number, h: number, s: number, n: number }
local ROCK_LAYERS: { RockLayer } = {
	{ y = -6.8, h = 6.8, s = 0.99, n = 28 },
	{ y = -12.6, h = 6.6, s = 0.87, n = 24 },
	{ y = -18.2, h = 6.2, s = 0.72, n = 20 },
	{ y = -23.4, h = 5.6, s = 0.56, n = 16 },
	{ y = -28.0, h = 5.0, s = 0.39, n = 12 },
	{ y = -31.8, h = 4.4, s = 0.22, n = 8 },
}

local function buildRock(decor: Instance)
	local rockF = makeFolder(decor, "Rock")
	local crystF = makeFolder(decor, "RockCrystals")
	local avgR = (RX + RZ) / 2
	for k, layer in ROCK_LAYERS do
		local tcol = (k - 1) / (#ROCK_LAYERS - 1)
		local baseColor = PALETTE.rockTop:Lerp(PALETTE.rockBottom, tcol)
		makeEllipsoid(
			rockF,
			"RockCore",
			CFrame.new(0, layer.y, 0),
			v3(2 * RX * layer.s * 0.92, layer.h * 1.65, 2 * RZ * layer.s * 0.92),
			PALETTE.rockCore:Lerp(PALETTE.rockBottom, 0.35),
			Enum.Material.SmoothPlastic
		)
		local lean = 0.14 + 0.36 * (1 - layer.s)
		for j = 0, layer.n - 1 do
			local a = (j + rand(-0.2, 0.2)) / layer.n * TAU
			local outer = edgePoint(a, layer.s)
			local n = edgeNormal(a)
			local tangent = v3(-n.Z, 0, n.X)
			local w = TAU * avgR * layer.s / layer.n * rand(1.22, 1.48)
			local h = layer.h * rand(0.95, 1.32)
			local d = rand(7.2, 10.5) * (0.58 + 0.42 * layer.s)
			local inset = if k == 1 then 0.55 else rand(0.0, 1.2)
			local pos = outer - n * (d * 0.42 + inset) + v3(0, layer.y + rand(-0.9, 0.9), 0)
			if k == 1 then
				pos = v3(pos.X, math.min(pos.Y, -4.0 - h * 0.45), pos.Z)
			end
			local cf = edgeFrame(pos, tangent)
				* CFrame.Angles(-lean, 0, 0)
				* CFrame.Angles(rand(-0.18, 0.18), rand(-0.34, 0.34), rand(-0.22, 0.22))
			local col = jitter(baseColor, 0.028)
			-- Chiseled angular cliff boulder (faceted rotated block + angled bevel wedges!)
			makePart(
				rockF,
				"RockCrag",
				cf,
				v3(w * 0.96, h, d * 0.92),
				col,
				Enum.Material.SmoothPlastic
			)
			-- Sunlit beveled angular upper facet (classic stylized low-poly cliff look!)
			local bevelCF = cf
				* CFrame.new(rand(-w * 0.14, w * 0.14), h * 0.28, -d * 0.22)
				* CFrame.Angles(rand(-0.35, -0.1), rand(-0.35, 0.35), rand(-0.25, 0.25))
			makeWedge(
				rockF,
				"RockBevel",
				bevelCF,
				v3(w * rand(0.68, 0.92), h * rand(0.55, 0.78), d * 0.62),
				jitter(col:Lerp(PALETTE.rockHighlight, 0.48), 0.022),
				Enum.Material.SmoothPlastic
			)
			-- Deep angled shadow underside wedge
			if rng:NextNumber() < 0.72 then
				local underCF = cf
					* CFrame.new(rand(-w * 0.2, w * 0.2), -h * 0.3, -d * 0.18)
					* CFrame.Angles(
						math.pi + rand(-0.25, 0.2),
						rand(-0.35, 0.35),
						rand(-0.22, 0.22)
					)
				makeWedge(
					rockF,
					"RockUnder",
					underCF,
					v3(w * rand(0.62, 0.85), h * rand(0.5, 0.72), d * 0.58),
					jitter(col:Lerp(PALETTE.rockBottom, 0.5), 0.025),
					Enum.Material.SmoothPlastic
				)
			end
		end
	end
	-- Angular sculpted underside keel
	makePart(
		rockF,
		"RockTip",
		CFrame.new(0, -33.6, 0) * CFrame.Angles(0.15, math.pi / 4, 0.12),
		v3(15, 7.5, 13),
		PALETTE.rockBottom:Lerp(PALETTE.rockCore, 0.35),
		Enum.Material.SmoothPlastic
	)
	for i = 0, 5 do
		local a = i / 6 * TAU + 0.3
		local p = v3(math.cos(a) * 4.2, -35.6, math.sin(a) * 3.5)
		makeWedge(
			rockF,
			"RockKeel",
			CFrame.new(p) * CFrame.Angles(math.pi + rand(-0.25, 0.25), a, rand(-0.25, 0.25)),
			v3(4.8, 6.2, 4.4),
			jitter(PALETTE.rockBottom, 0.03),
			Enum.Material.SmoothPlastic
		)
	end

	-- HERO glowing crystal clusters facing the camera (matches concept art layout!)
	local heroCrystals = {
		{ a = math.rad(152), k = 2, dy = -0.5, scale = 2.6, col = PALETTE.crystalGold, n = 5 },
		{ a = math.rad(124), k = 3, dy = -1.2, scale = 2.3, col = PALETTE.crystalCyan, n = 4 },
		{ a = math.rad(96), k = 2, dy = -1.8, scale = 3.0, col = PALETTE.crystalGold, n = 5 },
		{ a = math.rad(66), k = 3, dy = -1.0, scale = 2.7, col = PALETTE.crystalGold, n = 5 },
		{ a = math.rad(38), k = 2, dy = -0.8, scale = 2.4, col = PALETTE.crystalGold, n = 4 },
		{ a = math.rad(82), k = 4, dy = -1.8, scale = 2.4, col = PALETTE.crystalCyan, n = 4 },
		{ a = math.rad(110), k = 5, dy = -1.6, scale = 2.2, col = PALETTE.crystalCyan, n = 4 },
	}
	for _, hc in heroCrystals do
		local layer = ROCK_LAYERS[hc.k]
		local n = edgeNormal(hc.a)
		local pos = edgePoint(hc.a, layer.s) + n * 0.4 + v3(0, layer.y + hc.dy, 0)
		local dir = (n * 0.82 + v3(0, -0.35, 0)).Unit
		makeCrystalCluster(crystF, cfFromUp(pos, dir, rand(0, math.pi)), hc.scale, hc.col, hc.n)
	end

	-- Supporting encrusted crystals around sides & back
	for c = 1, 18 do
		local k = randInt(1, 4)
		local layer = ROCK_LAYERS[k]
		local a = rand(0, TAU)
		local n = edgeNormal(a)
		local tangent = v3(-n.Z, 0, n.X)
		local pos = edgePoint(a, layer.s) + n * 0.2 + v3(0, layer.y + rand(-1.4, 1.0), 0)
		if k == 1 then
			pos = v3(pos.X, math.min(pos.Y, -5.5), pos.Z)
		end
		local dir = (n * 0.85 + v3(0, rand(-0.6, 0.05), 0) + tangent * rand(-0.25, 0.25)).Unit
		local color = if c % 3 == 0 then PALETTE.crystalCyan else PALETTE.crystalGold
		makeCrystalCluster(
			crystF,
			cfFromUp(pos, dir, rand(0, math.pi)),
			rand(1.3, 2.0),
			color,
			randInt(3, 4)
		)
	end
	-- Prominent cyan crystal stalactite cluster hanging from the bottom keel
	for c = 0, 4 do
		local a = c / 5 * TAU + 0.5
		local p = v3(math.cos(a) * 9.5, -33.2, math.sin(a) * 8.2)
		local dir = (v3(math.cos(a) * 0.35, -1, math.sin(a) * 0.35)).Unit
		makeCrystalCluster(
			crystF,
			cfFromUp(p, dir, rand(0, math.pi)),
			rand(1.9, 2.5),
			if c % 3 == 0 then PALETTE.crystalGold else PALETTE.crystalCyan,
			4
		)
	end
	makeCrystalCluster(crystF, cfFromUp(v3(0, -36.5, 0), v3(0, -1, 0)), 2.6, PALETTE.crystalCyan, 5)
end

local function buildPond(
	pond: Model,
	center: Vector3,
	r: number,
	waterColor: Color3,
	glowColor: Color3,
	skips: { { number } },
	waterTransparency: number?
): BasePart
	-- SmoothPlastic instead of Glass so layered underwater gradients & glowing fish remain vivid!
	-- Bottom sits at Y = 0.20 (strictly > ground Y = 0.00 to pass selfTest).
	local water = makeCylinderY(
		pond,
		"Water",
		CFrame.new(center.X, 0.325, center.Z),
		0.25,
		2 * r + 0.8,
		waterColor,
		Enum.Material.SmoothPlastic,
		false,
		waterTransparency or 0.36
	)
	local glow = makeCylinderY(
		pond,
		"WaterGlow",
		CFrame.new(center.X, 0.05, center.Z),
		0.08,
		2 * r,
		glowColor,
		Enum.Material.SmoothPlastic,
		false,
		0
	)
	addLight(glow, glowColor, 18, 0.75)
	local function skip(a: number): boolean
		for _, s in skips do
			local d = math.abs((a - s[1] + math.pi) % TAU - math.pi)
			if d < s[2] then
				return true
			end
		end
		return false
	end
	local rimCF = CFrame.new(center.X, 0.28, center.Z)
	makeRingBand(
		pond,
		"PondRim",
		rimCF,
		r + 0.75,
		1.55,
		1.06,
		PALETTE.marble,
		Enum.Material.SmoothPlastic,
		false,
		0,
		1.8,
		skip,
		0.008
	)
	makeRingBand(
		pond,
		"PondRimTrim",
		CFrame.new(center.X, 0.84, center.Z),
		r + 0.06,
		0.38,
		0.18,
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic,
		false,
		0,
		1.8,
		skip
	)
	addZone(center, nil, r + 1.6)
	return water
end

local function buildPonds(model: Model, decor: Instance): (Model, Model)
	local focus = makeModel(model, "FocusPond")
	local instinct = makeModel(model, "InstinctPond")

	-- Focus pond: crystal-aqua liquid light with warm luminous golden center
	buildPond(
		focus,
		FOCUS_C,
		FOCUS_R,
		PALETTE.focusWater,
		PALETTE.focusDeep,
		{ { 0, 0.24 }, { math.rad(70), 0.17 }, { math.rad(FOCUS_DECK_ANGLE), 0.28 } },
		0.36
	)
	local fx = FOCUS_C + v3(-2.4, 0, -1.6)
	makeCylinderY(
		focus,
		"FocusBedMid",
		CFrame.new(FOCUS_C.X, 0.09, FOCUS_C.Z),
		0.06,
		FOCUS_R * 1.68,
		PALETTE.focusWater,
		Enum.Material.SmoothPlastic
	)
	local focusGlowInner = makeCylinderY(
		focus,
		"FocusBedGlow",
		CFrame.new(fx.X, 0.13, fx.Z),
		0.06,
		FOCUS_R * 1.18,
		PALETTE.focusGlow,
		Enum.Material.Neon,
		false,
		0.22
	)
	addTag(
		focusGlowInner,
		TAG_PULSE,
		{ Min = 0.16, Max = 0.34, Speed = 1.0, Target = "Transparency" }
	)
	makeCylinderY(
		focus,
		"FocusBedCore",
		CFrame.new(fx.X, 0.17, fx.Z),
		0.04,
		FOCUS_R * 0.62,
		PALETTE.focusCore,
		Enum.Material.Neon,
		false,
		0.12
	)
	-- Crisp golden-white concentric surface ripples
	for i, r in { 2.8, 5.4, 8.2, 11.0 } do
		makeNeonRing(
			focus,
			"Ripple",
			CFrame.new(fx.X, 0.49, fx.Z),
			r,
			0.24 - i * 0.02,
			PALETTE.goldLight,
			0.08 + i * 0.08
		)
	end
	-- Three bold floating golden halos + two hovering golden orbs (concept art centerpiece!)
	local halos = makePivotModel(focus, "FocusHalos", CFrame.new(fx.X, 4.8, fx.Z))
	for i, spec in { { 6.2, 2.5 }, { 5.1, 4.9 }, { 4.0, 7.3 } } do
		makeNeonRing(
			halos,
			"Halo",
			CFrame.new(fx.X, spec[2], fx.Z),
			spec[1],
			0.44 - i * 0.04,
			PALETTE.goldLight,
			0.04
		)
	end
	for _, orbOff in { v3(6.8, 1.3, 6.2), v3(10.2, 4.5, 1.8) } do
		makeBall(halos, "FocusOrb", fx + orbOff, 1.15, PALETTE.goldGlow, Enum.Material.Neon)
		makeBall(
			halos,
			"FocusOrbAura",
			fx + orbOff,
			2.1,
			PALETTE.goldLight,
			Enum.Material.Neon,
			0.72
		)
	end
	addTag(halos, TAG_BOB, { Amplitude = 0.55, Speed = 1.15, Phase = 0 })
	local constellation = makeConstellation(
		focus,
		"FocusConstellation",
		CFrame.new(FOCUS_C.X - 2.0, 11.8, FOCUS_C.Z - 2.0),
		{
			v3(-8.5, 1.8, -6.5),
			v3(-3.0, 5.2, -8.0),
			v3(3.2, 2.6, -5.0),
			v3(8.0, 5.6, 1.2),
			v3(3.0, -0.8, 5.5),
			v3(-5.0, 3.0, 4.5),
			v3(10.5, 1.0, 6.8),
		},
		{ { 1, 2 }, { 2, 3 }, { 3, 4 }, { 3, 5 }, { 5, 6 }, { 6, 1 }, { 4, 7 } }
	)
	addTag(constellation, TAG_SPIN, { Speed = 8, Axis = "Y", Phase = 0 })
	local glints = makePart(
		focus,
		"FocusSparkleEmitter",
		CFrame.new(FOCUS_C.X, 2.4, FOCUS_C.Z),
		v3(20, 2.5, 20),
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	makeSparkles(glints, PALETTE.goldLight, 5, 0.38, 3.2, 0.9)

	-- 3 TALL majestic crystal pillars (~15 studs tall) with dreamy wide golden Beam light shafts
	local pillarSpots = { v3(-42.5, 0, -4.5), v3(-30.5, 0, -17.5), v3(-44.0, 0, 14.5) }
	for i, p in pillarSpots do
		local pcf = CFrame.new(p) * CFrame.Angles(0, rand(0, TAU), 0)
		makePart(
			decor,
			"PillarBase",
			pcf * CFrame.new(0, 0.65, 0),
			v3(4.0, 1.3, 4.0),
			PALETTE.marble,
			Enum.Material.SmoothPlastic
		)
		makePart(
			decor,
			"PillarBaseTrim",
			pcf * CFrame.new(0, 1.35, 0),
			v3(4.25, 0.22, 4.25),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		makeCylinderY(
			decor,
			"PillarShaft",
			pcf * CFrame.new(0, 4.1, 0),
			5.4,
			2.6,
			PALETTE.marbleShade,
			Enum.Material.SmoothPlastic
		)
		for _, y in { 2.0, 6.2 } do
			makeCylinderY(
				decor,
				"PillarBand",
				pcf * CFrame.new(0, y, 0),
				0.38,
				2.9,
				PALETTE.gold,
				Enum.Material.SmoothPlastic
			)
		end
		makeCylinderY(
			decor,
			"PillarCup",
			pcf * CFrame.new(0, 7.1, 0),
			0.8,
			3.4,
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
		for k = 0, 3 do
			local a = k / 4 * TAU
			makeWedge(
				decor,
				"PillarClaw",
				pcf * CFrame.Angles(0, a, 0) * CFrame.new(0, 8.4, 1.5),
				v3(0.48, 2.0, 0.7),
				PALETTE.goldLight,
				Enum.Material.SmoothPlastic
			)
		end
		local crystalCF = pcf * CFrame.new(0, 7.3, 0)
		local holder = makePivotModel(decor, "PillarCrystal", crystalCF)
		makeCrystal(
			holder,
			"PillarCrystal",
			crystalCF,
			7.8,
			1.5,
			if i == 2 then PALETTE.crystalPink else PALETTE.crystalCyan,
			true
		)
		makeCrystal(
			holder,
			"PillarCrystalInner",
			crystalCF * CFrame.new(0, 0.4, 0) * CFrame.Angles(0, math.pi / 6, 0),
			6.6,
			0.95,
			PALETTE.crystalPale,
			true
		)
		addTag(holder, TAG_BOB, { Amplitude = 0.4, Speed = 1.25, Phase = i })
		-- Wide ethereal upward-fading golden Beam light shafts (replacing stiff neon sticks!)
		if i <= 2 then
			local shaftAnchor = makePart(
				decor,
				"LightShaftAnchor",
				CFrame.new(p + v3(0, 14.2, 0)),
				v3(0.4, 0.4, 0.4),
				PALETTE.goldLight,
				Enum.Material.SmoothPlastic,
				false,
				1
			)
			for layer = 1, 2 do
				local a0 = Instance.new("Attachment")
				a0.Name = "ShaftA0_" .. layer
				a0.Position = v3(0, -1.0, 0)
				a0.Parent = shaftAnchor
				local a1 = Instance.new("Attachment")
				a1.Name = "ShaftA1_" .. layer
				a1.Position = v3(0, 82, 0)
				a1.Parent = shaftAnchor
				local b = Instance.new("Beam")
				b.Name = "LightShaftBeam_" .. layer
				b.Attachment0 = a0
				b.Attachment1 = a1
				b.FaceCamera = true
				b.Segments = 8
				b.Width0 = if layer == 1 then 1.8 else 4.6
				b.Width1 = if layer == 1 then 3.2 else 7.6
				b.LightEmission = 0.9
				b.LightInfluence = 0
				b.Color = ColorSequence.new(PALETTE.goldLight, PALETTE.cloudSunset)
				b.Transparency = if layer == 1
					then NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.25),
						NumberSequenceKeypoint.new(0.45, 0.52),
						NumberSequenceKeypoint.new(0.85, 0.85),
						NumberSequenceKeypoint.new(1, 1),
					})
					else NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.58),
						NumberSequenceKeypoint.new(0.45, 0.76),
						NumberSequenceKeypoint.new(0.85, 0.92),
						NumberSequenceKeypoint.new(1, 1),
					})
				b.Parent = shaftAnchor
			end
		end
		addZone(p, nil, 2.8)
	end

	-- Instinct pond: deep royal-purple outer rim -> rose-magenta -> warm golden-amber galaxy heart!
	buildPond(
		instinct,
		INSTINCT_C,
		INSTINCT_R,
		PALETTE.instinctWater,
		PALETTE.instinctDeep,
		{ { math.pi, 0.22 }, { math.rad(35), 0.16 }, { math.rad(INSTINCT_DECK_ANGLE), 0.28 } },
		0.48
	)
	local ix = INSTINCT_C + v3(1.2, 0, 1.0)
	-- Opaque stepped concentric gradient discs under translucent SmoothPlastic Water
	-- (opaque avoids Roblox transparent z-sorting glitches against the glowing fish!)
	local gradLayers = {
		{ c = INSTINCT_C, y = 0.06, d = INSTINCT_R * 1.84, col = PALETTE.instinctWater },
		{ c = ix - v3(0.9, 0, 0.7), y = 0.08, d = INSTINCT_R * 1.62, col = PALETTE.instinctMid },
		{ c = ix - v3(0.4, 0, 0.3), y = 0.10, d = INSTINCT_R * 1.36, col = PALETTE.instinctGlow },
		{
			c = ix + v3(0.1, 0, 0.1),
			y = 0.12,
			d = INSTINCT_R * 1.08,
			col = Color3.fromRGB(246, 134, 132),
		},
		{
			c = ix + v3(0.4, 0, 0.25),
			y = 0.14,
			d = INSTINCT_R * 0.78,
			col = Color3.fromRGB(252, 174, 108),
		},
	}
	for idx, gl in gradLayers do
		makeCylinderY(
			instinct,
			"WaterGrad" .. idx,
			CFrame.new(gl.c.X, gl.y, gl.c.Z),
			0.035,
			gl.d,
			gl.col,
			Enum.Material.SmoothPlastic,
			false,
			0
		)
	end
	local instinctCore = makeCylinderY(
		instinct,
		"WaterGlowCore",
		CFrame.new(ix.X + 0.5, 0.16, ix.Z + 0.3),
		0.035,
		INSTINCT_R * 0.5,
		PALETTE.instinctGold,
		Enum.Material.SmoothPlastic,
		false,
		0
	)
	local instinctAura = makeCylinderY(
		instinct,
		"WaterGlowAura",
		CFrame.new(ix.X + 0.5, 0.18, ix.Z + 0.3),
		0.02,
		INSTINCT_R * 0.58,
		PALETTE.instinctGold,
		Enum.Material.Neon,
		false,
		0.72
	)
	addTag(
		instinctAura,
		TAG_PULSE,
		{ Min = 0.64, Max = 0.82, Speed = 1.0, Target = "Transparency" }
	)
	-- Delicate shimmering caustic ripples & golden glints
	for i, r in { 8.6, 11.8 } do
		makeNeonRing(
			instinct,
			"RainbowRipple",
			CFrame.new(INSTINCT_C.X, 0.48, INSTINCT_C.Z),
			r,
			0.14,
			if i == 1 then PALETTE.instinctGold else PALETTE.pastelPink,
			0.42
		)
	end
	for _ = 1, 14 do
		local a, d = rand(0, TAU), rand(2.0, INSTINCT_R - 2.5)
		local p = INSTINCT_C + v3(math.cos(a) * d, 0.2, math.sin(a) * d)
		makePart(
			instinct,
			"GoldGlint",
			CFrame.new(p) * CFrame.Angles(0, rand(0, TAU), 0),
			v3(0.24, 0.04, rand(1.1, 2.4)),
			PALETTE.goldGlow,
			Enum.Material.Neon,
			false,
			0.35
		)
	end

	-- 4 LARGE sculptural glowing Legendary Fish (opaque Neon body -> 100% immune to water z-sorting!)
	local fishFolder = makeFolder(instinct, "LegendaryFish")
	local fishSpecs = {
		{ radius = 6.2, speed = 0.38, phase = 0.35, rainbow = false, len = 5.4 },
		{ radius = 8.8, speed = -0.28, phase = 2.35, rainbow = true, len = 6.2 },
		{ radius = 10.6, speed = 0.24, phase = 4.15, rainbow = false, len = 5.4 },
		{ radius = 7.4, speed = -0.34, phase = 5.5, rainbow = true, len = 5.6 },
	}
	local fishY = 0.44
	for i, spec in fishSpecs do
		local pos = INSTINCT_C
			+ v3(math.cos(spec.phase) * spec.radius, fishY, math.sin(spec.phase) * spec.radius)
		local sgn = if spec.speed >= 0 then 1 else -1
		local dir = v3(-math.sin(spec.phase), 0, math.cos(spec.phase)) * sgn
		local fcf = CFrame.lookAt(pos, pos + dir)
		local fish = makePivotModel(fishFolder, "LegendaryFish" .. i, fcf)
		local len = spec.len
		local bodyCol = if spec.rainbow then PALETTE.pastelAqua else Color3.fromRGB(255, 162, 46)
		local rimCol = if spec.rainbow then PALETTE.pastelPink else PALETTE.goldLight
		-- Opaque deep violet silhouette halo just beneath the fish so golden fish pop over any pond color!
		makeEllipsoid(
			fish,
			"FishShadow",
			fcf * CFrame.new(0, -0.2, 0.05),
			v3(len * 0.42, 0.1, len * 0.88),
			PALETTE.instinctDeep,
			Enum.Material.SmoothPlastic,
			0
		)
		makeEllipsoid(
			fish,
			"FishBody",
			fcf * CFrame.new(0, 0, -len * 0.08),
			v3(len * 0.36, 0.42, len * 0.78),
			bodyCol,
			Enum.Material.Neon,
			0
		)
		makeEllipsoid(
			fish,
			"FishTailBody",
			fcf * CFrame.new(0.12, 0, len * 0.32) * CFrame.Angles(0, 0.14, 0),
			v3(len * 0.22, 0.32, len * 0.45),
			rimCol,
			Enum.Material.Neon,
			0
		)
		if spec.rainbow then
			local stripes = { PALETTE.pastelPink, PALETTE.pastelLemon, PALETTE.pastelMint }
			for k, c in stripes do
				makeEllipsoid(
					fish,
					"FishStripe",
					fcf * CFrame.new(0, 0.02, -len * 0.3 + k * len * 0.16),
					v3(len * 0.38, 0.44, len * 0.16),
					c,
					Enum.Material.Neon,
					0
				)
			end
		else
			makeEllipsoid(
				fish,
				"FishSpineGlow",
				fcf * CFrame.new(0, 0.06, -len * 0.05),
				v3(len * 0.2, 0.42, len * 0.58),
				PALETTE.goldLight,
				Enum.Material.Neon,
				0
			)
		end
		-- Graceful forked flowing tail + wide sweeping pectoral fins (opaque so always crisp!)
		for sx = -1, 1, 2 do
			makeEllipsoid(
				fish,
				"FishTail",
				fcf * CFrame.new(sx * 0.52, 0, len * 0.62) * CFrame.Angles(0, sx * 0.58, 0),
				v3(len * 0.24, 0.14, len * 0.46),
				rimCol,
				Enum.Material.Neon,
				0
			)
			makeEllipsoid(
				fish,
				"FishFin",
				fcf * CFrame.new(sx * len * 0.26, 0, -len * 0.06) * CFrame.Angles(0, sx * 0.92, 0),
				v3(len * 0.14, 0.1, len * 0.36),
				rimCol,
				Enum.Material.Neon,
				0
			)
		end
		makeBall(
			fish,
			"FishEye",
			(fcf * CFrame.new(0, 0.18, -len * 0.34)).Position,
			0.24,
			PALETTE.eye,
			Enum.Material.SmoothPlastic
		)
		fish:SetAttribute("OrbitRadius", spec.radius)
		fish:SetAttribute("OrbitSpeed", spec.speed)
		fish:SetAttribute("OrbitPhase", spec.phase)
		fish:SetAttribute("DepthY", (ORIGIN_CF * CFrame.new(0, fishY, 0)).Position.Y)
		fish:SetAttribute(
			"OrbitCenter",
			(ORIGIN_CF * CFrame.new(INSTINCT_C.X, fishY, INSTINCT_C.Z)).Position
		)
	end
	local _ = instinctCore

	local fireflies = makeFolder(instinct, "Fireflies")
	for i = 1, 12 do
		local a = rand(0, TAU)
		local base = if i <= 6 then TREE_BASE else INSTINCT_C
		local d = if i <= 6 then rand(4, 10) else rand(4, 13)
		local p = base + v3(math.cos(a) * d, rand(2.5, 9.5), math.sin(a) * d)
		local m = makePivotModel(fireflies, "Firefly", CFrame.new(p))
		makeBall(m, "FireflyGlow", p, 0.38, PALETTE.goldGlow, Enum.Material.Neon)
		makeBall(m, "FireflyHalo", p, 0.95, PALETTE.goldLight, Enum.Material.Neon, 0.72)
		addTag(
			m,
			TAG_BOB,
			{ Amplitude = rand(0.45, 0.95), Speed = rand(1.0, 1.9), Phase = rand(0, TAU) }
		)
	end
	return focus, instinct
end

local function buildCanals(decor: Instance)
	local canals = makeFolder(decor, "CanalsAndFalls")
	-- central canal linking both ponds cleanly (under the bridge)
	makeCanal(
		canals,
		v3(FOCUS_C.X + FOCUS_R - 0.15, 0, 2),
		v3(INSTINCT_C.X - INSTINCT_R + 0.15, 0, 2),
		4.4,
		1.0
	)
	addZone(v3(-10, 0, 2), v3(9, 0, 2), 2.6)
	-- three canals that become the waterfalls
	local specs = {
		{
			from = FOCUS_C
				+ v3(math.cos(math.rad(70)), 0, math.sin(math.rad(70))) * (FOCUS_R - 0.6),
			theta = 1.94,
			width = 3.2,
			curbFrom = 1.6,
		},
		{ from = v3(5.6, 0, 3.8), theta = 1.332, width = 3.2, curbFrom = 0.6 },
		{
			from = INSTINCT_C
				+ v3(math.cos(math.rad(35)), 0, math.sin(math.rad(35))) * (INSTINCT_R - 0.6),
			theta = 0.52,
			width = 2.8,
			curbFrom = 1.6,
		},
	}
	for _, s in specs do
		local e = edgePoint(s.theta)
		local n = edgeNormal(s.theta)
		local stop = e - n * 0.95
		makeCanal(canals, s.from, stop, s.width, s.curbFrom)
		makeFalls(canals, e, n, s.width, 46)
		addZone(s.from, stop, s.width / 2 + 0.8)
	end
end

local function canalLeftXAt(z: number): number
	local a = FOCUS_C + v3(math.cos(math.rad(70)), 0, math.sin(math.rad(70))) * (FOCUS_R - 1)
	local b = edgePoint(1.94) - edgeNormal(1.94) * 0.95
	local t = (z - a.Z) / (b.Z - a.Z)
	return a.X + (b.X - a.X) * t
end

local function buildPortal(walk: Instance, decor: Instance)
	local portalF = makeFolder(decor, "Portal")
	-- Grand stepped warm-ivory pedestal (walkable; top = STEP_TOP = 1.8)
	local steps = {
		{ y = 0.3, w = 20.4, d = 12.2, z = -33.0 },
		{ y = 0.9, w = 17.2, d = 9.4, z = -34.2 },
		{ y = 1.5, w = 15.0, d = 6.8, z = -35.2 },
	}
	for i, s in steps do
		makePart(
			walk,
			"PortalStep",
			CFrame.new(0, s.y, s.z),
			v3(s.w, 0.6, s.d),
			jitter(PALETTE.marble, 0.006),
			Enum.Material.SmoothPlastic,
			true
		)
		makePart(
			portalF,
			"PortalStepTrim",
			CFrame.new(0, s.y + 0.22, s.z + s.d / 2 + 0.04),
			v3(s.w + 0.08, 0.18, 0.16),
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
		if i == 1 then
			for sx = -1, 1, 2 do
				makePart(
					portalF,
					"PortalStepTrim",
					CFrame.new(sx * (s.w / 2 + 0.04), s.y + 0.22, s.z),
					v3(0.16, 0.18, s.d + 0.08),
					PALETTE.goldLight,
					Enum.Material.SmoothPlastic
				)
			end
		end
	end
	local top = STEP_TOP
	local zP = PORTAL_Z
	local pillarX = 5.6
	-- Grand heroic warm-ivory & gold pillars
	for sx = -1, 1, 2 do
		local x = sx * pillarX
		makePart(
			portalF,
			"PortalPlinth",
			CFrame.new(x, top + 0.75, zP),
			v3(3.8, 1.5, 3.8),
			PALETTE.marble,
			Enum.Material.SmoothPlastic
		)
		makePart(
			portalF,
			"PortalPlinthTrim",
			CFrame.new(x, top + 1.56, zP),
			v3(4.0, 0.22, 4.0),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		makePart(
			portalF,
			"PortalShaft",
			CFrame.new(x, top + 6.4, zP),
			v3(2.85, 9.8, 2.85),
			jitter(PALETTE.marble, 0.006),
			Enum.Material.SmoothPlastic
		)
		for _, y in { 2.4, 10.6 } do
			makePart(
				portalF,
				"PortalBand",
				CFrame.new(x, top + y, zP),
				v3(3.25, 0.48, 3.25),
				PALETTE.gold,
				Enum.Material.SmoothPlastic
			)
		end
		makePart(
			portalF,
			"PortalInlay",
			CFrame.new(x, top + 6.5, zP + 1.46),
			v3(1.15, 6.4, 0.1),
			PALETTE.marbleShade,
			Enum.Material.SmoothPlastic
		)
		makePart(
			portalF,
			"PortalInlayGold",
			CFrame.new(x, top + 6.5, zP + 1.52),
			v3(0.26, 5.4, 0.08),
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
		makePart(
			portalF,
			"PortalGem",
			CFrame.new(x, top + 6.5, zP + 1.58) * CFrame.Angles(0, 0, math.pi / 4),
			v3(0.75, 0.75, 0.28),
			PALETTE.crystalCyan,
			Enum.Material.Neon
		)
		makePart(
			portalF,
			"PortalCapital",
			CFrame.new(x, top + 11.4, zP),
			v3(3.6, 0.95, 3.6),
			PALETTE.marble,
			Enum.Material.SmoothPlastic
		)
		makePart(
			portalF,
			"PortalCapitalTrim",
			CFrame.new(x, top + 11.95, zP),
			v3(3.75, 0.2, 3.75),
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
		-- Graceful sculpted angelic wings framing cleanly OUTSIDE the arch
		makeWing(portalF, CFrame.new(sx * 7.45, top + 9.4, zP - 0.15), sx, 1.06)
		-- Prominent cyan & gold crystals flanking the portal base
		makeCrystalCluster(
			portalF,
			CFrame.new(sx * 8.6, top, zP + 1.8) * CFrame.Angles(0, 0, -sx * 0.22),
			1.15,
			PALETTE.crystalCyan,
			5
		)
		makeCrystalCluster(
			portalF,
			CFrame.new(sx * 11.8, 0, zP + 5.2) * CFrame.Angles(0, 0, -sx * 0.25),
			1.25,
			PALETTE.crystalCyan,
			5
		)
		makeCrystalCluster(portalF, CFrame.new(sx * 10.8, 0, zP - 0.8), 0.8, PALETTE.crystalGold, 3)
	end

	-- Seamless airtight semicircle celestial arch + bold gold inner/outer moldings
	local archC = v3(0, top + 11.6, zP)
	local nSeg = 18
	for i = 0, nSeg - 1 do
		local a = (i + 0.5) / nSeg * math.pi
		local dir = v3(math.cos(a), math.sin(a), 0)
		local tangent = v3(-math.sin(a), math.cos(a), 0)
		local midR = pillarX
		local segLen = math.pi * midR / nSeg * 1.24
		local cf = CFrame.fromMatrix(archC + dir * midR, tangent, dir, Vector3.zAxis)
		makePart(
			portalF,
			"PortalArch",
			cf,
			v3(segLen, 2.9, 3.0),
			jitter(PALETTE.marble, 0.005),
			Enum.Material.SmoothPlastic
		)
		local inCF = CFrame.fromMatrix(archC + dir * (midR - 1.48), tangent, dir, Vector3.zAxis)
		makePart(
			portalF,
			"PortalArchGold",
			inCF,
			v3(math.pi * (midR - 1.48) / nSeg * 1.26, 0.42, 3.25),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		local outCF = CFrame.fromMatrix(archC + dir * (midR + 1.48), tangent, dir, Vector3.zAxis)
		makePart(
			portalF,
			"PortalArchRim",
			outCF,
			v3(math.pi * (midR + 1.48) / nSeg * 1.26, 0.4, 3.2),
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
		makePart(
			portalF,
			"PortalArchFace",
			CFrame.fromMatrix(archC + dir * midR + v3(0, 0, 1.54), tangent, dir, Vector3.zAxis),
			v3(segLen * 0.52, 0.24, 0.08),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end

	-- Pointed celestial gable crown + luminous faceted cyan diamond keystone
	local keyY = top + 17.9
	makePart(
		portalF,
		"PortalKeystone",
		CFrame.new(0, keyY, zP) * CFrame.Angles(0, 0, math.pi / 4),
		v3(3.5, 3.5, 3.3),
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makePart(
		portalF,
		"PortalKeystoneGold",
		CFrame.new(0, keyY, zP + 1.66) * CFrame.Angles(0, 0, math.pi / 4),
		v3(2.85, 2.85, 0.14),
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic
	)
	makePart(
		portalF,
		"PortalKeystoneDiamond",
		CFrame.new(0, keyY, zP + 1.8) * CFrame.Angles(0, 0, math.pi / 4),
		v3(1.95, 1.95, 0.36),
		PALETTE.crystalCyan,
		Enum.Material.Neon
	)
	makeCrystal(
		portalF,
		"PortalTopCrystal",
		CFrame.new(0, keyY + 1.8, zP),
		3.6,
		0.9,
		PALETTE.crystalCyan,
		true
	)

	-- SEAMLESS OPAQUE IRIDESCENT ARCH BACKING + FULL-ARCH SPINNING RAINBOW SPIRAL
	-- (Opaque backing at zP - 0.34 guarantees ZERO Roblox transparent z-sorting glitches!)
	local openY = top + 11.6
	local backCol = Color3.fromRGB(154, 114, 238)
	makePart(
		portalF,
		"PortalGlow",
		CFrame.new(0, (top + openY) / 2, zP - 0.34),
		v3(8.5, openY - top, 0.2),
		backCol,
		Enum.Material.SmoothPlastic,
		false,
		0
	)
	makeCylinderZ(
		portalF,
		"PortalGlowTop",
		CFrame.new(0, openY, zP - 0.34),
		0.2,
		8.5,
		backCol,
		Enum.Material.SmoothPlastic,
		0
	)

	local vc = v3(0, top + 8.6, zP + 0.02)
	local vortex = makePivotModel(portalF, "PortalVortex", CFrame.new(vc))
	-- Opaque layered glowing pastel rainbow aura discs (clean depth order, zero transparency cuts!)
	local auraSpecs = {
		{ r = 4.2, z = -0.20, col = PALETTE.pastelLilac },
		{ r = 3.55, z = -0.14, col = PALETTE.pastelPink },
		{ r = 2.9, z = -0.08, col = PALETTE.pastelAqua },
		{ r = 2.2, z = -0.02, col = PALETTE.pastelMint },
		{ r = 1.5, z = 0.04, col = PALETTE.pastelLemon },
	}
	for _, au in auraSpecs do
		makeCylinderZ(
			vortex,
			"VortexAura",
			CFrame.new(vc + v3(0, 0, au.z)),
			0.05,
			au.r * 2,
			au.col,
			Enum.Material.Neon,
			0
		)
	end
	local armCols = {
		PALETTE.pastelPink,
		PALETTE.pastelPeach,
		PALETTE.pastelLemon,
		PALETTE.pastelMint,
		PALETTE.pastelAqua,
		PALETTE.pastelLilac,
	}
	for arm = 0, 5 do
		local prev = vc + v3(0, 0, 0.16)
		local col = armCols[(arm % #armCols) + 1]
		for k = 1, 20 do
			local t = k / 20
			local a = arm * (TAU / 6) + t * 2.75 * math.pi
			local rx = 0.25 + 4.1 * t
			local ry = 0.25 + 5.2 * t
			local p = vc + v3(math.cos(a) * rx, math.sin(a) * ry, 0.16)
			makeSegment(
				vortex,
				"VortexArm",
				prev,
				p,
				0.6 * (1.16 - t * 0.38),
				0.14,
				col,
				Enum.Material.Neon,
				0
			)
			prev = p
		end
	end
	local eye = makeBall(
		vortex,
		"VortexEye",
		vc + v3(0, 0, 0.26),
		1.65,
		Color3.fromRGB(255, 250, 234),
		Enum.Material.Neon
	)
	addTag(eye, TAG_PULSE, { Min = 0.0, Max = 0.18, Speed = 1.4, Target = "Transparency" })
	addTag(vortex, TAG_SPIN, { Speed = 24, Axis = "Z", Phase = 0 })

	local fx = makePart(
		portalF,
		"PortalSparkleEmitter",
		CFrame.new(vc + v3(0, 0, 0.7)),
		v3(8, 12, 0.5),
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	makeSparkles(fx, PALETTE.goldLight, 7, 0.42, 2.2, 1.8)
	addLight(fx, PALETTE.pastelLilac, 20, 1.35)
	addZone(v3(0, 0, zP), nil, 9.5)
	addZone(v3(-12, 0, zP + 3), v3(12, 0, zP + 3), 2.8)
end

local function buildPath(walk: Instance, decor: Instance)
	local pathF = makeFolder(decor, "PathRunes")
	local function tile(pos: Vector3, yaw: number, w: number, d: number)
		local cf = CFrame.new(pos.X, 0.1, pos.Z) * CFrame.Angles(0, yaw, 0)
		makePart(
			walk,
			"PathTile",
			cf,
			v3(w, 0.3, d),
			jitter(PALETTE.marble, 0.015),
			Enum.Material.SmoothPlastic,
			true
		)
		makePart(
			pathF,
			"PathTileEdge",
			cf * CFrame.new(0, -0.02, 0),
			v3(w + 0.16, 0.22, d + 0.16),
			PALETTE.goldDeep,
			Enum.Material.SmoothPlastic
		)
		drawRune(
			pathF,
			cf * CFrame.new(0, 0.17, 0),
			math.min(w, d) * 0.4,
			RUNES[randInt(1, #RUNES)],
			0.2,
			PALETTE.goldGlow,
			Enum.Material.Neon
		)
	end
	-- main path: portal -> bridge
	local zA, zB = -27.9, -6.4
	local rows = 6
	local gap = 0.25
	local depth = (zB - zA - (rows - 1) * gap) / rows
	for r = 0, rows - 1 do
		local z = zA + depth / 2 + r * (depth + gap)
		for sx = -1, 1, 2 do
			tile(v3(sx * 1.85, 0, z), rand(-0.03, 0.03), 3.45, depth)
		end
	end
	for sx = -1, 1, 2 do
		makePart(
			pathF,
			"PathBorder",
			CFrame.new(sx * 3.85, 0.08, (zA + zB) / 2),
			v3(0.3, 0.2, zB - zA),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end
	addZone(v3(0, 0, zA), v3(0, 0, zB), 4.4)
	-- front path after the bridge
	for r = 0, 1 do
		local z = 12.0 + r * 3.6
		for sx = -1, 1, 2 do
			tile(v3(sx * 1.85, 0, z), rand(-0.04, 0.04), 3.45, 3.35)
		end
	end
	addZone(v3(0, 0, 10), v3(0, 0, 17.5), 4.2)
	-- stepping tiles to the Focus deck (with a slab over the left canal)
	local steps = {
		v3(-4.2, 0, 18.6),
		v3(-7.6, 0, 19.6),
		v3(-11.1, 0, 20.1),
		v3(-14.6, 0, 20.2),
		v3(-21.6, 0, 20.0),
		v3(-25.0, 0, 19.6),
		v3(-28.3, 0, 18.5),
	}
	for i, p in steps do
		tile(p, rand(-0.25, 0.25), 2.7, 2.7)
		if i > 1 then
			addZone(steps[i - 1], p, 1.9)
		end
	end
	local slabX = canalLeftXAt(20.1)
	local slabCF = CFrame.new(slabX, 0.42, 20.1)
	makePart(
		walk,
		"CanalSlab",
		slabCF,
		v3(5.2, 0.36, 3.4),
		jitter(PALETTE.marble, 0.01),
		Enum.Material.SmoothPlastic,
		true
	)
	for sz = -1, 1, 2 do
		makePart(
			pathF,
			"CanalSlabTrim",
			slabCF * CFrame.new(0, 0.12, sz * 1.72),
			v3(5.24, 0.14, 0.1),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end
	addZone(v3(slabX - 2.5, 0, 20.1), v3(slabX + 2.5, 0, 20.1), 2)
end

local function bridgePoint(t: number, x: number): Vector3
	local z = BRIDGE_Z0 + (BRIDGE_Z1 - BRIDGE_Z0) * t
	return v3(x, BRIDGE_BASE + BRIDGE_RISE * math.sin(math.pi * t), z)
end

local function buildBridge(walk: Instance, decor: Instance)
	local bridgeF = makeFolder(decor, "Bridge")
	local n = 12
	for i = 0, n - 1 do
		local p0, p1 = bridgePoint(i / n, 0), bridgePoint((i + 1) / n, 0)
		local cf = frameAlong(p0, p1)
		local len = (p1 - p0).Magnitude * 1.02
		makePart(
			walk,
			"BridgeDeck",
			cf * CFrame.new(0, -0.3, 0),
			v3(BRIDGE_W, 0.6, len),
			jitter(PALETTE.marble, 0.01),
			Enum.Material.SmoothPlastic,
			true
		)
		makePart(
			bridgeF,
			"BridgeUnder",
			cf * CFrame.new(0, -0.95, 0),
			v3(BRIDGE_W - 0.6, 0.7, len),
			PALETTE.marbleShade,
			Enum.Material.SmoothPlastic
		)
		for sx = -1, 1, 2 do
			makePart(
				bridgeF,
				"BridgeCurb",
				cf * CFrame.new(sx * (BRIDGE_W / 2 + 0.15), 0.05, 0),
				v3(0.5, 0.8, len),
				PALETTE.marble,
				Enum.Material.SmoothPlastic
			)
			makePart(
				bridgeF,
				"BridgeCurbGold",
				cf * CFrame.new(sx * (BRIDGE_W / 2 + 0.44), -0.15, 0),
				v3(0.18, 0.28, len),
				PALETTE.gold,
				Enum.Material.SmoothPlastic
			)
		end
		-- warm golden step seam
		makePart(
			bridgeF,
			"BridgeSeam",
			cf * CFrame.new(0, 0.015, -len / 2),
			v3(BRIDGE_W - 0.3, 0.04, 0.14),
			PALETTE.goldDeep:Lerp(PALETTE.marbleDark, 0.45),
			Enum.Material.SmoothPlastic
		)
	end
	-- abutments
	for _, t in { 0, 1 } do
		local p = bridgePoint(t, 0)
		makePart(
			bridgeF,
			"BridgeAbutment",
			CFrame.new(p.X, -0.25, p.Z),
			v3(BRIDGE_W + 1.4, 0.9, 1.6),
			PALETTE.marbleShade,
			Enum.Material.SmoothPlastic
		)
	end
	-- railings: posts, bold gold top rail and balusters
	local postTs = { 0, 0.2, 0.4, 0.6, 0.8, 1.0 }
	for sx = -1, 1, 2 do
		local x = sx * (BRIDGE_W / 2 + 0.15)
		local prevTop: Vector3? = nil
		local prevT = 0
		for _, t in postTs do
			local base = bridgePoint(t, x)
			local postH = if t == 0 or t == 1 then 2.9 else 2.35
			makePart(
				bridgeF,
				"BridgePost",
				CFrame.new(base + v3(0, postH / 2, 0)),
				v3(0.82, postH, 0.82),
				PALETTE.marble,
				Enum.Material.SmoothPlastic
			)
			makePart(
				bridgeF,
				"BridgePostBand",
				CFrame.new(base + v3(0, postH - 0.32, 0)),
				v3(0.94, 0.2, 0.94),
				PALETTE.gold,
				Enum.Material.SmoothPlastic
			)
			makeBall(
				bridgeF,
				"BridgePostCap",
				base + v3(0, postH + 0.28, 0),
				0.82,
				PALETTE.goldLight,
				Enum.Material.SmoothPlastic
			)
			local topP = base + v3(0, 2.05, 0)
			if prevTop then
				makeSegment(
					bridgeF,
					"BridgeRail",
					prevTop,
					topP,
					0.5,
					0.36,
					PALETTE.marble,
					Enum.Material.SmoothPlastic
				)
				makeSegment(
					bridgeF,
					"BridgeRailGold",
					prevTop + v3(0, 0.22, 0),
					topP + v3(0, 0.22, 0),
					0.34,
					0.14,
					PALETTE.goldLight,
					Enum.Material.SmoothPlastic
				)
				for k = 1, 3 do
					local tt = prevT + (t - prevT) * k / 4
					local b = bridgePoint(tt, x)
					makeCylinderY(
						bridgeF,
						"BridgeBaluster",
						CFrame.new(b + v3(0, 1.0, 0)),
						1.6,
						0.32,
						PALETTE.marbleShade,
						Enum.Material.SmoothPlastic
					)
					makeBall(
						bridgeF,
						"BridgeBalusterKnob",
						b + v3(0, 1.0, 0),
						0.42,
						PALETTE.marble,
						Enum.Material.SmoothPlastic
					)
				end
			end
			prevTop = topP
			prevT = t
		end
	end
	addZone(v3(0, 0, BRIDGE_Z0 - 1), v3(0, 0, BRIDGE_Z1 + 1), 3.6)
end

type DeckInfo = { spot: Vector3, frame: CFrame }

local function buildDeck(
	walk: Instance,
	decor: Instance,
	name: string,
	center: Vector3,
	r: number,
	angleDeg: number,
	cushions: boolean
): DeckInfo
	local deckF = makeFolder(decor, name .. "Props")
	local a = math.rad(angleDeg)
	local u = v3(math.cos(a), 0, math.sin(a))
	local up = v3(0, 1, 0)
	local rim = center + u * r
	local mid = rim + u * ((DECK_LEN_OUT - DECK_LEN_IN) / 2)
	local frame = CFrame.fromMatrix(mid, up:Cross(u), up, u)
	local total = DECK_LEN_OUT + DECK_LEN_IN
	local planks = 7
	local gap = 0.08
	local d = (total - (planks - 1) * gap) / planks
	for i = 0, planks - 1 do
		local z = -total / 2 + d / 2 + i * (d + gap)
		makePart(
			walk,
			name,
			frame * CFrame.new(0, DECK_TOP - 0.13, z),
			v3(DECK_W, 0.26, d),
			jitter(PALETTE.marble, 0.014),
			Enum.Material.SmoothPlastic,
			true
		)
	end
	for sx = -1, 1, 2 do
		makePart(
			deckF,
			"DeckBeam",
			frame * CFrame.new(sx * (DECK_W * 0.38), 0.32, 0),
			v3(0.56, 0.58, total),
			PALETTE.marbleDark,
			Enum.Material.SmoothPlastic
		)
		makePart(
			deckF,
			"DeckTrim",
			frame * CFrame.new(sx * (DECK_W / 2 + 0.06), DECK_TOP - 0.08, 0),
			v3(0.18, 0.24, total),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		for sz = -1, 1, 2 do
			local pcf = frame * CFrame.new(sx * (DECK_W / 2 - 0.28), 0, sz * (total / 2 - 0.34))
			makeCylinderY(
				deckF,
				"DeckPost",
				pcf * CFrame.new(0, 0.85, 0),
				2.35,
				0.82,
				PALETTE.marble,
				Enum.Material.SmoothPlastic
			)
			makeCylinderY(
				deckF,
				"DeckPostBand",
				pcf * CFrame.new(0, 1.65, 0),
				0.18,
				0.95,
				PALETTE.gold,
				Enum.Material.SmoothPlastic
			)
			makeBall(
				deckF,
				"DeckPostCap",
				(pcf * CFrame.new(0, 2.15, 0)).Position,
				0.92,
				PALETTE.goldLight,
				Enum.Material.SmoothPlastic
			)
		end
	end
	-- Chunky warm wooden stool near the water end, spot right next to it
	makeStool(deckF, frame * CFrame.new(1.6, DECK_TOP, -2.5))
	if cushions then
		makeCushion(
			deckF,
			frame * CFrame.new(-1.6, DECK_TOP + 0.26, -2.6),
			v3(2.2, 0.62, 1.85),
			PALETTE.goldLight
		)
		makeCushion(
			deckF,
			frame * CFrame.new(-1.4, DECK_TOP + 0.24, -0.5) * CFrame.Angles(0, 0.38, 0),
			v3(2.0, 0.56, 1.7),
			PALETTE.fabric
		)
	end
	addZone(rim + u * DECK_LEN_OUT, rim - u * DECK_LEN_IN, 3.8)
	return { spot = (frame * CFrame.new(0, DECK_TOP + 1, -1.4)).Position, frame = frame }
end

local function buildTree(decor: Instance)
	local treeF = makeFolder(decor, "BlossomTree")
	local B = TREE_BASE
	-- Heroic sweeping S-curved golden trunk (~12.4 studs high -> canopy reaches ~22 studs!)
	local trunk = {
		B + v3(0, -0.3, 0),
		B + v3(1.5, 2.8, 0.6),
		B + v3(-1.1, 6.2, 1.2),
		B + v3(1.2, 9.4, 0.2),
		B + v3(-0.3, 12.2, -0.4),
	}
	local widths = { 3.2, 2.65, 2.25, 1.85 }
	for i = 1, #trunk - 1 do
		makeSegment(
			treeF,
			"TreeTrunk",
			trunk[i],
			trunk[i + 1],
			widths[i],
			widths[i],
			PALETTE.goldWood,
			Enum.Material.SmoothPlastic,
			0,
			true
		)
		makeBall(
			treeF,
			"TreeKnot",
			trunk[i + 1],
			widths[i] * 1.04,
			PALETTE.goldWood,
			Enum.Material.SmoothPlastic
		)
		-- Luminous swirling golden grain ribbons along the trunk
		makeSegment(
			treeF,
			"TreeStreak",
			trunk[i] + v3(0.55, 0, 0.55),
			trunk[i + 1] + v3(-0.55, 0, 0.55),
			widths[i] * 0.34,
			widths[i] * 0.34,
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic,
			0,
			true
		)
	end
	for i = 0, 5 do
		local a = i / 6 * TAU + 0.3
		local p = B + v3(math.cos(a) * 2.3, 0.55, math.sin(a) * 2.3)
		makeEllipsoid(
			treeF,
			"TreeRoot",
			CFrame.lookAt(p, p + v3(math.cos(a), -0.35, math.sin(a))),
			v3(1.4, 1.2, 4.2),
			PALETTE.goldWood:Lerp(PALETTE.woodDark, 0.15),
			Enum.Material.SmoothPlastic
		)
	end
	local top = trunk[#trunk]
	-- 7 lush multi-tiered cherry-blossom clusters (~20 studs wide, ~22 studs tall!)
	local clumps = {
		{ c = B + v3(-6.2, 15.2, 2.2), r = 4.9 },
		{ c = B + v3(5.6, 15.0, -1.6), r = 4.6 },
		{ c = B + v3(0.4, 18.8, 1.2), r = 5.4 },
		{ c = B + v3(-3.0, 17.6, -3.6), r = 4.2 },
		{ c = B + v3(3.4, 17.8, 3.8), r = 4.1 },
		{ c = B + v3(-6.8, 13.0, -2.0), r = 3.5 },
		{ c = B + v3(6.6, 12.6, 2.6), r = 3.6 },
	}
	for _, cl in clumps do
		makeSegment(
			treeF,
			"TreeBranch",
			top,
			cl.c - (cl.c - top).Unit * cl.r * 0.62,
			1.2,
			1.2,
			PALETTE.goldWood,
			Enum.Material.SmoothPlastic,
			0,
			true
		)
	end
	local canopy = makePivotModel(treeF, "TreeCanopy", CFrame.new(top))
	for _, cl in clumps do
		-- Deep rose shaded base cloud (flattened slightly for organic layered sakura look)
		makeEllipsoid(
			canopy,
			"BlossomBase",
			CFrame.new(cl.c + v3(0, -cl.r * 0.22, 0)),
			v3(cl.r * 1.9, cl.r * 1.08, cl.r * 1.85),
			PALETTE.blossomDeep,
			Enum.Material.SmoothPlastic
		)
		-- Abundant varied smaller layered blossom tufts (organic sakura cloud, never smooth balloons!)
		for _ = 1, 16 do
			local a = rand(0, TAU)
			local elev = rand(-0.32, 0.85)
			local dist = cl.r * rand(0.45, 0.98)
			local p = cl.c + v3(math.cos(a) * dist, elev * cl.r * 0.72, math.sin(a) * dist)
			local s = cl.r * rand(0.38, 0.64)
			local col = if elev > 0.34
				then PALETTE.blossomLight
				elseif elev < -0.05 then PALETTE.blossomDeep:Lerp(PALETTE.blossom, 0.42)
				else PALETTE.blossom
			makeEllipsoid(
				canopy,
				"Blossom",
				CFrame.new(p) * CFrame.Angles(rand(-0.2, 0.2), rand(0, TAU), rand(-0.2, 0.2)),
				v3(s * 1.22, s * 0.74, s * 1.18),
				jitter(col, 0.025),
				Enum.Material.SmoothPlastic
			)
		end
		-- Crisp sunlit 5-petal sakura blossom accents across the upper crown
		for _ = 1, 7 do
			local dir = v3(rand(-1, 1), rand(0.15, 1), rand(-1, 1)).Unit
			local p = cl.c + v3(dir.X * cl.r * 1.05, dir.Y * cl.r * 0.74, dir.Z * cl.r * 1.05)
			local fcf = cfFromUp(p, dir, rand(0, TAU))
			makeEllipsoid(
				canopy,
				"BlossomFlower",
				fcf,
				v3(1.18, 0.26, 1.18),
				Color3.fromRGB(255, 224, 238),
				Enum.Material.SmoothPlastic
			)
			makeBall(
				canopy,
				"BlossomHeart",
				(fcf * CFrame.new(0, 0.12, 0)).Position,
				0.34,
				PALETTE.goldLight,
				Enum.Material.SmoothPlastic
			)
		end
	end
	addTag(canopy, TAG_SWAY, { Angle = 2.6, Speed = 1.05, Phase = 0 })
	local petals = makePart(
		treeF,
		"PetalEmitter",
		CFrame.new(B + v3(0, 15.5, 0)),
		v3(13, 3, 13),
		PALETTE.blossom,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	local pe = makeSparkles(petals, PALETTE.blossomLight, 5, 0.45, 5.5, 1.1)
	pe.Name = "Petals"
	pe.LightEmission = 0.25
	pe.Acceleration = v3(0.45, -0.75, 0.25)
	-- Radiant double golden halo around the base
	makeNeonRing(treeF, "TreeHalo", CFrame.new(B.X, 0.16, B.Z), 5.2, 0.34, PALETTE.goldGlow, 0.04)
	makeNeonRing(treeF, "TreeHalo", CFrame.new(B.X, 0.13, B.Z), 6.4, 0.2, PALETTE.goldLight, 0.38)
	local glow = makePart(
		treeF,
		"TreeGlow",
		CFrame.new(B + v3(0, 4.5, 0)),
		v3(1, 1, 1),
		PALETTE.blossom,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	addLight(glow, PALETTE.blossomLight, 20, 0.95)
	for i = 1, 10 do
		local a = rand(0, TAU)
		local p = B + v3(math.cos(a) * rand(2.5, 7.2), 0.06, math.sin(a) * rand(2.5, 7.2))
		makeEllipsoid(
			treeF,
			"FallenPetal",
			CFrame.new(p) * CFrame.Angles(0, rand(0, TAU), 0),
			v3(0.68, 0.08, 0.42),
			if i % 2 == 0 then PALETTE.blossom else PALETTE.blossomLight,
			Enum.Material.SmoothPlastic
		)
	end
	addZone(B, nil, 6.2)
end

local function buildFence(decor: Instance)
	local fenceF = makeFolder(decor, "RopeFence")
	local canalA: { Vector3 } = {
		FOCUS_C + v3(math.cos(math.rad(70)), 0, math.sin(math.rad(70))) * (FOCUS_R - 1),
		v3(5.6, 0, 3.8),
	}
	local canalB: { Vector3 } = { edgePoint(1.94), edgePoint(1.332) }
	local function nearCanal(p: Vector3, r: number): boolean
		for i = 1, #canalA do
			if distToSegmentXZ(p, canalA[i], canalB[i]) < r then
				return true
			end
		end
		return false
	end
	local function run(a0: number, a1: number)
		local points: { Vector3 } = {}
		local valid: { boolean } = {}
		local steps = math.floor(math.abs(a1 - a0) * 46 / 5.4 + 0.5)
		for i = 0, steps do
			local a = a0 + (a1 - a0) * i / steps
			local p = edgePoint(a) - edgeNormal(a) * 3.0
			table.insert(points, p)
			table.insert(valid, not nearCanal(p, 2.6))
		end
		for i, p in points do
			if valid[i] then
				makeCylinderY(
					fenceF,
					"FencePost",
					CFrame.new(p + v3(0, 1.2, 0)),
					2.4,
					1.0,
					PALETTE.marble,
					Enum.Material.SmoothPlastic
				)
				makeCylinderY(
					fenceF,
					"FencePostBand",
					CFrame.new(p + v3(0, 1.98, 0)),
					0.18,
					1.12,
					PALETTE.gold,
					Enum.Material.SmoothPlastic
				)
				makeEllipsoid(
					fenceF,
					"FencePostCap",
					CFrame.new(p + v3(0, 2.46, 0)),
					v3(1.16, 0.65, 1.16),
					PALETTE.marble,
					Enum.Material.SmoothPlastic
				)
				if i < #points and valid[i + 1] then
					makeRope(
						fenceF,
						p + v3(0, 1.95, 0),
						points[i + 1] + v3(0, 1.95, 0),
						0.68,
						0.26,
						PALETTE.rope
					)
				end
			end
		end
	end
	run(2.55, 1.40)
	run(3.40, 4.10)
end

local function buildProps(decor: Instance)
	local propsF = makeFolder(decor, "Props")
	makeCrown(propsF, CROWN_BASE + v3(0, 0, 1.6), 1.42)
	addZone(CROWN_BASE + v3(0, 0, 1.6), nil, 5.2)
	-- Heroic fish statue in warm marble beside the portal
	local sp = v3(-11.8, 0, -18.5)
	makeCylinderY(
		propsF,
		"StatueBase",
		CFrame.new(sp + v3(0, 0.6, 0)),
		1.2,
		3.8,
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		propsF,
		"StatueBaseTrim",
		CFrame.new(sp + v3(0, 1.24, 0)),
		0.18,
		4.0,
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		propsF,
		"StatueColumn",
		CFrame.new(sp + v3(0, 2.3, 0)),
		2.1,
		2.4,
		PALETTE.marbleShade,
		Enum.Material.SmoothPlastic
	)
	makeCylinderY(
		propsF,
		"StatueTop",
		CFrame.new(sp + v3(0, 3.55, 0)),
		0.48,
		3.1,
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	local fcf = CFrame.new(sp + v3(0, 5.2, 0))
		* CFrame.Angles(0, math.rad(-22), 0)
		* CFrame.Angles(math.rad(22), 0, 0)
	makeEllipsoid(
		propsF,
		"StatueFish",
		fcf,
		v3(1.55, 2.05, 4.4),
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makeEllipsoid(
		propsF,
		"StatueFishTail",
		fcf * CFrame.new(0, 0.55, 2.4) * CFrame.Angles(-0.6, 0, 0),
		v3(0.45, 1.9, 1.25),
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makeEllipsoid(
		propsF,
		"StatueFishTail",
		fcf * CFrame.new(0, -0.48, 2.35) * CFrame.Angles(0.6, 0, 0),
		v3(0.45, 1.65, 1.1),
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makeWedge(
		propsF,
		"StatueFishFin",
		fcf * CFrame.new(0, 1.18, 0.28),
		v3(0.28, 0.96, 1.65),
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic
	)
	for sx = -1, 1, 2 do
		makeBall(
			propsF,
			"StatueFishEye",
			(fcf * CFrame.new(sx * 0.65, 0.28, -1.35)).Position,
			0.34,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end
	addZone(sp, nil, 2.4)
	-- Banners, signs, barrels, lanterns (positioned cleanly outside enlarged ponds!)
	makeBanner(propsF, v3(-11.4, 0, -27.2), v3(0, 0, 1))
	makeBanner(propsF, v3(11.4, 0, -27.2), v3(0, 0, 1))
	makeBanner(propsF, v3(9.8, 0, 21.0), v3(-0.25, 0, 1))
	makeBanner(propsF, v3(-17.0, 0, -17.0), v3(0.35, 0, 1))
	makeSign(propsF, v3(8.2, 0, -22.0), v3(-0.4, 0, 1), "CELESTIAL")
	makeSign(propsF, v3(-36.5, 0, 23.0), v3(0.3, 0, 1), "FOCO")
	makeSign(propsF, v3(33.5, 0, 18.2), v3(-0.35, 0, 1), "INSTINTO")
	makeSign(propsF, v3(4.8, 0, 22.8), v3(0, 0, 1), "x50")
	makeBarrel(propsF, v3(-13.4, 0, 26.8))
	makeBarrel(propsF, v3(6.8, 0, -12.8))
	makeBarrel(propsF, v3(-36.4, 0, 14.5))
	makeLanternPost(propsF, v3(-16.2, 0, 24.8), v3(1, 0, 0.3))
	makeLanternPost(propsF, v3(-38.0, 0, 18.6), v3(1, 0, -0.4))
	makeLanternPost(propsF, v3(38.8, 0, -10.5), v3(-1, 0, 0.2))
	makeLanternPost(propsF, v3(15.2, 0, -23.5), v3(-1, 0, 0))
	makeLanternPost(propsF, v3(-15.2, 0, -25.5), v3(1, 0, 0))
	makeLanternPost(propsF, v3(41.8, 0, 8.8), v3(-1, 0, -0.3))
	-- Rune stones circling the Instinct pond
	local runeSpots = {
		v3(13.5, 0, 20.6),
		v3(20.5, 0, 20.0),
		v3(27.5, 0, 18.8),
		v3(39.8, 0, -2.0),
		v3(11.8, 0, -13.6),
		v3(44.2, 0, 2.2),
	}
	for _, p in runeSpots do
		local toPond = (INSTINCT_C - p).Unit
		makeRuneStone(propsF, p, (toPond * 0.4 + v3(0, 0, 1)))
	end
end

local function buildScatter(decor: Instance)
	local scatterF = makeFolder(decor, "Scatter")
	-- flower beds flanking the portal
	for sx = -1, 1, 2 do
		local c = v3(sx * 15.2, 0, -31.5)
		makeRingBand(
			scatterF,
			"FlowerBedRim",
			CFrame.new(c.X, 0.22, c.Z),
			2.5,
			0.55,
			0.5,
			PALETTE.marble,
			Enum.Material.SmoothPlastic,
			false,
			0,
			1.3,
			nil,
			0.01
		)
		makeRingBand(
			scatterF,
			"FlowerBedTrim",
			CFrame.new(c.X, 0.5, c.Z),
			2.5,
			0.6,
			0.08,
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false,
			0,
			1.3
		)
		makeCylinderY(
			scatterF,
			"FlowerBedSoil",
			CFrame.new(c.X, 0.2, c.Z),
			0.3,
			4.6,
			PALETTE.grassDark,
			Enum.Material.SmoothPlastic
		)
		for _ = 1, 9 do
			local a, d = rand(0, TAU), rand(0, 1.8)
			makeFlower(scatterF, c + v3(math.cos(a) * d, 0.3, math.sin(a) * d))
		end
		addZone(c, nil, 3)
	end
	-- bushes near the rim
	local bushes, bushTries = 0, 0
	while bushes < 18 and bushTries < 400 do
		bushTries += 1
		local a = rand(0, TAU)
		local p = edgePoint(a, rand(0.8, 0.9))
		if isFree(p, 1.6) then
			makeBush(scatterF, p, rand(0.8, 1.2))
			addZone(p, nil, 1.4)
			bushes += 1
		end
	end
	local function scatter(count: number, radius: number, margin: number, fn: (Vector3) -> ())
		local made, attempts = 0, 0
		while made < count and attempts < count * 30 do
			attempts += 1
			local p = v3(rand(-RX, RX), 0, rand(-RZ, RZ))
			if insideIsland(p, margin) and isFree(p, radius) then
				fn(p)
				made += 1
				if radius > 0.9 then
					addZone(p, nil, radius * 0.6)
				end
			end
		end
	end
	scatter(105, 0.45, 1.6, function(p: Vector3)
		makeGrassTuft(scatterF, p, rand(0.95, 1.45))
	end)
	scatter(22, 0.75, 2.4, function(p: Vector3)
		for _ = 1, randInt(2, 3) do
			makeFlower(scatterF, p + v3(rand(-0.9, 0.9), 0, rand(-0.9, 0.9)))
		end
	end)
	scatter(30, 0.65, 2.0, function(p: Vector3)
		local s = rand(0.65, 1.35)
		makeEllipsoid(
			scatterF,
			"Pebble",
			CFrame.new(p + v3(0, 0.12, 0)) * CFrame.Angles(0, rand(0, TAU), 0),
			v3(s * 1.3, s * 0.55, s),
			jitter(pickColor({ PALETTE.stone, PALETTE.marbleShade }), 0.02),
			Enum.Material.SmoothPlastic
		)
	end)
	scatter(7, 1.2, 4, function(p: Vector3)
		makeCrystalCluster(
			scatterF,
			CFrame.new(p) * CFrame.Angles(rand(-0.15, 0.15), 0, rand(-0.15, 0.15)),
			rand(0.55, 0.8),
			if rng:NextNumber() < 0.5 then PALETTE.crystalCyan else PALETTE.crystalGold,
			3
		)
	end)
	-- grass fringe hugging the rim curb
	for i = 0, EDGE_SEGMENTS - 1, 2 do
		local a = (i + 0.5) / EDGE_SEGMENTS * TAU
		local p = edgePoint(a) - edgeNormal(a) * 1.5
		if isFree(p, 0.3) then
			makeGrassTuft(scatterF, p, 0.9)
		end
	end
end

local function buildSky(decor: Instance)
	local skyF = makeFolder(decor, "Sky")
	-- Sleek luminous double golden orbit ring with star beads & sparkles
	local ring = makePivotModel(skyF, "OrbitRing", CFrame.new(0, RING_Y, 0))
	makeRingBand(
		ring,
		"OrbitRingA",
		CFrame.new(0, RING_Y, 0),
		60.5,
		0.56,
		0.52,
		PALETTE.goldLight,
		Enum.Material.Neon,
		false,
		0.08,
		4.0
	)
	makeRingBand(
		ring,
		"OrbitRingB",
		CFrame.new(0, RING_Y - 0.3, 0),
		64.5,
		0.32,
		0.32,
		PALETTE.goldGlow,
		Enum.Material.Neon,
		false,
		0.28,
		4.4
	)
	for i = 0, 9 do
		local a = i / 10 * TAU
		local p = v3(math.cos(a) * 60.5, RING_Y, math.sin(a) * 60.5)
		makeBall(ring, "OrbitBead", p, 1.35, PALETTE.goldGlow, Enum.Material.Neon)
		-- Sleek tapered 4-point celestial diamond sparkles alternating on the outer halo
		if i % 2 == 0 then
			local sp = v3(math.cos(a + 0.3) * 64.5, RING_Y + 0.2, math.sin(a + 0.3) * 64.5)
			makeEllipsoid(
				ring,
				"OrbitStarV",
				CFrame.new(sp),
				v3(0.28, 2.5, 0.28),
				Color3.fromRGB(255, 250, 224),
				Enum.Material.Neon
			)
			makeEllipsoid(
				ring,
				"OrbitStarH",
				CFrame.new(sp),
				v3(2.5, 0.28, 0.28),
				Color3.fromRGB(255, 250, 224),
				Enum.Material.Neon
			)
			makeBall(ring, "OrbitStarCore", sp, 0.65, PALETTE.goldLight, Enum.Material.Neon)
		end
	end
	addTag(ring, TAG_SPIN, { Speed = 8, Axis = "Y", Phase = 0 })

	-- Floating islets framed cleanly in CameraShot (left-front, right-front, and rear)
	makeIslet(skyF, "IsletFrontLeft", v3(-57, -15, 29), 1.18, 0)
	makeIslet(skyF, "IsletFrontRight", v3(58, -17, 26), 1.08, 2.2)
	makeIslet(skyF, "IsletBack", v3(-33, -18, -68), 0.88, 4.1)

	-- Sculpted undulating golden-hour sea of clouds (broad, soft, pillowy — never eggs or flat floor!)
	local cloudF = makeFolder(skyF, "CloudSea")
	local tints = {
		PALETTE.cloudCream,
		PALETTE.cloudSunset,
		PALETTE.cloudPink,
		PALETTE.cloudLilac,
		PALETTE.cloudBlue,
	}
	local rings = {
		{ r = 0, n = 1, scale = 68, y = -58, puffs = 5 },
		{ r = 64, n = 8, scale = 58, y = -56, puffs = 5 },
		{ r = 122, n = 12, scale = 72, y = -54, puffs = 5 },
		{ r = 186, n = 16, scale = 88, y = -54, puffs = 4 },
		{ r = 262, n = 18, scale = 112, y = -56, puffs = 4 },
	}
	for _, ringSpec in rings do
		for i = 0, ringSpec.n - 1 do
			local a = (i + rand(-0.22, 0.22)) / ringSpec.n * TAU
			local rr = ringSpec.r + rand(-0.1, 0.1) * math.max(ringSpec.r, 12)
			local c = v3(math.cos(a) * rr, ringSpec.y + rand(-3.0, 2.5), math.sin(a) * rr)
			local tint = if c.X < -30
				then pickColor({ PALETTE.cloudSunset, PALETTE.cloudCream, PALETTE.cloudPink })
				elseif c.X > 30 then pickColor({
					PALETTE.cloudLilac,
					PALETTE.cloudPink,
					PALETTE.cloudBlue,
				})
				else pickColor(tints)
			makeCloud(cloudF, c, ringSpec.scale * rand(0.9, 1.15), ringSpec.puffs, tint)
		end
	end
	-- Sweeping golden-hour cumulus horizon banks framing the left, right, and rear sky
	local horizonSpecs = {
		{ pos = v3(-225, -4, -155), scale = 90, tint = PALETTE.cloudSunset },
		{ pos = v3(-160, -14, -200), scale = 82, tint = PALETTE.cloudCream },
		{ pos = v3(-85, -26, -240), scale = 80, tint = PALETTE.cloudPink },
		{ pos = v3(0, -30, -255), scale = 86, tint = PALETTE.cloudPink },
		{ pos = v3(95, -24, -235), scale = 82, tint = PALETTE.cloudLilac },
		{ pos = v3(175, -12, -195), scale = 88, tint = PALETTE.cloudLilac },
		{ pos = v3(235, 2, -155), scale = 96, tint = PALETTE.cloudPink },
		{ pos = v3(-200, 26, -175), scale = 68, tint = PALETTE.cloudSunset },
		{ pos = v3(205, 32, -170), scale = 72, tint = PALETTE.cloudPink },
	}
	for _, hs in horizonSpecs do
		makeCloud(cloudF, hs.pos, hs.scale, 4, hs.tint)
	end

	-- Vivid sweeping pastel-rainbow aurora curtains (rose-magenta, sunrise gold, mint-emerald, violet!)
	local auroraF = makeFolder(skyF, "Aurora")
	local anchor = makePart(
		auroraF,
		"AuroraAnchor",
		CFrame.new(0, 38, -135),
		v3(1, 1, 1),
		PALETTE.pastelLilac,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	local auroraFade = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.26),
		NumberSequenceKeypoint.new(0.66, 0.38),
		NumberSequenceKeypoint.new(1, 1),
	})
	local auroraColors = {
		Color3.fromRGB(255, 74, 166), -- rose-magenta
		Color3.fromRGB(255, 168, 72), -- sunrise gold-peach
		Color3.fromRGB(255, 212, 86), -- warm lemon-gold
		Color3.fromRGB(64, 236, 178), -- celestial mint-emerald
		Color3.fromRGB(76, 206, 255), -- sky aqua
		Color3.fromRGB(168, 86, 255), -- royal violet
		Color3.fromRGB(246, 94, 188), -- sunset rose
	}
	for band = 1, 3 do
		local count = 15
		for i = 0, count - 1 do
			local t = i / (count - 1)
			local x = -220 + 440 * t
			local arch = math.sin(t * math.pi) * 28
			local z = -band * 22 + math.sin(t * math.pi * 2.5 + band) * 18
			local y = arch + band * 7 + math.sin(t * math.pi * 2 + band) * 5
			local h = rand(68, 98)
			local idxA = math.clamp(math.floor(t * (#auroraColors - 1)) + 1, 1, #auroraColors - 1)
			local colA = auroraColors[idxA]
			local colB = auroraColors[idxA + 1]
			local tiltX = (t - 0.5) * 32 + rand(-6, 6)
			local a0 = Instance.new("Attachment")
			a0.Name = "AuroraA0"
			a0.Position = v3(x, y - h * 0.46, z)
			a0.Parent = anchor
			local a1 = Instance.new("Attachment")
			a1.Name = "AuroraA1"
			a1.Position = v3(x + tiltX, y + h * 0.54, z)
			a1.Parent = anchor
			local beam = Instance.new("Beam")
			beam.Name = "AuroraBeam"
			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Width0 = 38
			beam.Width1 = 54
			beam.FaceCamera = true
			beam.Segments = 8
			beam.CurveSize0 = rand(-14, 14)
			beam.CurveSize1 = rand(-14, 14)
			beam.LightEmission = 0.52
			beam.LightInfluence = 0
			beam.Color = ColorSequence.new(colA, colB)
			beam.Transparency = auroraFade
			beam.Parent = anchor
		end
	end

	-- Celestial air: golden sparkles + graceful drifting feathers
	local air = makePart(
		skyF,
		"AirSparkleEmitter",
		CFrame.new(0, 14, 0),
		v3(105, 26, 88),
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	makeSparkles(air, PALETTE.goldLight, 7, 0.34, 4.5, 0.45)
	for i = 1, 11 do
		local a = rand(0, TAU)
		local d = rand(46, 68)
		local p = v3(math.cos(a) * d, rand(-6, 14), math.sin(a) * d)
		local m = makePivotModel(skyF, "Feather", CFrame.new(p))
		local fcf = CFrame.new(p) * CFrame.Angles(rand(-0.5, 0.5), rand(0, TAU), rand(0.7, 1.3))
		makeEllipsoid(
			m,
			"FeatherVane",
			fcf,
			v3(0.85, 2.8, 0.16),
			PALETTE.fabric,
			Enum.Material.SmoothPlastic
		)
		makePart(
			m,
			"FeatherQuill",
			fcf * CFrame.new(0, -0.2, -0.09),
			v3(0.1, 2.8, 0.06),
			PALETTE.goldLight,
			Enum.Material.SmoothPlastic
		)
		addTag(m, TAG_BOB, { Amplitude = rand(0.6, 1.3), Speed = rand(1.0, 1.5), Phase = i })
	end
end

local function buildContract(model: Model, focusSpot: Vector3, instinctSpot: Vector3): Part
	local function marker(name: string, cf: CFrame, size: Vector3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = ORIGIN_CF * cf
		p.Transparency = 1
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = true
		p.CastShadow = false
		p.Parent = model
		return p
	end
	local center = marker("IslandCenter", CFrame.new(0, 0, 0), v3(2, 2, 2))
	model.PrimaryPart = center

	local spawn =
		marker("ArrivalSpawn", CFrame.lookAt(SPAWN_POS, v3(0, SPAWN_POS.Y, 0)), v3(4, 1, 4))
	CollectionService:AddTag(spawn, "ZoneSpawn")
	spawn:SetAttribute("Destination", "training_celestial")

	local portal = marker("ReturnPortal", CFrame.new(0, STEP_TOP + 4.1, PORTAL_Z), v3(6, 8, 2.4))
	portal.CanTouch = true
	portal.CanQuery = true
	CollectionService:AddTag(portal, "ZonePortal")
	portal:SetAttribute("PortalId", "training_celestial_to_main")
	portal:SetAttribute("ZoneId", "lagoon")
	portal:SetAttribute("Destination", "main")

	local focus = marker("FocusSpot", CFrame.new(focusSpot), v3(5.5, 2, 5.5))
	CollectionService:AddTag(focus, "TrainingSpot")
	focus:SetAttribute("TrainingIsland", 4)
	focus:SetAttribute("TrainingStat", "Control")

	local instinct = marker("InstinctSpot", CFrame.new(instinctSpot), v3(5.5, 2, 5.5))
	CollectionService:AddTag(instinct, "TrainingSpot")
	instinct:SetAttribute("TrainingIsland", 4)
	instinct:SetAttribute("TrainingStat", "Instinct")

	local cam = marker("CameraShot", CFrame.lookAt(CAMERA_POS, v3(0, 0, 0)), v3(1, 1, 1))
	cam:SetAttribute("FieldOfView", 55)
	return center
end

-- ============================================================================
-- Public API
-- ============================================================================
function Builder.build(origin: Vector3?): Model
	local t0 = os.clock()
	local o = origin or DEFAULT_ORIGIN
	ORIGIN_CF = CFrame.new(o)
	rng = Random.new(SEED)
	zones = {}
	animatedCount = 0

	local folder = Workspace:FindFirstChild(FOLDER_NAME)
	if folder == nil then
		folder = makeFolder(Workspace, FOLDER_NAME)
	end
	local root = folder :: Instance
	local old = root:FindFirstChild(MODEL_NAME)
	while old do
		old:Destroy()
		old = root:FindFirstChild(MODEL_NAME)
	end

	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	local walk = makeFolder(model, "Walkable")
	local decor = makeFolder(model, "Decor")

	-- reserve zones for the main features before scattering
	buildRim(walk, makeFolder(decor, "Rim"))
	buildPonds(model, makeFolder(decor, "FocusFeatures"))
	task.wait()
	buildPortal(walk, decor)
	buildPath(walk, decor)
	buildBridge(walk, decor)
	local focusDeck = buildDeck(walk, decor, "FocusDeck", FOCUS_C, FOCUS_R, FOCUS_DECK_ANGLE, true)
	local instinctDeck =
		buildDeck(walk, decor, "InstinctDeck", INSTINCT_C, INSTINCT_R, INSTINCT_DECK_ANGLE, false)
	buildCanals(decor)
	task.wait()
	buildTree(decor)
	buildProps(decor)
	buildFence(decor)
	addZone(SPAWN_POS, nil, 2.5)
	addZone(v3(0, 0, -22), v3(34.6, 0, -12.5), 1.6) -- walking line to the Instinct deck
	buildGround(walk, decor)
	buildScatter(decor)
	task.wait()
	buildRock(decor)
	task.wait()
	buildSky(decor)
	buildContract(model, focusDeck.spot, instinctDeck.spot)

	model.Parent = root

	local count = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			count += 1
		end
	end
	print(
		string.format(
			"[TrainingIsland4Builder] %s built: %d BaseParts, %d animated tags, %.2fs",
			MODEL_NAME,
			count,
			animatedCount,
			os.clock() - t0
		)
	)
	if count > PART_LIMIT then
		warn(
			string.format(
				"[TrainingIsland4Builder] part count %d is above the %d budget",
				count,
				PART_LIMIT
			)
		)
	end
	return model
end

-- ----------------------------------------------------------------------------
-- Self test
-- ----------------------------------------------------------------------------
local function worldHalfY(p: BasePart): number
	local cf = p.CFrame
	local s = p.Size
	return math.abs(cf.RightVector.Y) * s.X / 2
		+ math.abs(cf.UpVector.Y) * s.Y / 2
		+ math.abs(cf.LookVector.Y) * s.Z / 2
end

function Builder.selfTest(origin: Vector3?): { string }
	local failures: { string } = {}
	local function fail(msg: string)
		table.insert(failures, msg)
	end

	local folder = Workspace:FindFirstChild(FOLDER_NAME)
	local found = if folder then folder:FindFirstChild(MODEL_NAME) else nil
	local model: Model
	if found and found:IsA("Model") then
		model = found
	else
		model = Builder.build(origin)
	end

	-- contract ---------------------------------------------------------------
	type Spec = {
		name: string,
		size: Vector3?,
		tag: string?,
		attrs: { [string]: any },
		touch: boolean?,
	}
	local specs: { Spec } = {
		{ name = "IslandCenter", size = v3(2, 2, 2), attrs = {} },
		{
			name = "ArrivalSpawn",
			size = v3(4, 1, 4),
			tag = "ZoneSpawn",
			attrs = { Destination = "training_celestial" },
		},
		{
			name = "ReturnPortal",
			size = v3(6, 8, 2.4),
			tag = "ZonePortal",
			attrs = {
				PortalId = "training_celestial_to_main",
				ZoneId = "lagoon",
				Destination = "main",
			},
			touch = true,
		},
		{
			name = "FocusSpot",
			size = v3(5.5, 2, 5.5),
			tag = "TrainingSpot",
			attrs = { TrainingIsland = 4, TrainingStat = "Control" },
		},
		{
			name = "InstinctSpot",
			size = v3(5.5, 2, 5.5),
			tag = "TrainingSpot",
			attrs = { TrainingIsland = 4, TrainingStat = "Instinct" },
		},
		{ name = "CameraShot", size = v3(1, 1, 1), attrs = { FieldOfView = 55 } },
	}
	local parts: { [string]: BasePart } = {}
	for _, spec in specs do
		local inst = model:FindFirstChild(spec.name)
		if inst == nil or not inst:IsA("BasePart") then
			fail("missing direct child BasePart: " .. spec.name)
			continue
		end
		local p = inst :: BasePart
		parts[spec.name] = p
		if not p.Anchored then
			fail(spec.name .. " not anchored")
		end
		if p.Transparency ~= 1 then
			fail(spec.name .. " Transparency ~= 1")
		end
		if p.CanCollide then
			fail(spec.name .. " CanCollide should be false")
		end
		if p.CastShadow then
			fail(spec.name .. " CastShadow should be false")
		end
		if spec.size and (p.Size - spec.size).Magnitude > 0.01 then
			fail(spec.name .. " has wrong size")
		end
		if spec.touch and not (p.CanTouch and p.CanQuery) then
			fail(spec.name .. " needs CanTouch and CanQuery")
		end
		if spec.tag and not CollectionService:HasTag(p, spec.tag) then
			fail(spec.name .. " missing tag " .. spec.tag)
		end
		for k, v in spec.attrs do
			local got = p:GetAttribute(k)
			if got ~= v or typeof(got) ~= typeof(v) then
				fail(
					string.format(
						"%s attribute %s = %s (%s), expected %s (%s)",
						spec.name,
						k,
						tostring(got),
						typeof(got),
						tostring(v),
						typeof(v)
					)
				)
			end
		end
	end
	if model.PrimaryPart ~= parts.IslandCenter then
		fail("PrimaryPart is not IslandCenter")
	end
	for _, name in { "FocusPond", "InstinctPond" } do
		local m = model:FindFirstChild(name)
		if m == nil or not m:IsA("Model") then
			fail("missing direct child Model " .. name)
		end
	end
	local center = if parts.IslandCenter
		then parts.IslandCenter.Position
		else (origin or DEFAULT_ORIGIN)
	local cam = parts.CameraShot
	if cam then
		if (cam.Position - (center + CAMERA_POS)).Magnitude > 0.05 then
			fail("CameraShot not at center + (0, 48, 100)")
		end
		if cam.CFrame.LookVector:Dot((center - cam.Position).Unit) < 0.999 then
			fail("CameraShot does not look at the island center")
		end
	end
	local spawnPart = parts.ArrivalSpawn
	if
		spawnPart
		and spawnPart.CFrame.LookVector:Dot(
				(v3(center.X, spawnPart.Position.Y, center.Z) - spawnPart.Position).Unit
			)
			< 0.9
	then
		fail("ArrivalSpawn does not face the island center")
	end

	-- forbidden instances + collision rules ------------------------------------
	local walk = model:FindFirstChild("Walkable")
	local partCount = 0
	local tagged = 0
	for _, d in model:GetDescendants() do
		if
			d:IsA("Script")
			or d:IsA("LocalScript")
			or d:IsA("ModuleScript")
			or d:IsA("ProximityPrompt")
			or d:IsA("Seat")
			or d:IsA("VehicleSeat")
		then
			fail("forbidden instance: " .. d:GetFullName())
		end
		for _, tag in { TAG_SPIN, TAG_BOB, TAG_PULSE, TAG_FLICKER, TAG_SWAY } do
			if CollectionService:HasTag(d, tag) then
				tagged += 1
			end
		end
		if d:IsA("BasePart") then
			partCount += 1
			local p = d :: BasePart
			if not p.Anchored then
				fail("unanchored part: " .. p:GetFullName())
			end
			if walk and p:IsDescendantOf(walk) then
				if not p.CanCollide then
					fail("walkable part without collision: " .. p:GetFullName())
				end
			elseif p.Parent ~= model and p.CanCollide then
				fail("decoration with collision: " .. p:GetFullName())
			end
		end
	end
	if walk == nil then
		fail("missing Walkable folder")
	end
	if partCount > PART_LIMIT then
		fail(string.format("part count %d above limit %d", partCount, PART_LIMIT))
	end
	if tagged >= 150 then
		fail(string.format("too many animated items (%d)", tagged))
	end

	-- raycast helpers (only collidable parts of this model) ---------------------
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { model }
	params.RespectCanCollide = true
	local function groundY(x: number, z: number): (number?, Instance?)
		local res = Workspace:Raycast(center + v3(x, 20, z), v3(0, -40, 0), params)
		if res then
			return res.Position.Y - center.Y, res.Instance
		end
		return nil, nil
	end

	-- spawn on solid ground (spawn itself is non-collidable, so ignored)
	if spawnPart then
		local res = Workspace:Raycast(spawnPart.Position, v3(0, -6, 0), params)
		if res == nil then
			fail("ArrivalSpawn has no solid ground below")
		elseif (spawnPart.Position.Y - spawnPart.Size.Y / 2) - res.Position.Y > 1.5 then
			fail("ArrivalSpawn floats above the ground")
		end
	end

	-- walking routes ----------------------------------------------------------
	local function local2(p: BasePart?): Vector3
		if p == nil then
			return v3(0, 0, 0)
		end
		return p.Position - center
	end
	local fSpot = local2(parts.FocusSpot)
	local iSpot = local2(parts.InstinctSpot)
	local sp = SPAWN_POS
	local routes: { [string]: { Vector3 } } = {
		["spawn->portal"] = { sp, v3(0, 0, -27), v3(0, 0, -31), v3(0, 0, -34) },
		["spawn->focus deck"] = {
			sp,
			v3(0, 0, -8),
			v3(0, 0, BRIDGE_Z0),
			v3(0, 0, 2),
			v3(0, 0, BRIDGE_Z1),
			v3(0, 0, 13),
			v3(-4.2, 0, 18.6),
			v3(-11.1, 0, 20.1),
			v3(-17.9, 0, 20.1),
			v3(-25.0, 0, 19.6),
			v3(-28.3, 0, 18.5),
			v3(fSpot.X, 0, fSpot.Z),
		},
		["spawn->instinct deck"] = {
			sp,
			v3(8, 0, -21),
			v3(14, 0, -20),
			v3(30, 0, -17),
			v3(iSpot.X, 0, iSpot.Z),
		},
	}
	for routeName, pts in routes do
		local prevY: number? = nil
		local prevP: Vector3? = nil
		local ok = true
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local dist = (v3(b.X, 0, b.Z) - v3(a.X, 0, a.Z)).Magnitude
			local n = math.max(1, math.ceil(dist / 0.8))
			for k = 0, n do
				local q = a:Lerp(b, k / n)
				local y = groundY(q.X, q.Z)
				if y == nil then
					fail(string.format("%s: no ground at (%.1f, %.1f)", routeName, q.X, q.Z))
					ok = false
					break
				end
				local here = v3(q.X, y, q.Z)
				if prevY and prevP then
					if math.abs(y - prevY) > 3 then
						fail(
							string.format(
								"%s: step of %.2f studs at (%.1f, %.1f)",
								routeName,
								y - prevY,
								q.X,
								q.Z
							)
						)
						ok = false
						break
					end
					for _, h in { 1.0, 2.2, 3.6 } do
						local from = center + prevP + v3(0, h, 0)
						local to = center + here + v3(0, h, 0)
						local dir = to - from
						if dir.Magnitude > 1e-3 then
							local hit = Workspace:Raycast(from, dir, params)
							if hit then
								fail(
									string.format(
										"%s: blocked by %s at (%.1f, %.1f)",
										routeName,
										hit.Instance:GetFullName(),
										q.X,
										q.Z
									)
								)
								ok = false
								break
							end
						end
					end
					if not ok then
						break
					end
				end
				prevY, prevP = y, here
			end
			if not ok then
				break
			end
		end
	end

	-- spots stand on their decks ------------------------------------------------
	for _, name in { "FocusSpot", "InstinctSpot" } do
		local p = parts[name]
		if p then
			local res = Workspace:Raycast(p.Position, v3(0, -4, 0), params)
			if res == nil or not string.find(res.Instance.Name, "Deck") then
				fail(name .. " is not above its deck")
			elseif (p.Position.Y - p.Size.Y / 2) - res.Position.Y > 0.6 then
				fail(name .. " floats above its deck")
			end
		end
	end

	-- bridge is walkable
	local deckY = groundY(0, (BRIDGE_Z0 + BRIDGE_Z1) / 2)
	if deckY == nil or deckY < BRIDGE_RISE - 0.5 then
		fail("bridge deck not found / not collidable at its middle")
	end

	-- water above the ground below it -------------------------------------------
	for _, pondName in { "FocusPond", "InstinctPond" } do
		local pond = model:FindFirstChild(pondName)
		local water = if pond then pond:FindFirstChild("Water") else nil
		if water and water:IsA("BasePart") then
			local w = water :: BasePart
			local top = w.Position.Y + worldHalfY(w)
			local bottom = w.Position.Y - worldHalfY(w)
			for _, off in { v3(0, 0, 0), v3(5, 0, 3), v3(-6, 0, -2), v3(2, 0, -7) } do
				local res =
					Workspace:Raycast(w.Position + off + v3(0, 10, 0), v3(0, -20, 0), params)
				if res and top <= res.Position.Y then
					fail(pondName .. " water top is below the ground (water invisible)")
					break
				elseif res and res.Position.Y > bottom + 0.01 then
					fail(
						string.format(
							"%s water partly hidden: ground %.2f vs water bottom %.2f",
							pondName,
							res.Position.Y,
							bottom
						)
					)
					break
				end
			end
		else
			fail(pondName .. " has no Water part")
		end
	end

	if #failures == 0 then
		print(
			string.format(
				"[TrainingIsland4Builder] selfTest OK (%d parts, %d animated)",
				partCount,
				tagged
			)
		)
	end
	return failures
end

-- ----------------------------------------------------------------------------
-- Optional reference lighting (screenshots only; never called by build)
-- ----------------------------------------------------------------------------
local savedLighting: { [string]: any }? = nil
local LIGHT_PROPS = {
	"ClockTime",
	"Brightness",
	"Ambient",
	"OutdoorAmbient",
	"ColorShift_Top",
	"ColorShift_Bottom",
	"FogColor",
	"FogStart",
	"FogEnd",
	"ExposureCompensation",
	"EnvironmentDiffuseScale",
	"EnvironmentSpecularScale",
}

function Builder.applyReferenceLighting()
	if savedLighting == nil then
		local saved: { [string]: any } = {}
		for _, prop in LIGHT_PROPS do
			saved[prop] = (Lighting :: any)[prop]
		end
		savedLighting = saved
	end
	Lighting.ClockTime = 16.9
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(176, 160, 196)
	Lighting.OutdoorAmbient = Color3.fromRGB(214, 196, 226)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 226, 200)
	Lighting.ColorShift_Bottom = Color3.fromRGB(220, 200, 255)
	Lighting.FogColor = Color3.fromRGB(250, 220, 236)
	Lighting.FogStart = 350
	Lighting.FogEnd = 1400
	Lighting.ExposureCompensation = 0.05
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	local cc = Lighting:FindFirstChild("CelestialRefColor")
	if cc == nil then
		local e = Instance.new("ColorCorrectionEffect")
		e.Name = "CelestialRefColor"
		e.Saturation = 0.12
		e.Contrast = 0.05
		e.TintColor = Color3.fromRGB(255, 244, 250)
		e.Parent = Lighting
	end
	local bloom = Lighting:FindFirstChild("CelestialRefBloom")
	if bloom == nil then
		local b = Instance.new("BloomEffect")
		b.Name = "CelestialRefBloom"
		b.Intensity = 0.6
		b.Size = 28
		b.Threshold = 1.6
		b.Parent = Lighting
	end
end

function Builder.restoreLighting()
	local saved = savedLighting
	if saved then
		for prop, value in saved do
			(Lighting :: any)[prop] = value
		end
		savedLighting = nil
	end
	for _, name in { "CelestialRefColor", "CelestialRefBloom" } do
		local e = Lighting:FindFirstChild(name)
		if e then
			e:Destroy()
		end
	end
end

return Builder
