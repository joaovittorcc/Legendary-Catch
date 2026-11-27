--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Panel = require(script.Parent.Parent.Hud.Panel)
local Income = require(script.Parent.AquariumIncome)
local Candy = require(script.Parent.AquariumCandy)

local Copy = Text.aquariumPreview
local LOSS = Color3.fromRGB(142, 40, 76)
local GAIN = Color3.fromRGB(23, 106, 74)
local AquariumView = {}

export type Specimen = {
	key: string,
	id: string,
	rarity: string,
	base: number,
	potential: number,
	variant: string,
	count: number,
	available: number,
	bestWeight: number,
	discovered: boolean?,
}
export type Occupant = { specimen: Specimen, effective: number }
export type Slot = { id: number, occupant: Occupant?, locked: boolean? }
-- Rates are hundredths of a coin per minute. Coins is the confirmed balance.
export type Snapshot = {
	status: string,
	version: number,
	total: number,
	coins: number,
	slots: { Slot },
	candidates: { Specimen },
	synergies: { string }?,
	capacity: number?,
	level: number?,
}
export type Comparison = {
	version: number,
	slotId: number,
	specimenKey: string,
	beforeSlot: number,
	afterSlot: number,
	beforeTotal: number,
	afterTotal: number,
	synergyDelta: number,
	synergiesGained: { string }?,
	synergiesLost: { string }?,
}
export type Source = {
	read: () -> Snapshot,
	changed: RBXScriptSignal,
	compare: (number, string, number, (Comparison?, string?) -> ()) -> (),
	confirm: (Comparison, (string?) -> ()) -> (),
	canRemove: boolean?,
	focus: ((number?) -> ())?,
	stage: ((Frame) -> (() -> ())?)?,
}

local REMOVE = "remove"

local function name(specimen: Specimen): string
	return Strings.creatureName[specimen.id] or specimen.id
end

local function label(parent: Instance, content: string, size: number, color: Color3?): TextLabel
	local text = Panel.label(parent, content, size, color or Candy.ink)
	text.TextStrokeTransparency = 1
	return text
end

function AquariumView.button(
	parent: Instance,
	key: string,
	content: string,
	accent: Color3,
	pressed: (() -> ())?
)
	local action = Candy.button(parent, content, accent)
	action.Name = key
	if pressed then
		action.Activated:Connect(pressed)
	else
		action.Interactable = false
		action.Selectable = false
	end
	return action
end

local function occupancy(snapshot: Snapshot): number
	local occupied = 0
	for _, entry in snapshot.slots do
		if entry.occupant then
			occupied += 1
		end
	end
	return occupied
end

local function summary(parent: Instance, snapshot: Snapshot, stacked: boolean?): (number) -> ()
	local capacity = snapshot.capacity or #snapshot.slots
	local metrics = if stacked then parent else Candy.row(parent, 63, 2, 8)
	Candy.metric(metrics, Copy.tankRate, Income.rate(snapshot.total), Candy.cyan)
	local levelName = Text.aquariumTabs.levels[snapshot.level or 0] or Copy.title
	Candy.metric(
		metrics,
		levelName,
		string.format("%d / %d", occupancy(snapshot), capacity),
		Candy.violet
	)
	local strip = Candy.card(parent, Candy.gold, 44)
	local balance = label(strip, string.format(Copy.balance, Theme.formatInt(snapshot.coins)), 16)
	balance.Size = UDim2.fromScale(1, 1)
	balance.Name = "AquariumBalance"
	local tween: Tween? = nil
	local counter = Instance.new("NumberValue")
	counter.Value = snapshot.coins
	counter.Parent = balance
	counter:GetPropertyChangedSignal("Value"):Connect(function()
		balance.Text = string.format(Copy.balance, Theme.formatInt(counter.Value))
	end)
	balance.Destroying:Once(function()
		if tween then
			tween:Cancel()
		end
	end)
	return function(coins: number)
		if tween then
			tween:Cancel()
		end
		if Players.LocalPlayer:GetAttribute("ReduceEffects") == true then
			counter.Value = coins
		else
			local counting = TweenService:Create(counter, TweenInfo.new(0.4), { Value = coins })
			tween = counting
			counting:Play()
		end
	end
end

