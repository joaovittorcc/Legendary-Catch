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
	band: BasePart,
	beacon: BasePart,
	beaconLight: PointLight,
	trail: Trail,
	beam: Beam,
	tip: Attachment,
	tipPart: BasePart?,
	rest: Vector3,
	fightColor: Color3,
	nextFightFx: number,
	mode: string,
	hookAt: number,
	pulseAt: number,
	pulse: number,
	tipColor: Color3?,
	tipLight: PointLight?,
	tipLightColor: Color3?,
	tipLightBrightness: number?,
	recovery: Tween?,
	conn: RBXScriptConnection?,
	stopPose: (() -> ())?,
}

local Line = {}
local localLine: Line? = nil

local function newBobber(): (BasePart, BasePart, BasePart, PointLight, Trail)
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

	return bobber, band, beacon, beaconLight, trail
end

function Line.create(tip: Attachment): Line
	local bobber, band, beacon, beaconLight, trail = newBobber()
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

	local attachmentParent = tip.Parent
	local tipPart = if attachmentParent and attachmentParent:IsA("BasePart")
		then attachmentParent
		else nil
	local light = tipPart and tipPart:FindFirstChild("TipGlow")
	local tipLight = if light and light:IsA("PointLight") then light else nil
	local self: Line = {
		bobber = bobber,
		band = band,
		beacon = beacon,
		beaconLight = beaconLight,
		trail = trail,
		beam = beam,
		tip = tip,
		tipPart = tipPart,
		tipColor = if tipPart then tipPart.Color else nil,
		tipLight = tipLight,
		tipLightColor = if tipLight then tipLight.Color else nil,
		tipLightBrightness = if tipLight then tipLight.Brightness else nil,
		rest = bobber.Position,
		fightColor = DEFAULT_LINE_COLOR,
		nextFightFx = 0,
		mode = "flying",
		hookAt = -math.huge,
		pulseAt = -math.huge,
		pulse = 0,
		recovery = nil,
		conn = nil,
		stopPose = nil,
	}

	local t = 0
	local nextIdleRipple = 0
	self.conn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		if not tip.Parent or not bobber.Parent then
			return
		end
		local isReduced = reduced()
		local now = os.clock()
		local out = (self.rest - tip.WorldPosition) * Vector3.new(1, 0, 1)
		local side = if out.Magnitude > 0.01 then out.Unit:Cross(Vector3.yAxis) else Vector3.xAxis
		local forward = if out.Magnitude > 0.01 then out.Unit else Vector3.zAxis
		if self.mode == "floating" then
			local drift = if isReduced then 0.38 else 1
			bobber.Position = self.rest
				+ side * (math.sin(t * 0.82) * 0.72 * drift)
				+ Vector3.new(0, math.sin(t * 2.6) * 0.11 * drift, 0)
			beam.CurveSize0 = 2.1 + math.sin(t * 0.82) * 0.48 * drift
			beam.CurveSize1 = -1.8
			if self == localLine and t >= nextIdleRipple then
				nextIdleRipple = t + 2.1
				local water = Vector3.new(bobber.Position.X, SEA_Y, bobber.Position.Z)
				Effects.ripple(water, DEFAULT_LINE_COLOR, 1.65, 0.85, true)
			end
		elseif self.mode == "fighting" then
			local hook = math.max(0, 1 - (now - self.hookAt) / 0.30)
			local pulse = self.pulse * math.max(0, 1 - (now - self.pulseAt) / 0.38)
			local energy = if isReduced then 0.34 else 1
			local sweep = (math.sin(t * 1.6) * 2.55 + math.sin(t * 4.1) * 0.38) * energy
			bobber.Position = self.rest
				+ side * sweep * (1 - hook)
				+ forward * ((math.sin(t * 0.9) * 0.68 + pulse * 0.55) * energy)
				+ Vector3.yAxis
					* (-0.28 - hook * 0.73 + (math.sin(t * 9) * 0.12 - pulse * 0.20) * energy)
			beam.CurveSize0 = 0.22 + sweep * 0.36 + math.max(0, -pulse) * 1.7
			beam.CurveSize1 = -0.28 - math.max(0, -pulse) * 0.8
			beam.Width0 = 0.062 + (hook + math.abs(pulse)) * 0.026
			beam.Width1 = 0.088 + (hook + math.abs(pulse)) * 0.028
			if
				self == localLine
				and not isReduced
				and now - self.hookAt >= 0.62
				and t >= self.nextFightFx
			then
				self.nextFightFx = t + 0.85
				local water = Vector3.new(bobber.Position.X, SEA_Y, bobber.Position.Z)
				Effects.ripple(water, self.fightColor, 2.65, 0.50, true)
			end
		end
		if isReduced and trail.Enabled then
			trail.Enabled = false
		end
		if self.mode == "floating" or self.mode == "fighting" then
			local brightness = if self.mode == "fighting" then 2.1 else 1.1
			beaconLight.Brightness = if isReduced then 0 else brightness
		end
		band.CFrame = bobber.CFrame * CFrame.Angles(0, 0, math.rad(90))
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
	localLine = self
	local to = Vector3.new(target.X, SEA_Y, target.Z)
	self.rest = to
	pose(self, function(t)
		if t >= 0.64 then
			return nil
		end
		local angle = if t < 0.14
			then -math.sin(t / 0.14 * math.pi / 2) * 0.82
			elseif t < 0.28 then -0.82 + math.sin((t - 0.14) / 0.14 * math.pi / 2) * 1.78
			else 0.96 * math.max(0, 1 - (t - 0.28) / 0.36) ^ 2
		return CFrame.Angles(angle, 0.1, 0)
	end)
	local from = self.tip.WorldPosition
	local start = os.clock()
	local trail = self.trail
	local firstWidth, firstLifetime = trail.WidthScale, trail.Lifetime
	trail.Lifetime = 0.34
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.8),
		NumberSequenceKeypoint.new(0.45, 0.84),
		NumberSequenceKeypoint.new(1, 0),
	})
	while self.mode == "flying" and self.bobber.Parent and self.tip.Parent do
		local elapsed = os.clock() - start
		if elapsed < 0.14 then
			from = self.tip.WorldPosition
			self.bobber.Position = from
			self.trail.Enabled = false
		else
			local progress = math.clamp((elapsed - 0.14) / 0.56, 0, 1)
			local apex = (from + to) / 2 + Vector3.yAxis * 9
			local travel = 1 - (1 - progress) ^ 1.35
			self.bobber.Position = from:Lerp(apex, travel):Lerp(apex:Lerp(to, travel), travel)
			self.trail.Enabled = not reduced()
			if progress >= 1 then
				self.mode = "floating"
				self.trail.Enabled = false
				local quiet = reduced()
				Effects.ripple(to, Color3.fromRGB(220, 245, 255), if quiet then 3.1 else 5.1, 0.55)
				Effects.splash(to, Color3.fromRGB(205, 245, 255), if quiet then 8 else 19)
				break
			end
		end
		RunService.RenderStepped:Wait()
	end
	if trail.Parent then
		trail.WidthScale, trail.Lifetime = firstWidth, firstLifetime
	end
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
		local glow = self.tipLight
		if glow then
			glow.Color = color
			glow.Brightness = if reduced() then 0 else 2.1
		end
	end
