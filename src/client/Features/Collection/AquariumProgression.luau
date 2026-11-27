--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config.Aquarium)
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Panel = require(script.Parent.Parent.Hud.Panel)
local View = require(script.Parent.AquariumView)
local Tank = require(script.Parent.AquariumTank)
local Candy = require(script.Parent.AquariumCandy)

local Copy = Text.aquariumProgression
local Tabs = Text.aquariumTabs
local Progression = {}

export type Goal = {
	id: string?,
	claimed: boolean?,
	canClaim: boolean?,
	title: string,
	progress: number,
	target: number,
	progressText: string,
	reward: string,
}

export type Expansion = {
	capacity: number,
	cost: number,
	id: string?,
	version: number?,
	canBuy: boolean?,
	requirement: string?,
	reason: string?,
}
export type State = {
	capacity: number,
	levelId: string?,
	nextExpansion: Expansion?,
	coins: number,
	rate: number,
	goals: { Goal },
	previousSessionCoins: number?,
}

local function label(parent: Instance, content: string, size: number): TextLabel
	local text = Panel.label(parent, content, size)
	text.TextColor3 = Candy.ink
	text.TextStrokeTransparency = 1
	return text
end

local function addGoal(parent: Instance, goal: Goal, claim: (() -> ())?)
	local tone = if goal.claimed
		then Candy.cyan
		elseif goal.canClaim then Candy.gold
		else Candy.pearl
	local card = Candy.card(parent, tone, 100)
	local function line(content: string, size: number, y: number, height: number)
		local text = label(card, content, size)
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.Size = UDim2.new(0.62, -12, 0, height)
		text.Position = UDim2.fromOffset(12, y)
		text.TextScaled = true
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize = 11
		limit.MaxTextSize = size
		limit.Parent = text
	end
	line(goal.title, 16, 5, 38)
	line(goal.progressText, 14, 46, 24)
	local reward = label(card, goal.reward, 13)
	reward.Size = UDim2.new(0.36, -6, 0, 28)
	reward.Position = UDim2.new(0.64, 0, 0, 9)
	local action = View.button(
		card,
		"Claim_" .. (goal.id or ""),
		if goal.claimed then Copy.claimed elseif goal.canClaim then Copy.claim else Tabs.progress,
		if goal.claimed then Candy.cyan elseif goal.canClaim then Candy.gold else Candy.muted,
		claim
	)
	action.TextSize = 14
	action.Size = UDim2.new(0.36, -6, 0, 44)
	action.Position = UDim2.new(0.64, 0, 0, 42)

	local track = Instance.new("Frame")
	track.Name = "GoalProgress"
	track.Size = UDim2.new(0.58, -12, 0, 9)
	track.Position = UDim2.new(0, 12, 1, -24)
	track.BackgroundColor3 = Candy.ink
	track.BorderSizePixel = 0
	Theme.corner(track, 4)
	local progress = Instance.new("Frame")
	progress.Size = UDim2.fromScale(math.clamp(goal.progress / math.max(1, goal.target), 0, 1), 1)
	progress.BackgroundColor3 = Candy.cyan
	progress.BorderSizePixel = 0
	Theme.corner(progress, 4)
	progress.Parent = track
	track.Parent = card
end

local function addLevels(parent: Instance, state: State)
	local tones = { Candy.cyan, Candy.gold, Candy.violet, Candy.coral }
	local row = Candy.row(parent, 63, 2, 8)
	for index, level in Config.LEVELS do
		if index == 3 then
			row = Candy.row(parent, 63, 2, 8)
		end
		local isCurrent = level.id == state.levelId
		local title = (Tabs.levels[index] or level.id)
			.. " · "
			.. string.format(Tabs.slotsCount, level.slots)
		local detail = if isCurrent
			then Tabs.current
			elseif level.cost == 0 then "✓"
			else string.format(Tabs.levelCost, Theme.formatInt(level.cost), level.minSpecies)
		Candy.metric(row, title, detail, tones[index])
	end
end

