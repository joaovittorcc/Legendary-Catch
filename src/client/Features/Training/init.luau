--!strict
-- Lagoon training (client): plays the semi-idle session the server runs.
--   * slow orbit camera around the player, cheer animation loop, rising aura
--   * HUD with stat, level, XP bar and a Stop button
--   * occasional rhythm ring for bonus XP (reuses the fishing rhythm minigame)
-- Walking stops training (the server also stops it if the player leaves the spot).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi")).training
local Theme = require(Shared:WaitForChild("UiTheme"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))

local FishingFolder = script.Parent:WaitForChild("Fishing")
local Effects = require(FishingFolder:WaitForChild("Effects"))
local PressInput = require(FishingFolder:WaitForChild("PressInput"))
local Rhythm = require(FishingFolder:WaitForChild("Minigames"):WaitForChild("Rhythm"))
local Ui = require(FishingFolder:WaitForChild("Ui"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Tutorial = require(script.Parent:WaitForChild("Tutorial"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Panel = require(script.Parent.Hud:WaitForChild("Panel"))

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
local animationTracks: { AnimationTrack } = {}
local previousCameraType: Enum.CameraType? = nil
local aura: Attachment? = nil
local emitter: ParticleEmitter? = nil
local xpTween: Tween? = nil
local lastTotalXp: number? = nil
local xpLabel: TextLabel? = nil
local milestoneLabel: TextLabel? = nil
local levelBanner: TextLabel? = nil
local cameraPunch = 0
local lastCelebrated = 0
local stopRing: (() -> ())? = nil
local stopButton: TextButton? = nil

local function rootPart(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function attrNumber(name: string): number
	local v = player:GetAttribute(name)
	return if typeof(v) == "number" then v else 0
end

local function showXp(amount: number, color: Color3)
	local frame = hud
	if not frame or amount < 1 or frame:FindFirstChild("DailyBonus") then
		return
	end
	local pop = Ui.label(
		frame,
		"XpGain",
		UDim2.fromOffset(76, 20),
		UDim2.new(0.68, 0, 1, 8),
		string.format(Text.gain, amount),
		color:Lerp(Theme.sand, 0.35)
	)
	pop.AnchorPoint = Vector2.new(0.5, 0)
	pop.ZIndex = 5
	if not Ui.reduced() then
		TweenService
			:Create(pop, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.68, 0, 1, 28),
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			})
			:Play()
	end
	task.delay(0.67, function()
		pop:Destroy()
	end)
end

local function refreshHud()
	local label, fill, progressLabel = levelLabel, xpFill, xpLabel
	if activeStat == "" or not label or not fill or not progressLabel then
		return
	end
	local snapshot = Data.get()
	local stat = snapshot and snapshot.training[activeStat]
	local level = if stat then stat.level else attrNumber(TrainingConfig.levelAttribute(activeStat))
	local xp = if stat then stat.xp else attrNumber(TrainingConfig.xpAttribute(activeStat))
	local maximum = TrainingConfig.xpToNext(level)
	local maxed = level >= TrainingConfig.MAX_LEVEL
	label.Text = string.format(Text.level, level)
	progressLabel.Text = if maxed
		then Strings.maxLevel
		else string.format(Text.progress, xp, maximum)
	local milestone = milestoneLabel
	if milestone then
		local rank = math.clamp(math.floor(level / 5), 0, #Text.titles)
		local combo = attrNumber("TrainingCombo")
		milestone.Text = if combo >= 2
			then string.format(Text.combo, combo)
			elseif rank > 0 then "★ " .. Text.titles[rank]
			else ""
	end

	local total = xp
	for previous = 0, level - 1 do
		total += TrainingConfig.xpToNext(previous)
	end
	local last = lastTotalXp
	if not last or total >= last then
		lastTotalXp = total
		if last and total > last then
			showXp(total - last, STAT_COLORS[activeStat] or Theme.crystal)
		end
	end
	if xpTween then
		xpTween:Cancel()
		xpTween = nil
	end
	local goal = UDim2.fromScale(if maxed then 1 else math.clamp(xp / maximum, 0, 1), 1)
	if Ui.reduced() or not last or fill.Size.X.Scale > goal.X.Scale then
		fill.Size = goal
	else
		local tween =
			TweenService:Create(fill, TweenInfo.new(0.24, Enum.EasingStyle.Quad), { Size = goal })
		xpTween = tween
		tween:Play()
	end
	local particles = emitter
	if particles then
		local growth = math.clamp(level / TrainingConfig.MAX_LEVEL, 0, 1)
		particles.Enabled = not Ui.reduced()
		particles.Rate = 4 + 9 * growth
		particles.Speed = NumberRange.new(1.3, 2.4 + growth * 2)
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.24 + 0.36 * growth),
			NumberSequenceKeypoint.new(1, 0),
		})
	end
end

local function positionHud()
	local frame = hud
	if frame then
		frame.Position =
			UDim2.new(0.5, 0, 0, math.max(Hud.navBottom() + 8, Tutorial.cardBottom() + 12))
	end
end

function Training.cardBottom(): number
	local frame = hud
	return if frame then frame.Position.Y.Offset + frame.AbsoluteSize.Y else 0
end

local function buildHud(color: Color3)
	local frame = Ui.frame(
		Ui.screen(),
		"TrainingHud",
		UDim2.new(0.88, 0, 0, 84),
		UDim2.new(0.5, 0, 0, 66),
		Color3.fromRGB(14, 18, 40),
		0.25
	)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	Art.panel(frame, color)
	local icon = Instance.new("Frame")
	icon.Name = "StatIcon"
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.fromScale(0.035, 0.5)
	icon.Size = UDim2.fromOffset(40, 40)
	icon.BackgroundColor3 = Theme.cream
	icon.BorderSizePixel = 0
	Theme.corner(icon, 20)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Theme.outline
	iconStroke.Thickness = 2
	iconStroke.Parent = icon
	local glyph = Panel.label(icon, if activeStat == "Instinct" then "✨" else "🎣", 26)
	glyph.TextStrokeTransparency = 1
	glyph.TextScaled = true
	glyph.Size = UDim2.fromScale(1, 1)
	icon.Parent = frame
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(450, 84)
	size.Parent = frame

	local statName = Ui.label(
		frame,
		"Stat",
		UDim2.fromScale(0.46, 0.18),
		UDim2.fromScale(0.21, 0.12),
		Strings.stat[activeStat] or activeStat,
		Theme.ink
	)
	statName.TextXAlignment = Enum.TextXAlignment.Left
	statName.TextStrokeTransparency = 1
	local milestone = Ui.label(
		frame,
		"Milestone",
		UDim2.fromScale(0.46, 0.14),
		UDim2.fromScale(0.21, 0.56),
		"",
		Theme.ink
	)
	milestone.TextXAlignment = Enum.TextXAlignment.Left
	milestone.TextStrokeTransparency = 1
	milestoneLabel = milestone

	local level = Ui.label(
		frame,
		"Level",
		UDim2.fromScale(0.47, 0.27),
		UDim2.fromScale(0.21, 0.29),
		"",
		Theme.ink
	)
	level.TextXAlignment = Enum.TextXAlignment.Left
	level.TextStrokeTransparency = 1
	levelLabel = level
	local back = Ui.frame(
		frame,
		"XpBack",
		UDim2.fromScale(0.49, 0.20),
		UDim2.fromScale(0.21, 0.73),
		Theme.muted
	)
	Ui.corner(back, 0.5)
	local backStroke = Instance.new("UIStroke")
	backStroke.Color = Theme.outline
	backStroke.Thickness = 2
	backStroke.Parent = back
	local fill = Ui.frame(back, "XpFill", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0), color)
	Ui.corner(fill, 0.5)
	local sheen = Instance.new("UIGradient")
	sheen.Color = ColorSequence.new(Theme.sand, Color3.fromRGB(150, 137, 158))
	sheen.Rotation = 90
	sheen.Parent = fill
	xpFill = fill
	local xpCount = Ui.label(
		back,
		"XpCount",
		UDim2.fromScale(1, 0.85),
		UDim2.fromScale(0, 0.075),
		"",
		Theme.sand
	)
	xpCount.ZIndex = 3
	xpLabel = xpCount

	local button = Panel.button(frame, Strings.stop, Color3.fromRGB(247, 75, 91))
	button.Name = "Stop"
	button.Size = UDim2.new(0.23, 0, 0, 44)
	button.Position = UDim2.fromScale(0.73, 0.24)
	button.Activated:Connect(function()
		stopRemote:FireServer()
	end)
	stopButton = button

	hud = frame
	local showHud = Hud.bindFishingVisibility(frame, false)
	showHud(true)
	positionHud()
	refreshHud()
