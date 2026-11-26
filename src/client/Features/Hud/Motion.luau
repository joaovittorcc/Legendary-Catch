--!strict
--[[
	Motion.luau
	Shared UI animation controller using ONE SINGLE RunService.Heartbeat loop for:
	- Periodic glossy shimmer sweeps across buttons/headers/cards
	- Staggered gentle breathing for hero icons & mascots
	- Rhythmic pulsing for notification badges
	- Squash & stretch on button tap/press, hover lift (Touch-safe), elastic panel pop-open,
	  fast pop-close, and cascaded list/grid item entrances.
	Strictly respects LocalPlayer attribute "ReduceEffects" (layout stays 100% identical).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VfxFolder = Shared:FindFirstChild("Vfx")
local SfxKit: any = nil
if VfxFolder then
	local sfxMod = VfxFolder:FindFirstChild("SfxKit")
	if sfxMod and sfxMod:IsA("ModuleScript") then
		local ok, mod = pcall(require, sfxMod)
		if ok then
			SfxKit = mod
		end
	end
end

export type MountOptions = {
	shimmer: boolean?,
	shimmerInterval: number?,
	onPressChange: ((boolean) -> ())?,
	clickSound: boolean?,
}

type ShimmerEntry = {
	target: GuiObject,
	layer: Frame,
	gradient: UIGradient,
	interval: number,
	phase: number,
	sway: number,
	baseRotation: number,
	active: boolean,
}

type PulseEntry = {
	target: GuiObject,
	scale: UIScale,
	speed: number,
	amp: number,
	phase: number,
	active: boolean,
}

local Motion = {}
local player = Players.LocalPlayer

local shimmers: { ShimmerEntry } = {}
local pulses: { PulseEntry } = {}
local loopConn: RBXScriptConnection? = nil
local nextPhase = 0
local accumulator = 0

local function isReduced(): boolean
	return player:GetAttribute("ReduceEffects") == true
end

local function isVisibleInTree(target: GuiObject): boolean
	if not target.Parent or not target.Visible then
		return false
	end
	local screen = target:FindFirstAncestorWhichIsA("ScreenGui")
	if not screen or not screen.Enabled then
		return false
	end
	return true
end

local function ensureScale(target: GuiObject, name: string?): UIScale
	local existing = if name
		then target:FindFirstChild(name)
		else target:FindFirstChild("MotionScale")
	if existing and existing:IsA("UIScale") then
		return existing
	end
	local anyScale = target:FindFirstChildOfClass("UIScale")
	if anyScale then
		return anyScale
	end
	local created = Instance.new("UIScale")
	created.Name = name or "MotionScale"
	created.Scale = 1
	created.Parent = target
	return created
end

local function stopSharedLoopIfIdle()
	if loopConn and #shimmers == 0 and #pulses == 0 then
		loopConn:Disconnect()
		loopConn = nil
	end
end

local function stepSharedLoop(dt: number)
	accumulator += dt
	if accumulator < 1 / 30 then
		return
	end
	accumulator = 0

	local reduced = isReduced()
	local now = os.clock()

	-- Update shimmers & gentle sway
	for i = #shimmers, 1, -1 do
		local entry = shimmers[i]
		if not entry.active or not entry.target.Parent or not entry.layer.Parent then
			if entry.layer.Parent then
				entry.layer.Visible = false
			end
			if entry.target.Parent then
				entry.target.Rotation = entry.baseRotation
			end
			table.remove(shimmers, i)
		elseif reduced or not isVisibleInTree(entry.target) then
			entry.layer.Visible = false
			if entry.sway ~= 0 then
				entry.target.Rotation = entry.baseRotation
			end
		else
			if entry.sway ~= 0 then
				entry.target.Rotation = entry.baseRotation
					+ math.sin(now * 3.1 + entry.phase) * entry.sway
			end
			local cycle = (now + entry.phase) % entry.interval
			local sweepDuration = 0.68
			if cycle < sweepDuration then
				entry.layer.Visible = true
				entry.gradient.Offset = Vector2.new((cycle / sweepDuration) * 2.2 - 1.1, 0)
			else
				entry.layer.Visible = false
			end
		end
	end

	-- Update breathing icons & pulsing badges
	for i = #pulses, 1, -1 do
		local entry = pulses[i]
		if not entry.active or not entry.target.Parent or not entry.scale.Parent then
			if entry.scale.Parent then
				entry.scale.Scale = 1
			end
			table.remove(pulses, i)
		elseif reduced or not isVisibleInTree(entry.target) then
			entry.scale.Scale = 1
		else
			entry.scale.Scale = 1 + math.sin(now * entry.speed + entry.phase) * entry.amp
		end
	end

	stopSharedLoopIfIdle()
end

local function ensureSharedLoop()
	if loopConn then
		return
	end
	loopConn = RunService.Heartbeat:Connect(stepSharedLoop)
end

local function createShimmerLayer(target: GuiObject, radius: number?): (Frame, UIGradient)
	local existing = target:FindFirstChild("MotionShine")
	if existing and existing:IsA("Frame") then
		local grad = existing:FindFirstChildOfClass("UIGradient")
		if grad then
			return existing, grad
		end
		existing:Destroy()
	end
	local layer = Instance.new("Frame")
	layer.Name = "MotionShine"
	layer.AnchorPoint = Vector2.new(0.5, 0.5)
	layer.Position = UDim2.fromScale(0.5, 0.48)
	layer.Size = UDim2.new(1, -12, 0.72, 0)
	layer.BackgroundColor3 = Color3.new(1, 1, 1)
	layer.BackgroundTransparency = 0.45
	layer.BorderSizePixel = 0
	layer.Visible = false
	layer.ZIndex = target.ZIndex + 4
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 16)
	corner.Parent = layer
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 24
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.38, 1),
		NumberSequenceKeypoint.new(0.5, 0.24),
		NumberSequenceKeypoint.new(0.62, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = layer
	layer.Parent = target
	return layer, gradient
end

-- Register a periodic glossy shimmer sweep on the single shared loop.
function Motion.shimmer(target: GuiObject, interval: number?, phase: number?): () -> ()
	local layer, gradient = createShimmerLayer(target)
	nextPhase += 1.37
	local entry: ShimmerEntry = {
		target = target,
		layer = layer,
		gradient = gradient,
		interval = math.max(2.2, interval or 5.5),
		phase = phase or nextPhase,
		sway = 0,
		baseRotation = target.Rotation,
		active = true,
	}
	table.insert(shimmers, entry)
	ensureSharedLoop()
	target.Destroying:Once(function()
		entry.active = false
	end)
	return function()
		entry.active = false
		if layer.Parent then
			layer.Visible = false
		end
	end
end

-- Staggered gentle breathing for big icons / mascots (uses the single shared loop).
function Motion.breathe(target: GuiObject, amp: number?, speed: number?, phase: number?): () -> ()
	local scale = ensureScale(target, "BreatheScale")
	nextPhase += 1.15
	local entry: PulseEntry = {
		target = target,
		scale = scale,
		speed = speed or 2.8,
		amp = amp or 0.045,
		phase = phase or nextPhase,
		active = true,
	}
	table.insert(pulses, entry)
	ensureSharedLoop()
	target.Destroying:Once(function()
		entry.active = false
	end)
	return function()
		entry.active = false
		if scale.Parent then
			scale.Scale = 1
		end
	end
end

-- Rhythmic playful pulse for notification badges / NEW tags (uses the single shared loop).
function Motion.pulseBadge(target: GuiObject): () -> ()
	return Motion.breathe(target, 0.11, 5.4)
end

-- Elastic panel pop-open animation (instant when ReduceEffects = true).
function Motion.popOpen(target: GuiObject, backdrop: Frame?)
	local scale = ensureScale(target, "PanelScale")
	if isReduced() then
		scale.Scale = 1
		if backdrop then
			backdrop.BackgroundTransparency = 0.62
		end
		return
	end
	scale.Scale = 0.84
	TweenService:Create(
		scale,
		TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	):Play()
	if backdrop then
		backdrop.BackgroundTransparency = 1
		TweenService:Create(
			backdrop,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.62 }
		):Play()
	end
