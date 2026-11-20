--!strict
-- Auras around Epic and Legendary creatures (reveal, photo mode, trophy...).
--   Epic: a small aura unique to each creature (its own colors and particle mood).
--   Legendary: the "maximum" aura: rotating rune ring under it, light pillar, orbiting
--   orbs, layered particles, pulsing light, and a signature touch per creature (arcs,
--   flames, petals, rainbow...).
-- The aura lives beside the model (same parent) and is removed when the model goes away.
-- "Reduce effects" keeps only a soft glow and a few particles. Client only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local CosmicOrbit = require(script:WaitForChild("CosmicOrbit"))

local CreatureAura = {
	attachOrbit = CosmicOrbit.attach,
}

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

-- mood: how the particles move. "rise" (embers/flames), "fall" (snow/petals/leaves),
-- "drift" (mist/nebula), "burst" (sparkles out), "bubble" (slow up, wobbly).
type Spec = {
	a: Color3,
	b: Color3,
	mood: string,
	texture: string?,
	arcs: boolean?, -- legendary: lightning arcs flicker around it
	rainbow: boolean?, -- legendary: the ring cycles through every hue
}

local SPECS: { [string]: Spec } = {
	-- Epic: small and unique.
	C09_Guardiao_Cristal = {
		a = Color3.fromRGB(120, 240, 255),
		b = Color3.fromRGB(200, 255, 255),
		mood = "burst",
	},
	C20_Raia_Vulcanica = {
		a = Color3.fromRGB(255, 120, 40),
		b = Color3.fromRGB(255, 220, 90),
		mood = "rise",
		texture = FIRE,
	},
	C21_Baleia_Nebulosa = {
		a = Color3.fromRGB(200, 120, 255),
		b = Color3.fromRGB(255, 160, 220),
		mood = "drift",
		texture = SMOKE,
	},
	C22_Serpente_Glacial = {
		a = Color3.fromRGB(210, 240, 255),
		b = Color3.fromRGB(150, 200, 255),
		mood = "fall",
	},
	C29_Dragao_Folha = {
		a = Color3.fromRGB(110, 230, 120),
		b = Color3.fromRGB(210, 255, 150),
		mood = "fall",
	},
	C33_Orca_Aurora = {
		a = Color3.fromRGB(90, 255, 180),
		b = Color3.fromRGB(200, 120, 255),
		mood = "drift",
		texture = SMOKE,
	},
	C56_Dragao_de_Coral = {
		a = Color3.fromRGB(255, 130, 160),
		b = Color3.fromRGB(255, 210, 170),
		mood = "bubble",
	},
	C57_Manta_Galactica = {
		a = Color3.fromRGB(120, 110, 255),
		b = Color3.fromRGB(255, 255, 255),
		mood = "burst",
	},
	C58_Tubarao_Fantasma = {
		a = Color3.fromRGB(200, 230, 255),
		b = Color3.fromRGB(150, 170, 210),
		mood = "drift",
		texture = SMOKE,
	},
	C59_Narval_Unicornio = {
		a = Color3.fromRGB(255, 180, 240),
		b = Color3.fromRGB(170, 230, 255),
		mood = "burst",
	},
	-- Legendary: maximum aura.
	C10_Leviata_Astral = {
		a = Color3.fromRGB(150, 120, 255),
		b = Color3.fromRGB(120, 230, 255),
		mood = "burst",
	},
	C23_Kraken_Trovejante = {
		a = Color3.fromRGB(150, 140, 255),
		b = Color3.fromRGB(255, 255, 160),
		mood = "drift",
		texture = SMOKE,
		arcs = true,
	},
	C24_Fenix_das_Mares = {
		a = Color3.fromRGB(80, 170, 255),
		b = Color3.fromRGB(190, 240, 255),
		mood = "rise",
		texture = FIRE,
	},
	C30_Tartaruga_Ilha = {
		a = Color3.fromRGB(255, 170, 210),
		b = Color3.fromRGB(255, 220, 120),
		mood = "fall",
	},
	C34_Serpente_Arco_Iris = {
		a = Color3.fromRGB(255, 120, 120),
		b = Color3.fromRGB(120, 200, 255),
		mood = "burst",
		rainbow = true,
	},
	C60_Hidra_das_Profundezas = {
		a = Color3.fromRGB(120, 255, 140),
		b = Color3.fromRGB(70, 60, 120),
		mood = "drift",
		texture = SMOKE,
		arcs = true,
	},
	C61_Baleia_Celestial = {
		a = Color3.fromRGB(110, 90, 255),
		b = Color3.fromRGB(255, 200, 255),
		mood = "burst",
		rainbow = true,
	},
	C62_Dragao_Dourado = {
		a = Color3.fromRGB(255, 210, 80),
		b = Color3.fromRGB(255, 255, 200),
		mood = "rise",
		arcs = true,
	},
	C63_Grifo_Marinho = {
		a = Color3.fromRGB(255, 245, 220),
		b = Color3.fromRGB(255, 200, 90),
		mood = "fall",
	},
	C64_Guardiao_Abissal = {
		a = Color3.fromRGB(60, 230, 220),
		b = Color3.fromRGB(40, 60, 140),
		mood = "rise",
		texture = SMOKE,
	},
}

