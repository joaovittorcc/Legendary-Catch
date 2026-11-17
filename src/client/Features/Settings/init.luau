--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("Types"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))

local Settings = {}
local player = Players.LocalPlayer

function Settings.start()
	local gui, body = Panel.create("Settings", Text.settings, Theme.rose, 0.75, 242)
	Panel.stack(body)
	local music = Audio.group("Music")
	local effects = Audio.group("Effects")
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local revision = 0
	local desired: Types.Settings? = nil
	local function send()
		local remote = remotes:FindFirstChild(Net.SAVE_SETTINGS)
		if remote and remote:IsA("RemoteEvent") and desired then
			remote:FireServer(desired)
		end
	end
	local function changed()
		revision += 1
		local token = revision
		desired = {
			music = music.Volume,
			sfx = effects.Volume,
			reduceEffects = player:GetAttribute("ReduceEffects") == true,
		}
		task.delay(0.45, function()
			if revision == token then
				send()
			end
		end)
	end

	local function volume(name: string, group: SoundGroup)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 48)
		row.BackgroundTransparency = 1
		local label = Panel.label(row, "", 16)
		label.Size = UDim2.new(1, -108, 1, 0)
		local function refresh()
			label.Text = string.format("%s  ·  %d%%", name, math.round(group.Volume * 100))
		end
		group:GetPropertyChangedSignal("Volume"):Connect(refresh)
		refresh()
		for i, delta in { -0.1, 0.1 } do
			local button = Panel.button(row, if delta < 0 then "−" else "+", Theme.rose)
			button.Position = UDim2.new(1, -100 + (i - 1) * 50, 0, 1)
			button.Size = UDim2.fromOffset(46, 46)
			button.Activated:Connect(function()
				group.Volume = math.clamp(math.round((group.Volume + delta) * 10) / 10, 0, 1)
				changed()
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
		changed()
	end)
	refresh()

	local function applySnapshot()
		local snapshot = Data.get()
		local remoteSettings = snapshot and snapshot.settings
		if not remoteSettings then
			return
		end
		local pending = desired
		if pending then
			if
				math.abs(pending.music - remoteSettings.music) > 0.001
				or math.abs(pending.sfx - remoteSettings.sfx) > 0.001
				or pending.reduceEffects ~= remoteSettings.reduceEffects
			then
				return
			end
			desired = nil
		end
		music.Volume = remoteSettings.music
		effects.Volume = remoteSettings.sfx
		player:SetAttribute("ReduceEffects", remoteSettings.reduceEffects)
	end
	Data.changed:Connect(applySnapshot)
	remotes.ChildAdded:Connect(function(child)
		if child.Name == Net.SAVE_SETTINGS then
			send()
		end
	end)
	applySnapshot()
	Hud.panelChanged:Connect(function(name: string)
		gui.Enabled = name == "Settings"
	end)
end

return Settings
