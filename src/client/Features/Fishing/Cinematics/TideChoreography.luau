--!strict
local Tide = {}

Tide.IMPACT = 2.25
Tide.RISE = 3.05
Tide.GRIP = 5.6
Tide.LIFT = 6.05
Tide.CROWN = 7.9
Tide.RELEASE = 9.85
Tide.REST = 11.85

local UP = Vector3.yAxis
local CYAN = Color3.fromRGB(53, 240, 255)
local GOLD = Color3.fromRGB(255, 197, 82)
local VIOLET = Color3.fromRGB(147, 107, 255)

local function ease(t: number, start: number, finish: number): number
	local p = math.clamp((t - start) / (finish - start), 0, 1)
	return p * p * (3 - 2 * p)
end

type Joint = { part: BasePart, rest: CFrame, shoulder: Vector3 }
export type Draw = (number, CFrame, CFrame) -> Vector3?

local function joint(model: Model, name: string, shoulder: Vector3): Joint?
	local part = model:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return {
			part = part,
			rest = model:GetPivot():ToObjectSpace(part.CFrame),
			shoulder = shoulder,
		}
	end
	return nil
end

local function turn(arm: Joint, angle: CFrame): CFrame
	return CFrame.new(arm.shoulder) * angle * CFrame.new(-arm.shoulder)
end

local function spark(parent: Folder, tint: Color3): Part
	local part = Instance.new("Part")
	part.Name = "CrownSpark"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * 0.24
	part.Material = Enum.Material.Neon
	part.Color = tint
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Parent = parent
	return part
end

function Tide.bind(model: Model, falling: BasePart, scene: Folder, scale: number): Draw?
	local blade = model:FindFirstChild("Sword")
	local right = joint(model, "FinR", Vector3.new(-0.46, 0.47, 0.07) * scale)
	local left = joint(model, "FinL", Vector3.new(0.46, 0.47, 0.07) * scale)
	if not (blade and blade:IsA("BasePart") and right and left) then
		return nil
	end
	local rightArm: Joint, leftArm: Joint, sword: BasePart = right, left, blade
	local swordRest = model:GetPivot():ToObjectSpace(sword.CFrame)
	local bladeTransparency = sword.Transparency
	local tipLength = sword.Size.Y * 0.47
	sword.Transparency = 1
	local sparks = {}
	for i = 1, 14 do
		sparks[i] = spark(scene, if i % 3 == 0 then GOLD else if i % 2 == 0 then CYAN else VIOLET)
	end
	return function(t, pivot, waterBlade)
		local cut = ease(t, Tide.RELEASE, Tide.RELEASE + 0.64)
		local lift = ease(t, Tide.LIFT, Tide.CROWN) - cut
		local reach = ease(t, Tide.RISE + 0.6, Tide.GRIP - 0.42)
			* (1 - ease(t, Tide.GRIP - 0.32, Tide.GRIP))
		local follow = cut * (1 - ease(t, Tide.RELEASE + 0.48, Tide.REST))
		local lead = turn(
			rightArm,
			CFrame.Angles(-2.51 * lift + 0.56 * reach + 0.24 * follow, -0.93 * lift, 0.1 * follow)
		)
		local open = ease(t, Tide.LIFT + 0.19, Tide.CROWN) - ease(t, Tide.RELEASE + 0.28, Tide.REST)
		local offhand = turn(leftArm, CFrame.Angles(-0.22 * open, 0.75 * open, -0.5 * open))
		rightArm.part.CFrame = pivot * lead * rightArm.rest
		leftArm.part.CFrame = pivot * offhand * leftArm.rest
		local held = pivot * lead * swordRest
		local grab = ease(t, Tide.GRIP - 1.02, Tide.GRIP)
		if t < Tide.GRIP then
			falling.CFrame = waterBlade:Lerp(held, grab) + UP * (math.sin(grab * math.pi) * 1.05)
		else
			falling.Transparency = 1
			sword.Transparency = bladeTransparency
		end
		sword.CFrame = held

		local tip = held.Position - held.UpVector * tipLength
		local aura = ease(t, Tide.LIFT + 0.3, Tide.CROWN + 0.4)
			* (1 - ease(t, Tide.RELEASE + 0.36, Tide.REST))
		local release = ease(t, Tide.RELEASE, Tide.REST)
		local charge = ease(t, Tide.LIFT, Tide.RELEASE)
		for i, orb in sparks do
			local angle = i * 2.39996 + t * (1.42 + charge * 1.7)
			local radius = 1.8 + (1 - charge) * 3.8 + release * 19
			local position = Vector3.new(
				math.cos(angle) * radius,
				math.sin(angle * 0.5 + i) * (0.95 + release * 1.6) - release * 3,
				math.sin(angle) * radius
			)
			orb.Position = tip + position
			orb.Transparency = 1 - aura * (0.63 + 0.24 * math.sin(t * 8 + i))
		end
		return if t >= Tide.GRIP then tip else nil
	end
end

return Tide
