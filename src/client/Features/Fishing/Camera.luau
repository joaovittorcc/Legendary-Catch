--!strict
-- Cinematic camera while fishing (waiting for a bite and during the fight): glides between
-- several angles around the player and the bobber, faster and closer during the fight.
-- During the minigame the view trembles slightly with small yanks from the fish.
-- "Reduce effects" keeps one steady over-the-shoulder angle (no cuts, no drift, no tremor).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FishingCamera = {}

type Shot = (
	root: Vector3,
	bobber: Vector3,
	forward: Vector3,
	side: Vector3,
	t: number
) -> (Vector3, Vector3)

local UP = Vector3.yAxis

-- Each shot returns (camera position, look-at point). `t` is seconds into the shot, used for a
-- slow drift so even a held angle feels alive.
local SHOTS: { [string]: Shot } = {
	-- Behind the shoulder, the line stretching out to the bobber.
	shoulder = function(root, bobber, forward, side, t)
		return root - forward * 9.5 + side * 3 + UP * (4.8 + t * 0.05), bobber:Lerp(root, 0.3)
	end,
	-- Wide profile of the whole scene: player, line and water.
	profile = function(root, bobber, _forward, side, t)
		local mid = root:Lerp(bobber, 0.5)
		return mid + side * (19 - t * 0.6) + UP * 4, mid + UP * 1
	end,
	-- Low on the water next to the bobber, looking back at the player.
	water = function(root, bobber, forward, side, t)
		return bobber - side * (6 + t * 0.2) + forward * 3.5 + UP * 2.2, root + UP * 2
	end,
	-- High drone shot circling slowly.
	drone = function(root, bobber, forward, side, t)
		local mid = root:Lerp(bobber, 0.5)
		local angle = t * 0.12
		local around = side * math.cos(angle) + forward * math.sin(angle)
		return mid + around * 11 - forward * 6 + UP * 17, mid
	end,
	-- Close on the bobber, where the action is.
	bobber = function(_root, bobber, forward, side, t)
		return bobber - forward * 8.5 + side * (2.2 + t * 0.15) + UP * 2.4, bobber
	end,
}

local WAITING_ORDER = { "shoulder", "profile", "water", "drone" }
local FIGHT_ORDER = { "bobber", "shoulder", "water", "profile", "bobber", "drone" }
local WAITING_SECONDS = 3.6
local FIGHT_SECONDS = 2.6
-- Fight tremor, in degrees: kept small on purpose (kids, phones, motion sickness).
local SHAKE_TREMBLE = 0.35
local SHAKE_BUMP = 1.1
local SHAKE_BUMP_SECONDS = 0.3

local player = Players.LocalPlayer
local conn: RBXScriptConnection? = nil
local oldType: Enum.CameraType? = nil
local oldFov: number? = nil
local phase = "waiting"
local shotIndex = 1
local shotStart = 0
local trauma = 0
local fovOffset = 0
local smoothedFps = 60
-- The catch shot: over the shoulder, on the fish that flies in from the water.
local catchOrigin = Vector3.zero
local catchStart = 0
local CATCH_FLIGHT_SECONDS = 1.1

local function reduceEffects(): boolean
	return player:GetAttribute("ReduceEffects") == true
end

