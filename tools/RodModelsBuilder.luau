--!strict
-- Builds detailed, lightweight stylized fishing rods directly into ServerStorage.RodModels
-- (backing up existing models as *_v1 in ServerStorage.RodPrototypes).
-- Convention required by src/server/Features/Rod:
--   * WorldPivot at grip origin (0, 0, 0)
--   * Rod extends toward -Z (~7.6 studs total)
--   * BasePart named "Tip" (Neon) at the very end for LineAttachment + TipGlow
--   * No scripts, no Collision, Massless = true, CastShadow = false on fine trim

local ServerStorage = game:GetService("ServerStorage")

local rodsFolder = ServerStorage:FindFirstChild("RodModels")
if not rodsFolder then
	local f = Instance.new("Folder")
	f.Name = "RodModels"
	f.Parent = ServerStorage
	rodsFolder = f
end

local protoFolder = ServerStorage:FindFirstChild("RodPrototypes")
if not protoFolder then
	local f = Instance.new("Folder")
	f.Name = "RodPrototypes"
	f.Parent = ServerStorage
	protoFolder = f
end

type RodTheme = {
	id: string,
	gripColor: Color3,
	gripMat: Enum.Material,
	trimColor: Color3,
	trimMat: Enum.Material,
	reelColor: Color3,
	lineColor: Color3,
	blankColor: Color3,
	accentColor: Color3,
	tipColor: Color3,
	style: string,
}

local THEMES: { RodTheme } = {
	{
		id = "starter",
		gripColor = Color3.fromRGB(196, 148, 96), -- warm cork
		gripMat = Enum.Material.Wood,
		trimColor = Color3.fromRGB(198, 156, 86), -- brushed brass
		trimMat = Enum.Material.Metal,
		reelColor = Color3.fromRGB(72, 78, 96),
		lineColor = Color3.fromRGB(150, 230, 255),
		blankColor = Color3.fromRGB(36, 40, 56),
		accentColor = Color3.fromRGB(95, 205, 238),
		tipColor = Color3.fromRGB(150, 230, 255),
		style = "starter",
	},
	{
		id = "coral",
		gripColor = Color3.fromRGB(186, 114, 88), -- warm driftwood
		gripMat = Enum.Material.Wood,
		trimColor = Color3.fromRGB(246, 198, 128), -- rose-gold
		trimMat = Enum.Material.Metal,
		reelColor = Color3.fromRGB(248, 236, 224), -- pearl
		lineColor = Color3.fromRGB(255, 190, 150),
		blankColor = Color3.fromRGB(230, 110, 120),
		accentColor = Color3.fromRGB(255, 154, 178),
		tipColor = Color3.fromRGB(255, 200, 160),
		style = "coral",
	},
	{
		id = "crystal",
		gripColor = Color3.fromRGB(52, 74, 112),
		gripMat = Enum.Material.SmoothPlastic,
		trimColor = Color3.fromRGB(205, 230, 250), -- silver
		trimMat = Enum.Material.Metal,
		reelColor = Color3.fromRGB(70, 178, 235),
		lineColor = Color3.fromRGB(145, 245, 255),
		blankColor = Color3.fromRGB(80, 170, 230),
		accentColor = Color3.fromRGB(120, 245, 255),
		tipColor = Color3.fromRGB(120, 240, 255),
		style = "crystal",
	},
	{
		id = "storm",
		gripColor = Color3.fromRGB(48, 52, 76),
		gripMat = Enum.Material.SmoothPlastic,
		trimColor = Color3.fromRGB(255, 205, 92), -- lightning gold
		trimMat = Enum.Material.Metal,
		reelColor = Color3.fromRGB(64, 62, 118),
		lineColor = Color3.fromRGB(210, 192, 255),
		blankColor = Color3.fromRGB(60, 60, 110),
		accentColor = Color3.fromRGB(190, 155, 255),
		tipColor = Color3.fromRGB(200, 190, 255),
		style = "storm",
	},
	{
		id = "astral",
		gripColor = Color3.fromRGB(56, 30, 96), -- cosmic velvet
		gripMat = Enum.Material.SmoothPlastic,
		trimColor = Color3.fromRGB(255, 212, 92), -- celestial gold
		trimMat = Enum.Material.Metal,
		reelColor = Color3.fromRGB(98, 52, 168),
		lineColor = Color3.fromRGB(255, 224, 130),
		blankColor = Color3.fromRGB(80, 40, 140),
		accentColor = Color3.fromRGB(255, 210, 90),
		tipColor = Color3.fromRGB(255, 210, 90),
		style = "astral",
	},
}

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material,
	shape: Enum.PartType?,
	shadow: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = shadow == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Cylinder aligned along Z axis (Roblox cylinders have length along local X, so rotate Y 90 deg).
