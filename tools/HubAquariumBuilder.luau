--!strict
-- Hub aquarium builder (Studio, Edit mode, run via execute_luau or the command bar).
-- Idempotent: removes everything it built before (attribute GeneratedBy) and builds again.
-- What was applied in the place (v87) also included one-off fixes documented in
-- docs/AQUARIO-ARTE-STATUS.md (decor moved out of the level 4 footprint, training deck lift).
--   * a wooden platform per aquarium level (deck, raised rim, pilings to the sea floor,
--     railing on back/sides, open front), stored INSIDE each level model as
--     Layer_00_Platform so a level swap also swaps the platform
--   * installs level 1 in the hub (Workspace.Island.AquariumNursery) at ORIGIN
--   * a stone path from the plaza to the platform front, following the terrain
-- Guidance used: fwjelaa vault, "World Composition and Set Dressing" (grounded props, clear
-- approach, made things aligned) and "Level of Detail and Model Streaming" (coplanar faces
-- z-fight: every stacked surface here is offset by at least 0.05 studs).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TAG_BUILT = "HubAquariumBuilder"
-- Final spot (2026-11-22): south-west point of the hub, over the water. 10.4 keeps every deck
-- at least 0.35 above the terrain (at 10.0 the grass came through the level 3-4 decks), and the
-- level 4 footprint clears the lagoon rocks and the floating leaderboard.
local ORIGIN = CFrame.new(-40, 10.4, 47.5) * CFrame.Angles(0, math.rad(90), 0)

-- Platform per level, in the level's local frame (origin = AquariumOrigin, front = +Z).
local SPECS = {
	[1] = { halfX = 12, back = -12, front = 9 },
	[2] = { halfX = 16, back = -15, front = 10 },
	[3] = { halfX = 22, back = -20, front = 12 },
	[4] = { halfX = 28.5, back = -26, front = 14 },
}

