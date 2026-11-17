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
		Panel.label(body, title, 19, Theme.gold).Size = UDim2.new(1, 0, 0, 32)
		Panel.label(body, description, 15, Theme.muted).Size = UDim2.new(1, 0, 0, 43)
		if id == 0 or reason then
			Panel.label(body, reason or Text.unavailable, 14).Size = UDim2.new(1, 0, 0, 28)
			return
		end
		local button = Panel.button(body, Text.price, Theme.gold)
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
		Panel.button(body, Text.workshop, Theme.crystal).Activated:Connect(function()
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
		gui.Enabled = name == "Robux"
		if gui.Enabled then
			render()
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