local function cylZ(
	parent: Instance,
	name: string,
	length: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material,
	shadow: boolean?
): Part
	return makePart(
		parent,
		name,
		Vector3.new(length, diameter, diameter),
		cf * CFrame.Angles(0, math.rad(90), 0),
		color,
		mat,
		Enum.PartType.Cylinder,
		shadow
	)
end

-- Ring guide hanging beneath the blank (-Y side) facing along Z.
local function addGuideRing(
	parent: Instance,
	index: number,
	centerCf: CFrame,
	dropY: number,
	outerDiam: number,
	color: Color3,
	mat: Enum.Material
)
	-- Strut leg from shaft down to ring top
	makePart(
		parent,
		"GuideFoot" .. index,
		Vector3.new(0.05, dropY, 0.08),
		centerCf * CFrame.new(0, -dropY * 0.5, 0) * CFrame.Angles(math.rad(-14), 0, 0),
		color,
		mat,
		nil,
		false
	)
	local ringCenter = centerCf * CFrame.new(0, -dropY - outerDiam * 0.36, 0)
	local ringThick = math.max(0.04, outerDiam * 0.16)
	local radius = outerDiam * 0.5
	local segCount = 6
	local segLen = 2 * radius * math.sin(math.pi / segCount) + ringThick * 0.3
	for s = 1, segCount do
		local a = (s - 0.5) * (2 * math.pi / segCount)
		local p = Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)
		makePart(
			parent,
			string.format("Guide%d_%d", index, s),
			Vector3.new(segLen, ringThick, ringThick),
			ringCenter * CFrame.new(p) * CFrame.Angles(0, 0, a + math.pi / 2),
			color,
			mat,
			nil,
			false
		)
	end
end