end

function Line.bite(self: Line, color: Color3)
	self.hookAt = os.clock()
	pose(self, function(t)
		local impulse = math.max(0, 1 - t / 0.33)
		local pulse = self.pulse * math.max(0, 1 - (os.clock() - self.pulseAt) / 0.36)
		local energy = if reduced() then 0.28 else 1
		return CFrame.Angles(-0.25 - (impulse * 0.47 + pulse * 0.23) * energy, 0.1, 0)
	end)
	Line.setColor(self, color)
	self.trail.Enabled = false
	self.nextFightFx = 0
	self.mode = "fighting"
	Effects.ripple(self.rest, color, 5.6, 0.72)
	Effects.splash(self.rest, color, 14)
end

function Line.feedback(success: boolean, perfect: boolean?)
	local line = localLine
	if not line or line.mode ~= "fighting" then
		return
	end
	line.pulseAt = os.clock()
	line.pulse = if perfect then 1 elseif success then 0.62 else -0.72
end

function Line.reelIn(self: Line, duration: number)
	pose(self, function(t)
		if t >= 0.95 then
			return nil
		end
		return CFrame.Angles(-math.sin(t / 0.95 * math.pi) * 0.85, 0, math.sin(t * 5) * 0.16)
	end)
	self.mode = "reeling"
	Effects.ripple(self.rest, self.fightColor:Lerp(Color3.new(1, 1, 1), 0.4), 3.4, 0.42, true)
	self.beam.CurveSize0 = 0.4
	self.beam.CurveSize1 = -0.32
	self.trail.Enabled = not reduced()
	local goal = self.tip.WorldPosition
	local tween = TweenService:Create(
		self.bobber,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = goal }
	)
	self.recovery = tween
	tween:Play()
	-- Once it reaches the rod the bobber and line get out of the reveal's way.
	tween.Completed:Once(function(state)
		if state ~= Enum.PlaybackState.Completed or self.mode ~= "reeling" then
			return
		end
		self.beam.Enabled = false
		self.trail.Enabled = false
		self.bobber.Transparency = 1
		self.beacon.Transparency = 1
		self.beaconLight.Brightness = 0
		self.band.Transparency = 1
	end)
end

function Line.snap(self: Line)
	if self.stopPose then
		self.stopPose()
		self.stopPose = nil
	end
	self.mode = "recovering"
	self.trail.Enabled = false
	self.beam.CurveSize0 = 2.4
	self.beam.CurveSize1 = -1.8
	local tween = TweenService:Create(
		self.bobber,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = self.tip.WorldPosition }
	)
	self.recovery = tween
	tween:Play()
end

function Line.destroy(self: Line)
	self.mode = "destroyed"
	if localLine == self then
		localLine = nil
	end
	if self.recovery then
		self.recovery:Cancel()
		self.recovery = nil
	end
	if self.stopPose then
		self.stopPose()
		self.stopPose = nil
	end
	local conn = self.conn
	if conn then
		conn:Disconnect()
		self.conn = nil
	end
	self.bobber:Destroy()
	local tipPart = self.tipPart
	if tipPart and tipPart.Parent then
		if self.tipColor then
			tipPart.Color = self.tipColor
		end
		local glow = self.tipLight
		if glow and glow.Parent and self.tipLightColor and self.tipLightBrightness then
			glow.Color = self.tipLightColor
			glow.Brightness = self.tipLightBrightness
		end
	end
end

return Line
