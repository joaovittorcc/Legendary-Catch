--[[
	Island generator v3 (Edit-time only).

	Builds the hub island from the approved reference (art/reference/island-approved.png):
	training lagoon on the left, upgrade workshop on a raised terrace at the back, paved plaza
	in the middle, stone stairs at the front and the fishing pier on the right.

	Axes: +X = pier side, -X = lagoon side, -Z = workshop (back), +Z = stairs (front).
	Sea level is y = 0. Plaza top is y = PLAZA_Y.

	Run from the MCP (`execute_luau` in Edit) by requiring a clone of this module. It wipes
	Terrain and rebuilds Workspace.Island, so the place must be dedicated to this map.
	AI meshes live in ServerStorage.MapMeshes and replace part fallbacks (see `placeMesh`).
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Terrain = Workspace.Terrain
local rng = Random.new(1117)

local PLAZA_Y = 10.3
local TERRACE_Y = 14.3
local PIER_Y = 10.1
local OCEAN_SIZE = 2048
local OCEAN_DEPTH = 14

local COLORS = {
	rock = Color3.fromRGB(112, 118, 148),
	rockDark = Color3.fromRGB(78, 84, 116),
	grass = Color3.fromRGB(74, 164, 92),
	sand = Color3.fromRGB(232, 214, 172),
	seabed = Color3.fromRGB(12, 40, 84),
	paving = Color3.fromRGB(178, 162, 156),
	pavingDark = Color3.fromRGB(142, 130, 134),
	wood = Color3.fromRGB(148, 90, 52),
	woodLight = Color3.fromRGB(184, 126, 76),
	woodDark = Color3.fromRGB(88, 52, 36),
	rope = Color3.fromRGB(196, 158, 108),
	bronze = Color3.fromRGB(176, 132, 68),
	gold = Color3.fromRGB(255, 200, 96),
	amber = Color3.fromRGB(255, 174, 68),
	cyan = Color3.fromRGB(74, 228, 255),
	crystal = Color3.fromRGB(108, 204, 255),
	lilac = Color3.fromRGB(198, 140, 255),
	pink = Color3.fromRGB(246, 142, 214),
	roof = Color3.fromRGB(36, 92, 182),
	banner = Color3.fromRGB(36, 84, 172),
	cream = Color3.fromRGB(248, 238, 214),
	red = Color3.fromRGB(224, 58, 54),
	white = Color3.fromRGB(245, 245, 245),
}

local root: Model
local groups: { [string]: Model } = {}

-- Helpers -----------------------------------------------------------------------------

local function group(name: string): Model
	local existing = groups[name]
	if existing then
		return existing
	end
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = root
	groups[name] = m
	return m
end

type PartOpts = {
	shape: Enum.PartType?,
	wedge: boolean?,
	collide: boolean?,
	shadow: boolean?,
	transparency: number?,
	reflectance: number?,
}

local function part(
	name: string,
	parent: Instance,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	opts: PartOpts?
): BasePart
	local o: PartOpts = opts or {}
	local p: BasePart
	if o.wedge then
		p = Instance.new("WedgePart")
	else
		local np = Instance.new("Part")
		if o.shape then
			np.Shape = o.shape
		end
		p = np
	end
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.CanCollide = o.collide ~= false
	p.CanTouch = false
	p.CanQuery = o.collide ~= false
	p.CastShadow = o.shadow ~= false
	p.Transparency = o.transparency or 0
	p.Reflectance = o.reflectance or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function deco(name, parent, size, cf, color, material, opts: PartOpts?)
	local o: PartOpts = opts or {}
	o.collide = false
	return part(name, parent, size, cf, color, material, o)
end

local function beam(
	name,
	parent,
	a: Vector3,
	b: Vector3,
	thick: number,
	color,
	material,
	opts: PartOpts?
)
	local len = (b - a).Magnitude
	if len < 0.01 then
		return nil
	end
	return part(
		name,
		parent,
		Vector3.new(thick, thick, len),
		CFrame.lookAt((a + b) / 2, b),
		color,
		material,
		opts
	)
end

local function cylinderPost(
	name: string,
	parent: Instance,
	base: Vector3,
	height: number,
	radius: number,
	color: Color3,
	material: Enum.Material,
	opts: PartOpts?
)
	local o: PartOpts = opts or {}
	o.shape = Enum.PartType.Cylinder
	return part(
		name,
		parent,
		Vector3.new(height, radius * 2, radius * 2),
		CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material,
		o
	)
end

local function pointLight(parent: Instance, color: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = parent
end

local function disc(
	name,
	parent,
	center: Vector3,
	radius: number,
	thick: number,
	color,
	material,
	opts: PartOpts?
)
	local o: PartOpts = opts or {}
	o.shape = Enum.PartType.Cylinder
	return part(
		name,
		parent,
		Vector3.new(thick, radius * 2, radius * 2),
		CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material,
		o
	)
end

-- Smooth concentric cylinder ring (zero segment overlap / zero Z-fighting).
local function flushRing(
	parent: Instance,
	name: string,
	center: Vector3,
	outerR: number,
	innerR: number,
	ringColor: Color3,
	fillColor: Color3,
	fillMaterial: Enum.Material,
	ringTopOffset: number
)
	local thick = 0.08
	disc(
		name,
		parent,
		center + Vector3.new(0, ringTopOffset - thick / 2, 0),
		outerR,
		thick,
		ringColor,
		Enum.Material.Neon,
		{ collide = false, shadow = false }
	)
	disc(
		name .. "Fill",
		parent,
		center + Vector3.new(0, ringTopOffset + 0.015 - thick / 2, 0),
		innerR,
		thick,
		fillColor,
		fillMaterial,
		{ collide = false, shadow = false }
	)
end

-- Hanging catenary rope between `a` and `b` in small non-overlapping segments.
local function ropeSpan(parent: Instance, a: Vector3, b: Vector3, sag: number, thick: number)
	local steps = 2
	local prev = a
	for i = 1, steps do
		local t = i / steps
		local nextPt = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * sag, 0)
		beam(
			"Rope",
			parent,
			prev,
			nextPt,
			thick,
			COLORS.rope,
			Enum.Material.Fabric,
			{ collide = false, shadow = false }
		)
		prev = nextPt
	end
end

type MeshOpts = {
	scale: number?,
	collide: boolean?,
	shadow: boolean?,
	anchorMode: ("bottom" | "top" | "center")?,
}

local function placeMesh(
	name: string,
	parent: Instance,
	cf: CFrame,
	fallback: () -> (),
	optsOrScale: (number | MeshOpts)?
): Instance?
	local opts: MeshOpts = if typeof(optsOrScale) == "table"
		then optsOrScale
		else { scale = optsOrScale }
	local lib = ServerStorage:FindFirstChild("MapMeshes")
	local template = lib and lib:FindFirstChild(name)
	if not template then
		fallback()
		return nil
	end
	local clone = template:Clone()
	if opts.scale and clone:IsA("Model") then
		clone:ScaleTo(clone:GetScale() * opts.scale)
	end
	local yaw = template:GetAttribute("YawOffset")
	local yawOffset = CFrame.Angles(0, math.rad(if typeof(yaw) == "number" then yaw else 0), 0)
	local anchorMode = opts.anchorMode or "bottom"
	local collide = opts.collide ~= false

	if clone:IsA("Model") then
		local _, size = clone:GetBoundingBox()
		local shiftY = if anchorMode == "bottom"
			then size.Y / 2
			elseif anchorMode == "top" then -size.Y / 2
			else 0
		clone:PivotTo(cf * yawOffset * CFrame.new(0, shiftY, 0))
	elseif clone:IsA("BasePart") then
		local shiftY = if anchorMode == "bottom"
			then clone.Size.Y / 2
			elseif anchorMode == "top" then -clone.Size.Y / 2
			else 0
		clone.CFrame = cf * yawOffset * CFrame.new(0, shiftY, 0)
	end

	local shadow = if opts.shadow ~= nil then opts.shadow else collide

	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = collide
			d.CanQuery = collide
			d.CanTouch = false
			d.CastShadow = shadow
		end
	end
	if clone:IsA("BasePart") then
		clone.Anchored = true
		clone.CanCollide = collide
		clone.CanQuery = collide
		clone.CanTouch = false
		clone.CastShadow = shadow
	end
	clone.Parent = parent
	return clone
end

local function hangingLantern(
	parent: Instance,
	hookPos: Vector3,
	scale: number,
	withLight: boolean,
	yawDeg: number?
)
	local cf = CFrame.new(hookPos) * CFrame.Angles(0, math.rad(yawDeg or 0), 0)
	placeMesh("HangingLantern", parent, cf, function()
		deco(
			"LanternCord",
			parent,
			Vector3.new(0.1, 0.7, 0.1),
			CFrame.new(hookPos - Vector3.new(0, 0.35, 0)),
			COLORS.woodDark,
			Enum.Material.Wood,
			{ shadow = false }
		)
		deco(
			"LanternBody",
			parent,
			Vector3.new(0.9 * scale, 1.2 * scale, 0.9 * scale),
			CFrame.new(hookPos - Vector3.new(0, 1.1 * scale, 0)),
			COLORS.amber,
			Enum.Material.Neon,
			{ shadow = false }
		)
	end, { scale = scale, collide = false, anchorMode = "top" })

	if withLight then
		local emitter = deco(
			"LanternLight",
			parent,
			Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(hookPos - Vector3.new(0, 1.2 * scale, 0)),
			COLORS.amber,
			Enum.Material.Neon,
			{ transparency = 1, shadow = false }
		)
		pointLight(emitter, COLORS.amber, 1.5, 16)
	end
end

-- Terrain -----------------------------------------------------------------------------

local function buildOcean()
	Terrain:Clear()
	Terrain.Decoration = false
	Terrain.WaterColor = Color3.fromRGB(10, 96, 168)
	Terrain.WaterTransparency = 0.52
	Terrain.WaterReflectance = 0.55
	Terrain.WaterWaveSize = 0.14
	Terrain.WaterWaveSpeed = 9
	Terrain:SetMaterialColor(Enum.Material.Rock, COLORS.rock)
	Terrain:SetMaterialColor(Enum.Material.Grass, COLORS.grass)
	Terrain:SetMaterialColor(Enum.Material.Sand, COLORS.sand)
	Terrain:SetMaterialColor(Enum.Material.Slate, COLORS.seabed)
	Terrain:SetMaterialColor(Enum.Material.Basalt, COLORS.rockDark)

	local tile = 512
	local half = OCEAN_SIZE / 2
	for x = -half + tile / 2, half - tile / 2, tile do
		for z = -half + tile / 2, half - tile / 2, tile do
			Terrain:FillBlock(
				CFrame.new(x, -OCEAN_DEPTH / 2, z),
				Vector3.new(tile, OCEAN_DEPTH, tile),
				Enum.Material.Water
			)
			Terrain:FillBlock(
				CFrame.new(x, -OCEAN_DEPTH - 2, z),
				Vector3.new(tile, 4, tile),
				Enum.Material.Slate
			)
			task.wait()
		end
	end

	-- Shallow sand shelf around the island so coastal water glows turquoise.
	local up = CFrame.new(-16, 0, -2)
	Terrain:FillCylinder(up * CFrame.new(0, -12, 0), 4, 155, Enum.Material.Sand)
	Terrain:FillCylinder(up * CFrame.new(0, -9, 0), 4, 120, Enum.Material.Sand)
	Terrain:FillCylinder(up * CFrame.new(0, -6.5, 0), 4, 92, Enum.Material.Sand)
end

local ISLAND_CORE = {
	{ -24, -8, 40 },
	{ -50, -2, 26 },
	{ 0, 2, 24 },
	{ -22, 22, 22 },
	{ -10, -36, 26 },
	{ 6, 22, 16 },
}

local function nearStairs(x: number, z: number): boolean
	return x > -17 and x < 5 and z > 22
end

local function nearPier(x: number, z: number): boolean
	return x > 12 and z > -2 and z < 18
end

local function buildIsland()
	for _, c in ISLAND_CORE do
		Terrain:FillCylinder(CFrame.new(c[1], -10, c[2]), 20, c[3], Enum.Material.Rock)
	end
	for _, c in ISLAND_CORE do
		Terrain:FillCylinder(CFrame.new(c[1], 3, c[2]), 6, c[3] - 3, Enum.Material.Grass)
	end
	task.wait()

	-- Boulder rim along the shore.
	local cx, cz, rx, rz = -22, -6, 50, 47
	for i = 1, 64 do
		local a = (i - 1) / 64 * math.pi * 2
		local x = cx + math.cos(a) * rx + rng:NextNumber(-3, 3)
		local z = cz + math.sin(a) * rz + rng:NextNumber(-3, 3)
		if not nearStairs(x, z) and not nearPier(x, z) then
			local r = rng:NextNumber(6, 9)
			Terrain:FillBall(Vector3.new(x, rng:NextNumber(-3, 0), z), r, Enum.Material.Rock)
			if i % 3 == 0 then
				Terrain:FillBall(Vector3.new(x * 1.02, -2, z * 1.02), r * 0.8, Enum.Material.Basalt)
			end
		end
	end
	task.wait()

	-- Workshop terrace and rocky hill behind it.
	Terrain:FillBlock(CFrame.new(-6, 4, -37), Vector3.new(46, 16, 30), Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-6, 14, -57), 18, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-30, 11, -54), 13, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(18, 10, -50), 11, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-6, 24, -60), 10, Enum.Material.Grass)
	Terrain:FillBall(Vector3.new(-28, 19, -56), 6, Enum.Material.Grass)

	-- Waterfall cliff behind the lagoon.
	Terrain:FillBall(Vector3.new(-50, 12, -18), 10, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-40, 10, -21), 8, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-58, 10, -16), 7, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-52, 20, -20), 6, Enum.Material.Grass)
	task.wait()

	-- Lagoon basin: carve, sand floor, then water.
	local lagoon = CFrame.new(-44, 0, 2)
	Terrain:FillCylinder(lagoon * CFrame.new(0, 6, 0), 8, 16, Enum.Material.Air)
	Terrain:FillCylinder(lagoon * CFrame.new(0, 0, 0), 4, 17, Enum.Material.Sand)
	Terrain:FillCylinder(lagoon * CFrame.new(0, 4, 0), 4, 15, Enum.Material.Water)

	-- Cut for the front stairs.
	Terrain:FillBlock(CFrame.new(-6, 7, 39), Vector3.new(16, 16, 26), Enum.Material.Air)
	Terrain:FillBlock(CFrame.new(-6, -6, 39), Vector3.new(16, 10, 26), Enum.Material.Water)
