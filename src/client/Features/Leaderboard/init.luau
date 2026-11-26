--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Creatures = require(Config:WaitForChild("Creatures"))
local Fishing = require(Config:WaitForChild("Fishing"))
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Panel = require(script.Parent.Hud:WaitForChild("Panel"))

local Leaderboard = {}
local localPlayer = Players.LocalPlayer

local BOARDS = { "Catches", "Species", "Level" }
local TAB_INACTIVE = Color3.fromRGB(130, 175, 210)
local GOLD_RANK = Color3.fromRGB(255, 208, 72)
local SILVER_RANK = Color3.fromRGB(214, 224, 238)
local BRONZE_RANK = Color3.fromRGB(220, 148, 86)
local SELF_BG = Color3.fromRGB(255, 245, 208)
local ROW_BG = Color3.fromRGB(250, 243, 227)
local REQUEST_COOLDOWN = 1.08
local INSPECT_COOLDOWN = 1.05

type Thumbnail = { holder: Frame, id: string, hidden: boolean }

local function formatScore(board: string, score: number): string
	local pattern = Text.leaderboard.units[board] or "%d"
	return string.format(pattern, math.round(score))
end

local function rankAccent(rank: number): (Color3, Color3)
	if rank == 1 then
		return GOLD_RANK, Color3.fromRGB(255, 249, 222)
	elseif rank == 2 then
		return SILVER_RANK, Color3.fromRGB(244, 247, 252)
	elseif rank == 3 then
		return BRONZE_RANK, Color3.fromRGB(252, 241, 232)
	end
	return Theme.crystal, ROW_BG
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

