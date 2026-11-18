--!strict
-- Full-screen timing targets. Pointer hits must land on the current circle.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Text = require(Shared:WaitForChild("StringsUi")).minigames
local Theme = require(Shared:WaitForChild("UiTheme"))
local Control = require(script.Parent.Parent:WaitForChild("Control"))
local Ui = require(script.Parent.Parent:WaitForChild("Ui"))
local Input = require(script.Parent:WaitForChild("Input"))
local Features = script.Parent.Parent.Parent
local Hud = require(Features:WaitForChild("Hud"))
local Tutorial = require(Features:WaitForChild("Tutorial"))
local Lesson = require(script.Parent:WaitForChild("ReelLesson"))

local Rhythm = {}
type Target = { disc: Frame, ring: Frame, center: Vector2, diameter: number, time: number }

function Rhythm.run(
	area: Frame,
	tier: number,
	color: Color3,
	done: (boolean, boolean?) -> (),
	ringCount: number?,
	interceptPointer: ((Vector2) -> boolean)?
): () -> ()
	local cfg = Config.RHYTHM
	local total = ringCount or math.floor(Config.tierValue(cfg.rings, tier))
	local shrink = Config.tierValue(cfg.shrinkSeconds, tier)
	local window = math.min(shrink * cfg.window * Control.ease(), shrink * 0.46)
	local interval = Config.tierValue(cfg.gapByTier, tier)
	local function top(): number
		local topInset = math.max(Hud.navBottom() + 8, Tutorial.cardBottom() + 12)
		return topInset + (if ringCount then 94 else 0)
	end
	local counter = Ui.label(
		area,
		"Counter",
		UDim2.fromOffset(112, 24),
		UDim2.new(0.5, -56, 0, top()),
		"",
		Theme.sand
	)
	counter.RichText = true
	local comboTrack =
		Ui.frame(counter, "ComboTrack", UDim2.new(1, 0, 0, 5), UDim2.new(0, 0, 1, 1), Theme.outline)
	Ui.corner(comboTrack, 0.5)
	local comboFill =
		Ui.frame(comboTrack, "ComboFill", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0), color)
	Ui.corner(comboFill, 0.5)
	Ui.bounce(counter)
	local combo = 0
	local lesson = if ringCount then nil else Lesson.show("rhythm")
	local rng = Random.new()
	local hits, misses = 0, 0
	local finished = false
	local current: Target? = nil
	local gap = 0.4
	local previous: Vector2? = nil
	local pending: thread? = nil
	local step: RBXScriptConnection? = nil
	local controls: { stop: () -> () }? = nil
	local function cleanup()
		if step then
			step:Disconnect()
			step = nil
		end
		if controls then
			controls.stop()
			controls = nil
		end
		if lesson then
			lesson.stop()
		end
	end
	local function finish(success: boolean)
		if finished then
			return
		end
		finished = true
		cleanup()
		Ui.exitPulse(comboTrack, if success then color else Theme.rose)
		pending = task.delay(0.34, function()
			pending = nil
			done(success, success and misses == 0)
		end)
	end
	local function updateCounter()
		counter.Text = string.format(Text.rings, hits, total)
			.. '<font color="#FF7D94">'
			.. string.rep("  ×", misses)
			.. "</font>"
		comboFill.Size = UDim2.fromScale(combo / total, 1)
	end
	updateCounter()
	local function resolve(success: boolean, perfect: boolean)
		local target = current
		if not target or finished then
			return
		end
		current = nil
		target.disc:Destroy()
		target.ring:Destroy()
		if success then
			hits += 1
			combo += 1
		else
			misses += 1
			combo = 0
		end
		local feedbackX = math.clamp(target.center.X, 80, math.max(80, area.AbsoluteSize.X - 80))
		Ui.feedback(
			area,
			UDim2.fromOffset(feedbackX, target.center.Y - target.diameter / 2 - 16),
			color,
			success,
			perfect,
			combo
		)
		updateCounter()
		if misses >= cfg.missesAllowed or hits >= total then
			finish(hits >= total)
		else
			gap = interval
		end
	end
	controls = Input.bind(function(point)
		if point and interceptPointer and interceptPointer(point) then
			return
		end
		if lesson and lesson.active() then
			lesson.press(point)
			return
		end
		local target = current
		if not target or finished then
			return
		end
		local center = target.disc.AbsolutePosition + target.disc.AbsoluteSize / 2
		local inside = point == nil or (point - center).Magnitude <= target.diameter * 0.6
		local error = math.abs(target.time - shrink)
		resolve(inside and error <= window, inside and error <= window * 0.3)
	end)
	local function bounds(): (Vector2, Vector2, number)
		local size = area.AbsoluteSize
		local diameter = math.clamp(math.min(size.X, size.Y) * 0.19, 60, 106)
		local margin = diameter * 0.86
		local bottom = size.Y - (if size.Y < 430 then 72 else 112)
		local left = math.min(size.X / 2, math.max(size.X * 0.1, margin + 12))
		local safeTop = math.min(top() + 38 + margin, math.max(margin, bottom - margin))
		local low = Vector2.new(left, safeTop)
		local high = Vector2.new(size.X - left, math.max(safeTop, bottom - margin))
		return low, high, diameter
	end
	local function spawnTarget()
		local low, high, diameter = bounds()
		local center = low
		for _ = 1, 8 do
			center = low + (high - low) * Vector2.new(rng:NextNumber(), rng:NextNumber())
			if not previous or (center - previous).Magnitude >= diameter * 1.3 then
				break
			end
		end
		previous = center
		local disc = Ui.frame(
			area,
			"Target",
			UDim2.fromOffset(diameter, diameter),
			UDim2.fromOffset(center.X, center.Y),
			color
		)
		disc.AnchorPoint = Vector2.new(0.5, 0.5)
		Theme.surface(disc, color, diameter / 2)
		local gleam = Ui.frame(
			disc,
			"Gleam",
			UDim2.fromScale(0.55, 0.10),
			UDim2.fromScale(0.225, 0.13),
			Color3.new(1, 1, 1),
			0.65
		)
		Ui.corner(gleam, 0.5)
		local number = Ui.label(
			disc,
			"Order",
			UDim2.fromScale(0.8, 0.8),
			UDim2.fromScale(0.1, 0.1),
			tostring(hits + 1),
			Theme.sand
		)
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 46
		limit.Parent = number
		local ring = Ui.frame(
			area,
			"Approach",
			UDim2.fromOffset(diameter * 1.65, diameter * 1.65),
			disc.Position,
			color,
			1
		)
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		Ui.corner(ring, 0.5)
		Ui.stroke(ring, color, 4)
		Ui.bounce(disc)
		current = { disc = disc, ring = ring, center = center, diameter = diameter, time = 0 }
	end
	step = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		counter.Position = UDim2.new(0.5, -56, 0, top())
		if lesson and lesson.active() then
			lesson.update(dt)
			return
		end
		local target = current
		if not target then
			gap -= dt
			if gap <= 0 then
				spawnTarget()
			end
			return
		end
		target.time += dt
		local low, high, diameter = bounds()
		if target.diameter ~= diameter then
			target.diameter = diameter
			target.disc.Size = UDim2.fromOffset(diameter, diameter)
		end
		target.center = Vector2.new(
			math.clamp(target.center.X, low.X, high.X),
			math.clamp(target.center.Y, low.Y, high.Y)
		)
		target.disc.Position = UDim2.fromOffset(target.center.X, target.center.Y)
		target.ring.Position = target.disc.Position
		local scale = 1.65 - 0.65 * math.clamp(target.time / shrink, 0, 1)
		target.ring.Size = UDim2.fromOffset(target.diameter * scale, target.diameter * scale)
		local stroke = target.ring:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if math.abs(target.time - shrink) <= window then Theme.gold else color
		end
		if target.time > shrink + window then
			resolve(false, false)
		end
	end)
	return function()
		if pending then
			task.cancel(pending)
			pending = nil
		end
		finished = true
		cleanup()
	end
end

return Rhythm
