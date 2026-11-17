--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Perfect = {}
local activeCast: number? = nil
local flawless = false

function Perfect.mark()
	if activeCast then
		flawless = true
	end
end

function Perfect.start(remotes: Instance)
	local updates = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent
	updates.OnClientEvent:Connect(function(update: Net.FishingUpdate)
		if update.event == "bite" then
			activeCast = update.castId
			flawless = false
		elseif
			update.event == "caught"
			or update.event == "escaped"
			or update.event == "cancelled"
			or update.event == "cast"
		then
			if
				update.event == "caught"
				and flawless
				and activeCast
				and update.castId == activeCast
			then
				local report = remotes:FindFirstChild(Net.REPORT_PERFECT)
				if report and report:IsA("RemoteEvent") then
					report:FireServer(activeCast)
				end
			end
			activeCast = nil
			flawless = false
		end
	end)
end

return Perfect
