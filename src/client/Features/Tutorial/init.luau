--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

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
local CARD_HEIGHT = 62
local CELEBRATE_HEIGHT = 104
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
	collection = "🎉",
	workshop = "🛠️",
	training = "✨",
}

local function findGuideTarget(tag: string): BasePart?
	local tagged = CollectionService:GetTagged(tag)
	if tag == "FishingZone" then
		for _, item in tagged do
			if item:IsA("BasePart") then
				local zoneId = item:GetAttribute("ZoneId")
				if zoneId == nil or zoneId == "" or zoneId == "lagoon" then
					return item
				end
			end
		end
	end
	for _, item in tagged do
		if item:IsA("BasePart") then
			return item
		end
	end
	return nil
end

local function spawnConfetti(parent: Instance, card: Frame)
	if player:GetAttribute("ReduceEffects") == true then
		return
	end
	local center = card.AbsolutePosition + card.AbsoluteSize * 0.5
	if card.AbsoluteSize.X <= 0 then
		return
	end
	local palette = {
		Theme.gold,
		Theme.crystal,
		Theme.rose,
		Color3.fromRGB(120, 230, 170),
	}
	for i = 1, 14 do
		local piece = Instance.new("Frame")
		piece.Name = "Confetti"
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Position = UDim2.fromOffset(center.X + math.random(-70, 70), center.Y)
		piece.Size = UDim2.fromOffset(math.random(6, 9), math.random(6, 9))
		piece.Rotation = math.random(-45, 45)
		piece.BackgroundColor3 = palette[((i - 1) % #palette) + 1]
		piece.BorderSizePixel = 0
		piece.ZIndex = 12
		Theme.corner(piece, 2)
		piece.Parent = parent

		local angle = ((i - 1) / 14) * math.pi * 2 + math.random() * 0.3
		local dist = math.random(65, 135)
		local goalPos = UDim2.fromOffset(
			center.X + math.cos(angle) * dist,
			center.Y + math.sin(angle) * (dist * 0.65) + 28
		)
		local tween = TweenService:Create(
			piece,
			TweenInfo.new(0.95, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = goalPos,
				Rotation = piece.Rotation + math.random(-180, 180),
				BackgroundTransparency = 1,
			}
		)
		tween.Completed:Once(function()
			piece:Destroy()
		end)
		tween:Play()
	end
end

local function createGuideBeam(): (Part, Beam)
	local holder = Instance.new("Part")
	holder.Name = "TutorialGuideBeam"
	holder.Size = Vector3.new(1, 1, 1)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CastShadow = false

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.2, 0)
	a0.Parent = holder

	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 26, 0)
	a1.Parent = holder

	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 2.4
	beam.Width1 = 0.7
	beam.FaceCamera = true
	beam.LightEmission = 0.85
	beam.LightInfluence = 0
	beam.Color = ColorSequence.new(Theme.crystal, Theme.gold)
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.6, 0.72),
		NumberSequenceKeypoint.new(1, 1),
	})
	beam.Enabled = false
	beam.Parent = holder
	return holder, beam
end

