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
local activeBursts = 0
local flashTimes: { number } = {}
local MAX_FLASHES_PER_SEC = 3

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

-- Layered neon wave rings (contrast halo + rarity wave + white-hot core) that expand on water.
function Effects.ripple(
	center: Vector3,
	color: Color3,
	radius: number,
	duration: number,
	quiet: boolean?
)
	local baseCf = CFrame.new(center + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local ring = fx(
		"Ripple",
		Vector3.new(0.08, 0.9, 0.9),
		baseCf,
		color,
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
	ring.Transparency = if quiet or reduced() then 0.68 else 0.2
	TweenService
		:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.08, radius * 2, radius * 2),
			Transparency = 1,
		})
		:Play()
	Debris:AddItem(ring, duration + 0.1)

	if quiet or reduced() then
		return
	end

	-- Deep navy contrast layer underneath so bright ripples read clearly on sunlit water.
	local shade = fx(
		"RippleShade",
		Vector3.new(0.05, 1.1, 1.1),
		CFrame.new(center + Vector3.new(0, 0.02, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(16, 36, 78),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Cylinder
	)
	shade.Transparency = 0.52
	TweenService
		:Create(
			shade,
			TweenInfo.new(duration * 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Size = Vector3.new(0.05, radius * 2.15, radius * 2.15),
				Transparency = 1,
			}
		)
		:Play()
	Debris:AddItem(shade, duration)

	-- Crisp white-hot foam core that snaps outward slightly faster.
	local coreDur = duration * 0.72
	local core = fx(
		"RippleCore",
		Vector3.new(0.1, 0.6, 0.6),
		CFrame.new(center + Vector3.new(0, 0.07, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.new(1, 1, 1):Lerp(color, 0.25),
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)
	core.Transparency = 0.1
	TweenService
		:Create(core, TweenInfo.new(coreDur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.1, radius * 1.42, radius * 1.42),
			Transparency = 1,
		})
		:Play()
	Debris:AddItem(core, coreDur + 0.1)
end

function Effects.splash(center: Vector3, color: Color3, count: number)
	local isReduced = reduced()
	local limit = if isReduced then 1 else 3
	if activeBursts >= limit then
		return
	end
	activeBursts += 1
	task.delay(1.3, function()
		activeBursts = math.max(0, activeBursts - 1)
	end)
	local anchor = fx("Splash", Vector3.new(1, 1, 1), CFrame.new(center), color, Enum.Material.Air)
	anchor.Transparency = 1

	-- Primary sparkling droplets with velocity stretch, air drag and white-core gradient.
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.35, color:Lerp(Color3.new(1, 1, 1), 0.25)),
		ColorSequenceKeypoint.new(1, color),
	})
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(0.22, 0.68),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.65, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Squash = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, -0.15),
	})
	emitter.Drag = 3.2
	emitter.Lifetime = NumberRange.new(0.55, 1.0)
	emitter.Speed = NumberRange.new(10, 19)
	emitter.SpreadAngle = Vector2.new(38, 38)
	emitter.Acceleration = Vector3.new(0, -34, 0)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(if isReduced then math.min(count, 4) else math.min(count, 22))

	if not isReduced then
		-- Secondary fine foam mist rising softly above the impact.
		local mist = Instance.new("ParticleEmitter")
		mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
		mist.Color =
			ColorSequence.new(Color3.fromRGB(235, 250, 255), color:Lerp(Color3.new(1, 1, 1), 0.55))
		mist.LightEmission = 0.35
		mist.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(0.5, 1.35),
			NumberSequenceKeypoint.new(1, 1.8),
		})
		mist.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.4, 0.72),
			NumberSequenceKeypoint.new(1, 1),
		})
		mist.Drag = 4.5
		mist.Lifetime = NumberRange.new(0.35, 0.65)
		mist.Speed = NumberRange.new(4, 9)
		mist.SpreadAngle = Vector2.new(55, 55)
		mist.Acceleration = Vector3.new(0, 2, 0)
		mist.EmissionDirection = Enum.NormalId.Top
		mist.Rate = 0
		mist.Parent = anchor
		mist:Emit(math.min(math.ceil(count * 0.4), 8))
	end

	Debris:AddItem(anchor, 1.4)
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
	-- Comfort cap: at most 3 full-screen flashes per rolling second.
	local now = os.clock()
	for i = #flashTimes, 1, -1 do
		if now - flashTimes[i] > 1 then
			table.remove(flashTimes, i)
		end
	end
	if #flashTimes >= MAX_FLASHES_PER_SEC then
		return
	end
	table.insert(flashTimes, now)
	local f = Instance.new("Frame")
	f.Name = "Flash"
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = 50
	f.BackgroundTransparency = 0.68
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
	-- Uses squared trauma envelope + Nyquist-safe smooth noise (no jitter on 30 fps phones).
	local name = "FishingShake" .. tostring(os.clock())
	local start = os.clock()
	local seed = (start * 17.3) % 100
	local smoothedFps = 60
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local t = os.clock() - start
		if t >= duration or reduced() then
			RunService:UnbindFromRenderStep(name)
			return
		end
		if dt > 0.001 then
			smoothedFps += (math.clamp(1 / dt, 15, 240) - smoothedFps) * 0.15
		end
		local freq = math.min(12, 0.4 * smoothedFps)
		local decay = 1 - t / duration
		local amp = magnitude * decay * decay
		local rx = math.noise(t * freq, seed) * 2 * amp
		local ry = math.noise(seed + 13.7, t * freq) * 2 * amp
		camera.CFrame *= CFrame.Angles(math.rad(rx), math.rad(ry), 0)
	end)
end

return Effects
