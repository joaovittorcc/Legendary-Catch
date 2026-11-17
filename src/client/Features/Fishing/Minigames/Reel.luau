--!strict
-- Vertical, directly draggable control zone with responsive hold/release and keyboard input.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi")).minigames
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
	Ui.reelLayout()
	local rail =
		Ui.frame(area, "Bar", UDim2.fromScale(0.22, 0.87), UDim2.fromScale(0.26, 0.01), Theme.track)
	Ui.gloss(rail, Color3.fromRGB(81, 141, 228))
	local zone = Ui.frame(
		rail,
		"Zone",
		UDim2.fromScale(1, width),
		UDim2.fromScale(0, 0.5),
		Color3.fromRGB(114, 255, 194),
		0.12
	)
	zone.AnchorPoint = Vector2.new(0, 0.5)
	Ui.corner(zone, 0.2)
	Ui.stroke(zone, Theme.gold, 3)
	local fish = Ui.frame(rail, "Fish", UDim2.fromOffset(25, 15), UDim2.fromScale(0.5, 0.5), color)
	fish.AnchorPoint = Vector2.new(0.5, 0.5)
	Ui.corner(fish, 0.5)
	Ui.stroke(fish, Theme.sand, 2)
	local tail = Ui.frame(fish, "Tail", UDim2.fromOffset(8, 8), UDim2.fromScale(0.9, 0.3), color)
	tail.Rotation = 45
	local eye =
		Ui.frame(fish, "Eye", UDim2.fromOffset(3, 3), UDim2.fromScale(0.22, 0.27), Theme.ink)
	Ui.corner(eye, 0.5)
	local meter = Ui.frame(
		area,
		"ProgressBack",
		UDim2.fromScale(0.09, 0.62),
		UDim2.fromScale(0.72, 0.08),
		Theme.track
	)
	Ui.corner(meter, 0.3)
	local fill =
		Ui.frame(meter, "ProgressFill", UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 1), Theme.gold)
	fill.AnchorPoint = Vector2.new(0, 1)
	Ui.gloss(fill, Theme.gold)
	local status = Ui.label(
		area,
		"CatchProgress",
		UDim2.fromScale(0.45, 0.12),
		UDim2.fromScale(0.54, 0.75),
		string.format(Text.reelProgress, 30),
		Theme.sand
	)
	local risk = Ui.frame(
		area,
		"FailBack",
		UDim2.fromScale(0.94, 0.055),
		UDim2.fromScale(0.03, 0.94),
		Theme.track
	)
	Ui.corner(risk, 0.5)
	local riskFill = Ui.frame(
		risk,
		"FailFill",
		UDim2.fromScale(0, 1),
		UDim2.fromScale(0, 0),
		Color3.fromRGB(255, 89, 120)
	)
	Ui.corner(riskFill, 0.5)

	local lesson = Lesson.show()
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
	local pending: thread? = nil
	local step: RBXScriptConnection

	local function stop()
		controls.stop()
		step:Disconnect()
		if lesson then
			lesson.stop()
		end
	end
	local function finish(success: boolean)
		finished = true
		stop()
		Ui.feedback(area, success, success and not everOutside)
		pending = task.delay(0.34, done, success, success and not everOutside)
	end
	step = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		if lesson and lesson.active() then
			lesson.update(dt)
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
		fishPos += math.clamp(fishTarget - fishPos, -fishSpeed * movementDt, fishSpeed * movementDt)
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
		zone.BackgroundTransparency = if inside then 0.08 else 0.35
		fish.Position = UDim2.fromScale(0.5, 1 - fishPos)
		fill.Size = UDim2.fromScale(1, math.clamp(progress, 0, 1))
		riskFill.Size = UDim2.fromScale(math.clamp(fail, 0, 1), 1)
		status.Text = string.format(Text.reelProgress, math.floor(math.clamp(progress, 0, 1) * 100))
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
