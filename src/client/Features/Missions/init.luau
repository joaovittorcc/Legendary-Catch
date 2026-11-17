--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))

type Mission = {
	id: string,
	kind: string,
	target: number,
	progress: number,
	reward: number,
	claimed: boolean,
}
type Daily = { day: number, list: { Mission } }
type ClaimResult = { ok: boolean, kind: string, id: string, reward: number?, reason: string? }
local DAY_SECONDS = 86400
local Missions = {}
local Perfect = require(script:WaitForChild("Perfect"))

local function description(mission: Mission): string
	local rarity = string.match(mission.kind, "^catchRarity:(.+)$")
	if rarity then
		return string.format(Text.missions.rarity, mission.target, Strings.rarity[rarity] or rarity)
	end
	return string.format(Text.missions.kinds[mission.kind] or "%d", mission.target)
end

function Missions.start()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	Perfect.start(remotes)
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

	local function render()
		rows:ClearAllChildren()
		Panel.stack(rows)
		local snapshot = Data.get()
		local real: Daily? = if snapshot then (snapshot :: any).missions else nil
		local daily = real or mock
		if not daily then
			Panel.label(rows, Text.loading, 18)
			return
		end

		for index, mission in daily.list do
			local done = mission.progress >= mission.target
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 100)
			row.LayoutOrder = index
			Theme.surface(row, if done then Theme.gold else Theme.crystal, 11)
			local title = Panel.label(row, description(mission), 15)
			title.Size = UDim2.fromScale(0.58, 0.52)
			title.Position = UDim2.fromScale(0.025, 0)
			local status = Panel.label(
				row,
				string.format(
					"%d / %d    ·    +%d ◆",
					math.min(mission.progress, mission.target),
					mission.target,
					mission.reward
				),
				14,
				Theme.gold
			)
			status.Size = UDim2.fromScale(0.58, 0.23)
			status.Position = UDim2.fromScale(0.025, 0.51)
			local bar = Instance.new("Frame")
			bar.Size = UDim2.fromScale(0.54, 0.07)
			bar.Position = UDim2.fromScale(0.045, 0.8)
			bar.BackgroundColor3 = Theme.ink
			Theme.corner(bar, 4)
			local fill = Instance.new("Frame")
			fill.Size =
				UDim2.fromScale(math.clamp(mission.progress / math.max(1, mission.target), 0, 1), 1)
			fill.BackgroundColor3 = Theme.crystal
			Theme.corner(fill, 4)
			fill.Parent = bar
			bar.Parent = row

			local label = if mission.claimed
				then Text.missions.claimed
				elseif done then Text.missions.claim
				else Text.missions.ongoing
			local button = Panel.button(row, label, if done then Theme.gold else Theme.muted)
			button.TextSize = 14
			button.Size = UDim2.new(0.34, 0, 0, 44)
			button.Position = UDim2.new(0.63, 0, 0.5, -22)
			button.Interactable = done and not mission.claimed
			button.Activated:Connect(function()
				if pending then
					return
				end
				if not real then
					mission.claimed = true
					render()
					return
				end
				local remote = remotes:FindFirstChild("ClaimMission")
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
		local real: Daily? = if snapshot then (snapshot :: any).missions else nil
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
		if child.Name ~= "ClaimResult" or not child:IsA("RemoteEvent") then
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
	local result = remotes:FindFirstChild("ClaimResult")
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