-- Starts (or keeps) the cinematic camera around `root` and the `bobber` part.
function FishingCamera.start(root: BasePart, bobber: BasePart)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	FishingCamera.stop()
	if camera.CameraType == Enum.CameraType.Scriptable then
		oldType = Enum.CameraType.Custom
		oldFov = 70
	else
		oldType = camera.CameraType
		oldFov = camera.FieldOfView
	end
	camera.CameraType = Enum.CameraType.Scriptable
	phase = "waiting"
	shotIndex = 1
	shotStart = os.clock()
	trauma = 0
	fovOffset = 0
	smoothedFps = 60
	-- The player faces the water: forward/side come from that, fixed for the whole cast.
	local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local forward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local side = forward:Cross(UP).Unit
	-- Keeps the camera out of the pier, posts and rocks: if something solid is between the
	-- look-at anchor and the wanted position, stop just in front of it. RespectCanCollide avoids
	-- invisible FishingZone volumes, and transparent barriers are stepped past.
	local baseFilter: { Instance } = { root.Parent :: Instance, bobber }
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = baseFilter
	params.IgnoreWater = true
	params.RespectCanCollide = true
	-- Cast from whatever the shot is built around (the player's head or the bobber, whichever
	-- is closer to the camera), like the default camera does from the character.
	local function unblocked(position: Vector3): Vector3
		local safePos = if position.Y < 1.2
			then Vector3.new(position.X, 1.2, position.Z)
			else position
		local head = root.Position + UP * 2
		local float = bobber.Position + UP * 1.5
		local anchor = if (safePos - head).Magnitude <= (safePos - float).Magnitude
			then head
			else float
		local skipped: { Instance }? = nil
		local origin = anchor
		for _ = 1, 6 do
			local delta = safePos - origin
			if delta.Magnitude < 0.05 then
				break
			end
			local hit = Workspace:Raycast(origin, delta, params)
			if not hit then
				break
			end
			local inst = hit.Instance
			if inst:IsA("BasePart") and inst.Transparency >= 0.8 then
				if not skipped then
					skipped = table.clone(baseFilter)
				end
				table.insert(skipped :: { Instance }, inst)
				params.FilterDescendantsInstances = skipped :: { Instance }
				origin = hit.Position + delta.Unit * 0.05
			else
				if skipped then
					params.FilterDescendantsInstances = baseFilter
				end
				local pulled = hit.Position + (anchor - hit.Position).Unit * 0.8
				return if pulled.Y < 1.2 then Vector3.new(pulled.X, 1.2, pulled.Z) else pulled
			end
		end
		if skipped then
			params.FilterDescendantsInstances = baseFilter
		end
		return safePos
	end

	-- The glide works on `smooth`; the fight tremor is added on top so it never accumulates.
	local smooth = camera.CFrame
	local rng = Random.new()
	local nextBump = os.clock() + 0.8
	local bumpAt = -math.huge
	local bumpDir = Vector2.zero

	local function tremor(now: number, dt: number): CFrame
		if reduceEffects() then
			trauma = 0
			return CFrame.identity
		end
		if dt > 0.001 then
			smoothedFps += (math.clamp(1 / dt, 15, 240) - smoothedFps) * 0.15
		end
		-- Nyquist-safe cap so 30 fps phones never alias shake into jitter.
		local freq = math.min(9, 0.4 * smoothedFps)
		trauma = math.max(0, trauma - dt * 1.9)
		local impulseMag = trauma * trauma * 1.45
		local rx = math.noise(now * freq, 2.7) * 2 * impulseMag
		local ry = math.noise(7.1, now * freq) * 2 * impulseMag
		if phase == "fight" then
			rx += math.noise(now * freq, 0.5) * 2 * SHAKE_TREMBLE
			ry += math.noise(0.5, now * freq) * 2 * SHAKE_TREMBLE
			-- Every so often the fish yanks: a quick bump that fades out.
			if now >= nextBump then
				bumpAt = now
				bumpDir = Vector2.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
				nextBump = now + rng:NextNumber(0.7, 1.5)
			end
			local fade = math.clamp(1 - (now - bumpAt) / SHAKE_BUMP_SECONDS, 0, 1)
			local bump = fade
				* fade
				* SHAKE_BUMP
				* math.sin((now - bumpAt) * math.min(40, freq * 3.5))
			rx += bumpDir.Y * bump
			ry += bumpDir.X * bump
		end
		if math.abs(rx) < 0.001 and math.abs(ry) < 0.001 then
			return CFrame.identity
		end
		return CFrame.Angles(math.rad(rx), math.rad(ry), 0)
	end

	conn = RunService.RenderStepped:Connect(function(dt)
		local character = root.Parent
		local hum = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if not character or not bobber.Parent or (hum ~= nil and hum.Health <= 0) then
			FishingCamera.stop()
			return
		end
		local position: Vector3
		local look: Vector3
		local speed: number
		local baseFov = oldFov or 70
		local targetFovOffset = 0
		if phase == "catch" then
			-- Behind the character's shoulder, on the spot where the fish is shown.
			local display = root.Position + forward * 7 + UP * 3
			local a = math.clamp((os.clock() - catchStart) / CATCH_FLIGHT_SECONDS, 0, 1)
			look = (catchOrigin + UP):Lerp(display, a * a * (3 - 2 * a))
			position = root.Position - forward * 3.2 + side * 2.3 + UP * 3.6
			speed = 3.2
			targetFovOffset = -7
		else
			local order = if phase == "fight" then FIGHT_ORDER else WAITING_ORDER
			local length = if phase == "fight" then FIGHT_SECONDS else WAITING_SECONDS
			local calm = reduceEffects()
			if calm then
				shotIndex = 1
			elseif os.clock() - shotStart >= length then
				shotIndex = shotIndex % #order + 1
				shotStart = os.clock()
			end
			local name = if calm then "shoulder" else order[shotIndex]
			local t = if calm then 0 else os.clock() - shotStart
			position, look = SHOTS[name](root.Position, bobber.Position, forward, side, t)
			-- Smooth glide between angles; snappier while fighting.
			speed = if phase == "fight" then 4 else 2.2
			targetFovOffset = if phase == "fight" then -2.5 else 0
		end
		if reduceEffects() then
			fovOffset = 0
		else
			fovOffset += (targetFovOffset - fovOffset) * (1 - math.exp(-dt * 6.5))
		end
		local goal = CFrame.lookAt(unblocked(position), look)
		smooth = smooth:Lerp(goal, 1 - math.exp(-dt * speed))
		camera.CFrame = smooth * tremor(os.clock(), dt)
		camera.FieldOfView = math.clamp(baseFov + fovOffset, 50, 82)
		camera.Focus = CFrame.new(look)
	end)
end

-- Adds a capped trauma kick (used on bites, perfect minigame hits, and misses).
function FishingCamera.impulse(amount: number)
	if not conn or reduceEffects() then
		return
	end
	trauma = math.min(0.6, trauma + math.max(amount, 0))
end

-- The bite: switch to the faster, closer fight sequence with an immediate FOV punch.
function FishingCamera.fight()
	if conn then
		phase = "fight"
		shotIndex = 1
		shotStart = os.clock()
		if not reduceEffects() then
			fovOffset = -7
			trauma = math.min(0.6, trauma + 0.42)
		end
	end
end

-- The catch: glide behind the character's shoulder and follow the fish flying in from `origin`.
-- Keeps the camera until `stop()` (the reveal ends with the cleanup that calls it).
function FishingCamera.catch(origin: Vector3)
	if conn then
		phase = "catch"
		catchOrigin = origin
		catchStart = os.clock()
		if not reduceEffects() then
			trauma = math.min(0.6, trauma + 0.25)
		end
	end
end

-- Gives the camera back to the player (call before the reveal and on any cleanup).
function FishingCamera.stop()
	local c = conn
	conn = nil
	if c then
		c:Disconnect()
	end
	local camera = Workspace.CurrentCamera
	if camera then
		if oldType then
			camera.CameraType = oldType
		end
		if oldFov then
			camera.FieldOfView = oldFov
		end
	end
	oldType = nil
	oldFov = nil
	trauma = 0
	fovOffset = 0
end

return FishingCamera