local WOOD = Color3.fromRGB(160, 112, 70)
local WOOD_DARK = Color3.fromRGB(104, 70, 42)
local WOOD_RIM = Color3.fromRGB(128, 86, 52)
local DECK_TOP = -0.05 -- below the origin so no tank face is coplanar with the deck
local DECK_T = 1
local RIM_UP = 0.18 -- rim stands proud of the deck (never coplanar)

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
terrainOnly.IgnoreWater = true

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.WoodPlanks
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Builds the platform for one level at a WORLD origin (pilings need the real terrain).
local function buildPlatform(levelIndex: number, origin: CFrame): Model
	local s = SPECS[levelIndex]
	local model = Instance.new("Model")
	model.Name = "Layer_00_Platform"
	model:SetAttribute("GeneratedBy", TAG_BUILT)
	local w, d = s.halfX * 2, s.front - s.back
	local zc = (s.front + s.back) / 2
	local deckY = DECK_TOP - DECK_T / 2
	part(model, "Deck", Vector3.new(w, DECK_T, d), origin * CFrame.new(0, deckY, zc), WOOD)
	-- raised rim on back and sides (front stays flush so it is walkable)
	local rimH = 0.5
	local rimY = DECK_TOP + RIM_UP - rimH / 2 + 0.25
	part(
		model,
		"RimBack",
		Vector3.new(w, rimH, 0.8),
		origin * CFrame.new(0, rimY, s.back + 0.4),
		WOOD_RIM
	)
	-- side rims start where the back rim ends, so no two rims overlap (overlap = z-fight)
	part(
		model,
		"RimLeft",
		Vector3.new(0.8, rimH, d - 0.8),
		origin * CFrame.new(-s.halfX + 0.4, rimY, zc + 0.4),
		WOOD_RIM
	)
	part(
		model,
		"RimRight",
		Vector3.new(0.8, rimH, d - 0.8),
		origin * CFrame.new(s.halfX - 0.4, rimY, zc + 0.4),
		WOOD_RIM
	)
	-- front fascia: a thin board under the front edge, recessed so it is never coplanar
	part(
		model,
		"FrontFascia",
		Vector3.new(w - 0.2, DECK_T + 0.6, 0.4),
		origin * CFrame.new(0, deckY - 0.35, s.front + 0.15),
		WOOD_DARK
	)
	-- railing: posts every ~6 studs on back and sides, top rail
	local postH, railY = 3.15, DECK_TOP + 3 -- post tops end inside the rail
	local function post(x: number, z: number)
		part(
			model,
			"RailPost",
			Vector3.new(0.6, postH, 0.6),
			origin * CFrame.new(x, DECK_TOP + postH / 2 + 0.01, z),
			WOOD_DARK
		)
	end
	local nx = math.max(2, math.floor(w / 6) + 1)
	for i = 0, nx - 1 do
		post(-s.halfX + 0.4 + (w - 0.8) * i / (nx - 1), s.back + 0.4)
	end
	local nz = math.max(2, math.floor(d / 6) + 1)
	for i = 1, nz - 1 do
		local z = s.back + 0.4 + (d - 1.2) * i / (nz - 1)
		post(-s.halfX + 0.4, z)
		post(s.halfX - 0.4, z)
	end
	part(
		model,
		"RailBack",
		Vector3.new(w, 0.35, 0.45),
		origin * CFrame.new(0, railY + 0.18, s.back + 0.4),
		WOOD
	)
	-- side rails start after the back rail (no overlapping coplanar tops)
	local sideLen = d - 1.1
	local sideZ = (s.back + 0.7 + s.front - 0.4) / 2
	part(
		model,
		"RailLeft",
		Vector3.new(0.45, 0.35, sideLen),
		origin * CFrame.new(-s.halfX + 0.4, railY + 0.18, sideZ),
		WOOD
	)
	part(
		model,
		"RailRight",
		Vector3.new(0.45, 0.35, sideLen),
		origin * CFrame.new(s.halfX - 0.4, railY + 0.18, sideZ),
		WOOD
	)
	-- pilings on a grid, down to the sea floor / ground (skipped where the ground is right under the deck)
	local bottom = DECK_TOP - DECK_T
	local step = 7
	local xs, zs = {}, {}
	for x = -s.halfX + 1, s.halfX - 1, (w - 2) / math.max(1, math.floor((w - 2) / step)) do
		table.insert(xs, x)
	end
	for z = s.back + 1, s.front - 1, (d - 2) / math.max(1, math.floor((d - 2) / step)) do
		table.insert(zs, z)
	end
	for _, x in xs do
		for _, z in zs do
			local top = (origin * CFrame.new(x, bottom + 0.3, z)).Position -- sinks into the deck
			local hit = workspace:Raycast(top, Vector3.new(0, -60, 0), terrainOnly)
			local floorY = if hit then hit.Position.Y - 1.5 else top.Y - 14
			local len = top.Y - floorY
			if len > 1.2 then
				local cyl = part(
					model,
					"Piling",
					Vector3.new(len, 1.4, 1.4),
					CFrame.new(top.X, (top.Y + floorY) / 2, top.Z)
						* CFrame.Angles(0, 0, math.rad(90)),
					WOOD_DARK
				)
				cyl.Shape = Enum.PartType.Cylinder
			end
		end
	end
	model.WorldPivot = origin
	return model
end

-- Re-expresses a platform built at `fromOrigin` relative to `toOrigin` (for the kit copies).
local function moveTo(model: Model, fromOrigin: CFrame, toOrigin: CFrame)
	model:PivotTo(toOrigin * fromOrigin:Inverse() * model:GetPivot())
end

local function clearBuilt(root: Instance)
	for _, d in root:GetDescendants() do
		if d:GetAttribute("GeneratedBy") == TAG_BUILT then
			d:Destroy()
		end
	end
end

local COBBLE = Color3.new(0.698, 0.635, 0.612) -- matches CentralPlaza.PlazaPaving

