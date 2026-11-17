--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Types = require(Shared:WaitForChild("Types"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))

type Mission = Types.Mission
type Daily = Types.Missions
type ClaimResult = { ok: boolean, kind: string, id: string, reward: number?, reason: string? }
local DAY_SECONDS = 86400
local Missions = {}

local function description(mission: Mission): string
	local rarity = string.match(mission.kind, "^catchRarity:(.+)$")
	if rarity then
		local name = Strings.rarity[rarity] or rarity
		return if mission.target == 1
			then string.format(Text.missions.raritySingle, name)
			else string.format(Text.missions.rarity, mission.target, name)
	end
	return string.format(Text.missions.kinds[mission.kind] or "%d", mission.target)
end

function Missions.start()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local gui, scroll = Panel.create("Missions", Text.missions.title, Theme.gold)
	Panel.stack(scroll)
	local clock = Panel.label(scroll, "", 15, Theme.gold)
	local rows = Instance.new("Frame")
	rows.LayoutOrder = 1
	rows.Size = UDim2.fromScale(1, 0)
	rows.AutomaticSize = Enum.AutomaticSize.Y
	rows.BackgroundTransparency = 1
	rows.Parent = scroll
	local mock: Daily? = nil
	if RunService:IsStudio() and Players.LocalPlayer:GetAttribute("DevMockMissions") == true then
		mock = {
			day = math.floor(workspace:GetServerTimeNow() / DAY_SECONDS),
			list = {
				{
					id = "mockCatch",
					kind = "catch",
					target = 5,
					progress = 2,
					reward = 45,
					claimed = false,
				},
				{
					id = "mockRare",
					kind = "catchRarity:Rare",
					target = 1,
					progress = 1,
					reward = 75,
					claimed = false,
				},
				{
					id = "mockTrain",
					kind = "train",
					target = 60,
					progress = 14,
					reward = 65,
					claimed = false,
				},
			},
		}
	end
	local day: number? = nil
	local completed: { [string]: boolean } = {}
	local pending: number? = nil

	local rowUpdates: { (Mission) -> () } = {}
	local rowIds: { string } = {}
	local renderedDay: number? = nil
	local displayed: Daily? = nil
	local loading: TextLabel? = nil

	local function render()
		local snapshot = Data.get()
		local live = snapshot and snapshot.missions
		local daily = live or mock
		displayed = daily
		if not daily then
			if not loading then
				loading = Panel.label(rows, Text.loading, 18)
			end
			return
		end

		local rebuild = renderedDay ~= daily.day or #rowIds ~= #daily.list
		for index, mission in daily.list do
			if rowIds[index] ~= mission.id then
				rebuild = true
				break
			end
		end
		if not rebuild then
			for index, mission in daily.list do
				rowUpdates[index](mission)
			end
			return
		end

		rows:ClearAllChildren()
		loading = nil
		table.clear(rowUpdates)
		table.clear(rowIds)
		renderedDay = daily.day
		Panel.stack(rows)
		scroll.CanvasPosition = Vector2.zero
		for index, mission in daily.list do
			rowIds[index] = mission.id
			local row = Instance.new("Frame")
			row.Name = "Challenge" .. index
			row.Size = UDim2.new(1, 0, 0, 100)
			row.LayoutOrder = index
			Theme.surface(row, Theme.crystal, 11)
			local outline = row:FindFirstChildWhichIsA("UIStroke")
			local title = Panel.label(row, "", 15)
			title.Size = UDim2.fromScale(0.58, 0.52)
			title.Position = UDim2.fromScale(0.025, 0)
			local status = Panel.label(row, "", 14, Theme.gold)
			status.Size = UDim2.fromScale(0.58, 0.23)
			status.Position = UDim2.fromScale(0.025, 0.51)
			local bar = Instance.new("Frame")
			bar.Size = UDim2.fromScale(0.54, 0.07)
			bar.Position = UDim2.fromScale(0.045, 0.8)
			bar.BackgroundColor3 = Theme.track
			Theme.corner(bar, 4)
			local fill = Instance.new("Frame")
			fill.BackgroundColor3 = Theme.gold
			Theme.corner(fill, 4)
			fill.Parent = bar
			bar.Parent = row

			local button = Panel.button(row, "", Theme.muted)
			button.Name = "Claim"
			button.TextSize = 14
			button.Size = UDim2.new(0.34, 0, 0, 44)
			button.Position = UDim2.new(0.63, 0, 0.5, -22)
			local buttonOutline = button:FindFirstChildWhichIsA("UIStroke")
			local function update(nextMission: Mission)
				local done = nextMission.progress >= nextMission.target
				title.Text = description(nextMission)
				status.Text = string.format(
					"%d / %d    ·    +%d ◆",
					math.min(nextMission.progress, nextMission.target),
					nextMission.target,
					nextMission.reward
				)
				fill.Size = UDim2.fromScale(
					math.clamp(nextMission.progress / math.max(1, nextMission.target), 0, 1),
					1
				)
				if outline then
					outline.Color = if done then Theme.gold else Theme.crystal
				end
				if buttonOutline then
					buttonOutline.Color = if done then Theme.gold else Theme.muted
				end
				button.Text = if nextMission.claimed
					then Text.missions.claimed
					elseif done then Text.missions.claim
					else Text.missions.ongoing
				button.Interactable = done and not nextMission.claimed
			end
			rowUpdates[index] = update
			update(mission)
			button.Activated:Connect(function()
				if pending or not button.Interactable then
					return
				end
				local latest = displayed
				local record = latest and latest.list[index]
				if not record or record.id ~= mission.id then
					return
				end
				if latest == mock then
					record.claimed = true
					update(record)
					return
				end
				local remote = remotes:FindFirstChild(Net.CLAIM_MISSION)
				if not remote or not remote:IsA("RemoteEvent") then
					Hud.toast(Text.unavailable)
					return
				end
				pending = index
				remote:FireServer(index)
				task.delay(4, function()
					if pending == index then
						pending = nil
					end
				end)
			end)
			row.Parent = rows
		end
	end

	local function refresh()
		local snapshot = Data.get()
		local real: Daily? = if snapshot then snapshot.missions else nil
		if real then
			local sameDay = day == real.day
			if not sameDay then
				table.clear(completed)
				day = real.day
			end
			for _, mission in real.list do
				local done = mission.progress >= mission.target
				if done and sameDay and completed[mission.id] == false and not mission.claimed then
					Hud.toast(Text.missions.complete, Theme.gold)
				end
				completed[mission.id] = done
			end
		end
		if gui.Enabled then
			render()
		end
	end

	local function countdown()
		local remaining = DAY_SECONDS - (math.floor(workspace:GetServerTimeNow()) % DAY_SECONDS)
		clock.Text = string.format(
			Text.missions.reset,
			math.floor(remaining / 3600),
			math.floor(remaining / 60) % 60,
			remaining % 60
		)
	end
	local function watchResult(child: Instance)
		if child.Name ~= Net.CLAIM_RESULT or not child:IsA("RemoteEvent") then
			return
		end
		child.OnClientEvent:Connect(function(result: ClaimResult)
			if result.kind == "mission" then
				pending = nil
			end
			Hud.toast(
				if result.ok
					then string.format(Text.missions.reward, result.reward or 0)
					else Text.missions.failed,
				if result.ok then Theme.gold else Theme.rose
			)
		end)
	end
	local result = remotes:FindFirstChild(Net.CLAIM_RESULT)
	if result then
		watchResult(result)
	end
	remotes.ChildAdded:Connect(watchResult)
	Hud.panelChanged:Connect(function(name: string)
		gui.Enabled = name == "Missions"
		if gui.Enabled then
			refresh()
			countdown()
		end
	end)
	Data.changed:Connect(refresh)
	task.spawn(function()
		while gui.Parent do
			if gui.Enabled then
				countdown()
			end
			task.wait(1)
		end
	end)
	refresh()
end

return Missions
