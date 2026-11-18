--!strict
-- Robux purchases. The only ProcessReceipt in the game:
--   * idempotent: each PurchaseId is granted once (recorded in the profile)
--   * the grant is saved in the profile BEFORE returning PurchaseGranted
--   * profile not loaded yet -> NotProcessedYet (Roblox retries later)
-- Game passes are checked on join and on in-session purchase, cached as attributes.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Products = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Products")
)

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local MAX_RECORDED_PURCHASES = 200

local Monetization = {}
Monetization.order = 25

function Monetization.hasPass(player: Player, key: string): boolean
	return player:GetAttribute(Products.passAttribute(key)) == true
end

function Monetization.ownsAutoFish(player: Player): boolean
	if not Products.pass("autoFish") then
		return false
	end
	if RunService:IsStudio() and player:GetAttribute("DevAutoFish") == true then
		return true
	end
	return Monetization.hasPass(player, "autoFish")
end

local function publishAutoFish(player: Player)
	player:SetAttribute(Products.AUTO_FISH_OWNED_ATTRIBUTE, Monetization.ownsAutoFish(player))
end

function Monetization.coinMultiplier(player: Player): number
	local mult = 1
	for _, pass in Products.PASSES do
		if pass.coinMultiplier and Monetization.hasPass(player, pass.key) then
			mult *= pass.coinMultiplier
		end
	end
	return mult
end

function Monetization.luckBoostActive(player: Player): boolean
	local profile = PlayerData.get(player)
	return profile ~= nil and profile.boosts ~= nil and (profile.boosts.luckUntil or 0) > os.time()
end

local function publishBoost(player: Player)
	local profile = PlayerData.get(player)
	player:SetAttribute(
		Products.LUCK_BOOST_ATTRIBUTE,
		if profile then profile.boosts.luckUntil else 0
	)
end

local function checkPasses(player: Player)
	for _, pass in Products.PASSES do
		if pass.id ~= 0 then
			local ok, owns = pcall(
				MarketplaceService.UserOwnsGamePassAsync,
				MarketplaceService,
				player.UserId,
				pass.id
			)
			player:SetAttribute(Products.passAttribute(pass.key), ok and owns == true)
		else
			player:SetAttribute(Products.passAttribute(pass.key), false)
		end
	end
	publishAutoFish(player)
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local profile = player and PlayerData.get(player)
	if not player or not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receipt.PurchaseId)
	if profile.purchases[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local product = Products.byProductId(receipt.ProductId)
	if not product then
		warn(`[Monetization] unknown product {receipt.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	PlayerData.update(player, function(p)
		p.purchases[purchaseId] = true
		p.purchaseOrder = p.purchaseOrder or {}
		table.insert(p.purchaseOrder, purchaseId)
		-- Keep the record bounded; old ids can't be redelivered after this many purchases.
		while #p.purchaseOrder > MAX_RECORDED_PURCHASES do
			p.purchases[table.remove(p.purchaseOrder, 1) :: string] = nil
		end
		if product.coins then
			p.coins += product.coins
		end
		if product.boost == "luck" and product.boostSeconds then
			p.boosts.luckUntil = math.max(p.boosts.luckUntil, os.time()) + product.boostSeconds
		end
	end)
	publishBoost(player)
	if product.coins then
		Analytics.coins(player, true, product.coins, "Robux", product.key)
	end

	-- ProfileStore saves on its own schedule; ask for a save now so the grant is durable
	-- before telling Roblox the purchase is done.
	if not PlayerData.saveNow(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetization.start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then
			for _, pass in Products.PASSES do
				if pass.id == passId then
					player:SetAttribute(Products.passAttribute(pass.key), true)
				end
			end
			publishAutoFish(player)
		end
	end)
	local function onPlayer(player: Player)
		publishAutoFish(player)
		if RunService:IsStudio() then
			player:GetAttributeChangedSignal("DevAutoFish"):Connect(function()
				publishAutoFish(player)
			end)
		end
		task.spawn(checkPasses, player)
		task.spawn(function()
			PlayerData.wait(player)
			publishBoost(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return Monetization
