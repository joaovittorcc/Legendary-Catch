--!strict
-- Lagoon training (client): plays the semi-idle session the server runs.
-- Owns the practice presentation and forwards drill results to the training server.
-- Walking stops training (the server also stops it if the player leaves the spot).

local ProximityPromptService = game:GetService("ProximityPromptService")
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
local Drill = require(script:WaitForChild("Drill"))
local Power = require(script:WaitForChild("Power"))
local Practice = require(script:WaitForChild("Practice"))
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
local practice: Practice.Session? = nil
local drillAwardUntil = 0
local sessionXp = 0
local sessionHits = 0
local sessionLevels = 0
local sessionStart = 0
local drillFeedback: TextLabel? = nil
local powerFloat: BillboardGui? = nil
local powerFloatTween: Tween? = nil
local powerFloatBonusUntil = 0
local preview: Frame? = nil
local nearbyPrompts: { [ProximityPrompt]: boolean } = {}
local cards: { [string]: { level: TextLabel, benefit: TextLabel, fill: Frame } } = {}
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

local function boost(stat: string, level: number): string
	local raw = if stat == "Control"
		then string.format(Text.controlBoost, (TrainingConfig.controlEase(level) - 1) * 100)
		else string.format(Text.instinctBoost, TrainingConfig.luckMultiplier(level, 5))
	return (raw:gsub("(%d)%.(%d)", "%1" .. Strings.decimalSep .. "%2"))
end

local function showXp(amount: number, color: Color3)
	local scene = practice
	if not scene or amount < 1 then
		return
	end
	sessionXp += amount
	local special = os.clock() <= drillAwardUntil and amount > 1
	if special then
		drillAwardUntil = 0
	end
	local old = scene.bobber:FindFirstChild("TrainingXp")
	if old then
		old:Destroy()
	end
	local board = Instance.new("BillboardGui")
	board.Name = "TrainingXp"
	board.AlwaysOnTop = true
	board.Size = UDim2.fromOffset(174, if special then 38 else 28)
	board.StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0)
	board.MaxDistance = 40
	local label = Ui.label(
		board,
		"Amount",
		UDim2.fromScale(1, 1),
		UDim2.fromScale(0, 0),
		string.format(if special then Text.perfectGain else Text.gain, amount),
		color:Lerp(Theme.sand, 0.4)
	)
	local size = Instance.new("UITextSizeConstraint")
	size.MaxTextSize = if special then 22 else 18
	size.Parent = label
	board.Parent = scene.bobber
	if not Ui.reduced() then
		TweenService
			:Create(board, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				StudsOffsetWorldSpace = Vector3.new(0, 2.65, 0),
			})
			:Play()
	end
	task.delay(0.86, function()
		board:Destroy()
	end)
end

local function refreshCards()
	local snapshot = Data.get()
	for stat, card in cards do
		local stats = snapshot and snapshot.training[stat]
		local level = if stats then stats.level else attrNumber(TrainingConfig.levelAttribute(stat))
		local xp = if stats then stats.xp else attrNumber(TrainingConfig.xpAttribute(stat))
		local goal = TrainingConfig.xpToNext(level)
		card.level.Text = (Strings.stat[stat] or stat)
			.. "  ·  "
			.. string.format(Text.level, level)
		card.benefit.Text = boost(stat, level)
		card.fill.Size = UDim2.fromScale(
			if level >= TrainingConfig.MAX_LEVEL then 1 else math.clamp(xp / goal, 0, 1),
			1
		)
	end
end