local function preview(parent: Instance, creatureId: string, hidden: boolean)
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
	model:PivotTo(cf:ToObjectSpace(model:GetPivot()))
	model.Parent = view
	local camera = Instance.new("Camera")
	camera.FieldOfView = 44
	local radius = math.max(size.Magnitude, 1)
	camera.CFrame = CFrame.lookAt(Vector3.new(0, radius * 0.14, radius * 1.4), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera
end

function Leaderboard.start()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local requestRemote = remotes:WaitForChild(Net.REQUEST_LEADERBOARD) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(Net.LEADERBOARD_RESULT) :: RemoteEvent
	local inspectRemote = remotes:WaitForChild(Net.INSPECT_PLAYER) :: RemoteEvent
	local inspectResultRemote = remotes:WaitForChild(Net.INSPECT_RESULT) :: RemoteEvent

	local gui, scroll, heading =
		Panel.create("Leaderboard", Text.leaderboard.title, Panel.themeColor("Leaderboard"))
	local titleRibbon = gui:FindFirstChild("TitleRibbon", true)
	local titleIconHolder = titleRibbon and titleRibbon:FindFirstChild("TitleIcon")
	local titleIcon = titleIconHolder and titleIconHolder:FindFirstChildWhichIsA("TextLabel")

	local boardView = Instance.new("Frame")
	boardView.Name = "BoardView"
	boardView.BackgroundTransparency = 1
	boardView.Size = UDim2.new(1, -10, 0, 0)
	boardView.AutomaticSize = Enum.AutomaticSize.Y
	Panel.stack(boardView)
	boardView.Parent = scroll

	local albumView = Instance.new("Frame")
	albumView.Name = "AlbumView"
	albumView.BackgroundTransparency = 1
	albumView.Size = UDim2.new(1, -10, 0, 0)
	albumView.AutomaticSize = Enum.AutomaticSize.Y
	albumView.Visible = false
	Panel.stack(albumView)
	albumView.Parent = scroll

	local tabsBar = Instance.new("Frame")
	tabsBar.Name = "Tabs"
	tabsBar.LayoutOrder = 1
	tabsBar.Size = UDim2.new(1, 0, 0, 46)
	tabsBar.BackgroundTransparency = 1
	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.Padding = UDim.new(0, 8)
	tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabsLayout.Parent = tabsBar
	tabsBar.Parent = boardView

	local mineCard = Panel.card(boardView, Theme.gold, 50)
	mineCard.Name = "MyScore"
	mineCard.LayoutOrder = 2
	mineCard.BackgroundColor3 = SELF_BG
	local mineLabel = Panel.label(mineCard, Text.leaderboard.loading, 17, Theme.ink)
	mineLabel.Name = "Value"
	mineLabel.Position = UDim2.fromOffset(14, 0)
	mineLabel.Size = UDim2.new(1, -28, 1, 0)
	mineLabel.TextStrokeTransparency = 1

	local list = Instance.new("Frame")
	list.Name = "Entries"
	list.LayoutOrder = 3
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 0, 60)
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = list
	list.Parent = boardView

	local activeBoard = BOARDS[1]
	local tabButtons: { [string]: TextButton } = {}
	local cachedResults: { [string]: Net.LeaderboardResult } = {}
	local renderGeneration = 0
	local lastRequestAt = 0
	local queuedRequest = false

	local inspectingUserId: number? = nil
	local lastInspectAt = 0
	local albumThumbnails: { Thumbnail } = {}
	local albumGrids: { UIGridLayout } = {}
	local previewsDirty = false

	local function updateAlbumGrids()
		local width = math.max(0, scroll.AbsoluteSize.X - 14)
		local columns = math.clamp(math.floor((width + 10) / 138), 2, 4)
		local cellWidth = math.floor((width - (columns - 1) * 10) / columns)
		for _, grid in albumGrids do
			grid.CellSize = UDim2.fromOffset(cellWidth, math.max(116, math.floor(cellWidth * 0.98)))
		end
	end

	local function refreshAlbumPreviews()
		if not gui.Enabled or not albumView.Visible then
			return
		end
		local top = scroll.AbsolutePosition.Y - 44
		local bottom = scroll.AbsolutePosition.Y + scroll.AbsoluteWindowSize.Y + 44
		local remaining = 12
		for _, thumb in albumThumbnails do
			local holder = thumb.holder
			local y, height = holder.AbsolutePosition.Y, holder.AbsoluteSize.Y
			local show = remaining > 0 and height > 0 and y + height >= top and y <= bottom
			local view = holder:FindFirstChildWhichIsA("ViewportFrame")
			if show then
				remaining -= 1
				if not view then
					preview(holder, thumb.id, thumb.hidden)
				end
			elseif view then
				view:Destroy()
			end
		end
	end

	local function clearAlbum()
		table.clear(albumThumbnails)
		table.clear(albumGrids)
		for _, child in albumView:GetChildren() do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end

	local function showBoardView()
		inspectingUserId = nil
		albumView.Visible = false
		clearAlbum()
		boardView.Visible = true
		heading.Text = Text.leaderboard.title
		if titleIcon and titleIcon:IsA("TextLabel") then
			titleIcon.Text = "👑"
		end
		scroll.CanvasPosition = Vector2.zero
	end

	local function showAlbumLoading(displayName: string)
		clearAlbum()
		boardView.Visible = false
		albumView.Visible = true
		heading.Text = string.format(Text.leaderboard.albumOf, displayName)
		if titleIcon and titleIcon:IsA("TextLabel") then
			titleIcon.Text = "📖"
		end
		scroll.CanvasPosition = Vector2.zero

		local back = Panel.button(albumView, Text.leaderboard.backToBoard, Theme.crystal)
		back.Name = "BackButton"
		back.LayoutOrder = -4
		back.Activated:Connect(showBoardView)

		local card = Panel.card(albumView, Theme.crystal, 72)
		card.Name = "AlbumLoading"
		card.BackgroundColor3 = ROW_BG
		local msg = Panel.label(card, Text.leaderboard.inspectLoading, 16, Theme.ink)
		msg.Size = UDim2.fromScale(1, 1)
		msg.TextStrokeTransparency = 1
	end

	local function renderInspectAlbum(payload: Net.InspectResult)
		clearAlbum()
		boardView.Visible = false
		albumView.Visible = true
		heading.Text = string.format(Text.leaderboard.albumOf, payload.displayName)
		if titleIcon and titleIcon:IsA("TextLabel") then
			titleIcon.Text = "📖"
		end
		scroll.CanvasPosition = Vector2.zero

		local back = Panel.button(albumView, Text.leaderboard.backToBoard, Theme.crystal)
		back.Name = "BackButton"
		back.LayoutOrder = -4
		back.Activated:Connect(showBoardView)

		local foundSet: { [string]: boolean } = {}
		for _, creatureId in payload.discovered do
			foundSet[creatureId] = true
		end

		local totals: { [string]: number } = {}
		local discoveredByRarity: { [string]: number } = {}
		local totalFound = 0
		for _, entry in Creatures.LIST do
			totals[entry.rarity] = (totals[entry.rarity] or 0) + 1
			if foundSet[entry.id] then
				discoveredByRarity[entry.rarity] = (discoveredByRarity[entry.rarity] or 0) + 1
				totalFound += 1
			end
		end

		local summary = Panel.card(albumView, Theme.gold, 76)
		summary.Name = "InspectSummary"
		summary.LayoutOrder = -3
		summary.BackgroundColor3 = ROW_BG
		local headerText = string.format(
			Text.leaderboard.inspectStats,
			payload.level,
			payload.catches,
			totalFound,
			#Creatures.LIST
		)
		if payload.prestige > 0 then
			headerText ..= string.format(Text.leaderboard.inspectPrestige, payload.prestige)
		end
		if payload.shinies > 0 then
			headerText ..= string.format(Text.leaderboard.inspectShinies, payload.shinies)
		end
		local statsLabel = Panel.label(summary, headerText, 15, Theme.ink)
		statsLabel.Name = "Stats"
		statsLabel.Position = UDim2.fromOffset(12, 8)
		statsLabel.Size = UDim2.new(1, -24, 0, 40)
		statsLabel.TextStrokeTransparency = 1
		local track = Instance.new("Frame")
		track.Name = "AlbumTrack"
		track.Position = UDim2.fromOffset(12, 56)
		track.Size = UDim2.new(1, -24, 0, 8)
		track.BackgroundTransparency = 1
		progressBar(track, totalFound, #Creatures.LIST, Theme.crystal)
		track.Parent = summary

		local order = 0
		for _, rarity in Fishing.RARITY_ORDER do
			local color = Theme.rarity[rarity]
			local count = discoveredByRarity[rarity] or 0
			local total = totals[rarity] or 0
			order += 1
			local section = Panel.label(
				albumView,
				string.format("%s  ·  %d / %d", Theme.rarityLabel(rarity), count, total),
				17
			)
			section.LayoutOrder = order
			section.TextStrokeTransparency = 1
			local mystic = Theme.rarityRank(rarity) == 6
			if mystic then
				section.BackgroundTransparency = 0
				Theme.corner(section, 10)
				Theme.iridescent(section)
			end
			order += 1
			local barHolder = Instance.new("Frame")
			barHolder.LayoutOrder = order
			barHolder.BackgroundTransparency = 1
			barHolder.Size = UDim2.new(1, 0, 0, 8)
			progressBar(barHolder, count, total, color)
			barHolder.Parent = albumView

			order += 1
			local group = Instance.new("Frame")
			group.Name = "Rarity_" .. rarity
			group.LayoutOrder = order
			group.BackgroundTransparency = 1
			group.Size = UDim2.fromScale(1, 0)
			group.AutomaticSize = Enum.AutomaticSize.Y
			local grid = Instance.new("UIGridLayout")
			grid.CellSize = UDim2.fromOffset(128, 128)
			grid.CellPadding = UDim2.fromOffset(10, 10)
			grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
			grid.Parent = group
			table.insert(albumGrids, grid)

			for _, entry in Creatures.ofRarity(rarity) do
				local found = foundSet[entry.id] == true
				local shinyCount = payload.shinyCounts[entry.id] or 0
				local label = if found then Strings.creatureName[entry.id] or entry.id else "???"
				if found and shinyCount > 0 then
					label = "✦ " .. label
				end
				local card = Instance.new("Frame")
				card.Name = entry.id
				card.BorderSizePixel = 0
				card.BackgroundColor3 = color:Lerp(Theme.cream, 0.86)
				Theme.corner(card, 14)
				local outline = Instance.new("UIStroke")
				outline.Color = color
				outline.Thickness = 3
				outline.Parent = card
				if mystic then
					Theme.iridescent(card)
				end

				local icon = Instance.new("Frame")
				icon.BackgroundTransparency = 1
				icon.Size = UDim2.fromScale(1, 0.61)
				icon.Parent = card
				table.insert(albumThumbnails, { holder = icon, id = entry.id, hidden = not found })

				local nameLabel = Panel.label(card, label, 14)
				nameLabel.TextStrokeTransparency = 1
				nameLabel.Size = UDim2.fromScale(0.94, 0.24)
				nameLabel.Position = UDim2.fromScale(0.03, 0.59)

				local bestWeight = payload.bestWeights[entry.id]
				local glyph = Theme.rarityGlyph(entry.rarity)
				local footText = if found and typeof(bestWeight) == "number"
					then (if glyph ~= "" then glyph .. " " else "") .. string.format(
						Text.leaderboard.bestWeightShort,
						bestWeight
					)
					else Theme.rarityLabel(entry.rarity)
				local foot = Panel.label(
					card,
					footText,
					14,
					if found and typeof(bestWeight) == "number" then Theme.wood else Theme.ink
				)
				foot.Name = "Footer"
				foot.TextStrokeTransparency = 1
				foot.Size = UDim2.fromScale(1, 0.17)
				foot.Position = UDim2.fromScale(0, 0.82)

				card.Parent = group
			end
			group.Parent = albumView
		end

		updateAlbumGrids()
		previewsDirty = true
		task.defer(refreshAlbumPreviews)
	end

	local function openInspect(userId: number, displayName: string)
		if not Players:GetPlayerByUserId(userId) then
			return
		end
		local now = os.clock()
		local waitFor = INSPECT_COOLDOWN - (now - lastInspectAt)
		inspectingUserId = userId
		showAlbumLoading(displayName)
		if waitFor <= 0 then
			lastInspectAt = now
			inspectRemote:FireServer(userId)
		else
			task.delay(waitFor, function()
				if inspectingUserId == userId and gui.Enabled then
					lastInspectAt = os.clock()
					inspectRemote:FireServer(userId)
				end
			end)
		end
	end

	local function clearList()
		for _, child in list:GetChildren() do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end

	local function buildRow(entry: Net.LeaderboardEntry, gen: number): Frame
		local isSelf = entry.userId == localPlayer.UserId
		local inServer = Players:GetPlayerByUserId(entry.userId) ~= nil
		local accent, baseBg = rankAccent(entry.rank)
		local row = Panel.card(list, if isSelf then Theme.gold else accent, 58)
		row.Name = "Rank_" .. tostring(entry.rank)
		row.LayoutOrder = entry.rank
		row.BackgroundColor3 = if isSelf then SELF_BG else baseBg
		local stroke = row:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = if isSelf or entry.rank <= 3 then 3 else 2
		end

		local medalText = if entry.rank == 1
			then "🥇"
			elseif entry.rank == 2 then "🥈"
			elseif entry.rank == 3 then "🥉"
			else "#" .. tostring(entry.rank)
		local rankBadge = Panel.label(row, medalText, if entry.rank <= 3 then 22 else 17, Theme.ink)
		rankBadge.Name = "Rank"
		rankBadge.Position = UDim2.fromOffset(8, 12)
		rankBadge.Size = UDim2.fromOffset(36, 36)
		rankBadge.BackgroundTransparency = 0
		rankBadge.BackgroundColor3 = if entry.rank <= 3
			then accent
			else Color3.fromRGB(224, 234, 244)
		rankBadge.TextStrokeTransparency = 1
		Theme.corner(rankBadge, 12)

		local avatar = Instance.new("ImageLabel")
		avatar.Name = "Avatar"
		avatar.Position = UDim2.fromOffset(48, 10)
		avatar.Size = UDim2.fromOffset(38, 38)
		avatar.BackgroundColor3 = Color3.fromRGB(220, 236, 248)
		avatar.BorderSizePixel = 0
		avatar.Image = ""
		Theme.corner(avatar, 21)
		local avStroke = Instance.new("UIStroke")
		avStroke.Color = accent
		avStroke.Thickness = 2
		avStroke.Parent = avatar
		avatar.Parent = row

		task.spawn(function()
			local ok, thumb = pcall(function()
				return Players:GetUserThumbnailAsync(
					entry.userId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size100x100
				)
			end)
			if ok and typeof(thumb) == "string" and renderGeneration == gen and avatar.Parent then
				avatar.Image = thumb
			end
		end)

		local displayName = if isSelf
			then string.format("%s (%s)", entry.name, Text.leaderboard.you)
			else entry.name
		local nameLabel = Panel.label(row, displayName, 16, Theme.ink)
		nameLabel.Name = "PlayerName"
		nameLabel.Position = UDim2.fromOffset(94, 0)
		nameLabel.Size = UDim2.new(if inServer then 0.72 else 0.75, -100, 1, 0)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextScaled = true
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.TextStrokeTransparency = 1
		local nameLimit = Instance.new("UITextSizeConstraint")
		nameLimit.MinTextSize = 11
		nameLimit.MaxTextSize = 16
		nameLimit.Parent = nameLabel

		local scoreLabel =
			Panel.label(row, string.format("%d", math.round(entry.score)), 16, Theme.wood)
		scoreLabel.Name = "Score"
		scoreLabel.AnchorPoint = Vector2.new(1, 0)
		scoreLabel.Position = UDim2.new(1, if inServer then -40 else -8, 0, 0)
		scoreLabel.Size = UDim2.new(0.25, -8, 1, 0)
		scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
		scoreLabel.TextStrokeTransparency = 1

		if inServer then
			local badge = Panel.label(row, "📖", 16, Theme.ink)
			badge.Name = "InspectBadge"
			badge.AnchorPoint = Vector2.new(1, 0.5)
			badge.Position = UDim2.new(1, -8, 0.5, 0)
			badge.Size = UDim2.fromOffset(26, 26)
			badge.BackgroundTransparency = 0
			badge.BackgroundColor3 = Theme.crystal:Lerp(Theme.cream, 0.55)
			badge.TextStrokeTransparency = 1
			Theme.corner(badge, 9)

			local trigger = Instance.new("TextButton")
			trigger.Name = "InspectButton"
			trigger.Text = ""
			trigger.AutoButtonColor = false
			trigger.BackgroundTransparency = 1
			trigger.Size = UDim2.fromScale(1, 1)
			trigger.ZIndex = 10
			trigger.Activated:Connect(function()
				openInspect(entry.userId, entry.name)
			end)
			trigger.Parent = row
		end

		return row
	end

	local function render(board: string, payload: Net.LeaderboardResult?)
		renderGeneration += 1
		local gen = renderGeneration
		clearList()

		if not payload then
			mineLabel.Text = Text.leaderboard.loading
			local loadingCard = Panel.card(list, Theme.crystal, 66)
			loadingCard.Name = "Loading"
			loadingCard.BackgroundColor3 = ROW_BG
			local msg = Panel.label(loadingCard, Text.leaderboard.loading, 16, Theme.ink)
			msg.TextStrokeTransparency = 1
			msg.Size = UDim2.fromScale(1, 1)
			list.Size = UDim2.new(1, 0, 0, 66)
			return
		end

		mineLabel.Text = string.format(Text.leaderboard.yourScore, formatScore(board, payload.mine))

		if #payload.entries == 0 then
			local emptyCard = Panel.card(list, Theme.gold, 232)
			emptyCard.Name = "EmptyState"
			emptyCard.BackgroundColor3 = Color3.fromRGB(255, 248, 226)

			local crownBadge = Instance.new("Frame")
			crownBadge.Name = "CrownEmblem"
			crownBadge.AnchorPoint = Vector2.new(0.5, 0)
			crownBadge.Position = UDim2.new(0.5, 0, 0, 12)
			crownBadge.Size = UDim2.fromOffset(50, 50)
			crownBadge.BackgroundColor3 = Theme.gold
			crownBadge.BorderSizePixel = 0
			Theme.corner(crownBadge, 25)
			local crownStroke = Instance.new("UIStroke")
			crownStroke.Color = Theme.outline
			crownStroke.Thickness = 3
			crownStroke.Parent = crownBadge
			local crownIcon = Panel.label(crownBadge, "👑", 28, Theme.ink)
			crownIcon.Size = UDim2.fromScale(1, 1)
			crownIcon.TextStrokeTransparency = 1
			crownBadge.Parent = emptyCard

			local emptyTitle = Panel.label(emptyCard, Text.leaderboard.empty, 21, Theme.ink)
			emptyTitle.Name = "EmptyTitle"
			emptyTitle.TextStrokeTransparency = 1
			emptyTitle.Position = UDim2.fromOffset(14, 66)
			emptyTitle.Size = UDim2.new(1, -28, 0, 28)

			local podium = Instance.new("Frame")
			podium.Name = "PodiumIllustration"
			podium.AnchorPoint = Vector2.new(0.5, 0)
			podium.Position = UDim2.new(0.5, 0, 0, 100)
			podium.Size = UDim2.fromOffset(234, 72)
			podium.BackgroundTransparency = 1
			podium.Parent = emptyCard

			local steps = {
				{
					rank = "#2",
					medal = "🥈",
					x = 0,
					y = 20,
					h = 52,
					bg = Color3.fromRGB(202, 214, 228),
				},
				{
					rank = "#1",
					medal = "🥇",
					x = 80,
					y = 4,
					h = 68,
					bg = Color3.fromRGB(255, 206, 76),
				},
				{
					rank = "#3",
					medal = "🥉",
					x = 160,
					y = 28,
					h = 44,
					bg = Color3.fromRGB(234, 166, 108),
				},
			}
			for _, stepInfo in steps do
				local block = Instance.new("Frame")
				block.Name = "Step" .. stepInfo.rank
				block.Position = UDim2.fromOffset(stepInfo.x, stepInfo.y)
				block.Size = UDim2.fromOffset(74, stepInfo.h)
				block.BackgroundColor3 = stepInfo.bg
				block.BorderSizePixel = 0
				Theme.corner(block, 12)
				local blockStroke = Instance.new("UIStroke")
				blockStroke.Color = Theme.outline
				blockStroke.Thickness = 2.5
				blockStroke.Parent = block
				local medal = Panel.label(block, stepInfo.medal, 22, Theme.ink)
				medal.Size = UDim2.new(1, 0, 0, 24)
				medal.Position = UDim2.fromOffset(0, 4)
				medal.TextStrokeTransparency = 1
				local rankTxt = Panel.label(block, stepInfo.rank, 14, Theme.ink)
				rankTxt.Size = UDim2.new(1, 0, 0, 18)
				rankTxt.Position = UDim2.new(0, 0, 1, -20)
				rankTxt.TextStrokeTransparency = 1
				block.Parent = podium
			end

			local emptySub = Panel.label(emptyCard, Text.leaderboard.emptySubtitle, 15, Theme.wood)
			emptySub.Name = "EmptySubtitle"
			emptySub.TextStrokeTransparency = 1
			emptySub.TextWrapped = true
			emptySub.Position = UDim2.fromOffset(18, 178)
			emptySub.Size = UDim2.new(1, -36, 0, 44)

			list.Size = UDim2.new(1, 0, 0, 232)
			return
		end

		for _, entry in payload.entries do
			buildRow(entry, gen)
		end
		list.Size = UDim2.new(1, 0, 0, #payload.entries * 66 - 8)
	end

	local function requestBoard(board: string)
		local now = os.clock()
		local waitFor = REQUEST_COOLDOWN - (now - lastRequestAt)
		if waitFor <= 0 then
			lastRequestAt = now
			requestRemote:FireServer(board)
			return
		end
		if queuedRequest then
			return
		end
		queuedRequest = true
		task.delay(waitFor, function()
			queuedRequest = false
			if gui.Enabled then
				lastRequestAt = os.clock()
				requestRemote:FireServer(activeBoard)
			end
		end)
	end

	local function selectBoard(board: string)
		activeBoard = board
		for id, btn in tabButtons do
			Panel.tintButton(btn, if id == board then Theme.gold else TAB_INACTIVE)
		end
		render(board, cachedResults[board])
		requestBoard(board)
	end

	for order, board in BOARDS do
		local btn = Panel.button(tabsBar, Text.leaderboard.tabs[board] or board, Theme.crystal)
		btn.Name = "Tab_" .. board
		btn.LayoutOrder = order
		btn.Size = UDim2.new(1 / #BOARDS, -6, 1, 0)
		btn.TextSize = 16
		tabButtons[board] = btn
		btn.Activated:Connect(function()
			selectBoard(board)
		end)
	end

	resultRemote.OnClientEvent:Connect(function(payload: Net.LeaderboardResult)
		if typeof(payload) ~= "table" or typeof(payload.board) ~= "string" then
			return
		end
		cachedResults[payload.board] = payload
		if gui.Enabled and boardView.Visible and payload.board == activeBoard then
			render(payload.board, payload)
		end
	end)

	inspectResultRemote.OnClientEvent:Connect(function(payload: Net.InspectResult)
		if typeof(payload) ~= "table" or typeof(payload.userId) ~= "number" then
			return
		end
		if not gui.Enabled or inspectingUserId ~= payload.userId then
			return
		end
		renderInspectAlbum(payload)
	end)

	local function refreshOnlineRows()
		if gui.Enabled and boardView.Visible and cachedResults[activeBoard] then
			render(activeBoard, cachedResults[activeBoard])
		end
	end

	Players.PlayerAdded:Connect(refreshOnlineRows)
	Players.PlayerRemoving:Connect(function(removed)
		if inspectingUserId == removed.UserId and gui.Enabled and albumView.Visible then
			showBoardView()
		else
			refreshOnlineRows()
		end
	end)

	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updateAlbumGrids()
		previewsDirty = true
	end)
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		previewsDirty = true
	end)
	RunService.Heartbeat:Connect(function()
		if previewsDirty and gui.Enabled and albumView.Visible then
			previewsDirty = false
			refreshAlbumPreviews()
		end
	end)

	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled then
			showBoardView()
			selectBoard(activeBoard)
		else
			showBoardView()
		end
	end)
end

return Leaderboard
