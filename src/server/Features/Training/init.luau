--!strict
-- Lagoon training (server authority). Approaching a training stool starts a seated session.
-- Periodic drills grant a bonus. Standing up or pressing Stop ends the session.
--
-- Levels live in the player profile (PlayerData); the profile mirrors them as attributes.
--
-- Fishing Power v2 (ReplicatedStorage attribute "TrainingPower" = true): each stat gains power
-- (1..1e15) every second instead of XP, multiplied by the training field (bought with
-- TrainingBuyField), the spot's island and prestige. Level/XP are then derived from power so
-- older readers keep working. Contract: docs/TREINO-PP-CONTRATO.md.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local TrainingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Training"))

local Achievements = require(script.Parent:WaitForChild("Achievements"))
local Analytics = require(script.Parent:WaitForChild("Analytics"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Progress = require(script.Parent:WaitForChild("Progress"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))
local Seats = require(script:WaitForChild("Seats"))

type Session = {
	stat: string,
	seat: Seat,
	humanoid: Humanoid,
	seated: RBXScriptConnection?,
	nextRingAt: number,
	ringId: number,
	ringExpires: number, -- 0 when no ring is pending
	combo: number,
	island: number, -- island index of the spot (1 = hub lagoon)
}

local Training = {}
local POWER_GAIN_MULTIPLIER = 10
Training.order = 40

local sessions: { [Player]: Session } = {}
local blockedSeats: { [Player]: Seat } = {}
local stationGroups: { [BasePart]: { folder: Folder, stations: { Seats.Station } } } = {}
local rng = Random.new()
local update: RemoteEvent

local function level(player: Player, stat: string): number
	local profile = PlayerData.get(player)
	local t = profile and profile.training[stat]
	return if t then t.level else 0
end

local function powerOf(player: Player, stat: string): number
	local profile = PlayerData.get(player)
	local t = profile and profile.training[stat]
	return TrainingConfig.clampPower(t and t.power)
end

local function powerSum(player: Player): number
	local total = 0
	for _, stat in TrainingConfig.STATS do
		total += powerOf(player, stat)
	end
	return total
end

-- Effective level for gameplay: the stored level, or the power mapped onto 0..25 (continuous).
local function effectiveLevel(player: Player, stat: string): number
	if TrainingConfig.powerEnabled() then
		return TrainingConfig.equivalentLevel(powerOf(player, stat))
	end
	return level(player, stat)
end

local function prestigeOf(player: Player): number
	local profile = PlayerData.get(player)
	return if profile then math.max(0, profile.prestige or 0) else 0
end

-- Power per second right now for `player` training `stat` on `island`.
local function currentGain(player: Player, stat: string, island: number): number
	local profile = PlayerData.get(player)
	local field = if profile then profile.trainingField else 1
	local mult = TrainingConfig.multiplier(field, island, prestigeOf(player))
	return TrainingConfig.gainPerSecond(powerOf(player, stat), mult) * POWER_GAIN_MULTIPLIER
end

-- Adds power, keeps level/xp in step (old UI, achievements) and announces level-ups and
-- each power of ten crossed.
local function addPower(player: Player, stat: string, amount: number): number
	local profile = PlayerData.get(player)
	local t = profile and profile.training[stat]
	if not t then
		return 0
	end
	local before = TrainingConfig.clampPower(t.power)
	local after = TrainingConfig.addPower(before, amount)
	if after == before then
		return 0
	end
	local oldLevel = TrainingConfig.legacyLevel(before)
	local newLevel, newXp = TrainingConfig.legacyLevel(after)
	PlayerData.update(player, function(p)
		p.training[stat] = { level = newLevel, xp = newXp, power = after }
	end)
	local fromDecade = math.floor(math.log10(before) + 1e-9)
	local toDecade = math.floor(math.log10(after) + 1e-9)
	if toDecade > fromDecade and toDecade >= 3 then
		update:FireClient(
			player,
			{
				event = "powerMilestone",
				stat = stat,
				power = after,
				milestone = 10 ^ toDecade,
			} :: Net.TrainingUpdate
		)
		Analytics.custom(player, "TrainingPowerMilestone", toDecade)
	end
	for lvl = oldLevel + 1, newLevel do
		update:FireClient(
			player,
			{ event = "levelUp", stat = stat, level = lvl } :: Net.TrainingUpdate
		)
	end
	if newLevel > oldLevel then
		Achievements.check(player)
	end
	return after - before
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function stop(player: Player, reason: string)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	blockedSeats[player] = session.seat
	if session.seated then
		session.seated:Disconnect()
	end
	if session.seat.Occupant == session.humanoid then
		local weld = session.seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		session.humanoid.Sit = false
	end
	player:SetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE, "")
	player:SetAttribute("TrainingCombo", 0)
	if player.Parent == Players then
		update:FireClient(player, { event = "stopped", reason = reason } :: Net.TrainingUpdate)
	end
end

local function stillSeated(session: Session): boolean
	return session.seat:IsDescendantOf(workspace)
		and session.seat.Occupant == session.humanoid
		and session.humanoid.Health > 0
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
		p.training[stat] = {
			level = lvl,
			xp = total,
			power = TrainingConfig.powerFromLevel(lvl, total),
		}
	end)
	if lvl > t.level then
		Achievements.check(player)
	end
