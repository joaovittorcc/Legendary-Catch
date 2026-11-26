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
	mystic = "🌟",
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
	indent: number,
	color: Color3?,
	minSize: number?
): TextLabel
	local label = Panel.label(parent, content, size, color)
	label.Name = name
	label.Position = UDim2.fromOffset(indent, y)
	label.Size = UDim2.new(1, -indent - 10, 0, height)
	label.TextScaled = true
	label.TextWrapped = true
	local cap = Instance.new("UITextSizeConstraint")
	cap.MinTextSize = minSize or 14
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
	local frame = Panel.card(grid, Theme.gold, 118)
	frame.Name = achievement.id
	frame.LayoutOrder = order

	local icon = Panel.label(frame, Icons[achievement.metric] or "🏅", 24)
	icon.Name = "Icon"
	icon.Position = UDim2.fromOffset(10, 10)
	icon.Size = UDim2.fromOffset(42, 42)
	icon.BackgroundTransparency = 0
	icon.BackgroundColor3 = Color3.fromRGB(224, 242, 255)
	icon.TextStrokeTransparency = 1
	Theme.corner(icon, 14)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Theme.outline
	iconStroke.Thickness = 2.5
	iconStroke.Parent = icon

	leftLabel(
		frame,
		"Title",
		if copy then copy.name else achievement.id,
		17,
		6,
		26,
		58,
		Theme.ink,
		14
	)
	leftLabel(
		frame,
		"Description",
		if copy then copy.description else "",
		15,
		32,
		38,
		58,
		Color3.fromRGB(74, 44, 34),
		14
	)
	local badge = leftLabel(frame, "Status", "", 15, 72, 22, 12, Theme.ink, 14)
	badge.Size = UDim2.new(0.56, -12, 0, 22)
	local reward = Panel.label(
		frame,
		string.format("+%d ◆", achievement.reward),
		15,
		Color3.fromRGB(134, 66, 12)
	)
	reward.Name = "Reward"
	reward.Position = UDim2.new(1, -94, 0, 72)
	reward.Size = UDim2.fromOffset(82, 22)
	reward.TextXAlignment = Enum.TextXAlignment.Right
	reward.TextStrokeTransparency = 1

	local track, fill = Panel.progressBar(frame, "gold", 12)
	track.Name = "Progress"
	track.Position = UDim2.fromOffset(12, 96)
	track.Size = UDim2.new(1, -24, 0, 12)

	return function(value: number, unlocked: boolean)
		local progress = if unlocked
			then achievement.target
			else math.min(value, achievement.target)
		badge.Text = if unlocked
			then "✓ " .. Text.achievementUi.unlocked
			else string.format("%d / %d", progress, achievement.target)
		badge.TextColor3 = if unlocked then Color3.fromRGB(18, 108, 62) else Theme.ink
		icon.BackgroundColor3 = if unlocked then Theme.gold else Color3.fromRGB(224, 242, 255)
		fill.Size = UDim2.fromScale(progress / achievement.target, 1)
		Panel.setCardState(frame, if unlocked then "selected" else "normal", Theme.gold)
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
		local columns = if width >= 640 then 3 elseif width >= 420 then 2 else 1
		local rows = math.ceil(#cards / columns)
		layout.FillDirectionMaxCells = columns
		layout.CellSize = UDim2.fromOffset(math.floor((width - 10 * (columns - 1)) / columns), 118)
		grid.Size = UDim2.new(1, -8, 0, 128 * rows - 10)
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
