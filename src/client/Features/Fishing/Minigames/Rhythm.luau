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
		UDim2.new(if ringCount then 0.5 else 1, if ringCount then 0 else -16, 0, top()),
		"",
		Theme.sand
	)
	counter.AnchorPoint = Vector2.new(if ringCount then 0.5 else 1, 0)
	counter.RichText = true
	local comboTrack =
		Ui.frame(counter, "ComboTrack", UDim2.new(1, 0, 0, 5), UDim2.new(0, 0, 1, 1), Theme.outline)
	Ui.corner(comboTrack, 0.5)
	local comboFill =
		Ui.frame(comboTrack, "ComboFill", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0), color)
	Ui.corner(comboFill, 0.5)
	Ui.bounce(counter)
	local combo = 0
	local disc = Ui.frame(area, "Target", UDim2.new(), UDim2.new(), color)
	disc.AnchorPoint = Vector2.new(0.5, 0.5)
	disc.Visible = false
	Theme.surface(disc, color, 80)
	local gleam = Ui.frame(
		disc,
		"Gleam",
		UDim2.fromScale(0.55, 0.10),
		UDim2.fromScale(0.225, 0.13),
		Theme.sand,
		0.45
	)
	Ui.corner(gleam, 0.5)
	local number =
		Ui.label(disc, "Order", UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.1, 0.1), "", Theme.ink)
	number.TextStrokeTransparency = 1
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 46
	limit.Parent = number
	local ring = Ui.frame(area, "Approach", UDim2.new(), UDim2.new(), color, 1)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Visible = false
	Ui.corner(ring, 0.5)
	Ui.stroke(ring, color, 4)
	local rim = ring:FindFirstChildOfClass("UIStroke") :: UIStroke
	local lesson = if ringCount then nil else Lesson.show("rhythm")
	local rng = Random.new()
	local hits, misses = 0, 0
	local finished = false
	local active = false
	local center = Vector2.zero
	local diameter = 60
	local time = 0
	local gap = 0.4
	local impactEnd = 0
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
		if not active or finished then
			return
		end
		active = false
		if success then
			hits += 1
			combo += 1
		else
			misses += 1
			combo = 0
		end
		local feedbackX = math.clamp(center.X, 80, math.max(80, area.AbsoluteSize.X - 80))
		Ui.feedback(
			area,
			UDim2.fromOffset(feedbackX, center.Y - diameter / 2 - 16),
			color,
			success,
			perfect,
			combo
		)
		updateCounter()
		local freeze = perfect and not Ui.reduced()
		if freeze then
			impactEnd = os.clock() + 0.06
		else
			disc.Visible = false
			ring.Visible = false
		end
		if misses >= cfg.missesAllowed or hits >= total then
			if freeze then
				task.delay(0.06, function()
					if disc.Parent then
						disc.Visible = false
						ring.Visible = false
					end
				end)
			end
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
		if not active or finished then
			return
		end
		local screenCenter = disc.AbsolutePosition + disc.AbsoluteSize / 2
		local inside = point == nil or (point - screenCenter).Magnitude <= diameter * 0.6
		local error = math.abs(time - shrink)
		resolve(inside and error <= window, inside and error <= window * 0.3)
	end)
	local function bounds(): (Vector2, Vector2, number)
		local size = area.AbsoluteSize
		local targetSize = math.clamp(math.min(size.X, size.Y) * 0.19, 60, 106)
		local margin = targetSize * 0.86
		local bottom = size.Y - (if size.Y < 430 then 72 else 112)
		local left = math.min(size.X / 2, math.max(size.X * 0.1, margin + 12))
		local safeTop = math.min(top() + 38 + margin, math.max(margin, bottom - margin))
		local low = Vector2.new(left, safeTop)
		local high = Vector2.new(size.X - left, math.max(safeTop, bottom - margin))
		return low, high, targetSize
	end
	local function spawnTarget()
		local low, high, size = bounds()
		diameter = size
		for _ = 1, 8 do
			center = low + (high - low) * Vector2.new(rng:NextNumber(), rng:NextNumber())
			if not previous or (center - previous).Magnitude >= diameter * 1.3 then
				break
			end
		end
		previous = center
		disc.Size = UDim2.fromOffset(diameter, diameter)
		disc.Position = UDim2.fromOffset(center.X, center.Y)
		number.Text = tostring(hits + 1)
		ring.Position = disc.Position
		ring.Size = UDim2.fromOffset(diameter * 1.65, diameter * 1.65)
		rim.Color = color
		disc.Visible = true
		ring.Visible = true
		time = 0
		active = true
	end
	local lastTop = top()
	local canvasSize = area.AbsoluteSize
	step = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		local currentTop = top()
		local size = area.AbsoluteSize
		if currentTop ~= lastTop or canvasSize ~= size then
			counter.Position =
				UDim2.new(counter.Position.X.Scale, counter.Position.X.Offset, 0, currentTop)
			lastTop, canvasSize = currentTop, size
			if active then
				local low, high, newDiameter = bounds()
				diameter = newDiameter
				center = Vector2.new(
					math.clamp(center.X, low.X, high.X),
					math.clamp(center.Y, low.Y, high.Y)
				)
				disc.Size = UDim2.fromOffset(diameter, diameter)
				disc.Position = UDim2.fromOffset(center.X, center.Y)
				ring.Position = disc.Position
			end
		end
		if lesson and lesson.active() then
			lesson.update(dt)
			return
		end
		if not active then
			if not Ui.reduced() and os.clock() < impactEnd then
				return
			end
			disc.Visible = false
			ring.Visible = false
			gap -= dt
			if gap <= 0 then
				spawnTarget()
			end
			return
		end
		time += dt
		local scale = 1.65 - 0.65 * math.clamp(time / shrink, 0, 1)
		ring.Size = UDim2.fromOffset(diameter * scale, diameter * scale)
		local accent = if math.abs(time - shrink) <= window then Theme.sand else color
		if rim.Color ~= accent then
			rim.Color = accent
		end
		if time > shrink + window then
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
