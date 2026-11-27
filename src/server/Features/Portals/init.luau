--!strict
-- Server-authoritative zone portal teleportation.
-- Any BasePart tagged "ZonePortal" with attributes PortalId, ZoneId and Destination
-- receives a ProximityPrompt and Touched listener. The server validates player level
-- against Config/Zones, cancels active fishing/training, streams the destination area,
-- raycasts the landing floor and pivots the character with a small horizontal spread.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))
local Zones = require(Shared:WaitForChild("Config"):WaitForChild("Zones"))

local Features = script.Parent
local Fishing = require(Features:WaitForChild("Fishing"))
local PlayerData = require(Features:WaitForChild("PlayerData"))
local Training = require(Features:WaitForChild("Training"))
local Remotes = require(Features.Parent:WaitForChild("Remotes"))

local Portals = {}
Portals.order = 55

local PORTAL_TAG = "ZonePortal"
local SPAWN_TAG = "ZoneSpawn"
local TELEPORT_COOLDOWN = 2.0
local LOCKED_COOLDOWN = 2.2
local MAX_TRIGGER_DISTANCE = 18
local FALLBACK_MAIN_POS = Vector3.new(-6, 13.6, 16)

local effectRemote: RemoteEvent
local fishingUpdateRemote: RemoteEvent
local trainingUpdateRemote: RemoteEvent
local rng = Random.new()

local lastTeleport: { [Player]: number } = {}
local lastLockedNotice: { [Player]: number } = {}
local teleporting: { [Player]: boolean } = {}
local spawnCursor: { [string]: number } = {}

local function playerLevel(player: Player): number
	local profile = PlayerData.get(player)
	if profile then
		return profile.stats.level
	end
	local attr = player:GetAttribute("PlayerLevel")
	return if typeof(attr) == "number" then attr else 1
end

