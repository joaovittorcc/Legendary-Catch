--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Panel = require(script.Parent.Parent.Hud.Panel)
local View = require(script.Parent.AquariumView)
local Tank = require(script.Parent.AquariumTank)
local Income = require(script.Parent.AquariumIncome)

local Copy = Text.aquariumProgression
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
	text.TextStrokeTransparency = 1
	return text
end

local function addGoal(parent: Instance, goal: Goal)
	local card = Panel.card(parent, Theme.crystal, 106)
	local function line(content: string, size: number, y: number)
		local text = label(card, content, size)
		text.Size = UDim2.new(1, -20, 0, 23)
		text.Position = UDim2.fromOffset(10, y)
	end
	line(goal.title, 17, 5)
	line(goal.progressText, 14, 32)
	line(string.format(Copy.reward, goal.reward), 14, 58)

	local track = Instance.new("Frame")
	track.Name = "GoalProgress"
	track.Size = UDim2.new(1, -24, 0, 7)
	track.Position = UDim2.new(0, 12, 1, -17)
	track.BackgroundColor3 = Theme.ink
	track.BorderSizePixel = 0
	Theme.corner(track, 4)
	local progress = Instance.new("Frame")
	progress.Size = UDim2.fromScale(math.clamp(goal.progress / math.max(1, goal.target), 0, 1), 1)
	progress.BackgroundColor3 = Theme.crystal
	progress.BorderSizePixel = 0
	Theme.corner(progress, 4)
	progress.Parent = track
	track.Parent = card
end

function Progression.mount(
	view: Frame,
	scroll: ScrollingFrame,
	displays: { Tank.Display },
	read: () -> State,
	requestExpansion: (Expansion, (boolean) -> ()) -> (),
	back: () -> (),
	changed: RBXScriptSignal?,
	claim: ((string, (string?) -> ()) -> ())?
)
	Panel.stack(view)
	local stage = Instance.new("Frame")
	stage.Name = "TankStage"
	stage.BackgroundTransparency = 1
	stage.Size = UDim2.new(1, 0, 0, 175)
	stage.Parent = view
	local state = read()
	local habitat = Tank.mount(stage, scroll, displays, state.capacity, state.levelId)

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
		label(content, string.format(Copy.tankStatus, state.capacity, Income.rate(state.rate)), 17)
		if notice then
			label(content, notice, 16)
		end

		if nextExpansion and previewing then
			label(
				content,
				string.format(Copy.expansionPreview, state.capacity, nextExpansion.capacity),
				20
			)
			label(content, string.format(Copy.expansionCost, nextExpansion.cost, state.coins), 16)
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
						habitat.expand(state.capacity, state.levelId)
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
				if canBuy then Theme.track else Theme.muted,
				if canBuy and not pending then buy else nil
			)
			View.button(
				content,
				"CancelExpansion",
				Copy.cancelExpansion,
				Theme.crystal,
				if pending
					then nil
					else function()
						previewing = false
						notice = nil
						habitat.preview(nil)
						render()
					end
			)
		elseif nextExpansion then
			View.button(content, "PreviewExpansion", Copy.previewExpansion, Theme.track, function()
				previewing = true
				notice = nil
				habitat.preview(nextExpansion.capacity, nextExpansion.id)
				scroll.CanvasPosition = Vector2.zero
				render()
			end)
		end

		if not previewing then
			if #displays > 0 then
				View.button(content, "ReactToTank", Copy.react, Theme.crystal, function()
					habitat.react()
					scroll.CanvasPosition = Vector2.zero
				end)
			end
			for _, goal in state.goals do
				addGoal(content, goal)
				local id = goal.id
				if claim and id then
					View.button(
						content,
						"Claim_" .. id,
						if goal.claimed then Copy.claimed else Copy.claim,
						Theme.track,
						if goal.canClaim and not pending
							then function()
								pending = true
								notice = nil
								render()
								claim(id, function(reason)
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
			local previous = state.previousSessionCoins
			if previous ~= nil then
				label(content, string.format(Copy.returnSummary, previous), 15)
			end
		end

		View.button(
			content,
			"BackToAquarium",
			Copy.back,
			Theme.crystal,
			if pending then nil else back
		)
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
