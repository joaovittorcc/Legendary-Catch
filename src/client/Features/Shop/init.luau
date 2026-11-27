--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

local function formatPrice(price: number): string
	local digits = tostring(price)
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1" .. Text.thousandsSeparator):reverse()
	return if #digits % 3 == 0 then grouped:sub(2) else grouped
end

local function fitLabel(label: TextLabel, maxSize: number, minSize: number?)
	label.TextScaled = true
	label.TextWrapped = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.MinTextSize = minSize or 11
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
	local handle = model:FindFirstChild("GripReelMesh", true)
		or model:FindFirstChild("Handle", true)
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

local DIAG_TILT = 1.18

local function worldExtents(cf: CFrame, size: Vector3): (Vector3, Vector3)
	local half = size * 0.5
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local pt = (cf * CFrame.new(sx * half.X, sy * half.Y, sz * half.Z)).Position
				minV = Vector3.new(
					math.min(minV.X, pt.X),
					math.min(minV.Y, pt.Y),
					math.min(minV.Z, pt.Z)
				)
				maxV = Vector3.new(
					math.max(maxV.X, pt.X),
					math.max(maxV.Y, pt.Y),
					math.max(maxV.Z, pt.Z)
				)
			end
		end
	end
	return (minV + maxV) * 0.5, maxV - minV
end

type ShowcaseSlot = {
	holder: Frame,
	rod: Rods.Rod,
	view: ViewportFrame?,
	model: Model?,
	pose: CFrame?,
}

local function mountRodViewport(slot: ShowcaseSlot, framing: number?)
	if slot.view and slot.view.Parent then
		return
	end
	local rod = slot.rod
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
	local angle = CFrame.Angles(0, 0.35, DIAG_TILT)
	model:PivotTo(angle * pose)
	local rotCf, rotSize = model:GetBoundingBox()
	local worldCenter, worldSpan = worldExtents(rotCf, rotSize)
	-- Recenter by true world AABB and frame using rotated world-space extents so even the
	-- longest rods (Celestial, Abyss, Mystic) stay 100% inside the showcase on PC and mobile.
	pose = CFrame.new(-angle:VectorToObjectSpace(worldCenter)) * pose
	model:PivotTo(angle * pose)

	local fov = 30
	local halfTan = math.tan(math.rad(fov * 0.5))
	local distY = (worldSpan.Y * 0.5) / (halfTan * 0.78)

	local camera = Instance.new("Camera")
	camera.FieldOfView = fov
	local function fitCamera()
		local size = view.AbsoluteSize
		local aspect = if size.X > 10 and size.Y > 10
			then math.clamp(size.X / size.Y, 0.75, 3.4)
			else 1.05
		local distX = (worldSpan.X * 0.5) / (halfTan * aspect * 0.79)
		local dist = math.max(distY, distX, 3.1) + worldSpan.Z * 0.48
		camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, dist * (framing or 1)), Vector3.zero)
	end
	camera.Parent = view
	view.CurrentCamera = camera

	model.Parent = view
	view.Parent = slot.holder
	view:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitCamera)
	fitCamera()
	slot.view = view
	slot.model = model
	slot.pose = pose
end

local NAVY = Color3.fromRGB(9, 41, 86)
local CRYSTAL = Color3.fromRGB(45, 199, 237)
local GOLD = Color3.fromRGB(255, 199, 55)
local IVORY = Color3.fromRGB(255, 235, 202)

local function surface(
	target: GuiObject,
	top: Color3,
	bottom: Color3,
	edge: Color3,
	radius: number
): UIStroke
	target.BackgroundColor3 = Color3.new(1, 1, 1)
	target.BackgroundTransparency = 0
	target.BorderSizePixel = 0
	Theme.corner(target, radius)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	stroke.Color = edge
	stroke.Thickness = 2
	stroke.Parent = target
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(top, bottom)
	gradient.Rotation = 90
	gradient.Parent = target
	return stroke
