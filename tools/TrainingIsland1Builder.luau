--!strict
--[[
	TrainingIsland1Builder.luau
	Constrói/recria a Ilha de Treino 1 ("Ilha do Aprendiz") em:
		Workspace.TrainingIslands.TrainingIsland_Apprentice

	Uso no Roblox Studio (Command Bar):
		local src = game.ServerStorage.DevTools.TrainingIsland1Builder:Clone()
		require(src).build()
		src:Destroy()

	Para pré-visualizar a iluminação dourada da concept art (apenas para prints):
		local mod = require(game.ServerStorage.DevTools.TrainingIsland1Builder:Clone())
		mod.build()
		mod.applyReferenceLighting()
		-- depois, para desfazer:
		mod.restoreLighting()
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Builder = {}

-- ============================================================================
-- CONFIGURAÇÃO GLOBAL & PALETA (fiel às referências A e B)
-- ============================================================================

local CONTAINER_NAME = "TrainingIslands"
local ISLAND_NAME = "TrainingIsland_Apprentice"
local DEFAULT_ORIGIN = Vector3.new(520, 12, -380)
local SEED = 20261124

local FOCUS_CENTER = Vector2.new(-16.5, -5.5)
local FOCUS_RX = 14.2
local FOCUS_RZ = 12.2

local INSTINCT_CENTER = Vector2.new(20.5, 7.5)
local INSTINCT_RX = 14.5
local INSTINCT_RZ = 12.6

local PORTAL_LOCAL = Vector3.new(-11.2, -0.22, 31.2)
local PORTAL_LOOK_LOCAL = Vector3.new(-14.2, -0.22, 43.0)

local BOARDWALK_START = Vector3.new(-2.8, 0.16, 24.0)
local BOARDWALK_END = Vector3.new(4.2, 0.16, -3.5)

local PALETTE = {
	-- Topo (grama oliva-dourada e areia quente)
	GrassMain = Color3.fromRGB(134, 174, 66),
	GrassWarm = Color3.fromRGB(154, 184, 74),
	GrassDeep = Color3.fromRGB(112, 152, 56),
	SandMain = Color3.fromRGB(238, 204, 128),
	SandWarm = Color3.fromRGB(224, 186, 110),
	DirtLip = Color3.fromRGB(138, 94, 60),
	PondEdgeDirt = Color3.fromRGB(192, 158, 104),

	-- Rochas laterais marrom terracota quente + raízes + musgo
	RockLight = Color3.fromRGB(186, 134, 96),
	RockMid = Color3.fromRGB(158, 108, 76),
	RockDark = Color3.fromRGB(124, 82, 58),
	RockDeep = Color3.fromRGB(94, 60, 42),
	RockShadow = Color3.fromRGB(66, 42, 32),
	RootDark = Color3.fromRGB(84, 52, 34),
	MossGreen = Color3.fromRGB(102, 148, 58),

	-- Pedra do portal e runas
	StoneLight = Color3.fromRGB(196, 192, 188),
	StoneMid = Color3.fromRGB(168, 164, 162),
	StoneMortar = Color3.fromRGB(92, 92, 102),
	StoneRune = Color3.fromRGB(122, 126, 144),

	-- Madeiras, corda e metais
	WoodWarm1 = Color3.fromRGB(182, 118, 66),
	WoodWarm2 = Color3.fromRGB(162, 100, 54),
	WoodWarm3 = Color3.fromRGB(198, 134, 76),
	WoodWeathered = Color3.fromRGB(146, 92, 50),
	WoodDark = Color3.fromRGB(108, 66, 38),
	WoodCarved = Color3.fromRGB(244, 222, 180),
	RopeTan = Color3.fromRGB(212, 174, 114),
	RopeKnot = Color3.fromRGB(190, 152, 94),
	BarrelIronBlue = Color3.fromRGB(74, 114, 162),
	IronDark = Color3.fromRGB(62, 68, 80),

	-- Cristais e Lagoa do Foco
	CrystalIce = Color3.fromRGB(68, 206, 255),
	CrystalCyan = Color3.fromRGB(46, 224, 255),
	CrystalCore = Color3.fromRGB(186, 248, 255),
	FocusFloor = Color3.fromRGB(72, 222, 240),
	FocusWater = Color3.fromRGB(58, 214, 248),
	FocusCaustic = Color3.fromRGB(184, 250, 255),
	FocusRing = Color3.fromRGB(216, 254, 255),

	-- Lagoa do Instinto
	InstinctCenter = Color3.fromRGB(26, 204, 196),
	InstinctMid = Color3.fromRGB(54, 62, 166),
	InstinctOuter = Color3.fromRGB(98, 36, 186),
	InstinctRimGlow = Color3.fromRGB(184, 68, 255),
	InstinctWater = Color3.fromRGB(104, 58, 204),
	FishWhaleDark = Color3.fromRGB(16, 56, 92),
	FishWhaleRim = Color3.fromRGB(74, 224, 242),
	FishGold = Color3.fromRGB(255, 214, 96),
	FishRainbowA = Color3.fromRGB(255, 136, 216),
	FishRainbowB = Color3.fromRGB(110, 242, 255),
	FishRainbowC = Color3.fromRGB(255, 236, 122),

	-- Árvore de flores, lanternas, boias e nuvens
	TreeBark = Color3.fromRGB(116, 72, 74),
	TreeBarkDark = Color3.fromRGB(88, 54, 58),
	BlossomLight = Color3.fromRGB(255, 214, 236),
	BlossomPink = Color3.fromRGB(255, 164, 216),
	BlossomRose = Color3.fromRGB(240, 124, 194),
	BlossomLilac = Color3.fromRGB(206, 114, 206),

	AmberGlow = Color3.fromRGB(255, 188, 58),
	AmberCore = Color3.fromRGB(255, 236, 148),
	BuoyOrange = Color3.fromRGB(248, 112, 42),
	BuoyWhite = Color3.fromRGB(250, 248, 244),

	CloudTop = Color3.fromRGB(255, 244, 224),
	CloudShade = Color3.fromRGB(234, 212, 188),
	WaterfallBlue = Color3.fromRGB(96, 222, 252),
	WaterfallLight = Color3.fromRGB(164, 242, 255),
	WaterfallFoam = Color3.fromRGB(238, 252, 255),
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
-- UTILITÁRIOS DE GEOMETRIA
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
	p.Name = name
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	local col = if canCollide == nil then true else canCollide
	p.CanCollide = col
	p.CanTouch = false
	p.CanQuery = col
	p.Transparency = transparency or 0
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
	material: Enum.Material?,
	canCollide: boolean?,
	transparency: number?
): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Color = color
	w.Material = material or Enum.Material.SmoothPlastic
	local col = if canCollide == nil then true else canCollide
	w.CanCollide = col
	w.CanTouch = false
	w.CanQuery = col
	w.Transparency = transparency or 0
	w.Size = size
	w.CFrame = cf
	w.Parent = parent
	return w
end

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
	local p = makePart(
		parent,
		name,
		cf * CFrame.Angles(0, 0, math.rad(90)),
		Vector3.new(height, diameter, diameter),
		color,
		material,
		canCollide,
		transparency
	)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function makeEllipsoid(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	canCollide: boolean?,
	transparency: number?
): Part
	local p = makePart(parent, name, cf, size, color, material, canCollide, transparency)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function makeSegment(
	parent: Instance,
	name: string,
	p1: Vector3,
	p2: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material?,
	isCylinder: boolean?,
	canCollide: boolean?
): Part?
	local diff = p2 - p1
	local len = diff.Magnitude
	if len < 0.01 then
		return nil
	end
	local mid = (p1 + p2) * 0.5
	local look = CFrame.lookAt(mid, p2)
	if isCylinder then
		local p = makePart(
			parent,
			name,
			look * CFrame.Angles(0, math.rad(90), 0),
			Vector3.new(len, thickness, thickness),
			color,
			material,
			canCollide,
			0
		)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	return makePart(
		parent,
		name,
		look,
		Vector3.new(thickness, thickness, len),
		color,
		material,
		canCollide,
		0
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
		1
	)
	hub.CastShadow = false
	hub.CanQuery = false
	hub.CanTouch = false
	ringModel.PrimaryPart = hub

	local segLen = 2 * radius * math.tan(math.pi / segments) * 1.1
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
			transparency or 0
		)
		seg.CastShadow = false
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
		local yOff = (c - (coils + 1) * 0.5) * 0.24
		local ring = makeCylinderY(
			parent,
			name .. "_" .. tostring(c),
			CFrame.new(centerPos + Vector3.new(0, yOff, 0))
				* CFrame.Angles(math.rad((c % 2 == 0 and 3 or -3)), 0, 0),
			0.22,
			coilDiameter,
			if c % 2 == 0 then PALETTE.RopeTan else PALETTE.RopeKnot,
			Enum.Material.Fabric,
			false,
			0
		)
		ring.CastShadow = false
	end
end

-- ============================================================================
-- FUNÇÕES DE FORMATO DA ILHA & LAGOAS
-- ============================================================================

local function getIslandRadius(angle: number): number
	return 46.5 + 1.35 * math.sin(angle * 3 + 0.45) + 0.75 * math.cos(angle * 5 - 0.55)
end

local function getBeachWidth(angle: number): number
	local delta = angle - 1.96
	local frontFocus = math.max(0, math.cos(delta))
	return 2.4 + (frontFocus ^ 2.2) * 13.0
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

local function isOnPortalSandPath(x: number, z: number): boolean
	-- Caminho curvo suave de areia ligando o portal ao início da passarela
	if z < 22.0 or z > 35.0 then
		return false
	end
	local t = math.clamp((z - 22.5) / 10.5, 0, 1)
	local centerX = -3.4 * (1 - t) + -11.2 * t
	return math.abs(x - centerX) < (2.8 + t * 2.2)
end

local function getTopSurfaceY(x: number, z: number): number
	local r = math.sqrt(x * x + z * z)
	local angle = math.atan2(z, x)
	local grassR = getIslandRadius(angle) - getBeachWidth(angle)
	if r <= grassR and not isOnPortalSandPath(x, z) then
		return 0.0
	end
	return -0.22
end

-- ============================================================================
-- 1. TERRENO DO TOPO (GRAMA QUENTE + AREIA + BORDA SUAVE + LÁBIO DE TERRA)
-- ============================================================================

local function buildIslandTopTerrain(root: Model, origin: Vector3, rng: Random)
	local folder = makeFolder(root, "TerrainTop")
	local step = 1.25
	local halfSpan = 48.0
	local cols = math.floor((halfSpan * 2) / step)

	-- Miolo em faixas finas (recuadas 1.8 studs da borda para NUNCA criar escadinha visível)
	for iz = 0, cols do
		local z = -halfSpan + iz * step
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
					CFrame.new(origin + Vector3.new(midX, -0.85, z)),
					Vector3.new(width, 1.7, step + 0.05),
					PALETTE.GrassMain,
					Enum.Material.Grass,
					true,
					0
				)
			elseif runKind == "Sand" then
				makePart(
					folder,
					"SandStrip",
					CFrame.new(origin + Vector3.new(midX, -1.01, z)),
					Vector3.new(width, 1.58, step + 0.05),
					PALETTE.SandMain,
					Enum.Material.Sand,
					true,
					0
				)
			end
			runKind = nil
		end

		for ix = 0, cols do
			local x = -halfSpan + ix * step
			local r = math.sqrt(x * x + z * z)
			local angle = math.atan2(z, x)
			local islandR = getIslandRadius(angle) - 2.4
			local grassR = getIslandRadius(angle) - getBeachWidth(angle)

			local cellKind: string? = nil
			if r <= islandR then
				local inFocus = isInsideEllipse(x, z, FOCUS_CENTER, FOCUS_RX, FOCUS_RZ, -0.35)
				local inInstinct =
					isInsideEllipse(x, z, INSTINCT_CENTER, INSTINCT_RX, INSTINCT_RZ, -0.35)
				if not inFocus and not inInstinct then
					if r <= grassR and not isOnPortalSandPath(x, z) then
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
		flushRun(halfSpan + step * 0.5)
	end

	-- Borda externa CONTÍNUA e integrada à rocha (sem degrau nem prato sobrando)
	local rimFolder = makeFolder(folder, "SmoothCurvedRims")
	local segCount = 76
	for i = 1, segCount do
		local a1 = (i / segCount) * math.pi * 2
		local a2 = ((i + 1) / segCount) * math.pi * 2
		local r1 = getIslandRadius(a1)
		local r2 = getIslandRadius(a2)

		local p1 = origin + Vector3.new(math.cos(a1) * r1, -0.22, math.sin(a1) * r1)
		local p2 = origin + Vector3.new(math.cos(a2) * r2, -0.22, math.sin(a2) * r2)
		local segLen = (p2 - p1).Magnitude + 1.05
		local mid = (p1 + p2) * 0.5
		local cf = CFrame.lookAt(mid, p2)

		-- Faixa externa lisa de areia nivelada com o raio da rocha (+X aponta para DENTRO!)
		makePart(
			rimFolder,
			"SandRim_" .. tostring(i),
			cf * CFrame.new(2.55, -0.68, 0),
			Vector3.new(5.4, 1.36, segLen),
			PALETTE.SandMain,
			Enum.Material.Sand,
			true,
			0
		)

		-- Chanfro arredondado de areia descendo suavemente para o lábio de terra na borda exata
		local sandBevel = makePart(
			rimFolder,
			"SandBevel_" .. tostring(i),
			cf * CFrame.new(0.32, -0.82, 0) * CFrame.Angles(0, 0, math.rad(24)),
			Vector3.new(1.45, 1.25, segLen * 1.05),
			PALETTE.SandWarm,
			Enum.Material.Sand,
			false,
			0
		)
		sandBevel.CastShadow = false

		-- Lábio de terra marrom quente contínuo colado no mesmo raio da rocha (zero degrau)
		local dirtLip = makePart(
			rimFolder,
			"DirtLip_" .. tostring(i),
			cf * CFrame.new(1.15, -1.78, 0) * CFrame.Angles(0, 0, math.rad(12)),
			Vector3.new(3.0, 1.85, segLen * 1.08),
			PALETTE.DirtLip,
			Enum.Material.Concrete,
			true,
			0
		)
		dirtLip.CastShadow = true

		-- Transição larga e suave de grama sobre a areia (+X para dentro, cobre 100% da escadinha)
		local bw1 = getBeachWidth(a1)
		local bw2 = getBeachWidth(a2)
		local g1 = origin + Vector3.new(math.cos(a1) * (r1 - bw1), -0.02, math.sin(a1) * (r1 - bw1))
		local g2 = origin + Vector3.new(math.cos(a2) * (r2 - bw2), -0.02, math.sin(a2) * (r2 - bw2))
		local gMid = (g1 + g2) * 0.5
		local gLen = (g2 - g1).Magnitude + 1.3
		local gCf = CFrame.lookAt(gMid, g2)
		if not isOnPortalSandPath(gMid.X - origin.X, gMid.Z - origin.Z) then
			local grassEdge = makePart(
				rimFolder,
				"GrassEdge_" .. tostring(i),
				gCf * CFrame.new(1.95, -0.18, 0) * CFrame.Angles(0, 0, math.rad(5)),
				Vector3.new(4.8, 0.38, gLen),
				if i % 3 == 0 then PALETTE.GrassWarm else PALETTE.GrassMain,
				Enum.Material.Grass,
				false,
				0
			)
			grassEdge.CastShadow = false
		end
	end

	-- Caminho suave de areia orgânico do portal até o começo da passarela (sem escadinha)
	local pathFolder = makeFolder(folder, "PortalSandPath")
	for s = 0, 8 do
		local t = s / 8
		local px = -11.2 * (1 - t) + -3.2 * t + math.sin(t * math.pi) * 1.2
		local pz = 32.8 * (1 - t) + 23.0 * t
		local radW = 5.8 * (1 - t) + 5.2 * t
		local pad = makeCylinderY(
			pathFolder,
			"SandPathPad_" .. tostring(s),
			CFrame.new(origin + Vector3.new(px, -0.30, pz)),
			0.22,
			radW,
			if s % 2 == 0 then PALETTE.SandMain else PALETTE.SandWarm,
			Enum.Material.Sand,
			true,
			0
		)
		pad.CastShadow = false
	end

	-- Tufos de grama cruzados, florzinhas, pedrinhas, conchas e estrelas-do-mar na areia
	local decoFolder = makeFolder(folder, "GroundDetails")
	local flowerColors = {
		Color3.fromRGB(255, 232, 112),
		Color3.fromRGB(255, 178, 224),
		Color3.fromRGB(250, 248, 238),
		Color3.fromRGB(168, 236, 255),
	}

	for i = 1, 125 do
		local ang = rng:NextNumber(0, math.pi * 2)
		local maxR = getIslandRadius(ang) - getBeachWidth(ang) - 1.2
		local rad = math.sqrt(rng:NextNumber(0.06, 1.0)) * maxR
		local x = math.cos(ang) * rad
		local z = math.sin(ang) * rad

		local nearFocus = isInsideEllipse(x, z, FOCUS_CENTER, FOCUS_RX, FOCUS_RZ, 1.8)
		local nearInstinct = isInsideEllipse(x, z, INSTINCT_CENTER, INSTINCT_RX, INSTINCT_RZ, 1.8)
		local nearWalk = math.abs(x - (0.25 * (24.0 - z) - 2.8)) < 4.9 and z > -5 and z < 26

		if not nearFocus and not nearInstinct and not nearWalk and not isOnPortalSandPath(x, z) then
			local basePos = origin + Vector3.new(x, 0.02, z)
			local tuftColor = if rng:NextNumber() > 0.45
				then PALETTE.GrassWarm
				else PALETTE.GrassDeep
			for b = 1, 3 do
				local yaw = rng:NextNumber(0, math.pi * 2)
				local tilt = math.rad(rng:NextNumber(14, 28))
				local h = rng:NextNumber(0.50, 1.10)
				local blade = makeWedge(
					decoFolder,
					"GrassBlade_" .. tostring(i) .. "_" .. tostring(b),
					CFrame.new(
						basePos
							+ Vector3.new(
								rng:NextNumber(-0.25, 0.25),
								h * 0.42,
								rng:NextNumber(-0.25, 0.25)
							)
					)
						* CFrame.Angles(0, yaw, 0)
						* CFrame.Angles(tilt, 0, 0),
					Vector3.new(0.16, h, 0.40),
					tuftColor,
					Enum.Material.SmoothPlastic,
					false,
					0
				)
				blade.CastShadow = false
			end

			if i % 4 == 0 then
				local fCol = flowerColors[(i % #flowerColors) + 1]
				local flower = makeEllipsoid(
					decoFolder,
					"Wildflower_" .. tostring(i),
					CFrame.new(basePos + Vector3.new(0.35, 0.26, -0.2)),
					Vector3.new(0.46, 0.20, 0.46),
					fCol,
					Enum.Material.SmoothPlastic,
					false,
					0
				)
				flower.CastShadow = false
				local center = makeEllipsoid(
					decoFolder,
					"WildflowerCenter_" .. tostring(i),
					CFrame.new(basePos + Vector3.new(0.35, 0.34, -0.2)),
					Vector3.new(0.18, 0.14, 0.18),
					PALETTE.AmberGlow,
					Enum.Material.SmoothPlastic,
					false,
					0
				)
				center.CastShadow = false
			end

			if i % 11 == 0 then
				local pebble = makeEllipsoid(
					decoFolder,
					"GrassPebble_" .. tostring(i),
					CFrame.new(basePos + Vector3.new(-0.4, 0.12, 0.35))
						* CFrame.Angles(0, rng:NextNumber(0, 6), 0),
					Vector3.new(0.75, 0.34, 0.62),
					PALETTE.StoneMid,
					Enum.Material.Concrete,
					false,
					0
				)
				pebble.CastShadow = false
			end
		end
	end

	-- Conchinhas, pedrinhas e estrelas-do-mar na faixa de areia da frente
	for i = 1, 24 do
		local ang = rng:NextNumber(1.12, 2.78)
		local outerR = getIslandRadius(ang)
		local bw = getBeachWidth(ang)
		local rad = rng:NextNumber(outerR - bw + 1.4, outerR - 1.8)
		local x = math.cos(ang) * rad
		local z = math.sin(ang) * rad
		if math.abs(x - PORTAL_LOCAL.X) > 4.6 or math.abs(z - PORTAL_LOCAL.Z) > 4.6 then
			local kind = i % 4
			if kind == 0 then
				-- Estrelinha-do-mar coral na areia
				local starPos = origin + Vector3.new(x, -0.15, z)
				for arm = 0, 4 do
					local armAng = math.rad(arm * 72) + rng:NextNumber(-0.1, 0.1)
					local leg = makeEllipsoid(
						decoFolder,
						"Starfish_" .. tostring(i) .. "_" .. tostring(arm),
						CFrame.new(starPos) * CFrame.Angles(0, armAng, 0) * CFrame.new(0, 0, 0.28),
						Vector3.new(0.24, 0.14, 0.68),
						Color3.fromRGB(246, 134, 108),
						Enum.Material.SmoothPlastic,
						false,
						0
					)
					leg.CastShadow = false
				end
			else
				local isShell = kind == 1
				local item = makeEllipsoid(
					decoFolder,
					(if isShell then "Shell_" else "SandPebble_") .. tostring(i),
					CFrame.new(origin + Vector3.new(x, -0.16, z))
						* CFrame.Angles(0, rng:NextNumber(0, 6), 0),
					if isShell then Vector3.new(0.68, 0.26, 0.56) else Vector3.new(0.82, 0.30, 0.68),
					if isShell then Color3.fromRGB(255, 214, 224) else PALETTE.StoneLight,
					Enum.Material.SmoothPlastic,
					false,
					0
				)
				item.CastShadow = false
			end
		end
	end
end

-- ============================================================================
-- 2. ROCHA ORGÂNICA MARROM QUENTE, CRISTAIS CIANO, RAÍZES E 2 CACHOEIRAS
-- ============================================================================

local function buildHexCrystal(
	parent: Instance,
	name: string,
	baseCf: CFrame,
	radius: number,
	height: number,
	outerColor: Color3,
	coreColor: Color3,
	canCollide: boolean?
): Model
	local shard = makeModel(parent, name)
	local collide = if canCollide == nil then true else canCollide
	local shaftH = height * 0.66
	local tipH = height * 0.34
	-- Prisma hexagonal regular real: 3 prismas retangulares girados em 0°, 60° e 120°
	local flatWidth = radius * 1.1547
	local depthSpan = radius * 2.0

	for k = 0, 2 do
		local rot = CFrame.Angles(0, math.rad(k * 60), 0)
		local p = makePart(
			shard,
			"HexShaft_" .. tostring(k + 1),
			baseCf * rot * CFrame.new(0, shaftH * 0.5, 0),
			Vector3.new(flatWidth, shaftH, depthSpan),
			outerColor,
			Enum.Material.SmoothPlastic,
			collide,
			0.34
		)
		p.Reflectance = 0.30
		p.CastShadow = false
		if k == 0 then
			shard.PrimaryPart = p
		end
	end

	-- Ponta piramidal hexagonal (6 cunhas convergindo no vértice)
	for s = 0, 5 do
		local ang = math.rad(s * 60)
		local tipW = makeWedge(
			shard,
			"HexTip_" .. tostring(s + 1),
			baseCf * CFrame.Angles(0, ang, 0) * CFrame.new(0, shaftH + tipH * 0.5, -radius * 0.44),
			Vector3.new(flatWidth * 0.96, tipH, radius * 0.92),
			outerColor,
			Enum.Material.SmoothPlastic,
			collide,
			0.34
		)
		tipW.Reflectance = 0.30
		tipW.CastShadow = false
	end

	-- Núcleo emissivo ciano-translúcido interno (brilho de gema sem estourar em barra branca)
	local coreR = radius * 0.34
	local coreFlat = coreR * 1.1547
	local coreDepth = coreR * 2.0
	local gemCoreCol = outerColor:Lerp(coreColor, 0.35)
	for k = 0, 2 do
		local rot = CFrame.Angles(0, math.rad(k * 60 + 30), 0)
		local cp = makePart(
			shard,
			"CoreShaft_" .. tostring(k + 1),
			baseCf * rot * CFrame.new(0, shaftH * 0.52, 0),
			Vector3.new(coreFlat, shaftH * 0.90, coreDepth),
			gemCoreCol,
			Enum.Material.Neon,
			false,
			0.44
		)
		cp.CastShadow = false
	end
	for s = 0, 2 do
		local ang = math.rad(s * 120)
		local ct = makeWedge(
			shard,
			"CoreTip_" .. tostring(s + 1),
			baseCf * CFrame.Angles(0, ang, 0) * CFrame.new(0, shaftH + tipH * 0.40, -coreR * 0.42),
			Vector3.new(coreFlat, tipH * 0.84, coreR * 0.88),
			gemCoreCol,
			Enum.Material.Neon,
			false,
			0.44
		)
		ct.CastShadow = false
	end

	return shard
end

local function buildRockUnderside(root: Model, origin: Vector3, rng: Random)
	local folder = makeFolder(root, "RockUnderside")
	local rockUpperColors = { PALETTE.RockLight, PALETTE.RockMid }
	local rockMidColors = { PALETTE.RockMid, PALETTE.RockDark }
	local rockLowerColors = { PALETTE.RockDark, PALETTE.RockDeep }

	-- Núcleo sólido cônico marrom-escuro recuado (elimina frestas e cria rachaduras escuras entre blocos)
	local coreTiers = {
		{ name = "CoreTier1", y = -3.4, h = 3.8, diam = 88.0 },
		{ name = "CoreTier2", y = -6.6, h = 3.6, diam = 74.0 },
		{ name = "CoreTier3", y = -9.4, h = 3.2, diam = 54.0 },
		{ name = "CoreTier4", y = -11.4, h = 2.4, diam = 32.0 },
	}
	for _, ct in ipairs(coreTiers) do
		makeCylinderY(
			folder,
			ct.name,
			CFrame.new(origin + Vector3.new(0, ct.y, 0)),
			ct.h,
			ct.diam,
			PALETTE.RockShadow,
			Enum.Material.Concrete,
			true,
			0
		)
	end

	-- 4 camadas contínuas de blocos de rocha marrom-terracota quente afinando como um pião achatado
	-- Raio superior alinhado à borda (sem degrau), descendo em blocos arredondados/rachados até a ponta
	local tiers = {
		{
			count = 28,
			rScale = 1.025,
			yMin = -3.8,
			yMax = -3.1,
			widthScale = 1.06,
			height = 4.35,
			depth = 7.8,
			inwardTilt = 9,
			colors = rockUpperColors,
			mat = Enum.Material.Concrete,
		},
		{
			count = 22,
			rScale = 0.925,
			yMin = -7.0,
			yMax = -6.2,
			widthScale = 1.12,
			height = 4.55,
			depth = 8.4,
			inwardTilt = 21,
			colors = rockMidColors,
			mat = Enum.Material.Concrete,
		},
		{
			count = 16,
			rScale = 0.74,
			yMin = -9.9,
			yMax = -9.0,
			widthScale = 1.18,
			height = 4.15,
			depth = 8.4,
			inwardTilt = 33,
			colors = rockLowerColors,
			mat = Enum.Material.Concrete,
		},
		{
			count = 10,
			rScale = 0.48,
			yMin = -11.7,
			yMax = -10.9,
			widthScale = 1.25,
			height = 3.2,
			depth = 7.4,
			inwardTilt = 46,
			colors = rockLowerColors,
			mat = Enum.Material.Concrete,
		},
	}

	local function angleDiff(a: number, b: number): number
		local d = (a - b + math.pi) % (math.pi * 2) - math.pi
		return math.abs(d)
	end

	for tIdx, tier in ipairs(tiers) do
		local arcStep = (math.pi * 2) / tier.count
		for i = 1, tier.count do
			local ang = (i / tier.count) * math.pi * 2 + tIdx * 0.24 + rng:NextNumber(-0.04, 0.04)
			-- Abre fenda natural limpa para as 2 cachoeiras (evita pedra cortando o fluxo da água)
			local inWaterfallNotch = tIdx <= 2
				and (angleDiff(ang, 1.96) < 0.095 or angleDiff(ang, 0.88) < 0.095)
			if inWaterfallNotch then
				continue
			end

			local baseR = getIslandRadius(ang) * tier.rScale
			local rJitter = rng:NextNumber(-0.65, 0.60)
			local r = baseR + rJitter
			local y = rng:NextNumber(tier.yMin, tier.yMax)
			local dirOut = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local pos = origin + dirOut * (r - tier.depth * 0.45) + Vector3.new(0, y, 0)

			local chordW = baseR * arcStep * tier.widthScale * rng:NextNumber(0.88, 1.06)
			local blkH = tier.height * rng:NextNumber(0.88, 1.14)
			local blkD = tier.depth * rng:NextNumber(0.90, 1.12)

			local col = tier.colors[((i + tIdx) % #tier.colors) + 1]
			local useMat = if i % 4 == 0 then Enum.Material.Sandstone else tier.mat

			-- Orientação: -Z aponta para fora; inclinamos a base para dentro (pião achatado)
			local baseCf = CFrame.lookAt(pos, pos + dirOut)
				* CFrame.Angles(
					math.rad(-tier.inwardTilt + rng:NextNumber(-5, 5)),
					math.rad(rng:NextNumber(-6, 6)),
					math.rad(rng:NextNumber(-5, 5))
				)

			-- Corpo estrutural interno recuado (solidez sem cantos quadrados espetados)
			makePart(
				folder,
				"CliffBlock_" .. tostring(tIdx) .. "_" .. tostring(i),
				baseCf * CFrame.new(0, 0, blkD * 0.14),
				Vector3.new(chordW * 0.80, blkH * 0.88, blkD * 0.74),
				col,
				useMat,
				tIdx <= 2,
				0
			)

			-- Volume arredondado principal (pedra grossa orgânica e acolhedora da referência)
			local shoulderCol = if tIdx == 1
				then PALETTE.RockLight
				elseif tIdx == 2 then PALETTE.RockMid
				else PALETTE.RockDark
			makeEllipsoid(
				folder,
				"CliffBelly_" .. tostring(tIdx) .. "_" .. tostring(i),
				baseCf * CFrame.new(rng:NextNumber(-0.35, 0.35), 0.08 * blkH, -blkD * 0.12),
				Vector3.new(chordW * 1.08, blkH * 1.06, blkD * 0.94),
				shoulderCol,
				useMat,
				false,
				0
			)

			-- Quebra angular inferior (faceta estilizada de pedra rachada)
			makeWedge(
				folder,
				"CliffBevel_" .. tostring(tIdx) .. "_" .. tostring(i),
				baseCf
					* CFrame.new(rng:NextNumber(-0.4, 0.4), -blkH * 0.18, -blkD * 0.30)
					* CFrame.Angles(math.rad(180), 0, math.rad(rng:NextNumber(-7, 7))),
				Vector3.new(chordW * 0.72, blkH * 0.64, blkD * 0.42),
				if tIdx == 1 then PALETTE.RockMid else PALETTE.RockDark,
				useMat,
				false,
				0
			)

			-- Tufos de musgo e pequenas pedras de cascalho como detalhe nas juntas
			if tIdx == 1 and i % 5 == 0 then
				local moss = makeEllipsoid(
					folder,
					"CliffMoss_" .. tostring(i),
					baseCf * CFrame.new(0, blkH * 0.44, -blkD * 0.34),
					Vector3.new(3.0, 0.9, 2.3),
					PALETTE.MossGreen,
					Enum.Material.Grass,
					false,
					0
				)
				moss.CastShadow = false
			end
			if tIdx == 2 and i % 4 == 0 then
				local chip = makeEllipsoid(
					folder,
					"GravelLedge_" .. tostring(i),
					baseCf * CFrame.new(rng:NextNumber(-1.4, 1.4), blkH * 0.46, -blkD * 0.42),
					Vector3.new(1.9, 1.0, 1.6),
					PALETTE.RockLight,
					Enum.Material.Concrete,
					false,
					0
				)
				chip.CastShadow = false
			end
		end
	end

	-- Ponta irregular inferior (quilha rochosa afinando sobre a água)
	local apexSpecs = {
		{
			off = Vector3.new(0, -11.9, 0),
			sz = Vector3.new(18.0, 2.8, 18.0),
			rot = Vector3.new(4, 20, -3),
		},
		{
			off = Vector3.new(-3.6, -12.1, 2.8),
			sz = Vector3.new(10.5, 2.4, 9.6),
			rot = Vector3.new(-8, 45, 6),
		},
		{
			off = Vector3.new(4.0, -12.0, -2.0),
			sz = Vector3.new(9.8, 2.3, 10.0),
			rot = Vector3.new(6, -30, -7),
		},
	}
	for idx, ap in ipairs(apexSpecs) do
		makePart(
			folder,
			"BottomApex_" .. tostring(idx),
			CFrame.new(origin + ap.off)
				* CFrame.Angles(math.rad(ap.rot.X), math.rad(ap.rot.Y), math.rad(ap.rot.Z)),
			ap.sz,
			if idx == 1 then PALETTE.RockDeep else PALETTE.RockShadow,
			Enum.Material.Concrete,
			true,
			0
		)
	end

	-- Cristais ciano encravados na rocha, MAIORES e mais numerosos (9 clusters bem visíveis)
	local crystalFolder = makeFolder(folder, "UndersideCrystals")
	local crystalSpecs = {
		-- Frente-esquerda e flanco esquerdo
		{ ang = 2.74, y = -3.8, rFactor = 1.03, rad = 1.75, h = 5.6, light = true },
		{ ang = 2.34, y = -4.6, rFactor = 1.01, rad = 2.15, h = 6.8, light = true },
		{ ang = 2.12, y = -6.8, rFactor = 0.94, rad = 1.45, h = 4.6, light = false },
		-- Frente-centro
		{ ang = 1.64, y = -5.6, rFactor = 0.99, rad = 2.05, h = 6.4, light = true },
		{ ang = 1.48, y = -7.8, rFactor = 0.90, rad = 1.40, h = 4.4, light = false },
		-- Frente-direita (cluster herói grande igual à referência A!)
		{ ang = 1.18, y = -5.4, rFactor = 1.00, rad = 2.45, h = 7.6, light = true },
		{ ang = 0.56, y = -4.3, rFactor = 1.02, rad = 1.95, h = 6.0, light = true },
		-- Costas/laterais para 360°
		{ ang = 3.65, y = -4.8, rFactor = 1.00, rad = 1.70, h = 5.4, light = false },
		{ ang = 5.15, y = -5.0, rFactor = 1.00, rad = 1.80, h = 5.8, light = false },
	}

	for idx, cs in ipairs(crystalSpecs) do
		local r = getIslandRadius(cs.ang) * cs.rFactor
		local basePos = origin + Vector3.new(math.cos(cs.ang) * r, cs.y, math.sin(cs.ang) * r)
		local outDir = Vector3.new(math.cos(cs.ang), -0.10, math.sin(cs.ang)).Unit
		local mainCf = CFrame.lookAt(basePos - outDir * 1.4, basePos + outDir)
			* CFrame.Angles(math.rad(-90), 0, 0)

		buildHexCrystal(
			crystalFolder,
			"CliffCrystalMain_" .. tostring(idx),
			mainCf,
			cs.rad,
			cs.h,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			false
		)

		-- 2 cristais menores acompanhando o cluster
		for sub = 1, 2 do
			local sAng = cs.ang + (if sub == 1 then -0.075 else 0.075)
			local sPos = basePos
				+ Vector3.new(
					rng:NextNumber(-1.8, 1.8),
					rng:NextNumber(-1.0, 1.1),
					rng:NextNumber(-1.8, 1.8)
				)
			local sOut =
				Vector3.new(math.cos(sAng), rng:NextNumber(-0.28, 0.14), math.sin(sAng)).Unit
			local sCf = CFrame.lookAt(sPos - sOut * 0.9, sPos + sOut)
				* CFrame.Angles(math.rad(-90), 0, 0)
			buildHexCrystal(
				crystalFolder,
				"CliffCrystalSub_" .. tostring(idx) .. "_" .. tostring(sub),
				sCf,
				cs.rad * 0.56,
				cs.h * 0.58,
				PALETTE.CrystalIce,
				PALETTE.CrystalCyan,
				false
			)
		end

		if cs.light then
			local glowPt = makePart(
				crystalFolder,
				"CrystalLight_" .. tostring(idx),
				CFrame.new(basePos + outDir * 2.4),
				Vector3.new(0.4, 0.4, 0.4),
				PALETTE.CrystalCyan,
				Enum.Material.SmoothPlastic,
				false,
				1
			)
			glowPt.CanQuery = false
			local pl = Instance.new("PointLight")
			pl.Color = PALETTE.CrystalCyan
			pl.Brightness = 1.25
			pl.Range = 14
			pl.Parent = glowPt
		end
	end

	-- Raízes finas e escuras saindo por baixo das rochas (visíveis contra o mar turquesa)
	local rootsFolder = makeFolder(folder, "HangingRoots")
	local rootSpecs = {
		{ ang = 2.46, yStart = -5.4, rFactor = 0.98, len = 6.2 },
		{ ang = 2.26, yStart = -6.0, rFactor = 0.94, len = 5.6 },
		{ ang = 1.76, yStart = -6.6, rFactor = 0.92, len = 5.2 },
		{ ang = 1.38, yStart = -6.8, rFactor = 0.91, len = 5.0 },
		{ ang = 0.72, yStart = -5.4, rFactor = 0.97, len = 6.2 },
		{ ang = 0.54, yStart = -5.8, rFactor = 0.95, len = 5.6 },
		{ ang = 1.04, yStart = -6.4, rFactor = 0.92, len = 5.2 },
	}
	for rIdx, rs in ipairs(rootSpecs) do
		local r = getIslandRadius(rs.ang) * rs.rFactor
		local cur = origin + Vector3.new(math.cos(rs.ang) * r, rs.yStart, math.sin(rs.ang) * r)
		local segs = 5
		for s = 1, segs do
			local nextPt = cur
				+ Vector3.new(
					rng:NextNumber(-0.85, 0.85),
					-(rs.len / segs),
					rng:NextNumber(-0.85, 0.85)
				)
			local thick = 0.56 * (1 - (s - 1) / (segs + 1.4))
			makeSegment(
				rootsFolder,
				"Root_" .. tostring(rIdx) .. "_" .. tostring(s),
				cur,
				nextPt,
				thick,
				PALETTE.RootDark,
				Enum.Material.Wood,
				true,
				false
			)
			if s == 2 or s == 3 then
				local bEnd = nextPt
					+ Vector3.new(
						rng:NextNumber(-1.6, 1.6),
						-rng:NextNumber(0.9, 1.8),
						rng:NextNumber(-1.6, 1.6)
					)
				makeSegment(
					rootsFolder,
					"RootTwig_" .. tostring(rIdx) .. "_" .. tostring(s),
					nextPt,
					bEnd,
					thick * 0.55,
					PALETTE.RootDark,
					Enum.Material.Wood,
					true,
					false
				)
			end
			cur = nextPt
		end
	end

	-- Duas cachoeiras finas translúcidas com fluxo ondulado em camadas, espuma, névoa e ondulação no mar
	local fallsFolder = makeFolder(folder, "Waterfalls")
	local waterfallSpecs = {
		{ name = "Waterfall_FrontLeft", ang = 1.96, width = 3.1, drop = 10.6 },
		{ name = "Waterfall_FrontRight", ang = 0.88, width = 2.8, drop = 10.6 },
	}

	for _, wf in ipairs(waterfallSpecs) do
		local wfModel = makeModel(fallsFolder, wf.name)
		local r = getIslandRadius(wf.ang) * 0.985
		local dir = Vector3.new(math.cos(wf.ang), 0, math.sin(wf.ang))
		local spoutPos = origin + dir * r + Vector3.new(0, -1.45, 0)
		local cf = CFrame.lookAt(spoutPos, spoutPos + dir)

		-- Pedras esculpidas emoldurando a fenda da cachoeira
		makePart(
			wfModel,
			"NotchRockL",
			cf * CFrame.new(-wf.width * 0.68, -0.45, 0.35) * CFrame.Angles(0, 0, math.rad(10)),
			Vector3.new(2.2, 2.9, 2.6),
			PALETTE.RockDark,
			Enum.Material.Concrete,
			false,
			0
		)
		makePart(
			wfModel,
			"NotchRockR",
			cf * CFrame.new(wf.width * 0.68, -0.45, 0.35) * CFrame.Angles(0, 0, math.rad(-10)),
			Vector3.new(2.2, 2.9, 2.6),
			PALETTE.RockDark,
			Enum.Material.Concrete,
			false,
			0
		)

		-- Crista espumosa saindo da rocha
		local lip = makeEllipsoid(
			wfModel,
			"SpoutCrest",
			cf * CFrame.new(0, -0.15, -0.95),
			Vector3.new(wf.width * 1.05, 1.15, 2.3),
			PALETTE.WaterfallLight,
			Enum.Material.SmoothPlastic,
			false,
			0.28
		)
		lip.CastShadow = false

		-- Fluxo em 5 faixas finas levemente onduladas com transparências variadas (sem barras chapadas)
		local streamRibbons = {
			{
				xOff = 0.0,
				zOff = -1.65,
				w = 0.92,
				col = PALETTE.WaterfallBlue,
				trans = 0.42,
				phase = 0.0,
			},
			{
				xOff = -0.26,
				zOff = -1.85,
				w = 0.34,
				col = PALETTE.WaterfallLight,
				trans = 0.52,
				phase = 0.9,
			},
			{
				xOff = 0.24,
				zOff = -1.82,
				w = 0.32,
				col = PALETTE.WaterfallLight,
				trans = 0.56,
				phase = 2.1,
			},
			{
				xOff = -0.08,
				zOff = -1.98,
				w = 0.22,
				col = PALETTE.WaterfallFoam,
				trans = 0.64,
				phase = 3.4,
			},
			{
				xOff = 0.14,
				zOff = -1.96,
				w = 0.18,
				col = PALETTE.WaterfallFoam,
				trans = 0.68,
				phase = 4.7,
			},
		}
		local segs = 6
		for rIdx, rib in ipairs(streamRibbons) do
			for s = 1, segs do
				local t0 = (s - 1) / segs
				local t1 = s / segs
				local tMid = (t0 + t1) * 0.5
				local segH = (wf.drop / segs) + 0.24
				-- Arco suave na saída que vai ficando vertical e ondula levemente
				local archOut = math.sin(math.min(tMid * 2.2, 1.0) * math.pi * 0.5) * 0.72
				local waveZ = math.sin(tMid * math.pi * 3.0 + rib.phase) * 0.14
				local waveX = math.cos(tMid * math.pi * 2.5 + rib.phase) * 0.09
				local widthTaper = 1.0 - tMid * 0.14 + math.sin(tMid * math.pi * 2.0) * 0.06
				local segTilt = if s == 1 then math.rad(22) elseif s == 2 then math.rad(8) else 0

				local seg = makePart(
					wfModel,
					"Stream_" .. tostring(rIdx) .. "_" .. tostring(s),
					cf
						* CFrame.new(
							wf.width * rib.xOff + waveX,
							-tMid * wf.drop - 0.15,
							rib.zOff - archOut + waveZ
						)
						* CFrame.Angles(segTilt, 0, 0),
					Vector3.new(wf.width * rib.w * widthTaper, segH, 0.26),
					rib.col,
					Enum.Material.SmoothPlastic,
					false,
					rib.trans
				)
				seg.Reflectance = 0.12
				seg.CastShadow = false
			end
		end

		-- Espuma fofa na base (exatamente no nível do oceano Y = origin.Y - 12.0)
		local splashCenterCf = cf * CFrame.new(0, -wf.drop + 0.15, -2.35)
		local splashCore = makeEllipsoid(
			wfModel,
			"BaseSplashFoam",
			splashCenterCf,
			Vector3.new(wf.width * 1.95, 0.95, 2.75),
			PALETTE.WaterfallFoam,
			Enum.Material.SmoothPlastic,
			false,
			0.26
		)
		splashCore.CastShadow = false

		-- Puffs extras de espuma fofa em volta da queda
		local puffOffs = {
			{ x = -1.25, y = -0.1, z = -0.5, sz = Vector3.new(2.1, 0.75, 1.9), tr = 0.36 },
			{ x = 1.30, y = -0.08, z = -0.4, sz = Vector3.new(2.0, 0.72, 1.85), tr = 0.38 },
			{ x = 0.15, y = 0.12, z = -1.05, sz = Vector3.new(2.4, 0.65, 1.7), tr = 0.44 },
		}
		for pIdx, pf in ipairs(puffOffs) do
			local puff = makeEllipsoid(
				wfModel,
				"SplashPuff_" .. tostring(pIdx),
				splashCenterCf * CFrame.new(pf.x, pf.y, pf.z),
				pf.sz,
				PALETTE.WaterfallFoam,
				Enum.Material.SmoothPlastic,
				false,
				pf.tr
			)
			puff.CastShadow = false
		end

		-- Pequenas ondulações concêntricas no mar onde a cachoeira cai
		makeNeonRing(
			wfModel,
			"SeaRippleInner",
			splashCenterCf * CFrame.new(0, -0.22, -0.3),
			wf.width * 1.05,
			0.18,
			0.05,
			22,
			PALETTE.WaterfallFoam,
			0.46
		)
		makeNeonRing(
			wfModel,
			"SeaRippleOuter",
			splashCenterCf * CFrame.new(0, -0.24, -0.3),
			wf.width * 1.55,
			0.12,
			0.04,
			24,
			PALETTE.WaterfallLight,
			0.66
		)

		-- Emissor leve de gotículas e névoa suave na queda e na base
		local fallMist = Instance.new("ParticleEmitter")
		fallMist.Name = "WaterfallSpray"
		fallMist.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, PALETTE.WaterfallFoam),
			ColorSequenceKeypoint.new(1, PALETTE.WaterfallBlue),
		})
		fallMist.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.38),
			NumberSequenceKeypoint.new(1, 1.45),
		})
		fallMist.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.7, 0.78),
			NumberSequenceKeypoint.new(1, 1),
		})
		fallMist.Lifetime = NumberRange.new(0.85, 1.25)
		fallMist.Speed = NumberRange.new(7, 11)
		fallMist.EmissionDirection = Enum.NormalId.Bottom
		fallMist.SpreadAngle = Vector2.new(12, 12)
		fallMist.Rate = 12
		fallMist.LightEmission = 0.25
		fallMist.Parent = lip

		local baseMist = Instance.new("ParticleEmitter")
		baseMist.Name = "SplashMist"
		baseMist.Color = ColorSequence.new(PALETTE.WaterfallFoam)
		baseMist.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.85),
			NumberSequenceKeypoint.new(1, 2.9),
		})
		baseMist.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.52),
			NumberSequenceKeypoint.new(1, 1),
		})
		baseMist.Lifetime = NumberRange.new(0.95, 1.55)
		baseMist.Speed = NumberRange.new(1.2, 2.8)
		baseMist.EmissionDirection = Enum.NormalId.Top
		baseMist.SpreadAngle = Vector2.new(68, 68)
		baseMist.Rate = 11
		baseMist.Parent = splashCore
	end
