--!strict
-- Client-only visuals for the cast: glowing line (Beam) from the rod tip to a bobber that
-- arcs out over the water, bobs, dips on the bite and shakes during the fight.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Pose = require(script.Parent.Parent:WaitForChild("AvatarVisuals"):WaitForChild("Pose"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local SEA_Y = 0.25
local DEFAULT_LINE_COLOR = Color3.fromRGB(150, 235, 255)

local function reduced(): boolean
	return Players.LocalPlayer:GetAttribute("ReduceEffects") == true
end

export type Line = {
	bobber: BasePart,
	beacon: BasePart,
	beaconLight: PointLight,
	trail: Trail,
	beam: Beam,
	tip: Attachment,
	tipPart: BasePart?,
	rest: Vector3,
	fightColor: Color3,
	nextFightFx: number,
	mode: string, -- "flying" | "floating" | "fighting"
	conn: RBXScriptConnection?,
	stopPose: (() -> ())?,
}

local Line = {}

local function newBobber(): (BasePart, BasePart, PointLight, Trail)
	local bobber = Instance.new("Part")
	bobber.Name = "Bobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.7, 0.7, 0.7)
	bobber.Color = Color3.fromRGB(235, 60, 60)
	bobber.Material = Enum.Material.SmoothPlastic
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.CanTouch = false
	bobber.CastShadow = false

	local band = Instance.new("Part")
	band.Name = "Band"
	band.Shape = Enum.PartType.Cylinder
	band.Size = Vector3.new(0.22, 0.74, 0.74)
	band.Color = Color3.fromRGB(250, 250, 250)
	band.Material = Enum.Material.SmoothPlastic
	band.Anchored = true
	band.CanCollide = false
	band.CanQuery = false
	band.CanTouch = false
	band.CastShadow = false
	band.Parent = bobber

	-- Glowing crystal beacon on top of the bobber; shifts color to the hooked rarity.
	local beacon = Instance.new("Part")
	beacon.Name = "Beacon"
	beacon.Shape = Enum.PartType.Ball
	beacon.Size = Vector3.new(0.32, 0.32, 0.32)
	beacon.Color = DEFAULT_LINE_COLOR
	beacon.Material = Enum.Material.Neon
	beacon.Anchored = true
	beacon.CanCollide = false
	beacon.CanQuery = false
	beacon.CanTouch = false
	beacon.CastShadow = false
	beacon.Parent = bobber

	local beaconLight = Instance.new("PointLight")
	beaconLight.Color = DEFAULT_LINE_COLOR
	beaconLight.Brightness = if reduced() then 0 else 1.5
	beaconLight.Range = 9
	beaconLight.Parent = beacon

	-- Tapered energy ribbon during cast flight and reel-in.
	local trailTop = Instance.new("Attachment")
	trailTop.Position = Vector3.new(0, 0.24, 0)
	trailTop.Parent = bobber
	local trailBottom = Instance.new("Attachment")
	trailBottom.Position = Vector3.new(0, -0.24, 0)
	trailBottom.Parent = bobber
	local trail = Instance.new("Trail")
	trail.Attachment0 = trailTop
	trail.Attachment1 = trailBottom
	trail.Lifetime = 0.26
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1), DEFAULT_LINE_COLOR)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(0.55, 0.52),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Enabled = not reduced()
	trail.Parent = bobber

	return bobber, beacon, beaconLight, trail
end

function Line.create(tip: Attachment): Line
	local bobber, beacon, beaconLight, trail = newBobber()
	bobber.CFrame = tip.WorldCFrame
	local attachment = Instance.new("Attachment")
	attachment.Parent = bobber
	bobber.Parent = Workspace

	local beam = Instance.new("Beam")
	beam.Attachment0 = tip
	beam.Attachment1 = attachment
	beam.Width0 = 0.06
	beam.Width1 = 0.06
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 24
	beam.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
	beam.CurveSize0 = 1.5
	beam.CurveSize1 = -1
	beam.Parent = bobber

	local tipPart = tip.Parent
	local self: Line = {
		bobber = bobber,
		beacon = beacon,
		beaconLight = beaconLight,
		trail = trail,
		beam = beam,
		tip = tip,
		tipPart = if tipPart and tipPart:IsA("BasePart") then tipPart else nil,
		rest = bobber.Position,
		fightColor = DEFAULT_LINE_COLOR,
		nextFightFx = 0,
		mode = "flying",
		conn = nil,
		stopPose = nil,
	}

	local t = 0
	self.conn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		-- Sideways axis across the line (from the rod tip out to the bobber), so the bobber
		-- and the line sweep from one side to the other.
		local out = (self.rest - tip.WorldPosition) * Vector3.new(1, 0, 1)
		local side = if out.Magnitude > 0.01 then out.Unit:Cross(Vector3.yAxis) else Vector3.xAxis
		local forward = if out.Magnitude > 0.01 then out.Unit else Vector3.zAxis
		if self.mode == "floating" then
			-- Gentle drift with the current while waiting.
			bobber.Position = self.rest
				+ side * (math.sin(t * 0.7) * 0.9)
				+ Vector3.new(0, math.sin(t * 2.4) * 0.12, 0)
			beam.CurveSize0 = 1.5 + math.sin(t * 0.7) * 0.4
		elseif self.mode == "fighting" then
			-- The fish pulls the line wide from side to side, with a quick tremble on top.
			local sweep = math.sin(t * 1.6) * 3.2 + math.sin(t * 4.1) * 0.6
			bobber.Position = self.rest
				+ side * sweep
				+ forward * (math.sin(t * 0.9) * 0.8)
				+ Vector3.new(
					math.sin(t * 13) * 0.2,
					-0.35 + math.sin(t * 9) * 0.15,
					math.cos(t * 11) * 0.2
				)
			-- Bend the line toward the pull and hum with tension.
			beam.CurveSize0 = 1.2 + math.sin(t * 1.6) * 1.6
			beam.CurveSize1 = -1 + math.cos(t * 1.6) * 0.8
			local tension = math.abs(math.sin(t * 7.5))
			beam.Width0 = 0.07 + tension * 0.035
			beam.Width1 = 0.09 + tension * 0.045
			if not reduced() and t >= self.nextFightFx then
				self.nextFightFx = t + 0.58
				local waterSpot = Vector3.new(bobber.Position.X, SEA_Y, bobber.Position.Z)
				Effects.ripple(waterSpot, self.fightColor, 3.8, 0.55)
				Effects.splash(waterSpot, self.fightColor, 8)
			end
		end
		local band = bobber:FindFirstChild("Band")
		if band and band:IsA("BasePart") then
			band.CFrame = bobber.CFrame * CFrame.Angles(0, 0, math.rad(90))
		end
		beacon.CFrame = bobber.CFrame * CFrame.new(0, 0.44, 0)
	end)
	return self