end

local function start(player: Player, humanoid: Humanoid, station: Seats.Station, spot: BasePart)
	local seat, stat = station.seat, station.stat
	local island = TrainingConfig.islandIndex(spot:GetAttribute(TrainingConfig.ISLAND_ATTRIBUTE))
	if
		TrainingConfig.powerEnabled()
		and not TrainingConfig.islandAllowed(island, powerSum(player))
	then
		blockedSeats[player] = seat
		update:FireClient(
			player,
			{
				event = "islandLocked",
				island = island,
				gate = TrainingConfig.ISLANDS[island].gate,
			} :: Net.TrainingUpdate
		)
		return
	end
	seat:Sit(humanoid)
	if seat.Occupant ~= humanoid then
		return
	end
	local session: Session = {
		stat = stat,
		seat = seat,
		humanoid = humanoid,
		island = island,
		nextRingAt = os.clock()
			+ rng:NextNumber(TrainingConfig.RING_INTERVAL_MIN, TrainingConfig.RING_INTERVAL_MAX),
		ringId = 0,
		ringExpires = 0,
		combo = 0,
	}
	sessions[player] = session
	session.seated = humanoid.Seated:Connect(function(active, currentSeat)
		if sessions[player] == session and (not active or currentSeat ~= seat) then
			stop(player, "stood")
		end
	end)
	player:SetAttribute(TrainingConfig.ACTIVE_ATTRIBUTE, stat)
	player:SetAttribute("TrainingCombo", 0)
	-- First training of the (UTC) day: a bonus that grows a little with the stat level.
	local today = os.time() // 86400
	local profile = PlayerData.get(player)
	if profile and profile.stats.trainDay ~= today then
		PlayerData.update(player, function(p)
			p.stats.trainDay = today
		end)
		if TrainingConfig.powerEnabled() then
			local bonus = addPower(
				player,
				stat,
				currentGain(player, stat, island) * TrainingConfig.DAILY_GAIN_SECONDS
			)
			update:FireClient(
				player,
				{ event = "dailyBonus", stat = stat, gain = bonus } :: Net.TrainingUpdate
			)
		else
			local bonus = 15 + level(player, stat) * 3
			addXp(player, stat, bonus)
			update:FireClient(
				player,
				{ event = "dailyBonus", stat = stat, bonusXp = bonus } :: Net.TrainingUpdate
			)
		end
	end
	Analytics.step(player, "firstTraining")
	Progress.onTrainingStarted(player)
end

