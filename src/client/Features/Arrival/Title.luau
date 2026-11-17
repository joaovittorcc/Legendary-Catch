--!strict
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Panel = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local player = Players.LocalPlayer
local Title = {}

local function position(tag: string): Vector3?
	local part = CollectionService:GetTagged(tag)[1]
	return if part and part:IsA("BasePart") then part.Position else nil
end

local function panorama(camera: Camera, playerPosition: Vector3): () -> ()
	local saved = camera.CFrame
	local savedFocus = camera.Focus
	local workshop = position("WorkshopSpot") or playerPosition
	local lagoon = position("TrainingSpot") or playerPosition
	local pier = position("FishingZone") or playerPosition
	local focus = playerPosition * 0.4
		+ workshop * 0.25
		+ lagoon * 0.2
		+ pier * 0.15
		+ Vector3.new(0, 4, 0)
	local span = math.clamp((pier - lagoon).Magnitude * 0.53, 55, 110)
	local shore = (playerPosition - workshop) * Vector3.new(1, 0, 1)
	local direction = if shore.Magnitude > 1 then shore.Unit else Vector3.zAxis
	local across = Vector3.new(direction.Z, 0, -direction.X)
	local start = os.clock()
	local function step()
		if camera ~= workspace.CurrentCamera or camera.CameraType ~= Enum.CameraType.Scriptable then
			return
		end
		local angle = if player:GetAttribute("ReduceEffects") == true
			then 0.42
			else 0.42 + 0.7 * math.sin((os.clock() - start) * 0.12)
		local offset = (direction * math.cos(angle) + across * math.sin(angle)) * span
		camera.CFrame = CFrame.lookAt(focus + offset + Vector3.new(0, span * 0.51, 0), focus)
		camera.Focus = CFrame.new(focus)
	end
	camera.CameraType = Enum.CameraType.Scriptable
	step()
	local connection = RunService.RenderStepped:Connect(step)
	return function()
		connection:Disconnect()
		if
			workspace.CurrentCamera == camera
			and camera.CameraType == Enum.CameraType.Scriptable
		then
			camera.CFrame = saved
			camera.Focus = savedFocus
			camera.CameraType = Enum.CameraType.Custom
		end
	end
end

local function crystal(parent: Instance, x: number, y: number, size: number, color: Color3)
	local gem = Instance.new("Frame")
	gem.AnchorPoint = Vector2.new(0.5, 0.5)
	gem.Position = UDim2.fromScale(x, y)
	gem.Size = UDim2.fromOffset(size, size)
	gem.Rotation = 45
	gem.BackgroundColor3 = color
	gem.BorderSizePixel = 0
	local shine = Instance.new("UIGradient")
	shine.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(69, 93, 194))
	shine.Rotation = 65
	shine.Parent = gem
	Theme.corner(gem, 3)
	gem.Parent = parent
end

-- Returns true when the player skips the short arrival camera as well.
function Title.open(playerGui: PlayerGui): boolean
	local gui = Instance.new("ScreenGui")
	gui.Name = "IslandTitle"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 52
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local shade = Instance.new("Frame")
	shade.Name = "Backdrop"
	shade.Size = UDim2.fromScale(1, 1)
	shade.Active = true
	shade.BorderSizePixel = 0
	shade.BackgroundColor3 = Theme.ink
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.58),
		NumberSequenceKeypoint.new(0.45, 0.25),
		NumberSequenceKeypoint.new(1, 0.07),
	})
	gradient.Parent = shade
	shade.Parent = gui

	local crest = Instance.new("Frame")
	crest.AnchorPoint = Vector2.new(0.5, 0.5)
	crest.Position = UDim2.fromScale(0.5, 0.39)
	crest.Size = UDim2.fromScale(0.86, 0.29)
	crest.BackgroundTransparency = 1
	local max = Instance.new("UISizeConstraint")
	max.MaxSize = Vector2.new(750, 170)
	max.Parent = crest
	crest.Parent = shade

	local shadow = Panel.label(crest, Text.arrival.title, 42, Theme.ink)
	shadow.Size = UDim2.fromScale(1, 0.78)
	shadow.Position = UDim2.fromOffset(0, 4)
	shadow.TextScaled = true
	local logo = Panel.label(crest, Text.arrival.title, 42, Color3.new(1, 1, 1))
	logo.Name = "Logo"
	logo.Size = UDim2.fromScale(1, 0.78)
	logo.TextScaled = true
	logo.TextStrokeColor3 = Theme.ink
	logo.TextStrokeTransparency = 0.52
	local color = Instance.new("UIGradient")
	color.Color = ColorSequence.new(Theme.sand, Theme.crystal)
	color.Rotation = 90
	color.Parent = logo

	for i, tint in { Theme.crystal, Theme.rose, Theme.gold } do
		local wave = Instance.new("Frame")
		wave.AnchorPoint = Vector2.new(0.5, 0.5)
		wave.Size = UDim2.new(0.54 - i * 0.08, 0, 0, 2)
		wave.Position = UDim2.fromScale(0.5, 0.79 + i * 0.08)
		wave.BorderSizePixel = 0
		wave.BackgroundColor3 = tint
		wave.BackgroundTransparency = 0.16
		wave.Rotation = if i % 2 == 0 then -2 else 2
		Theme.corner(wave, 2)
		wave.Parent = crest
	end
	crystal(crest, 0.5, 0.81, 14, Theme.gold)
	crystal(crest, 0.18, 0.91, 9, Theme.crystal)
	crystal(crest, 0.82, 0.91, 9, Theme.rose)

	local play = Panel.button(shade, Text.arrival.play, Theme.crystal)
	play.Name = "Play"
	play.AnchorPoint = Vector2.new(0.5, 0.5)
	play.Position = UDim2.fromScale(0.5, 0.70)
	play.Size = UDim2.fromOffset(210, 56)
	play.TextSize = 23
	local skip = Panel.button(shade, Text.skip, Theme.gold)
	skip.Name = "SkipTitle"
	skip.AnchorPoint = Vector2.new(0.5, 0.5)
	skip.Position = UDim2.fromScale(0.5, 0.70) + UDim2.fromOffset(0, 60)
	skip.Size = UDim2.fromOffset(116, 44)

	local choice: string? = nil
	play.Activated:Connect(function()
		choice = "play"
	end)
	skip.Activated:Connect(function()
		choice = "skip"
	end)
	local keys = UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Return then
			choice = "play"
		end
	end)
	ContextActionService:BindActionAtPriority(
		"LegendaryCatchTitle",
		function()
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.PlayerActions.CharacterForward,
		Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft,
		Enum.PlayerActions.CharacterRight,
		Enum.PlayerActions.CharacterJump
	)
	gui.Parent = playerGui

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local restore = if camera
			and camera.CameraType == Enum.CameraType.Custom
			and root
			and root:IsA("BasePart")
		then panorama(camera, root.Position)
		else nil
	repeat
		RunService.Heartbeat:Wait()
	until choice or not gui.Parent
	if restore then
		restore()
	end
	ContextActionService:UnbindAction("LegendaryCatchTitle")
	keys:Disconnect()
	gui:Destroy()
	return choice == "skip"
end

return Title
