--!strict
-- Lagoon training (client): plays the semi-idle session the server runs.
--   * slow orbit camera around the player, cheer animation loop, rising aura
--   * HUD with stat, level, XP bar and a Stop button
--   * occasional rhythm ring for bonus XP (reuses the fishing rhythm minigame)
-- Walking stops training (the server also stops it if the player leaves the spot).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))

local FishingFolder = script.Parent:WaitForChild("Fishing")
local Effects = require(FishingFolder:WaitForChild("Effects"))
local PressInput = require(FishingFolder:WaitForChild("PressInput"))
local Rhythm = require(FishingFolder:WaitForChild("Minigames"):WaitForChild("Rhythm"))
local Ui = require(FishingFolder:WaitForChild("Ui"))

local STAT_COLORS: { [string]: Color3 } = {
	Control = Color3.fromRGB(90, 220, 255),
	Instinct = Color3.fromRGB(200, 140, 255),
}

local Training = {}

local player = Players.LocalPlayer
local stopRemote: RemoteEvent
local ringRemote: RemoteEvent

local activeStat = ""
local hud: Frame? = nil
local levelLabel: TextLabel? = nil
local xpFill: Frame? = nil
local orbitConn: RBXScriptConnection? = nil
local moveConn: RBXScriptConnection? = nil
local animThread: thread? = nil
local animationTrack: AnimationTrack? = nil
local previousCameraType: Enum.CameraType? = nil
local aura: BasePart? = nil
local stopRing: (() -> ())? = nil

local function rootPart(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function attrNumber(name: string): number
	local v = player:GetAttribute(name)
	return if typeof(v) == "number" then v else 0
end

local function refreshHud()
	local label, fill = levelLabel, xpFill
	if activeStat == "" or not label or not fill then
		return
	end
	local lvl = attrNumber(TrainingConfig.levelAttribute(activeStat))
	local name = Strings.stat[activeStat] or activeStat
	if lvl >= TrainingConfig.MAX_LEVEL then
		label.Text = `{Strings.training} {name} — {Strings.maxLevel}`
		fill.Size = UDim2.fromScale(1, 1)
		return
	end
	label.Text = `{Strings.training} {name} — {Strings.level} {lvl}`
	local progress = attrNumber(TrainingConfig.xpAttribute(activeStat))
		/ TrainingConfig.xpToNext(lvl)
	fill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
end

local function buildHud(color: Color3)
	local frame = Ui.frame(
		Ui.screen(),
		"TrainingHud",
		UDim2.fromScale(0.36, 0.11),
		UDim2.fromScale(0.5, 0.17),
		Color3.fromRGB(14, 18, 40),
		0.25
	)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	Theme.surface(frame, color, 13)
	local size = Instance.new("UISizeConstraint")
	size.MinSize = Vector2.new(280, 68)
	size.MaxSize = Vector2.new(520, 110)
	size.Parent = frame

	levelLabel = Ui.label(
		frame,
		"Level",
		UDim2.fromScale(0.7, 0.45),
		UDim2.fromScale(0.04, 0.08),
		"",
		Color3.new(1, 1, 1)
	)
	local back = Ui.frame(
		frame,
		"XpBack",
		UDim2.fromScale(0.7, 0.22),
		UDim2.fromScale(0.04, 0.64),
		Color3.fromRGB(30, 34, 60)
	)
	Ui.corner(back, 0.5)
	local fill = Ui.frame(back, "XpFill", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0), color)
	Ui.corner(fill, 0.5)
	xpFill = fill

	local button = Instance.new("TextButton")
	button.Name = "Stop"
	button.Size = UDim2.new(0.22, 0, 0, 44)
	button.Position = UDim2.fromScale(0.77, 0.15)
	button.BackgroundColor3 = Color3.fromRGB(220, 70, 80)
	button.Text = Strings.stop
	button.TextScaled = true
	button.Font = Enum.Font.FredokaOne
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = frame
	Ui.corner(button, 0.3)
	button.Activated:Connect(function()
		stopRemote:FireServer()
	end)

	hud = frame
	refreshHud()
end

local function startAura(root: BasePart, color: Color3)
	local p = Instance.new("Part")
	p.Name = "TrainingAura"
	p.Size = Vector3.new(4, 0.2, 4)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CFrame = root.CFrame * CFrame.new(0, -2.8, 0)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(1, 1.8)
	e.Rate = 14
	e.Speed = NumberRange.new(2, 4)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = p
	p.Parent = Workspace
	aura = p
end

-- Loops the default Animate "cheer" as a simple training move until stopped.
local function startAnimation()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local animate = character and character:FindFirstChild("Animate")
	local cheer = animate and animate:FindFirstChild("cheer")
	local anim = cheer and cheer:FindFirstChildOfClass("Animation")
	if not (animator and anim) then
		return
	end
	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	animationTrack = track
	animThread = task.spawn(function()
		while true do
			track:Play(0.2)
			task.wait(3.5)
		end
	end)
end

