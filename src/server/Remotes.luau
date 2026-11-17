--!strict
-- Creates remotes on demand and wraps client→server handlers with a per-player rate limit,
-- so every feature validates input against spam the same way.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Remotes = {}

local function folder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(Net.FOLDER)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = Net.FOLDER
	f.Parent = ReplicatedStorage
	return f
end

function Remotes.event(name: string): RemoteEvent
	local f = folder()
	local existing = f:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = f
	return r
end

-- Token bucket per player: `perSecond` sustained, bursts up to `burst`. Excess calls are
-- dropped silently (a real client never gets near these limits).
function Remotes.onServerEvent(
	name: string,
	perSecond: number,
	burst: number,
	handler: (Player, ...any) -> ()
)
	local remote = Remotes.event(name)
	local buckets: { [Player]: { tokens: number, at: number } } = {}
	remote.OnServerEvent:Connect(function(player: Player, ...)
		local now = os.clock()
		local b = buckets[player]
		if not b then
			b = { tokens = burst, at = now }
			buckets[player] = b
		end
		b.tokens = math.min(burst, b.tokens + (now - b.at) * perSecond)
		b.at = now
		if b.tokens < 1 then
			return
		end
		b.tokens -= 1
		handler(player, ...)
	end)
	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)
	return remote
end

return Remotes