local function buildRodModel(theme: RodTheme): Model
	local m = Instance.new("Model")
	m.Name = theme.id

	-- 1. Handle & Grip (centered at Z = 0, extending Z = +1.12 .. -0.92)
	-- Identity-aligned invisible PrimaryPart keeps GetBoundingBox() length on Z (-Z) for Shop previews.
	local gripRoot = makePart(
		m,
		"GripRoot",
		Vector3.new(0.16, 0.16, 0.16),
		CFrame.new(0, 0, 0),
		theme.gripColor,
		theme.gripMat,
		nil,
		false
	)
	gripRoot.Transparency = 1
	m.PrimaryPart = gripRoot
	cylZ(m, "GripCore", 1.15, 0.28, CFrame.new(0, 0, 0.02), theme.gripColor, theme.gripMat, true)

	-- Cork/leather grip band rings
	for idx, gz in { 0.42, 0.0, -0.42 } do
		cylZ(
			m,
			"GripRing" .. idx,
			0.06,
			0.31,
			CFrame.new(0, 0, gz),
			theme.trimColor,
			theme.trimMat,
			false
		)
	end

	-- Rear butt grip & pommel cap (+Z behind hand)
	cylZ(m, "RearCork", 0.42, 0.26, CFrame.new(0, 0, 0.80), theme.gripColor, theme.gripMat, true)
	cylZ(m, "RearCollar", 0.08, 0.31, CFrame.new(0, 0, 0.58), theme.trimColor, theme.trimMat, false)
	cylZ(m, "ButtCap", 0.16, 0.34, CFrame.new(0, 0, 1.07), theme.trimColor, theme.trimMat, false)
	makePart(
		m,
		"ButtGem",
		Vector3.new(0.20, 0.20, 0.14),
		CFrame.new(0, 0, 1.15),
		theme.accentColor,
		Enum.Material.Neon,
		Enum.PartType.Ball,
		false
	)

	-- Reel seat & front winding check (-Z ahead of hand)
	cylZ(
		m,
		"ReelSeat",
		0.44,
		0.27,
		CFrame.new(0, 0, -0.76),
		theme.reelColor,
		Enum.Material.Metal,
		true
	)
	cylZ(m, "ReelNut", 0.10, 0.33, CFrame.new(0, 0, -0.58), theme.trimColor, theme.trimMat, false)
	cylZ(
		m,
		"ForeWindingCheck",
		0.14,
		0.32,
		CFrame.new(0, 0, -1.00),
		theme.trimColor,
		theme.trimMat,
		false
	)

	-- 2. Detailed Spinning Reel under ReelSeat (-Y side at Z = -0.78)
	local reelAnchor = CFrame.new(0, -0.14, -0.78)
	makePart(
		m,
		"ReelStem",
		Vector3.new(0.11, 0.34, 0.16),
		reelAnchor * CFrame.new(0, -0.16, 0) * CFrame.Angles(math.rad(-14), 0, 0),
		theme.trimColor,
		theme.trimMat,
		nil,
		false
	)
	local reelBodyCf = reelAnchor * CFrame.new(0, -0.42, 0.08)
	makePart(
		m,
		"ReelBody",
		Vector3.new(0.32, 0.36, 0.56),
		reelBodyCf,
		theme.reelColor,
		Enum.Material.Metal,
		Enum.PartType.Ball,
		true
	)
	cylZ(
		m,
		"ReelRearCap",
		0.14,
		0.28,
		reelBodyCf * CFrame.new(0, 0.02, 0.26),
		theme.trimColor,
		theme.trimMat,
		false
	)

	-- Spool + visible line winding + front drag knob + bail arm
	local spoolCf = reelAnchor * CFrame.new(0, -0.40, -0.28)
	cylZ(
		m,
		"SpoolRimBack",
		0.05,
		0.44,
		spoolCf * CFrame.new(0, 0, 0.14),
		theme.trimColor,
		theme.trimMat,
		false
	)
	cylZ(m, "SpoolLine", 0.24, 0.37, spoolCf, theme.lineColor, Enum.Material.SmoothPlastic, false)
	cylZ(
		m,
		"SpoolRimFront",
		0.05,
		0.44,
		spoolCf * CFrame.new(0, 0, -0.14),
		theme.trimColor,
		theme.trimMat,
		false
	)
	cylZ(
		m,
		"DragKnob",
		0.10,
		0.20,
		spoolCf * CFrame.new(0, 0, -0.21),
		theme.trimColor,
		theme.trimMat,
		false
	)
	makePart(
		m,
		"BailArm",
		Vector3.new(0.50, 0.05, 0.05),
		spoolCf * CFrame.new(0, 0.22, -0.02),
		theme.trimColor,
		theme.trimMat,
		nil,
		false
	)

	-- Reel Crank Handle on right side (+X)
	local crankHub = reelBodyCf * CFrame.new(0.20, 0, 0)
	makePart(
		m,
		"CrankShaft",
		Vector3.new(0.18, 0.08, 0.08),
		crankHub,
		theme.trimColor,
		theme.trimMat,
		nil,
		false
	)
	makePart(
		m,
		"CrankArm",
		Vector3.new(0.06, 0.26, 0.07),
		crankHub * CFrame.new(0.10, -0.08, 0.04) * CFrame.Angles(math.rad(-22), 0, 0),
		theme.trimColor,
		theme.trimMat,
		nil,
		false
	)
	makePart(
		m,
		"CrankKnob",
		Vector3.new(0.14, 0.10, 0.10),
		crankHub * CFrame.new(0.18, -0.18, 0.09),
		theme.gripColor,
		theme.gripMat,
		Enum.PartType.Cylinder,
		false
	)

	-- 3. Tapered 4-Section Flexible Blank extending to -Z (~7.6 studs total)
	local sections = {
		{ len = 1.65, diam = 0.20, pitchDeg = 0.0, ferrule = true },
		{ len = 1.65, diam = 0.15, pitchDeg = -1.2, ferrule = true },
		{ len = 1.65, diam = 0.105, pitchDeg = -2.2, ferrule = true },
		{ len = 1.55, diam = 0.068, pitchDeg = -3.4, ferrule = false },
	}
	local cursor = CFrame.new(0, 0, -1.04)
	local tipEndCf = cursor
	local guideIndex = 0
	for i, sec in ipairs(sections) do
		cursor = cursor * CFrame.Angles(math.rad(sec.pitchDeg), 0, 0)
		local segCenter = cursor * CFrame.new(0, 0, -sec.len * 0.5)
		cylZ(
			m,
			"BlankSeg" .. i,
			sec.len + 0.03,
			sec.diam,
			segCenter,
			theme.blankColor,
			Enum.Material.SmoothPlastic,
			true
		)

		-- Accent ring wrap near each section start + ferrule sleeve at joint
		cylZ(
			m,
			"Wrap" .. i,
			0.12,
			sec.diam + 0.03,
			cursor * CFrame.new(0, 0, -0.18),
			theme.accentColor,
			Enum.Material.Neon,
			false
		)
		if sec.ferrule then
			cylZ(
				m,
				"Ferrule" .. i,
				0.14,
				sec.diam + 0.045,
				cursor * CFrame.new(0, 0, -sec.len),
				theme.trimColor,
				theme.trimMat,
				false
			)
		end

		-- Place graduated line guides along the blank (-Y side)
		for _, frac in (if i <= 2 then { 0.35, 0.85 } else { 0.55 }) do
			guideIndex += 1
			local gCf = cursor * CFrame.new(0, 0, -sec.len * frac)
			local gDiam = math.max(0.13, 0.34 - guideIndex * 0.035)
			local drop = math.max(0.08, 0.20 - guideIndex * 0.02)
			addGuideRing(m, guideIndex, gCf, drop, gDiam, theme.trimColor, theme.trimMat)
		end

		cursor = cursor * CFrame.new(0, 0, -sec.len)
		tipEndCf = cursor
	end

	-- 4. Glowing Neon Tip piece (required name = "Tip")
	local tipCollar = tipEndCf * CFrame.new(0, 0, -0.02)
	cylZ(m, "TipRing", 0.08, 0.10, tipCollar, theme.trimColor, theme.trimMat, false)
	makePart(
		m,
		"Tip",
		Vector3.new(0.20, 0.20, 0.20),
		tipEndCf * CFrame.new(0, 0, -0.11),
		theme.tipColor,
		Enum.Material.Neon,
		Enum.PartType.Ball,
		false
	)

	-- 5. Theme-specific hero flourishes (carefully positioned clear of the hand grip Z = -0.55..+0.55!)
	if theme.style == "coral" then
		-- Living coral sprigs near fore-winding check & pearl finial on reel
		makePart(
			m,
			"ReelPearl",
			Vector3.new(0.22, 0.22, 0.22),
			reelBodyCf * CFrame.new(-0.18, 0, 0.04),
			Color3.fromRGB(255, 244, 240),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball,
			false
		)
		for idx, ang in ipairs({ 26, -32, 8 }) do
			local branchCf = CFrame.new(0, 0.10, -1.16 - idx * 0.18)
				* CFrame.Angles(math.rad(18), math.rad(ang), math.rad(ang * 0.6))
			cylZ(
				m,
				"CoralTwig" .. idx,
				0.42,
				0.10,
				branchCf * CFrame.new(0, 0.14, 0) * CFrame.Angles(math.rad(55), 0, 0),
				theme.accentColor,
				Enum.Material.SmoothPlastic,
				false
			)
			makePart(
				m,
				"CoralBulb" .. idx,
				Vector3.new(0.14, 0.14, 0.14),
				branchCf * CFrame.new(0, 0.30, -0.12),
				theme.tipColor,
				Enum.Material.Neon,
				Enum.PartType.Ball,
				false
			)
		end
	elseif theme.style == "crystal" then
		-- Glowing faceted cyan crystals mounted neatly at the foregrip collar & joint 1
		for idx, item in ipairs({
			{
				cf = CFrame.new(0, 0.18, -1.10) * CFrame.Angles(math.rad(28), 0, 0),
				s = Vector3.new(0.20, 0.56, 0.20),
			},
			{
				cf = CFrame.new(0.16, 0.12, -1.18) * CFrame.Angles(math.rad(22), 0, math.rad(-32)),
				s = Vector3.new(0.14, 0.40, 0.14),
			},
			{
				cf = CFrame.new(-0.16, 0.12, -1.18) * CFrame.Angles(math.rad(22), 0, math.rad(32)),
				s = Vector3.new(0.14, 0.40, 0.14),
			},
			{
				cf = CFrame.new(0, 0.15, -2.65) * CFrame.Angles(math.rad(34), 0, 0),
				s = Vector3.new(0.14, 0.38, 0.14),
			},
		}) do
			makePart(
				m,
				"CrystalShard" .. idx,
				item.s,
				item.cf,
				theme.accentColor,
				Enum.Material.Neon,
				nil,
				false
			)
		end
	elseif theme.style == "storm" then
		-- Twin golden lightning fins ahead of reel seat & energized coil wraps
		for _, sx in { -1, 1 } do
			makePart(
				m,
				"StormFin" .. sx,
				Vector3.new(0.08, 0.44, 0.58),
				CFrame.new(sx * 0.22, 0.12, -1.24)
					* CFrame.Angles(math.rad(24), math.rad(sx * 16), math.rad(sx * -26)),
				theme.trimColor,
				Enum.Material.Metal,
				nil,
				false
			)
			makePart(
				m,
				"StormArc" .. sx,
				Vector3.new(0.06, 0.18, 0.42),
				CFrame.new(sx * 0.27, 0.22, -1.36)
					* CFrame.Angles(math.rad(30), math.rad(sx * 16), math.rad(sx * -26)),
				theme.accentColor,
				Enum.Material.Neon,
				nil,
				false
			)
		end
		cylZ(m, "StormCoreGlow", 0.28, 0.41, spoolCf, theme.accentColor, Enum.Material.Neon, false)
	elseif theme.style == "astral" then
		-- Celestial sun orb + tilted golden halo rings mounted at foregrip collar + twin crescent wings
		local orbCenter = CFrame.new(0, 0.26, -1.22)
		makePart(
			m,
			"AstralOrb",
			Vector3.new(0.32, 0.32, 0.32),
			orbCenter,
			theme.tipColor,
			Enum.Material.Neon,
			Enum.PartType.Ball,
			false
		)
		for s = 1, 10 do
			local a = (s - 0.5) * (2 * math.pi / 10)
			local r = 0.42
			local seg = 2 * r * math.sin(math.pi / 10) + 0.03
			makePart(
				m,
				"AstralHalo" .. s,
				Vector3.new(seg, 0.06, 0.06),
				orbCenter
					* CFrame.Angles(math.rad(55), 0, math.rad(18))
					* CFrame.new(math.cos(a) * r, math.sin(a) * r, 0)
					* CFrame.Angles(0, 0, a + math.pi / 2),
				theme.trimColor,
				Enum.Material.Metal,
				nil,
				false
			)
		end
		for _, sx in { -1, 1 } do
			makePart(
				m,
				"AstralWing" .. sx,
				Vector3.new(0.07, 0.48, 0.62),
				CFrame.new(sx * 0.24, 0.18, -1.40)
					* CFrame.Angles(math.rad(28), math.rad(sx * 20), math.rad(sx * -34)),
				theme.trimColor,
				Enum.Material.Metal,
				nil,
				false
			)
		end
	end

	m.WorldPivot = CFrame.new(0, 0, 0)
	return m
end

for _, theme in THEMES do
	local old = rodsFolder:FindFirstChild(theme.id)
	if old then
		local backupName = theme.id .. "_v1"
		if not protoFolder:FindFirstChild(backupName) then
			old.Name = backupName
			old.Parent = protoFolder
		else
			old:Destroy()
		end
	end
	local built = buildRodModel(theme)
	built.Parent = rodsFolder
	local cf, sz = built:GetBoundingBox()
	local tip = built:FindFirstChild("Tip") :: BasePart
	print(
		string.format(
			"[RodModelsBuilder] Built %s: parts=%d size=(%.2f, %.2f, %.2f) tipZ=%.2f centerZ=%.2f",
			theme.id,
			#built:GetDescendants(),
			sz.X,
			sz.Y,
			sz.Z,
			tip.Position.Z,
			cf.Position.Z
		)
	)
end

return true
