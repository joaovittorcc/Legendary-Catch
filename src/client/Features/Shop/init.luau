--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Strings = require(Shared:WaitForChild("Strings"))
local Net = require(Shared:WaitForChild("Net"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local Fishing = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))

local Robux = require(script:WaitForChild("Robux"))
local Shop = {}
local PREVIEWS = "RodPreviews"

local function formatPrice(price: number): string
	local digits = tostring(price)
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1" .. Text.thousandsSeparator):reverse()
	return if #digits % 3 == 0 then grouped:sub(2) else grouped
end

local function fitLabel(label: TextLabel, maxSize: number)
	label.TextScaled = true
	label.TextWrapped = false
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.Parent = label
end

local function cloneRod(id: string): Model?
	local library = ReplicatedStorage:FindFirstChild(PREVIEWS)
	local source = library and library:FindFirstChild(id)
	if not source or not (source:IsA("Model") or source:IsA("BasePart")) then
		return nil
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
		return nil
	end
	local handle = model:FindFirstChild("Handle", true)
	local tip = model:FindFirstChild("Tip", true)
	local axis = Vector3.zAxis
	if handle and handle:IsA("BasePart") and tip and tip:IsA("BasePart") then
		local direction = tip.Position - handle.Position
		if direction.Magnitude > 0.01 then
			axis = direction.Unit
		end
	end
	for _, instance in model:GetDescendants() do
		if
			instance:IsA("BaseScript")
			or instance:IsA("ModuleScript")
			or instance:IsA("ParticleEmitter")
			or instance:IsA("Trail")
			or instance:IsA("Beam")
			or (instance:IsA("BasePart") and instance.Transparency >= 1)
		then
			instance:Destroy()
		elseif instance:IsA("BasePart") then
			instance.Anchored = true
			instance.CanCollide = false
		end
	end
	if not model:FindFirstChildWhichIsA("BasePart", true) then
		model:Destroy()
		return nil
	end
	local up = if math.abs(axis.Y) > 0.95 then Vector3.zAxis else Vector3.yAxis
	local align = CFrame.Angles(math.pi / 2, 0, 0)
		* CFrame.lookAlong(Vector3.zero, axis, up):Inverse()
	model:PivotTo(align * model:GetPivot())
	local _, size = model:GetBoundingBox()
	model:ScaleTo(model:GetScale() * 5.2 / math.max(size.X, size.Y, size.Z, 0.1))
	local bounds = select(1, model:GetBoundingBox())
	model:PivotTo(CFrame.new(-bounds.Position) * model:GetPivot())
	return model
end

local DIAG_TILT = -0.68

local function rarityStars(rarity: string): string
	local rank = Theme.rarityRank(rarity)
	if rank >= 6 then
		return "🌟"
	end
	return string.rep("★", math.clamp(rank, 1, 5))
end

