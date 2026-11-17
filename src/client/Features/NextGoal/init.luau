--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Creatures = require(Config:WaitForChild("Creatures"))
local Milestones = require(Config:WaitForChild("Milestones"))
local Missions = require(Config:WaitForChild("Missions"))
local Rods = require(Config:WaitForChild("Rods"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi")).nextGoal
local Theme = require(Shared:WaitForChild("UiTheme"))
local Types = require(Shared:WaitForChild("Types"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Assets = require(script.Parent.Hud:WaitForChild("Assets"))
local Motion = require(script.Parent.Hud:WaitForChild("Motion"))

local NextGoal = { order = 125 }
local player = Players.LocalPlayer

type Goal = { panel: string, text: string, progress: number }

local function nextGoal(snapshot: Types.Snapshot): Goal?
	for _, rod in Rods.LIST do
		if rod.price > 0 and not table.find(snapshot.rodsOwned, rod.id) then
			local name = Strings.rodName[rod.id] or rod.id
			local missing = rod.price - snapshot.coins
			return {
				panel = "Shop",
				text = if missing <= 0
					then string.format(Text.rodReady, name)
					elseif missing == 1 then string.format(Text.rodSingle, name)
					else string.format(Text.rod, missing, name),
				progress = math.clamp(snapshot.coins / rod.price, 0, 1),
			}
		end
	end

	if snapshot.milestones then
		for _, milestone in Milestones.LIST do
			if snapshot.milestones[milestone.id] then
				continue
			end
			local rarity = milestone.rarity
			local target = if rarity then 0 else milestone.count
			local found = 0
			for _, creature in Creatures.LIST do
				if not rarity or creature.rarity == rarity then
					if rarity then
						target += 1
					end
					if snapshot.collection[creature.id] then
						found += 1
					end
				end
			end
			if target > 0 then
				local missing = target - found
				local rarityName = if rarity then Strings.rarity[rarity] or rarity else nil
				local message = if missing <= 0
					then Text.milestoneReady
					elseif missing == 1 then (if rarityName
						then string.format(Text.speciesRaritySingle, rarityName)
						else Text.speciesSingle)
					elseif rarityName then string.format(
						Text.speciesRarity,
						missing,
						rarityName
					)
					else string.format(Text.species, missing)
				return {
					panel = "Milestones",
					text = message,
					progress = math.min(found / target, 1),
				}
			end
		end
	end

	local missions = snapshot.missions
	if missions and missions.day == Missions.today() then
		for _, mission in missions.list do
			if not mission.claimed and mission.progress >= mission.target then
				return { panel = "Missions", text = Text.missionReady, progress = 1 }
			end
		end
	end
	return nil
end

function NextGoal.start()
	local playerGui = player:WaitForChild("PlayerGui")
	local hud = playerGui:WaitForChild("AdventureHud")
	local navigation = hud:WaitForChild("Navigation") :: Frame
	local fishing = playerGui:WaitForChild("FishingUI")
	local minigame = fishing:WaitForChild("Panel") :: Frame
	local announcements = playerGui:WaitForChild("CatchAnnouncements")

	local chip = Art.button(Assets.goal)
	chip.Name = "NextGoal"
	chip.Visible = false
	chip.AnchorPoint = Vector2.new(0.5, 0)
	chip.Size = UDim2.new(0.55, 0, 0, 52)
	Motion.mount(chip, 0, 8.6)
	local heading = Art.caption(chip, "Heading", Text.title, 26, Theme.gold)
	heading.Position = UDim2.fromScale(0.32, 0.105)
	heading.Size = UDim2.fromScale(0.62, 0.29)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	local message = Art.caption(chip, "Objective", "", 23)
	message.Position = UDim2.fromScale(0.32, 0.4)
	message.Size = UDim2.fromScale(0.62, 0.29)
	message.TextXAlignment = Enum.TextXAlignment.Left

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.fromScale(0.32, 0.74)
	track.Size = UDim2.fromScale(0.61, 0.15)
	track.BackgroundColor3 = Color3.fromRGB(66, 34, 121)
	track.BorderSizePixel = 0
	Theme.corner(track, 5)
	track.Parent = chip
	local fill = Instance.new("Frame")
	fill.Name = "Progress"
	fill.BackgroundColor3 = Color3.fromRGB(246, 169, 43)
	fill.BorderSizePixel = 0
	fill.ZIndex = track.ZIndex + 1
	Theme.corner(fill, 5)
	fill.Parent = track
	local golden = Art.image(fill, Assets.progress)
	golden.ZIndex = fill.ZIndex + 1

	local function place()
		local width = hud.AbsoluteSize.X
		local height = math.clamp(math.round(hud.AbsoluteSize.Y * 0.108), 50, 88)
		chip.Size = UDim2.fromOffset(math.round(math.min(width * 0.82, height * 4.5)), height)
		chip.Position =
			UDim2.new(0.5, 0, 0, navigation.Position.Y.Offset + navigation.Size.Y.Offset + 7)
	end
	Hud.layoutChanged:Connect(place)
	place()
	chip.Parent = hud

	local goal: Goal? = nil
	local function refreshVisibility()
		local training = player:GetAttribute("TrainingStat")
		chip.Visible = goal ~= nil
			and Hud.panel() == ""
			and not minigame.Visible
			and player:GetAttribute("CatchRevealActive") ~= true
			and not (typeof(training) == "string" and training ~= "")
			and announcements:FindFirstChild("CatchBanner") == nil
	end
	local function refresh(snapshot: Types.Snapshot?)
		goal = if snapshot
				and snapshot.tutorial
				and snapshot.tutorial.done
			then nextGoal(snapshot)
			else nil
		local current = goal
		if current then
			message.Text = current.text
			fill.Size = UDim2.fromScale(current.progress, 1)
			fill.Visible = current.progress > 0
		end
		refreshVisibility()
	end
	chip.Activated:Connect(function()
		local current = goal
		if current and chip.Visible then
			Hud.showPanel(current.panel)
		end
	end)
	Data.changed:Connect(refresh)
	Hud.panelChanged:Connect(refreshVisibility)
	minigame:GetPropertyChangedSignal("Visible"):Connect(refreshVisibility)
	player:GetAttributeChangedSignal("CatchRevealActive"):Connect(refreshVisibility)
	player:GetAttributeChangedSignal("TrainingStat"):Connect(refreshVisibility)
	announcements.ChildAdded:Connect(refreshVisibility)
	announcements.ChildRemoved:Connect(refreshVisibility)
	refresh(Data.get())
end

return NextGoal
