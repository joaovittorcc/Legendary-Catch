--!strict
-- Client-only visuals for the cast: glowing line (Beam) from the rod tip to a bobber that
-- arcs out over the water, bobs, dips on the bite and shakes during the fight.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Effects = require(script.Parent:WaitForChild("Effects"))

local SEA_Y = 0.25

export type Line = {
	bobber: BasePart,
	beam: Beam,
	tip: Attachment,
	tipPart: BasePart?,
	rest: Vector3,
	mode: string, -- "flying" | "floating" | "fighting"
	conn: RBXScriptConnection?,
}

local Line = {}

local function newBobber(): BasePart
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
	return bobber
end

function Line.create(tip: Attachment): Line
	local bobber = newBobber()
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
		beam = beam,
		tip = tip,
		tipPart = if tipPart and tipPart:IsA("BasePart") then tipPart else nil,
		rest = bobber.Position,
		mode = "flying",
		conn = nil,
	}

	local t = 0
	self.conn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		if self.mode == "floating" then
			bobber.Position = self.rest + Vector3.new(0, math.sin(t * 2.4) * 0.12, 0)
		elseif self.mode == "fighting" then
			bobber.Position = self.rest
				+ Vector3.new(
					math.sin(t * 13) * 0.35,
					-0.35 + math.sin(t * 9) * 0.15,
					math.cos(t * 11) * 0.35
				)
		end
		local band = bobber:FindFirstChild("Band")
		if band and band:IsA("BasePart") then
			band.CFrame = bobber.CFrame * CFrame.Angles(0, 0, math.rad(90))
		end
	end)
	return self
end

-- Arcs the bobber from the rod tip to the water point; yields until it lands.
function Line.castTo(self: Line, target: Vector3)
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
	Effects.ripple(to, Color3.fromRGB(220, 245, 255), 3, 0.6)
end

function Line.setColor(self: Line, color: Color3)
	self.beam.Color = ColorSequence.new(Color3.fromRGB(240, 245, 255), color)
	self.beam.Width0 = 0.08
	self.beam.Width1 = 0.1
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
	Line.setColor(self, color)
	self.mode = "fighting"
	Effects.ripple(self.rest, color, 6, 0.8)
	Effects.splash(self.rest, color, 14)
end

function Line.reelIn(self: Line, duration: number)
	self.mode = "flying"
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
		self.bobber.Transparency = 1
		local band = self.bobber:FindFirstChild("Band")
		if band and band:IsA("BasePart") then
			band.Transparency = 1
		end
	end)
end

function Line.snap(self: Line)
	self.beam.Enabled = false
	self.mode = "flying"
	TweenService
		:Create(self.bobber, TweenInfo.new(0.6), { Position = self.rest - Vector3.new(0, 1.5, 0) })
		:Play()
end

function Line.destroy(self: Line)
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
