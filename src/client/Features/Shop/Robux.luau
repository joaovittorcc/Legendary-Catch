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
local StarterOffer = require(script.Parent:WaitForChild("StarterOffer"))

local Robux = {}
local player = Players.LocalPlayer
local vip = Products.passAttribute("vip")
local offerAvailable = "PaidLuckOfferAvailable"

function Robux.start()
	local gui, body = Panel.create("Robux", Text.title, Theme.gold)
	local timer: TextLabel? = nil
	local function row(
		title: string,
		description: string,
		id: number,
		pass: boolean,
		reason: string?,
		duration: (() -> number)?
	): TextLabel?
		local card = Panel.card(body, Theme.gold, if duration then 114 else 94)
		local name = Panel.label(card, title, 17, Theme.ink)
		name.Size = UDim2.fromScale(0.64, 0.34)
		name.Position = UDim2.fromScale(0.025, 0.05)
		name.TextStrokeTransparency = 1
		local info = Panel.label(card, description, 13, Theme.ink)
		info.TextStrokeTransparency = 1
		info.Size = UDim2.fromScale(0.64, if duration then 0.37 else 0.53)
		info.Position = UDim2.fromScale(0.025, if duration then 0.34 else 0.41)
		local countdown: TextLabel? = nil
		if duration then
			local label = Panel.label(card, "", 13, Theme.wood)
			label.Name = "OfferCountdown"
			label.Size = UDim2.fromScale(0.60, 0.2)
			label.Position = UDim2.fromScale(0.045, 0.74)
			label.TextStrokeTransparency = 1
			Theme.surface(label, Theme.gold, 10, Theme.gold:Lerp(Theme.cream, 0.6))
			countdown = label
		end
		if id == 0 or reason then
			local state = Panel.label(card, reason or Text.unavailable, 14)
			state.Name = "OfferStatus"
			state.Size = UDim2.fromScale(0.30, 0.75)
			state.Position = UDim2.fromScale(0.68, 0.125)
			return countdown
		end
		local button = Panel.button(card, Text.price, Theme.gold)
		button.Size = UDim2.new(0.3, 0, 0, 44)
		button.Position = UDim2.new(0.68, 0, 0.5, -22)
		button.TextWrapped = true
		button.TextSize = 13
		button.Activated:Connect(function()
			if duration and duration() <= 0 then
				return
			end
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
		return countdown
	end
	local function updateTimer()
		local label = timer
		if not label then
			return
		end
		label.Text = string.format(Text.offerEnds, StarterOffer.clock(StarterOffer.remaining()))
	end
	local function render()
		timer = nil
		body:ClearAllChildren()
		Panel.stack(body)
		local back = Panel.button(body, Text.workshop, Theme.crystal)
		back.Name = "BackToWorkshop"
		back.LayoutOrder = -1
		back.Activated:Connect(function()
			Hud.showPanel("Shop")
		end)
		for _, product in Products.PRODUCTS do
			if product.key == "starterPack" then
				if product.id > 0 and product.coins and product.coins > 0 then
					local owned = player:GetAttribute(StarterOffer.ownedAttribute) == true
					local canBuy = StarterOffer.remaining() > 0
					if canBuy or owned then
						timer = row(
							Text.starterPack,
							string.format(Text.starterContents, product.coins),
							product.id,
							false,
							if owned then Text.owned else nil,
							if canBuy then StarterOffer.remaining else nil
						)
					end
				end
			elseif product.coins then
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
		updateTimer()
	end
	Hud.panelChanged:Connect(function(name: string)
		local visible = name == "Robux"
		if visible then
			render()
		else
			timer = nil
			body:ClearAllChildren()
		end
	end)
	for _, attribute in
		{
			vip,
			offerAvailable,
			StarterOffer.availableAttribute,
			StarterOffer.ownedAttribute,
			StarterOffer.endsAtAttribute,
		}
	do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			if gui.Enabled then
				render()
			end
		end)
	end
	task.spawn(function()
		while gui.Parent do
			task.wait(1)
			if gui.Enabled and timer then
				if StarterOffer.remaining() <= 0 then
					render()
				else
					updateTimer()
				end
			end
		end
	end)
end
return Robux
