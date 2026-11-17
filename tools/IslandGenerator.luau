--[[
	Island generator v2 (Edit-time only).

	Builds the hub island from the approved reference (art/reference/island-approved.png):
	training lagoon on the left, upgrade workshop on a raised terrace at the back, paved plaza
	in the middle, stone stairs at the front and the fishing pier on the right.

	Axes: +X = pier side, -X = lagoon side, -Z = workshop (back), +Z = stairs (front).
	Sea level is y = 0. Plaza top is y = PLAZA_Y.

	Run from the MCP (`execute_luau` in Edit) by requiring a clone of this module. It wipes
	Terrain and rebuilds Workspace.Island, so the place must be dedicated to this map.
	AI meshes are optional: templates found in ServerStorage.MapMeshes replace the part
	fallbacks (see `placeMesh`).
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
	rock = Color3.fromRGB(116, 122, 150),
	rockDark = Color3.fromRGB(84, 90, 122),
	grass = Color3.fromRGB(86, 176, 92),
	sand = Color3.fromRGB(236, 214, 168),
	seabed = Color3.fromRGB(14, 42, 86),
	paving = Color3.fromRGB(168, 152, 146),
	pavingDark = Color3.fromRGB(136, 124, 128),
	wood = Color3.fromRGB(150, 92, 52),
	woodLight = Color3.fromRGB(186, 128, 76),
	woodDark = Color3.fromRGB(92, 56, 38),
	rope = Color3.fromRGB(226, 196, 140),
	gold = Color3.fromRGB(255, 196, 92),
	amber = Color3.fromRGB(255, 170, 64),
	cyan = Color3.fromRGB(70, 226, 255),
	crystal = Color3.fromRGB(120, 210, 255),
	lilac = Color3.fromRGB(196, 140, 255),
	pink = Color3.fromRGB(255, 140, 210),
	roof = Color3.fromRGB(38, 92, 180),
	banner = Color3.fromRGB(40, 86, 170),
	cream = Color3.fromRGB(248, 238, 214),
	red = Color3.fromRGB(226, 60, 56),
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

local function neonRing(
	parent,
	center: Vector3,
	radius: number,
	thick: number,
	color: Color3,
	segments: number
)
	for i = 1, segments do
		local a0 = (i - 1) / segments * math.pi * 2
		local a1 = i / segments * math.pi * 2
		beam(
			"GlyphLine",
			parent,
			center + Vector3.new(math.cos(a0) * radius, 0, math.sin(a0) * radius),
			center + Vector3.new(math.cos(a1) * radius, 0, math.sin(a1) * radius),
			thick,
			color,
			Enum.Material.Neon,
			{ collide = false, shadow = false }
		)
	end
end

-- Clones ServerStorage.MapMeshes[name] at `cf` when the AI mesh exists, else runs `fallback`.
-- Templates may carry a "YawOffset" attribute (degrees) to fix the generator's facing.
local function placeMesh(
	name: string,
	parent: Instance,
	cf: CFrame,
	fallback: () -> (),
	scale: number?
)
	local lib = ServerStorage:FindFirstChild("MapMeshes")
	local template = lib and lib:FindFirstChild(name)
	if not template then
		fallback()
		return
	end
	local clone = template:Clone()
	if scale and clone:IsA("Model") then
		clone:ScaleTo(clone:GetScale() * scale)
	end
	local yaw = template:GetAttribute("YawOffset")
	local offset = CFrame.Angles(0, math.rad(if typeof(yaw) == "number" then yaw else 0), 0)
	if clone:IsA("Model") then
		local _, size = clone:GetBoundingBox()
		clone:PivotTo(cf * offset * CFrame.new(0, size.Y / 2, 0))
	elseif clone:IsA("BasePart") then
		clone.CFrame = cf * offset * CFrame.new(0, clone.Size.Y / 2, 0)
	end
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	if clone:IsA("BasePart") then
		clone.Anchored = true
	end
	clone.Parent = parent
end

-- Terrain -----------------------------------------------------------------------------

local function buildOcean()
	Terrain:Clear()
	-- Animated grass blades poke through the plaza paving and cost FPS on phones.
	Terrain.Decoration = false
	Terrain.WaterColor = Color3.fromRGB(10, 92, 160)
	Terrain.WaterTransparency = 0.55
	Terrain.WaterReflectance = 0.5
	Terrain.WaterWaveSize = 0.12
	Terrain.WaterWaveSpeed = 9
	Terrain:SetMaterialColor(Enum.Material.Rock, COLORS.rock)
	Terrain:SetMaterialColor(Enum.Material.Grass, COLORS.grass)
	Terrain:SetMaterialColor(Enum.Material.Sand, COLORS.sand)
	Terrain:SetMaterialColor(Enum.Material.Slate, COLORS.seabed)
	Terrain:SetMaterialColor(Enum.Material.Basalt, COLORS.rockDark)

	-- Tiles keep each fill small enough not to freeze Studio.
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

	-- Sand shelf around the island: shallow water reads turquoise, deep water reads navy.
	local up = CFrame.new(-20, 0, -4)
	Terrain:FillCylinder(up * CFrame.new(0, -12, 0), 4, 150, Enum.Material.Sand)
	Terrain:FillCylinder(up * CFrame.new(0, -10, 0), 4, 118, Enum.Material.Sand)
	Terrain:FillCylinder(up * CFrame.new(0, -7, 0), 4, 92, Enum.Material.Sand)
end

local ISLAND_CORE = {
	-- x, z, radius
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

-- Terrain voxels are 4 studs. A solid fill ending halfway through voxel [4, 8] draws its
-- surface at y = 8 (measured); thin fills round up to the whole voxel, so layers are kept
-- thick and end on the half-voxel line.
local function buildIsland()
	for _, c in ISLAND_CORE do
		Terrain:FillCylinder(CFrame.new(c[1], -10, c[2]), 20, c[3], Enum.Material.Rock)
	end
	for _, c in ISLAND_CORE do
		Terrain:FillCylinder(CFrame.new(c[1], 3, c[2]), 6, c[3] - 3, Enum.Material.Grass)
	end
	task.wait()

	-- Boulder rim along the shore: breaks the cylinder outline and gives the rocky edge.
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

	-- Workshop terrace and the hill behind it.
	Terrain:FillBlock(CFrame.new(-6, 4, -37), Vector3.new(46, 16, 30), Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-6, 13, -58), 17, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-30, 11, -54), 13, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(18, 10, -50), 11, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-6, 22, -62), 9, Enum.Material.Grass)
	Terrain:FillBall(Vector3.new(-28, 19, -56), 6, Enum.Material.Grass)

	-- Waterfall cliff behind the lagoon.
	Terrain:FillBall(Vector3.new(-50, 12, -18), 10, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-40, 10, -21), 8, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-58, 10, -16), 7, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-52, 20, -20), 5, Enum.Material.Grass)
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
	local function slab(name, size: Vector3, pos: Vector3)
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
	slab("PathToPier", Vector3.new(26, 1, 14), Vector3.new(12, PLAZA_Y, 8))
	slab("PathToLagoon", Vector3.new(14, 1, 14), Vector3.new(-28, PLAZA_Y, 2))
	slab("PathToStairs", Vector3.new(16, 1, 10), Vector3.new(-6, PLAZA_Y, 23))
	slab("PathToWorkshop", Vector3.new(18, 1, 10), Vector3.new(-6, PLAZA_Y, -16))

	-- Darker stones scattered on the paving so it doesn't read as one flat disc.
	for _ = 1, 26 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(3, 20)
		deco(
			"PavingStone",
			g,
			Vector3.new(rng:NextNumber(2, 4), 0.08, rng:NextNumber(2, 3.5)),
			CFrame.new(-6 + math.cos(a) * r, PLAZA_Y + 0.02, 4 + math.sin(a) * r)
				* CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
			COLORS.pavingDark,
			Enum.Material.Slate,
			{ shadow = false }
		)
	end

	-- Glowing crystal glyph inlaid in the paving.
	local glyph = Vector3.new(-2, PLAZA_Y + 0.05, -4)
	neonRing(g, glyph, 6, 0.18, COLORS.gold, 28)
	neonRing(g, glyph, 3.6, 0.14, COLORS.cyan, 20)
	for i = 0, 3 do
		local a = i * math.pi / 2
		local tip = glyph + Vector3.new(math.cos(a) * 5.4, 0, math.sin(a) * 5.4)
		beam(
			"GlyphStar",
			g,
			glyph,
			tip,
			0.22,
			COLORS.cyan,
			Enum.Material.Neon,
			{ collide = false, shadow = false }
		)
	end
	-- Thin gold inlays from the glyph to each destination, as in the reference paving.
	for _, target in
		{
			Vector3.new(-6, PLAZA_Y + 0.04, -12), -- workshop steps
			Vector3.new(16, PLAZA_Y + 0.04, 8), -- pier
			Vector3.new(-26, PLAZA_Y + 0.04, 2), -- lagoon
			Vector3.new(-6, PLAZA_Y + 0.04, 26), -- stairs
		}
	do
		local from = glyph + (target - glyph).Unit * 6.2
		beam(
			"GoldInlay",
			g,
			Vector3.new(from.X, PLAZA_Y + 0.04, from.Z),
			target,
			0.16,
			COLORS.gold,
			Enum.Material.Neon,
			{ collide = false, shadow = false }
		)
	end
	deco(
		"GlyphCore",
		g,
		Vector3.new(1.6, 0.1, 1.6),
		CFrame.new(glyph) * CFrame.Angles(0, math.rad(45), 0),
		COLORS.cyan,
		Enum.Material.Neon,
		{ shadow = false }
	)

	-- Spawn on flat paving between the stairs and the plaza, facing the workshop.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = CFrame.new(-6, PLAZA_Y + 0.1, 16) * CFrame.Angles(0, 0, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanTouch = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = g
end

local function buildCampfire()
	local g = group("Campfire")
	local c = Vector3.new(-18, PLAZA_Y, 9)
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		part(
			"FireStone",
			g,
			Vector3.new(1.6, 1, 1.4),
			CFrame.new(c + Vector3.new(math.cos(a) * 2.6, 0.4, math.sin(a) * 2.6))
				* CFrame.Angles(0, -a, 0),
			COLORS.rockDark,
			Enum.Material.Slate
		)
	end
	for i = 0, 2 do
		local a = i * math.pi / 3
		beam(
			"Log",
			g,
			c + Vector3.new(math.cos(a) * 1.6, 0.3, math.sin(a) * 1.6),
			c + Vector3.new(-math.cos(a) * 1.6, 0.5, -math.sin(a) * 1.6),
			0.6,
			COLORS.woodDark,
			Enum.Material.Wood,
			{ collide = false }
		)
	end
	local ember = deco(
		"Embers",
		g,
		Vector3.new(1.6, 0.4, 1.6),
		CFrame.new(c + Vector3.new(0, 0.5, 0)),
		COLORS.amber,
		Enum.Material.Neon
	)
	pointLight(ember, COLORS.amber, 2, 18)
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 7
	fire.Color = Color3.fromRGB(255, 170, 60)
	fire.SecondaryColor = Color3.fromRGB(255, 80, 30)
	fire.Parent = ember

	-- Three log benches around the fire, open toward the stairs.
	for _, a in { 200, 270, 340 } do
		local r = math.rad(a)
		local pos = c + Vector3.new(math.cos(r) * 6, 0, math.sin(r) * 6)
		local cf = CFrame.lookAt(pos, c) * CFrame.Angles(0, math.rad(90), 0)
		part(
			"BenchSeat",
			g,
			Vector3.new(6, 0.7, 1.8),
			cf * CFrame.new(0, 1.6, 0),
			COLORS.woodLight,
			Enum.Material.WoodPlanks
		)
		for _, dx in { -2.2, 2.2 } do
			part(
				"BenchLeg",
				g,
				Vector3.new(0.8, 1.3, 1.4),
				cf * CFrame.new(dx, 0.65, 0),
				COLORS.woodDark,
				Enum.Material.Wood
			)
		end
	end
end

-- Lanterns, signs ----------------------------------------------------------------------

local function lantern(parent: Instance, base: Vector3, height: number)
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
			height / 4.5
		)
		-- Light near the hanging lantern of the mesh (upper part of the post).
		local glow = deco(
			"LightSource",
			g,
			Vector3.new(0.2, 0.2, 0.2),
			CFrame.new(base + Vector3.new(0, height * 0.72, 0)),
			COLORS.amber,
			Enum.Material.Neon,
			{ transparency = 1, shadow = false }
		)
		pointLight(glow, COLORS.amber, 1.4, 16)
		return g
	end
	part(
		"Post",
		g,
		Vector3.new(0.7, height, 0.7),
		CFrame.new(base + Vector3.new(0, height / 2, 0)),
		COLORS.woodDark,
		Enum.Material.Wood
	)
	part(
		"Arm",
		g,
		Vector3.new(0.4, 0.4, 1.8),
		CFrame.new(base + Vector3.new(0, height - 0.3, 0.8)),
		COLORS.woodDark,
		Enum.Material.Wood,
		{ collide = false }
	)
	local top = base + Vector3.new(0, height - 1.4, 1.5)
	deco(
		"Cap",
		g,
		Vector3.new(1.3, 0.35, 1.3),
		CFrame.new(top + Vector3.new(0, 0.9, 0)),
		COLORS.woodDark,
		Enum.Material.Wood
	)
	local glass = deco(
		"Glow",
		g,
		Vector3.new(0.9, 1.3, 0.9),
		CFrame.new(top),
		COLORS.amber,
		Enum.Material.Neon,
		{ shadow = false }
	)
	deco(
		"Base",
		g,
		Vector3.new(1.1, 0.3, 1.1),
		CFrame.new(top - Vector3.new(0, 0.8, 0)),
		COLORS.woodDark,
		Enum.Material.Wood
	)
	pointLight(glass, COLORS.amber, 1.4, 16)
	g.Parent = parent
	return g
