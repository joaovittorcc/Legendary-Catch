--!strict
-- AquariumA1Builder.luau
-- Builds the four Aquarium level presets (ReplicatedStorage.AquariumLevels),
-- the 8 award & decor props (ReplicatedStorage.AquariumDecor),
-- and the Giant / Golden / Synergy visual references (ReplicatedStorage.AquariumVariantRefs).
-- Designed for Legendary Catch (A1). Follows fwjelaa vault mobile & stylized rules:
--   * SmoothPlastic glass panes (never Enum.Material.Glass, which hides particles/beams/translucents)
--   * Max 2 water layers (WaterTint + WaterSurface)
--   * Calm deep slate-teal backdrops so all 6 income label colors read cleanly on phones
--   * Shared AquariumOrigin front-threshold pivot across all 4 levels
--   * 5 discrete transition layers (Layer_01..Layer_05) for Codex upgrade animations
--   * Zero floating parts, <= 2 local lights per level, CastShadow=false on decor/glass/crystals

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PALETTE = {
	woodMain = Color3.fromRGB(122, 76, 46),
	woodDark = Color3.fromRGB(76, 46, 30),
	woodLight = Color3.fromRGB(164, 114, 72),
	woodPlank = Color3.fromRGB(142, 92, 56),
	stoneLight = Color3.fromRGB(184, 194, 204),
	stoneMid = Color3.fromRGB(132, 146, 160),
	stoneDark = Color3.fromRGB(84, 98, 114),
	gold = Color3.fromRGB(246, 196, 82),
	goldBright = Color3.fromRGB(255, 224, 118),
	brass = Color3.fromRGB(204, 152, 66),
	sand = Color3.fromRGB(238, 214, 158),
	sandWarm = Color3.fromRGB(224, 194, 134),
	backDeep = Color3.fromRGB(16, 48, 68),
	backMid = Color3.fromRGB(24, 72, 96),
	waterTint = Color3.fromRGB(44, 184, 200),
	waterSurface = Color3.fromRGB(102, 226, 234),
	foam = Color3.fromRGB(226, 250, 255),
	glass = Color3.fromRGB(174, 240, 250),
	crystalCyan = Color3.fromRGB(92, 230, 255),
	crystalDeep = Color3.fromRGB(46, 168, 224),
	crystalLilac = Color3.fromRGB(186, 134, 255),
	coralPink = Color3.fromRGB(255, 114, 154),
	coralOrange = Color3.fromRGB(255, 148, 92),
	coralMagenta = Color3.fromRGB(228, 98, 204),
	kelp = Color3.fromRGB(62, 188, 138),
	kelpDark = Color3.fromRGB(40, 144, 108),
	lanternAmber = Color3.fromRGB(255, 206, 114),
	pearl = Color3.fromRGB(246, 240, 255),
}

local INCOME_COLORS = {
	Common = Color3.fromRGB(255, 255, 255),
	Uncommon = Color3.fromRGB(92, 238, 126),
	Rare = Color3.fromRGB(92, 188, 255),
	Epic = Color3.fromRGB(196, 118, 255),
	Legendary = Color3.fromRGB(255, 210, 68),
	Mystic = Color3.fromRGB(255, 140, 225),
}

local SYNERGY_FAMILIES = {
	{
		id = "reef",
		namePT = "Recife",
		nameEN = "Reef",
		color = Color3.fromRGB(255, 128, 164),
		secondary = Color3.fromRGB(88, 234, 214),
	},
	{
		id = "storm",
		namePT = "Tempestade",
		nameEN = "Storm",
		color = Color3.fromRGB(96, 214, 255),
		secondary = Color3.fromRGB(255, 230, 110),
	},
	{
		id = "abyssal",
		namePT = "Abissal",
		nameEN = "Abyssal",
		color = Color3.fromRGB(168, 108, 255),
		secondary = Color3.fromRGB(78, 228, 255),
	},
	{
		id = "celestial",
		namePT = "Celestial",
		nameEN = "Celestial",
		color = Color3.fromRGB(255, 212, 86),
		secondary = Color3.fromRGB(210, 174, 255),
	},
	{
		id = "festival",
		namePT = "Festival",
		nameEN = "Festival",
		color = Color3.fromRGB(255, 104, 138),
		secondary = Color3.fromRGB(118, 244, 168),
	},
}