end

local function startAura(root: BasePart, color: Color3)
	local p = Instance.new("Attachment")
	p.Name = "TrainingAura"
	p.Position = Vector3.new(0, -2.2, 0)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(1, 1.8)
	e.Rate = 4
	e.Enabled = not Ui.reduced()
	e.SpreadAngle = Vector2.new(32, 32)
	e.Speed = NumberRange.new(2, 4)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = p
	p.Parent = root
	aura = p
	emitter = e
end

-- Reuse avatar emotes as training moves.
local function startAnimation()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local animate = character and character:FindFirstChild("Animate")
	if not (animator and animate) then
		return
	end
	local poses: { AnimationTrack } = {}
	for _, name in { "cheer", "wave", "point" } do
		local holder = animate:FindFirstChild(name)
		local pose = holder and holder:FindFirstChildOfClass("Animation")
		if pose then
			local track = animator:LoadAnimation(pose)
			track.Priority = Enum.AnimationPriority.Action
			table.insert(poses, track)
		end
	end
	if #poses == 0 then
		return
	end
	animationTracks = poses
	animThread = task.spawn(function()
		local index = 1
		while true do
			local track = poses[index]
			track:Play(0.2)
			task.wait(3.5)
			track:Stop(0.2)
			index = index % #poses + 1
		end
	end)
