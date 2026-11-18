--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Achievements = require(Config:WaitForChild("Achievements"))
local Creatures = require(Config:WaitForChild("Creatures"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Types = require(Shared:WaitForChild("Types"))
local Panel = require(script.Parent.Hud:WaitForChild("Panel"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))

local Screen = {}
local Icons: { [string]: string } = {
	catches = "🎣",
	species = "📖",
	legendaries = "⭐",
	mystic = "✺",
	level = "⚓",
	combo = "⚡",
	training = "💪",
}

local function metrics(snapshot: Types.Snapshot): { [string]: number }
	local species, mystic, training = 0, 0, 0
	for id in snapshot.collection do
		species += 1
		local creature = Creatures.get(id)
		if creature and creature.rarity == "Mystic" then
			mystic += 1
		end
	end
	for _, stat in snapshot.training do
		training = math.max(training, stat.level)
	end
	return {
		catches = snapshot.stats.catches,
		species = species,
		legendaries = snapshot.stats.legendaries,
		mystic = mystic,
		level = snapshot.stats.level,
		combo = snapshot.stats.bestCombo,
		training = training,
	}
end

local function leftLabel(
	parent: Frame,
	name: string,
	content: string,
	size: number,
	y: number,
	height: number,
	indent: number
): TextLabel
	local label = Panel.label(parent, content, size)
	label.Name = name
	label.Position = UDim2.fromOffset(indent, y)
	label.Size = UDim2.new(1, -indent - 10, 0, height)
	label.TextScaled = true
	label.TextWrapped = true
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = size
	cap.Parent = label
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextStrokeTransparency = 1
	return label
end

local function card(
	grid: Frame,
	achievement: Achievements.Achievement,
	order: number
): (number, boolean) -> ()
	local copy = Text.achievements[achievement.id]
	local frame = Instance.new("Frame")
	frame.Name = achievement.id
	frame.LayoutOrder = order
	Theme.surface(frame, Theme.crystal, 12, Color3.fromRGB(250, 243, 227))
	local stroke = frame:FindFirstChildOfClass("UIStroke")

	local icon = Panel.label(frame, Icons[achievement.metric] or "🏅", 22)
	icon.Name = "Icon"
	icon.Position = UDim2.fromOffset(8, 8)
	icon.Size = UDim2.fromOffset(34, 34)
	icon.BackgroundTransparency = 0
	icon.BackgroundColor3 = Color3.fromRGB(220, 239, 249)
	icon.TextStrokeTransparency = 1
	Theme.corner(icon, 11)

	leftLabel(frame, "Title", if copy then copy.name else achievement.id, 16, 4, 26, 48)
	leftLabel(frame, "Description", if copy then copy.description else "", 14, 29, 28, 48)
	local badge = leftLabel(frame, "Status", "", 14, 58, 19, 10)
	local reward = Panel.label(frame, string.format("+%d ◆", achievement.reward), 14, Theme.wood)
	reward.Name = "Reward"
	reward.Position = UDim2.new(1, -85, 0, 58)
	reward.Size = UDim2.fromOffset(75, 19)
	reward.TextXAlignment = Enum.TextXAlignment.Right
	reward.TextStrokeTransparency = 1

	local track = Instance.new("Frame")
	track.Name = "Progress"
	track.BackgroundColor3 = Color3.fromRGB(211, 199, 194)
	track.BorderSizePixel = 0
	track.Position = UDim2.fromOffset(10, 83)
	track.Size = UDim2.new(1, -20, 0, 6)
	Theme.corner(track, 3)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	Theme.corner(fill, 3)
	fill.Parent = track
	track.Parent = frame
	frame.Parent = grid

	return function(value: number, unlocked: boolean)
		local progress = if unlocked
			then achievement.target
			else math.min(value, achievement.target)
		local color = if unlocked then Theme.gold else Theme.track
		badge.Text = if unlocked
			then "✓ " .. Text.achievementUi.unlocked
			else string.format("%d / %d", progress, achievement.target)
		icon.BackgroundColor3 = if unlocked then Theme.gold else Color3.fromRGB(220, 239, 249)
		fill.BackgroundColor3 = color
		fill.Size = UDim2.fromScale(progress / achievement.target, 1)
		if stroke then
			stroke.Color = if unlocked then Theme.wood else Color3.fromRGB(182, 160, 153)
		end
	end
end

function Screen.start()
	local gui, body = Panel.create("Achievements", Text.achievementUi.title, Theme.gold)
	Panel.stack(body)
	local summary = Panel.label(body, Text.loading, 17)
	summary.Name = "Summary"
	summary.Size = UDim2.new(1, 0, 0, 24)
	summary.TextStrokeTransparency = 1
	local grid = Instance.new("Frame")
	grid.Name = "Cards"
	grid.LayoutOrder = 1
	grid.BackgroundTransparency = 1
	local layout = Instance.new("UIGridLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.CellPadding = UDim2.fromOffset(10, 10)
	layout.Parent = grid
	grid.Parent = body

	local cards: { (number, boolean) -> () } = {}
	for order, achievement in Achievements.LIST do
		cards[order] = card(grid, achievement, order)
		cards[order](0, false)
	end

	local function fit()
		local width = math.max(1, body.AbsoluteWindowSize.X - 8)
		local columns = if width >= 580 then 3 elseif width >= 400 then 2 else 1
		local rows = math.ceil(#cards / columns)
		layout.FillDirectionMaxCells = columns
		layout.CellSize = UDim2.fromOffset(math.floor((width - 10 * (columns - 1)) / columns), 98)
		grid.Size = UDim2.new(1, -8, 0, 108 * rows - 10)
	end
	body:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(fit)
	fit()

	local function refresh(snapshot: Types.Snapshot?)
		if not gui.Enabled or not snapshot then
			return
		end
		local values = metrics(snapshot)
		local unlockedCount = 0
		for index, achievement in Achievements.LIST do
			local unlocked = snapshot.achievements ~= nil
				and snapshot.achievements[achievement.id] ~= nil
			cards[index](values[achievement.metric] or 0, unlocked)
			if unlocked then
				unlockedCount += 1
			end
		end
		summary.Text = string.format(Text.achievementUi.summary, unlockedCount, #cards)
	end
	Data.changed:Connect(refresh)
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		refresh(Data.get())
	end)
end

return Screen