end

local function sign(parent: Instance, text: string, cf: CFrame, width: number, height: number)
	local g = Instance.new("Model")
	g.Name = "Sign_" .. text:gsub("%W", "")
	part(
		"Frame",
		g,
		Vector3.new(width + 0.8, height + 0.8, 0.5),
		cf,
		COLORS.woodDark,
		Enum.Material.Wood
	)
	local board =
		part("Board", g, Vector3.new(width, height, 0.6), cf, COLORS.wood, Enum.Material.WoodPlanks)
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
	local landingY = PLAZA_Y - steps * 0.8
	part(
		"Landing",
		g,
		Vector3.new(18, 4, 6),
		CFrame.new(-6, landingY - 2, 50),
		COLORS.pavingDark,
		Enum.Material.Cobblestone
	)
	-- Rocky flanks that step down with the stairs, like the cliff in the reference.
	for _, x in { -16.5, 4.5 } do
		for i = 0, 5 do
			local z = 28 + i * 4
			local y = PLAZA_Y - 4 - i * 1.6
			Terrain:FillBall(Vector3.new(x, y, z), rng:NextNumber(3.6, 4.4), Enum.Material.Rock)
		end
	end
	for _, x in { -14.5, 2.5 } do
		lantern(g, Vector3.new(x, PLAZA_Y, 25), 6)
		lantern(g, Vector3.new(x, landingY, 50), 5)
	end
