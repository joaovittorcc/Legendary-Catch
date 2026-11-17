--!strict
-- Track raw pointing inputs alongside FishingPress and reserve directional keys for the game.
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Input = {}
local sequence = 0

function Input.bind(press: (Vector2?) -> ())
	sequence += 1
	local action = "FishingAim" .. sequence
	local pointer: InputObject? = nil
	local origin: Vector2? = nil
	local position: Vector2? = nil
	local dragging = false
	local held: { [Enum.KeyCode]: boolean } = {}
	local mouseHeld = false

	local function point(input: InputObject): Vector2
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local inset = GuiService:GetGuiInset()
			return UserInputService:GetMouseLocation() - inset
		end
		-- InputObject positions already use Core UI safe-inset coordinates.
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	local function reset()
		pointer, origin, position = nil, nil, nil
		dragging, mouseHeld = false, false
		table.clear(held)
	end
	local function handle(
		_: string,
		state: Enum.UserInputState,
		input: InputObject
	): Enum.ContextActionResult
		local isPointer = input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		if isPointer then
			if state == Enum.UserInputState.Begin and not pointer then
				pointer = input
				origin = point(input)
				position = origin
				mouseHeld = true
				dragging = false
				press(position)
			elseif
				pointer == input
				and (state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel)
			then
				pointer, origin, position = nil, nil, nil
				dragging, mouseHeld = false, false
			end
		else
			local key = input.KeyCode
			local down = state == Enum.UserInputState.Begin
			if down then
				held[key] = true
				if
					key == Enum.KeyCode.Space
					or key == Enum.KeyCode.ButtonA
					or key == Enum.KeyCode.ButtonR2
				then
					press(nil)
				end
			elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				held[key] = nil
			end
		end
		if
			input.KeyCode == Enum.KeyCode.W
			or input.KeyCode == Enum.KeyCode.S
			or input.KeyCode == Enum.KeyCode.Up
			or input.KeyCode == Enum.KeyCode.Down
		then
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end
	ContextActionService:BindActionAtPriority(
		action,
		handle,
		false,
		Enum.ContextActionPriority.High.Value + 1,
		Enum.KeyCode.Space,
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.ButtonR2,
		Enum.KeyCode.W,
		Enum.KeyCode.S,
		Enum.KeyCode.Up,
		Enum.KeyCode.Down
	)
	-- Raw pointer events still arrive when FishingPress or a GuiButton consumes the tap.
	local began = UserInputService.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			handle(action, Enum.UserInputState.Begin, input)
		end
	end)
	local changed = UserInputService.InputChanged:Connect(function(input: InputObject)
		if
			pointer
			and (input == pointer or input.UserInputType == Enum.UserInputType.MouseMovement)
		then
			local nextPosition = point(input)
			position = nextPosition
			local start = origin
			if start and (nextPosition - start).Magnitude >= 6 then
				dragging = true
			end
		end
	end)
	local released = UserInputService.InputEnded:Connect(function(input: InputObject)
		if
			input == pointer
			or (input.UserInputType == Enum.UserInputType.MouseButton1 and mouseHeld)
		then
			pointer, origin, position = nil, nil, nil
			dragging, mouseHeld = false, false
		end
	end)
	local focus = UserInputService.WindowFocusReleased:Connect(reset)
	return {
		held = function(): boolean
			return mouseHeld
				or held[Enum.KeyCode.Space] == true
				or held[Enum.KeyCode.ButtonA] == true
				or held[Enum.KeyCode.ButtonR2] == true
		end,
		axis = function(): number
			local up = held[Enum.KeyCode.W] or held[Enum.KeyCode.Up]
			local down = held[Enum.KeyCode.S] or held[Enum.KeyCode.Down]
			return (if up then 1 else 0) - (if down then 1 else 0)
		end,
		drag = function(): Vector2?
			return if dragging then position else nil
		end,
		origin = function(): Vector2?
			return origin
		end,
		stop = function()
			ContextActionService:UnbindAction(action)
			began:Disconnect()
			changed:Disconnect()
			released:Disconnect()
			focus:Disconnect()
			reset()
		end,
	}
end

return Input
