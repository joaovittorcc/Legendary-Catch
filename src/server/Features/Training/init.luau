--!strict
-- Lagoon training (server authority). Any part tagged TrainingSpot gets two prompts
-- (Control / Instinct). While training, XP ticks in every second; now and then a rhythm
-- ring event is offered for bonus XP. Walking away from the spot stops it.
--
-- Levels live in the player profile (PlayerData); the profile mirrors them as attributes.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

type Session = {
	stat: string,
	spot: BasePart,
	nextRingAt: number,
	ringId: number,
	ringExpires: number, -- 0 when no ring is pending
}

local Training = {}
Training.order = 40

local sessions: { [Player]: Session } = {}
local rng = Random.new()
local update: RemoteEvent

local function level(player: Player, stat: string): number
	local profile = PlayerData.get(player)
	local t = profile and profile.training[stat]
	return if t then t.level else 0
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function near(player: Player, spot: BasePart): boolean
	local root = rootOf(player)
	return root ~= nil and (root.Position - spot.Position).Magnitude <= TrainingConfig.SPOT_RADIUS
end

local function stop(player: Player, reason: string)
	if not sessions[player] then
		return
	end
	sessions[player] = nil
	player:SetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE, "")
	update:FireClient(player, { event = "stopped", reason = reason } :: Net.TrainingUpdate)
end

local function addXp(player: Player, stat: string, amount: number)
	local profile = PlayerData.get(player)
	local t = profile and profile.training[stat]
	if not t or t.level >= TrainingConfig.MAX_LEVEL then
		return
	end
	local lvl = t.level
	local total = t.xp + amount
	while lvl < TrainingConfig.MAX_LEVEL and total >= TrainingConfig.xpToNext(lvl) do
		total -= TrainingConfig.xpToNext(lvl)
		lvl += 1
		update:FireClient(
			player,
			{ event = "levelUp", stat = stat, level = lvl } :: Net.TrainingUpdate
		)
	end
	if lvl >= TrainingConfig.MAX_LEVEL then
		total = 0
	end
	PlayerData.update(player, function(p)
		p.training[stat] = { level = lvl, xp = total }
	end)
end

local function start(player: Player, stat: string, spot: BasePart)
	if not near(player, spot) or not PlayerData.get(player) then
		return
	end
	sessions[player] = {
		stat = stat,
		spot = spot,
		nextRingAt = os.clock()
			+ rng:NextNumber(TrainingConfig.RING_INTERVAL_MIN, TrainingConfig.RING_INTERVAL_MAX),
		ringId = 0,
		ringExpires = 0,
	}
	player:SetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE, stat)
	Analytics.step(player, "firstTraining")
end

local function addPrompts(spot: Instance)
	if not spot:IsA("BasePart") then
		return
	end
	for i, stat in TrainingConfig.STATS do
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Train" .. stat
		prompt.ActionText = `{Strings.trainAction} {Strings.stat[stat] or stat}`
		prompt.ObjectText = Strings.statHelp[stat] or Strings.trainingSpot
		prompt.KeyboardKeyCode = if i == 1 then Enum.KeyCode.E else Enum.KeyCode.R
		prompt.GamepadKeyCode = if i == 1 then Enum.KeyCode.ButtonX else Enum.KeyCode.ButtonY
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.UIOffset = Vector2.new(0, (i - 1) * -72)
		prompt.Triggered:Connect(function(player)
			start(player, stat, spot)
		end)
		prompt.Parent = spot
	end
end

local function step()
	local now = os.clock()
	for player, s in sessions do
		if not near(player, s.spot) then
			stop(player, "left")
			continue
		end
		addXp(player, s.stat, TrainingConfig.XP_PER_SECOND)

		if s.ringExpires > 0 and now > s.ringExpires then
			s.ringExpires = 0
		end
		if s.ringExpires == 0 and now >= s.nextRingAt then
			s.ringId += 1
			s.ringExpires = now + TrainingConfig.RING_TIMEOUT
			s.nextRingAt = now
				+ rng:NextNumber(TrainingConfig.RING_INTERVAL_MIN, TrainingConfig.RING_INTERVAL_MAX)
			local rings = if level(player, s.stat) >= 10 then 2 else 1
			update:FireClient(
				player,
				{ event = "ring", ringId = s.ringId, rings = rings, stat = s.stat } :: Net.TrainingUpdate
			)
		end
	end
end

local function onRingResult(player: Player, ringId: unknown, success: unknown)
	if typeof(ringId) ~= "number" or typeof(success) ~= "boolean" then
		return
	end
	local s = sessions[player]
	if not s or s.ringExpires == 0 or s.ringId ~= ringId then
		return
	end
	s.ringExpires = 0
	if success then
		addXp(player, s.stat, TrainingConfig.ringBonus(level(player, s.stat)))
	end
end

-- Used by fishing: the player's current level in a stat (0 if never trained).
function Training.level(player: Player, stat: string): number
	return level(player, stat)
end

function Training.start()
	update = Remotes.event(Net.TRAINING_UPDATE)
	Remotes.onServerEvent(Net.STOP_TRAINING, 2, 3, function(player)
		stop(player, "manual")
	end)
	Remotes.onServerEvent(Net.TRAINING_RING_RESULT, 2, 3, onRingResult)

	local function initPlayer(player: Player)
		player:SetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE, "")
		player.CharacterRemoving:Connect(function()
			stop(player, "respawn")
		end)
	end
	Players.PlayerAdded:Connect(initPlayer)
	for _, player in Players:GetPlayers() do
		initPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)

	-- The map is rebuilt in Studio, so spots can appear after start.
	for _, spot in CollectionService:GetTagged(TrainingConfig.SPOT_TAG) do
		addPrompts(spot)
	end
	CollectionService:GetInstanceAddedSignal(TrainingConfig.SPOT_TAG):Connect(addPrompts)
	if #CollectionService:GetTagged(TrainingConfig.SPOT_TAG) == 0 then
		warn(`[Training] no part tagged "{TrainingConfig.SPOT_TAG}" in the map yet`)
	end

	task.spawn(function()
		while true do
			task.wait(1)
			step()
		end
	end)
end

return Training