end

-- Blossom tree ------------------------------------------------------------------------

-- AI meshes can't do a full canopy (they come back bare or boxy), so the tree is a
-- generated trunk crowned by cloned blossom clumps, hanging wisteria and lanterns.
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
	end, 0.6)

	local crown = base + Vector3.new(1, trunkHeight + 1, 0)
	local clumps = {
		{ 0, 3, 0, 1.3 },
		{ 6, 1, 2, 1.1 },
		{ -6, 1, -1, 1.15 },
		{ 2, 0, 7, 1 },
		{ -2, 0, -7, 1.05 },
		{ 9, -2, -4, 0.9 },
		{ -9, -2, 5, 0.9 },
		{ 4, 4, -4, 1 },
		{ -4, 4, 4, 1 },
		{ 10, -3, 5, 0.75 },
		{ -10, -3, -6, 0.8 },
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
			c[4] * 1.45
		)
	end

	-- Hanging wisteria strands and lanterns along the canopy rim.
	-- Each strand is a chain of shrinking blossom beads, so it reads as a flower cluster.
	for i = 1, 18 do
		local a = i / 18 * math.pi * 2
		local r = rng:NextNumber(7, 11)
		local top = crown + Vector3.new(math.cos(a) * r, -3, math.sin(a) * r)
		local beads = rng:NextInteger(3, 5)
		for b = 0, beads - 1 do
			local s = 1.1 - b * 0.18
			deco(
				"Wisteria",
				g,
				Vector3.new(s, s * 1.2, s),
				CFrame.new(top - Vector3.new(0, b * 0.9, 0)),
				if (i + b) % 2 == 0 then COLORS.lilac else Color3.fromRGB(170, 120, 240),
				Enum.Material.SmoothPlastic,
				{ shape = Enum.PartType.Ball, shadow = false }
			)
		end
	end
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2 + 0.4
		local hook = crown + Vector3.new(math.cos(a) * 8, -2, math.sin(a) * 8)
		deco(
			"LanternString",
			g,
			Vector3.new(0.1, 2, 0.1),
			CFrame.new(hook - Vector3.new(0, 1, 0)),
			COLORS.rope,
			Enum.Material.Fabric,
			{ shadow = false }
		)
		local glow = deco(
			"HangingLantern",
			g,
			Vector3.new(0.9, 1.2, 0.9),
			CFrame.new(hook - Vector3.new(0, 2.6, 0)),
			COLORS.amber,
			Enum.Material.Neon,
			{ shadow = false }
		)
		pointLight(glow, COLORS.amber, 1, 12)
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

	-- Glow sheet under the surface: terrain water alone reads grey, the reference lagoon
	-- is bright turquoise.
	disc(
		"LagoonGlow",
		g,
		c + Vector3.new(0, 8.08, 0),
		14.8,
		0.1,
		Color3.fromRGB(60, 226, 220),
		Enum.Material.Glass,
		{ collide = false, transparency = 0.35, reflectance = 0.15, shadow = false }
	)
	disc(
		"LagoonBed",
		g,
		c + Vector3.new(0, 6, 0),
		15,
		0.2,
		Color3.fromRGB(40, 200, 210),
		Enum.Material.SmoothPlastic,
		{ collide = false, shadow = false }
	)

	-- Lily pads and lotus flowers.
	for i = 1, 9 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(4, 12)
		local p = c + Vector3.new(math.cos(a) * r, 8.16, math.sin(a) * r)
		disc(
			"LilyPad",
			g,
			p,
			rng:NextNumber(1, 1.6),
			0.1,
			Color3.fromRGB(60, 168, 86),
			Enum.Material.Grass,
			{ collide = false, shadow = false }
		)
		if i % 2 == 0 then
			deco(
				"Lotus",
				g,
				Vector3.new(0.9, 0.7, 0.9),
				CFrame.new(p + Vector3.new(0, 0.35, 0)),
				COLORS.pink,
				Enum.Material.Neon,
				{ shape = Enum.PartType.Ball, shadow = false }
			)
		end
	end

	-- Fish silhouettes swimming in the shallows.
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		-- Just under the glow sheet so the silhouettes stay visible through it.
		local p = c + Vector3.new(math.cos(a) * 8, 7.85, math.sin(a) * 6)
		deco(
			"FishShadow",
			g,
			Vector3.new(0.8, 0.3, 2.6),
			CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))),
			Color3.fromRGB(14, 60, 96),
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Ball, shadow = false }
		)
	end

	-- Wooden fence with rope on the plaza side.
	local fenceAngles = { -50, -25, 0, 25, 50, 75 }
	local prev: Vector3? = nil
	for _, deg in fenceAngles do
		local a = math.rad(deg)
		local base = c + Vector3.new(math.cos(a) * 18.5, PLAZA_Y - 0.3, math.sin(a) * 18.5)
		part(
			"FencePost",
			g,
			Vector3.new(0.9, 3.6, 0.9),
			CFrame.new(base + Vector3.new(0, 1.8, 0)),
			COLORS.wood,
			Enum.Material.Wood
		)
		deco(
			"FenceCap",
			g,
			Vector3.new(1.1, 0.4, 1.1),
			CFrame.new(base + Vector3.new(0, 3.8, 0)),
			COLORS.gold,
			Enum.Material.Metal
		)
		if prev then
			local top0 = prev + Vector3.new(0, 3.2, 0)
			local top1 = base + Vector3.new(0, 3.2, 0)
			local mid = (top0 + top1) / 2 - Vector3.new(0, 0.6, 0)
			beam(
				"Rope",
				g,
				top0,
				mid,
				0.25,
				COLORS.rope,
				Enum.Material.Fabric,
				{ collide = false, shadow = false }
			)
			beam(
				"Rope",
				g,
				mid,
				top1,
				0.25,
				COLORS.rope,
				Enum.Material.Fabric,
				{ collide = false, shadow = false }
			)
		end
		prev = base
	end

	-- Waterfall falling from the cliff into the back of the lagoon.
	-- Two segments follow the measured cliff face (rock at z -12.7 @ y22, -8.6 @ y14), so
	-- the sheet stays in front of the terrain instead of disappearing into it.
	local fallPath = {
		Vector3.new(-48, 21.5, -11.4),
		Vector3.new(-48, 15, -7.6),
		Vector3.new(-48, 8, -6.6),
	}
	for seg = 1, #fallPath - 1 do
		local a, b = fallPath[seg], fallPath[seg + 1]
		for i = -2, 2 do
			local off = Vector3.new(i * 1.2, 0, 0)
			deco(
				"Waterfall",
				g,
				Vector3.new(1.4, 0.4, (b - a).Magnitude + 0.6),
				CFrame.lookAt((a + b) / 2 + off, b + off),
				if i % 2 == 0 then COLORS.cyan else COLORS.white,
				Enum.Material.Glass,
				{ transparency = if i % 2 == 0 then 0.25 else 0.45, shadow = false }
			)
		end
	end
	do
		local p = deco(
			"WaterfallMistSource",
			g,
			Vector3.new(3, 0.2, 1),
			CFrame.new(fallPath[#fallPath]),
			COLORS.white,
			Enum.Material.SmoothPlastic,
			{ transparency = 1, shadow = false }
		)
		do
			local mist = Instance.new("ParticleEmitter")
			mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
			mist.Color = ColorSequence.new(COLORS.white)
			mist.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 2),
				NumberSequenceKeypoint.new(1, 5),
			})
			mist.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.6),
				NumberSequenceKeypoint.new(1, 1),
			})
			mist.Lifetime = NumberRange.new(1.2, 2)
			mist.Rate = 8
			mist.Speed = NumberRange.new(1, 3)
			mist.EmissionDirection = Enum.NormalId.Bottom
			mist.Parent = p
		end
	end
	disc(
		"Foam",
		g,
		Vector3.new(-48, 8.2, -6),
		4,
		0.15,
		COLORS.white,
		Enum.Material.Neon,
		{ collide = false, transparency = 0.4, shadow = false }
	)

	-- Training spot: interaction will be added later; for now a marked platform.
	local spot = Vector3.new(-30, PLAZA_Y, -6)
	neonRing(g, spot + Vector3.new(0, 0.06, 0), 3, 0.14, COLORS.lilac, 18)

	sign(
		g,
		"TRAINING LAGOON\n(PRACTICE)",
		CFrame.new(-31, PLAZA_Y + 4.2, 14) * CFrame.Angles(0, math.rad(30), 0),
		7,
		3.4
	)
	for _, dx in { -3.2, 3.2 } do
		part(
			"SignPost",
			g,
			Vector3.new(0.8, 6, 0.8),
			CFrame.new(-31, PLAZA_Y + 3, 14)
				* CFrame.Angles(0, math.rad(30), 0)
				* CFrame.new(dx, 0, 0.5),
			COLORS.woodDark,
			Enum.Material.Wood
		)
	end
	lantern(g, Vector3.new(-26, PLAZA_Y, 14), 5.5)

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
	for i = 1, 5 do
		local top = PLAZA_Y + i * 0.8
		local h = top - 4
		part(
			"WorkshopStep",
			g,
			Vector3.new(16, h, 1.8),
			CFrame.new(-6, top - h / 2, -13.6 - (i - 1) * 1.8),
			COLORS.paving,
			Enum.Material.Cobblestone
		)
	end
	for _, x in { -15, 3 } do
		lantern(g, Vector3.new(x, TERRACE_Y, front + 1), 6)
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

	-- Crystal pedestal at the open front: the upgrade station.
	local pedestal = Vector3.new(-6, TERRACE_Y, -26)
	part(
		"Pedestal",
		g,
		Vector3.new(4, 2, 4),
		CFrame.new(pedestal + Vector3.new(0, 1, 0)),
		COLORS.woodDark,
		Enum.Material.Wood
	)
	neonRing(g, pedestal + Vector3.new(0, 2.05, 0), 2.4, 0.14, COLORS.gold, 18)
	local gem = deco(
		"UpgradeCrystalLight",
		g,
		Vector3.new(0.2, 0.2, 0.2),
		CFrame.new(pedestal + Vector3.new(0, 4, 0)),
		COLORS.cyan,
		Enum.Material.Neon,
		{ transparency = 1, shadow = false }
	)
	pointLight(gem, COLORS.cyan, 2.4, 20)
	placeMesh("CrystalCluster", g, CFrame.new(pedestal + Vector3.new(0, 2, 0)), function()
		deco(
			"UpgradeCrystal",
			g,
			Vector3.new(1.6, 3.4, 1.6),
			CFrame.new(pedestal + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.rad(45), 0),
			COLORS.cyan,
			Enum.Material.Neon,
			{ shadow = false }
		)
	end, 0.4)

	-- The mesh has an empty board under the roof; the sign goes right on its face.
	local shop = g:FindFirstChild("Workshop")
	local emblem = Vector3.new(-6, TERRACE_Y + 25, -40)
	if shop and shop:IsA("Model") then
		local cf, size = shop:GetBoundingBox()
		local face = cf.Position + Vector3.new(0, size.Y * 0.12, size.Z / 2 + 0.1)
		sign(g, "UPGRADE WORKSHOP", CFrame.new(face), size.X * 0.42, size.Y * 0.14)
		emblem = cf.Position + Vector3.new(0, size.Y / 2 + 4, size.Z * 0.1)
	else
		sign(g, "UPGRADE WORKSHOP", CFrame.new(-6, TERRACE_Y + 12.5, front - 1.5), 12, 3.6)
	end

	-- Golden magic emblem floating above the roof, as in the reference.
	local e = Instance.new("Model")
	e.Name = "RoofEmblem"
	for i = 1, 24 do
		local a0 = (i - 1) / 24 * math.pi * 2
		local a1 = i / 24 * math.pi * 2
		beam(
			"EmblemRing",
			e,
			emblem + Vector3.new(math.cos(a0) * 4.5, math.sin(a0) * 2.2, 0),
			emblem + Vector3.new(math.cos(a1) * 4.5, math.sin(a1) * 2.2, 0),
			0.2,
			COLORS.gold,
			Enum.Material.Neon,
			{ collide = false, shadow = false }
		)
	end
	for i = 0, 3 do
		local a = i * math.pi / 2
		beam(
			"EmblemStar",
			e,
			emblem,
			emblem + Vector3.new(math.cos(a) * 3.6, math.sin(a) * 3.6, 0),
			0.35,
			COLORS.gold,
			Enum.Material.Neon,
			{ collide = false, shadow = false }
		)
	end
	e.Parent = g
