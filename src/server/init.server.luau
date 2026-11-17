--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Version"))

local Features = script:WaitForChild("Features")
local Fishing = require(Features:WaitForChild("Fishing"))
local Rod = require(Features:WaitForChild("Rod"))

-- Remotes first: the client waits on them.
Fishing.start()
Rod.start()

print(`[Server] booted, build {Version.BUILD}`)