local function showSpecimen(
	parent: Instance,
	specimen: Specimen,
	effective: number?,
	showModel: (Frame, string) -> ()
)
	local model = Candy.card(parent, Candy.cobalt, 142)
	local stage = Instance.new("Frame")
	stage.Name = "SpecimenViewportStage"
	stage.Position = UDim2.fromOffset(8, 8)
	stage.Size = UDim2.new(1, -16, 1, -16)
	stage.BackgroundColor3 = Theme.viewport
	stage.BorderSizePixel = 0
	Theme.corner(stage, 12)
	stage.Parent = model
	showModel(stage, specimen.id)
	if effective then
		local badge = Income.badge(effective, specimen.rarity)
		badge.AnchorPoint = Vector2.new(0.5, 0)
		badge.Position = UDim2.fromScale(0.5, 0.04)
		badge.Size = UDim2.fromOffset(136, 32)
		badge.Parent = stage
	end
	label(parent, name(specimen), 21)
	label(parent, Theme.rarityLabel(specimen.rarity) .. "  ·  " .. specimen.variant, 15)
	if specimen.discovered then
		label(parent, Copy.discovery, 15, GAIN)
	end
	label(
		parent,
		string.format(
			Text.collectionStats,
			Text.captures,
			Theme.formatInt(specimen.count),
			Text.bestWeight,
			(string.format("%.2f", specimen.bestWeight):gsub("%.", Strings.decimalSep))
		),
		15
	)
	label(
		parent,
		string.format(
			Copy.specimenRate,
			Income.rate(specimen.base),
			Income.rate(specimen.potential)
		),
		16
	)
	if effective then
		label(parent, string.format(Copy.effective, Income.rate(effective)), 16)
	end
end

local function showComparison(parent: Instance, comparison: Comparison)
	local difference = comparison.afterTotal - comparison.beforeTotal
	local row = Candy.row(parent, 63, 3, 7)
	local tabs = Text.aquariumTabs
	Candy.metric(row, tabs.currentRate, Income.rate(comparison.beforeTotal), Candy.pearl)
	Candy.metric(row, tabs.afterRate, Income.rate(comparison.afterTotal), Candy.cyan)
	Candy.metric(
		row,
		tabs.difference,
		Income.signed(difference),
		if difference < 0 then Candy.coral else Candy.gold
	)
	label(
		parent,
		string.format(
			Copy.slotRate,
			Income.rate(comparison.beforeSlot),
			Income.rate(comparison.afterSlot)
		),
		15
	)
	if comparison.synergyDelta ~= 0 then
		label(
			parent,
			string.format(Copy.synergy, Income.signed(comparison.synergyDelta)),
			16,
			if comparison.synergyDelta < 0 then LOSS else GAIN
		)
	end
	for _, id in ipairs(comparison.synergiesGained or {}) do
		label(parent, string.format(Copy.synergyGained, Strings.aquariumFamily[id] or id), 16, GAIN)
	end
	for _, id in ipairs(comparison.synergiesLost or {}) do
		label(parent, string.format(Copy.synergyLost, Strings.aquariumFamily[id] or id), 16, LOSS)
	end
end

local function chooserColumns(parent: Frame): (Frame, Frame)
	local row = Instance.new("Frame")
	row.Name = "SpecimenPicker"
	row.BackgroundTransparency = 1
	local function column(title: string): Frame
		local content = Instance.new("Frame")
		content.Name = title
		content.BackgroundTransparency = 1
		content.AutomaticSize = Enum.AutomaticSize.Y
		Panel.stack(content)
		content.Parent = row
		return content
	end
	local options = column("Options")
	local details = column("CurrentSpecimen")
	local function fit()
		local wide = row.AbsoluteSize.X >= 535
		options.Size = UDim2.new(if wide then 0.5 else 1, if wide then -5 else 0, 0, 0)
		details.Size = options.Size
		details.Position = if wide
			then UDim2.new(0.5, 5, 0, 0)
			else UDim2.fromOffset(0, options.AbsoluteSize.Y + 10)
		local height = if wide
			then math.max(options.AbsoluteSize.Y, details.AbsoluteSize.Y)
			else options.AbsoluteSize.Y + 10 + details.AbsoluteSize.Y
		row.Size = UDim2.new(1, 0, 0, height)
	end
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	options:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	details:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	row.Parent = parent
	fit()
	return options, details
end

