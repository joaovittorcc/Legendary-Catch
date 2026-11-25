--!strict
-- HubMigration: makes hub V2 (HubBuilder_claude) the live hub, Workspace.Island at the origin.
--
-- Safe to run again: the old hub is archived (not deleted) the first time, and the pieces
-- that only exist in the old hub (functional aquarium, server trophy, guide NPC, ocean
-- event anchor) are cloned from that archive into every new build.
--
-- Usage (Studio command bar / MCP, Edit mode):
--   local DevTools = game.ServerStorage.DevTools
--   local Builder = require(DevTools.HubBuilder_claude:Clone())
--   local Migration = require(DevTools.HubMigration:Clone())
--   print(Migration.run(Builder))
--
-- Archived instances lose their CollectionService tags (kept in the "ArchivedTags"
-- attribute) so server systems that scan tags (ZoneSpawn, ZonePortal, TrophyPedestal...)
-- never pick an archived copy. Migration.restoreTags(instance) puts them back.

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local HUB_NAME = "Island"
local HUB_VERSION = 2
local OLD_HUB_ARCHIVE = "Archive_OldHub"
local OLD_ISLANDS_ARCHIVE = "Archive_OldIslands"
local OLD_HUB_NAME = "Island_OldHub"

-- Where the V2 test copy was built (its terrain is cleared).
local TEST_ORIGIN = Vector3.new(-700, 0, 700)
local TERRAIN_MIN = Vector3.new(-116, -20, -96)
local TERRAIN_MAX = Vector3.new(52, 64, 84)

