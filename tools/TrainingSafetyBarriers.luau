--!strict
-- TrainingSafetyBarriers.luau
-- Adds invisible perimeter safety barriers around Training Islands 1-3 (Edit mode)
-- so players cannot accidentally walk off into the ocean where there is no ladder back up.
-- Safe to run multiple times (replaces existing SafetyBarrier folder on each island).
-- Island 4 (Celestial) builds its own perimeter barrier in TrainingIsland4Builder.
--
-- Usage (Edit mode):
--   local B = require(game.ServerStorage.DevTools.TrainingSafetyBarriers:Clone())
--   print(B.apply())

local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local Barriers = {}

local TAU = math.pi * 2

local function buildRingFromGround(island: Model): { count: number, avgR: number }
	local old = island:FindFirstChild("SafetyBarriers")
	if old then
		old:Destroy()
	end

	local centerPart = island.PrimaryPart or island:FindFirstChild("IslandCenter")
	local center = if centerPart and centerPart:IsA("BasePart")
		then centerPart.Position
		else island:GetPivot().Position

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { island }
	params.RespectCanCollide = true

	local segs = 36
	local radii: { number } = {}
	local sumR = 0

	-- Measure the exact outer walkable edge in 36 directions by probing inward from 65 studs.
	for i = 0, segs - 1 do
		local a = (i / segs) * TAU
		local ca, sa = math.cos(a), math.sin(a)
		local edgeR = 44
		for r = 64, 24, -1.5 do
			local probe = Vector3.new(center.X + ca * r, center.Y + 25, center.Z + sa * r)
			local hit = Workspace:Raycast(probe, Vector3.new(0, -35, 0), params)
			if hit and hit.Position.Y >= center.Y - 2.5 then
				edgeR = r + 0.6
				break
			end
		end
		radii[i + 1] = edgeR
		sumR += edgeR
	end

	local folder = Instance.new("Folder")
	folder.Name = "SafetyBarriers"

	for i = 1, segs do
		local j = (i % segs) + 1
		local a0 = ((i - 1) / segs) * TAU
		local a1 = ((j - 1) / segs) * TAU
		local p0 = Vector3.new(
			center.X + math.cos(a0) * radii[i],
			center.Y,
			center.Z + math.sin(a0) * radii[i]
		)
		local p1 = Vector3.new(
			center.X + math.cos(a1) * radii[j],
			center.Y,
			center.Z + math.sin(a1) * radii[j]
		)
		local diff = p1 - p0
		local len = diff.Magnitude + 0.8
		local mid = (p0 + p1) * 0.5 + Vector3.new(0, 7.5, 0)
		local wall = Instance.new("Part")
		wall.Name = "SafetyWall_" .. tostring(i)
		wall.Anchored = true
		wall.Transparency = 1
		wall.CanCollide = true
		wall.CanQuery = false
		wall.CanTouch = false
		wall.CastShadow = false
		wall.Size = Vector3.new(1.2, 15, len)
		wall.CFrame = CFrame.lookAt(mid, mid + diff.Unit)
		wall.Parent = folder
	end

	folder.Parent = island
	return { count = segs, avgR = math.floor((sumR / segs) * 10) / 10 }
end

function Barriers.apply(): string
	local ti = Workspace:FindFirstChild("TrainingIslands")
	if not ti then
		return HttpService:JSONEncode({ error = "Workspace.TrainingIslands missing" })
	end

	local targets = {
		"TrainingIsland_Apprentice",
		"TrainingIsland_Reef",
		"TrainingIsland_Abyss",
	}
	local result: { [string]: any } = {}
	for _, name in targets do
		local island = ti:FindFirstChild(name)
		if island and island:IsA("Model") then
			result[name] = buildRingFromGround(island)
		else
			result[name] = "missing"
		end
	end
	return HttpService:JSONEncode(result)
end

return Barriers