end

local function startOrbit(root: BasePart)
	local camera = Workspace.CurrentCamera
	if not camera or Ui.reduced() then
		return
	end
	previousCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local angle = math.atan2(
		camera.CFrame.Position.Z - root.Position.Z,
		camera.CFrame.Position.X - root.Position.X
	)
	orbitConn = RunService.RenderStepped:Connect(function(dt: number)
		angle += dt * (if stopRing then 0.09 else 0.24)
		cameraPunch *= math.exp(-dt * 2.4)
		local distance = (if stopRing then 10.5 else 13) - cameraPunch
		local focus = root.Position + Vector3.new(0, 1.5, 0)
		local eye = focus
			+ Vector3.new(
				math.cos(angle) * distance,
				4.6 + math.sin(angle * 2) * 0.6,
				math.sin(angle) * distance
			)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(eye, focus), math.min(dt * 4, 1))
	end)
end

local function stopOrbit()
	local conn = orbitConn
	orbitConn = nil
	if conn then
		conn:Disconnect()
	end
	local camera = Workspace.CurrentCamera
	if camera and previousCameraType then
		camera.CameraType = previousCameraType
	end
	previousCameraType = nil
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
	stopOrbit()
	if moveConn then
		moveConn:Disconnect()
		moveConn = nil
	end
	local thread = animThread
	animThread = nil
	if thread then
		task.cancel(thread)
	end
	for _, track in animationTracks do
		track:Stop(0.2)
		task.delay(0.25, function()
			track:Destroy()
		end)
	end
	table.clear(animationTracks)
	local a = aura
	aura, emitter = nil, nil
	lastTotalXp, lastCelebrated, cameraPunch = nil, 0, 0
	if xpTween then
		xpTween:Cancel()
		xpTween = nil
	end
	if levelBanner then
		levelBanner:Destroy()
		levelBanner = nil
	end
	if a then
		a:Destroy()
	end
	local h = hud
	hud, levelLabel, xpFill, xpLabel, milestoneLabel = nil, nil, nil, nil, nil
	stopButton = nil
	if h then
		h:Destroy()
	end
end

