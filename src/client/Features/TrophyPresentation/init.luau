--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local TAG = "TrophyPedestal"
local player = Players.LocalPlayer
local TrophyPresentation = {}

type DisplayState = {
	connections: { RBXScriptConnection },
	model: Model?,
	pivot: CFrame?,
	center: Vector3?,
	angle: number,
}

local function styleSign(sign: BillboardGui, color: Color3, rarity: string?, shiny: boolean)
	local caption = sign:FindFirstChildOfClass("TextLabel")
	if not caption then
		return
	end

	local plate = sign:FindFirstChild("LocalTrophyPlate")
	if not plate or not plate:IsA("Frame") then
		local frame = Instance.new("Frame")
		frame.Name = "LocalTrophyPlate"
		frame.Size = UDim2.fromScale(1, 1)
		frame.ZIndex = 1
		Theme.surface(frame, color, 11, Theme.ink)
		local badge = Instance.new("TextLabel")
		badge.Name = "ShinyBadge"
		badge.AnchorPoint = Vector2.new(0.5, 0)
		badge.Position = UDim2.new(0.75, 0, 0, 7)
		badge.Size = UDim2.fromOffset(112, 19)
		badge.ZIndex = 3
		badge.BackgroundColor3 = Theme.gold
		badge.TextColor3 = Theme.ink
		badge.Text = "✦ " .. Text.shiny
		badge.TextSize = 13
		badge.Font = Theme.font
		badge.BorderSizePixel = 0
		Theme.corner(badge, 7)
		badge.Parent = frame
		local rank = Instance.new("TextLabel")
		rank.Name = "Rarity"
		rank.AnchorPoint = Vector2.new(0.5, 0)
		rank.Size = UDim2.fromOffset(136, 19)
		rank.BackgroundTransparency = 1
		rank.TextColor3 = Theme.sand
		rank.Font = Theme.font
		rank.TextSize = 14
		rank.ZIndex = 3
		rank.Parent = frame
		frame.Parent = sign
		plate = frame
	end
	local styledPlate = assert(plate, "Trophy plate was not created")
	local rim = styledPlate:FindFirstChildWhichIsA("UIStroke")
	if rim then
		rim.Color = color
	end
	local badge = styledPlate:FindFirstChild("ShinyBadge")
	if badge and badge:IsA("GuiObject") then
		badge.Visible = shiny
	end

	local rank = styledPlate:FindFirstChild("Rarity")
	if rank and rank:IsA("TextLabel") then
		rank.Text = if rarity then Theme.rarityLabel(rarity) else ""
		rank.Position = UDim2.new(if shiny then 0.28 else 0.5, 0, 0, 7)
	end
	local hasHeader = shiny or rarity ~= nil
	sign.Size = UDim2.fromOffset(268, if hasHeader then 94 else 70)
	caption.ZIndex = 2
	caption.Position = UDim2.fromOffset(10, if hasHeader then 30 else 7)
	caption.Size = UDim2.new(1, -20, 1, if hasHeader then -36 else -14)
	caption.TextColor3 = Theme.sand
	caption.TextStrokeColor3 = Color3.new(0, 0, 0)
	caption.TextStrokeTransparency = 0.48
	-- The server and WorldText keep ownership of the caption's content.
end

function TrophyPresentation.start()
	local active: { [BasePart]: DisplayState } = {}
	local function unwatch(instance: Instance)
		if not instance:IsA("BasePart") then
			return
		end
		local state = active[instance]
		if not state then
			return
		end
		for _, connection in state.connections do
			connection:Disconnect()
		end
		local model, pivot = state.model, state.pivot
		if model and pivot and model.Parent then
			model:PivotTo(pivot)
		end
		active[instance] = nil
	end

	local function watch(instance: Instance)
		if not instance:IsA("BasePart") or active[instance] then
			return
		end
		local state: DisplayState =
			{ connections = {}, model = nil, pivot = nil, center = nil, angle = 0 }
		active[instance] = state
		local queued = false
		local function refresh()
			if queued then
				return
			end
			queued = true
			task.defer(function()
				queued = false
				if active[instance] ~= state then
					return
				end
				local display = instance:FindFirstChild("TrophyDisplay")
				local id = instance:GetAttribute("TrophyCreature")
				local creature = if typeof(id) == "string" then Creatures.get(id) else nil
				local color = if creature
					then Theme.rarity[creature.rarity] or Theme.gold
					else Theme.gold
				local sign = display and display:FindFirstChild("TrophySign")
				if sign and sign:IsA("BillboardGui") then
					styleSign(
						sign,
						color,
						if creature then creature.rarity else nil,
						instance:GetAttribute("TrophyVariant") == "Shiny"
					)
				end
				local model = display and display:FindFirstChildOfClass("Model")
				if model and not model:FindFirstChildWhichIsA("BasePart", true) then
					model = nil
				end
				if model ~= state.model then
					state.model = model
					state.pivot = if model then model:GetPivot() else nil
					state.center = if model then select(1, model:GetBoundingBox()).Position else nil
					state.angle = 0
				end
			end)
		end
		table.insert(
			state.connections,
			instance:GetAttributeChangedSignal("TrophyCreature"):Connect(refresh)
		)
		table.insert(
			state.connections,
			instance:GetAttributeChangedSignal("TrophyVariant"):Connect(refresh)
		)
		table.insert(state.connections, instance.DescendantAdded:Connect(refresh))
		table.insert(state.connections, instance.DescendantRemoving:Connect(refresh))
		refresh()
	end

	CollectionService:GetInstanceAddedSignal(TAG):Connect(watch)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(unwatch)
	for _, item in CollectionService:GetTagged(TAG) do
		watch(item)
	end

	player:GetAttributeChangedSignal("ReduceEffects"):Connect(function()
		if player:GetAttribute("ReduceEffects") ~= true then
			return
		end
		for _, state in active do
			local model, pivot = state.model, state.pivot
			if model and pivot and model.Parent then
				model:PivotTo(pivot)
			end
			state.angle = 0
		end
	end)

	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < 1 / 30 then
			return
		end
		local delta = accumulated
		accumulated = 0
		local camera = workspace.CurrentCamera
		if not camera or player:GetAttribute("ReduceEffects") == true then
			return
		end
		for pedestal, state in active do
			local model, pivot, center = state.model, state.pivot, state.center
			if
				model
				and model.Parent
				and pivot
				and center
				and (camera.CFrame.Position - pedestal.Position).Magnitude < 82
			then
				state.angle = (state.angle + math.min(delta, 0.15) * 0.48) % (math.pi * 2)
				model:PivotTo(
					CFrame.new(center)
						* CFrame.Angles(0, state.angle, 0)
						* CFrame.new(-center)
						* pivot
				)
			end
		end
	end)
end

return TrophyPresentation
