--!strict
local CaptureService = game:GetService("CaptureService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local Panel = require(script.Parent.Parent.Hud:WaitForChild("Panel"))

local PhotoMode = {}
local DURATION = 30
local FIELD_OF_VIEW = 38

local function framePhoto(gui: ScreenGui, name: string, rarity: string, color: Color3)
	local frame =
		Ui.frame(gui, "Frame", UDim2.new(1, -26, 1, -26), UDim2.fromOffset(13, 13), color, 1)
	Theme.corner(frame, 14)
	local outline = Instance.new("UIStroke")
	outline.Color = color
	outline.Thickness = 1.5
	outline.Transparency = 0.25
	outline.Parent = frame

	local caption = Ui.frame(
		frame,
		"Caption",
		UDim2.new(0.65, 0, 0, 52),
		UDim2.new(0.5, 0, 1, -11),
		Theme.ink,
		0.12
	)
	caption.AnchorPoint = Vector2.new(0.5, 1)
	Theme.surface(caption, color, 10)
	local max = Instance.new("UISizeConstraint")
	max.MaxSize = Vector2.new(345, 52)
	max.Parent = caption

	Ui.label(
		caption,
		"Game",
		UDim2.new(1, -16, 0, 16),
		UDim2.fromOffset(8, 5),
		Text.arrival.title .. "  ·  " .. Theme.rarityLabel(rarity),
		Theme.sand
	)
	Ui.label(
		caption,
		"Creature",
		UDim2.new(1, -16, 0, 23),
		UDim2.fromOffset(8, 22),
		name,
		Theme.sand
	)
end

local function hideInterface(playerGui: PlayerGui): () -> ()
	local layers: { [LayerCollector]: boolean } = {}
	local function hide(instance: Instance)
		if instance:IsA("LayerCollector") then
			layers[instance] = instance.Enabled
			instance.Enabled = false
		end
	end
	for _, instance in playerGui:GetChildren() do
		hide(instance)
	end
	for _, instance in Workspace:GetDescendants() do
		if instance:IsA("BillboardGui") then
			hide(instance)
		end
	end
	-- CoreScripts register this separately from the game's ScreenGuis.
	local topbarHidden = pcall(StarterGui.SetCore, StarterGui, "TopbarEnabled", false)
	local touchControls = GuiService.TouchControlsEnabled
	local prompts = ProximityPromptService.Enabled
	GuiService.TouchControlsEnabled = false
	ProximityPromptService.Enabled = false
	return function()
		for layer, enabled in layers do
			if layer.Parent then
				layer.Enabled = enabled
			end
		end
		GuiService.TouchControlsEnabled = touchControls
		ProximityPromptService.Enabled = prompts
		if topbarHidden then
			pcall(StarterGui.SetCore, StarterGui, "TopbarEnabled", true)
		end
	end
end

function PhotoMode.show(model: Model, root: BasePart, name: string, rarity: string, color: Color3)
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local camera = Workspace.CurrentCamera
	if not playerGui or not camera then
		return
	end
	for _, child in model:GetDescendants() do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
			child:Clear()
		end
	end
	local bounds, size = model:GetBoundingBox()
	local target = bounds.Position
	local front = model:GetPivot().LookVector
	local yaw = math.atan2(front.X, front.Z) - 0.72
	local pitch = 0.16
	local halfFov = math.rad(FIELD_OF_VIEW / 2)
	local oldType, oldCFrame, oldFocus, oldFov =
		camera.CameraType, camera.CFrame, camera.Focus, camera.FieldOfView

	local raycast = RaycastParams.new()
	raycast.FilterType = Enum.RaycastFilterType.Exclude
	raycast.FilterDescendantsInstances = { model, root.Parent or root }
	raycast.IgnoreWater = true

	local restoreInterface = hideInterface(playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CatchPhoto"
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	framePhoto(gui, name, rarity, color)
	local hint = Ui.label(
		gui,
		"Hint",
		UDim2.new(0.9, 0, 0, 30),
		UDim2.new(0.05, 0, 0, 76),
		Text.photoHint,
		Theme.sand
	)
	local controls = Instance.new("Frame")
	controls.Name = "PhotoControls"
	controls.AnchorPoint = Vector2.new(0.5, 0)
	controls.Position = UDim2.new(0.5, 0, 0, 22)
	controls.Size = UDim2.new(1, -42, 0, 46)
	controls.BackgroundTransparency = 1
	local controlBounds = Instance.new("UISizeConstraint")
	controlBounds.MaxSize = Vector2.new(420, 46)
	controlBounds.Parent = controls
	local capture = Panel.button(controls, Text.photoTools.capture, Theme.crystal)
	capture.Name = "Capture"
	capture.Size = UDim2.new(1, -58, 1, 0)
	local save = Panel.button(controls, Text.photoTools.save, Theme.gold)
	save.Name = "Save"
	save.Size = UDim2.new(0.5, -31, 1, 0)
	save.Visible = false
	local share = Panel.button(controls, Text.photoTools.share, Theme.crystal)
	share.Name = "Share"
	share.Position = UDim2.new(0.5, -23, 0, 0)
	share.Size = UDim2.new(0.5, -35, 1, 0)
	share.TextSize = 14
	share.Visible = false
	local close = Panel.button(controls, Text.close, Theme.rose)
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.fromScale(1, 0)
	close.Size = UDim2.new(0, 52, 1, 0)
	close.TextSize = 13
	controls.Parent = gui
	gui.Parent = playerGui
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FIELD_OF_VIEW

	local open = true
	local deadline = os.clock() + DURATION
	local taking = false
	local captureVersion = 0
	local photo: ScreenshotCapture? = nil
	close.Activated:Connect(function()
		open = false
	end)
	capture.Activated:Connect(function()
		if taking then
			return
		end
		taking = true
		captureVersion += 1
		local version = captureVersion
		controls.Visible = false
		hint.Visible = false
		local function finish(result: ScreenshotCapture?)
			if not open or not gui.Parent or not taking or version ~= captureVersion then
				return
			end
			taking = false
			photo = result
			capture.Visible = result == nil
			save.Visible = result ~= nil
			share.Visible = result ~= nil
			controls.Visible = true
			hint.Visible = true
			hint.Text = if result then Text.photoTools.ready else Text.photoTools.unavailable
			deadline = os.clock() + DURATION
		end
		task.delay(4, finish, nil)
		local ok = pcall(function()
			CaptureService:TakeScreenshotCaptureAsync(function(result, screenshot)
				finish(if result == Enum.ScreenshotCaptureResult.Success then screenshot else nil)
			end, { UICaptureMode = Enum.UICaptureMode.All })
		end)
		if not ok then
			finish(nil)
		end
	end)
	save.Activated:Connect(function()
		local screenshot = photo
		if not screenshot or not save.Interactable then
			return
		end
		local ok = pcall(function()
			CaptureService:PromptSaveCapturesToGallery({ screenshot }, function(results)
				if gui.Parent and results[screenshot] then
					hint.Text = Text.photoTools.saved
					save.Interactable = false
				end
			end)
		end)
		if not ok then
			hint.Text = Text.photoTools.unavailable
		end
	end)
	share.Activated:Connect(function()
		local screenshot = photo
		if not screenshot then
			return
		end
		local ok = pcall(function()
			CaptureService:PromptShareCapture(
				Content.fromObject(screenshot),
				"",
				function() end,
				function() end
			)
		end)
		if not ok then
			hint.Text = Text.photoTools.shareUnavailable
		end
	end)

	local pointer: InputObject? = nil
	local startPoint = Vector2.zero
	local previousPoint = Vector2.zero
	local dragged = false
	local function point(input: InputObject): Vector2
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	local began = UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			open = false
		elseif
			not processed
			and not taking
			and not pointer
			and (
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			)
		then
			pointer = input
			startPoint = point(input)
			previousPoint = startPoint
			dragged = false
		end
	end)
	local changed = UserInputService.InputChanged:Connect(function(input: InputObject)
		local captured = pointer
		if not captured then
			return
		end
		local mouseDrag = captured.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseMovement
		if input ~= captured and not mouseDrag then
			return
		end
		local position = point(input)
		if not dragged and (position - startPoint).Magnitude < 8 then
			return
		end
		dragged = true
		local delta = position - previousPoint
		previousPoint = position
		yaw -= delta.X * 0.009
		pitch = math.clamp(pitch + delta.Y * 0.007, -0.12, 0.7)
	end)
	local ended = UserInputService.InputEnded:Connect(function(input)
		if input == pointer then
			pointer = nil
		end
	end)
	local menu = GuiService.MenuOpened:Connect(function()
		open = false
	end)

	while
		open
		and os.clock() < deadline
		and camera == Workspace.CurrentCamera
		and root:IsDescendantOf(Workspace)
	do
		local viewport = camera.ViewportSize
		local aspect = viewport.X / math.max(viewport.Y, 1)
		local aperture = math.atan(math.tan(halfFov) * math.min(aspect, 1))
		local distance = math.max(size.Magnitude * 0.56 / math.sin(aperture), 5)
		local direction = Vector3.new(
			math.sin(yaw) * math.cos(pitch),
			math.sin(pitch),
			math.cos(yaw) * math.cos(pitch)
		)
		local hit = Workspace:Raycast(target, direction * distance, raycast)
		camera.CFrame = CFrame.lookAt(
			target + direction * (if hit then math.max(hit.Distance - 0.35, 0.8) else distance),
			target
		)
		camera.Focus = CFrame.new(target)
		RunService.RenderStepped:Wait()
	end
	began:Disconnect()
	changed:Disconnect()
	ended:Disconnect()
	menu:Disconnect()
	gui:Destroy()
	camera.FieldOfView = oldFov
	camera.CFrame = oldCFrame
	camera.Focus = oldFocus
	camera.CameraType = oldType
	restoreInterface()
end

return PhotoMode
