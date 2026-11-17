--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Creator Store publisher: Roblox. Keep provenance next to the asset IDs.
local IDs = {
	cast = 12222200, -- swoosh.wav
	bite = 12221944, -- bass.wav
	tension = 12221944,
	hit = 12221990, -- electronicpingshort.wav
	miss = 10066914500, -- RBLX UI Back
	capture = 12221990,
	legendary = 10128766965, -- RBLX UI Swipe
	click = 10128760939, -- RBLX UI Select 01
	panel = 10066968815, -- RBLX UI Select 02
	coins = 10066947742, -- RBLX UI Purchase
	level = 12221990,
	water = 365551014, -- BathRunning
	music = 130053244401794, -- TutorialMusic_01
} :: { [string]: number }

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Fishing = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Audio = { order = 15 }
local sounds: { [string]: Sound } = {}
local player = Players.LocalPlayer

function Audio.group(name: string): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Volume = if name == "Music" then 0.5 else 0.7
	group.Parent = SoundService
	return group
end

local function get(cue: string): Sound?
	local existing = sounds[cue]
	if existing then
		return existing
	end
	local id = IDs[cue]
	if not id then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = "Adventure_" .. cue
	sound.SoundId = "rbxassetid://" .. id
	sound.SoundGroup = Audio.group(if cue == "music" then "Music" else "Effects")
	sound.Parent = SoundService
	sounds[cue] = sound
	return sound
end

function Audio.play(cue: string, volume: number, speed: number?): Sound?
	local sound = get(cue)
	if sound then
		sound.Volume = volume
		sound.PlaybackSpeed = speed or 1
		sound:Stop()
		sound:Play()
	end
	return sound
end

function Audio.capture(rarity: string, shiny: boolean)
	local rank = table.find(Fishing.RARITY_ORDER, rarity) or 1
	local pitch = 0.87 + rank * 0.085 + (if shiny then 0.18 else 0)
	Audio.play("capture", 0.17 + rank * 0.035, pitch)
	if rank >= 4 then
		task.delay(0.13, function()
			Audio.play("level", 0.19, pitch * 1.25)
		end)
	end
end

local function loop(cue: string, volume: number, speed: number): Sound?
	local sound = get(cue)
	if sound then
		sound.Looped = true
		Audio.play(cue, volume, speed)
	end
	return sound
end

function Audio.start()
	loop("music", 0.19, 1)
	local water = loop("water", 0, 0.85)
	local tension = get("tension")
	local tensionFade: Tween? = nil
	local function stopTension()
		if tensionFade then
			tensionFade:Cancel()
			tensionFade = nil
		end
		if tension then
			tension:Stop()
		end
	end

	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local updates = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent
	updates.OnClientEvent:Connect(function(update: Net.FishingUpdate)
		if update.event == "cast" then
			stopTension()
			Audio.play("cast", 0.27, 1.2)
		elseif update.event == "bite" then
			Audio.play("bite", 0.23, 1.19)
			if tension then
				loop("tension", 0.02, 0.55)
				local crescendo = TweenService:Create(
					tension,
					TweenInfo.new(9),
					{ Volume = 0.09, PlaybackSpeed = 0.7 }
				)
				tensionFade = crescendo
				crescendo:Play()
			end
		else
			stopTension()
		end
	end)
	player.CharacterRemoving:Connect(stopTension)

	local training = remotes:WaitForChild(Net.TRAINING_UPDATE) :: RemoteEvent
	training.OnClientEvent:Connect(function(update: Net.TrainingUpdate)
		if update.event == "levelUp" then
			Audio.play("level", 0.29, 1.2)
		end
	end)

	local gui = player:WaitForChild("PlayerGui")
	local function watchButton(obj: Instance)
		if obj:IsA("GuiButton") then
			obj.Activated:Connect(function()
				Audio.play("click", 0.11)
			end)
		end
	end
	gui.DescendantAdded:Connect(watchButton)
	for _, obj in gui:GetDescendants() do
		watchButton(obj)
	end
	Hud.panelChanged:Connect(function(name: string)
		if name ~= "" then
			Audio.play("panel", 0.15)
		end
	end)

	local last = player:GetAttribute("Coins")
	player:GetAttributeChangedSignal("Coins"):Connect(function()
		local amount = player:GetAttribute("Coins")
		if typeof(last) == "number" and typeof(amount) == "number" and amount > last then
			Audio.play("coins", 0.13, 1.14)
		end
		last = amount
	end)

	task.spawn(function()
		while water and water.Parent do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local gain = 0
			if root and root:IsA("BasePart") then
				for _, tag in { "FishingZone", "TrainingSpot" } do
					local spot = CollectionService:GetTagged(tag)[1]
					if spot and spot:IsA("BasePart") then
						local distance = (root.Position - spot.Position).Magnitude
						gain = math.max(gain, 1 - distance / 62)
					end
				end
			end
			TweenService:Create(water, TweenInfo.new(0.45), { Volume = 0.14 * gain }):Play()
			task.wait(0.5)
		end
	end)
end

return Audio
