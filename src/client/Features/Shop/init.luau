--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Strings = require(Shared:WaitForChild("Strings"))
local Net = require(Shared:WaitForChild("Net"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))

local Robux = require(script:WaitForChild("Robux"))
local Shop = {}
local PREVIEWS = "RodPreviews"

local function showMesh(view: ViewportFrame, id: string): boolean
	local library = ReplicatedStorage:FindFirstChild(PREVIEWS)
	local source = library and library:FindFirstChild(id)
	if not source or not (source:IsA("Model") or source:IsA("BasePart")) then
		return false
	end

	local model: Model
	if source:IsA("Model") then
		model = source:Clone()
	else
		model = Instance.new("Model")
		source:Clone().Parent = model
	end
	model.Name = "RodMesh"
	if not model:FindFirstChildWhichIsA("BasePart", true) then
		model:Destroy()
		return false
	end
	for _, instance in model:GetDescendants() do
		if
			instance:IsA("BaseScript")
			or instance:IsA("ModuleScript")
			or instance:IsA("ParticleEmitter")
			or instance:IsA("Trail")
			or (instance:IsA("BasePart") and instance.Name == "Tip")
		then
			instance:Destroy()
		elseif instance:IsA("BasePart") then
			instance.Anchored = true
			instance.CanCollide = false
		end
	end
	local _, size = model:GetBoundingBox()
	model:ScaleTo(model:GetScale() * 4.3 / math.max(size.X, size.Y, size.Z, 0.1))
	local bounds = select(1, model:GetBoundingBox())
	local centered = CFrame.new(-bounds.Position) * model:GetPivot()
	model:PivotTo(
		CFrame.Angles(0.1, 0, math.rad(-38)) * CFrame.Angles(0, math.rad(81), 0) * centered
	)
	model.Parent = view
	return true
end

local function preview(parent: Instance, rod: Rods.Rod)
	local view = Instance.new("ViewportFrame")
	view.Name = "RodPreview"
	view.BackgroundColor3 = Theme.viewport
	view.Ambient = Color3.fromRGB(165, 174, 197)
	view.LightColor = Color3.fromRGB(255, 239, 217)
	view.Size = UDim2.fromScale(0.28, 0.86)
	view.Position = UDim2.fromScale(0.025, 0.07)
	Theme.corner(view, 10)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 31
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, 11), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera

	if showMesh(view, rod.id) then
		view.Parent = parent
		return
	end
	local pose = CFrame.Angles(0.2, 0, -0.6)
	local function part(name: string, size: Vector3, position: Vector3, tint: Color3)
		local piece = Instance.new("Part")
		piece.Name = name
		piece.Size = size
		piece.Color = tint
		piece.CFrame = pose * CFrame.new(position)
		piece.Anchored = true
		piece.Parent = view
	end
	part("Handle", Vector3.new(0.35, 1.1, 0.35), Vector3.new(0, -1.55, 0), Theme.wood)
	part("Blank", Vector3.new(0.19, 3.4, 0.19), Vector3.new(0, 0.61, 0), rod.color)
	part("Reel", Vector3.new(0.48, 0.55, 0.46), Vector3.new(0.31, -0.91, 0), Theme.gold)
	part("Tip", Vector3.new(0.24, 0.24, 0.24), Vector3.new(0, 2.3, 0), rod.tipColor)
	for n = 1, 3 do
		part("Guide", Vector3.new(0.28, 0.08, 0.27), Vector3.new(0, n * 0.68, 0), Theme.gold)
	end
	view.Parent = parent
end

