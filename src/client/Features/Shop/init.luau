--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi"))
local Strings = require(Shared:WaitForChild("Strings"))
local Net = require(Shared:WaitForChild("Net"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent:WaitForChild("Hud"):WaitForChild("Panel"))
local Data = require(script.Parent.Parent:WaitForChild("Data"))

local Robux = require(script:WaitForChild("Robux"))
local Shop = {}

local function preview(parent: Instance, rod: Rods.Rod)
	local view = Instance.new("ViewportFrame")
	view.BackgroundColor3 = Theme.ink
	view.Size = UDim2.fromScale(0.28, 0.86)
	view.Position = UDim2.fromScale(0.025, 0.07)
	Theme.corner(view, 10)
	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, 11), Vector3.zero)
	camera.Parent = view
	view.CurrentCamera = camera

	local pose = CFrame.Angles(0.2, 0, -0.6)
	local function part(name: string, size: Vector3, position: Vector3, tint: Color3)
		local piece = Instance.new("Part")
		piece.Name = name
		piece.Size = size
		piece.Color = tint
		piece.CFrame = pose * CFrame.new(position)
		piece.Anchored = true
		piece.Parent = view
	end
	part("Handle", Vector3.new(0.35, 1.1, 0.35), Vector3.new(0, -1.55, 0), Theme.wood)
	part("Blank", Vector3.new(0.19, 3.4, 0.19), Vector3.new(0, 0.61, 0), rod.color)
	part("Reel", Vector3.new(0.48, 0.55, 0.46), Vector3.new(0.31, -0.91, 0), Theme.gold)
	part("Tip", Vector3.new(0.24, 0.24, 0.24), Vector3.new(0, 2.3, 0), rod.tipColor)
	for n = 1, 3 do
		part("Guide", Vector3.new(0.28, 0.08, 0.27), Vector3.new(0, n * 0.68, 0), Theme.gold)
	end
	view.Parent = parent
end

function Shop.start()
	Robux.start()
	local gui, scroll = Panel.create("Shop", Text.shop, Theme.gold)
	local body = Instance.new("Frame")
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Size = UDim2.fromScale(1, 0)
	body.BackgroundTransparency = 1
	body.Parent = scroll
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local pending = ""
	local function render()
		body:ClearAllChildren()
		Panel.stack(body)
		Panel.button(body, Text.robux.title, Theme.gold).Activated:Connect(function()
			Hud.showPanel("Robux")
		end)
		local snapshot = Data.get()
		if not snapshot then
			Panel.label(body, Text.loading, 18)
			return
		end
		for _, rod in Rods.LIST do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 118)
			Theme.surface(row, rod.tipColor, 12)
			preview(row, rod)
			local title = Panel.label(row, Strings.rodName[rod.id] or rod.id, 19, rod.tipColor)
			title.Position = UDim2.fromScale(0.33, 0.035)
			title.Size = UDim2.fromScale(0.64, 0.23)
			local bonus = Panel.label(
				row,
				string.format(
					"%s +%.0f%%  ·  %s +%.0f%%",
					Text.control,
					rod.controlBonus * 100,
					Text.luck,
					rod.luckBonus * 100
				),
				14
			)
			bonus.Position = UDim2.fromScale(0.33, 0.29)
			bonus.Size = UDim2.fromScale(0.64, 0.2)

			local owned = table.find(snapshot.rodsOwned, rod.id) ~= nil
			local equipped = snapshot.equippedRod == rod.id
			local button = Panel.button(
				row,
				if equipped
					then Text.equipped
					elseif owned then Text.equip
					else string.format("%s  ·  %d ◆", Text.buy, rod.price),
				if equipped then Theme.crystal else Theme.gold
			)
			button.Position = UDim2.fromScale(0.39, 0.53)
			button.Size = UDim2.new(0.52, 0, 0, 46)
			button.Activated:Connect(function()
				if equipped or pending ~= "" then
					return
				end
				local remote = remotes:FindFirstChild(if owned then Net.EQUIP_ROD else Net.BUY_ROD)
				if not remote or not remote:IsA("RemoteEvent") then
					Hud.toast(Text.unavailable)
					return
				end
				pending = rod.id
				remote:FireServer(rod.id)
				task.delay(5, function()
					if pending == rod.id then
						pending = ""
					end
				end)
			end)
			row.Parent = body
		end
	end

	Hud.panelChanged:Connect(function(name: string)
		gui.Enabled = name == "Shop"
		if gui.Enabled then
			render()
		else
			body:ClearAllChildren()
		end
	end)
	Data.changed:Connect(function()
		if gui.Enabled then
			render()
		end
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if player == Players.LocalPlayer and prompt.Name == "OpenWorkshop" then
			Hud.showPanel("Shop")
		end
	end)
	local result = remotes:WaitForChild(Net.SHOP_RESULT) :: RemoteEvent
	result.OnClientEvent:Connect(function(payload: Net.ShopResult)
		pending = ""
		Hud.toast(
			if payload.ok
				then (Strings.rodName[payload.rodId] or payload.rodId)
				else Text.shopErrors[payload.reason or "unknown"] or Text.unavailable,
			if payload.ok then Theme.crystal else Theme.rose
		)
	end)
end

return Shop
