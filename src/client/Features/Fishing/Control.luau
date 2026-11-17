--!strict
-- How much the player's Control training eases the minigames (1 = no help).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrainingConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Training")
)

local Control = {}

function Control.ease(): number
	local value = Players.LocalPlayer:GetAttribute(TrainingConfig.levelAttribute("Control"))
	return TrainingConfig.controlEase(if typeof(value) == "number" then value else 0)
end

return Control
