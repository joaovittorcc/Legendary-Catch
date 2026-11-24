--!strict
-- Cast cutscene (phase "aiming", flag FishingPower). Same for every result.
--
--   windup  The camera cuts to a low shot in FRONT of the player, looking up at them, with
--           black letterbox bars (HUD hidden). The player readies the rod, then swings it back
--           over the shoulder, twisting the torso and lifting the front foot like a pitcher,
--           and holds that pose (tension tremble, balance sway) while the power bar runs.
--   release On the tap: a small extra pull back (anticipation), an explosive forward strike
--           (front foot plants, back leg extends, torso unwinds, left arm swings back) and a
--           settle with the rod pointing out to sea. The camera keeps the front shot for the
--           strike, then sweeps behind the shoulder toward the water and hands over to the
--           fishing camera.
--
-- The whole body is keyframed here (Line.castTo's own short swing is stopped by the controller
-- while this runs, so the two never fight). Joints are written in PreSimulation on top of the
-- animation (R15 AnimationConstraint or Motor6D; R6 names map to the same keys where they
-- exist). "Reduce effects" keeps the cut and the motion but drops the tremble, sway and drift.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Audio = require(script.Parent.Parent:WaitForChild("Audio"))

local CastCutscene = {}

local player = Players.LocalPlayer
local UP = Vector3.yAxis

-- Euler XYZ offsets (radians) per joint key, on top of the rod-holding animation (its right
-- arm already points forward, RightShoulder X ~ +1.4). +X on a shoulder raises the arm, +X on
-- a hip lifts the thigh forward, -X on a knee bends it, -Y on Waist/Root turns right.
type Pose = { [string]: Vector3 }
type Key = { t: number, pose: Pose, ease: string }

local V = Vector3.new
local READY: Pose = {
	RightShoulder = V(0.35, 0, 0.1),
	RightElbow = V(0.5, 0, 0),
	LeftShoulder = V(0.25, 0, -0.05),
	Waist = V(0.06, 0, 0),
	RightHip = V(0.22, 0, 0),
	LeftHip = V(0.22, 0, 0),
	RightKnee = V(-0.3, 0, 0),
	LeftKnee = V(-0.3, 0, 0),
	RightAnkle = V(0.08, 0, 0),
	LeftAnkle = V(0.08, 0, 0),
}
local COCKED: Pose = { -- rod up and back over the shoulder (out to the side, so it reads
	-- against the sky from the front), front foot up
	RightShoulder = V(1.3, 0, 0.45),
	RightElbow = V(0.6, 0, 0),
	LeftShoulder = V(1.2, 0, -0.18),
	LeftElbow = V(0.3, 0, 0),
	Waist = V(-0.16, -0.5, 0),
	Root = V(-0.05, -0.16, 0),
	Neck = V(0.08, 0.4, 0),
	LeftHip = V(1.15, 0, 0.1),
	LeftKnee = V(-1.35, 0, 0),
	LeftAnkle = V(0.35, 0, 0),
	RightHip = V(0.18, 0, 0),
	RightKnee = V(-0.32, 0, 0),
	RightAnkle = V(0.12, 0, 0),
}
local PULL: Pose = { -- anticipation right before the strike
	RightShoulder = V(1.6, 0, 0.5),
	RightElbow = V(0.8, 0, 0),
	LeftShoulder = V(1.3, 0, -0.2),
	LeftElbow = V(0.25, 0, 0),
	Waist = V(-0.22, -0.62, 0),
	Root = V(-0.07, -0.2, 0),
	Neck = V(0.1, 0.48, 0),
	LeftHip = V(1.3, 0, 0.1),
	LeftKnee = V(-1.45, 0, 0),
	LeftAnkle = V(0.4, 0, 0),
	RightHip = V(0.25, 0, 0),
	RightKnee = V(-0.42, 0, 0),
	RightAnkle = V(0.16, 0, 0),
}
local STRIKE: Pose = { -- follow-through: everything unwinds toward the sea
	RightShoulder = V(-0.62, 0, 0.08),
	RightElbow = V(0.12, 0, 0),
	LeftShoulder = V(-0.55, 0, -0.12),
	LeftElbow = V(0.45, 0, 0),
	Waist = V(0.32, 0.45, 0),
	Root = V(0.12, 0.16, 0),
	Neck = V(-0.12, -0.32, 0),
	LeftHip = V(0.55, 0, 0),
	LeftKnee = V(-0.45, 0, 0),
	LeftAnkle = V(-0.1, 0, 0),
	RightHip = V(-0.38, 0, 0),
	RightKnee = V(-0.22, 0, 0),
	RightAnkle = V(0.32, 0, 0),
}
local SETTLE: Pose = { -- rod held out to sea, weight on the front foot
	RightShoulder = V(-0.18, 0, 0.05),
	RightElbow = V(0.2, 0, 0),
	LeftShoulder = V(-0.1, 0, -0.05),
	LeftElbow = V(0.25, 0, 0),
	Waist = V(0.1, 0.14, 0),
	Root = V(0.04, 0.05, 0),
	Neck = V(-0.04, -0.1, 0),
	LeftHip = V(0.26, 0, 0),
	LeftKnee = V(-0.26, 0, 0),
	RightHip = V(-0.1, 0, 0),
	RightKnee = V(-0.12, 0, 0),
	RightAnkle = V(0.1, 0, 0),
}
local NEUTRAL: Pose = {}

