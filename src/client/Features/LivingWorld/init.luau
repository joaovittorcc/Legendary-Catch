--!strict
-- Living world polish (client-side, mobile-friendly):
--   1. Smooth atmosphere & lighting tints synced to server DayNight clock, yielding cleanly to OceanEvents
--   2. Night-reactive island lanterns + light campfire flame/spark emitters
--   3. Procedural breathing/head-look on GuideNPC + 2 new stylized NPCs (pier bait vendor & shore shell girl)
--      with rotating proximity BillboardGui dialogue in PT/EN.
-- Disables animations and particle emitters when Player attribute ReduceEffects = true.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EventsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Events"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local Hud = require(script.Parent:WaitForChild("Hud"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Panel = require(script.Parent.Hud:WaitForChild("Panel"))

local LivingWorld = {}
LivingWorld.order = 320

local player = Players.LocalPlayer

type SkyKeyframe = {
	hour: number,
	ambient: Color3,
	outdoor: Color3,
	shiftTop: Color3,
	atmColor: Color3,
	atmDecay: Color3,
	brightness: number,
	density: number,
	glare: number,
	haze: number,
}

local KEYFRAMES: { SkyKeyframe } = {
	{
		hour = 0.0,
		ambient = Color3.fromRGB(102, 108, 172),
		outdoor = Color3.fromRGB(116, 134, 198),
		shiftTop = Color3.fromRGB(122, 136, 218),
		atmColor = Color3.fromRGB(92, 112, 188),
		atmDecay = Color3.fromRGB(68, 70, 145),
		brightness = 1.65,
		density = 0.36,
		glare = 0.05,
		haze = 1.5,
	},
	{
		hour = 5.5,
		ambient = Color3.fromRGB(115, 118, 178),
		outdoor = Color3.fromRGB(134, 144, 198),
		shiftTop = Color3.fromRGB(150, 140, 210),
		atmColor = Color3.fromRGB(124, 132, 198),
		atmDecay = Color3.fromRGB(110, 96, 165),
		brightness = 1.85,
		density = 0.35,
		glare = 0.1,
		haze = 1.45,
	},
	{
		hour = 6.75, -- Pink dawn
		ambient = Color3.fromRGB(178, 146, 168),
		outdoor = Color3.fromRGB(220, 178, 188),
		shiftTop = Color3.fromRGB(255, 192, 206),
		atmColor = Color3.fromRGB(246, 190, 202),
		atmDecay = Color3.fromRGB(196, 126, 152),
		brightness = 2.55,
		density = 0.34,
		glare = 0.32,
		haze = 1.35,
	},
	{
		hour = 9.0, -- Bright tropical morning
		ambient = Color3.fromRGB(116, 126, 156),
		outdoor = Color3.fromRGB(154, 174, 204),
		shiftTop = Color3.fromRGB(185, 224, 255),
		atmColor = Color3.fromRGB(196, 226, 255),
		atmDecay = Color3.fromRGB(96, 150, 210),
		brightness = 3.0,
		density = 0.32,
		glare = 0.22,
		haze = 1.2,
	},
	{
		hour = 15.5,
		ambient = Color3.fromRGB(122, 130, 158),
		outdoor = Color3.fromRGB(164, 180, 204),
		shiftTop = Color3.fromRGB(210, 226, 248),
		atmColor = Color3.fromRGB(204, 228, 255),
		atmDecay = Color3.fromRGB(112, 156, 205),
		brightness = 2.95,
		density = 0.33,
		glare = 0.28,
		haze = 1.25,
	},
	{
		hour = 17.6, -- Golden afternoon
		ambient = Color3.fromRGB(168, 138, 124),
		outdoor = Color3.fromRGB(232, 178, 122),
		shiftTop = Color3.fromRGB(255, 208, 138),
		atmColor = Color3.fromRGB(255, 212, 152),
		atmDecay = Color3.fromRGB(214, 136, 84),
		brightness = 2.6,
		density = 0.35,
		glare = 0.45,
		haze = 1.4,
	},
	{
		hour = 19.2, -- Violet twilight -> night
		ambient = Color3.fromRGB(112, 114, 178),
		outdoor = Color3.fromRGB(128, 140, 200),
		shiftTop = Color3.fromRGB(142, 138, 216),
		atmColor = Color3.fromRGB(106, 118, 190),
		atmDecay = Color3.fromRGB(82, 78, 152),
		brightness = 1.8,
		density = 0.36,
		glare = 0.08,
		haze = 1.5,
	},
	{
		hour = 24.0,
		ambient = Color3.fromRGB(102, 108, 172),
		outdoor = Color3.fromRGB(116, 134, 198),
		shiftTop = Color3.fromRGB(122, 136, 218),
		atmColor = Color3.fromRGB(92, 112, 188),
		atmDecay = Color3.fromRGB(68, 70, 145),
		brightness = 1.65,
		density = 0.36,
		glare = 0.05,
		haze = 1.5,
	},
}

