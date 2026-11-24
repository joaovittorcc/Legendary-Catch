--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Text = require(Shared:WaitForChild("StringsUi")).minigames
local Theme = require(Shared:WaitForChild("UiTheme"))
local Control = require(script.Parent.Parent:WaitForChild("Control"))
local Input = require(script.Parent:WaitForChild("Input"))
local Lesson = require(script.Parent:WaitForChild("ReelLesson"))
local Ui = require(script.Parent.Parent:WaitForChild("Ui"))

local Precision = {}

function Precision.run(
	area: Frame,
	tier: number,
	color: Color3,
	done: (boolean, boolean?) -> ()
): () -> ()
	local cfg = Config.PRECISION
	local speed = Config.tierValue(cfg.markerSpeed, tier)
	local zoneWidth = math.min(Config.tierValue(cfg.zoneWidth, tier) * Control.ease(), 0.4)
	local reverseRate = Config.tierValue(cfg.reverseRate, tier)
	local jitter = Config.tierValue(cfg.speedJitter, tier)
	local rng = Random.new()
	local dock = Ui.frame(
		area,
		"PrecisionDock",
		UDim2.new(0.78, 0, 0, 80),
		UDim2.new(0.5, 0, 1, -84),
		Theme.ink,
		1
	)
	dock.AnchorPoint = Vector2.new(0.5, 1)
	local function placeDock()
		local size = area.AbsoluteSize
		dock.Position = UDim2.new(0.5, 0, 1, if size.Y > size.X then -116 else -84)
	end
	local resize = area:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeDock)
	dock.Destroying:Once(function()
		resize:Disconnect()
	end)
	placeDock()
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(560, 80)
	cap.Parent = dock
	local bar =
		Ui.frame(dock, "Bar", UDim2.new(1, 0, 0, 18), UDim2.fromScale(0, 0.34), Theme.outline)
	Ui.corner(bar, 0.5)
	Ui.stroke(bar, Theme.ink, 3)
	Ui.bounce(dock)
	Ui.label(
		dock,
		"Instruction",
		UDim2.new(1, 0, 0, 19),
		UDim2.fromScale(0, 1.04),
		Text.precisionControl,
		Theme.sand
	)
	local trail: { Frame } = {}
	for index = 1, 5 do
		local ghost = Ui.frame(
			bar,
			"Trail",
			UDim2.fromOffset(6, 9),
			UDim2.fromScale(0.08, 0.5),
			color,
			0.18 + index * 0.13
		)
		ghost.AnchorPoint = Vector2.new(0.5, 0.5)
		ghost.Visible = false
		Ui.corner(ghost, 0.5)
		table.insert(trail, ghost)
	end
	local sampleTime = 0
	local zone =
		Ui.frame(bar, "Zone", UDim2.fromScale(zoneWidth, 1), UDim2.fromScale(0.5, 0), color, 0.12)
	zone.AnchorPoint = Vector2.new(0.5, 0)
	Theme.surface(zone, color, 8)
	Ui.stroke(zone, color:Lerp(Theme.sand, 0.5), 2)
	local centerLine = Ui.frame(
		zone,
		"SweetSpot",
		UDim2.new(0.3, 0, 1, -4),
		UDim2.new(0.35, 0, 0, 2),
		Theme.sand,
		0.38
	)
	Ui.corner(centerLine, 0.5)
	local marker =
		Ui.frame(bar, "Marker", UDim2.new(0, 7, 1.35, 0), UDim2.fromScale(0.08, 0.5), Theme.sand)
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	Ui.corner(marker, 0.5)
	Ui.stroke(marker, Theme.ink, 2)
	local timer = Ui.label(
		dock,
		"DecisionTime",
		UDim2.fromScale(0.25, 0.22),
		UDim2.fromScale(0.75, 0),
		"",
		Theme.gold
	)
	local timerTrack = Ui.frame(
		dock,
		"TimerTrack",
		UDim2.fromScale(0.7, 0.065),
		UDim2.fromScale(0, 0.08),
		Theme.track
	)
	Ui.corner(timerTrack, 0.5)
	local timeFill =
		Ui.frame(timerTrack, "Remaining", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Theme.gold)
	Ui.corner(timeFill, 0.5)
	local pips: { Frame } = {}
	local lives: { Frame } = {}
	for i = 1, cfg.hitsNeeded do
		local pip = Ui.frame(
			dock,
			"Hit" .. i,
			UDim2.fromScale(0.07, 0.19),
			UDim2.fromScale((i - 1) * 0.09, 0.78),
			Theme.outline
		)
		Ui.corner(pip, 0.5)
		Ui.stroke(pip, Theme.sand, 1.5)
		table.insert(pips, pip)
	end
	for i = 1, cfg.missesAllowed do
		local light = Ui.frame(
			dock,
			"Miss" .. i,
			UDim2.fromScale(0.05, 0.19),
			UDim2.fromScale(1 - i * 0.075, 0.78),
			Theme.outline
		)
		Ui.corner(light, 0.5)
		Ui.stroke(light, Theme.rose, 1)
		table.insert(lives, light)
	end
	local pos, direction = 0.08, 1
	local velocity = speed
	local feint = 0
	local hits, misses = 0, 0
	local remaining = cfg.decisionSeconds
	local lastTenth = -1
	local timeWarning = false
	local trailVisible = false
	local cooldown = 0
	local impactEnd = 0
	local moveAfterImpact = false
	local combo = 0
	local finished = false
	local pending: thread? = nil
	local lesson = Lesson.show("precision")
	local controls: { stop: () -> () }
	local step: RBXScriptConnection
	local function moveZone()
		local half = zoneWidth / 2
		local center = rng:NextNumber(half, 1 - half)
		if math.abs(center - pos) < 0.25 then
			center = math.clamp(center + (if center > 0.5 then -0.35 else 0.35), half, 1 - half)
		end
		zone.Position = UDim2.fromScale(center, 0)
	end
	local function finish(success: boolean)
		finished = true
		Ui.exitPulse(bar, if success then color else Theme.rose)
		controls.stop()
		if lesson then
			lesson.stop()
		end
		step:Disconnect()
		pending = task.delay(0.34, function()
			pending = nil
			done(success, success and misses == 0)
		end)
	end
	local function miss(timedOut: boolean)
		misses += 1
		local life = lives[misses]
		life.BackgroundColor3 = Color3.fromRGB(255, 83, 118)
		Ui.exitPulse(life, Theme.rose)
		combo = 0
		Ui.feedback(dock, UDim2.fromScale(0.5, -0.20), color, false)
		if timedOut then
			timer.Text = Text.timeUp
			lastTenth = -1
		end
		remaining = cfg.decisionSeconds
		cooldown = 0.18
		if misses >= cfg.missesAllowed then
			finish(false)
		end
	end
	moveZone()
	controls = Input.bind(function(point)
		if lesson and lesson.active() then
			lesson.press(point)
			return
		end
		if finished or cooldown > 0 then
			return
		end
		cooldown = 0.18
		local distance = math.abs(pos - zone.Position.X.Scale)
		if distance <= zoneWidth / 2 then
			local perfect = distance < zoneWidth * 0.15
			hits += 1
			pips[hits].BackgroundColor3 = Theme.gold
			combo += 1
			Ui.feedback(dock, UDim2.fromScale(0.5, -0.20), color, true, perfect, combo)
			remaining = cfg.decisionSeconds
			if hits >= cfg.hitsNeeded then
				finish(true)
			elseif perfect and not Ui.reduced() then
				impactEnd = os.clock() + 0.06
				moveAfterImpact = true
			else
				moveZone()
			end
		else
			miss(false)
		end
	end)
	step = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		if lesson and lesson.active() then
			lesson.update(dt)
			return
		end
		if moveAfterImpact then
			if not Ui.reduced() and os.clock() < impactEnd then
				return
			end
			moveAfterImpact = false
			moveZone()
		end
		cooldown = math.max(0, cooldown - dt)
		remaining -= dt
		local tenth = math.max(0, math.ceil(remaining * 10))
		if tenth ~= lastTenth and cooldown <= 0 then
			lastTenth = tenth
			timer.Text = string.format(Text.seconds, tenth / 10)
		end
		timeFill.Size = UDim2.fromScale(math.max(0, remaining / cfg.decisionSeconds), 1)
		local warning = remaining < 1.2
		if warning ~= timeWarning then
			timeWarning = warning
			timeFill.BackgroundColor3 = if warning then Theme.rose else Theme.gold
		end
		if remaining <= 0 then
			miss(true)
			if finished then
				return
			end
		end
		local movementDt = math.min(dt, 0.1)
		if feint > 0 then
			feint -= movementDt
			if feint <= 0 then
				direction = -direction
				velocity = speed * rng:NextNumber(1 - jitter, 1 + jitter)
			end
		elseif rng:NextNumber() < 1 - math.exp(-reverseRate * movementDt) then
			direction = -direction
			velocity = speed * rng:NextNumber(1 - jitter, 1 + jitter)
			if rng:NextNumber() < 0.4 then
				feint = rng:NextNumber(0.09, 0.2)
				velocity *= 0.45
			end
		end
		pos += direction * velocity * movementDt
		if pos >= 1 then
			pos, direction = 1, -1
		elseif pos <= 0 then
			pos, direction = 0, 1
		end
		marker.Position = UDim2.fromScale(pos, 0.5)
		local showTrail = not Ui.reduced()
		if showTrail ~= trailVisible then
			trailVisible = showTrail
			for _, ghost in trail do
				ghost.Visible = showTrail
				ghost.Position = marker.Position
			end
		end
		if showTrail then
			sampleTime += dt
			if sampleTime >= 1 / 30 then
				sampleTime %= 1 / 30
				for index = #trail, 2, -1 do
					trail[index].Position = trail[index - 1].Position
				end
				trail[1].Position = marker.Position
			end
		end
	end)
	return function()
		finished = true
		controls.stop()
		if lesson then
			lesson.stop()
		end
		step:Disconnect()
		if pending then
			task.cancel(pending)
			pending = nil
		end
	end
end

return Precision