end

-- Fishing pier -------------------------------------------------------------------------

local function buildPier()
	local g = group("FishingPier")
	local x0, x1, zc, w = 18, 84, 8, 14

	for x = x0, x1, 2.4 do
		part(
			"Plank",
			g,
			Vector3.new(2.25, 0.5, w),
			CFrame.new(x, PIER_Y - 0.25, zc),
			if math.floor(x) % 3 == 0 then COLORS.woodLight else COLORS.wood,
			Enum.Material.WoodPlanks
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

	local railTop: { [number]: Vector3? } = {}
	local postIndex = 0
	for x = x0 + 4, x1, 8 do
		postIndex += 1
		for side, dz in { -w / 2 + 0.4, w / 2 - 0.4 } do
			part(
				"Piling",
				g,
				Vector3.new(1.4, 22, 1.4),
				CFrame.new(x, PIER_Y - 11, zc + dz),
				COLORS.woodDark,
				Enum.Material.Wood
			)
			local top = Vector3.new(x, PIER_Y + 3.4, zc + dz)
			deco(
				"PostCap",
				g,
				Vector3.new(1.6, 0.5, 1.6),
				CFrame.new(top + Vector3.new(0, 0.25, 0)),
				COLORS.gold,
				Enum.Material.Metal
			)
			local prev = railTop[side]
			if prev then
				local mid = (prev + top) / 2 - Vector3.new(0, 0.8, 0)
				beam(
					"Rope",
					g,
					prev,
					mid,
					0.28,
					COLORS.rope,
					Enum.Material.Fabric,
					{ collide = false, shadow = false }
				)
				beam(
					"Rope",
					g,
					mid,
					top,
					0.28,
					COLORS.rope,
					Enum.Material.Fabric,
					{ collide = false, shadow = false }
				)
			end
			railTop[side] = top
			if postIndex % 3 == 2 and side == 1 then
				lantern(g, Vector3.new(x, PIER_Y, zc + dz), 5.5)
			end
		end
	end
	-- Invisible rails keep players on the deck without blocking the cast.
	for _, dz in { -w / 2, w / 2 } do
		local rail = part(
			"RailCollider",
			g,
			Vector3.new(x1 - x0, 4, 0.4),
			CFrame.new((x0 + x1) / 2 + 2, PIER_Y + 2, zc + dz),
			COLORS.wood,
			Enum.Material.Wood,
			{ transparency = 1, shadow = false }
		)
		rail.CanQuery = false
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

	-- Entrance arch with the FISHING PIER board and a blue banner.
	local archX = x0 + 1
	for _, dz in { -w / 2 + 0.4, w / 2 - 0.4 } do
		part(
			"ArchPost",
			g,
			Vector3.new(1.6, 13, 1.6),
			CFrame.new(archX, PIER_Y + 6.5, zc + dz),
			COLORS.woodDark,
			Enum.Material.Wood
		)
		local glow = deco(
			"ArchLantern",
			g,
			Vector3.new(0.9, 1.3, 0.9),
			CFrame.new(archX - 1.2, PIER_Y + 8, zc + dz),
			COLORS.amber,
			Enum.Material.Neon,
			{ shadow = false }
		)
		pointLight(glow, COLORS.amber, 1.4, 16)
	end
	part(
		"ArchBeam",
		g,
		Vector3.new(1.4, 1.2, w + 2),
		CFrame.new(archX, PIER_Y + 12.8, zc),
		COLORS.woodDark,
		Enum.Material.Wood
	)
	sign(
		g,
		"FISHING PIER",
		CFrame.new(archX, PIER_Y + 10.4, zc) * CFrame.Angles(0, math.rad(-90), 0),
		10,
		3
	)
	local banner = deco(
		"Banner",
		g,
		Vector3.new(0.2, 5, 2.6),
		CFrame.new(archX + 1, PIER_Y + 8.5, zc - w / 2 + 0.4),
		COLORS.banner,
		Enum.Material.Fabric
	)
	deco(
		"BannerEmblem",
		g,
		Vector3.new(0.25, 1.4, 1.4),
		banner.CFrame * CFrame.Angles(math.rad(45), 0, 0),
		COLORS.cyan,
		Enum.Material.Neon
	)

	-- Life rings, crates, fishing spot, buoys.
	for _, x in { 38, 70 } do
		local ring = Instance.new("Model")
		ring.Name = "LifeRing"
		for i = 1, 12 do
			local a0 = (i - 1) / 12 * math.pi * 2
			local a1 = i / 12 * math.pi * 2
			local center = Vector3.new(x, PIER_Y + 1, zc + w / 2 + 0.7)
			beam(
				"RingSegment",
				ring,
				center + Vector3.new(math.cos(a0) * 1.4, math.sin(a0) * 1.4, 0),
				center + Vector3.new(math.cos(a1) * 1.4, math.sin(a1) * 1.4, 0),
				0.6,
				if i % 3 == 0 then COLORS.red else COLORS.white,
				Enum.Material.SmoothPlastic,
				{ collide = false }
			)
		end
		ring.Parent = g
	end
	for _, spot in
		{
			{ pos = Vector3.new(15, PLAZA_Y, 17.5), yaw = 20 },
			{ pos = Vector3.new(15, PLAZA_Y, -2), yaw = 160 },
		}
	do
		local p, yaw = spot.pos, spot.yaw
		placeMesh("CrateStack", g, CFrame.new(p) * CFrame.Angles(0, math.rad(yaw), 0), function()
			for i = 0, 2 do
				part(
					"Crate",
					g,
					Vector3.new(2.4, 2.4, 2.4),
					CFrame.new(p + Vector3.new(i % 2 * 2.5, 1.2 + math.floor(i / 2) * 2.4, 0))
						* CFrame.Angles(0, math.rad(i * 17), 0),
					COLORS.woodLight,
					Enum.Material.WoodPlanks
				)
			end
		end, 1.1)
	end
	neonRing(g, Vector3.new(x1 - 3, PIER_Y + 0.05, zc), 2.6, 0.12, COLORS.cyan, 16)

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

	for _, p in { Vector3.new(58, 0, 26), Vector3.new(96, 0, 18), Vector3.new(76, 0, -12) } do
		local b = Instance.new("Model")
		b.Name = "Buoy"
		part(
			"BuoyBase",
			b,
			Vector3.new(2.6, 1.6, 2.6),
			CFrame.new(p + Vector3.new(0, 0.3, 0)),
			COLORS.white,
			Enum.Material.SmoothPlastic,
			{ shape = Enum.PartType.Cylinder }
		)
		for i = 0, 2 do
			part(
				"BuoyBand",
				b,
				Vector3.new(2.2 - i * 0.6, 0.8, 2.2 - i * 0.6),
				CFrame.new(p + Vector3.new(0, 1.4 + i * 0.8, 0)),
				if i % 2 == 0 then COLORS.red else COLORS.white,
				Enum.Material.SmoothPlastic
			)
		end
		b.Parent = g
	end
end

-- Vegetation and crystals ----------------------------------------------------------------

local function crystalCluster(parent: Instance, base: Vector3, scale: number)
	local glow = deco(
		"CrystalGlow",
		parent,
		Vector3.new(0.2, 0.2, 0.2),
		CFrame.new(base + Vector3.new(0, scale * 0.6, 0)),
		COLORS.cyan,
		Enum.Material.Neon,
		{ transparency = 1, shadow = false }
	)
	pointLight(glow, COLORS.cyan, 1.6, scale * 2.2)
	placeMesh(
		"CrystalCluster",
		parent,
		CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
		function()
			for i = 1, 4 do
				local a = i * 1.7
				local h = scale * rng:NextNumber(0.5, 1)
				local p = base
					+ Vector3.new(math.cos(a) * scale * 0.3, h / 2, math.sin(a) * scale * 0.3)
				local c = deco(
					"Crystal",
					parent,
					Vector3.new(h * 0.32, h, h * 0.32),
					CFrame.new(p)
						* CFrame.Angles(
							math.rad(rng:NextNumber(-18, 18)),
							a,
							math.rad(rng:NextNumber(-18, 18))
						),
					if i == 3 then COLORS.lilac else COLORS.crystal,
					Enum.Material.Glass,
					{ transparency = 0.15, shadow = false }
				)
				if i == 1 then
					pointLight(c, COLORS.cyan, 1, 12)
				end
			end
		end,
		scale / 12 * 2
	)
end

local function palm(parent: Instance, base: Vector3, s: number)
	placeMesh(
		"PalmTree",
		parent,
		CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
		function()
			local top = base + Vector3.new(s * 1.5, s * 9, 0)
			beam("PalmTrunk", parent, base, top, s * 0.9, COLORS.wood, Enum.Material.Wood)
			for i = 1, 7 do
				local a = i / 7 * math.pi * 2
				beam(
					"PalmLeaf",
					parent,
					top,
					top + Vector3.new(math.cos(a) * s * 5, -s * 1.6, math.sin(a) * s * 5),
					s * 0.5,
					Color3.fromRGB(56, 170, 80),
					Enum.Material.Grass,
					{ collide = false }
				)
			end
		end,
		s * 0.85
	)
end

local function flowerBush(parent: Instance, base: Vector3, s: number)
	placeMesh(
		"FlowerBush",
		parent,
		CFrame.new(base) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
		function()
			for i = 1, 4 do
				local a = i * 1.6
				deco(
					"Leaf",
					parent,
					Vector3.new(s * 1.3, s * 0.8, s * 1.2),
					CFrame.new(
						base + Vector3.new(math.cos(a) * s * 0.4, s * 0.3, math.sin(a) * s * 0.4)
					),
					Color3.fromRGB(60, 160, 80),
					Enum.Material.Grass,
					{ shape = Enum.PartType.Ball, shadow = false }
				)
			end
			local palette = {
				COLORS.pink,
				COLORS.lilac,
				Color3.fromRGB(110, 190, 255),
				Color3.fromRGB(255, 220, 110),
			}
			for i = 1, 5 do
				local a = i * 1.3
				deco(
					"Flower",
					parent,
					Vector3.new(0.6, 0.5, 0.6),
					CFrame.new(
						base + Vector3.new(math.cos(a) * s * 0.5, s * 0.75, math.sin(a) * s * 0.5)
					),
					palette[1 + i % #palette],
					Enum.Material.SmoothPlastic,
					{ shape = Enum.PartType.Ball, shadow = false }
				)
			end
		end,
		s * 0.7
	)
end

local function buildDecor()
	local g = group("Decor")
	for _, c in
		{
			{ -36, 9, -46, 9 },
			{ -24, 20, -58, 12 },
			{ 8, 18, -60, 10 },
			{ 22, 10, -40, 7 },
			{ -70, 4, 14, 8 },
			{ -54, 4, 34, 9 },
			{ -66, 6, -26, 7 },
			{ 10, 3, 36, 8 },
			{ -19, 4, 36, 7 },
			{ 7, 3, 42, 6 },
			{ 22, 4, 24, 7 },
			{ 72, -2, 22, 7 },
			{ 30, -2, -18, 6 },
		}
	do
		crystalCluster(g, Vector3.new(c[1], c[2], c[3]), c[4])
	end

	palm(g, Vector3.new(-26, TERRACE_Y - 2, -46), 1.4)
	palm(g, Vector3.new(16, TERRACE_Y - 3, -40), 1.35)
	palm(g, Vector3.new(-66, PLAZA_Y - 1, 20), 1.1)

	for _, b in
		{
			{ -40, PLAZA_Y - 0.5, 22, 2.4 },
			{ -30, PLAZA_Y - 0.5, 28, 2.2 },
			{ -20, PLAZA_Y - 0.5, 30, 2.6 },
			{ 6, PLAZA_Y - 0.5, 28, 2.6 },
			{ 16, PLAZA_Y - 0.5, 22, 2.2 },
			{ 18, PLAZA_Y - 0.5, -6, 2.4 },
			{ -24, PLAZA_Y - 0.5, -14, 2.2 },
			{ 8, PLAZA_Y - 0.5, -12, 2 },
			{ -22, TERRACE_Y, -24, 2 },
			{ 10, TERRACE_Y, -24, 2 },
			{ -62, PLAZA_Y - 0.5, 4, 2.4 },
			{ -60, PLAZA_Y - 0.5, 20, 2.2 },
			{ -14, 20, -52, 2.6 },
		}
	do
		flowerBush(g, Vector3.new(b[1], b[2], b[3]), b[4])
	end

	-- Plaza lanterns.
	for _, p in
		{
			Vector3.new(-28, PLAZA_Y, -10),
			Vector3.new(14, PLAZA_Y, -6),
			Vector3.new(12, PLAZA_Y, 20),
			Vector3.new(-26, PLAZA_Y, 20),
		}
	do
		lantern(g, p, 6)
	end

	-- Bunting between the workshop and the trees, like the reference.
	local function bunting(a: Vector3, b: Vector3, count: number)
		beam(
			"BuntingLine",
			g,
			a,
			b,
			0.12,
			COLORS.rope,
			Enum.Material.Fabric,
			{ collide = false, shadow = false }
		)
		local palette = { COLORS.pink, COLORS.cyan, Color3.fromRGB(255, 220, 110), COLORS.lilac }
		for i = 1, count do
			local t = i / (count + 1)
			local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * 1.2 + 0.9, 0)
			deco(
				"Flag",
				g,
				Vector3.new(0.1, 1.6, 1.4),
				CFrame.lookAt(p, p + (b - a).Unit:Cross(Vector3.yAxis))
					* CFrame.Angles(0, math.rad(90), math.rad(180)),
				palette[1 + i % #palette],
				Enum.Material.Fabric,
				{ wedge = true, shadow = false }
			)
		end
	end
	bunting(Vector3.new(-24, TERRACE_Y + 12, -24), Vector3.new(-36, TERRACE_Y + 8, -16), 6)
	bunting(Vector3.new(12, TERRACE_Y + 12, -24), Vector3.new(24, TERRACE_Y + 6, -14), 6)
end

-- Horizon and lighting ------------------------------------------------------------------

local function buildHorizon()
	local g = group("Horizon")
	-- Far islets: silhouettes in the haze, not playable.
	for _, p in
		{ Vector3.new(-420, 0, -520), Vector3.new(-160, 0, -700), Vector3.new(380, 0, -560) }
	do
		Terrain:FillBall(p + Vector3.new(0, -6, 0), 26, Enum.Material.Rock)
		Terrain:FillBall(p + Vector3.new(14, 4, 6), 14, Enum.Material.Rock)
	end
	-- Mystic citadel with a halo ring on the horizon (scenery only).
	local c = Vector3.new(560, 0, -820)
	Terrain:FillBall(c + Vector3.new(0, -10, 0), 40, Enum.Material.Rock)
	part(
		"CitadelSpire",
		g,
		Vector3.new(14, 70, 14),
		CFrame.new(c + Vector3.new(0, 35, 0)),
		COLORS.rock,
		Enum.Material.Slate,
		{ shadow = false }
	)
	part(
		"CitadelTower",
		g,
		Vector3.new(9, 44, 9),
		CFrame.new(c + Vector3.new(-18, 22, 6)),
		COLORS.rock,
		Enum.Material.Slate,
		{ shadow = false }
	)
	part(
		"CitadelTower",
		g,
		Vector3.new(9, 52, 9),
		CFrame.new(c + Vector3.new(16, 26, -4)),
		COLORS.rock,
		Enum.Material.Slate,
		{ shadow = false }
	)
	for i = 1, 32 do
		local a0 = (i - 1) / 32 * math.pi * 2
		local a1 = i / 32 * math.pi * 2
		local h = c + Vector3.new(0, 90, 0)
		beam(
			"Halo",
			g,
			h + Vector3.new(math.cos(a0) * 46, 0, math.sin(a0) * 46),
			h + Vector3.new(math.cos(a1) * 46, 0, math.sin(a1) * 46),
			1.4,
			COLORS.white,
			Enum.Material.Neon,
			{ collide = false, shadow = false }
		)
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
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.8
	Lighting.Ambient = Color3.fromRGB(110, 120, 150)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 170, 200)
	Lighting.ExposureCompensation = -0.1

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.36
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(196, 226, 255)
	atmosphere.Decay = Color3.fromRGB(96, 150, 210)
	atmosphere.Glare = 0.25
	atmosphere.Haze = 1.4
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.7
	bloom.Size = 26
	bloom.Threshold = 1.1
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

	-- The ocean ends at OCEAN_SIZE / 2; a capped zoom keeps the edge inside the haze.
	local starterPlayer = game:GetService("StarterPlayer")
	starterPlayer.CameraMaxZoomDistance = 90
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
buildLighting()

root:SetAttribute("GeneratorVersion", 2)
print(`[IslandGenerator] built {#root:GetDescendants()} instances`)

return true