end

-- Plaza, paths, spawn ----------------------------------------------------------------

local function buildPlaza()
	local g = group("CentralPlaza")
	local PATH_Y = PLAZA_Y - 0.05 -- 0.05 stud step below PlazaPaving eliminates all Z-fighting

	local function pathSlab(name: string, size: Vector3, pos: Vector3)
		part(
			name,
			g,
			size,
			CFrame.new(pos - Vector3.new(0, size.Y / 2, 0)),
			COLORS.paving,
			Enum.Material.Cobblestone
		)
	end

	disc(
		"PlazaPaving",
		g,
		Vector3.new(-6, PLAZA_Y - 0.5, 4),
		23,
		1,
		COLORS.paving,
		Enum.Material.Cobblestone
	)
	-- Paths stop cleanly at pier/stairs/terrace edges and sit 0.05 below PlazaPaving.
	pathSlab("PathToPier", Vector3.new(20, 1, 14), Vector3.new(8, PATH_Y, 8))
	pathSlab("PathToLagoon", Vector3.new(14, 1, 14), Vector3.new(-28, PATH_Y, 2))
	pathSlab("PathToStairs", Vector3.new(16, 1, 10), Vector3.new(-6, PATH_Y, 22))
	pathSlab("PathToWorkshop", Vector3.new(18, 1, 10), Vector3.new(-6, PATH_Y, -16))

	-- Clean magic compass rune inlaid flush into the paving (concentric cylinders, zero Z-fighting).
	local glyph = Vector3.new(-2, PLAZA_Y, -4)
	flushRing(
		g,
		"GlyphOuterGold",
		glyph,
		6.2,
		5.95,
		COLORS.gold,
		COLORS.paving,
		Enum.Material.Cobblestone,
		0.03
	)
	flushRing(
		g,
		"GlyphInnerCyan",
		glyph,
		4.0,
		3.7,
		COLORS.cyan,
		COLORS.paving,
		Enum.Material.Cobblestone,
		0.06
	)

	for i = 0, 1 do
		local a = i * math.pi / 2 + math.pi / 4
		deco(
			"GlyphRay",
			g,
			Vector3.new(0.28, 0.08, 7.2),
			CFrame.new(glyph + Vector3.new(0, 0.045 + i * 0.008, 0)) * CFrame.Angles(0, a, 0),
			COLORS.cyan,
			Enum.Material.Neon,
			{ shadow = false }
		)
	end
	deco(
		"GlyphCoreOuter",
		g,
		Vector3.new(2.2, 0.08, 2.2),
		CFrame.new(glyph + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, math.rad(45), 0),
		COLORS.gold,
		Enum.Material.Neon,
		{ shadow = false }
	)
	deco(
		"GlyphCoreInner",
		g,
		Vector3.new(1.5, 0.08, 1.5),
		CFrame.new(glyph + Vector3.new(0, 0.075, 0)) * CFrame.Angles(0, math.rad(45), 0),
		COLORS.cyan,
		Enum.Material.Neon,
		{ shadow = false }
	)

	-- Golden guide inlays from outside the glyph ring to each area (flat top above both surfaces).
	for _, target in
		{
			Vector3.new(-6, PLAZA_Y, -12.5), -- workshop steps
			Vector3.new(16.5, PLAZA_Y, 8), -- pier arch
			Vector3.new(-27, PLAZA_Y, 2), -- lagoon
			Vector3.new(-6, PLAZA_Y, 25.5), -- front stairs
		}
	do
		local from = glyph + (target - glyph).Unit * 6.3
		local len = (target - from).Magnitude
		local mid = (from + target) / 2
		deco(
			"GoldInlay",
			g,
			Vector3.new(0.18, 0.1, len),
			CFrame.lookAt(
				Vector3.new(mid.X, PLAZA_Y - 0.01, mid.Z),
				Vector3.new(target.X, PLAZA_Y - 0.01, target.Z)
			),
			COLORS.gold,
			Enum.Material.Neon,
			{ shadow = false }
		)
	end

	-- Spawn on flat paving between stairs and plaza, facing the workshop.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = CFrame.new(-6, PLAZA_Y + 0.1, 16)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanTouch = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = g

	-- Trophy pedestal on the front-right of the plaza (opposite the campfire), ~4 studs tall.
	local tp = Vector3.new(6.5, PLAZA_Y, 18.5)
	local plinth = Instance.new("Model")
	plinth.Name = "TrophyPlinth"
	plinth.Parent = g
	disc(
		"PlinthStep1",
		plinth,
		tp + Vector3.new(0, 0.3, 0),
		3.3,
		0.6,
		COLORS.pavingDark,
		Enum.Material.Cobblestone
	)
	disc(
		"PlinthStep2",
		plinth,
		tp + Vector3.new(0, 0.95, 0),
		2.6,
		0.7,
		COLORS.paving,
		Enum.Material.Cobblestone
	)
	disc(
		"PlinthColumn",
		plinth,
		tp + Vector3.new(0, 2.3, 0),
		1.55,
		2.0,
		COLORS.cream,
		Enum.Material.Marble
	)
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		local ribPos = tp + Vector3.new(math.cos(a) * 1.55, 2.3, math.sin(a) * 1.55)
		deco(
			"PlinthCrystalRib",
			plinth,
			Vector3.new(0.42, 1.8, 0.42),
			CFrame.new(ribPos) * CFrame.Angles(0, -a, 0),
			COLORS.crystal,
			Enum.Material.Glass,
			{ transparency = 0.15, shadow = false }
		)
	end
	disc(
		"PlinthCap",
		plinth,
		tp + Vector3.new(0, 3.55, 0),
		2.15,
		0.5,
		COLORS.paving,
		Enum.Material.Cobblestone
	)
	flushRing(
		plinth,
		"PlinthGoldRim",
		tp + Vector3.new(0, 3.8, 0),
		2.25,
		1.8,
		COLORS.gold,
		COLORS.pavingDark,
		Enum.Material.Slate,
		0.04
	)
	disc(
		"PlinthCoreGlow",
		plinth,
		tp + Vector3.new(0, 3.86, 0),
		1.35,
		0.08,
		COLORS.cyan,
		Enum.Material.Neon,
		{ collide = false, shadow = false }
	)

	local trophyPos = tp + Vector3.new(0, 4.2, 0)
	local trophyTop = part(
		"TrophyPedestal",
		g,
		Vector3.new(2.4, 0.4, 2.4),
		CFrame.lookAt(trophyPos, Vector3.new(-6, trophyPos.Y, 14)) * CFrame.Angles(0, math.pi, 0),
		COLORS.gold,
		Enum.Material.ForceField,
		{ collide = false, transparency = 1, shadow = false }
	)
	trophyTop.CanQuery = false
	CollectionService:AddTag(trophyTop, "TrophyPedestal")
end

