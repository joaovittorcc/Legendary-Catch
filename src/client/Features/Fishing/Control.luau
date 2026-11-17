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
	local rodId = player:GetAttribute("EquippedRod")
	local rod = if typeof(rodId) == "string" then Rods.get(rodId) else nil
	local training = TrainingConfig.controlEase(if typeof(level) == "number" then level else 0)
	return training * (1 + (if rod then rod.controlBonus else 0))
end

return Control
