--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AquariumConfig = require(Shared.Config.Aquarium)
local Creatures = require(Shared.Config.Creatures)
local Types = require(Shared.Types)
local Income = require(script.Parent.AquariumIncome)
local Tank = require(script.Parent.AquariumTank)

local World = {}
type Swimmer = {
	model: Model,
	volume: BasePart?,
	home: CFrame,
	scale: number,
	seed: number,
	linked: boolean,
	glow: Highlight?,
}
local function part(parent: Instance, name: string): BasePart?
	local value = parent:FindFirstChild(name, true)
	return if value and value:IsA("BasePart") then value else nil
end

local function prepare(model: Model, gold: boolean)
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") then
			child.Anchored = true
			child.CanCollide = false
			child.CanQuery = false
			child.CanTouch = false
			child.CastShadow = false
			if gold then
				child.Color = child.Color:Lerp(Color3.fromRGB(255, 198, 76), 0.65)
			end
		elseif child:IsA("ProximityPrompt") or child:IsA("BaseScript") then
			child:Destroy()
		end
	end
end

function World.displays(state: Types.AquariumSnapshot?): { Tank.Display }
	local displays: { Tank.Display } = {}
	local linked: { [string]: boolean } = {}
	for _, synergy in ipairs((state and state.synergies) or {}) do
		if synergy.active then
			for _, id in synergy.members do
				linked[id] = true
			end
		end
	end
	for _, slot in ipairs((state and state.slots) or {}) do
		local fish = slot.occupant
		local creature = fish and Creatures.get(fish.creatureId)
		if fish and creature then
			table.insert(displays, {
				slot = slot.index,
				creatureId = fish.creatureId,
				rarity = creature.rarity,
				large = fish.variant == "giant" or fish.variant == "both",
				gold = fish.variant == "gold" or fish.variant == "both",
				linked = linked[fish.creatureId] == true,
			})
		end
	end
	return displays
end