local function buildCampfire()
	local g = group("Campfire")
	local c = Vector3.new(-18, PLAZA_Y, 9)
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		part(
			"FireStone",
			g,
			Vector3.new(1.5, 0.9, 1.3),
			CFrame.new(c + Vector3.new(math.cos(a) * 2.5, 0.35, math.sin(a) * 2.5))
				* CFrame.Angles(0, -a, 0),
			COLORS.rockDark,
			Enum.Material.Slate
		)
	end
	local ember = deco(
		"Embers",
		g,
		Vector3.new(0.3, 3.0, 3.0),
		CFrame.new(c + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		COLORS.amber,
		Enum.Material.Neon,
		{ shape = Enum.PartType.Cylinder, shadow = false }
	)
	pointLight(ember, COLORS.amber, 2.2, 20)

	for i = 0, 2 do
		local a = i * math.pi / 3
		beam(
			"Log",
			g,
			c + Vector3.new(math.cos(a) * 1.5, 0.35 + i * 0.04, math.sin(a) * 1.5),
			c + Vector3.new(-math.cos(a) * 1.5, 0.75 + i * 0.04, -math.sin(a) * 1.5),
			0.55,
			COLORS.woodDark,
			Enum.Material.Wood,
			{ collide = false }
		)
	end
	local fire = Instance.new("Fire")
	fire.Size = 4.2
	fire.Heat = 7
	fire.Color = Color3.fromRGB(255, 175, 65)
	fire.SecondaryColor = Color3.fromRGB(255, 85, 30)
	fire.Parent = ember

	-- Three timber benches around the fire.
	for _, a in { 200, 270, 340 } do
		local r = math.rad(a)
		local pos = c + Vector3.new(math.cos(r) * 6, 0, math.sin(r) * 6)
		local cf = CFrame.lookAt(pos, c) * CFrame.Angles(0, math.rad(90), 0)
		part(
			"BenchSeat",
			g,
			Vector3.new(5.8, 0.65, 1.7),
			cf * CFrame.new(0, 1.55, 0),
			COLORS.woodLight,
			Enum.Material.WoodPlanks
		)
		for _, dx in { -2.1, 2.1 } do
			part(
				"BenchLeg",
				g,
				Vector3.new(0.75, 1.25, 1.35),
				cf * CFrame.new(dx, 0.625, 0),
				COLORS.woodDark,
				Enum.Material.Wood
			)
		end
	end
end

-- Lanterns, signs ----------------------------------------------------------------------

local function lantern(parent: Instance, base: Vector3, height: number, withLight: boolean?)
	local g = Instance.new("Model")
	g.Name = "Lantern"
	local lib = ServerStorage:FindFirstChild("MapMeshes")
	if lib and lib:FindFirstChild("LanternPost") then
		g.Parent = parent
		part(
			"PostCollider",
			g,
			Vector3.new(0.8, height, 0.8),
			CFrame.new(base + Vector3.new(0, height / 2, 0)),
			COLORS.woodDark,
			Enum.Material.Wood,
			{ transparency = 1, shadow = false }
		)
		placeMesh(
			"LanternPost",
			g,
			CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
			function() end,
			{ scale = height / 4.5, collide = false }
		)
		if withLight ~= false then
			local glow = deco(
				"LightSource",
				g,
				Vector3.new(0.2, 0.2, 0.2),
				CFrame.new(base + Vector3.new(0, height * 0.72, 0)),
				COLORS.amber,
				Enum.Material.Neon,
				{ transparency = 1, shadow = false }
			)
			pointLight(glow, COLORS.amber, 1.3, 15)
		end
		return g
	end
	cylinderPost("Post", g, base, height, 0.35, COLORS.woodDark, Enum.Material.Wood)
	hangingLantern(g, base + Vector3.new(0, height - 0.2, 1.1), 0.75, withLight ~= false, 0)
	g.Parent = parent
	return g
end

local function stonePedestalLantern(parent: Instance, base: Vector3, withLight: boolean)
	local g = Instance.new("Model")
	g.Name = "StoneLanternPedestal"
	g.Parent = parent
	part(
		"Pedestal",
		g,
		Vector3.new(2.2, 1.2, 2.2),
		CFrame.new(base + Vector3.new(0, 0.6, 0)),
		COLORS.pavingDark,
		Enum.Material.Cobblestone
	)
	local lanternBase = base + Vector3.new(0, 1.2, 0)
	placeMesh("StoneLantern", g, CFrame.new(lanternBase), function()
		part(
			"LanternPost",
			g,
			Vector3.new(1.2, 2.2, 1.2),
			CFrame.new(lanternBase + Vector3.new(0, 1.1, 0)),
			COLORS.amber,
			Enum.Material.Neon
		)
	end, { scale = 1.0, collide = true })
	if withLight then
		local glow = deco(
			"LightSource",
			g,
			Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(lanternBase + Vector3.new(0, 2.0, 0)),
			COLORS.amber,
			Enum.Material.Neon,
			{ transparency = 1, shadow = false }
		)
		pointLight(glow, COLORS.amber, 1.4, 15)
	end
end

local function sign(
	parent: Instance,
	text: string,
	cf: CFrame,
	width: number,
	height: number,
	withFishCrest: boolean?
)
	local g = Instance.new("Model")
	g.Name = "Sign_" .. text:gsub("%W", "")
	part(
		"Frame",
		g,
		Vector3.new(width + 0.8, height + 0.8, 0.45),
		cf,
		COLORS.woodDark,
		Enum.Material.Wood
	)
	local board =
		part("Board", g, Vector3.new(width, height, 0.6), cf, COLORS.wood, Enum.Material.WoodPlanks)

	-- Optional curved wood crest + fish emblem above the board, matching the reference signs.
	if withFishCrest then
		part(
			"ArchedCap",
			g,
			Vector3.new(width * 0.72, 1.1, 0.55),
			cf * CFrame.new(0, height / 2 + 0.55, 0),
			COLORS.woodDark,
			Enum.Material.Wood
		)
		deco(
			"FishEmblemBody",
			g,
			Vector3.new(1.6, 0.75, 0.16),
			cf * CFrame.new(0, height / 2 + 0.65, 0.34),
			COLORS.cream,
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Ball, shadow = false }
		)
		deco(
			"FishEmblemTail",
			g,
			Vector3.new(0.14, 0.6, 0.65),
			cf
				* CFrame.new(-0.9, height / 2 + 0.65, 0.34)
				* CFrame.Angles(0, math.rad(90), math.rad(90)),
			COLORS.cream,
			Enum.Material.SmoothPlastic,
			{ wedge = true, shadow = false }
		)
	end

	for _, side in { Enum.NormalId.Back, Enum.NormalId.Front } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = side
		gui.CanvasSize = Vector2.new(width * 50, height * 50)
		gui.LightInfluence = 0.4
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(0.92, 0.84)
		label.Position = UDim2.fromScale(0.04, 0.08)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = COLORS.cream
		label.TextStrokeColor3 = COLORS.woodDark
		label.TextStrokeTransparency = 0.2
		label.Parent = gui
		gui.Parent = board
	end
	g.Parent = parent
	return g
end

-- Stairs -------------------------------------------------------------------------------

local function buildStairs()
	local g = group("FrontStairs")
	local steps = 11
	for i = 1, steps do
		local top = PLAZA_Y - i * 0.8
		local z = 27 + (i - 1) * 2
		local h = top + 4
		part(
			"Step",
			g,
			Vector3.new(14, h, 2.2),
			CFrame.new(-6, top - h / 2, z),
			COLORS.paving,
			Enum.Material.Cobblestone
		)
	end
	local landingY = PLAZA_Y - steps * 0.8 - 0.15 -- 0.15 below step 11 prevents Z-fighting
	part(
		"Landing",
		g,
		Vector3.new(18, 4, 6),
		CFrame.new(-6, landingY - 2, 51.1),
		COLORS.pavingDark,
		Enum.Material.Cobblestone
	)

	-- Stepped stone retaining walls along both flanks of the stairs.
	for _, x in { -13.9, 1.9 } do
		for i = 0, 4 do
			local z = 28 + i * 4.4
			local top = PLAZA_Y + 0.5 - i * 1.7
			local h = top + 4
			part(
				"StairCurb",
				g,
				Vector3.new(1.8, h, 4.6),
				CFrame.new(x, top - h / 2, z),
				COLORS.pavingDark,
				Enum.Material.Cobblestone,
				{ shadow = false }
			)
		end
	end

	-- Gentle 13-degree submerged stone ramp at the foot of the stairs so swimmers walk straight out.
	local rampH = landingY + 1.5
	part(
		"WaterExitRamp",
		g,
		Vector3.new(16, rampH, 12),
		CFrame.new(-6, landingY - rampH / 2, 60.1) * CFrame.Angles(0, math.rad(180), 0),
		COLORS.pavingDark,
		Enum.Material.Cobblestone,
		{ wedge = true, shadow = false }
	)

	-- Rocky flanks and submerged reef rocks in the shallow turquoise water.
	for _, x in { -17, 5 } do
		for i = 0, 5 do
			local z = 28 + i * 4.2
			local y = PLAZA_Y - 4 - i * 1.6
			Terrain:FillBall(Vector3.new(x, y, z), rng:NextNumber(3.6, 4.4), Enum.Material.Rock)
		end
	end
	for _, rp in
		{
			{ -18, -1.2, 56, 3.8 },
			{ 6, -1.0, 57, 3.4 },
			{ -12, -1.6, 61, 2.8 },
			{ 2, -1.5, 62, 2.6 },
		}
	do
		deco(
			"ReefRock",
			g,
			Vector3.new(rp[4], rp[4] * 0.65, rp[4]),
			CFrame.new(rp[1], rp[2], rp[3]) * CFrame.Angles(0, rp[1], 0),
			COLORS.rockDark,
			Enum.Material.Slate,
			{ shape = Enum.PartType.Ball, shadow = false }
		)
	end

	-- Four warm stone pedestal lanterns flanking the top and bottom of the stairs (top 2 lit).
	for _, x in { -14.2, 2.2 } do
		stonePedestalLantern(g, Vector3.new(x, PLAZA_Y, 25.5), true)
		stonePedestalLantern(g, Vector3.new(x, landingY, 49.5), false)
	end

	-- Cute orange starfish on the front-left shore rock, as in the reference.
	placeMesh(
		"Starfish",
		g,
		CFrame.new(-21.5, 5.2, 37.5) * CFrame.Angles(math.rad(-75), math.rad(25), math.rad(15)),
		function() end,
		{ scale = 3.2, collide = false, anchorMode = "center" }
	)
end

-- Blossom tree ------------------------------------------------------------------------