-- Fallback per rarity for anything without a hand-made spec.
local FALLBACK: { [string]: Spec } = {
	Epic = { a = Color3.fromRGB(255, 100, 220), b = Color3.fromRGB(255, 200, 255), mood = "burst" },
	Legendary = {
		a = Color3.fromRGB(255, 205, 70),
		b = Color3.fromRGB(255, 255, 210),
		mood = "burst",
	},
}

local player = Players.LocalPlayer

type Live = {
	model: Model,
	folder: Folder,
	core: Attachment,
	ring: { BasePart },
	orbs: { BasePart },
	arcs: { Beam },
	light: PointLight,
	radius: number,
	drop: number, -- ring height below the center (half the creature height)
	rainbow: boolean,
	legendary: boolean,
	born: number,
}
local live: { Live } = {}
local loop: RBXScriptConnection? = nil

local function emitter(
	parent: Attachment,
	spec: Spec,
	rate: number,
	size: number,
	legendary: boolean
)
	local e = Instance.new("ParticleEmitter")
	e.Texture = spec.texture or SPARKLE
	e.Color = ColorSequence.new(spec.a, spec.b)
	e.LightEmission = 0.9
	e.LightInfluence = 0
	e.Rate = rate
	e.Lifetime = NumberRange.new(0.9, 1.8)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	local mood = spec.mood
	if mood == "rise" then
		e.EmissionDirection = Enum.NormalId.Top
		e.Speed = NumberRange.new(2, 4)
		e.SpreadAngle = Vector2.new(25, 25)
		e.Acceleration = Vector3.new(0, 2, 0)
	elseif mood == "fall" then
		e.EmissionDirection = Enum.NormalId.Top
		e.Speed = NumberRange.new(1, 2)
		e.SpreadAngle = Vector2.new(70, 70)
		e.Acceleration = Vector3.new(0, -3, 0)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-120, 120)
		e.Lifetime = NumberRange.new(1.6, 2.6)
	elseif mood == "drift" then
		e.Speed = NumberRange.new(0.3, 1)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Lifetime = NumberRange.new(1.8, 3)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.65),
			NumberSequenceKeypoint.new(1, 1),
		})
	elseif mood == "bubble" then
		e.EmissionDirection = Enum.NormalId.Top
		e.Speed = NumberRange.new(1, 2)
		e.SpreadAngle = Vector2.new(40, 40)
		e.Acceleration = Vector3.new(0, 1.5, 0)
	else -- burst
		e.Speed = NumberRange.new(1.5, 3.5)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Drag = 2
	end
	if legendary then
		e.Lifetime = NumberRange.new(e.Lifetime.Min * 1.3, e.Lifetime.Max * 1.3)
	end
	e.Parent = parent
end

