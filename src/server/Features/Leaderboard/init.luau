--!strict
-- Global leaderboards (OrderedDataStore): total catches, species discovered, player level.
-- Scores are written from the profile every minute while the player is online. The client asks
-- for a board with RequestLeaderboard(boardName) and gets the cached top 10 back on
-- LeaderboardResult (entries + this player's own score). Without Studio API access everything
-- degrades to an empty board, never an error.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

local Leaderboard = {}
Leaderboard.order = 90

local BOARDS = { "Catches", "Species", "Level" }
local STORE_SUFFIX = if RunService:IsStudio() then "_Studio_v1" else "_v1"
local TOP = 10
local SAVE_INTERVAL = 60
local CACHE_SECONDS = 90

local stores: { [string]: OrderedDataStore? } = {}
local cache: { [string]: { at: number, entries: { Net.LeaderboardEntry } } } = {}
local nameCache: { [number]: string } = {}
local lastSaved: { [Player]: { [string]: number } } = {}
local result: RemoteEvent

local function scoreOf(player: Player, board: string): number?
	local profile = PlayerData.get(player)
	if not profile then
		return nil
	end
	if board == "Catches" then
		return profile.stats.catches
	elseif board == "Level" then
		return profile.stats.level
	end
	local species = 0
	for _ in profile.collection do
		species += 1
	end
	return species
end

local function store(board: string): OrderedDataStore?
	if stores[board] == nil then
		local ok, s = pcall(function()
			return DataStoreService:GetOrderedDataStore("Board_" .. board .. STORE_SUFFIX)
		end)
		stores[board] = if ok then s else nil
	end
	return stores[board]
end

local function nameOf(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local live = Players:GetPlayerByUserId(userId)
	if live then
		nameCache[userId] = live.DisplayName
		return live.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and typeof(name) == "string" and name ~= "" then
		nameCache[userId] = name
		return name
	end
	return "???"
end

local function top(board: string): { Net.LeaderboardEntry }
	local entry = cache[board]
	if entry and os.clock() - entry.at < CACHE_SECONDS then
		return entry.entries
	end
	local entries: { Net.LeaderboardEntry } = {}
	local s = store(board)
	if s then
		local ok, pages = pcall(function()
			return s:GetSortedAsync(false, TOP)
		end)
		if ok and pages then
			local okPage, data = pcall(function()
				return pages:GetCurrentPage()
			end)
			if okPage and data then
				for rank, item in data do
					local userId = tonumber(item.key)
					if userId and typeof(item.value) == "number" then
						table.insert(entries, {
							rank = rank,
							userId = userId,
							name = nameOf(userId),
							score = item.value,
						})
					end
				end
			end
		end
	end
	cache[board] = { at = os.clock(), entries = entries }
	return entries
end

local function onRequest(player: Player, board: unknown)
	if typeof(board) ~= "string" or #board > 32 or not table.find(BOARDS, board) then
		return
	end
	local entries = top(board)
	result:FireClient(
		player,
		{
			board = board,
			entries = entries,
			mine = scoreOf(player, board) or 0,
		} :: Net.LeaderboardResult
	)
end

local function savePlayer(player: Player)
	local saved = lastSaved[player]
	if not saved then
		saved = {}
		lastSaved[player] = saved
	end
	local userIdKey = tostring(player.UserId)
	for _, board in BOARDS do
		local score = scoreOf(player, board)
		local s = store(board)
		if score and s and score > 0 and saved[board] ~= score then
			local ok = pcall(function()
				s:SetAsync(userIdKey, score)
			end)
			if ok then
				saved[board] = score
			end
		end
	end
end

local function saveAll()
	for _, player in Players:GetPlayers() do
		savePlayer(player)
	end
end

local function flushOnShutdown()
	local players = Players:GetPlayers()
	local pending = #players
	if pending == 0 then
		return
	end
	for _, player in players do
		task.spawn(function()
			savePlayer(player)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 10
	while pending > 0 and os.clock() < deadline do
		task.wait(0.05)
	end
end

function Leaderboard.start()
	result = Remotes.event(Net.LEADERBOARD_RESULT)
	Remotes.onServerEvent(Net.REQUEST_LEADERBOARD, 1, 3, onRequest)
	Players.PlayerRemoving:Connect(function(player)
		local snapshotScores: { [string]: number } = {}
		local saved = lastSaved[player]
		for _, board in BOARDS do
			local score = scoreOf(player, board)
			if score and score > 0 and (not saved or saved[board] ~= score) then
				snapshotScores[board] = score
			end
		end
		lastSaved[player] = nil
		if next(snapshotScores) ~= nil then
			local userIdKey = tostring(player.UserId)
			task.spawn(function()
				for board, score in snapshotScores do
					local s = store(board)
					if s then
						pcall(function()
							s:SetAsync(userIdKey, score)
						end)
					end
				end
			end)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(SAVE_INTERVAL)
			saveAll()
		end
	end)
	game:BindToClose(flushOnShutdown)
end

return Leaderboard
