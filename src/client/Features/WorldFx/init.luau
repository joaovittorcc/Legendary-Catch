--!strict
-- World VFX layered on top of existing features (presentation only):
--   * Portals (tag ZonePortal, colours from PrimaryColor / AccentColor): sparkles drawn into
--     the portal while the player is near, and a swirl + ring burst where the player leaves
--     and where they arrive after a teleport.
--   * Aquarium (tag AquariumTank): bubbles rising from the water and a soft shimmer on the surface.
-- Everything respects ReduceEffects and only runs near the camera.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Vfx = Shared:WaitForChild("Vfx")
local Palette = require(Vfx:WaitForChild("Palette"))
local VfxKit = require(Vfx:WaitForChild("VfxKit"))
local SfxKit = require(Vfx:WaitForChild("SfxKit"))

local WorldFx = {}
WorldFx.order = 190

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local PORTAL_NEAR = 45
local TELEPORT_JUMP = 60

local player = Players.LocalPlayer

local function reduced(): boolean
	return player:GetAttribute("ReduceEffects") == true
end

local function colorAttr(inst: Instance, name: string, fallback: Color3): Color3
	local v = inst:GetAttribute(name)
	if typeof(v) == "Color3" then
		return v
	end
	return fallback
end

-- ---------------------------------------------------------------------------
-- Portals
-- ---------------------------------------------------------------------------

type PortalFxEntry = {
	part: BasePart,
	attachment: Attachment,
	emitter: ParticleEmitter,
	color: Color3,
}
local portals: { [BasePart]: PortalFxEntry } = {}

local function addPortal(inst: Instance)
	if not inst:IsA("BasePart") or portals[inst] then
		return
	end
	local primary = colorAttr(inst, "PrimaryColor", Palette.World.CrystalCyan)
	local accent = colorAttr(inst, "AccentColor", Palette.World.BlossomPink)
	local att = Instance.new("Attachment")
	att.Name = "WorldFxPortalAttachment"
	local e = Instance.new("ParticleEmitter")
	e.Name = "WorldFxPortalSuck"
	e.Texture = SPARKLE
	e.LightEmission = 1
	e.Color = ColorSequence.new(primary, accent)
	e.Rate = 0
	e.Enabled = false
	e.Lifetime = NumberRange.new(0.9, 1.4)
	e.Speed = NumberRange.new(0, 0)
	e.SpreadAngle = Vector2.new(180, 180)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, 0.55),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	-- Particles spawn in a shell around the portal and drift in to the middle.
	e.Shape = Enum.ParticleEmitterShape.Sphere
	e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	e.Acceleration = Vector3.zero
	e.Parent = att
	att.Parent = inst
	portals[inst] = { part = inst, attachment = att, emitter = e, color = primary }
end

local function removePortal(inst: Instance)
	local entry = portals[inst :: BasePart]
	if entry then
		entry.attachment:Destroy()
		portals[inst :: BasePart] = nil
	end
end

local function updatePortals(camPos: Vector3)
	local calm = reduced()
	for part, entry in portals do
		if not part.Parent then
			portals[part] = nil
			continue
		end
		local near = (part.Position - camPos).Magnitude <= PORTAL_NEAR and not calm
		entry.emitter.Enabled = near
		if near then
			entry.emitter.Rate = 10
		end
	end
end

local function nearestPortalColor(pos: Vector3): Color3
	local best = Palette.World.CrystalCyan
	local bestDist = 40
	for part, entry in portals do
		local d = (part.Position - pos).Magnitude
		if d < bestDist then
			bestDist = d
			best = entry.color
		end
	end
	return best
end

local function teleportBurst(pos: Vector3, color: Color3)
	VfxKit.ring(pos, color, 7, 0.7, 1, 3)
	VfxKit.burst(pos + Vector3.new(0, 2, 0), "sparks", 0.9, 3, color)
	VfxKit.burst(pos + Vector3.new(0, 2, 0), "stars", 0.5, 3, Color3.new(1, 1, 1))
	SfxKit.playAt("portal_teleport", pos)
end

