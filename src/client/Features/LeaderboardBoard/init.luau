--!strict
-- Candy-styled SurfaceGuis mounted on the physical plaza LeaderboardBoard screens:
--   LeaderboardScreen_Catches, LeaderboardScreen_Species, LeaderboardScreen_Level
-- Displays Top 5 entries + local player's own score, refreshing every ~60 s only when nearby.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local LeaderboardBoard = {}
LeaderboardBoard.order = 95

local player = Players.LocalPlayer

local NEAR_DISTANCE = 52
local REFRESH_INTERVAL = 60
local STAGGER_SECONDS = 1.18

type ScreenSpec = {
	board: string,
	partName: string,
	icon: string,
	accent: Color3,
}

local SPECS: { ScreenSpec } = {
	{
		board = "Catches",
		partName = "LeaderboardScreen_Catches",
		icon = "🎣",
		accent = Theme.gold,
	},
	{
		board = "Species",
		partName = "LeaderboardScreen_Species",
		icon = "📖",
		accent = Theme.crystal,
	},
	{
		board = "Level",
		partName = "LeaderboardScreen_Level",
		icon = "⭐",
		accent = Theme.rose,
	},
}

local GOLD = Color3.fromRGB(255, 208, 72)
local SILVER = Color3.fromRGB(214, 224, 238)
local BRONZE = Color3.fromRGB(220, 148, 86)

local function rankBg(rank: number, isSelf: boolean): Color3
	if isSelf then
		return Color3.fromRGB(64, 58, 36)
	elseif rank == 1 then
		return Color3.fromRGB(58, 52, 34)
	elseif rank == 2 then
		return Color3.fromRGB(44, 54, 74)
	elseif rank == 3 then
		return Color3.fromRGB(58, 44, 40)
	end
	return Color3.fromRGB(32, 46, 74)
end

local function rankPill(rank: number): Color3
	if rank == 1 then
		return GOLD
	elseif rank == 2 then
		return SILVER
	elseif rank == 3 then
		return BRONZE
	end
	return Color3.fromRGB(205, 224, 240)
end

local function formatScore(board: string, score: number): string
	local pattern = Text.leaderboard.units[board] or "%d"
	return string.format(pattern, math.round(score))
end

local function makeLabel(
	parent: Instance,
	content: string,
	size: number,
	color: Color3,
	align: Enum.TextXAlignment?
): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Font = Theme.font
	lbl.Text = content
	lbl.TextSize = size
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 1
	lbl.TextXAlignment = align or Enum.TextXAlignment.Center
	lbl.Parent = parent
	return lbl
end

type BoardWidget = {
	gui: SurfaceGui,
	list: Frame,
	mineLabel: TextLabel,
	board: string,
	accent: Color3,
}

local function buildWidget(screenPart: BasePart, spec: ScreenSpec): BoardWidget
	local existing = screenPart:FindFirstChild("BoardSurfaceGui")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardSurfaceGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50 -- 8x5 studs -> 400x250 px
	gui.LightInfluence = 0
	gui.Brightness = 0.85
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
	root.BorderSizePixel = 0
	Theme.corner(root, 10)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Color = spec.accent
	outerStroke.Thickness = 4
	outerStroke.Parent = root
	root.Parent = gui

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Position = UDim2.fromOffset(8, 8)
	header.Size = UDim2.new(1, -16, 0, 38)
	Theme.surface(header, spec.accent, 10)
	header.Parent = root

	local tabName = Text.leaderboard.tabs[spec.board] or spec.board
	local title = makeLabel(header, spec.icon .. "  " .. tabName, 21, Theme.sand)
	title.Size = UDim2.fromScale(1, 1)
	title.TextStrokeColor3 = Theme.outline
	title.TextStrokeTransparency = 0.15

	local list = Instance.new("Frame")
	list.Name = "TopRows"
	list.Position = UDim2.fromOffset(10, 52)
	list.Size = UDim2.new(1, -20, 1, -88)
	list.BackgroundTransparency = 1
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = list
	list.Parent = root

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.new(0, 10, 1, -8)
	footer.Size = UDim2.new(1, -20, 0, 24)
	footer.BackgroundColor3 = Color3.fromRGB(34, 48, 78)
	footer.BorderSizePixel = 0
	Theme.corner(footer, 8)
	local footStroke = Instance.new("UIStroke")
	footStroke.Color = Theme.gold
	footStroke.Thickness = 2
	footStroke.Parent = footer
	footer.Parent = root

	local mineLabel = makeLabel(footer, Text.leaderboard.loading, 14, Theme.gold)
	mineLabel.Name = "MineScore"
	mineLabel.Size = UDim2.new(1, -12, 1, 0)
	mineLabel.Position = UDim2.fromOffset(6, 0)
	mineLabel.TextTruncate = Enum.TextTruncate.AtEnd

	gui.Parent = screenPart
	return {
		gui = gui,
		list = list,
		mineLabel = mineLabel,
		board = spec.board,
		accent = spec.accent,
	}
end

