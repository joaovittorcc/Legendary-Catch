--!strict
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local Hud = script.Parent:WaitForChild("Hud")
local Panel = require(Hud:WaitForChild("Panel"))
local Title = require(script:WaitForChild("Title"))
local Arrival = { order = 0 }
local player = Players.LocalPlayer
local LOAD_TIMEOUT = 6
local MINIMUM_DISPLAY = 0.55

local function assetsFor(gui: PlayerGui): { Instance }
	local assets: { Instance } = {}
	local models = ReplicatedStorage:FindFirstChild(Creatures.MODELS_FOLDER)
	if models then
		for _, node in models:GetDescendants() do
			if
				node:IsA("MeshPart")
				or node:IsA("SpecialMesh")
				or node:IsA("SurfaceAppearance")
				or node:IsA("Decal")
				or node:IsA("Texture")
			then
				table.insert(assets, node)
			end
		end
	end
	for _, node in gui:GetDescendants() do
		if (node:IsA("ImageLabel") or node:IsA("ImageButton")) and node.Image ~= "" then
			table.insert(assets, node)
		end
	end
	return assets
end

function Arrival.start()
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "IslandArrival"
	gui.DisplayOrder = 50
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local cover = Instance.new("CanvasGroup")
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Color3.new(1, 1, 1)
	cover.BorderSizePixel = 0
	cover.Active = true
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(16, 45, 65), Color3.fromRGB(66, 36, 75))
	gradient.Rotation = 32
	gradient.Parent = cover
	local card = Instance.new("Frame")
	card.Name = "Welcome"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.48)
	card.Size = UDim2.new(0.84, 0, 0, 178)
	Theme.surface(card, Theme.crystal, 16)
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(480, 178)
	bounds.Parent = card
	local title = Panel.label(card, Text.arrival.title, 28, Theme.crystal)
	title.Position = UDim2.fromScale(0, 0.12)
	title.Size = UDim2.fromScale(1, 0.28)
	local status = Panel.label(card, Text.arrival.loading, 16, Theme.sand)
	status.Position = UDim2.fromScale(0, 0.43)
	status.Size = UDim2.fromScale(1, 0.24)
	local meter = Instance.new("Frame")
	meter.Position = UDim2.fromScale(0.1, 0.78)
	meter.Size = UDim2.fromScale(0.8, 0.065)
	meter.BackgroundColor3 = Theme.ink
	meter.BorderSizePixel = 0
	meter.ClipsDescendants = true
	Theme.corner(meter, 4)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Theme.crystal
	fill.BorderSizePixel = 0
	Theme.corner(fill, 4)
	fill.Parent = meter
	meter.Parent = card
	card.Parent = cover
	cover.Parent = gui

	local skip = Panel.button(gui, Text.skip, Theme.gold)
	skip.Name = "SkipArrival"
	skip.AnchorPoint = Vector2.new(0.5, 1)
	skip.Position = UDim2.fromScale(0.5, 0.83)
	skip.Size = UDim2.fromOffset(108, 46)
	skip.Visible = false
	local skipped = false
	skip.Activated:Connect(function()
		skipped = true
	end)
	gui.Parent = playerGui

	local opened = os.clock()
	local progress = 0
	local ready = false
	task.spawn(function()
		-- Let the other client features mount their initial UI before collecting images.
		RunService.Heartbeat:Wait()
		local assets = assetsFor(playerGui)
		for first = 1, #assets, 12 do
			if not gui.Parent or os.clock() - opened > LOAD_TIMEOUT then
				break
			end
			local batch = {}
			for index = first, math.min(first + 11, #assets) do
				table.insert(batch, assets[index])
			end
			pcall(function()
				ContentProvider:PreloadAsync(batch)
			end)
			progress = math.min(first + #batch - 1, #assets) / #assets
		end
		ready = true
	end)

	while os.clock() - opened < LOAD_TIMEOUT do
		if
			ready
			and player.Character
			and player:GetAttribute("DataLoaded") == true
			and os.clock() - opened >= MINIMUM_DISPLAY
		then
			break
		end
		fill.Size = UDim2.fromScale(
			math.max(progress * 0.9, math.min((os.clock() - opened) / LOAD_TIMEOUT, 0.85)),
			1
		)
		RunService.Heartbeat:Wait()
	end
	fill.Size = UDim2.fromScale(1, 1)
	status.Text = Text.arrival.ready

	local skipPanorama = Title.open(playerGui)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local animate = not skipPanorama
		and camera
		and camera.CameraType == Enum.CameraType.Custom
		and root
		and root:IsA("BasePart")
		and player:GetAttribute("ReduceEffects") ~= true
	local finish = TweenService:Create(cover, TweenInfo.new(0.34), { GroupTransparency = 1 })
	finish:Play()
	if animate and camera and root and root:IsA("BasePart") then
		local view = camera.CFrame
		local focus = root.Position + Vector3.new(0, 2, 0)
		local backward = -root.CFrame.LookVector
		local start = CFrame.lookAt(
			focus + backward * 20 + root.CFrame.RightVector * 8 + Vector3.new(0, 9, 0),
			focus
		)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = start
		skip.Visible = true
		local begin = os.clock()
		while
			not skipped
			and workspace.CurrentCamera == camera
			and camera.CameraType == Enum.CameraType.Scriptable
			and root:IsDescendantOf(workspace)
		do
			local fraction = math.clamp((os.clock() - begin) / 1.65, 0, 1)
			camera.CFrame = start:Lerp(
				view,
				TweenService:GetValue(fraction, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			)
			if fraction >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		if camera.CameraType == Enum.CameraType.Scriptable then
			camera.CFrame = view
			camera.CameraType = Enum.CameraType.Custom
		end
	else
		finish.Completed:Wait()
	end
	gui:Destroy()
end

return Arrival
