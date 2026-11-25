--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Fishing = require(Shared.Config.Fishing)
local Zones = require(Shared.Config.Zones)
local Theme = require(Shared.UiTheme)

local Scenery = {}
local SCENERY_TAG = "OceanEventScenery"

function Scenery.anchor(eventId: string): (Instance?, CFrame?)
	local player = Players.LocalPlayer
	local character = player and player.Character
	local root = character and character.PrimaryPart
	local position = root and root.Position
	local sharedAnchor: Instance? = nil
	local sharedPose: CFrame? = nil
	local best = math.huge
	local candidates = CollectionService:GetTagged(SCENERY_TAG)
	for _, zone in CollectionService:GetTagged("OceanEventSceneryZone") do
		table.insert(candidates, zone)
	end
	for _, instance in candidates do
		if not instance:IsDescendantOf(Workspace) then
			continue
		end
		local pose = if instance:IsA("BasePart")
			then instance.CFrame
			elseif instance:IsA("Attachment") then instance.WorldCFrame
			else nil
		if not pose then
			continue
		end
		local event = instance:GetAttribute("EventId")
		if event == nil or event == eventId then
			local distance = if position then (pose.Position - position).Magnitude else 0
			local score = distance - (if event == eventId then 0.1 else 0)
			if score < best then
				best = score
				sharedAnchor, sharedPose = instance, pose
			end
		end
	end
	if sharedAnchor then
		return sharedAnchor, sharedPose
	end
	for _, zone in CollectionService:GetTagged(Fishing.ZONE_TAG) do
		if
			zone:IsA("BasePart")
			and zone:IsDescendantOf(Workspace)
			and Zones.zoneIdOfPart(zone) == Zones.DEFAULT_ID
		then
			return zone, zone.CFrame * CFrame.new(12, 1.5 - zone.Size.Y / 2, -zone.Size.Z / 2 - 8)
		end
	end
	return nil, nil
end

local function part(
	parent: Model,
	name: string,
	size: Vector3,
	pose: CFrame,
	tint: Color3,
	material: Enum.Material
): Part
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.CFrame = pose
	piece.Color = tint
	piece.Material = material
	piece.Anchored = true
	piece.CanCollide = false
	piece.CanQuery = false
	piece.CanTouch = false
	piece.CastShadow = false
	piece.Parent = parent
	return piece
end

local function buildArch(model: Model, pose: CFrame, tint: Color3): BasePart
	local shadow = tint:Lerp(Theme.ink, 0.59)
	local pale = tint:Lerp(Theme.cream, 0.38)
	for side = -1, 1, 2 do
		part(
			model,
			"Foot",
			Vector3.new(1.7, 0.38, 1.5),
			pose * CFrame.new(side * 3.35, 0.20, 0),
			shadow,
			Enum.Material.Slate
		)
		part(
			model,
			"Pillar",
			Vector3.new(0.78, 3.7, 0.9),
			pose * CFrame.new(side * 3.35, 2, 0),
			shadow,
			Enum.Material.Slate
		)
		part(
			model,
			"Inlay",
			Vector3.new(0.20, 3.25, 0.12),
			pose * CFrame.new(side * 3.35, 2.12, 0.51),
			pale,
			Enum.Material.Neon
		)
	end
	for index = 1, 8 do
		local a = math.pi * (index - 1) / 8
		local b = math.pi * index / 8
		local head = (pose * CFrame.new(math.cos(a) * 3.35, 3.80 + math.sin(a) * 2.2, 0)).Position
		local tail = (pose * CFrame.new(math.cos(b) * 3.35, 3.80 + math.sin(b) * 2.2, 0)).Position
		local segment = CFrame.lookAt((head + tail) / 2, tail)
		part(
			model,
			"Arch",
			Vector3.new(0.58, 0.58, (tail - head).Magnitude + 0.06),
			segment,
			shadow,
			Enum.Material.Slate
		)
		part(
			model,
			"CrystalTrim",
			Vector3.new(0.16, 0.19, (tail - head).Magnitude),
			segment + pose.ZVector * 0.34,
			tint,
			Enum.Material.Neon
		)
	end

	local header = part(
		model,
		"HeaderAnchor",
		Vector3.one * 0.2,
		pose * CFrame.new(0, 6.4, 0),
		tint,
		Enum.Material.SmoothPlastic
	)
	header.Transparency = 1
	return header
end