end

-- ============================================================================
-- 3. DECK DE MADEIRA ENVELHECIDA COM BANQUINHO & ESTACAS COM CORDA
-- ============================================================================

local function buildWoodenDeck(
	parent: Instance,
	name: string,
	deckCf: CFrame,
	width: number,
	depth: number,
	rng: Random
): Model
	local deck = makeModel(parent, name)
	local plankCount = 7
	local stepZ = depth / plankCount
	local woodTones =
		{ PALETTE.WoodWarm1, PALETTE.WoodWarm2, PALETTE.WoodWarm3, PALETTE.WoodWeathered }

	-- Longarinas estruturais
	makePart(
		deck,
		"BeamL",
		deckCf * CFrame.new(-width * 0.36, -0.34, 0),
		Vector3.new(0.62, 0.52, depth * 0.94),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		true,
		0
	)
	makePart(
		deck,
		"BeamR",
		deckCf * CFrame.new(width * 0.36, -0.34, 0),
		Vector3.new(0.62, 0.52, depth * 0.94),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		true,
		0
	)

	-- Tábuas variadas com leve folga artesanal
	for i = 1, plankCount do
		local zOff = -depth * 0.5 + (i - 0.5) * stepZ
		local wVar = width + rng:NextNumber(-0.22, 0.32)
		local yaw = math.rad(rng:NextNumber(-1.0, 1.0))
		local plank = makePart(
			deck,
			"Plank_" .. tostring(i),
			deckCf * CFrame.new(rng:NextNumber(-0.08, 0.08), 0, zOff) * CFrame.Angles(0, yaw, 0),
			Vector3.new(wVar, 0.34, stepZ - 0.14),
			woodTones[((i - 1) % #woodTones) + 1],
			Enum.Material.WoodPlanks,
			true,
			0
		)
		if i == 4 then
			deck.PrimaryPart = plank
		end
	end

	-- 4 estacas grossas com nó de corda enrolado no topo
	local postOffsets = {
		Vector3.new(-width * 0.44, -1.25, -depth * 0.44),
		Vector3.new(width * 0.44, -1.25, -depth * 0.44),
		Vector3.new(-width * 0.44, -1.25, depth * 0.44),
		Vector3.new(width * 0.44, -1.25, depth * 0.44),
	}
	for idx, off in ipairs(postOffsets) do
		local postCf = deckCf * CFrame.new(off)
		makeCylinderY(
			deck,
			"Piling_" .. tostring(idx),
			postCf,
			4.4,
			0.92,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			true,
			0
		)
		makeCylinderY(
			deck,
			"PilingCap_" .. tostring(idx),
			postCf * CFrame.new(0, 2.25, 0),
			0.18,
			0.96,
			PALETTE.WoodWarm3,
			Enum.Material.Wood,
			false,
			0
		)
		addRopeCoil(
			deck,
			"PilingRope_" .. tostring(idx),
			(postCf * CFrame.new(0, 1.72, 0)).Position,
			0.92,
			3
		)
	end

	-- Banquinho redondo de 3 pernas inclinadas
	local stoolCf = deckCf * CFrame.new(0.25, 0.18, 0.1)
	makeCylinderY(
		deck,
		"StoolTop",
		stoolCf * CFrame.new(0, 1.48, 0),
		0.32,
		2.25,
		PALETTE.WoodWarm3,
		Enum.Material.WoodPlanks,
		true,
		0
	)
	makeCylinderY(
		deck,
		"StoolRim",
		stoolCf * CFrame.new(0, 1.28, 0),
		0.14,
		1.95,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)
	for leg = 1, 3 do
		local a = (leg / 3) * math.pi * 2 + 0.35
		local topPt = (stoolCf * CFrame.new(math.cos(a) * 0.56, 1.32, math.sin(a) * 0.56)).Position
		local botPt = (stoolCf * CFrame.new(math.cos(a) * 0.92, 0.0, math.sin(a) * 0.92)).Position
		makeSegment(
			deck,
			"StoolLeg_" .. tostring(leg),
			topPt,
			botPt,
			0.26,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			true,
			false
		)
	end

	return deck
end

local function buildConeBuoy(parent: Instance, name: string, cf: CFrame): Model
	local buoy = makeModel(parent, name)
	local base = makeCylinderY(
		buoy,
		"FloatBase",
		cf,
		0.45,
		2.05,
		PALETTE.BuoyOrange,
		Enum.Material.SmoothPlastic,
		false,
		0
	)
	buoy.PrimaryPart = base

	local layers = {
		{ y = 0.38, h = 0.38, d = 1.62, c = PALETTE.BuoyOrange },
		{ y = 0.74, h = 0.36, d = 1.30, c = PALETTE.BuoyWhite },
		{ y = 1.08, h = 0.34, d = 0.98, c = PALETTE.BuoyOrange },
		{ y = 1.40, h = 0.32, d = 0.66, c = PALETTE.BuoyWhite },
		{ y = 1.68, h = 0.28, d = 0.36, c = PALETTE.BuoyOrange },
	}
	for idx, layer in ipairs(layers) do
		makeCylinderY(
			buoy,
			"Cone_" .. tostring(idx),
			cf * CFrame.new(0, layer.y, 0),
			layer.h,
			layer.d,
			layer.c,
			Enum.Material.SmoothPlastic,
			false,
			0
		)
	end
	local tip = makeEllipsoid(
		buoy,
		"Tip",
		cf * CFrame.new(0, 1.90, 0),
		Vector3.new(0.28, 0.28, 0.28),
		PALETTE.BuoyOrange,
		Enum.Material.SmoothPlastic,
		false,
		0
	)
	tip.CastShadow = false

	-- Ondinhas concêntricas suaves em volta da boia
	makeNeonRing(
		buoy,
		"RippleInner",
		cf * CFrame.new(0, -0.02, 0),
		1.38,
		0.12,
		0.05,
		18,
		Color3.fromRGB(232, 252, 255),
		0.25
	)
	makeNeonRing(
		buoy,
		"RippleOuter",
		cf * CFrame.new(0, -0.04, 0),
		1.95,
		0.08,
		0.04,
		20,
		Color3.fromRGB(204, 248, 255),
		0.55
	)

	return buoy
end

local function buildRopeFence(parent: Instance, name: string, postPositions: { Vector3 })
	local fence = makeModel(parent, name)
	for i, p in ipairs(postPositions) do
		local post = makeCylinderY(
			fence,
			"FencePost_" .. tostring(i),
			CFrame.new(p + Vector3.new(0, 1.55, 0)),
			3.3,
			0.94,
			PALETTE.WoodWarm2,
			Enum.Material.Wood,
			true,
			0
		)
		makeEllipsoid(
			fence,
			"PostTopRound_" .. tostring(i),
			CFrame.new(p + Vector3.new(0, 3.22, 0)),
			Vector3.new(0.94, 0.38, 0.94),
			PALETTE.WoodWarm3,
			Enum.Material.Wood,
			false,
			0
		)
		addRopeCoil(fence, "PostRopeCoil_" .. tostring(i), p + Vector3.new(0, 2.55, 0), 0.94, 3)
		if i == 1 then
			fence.PrimaryPart = post
		end

		if i < #postPositions then
			local pNext = postPositions[i + 1]
			local startPt = p + Vector3.new(0, 2.55, 0)
			local endPt = pNext + Vector3.new(0, 2.55, 0)
			local segs = 8
			local sag = 1.15
			local prev = startPt
			for s = 1, segs do
				local t = s / segs
				local pt = startPt:Lerp(endPt, t) - Vector3.new(0, 4 * sag * t * (1 - t), 0)
				makeSegment(
					fence,
					"Rope_" .. tostring(i) .. "_" .. tostring(s),
					prev,
					pt,
					0.36,
					PALETTE.RopeTan,
					Enum.Material.Fabric,
					true,
					false
				)
				prev = pt
			end
		end
	end
end

-- ============================================================================
-- 4. LAGOA DO FOCO (CONTROLE) — MODELO DIRETO `FocusPond`
-- ============================================================================

local function buildFocusPond(root: Model, origin: Vector3, rng: Random): Model
	local pond = makeModel(root, "FocusPond")
	local centerPos = origin + Vector3.new(FOCUS_CENTER.X, 0, FOCUS_CENTER.Y)

	-- Fundo turquesa luminoso
	local floor = makeEllipsoid(
		pond,
		"PondFloor",
		CFrame.new(centerPos + Vector3.new(0, -1.75, 0)),
		Vector3.new(FOCUS_RX * 1.98, 0.7, FOCUS_RZ * 1.98),
		PALETTE.FocusFloor,
		Enum.Material.Sand,
		true,
		0
	)
	floor.CastShadow = false
	pond.PrimaryPart = floor

	-- Padrão de células hexagonais luminosas no fundo da lagoa (visíveis através da água cristalina!)
	local hexFolder = makeFolder(pond, "WaterCellPattern")
	local hexR = 2.65
	local dx = hexR * 1.75
	local dz = hexR * 1.52
	local row = 0
	for zOff = -FOCUS_RZ + 2.0, FOCUS_RZ - 2.0, dz do
		row += 1
		local xShift = if row % 2 == 0 then dx * 0.5 else 0
		for xOff = -FOCUS_RX + 2.0, FOCUS_RX - 2.0, dx do
			local hx = xOff + xShift
			if
				isInsideEllipse(
					FOCUS_CENTER.X + hx,
					FOCUS_CENTER.Y + zOff,
					FOCUS_CENTER,
					FOCUS_RX - 1.8,
					FOCUS_RZ - 1.8,
					0
				)
			then
				makeNeonRing(
					hexFolder,
					"HexCell_" .. tostring(row) .. "_" .. tostring(math.floor(hx)),
					CFrame.new(centerPos + Vector3.new(hx, -1.25, zOff)),
					hexR * 0.88,
					0.34,
					0.08,
					6,
					PALETTE.FocusCaustic,
					0.20
				)
			end
		end
	end

	-- Brilho suave turquesa no centro do fundo da lagoa
	local focusFloorGlow = makeEllipsoid(
		pond,
		"FocusCenterGlow",
		CFrame.new(centerPos + Vector3.new(1.2, -1.42, -0.3)),
		Vector3.new(FOCUS_RX * 1.15, 0.28, FOCUS_RZ * 1.15),
		PALETTE.FocusCaustic,
		Enum.Material.Neon,
		false,
		0.48
	)
	focusFloorGlow.CastShadow = false

	-- Margem suave de areia/terra fina + colar de grama sem escadinha (+X aponta para DENTRO!)
	local bankCount = 56
	for i = 1, bankCount do
		local a1 = (i / bankCount) * math.pi * 2
		local a2 = ((i + 1) / bankCount) * math.pi * 2
		local p1 = centerPos + Vector3.new(math.cos(a1) * FOCUS_RX, -0.1, math.sin(a1) * FOCUS_RZ)
		local p2 = centerPos + Vector3.new(math.cos(a2) * FOCUS_RX, -0.1, math.sin(a2) * FOCUS_RZ)
		local mid = (p1 + p2) * 0.5
		local segLen = (p2 - p1).Magnitude + 0.65
		local cf = CFrame.lookAt(mid, p2)

		-- Colar externo de grama nivelado ao terreno (-X = fora, sem linha de costura)
		local grassCollar = makePart(
			pond,
			"GrassCollar_" .. tostring(i),
			cf * CFrame.new(-1.55, -0.11, 0),
			Vector3.new(3.4, 0.22, segLen * 1.12),
			PALETTE.GrassMain,
			Enum.Material.Grass,
			true,
			0
		)
		grassCollar.CastShadow = false

		-- Parede interna arenosa suave
		makePart(
			pond,
			"BankSlope_" .. tostring(i),
			cf * CFrame.new(0.45, -1.25, 0) * CFrame.Angles(0, 0, math.rad(-16)),
			Vector3.new(1.8, 2.5, segLen),
			PALETTE.PondEdgeDirt,
			Enum.Material.Sand,
			true,
			0
		)

		-- Filete fino de margem arenosa rente à grama
		local shoreLip = makePart(
			pond,
			"ShoreEdge_" .. tostring(i),
			cf * CFrame.new(0.15, -0.06, 0),
			Vector3.new(1.30, 0.22, segLen * 1.08),
			PALETTE.PondEdgeDirt,
			Enum.Material.Sand,
			false,
			0
		)
		shoreLip.CastShadow = false

		-- Pedrinhas ocasionais na borda
		if i % 4 == 0 then
			local peb = makeEllipsoid(
				pond,
				"ShorePebble_" .. tostring(i),
				cf
					* CFrame.new(rng:NextNumber(-0.75, 0.15), 0.14, 0)
					* CFrame.Angles(0, rng:NextNumber(0, 6), 0),
				Vector3.new(
					rng:NextNumber(0.8, 1.45),
					rng:NextNumber(0.45, 0.72),
					rng:NextNumber(0.75, 1.35)
				),
				if i % 8 == 0 then PALETTE.StoneLight else PALETTE.StoneMid,
				Enum.Material.Concrete,
				false,
				0
			)
			peb.CastShadow = false
		end
	end

	-- Superfície cristalina azul-clara bem translúcida (exibe o padrão hexagonal + ondulações!)
	local water = makeEllipsoid(
		pond,
		"WaterSurface",
		CFrame.new(centerPos + Vector3.new(0, -0.32, 0)),
		Vector3.new(FOCUS_RX * 2.02, 0.22, FOCUS_RZ * 2.02),
		PALETTE.FocusWater,
		Enum.Material.SmoothPlastic,
		false,
		0.66
	)
	water.Reflectance = 0.08
	water.CastShadow = false

	-- 3 anéis de luz empilhados mais grossos e brilhantes + halo suave + feixe vertical difuso
	local ringsFolder = makeFolder(pond, "FocusLightRings")
	local ringSpecs = {
		{
			name = "FocusRing_1",
			pos = Vector3.new(1.4, -0.10, 0.5),
			radius = 4.9,
			thick = 0.42,
			height = 0.18,
			trans = 0.0,
			halo = true,
		},
		{
			name = "FocusRing_2",
			pos = Vector3.new(1.4, 1.45, -0.4),
			radius = 3.55,
			thick = 0.38,
			height = 0.16,
			trans = 0.04,
			halo = true,
		},
		{
			name = "FocusRing_3",
			pos = Vector3.new(1.4, 3.05, -1.3),
			radius = 2.25,
			thick = 0.34,
			height = 0.15,
			trans = 0.08,
			halo = true,
		},
		{
			name = "FocusRing_Ripple",
			pos = Vector3.new(5.6, -0.15, -3.2),
			radius = 2.65,
			thick = 0.20,
			height = 0.08,
			trans = 0.26,
			halo = false,
		},
		{
			name = "FocusRing_OuterWave",
			pos = Vector3.new(1.4, -0.17, 0.5),
			radius = 6.4,
			thick = 0.16,
			height = 0.06,
			trans = 0.48,
			halo = false,
		},
	}
	for idx, rs in ipairs(ringSpecs) do
		local ring = makeNeonRing(
			ringsFolder,
			rs.name,
			CFrame.new(centerPos + rs.pos),
			rs.radius,
			rs.thick,
			rs.height,
			34,
			PALETTE.FocusRing,
			rs.trans
		)
		ring:SetAttribute("RingIndex", idx)
		ring:SetAttribute("BaseY", (centerPos + rs.pos).Y)

		if rs.halo then
			makeNeonRing(
				ringsFolder,
				rs.name .. "_Halo",
				CFrame.new(centerPos + rs.pos + Vector3.new(0, -0.02, 0)),
				rs.radius + 0.22,
				rs.thick * 0.95,
				rs.height * 0.65,
				34,
				PALETTE.CrystalCyan,
				0.50
			)
		end
	end

	-- Feixe de luz vertical difuso subindo do centro dos anéis de foco
	local beamBase = makePart(
		ringsFolder,
		"FocusColumnBase",
		CFrame.new(centerPos + Vector3.new(1.4, -0.15, -0.2)),
		Vector3.new(0.4, 0.4, 0.4),
		PALETTE.FocusRing,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	beamBase.CanQuery = false
	local beamTop = makePart(
		ringsFolder,
		"FocusColumnTop",
		CFrame.new(centerPos + Vector3.new(1.4, 17.5, -0.8)),
		Vector3.new(0.4, 0.4, 0.4),
		PALETTE.FocusRing,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	beamTop.CanQuery = false
	local fAtt0 = Instance.new("Attachment")
	fAtt0.Parent = beamBase
	local fAtt1 = Instance.new("Attachment")
	fAtt1.Parent = beamTop

	local focusBeam = Instance.new("Beam")
	focusBeam.Name = "FocusVerticalColumn"
	focusBeam.Attachment0 = fAtt0
	focusBeam.Attachment1 = fAtt1
	focusBeam.FaceCamera = true
	focusBeam.Width0 = 5.4
	focusBeam.Width1 = 8.6
	focusBeam.LightEmission = 1
	focusBeam.LightInfluence = 0
	focusBeam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.FocusRing),
		ColorSequenceKeypoint.new(1, PALETTE.CrystalCyan),
	})
	focusBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.62),
		NumberSequenceKeypoint.new(0.45, 0.80),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	focusBeam.Parent = beamBase

	local focusCenterLight = Instance.new("PointLight")
	focusCenterLight.Color = PALETTE.CrystalCyan
	focusCenterLight.Brightness = 1.15
	focusCenterLight.Range = 16
	focusCenterLight.Parent = beamBase

	local moteAnchor = makePart(
		ringsFolder,
		"RingSparkleAnchor",
		CFrame.new(centerPos + Vector3.new(1.4, 0.15, -0.4)),
		Vector3.new(5.5, 0.2, 5.5),
		PALETTE.FocusRing,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	moteAnchor.CanQuery = false
	local focusMotes = Instance.new("ParticleEmitter")
	focusMotes.Name = "FocusLightMotes"
	focusMotes.Color = ColorSequence.new(PALETTE.FocusRing)
	focusMotes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.24),
		NumberSequenceKeypoint.new(1, 0),
	})
	focusMotes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	focusMotes.Lifetime = NumberRange.new(1.8, 3.0)
	focusMotes.Speed = NumberRange.new(1.4, 2.6)
	focusMotes.Rate = 10
	focusMotes.LightEmission = 1
	focusMotes.Parent = moteAnchor

	-- 3 Boias cônicas laranja com listras brancas e ondinha em volta
	local buoysFolder = makeFolder(pond, "FocusBuoys")
	local buoyOffsets = {
		Vector3.new(-6.6, -0.24, 3.2),
		Vector3.new(5.0, -0.24, 5.8),
		Vector3.new(9.2, -0.24, -2.8),
	}
	for idx, off in ipairs(buoyOffsets) do
		local b =
			buildConeBuoy(buoysFolder, "FocusBuoy_" .. tostring(idx), CFrame.new(centerPos + off))
		b:SetAttribute("BuoyIndex", idx)
	end

	-- Deck de madeira na borda superior-esquerda + brilho quente âmbar discreto
	local deckPos = centerPos + Vector3.new(-8.6, 0.58, -8.8)
	local deckCf = CFrame.lookAt(deckPos, centerPos + Vector3.new(0, 0.58, 0))
	buildWoodenDeck(pond, "FocusDeck", deckCf, 6.4, 8.4, rng)

	local focusDeckGlow = makePart(
		pond,
		"FocusDeckWarmGlow",
		deckCf * CFrame.new(-2.8, 2.4, -3.5),
		Vector3.new(0.4, 0.4, 0.4),
		PALETTE.AmberGlow,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	focusDeckGlow.CanQuery = false
	local deckAmber = Instance.new("PointLight")
	deckAmber.Color = PALETTE.AmberGlow
	deckAmber.Brightness = 1.1
	deckAmber.Range = 14
	deckAmber.Parent = focusDeckGlow

	-- 2 Pilares de Cristal Hexagonal Azul-Gelo translúcidos com cristais menores na base e feixe suave
	local pillarsFolder = makeFolder(pond, "CrystalPillars")
	local pillarConfigs = {
		{
			name = "CrystalPillar_Left",
			pos = origin + Vector3.new(-33.5, -0.1, -5.8),
			height = 10.8,
			radius = 1.70,
			beamBright = 0.64,
		},
		{
			name = "CrystalPillar_Back",
			pos = origin + Vector3.new(2.0, -0.1, -23.0),
			height = 12.2,
			radius = 1.85,
			beamBright = 0.66,
		},
	}
	for idx, cfg in ipairs(pillarConfigs) do
		local cluster = makeModel(pillarsFolder, cfg.name)
		buildHexCrystal(
			cluster,
			"MainHexCrystal",
			CFrame.new(cfg.pos) * CFrame.Angles(0, math.rad(idx * 30), 0),
			cfg.radius,
			cfg.height,
			PALETTE.CrystalIce,
			PALETTE.CrystalCore,
			true
		)
		buildHexCrystal(
			cluster,
			"SideCrystalA",
			CFrame.new(cfg.pos + Vector3.new(-1.85, -0.15, 1.0))
				* CFrame.Angles(math.rad(14), math.rad(20), math.rad(20)),
			cfg.radius * 0.56,
			cfg.height * 0.48,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			false
		)
		buildHexCrystal(
			cluster,
			"SideCrystalB",
			CFrame.new(cfg.pos + Vector3.new(1.75, -0.15, 0.85))
				* CFrame.Angles(math.rad(-10), math.rad(-35), math.rad(-18)),
			cfg.radius * 0.50,
			cfg.height * 0.42,
			PALETTE.CrystalCyan,
			PALETTE.CrystalCore,
			false
		)
		buildHexCrystal(
			cluster,
			"SideCrystalC",
			CFrame.new(cfg.pos + Vector3.new(0.2, -0.15, -1.65))
				* CFrame.Angles(math.rad(-16), math.rad(10), math.rad(8)),
			cfg.radius * 0.44,
			cfg.height * 0.36,
			PALETTE.CrystalIce,
			PALETTE.CrystalCore,
			false
		)
		buildHexCrystal(
			cluster,
			"SideCrystalD",
			CFrame.new(cfg.pos + Vector3.new(-0.95, -0.2, 1.85))
				* CFrame.Angles(math.rad(22), math.rad(-15), math.rad(12)),
			cfg.radius * 0.36,
			cfg.height * 0.28,
			PALETTE.CrystalIce,
			PALETTE.CrystalCyan,
			false
		)

		makeEllipsoid(
			cluster,
			"BaseStoneA",
			CFrame.new(cfg.pos + Vector3.new(-1.3, 0.2, -1.1)),
			Vector3.new(2.3, 1.1, 1.9),
			PALETTE.StoneMid,
			Enum.Material.Concrete,
			false,
			0
		)
		makeEllipsoid(
			cluster,
			"BaseStoneB",
			CFrame.new(cfg.pos + Vector3.new(1.4, 0.15, -0.7)),
			Vector3.new(1.9, 0.9, 1.7),
			PALETTE.StoneLight,
			Enum.Material.Concrete,
			false,
			0
		)

		-- Feixe de luz vertical suave e difuso subindo a partir do topo do cristal
		local beamStart = makePart(
			cluster,
			"BeamStart",
			CFrame.new(cfg.pos + Vector3.new(0, cfg.height * 0.55, 0)),
			Vector3.new(0.3, 0.3, 0.3),
			PALETTE.CrystalCyan,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		beamStart.CanQuery = false
		local beamEnd = makePart(
			cluster,
			"BeamEnd",
			CFrame.new(cfg.pos + Vector3.new(0, cfg.height + 15.5, 0)),
			Vector3.new(0.3, 0.3, 0.3),
			PALETTE.CrystalCyan,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		beamEnd.CanQuery = false
		local att0 = Instance.new("Attachment")
		att0.Parent = beamStart
		local att1 = Instance.new("Attachment")
		att1.Parent = beamEnd

		local beam = Instance.new("Beam")
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.FaceCamera = true
		beam.Width0 = cfg.radius * 2.4
		beam.Width1 = cfg.radius * 4.2
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, PALETTE.CrystalCyan),
			ColorSequenceKeypoint.new(1, PALETTE.CrystalCore),
		})
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, cfg.beamBright),
			NumberSequenceKeypoint.new(0.45, 0.84),
			NumberSequenceKeypoint.new(1, 1.0),
		})
		beam.Parent = beamStart

		local light = Instance.new("PointLight")
		light.Color = PALETTE.CrystalCyan
		light.Brightness = 1.35
		light.Range = 18
		light.Parent = beamStart

		-- Partículas leves subindo ao redor dos cristais
		local cMotes = Instance.new("ParticleEmitter")
		cMotes.Name = "CrystalSparkles"
		cMotes.Color = ColorSequence.new(PALETTE.CrystalCore)
		cMotes.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.20),
			NumberSequenceKeypoint.new(1, 0),
		})
		cMotes.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
		cMotes.Lifetime = NumberRange.new(1.8, 3.0)
		cMotes.Speed = NumberRange.new(1.0, 2.0)
		cMotes.EmissionDirection = Enum.NormalId.Top
		cMotes.SpreadAngle = Vector2.new(35, 35)
		cMotes.Rate = 5
		cMotes.LightEmission = 1
		cMotes.Parent = beamStart
	end

	-- Cerca traseira com nós de corda contornando a Lagoa do Foco
	buildRopeFence(pond, "Fence_BackFocus", {
		origin + Vector3.new(-31.5, 0, -16.8),
		origin + Vector3.new(-24.8, 0, -23.6),
		origin + Vector3.new(-15.5, 0, -26.5),
		origin + Vector3.new(-6.2, 0, -24.8),
	})

	return pond
