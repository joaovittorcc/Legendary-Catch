--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Version"))

local Features = script:WaitForChild("Features")
local Fishing = require(Features:WaitForChild("Fishing"))
local Training = require(Features:WaitForChild("Training"))

-- Fishing first: it creates the shared HUD that training reuses.
Fishing.start()
Training.start()

print(`[Client] booted, build {Version.BUILD}`)