function World.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local state: Types.AquariumSnapshot? = nil
	local scene: Folder? = nil
	local labels: ScreenGui? = nil
	local signature = ""
	local base: Model? = nil
	local hidden: { [BasePart]: number } = {}
	local hiddenEffects: { [Instance]: boolean } = {}
	local swimmers: { Swimmer } = {}
	local anchors: { [number]: Attachment } = {}
	local focus: number? = nil
	local elapsed = 0
	local glowUntil = 0
	local time = 0
	local lastLevel: string? = nil
	local near = false

	local function clear()
		if labels then
			labels:Destroy()
		end
		if scene then
			scene:Destroy()
		end
		for piece, original in hidden do
			piece.LocalTransparencyModifier = original
		end
		for effect, enabled in hiddenEffects do
			if effect:IsA("ParticleEmitter") or effect:IsA("Light") or effect:IsA("SurfaceGui") then
				(effect :: any).Enabled = enabled
			end
		end
		table.clear(hidden)
		table.clear(hiddenEffects)
		table.clear(swimmers)
		table.clear(anchors)
	end

	local function rebuild()
		local source: Model? = nil
		for _, instance in CollectionService:GetTagged("AquariumTank") do
			if instance:IsA("Model") and instance:IsDescendantOf(Workspace) then
				source = instance
				break
			end
		end
		local snapshot = state
		local levelId = if snapshot and snapshot.status == "ready" then snapshot.levelId else nil
		local displays = World.displays(snapshot)
		local key = { levelId or "" }
		for _, fish in displays do
			table.insert(
				key,
				string.format(
					"%d/%s/%s/%s/%s/%d",
					fish.slot,
					fish.creatureId,
					tostring(fish.large),
					tostring(fish.gold),
					tostring(fish.linked),
					(snapshot and snapshot.slotCpm or {})[fish.slot] or 0
				)
			)
		end
		for _, cosmetic in ipairs((snapshot and snapshot.cosmetics) or {}) do
			table.insert(key, cosmetic)
		end
		local nextSignature = table.concat(key, "|")
		if base == source and signature == nextSignature then
			return
		end
		clear()
		base, signature = source, nextSignature
		if not source or not levelId or not snapshot then
			lastLevel = nil
			return
		end

		local holder = Instance.new("Folder")
		holder.Name = "LocalAquariumDisplay"
		scene = holder
		local habitat = source
		local kit = ReplicatedStorage:FindFirstChild("AquariumLevels")
		local levels = kit and kit:FindFirstChild("Levels")
		local template = levels and levels:FindFirstChild(levelId)
		if source:GetAttribute("LevelId") ~= levelId and template and template:IsA("Model") then
			local origin = source:GetAttribute("OriginCFrame")
			local originalMarker = part(source, "AquariumOrigin")
			local originPose = if typeof(origin) == "CFrame"
				then origin
				elseif originalMarker then originalMarker.CFrame
				else nil
			local variant = template:Clone()
			local offset = part(variant, "AquariumOrigin")
			if originPose and offset then
				prepare(variant, false)
				variant:PivotTo(originPose * offset.CFrame:Inverse() * variant:GetPivot())
				for _, layer in source:GetChildren() do
					if layer.Name:match("^Layer_") then
						for _, piece in layer:GetDescendants() do
							if piece:IsA("BasePart") then
								hidden[piece] = piece.LocalTransparencyModifier
								piece.LocalTransparencyModifier = 1
							elseif
								piece:IsA("ParticleEmitter")
								or piece:IsA("Light")
								or piece:IsA("SurfaceGui")
							then
								local effect = piece :: any
								hiddenEffects[piece] = effect.Enabled
								effect.Enabled = false
							end
						end
					end
				end
				if
					lastLevel
					and lastLevel ~= levelId
					and player:GetAttribute("ReduceEffects") ~= true
				then
					for _, piece in variant:GetDescendants() do
						if piece:IsA("BasePart") and piece.Transparency < 1 then
							piece.LocalTransparencyModifier = 1
							TweenService
								:Create(
									piece,
									TweenInfo.new(0.65),
									{ LocalTransparencyModifier = 0 }
								)
								:Play()
						end
					end
				end
				variant.Parent = holder
				habitat = variant
			else
				variant:Destroy()
			end
		end
		lastLevel = levelId

		local decor = kit and kit:FindFirstChild("Decor")
		for _, id in ipairs(snapshot.cosmetics or {}) do
			local definition = AquariumConfig.COSMETICS[id]
			local fallback = definition and definition.fallback
			local prop = definition and decor and decor:FindFirstChild(definition.prop)
			local anchor = definition
				and (part(habitat, definition.anchor) or (fallback and part(habitat, fallback)))
			if prop and prop:IsA("Model") and anchor then
				local copy = prop:Clone()
				prepare(copy, false)
				copy:PivotTo(anchor.CFrame)
				copy.Parent = holder
			end
		end
		local entries: { Income.WorldEntry } = {}
		local models = ReplicatedStorage:FindFirstChild(Creatures.MODELS_FOLDER)
		local normalVolume = part(habitat, "SwimVolume")
		local largeVolume = part(habitat, "SwimVolumeLarge") or normalVolume
		for _, fish in displays do
			local templateFish = models and models:FindFirstChild(fish.creatureId)
			local slot = part(habitat, string.format("Slot_%02d", fish.slot))
			if templateFish and templateFish:IsA("Model") and slot then
				local copy = templateFish:Clone()
				prepare(copy, fish.gold == true)
				local volume = if fish.large then largeVolume else normalVolume
				local extent = copy:GetExtentsSize()
				local scale = if fish.large then 3.5 else 2.0
				if volume then
					scale = math.min(scale, volume.Size.Y * 0.54, volume.Size.Z * 0.42)
				end
				copy:ScaleTo(copy:GetScale() * scale / math.max(0.1, extent.X, extent.Y, extent.Z))
				copy:PivotTo(slot.CFrame)
				local root = copy.PrimaryPart or copy:FindFirstChildWhichIsA("BasePart", true)
				if root then
					local anchor = Instance.new("Attachment")
					anchor.Name = "IncomeAnchor"
					anchor.Position = Vector3.new(0, scale * 0.56, 0)
					anchor.Parent = root
					anchors[fish.slot] = anchor
					table.insert(entries, {
						anchor = anchor,
						rarity = fish.rarity,
						cpm = (snapshot.slotCpm or {})[fish.slot] or 0,
					})
				end
				local glow = nil
				if fish.linked then
					local light = Instance.new("Highlight")
					light.FillColor = Color3.fromRGB(97, 237, 236)
					light.OutlineColor = light.FillColor
					light.Enabled = false
					light.Parent = copy
					glow = light
				end
				table.insert(swimmers, {
					model = copy,
					volume = volume,
					home = slot.CFrame,
					scale = scale,
					seed = fish.slot * 1.71,
					linked = fish.linked,
					glow = glow,
				})
				copy.Parent = holder
			end
		end
		holder.Parent = Workspace
		if #entries > 0 then
			labels = Income.mountWorld(playerGui, entries, 48, function(): Attachment?
				return if focus then anchors[focus] else nil
			end)
		end
		glowUntil = os.clock() + 1.15
	end

	CollectionService:GetInstanceAddedSignal("AquariumTank"):Connect(function()
		task.defer(rebuild)
	end)
	CollectionService:GetInstanceRemovedSignal("AquariumTank"):Connect(rebuild)
	ReplicatedStorage.ChildAdded:Connect(function(child)
		if child.Name == "AquariumLevels" or child.Name == Creatures.MODELS_FOLDER then
			signature = ""
			task.defer(rebuild)
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		if #swimmers == 0 then
			return
		end
		elapsed += dt
		if elapsed < (if near then 1 / 24 else 0.25) then
			return
		end
		local step = elapsed
		elapsed = 0
		local origin = base and base:GetPivot().Position
		local camera = Workspace.CurrentCamera
		if not origin or not camera then
			return
		end
		local distance = (camera.CFrame.Position - origin).Magnitude
		local wasNear = near
		near = distance < 44
		if near and not wasNear then
			glowUntil = os.clock() + 1.15
		end
		local reduced = player:GetAttribute("ReduceEffects") == true
		if not reduced and distance < 95 then
			time += step
		end
		for _, fish in swimmers do
			local glow = fish.glow
			if glow then
				glow.Enabled = not reduced and near and os.clock() < glowUntil
			end
			local volume = fish.volume
			if reduced or not volume then
				fish.model:PivotTo(fish.home)
			elseif distance < 95 then
				local t = time * (if near then 0.65 else 0.32) + fish.seed
				local pause = t - math.sin(t * 0.74) * 0.62
				local space = volume.Size * 0.5 - Vector3.one * fish.scale * 0.52
				local x = math.sin(pause) * math.max(0, space.X) * 0.82
				local y = math.sin(pause * 0.64 + fish.seed) * math.max(0, space.Y) * 0.8
				local z = math.cos(pause) * math.max(0, space.Z) * 0.78
				local yaw = math.atan2(
					math.cos(pause) * math.max(0.2, space.X),
					-math.sin(pause) * math.max(0.2, space.Z)
				)
				fish.model:PivotTo(volume.CFrame * CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0))
			end
		end
	end)

	return {
		update = function(snapshot: Types.AquariumSnapshot?)
			state = snapshot
			rebuild()
		end,
		focus = function(slot: number?)
			focus = slot
		end,
	}
end

return World
