--!strict
-- Social layer: leaderstats in the player list (coins, catches) and a server-wide
-- announcement for big catches so everyone in the server shares the moment.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local Net = require(Shared:WaitForChild("Net"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

local Social = {}
Social.order = 60

local announceRemote: RemoteEvent

local function value(folder: Folder, name: string): IntValue
	local v = Instance.new("IntValue")
	v.Name = name
	v.Parent = folder
	return v
end

local function setupLeaderstats(player: Player)
	local profile = PlayerData.wait(player)
	if not profile or not player.Parent then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats" -- exact name Roblox's player list looks for
	local coins = value(folder, "Coins")
	local catches = value(folder, "Catches")
	local function refresh()
		local p = PlayerData.get(player)
		if p then
			coins.Value = p.coins
			catches.Value = p.stats.catches
		end
	end
	refresh()
	folder.Parent = player
	-- Coins is mirrored on every profile change, so it doubles as the change signal.
	player:GetAttributeChangedSignal("Coins"):Connect(refresh)
end

-- Called by Fishing after a catch is paid.
function Social.onCatch(player: Player, creature: Creatures.Creature, variant: string)
	local big = creature.rarity == "Legendary"
		or (variant == "Shiny" and (creature.rarity == "Epic"))
	if not big then
		return
	end
	local payload: Net.CatchAnnounce = {
		userId = player.UserId,
		displayName = player.DisplayName,
		creatureId = creature.id,
		rarity = creature.rarity,
		variant = variant,
	}
	announceRemote:FireAllClients(payload)
end

function Social.start()
	announceRemote = Remotes.event(Net.CATCH_ANNOUNCE)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(setupLeaderstats, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(setupLeaderstats, player)
	end
end

return Social