local function addStationGroup(spot: Instance)
	if not spot:IsA("BasePart") or not spot:IsDescendantOf(workspace) or stationGroups[spot] then
		return
	end
	-- Map builders can parent and tag a spot in the same frame as the decor.
	task.defer(function()
		if
			stationGroups[spot]
			or not spot:IsDescendantOf(workspace)
			or not CollectionService:HasTag(spot, TrainingConfig.SPOT_TAG)
		then
			return
		end
		local folder, stations = Seats.build(spot, TrainingConfig.STATS)
		stationGroups[spot] = { folder = folder, stations = stations }
	end)
end

local function removeStationGroup(spot: Instance)
	if not spot:IsA("BasePart") then
		return
	end
	local group = stationGroups[spot]
	if group then
		stationGroups[spot] = nil
		group.folder:Destroy()
	end
end

local function tryNearbySeat(player: Player)
	if sessions[player] or not PlayerData.get(player) then
		return
	end
	local character = player.Character
	local root = rootOf(player)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not humanoid or humanoid.Health <= 0 or humanoid.SeatPart then
		return
	end
	local fishing = character:GetAttribute("FishingState")
	if fishing == "waiting" or fishing == "fighting" then
		return
	end
	local blocked = blockedSeats[player]
	if
		blocked
		and (
			not blocked:IsDescendantOf(workspace)
			or Seats.distanceSquared(root.Position, blocked.Position) >= Seats.EXIT_RADIUS ^ 2
		)
	then
		blockedSeats[player] = nil
	end

	local bestSpot: BasePart? = nil
	local bestStation: Seats.Station? = nil
	local bestDistance = Seats.ENTER_RADIUS ^ 2
	for spot, group in stationGroups do
		for _, station in group.stations do
			local seat = station.seat
			local distance = Seats.distanceSquared(root.Position, seat.Position)
			if distance < bestDistance and math.abs(root.Position.Y - seat.Position.Y) <= 3.5 then
				bestStation, bestSpot, bestDistance = station, spot, distance
			end
		end
	end
	if
		bestStation
		and bestSpot
		and bestStation.seat ~= blockedSeats[player]
		and bestStation.seat:IsDescendantOf(workspace)
		and not bestStation.seat.Occupant
	then
		start(player, humanoid, bestStation, bestSpot)
	end
end

local function step()
	local now = os.clock()
	for player, s in sessions do
		if not stillSeated(s) then
			stop(player, "left")
			continue
		end
		if TrainingConfig.powerEnabled() then
			local gain = addPower(player, s.stat, currentGain(player, s.stat, s.island))
			update:FireClient(
				player,
				{
					event = "power",
					stat = s.stat,
					power = powerOf(player, s.stat),
					gain = gain,
				} :: Net.TrainingUpdate
			)
		else
			addXp(player, s.stat, TrainingConfig.XP_PER_SECOND)
		end
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
			local rings = if effectiveLevel(player, s.stat) >= 10 then 2 else 1
			update:FireClient(
				player,
				{ event = "ring", ringId = s.ringId, rings = rings, stat = s.stat } :: Net.TrainingUpdate
			)
		end
	end
end

local function onRingResult(player: Player, ringId: unknown, success: unknown)
	if
		typeof(ringId) ~= "number"
		or ringId ~= ringId
		or math.abs(ringId) >= math.huge
		or typeof(success) ~= "boolean"
	then
		return
	end
	local s = sessions[player]
	if not s or not stillSeated(s) or s.ringExpires == 0 or s.ringId ~= ringId then
		return
	end
	s.ringExpires = 0
	if success then
		s.combo += 1
		-- Streak of rings in a row: +10% bonus XP per step, up to +50%.
		local mult = 1 + math.min(s.combo - 1, 5) * 0.1
		if TrainingConfig.powerEnabled() then
			local bonus = addPower(
				player,
				s.stat,
				currentGain(player, s.stat, s.island) * TrainingConfig.RING_GAIN_SECONDS * mult
			)
			update:FireClient(
				player,
				{
					event = "ringResult",
					stat = s.stat,
					combo = s.combo,
					gain = bonus,
				} :: Net.TrainingUpdate
			)
		else
			addXp(
				player,
				s.stat,
				math.floor(TrainingConfig.ringBonus(level(player, s.stat)) * mult)
			)
		end
	else
		s.combo = 0
	end
	player:SetAttribute("TrainingCombo", s.combo)
