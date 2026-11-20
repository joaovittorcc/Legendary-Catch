--!strict

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local CosmicOrbit = {}

local COLORS = {
	Color3.fromRGB(91, 224, 255),
	Color3.fromRGB(190, 143, 255),
	Color3.fromRGB(255, 202, 112),
	Color3.fromRGB(255, 99, 174),
	Color3.fromRGB(113, 234, 255),
	Color3.fromRGB(172, 126, 250),
}

type Stop = () -> ()
type Orb = { part: Part, trail: Trail? }
local active: { [Model]: Stop } = {}

local function makeOrb(color: Color3, reduced: boolean): Orb
	local part = Instance.new("Part")
	part.Name = "Star"
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = color
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Anchored = true
	part.Size = Vector3.one * 0.09
	if reduced then
		return { part = part }
	end

	local a = Instance.new("Attachment")
	a.Position = Vector3.yAxis * 0.055
	a.Parent = part
	local b = Instance.new("Attachment")
	b.Position = -Vector3.yAxis * 0.055
	b.Parent = part

	local trail = Instance.new("Trail")
	trail.Attachment0 = a
	trail.Attachment1 = b
	trail.Color = ColorSequence.new(color)
	trail.FaceCamera = true
	trail.LightEmission = 0.8
	trail.LightInfluence = 0
	trail.Lifetime = 0.36
	trail.MinLength = 0.04
	trail.Transparency = NumberSequence.new(0.25, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Parent = part
	return { part = part, trail = trail }
end

-- Call from the client after parenting the reveal model to Workspace.
-- The aura lives beside the model so it does not affect model bounds.
function CosmicOrbit.attach(model: Model, reduced: boolean): Stop
	assert(model:IsDescendantOf(Workspace), "CosmicOrbit needs a model in Workspace")
	local previous = active[model]
	if previous then
		previous()
	end

	local container = Instance.new("Folder")
	container.Name = "C93CosmicOrbit"
	local orbs: { Orb } = {}
	local count = if reduced then 3 else #COLORS
	for index = 1, count do
		local colorIndex = if reduced then index * 2 - 1 else index
		local orb = makeOrb(COLORS[colorIndex], reduced)
		orb.part.Parent = container
		orbs[index] = orb
	end

	local age = 0
	local previousPosition: Vector3? = nil
	local function update()
		local pivot = model:GetPivot()
		local scale = model:GetScale()
		local jump = previousPosition ~= nil
			and (pivot.Position - previousPosition).Magnitude > 3 * scale
		for index, orb in orbs do
			local theta = index * (2 * math.pi / count) + (if reduced then 0 else age * 1.1)
			local radius = (1.9 + (index % 2) * 0.32) * scale
			local offset = Vector3.new(
				math.cos(theta) * radius,
				math.sin(theta) * radius * 0.86,
				math.sin(theta * 2 + index) * 0.34 * scale
			)
			orb.part.Size = Vector3.one * (0.09 * scale)
			orb.part.CFrame = pivot * CFrame.new(offset)
			local trail = orb.trail
			if trail then
				trail.Enabled = not jump
				if jump then
					trail:Clear()
				end
			end
		end
		previousPosition = pivot.Position
	end

	update()
	container.Parent = Workspace
	local heartbeat: RBXScriptConnection? = nil
	local destroying: RBXScriptConnection? = nil
	local alive = true
	local function stop()
		if not alive then
			return
		end
		alive = false
		active[model] = nil
		if heartbeat then
			heartbeat:Disconnect()
		end
		if destroying then
			destroying:Disconnect()
		end
		container:Destroy()
	end

	active[model] = stop
	destroying = model.Destroying:Connect(stop)
	local sinceUpdate = 0
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		if not model:IsDescendantOf(Workspace) then
			stop()
			return
		end
		age += dt
		sinceUpdate += dt
		if sinceUpdate >= 1 / 30 then
			sinceUpdate %= 1 / 30
			update()
		end
	end)
	return stop
end

return CosmicOrbit
