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
local UiAssets = require(Shared:WaitForChild("Ui"):WaitForChild("UiAssets"))
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local HudModule = script.Parent:WaitForChild("Hud")
local Hud = require(HudModule)
local Panel = require(HudModule:WaitForChild("Panel"))
local Art = require(HudModule:WaitForChild("Art"))
local HudAssets = require(HudModule:WaitForChild("Assets"))
local Arrival = { order = 0 }
local player = Players.LocalPlayer
local LOAD_TIMEOUT = 5
local COVER_IMAGE = "rbxassetid://127393649193984" -- art/arrival/fishing-lagoon.jpg
local MINIMUM_DISPLAY = 0.45
local FLYOVER_SECONDS = 2.3

local function interfaceAssets(gui: PlayerGui): { ImageLabel }
	local images: { ImageLabel } = {}
	local seen: { [string]: boolean } = {}
	local function add(id: string)
		if id ~= "" and not seen[id] then
			seen[id] = true
			local probe = Instance.new("ImageLabel")
			probe.Image = id
			table.insert(images, probe)
		end
	end
	local function catalog(value: unknown)
		if type(value) == "table" then
			for _, item in value :: { [any]: unknown } do
				catalog(item)
			end
		elseif type(value) == "string" and string.match(value, "^rbxasset") then
			add(value)
		end
	end

	add(COVER_IMAGE)
	catalog(HudAssets)
	-- The catalogs also include images used by screens that build on first open.
	catalog(UiAssets)
	for _, node in gui:GetDescendants() do
		if node:IsA("ImageLabel") or node:IsA("ImageButton") then
			add(node.Image)
		end
	end
	return images
end

local function preloadPreviews()
	local function loadBatch(batch: { Instance })
		repeat
			task.wait(0.15)
		until Hud.panel() == "" and not Hud.isMenuOpen() and not Hud.isFishingActive()
		pcall(ContentProvider.PreloadAsync, ContentProvider, batch)
		table.clear(batch)
	end
	for _, name in { "RodPreviews", "TrainingLevels", "AquariumLevels", Creatures.MODELS_FOLDER } do
		local root = ReplicatedStorage:FindFirstChild(name)
		if not root then
			continue
		end
		local batch: { Instance } = {}
		for _, node in root:GetDescendants() do
			if
				node:IsA("MeshPart")
				or node:IsA("SpecialMesh")
				or node:IsA("Decal")
				or node:IsA("Texture")
			then
				table.insert(batch, node)
				if #batch == 12 then
					loadBatch(batch)
				end
			end
		end
		if #batch > 0 then
			loadBatch(batch)
		end
	end
end

function Arrival.start()
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "IslandArrival"
	gui.DisplayOrder = 50
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local cover = Instance.new("Frame")
	cover.Name = "LoadingCover"
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Color3.new(1, 1, 1)
	cover.BorderSizePixel = 0
	cover.Active = true
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(23, 35, 74), Color3.fromRGB(8, 51, 62))
	gradient.Rotation = 90
	gradient.Parent = cover

	local backdrop = Instance.new("ImageLabel")
	backdrop.Name = "FishingLagoon"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundTransparency = 1
	backdrop.ScaleType = Enum.ScaleType.Crop
	backdrop.Image = COVER_IMAGE
	backdrop.Parent = cover

	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.fromRGB(8, 15, 37)
	shade.BorderSizePixel = 0
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.97),
		NumberSequenceKeypoint.new(0.32, 0.9),
		NumberSequenceKeypoint.new(0.58, 0.35),
		NumberSequenceKeypoint.new(0.77, 0.62),
		NumberSequenceKeypoint.new(1, 0.79),
	})
	fade.Parent = shade
	shade.Parent = cover

	local card = Instance.new("Frame")
	card.Name = "LoadingProgress"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.56)
	card.Size = UDim2.new(0.84, 0, 0, 122)
	card.BackgroundTransparency = 1
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(570, 122)
	bounds.Parent = card
	local title = Art.caption(card, "Title", Text.arrival.title, 66, Theme.gold)
	title.Position = UDim2.fromScale(0, 0)
	title.Size = UDim2.fromScale(1, 0.56)
	local status = Art.caption(card, "Status", Text.arrival.loadingUi, 18, Theme.sand)
	status.Position = UDim2.fromScale(0, 0.62)
	status.Size = UDim2.fromScale(1, 0.2)
	local meter = Instance.new("Frame")
	meter.Position = UDim2.fromScale(0.20, 0.89)
	meter.Size = UDim2.new(0.60, 0, 0, 7)
	meter.BackgroundColor3 = Color3.fromRGB(29, 59, 84)
	meter.BorderSizePixel = 0
	Theme.corner(meter, 4)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	Theme.corner(fill, 4)
	local sheen = Instance.new("UIGradient")
	sheen.Color = ColorSequence.new(Color3.fromRGB(75, 221, 245), Theme.gold)
	sheen.Parent = fill
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
	local completed = 0
	local total = 0
	local ready = false
	task.spawn(function()
		-- Give start() handlers one frame to mount the initial UI.
		RunService.Heartbeat:Wait()
		local images = interfaceAssets(playerGui)
		total = #images
		pcall(function()
			ContentProvider:PreloadAsync(images, function()
				completed += 1
			end)
		end)
		for _, image in images do
			image:Destroy()
		end
		ready = true
		preloadPreviews()
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
		status.Text = if ready then Text.arrival.loading else Text.arrival.loadingUi
		fill.Size = UDim2.fromScale(
			if ready then 1 else math.clamp(completed / math.max(total, 1), 0, 1),
			1
		)
		RunService.Heartbeat:Wait()
	end
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
