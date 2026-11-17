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
local Wood = require(script.Parent.Hud:WaitForChild("Wood"))

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

	local chip = Instance.new("TextButton")
	chip.Name = "NextGoal"
	chip.Text = ""
	chip.Visible = false
	chip.AnchorPoint = Vector2.new(0.5, 0)
	chip.Size = UDim2.new(0.55, 0, 0, 52)
	Wood.mount(chip, true, Color3.fromRGB(40, 76, 69))
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(1000, 110)
	bounds.Parent = chip

	local icons = {
		Shop = Wood.icon(chip, "Rod", 34),
		Milestones = Wood.icon(chip, "Collection", 34),
		Missions = Wood.icon(chip, "Missions", 34),
	} :: { [string]: Frame }
	for _, icon in icons do
		icon.Position = UDim2.fromOffset(13, 8)
		icon.Visible = false
	end
	local heading = Wood.caption(chip, "Heading", Text.title, 28, Theme.gold)
	heading.Size = UDim2.new(1, -68, 0, 15)
	heading.Position = UDim2.fromOffset(54, 4)
	heading.TextXAlignment = Enum.TextXAlignment.Left
	local message = Wood.caption(chip, "Objective", "", 25)
	message.Size = UDim2.new(1, -68, 0, 17)
	message.Position = UDim2.fromOffset(54, 19)
	message.TextXAlignment = Enum.TextXAlignment.Left

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -69, 0, 6)
	track.Position = UDim2.fromOffset(54, 39)
	track.BackgroundColor3 = Color3.fromRGB(41, 27, 17)
	track.BorderSizePixel = 0
	Theme.corner(track, 2)
	track.Parent = chip
	local fill = Instance.new("Frame")
	fill.Name = "Progress"
	fill.BackgroundColor3 = Theme.gold
	fill.BorderSizePixel = 0
	Theme.corner(fill, 2)
	local sheen = Instance.new("UIGradient")
	sheen.Rotation = 90
	sheen.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(203, 140, 43))
	sheen.Parent = fill
	fill.Parent = track

	local function place()
		local width = hud.AbsoluteSize.X
		local height = math.clamp(math.round(hud.AbsoluteSize.Y * 0.102), 46, 110)
		local wide = width > 1000
		chip.Size = UDim2.new(if width < 520 then 0.81 else 0.55, 0, 0, height)
		local iconSize = math.round(height * 0.83)
		local left = iconSize + 18
		for _, icon in icons do
			icon.Size = UDim2.fromOffset(iconSize, iconSize)
			icon.Position = UDim2.fromOffset(10, (height - iconSize) / 2)
		end
		heading.Position = UDim2.new(0, left, 0.08, 0)
		heading.Size = UDim2.new(if wide then 0.47 else 1, -left - 10, 0.35, 0)
		message.Position = UDim2.new(0, left, 0.42, 0)
		message.Size = UDim2.new(if wide then 0.49 else 1, -left - 10, 0.33, 0)
		track.Position = if wide then UDim2.fromScale(0.50, 0.49) else UDim2.new(0, left, 0.81, 0)
		track.Size = if wide then UDim2.fromScale(0.46, 0.21) else UDim2.new(1, -left - 14, 0.12, 0)
		chip.Position = UDim2.new(
			0.5,
			0,
			navigation.Position.Y.Scale,
			navigation.Position.Y.Offset + navigation.AbsoluteSize.Y + 7
		)
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
			for panel, icon in icons do
				icon.Visible = panel == current.panel
			end
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
