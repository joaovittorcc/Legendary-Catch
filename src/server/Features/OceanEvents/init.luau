--!strict
-- Server-wide ocean events on a random schedule. The active event is published as
-- ReplicatedStorage attributes (OceanEvent, OceanEventEndsAt) for the client visuals;
-- fishing asks current() for the rarity boost and value multiplier.
-- Studio: set Workspace attribute "DevStartEvent" to an event id to start it now.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Events =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Events"))

local OceanEvents = {}
OceanEvents.order = 20

local rng = Random.new()
local active: Events.OceanEvent? = nil
local runId = 0

function OceanEvents.current(): Events.OceanEvent?
	return active
end

local function finish(id: number)
	if runId ~= id then
		return
	end
	active = nil
	ReplicatedStorage:SetAttribute(Events.ACTIVE_ATTRIBUTE, "")
	ReplicatedStorage:SetAttribute(Events.ENDS_AT_ATTRIBUTE, 0)
end

function OceanEvents.startEvent(eventId: string): boolean
	local event = Events.get(eventId)
	if not event then
		return false
	end
	runId += 1
	local id = runId
	active = event
	ReplicatedStorage:SetAttribute(Events.ACTIVE_ATTRIBUTE, event.id)
	ReplicatedStorage:SetAttribute(
		Events.ENDS_AT_ATTRIBUTE,
		Workspace:GetServerTimeNow() + event.durationSeconds
	)
	task.delay(event.durationSeconds, finish, id)
	return true
end

function OceanEvents.start()
	ReplicatedStorage:SetAttribute(Events.ACTIVE_ATTRIBUTE, "")
	ReplicatedStorage:SetAttribute(Events.ENDS_AT_ATTRIBUTE, 0)

	task.spawn(function()
		while true do
			local delay = rng:NextNumber(Events.INTERVAL_MIN, Events.INTERVAL_MAX)
			ReplicatedStorage:SetAttribute(
				Events.NEXT_AT_ATTRIBUTE,
				Workspace:GetServerTimeNow() + delay
			)
			task.wait(delay)
			if not active then
				OceanEvents.startEvent(Events.LIST[rng:NextInteger(1, #Events.LIST)].id)
			end
		end
	end)

	if RunService:IsStudio() then
		Workspace:GetAttributeChangedSignal("DevStartEvent"):Connect(function()
			local id = Workspace:GetAttribute("DevStartEvent")
			if typeof(id) == "string" and id ~= "" then
				OceanEvents.startEvent(id)
				Workspace:SetAttribute("DevStartEvent", "")
			end
		end)
	end
end

return OceanEvents
