--!strict
local Cosmic = {}

Cosmic.BREACH = 1.55
Cosmic.OPEN = 3.3
Cosmic.COIL = 7.6
Cosmic.CHARGE = 8.85
Cosmic.RELEASE = 10.7
Cosmic.REST = 12.8

local CYAN = Color3.fromRGB(85, 237, 255)
local VIOLET = Color3.fromRGB(172, 96, 255)
local GOLD = Color3.fromRGB(255, 210, 131)
local WHITE = Color3.fromRGB(245, 234, 255)

local function ease(t: number, first: number, last: number): number
	local p = math.clamp((t - first) / (last - first), 0, 1)
	return p * p * (3 - 2 * p)
end

export type Pose = {
	offset: Vector3,
	phase: number,
	bank: number,
	yaw: number,
	lensYaw: number,
	charge: number,
}

function Cosmic.pose(t: number, height: number): Pose
	local breach = ease(t, Cosmic.BREACH, Cosmic.OPEN)
	local travel = ease(t, Cosmic.OPEN - 0.36, Cosmic.COIL)
	local uncoiled = math.sin(math.pi * travel)
	local coil = ease(t, Cosmic.COIL - 1.15, Cosmic.CHARGE)
	local charge = ease(t, Cosmic.CHARGE - 0.6, Cosmic.RELEASE)
		* (1 - ease(t, Cosmic.RELEASE + 0.13, Cosmic.REST))
	local recoil = math.sin(math.pi * ease(t, Cosmic.RELEASE, Cosmic.RELEASE + 1.72))
	return {
		offset = Vector3.new(
			-4.8 * breach * (1 - travel) + 6.2 * uncoiled - recoil * 0.52,
			-height * 0.24 + breach * 7.35 + uncoiled * 2.8 + charge * 0.58 - recoil * 0.46,
			-2.3 * uncoiled + 2.0 * coil
		),
		phase = travel * 6.65 + coil * 1.33,
		bank = uncoiled * 1.34 - recoil * 0.12,
		yaw = -0.36 - uncoiled * 0.46 + coil * 1.03,
		lensYaw = 0.79 - travel * 1.04 - coil * 0.43,
		charge = charge,
	}
end

type Satellite = { object: Part, trail: Trail }

local function satellite(parent: Folder, tint: Color3): Satellite
	local orb = Instance.new("Part")
	orb.Name = "CosmicSatellite"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.one * 0.29
	orb.Material = Enum.Material.Neon
	orb.Color = tint
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.CanTouch = false
	orb.CastShadow = false
	orb.Transparency = 1
	local upper = Instance.new("Attachment")
	upper.Position = Vector3.new(0, 0.12, 0)
	upper.Parent = orb
	local lower = Instance.new("Attachment")
	lower.Position = Vector3.new(0, -0.12, 0)
	lower.Parent = orb
	local trail = Instance.new("Trail")
	trail.Name = "StardustTrail"
	trail.Attachment0 = upper
	trail.Attachment1 = lower
	trail.Color = ColorSequence.new(WHITE, tint)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.24),
		NumberSequenceKeypoint.new(0.48, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Lifetime = 0.32
	trail.FaceCamera = true
	trail.LightEmission = 0.75
	trail.MinLength = 0.08
	trail.Enabled = false
	trail.Parent = orb
	orb.Parent = parent
	return { object = orb, trail = trail }
end

export type Draw = (number, Vector3, Vector3, Vector3) -> Vector3

function Cosmic.bind(scene: Folder, model: Model): Draw
	local instance = model:FindFirstChild("OrbitCore", true)
	local core = if instance and instance:IsA("Bone") then instance else nil
	local orbs: { Satellite } = {}
	for i = 1, 8 do
		orbs[i] = satellite(scene, if i % 4 == 0 then GOLD else if i % 2 == 0 then CYAN else VIOLET)
	end
	return function(t, center, side, forward)
		local point = if core then core.TransformedWorldCFrame.Position else center
		local appear = ease(t, Cosmic.OPEN - 0.4, Cosmic.OPEN + 0.55)
		local gather = ease(t, Cosmic.COIL - 0.3, Cosmic.RELEASE)
		local blast = ease(t, Cosmic.RELEASE, Cosmic.REST)
		local radius = 5.75 - 3.65 * gather + 19 * blast
		local alpha = appear * (1 - ease(t, Cosmic.RELEASE + 0.48, Cosmic.REST))
		for i, orb in orbs do
			local angle = i * 2.39996 + t * 1.3 + gather * 3.85
			local arc = angle + (i % 2) * 0.36
			local shift = side * (math.cos(arc) * radius)
				+ forward * (math.sin(arc) * radius * 0.57)
				+ Vector3.yAxis * (math.sin(arc * 1.1 + i) * (radius * 0.43) - blast * 3.8)
			orb.object.Position = point + shift
			orb.object.Transparency = 1 - alpha * (0.84 + 0.12 * math.sin(t * 7 + i))
			orb.trail.Enabled = alpha > 0.12
		end
		return point
	end
end

return Cosmic