end

local function frame(parent: Instance, name: string): Frame
	local view = Instance.new("Frame")
	view.Name = name
	view.BackgroundTransparency = 1
	view.BorderSizePixel = 0
	view.Parent = parent
	return view
end

local function showcase(parent: Instance): Frame
	local view = frame(parent, "RodShowcase")
	view.ClipsDescendants = true
	surface(view, Color3.fromRGB(30, 100, 173), NAVY, CRYSTAL, 17)
	local shelf = frame(view, "DisplayPlinth")
	shelf.AnchorPoint = Vector2.new(0.5, 1)
	shelf.Position = UDim2.fromScale(0.5, 0.94)
	shelf.Size = UDim2.new(0.77, 0, 0, 12)
	surface(shelf, Color3.fromRGB(217, 142, 76), Theme.wood, Color3.fromRGB(88, 45, 41), 5)
	return view
end

local function caption(parent: Instance, name: string, size: number): TextLabel
	local label = Panel.label(parent, "", size, Theme.ink)
	label.Name = name
	label.TextStrokeTransparency = 1
	fitLabel(label, size, 12)
	return label
end

local function reload(slot: ShowcaseSlot, rod: Rods.Rod)
	if slot.view then
		slot.view:Destroy()
	end
	slot.view, slot.model, slot.pose = nil, nil, nil
	slot.rod = rod
end