end

-- ============================================================================
-- 5. LAGOA DO INSTINTO (SORTE) — MODELO DIRETO `InstinctPond`
-- ============================================================================

local function buildInstinctFish(
	parent: Instance,
	name: string,
	cf: CFrame,
	scale: number,
	bodyColor: Color3,
	accentColor: Color3,
	isRainbow: boolean
): Model
	local fish = makeModel(parent, name)
	local bodyMat = if isRainbow then Enum.Material.Neon else Enum.Material.SmoothPlastic
	local bodyTrans = if isRainbow then 0.14 else 0.0

	local body = makeEllipsoid(
		fish,
		"Body",
		cf,
		Vector3.new(1.70 * scale, 0.78 * scale, 5.0 * scale),
		bodyColor,
		bodyMat,
		false,
		bodyTrans
	)
	body.CastShadow = false
	fish.PrimaryPart = body

	local head = makeEllipsoid(
		fish,
		"Head",
		cf * CFrame.new(0, 0, -2.1 * scale),
		Vector3.new(1.36 * scale, 0.68 * scale, 1.95 * scale),
		if isRainbow then PALETTE.FishRainbowA else bodyColor,
		bodyMat,
		false,
		bodyTrans
	)
	head.CastShadow = false

	-- Faixa/contorno luminoso nas costas para destacar nitidamente visto de cima
	local spineGlow = makeEllipsoid(
		fish,
		"GlowAccent",
		cf * CFrame.new(0, 0.24 * scale, -0.15 * scale),
		Vector3.new(0.76 * scale, 0.24 * scale, 3.4 * scale),
		accentColor,
		Enum.Material.Neon,
		false,
		if isRainbow then 0.12 else 0.22
	)
	spineGlow.CastShadow = false

	-- Nadadeira dorsal + peitorais bem marcantes
	local dorsal = makeWedge(
		fish,
		"Dorsal",
		cf * CFrame.new(0, 0.48 * scale, 0.1 * scale),
		Vector3.new(0.22 * scale, 0.88 * scale, 1.55 * scale),
		accentColor,
		Enum.Material.Neon,
		false,
		0.16
	)
	dorsal.CastShadow = false

	local finL = makeEllipsoid(
		fish,
		"FinL",
		cf
			* CFrame.new(-1.55 * scale, -0.02 * scale, -0.35 * scale)
			* CFrame.Angles(0, math.rad(32), 0),
		Vector3.new(2.25 * scale, 0.18 * scale, 1.05 * scale),
		if isRainbow then PALETTE.FishRainbowB else bodyColor,
		bodyMat,
		false,
		bodyTrans
	)
	finL.CastShadow = false
	local finR = makeEllipsoid(
		fish,
		"FinR",
		cf
			* CFrame.new(1.55 * scale, -0.02 * scale, -0.35 * scale)
			* CFrame.Angles(0, math.rad(-32), 0),
		Vector3.new(2.25 * scale, 0.18 * scale, 1.05 * scale),
		if isRainbow then PALETTE.FishRainbowB else bodyColor,
		bodyMat,
		false,
		bodyTrans
	)
	finR.CastShadow = false

	-- Cauda em meia-lua bem definida
	local tailCol = if isRainbow then PALETTE.FishRainbowC else accentColor
	local tailL = makeEllipsoid(
		fish,
		"TailL",
		cf * CFrame.new(-0.72 * scale, 0, 2.95 * scale) * CFrame.Angles(0, math.rad(-34), 0),
		Vector3.new(0.56 * scale, 0.18 * scale, 2.15 * scale),
		tailCol,
		Enum.Material.Neon,
		false,
		0.14
	)
	tailL.CastShadow = false
	local tailR = makeEllipsoid(
		fish,
		"TailR",
		cf * CFrame.new(0.72 * scale, 0, 2.95 * scale) * CFrame.Angles(0, math.rad(34), 0),
		Vector3.new(0.56 * scale, 0.18 * scale, 2.15 * scale),
		tailCol,
		Enum.Material.Neon,
		false,
		0.14
	)
	tailR.CastShadow = false

	return fish
