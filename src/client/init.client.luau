--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Version"))

local Features = script:WaitForChild("Features")
local Fishing = require(Features:WaitForChild("Fishing"))

Fishing.start()

print(`[Client] booted, build {Version.BUILD}`)