local function buildBlossomTree(parent: Instance, base: Vector3)
	local g = Instance.new("Model")
	g.Name = "BlossomTree"
	g.Parent = parent
	local trunkHeight = 17
	placeMesh("TreeTrunk", g, CFrame.new(base), function()
		beam(
			"Trunk",
			g,
			base,
			base + Vector3.new(2, trunkHeight, 0),
			2.8,
			COLORS.wood,
			Enum.Material.Wood
		)
	end, { scale = 0.62, collide = true })

	local crown = base + Vector3.new(1.5, trunkHeight + 1.5, 0)
	local clumps = {
		{ 0, 3.5, 0, 1.4 },
		{ 6.5, 1.2, 2.2, 1.2 },
		{ -6.5, 1.2, -1.2, 1.2 },
		{ 2.5, 0.2, 7.5, 1.1 },
		{ -2.5, 0.2, -7.5, 1.1 },
		{ 10, -1.8, -4, 0.95 },
		{ -9.5, -1.8, 5.5, 0.95 },
		{ 4.5, 4.2, -4.5, 1.05 },
		{ -4.5, 4.2, 4.5, 1.05 },
		{ 11.5, -2.6, 4.5, 0.85 },
		{ -10.5, -2.6, -5.5, 0.85 },
		{ 1.5, 5.5, 1.5, 1.0 },
	}
	for i, c in clumps do
		local pos = crown + Vector3.new(c[1], c[2], c[3])
		placeMesh(
			"BlossomClump",
			g,
			CFrame.new(pos - Vector3.new(0, 2.5 * c[4], 0)) * CFrame.Angles(0, i * 1.3, 0),
			function()
				deco(
					"Blossom",
					g,
					Vector3.new(8, 5.5, 8) * c[4],
					CFrame.new(pos),
					if i % 3 == 0 then COLORS.lilac else COLORS.pink,
					Enum.Material.SmoothPlastic,
					{ shape = Enum.PartType.Ball }
				)
			end,
			{ scale = c[4] * 1.5, collide = false }
		)
	end

	-- Cascading wisteria vines hanging around the blossom canopy rim.
	for i = 1, 8 do
		local a = i / 8 * math.pi * 2 + 0.3
		local r = rng:NextNumber(8, 11)
		local top = crown + Vector3.new(math.cos(a) * r, -1.8, math.sin(a) * r)
		placeMesh("WisteriaDrape", g, CFrame.new(top) * CFrame.Angles(0, a, 0), function()
			deco(
				"WisteriaFallback",
				g,
				Vector3.new(1.4, 2.8, 1.4),
				CFrame.new(top - Vector3.new(0, 1.4, 0)),
				COLORS.lilac,
				Enum.Material.SmoothPlastic,
				{ shape = Enum.PartType.Ball, shadow = false }
			)
		end, { scale = 1.6, collide = false, anchorMode = "top" })
	end

	-- Hanging glowing lanterns under the pink branches (2 carry lights for mobile budget).
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2 + 0.45
		local hook = crown + Vector3.new(math.cos(a) * 8.5, -2.2, math.sin(a) * 8.5)
		hangingLantern(g, hook, 0.9, i % 2 == 0, i * 75)
	end
end

-- Training lagoon ----------------------------------------------------------------------