local function startVisuals(stat: string)
	local root = rootPart()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and humanoid) then
		return
	end
	local color = STAT_COLORS[stat] or Color3.new(1, 1, 1)
	startAura(root, color)
	buildHud(color)
	startAnimation()
	startOrbit(root)
	if not Ui.reduced() then
		Effects.ripple(root.Position - Vector3.new(0, 2.9, 0), color, 6, 0.8)
	end
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
	stopRing = Rhythm.run(
		area,
		tier,
		color,
		function(success)
			if not stopRing then
				return
			end
			stopRing = nil
			PressInput.disable()
			Ui.hidePanel()
			ringRemote:FireServer(ringId, success)
		end,
		update.rings or 1,
		function(point)
			local button = stopButton
			if not button then
				return false
			end
			local offset = point - button.AbsolutePosition
			local size = button.AbsoluteSize
			if offset.X < 0 or offset.Y < 0 or offset.X > size.X or offset.Y > size.Y then
				return false
			end
			finishRing()
			stopRemote:FireServer()
			return true
		end
	)
end

local function onUpdate(update: Net.TrainingUpdate)
	if update.event == "dailyBonus" then
		local xp = update.bonusXp
		local frame = hud
		if frame and xp and xp > 0 then
			local bonus = Ui.label(
				frame,
				"DailyBonus",
				UDim2.new(0.9, 0, 0, 22),
				UDim2.new(0.5, 0, 1, 7),
				string.format(Text.daily, xp),
				Theme.gold
			)
			bonus.AnchorPoint = Vector2.new(0.5, 0)
			bonus.ZIndex = 5
			task.delay(2, function()
				bonus:Destroy()
			end)
			Audio.play("level", 0.2, 1.15)
		end
	elseif update.event == "ring" then
		onRing(update)
	elseif update.event == "levelUp" then
		local stat, level = update.stat or "", update.level or 0
		local frame = hud
		if not frame or stat ~= activeStat or level <= lastCelebrated then
			return
		end
		lastCelebrated = level
		local color = STAT_COLORS[stat] or Theme.crystal
		if levelBanner then
			levelBanner:Destroy()
		end
		local banner = Ui.label(
			frame,
			"LevelUp",
			UDim2.new(0.86, 0, 0, 46),
			UDim2.new(0.5, 0, 1, 31),
			string.format(Text.levelUp, level),
			Theme.sand
		)
		banner.AnchorPoint = Vector2.new(0.5, 0)
		local reward = update.rewardCoins
		if reward and reward > 0 then
			banner.Text ..= "\n" .. string.format(Text.milestoneReward, reward)
		end
		banner.BackgroundTransparency = 0
		banner.ZIndex = 8
		Theme.surface(banner, color, 20)
		local cap = Instance.new("UISizeConstraint")
		cap.MaxSize = Vector2.new(290, 46)
		cap.Parent = banner
		levelBanner = banner
		Ui.bounce(banner)
		Audio.play("level", 0.22, if reward and reward > 0 then 1.1 else 1)
		task.delay(1.75, function()
			if levelBanner == banner then
				levelBanner = nil
			end
			banner:Destroy()
		end)
		local root = rootPart()
		if root and not Ui.reduced() then
			cameraPunch = 1.3
			Effects.ripple(root.Position - Vector3.new(0, 2.9, 0), color, 10, 1)
			Effects.ripple(root.Position - Vector3.new(0, 2.85, 0), Theme.gold, 7, 0.55)
			Effects.splash(root.Position, color, 24)
			local particles = emitter
			if particles then
				particles:Emit(14)
			end
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

	Tutorial.layoutChanged:Connect(positionHud)
	Hud.layoutChanged:Connect(positionHud)
	updateRemote.OnClientEvent:Connect(onUpdate)
	player:GetAttributeChangedSignal(TrainingConfig.ACTIVE_ATTRIBUTE):Connect(onActiveChanged)
	player:GetAttributeChangedSignal("TrainingCombo"):Connect(refreshHud)
	Data.changed:Connect(refreshHud)
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(function()
		refreshHud()
		if Ui.reduced() then
			stopOrbit()
			local particles = emitter
			if particles then
				particles:Clear()
			end
		elseif activeStat ~= "" and not orbitConn then
			local root = rootPart()
			if root then
				startOrbit(root)
			end
		end
	end)
	player.CharacterAdded:Connect(function()
		stopVisuals()
		activeStat = ""
	end)
	onActiveChanged()
end

return Training