local function refreshHud()
	refreshCards()
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
	label.Text = (Strings.stat[activeStat] or activeStat)
		.. "  ·  "
		.. string.format(Text.level, level)
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
	local frame = hud or preview
	if frame then
		local camera = Workspace.CurrentCamera
		local viewport = if camera then camera.ViewportSize else Vector2.new(800, 600)
		local compact = viewport.Y < 520 and viewport.X > viewport.Y * 1.45
		local top = math.max(Hud.navBottom() + 8, Tutorial.cardBottom() + 12)
		if TrainingConfig.powerEnabled() then
			if frame == preview then
				local playerGui = frame:FindFirstAncestorOfClass("PlayerGui")
				local adventure = playerGui and playerGui:FindFirstChild("AdventureHud")
				local rod = adventure and adventure:FindFirstChild("RodHotbar")
				local clearance = if rod and rod:IsA("GuiObject")
					then math.max(78, rod.AbsoluteSize.Y + 22)
					else 110
				frame.AnchorPoint = Vector2.new(0.5, 1)
				frame.Size = UDim2.new(if compact then 0.48 else 0.84, 0, 0, frame.Size.Y.Offset)
				frame.Position = UDim2.new(0.5, 0, 1, -clearance)
				return
			end
			frame.AnchorPoint = Vector2.zero
			frame.Size = UDim2.new(if compact then 0.45 else 0.86, 0, 0, frame.Size.Y.Offset)
			frame.Position = UDim2.new(0.02, 0, 0, top)
			return
		end
		local x = if compact then 0.25 else 0.5
		frame.Size = UDim2.new(if compact then 0.46 else 0.92, 0, 0, frame.Size.Y.Offset)
		frame.Position = UDim2.new(x, 0, 0, top)
	end
end

function Training.cardBottom(): number
	local frame = hud or (if TrainingConfig.powerEnabled() then nil else preview)
	return if frame then frame.Position.Y.Offset + frame.AbsoluteSize.Y else 0
end

local function addCards(frame: Frame, top: number)
	table.clear(cards)
	for index, stat in TrainingConfig.STATS do
		local selected = stat == activeStat
		local accent = STAT_COLORS[stat] or Theme.crystal
		local card = Ui.frame(
			frame,
			stat,
			UDim2.new(0.458, 0, 0, 60),
			UDim2.new(0.031 + (index - 1) * 0.48, 0, 0, top),
			Theme.ink
		)
		Theme.surface(card, accent, 12, Theme.ink)
		local header = Ui.label(
			card,
			"Level",
			UDim2.fromScale(0.94, 0.36),
			UDim2.fromScale(0.03, 0.04),
			"",
			if selected then Theme.sand else accent
		)
		local benefit = Ui.label(
			card,
			"Benefit",
			UDim2.fromScale(0.94, 0.30),
			UDim2.fromScale(0.03, 0.43),
			"",
			Theme.sand
		)
		local back = Ui.frame(
			card,
			"Track",
			UDim2.fromScale(0.88, 0.095),
			UDim2.fromScale(0.06, 0.81),
			Theme.muted
		)
		Ui.corner(back, 0.5)
		local fill = Ui.frame(back, "Fill", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0), accent)
		Ui.corner(fill, 0.5)
		cards[stat] = { level = header, benefit = benefit, fill = fill }
	end
	refreshCards()
end

local function mountCard(
	name: string,
	height: number,
	color: Color3,
	slim: boolean?
): (Frame, Frame)
	local padding = if slim then 6 else 12
	local totalHeight = height + (if slim then 2 * padding else 26)
	local frame = Ui.frame(
		Ui.screen(),
		name,
		UDim2.new(0.92, 0, 0, totalHeight),
		UDim2.new(0.5, 0, 0, math.max(Hud.navBottom() + 8, Tutorial.cardBottom() + 12)),
		Theme.ink
	)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	if slim then
		Theme.corner(frame, 14)
		frame.BackgroundTransparency = 0.13
		local rim = Instance.new("UIStroke")
		rim.Color = color
		rim.Transparency = 0.55
		rim.Parent = frame
	else
		Art.panel(frame, color)
	end
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(if slim then 326 else 456, totalHeight)
	cap.Parent = frame
	local inner = Instance.new("Frame")
	inner.Name = "Content"
	inner.BackgroundTransparency = 1
	inner.Position = UDim2.fromOffset(padding, padding)
	inner.Size = UDim2.new(1, -2 * padding, 0, height)
	inner.ZIndex = 2
	inner.Parent = frame
	local setVisible = Hud.bindFishingVisibility(frame, false)
	local function updateVisibility()
		setVisible(Hud.panel() == "" and not Hud.isMenuOpen())
	end
	local panelConn = Hud.panelChanged:Connect(updateVisibility)
	local menuConn = Hud.menuChanged:Connect(updateVisibility)
	frame.Destroying:Once(function()
		panelConn:Disconnect()
		menuConn:Disconnect()
	end)
	updateVisibility()
	return frame, inner
end