local function preview(
	parent: Instance,
	rod: Rods.Rod,
	accent: Color3
): (Model, CFrame, ViewportFrame)
	local showcase = Instance.new("Frame")
	showcase.Name = "RodShowcase"
	showcase.Size = UDim2.fromScale(0.36, 0.88)
	showcase.Position = UDim2.fromScale(0.022, 0.06)
	showcase.BackgroundColor3 = Color3.new(1, 1, 1)
	showcase.BorderSizePixel = 0
	showcase.ClipsDescendants = true
	Theme.corner(showcase, 14)
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, accent:Lerp(Color3.fromRGB(30, 54, 102), 0.68)),
		ColorSequenceKeypoint.new(0.55, accent:Lerp(Color3.fromRGB(70, 128, 194), 0.56)),
		ColorSequenceKeypoint.new(1, accent:Lerp(Color3.fromRGB(22, 34, 68), 0.78)),
	})
	bgGrad.Rotation = 135
	bgGrad.Parent = showcase
	local showcaseStroke = Instance.new("UIStroke")
	showcaseStroke.Color = Theme.outline
	showcaseStroke.Thickness = 2.5
	showcaseStroke.Parent = showcase
	local gloss = Instance.new("Frame")
	gloss.Name = "TopSheen"
	gloss.Position = UDim2.fromScale(0.08, 0.05)
	gloss.Size = UDim2.fromScale(0.84, 0.22)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.84
	gloss.BorderSizePixel = 0
	gloss.ZIndex = 1
	Theme.corner(gloss, 10)
	gloss.Parent = showcase
	local pedestal = Instance.new("Frame")
	pedestal.Name = "GlowFloor"
	pedestal.AnchorPoint = Vector2.new(0.5, 1)
	pedestal.Position = UDim2.fromScale(0.5, 0.96)
	pedestal.Size = UDim2.fromScale(0.76, 0.14)
	pedestal.BackgroundColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.35)
	pedestal.BackgroundTransparency = 0.72
	pedestal.BorderSizePixel = 0
	pedestal.ZIndex = 1
	Theme.corner(pedestal, 99)
	pedestal.Parent = showcase

	local view = Instance.new("ViewportFrame")
	view.Name = "RodPreview"
	view.BackgroundTransparency = 1
	view.Ambient = Color3.fromRGB(190, 200, 224)
	view.LightColor = Color3.fromRGB(255, 244, 224)
	view.LightDirection = Vector3.new(-0.6, -0.7, -1)
	view.Size = UDim2.fromScale(1, 1)
	view.ZIndex = 2

	local imported = cloneRod(rod.id)
	local model = imported or Instance.new("Model")
	local function part(name: string, size: Vector3, position: Vector3, tint: Color3)
		local piece = Instance.new("Part")
		piece.Name = name
		piece.Size = size
		piece.Color = tint
		piece.CFrame = CFrame.new(position)
		piece.Anchored = true
		piece.Parent = model
	end
	if not imported then
		part("Handle", Vector3.new(0.42, 1.3, 0.42), Vector3.new(0, -1.85, 0), Theme.wood)
		part("Blank", Vector3.new(0.24, 4.0, 0.24), Vector3.new(0, 0.72, 0), rod.color)
		part("Reel", Vector3.new(0.56, 0.64, 0.54), Vector3.new(0.36, -1.05, 0), Theme.gold)
		part("Tip", Vector3.new(0.32, 0.32, 0.32), Vector3.new(0, 2.75, 0), rod.tipColor)
		for n = 1, 3 do
			part("Guide", Vector3.new(0.34, 0.1, 0.32), Vector3.new(0, n * 0.82, 0), Theme.gold)
		end
	end
	local pose = model:GetPivot()
	model:PivotTo(CFrame.Angles(0, 0.35, DIAG_TILT) * pose)
	local rotCf, rotSize = model:GetBoundingBox()
	-- Recenter after diagonal tilt so the whole rod fills ~75% of the showcase cleanly.
	pose = CFrame.new(-rotCf.Position) * pose
	model:PivotTo(CFrame.Angles(0, 0.35, DIAG_TILT) * pose)

	local fov = 30
	local halfTan = math.tan(math.rad(fov * 0.5))
	local aspect = 1.45
	local distY = (rotSize.Y * 0.5) / (halfTan * 0.72)
	local distX = (rotSize.X * 0.5) / (halfTan * aspect * 0.72)
	local dist = math.max(distY, distX, 4.2) + rotSize.Z * 0.5

	local camera = Instance.new("Camera")
	camera.FieldOfView = fov
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.08, dist), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera

	model.Parent = view
	view.Parent = showcase
	showcase.Parent = parent
	return model, pose, view
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
	local previews: { { model: Model, pose: CFrame, view: ViewportFrame } } = {}
	local rotation = 0
	local function render()
		table.clear(previews)
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
			local rarity = Fishing.RARITY_ORDER[math.min(rod.order, #Fishing.RARITY_ORDER)]
			local accent = Theme.rarity[rarity] or rod.tipColor
			local row = Panel.card(body, accent, 168)
			row.Name = rod.id
			row.LayoutOrder = rod.order
			local model, pose, view = preview(row, rod, accent)
			table.insert(previews, { model = model, pose = pose, view = view })
			model:PivotTo(CFrame.Angles(0, 0.35, DIAG_TILT) * pose)
			local title = Panel.label(row, Strings.rodName[rod.id] or rod.id, 22, Theme.ink)
			title.Position = UDim2.fromScale(0.405, 0.04)
			title.Size = UDim2.fromScale(0.565, 0.22)
			title.TextStrokeTransparency = 1
			fitLabel(title, 22)
			local bonus = Panel.label(
				row,
				string.format(
					"%s +%.0f%%  ·  %s +%.0f%%",
					Text.control,
					rod.controlBonus * 100,
					Text.luck,
					rod.luckBonus * 100
				),
				15,
				Theme.wood
			)
			bonus.Position = UDim2.fromScale(0.405, 0.25)
			bonus.Size = UDim2.new(0.565, 0, 0, 28)
			bonus.TextStrokeTransparency = 1
			fitLabel(bonus, 15)

			local owned = table.find(snapshot.rodsOwned, rod.id) ~= nil
			local equipped = snapshot.equippedRod == rod.id
			local affordable = snapshot.coins >= rod.price
			local rarityText =
				string.format("%s  %s", rarityStars(rarity), Strings.rarity[rarity] or rarity)
			local seal = Panel.label(row, rarityText, 15, accent:Lerp(Color3.new(1, 1, 1), 0.28))
			seal.Name = "RodRarity"
			seal.BackgroundTransparency = 0
			seal.Position = UDim2.fromScale(0.405, 0.45)
			seal.Size = UDim2.fromScale(0.555, 0.17)
			seal.TextStrokeTransparency = 1
			fitLabel(seal, 15)
			Theme.surface(seal, accent, 10, Theme.ink)
			local blocked = equipped or (not owned and not affordable)
			local price = formatPrice(rod.price)
			local button = Panel.button(
				row,
				if equipped
					then Text.equipped
					elseif owned then Text.equip
					elseif affordable then string.format("%s  ·  %s ◆", Text.buy, price)
					else string.format(Text.rodUnaffordable, price),
				if blocked
					then Theme.muted
					elseif owned then Theme.crystal
					else Color3.fromRGB(68, 194, 104)
			)
			button.Name = "RodAction"
			button.TextSize = 16
			button.AnchorPoint = Vector2.new(0.5, 0)
			button.Position = UDim2.fromScale(0.68, 0.67)
			button.Size = UDim2.new(0.555, 0, 0, 44)
			button.Interactable = not blocked
			if blocked then
				Panel.tintButton(
					button,
					if equipped then Color3.fromRGB(55, 133, 115) else Color3.fromRGB(103, 88, 117)
				)
			end
			button.Activated:Connect(function()
				if blocked or pending ~= "" then
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
			table.clear(previews)
			body:ClearAllChildren()
		end
	end)
	local wasReduced = false
	RunService.RenderStepped:Connect(function(dt: number)
		if not gui.Enabled then
			wasReduced = false
			return
		end
		local reduced = Players.LocalPlayer:GetAttribute("ReduceEffects") == true
		if reduced and wasReduced then
			return
		end
		wasReduced = reduced
		if not reduced then
			rotation = (rotation + dt * 0.65) % (2 * math.pi)
		end
		local top = scroll.AbsolutePosition.Y
		local bottom = top + scroll.AbsoluteWindowSize.Y
		local pose = CFrame.Angles(0, if reduced then 0.35 else rotation, DIAG_TILT)
		for _, entry in previews do
			local y = entry.view.AbsolutePosition.Y
			if y < bottom and y + entry.view.AbsoluteSize.Y > top then
				entry.model:PivotTo(pose * entry.pose)
			end
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