local WINDUP_KEYS: { Key } = {
	{ t = 0, pose = NEUTRAL, ease = "smooth" },
	{ t = 0.3, pose = READY, ease = "smooth" },
	{ t = 0.82, pose = COCKED, ease = "back" },
}
local RELEASE_KEYS: { Key } = {
	{ t = 0, pose = COCKED, ease = "smooth" },
	{ t = 0.1, pose = PULL, ease = "outQuad" },
	{ t = 0.3, pose = STRIKE, ease = "outQuint" },
	{ t = 0.68, pose = SETTLE, ease = "smooth" },
	{ t = 1.1, pose = NEUTRAL, ease = "smooth" },
}
local RELEASE_END = 1.1
-- Line.castTo should launch the bobber at the strike: the controller waits this long after
-- release before starting it (castTo lets go of the bobber 0.14 s after it starts).
CastCutscene.LAUNCH_DELAY = 0.12

local JOINT_KEYS: { [string]: string } = {
	RightShoulder = "RightShoulder",
	["Right Shoulder"] = "RightShoulder",
	RightElbow = "RightElbow",
	LeftShoulder = "LeftShoulder",
	["Left Shoulder"] = "LeftShoulder",
	LeftElbow = "LeftElbow",
	Waist = "Waist",
	Neck = "Neck",
	Root = "Root",
	RightHip = "RightHip",
	["Right Hip"] = "RightHip",
	LeftHip = "LeftHip",
	["Left Hip"] = "LeftHip",
	RightKnee = "RightKnee",
	LeftKnee = "LeftKnee",
	RightAnkle = "RightAnkle",
	LeftAnkle = "LeftAnkle",
}

local CAMERA_IN_SECONDS = 0.6
local FOLLOW_HOLD = 0.3 -- the camera keeps the front shot through the strike
local FOLLOW_SECONDS = 0.85 -- then sweeps behind the shoulder until this
local HOLD_FOV = 55
local BAR_HEIGHT = 0.11 -- letterbox bar, share of the screen height

type Joint = { Transform: CFrame, Parent: Instance? }
type Entry = { joint: Joint, key: string, base: CFrame, applied: CFrame? }

type Run = {
	poseConn: RBXScriptConnection?,
	entries: { Entry },
	started: number,
	releaseAt: number?,
	releaseCf: CFrame?,
	onHandover: (() -> ())?,
	handedOver: boolean,
	cameraBound: boolean,
	oldType: Enum.CameraType?,
	oldFov: number?,
	bars: ScreenGui?,
	hidden: { ScreenGui },
	backpack: boolean,
}

local current: Run? = nil
local RENDER_NAME = "LegendaryCatchCastCutscene"

local function reduced(): boolean
	return player:GetAttribute("ReduceEffects") == true
end

local function ease(kind: string, a: number): number
	a = math.clamp(a, 0, 1)
	if kind == "outQuad" then
		return 1 - (1 - a) * (1 - a)
	elseif kind == "outQuint" then
		return 1 - (1 - a) ^ 5
	elseif kind == "back" then
		local c = 1.5
		local x = a - 1
		return 1 + (c + 1) * x * x * x + c * x * x
	end
	return a * a * (3 - 2 * a)