local function refreshPreview()
	if activeStat ~= "" or next(nearbyPrompts) == nil then
		if preview then
			preview:Destroy()
			preview = nil
			if not hud then
				table.clear(cards)
			end
		end
		return
	end
	if preview then
		return
	end
	local usePower = TrainingConfig.powerEnabled()
	local frame, inner =
		mountCard("TrainingPreview", if usePower then 69 else 97, Theme.crystal, usePower)
	if usePower then
		Power.mountLauncher(inner)
		preview = frame
		positionHud()
		return
	end
	Ui.label(
		inner,
		"Title",
		UDim2.new(0.92, 0, 0, 20),
		UDim2.new(0.04, 0, 0, 7),
		Text.chooseMode,
		Theme.ink
	).TextStrokeTransparency =
		1
	addCards(inner, 30)
	preview = frame
	positionHud()
end

local function buildHud(color: Color3)
	local usePower = TrainingConfig.powerEnabled()
	local frame, inner = mountCard("TrainingHud", if usePower then 105 else 146, color, usePower)
	if usePower then
		local field = Power.fieldButton(inner, UDim2.fromOffset(0, 61), 0.58)
		Power.mount(inner, activeStat, color, field)
	else
		addCards(inner, 8)
		local statLabel = Ui.label(
			inner,
			"ActiveLevel",
			UDim2.new(0.63, 0, 0, 20),
			UDim2.new(0.04, 0, 0, 72),
			"",
			Theme.ink
		)
		statLabel.TextStrokeTransparency = 1
		levelLabel = statLabel
		local milestone = Ui.label(
			inner,
			"Milestone",
			UDim2.new(0.63, 0, 0, 18),
			UDim2.new(0.04, 0, 0, 92),
			"",
			Theme.ink
		)
		milestone.TextStrokeTransparency = 1
		milestoneLabel = milestone
		local track = Ui.frame(
			inner,
			"ActiveXpTrack",
			UDim2.new(0.63, 0, 0, 22),
			UDim2.new(0.04, 0, 0, 114),
			Theme.ink
		)
		Ui.corner(track, 0.35)
		xpFill = Ui.frame(track, "Fill", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0), color)
		local count = Ui.label(
			track,
			"Count",
			UDim2.fromScale(1, 0.84),
			UDim2.fromScale(0, 0.08),
			"",
			Theme.sand
		)
		count.ZIndex = 3
		xpLabel = count
	end
	local button = Panel.button(inner, Strings.stop, Color3.fromRGB(247, 75, 91))
	button.Name = "Stop"
	button.Size = UDim2.new(if usePower then 0.39 else 0.25, 0, 0, 44)
	button.Position = if usePower then UDim2.new(0.61, 0, 0, 61) else UDim2.new(0.71, 0, 0, 81)
	button.TextScaled = true
	local stopLimit = Instance.new("UITextSizeConstraint")
	stopLimit.MinTextSize = 10
	stopLimit.MaxTextSize = 16
	stopLimit.Parent = button
	button.Activated:Connect(function()
		stopRemote:FireServer()
	end)
	stopButton = button
	hud = frame
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
		local distance = (if stopRing then 14 else 15) - cameraPunch
		local scene = practice
		local focus = root.Position + Vector3.new(0, 1.1, 0)
		if scene then
			focus = focus:Lerp(scene.target + Vector3.yAxis * 1.4, 0.33)
		end
		local portrait = camera.ViewportSize.X < camera.ViewportSize.Y
		local offset = Vector3.new(
			math.cos(angle) * distance,
			4.6 + math.sin(angle * 2) * 0.6,
			math.sin(angle) * distance
		)
		if portrait and scene then
			local toward = (scene.target - root.Position) * Vector3.new(1, 0, 1)
			if toward.Magnitude > 0.1 then
				local forward = toward.Unit
				offset = -forward * (distance + 1)
					+ forward:Cross(Vector3.yAxis) * 4
					+ Vector3.yAxis * 6
			end
		end
		local eye = focus + offset
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
		local scene = practice
		if scene then
			scene.pull, scene.bite = 0, false
			scene.drilling = false
		end
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
	if practice then
		practice.stop()
	end
	practice = nil
	if powerFloatTween then
		powerFloatTween:Cancel()
		powerFloatTween = nil
	end
	powerFloat = nil
	powerFloatBonusUntil = 0
	drillAwardUntil = 0
	sessionXp, sessionHits, sessionLevels, sessionStart = 0, 0, 0, 0
	drillFeedback = nil
	table.clear(cards)
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
	if not (root and humanoid and character) then
		return
	end
	local color = STAT_COLORS[stat] or Color3.new(1, 1, 1)
	sessionStart = os.clock()
	startAura(root, color)
	practice = Practice.start(character, root, color)
	buildHud(color)
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
	if sessionStart > 0 and sessionXp > 0 then
		local color = STAT_COLORS[activeStat] or Theme.crystal
		local summary = Ui.label(
			Ui.screen(),
			"TrainingSummary",
			UDim2.new(0.86, 0, 0, 40),
			UDim2.fromScale(0.5, 0.84),
			string.format(
				Text.sessionSummary,
				Strings.stat[activeStat] or activeStat,
				math.floor(os.clock() - sessionStart),
				sessionXp,
				sessionHits,
				sessionLevels
			),
			color
		)
		summary.AnchorPoint = Vector2.new(0.5, 0.5)
		summary.BackgroundTransparency = 0
		Theme.surface(summary, color, 14, Theme.ink)
		task.delay(3, function()
			summary:Destroy()
		end)
	end
	stopVisuals()
	activeStat = stat
	refreshPreview()
	if stat ~= "" then
		startVisuals(stat)
	end
