--!strict
-- Reel bar (style of the reference video / Stardew): hold to push the zone right, release
-- and it drifts left. Keep the fish marker inside to fill progress; time outside fills the
-- red failure meter. Progress full = caught, failure full = escaped.

local RunService = game:GetService("RunService")

local Minigames = script.Parent
local Fishing = Minigames.Parent
local FishingConfig = require(
	game:GetService("ReplicatedStorage")
		:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("Fishing")
)
local Control = require(Fishing:WaitForChild("Control"))
local PressInput = require(Fishing:WaitForChild("PressInput"))
local Ui = require(Fishing:WaitForChild("Ui"))

local Reel = {}

function Reel.run(area: Frame, tier: number, color: Color3, done: (boolean) -> ()): () -> ()
	local cfg = FishingConfig.REEL
	local ease = Control.ease()
	local zoneWidth = math.min(FishingConfig.tierValue(cfg.zoneWidth, tier) * ease, 0.5)
	local fishSpeed = FishingConfig.tierValue(cfg.fishSpeed, tier)
	local retarget = FishingConfig.tierValue(cfg.fishRetarget, tier)
	local gain = FishingConfig.tierValue(cfg.gain, tier)
	local failRise = FishingConfig.tierValue(cfg.failRise, tier) / ease

	local failBack = Ui.frame(
		area,
		"FailBack",
		UDim2.fromScale(1, 0.1),
		UDim2.fromScale(0, 0),
		Color3.fromRGB(60, 20, 30)
	)
	Ui.corner(failBack, 0.5)
	local failFill = Ui.frame(
		failBack,
		"FailFill",
		UDim2.fromScale(0, 1),
		UDim2.fromScale(0, 0),
		Color3.fromRGB(255, 60, 70)
	)
	Ui.corner(failFill, 0.5)

	local bar = Ui.frame(
		area,
		"Bar",
		UDim2.fromScale(1, 0.42),
		UDim2.fromScale(0, 0.2),
		Color3.fromRGB(22, 24, 44)
	)
	Ui.corner(bar, 0.3)
	Ui.stroke(bar, color, 2)
	local zone = Ui.frame(
		bar,
		"Zone",
		UDim2.fromScale(zoneWidth, 1),
		UDim2.fromScale(0.5, 0),
		Color3.fromRGB(190, 200, 230),
		0.45
	)
	zone.AnchorPoint = Vector2.new(0.5, 0)
	Ui.corner(zone, 0.3)
	local fish = Ui.frame(bar, "Fish", UDim2.fromScale(0.6, 0.6), UDim2.fromScale(0.5, 0.5), color)
	fish.AnchorPoint = Vector2.new(0.5, 0.5)
	fish.Rotation = 45
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = fish
	Ui.stroke(fish, Color3.new(1, 1, 1), 2)

	local progressBack = Ui.frame(
		area,
		"ProgressBack",
		UDim2.fromScale(1, 0.14),
		UDim2.fromScale(0, 0.74),
		Color3.fromRGB(30, 34, 60)
	)
	Ui.corner(progressBack, 0.5)
	local progressFill = Ui.frame(
		progressBack,
		"ProgressFill",
		UDim2.fromScale(0.3, 1),
		UDim2.fromScale(0, 0),
		color
	)
	Ui.corner(progressFill, 0.5)

	local zonePos, zoneVel = 0.5, 0
	local fishPos, fishTarget = 0.5, 0.5
	local nextTarget = 0
	local progress, fail = 0.3, 0
	local elapsed = 0
	local finished = false

	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		elapsed += dt

		local accel = if PressInput.isHeld() then cfg.zoneAccel else -cfg.zoneAccel
		zoneVel = math.clamp(zoneVel + accel * dt, -cfg.zoneMaxSpeed, cfg.zoneMaxSpeed)
		zonePos += zoneVel * dt
		local half = zoneWidth / 2
		if zonePos < half then
			zonePos, zoneVel = half, 0
		elseif zonePos > 1 - half then
			zonePos, zoneVel = 1 - half, 0
		end

		if elapsed >= nextTarget then
			fishTarget = math.random(5, 95) / 100
			nextTarget = elapsed + retarget * (0.6 + math.random() * 0.8)
		end
		local step = fishSpeed * dt
		fishPos += math.clamp(fishTarget - fishPos, -step, step)

		local inside = math.abs(fishPos - zonePos) <= half
		if inside then
			progress += gain * dt
			fail = math.max(fail - cfg.failRecover * dt, 0)
		else
			progress = math.max(progress - cfg.drain * dt, 0)
			fail += failRise * dt
		end

		zone.Position = UDim2.fromScale(zonePos, 0)
		zone.BackgroundTransparency = if inside then 0.25 else 0.55
		fish.Position = UDim2.fromScale(fishPos, 0.5)
		progressFill.Size = UDim2.fromScale(math.clamp(progress, 0, 1), 1)
		failFill.Size = UDim2.fromScale(math.clamp(fail, 0, 1), 1)

		if progress >= 1 or fail >= 1 then
			finished = true
			conn:Disconnect()
			done(progress >= 1)
		end
	end)

	return function()
		finished = true
		conn:Disconnect()
	end
end

return Reel
