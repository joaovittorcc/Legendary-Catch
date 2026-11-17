--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi")).tutorial
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))

local Tutorial = {}
local CARD_HEIGHT = 60
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
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, Hud.navBottom() + 8)
	card.Size = UDim2.new(0.92, 0, 0, CARD_HEIGHT)
	card.Visible = false
	Art.panel(card, Theme.crystal)
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(630, CARD_HEIGHT)
	bounds.Parent = card
	local message = Panel.label(card, "", 14)
	message.Size = UDim2.new(1, -124, 1, -12)
	message.TextScaled = true
	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MaxTextSize = 20
	textLimit.Parent = message
	message.Position = UDim2.fromOffset(18, 6)
	local skip = Panel.button(card, Text.skip, Theme.gold)
	skip.Size = UDim2.fromOffset(88, 44)
	skip.AnchorPoint = Vector2.new(1, 0.5)
	skip.Position = UDim2.new(1, -17, 0.5, 0)
	card.Parent = gui

	local guide = Instance.new("BillboardGui")
	guide.Name = "TutorialDestination"
	guide.Size = UDim2.fromOffset(142, 56)
	guide.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	guide.AlwaysOnTop = true
	guide.Enabled = false
	local arrow = Panel.label(guide, "", 18, Theme.crystal)
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.TextStrokeTransparency = 0.22
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
	Hud.layoutChanged:Connect(function()
		card.Position = UDim2.fromOffset(0, Hud.navBottom() + 8) + UDim2.fromScale(0.5, 0)
		publishLayout()
	end)
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
		card.Visible = hint ~= nil
			and Hud.panel() == ""
			and player:GetAttribute("CatchRevealActive") ~= true
		message.Text = hint or ""
		local tag = if step == "workshop" and not affordable
			then "FishingZone"
			else destinations[step]
		local target = tag and CollectionService:GetTagged(tag)[1]
		guide.Adornee = if target and target:IsA("BasePart") then target else nil
		guide.Enabled = card.Visible and not not target
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
