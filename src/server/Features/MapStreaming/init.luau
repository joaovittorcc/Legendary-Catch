--!strict
-- Animated map models must reach a client whole. With StreamingEnabled a Model can arrive
-- before its parts; the animator then captured an empty pivot near the world origin and
-- dragged the parts there when they streamed in (blossoms floating in the hub plaza).

local CollectionService = game:GetService("CollectionService")

local MapStreaming = {}
MapStreaming.order = 5

local ANIMATED_TAGS = { "HubSpin", "HubBob", "HubSway", "HubWave" }

local function makeAtomic(inst: Instance)
	if inst:IsA("Model") and inst.ModelStreamingMode == Enum.ModelStreamingMode.Default then
		inst.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end
end

function MapStreaming.start()
	for _, tag in ANIMATED_TAGS do
		CollectionService:GetInstanceAddedSignal(tag):Connect(makeAtomic)
		for _, inst in CollectionService:GetTagged(tag) do
			makeAtomic(inst)
		end
	end
end

return MapStreaming
