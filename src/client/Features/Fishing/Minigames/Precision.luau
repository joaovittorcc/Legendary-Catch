--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Text = require(Shared:WaitForChild("StringsUi")).minigames
local Theme = require(Shared:WaitForChild("UiTheme"))
local Control = require(script.Parent.Parent:WaitForChild("Control"))
local PressInput = require(script.Parent.Parent:WaitForChild("PressInput"))
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
	local bar = Ui.frame(area, "Bar", UDim2.fromScale(1, 0.34), UDim2.fromScale(0, 0.3), color)
	Ui.gloss(bar, Color3.fromRGB(80, 147, 240))
	local zone =
		Ui.frame(bar, "Zone", UDim2.fromScale(zoneWidth, 1), UDim2.fromScale(0.5, 0), color, 0.12)
	zone.AnchorPoint = Vector2.new(0.5, 0)
	Ui.corner(zone, 0.3)
	Ui.stroke(zone, Theme.gold, 3)
	local marker =
		Ui.frame(bar, "Marker", UDim2.new(0, 7, 1.35, 0), UDim2.fromScale(0.08, 0.5), Theme.sand)
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	Ui.corner(marker, 0.5)
	Ui.stroke(marker, Theme.ink, 2)
	local timer = Ui.label(
		area,
		"DecisionTime",
		UDim2.fromScale(0.25, 0.22),
		UDim2.fromScale(0.75, 0),
		"",
		Theme.gold
	)
	local timerTrack = Ui.frame(
		area,
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
			area,
			"Hit" .. i,
			UDim2.fromScale(0.07, 0.19),
			UDim2.fromScale((i - 1) * 0.09, 0.78),
			Color3.fromRGB(157, 199, 246)
		)
		Ui.corner(pip, 0.5)
		Ui.stroke(pip, Theme.sand, 1.5)
		table.insert(pips, pip)
	end
	for i = 1, cfg.missesAllowed do
		local light = Ui.frame(
			area,
			"Miss" .. i,
			UDim2.fromScale(0.05, 0.19),
			UDim2.fromScale(1 - i * 0.075, 0.78),
			Color3.fromRGB(157, 199, 246)
		)
		Ui.corner(light, 0.5)
		table.insert(lives, light)
	end
	local pos, direction = 0.08, 1
	local velocity = speed
	local feint = 0
	local hits, misses = 0, 0
	local remaining = cfg.decisionSeconds
	local cooldown = 0
	local finished = false
	local pending: thread? = nil
	local press: RBXScriptConnection
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
		press:Disconnect()
		step:Disconnect()
		pending = task.delay(0.34, done, success, success and misses == 0)
	end
	local function miss(timedOut: boolean)
		misses += 1
		lives[misses].BackgroundColor3 = Color3.fromRGB(255, 83, 118)
		Ui.feedback(area, false)
		if timedOut then
			timer.Text = Text.timeUp
		end
		remaining = cfg.decisionSeconds
		cooldown = 0.18
		if misses >= cfg.missesAllowed then
			finish(false)
		end
	end
	moveZone()
	press = PressInput.Pressed:Connect(function()
		if finished or cooldown > 0 then
			return
		end
		cooldown = 0.18
		local distance = math.abs(pos - zone.Position.X.Scale)
		if distance <= zoneWidth / 2 then
			hits += 1
			pips[hits].BackgroundColor3 = Theme.gold
			Ui.feedback(area, true, distance < zoneWidth * 0.15)
			remaining = cfg.decisionSeconds
			if hits >= cfg.hitsNeeded then
				finish(true)
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
		cooldown = math.max(0, cooldown - dt)
		remaining -= dt
		timer.Text = string.format(Text.seconds, math.max(0, remaining))
		timeFill.Size = UDim2.fromScale(math.max(0, remaining / cfg.decisionSeconds), 1)
		timeFill.BackgroundColor3 = if remaining < 1.2
			then Color3.fromRGB(255, 96, 127)
			else Theme.gold
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
	end)
	return function()
		finished = true
		press:Disconnect()
		step:Disconnect()
		if pending then
			task.cancel(pending)
			pending = nil
		end
	end
end

return Precision