end

local function onRing(update: Net.TrainingUpdate)
	if activeStat == "" or (update.stat and update.stat ~= activeStat) or stopRing then
		return
	end
	local ringId = update.ringId or 0
	local color = STAT_COLORS[activeStat] or Color3.new(1, 1, 1)
	local activePractice = practice
	if activePractice then
		activePractice.drilling = true
	end
	PressInput.enable()
	local area = Ui.showPanel("", color, "")
	stopRing = Drill.run(area, activeStat, color, update.rings or 1, function(pull, bite)
		local scene = practice
		if not scene then
			return
		end
		if bite and not scene.bite and not Ui.reduced() then
			Effects.ripple(scene.target, color, 2, 0.48)
		end
		scene.pull, scene.bite = pull, bite
	end, function(success)
		if not stopRing then
			return
		end
		finishRing()
		local scene = practice
		if scene then
			scene.reelAt = os.clock()
			if success and not Ui.reduced() then
				Effects.ripple(scene.target, color, 4.5, 0.64)
				Effects.splash(scene.target, color, 10)
			end
		end
		local frame = hud
		if frame then
			if drillFeedback then
				drillFeedback:Destroy()
			end
			local feedback = Ui.label(
				frame,
				"DrillFeedback",
				UDim2.new(0.9, 0, 0, 25),
				UDim2.new(0.05, 0, 1, 2),
				if success then Text.drillGood else Text.drillMiss,
				if success then color else Theme.sand
			)
			drillFeedback = feedback
			Ui.bounce(feedback)
			task.delay(1.1, function()
				if drillFeedback == feedback then
					drillFeedback = nil
				end
				feedback:Destroy()
			end)
		end
		drillAwardUntil = if success then os.clock() + 2 else 0
		if success then
			sessionHits += 1
			Audio.play("level", 0.14, 1.25)
		end
		ringRemote:FireServer(ringId, success)
	end, function(point)
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
	end)
end

local function floatPower(gain: number, bonus: boolean)
	local scene = practice
	if not scene then
		return
	end
	local now = os.clock()
	if not bonus and now < powerFloatBonusUntil then
		return
	end
	if bonus then
		powerFloatBonusUntil = now + 0.78
	end
	local board: BillboardGui = powerFloat or Instance.new("BillboardGui")
	if not powerFloat then
		board.Name = "TrainingPowerGain"
		board.AlwaysOnTop = true
		board.Size = UDim2.fromOffset(160, 30)
		board.MaxDistance = 48
		local label = Ui.label(board, "Amount", UDim2.fromScale(1, 1), UDim2.new(), "", Theme.sand)
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 20
		limit.Parent = label
		board.Parent = scene.bobber
		powerFloat = board
	end
	local label = board:FindFirstChild("Amount") :: TextLabel
	label.Text = "+" .. TrainingConfig.formatPower(gain, Strings.decimalSep)
	label.TextColor3 = if bonus then Theme.gold else STAT_COLORS[activeStat] or Theme.crystal
	board.StudsOffsetWorldSpace = Vector3.new(0, 1.1, 0)
	if powerFloatTween then
		powerFloatTween:Cancel()
	end
	if Ui.reduced() then
		board.Enabled = false
		return
	end
	board.Enabled = true
	local tween = TweenService:Create(board, TweenInfo.new(0.85, Enum.EasingStyle.Quad), {
		StudsOffsetWorldSpace = Vector3.new(0, if bonus then 2.9 else 2.05, 0),
	})
	powerFloatTween = tween
	tween.Completed:Once(function(playback)
		if playback == Enum.PlaybackState.Completed and powerFloatTween == tween then
			board.Enabled = false
		end
	end)
	tween:Play()
	local particles = emitter
	if particles then
		particles:Emit(if bonus then 10 else 2)
	end
