--!strict
-- MapPerfOptimizer.luau
-- Safe, idempotent mobile performance pass for the saved place (Edit mode).
-- Disables CanTouch, CanQuery, and unnecessary CastShadow on non-collidable decorative
-- map parts while preserving every contract tag, trigger, prompt, SurfaceGui, and visual shadow.
--
-- Usage (Edit mode):
--   local Opt = require(game.ServerStorage.DevTools.MapPerfOptimizer:Clone())
--   print(Opt.run())

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local Optimizer = {}

local PROTECTED_TAGS = {
	"ZonePortal",
	"ZoneSpawn",
	"TrainingSpot",
	"WorkshopSpot",
	"TrophyPedestal",
	"PlayerSpawn",
	"OceanEventScenery",
	"OceanEventSceneryZone",
	"LeaderboardBoard",
	"TrainingPortalGuide",
}

local NO_SHADOW_ANCESTORS: { [string]: boolean } = {
	CloudSea = true,
	Rock = true,
	RockCrystals = true,
	Aurora = true,
	OrbitRing = true,
	GrassPatches = true,
	Scatter = true,
	CanalsAndFalls = true,
	Fireflies = true,
	LegendaryFish = true,
	MysteryFish = true,
}

local NO_SHADOW_PREFIXES = {
	"Cloud",
	"Rock",
	"Cliff",
	"Water",
	"Ripple",
	"Caustic",
	"Grass",
	"Flower",
	"Petal",
	"FallenPetal",
	"Star",
	"Orbit",
	"Coral",
	"Anemone",
	"Fish",
	"Jelly",
	"Tent_",
	"Foam",
	"Mist",
	"Bubble",
	"Rune",
	"Pebble",
	"Sparkle",
	"Glow",
	"Halo",
	"Beam",
	"Feather",
	"Firefly",
	"Vortex",
	"Seaweed",
	"Shell",
	"Starfish",
	"Hex",
	"Spiral",
	"Galaxy",
	"Nebula",
	"CanopyCrystal",
}

local function isProtected(part: BasePart): boolean
	for _, tag in PROTECTED_TAGS do
		if CollectionService:HasTag(part, tag) then
			return true
		end
	end
	for _, child in part:GetChildren() do
		if
			child:IsA("ProximityPrompt")
			or child:IsA("ClickDetector")
			or child:IsA("SurfaceGui")
		then
			return true
		end
	end
	return false
end

local function shouldDisableShadow(part: BasePart): boolean
	if not part.CastShadow then
		return false
	end
	if
		part.Transparency > 0.05
		or part.Material == Enum.Material.Neon
		or part.Material == Enum.Material.Glass
		or part.Material == Enum.Material.ForceField
	then
		return true
	end
	local p: Instance? = part.Parent
	while p and p ~= Workspace do
		if NO_SHADOW_ANCESTORS[p.Name] then
			return true
		end
		p = p.Parent
	end
	local name = part.Name
	for _, prefix in NO_SHADOW_PREFIXES do
		if string.sub(name, 1, #prefix) == prefix then
			return true
		end
	end
	if not part.CanCollide then
		local maxDim = math.max(part.Size.X, part.Size.Y, part.Size.Z)
		if maxDim <= 4.5 then
			return true
		end
	end
	return false
end

type AreaStats = {
	parts: number,
	collidable: number,
	touchBefore: number,
	touchAfter: number,
	queryBefore: number,
	queryAfter: number,
	shadowBefore: number,
	shadowAfter: number,
	unanchoredFixed: number,
}

local function optimizeContainer(container: Instance, dryRun: boolean): AreaStats
	local stats: AreaStats = {
		parts = 0,
		collidable = 0,
		touchBefore = 0,
		touchAfter = 0,
		queryBefore = 0,
		queryAfter = 0,
		shadowBefore = 0,
		shadowAfter = 0,
		unanchoredFixed = 0,
	}

	local processed = 0
	for _, desc in container:GetDescendants() do
		if desc:IsA("BasePart") then
			stats.parts += 1
			if desc.CanCollide then
				stats.collidable += 1
			end
			if desc.CanTouch then
				stats.touchBefore += 1
			end
			if desc.CanQuery then
				stats.queryBefore += 1
			end
			if desc.CastShadow then
				stats.shadowBefore += 1
			end

			local protected = isProtected(desc)
			if not desc.Anchored then
				stats.unanchoredFixed += 1
				if not dryRun then
					desc.Anchored = true
				end
			end

			if not desc.CanCollide and not protected then
				if desc.CanTouch and not dryRun then
					desc.CanTouch = false
				end
				if desc.CanQuery and not dryRun then
					desc.CanQuery = false
				end
			end

			if shouldDisableShadow(desc) and not protected then
				if not dryRun then
					desc.CastShadow = false
				end
			end

			if dryRun then
				if desc.CanTouch and (desc.CanCollide or protected) then
					stats.touchAfter += 1
				end
				if desc.CanQuery and (desc.CanCollide or protected) then
					stats.queryAfter += 1
				end
				if desc.CastShadow and (protected or not shouldDisableShadow(desc)) then
					stats.shadowAfter += 1
				end
			else
				if desc.CanTouch then
					stats.touchAfter += 1
				end
				if desc.CanQuery then
					stats.queryAfter += 1
				end
				if desc.CastShadow then
					stats.shadowAfter += 1
				end
			end

			processed += 1
			if processed % 1500 == 0 then
				task.wait()
			end
		end
	end

	return stats
end

function Optimizer.run(dryRun: boolean?): string
	local dry = dryRun == true
	local report: { [string]: AreaStats } = {}

	local island = Workspace:FindFirstChild("Island")
	if island then
		report["Island"] = optimizeContainer(island, dry)
	end

	local ti = Workspace:FindFirstChild("TrainingIslands")
	if ti then
		for _, child in ti:GetChildren() do
			report["TrainingIslands." .. child.Name] = optimizeContainer(child, dry)
		end
	end

	local exp = Workspace:FindFirstChild("ExpeditionIslands")
	if exp then
		report["ExpeditionIslands"] = optimizeContainer(exp, dry)
	end

	return HttpService:JSONEncode({
		dryRun = dry,
		areas = report,
	})
end

return Optimizer
