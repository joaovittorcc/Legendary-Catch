--!strict

local Players = game:GetService("Players")
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

export type Stop = () -> ()
type Orb = { part: Part, trail: Trail?, ghosts: { Part } }
local active: { [Model]: Stop } = {}

local function makeBall(name: string, color: Color3, transparency: number): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = transparency
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Anchored = true
	part.Size = Vector3.one * 0.09
	return part
end

local function makeOrb(color: Color3, reduced: boolean, inViewport: boolean): Orb
	local part = makeBall("Star", color, 0)
	if reduced then
		return { part = part, ghosts = {} }
	end

	if inViewport then
		local ghosts: { Part } = {}
		for step = 1, 3 do
			table.insert(ghosts, makeBall("StarTrail", color, 0.22 + step * 0.2))
		end
		return { part = part, ghosts = ghosts }
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
	return { part = part, trail = trail, ghosts = {} }
end

local function orbitOffset(theta: number, radius: number, index: number, scale: number): Vector3
	return Vector3.new(
		math.cos(theta) * radius,
		math.sin(theta) * radius * 0.86,
		math.sin(theta * 2 + index) * 0.34 * scale
	)
end

-- Call from the client after parenting the reveal model to Workspace or ForegroundCreature.
-- The aura lives beside the model so it does not affect model bounds.
function CosmicOrbit.attach(model: Model, initialReduced: boolean?): Stop
	local previous = active[model]
	if previous then
		previous()
	end

	local player = Players.LocalPlayer
	local reduced = if initialReduced ~= nil
		then initialReduced
		else (player ~= nil and player:GetAttribute("ReduceEffects") == true)

	local container: Folder? = nil
	local orbs: { Orb } = {}
	local currentHost: Instance? = nil
	local inViewport = false

	local function resolveHost(): Instance?
		if not model.Parent then
			return nil
		end
		if model:IsDescendantOf(Workspace) then
			return Workspace
		end
		return model.Parent
	end

	local function rebuild()
		if container then
			container:Destroy()
			container = nil
		end
		table.clear(orbs)
		local host = resolveHost()
		currentHost = host
		if not host then
			return
		end
		inViewport = not model:IsDescendantOf(Workspace)
		local folder = Instance.new("Folder")
		folder.Name = "C93CosmicOrbit"
		local count = if reduced then 3 else #COLORS
		for index = 1, count do
			local colorIndex = if reduced then index * 2 - 1 else index
			local orb = makeOrb(COLORS[colorIndex], reduced, inViewport)
			orb.part.Parent = folder
			for _, ghost in orb.ghosts do
				ghost.Parent = folder
			end
			orbs[index] = orb
		end
		folder.Parent = host
		container = folder
	end

	local age = 0
	local previousPosition: Vector3? = nil
	local function update()
		local host = resolveHost()
		if host ~= currentHost then
			rebuild()
			previousPosition = nil
		end
		if not container or #orbs == 0 then
			return
		end
		local pivot = model:GetPivot()
		local scale = model:GetScale()
		local jump = previousPosition ~= nil
			and (pivot.Position - previousPosition).Magnitude > 3 * scale
		local count = #orbs
		for index, orb in orbs do
			local theta = index * (2 * math.pi / count) + (if reduced then 0 else age * 1.1)
			local radius = (1.72 + (index % 2) * 0.26) * scale
			local offset = orbitOffset(theta, radius, index, scale)
			orb.part.Size = Vector3.one * (0.09 * scale)
			orb.part.CFrame = pivot * CFrame.new(offset)
			for step, ghost in orb.ghosts do
				local ghostTheta = theta - step * 0.11
				local ghostOffset = orbitOffset(ghostTheta, radius, index, scale)
				local factor = 1 - step * 0.22
				ghost.Size = Vector3.one * (0.09 * scale * factor)
				ghost.CFrame = pivot * CFrame.new(ghostOffset)
			end
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

	rebuild()
	update()

	local heartbeat: RBXScriptConnection? = nil
	local destroying: RBXScriptConnection? = nil
	local reduceConn: RBXScriptConnection? = nil
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
		if reduceConn then
			reduceConn:Disconnect()
		end
		if container then
			container:Destroy()
			container = nil
		end
	end

	active[model] = stop
	destroying = model.Destroying:Connect(stop)
	if player then
		reduceConn = player:GetAttributeChangedSignal("ReduceEffects"):Connect(function()
			if not alive then
				return
			end
			local nextReduced = player:GetAttribute("ReduceEffects") == true
			if nextReduced ~= reduced then
				reduced = nextReduced
				rebuild()
				update()
			end
		end)
	end
	local sinceUpdate = 0
	local orphanTime = 0
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		if not model.Parent then
			if container then
				container:Destroy()
				container = nil
				currentHost = nil
			end
			orphanTime += dt
			if orphanTime > 0.5 then
				stop()
			end
			return
		end
		orphanTime = 0
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
