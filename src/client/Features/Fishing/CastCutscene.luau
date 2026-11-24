--!strict
-- Cast cutscene (phase "aiming", flag FishingPower): the moment the player presses to fish,
-- the camera cuts to a low cinematic 3/4 shot from the rod side, black letterbox bars slide in
-- and the character pulls the rod back over the shoulder and holds it there, trembling a
-- little with tension, while the power bar runs. When the tap lands (or the bar times out)
-- `release` eases the hold off exactly while Line.castTo's swing takes over, so the rod goes
-- straight from the hold into the throw, and the fishing camera glides from this shot to its
-- own. Same cutscene for every result; the tap never changes it.
--
-- Joints are written in PreSimulation on top of the animation (R15 AnimationConstraint or
-- Motor6D), like AvatarVisuals/Pose: the same technique, so it composes with Line's pose.
-- "Reduce effects" keeps the cut and the pose but drops the drift and the tremble.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local CastCutscene = {}

local player = Players.LocalPlayer
local UP = Vector3.yAxis

-- Hold pose (radians), on top of the rod-holding animation (its right arm points forward,
-- RightShoulder X ~ +1.4). +X raises the arm further: the hold lifts it overhead so the rod
-- points up and back over the shoulder, torso twisted so the right shoulder goes back (-Y).
-- On release this eases to zero while Line.castTo swings -0.82 then +0.96: the sum is an
-- overhead throw coming down toward the water.
local HOLD: { [string]: CFrame } = {
	RightShoulder = CFrame.Angles(1.55, 0, 0.18),
	RightElbow = CFrame.Angles(0.7, 0, 0),
	LeftShoulder = CFrame.Angles(1.15, 0, -0.15),
	LeftElbow = CFrame.Angles(0.35, 0, 0),
	Waist = CFrame.Angles(-0.12, -0.32, 0),
	Neck = CFrame.Angles(0.05, 0.22, 0),
	Root = CFrame.Angles(0, -0.1, 0),
}
local JOINT_NAMES: { [string]: string } = {
	RightShoulder = "RightShoulder",
	["Right Shoulder"] = "RightShoulder",
	RightElbow = "RightElbow",
	LeftShoulder = "LeftShoulder",
	["Left Shoulder"] = "LeftShoulder",
	LeftElbow = "LeftElbow",
	Waist = "Waist",
	Neck = "Neck",
	Root = "Root",
}
local WINDUP_SECONDS = 0.42 -- pull back
-- Line.castTo pulls back for 0.14 s first; easing ours off over the same time keeps the sum
-- steady, then its forward swing is the throw.
local RELEASE_SECONDS = 0.14
local CAMERA_IN_SECONDS = 0.55
-- After the tap the cinematic camera follows the throw this long (pulls back and up behind the
-- shoulder, toward the water) before the fishing camera takes over from there.
local FOLLOW_SECONDS = 0.5
local BAR_HEIGHT = 0.11 -- letterbox bar, share of the screen height

type Joint = { Transform: CFrame, Parent: Instance? }
type Entry = { joint: Joint, key: string, base: CFrame, applied: CFrame? }

type Run = {
	hidden: { ScreenGui },
	backpack: boolean,
	poseConn: RBXScriptConnection?,
	entries: { Entry },
	weight: () -> number,
	releaseAt: number?,
	releaseCf: CFrame?, -- camera when the throw started
	onHandover: (() -> ())?,
	handedOver: boolean,
	cameraBound: boolean,
	oldType: Enum.CameraType?,
	oldFov: number?,
	bars: ScreenGui?,
}

local current: Run? = nil
local RENDER_NAME = "LegendaryCatchCastCutscene"

local function reduced(): boolean
	return player:GetAttribute("ReduceEffects") == true
end

local function smoothstep(a: number): number
	a = math.clamp(a, 0, 1)
	return a * a * (3 - 2 * a)
end

local function backOut(a: number): number
	a = math.clamp(a, 0, 1)
	local c = 1.4
	local x = a - 1
	return 1 + (c + 1) * x * x * x + c * x * x
end

local function collectJoints(character: Model): { Entry }
	local list: { Entry } = {}
	for _, child in character:GetDescendants() do
		local key = JOINT_NAMES[child.Name]
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

local function unbindCamera(run: Run, restore: boolean)
	if not run.cameraBound then
		return
	end
	run.cameraBound = false
	RunService:UnbindFromRenderStep(RENDER_NAME)
	local camera = Workspace.CurrentCamera
	if camera and restore then
		camera.CameraType = run.oldType or Enum.CameraType.Custom
		if run.oldFov then
			camera.FieldOfView = run.oldFov
		end
	end
end

-- Picks a low 3/4 shot from the rod side; falls back to the other side if something
-- (posts, rocks, the shop) is between the camera and the character.
local function shotFor(root: BasePart): (Vector3, Vector3, Vector3, Vector3)
	local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local forward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local side = forward:Cross(UP).Unit -- the character's right: the rod hand
	-- Profile from the rod side, a little ahead of the character: the rod held back reads as a
	-- clear silhouette against the sky, with the water it is about to fly to in frame.
	local look = root.Position + UP * 2.1 + forward * 1.4
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { root.Parent :: Instance }
	params.IgnoreWater = true
	for _, sign in { 1, -1 } do
		local position = root.Position + forward * 2.2 + side * (9.5 * sign) + UP * 1.1
		local hit = Workspace:Raycast(look, position - look, params)
		if not hit then
			return position, look, forward, side * sign
		end
	end
	-- Both sides blocked: over the shoulder, close.
	return root.Position - forward * 5 + side * 2.5 + UP * 3, look + forward * 4, forward, side
