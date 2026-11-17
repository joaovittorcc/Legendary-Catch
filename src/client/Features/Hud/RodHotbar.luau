--!strict
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Art = require(script.Parent:WaitForChild("Art"))
local Assets = require(script.Parent:WaitForChild("Assets"))
local Motion = require(script.Parent:WaitForChild("Motion"))

local RodHotbar = {}
local player = Players.LocalPlayer
local action = "AdventureRodSlot"
local backpackGui = Enum.CoreGuiType.Backpack

function RodHotbar.mount(gui: ScreenGui, panelChanged: RBXScriptSignal, panel: () -> string)
	local slot = Art.button(Assets.rod)
	slot.Name = "RodHotbar"
	slot.AnchorPoint = Vector2.new(0.5, 1)
	slot.Position = UDim2.new(0.5, 0, 1, -10)
	slot.Size = UDim2.fromOffset(62, 64)
	slot.Visible = false
	local caption = Art.caption(slot, "ItemName", Text.rodSlot, 26)
	caption.Size = UDim2.fromScale(0.78, 0.18)
	caption.Position = UDim2.fromScale(0.11, 0.75)
	local key = Art.caption(slot, "Shortcut", "1", 15, Theme.gold)
	key.Size = UDim2.fromScale(0.2, 0.2)
	key.Position = UDim2.fromScale(0.13, 0.1)
	Motion.mount(slot, 0, 8)
	slot.Parent = gui

	local character: Model? = nil
	local backpack: Backpack? = nil
	local rigSignals: { RBXScriptConnection } = {}
	local bagSignals: { RBXScriptConnection } = {}
	local tool: Tool? = nil
	local function layout()
		local height = math.clamp(math.round(gui.AbsoluteSize.Y * 0.175), 58, 160)
		slot.Size = UDim2.fromOffset(height, height)
	end
	local nativeEnabled: boolean? = nil
	local queued = false
	local playerGui = player:WaitForChild("PlayerGui")
	local fishing = playerGui:WaitForChild("FishingUI")
	local minigame = fishing:WaitForChild("Panel") :: Frame

	local function refresh()
		local candidate: Tool? = nil
		local busyInventory = false
		local function collect(container: Instance?)
			if not container then
				return
			end
			for _, item in container:GetChildren() do
				if item:IsA("Tool") then
					if candidate or item.Name ~= "Rod" then
						busyInventory = true
					else
						candidate = item
					end
				end
			end
		end
		collect(character)
		collect(backpack)
		tool = if not busyInventory then candidate else nil

		-- Only take over the inventory when its entire contents can be shown in this slot.
		if tool and nativeEnabled == nil then
			local enabled = StarterGui:GetCoreGuiEnabled(backpackGui)
			if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, backpackGui, false) then
				nativeEnabled = enabled
			end
		elseif not tool and nativeEnabled ~= nil then
			if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, backpackGui, nativeEnabled) then
				nativeEnabled = nil
			end
		end
		local current = tool
		slot.Visible = current ~= nil
			and nativeEnabled ~= nil
			and gui.Enabled
			and panel() == ""
			and not minigame.Visible
			and player:GetAttribute("CatchRevealActive") ~= true
		slot.ImageColor3 = if current and current.Parent == character
			then Color3.new(1, 1, 1)
			else Color3.fromRGB(218, 219, 242)
		key.Visible = UserInputService.KeyboardEnabled
			and UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch
	end

	local function schedule()
		if queued then
			return
		end
		queued = true
		task.defer(function()
			queued = false
			if gui.Parent then
				refresh()
			end
		end)
	end
	local function watch(container: Instance?, signals: { RBXScriptConnection })
		for _, signal in signals do
			signal:Disconnect()
		end
		table.clear(signals)
		if container then
			local function toolChanged(child: Instance)
				if child:IsA("Tool") then
					schedule()
				end
			end
			table.insert(signals, container.ChildAdded:Connect(toolChanged))
			table.insert(signals, container.ChildRemoved:Connect(toolChanged))
		end
		schedule()
	end
	local function setCharacter(model: Model?)
		character = model
		watch(character, rigSignals)
	end
	local function syncBackpack(child: Instance)
		if child:IsA("Backpack") then
			backpack = player:FindFirstChildOfClass("Backpack")
			watch(backpack, bagSignals)
		end
	end
	local function toggle()
		local current = tool
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not slot.Visible or not current or not humanoid or humanoid.Health <= 0 then
			return
		end
		if current.Parent == character then
			humanoid:UnequipTools()
		elseif current.Parent == backpack then
			humanoid:EquipTool(current)
		end
	end

	slot.Activated:Connect(toggle)
	ContextActionService:BindAction(action, function(_, state)
		if not slot.Visible or UserInputService:GetFocusedTextBox() then
			return Enum.ContextActionResult.Pass
		end
		if state == Enum.UserInputState.Begin then
			toggle()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.One, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)

	local signals = {
		player.CharacterAdded:Connect(setCharacter),
		player.CharacterRemoving:Connect(function()
			setCharacter(nil)
		end),
		player.ChildAdded:Connect(syncBackpack),
		player.ChildRemoved:Connect(syncBackpack),
		player:GetAttributeChangedSignal("CatchRevealActive"):Connect(schedule),
		minigame:GetPropertyChangedSignal("Visible"):Connect(schedule),
		gui:GetPropertyChangedSignal("Enabled"):Connect(schedule),
		gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout),
		UserInputService.LastInputTypeChanged:Connect(schedule),
		panelChanged:Connect(schedule),
	}
	gui.Destroying:Once(function()
		ContextActionService:UnbindAction(action)
		for _, pool in { signals, rigSignals, bagSignals } do
			for _, signal in pool do
				signal:Disconnect()
			end
		end
		if nativeEnabled ~= nil then
			pcall(StarterGui.SetCoreGuiEnabled, StarterGui, backpackGui, nativeEnabled)
		end
	end)
	backpack = player:FindFirstChildOfClass("Backpack")
	watch(backpack, bagSignals)
	setCharacter(player.Character)
	layout()
end

return RodHotbar
