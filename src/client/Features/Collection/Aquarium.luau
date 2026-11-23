--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config.Aquarium)
local Creatures = require(Shared.Config.Creatures)
local Net = require(Shared.Net)
local Text = require(Shared.StringsUi)
local Theme = require(Shared.UiTheme)
local Types = require(Shared.Types)
local Data = require(script.Parent.Parent.Parent.Data)
local View = require(script.Parent.AquariumView)
local Income = require(script.Parent.AquariumIncome)
local Progression = require(script.Parent.AquariumProgression)
local Tank = require(script.Parent.AquariumTank)
local World = require(script.Parent.AquariumWorld)

local Aquarium = {}
export type Detail = {
	id: string,
	variant: string,
	count: number,
	potential: number,
	effective: number?,
}
type Fish = { creatureId: string, variant: string }
type Reply = (Net.AquariumResult?) -> ()
local Copy = Text.aquariumPreview
local Goals = Text.aquariumProgression
local variants = { "base", "giant", "gold", "both" }
local names: { [string]: string } =
	{ base = Copy.base, giant = Copy.giant, gold = Copy.golden, both = Copy.combined }

function Aquarium.start(remotes: Instance)
	local changed = Instance.new("BindableEvent")
	local state: Types.AquariumSnapshot? = nil
	local profile = Data.get()
	local pending: { [string]: Reply } = {}
	local world = World.start()
	local placed = false

	local function update(nextState: Types.AquariumSnapshot?)
		local oldVersion = if state then state.version or 0 else 0
		local newVersion = if nextState then nextState.version or 0 else 0
		if nextState == nil or nextState.status ~= "ready" or newVersion >= oldVersion then
			state = nextState
			for _, slot in ipairs((nextState and nextState.slots) or {}) do
				placed = placed or slot.occupant ~= nil
			end
			world.update(state)
		end
	end

	update(if profile then profile.aquarium else nil)
	Data.changed:Connect(function(newProfile: Types.Snapshot)
		profile = newProfile
		update(newProfile.aquarium)
		changed:Fire()
	end)

	local function request(remoteName: string, payload: { [string]: any }, reply: Reply)
		local remote = remotes:FindFirstChild(remoteName)
		if not remote or not remote:IsA("RemoteEvent") then
			reply(nil)
			return
		end
		local id = HttpService:GenerateGUID(false)
		payload.requestId = id
		pending[id] = reply
		remote:FireServer(payload)
		task.delay(8, function()
			local callback = pending[id]
			if callback then
				pending[id] = nil
				callback(nil)
			end
		end)
	end

	task.spawn(function()
		local remote = remotes:WaitForChild(Net.AQUARIUM_RESULT, 15)
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(function(result: Net.AquariumResult)
				local callback = pending[result.requestId]
				local latestProfile = Data.get()
				local latest = latestProfile and latestProfile.aquarium
				if result.snapshot and latest and latest.status == "ready" then
					update(result.snapshot)
				end
				if callback then
					pending[result.requestId] = nil
					callback(result)
				end
				if result.snapshot then
					changed:Fire()
				end
			end)
		end
	end)

	local function specimen(fish: Fish, available: number): View.Specimen
		local creature = Creatures.get(fish.creatureId)
		local record = profile and profile.collection[fish.creatureId]
		return {
			key = fish.creatureId .. "/" .. fish.variant,
			id = fish.creatureId,
			rarity = if creature then creature.rarity else "Common",
			base = Config.RATES_CPM[fish.creatureId] or 0,
			potential = Config.rateCpm(fish.creatureId, fish.variant) or 0,
			variant = names[fish.variant] or fish.variant,
			count = if record then record.count else available,
			available = available,
			bestWeight = if record then record.bestWeight else 0,
		}
	end

	local function read(): View.Snapshot
		local snapshot = state
		local slots: { View.Slot } = {}
		local candidates: { View.Specimen } = {}
		local slotCpm = snapshot and snapshot.slotCpm
		for _, slot in ipairs((snapshot and snapshot.slots) or {}) do
			local occupant = slot.occupant
			table.insert(slots, {
				id = slot.index,
				occupant = if occupant
					then {
						specimen = specimen(occupant, 0),
						effective = if slotCpm then slotCpm[slot.index] or 0 else 0,
					}
					else nil,
			})
		end
		if snapshot and snapshot.nextLevel then
			for index = #slots + 1, snapshot.nextLevel.slots do
				table.insert(slots, { id = index, locked = true })
			end
		end
		local inventory = snapshot and snapshot.inventory
		if inventory then
			for _, entry in Creatures.LIST do
				local counts = inventory[entry.id]
				if counts then
					local byVariant: { [string]: number } = {
						base = counts.base,
						giant = counts.giant,
						gold = counts.gold,
						both = counts.both,
					}
					for _, variant in variants do
						local available = byVariant[variant]
						if available > 0 then
							table.insert(
								candidates,
								specimen({ creatureId = entry.id, variant = variant }, available)
							)
						end
					end
				end
			end
		end
		return {
			status = if not profile
				then "loading"
				elseif snapshot and snapshot.status == "ready" then "active"
				else "disabled",
			version = if snapshot then snapshot.version or 0 else 0,
			total = if snapshot then snapshot.totalCpm or 0 else 0,
			coins = if profile then profile.coins else 0,
			level = if snapshot then snapshot.level else nil,
			capacity = if snapshot and snapshot.slots then #snapshot.slots else 0,
			slots = slots,
			candidates = candidates,
		}
	end

	local function modify(slot: number, key: string, version: number, remote: string, reply: Reply)
		local creatureId, variant = key:match("^([^/]+)/([^/]+)$")
		local slots = state and state.slots
		local current = slots and slots[slot]
		request(remote, {
			op = if key == "remove"
				then "remove"
				elseif current and current.occupant then "swap"
				else "place",
			slot = slot,
			creatureId = creatureId,
			variant = variant,
			expectedVersion = version,
		}, reply)
	end

	local function reason(result: Net.AquariumResult?): string?
		if result and result.ok then
			return nil
		end
		return if result then result.reason or "rejected" else "timeout"
	end

	local source: View.Source = {
		read = read,
		changed = changed.Event,
		canRemove = true,
		focus = world.focus,
		compare = function(slot, key, version, done)
			modify(slot, key, version, Net.AQUARIUM_PREVIEW, function(result)
				local preview: Types.AquariumPreview? = if result and result.ok
					then result.preview
					else nil
				if not preview then
					done(nil, reason(result))
					return
				end
				done({
					version = preview.usedVersion,
					slotId = preview.slot,
					specimenKey = key,
					beforeSlot = preview.slotBeforeCpm,
					afterSlot = preview.slotAfterCpm,
					beforeTotal = preview.totalBeforeCpm,
					afterTotal = preview.totalAfterCpm,
					synergyDelta = preview.deltaCpm - (if preview.candidate
						then preview.candidate.cpm
						else 0) + (if preview.current then preview.current.cpm else 0),
					synergiesGained = preview.synergiesGained,
					synergiesLost = preview.synergiesLost,
				}, nil)
			end)
		end,
		confirm = function(comparison, done)
			modify(
				comparison.slotId,
				comparison.specimenKey,
				comparison.version,
				Net.AQUARIUM_APPLY,
				function(result)
					done(reason(result))
				end
			)
		end,
	}

	local function progress(): Progression.State
		local snapshot = state
		local nextLevel = snapshot and snapshot.nextLevel
		local expanded: Progression.Expansion? = nil
		if nextLevel then
			local requirement = nextLevel.requirement
				and nextLevel.requirement:match("^species:(%d+)$")
			expanded = {
				capacity = nextLevel.slots,
				cost = nextLevel.cost,
				id = nextLevel.levelId,
				version = snapshot and snapshot.version,
				canBuy = nextLevel.canBuy,
				requirement = if requirement
					then string.format(Goals.speciesRequired, tonumber(requirement) or 0)
					else nil,
				reason = nextLevel.reason,
			}
		end
		local goals: { Progression.Goal } = {}
		local goalsState = snapshot and snapshot.goals
		if goalsState then
			for _, goal in goalsState.income.list do
				table.insert(goals, {
					id = "income:" .. goal.id,
					title = Goals.incomeGoal,
					progress = goalsState.income.bestCpm,
					target = goal.cpm,
					progressText = Income.rate(goalsState.income.bestCpm) .. " / " .. Income.rate(
						goal.cpm
					),
					reward = Goals.cosmeticNames[goal.cosmetic] or goal.cosmetic,
					claimed = goal.claimed,
					canClaim = goal.reached and not goal.claimed,
				})
			end
			for _, goal in goalsState.session.list do
				table.insert(goals, {
					id = "session:" .. goal.id,
					title = Goals.sessionNames[goal.id] or Goals.sessionGoal,
					progress = goal.progress,
					target = goal.target,
					progressText = string.format("%d / %d", goal.progress, goal.target),
					reward = string.format(Goals.coinReward, goal.coins),
					claimed = goal.claimed,
					canClaim = goal.progress >= goal.target
						and not goal.claimed
						and goalsState.session.coinsLeftToday > 0,
				})
			end
		end
		local slots = snapshot and snapshot.slots
		local offline = snapshot and snapshot.offline
		return {
			capacity = if slots then #slots else 0,
			levelId = if snapshot then snapshot.levelId else nil,
			nextExpansion = expanded,
			coins = if profile then profile.coins else 0,
			rate = if snapshot then snapshot.totalCpm or 0 else 0,
			goals = goals,
			previousSessionCoins = if offline then offline.coins else nil,
		}
	end

	local function mount(
		parent: Frame,
		scroll: ScrollingFrame,
		showModel: (Frame, string) -> (),
		back: () -> ()
	)
		local function frame(name: string, container: Frame): Frame
			local page = Instance.new("Frame")
			page.Name = name
			page.BackgroundTransparency = 1
			page.Size = UDim2.fromScale(1, 0)
			page.AutomaticSize = Enum.AutomaticSize.Y
			page.Parent = container
			return page
		end
		local page = frame("Aquarium", parent)
		local showSlots: () -> ()
		local function showProgress()
			page:ClearAllChildren()
			scroll.CanvasPosition = Vector2.zero
			local view = frame("AquariumProgression", page)
			Progression.mount(
				view,
				scroll,
				World.displays(state),
				progress,
				function(expansion, done)
					request(
						Net.AQUARIUM_BUY_LEVEL,
						{ levelId = expansion.id, expectedVersion = expansion.version },
						function(result)
							done(result ~= nil and result.ok)
						end
					)
				end,
				showSlots,
				changed.Event,
				function(id, done)
					request(Net.AQUARIUM_CLAIM_GOAL, { goalId = id }, function(result)
						done(reason(result))
					end)
				end
			)
		end
		showSlots = function()
			page:ClearAllChildren()
			scroll.CanvasPosition = Vector2.zero
			local view = frame("AquariumSlots", page)
			local screenSource = table.clone(source)
			screenSource.stage = function(stage)
				local aquarium = state
				local slots = aquarium and aquarium.slots
				Tank.mount(
					stage,
					scroll,
					World.displays(aquarium),
					if slots then #slots else 0,
					if aquarium then aquarium.levelId else nil
				)
			end
			View.mount(view, scroll, screenSource, showModel, function(container, snapshot)
				if snapshot.status == "active" then
					View.button(
						container,
						"AquariumProgression",
						Goals.open,
						Theme.track,
						showProgress
					)
				end
				View.button(container, "BackToCollection", Text.collection, Theme.crystal, back)
			end)
		end
		showSlots()
	end

	return {
		mount = mount,
		available = function()
			return state ~= nil and state.status == "ready"
		end,
		firstDisplay = function(): boolean
			if placed or not profile or not state or state.status ~= "ready" then
				return false
			end
			return next(profile.collection) ~= nil
		end,
		details = function(id: string): { Detail }
			local snapshot = state
			if not snapshot or snapshot.status ~= "ready" then
				return {}
			end
			local result: { Detail } = {}
			local inventory = snapshot.inventory and snapshot.inventory[id]
			local totals: { [string]: number } = if inventory
				then {
					base = inventory.base,
					giant = inventory.giant,
					gold = inventory.gold,
					both = inventory.both,
				}
				else {}
			local rates: { [string]: number } = {}
			local slotCpm = snapshot.slotCpm
			for _, slot in ipairs(snapshot.slots or {}) do
				local fish = slot.occupant
				if fish and fish.creatureId == id then
					totals[fish.variant] = (totals[fish.variant] or 0) + 1
					rates[fish.variant] = (rates[fish.variant] or 0)
						+ (if slotCpm then slotCpm[slot.index] or 0 else 0)
				end
			end
			for _, variant in variants do
				if (totals[variant] or 0) > 0 then
					table.insert(result, {
						id = variant,
						variant = names[variant],
						count = totals[variant],
						potential = Config.rateCpm(id, variant) or 0,
						effective = rates[variant],
					})
				end
			end
			return result
		end,
	}
end

return Aquarium