function Progression.mount(
	view: Frame,
	scroll: ScrollingFrame,
	displays: { Tank.Display },
	read: () -> State,
	requestExpansion: (Expansion, (boolean) -> ()) -> (),
	back: () -> (),
	changed: RBXScriptSignal?,
	claim: ((string, (string?) -> ()) -> ())?,
	mode: string
)
	Panel.stack(view)
	local stage = Instance.new("Frame")
	stage.Name = "TankStage"
	stage.BackgroundTransparency = 1
	local state = read()
	local habitat: Tank.Controller? = nil
	if mode == "expansion" then
		stage.Size = UDim2.new(1, 0, 0, 175)
		stage.Parent = view
		habitat = Tank.mount(stage, scroll, displays, state.capacity, state.levelId)
	else
		stage:Destroy()
	end

	local content = Instance.new("Frame")
	content.Name = "ProgressionDetails"
	content.LayoutOrder = 1
	content.Size = UDim2.fromScale(1, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.Parent = view
	local previewing = false
	local pending = false
	local notice: string? = nil

	local render: () -> ()
	render = function()
		content:ClearAllChildren()
		Panel.stack(content)
		local nextExpansion = state.nextExpansion
		if mode == "expansion" and not previewing then
			addLevels(content, state)
		end
		if notice then
			label(content, notice, 16)
		end

		if habitat and nextExpansion and previewing then
			local tank = habitat
			label(
				content,
				string.format(Copy.expansionPreview, state.capacity, nextExpansion.capacity),
				20
			)
			label(
				content,
				string.format(
					Copy.expansionCost,
					Theme.formatInt(nextExpansion.cost),
					Theme.formatInt(state.coins)
				),
				16
			)
			label(content, Copy.expansionKeepsSpecimens, 14)
			local canBuy = nextExpansion.canBuy
			if canBuy == nil then
				canBuy = state.coins >= nextExpansion.cost
			end
			if nextExpansion.requirement then
				label(content, nextExpansion.requirement, 14)
			end
			local function buy()
				pending = true
				notice = nil
				render()
				requestExpansion(nextExpansion, function(confirmed)
					if not view.Parent then
						return
					end
					pending = false
					local oldCapacity = state.capacity
					state = read()
					if confirmed and state.capacity > oldCapacity then
						previewing = false
						notice =
							string.format(Copy.expansionConfirmed, oldCapacity + 1, state.capacity)
						tank.expand(state.capacity, state.levelId)
						scroll.CanvasPosition = Vector2.zero
					else
						notice = Copy.expansionRejected
					end
					render()
				end)
			end
			View.button(
				content,
				"BuyExpansion",
				if pending
					then Copy.buyingExpansion
					elseif canBuy then Copy.buyExpansion
					else Text.aquariumPreview.errors[nextExpansion.reason or "noCoins"]
						or Copy.insufficient,
				if canBuy and not pending then Candy.gold else Candy.muted,
				if canBuy and not pending then buy else nil
			)
			View.button(
				content,
				"CancelExpansion",
				Copy.cancelExpansion,
				Candy.secondary,
				if pending
					then nil
					else function()
						previewing = false
						notice = nil
						tank.preview(nil)
						render()
					end
			)
		elseif habitat and nextExpansion then
			local tank = habitat
			View.button(content, "PreviewExpansion", Copy.previewExpansion, Candy.gold, function()
				previewing = true
				notice = nil
				tank.preview(nextExpansion.capacity, nextExpansion.id)
				scroll.CanvasPosition = Vector2.zero
				render()
			end)
		end

		if mode == "goals" then
			local function group(prefix: string, caption: string)
				label(content, caption, 20)
				for _, goal in state.goals do
					local claimGoal = claim
					local id = goal.id
					if not id or string.sub(id, 1, #prefix) ~= prefix then
						continue
					end
					addGoal(
						content,
						goal,
						if claimGoal
								and goal.canClaim
								and not pending
							then function()
								pending = true
								notice = nil
								render()
								claimGoal(id, function(reason)
									if not view.Parent then
										return
									end
									pending = false
									notice = if reason
										then Text.aquariumPreview.errors[reason]
											or Text.aquariumPreview.rejected
										else nil
									state = read()
									render()
								end)
							end
							else nil
					)
				end
			end
			group("session:", Tabs.session)
			group("income:", Tabs.income)
			local previous = state.previousSessionCoins
			if previous ~= nil then
				label(content, string.format(Copy.returnSummary, previous), 15)
			end
		end
	end
	if changed then
		local connection = changed:Connect(function()
			if not view.Parent or pending then
				return
			end
			local nextState = read()
			if nextState.capacity == 0 then
				back()
				return
			end
			local needsRender = nextState.rate ~= state.rate
				or nextState.capacity ~= state.capacity
				or nextState.previousSessionCoins ~= state.previousSessionCoins
				or #nextState.goals ~= #state.goals
				or (previewing and nextState.coins ~= state.coins)
			if not needsRender then
				for index, goal in nextState.goals do
					local previous = state.goals[index]
					if
						goal.progress ~= previous.progress
						or goal.claimed ~= previous.claimed
						or goal.canClaim ~= previous.canClaim
					then
						needsRender = true
						break
					end
				end
			end
			state = nextState
			if not needsRender then
				return
			end
			render()
		end)
		view.Destroying:Once(function()
			connection:Disconnect()
		end)
	end
	render()
end

return Progression