function Tutorial.start()
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local mockEnabled = RunService:IsStudio() and player:GetAttribute("DevMockTutorial") == true
	local mock: TutorialState = { step = "goToPier", done = false }
	local step = ""
	local atPier = false
	local celebratedFirstCatch = false
	local cardHeight = CARD_HEIGHT

	local gui = Instance.new("ScreenGui")
	gui.Name = "TutorialGuide"
	gui.DisplayOrder = 3
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local card = Instance.new("Frame")
	card.Name = "TutorialCard"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, Hud.navBottom() + 6)
	card.Size = UDim2.new(0.92, 0, 0, CARD_HEIGHT)
	card.Visible = false
	Art.panel(card, Theme.crystal)
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize = Vector2.new(412, CELEBRATE_HEIGHT)
	bounds.Parent = card
	local iconHolder = Instance.new("TextButton")
	iconHolder.Name = "StepIcon"
	iconHolder.Text = ""
	iconHolder.AutoButtonColor = false
	iconHolder.AnchorPoint = Vector2.new(0, 0.5)
	iconHolder.Position = UDim2.fromOffset(14, CARD_HEIGHT / 2)
	iconHolder.Size = UDim2.fromOffset(38, 38)
	iconHolder.BackgroundColor3 = Theme.cream
	iconHolder.BorderSizePixel = 0
	iconHolder.ZIndex = 3
	Theme.corner(iconHolder, 19)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Theme.outline
	iconStroke.Thickness = 2
	iconStroke.Parent = iconHolder
	local stepIcon = Panel.label(iconHolder, "🧭", 22)
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
	local message = Panel.label(card, "", 15)
	message.Size = UDim2.new(1, -162, 1, -18)
	message.TextScaled = true
	message.TextStrokeTransparency = 1
	message.TextXAlignment = Enum.TextXAlignment.Left
	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MinTextSize = 11
	textLimit.MaxTextSize = 16
	textLimit.Parent = message
	message.Position = UDim2.fromOffset(58, 9)
	local celebrateTitle = Panel.label(card, Text.firstCatchBanner, 16, Theme.wood)
	celebrateTitle.Name = "CelebrateTitle"
	celebrateTitle.Position = UDim2.fromOffset(58, 12)
	celebrateTitle.Size = UDim2.new(1, -162, 0, 26)
	celebrateTitle.TextStrokeTransparency = 1
	celebrateTitle.TextXAlignment = Enum.TextXAlignment.Left
	celebrateTitle.Visible = false
	local skip = Panel.button(card, Text.skip, Theme.gold)
	skip.Size = UDim2.fromOffset(78, 44)
	skip.AnchorPoint = Vector2.new(1, 0.5)
	skip.Position = UDim2.new(1, -14, 0.5, 0)
	local openAlbum = Panel.button(card, StringsUi.adventure.openAlbum, Theme.crystal)
	openAlbum.Name = "OpenAlbum"
	openAlbum.Size = UDim2.new(1, -162, 0, 44)
	openAlbum.Position = UDim2.fromOffset(58, 44)
	openAlbum.TextSize = 15
	openAlbum.Visible = false
	openAlbum.Activated:Connect(function()
		Hud.showPanel("Collection")
	end)
	card.Parent = gui
	local setCardVisible = Hud.bindFishingVisibility(card, false)

	local guide = Instance.new("BillboardGui")
	guide.Name = "TutorialDestination"
	guide.Size = UDim2.fromOffset(136, 52)
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

	local beamHolder, beam = createGuideBeam()
	local beamConn: RBXScriptConnection? = nil

	local function stopBeamBob()
		if beamConn then
			beamConn:Disconnect()
			beamConn = nil
		end
	end

	gui.Destroying:Once(function()
		stopBeamBob()
		beamHolder:Destroy()
	end)

	local function publishLayout()
		local bottom = if gui.Enabled and card.Visible
			then card.Position.Y.Offset + cardHeight
			else 0
		if visibleBottom ~= bottom then
			visibleBottom = bottom
			layout:Fire()
		end
	end
	local function placeCard()
		local viewport = gui.AbsoluteSize
		local portrait = viewport.Y > viewport.X
		local tuckInTopBar = not portrait and viewport.X >= 900 and cardHeight == CARD_HEIGHT
		if tuckInTopBar then
			local pillWidth = math.min(396, math.floor(viewport.X * 0.34))
			card.Size = UDim2.fromOffset(pillWidth, cardHeight)
			card.Position = UDim2.new(0.5, 0, 0, 10)
		else
			card.Size = UDim2.new(if portrait then 0.92 else 0.5, 0, 0, cardHeight)
			card.Position = UDim2.new(0.5, 0, 0, Hud.navBottom() + 6)
		end
		iconHolder.Position = UDim2.fromOffset(10, cardHeight / 2)
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
		local reduced = player:GetAttribute("ReduceEffects") == true
		local training = player:GetAttribute("TrainingStat")
		local showCard = hint ~= nil
			and Hud.panel() == ""
			and not Hud.isMenuOpen()
			and not Hud.isFishingActive()
			and (training == nil or training == "")
			and player:GetAttribute("CatchRevealActive") ~= true
		local celebrating = showCard and step == "collection"
		cardHeight = if celebrating then CELEBRATE_HEIGHT else CARD_HEIGHT
		placeCard()
		setCardVisible(showCard)
		message.Text = hint or ""
		celebrateTitle.Visible = celebrating
		openAlbum.Visible = step == "collection"
		message.Visible = not openAlbum.Visible
		stepIcon.Text = icons[if step == "goToPier" and atPier then "cast" else step] or "🧭"
		iconHolder.Interactable = step == "collection"
		iconHolder.Selectable = iconHolder.Interactable

		if celebrating and not celebratedFirstCatch then
			celebratedFirstCatch = true
			if not reduced then
				local scale = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
				scale.Scale = 0.88
				scale.Parent = card
				TweenService:Create(
					scale,
					TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1 }
				):Play()
				task.defer(spawnConfetti, gui, card)
			end
		end

		local tag = if step == "workshop" and not affordable
			then "FishingZone"
			else destinations[step]
		local target = if tag then findGuideTarget(tag) else nil
		local showGuide = showCard and target ~= nil and not (step == "goToPier" and atPier)
		if target then
			guide.Adornee = target
		else
			guide.Adornee = nil :: any
		end
		guide.Enabled = showGuide
		setArrowVisible(showGuide)
		arrow.Text = (if tag then Text.destinations[tag] or "" else "") .. "\n▼"

		local showBeam = showGuide and target ~= nil and target:IsA("BasePart") and not reduced
		if showBeam and target and target:IsA("BasePart") then
			beamHolder.CFrame = CFrame.new(target.Position)
			beamHolder.Parent = Workspace
			beam.Enabled = true
			if not beamConn then
				beamConn = RunService.Heartbeat:Connect(function()
					guide.StudsOffsetWorldSpace =
						Vector3.new(0, 5 + math.sin(os.clock() * 3) * 0.55, 0)
				end)
			end
		else
			beam.Enabled = false
			beamHolder.Parent = nil
			stopBeamBob()
			guide.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
		end
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
	Hud.menuChanged:Connect(refresh)
	Data.changed:Connect(refresh)
	player:GetAttributeChangedSignal("CatchRevealActive"):Connect(refresh)
	player:GetAttributeChangedSignal("Coins"):Connect(refresh)
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(refresh)
	player:GetAttributeChangedSignal("TrainingStat"):Connect(function()
		if
			mockEnabled
			and mock.step == "training"
			and player:GetAttribute("TrainingStat") ~= ""
		then
			mock.done = true
		end
		refresh()
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
				local zone = findGuideTarget("FishingZone")
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