end

local function buildBlossomTree(parent: Instance, basePos: Vector3, rng: Random): Model
	local tree = makeModel(parent, "PinkLilacBlossomTree")

	-- Raízes curvas abraçando o gramado (tronco roxo-acastanhado quente)
	for r = 1, 5 do
		local a = (r / 5) * math.pi * 2 + 0.35
		local p1 = basePos + Vector3.new(0, 1.2, 0)
		local p2 = basePos + Vector3.new(math.cos(a) * 3.2, -0.05, math.sin(a) * 3.2)
		makeSegment(
			tree,
			"TreeRoot_" .. tostring(r),
			p1,
			p2,
			1.18,
			PALETTE.TreeBarkDark,
			Enum.Material.Wood,
			true,
			true
		)
	end

	-- Tronco retorcido elegante em curva S
	local trunkPts = {
		basePos + Vector3.new(0, 0, 0),
		basePos + Vector3.new(-1.3, 2.7, 0.9),
		basePos + Vector3.new(-0.6, 5.8, 1.3),
		basePos + Vector3.new(1.4, 8.9, 0.3),
		basePos + Vector3.new(0.9, 11.7, -0.8),
	}
	local trunkRadii = { 2.35, 2.0, 1.70, 1.40 }
	for i = 1, #trunkPts - 1 do
		local seg = makeSegment(
			tree,
			"Trunk_" .. tostring(i),
			trunkPts[i],
			trunkPts[i + 1],
			trunkRadii[i],
			PALETTE.TreeBark,
			Enum.Material.Wood,
			true,
			true
		)
		if i == 1 and seg then
			tree.PrimaryPart = seg
		end
		makeEllipsoid(
			tree,
			"TrunkJoint_" .. tostring(i),
			CFrame.new(trunkPts[i + 1]),
			Vector3.new(trunkRadii[i] * 0.96, trunkRadii[i] * 0.96, trunkRadii[i] * 0.96),
			PALETTE.TreeBark,
			Enum.Material.Wood,
			false,
			0
		)
	end

	-- Galhos curvos dividindo em 4 massas de copa sakura exuberante
	local branchCurves = {
		{
			trunkPts[4],
			basePos + Vector3.new(-2.4, 11.6, -1.0),
			basePos + Vector3.new(-5.4, 13.6, -1.8),
		},
		{
			trunkPts[5],
			basePos + Vector3.new(1.5, 13.8, -1.6),
			basePos + Vector3.new(1.8, 15.8, -2.2),
		},
		{
			trunkPts[3],
			basePos + Vector3.new(3.4, 8.6, 1.8),
			basePos + Vector3.new(6.4, 10.6, 2.6),
		},
		{
			trunkPts[4],
			basePos + Vector3.new(3.6, 12.2, -0.4),
			basePos + Vector3.new(5.8, 13.8, -1.2),
		},
	}
	for bIdx, curve in ipairs(branchCurves) do
		makeSegment(
			tree,
			"BranchA_" .. tostring(bIdx),
			curve[1],
			curve[2],
			1.10,
			PALETTE.TreeBark,
			Enum.Material.Wood,
			true,
			false
		)
		makeSegment(
			tree,
			"BranchB_" .. tostring(bIdx),
			curve[2],
			curve[3],
			0.82,
			PALETTE.TreeBarkDark,
			Enum.Material.Wood,
			true,
			false
		)
	end

	-- Copa sakura rosa-quente em 4 nuvens frondosas com muitos cachinhos pequenos
	local blossomShades =
		{ PALETTE.BlossomLight, PALETTE.BlossomPink, PALETTE.BlossomPink, PALETTE.BlossomRose }
	local canopyClouds = {
		{
			center = basePos + Vector3.new(-5.2, 14.3, -1.8),
			rx = 5.4,
			ry = 3.1,
			rz = 5.0,
			clusters = 28,
		},
		{
			center = basePos + Vector3.new(1.4, 16.6, -2.2),
			rx = 6.4,
			ry = 3.8,
			rz = 5.8,
			clusters = 34,
		},
		{
			center = basePos + Vector3.new(6.4, 11.1, 2.4),
			rx = 4.6,
			ry = 2.7,
			rz = 4.4,
			clusters = 22,
		},
		{
			center = basePos + Vector3.new(5.4, 14.2, -1.2),
			rx = 4.4,
			ry = 2.6,
			rz = 4.2,
			clusters = 20,
		},
	}

	for cIdx, cl in ipairs(canopyClouds) do
		makeEllipsoid(
			tree,
			"CanopyCore_" .. tostring(cIdx),
			CFrame.new(cl.center + Vector3.new(0, -0.45, 0)),
			Vector3.new(cl.rx * 1.38, cl.ry * 1.25, cl.rz * 1.38),
			PALETTE.BlossomRose,
			Enum.Material.SmoothPlastic,
			false,
			0
		)

		for k = 1, cl.clusters do
			local theta = rng:NextNumber(0, math.pi * 2)
			local phi = rng:NextNumber(-0.42, 0.92)
			local dist = rng:NextNumber(0.38, 1.0)
			local pos = cl.center
				+ Vector3.new(
					math.cos(theta) * math.cos(phi) * cl.rx * dist,
					math.sin(phi) * cl.ry * dist,
					math.sin(theta) * math.cos(phi) * cl.rz * dist
				)

			local col: Color3
			if pos.Y > cl.center.Y + cl.ry * 0.28 then
				col = if rng:NextNumber() > 0.32 then PALETTE.BlossomLight else PALETTE.BlossomPink
			elseif pos.Y < cl.center.Y - cl.ry * 0.25 then
				col = if rng:NextNumber() > 0.45 then PALETTE.BlossomRose else PALETTE.BlossomLilac
			else
				col = blossomShades[rng:NextInteger(1, #blossomShades)]
			end

			local s = rng:NextNumber(1.65, 3.05)
			local blossom = makeEllipsoid(
				tree,
				"FlowerCluster_" .. tostring(cIdx) .. "_" .. tostring(k),
				CFrame.new(pos)
					* CFrame.Angles(
						rng:NextNumber(0, 3),
						rng:NextNumber(0, 3),
						rng:NextNumber(0, 3)
					),
				Vector3.new(s, s * rng:NextNumber(0.62, 0.88), s * rng:NextNumber(0.85, 1.15)),
				col,
				Enum.Material.SmoothPlastic,
				false,
				0
			)
			blossom.CastShadow = true
		end
	end

	-- Emissor leve de pétalas rosa caindo
	local petalAnchor = makePart(
		tree,
		"PetalEmitterAnchor",
		CFrame.new(basePos + Vector3.new(0, 12.2, 0)),
		Vector3.new(13, 1, 13),
		PALETTE.BlossomPink,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	petalAnchor.CanQuery = false
	local petals = Instance.new("ParticleEmitter")
	petals.Name = "FallingPetals"
	petals.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.BlossomLight),
		ColorSequenceKeypoint.new(1, PALETTE.BlossomRose),
	})
	petals.Size = NumberSequence.new(0.32)
	petals.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.12),
		NumberSequenceKeypoint.new(1, 1),
	})
	petals.Lifetime = NumberRange.new(3.2, 5.2)
	petals.Speed = NumberRange.new(1.0, 2.0)
	petals.EmissionDirection = Enum.NormalId.Bottom
	petals.SpreadAngle = Vector2.new(38, 38)
	petals.Acceleration = Vector3.new(0.7, -0.35, 0.5)
	petals.RotSpeed = NumberRange.new(-90, 90)
	petals.Rate = 10
	petals.Parent = petalAnchor

	-- Pétalas caídas na grama em volta do tronco e da árvore
	for p = 1, 34 do
		local pa = rng:NextNumber(0, math.pi * 2)
		local pr = rng:NextNumber(1.6, 10.5)
		local gx = basePos.X + math.cos(pa) * pr
		local gz = basePos.Z + math.sin(pa) * pr
		local pet = makeEllipsoid(
			tree,
			"GroundPetal_" .. tostring(p),
			CFrame.new(gx, basePos.Y + 0.15, gz) * CFrame.Angles(0, rng:NextNumber(0, 6), 0),
			Vector3.new(0.62, 0.08, 0.38),
			if p % 3 == 0
				then PALETTE.BlossomRose
				elseif p % 2 == 0 then PALETTE.BlossomLight
				else PALETTE.BlossomPink,
			Enum.Material.SmoothPlastic,
			false,
			0
		)
		pet.CastShadow = false
	end

	return tree
end

local function buildLanternUnit(
	parent: Instance,
	name: string,
	centerPos: Vector3,
	scale: number
): Model
	local lantern = makeModel(parent, name)
	local cap = makePart(
		lantern,
		"TopCap",
		CFrame.new(centerPos + Vector3.new(0, 0.85 * scale, 0)),
		Vector3.new(1.22 * scale, 0.24 * scale, 1.22 * scale),
		PALETTE.IronDark,
		Enum.Material.Metal,
		false,
		0
	)
	lantern.PrimaryPart = cap
	makePart(
		lantern,
		"RoofPeak",
		CFrame.new(centerPos + Vector3.new(0, 1.05 * scale, 0)),
		Vector3.new(0.75 * scale, 0.22 * scale, 0.75 * scale),
		PALETTE.IronDark,
		Enum.Material.Metal,
		false,
		0
	)
	makePart(
		lantern,
		"BottomCap",
		CFrame.new(centerPos + Vector3.new(0, -0.85 * scale, 0)),
		Vector3.new(1.12 * scale, 0.24 * scale, 1.12 * scale),
		PALETTE.IronDark,
		Enum.Material.Metal,
		false,
		0
	)

	local core = makePart(
		lantern,
		"AmberCore",
		CFrame.new(centerPos),
		Vector3.new(0.88 * scale, 1.42 * scale, 0.88 * scale),
		PALETTE.AmberGlow,
		Enum.Material.Neon,
		false,
		0.04
	)
	core.CastShadow = false

	local cornerOffs = {
		Vector3.new(-0.48 * scale, 0, -0.48 * scale),
		Vector3.new(0.48 * scale, 0, -0.48 * scale),
		Vector3.new(-0.48 * scale, 0, 0.48 * scale),
		Vector3.new(0.48 * scale, 0, 0.48 * scale),
	}
	for i, off in ipairs(cornerOffs) do
		makePart(
			lantern,
			"Frame_" .. tostring(i),
			CFrame.new(centerPos + off),
			Vector3.new(0.13 * scale, 1.62 * scale, 0.13 * scale),
			PALETTE.IronDark,
			Enum.Material.Metal,
			false,
			0
		)
	end

	local light = Instance.new("PointLight")
	light.Color = PALETTE.AmberGlow
	light.Brightness = 1.85
	light.Range = 18 * scale
	light.Parent = core

	return lantern
end

local function buildLanternPost(
	parent: Instance,
	name: string,
	basePos: Vector3,
	faceTarget: Vector3
): Model
	local postModel = makeModel(parent, name)
	local cf = CFrame.lookAt(basePos, Vector3.new(faceTarget.X, basePos.Y, faceTarget.Z))

	local pole = makePart(
		postModel,
		"MainPole",
		cf * CFrame.new(0, 4.1, 0),
		Vector3.new(0.88, 8.4, 0.88),
		PALETTE.WoodWarm2,
		Enum.Material.Wood,
		true,
		0
	)
	postModel.PrimaryPart = pole
	makeEllipsoid(
		postModel,
		"PoleTop",
		cf * CFrame.new(0, 8.35, 0),
		Vector3.new(0.96, 0.42, 0.96),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)

	-- Braço curvo em 2 segmentos + mão-francesa + corrente
	local armStart = (cf * CFrame.new(0, 7.65, -0.1)).Position
	local armMid = (cf * CFrame.new(0, 8.05, -1.65)).Position
	local armTip = (cf * CFrame.new(0, 7.75, -3.05)).Position
	makeSegment(
		postModel,
		"ArmA",
		armStart,
		armMid,
		0.56,
		PALETTE.WoodWarm1,
		Enum.Material.Wood,
		true,
		false
	)
	makeSegment(
		postModel,
		"ArmB",
		armMid,
		armTip,
		0.48,
		PALETTE.WoodWarm1,
		Enum.Material.Wood,
		true,
		false
	)
	makeSegment(
		postModel,
		"Brace",
		(cf * CFrame.new(0, 6.0, -0.25)).Position,
		(cf * CFrame.new(0, 7.85, -1.7)).Position,
		0.38,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		false
	)

	local lanternPos = (cf * CFrame.new(0, 5.85, -3.0)).Position
	makeSegment(
		postModel,
		"Chain",
		armTip,
		lanternPos + Vector3.new(0, 1.0, 0),
		0.14,
		PALETTE.IronDark,
		Enum.Material.Metal,
		true,
		false
	)
	buildLanternUnit(postModel, "HangingLantern", lanternPos, 1.0)

	return postModel
end