end

local function smoothstep(a: number): number
	return ease("smooth", a)
end

-- Pose at time t on a key list (holds the last key after the end).
local function sample(keys: { Key }, t: number, joint: string): Vector3
	if t <= keys[1].t then
		return keys[1].pose[joint] or Vector3.zero
	end
	for i = 2, #keys do
		local k = keys[i]
		if t <= k.t then
			local prev = keys[i - 1]
			local a = ease(k.ease, (t - prev.t) / (k.t - prev.t))
			local from = prev.pose[joint] or Vector3.zero
			local to = k.pose[joint] or Vector3.zero
			return from:Lerp(to, a)
		end
	end
	return keys[#keys].pose[joint] or Vector3.zero
end

local function collectJoints(character: Model): { Entry }
	local list: { Entry } = {}
	for _, child in character:GetDescendants() do
		local key = JOINT_KEYS[child.Name]
		if key and (child:IsA("Motor6D") or child.ClassName == "AnimationConstraint") then
			local joint = (child :: any) :: Joint
			table.insert(list, { joint = joint, key = key, base = joint.Transform })
		end
	end
	return list
end

local function makeBars(): ScreenGui
	local screen = Instance.new("ScreenGui")
	screen.Name = "CastLetterbox"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 4 -- under the power bar (7) and the fishing HUD (5)
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	for i, y in { 0, 1 } do
		local bar = Instance.new("Frame")
		bar.Name = if i == 1 then "Top" else "Bottom"
		bar.AnchorPoint = Vector2.new(0, y)
		bar.Size = UDim2.fromScale(1, BAR_HEIGHT)
		bar.Position = UDim2.fromScale(0, if y == 0 then -BAR_HEIGHT else 1 + BAR_HEIGHT)
		bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.BorderSizePixel = 0
		bar.Parent = screen
		TweenService:Create(
			bar,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = UDim2.fromScale(0, y) }
		):Play()
	end
	screen.Parent = player:WaitForChild("PlayerGui")
	return screen
end

local function removeBars(screen: ScreenGui?)
	if not screen then
		return
	end
	for _, bar in screen:GetChildren() do
		if bar:IsA("Frame") then
			local y = bar.AnchorPoint.Y
			TweenService:Create(
				bar,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromScale(0, if y == 0 then -BAR_HEIGHT else 1 + BAR_HEIGHT) }
			):Play()
		end
	end
	task.delay(0.35, function()
		screen:Destroy()
	end)
end

-- The HUD steps aside for the shot (the power bar is created afterwards and stays).
local function hideHud(run: Run)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if gui then
		for _, screen in gui:GetChildren() do
			if screen:IsA("ScreenGui") and screen.Enabled and screen.Name ~= "CastLetterbox" then
				screen.Enabled = false
				table.insert(run.hidden, screen)
			end
		end
	end
	local ok, enabled = pcall(function()
		return StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
	end)
	if ok and enabled then
		run.backpack = true
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
	end
end

local function showHud(run: Run)
	for _, screen in run.hidden do
		if screen.Parent then
			screen.Enabled = true
		end
	end
	table.clear(run.hidden)
	if run.backpack then
		run.backpack = false
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		end)
	end
end

local function stopPose(run: Run)
	local conn = run.poseConn
	run.poseConn = nil
	if conn then
		conn:Disconnect()
	end
	for _, entry in run.entries do
		if entry.joint.Parent and entry.joint.Transform == entry.applied then
			entry.joint.Transform = entry.base
		end
	end
end

local function unbindCamera(run: Run)
	if not run.cameraBound then
		return
	end
	run.cameraBound = false
	RunService:UnbindFromRenderStep(RENDER_NAME)
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = run.oldType or Enum.CameraType.Custom
		if run.oldFov then
			camera.FieldOfView = run.oldFov
		end
	end
end

