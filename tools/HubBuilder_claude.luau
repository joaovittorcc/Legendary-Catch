--!strict
-- HubBuilder V2 (Claude version): builds the whole "Legendary Catch" hub island by code.
-- Usage (Studio command bar or a dev script):
--   local m = game.ServerStorage.DevTools.HubBuilder:Clone()
--   local B = require(m); B.build(); print(table.concat(B.selfTest(), "\n"))
-- All positions below are written relative to the origin, using the server contract
-- coordinates as if the origin were (0,0,0).

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Builder = {}

---------------------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------------------

local SEED = 41873
local NOISE_Z = 17.37 -- third noise coordinate (fixed seed for math.noise)
local DEFAULT_ORIGIN = Vector3.new(0, 0, 700)
local MODEL_NAME = "HubNew"

local PLAZA_Y = 10.3
local TERRACE_Y = 14.3
local PIER_Y = 10.1
local SANCT_Y = 20.3
local WHARF_Y = 8.8 -- expedition wharf sits a bit lower than the plaza (ref-3)
-- Terrain renders ~2 studs above the written heightfield, so everything under a
-- floor is kept at least TERRAIN_MARGIN below it.
local TERRAIN_MARGIN = 4.3
-- Measured in Studio (V1 selfTest): the visible terrain surface sits ~2 studs above
-- the written height. Props placed on terrain use this offset.
local TERRAIN_RENDER_OFFSET = 2
local LAGOON_WATER_Y = 8
local FRONT_STAIR_RISE = 0.45 -- 18 steps: plaza 10.3 -> landing 2.2 (just above the visible sea)
local SEA_Y = 0

-- Terrain box (relative to origin, aligned to the 4-stud voxel grid).
local TERRAIN_MIN = Vector3.new(-104, -20, -92)
local TERRAIN_MAX = Vector3.new(44, 60, 80)
local VOXEL = 4

-- Key layout anchors (relative).
local LAGOON_CX, LAGOON_CZ, LAGOON_R = -44, 2, 15
local SANCT_CX, SANCT_CZ, SANCT_R = -68, -30, 18
local SPAWN_POS = Vector3.new(-6, 10.4, 11.5)
local FIRE_POS = Vector3.new(-16, PLAZA_Y, 11)
local PIER_TIP = Vector3.new(81, PIER_Y, 8)
local LAGOON_PORTAL_POS = Vector3.new(-45.2, PLAZA_Y, -4.2)

local PALETTE = {
	-- Warm rosy/lilac stone (never white: big surfaces blow out under the sun).
	stone = Color3.fromRGB(200, 178, 176),
	stoneWarm = Color3.fromRGB(212, 190, 184),
	stoneLight = Color3.fromRGB(220, 200, 192),
	stoneDark = Color3.fromRGB(118, 108, 124),
	stoneMid = Color3.fromRGB(168, 150, 158),
	stoneJoint = Color3.fromRGB(122, 104, 112),
	stoneBlue = Color3.fromRGB(124, 132, 164),
	stoneGray = Color3.fromRGB(150, 152, 166),
	stoneGrayDark = Color3.fromRGB(104, 106, 124),
	slateInlay = Color3.fromRGB(62, 66, 96),
	wood = Color3.fromRGB(176, 112, 62),
	woodLight = Color3.fromRGB(206, 142, 84),
	woodDark = Color3.fromRGB(112, 70, 40),
	woodWarm = Color3.fromRGB(196, 124, 66),
	rope = Color3.fromRGB(214, 180, 120),
	roofBlue = Color3.fromRGB(64, 106, 214),
	roofBlueLight = Color3.fromRGB(96, 140, 236),
	roofBlueDark = Color3.fromRGB(46, 78, 170),
	signBg = Color3.fromRGB(36, 44, 68),
	signWood = Color3.fromRGB(120, 76, 44),
	signText = Color3.fromRGB(255, 246, 228),
	gold = Color3.fromRGB(246, 196, 72),
	goldLight = Color3.fromRGB(255, 226, 120),
	amber = Color3.fromRGB(255, 176, 64),
	flame = Color3.fromRGB(255, 132, 36),
	flameCore = Color3.fromRGB(255, 220, 90),
	cyan = Color3.fromRGB(80, 226, 255),
	cyanDeep = Color3.fromRGB(40, 170, 230),
	crystalCyan = Color3.fromRGB(140, 236, 255),
	crystalPink = Color3.fromRGB(255, 160, 220),
	crystalLilac = Color3.fromRGB(196, 160, 255),
	crystalGold = Color3.fromRGB(255, 214, 120),
	pink = Color3.fromRGB(255, 132, 186),
	pinkLight = Color3.fromRGB(255, 186, 214),
	coral = Color3.fromRGB(255, 140, 120),
	coralLight = Color3.fromRGB(255, 186, 160),
	lilac = Color3.fromRGB(168, 120, 255),
	violet = Color3.fromRGB(110, 70, 220),
	violetDark = Color3.fromRGB(62, 40, 140),
	navy = Color3.fromRGB(34, 40, 96),
	leaf = Color3.fromRGB(96, 196, 84),
	leafLight = Color3.fromRGB(140, 222, 96),
	leafDark = Color3.fromRGB(56, 150, 76),
	fern = Color3.fromRGB(70, 178, 110),
	teal = Color3.fromRGB(64, 190, 170),
	bark = Color3.fromRGB(150, 104, 70),
	barkDark = Color3.fromRGB(110, 76, 54),
	water = Color3.fromRGB(110, 220, 240),
	waterDeep = Color3.fromRGB(60, 170, 220),
	foam = Color3.fromRGB(240, 252, 255),
	white = Color3.fromRGB(250, 250, 250),
	red = Color3.fromRGB(236, 74, 74),
	metal = Color3.fromRGB(80, 86, 104),
	glass = Color3.fromRGB(200, 240, 255),
	board = Color3.fromRGB(22, 26, 44),
	lily = Color3.fromRGB(92, 190, 96),
	sandPart = Color3.fromRGB(226, 204, 170),
	peach = Color3.fromRGB(255, 178, 152),
	peachLight = Color3.fromRGB(255, 206, 182),
	coralDeep = Color3.fromRGB(232, 108, 112),
	abyssBlue = Color3.fromRGB(70, 96, 226),
	abyssBlueLight = Color3.fromRGB(124, 152, 255),
	hexPink = Color3.fromRGB(255, 120, 206),
	leafMid = Color3.fromRGB(118, 208, 92),
}

local FLAG_COLORS = {
	Color3.fromRGB(255, 92, 92),
	Color3.fromRGB(255, 196, 64),
	Color3.fromRGB(96, 210, 110),
	Color3.fromRGB(80, 190, 255),
	Color3.fromRGB(196, 120, 255),
	Color3.fromRGB(255, 140, 200),
}

local TERRAIN_COLORS = {
	rock = Color3.fromRGB(112, 118, 148),
	basalt = Color3.fromRGB(78, 84, 116),
	grass = Color3.fromRGB(74, 164, 92),
	sand = Color3.fromRGB(222, 202, 164),
	slate = Color3.fromRGB(12, 40, 84),
}

local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

---------------------------------------------------------------------------------------
-- Build state (reset on every build)
---------------------------------------------------------------------------------------

local O: Vector3 = DEFAULT_ORIGIN
local rng: Random = Random.new(SEED)

local stats = { parts = 0, lights = 0, emitters = 0 }

---------------------------------------------------------------------------------------
-- Math helpers
---------------------------------------------------------------------------------------

local function clamp(v: number, a: number, b: number): number
	if v < a then
		return a
	elseif v > b then
		return b
	end
	return v
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function smoothstep(e0: number, e1: number, x: number): number
	local t = clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

local function ell(x: number, z: number, cx: number, cz: number, rx: number, rz: number): number
	local dx = (x - cx) / rx
	local dz = (z - cz) / rz
	return math.sqrt(dx * dx + dz * dz)
end

local function dist2(x: number, z: number, cx: number, cz: number): number
	local dx = x - cx
	local dz = z - cz
	return math.sqrt(dx * dx + dz * dz)
end

local function inRect(x: number, z: number, x0: number, x1: number, z0: number, z1: number): boolean
	return x >= x0 and x <= x1 and z >= z0 and z <= z1
end

local function noise2(x: number, z: number, freq: number, salt: number): number
	return math.noise(x * freq + salt * 13.1, z * freq - salt * 7.7, NOISE_Z)
end

local function rnd(a: number, b: number): number
	return rng:NextNumber(a, b)
end

local function rndInt(a: number, b: number): number
	return rng:NextInteger(a, b)
end

local function vary(c: Color3, amount: number): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(
		h,
		clamp(s + rnd(-amount, amount) * 0.5, 0, 1),
		clamp(v + rnd(-amount, amount), 0, 1)
	)
end

-- Relative position helpers.
local function V(x: number, y: number, z: number): Vector3
	return O + Vector3.new(x, y, z)
end

local function C(x: number, y: number, z: number): CFrame
	return CFrame.new(O + Vector3.new(x, y, z))
end

local function CY(x: number, y: number, z: number, yawDeg: number): CFrame
	return CFrame.new(O + Vector3.new(x, y, z)) * CFrame.Angles(0, math.rad(yawDeg), 0)
end

-- CFrame at world position p whose front (-Z) faces the horizontal direction toward q.
local function faceTo(p: Vector3, q: Vector3): CFrame
	local flat = Vector3.new(q.X, p.Y, q.Z)
	if (flat - p).Magnitude < 0.01 then
		return CFrame.new(p)
	end
	return CFrame.lookAt(p, flat)
end

---------------------------------------------------------------------------------------
-- Terrain height field (shared by terrain generation and prop placement)
---------------------------------------------------------------------------------------

local function stairTopAt(x: number): number
	-- Sanctuary stairs climb from X -35 (Y 10.3) to X -53 (Y 20.3).
	return PLAZA_Y + clamp((-35 - x) / 18, 0, 1) * (SANCT_Y - PLAZA_Y)
end

local function terrace3(h: number): number
	-- Layered strata look: flat ledges every 3 studs with short steep risers.
	local band = math.floor(h / 3)
	local f = h / 3 - band
	return band * 3 + 3 * smoothstep(0.55, 1, f)
end

local function beachWeight(x: number, z: number): number
	-- Only two small sandy coves (ref: the island is rock and stone, very little beach).
	return smoothstep(0.24, 0.38, noise2(x, z, 0.028, 3))
end

local function heightAt(x: number, z: number): number
	local n = noise2(x, z, 0.045, 1)
	local n2 = noise2(x, z, 0.11, 2)

	-- Organic island outline: union of soft ellipses with a noisy boundary.
	local m = math.min(
		ell(x, z, -22, 2, 48, 38),
		ell(x, z, -6, -60, 30, 22),
		ell(x, z, SANCT_CX, SANCT_CZ, 28, 26),
		ell(x, z, -38, 36, 17, 15),
		ell(x, z, -70, 8, 16, 18)
	) + n * 0.16

	local land = 8.2 + n2 * 0.6
	local h: number
	if m < 0.8 then
		h = land
	else
		-- Layered rock cliff dropping steeply into the sea, tapering under water.
		local cliff: number
		if m < 1.0 then
			cliff = terrace3(lerp(land, 0.6, smoothstep(0.8, 1.0, m)))
		elseif m < 1.12 then
			cliff = lerp(0.6, -7, (m - 1.0) / 0.12)
		else
			cliff = lerp(-7, -13, clamp((m - 1.12) / 0.5, 0, 1))
		end
		local beach: number
		if m < 1.1 then
			beach = lerp(land, 1.0, smoothstep(0.78, 1.1, m))
		elseif m < 1.35 then
			beach = lerp(1.0, -4, (m - 1.1) / 0.25)
		else
			beach = lerp(-4, -13, clamp((m - 1.35) / 0.6, 0, 1))
		end
		h = lerp(cliff, beach, beachWeight(x, z))
	end

	-- Small separate grass islet south-west (ref-1/ref-2).
	local im = ell(x, z, -86, 30, 7, 6) + n * 0.1
	if im < 1.25 then
		local ih = if im < 0.75
			then 6.2 + n2 * 0.4
			else terrace3(lerp(6.2, -8, smoothstep(0.75, 1.25, im)))
		h = math.max(h, ih)
	end

	-- Rocky hill behind the Workshop (layered, grass patches on top).
	local hm = ell(x, z, -6, -64, 25, 16) + n * 0.08
	if hm < 1 then
		local hh = 12 + 22 * (1 - hm * hm) ^ 0.75
		h = math.max(h, terrace3(hh))
	end
	-- Rock shoulders beside the Workshop terrace.
	local s1 = ell(x, z, -35, -42, 9, 8)
	if s1 < 1 then
		h = math.max(h, terrace3(12 + 7 * (1 - s1 * s1)))
	end
	local s2 = ell(x, z, 23, -38, 8, 9)
	if s2 < 1 then
		h = math.max(h, terrace3(11 + 7 * (1 - s2 * s2)))
	end

	-- Sanctuary plateau: tall round stone mesa with layered cliffs.
	local plateauTop = SANCT_Y - TERRAIN_MARGIN
	local pm = ell(x, z, SANCT_CX, SANCT_CZ, 21.5, 21.5) + n * 0.04
	if pm < 1.25 then
		local ph = if pm < 0.86
			then plateauTop
			else terrace3(lerp(plateauTop, 2, smoothstep(0.86, 1.25, pm)))
		h = math.max(h, ph)
	end
	-- Grass ledge west of the plateau for the giant blossom tree.
	local tm = ell(x, z, -86, -13, 8, 7)
	if tm < 1.3 then
		local th = if tm < 0.8
			then plateauTop
			else terrace3(lerp(plateauTop, 4, smoothstep(0.8, 1.3, tm)))
		h = math.max(h, th)
	end
	-- Waterfall cliff (between plateau and lagoon).
	local wm = ell(x, z, -62, -19, 10, 7.5)
	if wm < 1.3 then
		local wh = if wm < 0.8
			then plateauTop
			else terrace3(lerp(plateauTop, 6, smoothstep(0.8, 1.3, wm)))
		h = math.max(h, wh)
	end

	-- Lagoon basin: sand floor, raised rim so the water is held.
	local lr = dist2(x, z, LAGOON_CX, LAGOON_CZ)
	if lr < 15 then
		h = 3.9 + n2 * 0.4
	elseif lr < 16.5 then
		h = math.min(h, lerp(4.2, 8.0, (lr - 15) / 1.5))
	elseif lr < 21 then
		h = math.max(h, 8.4 + n2 * 0.3)
	end

	-- Under-floor clearances (everything at least TERRAIN_MARGIN below the floor).
	if inRect(x, z, -28, 16, -51, -21) then
		h = TERRACE_Y - TERRAIN_MARGIN
	end
	if inRect(x, z, -32, 20, -24, 26) then
		h = math.min(h, PLAZA_Y - TERRAIN_MARGIN)
	end
	if inRect(x, z, -59, -30, -29, -15) then
		h = math.min(h, stairTopAt(x) - TERRAIN_MARGIN)
	end
	-- Front stairs trench + shallow turquoise pool (top voxel stays under the water).
	if inRect(x, z, -17, 5, 24, 62) then
		h = math.min(h, -4.6)
	end
	-- Reef shelf in front of the stairs.
	local rm = ell(x, z, -6, 62, 24, 12)
	if rm < 1 then
		h = math.max(h, -6 + n * 1.0)
		h = math.min(h, -4.6)
	end
	-- Fishing pier: terrain only touches its start, open sea after.
	if x > 14 and z > -10 and z < 24 then
		h = math.min(h, lerp(PLAZA_Y - TERRAIN_MARGIN, -8, clamp((x - 14) / 6, 0, 1)))
	end
	-- Wharf bridge and expedition wharf over open water.
	if inRect(x, z, 9, 20, 22, 32) then
		h = math.min(h, PLAZA_Y - TERRAIN_MARGIN - 1)
	end
	if x > 9 and z > 28 then
		h = math.min(h, lerp(-4.6, -9, clamp((x - 10) / 25, 0, 1)))
	end
	-- Aquarium deck and its path.
	if inRect(x, z, -53, -23, 31, 58) then
		h = math.min(h, 5.2)
	end
	if inRect(x, z, -33, -21, 22, 37) then
		h = math.min(h, PLAZA_Y - TERRAIN_MARGIN)
	end
	-- Lagoon bridge and portal deck.
	if inRect(x, z, -52, -29, -11, 3) and lr >= 16.5 then
		h = math.min(h, PLAZA_Y - TERRAIN_MARGIN)
	end

	-- Fade to open seabed near the box edge.
	local edge =
		math.min(x - TERRAIN_MIN.X, TERRAIN_MAX.X - x, z - TERRAIN_MIN.Z, TERRAIN_MAX.Z - z)
	if edge < 10 then
		h = lerp(-13, h, clamp(edge / 10, 0, 1))
	end
	return h
end

-- Which columns get sand on top (coves, reef, stairs pool, lagoon floor).
local function sandAt(x: number, z: number, h: number): boolean
	if dist2(x, z, LAGOON_CX, LAGOON_CZ) < 16 and h < 8 then
		return true
	end
	if inRect(x, z, -17, 5, 24, 62) or ell(x, z, -6, 62, 24, 12) < 1.05 then
		return true
	end
	return h < 2.6 and h > -5 and beachWeight(x, z) > 0.5
end

-- Grass only in patches on flat ground (rest is layered rock).
local function grassAt(x: number, z: number): boolean
	return noise2(x, z, 0.06, 7) > -0.18
end

local function waterLevelAt(x: number, z: number): number
	if dist2(x, z, LAGOON_CX, LAGOON_CZ) < 16.5 then
		return LAGOON_WATER_Y
	end
	return SEA_Y
end

local function slopeAt(x: number, z: number): number
	local dx = math.abs(heightAt(x + 2, z) - heightAt(x - 2, z)) / 4
	local dz = math.abs(heightAt(x, z + 2) - heightAt(x, z - 2)) / 4
	return math.max(dx, dz)
end

-- Visible ground height for placing props (relative Y).
local function groundY(x: number, z: number): number
	return heightAt(x, z) + TERRAIN_RENDER_OFFSET
end

---------------------------------------------------------------------------------------
-- Terrain generation (native Terrain, only inside the hub box)
---------------------------------------------------------------------------------------

local function setupTerrainLook(terrain: Terrain)
	terrain.Decoration = false
	terrain.WaterColor = Color3.fromRGB(10, 96, 168)
	terrain.WaterTransparency = 0.52
	terrain.WaterReflectance = 0.55
	terrain.WaterWaveSize = 0.14
	terrain.WaterWaveSpeed = 9
	terrain:SetMaterialColor(Enum.Material.Rock, TERRAIN_COLORS.rock)
	terrain:SetMaterialColor(Enum.Material.Basalt, TERRAIN_COLORS.basalt)
	terrain:SetMaterialColor(Enum.Material.Grass, TERRAIN_COLORS.grass)
	terrain:SetMaterialColor(Enum.Material.Sand, TERRAIN_COLORS.sand)
	terrain:SetMaterialColor(Enum.Material.Slate, TERRAIN_COLORS.slate)
end

local function terrainRegion(): Region3
	return Region3.new(O + TERRAIN_MIN, O + TERRAIN_MAX):ExpandToGrid(VOXEL)
end

local function strataMaterial(y: number, x: number, z: number): Enum.Material
	local band = math.floor((y + noise2(x, z, 0.08, 9) * 2.5) / 3)
	if band % 3 == 0 then
		return Enum.Material.Basalt
	end
	return Enum.Material.Rock
end

local function generateHeightTerrain(terrain: Terrain)
	local region = terrainRegion()
	local minW = region.CFrame.Position - region.Size / 2
	local nx = math.floor(region.Size.X / VOXEL + 0.5)
	local ny = math.floor(region.Size.Y / VOXEL + 0.5)
	local nz = math.floor(region.Size.Z / VOXEL + 0.5)

	-- Precompute column data (relative coordinates).
	local heights: { { number } } = {}
	local slopes: { { number } } = {}
	local waters: { { number } } = {}
	for ix = 1, nx do
		local hx: { number } = {}
		local sx: { number } = {}
		local wx: { number } = {}
		local rx = minW.X + (ix - 0.5) * VOXEL - O.X
		for iz = 1, nz do
			local rz = minW.Z + (iz - 0.5) * VOXEL - O.Z
			hx[iz] = heightAt(rx, rz)
			sx[iz] = slopeAt(rx, rz)
			wx[iz] = waterLevelAt(rx, rz)
		end
		heights[ix] = hx
		slopes[ix] = sx
		waters[ix] = wx
	end
	task.wait()

	local materials: { { { Enum.Material } } } = {}
	local occupancies: { { { number } } } = {}
	for ix = 1, nx do
		local mx: { { Enum.Material } } = {}
		local ox: { { number } } = {}
		local rx = minW.X + (ix - 0.5) * VOXEL - O.X
		for iy = 1, ny do
			local my: { Enum.Material } = {}
			local oy: { number } = {}
			local yBottom = minW.Y + (iy - 1) * VOXEL - O.Y
			local yTop = yBottom + VOXEL
			local yMid = yBottom + VOXEL / 2
			for iz = 1, nz do
				local rz = minW.Z + (iz - 0.5) * VOXEL - O.Z
				local h = heights[ix][iz]
				local s = slopes[ix][iz]
				local wl = waters[ix][iz]
				local occ = clamp((h - yBottom) / VOXEL, 0, 1)
				local mat: Enum.Material = Enum.Material.Air
				if occ > 0 then
					-- Under water, round partial voxels up to avoid air pockets.
					if yTop <= wl + 0.01 and occ < 1 then
						occ = if occ >= 0.12 then 1 else 0
					end
				end
				if occ > 0 then
					local depth = h - yMid
					if yMid < -13 and depth > 2 then
						mat = Enum.Material.Slate
					elseif depth < 4.5 then
						if h < -9 then
							mat = Enum.Material.Slate
						elseif sandAt(rx, rz, h) then
							mat = Enum.Material.Sand
						elseif h <= 2.6 or s > 0.7 then
							mat = strataMaterial(yMid, rx, rz)
						elseif grassAt(rx, rz) then
							mat = Enum.Material.Grass
						else
							mat = strataMaterial(yMid, rx, rz)
						end
					else
						mat = strataMaterial(yMid, rx, rz)
					end
				end
				if occ <= 0 then
					if yTop <= wl + 0.01 then
						mat = Enum.Material.Water
						-- Lagoon top layer at half occupancy so the visible surface sits near Y 8.
						occ = if wl > SEA_Y + 1 and yTop > wl - 0.01 then 0.5 else 1
					else
						mat = Enum.Material.Air
						occ = 0
					end
				end
				my[iz] = mat
				oy[iz] = occ
			end
			mx[iy] = my
			ox[iy] = oy
		end
		materials[ix] = mx
		occupancies[ix] = ox
		if ix % 8 == 0 then
			task.wait()
		end
	end
	terrain:WriteVoxels(region, VOXEL, materials :: any, occupancies :: any)
	task.wait()
end

local function rockBall(
	terrain: Terrain,
	x: number,
	y: number,
	z: number,
	r: number,
	mat: Enum.Material?
)
	terrain:FillBall(V(x, y, z), r, mat or Enum.Material.Rock)
end

local function buildTerrainFeatures(terrain: Terrain)
	-- Island underside: fully submerged boulders so the island tapers into the sea
	-- (nothing loose sticking out of the water).
	for i = 1, 70 do
		local a = (i - 1) / 70 * math.pi * 2 + rnd(-0.03, 0.03)
		local x = -22 + math.cos(a) * 53 + rnd(-3, 3)
		local z = 2 + math.sin(a) * 42 + rnd(-3, 3)
		local nearStairs = x > -20 and x < 8 and z > 20
		local nearPier = x > 8 and z > -12 and z < 26
		local nearWharf = x > 6 and z > 24
		local nearAquarium = x > -56 and x < -20 and z > 28
		if not (nearStairs or nearPier or nearWharf or nearAquarium) then
			local r = rnd(4, 6)
			rockBall(
				terrain,
				x,
				rnd(-14, -11),
				z,
				r,
				if i % 3 == 0 then Enum.Material.Basalt else Enum.Material.Rock
			)
		end
	end
	task.wait()

	-- Rock walls along both sides of the front stairs (stepping down to the reef).
	for _, x in { -18.5, 6.5 } do
		for i = 1, 7 do
			local z = 27 + i * 4
			local y = PLAZA_Y - 5.5 - i * 1.4
			rockBall(terrain, x + rnd(-0.6, 0.6), y, z, rnd(3.2, 4.0))
		end
	end
	-- Submerged reef boulders (turquoise shallows).
	for i = 1, 16 do
		local side = if i % 2 == 0 then 1 else -1
		local x = -6 + side * rnd(11, 22)
		local z = rnd(48, 72)
		rockBall(
			terrain,
			x,
			rnd(-7.5, -6.5),
			z,
			rnd(1.6, 2.6),
			if i % 3 == 0 then Enum.Material.Basalt else Enum.Material.Rock
		)
	end

	-- Rock ledge behind the waterfall (lip at the plateau height, face toward the lagoon).
	-- (fall at lagoon radius 15.2 toward north-north-west, ledge right behind it)
	terrain:FillBlock(
		CFrame.lookAt(V(-52.6, 11.5, -14.5), V(LAGOON_CX, 11.5, LAGOON_CZ)),
		Vector3.new(6.5, 9, 3),
		Enum.Material.Rock
	)
	terrain:FillBlock(
		CFrame.lookAt(V(-55.5, 12, -16.0), V(LAGOON_CX, 12, LAGOON_CZ)),
		Vector3.new(8, 10, 3),
		Enum.Material.Basalt
	)

	-- Safety carves: never solid terrain inside the Workshop house or above the plaza.
	terrain:FillBlock(C(-6, 28, -36), Vector3.new(36, 24, 26), Enum.Material.Air)
	terrain:FillBlock(C(-6, 16, 1), Vector3.new(48, 8, 46), Enum.Material.Air)
	terrain:FillBlock(C(SANCT_CX, 24, SANCT_CZ), Vector3.new(32, 8, 32), Enum.Material.Air)
	task.wait()
end

local function buildTerrain()
	local terrain = Workspace.Terrain
	setupTerrainLook(terrain)
	generateHeightTerrain(terrain)
	buildTerrainFeatures(terrain)
end

---------------------------------------------------------------------------------------
-- Instance helpers
---------------------------------------------------------------------------------------

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
	name: string,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	transparency: number?
)
	p.Name = name
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local collide = canCollide == true
	p.CanCollide = collide
	p.CanTouch = false
	if not collide then
		p.CanQuery = false
	end
	p.Transparency = transparency or 0
	local s = p.Size
	if not collide and math.max(s.X, s.Y, s.Z) < 8 then
		p.CastShadow = false
	end
	stats.parts += 1
end

