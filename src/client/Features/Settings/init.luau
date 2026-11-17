--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Settings = {}
local player = Players.LocalPlayer

local function soundGroup(name: string): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Parent = SoundService
	return group
end

function Settings.start()
	local gui, body = Panel.create("Settings", Text.settings, Theme.rose)
	Panel.stack(body)
	local music = soundGroup("Music")
	local effects = soundGroup("Effects")
	local function route(sound: Instance)
		if sound:IsA("Sound") and not sound.SoundGroup then
			sound.SoundGroup = if sound:GetAttribute("AudioCategory") == "Music"
					or string.find(string.lower(sound.Name), "music", 1, true)
				then music
				else effects
		end
	end
	game.DescendantAdded:Connect(route)
	for _, container in { SoundService, workspace, player:WaitForChild("PlayerGui") } do
		for _, sound in container:GetDescendants() do
			route(sound)
		end
	end

	local function volume(name: string, group: SoundGroup)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 50)
		row.BackgroundTransparency = 1
		local label = Panel.label(row, "", 19)
		label.Size = UDim2.fromScale(0.62, 1)
		local function refresh()
			label.Text = string.format("%s  ·  %d%%", name, math.round(group.Volume * 100))
		end
		refresh()
		for i, delta in { -0.1, 0.1 } do
			local button = Panel.button(row, if delta < 0 then "−" else "+", Theme.rose)
			button.Position = UDim2.fromScale(0.64 + (i - 1) * 0.18, 0)
			button.Size = UDim2.fromOffset(46, 46)
			button.Activated:Connect(function()
				group.Volume = math.clamp(math.round((group.Volume + delta) * 10) / 10, 0, 1)
				refresh()
			end)
		end
		row.Parent = body
	end
	volume(Text.music, music)
	volume(Text.effects, effects)
	local reduced = Panel.button(body, "", Theme.crystal)
	local function refresh()
		reduced.Text = Text.reduced
			.. "  ·  "
			.. (if player:GetAttribute("ReduceEffects") == true then Text.on else Text.off)
	end
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(refresh)
	reduced.Activated:Connect(function()
		player:SetAttribute("ReduceEffects", player:GetAttribute("ReduceEffects") ~= true)
	end)
	refresh()
	Hud.panelChanged:Connect(function(name: string)
		gui.Enabled = name == "Settings"
	end)
end

return Settings