-- First solid, visible thing between `from` and `to` (invisible colliders do not block a shot).
local function blocked(from: Vector3, to: Vector3, ignore: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local skip = table.clone(ignore)
	for _ = 1, 6 do
		params.FilterDescendantsInstances = skip
		local hit = Workspace:Raycast(from, to - from, params)
		if not hit then
			return false
		end
		if hit.Instance.Transparency < 0.8 then
			return true
		end
		table.insert(skip, hit.Instance)
	end
	return false
end

-- Low shot in front of the player looking up at them; moves around to a front 3/4 if the
-- straight front is blocked.
local function shotFor(root: BasePart): (Vector3, Vector3, Vector3, Vector3)
	local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local forward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local side = forward:Cross(UP).Unit -- the character's right
	-- Whole body in frame (the raised foot and the rod over the shoulder), from a front 3/4 on
	-- the rod side so the rod reads against the sky.
	local look = root.Position + UP * 0.9
	local ignore: { Instance } = { root.Parent :: Instance }
	for _, offset in { 3.5, 6, 1, -3.5 } do
		local position = root.Position + forward * 8.5 + side * offset - UP * 1.3
		if not blocked(look, position, ignore) then
			return position, look, forward, side
		end
	end
	return root.Position + forward * 5 + side * 5 + UP * 1, look, forward, side
end

local function startPoseLoop(run: Run, character: Model)
	local calm = reduced()
	run.poseConn = RunService.PreSimulation:Connect(function()
		if not character.Parent then
			stopPose(run)
			return
		end
		local now = os.clock()
		local releaseAt = run.releaseAt
		local keys: { Key }
		local t: number
		if releaseAt then
			keys, t = RELEASE_KEYS, now - releaseAt
			if t > RELEASE_END then
				stopPose(run)
				return
			end
		else
			keys, t = WINDUP_KEYS, now - run.started
		end
		-- Held tension (only while waiting for the tap): a fast tremble in the casting arm and
		-- a slow balance sway on the raised foot.
		local hold = if releaseAt or calm then 0 else math.clamp((t - 0.82) / 0.4, 0, 1)
		for _, entry in run.entries do
			local joint = entry.joint
			if joint.Parent then
				if joint.Transform ~= entry.applied then
					entry.base = joint.Transform
				end
				local r = sample(keys, t, entry.key)
				if hold > 0 then
					if entry.key == "RightShoulder" then
						r += V(math.sin(t * 31) * 0.014 + math.sin(t * 2.2) * 0.04, 0, 0) * hold
					elseif entry.key == "Root" then
						r += V(0, 0, math.sin(t * 1.7) * 0.035) * hold
					elseif entry.key == "LeftHip" then
						r += V(math.sin(t * 1.7 + 1) * 0.06, 0, 0) * hold
					end
				end
				joint.Transform = entry.base * CFrame.Angles(r.X, r.Y, r.Z)
				entry.applied = joint.Transform
			end
		end
	end)
end

-- Starts the cutscene: camera cut + letterbox + windup and hold. Safe to call twice.
function CastCutscene.windup(character: Model?)
	CastCutscene.stop()
	local camera = Workspace.CurrentCamera
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (camera and character and root and root:IsA("BasePart")) then
		return
	end
	local calm = reduced()
	local run: Run = {
		entries = collectJoints(character),
		started = os.clock(),
		handedOver = false,
		cameraBound = false,
		hidden = {},
		backpack = false,
		oldType = camera.CameraType,
		oldFov = camera.FieldOfView,
	}
	current = run
	startPoseLoop(run, character)

	local position, look, forward, side = shotFor(root)
	local baseFov = run.oldFov or 70
	camera.CameraType = Enum.CameraType.Scriptable
	run.cameraBound = true
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		if not root.Parent then
			return
		end
		local now = os.clock()
		local releaseAt = run.releaseAt
		if releaseAt then
			local a = (now - releaseAt - FOLLOW_HOLD) / (FOLLOW_SECONDS - FOLLOW_HOLD)
			if a >= 1 then
				CastCutscene.finish()
				return
			end
			-- Front shot through the strike, then orbit around the rod side (never through the
			-- character) up behind the shoulder, looking where the bobber flies.
			local e = smoothstep(a)
			local from = (run.releaseCf or camera.CFrame).Position - root.Position
			local behind = -forward * 7.5 + side * 2.2 + UP * 4.6
			local function yawOf(v: Vector3): number
				return math.atan2(v:Dot(side), v:Dot(forward))
			end
			local yawFrom, yawTo = yawOf(from), yawOf(behind)
			-- go around through the rod side (+side)
			if yawTo < yawFrom then
				yawTo += math.pi * 2
			end
			local yaw = yawFrom + (yawTo - yawFrom) * e
			local flatFrom = (from * Vector3.new(1, 0, 1)).Magnitude
			local flatTo = (behind * Vector3.new(1, 0, 1)).Magnitude
			local radius = flatFrom + (flatTo - flatFrom) * e
			local height = from.Y + (behind.Y - from.Y) * e
			local pos = root.Position
				+ (forward * math.cos(yaw) + side * math.sin(yaw)) * radius
				+ UP * height
			local target = (root.Position + UP * 0.9):Lerp(
				root.Position + forward * 16 + UP * 0.5,
				e
			)
			camera.CFrame = CFrame.lookAt(pos, target)
			camera.FieldOfView = HOLD_FOV + (baseFov - HOLD_FOV) * e
			camera.Focus = CFrame.new(target)
			return
		end
		local t = now - run.started
		local drift = if calm then 0 else math.min(t, 5)
		-- Slow push-in and a slight orbit, so the hold never feels frozen.
		local pos = position - forward * (drift * 0.3) + side * (drift * 0.22) + UP * (drift * 0.04)
		local roll = if calm then 0 else math.rad(3)
		local goal = CFrame.lookAt(pos, look) * CFrame.Angles(0, 0, roll)
		-- Hard cut (a glide from the play camera would cross posts and rails), a slow zoom in.
		local a = smoothstep(t / CAMERA_IN_SECONDS)
		camera.CFrame = goal
		camera.FieldOfView = HOLD_FOV + 6 * (1 - a)
		camera.Focus = CFrame.new(look)
	end)

	hideHud(run)
	run.bars = makeBars()
	-- the cut comes in from black
	local bars = run.bars
	if bars then
		local fade = Instance.new("Frame")
		fade.Name = "CutFade"
		fade.Size = UDim2.fromScale(1, 1)
		fade.BackgroundColor3 = Color3.new(0, 0, 0)
		fade.BackgroundTransparency = 0
		fade.BorderSizePixel = 0
		fade.ZIndex = 0
		fade.Parent = bars
		local tween = TweenService:Create(fade, TweenInfo.new(0.28), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Once(function()
			fade:Destroy()
		end)
	end
	task.delay(0.3, function()
		if current == run and not run.releaseAt then
			Audio.play("cast", 0.3, 0.55) -- slow swing back
		end
	end)
end

-- The throw (on the tap or the bar's timeout): anticipation, strike and settle; the camera
-- follows, then `onHandover` runs (start the fishing camera there: it glides on from this
-- shot), the HUD comes back and the bars slide out.
function CastCutscene.release(onHandover: (() -> ())?)
	local run = current
	if not run or run.releaseAt then
		if onHandover then
			onHandover()
		end
		return
	end
	run.releaseAt = os.clock()
	run.onHandover = onHandover
	local camera = Workspace.CurrentCamera
	run.releaseCf = camera and camera.CFrame
	task.delay(0.1, function()
		Audio.play("cast", 0.65, 1.25) -- the strike
	end)
	if reduced() or not run.cameraBound then
		CastCutscene.finish()
	end
end

-- Ends the camera part now (a bite came early, or the follow ran out) and hands over; the
-- body keeps finishing its throw.
function CastCutscene.finish()
	local run = current
	if not run or not run.releaseAt or run.handedOver then
		return
	end
	run.handedOver = true
	unbindCamera(run)
	showHud(run)
	local bars = run.bars
	run.bars = nil
	removeBars(bars)
	local handover = run.onHandover
	run.onHandover = nil
	if handover then
		handover()
	end
	local releaseAt = run.releaseAt or os.clock()
	task.delay(math.max(0, RELEASE_END + 0.05 - (os.clock() - releaseAt)), function()
		if current == run then
			stopPose(run)
			current = nil
		end
	end)
end

-- Cancels everything at once (cancel, death, unequip).
function CastCutscene.stop()
	local run = current
	current = nil
	if not run then
		return
	end
	stopPose(run)
	unbindCamera(run)
	showHud(run)
	local bars = run.bars
	run.bars = nil
	removeBars(bars)
end

-- True from the press until the tap (the hold is on screen).
function CastCutscene.active(): boolean
	return current ~= nil and current.releaseAt == nil
end

-- True while the throw is playing (after the tap, before the body is back to normal).
function CastCutscene.throwing(): boolean
	return current ~= nil and current.releaseAt ~= nil
end

return CastCutscene
