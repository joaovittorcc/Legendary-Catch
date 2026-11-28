--!strict
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi")).training
local Theme = require(Shared:WaitForChild("UiTheme"))
local Fishing = script.Parent.Parent:WaitForChild("Fishing")
local Ui = require(Fishing.Ui)
local Input = require(Fishing.Minigames.Input)

local Drill = {}
type ReturnInput = { held: () -> boolean, stop: () -> () }
local CONTROL_TIME = 5.5
local CONTROL_TARGET = 1.9
local CONTROL_HALF_ZONE = 0.21
local BITE_WINDOW = 1.3

function Drill.run(
	area: Frame,
	stat: string,
	color: Color3,
	rounds: number,
	sample: (number, boolean) -> (),
	done: (boolean) -> (),
	isStop: (Vector2) -> boolean
): () -> ()
	local control = stat == "Control"
	local panel = Ui.frame(
		area,
		"TrainingDrill",
		UDim2.new(0.82, 0, 0, 76),
		UDim2.new(0.5, 0, 1, -72),
		Theme.ink
	)
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.BackgroundTransparency = 0.12
	Theme.corner(panel, 14)
	local outline = Instance.new("UIStroke")
	outline.Color = color
	outline.Transparency = 0.5
	outline.Parent = panel
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(320, 76)
	cap.Parent = panel
	local title = Ui.label(
		panel,
		"Instruction",
		UDim2.fromScale(0.9, 0.28),
		UDim2.fromScale(0.05, 0.05),
		if control then Text.holdHint else Text.biteWait,
		Theme.sand
	)
	local track = Ui.frame(
		panel,
		"Track",
		UDim2.fromScale(0.84, 0.18),
		UDim2.fromScale(0.08, 0.44),
		Theme.muted
	)
	Ui.corner(track, 0.4)
	local zone = Ui.frame(
		track,
		"Zone",
		UDim2.fromScale(if control then 2 * CONTROL_HALF_ZONE else 0, 1),
		UDim2.fromScale(0.34, 0),
		color
	)
	Ui.corner(zone, 0.4)
	local marker =
		Ui.frame(track, "Marker", UDim2.new(0, 12, 1, 6), UDim2.fromScale(0.5, 0.5), Theme.sand)
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	Ui.corner(marker, 0.4)
	marker.Visible = control
	local progress = Ui.label(
		panel,
		"Progress",
		UDim2.fromScale(0.9, 0.24),
		UDim2.fromScale(0.05, 0.69),
		"",
		color
	)
	local elapsed, tension, onTarget, hits = 0, 0.5, 0, 0
	local biteAt = Random.new():NextNumber(1.55, 2.65)
	local finished = false
	local render: RBXScriptConnection?
	local input: ReturnInput?
	local function stop()
		if finished then
			return
		end
		finished = true
		if render then
			render:Disconnect()
		end
		if input then
			input.stop()
		end
		panel:Destroy()
	end
	local function finish(success: boolean)
		stop()
		done(success)
	end
	input = Input.bind(function(point)
		if point and isStop(point) then
			return
		end
		if not control then
			if elapsed < biteAt or elapsed > biteAt + BITE_WINDOW then
				finish(false)
				return
			end
			hits += 1
			if hits >= rounds then
				finish(true)
			else
				biteAt = elapsed + Random.new():NextNumber(1.1, 2.0)
			end
		end
	end)
	render = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		if control then
			tension =
				math.clamp(tension + dt * (if input and input.held() then 0.72 else -0.53), 0, 1)
			local center = 0.5 + math.sin(elapsed * 2.1) * 0.12
			zone.Position = UDim2.fromScale(center - CONTROL_HALF_ZONE, 0)
			local inside = math.abs(tension - center) <= CONTROL_HALF_ZONE
			if inside then
				onTarget += dt
			end
			marker.Position = UDim2.fromScale(tension, 0.5)
			marker.BackgroundColor3 = if inside then Theme.sand else Theme.rose
			progress.Text = string.format(
				Text.tensionProgress,
				math.floor(math.min(onTarget / CONTROL_TARGET, 1) * 100)
			)
			sample(tension, false)
			if elapsed >= CONTROL_TIME or onTarget >= CONTROL_TARGET then
				finish(onTarget >= CONTROL_TARGET)
			end
		else
			local biting = elapsed >= biteAt
			title.Text = if biting
				then Text.biteNow
				elseif elapsed >= biteAt - 0.48 then Text.biteRipple
				else Text.biteWait
			zone.Position = UDim2.fromScale(0, 0)
			zone.Size = UDim2.fromScale(
				if biting then math.clamp(1 - (elapsed - biteAt) / BITE_WINDOW, 0, 1) else 0,
				1
			)
			progress.Text = string.format(Text.biteProgress, hits, rounds)
			sample(if biting then 0.6 else 0, biting)
			if elapsed > biteAt + BITE_WINDOW then
				finish(false)
			end
		end
	end)
	return stop
end

return Drill
