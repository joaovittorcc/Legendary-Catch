--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Products = require(Config:WaitForChild("Products"))
local player = Players.LocalPlayer

local StarterOffer = {
	availableAttribute = "StarterOfferAvailable",
	ownedAttribute = "StarterPackOwned",
	endsAtAttribute = "StarterOfferEndsAt",
}

function StarterOffer.remaining(): number
	local product = Products.product("starterPack")
	local endsAt = player:GetAttribute(StarterOffer.endsAtAttribute)
	if
		not product
		or product.id <= 0
		or not product.coins
		or product.coins <= 0
		or player:GetAttribute(StarterOffer.availableAttribute) ~= true
		or player:GetAttribute(StarterOffer.ownedAttribute) == true
		or typeof(endsAt) ~= "number"
	then
		return 0
	end
	return math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
end

function StarterOffer.clock(seconds: number): string
	return string.format(
		"%02d:%02d:%02d",
		math.floor(seconds / 3600),
		math.floor(seconds / 60) % 60,
		seconds % 60
	)
end

return StarterOffer
