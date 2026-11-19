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

local Achievements = require(script.Parent:WaitForChild("Achievements"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Progress = require(script.Parent:WaitForChild("Progress"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

type Session = {
	stat: string,
	spot: BasePart,
	nextRingAt: number,
	ringId: number,
	ringExpires: number, -- 0 when no ring is pending
	combo: number,
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
	local character = player.Character
	local root = rootOf(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return root ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
		and (root.Position - spot.Position).Magnitude <= TrainingConfig.SPOT_RADIUS
end

local function stop(player: Player, reason: string)
	if not sessions[player] then
		return
	end
	sessions[player] = nil
	player:SetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE, "")
	player:SetAttribute("TrainingCombo", 0)
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
		-- Every 5th level pays coins (10 per level reached: level 10 = 100).
		local rewardCoins = if lvl % 5 == 0 then lvl * 10 else nil
		if rewardCoins then
			PlayerData.update(player, function(p)
				p.coins += rewardCoins
			end)
		end
		update:FireClient(
			player,
			{ event = "levelUp", stat = stat, level = lvl, rewardCoins = rewardCoins } :: Net.TrainingUpdate
		)
	end
	if lvl >= TrainingConfig.MAX_LEVEL then
		total = 0
	end
	PlayerData.update(player, function(p)
		p.training[stat] = { level = lvl, xp = total }
	end)
	if lvl > t.level then
		Achievements.check(player)
	end
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
		combo = 0,
	}
	player:SetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE, stat)
	player:SetAttribute("TrainingCombo", 0)
	-- First training of the (UTC) day: a bonus that grows a little with the stat level.
	local today = os.time() // 86400
	local profile = PlayerData.get(player)
	if profile and profile.stats.trainDay ~= today then
		PlayerData.update(player, function(p)
			p.stats.trainDay = today
		end)
		local bonus = 15 + level(player, stat) * 3
		addXp(player, stat, bonus)
		update:FireClient(
			player,
			{ event = "dailyBonus", stat = stat, bonusXp = bonus } :: Net.TrainingUpdate
		)
	end
	Analytics.step(player, "firstTraining")
	Progress.onTrainingStarted(player)
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
		Progress.onTrainSecond(player)

		if s.ringExpires > 0 and now > s.ringExpires then
			s.ringExpires = 0
			s.combo = 0
			player:SetAttribute("TrainingCombo", 0)
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
		s.combo += 1
		-- Streak of rings in a row: +10% bonus XP per step, up to +50%.
		local mult = 1 + math.min(s.combo - 1, 5) * 0.1
		addXp(player, s.stat, math.floor(TrainingConfig.ringBonus(level(player, s.stat)) * mult))
	else
		s.combo = 0
	end
	player:SetAttribute("TrainingCombo", s.combo)
end

-- Used by fishing: the player's current level in a stat (0 if never trained).
function Training.level(player: Player, stat: string): number
	return level(player, stat)
end

-- Used by portals: cleanly stops any active training session before teleporting.
function Training.stopFor(player: Player, reason: string?)
	stop(player, reason or "portal")
end

function Training.start()
	update = Remotes.event(Net.TRAINING_UPDATE)
	Remotes.onServerEvent(Net.STOP_TRAINING, 2, 3, function(player)
		stop(player, "manual")
	end)
	Remotes.onServerEvent(Net.TRAINING_RING_RESULT, 2, 3, onRingResult)

	local function initPlayer(player: Player)
		player:SetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE, "")
		local function watchCharacter(character: Model?)
			if not character then
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
				or character:WaitForChild("Humanoid", 5)
			if humanoid and humanoid:IsA("Humanoid") then
				humanoid.Died:Connect(function()
					stop(player, "respawn")
				end)
			end
		end
		if player.Character then
			task.spawn(watchCharacter, player.Character)
		end
		player.CharacterAdded:Connect(watchCharacter)
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