end

local function pose(self: Line, sample: (number) -> CFrame?)
	if self.stopPose then
		self.stopPose()
	end
	local tool = self.tip:FindFirstAncestorOfClass("Tool")
	local character = tool and tool.Parent
	self.stopPose = if character and character:IsA("Model")
		then Pose.play(character, sample)
		else nil
end

-- Arcs the bobber from the rod tip to the water point; yields until it lands.
function Line.castTo(self: Line, target: Vector3)
	self.trail.Enabled = not reduced()
	pose(self, function(t)
		if t >= 0.68 then
			return nil
		end
		local angle = if t < 0.19
			then -math.sin(t / 0.19 * math.pi / 2) * 0.95
			else -0.95 * math.cos((t - 0.19) / 0.49 * math.pi * 1.5)
		return CFrame.Angles(angle, 0.12, 0)
	end)
	local from = self.tip.WorldPosition
	local to = Vector3.new(target.X, SEA_Y, target.Z)
	local apex = (from + to) / 2 + Vector3.new(0, 7, 0)
	local duration = 0.7
	local start = os.clock()
	while true do
		local a = math.min((os.clock() - start) / duration, 1)
		local p = from:Lerp(apex, a):Lerp(apex:Lerp(to, a), a)
		self.bobber.Position = p
		if a >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
	self.rest = to
	self.mode = "floating"
	self.trail.Enabled = false
	Effects.ripple(to, Color3.fromRGB(220, 245, 255), 3.4, 0.65)
	Effects.splash(to, Color3.fromRGB(205, 245, 255), 10)
end

function Line.setColor(self: Line, color: Color3)
	self.fightColor = color
	self.beam.Color = ColorSequence.new(Color3.fromRGB(240, 245, 255), color)
	self.beam.Width0 = 0.08
	self.beam.Width1 = 0.1
	self.beacon.Color = color
	self.beaconLight.Color = color
	self.beaconLight.Brightness = if reduced() then 0 else 2.6
	self.trail.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	local tipPart = self.tipPart
	if tipPart then
		tipPart.Color = color
		local glow = tipPart:FindFirstChild("TipGlow")
		if glow and glow:IsA("PointLight") then
			glow.Color = color
			glow.Brightness = 2.5
		end
	end
end

function Line.bite(self: Line, color: Color3)
	pose(self, function(t)
		return CFrame.Angles(-0.28 + math.sin(t * 9) * 0.16, 0.1, 0)
	end)
	Line.setColor(self, color)
	self.nextFightFx = 0
	self.mode = "fighting"
	Effects.ripple(self.rest, color, 6.2, 0.85)
	Effects.splash(self.rest, color, 18)
end

function Line.reelIn(self: Line, duration: number)
	pose(self, function(t)
		if t >= 0.95 then
			return nil
		end
		return CFrame.Angles(-math.sin(t / 0.95 * math.pi) * 0.85, 0, math.sin(t * 5) * 0.16)
	end)
	self.mode = "flying"
	self.trail.Enabled = not reduced()
	local goal = self.tip.WorldPosition
	local tween = TweenService:Create(
		self.bobber,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = goal }
	)
	tween:Play()
	-- Once it reaches the rod the bobber and line get out of the reveal's way.
	tween.Completed:Once(function()
		self.beam.Enabled = false
		self.trail.Enabled = false
		self.bobber.Transparency = 1
		self.beacon.Transparency = 1
		self.beaconLight.Brightness = 0
		local band = self.bobber:FindFirstChild("Band")
		if band and band:IsA("BasePart") then
			band.Transparency = 1
		end
	end)
end

function Line.snap(self: Line)
	if self.stopPose then
		self.stopPose()
		self.stopPose = nil
	end
	self.beam.Enabled = false
	self.mode = "flying"
	TweenService
		:Create(self.bobber, TweenInfo.new(0.6), { Position = self.rest - Vector3.new(0, 1.5, 0) })
		:Play()
end

function Line.destroy(self: Line)
	if self.stopPose then
		self.stopPose()
		self.stopPose = nil
	end
	local conn = self.conn
	if conn then
		conn:Disconnect()
	end
	self.bobber:Destroy()
	local tipPart = self.tipPart
	if tipPart then
		tipPart.Color = Color3.fromRGB(150, 230, 255)
		local glow = tipPart:FindFirstChild("TipGlow")
		if glow and glow:IsA("PointLight") then
			glow.Color = tipPart.Color
			glow.Brightness = 1.2
		end
	end
end

return Line