end

local function onUpdate(update: Net.TrainingUpdate)
	if TrainingConfig.powerEnabled() then
		Power.onUpdate(update)
		local gain = update.gain
		if update.stat == activeStat and gain and gain > 0 and not Ui.reduced() then
			floatPower(gain, update.event ~= "power")
		end
		if update.event == "levelUp" then
			return
		end
	end
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
		sessionLevels += 1
		local color = STAT_COLORS[stat] or Theme.crystal
		if levelBanner then
			levelBanner:Destroy()
		end
		local banner = Ui.label(
			frame,
			"LevelUp",
			UDim2.new(0.94, 0, 0, 64),
			UDim2.new(0.5, 0, 1, 31),
			(Strings.stat[stat] or stat)
				.. "  ·  "
				.. string.format(Text.levelUp, level)
				.. "\n"
				.. boost(stat, math.max(0, level - 1))
				.. " → "
				.. boost(stat, level),
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
		cap.MaxSize = Vector2.new(405, 64)
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
		local scene = practice
		if scene then
			scene.reelAt = os.clock()
		end
		if scene and not Ui.reduced() then
			cameraPunch = 0.6
			Effects.ripple(scene.target, color, 7, 0.9)
			Effects.ripple(scene.target + Vector3.yAxis * 0.03, Theme.gold, 5, 0.55)
			Effects.splash(scene.target, color, 18)
			local particles = emitter
			if particles then
				particles:Emit(14)
			end
		end
	elseif update.event == "stopped" then
		finishRing()
	end
end

local function watchNearbyTraining()
	local observed: { [Player]: { character: Model, stat: string, session: Practice.Session } } = {}
	local function remove(other: Player)
		local entry = observed[other]
		if entry then
			entry.session.stop()
			observed[other] = nil
		end
	end
	Players.PlayerRemoving:Connect(remove)
	task.spawn(function()
		while true do
			local localRoot = rootPart()
			for _, other in Players:GetPlayers() do
				if other == player then
					continue
				end
				local stat = other:GetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE)
				local color = if typeof(stat) == "string" then STAT_COLORS[stat] else nil
				local character = other.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local entry = observed[other]
				if
					localRoot
					and character
					and root
					and root:IsA("BasePart")
					and color
					and typeof(stat) == "string"
					and (localRoot.Position - root.Position).Magnitude <= 65
				then
					if not entry or entry.character ~= character or entry.stat ~= stat then
						remove(other)
						observed[other] = {
							character = character,
							stat = stat,
							session = Practice.start(character, root, color, true),
						}
					end
				else
					remove(other)
				end
			end
			task.wait(0.35)
		end
	end)
end

function Training.start()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	stopRemote = remotes:WaitForChild(Net.STOP_TRAINING) :: RemoteEvent
	ringRemote = remotes:WaitForChild(Net.TRAINING_RING_RESULT) :: RemoteEvent
	local updateRemote = remotes:WaitForChild(Net.TRAINING_UPDATE) :: RemoteEvent
	Power.start(remotes:WaitForChild(Net.TRAINING_BUY_FIELD) :: RemoteEvent)

	Tutorial.layoutChanged:Connect(positionHud)
	Hud.layoutChanged:Connect(positionHud)
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt.Name == "TrainControl" or prompt.Name == "TrainInstinct" then
			nearbyPrompts[prompt] = true
			refreshPreview()
		end
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		nearbyPrompts[prompt] = nil
		refreshPreview()
	end)
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
		table.clear(nearbyPrompts)
		refreshPreview()
	end)
	onActiveChanged()
	watchNearbyTraining()
end

return Training
