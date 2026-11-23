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
	stage: ((Frame) -> ())?,
}

local REMOVE = "remove"

local function name(specimen: Specimen): string
	return Strings.creatureName[specimen.id] or specimen.id
end

local function label(parent: Instance, content: string, size: number, color: Color3?): TextLabel
	local text = Panel.label(parent, content, size, color)
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
	local action = Panel.button(parent, content, accent)
	action.Name = key
	if accent == Theme.gold or accent == Theme.crystal then
		action.TextColor3 = Theme.ink
		action.TextStrokeTransparency = 1
	end
	if pressed then
		action.Activated:Connect(pressed)
	else
		action.Interactable = false
		action.Selectable = false
	end
	return action
end

local function summary(parent: Instance, snapshot: Snapshot): (number) -> ()
	local card = Panel.card(parent, Theme.crystal, 68)
	local function line(content: string, x: number, w: number, y: number, size: number): TextLabel
		local text = label(card, content, size)
		text.Size = UDim2.new(w, -8, 0, 27)
		text.Position = UDim2.new(x, 4, 0, y)
		text.TextScaled = true
		local constraint = Instance.new("UITextSizeConstraint")
		constraint.MinTextSize = 11
		constraint.MaxTextSize = size
		constraint.Parent = text
		return text
	end
	line(Copy.tankRate, 0, 0.55, 3, 14)
	line(Income.rate(snapshot.total), 0, 0.55, 30, 22)
	line(
		if snapshot.level then string.format(Copy.level, snapshot.level) else Copy.title,
		0.55,
		0.45,
		3,
		14
	)
	local balance = line(string.format(Copy.balance, snapshot.coins), 0.55, 0.45, 30, 15)
	balance.Name = "AquariumBalance"
	local tween: Tween? = nil
	local counter = Instance.new("NumberValue")
	counter.Value = snapshot.coins
	counter.Parent = balance
	counter:GetPropertyChangedSignal("Value"):Connect(function()
		balance.Text = string.format(Copy.balance, math.round(counter.Value))
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
	local model = Panel.card(parent, Theme.crystal, 125)
	model.BackgroundColor3 = Theme.viewport
	showModel(model, specimen.id)
	if effective then
		local badge = Income.badge(effective, specimen.rarity)
		badge.AnchorPoint = Vector2.new(0.5, 0)
		badge.Position = UDim2.fromScale(0.5, 0.04)
		badge.Size = UDim2.fromOffset(136, 32)
		badge.Parent = model
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
			specimen.count,
			Text.bestWeight,
			specimen.bestWeight
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
	label(
		parent,
		string.format(
			Copy.comparison,
			Income.rate(comparison.beforeTotal),
			Income.rate(comparison.afterTotal)
		),
		20
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
	label(
		parent,
		string.format(Copy.change, Income.signed(difference)),
		16,
		if difference < 0 then LOSS else GAIN
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
					Theme.gold,
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
					Theme.track,
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
			if inspected then
				showSpecimen(view, inspected.specimen, inspected.effective, showModel)
				if source.canRemove then
					AquariumView.button(view, "CompareRemoval", Copy.remove, Theme.rose, function()
						specimenKey = REMOVE
						notice = nil
						requestComparison()
					end)
				end
			end
			if #snapshot.candidates == 0 then
				label(view, Copy.noCandidates, 16)
			end
			for index, specimen in snapshot.candidates do
				local available = specimen.available > 0
				AquariumView.button(
					view,
					"Candidate" .. index,
					string.format(
						Copy.candidate,
						name(specimen),
						specimen.variant,
						specimen.available
					),
					if available then Theme.track else Theme.muted,
					if available
						then function()
							specimenKey = specimen.key
							notice = nil
							scroll.CanvasPosition = Vector2.zero
							requestComparison()
						end
						else nil
				)
			end
		else
			if source.stage then
				local intro = Instance.new("Frame")
				intro.Name = "TankOverview"
				intro.BackgroundTransparency = 1
				intro.Size = UDim2.new(1, 0, 0, 350)
				intro.Parent = view
				local stage = Panel.card(intro, Theme.crystal, 170)
				stage.Name = "TankPreview"
				local stats = Instance.new("Frame")
				stats.Name = "TankActions"
				stats.BackgroundTransparency = 1
				stats.AutomaticSize = Enum.AutomaticSize.Y
				Panel.stack(stats)
				stats.Parent = intro
				updateCoins = summary(stats, snapshot)
				overviewActions(stats, snapshot)
				local function fitOverview()
					local wide = intro.AbsoluteSize.X >= 455
					stage.Size = UDim2.new(
						if wide then 0.56 else 1,
						if wide then -5 else 0,
						0,
						if wide then 177 else 152
					)
					stats.Position = if wide
						then UDim2.new(0.56, 5, 0, 0)
						else UDim2.fromOffset(0, 162)
					stats.Size = UDim2.new(if wide then 0.44 else 1, if wide then -5 else 0, 0, 0)
					intro.Size =
						UDim2.new(1, 0, 0, if wide then 177 else 162 + stats.AbsoluteSize.Y)
				end
				intro:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitOverview)
				stats:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitOverview)
				fitOverview()
				source.stage(stage)
			end
			local occupied = 0
			for _, entry in snapshot.slots do
				if entry.occupant then
					occupied += 1
				end
			end
			label(
				view,
				string.format(Copy.occupancy, occupied, snapshot.capacity or #snapshot.slots),
				17
			)
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
					50
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
						then Theme.muted
						elseif occupant then Theme.crystal
						else Theme.track,
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
			if occupied == 0 then
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
				Theme.crystal,
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
