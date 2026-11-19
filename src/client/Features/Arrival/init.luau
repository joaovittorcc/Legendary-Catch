--!strict
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Hud = script.Parent:WaitForChild("Hud")
local Panel = require(Hud:WaitForChild("Panel"))
local Arrival = { order = 0 }
local player = Players.LocalPlayer
local LOAD_TIMEOUT = 2.6
local MINIMUM_DISPLAY = 0.45
local FLYOVER_SECONDS = 2.3

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
	skip.Position = UDim2.fromScale(0.5, 0.86)
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
	cover.Visible = false
	cover.Active = false

	-- Only first-time players (tutorial not done) get the short island flyover (~2.3s),
	-- skippable on any tap/click or the Skip button, ending smoothly behind the character.
	local snapshot = Data.get()
	local firstTime = not snapshot or not snapshot.tutorial or not snapshot.tutorial.done
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local landingView: CFrame? = nil
	if root and root:IsA("BasePart") then
		-- Frame the player from behind looking across the plaza toward the Workshop (-Z)
		-- so the initial camera never starts buried inside the entrance stairs or welcome arch.
		local back = -root.CFrame.LookVector
		local horizBack = Vector3.new(back.X, 0, back.Z)
		local dir = if horizBack.Magnitude > 0.01 then horizBack.Unit else Vector3.new(0, 0, 1)
		landingView = CFrame.lookAt(
			root.Position + dir * 13.5 + Vector3.new(0, 5.2, 0),
			root.Position - dir * 14 + Vector3.new(0, 2.2, 0)
		)
	end
	local animate = firstTime
		and camera
		and camera.CameraType == Enum.CameraType.Custom
		and root
		and root:IsA("BasePart")
		and player:GetAttribute("ReduceEffects") ~= true
	if animate and camera and root and root:IsA("BasePart") then
		local view = landingView or camera.CFrame
		local focus = root.Position + Vector3.new(0, 2, 0)
		local high = focus + Vector3.new(-28, 22, 34)
		local sweep = focus + Vector3.new(30, 14, 18)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(high, focus)
		skip.Visible = true
		local tapConn = UserInputService.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				skipped = true
			end
		end)
		local begin = os.clock()
		while
			not skipped
			and workspace.CurrentCamera == camera
			and camera.CameraType == Enum.CameraType.Scriptable
			and root:IsDescendantOf(workspace)
		do
			local fraction = math.clamp((os.clock() - begin) / FLYOVER_SECONDS, 0, 1)
			local eased =
				TweenService:GetValue(fraction, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			if eased < 0.5 then
				local sub = eased * 2
				local pos = high:Lerp(sweep, sub)
				camera.CFrame = CFrame.lookAt(pos, focus)
			else
				local sub = (eased - 0.5) * 2
				local mid = CFrame.lookAt(sweep, focus)
				camera.CFrame = mid:Lerp(view, sub)
			end
			if fraction >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		tapConn:Disconnect()
		if camera.CameraType == Enum.CameraType.Scriptable then
			camera.CFrame = view
			camera.CameraType = Enum.CameraType.Custom
		end
	elseif camera and landingView and camera.CameraType == Enum.CameraType.Custom then
		camera.CFrame = landingView
	end
	gui:Destroy()
end

return Arrival
