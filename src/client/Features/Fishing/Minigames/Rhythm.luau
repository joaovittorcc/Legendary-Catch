--!strict
-- Rhythm rings: a circle appears with an outer ring closing in; press when the ring meets
-- the circle. Tapping anywhere counts (big, forgiving input for phones and kids).
-- Clear all rings to catch; 2 misses (bad timing or a ring that runs out) lose it.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Minigames = script.Parent
local Fishing = Minigames.Parent
local FishingConfig = require(
	game:GetService("ReplicatedStorage")
		:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("Fishing")
)
local Control = require(Fishing:WaitForChild("Control"))
local PressInput = require(Fishing:WaitForChild("PressInput"))
local Ui = require(Fishing:WaitForChild("Ui"))

local Rhythm = {}

local GREY = Color3.fromRGB(70, 74, 100)
local RED = Color3.fromRGB(255, 60, 70)
local TARGET_SIZE = 0.62 -- of the area height
local START_SCALE = 2.6

-- ringCount overrides the tier's ring count (training uses 1-2 rings).
function Rhythm.run(
	area: Frame,
	tier: number,
	color: Color3,
	done: (boolean) -> (),
	ringCount: number?
): () -> ()
	local cfg = FishingConfig.RHYTHM
	local total = ringCount or math.floor(FishingConfig.tierValue(cfg.rings, tier))
	local shrink = FishingConfig.tierValue(cfg.shrinkSeconds, tier)
	local window = shrink * cfg.window * Control.ease()

	local field = Ui.frame(
		area,
		"Field",
		UDim2.fromScale(0.78, 1),
		UDim2.fromScale(0.11, 0),
		Color3.new(0, 0, 0),
		1
	)
	field.ClipsDescendants = false

	local lives: { Frame } = {}
	for i = 1, cfg.missesAllowed do
		local light = Ui.frame(
			area,
			"Miss" .. i,
			UDim2.fromScale(0.05, 0.16),
			UDim2.fromScale(0.95, 0.05 + (i - 1) * 0.22),
			GREY
		)
		Ui.corner(light, 0.5)
		local ratio = Instance.new("UIAspectRatioConstraint")
		ratio.AspectRatio = 1
		ratio.Parent = light
		table.insert(lives, light)
	end
	local counter = Ui.label(
		area,
		"Counter",
		UDim2.fromScale(0.1, 0.3),
		UDim2.fromScale(0, 0.35),
		`0/{total}`,
		color
	)

	local hits, misses = 0, 0
	local finished = false
	local pressConn: RBXScriptConnection
	local stepConn: RBXScriptConnection
	local function finish(success: boolean)
		finished = true
		pressConn:Disconnect()
		stepConn:Disconnect()
		task.delay(0.34, done, success)
	end
	local current: { target: Frame, ring: Frame, t: number }? = nil
	local gap = 0.4

	local function circle(
		name: string,
		scale: number,
		fill: Color3,
		transparency: number,
		strokeColor: Color3,
		thickness: number
	): Frame
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromScale(TARGET_SIZE * scale, TARGET_SIZE * scale)
		f.SizeConstraint = Enum.SizeConstraint.RelativeYY
		f.BackgroundColor3 = fill
		f.BackgroundTransparency = transparency
		f.BorderSizePixel = 0
		Ui.corner(f, 0.5)
		Ui.stroke(f, strokeColor, thickness)
		f.Parent = field
		return f
	end

	local function spawnRing()
		local x = 0.15 + math.random() * 0.7
		local target = circle("Target", 1, color, 0.55, Color3.new(1, 1, 1), 3)
		target.Position = UDim2.fromScale(x, 0.5)
		local ring = circle("Approach", START_SCALE, Color3.new(0, 0, 0), 1, color, 4)
		ring.Position = target.Position
		current = { target = target, ring = ring, t = 0 }
	end

	local function clear(success: boolean)
		local c = current
		current = nil
		if not c then
			return
		end
		c.ring:Destroy()
		local burst = TweenService:Create(c.target, TweenInfo.new(0.25), {
			Size = UDim2.fromScale(TARGET_SIZE * 1.5, TARGET_SIZE * 1.5),
			BackgroundTransparency = 1,
			BackgroundColor3 = if success then Color3.new(1, 1, 1) else RED,
		})
		burst:Play()
		task.delay(0.26, function()
			c.target:Destroy()
		end)
	end

	local function miss()
		Ui.feedback(area, false)
		misses += 1
		local light = lives[misses]
		light.BackgroundColor3 = RED
		TweenService:Create(
			light,
			TweenInfo.new(0.12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true),
			{
				BackgroundTransparency = 0.7,
			}
		):Play()
		clear(false)
		if misses >= cfg.missesAllowed then
			finish(false)
		end
	end

	pressConn = PressInput.Pressed:Connect(function()
		local c = current
		if finished or not c then
			return
		end
		if math.abs(c.t - shrink) <= window then
			Ui.feedback(area, true, math.abs(c.t - shrink) < window * 0.25)
			hits += 1
			counter.Text = `{hits}/{total}`
			clear(true)
			if hits >= total then
				finish(true)
			end
		else
			miss()
		end
		gap = cfg.gapSeconds
	end)

	stepConn = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		local c = current
		if not c then
			gap -= dt
			if gap <= 0 then
				spawnRing()
			end
			return
		end
		c.t += dt
		local a = math.clamp(c.t / shrink, 0, 1)
		local scale = START_SCALE + (1 - START_SCALE) * a
		c.ring.Size = UDim2.fromScale(TARGET_SIZE * scale, TARGET_SIZE * scale)
		-- Ring flashes white inside the timing window.
		local stroke = c.ring:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if math.abs(c.t - shrink) <= window then Color3.new(1, 1, 1) else color
		end
		if c.t > shrink + window then
			gap = cfg.gapSeconds
			miss()
		end
	end)

	return function()
		finished = true
		pressConn:Disconnect()
		stepConn:Disconnect()
	end
end

return Rhythm
