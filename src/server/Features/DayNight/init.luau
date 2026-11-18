--!strict
-- Server-authoritative 12-minute day/night cycle.
-- Advances Lighting.ClockTime smoothly so all players share the same time of day;
-- client LivingWorld tints Atmosphere/Ambient smoothly and yields to OceanEvents.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DayNight = {}
DayNight.order = 20

local CYCLE_SECONDS = 720 -- 12 real minutes per 24 in-game hours
local UPDATE_INTERVAL = 0.25

local function nightWeightFor(clock: number): number
	if clock >= 17.5 and clock < 19.0 then
		return (clock - 17.5) / 1.5
	elseif clock >= 19.0 or clock < 5.5 then
		return 1
	elseif clock >= 5.5 and clock < 7.0 then
		return 1 - (clock - 5.5) / 1.5
	end
	return 0
end

function DayNight.start()
	local startClock = Lighting.ClockTime
	local t0 = os.clock()
	ReplicatedStorage:SetAttribute("DayClockTime", startClock)
	ReplicatedStorage:SetAttribute("DayNightWeight", nightWeightFor(startClock))

	task.spawn(function()
		while true do
			local elapsed = os.clock() - t0
			local clock = (startClock + (elapsed / CYCLE_SECONDS) * 24) % 24
			Lighting.ClockTime = clock
			ReplicatedStorage:SetAttribute("DayClockTime", clock)
			ReplicatedStorage:SetAttribute("DayNightWeight", nightWeightFor(clock))
			task.wait(UPDATE_INTERVAL)
		end
	end)
end

return DayNight