function AquariumView.mount(
	view: Frame,
	scroll: ScrollingFrame,
	source: Source,
	showModel: (Frame, string) -> (),
	overviewActions: (Frame, Snapshot) -> ()
)
	local snapshot = source.read()
	local updateCoins: ((number) -> ())? = nil
	local slotId: number? = nil
	local specimenKey: string? = nil
	local comparison: Comparison? = nil
	local busy: string? = nil
	local notice: string? = nil
	local request = 0
	local mounted = true
	local requestComparison: () -> ()

	local function render(top: boolean)
		if source.focus then
			source.focus(slotId)
		end
		view:ClearAllChildren()
		updateCoins = nil
		Panel.stack(view)
		if top then
			scroll.CanvasPosition = Vector2.zero
		end
		if snapshot.status ~= "active" then
			label(view, if snapshot.status == "loading" then Text.loading else Copy.unavailable, 17)
			overviewActions(view, snapshot)
			return
		end
		local slot: Slot? = nil
		for _, entry in snapshot.slots do
			if entry.id == slotId and not entry.locked then
				slot = entry
				break
			end
		end
		local candidate: Specimen? = nil
		for _, entry in snapshot.candidates do
			if entry.key == specimenKey then
				candidate = entry
				break
			end
		end
		if slot or not source.stage then
			updateCoins = summary(view, snapshot)
		end

		if notice then
			label(view, notice, 16)
		end
		local inspected = slot and slot.occupant
		if slot and (candidate or specimenKey == REMOVE) then
			local subject = candidate or (inspected and inspected.specimen)
			if subject then
				label(view, name(subject) .. "  ·  " .. subject.variant, 18)
			end
			if comparison then
				local approved = comparison
				showComparison(view, approved)
				AquariumView.button(
					view,
					"ApplyAquarium",
					if busy
						then Copy.confirming
						elseif specimenKey == REMOVE then Copy.remove
						elseif inspected then Copy.swap
						else Copy.display,
					if specimenKey == REMOVE then Candy.coral else Candy.gold,
					if busy
						then nil
						else function()
							busy = "confirm"
							request += 1
							local token = request
							render(false)
							source.confirm(approved, function(reason)
								if not mounted or token ~= request then
									return
								end
								busy = nil
								snapshot = source.read()
								if reason == nil then
									slotId = nil
									specimenKey = nil
									comparison = nil
									notice = Copy.updated
									render(true)
								elseif reason == "stale" or reason == "staleVersion" then
									notice = Copy.stale
									requestComparison()
								else
									comparison = nil
									notice = Copy.errors[reason] or Copy.rejected
									render(false)
								end
							end)
						end
				)
			elseif busy then
				label(view, Copy.comparing, 16)
			else
				AquariumView.button(
					view,
					"RetryCompare",
					Copy.retry,
					Candy.cobalt,
					requestComparison
				)
			end
			if subject and not busy then
				showSpecimen(
					view,
					subject,
					if candidate then nil else inspected and inspected.effective,
					showModel
				)
			end
		elseif slot then
			label(view, string.format(Copy.choose, slot.id), 20)
			local options = view
			if inspected then
				local list, details = chooserColumns(view)
				options = list
				showSpecimen(details, inspected.specimen, inspected.effective, showModel)
				if source.canRemove then
					AquariumView.button(
						options,
						"CompareRemoval",
						Copy.remove,
						Candy.coral,
						function()
							specimenKey = REMOVE
							notice = nil
							requestComparison()
						end
					)
				end
			end
			if #snapshot.candidates == 0 then
				label(options, Copy.noCandidates, 16)
			end
			for index, specimen in snapshot.candidates do
				local available = specimen.available > 0
				local option = AquariumView.button(
					options,
					"Candidate" .. index,
					(
						if specimen.available == 1
							then string.format(
								Copy.candidateSingle,
								name(specimen),
								specimen.variant
							)
							else string.format(
								Copy.candidate,
								name(specimen),
								specimen.variant,
								specimen.available
							)
					)
						.. "\n"
						.. Income.rate(specimen.potential),
					if available
						then (if index % 2 == 1 then Candy.violet else Candy.cobalt)
						else Candy.muted,
					if available
						then function()
							specimenKey = specimen.key
							notice = nil
							scroll.CanvasPosition = Vector2.zero
							requestComparison()
						end
						else nil
				)
				option.Size = UDim2.new(1, 0, 0, 54)
				option.TextSize = 15
			end
		else
			if source.stage then
				local intro = Instance.new("Frame")
				intro.Name = "TankOverview"
				intro.BackgroundTransparency = 1
				intro.Size = UDim2.new(1, 0, 0, 350)
				intro.Parent = view
				local stage = Candy.card(intro, Candy.cobalt, 200)
				stage.Name = "TankPreview"
				local stats = Instance.new("Frame")
				stats.Name = "TankActions"
				stats.BackgroundTransparency = 1
				stats.AutomaticSize = Enum.AutomaticSize.Y
				Panel.stack(stats)
				stats.Parent = intro
				updateCoins = summary(stats, snapshot, true)
				for _, synergy in ipairs(snapshot.synergies or {}) do
					local card = Candy.card(stats, Candy.violet, 44)
					local badge = label(card, synergy, 16, Color3.fromRGB(98, 42, 178))
					badge.Size = UDim2.fromScale(1, 1)
				end
				overviewActions(stats, snapshot)
				local function fitOverview()
					local wide = intro.AbsoluteSize.X >= 455
					local tankHeight = if wide then 236 else 196
					stage.Size =
						UDim2.new(if wide then 0.56 else 1, if wide then -5 else 0, 0, tankHeight)
					stats.Position = if wide
						then UDim2.new(0.56, 5, 0, 0)
						else UDim2.fromOffset(0, tankHeight + 10)
					stats.Size = UDim2.new(if wide then 0.44 else 1, if wide then -5 else 0, 0, 0)
					intro.Size = UDim2.new(
						1,
						0,
						0,
						if wide
							then math.max(tankHeight, stats.AbsoluteSize.Y)
							else tankHeight + 10 + stats.AbsoluteSize.Y
					)
				end
				intro:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitOverview)
				stats:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitOverview)
				fitOverview()
				local react = source.stage(stage)
				if react then
					AquariumView.button(
						stats,
						"ReactToTank",
						Text.aquariumProgression.react,
						Candy.secondary,
						react
					)
				end
			end
			local grid = Instance.new("Frame")
			grid.Name = "TankSlotsGrid"
			grid.BackgroundTransparency = 1
			grid.Size = UDim2.fromScale(1, 0)
			grid.AutomaticSize = Enum.AutomaticSize.Y
			grid.Parent = view
			local layout = Instance.new("UIGridLayout")
			layout.CellPadding = UDim2.fromOffset(8, 8)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = grid
			local function resizeGrid()
				local width = grid.AbsoluteSize.X
				local columns = math.clamp(math.floor((width + 8) / 176), 1, 3)
				layout.CellSize = UDim2.fromOffset(
					math.max(1, math.floor((width - (columns - 1) * 8) / columns)),
					55
				)
			end
			grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeGrid)
			resizeGrid()
			for _, entry in snapshot.slots do
				local occupant = entry.occupant
				local title = if entry.locked
					then Copy.locked
					elseif occupant then name(occupant.specimen) .. " · " .. Income.rate(
						occupant.effective
					)
					else Copy.vacant
				local tile = AquariumView.button(
					grid,
					"Slot" .. entry.id,
					string.format(Copy.slot, entry.id, title),
					if entry.locked
						then Candy.muted
						elseif not occupant then Candy.gold
						elseif entry.id % 2 == 1 then Candy.cyan
						else Candy.violet,
					if entry.locked
						then nil
						else function()
							slotId = entry.id
							notice = nil
							render(true)
						end
				)
				tile.LayoutOrder = entry.id
				tile.TextSize = 14
			end
			if occupancy(snapshot) == 0 then
				label(view, Copy.empty, 16)
			end
			if not source.stage then
				overviewActions(view, snapshot)
			end
		end

		if slot then
			AquariumView.button(
				view,
				"BackStep",
				Copy.back,
				Candy.secondary,
				if busy == "confirm"
					then nil
					else function()
						request += 1
						busy = nil
						notice = nil
						comparison = nil
						if specimenKey then
							specimenKey = nil
						else
							slotId = nil
						end
						render(true)
					end
			)
		end
	end

	requestComparison = function()
		local slot = slotId
		local key = specimenKey
		if not slot or not key then
			return
		end
		request += 1
		local token = request
		local version = snapshot.version
		comparison = nil
		busy = "compare"
		render(false)
		source.compare(slot, key, version, function(reply, reason)
			if not mounted or token ~= request then
				return
			end
			busy = nil
			snapshot = source.read()
			if reason == "staleVersion" and snapshot.version > version then
				notice = Copy.stale
				requestComparison()
				return
			end
			if
				reply
				and reply.version == snapshot.version
				and reply.slotId == slot
				and reply.specimenKey == key
			then
				comparison = reply
			else
				notice = if reason == "stale" or reason == "staleVersion"
					then Copy.stale
					else Copy.errors[reason or ""] or Copy.rejected
			end
			render(false)
		end)
	end

	local connection = source.changed:Connect(function()
		local nextSnapshot = source.read()
		if nextSnapshot.status == "active" and nextSnapshot.version < snapshot.version then
			return
		end
		local changed = nextSnapshot.status == "active" and nextSnapshot.version ~= snapshot.version
		local statusChanged = nextSnapshot.status ~= snapshot.status
		local coinsChanged = nextSnapshot.coins ~= snapshot.coins
		snapshot = nextSnapshot
		if not changed and not statusChanged then
			if updateCoins and coinsChanged then
				updateCoins(nextSnapshot.coins)
			end
			return
		end
		if changed and busy ~= "confirm" and specimenKey then
			notice = Copy.stale
			requestComparison()
		else
			if changed and not specimenKey then
				notice = nil
			end
			render(false)
		end
	end)
	view.Destroying:Once(function()
		mounted = false
		connection:Disconnect()
		if source.focus then
			source.focus(nil)
		end
	end)
	render(true)
end

return AquariumView
