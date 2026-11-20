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
local Card = require(script.Parent.RevealCard)
local Photo = require(script.Parent.PhotoMode)
local Recipes = require(script.Recipes)
local Beats = require(script.Beats)

local Cinematics = { recipes = Recipes }
local FIRST_SKIP = 2
local REDUCED_DURATION = 3.25
local EMERGENCE = 1.15
local FOV = 36
local VIEWER = Vector3.new(0, 0.12, 1)
local AXES = CFrame.lookAt(Vector3.zero, -VIEWER)
local FULL = Rect.new(0.04, 0.04, 0.96, 0.96)

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
	local bounds = Framing.measure(model)
	local base = Framing.pose(bounds, Vector3.zero, VIEWER)
	local motion = Motion.bind(model, motif)
	model:PivotTo(base)
	model.Parent = hero
	hero.Parent = canvas
	hero.ZIndex = 3
	gui.Parent = player:WaitForChild("PlayerGui")

	local skipped, photo = false, false
	local skip = Card.action(gui, "SkipReveal", Text.skip, tint)
	skip.Visible = repeatView
	skip.Activated:Connect(function()
		skipped = true
	end)
	local card: Card.Card? = nil
	local reduced = player:GetAttribute("ReduceEffects") == true
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
				reduced = true
				Motion.reset(motion, base)
				start = now
				t = 0
			end
			local entrance = if reduced then 0 else recipe.entrance
			local duration = if reduced then REDUCED_DURATION else recipe.duration
			local age = t - entrance
			local progress = math.clamp(age / (if reduced then 0.28 else EMERGENCE), 0, 1)
			local settle = 1 - (1 - progress) ^ 3
			skip.Visible = repeatView or now - firstFrame >= FIRST_SKIP
			if camera and not reduced then
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
					local padding = if id == "C93_Ouroboros_Cosmico" then 1.24 else 1.02
					fit = Framing.camera(bounds, base, AXES, Vector3.zero, area, FOV, FULL, padding)
				end
			end
			local shade = if reduced
				then settle
				else 0.55 * math.min(t / 1.35, 1) + 0.45 * math.clamp((age + 1.4) / 1.65, 0, 1)
			sky.BackgroundTransparency = 1 - shade
			if not reduced then
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
			if age >= 0 then
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
				if card == nil and (reduced or progress >= 0.55) then
					Audio.capture(rarity, info ~= nil and info.variant == "Shiny")
					card = Card.open(gui, clone(id), id, name, rarity, tint, info, reduced)
					local button = Card.action(gui, "TakePhoto", Text.photo, recipe.light)
					button.Activated:Connect(function()
						photo = true
					end)
				end
				if card and not reduced then
					card.preview(age)
				end
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
	if card then
		card.close(true)
	end
	world:Destroy()
	gui:Destroy()
	if camera then
		camera.CFrame = oldCF
		camera.Focus = oldFocus
		camera.CameraType = oldType
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
