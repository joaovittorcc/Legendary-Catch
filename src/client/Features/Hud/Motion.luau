--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Motion = {}
local player = Players.LocalPlayer

function Motion.mount(target: GuiObject, sway: number?, period: number?)
	local scale = Instance.new("UIScale")
	scale.Name = "MotionScale"
	scale.Parent = target

	local shine: Frame? = nil
	local beam: UIGradient? = nil
	if sway then
		local layer = Instance.new("Frame")
		layer.Name = "MotionShine"
		layer.Position = UDim2.fromScale(0.1, 0.08)
		layer.Size = UDim2.fromScale(0.8, 0.56)
		layer.BackgroundColor3 = Color3.new(1, 1, 1)
		layer.BackgroundTransparency = 0.54
		layer.BorderSizePixel = 0
		layer.Visible = false
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.45, 0)
		corner.Parent = layer
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 23
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.39, 1),
			NumberSequenceKeypoint.new(0.5, 0.27),
			NumberSequenceKeypoint.new(0.61, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = layer
		layer.Parent = target
		shine, beam = layer, gradient
	end

	local rotation = target.Rotation
	local idle: RBXScriptConnection? = nil
	local tween: Tween? = nil
	local hoverTween: Tween? = nil
	local hovered = false
	local pointerPressed = false
	local skipActivatedPulse = false
	local useIdle = sway ~= nil
	local buttonSignals: { RBXScriptConnection } = {}
	local function scaleTo(value: number, duration: number, style: Enum.EasingStyle?)
		if player:GetAttribute("ReduceEffects") == true then
			return
		end
		if hoverTween then
			hoverTween:Cancel()
		end
		local running = TweenService:Create(
			scale,
			TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = value }
		)
		hoverTween = running
		running:Play()
	end
	local function stopPulse()
		local running = tween
		tween = nil
		if running then
			running:Cancel()
		end
		scale.Scale = if hovered then 1.045 else 1
	end
	local function stopIdle()
		if idle then
			idle:Disconnect()
			idle = nil
		end
		target.Rotation = rotation
		if shine then
			shine.Visible = false
		end
	end
	local function updateIdle()
		stopIdle()
		if player:GetAttribute("ReduceEffects") == true then
			if hoverTween then
				hoverTween:Cancel()
				hoverTween = nil
			end
			stopPulse()
			scale.Scale = 1
			return
		end
		local layer, gradient = shine, beam
		if not useIdle or not layer or not gradient then
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
				layer.Visible = false
				return
			end
			local now = os.clock()
			local phase = now % interval
			target.Rotation = rotation + math.sin(now * 3.2) * (sway or 0)
			layer.Visible = phase < 0.7
			if layer.Visible then
				gradient.Offset = Vector2.new(phase / 0.35 - 1, 0)
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
			local settle = TweenService:Create(
				scale,
				TweenInfo.new(0.15),
				{ Scale = if hovered then 1.045 else 1 }
			)
			tween = settle
			settle:Play()
		end)
		pop:Play()
	end
	if target:IsA("GuiButton") then
		table.insert(
			buttonSignals,
			target.MouseEnter:Connect(function()
				if
					not target.Interactable
					or UserInputService:GetLastInputType() == Enum.UserInputType.Touch
				then
					return
				end
				hovered = true
				scaleTo(1.045, 0.12, Enum.EasingStyle.Back)
			end)
		)
		table.insert(
			buttonSignals,
			target.MouseLeave:Connect(function()
				hovered = false
				if not pointerPressed then
					scaleTo(1, 0.12)
				end
			end)
		)
		table.insert(
			buttonSignals,
			target.SelectionGained:Connect(function()
				if target.Interactable then
					hovered = true
					scaleTo(1.045, 0.12, Enum.EasingStyle.Back)
				end
			end)
		)
		table.insert(
			buttonSignals,
			target.SelectionLost:Connect(function()
				hovered = false
				scaleTo(1, 0.12)
			end)
		)
		table.insert(
			buttonSignals,
			target.InputBegan:Connect(function(input)
				if
					not target.Interactable
					or (
						input.UserInputType ~= Enum.UserInputType.MouseButton1
						and input.UserInputType ~= Enum.UserInputType.Touch
					)
				then
					return
				end
				pointerPressed = true
				scaleTo(0.9, 0.07)
			end)
		)
		table.insert(
			buttonSignals,
			target.InputEnded:Connect(function(input)
				if
					not pointerPressed
					or (
						input.UserInputType ~= Enum.UserInputType.MouseButton1
						and input.UserInputType ~= Enum.UserInputType.Touch
					)
				then
					return
				end
				pointerPressed = false
				if player:GetAttribute("ReduceEffects") == true then
					scale.Scale = 1
					return
				end
				skipActivatedPulse = true
				local pop = TweenService:Create(
					scale,
					TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1.05 }
				)
				tween = pop
				pop.Completed:Once(function(state)
					if tween ~= pop or state ~= Enum.PlaybackState.Completed then
						return
					end
					local settle = TweenService:Create(
						scale,
						TweenInfo.new(0.15),
						{ Scale = if hovered then 1.045 else 1 }
					)
					tween = settle
					settle:Play()
				end)
				pop:Play()
				task.delay(0.25, function()
					skipActivatedPulse = false
				end)
			end)
		)
		table.insert(
			buttonSignals,
			target.Activated:Connect(function()
				if skipActivatedPulse then
					skipActivatedPulse = false
					return
				end
				pulse(0.9)
			end)
		)
	end
	local choice = player:GetAttributeChangedSignal("ReduceEffects"):Connect(updateIdle)
	target.Destroying:Once(function()
		choice:Disconnect()
		for _, connection in buttonSignals do
			connection:Disconnect()
		end
		if hoverTween then
			hoverTween:Cancel()
			hoverTween = nil
		end
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
