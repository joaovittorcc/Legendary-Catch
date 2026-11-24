--!strict
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Text = require(ReplicatedStorage.Shared.StringsUi)
local Audio = require(script.Parent.Parent.Audio)
local Motion = require(script.Parent.Parent.CreatureMotion)
local Framing = require(script.Parent.RevealFraming)
local Mutation = require(script.Parent.RevealMutation)
local Card = require(script.Parent.RevealCard)
local Photo = require(script.Parent.PhotoMode)
local Recipes = require(script.Recipes)
local Beats = require(script.Beats)
local MysticShots = require(script.MysticShots)

local Cinematics = { recipes = Recipes }
local FIRST_SKIP = 2
local REDUCED_DURATION = 3.25
local EMERGENCE = 1.15
local FOV = 36
local VIEWER = Vector3.new(0, 0.12, 1)
local AXES = CFrame.lookAt(Vector3.zero, -VIEWER)
local FULL = Rect.new(0.04, 0.04, 0.96, 0.96)
local HANDOFF_FADE = 0.65
local FINAL_FOV = 52

local function frame(parent: Instance, name: string): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

function Cinematics.play(
	recipe: Recipes.Recipe,
	id: string,
	name: string,
	rarity: string,
	tint: Color3,
	motif: string,
	origin: Vector3,
	root: BasePart,
	info: Card.CatchInfo?,
	repeatView: boolean,
	clone: (string) -> Model
): boolean
	local player = Players.LocalPlayer
	local camera = Workspace.CurrentCamera
	local character = root.Parent
	local hum = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local gui = Instance.new("ScreenGui")
	gui.Name = "CatchCinema"
	gui.DisplayOrder = 90
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.ClipToDeviceSafeArea = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ResetOnSpawn = false

	local canvas = frame(gui, "Backdrop")
	canvas.ZIndex = 0
	local sky = frame(canvas, "Sky")
	sky.ZIndex = 0
	sky.AnchorPoint = Vector2.new(0.5, 0.5)
	sky.Position = UDim2.fromScale(0.5, 0.5)
	sky.Size = UDim2.fromScale(1.6, 1.5)
	sky.BackgroundColor3 = Color3.new(1, 1, 1)
	local grade = Instance.new("UIGradient")
	grade.Color = ColorSequence.new(
		Color3.fromRGB(10, 15, 38),
		recipe.accent:Lerp(Color3.fromRGB(9, 16, 35), 0.72)
	)
	grade.Rotation = -24
	grade.Parent = sky
	local stage = frame(canvas, "PortalStage")
	stage.AnchorPoint = Vector2.new(0.5, 0.5)
	local dial = frame(stage, "Dial")
	local drawHalo = Beats.halo(dial, recipe)
	dial.Visible = false
	local reduced = player:GetAttribute("ReduceEffects") == true
	local world = Instance.new("Folder")
	world.Name = "CatchCinemaWater"
	world.Parent = Workspace

	-- One hero viewport and camera for both the silhouette and the face-first hold.
	local hero = Instance.new("ViewportFrame")
	hero.Name = "ForegroundCreature"
	hero.BackgroundTransparency = 1
	hero.AnchorPoint = Vector2.new(0.5, 0.5)
	hero.Ambient = Color3.fromRGB(177, 172, 195)
	hero.LightColor = Color3.fromRGB(255, 245, 221)
	hero.LightDirection = Vector3.new(-0.65, -0.7, -1)
	hero.Visible = false
	local lens = Instance.new("Camera")
	lens.FieldOfView = FOV
	lens.Parent = hero
	hero.CurrentCamera = lens
	local model = clone(id)
	local visualScale = Mutation.scale(info and info.sizeMult)
	local smallModelPadding = if visualScale < 1 then 1.18 else 1
	local mutation = info and info.mutation
	local modified = visualScale ~= 1 or Mutation.color(mutation) ~= nil
	if visualScale ~= 1 then
		model:ScaleTo(model:GetScale() * visualScale)
	end
	local bounds = Framing.measure(model)
	local extent = model:GetExtentsSize()
	local paintMutation = Mutation.paint(model, mutation)
	local drawMutation = Mutation.viewport(hero, mutation)
	local mutationSparks = Mutation.particles(model, mutation)
	local base = Framing.pose(bounds, Vector3.zero, VIEWER)
	local motion = Motion.bind(model, motif)
	model:PivotTo(base)
	local viewportWorld = Instance.new("WorldModel")
	viewportWorld.Name = "CreatureStage"
	viewportWorld.Parent = hero
	model.Parent = viewportWorld
	hero.Parent = canvas
	hero.ZIndex = 3
	local kind = recipe.mysticShot
	local handoff = recipe.handoff
	gui.Parent = player:WaitForChild("PlayerGui")

	local skipped, photo = false, false
	local skip = Card.action(gui, "SkipReveal", Text.skip, tint)
	skip.Visible = repeatView
	skip.Activated:Connect(function()
		skipped = true
	end)
	local card: Card.Card? = nil
	local active: { [number]: Beats.Beat } = {}
	local cameraMotion: Beats.CameraMotion = { push = 0, roll = 0, speed = 1 }
	local nextCue = 1
	local function clearBeats()
		for _, beat in active do
			beat.close()
		end
		table.clear(active)
		stage.Rotation = 0
	end
	local oldControls = GuiService.TouchControlsEnabled
	local oldActive = player:GetAttribute("CatchRevealActive")
	local oldType, oldCF, oldFocus = Enum.CameraType.Custom, CFrame.identity, CFrame.identity
	local oldFov = if camera then camera.FieldOfView else FINAL_FOV
	if camera then
		oldType, oldCF, oldFocus = camera.CameraType, camera.CFrame, camera.Focus
		if not reduced then
			camera.CameraType = Enum.CameraType.Scriptable
		end
	end
	GuiService.TouchControlsEnabled = false
	player:SetAttribute("CatchRevealActive", true)
	local forward = (origin - root.Position) * Vector3.new(1, 0, 1)
	forward = if forward.Magnitude > 0.1 then forward.Unit else Vector3.zAxis
	local waterShot =
		CFrame.lookAt(origin - forward * 24 + Vector3.yAxis * 8, origin + Vector3.yAxis * 2)
	local right = Vector3.new(forward.Z, 0, -forward.X)
	local mystic: MysticShots.Shot? = nil
	local finale = false
	local cameraRay = RaycastParams.new()
	cameraRay.FilterType = Enum.RaycastFilterType.Exclude
	cameraRay.FilterDescendantsInstances = { root.Parent or root, world }
	cameraRay.IgnoreWater = true
	cameraRay.RespectCanCollide = true
	local function showCatch(size: Vector2, age: number)
		if not camera then
			return
		end
		if not finale then
			finale = true
			clearBeats()
			if mystic then
				mystic.hide()
			end
			hero.Visible = false
			dial.Visible = false
			model.Parent = world
		end
		local aspect = size.X / math.max(1, size.Y)
		local portrait = aspect < 1
		local shoulder = root.Position
			+ right * (if portrait then 2.45 else 3.1)
			+ forward * 0.7
			+ Vector3.yAxis * 0.66
		if visualScale ~= 1 and size.X > 1 and size.Y > 1 then
			local clearance = math.max(0, extent.Y / 2 - 0.66)
			local center = shoulder + forward * clearance + Vector3.yAxis * clearance
			local facing = forward + right * 0.18 + Vector3.yAxis * 0.18
			local pose = Framing.pose(bounds, center, facing)
			local axes = CFrame.lookAt(Vector3.zero, -facing)
			model:PivotTo(pose)
			Motion.poseBones(motion, 8 + age * 0.45)
			camera.CFrame = Framing.camera(
				bounds,
				pose,
				axes,
				center,
				size,
				FINAL_FOV,
				Card.subjectRegion(size),
				1.24 * smallModelPadding
			)
			camera.Focus = CFrame.new(center)
			camera.FieldOfView = FINAL_FOV
			return
		end
		local halfHeight = math.tan(math.rad(FINAL_FOV) / 2)
		local distance = math.max(
			13,
			(if portrait then 4.5 else 3.3) / (halfHeight * math.max(0.4, aspect) * 0.8)
		)
		local center = root.Position:Lerp(shoulder, 0.49)
		local aim = center
			+ Vector3.yAxis * (if portrait then -distance * halfHeight * 0.27 else 0.08)
			- right * (if portrait then 0 else distance * halfHeight * aspect * 0.21)
		local pull = distance - math.clamp(age / 3, 0, 1) * 0.38
		local eye = aim + forward * pull + Vector3.yAxis * 4.3
		if Workspace:Raycast(center, eye - center, cameraRay) then
			local leftEye = eye - right * 4.1
			local rightEye = eye + right * 4.1
			if not Workspace:Raycast(center, leftEye - center, cameraRay) then
				eye = leftEye
			elseif not Workspace:Raycast(center, rightEye - center, cameraRay) then
				eye = rightEye
			else
				eye += Vector3.yAxis * 3.5
			end
		end
		local facing = if kind == "tide" then eye - shoulder else forward
		local turn = if kind == "tide" then math.rad(-12) else 0
		model:PivotTo(Framing.pose(bounds, shoulder, facing, turn))
		Motion.poseBones(motion, 8 + age * 0.45)
		camera.CFrame = CFrame.lookAt(eye, aim)
		camera.Focus = CFrame.new(center)
		camera.FieldOfView = FINAL_FOV
	end
	local start = os.clock()
	local firstFrame = start
	local lastTime, poseTime = start, 0
	local previousSize = Vector2.zero
	local fit = CFrame.identity
	local completed = false
	local function alive(): boolean
		return player.Parent ~= nil
			and root:IsDescendantOf(Workspace)
			and (hum == nil or hum.Health > 0)
			and gui.Parent ~= nil
	end
	local function run()
		if kind and not modified and not reduced and camera then
			mystic = MysticShots.create(world, kind, id, origin, forward, character or root, clone)
		end
		if not reduced then
			Audio.play("legendary", 0.24, 0.74)
		end
		while alive() and not skipped and not photo do
			local now = os.clock()
			local delta = now - lastTime
			lastTime = now
			local t = now - start
			if not reduced and player:GetAttribute("ReduceEffects") == true then
				clearBeats()
				if mystic then
					mystic.hide()
				end
				reduced = true
				if finale then
					model.Parent = viewportWorld
					finale = false
				end
				previousSize = Vector2.zero
				if camera then
					camera.CFrame = oldCF
					camera.Focus = oldFocus
					camera.CameraType = oldType
					camera.FieldOfView = oldFov
				end
				Motion.reset(motion, base)
				start = now
				t = 0
			end
			local entrance = if reduced then 0 else recipe.entrance
			local duration = if reduced then REDUCED_DURATION else recipe.duration
			local age = t - entrance
			local worldAge = if handoff and not reduced and camera then t - handoff else -1
			local progress = math.clamp(age / (if reduced then 0.28 else EMERGENCE), 0, 1)
			local settle = 1 - (1 - progress) ^ 3
			skip.Visible = repeatView or now - firstFrame >= FIRST_SKIP
			if camera and not reduced and not mystic then
				camera.CFrame = oldCF:Lerp(waterShot, math.min(t / 0.6, 1))
					* CFrame.new(0, 0, -cameraMotion.push)
					* CFrame.Angles(0, 0, cameraMotion.roll)
				camera.Focus = CFrame.new(origin)
			end
			local size = gui.AbsoluteSize
			if size.X > 1 and size.Y > 1 then
				local region = Card.subjectRegion(size)
				local center = (region.Min + region.Max) / 2
				local intro = Vector2.new(0.5, 0.49)
				local position = intro:Lerp(center, if reduced then 1 else settle)
				local area = Vector2.new(region.Width * size.X, region.Height * size.Y)
				local diameter = math.min(area.X, area.Y) * 1.12
				stage.Position = UDim2.fromScale(position.X, position.Y)
				stage.Size = UDim2.fromScale(diameter / size.X, diameter / size.Y)
				hero.Position = stage.Position
				hero.Size = UDim2.fromScale(region.Width, region.Height)
				if size ~= previousSize then
					previousSize = size
					local padding = if kind == "orbit" then 1.28 else 1.02
					fit = Framing.camera(
						bounds,
						base,
						AXES,
						Vector3.zero,
						area,
						FOV,
						FULL,
						padding * smallModelPadding
					)
				end
			end
			local shade = if worldAge >= 0
				then 1 - math.clamp(worldAge / HANDOFF_FADE, 0, 1)
				elseif mystic and handoff and not reduced then math.max(
					1 - math.clamp(t / 0.45, 0, 1),
					math.clamp((t - handoff + 0.25) / 0.25, 0, 1)
				)
				elseif reduced then settle
				else 0.55 * math.min(t / 1.35, 1) + 0.45 * math.clamp((age + 1.4) / 1.65, 0, 1)
			if paintMutation then
				paintMutation(math.max(age, 0), reduced)
			end
			if drawMutation then
				drawMutation(age, hero.Visible and worldAge < 0 and not reduced and progress > 0.4)
			end
			if mutationSparks then
				if worldAge < 0 and mutationSparks.Enabled then
					mutationSparks:Clear()
				end
				mutationSparks.Enabled = worldAge >= 0
			end
			sky.BackgroundTransparency = 1 - shade
			if worldAge >= 0 then
				showCatch(size, worldAge)
			elseif mystic and camera and not reduced then
				mystic.draw(t, camera, size)
			elseif not reduced then
				while nextCue <= #recipe.cues and recipe.cues[nextCue].at <= t do
					local cue = recipe.cues[nextCue]
					if t < cue.at + cue.duration then
						active[nextCue] =
							Beats.start(cue, recipe, canvas, stage, world, origin, cameraMotion)
					end
					nextCue += 1
				end
				for index, beat in active do
					local cue = recipe.cues[index]
					local p = (t - cue.at) / cue.duration
					if p >= 1 then
						beat.draw(1)
						beat.close()
						active[index] = nil
					else
						beat.draw(p)
					end
				end
			end
			if age >= 0 and worldAge < 0 and (not mystic or reduced) then
				hero.Visible = true
				hero.ImageTransparency = if reduced then 1 - settle else 0
				hero.ImageColor3 = Color3.fromRGB(31, 24, 51)
					:Lerp(Color3.new(1, 1, 1), if reduced then 1 else progress ^ 1.4)
				lens.CFrame = fit
					* CFrame.new(
						0,
						0,
						if reduced then 0 else (1 - settle) * fit.Position.Magnitude * 3.2
					)
				if not reduced then
					poseTime += delta * cameraMotion.speed
					Motion.pose(motion, base, poseTime, false)
				end
				dial.Visible = true
				drawHalo(if reduced then 0 else age, settle)
			end
			local cardReady = if handoff and camera
				then worldAge >= HANDOFF_FADE * 0.55
				else progress >= 0.55
			if age >= 0 and card == nil and (reduced or cardReady) then
				Audio.capture(rarity, info ~= nil and info.variant == "Shiny")
				card = Card.open(gui, clone(id), id, name, rarity, tint, info, reduced)
				local button = Card.action(gui, "TakePhoto", Text.photo, recipe.light)
				button.Activated:Connect(function()
					photo = true
				end)
			end
			if card and not reduced then
				card.preview(if worldAge >= 0 then worldAge else age)
			end
			if t >= duration then
				completed = true
				break
			end
			RunService.RenderStepped:Wait()
		end
		return true
	end
	local ok, err = pcall(run)
	local takePhoto = ok and photo and alive()
	if takePhoto then
		model.Parent = nil
	end
	clearBeats()
	if mystic then
		mystic.hide()
	end
	if card then
		card.close(true)
	end
	world:Destroy()
	gui:Destroy()
	if camera then
		camera.CFrame = oldCF
		camera.Focus = oldFocus
		camera.CameraType = oldType
		camera.FieldOfView = oldFov
	end
	GuiService.TouchControlsEnabled = oldControls
	player:SetAttribute("CatchRevealActive", oldActive)
	if takePhoto then
		local display = root.Position + forward * 12 + Vector3.yAxis * 4
		local pose = Framing.pose(bounds, display, -forward)
		Motion.reset(motion, pose)
		model:PivotTo(pose)
		model.Parent = Workspace
		local photoOK, photoError = pcall(function()
			Photo.show(model, root, name, rarity, tint, pose:VectorToWorldSpace(bounds.forward))
			return true
		end)
		model:Destroy()
		if not photoOK then
			error(photoError)
		end
	end
	if not ok then
		error(err)
	end
	return completed or skipped or takePhoto
end
return Cinematics
