--!strict
-- How much easier the minigames get (1 = no help): Control training times the equipped
-- rod's controlBonus. Read when a minigame starts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Rods = require(Config:WaitForChild("Rods"))
local TrainingConfig = require(Config:WaitForChild("Training"))

local Control = {}

function Control.ease(): number
	local player = Players.LocalPlayer
	local level = player:GetAttribute(TrainingConfig.levelAttribute("Control"))
	local lvl = if typeof(level) == "number" then level else 0
	if TrainingConfig.powerEnabled() then
		-- Fishing Power v2: continuous level from power (same curve the server uses).
		lvl = TrainingConfig.equivalentLevel(
			TrainingConfig.clampPower(player:GetAttribute(TrainingConfig.powerAttribute("Control")))
		)
	end
	local rodId = player:GetAttribute("EquippedRod")
	local rod = if typeof(rodId) == "string" then Rods.get(rodId) else nil
	local training = TrainingConfig.controlEase(lvl)
	return training * (1 + (if rod then rod.controlBonus else 0))
end

return Control
