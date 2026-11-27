--!strict
-- Fishing Power floating above every player's head. The server mirrors both power
-- attributes on the Player, so this only reads them and draws; the number pops when it grows.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Training = require(Shared:WaitForChild("Config"):WaitForChild("Training"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local OverheadPower = {
	order = 112,
}

local GUI_NAME = "OverheadPower"
-- Above the default name tag so the two never overlap.
local HEIGHT_STUDS = 2.9
local MAX_DISTANCE = 70

local localPlayer = Players.LocalPlayer
local watching: { [Player]: { RBXScriptConnection } } = {}
local OVERLAY_GUIS: { [string]: boolean } = {
	CatchShow = true,
	Roulette = true,
	OddsMoment = true,
	CatchPhoto = true,
}

local function overlayBlocking(): boolean
	if localPlayer:GetAttribute("CatchRevealActive") == true then
		return true
	end
	local pg = localPlayer:FindFirstChildOfClass("PlayerGui")
	if pg then
		for name in OVERLAY_GUIS do
			if pg:FindFirstChild(name) ~= nil then
				return true
			end
		end
	end
	return false
end

local function build(head: BasePart): (BillboardGui, TextLabel, UIScale)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = GUI_NAME
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(150, 34)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, HEIGHT_STUDS, 0)
	billboard.MaxDistance = MAX_DISTANCE
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false

	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Theme.font
	label.TextScaled = true
	label.Parent = billboard

	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 26
	limit.Parent = label

	local outline = Instance.new("UIStroke")
	outline.Color = Theme.ink
	outline.Thickness = 3
	outline.Parent = label

	local scale = Instance.new("UIScale")
	scale.Parent = label

	return billboard, label, scale
end

local function watch(player: Player)
	local controlAttribute = Training.powerAttribute("Control")
	local instinctAttribute = Training.powerAttribute("Instinct")
	local billboard: BillboardGui? = nil
	local label: TextLabel? = nil
	local scale: UIScale? = nil
	local lastTotal: number? = nil

	local function refresh()
		local gui, text = billboard, label
		if not gui or not text then
			return
		end
		local control = player:GetAttribute(controlAttribute)
		local instinct = player:GetAttribute(instinctAttribute)
		if typeof(control) ~= "number" or typeof(instinct) ~= "number" then
			gui.Enabled = false
			return
		end
		local total = control + instinct
		text.Text = "⚡ " .. Training.formatPower(total, Strings.decimalSep)
		text.TextColor3 = Training.TIER_COLORS[Training.tier(total)]
		-- Fullscreen catch overlays own the screen; hide overhead power while they play.
		gui.Enabled = not overlayBlocking()

		local pop = scale
		if
			pop
			and lastTotal
			and total > lastTotal
			and localPlayer:GetAttribute("ReduceEffects") ~= true
		then
			pop.Scale = 1.25
			TweenService:Create(
				pop,
				TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end
		lastTotal = total
	end

	local function onCharacter(character: Model)
		if billboard then
			billboard:Destroy()
			billboard = nil
		end
		local head = character:WaitForChild("Head", 15)
		if
			not head
			or not head:IsA("BasePart")
			or player.Character ~= character
			or not player.Parent
			or not watching[player]
		then
			return
		end
		billboard, label, scale = build(head)
		local playerGui = localPlayer:WaitForChild("PlayerGui")
		if billboard then
			billboard.Parent = playerGui
		end
		refresh()
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local function onOverlayChange(child: Instance)
		if OVERLAY_GUIS[child.Name] then
			refresh()
		end
	end
	watching[player] = {
		player.CharacterAdded:Connect(onCharacter),
		player.CharacterRemoving:Connect(function()
			if billboard then
				billboard:Destroy()
				billboard = nil
			end
		end),
		player:GetAttributeChangedSignal(controlAttribute):Connect(refresh),
		player:GetAttributeChangedSignal(instinctAttribute):Connect(refresh),
		localPlayer:GetAttributeChangedSignal("CatchRevealActive"):Connect(refresh),
		playerGui.ChildAdded:Connect(onOverlayChange),
		playerGui.ChildRemoved:Connect(onOverlayChange),
		player.AncestryChanged:Connect(function(_, parent: Instance?)
			if parent then
				return
			end
			if billboard then
				billboard:Destroy()
				billboard = nil
			end
			local connections: { RBXScriptConnection } = watching[player] or {}
			for _, connection in connections do
				connection:Disconnect()
			end
			watching[player] = nil
		end),
	}

	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

function OverheadPower.start()
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
end

return OverheadPower