local function sampleSky(clock: number): SkyKeyframe
	local c = clock % 24
	for i = 1, #KEYFRAMES - 1 do
		local a = KEYFRAMES[i]
		local b = KEYFRAMES[i + 1]
		if c >= a.hour and c <= b.hour then
			local alpha = (c - a.hour) / math.max(0.001, b.hour - a.hour)
			return {
				hour = c,
				ambient = a.ambient:Lerp(b.ambient, alpha),
				outdoor = a.outdoor:Lerp(b.outdoor, alpha),
				shiftTop = a.shiftTop:Lerp(b.shiftTop, alpha),
				atmColor = a.atmColor:Lerp(b.atmColor, alpha),
				atmDecay = a.atmDecay:Lerp(b.atmDecay, alpha),
				brightness = a.brightness + (b.brightness - a.brightness) * alpha,
				density = a.density + (b.density - a.density) * alpha,
				glare = a.glare + (b.glare - a.glare) * alpha,
				haze = a.haze + (b.haze - a.haze) * alpha,
			}
		end
	end
	return KEYFRAMES[1]
end

local function nightWeightFor(clock: number): number
	if clock >= 17.5 and clock < 19.0 then
		return (clock - 17.5) / 1.5
	elseif clock >= 19.0 or clock < 5.5 then
		return 1
	elseif clock >= 5.5 and clock < 7.0 then
		return 1 - (clock - 5.5) / 1.5
	end
	return 0
end

type LanternTarget = {
	part: BasePart,
	light: PointLight?,
	baseBrightness: number,
	dayColor: Color3,
}

local function collectLanterns(island: Instance?): { LanternTarget }
	local targets: { LanternTarget } = {}
	if not island then
		return targets
	end
	for _, d in island:GetDescendants() do
		if
			d:IsA("BasePart")
			and (
				d.Name == "LightSource"
				or d.Name == "LanternLight"
				or string.find(d.Name, "^WelcomeLanternGlow") ~= nil
			)
		then
			local pl = d:FindFirstChildOfClass("PointLight")
			table.insert(targets, {
				part = d,
				light = pl,
				baseBrightness = if pl then math.max(pl.Brightness, 1.3) else 1.4,
				dayColor = d.Color,
			})
		end
	end
	return targets
end

local function mountCampfireEmitters(island: Instance?): { ParticleEmitter }
	local list: { ParticleEmitter } = {}
	local campfire = island and island:FindFirstChild("Campfire")
	local embers = campfire and campfire:FindFirstChild("Embers")
	if not (embers and embers:IsA("BasePart")) then
		return list
	end
	if not embers:FindFirstChild("FlameMotes") then
		local flame = Instance.new("ParticleEmitter")
		flame.Name = "FlameMotes"
		flame.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		flame.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 224, 110)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 136, 52)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 68, 36)),
		})
		flame.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(0.5, 0.35),
			NumberSequenceKeypoint.new(1, 0),
		})
		flame.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
		flame.LightEmission = 0.9
		flame.Rate = 4
		flame.Lifetime = NumberRange.new(0.8, 1.3)
		flame.Speed = NumberRange.new(1.4, 2.3)
		flame.SpreadAngle = Vector2.new(14, 14)
		flame.EmissionDirection = Enum.NormalId.Top
		flame.Parent = embers
		table.insert(list, flame)
	end
	if not embers:FindFirstChild("SparkMotes") then
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "SparkMotes"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(Color3.fromRGB(255, 228, 130))
		sparks.Size = NumberSequence.new(0.11, 0)
		sparks.Transparency = NumberSequence.new(0.15, 1)
		sparks.LightEmission = 1
		sparks.Rate = 2
		sparks.Lifetime = NumberRange.new(1.3, 2.1)
		sparks.Speed = NumberRange.new(1.8, 3.0)
		sparks.SpreadAngle = Vector2.new(26, 26)
		sparks.EmissionDirection = Enum.NormalId.Top
		sparks.Parent = embers
		table.insert(list, sparks)
	end
	return list