local function rootOf(player: Player): (Model?, BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return character, root, humanoid
	end
	return nil, nil, nil
end

local function resolveMainSpawn(): CFrame
	-- The hub tags its plaza spawn "PlayerSpawn"; fall back to the old hub layout.
	local spawnPart: Instance? = nil
	for _, tagged in CollectionService:GetTagged("PlayerSpawn") do
		if tagged:IsA("BasePart") and tagged:IsDescendantOf(Workspace) then
			spawnPart = tagged
			break
		end
	end
	if not spawnPart then
		local island = Workspace:FindFirstChild("Island")
		local plaza = island and island:FindFirstChild("CentralPlaza")
		spawnPart = plaza and plaza:FindFirstChild("PlayerSpawn")
	end
	if spawnPart and spawnPart:IsA("BasePart") then
		local pos = spawnPart.Position
		-- Face north (-Z) toward the central plaza & Workshop.
		return CFrame.lookAt(pos + Vector3.new(0, 3.2, 0), pos + Vector3.new(0, 3.2, -16))
	end
	return CFrame.lookAt(FALLBACK_MAIN_POS, FALLBACK_MAIN_POS + Vector3.new(0, 0, -16))
end

local function resolveDestination(destination: string): CFrame?
	if destination == "main" then
		return resolveMainSpawn()
	end
	local candidates: { BasePart } = {}
	for _, inst in CollectionService:GetTagged(SPAWN_TAG) do
		if inst:IsA("BasePart") and inst:GetAttribute("Destination") == destination then
			table.insert(candidates, inst)
		end
	end
	if #candidates == 0 then
		return nil
	end
	local idx = ((spawnCursor[destination] or 0) % #candidates) + 1
	spawnCursor[destination] = idx
	local chosen = candidates[idx]

	-- Verify solid floor beneath landing point via Raycast so player never clips or falls.
	local offset = Vector3.new(rng:NextNumber(-1.4, 1.4), 0, rng:NextNumber(-1.4, 1.4))
	local probeXZ = chosen.Position + offset
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = candidates :: { any }
	local hit = Workspace:Raycast(
		Vector3.new(probeXZ.X, chosen.Position.Y + 6, probeXZ.Z),
		Vector3.new(0, -24, 0),
		params
	)
	local groundY = if hit then hit.Position.Y else chosen.Position.Y
	local targetPos = Vector3.new(probeXZ.X, groundY + 3.2, probeXZ.Z)
	local lookDir = chosen.CFrame.LookVector
	local flatLook = Vector3.new(lookDir.X, 0, lookDir.Z)
	if flatLook.Magnitude < 0.01 then
		flatLook = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(targetPos, targetPos + flatLook.Unit)
end

local function tryUsePortal(player: Player, portalPart: BasePart)
	if teleporting[player] then
		return
	end
	local now = os.clock()
	if (lastTeleport[player] or 0) + TELEPORT_COOLDOWN > now then
		return
	end

	local character, root = rootOf(player)
	if not (character and root) then
		return
	end
	if (root.Position - portalPart.Position).Magnitude > MAX_TRIGGER_DISTANCE then
		return
	end

	local rawDest = portalPart:GetAttribute("Destination")
	local destination = if typeof(rawDest) == "string" then rawDest else ""
	if destination == "" then
		return
	end

	local rawZone = portalPart:GetAttribute("ZoneId")
	local zoneId = if typeof(rawZone) == "string" then rawZone else Zones.DEFAULT_ID

	-- Validate zone level and training island power requirements on the server (return to "main" is always allowed).
	if destination ~= "main" then
		local zone = Zones.get(zoneId)
		if zone and playerLevel(player) < zone.minLevel then
			if (lastLockedNotice[player] or 0) + LOCKED_COOLDOWN <= now then
				lastLockedNotice[player] = now
				fishingUpdateRemote:FireClient(
					player,
					{
						event = "rejected",
						reason = "levelLocked",
						zoneId = zone.id,
						minLevel = zone.minLevel,
					} :: Net.FishingUpdate
				)
			end
			return
		end
		local rawIsland = portalPart:GetAttribute(TrainingConfig.ISLAND_ATTRIBUTE)
		if typeof(rawIsland) == "number" and TrainingConfig.powerEnabled() then
			local island = TrainingConfig.islandIndex(rawIsland)
			if not TrainingConfig.islandAllowed(island, Training.powerSum(player)) then
				if (lastLockedNotice[player] or 0) + LOCKED_COOLDOWN <= now then
					lastLockedNotice[player] = now
					trainingUpdateRemote:FireClient(
						player,
						{
							event = "islandLocked",
							island = island,
							gate = TrainingConfig.ISLANDS[island].gate,
						} :: Net.TrainingUpdate
					)
				end
				return
			end
		end
	end

	local destCF = resolveDestination(destination)
	if not destCF then
		warn(`[Portals] no spawn destination found for "{destination}"`)
		return
	end

	teleporting[player] = true
	lastTeleport[player] = now

	-- Cancel any ongoing fishing or training session cleanly before moving the player.
	Fishing.cancelFor(player)
	Training.stopFor(player, "portal")

	local primaryColor = portalPart:GetAttribute("PrimaryColor")
	effectRemote:FireClient(player, {
		phase = "start",
		destination = destination,
		color = if typeof(primaryColor) == "Color3" then primaryColor else nil,
	})

	task.spawn(function()
		-- Brief fade-in window & stream request around the destination island.
		pcall(function()
			player:RequestStreamAroundAsync(destCF.Position)
		end)
		task.wait(0.16)

		local liveChar, liveRoot = rootOf(player)
		if liveChar and liveRoot then
			-- Re-verify floor in case StreamingEnabled just finished loading destination chunks.
			local refreshed = resolveDestination(destination)
			local finalCF = refreshed or destCF
			liveRoot.AssemblyLinearVelocity = Vector3.zero
			liveRoot.AssemblyAngularVelocity = Vector3.zero
			liveChar:PivotTo(finalCF)
		end

		if player.Parent then
			effectRemote:FireClient(player, {
				phase = "done",
				destination = destination,
			})
		end
		teleporting[player] = nil
	end)
end

local function hookPortal(inst: Instance)
	if not inst:IsA("BasePart") or inst:GetAttribute("PortalHooked") then
		return
	end
	inst:SetAttribute("PortalHooked", true)

	local rawDest = inst:GetAttribute("Destination")
	local destination = if typeof(rawDest) == "string" then rawDest else ""
	local rawZone = inst:GetAttribute("ZoneId")
	local zoneId = if typeof(rawZone) == "string" then rawZone else ""

	local existingPrompt = inst:FindFirstChild("UsePortal")
	local prompt: ProximityPrompt
	if existingPrompt and existingPrompt:IsA("ProximityPrompt") then
		prompt = existingPrompt
	else
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "UsePortal"
		prompt.ActionText = "Enter"
		prompt.ObjectText = if destination == "main"
			then "Main Island"
			else (Strings.zoneName[zoneId] or zoneId)
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = inst
	end

	prompt.Triggered:Connect(function(player: Player)
		tryUsePortal(player, inst)
	end)

	inst.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			tryUsePortal(player, inst)
		end
	end)
end

function Portals.start()
	effectRemote = Remotes.event(Net.PORTAL_EFFECT)
	fishingUpdateRemote = Remotes.event(Net.FISHING_UPDATE)
	trainingUpdateRemote = Remotes.event(Net.TRAINING_UPDATE)

	for _, inst in CollectionService:GetTagged(PORTAL_TAG) do
		hookPortal(inst)
	end
	CollectionService:GetInstanceAddedSignal(PORTAL_TAG):Connect(hookPortal)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastTeleport[player] = nil
		lastLockedNotice[player] = nil
		teleporting[player] = nil
	end)
end

return Portals
