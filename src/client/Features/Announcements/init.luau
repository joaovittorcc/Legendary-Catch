--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Training = require(Shared:WaitForChild("Config"):WaitForChild("Training"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Tutorial = require(script.Parent:WaitForChild("Tutorial"))
local Announcements = {}
local player = Players.LocalPlayer

function Announcements.start()
	local update =
		ReplicatedStorage:WaitForChild(Net.FOLDER):WaitForChild(Net.CATCH_ANNOUNCE) :: RemoteEvent
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "CatchAnnouncements"
	gui.DisplayOrder = 4
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local queue: { Net.CatchAnnounce } = {}
	local busy = false
	local function show(catch: Net.CatchAnnounce)
		local color = Theme.rarity[catch.rarity] or Theme.gold
		local card = Instance.new("CanvasGroup")
		card.Name = "CatchBanner"
		card.AnchorPoint = Vector2.new(0.5, 0)
		local eventGui = playerGui:FindFirstChild("OceanEventHud")
		local event = eventGui and eventGui:FindFirstChild("EventBanner")
		local eventBottom = if event
				and event:IsA("GuiObject")
				and event.Visible
			then event.Position.Y.Offset + event.AbsoluteSize.Y
			else 0
		local top = math.max(Hud.navBottom(), Tutorial.cardBottom(), eventBottom) + 10
		card.Position = UDim2.new(0.5, 0, 0, top)
		card.Size = UDim2.new(0.84, 0, 0, 66)
		card.GroupTransparency = 1
		Theme.surface(card, color, 16, Theme.ink)
		local rim = card:FindFirstChildOfClass("UIStroke")
		if rim then
			rim.Color = color
		end
		local bounds = Instance.new("UISizeConstraint")
		bounds.MaxSize = Vector2.new(452, 66)
		bounds.Parent = card

		local crest =
			Panel.label(card, if catch.rarity == "Mystic" then "✺" else "★", 25, Theme.ink)
		crest.Name = "CatchCrest"
		crest.Size = UDim2.fromOffset(38, 38)
		crest.Position = UDim2.fromOffset(11, 14)
		crest.TextStrokeTransparency = 1
		Theme.surface(crest, color, 19, color)
		local rarity = Theme.rarityLabel(catch.rarity)
		local heading = Panel.label(
			card,
			if catch.variant == "Shiny" then rarity .. "  ·  " .. Text.shiny else rarity,
			14,
			color
		)
		heading.Name = "Rarity"
		heading.Size = UDim2.new(1, -72, 0, 20)
		heading.Position = UDim2.fromOffset(61, 6)
		heading.TextStrokeTransparency = 1
		heading.TextXAlignment = Enum.TextXAlignment.Left
		local creature = Strings.creatureName[catch.creatureId] or catch.creatureId
		local story = Panel.label(
			card,
			string.format(Text.catchAnnouncement, catch.displayName, creature),
			17,
			Theme.sand
		)
		story.Name = "Catch"
		story.Size = UDim2.new(1, -72, 0, 32)
		story.Position = UDim2.fromOffset(61, 24)
		story.TextScaled = true
		story.TextXAlignment = Enum.TextXAlignment.Left
		story.TextStrokeTransparency = 1
		local textLimit = Instance.new("UITextSizeConstraint")
		textLimit.MaxTextSize = 17
		textLimit.Parent = story
		card.Parent = gui
		Audio.play("panel", 0.19, 1.18)
		local reduced = player:GetAttribute("ReduceEffects") == true
		if not reduced then
			card.Position = UDim2.new(0.5, 0, 0, top - 8)
		end
		local enter = TweenService:Create(
			card,
			TweenInfo.new(0.22),
			{ GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0, top) }
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
			while
				Hud.isFishingActive()
				or Hud.panel() ~= ""
				or player:GetAttribute("CatchRevealActive") == true
				or (player:GetAttribute(Training.ACTIVE_ATTRIBUTE) or "") ~= ""
			do
				task.wait(0.25)
			end
			local nextCatch = table.remove(queue, 1)
			if nextCatch then
				show(nextCatch)
			end
		end
		busy = false
	end)
end

return Announcements