end

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): BasePart
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

type AnimatedNpc = {
	headRoot: CFrame,
	headForward: Vector3,
	headParts: { { part: BasePart, offset: CFrame } },
	torsoRoot: CFrame,
	torsoParts: { { part: BasePart, offset: CFrame } },
	currentYaw: number,
	lookRadius: number,
	talkRadius: number,
	phase: number,
	speechPoint: Attachment?,
	lines: { string }?,
	displayName: string?,
	accent: Color3?,
	iconGlyph: string?,
}

local function bindGuideNpc(guide: Instance): AnimatedNpc?
	local torso = guide:FindFirstChild("Torso")
	local head = guide:FindFirstChild("Head")
	local nose = guide:FindFirstChild("Nose")
	if not (torso and torso:IsA("BasePart") and head and head:IsA("BasePart")) then
		return nil
	end
	local headRoot = head.CFrame
	local torsoRoot = torso.CFrame
	local headInv = headRoot:Inverse()
	local torsoInv = torsoRoot:Inverse()

	local headFwd = if nose and nose:IsA("BasePart")
		then Vector3.new(nose.Position.X - head.Position.X, 0, nose.Position.Z - head.Position.Z).Unit
		else -headRoot.RightVector

	local headNames = {
		Head = true,
		Nose = true,
		BackHair = true,
		BackHairTuft = true,
	}
	local headPrefixes = { "Eye", "Brow", "Ear", "Sideburn" }
	local staticPrefixes = { "Leg", "Boot" }

	local headParts: { { part: BasePart, offset: CFrame } } = {}
	local torsoParts: { { part: BasePart, offset: CFrame } } = {}

	for _, d in guide:GetDescendants() do
		if d:IsA("BasePart") then
			local isStatic = false
			for _, pref in staticPrefixes do
				if string.sub(d.Name, 1, #pref) == pref then
					isStatic = true
					break
				end
			end
			if not isStatic then
				local isHead = headNames[d.Name] == true
					or (d.Position.Y > 15.6 and d.Name == "body_geom")
				if not isHead then
					for _, pref in headPrefixes do
						if string.sub(d.Name, 1, #pref) == pref then
							isHead = true
							break
						end
					end
				end
				if isHead then
					table.insert(headParts, { part = d, offset = headInv * d.CFrame })
				elseif d.Name ~= "Neck" then
					table.insert(torsoParts, { part = d, offset = torsoInv * d.CFrame })
				end
			end
		end
	end

	return {
		headRoot = headRoot,
		headForward = headFwd,
		headParts = headParts,
		torsoRoot = torsoRoot,
		torsoParts = torsoParts,
		currentYaw = 0,
		lookRadius = 26,
		talkRadius = 0, -- Guide/init.luau owns GuideNPC speech bubble
		phase = 0.2,
	}
end

local function buildCustomNpc(
	parent: Instance,
	spec: {
		name: string,
		cf: CFrame,
		shirt: Color3,
		vest: Color3,
		pants: Color3,
		skin: Color3,
		hair: Color3,
		hatColor: Color3,
		hatBand: Color3,
		propColor: Color3,
		lines: { string },
		displayName: string,
		accent: Color3,
		iconGlyph: string,
		phase: number,
		isVendor: boolean,
	}
): AnimatedNpc
	local model = Instance.new("Model")
	model.Name = spec.name

	-- Grounded legs & shoes (feet sit at local Y = 0)
	local bootColor = Color3.fromRGB(64, 46, 40)
	makePart(
		model,
		"BootL",
		Vector3.new(0.6, 0.45, 0.8),
		spec.cf * CFrame.new(0.4, 0.225, -0.05),
		bootColor
	)
	makePart(
		model,
		"BootR",
		Vector3.new(0.6, 0.45, 0.8),
		spec.cf * CFrame.new(-0.4, 0.225, -0.05),
		bootColor
	)
	makePart(
		model,
		"LegL",
		Vector3.new(0.54, 1.35, 0.54),
		spec.cf * CFrame.new(0.4, 1.12, 0),
		spec.pants
	)
	makePart(
		model,
		"LegR",
		Vector3.new(0.54, 1.35, 0.54),
		spec.cf * CFrame.new(-0.4, 1.12, 0),
		spec.pants
	)

	-- Torso + arms + cute prop
	local torsoRoot = spec.cf * CFrame.new(0, 2.7, 0)
	local torsoInv = torsoRoot:Inverse()
	local torsoParts: { { part: BasePart, offset: CFrame } } = {}
	local function addTorso(
		name: string,
		size: Vector3,
		localCF: CFrame,
		col: Color3,
		mat: Enum.Material?,
		shape: Enum.PartType?
	)
		local p = makePart(model, name, size, torsoRoot * localCF, col, mat, shape)
		table.insert(torsoParts, { part = p, offset = torsoInv * p.CFrame })
	end

	addTorso("Torso", Vector3.new(1.55, 1.75, 0.95), CFrame.new(), spec.shirt)
	addTorso("Vest", Vector3.new(1.64, 1.35, 1.02), CFrame.new(0, -0.08, 0), spec.vest)
	addTorso(
		"ArmL",
		Vector3.new(0.48, 1.45, 0.48),
		CFrame.new(1.06, -0.05, -0.06) * CFrame.Angles(0, 0, math.rad(-10)),
		spec.skin
	)
	addTorso(
		"ArmR",
		Vector3.new(0.48, 1.45, 0.48),
		CFrame.new(-1.06, -0.05, -0.06) * CFrame.Angles(0, 0, math.rad(10)),
		spec.skin
	)
	-- Held bucket / basket prop
	addTorso(
		"PropBucket",
		Vector3.new(0.7, 0.65, 0.7),
		CFrame.new(1.12, -0.82, -0.35),
		spec.propColor,
		Enum.Material.Wood,
		Enum.PartType.Cylinder
	)
	addTorso(
		"PropGlow",
		Vector3.new(0.45, 0.25, 0.45),
		CFrame.new(1.12, -0.52, -0.35),
		spec.accent,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)

	-- Head + face + hat (forward is -Z of spec.cf)
	local headRoot = spec.cf * CFrame.new(0, 4.25, 0)
	local headInv = headRoot:Inverse()
	local headParts: { { part: BasePart, offset: CFrame } } = {}
	local function addHead(
		name: string,
		size: Vector3,
		localCF: CFrame,
		col: Color3,
		mat: Enum.Material?,
		shape: Enum.PartType?
	)
		local p = makePart(model, name, size, headRoot * localCF, col, mat, shape)
		table.insert(headParts, { part = p, offset = headInv * p.CFrame })
	end

	addHead("Head", Vector3.new(1.3, 1.25, 1.25), CFrame.new(), spec.skin, nil, Enum.PartType.Ball)
	addHead(
		"HairBack",
		Vector3.new(1.38, 1.1, 0.85),
		CFrame.new(0, 0.05, 0.26),
		spec.hair,
		nil,
		Enum.PartType.Ball
	)
	addHead(
		"EyeL",
		Vector3.new(0.18, 0.24, 0.14),
		CFrame.new(0.28, 0.08, -0.56),
		Color3.fromRGB(28, 28, 38),
		nil,
		Enum.PartType.Ball
	)
	addHead(
		"EyeR",
		Vector3.new(0.18, 0.24, 0.14),
		CFrame.new(-0.28, 0.08, -0.56),
		Color3.fromRGB(28, 28, 38),
		nil,
		Enum.PartType.Ball
	)
	addHead(
		"EyeShineL",
		Vector3.new(0.07, 0.07, 0.07),
		CFrame.new(0.31, 0.14, -0.61),
		Color3.new(1, 1, 1),
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	addHead(
		"EyeShineR",
		Vector3.new(0.07, 0.07, 0.07),
		CFrame.new(-0.25, 0.14, -0.61),
		Color3.new(1, 1, 1),
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	addHead(
		"BlushL",
		Vector3.new(0.18, 0.1, 0.08),
		CFrame.new(0.38, -0.1, -0.52),
		Color3.fromRGB(255, 145, 165)
	)
	addHead(
		"BlushR",
		Vector3.new(0.18, 0.1, 0.08),
		CFrame.new(-0.38, -0.1, -0.52),
		Color3.fromRGB(255, 145, 165)
	)
	addHead(
		"HatBrim",
		Vector3.new(2.05, 0.14, 2.05),
		CFrame.new(0, 0.56, 0),
		spec.hatColor,
		nil,
		Enum.PartType.Cylinder
	)
	addHead("HatCrown", Vector3.new(1.22, 0.52, 1.22), CFrame.new(0, 0.84, 0), spec.hatColor)
	addHead("HatBand", Vector3.new(1.3, 0.16, 1.3), CFrame.new(0, 0.68, 0), spec.hatBand)

	-- Ground props beside each NPC
	if spec.isVendor then
		-- Crate + glowing bait jars beside Marina on the pier
		makePart(
			model,
			"BaitCrate",
			Vector3.new(1.6, 1.2, 1.2),
			spec.cf * CFrame.new(-1.6, 0.6, -0.1),
			Color3.fromRGB(148, 90, 52),
			Enum.Material.WoodPlanks
		)
		makePart(
			model,
			"BaitJar1",
			Vector3.new(0.4, 0.55, 0.4),
			spec.cf * CFrame.new(-1.85, 1.48, -0.15),
			Color3.fromRGB(90, 255, 220),
			Enum.Material.Neon
		)
		makePart(
			model,
			"BaitJar2",
			Vector3.new(0.36, 0.48, 0.36),
			spec.cf * CFrame.new(-1.35, 1.44, 0.05),
			Color3.fromRGB(255, 178, 96),
			Enum.Material.Neon
		)
	else
		-- Pretty seashells near Luna on the seaside landing
		makePart(
			model,
			"Shell1",
			Vector3.new(0.65, 0.24, 0.65),
			spec.cf * CFrame.new(-1.45, 0.12, -0.45),
			Color3.fromRGB(255, 182, 206),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
		makePart(
			model,
			"Shell2",
			Vector3.new(0.55, 0.22, 0.55),
			spec.cf * CFrame.new(1.4, 0.11, -0.6),
			Color3.fromRGB(145, 232, 255),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
		makePart(
			model,
			"Shell3",
			Vector3.new(0.5, 0.2, 0.5),
			spec.cf * CFrame.new(-1.1, 0.1, 0.65),
			Color3.fromRGB(255, 224, 140),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Ball
		)
	end

	local speechHead = headParts[1].part
	local speechPoint = Instance.new("Attachment")
	speechPoint.Name = "SpeechPoint"
	speechPoint.Position = Vector3.new(0, 1.5, 0)
	speechPoint.Parent = speechHead

	model.Parent = parent
	return {
		headRoot = headRoot,
		headForward = spec.cf.LookVector,
		headParts = headParts,
		torsoRoot = torsoRoot,
		torsoParts = torsoParts,
		currentYaw = 0,
		lookRadius = 22,
		talkRadius = 18,
		phase = spec.phase,
		speechPoint = speechPoint,
		lines = spec.lines,
		displayName = spec.displayName,
		accent = spec.accent,
		iconGlyph = spec.iconGlyph,
	}
end

local function buildSpeechBubble(
	anchor: Attachment,
	titleText: string,
	accent: Color3,
	glyphChar: string,
	maxDist: number
): (BillboardGui, TextLabel, Frame)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NpcSpeechBubble"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(252, 102)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.0, 0)
	gui.MaxDistance = maxDist + 6
	gui.AlwaysOnTop = true
	gui.Enabled = false

	local frame = Instance.new("Frame")
	frame.Visible = false
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = accent
	frame.BorderSizePixel = 0
	Art.panel(frame, accent)
	frame.Parent = gui

	local icon = Instance.new("Frame")
	icon.Position = UDim2.fromOffset(10, 8)
	icon.Size = UDim2.fromOffset(34, 34)
	icon.BackgroundColor3 = Theme.cream
	icon.BorderSizePixel = 0
	icon.ZIndex = 2
	Theme.corner(icon, 17)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Theme.outline
	iconStroke.Thickness = 2
	iconStroke.Parent = icon
	local glyph = Panel.label(icon, glyphChar, 21, Theme.ink)
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.TextScaled = true
	glyph.TextStrokeTransparency = 1
	glyph.ZIndex = 3
	icon.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -60, 0, 20)
	nameLabel.Position = UDim2.fromOffset(52, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = titleText
	nameLabel.Font = Theme.font
	nameLabel.TextSize = 15
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Theme.ink
	nameLabel.TextStrokeTransparency = 1
	nameLabel.ZIndex = 2
	nameLabel.Parent = frame

	local line = Instance.new("TextLabel")
	line.Size = UDim2.new(1, -24, 1, -48)
	line.Position = UDim2.fromOffset(12, 44)
	line.BackgroundTransparency = 1
	line.TextWrapped = true
	line.TextScaled = true
	line.Font = Theme.font
	line.TextColor3 = Theme.ink
	line.TextStrokeTransparency = 1
	line.TextXAlignment = Enum.TextXAlignment.Center
	line.TextYAlignment = Enum.TextYAlignment.Center
	line.ZIndex = 2
	line.Parent = frame
	local maxSize = Instance.new("UITextSizeConstraint")
	maxSize.MaxTextSize = 17
	maxSize.Parent = line

	gui.Parent = player:WaitForChild("PlayerGui")
	return gui, line, frame
end

local function mountBubbleLoop(npc: AnimatedNpc)
	local anchor = npc.speechPoint
	local lines = npc.lines
	if not (anchor and lines and #lines > 0) then
		return
	end
	local gui, label, frame = buildSpeechBubble(
		anchor,
		npc.displayName or "",
		npc.accent or Theme.crystal,
		npc.iconGlyph or "💬",
		npc.talkRadius
	)
	local setBubbleVisible = Hud.bindFishingVisibility(frame, false)
	local lineIndex = 0
	local bubbleOpen = false
	local lastSwap = 0

	task.spawn(function()
		while gui.Parent and anchor.Parent do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local near = Hud.panel() == ""
				and not Hud.isFishingActive()
				and root
				and root:IsA("BasePart")
				and (root.Position - anchor.WorldPosition).Magnitude <= npc.talkRadius
			if near then
				if not bubbleOpen then
					lineIndex = (lineIndex % #lines) + 1
					label.Text = lines[lineIndex]
					lastSwap = os.clock()
					bubbleOpen = true
					setBubbleVisible(true)
					gui.Enabled = true
				elseif os.clock() - lastSwap >= 9 then
					lineIndex = (lineIndex % #lines) + 1
					label.Text = lines[lineIndex]
					lastSwap = os.clock()
				end
			elseif bubbleOpen then
				bubbleOpen = false
				setBubbleVisible(false)
				task.delay(0.2, function()
					if not bubbleOpen and gui.Parent then
						gui.Enabled = false
					end
				end)
			end
			task.wait(0.35)
		end
		gui:Destroy()
	end)
end

local function applyNpcRestPose(npc: AnimatedNpc)
	npc.currentYaw = 0
	for _, entry in npc.torsoParts do
		if entry.part.Parent then
			entry.part.CFrame = npc.torsoRoot * entry.offset
		end
	end
	for _, entry in npc.headParts do
		if entry.part.Parent then
			entry.part.CFrame = npc.headRoot * entry.offset
		end
	end
end

local function stepNpc(npc: AnimatedNpc, t: number, dt: number, playerPos: Vector3?)
	local breathY = math.sin(t * 2.1 + npc.phase) * 0.045
	local swayZ = math.sin(t * 1.05 + npc.phase) * 0.025
	local torsoCF = npc.torsoRoot * CFrame.new(0, breathY, 0) * CFrame.Angles(0, 0, swayZ)
	for _, entry in npc.torsoParts do
		if entry.part.Parent then
			entry.part.CFrame = torsoCF * entry.offset
		end
	end

	local targetYaw = 0
	if playerPos then
		local toPlayer = playerPos - npc.headRoot.Position
		local flat = Vector3.new(toPlayer.X, 0, toPlayer.Z)
		if flat.Magnitude > 0.5 and flat.Magnitude <= npc.lookRadius then
			local dir = flat.Unit
			local fwd = npc.headForward
			local dot = math.clamp(fwd:Dot(dir), -1, 1)
			local crossY = fwd.Z * dir.X - fwd.X * dir.Z
			local rawAngle = math.atan2(crossY, dot)
			targetYaw = math.clamp(rawAngle, -math.rad(42), math.rad(42))
		end
	end

	local blend = math.min(1, dt * 6)
	npc.currentYaw += (targetYaw - npc.currentYaw) * blend

	local headCF = CFrame.new(npc.headRoot.Position + Vector3.new(0, breathY * 0.9, 0))
		* CFrame.Angles(0, npc.currentYaw, 0)
		* npc.headRoot.Rotation
	for _, entry in npc.headParts do
		if entry.part.Parent then
			entry.part.CFrame = headCF * entry.offset
		end
	end
end

function LivingWorld.start()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end

	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "LivingWorldNPCs"
	npcFolder.Parent = Workspace

	local lanterns: { LanternTarget } = {}
	local seenLanterns: { [BasePart]: boolean } = {}
	local campfireEmitters: { ParticleEmitter } = {}
	local seenEmitters: { [ParticleEmitter]: boolean } = {}
	local campfireMounted = false
	local guideBound = false
	local npcs: { AnimatedNpc } = {}

	local function scanIsland(islandInst: Instance?)
		if not islandInst then
			return
		end
		local reduced = player:GetAttribute("ReduceEffects") == true
		for _, desc in islandInst:GetDescendants() do
			if desc:IsA("ParticleEmitter") and not seenEmitters[desc] then
				seenEmitters[desc] = true
				desc.Enabled = not reduced
				table.insert(campfireEmitters, desc)
			end
		end
		for _, item in collectLanterns(islandInst) do
			if not seenLanterns[item.part] then
				seenLanterns[item.part] = true
				table.insert(lanterns, item)
			end
		end
		if not campfireMounted then
			local mounted = mountCampfireEmitters(islandInst)
			if #mounted > 0 then
				campfireMounted = true
				for _, em in mounted do
					if not seenEmitters[em] then
						seenEmitters[em] = true
						em.Enabled = not reduced
						table.insert(campfireEmitters, em)
					end
				end
			end
		end
		if not guideBound then
			local guideInst = islandInst:FindFirstChild("GuideNPC")
			if guideInst then
				local bound = bindGuideNpc(guideInst)
				if bound then
					guideBound = true
					table.insert(npcs, bound)
				end
			end
		end
	end

	local initialIsland = Workspace:FindFirstChild("Island") or Workspace:WaitForChild("Island", 8)
	scanIsland(initialIsland)
	if initialIsland then
		initialIsland.DescendantAdded:Connect(function(desc)
			if
				desc.Name == "Embers"
				or desc.Name == "GuideNPC"
				or desc.Name == "LightSource"
				or desc.Name == "LanternLight"
				or desc:IsA("ParticleEmitter")
			then
				task.defer(scanIsland, initialIsland)
			end
		end)
		task.delay(1.5, scanIsland, initialIsland)
	end
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Island" then
			task.defer(scanIsland, child)
		end
	end)

	-- 2 new stylized NPCs: Marina on the pier, Luna on the seaside FrontStairs landing
	local vendorNpc = buildCustomNpc(npcFolder, {
		name = "NPC_BaitVendor",
		cf = CFrame.lookAt(Vector3.new(31, 10.15, 2.8), Vector3.new(31, 10.15, 10)),
		shirt = Color3.fromRGB(248, 240, 224),
		vest = Theme.rose,
		pants = Color3.fromRGB(48, 76, 114),
		skin = Color3.fromRGB(252, 212, 182),
		hair = Color3.fromRGB(98, 58, 42),
		hatColor = Theme.crystal,
		hatBand = Theme.gold,
		propColor = Color3.fromRGB(164, 104, 62),
		lines = Strings.npcLines.baitVendor,
		displayName = Strings.npcLines.baitVendorName,
		accent = Theme.crystal,
		iconGlyph = "🪱",
		phase = 1.4,
		isVendor = true,
	})
	table.insert(npcs, vendorNpc)
	mountBubbleLoop(vendorNpc)

	local shellNpc = buildCustomNpc(npcFolder, {
		name = "NPC_ShellGirl",
		cf = CFrame.lookAt(Vector3.new(-10.8, 1.35, 53.5), Vector3.new(-4, 1.35, 48)),
		shirt = Color3.fromRGB(216, 186, 255),
		vest = Color3.fromRGB(255, 220, 148),
		pants = Color3.fromRGB(86, 152, 198),
		skin = Color3.fromRGB(246, 200, 170),
		hair = Color3.fromRGB(54, 42, 66),
		hatColor = Color3.fromRGB(244, 218, 168),
		hatBand = Theme.rose,
		propColor = Color3.fromRGB(194, 142, 92),
		lines = Strings.npcLines.shellGirl,
		displayName = Strings.npcLines.shellGirlName,
		accent = Theme.rose,
		iconGlyph = "🐚",
		phase = 2.9,
		isVendor = false,
	})
	table.insert(npcs, shellNpc)
	mountBubbleLoop(shellNpc)

	local lastAtmUpdate = 0
	local lastNpcUpdate = 0

	local function applyLightingAndLanterns()
		local clock = Lighting.ClockTime
		local frame = sampleSky(clock)
		local eventId = ReplicatedStorage:GetAttribute(EventsConfig.ACTIVE_ATTRIBUTE)
		local reduced = player:GetAttribute("ReduceEffects") == true
		local isStorm = eventId == "thunderStorm" and not reduced
		local isGolden = eventId == "goldenHour" and not reduced
		local isFog = eventId == "fogBank" and not reduced
		local isAurora = eventId == "aurora" and not reduced

		Lighting.Ambient = if isFog
			then frame.ambient:Lerp(Color3.fromRGB(165, 192, 215), 0.45)
			else frame.ambient
		Lighting.OutdoorAmbient = if isFog
			then frame.outdoor:Lerp(Color3.fromRGB(175, 200, 222), 0.4)
			else frame.outdoor
		Lighting.ColorShift_Top = if isAurora
			then frame.shiftTop:Lerp(Color3.fromRGB(110, 255, 218), 0.65)
			else frame.shiftTop
		Lighting.Brightness = frame.brightness
			* (if isStorm then 0.85 elseif isFog then 0.92 else 1.0)

		if atmosphere then
			local atmColor = frame.atmColor
			local atmDecay = frame.atmDecay
			local density = frame.density
			local glare = frame.glare
			local haze = frame.haze
			if isStorm then
				density += 0.07
			elseif isGolden then
				glare += 0.16
			elseif isFog then
				atmColor = atmColor:Lerp(Color3.fromRGB(190, 218, 238), 0.72)
				atmDecay = atmDecay:Lerp(Color3.fromRGB(140, 175, 205), 0.65)
				density += 0.24
				haze = math.min(10, haze + 4.5)
			elseif isAurora then
				atmColor = atmColor:Lerp(Color3.fromRGB(108, 245, 210), 0.55)
				atmDecay = atmDecay:Lerp(Color3.fromRGB(150, 120, 245), 0.5)
				glare += 0.2
			end
			atmosphere.Color = atmColor
			atmosphere.Decay = atmDecay
			atmosphere.Density = density
			atmosphere.Glare = glare
			atmosphere.Haze = haze
		end

		local nw = nightWeightFor(clock)
		local lanternColor = Color3.fromRGB(255, 196, 108)
		for _, item in lanterns do
			if item.light and item.light.Parent then
				item.light.Brightness = item.baseBrightness * (0.15 + 1.25 * nw)
				item.light.Color = lanternColor
			end
			if item.part.Parent then
				item.part.Color = item.dayColor:Lerp(lanternColor, 0.25 + 0.75 * nw)
			end
		end
	end

	local function syncReduceEffects()
		local reduced = player:GetAttribute("ReduceEffects") == true
		for _, em in campfireEmitters do
			if em.Parent then
				em.Enabled = not reduced
				if reduced then
					em:Clear()
				end
			end
		end
		if reduced then
			for _, npc in npcs do
				applyNpcRestPose(npc)
			end
		end
		applyLightingAndLanterns()
	end

	local heartbeatConn: RBXScriptConnection? = nil
	local reduceConn = player:GetAttributeChangedSignal("ReduceEffects"):Connect(syncReduceEffects)
	local eventConn = ReplicatedStorage:GetAttributeChangedSignal(EventsConfig.ACTIVE_ATTRIBUTE)
		:Connect(applyLightingAndLanterns)

	syncReduceEffects()

	heartbeatConn = RunService.Heartbeat:Connect(function()
		local t = os.clock()
		local reduced = player:GetAttribute("ReduceEffects") == true

		if t - lastAtmUpdate >= (if reduced then 1.0 else 0.25) then
			lastAtmUpdate = t
			applyLightingAndLanterns()
		end

		if not reduced and t - lastNpcUpdate >= 0.033 then
			local dt = t - lastNpcUpdate
			lastNpcUpdate = t
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local playerPos = if root and root:IsA("BasePart") then root.Position else nil
			for _, npc in npcs do
				if not playerPos or (npc.torsoRoot.Position - playerPos).Magnitude <= 95 then
					stepNpc(npc, t, dt, playerPos)
				end
			end
		end
	end)

	npcFolder.Destroying:Once(function()
		if heartbeatConn then
			heartbeatConn:Disconnect()
			heartbeatConn = nil
		end
		reduceConn:Disconnect()
		eventConn:Disconnect()
	end)
end

return LivingWorld