local function startOrbit(root: BasePart)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	previousCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local angle = math.atan2(
		camera.CFrame.Position.Z - root.Position.Z,
		camera.CFrame.Position.X - root.Position.X
	)
	orbitConn = RunService.RenderStepped:Connect(function(dt: number)
		angle += dt * 0.18
		local focus = root.Position + Vector3.new(0, 1.5, 0)
		local eye = focus
			+ Vector3.new(
				math.cos(angle) * 13,
				4.6 + math.sin(angle * 2) * 0.6,
				math.sin(angle) * 13
			)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(eye, focus), math.min(dt * 4, 1))
	end)
end

local function finishRing()
	local stop = stopRing
	stopRing = nil
	if stop then
		stop()
		PressInput.disable()
		Ui.hidePanel()
	end
end

local function stopVisuals()
	finishRing()
	for _, conn in { orbitConn, moveConn } do
		if conn then
			conn:Disconnect()
		end
	end
	orbitConn, moveConn = nil, nil
	local thread = animThread
	animThread = nil
	if thread then
		task.cancel(thread)
	end
	local track = animationTrack
	animationTrack = nil
	if track then
		track:Stop(0.2)
		task.delay(0.25, function()
			track:Destroy()
		end)
	end
	local a = aura
	aura = nil
	if a then
		a:Destroy()
	end
	local h = hud
	hud, levelLabel, xpFill = nil, nil, nil
	if h then
		h:Destroy()
	end
	local camera = Workspace.CurrentCamera
	if camera and previousCameraType then
		camera.CameraType = previousCameraType
	end
	previousCameraType = nil
end

local function startVisuals(stat: string)
	local root = rootPart()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and humanoid) then
		return
	end
	local color = STAT_COLORS[stat] or Color3.new(1, 1, 1)
	buildHud(color)
	if player:GetAttribute("ReduceEffects") ~= true then
		startAura(root, color)
	end
	startAnimation()
	startOrbit(root)
	Effects.ripple(root.Position - Vector3.new(0, 2.9, 0), color, 6, 0.8)
	moveConn = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if humanoid.MoveDirection.Magnitude > 0.1 then
			stopRemote:FireServer()
		end
	end)
end

local function onActiveChanged()
	local value = player:GetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE)
	local stat = if typeof(value) == "string" then value else ""
	if stat == activeStat then
		return
	end
	stopVisuals()
	activeStat = stat
	if stat ~= "" then
		startVisuals(stat)
	end
end

local function onRing(update: Net.TrainingUpdate)
	if activeStat == "" or stopRing then
		return
	end
	local ringId = update.ringId or 0
	local color = STAT_COLORS[activeStat] or Color3.new(1, 1, 1)
	local lvl = attrNumber(TrainingConfig.levelAttribute(activeStat))
	local tier = math.clamp(1 + math.floor(lvl / 6), 1, 5)
	PressInput.enable()
	local area = Ui.showPanel(Strings.ringHint, color, Strings.instructions.rhythm or "")
	stopRing = Rhythm.run(area, tier, color, function(success)
		if not stopRing then
			return
		end
		stopRing = nil
		PressInput.disable()
		Ui.hidePanel()
		ringRemote:FireServer(ringId, success)
		if success then
			Ui.toast(Strings.ringBonus, color)
		end
	end, update.rings or 1)
end

local function onUpdate(update: Net.TrainingUpdate)
	if update.event == "ring" then
		onRing(update)
	elseif update.event == "levelUp" then
		local stat = update.stat or ""
		local color = STAT_COLORS[stat] or Color3.new(1, 1, 1)
		Ui.toast(`{Strings.stat[stat] or stat} {Strings.levelUp} {update.level or 0}!`, color)
		local root = rootPart()
		if root then
			Effects.ripple(root.Position - Vector3.new(0, 2.9, 0), color, 10, 1)
			Effects.ripple(root.Position - Vector3.new(0, 2.85, 0), Theme.gold, 7, 0.55)
			Effects.splash(root.Position, color, 24)
		end
	elseif update.event == "stopped" then
		finishRing()
	end
end

function Training.start()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	stopRemote = remotes:WaitForChild(Net.STOP_TRAINING) :: RemoteEvent
	ringRemote = remotes:WaitForChild(Net.TRAINING_RING_RESULT) :: RemoteEvent
	local updateRemote = remotes:WaitForChild(Net.TRAINING_UPDATE) :: RemoteEvent

	updateRemote.OnClientEvent:Connect(onUpdate)
	player:GetAttributeChangedSignal(TrainingConfig.ACTIVE_ATTRIBUTE):Connect(onActiveChanged)
	for _, stat in TrainingConfig.STATS do
		player:GetAttributeChangedSignal(TrainingConfig.levelAttribute(stat)):Connect(refreshHud)
		player:GetAttributeChangedSignal(TrainingConfig.xpAttribute(stat)):Connect(refreshHud)
	end
	player.CharacterAdded:Connect(function()
		stopVisuals()
		activeStat = ""
	end)
	onActiveChanged()
end

return Training