local function buildLagoon()
	local g = group("TrainingLagoon")
	local c = Vector3.new(-44, 0, 2)

	-- Rounded stones on the rim.
	for i = 1, 22 do
		local a = i / 22 * math.pi * 2
		local r = 15.5
		local p = c + Vector3.new(math.cos(a) * r, 8.2, math.sin(a) * r)
		part(
			"RimStone",
			g,
			Vector3.new(rng:NextNumber(2.6, 3.6), rng:NextNumber(1.4, 2), rng:NextNumber(2.4, 3.2)),
			CFrame.new(p) * CFrame.Angles(0, -a, 0),
			COLORS.rock,
			Enum.Material.Slate,
			{ shape = Enum.PartType.Ball }
		)
	end

	-- Bright turquoise water glow sheet and bed.
	disc(
		"LagoonGlow",
		g,
		c + Vector3.new(0, 8.08, 0),
		14.8,
		0.1,
		Color3.fromRGB(56, 230, 226),
		Enum.Material.Glass,
		{ collide = false, transparency = 0.3, reflectance = 0.2, shadow = false }
	)
	disc(
		"LagoonBed",
		g,
		c + Vector3.new(0, 6, 0),
		15,
		0.2,
		Color3.fromRGB(32, 206, 218),
		Enum.Material.SmoothPlastic,
		{ collide = false, shadow = false }
	)

	-- Lily pads and glowing lotus flowers.
	for i = 1, 9 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(4, 12)
		local p = c + Vector3.new(math.cos(a) * r, 8.16, math.sin(a) * r)
		disc(
			"LilyPad",
			g,
			p,
			rng:NextNumber(1.1, 1.65),
			0.1,
			Color3.fromRGB(58, 174, 88),
			Enum.Material.Grass,
			{ collide = false, shadow = false }
		)
		if i % 2 == 0 then
			deco(
				"Lotus",
				g,
				Vector3.new(0.95, 0.7, 0.95),
				CFrame.new(p + Vector3.new(0, 0.35, 0)),
				COLORS.pink,
				Enum.Material.Neon,
				{ shape = Enum.PartType.Ball, shadow = false }
			)
		end
	end

	-- Fish silhouettes swimming in the shallows (body + tail fin).
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2 + 0.4
		local p = c + Vector3.new(math.cos(a) * 7.5, 7.85, math.sin(a) * 5.5)
		local cf = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
		deco(
			"FishShadowBody",
			g,
			Vector3.new(0.85, 0.28, 2.2),
			cf,
			Color3.fromRGB(12, 58, 96),
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Ball, shadow = false }
		)
		deco(
			"FishShadowTail",
			g,
			Vector3.new(0.18, 0.85, 0.85),
			cf * CFrame.new(0, 0, 1.15) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(12, 58, 96),
			Enum.Material.SmoothPlastic,
			{ wedge = true, shadow = false }
		)
	end

	-- Wooden fence with natural rope on the plaza-south rim (keeps TrainingSpot entrance wide open!).
	local fenceAngles = { 4, 26, 48 }
	local prev: Vector3? = nil
	for _, deg in fenceAngles do
		local a = math.rad(deg)
		local base = c + Vector3.new(math.cos(a) * 18.2, PLAZA_Y - 0.3, math.sin(a) * 18.2)
		cylinderPost(
			"FencePost",
			g,
			base,
			3.6,
			0.42,
			COLORS.wood,
			Enum.Material.Wood,
			{ shadow = false }
		)
		deco(
			"FenceCap",
			g,
			Vector3.new(0.3, 1.0, 1.0),
			CFrame.new(base + Vector3.new(0, 3.7, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			COLORS.bronze,
			Enum.Material.Metal,
			{ shape = Enum.PartType.Cylinder, shadow = false }
		)
		if prev then
			ropeSpan(g, prev + Vector3.new(0, 3.1, 0), base + Vector3.new(0, 3.1, 0), 0.55, 0.18)
		end
		prev = base
	end

	-- Lush continuous curving waterfall (shifted +0.6 Z clear of cliff rocks, softer foam).
	local fallPath = {
		Vector3.new(-48, 22.0, -11.2),
		Vector3.new(-48, 16.0, -7.4),
		Vector3.new(-48, 8.05, -5.8),
	}
	for seg = 1, #fallPath - 1 do
		local a, b = fallPath[seg], fallPath[seg + 1]
		local len = (b - a).Magnitude + 0.8
		local look = CFrame.lookAt((a + b) / 2, b)
		deco(
			"WaterfallSheet",
			g,
			Vector3.new(7.4, 0.55, len),
			look,
			Color3.fromRGB(82, 222, 255),
			Enum.Material.Glass,
			{ transparency = 0.24, reflectance = 0.3, shadow = false }
		)
		for _, dx in { -2.0, 0, 2.0 } do
			deco(
				"WaterfallFoamStreak",
				g,
				Vector3.new(0.45, 0.16, len),
				look * CFrame.new(dx, 0.28, 0),
				Color3.fromRGB(190, 245, 255),
				Enum.Material.Neon,
				{ transparency = 0.72, shadow = false }
			)
		end
	end
	local mistPart = deco(
		"WaterfallMistSource",
		g,
		Vector3.new(5.5, 0.2, 2),
		CFrame.new(fallPath[#fallPath]),
		COLORS.white,
		Enum.Material.SmoothPlastic,
		{ transparency = 1, shadow = false }
	)
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(Color3.fromRGB(220, 250, 255))
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.2),
		NumberSequenceKeypoint.new(1, 5.5),
	})
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	mist.Lifetime = NumberRange.new(1.1, 1.9)
	mist.Rate = 14
	mist.Speed = NumberRange.new(1.5, 3.5)
	mist.EmissionDirection = Enum.NormalId.Top
	mist.Parent = mistPart

	disc(
		"FoamOuter",
		g,
		Vector3.new(-48, 8.15, -5.6),
		4.4,
		0.14,
		Color3.fromRGB(190, 246, 255),
		Enum.Material.Neon,
		{ collide = false, transparency = 0.65, shadow = false }
	)

	-- Training spot (tagged TrainingSpot so server Training feature activates automatically).
	local spot = Vector3.new(-30, PLAZA_Y, -6)
	flushRing(
		g,
		"TrainingRing",
		spot,
		3.1,
		2.75,
		COLORS.lilac,
		COLORS.paving,
		Enum.Material.Cobblestone,
		0.04
	)
	local spotZone = part(
		"TrainingSpot",
		g,
		Vector3.new(5.5, 4, 5.5),
		CFrame.new(spot + Vector3.new(0, 2, 0)),
		COLORS.lilac,
		Enum.Material.ForceField,
		{ collide = false, transparency = 1, shadow = false }
	)
	spotZone.CanQuery = false
	CollectionService:AddTag(spotZone, "TrainingSpot")

	-- Sign placed cleanly in front of the lagoon rim, clear of the fence, with hanging lantern.
	local signCf = CFrame.new(-42, PLAZA_Y + 4.3, 19.5) * CFrame.Angles(0, math.rad(28), 0)
	sign(g, "TRAINING LAGOON\n(PRACTICE)", signCf, 7.6, 3.6, true)
	for _, dx in { -3.5, 3.5 } do
		cylinderPost(
			"SignPost",
			g,
			(signCf * CFrame.new(dx, -4.3, 0)).Position,
			6.2,
			0.45,
			COLORS.woodDark,
			Enum.Material.Wood
		)
	end
	local lanternArm = (signCf * CFrame.new(-4.8, 1.8, 0)).Position
	beam(
		"SignLanternArm",
		g,
		(signCf * CFrame.new(-3.5, 1.8, 0)).Position,
		lanternArm,
		0.28,
		COLORS.woodDark,
		Enum.Material.Wood,
		{ collide = false }
	)
	hangingLantern(g, lanternArm, 0.85, true, 28)

	buildBlossomTree(g, Vector3.new(-58, PLAZA_Y - 0.6, -14))
end

-- Upgrade workshop -------------------------------------------------------------------

local function buildWorkshop()
	local g = group("UpgradeWorkshop")
	local front = -22

	part(
		"TerraceFloor",
		g,
		Vector3.new(40, 1, 26),
		CFrame.new(-6, TERRACE_Y - 0.5, -35),
		COLORS.woodLight,
		Enum.Material.WoodPlanks
	)
	-- 4 steps rising 0.8 each (11.1, 11.9, 12.7, 13.5) -> top step never Z-fights with TerraceFloor (14.3).
	for i = 1, 4 do
		local top = PLAZA_Y + i * 0.8
		local h = top - 4
		part(
			"WorkshopStep",
			g,
			Vector3.new(16, h, 2.0),
			CFrame.new(-6, top - h / 2, -13.6 - (i - 1) * 2.0),
			COLORS.paving,
			Enum.Material.Cobblestone
		)
	end
	for _, x in { -15, 3 } do
		lantern(g, Vector3.new(x, TERRACE_Y, front + 1), 6, false)
	end

	placeMesh("Workshop", g, CFrame.new(-6, TERRACE_Y, -36), function()
		part(
			"Walls",
			g,
			Vector3.new(30, 11, 18),
			CFrame.new(-6, TERRACE_Y + 5.5, -38),
			COLORS.wood,
			Enum.Material.WoodPlanks
		)
		for _, s in { -1, 1 } do
			part(
				"Roof",
				g,
				Vector3.new(18, 1, 22),
				CFrame.new(-6 + s * 7.5, TERRACE_Y + 14, -38)
					* CFrame.Angles(0, 0, math.rad(-s * 28)),
				COLORS.roof,
				Enum.Material.Slate
			)
		end
	end)

	-- Ornate round crystal pedestal altar at the workshop front.
	local pedestal = Vector3.new(-6, TERRACE_Y, -26.5)
	flushRing(
		g,
		"AltarFloorRing",
		pedestal,
		3.2,
		2.85,
		COLORS.gold,
		COLORS.woodLight,
		Enum.Material.WoodPlanks,
		0.04
	)
	placeMesh("WorkshopAltar", g, CFrame.new(pedestal), function()
		cylinderPost("Pedestal", g, pedestal, 2.4, 2.0, COLORS.woodDark, Enum.Material.Wood)
	end, { scale = 1.0, collide = true })

	local altarTop = pedestal + Vector3.new(0, 2.8, 0)
	local workshopZone = part(
		"WorkshopSpot",
		g,
		Vector3.new(8, 5, 8),
		CFrame.new(pedestal + Vector3.new(0, 2.5, 1.5)),
		COLORS.gold,
		Enum.Material.ForceField,
		{ collide = false, transparency = 1, shadow = false }
	)
	workshopZone.CanQuery = false
	CollectionService:AddTag(workshopZone, "WorkshopSpot")
	local gem = deco(
		"UpgradeCrystalLight",
		g,
		Vector3.new(0.2, 0.2, 0.2),
		CFrame.new(altarTop + Vector3.new(0, 2.0, 0)),
		COLORS.cyan,
		Enum.Material.Neon,
		{ transparency = 1, shadow = false }
	)
	pointLight(gem, COLORS.cyan, 2.5, 22)
	placeMesh("CrystalCluster", g, CFrame.new(altarTop), function()
		deco(
			"UpgradeCrystal",
			g,
			Vector3.new(1.6, 3.4, 1.6),
			CFrame.new(altarTop + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, math.rad(45), 0),
			COLORS.cyan,
			Enum.Material.Neon,
			{ shadow = false }
		)
	end, { scale = 0.42, collide = false })

	-- Sign and 3D golden sunburst emblem above the roof.
	local shop = g:FindFirstChild("Workshop")
	local emblem = Vector3.new(-6, TERRACE_Y + 25.5, -39)
	if shop and shop:IsA("Model") then
		local cf, size = shop:GetBoundingBox()
		local face = cf.Position + Vector3.new(0, size.Y * 0.12, size.Z / 2 + 0.1)
		sign(g, "UPGRADE WORKSHOP", CFrame.new(face), size.X * 0.42, size.Y * 0.14, false)
		emblem = cf.Position + Vector3.new(0, size.Y / 2 + 5.2, size.Z * 0.14)
	else
		sign(g, "UPGRADE WORKSHOP", CFrame.new(-6, TERRACE_Y + 12.5, front - 1.5), 12, 3.6, false)
	end

	-- 3D golden 4-pointed diamond starburst + sleek halo ring nestled above the roof.
	local e = Instance.new("Model")
	e.Name = "RoofEmblem"
	for i = 1, 14 do
		local a0 = (i - 1) / 14 * math.pi * 2
		local a1 = i / 14 * math.pi * 2
		beam(
			"EmblemRing",
			e,
			emblem + Vector3.new(math.cos(a0) * 5.0, math.sin(a0) * 1.4, 0),
			emblem + Vector3.new(math.cos(a1) * 5.0, math.sin(a1) * 1.4, 0),
			0.24,
			COLORS.gold,
			Enum.Material.Neon,
			{ collide = false, shadow = false }
		)
	end
	deco(
		"EmblemCenter",
		e,
		Vector3.new(1.6, 1.6, 1.6),
		CFrame.new(emblem),
		COLORS.gold,
		Enum.Material.Neon,
		{ shape = Enum.PartType.Ball, shadow = false }
	)
	for i = 0, 1 do
		local rotZ = if i == 0 then 0 else math.pi / 2
		local stretch = if i == 0 then 6.2 else 7.6
		deco(
			"EmblemDiamondBlade",
			e,
			Vector3.new(0.95, stretch, 0.7),
			CFrame.new(emblem) * CFrame.Angles(0, 0, rotZ),
			COLORS.gold,
			Enum.Material.Neon,
			{ shape = Enum.PartType.Ball, shadow = false }
		)
	end
	e.Parent = g

	-- Lush cascading wisteria vines on the rocky peak behind/above the workshop roof.
	for _, wp in
		{
			{ -12, TERRACE_Y + 19, -48, 2.2 },
			{ 2, TERRACE_Y + 19.5, -49, 2.4 },
			{ -5, TERRACE_Y + 21, -50, 2.0 },
		}
	do
		placeMesh("WisteriaDrape", g, CFrame.new(wp[1], wp[2], wp[3]), function() end, {
			scale = wp[4],
			collide = false,
			anchorMode = "top",
		})
	end
end

-- Fishing pier -------------------------------------------------------------------------

local function buildPier()
	local g = group("FishingPier")
	local x0, x1, zc, w = 18.2, 84, 8, 14

	-- Single smooth invisible deck collider eliminates plank seams and cuts 28 shadow casters.
	local deckCollider = part(
		"PierDeckCollider",
		g,
		Vector3.new(x1 - x0 + 2.4, 0.5, w),
		CFrame.new((x0 + x1) / 2, PIER_Y - 0.25, zc),
		COLORS.wood,
		Enum.Material.WoodPlanks,
		{ transparency = 1, shadow = false }
	)
	deckCollider.CanQuery = true

	for x = x0, x1, 2.4 do
		deco(
			"Plank",
			g,
			Vector3.new(2.25, 0.5, w),
			CFrame.new(x, PIER_Y - 0.25, zc),
			if math.floor(x) % 3 == 0 then COLORS.woodLight else COLORS.wood,
			Enum.Material.WoodPlanks,
			{ shadow = false }
		)
	end
	for _, dz in { -w / 2 + 0.6, w / 2 - 0.6 } do
		part(
			"Stringer",
			g,
			Vector3.new(x1 - x0 + 2, 1, 0.9),
			CFrame.new((x0 + x1) / 2, PIER_Y - 1, zc + dz),
			COLORS.woodDark,
			Enum.Material.Wood
		)
	end

	-- Pilings stay strictly below the planks (top at PIER_Y - 0.55) to eliminate deck Z-fighting;
	-- round railing posts sit cleanly on top of the deck.
	local railTop: { [number]: Vector3? } = {}
	local postIndex = 0
	for x = x0 + 4, x1, 8 do
		postIndex += 1
		for side, dz in { -w / 2 + 0.45, w / 2 - 0.45 } do
			cylinderPost(
				"Piling",
				g,
				Vector3.new(x, PIER_Y - 22, zc + dz),
				21.45,
				0.72,
				COLORS.woodDark,
				Enum.Material.Wood
			)
			local postBase = Vector3.new(x, PIER_Y, zc + dz)
			cylinderPost(
				"RailingPost",
				g,
				postBase,
				3.3,
				0.42,
				COLORS.wood,
				Enum.Material.Wood,
				{ shadow = false }
			)
			local top = postBase + Vector3.new(0, 3.3, 0)
			deco(
				"PostCap",
				g,
				Vector3.new(0.28, 1.0, 1.0),
				CFrame.new(top + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				COLORS.bronze,
				Enum.Material.Metal,
				{ shape = Enum.PartType.Cylinder, shadow = false }
			)
			local prev = railTop[side]
			if prev then
				ropeSpan(g, prev - Vector3.new(0, 0.2, 0), top - Vector3.new(0, 0.2, 0), 0.65, 0.17)
			end
			railTop[side] = top
			if postIndex % 3 == 2 and side == 1 then
				lantern(g, Vector3.new(x, PIER_Y, zc + dz), 5.5, postIndex == 5)
			end
		end
	end

	-- Climbable wooden swim ladders in open water beside the pier (x = 44), with gap in RailCollider.
	local function swimLadder(name: string, pos: Vector3, height: number)
		local truss = Instance.new("TrussPart")
		truss.Name = name
		truss.Anchored = true
		truss.Size = Vector3.new(2, height, 2)
		truss.Position = pos
		truss.Color = COLORS.wood
		truss.Material = Enum.Material.Wood
		truss.CastShadow = false
		truss.Parent = g
	end
	swimLadder("PierSwimLadderSouth", Vector3.new(44, 4.5, zc + w / 2 + 0.8), 13)
	swimLadder("PierSwimLadderNorth", Vector3.new(44, 4.5, zc - w / 2 - 0.8), 13)

	-- Invisible side/end rails keep players on deck (leaving a 4-stud gap at x=42..46 for swim ladders).
	for _, dz in { -w / 2, w / 2 } do
		for _, seg in { { x0, 42 }, { 46, x1 + 1.5 } } do
			local len = seg[2] - seg[1]
			local rail = part(
				"RailCollider",
				g,
				Vector3.new(len, 4, 0.4),
				CFrame.new((seg[1] + seg[2]) / 2, PIER_Y + 2, zc + dz),
				COLORS.wood,
				Enum.Material.Wood,
				{ transparency = 1, shadow = false }
			)
			rail.CanQuery = false
		end
	end
	part(
		"EndCollider",
		g,
		Vector3.new(0.4, 4, w),
		CFrame.new(x1 + 1.4, PIER_Y + 2, zc),
		COLORS.wood,
		Enum.Material.Wood,
		{ transparency = 1, shadow = false }
	).CanQuery =
		false

	-- Sturdy rustic entrance arch with fish crest, 2 hanging lanterns, and left blue pennant banner.
	local archX = x0 + 1.0
	for _, dz in { -w / 2 + 0.45, w / 2 - 0.45 } do
		local base = Vector3.new(archX, PIER_Y, zc + dz)
		part(
			"ArchStoneBase",
			g,
			Vector3.new(2.0, 1.4, 2.0),
			CFrame.new(base + Vector3.new(0, 0.7, 0)),
			COLORS.pavingDark,
			Enum.Material.Cobblestone
		)
		cylinderPost("ArchPost", g, base, 13.0, 0.75, COLORS.woodDark, Enum.Material.Wood)
		hangingLantern(
			g,
			Vector3.new(archX - 0.9, PIER_Y + 11.4, zc + dz * 0.78),
			0.95,
			dz > 0,
			-90
		)
	end
	part(
		"ArchBeam",
		g,
		Vector3.new(1.5, 1.3, w + 2.4),
		CFrame.new(archX, PIER_Y + 12.8, zc),
		COLORS.woodDark,
		Enum.Material.Wood
	)
	sign(
		g,
		"FISHING PIER",
		CFrame.new(archX, PIER_Y + 10.4, zc) * CFrame.Angles(0, math.rad(-90), 0),
		10,
		3,
		true
	)

	-- Blue pennant banner on the left (north / -Z) column of the pier arch, matching the reference.
	local bannerCf = CFrame.new(archX - 1.1, PIER_Y + 8.6, zc - w / 2 + 0.45)
	deco(
		"Banner",
		g,
		Vector3.new(0.18, 4.8, 2.4),
		bannerCf,
		COLORS.banner,
		Enum.Material.Fabric,
		{ shadow = false }
	)
	deco(
		"BannerTrim",
		g,
		Vector3.new(0.22, 0.25, 2.6),
		bannerCf * CFrame.new(0, 2.4, 0),
		COLORS.gold,
		Enum.Material.Metal,
		{ shadow = false }
	)
	deco(
		"BannerEmblem",
		g,
		Vector3.new(0.24, 1.35, 1.35),
		bannerCf * CFrame.Angles(math.rad(45), 0, 0),
		COLORS.cyan,
		Enum.Material.Neon,
		{ shadow = false }
	)

	-- Smooth AI-mesh lifebuoy rings mounted vertically on the pier side stringers.
	for _, x in { 38, 70 } do
		placeMesh(
			"LifeRing",
			g,
			CFrame.new(x, PIER_Y + 0.6, zc + w / 2 + 0.3) * CFrame.Angles(math.rad(90), 0, 0),
			function()
				deco(
					"LifeRingFallback",
					g,
					Vector3.new(0.4, 2.6, 2.6),
					CFrame.new(x, PIER_Y + 0.6, zc + w / 2 + 0.3)
						* CFrame.Angles(0, math.rad(90), 0),
					COLORS.red,
					Enum.Material.SmoothPlastic,
					{ shape = Enum.PartType.Cylinder }
				)
			end,
			{ scale = 3.2, collide = false, anchorMode = "center" }
		)
	end

	-- Crate stacks neatly tucked next to the pier entrance.
	for _, spot in
		{
			{ pos = Vector3.new(15, PLAZA_Y - 0.05, 17.5), yaw = 20 },
			{ pos = Vector3.new(15, PLAZA_Y - 0.05, -2.5), yaw = 160 },
		}
	do
		placeMesh(
			"CrateStack",
			g,
			CFrame.new(spot.pos) * CFrame.Angles(0, math.rad(spot.yaw), 0),
			function() end,
			{ scale = 1.1, collide = true }
		)
	end

	-- Fishing spot ring at the pier tip.
	flushRing(
		g,
		"FishingSpotRing",
		Vector3.new(x1 - 3, PIER_Y, zc),
		2.8,
		2.5,
		COLORS.cyan,
		COLORS.wood,
		Enum.Material.WoodPlanks,
		0.03
	)

	-- Server checks the player stands inside this box before accepting a cast.
	local zone = part(
		"FishingZone",
		g,
		Vector3.new(x1 - 40 + 2, 10, w),
		CFrame.new((40 + x1) / 2 + 1, PIER_Y + 4, zc),
		COLORS.cyan,
		Enum.Material.ForceField,
		{ collide = false, transparency = 1, shadow = false }
	)
	zone.CanQuery = false
	CollectionService:AddTag(zone, "FishingZone")

	-- Red & white cone buoys bobbing in the shallow turquoise sea near the pier.
	for _, bp in
		{
			{ 46, -0.6, 25, 15 },
			{ 90, -0.6, 18, -25 },
			{ 74, -0.6, -12, 40 },
		}
	do
		placeMesh(
			"ConeBuoy",
			g,
			CFrame.new(bp[1], bp[2], bp[3]) * CFrame.Angles(0, math.rad(bp[4]), 0),
			function()
				cylinderPost(
					"BuoyFallback",
					g,
					Vector3.new(bp[1], bp[2], bp[3]),
					3.5,
					1.2,
					COLORS.red,
					Enum.Material.SmoothPlastic
				)
			end,
			{ scale = 1.15, collide = false }
		)
	end
end

-- Vegetation and crystals ----------------------------------------------------------------

local function crystalCluster(
	parent: Instance,
	base: Vector3,
	scale: number,
	withLight: boolean,
	tiltDeg: number?
)
	if withLight then
		local glow = deco(
			"CrystalGlow",
			parent,
			Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(base + Vector3.new(0, scale * 0.6, 0)),
			COLORS.cyan,
			Enum.Material.Neon,
			{ transparency = 1, shadow = false }
		)
		pointLight(glow, COLORS.cyan, 1.7, math.min(scale * 2.4, 34))
	end
	local cf = CFrame.new(base)
		* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), math.rad(tiltDeg or 0))
	placeMesh("CrystalCluster", parent, cf, function()
		for i = 1, 4 do
			local a = i * 1.7
			local h = scale * rng:NextNumber(0.5, 1)
			local p = base
				+ Vector3.new(math.cos(a) * scale * 0.3, h / 2, math.sin(a) * scale * 0.3)
			deco(
				"Crystal",
				parent,
				Vector3.new(h * 0.32, h, h * 0.32),
				CFrame.new(p)
					* CFrame.Angles(
						math.rad(rng:NextNumber(-16, 16)),
						a,
						math.rad(rng:NextNumber(-16, 16))
					),
				if i == 3 then COLORS.lilac else COLORS.crystal,
				Enum.Material.Glass,
				{ transparency = 0.15, shadow = false }
			)
		end
	end, { scale = scale / 12 * 2, collide = false })