function Shop.start()
	Robux.start()
	local shopAccent = Panel.themeColor("Shop")
	local gui, scroll, heading = Panel.create("Shop", Text.workshopTitle, shopAccent, 1, 650, true)
	local ribbon = heading.Parent
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local body = frame(scroll, "Workshop")
	body.Size = UDim2.fromScale(1, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	Panel.stack(body)

	local top = frame(body, "WorkshopBalanceBar")
	top.Size = UDim2.new(1, 0, 0, 44)
	top.LayoutOrder = 1
	local wallet = caption(top, "WorkshopBalance", 20)
	wallet.Size = UDim2.fromOffset(146, 39)
	wallet.TextXAlignment = Enum.TextXAlignment.Center
	surface(wallet, IVORY, IVORY, Color3.fromRGB(226, 180, 112), 14)
	local robux = Panel.button(top, Text.robux.title, Color3.fromRGB(65, 151, 188))
	robux.Name = "RobuxTab"
	robux.AnchorPoint = Vector2.new(1, 0)
	robux.Position = UDim2.fromScale(1, 0)
	robux.Size = UDim2.fromOffset(146, 44)
	robux.TextScaled = true
	local robuxCaption = robux:FindFirstChild("ButtonCaption")
	if robuxCaption and robuxCaption:IsA("TextLabel") then
		fitLabel(robuxCaption, 16, 11)
	end
	robux.Activated:Connect(function()
		Hud.showPanel("Robux")
	end)

	local main = frame(body, "RodDetails")
	main.LayoutOrder = 2
	local preview = showcase(main)
	local details = frame(main, "StatsAndPurchase")
	local title = caption(details, "RodName", 32)
	local control = caption(details, "RodControl", 18)
	local luck = caption(details, "RodLuck", 18)
	local action = Panel.button(details, "", GOLD)
	action.Name = "RodAction"
	action.TextColor3 = NAVY
	action.TextStrokeTransparency = 1
	action.TextSize = 19
	action.TextScaled = true
	local actionCaption = action:FindFirstChild("ButtonCaption")
	if actionCaption and actionCaption:IsA("TextLabel") then
		fitLabel(actionCaption, 23, 12)
	end
	for _, label in { title, control, luck } do
		surface(label, IVORY, IVORY, Color3.fromRGB(225, 188, 140), 12)
	end

	local catalog = Instance.new("ScrollingFrame")
	catalog.Name = "RodCatalog"
	catalog.LayoutOrder = 3
	catalog.Size = UDim2.new(1, 0, 0, 77)
	catalog.BackgroundTransparency = 1
	catalog.BorderSizePixel = 0
	catalog.ScrollBarThickness = 4
	catalog.ScrollBarImageColor3 = NAVY
	catalog.ScrollingDirection = Enum.ScrollingDirection.X
	catalog.AutomaticCanvasSize = Enum.AutomaticSize.X
	catalog.CanvasSize = UDim2.new()
	catalog.Parent = body
	local rail = Instance.new("UIListLayout")
	rail.Padding = UDim.new(0, 6)
	rail.FillDirection = Enum.FillDirection.Horizontal
	rail.SortOrder = Enum.SortOrder.LayoutOrder
	rail.Parent = catalog

	local selected = 1
	local hero: ShowcaseSlot = { holder = preview, rod = Rods.LIST[selected] }
	local slots: { ShowcaseSlot } = {}
	local outlines: { UIStroke } = {}
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local pending: number? = nil
	local requestId = 0
	local previewsDirty = true
	local rotation = 0
	local refreshDetails: () -> ()

	local function selectRod(index: number)
		if selected == index then
			return
		end
		selected = index
		reload(hero, Rods.LIST[index])
		previewsDirty = true
		refreshDetails()
	end

	-- Roblox only drag-scrolls a ScrollingFrame by touch, so the mouse gets its own
	-- click-and-drag and wheel here. A real drag must not also select the tile under it.
	local catalogDragged = false
	local dragStartX: number? = nil
	local dragStartCanvas = 0
	local function isOverCatalog(position: Vector3): boolean
		local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if not gui.Enabled or not playerGui then
			return false
		end
		for _, object in playerGui:GetGuiObjectsAtPosition(position.X, position.Y) do
			if object == catalog or object:IsDescendantOf(catalog) then
				return true
			end
		end
		return false
	end
	local function scrollCatalogTo(x: number)
		local limit = math.max(0, catalog.AbsoluteCanvasSize.X - catalog.AbsoluteWindowSize.X)
		catalog.CanvasPosition = Vector2.new(math.clamp(x, 0, limit), 0)
	end
	UserInputService.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
			return
		end
		catalogDragged = false
		if kind == Enum.UserInputType.MouseButton1 and isOverCatalog(input.Position) then
			dragStartX = input.Position.X
			dragStartCanvas = catalog.CanvasPosition.X
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local startX = dragStartX
			if startX then
				local moved = input.Position.X - startX
				if math.abs(moved) > 6 then
					catalogDragged = true
				end
				if catalogDragged then
					scrollCatalogTo(dragStartCanvas - moved)
				end
			end
		elseif
			input.UserInputType == Enum.UserInputType.MouseWheel and isOverCatalog(input.Position)
		then
			scrollCatalogTo(catalog.CanvasPosition.X - input.Position.Z * 90)
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragStartX = nil
		end
	end)

	for index, rod in Rods.LIST do
		local tile = Instance.new("TextButton")
		tile.Name = rod.id
		tile.Text = ""
		tile.AutoButtonColor = false
		tile.LayoutOrder = index
		table.insert(
			outlines,
			surface(tile, Color3.fromRGB(32, 91, 149), NAVY, Color3.fromRGB(45, 109, 160), 12)
		)
		local view = frame(tile, "Miniature")
		view.Size = UDim2.new(1, -4, 1, -5)
		tile.Activated:Connect(function()
			if not catalogDragged then
				selectRod(index)
			end
		end)
		table.insert(slots, { holder = view, rod = rod })
		tile.Parent = catalog
	end

	local function layout()
		local width = scroll.AbsoluteWindowSize.X
		if width <= 0 then
			return
		end
		local stacked = gui.AbsoluteSize.Y > gui.AbsoluteSize.X
		local shell = ribbon and ribbon.Parent
		if not stacked and shell and shell:IsA("Frame") then
			top.Parent = shell
			top.AnchorPoint = Vector2.new(1, 0)
			top.Position = UDim2.new(1, -57, 0, -7)
			top.Size = UDim2.fromOffset(199, 44)
			top.ZIndex = 6
			wallet.Size = UDim2.fromOffset(104, 42)
			robux.Size = UDim2.fromOffset(89, 44)
		else
			top.Parent = body
			top.AnchorPoint = Vector2.zero
			top.Position = UDim2.fromOffset(0, 0)
			top.Size = UDim2.new(1, 0, 0, 44)
			wallet.Size = UDim2.fromOffset(146, 39)
			robux.Size = UDim2.fromOffset(128, 44)
		end
		local available = scroll.AbsoluteWindowSize.Y
		local compact = not stacked and available < 290
		local railHeight = if compact then 60 else 77
		catalog.Size = UDim2.new(1, 0, 0, railHeight)
		local heroHeight = if stacked
			then math.clamp(math.round(width * 0.64), 145, 260)
			else math.clamp(available - railHeight - 10, 131, 460)
		main.Size = UDim2.new(1, 0, 0, if stacked then heroHeight + 182 else heroHeight)
		preview.Size = if stacked then UDim2.new(1, 0, 0, heroHeight) else UDim2.new(0.56, -5, 1, 0)
		details.Position = if stacked
			then UDim2.fromOffset(0, heroHeight + 8)
			else UDim2.new(0.56, 5, 0, 0)
		details.Size = if stacked then UDim2.new(1, 0, 0, 174) else UDim2.new(0.44, -5, 1, 0)
		title.Size = UDim2.new(1, 0, 0.26, -3)
		control.Position = UDim2.fromScale(0, 0.26)
		control.Size = UDim2.new(1, 0, 0.20, -3)
		luck.Position = UDim2.fromScale(0, 0.46)
		luck.Size = UDim2.new(1, 0, 0.20, -3)
		action.AnchorPoint = Vector2.new(0, 1)
		action.Position = UDim2.fromScale(0, 1)
		action.Size = UDim2.new(
			1,
			0,
			0,
			math.max(44, math.floor((if stacked then 174 else heroHeight) * 0.30))
		)
		local slotWidth = math.max(69, math.floor((width - 26) / 5))
		for _, slot in slots do
			local button = slot.holder.Parent
			if button and button:IsA("GuiButton") then
				button.Size = UDim2.fromOffset(slotWidth, railHeight - 8)
			end
		end
		previewsDirty = true
	end

	refreshDetails = function()
		local rod = Rods.LIST[selected]
		local snapshot = Data.get()
		title.Text = Strings.rodName[rod.id] or rod.id
		control.Text = string.format("%s +%.0f%%", Text.control, rod.controlBonus * 100)
		luck.Text = string.format("%s +%.0f%%", Text.luck, rod.luckBonus * 100)
		wallet.Text = if not snapshot
			then Text.loading
			elseif top.Parent == body then string.format(
				Text.workshopBalance,
				formatPrice(snapshot.coins)
			)
			else "◆ " .. formatPrice(snapshot.coins)
		local owned = snapshot ~= nil and table.find(snapshot.rodsOwned, rod.id) ~= nil
		local equipped = snapshot ~= nil and snapshot.equippedRod == rod.id
		local affordable = snapshot ~= nil and snapshot.coins >= rod.price
		local price = formatPrice(rod.price)
		action.Text = if not snapshot
			then Text.loading
			elseif pending then Text.workshopPending
			elseif equipped then Text.equipped
			elseif owned then Text.equip
			elseif affordable then string.format("%s · %s", Text.buy, price)
			else string.format(Text.rodUnaffordable, price)
		action.Interactable = snapshot ~= nil
			and not pending
			and not equipped
			and (owned or affordable)
		action.Selectable = action.Interactable
		Panel.tintButton(
			action,
			if equipped
				then Color3.fromRGB(113, 202, 170)
				elseif owned then CRYSTAL
				elseif affordable then GOLD
				else Color3.fromRGB(173, 157, 137)
		)
		for index, outline in outlines do
			outline.Color = if index == selected then CRYSTAL else Color3.fromRGB(45, 109, 160)
			outline.Thickness = if index == selected then 4 else 2
		end
	end

	action.Activated:Connect(function()
		local snapshot = Data.get()
		local rod = Rods.LIST[selected]
		if not snapshot or pending or not action.Interactable then
			return
		end
		local owned = table.find(snapshot.rodsOwned, rod.id) ~= nil
		local remote = remotes:FindFirstChild(if owned then Net.EQUIP_ROD else Net.BUY_ROD)
		if not remote or not remote:IsA("RemoteEvent") then
			Hud.toast(Text.unavailable)
			return
		end
		requestId += 1
		local token = requestId
		pending = token
		refreshDetails()
		remote:FireServer(rod.id)
		task.delay(5, function()
			if pending == token then
				pending = nil
				refreshDetails()
			end
		end)
	end)

	scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(layout)
	catalog:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		previewsDirty = true
	end)
	Hud.panelChanged:Connect(function(name: string)
		if name == "Shop" then
			local snapshot = Data.get()
			if snapshot then
				for index, rod in Rods.LIST do
					if rod.id == snapshot.equippedRod then
						selectRod(index)
						local tile = slots[index].holder.Parent
						if tile and tile:IsA("GuiButton") then
							catalog.CanvasPosition =
								Vector2.new(math.max(0, (index - 3) * (tile.AbsoluteSize.X + 6)), 0)
						end
						break
					end
				end
			end
			layout()
			refreshDetails()
		else
			reload(hero, hero.rod)
			for _, slot in slots do
				reload(slot, slot.rod)
			end
		end
	end)
	RunService.RenderStepped:Connect(function(dt: number)
		if not gui.Enabled then
			return
		end
		if previewsDirty then
			previewsDirty = false
			mountRodViewport(hero, 0.8)
			local left = catalog.AbsolutePosition.X
			local right = left + catalog.AbsoluteWindowSize.X
			for _, slot in slots do
				local x = slot.holder.AbsolutePosition.X
				if x < right and x + slot.holder.AbsoluteSize.X > left then
					mountRodViewport(slot)
				elseif slot.view then
					reload(slot, slot.rod)
				end
			end
		end
		local reduced = Players.LocalPlayer:GetAttribute("ReduceEffects") == true
		if not reduced then
			rotation = (rotation + dt * 0.72) % (2 * math.pi)
		end
		if hero.model and hero.pose then
			hero.model:PivotTo(
				CFrame.Angles(
					0,
					if reduced then 0.35 else 0.35 + math.sin(rotation) * 0.32,
					DIAG_TILT
				) * hero.pose
			)
		end
	end)
	Data.changed:Connect(function()
		if gui.Enabled then
			refreshDetails()
		end
	end)
	local function watchPreviews(library: Instance)
		if library.Name ~= PREVIEWS then
			return
		end
		local function refreshPreviews()
			reload(hero, hero.rod)
			for _, slot in slots do
				reload(slot, slot.rod)
			end
			previewsDirty = true
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
		if
			player == Players.LocalPlayer
			and prompt.Name == "OpenWorkshop"
			and not Hud.isFishingActive()
		then
			Hud.showPanel("Shop")
		end
	end)
	local result = remotes:WaitForChild(Net.SHOP_RESULT) :: RemoteEvent
	result.OnClientEvent:Connect(function(payload: Net.ShopResult)
		pending = nil
		refreshDetails()
		Hud.toast(
			if payload.ok
				then (Strings.rodName[payload.rodId] or payload.rodId)
				else Text.shopErrors[payload.reason or "unknown"] or Text.unavailable,
			if payload.ok then Theme.crystal else Theme.rose
		)
	end)
	layout()
	refreshDetails()
end

return Shop