local lastCharacter: Model? = nil
local lastRootPos: Vector3? = nil
local function watchTeleports()
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not character or not root or not root:IsA("BasePart") then
			lastCharacter = nil
			lastRootPos = nil
			return
		end
		if character ~= lastCharacter then
			lastCharacter = character
			lastRootPos = root.Position
			return
		end
		local pos = root.Position
		local previous = lastRootPos
		lastRootPos = pos
		if previous and (pos - previous).Magnitude > TELEPORT_JUMP and not reduced() then
			teleportBurst(previous, nearestPortalColor(previous))
			task.delay(0.1, function()
				teleportBurst(pos, nearestPortalColor(pos))
			end)
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Aquarium
-- ---------------------------------------------------------------------------

local aquariums: { [Instance]: { attachment: Attachment, emitters: { ParticleEmitter } } } = {}

local function addAquarium(tank: Instance)
	if aquariums[tank] then
		return
	end
	local surface = tank:FindFirstChild("WaterSurface", true)
	if not surface or not surface:IsA("BasePart") then
		return
	end
	local att = Instance.new("Attachment")
	att.Name = "WorldFxBubbleAttachment"
	att.Position = Vector3.new(0, -surface.Size.Y / 2 - 3, 0)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "WorldFxBubbles"
	bubbles.Texture = ""
	bubbles.LightEmission = 0.5
	bubbles.Color = ColorSequence.new(Color3.fromRGB(190, 244, 255), Color3.new(1, 1, 1))
	bubbles.Rate = 5
	bubbles.Lifetime = NumberRange.new(1.8, 2.8)
	bubbles.Speed = NumberRange.new(1.2, 2.2)
	bubbles.SpreadAngle = Vector2.new(8, 8)
	bubbles.EmissionDirection = Enum.NormalId.Top
	bubbles.Size = NumberSequence.new(0.22, 0.4)
	bubbles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(0.15, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	bubbles.Shape = Enum.ParticleEmitterShape.Box
	bubbles.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	bubbles.Parent = att

	local shimmer = Instance.new("ParticleEmitter")
	shimmer.Name = "WorldFxShimmer"
	shimmer.Texture = SPARKLE
	shimmer.LightEmission = 1
	shimmer.Color = ColorSequence.new(Palette.World.SoftAqua, Color3.new(1, 1, 1))
	shimmer.Rate = 3
	shimmer.Lifetime = NumberRange.new(1.2, 2)
	shimmer.Speed = NumberRange.new(0.2, 0.6)
	shimmer.SpreadAngle = Vector2.new(180, 180)
	shimmer.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	shimmer.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	shimmer.Parent = att
	att.Parent = surface
	aquariums[tank] = { attachment = att, emitters = { bubbles, shimmer } }
end

local function removeAquarium(tank: Instance)
	local entry = aquariums[tank]
	if entry then
		entry.attachment:Destroy()
		aquariums[tank] = nil
	end
end

local function updateAquariums(camPos: Vector3)
	local calm = reduced()
	for tank, entry in aquariums do
		if not tank.Parent then
			aquariums[tank] = nil
			continue
		end
		local pos = if tank:IsA("Model") then tank:GetPivot().Position else camPos
		local on = (pos - camPos).Magnitude <= 90 and not calm
		for _, e in entry.emitters do
			e.Enabled = on
		end
	end
end

function WorldFx.start()
	VfxKit.init()
	SfxKit.init()

	for _, p in CollectionService:GetTagged("ZonePortal") do
		addPortal(p)
	end
	CollectionService:GetInstanceAddedSignal("ZonePortal"):Connect(addPortal)
	CollectionService:GetInstanceRemovedSignal("ZonePortal"):Connect(removePortal)

	for _, t in CollectionService:GetTagged("AquariumTank") do
		addAquarium(t)
	end
	CollectionService:GetInstanceAddedSignal("AquariumTank"):Connect(function(t)
		task.delay(1, addAquarium, t)
	end)
	CollectionService:GetInstanceRemovedSignal("AquariumTank"):Connect(removeAquarium)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.5 then
			return
		end
		acc = 0
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		updatePortals(cam.CFrame.Position)
		updateAquariums(cam.CFrame.Position)
	end)

	watchTeleports()
end

return WorldFx
