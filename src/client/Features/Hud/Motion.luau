--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Motion = {}
local player = Players.LocalPlayer

function Motion.mount(target: GuiObject, sway: number?, period: number?)
	local scale = Instance.new("UIScale")
	scale.Name = "MotionScale"
	scale.Parent = target

	local shine = Instance.new("Frame")
	shine.Name = "MotionShine"
	shine.Position = UDim2.fromScale(0.1, 0.08)
	shine.Size = UDim2.fromScale(0.8, 0.56)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.54
	shine.BorderSizePixel = 0
	shine.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.45, 0)
	corner.Parent = shine
	local beam = Instance.new("UIGradient")
	beam.Rotation = 23
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.39, 1),
		NumberSequenceKeypoint.new(0.5, 0.27),
		NumberSequenceKeypoint.new(0.61, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	beam.Parent = shine
	shine.Parent = target

	local rotation = target.Rotation
	local idle: RBXScriptConnection? = nil
	local tween: Tween? = nil
	local useIdle = sway ~= nil
	local function stopPulse()
		local running = tween
		tween = nil
		if running then
			running:Cancel()
		end
		scale.Scale = 1
	end
	local function stopIdle()
		if idle then
			idle:Disconnect()
			idle = nil
		end
		target.Rotation = rotation
		shine.Visible = false
	end
	local function updateIdle()
		stopIdle()
		if player:GetAttribute("ReduceEffects") == true or not useIdle then
			stopPulse()
			return
		end
		local elapsed = 0
		local interval = period or 7
		idle = RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			if elapsed < 1 / 24 then
				return
			end
			elapsed = 0
			local screen = target:FindFirstAncestorWhichIsA("ScreenGui")
			if not target.Visible or not screen or not screen.Enabled then
				shine.Visible = false
				return
			end
			local now = os.clock()
			local phase = now % interval
			target.Rotation = rotation + math.sin(now * 3.2) * (sway or 0)
			shine.Visible = phase < 0.7
			if shine.Visible then
				beam.Offset = Vector2.new(phase / 0.35 - 1, 0)
			end
		end)
	end
	local function pulse(from: number)
		if player:GetAttribute("ReduceEffects") == true then
			return
		end
		stopPulse()
		scale.Scale = from
		local pop = TweenService:Create(scale, TweenInfo.new(0.11), { Scale = 1.05 })
		tween = pop
		pop.Completed:Once(function(state)
			if tween ~= pop or state ~= Enum.PlaybackState.Completed then
				return
			end
			local settle = TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 })
			tween = settle
			settle:Play()
		end)
		pop:Play()
	end
	if target:IsA("GuiButton") then
		target.Activated:Connect(function()
			pulse(0.9)
		end)
	end
	local choice = player:GetAttributeChangedSignal("ReduceEffects"):Connect(updateIdle)
	target.Destroying:Once(function()
		choice:Disconnect()
		stopIdle()
		stopPulse()
	end)
	updateIdle()

	return {
		pulse = pulse,
		finishIdle = function()
			useIdle = false
			stopIdle()
		end,
	}
end

return Motion