local function makePart(props: {
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	reflectance: number?,
	shape: Enum.PartType?,
	canCollide: boolean?,
	castShadow: boolean?,
	parent: Instance,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name
	p.Anchored = true
	p.Size = props.size
	p.CFrame = props.cf
	p.Color = props.color
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Transparency = props.transparency or 0
	p.Reflectance = props.reflectance or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.shape then
		p.Shape = props.shape
	end
	local collide = props.canCollide == true
	p.CanCollide = collide
	p.CanTouch = false
	p.CanQuery = collide
	p.CastShadow = props.castShadow == true
	p.Parent = props.parent
	return p
end

local function makeMarker(
	name: string,
	size: Vector3,
	cf: CFrame,
	parent: Instance,
	attrs: { [string]: any }?
): Part
	local p = makePart({
		name = name,
		size = size,
		cf = cf,
		color = Color3.fromRGB(120, 240, 255),
		transparency = 1,
		canCollide = false,
		castShadow = false,
		parent = parent,
	})
	if attrs then
		for k, v in pairs(attrs) do
			p:SetAttribute(k, v)
		end
	end
	return p
end

local function makeWedge(
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	castShadow: boolean,
	parent: Instance
): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.Size = size
	w.CFrame = cf
	w.Color = color
	w.Material = material
	w.CanCollide = false
	w.CanTouch = false
	w.CanQuery = false
	w.CastShadow = castShadow
	w.Parent = parent
	return w
end

local function addBubbleEmitter(
	parent: Instance,
	rate: number,
	speedMax: number,
	lifetimeMax: number
)
	local att = Instance.new("Attachment")
	att.Name = "BubbleSource"
	att.Parent = parent
	local em = Instance.new("ParticleEmitter")
	em.Name = "AquariumBubbles"
	em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	em.Color = ColorSequence.new(PALETTE.foam, PALETTE.crystalCyan)
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(0.6, 0.24),
		NumberSequenceKeypoint.new(1, 0.08),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.8, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(lifetimeMax * 0.65, lifetimeMax)
	em.Speed = NumberRange.new(speedMax * 0.65, speedMax)
	em.SpreadAngle = Vector2.new(12, 12)
	em.Rate = rate
	em.EmissionDirection = Enum.NormalId.Top
	em.LightEmission = 0.25
	em.Parent = att
end

local function buildCrystalCluster(
	parent: Instance,
	name: string,
	basePos: Vector3,
	scale: number,
	primaryColor: Color3,
	tipColor: Color3,
	spires: number
)
	local cluster = Instance.new("Model")
	cluster.Name = name
	for i = 1, spires do
		local ang = (i - 1) * (math.pi * 2 / spires) + 0.35
		local isCenter = i == 1
		local h = (if isCenter then 2.8 else 1.55 + (i % 3) * 0.42) * scale
		local w = (if isCenter then 0.72 else 0.46) * scale
		local tilt = if isCenter then 0.06 else 0.24 + (i % 2) * 0.12
		local offset = if isCenter
			then Vector3.zero
			else Vector3.new(math.cos(ang) * 0.45 * scale, 0, math.sin(ang) * 0.45 * scale)
		local cf = CFrame.new(basePos + offset)
			* CFrame.Angles(0, ang, 0)
			* CFrame.Angles(tilt, 0, 0)
			* CFrame.new(0, h * 0.46, 0)
		makePart({
			name = "Spire_" .. i,
			size = Vector3.new(w, h, w),
			cf = cf,
			color = if isCenter then primaryColor else primaryColor:Lerp(tipColor, 0.3),
			material = Enum.Material.SmoothPlastic,
			reflectance = 0.12,
			parent = cluster,
		})
		-- Small glowing crown cap (keeps Neon coverage < 10% of frame)
		makePart({
			name = "SpireTip_" .. i,
			size = Vector3.new(w * 0.62, h * 0.24, w * 0.62),
			cf = cf * CFrame.new(0, h * 0.45, 0),
			color = tipColor,
			material = Enum.Material.Neon,
			parent = cluster,
		})
	end
	cluster.Parent = parent
end

local function buildCoralCluster(
	parent: Instance,
	name: string,
	basePos: Vector3,
	scale: number,
	colorA: Color3,
	colorB: Color3
)
	local model = Instance.new("Model")
	model.Name = name
	-- Reef rock mound
	makePart({
		name = "ReefRock",
		size = Vector3.new(2.2, 0.9, 1.8) * scale,
		cf = CFrame.new(basePos + Vector3.new(0, 0.35 * scale, 0)) * CFrame.Angles(0, 0.3, 0),
		color = PALETTE.stoneMid,
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	-- Coral branches
	for i = 1, 4 do
		local ang = (i - 1) * 1.55 + 0.2
		local h = (1.1 + (i % 2) * 0.55) * scale
		local cf = CFrame.new(
			basePos
				+ Vector3.new(
					math.cos(ang) * 0.48 * scale,
					0.5 * scale,
					math.sin(ang) * 0.38 * scale
				)
		) * CFrame.Angles(0, ang, 0) * CFrame.Angles(0.28, 0, 0.12) * CFrame.new(0, h * 0.5, 0)
		makePart({
			name = "Branch_" .. i,
			size = Vector3.new(h, 0.32 * scale, 0.32 * scale),
			cf = cf * CFrame.Angles(0, 0, math.rad(90)),
			color = if i % 2 == 0 then colorA else colorB,
			material = Enum.Material.SmoothPlastic,
			shape = Enum.PartType.Cylinder,
			parent = model,
		})
		makePart({
			name = "Bulb_" .. i,
			size = Vector3.one * (0.48 * scale),
			cf = cf * CFrame.new(0, h * 0.5, 0),
			color = if i % 2 == 0 then colorA else colorB,
			material = Enum.Material.SmoothPlastic,
			shape = Enum.PartType.Ball,
			parent = model,
		})
	end
	model.Parent = parent
end

local function buildPlantTuft(
	parent: Instance,
	name: string,
	basePos: Vector3,
	scale: number,
	blades: number
)
	local m = Instance.new("Model")
	m.Name = name
	for i = 1, blades do
		local ang = (i - 1) * (math.pi * 2 / blades)
		local h = (1.1 + (i % 3) * 0.35) * scale
		local cf = CFrame.new(
			basePos + Vector3.new(math.cos(ang) * 0.22 * scale, 0, math.sin(ang) * 0.22 * scale)
		) * CFrame.Angles(0, ang, 0) * CFrame.Angles(0.18, 0, 0) * CFrame.new(0, h * 0.5, 0)
		makePart({
			name = "Leaf_" .. i,
			size = Vector3.new(0.26 * scale, h, 0.1 * scale),
			cf = cf,
			color = if i % 2 == 0 then PALETTE.kelp else PALETTE.kelpDark,
			parent = m,
		})
	end
	m.Parent = parent
end

local function buildHangingLamp(
	parent: Instance,
	name: string,
	topPos: Vector3,
	dropLen: number,
	color: Color3
)
	local m = Instance.new("Model")
	m.Name = name
	makePart({
		name = "Rod",
		size = Vector3.new(0.16, dropLen, 0.16),
		cf = CFrame.new(topPos - Vector3.new(0, dropLen * 0.5, 0)),
		color = PALETTE.woodDark,
		material = Enum.Material.Metal,
		parent = m,
	})
	makePart({
		name = "Hood",
		size = Vector3.new(1.5, 0.45, 1.1),
		cf = CFrame.new(topPos - Vector3.new(0, dropLen, 0)),
		color = PALETTE.brass,
		material = Enum.Material.Metal,
		parent = m,
	})
	makePart({
		name = "GlowLens",
		size = Vector3.new(1.15, 0.18, 0.78),
		cf = CFrame.new(topPos - Vector3.new(0, dropLen + 0.26, 0)),
		color = color,
		material = Enum.Material.Neon,
		parent = m,
	})
	m.Parent = parent
end

local function buildSignFrame(
	parent: Instance,
	pos: Vector3,
	width: number,
	height: number,
	ornate: boolean
)
	local m = Instance.new("Model")
	m.Name = "IncomeSignStructure"
	-- Left and right posts seated directly on deck Y=0
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			name = if side < 0 then "PostLeft" else "PostRight",
			size = Vector3.new(0.45, pos.Y + height * 0.5, 0.45),
			cf = CFrame.new(pos.X + side * (width * 0.46), (pos.Y + height * 0.5) * 0.5, pos.Z),
			color = PALETTE.woodDark,
			material = Enum.Material.WoodPlanks,
			parent = m,
		})
	end
	-- Backing board
	makePart({
		name = "BoardBack",
		size = Vector3.new(width, height, 0.34),
		cf = CFrame.new(pos),
		color = Color3.fromRGB(32, 26, 42),
		material = Enum.Material.SmoothPlastic,
		parent = m,
	})
	-- Outer trim
	local trimColor = if ornate then PALETTE.gold else PALETTE.woodLight
	local trimMat = if ornate then Enum.Material.Metal else Enum.Material.Wood
	makePart({
		name = "TrimTop",
		size = Vector3.new(width + 0.45, 0.32, 0.44),
		cf = CFrame.new(pos + Vector3.new(0, height * 0.5 + 0.12, 0)),
		color = trimColor,
		material = trimMat,
		parent = m,
	})
	makePart({
		name = "TrimBottom",
		size = Vector3.new(width + 0.45, 0.32, 0.44),
		cf = CFrame.new(pos - Vector3.new(0, height * 0.5 + 0.12, 0)),
		color = trimColor,
		material = trimMat,
		parent = m,
	})
	if ornate then
		makePart({
			name = "CrownGem",
			size = Vector3.new(0.65, 0.65, 0.5),
			cf = CFrame.new(pos + Vector3.new(0, height * 0.5 + 0.48, 0))
				* CFrame.Angles(0, 0, math.rad(45)),
			color = PALETTE.crystalCyan,
			material = Enum.Material.Neon,
			parent = m,
		})
	end
	m.Parent = parent
end

local function buildSegmentedArch(
	parent: Instance,
	name: string,
	center: Vector3,
	radiusX: number,
	radiusY: number,
	thickness: number,
	depth: number,
	color: Color3,
	goldTrim: boolean
)
	local m = Instance.new("Model")
	m.Name = name
	local segments = 9
	for i = 0, segments - 1 do
		local a0 = math.pi * (i / segments)
		local a1 = math.pi * ((i + 1) / segments)
		local p0 = Vector3.new(math.cos(a0) * radiusX, math.sin(a0) * radiusY, 0)
		local p1 = Vector3.new(math.cos(a1) * radiusX, math.sin(a1) * radiusY, 0)
		local segLen = (p1 - p0).Magnitude + 0.35
		local tangent = (p1 - p0).Unit
		local normal = Vector3.new(-tangent.Y, tangent.X, 0)
		local segCenter = center + (p0 + p1) * 0.5
		local cf = CFrame.fromMatrix(segCenter, tangent, normal)
		makePart({
			name = "ArchSeg_" .. (i + 1),
			size = Vector3.new(segLen, thickness, depth),
			cf = cf,
			color = color,
			material = Enum.Material.SmoothPlastic,
			castShadow = i == 4,
			parent = m,
		})
		if goldTrim then
			makePart({
				name = "ArchTrim_" .. (i + 1),
				size = Vector3.new(segLen * 0.96, 0.24, depth + 0.28),
				cf = cf * CFrame.new(0, -thickness * 0.52, 0),
				color = PALETTE.gold,
				material = Enum.Material.Metal,
				parent = m,
			})
		end
	end
	m.Parent = parent
end

-- Helper to create the standardized 5-layer + Anchors skeleton for every Aquarium level
local function createLevelSkeleton(cfg: {
	id: string,
	index: number,
	capacity: number,
	namePT: string,
	nameEN: string,
	tankW: number,
	tankH: number,
	tankD: number,
	giantMax: number,
})
	local model = Instance.new("Model")
	model.Name = cfg.id
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("LevelId", cfg.id)
	model:SetAttribute("LevelIndex", cfg.index)
	model:SetAttribute("Capacity", cfg.capacity)
	model:SetAttribute("DisplayNamePT", cfg.namePT)
	model:SetAttribute("DisplayNameEN", cfg.nameEN)
	model:SetAttribute("TankWidth", cfg.tankW)
	model:SetAttribute("TankHeight", cfg.tankH)
	model:SetAttribute("TankDepth", cfg.tankD)
	model:SetAttribute("GiantMaxExtent", cfg.giantMax)

	-- Shared front-threshold origin across all 4 levels (Y=0 deck top, Z=0 front threshold)
	local origin =
		makeMarker("AquariumOrigin", Vector3.new(1, 0.2, 1), CFrame.new(0, 0, 0), model, {
			Role = "SharedOrigin",
		})
	model.PrimaryPart = origin

	local anchors = Instance.new("Folder")
	anchors.Name = "Anchors"
	anchors.Parent = model

	local slotsFolder = Instance.new("Folder")
	slotsFolder.Name = "Slots"
	slotsFolder.Parent = anchors

	local lanesFolder = Instance.new("Folder")
	lanesFolder.Name = "SwimLanes"
	lanesFolder.Parent = anchors

	local decorFolder = Instance.new("Folder")
	decorFolder.Name = "DecorAnchors"
	decorFolder.Parent = anchors

	local layers = {}
	for _, layerName in ipairs({
		"Layer_01_Foundation",
		"Layer_02_Structure",
		"Layer_03_Habitat",
		"Layer_04_WaterAndGlass",
		"Layer_05_LightingAndSignage",
	}) do
		local lm = Instance.new("Model")
		lm.Name = layerName
		lm.Parent = model
		layers[layerName] = lm
	end

	return model, anchors, slotsFolder, lanesFolder, decorFolder, layers
end

local function addStandardDeck(
	layer1: Instance,
	deckW: number,
	deckD: number,
	frontZ: number,
	stoneTrim: boolean,
	pilings: boolean
)
	local centerZ = frontZ - deckD * 0.5
	-- Main walkable deck (top flush at Y = 0)
	makePart({
		name = "MainDeck",
		size = Vector3.new(deckW, 0.9, deckD),
		cf = CFrame.new(0, -0.45, centerZ),
		color = PALETTE.woodPlank,
		material = Enum.Material.WoodPlanks,
		canCollide = true,
		castShadow = true,
		parent = layer1,
	})
	-- Front step lip (walkable auto-step <= 0.5 stud)
	makePart({
		name = "FrontStep",
		size = Vector3.new(math.min(deckW - 2, 14), 0.45, 1.4),
		cf = CFrame.new(0, -0.225, frontZ + 0.7),
		color = PALETTE.woodLight,
		material = Enum.Material.Wood,
		canCollide = true,
		parent = layer1,
	})
	-- Decorative perimeter edge fascia
	local edgeColor = if stoneTrim then PALETTE.stoneLight else PALETTE.woodDark
	local edgeMat = if stoneTrim then Enum.Material.SmoothPlastic else Enum.Material.Wood
	makePart({
		name = "EdgeFront",
		size = Vector3.new(deckW + 0.5, 0.5, 0.45),
		cf = CFrame.new(0, -0.25, frontZ + 0.12),
		color = edgeColor,
		material = edgeMat,
		parent = layer1,
	})
	makePart({
		name = "EdgeBack",
		size = Vector3.new(deckW + 0.5, 0.5, 0.45),
		cf = CFrame.new(0, -0.25, frontZ - deckD - 0.12),
		color = edgeColor,
		material = edgeMat,
		parent = layer1,
	})
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			name = if side < 0 then "EdgeLeft" else "EdgeRight",
			size = Vector3.new(0.45, 0.5, deckD + 0.5),
			cf = CFrame.new(side * (deckW * 0.5 + 0.12), -0.25, centerZ),
			color = edgeColor,
			material = edgeMat,
			parent = layer1,
		})
	end
	-- Under-deck coastal pilings for expansion over SW cliff/ocean
	if pilings then
		local cols = math.max(3, math.floor(deckW / 10) + 1)
		for ix = 0, cols - 1 do
			local x = -deckW * 0.44 + (deckW * 0.88) * (ix / (cols - 1))
			for _, rz in ipairs({ frontZ - deckD * 0.35, frontZ - deckD * 0.85 }) do
				makePart({
					name = string.format("Piling_%d_%d", ix + 1, math.floor(math.abs(rz))),
					size = Vector3.new(1.15, 11.5, 1.15),
					cf = CFrame.new(x, -6.5, rz),
					color = PALETTE.woodDark,
					material = Enum.Material.Wood,
					shape = Enum.PartType.Cylinder,
					parent = layer1,
				})
				-- Cylinder in Roblox lies along X axis; rotate Z 90deg to stand vertical
				local last = layer1:GetChildren()[#layer1:GetChildren()] :: Part
				last.Size = Vector3.new(11.5, 1.15, 1.15)
				last.CFrame = CFrame.new(x, -6.5, rz) * CFrame.Angles(0, 0, math.rad(90))
			end
		end
	end
end

local function addTankWaterAndGlass(
	layer4: Instance,
	centerZ: number,
	baseY: number,
	tankW: number,
	tankH: number,
	tankD: number,
	bubbleCount: number
)
	local innerW = tankW - 0.6
	local innerH = tankH - 0.55
	local innerD = tankD - 0.55
	local waterY = baseY + innerH * 0.5 + 0.15

	-- Layer 1 of Water: single calm translucent turquoise interior tint
	makePart({
		name = "WaterTint",
		size = Vector3.new(innerW, innerH - 0.35, innerD),
		cf = CFrame.new(0, waterY - 0.15, centerZ),
		color = PALETTE.waterTint,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.87,
		parent = layer4,
	})
	-- Layer 2 of Water: crisp shimmering top surface sheet + thin edge foam
	makePart({
		name = "WaterSurface",
		size = Vector3.new(innerW, 0.16, innerD),
		cf = CFrame.new(0, baseY + innerH - 0.08, centerZ),
		color = PALETTE.waterSurface,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.56,
		reflectance = 0.14,
		parent = layer4,
	})
	makePart({
		name = "SurfaceFoamFront",
		size = Vector3.new(innerW - 0.2, 0.08, 0.28),
		cf = CFrame.new(0, baseY + innerH + 0.02, centerZ + innerD * 0.5 - 0.16),
		color = PALETTE.foam,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.42,
		parent = layer4,
	})

	-- Viewing panes: SmoothPlastic (NEVER Glass, so bubbles, beams & creatures always render cleanly!)
	makePart({
		name = "FrontPane",
		size = Vector3.new(tankW - 0.4, tankH - 0.3, 0.16),
		cf = CFrame.new(0, baseY + tankH * 0.5, centerZ + tankD * 0.5 - 0.08),
		color = PALETTE.glass,
		material = Enum.Material.SmoothPlastic,
		transparency = 0.81,
		reflectance = 0.08,
		canCollide = true,
		parent = layer4,
	})
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			name = if side < 0 then "LeftPane" else "RightPane",
			size = Vector3.new(0.16, tankH - 0.3, tankD - 0.4),
			cf = CFrame.new(side * (tankW * 0.5 - 0.08), baseY + tankH * 0.5, centerZ),
			color = PALETTE.glass,
			material = Enum.Material.SmoothPlastic,
			transparency = 0.79,
			reflectance = 0.08,
			canCollide = true,
			parent = layer4,
		})
	end

	-- Gentle bubble risers
	for i = 1, bubbleCount do
		local frac = if bubbleCount == 1 then 0 else ((i - 1) / (bubbleCount - 1)) * 2 - 1
		local bp = makePart({
			name = "BubbleVent_" .. i,
			size = Vector3.new(0.65, 0.22, 0.65),
			cf = CFrame.new(frac * (tankW * 0.34), baseY + 0.25, centerZ - tankD * 0.22),
			color = PALETTE.stoneDark,
			parent = layer4,
		})
		addBubbleEmitter(bp, 4, math.min(2.8, tankH * 0.32), math.max(1.8, tankH * 0.35))
	end
end

