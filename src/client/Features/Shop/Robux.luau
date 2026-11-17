--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Products = require(Shared:WaitForChild("Config"):WaitForChild("Products"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Text = require(Shared:WaitForChild("StringsUi")).robux
local Hud = require(script.Parent.Parent:WaitForChild("Hud"))
local Panel = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("Panel"))

local Robux = {}
local player = Players.LocalPlayer
local vip = Products.passAttribute("vip")
local offerAvailable = "PaidLuckOfferAvailable"

function Robux.start()
	local gui, body = Panel.create("Robux", Text.title, Theme.gold)
	local function row(
		title: string,
		description: string,
		id: number,
		pass: boolean,
		reason: string?
	)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 86)
		Theme.surface(card, Theme.gold, 11, Theme.ink)
		card.Parent = body
		local name = Panel.label(card, title, 17, Theme.gold)
		name.Size = UDim2.fromScale(0.64, 0.34)
		name.Position = UDim2.fromScale(0.025, 0.05)
		local info = Panel.label(card, description, 13, Theme.muted)
		info.Size = UDim2.fromScale(0.64, 0.53)
		info.Position = UDim2.fromScale(0.025, 0.41)
		if id == 0 or reason then
			local state = Panel.label(card, reason or Text.unavailable, 14)
			state.Name = "OfferStatus"
			state.Size = UDim2.fromScale(0.30, 0.75)
			state.Position = UDim2.fromScale(0.68, 0.125)
			return
		end
		local button = Panel.button(card, Text.price, Theme.gold)
		button.Size = UDim2.new(0.3, 0, 0, 44)
		button.Position = UDim2.new(0.68, 0, 0.5, -22)
		button.TextWrapped = true
		button.TextSize = 13
		button.Activated:Connect(function()
			local ok = pcall(function()
				if pass then
					MarketplaceService:PromptGamePassPurchase(player, id)
				else
					MarketplaceService:PromptProductPurchase(player, id)
				end
			end)
			if not ok then
				Hud.toast(Text.promptFailed, Theme.rose)
			end
		end)
	end
	local function render()
		body:ClearAllChildren()
		Panel.stack(body)
		local back = Panel.button(body, Text.workshop, Theme.crystal)
		back.Name = "BackToWorkshop"
		back.LayoutOrder = -1
		back.Activated:Connect(function()
			Hud.showPanel("Shop")
		end)
		for _, product in Products.PRODUCTS do
			if product.coins then
				row(
					string.format(Text.coins, product.coins),
					Text.coinsDescription,
					product.id,
					false,
					nil
				)
			elseif product.boost == "luck" then
				local allowed = player:GetAttribute(offerAvailable) == true
				row(
					Text.luck,
					string.format(
						Text.luckDescription,
						math.floor((product.boostSeconds or 0) / 60),
						Products.LUCK_BOOST_MULTIPLIER
					),
					product.id,
					false,
					if allowed then nil else Text.unavailable
				)
			end
		end
		for _, pass in Products.PASSES do
			if pass.key == "vip" then
				row(
					Text.vip,
					string.format(
						Text.vipDescription,
						math.round(((pass.coinMultiplier or 1) - 1) * 100)
					),
					pass.id,
					true,
					if player:GetAttribute(vip) == true then Text.owned else nil
				)
			end
		end
	end
	Hud.panelChanged:Connect(function(name: string)
		local visible = name == "Robux"
		if gui.Enabled == visible then
			return
		end
		gui.Enabled = visible
		if visible then
			render()
		else
			body:ClearAllChildren()
		end
	end)
	for _, attribute in { vip, offerAvailable } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			if gui.Enabled then
				render()
			end
		end)
	end
end
return Robux