end

-- Buys the next training field level (Fishing Power v2). Server checks coins, power and level.
local function onBuyField(player: Player, requestId: unknown)
	local id = if typeof(requestId) == "number"
			and requestId == requestId
			and math.abs(requestId) < math.huge
		then requestId
		else 0
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local function reply(ok: boolean, reason: string?, gate: number?)
		local current = PlayerData.get(player)
		update:FireClient(
			player,
			{
				event = "fieldResult",
				ok = ok,
				reason = reason,
				field = if current then current.trainingField else 1,
				requestId = id,
				gate = gate,
			} :: Net.TrainingUpdate
		)
	end
	if not TrainingConfig.powerEnabled() then
		reply(false, "disabled")
		return
	end
	local sum = powerSum(player)
	local ok, reason, cost = TrainingConfig.canBuyField(profile.trainingField, sum, profile.coins)
	if not ok then
		local nextDef = TrainingConfig.FIELD[TrainingConfig.fieldLevel(profile.trainingField) + 1]
		reply(false, reason, if reason == "power" and nextDef then nextDef.gate else nil)
		return
	end
	local bought, newLevel = false, profile.trainingField
	PlayerData.update(player, function(p)
		-- Re-check inside the mutation: coins or level may have moved since.
		local stillOk, _, price = TrainingConfig.canBuyField(p.trainingField, sum, p.coins)
		if not stillOk or price ~= cost then
			return
		end
		p.coins -= price
		p.trainingField = TrainingConfig.fieldLevel(p.trainingField + 1)
		bought, newLevel = true, p.trainingField
	end)
	if not bought then
		reply(false, "changed")
		return
	end
	Analytics.coins(player, false, cost, "TrainingField", "field_" .. tostring(newLevel))
	reply(true)
end

-- Used by fishing: the player's effective level in a stat (0 if never trained). With Fishing
-- Power on it is continuous (power mapped onto 0..25).
function Training.level(player: Player, stat: string): number
	return effectiveLevel(player, stat)
end

-- Fishing Power of a stat (1 when never trained or the profile is not loaded).
function Training.power(player: Player, stat: string): number
	return powerOf(player, stat)
end

-- Total Fishing Power across all stats (used by portals to enforce island power gates).
function Training.powerSum(player: Player): number
	return powerSum(player)
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
	Remotes.onServerEvent(Net.TRAINING_BUY_FIELD, 2, 3, onBuyField)

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
		player.CharacterAdded:Connect(function(character)
			blockedSeats[player] = nil
			watchCharacter(character)
		end)
		player.CharacterRemoving:Connect(function()
			stop(player, "respawn")
		end)
	end
	Players.PlayerAdded:Connect(initPlayer)
	for _, player in Players:GetPlayers() do
		initPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		stop(player, "left")
		blockedSeats[player] = nil
	end)

	-- The map is rebuilt in Studio, so spots can appear after start.
	for _, spot in CollectionService:GetTagged(TrainingConfig.SPOT_TAG) do
		addStationGroup(spot)
	end
	CollectionService:GetInstanceAddedSignal(TrainingConfig.SPOT_TAG):Connect(addStationGroup)
	CollectionService:GetInstanceRemovedSignal(TrainingConfig.SPOT_TAG):Connect(removeStationGroup)
	if #CollectionService:GetTagged(TrainingConfig.SPOT_TAG) == 0 then
		warn(`[Training] no part tagged "{TrainingConfig.SPOT_TAG}" in the map yet`)
	end

	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				tryNearbySeat(player)
			end
			task.wait(0.15)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			step()
		end
	end)
end

return Training