-- =========================================================================
-- LEVEL 1: BERÇÁRIO (3 SLOTS)
-- Compact glass tank on warm-wood craftsman bench, sand, plants, bubbles
-- =========================================================================
local function buildLevel1(): Model
	local tankW, tankH, tankD = 14, 6.5, 7
	local benchH = 2.0
	local frontZ = 3.2
	local tankFrontZ = -1.6
	local centerZ = tankFrontZ - tankD * 0.5

	local model, anchors, slots, lanes, decor, L = createLevelSkeleton({
		id = "aquarium_lv1_nursery",
		index = 1,
		capacity = 3,
		namePT = "Berçário",
		nameEN = "Nursery",
		tankW = tankW,
		tankH = tankH,
		tankD = tankD,
		giantMax = 4.6,
	})

	-- Layer 1: Foundation (compact deck + warm-wood bench)
	addStandardDeck(L.Layer_01_Foundation, 18, 12, frontZ, false, false)
	makePart({
		name = "TimberBench",
		size = Vector3.new(tankW + 1.0, benchH, tankD + 1.0),
		cf = CFrame.new(0, benchH * 0.5, centerZ),
		color = PALETTE.woodMain,
		material = Enum.Material.WoodPlanks,
		canCollide = true,
		castShadow = true,
		parent = L.Layer_01_Foundation,
	})
	makePart({
		name = "BenchCounterLip",
		size = Vector3.new(tankW + 1.5, 0.32, tankD + 1.5),
		cf = CFrame.new(0, benchH - 0.1, centerZ),
		color = PALETTE.woodLight,
		material = Enum.Material.Wood,
		parent = L.Layer_01_Foundation,
	})
	-- Carved bench cabinet panels on front
	for _, ox in ipairs({ -4.2, 0, 4.2 }) do
		makePart({
			name = "CabinetPanel_" .. math.floor(ox + 10),
			size = Vector3.new(3.4, 1.25, 0.18),
			cf = CFrame.new(ox, 0.95, tankFrontZ + 0.52),
			color = PALETTE.woodDark,
			material = Enum.Material.Wood,
			parent = L.Layer_01_Foundation,
		})
	end

	-- Layer 2: Structure (calm backwall, corner wood posts, brass corner brackets, top rim)
	makePart({
		name = "CalmBackdropWall",
		size = Vector3.new(tankW, tankH, 0.38),
		cf = CFrame.new(0, benchH + tankH * 0.5, centerZ - tankD * 0.5),
		color = PALETTE.backDeep,
		material = Enum.Material.SmoothPlastic,
		canCollide = true,
		castShadow = true,
		parent = L.Layer_02_Structure,
	})
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local px = sx * (tankW * 0.5)
			local pz = centerZ + sz * (tankD * 0.5)
			makePart({
				name = string.format("FramePost_%d_%d", sx + 2, sz + 2),
				size = Vector3.new(0.5, tankH + 0.35, 0.5),
				cf = CFrame.new(px, benchH + tankH * 0.5, pz),
				color = PALETTE.woodDark,
				material = Enum.Material.Wood,
				parent = L.Layer_02_Structure,
			})
			makePart({
				name = string.format("BrassBracket_%d_%d", sx + 2, sz + 2),
				size = Vector3.new(0.64, 0.42, 0.64),
				cf = CFrame.new(px, benchH + tankH + 0.05, pz),
				color = PALETTE.brass,
				material = Enum.Material.Metal,
				parent = L.Layer_02_Structure,
			})
		end
	end
	-- Top frame rails
	makePart({
		name = "TopFrontRail",
		size = Vector3.new(tankW + 0.6, 0.36, 0.48),
		cf = CFrame.new(0, benchH + tankH + 0.06, centerZ + tankD * 0.5),
		color = PALETTE.woodMain,
		material = Enum.Material.Wood,
		parent = L.Layer_02_Structure,
	})
	makePart({
		name = "TopBackRail",
		size = Vector3.new(tankW + 0.6, 0.42, 0.54),
		cf = CFrame.new(0, benchH + tankH + 0.08, centerZ - tankD * 0.5),
		color = PALETTE.woodMain,
		material = Enum.Material.Wood,
		parent = L.Layer_02_Structure,
	})

	-- Layer 3: Habitat (warm sand bed, smooth pebbles, seagrass tufts, 1 starter crystal)
	makePart({
		name = "SandBed",
		size = Vector3.new(tankW - 0.5, 0.48, tankD - 0.5),
		cf = CFrame.new(0, benchH + 0.24, centerZ),
		color = PALETTE.sand,
		material = Enum.Material.SmoothPlastic,
		parent = L.Layer_03_Habitat,
	})
	buildPlantTuft(
		L.Layer_03_Habitat,
		"PlantLeft",
		Vector3.new(-4.8, benchH + 0.45, centerZ - 1.6),
		0.95,
		5
	)
	buildPlantTuft(
		L.Layer_03_Habitat,
		"PlantCenter",
		Vector3.new(-0.8, benchH + 0.45, centerZ - 2.1),
		0.8,
		4
	)
	buildPlantTuft(
		L.Layer_03_Habitat,
		"PlantRight",
		Vector3.new(4.9, benchH + 0.45, centerZ - 1.5),
		1.0,
		5
	)
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"StarterCrystal",
		Vector3.new(-5.2, benchH + 0.42, centerZ - 1.9),
		0.52,
		PALETTE.crystalCyan,
		PALETTE.foam,
		3
	)

	-- Layer 4: Water & SmoothPlastic panes
	addTankWaterAndGlass(
		L.Layer_04_WaterAndGlass,
		centerZ,
		benchH + 0.35,
		tankW,
		tankH - 0.35,
		tankD,
		2
	)

	-- Layer 5: Signage & subtle lighting
	buildSignFrame(
		L.Layer_05_LightingAndSignage,
		Vector3.new(7.4, 3.6, tankFrontZ + 1.3),
		3.6,
		2.0,
		false
	)
	local lightHost = makePart({
		name = "SoftTankLight",
		size = Vector3.new(0.4, 0.4, 0.4),
		cf = CFrame.new(0, benchH + tankH - 0.4, centerZ + 0.6),
		color = PALETTE.crystalCyan,
		transparency = 1,
		parent = L.Layer_05_LightingAndSignage,
	})
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(168, 238, 250)
	pl.Brightness = 0.85
	pl.Range = 16
	pl.Shadows = false
	pl.Parent = lightHost

	-- Anchors (contract)
	makeMarker(
		"InteractPoint",
		Vector3.new(2, 2, 2),
		CFrame.new(0, 3.2, frontZ - 0.4),
		anchors,
		{ PromptAction = "OpenAquarium" }
	)
	makeMarker(
		"InspectCamera",
		Vector3.new(1, 1, 1),
		CFrame.lookAt(Vector3.new(0, 5.4, 11.5), Vector3.new(0, 5.2, centerZ)),
		anchors
	)
	makeMarker(
		"OverviewCamera",
		Vector3.new(1, 1, 1),
		CFrame.lookAt(Vector3.new(10, 9.5, 13.5), Vector3.new(0, 4.8, centerZ)),
		anchors
	)
	makeMarker(
		"BoardAnchor",
		Vector3.new(3.4, 1.8, 0.1),
		CFrame.new(7.4, 3.6, tankFrontZ + 1.52),
		anchors
	)
	makeMarker(
		"SwimVolume",
		Vector3.new(tankW - 2.0, tankH - 1.6, tankD - 1.8),
		CFrame.new(0, benchH + tankH * 0.5 + 0.1, centerZ),
		anchors
	)
	makeMarker(
		"SwimVolumeLarge",
		Vector3.new(tankW - 2.6, tankH - 1.5, tankD - 2.0),
		CFrame.new(0, benchH + tankH * 0.5 + 0.15, centerZ),
		anchors
	)

	-- 1 Swim Lane (Mid)
	makeMarker(
		"Lane_Mid",
		Vector3.new(tankW - 3.0, 2.6, tankD - 2.6),
		CFrame.new(0, benchH + 3.4, centerZ + 0.2),
		lanes,
		{
			LaneId = "Lane_Mid",
			Band = "Mid",
			SpeedScale = 0.9,
			RadiusX = 4.6,
			RadiusY = 0.7,
			RadiusZ = 1.6,
			AltitudeY = benchH + 3.4,
		}
	)

	-- 3 Slots (front-center core band)
	local slotCoords = {
		{ x = -3.8, y = benchH + 3.1, z = centerZ + 0.3, lane = "Lane_Mid" },
		{ x = 0.0, y = benchH + 3.6, z = centerZ - 0.2, lane = "Lane_Mid" },
		{ x = 3.8, y = benchH + 3.1, z = centerZ + 0.3, lane = "Lane_Mid" },
	}
	for i, s in ipairs(slotCoords) do
		makeMarker(
			string.format("Slot_%02d", i),
			Vector3.new(1.2, 1.2, 1.2),
			CFrame.new(s.x, s.y, s.z),
			slots,
			{
				SlotIndex = i,
				LaneId = s.lane,
				LabelOffsetY = 2.0,
				IsNewInLevel = true,
				PrevLevelSlot = i,
			}
		)
	end

	-- Persistent Decor Anchors (6 available at Lv1)
	makeMarker(
		"DecorAnchor_01_Plaque",
		Vector3.new(1, 1, 1),
		CFrame.new(7.4, 4.9, tankFrontZ + 1.3),
		decor,
		{ AttachType = "BoardFrame", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_02_Lamp",
		Vector3.new(1, 1, 1),
		CFrame.new(0, benchH + tankH + 0.25, centerZ),
		decor,
		{ AttachType = "Overhead", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_03_LeftBed",
		Vector3.new(1, 1, 1),
		CFrame.new(-4.5, benchH + 0.48, centerZ + 0.8),
		decor,
		{ AttachType = "FloorBed", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_04_RightBed",
		Vector3.new(1, 1, 1),
		CFrame.new(4.5, benchH + 0.48, centerZ + 0.8),
		decor,
		{ AttachType = "FloorBed", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_05_LeftPost",
		Vector3.new(1, 1, 1),
		CFrame.new(-7.6, 0, frontZ - 1.2),
		decor,
		{ AttachType = "DeckPost", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_06_RightPost",
		Vector3.new(1, 1, 1),
		CFrame.new(7.6, 0, frontZ - 1.2),
		decor,
		{ AttachType = "DeckPost", PersistsFromLevel = 1 }
	)

	return model
end

-- =========================================================================
-- LEVEL 2: TANQUE DE RECIFE (5 SLOTS)
-- Wider glass, overhead wooden light gantry, colorful coral reef terraces, 2 swim lanes
-- =========================================================================
local function buildLevel2(): Model
	local tankW, tankH, tankD = 22, 8.5, 9.5
	local benchH = 2.2
	local frontZ = 3.2
	local tankFrontZ = -2.0
	local centerZ = tankFrontZ - tankD * 0.5

	local model, anchors, slots, lanes, decor, L = createLevelSkeleton({
		id = "aquarium_lv2_reef",
		index = 2,
		capacity = 5,
		namePT = "Tanque de Recife",
		nameEN = "Reef Tank",
		tankW = tankW,
		tankH = tankH,
		tankD = tankD,
		giantMax = 5.0,
	})

	-- Layer 1: Foundation (wider deck on pilings + stone-trimmed cedar plinth)
	addStandardDeck(L.Layer_01_Foundation, 26, 15.5, frontZ, true, true)
	makePart({
		name = "ReefPlinth",
		size = Vector3.new(tankW + 1.4, benchH, tankD + 1.2),
		cf = CFrame.new(0, benchH * 0.5, centerZ),
		color = PALETTE.woodMain,
		material = Enum.Material.WoodPlanks,
		canCollide = true,
		castShadow = true,
		parent = L.Layer_01_Foundation,
	})
	makePart({
		name = "StoneBaseTrim",
		size = Vector3.new(tankW + 1.9, 0.55, tankD + 1.7),
		cf = CFrame.new(0, 0.275, centerZ),
		color = PALETTE.stoneLight,
		parent = L.Layer_01_Foundation,
	})
	makePart({
		name = "GoldCounterTrim",
		size = Vector3.new(tankW + 1.65, 0.22, tankD + 1.45),
		cf = CFrame.new(0, benchH - 0.08, centerZ),
		color = PALETTE.brass,
		material = Enum.Material.Metal,
		parent = L.Layer_01_Foundation,
	})

	-- Layer 2: Structure (calm backwall with subtle reef silhouette, heavier columns, overhead light gantry)
	makePart({
		name = "CalmBackdropWall",
		size = Vector3.new(tankW, tankH, 0.44),
		cf = CFrame.new(0, benchH + tankH * 0.5, centerZ - tankD * 0.5),
		color = PALETTE.backDeep,
		canCollide = true,
		castShadow = true,
		parent = L.Layer_02_Structure,
	})
	makePart({
		name = "UpperDepthBand",
		size = Vector3.new(tankW - 0.8, tankH * 0.42, 0.14),
		cf = CFrame.new(0, benchH + tankH * 0.76, centerZ - tankD * 0.5 + 0.25),
		color = PALETTE.backMid,
		parent = L.Layer_02_Structure,
	})
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local px = sx * (tankW * 0.5)
			local pz = centerZ + sz * (tankD * 0.5)
			makePart({
				name = string.format("Column_%d_%d", sx + 2, sz + 2),
				size = Vector3.new(0.76, tankH + 0.5, 0.76),
				cf = CFrame.new(px, benchH + tankH * 0.5, pz),
				color = PALETTE.woodDark,
				material = Enum.Material.Wood,
				parent = L.Layer_02_Structure,
			})
			makePart({
				name = string.format("CapGold_%d_%d", sx + 2, sz + 2),
				size = Vector3.new(0.95, 0.36, 0.95),
				cf = CFrame.new(px, benchH + tankH + 0.2, pz),
				color = PALETTE.gold,
				material = Enum.Material.Metal,
				parent = L.Layer_02_Structure,
			})
		end
	end
	-- Top frame + raised overhead light gantry (unmistakable Lv2 upgrade silhouette!)
	local gantryY = benchH + tankH + 2.4
	for _, sx in ipairs({ -1, 1 }) do
		makePart({
			name = if sx < 0 then "GantryPostLeft" else "GantryPostRight",
			size = Vector3.new(0.62, 2.5, 0.62),
			cf = CFrame.new(sx * (tankW * 0.5), benchH + tankH + 1.35, centerZ),
			color = PALETTE.woodMain,
			material = Enum.Material.Wood,
			parent = L.Layer_02_Structure,
		})
	end
	makePart({
		name = "OverheadGantryBeam",
		size = Vector3.new(tankW + 1.8, 0.68, 1.0),
		cf = CFrame.new(0, gantryY, centerZ),
		color = PALETTE.woodDark,
		material = Enum.Material.Wood,
		castShadow = true,
		parent = L.Layer_02_Structure,
	})
	makePart({
		name = "GantryGoldAccent",
		size = Vector3.new(tankW + 1.4, 0.16, 1.12),
		cf = CFrame.new(0, gantryY + 0.32, centerZ),
		color = PALETTE.gold,
		material = Enum.Material.Metal,
		parent = L.Layer_02_Structure,
	})

	-- Layer 3: Habitat (sand, stepped left/right coral reef terraces, bright corals, cyan crystals)
	makePart({
		name = "SandBed",
		size = Vector3.new(tankW - 0.6, 0.55, tankD - 0.6),
		cf = CFrame.new(0, benchH + 0.28, centerZ),
		color = PALETTE.sand,
		parent = L.Layer_03_Habitat,
	})
	-- Stepped reef rock shelves at flanks (leaving wide center channel open!)
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			name = if side < 0 then "ReefTerraceLeft" else "ReefTerraceRight",
			size = Vector3.new(5.2, 1.4, 4.4),
			cf = CFrame.new(side * (tankW * 0.34), benchH + 0.9, centerZ - 1.6)
				* CFrame.Angles(0, side * 0.18, 0),
			color = PALETTE.stoneMid,
			parent = L.Layer_03_Habitat,
		})
	end
	buildCoralCluster(
		L.Layer_03_Habitat,
		"CoralLeft",
		Vector3.new(-7.6, benchH + 1.5, centerZ - 1.8),
		1.15,
		PALETTE.coralPink,
		PALETTE.coralOrange
	)
	buildCoralCluster(
		L.Layer_03_Habitat,
		"CoralRight",
		Vector3.new(7.6, benchH + 1.5, centerZ - 1.8),
		1.15,
		PALETTE.coralMagenta,
		PALETTE.coralPink
	)
	buildCoralCluster(
		L.Layer_03_Habitat,
		"CoralBackCenter",
		Vector3.new(0, benchH + 0.52, centerZ - 3.0),
		0.95,
		PALETTE.coralOrange,
		PALETTE.coralPink
	)
	buildPlantTuft(
		L.Layer_03_Habitat,
		"KelpLeft",
		Vector3.new(-4.8, benchH + 0.52, centerZ - 2.6),
		1.3,
		6
	)
	buildPlantTuft(
		L.Layer_03_Habitat,
		"KelpRight",
		Vector3.new(4.8, benchH + 0.52, centerZ - 2.6),
		1.3,
		6
	)
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"ReefCrystalLeft",
		Vector3.new(-8.6, benchH + 1.5, centerZ - 2.8),
		0.85,
		PALETTE.crystalCyan,
		PALETTE.foam,
		4
	)
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"ReefCrystalRight",
		Vector3.new(8.6, benchH + 1.5, centerZ - 2.8),
		0.85,
		PALETTE.crystalLilac,
		PALETTE.crystalCyan,
		4
	)

	-- Layer 4: Water & SmoothPlastic panes
	addTankWaterAndGlass(
		L.Layer_04_WaterAndGlass,
		centerZ,
		benchH + 0.4,
		tankW,
		tankH - 0.4,
		tankD,
		3
	)

	-- Layer 5: Overhead hanging lamps + upgraded income board
	buildHangingLamp(
		L.Layer_05_LightingAndSignage,
		"ReefLampLeft",
		Vector3.new(-6.2, gantryY - 0.3, centerZ),
		1.4,
		PALETTE.lanternAmber
	)
	buildHangingLamp(
		L.Layer_05_LightingAndSignage,
		"ReefLampCenter",
		Vector3.new(0, gantryY - 0.3, centerZ),
		1.2,
		PALETTE.crystalCyan
	)
	buildHangingLamp(
		L.Layer_05_LightingAndSignage,
		"ReefLampRight",
		Vector3.new(6.2, gantryY - 0.3, centerZ),
		1.4,
		PALETTE.lanternAmber
	)
	buildSignFrame(
		L.Layer_05_LightingAndSignage,
		Vector3.new(10.8, 4.1, tankFrontZ + 1.6),
		4.2,
		2.3,
		true
	)
	for _, ox in ipairs({ -5.5, 5.5 }) do
		local lh = makePart({
			name = "OverheadLight_" .. math.floor(ox + 10),
			size = Vector3.new(0.4, 0.4, 0.4),
			cf = CFrame.new(ox, gantryY - 1.9, centerZ + 0.5),
			color = PALETTE.lanternAmber,
			transparency = 1,
			parent = L.Layer_05_LightingAndSignage,
		})
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(190, 240, 255)
		pl.Brightness = 0.9
		pl.Range = 20
		pl.Shadows = false
		pl.Parent = lh
	end

	-- Anchors
	makeMarker(
		"InteractPoint",
		Vector3.new(2, 2, 2),
		CFrame.new(0, 3.2, frontZ - 0.4),
		anchors,
		{ PromptAction = "OpenAquarium" }
	)
	makeMarker(
		"InspectCamera",
		Vector3.new(1, 1, 1),
		CFrame.lookAt(Vector3.new(0, 6.8, 16.5), Vector3.new(0, 6.4, centerZ)),
		anchors
	)
	makeMarker(
		"OverviewCamera",
		Vector3.new(1, 1, 1),
		CFrame.lookAt(Vector3.new(14, 12.0, 18.0), Vector3.new(0, 6.2, centerZ)),
		anchors
	)
	makeMarker(
		"BoardAnchor",
		Vector3.new(4.0, 2.1, 0.1),
		CFrame.new(10.8, 4.1, tankFrontZ + 1.82),
		anchors
	)
	makeMarker(
		"SwimVolume",
		Vector3.new(tankW - 2.4, tankH - 1.8, tankD - 2.0),
		CFrame.new(0, benchH + tankH * 0.5 + 0.15, centerZ),
		anchors
	)
	makeMarker(
		"SwimVolumeLarge",
		Vector3.new(tankW - 3.4, tankH - 1.8, tankD - 2.4),
		CFrame.new(0, benchH + tankH * 0.5 + 0.25, centerZ),
		anchors
	)

	-- 2 Swim Lanes (Low reef + High sunlit)
	makeMarker(
		"Lane_Low",
		Vector3.new(tankW - 4.0, 2.8, tankD - 3.0),
		CFrame.new(0, benchH + 3.0, centerZ + 0.7),
		lanes,
		{
			LaneId = "Lane_Low",
			Band = "Low",
			SpeedScale = 0.92,
			RadiusX = 7.4,
			RadiusY = 0.65,
			RadiusZ = 2.2,
			AltitudeY = benchH + 3.0,
		}
	)
	makeMarker(
		"Lane_High",
		Vector3.new(tankW - 4.8, 2.6, tankD - 3.4),
		CFrame.new(0, benchH + 5.8, centerZ - 0.7),
		lanes,
		{
			LaneId = "Lane_High",
			Band = "High",
			SpeedScale = 1.05,
			RadiusX = 6.8,
			RadiusY = 0.6,
			RadiusZ = 1.9,
			AltitudeY = benchH + 5.8,
		}
	)

	-- 5 Slots: 01..03 preserved in front-center core; 04..05 added in upper reef band!
	local slotCoords = {
		{ x = -5.4, y = benchH + 3.2, z = centerZ + 0.8, lane = "Lane_Low", isNew = false },
		{ x = 0.0, y = benchH + 3.8, z = centerZ + 0.2, lane = "Lane_Low", isNew = false },
		{ x = 5.4, y = benchH + 3.2, z = centerZ + 0.8, lane = "Lane_Low", isNew = false },
		{ x = -4.2, y = benchH + 6.0, z = centerZ - 1.2, lane = "Lane_High", isNew = true },
		{ x = 4.2, y = benchH + 6.0, z = centerZ - 1.2, lane = "Lane_High", isNew = true },
	}
	for i, s in ipairs(slotCoords) do
		makeMarker(
			string.format("Slot_%02d", i),
			Vector3.new(1.2, 1.2, 1.2),
			CFrame.new(s.x, s.y, s.z),
			slots,
			{
				SlotIndex = i,
				LaneId = s.lane,
				LabelOffsetY = 2.1,
				IsNewInLevel = s.isNew,
				PrevLevelSlot = if s.isNew then 0 else i,
			}
		)
	end

	-- Decor Anchors (6 carried over + Anchor 07 Crown unlocked!)
	makeMarker(
		"DecorAnchor_01_Plaque",
		Vector3.new(1, 1, 1),
		CFrame.new(10.8, 5.55, tankFrontZ + 1.6),
		decor,
		{ AttachType = "BoardFrame", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_02_Lamp",
		Vector3.new(1, 1, 1),
		CFrame.new(0, gantryY - 0.3, centerZ),
		decor,
		{ AttachType = "Overhead", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_03_LeftBed",
		Vector3.new(1, 1, 1),
		CFrame.new(-6.4, benchH + 0.55, centerZ + 1.4),
		decor,
		{ AttachType = "FloorBed", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_04_RightBed",
		Vector3.new(1, 1, 1),
		CFrame.new(6.4, benchH + 0.55, centerZ + 1.4),
		decor,
		{ AttachType = "FloorBed", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_05_LeftPost",
		Vector3.new(1, 1, 1),
		CFrame.new(-11.4, 0, frontZ - 1.2),
		decor,
		{ AttachType = "DeckPost", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_06_RightPost",
		Vector3.new(1, 1, 1),
		CFrame.new(11.4, 0, frontZ - 1.2),
		decor,
		{ AttachType = "DeckPost", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_07_Crown",
		Vector3.new(1, 1, 1),
		CFrame.new(0, gantryY + 0.45, centerZ),
		decor,
		{ AttachType = "CrownArch", PersistsFromLevel = 2 }
	)

	return model
end

-- =========================================================================
-- LEVEL 3: GALERIA (8 SLOTS)
-- Panoramic front bay + flanking viewing niches, front promenade walkway, deeper reef, 3 lanes
-- =========================================================================
local function buildLevel3(): Model
	local tankW, tankH, tankD = 32, 11.5, 13
	local benchH = 2.4
	local frontZ = 4.2
	local tankFrontZ = -2.4
	local centerZ = tankFrontZ - tankD * 0.5

	local model, anchors, slots, lanes, decor, L = createLevelSkeleton({
		id = "aquarium_lv3_gallery",
		index = 3,
		capacity = 8,
		namePT = "Galeria",
		nameEN = "Gallery",
		tankW = tankW,
		tankH = tankH,
		tankD = tankD,
		giantMax = 5.4,
	})

	-- Layer 1: Foundation (grand viewing promenade walkway + stone-faced plinth)
	addStandardDeck(L.Layer_01_Foundation, 38, 21, frontZ, true, true)
	-- Front viewing promenade carpet/runner strip leading visitors along the panoramic glass
	makePart({
		name = "PromenadeRunner",
		size = Vector3.new(33, 0.08, 3.2),
		cf = CFrame.new(0, 0.04, 0.8),
		color = PALETTE.woodLight,
		material = Enum.Material.Wood,
		parent = L.Layer_01_Foundation,
	})
	-- Decorative wooden-and-gold promenade railings on left/right front wings
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			name = if side < 0 then "PromenadeRailLeft" else "PromenadeRailRight",
			size = Vector3.new(10.5, 0.24, 0.24),
			cf = CFrame.new(side * 12.8, 2.3, frontZ - 0.35),
			color = PALETTE.woodLight,
			material = Enum.Material.Wood,
			parent = L.Layer_01_Foundation,
		})
		for i = 0, 2 do
			makePart({
				name = string.format("RailPost_%d_%d", side + 2, i),
				size = Vector3.new(0.32, 2.5, 0.32),
				cf = CFrame.new(side * (8.2 + i * 4.6), 1.25, frontZ - 0.35),
				color = PALETTE.woodDark,
				material = Enum.Material.Wood,
				parent = L.Layer_01_Foundation,
			})
		end
	end
	-- Stone gallery plinth
	makePart({
		name = "GalleryPlinth",
		size = Vector3.new(tankW + 1.8, benchH, tankD + 1.6),
		cf = CFrame.new(0, benchH * 0.5, centerZ),
		color = PALETTE.stoneLight,
		canCollide = true,
		castShadow = true,
		parent = L.Layer_01_Foundation,
	})
	makePart({
		name = "PlinthGoldBand",
		size = Vector3.new(tankW + 2.1, 0.26, tankD + 1.9),
		cf = CFrame.new(0, benchH - 0.14, centerZ),
		color = PALETTE.gold,
		material = Enum.Material.Metal,
		parent = L.Layer_01_Foundation,
	})

	-- Layer 2: Structure (panoramic 3-bay gallery: wide central window + 2 framed side viewing niches!)
	makePart({
		name = "CalmBackdropWall",
		size = Vector3.new(tankW, tankH, 0.5),
		cf = CFrame.new(0, benchH + tankH * 0.5, centerZ - tankD * 0.5),
		color = PALETTE.backDeep,
		canCollide = true,
		castShadow = true,
		parent = L.Layer_02_Structure,
	})
	makePart({
		name = "UpperDepthBand",
		size = Vector3.new(tankW - 1.0, tankH * 0.45, 0.16),
		cf = CFrame.new(0, benchH + tankH * 0.74, centerZ - tankD * 0.5 + 0.3),
		color = PALETTE.backMid,
		parent = L.Layer_02_Structure,
	})
	-- 4 front architectural gallery mullions defining Left Niche | Central Panoramic Bay | Right Niche
	for _, mx in ipairs({ -tankW * 0.5, -8.5, 8.5, tankW * 0.5 }) do
		makePart({
			name = "GalleryColumn_" .. math.floor(mx + 20),
			size = Vector3.new(0.95, tankH + 1.2, 1.05),
			cf = CFrame.new(mx, benchH + tankH * 0.5 + 0.4, tankFrontZ),
			color = PALETTE.woodDark,
			material = Enum.Material.Wood,
			castShadow = math.abs(mx) > 10,
			parent = L.Layer_02_Structure,
		})
		makePart({
			name = "ColumnGoldCap_" .. math.floor(mx + 20),
			size = Vector3.new(1.22, 0.42, 1.32),
			cf = CFrame.new(mx, benchH + tankH + 1.05, tankFrontZ),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = L.Layer_02_Structure,
		})
	end
	-- Rear corner piers
	for _, sx in ipairs({ -1, 1 }) do
		makePart({
			name = if sx < 0 then "RearPierLeft" else "RearPierRight",
			size = Vector3.new(1.1, tankH + 1.2, 1.1),
			cf = CFrame.new(sx * tankW * 0.5, benchH + tankH * 0.5 + 0.4, centerZ - tankD * 0.5),
			color = PALETTE.stoneDark,
			parent = L.Layer_02_Structure,
		})
	end
	-- Sculpted panoramic cornice roof beam & arched niche headers
	local corniceY = benchH + tankH + 1.5
	makePart({
		name = "GalleryCornice",
		size = Vector3.new(tankW + 2.6, 1.05, 2.2),
		cf = CFrame.new(0, corniceY, tankFrontZ - 0.2),
		color = PALETTE.woodMain,
		material = Enum.Material.Wood,
		castShadow = true,
		parent = L.Layer_02_Structure,
	})
	makePart({
		name = "CorniceGoldLine",
		size = Vector3.new(tankW + 2.8, 0.22, 2.38),
		cf = CFrame.new(0, corniceY + 0.55, tankFrontZ - 0.2),
		color = PALETTE.gold,
		material = Enum.Material.Metal,
		parent = L.Layer_02_Structure,
	})
	-- Subtle viewing niche alcove accents protruding slightly on left & right wings
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			name = if side < 0 then "NicheHeaderLeft" else "NicheHeaderRight",
			size = Vector3.new(7.4, 0.55, 1.2),
			cf = CFrame.new(side * 12.2, benchH + tankH - 0.15, tankFrontZ + 0.35),
			color = PALETTE.stoneLight,
			parent = L.Layer_02_Structure,
		})
		-- Back light-strip ridge framing each niche
		makePart({
			name = if side < 0 then "NicheCrystalStripLeft" else "NicheCrystalStripRight",
			size = Vector3.new(6.2, 0.14, 0.14),
			cf = CFrame.new(side * 12.2, benchH + tankH - 0.46, tankFrontZ + 0.2),
			color = PALETTE.crystalCyan,
			material = Enum.Material.Neon,
			parent = L.Layer_02_Structure,
		})
	end

	-- Layer 3: Habitat (deep multi-tier coral garden, niche alcoves, crystalline backdrop ridges)
	makePart({
		name = "SandBed",
		size = Vector3.new(tankW - 0.7, 0.65, tankD - 0.7),
		cf = CFrame.new(0, benchH + 0.325, centerZ),
		color = PALETTE.sand,
		parent = L.Layer_03_Habitat,
	})
	-- Stepped deep reef shelves along rear & flanks
	makePart({
		name = "RearReefRidge",
		size = Vector3.new(tankW - 4.0, 2.2, 3.6),
		cf = CFrame.new(0, benchH + 1.3, centerZ - tankD * 0.34),
		color = PALETTE.stoneMid,
		parent = L.Layer_03_Habitat,
	})
	buildCoralCluster(
		L.Layer_03_Habitat,
		"NicheCoralLeft",
		Vector3.new(-12.5, benchH + 0.6, centerZ - 1.4),
		1.45,
		PALETTE.coralPink,
		PALETTE.coralMagenta
	)
	buildCoralCluster(
		L.Layer_03_Habitat,
		"NicheCoralRight",
		Vector3.new(12.5, benchH + 0.6, centerZ - 1.4),
		1.45,
		PALETTE.coralOrange,
		PALETTE.coralPink
	)
	buildCoralCluster(
		L.Layer_03_Habitat,
		"CenterReefLeft",
		Vector3.new(-4.8, benchH + 2.35, centerZ - tankD * 0.34),
		1.25,
		PALETTE.coralMagenta,
		PALETTE.coralOrange
	)
	buildCoralCluster(
		L.Layer_03_Habitat,
		"CenterReefRight",
		Vector3.new(4.8, benchH + 2.35, centerZ - tankD * 0.34),
		1.25,
		PALETTE.coralPink,
		PALETTE.coralOrange
	)
	buildPlantTuft(
		L.Layer_03_Habitat,
		"TallKelp1",
		Vector3.new(-9.2, benchH + 0.6, centerZ - 3.6),
		1.8,
		6
	)
	buildPlantTuft(
		L.Layer_03_Habitat,
		"TallKelp2",
		Vector3.new(0, benchH + 2.35, centerZ - 4.4),
		1.6,
		6
	)
	buildPlantTuft(
		L.Layer_03_Habitat,
		"TallKelp3",
		Vector3.new(9.2, benchH + 0.6, centerZ - 3.6),
		1.8,
		6
	)
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"GalleryCrystalLeft",
		Vector3.new(-13.8, benchH + 0.6, centerZ - 4.0),
		1.25,
		PALETTE.crystalCyan,
		PALETTE.foam,
		5
	)
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"GalleryCrystalRight",
		Vector3.new(13.8, benchH + 0.6, centerZ - 4.0),
		1.25,
		PALETTE.crystalLilac,
		PALETTE.crystalCyan,
		5
	)

	-- Layer 4: Water & SmoothPlastic panes
	addTankWaterAndGlass(
		L.Layer_04_WaterAndGlass,
		centerZ,
		benchH + 0.45,
		tankW,
		tankH - 0.45,
		tankD,
		4
	)

	-- Layer 5: Gallery overhead lamps, promenade lanterns, grand sign
	for _, lx in ipairs({ -12.2, -4.2, 4.2, 12.2 }) do
		buildHangingLamp(
			L.Layer_05_LightingAndSignage,
			"GalleryLamp_" .. math.floor(lx + 20),
			Vector3.new(lx, corniceY - 0.4, centerZ + 1.2),
			1.1,
			if math.abs(lx) > 8 then PALETTE.crystalCyan else PALETTE.lanternAmber
		)
	end
	buildSignFrame(
		L.Layer_05_LightingAndSignage,
		Vector3.new(14.5, 4.6, frontZ - 2.2),
		4.6,
		2.5,
		true
	)
	for _, ox in ipairs({ -8.0, 8.0 }) do
		local lh = makePart({
			name = "GalleryLight_" .. math.floor(ox + 10),
			size = Vector3.new(0.4, 0.4, 0.4),
			cf = CFrame.new(ox, benchH + tankH - 0.6, centerZ + 1.5),
			color = PALETTE.crystalCyan,
			transparency = 1,
			parent = L.Layer_05_LightingAndSignage,
		})
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(186, 238, 255)
		pl.Brightness = 0.95
		pl.Range = 28
		pl.Shadows = false
		pl.Parent = lh
	end

	-- Anchors
	makeMarker(
		"InteractPoint",
		Vector3.new(2, 2, 2),
		CFrame.new(0, 3.2, frontZ - 0.6),
		anchors,
		{ PromptAction = "OpenAquarium" }
	)
	makeMarker(
		"InspectCamera",
		Vector3.new(1, 1, 1),
		CFrame.lookAt(Vector3.new(0, 8.4, 24.5), Vector3.new(0, 8.0, centerZ)),
		anchors
	)
	makeMarker(
		"OverviewCamera",
		Vector3.new(1, 1, 1),
		CFrame.lookAt(Vector3.new(18, 15.0, 26.0), Vector3.new(0, 7.6, centerZ)),
		anchors
	)
	makeMarker(
		"BoardAnchor",
		Vector3.new(4.4, 2.3, 0.1),
		CFrame.new(14.5, 4.6, frontZ - 1.98),
		anchors
	)
	makeMarker(
		"SwimVolume",
		Vector3.new(tankW - 2.8, tankH - 2.0, tankD - 2.4),
		CFrame.new(0, benchH + tankH * 0.5 + 0.2, centerZ),
		anchors
	)
	makeMarker(
		"SwimVolumeLarge",
		Vector3.new(tankW - 4.4, tankH - 2.2, tankD - 3.0),
		CFrame.new(0, benchH + tankH * 0.5 + 0.35, centerZ),
		anchors
	)

	-- 3 Swim Lanes (FrontLow, CenterMid, BackHigh)
	makeMarker(
		"Lane_FrontLow",
		Vector3.new(26, 3.2, 4.0),
		CFrame.new(0, benchH + 3.4, centerZ + 2.6),
		lanes,
		{
			LaneId = "Lane_FrontLow",
			Band = "Low",
			SpeedScale = 0.9,
			RadiusX = 10.5,
			RadiusY = 0.7,
			RadiusZ = 1.6,
			AltitudeY = benchH + 3.4,
		}
	)
	makeMarker(
		"Lane_CenterMid",
		Vector3.new(28, 3.6, 5.0),
		CFrame.new(0, benchH + 6.2, centerZ),
		lanes,
		{
			LaneId = "Lane_CenterMid",
			Band = "Mid",
			SpeedScale = 1.0,
			RadiusX = 11.8,
			RadiusY = 0.85,
			RadiusZ = 2.4,
			AltitudeY = benchH + 6.2,
		}
	)
	makeMarker(
		"Lane_BackHigh",
		Vector3.new(24, 3.2, 4.2),
		CFrame.new(0, benchH + 8.8, centerZ - 2.2),
		lanes,
		{
			LaneId = "Lane_BackHigh",
			Band = "High",
			SpeedScale = 1.1,
			RadiusX = 9.5,
			RadiusY = 0.7,
			RadiusZ = 1.8,
			AltitudeY = benchH + 8.8,
		}
	)

	-- 8 Slots: 01..05 preserved cleanly from Lv2; 06..08 added in panoramic wings & high gallery!
	local slotCoords = {
		{ x = -6.2, y = benchH + 3.4, z = centerZ + 2.5, lane = "Lane_FrontLow", isNew = false },
		{ x = 0.0, y = benchH + 4.0, z = centerZ + 1.8, lane = "Lane_FrontLow", isNew = false },
		{ x = 6.2, y = benchH + 3.4, z = centerZ + 2.5, lane = "Lane_FrontLow", isNew = false },
		{ x = -5.2, y = benchH + 6.8, z = centerZ - 0.6, lane = "Lane_CenterMid", isNew = false },
		{ x = 5.2, y = benchH + 6.8, z = centerZ - 0.6, lane = "Lane_CenterMid", isNew = false },
		{ x = -12.2, y = benchH + 5.8, z = centerZ + 0.8, lane = "Lane_CenterMid", isNew = true },
		{ x = 12.2, y = benchH + 5.8, z = centerZ + 0.8, lane = "Lane_CenterMid", isNew = true },
		{ x = 0.0, y = benchH + 8.8, z = centerZ - 2.2, lane = "Lane_BackHigh", isNew = true },
	}
	for i, s in ipairs(slotCoords) do
		makeMarker(
			string.format("Slot_%02d", i),
			Vector3.new(1.2, 1.2, 1.2),
			CFrame.new(s.x, s.y, s.z),
			slots,
			{
				SlotIndex = i,
				LaneId = s.lane,
				LabelOffsetY = 2.2,
				IsNewInLevel = s.isNew,
				PrevLevelSlot = if s.isNew then 0 else i,
			}
		)
	end

	-- Decor Anchors (all 7 carried over + Anchor 08 CenterBed unlocked!)
	makeMarker(
		"DecorAnchor_01_Plaque",
		Vector3.new(1, 1, 1),
		CFrame.new(14.5, 6.2, frontZ - 2.2),
		decor,
		{ AttachType = "BoardFrame", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_02_Lamp",
		Vector3.new(1, 1, 1),
		CFrame.new(0, corniceY - 0.5, centerZ + 1.2),
		decor,
		{ AttachType = "Overhead", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_03_LeftBed",
		Vector3.new(1, 1, 1),
		CFrame.new(-11.8, benchH + 0.65, centerZ + 2.2),
		decor,
		{ AttachType = "FloorBed", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_04_RightBed",
		Vector3.new(1, 1, 1),
		CFrame.new(11.8, benchH + 0.65, centerZ + 2.2),
		decor,
		{ AttachType = "FloorBed", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_05_LeftPost",
		Vector3.new(1, 1, 1),
		CFrame.new(-16.5, 0, frontZ - 1.0),
		decor,
		{ AttachType = "DeckPost", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_06_RightPost",
		Vector3.new(1, 1, 1),
		CFrame.new(16.5, 0, frontZ - 1.0),
		decor,
		{ AttachType = "DeckPost", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_07_Crown",
		Vector3.new(1, 1, 1),
		CFrame.new(0, corniceY + 0.7, tankFrontZ - 0.2),
		decor,
		{ AttachType = "CrownArch", PersistsFromLevel = 2 }
	)
	makeMarker(
		"DecorAnchor_08_CenterBed",
		Vector3.new(1, 1, 1),
		CFrame.new(0, benchH + 0.65, centerZ + 0.5),
		decor,
		{ AttachType = "CenterBed", PersistsFromLevel = 3 }
	)

	return model
end

-- =========================================================================
-- LEVEL 4: SANTUÁRIO (12 SLOTS)
-- Twin sweeping stone-and-gold arches, 3 distinct water sectors, giant hero crystals,
-- visible aqueduct water circulation streams, grand promenade, 4 swim lanes
-- =========================================================================
local function buildLevel4(): Model
	local tankW, tankH, tankD = 44, 16.0, 17.5
	local benchH = 2.8
	local frontZ = 5.2
	local tankFrontZ = -2.8
	local centerZ = tankFrontZ - tankD * 0.5

	local model, anchors, slots, lanes, decor, L = createLevelSkeleton({
		id = "aquarium_lv4_sanctuary",
		index = 4,
		capacity = 12,
		namePT = "Santuário",
		nameEN = "Sanctuary",
		tankW = tankW,
		tankH = tankH,
		tankD = tankD,
		giantMax = 6.0,
	})

	-- Layer 1: Foundation (monumental coastal terrace + grand steps + stone sanctuary plinth)
	addStandardDeck(L.Layer_01_Foundation, 52, 28, frontZ, true, true)
	makePart({
		name = "SanctuaryInlayPath",
		size = Vector3.new(44, 0.1, 4.4),
		cf = CFrame.new(0, 0.05, 1.0),
		color = PALETTE.stoneLight,
		parent = L.Layer_01_Foundation,
	})
	makePart({
		name = "SanctuaryGoldInlay",
		size = Vector3.new(42, 0.12, 0.35),
		cf = CFrame.new(0, 0.06, 3.0),
		color = PALETTE.gold,
		material = Enum.Material.Metal,
		parent = L.Layer_01_Foundation,
	})
	makePart({
		name = "SanctuaryPlinth",
		size = Vector3.new(tankW + 2.4, benchH, tankD + 2.0),
		cf = CFrame.new(0, benchH * 0.5, centerZ),
		color = PALETTE.stoneLight,
		canCollide = true,
		castShadow = true,
		parent = L.Layer_01_Foundation,
	})
	makePart({
		name = "SanctuaryBaseGold",
		size = Vector3.new(tankW + 2.8, 0.36, tankD + 2.4),
		cf = CFrame.new(0, benchH - 0.16, centerZ),
		color = PALETTE.gold,
		material = Enum.Material.Metal,
		parent = L.Layer_01_Foundation,
	})

	-- Layer 2: Structure (3 water sectors divided by slender crystal-stone colonnades + sweeping arches!)
	makePart({
		name = "CalmBackdropWall",
		size = Vector3.new(tankW, tankH, 0.6),
		cf = CFrame.new(0, benchH + tankH * 0.5, centerZ - tankD * 0.5),
		color = PALETTE.backDeep,
		canCollide = true,
		castShadow = true,
		parent = L.Layer_02_Structure,
	})
	makePart({
		name = "UpperDepthBand",
		size = Vector3.new(tankW - 1.2, tankH * 0.45, 0.18),
		cf = CFrame.new(0, benchH + tankH * 0.76, centerZ - tankD * 0.5 + 0.35),
		color = PALETTE.backMid,
		parent = L.Layer_02_Structure,
	})
	-- 4 monumental sanctuary columns framing Left Sector | Grand Central Abyssal Sector | Right Sector
	local colXs = { -tankW * 0.5, -10.5, 10.5, tankW * 0.5 }
	for idx, cx in ipairs(colXs) do
		local isInner = idx == 2 or idx == 3
		local h = if isInner then tankH + 2.4 else tankH + 1.2
		makePart({
			name = "SanctuaryPillar_" .. idx,
			size = Vector3.new(if isInner then 1.35 else 1.25, h, 1.45),
			cf = CFrame.new(cx, benchH + h * 0.5, tankFrontZ),
			color = PALETTE.stoneLight,
			castShadow = isInner,
			parent = L.Layer_02_Structure,
		})
		makePart({
			name = "PillarGoldRing_" .. idx,
			size = Vector3.new(1.55, 0.4, 1.65),
			cf = CFrame.new(cx, benchH + h - 0.3, tankFrontZ),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = L.Layer_02_Structure,
		})
		makePart({
			name = "PillarWoodTrim_" .. idx,
			size = Vector3.new(1.48, 0.65, 1.58),
			cf = CFrame.new(cx, benchH + 0.5, tankFrontZ),
			color = PALETTE.woodMain,
			material = Enum.Material.Wood,
			parent = L.Layer_02_Structure,
		})
	end
	-- Grand central sweeping stone-and-gold Sanctuary Arch!
	buildSegmentedArch(
		L.Layer_02_Structure,
		"SanctuaryGrandArch",
		Vector3.new(0, benchH + tankH + 1.2, tankFrontZ - 0.1),
		11.0,
		7.2,
		1.35,
		1.85,
		PALETTE.stoneLight,
		true
	)
	-- Flanking side arches framing Left & Right Sectors
	for _, side in ipairs({ -1, 1 }) do
		buildSegmentedArch(
			L.Layer_02_Structure,
			if side < 0 then "LeftSectorArch" else "RightSectorArch",
			Vector3.new(side * 16.25, benchH + tankH + 0.8, tankFrontZ - 0.1),
			5.9,
			4.0,
			1.0,
			1.45,
			PALETTE.woodMain,
			true
		)
	end
	-- Upper rear stone aqueduct channels for visible water circulation!
	for _, side in ipairs({ -1, 1 }) do
		makePart({
			name = if side < 0 then "AqueductChannelLeft" else "AqueductChannelRight",
			size = Vector3.new(2.4, 1.1, 4.4),
			cf = CFrame.new(side * 10.5, benchH + tankH + 0.8, centerZ - tankD * 0.32),
			color = PALETTE.stoneLight,
			parent = L.Layer_02_Structure,
		})
		makePart({
			name = if side < 0 then "AqueductLipLeft" else "AqueductLipRight",
			size = Vector3.new(1.8, 0.25, 1.2),
			cf = CFrame.new(side * 10.5, benchH + tankH + 0.4, centerZ - tankD * 0.16),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = L.Layer_02_Structure,
		})
	end

	-- Layer 3: Habitat (3 distinct underwater sectors: Left Coral Reef, Center Crystal Abyss, Right Luminous Crystal Spire!)
	makePart({
		name = "SandBed",
		size = Vector3.new(tankW - 0.8, 0.75, tankD - 0.8),
		cf = CFrame.new(0, benchH + 0.375, centerZ),
		color = PALETTE.sand,
		parent = L.Layer_03_Habitat,
	})
	-- Subtle underwater stone divider ledges marking the 3 water sectors (low enough so fish swim freely above!)
	for _, sx in ipairs({ -10.5, 10.5 }) do
		makePart({
			name = "SectorDividerLedge_" .. math.floor(sx + 20),
			size = Vector3.new(1.2, 2.2, tankD - 3.6),
			cf = CFrame.new(sx, benchH + 1.4, centerZ - 0.6),
			color = PALETTE.stoneDark,
			parent = L.Layer_03_Habitat,
		})
	end
	-- Left Sector: lush coral sanctuary
	buildCoralCluster(
		L.Layer_03_Habitat,
		"SectorLeftCoral1",
		Vector3.new(-16.5, benchH + 0.75, centerZ - 3.8),
		1.9,
		PALETTE.coralPink,
		PALETTE.coralOrange
	)
	buildCoralCluster(
		L.Layer_03_Habitat,
		"SectorLeftCoral2",
		Vector3.new(-13.2, benchH + 0.75, centerZ - 5.2),
		1.5,
		PALETTE.coralMagenta,
		PALETTE.coralPink
	)
	buildPlantTuft(
		L.Layer_03_Habitat,
		"SectorLeftKelp",
		Vector3.new(-19.0, benchH + 0.75, centerZ - 1.2),
		2.2,
		6
	)
	-- Right Sector: lilac & cyan crystal garden
	buildCoralCluster(
		L.Layer_03_Habitat,
		"SectorRightCoral",
		Vector3.new(16.2, benchH + 0.75, centerZ - 4.0),
		1.8,
		PALETTE.coralMagenta,
		PALETTE.coralPink
	)
	buildPlantTuft(
		L.Layer_03_Habitat,
		"SectorRightKelp",
		Vector3.new(19.0, benchH + 0.75, centerZ - 1.2),
		2.2,
		6
	)
	-- Hero towering crystals flanking outside & inside the Sanctuary!
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"SanctuaryHeroCrystalLeft",
		Vector3.new(-23.2, 0.0, tankFrontZ - 1.2),
		2.3,
		PALETTE.crystalCyan,
		PALETTE.foam,
		5
	)
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"SanctuaryHeroCrystalRight",
		Vector3.new(23.2, 0.0, tankFrontZ - 1.2),
		2.3,
		PALETTE.crystalLilac,
		PALETTE.crystalCyan,
		5
	)
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"InnerCrystalLeft",
		Vector3.new(-17.8, benchH + 0.72, centerZ - 5.8),
		1.55,
		PALETTE.crystalCyan,
		PALETTE.foam,
		4
	)
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"InnerCrystalRight",
		Vector3.new(17.8, benchH + 0.72, centerZ - 5.8),
		1.55,
		PALETTE.crystalLilac,
		PALETTE.crystalCyan,
		4
	)
	buildCrystalCluster(
		L.Layer_03_Habitat,
		"CenterAbyssCrystal",
		Vector3.new(0, benchH + 0.72, centerZ - 6.6),
		1.65,
		PALETTE.crystalCyan,
		PALETTE.crystalLilac,
		5
	)

	-- Layer 4: Water, SmoothPlastic panes, AND visible water circulation streams (aqueduct falls + aeration rings)!
	addTankWaterAndGlass(
		L.Layer_04_WaterAndGlass,
		centerZ,
		benchH + 0.5,
		tankW,
		tankH - 0.5,
		tankD,
		5
	)
	for _, side in ipairs({ -1, 1 }) do
		local streamTop = Vector3.new(side * 10.5, benchH + tankH + 0.35, centerZ - tankD * 0.14)
		local streamBot = Vector3.new(side * 10.5, benchH + tankH - 3.6, centerZ - tankD * 0.08)
		local pTop = makePart({
			name = if side < 0 then "CirculationTopLeft" else "CirculationTopRight",
			size = Vector3.new(1.1, 0.2, 0.4),
			cf = CFrame.new(streamTop),
			color = PALETTE.foam,
			transparency = 0.35,
			parent = L.Layer_04_WaterAndGlass,
		})
		local pBot = makePart({
			name = if side < 0 then "CirculationSplashLeft" else "CirculationSplashRight",
			size = Vector3.new(2.2, 0.16, 2.2),
			cf = CFrame.new(streamBot.X, benchH + tankH - 0.06, streamBot.Z),
			color = PALETTE.foam,
			transparency = 0.45,
			shape = Enum.PartType.Cylinder,
			parent = L.Layer_04_WaterAndGlass,
		})
		pBot.Size = Vector3.new(0.16, 2.2, 2.2)
		pBot.CFrame = CFrame.new(streamBot.X, benchH + tankH - 0.06, streamBot.Z)
			* CFrame.Angles(0, 0, math.rad(90))
		local a0 = Instance.new("Attachment")
		a0.Parent = pTop
		local a1 = Instance.new("Attachment")
		a1.Parent = pBot
		local beam = Instance.new("Beam")
		beam.Name = "WaterCirculationStream"
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = 1.25
		beam.Width1 = 1.75
		beam.Color = ColorSequence.new(PALETTE.foam, PALETTE.crystalCyan)
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(0.7, 0.35),
			NumberSequenceKeypoint.new(1, 0.75),
		})
		beam.LightEmission = 0.35
		beam.FaceCamera = true
		beam.Parent = pTop
	end

	-- Layer 5: Royal crown medallion, grand signage, 2 crisp Sanctuary lights
	local archApexY = benchH + tankH + 1.2 + 7.2
	makePart({
		name = "SanctuaryCrownCrystal",
		size = Vector3.new(1.8, 2.6, 1.2),
		cf = CFrame.new(0, archApexY + 1.6, tankFrontZ - 0.1) * CFrame.Angles(0, 0, math.rad(45)),
		color = PALETTE.crystalCyan,
		material = Enum.Material.Neon,
		parent = L.Layer_05_LightingAndSignage,
	})
	buildSignFrame(
		L.Layer_05_LightingAndSignage,
		Vector3.new(19.5, 5.0, frontZ - 2.4),
		5.2,
		2.8,
		true
	)
	for _, ox in ipairs({ -11.0, 11.0 }) do
		local lh = makePart({
			name = "SanctuaryLight_" .. math.floor(ox + 20),
			size = Vector3.new(0.4, 0.4, 0.4),
			cf = CFrame.new(ox, benchH + tankH - 1.0, centerZ + 2.0),
			color = PALETTE.crystalCyan,
			transparency = 1,
			parent = L.Layer_05_LightingAndSignage,
		})
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(190, 240, 255)
		pl.Brightness = 1.0
		pl.Range = 36
		pl.Shadows = false
		pl.Parent = lh
	end

	-- Anchors
	makeMarker(
		"InteractPoint",
		Vector3.new(2, 2, 2),
		CFrame.new(0, 3.2, frontZ - 0.8),
		anchors,
		{ PromptAction = "OpenAquarium" }
	)
	makeMarker(
		"InspectCamera",
		Vector3.new(1, 1, 1),
		CFrame.lookAt(Vector3.new(0, 11.2, 34.0), Vector3.new(0, 10.6, centerZ)),
		anchors
	)
	makeMarker(
		"OverviewCamera",
		Vector3.new(1, 1, 1),
		CFrame.lookAt(Vector3.new(24, 20.0, 36.0), Vector3.new(0, 10.0, centerZ)),
		anchors
	)
	makeMarker(
		"BoardAnchor",
		Vector3.new(5.0, 2.6, 0.1),
		CFrame.new(19.5, 5.0, frontZ - 2.18),
		anchors
	)
	makeMarker(
		"SwimVolume",
		Vector3.new(tankW - 3.6, tankH - 2.4, tankD - 2.8),
		CFrame.new(0, benchH + tankH * 0.5 + 0.25, centerZ),
		anchors
	)
	makeMarker(
		"SwimVolumeLarge",
		Vector3.new(tankW - 5.2, tankH - 2.6, tankD - 3.6),
		CFrame.new(0, benchH + tankH * 0.5 + 0.4, centerZ),
		anchors
	)

	-- 4 Swim Lanes across 3 Water Sectors!
	makeMarker(
		"Lane_CenterLow",
		Vector3.new(20, 4.2, 7.0),
		CFrame.new(0, benchH + 4.0, centerZ + 2.6),
		lanes,
		{
			LaneId = "Lane_CenterLow",
			Band = "SectorCenter",
			SpeedScale = 0.88,
			RadiusX = 8.4,
			RadiusY = 0.85,
			RadiusZ = 2.6,
			AltitudeY = benchH + 4.0,
		}
	)
	makeMarker(
		"Lane_CenterHigh",
		Vector3.new(20, 5.2, 7.2),
		CFrame.new(0, benchH + 10.4, centerZ - 1.2),
		lanes,
		{
			LaneId = "Lane_CenterHigh",
			Band = "SectorCenter",
			SpeedScale = 1.0,
			RadiusX = 8.8,
			RadiusY = 1.1,
			RadiusZ = 2.8,
			AltitudeY = benchH + 10.4,
		}
	)
	makeMarker(
		"Lane_LeftSector",
		Vector3.new(10.5, 9.5, 9.5),
		CFrame.new(-16.2, benchH + 7.6, centerZ + 0.4),
		lanes,
		{
			LaneId = "Lane_LeftSector",
			Band = "SectorLeft",
			SpeedScale = 0.96,
			RadiusX = 4.2,
			RadiusY = 1.6,
			RadiusZ = 3.2,
			AltitudeY = benchH + 7.6,
		}
	)
	makeMarker(
		"Lane_RightSector",
		Vector3.new(10.5, 9.5, 9.5),
		CFrame.new(16.2, benchH + 7.6, centerZ + 0.4),
		lanes,
		{
			LaneId = "Lane_RightSector",
			Band = "SectorRight",
			SpeedScale = 0.96,
			RadiusX = 4.2,
			RadiusY = 1.6,
			RadiusZ = 3.2,
			AltitudeY = benchH + 7.6,
		}
	)

	-- 12 Slots: 01..08 preserved seamlessly from Lv3; 09..12 added in upper Sanctuary crown & outer sectors!
	local slotCoords = {
		{ x = -6.5, y = benchH + 3.8, z = centerZ + 3.4, lane = "Lane_CenterLow", isNew = false },
		{ x = 0.0, y = benchH + 4.5, z = centerZ + 2.6, lane = "Lane_CenterLow", isNew = false },
		{ x = 6.5, y = benchH + 3.8, z = centerZ + 3.4, lane = "Lane_CenterLow", isNew = false },
		{ x = -5.5, y = benchH + 8.4, z = centerZ - 0.6, lane = "Lane_CenterHigh", isNew = false },
		{ x = 5.5, y = benchH + 8.4, z = centerZ - 0.6, lane = "Lane_CenterHigh", isNew = false },
		{ x = -16.2, y = benchH + 5.2, z = centerZ + 1.8, lane = "Lane_LeftSector", isNew = false },
		{ x = 16.2, y = benchH + 5.2, z = centerZ + 1.8, lane = "Lane_RightSector", isNew = false },
		{ x = 0.0, y = benchH + 11.6, z = centerZ - 2.4, lane = "Lane_CenterHigh", isNew = false },
		-- New in Lv4 (09..12): spacious vertical separation so all 12 income labels remain 100% legible!
		{ x = -16.4, y = benchH + 10.6, z = centerZ - 1.2, lane = "Lane_LeftSector", isNew = true },
		{ x = 16.4, y = benchH + 10.6, z = centerZ - 1.2, lane = "Lane_RightSector", isNew = true },
		{ x = -6.6, y = benchH + 12.8, z = centerZ - 3.0, lane = "Lane_CenterHigh", isNew = true },
		{ x = 6.6, y = benchH + 12.8, z = centerZ - 3.0, lane = "Lane_CenterHigh", isNew = true },
	}
	for i, s in ipairs(slotCoords) do
		makeMarker(
			string.format("Slot_%02d", i),
			Vector3.new(1.2, 1.2, 1.2),
			CFrame.new(s.x, s.y, s.z),
			slots,
			{
				SlotIndex = i,
				LaneId = s.lane,
				LabelOffsetY = 2.35,
				IsNewInLevel = s.isNew,
				PrevLevelSlot = if s.isNew then 0 else i,
			}
		)
	end

	-- All 8 Decor Anchors carried forward seamlessly!
	makeMarker(
		"DecorAnchor_01_Plaque",
		Vector3.new(1, 1, 1),
		CFrame.new(19.5, 6.75, frontZ - 2.4),
		decor,
		{ AttachType = "BoardFrame", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_02_Lamp",
		Vector3.new(1, 1, 1),
		CFrame.new(0, benchH + tankH + 5.2, tankFrontZ - 0.1),
		decor,
		{ AttachType = "Overhead", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_03_LeftBed",
		Vector3.new(1, 1, 1),
		CFrame.new(-15.5, benchH + 0.75, centerZ + 3.2),
		decor,
		{ AttachType = "FloorBed", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_04_RightBed",
		Vector3.new(1, 1, 1),
		CFrame.new(15.5, benchH + 0.75, centerZ + 3.2),
		decor,
		{ AttachType = "FloorBed", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_05_LeftPost",
		Vector3.new(1, 1, 1),
		CFrame.new(-21.0, 0, frontZ - 1.2),
		decor,
		{ AttachType = "DeckPost", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_06_RightPost",
		Vector3.new(1, 1, 1),
		CFrame.new(21.0, 0, frontZ - 1.2),
		decor,
		{ AttachType = "DeckPost", PersistsFromLevel = 1 }
	)
	makeMarker(
		"DecorAnchor_07_Crown",
		Vector3.new(1, 1, 1),
		CFrame.new(0, archApexY + 0.2, tankFrontZ - 0.1),
		decor,
		{ AttachType = "CrownArch", PersistsFromLevel = 2 }
	)
	makeMarker(
		"DecorAnchor_08_CenterBed",
		Vector3.new(1, 1, 1),
		CFrame.new(0, benchH + 0.75, centerZ + 0.4),
		decor,
		{ AttachType = "CenterBed", PersistsFromLevel = 3 }
	)

	return model
end

-- =========================================================================
-- AWARD & DECORATION PROPS (8 RECOGNIZABLE PIECES)
-- Every prop has: DecorPivot (PrimaryPart), Bounds, PreviewCamera, metadata attributes
-- =========================================================================
local function createDecorSkeleton(cfg: {
	id: string,
	namePT: string,
	nameEN: string,
	attachType: string,
	milestoneRate: number,
	persist: boolean,
	boundsSize: Vector3,
	boundsOffsetY: number,
	camPos: Vector3,
	camTarget: Vector3,
}): Model
	local m = Instance.new("Model")
	m.Name = cfg.id
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	m:SetAttribute("DecorId", cfg.id)
	m:SetAttribute("DisplayNamePT", cfg.namePT)
	m:SetAttribute("DisplayNameEN", cfg.nameEN)
	m:SetAttribute("AttachType", cfg.attachType)
	m:SetAttribute("MilestoneRate", cfg.milestoneRate)
	m:SetAttribute("PersistAcrossLevels", cfg.persist)

	local pivot = makeMarker("DecorPivot", Vector3.new(0.4, 0.2, 0.4), CFrame.new(0, 0, 0), m)
	m.PrimaryPart = pivot
	makeMarker("Bounds", cfg.boundsSize, CFrame.new(0, cfg.boundsOffsetY, 0), m)
	makeMarker(
		"PreviewCamera",
		Vector3.new(0.4, 0.4, 0.4),
		CFrame.lookAt(cfg.camPos, cfg.camTarget),
		m
	)
	return m
end

local function buildDecorCatalog(folder: Folder)
	-- 1. Placa Real do Aquário (0.50/s)
	do
		local m = createDecorSkeleton({
			id = "decor_income_plaque",
			namePT = "Placa Real do Aquário",
			nameEN = "Royal Aquarium Crest",
			attachType = "BoardFrame",
			milestoneRate = 0.50,
			persist = true,
			boundsSize = Vector3.new(3.8, 1.5, 0.8),
			boundsOffsetY = 0.6,
			camPos = Vector3.new(0, 0.8, 4.4),
			camTarget = Vector3.new(0, 0.6, 0),
		})
		makePart({
			name = "CrestWing",
			size = Vector3.new(3.4, 0.55, 0.36),
			cf = CFrame.new(0, 0.35, 0),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "CrestShield",
			size = Vector3.new(1.3, 1.15, 0.48),
			cf = CFrame.new(0, 0.62, 0.04),
			color = PALETTE.woodDark,
			material = Enum.Material.Wood,
			parent = m,
		})
		makePart({
			name = "CrestGem",
			size = Vector3.new(0.62, 0.62, 0.58),
			cf = CFrame.new(0, 0.65, 0.1) * CFrame.Angles(0, 0, math.rad(45)),
			color = PALETTE.crystalCyan,
			material = Enum.Material.Neon,
			parent = m,
		})
		for _, s in ipairs({ -1, 1 }) do
			makePart({
				name = "Star_" .. (s + 2),
				size = Vector3.new(0.42, 0.42, 0.44),
				cf = CFrame.new(s * 1.25, 0.38, 0.06) * CFrame.Angles(0, 0, math.rad(45)),
				color = PALETTE.goldBright,
				material = Enum.Material.Neon,
				parent = m,
			})
		end
		m.Parent = folder
	end

	-- 2. Luminária de Recife (1.00/s)
	do
		local m = createDecorSkeleton({
			id = "decor_reef_lamp",
			namePT = "Luminária de Recife",
			nameEN = "Reef Pendant Lamp",
			attachType = "Overhead",
			milestoneRate = 1.00,
			persist = true,
			boundsSize = Vector3.new(2.4, 2.4, 2.4),
			boundsOffsetY = -1.1,
			camPos = Vector3.new(2.2, -0.8, 3.6),
			camTarget = Vector3.new(0, -1.1, 0),
		})
		makePart({
			name = "Chain",
			size = Vector3.new(0.18, 1.1, 0.18),
			cf = CFrame.new(0, -0.55, 0),
			color = PALETTE.brass,
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "CrownRing",
			size = Vector3.new(1.9, 0.32, 1.9),
			cf = CFrame.new(0, -1.15, 0),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "CrystalCore",
			size = Vector3.new(1.1, 1.1, 1.1),
			cf = CFrame.new(0, -1.65, 0) * CFrame.Angles(0, math.rad(45), 0),
			color = PALETTE.lanternAmber,
			material = Enum.Material.Neon,
			parent = m,
		})
		for i = 1, 4 do
			local a = i * math.pi * 0.5
			makePart({
				name = "Fin_" .. i,
				size = Vector3.new(0.24, 0.85, 0.45),
				cf = CFrame.new(math.cos(a) * 0.85, -1.45, math.sin(a) * 0.85)
					* CFrame.Angles(0, -a, 0),
				color = PALETTE.coralPink,
				parent = m,
			})
		end
		m.Parent = folder
	end

	-- 3. Coral de Cristal Vivo (2.00/s)
	do
		local m = createDecorSkeleton({
			id = "decor_crystal_coral",
			namePT = "Coral de Cristal Vivo",
			nameEN = "Living Crystal Coral",
			attachType = "FloorBed",
			milestoneRate = 2.00,
			persist = true,
			boundsSize = Vector3.new(3.0, 2.8, 2.6),
			boundsOffsetY = 1.35,
			camPos = Vector3.new(2.6, 2.2, 4.2),
			camTarget = Vector3.new(0, 1.2, 0),
		})
		buildCoralCluster(
			m,
			"CoralBase",
			Vector3.new(0, 0, 0),
			1.25,
			PALETTE.coralPink,
			PALETTE.coralMagenta
		)
		buildCrystalCluster(
			m,
			"CoralCrystalCrown",
			Vector3.new(0, 0.55, -0.2),
			0.72,
			PALETTE.crystalCyan,
			PALETTE.foam,
			3
		)
		m.Parent = folder
	end

	-- 4. Fonte de Bolhas Ancestral (4.00/s)
	do
		local m = createDecorSkeleton({
			id = "decor_bubble_fountain",
			namePT = "Fonte de Bolhas Ancestral",
			nameEN = "Ancient Bubble Fountain",
			attachType = "FloorBed",
			milestoneRate = 4.00,
			persist = true,
			boundsSize = Vector3.new(3.2, 2.6, 3.0),
			boundsOffsetY = 1.3,
			camPos = Vector3.new(2.8, 2.2, 4.4),
			camTarget = Vector3.new(0, 1.1, 0),
		})
		makePart({
			name = "StoneBase",
			size = Vector3.new(2.6, 0.7, 2.6),
			cf = CFrame.new(0, 0.35, 0),
			color = PALETTE.stoneLight,
			parent = m,
		})
		makePart({
			name = "BowlRim",
			size = Vector3.new(2.2, 0.45, 2.2),
			cf = CFrame.new(0, 0.92, 0),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = m,
		})
		local core = makePart({
			name = "PearlCore",
			size = Vector3.one * 1.05,
			cf = CFrame.new(0, 1.45, 0),
			color = PALETTE.crystalCyan,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			parent = m,
		})
		addBubbleEmitter(core, 7, 3.4, 2.4)
		m.Parent = folder
	end

	-- 5. Moldura Dourada do Santuário (8.00/s)
	do
		local m = createDecorSkeleton({
			id = "decor_golden_frame",
			namePT = "Moldura Dourada do Santuário",
			nameEN = "Golden Sanctuary Crest",
			attachType = "CrownArch",
			milestoneRate = 8.00,
			persist = true,
			boundsSize = Vector3.new(5.6, 2.6, 1.4),
			boundsOffsetY = 1.2,
			camPos = Vector3.new(0, 1.6, 6.2),
			camTarget = Vector3.new(0, 1.2, 0),
		})
		makePart({
			name = "ArchBar",
			size = Vector3.new(5.2, 0.52, 0.6),
			cf = CFrame.new(0, 0.45, 0),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "CenterSun",
			size = Vector3.new(1.5, 1.5, 0.75),
			cf = CFrame.new(0, 1.35, 0) * CFrame.Angles(0, 0, math.rad(45)),
			color = PALETTE.goldBright,
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "CenterCrystal",
			size = Vector3.new(0.85, 0.85, 0.9),
			cf = CFrame.new(0, 1.35, 0) * CFrame.Angles(0, 0, math.rad(45)),
			color = PALETTE.crystalCyan,
			material = Enum.Material.Neon,
			parent = m,
		})
		for _, s in ipairs({ -1, 1 }) do
			makeWedge(
				"Wing_" .. (s + 2),
				Vector3.new(0.55, 1.1, 1.8),
				CFrame.new(s * 1.95, 1.05, 0)
					* CFrame.Angles(0, if s < 0 then math.rad(90) else math.rad(-90), 0),
				PALETTE.gold,
				Enum.Material.Metal,
				false,
				m
			)
		end
		m.Parent = folder
	end

	-- 6. Poste-Lanterna de Pérola (DeckPost)
	do
		local m = createDecorSkeleton({
			id = "decor_shell_lantern",
			namePT = "Poste-Lanterna de Pérola",
			nameEN = "Pearl Lantern Post",
			attachType = "DeckPost",
			milestoneRate = 0,
			persist = true,
			boundsSize = Vector3.new(1.8, 5.0, 1.8),
			boundsOffsetY = 2.5,
			camPos = Vector3.new(2.8, 3.2, 5.2),
			camTarget = Vector3.new(0, 2.5, 0),
		})
		makePart({
			name = "Base",
			size = Vector3.new(1.3, 0.55, 1.3),
			cf = CFrame.new(0, 0.275, 0),
			color = PALETTE.stoneLight,
			parent = m,
		})
		makePart({
			name = "Shaft",
			size = Vector3.new(0.48, 3.8, 0.48),
			cf = CFrame.new(0, 2.35, 0),
			color = PALETTE.woodDark,
			material = Enum.Material.Wood,
			parent = m,
		})
		makePart({
			name = "LanternCap",
			size = Vector3.new(1.25, 0.34, 1.25),
			cf = CFrame.new(0, 4.75, 0),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "PearlBulb",
			size = Vector3.one * 0.88,
			cf = CFrame.new(0, 4.25, 0),
			color = PALETTE.lanternAmber,
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			parent = m,
		})
		m.Parent = folder
	end

	-- 7. Baú do Tesouro Submerso (FloorBed)
	do
		local m = createDecorSkeleton({
			id = "decor_sunken_chest",
			namePT = "Baú do Tesouro Submerso",
			nameEN = "Sunken Treasure Chest",
			attachType = "FloorBed",
			milestoneRate = 0,
			persist = true,
			boundsSize = Vector3.new(2.8, 2.0, 2.2),
			boundsOffsetY = 0.95,
			camPos = Vector3.new(2.5, 2.0, 3.8),
			camTarget = Vector3.new(0, 0.85, 0),
		})
		makePart({
			name = "ChestBody",
			size = Vector3.new(2.3, 1.05, 1.5),
			cf = CFrame.new(0, 0.525, 0),
			color = PALETTE.woodMain,
			material = Enum.Material.WoodPlanks,
			parent = m,
		})
		makePart({
			name = "ChestBand",
			size = Vector3.new(2.42, 0.22, 1.62),
			cf = CFrame.new(0, 0.9, 0),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = m,
		})
		makePart({
			name = "ChestLid",
			size = Vector3.new(2.3, 0.42, 1.4),
			cf = CFrame.new(0, 1.48, -0.58) * CFrame.Angles(math.rad(-42), 0, 0),
			color = PALETTE.woodDark,
			material = Enum.Material.Wood,
			parent = m,
		})
		makePart({
			name = "GoldPile",
			size = Vector3.new(1.9, 0.38, 1.1),
			cf = CFrame.new(0, 1.08, 0.05),
			color = PALETTE.goldBright,
			material = Enum.Material.Neon,
			parent = m,
		})
		m.Parent = folder
	end

	-- 8. Monólito Cristalino (15.00/s CenterBed)
	do
		local m = createDecorSkeleton({
			id = "decor_astral_obelisk",
			namePT = "Monólito Cristalino",
			nameEN = "Astral Crystal Obelisk",
			attachType = "CenterBed",
			milestoneRate = 15.00,
			persist = true,
			boundsSize = Vector3.new(3.6, 5.2, 3.6),
			boundsOffsetY = 2.6,
			camPos = Vector3.new(3.8, 3.2, 6.0),
			camTarget = Vector3.new(0, 2.5, 0),
		})
		makePart({
			name = "StoneAltar",
			size = Vector3.new(3.0, 0.8, 3.0),
			cf = CFrame.new(0, 0.4, 0),
			color = PALETTE.stoneLight,
			parent = m,
		})
		makePart({
			name = "GoldRing",
			size = Vector3.new(2.4, 0.28, 2.4),
			cf = CFrame.new(0, 1.0, 0),
			color = PALETTE.gold,
			material = Enum.Material.Metal,
			parent = m,
		})
		buildCrystalCluster(
			m,
			"ObeliskCrystals",
			Vector3.new(0, 1.05, 0),
			1.35,
			PALETTE.crystalLilac,
			PALETTE.crystalCyan,
			5
		)
		m.Parent = folder
	end
end

-- =========================================================================
-- VARIANT & SYNERGY VISUAL REFERENCE KIT
-- Verified in Studio on real textured MeshParts (preserves eyes/face!)
-- =========================================================================
local function applyGoldenRecipe(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("MeshPart") and d.TextureID ~= "" then
			local existing = d:FindFirstChildOfClass("SurfaceAppearance")
			if existing then
				existing:Destroy()
			end
			-- Warm peach-amber suppresses blue->green shift while preserving dark eyes/mouth/stripes
			local sa = Instance.new("SurfaceAppearance")
			sa.Name = "GoldenTintSA"
			sa.ColorMap = d.TextureID
			sa.Color = Color3.fromRGB(255, 174, 88)
			sa.AlphaMode = Enum.AlphaMode.Opaque
			sa.Parent = d
		end
	end
	local hl = Instance.new("Highlight")
	hl.Name = "GoldenVariantHighlight"
	hl.FillColor = Color3.fromRGB(255, 206, 36)
	hl.FillTransparency = 0.34
	hl.OutlineColor = Color3.fromRGB(255, 250, 190)
	hl.OutlineTransparency = 0.02
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = model

	local host = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if host then
		local att = Instance.new("Attachment")
		att.Name = "GoldGlintAnchor"
		att.Parent = host
		local em = Instance.new("ParticleEmitter")
		em.Name = "GoldGlintEmitter"
		em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		em.Color = ColorSequence.new(Color3.fromRGB(255, 248, 185), Color3.fromRGB(255, 196, 48))
		em.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.06),
			NumberSequenceKeypoint.new(0.45, 0.34),
			NumberSequenceKeypoint.new(1, 0.04),
		})
		em.Lifetime = NumberRange.new(0.65, 1.15)
		em.Speed = NumberRange.new(0.4, 1.2)
		em.SpreadAngle = Vector2.new(180, 180)
		em.Rate = 4
		em.LightEmission = 0.85
		em.Parent = att
	end
end

local function buildVariantRefs(folder: Folder)
	local creatures = ReplicatedStorage:FindFirstChild("Creatures")
	local sample = creatures
		and (
			creatures:FindFirstChild("C07_Arraia_Prisma")
			or creatures:FindFirstChild("C01_Bolhinha_Azul")
		)

	local specs = {
		{ name = "Variant_Base", scale = 1.0, golden = false, giant = false, mult = 1.00 },
		{ name = "Variant_Giant", scale = 1.42, golden = false, giant = true, mult = 1.30 },
		{ name = "Variant_Golden", scale = 1.0, golden = true, giant = false, mult = 1.60 },
		{ name = "Variant_GiantGolden", scale = 1.42, golden = true, giant = true, mult = 1.90 },
	}

	for _, sp in ipairs(specs) do
		local container = Instance.new("Model")
		container.Name = sp.name
		container:SetAttribute("ScaleMultiplier", sp.scale)
		container:SetAttribute("IsGiant", sp.giant)
		container:SetAttribute("IsGolden", sp.golden)
		container:SetAttribute("IncomeMultiplier", sp.mult)
		-- Golden recipe parameters for Codex runtime helper
		if sp.golden then
			container:SetAttribute("SA_Color", Color3.fromRGB(255, 174, 88))
			container:SetAttribute("HL_FillColor", Color3.fromRGB(255, 206, 36))
			container:SetAttribute("HL_FillTransparency", 0.34)
			container:SetAttribute("HL_OutlineColor", Color3.fromRGB(255, 250, 190))
			container:SetAttribute("HL_OutlineTransparency", 0.02)
		end
		if sample and sample:IsA("Model") then
			local clone = sample:Clone()
			clone.Name = "Specimen"
			clone:ScaleTo(clone:GetScale() * sp.scale)
			clone:PivotTo(CFrame.new(0, 0, 0))
			if sp.golden then
				applyGoldenRecipe(clone)
			end
			-- Subtle Giant presence ring below specimen for silhouette separation
			if sp.giant then
				local _, sz = clone:GetBoundingBox()
				local ring = makePart({
					name = "GiantWakeRing",
					size = Vector3.new(
						0.12,
						math.max(sz.X, sz.Z) * 1.15,
						math.max(sz.X, sz.Z) * 1.15
					),
					cf = CFrame.new(0, -sz.Y * 0.56, 0) * CFrame.Angles(0, 0, math.rad(90)),
					color = if sp.golden then PALETTE.goldBright else PALETTE.crystalCyan,
					material = Enum.Material.Neon,
					transparency = 0.58,
					shape = Enum.PartType.Cylinder,
					parent = container,
				})
				ring:SetAttribute("Role", "GiantSilhouetteAccent")
			end
			clone.Parent = container
			container.PrimaryPart = clone.PrimaryPart
		end
		container.Parent = folder
	end

	-- Synergy Visual Signal Reference (Beam + Family Color Presets + Pulse Node)
	local syn = Instance.new("Model")
	syn.Name = "Synergy_Link_Ref"
	syn:SetAttribute("PulseDurationSeconds", 1.35)
	syn:SetAttribute("CooldownSeconds", 8.0)
	syn:SetAttribute("ReduceEffectsMode", "StaticBadgeOnly")
	local nodeA = makePart({
		name = "SynergyNodeA",
		size = Vector3.one * 0.45,
		cf = CFrame.new(-3, 0, 0),
		color = PALETTE.crystalCyan,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = syn,
	})
	local nodeB = makePart({
		name = "SynergyNodeB",
		size = Vector3.one * 0.45,
		cf = CFrame.new(3, 0, 0),
		color = PALETTE.coralPink,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		parent = syn,
	})
	local a0 = Instance.new("Attachment")
	a0.Parent = nodeA
	local a1 = Instance.new("Attachment")
	a1.Parent = nodeB
	local beam = Instance.new("Beam")
	beam.Name = "SynergyTether"
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.CurveSize0 = 1.4
	beam.CurveSize1 = -1.4
	beam.Width0 = 0.28
	beam.Width1 = 0.28
	beam.Color = ColorSequence.new(PALETTE.crystalCyan, PALETTE.coralPink)
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.5, 0.08),
		NumberSequenceKeypoint.new(1, 0.35),
	})
	beam.LightEmission = 0.9
	beam.FaceCamera = true
	beam.Parent = nodeA

	local familiesFolder = Instance.new("Folder")
	familiesFolder.Name = "FamilyPalettes"
	familiesFolder.Parent = syn
	for _, fam in ipairs(SYNERGY_FAMILIES) do
		local f = Instance.new("Configuration")
		f.Name = fam.id
		f:SetAttribute("NamePT", fam.namePT)
		f:SetAttribute("NameEN", fam.nameEN)
		f:SetAttribute("PrimaryColor", fam.color)
		f:SetAttribute("SecondaryColor", fam.secondary)
		f.Parent = familiesFolder
	end
	syn.PrimaryPart = nodeA
	syn.Parent = folder

	local incomeCfg = Instance.new("Configuration")
	incomeCfg.Name = "IncomeLabelColors"
	for rarity, col in pairs(INCOME_COLORS) do
		incomeCfg:SetAttribute(rarity, col)
	end
	incomeCfg.Parent = folder
end

-- =========================================================================
-- MAIN ENTRYPOINT
-- =========================================================================
local function ensureCleanFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local levelsFolder = ensureCleanFolder(ReplicatedStorage, "AquariumLevels")
local lv1 = buildLevel1()
lv1.Parent = levelsFolder
local lv2 = buildLevel2()
lv2.Parent = levelsFolder
local lv3 = buildLevel3()
lv3.Parent = levelsFolder
local lv4 = buildLevel4()
lv4.Parent = levelsFolder

local decorFolder = ensureCleanFolder(ReplicatedStorage, "AquariumDecor")
buildDecorCatalog(decorFolder)

local variantFolder = ensureCleanFolder(ReplicatedStorage, "AquariumVariantRefs")
buildVariantRefs(variantFolder)

-- Summary stats for audit
local stats = {}
for _, lvl in ipairs({ lv1, lv2, lv3, lv4 }) do
	local parts, lights, emitters = 0, 0, 0
	for _, d in ipairs(lvl:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		elseif d:IsA("Light") then
			lights += 1
		elseif d:IsA("ParticleEmitter") then
			emitters += 1
		end
	end
	table.insert(
		stats,
		string.format(
			"%s: slots=%d parts=%d lights=%d emitters=%d",
			lvl.Name,
			lvl:GetAttribute("Capacity") :: number,
			parts,
			lights,
			emitters
		)
	)
end
table.insert(stats, "DecorProps: " .. #decorFolder:GetChildren())
table.insert(stats, "VariantRefs: " .. #variantFolder:GetChildren())
return table.concat(stats, "\n")
