--!strict
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Audio = require(script.Parent.Parent.Parent.Audio)
local Effects = require(script.Parent.Parent.Effects)
local Framing = require(script.Parent.Parent.RevealFraming)
local Motion = require(script.Parent.Parent.Parent.CreatureMotion)
local Water = require(script.Parent.Water)

local MysticShots = {}
local UP = Vector3.yAxis
local FOAM = Color3.fromRGB(211, 248, 255)
local GOLD = Color3.fromRGB(255, 213, 154)
local TIDE_IMPACT = 1.75
local TIDE_RISE = 2.55
local COSMIC_BREACH = 1.08
local TAU = math.pi * 2

export type Shot = {
	draw: (number, Camera, Vector2) -> (),
	hide: () -> (),
}

local function blend(t: number): number
	local x = math.clamp(t, 0, 1)
	return x * x * (3 - 2 * x)
end

local function stageOrigin(
	origin: Vector3,
	forward: Vector3,
	side: Vector3,
	player: Instance
): Vector3
	local params = RaycastParams.new()
	params.IgnoreWater = true
	params.RespectCanCollide = true
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player }
	local nearby = OverlapParams.new()
	nearby.FilterType = Enum.RaycastFilterType.Exclude
	nearby.FilterDescendantsInstances = { player }
	for _, offset in
		{
			forward * 42,
			forward * 54 + side * 22,
			forward * 54 - side * 22,
			forward * 67,
		}
	do
		local spot = origin + offset
		local hit = Workspace:Raycast(spot + UP * 20, -UP * 19.5, params)
		if not hit then
			local clear = true
			for _, obstacle in
				Workspace:GetPartBoundsInBox(
					CFrame.new(spot + UP * 7),
					Vector3.new(30, 14, 30),
					nearby
				)
			do
				if obstacle.Transparency < 0.9 then
					clear = false
					break
				end
			end
			if clear then
				return spot
			end
		end
	end
	return origin + forward * 72
end

local function addGrade(parent: Instance, tide: boolean): ColorCorrectionEffect
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "MysticCatchGrade"
	grade.Brightness = if tide then -0.17 else -0.19
	grade.Contrast = 0.12
	grade.Saturation = if tide then -0.22 else -0.25
	grade.TintColor = if tide then Color3.fromRGB(198, 228, 255) else Color3.fromRGB(225, 211, 255)
	grade.Enabled = false
	grade.Parent = parent
	return grade
end

local function addLight(parent: Instance, color: Color3, place: Vector3): Part
	local anchor = Instance.new("Part")
	anchor.Name = "MysticWaterLight"
	anchor.Size = Vector3.one
	anchor.Position = place
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	local light = Instance.new("PointLight")
	light.Range = 27
	light.Brightness = 1.1
	light.Color = color
	light.Parent = anchor
	anchor.Parent = parent
	return anchor
end

local function placeShot(camera: Camera, eye: Vector3, at: Vector3, fov: number, roll: number?)
	camera.CFrame = CFrame.lookAt(eye, at) * CFrame.Angles(0, 0, roll or 0)
	camera.Focus = CFrame.new(at)
	camera.FieldOfView = fov
end

local function sprayEmitter(parent: Part, tint: Color3, mist: boolean): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = if mist then "SeaFoamMist" else "SeaFoamDroplets"
	emitter.Texture = if mist
		then "rbxasset://textures/particles/smoke_main.dds"
		else "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(FOAM, tint)
	emitter.Rate = 0
	emitter.LightEmission = if mist then 0.25 else 0.8
	emitter.Lifetime = if mist then NumberRange.new(0.55, 1.1) else NumberRange.new(0.6, 1.2)
	emitter.Speed = if mist then NumberRange.new(7, 15) else NumberRange.new(15, 26)
	emitter.Acceleration = Vector3.new(0, if mist then 1 else -44, 0)
	emitter.Drag = if mist then 4 else 1.8
	emitter.SpreadAngle = Vector2.new(37, 37)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, if mist then 0.8 else 0.3),
		NumberSequenceKeypoint.new(0.32, if mist then 3.1 else 0.62),
		NumberSequenceKeypoint.new(1, if mist then 4.8 else 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, if mist then 0.67 else 0.16),
		NumberSequenceKeypoint.new(0.43, if mist then 0.68 else 0.26),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = parent
	return emitter