local function makePart(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	finishPart(p, name, color, material, canCollide, transparency)
	p.Parent = parent
	return p
end

local function makeWedge(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	transparency: number?
): WedgePart
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	finishPart(p, name, color, material, canCollide, transparency)
	p.Parent = parent
	return p
end

-- Vertical cylinder centered at cf (axis = cf.UpVector).
local function makeCylinderY(
	parent: Instance,
	name: string,
	cf: CFrame,
	height: number,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
	finishPart(p, name, color, material, canCollide, transparency)
	p.Parent = parent
	return p
end

local function makeBall(
	parent: Instance,
	name: string,
	pos: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(diameter, diameter, diameter)
	p.CFrame = CFrame.new(pos)
	finishPart(p, name, color, material, false, transparency)
	p.Parent = parent
	return p
end

local function makeEllipsoid(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	finishPart(p, name, color, material, false, transparency)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	p.Parent = parent
	return p
end

-- Square beam between two points.
local function makeSegment(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	thick: number,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?
): Part
	local len = math.max((b - a).Magnitude, 0.05)
	local cf = CFrame.lookAt((a + b) / 2, b)
	if math.abs((b - a).Unit.Y) > 0.98 then
		cf = CFrame.lookAt((a + b) / 2, b, Vector3.xAxis)
	end
	return makePart(parent, name, cf, Vector3.new(thick, thick, len), color, material, canCollide)
end

-- Round cylinder between two points.
local function makeTube(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?
): Part
	local len = math.max((b - a).Magnitude, 0.05)
	local up = if math.abs((b - a).Unit.Y) > 0.98 then Vector3.xAxis else Vector3.yAxis
	local cf = CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(len, diameter, diameter)
	p.CFrame = cf
	finishPart(p, name, color, material, canCollide, nil)
	p.Parent = parent
	return p
end

local function addLight(part: BasePart, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = part
	stats.lights += 1
end

local function addSparkles(
	part: BasePart,
	color: Color3,
	rate: number,
	size: number,
	speed: number,
	lifetime: number?
)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE_TEXTURE
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.8
	e.Rate = rate
	e.Lifetime = NumberRange.new(lifetime or 1.6, (lifetime or 1.6) * 1.6)
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.LockedToPart = false
	e.Parent = part
	stats.emitters += 1
end

-- Flat ring of segments lying in the cf's XZ plane.
local function makeNeonRing(
	parent: Instance,
	name: string,
	cf: CFrame,
	radius: number,
	thickness: number,
	segments: number,
	color: Color3,
	transparency: number?,
	material: Enum.Material?
)
	local seg = 2 * math.pi * radius / segments * 1.04
	for i = 0, segments - 1 do
		local a = (i + 0.5) / segments * math.pi * 2
		local pcf = cf * CFrame.Angles(0, -a, 0) * CFrame.new(radius, 0, 0)
		makePart(
			parent,
			name,
			pcf,
			Vector3.new(thickness, thickness * 0.5, seg),
			color,
			material or Enum.Material.Neon,
			false,
			transparency
		)
	end
end

-- Curved rope (catenary-like sag) between two points; returns sample points.
local function makeRope(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	sag: number,
	diameter: number?,
	color: Color3?
): { Vector3 }
	local len = (b - a).Magnitude
	local n = math.clamp(math.floor(len / 2.2), 3, 18)
	local pts: { Vector3 } = {}
	for i = 0, n do
		local t = i / n
		pts[i + 1] = a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
	end
	local d = diameter or 0.22
	for i = 1, n do
		makeTube(
			parent,
			name,
			pts[i],
			pts[i + 1],
			d,
			color or PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
	end
	return pts
end

-- Bunting: rope with triangular pennants.
local function makeBunting(parent: Instance, name: string, a: Vector3, b: Vector3, sag: number)
	makeRope(parent, name .. "Rope", a, b, sag, 0.14, PALETTE.rope)
	local len = (b - a).Magnitude
	local dir = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	if dir.Magnitude < 0.01 then
		return
	end
	local count = math.max(2, math.floor(len / 1.7))
	for i = 1, count do
		local t = (i - 0.5) / count
		local p = a:Lerp(b, t) - Vector3.new(0, sag * 4 * t * (1 - t) + 0.05, 0)
		local base = CFrame.lookAt(p, p + dir.Unit)
		local cf = base * CFrame.new(0, -0.55, 0) * CFrame.Angles(0, 0, math.pi)
		makeWedge(
			parent,
			name .. "Flag",
			cf,
			Vector3.new(0.06, 1.1, 0.9),
			FLAG_COLORS[(i - 1) % #FLAG_COLORS + 1],
			Enum.Material.Fabric,
			false
		)
	end
end

-- Sign board with SurfaceGui text (front face = -Z of cf).
local function makeSign(
	parent: Instance,
	name: string,
	cf: CFrame,
	w: number,
	h: number,
	title: string,
	subtitle: string?,
	bg: Color3?,
	fg: Color3?,
	subColor: Color3?,
	frameColor: Color3?,
	twoSided: boolean?
): Part
	local board = makePart(
		parent,
		name,
		cf,
		Vector3.new(w, h, 0.4),
		bg or PALETTE.signBg,
		Enum.Material.SmoothPlastic,
		false
	)
	local fc = frameColor or PALETTE.woodDark
	local t = 0.28
	makePart(
		parent,
		name .. "Trim",
		cf * CFrame.new(0, h / 2 + t / 2 - 0.05, 0),
		Vector3.new(w + t * 2, t, 0.55),
		fc,
		Enum.Material.Wood,
		false
	)
	makePart(
		parent,
		name .. "Trim",
		cf * CFrame.new(0, -h / 2 - t / 2 + 0.05, 0),
		Vector3.new(w + t * 2, t, 0.55),
		fc,
		Enum.Material.Wood,
		false
	)
	makePart(
		parent,
		name .. "Trim",
		cf * CFrame.new(w / 2 + t / 2 - 0.05, 0, 0),
		Vector3.new(t, h, 0.55),
		fc,
		Enum.Material.Wood,
		false
	)
	makePart(
		parent,
		name .. "Trim",
		cf * CFrame.new(-w / 2 - t / 2 + 0.05, 0, 0),
		Vector3.new(t, h, 0.55),
		fc,
		Enum.Material.Wood,
		false
	)
	local faces = if twoSided
		then { Enum.NormalId.Front, Enum.NormalId.Back }
		else { Enum.NormalId.Front }
	for _, face in faces do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0.15
		gui.AlwaysOnTop = false
		local titleLabel = Instance.new("TextLabel")
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.FredokaOne
		titleLabel.TextScaled = true
		titleLabel.Text = title
		titleLabel.TextColor3 = fg or PALETTE.signText
		titleLabel.TextStrokeTransparency = 0.55
		titleLabel.TextStrokeColor3 = Color3.fromRGB(20, 16, 30)
		if subtitle then
			titleLabel.Position = UDim2.fromScale(0.05, 0.06)
			titleLabel.Size = UDim2.fromScale(0.9, 0.56)
			local sub = Instance.new("TextLabel")
			sub.BackgroundTransparency = 1
			sub.Font = Enum.Font.FredokaOne
			sub.TextScaled = true
			sub.Text = subtitle
			sub.TextColor3 = subColor or PALETTE.gold
			sub.TextStrokeTransparency = 0.7
			sub.Position = UDim2.fromScale(0.08, 0.62)
			sub.Size = UDim2.fromScale(0.84, 0.32)
			sub.Parent = gui
		else
			titleLabel.Position = UDim2.fromScale(0.05, 0.1)
			titleLabel.Size = UDim2.fromScale(0.9, 0.8)
		end
		titleLabel.Parent = gui
		gui.Parent = board
	end
	return board
end

-- Lantern body (amber glass with dark frame); pos = lantern center.
local function makeLanternBody(
	parent: Instance,
	name: string,
	pos: Vector3,
	scale: number,
	withLight: boolean
)
	local s = scale
	local core = makePart(
		parent,
		name .. "Glow",
		CFrame.new(pos),
		Vector3.new(0.9, 1.1, 0.9) * s,
		PALETTE.amber,
		Enum.Material.Neon,
		false,
		0.05
	)
	for _, off in
		{
			Vector3.new(0.5, 0, 0.5),
			Vector3.new(-0.5, 0, 0.5),
			Vector3.new(0.5, 0, -0.5),
			Vector3.new(-0.5, 0, -0.5),
		}
	do
		makePart(
			parent,
			name .. "Frame",
			CFrame.new(pos + off * s),
			Vector3.new(0.16, 1.3, 0.16) * s,
			PALETTE.woodDark,
			Enum.Material.Metal,
			false
		)
	end
	makePart(
		parent,
		name .. "Base",
		CFrame.new(pos - Vector3.new(0, 0.68 * s, 0)),
		Vector3.new(1.25, 0.2, 1.25) * s,
		PALETTE.woodDark,
		Enum.Material.Metal,
		false
	)
	makePart(
		parent,
		name .. "Cap",
		CFrame.new(pos + Vector3.new(0, 0.72 * s, 0)),
		Vector3.new(1.3, 0.22, 1.3) * s,
		PALETTE.woodDark,
		Enum.Material.Metal,
		false
	)
	makePart(
		parent,
		name .. "Top",
		CFrame.new(pos + Vector3.new(0, 0.95 * s, 0)),
		Vector3.new(0.7, 0.3, 0.7) * s,
		PALETTE.woodDark,
		Enum.Material.Metal,
		false
	)
	makeTube(
		parent,
		name .. "Ring",
		pos + Vector3.new(0, 1.12 * s, -0.18 * s),
		pos + Vector3.new(0, 1.12 * s, 0.18 * s),
		0.3 * s,
		PALETTE.metal,
		Enum.Material.Metal,
		false
	)
	if withLight then
		addLight(core, PALETTE.amber, 13 * s, 1.1)
	end
end

-- Wooden post lantern standing on the ground (base = ground point).
local function makeLantern(
	parent: Instance,
	name: string,
	base: Vector3,
	height: number?,
	withLight: boolean?
)
	local h = height or 5
	makeCylinderY(
		parent,
		name .. "Foot",
		CFrame.new(base + Vector3.new(0, 0.25, 0)),
		0.5,
		1.2,
		PALETTE.stoneDark,
		Enum.Material.Slate,
		false
	)
	makeCylinderY(
		parent,
		name .. "Post",
		CFrame.new(base + Vector3.new(0, h / 2, 0)),
		h,
		0.45,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	makeLanternBody(parent, name, base + Vector3.new(0, h + 0.65, 0), 1, withLight ~= false)
end

-- Short stone lantern (pedestal style).
local function makeStoneLantern(parent: Instance, name: string, base: Vector3, withLight: boolean?)
	makePart(
		parent,
		name .. "Base",
		CFrame.new(base + Vector3.new(0, 0.3, 0)),
		Vector3.new(1.8, 0.6, 1.8),
		PALETTE.stoneMid,
		Enum.Material.Slate,
		true
	)
	makePart(
		parent,
		name .. "Shaft",
		CFrame.new(base + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, math.rad(45), 0),
		Vector3.new(0.9, 1.8, 0.9),
		PALETTE.stone,
		Enum.Material.Slate,
		true
	)
	makePart(
		parent,
		name .. "Seat",
		CFrame.new(base + Vector3.new(0, 2.5, 0)),
		Vector3.new(1.6, 0.25, 1.6),
		PALETTE.stoneMid,
		Enum.Material.Slate,
		false
	)
	local glow = makePart(
		parent,
		name .. "Glow",
		CFrame.new(base + Vector3.new(0, 3.1, 0)),
		Vector3.new(1, 0.95, 1),
		PALETTE.amber,
		Enum.Material.Neon,
		false,
		0.05
	)
	makePart(
		parent,
		name .. "Roof",
		CFrame.new(base + Vector3.new(0, 3.75, 0)) * CFrame.Angles(0, math.rad(45), 0),
		Vector3.new(1.7, 0.35, 1.7),
		PALETTE.stoneMid,
		Enum.Material.Slate,
		false
	)
	makePart(
		parent,
		name .. "Knob",
		CFrame.new(base + Vector3.new(0, 4.1, 0)),
		Vector3.new(0.5, 0.4, 0.5),
		PALETTE.stone,
		Enum.Material.Slate,
		false
	)
	if withLight ~= false then
		addLight(glow, PALETTE.amber, 11, 1)
	end
end

-- Hexagonal crystal prism with a pointed tip; cf = base, crystal grows along cf.UpVector.
local function makeCrystal(
	parent: Instance,
	name: string,
	cf: CFrame,
	height: number,
	radius: number,
	color: Color3,
	glow: boolean?
)
	local bodyH = height * 0.78
	local w = radius * math.sqrt(3)
	for k = 0, 2 do
		makePart(
			parent,
			name,
			cf * CFrame.new(0, bodyH / 2, 0) * CFrame.Angles(0, math.rad(60 * k), 0),
			Vector3.new(radius, bodyH, w),
			color,
			Enum.Material.Glass,
			false,
			0.18
		)
	end
	local s = radius * 1.18
	local tipCf = cf * CFrame.new(0, bodyH, 0) * CFrame.Angles(math.rad(45), 0, math.rad(35.264))
	makePart(
		parent,
		name .. "Tip",
		tipCf,
		Vector3.new(s, s, s),
		color,
		Enum.Material.Glass,
		false,
		0.12
	)
	local core = makePart(
		parent,
		name .. "Core",
		cf * CFrame.new(0, bodyH * 0.5, 0),
		Vector3.new(radius * 0.5, bodyH * 0.8, radius * 0.5),
		color,
		Enum.Material.Neon,
		false,
		0.35
	)
	if glow then
		addLight(core, color, math.clamp(height * 2.2, 8, 22), 0.8)
	end
end

-- Cluster of 3-5 tilted crystals around a ground point.
local function makeCrystalCluster(
	parent: Instance,
	name: string,
	base: Vector3,
	scale: number,
	color: Color3,
	glow: boolean?,
	altColor: Color3?
)
	local count = rndInt(3, 5)
	for i = 1, count do
		local main = i == 1
		local a = rnd(0, math.pi * 2)
		local off = if main
			then Vector3.zero
			else Vector3.new(math.cos(a), 0, math.sin(a)) * rnd(0.6, 1.3) * scale
		local tilt = if main then rnd(-6, 6) else rnd(18, 34)
		local yaw = math.deg(a) + 90
		local h = if main then scale * rnd(3.4, 4.2) else scale * rnd(1.6, 2.6)
		local r = if main then scale * 0.62 else scale * rnd(0.32, 0.45)
		local cf = CFrame.new(base + off - Vector3.new(0, 0.3 * scale, 0))
			* CFrame.Angles(0, math.rad(yaw), 0)
			* CFrame.Angles(math.rad(tilt), 0, 0)
		local col = if altColor and i % 2 == 0 then altColor else color
		makeCrystal(parent, name, cf, h, r, vary(col, 0.05), glow == true and main)
	end
	makeEllipsoid(
		parent,
		name .. "Rock",
		CFrame.new(base + Vector3.new(0, -0.1, 0)),
		Vector3.new(2.4, 0.8, 2.2) * scale,
		PALETTE.stoneBlue,
		Enum.Material.Slate
	)
end

-- Palm tree; base = ground point. Arched, rounded fronds in three greens (ref).
local function makePalm(
	parent: Instance,
	name: string,
	base: Vector3,
	height: number,
	leanDeg: number?
)
	local lean = math.rad(leanDeg or rnd(0, 360))
	local leanDir = Vector3.new(math.cos(lean), 0, math.sin(lean))
	local segs = 9
	local prev = base - Vector3.new(0, 0.8, 0)
	local top = prev
	for i = 1, segs do
		local t = i / segs
		local p = base + Vector3.new(0, height * t, 0) + leanDir * (height * 0.26 * t * t)
		local d = lerp(1.9, 1.05, t)
		makeTube(
			parent,
			name .. "Trunk",
			prev,
			p,
			d,
			if i % 2 == 0 then PALETTE.bark else PALETTE.barkDark,
			Enum.Material.Wood,
			i <= 4
		)
		makeCylinderY(
			parent,
			name .. "Ring",
			CFrame.lookAt(p, p + Vector3.new(0, 1, 0) + leanDir * 0.3)
				* CFrame.Angles(math.pi / 2, 0, 0),
			0.3,
			d + 0.3,
			PALETTE.barkDark,
			Enum.Material.Wood,
			false
		)
		prev = p
		top = p
	end
	makeEllipsoid(
		parent,
		name .. "Crown",
		CFrame.new(top + Vector3.new(0, 0.3, 0)),
		Vector3.new(2.2, 1.4, 2.2),
		PALETTE.leafDark,
		Enum.Material.SmoothPlastic
	)
	local tones = { PALETTE.leafDark, PALETTE.leaf, PALETTE.leafMid, PALETTE.leafLight }
	local fronds = 9
	for i = 1, fronds do
		local a = (i - 1) / fronds * math.pi * 2 + rnd(-0.12, 0.12)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local len = height * rnd(0.5, 0.6)
		local lift = rnd(1.2, 2.0)
		local prevP = top + Vector3.new(0, 0.4, 0)
		local n = 6
		for k = 1, n do
			local t = k / n
			-- arc: rises first, then droops toward the tip
			local p = top
				+ Vector3.new(0, 0.4, 0)
				+ dir * len * t
				+ Vector3.new(0, lift * math.sin(t * math.pi * 0.75) - 3.4 * t * t, 0)
			local width = lerp(2.4, 0.7, t) * (1 + 0.25 * math.sin(t * math.pi))
			local seg = p - prevP
			local cf = CFrame.lookAt((prevP + p) / 2, p)
			local tone = tones[math.clamp(math.floor(t * 3.2) + 1, 1, 4)]
			makeEllipsoid(
				parent,
				name .. "Frond",
				cf,
				Vector3.new(width, 0.42, seg.Magnitude + 0.9),
				vary(tone, 0.03),
				Enum.Material.SmoothPlastic
			)
			-- center rib, slightly darker
			makePart(
				parent,
				name .. "Rib",
				cf * CFrame.new(0, 0.16, 0),
				Vector3.new(0.14, 0.12, seg.Magnitude + 0.3),
				PALETTE.leafDark,
				Enum.Material.SmoothPlastic,
				false
			)
			prevP = p
		end
	end
	for i = 1, 4 do
		local a = i * 1.57 + 0.4
		makeBall(
			parent,
			name .. "Coconut",
			top + Vector3.new(math.cos(a) * 0.75, -0.55, math.sin(a) * 0.75),
			0.85,
			PALETTE.barkDark,
			Enum.Material.SmoothPlastic
		)
	end
end

-- Grass/fern tuft (thin blades); base = ground point.
local function makeTuft(parent: Instance, name: string, base: Vector3, scale: number, color: Color3)
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2 + rnd(-0.3, 0.3)
		local cf = CFrame.new(base)
			* CFrame.Angles(0, a, 0)
			* CFrame.Angles(math.rad(rnd(18, 34)), 0, 0)
			* CFrame.new(0, 0.7 * scale, 0)
		makePart(
			parent,
			name,
			cf,
			Vector3.new(0.35 * scale, 1.5 * scale, 0.08),
			vary(color, 0.06),
			Enum.Material.SmoothPlastic,
			false
		)
	end
end

local function makeFern(parent: Instance, name: string, base: Vector3, scale: number)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2 + rnd(-0.2, 0.2)
		local cf = CFrame.new(base)
			* CFrame.Angles(0, a, 0)
			* CFrame.Angles(math.rad(rnd(42, 60)), 0, 0)
			* CFrame.new(0, 1.2 * scale, 0)
		makeWedge(
			parent,
			name,
			cf,
			Vector3.new(0.1, 2.4 * scale, 0.8 * scale),
			vary(PALETTE.fern, 0.06),
			Enum.Material.SmoothPlastic,
			false
		)
	end
end

local function makeFlower(parent: Instance, name: string, base: Vector3, color: Color3)
	makeSegment(
		parent,
		name .. "Stem",
		base,
		base + Vector3.new(0, 0.7, 0),
		0.08,
		PALETTE.leafDark,
		Enum.Material.SmoothPlastic,
		false
	)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		makeBall(
			parent,
			name .. "Petal",
			base + Vector3.new(math.cos(a) * 0.22, 0.75, math.sin(a) * 0.22),
			0.32,
			color,
			Enum.Material.SmoothPlastic
		)
	end
	makeBall(
		parent,
		name .. "Center",
		base + Vector3.new(0, 0.78, 0),
		0.22,
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
end

local function makeBush(parent: Instance, name: string, base: Vector3, scale: number)
	for i = 1, 3 do
		local off = Vector3.new(rnd(-0.8, 0.8), 0, rnd(-0.8, 0.8)) * scale
		local s = rnd(1.6, 2.4) * scale
		makeEllipsoid(
			parent,
			name,
			CFrame.new(base + off + Vector3.new(0, s * 0.32, 0)),
			Vector3.new(s, s * 0.8, s),
			vary(PALETTE.leafDark, 0.06),
			Enum.Material.SmoothPlastic
		)
	end
	if rng:NextNumber() < 0.6 then
		makeFlower(
			parent,
			name .. "Flower",
			base + Vector3.new(rnd(-0.6, 0.6) * scale, 0.9 * scale, rnd(-0.6, 0.6) * scale),
			PALETTE.pink
		)
	end
end

-- Crystal plant in a clay pot (concept planters).
local function makePlanter(parent: Instance, name: string, base: Vector3, color: Color3)
	makeCylinderY(
		parent,
		name .. "Pot",
		CFrame.new(base + Vector3.new(0, 0.7, 0)),
		1.4,
		2.2,
		Color3.fromRGB(224, 196, 150),
		Enum.Material.SmoothPlastic,
		true
	)
	makeCylinderY(
		parent,
		name .. "Rim",
		CFrame.new(base + Vector3.new(0, 1.45, 0)),
		0.3,
		2.5,
		Color3.fromRGB(204, 170, 120),
		Enum.Material.SmoothPlastic,
		false
	)
	makeCylinderY(
		parent,
		name .. "Soil",
		CFrame.new(base + Vector3.new(0, 1.42, 0)),
		0.12,
		2.0,
		PALETTE.barkDark,
		Enum.Material.Ground,
		false
	)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local cf = CFrame.new(base + Vector3.new(0, 1.5, 0))
			* CFrame.Angles(0, a, 0)
			* CFrame.Angles(math.rad(rnd(15, 35)), 0, 0)
			* CFrame.new(0, 0.9, 0)
		makeWedge(
			parent,
			name .. "Leaf",
			cf,
			Vector3.new(0.1, 1.9, 0.6),
			if i % 2 == 0 then color else PALETTE.teal,
			Enum.Material.SmoothPlastic,
			false
		)
	end
end

local function makeCrate(parent: Instance, name: string, cf: CFrame, s: number)
	makePart(
		parent,
		name,
		cf,
		Vector3.new(s, s, s),
		vary(PALETTE.woodLight, 0.04),
		Enum.Material.Wood,
		true
	)
	for _, y in { -0.32, 0.32 } do
		makePart(
			parent,
			name .. "Band",
			cf * CFrame.new(0, y * s, 0),
			Vector3.new(s + 0.08, 0.16 * s, s + 0.08),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	makePart(
		parent,
		name .. "X",
		cf * CFrame.new(0, 0, -s / 2 - 0.03) * CFrame.Angles(0, 0, math.rad(45)),
		Vector3.new(0.14 * s, s * 1.25, 0.06),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
end

local function makeBarrel(parent: Instance, name: string, base: Vector3, h: number)
	makeCylinderY(
		parent,
		name,
		CFrame.new(base + Vector3.new(0, h / 2, 0)),
		h,
		h * 0.72,
		vary(PALETTE.wood, 0.04),
		Enum.Material.Wood,
		true
	)
	makeCylinderY(
		parent,
		name .. "Belly",
		CFrame.new(base + Vector3.new(0, h / 2, 0)),
		h * 0.5,
		h * 0.78,
		vary(PALETTE.wood, 0.04),
		Enum.Material.Wood,
		false
	)
	for _, y in { 0.18, 0.82 } do
		makeCylinderY(
			parent,
			name .. "Hoop",
			CFrame.new(base + Vector3.new(0, h * y, 0)),
			0.14,
			h * 0.76,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
	end
	makeCylinderY(
		parent,
		name .. "Lid",
		CFrame.new(base + Vector3.new(0, h + 0.02, 0)),
		0.06,
		h * 0.62,
		PALETTE.woodLight,
		Enum.Material.Wood,
		false
	)
end

-- Life buoy (ring of segments) facing direction of cf's -Z.
local function makeBuoy(parent: Instance, name: string, cf: CFrame, radius: number)
	local segs = 10
	for i = 0, segs - 1 do
		local a = (i + 0.5) / segs * math.pi * 2
		local pcf = cf * CFrame.Angles(0, 0, a) * CFrame.new(radius, 0, 0)
		makePart(
			parent,
			name,
			pcf,
			Vector3.new(radius * 0.55, radius * 0.7, radius * 0.5),
			if i % 2 == 0 then PALETTE.red else PALETTE.white,
			Enum.Material.SmoothPlastic,
			false
		)
	end
end

-- Hanging fishing net: rope grid between two top points, hanging down.
local function makeNet(parent: Instance, name: string, a: Vector3, b: Vector3, depth: number)
	local cols = math.max(3, math.floor((b - a).Magnitude / 0.9))
	local rows = math.max(3, math.floor(depth / 0.9))
	for i = 0, cols do
		local t = i / cols
		local top = a:Lerp(b, t) - Vector3.new(0, 0.5 * math.sin(t * math.pi), 0)
		makeTube(
			parent,
			name,
			top,
			top - Vector3.new(0, depth * (1 - 0.25 * math.sin(t * math.pi)), 0),
			0.07,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
	end
	for r = 0, rows do
		local dy = depth * r / rows
		local prev: Vector3? = nil
		for i = 0, cols do
			local t = i / cols
			local p = a:Lerp(b, t)
				- Vector3.new(
					0,
					0.5 * math.sin(t * math.pi) + dy * (1 - 0.25 * math.sin(t * math.pi)),
					0
				)
			if prev then
				makeTube(parent, name, prev, p, 0.06, PALETTE.rope, Enum.Material.Fabric, false)
			end
			prev = p
		end
	end
end

-- Stairs: start = center of the lower/upper edge at the starting level (world),
-- dir = horizontal unit direction of travel, rise per step (+ up, - down).
local function makeStairs(
	parent: Instance,
	name: string,
	start: Vector3,
	dir: Vector3,
	width: number,
	count: number,
	rise: number,
	run: number,
	bottomY: number,
	color: Color3,
	material: Enum.Material?,
	noseColor: Color3?
): { Part }
	local steps: { Part } = {}
	local d = Vector3.new(dir.X, 0, dir.Z).Unit
	for i = 1, count do
		local top = start.Y + rise * i
		local hgt = math.max(top - bottomY, 0.4)
		local c = Vector3.new(start.X, 0, start.Z) + d * (run * (i - 0.5))
		local center = Vector3.new(c.X, top - hgt / 2, c.Z)
		local cf = CFrame.lookAt(center, center + d)
		local step = makePart(
			parent,
			name .. "Step" .. i,
			cf,
			Vector3.new(width, hgt, run + 0.02),
			vary(color, 0.025),
			material or Enum.Material.Slate,
			true
		)
		steps[i] = step
		if noseColor then
			local noseZ = if rise > 0 then run / 2 - 0.2 else -run / 2 + 0.2
			-- The edge that faces the lower step gets a light nose strip.
			makePart(
				parent,
				name .. "Nose",
				cf * CFrame.new(0, hgt / 2 + 0.02, noseZ),
				Vector3.new(width - 0.2, 0.06, 0.36),
				noseColor,
				Enum.Material.SmoothPlastic,
				false
			)
		end
	end
	return steps
end

-- Plank deck: cf at top surface center, planks run along local X, laid along local Z.
local function makePlankDeck(
	parent: Instance,
	name: string,
	cf: CFrame,
	sizeX: number,
	sizeZ: number,
	thickness: number,
	color: Color3?
): Part
	local base = makePart(
		parent,
		name,
		cf * CFrame.new(0, -thickness / 2, 0),
		Vector3.new(sizeX, thickness, sizeZ),
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	local count = math.max(1, math.floor(sizeZ / 1.05))
	local pitch = sizeZ / count
	for i = 1, count do
		local z = -sizeZ / 2 + pitch * (i - 0.5)
		local shrink = rnd(0, 0.35)
		makePart(
			parent,
			name .. "Plank",
			cf * CFrame.new(rnd(-0.1, 0.1), -0.04, z),
			Vector3.new(sizeX - shrink, 0.18, pitch - 0.12),
			vary(color or PALETTE.wood, 0.05),
			Enum.Material.Wood,
			false
		)
	end
	return base
end

-- Wooden bridge between two deck-top points (same or slightly different heights).
local function makeBridge(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	width: number,
	lanterns: boolean,
	railHeight: number?
)
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = flat.Magnitude
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, mid + flat.Unit) * CFrame.Angles(math.atan2(b.Y - a.Y, len), 0, 0)
	-- planks run across the bridge (local X)
	makePlankDeck(parent, name .. "Deck", cf, width, len + 0.4, 0.8, PALETTE.woodWarm)
	for _, side in { -1, 1 } do
		makePart(
			parent,
			name .. "Beam",
			cf * CFrame.new(side * (width / 2 + 0.2), -0.55, 0),
			Vector3.new(0.5, 0.8, len + 0.6),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	local rh = railHeight or 2.6
	local posts = math.max(2, math.floor(len / 3.6) + 1)
	local prevTop: { [number]: Vector3 } = {}
	for i = 0, posts - 1 do
		local t = i / (posts - 1)
		for _, side in { -1, 1 } do
			local p = (cf * CFrame.new(side * (width / 2 + 0.15), 0, len / 2 - t * len)).Position
			local top = p + Vector3.new(0, rh, 0)
			makeCylinderY(
				parent,
				name .. "Post",
				CFrame.new(p + Vector3.new(0, rh / 2 - 0.6, 0)),
				rh + 1.2,
				0.5,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			makeCylinderY(
				parent,
				name .. "Piling",
				CFrame.new(p - Vector3.new(0, 6.6, 0)),
				10.8,
				0.7,
				PALETTE.woodDark,
				Enum.Material.Wood,
				false
			)
			makeCylinderY(
				parent,
				name .. "PostCap",
				CFrame.new(top + Vector3.new(0, 0.1, 0)),
				0.2,
				0.62,
				PALETTE.wood,
				Enum.Material.Wood,
				false
			)
			makeCylinderY(
				parent,
				name .. "Knot",
				CFrame.new(top - Vector3.new(0, 0.35, 0)),
				0.35,
				0.62,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			local prev = prevTop[side]
			if prev then
				makeRope(
					parent,
					name .. "Rail",
					prev - Vector3.new(0, 0.35, 0),
					top - Vector3.new(0, 0.35, 0),
					0.45,
					0.24
				)
			end
			prevTop[side] = top
			if
				lanterns
				and (i == 0 or i == posts - 1 or (posts > 4 and i == math.floor(posts / 2)))
			then
				makeLanternBody(
					parent,
					name .. "Lantern",
					top + Vector3.new(0, 0.95, 0),
					0.75,
					side == 1
				)
			end
		end
	end
end

-- Gently arched wooden bridge (ref-5) with stone end posts, lanterns and rope rails.
local function makeArchBridge(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	width: number,
	rise: number
)
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = flat.Magnitude
	local d = flat.Unit
	local side = Vector3.new(-d.Z, 0, d.X)
	local n = 8
	local function at(t: number): Vector3
		return a:Lerp(b, t) + Vector3.new(0, rise * 4 * t * (1 - t), 0)
	end
	for i = 1, n do
		local p0 = at((i - 1) / n)
		local p1 = at(i / n)
		local mid = (p0 + p1) / 2
		local seg = Vector3.new(p1.X - p0.X, 0, p1.Z - p0.Z).Magnitude
		local cf = CFrame.lookAt(mid, mid + d) * CFrame.Angles(math.atan2(p1.Y - p0.Y, seg), 0, 0)
		makePlankDeck(parent, name .. "Deck", cf, width, seg + 0.12, 0.7, PALETTE.woodWarm)
		for _, sd in { -1, 1 } do
			makePart(
				parent,
				name .. "Beam",
				cf * CFrame.new(sd * (width / 2 + 0.22), -0.5, 0),
				Vector3.new(0.5, 0.8, seg + 0.15),
				PALETTE.woodDark,
				Enum.Material.Wood,
				false
			)
		end
	end
	local posts = 5
	local prevTop: { [number]: Vector3 } = {}
	for i = 0, posts - 1 do
		local t = i / (posts - 1)
		local base = at(t)
		for _, sd in { -1, 1 } do
			local p = base + side * sd * (width / 2 + 0.35)
			local isEnd = i == 0 or i == posts - 1
			local top: Vector3
			if isEnd then
				-- stone post with lantern on top
				makePart(
					parent,
					name .. "StonePost",
					CFrame.new(p + Vector3.new(0, 1.0, 0)),
					Vector3.new(1.3, 3.0, 1.3),
					vary(PALETTE.stoneGray, 0.03),
					Enum.Material.Slate,
					true
				)
				makePart(
					parent,
					name .. "StoneCap",
					CFrame.new(p + Vector3.new(0, 2.6, 0)),
					Vector3.new(1.6, 0.3, 1.6),
					PALETTE.stoneGrayDark,
					Enum.Material.Slate,
					false
				)
				makeLanternBody(
					parent,
					name .. "Lantern",
					p + Vector3.new(0, 3.45, 0),
					0.8,
					sd == 1
				)
				top = p + Vector3.new(0, 2.2, 0)
			else
				makeCylinderY(
					parent,
					name .. "Post",
					CFrame.new(p + Vector3.new(0, 0.7, 0)),
					2.6,
					0.5,
					PALETTE.woodDark,
					Enum.Material.Wood,
					true
				)
				makeCylinderY(
					parent,
					name .. "Knot",
					CFrame.new(p + Vector3.new(0, 1.65, 0)),
					0.3,
					0.62,
					PALETTE.rope,
					Enum.Material.Fabric,
					false
				)
				top = p + Vector3.new(0, 1.65, 0)
				if i == 2 then
					makeLanternBody(
						parent,
						name .. "MidLantern",
						p + Vector3.new(0, 2.6, 0),
						0.65,
						false
					)
				end
			end
			makeCylinderY(
				parent,
				name .. "Piling",
				CFrame.new(p - Vector3.new(0, 5.8, 0)),
				10,
				0.7,
				PALETTE.woodDark,
				Enum.Material.Wood,
				false
			)
			local prev = prevTop[sd]
			if prev then
				makeRope(parent, name .. "Rail", prev, top, 0.5, 0.26)
			end
			prevTop[sd] = top
		end
	end
end

---------------------------------------------------------------------------------------
-- Shared builders used by several regions
---------------------------------------------------------------------------------------

-- Flat ring band lying on a horizontal plane (cf = center at the band's vertical center).
local function flatRing(
	parent: Instance,
	name: string,
	cf: CFrame,
	radius: number,
	width: number,
	height: number,
	segments: number,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	skipFrom: number?,
	skipTo: number?
)
	local seg = 2 * math.pi * radius / segments * 1.06
	for i = 0, segments - 1 do
		local deg = (i + 0.5) / segments * 360
		local skip = skipFrom ~= nil and skipTo ~= nil and deg >= skipFrom and deg <= skipTo
		if not skip then
			-- angle convention: x = cos(a), z = sin(a)
			local a = math.rad(deg)
			local pos = cf * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius)
			local pcf = CFrame.lookAt(
				pos.Position,
				pos.Position + Vector3.new(-math.sin(a), 0, math.cos(a))
			)
			makePart(
				parent,
				name,
				pcf,
				Vector3.new(width, height, seg),
				color,
				material or Enum.Material.Slate,
				canCollide
			)
		end
	end
end

-- Simple rune glyph (2-3 neon bars) flat on a surface; cf = glyph center on the surface.
local function makeRune(parent: Instance, name: string, cf: CFrame, s: number, color: Color3)
	local kind = rndInt(1, 5)
	local function bar(x: number, z: number, len: number, rot: number)
		makePart(
			parent,
			name,
			cf * CFrame.new(x * s, 0, z * s) * CFrame.Angles(0, math.rad(rot), 0),
			Vector3.new(0.1 * s, 0.05, len * s),
			color,
			Enum.Material.Neon,
			false,
			0.2
		)
	end
	if kind == 1 then
		bar(0, 0, 1.4, 0)
		bar(0, -0.3, 0.9, 50)
		bar(0, 0.3, 0.9, -50)
	elseif kind == 2 then
		bar(-0.3, 0, 1.4, 0)
		bar(0.3, 0, 1.4, 0)
		bar(0, 0, 0.7, 90)
	elseif kind == 3 then
		bar(0, 0, 1.4, 35)
		bar(0, 0, 1.4, -35)
	elseif kind == 4 then
		bar(0, -0.45, 0.9, 90)
		bar(0, 0.45, 0.9, 90)
		bar(0, 0, 1.0, 0)
	else
		bar(-0.25, 0, 1.2, 15)
		bar(0.25, 0, 1.2, -15)
		bar(0, -0.5, 0.6, 90)
	end
end

local function makeBench(parent: Instance, name: string, cf: CFrame)
	makePart(
		parent,
		name .. "Seat",
		cf * CFrame.new(0, 1.2, 0),
		Vector3.new(5, 0.35, 1.5),
		PALETTE.woodLight,
		Enum.Material.Wood,
		true
	)
	for _, z in { -0.4, 0.4 } do
		makePart(
			parent,
			name .. "Slat",
			cf * CFrame.new(0, 1.39, z),
			Vector3.new(5.05, 0.05, 0.55),
			PALETTE.woodWarm,
			Enum.Material.Wood,
			false
		)
	end
	makePart(
		parent,
		name .. "Back",
		cf * CFrame.new(0, 2.3, 0.75) * CFrame.Angles(math.rad(-12), 0, 0),
		Vector3.new(5, 1.2, 0.25),
		PALETTE.woodLight,
		Enum.Material.Wood,
		false
	)
	for _, x in { -2.1, 2.1 } do
		makePart(
			parent,
			name .. "Leg",
			cf * CFrame.new(x, 0.55, 0),
			Vector3.new(0.35, 1.1, 1.3),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makePart(
			parent,
			name .. "BackLeg",
			cf * CFrame.new(x, 1.9, 0.72),
			Vector3.new(0.3, 1.6, 0.25),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
end

local function makeStump(parent: Instance, name: string, base: Vector3, h: number)
	makeCylinderY(
		parent,
		name,
		CFrame.new(base + Vector3.new(0, h / 2, 0)),
		h,
		1.7,
		PALETTE.bark,
		Enum.Material.Wood,
		true
	)
	makeCylinderY(
		parent,
		name .. "Top",
		CFrame.new(base + Vector3.new(0, h + 0.02, 0)),
		0.06,
		1.5,
		PALETTE.woodLight,
		Enum.Material.Wood,
		false
	)
	makeCylinderY(
		parent,
		name .. "Ring",
		CFrame.new(base + Vector3.new(0, h + 0.05, 0)),
		0.03,
		0.8,
		PALETTE.wood,
		Enum.Material.Wood,
		false
	)
end

local function makeCampfire(parent: Instance, name: string, base: Vector3)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		makeEllipsoid(
			parent,
			name .. "Stone",
			CFrame.new(base + Vector3.new(math.cos(a) * 1.8, 0.3, math.sin(a) * 1.8))
				* CFrame.Angles(0, a, 0),
			Vector3.new(1.1, 0.7, 0.9),
			vary(PALETTE.stoneMid, 0.05),
			Enum.Material.Slate
		)
	end
	makeCylinderY(
		parent,
		name .. "Ash",
		CFrame.new(base + Vector3.new(0, 0.05, 0)),
		0.1,
		3.2,
		Color3.fromRGB(70, 60, 60),
		Enum.Material.Slate,
		false
	)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		local foot = base + Vector3.new(math.cos(a) * 1.2, 0.1, math.sin(a) * 1.2)
		makeTube(
			parent,
			name .. "Log",
			foot,
			base + Vector3.new(0, 1.6, 0),
			0.4,
			PALETTE.barkDark,
			Enum.Material.Wood,
			false
		)
	end
	local flame = makeEllipsoid(
		parent,
		name .. "Flame",
		CFrame.new(base + Vector3.new(0, 1.1, 0)),
		Vector3.new(1.6, 2.4, 1.6),
		PALETTE.flame,
		Enum.Material.Neon,
		0.15
	)
	makeEllipsoid(
		parent,
		name .. "FlameCore",
		CFrame.new(base + Vector3.new(0, 0.9, 0)),
		Vector3.new(0.9, 1.6, 0.9),
		PALETTE.flameCore,
		Enum.Material.Neon,
		0.05
	)
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 8
	fire.Color = PALETTE.flame
	fire.SecondaryColor = PALETTE.flameCore
	fire.Parent = flame
	stats.emitters += 1
	addLight(flame, PALETTE.flame, 18, 1.6)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE_TEXTURE
	e.Color = ColorSequence.new(PALETTE.flameCore, PALETTE.flame)
	e.LightEmission = 1
	e.Rate = 6
	e.Lifetime = NumberRange.new(1.2, 2)
	e.Speed = NumberRange.new(2, 4)
	e.SpreadAngle = Vector2.new(20, 20)
	e.Acceleration = Vector3.new(0, 1, 0)
	e.Size = NumberSequence.new(0.25, 0)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = flame
	stats.emitters += 1
end

-- Stone basin with water and a large central crystal (plaza centerpiece).
local function makeCrystalFountain(parent: Instance, name: string, base: Vector3)
	flatRing(
		parent,
		name .. "Basin",
		CFrame.new(base + Vector3.new(0, 0.45, 0)),
		3.6,
		1.1,
		0.9,
		18,
		PALETTE.stoneMid,
		Enum.Material.Slate,
		true
	)
	flatRing(
		parent,
		name .. "BasinCap",
		CFrame.new(base + Vector3.new(0, 0.93, 0)),
		3.6,
		1.3,
		0.12,
		18,
		PALETTE.stoneWarm,
		Enum.Material.Slate,
		false
	)
	makeCylinderY(
		parent,
		name .. "Water",
		CFrame.new(base + Vector3.new(0, 0.6, 0)),
		0.3,
		6.6,
		PALETTE.water,
		Enum.Material.Glass,
		false,
		0.25
	)
	makeCylinderY(
		parent,
		name .. "Pedestal",
		CFrame.new(base + Vector3.new(0, 1.2, 0)),
		2.0,
		2.2,
		PALETTE.stone,
		Enum.Material.Slate,
		true
	)
	makeCylinderY(
		parent,
		name .. "PedestalTop",
		CFrame.new(base + Vector3.new(0, 2.25, 0)),
		0.2,
		2.8,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false
	)
	makeCrystalCluster(
		parent,
		name .. "Crystal",
		base + Vector3.new(0, 2.6, 0),
		1.25,
		PALETTE.crystalCyan,
		true,
		PALETTE.crystalLilac
	)
	makeNeonRing(
		parent,
		name .. "Glow",
		CFrame.new(base + Vector3.new(0, 0.78, 0)),
		2.6,
		0.2,
		16,
		PALETTE.cyan,
		0.45
	)
	local sparkle = makePart(
		parent,
		name .. "Sparkles",
		CFrame.new(base + Vector3.new(0, 4.5, 0)),
		Vector3.new(3, 3, 3),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	addSparkles(sparkle, PALETTE.crystalCyan, 5, 0.5, 1.2)
end

-- Arrow sign board pointing along `dir` (horizontal), text readable from both sides.
local function makeArrowSign(
	parent: Instance,
	name: string,
	center: Vector3,
	dir: Vector3,
	w: number,
	h: number,
	text: string,
	sub: string?
)
	local d = Vector3.new(dir.X, 0, dir.Z).Unit
	local side = Vector3.new(-d.Z, 0, d.X)
	local cf = CFrame.lookAt(center, center + side)
	makeSign(
		parent,
		name,
		cf,
		w,
		h,
		text,
		sub,
		PALETTE.signWood,
		PALETTE.signText,
		PALETTE.goldLight,
		PALETTE.woodDark,
		true
	)
	-- Arrow tip at the pointing end (two wedges forming a triangle).
	local tip = center + d * (w / 2 + 0.55)
	local tcf = CFrame.lookAt(tip, tip + d)
	makeWedge(
		parent,
		name .. "Tip",
		tcf * CFrame.new(0, h / 4, 0) * CFrame.Angles(0, 0, math.pi),
		Vector3.new(0.4, h / 2 + 0.2, 1.2),
		PALETTE.signWood,
		Enum.Material.Wood,
		false
	)
	makeWedge(
		parent,
		name .. "Tip",
		tcf * CFrame.new(0, -h / 4, 0),
		Vector3.new(0.4, h / 2 + 0.2, 1.2),
		PALETTE.signWood,
		Enum.Material.Wood,
		false
	)
end

---------------------------------------------------------------------------------------
-- Region: central plaza (+ campfire rest deck, rune path, signposts)
---------------------------------------------------------------------------------------

local function buildPlaza(root: Instance)
	local m = makeModel(root, "Plaza")
	local Y = PLAZA_Y

	-- Floor slab: X -30..18, Z -22..24, top exactly at Y 10.3.
	-- (deep slab: terrain stays well below it; the base colour shows as dark joints)
	makePart(
		m,
		"PlazaFloor",
		C(-6, Y - 2.65, 1),
		Vector3.new(48, 5.3, 46),
		PALETTE.stoneJoint,
		Enum.Material.Slate,
		true
	)
	-- Skirt (darker stone lip visible from the grass).
	for _, s in
		{
			{ -6, -22.15, 48.3, 0.3 },
			{ -6, 24.15, 48.3, 0.3 },
		}
	do
		makePart(
			m,
			"PlazaSkirt",
			C(s[1], Y - 3.3, s[2]),
			Vector3.new(s[3], 4.4, s[4]),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			false
		)
	end
	for _, x in { -30.15, 18.15 } do
		makePart(
			m,
			"PlazaSkirt",
			C(x, Y - 3.3, 1),
			Vector3.new(0.3, 4.4, 46.3),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			false
		)
	end
	-- Stone slabs (4-stud grid) in 4 warm tones; the dark base shows as joints.
	local tones =
		{ PALETTE.stone, PALETTE.stoneWarm, PALETTE.stoneLight, PALETTE.stoneMid, PALETTE.stone }
	local pz = 46 / 12
	for ix = 0, 11 do
		for iz = 0, 11 do
			local x = -30 + 4 * (ix + 0.5)
			local z = -22 + pz * (iz + 0.5)
			makePart(
				m,
				"Slab",
				C(x + rnd(-0.04, 0.04), Y + 0.01, z),
				Vector3.new(4 - rnd(0.14, 0.24), 0.1, pz - rnd(0.14, 0.24)),
				vary(tones[rndInt(1, #tones)], 0.025),
				Enum.Material.Slate,
				false
			)
		end
	end
	-- Round inlay: disc + rings + radial lines.
	makeCylinderY(
		m,
		"Inlay",
		C(-6, Y + 0.07, 1),
		0.08,
		31,
		PALETTE.stoneWarm,
		Enum.Material.Slate,
		false
	)
	flatRing(
		m,
		"InlayRing",
		C(-6, Y + 0.115, 1),
		15.2,
		0.9,
		0.04,
		48,
		PALETTE.stoneDark,
		Enum.Material.Slate,
		false
	)
	flatRing(
		m,
		"InlayRing",
		C(-6, Y + 0.115, 1),
		9.5,
		0.6,
		0.04,
		36,
		PALETTE.stoneMid,
		Enum.Material.Slate,
		false
	)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local p = V(-6 + math.cos(a) * 12.3, Y + 0.115, 1 + math.sin(a) * 12.3)
		makePart(
			m,
			"InlayRay",
			CFrame.lookAt(p, p + Vector3.new(math.cos(a), 0, math.sin(a))),
			Vector3.new(0.35, 0.04, 4.2),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			false
		)
	end
	makeCrystalFountain(m, "CentralCrystal", V(-6, Y, -2))
	task.wait()

	-- Campfire rest deck (around the contract fire at (-16, 10.3, 11)).
	local deckTop = Y + 0.3
	makePlankDeck(m, "RestDeck", C(-17, deckTop, 11), 12, 12, 0.6, PALETTE.woodWarm)
	for _, e in { { -17, 4.9, 12.2, 0.3 }, { -17, 17.1, 12.2, 0.3 } } do
		makePart(
			m,
			"RestDeckEdge",
			C(e[1], deckTop - 0.25, e[2]),
			Vector3.new(e[3], 0.5, e[4]),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	makePart(
		m,
		"RestDeckEdge",
		C(-23.1, deckTop - 0.25, 11),
		Vector3.new(0.3, 0.5, 12.2),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"RestDeckEdge",
		C(-10.9, deckTop - 0.25, 11),
		Vector3.new(0.3, 0.5, 12.2),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeCampfire(m, "Campfire", V(FIRE_POS.X, deckTop, FIRE_POS.Z))
	for i, a in { 40, 140, 220, 320 } do
		local r = math.rad(a)
		makeStump(
			m,
			"Stump" .. i,
			V(FIRE_POS.X + math.cos(r) * 4, deckTop, FIRE_POS.Z + math.sin(r) * 4),
			rnd(1.0, 1.3)
		)
	end
	makeBench(m, "RestBench", CY(-17, deckTop, 15.8, 0))
	-- Rope fence on south and west edges.
	local fence = {
		V(-11.4, deckTop, 16.6),
		V(-15.4, deckTop, 16.6),
		V(-19.4, deckTop, 16.6),
		V(-22.6, deckTop, 16.6),
		V(-22.6, deckTop, 12.6),
		V(-22.6, deckTop, 8.6),
		V(-22.6, deckTop, 5.4),
	}
	for i, p in fence do
		makeCylinderY(
			m,
			"FencePost",
			CFrame.new(p + Vector3.new(0, 1.0, 0)),
			2.0,
			0.45,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeCylinderY(
			m,
			"FenceKnot",
			CFrame.new(p + Vector3.new(0, 1.55, 0)),
			0.3,
			0.6,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
		if i > 1 then
			makeRope(
				m,
				"FenceRope",
				fence[i - 1] + Vector3.new(0, 1.55, 0),
				p + Vector3.new(0, 1.55, 0),
				0.35,
				0.2
			)
		end
	end
	-- Gallows lantern post with hanging lantern and bunting across the deck.
	do
		local post = V(-22.6, deckTop, 16.6)
		makeCylinderY(
			m,
			"LampPost",
			CFrame.new(post + Vector3.new(0, 3.5, 0)),
			7,
			0.6,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeSegment(
			m,
			"LampArm",
			post + Vector3.new(0, 6.6, 0),
			post + Vector3.new(2.6, 6.6, -2.6),
			0.4,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeSegment(
			m,
			"LampBrace",
			post + Vector3.new(0, 5.2, 0),
			post + Vector3.new(1.5, 6.6, -1.5),
			0.3,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeTube(
			m,
			"LampWrap",
			post + Vector3.new(0, 4.2, 0),
			post + Vector3.new(0, 5.0, 0),
			0.75,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
		makeTube(
			m,
			"LampChain",
			post + Vector3.new(2.4, 6.5, -2.4),
			post + Vector3.new(2.4, 5.6, -2.4),
			0.1,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeLanternBody(m, "RestLantern", post + Vector3.new(2.4, 4.8, -2.4), 1, true)
		local post2 = V(-11.4, deckTop, 16.6)
		makeCylinderY(
			m,
			"BuntingPole",
			CFrame.new(post2 + Vector3.new(0, 3, 0)),
			6,
			0.45,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeBunting(
			m,
			"RestBunting",
			post + Vector3.new(0, 6.3, 0),
			post2 + Vector3.new(0, 5.8, 0),
			0.9
		)
		makeLantern(m, "RestDeckLantern", V(-11.6, deckTop, 5.4), 3.2, true)
		makePlanter(m, "RestPlanter", V(-20.6, deckTop, 6.4), PALETTE.crystalPink)
	end
	task.wait()

	-- Rune path from the rest deck to the Training Sanctuary landing.
	local path = {
		Vector3.new(-20.5, 0, 4.6),
		Vector3.new(-24, 0, -5.6),
		Vector3.new(-27.4, 0, -14.6),
		Vector3.new(-30.05, 0, -21.6),
	}
	for i = 1, #path - 1 do
		local a = V(path[i].X, Y + 0.12, path[i].Z)
		local b = V(path[i + 1].X, Y + 0.12, path[i + 1].Z)
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		makePart(
			m,
			"RunePath",
			cf,
			Vector3.new(3.4, 0.08, len + 3.3),
			PALETTE.slateInlay,
			Enum.Material.Slate,
			false
		)
		for _, sx in { -1.55, 1.55 } do
			makePart(
				m,
				"RunePathEdge",
				cf * CFrame.new(sx, 0.05, 0),
				Vector3.new(0.1, 0.05, len + 2.6),
				PALETTE.cyan,
				Enum.Material.Neon,
				false,
				0.25
			)
		end
		local count = math.floor(len / 2.4)
		for k = 0, count - 1 do
			local t = (k + 0.5) / count
			makeRune(
				m,
				"RuneGlyph",
				CFrame.lookAt(a:Lerp(b, t) + Vector3.new(0, 0.05, 0), b),
				0.9,
				PALETTE.cyan
			)
		end
	end

	-- Big arrow sign toward the Apprentice portal bridge.
	makeCylinderY(
		m,
		"AprendizSignPost",
		C(-28.4, Y + 2.6, -10.4),
		5.2,
		0.6,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	makeArrowSign(
		m,
		"AprendizArrow",
		V(-28.4, Y + 4.1, -10.4),
		Vector3.new(-1, 0, 0.35),
		6.4,
		1.9,
		"ILHA DO APRENDIZ",
		"Grátis · Comece aqui!"
	)
	makeArrowSign(
		m,
		"SanctuaryArrow",
		V(-28.4, Y + 2.2, -10.4),
		Vector3.new(-0.4, 0, -1),
		5.2,
		1.3,
		"SANTUÁRIO DO TREINO",
		nil
	)
	-- Multi-direction signpost near the spawn.
	makeCylinderY(
		m,
		"SignPost",
		C(4.5, Y + 2.8, 9),
		5.6,
		0.55,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	makeArrowSign(
		m,
		"PierArrow",
		V(4.5, Y + 4.6, 9),
		Vector3.new(1, 0, 0),
		4.6,
		1.1,
		"PÍER DE PESCA",
		nil
	)
	makeArrowSign(
		m,
		"WharfArrow",
		V(4.5, Y + 3.4, 9),
		Vector3.new(0.5, 0, 1),
		4.6,
		1.1,
		"CAIS DAS EXPEDIÇÕES",
		nil
	)
	makeArrowSign(
		m,
		"WorkshopArrow",
		V(4.5, Y + 2.2, 9),
		Vector3.new(0, 0, -1),
		4.6,
		1.1,
		"OFICINA DE VARAS",
		nil
	)
	makeBall(m, "SignPostKnob", V(4.5, Y + 5.75, 9), 0.8, PALETTE.gold, Enum.Material.SmoothPlastic)

	-- Perimeter lanterns, planters and benches (kept away from every exit).
	for _, p in
		{
			{ -29.3, -12.8 },
			{ -28.6, 0.6 },
			{ -28.6, 15.6 },
			{ -17.2, 22.6 },
			{ 5.2, 22.6 },
			{ 17, 19.2 },
			{ 17, -0.8 },
			{ 17, -12.5 },
			{ 16, -20.6 },
			{ -17.6, -15 },
			{ 5.6, -15 },
		}
	do
		makeLantern(m, "PlazaLantern", V(p[1], Y, p[2]), 4.6, true)
	end
	makeBunting(m, "WorkshopBunting", V(-17.6, Y + 5.6, -15), V(5.6, Y + 5.6, -15), 1.4)
	makeBunting(m, "PlazaBuntingE", V(17, Y + 5.6, -0.8), V(17, Y + 5.6, -12.5), 0.9)
	makeBunting(m, "PlazaBuntingW", V(-28.6, Y + 5.6, 0.6), V(-28.6, Y + 5.6, 15.6), 1.0)
	for _, p in
		{
			{ 8.8, 22.4 },
			{ 15.4, -17.8 },
			{ -26.2, 20.6 },
			{ 8.6, -18.8 },
			{ -12.5, 22.2 },
			{ 0.6, -18.6 },
		}
	do
		makePlanter(
			m,
			"PlazaPlanter",
			V(p[1], Y, p[2]),
			if p[1] > 0 then PALETTE.crystalCyan else PALETTE.crystalPink
		)
	end
	-- Second rest deck right beside the Training Sanctuary gate (ref-1).
	do
		local dt = Y + 0.3
		makePlankDeck(m, "GateRestDeck", C(-22.5, dt, -18.3), 6, 5.6, 0.6, PALETTE.woodWarm)
		local bowl = V(-22.3, dt, -18.0)
		makeCylinderY(
			m,
			"BrazierBase",
			CFrame.new(bowl + Vector3.new(0, 0.45, 0)),
			0.9,
			1.4,
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		makeCylinderY(
			m,
			"BrazierBowl",
			CFrame.new(bowl + Vector3.new(0, 1.05, 0)),
			0.4,
			2.2,
			PALETTE.stoneDark,
			Enum.Material.Slate,
			false
		)
		local f = makeEllipsoid(
			m,
			"BrazierFlame",
			CFrame.new(bowl + Vector3.new(0, 1.7, 0)),
			Vector3.new(1.2, 1.6, 1.2),
			PALETTE.flame,
			Enum.Material.Neon,
			0.2
		)
		makeEllipsoid(
			m,
			"BrazierCore",
			CFrame.new(bowl + Vector3.new(0, 1.55, 0)),
			Vector3.new(0.6, 1.0, 0.6),
			PALETTE.flameCore,
			Enum.Material.Neon,
			0.05
		)
		addLight(f, PALETTE.flame, 14, 1.2)
		local fire = Instance.new("Fire")
		fire.Size = 2.5
		fire.Heat = 6
		fire.Color = PALETTE.flame
		fire.SecondaryColor = PALETTE.flameCore
		fire.Parent = f
		stats.emitters += 1
		makeStump(m, "GateStump", V(-24.3, dt, -16.9), 1.1)
		makeStump(m, "GateStump", V(-20.3, dt, -16.6), 1.0)
		makeBench(m, "GateBench", CY(-22.5, dt, -20.2, 180))
		local post = V(-25.3, dt, -15.7)
		makeCylinderY(
			m,
			"GateLampPost",
			CFrame.new(post + Vector3.new(0, 3.2, 0)),
			6.4,
			0.55,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeSegment(
			m,
			"GateLampArm",
			post + Vector3.new(0, 6.1, 0),
			post + Vector3.new(2.2, 6.1, 0),
			0.35,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeTube(
			m,
			"GateLampWrap",
			post + Vector3.new(0, 4.0, 0),
			post + Vector3.new(0, 4.8, 0),
			0.7,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
		makeLanternBody(m, "GateRestLantern", post + Vector3.new(2.0, 5.0, 0), 0.9, true)
		makeBunting(
			m,
			"GateRestBunting",
			post + Vector3.new(0, 5.9, 0),
			V(-31.9, Y + 6.6, -16.3),
			0.8
		)
		for _, p in { V(-25.3, dt, -20.9), V(-19.7, dt, -20.9) } do
			makeCylinderY(
				m,
				"GateDeckPost",
				CFrame.new(p + Vector3.new(0, 0.9, 0)),
				1.8,
				0.4,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
		end
		makeRope(m, "GateDeckRope", V(-25.3, dt + 1.5, -15.7), V(-25.3, dt + 1.5, -20.9), 0.3, 0.2)
		makeRope(m, "GateDeckRope", V(-25.3, dt + 1.5, -20.9), V(-19.7, dt + 1.5, -20.9), 0.3, 0.2)
	end
	makeBunting(m, "PlazaBuntingS", V(-17.2, Y + 5.6, 22.6), V(-28.6, Y + 5.6, 15.6), 1.0)
	makeBunting(m, "PlazaBuntingSE", V(5.2, Y + 5.6, 22.6), V(17, Y + 5.6, 19.2), 0.9)
	makeBunting(m, "PlazaBuntingNE", V(17, Y + 5.6, -12.5), V(16, Y + 5.6, -20.6), 0.6)
	makeBunting(m, "PlazaBuntingN", V(5.6, Y + 5.6, -15), V(16, Y + 5.6, -20.6), 0.8)
	makeBench(m, "PlazaBench", CY(8.5, Y, -6, 90))
	makeBench(m, "PlazaBench", CY(8.5, Y, 4, 90))
	makeBench(m, "PlazaBench", CY(-20, Y, -5, -90 + 25))
	task.wait()

	-- Bushes, tufts and flowers along the outer plaza edge (on the grass).
	for i = 1, 40 do
		local side = rndInt(1, 4)
		local x: number, z: number = 0, 0
		if side == 1 then
			x, z = rnd(-29, 17), -23.2
		elseif side == 2 then
			x, z = rnd(-29, 17), 25.3
		elseif side == 3 then
			x, z = -31.2, rnd(-21, 23)
		else
			x, z = 19.2, rnd(-21, 23)
		end
		local exits = (side == 2 and ((x > -15.5 and x < 4) or (x > 9 and x < 19) or (x < -23)))
			or (side == 4 and z > -1 and z < 17)
			or (side == 3 and (z < -16 or (z > -11 and z < 0) or z > 20))
			or (side == 1 and ((x > -17 and x < 5) or x < -26))
		if not exits then
			local g = groundY(x, z)
			if g > 6.5 then
				if i % 3 == 0 then
					makeBush(m, "EdgeBush", V(x, g, z), rnd(0.8, 1.1))
				else
					makeTuft(m, "EdgeTuft", V(x, g, z), rnd(0.8, 1.2), PALETTE.leaf)
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------
-- Region: Workshop (Oficina de Varas)
---------------------------------------------------------------------------------------

local function buildWorkshop(root: Instance)
	local m = makeModel(root, "Workshop")
	local T = TERRACE_Y

	-- Terrace deck X -26..14, Z -48..-22 at Y 14.3.
	makePlankDeck(m, "Terrace", C(-6, T, -35), 40, 26, 1.0, PALETTE.wood)
	makePart(
		m,
		"TerraceWall",
		C(-6, (8.4 + T - 1) / 2, -22.75),
		Vector3.new(40.6, T - 1 - 8.4, 1.6),
		PALETTE.stoneMid,
		Enum.Material.Cobblestone,
		true
	)
	for _, x in { -26.6, 14.6 } do
		makePart(
			m,
			"TerraceWall",
			C(x, (8.4 + T - 1) / 2, -35),
			Vector3.new(1.2, T - 1 - 8.4, 27),
			PALETTE.stoneMid,
			Enum.Material.Cobblestone,
			true
		)
	end
	makePart(
		m,
		"TerraceLip",
		C(-6, T - 0.95, -21.9),
		Vector3.new(40.8, 0.3, 0.4),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)

	-- Stairs plaza (10.3) -> terrace (14.3): 8 steps of 0.5.
	makeStairs(
		m,
		"WorkshopStairs",
		V(-6, PLAZA_Y, -14),
		Vector3.new(0, 0, -1),
		20,
		8,
		0.5,
		1,
		PLAZA_Y - 1.5,
		PALETTE.stone,
		Enum.Material.Slate,
		PALETTE.stoneWarm
	)
	for _, x in { -16.6, 4.6 } do
		for i = 1, 8 do
			local top = PLAZA_Y + 0.5 * i + 0.7
			makePart(
				m,
				"StairCheek",
				C(x, (PLAZA_Y - 1 + top) / 2, -14.5 - (i - 1)),
				Vector3.new(1.2, top - PLAZA_Y + 1, 1.02),
				PALETTE.stoneMid,
				Enum.Material.Slate,
				true
			)
		end
		makeStoneLantern(m, "StairLantern", V(x, T, -23.4), true)
	end

	-- House frame: back wall Z -47, side walls X -20 / 8, open front with counter.
	local wallH = 8.4
	makePart(
		m,
		"BackWall",
		C(-6, T + wallH / 2, -47),
		Vector3.new(29, wallH, 1),
		PALETTE.woodLight,
		Enum.Material.Wood,
		true
	)
	for k = 0, 6 do
		makePart(
			m,
			"BackWallBoard",
			C(-6, T + 0.6 + k * 1.2, -46.45),
			Vector3.new(28.6, 0.12, 0.1),
			PALETTE.wood,
			Enum.Material.Wood,
			false
		)
	end
	for _, x in { -20, 8 } do
		makePart(
			m,
			"SideWall",
			C(x, T + wallH / 2, -41),
			Vector3.new(1, wallH, 11.6),
			PALETTE.woodLight,
			Enum.Material.Wood,
			true
		)
		makePart(
			m,
			"SideWallLow",
			C(x, T + 1.1, -36.2),
			Vector3.new(1, 2.2, 2.4),
			PALETTE.wood,
			Enum.Material.Wood,
			true
		)
		for _, z in { -47, -34.5 } do
			makeCylinderY(
				m,
				"Log",
				C(x, T + 5.2, z),
				10.4,
				2.4,
				PALETTE.bark,
				Enum.Material.Wood,
				true
			)
			makeCylinderY(
				m,
				"LogBand",
				C(x, T + 2.0, z),
				0.45,
				2.6,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			makeCylinderY(
				m,
				"LogBand",
				C(x, T + 2.6, z),
				0.45,
				2.6,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
		end
	end
	makeTube(
		m,
		"FrontBeam",
		V(-21.4, T + 9.6, -34.5),
		V(9.4, T + 9.6, -34.5),
		1.9,
		PALETTE.bark,
		Enum.Material.Wood,
		false
	)
	makeTube(
		m,
		"BackBeam",
		V(-21.4, T + 9.6, -47),
		V(9.4, T + 9.6, -47),
		1.9,
		PALETTE.bark,
		Enum.Material.Wood,
		false
	)
	for _, x in { -21.4, 9.4 } do
		makeCylinderY(
			m,
			"BeamEnd",
			C(x + (if x < 0 then -0.06 else 0.06), T + 9.6, -34.5)
				* CFrame.Angles(0, 0, math.pi / 2),
			0.1,
			1.7,
			PALETTE.woodLight,
			Enum.Material.Wood,
			false
		)
	end
	for _, x in { -20, 8 } do
		makeTube(
			m,
			"SideBeam",
			V(x, T + 9.6, -48),
			V(x, T + 9.6, -33.2),
			1.6,
			PALETTE.bark,
			Enum.Material.Wood,
			false
		)
	end

	-- Counter (WorkshopSpot sits on it at (-6, 15.5, -38)).
	makePart(
		m,
		"Counter",
		C(-6, T + 0.6, -37.5),
		Vector3.new(20, 1.2, 2),
		PALETTE.wood,
		Enum.Material.Wood,
		true
	)
	makePart(
		m,
		"CounterTop",
		C(-6, T + 1.28, -37.5),
		Vector3.new(20.6, 0.16, 2.5),
		PALETTE.woodLight,
		Enum.Material.Wood,
		false
	)
	for k = 0, 9 do
		makePart(
			m,
			"CounterPanel",
			C(-15 + k * 2, T + 0.6, -36.47),
			Vector3.new(1.8, 1.0, 0.06),
			vary(PALETTE.woodWarm, 0.04),
			Enum.Material.Wood,
			false
		)
	end
	makePart(
		m,
		"CounterBadge",
		C(-6, T + 0.65, -36.42),
		Vector3.new(3.4, 0.7, 0.08),
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false
	)
	-- Items on the counter.
	makeCylinderY(
		m,
		"Jar",
		C(-13, T + 1.75, -37.6),
		0.8,
		0.8,
		PALETTE.crystalCyan,
		Enum.Material.Glass,
		false,
		0.3
	)
	makeCylinderY(
		m,
		"JarLid",
		C(-13, T + 2.2, -37.6),
		0.15,
		0.85,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"ToolBox",
		C(1.5, T + 1.7, -37.7),
		Vector3.new(1.6, 0.7, 0.9),
		PALETTE.red,
		Enum.Material.SmoothPlastic,
		false
	)
	makePart(
		m,
		"ToolBoxHandle",
		C(1.5, T + 2.15, -37.7),
		Vector3.new(0.9, 0.12, 0.15),
		PALETTE.metal,
		Enum.Material.Metal,
		false
	)
	makeTube(
		m,
		"RodOnCounter",
		V(-10.5, T + 1.45, -37.9),
		V(-2.5, T + 1.45, -37.2),
		0.14,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeCylinderY(
		m,
		"RodReel",
		C(-9.6, T + 1.6, -37.85),
		0.3,
		0.55,
		PALETTE.gold,
		Enum.Material.Metal,
		false
	)
	makeCrystal(m, "CounterCrystal", C(4.8, T + 1.36, -37.4), 1.1, 0.25, PALETTE.crystalPink, false)

	-- Back shelves with goods.
	for row = 0, 2 do
		local y = T + 2.2 + row * 1.9
		makePart(
			m,
			"Shelf",
			C(-6, y, -46.1),
			Vector3.new(24, 0.22, 1.2),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		local x = -16.5
		while x < 4.5 do
			local kind = rndInt(1, 4)
			if kind == 1 then
				makeCylinderY(
					m,
					"Bottle",
					C(x, y + 0.5, -46.1),
					0.8,
					0.45,
					vary(PALETTE.crystalLilac, 0.1),
					Enum.Material.Glass,
					false,
					0.2
				)
				makeCylinderY(
					m,
					"BottleNeck",
					C(x, y + 1.0, -46.1),
					0.3,
					0.2,
					PALETTE.woodDark,
					Enum.Material.Wood,
					false
				)
			elseif kind == 2 then
				makePart(
					m,
					"Box",
					C(x, y + 0.35, -46.1),
					Vector3.new(0.9, 0.5, 0.8),
					vary(PALETTE.coral, 0.08),
					Enum.Material.SmoothPlastic,
					false
				)
			elseif kind == 3 then
				makeCrystal(
					m,
					"ShelfCrystal",
					C(x, y + 0.11, -46.1),
					0.9,
					0.2,
					PALETTE.crystalCyan,
					false
				)
			else
				makeCylinderY(
					m,
					"Pot",
					C(x, y + 0.4, -46.1),
					0.6,
					0.75,
					PALETTE.leaf,
					Enum.Material.SmoothPlastic,
					false
				)
			end
			x += rnd(1.1, 1.8)
		end
	end
	-- Rod rack on the left wall.
	for k = 0, 4 do
		makeTube(
			m,
			"RackRod",
			V(-19.2, T + 0.3, -44 + k * 1.4),
			V(-19.2, T + 6.5, -43.2 + k * 1.4),
			0.14,
			vary(PALETTE.woodDark, 0.1),
			Enum.Material.Wood,
			false
		)
	end
	makeBarrel(m, "ShopBarrel", V(5.5, T, -44), 1.8)
	makeCrate(m, "ShopCrate", CY(-17, T + 0.55, -40.5, 12), 1.1)
	makeTube(
		m,
		"HangChain",
		V(-6, T + 9.0, -41),
		V(-6, T + 7.6, -41),
		0.1,
		PALETTE.metal,
		Enum.Material.Metal,
		false
	)
	makeLanternBody(m, "ShopLantern", V(-6, T + 6.9, -41), 0.9, true)

	-- Gable roof (blue tiles), ridge along Z.
	local eaveY, ridgeY = T + 9.0, T + 16.0
	local half = 16.5
	local slope = math.atan2(ridgeY - eaveY, half)
	local planeW = math.sqrt(half * half + (ridgeY - eaveY) ^ 2) + 0.4
	for _, side in { -1, 1 } do
		local cx = -6 + side * half / 2
		local rot = if side < 0 then slope else -slope
		local pcf = C(cx, (eaveY + ridgeY) / 2, -40.5) * CFrame.Angles(0, 0, rot)
		makePart(
			m,
			"Roof",
			pcf,
			Vector3.new(planeW, 0.7, 19),
			PALETTE.roofBlueDark,
			Enum.Material.SmoothPlastic,
			true
		)
		local rows = 12
		for r = 0, rows - 1 do
			local lx = -planeW / 2 + (r + 0.5) * planeW / rows
			makePart(
				m,
				"RoofTiles",
				pcf * CFrame.new(lx, 0.42, 0) * CFrame.Angles(0, 0, side * math.rad(4)),
				Vector3.new(planeW / rows + 0.25, 0.3, 19.4),
				if r % 2 == 0 then PALETTE.roofBlue else PALETTE.roofBlueLight,
				Enum.Material.SmoothPlastic,
				false
			)
		end
	end
	makeTube(
		m,
		"Ridge",
		V(-6, ridgeY + 0.55, -50.4),
		V(-6, ridgeY + 0.55, -30.6),
		1.4,
		PALETTE.bark,
		Enum.Material.Wood,
		false
	)
	makeCylinderY(
		m,
		"RidgeCapFront",
		C(-6, ridgeY + 0.55, -30.4) * CFrame.Angles(math.pi / 2, 0, 0),
		0.4,
		1.9,
		PALETTE.woodLight,
		Enum.Material.Wood,
		false
	)
	-- Gable triangles (front and back).
	for _, z in { -31.6, -49.4 } do
		makeWedge(
			m,
			"Gable",
			C(-13, eaveY + (ridgeY - eaveY) / 2 - 0.2, z) * CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(0.6, ridgeY - eaveY - 0.4, 14),
			PALETTE.woodLight,
			Enum.Material.Wood,
			false
		)
		makeWedge(
			m,
			"Gable",
			C(1, eaveY + (ridgeY - eaveY) / 2 - 0.2, z) * CFrame.Angles(0, math.rad(-90), 0),
			Vector3.new(0.6, ridgeY - eaveY - 0.4, 14),
			PALETTE.woodLight,
			Enum.Material.Wood,
			false
		)
	end
	makeSign(
		m,
		"WorkshopSign",
		faceTo(V(-6, eaveY + 1.9, -31.1), V(-6, eaveY + 1.9, 0)),
		11,
		3.3,
		"OFICINA DE VARAS",
		nil,
		PALETTE.signBg,
		PALETTE.signText,
		nil,
		PALETTE.woodDark,
		false
	)
	local halo = Instance.new("Model")
	halo.Name = "Halo"
	halo.Parent = m
	makeNeonRing(halo, "HaloRing", C(-6, ridgeY + 3.2, -32), 2.2, 0.35, 20, PALETTE.gold, 0.05)
	makeTube(
		m,
		"HaloRod",
		V(-6, ridgeY + 1.2, -32),
		V(-6, ridgeY + 3.0, -32),
		0.2,
		PALETTE.gold,
		Enum.Material.Metal,
		false
	)
	-- Crystal shield emblems on the front posts.
	for _, x in { -20, 8 } do
		local p = V(x, T + 6.6, -33.0)
		local cf = faceTo(p, p + Vector3.new(0, 0, 1))
		makePart(
			m,
			"Shield",
			cf,
			Vector3.new(2, 2.4, 0.3),
			PALETTE.roofBlueLight,
			Enum.Material.SmoothPlastic,
			false
		)
		makePart(
			m,
			"ShieldRim",
			cf * CFrame.new(0, 0, 0.08),
			Vector3.new(2.3, 2.7, 0.2),
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false
		)
		makePart(
			m,
			"ShieldGem",
			cf * CFrame.new(0, 0.1, -0.25) * CFrame.Angles(0, 0, math.rad(45)),
			Vector3.new(1.05, 1.05, 0.3),
			PALETTE.crystalCyan,
			Enum.Material.Glass,
			false,
			0.1
		)
		makePart(
			m,
			"ShieldGemCore",
			cf * CFrame.new(0, 0.1, -0.36) * CFrame.Angles(0, 0, math.rad(45)),
			Vector3.new(0.5, 0.5, 0.1),
			PALETTE.cyan,
			Enum.Material.Neon,
			false,
			0.3
		)
	end
	makeBunting(m, "WorkshopFrontBunting", V(-20, T + 8.4, -33.6), V(-6, T + 7.6, -33.6), 0.6)
	makeBunting(m, "WorkshopFrontBunting", V(-6, T + 7.6, -33.6), V(8, T + 8.4, -33.6), 0.6)

	-- Terrace props.
	makeStoneLantern(m, "TerraceLantern", V(-24.6, T, -23.6), true)
	makeStoneLantern(m, "TerraceLantern", V(12.6, T, -23.6), true)
	makePart(
		m,
		"SpotPedestal",
		C(-6, T + 0.5, -27.5),
		Vector3.new(1.8, 1.0, 1.8),
		PALETTE.stone,
		Enum.Material.Slate,
		true
	)
	makeCrystalCluster(m, "SpotCrystal", V(-6, T + 1.0, -27.5), 0.6, PALETTE.crystalCyan, true)
	makeNeonRing(m, "SpotRing", C(-6, T + 0.08, -27.5), 2.2, 0.2, 16, PALETTE.cyan, 0.3)
	makePlanter(m, "ShopPlanter", V(-21.8, T, -32), PALETTE.crystalPink)
	makePlanter(m, "ShopPlanter", V(9.8, T, -32), PALETTE.crystalCyan)
	makeBarrel(m, "TerraceBarrel", V(-23.8, T, -28.5), 1.8)
	makeCrate(m, "TerraceCrate", CY(11.5, T + 0.6, -28.4, 20), 1.2)
	makeCrate(m, "TerraceCrate", CY(11.6, T + 1.75, -28.6, -8), 1.0)
	makePalm(m, "TerracePalm", V(-24, T, -45.5), 12, 200)
	makePalm(m, "TerracePalm", V(12, T, -45.5), 12, -20)
	makeCrystalCluster(m, "TerraceCrystal", V(-24.4, T, -38), 1.0, PALETTE.crystalLilac, true)
	makeCrystalCluster(m, "TerraceCrystal", V(12.6, T, -38.5), 1.0, PALETTE.crystalCyan, true)
	-- Big crystal tufts on the rocks behind the Workshop.
	for _, c in
		{
			{ -29, -50, PALETTE.crystalCyan },
			{ 17.5, -50, PALETTE.crystalLilac },
			{ -14, -55, PALETTE.crystalPink },
			{ 3, -56, PALETTE.crystalCyan },
		}
	do
		local x, z = c[1] :: number, c[2] :: number
		makeCrystalCluster(
			m,
			"BackCrystal",
			V(x, groundY(x, z), z),
			rnd(2.2, 2.8),
			c[3] :: Color3,
			true,
			PALETTE.crystalLilac
		)
	end
end

---------------------------------------------------------------------------------------
-- Region: front entrance stairs (south) with the "Legendary Catch" arch
---------------------------------------------------------------------------------------

local function buildStairs(root: Instance)
	local m = makeModel(root, "Stairs")
	local count = 18
	local rise = FRONT_STAIR_RISE
	local run = 28 / count
	makeStairs(
		m,
		"FrontStairs",
		V(-6, PLAZA_Y, 24),
		Vector3.new(0, 0, 1),
		16,
		count,
		-rise,
		run,
		-2.5,
		PALETTE.stone,
		Enum.Material.Slate,
		PALETTE.stoneWarm
	)
	local bottomTop = PLAZA_Y - rise * count
	makePart(
		m,
		"Landing",
		C(-6, (bottomTop - 3) / 2, 55),
		Vector3.new(16, bottomTop + 3, 6),
		PALETTE.stoneMid,
		Enum.Material.Slate,
		true
	)
	for k = 0, 5 do
		makePart(
			m,
			"LandingSeam",
			C(-6, bottomTop + 0.02, 52.5 + k),
			Vector3.new(15.6, 0.04, 0.12),
			PALETTE.stoneDark,
			Enum.Material.Slate,
			false
		)
	end
	-- Stepped side walls (X -16..-14 and 2..4), cap stones on top.
	for _, x in { -15, 3 } do
		for i = 1, count do
			local top = PLAZA_Y - rise * i + 1.1
			local z = 24 + run * (i - 0.5)
			makePart(
				m,
				"SideWall",
				C(x, (top - 2.5) / 2, z),
				Vector3.new(2, top + 2.5, run + 0.02),
				vary(PALETTE.stoneMid, 0.02),
				Enum.Material.Slate,
				true
			)
			makePart(
				m,
				"SideCap",
				C(x, top + 0.1, z),
				Vector3.new(2.3, 0.2, run + 0.06),
				PALETTE.stoneWarm,
				Enum.Material.Slate,
				false
			)
		end
		makePart(
			m,
			"LandingWall",
			C(x, (bottomTop + 1.1 - 2.5) / 2, 55),
			Vector3.new(2, bottomTop + 1.1 + 2.5, 6),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		makeLantern(m, "LandingLantern", V(x, bottomTop + 1.1, 57.2), 2.4, true)
		makeCrystalCluster(
			m,
			"WallCrystal",
			V(x, PLAZA_Y - rise * 9 + 1.2, 24 + run * 8.5),
			0.55,
			if x < 0 then PALETTE.crystalCyan else PALETTE.crystalLilac,
			true
		)
	end
	task.wait()

	-- "Legendary Catch" big wooden arch at the top of the stairs (ref).
	for _, x in { -17.2, 5.2 } do
		local base = V(x, PLAZA_Y, 24.6)
		makeCylinderY(
			m,
			"ArchLog",
			CFrame.new(base + Vector3.new(0, 4.3, 0)),
			10.6,
			2.2,
			PALETTE.bark,
			Enum.Material.Wood,
			true
		)
		makeCylinderY(
			m,
			"ArchFoot",
			CFrame.new(base + Vector3.new(0, 0.5, 0)),
			1.0,
			3.0,
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		for k = 0, 2 do
			makeCylinderY(
				m,
				"ArchWrap",
				CFrame.new(base + Vector3.new(0, 1.8 + k * 0.42, 0)),
				0.34,
				2.4,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			makeCylinderY(
				m,
				"ArchWrap",
				CFrame.new(base + Vector3.new(0, 6.0 + k * 0.42, 0)),
				0.34,
				2.4,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
		end
		makeCylinderY(
			m,
			"ArchCap",
			CFrame.new(base + Vector3.new(0, 9.75, 0)),
			0.3,
			2.5,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeCrystalCluster(
			m,
			"ArchCrystal",
			base + Vector3.new(0, 10.0, 0),
			0.75,
			PALETTE.crystalCyan,
			true
		)
	end
	makeTube(
		m,
		"ArchBeam",
		V(-19.2, PLAZA_Y + 7.6, 24.6),
		V(7.2, PLAZA_Y + 7.6, 24.6),
		1.7,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeTube(
		m,
		"ArchBeamLow",
		V(-17.2, PLAZA_Y + 6.6, 25.45),
		V(5.2, PLAZA_Y + 6.6, 25.45),
		0.8,
		PALETTE.wood,
		Enum.Material.Wood,
		false
	)
	makeSign(
		m,
		"LegendaryCatchSign",
		faceTo(V(-6, PLAZA_Y + 6.1, 24.6), V(-6, PLAZA_Y + 6.1, 60)),
		11,
		2.1,
		"Legendary Catch",
		nil,
		PALETTE.signBg,
		PALETTE.goldLight,
		nil,
		PALETTE.gold,
		true
	)
	makePart(
		m,
		"ArchGem",
		C(-6, PLAZA_Y + 8.9, 24.6) * CFrame.Angles(0, 0, math.rad(45)),
		Vector3.new(1.1, 1.1, 0.5),
		PALETTE.cyan,
		Enum.Material.Neon,
		false,
		0.05
	)
	for _, x in { -12.5, 0.5 } do
		makeTube(
			m,
			"ArchChain",
			V(x, PLAZA_Y + 6.85, 24.6),
			V(x, PLAZA_Y + 6.1, 24.6),
			0.1,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeLanternBody(m, "ArchLantern", V(x, PLAZA_Y + 5.4, 24.6), 0.8, true)
	end

	-- Stepping stones in the turquoise shallows + crystals on the side rocks.
	for _, s in { { -9.5, 60.5 }, { -3.5, 62.5 }, { -7.5, 65.5 }, { 0.5, 60 }, { -12.5, 63.5 } } do
		makeCylinderY(
			m,
			"SteppingStone",
			CY(s[1], 0, s[2], rnd(0, 90)),
			4.6,
			rnd(2.2, 3),
			vary(PALETTE.stoneMid, 0.04),
			Enum.Material.Slate,
			true
		)
	end
	for _, c in { { -21, 31 }, { 9.4, 33 }, { -22, 42 }, { 9.8, 44.5 }, { -20.5, 51 }, { 8.6, 52 } } do
		local g = groundY(c[1], c[2])
		if g > -1 then
			makeCrystalCluster(
				m,
				"RockCrystal",
				V(c[1], g, c[2]),
				rnd(0.8, 1.2),
				if c[1] < 0 then PALETTE.crystalLilac else PALETTE.crystalCyan,
				c[2] < 40,
				PALETTE.crystalPink
			)
		end
	end
end

---------------------------------------------------------------------------------------
-- Portals (visual) + contract triggers
---------------------------------------------------------------------------------------

local PORTAL_BASE_H = 0.7

local function addSwirl(
	m: Instance,
	cf: CFrame,
	cy: number,
	arms: number,
	steps: number,
	maxR: number,
	color: Color3,
	thick: number
)
	for arm = 0, arms - 1 do
		local prev: Vector3? = nil
		for k = 0, steps do
			local r = 0.25 + k / steps * maxR
			local a = arm * (math.pi * 2 / arms) + r * 1.35
			local p = (cf * CFrame.new(math.cos(a) * r, cy + math.sin(a) * r, -0.1)).Position
			local q = prev
			if q then
				makeSegment(
					m,
					"Swirl",
					q,
					p,
					thick * (1 - 0.4 * k / steps),
					color,
					Enum.Material.Neon,
					false
				)
			end
			prev = p
		end
	end
end

-- Round-topped arch made of segments (sides + semicircle).
local function archFrame(
	m: Instance,
	cf: CFrame,
	bh: number,
	R: number,
	springY: number,
	w: number,
	depth: number,
	color: Color3,
	alt: Color3,
	mat: Enum.Material
)
	for _, sx in { -R, R } do
		makePart(
			m,
			"ArchSide",
			cf * CFrame.new(sx, (bh + springY) / 2, 0),
			Vector3.new(w, springY - bh, depth),
			color,
			mat,
			true
		)
		makePart(
			m,
			"ArchSideTrim",
			cf * CFrame.new(sx, (bh + springY) / 2, -0.2),
			Vector3.new(w * 0.45, springY - bh - 0.4, depth - 0.2),
			alt,
			mat,
			false
		)
	end
	local segs = 11
	for i = 0, segs - 1 do
		local a = (i + 0.5) / segs * math.pi
		local pcf = cf
			* CFrame.new(math.cos(a) * R, springY + math.sin(a) * R, 0)
			* CFrame.Angles(0, 0, a)
		local seg = math.pi * R / segs * 1.1
		makePart(
			m,
			"Arch",
			pcf,
			Vector3.new(w, seg, depth),
			if i % 2 == 0 then color else vary(color, 0.04),
			mat,
			false
		)
		makePart(
			m,
			"ArchTrim",
			pcf * CFrame.new(0, 0, -0.2),
			Vector3.new(w * 0.45, seg, depth - 0.2),
			alt,
			mat,
			false
		)
	end
end

-- Visual portal. cf = floor point at the portal center, front (-Z) faces the player.
-- Styles: stone, coral (fishing shell ring), reef, abyss (dark crystal arch),
-- abyssTall (fishing: tall narrow blue arch with pink hexagon), gold (rays fan).
-- Returns the CFrame where the PortalTrigger must go.
local function makePortal(
	parent: Instance,
	name: string,
	cf: CFrame,
	style: string,
	primary: Color3,
	accent: Color3,
	lightBeam: boolean
): CFrame
	local m = makeModel(parent, name)
	local bh = PORTAL_BASE_H
	local baseColor = if style == "gold"
		then PALETTE.stoneWarm
		elseif style == "abyss" or style == "abyssTall" then PALETTE.stoneBlue
		else PALETTE.stoneMid
	-- Two-step stone base.
	makeCylinderY(
		m,
		"BaseStep",
		cf * CFrame.new(0, bh / 4, 0),
		bh / 2,
		11.2,
		vary(baseColor, 0.03),
		Enum.Material.Slate,
		true
	)
	makeCylinderY(
		m,
		"Base",
		cf * CFrame.new(0, bh * 0.75, 0),
		bh / 2,
		9.6,
		baseColor,
		Enum.Material.Slate,
		true
	)
	makeNeonRing(m, "BaseGlow", cf * CFrame.new(0, bh + 0.06, 0), 4.1, 0.16, 24, accent, 0.45)
	for k = 0, 7 do
		local a = k / 8 * math.pi * 2
		makePart(
			m,
			"BaseRune",
			cf
				* CFrame.new(math.cos(a) * 3.3, bh + 0.03, math.sin(a) * 3.3)
				* CFrame.Angles(0, -a, 0),
			Vector3.new(0.1, 0.05, 0.75),
			primary,
			Enum.Material.Neon,
			false,
			0.3
		)
	end

	local cy: number -- swirl center height (relative to cf)
	if style == "stone" then
		-- Gray stone blocks with dark joints + dark wooden lintel + rune emblem.
		for _, sx in { -4.5, 4.5 } do
			makePart(
				m,
				"PillarCore",
				cf * CFrame.new(sx, bh + 5.4, 0),
				Vector3.new(1.7, 10.8, 1.6),
				PALETTE.stoneGrayDark,
				Enum.Material.Slate,
				true
			)
			local y = bh
			for i, hgt in { 2.3, 2.1, 2.2, 2.0, 2.2 } do
				local w = if i % 2 == 0 then 2.0 else 2.3
				makePart(
					m,
					"PillarBlock",
					cf
						* CFrame.new(sx + rnd(-0.06, 0.06), y + hgt / 2, 0)
						* CFrame.Angles(0, math.rad(rnd(-3, 3)), 0),
					Vector3.new(w, hgt - 0.22, 2.1),
					vary(PALETTE.stoneGray, 0.04),
					Enum.Material.Slate,
					false
				)
				y += hgt
			end
		end
		makePart(
			m,
			"Lintel",
			cf * CFrame.new(0, bh + 11.55, 0),
			Vector3.new(12.2, 1.5, 2.5),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makePart(
			m,
			"LintelTop",
			cf * CFrame.new(0, bh + 12.35, 0),
			Vector3.new(12.6, 0.2, 2.7),
			PALETTE.barkDark,
			Enum.Material.Wood,
			false
		)
		makePart(
			m,
			"Emblem",
			cf * CFrame.new(0, bh + 12.9, 0),
			Vector3.new(2.6, 2.6, 2.2),
			vary(PALETTE.stoneGray, 0.03),
			Enum.Material.Slate,
			false
		)
		makeNeonRing(
			m,
			"EmblemRune",
			cf * CFrame.new(0, bh + 12.9, -1.15) * CFrame.Angles(math.pi / 2, 0, 0),
			0.8,
			0.18,
			12,
			primary,
			0.15
		)
		makeNeonRing(
			m,
			"EmblemRune",
			cf * CFrame.new(0, bh + 12.9, -1.15) * CFrame.Angles(math.pi / 2, 0, 0),
			0.35,
			0.16,
			8,
			primary,
			0.15
		)
		makePart(
			m,
			"Energy",
			cf * CFrame.new(0, bh + 5.3, 0.1),
			Vector3.new(6.7, 10.6, 0.2),
			primary,
			Enum.Material.Neon,
			false,
			0.35
		)
		cy = bh + 5.4
		addSwirl(m, cf, cy, 4, 12, 3.1, accent, 0.26)
	elseif style == "coral" then
		-- Chunky shell/coral ring in peach with stripes (ref-3).
		local R = 4.3
		cy = bh + 5.5
		local segs = 22
		for i = 0, segs - 1 do
			local a = (i + 0.5) / segs * math.pi * 2
			local pcf = cf
				* CFrame.new(math.cos(a) * R, cy + math.sin(a) * R, 0)
				* CFrame.Angles(0, 0, a)
			local seg = 2 * math.pi * R / segs * 1.12
			makePart(
				m,
				"Shell",
				pcf,
				Vector3.new(2.3, seg, 2.8),
				if i % 2 == 0 then PALETTE.peach else PALETTE.peachLight,
				Enum.Material.SmoothPlastic,
				false
			)
			makePart(
				m,
				"ShellGroove",
				pcf * CFrame.new(0, seg / 2 - 0.05, -0.05),
				Vector3.new(2.34, 0.12, 2.6),
				PALETTE.coralDeep,
				Enum.Material.SmoothPlastic,
				false
			)
		end
		local disc = Instance.new("Part")
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.2, 6.4, 6.4)
		disc.CFrame = cf * CFrame.new(0, cy, 0.1) * CFrame.Angles(0, math.pi / 2, 0)
		finishPart(disc, "Energy", primary, Enum.Material.Neon, false, 0.35)
		disc.Parent = m
		for k = 0, 6 do
			local a = math.rad(40 + k * 17)
			makeBall(
				m,
				"Seashell",
				(cf * CFrame.new(math.cos(a) * (R + 1.2), cy + math.sin(a) * (R + 1.2), -0.3)).Position,
				rnd(0.7, 1.1),
				if k % 2 == 0 then PALETTE.white else PALETTE.pinkLight,
				Enum.Material.SmoothPlastic
			)
		end
		for _, sx in { -1, 1 } do
			local root = (cf * CFrame.new(sx * (R + 1.8), bh, 0.4)).Position
			for b = 1, 4 do
				local col = if b % 2 == 0 then PALETTE.coralDeep else PALETTE.coral
				local tip = root + Vector3.new(sx * rnd(0.3, 1.2), rnd(1.4, 3.2), rnd(-0.8, 0.8))
				makeTube(m, "Coral", root, tip, 0.35, col, Enum.Material.SmoothPlastic, false)
				makeBall(m, "CoralTip", tip, 0.45, col, Enum.Material.SmoothPlastic)
			end
		end
		addSwirl(m, cf, cy, 3, 9, 2.6, accent, 0.2)
	elseif style == "abyssTall" then
		-- Tall narrow blue arch, pointed top, crystal on top, pink hexagon inside.
		local hw = 3.4
		local sideTop = bh + 8.6
		local apex = bh + 12.4
		for _, sx in { -hw, hw } do
			makePart(
				m,
				"Side",
				cf * CFrame.new(sx, (bh + sideTop) / 2, 0),
				Vector3.new(1.3, sideTop - bh, 1.8),
				PALETTE.abyssBlue,
				Enum.Material.SmoothPlastic,
				true
			)
			makePart(
				m,
				"SideTrim",
				cf * CFrame.new(sx * 0.86, (bh + sideTop) / 2, -0.25),
				Vector3.new(0.35, sideTop - bh - 0.3, 1.5),
				PALETTE.abyssBlueLight,
				Enum.Material.SmoothPlastic,
				false
			)
			local a = (cf * CFrame.new(sx, sideTop - 0.3, 0)).Position
			local b = (cf * CFrame.new(0, apex, 0)).Position
			local seg = makeSegment(
				m,
				"Peak",
				a,
				b,
				1.3,
				PALETTE.abyssBlue,
				Enum.Material.SmoothPlastic,
				false
			)
			seg.Size = Vector3.new(1.8, 1.3, seg.Size.Z + 0.6)
			makeCrystalCluster(
				m,
				"SideCrystal",
				(cf * CFrame.new(sx * 1.45, bh, 0.3)).Position,
				0.55,
				PALETTE.crystalLilac,
				false,
				PALETTE.abyssBlueLight
			)
		end
		makeCrystal(
			m,
			"TopCrystal",
			cf * CFrame.new(0, apex + 0.3, 0),
			2.2,
			0.45,
			PALETTE.crystalCyan,
			true
		)
		makePart(
			m,
			"Energy",
			cf * CFrame.new(0, (bh + sideTop) / 2, 0.15),
			Vector3.new(5.6, sideTop - bh, 0.2),
			PALETTE.navy,
			Enum.Material.SmoothPlastic,
			false,
			0.05
		)
		makeWedge(
			m,
			"EnergyTop",
			cf * CFrame.new(-1.4, sideTop + 1.6, 0.15) * CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(0.2, 3.2, 2.8),
			PALETTE.navy,
			Enum.Material.SmoothPlastic,
			false,
			0.05
		)
		makeWedge(
			m,
			"EnergyTop",
			cf * CFrame.new(1.4, sideTop + 1.6, 0.15) * CFrame.Angles(0, math.rad(-90), 0),
			Vector3.new(0.2, 3.2, 2.8),
			PALETTE.navy,
			Enum.Material.SmoothPlastic,
			false,
			0.05
		)
		cy = bh + 5.4
		-- Pink hexagon (filled, glowing) with a brighter outline.
		for k = 0, 2 do
			makePart(
				m,
				"Hexagon",
				cf * CFrame.new(0, cy, 0) * CFrame.Angles(0, 0, math.rad(60 * k)),
				Vector3.new(1.8, 3.12, 0.1),
				PALETTE.hexPink,
				Enum.Material.Neon,
				false,
				0.35
			)
		end
		for k = 0, 5 do
			local a0 = math.rad(60 * k + 30)
			local a1 = math.rad(60 * (k + 1) + 30)
			makeSegment(
				m,
				"HexEdge",
				(cf * CFrame.new(math.cos(a0) * 2.2, cy + math.sin(a0) * 2.2, -0.12)).Position,
				(cf * CFrame.new(math.cos(a1) * 2.2, cy + math.sin(a1) * 2.2, -0.12)).Position,
				0.16,
				PALETTE.pinkLight,
				Enum.Material.Neon,
				false
			)
		end
		for k = 1, 8 do
			makeBall(
				m,
				"Star",
				(cf * CFrame.new(rnd(-2.3, 2.3), rnd(1.5, 10), -0.2)).Position,
				0.22,
				PALETTE.white,
				Enum.Material.Neon
			)
		end
		local inner = makePart(
			m,
			"Glow",
			cf * CFrame.new(0, cy, -0.3),
			Vector3.new(2, 2, 0.1),
			primary,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		addLight(inner, primary, 16, 1.2)
		addSparkles(inner, PALETTE.hexPink, 6, 0.35, 1.0, 1.4)
	else
		-- Round-topped arch variants: reef (turquoise + corals), abyss (dark + crystals), gold (rays).
		local frameColor: Color3
		local frameAlt: Color3
		if style == "reef" then
			frameColor, frameAlt = PALETTE.teal, Color3.fromRGB(120, 220, 200)
		elseif style == "abyss" then
			frameColor, frameAlt = PALETTE.violetDark, PALETTE.violet
		else
			frameColor, frameAlt = PALETTE.gold, PALETTE.goldLight
		end
		local R = 4.4
		local springY = bh + 6.6
		archFrame(
			m,
			cf,
			bh,
			R,
			springY,
			1.4,
			1.7,
			frameColor,
			frameAlt,
			Enum.Material.SmoothPlastic
		)
		if style == "reef" then
			for _, sx in { -1, 1 } do
				local root = (cf * CFrame.new(sx * (R + 1.2), bh, 0.3)).Position
				for b = 1, 5 do
					local col = if b % 2 == 0 then PALETTE.pink else PALETTE.flame
					local tip = root
						+ Vector3.new(sx * rnd(0.4, 1.6), rnd(1.8, 4.2), rnd(-0.9, 0.9))
					makeTube(m, "Coral", root, tip, 0.4, col, Enum.Material.SmoothPlastic, false)
					makeBall(m, "CoralTip", tip, 0.5, col, Enum.Material.SmoothPlastic)
					local tip2 = tip + Vector3.new(sx * rnd(0.2, 0.9), rnd(0.6, 1.3), 0)
					makeTube(m, "Coral", tip, tip2, 0.28, col, Enum.Material.SmoothPlastic, false)
					makeBall(m, "CoralTip", tip2, 0.36, col, Enum.Material.SmoothPlastic)
				end
			end
			for k = 0, 5 do
				local a = k / 5 * math.pi
				makeBall(
					m,
					"Shell",
					(cf * CFrame.new(
						math.cos(a) * (R + 0.6),
						springY + math.sin(a) * (R + 0.6),
						-0.4
					)).Position,
					rnd(0.6, 0.9),
					if k % 2 == 0 then PALETTE.white else PALETTE.peachLight,
					Enum.Material.SmoothPlastic
				)
			end
		elseif style == "abyss" then
			for k = 0, 10 do
				local a = k / 10 * math.pi
				local p = cf
					* CFrame.new(math.cos(a) * (R + 0.6), springY + math.sin(a) * (R + 0.6), 0)
				makeCrystal(
					m,
					"Spike",
					p * CFrame.Angles(0, 0, a - math.pi / 2),
					rnd(1.8, 3.0),
					0.36,
					if k % 2 == 0 then PALETTE.crystalLilac else PALETTE.violet,
					k == 5
				)
			end
			for _, sx in { -1, 1 } do
				makeCrystalCluster(
					m,
					"BaseCrystal",
					(cf * CFrame.new(sx * (R + 1.3), bh, 0.2)).Position,
					0.7,
					PALETTE.violet,
					false,
					PALETTE.crystalLilac
				)
			end
		else
			makeCrystal(
				m,
				"TopGem",
				cf * CFrame.new(0, springY + R + 0.7, 0),
				2.4,
				0.6,
				PALETTE.crystalGold,
				true
			)
			for _, sx in { -R, R } do
				for k = 0, 3 do
					makeBall(
						m,
						"Bulb",
						(cf * CFrame.new(sx, bh + 1.2 + k * 1.5, -0.95)).Position,
						0.4,
						PALETTE.white,
						Enum.Material.Neon,
						0.2
					)
				end
				makePart(
					m,
					"Capital",
					cf * CFrame.new(sx, springY + 0.2, 0),
					Vector3.new(2.1, 0.5, 2.1),
					PALETTE.goldLight,
					Enum.Material.SmoothPlastic,
					false
				)
				makePart(
					m,
					"Plinth",
					cf * CFrame.new(sx, bh + 0.35, 0),
					Vector3.new(2.2, 0.7, 2.2),
					PALETTE.goldLight,
					Enum.Material.SmoothPlastic,
					false
				)
			end
			-- Pastel ray fan behind the arch (short, soft).
			local rayCols = {
				PALETTE.pinkLight,
				PALETTE.goldLight,
				Color3.fromRGB(170, 240, 200),
				Color3.fromRGB(170, 210, 255),
				PALETTE.crystalLilac,
			}
			for k = 0, 6 do
				local ang = math.rad(-54 + k * 18)
				local base = cf * CFrame.new(0, springY + R - 0.5, 1.4) * CFrame.Angles(0, 0, ang)
				makePart(
					m,
					"Ray",
					base * CFrame.new(0, 7.5, 0),
					Vector3.new(0.9, 14, 0.1),
					rayCols[k % #rayCols + 1],
					Enum.Material.Neon,
					false,
					0.78
				)
			end
		end
		makePart(
			m,
			"Energy",
			cf * CFrame.new(0, (bh + springY) / 2, 0.1),
			Vector3.new(7.6, springY - bh, 0.2),
			primary,
			Enum.Material.Neon,
			false,
			0.35
		)
		local disc = Instance.new("Part")
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.2, 7.6, 7.6)
		disc.CFrame = cf * CFrame.new(0, springY, 0.1) * CFrame.Angles(0, math.pi / 2, 0)
		finishPart(disc, "EnergyTop", primary, Enum.Material.Neon, false, 0.35)
		disc.Parent = m
		cy = bh + 6.2
		addSwirl(m, cf, cy, 3, 10, 3.2, accent, 0.2)
	end

	if style ~= "abyssTall" then
		local glow = makePart(
			m,
			"Glow",
			cf * CFrame.new(0, cy, -0.3),
			Vector3.new(2, 2, 0.1),
			primary,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		makeBall(
			m,
			"Core",
			(cf * CFrame.new(0, cy, -0.12)).Position,
			1.0,
			PALETTE.white,
			Enum.Material.Neon,
			0.2
		)
		addLight(glow, primary, 16, 1.2)
		addSparkles(glow, accent, 7, 0.4, 1.4, 1.4)
	end

	if lightBeam then
		-- Thin, short, soft beam (ref-3): no giant neon columns.
		makeCylinderY(
			m,
			"LightBeam",
			cf * CFrame.new(0, bh + 24, 2.4),
			22,
			2.0,
			primary,
			Enum.Material.Neon,
			false,
			0.86
		)
		makeCylinderY(
			m,
			"LightHalo",
			cf * CFrame.new(0, bh + 22, 2.4),
			18,
			3.4,
			primary,
			Enum.Material.Neon,
			false,
			0.94
		)
	end
	return cf * CFrame.new(0, bh + 4.7, 0)
end

local function makeTrigger(
	contract: Instance,
	cf: CFrame,
	attrs: { [string]: string | number | Color3 },
	tags: { string }
): Part
	local p = Instance.new("Part")
	p.Name = "PortalTrigger"
	p.Size = Vector3.new(7.2, 9.4, 4.8)
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = true
	p.Transparency = 1
	p.CastShadow = false
	for k, v in attrs do
		p:SetAttribute(k, v)
	end
	for _, t in tags do
		CollectionService:AddTag(p, t)
	end
	p.Parent = contract
	stats.parts += 1
	return p
end

---------------------------------------------------------------------------------------
-- Region: fishing pier (geometry fixed by the server contract)
---------------------------------------------------------------------------------------

local function buildFishingPier(root: Instance)
	local m = makeModel(root, "FishingPier")
	local Y = PIER_Y

	-- Main deck X 17..73, Z 3..13 and T-head X 73..85, Z 1..15 (floor at Y 10.1).
	makePlankDeck(
		m,
		"PierDeck",
		C(45, Y, 8) * CFrame.Angles(0, math.rad(90), 0),
		10,
		56,
		0.9,
		PALETTE.wood
	)
	makePlankDeck(m, "PierHead", C(79, Y, 8), 12, 14, 0.9, PALETTE.woodWarm)
	for x = 19, 71, 4 do
		makePart(
			m,
			"CrossBeam",
			C(x, Y - 1.2, 8),
			Vector3.new(0.6, 0.6, 11),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	for x = 75, 83, 4 do
		makePart(
			m,
			"CrossBeam",
			C(x, Y - 1.2, 8),
			Vector3.new(0.6, 0.6, 15),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	for _, z in { 3.2, 12.8 } do
		makePart(
			m,
			"StringerBeam",
			C(45, Y - 1.6, z),
			Vector3.new(56, 0.5, 0.5),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end

	-- Pilings + rope rails along both sides (gap on the south side for the boardwalk).
	local railY = Y + 1.3
	local function railSide(z: number, xs: { number }, skipFrom: number?, skipTo: number?)
		local prev: Vector3? = nil
		for _, x in xs do
			local skip = skipFrom ~= nil and skipTo ~= nil and x >= skipFrom and x <= skipTo
			local top = V(x, railY, z)
			if not skip then
				makeCylinderY(
					m,
					"Piling",
					CFrame.new((top + V(x, -9, z)) / 2),
					railY + 9 + 0.3,
					0.9,
					vary(PALETTE.woodDark, 0.04),
					Enum.Material.Wood,
					true
				)
				makeCylinderY(
					m,
					"PilingCap",
					CFrame.new(top + Vector3.new(0, 0.2, 0)),
					0.2,
					1.0,
					PALETTE.wood,
					Enum.Material.Wood,
					false
				)
				makeCylinderY(
					m,
					"PilingKnot",
					CFrame.new(top - Vector3.new(0, 0.3, 0)),
					0.35,
					1.05,
					PALETTE.rope,
					Enum.Material.Fabric,
					false
				)
				local p = prev
				if p then
					makeRope(
						m,
						"Rail",
						p - Vector3.new(0, 0.3, 0),
						top - Vector3.new(0, 0.3, 0),
						0.4,
						0.22
					)
				end
				prev = top
			else
				prev = nil
			end
		end
	end
	local xsMain: { number } = {}
	for x = 20, 72, 4 do
		table.insert(xsMain, x)
	end
	railSide(2.55, xsMain)
	railSide(13.45, xsMain, 58.5, 67.5)
	-- Head perimeter.
	local headSouth: { number } = {}
	local headNorth: { number } = {}
	for x = 74, 84, 2.5 do
		table.insert(headSouth, x)
		table.insert(headNorth, x)
	end
	railSide(0.55, headNorth)
	railSide(15.45, headSouth)
	do
		local prev: Vector3? = nil
		for _, z in { 0.55, 4.5, 8, 11.5, 15.45 } do
			local top = V(85.45, Y + 1.0, z)
			makeCylinderY(
				m,
				"EndPiling",
				CFrame.new(V(85.45, (Y + 1.0 - 9) / 2, z)),
				Y + 1.0 + 9,
				0.9,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			makeCylinderY(
				m,
				"EndKnot",
				CFrame.new(top - Vector3.new(0, 0.25, 0)),
				0.3,
				1.05,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			local p = prev
			if p then
				makeRope(
					m,
					"EndRope",
					p - Vector3.new(0, 0.25, 0),
					top - Vector3.new(0, 0.25, 0),
					0.3,
					0.2
				)
			end
			prev = top
		end
	end
	-- Middle pilings under the head.
	for _, p in { { 77, 5 }, { 77, 11 }, { 82, 5 }, { 82, 11 }, { 30, 8 }, { 50, 8 }, { 66, 8 } } do
		makeCylinderY(
			m,
			"UnderPiling",
			C(p[1], (Y - 1.5 - 9) / 2, p[2]),
			Y - 1.5 + 9,
			1.0,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	task.wait()

	-- Entrance gate "PÍER DE PESCA".
	for _, z in { 1.9, 14.1 } do
		makeCylinderY(
			m,
			"GatePost",
			C(19.6, (Y + 10.2 - 6) / 2, z),
			Y + 10.2 + 6,
			1.9,
			PALETTE.bark,
			Enum.Material.Wood,
			true
		)
		makeCylinderY(
			m,
			"GatePostCap",
			C(19.6, Y + 10.3, z),
			0.25,
			2.1,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		for k = 0, 3 do
			makeCylinderY(
				m,
				"GateWrap",
				C(19.6, Y + 1.4 + k * 0.42, z),
				0.34,
				2.15,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			makeCylinderY(
				m,
				"GateWrap",
				C(19.6, Y + 7.2 + k * 0.42, z),
				0.34,
				2.15,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
		end
		makeTube(
			m,
			"GateCross",
			V(19.6, Y + 7.3, z) + Vector3.new(0, 0, -0.9),
			V(19.6, Y + 8.9, z) + Vector3.new(0, 0, 0.9),
			0.3,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
		makeTube(
			m,
			"GateCross",
			V(19.6, Y + 8.9, z) + Vector3.new(0, 0, -0.9),
			V(19.6, Y + 7.3, z) + Vector3.new(0, 0, 0.9),
			0.3,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
		makeTube(
			m,
			"LampArm",
			V(19.6, Y + 6.2, z),
			V(19.6, Y + 6.2, if z < 8 then z + 1.4 else z - 1.4),
			0.25,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeLanternBody(
			m,
			"GateLantern",
			V(19.6, Y + 5.4, if z < 8 then z + 1.4 else z - 1.4),
			0.85,
			true
		)
	end
	makeTube(
		m,
		"GateBeam",
		V(19.6, Y + 8.6, 0.2),
		V(19.6, Y + 8.6, 15.8),
		1.6,
		PALETTE.bark,
		Enum.Material.Wood,
		false
	)
	for _, z in { 5.2, 10.8 } do
		makeTube(
			m,
			"SignRope",
			V(19.6, Y + 7.9, z),
			V(19.6, Y + 7.1, z),
			0.12,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
	end
	makeSign(
		m,
		"PierSign",
		faceTo(V(19.6, Y + 6.15, 8), V(0, Y + 6.15, 8)),
		7.4,
		2.1,
		"PÍER DE PESCA",
		nil,
		PALETTE.signWood,
		PALETTE.signText,
		nil,
		PALETTE.woodDark,
		true
	)
	makeBunting(m, "GateBunting", V(19.4, Y + 7.8, 2.4), V(19.4, Y + 7.8, 13.6), 0.7)
	-- Fishing hook icon on the sign (3D).
	do
		local base = V(19.25, Y + 6.15, 4.85)
		makeTube(
			m,
			"Hook",
			base + Vector3.new(0, 0.7, 0),
			base + Vector3.new(0, -0.3, 0),
			0.16,
			PALETTE.white,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Hook",
			base + Vector3.new(0, -0.3, 0),
			base + Vector3.new(0, -0.6, 0.35),
			0.16,
			PALETTE.white,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Hook",
			base + Vector3.new(0, -0.6, 0.35),
			base + Vector3.new(0, -0.2, 0.6),
			0.16,
			PALETTE.white,
			Enum.Material.Metal,
			false
		)
	end

	-- Props: crates, barrels, nets, buoys, rope coils, rods, poles with bunting.
	makeCrate(m, "PierCrate", CY(23, Y + 0.6, 4.3, 8), 1.2)
	makeCrate(m, "PierCrate", CY(24.4, Y + 0.55, 4.2, -14), 1.1)
	makeCrate(m, "PierCrate", CY(23.4, Y + 1.75, 4.4, 30), 1.0)
	makeBarrel(m, "PierBarrel", V(26.5, Y, 11.9), 1.7)
	makeBarrel(m, "PierBarrel", V(28, Y, 12.1), 1.5)
	makeNet(m, "PierNet", V(33, railY - 0.3, 13.75), V(40, railY - 0.3, 13.75), 1.8)
	makeNet(m, "PierNet", V(45, railY - 0.3, 2.25), V(51, railY - 0.3, 2.25), 1.6)
	for i, x in { 24, 36, 48, 56, 68 } do
		local z = if i % 2 == 0 then 1.95 else 14.05
		local pos = V(x, Y - 0.4, z)
		makeBuoy(m, "Buoy", faceTo(pos, pos + Vector3.new(0, 0, if z < 8 then -1 else 1)), 0.75)
	end
	for _, c in { { 30.5, 4.0 }, { 62, 4.2 }, { 83.6, 12.8 } } do
		makeNeonRing(
			m,
			"RopeCoil",
			C(c[1], Y + 0.12, c[2]),
			0.6,
			0.3,
			10,
			PALETTE.rope,
			0,
			Enum.Material.Fabric
		)
		makeNeonRing(
			m,
			"RopeCoil",
			C(c[1], Y + 0.3, c[2]),
			0.45,
			0.28,
			9,
			PALETTE.rope,
			0,
			Enum.Material.Fabric
		)
	end
	for k = 0, 2 do
		makeTube(
			m,
			"LeaningRod",
			V(41 + k * 0.6, Y + 0.1, 12.6),
			V(41.4 + k * 0.6, Y + 4.6, 13.4),
			0.12,
			vary(PALETTE.woodDark, 0.1),
			Enum.Material.Wood,
			false
		)
	end
	makeCylinderY(
		m,
		"Bucket",
		C(42.8, Y + 0.45, 12.2),
		0.9,
		1.0,
		PALETTE.roofBlueLight,
		Enum.Material.SmoothPlastic,
		false
	)
	for _, x in { 28, 44, 60 } do
		makeLanternBody(m, "PierLantern", V(x, railY + 0.95, 2.55), 0.75, true)
	end
	for _, x in { 36, 52, 72 } do
		makeLanternBody(m, "PierLantern", V(x, railY + 0.95, 13.45), 0.75, x ~= 52)
	end
	local poles = { V(34, Y, 1.85), V(52, Y, 1.85), V(70, Y, 1.85), V(84.8, Y, 0.9) }
	for i, p in poles do
		makeCylinderY(
			m,
			"FlagPole",
			CFrame.new(p + Vector3.new(0, 3.6, 0)),
			7.2,
			0.35,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeBall(
			m,
			"PoleKnob",
			p + Vector3.new(0, 7.3, 0),
			0.5,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		if i > 1 then
			makeBunting(
				m,
				"PierBunting",
				poles[i - 1] + Vector3.new(0, 6.8, 0),
				p + Vector3.new(0, 6.8, 0),
				1.2
			)
		end
	end
	task.wait()

	-- Fishing spot at the tip (visual marker kept on the deck).
	makeNeonRing(
		m,
		"FishingSpotRing",
		CFrame.new(V(PIER_TIP.X, Y + 0.11, PIER_TIP.Z)),
		3.6,
		0.32,
		28,
		PALETTE.cyan,
		0.15
	)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local p = V(PIER_TIP.X + math.cos(a) * 2.6, Y + 0.11, PIER_TIP.Z + math.sin(a) * 2.6)
		makePart(
			m,
			"FishingSpotDash",
			CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))),
			Vector3.new(0.22, 0.08, 0.7),
			PALETTE.white,
			Enum.Material.Neon,
			false,
			0.2
		)
	end
	local spark = makePart(
		m,
		"FishingSpotSparkles",
		C(PIER_TIP.X, Y + 1.2, PIER_TIP.Z),
		Vector3.new(6, 1, 6),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	addSparkles(spark, PALETTE.crystalCyan, 4, 0.4, 0.8)
	makeCylinderY(
		m,
		"TipSignPost",
		C(84.3, Y + 2, 14.3),
		4,
		0.45,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	makeSign(
		m,
		"TipSign",
		faceTo(V(84.3, Y + 4.2, 14.3), V(60, Y + 4.2, 8)),
		4.4,
		1.5,
		"PONTO DE PESCA",
		"Lance para o leste!",
		PALETTE.signWood,
		PALETTE.signText,
		PALETTE.goldLight,
		PALETTE.woodDark,
		true
	)
	for _, z in { 2.4, 13.6 } do
		local base = V(75.4, Y, z)
		makeCylinderY(
			m,
			"DisplayBase",
			CFrame.new(base + Vector3.new(0, 0.3, 0)),
			0.6,
			2.4,
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		makeCylinderY(
			m,
			"DisplayTrim",
			CFrame.new(base + Vector3.new(0, 0.62, 0)),
			0.06,
			2.6,
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false
		)
		makeCrystalCluster(
			m,
			"DisplayCrystal",
			base + Vector3.new(0, 0.6, 0),
			0.6,
			if z < 8 then PALETTE.crystalCyan else PALETTE.white,
			true
		)
	end
end

---------------------------------------------------------------------------------------
-- Region: Expedition Wharf (fishing portals) + curved boardwalk to the pier
---------------------------------------------------------------------------------------

local function buildExpeditionWharf(root: Instance, contract: Instance)
	local m = makeModel(root, "ExpeditionWharf")
	local Y = PLAZA_Y

	-- Bridge from the plaza (south edge, Y 10.3) gently down to the wharf (Y 8.8).
	makeBridge(m, "WharfBridge", V(14.5, PLAZA_Y, 24.1), V(14.5, WHARF_Y, 29.9), 7, true)
	Y = WHARF_Y

	-- Darker stone platform X 10..62, Z 30..60, with slab tiles in 3 tones.
	makePart(
		m,
		"WharfFloor",
		C(36, Y - 1.6, 45),
		Vector3.new(52, 3.2, 30),
		PALETTE.stoneJoint,
		Enum.Material.Slate,
		true
	)
	local wTones = { PALETTE.stoneMid, PALETTE.stone, PALETTE.stoneDark, PALETTE.stoneMid }
	for ix = 0, 12 do
		for iz = 0, 6 do
			local x = 10 + 4 * (ix + 0.5)
			local z = 30 + (30 / 7) * (iz + 0.5)
			makePart(
				m,
				"WharfSlab",
				C(x, Y + 0.01, z),
				Vector3.new(3.8 - rnd(0, 0.1), 0.1, 30 / 7 - 0.2 - rnd(0, 0.1)),
				vary(wTones[rndInt(1, #wTones)], 0.03),
				Enum.Material.Slate,
				false
			)
		end
	end
	makePart(
		m,
		"WharfSkirt",
		C(36, Y - 3.4, 45),
		Vector3.new(52.6, 1.0, 30.6),
		PALETTE.stoneDark,
		Enum.Material.Slate,
		false
	)
	for _, e in { { 36, 29.8, 52.8, 0.4 }, { 36, 60.2, 52.8, 0.4 } } do
		makePart(
			m,
			"WharfEdgeStone",
			C(e[1], Y - 0.9, e[2]),
			Vector3.new(e[3], 1.8, e[4]),
			PALETTE.stoneDark,
			Enum.Material.Cobblestone,
			false
		)
	end
	for _, x in { 9.8, 62.2 } do
		makePart(
			m,
			"WharfEdgeStone",
			C(x, Y - 0.9, 45),
			Vector3.new(0.4, 1.8, 30.8),
			PALETTE.stoneDark,
			Enum.Material.Cobblestone,
			false
		)
	end
	for _, p in { { 15, 35 }, { 36, 35 }, { 57, 35 }, { 15, 55 }, { 36, 55 }, { 57, 55 } } do
		makeCylinderY(
			m,
			"WharfColumn",
			C(p[1], (Y - 3.3 - 9) / 2, p[2]),
			Y - 3.3 + 9,
			4.2,
			PALETTE.stoneDark,
			Enum.Material.Cobblestone,
			false
		)
		makeCylinderY(
			m,
			"WharfColumnRing",
			C(p[1], 0.4, p[2]),
			0.8,
			4.6,
			PALETTE.stoneDark,
			Enum.Material.Slate,
			false
		)
	end
	-- Curb (keeps players on the platform; openings for bridge and boardwalk).
	local curbH = 0.5
	local function curb(x0: number, z0: number, x1: number, z1: number)
		local a = V(x0, Y + curbH / 2, z0)
		local b = V(x1, Y + curbH / 2, z1)
		local len = (b - a).Magnitude
		makePart(
			m,
			"Curb",
			CFrame.lookAt((a + b) / 2, b),
			Vector3.new(0.8, curbH, len),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
	end
	curb(10.4, 30.4, 10.4, 59.6)
	curb(10.4, 59.6, 61.6, 59.6)
	curb(61.6, 59.6, 61.6, 46.6)
	curb(61.6, 39.4, 61.6, 30.4)
	curb(61.6, 30.4, 18.6, 30.4)
	task.wait()

	-- Portico "CAIS DAS EXPEDIÇÕES".
	local pz = 31.6
	for _, x in { 10.9, 18.1 } do
		makeCylinderY(
			m,
			"PorticoPost",
			C(x, Y + 5.7, pz),
			11.4,
			1.5,
			PALETTE.bark,
			Enum.Material.Wood,
			true
		)
		for k = 0, 3 do
			makeCylinderY(
				m,
				"PorticoWrap",
				C(x, Y + 1.3 + k * 0.42, pz),
				0.34,
				1.65,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			makeCylinderY(
				m,
				"PorticoWrap",
				C(x, Y + 8.6 + k * 0.42, pz),
				0.34,
				1.65,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
		end
		makeCrystalCluster(
			m,
			"PorticoCrystal",
			V(x, Y + 11.6, pz),
			0.55,
			PALETTE.crystalCyan,
			x < 14
		)
		local bpos = V(if x < 14 then x - 0.85 else x + 0.85, Y + 4.4, pz)
		makeBuoy(
			m,
			"PorticoBuoy",
			faceTo(bpos, bpos + Vector3.new(0, 0, -1)) * CFrame.Angles(0, math.rad(90), 0),
			0.75
		)
	end
	makeTube(
		m,
		"PorticoBeam",
		V(8.8, Y + 10.6, pz),
		V(20.2, Y + 10.6, pz),
		1.2,
		PALETTE.bark,
		Enum.Material.Wood,
		false
	)
	makeTube(
		m,
		"PorticoBeamLow",
		V(10.9, Y + 9.3, pz),
		V(18.1, Y + 9.3, pz),
		0.7,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeSign(
		m,
		"WharfSign",
		faceTo(V(14.5, Y + 7.9, pz), V(14.5, Y + 7.9, 0)),
		6.4,
		2.3,
		"CAIS DAS",
		"EXPEDIÇÕES",
		PALETTE.signWood,
		PALETTE.signText,
		PALETTE.goldLight,
		PALETTE.woodDark,
		true
	)
	makeBunting(m, "PorticoBunting", V(11.4, Y + 9.0, pz - 0.5), V(17.6, Y + 9.0, pz - 0.5), 0.6)
	for _, x in { 8.6, 20.4 } do
		makeTube(
			m,
			"BeamChain",
			V(x, Y + 10.2, pz),
			V(x, Y + 9.3, pz),
			0.1,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeLanternBody(m, "PorticoLantern", V(x, Y + 8.6, pz), 0.8, true)
	end
	makeNet(m, "PorticoNet", V(20.6, Y + 10.0, pz + 0.6), V(22.8, Y + 8.2, pz + 0.6), 2.4)
	makeNet(m, "PorticoNet", V(8.4, Y + 10.0, pz + 0.6), V(10.4, Y + 6.2, pz + 0.6), 1.6)

	-- Portals: two active + two "coming soon" slots, all facing the plaza (-Z).
	local slotZ = 53.8
	local portals = {
		{
			x = 20,
			id = "main_to_coral",
			zone = "coral",
			style = "coral",
			primary = Color3.fromRGB(255, 150, 200),
			accent = PALETTE.white,
			title = "RECIFE DE CORAL",
			sub = "Ilha de pesca",
		},
		{
			x = 32,
			id = "main_to_abyss",
			zone = "abyss",
			style = "abyssTall",
			primary = Color3.fromRGB(110, 150, 255),
			accent = PALETTE.hexPink,
			title = "ABISMO ESTELAR",
			sub = "Ilha de pesca",
		},
	}
	for _, d in portals do
		local cf = faceTo(V(d.x, Y, slotZ), V(d.x, Y, 0))
		local tcf = makePortal(m, "Portal_" .. d.zone, cf, d.style, d.primary, d.accent, true)
		makeTrigger(contract, tcf, {
			PortalId = d.id,
			ZoneId = d.zone,
			Destination = d.zone,
			PrimaryColor = d.primary,
			AccentColor = d.accent,
		}, { "ZonePortal" })
		makeSign(
			m,
			"PortalSign",
			cf * CFrame.new(0, PORTAL_BASE_H + 16.2, 0),
			7.2,
			2.2,
			d.title,
			d.sub,
			PALETTE.signBg,
			PALETTE.signText,
			d.primary,
			PALETTE.gold,
			true
		)
	end
	for _, x in { 44, 56 } do
		local cf = faceTo(V(x, Y, slotZ), V(x, Y, 0))
		makeCylinderY(
			m,
			"EmptySlotBase",
			cf * CFrame.new(0, PORTAL_BASE_H / 2, 0),
			PORTAL_BASE_H,
			10,
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		makeNeonRing(
			m,
			"EmptySlotRing",
			cf * CFrame.new(0, PORTAL_BASE_H + 0.06, 0),
			4.3,
			0.2,
			24,
			PALETTE.white,
			0.6
		)
		for _, sx in { -4.4, 4.4 } do
			makePart(
				m,
				"GhostPillar",
				cf * CFrame.new(sx, PORTAL_BASE_H + 4, 0),
				Vector3.new(1.2, 8, 1.4),
				PALETTE.stone,
				Enum.Material.Slate,
				false,
				0.55
			)
			makeCylinderY(
				m,
				"BarrierPost",
				cf * CFrame.new(sx * 0.7, PORTAL_BASE_H + 0.9, -4.4),
				1.8,
				0.4,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
		end
		makeRope(
			m,
			"BarrierRope",
			(cf * CFrame.new(-3.08, PORTAL_BASE_H + 1.6, -4.4)).Position,
			(cf * CFrame.new(3.08, PORTAL_BASE_H + 1.6, -4.4)).Position,
			0.4,
			0.2,
			PALETTE.red
		)
		makeSign(
			m,
			"SoonSign",
			cf * CFrame.new(0, PORTAL_BASE_H + 4.6, 0),
			5.6,
			1.8,
			"EM BREVE",
			"Nova expedição",
			PALETTE.signBg,
			PALETTE.signText,
			PALETTE.crystalCyan,
			PALETTE.gold,
			true
		)
		makeCrate(m, "SlotCrate", cf * CFrame.new(3.2, PORTAL_BASE_H + 0.55, 1.6), 1.1)
		makeCrystalCluster(
			m,
			"SlotCrystal",
			(cf * CFrame.new(-3.0, PORTAL_BASE_H, 2.0)).Position,
			0.5,
			PALETTE.crystalLilac,
			false
		)
	end
	task.wait()

	-- Wharf props.
	makeCrate(m, "WharfCrate", CY(13, Y + 0.65, 57.4, 10), 1.3)
	makeCrate(m, "WharfCrate", CY(14.5, Y + 0.6, 57.6, -12), 1.2)
	makeCrate(m, "WharfCrate", CY(13.6, Y + 1.85, 57.4, 25), 1.1)
	makeBarrel(m, "WharfBarrel", V(12.6, Y, 40), 1.8)
	makeBarrel(m, "WharfBarrel", V(13.2, Y, 42.2), 1.6)
	makeBarrel(m, "WharfBarrel", V(59.4, Y, 32.8), 1.7)
	makeCrate(m, "WharfCrate", CY(59.2, Y + 0.6, 35, 5), 1.2)
	for _, p in
		{
			{ 10.4, 37.5 },
			{ 10.4, 50 },
			{ 61.6, 34.5 },
			{ 61.6, 54 },
			{ 26, 59.6 },
			{ 38, 59.6 },
			{ 50, 59.6 },
		}
	do
		makeLantern(m, "WharfLantern", V(p[1], Y + 0.5, p[2]), 3.6, true)
	end
	for _, p in { { 22, 30.4 }, { 30, 30.4 }, { 40, 30.4 }, { 50, 30.4 } } do
		makeCylinderY(
			m,
			"Bollard",
			C(p[1], Y + 0.9, p[2]),
			1.0,
			1.0,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeCylinderY(
			m,
			"BollardCap",
			C(p[1], Y + 1.45, p[2]),
			0.25,
			1.25,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
	end
	makeNet(m, "CurbNet", V(23, Y + 1.0, 30.0), V(29, Y + 1.0, 30.0), 1.6)
	makeCrystalCluster(
		m,
		"WharfCrystal",
		V(60.2, Y, 58.2),
		1.0,
		PALETTE.crystalCyan,
		true,
		PALETTE.crystalPink
	)
	makeCrystalCluster(m, "WharfCrystal", V(11.8, Y, 58.6), 0.8, PALETTE.crystalLilac, true)
	makeBunting(m, "WharfBunting", V(26, Y + 4.9, 59.6), V(38, Y + 4.9, 59.6), 1.0)
	makeBunting(m, "WharfBunting", V(38, Y + 4.9, 59.6), V(50, Y + 4.9, 59.6), 1.0)
	-- Anchor decoration.
	do
		local a = V(58.6, Y, 57.6)
		makeTube(
			m,
			"Anchor",
			a + Vector3.new(0, 0.4, 0),
			a + Vector3.new(0, 3.4, 0),
			0.35,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Anchor",
			a + Vector3.new(-1.0, 2.8, 0),
			a + Vector3.new(1.0, 2.8, 0),
			0.3,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Anchor",
			a + Vector3.new(-1.4, 1.2, 0),
			a + Vector3.new(0, 0.4, 0),
			0.35,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Anchor",
			a + Vector3.new(1.4, 1.2, 0),
			a + Vector3.new(0, 0.4, 0),
			0.35,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeNeonRing(
			m,
			"AnchorRing",
			CFrame.new(a + Vector3.new(0, 3.8, 0)) * CFrame.Angles(math.pi / 2, 0, 0),
			0.4,
			0.2,
			8,
			PALETTE.metal,
			0,
			Enum.Material.Metal
		)
	end

	-- Curved boardwalk from the pier's south side to the wharf's east entrance.
	local pts = {
		Vector3.new(63, PIER_Y, 13.05),
		Vector3.new(63, PIER_Y, 17.5),
		Vector3.new(66.8, PIER_Y, 23.2),
		Vector3.new(69.4, PIER_Y - 0.1, 30),
		Vector3.new(68.6, PIER_Y - 0.45, 36.6),
		Vector3.new(66.4, (PIER_Y + WHARF_Y) / 2, 43),
		Vector3.new(62.05, WHARF_Y, 43),
	}
	local w = 6
	for i = 1, #pts - 1 do
		local a = O + pts[i]
		local b = O + pts[i + 1]
		local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local len = flat.Magnitude
		local mid = (a + b) / 2
		local cf = CFrame.lookAt(mid, mid + flat.Unit)
			* CFrame.Angles(math.atan2(b.Y - a.Y, len), 0, 0)
		makePlankDeck(m, "Boardwalk", cf, w, len, 0.8, PALETTE.wood)
		if i > 1 then
			makeCylinderY(
				m,
				"BoardwalkJoint",
				CFrame.new(a - Vector3.new(0, 0.4, 0)),
				0.8,
				w,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
		end
		makeCylinderY(
			m,
			"BoardwalkPiling",
			CFrame.new(mid + Vector3.new(0, -5.2, 0)),
			9.6,
			0.9,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	-- Rails: outer side (east) and inner side (west), skipping the display pads.
	local function sideOffset(i: number): Vector3
		local prevP = pts[math.max(i - 1, 1)]
		local nextP = pts[math.min(i + 1, #pts)]
		local d = Vector3.new(nextP.X - prevP.X, 0, nextP.Z - prevP.Z).Unit
		return Vector3.new(-d.Z, 0, d.X)
	end
	for _, side in { -1, 1 } do
		local prevTop: Vector3? = nil
		for i = 2, #pts - 1 do
			local off = sideOffset(i) * side * (w / 2 + 0.25)
			local base = O + pts[i] + off
			local outer = side == -1
			local skip = outer and (i == 3 or i == 5)
			if skip then
				prevTop = nil
			else
				local top = base + Vector3.new(0, 1.4, 0)
				makeCylinderY(
					m,
					"RailPost",
					CFrame.new(base + Vector3.new(0, 0.2, 0)),
					2.6,
					0.5,
					PALETTE.woodDark,
					Enum.Material.Wood,
					true
				)
				makeCylinderY(
					m,
					"RailKnot",
					CFrame.new(top - Vector3.new(0, 0.3, 0)),
					0.3,
					0.62,
					PALETTE.rope,
					Enum.Material.Fabric,
					false
				)
				local p = prevTop
				if p then
					makeRope(
						m,
						"BoardwalkRail",
						p - Vector3.new(0, 0.3, 0),
						top - Vector3.new(0, 0.3, 0),
						0.45,
						0.22
					)
				end
				prevTop = top
				if i == 4 then
					makeLanternBody(
						m,
						"BoardwalkLantern",
						top + Vector3.new(0, 0.9, 0),
						0.75,
						outer
					)
				end
			end
		end
	end
	-- Crystal display pads on the outer side (concept).
	for _, i in { 3, 5 } do
		local off = sideOffset(i) * -1 * (w / 2 + 1.9)
		local c = O + pts[i] + off
		makeCylinderY(
			m,
			"DisplayPad",
			CFrame.new(c - Vector3.new(0, 0.4, 0)),
			0.8,
			5.2,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeCylinderY(
			m,
			"DisplayPadTop",
			CFrame.new(c + Vector3.new(0, 0.03, 0)),
			0.06,
			4.8,
			PALETTE.woodLight,
			Enum.Material.Wood,
			false
		)
		makeCylinderY(
			m,
			"DisplayStone",
			CFrame.new(c + Vector3.new(0, 0.35, 0)),
			0.6,
			3.0,
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		makeCrystalCluster(
			m,
			"DisplayCrystal",
			c + Vector3.new(0, 0.65, 0),
			0.75,
			if i == 3 then PALETTE.white else PALETTE.crystalCyan,
			true
		)
		makeBuoy(
			m,
			"PadBuoy",
			faceTo(c + off.Unit * 2.7 + Vector3.new(0, -0.2, 0), c + off.Unit * 6),
			0.7
		)
	end
	makeBunting(
		m,
		"BoardwalkBunting",
		O + pts[2] + sideOffset(2) * -3.25 + Vector3.new(0, 4.2, 0),
		O + pts[4] + sideOffset(4) * -3.25 + Vector3.new(0, 4.2, 0),
		1.2
	)
	makeCylinderY(
		m,
		"BuntingPole",
		CFrame.new(O + pts[2] + sideOffset(2) * -3.25 + Vector3.new(0, 2.2, 0)),
		4.4,
		0.35,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeCylinderY(
		m,
		"BuntingPole",
		CFrame.new(O + pts[4] + sideOffset(4) * -3.25 + Vector3.new(0, 2.2, 0)),
		4.4,
		0.35,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
end

---------------------------------------------------------------------------------------
-- Region: Training Sanctuary (gate + rune stairs + plateau with 4 portals)
---------------------------------------------------------------------------------------

-- Giant blossom tree: twisted trunk, layered petal canopy, falling petals (ref).
local function makeFlowerTree(parent: Instance, name: string, base: Vector3, scale: number)
	local s = scale
	-- Twisted trunk: 4 segments that wander around the axis.
	local pts = {
		base - Vector3.new(0, 0.8, 0),
		base + Vector3.new(0.9, 2.6, 0.4) * s,
		base + Vector3.new(-0.4, 5.0, 1.0) * s,
		base + Vector3.new(0.8, 7.2, 0.2) * s,
		base + Vector3.new(0.3, 8.6, -0.3) * s,
	}
	for i = 1, #pts - 1 do
		local d = lerp(2.8, 1.6, i / (#pts - 1)) * s
		makeTube(
			parent,
			name .. "Trunk",
			pts[i],
			pts[i + 1],
			d,
			if i % 2 == 0 then PALETTE.bark else PALETTE.barkDark,
			Enum.Material.Wood,
			true
		)
		makeBall(parent, name .. "Knot", pts[i + 1], d * 1.05, PALETTE.barkDark, Enum.Material.Wood)
	end
	-- Roots.
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		makeTube(
			parent,
			name .. "Root",
			base + Vector3.new(0, 0.9, 0) * s,
			base + Vector3.new(math.cos(a) * 2.6, -0.4, math.sin(a) * 2.6) * s,
			0.9 * s,
			PALETTE.barkDark,
			Enum.Material.Wood,
			false
		)
	end
	local top = pts[#pts]
	local branchEnds: { Vector3 } = {}
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + 0.3
		local e = top + Vector3.new(math.cos(a) * 5.2 * s, rnd(0.8, 2.4) * s, math.sin(a) * 5.2 * s)
		makeTube(
			parent,
			name .. "Branch",
			top - Vector3.new(0, 1.2 * s, 0),
			e,
			0.9 * s,
			PALETTE.bark,
			Enum.Material.Wood,
			false
		)
		branchEnds[i] = e
	end
	-- Layered canopy: lower ring, middle ring, crown.
	local tiers = {
		{ y = 0.6, r = 6.4, count = 9, size = 6.0, col = PALETTE.pink },
		{ y = 3.0, r = 4.6, count = 7, size = 6.2, col = vary(PALETTE.pink, 0.04) },
		{ y = 5.2, r = 2.4, count = 5, size = 5.6, col = PALETTE.pinkLight },
	}
	for _, t in tiers do
		for k = 1, t.count do
			local a = k / t.count * math.pi * 2 + t.y
			local c = top
				+ Vector3.new(
					math.cos(a) * t.r * s,
					t.y * s + rnd(-0.4, 0.4),
					math.sin(a) * t.r * s
				)
			makeEllipsoid(
				parent,
				name .. "Bloom",
				CFrame.new(c) * CFrame.Angles(0, a, 0),
				Vector3.new(t.size, t.size * 0.66, t.size * 0.9) * s * rnd(0.85, 1.1),
				vary(t.col, 0.04),
				Enum.Material.SmoothPlastic
			)
		end
	end
	makeEllipsoid(
		parent,
		name .. "BloomCrown",
		CFrame.new(top + Vector3.new(0, 7.0 * s, 0)),
		Vector3.new(6.5, 4.5, 6.5) * s,
		PALETTE.pinkLight,
		Enum.Material.SmoothPlastic
	)
	-- Big five-petal flowers on the canopy surface.
	for i = 1, 18 do
		local a = rnd(0, math.pi * 2)
		local r = rnd(3, 8.5) * s
		local e = top
			+ Vector3.new(
				math.cos(a) * r,
				(lerp(4.5, 1.2, r / (8.5 * s)) + rnd(0.6, 1.6)) * s,
				math.sin(a) * r
			)
		local fs = rnd(0.5, 0.8) * s
		for k = 0, 4 do
			local pa = k / 5 * math.pi * 2
			makeBall(
				parent,
				name .. "Petal",
				e + Vector3.new(math.cos(pa) * fs, 0, math.sin(pa) * fs),
				fs * 1.25,
				if i % 3 == 0 then PALETTE.white else PALETTE.pinkLight,
				Enum.Material.SmoothPlastic
			)
		end
		makeBall(
			parent,
			name .. "PetalCenter",
			e + Vector3.new(0, 0.12, 0),
			fs * 0.8,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end
	-- Falling petals + petals on the ground.
	local emitterPart = makePart(
		parent,
		name .. "PetalEmitter",
		CFrame.new(top + Vector3.new(0, 2 * s, 0)),
		Vector3.new(14, 1, 14) * s,
		PALETTE.pink,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE_TEXTURE
	e.Color = ColorSequence.new(PALETTE.pink, PALETTE.pinkLight)
	e.LightEmission = 0.2
	e.Rate = 7
	e.Lifetime = NumberRange.new(4, 6)
	e.Speed = NumberRange.new(0.5, 1.2)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = Vector3.new(0.6, -1.0, 0.3)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.Size = NumberSequence.new(0.35, 0.25)
	e.Parent = emitterPart
	stats.emitters += 1
	for i = 1, 26 do
		local a = rnd(0, math.pi * 2)
		local r = rnd(2, 8) * s
		makePart(
			parent,
			name .. "FallenPetal",
			CFrame.new(base + Vector3.new(math.cos(a) * r, 0.03, math.sin(a) * r))
				* CFrame.Angles(0, rnd(0, 6.28), 0),
			Vector3.new(0.5, 0.04, 0.32),
			vary(PALETTE.pink, 0.06),
			Enum.Material.SmoothPlastic,
			false
		)
	end
end

local function buildSanctuary(root: Instance, contract: Instance)
	local m = makeModel(root, "TrainingSanctuary")
	local Y = PLAZA_Y
	local steps = 18
	local rise = (SANCT_Y - PLAZA_Y - 0.05) / steps

	-- Bottom landing X -35..-30, Z -27..-17 (touches the plaza west edge).
	makePart(
		m,
		"GateLanding",
		C(-32.5, Y - 2.25, -22),
		Vector3.new(5, 4.5, 10),
		PALETTE.stone,
		Enum.Material.Pavement,
		true
	)
	makePart(
		m,
		"GateLandingInlay",
		C(-32.5, Y + 0.02, -22),
		Vector3.new(3.4, 0.06, 8.4),
		PALETTE.slateInlay,
		Enum.Material.Slate,
		false
	)
	for k = 0, 2 do
		makeRune(
			m,
			"LandingRune",
			CFrame.lookAt(V(-32.5, Y + 0.07, -25 + k * 3), V(-40, Y + 0.07, -25 + k * 3)),
			0.9,
			PALETTE.cyan
		)
	end

	-- Wide stairs climbing west (X -35 -> -53), glowing rune on every step.
	makeStairs(
		m,
		"SanctuaryStairs",
		V(-35, Y, -22),
		Vector3.new(-1, 0, 0),
		9,
		steps,
		rise,
		1,
		Y - 4.5,
		PALETTE.stone,
		Enum.Material.Slate,
		PALETTE.stoneWarm
	)
	for i = 1, steps do
		local top = Y + rise * i
		local x = -35 - (i - 0.5)
		makeRune(
			m,
			"StepRune",
			CFrame.lookAt(V(x, top + 0.025, -22), V(x - 5, top + 0.025, -22)),
			0.6,
			PALETTE.cyan
		)
		for _, z in { -27.1, -16.9 } do
			local wallTop = top + 1.0
			makePart(
				m,
				"StairWall",
				C(x, (wallTop + Y - 4.5) / 2, z),
				Vector3.new(1.02, wallTop - (Y - 4.5), 1.2),
				vary(PALETTE.stoneMid, 0.02),
				Enum.Material.Slate,
				true
			)
			makePart(
				m,
				"StairWallCap",
				C(x, wallTop + 0.08, z),
				Vector3.new(1.06, 0.16, 1.45),
				PALETTE.stoneWarm,
				Enum.Material.Slate,
				false
			)
			if i == 4 or i == 10 or i == 16 then
				makeStoneLantern(m, "StairLantern", V(x, wallTop + 0.16, z), true)
			elseif (i == 7 and z < -20) or (i == 13 and z > -20) then
				makeCrystalCluster(
					m,
					"StairCrystal",
					V(x, wallTop + 0.16, z),
					0.55,
					if z < -20 then PALETTE.crystalCyan else PALETTE.crystalLilac,
					true
				)
			end
		end
	end
	-- Upper landing (just under the plateau floor so they never z-fight).
	makePart(
		m,
		"UpperLanding",
		C(-55.5, SANCT_Y - 0.05 - 2.5, -22),
		Vector3.new(5, 5, 10),
		PALETTE.stone,
		Enum.Material.Pavement,
		true
	)
	task.wait()

	-- Gate "SANTUÁRIO DO TREINO" over the landing.
	for _, z in { -27.95, -16.05 } do
		local base = V(-33.2, Y - 2.5, z)
		local y = 0
		for i, bh in { 4.4, 2.1, 2.2, 2.0, 1.4 } do
			local w = if i % 2 == 0 then 2.1 else 2.4
			makePart(
				m,
				"GatePillar",
				CFrame.new(base + Vector3.new(0, y + bh / 2, 0))
					* CFrame.Angles(0, math.rad(rnd(-4, 4)), 0),
				Vector3.new(w, bh - 0.08, w),
				vary(PALETTE.stone, 0.03),
				Enum.Material.Slate,
				true
			)
			y += bh
		end
		makeCylinderY(
			m,
			"GateLog",
			CFrame.new(base + Vector3.new(-1.6, 6.4, 0)),
			12.8,
			1.2,
			PALETTE.bark,
			Enum.Material.Wood,
			true
		)
		makeCrystalCluster(
			m,
			"GateCrystal",
			V(-33.2, Y + 10.5, if z < -22 then -29.7 else -14.3),
			0.65,
			PALETTE.crystalCyan,
			true,
			PALETTE.crystalPink
		)
		local lp = V(-31.85, Y + 6.1, z)
		makeTube(
			m,
			"GateHook",
			V(-32.0, Y + 7.6, z),
			lp + Vector3.new(0, 1.0, 0),
			0.14,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeLanternBody(m, "GateLantern", lp, 0.9, true)
		makeStoneLantern(m, "GateTorch", V(-30.9, Y, if z < -22 then -26.1 else -17.9), true)
	end
	makeTube(
		m,
		"GateBeam",
		V(-33.2, Y + 9.9, -30.4),
		V(-33.2, Y + 9.9, -13.6),
		1.5,
		PALETTE.woodWarm,
		Enum.Material.Wood,
		false
	)
	local signCf = faceTo(V(-32.7, Y + 8.1, -22), V(0, Y + 8.1, -22))
	makeSign(
		m,
		"SanctuarySign",
		signCf,
		9.2,
		2.8,
		"SANTUÁRIO DO TREINO",
		"4 ilhas de treino",
		PALETTE.signWood,
		PALETTE.signText,
		PALETTE.goldLight,
		PALETTE.woodDark,
		true
	)
	-- Dumbbell and crystal icons on the sign corners.
	do
		local l = signCf * CFrame.new(-3.9, -0.6, -0.35)
		makeTube(
			m,
			"Dumbbell",
			(l * CFrame.new(-0.45, 0, 0)).Position,
			(l * CFrame.new(0.45, 0, 0)).Position,
			0.16,
			PALETTE.woodDark,
			Enum.Material.Metal,
			false
		)
		for _, sx in { -0.5, 0.5 } do
			makeTube(
				m,
				"DumbbellWeight",
				(l * CFrame.new(sx - 0.1, 0, 0)).Position,
				(l * CFrame.new(sx + 0.1, 0, 0)).Position,
				0.55,
				PALETTE.woodDark,
				Enum.Material.Metal,
				false
			)
		end
		makeCrystal(
			m,
			"SignGem",
			signCf * CFrame.new(3.9, -1.0, -0.35),
			0.9,
			0.22,
			PALETTE.crystalGold,
			false
		)
	end
	makeBunting(m, "GateBunting", V(-32.3, Y + 6.2, -26.8), V(-32.3, Y + 6.2, -17.2), 0.7)
	task.wait()

	-- Plateau floor (circle r 18) with rim wall, rune circle and decor.
	local center = V(SANCT_CX, SANCT_Y, SANCT_CZ)
	makeCylinderY(
		m,
		"SanctuaryFloor",
		CFrame.new(center - Vector3.new(0, 2.5, 0)),
		5,
		SANCT_R * 2,
		PALETTE.stoneJoint,
		Enum.Material.Slate,
		true
	)
	-- Concentric slab bands in warm tones (dark joints between them).
	for i, r in { 16.4, 13.8, 11.4 } do
		flatRing(
			m,
			"FloorBand",
			CFrame.new(center + Vector3.new(0, 0.01, 0)),
			r,
			2.3,
			0.1,
			40 - i * 4,
			if i % 2 == 0 then PALETTE.stoneWarm else PALETTE.stone,
			Enum.Material.Slate,
			false
		)
	end
	flatRing(
		m,
		"RimWall",
		CFrame.new(center + Vector3.new(0, 0.5, 0)),
		17.65,
		0.9,
		1.0,
		44,
		vary(PALETTE.stoneMid, 0.02),
		Enum.Material.Slate,
		true,
		6,
		52
	)
	flatRing(
		m,
		"RimCap",
		CFrame.new(center + Vector3.new(0, 1.08, 0)),
		17.65,
		1.15,
		0.16,
		44,
		PALETTE.stoneWarm,
		Enum.Material.Slate,
		false,
		6,
		52
	)
	makeCylinderY(
		m,
		"CircleInlay",
		CFrame.new(center + Vector3.new(0, 0.08, 0)),
		0.06,
		22,
		PALETTE.stoneLight,
		Enum.Material.Slate,
		false
	)
	flatRing(
		m,
		"CircleRing",
		CFrame.new(center + Vector3.new(0, 0.12, 0)),
		10.6,
		0.6,
		0.04,
		40,
		PALETTE.slateInlay,
		Enum.Material.Slate,
		false
	)
	flatRing(
		m,
		"CircleRing",
		CFrame.new(center + Vector3.new(0, 0.12, 0)),
		8.6,
		0.4,
		0.04,
		34,
		PALETTE.stoneMid,
		Enum.Material.Slate,
		false
	)
	makeNeonRing(
		m,
		"RuneRing",
		CFrame.new(center + Vector3.new(0, 0.15, 0)),
		7.4,
		0.2,
		32,
		PALETTE.cyan,
		0.3
	)
	makeNeonRing(
		m,
		"RuneRing",
		CFrame.new(center + Vector3.new(0, 0.15, 0)),
		3.6,
		0.18,
		18,
		PALETTE.cyan,
		0.3
	)
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * 5.5, 0.14, math.sin(a) * 5.5)
		makeRune(
			m,
			"CircleRune",
			CFrame.lookAt(p, center + Vector3.new(0, 0.14, 0)),
			0.85,
			PALETTE.cyan
		)
	end
	for k = 0, 23 do
		local a = (k + 0.5) / 24 * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * 9.6, 0.14, math.sin(a) * 9.6)
		makePart(
			m,
			"CircleDash",
			CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))),
			Vector3.new(0.2, 0.05, 1.2),
			PALETTE.crystalLilac,
			Enum.Material.Neon,
			false,
			0.2
		)
	end
	makeCylinderY(
		m,
		"CorePedestal",
		CFrame.new(center + Vector3.new(0, 0.6, 0)),
		1.2,
		3.2,
		PALETTE.stone,
		Enum.Material.Slate,
		true
	)
	makeCylinderY(
		m,
		"CorePedestalTrim",
		CFrame.new(center + Vector3.new(0, 1.24, 0)),
		0.1,
		3.5,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false
	)
	makeCrystalCluster(
		m,
		"CoreCrystal",
		center + Vector3.new(0, 1.3, 0),
		1.1,
		PALETTE.crystalCyan,
		true,
		PALETTE.crystalLilac
	)
	local coreSpark = makePart(
		m,
		"CoreSparkles",
		CFrame.new(center + Vector3.new(0, 4, 0)),
		Vector3.new(4, 4, 4),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	addSparkles(coreSpark, PALETTE.crystalCyan, 6, 0.5, 1.4)
	task.wait()

	-- Four training portals in progression around the circle.
	local defs = {
		{
			ang = 120,
			style = "stone",
			primary = Color3.fromRGB(255, 186, 90),
			accent = PALETTE.white,
			title = "ILHA DO APRENDIZ",
			sub = "Treino x1 · Grátis",
			dest = "training_1",
			pid = "main_to_training_1",
			island = 1,
			beam = false,
		},
		{
			ang = 175,
			style = "reef",
			primary = Color3.fromRGB(90, 230, 200),
			accent = PALETTE.coralLight,
			title = "ILHA DO RECIFE",
			sub = "Treino x3 · 100K Poder",
			dest = "training_reef",
			pid = "main_to_training_reef",
			island = 2,
			beam = false,
		},
		{
			ang = 230,
			style = "abyss",
			primary = Color3.fromRGB(236, 140, 255),
			accent = PALETTE.crystalLilac,
			title = "ABISMO ESTELAR",
			sub = "Treino x12 · 100M Poder",
			dest = "training_abyss",
			pid = "main_to_training_abyss",
			island = 3,
			beam = false,
		},
		{
			ang = 285,
			style = "gold",
			primary = Color3.fromRGB(255, 220, 110),
			accent = PALETTE.white,
			title = "ILHA CELESTIAL",
			sub = "Treino x50 · 1T Poder",
			dest = "training_celestial",
			pid = "main_to_training_celestial",
			island = 4,
			beam = false,
		},
	}
	local subColors = { PALETTE.goldLight, PALETTE.crystalCyan, PALETTE.crystalLilac, PALETTE.gold }
	for i, d in defs do
		local a = math.rad(d.ang)
		local pos = center + Vector3.new(math.cos(a) * 12.6, 0, math.sin(a) * 12.6)
		local cf = faceTo(pos, center)
		local tcf = makePortal(m, "TrainingPortal" .. i, cf, d.style, d.primary, d.accent, d.beam)
		makeTrigger(contract, tcf, {
			PortalId = d.pid,
			ZoneId = "lagoon",
			Destination = d.dest,
			TrainingIsland = d.island,
			PrimaryColor = d.primary,
			AccentColor = d.accent,
		}, { "ZonePortal" })
		makeSign(
			m,
			"TrainingSign",
			cf * CFrame.new(0, PORTAL_BASE_H + 15.8, 0),
			7.6,
			2.3,
			d.title,
			d.sub,
			PALETTE.signBg,
			PALETTE.signText,
			subColors[i],
			PALETTE.gold,
			true
		)
		-- Progress stars on the base front.
		for k = 1, i do
			local sp = (cf * CFrame.new((k - (i + 1) / 2) * 0.9, PORTAL_BASE_H + 0.06, -4.75)).Position
			makePart(
				m,
				"ProgressStar",
				CFrame.new(sp) * CFrame.Angles(0, math.rad(45), 0),
				Vector3.new(0.5, 0.1, 0.5),
				PALETTE.gold,
				Enum.Material.Neon,
				false,
				0.05
			)
		end
	end
	for _, ang in { 95, 147.5, 202.5, 257.5, 310 } do
		local a = math.rad(ang)
		makeStoneLantern(
			m,
			"CircleLantern",
			center + Vector3.new(math.cos(a) * 15.2, 0, math.sin(a) * 15.2),
			true
		)
	end
	for _, ang in { 62, 100, 300, 330 } do
		local a = math.rad(ang)
		makeCrystalCluster(
			m,
			"RimCrystal",
			center + Vector3.new(math.cos(a) * 17.65, 1.16, math.sin(a) * 17.65),
			0.6,
			if ang < 200 then PALETTE.crystalPink else PALETTE.crystalCyan,
			ang == 62
		)
	end
	makeBunting(
		m,
		"CircleBunting",
		center + Vector3.new(math.cos(math.rad(95)) * 15.2, 4.6, math.sin(math.rad(95)) * 15.2),
		center + Vector3.new(math.cos(math.rad(62)) * 17.0, 4.0, math.sin(math.rad(62)) * 17.0),
		0.8
	)
	makeCylinderY(
		m,
		"BuntingPole",
		CFrame.new(
			center + Vector3.new(math.cos(math.rad(62)) * 17.0, 2.0, math.sin(math.rad(62)) * 17.0)
		),
		4.0,
		0.35,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeFlowerTree(m, "BlossomTree", V(-86, groundY(-86, -13), -13), 1.7)
end

---------------------------------------------------------------------------------------
-- Region: Lagoon gate (Apprentice portal facing the plaza, waterfall behind)
---------------------------------------------------------------------------------------

local function buildLagoonGate(root: Instance, contract: Instance)
	local m = makeModel(root, "LagoonGate")
	local Y = PLAZA_Y

	local PZ = LAGOON_PORTAL_POS.Z
	-- Wide, gently arched bridge from the plaza to the portal deck (ref-5).
	makeArchBridge(m, "ApprenticeBridge", V(-30.25, Y, PZ), V(-39.75, Y, PZ), 7, 0.7)

	-- Portal deck X -51..-40 on stilts in the lagoon.
	makePlankDeck(m, "PortalDeck", C(-45.5, Y, PZ), 11, 11, 1.0, PALETTE.woodWarm)
	for _, p in
		{
			{ -50.6, PZ - 5.1 },
			{ -50.6, PZ + 5.1 },
			{ -40.4, PZ - 5.1 },
			{ -40.4, PZ + 5.1 },
			{ -45.5, PZ - 5.1 },
			{ -45.5, PZ + 5.1 },
		}
	do
		makeCylinderY(
			m,
			"Stilt",
			C(p[1], (Y - 1 + 3.5) / 2, p[2]),
			Y - 1 - 3.5,
			0.9,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	-- Rope rails (north, south and west) on the deck.
	local zn, zs = PZ - 5.75, PZ + 5.75
	local railPts = {
		{ V(-40.4, Y, zn), V(-43, Y, zn), V(-45.5, Y, zn), V(-48, Y, zn), V(-51.25, Y, zn) },
		{ V(-40.4, Y, zs), V(-43, Y, zs), V(-45.5, Y, zs), V(-48, Y, zs), V(-51.25, Y, zs) },
		{ V(-51.25, Y, zn), V(-51.25, Y, PZ - 2), V(-51.25, Y, PZ + 2), V(-51.25, Y, zs) },
	}
	for _, line in railPts do
		for i, p in line do
			makeCylinderY(
				m,
				"RailPost",
				CFrame.new(p + Vector3.new(0, 1.1, 0)),
				2.6,
				0.5,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			makeCylinderY(
				m,
				"RailKnot",
				CFrame.new(p + Vector3.new(0, 2.05, 0)),
				0.3,
				0.62,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			if i > 1 then
				makeRope(
					m,
					"DeckRail",
					line[i - 1] + Vector3.new(0, 2.05, 0),
					p + Vector3.new(0, 2.05, 0),
					0.35,
					0.22
				)
			end
		end
	end

	-- Apprentice portal (first portal of the tutorial), facing the plaza (+X).
	local pcf = faceTo(V(LAGOON_PORTAL_POS.X, Y, PZ), V(0, Y, PZ))
	local tcf = makePortal(m, "ApprenticePortal", pcf, "stone", PALETTE.cyan, PALETTE.white, false)
	makeTrigger(contract, tcf, {
		PortalId = "lagoon_to_training_1",
		ZoneId = "lagoon",
		Destination = "training_1",
		TrainingIsland = 1,
		PrimaryColor = PALETTE.cyan,
		AccentColor = PALETTE.white,
	}, { "ZonePortal", "TrainingPortalGuide" })
	makeSign(
		m,
		"ApprenticePortalSign",
		pcf * CFrame.new(0, PORTAL_BASE_H + 15.6, 0),
		7.6,
		2.3,
		"ILHA DO APRENDIZ",
		"Treino x1 · Grátis",
		PALETTE.signBg,
		PALETTE.signText,
		PALETTE.crystalCyan,
		PALETTE.gold,
		true
	)
	-- Small sign on the deck corner, readable from the bridge.
	makeCylinderY(
		m,
		"DeckSignPost",
		C(-40.9, Y + 1.6, PZ - 4.9),
		3.2,
		0.45,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	makeSign(
		m,
		"ApprenticeDeckSign",
		faceTo(V(-40.9, Y + 3.7, PZ - 4.9), V(0, Y + 3.7, PZ - 4.9)),
		4.4,
		1.6,
		"ILHA DO APRENDIZ",
		"Grátis",
		PALETTE.signBg,
		PALETTE.signText,
		PALETTE.crystalCyan,
		PALETTE.gold,
		true
	)
	for _, z in { PZ + 4.8, PZ - 4.8 } do
		makeCrystalCluster(
			m,
			"DeckCrystal",
			V(-50.2, Y, z),
			0.85,
			PALETTE.crystalCyan,
			true,
			PALETTE.crystalLilac
		)
	end
	makeFern(m, "DeckFern", V(-50.0, Y, PZ + 2.6), 0.8)
	task.wait()

	-- Waterfall (sheet + streaks + foam + mist) falling into the lagoon behind the portal.
	local dir = Vector3.new(-0.464, 0, -0.886).Unit -- from lagoon center toward the cliff (right of the portal)
	local fallXZ = Vector3.new(LAGOON_CX, 0, LAGOON_CZ) + dir * 15.2
	local topY = 18.6
	local bottomY = LAGOON_WATER_Y + 0.05
	local facing = -dir
	local segs = 6
	for k = 0, segs - 1 do
		local y0 = topY - (topY - bottomY) * k / segs
		local y1 = topY - (topY - bottomY) * (k + 1) / segs
		local out0 = 0.9 * (1 - k / segs) ^ 2
		local out1 = 0.9 * (1 - (k + 1) / segs) ^ 2
		local p0 = O + Vector3.new(fallXZ.X, y0, fallXZ.Z) + facing * out0
		local p1 = O + Vector3.new(fallXZ.X, y1, fallXZ.Z) + facing * out1
		local mid = (p0 + p1) / 2
		local cf = CFrame.lookAt(mid, mid + facing)
			* CFrame.Angles(math.atan2(out1 - out0, y0 - y1), 0, 0)
		makePart(
			m,
			"Waterfall",
			cf,
			Vector3.new(4.8 - k * 0.12, (p1 - p0).Magnitude + 0.15, 0.5),
			PALETTE.water,
			Enum.Material.Glass,
			false,
			0.2
		)
		for sx = -1.6, 1.6, 0.8 do
			makePart(
				m,
				"WaterStreak",
				cf * CFrame.new(sx + rnd(-0.15, 0.15), 0, -0.28),
				Vector3.new(0.16, (p1 - p0).Magnitude + 0.1, 0.05),
				PALETTE.foam,
				Enum.Material.Neon,
				false,
				0.35
			)
		end
	end
	local lip = O + Vector3.new(fallXZ.X, topY, fallXZ.Z) - facing * 2.2
	makePart(
		m,
		"WaterfallStream",
		CFrame.lookAt(lip, lip + facing) * CFrame.new(0, 0.08, 0),
		Vector3.new(3.8, 0.3, 4.6),
		PALETTE.water,
		Enum.Material.Glass,
		false,
		0.2
	)
	local foamCenter = O + Vector3.new(fallXZ.X, bottomY, fallXZ.Z) + facing * 0.9
	for k = 1, 7 do
		local off = Vector3.new(rnd(-2.2, 2.2), 0, rnd(-1.4, 1.4))
		makeEllipsoid(
			m,
			"Foam",
			CFrame.new(foamCenter + off),
			Vector3.new(rnd(1.6, 2.6), rnd(0.7, 1.1), rnd(1.6, 2.6)),
			PALETTE.foam,
			Enum.Material.SmoothPlastic,
			0.1
		)
	end
	local mistPart = makePart(
		m,
		"Mist",
		CFrame.new(foamCenter + Vector3.new(0, 0.6, 0)),
		Vector3.new(4, 0.5, 3),
		PALETTE.foam,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = SPARKLE_TEXTURE
	mist.Color = ColorSequence.new(PALETTE.foam)
	mist.LightEmission = 0.3
	mist.Rate = 14
	mist.Lifetime = NumberRange.new(1.2, 2.2)
	mist.Speed = NumberRange.new(1.5, 3)
	mist.SpreadAngle = Vector2.new(50, 50)
	mist.EmissionDirection = Enum.NormalId.Top
	mist.Acceleration = Vector3.new(0, -1.5, 0)
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 1.8),
	})
	mist.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	mist.Parent = mistPart
	stats.emitters += 1
	addLight(mistPart, PALETTE.crystalCyan, 12, 0.6)

	-- Lily pads and lotus flowers.
	local placed = 0
	local tries = 0
	while placed < 20 and tries < 300 do
		tries += 1
		local a = rnd(0, math.pi * 2)
		local r = rnd(3, 13.5)
		local x = LAGOON_CX + math.cos(a) * r
		local z = LAGOON_CZ + math.sin(a) * r
		local onDeck = inRect(x, z, -52.5, -38.5, PZ - 6.8, PZ + 6.8)
		local onBridge = inRect(x, z, -41, -28, PZ - 4.6, PZ + 4.6)
		local nearFall = dist2(x, z, fallXZ.X, fallXZ.Z) < 4.5
		if not (onDeck or onBridge or nearFall) then
			local d = rnd(1.6, 2.8)
			makeCylinderY(
				m,
				"LilyPad",
				CY(x, LAGOON_WATER_Y + 0.04, z, rnd(0, 360)),
				0.08,
				d,
				vary(PALETTE.lily, 0.06),
				Enum.Material.SmoothPlastic,
				false
			)
			if placed % 3 == 0 then
				for k = 0, 5 do
					local pa = k / 6 * math.pi * 2
					makeEllipsoid(
						m,
						"Lotus",
						CFrame.new(
							V(x + math.cos(pa) * 0.3, LAGOON_WATER_Y + 0.3, z + math.sin(pa) * 0.3)
						) * CFrame.Angles(0, -pa, math.rad(35)),
						Vector3.new(0.7, 0.3, 0.4),
						PALETTE.pinkLight,
						Enum.Material.SmoothPlastic
					)
				end
				makeBall(
					m,
					"LotusCenter",
					V(x, LAGOON_WATER_Y + 0.35, z),
					0.3,
					PALETTE.gold,
					Enum.Material.SmoothPlastic
				)
			end
			placed += 1
		end
	end
	-- Rim stones, ferns and flowers around the lagoon.
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2 + rnd(-0.08, 0.08)
		local x = LAGOON_CX + math.cos(a) * 15.8
		local z = LAGOON_CZ + math.sin(a) * 15.8
		local eastSide = x > -31
		local deckSide = inRect(x, z, -53, -37, PZ - 8, PZ + 8)
		if not eastSide and not deckSide and dist2(x, z, fallXZ.X, fallXZ.Z) > 3.5 then
			makeEllipsoid(
				m,
				"RimStone",
				CFrame.new(V(x, LAGOON_WATER_Y + 0.2, z)) * CFrame.Angles(0, a, 0),
				Vector3.new(rnd(1.8, 2.8), rnd(1.0, 1.6), rnd(1.6, 2.4)),
				vary(PALETTE.stoneBlue, 0.05),
				Enum.Material.Slate
			)
			local fx = LAGOON_CX + math.cos(a) * 18
			local fz = LAGOON_CZ + math.sin(a) * 18
			local g = groundY(fx, fz)
			if g > 7.5 and g < 12 and not inRect(fx, fz, -58, -29, -29, -15) then
				if k % 2 == 0 then
					makeFern(m, "RimFern", V(fx, g, fz), rnd(0.8, 1.1))
				else
					makeFlower(
						m,
						"RimFlower",
						V(fx, g, fz),
						if k % 3 == 0 then PALETTE.pink else PALETTE.goldLight
					)
					makeTuft(m, "RimTuft", V(fx + 0.6, g, fz + 0.4), 0.9, PALETTE.leaf)
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------
-- Region: Aquarium deck (platform + glass tank only, no logic)
---------------------------------------------------------------------------------------

local function makeToyFish(parent: Instance, cf: CFrame, color: Color3)
	makeEllipsoid(
		parent,
		"ToyFish",
		cf,
		Vector3.new(0.5, 0.7, 1.2),
		color,
		Enum.Material.SmoothPlastic
	)
	makeWedge(
		parent,
		"ToyFishTail",
		cf * CFrame.new(0, 0, 0.75) * CFrame.Angles(0, math.pi, 0),
		Vector3.new(0.1, 0.6, 0.5),
		color,
		Enum.Material.SmoothPlastic,
		false
	)
	makeBall(
		parent,
		"ToyFishEye",
		(cf * CFrame.new(0.2, 0.12, -0.35)).Position,
		0.14,
		PALETTE.board,
		Enum.Material.SmoothPlastic
	)
end

local function buildAquarium(root: Instance)
	local m = makeModel(root, "Aquarium")
	local Y = PLAZA_Y

	-- Walkway from the plaza's south-west corner, then the deck X -50..-24, Z 35..55.
	makePlankDeck(m, "AquariumWalk", C(-27, Y, 29.525), 6, 10.95, 0.8, PALETTE.wood)
	makePlankDeck(m, "AquariumDeck", C(-37, Y, 45), 26, 20, 1.0, PALETTE.woodWarm)
	for _, p in
		{
			{ -49.4, 35.6 },
			{ -49.4, 54.4 },
			{ -24.6, 54.4 },
			{ -37, 54.4 },
			{ -37, 35.6 },
			{ -49.4, 45 },
			{ -24.6, 45 },
			{ -29.6, 30 },
			{ -24.4, 30 },
		}
	do
		makeCylinderY(
			m,
			"Stilt",
			C(p[1], (Y - 1 - 6) / 2, p[2]),
			Y - 1 + 6,
			1.0,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	-- Rope rails around the deck (entrance left open at the walkway).
	local loop = {
		V(-30.3, Y, 35.3),
		V(-37, Y, 35.3),
		V(-43.5, Y, 35.3),
		V(-50.3, Y, 35.3),
		V(-50.3, Y, 41.5),
		V(-50.3, Y, 48.5),
		V(-50.3, Y, 55.3),
		V(-43.5, Y, 55.3),
		V(-37, Y, 55.3),
		V(-30.5, Y, 55.3),
		V(-23.7, Y, 55.3),
		V(-23.7, Y, 48.5),
		V(-23.7, Y, 41.5),
		V(-23.7, Y, 35.6),
	}
	for i, p in loop do
		makeCylinderY(
			m,
			"RailPost",
			CFrame.new(p + Vector3.new(0, 1.0, 0)),
			2.4,
			0.5,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		if i > 1 then
			makeRope(
				m,
				"DeckRail",
				loop[i - 1] + Vector3.new(0, 1.9, 0),
				p + Vector3.new(0, 1.9, 0),
				0.35,
				0.22
			)
		end
	end
	for _, x in { -30.3, -23.7 } do
		makeRope(m, "WalkRail", V(x, Y + 1.9, 24.6), V(x, Y + 1.9, 35.3), 0.5, 0.22)
		makeCylinderY(
			m,
			"WalkPost",
			C(x, Y + 1.0, 24.6),
			2.4,
			0.5,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
	end

	-- Glass tank.
	local tc = V(-38, Y, 47)
	makePart(
		m,
		"TankBase",
		CFrame.new(tc + Vector3.new(0, 0.5, 0)),
		Vector3.new(14, 1, 9),
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	makePart(
		m,
		"TankBaseTrim",
		CFrame.new(tc + Vector3.new(0, 1.02, 0)),
		Vector3.new(14.3, 0.06, 9.3),
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false
	)
	local h = 6.4
	local gy = 1.05 + h / 2
	makePart(
		m,
		"TankGlass",
		CFrame.new(tc + Vector3.new(0, gy, 4.3)),
		Vector3.new(13.4, h, 0.25),
		PALETTE.glass,
		Enum.Material.Glass,
		true,
		0.6
	)
	makePart(
		m,
		"TankGlass",
		CFrame.new(tc + Vector3.new(0, gy, -4.3)),
		Vector3.new(13.4, h, 0.25),
		PALETTE.glass,
		Enum.Material.Glass,
		true,
		0.6
	)
	makePart(
		m,
		"TankGlass",
		CFrame.new(tc + Vector3.new(6.7, gy, 0)),
		Vector3.new(0.25, h, 8.4),
		PALETTE.glass,
		Enum.Material.Glass,
		true,
		0.6
	)
	makePart(
		m,
		"TankGlass",
		CFrame.new(tc + Vector3.new(-6.7, gy, 0)),
		Vector3.new(0.25, h, 8.4),
		PALETTE.glass,
		Enum.Material.Glass,
		true,
		0.6
	)
	makePart(
		m,
		"TankWater",
		CFrame.new(tc + Vector3.new(0, 1.05 + (h - 0.8) / 2, 0)),
		Vector3.new(13.1, h - 0.8, 8.3),
		PALETTE.waterDeep,
		Enum.Material.Glass,
		false,
		0.55
	)
	makePart(
		m,
		"TankSand",
		CFrame.new(tc + Vector3.new(0, 1.25, 0)),
		Vector3.new(13.1, 0.4, 8.3),
		PALETTE.sandPart,
		Enum.Material.Sand,
		false
	)
	for _, c in { { 6.8, 4.4 }, { -6.8, 4.4 }, { 6.8, -4.4 }, { -6.8, -4.4 } } do
		makePart(
			m,
			"TankFrame",
			CFrame.new(tc + Vector3.new(c[1], gy, c[2])),
			Vector3.new(0.4, h + 0.1, 0.4),
			PALETTE.navy,
			Enum.Material.Metal,
			false
		)
	end
	for _, e in
		{ { 0, 4.4, 14, 0.4 }, { 0, -4.4, 14, 0.4 }, { 6.8, 0, 0.4, 9.2 }, { -6.8, 0, 0.4, 9.2 } }
	do
		makePart(
			m,
			"TankRim",
			CFrame.new(tc + Vector3.new(e[1], 1.05 + h + 0.15, e[2])),
			Vector3.new(e[3], 0.3, e[4]),
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false
		)
	end
	-- Tank interior: coral, seaweed, crystals, toy fish, bubbles.
	for k = 1, 6 do
		local root2 = tc + Vector3.new(rnd(-5.5, 5.5), 1.45, rnd(-3.2, 3.2))
		local col = if k % 2 == 0 then PALETTE.coral else PALETTE.pink
		for b = 1, 3 do
			local tip = root2 + Vector3.new(rnd(-0.8, 0.8), rnd(1.0, 2.2), rnd(-0.6, 0.6))
			makeTube(m, "TankCoral", root2, tip, 0.25, col, Enum.Material.SmoothPlastic, false)
			makeBall(m, "TankCoralTip", tip, 0.35, col, Enum.Material.SmoothPlastic)
		end
	end
	for k = 1, 8 do
		local b = tc + Vector3.new(rnd(-6, 6), 1.45, rnd(-3.6, 3.6))
		makeWedge(
			m,
			"Seaweed",
			CFrame.new(b + Vector3.new(0, 1.2, 0))
				* CFrame.Angles(0, rnd(0, 6.28), math.rad(rnd(-10, 10))),
			Vector3.new(0.1, 2.4, 0.5),
			PALETTE.teal,
			Enum.Material.SmoothPlastic,
			false
		)
	end
	makeCrystalCluster(
		m,
		"TankCrystal",
		tc + Vector3.new(3.5, 1.45, -1.5),
		0.45,
		PALETTE.crystalCyan,
		true
	)
	makeCrystalCluster(
		m,
		"TankCrystal",
		tc + Vector3.new(-4.2, 1.45, 1.8),
		0.4,
		PALETTE.crystalPink,
		false
	)
	local fishCols =
		{ PALETTE.gold, PALETTE.coral, PALETTE.crystalLilac, PALETTE.cyan, PALETTE.pink }
	for k = 1, 7 do
		local p = tc + Vector3.new(rnd(-5.4, 5.4), rnd(2.6, 5.8), rnd(-3, 3))
		makeToyFish(
			m,
			CFrame.new(p) * CFrame.Angles(0, rnd(0, 6.28), 0),
			fishCols[(k - 1) % #fishCols + 1]
		)
	end
	local bubbles = makePart(
		m,
		"TankBubbles",
		CFrame.new(tc + Vector3.new(0, 2, 0)),
		Vector3.new(12, 0.5, 7),
		PALETTE.white,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	local be = Instance.new("ParticleEmitter")
	be.Texture = SPARKLE_TEXTURE
	be.Color = ColorSequence.new(PALETTE.white)
	be.Rate = 5
	be.Lifetime = NumberRange.new(1.4, 2.0)
	be.Speed = NumberRange.new(1.6, 2.4)
	be.EmissionDirection = Enum.NormalId.Top
	be.SpreadAngle = Vector2.new(5, 5)
	be.Size = NumberSequence.new(0.2, 0.3)
	be.Parent = bubbles
	stats.emitters += 1

	-- Deck props.
	makeCylinderY(
		m,
		"AquariumSignPost",
		C(-31.2, Y + 2.4, 36.8),
		4.8,
		0.5,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	makeSign(
		m,
		"AquariumSign",
		faceTo(V(-31.2, Y + 4.2, 36.8), V(-31.2, Y + 4.2, 0)),
		4.6,
		1.6,
		"AQUÁRIO",
		"Seus peixes raros",
		PALETTE.signBg,
		PALETTE.signText,
		PALETTE.crystalCyan,
		PALETTE.gold,
		true
	)
	makeBench(m, "AquariumBench", CY(-38, Y, 39.6, 180))
	for _, p in { { -49.4, 54.4 }, { -24.6, 54.4 }, { -49.4, 35.6 } } do
		makeLantern(m, "DeckLantern", V(p[1], Y, p[2]), 3.4, true)
	end
	makeBarrel(m, "DeckBarrel", V(-48.4, Y, 41.2), 1.6)
	makePlanter(m, "DeckPlanter", V(-25.6, Y, 53.4), PALETTE.crystalCyan)
	makePlanter(m, "DeckPlanter", V(-48.6, Y, 52.8), PALETTE.crystalPink)
	makeBunting(m, "DeckBunting", V(-49.4, Y + 4.3, 54.4), V(-24.6, Y + 4.3, 54.4), 1.4)
end

---------------------------------------------------------------------------------------
-- Region: decoration (palms, crystals, vegetation, sea crystals, scoreboards frames)
---------------------------------------------------------------------------------------

local function isBuiltArea(x: number, z: number): boolean
	return inRect(x, z, -33, 20, -24, 27) -- plaza + edges
		or inRect(x, z, -29, 17, -51, -20) -- workshop terrace
		or dist2(x, z, LAGOON_CX, LAGOON_CZ) < 17.5
		or inRect(x, z, -59, -29, -29, -14) -- sanctuary stairs
		or dist2(x, z, SANCT_CX, SANCT_CZ) < 18.8
		or inRect(x, z, -19, 7, 22, 64) -- front stairs
		or inRect(x, z, -53, -21, 22, 58) -- aquarium
		or (x > 7 and z > 21) -- wharf
		or (x > 11 and z > -4 and z < 19) -- pier
		or inRect(x, z, -53, -27, -15, 4) -- lagoon bridge/deck
end

local function buildDecor(root: Instance): Model
	local m = makeModel(root, "Decor")

	-- Palms (only where the ground is real land).
	-- (few and well chosen: 2 on the terrace are built with the Workshop)
	local palms = { { -58, 15 }, { -21.5, 29.5 } }
	for i, p in palms do
		local g = groundY(p[1], p[2])
		if g > 3 then
			makePalm(m, "Palm" .. i, V(p[1], g, p[2]), rnd(10, 14), rnd(0, 360))
		end
	end
	task.wait()

	-- Big crystal tufts embedded in the cliffs (ice-blue, pink, lilac), tilted outward.
	local cliffCols = { PALETTE.crystalCyan, PALETTE.crystalPink, PALETTE.crystalLilac }
	local placedC = 0
	for i = 0, 63 do
		if placedC >= 16 then
			break
		end
		local a = i / 64 * math.pi * 2 + 0.05
		-- walk outward from the island center until the ground drops: that is the cliff lip
		for r = 30, 60, 1.5 do
			local x = -22 + math.cos(a) * r
			local z = 2 + math.sin(a) * r * 0.82
			local g = heightAt(x, z)
			if g < 5 then
				local lx = -22 + math.cos(a) * (r - 2.5)
				local lz = 2 + math.sin(a) * (r - 2.5) * 0.82
				local lg = groundY(lx, lz)
				if i % 4 == 0 and lg > 6 and not isBuiltArea(lx, lz) then
					local out = Vector3.new(math.cos(a), 0, math.sin(a))
					local base = V(lx, lg - 1.5, lz)
					local col = cliffCols[placedC % 3 + 1]
					for k = 1, 4 do
						local off = Vector3.new(rnd(-1.6, 1.6), rnd(-1, 0.5), rnd(-1.6, 1.6))
						local cf = CFrame.lookAt(base + off, base + off + out)
							* CFrame.Angles(math.rad(-90 + rnd(25, 50)), 0, 0)
						makeCrystal(
							m,
							"CliffCrystal",
							cf,
							rnd(3.5, 6.5),
							rnd(0.6, 1.0),
							vary(col, 0.05),
							k == 1
						)
					end
					placedC += 1
				end
				break
			end
		end
	end
	-- Crystal clusters on the hill, shoulders and islet.
	local crystals = {
		{ -22, -57, PALETTE.crystalCyan },
		{ -15, -61, PALETTE.crystalLilac },
		{ 12, -58, PALETTE.crystalCyan },
		{ -36, -45, PALETTE.crystalCyan },
		{ 23, -42, PALETTE.crystalLilac },
		{ -72, 14, PALETTE.crystalCyan },
		{ -71, 23, PALETTE.crystalPink },
		{ -60, 22, PALETTE.crystalLilac },
		{ -88, 29, PALETTE.crystalCyan },
		{ -84, 32, PALETTE.crystalPink },
		{ -78, -9, PALETTE.crystalLilac },
	}
	for i, c in crystals do
		local x, z = c[1] :: number, c[2] :: number
		local g = groundY(x, z)
		if g > 4 and not isBuiltArea(x, z) then
			makeCrystalCluster(
				m,
				"Crystal" .. i,
				V(x, g, z),
				rnd(1.4, 2.2),
				c[3] :: Color3,
				i % 3 == 1,
				PALETTE.crystalPink
			)
		end
	end
	-- Islet greenery.
	for k = 1, 6 do
		local x, z = -86 + rnd(-4, 4), 30 + rnd(-3, 3)
		if k % 2 == 0 then
			makeBush(m, "IsletBush", V(x, groundY(x, z), z), rnd(0.9, 1.2))
		else
			makeFlower(m, "IsletFlower", V(x, groundY(x, z), z), PALETTE.pink)
		end
	end
	task.wait()

	-- Vegetation scatter: tufts, flowers, bushes and pebbles on flat grass.
	local tufts, flowers, bushes, pebbles = 0, 0, 0, 0
	local flowerCols = { PALETTE.pink, PALETTE.goldLight, PALETTE.white, PALETTE.crystalLilac }
	for _ = 1, 1400 do
		if tufts >= 160 and flowers >= 70 and bushes >= 28 and pebbles >= 36 then
			break
		end
		local x = rnd(-92, 34)
		local z = rnd(-84, 50)
		if not isBuiltArea(x, z) then
			local g = groundY(x, z)
			if g > 5.2 and slopeAt(x, z) < 0.55 and grassAt(x, z) then
				local roll = rng:NextNumber()
				if roll < 0.5 and tufts < 160 then
					makeTuft(
						m,
						"Tuft",
						V(x, g, z),
						rnd(0.7, 1.2),
						if rng:NextNumber() < 0.5 then PALETTE.leaf else PALETTE.leafLight
					)
					tufts += 1
				elseif roll < 0.75 and flowers < 70 then
					makeFlower(m, "Flower", V(x, g, z), flowerCols[rndInt(1, #flowerCols)])
					flowers += 1
				elseif roll < 0.88 and bushes < 28 then
					makeBush(m, "Bush", V(x, g, z), rnd(0.8, 1.3))
					bushes += 1
				elseif pebbles < 36 then
					makeEllipsoid(
						m,
						"Pebble",
						CFrame.new(V(x, g + 0.1, z)) * CFrame.Angles(0, rnd(0, 6.28), 0),
						Vector3.new(rnd(0.6, 1.4), rnd(0.35, 0.6), rnd(0.5, 1.2)),
						vary(PALETTE.stoneMid, 0.06),
						Enum.Material.Slate
					)
					pebbles += 1
				end
			end
		end
	end
	task.wait()

	-- Seashells and starfish on the beaches.
	local shells = 0
	for _ = 1, 600 do
		if shells >= 14 then
			break
		end
		local x = rnd(-95, 40)
		local z = rnd(-88, 70)
		local g = groundY(x, z)
		if
			g > 2.4
			and g < 4.6
			and sandAt(x, z, g - TERRAIN_RENDER_OFFSET)
			and not isBuiltArea(x, z)
		then
			if shells % 3 == 0 then
				for k = 0, 4 do
					local a = k / 5 * math.pi * 2
					makePart(
						m,
						"StarfishArm",
						CFrame.new(V(x, g + 0.08, z))
							* CFrame.Angles(0, a, 0)
							* CFrame.new(0, 0, -0.3),
						Vector3.new(0.22, 0.12, 0.6),
						PALETTE.coral,
						Enum.Material.SmoothPlastic,
						false
					)
				end
			else
				makeEllipsoid(
					m,
					"Shell",
					CFrame.new(V(x, g + 0.1, z)) * CFrame.Angles(0, rnd(0, 6.28), 0),
					Vector3.new(0.6, 0.3, 0.5),
					if shells % 2 == 0 then PALETTE.pinkLight else PALETTE.white,
					Enum.Material.SmoothPlastic
				)
			end
			shells += 1
		end
	end
	return m
end

---------------------------------------------------------------------------------------
-- Contract parts (spawn, fishing zone, workshop spot, scoreboards)
---------------------------------------------------------------------------------------

local function contractPart(
	contract: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	tag: string?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.CastShadow = false
	if tag then
		CollectionService:AddTag(p, tag)
	end
	p.Parent = contract
	stats.parts += 1
	return p
end

local LEADERBOARD_POS = {
	Vector3.new(-85, 36, 24),
	Vector3.new(-70, 36, 27),
	Vector3.new(-55, 36, 28),
}

local function buildContract(contract: Instance, decor: Instance)
	-- Spawn: faces the Workshop (-Z), 8 x 0.2 x 8.
	contractPart(
		contract,
		"PlayerSpawn",
		CFrame.new(O + SPAWN_POS),
		Vector3.new(8, 0.2, 8),
		"PlayerSpawn"
	)
	-- Fishing zone over the pier tip.
	local zone = contractPart(
		contract,
		"FishingZone",
		C(63, 14.1, 8),
		Vector3.new(46, 10, 14),
		"FishingZone"
	)
	zone:SetAttribute("ZoneId", "lagoon")
	zone.CanTouch = true
	-- Workshop counter spot (the server adds the OpenWorkshop prompt here).
	contractPart(contract, "WorkshopSpot", C(-6, 15.5, -38), Vector3.new(2, 1, 2), "WorkshopSpot")

	-- Scoreboards floating over the sea to the west, front face toward the plaza.
	for i, rel in LEADERBOARD_POS do
		local pos = O + rel
		-- vertical, front face toward the plaza center (no tilt)
		local cf = faceTo(pos, V(-6, rel.Y, 1))
		local board = Instance.new("Part")
		board.Name = "LeaderboardBoard"
		board.Size = Vector3.new(14, 9, 0.6)
		board.CFrame = cf
		board.Anchored = true
		board.CanCollide = false
		board.CanQuery = false
		board.CanTouch = false
		board.Color = PALETTE.board
		board.Material = Enum.Material.SmoothPlastic
		board.TopSurface = Enum.SurfaceType.Smooth
		board.BottomSurface = Enum.SurfaceType.Smooth
		board:SetAttribute("BoardIndex", i)
		CollectionService:AddTag(board, "LeaderboardBoard")
		board.Parent = contract
		stats.parts += 1
		-- Frame (decor, behind the board so the front stays flat and dark).
		makePart(
			decor,
			"BoardFrame",
			cf * CFrame.new(0, 0, 0.45),
			Vector3.new(15.2, 10.2, 0.4),
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false
		)
		makePart(
			decor,
			"BoardBack",
			cf * CFrame.new(0, 0, 0.75),
			Vector3.new(14.4, 9.4, 0.3),
			PALETTE.navy,
			Enum.Material.SmoothPlastic,
			false
		)
		makePart(
			decor,
			"BoardCrest",
			cf * CFrame.new(0, 5.6, 0.45),
			Vector3.new(4, 1.2, 0.5),
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false
		)
		makePart(
			decor,
			"BoardGem",
			cf * CFrame.new(0, 5.7, 0.1) * CFrame.Angles(0, 0, math.rad(45)),
			Vector3.new(0.9, 0.9, 0.3),
			if i == 2 then PALETTE.goldLight else PALETTE.cyan,
			Enum.Material.Neon,
			false,
			0.05
		)
		local under = (cf * CFrame.new(0, -6.8, 0.4)).Position
		makeCrystal(
			decor,
			"BoardCrystal",
			CFrame.new(under - Vector3.new(0, 1.2, 0))
				* CFrame.Angles(math.pi, 0, 0)
				* CFrame.new(0, -1.6, 0),
			2.6,
			0.55,
			PALETTE.crystalCyan,
			true
		)
		local spark = makePart(
			decor,
			"BoardSparkles",
			CFrame.new(under),
			Vector3.new(3, 1, 3),
			PALETTE.cyan,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		addSparkles(spark, PALETTE.crystalCyan, 3, 0.4, 0.6)
	end
end

---------------------------------------------------------------------------------------
-- Reference lighting (screenshots only; never called by build())
---------------------------------------------------------------------------------------

type LightingState = {
	clock: number,
	brightness: number,
	ambient: Color3,
	outdoor: Color3,
	shiftTop: Color3,
	exposure: number,
	shadows: boolean,
	diffuse: number,
	specular: number,
	bloom: number?,
	bloomSize: number?,
	sunRays: number?,
}

local savedLighting: LightingState? = nil

-- Softer preset for screenshots (V2): lower sun for relief, less bloom, no blow-out.
function Builder.applyReferenceLighting()
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if savedLighting == nil then
		savedLighting = {
			clock = Lighting.ClockTime,
			brightness = Lighting.Brightness,
			ambient = Lighting.Ambient,
			outdoor = Lighting.OutdoorAmbient,
			shiftTop = Lighting.ColorShift_Top,
			exposure = Lighting.ExposureCompensation,
			shadows = Lighting.GlobalShadows,
			diffuse = Lighting.EnvironmentDiffuseScale,
			specular = Lighting.EnvironmentSpecularScale,
			bloom = if bloom then bloom.Intensity else nil,
			bloomSize = if bloom then bloom.Size else nil,
			sunRays = if rays then rays.Intensity else nil,
		}
	end
	Lighting.ClockTime = 11.8
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(108, 106, 128)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 138, 162)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 236, 210)
	Lighting.ExposureCompensation = -0.2
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.4
	if bloom then
		bloom.Intensity = 0.3
		bloom.Size = 20
	end
	if rays then
		rays.Intensity = 0.03
	end
end

function Builder.restoreLighting()
	local s = savedLighting
	if s == nil then
		return
	end
	Lighting.ClockTime = s.clock
	Lighting.Brightness = s.brightness
	Lighting.Ambient = s.ambient
	Lighting.OutdoorAmbient = s.outdoor
	Lighting.ColorShift_Top = s.shiftTop
	Lighting.ExposureCompensation = s.exposure
	Lighting.GlobalShadows = s.shadows
	Lighting.EnvironmentDiffuseScale = s.diffuse
	Lighting.EnvironmentSpecularScale = s.specular
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	local bi, bs = s.bloom, s.bloomSize
	if bloom and bi and bs then
		bloom.Intensity = bi
		bloom.Size = bs
	end
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	local ri = s.sunRays
	if rays and ri then
		rays.Intensity = ri
	end
	savedLighting = nil
end

---------------------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------------------

function Builder.build(origin: Vector3?): Model
	local t0 = os.clock()
	O = origin or DEFAULT_ORIGIN
	rng = Random.new(SEED)
	stats.parts = 0
	stats.lights = 0
	stats.emitters = 0

	local old = Workspace:FindFirstChild(MODEL_NAME)
	while old do
		old:Destroy()
		old = Workspace:FindFirstChild(MODEL_NAME)
	end

	local root = Instance.new("Model")
	root.Name = MODEL_NAME
	local contract = makeModel(root, "Contract")

	buildTerrain()
	task.wait()
	buildPlaza(root)
	task.wait()
	buildWorkshop(root)
	task.wait()
	buildStairs(root)
	task.wait()
	buildFishingPier(root)
	task.wait()
	buildExpeditionWharf(root, contract)
	task.wait()
	buildSanctuary(root, contract)
	task.wait()
	buildLagoonGate(root, contract)
	task.wait()
	buildAquarium(root)
	task.wait()
	local decor = buildDecor(root)
	task.wait()
	buildContract(contract, decor)

	root.WorldPivot = CFrame.new(O)
	root:SetAttribute("Origin", O)
	root:SetAttribute("PartCount", stats.parts)
	root:SetAttribute("LightCount", stats.lights)
	root:SetAttribute("EmitterCount", stats.emitters)
	root.Parent = Workspace

	print(
		string.format(
			"[HubBuilder] built %s at %s: %d parts, %d lights, %d emitters in %.1fs",
			MODEL_NAME,
			tostring(O),
			stats.parts,
			stats.lights,
			stats.emitters,
			os.clock() - t0
		)
	)
	return root
end

---------------------------------------------------------------------------------------
-- Self test (returns a list of failures; empty list = everything OK)
---------------------------------------------------------------------------------------

function Builder.selfTest(origin: Vector3?): { string }
	local fails: { string } = {}
	local function fail(msg: string)
		table.insert(fails, msg)
	end
	local o: Vector3 = origin or DEFAULT_ORIGIN
	local function R(x: number, y: number, z: number): Vector3
		return o + Vector3.new(x, y, z)
	end

	local hub = Workspace:FindFirstChild(MODEL_NAME)
	if hub == nil then
		fail("Workspace." .. MODEL_NAME .. " not found (run build first)")
		return fails
	end
	-- Default to the origin the model was built at (V1 tests ran at the wrong origin).
	local stored = hub:GetAttribute("Origin")
	local o: Vector3 = origin or (if typeof(stored) == "Vector3" then stored else DEFAULT_ORIGIN)

	local all = hub:GetDescendants()
	for _, d in all do
		if d:IsA("LuaSourceContainer") then
			fail("script inside the model: " .. d:GetFullName())
		end
	end

	local function tagged(tag: string): { BasePart }
		local out: { BasePart } = {}
		for _, d in all do
			if d:IsA("BasePart") and CollectionService:HasTag(d, tag) then
				table.insert(out, d)
			end
		end
		return out
	end

	local function checkHidden(p: BasePart, label: string)
		if not p.Anchored then
			fail(label .. ": not anchored")
		end
		if p.CanCollide then
			fail(label .. ": CanCollide must be false")
		end
		if p.CanQuery then
			fail(label .. ": CanQuery must be false")
		end
	end

	-- Spawn.
	local spawns = tagged("PlayerSpawn")
	if #spawns ~= 1 then
		fail("expected 1 PlayerSpawn tag, found " .. #spawns)
	else
		local s = spawns[1]
		checkHidden(s, "PlayerSpawn")
		if s.Name ~= "PlayerSpawn" then
			fail("PlayerSpawn has wrong name: " .. s.Name)
		end
		if (s.Position - R(SPAWN_POS.X, SPAWN_POS.Y, SPAWN_POS.Z)).Magnitude > 0.05 then
			fail("PlayerSpawn position off: " .. tostring(s.Position - o))
		end
		if (s.Size - Vector3.new(8, 0.2, 8)).Magnitude > 0.01 then
			fail("PlayerSpawn size wrong: " .. tostring(s.Size))
		end
		if s.CFrame.LookVector:Dot(Vector3.new(0, 0, -1)) < 0.99 then
			fail("PlayerSpawn must face -Z (Workshop)")
		end
	end

	-- Fishing zone.
	local zones = tagged("FishingZone")
	if #zones ~= 1 then
		fail("expected 1 FishingZone, found " .. #zones)
	else
		local z = zones[1]
		checkHidden(z, "FishingZone")
		if z.Name ~= "FishingZone" then
			fail("FishingZone has wrong name")
		end
		if z:GetAttribute("ZoneId") ~= "lagoon" then
			fail("FishingZone ZoneId must be 'lagoon'")
		end
		if (z.Position - R(63, 14.1, 8)).Magnitude > 0.05 then
			fail("FishingZone position off: " .. tostring(z.Position - o))
		end
		if (z.Size - Vector3.new(46, 10, 14)).Magnitude > 0.01 then
			fail("FishingZone size wrong")
		end
		local tipLocal = z.CFrame:PointToObjectSpace(R(PIER_TIP.X, PIER_TIP.Y + 0.5, PIER_TIP.Z))
		local half = z.Size / 2
		if
			math.abs(tipLocal.X) > half.X
			or math.abs(tipLocal.Y) > half.Y
			or math.abs(tipLocal.Z) > half.Z
		then
			fail("FishingZone does not cover the pier tip")
		end
	end

	-- Workshop spot.
	local spots = tagged("WorkshopSpot")
	if #spots ~= 1 then
		fail("expected 1 WorkshopSpot, found " .. #spots)
	else
		checkHidden(spots[1], "WorkshopSpot")
		if (spots[1].Position - R(-6, 15.5, -38)).Magnitude > 0.05 then
			fail("WorkshopSpot position off")
		end
		if spots[1].Name ~= "WorkshopSpot" then
			fail("WorkshopSpot has wrong name")
		end
	end

	-- Portals.
	type Expect = { zone: string, dest: string, island: number?, guide: boolean }
	local expected: { [string]: Expect } = {
		main_to_coral = { zone = "coral", dest = "coral", island = nil, guide = false },
		main_to_abyss = { zone = "abyss", dest = "abyss", island = nil, guide = false },
		main_to_training_1 = { zone = "lagoon", dest = "training_1", island = 1, guide = false },
		main_to_training_reef = {
			zone = "lagoon",
			dest = "training_reef",
			island = 2,
			guide = false,
		},
		main_to_training_abyss = {
			zone = "lagoon",
			dest = "training_abyss",
			island = 3,
			guide = false,
		},
		main_to_training_celestial = {
			zone = "lagoon",
			dest = "training_celestial",
			island = 4,
			guide = false,
		},
		lagoon_to_training_1 = { zone = "lagoon", dest = "training_1", island = 1, guide = true },
	}
	local seen: { [string]: boolean } = {}
	local portals = tagged("ZonePortal")
	if #portals ~= 7 then
		fail("expected 7 ZonePortal triggers, found " .. #portals)
	end
	for _, p in portals do
		local id = p:GetAttribute("PortalId")
		if typeof(id) ~= "string" then
			fail("ZonePortal without PortalId: " .. p:GetFullName())
			continue
		end
		local e = expected[id]
		if e == nil then
			fail("unexpected PortalId: " .. id)
			continue
		end
		if seen[id] then
			fail("duplicate PortalId: " .. id)
		end
		seen[id] = true
		checkHidden(p, id)
		if p.Name ~= "PortalTrigger" then
			fail(id .. ": name must be PortalTrigger")
		end
		if not p.CanTouch then
			fail(id .. ": CanTouch must be true")
		end
		if p.Transparency < 1 then
			fail(id .. ": must be invisible")
		end
		if (p.Size - Vector3.new(7.2, 9.4, 4.8)).Magnitude > 0.01 then
			fail(id .. ": size must be 7.2 x 9.4 x 4.8")
		end
		if p:GetAttribute("ZoneId") ~= e.zone then
			fail(id .. ": ZoneId should be " .. e.zone)
		end
		if p:GetAttribute("Destination") ~= e.dest then
			fail(id .. ": Destination should be " .. e.dest)
		end
		if e.island ~= nil and p:GetAttribute("TrainingIsland") ~= e.island then
			fail(id .. ": TrainingIsland should be " .. tostring(e.island))
		end
		if e.island == nil then
			if
				typeof(p:GetAttribute("PrimaryColor")) ~= "Color3"
				or typeof(p:GetAttribute("AccentColor")) ~= "Color3"
			then
				fail(id .. ": PrimaryColor/AccentColor (Color3) missing")
			end
		end
		local isGuide = CollectionService:HasTag(p, "TrainingPortalGuide")
		if isGuide ~= e.guide then
			fail(
				id
					.. ": TrainingPortalGuide tag "
					.. (if e.guide then "missing" else "must not be set")
			)
		end
		if e.guide then
			local rel = p.Position - o
			if math.abs(rel.X - -46) > 1.5 or math.abs(rel.Z - -5.5) > 1.5 then
				fail(id .. ": should be near (-46, ·, -5.5), is at " .. tostring(rel))
			end
			if p.CFrame.LookVector:Dot(Vector3.new(1, 0, 0)) < 0.95 then
				fail(id .. ": should face the plaza (+X)")
			end
		end
	end
	for id in expected do
		if not seen[id] then
			fail("missing portal " .. id)
		end
	end

	-- Scoreboards.
	local boards = tagged("LeaderboardBoard")
	if #boards ~= 3 then
		fail("expected 3 LeaderboardBoard parts, found " .. #boards)
	end
	for _, b in boards do
		if (b.Position - R(-70, 36, 27)).Magnitude > 25 then
			fail("LeaderboardBoard too far from (-70, 36, 27)")
		end
	end

	-- Walkable surfaces: collidable floor at the expected height.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { hub }
	params.RespectCanCollide = true
	local walk = {
		{ "spawn", -6, 11.5, PLAZA_Y },
		{ "plaza south", -6, 19, PLAZA_Y },
		{ "plaza east", 12, -10, PLAZA_Y },
		{ "workshop stairs", -6, -17.5, PLAZA_Y + 2.0 },
		{ "workshop terrace", -1, -30, TERRACE_Y },
		{ "workshop counter front", -6, -35.5, TERRACE_Y },
		{ "front stairs", -6, 37.2, PLAZA_Y - FRONT_STAIR_RISE * 9 },
		{ "front landing", -6, 55, PLAZA_Y - FRONT_STAIR_RISE * 18 },
		{ "pier start", 25, 8, PIER_Y },
		{ "pier middle", 55, 8, PIER_Y },
		{ "pier tip", PIER_TIP.X, PIER_TIP.Z, PIER_Y },
		{ "wharf bridge", 14.5, 27, (PLAZA_Y + WHARF_Y) / 2 },
		{ "wharf", 36, 42, WHARF_Y },
		{ "boardwalk", 69.4, 30, PIER_Y - 0.1 },
		{ "lagoon bridge", -35, LAGOON_PORTAL_POS.Z, PLAZA_Y + 0.7 },
		{ "lagoon deck", -41.5, LAGOON_PORTAL_POS.Z + 4.6, PLAZA_Y },
		{ "sanctuary landing", -32.5, -22, PLAZA_Y },
		{ "sanctuary stairs", -44.5, -22, PLAZA_Y + (SANCT_Y - PLAZA_Y - 0.05) / 18 * 10 },
		{ "sanctuary plateau", -62, -30, SANCT_Y },
		{ "aquarium walkway", -27, 30, PLAZA_Y },
		{ "aquarium deck", -46, 39, PLAZA_Y },
		{ "rest deck", -13.5, 11, PLAZA_Y + 0.3 },
	}
	for _, w in walk do
		local label = w[1] :: string
		local x, z, y = w[2] :: number, w[3] :: number, w[4] :: number
		local res = Workspace:Raycast(R(x, y + 4, z), Vector3.new(0, -30, 0), params)
		if res == nil then
			fail("walkable '" .. label .. "': no collidable floor")
		else
			local hit = res.Instance
			local dy = res.Position.Y - o.Y - y
			if math.abs(dy) > 0.35 then
				fail(
					string.format(
						"walkable '%s': floor at %.2f, expected %.2f (%s)",
						label,
						res.Position.Y - o.Y,
						y,
						hit:GetFullName()
					)
				)
			end
		end
	end

	-- Terrain heights at the check points.
	local tparams = RaycastParams.new()
	tparams.FilterType = Enum.RaycastFilterType.Include
	tparams.FilterDescendantsInstances = { Workspace.Terrain }
	tparams.IgnoreWater = true
	local function terrainTop(x: number, z: number): number?
		local res = Workspace:Raycast(R(x, 80, z), Vector3.new(0, -100, 0), tparams)
		if res then
			return res.Position.Y - o.Y
		end
		return nil
	end
	local function expectMax(label: string, x: number, z: number, maxY: number)
		local h = terrainTop(x, z)
		if h and h > maxY then
			fail(
				string.format(
					"terrain at %s (%g, %g) is %.2f, must be <= %.2f",
					label,
					x,
					z,
					h,
					maxY
				)
			)
		end
	end
	for _, p in { { -6, 11.5 }, { -6, 0 }, { -20, 4 }, { 6, 4 }, { -6, -16 } } do
		expectMax("plaza", p[1], p[2], 9.05)
	end
	for _, p in { { -6, -35 }, { -20, -30 }, { 8, -30 } } do
		expectMax("workshop terrace", p[1], p[2], 13.5)
	end
	for _, p in { { -6, 30 }, { -6, 45 } } do
		expectMax("front stairs", p[1], p[2], 0)
	end
	expectMax("pier start", 14, 8, 9)
	expectMax("open sea past pier start", 20, 8, 2.5)
	local lag = terrainTop(LAGOON_CX, LAGOON_CZ)
	if lag == nil or lag < 3 or lag > 7 then
		fail("lagoon floor should be ~Y 4..6, got " .. tostring(lag))
	end
	local hill = terrainTop(-6, -62)
	if hill == nil or hill < 25 then
		fail("hill behind the Workshop should be >= 25, got " .. tostring(hill))
	end

	-- Lagoon water at Y 4..8.
	do
		local region =
			Region3.new(R(LAGOON_CX - 2, 4, LAGOON_CZ - 2), R(LAGOON_CX + 2, 8, LAGOON_CZ + 2))
				:ExpandToGrid(4)
		local mats, _occ = Workspace.Terrain:ReadVoxels(region, 4)
		local hasWater = false
		for _, plane in ipairs(mats) do
			for _, row in ipairs(plane) do
				for _, mat in ipairs(row) do
					if mat == Enum.Material.Water then
						hasWater = true
					end
				end
			end
		end
		if not hasWater then
			fail("no water found in the lagoon at Y 4..8")
		end
	end

	-- No solid terrain inside the Workshop house or above the plaza floor.
	local function expectNoSolid(label: string, a: Vector3, b: Vector3)
		local region = Region3.new(a, b):ExpandToGrid(4)
		local mats, occs = Workspace.Terrain:ReadVoxels(region, 4)
		local solid = 0
		for ix, plane in ipairs(mats) do
			for iy, row in ipairs(plane) do
				for iz, mat in ipairs(row) do
					if
						mat ~= Enum.Material.Air
						and mat ~= Enum.Material.Water
						and occs[ix][iy][iz] > 0.02
					then
						solid += 1
					end
				end
			end
		end
		if solid > 0 then
			fail(string.format("%s: %d solid terrain voxels found", label, solid))
		end
	end
	expectNoSolid("inside the Workshop house", R(-23, 16, -48), R(11, 40, -24))
	expectNoSolid("above the plaza floor", R(-28, 12, -20), R(16, 20, 24))

	return fails
end

return Builder
