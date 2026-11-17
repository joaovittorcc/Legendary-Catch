--!strict
-- Client mirror of the player's profile. The server pushes a full snapshot on load and
-- after every change; UI reads it here and listens to `changed`. Never written by the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("Types"))

local Data = {}

local current: Types.Snapshot? = nil
local changedEvent = Instance.new("BindableEvent")

Data.changed = changedEvent.Event

function Data.get(): Types.Snapshot?
	return current
end

function Data.waitLoaded(): Types.Snapshot
	while not current do
		changedEvent.Event:Wait()
	end
	return current :: Types.Snapshot
end

local started = false

function Data.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
		local snapshotRemote = remotes:WaitForChild(Net.PROFILE_SNAPSHOT) :: RemoteEvent
		snapshotRemote.OnClientEvent:Connect(function(snapshot: Types.Snapshot)
			current = snapshot
			changedEvent:Fire(snapshot)
		end)
		-- The first push can arrive before this listener exists; ask again.
		local request = remotes:WaitForChild(Net.REQUEST_PROFILE) :: RemoteEvent
		request:FireServer()
	end)
end

return Data
