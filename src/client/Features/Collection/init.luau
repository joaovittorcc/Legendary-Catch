--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Creatures = require(Config:WaitForChild("Creatures"))
local Fishing = require(Config:WaitForChild("Fishing"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local RunService = game:GetService("RunService")

local Collection = {}

local function preview(parent: Instance, creatureId: string, hidden: boolean): Model?
	local library = ReplicatedStorage:FindFirstChild(Creatures.MODELS_FOLDER)
	local template = library and library:FindFirstChild(creatureId)
	local view = Instance.new("ViewportFrame")
	view.Size = UDim2.fromScale(1, 1)
	view.BackgroundTransparency = 1
	view.Ambient = Color3.fromRGB(178, 181, 210)
	view.LightColor = Color3.fromRGB(255, 228, 190)
	view.Parent = parent
	local model = if template and template:IsA("Model")
		then template:Clone()
		else Instance.new("Model")
	if not model:FindFirstChildWhichIsA("BasePart", true) then
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(2, 1.2, 1)
		part.Color = Theme.crystal
		part.Parent = model
	end
	for _, instance in model:GetDescendants() do
		if hidden and instance:IsA("BasePart") then
			instance.Color = Theme.ink
			instance.Material = Enum.Material.SmoothPlastic
			if instance:IsA("MeshPart") then
				instance.TextureID = ""
			end
		elseif
			hidden
			and (
				instance:IsA("SurfaceAppearance")
				or instance:IsA("Decal")
				or instance:IsA("ParticleEmitter")
				or instance:IsA("Light")
			)
		then
			instance:Destroy()
		end
	end
	local cf, size = model:GetBoundingBox()
	local pivot = cf:ToObjectSpace(model:GetPivot())
	model:PivotTo(pivot)
	model.Parent = view
	model:SetAttribute("PreviewPivot", pivot)
	local camera = Instance.new("Camera")
	local radius = math.max(size.Magnitude, 1)
	camera.CFrame = CFrame.lookAt(Vector3.new(0, radius * 0.14, radius * 1.4), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera
	return model
end

function Collection.start()
	local gui, scroll = Panel.create("Collection", Text.collection, Theme.crystal)
	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Size = UDim2.fromScale(1, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Parent = scroll

	local spinning: Model? = nil
	local rotation: RBXScriptConnection? = nil
	local selected: Creatures.Creature? = nil
	local function render()
		spinning = nil
		body:ClearAllChildren()
		local snapshot = Data.get()
		local creature = selected
		if creature and snapshot then
			Panel.stack(body)
			local record = snapshot.collection[creature.id]
			local title = if record
				then Strings.creatureName[creature.id] or creature.id
				else Text.undiscovered
			Panel.label(body, title, 23, Theme.rarity[creature.rarity])
			local stage = Instance.new("Frame")
			stage.Size = UDim2.new(1, 0, 0, 145)
			stage.BackgroundColor3 = Theme.ink
			Theme.corner(stage, 12)
			stage.Parent = body
			spinning = preview(stage, creature.id, record == nil)
			if record then
				Panel.label(
					body,
					string.format(
						"%s: %d   ·   %s: %.2f kg",
						Text.captures,
						record.count,
						Text.bestWeight,
						record.bestWeight
					),
					15
				)
				local lore = Strings.creatureLore[creature.id]
				if lore then
					Panel.label(body, lore, 15, Theme.muted).Size = UDim2.new(1, 0, 0, 66)
				end
			end
			Panel.button(body, Text.collection, Theme.crystal).Activated:Connect(function()
				selected = nil
				render()
			end)
			return
		end
		Panel.stack(body)
		if not snapshot then
			Panel.label(body, Text.loading, 18)
			return
		end
		for _, rarity in Fishing.RARITY_ORDER do
			local color = Theme.rarity[rarity]
			Panel.label(body, Strings.rarity[rarity] or rarity, 17, color)
			local group = Instance.new("Frame")
			group.BackgroundTransparency = 1
			group.Size = UDim2.fromScale(1, 0)
			group.AutomaticSize = Enum.AutomaticSize.Y
			local grid = Instance.new("UIGridLayout")
			grid.CellSize = UDim2.new(0.31, 0, 0, 96)
			grid.CellPadding = UDim2.new(0.025, 0, 0, 8)
			grid.Parent = group
			for _, entry in Creatures.ofRarity(rarity) do
				local found = snapshot.collection[entry.id] ~= nil
				local card = Panel.button(group, "", color)
				local icon = Instance.new("Frame")
				icon.BackgroundTransparency = 1
				icon.Size = UDim2.fromScale(1, 0.66)
				icon.Parent = card
				preview(icon, entry.id, not found)
				local name = Panel.label(
					card,
					if found then Strings.creatureName[entry.id] or entry.id else "???",
					13
				)
				name.Size = UDim2.fromScale(0.94, 0.3)
				name.Position = UDim2.fromScale(0.03, 0.67)
				card.Activated:Connect(function()
					selected = entry
					scroll.CanvasPosition = Vector2.zero
					render()
				end)
			end
			group.Parent = body
		end
	end

	Hud.panelChanged:Connect(function(name: string)
		gui.Enabled = name == "Collection"
		if rotation then
			rotation:Disconnect()
			rotation = nil
		end
		if gui.Enabled then
			render()
			rotation = RunService.RenderStepped:Connect(function()
				local model = spinning
				local pivot = model and model:GetAttribute("PreviewPivot")
				if model and typeof(pivot) == "CFrame" then
					model:PivotTo(CFrame.Angles(0, os.clock() * 0.65, 0) * pivot)
				end
			end)
		else
			selected = nil
			spinning = nil
			body:ClearAllChildren()
		end
	end)
	Data.changed:Connect(function()
		if gui.Enabled then
			render()
		end
	end)
end

return Collection