local function buildRuneStone(
	parent: Instance,
	name: string,
	pos: Vector3,
	faceTarget: Vector3,
	size: Vector3,
	runeGlyph: string,
	runeColor: Color3
): Model
	local stone = makeModel(parent, name)
	local cf = CFrame.lookAt(pos, Vector3.new(faceTarget.X, pos.Y, faceTarget.Z))

	local rock = makeEllipsoid(
		stone,
		"Boulder",
		cf * CFrame.new(0, size.Y * 0.36, 0),
		size,
		PALETTE.StoneRune,
		Enum.Material.Concrete,
		true,
		0
	)
	stone.PrimaryPart = rock

	-- Runa 3D luminosa esculpida em Neon na face frontal (visível em qualquer fonte/distância!)
	local faceCf = cf * CFrame.new(0, size.Y * 0.44, -size.Z * 0.505)
	local rw = size.X * 0.24
	local rh = size.Y * 0.26
	local strokeThick = 0.14
	local strokes: { { Vector2 } }
	if runeGlyph == "ᛉ" then
		-- Algiz (tridente rúnico)
		strokes = {
			{ Vector2.new(0, -rh), Vector2.new(0, rh) },
			{ Vector2.new(0, 0.15 * rh), Vector2.new(-rw, rh * 0.92) },
			{ Vector2.new(0, 0.15 * rh), Vector2.new(rw, rh * 0.92) },
		}
	elseif runeGlyph == "ᚱ" then
		-- Raido (R rúnico angular)
		strokes = {
			{ Vector2.new(-rw * 0.65, -rh), Vector2.new(-rw * 0.65, rh) },
			{ Vector2.new(-rw * 0.65, rh), Vector2.new(rw * 0.75, rh * 0.32) },
			{ Vector2.new(rw * 0.75, rh * 0.32), Vector2.new(-rw * 0.55, -rh * 0.05) },
			{ Vector2.new(-rw * 0.45, -rh * 0.05), Vector2.new(rw * 0.80, -rh) },
		}
	elseif runeGlyph == "ᛟ" then
		-- Othala (losango com pernas cruzadas)
		strokes = {
			{ Vector2.new(0, rh), Vector2.new(-rw * 0.8, 0.1 * rh) },
			{ Vector2.new(0, rh), Vector2.new(rw * 0.8, 0.1 * rh) },
			{ Vector2.new(-rw * 0.8, 0.1 * rh), Vector2.new(rw * 0.72, -rh) },
			{ Vector2.new(rw * 0.8, 0.1 * rh), Vector2.new(-rw * 0.72, -rh) },
		}
	else
		-- Kenaz / Ansuz (< rúnico com haste)
		strokes = {
			{ Vector2.new(rw * 0.65, rh * 0.85), Vector2.new(-rw * 0.75, 0) },
			{ Vector2.new(-rw * 0.75, 0), Vector2.new(rw * 0.65, -rh * 0.85) },
			{ Vector2.new(-rw * 0.15, rh * 0.42), Vector2.new(rw * 0.55, 0) },
		}
	end

	for sIdx, segPts in ipairs(strokes) do
		local pA = (faceCf * CFrame.new(segPts[1].X, segPts[1].Y, 0)).Position
		local pB = (faceCf * CFrame.new(segPts[2].X, segPts[2].Y, 0)).Position
		local seg = makeSegment(
			stone,
			"RuneStroke_" .. tostring(sIdx),
			pA,
			pB,
			strokeThick,
			runeColor,
			Enum.Material.Neon,
			true,
			false
		)
		if seg then
			seg.CastShadow = false
		end
	end

	local lightAnchor = makePart(
		stone,
		"RuneLight",
		faceCf * CFrame.new(0, 0, -0.25),
		Vector3.new(0.2, 0.2, 0.2),
		runeColor,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	lightAnchor.CanQuery = false
	local light = Instance.new("PointLight")
	light.Color = runeColor
	light.Brightness = 0.95
	light.Range = 8
	light.Parent = lightAnchor

	return stone
end

local function buildInstinctPond(root: Model, origin: Vector3, rng: Random): Model
	local pond = makeModel(root, "InstinctPond")
	local centerPos = origin + Vector3.new(INSTINCT_CENTER.X, 0, INSTINCT_CENTER.Y)

	-- Fundo em 5 camadas concêntricas de gradiente: roxo profundo -> violeta -> índigo -> teal -> turquesa luminoso!
	local outerFloor = makeEllipsoid(
		pond,
		"PondFloorOuter",
		CFrame.new(centerPos + Vector3.new(0, -1.95, 0)),
		Vector3.new(INSTINCT_RX * 1.98, 0.75, INSTINCT_RZ * 1.98),
		Color3.fromRGB(72, 22, 156),
		Enum.Material.SmoothPlastic,
		true,
		0
	)
	outerFloor.CastShadow = false
	pond.PrimaryPart = outerFloor

	local violetGlowLayer = makeEllipsoid(
		pond,
		"PondFloorVioletRing",
		CFrame.new(centerPos + Vector3.new(0, -1.58, 0)),
		Vector3.new(INSTINCT_RX * 1.88, 0.42, INSTINCT_RZ * 1.88),
		PALETTE.InstinctOuter,
		Enum.Material.Neon,
		false,
		0.48
	)
	violetGlowLayer.CastShadow = false

	local midFloor = makeEllipsoid(
		pond,
		"PondFloorMid",
		CFrame.new(centerPos + Vector3.new(0, -1.42, 0)),
		Vector3.new(INSTINCT_RX * 1.48, 0.36, INSTINCT_RZ * 1.48),
		PALETTE.InstinctMid,
		Enum.Material.SmoothPlastic,
		false,
		0.18
	)
	midFloor.CastShadow = false

	local tealMidLayer = makeEllipsoid(
		pond,
		"PondFloorTealMid",
		CFrame.new(centerPos + Vector3.new(-0.3, -1.24, 0.2)),
		Vector3.new(INSTINCT_RX * 1.18, 0.30, INSTINCT_RZ * 1.18),
		Color3.fromRGB(22, 156, 184),
		Enum.Material.SmoothPlastic,
		false,
		0.20
	)
	tealMidLayer.CastShadow = false

	local centerGlow = makeEllipsoid(
		pond,
		"PondFloorTurquoise",
		CFrame.new(centerPos + Vector3.new(-0.4, -1.06, 0.2)),
		Vector3.new(INSTINCT_RX * 0.92, 0.26, INSTINCT_RZ * 0.92),
		Color3.fromRGB(28, 224, 198),
		Enum.Material.Neon,
		false,
		0.14
	)
	centerGlow.CastShadow = false

	local centerLight = Instance.new("PointLight")
	centerLight.Color = PALETTE.InstinctCenter
	centerLight.Brightness = 1.75
	centerLight.Range = 18
	centerLight.Parent = centerGlow

	-- Margem com colar de grama liso nivelado + brilho roxo-violeta suave DENTRO da borda (+X = dentro)
	local bankCount = 56
	for i = 1, bankCount do
		local a1 = (i / bankCount) * math.pi * 2
		local a2 = ((i + 1) / bankCount) * math.pi * 2
		local p1 = centerPos
			+ Vector3.new(math.cos(a1) * INSTINCT_RX, -0.1, math.sin(a1) * INSTINCT_RZ)
		local p2 = centerPos
			+ Vector3.new(math.cos(a2) * INSTINCT_RX, -0.1, math.sin(a2) * INSTINCT_RZ)
		local mid = (p1 + p2) * 0.5
		local segLen = (p2 - p1).Magnitude + 0.65
		local cf = CFrame.lookAt(mid, p2)

		-- Colar externo de grama nivelado ao terreno (-X = fora, sem linha de costura)
		local grassCollar = makePart(
			pond,
			"GrassCollar_" .. tostring(i),
			cf * CFrame.new(-1.55, -0.11, 0),
			Vector3.new(3.4, 0.22, segLen * 1.12),
			PALETTE.GrassMain,
			Enum.Material.Grass,
			true,
			0
		)
		grassCollar.CastShadow = false

		makePart(
			pond,
			"BankSlope_" .. tostring(i),
			cf * CFrame.new(0.70, -1.35, 0) * CFrame.Angles(0, 0, math.rad(-16)),
			Vector3.new(1.7, 2.4, segLen),
			Color3.fromRGB(64, 42, 106),
			Enum.Material.Concrete,
			true,
			0
		)

		local shoreLip = makePart(
			pond,
			"ShoreEdge_" .. tostring(i),
			cf * CFrame.new(0.18, -0.08, 0),
			Vector3.new(1.15, 0.20, segLen * 1.08),
			PALETTE.PondEdgeDirt,
			Enum.Material.Ground,
			false,
			0
		)
		shoreLip.CastShadow = false

		-- Anel de brilho roxo-violeta suave DENTRO da borda da água (+X = para dentro!)
		local rimGlow = makePart(
			pond,
			"VioletRimGlow_" .. tostring(i),
			cf * CFrame.new(0.95, -0.44, 0),
			Vector3.new(1.75, 0.14, segLen * 1.10),
			Color3.fromRGB(168, 62, 255),
			Enum.Material.Neon,
			false,
			0.44
		)
		rimGlow.CastShadow = false
	end

	-- Arco-íris mágico curvo de 7 cores suaves na superfície da lagoa (NÃO faixa branca única!)
	local rainbowModel = makeModel(pond, "InstinctRainbowArc")
	local rainbowHub = makePart(
		rainbowModel,
		"Center",
		CFrame.new(centerPos + Vector3.new(0, -0.46, 0)),
		Vector3.new(0.3, 0.3, 0.3),
		PALETTE.AmberGlow,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	rainbowHub.CanQuery = false
	rainbowModel.PrimaryPart = rainbowHub

	local rainbowColors = {
		Color3.fromRGB(255, 96, 126), -- Vermelho-rosa
		Color3.fromRGB(255, 166, 86), -- Laranja
		Color3.fromRGB(255, 236, 102), -- Amarelo
		Color3.fromRGB(112, 242, 152), -- Verde
		Color3.fromRGB(92, 234, 255), -- Ciano
		Color3.fromRGB(116, 148, 255), -- Azul
		Color3.fromRGB(204, 114, 255), -- Violeta
	}
	local arcSegs = 14
	local startAng = math.rad(-148)
	local endAng = math.rad(42)
	for bandIdx, bandColor in ipairs(rainbowColors) do
		local bandRx = 7.6 + (bandIdx - 4) * 0.42
		local bandRz = 6.3 + (bandIdx - 4) * 0.36
		for s = 1, arcSegs do
			local t0 = (s - 1) / arcSegs
			local t1 = s / arcSegs
			local tMid = (t0 + t1) * 0.5
			local a0 = startAng + (endAng - startAng) * t0
			local a1 = startAng + (endAng - startAng) * t1
			local p0 = centerPos
				+ Vector3.new(math.cos(a0) * bandRx + 0.6, -0.44, math.sin(a0) * bandRz - 0.5)
			local p1 = centerPos
				+ Vector3.new(math.cos(a1) * bandRx + 0.6, -0.44, math.sin(a1) * bandRz - 0.5)
			local segMid = (p0 + p1) * 0.5
			local segLen = (p1 - p0).Magnitude + 0.22
			-- Suaviza nas pontas do arco para parecer luz prismática na água
			local endFade = math.sin(tMid * math.pi)
			local trans = 0.86 - endFade * 0.42
			local seg = makePart(
				rainbowModel,
				"Rainbow_" .. tostring(bandIdx) .. "_" .. tostring(s),
				CFrame.lookAt(segMid, p1),
				Vector3.new(0.46, 0.05, segLen),
				bandColor,
				if bandIdx >= 2 and bandIdx <= 6
					then Enum.Material.Neon
					else Enum.Material.SmoothPlastic,
				false,
				trans
			)
			seg.CastShadow = false
		end
	end

	-- Estrelinhas luminosas + pétalas rosa flutuando na superfície da lagoa
	local starColors = { PALETTE.AmberCore, PALETTE.BlossomLight, PALETTE.CrystalCore }
	for s = 1, 24 do
		local ang = rng:NextNumber(0, math.pi * 2)
		local rad = math.sqrt(rng:NextNumber(0.06, 0.88))
		local sx = math.cos(ang) * (INSTINCT_RX - 2.0) * rad
		local sz = math.sin(ang) * (INSTINCT_RZ - 2.0) * rad
		local starPos = centerPos + Vector3.new(sx, -0.26, sz)
		local starCol = starColors[(s % #starColors) + 1]
		local star = makeEllipsoid(
			rainbowModel,
			"WaterStar_" .. tostring(s),
			CFrame.new(starPos),
			Vector3.new(0.42, 0.12, 0.42),
			starCol,
			Enum.Material.Neon,
			false,
			0.05
		)
		star.CastShadow = false
		if s % 3 == 0 then
			-- Cruz de brilho de 4 pontas nas estrelas maiores
			local armA = makePart(
				rainbowModel,
				"StarCrossA_" .. tostring(s),
				CFrame.new(starPos),
				Vector3.new(0.95, 0.05, 0.14),
				starCol,
				Enum.Material.Neon,
				false,
				0.20
			)
			armA.CastShadow = false
			local armB = makePart(
				rainbowModel,
				"StarCrossB_" .. tostring(s),
				CFrame.new(starPos),
				Vector3.new(0.14, 0.05, 0.95),
				starCol,
				Enum.Material.Neon,
				false,
				0.20
			)
			armB.CastShadow = false
		end
	end

	-- Pétalas rosa da árvore flutuando perto da borda da lagoa
	for p = 1, 14 do
		local pa = rng:NextNumber(-1.8, 0.4)
		local pr = rng:NextNumber(0.68, 0.90)
		local px = math.cos(pa) * INSTINCT_RX * pr
		local pz = math.sin(pa) * INSTINCT_RZ * pr
		local pet = makeEllipsoid(
			rainbowModel,
			"WaterPetal_" .. tostring(p),
			CFrame.new(centerPos + Vector3.new(px, -0.25, pz))
				* CFrame.Angles(0, rng:NextNumber(0, 6), 0),
			Vector3.new(0.62, 0.07, 0.38),
			if p % 2 == 0 then PALETTE.BlossomLight else PALETTE.BlossomPink,
			Enum.Material.SmoothPlastic,
			false,
			0
		)
		pet.CastShadow = false
	end

	-- 3 Peixes submersos bem nítidos vistos de cima (com atributos de órbita preservados)
	local fishFolder = makeFolder(pond, "MysteryFish")

	local whaleFish = buildInstinctFish(
		fishFolder,
		"InstinctFish_Whale",
		CFrame.new(centerPos + Vector3.new(-0.4, -0.62, -0.4)) * CFrame.Angles(0, math.rad(-40), 0),
		1.72,
		PALETTE.FishWhaleDark,
		PALETTE.FishWhaleRim,
		false
	)
	whaleFish:SetAttribute("OrbitRadius", 3.6)
	whaleFish:SetAttribute("OrbitSpeed", 0.36)
	whaleFish:SetAttribute("OrbitPhase", 0.4)
	whaleFish:SetAttribute("DepthY", centerPos.Y - 0.62)

	local goldFish = buildInstinctFish(
		fishFolder,
		"InstinctFish_Gold",
		CFrame.new(centerPos + Vector3.new(1.6, -0.72, 5.2)) * CFrame.Angles(0, math.rad(135), 0),
		0.98,
		PALETTE.FishWhaleDark,
		PALETTE.FishGold,
		false
	)
	goldFish:SetAttribute("OrbitRadius", 6.8)
	goldFish:SetAttribute("OrbitSpeed", -0.52)
	goldFish:SetAttribute("OrbitPhase", 2.0)
	goldFish:SetAttribute("DepthY", centerPos.Y - 0.72)

	local rainbowFish = buildInstinctFish(
		fishFolder,
		"InstinctFish_Rainbow",
		CFrame.new(centerPos + Vector3.new(5.8, -0.68, -2.4)) * CFrame.Angles(0, math.rad(35), 0),
		1.02,
		PALETTE.FishRainbowA,
		PALETTE.FishRainbowB,
		true
	)
	rainbowFish:SetAttribute("OrbitRadius", 7.4)
	rainbowFish:SetAttribute("OrbitSpeed", 0.60)
	rainbowFish:SetAttribute("OrbitPhase", 4.4)
	rainbowFish:SetAttribute("DepthY", centerPos.Y - 0.68)

	-- Superfície da água violeta translúcida (Transparency=0.72 revela centro turquesa, arco-íris e peixes!)
	local water = makeEllipsoid(
		pond,
		"WaterSurface",
		CFrame.new(centerPos + Vector3.new(0, -0.32, 0)),
		Vector3.new(INSTINCT_RX * 2.02, 0.22, INSTINCT_RZ * 2.02),
		PALETTE.InstinctWater,
		Enum.Material.SmoothPlastic,
		false,
		0.72
	)
	water.Reflectance = 0.08
	water.CastShadow = false

	-- Partículas mágicas de brilho subindo da Lagoa do Instinto
	local pondSparkleAnchor = makePart(
		pond,
		"InstinctSparkleAnchor",
		CFrame.new(centerPos + Vector3.new(0, 0.15, 0)),
		Vector3.new(INSTINCT_RX * 1.4, 0.2, INSTINCT_RZ * 1.4),
		PALETTE.InstinctRimGlow,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	pondSparkleAnchor.CanQuery = false
	local pondSparkles = Instance.new("ParticleEmitter")
	pondSparkles.Name = "InstinctSparkles"
	pondSparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.AmberCore),
		ColorSequenceKeypoint.new(0.5, PALETTE.InstinctCenter),
		ColorSequenceKeypoint.new(1, PALETTE.BlossomLight),
	})
	pondSparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.24),
		NumberSequenceKeypoint.new(0.5, 0.34),
		NumberSequenceKeypoint.new(1, 0),
	})
	pondSparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	pondSparkles.Lifetime = NumberRange.new(1.8, 3.2)
	pondSparkles.Speed = NumberRange.new(0.6, 1.5)
	pondSparkles.EmissionDirection = Enum.NormalId.Top
	pondSparkles.SpreadAngle = Vector2.new(35, 35)
	pondSparkles.Rate = 10
	pondSparkles.LightEmission = 1
	pondSparkles.Parent = pondSparkleAnchor

	-- Deck com banquinho na frente-esquerda + lanterna âmbar no chão
	local deckPos = centerPos + Vector3.new(-10.2, 0.58, 7.6)
	local deckCf = CFrame.lookAt(deckPos, centerPos + Vector3.new(0, 0.58, 0))
	buildWoodenDeck(pond, "InstinctDeck", deckCf, 6.2, 8.0, rng)
	buildLanternUnit(pond, "GroundTinyLantern", origin + Vector3.new(15.2, 0.85, 20.8), 0.86)

	-- Árvore de flores rosa/lilás no fundo direito
	buildBlossomTree(pond, origin + Vector3.new(26.5, -0.05, -13.5), rng)

	-- 2 Postes de lanterna âmbar com braço curvo e corrente
	buildLanternPost(pond, "LanternPost_Left", origin + Vector3.new(17.2, 0, -10.2), centerPos)
	buildLanternPost(pond, "LanternPost_Right", origin + Vector3.new(37.2, 0, -3.6), centerPos)

	-- 5 Pedras de runa viradas para frente/câmera para as runas brilharem nitidamente
	local runesFolder = makeFolder(pond, "RuneStones")
	local runeSpecs = {
		{
			pos = Vector3.new(13.2, 0, -6.2),
			face = Vector3.new(8.0, 0, 14.0),
			size = Vector3.new(3.0, 3.4, 2.5),
			glyph = "ᛉ",
			col = PALETTE.CrystalCyan,
		},
		{
			pos = Vector3.new(31.8, 0, -5.8),
			face = Vector3.new(26.0, 0, 14.0),
			size = Vector3.new(2.8, 3.2, 2.4),
			glyph = "ᚱ",
			col = PALETTE.CrystalCyan,
		},
		{
			pos = Vector3.new(37.4, 0, 7.2),
			face = Vector3.new(26.0, 0, 26.0),
			size = Vector3.new(2.9, 3.5, 2.5),
			glyph = "ᛟ",
			col = PALETTE.AmberGlow,
		},
		{
			pos = Vector3.new(32.6, 0, 18.2),
			face = Vector3.new(26.0, 0, 38.0),
			size = Vector3.new(3.5, 4.0, 2.8),
			glyph = "ᚱ",
			col = PALETTE.AmberGlow,
		},
		{
			pos = Vector3.new(24.5, 0, 22.0),
			face = Vector3.new(22.0, 0, 42.0),
			size = Vector3.new(2.6, 2.2, 2.2),
			glyph = "ᚲ",
			col = PALETTE.AmberGlow,
		},
	}
	for idx, rs in ipairs(runeSpecs) do
		local wPos = origin + rs.pos
		local wFace = origin + rs.face
		buildRuneStone(
			runesFolder,
			"RuneStone_" .. tostring(idx),
			wPos,
			wFace,
			rs.size,
			rs.glyph,
			rs.col
		)
	end

	-- Vaga-lumes dourados pequenos flutuando pelo ar + brilhinhos na lagoa
	local fireflyAnchor = makePart(
		pond,
		"FireflyAnchor",
		CFrame.new(centerPos + Vector3.new(2, 4.2, -3)),
		Vector3.new(24, 6, 24),
		PALETTE.AmberGlow,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	fireflyAnchor.CanQuery = false
	local fireflies = Instance.new("ParticleEmitter")
	fireflies.Name = "GoldenFireflies"
	fireflies.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.AmberCore),
		ColorSequenceKeypoint.new(1, PALETTE.AmberGlow),
	})
	fireflies.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.5, 0.32),
		NumberSequenceKeypoint.new(1, 0.04),
	})
	fireflies.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0),
		NumberSequenceKeypoint.new(0.75, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	fireflies.Lifetime = NumberRange.new(2.8, 4.6)
	fireflies.Speed = NumberRange.new(0.45, 1.25)
	fireflies.SpreadAngle = Vector2.new(180, 180)
	fireflies.Rate = 16
	fireflies.LightEmission = 1
	fireflies.Parent = fireflyAnchor

	return pond
end

-- ============================================================================
-- 6. PORTAL DE PEDRA EMPILHADA COM ESPIRAL CIANO/BRANCO (SEM LAVAR A PEDRA)
-- ============================================================================

local function buildArrivalPortal(
	root: Model,
	origin: Vector3,
	rng: Random,
	scaleOpt: number?,
	includeStepsOpt: boolean?
): CFrame
	local s = scaleOpt or 1.0
	local includeSteps = if includeStepsOpt == nil then true else includeStepsOpt
	local folder = makeFolder(root, "PortalStructure")
	local basePos = origin + PORTAL_LOCAL
	local lookPos = origin + PORTAL_LOOK_LOCAL
	local cf = CFrame.lookAt(basePos, lookPos)

	-- Pilares de 5 blocos de pedra cinza-quente real empilhados (com junta escura, sem lavar de ciano)
	local pillarX = 4.1 * s
	local blockHeights = { 1.85 * s, 1.75 * s, 1.75 * s, 1.70 * s, 1.60 * s }
	for _, side in ipairs({ -1, 1 }) do
		local yCur = 0.0
		for bIdx, bh in ipairs(blockHeights) do
			local w = (if bIdx == 1 then 2.65 else 2.25 + rng:NextNumber(-0.12, 0.14)) * s
			local d = (if bIdx == 1 then 2.85 else 2.40 + rng:NextNumber(-0.1, 0.12)) * s
			local jitterX = rng:NextNumber(-0.08, 0.08) * s
			local jitterYaw = math.rad(rng:NextNumber(-2.5, 2.5))
			local blockCol = if bIdx % 2 == 0 then PALETTE.StoneMid else PALETTE.StoneLight

			makePart(
				folder,
				"StoneBlock_" .. (if side < 0 then "L_" else "R_") .. tostring(bIdx),
				cf
					* CFrame.new(side * pillarX + jitterX, yCur + bh * 0.5, 0)
					* CFrame.Angles(0, jitterYaw, 0),
				Vector3.new(w, bh - 0.12 * s, d),
				blockCol,
				Enum.Material.Concrete,
				true,
				0
			)
			-- Junta escura entre os blocos (rachadura/argamassa)
			if bIdx < #blockHeights then
				makePart(
					folder,
					"Mortar_" .. (if side < 0 then "L_" else "R_") .. tostring(bIdx),
					cf * CFrame.new(side * pillarX, yCur + bh - 0.04 * s, 0),
					Vector3.new(w * 0.90, 0.14 * s, d * 0.90),
					PALETTE.StoneMortar,
					Enum.Material.Concrete,
					false,
					0
				)
			end
			yCur += bh
		end
	end

	-- Viga de madeira marrom quente no topo com friso escuro
	makePart(
		folder,
		"WoodenLintelMain",
		cf * CFrame.new(0, 9.45 * s, 0),
		Vector3.new(11.8 * s, 1.85 * s, 2.85 * s),
		PALETTE.WoodWarm1,
		Enum.Material.WoodPlanks,
		true,
		0
	)
	makePart(
		folder,
		"WoodenLintelTop",
		cf * CFrame.new(0, 10.45 * s, 0),
		Vector3.new(12.2 * s, 0.36 * s, 3.05 * s),
		PALETTE.WoodWarm3,
		Enum.Material.Wood,
		true,
		0
	)
	makePart(
		folder,
		"WoodenLintelTrim",
		cf * CFrame.new(0, 8.45 * s, 0),
		Vector3.new(11.0 * s, 0.38 * s, 3.0 * s),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		true,
		0
	)

	-- Pedra angular central cinza com medalhão redondo e espiral ciano contínua gravada (frente e verso)
	local keyCf = cf * CFrame.new(0, 9.85 * s, 0)
	makePart(
		folder,
		"Keystone",
		keyCf,
		Vector3.new(3.2 * s, 3.65 * s, 3.35 * s),
		PALETTE.StoneLight,
		Enum.Material.Concrete,
		true,
		0
	)
	for _, zSide in ipairs({ -1.72 * s, 1.72 * s }) do
		local spiralBaseCf = keyCf * CFrame.new(0, 0.06 * s, zSide)
		local medallion = makeCylinderY(
			folder,
			"KeystoneMedallion_" .. (if zSide < 0 then "F" else "B"),
			spiralBaseCf
				* CFrame.new(0, 0, if zSide < 0 then 0.04 * s else -0.04 * s)
				* CFrame.Angles(math.rad(90), 0, 0),
			0.14 * s,
			2.15 * s,
			PALETTE.StoneMortar,
			Enum.Material.Concrete,
			false,
			0
		)
		medallion.CastShadow = false
		-- Espiral contínua suave gravada em 16 segmentos conectados
		local prevKeyPt: Vector3? = nil
		for k = 0, 16 do
			local t = k / 16
			local a = t * math.pi * 3.4
			local r = (0.06 + t * 0.78) * s
			local curKeyPt = (spiralBaseCf * CFrame.new(math.cos(a) * r, math.sin(a) * r, 0)).Position
			if prevKeyPt then
				local seg = makeSegment(
					folder,
					"KeySpiralSeg_" .. (if zSide < 0 then "F_" else "B_") .. tostring(k),
					prevKeyPt,
					curKeyPt,
					0.15 * s,
					if t < 0.38 then PALETTE.CrystalCore else PALETTE.CrystalCyan,
					Enum.Material.Neon,
					true,
					false
				)
				if seg then
					seg.CastShadow = false
				end
			end
			prevKeyPt = curKeyPt
		end
	end

	-- Cristais ciano MAIORES e mais chamativos nos dois pés do arco (3 de cada lado)
	buildHexCrystal(
		folder,
		"BaseCrystalL1",
		cf * CFrame.new(-5.75 * s, 0.0, -0.55 * s) * CFrame.Angles(0, math.rad(15), math.rad(14)),
		0.78 * s,
		3.25 * s,
		PALETTE.CrystalCyan,
		PALETTE.CrystalCore,
		false
	)
	buildHexCrystal(
		folder,
		"BaseCrystalL2",
		cf * CFrame.new(-6.65 * s, 0.0, 0.25 * s) * CFrame.Angles(math.rad(10), 0, math.rad(28)),
		0.52 * s,
		2.15 * s,
		PALETTE.CrystalIce,
		PALETTE.CrystalCyan,
		false
	)
	buildHexCrystal(
		folder,
		"BaseCrystalL3",
		cf * CFrame.new(-5.25 * s, 0.0, 0.95 * s) * CFrame.Angles(math.rad(-14), 0, math.rad(12)),
		0.46 * s,
		1.85 * s,
		PALETTE.CrystalIce,
		PALETTE.CrystalCore,
		false
	)
	buildHexCrystal(
		folder,
		"BaseCrystalR1",
		cf * CFrame.new(5.70 * s, 0.0, -0.48 * s) * CFrame.Angles(0, math.rad(-20), math.rad(-14)),
		0.74 * s,
		3.05 * s,
		PALETTE.CrystalCyan,
		PALETTE.CrystalCore,
		false
	)
	buildHexCrystal(
		folder,
		"BaseCrystalR2",
		cf * CFrame.new(6.55 * s, 0.0, 0.35 * s) * CFrame.Angles(math.rad(8), 0, math.rad(-26)),
		0.48 * s,
		1.95 * s,
		PALETTE.CrystalIce,
		PALETTE.CrystalCyan,
		false
	)
	buildHexCrystal(
		folder,
		"BaseCrystalR3",
		cf * CFrame.new(5.15 * s, 0.0, 0.95 * s) * CFrame.Angles(math.rad(-12), 0, math.rad(-10)),
		0.44 * s,
		1.75 * s,
		PALETTE.CrystalIce,
		PALETTE.CrystalCore,
		false
	)

	-- Redemoinho em ESPIRAL ciano/branco com brilho central, anel giratório e raios de luz atrás do arco
	local vortexCenterCf = cf * CFrame.new(0, 4.25 * s, 0)
	local softBackdrop = makePart(
		folder,
		"PortalGlowSheet",
		vortexCenterCf,
		Vector3.new(5.9 * s, 8.1 * s, 0.16 * s),
		Color3.fromRGB(28, 196, 238),
		Enum.Material.SmoothPlastic,
		false,
		0.52
	)
	softBackdrop.CastShadow = false

	local coreOval = makeEllipsoid(
		folder,
		"PortalEnergyOval",
		vortexCenterCf,
		Vector3.new(4.9 * s, 7.1 * s, 0.24 * s),
		PALETTE.CrystalCyan,
		Enum.Material.Neon,
		false,
		0.58
	)
	coreOval.CastShadow = false

	-- 2 braços de espiral luminosa girando do centro branco até a borda ciano
	for arm = 0, 1 do
		local armModel = makeModel(folder, "PortalSpiralArm_" .. tostring(arm + 1))
		local armHub = makePart(
			armModel,
			"Center",
			vortexCenterCf,
			Vector3.new(0.2, 0.2, 0.2),
			PALETTE.CrystalCyan,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		armHub.CanQuery = false
		armModel.PrimaryPart = armHub
		armModel:SetAttribute("VortexIndex", arm + 1)

		local steps = 24
		local prevPt: Vector3? = nil
		for stepIdx = 0, steps do
			local t = stepIdx / steps
			local ang = t * math.pi * 3.5 + arm * math.pi
			local rx = (0.14 + t * 2.55) * s
			local ry = (0.18 + t * 3.50) * s
			local curPt = (vortexCenterCf * CFrame.new(math.cos(ang) * rx, math.sin(ang) * ry, 0)).Position
			if prevPt then
				local col = if t < 0.34
					then Color3.fromRGB(246, 255, 255)
					elseif t < 0.70 then PALETTE.CrystalCore
					else PALETTE.CrystalCyan
				local seg = makeSegment(
					armModel,
					"Swirl_" .. tostring(stepIdx),
					prevPt,
					curPt,
					(0.32 + (1 - t) * 0.16) * s,
					col,
					Enum.Material.Neon,
					true,
					false
				)
				if seg then
					seg.CastShadow = false
					seg.Transparency = 0.04 + t * 0.16
				end
			end
			prevPt = curPt
		end
	end

	-- Anel de luz externo giratório emoldurando o vórtice (com atributo SpinSpeed)
	local spinRing = makeNeonRing(
		folder,
		"PortalSpinningRing",
		vortexCenterCf * CFrame.Angles(math.rad(90), 0, 0),
		2.85 * s,
		0.22 * s,
		0.28 * s,
		30,
		PALETTE.CrystalCore,
		0.18
	)
	spinRing:SetAttribute("SpinSpeed", 0.85)

	makeNeonRing(
		folder,
		"PortalOuterGlowRing",
		vortexCenterCf * CFrame.Angles(math.rad(90), 0, 0),
		3.15 * s,
		0.16 * s,
		0.20 * s,
		30,
		PALETTE.CrystalCyan,
		0.45
	)

	-- Raios suaves de luz irradiando atrás do arco do portal (presença chamativa!)
	local raysOrigin = makePart(
		folder,
		"PortalRaysOrigin",
		vortexCenterCf * CFrame.new(0, 0.5 * s, 0.85 * s),
		Vector3.new(0.3, 0.3, 0.3),
		PALETTE.CrystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	raysOrigin.CanQuery = false
	local rayAtt0 = Instance.new("Attachment")
	rayAtt0.Parent = raysOrigin

	local rayAngles = { -55, -20, 20, 55 }
	for rIdx, deg in ipairs(rayAngles) do
		local radA = math.rad(deg)
		local rayLen = 11.5 * s
		local tipPt = makePart(
			folder,
			"PortalRayTip_" .. tostring(rIdx),
			vortexCenterCf
				* CFrame.new(math.sin(radA) * rayLen, 0.5 * s + math.cos(radA) * rayLen, 1.35 * s),
			Vector3.new(0.2, 0.2, 0.2),
			PALETTE.CrystalCyan,
			Enum.Material.SmoothPlastic,
			false,
			1
		)
		tipPt.CanQuery = false
		local rAtt1 = Instance.new("Attachment")
		rAtt1.Parent = tipPt
		local rayBeam = Instance.new("Beam")
		rayBeam.Name = "PortalBackRay_" .. tostring(rIdx)
		rayBeam.Attachment0 = rayAtt0
		rayBeam.Attachment1 = rAtt1
		rayBeam.FaceCamera = true
		rayBeam.Width0 = 1.6 * s
		rayBeam.Width1 = 3.6 * s
		rayBeam.LightEmission = 1
		rayBeam.LightInfluence = 0
		rayBeam.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, PALETTE.CrystalCore),
			ColorSequenceKeypoint.new(1, PALETTE.CrystalCyan),
		})
		rayBeam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.72),
			NumberSequenceKeypoint.new(0.55, 0.88),
			NumberSequenceKeypoint.new(1, 1.0),
		})
		rayBeam.Parent = raysOrigin
	end

	-- Luz FRACA e contida (NÃO tinge a pedra cinza de ciano!) + partículas subindo e poeira dourada
	local lightAnchor = makePart(
		folder,
		"PortalLightAnchor",
		vortexCenterCf,
		Vector3.new(4.4 * s, 6.2 * s, 0.6 * s),
		PALETTE.CrystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	lightAnchor.CanQuery = false

	local pLight = Instance.new("PointLight")
	pLight.Color = PALETTE.CrystalCyan
	pLight.Brightness = 0.72
	pLight.Range = 9.5 * s
	pLight.Parent = lightAnchor

	local risingMotes = Instance.new("ParticleEmitter")
	risingMotes.Name = "PortalRisingSparkles"
	risingMotes.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.CrystalCore),
		ColorSequenceKeypoint.new(0.5, PALETTE.AmberCore),
		ColorSequenceKeypoint.new(1, PALETTE.CrystalCyan),
	})
	risingMotes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.24),
		NumberSequenceKeypoint.new(0.4, 0.30),
		NumberSequenceKeypoint.new(1, 0),
	})
	risingMotes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	risingMotes.Lifetime = NumberRange.new(1.5, 2.8)
	risingMotes.Speed = NumberRange.new(1.4, 3.0)
	risingMotes.EmissionDirection = Enum.NormalId.Top
	risingMotes.SpreadAngle = Vector2.new(28, 28)
	risingMotes.Rate = 14
	risingMotes.LightEmission = 1
	risingMotes.Parent = lightAnchor

	-- Pedrinhas de caminho na areia na frente do portal (apenas na ilha)
	if includeSteps then
		local stepSpecs = {
			{ pos = Vector3.new(-1.8, 0.06, -3.1), size = Vector3.new(2.2, 0.28, 1.65) },
			{ pos = Vector3.new(1.2, 0.06, -3.6), size = Vector3.new(2.4, 0.28, 1.75) },
			{ pos = Vector3.new(-0.5, 0.06, -5.5), size = Vector3.new(2.05, 0.28, 1.55) },
			{ pos = Vector3.new(2.1, 0.06, -5.8), size = Vector3.new(1.65, 0.26, 1.35) },
		}
		for idx, st in ipairs(stepSpecs) do
			makeEllipsoid(
				folder,
				"SteppingStone_" .. tostring(idx),
				cf * CFrame.new(st.pos * s),
				st.size * s,
				PALETTE.StoneLight,
				Enum.Material.Concrete,
				true,
				0
			)
		end
	end

	return cf