function Shop.start()
	Robux.start()
	local shopAccent = Color3.fromRGB(255, 151, 64)
	local gui, scroll = Panel.create("Shop", Text.shop, shopAccent)
	local body = Instance.new("Frame")
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Size = UDim2.fromScale(1, 0)
	body.BackgroundTransparency = 1
	body.Parent = scroll
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local pending = ""
	local function render()
		body:ClearAllChildren()
		Panel.stack(body)
		local robuxButton = Panel.button(body, Text.robux.title, Theme.gold)
		robuxButton.Name = "RobuxTab"
		robuxButton.LayoutOrder = -1
		robuxButton.Activated:Connect(function()
			Hud.showPanel("Robux")
		end)
		local snapshot = Data.get()
		if not snapshot then
			Panel.label(body, Text.loading, 18)
			return
		end
		for _, rod in Rods.LIST do
			local row = Panel.card(body, rod.tipColor, 124)
			row.Name = rod.id
			row.LayoutOrder = rod.order
			preview(row, rod)
			local title = Panel.label(row, Strings.rodName[rod.id] or rod.id, 19, rod.tipColor)
			title.Position = UDim2.fromScale(0.33, 0.035)
			title.Size = UDim2.fromScale(0.64, 0.23)
			local bonus = Panel.label(
				row,
				string.format(
					"%s +%.0f%%  ·  %s +%.0f%%",
					Text.control,
					rod.controlBonus * 100,
					Text.luck,
					rod.luckBonus * 100
				),
				14
			)
			bonus.Position = UDim2.fromScale(0.33, 0.29)
			bonus.Size = UDim2.fromScale(0.64, 0.2)

			local owned = table.find(snapshot.rodsOwned, rod.id) ~= nil
			local equipped = snapshot.equippedRod == rod.id
			local stars = Panel.label(row, "", 12, Theme.gold)
			stars.Name = "RodAccent"
			stars.Text = string.rep("★", math.clamp(1 + rod.order, 1, 5))
			stars.Position = UDim2.fromScale(0.33, 0.46)
			stars.Size = UDim2.fromScale(0.38, 0.16)
			local button = Panel.button(
				row,
				if equipped
					then Text.equipped
					elseif owned then Text.equip
					else string.format("%s  ·  %d ◆", Text.buy, rod.price),
				if equipped or owned then Theme.crystal else Color3.fromRGB(68, 194, 104)
			)
			button.Name = "RodAction"
			button.Position = UDim2.fromScale(0.36, 0.61)
			button.Size = UDim2.new(0.57, 0, 0, 42)
			button.Activated:Connect(function()
				if equipped or pending ~= "" then
					return
				end
				local remote = remotes:FindFirstChild(if owned then Net.EQUIP_ROD else Net.BUY_ROD)
				if not remote or not remote:IsA("RemoteEvent") then
					Hud.toast(Text.unavailable)
					return
				end
				pending = rod.id
				remote:FireServer(rod.id)
				task.delay(5, function()
					if pending == rod.id then
						pending = ""
					end
				end)
			end)
		end
	end

	Hud.panelChanged:Connect(function(name: string)
		gui.Enabled = name == "Shop"
		if gui.Enabled then
			render()
		else
			body:ClearAllChildren()
		end
	end)
	Data.changed:Connect(function()
		if gui.Enabled then
			render()
		end
	end)
	local function watchPreviews(library: Instance)
		if library.Name ~= PREVIEWS then
			return
		end
		local function refreshPreviews()
			if gui.Enabled then
				render()
			end
		end
		library.ChildAdded:Connect(refreshPreviews)
		library.ChildRemoved:Connect(refreshPreviews)
		refreshPreviews()
	end
	local library = ReplicatedStorage:FindFirstChild(PREVIEWS)
	if library then
		watchPreviews(library)
	end
	ReplicatedStorage.ChildAdded:Connect(watchPreviews)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if player == Players.LocalPlayer and prompt.Name == "OpenWorkshop" then
			Hud.showPanel("Shop")
		end
	end)
	local result = remotes:WaitForChild(Net.SHOP_RESULT) :: RemoteEvent
	result.OnClientEvent:Connect(function(payload: Net.ShopResult)
		pending = ""
		Hud.toast(
			if payload.ok
				then (Strings.rodName[payload.rodId] or payload.rodId)
				else Text.shopErrors[payload.reason or "unknown"] or Text.unavailable,
			if payload.ok then Theme.crystal else Theme.rose
		)
	end)
end

return Shop
