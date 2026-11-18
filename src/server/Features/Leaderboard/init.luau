--!strict
-- Global leaderboards (OrderedDataStore): total catches, species discovered, player level.
-- Scores are written from the profile every minute while the player is online. The client asks
-- for a board with RequestLeaderboard(boardName) and gets the cached top 10 back on
-- LeaderboardResult (entries + this player's own score). Without Studio API access everything
-- degrades to an empty board, never an error.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

local Leaderboard = {}
Leaderboard.order = 90

local BOARDS = { "Catches", "Species", "Level" }
local TOP = 10
local SAVE_INTERVAL = 60
local CACHE_SECONDS = 90

local stores: { [string]: OrderedDataStore? } = {}
local cache: { [string]: { at: number, entries: { Net.LeaderboardEntry } } } = {}
local nameCache: { [number]: string } = {}
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
			return DataStoreService:GetOrderedDataStore("Board_" .. board .. "_v1")
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
	local text = if ok and typeof(name) == "string" then name else "???"
	nameCache[userId] = text
	return text
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
	if typeof(board) ~= "string" or not table.find(BOARDS, board) then
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

local function saveAll()
	for _, player in Players:GetPlayers() do
		for _, board in BOARDS do
			local score = scoreOf(player, board)
			local s = store(board)
			if score and s and score > 0 then
				pcall(function()
					s:SetAsync(tostring(player.UserId), score)
				end)
			end
		end
	end
end

function Leaderboard.start()
	result = Remotes.event(Net.LEADERBOARD_RESULT)
	Remotes.onServerEvent(Net.REQUEST_LEADERBOARD, 1, 3, onRequest)
	task.spawn(function()
		while true do
			task.wait(SAVE_INTERVAL)
			saveAll()
		end
	end)
	game:BindToClose(saveAll)
end

return Leaderboard
