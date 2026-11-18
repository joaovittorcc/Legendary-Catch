--!strict
-- Seasonal windows (UTC calendar, supports year-wrap like Dec 1 -> Jan 6).
-- Studio override: set Player attribute "DevSeason" = "<seasonId>" on Server.

local RunService = game:GetService("RunService")

export type Season = {
	id: string,
	startMonthDay: { number }, -- { month, day }
	endMonthDay: { number }, -- { month, day }
}

local LIST: { Season } = {
	{
		id = "xmas",
		startMonthDay = { 12, 1 },
		endMonthDay = { 1, 6 },
	},
}

local byId: { [string]: Season } = {}
for _, s in LIST do
	byId[s.id] = s
end

local Seasons = {}
Seasons.LIST = LIST
Seasons.DEV_ATTRIBUTE = "DevSeason"

local function matchesWindow(season: Season, timestamp: number): boolean
	local utc = os.date("!*t", math.floor(timestamp)) :: { [string]: any }
	local month = utc.month :: number
	local day = utc.day :: number
	local mmdd = month * 100 + day
	local startMD = season.startMonthDay[1] * 100 + season.startMonthDay[2]
	local endMD = season.endMonthDay[1] * 100 + season.endMonthDay[2]
	if startMD <= endMD then
		return mmdd >= startMD and mmdd <= endMD
	end
	return mmdd >= startMD or mmdd <= endMD
end

function Seasons.get(id: string): Season?
	return byId[id]
end

function Seasons.active(timestamp: number?): { string }
	local now = timestamp or os.time()
	local ids: { string } = {}
	for _, s in LIST do
		if matchesWindow(s, now) then
			table.insert(ids, s.id)
		end
	end
	return ids
end

function Seasons.isActive(seasonId: string, player: Player?, timestamp: number?): boolean
	if
		RunService:IsStudio()
		and player
		and player:GetAttribute(Seasons.DEV_ATTRIBUTE) == seasonId
	then
		return true
	end
	local season = byId[seasonId]
	return if season then matchesWindow(season, timestamp or os.time()) else false
end

return Seasons
