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
local phase = "waiting"
local shotIndex = 1
local shotStart = 0
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
	oldType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	phase = "waiting"
	shotIndex = 1
	shotStart = os.clock()
	-- The player faces the water: forward/side come from that, fixed for the whole cast.
	local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local forward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local side = forward:Cross(UP).Unit
	-- Keeps the camera out of the pier, posts and rocks: if something is between the look-at
	-- point and the wanted position, stop just in front of it.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { root.Parent :: Instance, bobber }
	params.IgnoreWater = true
	-- Cast from whatever the shot is built around (the player's head or the bobber, whichever
	-- is closer to the camera), like the default camera does from the character.
	local function unblocked(position: Vector3): Vector3
		local head = root.Position + UP * 2
		local float = bobber.Position + UP * 1.5
		local anchor = if (position - head).Magnitude <= (position - float).Magnitude
			then head
			else float
		local hit = Workspace:Raycast(anchor, position - anchor, params)
		if hit then
			return hit.Position + (anchor - hit.Position).Unit * 0.8
		end
		return position
	end

	-- The glide works on `smooth`; the fight tremor is added on top so it never accumulates.
	local smooth = camera.CFrame
	local rng = Random.new()
	local nextBump = os.clock() + 0.8
	local bumpAt = -math.huge
	local bumpDir = Vector2.zero

	local function tremor(now: number): CFrame
		if phase ~= "fight" or reduceEffects() then
			return CFrame.identity
		end
		-- Constant faint tremble, like the line pulling.
		-- math.noise stays roughly within -0.5..0.5, so x2 gives about ±SHAKE_TREMBLE.
		local x = math.noise(now * 9, 0.5) * 2 * SHAKE_TREMBLE
		local y = math.noise(0.5, now * 9) * 2 * SHAKE_TREMBLE
		-- Every so often the fish yanks: a quick bump that fades out.
		if now >= nextBump then
			bumpAt = now
			bumpDir = Vector2.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
			nextBump = now + rng:NextNumber(0.7, 1.5)
		end
		local fade = math.clamp(1 - (now - bumpAt) / SHAKE_BUMP_SECONDS, 0, 1)
		local bump = fade * fade * SHAKE_BUMP * math.sin((now - bumpAt) * 40)
		return CFrame.Angles(math.rad(x + bumpDir.Y * bump), math.rad(y + bumpDir.X * bump), 0)
	end

	conn = RunService.RenderStepped:Connect(function(dt)
		if not root.Parent or not bobber.Parent then
			FishingCamera.stop()
			return
		end
		local position: Vector3
		local look: Vector3
		local speed: number
		if phase == "catch" then
			-- Behind the character's shoulder, on the spot where the fish is shown.
			local display = root.Position + forward * 7 + UP * 3
			local a = math.clamp((os.clock() - catchStart) / CATCH_FLIGHT_SECONDS, 0, 1)
			look = (catchOrigin + UP):Lerp(display, a * a * (3 - 2 * a))
			position = root.Position - forward * 3.2 + side * 2.3 + UP * 3.6
			speed = 3.2
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
		end
		local goal = CFrame.lookAt(unblocked(position), look)
		smooth = smooth:Lerp(goal, 1 - math.exp(-dt * speed))
		camera.CFrame = smooth * tremor(os.clock())
		camera.Focus = CFrame.new(look)
	end)
end

-- The bite: switch to the faster, closer fight sequence.
function FishingCamera.fight()
	if conn then
		phase = "fight"
		shotIndex = 1
		shotStart = os.clock()
	end
end

-- The catch: glide behind the character's shoulder and follow the fish flying in from `origin`.
-- Keeps the camera until `stop()` (the reveal ends with the cleanup that calls it).
function FishingCamera.catch(origin: Vector3)
	if conn then
		phase = "catch"
		catchOrigin = origin
		catchStart = os.clock()
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
	if camera and oldType then
		camera.CameraType = oldType
	end
	oldType = nil
end

return FishingCamera