local function neonPart(name: string, size: Vector3, color: Color3, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	if shape then
		p.Shape = shape
	end
	return p
end

local function step()
	local now = os.clock()
	for i = #live, 1, -1 do
		local aura = live[i]
		if not aura.model.Parent or not aura.core.Parent then
			aura.folder:Destroy()
			table.remove(live, i)
			continue
		end
		local t = now - aura.born
		local center = aura.core.WorldPosition
		-- Ring of runes turning slowly under the creature.
		for index, rune in aura.ring do
			local angle = t * 0.6 + index / #aura.ring * math.pi * 2
			rune.CFrame = CFrame.new(
				center
					+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * aura.radius * 1.15
					- Vector3.new(0, aura.drop, 0)
			) * CFrame.Angles(0, -angle, 0)
			if aura.rainbow then
				rune.Color = Color3.fromHSV((t * 0.25 + index / #aura.ring) % 1, 0.7, 1)
			end
		end
		-- Orbs orbiting on a tilted path.
		for index, orb in aura.orbs do
			local angle = -t * 1.4 + index / #aura.orbs * math.pi * 2
			local y = math.sin(angle * 2 + index) * aura.radius * 0.35
			orb.Position = center
				+ Vector3.new(math.cos(angle) * aura.radius, y, math.sin(angle) * aura.radius)
		end
		-- Lightning arcs flicker on and off.
		for _, arc in aura.arcs do
			arc.Enabled = math.random() < 0.35
			arc.CurveSize0 = math.random(-4, 4)
			arc.CurveSize1 = math.random(-4, 4)
		end
		-- Slow heartbeat light.
		local pulse = 0.5 + 0.5 * math.sin(t * (if aura.legendary then 3 else 2))
		aura.light.Brightness = (if aura.legendary then 2.2 else 1.2)
			+ pulse * (if aura.legendary then 2 else 0.8)
	end
	if #live == 0 and loop then
		loop:Disconnect()
		loop = nil
	end
end

-- Adds the aura to a creature model named by its id. Ignores creatures below Epic and
-- models inside ViewportFrames (particles and lights don't show there).
function CreatureAura.attach(model: Model)
	if not model.Parent or model:GetAttribute("HasAura") then
		return
	end
	local viewport = model:FindFirstAncestorWhichIsA("ViewportFrame")
	if model.Name == "C93_Ouroboros_Cosmico" then
		if viewport and viewport.Name ~= "ForegroundCreature" then
			return
		end
		model:SetAttribute("HasAura", true)
		CosmicOrbit.attach(model, player:GetAttribute("ReduceEffects") == true)
		return
	end
	local creature = Creatures.get(model.Name)
	if
		not creature
		or (
			creature.rarity ~= "Epic"
			and creature.rarity ~= "Legendary"
			and creature.rarity ~= "Mystic"
		)
	then
		return
	end
	if viewport then
		return
	end
	model:SetAttribute("HasAura", true)
	local legendary = creature.rarity == "Legendary" or creature.rarity == "Mystic"
	local spec = SPECS[model.Name] or FALLBACK[creature.rarity] or FALLBACK.Legendary
	local calm = player:GetAttribute("ReduceEffects") == true

	local box, size = model:GetBoundingBox()
	local radius = math.max(size.X, size.Z) * 0.5 + 0.6
	local folder = Instance.new("Folder")
	folder.Name = "CreatureAura"

	-- Invisible anchor at the model center; follows the model via a weld-free update.
	local anchorPart = neonPart("AuraCore", Vector3.new(0.2, 0.2, 0.2), spec.a)
	anchorPart.Transparency = 1
	anchorPart.CFrame = box
	anchorPart.Parent = folder
	local core = Instance.new("Attachment")
	core.Parent = anchorPart

	local light = Instance.new("PointLight")
	light.Color = spec.a
	light.Range = radius * (if legendary then 4 else 2.6)
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = anchorPart

	emitter(
		core,
		spec,
		if calm then 4 else (if legendary then 22 else 10),
		if legendary then 0.55 else 0.35,
		legendary
	)
	local ring: { BasePart } = {}
	local orbs: { BasePart } = {}
	local arcs: { Beam } = {}
	local pillarPart: BasePart? = nil
	if legendary and not calm then
		-- Second particle layer in the other color, bigger and slower.
		local swapped: Spec = { a = spec.b, b = spec.a, mood = "burst", texture = SPARKLE }
		emitter(core, swapped, 12, 1.5, true)
		-- Rune ring.
		for i = 1, 10 do
			local rune = neonPart(
				"Rune",
				Vector3.new(0.22, 0.22, radius * 0.6),
				if i % 2 == 0 then spec.a else spec.b
			)
			rune.Transparency = 0.15
			rune.Parent = folder
			table.insert(ring, rune)
		end
		-- Orbiting orbs.
		for i = 1, 6 do
			local orb = neonPart(
				"Orb",
				Vector3.new(0.35, 0.35, 0.35),
				if i % 2 == 0 then spec.a else spec.b,
				Enum.PartType.Ball
			)
			orb.Parent = folder
			table.insert(orbs, orb)
			local trailA = Instance.new("Attachment")
			trailA.Position = Vector3.new(0, 0.15, 0)
			trailA.Parent = orb
			local trailB = Instance.new("Attachment")
			trailB.Position = Vector3.new(0, -0.15, 0)
			trailB.Parent = orb
			local trail = Instance.new("Trail")
			trail.Attachment0 = trailA
			trail.Attachment1 = trailB
			trail.Color = ColorSequence.new(orb.Color)
			trail.LightEmission = 1
			trail.Lifetime = 0.35
			trail.Transparency = NumberSequence.new(0.2, 1)
			trail.Parent = orb
		end
		-- Light pillar straight up.
		local pillar = neonPart("Pillar", Vector3.new(radius * 0.35, 40, radius * 0.35), spec.b)
		pillar.Transparency = 0.7
		pillar.Parent = folder
		pillarPart = pillar
		-- Lightning arcs (storm legendaries).
		if spec.arcs then
			for i = 1, 4 do
				local from = Instance.new("Attachment")
				from.Position =
					Vector3.new(math.cos(i) * radius, size.Y * 0.4, math.sin(i) * radius)
				from.Parent = anchorPart
				local to = Instance.new("Attachment")
				to.Position =
					Vector3.new(-math.cos(i) * radius, -size.Y * 0.3, -math.sin(i) * radius)
				to.Parent = anchorPart
				local arc = Instance.new("Beam")
				arc.Attachment0 = from
				arc.Attachment1 = to
				arc.Color = ColorSequence.new(spec.b)
				arc.LightEmission = 1
				arc.Width0 = 0.18
				arc.Width1 = 0.05
				arc.Segments = 12
				arc.FaceCamera = true
				arc.Enabled = false
				arc.Parent = anchorPart
				table.insert(arcs, arc)
			end
		end
	end
	-- Beside the model, not inside: callers measure the model's bounding box.
	folder.Parent = model.Parent

	-- Keep the core on the model while it moves (reveal spin, photo mode).
	local followConn: RBXScriptConnection
	local offset = model:GetPivot():ToObjectSpace(box)
	followConn = RunService.RenderStepped:Connect(function()
		if not model.Parent or not anchorPart.Parent then
			followConn:Disconnect()
			return
		end
		anchorPart.CFrame = model:GetPivot() * offset
		local pillar = pillarPart
		if pillar then
			pillar.CFrame = CFrame.new(anchorPart.Position + Vector3.new(0, 20 + size.Y * 0.5, 0))
		end
	end)

	table.insert(live, {
		model = model,
		folder = folder,
		core = core,
		ring = ring,
		orbs = orbs,
		arcs = arcs,
		light = light,
		radius = radius,
		drop = size.Y * 0.5,
		rainbow = spec.rainbow == true,
		legendary = legendary,
		born = os.clock(),
	})
	if not loop then
		loop = RunService.RenderStepped:Connect(step)
	end
end

return CreatureAura
