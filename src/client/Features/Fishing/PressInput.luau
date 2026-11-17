--!strict
-- One "press" input for every minigame: tap anywhere, left click, Space, gamepad A/R2.
-- While enabled it sinks those inputs so Space doesn't jump and taps don't walk.

local ContextActionService = game:GetService("ContextActionService")

local ACTION = "FishingPress"

local PressInput = {}

local held = false
local pressed = Instance.new("BindableEvent")

PressInput.Pressed = pressed.Event

function PressInput.isHeld(): boolean
	return held
end

local function handle(
	_: string,
	state: Enum.UserInputState,
	_: InputObject
): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		held = true
		pressed:Fire()
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		held = false
	end
	return Enum.ContextActionResult.Sink
end

function PressInput.enable()
	held = false
	ContextActionService:BindActionAtPriority(
		ACTION,
		handle,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.Touch,
		Enum.KeyCode.Space,
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.ButtonR2
	)
end

function PressInput.disable()
	held = false
	ContextActionService:UnbindAction(ACTION)
end

return PressInput
