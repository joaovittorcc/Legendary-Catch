--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Creatures = require(Config:WaitForChild("Creatures"))
local Fishing = require(Config:WaitForChild("Fishing"))
local Milestones = require(Config:WaitForChild("Milestones"))
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local RunService = game:GetService("RunService")

local CreatureMotion = require(script.Parent:WaitForChild("CreatureMotion"))
local Collection = {}
type PreviewPose = { motion: CreatureMotion.Motion, base: CFrame }
type Thumbnail = { holder: Frame, id: string, hidden: boolean, pose: PreviewPose? }

local function preview(parent: Instance, creatureId: string, hidden: boolean): PreviewPose?
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
	local camera = Instance.new("Camera")
	camera.FieldOfView = 44
	local radius = math.max(size.Magnitude, 1)
	camera.CFrame = CFrame.lookAt(Vector3.new(0, radius * 0.14, radius * 1.4), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera
	local creature = Creatures.get(creatureId)
	return if hidden
		then nil
		else {
			motion = CreatureMotion.bind(model, creature and creature.revealStyle),
			base = pivot,
		}
end

local function progressBar(parent: Instance, count: number, target: number, color: Color3)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.BackgroundColor3 = Theme.track
	bar.BorderSizePixel = 0
	Theme.corner(bar, 4)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(math.clamp(count / math.max(target, 1), 0, 1), 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	Theme.corner(fill, 4)
	fill.Parent = bar
	bar.Parent = parent
end

function Collection.start()
	local gui, scroll, heading = Panel.create("Collection", Text.collection, Theme.crystal)
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Size = UDim2.fromScale(1, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Parent = scroll

	local spinning: PreviewPose? = nil
	local motionStart = os.clock()
	local rotation: RBXScriptConnection? = nil
	local selected: Creatures.Creature? = nil
	local showRewards = false
	local pending: string? = nil
	local revision = 0
	local thumbnails: { Thumbnail } = {}
	local grids: { UIGridLayout } = {}
	local titleRibbon = gui:FindFirstChild("TitleRibbon", true)
	local titleIconHolder = titleRibbon and titleRibbon:FindFirstChild("TitleIcon")
	local titleIcon = titleIconHolder and titleIconHolder:FindFirstChildWhichIsA("TextLabel")
	local function updateGrids()
		local width = math.max(0, scroll.AbsoluteSize.X - 14)
		local columns = math.clamp(math.floor((width + 10) / 138), 2, 4)
		local cellWidth = math.floor((width - (columns - 1) * 10) / columns)
		for _, grid in grids do
			grid.CellSize = UDim2.fromOffset(cellWidth, math.max(116, math.floor(cellWidth * 0.98)))
		end
	end
	local lastSignature: string? = nil
	local function refreshPreviews()
		if not gui.Enabled then
			return
		end
		local top = scroll.AbsolutePosition.Y - 44
		local bottom = scroll.AbsolutePosition.Y + scroll.AbsoluteWindowSize.Y + 44
		local remaining = 12
		for _, thumbnail in thumbnails do
			local holder = thumbnail.holder
			local y, height = holder.AbsolutePosition.Y, holder.AbsoluteSize.Y
			local show = remaining > 0 and height > 0 and y + height >= top and y <= bottom
			local view = holder:FindFirstChildWhichIsA("ViewportFrame")
			if show then
				remaining -= 1
				if not view then
					thumbnail.pose = preview(holder, thumbnail.id, thumbnail.hidden)
				end
			elseif view then
				thumbnail.pose = nil
				view:Destroy()
			end
		end
	end

	local function render()
		heading.Text = if showRewards then Text.milestones.title else Text.collection
		if titleIcon and titleIcon:IsA("TextLabel") then
			titleIcon.Text = if showRewards then "🏆" else "🐠"
		end
		spinning = nil
		table.clear(thumbnails)
		table.clear(grids)
		body:ClearAllChildren()
		local snapshot = Data.get()
		local creature = selected
		if creature and snapshot then
			Panel.stack(body)
			local record = snapshot.collection[creature.id]
			local title = if record
				then Strings.creatureName[creature.id] or creature.id
				else Text.undiscovered
			Panel.label(body, title, 23)
			local rarity = Panel.label(body, Theme.rarityLabel(creature.rarity), 15)
			rarity.Name = "Rarity"
			rarity.Size = UDim2.new(1, 0, 0, 22)
			local stage = Instance.new("Frame")
			stage.Size = UDim2.new(1, 0, 0, 145)
			Theme.surface(stage, Theme.crystal, 22, Theme.viewport)
			stage.Parent = body
			spinning = preview(stage, creature.id, record == nil)
			motionStart = os.clock()
			if record then
				local shiny = record.shiny
				if typeof(shiny) == "number" and shiny > 0 then
					Panel.label(body, string.format(Text.shinyCount, shiny), 15, Theme.gold)
				end
				Panel.label(
					body,
					string.format(
						Text.collectionStats,
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
		local totals: { [string]: number } = {}
		local discovered: { [string]: number } = {}
		local totalFound = 0
		for _, entry in Creatures.LIST do
			totals[entry.rarity] = (totals[entry.rarity] or 0) + 1
			if snapshot.collection[entry.id] then
				discovered[entry.rarity] = (discovered[entry.rarity] or 0) + 1
				totalFound += 1
			end
		end
		if showRewards then
			Panel.button(body, Text.collection, Theme.crystal).Activated:Connect(function()
				showRewards = false
				scroll.CanvasPosition = Vector2.zero
				render()
			end)
			local claimed = snapshot.milestones
			if not claimed then
				Panel.label(body, Text.milestones.missing, 16)
				return
			end
			for _, milestone in Milestones.LIST do
				local rarity = milestone.rarity
				local target = if rarity then totals[rarity] or 0 else milestone.count
				local count = if rarity then discovered[rarity] or 0 else totalFound
				local ready = target > 0 and count >= target
				local redeemed = claimed[milestone.id] == true
				local color = if rarity then Theme.rarity[rarity] else Theme.gold
				local title = if rarity
					then string.format(Text.milestones.rarity, Theme.rarityLabel(rarity))
					else string.format(Text.milestones.species, target)
				local row = Panel.card(body, color, 94)
				local emblem = Instance.new("Frame")
				emblem.Name = "MilestoneIcon"
				emblem.AnchorPoint = Vector2.new(0, 0.5)
				emblem.Position = UDim2.new(0, 10, 0.5, 0)
				emblem.Size = UDim2.fromOffset(42, 42)
				emblem.BackgroundColor3 = Color3.fromRGB(255, 238, 195)
				emblem.BorderSizePixel = 0
				Theme.corner(emblem, 21)
				local emblemStroke = Instance.new("UIStroke")
				emblemStroke.Color = color
				emblemStroke.Thickness = 2
				emblemStroke.Parent = emblem
				local icon = Panel.label(emblem, "🏆", 22, Theme.ink)
				icon.Size = UDim2.fromScale(1, 1)
				icon.TextStrokeTransparency = 1
				emblem.Parent = row
				local label = Panel.label(
					row,
					title
						.. string.format(
							"\n%d / %d  ·  +%d ◆",
							math.min(count, target),
							target,
							milestone.reward
						),
					14
				)
				label.Size = UDim2.fromScale(0.49, 1)
				label.Position = UDim2.fromScale(0.1, 0)
				local actionTint = if ready and not redeemed
					then Color3.fromRGB(68, 194, 104)
					else Color3.fromRGB(226, 218, 206)
				local button = Panel.button(
					row,
					if redeemed
						then Text.missions.claimed
						elseif ready then Text.missions.claim
						else Text.missions.ongoing,
					actionTint
				)
				Panel.tintButton(button, actionTint)
				button.TextColor3 = if ready and not redeemed then Theme.sand else Theme.outline
				button.TextStrokeTransparency = if ready and not redeemed then 0.06 else 1
				button.TextSize = 14
				button.Size = UDim2.new(0.34, 0, 0, 44)
				button.Position = UDim2.new(0.63, 0, 0.5, -22)
				button.Interactable = ready and not redeemed
				button.Activated:Connect(function()
					if pending then
						return
					end
					local remote = remotes:FindFirstChild(Net.CLAIM_MILESTONE)
					if not remote or not remote:IsA("RemoteEvent") then
						Hud.toast(Text.unavailable)
						return
					end
					pending = milestone.id
					revision += 1
					local token = revision
					remote:FireServer(milestone.id)
					task.delay(4, function()
						if revision == token then
							pending = nil
						end
					end)
				end)
			end
			return
		end
		Panel.button(body, Text.milestones.title, Theme.gold).Activated:Connect(function()
			showRewards = true
			scroll.CanvasPosition = Vector2.zero
			render()
		end)
		for _, rarity in Fishing.RARITY_ORDER do
			local color = Theme.rarity[rarity]
			local count, total = discovered[rarity] or 0, totals[rarity] or 0
			local section = Panel.label(
				body,
				string.format("%s  ·  %d / %d", Theme.rarityLabel(rarity), count, total),
				17
			)
			local mystic = Theme.rarityRank(rarity) == 6
			if mystic then
				section.BackgroundTransparency = 0
				Theme.corner(section, 10)
				Theme.iridescent(section)
			end
			progressBar(body, count, total, color)
			local group = Instance.new("Frame")
			group.BackgroundTransparency = 1
			group.Size = UDim2.fromScale(1, 0)
			group.AutomaticSize = Enum.AutomaticSize.Y
			local grid = Instance.new("UIGridLayout")
			grid.CellSize = UDim2.fromOffset(128, 128)
			grid.CellPadding = UDim2.fromOffset(10, 10)
			grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
			grid.Parent = group
			table.insert(grids, grid)
			for _, entry in Creatures.ofRarity(rarity) do
				local record = snapshot.collection[entry.id]
				local found = record ~= nil
				local shiny = record and record.shiny
				local label = if found then Strings.creatureName[entry.id] or entry.id else "???"
				if typeof(shiny) == "number" and shiny > 0 then
					label = "✦ " .. label
				end
				local card = Panel.button(group, "", color)
				card.BackgroundColor3 = Theme.cream
				local cardGradient = card:FindFirstChildWhichIsA("UIGradient")
				if cardGradient then
					cardGradient:Destroy()
				end
				card.Position = UDim2.new(0, 0, 0, 0)
				for _, decorationName in { "CandyLip", "CandyShine" } do
					local decoration = card:FindFirstChild(decorationName)
					if decoration then
						decoration:Destroy()
					end
				end
				local outline = card:FindFirstChildWhichIsA("UIStroke")
				if outline then
					outline.Color = color
				end
				if mystic then
					Theme.iridescent(card)
				end
				local icon = Instance.new("Frame")
				icon.BackgroundTransparency = 1
				icon.Size = UDim2.fromScale(1, 0.61)
				icon.Parent = card
				table.insert(thumbnails, { holder = icon, id = entry.id, hidden = not found })
				local name = Panel.label(card, label, 13)
				name.Size = UDim2.fromScale(0.94, 0.27)
				name.Position = UDim2.fromScale(0.03, 0.61)
				local rarityName =
					Panel.label(card, Strings.rarity[entry.rarity] or entry.rarity, 12)
				rarityName.Name = "Rarity"
				rarityName.Size = UDim2.fromScale(1, 0.17)
				rarityName.Position = UDim2.fromScale(0, 0.82)
				card.Activated:Connect(function()
					selected = entry
					scroll.CanvasPosition = Vector2.zero
					render()
				end)
			end
			group.Parent = body
		end
		updateGrids()
		task.defer(refreshPreviews)
	end

	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateGrids)
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(refreshPreviews)
	scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(refreshPreviews)
	local result = remotes:FindFirstChild(Net.CLAIM_RESULT)
	if result and result:IsA("RemoteEvent") then
		result.OnClientEvent:Connect(function(payload: Net.ClaimResult)
			if payload.kind == "milestone" then
				pending = nil
			end
		end)
	end
	Hud.panelChanged:Connect(function(name: string)
		gui.Enabled = name == "Collection" or name == "Milestones"
		if rotation then
			rotation:Disconnect()
			rotation = nil
		end
		if gui.Enabled then
			selected = nil
			showRewards = name == "Milestones"
			scroll.CanvasPosition = Vector2.zero
			render()
			local elapsed = 0
			local wasReduced = false
			rotation = RunService.RenderStepped:Connect(function(dt)
				elapsed += dt
				if elapsed < 1 / 30 then
					return
				end
				elapsed = 0
				local reduced = Players.LocalPlayer:GetAttribute("ReduceEffects") == true
				if reduced and wasReduced then
					return
				end
				wasReduced = reduced
				local time = os.clock() - motionStart
				local detail = spinning
				if detail then
					if reduced then
						CreatureMotion.reset(detail.motion, detail.base)
					else
						CreatureMotion.pose(detail.motion, detail.base, time, true)
					end
				end
				for index, thumbnail in thumbnails do
					local pose = thumbnail.pose
					if pose then
						if reduced then
							CreatureMotion.reset(pose.motion, pose.base)
						else
							CreatureMotion.pose(pose.motion, pose.base, time + index * 0.18, false)
						end
					end
				end
			end)
		else
			selected = nil
			showRewards = false
			lastSignature = nil
			table.clear(thumbnails)
			spinning = nil
			body:ClearAllChildren()
		end
	end)
	Data.changed:Connect(function()
		local snapshot = Data.get()
		if not gui.Enabled or not snapshot then
			return
		end
		local values = {}
		for _, entry in Creatures.LIST do
			local record = snapshot.collection[entry.id]
			if record then
				table.insert(
					values,
					`{entry.id}:{record.count}:{record.bestWeight}:{record.shiny or 0}`
				)
			end
		end
		for _, milestone in Milestones.LIST do
			if snapshot.milestones and snapshot.milestones[milestone.id] then
				table.insert(values, milestone.id)
			end
		end
		local signature = table.concat(values, "|")
		if signature ~= lastSignature then
			lastSignature = signature
			render()
		end
	end)
end

return Collection