-- V2 decorative tank pieces replaced by the functional nursery.
-- (the deck bench sits where the nursery's foundation goes).
local DECOR_TANK_PATTERNS = { "^Tank", "^Seaweed$", "^ToyFish", "^Jelly", "^AquariumBench" }

type Builder = {
	build: (origin: Vector3?, modelName: string?) -> Model,
	selfTest: (origin: Vector3?, modelName: string?) -> { string },
}

local Migration = {}

local function archiveFolder(name: string): Folder
	local existing = ServerStorage:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = ServerStorage
	return folder
end

local function stripTags(root: Instance)
	local list = root:GetDescendants()
	table.insert(list, root)
	for _, inst in list do
		local tags = inst:GetTags()
		if #tags > 0 then
			inst:SetAttribute("ArchivedTags", table.concat(tags, ","))
			for _, tag in tags do
				inst:RemoveTag(tag)
			end
		end
	end
end

function Migration.restoreTags(root: Instance)
	local list = root:GetDescendants()
	table.insert(list, root)
	for _, inst in list do
		local saved = inst:GetAttribute("ArchivedTags")
		if typeof(saved) == "string" then
			for tag in string.gmatch(saved, "[^,]+") do
				inst:AddTag(tag)
			end
			inst:SetAttribute("ArchivedTags", nil)
		end
	end
end

local function archive(inst: Instance, folder: Folder, newName: string?)
	stripTags(inst)
	if newName then
		inst.Name = newName
	end
	inst.Parent = folder
end

local function ensureModel(name: string): Model
	local existing = Workspace:FindFirstChild(name)
	if existing and existing:IsA("Model") then
		return existing
	end
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = Workspace
	return model
end

-- Clones an archived piece back to life (tags restored) under `parent`.
local function revive(source: Instance?, parent: Instance): Instance?
	if not source then
		return nil
	end
	local copy = source:Clone()
	Migration.restoreTags(copy)
	copy.Parent = parent
	return copy
end

local function matchesAny(name: string, patterns: { string }): boolean
	for _, pattern in patterns do
		if string.match(name, pattern) then
			return true
		end
	end
	return false
end

function Migration.run(Builder: Builder): { string }
	local log: { string } = {}
	local function note(msg: string)
		table.insert(log, msg)
	end

	local hubArchive = archiveFolder(OLD_HUB_ARCHIVE)

	-- 1. Retire the old hub once, keeping the expedition islands and world bounds alive.
	local current = Workspace:FindFirstChild(HUB_NAME)
	if current and current:GetAttribute("HubVersion") ~= HUB_VERSION then
		local expeditions = ensureModel("ExpeditionIslands")
		for _, name in { "CoralReefIsland", "StarAbyssIsland" } do
			local child = current:FindFirstChild(name)
			if child then
				child.Parent = expeditions
				note("kept " .. name .. " in Workspace.ExpeditionIslands")
			end
		end
		local bounds = ensureModel("WorldBounds")
		for _, name in { "OceanBounds", "Horizon" } do
			local child = current:FindFirstChild(name)
			if child then
				child.Parent = bounds
				note("kept " .. name .. " in Workspace.WorldBounds")
			end
		end
		local previous = hubArchive:FindFirstChild(OLD_HUB_NAME)
		if previous then
			previous.Name = OLD_HUB_NAME .. "_" .. os.time()
		end
		archive(current, hubArchive, OLD_HUB_NAME)
		note("archived old hub to ServerStorage." .. OLD_HUB_ARCHIVE .. "." .. OLD_HUB_NAME)
	end
	local oldHub = hubArchive:FindFirstChild(OLD_HUB_NAME)
	if not oldHub then
		note("WARNING: no archived old hub; aquarium/trophy/guide not transplanted")
	end

	-- 2. Retire old duplicates that now have a replacement (portal plaza next to the old
	--    hub, training islands 2 and 3 rebuilt in Workspace.TrainingIslands).
	local islandsArchive = archiveFolder(OLD_ISLANDS_ARCHIVE)
	local training = Workspace:FindFirstChild("TrainingIslands")
	local retire = {
		{ name = "TrainingPortalsHub", replacement = nil :: string? },
		{ name = "TrainingIsland_Reef", replacement = "TrainingIsland_Reef" :: string? },
		{ name = "TrainingIsland_Abyss", replacement = "TrainingIsland_Abyss" :: string? },
	}
	for _, item in retire do
		local inst = Workspace:FindFirstChild(item.name)
		local replaced = item.replacement == nil
			or (training ~= nil and training:FindFirstChild(item.replacement :: string) ~= nil)
		if inst and replaced then
			archive(inst, islandsArchive)
			note("archived " .. item.name .. " to ServerStorage." .. OLD_ISLANDS_ARCHIVE)
		end
	end

	-- 3. Drop the V2 test copy and its terrain.
	local test = Workspace:FindFirstChild("HubNew")
	if test then
		test:Destroy()
		local region = Region3.new(TEST_ORIGIN + TERRAIN_MIN, TEST_ORIGIN + TERRAIN_MAX)
			:ExpandToGrid(4)
		Workspace.Terrain:FillRegion(region, 4, Enum.Material.Air)
		note("removed HubNew test copy and its terrain")
	end

	-- 4. Build the live hub.
	local hub = Builder.build(Vector3.zero, HUB_NAME)
	hub:SetAttribute("HubVersion", HUB_VERSION)
	note(
		"built "
			.. HUB_NAME
			.. " at origin: "
			.. tostring(hub:GetAttribute("PartCount"))
			.. " parts"
	)

	-- 5. Transplant what only the old hub had.
	if oldHub then
		local aquariumGroup = hub:FindFirstChild("Aquarium") or hub
		local nursery = revive(oldHub:FindFirstChild("AquariumNursery"), aquariumGroup)
		if nursery then
			-- The V2 deck is the floor now; the old stilt platform would poke through it.
			local platform = nursery:FindFirstChild("Layer_00_Platform")
			if platform then
				platform:Destroy()
			end
			local removed = 0
			for _, child in aquariumGroup:GetChildren() do
				if child ~= nursery and matchesAny(child.Name, DECOR_TANK_PATTERNS) then
					child:Destroy()
					removed += 1
				end
			end
			note(
				"aquarium: functional nursery installed, "
					.. removed
					.. " decorative tank parts removed"
			)
		end

		if revive(oldHub:FindFirstChild("TrophyMonument"), hub) then
			note("trophy monument installed (best catch of the server)")
		end
		if revive(oldHub:FindFirstChild("GuideNPC"), hub) then
			note("guide NPC installed")
		end
		local oldPier = oldHub:FindFirstChild("FishingPier")
		local anchor = oldPier and oldPier:FindFirstChild("EventSceneryAnchor")
		local pier = hub:FindFirstChild("FishingPier") or hub
		if revive(anchor, pier) then
			note("ocean event scenery anchor installed on the pier")
		end
	end

	-- 6. Report the builder self test (contract positions, walkability...).
	local fails = Builder.selfTest(Vector3.zero, HUB_NAME)
	note("selfTest: " .. #fails .. " failures")
	for _, f in fails do
		note("  FAIL " .. f)
	end
	return log
end

-- Lists tagged instances still alive under Workspace per tag (quick sanity check).
function Migration.tagReport(tags: { string }): { string }
	local out: { string } = {}
	for _, tag in tags do
		local count = 0
		for _, inst in CollectionService:GetTagged(tag) do
			if inst:IsDescendantOf(Workspace) then
				count += 1
			end
		end
		table.insert(out, tag .. " = " .. count)
	end
	return out
end

return Migration
