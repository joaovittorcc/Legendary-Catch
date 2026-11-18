--!strict
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Products = require(Shared:WaitForChild("Config"):WaitForChild("Products"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Art = require(script.Parent:WaitForChild("Art"))
local Assets = require(script.Parent:WaitForChild("Assets"))
local Motion = require(script.Parent:WaitForChild("Motion"))

local RodHotbar = {}
local player = Players.LocalPlayer
local action = "AdventureRodSlot"
local backpackGui = Enum.CoreGuiType.Backpack

function RodHotbar.mount(
	gui: ScreenGui,
	panelChanged: RBXScriptSignal,
	panel: () -> string,
	bindFishingVisibility: (GuiObject, boolean?) -> (boolean) -> (),
	toast: ((string, Color3?) -> ())?
)
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

	local autoBtn = Instance.new("TextButton")
	autoBtn.Name = "AutoFishButton"
	autoBtn.AnchorPoint = Vector2.new(0, 1)
	autoBtn.Position = UDim2.new(0.5, 42, 1, -14)
	autoBtn.Size = UDim2.fromOffset(60, 46)
	autoBtn.AutoButtonColor = false
	autoBtn.Font = Theme.font
	autoBtn.Text = Text.autoFish.lockedButton
	autoBtn.TextColor3 = Theme.cream
	autoBtn.TextScaled = true
	autoBtn.TextStrokeTransparency = 0.25
	autoBtn.TextStrokeColor3 = Theme.outline
	autoBtn.Visible = false
	local autoLimit = Instance.new("UITextSizeConstraint")
	autoLimit.MaxTextSize = 15
	autoLimit.Parent = autoBtn
	local autoPad = Instance.new("UIPadding")
	autoPad.PaddingLeft = UDim.new(0, 6)
	autoPad.PaddingRight = UDim.new(0, 6)
	autoPad.Parent = autoBtn
	Theme.surface(autoBtn, Color3.fromRGB(158, 166, 180), 14, Color3.fromRGB(162, 172, 188))
	local autoStroke = autoBtn:FindFirstChildOfClass("UIStroke")
	local autoGradient = autoBtn:FindFirstChildOfClass("UIGradient")
	Motion.mount(autoBtn, 0, 8)
	autoBtn.Parent = gui

	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)

	local character: Model? = nil
	local backpack: Backpack? = nil
	local rigSignals: { RBXScriptConnection } = {}
	local bagSignals: { RBXScriptConnection } = {}
	local tool: Tool? = nil
	local function layout()
		local viewport = gui.AbsoluteSize
		local size = if viewport.Y > viewport.X
			then math.clamp(math.round(viewport.X * 0.16), 58, 82)
			else math.clamp(math.round(viewport.Y * 0.175), 58, 160)
		slot.Size = UDim2.fromOffset(size, size)
		local btnHeight = math.clamp(math.round(size * 0.68), 44, 58)
		local btnWidth = math.clamp(math.round(btnHeight * 1.45), 62, 86)
		autoBtn.Size = UDim2.fromOffset(btnWidth, btnHeight)
		autoBtn.Position =
			UDim2.new(0.5, math.floor(size / 2) + 8, 1, -10 - math.floor((size - btnHeight) / 2))
	end
	local setFishingVisible = bindFishingVisibility(slot, false)
	local setAutoVisible = bindFishingVisibility(autoBtn, false)
	local function paintAuto(
		fill: Color3,
		strokeColor: Color3,
		thickness: number,
		textColor: Color3
	)
		autoBtn.BackgroundColor3 = fill
		autoBtn.TextColor3 = textColor
		if autoGradient then
			autoGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, fill:Lerp(Color3.new(1, 1, 1), 0.28)),
				ColorSequenceKeypoint.new(0.2, fill),
				ColorSequenceKeypoint.new(1, fill:Lerp(Color3.new(0, 0, 0), 0.14)),
			})
		end
		if autoStroke then
			autoStroke.Color = strokeColor
			autoStroke.Thickness = thickness
		end
	end
	local function refreshAutoVisual()
		local owned = player:GetAttribute(Products.AUTO_FISH_OWNED_ATTRIBUTE) == true
		local active = player:GetAttribute(Products.AUTO_FISH_ACTIVE_ATTRIBUTE) == true
		if not owned then
			autoBtn.Text = Text.autoFish.lockedButton
			paintAuto(
				Color3.fromRGB(165, 174, 190),
				Color3.fromRGB(78, 84, 98),
				2.5,
				Color3.fromRGB(244, 247, 252)
			)
		elseif active then
			autoBtn.Text = Text.autoFish.button
			paintAuto(
				Color3.fromRGB(72, 224, 134),
				Color3.fromRGB(190, 255, 214),
				3.5,
				Color3.new(1, 1, 1)
			)
		else
			autoBtn.Text = Text.autoFish.button
			paintAuto(Theme.crystal, Theme.outline, 3, Theme.ink)
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
		local visible = current ~= nil
			and nativeEnabled ~= nil
			and gui.Enabled
			and panel() == ""
			and not minigame.Visible
			and player:GetAttribute("CatchRevealActive") ~= true
		setFishingVisible(visible)
		setAutoVisible(visible)
		refreshAutoVisual()
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
	autoBtn.Activated:Connect(function()
		if not autoBtn.Visible then
			return
		end
		if player:GetAttribute(Products.AUTO_FISH_OWNED_ATTRIBUTE) ~= true then
			if toast then
				toast(Text.autoFish.passSoon, Color3.fromRGB(190, 204, 224))
			end
			return
		end
		local active = player:GetAttribute(Products.AUTO_FISH_ACTIVE_ATTRIBUTE) == true
		if not active then
			local current = tool
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if current and current.Parent == backpack and humanoid and humanoid.Health > 0 then
				humanoid:EquipTool(current)
			end
		end
		local remote = remotes:FindFirstChild(Net.SET_AUTO_FISH)
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer(not active)
		end
	end)
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
		player
			:GetAttributeChangedSignal(Products.AUTO_FISH_OWNED_ATTRIBUTE)
			:Connect(refreshAutoVisual),
		player
			:GetAttributeChangedSignal(Products.AUTO_FISH_ACTIVE_ATTRIBUTE)
			:Connect(refreshAutoVisual),
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
