--!strict
-- HubBuilder V2 (Rodada 2): builds the whole "Legendary Catch" hub island by code.
-- Usage (Studio command bar or a dev script):
--   local m = game.ServerStorage.DevTools.HubBuilder_claude:Clone()
--   local B = require(m); B.build(Vector3.new(-700, 0, 700))
--   print(table.concat(B.selfTest(Vector3.new(-700, 0, 700)), "\n"))
-- All positions below are written relative to the origin, using the server contract
-- coordinates as if the origin were (0,0,0).
--
-- Client Animation Tags (zero Scripts inside the model; runtime driven by client module):
--   HubSpin    : Attributes Speed (deg/s), Axis ("Y"|"X"|"Z"), Phase (rad, optional)
--   HubBob     : Attributes Amplitude (studs), Speed (rad/s), Phase (rad, optional)
--   HubPulse   : Attributes Min, Max, Speed (rad/s), Target ("Brightness"|"Transparency"|"Size")
--   HubFlicker : Attributes Intensity (0..1)
--   HubSway    : Attributes Angle (deg), Speed (rad/s)
--   HubWave    : Attributes Amplitude (studs), Speed (rad/s), Phase (rad, optional)

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")

local Builder = {}

---------------------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------------------

local SEED = 41873
local NOISE_Z = 17.37 -- third noise coordinate (fixed seed for math.noise)
local DEFAULT_ORIGIN = Vector3.new(0, 0, 700)
local DEFAULT_MODEL_NAME = "HubNew"
-- Test builds use "HubNew"; the live hub (HubMigration) builds as "Island" at the origin.
local MODEL_NAME = DEFAULT_MODEL_NAME

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
local FRONT_STAIR_RISE = 0.51 -- 18 steps: plaza 10.3 -> landing 1.12 (matches Luna's seaside landing Y ~1.1)
local SEA_Y = 0

-- Terrain box (relative to origin, aligned to the 4-stud voxel grid).
local TERRAIN_MIN = Vector3.new(-116, -20, -96)
local TERRAIN_MAX = Vector3.new(52, 64, 84)
local VOXEL = 4

-- Key layout anchors (relative).
local LAGOON_CX, LAGOON_CZ = -44, 2
local SANCT_CX, SANCT_CZ, SANCT_R = -74, -34, 22
local SPAWN_POS = Vector3.new(-6, 10.4, 11.5)
local FIRE_POS = Vector3.new(-16, PLAZA_Y, 11)
local PIER_TIP = Vector3.new(81, PIER_Y, 8)
local LAGOON_PORTAL_POS = Vector3.new(-49.5, PLAZA_Y + 1.35, -3.0)

local PALETTE = {
	-- Warm rosy/lilac stone (darker & richer so big surfaces never blow out under daylight).
	stone = Color3.fromRGB(182, 158, 156),
	stoneWarm = Color3.fromRGB(196, 172, 164),
	stoneLight = Color3.fromRGB(204, 182, 174),
	stoneDark = Color3.fromRGB(106, 96, 114),
	stoneMid = Color3.fromRGB(152, 134, 144),
	stoneJoint = Color3.fromRGB(96, 82, 92),
	stoneBlue = Color3.fromRGB(112, 120, 152),
	stoneGray = Color3.fromRGB(138, 140, 154),
	stoneGrayDark = Color3.fromRGB(92, 94, 112),
	slateInlay = Color3.fromRGB(54, 58, 86),
	wood = Color3.fromRGB(168, 104, 56),
	woodLight = Color3.fromRGB(196, 132, 76),
	woodDark = Color3.fromRGB(104, 64, 36),
	woodWarm = Color3.fromRGB(186, 116, 60),
	rope = Color3.fromRGB(206, 172, 114),
	roofBlue = Color3.fromRGB(58, 100, 206),
	roofBlueLight = Color3.fromRGB(88, 134, 228),
	roofBlueDark = Color3.fromRGB(40, 72, 162),
	signBg = Color3.fromRGB(30, 38, 60),
	signWood = Color3.fromRGB(116, 72, 40),
	signText = Color3.fromRGB(255, 246, 228),
	gold = Color3.fromRGB(242, 190, 66),
	goldLight = Color3.fromRGB(252, 222, 114),
	amber = Color3.fromRGB(255, 172, 58),
	flame = Color3.fromRGB(255, 128, 32),
	flameCore = Color3.fromRGB(255, 218, 88),
	cyan = Color3.fromRGB(76, 222, 255),
	cyanDeep = Color3.fromRGB(36, 164, 224),
	crystalCyan = Color3.fromRGB(132, 230, 255),
	crystalPink = Color3.fromRGB(252, 150, 214),
	crystalLilac = Color3.fromRGB(190, 152, 252),
	crystalGold = Color3.fromRGB(252, 208, 112),
	pink = Color3.fromRGB(250, 124, 180),
	pinkLight = Color3.fromRGB(252, 178, 208),
	coral = Color3.fromRGB(252, 134, 114),
	coralLight = Color3.fromRGB(252, 178, 152),
	lilac = Color3.fromRGB(162, 114, 250),
	violet = Color3.fromRGB(106, 64, 216),
	violetDark = Color3.fromRGB(56, 36, 132),
	navy = Color3.fromRGB(30, 36, 90),
	leaf = Color3.fromRGB(86, 186, 78),
	leafLight = Color3.fromRGB(132, 214, 88),
	leafDark = Color3.fromRGB(48, 138, 68),
	fern = Color3.fromRGB(62, 168, 102),
	teal = Color3.fromRGB(58, 182, 164),
	bark = Color3.fromRGB(142, 96, 64),
	barkDark = Color3.fromRGB(102, 68, 48),
	water = Color3.fromRGB(102, 214, 236),
	waterDeep = Color3.fromRGB(52, 162, 214),
	foam = Color3.fromRGB(232, 246, 252),
	white = Color3.fromRGB(244, 244, 246),
	red = Color3.fromRGB(230, 70, 70),
	metal = Color3.fromRGB(74, 80, 98),
	glass = Color3.fromRGB(192, 234, 252),
	board = Color3.fromRGB(20, 24, 42),
	lily = Color3.fromRGB(86, 182, 90),
	sandPart = Color3.fromRGB(210, 184, 140),
	peach = Color3.fromRGB(248, 166, 140),
	peachLight = Color3.fromRGB(252, 196, 172),
	coralDeep = Color3.fromRGB(224, 98, 106),
	abyssBlue = Color3.fromRGB(64, 90, 220),
	abyssBlueLight = Color3.fromRGB(118, 146, 252),
	hexPink = Color3.fromRGB(252, 114, 200),
	leafMid = Color3.fromRGB(108, 198, 84),
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
	rock = Color3.fromRGB(102, 110, 142),
	basalt = Color3.fromRGB(68, 76, 108),
	grass = Color3.fromRGB(70, 158, 88),
	sand = Color3.fromRGB(208, 180, 132),
	slate = Color3.fromRGB(12, 40, 84),
}

local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

---------------------------------------------------------------------------------------
-- Build state (reset on every build)
---------------------------------------------------------------------------------------

local O: Vector3 = DEFAULT_ORIGIN
local rng: Random = Random.new(SEED)

local stats = { parts = 0, lights = 0, emitters = 0, animTags = 0 }

-- Animation tag helpers (zero Scripts in model; client runtime animates these).
local function tagSpin(inst: Instance, speed: number, axis: string, phase: number?)
	CollectionService:AddTag(inst, "HubSpin")
	inst:SetAttribute("Speed", speed)
	inst:SetAttribute("Axis", axis)
	if phase ~= nil then
		inst:SetAttribute("Phase", phase)
	end
	stats.animTags += 1
end

local function tagBob(inst: Instance, amplitude: number, speed: number, phase: number?)
	CollectionService:AddTag(inst, "HubBob")
	inst:SetAttribute("Amplitude", amplitude)
	inst:SetAttribute("Speed", speed)
	if phase ~= nil then
		inst:SetAttribute("Phase", phase)
	end
	stats.animTags += 1
end

local function tagPulse(inst: Instance, minV: number, maxV: number, speed: number, target: string)
	CollectionService:AddTag(inst, "HubPulse")
	inst:SetAttribute("Min", minV)
	inst:SetAttribute("Max", maxV)
	inst:SetAttribute("Speed", speed)
	inst:SetAttribute("Target", target)
	stats.animTags += 1
end

local function tagFlicker(inst: Instance, intensity: number)
	CollectionService:AddTag(inst, "HubFlicker")
	inst:SetAttribute("Intensity", intensity)
	stats.animTags += 1
end

local function tagSway(inst: Instance, angle: number, speed: number)
	CollectionService:AddTag(inst, "HubSway")
	inst:SetAttribute("Angle", angle)
	inst:SetAttribute("Speed", speed)
	stats.animTags += 1
end

local function tagWave(inst: Instance, amplitude: number, speed: number, phase: number?)
	CollectionService:AddTag(inst, "HubWave")
	inst:SetAttribute("Amplitude", amplitude)
	inst:SetAttribute("Speed", speed)
	if phase ~= nil then
		inst:SetAttribute("Phase", phase)
	end
	stats.animTags += 1
end

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
	-- Sanctuary stairs climb from X -35 (Y 10.3) to X -56 (Y 20.3).
	return PLAZA_Y + clamp((-35 - x) / 21, 0, 1) * (SANCT_Y - PLAZA_Y)
end

local function terrace3(h: number): number
	-- Layered strata look: flat ledges every 3 studs with short steep risers.
	local band = math.floor(h / 3)
	local f = h / 3 - band
	return band * 3 + 3 * smoothstep(0.55, 1, f)
end

local function beachWeight(x: number, z: number): number
	-- Minimal golden sand: keep rock cliffs dominant and avoid a bright beach under the aquarium.
	if inRect(x, z, -62, -20, 26, 66) then
		return 0
	end
	return smoothstep(0.36, 0.5, noise2(x, z, 0.028, 3)) * 0.55
end

local function heightAt(x: number, z: number): number
	local n = noise2(x, z, 0.045, 1)
	local n2 = noise2(x, z, 0.11, 2)

	-- Cohesive, expanded single-mass layered rock island (no detached floating chunks in the sea).
	local m = math.min(
		ell(x, z, -22, 2, 52, 41),
		ell(x, z, -6, -62, 33, 24),
		ell(x, z, SANCT_CX, SANCT_CZ, 32, 30),
		ell(x, z, -40, 38, 19, 17),
		ell(x, z, -76, 12, 21, 21),
		ell(x, z, -82, 22, 14, 13)
	) + n * 0.14

	local land = 8.2 + n2 * 0.6
	local h: number
	if m < 0.8 then
		h = land
	else
		-- Layered rock cliff dropping steeply into the sea, tapering cleanly under water.
		local cliff: number
		if m < 1.0 then
			cliff = terrace3(lerp(land, 0.6, smoothstep(0.8, 1.0, m)))
		elseif m < 1.12 then
			cliff = lerp(0.6, -7, (m - 1.0) / 0.12)
		else
			cliff = lerp(-7, -13, clamp((m - 1.12) / 0.45, 0, 1))
		end
		local beach: number
		if m < 1.1 then
			beach = lerp(land, 0.8, smoothstep(0.8, 1.1, m))
		elseif m < 1.32 then
			beach = lerp(0.8, -4.5, (m - 1.1) / 0.22)
		else
			beach = lerp(-4.5, -13, clamp((m - 1.32) / 0.55, 0, 1))
		end
		h = lerp(cliff, beach, beachWeight(x, z))
	end

	-- Connected terraced rocky grass outcrop on the southwest cliff (ref-1/ref-2, never floating loose).
	local im = ell(x, z, -86, 22, 10, 9) + n * 0.08
	if im < 1.2 then
		local ih = if im < 0.72
			then 7.4 + n2 * 0.35
			else terrace3(lerp(7.4, -8, smoothstep(0.72, 1.2, im)))
		h = math.max(h, ih)
	end

	-- Rocky hill behind the Workshop (pushed cleanly behind the blue roof so it frames without clipping).
	local hm = ell(x, z, -6, -73, 29, 16) + n * 0.08
	if hm < 1 then
		local hh = 13 + 26 * (1 - hm * hm) ^ 0.75
		h = math.max(h, terrace3(hh))
	end
	-- Rock shoulders beside the Workshop terrace.
	local s1 = ell(x, z, -36, -44, 10, 9)
	if s1 < 1 then
		h = math.max(h, terrace3(12 + 8 * (1 - s1 * s1)))
	end
	local s2 = ell(x, z, 24, -40, 10, 10)
	if s2 < 1 then
		h = math.max(h, terrace3(11 + 8 * (1 - s2 * s2)))
	end

	-- Sanctuary plateau: tall, spacious round stone mesa with layered cliffs.
	local plateauTop = SANCT_Y - TERRAIN_MARGIN
	local pm = ell(x, z, SANCT_CX, SANCT_CZ, SANCT_R + 3.8, SANCT_R + 3.8) + n * 0.04
	if pm < 1.25 then
		local ph = if pm < 0.86
			then plateauTop
			else terrace3(lerp(plateauTop, 2, smoothstep(0.86, 1.25, pm)))
		h = math.max(h, ph)
	end
	-- Grass ledge west of the plateau for the giant pink blossom tree.
	local tm = ell(x, z, -96, -15, 11, 10)
	if tm < 1.3 then
		local th = if tm < 0.8
			then plateauTop - 0.5
			else terrace3(lerp(plateauTop - 0.5, 4, smoothstep(0.8, 1.3, tm)))
		h = math.max(h, th)
	end
	-- Waterfall cliff on the southwest lagoon rim, cleanly BEHIND the waterfall lip (never blocking the cascade or Apprentice portal!).
	local wm = ell(x, z, -64.5, 11.5, 7.5, 7.5)
	if wm < 1.3 then
		local wh = if wm < 0.8
			then plateauTop - 0.6
			else terrace3(lerp(plateauTop - 0.6, 5, smoothstep(0.8, 1.3, wm)))
		h = math.max(h, wh)
	end

	-- Lagoon basin: wide turquoise water (floor ~Y 2.4, water surface Y 8) framing Apprentice bridge, portal & waterfall.
	local lr = dist2(x, z, LAGOON_CX, LAGOON_CZ)
	if lr < 16.5 then
		h = 2.4 + n2 * 0.4
	elseif lr < 18.8 then
		h = math.min(h, lerp(2.6, 8.0, (lr - 16.5) / 2.3))
	elseif lr < 22.0 then
		h = math.max(h, 8.4 + n2 * 0.3)
	end

	-- Under-floor clearances (everything well below the floor so smooth terrain never pokes through).
	if inRect(x, z, -28, 16, -53, -21) then
		h = TERRACE_Y - TERRAIN_MARGIN
	end
	if inRect(x, z, -32, 20, -24, 26) then
		h = math.min(h, PLAZA_Y - TERRAIN_MARGIN)
	end
	if inRect(x, z, -62, -30, -31, -13) then
		h = math.min(h, stairTopAt(x) - 5.4)
	end
	-- Front stairs trench + wide gentle coastal taper (prevents Roblox distant SmoothTerrain LOD from bridging across the stairs!).
	if inRect(x, z, -23, 11, 27, 64) then
		local stairDrop = clamp((z - 25) / 10, 0, 1)
		h = math.min(h, lerp(PLAZA_Y - 5.5, -4.6, stairDrop))
	end
	if inRect(x, z, -19, 7, 24, 64) then
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
	if inRect(x, z, 9, 21, 22, 34) then
		h = math.min(h, PLAZA_Y - TERRAIN_MARGIN - 1)
	end
	if x > 9 and z > 30 then
		h = math.min(h, lerp(-4.6, -9, clamp((x - 10) / 25, 0, 1)))
	end
	-- Aquarium deck, wide west promenade (X -45..-29, Z 13..38), and Luna-Aquarium stairs over cove water.
	if inRect(x, z, -58, -16, 33, 62) then
		h = math.min(h, 1.8)
	end
	if inRect(x, z, -46, -29, 13, 38) then
		h = math.min(h, PLAZA_Y - TERRAIN_MARGIN - 0.5)
	end
	-- Lagoon arrival plaza, bridge and portal deck.
	if inRect(x, z, -58, -29, -12, 6) and lr >= 18.8 then
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

-- Which columns get sand on top (lagoon floor, front stairs shallow reef, tiny warm coves).
local function sandAt(x: number, z: number, h: number): boolean
	if dist2(x, z, LAGOON_CX, LAGOON_CZ) < 18.4 and h < 8 then
		return true
	end
	if inRect(x, z, -18, 6, 24, 62) or ell(x, z, -6, 62, 22, 11) < 1.0 then
		return true
	end
	return h < 1.8 and h > -5 and beachWeight(x, z) > 0.35
end

-- Grass only in patches on flat ground (rest is layered rock).
local function grassAt(x: number, z: number): boolean
	return noise2(x, z, 0.06, 7) > -0.18
end

local function waterLevelAt(x: number, z: number): number
	if dist2(x, z, LAGOON_CX, LAGOON_CZ) < 18.8 then
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
						elseif h > 2.6 and s <= 0.7 and grassAt(rx, rz) then
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

	-- Low coastal rock framing outside the front stairs (kept far enough out to never bridge across the stairs).
	for _, x in { -21.5, 9.2 } do
		local maxI = if x < 0 then 4 else 5
		for i = 1, maxI do
			local z = 27 + i * 4.5
			local y = PLAZA_Y - 6.8 - i * 1.4
			rockBall(terrain, x + rnd(-0.4, 0.4), y, z, rnd(2.6, 3.3))
		end
	end
	-- Submerged reef boulders (turquoise shallows).
	for i = 1, 16 do
		local side = if i % 2 == 0 then 1 else -1
		local x = -6 + side * rnd(13, 23)
		local z = rnd(52, 72)
		rockBall(
			terrain,
			x,
			rnd(-7.5, -6.5),
			z,
			rnd(1.6, 2.6),
			if i % 3 == 0 then Enum.Material.Basalt else Enum.Material.Rock
		)
	end

	-- Rock ledge cleanly BEHIND the waterfall lip on the southwest lagoon rim (zero overhang blocking water ribbons!).
	terrain:FillBlock(
		CFrame.lookAt(V(-60.6, 12.2, 10.6), V(-48, 12.2, 1)),
		Vector3.new(9.0, 12.5, 4.5),
		Enum.Material.Rock
	)
	terrain:FillBlock(
		CFrame.lookAt(V(-63.2, 13.4, 12.0), V(-48, 13.4, 1)),
		Vector3.new(10.0, 13.5, 4.5),
		Enum.Material.Basalt
	)
	terrain:FillBall(V(-61.8, 18.8, 11.2), 4.0, Enum.Material.Grass)
	-- Solidify rock base strictly BELOW the Sanctuary plateau (<= Y 15.5) so the rune circle at Y 20.3 stays 100% crisp and clear!
	terrain:FillCylinder(C(SANCT_CX, 7.0, SANCT_CZ), 14.0, SANCT_R - 0.5, Enum.Material.Rock)

	-- Safety carves: never solid terrain inside the Workshop house/roof, above the plaza, on Sanctuary stairs, or on Front stairs.
	terrain:FillBlock(C(-6, 29, -39), Vector3.new(38, 30, 30), Enum.Material.Air)
	terrain:FillBlock(C(-6, 16, 1), Vector3.new(48, 8, 46), Enum.Material.Air)
	terrain:FillBlock(
		C(SANCT_CX, 24, SANCT_CZ),
		Vector3.new(SANCT_R * 2 + 2, 8, SANCT_R * 2 + 2),
		Enum.Material.Air
	)
	-- Stepped Air carve along the Sanctuary stairs & landing so grass/rock never clips onto steps or gate entry.
	for i = 0, 14 do
		local sx = -28 - i * 2.1
		local sy = if sx > -34 then PLAZA_Y else stairTopAt(sx)
		terrain:FillBlock(C(sx, sy + 5.0, -22), Vector3.new(4.2, 11.0, 15.0), Enum.Material.Air)
	end
	-- Air carve along the Front stairs trench (above sea level).
	terrain:FillBlock(C(-6, 7.5, 39), Vector3.new(18, 14, 28), Enum.Material.Air)
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
	-- Moderate daylight range/brightness so lanterns glow warmly at night without blowing out stone by day.
	l.Range = math.clamp(range * 0.82, 7, 16)
	l.Brightness = math.clamp(brightness * 0.68, 0.35, 1.15)
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
		local flag = makeWedge(
			parent,
			name .. "Flag",
			cf,
			Vector3.new(0.06, 1.1, 0.9),
			FLAG_COLORS[(i - 1) % #FLAG_COLORS + 1],
			Enum.Material.Fabric,
			false
		)
		if i % 3 == 1 then
			tagWave(flag, 0.14, 2.5, i * 0.6)
		end
	end
end

-- Sign board with SurfaceGui text (front face = -Z of cf).
-- Rule: Front/Back text faces stay 100% clear; trim frames sit strictly outside the text area.
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
		Vector3.new(w, h, 0.42),
		bg or PALETTE.signBg,
		Enum.Material.SmoothPlastic,
		false
	)
	local fc = frameColor or PALETTE.woodDark
	local t = math.clamp(h * 0.12, 0.28, 0.48)
	makePart(
		parent,
		name .. "Trim",
		cf * CFrame.new(0, h / 2 + t / 2 - 0.04, 0),
		Vector3.new(w + t * 2, t, 0.56),
		fc,
		Enum.Material.Wood,
		false
	)
	makePart(
		parent,
		name .. "Trim",
		cf * CFrame.new(0, -h / 2 - t / 2 + 0.04, 0),
		Vector3.new(w + t * 2, t, 0.56),
		fc,
		Enum.Material.Wood,
		false
	)
	makePart(
		parent,
		name .. "Trim",
		cf * CFrame.new(w / 2 + t / 2 - 0.04, 0, 0),
		Vector3.new(t, h, 0.56),
		fc,
		Enum.Material.Wood,
		false
	)
	makePart(
		parent,
		name .. "Trim",
		cf * CFrame.new(-w / 2 - t / 2 + 0.04, 0, 0),
		Vector3.new(t, h, 0.56),
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
		gui.PixelsPerStud = 48
		gui.LightInfluence = 0.12
		gui.AlwaysOnTop = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		local titleLabel = Instance.new("TextLabel")
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.FredokaOne
		titleLabel.TextScaled = true
		titleLabel.Text = title
		titleLabel.TextColor3 = fg or PALETTE.signText
		titleLabel.TextStrokeTransparency = 0.35
		titleLabel.TextStrokeColor3 = Color3.fromRGB(16, 14, 28)
		if subtitle then
			titleLabel.Position = UDim2.fromScale(0.06, 0.07)
			titleLabel.Size = UDim2.fromScale(0.88, 0.54)
			local sub = Instance.new("TextLabel")
			sub.BackgroundTransparency = 1
			sub.Font = Enum.Font.FredokaOne
			sub.TextScaled = true
			sub.Text = subtitle
			sub.TextColor3 = subColor or PALETTE.gold
			sub.TextStrokeTransparency = 0.45
			sub.TextStrokeColor3 = Color3.fromRGB(16, 14, 28)
			sub.Position = UDim2.fromScale(0.08, 0.63)
			sub.Size = UDim2.fromScale(0.84, 0.30)
			sub.Parent = gui
		else
			titleLabel.Position = UDim2.fromScale(0.06, 0.12)
			titleLabel.Size = UDim2.fromScale(0.88, 0.76)
		end
		titleLabel.Parent = gui
		gui.Parent = board
	end
	return board
end

-- Standing sign mounted cleanly ON TOP of a wooden post (post ends below bottom trim: NEVER crosses text).
local function makeStandingSign(
	parent: Instance,
	name: string,
	base: Vector3,
	lookTarget: Vector3,
	w: number,
	h: number,
	title: string,
	subtitle: string?,
	postH: number?,
	bg: Color3?,
	fg: Color3?,
	subColor: Color3?,
	frameColor: Color3?,
	twoSided: boolean?
): Part
	local ph = postH or 5.2
	local trimT = math.clamp(h * 0.12, 0.28, 0.48)
	local boardCenterY = base.Y + ph + trimT + h / 2
	local boardPos = Vector3.new(base.X, boardCenterY, base.Z)
	local cf = faceTo(boardPos, Vector3.new(lookTarget.X, boardCenterY, lookTarget.Z))
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
		CFrame.new(base + Vector3.new(0, ph / 2, 0)),
		ph,
		0.56,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	-- Neat horizontal support saddle strictly below the sign frame.
	makePart(
		parent,
		name .. "Saddle",
		cf * CFrame.new(0, -h / 2 - trimT - 0.14, 0),
		Vector3.new(math.min(w * 0.55, 3.2), 0.28, 0.62),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	return makeSign(
		parent,
		name,
		cf,
		w,
		h,
		title,
		subtitle,
		bg,
		fg,
		subColor,
		frameColor,
		if twoSided == nil then true else twoSided
	)
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
		addLight(core, PALETTE.amber, 13 * s, 1.05)
		tagFlicker(core, 0.22)
	end
end

-- Wooden post lantern standing on the ground (tall ~7.4 studs so it rises well above the avatar).
local function makeLantern(
	parent: Instance,
	name: string,
	base: Vector3,
	height: number?,
	withLight: boolean?
)
	local h = math.max(height or 7.4, 6.2)
	makeCylinderY(
		parent,
		name .. "Foot",
		CFrame.new(base + Vector3.new(0, 0.25, 0)),
		0.9,
		1.5,
		PALETTE.stoneDark,
		Enum.Material.Slate,
		false
	)
	makeCylinderY(
		parent,
		name .. "Post",
		CFrame.new(base + Vector3.new(0, h / 2 - 0.15, 0)),
		h + 0.3,
		0.58,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	makeCylinderY(
		parent,
		name .. "RopeWrap",
		CFrame.new(base + Vector3.new(0, h * 0.72, 0)),
		0.45,
		0.72,
		PALETTE.rope,
		Enum.Material.Fabric,
		false
	)
	makeCylinderY(
		parent,
		name .. "CapSeat",
		CFrame.new(base + Vector3.new(0, h + 0.08, 0)),
		0.2,
		1.15,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeLanternBody(parent, name, base + Vector3.new(0, h + 0.92, 0), 1.22, withLight ~= false)
end

-- Sculpted stone pedestal lantern (taller ~5.8 studs, firmly seated 0.25 stud into floor).
local function makeStoneLantern(parent: Instance, name: string, base: Vector3, withLight: boolean?)
	makePart(
		parent,
		name .. "Base",
		CFrame.new(base + Vector3.new(0, 0.325, 0)),
		Vector3.new(2.2, 1.15, 2.2),
		PALETTE.stoneDark,
		Enum.Material.Slate,
		true
	)
	makePart(
		parent,
		name .. "BaseStep",
		CFrame.new(base + Vector3.new(0, 1.05, 0)),
		Vector3.new(1.7, 0.35, 1.7),
		PALETTE.stoneMid,
		Enum.Material.Slate,
		false
	)
	makePart(
		parent,
		name .. "Shaft",
		CFrame.new(base + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, math.rad(45), 0),
		Vector3.new(1.15, 2.6, 1.15),
		PALETTE.stone,
		Enum.Material.Slate,
		true
	)
	makePart(
		parent,
		name .. "Seat",
		CFrame.new(base + Vector3.new(0, 3.9, 0)),
		Vector3.new(2.0, 0.32, 2.0),
		PALETTE.stoneMid,
		Enum.Material.Slate,
		false
	)
	local glow = makePart(
		parent,
		name .. "Glow",
		CFrame.new(base + Vector3.new(0, 4.7, 0)),
		Vector3.new(1.25, 1.2, 1.25),
		PALETTE.amber,
		Enum.Material.Neon,
		false,
		0.05
	)
	for _, off in { { 0.66, 0.66 }, { -0.66, 0.66 }, { 0.66, -0.66 }, { -0.66, -0.66 } } do
		makePart(
			parent,
			name .. "Corner",
			CFrame.new(base + Vector3.new(off[1], 4.7, off[2])),
			Vector3.new(0.22, 1.35, 0.22),
			PALETTE.stoneDark,
			Enum.Material.Slate,
			false
		)
	end
	makePart(
		parent,
		name .. "Roof",
		CFrame.new(base + Vector3.new(0, 5.55, 0)) * CFrame.Angles(0, math.rad(45), 0),
		Vector3.new(2.2, 0.45, 2.2),
		PALETTE.stoneDark,
		Enum.Material.Slate,
		false
	)
	makePart(
		parent,
		name .. "Knob",
		CFrame.new(base + Vector3.new(0, 6.0, 0)),
		Vector3.new(0.65, 0.5, 0.65),
		PALETTE.stoneWarm,
		Enum.Material.Slate,
		false
	)
	if withLight ~= false then
		addLight(glow, PALETTE.amber, 12, 0.92)
		tagFlicker(glow, 0.18)
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
	-- Only large hero crystals emit PointLights (avoiding redundant lights on small crystals).
	if glow and height >= 4.4 then
		addLight(core, color, math.clamp(height * 2.1, 9, 20), 0.75)
		tagPulse(core, 0.18, 0.5, 1.8, "Transparency")
		if height >= 5.5 then
			addSparkles(core, color, 4, 0.36, 1.1, 1.5)
		end
	end
end

-- Cluster of 3-5 tall sculpted crystals around a ground point.
local function makeCrystalCluster(
	parent: Instance,
	name: string,
	base: Vector3,
	scale: number,
	color: Color3,
	glow: boolean?,
	altColor: Color3?
)
	local count = rndInt(4, 5)
	for i = 1, count do
		local main = i == 1
		local a = (i - 2) / math.max(1, count - 1) * math.pi * 2 + rnd(-0.25, 0.25)
		local off = if main
			then Vector3.zero
			else Vector3.new(math.cos(a), 0, math.sin(a)) * rnd(0.65, 1.25) * scale
		local tilt = if main then rnd(-4, 4) else rnd(16, 28)
		local yaw = math.deg(a) + 90
		local h = if main then scale * rnd(4.4, 5.4) else scale * rnd(2.2, 3.4)
		local r = if main then scale * 0.72 else scale * rnd(0.38, 0.52)
		local cf = CFrame.new(base + off - Vector3.new(0, 0.35 * scale, 0))
			* CFrame.Angles(0, math.rad(yaw), 0)
			* CFrame.Angles(math.rad(tilt), 0, 0)
		local col = if altColor and i % 2 == 0 then altColor else color
		makeCrystal(parent, name, cf, h, r, vary(col, 0.05), glow == true and main)
	end
	makeEllipsoid(
		parent,
		name .. "Rock",
		CFrame.new(base + Vector3.new(0, -0.1, 0)),
		Vector3.new(2.7, 0.9, 2.5) * scale,
		PALETTE.stoneBlue,
		Enum.Material.Slate
	)
end

-- Tall stylized palm tree: curved tapered ringed trunk, 11 plump arched fan fronds in 3 greens, coconuts & dry base skirt.
local function makePalm(
	parent: Instance,
	name: string,
	base: Vector3,
	height: number,
	leanDeg: number?
)
	local h = math.max(height, 17)
	local lean = math.rad(leanDeg or rnd(0, 360))
	local leanDir = Vector3.new(math.cos(lean), 0, math.sin(lean))
	local perpDir = Vector3.new(-leanDir.Z, 0, leanDir.X)
	local segs = 11
	local prev = base - Vector3.new(0, 1.0, 0)
	local top = prev
	-- Root mound & subtle ring of dry fallen palm leaves at the base.
	makeEllipsoid(
		parent,
		name .. "BaseMound",
		CFrame.new(base + Vector3.new(0, 0.25, 0)),
		Vector3.new(3.4, 1.1, 3.4),
		PALETTE.barkDark,
		Enum.Material.Wood
	)
	for k = 0, 5 do
		local da = k / 6 * math.pi * 2 + rnd(-0.2, 0.2)
		local dp = base + Vector3.new(math.cos(da) * 1.9, 0.16, math.sin(da) * 1.9)
		makeEllipsoid(
			parent,
			name .. "DryLeaf",
			CFrame.lookAt(dp, dp + Vector3.new(math.cos(da), -0.15, math.sin(da))),
			Vector3.new(0.85, 0.18, 2.4),
			Color3.fromRGB(168, 134, 78),
			Enum.Material.SmoothPlastic
		)
	end
	for i = 1, segs do
		local t = i / segs
		-- Graceful organic curve leaning outward and gently swooping upward near the crown.
		local curve = leanDir * (h * 0.28 * (t ^ 1.7)) + perpDir * (math.sin(t * math.pi) * 0.8)
		local p = base + Vector3.new(0, h * t, 0) + curve
		local d = lerp(2.35, 1.05, t ^ 0.85)
		makeTube(
			parent,
			name .. "Trunk",
			prev,
			p,
			d,
			if i % 2 == 0 then PALETTE.bark else PALETTE.barkDark,
			Enum.Material.Wood,
			i <= 5
		)
		local tangent = (p - prev).Unit
		makeCylinderY(
			parent,
			name .. "Ring",
			CFrame.lookAt(p, p + tangent) * CFrame.Angles(math.pi / 2, 0, 0),
			0.34,
			d + 0.34,
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
		CFrame.new(top + Vector3.new(0, 0.4, 0)),
		Vector3.new(2.8, 1.8, 2.8),
		PALETTE.leafDark,
		Enum.Material.SmoothPlastic
	)
	-- Two tiers of plump arched fronds: 8 outer long cascading fronds + 4 brighter inner uplifting fronds.
	local outerFronds = 8
	for i = 1, outerFronds do
		local a = (i - 1) / outerFronds * math.pi * 2 + rnd(-0.1, 0.1)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local len = h * rnd(0.46, 0.54)
		local lift = rnd(2.2, 3.2)
		local drop = rnd(4.6, 5.8)
		local prevP = top + Vector3.new(0, 0.5, 0)
		local n = 6
		for k = 1, n do
			local t = k / n
			local p = top
				+ Vector3.new(0, 0.5, 0)
				+ dir * (len * t)
				+ Vector3.new(0, lift * math.sin(t * math.pi * 0.72) - drop * (t ^ 2.1), 0)
			local width = lerp(3.0, 0.85, t) * (1 + 0.32 * math.sin(t * math.pi))
			local thick = lerp(0.85, 0.34, t)
			local seg = p - prevP
			local cf = CFrame.lookAt((prevP + p) / 2, p)
			local tone = if k <= 2
				then PALETTE.leafDark
				elseif k <= 4 then PALETTE.leaf
				else PALETTE.leafMid
			makeEllipsoid(
				parent,
				name .. "Frond",
				cf,
				Vector3.new(width, thick, seg.Magnitude + 1.15),
				vary(tone, 0.03),
				Enum.Material.SmoothPlastic
			)
			-- Plump side lobe puffs for stylized cartoon volume (never flat umbrella sheets).
			if k >= 2 and k <= 5 then
				for _, sd in { -1, 1 } do
					makeEllipsoid(
						parent,
						name .. "FrondLobe",
						cf
							* CFrame.new(sd * width * 0.28, -0.14, 0)
							* CFrame.Angles(0, 0, sd * math.rad(-18)),
						Vector3.new(width * 0.48, thick * 0.72, seg.Magnitude + 0.7),
						vary(if k <= 3 then PALETTE.leaf else PALETTE.leafLight, 0.03),
						Enum.Material.SmoothPlastic
					)
				end
			end
			prevP = p
		end
	end
	-- Brighter inner crown fronds rising higher.
	for i = 1, 4 do
		local a = (i - 0.5) / 4 * math.pi * 2 + 0.35
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local len = h * rnd(0.32, 0.38)
		local prevP = top + Vector3.new(0, 0.8, 0)
		for k = 1, 5 do
			local t = k / 5
			local p = top
				+ Vector3.new(0, 0.8, 0)
				+ dir * (len * t)
				+ Vector3.new(0, 3.6 * math.sin(t * math.pi * 0.78) - 2.4 * t * t, 0)
			local width = lerp(2.3, 0.7, t) * (1 + 0.25 * math.sin(t * math.pi))
			local seg = p - prevP
			local cf = CFrame.lookAt((prevP + p) / 2, p)
			local frond = makeEllipsoid(
				parent,
				name .. "InnerFrond",
				cf,
				Vector3.new(width, lerp(0.75, 0.3, t), seg.Magnitude + 0.9),
				vary(if k <= 2 then PALETTE.leafMid else PALETTE.leafLight, 0.03),
				Enum.Material.SmoothPlastic
			)
			if k == 4 then
				tagSway(frond, 6, 1.4 + i * 0.2)
			end
			prevP = p
		end
	end
	-- 5 plump coconuts nestled beneath the crown.
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2 + 0.25
		makeEllipsoid(
			parent,
			name .. "Coconut",
			CFrame.new(top + Vector3.new(math.cos(a) * 0.95, -0.75, math.sin(a) * 0.95))
				* CFrame.Angles(0, a, math.rad(14)),
			Vector3.new(1.05, 1.2, 1.05),
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
	for _ = 1, 3 do
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

-- Lush tropical planter in a sculpted clay pot (volumetric arched leaves + blooms, never flat blades).
local function makePlanter(parent: Instance, name: string, base: Vector3, color: Color3)
	makeCylinderY(
		parent,
		name .. "Foot",
		CFrame.new(base + Vector3.new(0, 0.2, 0)),
		0.4,
		2.5,
		Color3.fromRGB(168, 134, 96),
		Enum.Material.SmoothPlastic,
		true
	)
	makeCylinderY(
		parent,
		name .. "Pot",
		CFrame.new(base + Vector3.new(0, 1.05, 0)),
		1.7,
		2.9,
		Color3.fromRGB(204, 168, 122),
		Enum.Material.SmoothPlastic,
		true
	)
	makeCylinderY(
		parent,
		name .. "Band",
		CFrame.new(base + Vector3.new(0, 1.25, 0)),
		0.22,
		3.02,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false
	)
	makeCylinderY(
		parent,
		name .. "Rim",
		CFrame.new(base + Vector3.new(0, 1.98, 0)),
		0.36,
		3.35,
		Color3.fromRGB(186, 148, 102),
		Enum.Material.SmoothPlastic,
		false
	)
	makeCylinderY(
		parent,
		name .. "Soil",
		CFrame.new(base + Vector3.new(0, 1.94, 0)),
		0.14,
		2.7,
		PALETTE.barkDark,
		Enum.Material.Ground,
		false
	)
	-- Two rings of plump arched 2-segment leaves in 3 shades of green/teal.
	local leafTones = { PALETTE.leafDark, PALETTE.teal, PALETTE.leafMid, PALETTE.leafLight }
	for ring = 1, 2 do
		local count = if ring == 1 then 8 else 6
		local rLen = if ring == 1 then 2.3 else 1.55
		local lift = if ring == 1 then 1.3 else 2.2
		for i = 1, count do
			local a = (i + ring * 0.5) / count * math.pi * 2
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local p0 = base + Vector3.new(0, 2.0, 0) + dir * 0.25
			local p1 = p0 + dir * (rLen * 0.55) + Vector3.new(0, lift, 0)
			local p2 = p0 + dir * rLen + Vector3.new(0, lift * 0.45, 0)
			local tone = leafTones[(i + ring) % #leafTones + 1]
			makeEllipsoid(
				parent,
				name .. "Leaf",
				CFrame.lookAt((p0 + p1) / 2, p1),
				Vector3.new(0.68, 0.28, (p1 - p0).Magnitude + 0.3),
				vary(tone, 0.04),
				Enum.Material.SmoothPlastic
			)
			makeEllipsoid(
				parent,
				name .. "LeafTip",
				CFrame.lookAt((p1 + p2) / 2, p2),
				Vector3.new(0.46, 0.22, (p2 - p1).Magnitude + 0.25),
				vary(PALETTE.leafLight, 0.04),
				Enum.Material.SmoothPlastic
			)
		end
	end
	-- Decorative blossoms / crystal buds rising from the center.
	for k = 0, 2 do
		local a = k / 3 * math.pi * 2 + 0.4
		local pos = base + Vector3.new(math.cos(a) * 0.5, 3.0 + (k % 2) * 0.35, math.sin(a) * 0.5)
		makeEllipsoid(
			parent,
			name .. "Flower",
			CFrame.new(pos),
			Vector3.new(0.65, 0.5, 0.65),
			vary(color, 0.05),
			Enum.Material.SmoothPlastic
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

-- Life buoy (ring of segments) facing direction of cf's -Z, wrapped as centered Model for HubBob.
local function makeBuoy(parent: Instance, name: string, cf: CFrame, radius: number)
	local bm = makeModel(parent, name .. "Model")
	local pivot = makePart(
		bm,
		"Pivot",
		cf,
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.red,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	bm.PrimaryPart = pivot
	bm.WorldPivot = pivot.CFrame
	local segs = 10
	for i = 0, segs - 1 do
		local a = (i + 0.5) / segs * math.pi * 2
		local pcf = cf * CFrame.Angles(0, 0, a) * CFrame.new(radius, 0, 0)
		makePart(
			bm,
			name,
			pcf,
			Vector3.new(radius * 0.55, radius * 0.7, radius * 0.5),
			if i % 2 == 0 then PALETTE.red else PALETTE.white,
			Enum.Material.SmoothPlastic,
			false
		)
	end
	tagBob(bm, 0.14, 1.9, rnd(0, 6.28))
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
	local rh = railHeight or 3.5
	local posts = math.max(2, math.floor(len / 3.8) + 1)
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
				0.58,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			makeCylinderY(
				parent,
				name .. "Piling",
				CFrame.new(p - Vector3.new(0, 6.6, 0)),
				10.8,
				0.78,
				PALETTE.woodDark,
				Enum.Material.Wood,
				false
			)
			makeCylinderY(
				parent,
				name .. "PostCap",
				CFrame.new(top + Vector3.new(0, 0.12, 0)),
				0.24,
				0.72,
				PALETTE.wood,
				Enum.Material.Wood,
				false
			)
			makeCylinderY(
				parent,
				name .. "Knot",
				CFrame.new(top - Vector3.new(0, 0.45, 0)),
				0.4,
				0.74,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			local prev = prevTop[side]
			if prev then
				makeRope(
					parent,
					name .. "Rail",
					prev - Vector3.new(0, 0.45, 0),
					top - Vector3.new(0, 0.45, 0),
					0.5,
					0.26
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
					top + Vector3.new(0, 1.05, 0),
					0.9,
					side == 1
				)
			end
		end
	end
end

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
		cf * CFrame.new(0, 1.45, 0),
		Vector3.new(5.8, 0.4, 1.8),
		PALETTE.woodLight,
		Enum.Material.Wood,
		true
	)
	for _, z in { -0.48, 0.48 } do
		makePart(
			parent,
			name .. "Slat",
			cf * CFrame.new(0, 1.68, z),
			Vector3.new(5.86, 0.06, 0.68),
			PALETTE.woodWarm,
			Enum.Material.Wood,
			false
		)
	end
	makePart(
		parent,
		name .. "Back",
		cf * CFrame.new(0, 2.75, 0.88) * CFrame.Angles(math.rad(-12), 0, 0),
		Vector3.new(5.8, 1.45, 0.3),
		PALETTE.woodLight,
		Enum.Material.Wood,
		false
	)
	for _, x in { -2.45, 2.45 } do
		makePart(
			parent,
			name .. "Leg",
			cf * CFrame.new(x, 0.62, 0),
			Vector3.new(0.46, 1.62, 1.6),
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makePart(
			parent,
			name .. "BackLeg",
			cf * CFrame.new(x, 2.25, 0.85),
			Vector3.new(0.36, 1.95, 0.32),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makePart(
			parent,
			name .. "Arm",
			cf * CFrame.new(x, 2.15, 0.05),
			Vector3.new(0.34, 0.24, 1.65),
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
	local flameCore = makeEllipsoid(
		parent,
		name .. "FlameCore",
		CFrame.new(base + Vector3.new(0, 0.9, 0)),
		Vector3.new(0.9, 1.6, 0.9),
		PALETTE.flameCore,
		Enum.Material.Neon,
		0.05
	)
	tagFlicker(flame, 0.35)
	tagPulse(flameCore, 0.02, 0.28, 4.2, "Transparency")
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 8
	fire.Color = PALETTE.flame
	fire.SecondaryColor = PALETTE.flameCore
	fire.Parent = flame
	stats.emitters += 1
	addLight(flame, PALETTE.flame, 16, 1.35)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE_TEXTURE
	e.Color = ColorSequence.new(PALETTE.flameCore, PALETTE.flame)
	e.LightEmission = 1
	e.Rate = 12
	e.Lifetime = NumberRange.new(1.4, 2.4)
	e.Speed = NumberRange.new(2.2, 4.4)
	e.SpreadAngle = Vector2.new(24, 24)
	e.Acceleration = Vector3.new(0, 1.2, 0)
	e.Size = NumberSequence.new(0.28, 0)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = flame
	stats.emitters += 1
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = SPARKLE_TEXTURE
	smoke.Color = ColorSequence.new(Color3.fromRGB(190, 180, 195))
	smoke.LightEmission = 0
	smoke.Rate = 4
	smoke.Lifetime = NumberRange.new(2.2, 3.6)
	smoke.Speed = NumberRange.new(1.2, 2.2)
	smoke.SpreadAngle = Vector2.new(14, 14)
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1.8),
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.72),
		NumberSequenceKeypoint.new(1, 1),
	})
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = flame
	stats.emitters += 1
end

-- Symmetrical stone basin with water and a strictly vertical, centered main crystal (plaza centerpiece).
local function makeCrystalFountain(parent: Instance, name: string, base: Vector3)
	-- Outer stepped stone plinth firmly seated on the plaza floor.
	makeCylinderY(
		parent,
		name .. "PlinthStep",
		CFrame.new(base + Vector3.new(0, 0.2, 0)),
		0.4,
		9.6,
		PALETTE.stoneDark,
		Enum.Material.Slate,
		true
	)
	flatRing(
		parent,
		name .. "Basin",
		CFrame.new(base + Vector3.new(0, 0.72, 0)),
		4.15,
		1.15,
		1.05,
		24,
		PALETTE.stoneMid,
		Enum.Material.Slate,
		true
	)
	flatRing(
		parent,
		name .. "BasinCap",
		CFrame.new(base + Vector3.new(0, 1.32, 0)),
		4.15,
		1.35,
		0.16,
		24,
		PALETTE.stoneWarm,
		Enum.Material.Slate,
		false
	)
	makeCylinderY(
		parent,
		name .. "Water",
		CFrame.new(base + Vector3.new(0, 0.88, 0)),
		0.28,
		7.4,
		PALETTE.water,
		Enum.Material.Glass,
		false,
		0.24
	)
	-- Uniform cyan glow ring strictly inside the basin water (slowly rotating!).
	local glowRingModel = makeModel(parent, name .. "GlowRing")
	local grPivot = makePart(
		glowRingModel,
		"Pivot",
		CFrame.new(base + Vector3.new(0, 1.06, 0)),
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	glowRingModel.PrimaryPart = grPivot
	glowRingModel.WorldPivot = grPivot.CFrame
	makeNeonRing(
		glowRingModel,
		name .. "Glow",
		CFrame.new(base + Vector3.new(0, 1.06, 0)),
		3.15,
		0.22,
		24,
		PALETTE.cyan,
		0.32
	)
	tagSpin(glowRingModel, 12, "Y", 0)
	-- Centered multi-tier stone pedestal supporting the crystals.
	makeCylinderY(
		parent,
		name .. "PedestalFoot",
		CFrame.new(base + Vector3.new(0, 1.0, 0)),
		1.2,
		3.8,
		PALETTE.stoneMid,
		Enum.Material.Slate,
		true
	)
	makeCylinderY(
		parent,
		name .. "Pedestal",
		CFrame.new(base + Vector3.new(0, 1.9, 0)),
		1.5,
		3.0,
		PALETTE.stone,
		Enum.Material.Slate,
		true
	)
	makeCylinderY(
		parent,
		name .. "PedestalTop",
		CFrame.new(base + Vector3.new(0, 2.75, 0)),
		0.22,
		3.4,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false
	)
	-- Strictly vertical main crystal dead-center on the pedestal (slow mystical rotation!).
	local crownBase = base + Vector3.new(0, 2.75, 0)
	local crystalSpinModel = makeModel(parent, name .. "MainCrystalSpin")
	local csPivot = makePart(
		crystalSpinModel,
		"Pivot",
		CFrame.new(crownBase + Vector3.new(0, 3.6, 0)),
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.crystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	crystalSpinModel.PrimaryPart = csPivot
	crystalSpinModel.WorldPivot = csPivot.CFrame
	makeCrystal(
		crystalSpinModel,
		name .. "MainCrystal",
		CFrame.new(crownBase),
		7.2,
		1.08,
		PALETTE.crystalCyan,
		true
	)
	tagSpin(crystalSpinModel, 10, "Y", 0)
	-- 4 symmetrical companion crystals evenly spaced at 90 degrees, seated cleanly inside the pedestal crown.
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local sideBase = crownBase + dir * 0.92 - Vector3.new(0, 0.08, 0)
		local sideCf = CFrame.lookAt(sideBase, sideBase + dir) * CFrame.Angles(math.rad(-18), 0, 0)
		local col = if i % 2 == 0 then PALETTE.crystalLilac else PALETTE.crystalPink
		makeCrystal(parent, name .. "SideCrystal", sideCf, 3.4, 0.56, col, false)
	end
	local sparkle = makePart(
		parent,
		name .. "Sparkles",
		CFrame.new(base + Vector3.new(0, 6.2, 0)),
		Vector3.new(3.5, 4.5, 3.5),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	addSparkles(sparkle, PALETTE.crystalCyan, 6, 0.5, 1.2)
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
	-- Arrow tip at the pointing end (strictly outside the text board).
	local trimT = math.clamp(h * 0.12, 0.28, 0.48)
	local tip = center + d * (w / 2 + trimT + 0.55)
	local tcf = CFrame.lookAt(tip, tip + d)
	makeWedge(
		parent,
		name .. "Tip",
		tcf * CFrame.new(0, h / 4, 0) * CFrame.Angles(0, 0, math.pi),
		Vector3.new(0.44, h / 2 + trimT * 0.5, 1.35),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeWedge(
		parent,
		name .. "Tip",
		tcf * CFrame.new(0, -h / 4, 0),
		Vector3.new(0.44, h / 2 + trimT * 0.5, 1.35),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
end

-- Clean single-destination standing arrow sign: post terminates strictly UNDER the bottom frame (never crosses text).
local function makeStandingArrowSign(
	parent: Instance,
	name: string,
	base: Vector3,
	dir: Vector3,
	w: number,
	h: number,
	text: string,
	sub: string?,
	postH: number?
)
	local ph = postH or 5.4
	local trimT = math.clamp(h * 0.12, 0.28, 0.48)
	local centerY = base.Y + ph + trimT + h / 2
	makeCylinderY(
		parent,
		name .. "Foot",
		CFrame.new(base + Vector3.new(0, 0.25, 0)),
		0.5,
		1.25,
		PALETTE.stoneDark,
		Enum.Material.Slate,
		false
	)
	makeCylinderY(
		parent,
		name .. "Post",
		CFrame.new(base + Vector3.new(0, ph / 2, 0)),
		ph,
		0.58,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	local d = Vector3.new(dir.X, 0, dir.Z).Unit
	local side = Vector3.new(-d.Z, 0, d.X)
	local cf = CFrame.lookAt(
		Vector3.new(base.X, centerY, base.Z),
		Vector3.new(base.X, centerY, base.Z) + side
	)
	makePart(
		parent,
		name .. "Saddle",
		cf * CFrame.new(0, -h / 2 - trimT - 0.14, 0),
		Vector3.new(math.min(w * 0.55, 3.4), 0.28, 0.64),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeArrowSign(parent, name, Vector3.new(base.X, centerY, base.Z), d, w, h, text, sub)
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
	makeCrystalFountain(m, "CentralCrystal", V(-6, Y, 1))
	task.wait()

	-- Campfire rest deck (around the contract fire at (-16, 10.3, 11)).
	local deckTop = Y + 0.3
	makePlankDeck(m, "RestDeck", C(-17, deckTop, 11), 11.6, 11.6, 0.6, PALETTE.woodWarm)
	for _, e in { { -17, 5.1, 11.8, 0.3 }, { -17, 16.9, 11.8, 0.3 } } do
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
		C(-22.9, deckTop - 0.25, 11),
		Vector3.new(0.3, 0.5, 11.8),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makePart(
		m,
		"RestDeckEdge",
		C(-11.1, deckTop - 0.25, 11),
		Vector3.new(0.3, 0.5, 11.8),
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeCampfire(m, "Campfire", V(FIRE_POS.X, deckTop, FIRE_POS.Z))
	for i, a in { 45, 135, 225, 315 } do
		local r = math.rad(a)
		makeStump(
			m,
			"Stump" .. i,
			V(FIRE_POS.X + math.cos(r) * 3.8, deckTop, FIRE_POS.Z + math.sin(r) * 3.8),
			1.25
		)
	end
	makeBench(m, "RestBench", CY(-17, deckTop, 15.6, 0))
	-- Taller rope fence on south and west edges (3.2 studs high).
	local fence = {
		V(-11.6, deckTop, 16.4),
		V(-15.4, deckTop, 16.4),
		V(-19.2, deckTop, 16.4),
		V(-22.4, deckTop, 16.4),
		V(-22.4, deckTop, 12.6),
		V(-22.4, deckTop, 8.8),
		V(-22.4, deckTop, 5.6),
	}
	for i, p in fence do
		makeCylinderY(
			m,
			"FencePost",
			CFrame.new(p + Vector3.new(0, 1.6, 0)),
			3.2,
			0.52,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeCylinderY(
			m,
			"FenceKnot",
			CFrame.new(p + Vector3.new(0, 2.55, 0)),
			0.36,
			0.68,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
		if i > 1 then
			makeRope(
				m,
				"FenceRope",
				fence[i - 1] + Vector3.new(0, 2.55, 0),
				p + Vector3.new(0, 2.55, 0),
				0.4,
				0.24
			)
		end
	end
	-- Tall gallows lantern post (~10.5 studs) with hanging lantern and high bunting across the deck.
	do
		local post = V(-22.4, deckTop, 16.4)
		makeCylinderY(
			m,
			"LampPost",
			CFrame.new(post + Vector3.new(0, 5.2, 0)),
			10.4,
			0.72,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeSegment(
			m,
			"LampArm",
			post + Vector3.new(0, 9.8, 0),
			post + Vector3.new(2.8, 9.8, -2.8),
			0.48,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeSegment(
			m,
			"LampBrace",
			post + Vector3.new(0, 8.0, 0),
			post + Vector3.new(1.7, 9.8, -1.7),
			0.34,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeTube(
			m,
			"LampWrap",
			post + Vector3.new(0, 6.2, 0),
			post + Vector3.new(0, 7.2, 0),
			0.88,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
		makeTube(
			m,
			"LampChain",
			post + Vector3.new(2.6, 9.7, -2.6),
			post + Vector3.new(2.6, 8.5, -2.6),
			0.12,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeLanternBody(m, "RestLantern", post + Vector3.new(2.6, 7.6, -2.6), 1.15, true)
		local post2 = V(-11.6, deckTop, 16.4)
		makeCylinderY(
			m,
			"BuntingPole",
			CFrame.new(post2 + Vector3.new(0, 4.9, 0)),
			9.8,
			0.54,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeBunting(
			m,
			"RestBunting",
			post + Vector3.new(0, 9.5, 0),
			post2 + Vector3.new(0, 9.3, 0),
			0.9
		)
		makeLantern(m, "RestDeckLantern", V(-11.8, deckTop, 5.8), 6.6, true)
		makePlanter(m, "RestPlanter", V(-20.4, deckTop, 6.8), PALETTE.crystalPink)
	end
	task.wait()

	-- Rune path from the center-west plaza cleanly up to the Training Sanctuary landing (clear of Apprentice arrival plaza!).
	local path = {
		Vector3.new(-19.5, 0, -5.0),
		Vector3.new(-24.8, 0, -13.5),
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
			Vector3.new(3.6, 0.08, len + 2.8),
			PALETTE.slateInlay,
			Enum.Material.Slate,
			false
		)
		for _, sx in { -1.65, 1.65 } do
			-- Subtle translucent rune edge (Transparency >= 0.45, width 0.28) so Neon never over-saturates!
			local edge = makePart(
				m,
				"RunePathEdge",
				cf * CFrame.new(sx, 0.05, 0),
				Vector3.new(0.28, 0.04, len + 2.2),
				PALETTE.cyan,
				Enum.Material.Neon,
				false,
				0.52
			)
			tagPulse(edge, 0.42, 0.68, 1.6, "Transparency")
		end
		local count = math.floor(len / 2.6)
		for k = 0, count - 1 do
			local t = (k + 0.5) / count
			makeRune(
				m,
				"RuneGlyph",
				CFrame.lookAt(a:Lerp(b, t) + Vector3.new(0, 0.05, 0), b),
				0.95,
				PALETTE.cyan
			)
		end
	end

	-- Clean single-destination standing arrow signs well spaced (>= 6 studs before each portico, widely separated from each other!).
	makeStandingArrowSign(
		m,
		"PierArrow",
		V(12.2, Y, -0.4),
		Vector3.new(1, 0, 0),
		6.8,
		1.9,
		"PÍER DE PESCA",
		nil,
		5.4
	)
	makeStandingArrowSign(
		m,
		"WharfArrow",
		V(9.2, Y, 20.6),
		Vector3.new(0, 0, 1),
		7.4,
		1.9,
		"CAIS DAS EXPEDIÇÕES",
		nil,
		5.4
	)
	makeStandingArrowSign(
		m,
		"AquariumArrow",
		V(-28.4, Y, 12.6),
		Vector3.new(-1, 0, 0),
		6.6,
		1.9,
		"AQUÁRIO",
		nil,
		5.4
	)

	-- Evenly spaced perimeter lanterns (>= 4 studs apart, zero crowding at Aquarium promenade, Apprentice plaza, or Wharf/Pier entries!).
	for _, p in
		{
			{ -17.2, 22.8 },
			{ 4.6, 22.8 },
			{ 16.8, -2.5 },
			{ 16.8, -12.8 },
			{ 16.2, -20.8 },
			{ -17.4, -14.6 },
			{ 5.4, -14.6 },
		}
	do
		makeLantern(m, "PlazaLantern", V(p[1], Y, p[2]), 7.6, true)
	end
	-- High bunting strung cleanly at ~10.2 studs (well above avatar head height, never crossing signs!).
	local bh = Y + 9.8
	makeBunting(m, "WorkshopBunting", V(-17.4, bh, -14.6), V(5.4, bh, -14.6), 1.3)
	makeBunting(m, "PlazaBuntingE", V(16.8, bh, -2.5), V(16.8, bh, -12.8), 0.9)
	-- Soft festive petals / sparkles drifting near the Workshop stairs.
	local plazaSpark = makePart(
		m,
		"PlazaWorkshopPetals",
		C(-6, Y + 5.5, -14),
		Vector3.new(20, 3, 8),
		PALETTE.pinkLight,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	addSparkles(plazaSpark, PALETTE.pinkLight, 5, 0.34, 0.8, 2.6)
	for _, p in
		{
			{ 15.0, -18.2 },
			{ 11.4, -19.2 },
			{ -12.2, 22.2 },
			{ 8.2, -19.2 },
		}
	do
		makePlanter(
			m,
			"PlazaPlanter",
			V(p[1], Y, p[2]),
			if p[1] > 0 then PALETTE.crystalCyan else PALETTE.crystalPink
		)
	end
	-- Second cozy rest deck near the Training Sanctuary gate, shifted 2 studs east for a wide unobstructed gate corridor!
	do
		local dt = Y + 0.3
		makePlankDeck(m, "GateRestDeck", C(-20.8, dt, -18.6), 6.4, 5.8, 0.6, PALETTE.woodWarm)
		local bowl = V(-20.8, dt, -18.2)
		makeCylinderY(
			m,
			"BrazierBase",
			CFrame.new(bowl + Vector3.new(0, 0.5, 0)),
			1.0,
			1.5,
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		makeCylinderY(
			m,
			"BrazierBowl",
			CFrame.new(bowl + Vector3.new(0, 1.15, 0)),
			0.45,
			2.4,
			PALETTE.stoneDark,
			Enum.Material.Slate,
			false
		)
		local f = makeEllipsoid(
			m,
			"BrazierFlame",
			CFrame.new(bowl + Vector3.new(0, 1.85, 0)),
			Vector3.new(1.25, 1.75, 1.25),
			PALETTE.flame,
			Enum.Material.Neon,
			0.2
		)
		makeEllipsoid(
			m,
			"BrazierCore",
			CFrame.new(bowl + Vector3.new(0, 1.7, 0)),
			Vector3.new(0.65, 1.1, 0.65),
			PALETTE.flameCore,
			Enum.Material.Neon,
			0.05
		)
		addLight(f, PALETTE.flame, 13, 1.1)
		tagFlicker(f, 0.28)
		local fire = Instance.new("Fire")
		fire.Size = 2.6
		fire.Heat = 6
		fire.Color = PALETTE.flame
		fire.SecondaryColor = PALETTE.flameCore
		fire.Parent = f
		stats.emitters += 1
		makeStump(m, "GateStump", V(-22.8, dt, -16.8), 1.2)
		makeStump(m, "GateStump", V(-18.8, dt, -16.8), 1.2)
		makeBench(m, "GateBench", CY(-20.8, dt, -20.5, 180))
		local post = V(-23.8, dt, -15.9)
		makeCylinderY(
			m,
			"GateLampPost",
			CFrame.new(post + Vector3.new(0, 4.9, 0)),
			9.8,
			0.66,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeSegment(
			m,
			"GateLampArm",
			post + Vector3.new(0, 9.2, 0),
			post + Vector3.new(2.4, 9.2, 0),
			0.42,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeTube(
			m,
			"GateLampWrap",
			post + Vector3.new(0, 6.0, 0),
			post + Vector3.new(0, 7.0, 0),
			0.82,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
		makeLanternBody(m, "GateRestLantern", post + Vector3.new(2.2, 8.0, 0), 1.05, true)
		makeBunting(
			m,
			"GateRestBunting",
			post + Vector3.new(0, 9.0, 0),
			V(-32.2, Y + 9.6, -15.4),
			0.8
		)
		for _, p in { V(-23.8, dt, -21.2), V(-17.8, dt, -21.2) } do
			makeCylinderY(
				m,
				"GateDeckPost",
				CFrame.new(p + Vector3.new(0, 1.5, 0)),
				3.0,
				0.48,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
		end
		makeRope(
			m,
			"GateDeckRope",
			V(-23.8, dt + 2.4, -15.9),
			V(-23.8, dt + 2.4, -21.2),
			0.35,
			0.24
		)
		makeRope(
			m,
			"GateDeckRope",
			V(-23.8, dt + 2.4, -21.2),
			V(-17.8, dt + 2.4, -21.2),
			0.35,
			0.24
		)
	end
	makeBunting(m, "PlazaBuntingNE", V(16.8, bh, -12.8), V(16.2, bh, -20.8), 0.7)
	makeBunting(m, "PlazaBuntingN", V(5.4, bh, -14.6), V(16.2, bh, -20.8), 0.8)

	-- Radially aligned symmetrical benches facing the exact center of the plaza (-6, Y, 1).
	local plazaCenter = V(-6, Y, 1)
	for i, angDeg in { -42, 42, -138 } do
		local a = math.rad(angDeg)
		local bp = V(-6 + math.cos(a) * 12.8, Y, 1 + math.sin(a) * 12.8)
		makeBench(m, "PlazaBench" .. i, faceTo(bp, plazaCenter))
	end
	-- Cozy lookout bench near Vô Anzol's spot (14, 10.3, 2), leaving a 4x4 clearing around him.
	makeBench(m, "GuideBench", CY(11.6, Y, -5.2, -90))
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
	-- Mount WorkshopSign 1.3 studs in front of the roof eave (-30.8 -> -29.5) with clean rear brackets so Roof NEVER blocks text!
	for _, bx in { -10.5, -1.5 } do
		makePart(
			m,
			"WorkshopSignBracket",
			C(bx, eaveY + 2.3, -30.5),
			Vector3.new(0.45, 0.45, 1.8),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	makeSign(
		m,
		"WorkshopSign",
		faceTo(V(-6, eaveY + 2.3, -29.5), V(-6, eaveY + 2.3, 0)),
		15.2,
		4.3,
		"OFICINA DE VARAS",
		nil,
		PALETTE.signBg,
		PALETTE.signText,
		nil,
		PALETTE.gold,
		false
	)
	local halo = Instance.new("Model")
	halo.Name = "Halo"
	halo.Parent = m
	local haloPivot = makePart(
		halo,
		"HaloPivot",
		C(-6, ridgeY + 3.4, -32),
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	halo.PrimaryPart = haloPivot
	halo.WorldPivot = haloPivot.CFrame
	makeNeonRing(halo, "HaloRing", C(-6, ridgeY + 3.4, -32), 2.5, 0.38, 22, PALETTE.gold, 0.05)
	tagSpin(halo, 24, "Y", 0)
	tagBob(halo, 0.22, 1.8, 0.2)
	makeTube(
		m,
		"HaloRod",
		V(-6, ridgeY + 1.2, -32),
		V(-6, ridgeY + 3.2, -32),
		0.22,
		PALETTE.gold,
		Enum.Material.Metal,
		false
	)
	-- Chunky crystal diamond shield emblems on the front columns (ref-1/ref-2).
	for _, x in { -20, 8 } do
		local p = V(x, T + 6.8, -32.9)
		local cf = faceTo(p, p + Vector3.new(0, 0, 1))
		makePart(
			m,
			"Shield",
			cf,
			Vector3.new(2.6, 3.1, 0.36),
			PALETTE.roofBlueLight,
			Enum.Material.SmoothPlastic,
			false
		)
		makePart(
			m,
			"ShieldRim",
			cf * CFrame.new(0, 0, 0.08),
			Vector3.new(2.95, 3.45, 0.24),
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false
		)
		makePart(
			m,
			"ShieldGem",
			cf * CFrame.new(0, 0.1, -0.28) * CFrame.Angles(0, 0, math.rad(45)),
			Vector3.new(1.45, 1.45, 0.38),
			PALETTE.crystalCyan,
			Enum.Material.Glass,
			false,
			0.1
		)
		makePart(
			m,
			"ShieldGemCore",
			cf * CFrame.new(0, 0.1, -0.4) * CFrame.Angles(0, 0, math.rad(45)),
			Vector3.new(0.7, 0.7, 0.14),
			PALETTE.cyan,
			Enum.Material.Neon,
			false,
			0.25
		)
	end
	makeBunting(m, "WorkshopFrontBunting", V(-20, T + 8.8, -33.6), V(-6, T + 8.2, -33.6), 0.55)
	makeBunting(m, "WorkshopFrontBunting", V(-6, T + 8.2, -33.6), V(8, T + 8.8, -33.6), 0.55)

	-- Terrace props (SpotPedestal seated -0.2 stud into Terrace for solid support!).
	makeStoneLantern(m, "TerraceLantern", V(-24.6, T, -23.6), true)
	makeStoneLantern(m, "TerraceLantern", V(12.6, T, -23.6), true)
	makePart(
		m,
		"SpotPedestal",
		C(-6, T + 0.45, -27.5),
		Vector3.new(2.2, 1.3, 2.2),
		PALETTE.stone,
		Enum.Material.Slate,
		true
	)
	makeCrystal(m, "SpotCrystalMain", C(-6, T + 1.1, -27.5), 2.8, 0.52, PALETTE.crystalCyan, false)
	local spotRing = makeModel(m, "SpotRingModel")
	local srPivot = makePart(
		spotRing,
		"Pivot",
		C(-6, T + 0.08, -27.5),
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	spotRing.PrimaryPart = srPivot
	spotRing.WorldPivot = srPivot.CFrame
	makeNeonRing(spotRing, "SpotRing", C(-6, T + 0.08, -27.5), 2.4, 0.2, 18, PALETTE.cyan, 0.3)
	tagSpin(spotRing, 18, "Y", 0)
	makePlanter(m, "ShopPlanter", V(-22.0, T, -31.5), PALETTE.crystalPink)
	makePlanter(m, "ShopPlanter", V(10.0, T, -31.5), PALETTE.crystalCyan)
	makeBarrel(m, "TerraceBarrel", V(-23.8, T, -28.0), 2.0)
	makeCrate(m, "TerraceCrate", CY(11.5, T + 0.65, -28.0, 0), 1.3)
	makeCrate(m, "TerraceCrate", CY(11.5, T + 1.85, -28.1, 12), 1.1)
	-- Tall lush palms flanking both sides of the Workshop (ref-2/ref-4).
	makePalm(m, "TerracePalm", V(-24.8, T, -45.5), 21.5, 205)
	makePalm(m, "TerracePalm", V(12.8, T, -45.5), 21.5, -25)
	makeCrystalCluster(m, "TerraceCrystal", V(-24.4, T, -38), 1.25, PALETTE.crystalLilac, true)
	makeCrystalCluster(m, "TerraceCrystal", V(12.6, T, -38.5), 1.25, PALETTE.crystalCyan, true)
	-- Dramatic big crystal tufts on the rocks behind the Workshop.
	for _, c in
		{
			{ -30, -52, PALETTE.crystalCyan },
			{ 18.5, -52, PALETTE.crystalLilac },
			{ -15, -58, PALETTE.crystalPink },
			{ 4, -59, PALETTE.crystalCyan },
		}
	do
		local x, z = c[1] :: number, c[2] :: number
		makeCrystalCluster(
			m,
			"BackCrystal",
			V(x, groundY(x, z), z),
			rnd(2.6, 3.4),
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

	-- Luna's Seaside Cove Landing (NPC Luna stands at (-10.8, 1.35, 53.5) facing (-4, 1.35, 48)).
	-- Spacious 10.5 x 12.5 wood+stone coastal landing seamlessly joined to the last stair step AND the Aquarium stairs!
	do
		local lY = bottomTop
		-- Seamless deck X -24.0..-13.5, Z 51.0..68.5 (overlaps Landing X -14..-13.5 with zero gap, >6.5 studs clear past gentle Aquarium stairs!).
		makePlankDeck(m, "LunaWoodDock", C(-18.75, lY, 59.75), 10.5, 17.5, 0.9, PALETTE.woodWarm)
		makePart(
			m,
			"LunaStoneTrim",
			C(-18.75, lY - 0.95, 59.75),
			Vector3.new(10.9, 1.4, 17.9),
			PALETTE.stoneMid,
			Enum.Material.Cobblestone,
			true
		)
		for _, p in
			{
				{ -23.6, 51.4 },
				{ -23.6, 68.0 },
				{ -18.8, 68.0 },
				{ -14.2, 68.0 },
				{ -14.2, 51.4 },
			}
		do
			makeCylinderY(
				m,
				"LunaPiling",
				C(p[1], (lY - 6.0) / 2, p[2]),
				lY + 6.0,
				0.9,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
		end
		-- Protective rope railing along the south & west water edges (north & east stay open for stairs & Landing!).
		local lunaRail = {
			V(-23.6, lY, 52.0),
			V(-23.6, lY, 60.0),
			V(-23.6, lY, 68.0),
			V(-18.8, lY, 68.0),
			V(-14.2, lY, 68.0),
		}
		for i, p in lunaRail do
			makeCylinderY(
				m,
				"LunaRailPost",
				CFrame.new(p + Vector3.new(0, 1.4, 0)),
				3.2,
				0.5,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			if i > 1 then
				makeRope(
					m,
					"LunaRailRope",
					lunaRail[i - 1] + Vector3.new(0, 2.5, 0),
					p + Vector3.new(0, 2.5, 0),
					0.35,
					0.22
				)
			end
		end
		-- Upright bench cleanly aligned at 0 deg on the south rim (zero tilt, >= 3.6 studs clear of Luna & stairs!).
		makeBench(m, "LunaBench", CY(-17.8, lY, 66.6, 0))
		makeLantern(m, "LunaLantern", V(-23.2, lY, 67.3), 6.4, true)
		-- Woven seashell basket + glowing shells & starfish along the south-west dock rim (clear of stairs & Luna!).
		makeCylinderY(
			m,
			"LunaBasket",
			C(-21.8, lY + 0.55, 65.8),
			1.1,
			1.55,
			PALETTE.woodLight,
			Enum.Material.Fabric,
			false
		)
		makeCylinderY(
			m,
			"LunaBasketRim",
			C(-21.8, lY + 1.12, 65.8),
			0.18,
			1.68,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		for k = 0, 3 do
			local sa = k * 1.55 + 0.3
			makeEllipsoid(
				m,
				"LunaBasketShell",
				C(-21.8 + math.cos(sa) * 0.36, lY + 1.18, 65.8 + math.sin(sa) * 0.36),
				Vector3.new(0.55, 0.32, 0.45),
				if k % 2 == 0 then PALETTE.pinkLight else PALETTE.crystalCyan,
				Enum.Material.SmoothPlastic
			)
		end
		for _, sp in
			{
				{ -22.2, 64.2, PALETTE.pinkLight },
				{ -14.8, 64.8, PALETTE.crystalCyan },
				{ -21.4, 67.2, PALETTE.goldLight },
			}
		do
			makeEllipsoid(
				m,
				"LunaDockShell",
				CY(sp[1] :: number, lY + 0.14, sp[2] :: number, rnd(0, 360)),
				Vector3.new(0.75, 0.34, 0.62),
				sp[3] :: Color3,
				Enum.Material.SmoothPlastic
			)
		end
		-- Cute starfish on the dock corner.
		for k = 0, 4 do
			local a = k / 5 * math.pi * 2
			makePart(
				m,
				"LunaStarfish",
				C(-15.0, lY + 0.08, 59.2) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.32),
				Vector3.new(0.24, 0.12, 0.65),
				PALETTE.coral,
				Enum.Material.SmoothPlastic,
				false
			)
		end
	end

	-- Stepped side walls (X -16..-14 and 2..4) with deep stone flanks closing dark gaps along the coastal rocks.
	for _, x in { -15, 3 } do
		for i = 1, count do
			local top = PLAZA_Y - rise * i + 1.1
			local z = 24 + run * (i - 0.5)
			makePart(
				m,
				"SideWall",
				C(x, (top - 5.5) / 2, z),
				Vector3.new(2.2, top + 5.5, run + 0.06),
				vary(PALETTE.stoneMid, 0.02),
				Enum.Material.Slate,
				true
			)
			makePart(
				m,
				"SideCap",
				C(x, top + 0.1, z),
				Vector3.new(2.4, 0.2, run + 0.08),
				PALETTE.stoneWarm,
				Enum.Material.Slate,
				false
			)
		end
		-- Continuous stone flank apron sealing dark water gaps under SideWall (kept low below Y 3.8 so Pathfinding never parkours over it!).
		local flankX = if x < 0 then -16.8 else 4.8
		makePart(
			m,
			"StairFlankRock",
			C(flankX, -0.5, 36.5),
			Vector3.new(2.4, 8.2, 24.0),
			PALETTE.stoneBlue,
			Enum.Material.Slate,
			true
		)
		if x > 0 then
			makePart(
				m,
				"LandingWall",
				C(x, (bottomTop + 1.1 - 5.0) / 2, 55),
				Vector3.new(2.2, bottomTop + 1.1 + 5.0, 6.2),
				PALETTE.stoneMid,
				Enum.Material.Slate,
				true
			)
			makeLantern(m, "LandingLantern", V(x, bottomTop + 1.1, 57.2), 6.2, true)
		end
		makeCrystalCluster(
			m,
			"WallCrystal",
			V(x, PLAZA_Y - rise * 9 + 1.2, 24 + run * 8.5),
			0.75,
			if x < 0 then PALETTE.crystalCyan else PALETTE.crystalLilac,
			false
		)
	end
	task.wait()

	-- Tall monumental "Legendary Catch" wooden arch at the top of the stairs (>= 10 studs clear headroom!).
	for _, x in { -17.4, 5.4 } do
		local base = V(x, PLAZA_Y, 24.6)
		makeCylinderY(
			m,
			"ArchLog",
			CFrame.new(base + Vector3.new(0, 7.6, 0)),
			16.4,
			2.6,
			PALETTE.bark,
			Enum.Material.Wood,
			true
		)
		makeCylinderY(
			m,
			"ArchFoot",
			CFrame.new(base + Vector3.new(0, 0.7, 0)),
			1.4,
			3.5,
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		for k = 0, 2 do
			makeCylinderY(
				m,
				"ArchWrap",
				CFrame.new(base + Vector3.new(0, 2.2 + k * 0.48, 0)),
				0.38,
				2.85,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			makeCylinderY(
				m,
				"ArchWrap",
				CFrame.new(base + Vector3.new(0, 10.6 + k * 0.48, 0)),
				0.38,
				2.85,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
		end
		makeCylinderY(
			m,
			"ArchCap",
			CFrame.new(base + Vector3.new(0, 15.9, 0)),
			0.36,
			3.0,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeCrystalCluster(
			m,
			"ArchCrystal",
			base + Vector3.new(0, 16.2, 0),
			0.95,
			PALETTE.crystalCyan,
			true
		)
	end
	makeTube(
		m,
		"ArchBeam",
		V(-19.8, PLAZA_Y + 13.0, 24.6),
		V(7.8, PLAZA_Y + 13.0, 24.6),
		2.0,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	-- Big legible sign cleanly mounted BELOW the high beam with ~9.7 studs clear headroom underneath!
	for _, sx in { -11.4, -0.6 } do
		makeTube(
			m,
			"ArchSignChain",
			V(sx, PLAZA_Y + 12.2, 24.6),
			V(sx, PLAZA_Y + 13.0, 24.6),
			0.14,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
	end
	makeSign(
		m,
		"LegendaryCatchSign",
		faceTo(V(-6, PLAZA_Y + 11.4, 24.6), V(-6, PLAZA_Y + 11.4, 60)),
		15.2,
		3.2,
		"Legendary Catch",
		nil,
		PALETTE.signBg,
		PALETTE.goldLight,
		nil,
		PALETTE.gold,
		true
	)
	local archGem = makePart(
		m,
		"ArchGem",
		C(-6, PLAZA_Y + 14.8, 24.6) * CFrame.Angles(0, 0, math.rad(45)),
		Vector3.new(1.5, 1.5, 0.6),
		PALETTE.cyan,
		Enum.Material.Neon,
		false,
		0.05
	)
	tagSpin(archGem, 32, "Y", 0)
	tagBob(archGem, 0.22, 2.0, 0.4)
	-- Side hanging lanterns flanking the sign (well outside the sign edges, > 9 studs above stairs).
	for _, x in { -14.8, 2.8 } do
		makeTube(
			m,
			"ArchChain",
			V(x, PLAZA_Y + 12.2, 24.6),
			V(x, PLAZA_Y + 11.1, 24.6),
			0.12,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeLanternBody(m, "ArchLantern", V(x, PLAZA_Y + 10.2, 24.6), 1.0, true)
	end

	-- Coastal foam rings and crystal accents flanking the entrance cove (removed dead-end stepping stones!).
	for _, fm in { { -21.0, 42.0 }, { 9.5, 42.0 }, { -12.0, 59.5 }, { 1.5, 59.0 } } do
		local ring = makeCylinderY(
			m,
			"CoveFoam",
			C(fm[1], SEA_Y + 0.06, fm[2]),
			0.06,
			rnd(2.8, 4.2),
			PALETTE.foam,
			Enum.Material.SmoothPlastic,
			false,
			0.45
		)
		tagPulse(ring, 0.35, 0.65, 1.4, "Transparency")
	end
	for _, c in { { -21, 31 }, { 9.4, 33 }, { -22, 42 }, { 9.8, 44.5 }, { 8.6, 52 } } do
		local g = groundY(c[1], c[2])
		if g > -1 then
			makeCrystalCluster(
				m,
				"RockCrystal",
				V(c[1], g, c[2]),
				rnd(0.8, 1.2),
				if c[1] < 0 then PALETTE.crystalLilac else PALETTE.crystalCyan,
				false,
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
	local sm = makeModel(m, "SwirlModel")
	local pivot = makePart(
		sm,
		"SwirlPivot",
		cf * CFrame.new(0, cy, -0.1),
		Vector3.new(0.2, 0.2, 0.2),
		color,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	sm.PrimaryPart = pivot
	sm.WorldPivot = pivot.CFrame
	for arm = 0, arms - 1 do
		local prev: Vector3? = nil
		for k = 0, steps do
			local r = 0.25 + k / steps * maxR
			local a = arm * (math.pi * 2 / arms) + r * 1.35
			local p = (cf * CFrame.new(math.cos(a) * r, cy + math.sin(a) * r, -0.1)).Position
			local q = prev
			if q then
				makeSegment(
					sm,
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
	tagSpin(sm, 36, "Z", 0)
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
	-- Two-step stone base firmly seated (-0.2 stud overlap) into floor/deck.
	makeCylinderY(
		m,
		"BaseStep",
		cf * CFrame.new(0, bh / 4 - 0.1, 0),
		bh / 2 + 0.2,
		11.4,
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
	local baseGlow = makeModel(m, "BaseGlowRing")
	local bgPivot = makePart(
		baseGlow,
		"Pivot",
		cf * CFrame.new(0, bh + 0.06, 0),
		Vector3.new(0.2, 0.2, 0.2),
		accent,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	baseGlow.PrimaryPart = bgPivot
	baseGlow.WorldPivot = bgPivot.CFrame
	makeNeonRing(
		baseGlow,
		"BaseGlow",
		cf * CFrame.new(0, bh + 0.06, 0),
		4.1,
		0.16,
		24,
		primary,
		0.4
	)
	tagSpin(baseGlow, 14, "Y", 0)
	-- Rising colored particles from the portal base ring.
	local risePart = makePart(
		m,
		"PortalRiseEmitter",
		cf * CFrame.new(0, bh + 0.35, 0),
		Vector3.new(6.8, 0.4, 2.4),
		primary,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	local rp = Instance.new("ParticleEmitter")
	rp.Texture = SPARKLE_TEXTURE
	rp.Color = ColorSequence.new(primary, accent)
	rp.LightEmission = 0.85
	rp.Rate = 9
	rp.Lifetime = NumberRange.new(1.6, 2.6)
	rp.Speed = NumberRange.new(1.4, 2.8)
	rp.EmissionDirection = Enum.NormalId.Top
	rp.SpreadAngle = Vector2.new(16, 16)
	rp.RotSpeed = NumberRange.new(-60, 60)
	rp.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.42),
		NumberSequenceKeypoint.new(1, 0),
	})
	rp.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	rp.Parent = risePart
	stats.emitters += 1
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
		-- Chunky gray stone blocks with dark recessed joints + heavy timber lintel + glowing spiral keystone (ref-5).
		for _, sx in { -4.6, 4.6 } do
			makePart(
				m,
				"PillarCore",
				cf * CFrame.new(sx, bh + 5.7, 0),
				Vector3.new(2.1, 11.4, 2.0),
				PALETTE.stoneGrayDark,
				Enum.Material.Slate,
				true
			)
			local y = bh
			for i, hgt in { 2.4, 2.2, 2.3, 2.2, 2.3 } do
				local w = if i % 2 == 0 then 2.55 else 2.85
				makePart(
					m,
					"PillarBlock",
					cf * CFrame.new(sx, y + hgt / 2, 0),
					Vector3.new(w, hgt - 0.24, 2.6),
					vary(PALETTE.stoneGray, 0.04),
					Enum.Material.Slate,
					false
				)
				y += hgt
			end
		end
		-- Front stone entry steps leading into the stone portal.
		for st = 0, 1 do
			makePart(
				m,
				"PortalStep",
				cf * CFrame.new(0, bh * (0.25 + st * 0.45), -5.4 + st * 0.9),
				Vector3.new(6.2 - st * 0.8, bh * 0.48, 1.3),
				PALETTE.stoneGray,
				Enum.Material.Slate,
				true
			)
		end
		makePart(
			m,
			"Lintel",
			cf * CFrame.new(0, bh + 12.2, 0),
			Vector3.new(13.6, 1.85, 2.9),
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makePart(
			m,
			"LintelTop",
			cf * CFrame.new(0, bh + 13.18, 0),
			Vector3.new(14.0, 0.24, 3.1),
			PALETTE.barkDark,
			Enum.Material.Wood,
			false
		)
		makePart(
			m,
			"Emblem",
			cf * CFrame.new(0, bh + 13.7, 0),
			Vector3.new(3.1, 3.1, 2.7),
			vary(PALETTE.stoneGray, 0.03),
			Enum.Material.Slate,
			false
		)
		makeNeonRing(
			m,
			"EmblemRune",
			cf * CFrame.new(0, bh + 13.7, -1.42) * CFrame.Angles(math.pi / 2, 0, 0),
			1.0,
			0.22,
			14,
			primary,
			0.12
		)
		makeNeonRing(
			m,
			"EmblemRune",
			cf * CFrame.new(0, bh + 13.7, -1.42) * CFrame.Angles(math.pi / 2, 0, 0),
			0.45,
			0.2,
			10,
			primary,
			0.12
		)
		makePart(
			m,
			"Energy",
			cf * CFrame.new(0, bh + 5.65, 0.1),
			Vector3.new(7.1, 11.3, 0.22),
			primary,
			Enum.Material.Neon,
			false,
			0.32
		)
		cy = bh + 5.7
		addSwirl(m, cf, cy, 5, 14, 3.35, accent, 0.30)
	elseif style == "coral" then
		-- Chunky sculpted peach-coral shell ring with ribs, pearls, shells & lush coral branches (ref-3).
		local R = 4.6
		cy = bh + 5.8
		local segs = 24
		for i = 0, segs - 1 do
			local a = (i + 0.5) / segs * math.pi * 2
			local pcf = cf
				* CFrame.new(math.cos(a) * R, cy + math.sin(a) * R, 0)
				* CFrame.Angles(0, 0, a)
			local seg = 2 * math.pi * R / segs * 1.15
			makeEllipsoid(
				m,
				"Shell",
				pcf,
				Vector3.new(2.75, seg * 1.18, 3.2),
				if i % 2 == 0 then PALETTE.peach else PALETTE.peachLight,
				Enum.Material.SmoothPlastic
			)
			makePart(
				m,
				"ShellGroove",
				pcf * CFrame.new(0, seg / 2 - 0.04, -0.08),
				Vector3.new(2.55, 0.16, 2.8),
				PALETTE.coralDeep,
				Enum.Material.SmoothPlastic,
				false
			)
		end
		-- Front stone entry steps leading into the coral portal.
		for st = 0, 1 do
			makePart(
				m,
				"PortalStep",
				cf * CFrame.new(0, bh * (0.25 + st * 0.45), -5.4 + st * 0.9),
				Vector3.new(5.6 - st * 0.8, bh * 0.48, 1.3),
				PALETTE.peachLight,
				Enum.Material.SmoothPlastic,
				true
			)
		end
		local disc = Instance.new("Part")
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.24, 6.9, 6.9)
		disc.CFrame = cf * CFrame.new(0, cy, 0.1) * CFrame.Angles(0, math.pi / 2, 0)
		finishPart(disc, "Energy", primary, Enum.Material.Neon, false, 0.34)
		disc.Parent = m
		for k = 0, 8 do
			local a = math.rad(28 + k * 15.5)
			makeEllipsoid(
				m,
				"Seashell",
				cf * CFrame.new(math.cos(a) * (R + 1.35), cy + math.sin(a) * (R + 1.35), -0.4),
				Vector3.new(rnd(0.9, 1.3), rnd(0.8, 1.15), rnd(0.7, 1.0)),
				if k % 2 == 0 then PALETTE.white else PALETTE.pinkLight,
				Enum.Material.SmoothPlastic
			)
		end
		for _, sx in { -1, 1 } do
			local root = (cf * CFrame.new(sx * (R + 1.9), bh, 0.3)).Position
			for b = 1, 5 do
				local col = if b % 2 == 0 then PALETTE.coralDeep else PALETTE.coral
				local tip = root + Vector3.new(sx * rnd(0.35, 1.5), rnd(1.8, 4.2), rnd(-0.9, 0.9))
				makeTube(m, "Coral", root, tip, 0.44, col, Enum.Material.SmoothPlastic, false)
				makeBall(m, "CoralTip", tip, 0.56, col, Enum.Material.SmoothPlastic)
			end
		end
		addSwirl(m, cf, cy, 3, 10, 2.8, accent, 0.2)
	elseif style == "abyssTall" then
		-- Tall narrow royal-blue sculpted gothic arch, crystal crown, glowing pink cosmic hexagon inside (ref-3).
		local hw = 3.6
		local sideTop = bh + 9.4
		local apex = bh + 13.8
		for _, sx in { -hw, hw } do
			makePart(
				m,
				"Side",
				cf * CFrame.new(sx, (bh + sideTop) / 2, 0),
				Vector3.new(1.75, sideTop - bh, 2.3),
				PALETTE.abyssBlue,
				Enum.Material.SmoothPlastic,
				true
			)
			makePart(
				m,
				"SideTrim",
				cf * CFrame.new(sx * 0.84, (bh + sideTop) / 2, -0.35),
				Vector3.new(0.45, sideTop - bh - 0.3, 1.85),
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
				1.7,
				PALETTE.abyssBlue,
				Enum.Material.SmoothPlastic,
				false
			)
			seg.Size = Vector3.new(2.3, 1.65, seg.Size.Z + 0.75)
			makeCrystalCluster(
				m,
				"SideCrystal",
				(cf * CFrame.new(sx * 1.48, bh, 0.25)).Position,
				0.72,
				PALETTE.crystalLilac,
				false,
				PALETTE.abyssBlueLight
			)
		end
		makeCrystal(
			m,
			"TopCrystal",
			cf * CFrame.new(0, apex + 0.35, 0),
			2.8,
			0.56,
			PALETTE.crystalCyan,
			true
		)
		makePart(
			m,
			"Energy",
			cf * CFrame.new(0, (bh + sideTop) / 2, 0.15),
			Vector3.new(5.8, sideTop - bh, 0.22),
			PALETTE.navy,
			Enum.Material.SmoothPlastic,
			false,
			0.05
		)
		makeWedge(
			m,
			"EnergyTop",
			cf * CFrame.new(-1.45, sideTop + 1.9, 0.15) * CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(0.22, 3.8, 2.9),
			PALETTE.navy,
			Enum.Material.SmoothPlastic,
			false,
			0.05
		)
		makeWedge(
			m,
			"EnergyTop",
			cf * CFrame.new(1.45, sideTop + 1.9, 0.15) * CFrame.Angles(0, math.rad(-90), 0),
			Vector3.new(0.22, 3.8, 2.9),
			PALETTE.navy,
			Enum.Material.SmoothPlastic,
			false,
			0.05
		)
		cy = bh + 5.8
		-- Glowing pink cosmic hexagon with crisp double outline.
		for k = 0, 2 do
			makePart(
				m,
				"Hexagon",
				cf * CFrame.new(0, cy, 0) * CFrame.Angles(0, 0, math.rad(60 * k)),
				Vector3.new(2.05, 3.55, 0.12),
				PALETTE.hexPink,
				Enum.Material.Neon,
				false,
				0.32
			)
		end
		for k = 0, 5 do
			local a0 = math.rad(60 * k + 30)
			local a1 = math.rad(60 * (k + 1) + 30)
			makeSegment(
				m,
				"HexEdge",
				(cf * CFrame.new(math.cos(a0) * 2.5, cy + math.sin(a0) * 2.5, -0.14)).Position,
				(cf * CFrame.new(math.cos(a1) * 2.5, cy + math.sin(a1) * 2.5, -0.14)).Position,
				0.18,
				PALETTE.pinkLight,
				Enum.Material.Neon,
				false
			)
		end
		for _ = 1, 10 do
			makeBall(
				m,
				"Star",
				(cf * CFrame.new(rnd(-2.4, 2.4), rnd(1.6, 11), -0.22)).Position,
				0.24,
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
		addLight(inner, primary, 15, 1.0)
		addSparkles(inner, PALETTE.hexPink, 7, 0.38, 1.0, 1.4)
	else
		-- Chunky round-topped arch variants: stoneArch (welcoming carved stone + cyan/gold runes),
		-- reef (turquoise + corals), abyss (dark + crystals), gold (temple + pastel rays).
		local frameColor: Color3
		local frameAlt: Color3
		local frameMat = Enum.Material.SmoothPlastic
		if style == "stoneArch" then
			frameColor, frameAlt = PALETTE.stoneGray, PALETTE.stoneWarm
			frameMat = Enum.Material.Slate
		elseif style == "reef" then
			frameColor, frameAlt = PALETTE.teal, Color3.fromRGB(120, 224, 204)
		elseif style == "abyss" then
			frameColor, frameAlt = PALETTE.violetDark, PALETTE.violet
		else
			frameColor, frameAlt = PALETTE.gold, PALETTE.goldLight
		end
		local R = if style == "stoneArch" then 4.9 else 4.7
		local springY = if style == "stoneArch" then bh + 7.8 else bh + 7.2
		archFrame(m, cf, bh, R, springY, 2.1, 2.5, frameColor, frameAlt, frameMat)
		-- Front steps leading up onto the portal base.
		for st = 0, 1 do
			makePart(
				m,
				"PortalStep",
				cf * CFrame.new(0, bh * (0.25 + st * 0.45), -5.5 + st * 0.9),
				Vector3.new(6.0 - st * 0.8, bh * 0.48, 1.3),
				baseColor,
				Enum.Material.Slate,
				true
			)
		end
		if style == "stoneArch" then
			-- Carved keystone with glowing spiral emblem + glowing runes on pillars + flanking crystals.
			makePart(
				m,
				"Keystone",
				cf * CFrame.new(0, springY + R + 0.4, 0),
				Vector3.new(3.0, 2.8, 2.9),
				PALETTE.stoneGrayDark,
				Enum.Material.Slate,
				false
			)
			local gem = makePart(
				m,
				"KeystoneGem",
				cf * CFrame.new(0, springY + R + 0.5, -1.48) * CFrame.Angles(0, 0, math.rad(45)),
				Vector3.new(1.3, 1.3, 0.3),
				primary,
				Enum.Material.Neon,
				false,
				0.1
			)
			tagPulse(gem, 0.05, 0.4, 2.0, "Transparency")
			for _, sx in { -R, R } do
				for k = 0, 2 do
					makePart(
						m,
						"PillarRune",
						cf * CFrame.new(sx, bh + 1.8 + k * 2.2, -1.32),
						Vector3.new(0.85, 0.22, 0.14),
						primary,
						Enum.Material.Neon,
						false,
						0.18
					)
				end
				makeCrystalCluster(
					m,
					"ArchFootCrystal",
					(cf * CFrame.new(sx * 1.38, bh, 0.25)).Position,
					0.82,
					primary,
					false,
					PALETTE.crystalGold
				)
			end
		elseif style == "reef" then
			for _, sx in { -1, 1 } do
				local root = (cf * CFrame.new(sx * (R + 1.4), bh, 0.3)).Position
				for b = 1, 6 do
					local col = if b % 2 == 0 then PALETTE.pink else PALETTE.flame
					local tip = root
						+ Vector3.new(sx * rnd(0.45, 1.9), rnd(2.2, 5.2), rnd(-1.0, 1.0))
					makeTube(m, "Coral", root, tip, 0.48, col, Enum.Material.SmoothPlastic, false)
					makeBall(m, "CoralTip", tip, 0.6, col, Enum.Material.SmoothPlastic)
					local tip2 = tip + Vector3.new(sx * rnd(0.25, 1.0), rnd(0.7, 1.5), 0)
					makeTube(m, "Coral", tip, tip2, 0.32, col, Enum.Material.SmoothPlastic, false)
					makeBall(m, "CoralTip", tip2, 0.42, col, Enum.Material.SmoothPlastic)
				end
			end
			for k = 0, 6 do
				local a = k / 6 * math.pi
				makeEllipsoid(
					m,
					"Shell",
					cf
						* CFrame.new(
							math.cos(a) * (R + 0.95),
							springY + math.sin(a) * (R + 0.95),
							-0.5
						),
					Vector3.new(rnd(0.85, 1.15), rnd(0.75, 1.0), rnd(0.7, 0.9)),
					if k % 2 == 0 then PALETTE.white else PALETTE.peachLight,
					Enum.Material.SmoothPlastic
				)
			end
		elseif style == "abyss" then
			for k = 0, 12 do
				local a = k / 12 * math.pi
				local p = cf
					* CFrame.new(math.cos(a) * (R + 0.9), springY + math.sin(a) * (R + 0.9), 0)
				makeCrystal(
					m,
					"Spike",
					p * CFrame.Angles(0, 0, a - math.pi / 2),
					rnd(2.4, 3.8),
					0.48,
					if k % 2 == 0 then PALETTE.crystalLilac else PALETTE.violet,
					k == 6
				)
			end
			for _, sx in { -1, 1 } do
				makeCrystalCluster(
					m,
					"BaseCrystal",
					(cf * CFrame.new(sx * (R + 1.6), bh, 0.25)).Position,
					0.95,
					PALETTE.violet,
					false,
					PALETTE.crystalLilac
				)
			end
		else
			makeCrystal(
				m,
				"TopGem",
				cf * CFrame.new(0, springY + R + 1.0, 0),
				3.0,
				0.72,
				PALETTE.crystalGold,
				true
			)
			for _, sx in { -R, R } do
				for k = 0, 3 do
					makeBall(
						m,
						"Bulb",
						(cf * CFrame.new(sx, bh + 1.3 + k * 1.65, -1.25)).Position,
						0.48,
						PALETTE.white,
						Enum.Material.Neon,
						0.18
					)
				end
				makePart(
					m,
					"Capital",
					cf * CFrame.new(sx, springY + 0.25, 0),
					Vector3.new(2.7, 0.65, 2.8),
					PALETTE.goldLight,
					Enum.Material.SmoothPlastic,
					false
				)
				makePart(
					m,
					"Plinth",
					cf * CFrame.new(sx, bh + 0.45, 0),
					Vector3.new(2.8, 0.9, 2.9),
					PALETTE.goldLight,
					Enum.Material.SmoothPlastic,
					false
				)
			end
			-- Soft pastel rainbow ray fan behind the Celestial arch (ref-1/ref-2).
			local rayCols = {
				PALETTE.pinkLight,
				PALETTE.goldLight,
				Color3.fromRGB(166, 240, 202),
				Color3.fromRGB(168, 212, 255),
				PALETTE.crystalLilac,
			}
			for k = 0, 8 do
				local ang = math.rad(-56 + k * 14)
				local base = cf * CFrame.new(0, springY + R - 0.6, 1.6) * CFrame.Angles(0, 0, ang)
				makePart(
					m,
					"Ray",
					base * CFrame.new(0, 8.2, 0),
					Vector3.new(1.15, 16, 0.12),
					rayCols[k % #rayCols + 1],
					Enum.Material.Neon,
					false,
					0.80
				)
			end
		end
		makePart(
			m,
			"Energy",
			cf * CFrame.new(0, (bh + springY) / 2, 0.1),
			Vector3.new(8.0, springY - bh, 0.22),
			primary,
			Enum.Material.Neon,
			false,
			0.35
		)
		local disc = Instance.new("Part")
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.22, 8.0, 8.0)
		disc.CFrame = cf * CFrame.new(0, springY, 0.1) * CFrame.Angles(0, math.pi / 2, 0)
		finishPart(disc, "EnergyTop", primary, Enum.Material.Neon, false, 0.35)
		disc.Parent = m
		cy = bh + 6.6
		addSwirl(m, cf, cy, 3, 11, 3.4, accent, 0.2)
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
		local coreBall = makeBall(
			m,
			"Core",
			(cf * CFrame.new(0, cy, -0.12)).Position,
			1.1,
			PALETTE.white,
			Enum.Material.Neon,
			0.2
		)
		tagPulse(coreBall, 0.1, 0.45, 2.2, "Transparency")
		addLight(glow, primary, 15, 0.95)
		addSparkles(glow, accent, 8, 0.42, 1.4, 1.5)
	end

	if lightBeam then
		-- Thin (1.3..2.3 studs), short (18..20 studs), very translucent beam (Transparency >= 0.90, ref-3).
		makeCylinderY(
			m,
			"LightBeam",
			cf * CFrame.new(0, bh + 23.5, 2.2),
			20,
			1.35,
			primary,
			Enum.Material.Neon,
			false,
			0.90
		)
		makeCylinderY(
			m,
			"LightHalo",
			cf * CFrame.new(0, bh + 21.5, 2.2),
			16,
			2.4,
			primary,
			Enum.Material.Neon,
			false,
			0.95
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

	-- Taller pilings + rope rails along both sides (gaps for Lucy's bait stall on north & boardwalk on south).
	local railY = Y + 2.7
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
					railY + 9 + 0.35,
					0.98,
					vary(PALETTE.woodDark, 0.04),
					Enum.Material.Wood,
					true
				)
				makeCylinderY(
					m,
					"PilingCap",
					CFrame.new(top + Vector3.new(0, 0.22, 0)),
					0.24,
					1.12,
					PALETTE.wood,
					Enum.Material.Wood,
					false
				)
				makeCylinderY(
					m,
					"PilingKnot",
					CFrame.new(top - Vector3.new(0, 0.45, 0)),
					0.42,
					1.18,
					PALETTE.rope,
					Enum.Material.Fabric,
					false
				)
				local p = prev
				if p then
					makeRope(
						m,
						"Rail",
						p - Vector3.new(0, 0.45, 0),
						top - Vector3.new(0, 0.45, 0),
						0.45,
						0.25
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
	railSide(2.55, xsMain, 30, 38)
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
			local top = V(85.45, Y + 1.8, z)
			makeCylinderY(
				m,
				"EndPiling",
				CFrame.new(V(85.45, (Y + 1.8 - 9) / 2, z)),
				Y + 1.8 + 9,
				0.98,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			makeCylinderY(
				m,
				"EndKnot",
				CFrame.new(top - Vector3.new(0, 0.35, 0)),
				0.36,
				1.15,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			local p = prev
			if p then
				makeRope(
					m,
					"EndRope",
					p - Vector3.new(0, 0.35, 0),
					top - Vector3.new(0, 0.35, 0),
					0.35,
					0.24
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

	-- Lucy's Bait Stall on the north edge of the pier (NPC Lucy stands at (34, 10.1, 3.2) looking south; >= 3 studs clear!).
	-- Deck overlaps PierDeck (+0.35 stud) + collidable pilings + exact-height 4 posts & side rafters supporting the sloped awning!
	do
		local sx = 34
		makePlankDeck(m, "BaitStallDeck", C(sx, Y, 0.75), 8.4, 5.2, 0.9, PALETTE.woodWarm)
		for _, px in { 30.2, 37.8 } do
			for _, pz in { -1.45, 2.15 } do
				makeCylinderY(
					m,
					"BaitStallPiling",
					C(px, (Y - 0.1 - 10) / 2, pz),
					Y - 0.1 + 10,
					0.88,
					PALETTE.woodDark,
					Enum.Material.Wood,
					true
				)
				-- Exact post height touching the 14-deg sloped awning (rear Z -1.45 = 8.95, front Z 2.15 = 7.95).
				local postH = if pz < 0 then 9.0 else 8.0
				makeCylinderY(
					m,
					"BaitStallPost",
					C(px, Y + postH / 2 - 0.1, pz),
					postH + 0.2,
					0.56,
					PALETTE.bark,
					Enum.Material.Wood,
					true
				)
			end
			-- Sloped side rafter tying front & rear posts solidly to the awning canopy!
			makeSegment(
				m,
				"BaitRafter",
				V(px, Y + 8.85, -1.65),
				V(px, Y + 7.75, 2.55),
				0.36,
				PALETTE.woodDark,
				Enum.Material.Wood,
				false
			)
		end
		-- Front & rear cross-headers tying left and right posts under the awning.
		makeTube(
			m,
			"BaitHeaderRear",
			V(30.0, Y + 8.75, -1.45),
			V(38.0, Y + 8.75, -1.45),
			0.36,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeTube(
			m,
			"BaitHeaderFront",
			V(30.0, Y + 7.85, 2.15),
			V(38.0, Y + 7.85, 2.15),
			0.36,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		-- Counter & back shelves behind Lucy (Z = -0.6..1.5, leaving >= 3 studs clear around Lucy at (34, 3.2)!).
		makePart(
			m,
			"BaitCounter",
			C(sx, Y + 1.15, 0.95),
			Vector3.new(6.8, 2.5, 1.3),
			PALETTE.wood,
			Enum.Material.Wood,
			true
		)
		makePart(
			m,
			"BaitCounterTop",
			C(sx, Y + 2.48, 0.95),
			Vector3.new(7.2, 0.22, 1.6),
			PALETTE.woodLight,
			Enum.Material.Wood,
			false
		)
		makePart(
			m,
			"BaitBackWall",
			C(sx, Y + 3.2, -1.35),
			Vector3.new(7.4, 6.4, 0.35),
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		-- Shelves with glowing bait jars & buckets.
		for row = 0, 1 do
			local sy = Y + 2.8 + row * 1.65
			makePart(
				m,
				"BaitShelf",
				C(sx, sy, -0.7),
				Vector3.new(6.6, 0.18, 0.85),
				PALETTE.woodLight,
				Enum.Material.Wood,
				false
			)
			local jarCols = {
				PALETTE.crystalCyan,
				PALETTE.coral,
				PALETTE.amber,
				PALETTE.crystalPink,
				PALETTE.leafLight,
			}
			for j = 1, 5 do
				local jx = sx - 2.6 + (j - 1) * 1.3
				makeCylinderY(
					m,
					"BaitJar",
					C(jx, sy + 0.45, -0.7),
					0.75,
					0.55,
					jarCols[j],
					Enum.Material.Glass,
					false,
					0.25
				)
				makeCylinderY(
					m,
					"BaitJarCap",
					C(jx, sy + 0.88, -0.7),
					0.16,
					0.6,
					PALETTE.woodDark,
					Enum.Material.Wood,
					false
				)
			end
		end
		-- Striped blue-and-cream sloped canopy roof.
		for k = 0, 5 do
			local rx = sx - 3.3 + k * 1.32
			makePart(
				m,
				"BaitAwning",
				C(rx, Y + 8.3, 0.55) * CFrame.Angles(math.rad(14), 0, 0),
				Vector3.new(1.34, 0.26, 4.8),
				if k % 2 == 0 then PALETTE.roofBlueLight else PALETTE.signText,
				Enum.Material.SmoothPlastic,
				false
			)
		end
		makeNet(m, "BaitNet", V(30.3, Y + 7.2, -1.2), V(30.3, Y + 7.2, 2.2), 2.2)
		makeLanternBody(m, "BaitLantern", V(sx, Y + 6.9, 1.9), 0.82, true)
		makeSign(
			m,
			"BaitStallSign",
			faceTo(V(sx, Y + 9.4, 2.35), V(sx, Y + 9.4, 15)),
			6.4,
			1.6,
			"ISCAS DA LUCY",
			nil,
			PALETTE.signWood,
			PALETTE.goldLight,
			nil,
			PALETTE.woodDark,
			false
		)
	end

	-- Tall monumental entrance gate "PÍER DE PESCA" (>= 9.8 studs clear headroom, zero bunting/hook over text!).
	for _, z in { 1.7, 14.3 } do
		makeCylinderY(
			m,
			"GatePost",
			C(19.6, (Y + 16.4 - 6) / 2, z),
			Y + 16.4 + 6,
			2.3,
			PALETTE.bark,
			Enum.Material.Wood,
			true
		)
		makeCylinderY(
			m,
			"GatePostCap",
			C(19.6, Y + 16.55, z),
			0.35,
			2.6,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		for k = 0, 3 do
			makeCylinderY(
				m,
				"GateWrap",
				C(19.6, Y + 1.8 + k * 0.46, z),
				0.38,
				2.55,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			makeCylinderY(
				m,
				"GateWrap",
				C(19.6, Y + 12.2 + k * 0.46, z),
				0.38,
				2.55,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
		end
		makeTube(
			m,
			"LampArm",
			V(19.6, Y + 11.4, z),
			V(19.6, Y + 11.4, if z < 8 then z + 1.6 else z - 1.6),
			0.3,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeLanternBody(
			m,
			"GateLantern",
			V(19.6, Y + 10.3, if z < 8 then z + 1.6 else z - 1.6),
			1.05,
			true
		)
	end
	makeTube(
		m,
		"GateBeam",
		V(19.6, Y + 14.4, -0.3),
		V(19.6, Y + 14.4, 16.3),
		2.0,
		PALETTE.bark,
		Enum.Material.Wood,
		false
	)
	for _, z in { 4.8, 11.2 } do
		makeTube(
			m,
			"SignRope",
			V(19.6, Y + 13.5, z),
			V(19.6, Y + 12.6, z),
			0.16,
			PALETTE.rope,
			Enum.Material.Fabric,
			false
		)
	end
	makeSign(
		m,
		"PierSign",
		faceTo(V(19.6, Y + 10.9, 8), V(0, Y + 10.9, 8)),
		10.2,
		2.9,
		"PÍER DE PESCA",
		nil,
		PALETTE.signWood,
		PALETTE.signText,
		nil,
		PALETTE.woodDark,
		true
	)
	-- Bunting strung cleanly ABOVE the crossbeam so flags never touch the sign top!
	makeBunting(m, "GateBunting", V(19.2, Y + 15.6, 2.3), V(19.2, Y + 15.6, 13.7), 0.35)
	-- 3D fishing hook emblem mounted cleanly on the outer north post side (never overlaps text).
	do
		local base = V(19.2, Y + 11.2, 2.9)
		makeTube(
			m,
			"Hook",
			base + Vector3.new(0, 0.9, 0),
			base + Vector3.new(0, -0.35, 0),
			0.2,
			PALETTE.goldLight,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Hook",
			base + Vector3.new(0, -0.35, 0),
			base + Vector3.new(0, -0.75, 0.45),
			0.2,
			PALETTE.goldLight,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Hook",
			base + Vector3.new(0, -0.75, 0.45),
			base + Vector3.new(0, -0.25, 0.78),
			0.2,
			PALETTE.goldLight,
			Enum.Material.Metal,
			false
		)
	end

	-- Props: crates, barrels, nets, buoys, rope coils, rods, tall flag poles with high bunting (~10.5 studs).
	makeCrate(m, "PierCrate", CY(23, Y + 0.6, 4.3, 0), 1.2)
	makeCrate(m, "PierCrate", CY(24.4, Y + 0.55, 4.2, -10), 1.1)
	makeCrate(m, "PierCrate", CY(23.4, Y + 1.75, 4.4, 8), 1.0)
	makeBarrel(m, "PierBarrel", V(26.5, Y, 11.9), 1.8)
	makeBarrel(m, "PierBarrel", V(28.1, Y, 12.1), 1.6)
	makeNet(m, "PierNet", V(33, railY - 0.4, 13.75), V(40, railY - 0.4, 13.75), 2.2)
	makeNet(m, "PierNet", V(45, railY - 0.4, 2.25), V(51, railY - 0.4, 2.25), 2.0)
	for i, x in { 24, 36, 48, 56, 68 } do
		local z = if i % 2 == 0 then 1.95 else 14.05
		local pos = V(x, Y - 0.4, z)
		makeBuoy(m, "Buoy", faceTo(pos, pos + Vector3.new(0, 0, if z < 8 then -1 else 1)), 0.82)
	end
	-- Subtle sea foam rings around the main pier pilings at water level (SEA_Y = 0).
	for idx, px in { 24, 38, 52, 66, 78, 84 } do
		local foam = makeCylinderY(
			m,
			"PierSeaFoam",
			C(px, SEA_Y + 0.05, if idx % 2 == 0 then 13.45 else 2.55),
			0.05,
			2.4,
			PALETTE.foam,
			Enum.Material.SmoothPlastic,
			false,
			0.48
		)
		tagPulse(foam, 0.38, 0.7, 1.5 + idx * 0.1, "Transparency")
	end
	for _, c in { { 29.0, 4.0 }, { 62, 4.2 }, { 83.6, 12.8 } } do
		makeNeonRing(
			m,
			"RopeCoil",
			C(c[1], Y + 0.12, c[2]),
			0.65,
			0.32,
			10,
			PALETTE.rope,
			0,
			Enum.Material.Fabric
		)
		makeNeonRing(
			m,
			"RopeCoil",
			C(c[1], Y + 0.32, c[2]),
			0.48,
			0.3,
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
			V(41.4 + k * 0.6, Y + 5.2, 13.4),
			0.14,
			vary(PALETTE.woodDark, 0.1),
			Enum.Material.Wood,
			false
		)
	end
	makeCylinderY(
		m,
		"Bucket",
		C(42.8, Y + 0.5, 12.2),
		1.0,
		1.1,
		PALETTE.roofBlueLight,
		Enum.Material.SmoothPlastic,
		false
	)
	for _, x in { 28, 44, 60 } do
		makeLanternBody(m, "PierLantern", V(x, railY + 1.05, 2.55), 0.9, true)
	end
	for _, x in { 36, 52, 72 } do
		makeLanternBody(m, "PierLantern", V(x, railY + 1.05, 13.45), 0.9, x ~= 52)
	end
	local poles =
		{ V(28, Y, 1.85), V(40, Y, 1.85), V(56, Y, 1.85), V(71, Y, 1.85), V(84.8, Y, 0.9) }
	for i, p in poles do
		makeCylinderY(
			m,
			"FlagPole",
			CFrame.new(p + Vector3.new(0, 5.4, 0)),
			10.8,
			0.46,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		makeBall(
			m,
			"PoleKnob",
			p + Vector3.new(0, 10.95, 0),
			0.65,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		if i > 1 then
			makeBunting(
				m,
				"PierBunting",
				poles[i - 1] + Vector3.new(0, 10.3, 0),
				p + Vector3.new(0, 10.3, 0),
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
	makeStandingSign(
		m,
		"TipSign",
		V(81.6, Y, 2.2),
		V(50, Y, 8),
		5.8,
		2.0,
		"PONTO DE PESCA",
		"Lance para o leste!",
		5.0,
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

	-- Continuous 10-stud wide ramp centered at X 16 (X 11..21, well inside WharfFloor X 10..66 so west Curb NEVER blocks entry!).
	makeBridge(m, "WharfBridge", V(16.0, PLAZA_Y, 23.4), V(16.0, WHARF_Y, 33.8), 10.0, false, 3.4)
	Y = WHARF_Y

	-- Darker weathered stone platform X 10..66, Z 33..64, with slab tiles in 3 warm-dark tones.
	makePart(
		m,
		"WharfFloor",
		C(38, Y - 1.6, 48.5),
		Vector3.new(56, 3.2, 31),
		PALETTE.stoneJoint,
		Enum.Material.Slate,
		true
	)
	local wTones = { PALETTE.stoneMid, PALETTE.stone, PALETTE.stoneDark, PALETTE.stoneMid }
	for ix = 0, 13 do
		for iz = 0, 6 do
			local x = 10 + 4 * (ix + 0.5)
			local z = 33 + (31 / 7) * (iz + 0.5)
			makePart(
				m,
				"WharfSlab",
				C(x, Y + 0.01, z),
				Vector3.new(3.8 - rnd(0, 0.1), 0.1, 31 / 7 - 0.2 - rnd(0, 0.1)),
				vary(wTones[rndInt(1, #wTones)], 0.03),
				Enum.Material.Slate,
				false
			)
		end
	end
	makePart(
		m,
		"WharfSkirt",
		C(38, Y - 3.4, 48.5),
		Vector3.new(56.6, 1.0, 31.6),
		PALETTE.stoneDark,
		Enum.Material.Slate,
		false
	)
	for _, e in { { 38, 32.8, 56.8, 0.45 }, { 38, 64.2, 56.8, 0.45 } } do
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
	for _, x in { 9.8, 66.2 } do
		makePart(
			m,
			"WharfEdgeStone",
			C(x, Y - 0.9, 48.5),
			Vector3.new(0.45, 1.8, 31.8),
			PALETTE.stoneDark,
			Enum.Material.Cobblestone,
			false
		)
	end
	for _, p in { { 15, 38 }, { 38, 38 }, { 61, 38 }, { 15, 59 }, { 38, 59 }, { 61, 59 } } do
		makeCylinderY(
			m,
			"WharfColumn",
			C(p[1], (Y - 3.3 - 9) / 2, p[2]),
			Y - 3.3 + 9,
			4.4,
			PALETTE.stoneDark,
			Enum.Material.Cobblestone,
			false
		)
		makeCylinderY(
			m,
			"WharfColumnRing",
			C(p[1], 0.4, p[2]),
			0.8,
			4.8,
			PALETTE.stoneDark,
			Enum.Material.Slate,
			false
		)
	end
	-- Curb (wide openings for 10-stud bridge X 9.5..20.2 and 7.4-stud east boardwalk Z 40.2..49.8; taller edge keeps Pathfinding off sea).
	local curbH = 0.85
	local function curb(x0: number, z0: number, x1: number, z1: number)
		local a = V(x0, Y + curbH / 2 - 0.1, z0)
		local b = V(x1, Y + curbH / 2 - 0.1, z1)
		local len = (b - a).Magnitude
		makePart(
			m,
			"Curb",
			CFrame.lookAt((a + b) / 2, b),
			Vector3.new(0.95, curbH + 0.2, len),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
	end
	curb(10.4, 34.4, 10.4, 63.6)
	curb(10.4, 63.6, 65.6, 63.6)
	curb(65.6, 63.6, 65.6, 49.8)
	curb(65.6, 40.2, 65.6, 33.4)
	curb(65.6, 33.4, 21.8, 33.4)
	-- Safety timber+rope railing along the west Wharf cliff drop-off (X 10.4, Z 35.0..63.6) so players never jump across water from FrontStairs!
	do
		makePart(
			m,
			"WharfWestGuard",
			C(10.4, Y + 4.5, 49.3),
			Vector3.new(0.6, 9.0, 29.2),
			PALETTE.woodDark,
			Enum.Material.Wood,
			true,
			1
		)
		local wPosts = { 36.2, 41.5, 47.0, 52.5, 58.0, 63.4 }
		for i, wz in wPosts do
			makeCylinderY(
				m,
				"WharfWestPost",
				C(10.4, Y + 1.9, wz),
				3.8,
				0.54,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			if i > 1 then
				local prevZ = wPosts[i - 1]
				makePart(
					m,
					"WharfWestRailBar",
					C(10.4, Y + 3.1, (prevZ + wz) / 2),
					Vector3.new(0.32, 0.32, wz - prevZ),
					PALETTE.wood,
					Enum.Material.Wood,
					true
				)
				makeRope(
					m,
					"WharfWestRope",
					V(10.4, Y + 2.2, prevZ),
					V(10.4, Y + 2.2, wz),
					0.35,
					0.22
				)
			end
		end
	end
	task.wait()

	-- Tall monumental Portico "CAIS DAS EXPEDIÇÕES" (>= 10 studs clear width & headroom; WharfSign mounted ABOVE beam, zero post overlap!).
	local pz = 34.8
	for _, x in { 10.1, 21.9 } do
		makeCylinderY(
			m,
			"PorticoPost",
			C(x, Y + 8.1, pz),
			16.6,
			1.85,
			PALETTE.bark,
			Enum.Material.Wood,
			true
		)
		for k = 0, 3 do
			makeCylinderY(
				m,
				"PorticoWrap",
				C(x, Y + 1.6 + k * 0.46, pz),
				0.38,
				2.05,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
			makeCylinderY(
				m,
				"PorticoWrap",
				C(x, Y + 12.2 + k * 0.46, pz),
				0.38,
				2.05,
				PALETTE.rope,
				Enum.Material.Fabric,
				false
			)
		end
		makeCrystalCluster(
			m,
			"PorticoCrystal",
			V(x, Y + 16.4, pz),
			0.75,
			PALETTE.crystalCyan,
			false
		)
		local bpos = V(if x < 16 then x - 1.0 else x + 1.0, Y + 5.2, pz)
		makeBuoy(
			m,
			"PorticoBuoy",
			faceTo(bpos, bpos + Vector3.new(0, 0, -1)) * CFrame.Angles(0, math.rad(90), 0),
			0.85
		)
	end
	makeTube(
		m,
		"PorticoBeam",
		V(8.1, Y + 13.8, pz),
		V(23.9, Y + 13.8, pz),
		1.55,
		PALETTE.bark,
		Enum.Material.Wood,
		false
	)
	for _, sx in { 12.9, 19.1 } do
		makeCylinderY(
			m,
			"PorticoSignMount",
			C(sx, Y + 14.7, pz),
			1.2,
			0.36,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	makeSign(
		m,
		"WharfSign",
		faceTo(V(16.0, Y + 16.7, pz), V(16.0, Y + 16.7, 0)),
		10.4,
		3.2,
		"CAIS DAS",
		"EXPEDIÇÕES",
		PALETTE.signWood,
		PALETTE.signText,
		PALETTE.goldLight,
		PALETTE.woodDark,
		true
	)
	-- Bunting strung cleanly BELOW the beam at Y + 12.6 (never touches sign above beam or avatar heads!).
	makeBunting(m, "PorticoBunting", V(11.3, Y + 12.8, pz), V(20.7, Y + 12.8, pz), 0.55)
	for _, x in { 8.3, 23.7 } do
		makeTube(
			m,
			"BeamChain",
			V(x, Y + 13.2, pz),
			V(x, Y + 11.8, pz),
			0.12,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeLanternBody(m, "PorticoLantern", V(x, Y + 10.8, pz), 1.0, x < 16)
	end

	-- Portals: two active + two "coming soon" slots, generously spaced (13 studs apart), facing the plaza (-Z).
	local slotZ = 56.8
	local portals = {
		{
			x = 19,
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
			cf * CFrame.new(0, PORTAL_BASE_H + 19.4, 0),
			10.2,
			3.1,
			d.title,
			d.sub,
			PALETTE.signBg,
			PALETTE.signText,
			d.primary,
			PALETTE.gold,
			true
		)
	end
	for _, x in { 45.5, 58.5 } do
		local cf = faceTo(V(x, Y, slotZ), V(x, Y, 0))
		makeCylinderY(
			m,
			"EmptySlotBase",
			cf * CFrame.new(0, PORTAL_BASE_H / 2, 0),
			PORTAL_BASE_H,
			10.4,
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		makeNeonRing(
			m,
			"EmptySlotRing",
			cf * CFrame.new(0, PORTAL_BASE_H + 0.06, 0),
			4.5,
			0.22,
			24,
			PALETTE.white,
			0.55
		)
		for _, sx in { -4.6, 4.6 } do
			makePart(
				m,
				"GhostPillar",
				cf * CFrame.new(sx, PORTAL_BASE_H + 4.8, 0),
				Vector3.new(1.3, 9.6, 1.5),
				PALETTE.stone,
				Enum.Material.Slate,
				false,
				0.55
			)
			makeCylinderY(
				m,
				"BarrierPost",
				cf * CFrame.new(sx * 0.72, PORTAL_BASE_H + 1.4, -4.6),
				2.8,
				0.48,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
		end
		makeRope(
			m,
			"BarrierRope",
			(cf * CFrame.new(-3.3, PORTAL_BASE_H + 2.4, -4.6)).Position,
			(cf * CFrame.new(3.3, PORTAL_BASE_H + 2.4, -4.6)).Position,
			0.45,
			0.24,
			PALETTE.red
		)
		makeStandingSign(
			m,
			"SoonSign",
			(cf * CFrame.new(0, PORTAL_BASE_H, 0)).Position,
			(cf * CFrame.new(0, PORTAL_BASE_H, -10)).Position,
			7.6,
			2.4,
			"EM BREVE",
			"Nova expedição",
			4.6,
			PALETTE.signBg,
			PALETTE.signText,
			PALETTE.crystalCyan,
			PALETTE.gold,
			true
		)
		makeCrate(m, "SlotCrate", cf * CFrame.new(3.4, PORTAL_BASE_H + 0.6, 1.8), 1.2)
		makeCrystalCluster(
			m,
			"SlotCrystal",
			(cf * CFrame.new(-3.2, PORTAL_BASE_H, 2.0)).Position,
			0.6,
			PALETTE.crystalLilac,
			false
		)
	end
	task.wait()

	-- Rich nautical wharf props & evenly spaced tall lanterns (7.4 studs) + high bunting (~9.8 studs).
	makeCrate(m, "WharfCrate", CY(13, Y + 0.65, 61.0, 0), 1.3)
	makeCrate(m, "WharfCrate", CY(14.5, Y + 0.6, 61.2, 6), 1.2)
	makeCrate(m, "WharfCrate", CY(13.6, Y + 1.85, 61.0, -4), 1.1)
	makeBarrel(m, "WharfBarrel", V(12.6, Y, 43), 2.0)
	makeBarrel(m, "WharfBarrel", V(13.2, Y, 45.4), 1.8)
	makeBarrel(m, "WharfBarrel", V(63.2, Y, 36.2), 1.9)
	makeCrate(m, "WharfCrate", CY(63.0, Y + 0.65, 38.6, 0), 1.3)
	makeCrate(m, "WharfCrate", CY(25.5, Y + 0.65, 35.4, 4), 1.3)
	makeBarrel(m, "WharfBarrel", V(27.4, Y, 35.4), 1.8)
	makeBarrel(m, "WharfBarrel", V(48.0, Y, 35.4), 1.8)
	makeCrate(m, "WharfCrate", CY(50.0, Y + 0.6, 35.4, -3), 1.2)
	for idx, p in
		{
			{ 10.4, 41.0 },
			{ 10.4, 53.5 },
			{ 65.6, 37.0 },
			{ 65.6, 56.5 },
			{ 26, 63.6 },
			{ 40, 63.6 },
			{ 54, 63.6 },
		}
	do
		makeLantern(m, "WharfLantern", V(p[1], Y + 0.75, p[2]), 7.2, idx % 2 == 1)
	end
	for _, p in { { 24, 33.4 }, { 34, 33.4 }, { 44, 33.4 }, { 54, 33.4 } } do
		makeCylinderY(
			m,
			"Bollard",
			C(p[1], Y + 1.0, p[2]),
			1.2,
			1.15,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeCylinderY(
			m,
			"BollardCap",
			C(p[1], Y + 1.65, p[2]),
			0.28,
			1.4,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
	end
	makeNet(m, "CurbNet", V(25, Y + 1.1, 33.0), V(33, Y + 1.1, 33.0), 2.0)
	makeCrystalCluster(
		m,
		"WharfCrystal",
		V(64.0, Y, 61.8),
		1.2,
		PALETTE.crystalCyan,
		true,
		PALETTE.crystalPink
	)
	makeCrystalCluster(m, "WharfCrystal", V(11.8, Y, 62.2), 1.0, PALETTE.crystalLilac, true)
	makeBunting(m, "WharfBunting", V(26, Y + 9.2, 63.6), V(40, Y + 9.2, 63.6), 1.0)
	makeBunting(m, "WharfBunting", V(40, Y + 9.2, 63.6), V(54, Y + 9.2, 63.6), 1.0)
	-- Anchor decoration.
	do
		local a = V(62.2, Y, 61.2)
		makeTube(
			m,
			"Anchor",
			a + Vector3.new(0, 0.4, 0),
			a + Vector3.new(0, 4.2, 0),
			0.42,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Anchor",
			a + Vector3.new(-1.2, 3.4, 0),
			a + Vector3.new(1.2, 3.4, 0),
			0.36,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Anchor",
			a + Vector3.new(-1.7, 1.5, 0),
			a + Vector3.new(0, 0.4, 0),
			0.42,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeTube(
			m,
			"Anchor",
			a + Vector3.new(1.7, 1.5, 0),
			a + Vector3.new(0, 0.4, 0),
			0.42,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeNeonRing(
			m,
			"AnchorRing",
			CFrame.new(a + Vector3.new(0, 4.7, 0)) * CFrame.Angles(math.pi / 2, 0, 0),
			0.48,
			0.24,
			8,
			PALETTE.metal,
			0,
			Enum.Material.Metal
		)
	end

	-- Wide smooth curved boardwalk (width 7.4, gentle <3 deg grade, zero steps/lips!) linking Pier south to Wharf east.
	local pts = {
		Vector3.new(63.0, PIER_Y, 12.2),
		Vector3.new(63.5, lerp(PIER_Y, WHARF_Y, 0.14), 17.6),
		Vector3.new(67.0, lerp(PIER_Y, WHARF_Y, 0.32), 23.4),
		Vector3.new(69.4, lerp(PIER_Y, WHARF_Y, 0.50), 30.0),
		Vector3.new(71.2, lerp(PIER_Y, WHARF_Y, 0.68), 37.6),
		Vector3.new(69.6, lerp(PIER_Y, WHARF_Y, 0.86), 44.8),
		Vector3.new(64.6, WHARF_Y, 45.0),
	}
	local w = 7.4
	for i = 1, #pts - 1 do
		local a = O + pts[i]
		local b = O + pts[i + 1]
		local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local len = flat.Magnitude
		local mid = (a + b) / 2
		local cf = CFrame.lookAt(mid, mid + flat.Unit)
			* CFrame.Angles(math.atan2(b.Y - a.Y, len), 0, 0)
		makePlankDeck(m, "Boardwalk", cf, w, len + 0.6, 0.85, PALETTE.wood)
		if i > 1 then
			makeCylinderY(
				m,
				"BoardwalkJoint",
				CFrame.new(a - Vector3.new(0, 0.42, 0)),
				0.8,
				w,
				PALETTE.woodDark,
				Enum.Material.Wood,
				false
			)
		end
		makeCylinderY(
			m,
			"BoardwalkPiling",
			CFrame.new(mid + Vector3.new(0, -5.2, 0)),
			10.0,
			0.95,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
	end
	-- Taller rails (3.2 studs) on outer and inner sides, skipping the display pads.
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
				local top = base + Vector3.new(0, 2.8, 0)
				makeCylinderY(
					m,
					"RailPost",
					CFrame.new(base + Vector3.new(0, 0.9, 0)),
					4.0,
					0.58,
					PALETTE.woodDark,
					Enum.Material.Wood,
					true
				)
				makeCylinderY(
					m,
					"RailKnot",
					CFrame.new(top - Vector3.new(0, 0.45, 0)),
					0.36,
					0.72,
					PALETTE.rope,
					Enum.Material.Fabric,
					false
				)
				local p = prevTop
				if p then
					makeRope(
						m,
						"BoardwalkRail",
						p - Vector3.new(0, 0.45, 0),
						top - Vector3.new(0, 0.45, 0),
						0.5,
						0.25
					)
				end
				prevTop = top
				if i == 4 then
					makeLanternBody(
						m,
						"BoardwalkLantern",
						top + Vector3.new(0, 1.05, 0),
						0.9,
						outer
					)
				end
			end
		end
	end
	-- Crystal display pads on the outer side (concept).
	for _, i in { 3, 5 } do
		local off = sideOffset(i) * -1 * (w / 2 + 2.1)
		local c = O + pts[i] + off
		makeCylinderY(
			m,
			"DisplayPad",
			CFrame.new(c - Vector3.new(0, 0.4, 0)),
			0.8,
			5.6,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makeCylinderY(
			m,
			"DisplayPadTop",
			CFrame.new(c + Vector3.new(0, 0.03, 0)),
			0.06,
			5.2,
			PALETTE.woodLight,
			Enum.Material.Wood,
			false
		)
		makeCylinderY(
			m,
			"DisplayStone",
			CFrame.new(c + Vector3.new(0, 0.35, 0)),
			0.6,
			3.3,
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		makeCrystalCluster(
			m,
			"DisplayCrystal",
			c + Vector3.new(0, 0.65, 0),
			0.95,
			if i == 3 then PALETTE.white else PALETTE.crystalCyan,
			true
		)
		makeBuoy(
			m,
			"PadBuoy",
			faceTo(c + off.Unit * 2.9 + Vector3.new(0, -0.2, 0), c + off.Unit * 6),
			0.78
		)
	end
	-- High bunting poles (~10.2 studs) along the curved boardwalk.
	makeBunting(
		m,
		"BoardwalkBunting",
		O + pts[2] + sideOffset(2) * -3.35 + Vector3.new(0, 9.8, 0),
		O + pts[4] + sideOffset(4) * -3.35 + Vector3.new(0, 9.8, 0),
		1.2
	)
	makeCylinderY(
		m,
		"BuntingPole",
		CFrame.new(O + pts[2] + sideOffset(2) * -3.35 + Vector3.new(0, 5.1, 0)),
		10.2,
		0.45,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
	makeCylinderY(
		m,
		"BuntingPole",
		CFrame.new(O + pts[4] + sideOffset(4) * -3.35 + Vector3.new(0, 5.1, 0)),
		10.2,
		0.45,
		PALETTE.woodDark,
		Enum.Material.Wood,
		false
	)
end

---------------------------------------------------------------------------------------
-- Region: Training Sanctuary (gate + rune stairs + plateau with 4 portals)
---------------------------------------------------------------------------------------

-- Giant pink blossom tree: gnarled twisted trunk, thick spreading branches, 5 multi-layered blossom clouds (60+ puffs in 4 shades of pink/lilac), 5-petal flowers, falling petals (ref-2/ref-4).
local function makeFlowerTree(parent: Instance, name: string, base: Vector3, scale: number)
	local s = scale
	-- Twisted, gnarled trunk rising proudly above the sanctuary cliff.
	local pts = {
		base - Vector3.new(0, 1.2, 0),
		base + Vector3.new(1.1, 2.8, 0.5) * s,
		base + Vector3.new(-0.5, 5.4, 1.2) * s,
		base + Vector3.new(0.9, 8.0, 0.3) * s,
		base + Vector3.new(0.2, 10.2, -0.4) * s,
	}
	for i = 1, #pts - 1 do
		local d = lerp(3.4, 1.85, i / (#pts - 1)) * s
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
		makeBall(parent, name .. "Knot", pts[i + 1], d * 1.06, PALETTE.barkDark, Enum.Material.Wood)
	end
	-- Thick surface roots gripping the rocky cliff.
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + rnd(-0.15, 0.15)
		local mid = base + Vector3.new(math.cos(a) * 1.8, 0.6, math.sin(a) * 1.8) * s
		local tip = base + Vector3.new(math.cos(a) * 3.6, -0.8, math.sin(a) * 3.6) * s
		makeTube(
			parent,
			name .. "Root",
			base + Vector3.new(0, 1.4, 0) * s,
			mid,
			1.15 * s,
			PALETTE.barkDark,
			Enum.Material.Wood,
			false
		)
		makeTube(
			parent,
			name .. "RootTip",
			mid,
			tip,
			0.72 * s,
			PALETTE.barkDark,
			Enum.Material.Wood,
			false
		)
	end
	local top = pts[#pts]
	-- 5 major spreading boughs leading into 5 distinct organic blossom clouds.
	local cloudCenters: { { pos: Vector3, rad: number, count: number } } = {
		{ pos = top + Vector3.new(0, 5.6, 0) * s, rad = 4.6 * s, count = 14 },
		{ pos = top + Vector3.new(-5.8, 2.4, 2.2) * s, rad = 4.2 * s, count = 12 },
		{ pos = top + Vector3.new(5.4, 2.8, 2.6) * s, rad = 4.1 * s, count = 12 },
		{ pos = top + Vector3.new(-3.8, 3.2, -4.8) * s, rad = 4.0 * s, count = 11 },
		{ pos = top + Vector3.new(4.4, 2.2, -4.2) * s, rad = 3.9 * s, count = 11 },
	}
	for i = 2, #cloudCenters do
		local c = cloudCenters[i].pos
		local mid = top:Lerp(c, 0.55) - Vector3.new(0, 0.6 * s, 0)
		makeTube(
			parent,
			name .. "Branch",
			top - Vector3.new(0, 1.2 * s, 0),
			mid,
			1.25 * s,
			PALETTE.bark,
			Enum.Material.Wood,
			false
		)
		makeTube(
			parent,
			name .. "SubBranch",
			mid,
			c - Vector3.new(0, 0.8 * s, 0),
			0.78 * s,
			PALETTE.barkDark,
			Enum.Material.Wood,
			false
		)
	end
	-- Multi-tone foliage clusters (many smaller overlapping blossom puffs instead of giant smooth balloons).
	local blossomCols = {
		Color3.fromRGB(238, 102, 168), -- deep sakura rose
		PALETTE.pink,
		PALETTE.pinkLight,
		Color3.fromRGB(244, 168, 224), -- soft pink-lilac
		Color3.fromRGB(255, 206, 228), -- bright blush highlight
	}
	for ci, cl in cloudCenters do
		for k = 1, cl.count do
			local theta = (k / cl.count) * math.pi * 2 + ci * 1.1 + rnd(-0.25, 0.25)
			local dist = cl.rad * rnd(0.25, 1.0)
			local lift = lerp(0.5, -0.35, dist / cl.rad) * cl.rad * 0.55 + rnd(-0.5, 0.7) * s
			local p = cl.pos + Vector3.new(math.cos(theta) * dist, lift, math.sin(theta) * dist)
			local sz = rnd(2.2, 3.6) * s
			-- Deeper rose underneath, brighter blush on upper outer puffs.
			local colIdx = if lift < -0.2 * s
				then 1
				elseif lift > 0.6 * s then rndInt(3, 5)
				else rndInt(2, 4)
			makeEllipsoid(
				parent,
				name .. "BlossomPuff",
				CFrame.new(p) * CFrame.Angles(rnd(-0.2, 0.2), theta, rnd(-0.2, 0.2)),
				Vector3.new(sz * rnd(0.95, 1.25), sz * rnd(0.68, 0.9), sz * rnd(0.95, 1.2)),
				vary(blossomCols[colIdx], 0.03),
				Enum.Material.SmoothPlastic
			)
		end
	end
	-- Sculpted 5-petal sakura flowers dotting the outer canopy (ref-5).
	for i = 1, 26 do
		local cl = cloudCenters[(i - 1) % #cloudCenters + 1]
		local a = rnd(0, math.pi * 2)
		local r = cl.rad * rnd(0.65, 1.15)
		local e = cl.pos + Vector3.new(math.cos(a) * r, rnd(-0.2, 1.6) * s, math.sin(a) * r)
		local fs = rnd(0.55, 0.92) * s
		local fcf = CFrame.lookAt(e, e + Vector3.new(math.cos(a), 0.35, math.sin(a)))
		for k = 0, 4 do
			local pa = k / 5 * math.pi * 2
			local ppos = (fcf * CFrame.new(math.cos(pa) * fs, math.sin(pa) * fs, 0)).Position
			makeEllipsoid(
				parent,
				name .. "Petal",
				CFrame.new(ppos) * CFrame.Angles(0, a, pa),
				Vector3.new(fs * 1.15, fs * 0.9, fs * 0.45),
				if i % 3 == 0 then PALETTE.white else PALETTE.pinkLight,
				Enum.Material.SmoothPlastic
			)
		end
		makeBall(
			parent,
			name .. "PetalCenter",
			e,
			fs * 0.72,
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
	end
	-- Gentle drifting sakura petals + scattered fallen petals on the ground.
	local emitterPart = makePart(
		parent,
		name .. "PetalEmitter",
		CFrame.new(top + Vector3.new(0, 2.5 * s, 0)),
		Vector3.new(18, 1, 18) * s,
		PALETTE.pink,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARKLE_TEXTURE
	e.Color = ColorSequence.new(PALETTE.pink, PALETTE.pinkLight)
	e.LightEmission = 0.15
	e.Rate = 9
	e.Lifetime = NumberRange.new(4.5, 6.5)
	e.Speed = NumberRange.new(0.5, 1.2)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.SpreadAngle = Vector2.new(65, 65)
	e.Acceleration = Vector3.new(0.7, -0.9, 0.35)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.Size = NumberSequence.new(0.4, 0.28)
	e.Parent = emitterPart
	stats.emitters += 1
	for _ = 1, 34 do
		local a = rnd(0, math.pi * 2)
		local r = rnd(2.2, 10.5) * s
		makePart(
			parent,
			name .. "FallenPetal",
			CFrame.new(base + Vector3.new(math.cos(a) * r, 0.04, math.sin(a) * r))
				* CFrame.Angles(0, rnd(0, 6.28), 0),
			Vector3.new(0.55, 0.05, 0.36),
			vary(PALETTE.pink, 0.06),
			Enum.Material.SmoothPlastic,
			false
		)
	end
end

local function buildSanctuary(root: Instance, contract: Instance)
	local m = makeModel(root, "TrainingSanctuary")
	local Y = PLAZA_Y
	local steps = 21
	local rise = (SANCT_Y - PLAZA_Y - 0.05) / steps

	-- Bottom landing X -35..-29, Z -28..-16 (overlaps plaza west edge smoothly by 1 stud, zero NavMesh gap!).
	makePart(
		m,
		"GateLanding",
		C(-32.0, Y - 2.25, -22),
		Vector3.new(6.0, 4.5, 12),
		PALETTE.stoneMid,
		Enum.Material.Slate,
		true
	)
	makePart(
		m,
		"GateLandingInlay",
		C(-32.5, Y + 0.02, -22),
		Vector3.new(3.8, 0.06, 9.6),
		PALETTE.slateInlay,
		Enum.Material.Slate,
		false
	)
	for k = 0, 2 do
		makeRune(
			m,
			"LandingRune",
			CFrame.lookAt(V(-32.5, Y + 0.07, -25.4 + k * 3.4), V(-40, Y + 0.07, -25.4 + k * 3.4)),
			0.95,
			PALETTE.cyan
		)
	end

	-- Wide warm-stone stairs climbing west (X -35 -> -56), dark slate runner + glowing cyan runes on every step (ref-1).
	makeStairs(
		m,
		"SanctuaryStairs",
		V(-35, Y, -22),
		Vector3.new(-1, 0, 0),
		10.6,
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
		makePart(
			m,
			"StepSlateStrip",
			C(x, top + 0.015, -22),
			Vector3.new(0.92, 0.03, 2.5),
			PALETTE.slateInlay,
			Enum.Material.Slate,
			false
		)
		makeRune(
			m,
			"StepRune",
			CFrame.lookAt(V(x, top + 0.04, -22), V(x - 5, top + 0.04, -22)),
			0.66,
			PALETTE.cyan
		)
		for _, z in { -27.9, -16.1 } do
			local wallTop = top + 1.15
			makePart(
				m,
				"StairWall",
				C(x, (wallTop + Y - 4.5) / 2, z),
				Vector3.new(1.02, wallTop - (Y - 4.5), 1.3),
				vary(PALETTE.stoneMid, 0.02),
				Enum.Material.Slate,
				true
			)
			makePart(
				m,
				"StairWallCap",
				C(x, wallTop + 0.09, z),
				Vector3.new(1.06, 0.18, 1.55),
				PALETTE.stoneWarm,
				Enum.Material.Slate,
				false
			)
			if i == 5 or i == 12 or i == 19 then
				makeStoneLantern(m, "StairLantern", V(x, wallTop + 0.18, z), true)
			elseif (i == 8 and z < -20) or (i == 15 and z > -20) then
				makeCrystalCluster(
					m,
					"StairCrystal",
					V(x, wallTop + 0.18, z),
					0.72,
					if z < -20 then PALETTE.crystalCyan else PALETTE.crystalLilac,
					true
				)
			end
		end
	end
	-- Upper landing connecting smoothly to the spacious Sanctuary plateau (center -74, -34, radius 22).
	makePart(
		m,
		"UpperLanding",
		C(-58.5, SANCT_Y - 0.05 - 2.5, -23.5),
		Vector3.new(8.5, 5, 13),
		PALETTE.stone,
		Enum.Material.Slate,
		true
	)
	task.wait()

	-- Tall monumental Gate "SANTUÁRIO DO TREINO" over the bottom landing (>= 10 studs clear headroom!).
	for _, z in { -28.6, -15.4 } do
		local base = V(-33.2, Y - 2.5, z)
		local y = 0
		for i, bh in { 5.0, 2.8, 2.8, 2.8, 2.4 } do
			local w = if i % 2 == 0 then 2.5 else 2.85
			makePart(
				m,
				"GatePillar",
				CFrame.new(base + Vector3.new(0, y + bh / 2, 0)),
				Vector3.new(w, bh - 0.12, w),
				vary(PALETTE.stone, 0.03),
				Enum.Material.Slate,
				true
			)
			y += bh
		end
		makeCylinderY(
			m,
			"GateLog",
			CFrame.new(base + Vector3.new(-1.8, 8.2, 0)),
			16.4,
			1.45,
			PALETTE.bark,
			Enum.Material.Wood,
			true
		)
		makeCrystalCluster(
			m,
			"GateCrystal",
			V(-33.2, Y + 14.0, if z < -22 then -30.5 else -13.5),
			0.9,
			PALETTE.crystalCyan,
			true,
			PALETTE.crystalPink
		)
		local lp = V(-31.6, Y + 9.2, z)
		makeTube(
			m,
			"GateHook",
			V(-32.0, Y + 11.2, z),
			lp + Vector3.new(0, 1.2, 0),
			0.16,
			PALETTE.metal,
			Enum.Material.Metal,
			false
		)
		makeLanternBody(m, "GateLantern", lp, 1.1, true)
		makeStoneLantern(m, "GateTorch", V(-30.9, Y, if z < -22 then -29.0 else -15.0), true)
	end
	makeTube(
		m,
		"GateBeam",
		V(-33.2, Y + 14.0, -31.8),
		V(-33.2, Y + 14.0, -12.2),
		1.9,
		PALETTE.woodWarm,
		Enum.Material.Wood,
		false
	)
	-- Mount SanctuarySign ABOVE the GateBeam & GatePillars (Y + 16.8, zero pillar blocking text from any angle!).
	for _, sz in { -26.2, -17.8 } do
		makeCylinderY(
			m,
			"SanctuarySignMount",
			C(-32.8, Y + 14.9, sz),
			1.4,
			0.4,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
	end
	local signCf = faceTo(V(-32.8, Y + 17.0, -22), V(0, Y + 17.0, -22))
	makeSign(
		m,
		"SanctuarySign",
		signCf,
		13.2,
		3.8,
		"SANTUÁRIO DO TREINO",
		"4 ilhas de treino",
		PALETTE.signWood,
		PALETTE.signText,
		PALETTE.goldLight,
		PALETTE.woodDark,
		true
	)
	-- Dumbbell and golden crystal emblems cleanly flanking the sign frame outside the text area.
	do
		local l = signCf * CFrame.new(-7.4, 0, -0.1)
		makeTube(
			m,
			"Dumbbell",
			(l * CFrame.new(-0.55, 0, 0)).Position,
			(l * CFrame.new(0.55, 0, 0)).Position,
			0.22,
			PALETTE.woodDark,
			Enum.Material.Metal,
			false
		)
		for _, sx in { -0.62, 0.62 } do
			makeTube(
				m,
				"DumbbellWeight",
				(l * CFrame.new(sx - 0.14, 0, 0)).Position,
				(l * CFrame.new(sx + 0.14, 0, 0)).Position,
				0.72,
				PALETTE.woodDark,
				Enum.Material.Metal,
				false
			)
		end
		makeCrystal(
			m,
			"SignGem",
			signCf * CFrame.new(7.4, -0.7, -0.1),
			1.5,
			0.34,
			PALETTE.crystalGold,
			false
		)
	end
	-- Bunting hung cleanly BELOW the beam at Y + 12.2 (high above avatar heads, never near the sign above the beam!).
	makeBunting(m, "GateBunting", V(-32.4, Y + 12.4, -27.2), V(-32.4, Y + 12.4, -16.8), 0.7)
	task.wait()

	-- Spacious Plateau floor (circle r 22) solidly anchored deep into the mountain (18 studs deep + 12 stone buttresses: ZERO floating gap!).
	local center = V(SANCT_CX, SANCT_Y, SANCT_CZ)
	makeCylinderY(
		m,
		"SanctuaryFloor",
		CFrame.new(center - Vector3.new(0, 9.0, 0)),
		18.0,
		SANCT_R * 2,
		PALETTE.stoneJoint,
		Enum.Material.Slate,
		true
	)
	makeCylinderY(
		m,
		"SanctuaryFoundation",
		CFrame.new(center - Vector3.new(0, 12.5, 0)),
		15.0,
		SANCT_R * 2 + 1.2,
		PALETTE.stoneBlue,
		Enum.Material.Cobblestone,
		true
	)
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local bp = center
			+ Vector3.new(math.cos(a) * (SANCT_R - 0.2), -7.5, math.sin(a) * (SANCT_R - 0.2))
		makePart(
			m,
			"SanctuaryButtress",
			CFrame.lookAt(bp, center + Vector3.new(0, -7.5, 0)),
			Vector3.new(3.2, 15.0, 3.6),
			PALETTE.stoneDark,
			Enum.Material.Cobblestone,
			true
		)
	end
	-- Concentric warm-stone slab bands (dark joints between them).
	for i, r in { 20.4, 17.6, 14.8, 12.2 } do
		flatRing(
			m,
			"FloorBand",
			CFrame.new(center + Vector3.new(0, 0.01, 0)),
			r,
			2.5,
			0.1,
			48 - i * 4,
			if i % 2 == 0 then PALETTE.stoneWarm else PALETTE.stone,
			Enum.Material.Slate,
			false
		)
	end
	flatRing(
		m,
		"RimWall",
		CFrame.new(center + Vector3.new(0, 0.6, 0)),
		SANCT_R - 0.35,
		1.0,
		1.2,
		52,
		vary(PALETTE.stoneMid, 0.02),
		Enum.Material.Slate,
		true,
		12,
		56
	)
	flatRing(
		m,
		"RimCap",
		CFrame.new(center + Vector3.new(0, 1.28, 0)),
		SANCT_R - 0.35,
		1.25,
		0.18,
		52,
		PALETTE.stoneWarm,
		Enum.Material.Slate,
		false,
		12,
		56
	)
	makeCylinderY(
		m,
		"CircleInlay",
		CFrame.new(center + Vector3.new(0, 0.08, 0)),
		0.06,
		24,
		PALETTE.stoneLight,
		Enum.Material.Slate,
		false
	)
	flatRing(
		m,
		"CircleRing",
		CFrame.new(center + Vector3.new(0, 0.12, 0)),
		11.6,
		0.7,
		0.04,
		44,
		PALETTE.slateInlay,
		Enum.Material.Slate,
		false
	)
	flatRing(
		m,
		"CircleRing",
		CFrame.new(center + Vector3.new(0, 0.12, 0)),
		9.4,
		0.45,
		0.04,
		38,
		PALETTE.stoneMid,
		Enum.Material.Slate,
		false
	)
	local runeSpin = makeModel(m, "SanctuaryRuneRingSpin")
	local rsPivot = makePart(
		runeSpin,
		"Pivot",
		CFrame.new(center + Vector3.new(0, 0.15, 0)),
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	runeSpin.PrimaryPart = rsPivot
	runeSpin.WorldPivot = rsPivot.CFrame
	makeNeonRing(
		runeSpin,
		"RuneRing",
		CFrame.new(center + Vector3.new(0, 0.15, 0)),
		8.0,
		0.22,
		36,
		PALETTE.cyan,
		0.32
	)
	makeNeonRing(
		runeSpin,
		"RuneRing",
		CFrame.new(center + Vector3.new(0, 0.15, 0)),
		4.0,
		0.2,
		20,
		PALETTE.cyan,
		0.32
	)
	tagSpin(runeSpin, 8, "Y", 0)
	for k = 0, 15 do
		local a = k / 16 * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * 6.0, 0.14, math.sin(a) * 6.0)
		makeRune(
			m,
			"CircleRune",
			CFrame.lookAt(p, center + Vector3.new(0, 0.14, 0)),
			0.95,
			PALETTE.cyan
		)
	end
	for k = 0, 23 do
		local a = (k + 0.5) / 24 * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * 10.5, 0.14, math.sin(a) * 10.5)
		local dash = makePart(
			m,
			"CircleDash",
			CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))),
			Vector3.new(0.22, 0.05, 1.3),
			PALETTE.crystalLilac,
			Enum.Material.Neon,
			false,
			0.3
		)
		if k % 3 == 0 then
			tagPulse(dash, 0.15, 0.65, 2.0, "Transparency")
		end
	end
	-- Symmetrical vertical central crystal pedestal (seated -0.2 stud into floor, slow mystic rotation!).
	makeCylinderY(
		m,
		"CorePedestal",
		CFrame.new(center + Vector3.new(0, 0.6, 0)),
		1.6,
		3.8,
		PALETTE.stone,
		Enum.Material.Slate,
		true
	)
	makeCylinderY(
		m,
		"CorePedestalTrim",
		CFrame.new(center + Vector3.new(0, 1.44, 0)),
		0.14,
		4.1,
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false
	)
	local coreBase = center + Vector3.new(0, 1.45, 0)
	local coreSpin = makeModel(m, "CoreCrystalSpin")
	local corePivot = makePart(
		coreSpin,
		"Pivot",
		CFrame.new(coreBase + Vector3.new(0, 3.2, 0)),
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.crystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	coreSpin.PrimaryPart = corePivot
	coreSpin.WorldPivot = corePivot.CFrame
	makeCrystal(
		coreSpin,
		"CoreCrystalMain",
		CFrame.new(coreBase),
		6.4,
		0.96,
		PALETTE.crystalCyan,
		true
	)
	tagSpin(coreSpin, 12, "Y", 0)
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local sb = coreBase + dir * 0.9 - Vector3.new(0, 0.06, 0)
		makeCrystal(
			m,
			"CoreCrystalSide",
			CFrame.lookAt(sb, sb + dir) * CFrame.Angles(math.rad(-18), 0, 0),
			3.0,
			0.5,
			if k % 2 == 0 then PALETTE.crystalLilac else PALETTE.crystalPink,
			false
		)
	end
	local coreSpark = makePart(
		m,
		"CoreSparkles",
		CFrame.new(center + Vector3.new(0, 4.8, 0)),
		Vector3.new(4, 4, 4),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	addSparkles(coreSpark, PALETTE.crystalCyan, 8, 0.5, 1.4)
	task.wait()

	-- Four training portals evenly spaced in a balanced semicircle (42 deg apart, >= 8 studs clear gap, all facing center!).
	-- The Apprentice island is reached only through the lagoon gate (decision 2026-11-25),
	-- so the sanctuary keeps the three paid islands.
	local defs = {
		{
			ang = 194,
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
			ang = 236,
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
			ang = 278,
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
	for _, d in defs do
		local i = d.island
		local a = math.rad(d.ang)
		local pos = center + Vector3.new(math.cos(a) * 16.6, 0, math.sin(a) * 16.6)
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
			cf * CFrame.new(0, PORTAL_BASE_H + 18.2, 0),
			10.2,
			3.0,
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
			local sp = (cf * CFrame.new((k - (i + 1) / 2) * 0.95, PORTAL_BASE_H + 0.06, -4.85)).Position
			makePart(
				m,
				"ProgressStar",
				CFrame.new(sp) * CFrame.Angles(0, math.rad(45), 0),
				Vector3.new(0.55, 0.1, 0.55),
				PALETTE.gold,
				Enum.Material.Neon,
				false,
				0.05
			)
		end
	end
	for idx, ang in { 118, 173, 215, 257, 306 } do
		local a = math.rad(ang)
		makeStoneLantern(
			m,
			"CircleLantern",
			center + Vector3.new(math.cos(a) * 19.6, 0, math.sin(a) * 19.6),
			idx % 2 == 1
		)
	end
	for _, ang in { 66, 102, 314, 342 } do
		local a = math.rad(ang)
		makeCrystalCluster(
			m,
			"RimCrystal",
			center
				+ Vector3.new(math.cos(a) * (SANCT_R - 0.35), 1.36, math.sin(a) * (SANCT_R - 0.35)),
			0.8,
			if ang < 200 then PALETTE.crystalPink else PALETTE.crystalCyan,
			false
		)
	end
	-- Monumental giant pink blossom tree dominating the left silhouette (removed central obstructive bunting pole!).
	makeFlowerTree(m, "BlossomTree", V(-96, groundY(-96, -15), -15), 2.35)
end

---------------------------------------------------------------------------------------
-- Region: Lagoon gate (Apprentice portal facing the plaza, waterfall behind)
---------------------------------------------------------------------------------------

local function buildLagoonGate(root: Instance, contract: Instance)
	local m = makeModel(root, "LagoonGate")
	local Y = PLAZA_Y
	local PZ = LAGOON_PORTAL_POS.Z

	-- 1. Welcoming Arrival Plaza seamlessly flush with the central plaza west edge (X -34.5..-29.0, Z -10.5..4.5, Y 10.3).
	makePart(
		m,
		"ArrivalPlazaFloor",
		C(-31.75, Y - 2.65, PZ),
		Vector3.new(5.5, 5.3, 15.0),
		PALETTE.stoneJoint,
		Enum.Material.Slate,
		true
	)
	-- Purely visual wood inlay flush on top of the solid ArrivalPlazaFloor (CanCollide = false avoids coplanar NavMesh seams!).
	makePart(
		m,
		"ArrivalWoodInlay",
		C(-31.5, Y + 0.02, PZ),
		Vector3.new(4.6, 0.06, 8.6),
		PALETTE.woodWarm,
		Enum.Material.Wood,
		false
	)
	for _, z in { PZ - 6.2, PZ + 6.2 } do
		makePart(
			m,
			"ArrivalFlowerBed",
			C(-32.2, Y + 0.35, z),
			Vector3.new(3.6, 1.1, 2.2),
			PALETTE.stoneMid,
			Enum.Material.Slate,
			true
		)
		makePart(
			m,
			"ArrivalBedSoil",
			C(-32.2, Y + 0.88, z),
			Vector3.new(3.0, 0.16, 1.6),
			PALETTE.leafDark,
			Enum.Material.Grass,
			false
		)
		makeFlower(m, "ArrivalFlower", V(-33.0, Y + 0.92, z), PALETTE.pink)
		makeFlower(m, "ArrivalFlower", V(-31.4, Y + 0.92, z), PALETTE.goldLight)
		makeCrystalCluster(
			m,
			"ArrivalCrystal",
			V(-32.2, Y + 0.92, z),
			0.48,
			PALETTE.crystalCyan,
			false
		)
	end
	-- Two cleanly aligned benches and ONLY 2 well-spaced lanterns (>= 11 studs apart) on the arrival plaza.
	makeBench(m, "LagoonArrivalBenchN", CY(-29.2, Y, PZ - 7.4, 180))
	makeBench(m, "LagoonArrivalBenchS", CY(-29.2, Y, PZ + 7.4, 0))
	makeLantern(m, "LagoonArrivalLanternN", V(-33.5, Y, PZ - 5.2), 7.4, true)
	makeLantern(m, "LagoonArrivalLanternS", V(-33.5, Y, PZ + 5.2), 7.4, true)
	-- ONE single, large, crisp directional sign at the entrance of the Apprentice path (zero overlap!).
	makeStandingArrowSign(
		m,
		"AprendizArrow",
		V(-28.6, Y, PZ + 5.6),
		Vector3.new(-1, 0, 0),
		8.2,
		2.5,
		"ILHA DO APRENDIZ",
		"Grátis · Comece aqui!",
		5.4
	)

	-- 2. Wide, straight, flat-grade wooden bridge (width 8.4, zero jumps!) directly aligned with the Apprentice Portal.
	do
		local bx0, bx1 = -33.2, -43.0
		local bw = 8.4
		makePlankDeck(
			m,
			"ApprenticeBridgeDeck",
			C((bx0 + bx1) / 2, Y, PZ),
			math.abs(bx1 - bx0) + 1.4,
			bw,
			1.2,
			PALETTE.woodWarm
		)
		for _, sd in { -1, 1 } do
			local rz = PZ + sd * (bw / 2 + 0.25)
			makePart(
				m,
				"ApprenticeBridgeBeam",
				C((bx0 + bx1) / 2, Y - 0.55, rz),
				Vector3.new(math.abs(bx1 - bx0) + 1.0, 0.85, 0.55),
				PALETTE.woodDark,
				Enum.Material.Wood,
				false
			)
			local postXs = { -34.2, -37.0, -39.8, -42.4 }
			local prevTop: Vector3? = nil
			for i, px in postXs do
				makeCylinderY(
					m,
					"ApprenticeBridgePiling",
					C(px, (Y - 0.3 + 2.5) / 2, rz),
					Y - 0.3 - 2.5,
					0.85,
					PALETTE.woodDark,
					Enum.Material.Wood,
					true
				)
				local isEnd = i == #postXs
				local topY = if isEnd then Y + 3.2 else Y + 2.7
				if isEnd then
					makePart(
						m,
						"BridgeStonePost",
						C(px, Y + 1.4, rz),
						Vector3.new(1.5, 3.8, 1.5),
						PALETTE.stoneGray,
						Enum.Material.Slate,
						true
					)
					makePart(
						m,
						"BridgeStoneCap",
						C(px, Y + 3.45, rz),
						Vector3.new(1.85, 0.34, 1.85),
						PALETTE.stoneGrayDark,
						Enum.Material.Slate,
						false
					)
					makeLanternBody(m, "BridgeEndLantern", V(px, Y + 4.5, rz), 0.98, sd == 1)
				else
					makeCylinderY(
						m,
						"BridgeRailPost",
						C(px, Y + 1.4, rz),
						3.4,
						0.54,
						PALETTE.woodDark,
						Enum.Material.Wood,
						true
					)
					makeCylinderY(
						m,
						"BridgeRailKnot",
						C(px, topY, rz),
						0.34,
						0.7,
						PALETTE.rope,
						Enum.Material.Fabric,
						false
					)
				end
				local top = V(px, topY, rz)
				if prevTop then
					makeRope(m, "ApprenticeBridgeRail", prevTop, top, 0.35, 0.25)
				end
				prevTop = top
			end
		end
	end

	-- 3. Grand stone Portal Platform with 3 wide front steps (rise 0.45 each, total +1.35) centered on the bridge axis!
	makePart(
		m,
		"PortalPlatformBase",
		C(-49.6, Y - 2.65, PZ),
		Vector3.new(14.0, 5.3, 15.2),
		PALETTE.stoneMid,
		Enum.Material.Slate,
		true
	)
	for _, p in
		{
			{ -55.6, PZ - 6.8 },
			{ -55.6, PZ + 6.8 },
			{ -43.6, PZ - 6.8 },
			{ -43.6, PZ + 6.8 },
			{ -49.6, PZ - 6.8 },
			{ -49.6, PZ + 6.8 },
		}
	do
		makeCylinderY(
			m,
			"PlatformPier",
			C(p[1], (Y - 2.0 + 2.0) / 2, p[2]),
			Y,
			1.4,
			PALETTE.stoneDark,
			Enum.Material.Cobblestone,
			true
		)
	end
	-- 3 wide welcoming stone steps ascending to the elevated Apprentice Portal dais (Y = PLAZA_Y + 1.35).
	local daisY = LAGOON_PORTAL_POS.Y
	makeStairs(
		m,
		"ApprenticePortalSteps",
		V(-42.6, Y, PZ),
		Vector3.new(-1, 0, 0),
		10.4,
		3,
		(daisY - Y) / 3,
		1.15,
		Y - 2.0,
		PALETTE.stone,
		Enum.Material.Slate,
		PALETTE.stoneWarm
	)
	makePart(
		m,
		"PortalDais",
		C(-51.2, (daisY + Y - 1.0) / 2, PZ),
		Vector3.new(10.6, daisY - (Y - 1.0), 14.4),
		PALETTE.stoneWarm,
		Enum.Material.Slate,
		true
	)
	-- Ground glow ring on the dais welcoming the player.
	local daisGlow = makeNeonRing
	daisGlow(m, "DaisGlowRing", C(-49.5, daisY + 0.06, PZ), 5.6, 0.2, 28, PALETTE.cyan, 0.35)
	-- Rope railings protecting north, south & west edges of the stone platform.
	local zn, zs = PZ - 7.3, PZ + 7.3
	local railPts = {
		{ V(-43.0, Y, zn), V(-46.5, daisY, zn), V(-51.5, daisY, zn), V(-56.2, daisY, zn) },
		{ V(-43.0, Y, zs), V(-46.5, daisY, zs), V(-51.5, daisY, zs), V(-56.2, daisY, zs) },
		{
			V(-56.2, daisY, zn),
			V(-56.2, daisY, PZ - 2.5),
			V(-56.2, daisY, PZ + 2.5),
			V(-56.2, daisY, zs),
		},
	}
	for _, line in railPts do
		for i, p in line do
			makeCylinderY(
				m,
				"RailPost",
				CFrame.new(p + Vector3.new(0, 1.4, 0)),
				3.4,
				0.54,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			if i > 1 then
				makeRope(
					m,
					"DeckRail",
					line[i - 1] + Vector3.new(0, 2.65, 0),
					p + Vector3.new(0, 2.65, 0),
					0.35,
					0.24
				)
			end
		end
	end

	-- 4. Grand Apprentice Portal (height ~13.5, carved stoneArch, directly facing the plaza +X on the bridge centerline!).
	local pcf = faceTo(V(LAGOON_PORTAL_POS.X, daisY, PZ), V(0, daisY, PZ))
	local tcf =
		makePortal(m, "ApprenticePortal", pcf, "stoneArch", PALETTE.cyan, PALETTE.white, false)
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
		pcf * CFrame.new(0, PORTAL_BASE_H + 17.6, 0),
		11.2,
		3.2,
		"ILHA DO APRENDIZ",
		"Treino x1 · Grátis",
		PALETTE.signBg,
		PALETTE.signText,
		PALETTE.crystalCyan,
		PALETTE.gold,
		true
	)
	for _, z in { PZ + 6.2, PZ - 6.2 } do
		makeCrystalCluster(
			m,
			"DeckCrystal",
			V(-54.8, daisY, z),
			1.15,
			PALETTE.crystalCyan,
			true,
			PALETTE.crystalLilac
		)
	end
	makeFern(m, "DeckFern", V(-54.6, daisY, PZ + 3.4), 1.05)
	makeFern(m, "DeckFern", V(-54.6, daisY, PZ - 3.4), 1.05)
	task.wait()

	-- 5. Real multi-ribbon Waterfall RIGHT BESIDE the Apprentice Portal (~7 studs south-west, ZERO rock blocking it!).
	local fallXZ = Vector3.new(-55.2, 0, 7.6)
	local topY = 19.4
	local bottomY = LAGOON_WATER_Y + 0.05
	local facing = Vector3.new(0.84, 0, -0.54).Unit
	local sideVec = Vector3.new(-facing.Z, 0, facing.X)
	-- Sculpted mossy rock shoulders framing the waterfall lip (strictly behind/beside, NEVER blocking the front!).
	for _, sOff in { -3.6, 3.6 } do
		makeEllipsoid(
			m,
			"FallCliffRock",
			CFrame.new(
				O + Vector3.new(fallXZ.X, topY - 1.4, fallXZ.Z) + sideVec * sOff - facing * 2.2
			),
			Vector3.new(3.8, 4.8, 3.8),
			PALETTE.stoneBlue,
			Enum.Material.Slate
		)
		makeEllipsoid(
			m,
			"FallCliffMoss",
			CFrame.new(
				O + Vector3.new(fallXZ.X, topY + 0.8, fallXZ.Z) + sideVec * sOff - facing * 2.0
			),
			Vector3.new(3.4, 1.4, 3.4),
			PALETTE.leafDark,
			Enum.Material.Grass
		)
	end
	-- 5 overlapping thin translucent water ribbons projecting smoothly forward into the lagoon!
	local ribbons = {
		{ off = 0, w = 4.2, bulge = 2.0, col = PALETTE.water, tr = 0.24 },
		{ off = -1.6, w = 1.9, bulge = 1.7, col = PALETTE.crystalCyan, tr = 0.34 },
		{ off = 1.6, w = 1.9, bulge = 1.7, col = PALETTE.crystalCyan, tr = 0.34 },
		{ off = -2.7, w = 1.1, bulge = 1.4, col = PALETTE.foam, tr = 0.42 },
		{ off = 2.7, w = 1.1, bulge = 1.4, col = PALETTE.foam, tr = 0.42 },
	}
	local segs = 9
	for _, rb in ribbons do
		for k = 0, segs - 1 do
			local t0 = k / segs
			local t1 = (k + 1) / segs
			local y0 = lerp(topY, bottomY, t0)
			local y1 = lerp(topY, bottomY, t1)
			local out0 = rb.bulge * math.sqrt(t0 + 0.05)
			local out1 = rb.bulge * math.sqrt(t1 + 0.05)
			local baseP = O + Vector3.new(fallXZ.X, 0, fallXZ.Z) + sideVec * rb.off
			local p0 = baseP + Vector3.new(0, y0, 0) + facing * out0
			local p1 = baseP + Vector3.new(0, y1, 0) + facing * out1
			local mid = (p0 + p1) / 2
			local cf = CFrame.lookAt(mid, mid + facing)
				* CFrame.Angles(math.atan2(out1 - out0, y0 - y1), 0, 0)
			makePart(
				m,
				"WaterfallRibbon",
				cf,
				Vector3.new(rb.w * (1 - t0 * 0.06), (p1 - p0).Magnitude + 0.2, 0.28),
				rb.col,
				Enum.Material.SmoothPlastic,
				false,
				rb.tr
			)
			if rb.off == 0 then
				for sx = -1.5, 1.5, 0.75 do
					makePart(
						m,
						"WaterStreak",
						cf * CFrame.new(sx + rnd(-0.1, 0.1), 0, -0.2),
						Vector3.new(0.18, (p1 - p0).Magnitude + 0.14, 0.06),
						PALETTE.foam,
						Enum.Material.Neon,
						false,
						0.4
					)
				end
			end
		end
	end
	-- Native animated flowing Beam down the waterfall face (self-animates via TextureSpeed, zero Script!).
	do
		local topAnchor = makePart(
			m,
			"WaterfallBeamTop",
			CFrame.new(O + Vector3.new(fallXZ.X, topY - 0.2, fallXZ.Z) + facing * 0.6),
			Vector3.new(0.2, 0.2, 0.2),
			PALETTE.foam,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		local botAnchor = makePart(
			m,
			"WaterfallBeamBot",
			CFrame.new(O + Vector3.new(fallXZ.X, bottomY + 0.2, fallXZ.Z) + facing * 2.2),
			Vector3.new(0.2, 0.2, 0.2),
			PALETTE.foam,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		local att0 = Instance.new("Attachment")
		att0.Parent = topAnchor
		local att1 = Instance.new("Attachment")
		att1.Parent = botAnchor
		local beam = Instance.new("Beam")
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.Width0 = 3.8
		beam.Width1 = 4.6
		beam.Color = ColorSequence.new(PALETTE.foam, PALETTE.crystalCyan)
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(1, 0.55),
		})
		beam.LightEmission = 0.35
		beam.Texture = SPARKLE_TEXTURE
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 3.5
		beam.TextureSpeed = 2.4
		beam.FaceCamera = false
		beam.Parent = topAnchor
	end
	local lip = O + Vector3.new(fallXZ.X, topY, fallXZ.Z) - facing * 1.4
	makePart(
		m,
		"WaterfallStream",
		CFrame.lookAt(lip, lip + facing) * CFrame.new(0, 0.08, 0),
		Vector3.new(4.8, 0.34, 4.2),
		PALETTE.water,
		Enum.Material.SmoothPlastic,
		false,
		0.25
	)
	local foamCenter = O + Vector3.new(fallXZ.X, bottomY, fallXZ.Z) + facing * 2.3
	for k = 1, 12 do
		local off = Vector3.new(rnd(-2.8, 2.8), rnd(-0.1, 0.25), rnd(-1.8, 1.8))
		local fm = makeEllipsoid(
			m,
			"Foam",
			CFrame.new(foamCenter + off),
			Vector3.new(rnd(1.8, 3.0), rnd(0.8, 1.3), rnd(1.8, 3.0)),
			PALETTE.foam,
			Enum.Material.SmoothPlastic,
			0.12
		)
		if k <= 3 then
			tagBob(fm, 0.14, 2.2, k * 1.1)
		end
	end
	-- Soft translucent rainbow arc hovering in the waterfall mist!
	do
		local rbCols = {
			Color3.fromRGB(255, 130, 140),
			Color3.fromRGB(255, 210, 120),
			Color3.fromRGB(130, 238, 170),
			Color3.fromRGB(130, 205, 255),
			Color3.fromRGB(205, 150, 255),
		}
		local rbCenter = foamCenter + facing * 2.4 + Vector3.new(0, 0.4, 0)
		local rbBasis = CFrame.lookAt(rbCenter, rbCenter + facing)
		for bi, col in rbCols do
			local r = 4.6 + (bi - 1) * 0.26
			for s = 0, 9 do
				local a0 = math.rad(15 + s * 15)
				local a1 = math.rad(15 + (s + 1) * 15)
				local p0 = (rbBasis * CFrame.new(math.cos(a0) * r, math.sin(a0) * r, 0)).Position
				local p1 = (rbBasis * CFrame.new(math.cos(a1) * r, math.sin(a1) * r, 0)).Position
				local rbSeg =
					makeSegment(m, "WaterfallRainbow", p0, p1, 0.18, col, Enum.Material.Neon, false)
				rbSeg.Transparency = 0.72
			end
		end
	end
	local rippleModel = makeModel(m, "WaterfallRippleRing")
	local ripPivot = makePart(
		rippleModel,
		"Pivot",
		CFrame.new(foamCenter + Vector3.new(0, 0.08, 0)),
		Vector3.new(0.2, 0.2, 0.2),
		PALETTE.foam,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	rippleModel.PrimaryPart = ripPivot
	rippleModel.WorldPivot = ripPivot.CFrame
	makeNeonRing(
		rippleModel,
		"WaterfallRipple",
		CFrame.new(foamCenter + Vector3.new(0, 0.08, 0)),
		4.0,
		0.24,
		22,
		PALETTE.foam,
		0.38
	)
	tagSpin(rippleModel, 10, "Y", 0)
	local mistPart = makePart(
		m,
		"Mist",
		CFrame.new(foamCenter + Vector3.new(0, 0.8, 0)),
		Vector3.new(5.8, 0.6, 3.8),
		PALETTE.foam,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = SPARKLE_TEXTURE
	mist.Color = ColorSequence.new(PALETTE.foam)
	mist.LightEmission = 0.25
	mist.Rate = 20
	mist.Lifetime = NumberRange.new(1.3, 2.4)
	mist.Speed = NumberRange.new(1.6, 3.4)
	mist.SpreadAngle = Vector2.new(58, 58)
	mist.EmissionDirection = Enum.NormalId.Top
	mist.Acceleration = Vector3.new(0, -1.4, 0)
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 2.2),
	})
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	mist.Parent = mistPart
	stats.emitters += 1
	addLight(mistPart, PALETTE.crystalCyan, 12, 0.6)

	-- Lagoon fireflies / dragonflies drifting softly above the water.
	local fireflyBox = makePart(
		m,
		"LagoonFireflies",
		C(LAGOON_CX, LAGOON_WATER_Y + 2.4, LAGOON_CZ + 4.0),
		Vector3.new(18, 2.5, 14),
		PALETTE.goldLight,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	addSparkles(fireflyBox, PALETTE.goldLight, 6, 0.32, 0.7, 2.4)

	-- Lily pads (some bobbing gently!) and lotus flowers.
	local placed = 0
	local tries = 0
	while placed < 22 and tries < 320 do
		tries += 1
		local a = rnd(0, math.pi * 2)
		local r = rnd(3, 14.2)
		local x = LAGOON_CX + math.cos(a) * r
		local z = LAGOON_CZ + math.sin(a) * r
		local onDeck = inRect(x, z, -57.5, -42.0, PZ - 8.2, PZ + 8.2)
		local onBridge = inRect(x, z, -43.5, -28.5, PZ - 5.4, PZ + 5.4)
		local nearFall = dist2(x, z, fallXZ.X, fallXZ.Z) < 5.0
		local onPromenade = inRect(x, z, -45, -29, 12.5, 25.5)
		if not (onDeck or onBridge or nearFall or onPromenade) then
			local d = rnd(1.6, 2.8)
			local pad = makeCylinderY(
				m,
				"LilyPad",
				CY(x, LAGOON_WATER_Y + 0.04, z, rnd(0, 360)),
				0.08,
				d,
				vary(PALETTE.lily, 0.06),
				Enum.Material.SmoothPlastic,
				false
			)
			if placed % 4 == 0 then
				tagBob(pad, 0.08, 1.4, placed * 0.9)
			end
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
		local x = LAGOON_CX + math.cos(a) * 16.5
		local z = LAGOON_CZ + math.sin(a) * 16.5
		local eastSide = x > -31
		local deckSide = inRect(x, z, -58, -37, PZ - 9, PZ + 9)
		local promSide = inRect(x, z, -46, -29, 12, 26)
		if
			not eastSide
			and not deckSide
			and not promSide
			and dist2(x, z, fallXZ.X, fallXZ.Z) > 4.2
		then
			makeEllipsoid(
				m,
				"RimStone",
				CFrame.new(V(x, LAGOON_WATER_Y + 0.2, z)) * CFrame.Angles(0, a, 0),
				Vector3.new(rnd(1.8, 2.8), rnd(1.0, 1.6), rnd(1.6, 2.4)),
				vary(PALETTE.stoneBlue, 0.05),
				Enum.Material.Slate
			)
			local fx = LAGOON_CX + math.cos(a) * 18.8
			local fz = LAGOON_CZ + math.sin(a) * 18.8
			local g = groundY(fx, fz)
			if
				g > 7.5
				and g < 12.5
				and not inRect(fx, fz, -58, -29, -29, -15)
				and not inRect(fx, fz, -46, -29, 12, 26)
			then
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

local function makeToyFish(parent: Instance, cf: CFrame, color: Color3, idx: number)
	local body = makeEllipsoid(
		parent,
		"ToyFish",
		cf,
		Vector3.new(0.55, 0.72, 1.25),
		color,
		Enum.Material.SmoothPlastic
	)
	tagBob(body, 0.25, 1.6 + (idx % 4) * 0.25, idx * 0.8)
	local tail = makeWedge(
		parent,
		"ToyFishTail",
		cf * CFrame.new(0, 0, 0.78) * CFrame.Angles(0, math.pi, 0),
		Vector3.new(0.12, 0.62, 0.52),
		color,
		Enum.Material.SmoothPlastic,
		false
	)
	tagWave(tail, 0.16, 4.2, idx * 0.9)
	makeBall(
		parent,
		"ToyFishEye",
		(cf * CFrame.new(0.2, 0.12, -0.35)).Position,
		0.14,
		PALETTE.board,
		Enum.Material.SmoothPlastic
	)
end

local function makeJellyfish(parent: Instance, pos: Vector3, color: Color3, idx: number)
	local bell = makeEllipsoid(
		parent,
		"JellyBell",
		CFrame.new(pos),
		Vector3.new(1.05, 0.78, 1.05),
		color,
		Enum.Material.Neon,
		0.25
	)
	tagBob(bell, 0.45, 1.2 + idx * 0.2, idx * 1.4)
	tagPulse(bell, 0.18, 0.48, 2.0, "Transparency")
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		local t = makePart(
			parent,
			"JellyTentacle",
			CFrame.new(pos + Vector3.new(math.cos(a) * 0.28, -0.78, math.sin(a) * 0.28)),
			Vector3.new(0.12, 1.15, 0.12),
			color,
			Enum.Material.Neon,
			false,
			0.35
		)
		tagWave(t, 0.12, 3.0, idx + k * 0.7)
	end
end

local function buildAquarium(root: Instance)
	local m = makeModel(root, "Aquarium")
	local Y = PLAZA_Y
	local lunaY = PLAZA_Y - FRONT_STAIR_RISE * 18

	-- Wide 11-stud west promenade leaving the plaza's west flank (Z 13.5..24.5, well away from the Legendary Catch arch!)
	-- and turning smoothly south into the center of the Aquarium deck (X -44..-33, Z 24..37.5). Zero jumps, zero gaps!
	makePlankDeck(m, "AquariumPromenadeW", C(-36.75, Y, 19.0), 14.5, 11.0, 0.9, PALETTE.wood)
	makePlankDeck(m, "AquariumWalk", C(-38.5, Y, 30.75), 11.0, 14.0, 0.9, PALETTE.wood)
	makePlankDeck(m, "AquariumDeck", C(-39.0, Y, 47.5), 30.0, 21.0, 1.0, PALETTE.woodWarm)
	-- East landing connecting Aquarium deck to the Luna stairs (X -24.5..-16.7, Z 37.0..42.8; wide smooth transition!).
	makePlankDeck(m, "AquariumLunaLanding", C(-20.6, Y, 39.9), 7.8, 5.8, 0.9, PALETTE.woodWarm)
	-- Solid collidable stilts supporting promenade, deck, and east landing down to rock/seabed.
	for _, p in
		{
			{ -53.4, 37.6 },
			{ -53.4, 57.4 },
			{ -24.6, 57.4 },
			{ -39.0, 57.4 },
			{ -39.0, 37.6 },
			{ -53.4, 47.5 },
			{ -24.6, 47.5 },
			{ -43.6, 14.0 },
			{ -43.6, 24.0 },
			{ -43.6, 31.0 },
			{ -33.4, 24.2 },
			{ -33.4, 31.0 },
			{ -33.4, 14.0 },
			{ -17.2, 37.6 },
			{ -17.2, 42.8 },
		}
	do
		makeCylinderY(
			m,
			"Stilt",
			C(p[1], (Y - 0.5 - 6) / 2, p[2]),
			Y - 0.5 + 6,
			1.05,
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
	end

	-- Second access: gentle 18-step wooden staircase (rise 0.51, run 1.08 -> 25 deg smooth slope, width 6.6) linking Aquarium deck to Luna's dock!
	do
		local steps = 18
		local rise = (Y - lunaY) / steps
		local run = 1.08
		local zStart = 42.8
		local totalRun = steps * run
		-- Visual wooden steps (CanCollide = false; smooth continuous collision ramp below matches exact step plane for 0-jump walking!).
		for i = 1, steps do
			local top = Y - rise * i
			local cz = zStart + run * (i - 0.5)
			local hStep = top - -3.5
			makePart(
				m,
				"LunaAquariumStairsStep" .. i,
				C(-20.2, (top - 3.5) / 2, cz),
				Vector3.new(6.6, hStep, run + 0.04),
				if i % 2 == 0 then PALETTE.woodLight else PALETTE.woodWarm,
				Enum.Material.Wood,
				false
			)
		end
		-- Exact flush collidable ramp (0.00 stud lip at top and bottom!) starting cleanly at zStart = 42.8 (zero posts inside landing opening!).
		local rampA = V(-20.2, Y, zStart)
		local rampB = V(-20.2, lunaY, zStart + totalRun)
		local rampMid = (rampA + rampB) / 2
		local rampLen = (rampB - rampA).Magnitude
		local rampCf = CFrame.lookAt(rampMid, rampB) * CFrame.new(0, -0.35, 0)
		makePart(
			m,
			"LunaAquariumStairsRamp",
			rampCf,
			Vector3.new(6.6, 0.7, rampLen),
			PALETTE.woodWarm,
			Enum.Material.Wood,
			true,
			1
		)
		-- Double wood handrail + tall side guard on east flank (stops 1.8 studs above foot where ramp meets LunaWoodDock smoothly!).
		for _, sx in { -23.7, -16.7 } do
			local s0 = if sx < -20 then zStart + 0.5 else zStart
			local s1 = zStart + totalRun - 1.8
			local f0 = (s0 - zStart) / totalRun
			local f1 = (s1 - zStart) / totalRun
			local yStart = Y - f0 * (Y - lunaY)
			local yEnd = Y - f1 * (Y - lunaY)
			makeSegment(
				m,
				"AquaStairHandrail",
				V(sx, yStart + 2.8, s0),
				V(sx, yEnd + 2.8, s1),
				0.36,
				PALETTE.wood,
				Enum.Material.Wood,
				true
			)
			makeSegment(
				m,
				"AquaStairMidRail",
				V(sx, yStart + 1.5, s0),
				V(sx, yEnd + 1.5, s1),
				0.26,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			if sx > -20 then
				-- Invisible tall safety barrier strictly along the stair flank wall so Pathfinding never vaults sideways over the handrail!
				local barMid = (V(sx, yStart + 2.2, s0) + V(sx, yEnd + 2.2, s1)) / 2
				local barLen = (V(sx, yEnd, s1) - V(sx, yStart, s0)).Magnitude
				makePart(
					m,
					"AquaStairFlankGuard",
					CFrame.lookAt(barMid, V(sx, yEnd + 2.2, s1)),
					Vector3.new(0.4, 5.2, barLen),
					PALETTE.woodDark,
					Enum.Material.Wood,
					true,
					1
				)
			end
			for idx = 0, 3 do
				local frac = idx / 3
				local sz = lerp(s0, s1, frac)
				local sy = Y - ((sz - zStart) / totalRun) * (Y - lunaY)
				makeCylinderY(
					m,
					"AquaStairPost",
					C(sx, sy + 1.3, sz),
					4.0,
					0.46,
					PALETTE.woodDark,
					Enum.Material.Wood,
					true
				)
			end
		end
		-- Protective north & east handrails along AquariumLunaLanding so Pathfinding uses the wide west promenade cleanly!
		makePart(
			m,
			"AquaLandingEastRail",
			C(-16.7, Y + 2.6, 40.0),
			Vector3.new(0.36, 0.36, 5.6),
			PALETTE.wood,
			Enum.Material.Wood,
			true
		)
		makePart(
			m,
			"AquaLandingEastMidRail",
			C(-16.7, Y + 1.4, 40.0),
			Vector3.new(0.26, 0.26, 5.6),
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
		makePart(
			m,
			"AquaLandingNorthRail",
			C(-20.2, Y + 2.6, 37.3),
			Vector3.new(7.0, 0.36, 0.36),
			PALETTE.wood,
			Enum.Material.Wood,
			true
		)
		makePart(
			m,
			"AquaLandingNorthMidRail",
			C(-20.2, Y + 1.4, 37.3),
			Vector3.new(7.0, 0.26, 0.26),
			PALETTE.woodDark,
			Enum.Material.Wood,
			true
		)
	end

	-- Continuous double rope railings protecting EVERY drop-off along the promenade, deck, and east landing.
	local railChains = {
		-- Promenade north & west outer rim down to Aquarium deck NW corner
		{
			V(-30.2, Y, 13.7),
			V(-37.0, Y, 13.7),
			V(-43.8, Y, 13.7),
			V(-43.8, Y, 20.0),
			V(-43.8, Y, 26.5),
			V(-43.8, Y, 33.0),
			V(-43.8, Y, 37.3),
			V(-49.0, Y, 37.3),
			V(-54.2, Y, 37.3),
			V(-54.2, Y, 44.0),
			V(-54.2, Y, 51.0),
			V(-54.2, Y, 58.2),
			V(-46.5, Y, 58.2),
			V(-39.0, Y, 58.2),
			V(-31.5, Y, 58.2),
			V(-23.8, Y, 58.2),
			V(-23.8, Y, 51.0),
			V(-23.8, Y, 43.6),
		},
		-- Promenade inner east/south corner down to Aquarium deck NE opening (zero post blocking east landing!)
		{
			V(-30.2, Y, 24.3),
			V(-33.2, Y, 24.3),
			V(-33.2, Y, 30.8),
			V(-33.2, Y, 37.3),
			V(-28.5, Y, 37.3),
			V(-23.8, Y, 37.3),
			V(-16.7, Y, 37.3),
		},
	}
	for _, chain in railChains do
		for i, p in chain do
			makeCylinderY(
				m,
				"RailPost",
				CFrame.new(p + Vector3.new(0, 1.4, 0)),
				3.4,
				0.54,
				PALETTE.woodDark,
				Enum.Material.Wood,
				true
			)
			if i > 1 then
				makeRope(
					m,
					"DeckRail",
					chain[i - 1] + Vector3.new(0, 2.65, 0),
					p + Vector3.new(0, 2.65, 0),
					0.35,
					0.24
				)
			end
		end
	end

	-- Tall monumental entrance portico "AQUÁRIO" spanning the 11-stud promenade (posts wide at -44.8/-32.2 so AquariumSign has 100% clear faces!).
	do
		local gz = 35.8
		for _, gx in { -44.8, -32.2 } do
			makeCylinderY(
				m,
				"AquaGatePost",
				C(gx, Y + 7.2, gz),
				15.2,
				1.6,
				PALETTE.bark,
				Enum.Material.Wood,
				true
			)
			for k = 0, 2 do
				makeCylinderY(
					m,
					"AquaGateWrap",
					C(gx, Y + 1.8 + k * 0.45, gz),
					0.35,
					1.8,
					PALETTE.rope,
					Enum.Material.Fabric,
					false
				)
				makeCylinderY(
					m,
					"AquaGateWrap",
					C(gx, Y + 11.4 + k * 0.45, gz),
					0.35,
					1.8,
					PALETTE.rope,
					Enum.Material.Fabric,
					false
				)
			end
			makeCrystalCluster(
				m,
				"AquaGateCrystal",
				V(gx, Y + 15.0, gz),
				0.72,
				PALETTE.crystalCyan,
				false
			)
			makeLanternBody(
				m,
				"AquaGateLantern",
				V(if gx < -38 then gx - 1.3 else gx + 1.3, Y + 10.6, gz),
				0.95,
				gx < -38
			)
		end
		makeTube(
			m,
			"AquaGateBeam",
			V(-46.4, Y + 13.4, gz),
			V(-30.6, Y + 13.4, gz),
			1.4,
			PALETTE.woodDark,
			Enum.Material.Wood,
			false
		)
		for _, sx in { -41.4, -35.6 } do
			makeCylinderY(
				m,
				"AquaSignMount",
				C(sx, Y + 14.3, gz),
				1.4,
				0.34,
				PALETTE.woodDark,
				Enum.Material.Wood,
				false
			)
		end
		makeSign(
			m,
			"AquariumSign",
			faceTo(V(-38.5, Y + 16.4, gz), V(-38.5, Y + 16.4, 0)),
			10.6,
			3.2,
			"AQUÁRIO",
			"Seus peixes raros",
			PALETTE.signBg,
			PALETTE.signText,
			PALETTE.crystalCyan,
			PALETTE.gold,
			true
		)
	end

	-- Bigger, richer glass aquarium showcase solidly seated into the deck (-0.2 stud overlap + collidable foundation).
	local tc = V(-39.5, Y, 49.8)
	makePart(
		m,
		"TankBase",
		CFrame.new(tc + Vector3.new(0, 0.45, 0)),
		Vector3.new(16.4, 1.3, 10.4),
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	-- Heavy collidable under-deck support piers directly under TankBase down into the cove.
	for _, px in { -46.2, -39.5, -32.8 } do
		for _, pz in { 45.8, 53.8 } do
			makeCylinderY(
				m,
				"TankSupportPier",
				C(px, (Y - 0.2 - 7) / 2, pz),
				Y - 0.2 + 7,
				1.35,
				PALETTE.stoneDark,
				Enum.Material.Cobblestone,
				true
			)
		end
	end
	makePart(
		m,
		"TankBaseTrim",
		CFrame.new(tc + Vector3.new(0, 1.14, 0)),
		Vector3.new(16.8, 0.1, 10.8),
		PALETTE.gold,
		Enum.Material.SmoothPlastic,
		false
	)
	local h = 7.2
	local gy = 1.15 + h / 2
	makePart(
		m,
		"TankGlass",
		CFrame.new(tc + Vector3.new(0, gy, 4.8)),
		Vector3.new(15.4, h, 0.25),
		PALETTE.glass,
		Enum.Material.Glass,
		true,
		0.58
	)
	makePart(
		m,
		"TankGlass",
		CFrame.new(tc + Vector3.new(0, gy, -4.8)),
		Vector3.new(15.4, h, 0.25),
		PALETTE.glass,
		Enum.Material.Glass,
		true,
		0.58
	)
	makePart(
		m,
		"TankGlass",
		CFrame.new(tc + Vector3.new(7.7, gy, 0)),
		Vector3.new(0.25, h, 9.4),
		PALETTE.glass,
		Enum.Material.Glass,
		true,
		0.58
	)
	makePart(
		m,
		"TankGlass",
		CFrame.new(tc + Vector3.new(-7.7, gy, 0)),
		Vector3.new(0.25, h, 9.4),
		PALETTE.glass,
		Enum.Material.Glass,
		true,
		0.58
	)
	makePart(
		m,
		"TankWater",
		CFrame.new(tc + Vector3.new(0, 1.15 + (h - 0.8) / 2, 0)),
		Vector3.new(15.1, h - 0.8, 9.3),
		PALETTE.waterDeep,
		Enum.Material.Glass,
		false,
		0.58
	)
	makePart(
		m,
		"TankSand",
		CFrame.new(tc + Vector3.new(0, 1.35, 0)),
		Vector3.new(15.1, 0.4, 9.3),
		PALETTE.sandPart,
		Enum.Material.Sand,
		false
	)
	for _, c in { { 7.8, 4.9 }, { -7.8, 4.9 }, { 7.8, -4.9 }, { -7.8, -4.9 } } do
		makePart(
			m,
			"TankFrame",
			CFrame.new(tc + Vector3.new(c[1], gy, c[2])),
			Vector3.new(0.46, h + 0.12, 0.46),
			PALETTE.navy,
			Enum.Material.Metal,
			false
		)
	end
	for _, e in
		{
			{ 0, 4.9, 16, 0.46 },
			{ 0, -4.9, 16, 0.46 },
			{ 7.8, 0, 0.46, 10.2 },
			{ -7.8, 0, 0.46, 10.2 },
		}
	do
		makePart(
			m,
			"TankRim",
			CFrame.new(tc + Vector3.new(e[1], 1.15 + h + 0.16, e[2])),
			Vector3.new(e[3], 0.34, e[4]),
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false
		)
	end
	-- Rich tank interior: reef rocks, corals, swaying seaweed, glowing crystals, 12 fish, 3 glowing jellyfish & bubbles.
	for k = 1, 8 do
		local root2 = tc + Vector3.new(rnd(-6.4, 6.4), 1.55, rnd(-3.6, 3.6))
		local col = if k % 3 == 0
			then PALETTE.coral
			elseif k % 3 == 1 then PALETTE.pink
			else PALETTE.gold
		for _ = 1, 4 do
			local tip = root2 + Vector3.new(rnd(-0.9, 0.9), rnd(1.1, 2.7), rnd(-0.7, 0.7))
			makeTube(m, "TankCoral", root2, tip, 0.28, col, Enum.Material.SmoothPlastic, false)
			makeBall(m, "TankCoralTip", tip, 0.38, col, Enum.Material.SmoothPlastic)
		end
	end
	for sw = 1, 10 do
		local b = tc + Vector3.new(rnd(-6.8, 6.8), 1.55, rnd(-4.0, 4.0))
		local weed = makeWedge(
			m,
			"Seaweed",
			CFrame.new(b + Vector3.new(0, 1.4, 0))
				* CFrame.Angles(0, rnd(0, 6.28), math.rad(rnd(-10, 10))),
			Vector3.new(0.12, 2.8, 0.55),
			if sw % 2 == 0 then PALETTE.teal else PALETTE.leaf,
			Enum.Material.SmoothPlastic,
			false
		)
		if sw % 2 == 0 then
			tagSway(weed, 9, 1.8)
		end
	end
	makeCrystalCluster(
		m,
		"TankCrystal",
		tc + Vector3.new(4.2, 1.55, -1.8),
		0.55,
		PALETTE.crystalCyan,
		false
	)
	makeCrystalCluster(
		m,
		"TankCrystal",
		tc + Vector3.new(-4.8, 1.55, 2.0),
		0.5,
		PALETTE.crystalPink,
		false
	)
	local fishCols = {
		PALETTE.gold,
		PALETTE.coral,
		PALETTE.crystalLilac,
		PALETTE.cyan,
		PALETTE.pink,
		PALETTE.leafLight,
	}
	for k = 1, 12 do
		local p = tc + Vector3.new(rnd(-6.0, 6.0), rnd(2.8, 6.6), rnd(-3.2, 3.2))
		makeToyFish(
			m,
			CFrame.new(p) * CFrame.Angles(0, rnd(0, 6.28), 0),
			fishCols[(k - 1) % #fishCols + 1],
			k
		)
	end
	-- 3 glowing animated jellyfish floating inside the tank.
	local jellySpots = {
		{ Vector3.new(-4.2, 5.6, -1.5), PALETTE.crystalPink },
		{ Vector3.new(0.8, 6.2, 1.4), PALETTE.crystalCyan },
		{ Vector3.new(4.6, 5.2, -0.4), PALETTE.crystalLilac },
	}
	for idx, j in jellySpots do
		makeJellyfish(m, tc + (j[1] :: Vector3), j[2] :: Color3, idx)
	end
	local bubbles = makePart(
		m,
		"TankBubbles",
		CFrame.new(tc + Vector3.new(0, 2.2, 0)),
		Vector3.new(14, 0.5, 8),
		PALETTE.white,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	addLight(bubbles, PALETTE.crystalCyan, 14, 0.75)
	local be = Instance.new("ParticleEmitter")
	be.Texture = SPARKLE_TEXTURE
	be.Color = ColorSequence.new(PALETTE.white)
	be.Rate = 10
	be.Lifetime = NumberRange.new(1.5, 2.4)
	be.Speed = NumberRange.new(1.6, 2.4)
	be.EmissionDirection = Enum.NormalId.Top
	be.SpreadAngle = Vector2.new(8, 8)
	be.Size = NumberSequence.new(0.22, 0.36)
	be.Parent = bubbles
	stats.emitters += 1

	-- Deck props cleanly placed along outer corners (>= 3 studs walkway clearance around tank!).
	makeBench(m, "AquariumBench", CY(-39.5, Y, 41.0, 180))
	for _, p in { { -53.4, 57.4 }, { -24.6, 57.4 }, { -53.4, 37.6 }, { -43.4, 14.2 } } do
		makeLantern(m, "DeckLantern", V(p[1], Y, p[2]), 7.2, p[1] < -35)
	end
	makeBarrel(m, "DeckBarrel", V(-52.2, Y, 43.2), 1.9)
	makePlanter(m, "DeckPlanter", V(-26.0, Y, 56.0), PALETTE.crystalCyan)
	makePlanter(m, "DeckPlanter", V(-52.2, Y, 55.6), PALETTE.crystalPink)
	makeBunting(m, "DeckBunting", V(-53.4, Y + 9.4, 57.4), V(-24.6, Y + 9.4, 57.4), 1.4)
end

---------------------------------------------------------------------------------------
-- Region: decoration (palms, crystals, vegetation, sea crystals, scoreboards frames)
---------------------------------------------------------------------------------------

local function isBuiltArea(x: number, z: number): boolean
	return inRect(x, z, -33, 20, -24, 27) -- plaza + edges
		or inRect(x, z, -29, 17, -51, -20) -- workshop terrace
		or dist2(x, z, LAGOON_CX, LAGOON_CZ) < 19.2
		or inRect(x, z, -62, -29, -30, -14) -- sanctuary stairs
		or dist2(x, z, SANCT_CX, SANCT_CZ) < SANCT_R + 1.8
		or inRect(x, z, -25, 7, 22, 65) -- front stairs + Luna's dock + Luna-Aquarium stairs
		or inRect(x, z, -56, -16, 13, 60) -- aquarium deck + west promenade + east landing
		or (x > 7 and z > 21) -- wharf
		or (x > 11 and z > -4 and z < 19) -- pier
		or inRect(x, z, -58, -28, -12, 6) -- lagoon arrival plaza, bridge & portal platform
end

local function buildDecor(root: Instance): Model
	local m = makeModel(root, "Decor")

	-- Intentional, tall palms (2 flank the Workshop; 3 frame the lagoon, sanctuary & aquarium).
	local palms = {
		{ -59, 14, 20.5, 145 },
		{ -56, -54, 21.5, -135 },
		{ -60, 35, 19.0, 120 },
	}
	for i, p in palms do
		local g = groundY(p[1], p[2])
		if g > 3 then
			makePalm(m, "Palm" .. i, V(p[1], g, p[2]), p[3], p[4])
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

-- Scoreboards side by side (decision 2026-11-25): one row facing the plaza, centred here,
-- each board BOARD_SCALE times the original 14 x 9 and BOARD_GAP studs apart centre to centre.
local LEADERBOARD_CENTER = Vector3.new(-78, 40, 31)
local LEADERBOARD_FACE = Vector3.new(-10, 40, 36)
local BOARD_SCALE = 1.3
local BOARD_GAP = 22

local LEADERBOARD_SCREENS = {
	"LeaderboardScreen_Catches",
	"LeaderboardScreen_Species",
	"LeaderboardScreen_Level",
}

local function buildContract(contract: Instance, decor: Instance)
	-- Spawn: faces the Workshop (-Z), 8 x 0.2 x 8. A real SpawnLocation (invisible,
	-- non-colliding) so new players and respawns land on the plaza.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Size = Vector3.new(8, 0.2, 8)
	spawn.CFrame = CFrame.new(O + SPAWN_POS)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.CanTouch = false
	spawn.Transparency = 1
	spawn.CastShadow = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Enabled = true
	CollectionService:AddTag(spawn, "PlayerSpawn")
	spawn.Parent = contract
	stats.parts += 1
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

	-- Scoreboards floating high over the sea to the west, squarely facing the plaza, with glowing frame & hex base.
	-- One Model tagged LeaderboardBoard holding the three screens the client fills
	-- (LeaderboardBoard feature looks for LeaderboardScreen_<board> parts inside it).
	local boardModel = Instance.new("Model")
	boardModel.Name = "LeaderboardBoard"
	CollectionService:AddTag(boardModel, "LeaderboardBoard")
	boardModel.Parent = contract
	local S = BOARD_SCALE
	-- One shared facing for the row, so the three boards stand side by side (never one behind
	-- the other) and read together from the plaza.
	local rowCf = faceTo(O + LEADERBOARD_CENTER, O + LEADERBOARD_FACE)
	for i = 1, #LEADERBOARD_SCREENS do
		-- Strictly upright, facing cleanly toward the plaza & arrival vista (zero awkward tilt).
		local cf = rowCf * CFrame.new((i - 2) * BOARD_GAP, 0, 0)
		local board = Instance.new("Part")
		board.Name = LEADERBOARD_SCREENS[i]
		board.Size = Vector3.new(14 * S, 9 * S, 0.6)
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
		board.Parent = boardModel
		stats.parts += 1
		-- Ornate glowing gold frame (strictly behind front face so SurfaceGui stays crisp and unobstructed).
		makePart(
			decor,
			"BoardFrame",
			cf * CFrame.new(0, 0, 0.45),
			Vector3.new(15.4 * S, 10.4 * S, 0.45),
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false
		)
		local glowRim = makePart(
			decor,
			"BoardGlowRim",
			cf * CFrame.new(0, 0, 0.36),
			Vector3.new(14.7 * S, 9.7 * S, 0.2),
			if i == 2 then PALETTE.goldLight else PALETTE.cyan,
			Enum.Material.Neon,
			false,
			0.35
		)
		tagPulse(glowRim, 0.22, 0.52, 1.5, "Transparency")
		makePart(
			decor,
			"BoardBack",
			cf * CFrame.new(0, 0, 0.78),
			Vector3.new(14.4 * S, 9.4 * S, 0.35),
			PALETTE.navy,
			Enum.Material.SmoothPlastic,
			false
		)
		makePart(
			decor,
			"BoardCrest",
			cf * CFrame.new(0, 5.75 * S, 0.45),
			Vector3.new(4.6 * S, 1.35 * S, 0.55),
			PALETTE.gold,
			Enum.Material.SmoothPlastic,
			false
		)
		local boardGem = makePart(
			decor,
			"BoardGem",
			cf * CFrame.new(0, 5.85 * S, 0.12) * CFrame.Angles(0, 0, math.rad(45)),
			Vector3.new(1.05 * S, 1.05 * S, 0.32),
			if i == 2 then PALETTE.goldLight else PALETTE.cyan,
			Enum.Material.Neon,
			false,
			0.05
		)
		tagBob(boardGem, 0.18, 1.6, i * 1.1)
		-- Floating hexagonal pedestal base + glowing inverted crystal under each board (gently bobbing!).
		local under = (cf * CFrame.new(0, -6.4 * S, 0.4)).Position
		local pedModel = makeModel(decor, "BoardPedestal" .. i)
		local pedPivot = makePart(
			pedModel,
			"Pivot",
			CFrame.new(under),
			Vector3.new(0.2, 0.2, 0.2),
			PALETTE.stoneDark,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		pedModel.PrimaryPart = pedPivot
		pedModel.WorldPivot = pedPivot.CFrame
		for k = 0, 2 do
			makePart(
				pedModel,
				"BoardHexBase",
				CFrame.new(under) * CFrame.Angles(0, math.rad(60 * k), 0),
				Vector3.new(3.2, 0.85, 5.5),
				PALETTE.stoneDark,
				Enum.Material.Slate,
				false
			)
		end
		makeNeonRing(
			pedModel,
			"BoardHexRing",
			CFrame.new(under + Vector3.new(0, 0.5, 0)),
			3.1,
			0.2,
			6,
			if i == 2 then PALETTE.goldLight else PALETTE.cyan,
			0.22
		)
		makeCrystal(
			pedModel,
			"BoardCrystal",
			CFrame.new(under - Vector3.new(0, 0.4, 0)) * CFrame.Angles(math.pi, 0, 0),
			3.2,
			0.65,
			PALETTE.crystalCyan,
			false
		)
		tagBob(pedModel, 0.32, 1.3, i * 1.4)
		local spark = makePart(
			decor,
			"BoardSparkles",
			CFrame.new(under),
			Vector3.new(3.5, 1.2, 3.5),
			PALETTE.cyan,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		addSparkles(spark, PALETTE.crystalCyan, 6, 0.45, 0.7)
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

function Builder.build(origin: Vector3?, modelName: string?): Model
	local t0 = os.clock()
	O = origin or DEFAULT_ORIGIN
	MODEL_NAME = modelName or DEFAULT_MODEL_NAME
	rng = Random.new(SEED)
	stats.parts = 0
	stats.lights = 0
	stats.emitters = 0
	stats.animTags = 0

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
	root:SetAttribute("AnimTagCount", stats.animTags)
	root.Parent = Workspace

	print(
		string.format(
			"[HubBuilder] built %s at %s: %d parts, %d lights, %d emitters, %d animTags in %.1fs",
			MODEL_NAME,
			tostring(O),
			stats.parts,
			stats.lights,
			stats.emitters,
			stats.animTags,
			os.clock() - t0
		)
	)
	return root
end

---------------------------------------------------------------------------------------
-- Self test (returns a list of failures; empty list = everything OK)
---------------------------------------------------------------------------------------

function Builder.selfTest(origin: Vector3?, modelName: string?): { string }
	MODEL_NAME = modelName or DEFAULT_MODEL_NAME
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
	o = origin or (if typeof(stored) == "Vector3" then stored else DEFAULT_ORIGIN)

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
	if #portals ~= 6 then
		fail("expected 6 ZonePortal triggers, found " .. #portals)
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
			if
				math.abs(rel.X - LAGOON_PORTAL_POS.X) > 2.0
				or math.abs(rel.Z - LAGOON_PORTAL_POS.Z) > 2.0
			then
				fail(
					id
						.. ": should be near "
						.. tostring(LAGOON_PORTAL_POS)
						.. ", is at "
						.. tostring(rel)
				)
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
	local boards: { BasePart } = {}
	local boardModels = 0
	for _, d in all do
		if d:IsA("Model") and CollectionService:HasTag(d, "LeaderboardBoard") then
			boardModels += 1
			for _, screenName in LEADERBOARD_SCREENS do
				local screen = d:FindFirstChild(screenName)
				if screen and screen:IsA("BasePart") then
					table.insert(boards, screen)
				else
					fail("LeaderboardBoard model missing " .. screenName)
				end
			end
		end
	end
	if boardModels ~= 1 or #boards ~= 3 then
		fail(
			"expected 1 LeaderboardBoard model with 3 screens, found "
				.. boardModels
				.. "/"
				.. #boards
		)
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
		{ "luna npc spot", -10.8, 53.5, PLAZA_Y - FRONT_STAIR_RISE * 18 },
		{ "luna dock", -15.5, 58.0, PLAZA_Y - FRONT_STAIR_RISE * 18 },
		{ "vo anzol spot", 14, 2, PLAZA_Y },
		{ "lucy npc spot", 34, 3.2, PIER_Y },
		{ "pier start", 25, 8, PIER_Y },
		{ "pier middle", 55, 8, PIER_Y },
		{ "pier tip", PIER_TIP.X, PIER_TIP.Z, PIER_Y },
		{ "wharf bridge", 16.0, 28.6, (PLAZA_Y + WHARF_Y) / 2 },
		{ "wharf", 36, 44, WHARF_Y },
		{ "boardwalk", 69.4, 30, (PIER_Y + WHARF_Y) / 2 },
		{ "lagoon arrival plaza", -31.5, LAGOON_PORTAL_POS.Z, PLAZA_Y },
		{ "lagoon bridge", -38.2, LAGOON_PORTAL_POS.Z, PLAZA_Y },
		{ "lagoon dais", -46.5, LAGOON_PORTAL_POS.Z + 5.0, LAGOON_PORTAL_POS.Y },
		{ "sanctuary landing", -32.5, -22, PLAZA_Y },
		{ "sanctuary stairs", -45.5, -22, PLAZA_Y + (SANCT_Y - PLAZA_Y - 0.05) / 21 * 11 },
		{ "sanctuary plateau", -62, -30, SANCT_Y },
		{ "aquarium promenade", -36.5, 19.0, PLAZA_Y },
		{ "aquarium walkway", -38.5, 31.0, PLAZA_Y },
		{ "aquarium deck", -46, 40, PLAZA_Y },
		{ "aquarium luna landing", -20.2, 39.6, PLAZA_Y },
		{ "aquarium luna stairs", -20.2, 52.5, (PLAZA_Y + (PLAZA_Y - FRONT_STAIR_RISE * 18)) / 2 },
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

	-- (a) PathfindingService navigability checks between 14 key points: Status == Success AND 0 Jump waypoints!
	do
		local lunaY = PLAZA_Y - FRONT_STAIR_RISE * 18
		local pts: { [string]: Vector3 } = {
			spawn = R(-6, PLAZA_Y + 0.5, 11.5),
			workshop = R(-6, TERRACE_Y + 0.5, -34.0),
			stairs_foot = R(-6, lunaY + 0.5, 55.0),
			luna = R(-10.8, lunaY + 0.5, 53.5),
			luna_dock = R(-19.5, lunaY + 0.5, 64.2),
			pier_start = R(24, PIER_Y + 0.5, 8),
			lucy = R(34, PIER_Y + 0.5, 5.2),
			pier_tip = R(78, PIER_Y + 0.5, 8),
			vo_anzol = R(14, PLAZA_Y + 0.5, 2),
			wharf_entry = R(16.0, WHARF_Y + 0.5, 39),
			wharf_portals = R(28, WHARF_Y + 0.5, 48),
			sanctuary_gate = R(-32.5, PLAZA_Y + 0.5, -22),
			sanctuary_portals = R(-66, SANCT_Y + 0.5, -34),
			apprentice_portal = R(-45.5, LAGOON_PORTAL_POS.Y + 0.5, LAGOON_PORTAL_POS.Z),
			aquarium = R(-38.5, PLAZA_Y + 0.5, 42.5),
		}
		local routes: { { string } } = {
			{ "spawn", "workshop" },
			{ "spawn", "stairs_foot" },
			{ "spawn", "luna" },
			{ "spawn", "pier_start" },
			{ "spawn", "lucy" },
			{ "spawn", "pier_tip" },
			{ "spawn", "vo_anzol" },
			{ "spawn", "wharf_entry" },
			{ "spawn", "wharf_portals" },
			{ "spawn", "sanctuary_gate" },
			{ "spawn", "sanctuary_portals" },
			{ "spawn", "apprentice_portal" },
			{ "spawn", "aquarium" },
			{ "aquarium", "luna_dock" },
			{ "luna_dock", "aquarium" },
			{ "luna_dock", "luna" },
			{ "wharf_portals", "pier_tip" },
			{ "sanctuary_portals", "apprentice_portal" },
		}
		for _, pair in routes do
			local aName, bName = pair[1], pair[2]
			local aPos, bPos = pts[aName], pts[bName]
			local path = PathfindingService:CreatePath({
				AgentRadius = 2,
				AgentHeight = 5,
				AgentCanJump = true,
				WaypointSpacing = 4,
			})
			local ok, err = pcall(function()
				path:ComputeAsync(aPos, bPos)
			end)
			if not ok then
				fail(string.format("path %s->%s compute error: %s", aName, bName, tostring(err)))
			elseif path.Status ~= Enum.PathStatus.Success then
				fail(string.format("path %s->%s failed: %s", aName, bName, tostring(path.Status)))
			else
				local jumps = 0
				local firstJump = ""
				for _, wp in path:GetWaypoints() do
					if wp.Action == Enum.PathWaypointAction.Jump then
						jumps += 1
						if firstJump == "" then
							local rp = wp.Position - o
							firstJump = string.format("(%.1f,%.1f,%.1f)", rp.X, rp.Y, rp.Z)
						end
					end
				end
				if jumps > 0 then
					fail(
						string.format(
							"path %s->%s requires %d jump(s), first at %s",
							aName,
							bName,
							jumps,
							firstJump
						)
					)
				end
			end
		end
	end

	-- (b) SurfaceGui face clearance: nothing opaque within 1.2 studs directly in front of any sign face!
	do
		local function faceNormal(n: Enum.NormalId): Vector3
			if n == Enum.NormalId.Front then
				return Vector3.new(0, 0, -1)
			elseif n == Enum.NormalId.Back then
				return Vector3.new(0, 0, 1)
			elseif n == Enum.NormalId.Right then
				return Vector3.new(1, 0, 0)
			elseif n == Enum.NormalId.Left then
				return Vector3.new(-1, 0, 0)
			elseif n == Enum.NormalId.Top then
				return Vector3.new(0, 1, 0)
			else
				return Vector3.new(0, -1, 0)
			end
		end
		local ovParams = OverlapParams.new()
		ovParams.FilterType = Enum.RaycastFilterType.Include
		ovParams.FilterDescendantsInstances = { hub }
		for _, d in all do
			if d:IsA("SurfaceGui") then
				local parentPart = d.Parent
				if parentPart and parentPart:IsA("BasePart") then
					local localDir = faceNormal(d.Face)
					local halfDepth = math.abs(localDir.X) * parentPart.Size.X / 2
						+ math.abs(localDir.Y) * parentPart.Size.Y / 2
						+ math.abs(localDir.Z) * parentPart.Size.Z / 2
					local boxCf = parentPart.CFrame * CFrame.new(localDir * (halfDepth + 0.65))
					local shrinkX = math.max(0.4, parentPart.Size.X - 0.45)
					local shrinkY = math.max(0.4, parentPart.Size.Y - 0.45)
					local boxSize = if math.abs(localDir.Z) > 0.5
						then Vector3.new(shrinkX, shrinkY, 1.15)
						elseif math.abs(localDir.X) > 0.5 then Vector3.new(
							1.15,
							shrinkY,
							math.max(0.4, parentPart.Size.Z - 0.45)
						)
						else Vector3.new(
							shrinkX,
							1.15,
							math.max(0.4, parentPart.Size.Z - 0.45)
						)
					local hits = Workspace:GetPartBoundsInBox(boxCf, boxSize, ovParams)
					for _, h in hits do
						if
							h ~= parentPart
							and h.Transparency < 0.95
							and not string.find(h.Name, "Frame")
							and not string.find(h.Name, "Back")
							and not string.find(h.Name, "Tip")
						then
							fail(
								string.format(
									"SurfaceGui blocked on %s (%s): hit %s",
									parentPart.Name,
									tostring(d.Face),
									h.Name
								)
							)
							break
						end
					end
				end
			end
		end
	end

	-- (c) Key collidable support check: important decks, tank, stall & lantern bases must touch supporting geometry!
	do
		local supportTargets: { [string]: boolean } = {
			TankBase = true,
			BaitStallDeck = true,
			StairLanternBase = true,
			TerraceLanternBase = true,
			CircleLanternBase = true,
			SpotPedestal = true,
			LunaWoodDock = true,
			AquariumDeck = true,
			PortalPlatformBase = true,
		}
		local ovParams = OverlapParams.new()
		ovParams.FilterType = Enum.RaycastFilterType.Include
		ovParams.FilterDescendantsInstances = { hub, Workspace.Terrain }
		for _, d in all do
			if d:IsA("BasePart") and d.CanCollide and supportTargets[d.Name] then
				local touching = Workspace:GetPartsInPart(d, ovParams)
				local supported = false
				for _, t in touching do
					if t ~= d and (t == Workspace.Terrain or t.CanCollide) then
						supported = true
						break
					end
				end
				if not supported then
					local rp = d.Position - o
					fail(
						string.format(
							"floating collidable part %s at (%.1f,%.1f,%.1f)",
							d.Name,
							rp.X,
							rp.Y,
							rp.Z
						)
					)
				end
			end
		end
	end

	-- (d) Minimum corridor width check via lateral raycasts (at player torso height Y + 3.0).
	do
		local corridors = {
			{ "aquarium promenade", R(-38.5, PLAZA_Y + 3.0, 30.0), Vector3.new(1, 0, 0), 9.0 },
			{
				"apprentice bridge",
				R(-38.2, PLAZA_Y + 3.0, LAGOON_PORTAL_POS.Z),
				Vector3.new(0, 0, 1),
				7.0,
			},
			{
				"wharf bridge",
				R(16.0, (PLAZA_Y + WHARF_Y) / 2 + 3.0, 28.6),
				Vector3.new(1, 0, 0),
				8.5,
			},
			{ "pier portico", R(19.6, PIER_Y + 3.0, 8.0), Vector3.new(0, 0, 1), 9.0 },
			{ "sanctuary stairs", R(-45.5, 18.5, -22.0), Vector3.new(0, 0, 1), 8.0 },
			{ "aquarium-luna stairs", R(-20.2, 8.7, 50.4), Vector3.new(1, 0, 0), 5.5 },
			{ "boardwalk", R(69.4, (PIER_Y + WHARF_Y) / 2 + 3.0, 30.0), Vector3.new(1, 0, 0), 6.0 },
		}
		for _, c in corridors do
			local label = c[1] :: string
			local pt = c[2] :: Vector3
			local axis = c[3] :: Vector3
			local minW = c[4] :: number
			local rPos = Workspace:Raycast(pt, axis * 15, params)
			local rNeg = Workspace:Raycast(pt, -axis * 15, params)
			local dPos = if rPos then rPos.Distance else 15
			local dNeg = if rNeg then rNeg.Distance else 15
			local width = dPos + dNeg
			if width < minW then
				fail(string.format("corridor '%s' too narrow: %.1f < %.1f", label, width, minW))
			end
		end
	end

	-- (e) Animation tags count >= 60 across the 6 client animation tags.
	do
		local animTagNames = { "HubSpin", "HubBob", "HubPulse", "HubFlicker", "HubSway", "HubWave" }
		local totalTagged = 0
		for _, tagName in animTagNames do
			for _, inst in CollectionService:GetTagged(tagName) do
				if inst:IsDescendantOf(hub) then
					totalTagged += 1
				end
			end
		end
		if totalTagged < 60 then
			fail(string.format("expected >= 60 animation-tagged instances, found %d", totalTagged))
		end
	end

	return fails
end

return Builder