end

-- Starts the cutscene: camera cut + letterbox + pull-back hold. Safe to call twice.
function CastCutscene.windup(character: Model?)
	CastCutscene.stop()
	local camera = Workspace.CurrentCamera
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (camera and character and root and root:IsA("BasePart")) then
		return
	end
	local calm = reduced()
	local started = os.clock()
	local run: Run = {
		entries = collectJoints(character),
		weight = function()
			return 0
		end,
		cameraBound = false,
		hidden = {},
		handedOver = false,
		backpack = false,
		oldType = camera.CameraType,
		oldFov = camera.FieldOfView,
	}
	current = run

	-- Pose: back-eased pull, then a held tension tremble.
	run.weight = function(): number
		local now = os.clock()
		local w = backOut((now - started) / WINDUP_SECONDS)
		local releaseAt = run.releaseAt
		if releaseAt then
			local a = (now - releaseAt) / RELEASE_SECONDS
			w *= 1 - math.sin(math.clamp(a, 0, 1) * math.pi / 2)
		end
		return w
	end
	run.poseConn = RunService.PreSimulation:Connect(function()
		if not character.Parent then
			stopPose(run)
			return
		end
		local w = run.weight()
		local now = os.clock()
		local t = now - started
		if run.releaseAt and now - run.releaseAt > RELEASE_SECONDS + 0.2 then
			stopPose(run)
			return
		end
		local shake = if calm or run.releaseAt then 0 else math.min(1, t / 0.6)
		for _, entry in run.entries do
			local joint = entry.joint
			if joint.Parent then
				if joint.Transform ~= entry.applied then
					entry.base = joint.Transform
				end
				local offset = HOLD[entry.key] or CFrame.identity
				local rx, ry, rz = offset:ToEulerAnglesXYZ()
				if entry.key == "RightShoulder" or entry.key == "Waist" then
					-- Tension: a small fast tremble and a slow breath on the hold.
					rx += (math.sin(t * 31) * 0.012 + math.sin(t * 2.4) * 0.03) * shake
				end
				joint.Transform = entry.base * CFrame.Angles(rx * w, ry * w, rz * w)
				entry.applied = joint.Transform
			end
		end
	end)

	-- Camera: glide from wherever it is to the low shot, then a slow push-in.
	local fromCf = camera.CFrame
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
			local a = (now - releaseAt) / FOLLOW_SECONDS
			if a >= 1 then
				CastCutscene.finish()
				return
			end
			-- Follow the throw: behind and above the shoulder, looking where the bobber goes.
			local behind = root.Position - forward * 7.5 + side * 2.2 + UP * 4.6
			local target = root.Position + forward * 16 + UP * 0.5
			local e = smoothstep(a)
			local from = run.releaseCf or camera.CFrame
			camera.CFrame = from:Lerp(CFrame.lookAt(behind, target), e)
			camera.FieldOfView = 56 + (baseFov - 56) * e
			camera.Focus = CFrame.new(target)
			return
		end
		local t = now - started
		local drift = if calm then 0 else math.min(t, 4)
		-- Slow dolly toward the character and a slight orbit, so the hold never feels frozen.
		local pos = position
			- forward * (drift * 0.25)
			- side * (drift * 0.35)
			+ UP * (drift * 0.06)
		local roll = if calm then 0 else math.rad(-4)
		local goal = CFrame.lookAt(pos, look) * CFrame.Angles(0, 0, roll)
		local a = smoothstep(t / CAMERA_IN_SECONDS)
		camera.CFrame = fromCf:Lerp(goal, a)
		camera.FieldOfView = baseFov + (56 - baseFov) * a
		camera.Focus = CFrame.new(look)
	end)

	hideHud(run)
	run.bars = makeBars()
end

-- The throw: eases the hold off while Line.castTo's swing starts, and the camera follows the
-- throw for FOLLOW_SECONDS. Then `onHandover` runs (start the fishing camera there: it glides
-- on from this shot), the HUD comes back and the bars slide out.
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
	if reduced() or not run.cameraBound then
		CastCutscene.finish()
	end
end

-- Ends the follow shot now (a bite came early, or the follow ran out) and hands over.
function CastCutscene.finish()
	local run = current
	if not run or not run.releaseAt or run.handedOver then
		return
	end
	run.handedOver = true
	unbindCamera(run, true)
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
	task.delay(math.max(0, RELEASE_SECONDS + 0.25 - (os.clock() - releaseAt)), function()
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
	unbindCamera(run, true)
	showHud(run)
	local bars = run.bars
	run.bars = nil
	removeBars(bars)
end

function CastCutscene.active(): boolean
	return current ~= nil and current.releaseAt == nil
end

return CastCutscene
