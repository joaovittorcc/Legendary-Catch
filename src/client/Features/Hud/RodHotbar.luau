--!strict
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Wood = require(script.Parent:WaitForChild("Wood"))

local RodHotbar = {}
local player = Players.LocalPlayer
local action = "AdventureRodSlot"
local backpackGui = Enum.CoreGuiType.Backpack

function RodHotbar.mount(gui: ScreenGui, panelChanged: RBXScriptSignal, panel: () -> string)
	local slot = Instance.new("TextButton")
	slot.Name = "RodHotbar"
	slot.Text = ""
	slot.AnchorPoint = Vector2.new(0.5, 1)
	slot.Position = UDim2.new(0.5, 0, 1, -10)
	slot.Size = UDim2.fromOffset(62, 64)
	slot.Visible = false
	local trim = Wood.mount(slot, true, Color3.fromRGB(25, 76, 76))
	local inactiveColor = trim.Color
	local caption = Wood.caption(slot, "ItemName", Text.rodSlot, 26)
	caption.Size = UDim2.new(1, -8, 0, 17)
	caption.Position = UDim2.new(0, 4, 1, -20)
	local key = Wood.caption(slot, "Shortcut", "1", 11, Theme.gold)
	key.Size = UDim2.fromOffset(12, 12)
	key.Position = UDim2.fromOffset(6, 5)
	slot.Parent = gui

	local character: Model? = nil
	local backpack: Backpack? = nil
	local rigSignals: { RBXScriptConnection } = {}
	local bagSignals: { RBXScriptConnection } = {}
	local tool: Tool? = nil
	local icon: Frame? = nil
	local iconRod: string? = nil
	local function layout()
		local height = math.clamp(math.round(gui.AbsoluteSize.Y * 0.18), 58, 174)
		slot.Size = UDim2.fromOffset(math.round(height * 0.96), height)
		caption.Size = UDim2.new(1, -13, 0.24, 0)
		caption.Position = UDim2.new(0, 6, 0.735, 0)
		if icon then
			local size = math.round(height * 0.69)
			icon.Size = UDim2.fromOffset(size, size)
		end
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
		trim.Color = if current and current.Parent == character
			then Theme.crystal
			else inactiveColor
		key.Visible = UserInputService.KeyboardEnabled
			and UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch
		if current then
			local id = current:GetAttribute("RodId")
			local rodId = if typeof(id) == "string" then id else Rods.STARTER
			if iconRod ~= rodId then
				if icon then
					icon:Destroy()
				end
				local rod = Rods.get(rodId)
				local newIcon = Wood.icon(slot, "Rod", 38, if rod then rod.tipColor else nil)
				newIcon.AnchorPoint = Vector2.new(0.5, 0)
				newIcon.Position = UDim2.new(0.5, 0, 0, 5)
				icon, iconRod = newIcon, rodId
				layout()
			end
		end
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
