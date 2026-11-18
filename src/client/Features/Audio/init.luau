--!strict
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Creator Store publisher: Roblox. Keep provenance next to the asset IDs.
local IDs = {
	cast = 12222200, -- swoosh.wav
	bite = 12221944, -- bass.wav
	tension = 12221944,
	legendary = 10128766965, -- RBLX UI Swipe
	panel = 10066968815, -- RBLX UI Select 02
} :: { [string]: number }

local Catalog = {
	music = "Music_Island",
	water = "Ambience_Waves",
	level = "LevelUp",
	coins = "Coin",
	click = "UiClick",
	hit = "HitGood",
	miss = "HitMiss",
	chest = "Chest",
} :: { [string]: string }

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
	local sound: Sound
	local name = Catalog[cue]
	if name then
		local folder = ReplicatedStorage:FindFirstChild("Audio")
		local template = folder and folder:FindFirstChild(name)
		if not template or not template:IsA("Sound") or template.SoundId == "" then
			return nil
		end
		sound = template:Clone()
	else
		local id = IDs[cue]
		if not id then
			return nil
		end
		sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. id
	end
	sound.Name = "Adventure_" .. cue
	sound.SoundGroup = Audio.group(if cue == "music" then "Music" else "Effects")
	sound.Parent = SoundService
	sounds[cue] = sound
	return sound
end

function Audio.play(cue: string, volume: number?, speed: number?): Sound?
	local sound = get(cue)
	if not sound or not sound.IsLoaded then
		return nil
	end
	if volume then
		sound.Volume = volume
	end
	sound.PlaybackSpeed = speed or 1
	sound:Stop()
	sound:Play()
	return sound
end

local activeStinger: Sound? = nil

function Audio.capture(rarity: string, shiny: boolean)
	if activeStinger then
		activeStinger:Stop()
	end
	activeStinger = Audio.play("stinger_" .. rarity, nil, if shiny then 1.12 else 1)
end

local function loop(cue: string, volume: number?, speed: number?): Sound?
	local sound = get(cue)
	if sound then
		sound.Looped = true
		Audio.play(cue, volume, speed)
	end
	return sound
end

local function ambientLoop(cue: string, volume: number?)
	local sound = get(cue)
	if not sound then
		return
	end
	if volume then
		sound.Volume = volume
	end
	if sound.IsLoaded then
		loop(cue)
	else
		sound.Loaded:Once(function()
			loop(cue)
		end)
	end
end

function Audio.start()
	for _, rarity in Fishing.RARITY_ORDER do
		Catalog["stinger_" .. rarity] = "Stinger_" .. rarity
	end
	ambientLoop("music")
	local water = get("water")
	local waterVolume = if water then water.Volume else 0
	ambientLoop("water", 0)

	for cue in Catalog do
		get(cue)
	end
	for cue in IDs do
		get(cue)
	end
	local assets: { Instance } = {}
	for _, sound in sounds do
		table.insert(assets, sound)
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(assets)
		end)
	end)

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
				Audio.play("click")
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
			Audio.play("coins")
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
					for _, spot in CollectionService:GetTagged(tag) do
						if spot:IsA("BasePart") then
							local distance = (root.Position - spot.Position).Magnitude
							gain = math.max(gain, 1 - distance / 62)
						end
					end
				end
			end
			TweenService:Create(water, TweenInfo.new(0.45), { Volume = waterVolume * gain }):Play()
			task.wait(0.5)
		end
	end)
end

return Audio
