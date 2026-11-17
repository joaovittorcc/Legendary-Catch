--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Line = require(script.Parent:WaitForChild("Fishing"):WaitForChild("Line"))
local Fishing =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Fishing"))
local Others = {}
local localPlayer = Players.LocalPlayer

function Others.start()
	local lines: { [Player]: Line.Line } = {}
	local function remove(player: Player)
		local line = lines[player]
		if line then
			lines[player] = nil
			Line.destroy(line)
		end
	end

	Players.PlayerRemoving:Connect(remove)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.13 then
			return
		end
		elapsed = 0
		local camera = workspace.CurrentCamera
		for _, player in Players:GetPlayers() do
			if player == localPlayer then
				continue
			end
			local character = player.Character
			local state = character and character:GetAttribute("FishingState")
			local target = character and character:GetAttribute("FishingTarget")
			if
				not character
				or (state ~= "waiting" and state ~= "fighting")
				or typeof(target) ~= "Vector3"
				or not camera
				or (camera.CFrame.Position - target).Magnitude > 160
			then
				remove(player)
				continue
			end
			local tool = character:FindFirstChild("Rod")
			local tip = tool and tool:FindFirstChild("Tip")
			local attachment = tip and tip:FindFirstChild("LineAttachment")
			if not attachment or not attachment:IsA("Attachment") then
				remove(player)
				continue
			end
			local line = lines[player]
			if not line or line.tip ~= attachment then
				remove(player)
				local newLine = Line.create(attachment)
				-- The spectator line should never repaint the equipped rod.
				newLine.tipPart = nil
				lines[player] = newLine
				line = newLine
			end
			if not line then
				continue
			end
			line.rest = target
			local mode = if state == "fighting" then "fighting" else "floating"
			if mode ~= line.mode then
				line.mode = mode
				local rarity = character:GetAttribute("FishingRarity")
				local color = if mode == "fighting" and typeof(rarity) == "string"
					then Fishing.RARITY_COLORS[rarity]
					else nil
				Line.setColor(line, color or Color3.fromRGB(220, 240, 255))
			end
		end
	end)
end

return Others
