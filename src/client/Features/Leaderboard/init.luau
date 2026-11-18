--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
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

function Leaderboard.start()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local requestRemote = remotes:WaitForChild(Net.REQUEST_LEADERBOARD) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(Net.LEADERBOARD_RESULT) :: RemoteEvent

	local gui, body = Panel.create("Leaderboard", Text.leaderboard.title, Theme.crystal)
	Panel.stack(body)

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
	tabsBar.Parent = body

	local mineCard = Panel.card(body, Theme.gold, 50)
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
	list.Parent = body

	local activeBoard = BOARDS[1]
	local tabButtons: { [string]: TextButton } = {}
	local cachedResults: { [string]: Net.LeaderboardResult } = {}
	local renderGeneration = 0
	local lastRequestAt = 0
	local queuedRequest = false

	local function clearList()
		for _, child in list:GetChildren() do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end

	local function buildRow(entry: Net.LeaderboardEntry, gen: number): Frame
		local isSelf = entry.userId == localPlayer.UserId
		local accent, baseBg = rankAccent(entry.rank)
		local row = Panel.card(list, if isSelf then Theme.gold else accent, 58)
		row.Name = "Rank_" .. tostring(entry.rank)
		row.LayoutOrder = entry.rank
		row.BackgroundColor3 = if isSelf then SELF_BG else baseBg
		local stroke = row:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = if isSelf or entry.rank <= 3 then 3 else 2
		end

		local rankBadge = Panel.label(row, "#" .. tostring(entry.rank), 18, Theme.ink)
		rankBadge.Name = "Rank"
		rankBadge.Position = UDim2.fromOffset(8, 12)
		rankBadge.Size = UDim2.fromOffset(34, 34)
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
		nameLabel.Size = UDim2.new(0.73, -100, 1, 0)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextWrapped = false
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.TextStrokeTransparency = 1

		local scoreLabel =
			Panel.label(row, string.format("%d", math.round(entry.score)), 16, Theme.wood)
		scoreLabel.Name = "Score"
		scoreLabel.AnchorPoint = Vector2.new(1, 0)
		scoreLabel.Position = UDim2.new(1, -8, 0, 0)
		scoreLabel.Size = UDim2.new(0.27, -8, 1, 0)
		scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
		scoreLabel.TextStrokeTransparency = 1

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
			local emptyCard = Panel.card(list, Theme.crystal, 88)
			emptyCard.Name = "EmptyState"
			emptyCard.BackgroundColor3 = ROW_BG
			local emptyTitle = Panel.label(emptyCard, Text.leaderboard.empty, 20, Theme.wood)
			emptyTitle.TextStrokeTransparency = 1
			emptyTitle.Position = UDim2.fromOffset(12, 0)
			emptyTitle.Size = UDim2.new(1, -24, 1, 0)
			list.Size = UDim2.new(1, 0, 0, 88)
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
		if gui.Enabled and payload.board == activeBoard then
			render(payload.board, payload)
		end
	end)

	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled then
			selectBoard(activeBoard)
		end
	end)
end

return Leaderboard
