--!strict
-- Precision bar: a marker sweeps back and forth; press while it is inside the zone.
-- 3 hits catch the creature, 2 misses lose it (two red lights, the first one blinks).

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Minigames = script.Parent
local Fishing = Minigames.Parent
local FishingConfig = require(
	game:GetService("ReplicatedStorage")
		:WaitForChild("Shared")
		:WaitForChild("Config")
		:WaitForChild("Fishing")
)
local PressInput = require(Fishing:WaitForChild("PressInput"))
local Ui = require(Fishing:WaitForChild("Ui"))

local Precision = {}

local GREY = Color3.fromRGB(70, 74, 100)
local RED = Color3.fromRGB(255, 60, 70)

function Precision.run(area: Frame, tier: number, color: Color3, done: (boolean) -> ()): () -> ()
	local cfg = FishingConfig.PRECISION
	local speed = FishingConfig.tierValue(cfg.markerSpeed, tier)
	local zoneWidth = FishingConfig.tierValue(cfg.zoneWidth, tier)

	local bar = Ui.frame(
		area,
		"Bar",
		UDim2.fromScale(1, 0.42),
		UDim2.fromScale(0, 0.2),
		Color3.fromRGB(22, 24, 44)
	)
	Ui.corner(bar, 0.3)
	Ui.stroke(bar, color, 2)
	local zone =
		Ui.frame(bar, "Zone", UDim2.fromScale(zoneWidth, 1), UDim2.fromScale(0.5, 0), color, 0.35)
	zone.AnchorPoint = Vector2.new(0.5, 0)
	Ui.corner(zone, 0.3)
	local marker = Ui.frame(
		bar,
		"Marker",
		UDim2.fromScale(0.012, 1.3),
		UDim2.fromScale(0, 0.5),
		Color3.new(1, 1, 1)
	)
	marker.AnchorPoint = Vector2.new(0.5, 0.5)

	-- Hit pips (left) and miss lights (right).
	local pips: { Frame } = {}
	for i = 1, cfg.hitsNeeded do
		local pip = Ui.frame(
			area,
			"Hit" .. i,
			UDim2.fromScale(0.07, 0.22),
			UDim2.fromScale((i - 1) * 0.09, 0.72),
			GREY
		)
		Ui.corner(pip, 0.5)
		table.insert(pips, pip)
	end
	local lives: { Frame } = {}
	for i = 1, cfg.missesAllowed do
		local light = Instance.new("Frame")
		light.Name = "Miss" .. i
		light.Size = UDim2.fromScale(0.055, 0.22)
		light.Position = UDim2.fromScale(1 - i * 0.075, 0.72)
		light.BackgroundColor3 = GREY
		light.BorderSizePixel = 0
		light.Parent = area
		Ui.corner(light, 0.5)
		local ratio = Instance.new("UIAspectRatioConstraint")
		ratio.AspectRatio = 1
		ratio.Parent = light
		table.insert(lives, light)
	end

	local pos, dir = 0, 1
	local hits, misses = 0, 0
	local cooldown = 0
	local finished = false

	local function moveZone()
		local half = zoneWidth / 2
		local center = math.random() * (1 - zoneWidth) + half
		-- Keep the new zone away from the marker so the next hit needs a fresh sweep.
		if math.abs(center - pos) < 0.25 then
			center = if center > 0.5 then center - 0.35 else center + 0.35
			center = math.clamp(center, half, 1 - half)
		end
		zone.Position = UDim2.fromScale(center, 0)
	end
	moveZone()

	local function finish(success: boolean)
		finished = true
		done(success)
	end

	local pressConn = PressInput.Pressed:Connect(function()
		if finished or cooldown > 0 then
			return
		end
		cooldown = 0.18
		local center = zone.Position.X.Scale
		if math.abs(pos - center) <= zoneWidth / 2 then
			hits += 1
			pips[hits].BackgroundColor3 = color
			zone.BackgroundTransparency = 0
			TweenService:Create(zone, TweenInfo.new(0.25), { BackgroundTransparency = 0.35 }):Play()
			if hits >= cfg.hitsNeeded then
				finish(true)
			else
				moveZone()
			end
		else
			misses += 1
			local light = lives[misses]
			light.BackgroundColor3 = RED
			-- Blink so the first mistake is impossible to miss.
			local blink = TweenService:Create(
				light,
				TweenInfo.new(0.12, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true),
				{
					BackgroundTransparency = 0.7,
				}
			)
			blink:Play()
			bar.BackgroundColor3 = Color3.fromRGB(90, 20, 30)
			TweenService
				:Create(bar, TweenInfo.new(0.3), { BackgroundColor3 = Color3.fromRGB(22, 24, 44) })
				:Play()
			if misses >= cfg.missesAllowed then
				finish(false)
			end
		end
	end)

	local stepConn = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		cooldown = math.max(cooldown - dt, 0)
		pos += dir * speed * dt
		if pos >= 1 then
			pos, dir = 1, -1
		elseif pos <= 0 then
			pos, dir = 0, 1
		end
		marker.Position = UDim2.fromScale(pos, 0.5)
	end)

	return function()
		finished = true
		pressConn:Disconnect()
		stepConn:Disconnect()
	end
end

return Precision