end

-- Quick snappy close animation (instant when ReduceEffects = true).
function Motion.popClose(target: GuiObject, backdrop: Frame?, onDone: () -> ())
	local scale = ensureScale(target, "PanelScale")
	if isReduced() then
		scale.Scale = 1
		onDone()
		return
	end
	local tw = TweenService:Create(
		scale,
		TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Scale = 0.90 }
	)
	if backdrop then
		TweenService:Create(
			backdrop,
			TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		):Play()
	end
	tw.Completed:Once(function()
		scale.Scale = 1
		onDone()
	end)
	tw:Play()
end

-- Cascaded spring entrance for list/grid children (capped for mobile smoothness).
function Motion.cascade(container: Instance, maxItems: number?)
	if isReduced() then
		return
	end
	local items: { GuiObject } = {}
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") and child.Visible then
			table.insert(items, child)
		end
	end
	if #items == 0 then
		return
	end
	table.sort(items, function(a, b)
		if a.LayoutOrder ~= b.LayoutOrder then
			return a.LayoutOrder < b.LayoutOrder
		end
		return a.Name < b.Name
	end)
	local cap = math.min(#items, maxItems or 10)
	for i = 1, cap do
		local item = items[i]
		local sc = ensureScale(item, "CascadeScale")
		sc.Scale = 0.88
		TweenService:Create(
			sc,
			TweenInfo.new(
				0.22,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out,
				0,
				false,
				(i - 1) * 0.026
			),
			{ Scale = 1 }
		):Play()
	end
end

-- Mount squash & stretch, hover lift (Touch-safe), optional shimmer/sway, and press callbacks.
function Motion.mount(target: GuiObject, sway: number?, period: number?, options: MountOptions?)
	local scale = ensureScale(target, "MotionScale")
	local opts = options or ({} :: MountOptions)

	local shimmerEntry: ShimmerEntry? = nil
	if sway ~= nil or opts.shimmer == true then
		local layer, gradient = createShimmerLayer(target)
		nextPhase += 1.41
		local entry: ShimmerEntry = {
			target = target,
			layer = layer,
			gradient = gradient,
			interval = math.max(2.4, period or opts.shimmerInterval or 6.2),
			phase = nextPhase,
			sway = sway or 0,
			baseRotation = target.Rotation,
			active = true,
		}
		table.insert(shimmers, entry)
		ensureSharedLoop()
		shimmerEntry = entry
	end

	local tween: Tween? = nil
	local hoverTween: Tween? = nil
	local hovered = false
	local pointerPressed = false
	local skipActivatedPulse = false
	local buttonSignals: { RBXScriptConnection } = {}

	local function setPressedVisual(pressed: boolean)
		if opts.onPressChange then
			opts.onPressChange(pressed)
		end
	end

	local function scaleTo(value: number, duration: number, style: Enum.EasingStyle?)
		if isReduced() then
			scale.Scale = 1
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
		scale.Scale = if hovered and not isReduced() then 1.045 else 1
	end

	local function pulse(from: number)
		if isReduced() then
			return
		end
		stopPulse()
		scale.Scale = from
		local pop = TweenService:Create(
			scale,
			TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1.06 }
		)
		tween = pop
		pop.Completed:Once(function(state)
			if tween ~= pop or state ~= Enum.PlaybackState.Completed then
				return
			end
			local settle = TweenService:Create(
				scale,
				TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
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
					or not target.Active
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
				if pointerPressed then
					pointerPressed = false
					setPressedVisual(false)
				end
				scaleTo(1, 0.12)
			end)
		)
		table.insert(
			buttonSignals,
			target.SelectionGained:Connect(function()
				if target.Interactable and target.Active then
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
					or not target.Active
					or (
						input.UserInputType ~= Enum.UserInputType.MouseButton1
						and input.UserInputType ~= Enum.UserInputType.Touch
					)
				then
					return
				end
				pointerPressed = true
				setPressedVisual(true)
				scaleTo(0.91, 0.065)
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
				setPressedVisual(false)
				if isReduced() then
					scale.Scale = 1
					return
				end
				skipActivatedPulse = true
				local pop = TweenService:Create(
					scale,
					TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1.06 }
				)
				tween = pop
				pop.Completed:Once(function(state)
					if tween ~= pop or state ~= Enum.PlaybackState.Completed then
						return
					end
					local settle = TweenService:Create(
						scale,
						TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Scale = if hovered then 1.045 else 1 }
					)
					tween = settle
					settle:Play()
				end)
				pop:Play()
				task.delay(0.22, function()
					skipActivatedPulse = false
				end)
			end)
		)
		table.insert(
			buttonSignals,
			target.Activated:Connect(function()
				if opts.clickSound ~= false and SfxKit then
					SfxKit.play("ui_click")
				end
				if skipActivatedPulse then
					skipActivatedPulse = false
					return
				end
				pulse(0.91)
			end)
		)
	end

	local choice = player:GetAttributeChangedSignal("ReduceEffects"):Connect(function()
		if isReduced() then
			if hoverTween then
				hoverTween:Cancel()
				hoverTween = nil
			end
			stopPulse()
			scale.Scale = 1
		end
	end)

	target.Destroying:Once(function()
		choice:Disconnect()
		for _, connection in buttonSignals do
			connection:Disconnect()
		end
		if hoverTween then
			hoverTween:Cancel()
			hoverTween = nil
		end
		if shimmerEntry then
			shimmerEntry.active = false
		end
		stopPulse()
	end)

	return {
		pulse = pulse,
		finishIdle = function()
			if shimmerEntry then
				shimmerEntry.active = false
				if shimmerEntry.layer.Parent then
					shimmerEntry.layer.Visible = false
				end
			end
		end,
	}
end

return Motion