local function buildKit(model: Model, pose: CFrame, id: string, reduced: boolean): Attachment?
	local kit = ReplicatedStorage:FindFirstChild("EventSceneryKit")
	local base = kit and kit:FindFirstChild("BaseArch")
	local palettes = kit and kit:FindFirstChild("Palettes")
	local palette = palettes and palettes:FindFirstChild(id)
	if not base or not base:IsA("Model") or not palette then
		return nil
	end
	local arch = base:Clone()
	local root = arch.PrimaryPart
	local header = root and root:FindFirstChild("HeaderAnchor")
	if not root or not header or not header:IsA("Attachment") then
		arch:Destroy()
		return nil
	end
	arch:PivotTo(pose)
	arch.Parent = model
	local crests = kit and kit:FindFirstChild("Crests")
	local crest = crests and crests:FindFirstChild("Crest_" .. id)
	local mount = root:FindFirstChild("CrestMount")
	if crest and crest:IsA("Model") and mount and mount:IsA("Attachment") then
		local copy = crest:Clone()
		copy:PivotTo(mount.WorldCFrame)
		copy.Parent = model
	end
	local props = kit and kit:FindFirstChild("EventProps")
	local prop = props and props:FindFirstChild("Props_" .. id)
	if prop and prop:IsA("Model") then
		local copy = prop:Clone()
		copy:PivotTo(pose)
		copy.Parent = model
	end
	for _, child in model:GetDescendants() do
		local role = child:GetAttribute("TintRole")
		local color = if typeof(role) == "string" then palette:GetAttribute(role) else nil
		if child:IsA("BasePart") then
			child.Anchored = true
			child.CanCollide = false
			child.CanTouch = false
			child.CanQuery = false
			if typeof(color) == "Color3" then
				child.Color = color
			end
			if not reduced and child.Transparency < 1 then
				local target = child.CFrame
				local alpha = child.Transparency
				local crown = child:FindFirstAncestor("ArchCrown") ~= nil
				local inBase = child:IsDescendantOf(arch)
				local delayTime = if crown then 0.30 elseif inBase then 0 else 0.65
				child.CFrame += Vector3.new(
					0,
					if crown then -1.8 elseif inBase then -2.5 else -0.35,
					0
				)
				child.Transparency = 1
				TweenService:Create(
					child,
					TweenInfo.new(
						0.4,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.Out,
						0,
						false,
						delayTime
					),
					{
						CFrame = target,
						Transparency = alpha,
					}
				):Play()
			end
		elseif child:IsA("Light") then
			if typeof(color) == "Color3" then
				child.Color = color
			end
			if reduced then
				child.Brightness *= 0.8
			else
				local target = child.Brightness
				child.Brightness = 0
				TweenService:Create(
					child,
					TweenInfo.new(
						0.45,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.Out,
						0,
						false,
						0.30
					),
					{
						Brightness = target,
					}
				):Play()
			end
		elseif child:IsA("Beam") then
			if typeof(color) == "Color3" then
				child.Color = ColorSequence.new(color)
			end
		elseif child:IsA("ParticleEmitter") then
			if typeof(color) == "Color3" then
				child.Color = ColorSequence.new(color)
			end
			child.Enabled = false
			child:Clear()
			if not reduced then
				task.delay(1, function()
					if model.Parent and model:GetAttribute("Closing") ~= true then
						child.Enabled = true
					end
				end)
			end
		end
	end
	return header
end

function Scenery.create(
	pose: CFrame,
	title: string,
	caption: string,
	tint: Color3,
	id: string,
	reduced: boolean
): Model
	local model = Instance.new("Model")
	model.Name = "OceanEventBackdrop"
	local pale = tint:Lerp(Theme.cream, 0.38)
	local header: Instance = buildKit(model, pose, id, reduced) or buildArch(model, pose, tint)
	local label = Instance.new("BillboardGui")
	label.Name = "EventSceneryLabel"
	label.Size = UDim2.fromOffset(192, 56)
	label.MaxDistance = 86
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Theme.ink
	card.BackgroundTransparency = 0.11
	card.BorderSizePixel = 0
	Theme.corner(card, 11)
	for index, value in { title, caption } do
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, -12, 0.5, -2)
		text.Position = UDim2.new(0, 6, (index - 1) * 0.5, 1)
		text.BackgroundTransparency = 1
		text.Text = value
		text.TextColor3 = if index == 1 then pale else Theme.sand
		text.TextScaled = true
		text.Font = Theme.font
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = if index == 1 then 17 else 13
		limit.Parent = text
		text.Parent = card
	end
	card.Parent = label
	label.Parent = header
	model.Parent = Workspace
	return model
end

function Scenery.remove(model: Model, immediate: boolean)
	if immediate then
		model:Destroy()
		return
	end
	model:SetAttribute("Closing", true)
	for _, child in model:GetDescendants() do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
		elseif child:IsA("Beam") or child:IsA("BillboardGui") then
			(child :: any).Enabled = false
		elseif child:IsA("Light") then
			TweenService:Create(child, TweenInfo.new(0.45), { Brightness = 0 }):Play()
		elseif child:IsA("BasePart") then
			TweenService:Create(child, TweenInfo.new(0.65), {
				CFrame = child.CFrame - Vector3.new(0, 2.2, 0),
				Transparency = 1,
			}):Play()
		end
	end
	task.delay(0.7, function()
		model:Destroy()
	end)
end

return Scenery