end

-- ============================================================================
-- 7. PÍER CENTRAL CURVADO, PLACAS COM PEIXE ENTALHADO, BARRIL & CERCAS
-- ============================================================================

local function buildCentralBoardwalk(root: Model, origin: Vector3, rng: Random)
	local folder = makeFolder(root, "CentralBoardwalk")
	local pStart = origin + BOARDWALK_START
	local pEnd = origin + BOARDWALK_END
	local plankCount = 24
	local width = 7.1
	local woodTones =
		{ PALETTE.WoodWarm1, PALETTE.WoodWarm2, PALETTE.WoodWarm3, PALETTE.WoodWeathered }

	-- Curva sutil em arco ligando o caminho de areia do portal entre as duas lagoas
	local function sampleCurve(t: number): Vector3
		local base = pStart:Lerp(pEnd, t)
		local bend = math.sin(t * math.pi) * 1.15
		return base + Vector3.new(bend, 0, 0)
	end

	local prevL: Vector3? = nil
	local prevR: Vector3? = nil

	for i = 1, plankCount do
		local t = (i - 0.5) / plankCount
		local tNext = math.min(1, t + 0.02)
		local pos = sampleCurve(t)
		local ahead = sampleCurve(tNext)
		local cf = CFrame.lookAt(pos, ahead)

		local wVar = width + rng:NextNumber(-0.35, 0.35)
		local yaw = math.rad(rng:NextNumber(-1.4, 1.4))
		local plankLen = ((pEnd - pStart).Magnitude / plankCount) - 0.14

		makePart(
			folder,
			"WalkPlank_" .. tostring(i),
			cf * CFrame.new(rng:NextNumber(-0.12, 0.12), 0.10, 0) * CFrame.Angles(0, yaw, 0),
			Vector3.new(wVar, 0.34, plankLen),
			woodTones[((i - 1) % #woodTones) + 1],
			Enum.Material.WoodPlanks,
			true,
			0
		)

		local railL = (cf * CFrame.new(-width * 0.42, -0.22, 0)).Position
		local railR = (cf * CFrame.new(width * 0.42, -0.22, 0)).Position
		if prevL and prevR then
			makeSegment(
				folder,
				"RailL_" .. tostring(i),
				prevL,
				railL,
				0.52,
				PALETTE.WoodDark,
				Enum.Material.Wood,
				false,
				true
			)
			makeSegment(
				folder,
				"RailR_" .. tostring(i),
				prevR,
				railR,
				0.52,
				PALETTE.WoodDark,
				Enum.Material.Wood,
				false,
				true
			)
		end
		prevL = railL
		prevR = railR
	end

	-- Postes grossos com corda enrolada nas extremidades da passarela
	for _, endT in ipairs({ 0.02, 0.98 }) do
		local cPos = sampleCurve(endT)
		local cLook = sampleCurve(if endT < 0.5 then 0.08 else 0.92)
		local cf = CFrame.lookAt(cPos, cLook)
		for _, side in ipairs({ -1, 1 }) do
			local pPos = (cf * CFrame.new(side * (width * 0.5 + 0.25), 0.85, 0)).Position
			makeCylinderY(
				folder,
				"WalkPost",
				CFrame.new(pPos),
				2.35,
				1.12,
				PALETTE.WoodDark,
				Enum.Material.Wood,
				true,
				0
			)
			makeEllipsoid(
				folder,
				"WalkPostCap",
				CFrame.new(pPos + Vector3.new(0, 1.18, 0)),
				Vector3.new(1.12, 0.36, 1.12),
				PALETTE.WoodWarm3,
				Enum.Material.Wood,
				false,
				0
			)
			addRopeCoil(folder, "WalkPostRope", pPos + Vector3.new(0, 0.65, 0), 1.12, 3)
		end
	end
end

local function buildFishSignpost(
	parent: Instance,
	name: string,
	pos: Vector3,
	faceTarget: Vector3
): Model
	local sign = makeModel(parent, name)
	local cf = CFrame.lookAt(pos, Vector3.new(faceTarget.X, pos.Y, faceTarget.Z))

	local post = makeCylinderY(
		sign,
		"Post",
		cf * CFrame.new(0, 2.45, 0),
		5.1,
		0.84,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		true,
		0
	)
	makeEllipsoid(
		sign,
		"PostTopRound",
		cf * CFrame.new(0, 5.0, 0),
		Vector3.new(0.84, 0.36, 0.84),
		PALETTE.WoodWarm2,
		Enum.Material.Wood,
		false,
		0
	)
	sign.PrimaryPart = post

	local boardCf = cf * CFrame.new(0, 3.95, -0.38) * CFrame.Angles(0, 0, math.rad(1.8))
	makePart(
		sign,
		"BoardMain",
		boardCf,
		Vector3.new(4.3, 2.55, 0.40),
		PALETTE.WoodWarm1,
		Enum.Material.WoodPlanks,
		true,
		0
	)
	-- Moldura de borda em madeira escura
	makePart(
		sign,
		"FrameTop",
		boardCf * CFrame.new(0, 1.28, 0),
		Vector3.new(4.5, 0.24, 0.48),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)
	makePart(
		sign,
		"FrameBot",
		boardCf * CFrame.new(0, -1.28, 0),
		Vector3.new(4.45, 0.22, 0.48),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)
	makePart(
		sign,
		"FrameL",
		boardCf * CFrame.new(-2.15, 0, 0),
		Vector3.new(0.24, 2.65, 0.48),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)
	makePart(
		sign,
		"FrameR",
		boardCf * CFrame.new(2.15, 0, 0),
		Vector3.new(0.24, 2.65, 0.48),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)

	-- Peixe entalhado em tom creme de madeira clara com sulco escuro embaixo (NÃO branco chapado)
	local iconCf = boardCf * CFrame.new(0, 0, -0.23)
	makeEllipsoid(
		sign,
		"FishCarveShadow",
		iconCf * CFrame.new(-0.28, -0.05, 0.04),
		Vector3.new(2.22, 1.20, 0.10),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)
	makeEllipsoid(
		sign,
		"FishBody",
		iconCf * CFrame.new(-0.32, 0, 0),
		Vector3.new(2.05, 1.05, 0.14),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0
	)
	makePart(
		sign,
		"FishTailTop",
		iconCf * CFrame.new(0.96, 0.28, 0) * CFrame.Angles(0, 0, math.rad(30)),
		Vector3.new(0.82, 0.28, 0.12),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0
	)
	makePart(
		sign,
		"FishTailBot",
		iconCf * CFrame.new(0.96, -0.28, 0) * CFrame.Angles(0, 0, math.rad(-30)),
		Vector3.new(0.82, 0.28, 0.12),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0
	)
	makeEllipsoid(
		sign,
		"FishFinTop",
		iconCf * CFrame.new(-0.1, 0.56, 0) * CFrame.Angles(0, 0, math.rad(-18)),
		Vector3.new(0.62, 0.28, 0.10),
		PALETTE.WoodCarved,
		Enum.Material.Wood,
		false,
		0
	)
	makeEllipsoid(
		sign,
		"FishEye",
		iconCf * CFrame.new(-0.92, 0.12, -0.04),
		Vector3.new(0.22, 0.22, 0.10),
		PALETTE.WoodDark,
		Enum.Material.SmoothPlastic,
		false,
		0
	)

	return sign
end

local function buildBaitBarrel(parent: Instance, pos: Vector3): Model
	local barrel = makeModel(parent, "BaitBarrel")
	local body = makeCylinderY(
		barrel,
		"BarrelBody",
		CFrame.new(pos + Vector3.new(0, 1.6, 0)),
		3.2,
		2.75,
		PALETTE.WoodWarm2,
		Enum.Material.WoodPlanks,
		true,
		0
	)
	barrel.PrimaryPart = body
	makeCylinderY(
		barrel,
		"BarrelRimTop",
		CFrame.new(pos + Vector3.new(0, 3.15, 0)),
		0.22,
		2.84,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)

	-- Aros de ferro azulados (fiel à especificação)
	makeCylinderY(
		barrel,
		"IronBandTop",
		CFrame.new(pos + Vector3.new(0, 2.65, 0)),
		0.28,
		2.90,
		PALETTE.BarrelIronBlue,
		Enum.Material.Metal,
		false,
		0
	)
	makeCylinderY(
		barrel,
		"IronBandBot",
		CFrame.new(pos + Vector3.new(0, 0.65, 0)),
		0.28,
		2.90,
		PALETTE.BarrelIronBlue,
		Enum.Material.Metal,
		false,
		0
	)

	-- Água/gelo e 3 peixes coloridos (vermelho, azul, roxo) aparecendo na boca do barril
	makeCylinderY(
		barrel,
		"WaterFill",
		CFrame.new(pos + Vector3.new(0, 3.08, 0)),
		0.16,
		2.38,
		Color3.fromRGB(148, 224, 248),
		Enum.Material.Ice,
		false,
		0.15
	)
	local baitSpecs = {
		{
			off = Vector3.new(-0.48, 3.38, 0.18),
			rot = Vector3.new(36, 25, 10),
			col = Color3.fromRGB(238, 86, 76),
		},
		{
			off = Vector3.new(0.45, 3.44, -0.22),
			rot = Vector3.new(-28, 125, -14),
			col = Color3.fromRGB(76, 178, 248),
		},
		{
			off = Vector3.new(0.05, 3.46, 0.44),
			rot = Vector3.new(42, -55, 8),
			col = Color3.fromRGB(178, 96, 236),
		},
	}
	for idx, bs in ipairs(baitSpecs) do
		local fCf = CFrame.new(pos + bs.off)
			* CFrame.Angles(math.rad(bs.rot.X), math.rad(bs.rot.Y), math.rad(bs.rot.Z))
		makeEllipsoid(
			barrel,
			"BaitFish_" .. tostring(idx),
			fCf,
			Vector3.new(0.56, 0.36, 1.35),
			bs.col,
			Enum.Material.SmoothPlastic,
			false,
			0
		)
		makeWedge(
			barrel,
			"BaitTail_" .. tostring(idx),
			fCf * CFrame.new(0, 0, 0.72),
			Vector3.new(0.14, 0.56, 0.45),
			bs.col,
			Enum.Material.SmoothPlastic,
			false,
			0
		)
	end

	return barrel
end

local function buildWoodenCrate(parent: Instance, name: string, cf: CFrame, sz: number): Model
	local crate = makeModel(parent, name)
	local body = makePart(
		crate,
		"CrateCore",
		cf * CFrame.new(0, sz * 0.5, 0),
		Vector3.new(sz, sz, sz),
		PALETTE.WoodWarm2,
		Enum.Material.WoodPlanks,
		false,
		0
	)
	crate.PrimaryPart = body
	-- Molduras externas da caixa
	for _, ySide in ipairs({ -sz * 0.44, sz * 0.44 }) do
		makePart(
			crate,
			"RimH",
			cf * CFrame.new(0, sz * 0.5 + ySide, 0),
			Vector3.new(sz * 1.06, sz * 0.14, sz * 1.06),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0
		)
	end
	makePart(
		crate,
		"CrossBrace",
		cf * CFrame.new(0, sz * 0.5, -sz * 0.51) * CFrame.Angles(0, 0, math.rad(45)),
		Vector3.new(sz * 1.15, sz * 0.14, 0.10),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)
	return crate
end

local function buildFishingBasketAndNet(parent: Instance, name: string, pos: Vector3): Model
	local kit = makeModel(parent, name)
	local basket = makeCylinderY(
		kit,
		"WovenBasket",
		CFrame.new(pos + Vector3.new(0, 0.85, 0)),
		1.7,
		1.95,
		PALETTE.RopeTan,
		Enum.Material.Fabric,
		false,
		0
	)
	kit.PrimaryPart = basket
	for _, bandY in ipairs({ 0.42, 0.92, 1.40 }) do
		makeCylinderY(
			kit,
			"BasketBand",
			CFrame.new(pos + Vector3.new(0, bandY, 0)),
			0.14,
			2.04,
			PALETTE.WoodWarm2,
			Enum.Material.Wood,
			false,
			0
		)
	end
	makeCylinderY(
		kit,
		"BasketRim",
		CFrame.new(pos + Vector3.new(0, 1.68, 0)),
		0.22,
		2.12,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)
	-- Peixinho azul-prateado saindo da boca do cesto
	local basketFish = makeEllipsoid(
		kit,
		"BasketFish",
		CFrame.new(pos + Vector3.new(0.15, 1.95, -0.1))
			* CFrame.Angles(math.rad(38), math.rad(25), 0),
		Vector3.new(0.45, 0.28, 1.15),
		Color3.fromRGB(108, 198, 246),
		Enum.Material.SmoothPlastic,
		false,
		0
	)
	basketFish.CastShadow = false
	-- Rede dobrada/enrolada ao lado do cesto com boias pequeninas
	local netRoll = makeEllipsoid(
		kit,
		"FishingNetRoll",
		CFrame.new(pos + Vector3.new(1.45, 0.42, 0.35)) * CFrame.Angles(0, math.rad(28), 0),
		Vector3.new(2.2, 0.85, 1.25),
		Color3.fromRGB(192, 186, 168),
		Enum.Material.Fabric,
		false,
		0
	)
	netRoll.CastShadow = false
	for f = 1, 3 do
		local cork = makeEllipsoid(
			kit,
			"NetCork_" .. tostring(f),
			CFrame.new(pos + Vector3.new(0.85 + f * 0.45, 0.68, 0.72)),
			Vector3.new(0.32, 0.28, 0.32),
			if f % 2 == 0 then PALETTE.BuoyOrange else PALETTE.BuoyWhite,
			Enum.Material.SmoothPlastic,
			false,
			0
		)
		cork.CastShadow = false
	end
	return kit
end

local function buildAnchoredRowboat(parent: Instance, boatPos: Vector3, moorPostPos: Vector3): Model
	local boat = makeModel(parent, "AnchoredRowboat")
	local cf = CFrame.new(boatPos) * CFrame.Angles(math.rad(-2), math.rad(32), math.rad(3))

	-- Casco estilizado de madeira quente
	local hull = makeEllipsoid(
		boat,
		"Hull",
		cf,
		Vector3.new(4.2, 1.85, 8.6),
		PALETTE.WoodWarm1,
		Enum.Material.WoodPlanks,
		false,
		0
	)
	boat.PrimaryPart = hull

	local deckInside = makeEllipsoid(
		boat,
		"DeckFloor",
		cf * CFrame.new(0, 0.42, 0),
		Vector3.new(3.3, 0.45, 6.8),
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)
	deckInside.CastShadow = false

	-- Borda azul-ciano marítima e bancos transversais
	local gunwale = makeEllipsoid(
		boat,
		"BlueStripe",
		cf * CFrame.new(0, 0.52, 0),
		Vector3.new(4.32, 0.32, 8.65),
		PALETTE.BarrelIronBlue,
		Enum.Material.Wood,
		false,
		0
	)
	gunwale.CastShadow = false

	for _, bz in ipairs({ -1.35, 1.35 }) do
		makePart(
			boat,
			"Bench",
			cf * CFrame.new(0, 0.78, bz),
			Vector3.new(3.35, 0.24, 0.92),
			PALETTE.WoodWarm3,
			Enum.Material.WoodPlanks,
			false,
			0
		)
	end

	-- Par de remos apoiados no barco
	for _, side in ipairs({ -1, 1 }) do
		local oarCf = cf
			* CFrame.new(side * 1.15, 0.95, 0.2)
			* CFrame.Angles(math.rad(6), math.rad(side * 14), math.rad(side * -8))
		makeSegment(
			boat,
			"OarShaft",
			(oarCf * CFrame.new(0, 0, -2.2)).Position,
			(oarCf * CFrame.new(0, 0, 2.4)).Position,
			0.20,
			PALETTE.WoodCarved,
			Enum.Material.Wood,
			true,
			false
		)
		makePart(
			boat,
			"OarBlade",
			oarCf * CFrame.new(0, 0, 2.65),
			Vector3.new(0.65, 0.10, 1.25),
			PALETTE.WoodWarm3,
			Enum.Material.Wood,
			false,
			0
		)
	end

	-- Mini lanterna âmbar quente na proa do barquinho
	buildLanternUnit(boat, "BoatBowLantern", (cf * CFrame.new(0, 1.35, -3.3)).Position, 0.55)

	-- Estaca na borda da ilha + corda bamba amarrando o barco
	makeCylinderY(
		boat,
		"MooringPost",
		CFrame.new(moorPostPos + Vector3.new(0, 1.15, 0)),
		2.6,
		0.86,
		PALETTE.WoodDark,
		Enum.Material.Wood,
		false,
		0
	)
	addRopeCoil(boat, "MooringCoil", moorPostPos + Vector3.new(0, 1.85, 0), 0.86, 2)

	local ropeStart = moorPostPos + Vector3.new(0, 1.85, 0)
	local ropeEnd = (cf * CFrame.new(0, 0.85, -3.9)).Position
	local segs = 7
	local prev = ropeStart
	for s = 1, segs do
		local t = s / segs
		local pt = ropeStart:Lerp(ropeEnd, t) - Vector3.new(0, 3.2 * t * (1 - t), 0)
		makeSegment(
			boat,
			"MoorRope_" .. tostring(s),
			prev,
			pt,
			0.22,
			PALETTE.RopeTan,
			Enum.Material.Fabric,
			true,
			false
		)
		prev = pt
	end

	-- Ondinha suave em volta do casco na água
	makeNeonRing(
		boat,
		"BoatRipple",
		CFrame.new(boatPos + Vector3.new(0, -0.15, 0)),
		4.8,
		0.14,
		0.05,
		24,
		PALETTE.WaterfallFoam,
		0.62
	)

	return boat
end

local function buildPropsAndFences(root: Model, origin: Vector3)
	local folder = makeFolder(root, "PropsLevel1")

	local sign1Pos = origin + Vector3.new(-24.2, getTopSurfaceY(-24.2, 22.0), 22.0)
	buildFishSignpost(folder, "Signpost_Focus", sign1Pos, origin + Vector3.new(-32, 0, 36))

	local sign2Pos = origin + Vector3.new(3.8, getTopSurfaceY(3.8, 29.5), 29.5)
	buildFishSignpost(folder, "Signpost_Instinct", sign2Pos, origin + Vector3.new(8, 0, 44))

	local barrelPos = origin + Vector3.new(-2.8, getTopSurfaceY(-2.8, 27.6), 27.6)
	buildBaitBarrel(folder, barrelPos)

	-- Caixotes artesanais e cestos/redes de pesca (CanCollide=false, fora das rotas de caminhada)
	buildWoodenCrate(
		folder,
		"SupplyCrate_1",
		CFrame.new(origin + Vector3.new(10.8, 0.0, 29.6)) * CFrame.Angles(0, math.rad(18), 0),
		2.05
	)
	buildWoodenCrate(
		folder,
		"SupplyCrate_2",
		CFrame.new(origin + Vector3.new(12.9, 0.0, 28.4)) * CFrame.Angles(0, math.rad(-24), 0),
		1.55
	)
	buildWoodenCrate(
		folder,
		"SupplyCrate_3",
		CFrame.new(origin + Vector3.new(11.3, 2.05, 29.4)) * CFrame.Angles(0, math.rad(38), 0),
		1.30
	)
	buildFishingBasketAndNet(folder, "FocusFishingKit", origin + Vector3.new(-28.4, 0.0, -14.8))
	buildFishingBasketAndNet(folder, "InstinctFishingKit", origin + Vector3.new(11.4, 0.0, 22.4))

	-- Barquinho de madeira ancorado perto da borda esquerda no mar turquesa
	buildAnchoredRowboat(
		folder,
		origin + Vector3.new(-52.5, -11.65, 21.5),
		origin + Vector3.new(-38.5, -0.22, 18.8)
	)

	-- Cerca de corda frente-direita com nós nos postes e corda curvada
	buildRopeFence(folder, "Fence_FrontRight", {
		origin + Vector3.new(10.5, 0, 32.5),
		origin + Vector3.new(19.2, 0, 30.2),
		origin + Vector3.new(28.0, 0, 26.2),
	})
end

-- ============================================================================
-- 8. NUVENS CREMOSAS E FOFAS (MUITAS ESFERAS + BASE ACHATADA COM SOMBRA)
-- ============================================================================

local function buildStylizedClouds(root: Model, origin: Vector3, rng: Random)
	local clouds = makeFolder(root, "StylizedClouds")
	local cloudConfigs = {
		{ pos = Vector3.new(-64, 24, -30), scale = 1.28 },
		{ pos = Vector3.new(6, 33, -64), scale = 0.92 },
		{ pos = Vector3.new(64, 26, -32), scale = 1.22 },
	}

	for cIdx, cfg in ipairs(cloudConfigs) do
		local cloud = makeModel(clouds, "Cloud_" .. tostring(cIdx))
		local base = origin + cfg.pos
		local s = cfg.scale

		-- Base achatada ligeiramente mais escura (sombra quente embaixo)
		local under = makeEllipsoid(
			cloud,
			"CloudUnder",
			CFrame.new(base + Vector3.new(0, -1.6 * s, 0)),
			Vector3.new(24 * s, 4.6 * s, 11.5 * s),
			PALETTE.CloudShade,
			Enum.Material.SmoothPlastic,
			false,
			0
		)
		under.CastShadow = false

		-- 16 esferas de tamanhos variados formando uma nuvem fofa e cremosa
		local puffSpecs = {
			{ x = -8.8, y = -0.3, z = 0.4, r = 5.4 },
			{ x = -6.2, y = 1.6, z = -0.8, r = 6.6 },
			{ x = -3.0, y = 3.2, z = 0.2, r = 8.0 },
			{ x = 0.8, y = 3.8, z = -0.5, r = 8.8 },
			{ x = 4.6, y = 2.6, z = 0.6, r = 7.4 },
			{ x = 8.0, y = 0.6, z = -0.4, r = 6.0 },
			{ x = 10.2, y = -0.5, z = 0.5, r = 4.6 },
			{ x = -4.6, y = 0.4, z = 2.8, r = 5.2 },
			{ x = 0.4, y = 1.2, z = 3.2, r = 6.2 },
			{ x = 5.2, y = 0.5, z = 2.6, r = 5.0 },
			{ x = -2.2, y = 0.8, z = -3.0, r = 5.6 },
			{ x = 3.2, y = 1.0, z = -2.8, r = 5.4 },
		}
		for pIdx, ps in ipairs(puffSpecs) do
			local jitter = Vector3.new(
				rng:NextNumber(-0.5, 0.5),
				rng:NextNumber(-0.2, 0.35),
				rng:NextNumber(-0.4, 0.4)
			) * s
			local puff = makeEllipsoid(
				cloud,
				"Puff_" .. tostring(pIdx),
				CFrame.new(base + Vector3.new(ps.x * s, ps.y * s, ps.z * s) + jitter),
				Vector3.new(ps.r * s * 1.12, ps.r * s * 0.86, ps.r * s),
				PALETTE.CloudTop,
				Enum.Material.SmoothPlastic,
				false,
				0
			)
			puff.CastShadow = false
		end
	end
end

-- ============================================================================
-- 9. CONTRATO COM O SERVIDOR (FILHOS DIRETOS, TAGS E ATRIBUTOS EXATOS)
-- ============================================================================

local function buildGameplayZones(root: Model, origin: Vector3, portalCf: CFrame)
	-- 1. ArrivalSpawn (tag ZoneSpawn, Destination="training_1")
	-- Posicionado na areia na frente do portal, olhando para a passarela (caminho 100% livre)
	local arrivalPos = (portalCf * CFrame.new(0, 1.8, -5.2)).Position
	local arrivalTarget = origin + BOARDWALK_START + Vector3.new(0, 1.8, 0)
	local arrivalSpawn = makePart(
		root,
		"ArrivalSpawn",
		CFrame.lookAt(arrivalPos, arrivalTarget),
		Vector3.new(4, 1, 4),
		PALETTE.CrystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	arrivalSpawn.CastShadow = false
	arrivalSpawn.CanQuery = false
	arrivalSpawn:SetAttribute("Destination", "training_1")
	CollectionService:AddTag(arrivalSpawn, "ZoneSpawn")

	-- 2. ReturnPortal (tag ZonePortal, PortalId="training_1_return", ZoneId="lagoon", Destination="main")
	local returnPortal = makePart(
		root,
		"ReturnPortal",
		portalCf * CFrame.new(0, 4.2, 0),
		Vector3.new(6.2, 8.2, 2.4),
		PALETTE.CrystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	returnPortal.CastShadow = false
	returnPortal.CanTouch = true
	returnPortal.CanQuery = true
	returnPortal:SetAttribute("PortalId", "training_1_return")
	returnPortal:SetAttribute("ZoneId", "lagoon")
	returnPortal:SetAttribute("Destination", "main")
	CollectionService:AddTag(returnPortal, "ZonePortal")

	-- 3. FocusSpot (tag TrainingSpot, TrainingIsland=1, TrainingStat="Control")
	local focusCenter = origin + Vector3.new(FOCUS_CENTER.X, 1.0, FOCUS_CENTER.Y)
	local focusSpotPos = focusCenter + Vector3.new(-8.2, 0.3, -8.4)
	local focusSpot = makePart(
		root,
		"FocusSpot",
		CFrame.lookAt(focusSpotPos, focusCenter),
		Vector3.new(5.5, 2.0, 5.5),
		PALETTE.FocusWater,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	focusSpot.CastShadow = false
	focusSpot:SetAttribute("TrainingIsland", 1)
	focusSpot:SetAttribute("TrainingStat", "Control")
	CollectionService:AddTag(focusSpot, "TrainingSpot")

	-- 4. InstinctSpot (tag TrainingSpot, TrainingIsland=1, TrainingStat="Instinct")
	local instinctCenter = origin + Vector3.new(INSTINCT_CENTER.X, 1.0, INSTINCT_CENTER.Y)
	local instinctSpotPos = instinctCenter + Vector3.new(-9.8, 0.3, 7.2)
	local instinctSpot = makePart(
		root,
		"InstinctSpot",
		CFrame.lookAt(instinctSpotPos, instinctCenter),
		Vector3.new(5.5, 2.0, 5.5),
		PALETTE.InstinctWater,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	instinctSpot.CastShadow = false
	instinctSpot:SetAttribute("TrainingIsland", 1)
	instinctSpot:SetAttribute("TrainingStat", "Instinct")
	CollectionService:AddTag(instinctSpot, "TrainingSpot")

	-- 5. CameraShot (ângulo exato da referência A: origin + (0, 48, 100), FOV 55)
	local cameraShot = makePart(
		root,
		"CameraShot",
		CFrame.lookAt(origin + Vector3.new(0, 48, 100), origin),
		Vector3.new(1, 1, 1),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	cameraShot.CastShadow = false
	cameraShot.CanQuery = false
	cameraShot:SetAttribute("FieldOfView", 55)
end

-- ============================================================================
-- 10. ILUMINAÇÃO OPCIONAL (APENAS PARA PRINTS — NÃO CHAMADA NO build())
-- ============================================================================

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

	Lighting.ClockTime = 9.4
	Lighting.GeographicLatitude = 26
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(118, 134, 152)
	Lighting.OutdoorAmbient = Color3.fromRGB(146, 156, 170)
	Lighting.EnvironmentDiffuseScale = 0.72
	Lighting.EnvironmentSpecularScale = 0.58

	local cc = Lighting:FindFirstChild("RefPreview_ColorCorrection") :: ColorCorrectionEffect?
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "RefPreview_ColorCorrection"
		cc.Parent = Lighting
	end
	if cc then
		cc.TintColor = Color3.fromRGB(255, 248, 236)
		cc.Saturation = 0.14
		cc.Contrast = 0.06
		cc.Brightness = 0.02
	end

	local rays = Lighting:FindFirstChild("RefPreview_SunRays") :: SunRaysEffect?
	if not rays then
		rays = Instance.new("SunRaysEffect")
		rays.Name = "RefPreview_SunRays"
		rays.Parent = Lighting
	end
	if rays then
		rays.Intensity = 0.08
		rays.Spread = 0.55
	end

	local bloom = Lighting:FindFirstChild("RefPreview_Bloom") :: BloomEffect?
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "RefPreview_Bloom"
		bloom.Parent = Lighting
	end
	if bloom then
		bloom.Intensity = 0.36
		bloom.Size = 20
		bloom.Threshold = 1.08
	end
end

function Builder.restoreLighting()
	if savedLighting then
		Lighting.ClockTime = savedLighting.ClockTime
		Lighting.GeographicLatitude = savedLighting.GeographicLatitude
		Lighting.Brightness = savedLighting.Brightness
		Lighting.Ambient = savedLighting.Ambient
		Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
		Lighting.EnvironmentDiffuseScale = savedLighting.EnvironmentDiffuseScale
		Lighting.EnvironmentSpecularScale = savedLighting.EnvironmentSpecularScale
		savedLighting = nil
	end

	for _, name in ipairs({ "RefPreview_ColorCorrection", "RefPreview_SunRays", "RefPreview_Bloom" }) do
		local inst = Lighting:FindFirstChild(name)
		if inst then
			inst:Destroy()
		end
	end
end

-- ============================================================================
-- HUB PORTAL TO ISLAND 1 (idempotent). Builds the same stone arch as the island's arrival portal
-- inside Workspace.TrainingPortalsHub, wired to the server's ZonePortal system.
-- Usage (Edit): mod.buildHubPortal(workspace.TrainingPortalsHub, worldCf) where worldCf is the
-- portal BASE (on the deck top). Front side faces -Z of worldCf (the side players approach from).
-- ============================================================================

local HUB_PORTAL_NAME = "Portal_Training_Apprentice"

local function makeSignFace(
	board: Part,
	face: Enum.NormalId,
	guiName: string,
	titleText: string,
	subtitleText: string
)
	local gui = Instance.new("SurfaceGui")
	gui.Name = guiName
	gui.Face = face
	gui.Adornee = board
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(14, 22, 42)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Name = "SignStroke"
	stroke.Color = PALETTE.CrystalCyan
	stroke.Thickness = 4
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.94, 0.54)
	title.Position = UDim2.fromScale(0.03, 0.06)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = titleText
	title.Parent = frame

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.Size = UDim2.fromScale(0.92, 0.36)
	subtitle.Position = UDim2.fromScale(0.04, 0.58)
	subtitle.Font = Enum.Font.FredokaOne
	subtitle.TextScaled = true
	subtitle.TextColor3 = PALETTE.CrystalCyan
	subtitle.Text = subtitleText
	subtitle.Parent = frame

	gui.Parent = board
end

export type HubPortalOptions = {
	name: string?,
	scale: number?,
	portalId: string?,
	extraTag: string?,
	deckExtension: boolean?,
	title: string?,
	subtitle: string?,
}

function Builder.buildHubPortal(
	parent: Instance,
	worldBase: CFrame,
	options: HubPortalOptions?
): Model
	local opts: HubPortalOptions = options or {}
	local portalName = opts.name or HUB_PORTAL_NAME
	-- Escala padrão 1.19 iguala a altura (~12.6 studs no topo da viga) aos portais vizinhos (Recife/Abismo/Celestial)
	local scale = opts.scale or 1.19
	local old = parent:FindFirstChild(portalName)
	if old then
		old:Destroy()
	end

	local model = makeModel(parent, portalName)
	local builtCf = buildArrivalPortal(model, Vector3.zero, Random.new(SEED), scale, false)
	-- The arrival portal's front (where players stand) is its -Z side; keep that convention.
	model.WorldPivot = builtCf
	model:PivotTo(worldBase)

	-- Haste/suporte central luminoso + hastes laterais ligando o arco à placa (sem placa flutuando)
	local signY = 13.11 * scale -- em scale=1.19 -> 15.60 acima da base (Y=25.97, nivelado com Recife/Abismo/Celestial!)
	local supportStem = makePart(
		model,
		"ArchSignKeystone",
		worldBase * CFrame.new(0, signY - 1.45 * scale, 0),
		Vector3.new(1.55, 1.95, 1.45) * scale,
		PALETTE.CrystalCyan,
		Enum.Material.Neon,
		false,
		0
	)
	supportStem.CastShadow = false
	for _, xSide in ipairs({ -2.45, 2.45 }) do
		local rod = makeCylinderY(
			model,
			"SignSupportRod_" .. (if xSide < 0 then "L" else "R"),
			worldBase * CFrame.new(xSide * scale, signY - 1.85 * scale, 0),
			2.1 * scale,
			0.30 * scale,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0
		)
		rod.CastShadow = false
	end

	local trigger = makePart(
		model,
		"PortalTrigger",
		worldBase * CFrame.new(0, 5.4 * scale, 0),
		Vector3.new(7.2, 9.4, 4.8) * scale,
		PALETTE.CrystalCyan,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	trigger.CastShadow = false
	trigger.CanTouch = true
	trigger.CanQuery = true
	trigger:SetAttribute("PortalId", opts.portalId or "main_to_training_1")
	trigger:SetAttribute("ZoneId", "lagoon")
	trigger:SetAttribute("Destination", "training_1")
	trigger:SetAttribute("TrainingIsland", 1)
	trigger:SetAttribute("PrimaryColor", PALETTE.CrystalCyan)
	trigger:SetAttribute("AccentColor", PALETTE.CrystalCore)
	CollectionService:AddTag(trigger, "ZonePortal")
	if opts.extraTag then
		CollectionService:AddTag(trigger, opts.extraTag)
	end

	local boardScale = if opts.scale then scale else 1.0
	local board = makePart(
		model,
		"PortalSignBoard",
		worldBase * CFrame.new(0, signY, 0),
		Vector3.new(9.6, 2.5, 0.45) * boardScale,
		Color3.fromRGB(14, 22, 42),
		Enum.Material.SmoothPlastic,
		false,
		0
	)
	board.CastShadow = false
	local titleText = opts.title or "ILHA DO APRENDIZ"
	local subtitleText = opts.subtitle or "Treino x1 · Grátis"
	makeSignFace(board, Enum.NormalId.Front, "PortalSignGui", titleText, subtitleText)
	makeSignFace(board, Enum.NormalId.Back, "PortalSignGuiBack", titleText, subtitleText)

	-- Extend the hub deck under the new portal (same deck part, 10 studs further along its X axis).
	local wantDeckExt = opts.deckExtension ~= false
	local oldExt = parent:FindFirstChild("TrainingPortalDeckExt1")
	if oldExt then
		oldExt:Destroy()
	end
	local deck = parent:FindFirstChild("TrainingPortalDeck")
	if wantDeckExt and deck and deck:IsA("BasePart") then
		local ext = deck:Clone()
		ext.Name = "TrainingPortalDeckExt1"
		ext.Size = Vector3.new(10, deck.Size.Y, deck.Size.Z)
		ext.CFrame = deck.CFrame * CFrame.new(-(deck.Size.X * 0.5 + 4.0), 0, 0)
		ext.Parent = parent
	end

	return model
end

-- ============================================================================
-- LAGOON GATE (hub). Replaces the old hub training deck with a wooden passage that leads to the
-- Training Island 1 portal, framed by a rebuilt waterfall. Idempotent.
--   * Old training deck parts are MOVED (never deleted) to ServerStorage.Archive_HubTraining.
--   * Result: Workspace.Island.TrainingGate (bridge, landing, portal, signs, waterfall FX).
--   * The portal trigger is tagged ZonePortal + TrainingPortalGuide (tutorial arrow target).
-- Usage (Edit): require(clone of this module).buildLagoonGate()
-- ============================================================================

local ServerStorage = game:GetService("ServerStorage")

local GATE_NAME = "TrainingGate"
local ARCHIVE_NAME = "Archive_HubTraining"
local DECK_TOP_Y = 10.32
local BRIDGE_Z = -5.5
local BRIDGE_X0 = -25.0
local BRIDGE_X1 = -38.5
local LANDING_X = -43.2
local LANDING_R = 6.4
local PORTAL_X = -46.4
local FALL_X = -49.2
local WATER_Y = 8.25

local function archiveLagoonParts()
	local lagoon = Workspace:FindFirstChild("Island")
		and Workspace.Island:FindFirstChild("TrainingLagoon")
	if not lagoon then
		return 0
	end
	local archive = ServerStorage:FindFirstChild(ARCHIVE_NAME)
		or makeFolder(ServerStorage, ARCHIVE_NAME)
	local moved = 0
	for _, name in
		{
			"TrainingDeckOverhaul",
			"TrainingSpot",
			"TrainingRingFoundation",
			"Sign_TRAININGLAGOONPRACTICE",
		}
	do
		local inst = lagoon:FindFirstChild(name)
		if inst then
			-- A TrainingSpot must not stay tagged while archived (the server would keep hooking it).
			if inst:IsA("BasePart") then
				CollectionService:RemoveTag(inst, "TrainingSpot")
			end
			inst.Parent = archive
			moved += 1
		end
	end
	-- Old straight waterfall stripes are replaced by the new curtain.
	local hero = lagoon:FindFirstChild("WaterfallHero")
	if hero then
		for _, name in { "WaterStreamOuter", "WaterStreamCore", "SplashFoam" } do
			local inst = hero:FindFirstChild(name)
			if inst then
				inst.Parent = archive
				moved += 1
			end
		end
	end
	return moved
end

local function buildBridge(gate: Model, rng: Random)
	local folder = makeFolder(gate, "Bridge")
	local length = BRIDGE_X0 - BRIDGE_X1
	local plankCount = 8
	local plankLen = length / plankCount
	local tones = { PALETTE.WoodWarm1, PALETTE.WoodWarm2, PALETTE.WoodWarm3, PALETTE.WoodWeathered }
	for i = 1, plankCount do
		local x = BRIDGE_X0 - (i - 0.5) * plankLen
		makePart(
			folder,
			"Plank_" .. tostring(i),
			CFrame.new(x, DECK_TOP_Y - 0.28 + rng:NextNumber(-0.012, 0.012), BRIDGE_Z)
				* CFrame.Angles(0, math.rad(rng:NextNumber(-1.4, 1.4)), 0),
			Vector3.new(plankLen - 0.12, 0.56, 7.4 + rng:NextNumber(-0.1, 0.25)),
			tones[(i % #tones) + 1],
			Enum.Material.WoodPlanks,
			true,
			0
		)
	end
	-- Under beams + pilings
	for _, side in { -1, 1 } do
		makePart(
			folder,
			"Beam",
			CFrame.new((BRIDGE_X0 + BRIDGE_X1) * 0.5, DECK_TOP_Y - 0.9, BRIDGE_Z + side * 3.0),
			Vector3.new(length, 0.6, 0.7),
			PALETTE.WoodDark,
			Enum.Material.Wood,
			true,
			0
		)
	end
	for i = 0, 3 do
		local x = BRIDGE_X0 - 1.5 - i * 3.9
		for _, side in { -1, 1 } do
			makeCylinderY(
				folder,
				"Piling",
				CFrame.new(x, (DECK_TOP_Y - 0.9 + 5.2) * 0.5, BRIDGE_Z + side * 3.4),
				DECK_TOP_Y - 0.9 - 5.2,
				0.9,
				PALETTE.WoodDark,
				Enum.Material.Wood,
				false,
				0
			)
		end
	end

	-- Rails: posts every ~3.2 studs, sagging rope between them, lantern posts at the entrance.
	local railZ = { BRIDGE_Z - 3.55, BRIDGE_Z + 3.55 }
	for _, z in railZ do
		local prev: Vector3? = nil
		for i = 0, 4 do
			local x = BRIDGE_X0 - 0.6 - i * ((length - 1.2) / 4)
			local top = Vector3.new(x, DECK_TOP_Y + 2.7, z)
			makeCylinderY(
				folder,
				"RailPost",
				CFrame.new(x, DECK_TOP_Y + 1.35, z),
				2.7,
				0.7,
				PALETTE.WoodWarm2,
				Enum.Material.Wood,
				true,
				0
			)
			makeCylinderY(
				folder,
				"RailCap",
				CFrame.new(x, DECK_TOP_Y + 2.78, z),
				0.2,
				0.84,
				PALETTE.WoodWarm3,
				Enum.Material.Wood,
				false,
				0
			)
			addRopeCoil(folder, "RailCoil", Vector3.new(x, DECK_TOP_Y + 2.35, z), 0.7, 2)
			if prev then
				local last = prev
				for s = 1, 6 do
					local t = s / 6
					local pt = prev:Lerp(top, t) - Vector3.new(0, 4 * 0.5 * t * (1 - t), 0)
					makeSegment(
						folder,
						"Rope",
						last,
						pt,
						0.26,
						PALETTE.RopeTan,
						Enum.Material.Fabric,
						true,
						false
					)
					last = pt
				end
			end
			prev = top
		end
	end
	-- Entrance lanterns (amber)
	for _, z in railZ do
		local lamp = Vector3.new(BRIDGE_X0 + 0.2, DECK_TOP_Y + 4.6, z)
		makeCylinderY(
			folder,
			"LampPole",
			CFrame.new(lamp.X, DECK_TOP_Y + 2.3, z),
			4.6,
			0.5,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0
		)
		local globe = makeEllipsoid(
			folder,
			"LampGlobe",
			CFrame.new(lamp),
			Vector3.new(1.1, 1.3, 1.1),
			PALETTE.AmberCore,
			Enum.Material.Neon,
			false,
			0.1
		)
		globe.CastShadow = false
		local light = Instance.new("PointLight")
		light.Color = PALETTE.AmberGlow
		light.Brightness = 1.4
		light.Range = 14
		light.Parent = globe
	end
end

local function buildLanding(gate: Model, rng: Random)
	local folder = makeFolder(gate, "Landing")
	local center = Vector3.new(LANDING_X, DECK_TOP_Y - 0.4, BRIDGE_Z)
	makeCylinderY(
		folder,
		"LandingStone",
		CFrame.new(center),
		0.8,
		LANDING_R * 2,
		PALETTE.StoneLight,
		Enum.Material.Cobblestone,
		true,
		0
	)
	makeCylinderY(
		folder,
		"LandingRim",
		CFrame.new(center + Vector3.new(0, -0.3, 0)),
		0.5,
		LANDING_R * 2 + 1.0,
		PALETTE.WoodWarm2,
		Enum.Material.Wood,
		true,
		0
	)
	local ring = makeNeonRing(
		folder,
		"LandingRing",
		CFrame.new(center + Vector3.new(0, 0.44, 0)),
		LANDING_R - 1.2,
		0.28,
		0.06,
		28,
		PALETTE.CrystalCyan,
		0.15
	)
	ring:SetAttribute("Decor", true)
	-- Runes around the ring
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local p = center
			+ Vector3.new(math.cos(a) * (LANDING_R - 2.2), 0.45, math.sin(a) * (LANDING_R - 2.2))
		local rune = makeEllipsoid(
			folder,
			"Rune_" .. tostring(i),
			CFrame.new(p) * CFrame.Angles(0, -a, 0),
			Vector3.new(0.7, 0.12, 0.7),
			PALETTE.CrystalCore,
			Enum.Material.Neon,
			false,
			0.2
		)
		rune.CastShadow = false
	end
	for i = 1, 6 do
		local a = (i / 6) * math.pi * 2 + 0.3
		makeCylinderY(
			folder,
			"LandingPiling",
			CFrame.new(
				center.X + math.cos(a) * (LANDING_R - 0.6),
				7.4,
				center.Z + math.sin(a) * (LANDING_R - 0.6)
			),
			6.0,
			1.0,
			PALETTE.WoodDark,
			Enum.Material.Wood,
			false,
			0
		)
	end
	-- Mossy rocks and crystals on the lagoon side of the landing
	for i = 1, 5 do
		local rp = Vector3.new(
			LANDING_X - LANDING_R + rng:NextNumber(-0.5, 1.5),
			WATER_Y + 0.2,
			BRIDGE_Z + rng:NextNumber(-7, 7)
		)
		makeEllipsoid(
			folder,
			"LagoonRock",
			CFrame.new(rp) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), 0),
			Vector3.new(
				rng:NextNumber(2.2, 3.6),
				rng:NextNumber(1.6, 2.6),
				rng:NextNumber(2.2, 3.4)
			),
			if i % 2 == 0 then PALETTE.RockMid else PALETTE.RockDark,
			Enum.Material.Slate,
			false,
			0
		)
	end
end

local function buildWaterfallCurtain(gate: Model, rng: Random)
	local folder = makeFolder(gate, "WaterfallCurtain")
	local topY = 19.0
	local height = topY - WATER_Y
	local strips = 7
	for i = 1, strips do
		local z = BRIDGE_Z - 3.6 + (i - 0.5) * (7.2 / strips)
		local t = rng:NextNumber(0.28, 0.5)
		local w = 7.2 / strips + 0.25
		local strip = makePart(
			folder,
			"Strip_" .. tostring(i),
			CFrame.new(FALL_X + rng:NextNumber(-0.18, 0.18), topY - height * 0.5, z)
				* CFrame.Angles(math.rad(rng:NextNumber(-1.5, 1.5)), 0, math.rad(2.5)),
			Vector3.new(0.55 + rng:NextNumber(0, 0.3), height, w),
			if i % 2 == 0 then PALETTE.WaterfallBlue else PALETTE.WaterfallLight,
			Enum.Material.Glass,
			false,
			t
		)
		strip.CastShadow = false
		if i % 2 == 1 then
			local core = makePart(
				folder,
				"Core_" .. tostring(i),
				strip.CFrame * CFrame.new(0.2, 0, 0),
				Vector3.new(0.25, height - 0.6, w * 0.55),
				PALETTE.WaterfallFoam,
				Enum.Material.Neon,
				false,
				0.62
			)
			core.CastShadow = false
		end
	end
	-- Lip of the fall: rounded mossy rocks
	for i = 1, 7 do
		local z = BRIDGE_Z - 4.6 + (i - 1) * 1.55
		makeEllipsoid(
			folder,
			"LipRock_" .. tostring(i),
			CFrame.new(FALL_X - 0.6, topY + 0.3 + rng:NextNumber(-0.2, 0.7), z)
				* CFrame.Angles(
					rng:NextNumber(-0.3, 0.3),
					rng:NextNumber(0, 6),
					rng:NextNumber(-0.3, 0.3)
				),
			Vector3.new(
				rng:NextNumber(2.2, 3.4),
				rng:NextNumber(1.8, 2.8),
				rng:NextNumber(2.0, 3.0)
			),
			if i % 3 == 0 then PALETTE.MossGreen else PALETTE.RockMid,
			Enum.Material.Slate,
			false,
			0
		)
	end
	-- Foam and ripples where the water lands
	for i = 1, 11 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0.4, 3.6)
		local s = rng:NextNumber(0.9, 2.2)
		local foam = makeEllipsoid(
			folder,
			"Foam_" .. tostring(i),
			CFrame.new(
				FALL_X + 1.2 + math.cos(a) * r,
				WATER_Y + 0.15,
				BRIDGE_Z + math.sin(a) * r * 1.3
			),
			Vector3.new(s, s * 0.55, s),
			PALETTE.WaterfallFoam,
			Enum.Material.SmoothPlastic,
			false,
			rng:NextNumber(0.05, 0.3)
		)
		foam.CastShadow = false
	end
	for i, rad in { 2.6, 4.4, 6.4 } do
		local ripple = makeNeonRing(
			folder,
			"Ripple_" .. tostring(i),
			CFrame.new(FALL_X + 1.6, WATER_Y + 0.06, BRIDGE_Z),
			rad,
			0.16,
			0.04,
			26,
			PALETTE.WaterfallFoam,
			0.45 + i * 0.12
		)
		ripple:SetAttribute("Decor", true)
	end
	-- Mist + splash emitters
	local src = makePart(
		folder,
		"MistSource",
		CFrame.new(FALL_X + 1.4, WATER_Y + 1.0, BRIDGE_Z),
		Vector3.new(3, 0.4, 7),
		PALETTE.WaterfallFoam,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	src.CanQuery = false
	src.CastShadow = false
	local mist = Instance.new("ParticleEmitter")
	mist.Name = "Mist"
	mist.Color = ColorSequence.new(PALETTE.WaterfallFoam)
	mist.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9) })
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75),
		NumberSequenceKeypoint.new(0.5, 0.82),
		NumberSequenceKeypoint.new(1, 1),
	})
	mist.Lifetime = NumberRange.new(2.0, 3.2)
	mist.Speed = NumberRange.new(0.8, 2)
	mist.SpreadAngle = Vector2.new(40, 40)
	mist.Rate = 9
	mist.LightEmission = 0.3
	mist.Parent = src
	local splash = Instance.new("ParticleEmitter")
	splash.Name = "Splash"
	splash.Color = ColorSequence.new(PALETTE.WaterfallLight)
	splash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	splash.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	splash.Lifetime = NumberRange.new(0.5, 0.9)
	splash.Speed = NumberRange.new(5, 9)
	splash.SpreadAngle = Vector2.new(30, 30)
	splash.EmissionDirection = Enum.NormalId.Top
	splash.Acceleration = Vector3.new(0, -22, 0)
	splash.Rate = 18
	splash.LightEmission = 0.5
	splash.Parent = src
end

function Builder.buildLagoonGate(): Model
	local islandModel = Workspace:FindFirstChild("Island")
	assert(islandModel, "Workspace.Island not found (run in the hub place)")
	archiveLagoonParts()

	local old = islandModel:FindFirstChild(GATE_NAME)
	if old then
		old:Destroy()
	end
	local gate = makeModel(islandModel, GATE_NAME)
	local rng = Random.new(SEED + 7)

	buildBridge(gate, rng)
	buildLanding(gate, rng)
	buildWaterfallCurtain(gate, rng)

	-- Portal: front (-Z of base... LookVector side) faces east, toward the plaza.
	local base = CFrame.lookAt(
		Vector3.new(PORTAL_X, DECK_TOP_Y + 0.02, BRIDGE_Z),
		Vector3.new(PORTAL_X + 10, DECK_TOP_Y + 0.02, BRIDGE_Z)
	)
	local portal = Builder.buildHubPortal(gate, base, {
		name = "Portal_Training_Lagoon",
		scale = 1.25,
		portalId = "lagoon_to_training_1",
		extraTag = "TrainingPortalGuide",
		deckExtension = false,
		title = "PORTAL DO TREINO",
		subtitle = "Ilha do Aprendiz · Grátis",
	})
	portal:SetAttribute("GateRole", "TrainingPortal")
	return gate
end

-- ============================================================================
-- ENTRADA PRINCIPAL IDEMPOTENTE
-- ============================================================================

function Builder.build(origin: Vector3?): Model
	local targetOrigin = origin or DEFAULT_ORIGIN
	local rng = Random.new(SEED)

	local container = Workspace:FindFirstChild(CONTAINER_NAME)
	if not container then
		container = makeFolder(Workspace, CONTAINER_NAME)
	end

	local existing = container:FindFirstChild(ISLAND_NAME)
	if existing then
		existing:Destroy()
	end

	local root = makeModel(container, ISLAND_NAME)
	root:SetAttribute("IslandTier", 1)
	root:SetAttribute("IslandName", "Ilha do Aprendiz")

	local centerPart = makePart(
		root,
		"IslandCenter",
		CFrame.new(targetOrigin),
		Vector3.new(2, 2, 2),
		PALETTE.GrassMain,
		Enum.Material.SmoothPlastic,
		false,
		1
	)
	centerPart.CanQuery = false
	centerPart.CastShadow = false
	root.PrimaryPart = centerPart

	buildIslandTopTerrain(root, targetOrigin, rng)
	buildRockUnderside(root, targetOrigin, rng)
	buildFocusPond(root, targetOrigin, rng)
	buildInstinctPond(root, targetOrigin, rng)
	local portalCf = buildArrivalPortal(root, targetOrigin, rng)
	buildCentralBoardwalk(root, targetOrigin, rng)
	buildPropsAndFences(root, targetOrigin)
	buildStylizedClouds(root, targetOrigin, rng)
	buildGameplayZones(root, targetOrigin, portalCf)

	local partCount = 0
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("BasePart") then
			partCount += 1
		end
	end

	print(
		string.format(
			"[TrainingIsland1Builder] '%s' recriada em %s (%d BaseParts).",
			ISLAND_NAME,
			tostring(targetOrigin),
			partCount
		)
	)
	return root
end

return Builder
