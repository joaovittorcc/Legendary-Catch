--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roulette = require(ReplicatedStorage.Shared.Config.Roulette)

local Mutation = {}
local WHITE = Color3.new(1, 1, 1)
local MATERIALS: { [string]: Enum.Material } = {
	neon = Enum.Material.Neon,
	frost = Enum.Material.Ice,
	magma = Enum.Material.Neon,
	storm = Enum.Material.Neon,
	rainbow = Enum.Material.SmoothPlastic,
	diamond = Enum.Material.Glass,
	cosmic = Enum.Material.SmoothPlastic,
}

function Mutation.scale(sizeMult: number?): number
	return math.clamp(math.sqrt(math.max(sizeMult or 1, 0)), 0.45, 6)
end

function Mutation.color(id: string?): Color3?
	return if id and MATERIALS[id] then Roulette.COLORS[id] else nil
end

function Mutation.paint(model: Model, id: string?): ((number, boolean) -> ())?
	local color = Mutation.color(id)
	local material = id and MATERIALS[id]
	if not color or not material then
		return nil
	end

	local parts: { BasePart } = {}
	local surfaces: { [BasePart]: SurfaceAppearance } = {}
	for _, object in model:GetDescendants() do
		if object:IsA("BasePart") then
			local surface = object:FindFirstChildOfClass("SurfaceAppearance")
			local tint =
				object.Color:Lerp(color, if material == Enum.Material.Neon then 0.6 else 0.73)
			if object.Transparency < 1 then
				table.insert(parts, object)
				object.Material = material
				object.MaterialVariant = ""
				object.Color = tint
				if id == "diamond" then
					object.Reflectance = 0.18
				end
				if surface then
					surfaces[object] = surface
					surface.Color = WHITE:Lerp(tint, 0.57)
				end
			end
		end
	end

	local rim = Instance.new("Highlight")
	rim.Name = "RouletteMutation"
	rim.FillColor = color
	rim.OutlineColor = color:Lerp(WHITE, 0.42)
	rim.FillTransparency = 0.88
	rim.OutlineTransparency = 0.48
	rim.DepthMode = Enum.HighlightDepthMode.Occluded
	rim.Parent = model

	if id == "rainbow" then
		local function draw(elapsed: number, reduced: boolean)
			local phase = if reduced then 0 else elapsed * 0.2
			for index, part in parts do
				local tint = Color3.fromHSV((phase + (index - 1) / #parts) % 1, 0.73, 1)
				part.Color = tint
				local surface = surfaces[part]
				if surface then
					surface.Color = WHITE:Lerp(tint, 0.65)
				end
			end
			rim.OutlineColor = Color3.fromHSV(phase % 1, 0.53, 1)
		end
		draw(0, true)
		return draw
	end
	return nil
end

function Mutation.particles(model: Model, id: string?): ParticleEmitter?
	local color = Mutation.color(id)
	local body = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not color or not body then
		return nil
	end
	local extent = model:GetExtentsSize()
	local radius = math.max(extent.X, extent.Y, extent.Z)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "MutationSparks"
	emitter.Enabled = false
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color =
		ColorSequence.new(color, color:Lerp(WHITE, if id == "cosmic" then 0.68 else 0.3))
	emitter.LightEmission = 0.75
	emitter.LightInfluence = 0
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Rate = if id == "cosmic" then 12 else 8
	emitter.Lifetime = NumberRange.new(0.55, 0.95)
	emitter.Speed = NumberRange.new(radius * 0.16, radius * 0.38)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, radius * 0.023),
		NumberSequenceKeypoint.new(0.32, radius * 0.092),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new(0.12, 1)
	emitter.Parent = body
	return emitter
end

-- World particles do not render in a ViewportFrame.
function Mutation.viewport(stage: GuiObject, id: string?): ((number, boolean) -> ())?
	local color = Mutation.color(id)
	if not color then
		return nil
	end
	local stars: { TextLabel } = {}
	for index = 1, if id == "cosmic" then 10 else 6 do
		local star = Instance.new("TextLabel")
		star.Name = "MutationSpark"
		star.AnchorPoint = Vector2.new(0.5, 0.5)
		star.BackgroundTransparency = 1
		star.Size = UDim2.fromOffset(22, 22)
		star.Text = if index % 3 == 0 then "·" else "✦"
		star.TextSize = 18
		star.TextColor3 = color:Lerp(WHITE, if id == "cosmic" then 0.65 else 0.27)
		star.ZIndex = 4
		star.Visible = false
		star.Parent = stage
		table.insert(stars, star)
	end
	return function(elapsed: number, visible: boolean)
		for index, star in stars do
			star.Visible = visible
			if visible then
				local angle = index / #stars * math.pi * 2 + elapsed * 0.53
				local pulse = (math.sin(elapsed * 3 + index) + 1) / 2
				star.Position =
					UDim2.fromScale(0.5 + math.cos(angle) * 0.43, 0.5 + math.sin(angle) * 0.4)
				star.TextTransparency = 0.22 + pulse * 0.52
				if id == "rainbow" then
					star.TextColor3 = Color3.fromHSV((elapsed * 0.2 + index / #stars) % 1, 0.64, 1)
				end
			end
		end
	end
end

return Mutation