end

local function palm(parent: Instance, base: Vector3, s: number)
	placeMesh(
		"PalmTree",
		parent,
		CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
		function()
			local top = base + Vector3.new(s * 1.5, s * 9, 0)
			beam("PalmTrunk", parent, base, top, s * 0.9, COLORS.wood, Enum.Material.Wood)
		end,
		{ scale = s * 0.88, collide = true }
	)
end

local function flowerBush(parent: Instance, base: Vector3, s: number)
	placeMesh(
		"FlowerBushRich",
		parent,
		CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
		function()
			deco(
				"BushFallback",
				parent,
				Vector3.new(s * 1.5, s, s * 1.5),
				CFrame.new(base + Vector3.new(0, s * 0.5, 0)),
				COLORS.grass,
				Enum.Material.Grass,
				{ shape = Enum.PartType.Ball, shadow = false }
			)
		end,
		{ scale = s * 0.65, collide = false }
	)
end

local function buildDecor()
	local g = group("Decor")

	-- Crystals: giant spires behind the workshop + glowing shore & shallow water clusters.
	-- Light flag kept selective (~5 lights here) to stay well within mobile GPU light limits.
	for _, c in
		{
			{ -25, 19, -59, 19, true, 12 }, -- giant spire behind left of workshop
			{ -14, 21, -61, 14, false, -8 }, -- secondary giant spire
			{ 10, 17, -58, 11, false, -10 },
			{ -37, 9, -46, 9, false, 8 },
			{ 22, 10, -40, 8, false, -6 },
			{ -70, 4, 14, 8, false, 10 },
			{ -55, 3, 34, 9, false, 12 },
			{ -66, 6, -26, 7, false, 8 },
			{ 10, 3, 36, 9, true, -10 }, -- front-right shore crystal near stairs
			{ -19, 4, 36, 8, false, 12 }, -- front-left shore crystal near stairs
			{ 8, 2, 43, 6, false, -6 },
			{ 24, 3, 24, 7, false, -8 },
			{ 56, -2, 22, 8, false, -6 }, -- crystal rising from shallow water near pier
			{ 30, -2, -18, 7, false, 8 },
			{ -36, 1.5, 40, 6.5, false, 14 }, -- front-left shallow water crystal
			{ 26, -1.5, 16, 6.0, false, -10 }, -- pier shallow water crystal
		}
	do
		crystalCluster(g, Vector3.new(c[1], c[2], c[3]), c[4], c[5], c[6])
	end

	palm(g, Vector3.new(-26, TERRACE_Y - 2, -46), 1.45)
	palm(g, Vector3.new(16, TERRACE_Y - 3, -40), 1.4)
	palm(g, Vector3.new(-66, PLAZA_Y - 1, 20), 1.15)

	for _, b in
		{
			{ -49, PLAZA_Y - 0.5, 24, 2.0 }, -- left of lagoon sign so text stays unobstructed
			{ -30, PLAZA_Y - 0.5, 28, 2.2 },
			{ -20, PLAZA_Y - 0.5, 30, 2.6 },
			{ 6, PLAZA_Y - 0.5, 28, 2.6 },
			{ 16, PLAZA_Y - 0.5, 22, 2.2 },
			{ 18, PLAZA_Y - 0.5, -6, 2.4 },
			{ -24, PLAZA_Y - 0.5, -14, 2.2 },
			{ 8, PLAZA_Y - 0.5, -12, 2.0 },
			{ -22, TERRACE_Y, -24, 2.0 },
			{ 10, TERRACE_Y, -24, 2.0 },
			{ -62, PLAZA_Y - 0.5, 4, 2.4 },
			{ -60, PLAZA_Y - 0.5, 20, 2.2 },
			{ -14, 20, -52, 2.6 },
			{ -10, 24, -55, 2.2 }, -- greenery on upper peak behind workshop
			{ 2, 23, -53, 2.0 },
		}
	do
		flowerBush(g, Vector3.new(b[1], b[2], b[3]), b[4])
	end

	-- Plaza corner lanterns (2 carry lights, 2 rely on Neon+Bloom).
	local plazaLanterns = {
		{ Vector3.new(-28, PLAZA_Y, -10), true },
		{ Vector3.new(14, PLAZA_Y, -6), false },
		{ Vector3.new(12, PLAZA_Y, 20), true },
		{ Vector3.new(-25, PLAZA_Y, 20), false },
	}
	for _, item in plazaLanterns do
		lantern(g, item[1], 6, item[2])
	end

	-- Bunting strings between the workshop roof corners and the flanking palm areas.
	local function bunting(a: Vector3, b: Vector3, count: number)
		ropeSpan(g, a, b, 1.4, 0.1)
		local palette = { COLORS.pink, COLORS.cyan, COLORS.gold, COLORS.lilac }
		for i = 1, count do
			local t = i / (count + 1)
			local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * 1.4 + 0.85, 0)
			deco(
				"Flag",
				g,
				Vector3.new(0.1, 1.5, 1.3),
				CFrame.lookAt(p, p + (b - a).Unit:Cross(Vector3.yAxis))
					* CFrame.Angles(0, math.rad(90), math.rad(180)),
				palette[1 + i % #palette],
				Enum.Material.Fabric,
				{ wedge = true, shadow = false }
			)
		end
	end
	bunting(Vector3.new(-21, TERRACE_Y + 12, -26), Vector3.new(-35, TERRACE_Y + 7.5, -18), 6)
	bunting(Vector3.new(9, TERRACE_Y + 12, -26), Vector3.new(23, TERRACE_Y + 5.5, -17), 6)
end

-- Horizon and lighting ------------------------------------------------------------------

local function buildHorizon()
	local g = group("Horizon")
	for _, p in
		{ Vector3.new(-420, 0, -520), Vector3.new(-160, 0, -700), Vector3.new(380, 0, -560) }
	do
		Terrain:FillBall(p + Vector3.new(0, -6, 0), 26, Enum.Material.Rock)
		Terrain:FillBall(p + Vector3.new(14, 4, 6), 14, Enum.Material.Rock)
	end
	-- Mystic citadel with a glowing halo ring on the upper-right horizon (scenery only).
	local c = Vector3.new(440, 0, -720)
	Terrain:FillBall(c + Vector3.new(0, -10, 0), 42, Enum.Material.Rock)
	part(
		"CitadelSpire",
		g,
		Vector3.new(16, 86, 16),
		CFrame.new(c + Vector3.new(0, 43, 0)),
		COLORS.rock,
		Enum.Material.Slate,
		{ shadow = false }
	)
	part(
		"CitadelTower",
		g,
		Vector3.new(10, 52, 10),
		CFrame.new(c + Vector3.new(-20, 26, 6)),
		COLORS.rock,
		Enum.Material.Slate,
		{ shadow = false }
	)
	part(
		"CitadelTower",
		g,
		Vector3.new(10, 60, 10),
		CFrame.new(c + Vector3.new(18, 30, -4)),
		COLORS.rock,
		Enum.Material.Slate,
		{ shadow = false }
	)
	for i = 1, 16 do
		local a0 = (i - 1) / 16 * math.pi * 2
		local a1 = i / 16 * math.pi * 2
		local h = c + Vector3.new(0, 102, 0)
		beam(
			"Halo",
			g,
			h + Vector3.new(math.cos(a0) * 52, 0, math.sin(a0) * 52),
			h + Vector3.new(math.cos(a1) * 52, 0, math.sin(a1) * 52),
			1.6,
			COLORS.white,
			Enum.Material.Neon,
			{ collide = false, shadow = false }
		)
	end
end

-- Invisible 16-sided sea barrier at ~250 studs from island center so players stay inside the playable ocean.
local function buildOceanBounds()
	local g = group("OceanBounds")
	local center = Vector3.new(-10, 0, 0)
	local radius = 250
	local sides = 16
	local segLen = 2 * radius * math.tan(math.pi / sides) + 6
	for i = 1, sides do
		local a = (i - 1) / sides * math.pi * 2
		local pos = center + Vector3.new(math.cos(a) * radius, 20, math.sin(a) * radius)
		local wall = part(
			"OceanBarrier",
			g,
			Vector3.new(segLen, 80, 4),
			CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z)),
			COLORS.cyan,
			Enum.Material.ForceField,
			{ collide = true, transparency = 1, shadow = false }
		)
		wall.CanQuery = false
		wall.CanTouch = false
	end