end

function MysticShots.create(
	parent: Folder,
	kind: string,
	id: string,
	origin: Vector3,
	forward: Vector3,
	character: Instance,
	clone: (string) -> Model
): Shot
	local scene = Instance.new("Folder")
	scene.Name = "MysticOceanScene"
	scene.Parent = parent
	local side = Vector3.new(forward.Z, 0, -forward.X)
	local spot = stageOrigin(origin, forward, side, character)
	local tide = kind == "tide"
	local accent = if tide then Color3.fromRGB(82, 214, 255) else Color3.fromRGB(185, 135, 255)
	local model = clone(id)
	model:ScaleTo(model:GetScale() * (if tide then 2.65 else 2.95))
	local spans = model:GetExtentsSize()
	local bounds = Framing.measure(model)
	local motion = Motion.bind(model, if tide then "storm" else "cosmic")
	local grade = addGrade(Lighting, tide)
	scene.Destroying:Once(function()
		grade:Destroy()
		if not model.Parent then
			model:Destroy()
		end
	end)
	local lamp = addLight(scene, accent, spot + UP * 2)
	local rim = addLight(scene, if tide then GOLD else Color3.fromRGB(121, 223, 255), spot + UP * 4)
	local foamParts: { Part } = {}
	local foamDrops: { ParticleEmitter } = {}
	local foamMist: { ParticleEmitter } = {}
	for i = 1, 5 do
		local a = (i - 1) * TAU / 5
		local direction = side * math.sin(a) + forward * math.cos(a)
		local anchor = Instance.new("Part")
		anchor.Name = "MysticFoam"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Size = Vector3.one
		anchor.Transparency = 1
		local start = spot + direction * 2.8
		anchor.CFrame = CFrame.lookAt(start, start + direction + UP * 1.9)
			* CFrame.Angles(-math.pi / 2, 0, 0)
		anchor.Parent = scene
		foamParts[i] = anchor
		foamDrops[i] = sprayEmitter(anchor, accent, false)
		foamMist[i] = sprayEmitter(anchor, accent, true)
	end
	local function foam(droplets: number, mist: number)
		for i in foamParts do
			foamDrops[i]:Emit(droplets)
			foamMist[i]:Emit(mist)
		end
	end
	local wakeFolder = Instance.new("Folder")
	wakeFolder.Name = "OceanWake"
	wakeFolder.Parent = scene
	local wakeStarts = if tide then TIDE_IMPACT else COSMIC_BREACH
	local wakeDuration = if tide then 3.3 else 2.75
	local wake = Water.create(wakeFolder, spot + UP * 0.03, {
		kind = "waves",
		at = wakeStarts,
		duration = wakeDuration,
		count = 3,
		strength = 1,
	}, {
		accent = accent,
		light = FOAM,
		entrance = 0,
		duration = wakeDuration,
		cues = {},
	})
	local sword: BasePart? = nil
	local blade = model:FindFirstChild("Sword", true)
	if tide and blade and blade:IsA("MeshPart") then
		local prop = blade:Clone()
		prop.Anchored = true
		prop.CanCollide = false
		prop.CanQuery = false
		prop.CanTouch = false
		prop.Parent = scene
		sword = prop
	end
	local swordRotation = if sword then sword.CFrame.Rotation else CFrame.identity
	local struckWater = false
	local breach = false
	local spray = false
	local opening = false
	local hidden = false

	local function hide()
		if hidden then
			return
		end
		hidden = true
		scene:Destroy()
	end

	local function draw(t: number, camera: Camera, size: Vector2)
		if hidden then
			return
		end
		local aspect = size.X / math.max(size.Y, 1)
		local tight = math.clamp((1.18 - aspect) / 0.72, 0, 1)
		grade.Enabled = true
		if wake then
			wake(math.clamp((t - wakeStarts) / wakeDuration, 0, 1))
		end
		if not opening then
			opening = true
			Effects.ripple(spot, accent, 8, 1.25)
		end

		local at: Vector3
		local eye: Vector3
		local fov: number
		if tide then
			local falling = blend((t - 0.35) / (TIDE_IMPACT - 0.35))
			local bladeAt = spot + UP * (2.15 + 15 * (1 - falling))
			local impact = math.max(0, t - TIDE_IMPACT)
			if sword then
				sword.Transparency = blend((t - 2.24) / 0.35)
				sword.CFrame = CFrame.new(bladeAt)
					* CFrame.Angles(0, math.atan2(forward.X, forward.Z) + t * 0.36, 0)
					* swordRotation
			end
			if t >= TIDE_IMPACT and not struckWater then
				struckWater = true
				Effects.lightning(spot, GOLD)
				foam(8, 4)
				Audio.play("bite", 0.36, 0.63)
			end
			if t < TIDE_RISE then
				at = spot + UP * ((if sword then bladeAt.Y - spot.Y else 3) * 0.69)
				eye = at
					- forward * (12 + tight * 8)
					+ side * (6 - falling * 2)
					+ UP * (1.25 - falling)
				fov = 49
			else
				local rise = blend((t - TIDE_RISE) / 1.55)
				local heroAt = spot + UP * (-spans.Y * 0.15 + spans.Y * 0.76 * rise)
				local arc = (1 - blend((t - TIDE_RISE) / 3.45)) * 0.93
				local direction = -forward * math.cos(arc) + side * math.sin(arc)
				at = spot + UP * (1.4 + rise * 3.3)
				eye = at + direction * (17.5 + tight * 40 - rise * 1.2) + UP * (-0.75 + rise * 2.75)
				fov = 48 - rise * 5
				model:PivotTo(Framing.pose(bounds, heroAt, eye - heroAt, math.rad(-14)))
				if not breach then
					breach = true
					model.Parent = scene
					foam(6, 3)
					Audio.play("cast", 0.22, 0.67)
				end
				if rise > 0.64 and not spray then
					spray = true
					foam(4, 2)
				end
				lamp.Position = spot + UP * (1.3 + 3.4 * rise) + direction * 4
				rim.Position = heroAt - direction * 4 + UP * 2
			end
			local recoil = if impact > 0
				then math.exp(-impact * 9) * math.sin(impact * 23) * 0.022
				else 0
			placeShot(camera, eye, at, fov, recoil)
			return
		end

		local age = math.max(0, t - COSMIC_BREACH)
		local rise = blend(age / 1.2)
		if t < COSMIC_BREACH then
			at = spot + UP * 0.25
			eye = spot - forward * (15 - t * 2.4) + side * 4 + UP * 1.25
			placeShot(camera, eye, at, 46)
			return
		end
		local travel = blend((age - 0.48) / 5.58)
		local arc = math.sin(math.pi * travel)
		local sweep = (math.sin(travel * 2 * math.pi + math.pi * 0.2) - math.sin(math.pi * 0.2))
			* 3.7
		local heroAt = spot + side * sweep + UP * (-spans.Y * 0.18 + rise * 6.8 + arc * 2.1)
		local yaw = 0.65 - travel * 1.03
		local direction = -forward * math.cos(yaw) + side * math.sin(yaw)
		at = heroAt + UP * (if travel < 0.12 then 0.6 else 0.35)
		eye = at + direction * (17 + 34 * tight + 2.7 * arc) + UP * (-2.6 + rise * 1.5)
		local pose = Framing.pose(bounds, heroAt, eye - heroAt, math.rad(-15) - arc * 0.55)
		local pivot = CFrame.new(heroAt)
			* CFrame.fromAxisAngle(direction, arc * 1.25)
			* CFrame.new(-heroAt)
			* pose
		model:PivotTo(pivot)
		Motion.poseBones(motion, travel * 8)
		if not breach then
			breach = true
			model.Parent = scene
			foam(9, 4)
			Audio.play("cast", 0.26, 0.61)
			Audio.play("bite", 0.24, 0.71)
		end
		if travel > 0.58 and not spray then
			spray = true
			Effects.ripple(spot + side * sweep, accent, 11, 1.6)
			Effects.splash(spot + side * sweep, Color3.fromRGB(165, 224, 255), 12)
		end
		lamp.Position = heroAt + direction * 3
		rim.Position = heroAt - direction * 4 + UP * 2
		placeShot(camera, eye, at, 47 - 3 * rise, -arc * 0.035)
	end

	return { draw = draw, hide = hide }
end

return MysticShots
