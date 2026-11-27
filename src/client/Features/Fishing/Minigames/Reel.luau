--!strict
-- Vertical, directly draggable control zone with responsive hold/release and keyboard input.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi")).minigames
local Audio = require(script.Parent.Parent.Parent:WaitForChild("Audio"))
local Control = require(script.Parent.Parent:WaitForChild("Control"))
local Ui = require(script.Parent.Parent:WaitForChild("Ui"))
local Input = require(script.Parent:WaitForChild("Input"))
local Lesson = require(script.Parent:WaitForChild("ReelLesson"))

local Reel = {}

function Reel.run(
	area: Frame,
	tier: number,
	color: Color3,
	done: (boolean, boolean?) -> ()
): () -> ()
	local cfg = Config.REEL
	local ease = Control.ease()
	local width = math.min(Config.tierValue(cfg.zoneWidth, tier) * ease, 0.5)
	local fishSpeed = Config.tierValue(cfg.fishSpeed, tier)
	local retarget = Config.tierValue(cfg.fishRetarget, tier)
	local gain = Config.tierValue(cfg.gain, tier)
	local failRise = Config.tierValue(cfg.failRise, tier) / ease
	local rng = Random.new()
	local dock = Ui.frame(
		area,
		"ReelDock",
		UDim2.new(0, 124, 0.50, 0),
		UDim2.fromScale(0.76, 0.56),
		Theme.ink,
		1
	)
	dock.AnchorPoint = Vector2.new(0.5, 0.5)
	local cap = Instance.new("UISizeConstraint")
	cap.MinSize = Vector2.new(124, 150)
	cap.MaxSize = Vector2.new(124, 520)
	cap.Parent = dock
	local function layoutDock()
		local size = area.AbsoluteSize
		local compact = size.Y < 450 or size.Y > size.X
		local y = if compact then 0.50 else 0.58
		local x = if size.Y > size.X then 0.74 else 0.76
		dock.Position = UDim2.fromScale(x, y)
	end
	layoutDock()
	local dockLayoutConn = area:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutDock)
	local rail =
		Ui.frame(dock, "Bar", UDim2.new(0, 56, 1, -10), UDim2.fromOffset(2, 5), Theme.outline)
	Ui.corner(rail, 0.32)
	Ui.stroke(rail, Theme.ink, 3)
	Ui.bounce(dock)
	local hint = Ui.label(
		area,
		"ReelControls",
		UDim2.new(0.92, 0, 0, 22),
		UDim2.new(0.5, 0, 0, 48),
		"",
		Theme.sand
	)
	hint.AnchorPoint = Vector2.new(0.5, 0)
	local function updateHint()
		local input = UserInputService.PreferredInput
		hint.Text = if input == Enum.PreferredInput.Touch
			then Text.reelControls
			elseif input == Enum.PreferredInput.Gamepad then Text.reelGamepad
			else Text.reelKeyboard
	end
	updateHint()
	local hintConnection = UserInputService:GetPropertyChangedSignal("PreferredInput")
		:Connect(updateHint)
	local zone = Ui.frame(
		rail,
		"Zone",
		UDim2.fromScale(1, width),
		UDim2.fromScale(0, 0.5),
		color:Lerp(Color3.fromRGB(114, 255, 194), 0.4),
		0.12
	)
	zone.AnchorPoint = Vector2.new(0, 0.5)
	Theme.surface(zone, color, 9)
	Ui.stroke(zone, color:Lerp(Theme.sand, 0.45), 2)
	local fish = Ui.frame(rail, "Fish", UDim2.fromOffset(34, 21), UDim2.fromScale(0.5, 0.5), color)
	fish.AnchorPoint = Vector2.new(0.5, 0.5)
	Ui.corner(fish, 0.5)
	Ui.stroke(fish, Theme.sand, 2)
	local tail = Ui.frame(fish, "Tail", UDim2.fromOffset(12, 12), UDim2.fromScale(0.9, 0.3), color)
	tail.Rotation = 45
	local eye =
		Ui.frame(fish, "Eye", UDim2.fromOffset(5, 5), UDim2.fromScale(0.22, 0.27), Theme.ink)
	Ui.corner(eye, 0.5)
	local meter = Ui.frame(
		dock,
		"ProgressRing",
		UDim2.fromOffset(54, 54),
		UDim2.new(0, 91, 0.5, 0),
		Theme.outline
	)
	meter.AnchorPoint = Vector2.new(0.5, 0.5)
	Ui.corner(meter, 0.5)
	Ui.stroke(meter, Theme.ink, 2)
	local segments: { Frame } = {}
	for index = 1, 20 do
		local angle = (index - 1) / 20 * math.pi * 2
		local segment = Ui.frame(
			meter,
			"Segment",
			UDim2.fromOffset(4, 6),
			UDim2.fromOffset(27 + math.sin(angle) * 22, 27 - math.cos(angle) * 22),
			Theme.muted
		)
		segment.AnchorPoint = Vector2.new(0.5, 0.5)
		segment.Rotation = math.deg(angle)
		Ui.corner(segment, 0.5)
		segments[index] = segment
	end
	local status = Ui.label(
		meter,
		"CatchProgress",
		UDim2.fromScale(0.59, 0.42),
		UDim2.fromScale(0.205, 0.29),
		"30%",
		Theme.sand
	)
	local risk =
		Ui.frame(dock, "FailBack", UDim2.fromOffset(50, 7), UDim2.new(0, 66, 0.5, 46), Theme.ink)
	Ui.corner(risk, 0.5)
	Ui.stroke(risk, Theme.rose, 1)
	local riskFill = Ui.frame(
		risk,
		"FailFill",
		UDim2.fromScale(0, 1),
		UDim2.fromScale(0, 0),
		Color3.fromRGB(255, 89, 120)
	)
	Ui.corner(riskFill, 0.5)
	local lineLabel = Ui.label(
		dock,
		"TensionLabel",
		UDim2.fromOffset(58, 16),
		UDim2.new(0, 63, 0.5, 28),
		Text.reelRisk,
		Theme.sand
	)
	local alignment = Ui.label(
		dock,
		"Alignment",
		UDim2.fromOffset(64, 27),
		UDim2.new(0, 59, 0.5, -56),
		Text.reelTrack,
		Theme.sand
	)
	alignment.TextWrapped = true
	local critical = false

	local lesson = Lesson.show("reel")
	local controls = Input.bind(function(point)
		if lesson and lesson.active() then
			lesson.press(point)
		end
	end)
	local pos, velocity = 0.5, 0
	local fishPos, fishTarget = 0.5, 0.5
	local nextTarget = 0
	local progress, fail = 0.3, 0
	local elapsed = 0
	local finished = false
	local everOutside = false
	local lastInside: boolean? = nil
	local lit = 0
	local percent = -1
	local hit50 = false
	local hit80 = false
	local impactEnd = 0
	local nextMissCue = 0
	local zoneStroke = zone:FindFirstChildOfClass("UIStroke")
	local meterScale = Instance.new("UIScale")
	meterScale.Parent = meter
	local riskBasePos = risk.Position
	local pending: thread? = nil
	local step: RBXScriptConnection

	local function popMeter(pitch: number)
		Audio.play("hit", 0.14, pitch)
		Audio.play("click", 0.12, pitch)
		if not Ui.reduced() then
			if math.abs(fishPos - pos) < width * 0.15 then
				impactEnd = os.clock() + 0.06
			end
			meterScale.Scale = 1.18
			TweenService:Create(
				meterScale,
				TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end
	end

	local function stop()
		dockLayoutConn:Disconnect()
		hintConnection:Disconnect()
		controls.stop()
		step:Disconnect()
		if lesson then
			lesson.stop()
		end
	end
	local function finish(success: boolean)
		finished = true
		stop()
		Ui.exitPulse(rail, if success then color else Theme.rose)
		Ui.feedback(area, UDim2.fromScale(0.55, 0.25), color, success, success and not everOutside)
		pending = task.delay(0.34, function()
			pending = nil
			done(success, success and not everOutside)
		end)
	end
	step = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		if lesson and lesson.active() then
			lesson.update(dt)
			return
		end
		if not Ui.reduced() and os.clock() < impactEnd then
			return
		end
		elapsed += dt
		local movementDt = math.min(dt, 0.1)
		local drag = controls.drag()
		local origin = controls.origin()
		local localOrigin = if origin
			then origin - rail.AbsolutePosition
			else Vector2.new(-100, -100)
		local startsOnRail = localOrigin.X >= -24
			and localOrigin.X <= rail.AbsoluteSize.X + 24
			and localOrigin.Y >= -24
			and localOrigin.Y <= rail.AbsoluteSize.Y + 24
		local half = width / 2
		if drag and startsOnRail then
			pos = math.clamp(
				1 - (drag.Y - rail.AbsolutePosition.Y) / math.max(rail.AbsoluteSize.Y, 1),
				half,
				1 - half
			)
			velocity = 0
		else
			local axis = controls.axis()
			local direction = if axis ~= 0 then axis elseif controls.held() then 1 else -1
			local desired = direction * cfg.zoneMaxSpeed
			velocity += (desired - velocity) * (1 - math.exp(-cfg.zoneAccel * 6 * movementDt))
			pos = math.clamp(pos + velocity * movementDt, half, 1 - half)
		end
		if elapsed >= nextTarget then
			fishTarget = rng:NextNumber(0.08, 0.92)
			nextTarget = elapsed + retarget
		end
		local prevFish = fishPos
		fishPos += math.clamp(fishTarget - fishPos, -fishSpeed * movementDt, fishSpeed * movementDt)
		local fishVel = (fishPos - prevFish) / math.max(movementDt, 0.001)
		local inside = math.abs(fishPos - pos) <= half
		if inside then
			progress += gain * dt
			fail = math.max(0, fail - cfg.failRecover * dt)
		else
			progress = math.max(0, progress - cfg.drain * dt)
			fail += failRise * dt
			everOutside = true
		end
		zone.Position = UDim2.fromScale(0, 1 - pos)
		if lastInside == true and not inside and elapsed >= nextMissCue then
			nextMissCue = elapsed + 0.45
			Ui.feedback(area, UDim2.fromScale(0.55, 0.25), color, false)
		end
		if inside ~= lastInside then
			lastInside = inside
			alignment.Text = if inside then "✓ " .. Text.reelTrack else Text.reelRecover
			alignment.TextColor3 = if inside then Theme.sand else Theme.gold
			zone.BackgroundTransparency = if inside then 0.06 else 0.35
			eye.BackgroundColor3 = if inside then Theme.ink else Theme.wood
			if zoneStroke then
				zoneStroke.Thickness = if inside then 3 else 1.5
				zoneStroke.Color = if inside
					then Color3.new(1, 1, 1)
					else color:Lerp(Theme.sand, 0.45)
			end
		end
		fish.Position = UDim2.fromScale(0.5, 1 - fishPos)
		if not Ui.reduced() then
			-- Alive swimming tilt + tail flutter as the fish darts up and down.
			local tilt = math.clamp(-fishVel * 18, -22, 22) + math.sin(elapsed * 14) * 5
			fish.Rotation = tilt
			tail.Rotation = 45 + math.sin(elapsed * 22) * 14
		else
			fish.Rotation = 0
			tail.Rotation = 45
		end
		local ratio = math.clamp(progress, 0, 1)
		if not hit50 and ratio >= 0.5 then
			hit50 = true
			popMeter(1.08)
		elseif not hit80 and ratio >= 0.8 then
			hit80 = true
			popMeter(1.22)
		end
		local nextLit = math.floor(ratio * #segments)
		if nextLit ~= lit then
			for index = math.min(lit, nextLit) + 1, math.max(lit, nextLit) do
				segments[index].BackgroundColor3 = if index <= nextLit then color else Theme.muted
			end
			lit = nextLit
		end
		local failClamped = math.clamp(fail, 0, 1)
		riskFill.Size = UDim2.fromScale(failClamped, 1)
		local highTension = failClamped > 0.65
		if highTension ~= critical then
			critical = highTension
			lineLabel.Text = if critical then Text.reelCritical else Text.reelRisk
			lineLabel.TextColor3 = if critical then Theme.rose else Theme.sand
		end
		if highTension and not Ui.reduced() then
			risk.Position = riskBasePos + UDim2.fromOffset(math.sin(elapsed * 42) * 2.5, 0)
		else
			risk.Position = riskBasePos
		end
		local nextPercent = math.floor(ratio * 100)
		if nextPercent ~= percent then
			percent = nextPercent
			status.Text = string.format("%d%%", percent)
		end
		if progress >= 1 or fail >= 1 then
			finish(progress >= 1)
		end
	end)
	return function()
		if pending then
			task.cancel(pending)
			pending = nil
		end
		if not finished then
			finished = true
			stop()
		end
	end
end

return Reel