end

local function buildLighting()
	for _, child in Lighting:GetChildren() do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") then
			child:Destroy()
		end
	end
	Lighting.ClockTime = 14.2
	Lighting.Brightness = 3
	Lighting.EnvironmentDiffuseScale = 0.65
	Lighting.EnvironmentSpecularScale = 0.85
	Lighting.Ambient = Color3.fromRGB(115, 125, 155)
	Lighting.OutdoorAmbient = Color3.fromRGB(154, 174, 204)
	Lighting.ExposureCompensation = -0.1

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.34
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(196, 226, 255)
	atmosphere.Decay = Color3.fromRGB(96, 150, 210)
	atmosphere.Glare = 0.25
	atmosphere.Haze = 1.3
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.65
	bloom.Size = 24
	bloom.Threshold = 1.05
	bloom.Parent = Lighting

	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.22
	grade.Contrast = 0.08
	grade.Brightness = 0.02
	grade.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.05
	rays.Spread = 0.7
	rays.Parent = Lighting

	local clouds = Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.55
	clouds.Color = Color3.fromRGB(255, 255, 255)
	clouds.Parent = Terrain

	local starterPlayer = game:GetService("StarterPlayer")
	starterPlayer.CameraMaxZoomDistance = 90

	-- Streaming tuned for a compact island on phones: keeps the hub loaded, streams distant horizon opportunistically.
	Workspace.StreamingEnabled = true
	Workspace.StreamingMinRadius = 128
	Workspace.StreamingTargetRadius = 1024
	Workspace.StreamOutBehavior = Enum.StreamOutBehavior.Opportunistic
end

