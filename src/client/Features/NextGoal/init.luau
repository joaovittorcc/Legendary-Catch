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
local Panel = require(script.Parent.Hud:WaitForChild("Panel"))

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
				text = if missing > 0
					then string.format(Text.rod, missing, name)
					else string.format(Text.rodReady, name),
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
				local message = if missing <= 0
					then Text.milestoneReady
					elseif rarity then string.format(
						Text.speciesRarity,
						missing,
						Strings.rarity[rarity] or rarity
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

	local chip = Instance.new("TextButton")
	chip.Name = "NextGoal"
	chip.Text = ""
	chip.Visible = false
	chip.AnchorPoint = Vector2.new(0.5, 0)
	chip.Size = UDim2.new(0.72, 0, 0, 46)
	Theme.surface(chip, Theme.crystal, 10, Theme.ink)
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(278, 46)
	bounds.Parent = chip

	local heading = Panel.label(chip, Text.title, 11, Theme.crystal)
	heading.Name = "Heading"
	heading.Size = UDim2.new(1, 0, 0, 13)
	heading.Position = UDim2.fromOffset(0, 3)
	local message = Panel.label(chip, "", 14)
	message.Name = "Objective"
	message.Size = UDim2.new(1, -12, 0, 18)
	message.Position = UDim2.fromOffset(6, 16)
	message.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 14
	limit.Parent = message

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -24, 0, 4)
	track.Position = UDim2.fromOffset(12, 37)
	track.BackgroundColor3 = Color3.fromRGB(57, 61, 86)
	track.BorderSizePixel = 0
	Theme.corner(track, 2)
	track.Parent = chip
	local fill = Instance.new("Frame")
	fill.Name = "Progress"
	fill.BackgroundColor3 = Theme.crystal
	fill.BorderSizePixel = 0
	Theme.corner(fill, 2)
	fill.Parent = track

	local function place()
		chip.Position =
			UDim2.new(0.5, 0, navigation.Position.Y.Scale, navigation.AbsoluteSize.Y + 8)
	end
	navigation:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
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
