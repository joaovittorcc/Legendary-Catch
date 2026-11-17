--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Announcements = {}
local player = Players.LocalPlayer

function Announcements.start()
	local update =
		ReplicatedStorage:WaitForChild(Net.FOLDER):WaitForChild(Net.CATCH_ANNOUNCE) :: RemoteEvent
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "CatchAnnouncements"
	gui.DisplayOrder = 7
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local queue: { Net.CatchAnnounce } = {}
	local busy = false
	local function show(catch: Net.CatchAnnounce)
		local color = Theme.rarity[catch.rarity] or Theme.gold
		local card = Instance.new("CanvasGroup")
		card.Name = "CatchBanner"
		card.AnchorPoint = Vector2.new(0.5, 0)
		card.Position = UDim2.new(0.5, 0, 0, 58)
		card.Size = UDim2.new(0.84, 0, 0, 65)
		card.GroupTransparency = 1
		Theme.surface(card, color, 12, Theme.ink)
		local bounds = Instance.new("UISizeConstraint")
		bounds.MaxSize = Vector2.new(510, 65)
		bounds.Parent = card

		local rarity = Strings.rarity[catch.rarity] or catch.rarity
		local heading = Panel.label(
			card,
			if catch.variant == "Shiny" then rarity .. "  ·  " .. Text.shiny else rarity,
			14,
			color
		)
		heading.Name = "Rarity"
		heading.Size = UDim2.fromScale(1, 0.38)
		local creature = Strings.creatureName[catch.creatureId] or catch.creatureId
		local story = Panel.label(
			card,
			string.format(Text.catchAnnouncement, catch.displayName, creature),
			17
		)
		story.Name = "Catch"
		story.Size = UDim2.fromScale(0.94, 0.57)
		story.Position = UDim2.fromScale(0.03, 0.39)
		story.TextScaled = true
		local textLimit = Instance.new("UITextSizeConstraint")
		textLimit.MaxTextSize = 17
		textLimit.Parent = story
		card.Parent = gui
		Audio.play("panel", 0.19, 1.18)
		local enter = TweenService:Create(
			card,
			TweenInfo.new(0.22),
			{ GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0, 64) }
		)
		enter:Play()
		task.wait(4)
		local fade = TweenService:Create(card, TweenInfo.new(0.22), { GroupTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		card:Destroy()
	end

	update.OnClientEvent:Connect(function(catch: Net.CatchAnnounce)
		if
			catch.userId == player.UserId
			or playerGui:FindFirstChild("IslandArrival")
			or playerGui:FindFirstChild("IslandTitle")
		then
			return
		end
		if #queue >= 3 then
			table.remove(queue, 1)
		end
		table.insert(queue, catch)
		if busy then
			return
		end
		busy = true
		while #queue > 0 do
			local nextCatch = table.remove(queue, 1)
			if nextCatch then
				show(nextCatch)
			end
		end
		busy = false
	end)
end

return Announcements
