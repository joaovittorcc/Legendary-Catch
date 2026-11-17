--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
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
	local settingsAccent = Color3.fromRGB(174, 116, 239)
	local gui, body = Panel.create("Settings", Text.settings, settingsAccent, 0.75, 330)
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
		row.Size = UDim2.new(1, 0, 0, 76)
		row.BackgroundColor3 = Theme.cream
		row.BorderSizePixel = 0
		Theme.corner(row, 12)
		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = settingsAccent
		rowStroke.Thickness = 2
		rowStroke.Parent = row
		local label = Panel.label(row, "", 16)
		label.Size = UDim2.new(1, -24, 0, 28)
		label.Position = UDim2.fromOffset(12, 0)
		local function refresh()
			label.Text = string.format("%s  ·  %d%%", name, math.round(group.Volume * 100))
		end
		group:GetPropertyChangedSignal("Volume"):Connect(refresh)
		refresh()
		local track = Instance.new("Frame")
		track.Name = "VolumeTrack"
		track.Position = UDim2.new(0, 12, 0, 43)
		track.Size = UDim2.new(1, -24, 0, 16)
		track.BackgroundColor3 = Color3.fromRGB(223, 207, 189)
		track.BorderSizePixel = 0
		track.Active = true
		Theme.corner(track, 8)
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(group.Volume, 1)
		fill.BackgroundColor3 = settingsAccent
		fill.BorderSizePixel = 0
		Theme.corner(fill, 8)
		fill.Parent = track
		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Position = UDim2.new(group.Volume, 0, 0.5, 0)
		knob.Size = UDim2.fromOffset(30, 30)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		Theme.corner(knob, 15)
		local knobStroke = Instance.new("UIStroke")
		knobStroke.Color = Theme.outline
		knobStroke.Thickness = 3
		knobStroke.Parent = knob
		knob.Parent = track
		track.Parent = row
		local dragging = false
		local inputConnections: { RBXScriptConnection } = {}
		local function setFromX(x: number)
			local value =
				math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			group.Volume = math.round(value * 20) / 20
			fill.Size = UDim2.fromScale(group.Volume, 1)
			knob.Position = UDim2.new(group.Volume, 0, 0.5, 0)
			changed()
		end
		table.insert(
			inputConnections,
			track.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragging = true
					setFromX(input.Position.X)
				end
			end)
		)
		table.insert(
			inputConnections,
			UserInputService.InputChanged:Connect(function(input)
				if
					dragging
					and (
						input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch
					)
				then
					setFromX(input.Position.X)
				end
			end)
		)
		table.insert(
			inputConnections,
			UserInputService.InputEnded:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragging = false
				end
			end)
		)
		row.Destroying:Once(function()
			for _, connection in inputConnections do
				connection:Disconnect()
			end
		end)
		row.Parent = body
	end
	volume(Text.music, music)
	volume(Text.effects, effects)
	local reduced = Panel.button(body, "", settingsAccent)
	reduced.Size = UDim2.new(1, 0, 0, 52)
	local function setToggleColor()
		local active = player:GetAttribute("ReduceEffects") == true
		local tint = if active then Color3.fromRGB(88, 193, 112) else Color3.fromRGB(173, 163, 174)
		Panel.tintButton(reduced, tint)
	end
	local function refresh()
		reduced.Text = Text.reduced
			.. "  ·  "
			.. (
				if player:GetAttribute("ReduceEffects") == true
					then "●  " .. Text.on
					else "○  " .. Text.off
			)
		setToggleColor()
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
