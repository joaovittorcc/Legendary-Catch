--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local StringsUi = require(Shared:WaitForChild("StringsUi"))
local Text = StringsUi.tutorial
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Motion = require(script.Parent.Hud:WaitForChild("Motion"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))

local Tutorial = {}
local CARD_HEIGHT = 64
local layout = Instance.new("BindableEvent")
local visibleBottom = 0
Tutorial.layoutChanged = layout.Event

function Tutorial.cardBottom(): number
	return visibleBottom
end
type TutorialState = { step: string, done: boolean }
local player = Players.LocalPlayer
local destinations: { [string]: string } = {
	goToPier = "FishingZone",
	cast = "FishingZone",
	workshop = "WorkshopSpot",
	training = "TrainingSpot",
}
local icons: { [string]: string } = {
	goToPier = "🧭",
	cast = "🎣",
	fight = "🐟",
	collection = "📖",
	workshop = "🛠️",
	training = "✨",
}

function Tutorial.start()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local mockEnabled = RunService:IsStudio() and player:GetAttribute("DevMockTutorial") == true
	local mock: TutorialState = { step = "goToPier", done = false }
	local step = ""
	local atPier = false
	local gui = Instance.new("ScreenGui")
	gui.Name = "TutorialGuide"
	gui.DisplayOrder = 3
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local card = Instance.new("Frame")
	card.Name = "TutorialCard"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, Hud.navBottom() + 8)
	card.Size = UDim2.new(0.92, 0, 0, CARD_HEIGHT)
	card.Visible = false
	Art.panel(card, Theme.crystal)
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(500, CARD_HEIGHT)
	bounds.Parent = card
	local iconHolder = Instance.new("TextButton")
	iconHolder.Name = "StepIcon"
	iconHolder.Text = ""
	iconHolder.AutoButtonColor = false
	iconHolder.AnchorPoint = Vector2.new(0, 0.5)
	iconHolder.Position = UDim2.fromOffset(10, CARD_HEIGHT / 2)
	iconHolder.Size = UDim2.fromOffset(44, 44)
	iconHolder.BackgroundColor3 = Theme.cream
	iconHolder.BorderSizePixel = 0
	iconHolder.ZIndex = 3
	Theme.corner(iconHolder, 21)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Theme.outline
	iconStroke.Thickness = 2
	iconStroke.Parent = iconHolder
	local stepIcon = Panel.label(iconHolder, "🧭", 26)
	stepIcon.Size = UDim2.fromScale(1, 1)
	stepIcon.TextScaled = true
	stepIcon.TextStrokeTransparency = 1
	stepIcon.ZIndex = 4
	Motion.mount(iconHolder)
	iconHolder.Parent = card
	iconHolder.Activated:Connect(function()
		if step == "collection" then
			Hud.showPanel("Collection")
		end
	end)
	local message = Panel.label(card, "", 14)
	message.Size = UDim2.new(1, -176, 1, -12)
	message.TextScaled = true
	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MaxTextSize = 20
	textLimit.Parent = message
	message.Position = UDim2.fromOffset(62, 6)
	local skip = Panel.button(card, Text.skip, Theme.gold)
	skip.Size = UDim2.fromOffset(88, 44)
	skip.AnchorPoint = Vector2.new(1, 0.5)
	skip.Position = UDim2.new(1, -17, 0.5, 0)
	local openAlbum = Panel.button(card, StringsUi.adventure.openAlbum, Theme.crystal)
	openAlbum.Name = "OpenAlbum"
	openAlbum.Size = UDim2.new(1, -176, 0, 44)
	openAlbum.Position = UDim2.fromOffset(62, 10)
	openAlbum.TextSize = 14
	openAlbum.Visible = false
	openAlbum.Activated:Connect(function()
		Hud.showPanel("Collection")
	end)
	card.Parent = gui
	local setCardVisible = Hud.bindFishingVisibility(card, false)

	local guide = Instance.new("BillboardGui")
	guide.Name = "TutorialDestination"
	guide.Size = UDim2.fromOffset(130, 48)
	guide.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	guide.AlwaysOnTop = true
	guide.Enabled = false
	local arrow = Panel.label(guide, "", 15, Theme.sand)
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.TextStrokeTransparency = 0.22
	arrow.BackgroundTransparency = 0.12
	Theme.surface(arrow, Theme.crystal, 12, Theme.ink)
	local setArrowVisible = Hud.bindFishingVisibility(arrow, false)
	guide.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")

	local function publishLayout()
		local bottom = if gui.Enabled and card.Visible
			then card.Position.Y.Offset + CARD_HEIGHT
			else 0
		if visibleBottom ~= bottom then
			visibleBottom = bottom
			layout:Fire()
		end
	end
	local function placeCard()
		local viewport = gui.AbsoluteSize
		local portrait = viewport.Y > viewport.X
		card.Size = UDim2.new(if portrait then 0.92 else 0.5, 0, 0, CARD_HEIGHT)
		card.Position = UDim2.new(0.5, 0, 0, Hud.navBottom() + 8)
		publishLayout()
	end
	Hud.layoutChanged:Connect(function()
		placeCard()
	end)
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeCard)
	gui:GetPropertyChangedSignal("Enabled"):Connect(publishLayout)
	card:GetPropertyChangedSignal("Visible"):Connect(publishLayout)

	local function realState(): TutorialState?
		local snapshot = Data.get()
		return if snapshot then snapshot.tutorial else nil
	end

	local function refresh()
		local state = realState() or (if mockEnabled then mock else nil)
		step = if state and not state.done then state.step else ""
		local hint = Text.steps[if step == "goToPier" and atPier then "cast" else step]
		local coral = Rods.get("coral")
		local coins = player:GetAttribute("Coins")
		local affordable = not coral or (typeof(coins) == "number" and coins >= coral.price)
		if step == "workshop" and not affordable then
			hint = Text.earn
		end
		local showCard = hint ~= nil
			and Hud.panel() == ""
			and not Hud.isFishingActive()
			and player:GetAttribute("CatchRevealActive") ~= true
		setCardVisible(showCard)
		message.Text = hint or ""
		openAlbum.Visible = step == "collection"
		message.Visible = not openAlbum.Visible
		stepIcon.Text = icons[if step == "goToPier" and atPier then "cast" else step] or "🧭"
		iconHolder.Interactable = step == "collection"
		iconHolder.Selectable = iconHolder.Interactable
		local tag = if step == "workshop" and not affordable
			then "FishingZone"
			else destinations[step]
		local target = tag and CollectionService:GetTagged(tag)[1]
		guide.Adornee = if target and target:IsA("BasePart") then target else nil
		guide.Enabled = target ~= nil and not (step == "goToPier" and atPier)
		setArrowVisible(showCard and target ~= nil)
		arrow.Text = (if tag then Text.destinations[tag] or "" else "") .. "\n▼"
	end

	local function send(name: string, event: string?)
		local remote = remotes:FindFirstChild(name)
		if remote and remote:IsA("RemoteEvent") then
			if event then
				remote:FireServer(event)
			else
				remote:FireServer()
			end
			return
		end
		if mockEnabled and not realState() then
			if name == "SkipTutorial" then
				mock.done = true
			elseif event == "openedCollection" and mock.step == "collection" then
				mock.step = "workshop"
			elseif event == "openedWorkshop" and mock.step == "workshop" then
				mock.step = "training"
			end
			refresh()
		end
	end

	skip.Activated:Connect(function()
		send("SkipTutorial", nil)
	end)
	Hud.panelChanged:Connect(function(name: string)
		if step ~= "" then
			if name == "Collection" then
				send("TutorialEvent", "openedCollection")
			end
			if name == "Shop" then
				send("TutorialEvent", "openedWorkshop")
			end
		end
		refresh()
	end)
	Hud.fishingChanged:Connect(refresh)
	Data.changed:Connect(refresh)
	player:GetAttributeChangedSignal("CatchRevealActive"):Connect(refresh)
	player:GetAttributeChangedSignal("Coins"):Connect(refresh)
	player:GetAttributeChangedSignal("TrainingStat"):Connect(function()
		if
			mockEnabled
			and mock.step == "training"
			and player:GetAttribute("TrainingStat") ~= ""
		then
			mock.done = true
			refresh()
		end
	end)
	for _, tag in { "FishingZone", "TrainingSpot", "WorkshopSpot" } do
		CollectionService:GetInstanceAddedSignal(tag):Connect(refresh)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(refresh)
	end
	if mockEnabled then
		local fishing = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent
		fishing.OnClientEvent:Connect(function(update: Net.FishingUpdate)
			if realState() or mock.done then
				return
			end
			if update.event == "cast" and mock.step == "goToPier" then
				mock.step = "cast"
			end
			if update.event == "bite" and mock.step == "cast" then
				mock.step = "fight"
			end
			if update.event == "caught" and mock.step == "fight" then
				mock.step = "collection"
			end
			refresh()
		end)
	end
	task.spawn(function()
		while gui.Parent do
			if step == "goToPier" then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local zone = CollectionService:GetTagged("FishingZone")[1]
				local inside = false
				if root and root:IsA("BasePart") and zone and zone:IsA("BasePart") then
					local position = zone.CFrame:PointToObjectSpace(root.Position)
					local half = zone.Size * 0.5
					inside = math.abs(position.X) <= half.X
						and math.abs(position.Y) <= half.Y
						and math.abs(position.Z) <= half.Z
				end
				if inside ~= atPier then
					atPier = inside
					refresh()
				end
			end
			task.wait(0.25)
		end
	end)
	refresh()
end

return Tutorial