local function renderWidget(widget: BoardWidget, payload: Net.LeaderboardResult?)
	for _, child in widget.list:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	if not payload then
		widget.mineLabel.Text = Text.leaderboard.loading
		local msg = makeLabel(widget.list, Text.leaderboard.loading, 16, Theme.sand)
		msg.Size = UDim2.fromScale(1, 1)
		return
	end

	widget.mineLabel.Text =
		string.format(Text.leaderboard.yourScore, formatScore(widget.board, payload.mine))

	if #payload.entries == 0 then
		local card = Instance.new("Frame")
		card.Name = "Empty"
		card.Size = UDim2.fromScale(1, 1)
		card.BackgroundColor3 = Color3.fromRGB(30, 44, 72)
		card.BorderSizePixel = 0
		Theme.corner(card, 10)
		local stroke = Instance.new("UIStroke")
		stroke.Color = widget.accent
		stroke.Thickness = 2
		stroke.Parent = card
		card.Parent = widget.list

		local msg = makeLabel(card, Text.leaderboard.empty, 20, Theme.sand)
		msg.Size = UDim2.fromScale(1, 1)
		return
	end

	local count = math.min(5, #payload.entries)
	for i = 1, count do
		local entry = payload.entries[i]
		local isSelf = entry.userId == player.UserId

		local row = Instance.new("Frame")
		row.Name = "Row_" .. tostring(i)
		row.LayoutOrder = i
		row.Size = UDim2.new(1, 0, 0, 28)
		row.BackgroundColor3 = rankBg(entry.rank, isSelf)
		row.BorderSizePixel = 0
		Theme.corner(row, 7)
		local rStroke = Instance.new("UIStroke")
		rStroke.Color = if isSelf then Theme.gold else rankPill(entry.rank)
		rStroke.Thickness = if isSelf or entry.rank <= 3 then 2 else 1.5
		rStroke.Parent = row
		row.Parent = widget.list

		local badge = makeLabel(row, "#" .. tostring(entry.rank), 14, Theme.ink)
		badge.Position = UDim2.fromOffset(4, 3)
		badge.Size = UDim2.fromOffset(32, 22)
		badge.BackgroundTransparency = 0
		badge.BackgroundColor3 = rankPill(entry.rank)
		Theme.corner(badge, 6)

		local nameText = if isSelf
			then string.format("%s (%s)", entry.name, Text.leaderboard.you)
			else entry.name
		local nameLbl = makeLabel(row, nameText, 14, Theme.sand, Enum.TextXAlignment.Left)
		nameLbl.Position = UDim2.fromOffset(42, 0)
		nameLbl.Size = UDim2.new(1, -156, 1, 0)
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

		local scoreLbl = makeLabel(
			row,
			formatScore(widget.board, entry.score),
			14,
			Theme.gold,
			Enum.TextXAlignment.Right
		)
		scoreLbl.AnchorPoint = Vector2.new(1, 0)
		scoreLbl.Position = UDim2.new(1, -8, 0, 0)
		scoreLbl.Size = UDim2.fromOffset(104, 28)
		scoreLbl.TextTruncate = Enum.TextTruncate.AtEnd
	end
end

function LeaderboardBoard.start()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local requestRemote = remotes:WaitForChild(Net.REQUEST_LEADERBOARD) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(Net.LEADERBOARD_RESULT) :: RemoteEvent

	local widgetsByBoard: { [string]: BoardWidget } = {}
	local cachedPayloads: { [string]: Net.LeaderboardResult } = {}
	local boardCenter: Vector3? = nil
	local mountedBoard: Instance? = nil

	local function mountBoard(boardModel: Instance)
		if mountedBoard == boardModel then
			return
		end
		mountedBoard = boardModel
		if boardModel:IsA("Model") then
			local cf = boardModel:GetBoundingBox()
			if cf.Position.Magnitude > 0.1 then
				boardCenter = cf.Position
			end
		end
		for _, spec in SPECS do
			task.spawn(function()
				local part = boardModel:FindFirstChild(spec.partName, true)
					or boardModel:WaitForChild(spec.partName, 15)
				if part and part:IsA("BasePart") then
					if not boardCenter then
						boardCenter = part.Position
					end
					local widget = buildWidget(part, spec)
					widgetsByBoard[spec.board] = widget
					renderWidget(widget, cachedPayloads[spec.board])
				end
			end)
		end
	end

	for _, tagged in CollectionService:GetTagged("LeaderboardBoard") do
		mountBoard(tagged)
	end
	CollectionService:GetInstanceAddedSignal("LeaderboardBoard"):Connect(mountBoard)

	resultRemote.OnClientEvent:Connect(function(payload: Net.LeaderboardResult)
		if typeof(payload) ~= "table" or typeof(payload.board) ~= "string" then
			return
		end
		cachedPayloads[payload.board] = payload
		local widget = widgetsByBoard[payload.board]
		if widget then
			renderWidget(widget, payload)
		end
	end)

	local lastRefreshAt = 0
	local refreshing = false

	task.spawn(function()
		while true do
			local center = boardCenter
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if
				center
				and root
				and root:IsA("BasePart")
				and not refreshing
				and (root.Position - center).Magnitude <= NEAR_DISTANCE
			then
				local now = os.clock()
				if lastRefreshAt == 0 or now - lastRefreshAt >= REFRESH_INTERVAL then
					refreshing = true
					lastRefreshAt = now
					for idx, spec in SPECS do
						if idx > 1 then
							task.wait(STAGGER_SECONDS)
						end
						requestRemote:FireServer(spec.board)
					end
					refreshing = false
				end
			end
			task.wait(2)
		end
	end)
end

return LeaderboardBoard