local function buildGuideNPC()
	local g = group("GuideNPC")
	g.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local basePos = Vector3.new(13.8, PLAZA_Y, 1.8)
	local lookTarget = Vector3.new(-4, PLAZA_Y, 10)
	local npcCf = CFrame.lookAt(basePos, lookTarget)

	local function npcPart(
		name: string,
		size: Vector3,
		localCf: CFrame,
		color: Color3,
		material: Enum.Material,
		opts: PartOpts?
	): BasePart
		local o: PartOpts = if opts then table.clone(opts) else {}
		o.collide = false
		if o.shadow == nil then
			o.shadow = false
		end
		return part(name, g, size, npcCf * localCf, color, material, o)
	end

	local skin = Color3.fromRGB(238, 186, 148)
	local shirt = COLORS.cream
	local vest = Color3.fromRGB(46, 94, 108)
	local vestTrim = COLORS.woodLight
	local trousers = Color3.fromRGB(58, 78, 96)
	local boots = Color3.fromRGB(58, 42, 34)
	local eyeColor = Color3.fromRGB(30, 34, 46)

	-- Legs & boots (slightly open natural fisherman stance, facing -Z)
	for _, leg in
		{
			{ side = "L", x = -0.54, z = -0.10, yaw = 8 },
			{ side = "R", x = 0.54, z = 0.08, yaw = -8 },
		}
	do
		local lCf = CFrame.new(leg.x, 0, leg.z) * CFrame.Angles(0, math.rad(leg.yaw), 0)
		npcPart(
			"Boot" .. leg.side,
			Vector3.new(0.86, 0.72, 1.12),
			lCf * CFrame.new(0, 0.36, -0.10),
			boots,
			Enum.Material.Leather,
			{ shadow = true }
		)
		npcPart(
			"BootSole" .. leg.side,
			Vector3.new(0.90, 0.14, 1.16),
			lCf * CFrame.new(0, 0.07, -0.10),
			Color3.fromRGB(38, 28, 22),
			Enum.Material.Rubber
		)
		npcPart(
			"BootCuff" .. leg.side,
			Vector3.new(0.94, 0.24, 0.96),
			lCf * CFrame.new(0, 0.78, 0),
			vestTrim,
			Enum.Material.Fabric
		)
		npcPart(
			"Leg" .. leg.side,
			Vector3.new(0.84, 1.28, 0.86),
			lCf * CFrame.new(0, 1.44, 0),
			trousers,
			Enum.Material.Fabric,
			{ shadow = true }
		)
	end

	-- Core torso: the ONLY collidable part on the Guide NPC
	local torso = part(
		"Torso",
		g,
		Vector3.new(2.04, 2.08, 1.12),
		npcCf * CFrame.new(0, 3.04, 0),
		shirt,
		Enum.Material.Fabric,
		{ collide = true, shadow = true }
	)
	g.PrimaryPart = torso

	-- Belt & brass buckle
	npcPart(
		"Belt",
		Vector3.new(2.14, 0.28, 1.22),
		CFrame.new(0, 2.16, 0),
		boots,
		Enum.Material.Leather
	)
	npcPart(
		"BeltBuckle",
		Vector3.new(0.42, 0.34, 0.18),
		CFrame.new(0, 2.16, -0.58),
		COLORS.gold,
		Enum.Material.Metal
	)

	-- Open fisherman vest over shirt
	npcPart(
		"VestBack",
		Vector3.new(2.16, 1.88, 0.46),
		CFrame.new(0, 3.12, 0.40),
		vest,
		Enum.Material.Fabric
	)
	for _, sx in { -0.66, 0.66 } do
		npcPart(
			"VestFront" .. (if sx < 0 then "L" else "R"),
			Vector3.new(0.78, 1.86, 0.78),
			CFrame.new(sx, 3.12, -0.22),
			vest,
			Enum.Material.Fabric
		)
		npcPart(
			"VestPocket" .. (if sx < 0 then "L" else "R"),
			Vector3.new(0.46, 0.44, 0.16),
			CFrame.new(sx, 2.66, -0.60),
			vestTrim,
			Enum.Material.Leather
		)
		npcPart(
			"VestButton" .. (if sx < 0 then "L" else "R"),
			Vector3.new(0.12, 0.12, 0.10),
			CFrame.new(sx * 0.56, 3.24, -0.62),
			COLORS.bronze,
			Enum.Material.Metal,
			{ shape = Enum.PartType.Ball }
		)
	end
	-- Small cyan crystal lure charm clipped to left vest chest
	npcPart(
		"VestCrystalPin",
		Vector3.new(0.16, 0.26, 0.14),
		CFrame.new(-0.68, 3.50, -0.62) * CFrame.Angles(0, 0, math.rad(14)),
		COLORS.cyan,
		Enum.Material.Neon
	)

	-- Diagonal leather rod strap across front & back of vest
	npcPart(
		"RodStrapFront",
		Vector3.new(0.24, 2.38, 0.12),
		CFrame.new(0, 3.12, -0.62) * CFrame.Angles(0, 0, math.rad(-34)),
		boots,
		Enum.Material.Leather
	)
	npcPart(
		"RodStrapBack",
		Vector3.new(0.24, 2.38, 0.12),
		CFrame.new(0, 3.12, 0.64) * CFrame.Angles(0, 0, math.rad(-34)),
		boots,
		Enum.Material.Leather
	)

	-- Friendly standing arms: +Z swings (-Y) out to +X, +X swings (-Y) forward to -Z.
	local rShoulder = CFrame.new(1.36, 3.82, 0) * CFrame.Angles(math.rad(6), 0, math.rad(14))
	npcPart(
		"ShoulderR",
		Vector3.new(0.68, 0.68, 0.68),
		rShoulder * CFrame.new(0, -0.06, 0),
		shirt,
		Enum.Material.Fabric,
		{ shape = Enum.PartType.Ball }
	)
	npcPart(
		"ArmR",
		Vector3.new(0.58, 0.88, 0.58),
		rShoulder * CFrame.new(0, -0.48, 0),
		shirt,
		Enum.Material.Fabric
	)
	npcPart(
		"CuffR",
		Vector3.new(0.64, 0.18, 0.64),
		rShoulder * CFrame.new(0, -0.88, 0),
		shirt,
		Enum.Material.Fabric
	)
	local rElbow = rShoulder
		* CFrame.new(0, -0.98, 0)
		* CFrame.Angles(math.rad(18), 0, math.rad(-10))
	npcPart(
		"ForearmR",
		Vector3.new(0.48, 0.82, 0.48),
		rElbow * CFrame.new(0, -0.40, 0),
		skin,
		Enum.Material.SmoothPlastic
	)
	npcPart(
		"HandR",
		Vector3.new(0.48, 0.48, 0.48),
		rElbow * CFrame.new(0, -0.84, 0),
		skin,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Ball }
	)

	local lShoulder = CFrame.new(-1.38, 3.82, 0) * CFrame.Angles(math.rad(14), 0, math.rad(-22))
	npcPart(
		"ShoulderL",
		Vector3.new(0.68, 0.68, 0.68),
		lShoulder * CFrame.new(0, -0.06, 0),
		shirt,
		Enum.Material.Fabric,
		{ shape = Enum.PartType.Ball }
	)
	npcPart(
		"ArmL",
		Vector3.new(0.58, 0.86, 0.58),
		lShoulder * CFrame.new(0, -0.48, 0),
		shirt,
		Enum.Material.Fabric
	)
	npcPart(
		"CuffL",
		Vector3.new(0.64, 0.18, 0.64),
		lShoulder * CFrame.new(0, -0.86, 0),
		shirt,
		Enum.Material.Fabric
	)
	local lElbow = lShoulder
		* CFrame.new(0, -0.96, 0)
		* CFrame.Angles(math.rad(42), 0, math.rad(10))
	npcPart(
		"ForearmL",
		Vector3.new(0.48, 0.82, 0.48),
		lElbow * CFrame.new(0, -0.40, 0),
		skin,
		Enum.Material.SmoothPlastic
	)
	npcPart(
		"HandL",
		Vector3.new(0.48, 0.48, 0.48),
		lElbow * CFrame.new(0, -0.84, 0),
		skin,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Ball }
	)

	-- Neck & head + SpeechPoint attachment (~1 stud above head)
	npcPart(
		"Neck",
		Vector3.new(0.64, 0.36, 0.64),
		CFrame.new(0, 4.18, 0),
		skin,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder }
	)
	local headSize = Vector3.new(1.36, 1.28, 1.28)
	local head = npcPart(
		"Head",
		headSize,
		CFrame.new(0, 4.86, 0),
		skin,
		Enum.Material.SmoothPlastic,
		{ shadow = true }
	)
	local headCorner = Instance.new("SpecialMesh")
	headCorner.MeshType = Enum.MeshType.Head
	headCorner.Scale = Vector3.new(1.0, 1.0, 1.0)
	headCorner.Parent = head

	local speechPoint = Instance.new("Attachment")
	speechPoint.Name = "SpeechPoint"
	speechPoint.Position = Vector3.new(0, headSize.Y / 2 + 1.05, 0)
	speechPoint.Parent = head

	-- Expressive face features (-Z is front) & fluffy white veteran hair around back/sides
	npcPart(
		"Nose",
		Vector3.new(0.28, 0.24, 0.32),
		CFrame.new(0, 4.84, -0.68),
		Color3.fromRGB(224, 152, 120),
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Ball }
	)
	local backHair = npcPart(
		"BackHair",
		Vector3.new(1.38, 0.78, 0.68),
		CFrame.new(0, 4.90, 0.34),
		COLORS.white,
		Enum.Material.SmoothPlastic
	)
	local backHairMesh = Instance.new("SpecialMesh")
	backHairMesh.MeshType = Enum.MeshType.Sphere
	backHairMesh.Parent = backHair
	local backTuft = npcPart(
		"BackHairTuft",
		Vector3.new(0.86, 0.44, 0.48),
		CFrame.new(0, 4.56, 0.44),
		COLORS.white,
		Enum.Material.SmoothPlastic
	)
	local backTuftMesh = Instance.new("SpecialMesh")
	backTuftMesh.MeshType = Enum.MeshType.Sphere
	backTuftMesh.Parent = backTuft
	for _, side in { -1, 1 } do
		local sideburn = npcPart(
			"Sideburn" .. side,
			Vector3.new(0.32, 0.60, 0.54),
			CFrame.new(side * 0.54, 4.80, 0.16),
			COLORS.white,
			Enum.Material.SmoothPlastic
		)
		local sbMesh = Instance.new("SpecialMesh")
		sbMesh.MeshType = Enum.MeshType.Sphere
		sbMesh.Parent = sideburn
		npcPart(
			"Ear" .. side,
			Vector3.new(0.20, 0.32, 0.26),
			CFrame.new(side * 0.68, 4.84, 0.02),
			skin,
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Ball }
		)
		npcPart(
			"Eye" .. side,
			Vector3.new(0.16, 0.20, 0.12),
			CFrame.new(side * 0.28, 4.96, -0.60),
			eyeColor,
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Ball }
		)
		npcPart(
			"EyeShine" .. side,
			Vector3.new(0.06, 0.06, 0.05),
			CFrame.new(side * 0.26 - 0.03, 5.00, -0.64),
			COLORS.white,
			Enum.Material.Neon,
			{ shape = Enum.PartType.Ball }
		)
		npcPart(
			"Brow" .. side,
			Vector3.new(0.32, 0.12, 0.14),
			CFrame.new(side * 0.28, 5.14, -0.58) * CFrame.Angles(0, 0, math.rad(side * -10)),
			COLORS.white,
			Enum.Material.SmoothPlastic
		)
	end

	-- Fisherman Hat (AI mesh with primitive fallback)
	local hatCf = npcCf * CFrame.new(0, 5.24, 0.04) * CFrame.Angles(math.rad(6), 0, math.rad(-3))
	placeMesh("FishermanHat", g, hatCf, function()
		npcPart(
			"HatBrim",
			Vector3.new(2.2, 0.18, 2.2),
			CFrame.new(0, 5.36, 0),
			vestTrim,
			Enum.Material.Fabric,
			{ shape = Enum.PartType.Cylinder }
		)
		npcPart(
			"HatCrown",
			Vector3.new(1.45, 0.68, 1.45),
			CFrame.new(0, 5.72, 0),
			vestTrim,
			Enum.Material.Fabric
		)
	end, { scale = 0.96, collide = false, shadow = true, anchorMode = "bottom" })

	-- White veteran beard (AI mesh with primitive fallback)
	local beardCf = npcCf * CFrame.new(0, 4.32, -0.52)
	placeMesh("FishermanBeard", g, beardCf, function()
		npcPart(
			"BeardFallback",
			Vector3.new(1.16, 0.92, 0.62),
			CFrame.new(0, 4.46, -0.46),
			COLORS.white,
			Enum.Material.SmoothPlastic
		)
	end, { scale = 0.92, collide = false, shadow = false, anchorMode = "center" })

	-- Fishing rod strapped diagonally across his back (+Z side)
	local rodsFolder = ServerStorage:FindFirstChild("RodModels")
	local rodTemplate = rodsFolder
		and (rodsFolder:FindFirstChild("starter") or rodsFolder:FindFirstChildOfClass("Model"))
	if rodTemplate then
		local rodClone = rodTemplate:Clone()
		rodClone.Name = "BackFishingRod"
		for _, tag in CollectionService:GetTags(rodClone) do
			CollectionService:RemoveTag(rodClone, tag)
		end
		for _, d in rodClone:GetDescendants() do
			for _, tag in CollectionService:GetTags(d) do
				CollectionService:RemoveTag(d, tag)
			end
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanTouch = false
				d.CanQuery = false
				d.CastShadow = false
			elseif d:IsA("Script") or d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		rodClone:ScaleTo(rodClone:GetScale() * 0.72)
		local _, rSize = rodClone:GetBoundingBox()
		-- Rod models extend toward -Z; rotate 90 deg pitch up so tip aims upward-left behind shoulder.
		local backRodCf = npcCf
			* CFrame.new(-0.36, 1.88, 0.68)
			* CFrame.Angles(0, 0, math.rad(28))
			* CFrame.Angles(math.rad(88), 0, 0)
		rodClone:PivotTo(backRodCf * CFrame.new(0, 0, -rSize.Z * 0.10))
		rodClone.Parent = g
	end

	CollectionService:AddTag(g, "GuideNPC")
end

-- Entry -------------------------------------------------------------------------------

local old = Workspace:FindFirstChild("Island")
if old then
	old:Destroy()
end
local legacy = Workspace:FindFirstChild("IlhaMistica_FishingHub")
if legacy then
	legacy:Destroy()
end

root = Instance.new("Model")
root.Name = "Island"
root.Parent = Workspace

buildOcean()
buildIsland()
buildPlaza()
task.wait()
buildCampfire()
buildStairs()
buildLagoon()
task.wait()
buildWorkshop()
buildPier()
task.wait()
buildDecor()
buildHorizon()
buildOceanBounds()
buildLighting()
buildGuideNPC()

for _, name in { "CentralPlaza", "TrainingLagoon", "UpgradeWorkshop", "FishingPier", "FrontStairs" } do
	local m = groups[name]
	if m then
		m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end
end

root:SetAttribute("GeneratorVersion", 3)
print(`[IslandGenerator] built {#root:GetDescendants()} instances`)

return true