local function slab(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	width: number,
	thick: number,
	color: Color3,
	material: Enum.Material,
	extra: number?
): Part
	local p = part(
		parent,
		name,
		Vector3.new(width, thick, (b - a).Magnitude + (extra or 0.6)),
		CFrame.new(),
		color,
		material
	)
	p.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -thick / 2, 0)
	return p
end

local function groundY(x: number, z: number): number
	local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -100, 0), terrainOnly)
	return if hit then hit.Position.Y else -50
end

-- Cobblestone path from the plaza to the deck shoulder, kept above the terrain everywhere
-- (alternate segments 0.02 apart so joints never share a plane).
local PATH = {
	Vector2.new(-19, 19),
	Vector2.new(-22, 24.5),
	Vector2.new(-23.5, 30.5),
	Vector2.new(-24, 36),
	Vector2.new(-24.2, 43.2), -- ends east of every deck front; ramps leave from here at z = 41
}

local function buildPath(island: Instance): (Model, Vector3)
	local model = Instance.new("Model")
	model.Name = "AquariumPath"
	model:SetAttribute("GeneratedBy", TAG_BUILT)
	local tops = {}
	for i, p in PATH do
		local m = -50
		for _, dx in { -2.8, 0, 2.8 } do
			for _, dz in { -1.5, 0, 1.5 } do
				m = math.max(m, groundY(p.X + dx, p.Y + dz))
			end
		end
		tops[i] = (if i == 1 then math.max(m, 10.3) else m) + 0.12
	end
	for i = 1, #PATH - 1 do
		for t = 0.25, 0.75, 0.25 do
			local q = PATH[i]:Lerp(PATH[i + 1], t)
			local need = -50
			for _, dx in { -2.8, 0, 2.8 } do
				need = math.max(need, groundY(q.X + dx, q.Y))
			end
			local h = tops[i] + (tops[i + 1] - tops[i]) * t
			if h < need + 0.1 then
				tops[i] += need + 0.1 - h
				tops[i + 1] += need + 0.1 - h
			end
		end
	end
	for i = 1, #PATH - 1 do
		local lift = (i % 2) * 0.02
		slab(
			model,
			"PathStone",
			Vector3.new(PATH[i].X, tops[i] + lift, PATH[i].Y),
			Vector3.new(PATH[i + 1].X, tops[i + 1] + lift, PATH[i + 1].Y),
			6,
			0.8,
			COBBLE,
			Enum.Material.Cobblestone
		)
	end
	model.Parent = island
	local last = PATH[#PATH]
	return model, Vector3.new(last.X, tops[#PATH] + 0.04, last.Y)
end

-- Ramp per level, perpendicular to that deck's front (the deck faces +X), from the path end at
-- z = 41 to just past the front fascia, top flush with the deck. A run shorter than 2.5x the
-- rise (level 4) becomes solid steps instead. Fixed 2026-11-22: the first version copied the
-- level 1 ramp into level 2, so it crossed the bigger deck diagonally and ended under its edge.
local RAMP_Z = 41
local RAMP_START_X = -24.2

local function buildRamp(levelIndex: number, pathTop: number, origin: CFrame): Model
	local ramp = Instance.new("Model")
	ramp.Name = "Ramp"
	local frontX = (origin * CFrame.new(0, 0, SPECS[levelIndex].front)).Position.X + 0.37
	local deckTop = origin.Y + DECK_TOP
	local a = Vector3.new(
		RAMP_START_X + 1.2,
		math.max(groundY(RAMP_START_X, RAMP_Z), pathTop - 0.25) + 0.06,
		RAMP_Z
	)
	local b = Vector3.new(frontX, deckTop, RAMP_Z)
	local run, rise = math.abs(b.X - a.X), b.Y - a.Y
	if run / math.max(rise, 0.01) >= 2.5 then
		slab(ramp, "RampDeck", a, b, 5, 0.5, WOOD, Enum.Material.WoodPlanks, 0)
		for _, sgn in { -1, 1 } do
			local off = Vector3.new(0, -0.15, 2.65 * sgn)
			slab(
				ramp,
				"RampBeam",
				a + off,
				b + off,
				0.5,
				0.7,
				WOOD_DARK,
				Enum.Material.WoodPlanks,
				0
			)
		end
		for _, t in { 0.45, 0.9 } do
			local q = a:Lerp(b, t)
			for _, sgn in { -1, 1 } do
				local z = q.Z + 2.2 * sgn
				local g, topY = groundY(q.X, z), q.Y - 0.5
				if topY - g > 0.8 then
					local post = part(
						ramp,
						"RampPost",
						Vector3.new(topY - g + 1, 1, 1),
						CFrame.new(q.X, (topY + g - 1) / 2, z) * CFrame.Angles(0, 0, math.rad(90)),
						WOOD_DARK
					)
					post.Shape = Enum.PartType.Cylinder
				end
			end
		end
	else
		local n = math.max(2, math.ceil(rise / 0.45))
		local tread = run / n
		for k = 1, n do
			local topY = a.Y + rise * k / n
			local x0 = a.X - tread * (k - 1)
			local x1 = x0 - tread
			local h = topY - (groundY((x0 + x1) / 2, RAMP_Z) - 0.4)
			part(
				ramp,
				"Step",
				Vector3.new(tread + 0.02, h, 5),
				CFrame.new((x0 + x1) / 2, topY - h / 2 - (k % 2) * 0.01, RAMP_Z),
				if k % 2 == 0 then WOOD else Color3.fromRGB(150, 104, 64)
			)
		end
	end
	ramp.WorldPivot = origin
	return ramp
end

local Builder = {}

function Builder.run(): string
	local kit = ReplicatedStorage:WaitForChild("AquariumLevels"):WaitForChild("Levels")
	local island = workspace:WaitForChild("Island")
	clearBuilt(kit)
	clearBuilt(island)
	for _, old in { "AquariumNursery", "AquariumDeck" } do
		local m = island:FindFirstChild(old)
		if m then
			m:Destroy()
		end
	end

	local _, pathEnd = buildPath(island)
	local pathTop = pathEnd.Y - 0.04

	-- platforms for every level, built at the hub origin then copied into the kit level
	local levels: { [number]: Model } = {}
	for _, m in kit:GetChildren() do
		local index = m:GetAttribute("LevelIndex")
		if m:IsA("Model") and typeof(index) == "number" then
			levels[index] = m
		end
	end
	for index = 1, 4 do
		local level = levels[index]
		local platform = buildPlatform(index, ORIGIN)
		buildRamp(index, pathTop, ORIGIN).Parent = platform
		moveTo(platform, ORIGIN, (level:FindFirstChild("AquariumOrigin") :: BasePart).CFrame)
		platform.Parent = level
	end

	-- install level 1 in the world
	local src = levels[1]
	local tank = src:Clone()
	tank.Name = "AquariumNursery"
	tank:PivotTo(
		ORIGIN
			* (src:FindFirstChild("AquariumOrigin") :: BasePart).CFrame:Inverse()
			* tank:GetPivot()
	)
	tank.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	tank:SetAttribute("HubInstall", true)
	tank:SetAttribute("OriginCFrame", ORIGIN)
	CollectionService:AddTag(tank, "AquariumTank")
	local anchors = tank:FindFirstChild("Anchors") :: Folder
	local ip = anchors:FindFirstChild("InteractPoint") :: BasePart
	local spot = Instance.new("Part")
	spot.Name = "AquariumSpot"
	spot.Size = Vector3.new(6, 1, 6)
	spot.CFrame = CFrame.new(ip.Position.X, ORIGIN.Y + 0.2, ip.Position.Z)
	spot.Anchored = true
	spot.CanCollide = false
	spot.CanQuery = false
	spot.Transparency = 1
	spot.Parent = tank
	CollectionService:AddTag(spot, "AquariumSpot")
	tank.Parent = island
	-- After building, run tools/ZFightFixer.luau over each kit level and reinstall level 1.
	return "built path, 4 platforms with their own ramp/steps, installed level 1"
end

return Builder
