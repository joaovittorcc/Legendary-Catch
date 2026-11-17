--!strict
-- Reusable one-shot VFX for fishing: water ripples, splashes, light pillars, lightning,
-- screen flash, darkening and camera shake. Everything cleans itself up.

local Players = game:GetService("Players")
local function reduced(): boolean
	return Players.LocalPlayer:GetAttribute("ReduceEffects") == true
end

local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Effects = {}

local function fx(
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = Workspace
	return p
end

-- Flat neon ring that grows and fades on the water.
function Effects.ripple(center: Vector3, color: Color3, radius: number, duration: number)
	local ring = fx(
		"Ripple",
		Vector3.new(0.08, 1, 1),
		CFrame.new(center + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
	ring.Transparency = 0.2
	local tween = TweenService:Create(
		ring,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(0.08, radius * 2, radius * 2),
			Transparency = 1,
		}
	)
	tween:Play()
	Debris:AddItem(ring, duration + 0.1)
end

function Effects.splash(center: Vector3, color: Color3, count: number)
	local anchor = fx("Splash", Vector3.new(1, 1, 1), CFrame.new(center), color, Enum.Material.Air)
	anchor.Transparency = 1
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	emitter.LightEmission = 1
	emitter.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.6, 1.1)
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Acceleration = Vector3.new(0, -30, 0)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(if reduced() then math.min(count, 4) else count)
	Debris:AddItem(anchor, 1.5)
end

-- Bright column rising from the water (the "geyser" moment before rare reveals).
function Effects.pillar(center: Vector3, color: Color3, height: number, duration: number)
	local column = fx(
		"LightPillar",
		Vector3.new(height, 1.6, 1.6),
		CFrame.new(center + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
	column.Transparency = 0.1
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 6
	light.Range = 30
	light.Parent = column
	TweenService
		:Create(column, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = Vector3.new(height, 0.1, 0.1),
			Transparency = 1,
		})
		:Play()
	Debris:AddItem(column, duration + 0.1)
end

-- Jagged bolt from the sky to a point, made of short neon segments.
function Effects.lightning(target: Vector3, color: Color3)
	if reduced() then
		return
	end
	local top = target + Vector3.new(math.random(-6, 6), 45, math.random(-6, 6))
	local segments = 9
	local prev = top
	for i = 1, segments do
		local a = i / segments
		local point = top:Lerp(target, a)
		if i < segments then
			point += Vector3.new(math.random(-25, 25) / 10, 0, math.random(-25, 25) / 10)
		end
		local len = (point - prev).Magnitude
		local seg = fx(
			"Bolt",
			Vector3.new(0.35, 0.35, len),
			CFrame.lookAt((prev + point) / 2, point),
			color,
			Enum.Material.Neon
		)
		TweenService:Create(seg, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		Debris:AddItem(seg, 0.4)
		prev = point
	end
	local glow = fx(
		"BoltGlow",
		Vector3.new(1, 1, 1),
		CFrame.new(target),
		color,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	glow.Transparency = 1
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 10
	light.Range = 40
	light.Parent = glow
	Debris:AddItem(glow, 0.25)
end

function Effects.flash(gui: ScreenGui, color: Color3, duration: number)
	if reduced() then
		return
	end
	local f = Instance.new("Frame")
	f.Name = "Flash"
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = 50
	f.BackgroundTransparency = 0.65
	f.Parent = gui
	TweenService
		:Create(f, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		:Play()
	Debris:AddItem(f, duration + 0.1)
end

-- Temporarily dims and tints the world; returns a function that restores it.
function Effects.darken(tint: Color3, fadeIn: number): () -> ()
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "FishingReveal"
	cc.Parent = Lighting
	TweenService
		:Create(
			cc,
			TweenInfo.new(fadeIn),
			{ Brightness = -0.35, TintColor = tint, Saturation = 0.2 }
		)
		:Play()
	return function()
		local out = TweenService:Create(
			cc,
			TweenInfo.new(0.5),
			{ Brightness = 0, TintColor = Color3.new(1, 1, 1), Saturation = 0 }
		)
		out:Play()
		Debris:AddItem(cc, 0.6)
	end
end

function Effects.shake(duration: number, magnitude: number)
	if reduced() then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	-- Runs right after the default camera so its offset isn't overwritten.
	local name = "FishingShake" .. tostring(os.clock())
	local start = os.clock()
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock() - start
		if t >= duration then
			RunService:UnbindFromRenderStep(name)
			return
		end
		local m = magnitude * (1 - t / duration)
		camera.CFrame *= CFrame.Angles(
			math.rad(math.random(-10, 10) / 10 * m),
			math.rad(math.random(-10, 10) / 10 * m),
			0
		)
	end)
end

return Effects
