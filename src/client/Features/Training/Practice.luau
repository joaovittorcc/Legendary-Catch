--!strict
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Features = script.Parent.Parent
local Pose = require(Features.AvatarVisuals.Pose)
local Effects = require(Features.Fishing.Effects)
local Ui = require(Features.Fishing.Ui)

local Practice = {}

export type Session = {
	bobber: Part,
	target: Vector3,
	pull: number,
	bite: boolean,
	drilling: boolean,
	reelAt: number?,
	stop: () -> (),
}

local function waterTarget(character: Model, root: BasePart): Vector3
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if not seat or not CollectionService:HasTag(seat, "TrainingSeat") then
		local distance = 6
		seat = nil
		for _, candidate in CollectionService:GetTagged("TrainingSeat") do
			if candidate:IsA("Seat") then
				local gap = (candidate.Position - root.Position).Magnitude
				if gap < distance then
					seat, distance = candidate, gap
				end
			end
		end
	end
	local seatTarget = seat and seat:FindFirstChild("PracticeTarget")
	if seatTarget and seatTarget:IsA("Attachment") then
		return seatTarget.WorldPosition
	end
	local nearest: BasePart? = nil
	local distance = 20
	for _, spot in CollectionService:GetTagged("TrainingSpot") do
		if spot:IsA("BasePart") then
			local gap = (spot.Position - root.Position).Magnitude
			if gap < distance then
				nearest, distance = spot, gap
			end
		end
	end
	local marker = nearest and nearest:FindFirstChild("PracticeTarget")
	if marker and marker:IsA("Attachment") then
		return marker.WorldPosition
	end
	local pool = nearest and nearest.Parent and nearest.Parent:FindFirstChild("PoolWater", true)
	if pool and pool:IsA("BasePart") then
		return pool.Position + Vector3.yAxis * 0.18
	end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	local forward = root.CFrame.LookVector
	local fallback = root.Position + forward * 8 - Vector3.yAxis * 2.6
	for _, angle in { 0, 45, -45, 90, -90, 180 } do
		local heading = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(angle))
			:VectorToWorldSpace(forward)
		for _, reach in { 8, 12, 5, 16 } do
			local hit = Workspace:Raycast(
				root.Position + heading * reach + Vector3.yAxis * 3,
				-Vector3.yAxis * 22,
				params
			)
			if
				hit
				and (
					hit.Material == Enum.Material.Water
					or hit.Instance.Name:lower():find("water", 1, true)
				)
			then
				return hit.Position + Vector3.yAxis * 0.1
			end
		end
	end
	return fallback
end

local function part(parent: Instance, name: string, size: Vector3, color: Color3): Part
	local object = Instance.new("Part")
	object.Name = name
	object.Size = size
	object.Color = color
	object.Anchored = true
	object.CanCollide = false
	object.CanTouch = false
	object.CanQuery = false
	object.CastShadow = false
	object.Material = Enum.Material.SmoothPlastic
	object.Parent = parent
	return object
end

function Practice.start(character: Model, root: BasePart, color: Color3, quiet: boolean?): Session
	local target = waterTarget(character, root)
	local folder = Instance.new("Folder")
	folder.Name = "TrainingPractice"
	local bobber = part(folder, "TrainingBobber", Vector3.new(0.47, 0.47, 0.47), color)
	bobber.Shape = Enum.PartType.Ball
	local cap =
		part(folder, "FloatCap", Vector3.new(0.36, 0.28, 0.36), Color3.fromRGB(255, 243, 214))
	cap.Shape = Enum.PartType.Ball
	local rod =
		part(folder, "TrainingRod", Vector3.new(0.11, 0.11, 3.65), Color3.fromRGB(57, 45, 72))
	local grip = part(folder, "Grip", Vector3.new(0.23, 0.23, 0.8), Color3.fromRGB(144, 88, 63))
	local reel = part(folder, "Reel", Vector3.new(0.25, 0.43, 0.43), Color3.fromRGB(240, 179, 80))
	reel.Shape = Enum.PartType.Cylinder
	local tip = Instance.new("Attachment")
	tip.Position = Vector3.new(0, 0, -rod.Size.Z / 2)
	tip.Parent = rod
	local float = Instance.new("Attachment")
	float.Parent = bobber
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = tip, float
	beam.Color = ColorSequence.new(Color3.fromRGB(245, 249, 255), color)
	beam.Width0, beam.Width1 = 0.055, 0.04
	beam.FaceCamera = true
	beam.LightEmission = 0.55
	beam.Parent = bobber
	folder.Parent = character

	local start = os.clock()
	local cast = -1
	local tool = character:FindFirstChild("Rod")
	local rodTip = tool and tool:FindFirstChild("LineAttachment", true)
	local equippedTip = if rodTip and rodTip:IsA("Attachment") then rodTip else nil
	local session: Session = {
		bobber = bobber,
		target = target,
		pull = 0,
		bite = false,
		drilling = false,
		reelAt = nil,
		stop = function() end,
	}
	local stopPose = Pose.play(character, function(t)
		local phase = t % 8
		local swept = if phase < 0.85 and not session.drilling
			then math.sin(phase / 0.85 * math.pi) * 0.87
			else 0
		local reeling = session.reelAt and os.clock() - session.reelAt < 0.9
		return CFrame.Angles(
			-0.46 - swept - session.pull * 0.54 - (if reeling then 0.58 else 0),
			0.08,
			0.05
		)
	end)
	local connection = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local elapsed = now - start
		local phase = elapsed % 8
		local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
		local from = if hand and hand:IsA("BasePart")
			then hand.Position
			else root.Position + root.CFrame.RightVector
		local sweep = if phase < 0.74 and not session.drilling
			then math.sin(phase / 0.74 * math.pi)
			else 0
		local toward = (target - from) * Vector3.new(1, 0, 1)
		local forward = if toward.Magnitude > 0.1 then toward.Unit else root.CFrame.LookVector
		local pitch = 0.5 + sweep * 2.4 + session.pull * 0.45
		local direction = forward * math.cos(pitch) + Vector3.yAxis * math.sin(pitch)
		local right = forward:Cross(Vector3.yAxis)
		local frame = CFrame.lookAt(from, from + direction, right:Cross(direction))
		rod.CFrame = frame * CFrame.new(0, 0, -1.56)
		grip.CFrame = frame
		reel.CFrame = frame * CFrame.new(0, -0.25, -0.25)
		local activeTip = if equippedTip and equippedTip:IsDescendantOf(character)
			then equippedTip
			else tip
		if beam.Attachment0 ~= activeTip then
			beam.Attachment0 = activeTip
			local transparency = if activeTip == tip then 0 else 1
			rod.Transparency, grip.Transparency, reel.Transparency =
				transparency, transparency, transparency
		end
		local reelAt = session.reelAt
		local manualReel = if reelAt then now - reelAt else math.huge
		local flight = math.clamp((phase - 0.43) / 0.69, 0, 1)
		if session.drilling then
			flight = 1
		end
		local position = activeTip.WorldPosition:Lerp(target, flight)
			+ Vector3.yAxis * (math.sin(flight * math.pi) * 4.1 + math.sin(elapsed * 5) * 0.08)
		if session.bite then
			position = target - Vector3.yAxis * 0.58
		elseif session.pull > 0 then
			position += root.CFrame.RightVector * math.sin(elapsed * 10) * session.pull * 0.65
		elseif not session.drilling and (manualReel < 1.2 or phase > 7) then
			local progress = if manualReel < 1.2
				then math.clamp(manualReel / 0.9, 0, 1)
				else phase - 7
			position = target:Lerp(activeTip.WorldPosition, progress)
				+ Vector3.yAxis * math.sin(progress * math.pi)
		end
		bobber.Position = position
		cap.Position = position + Vector3.yAxis * 0.17
		beam.CurveSize0 = if session.pull > 0 or session.bite then 0.07 else 0.5
		local cycle = math.floor(elapsed / 8)
		if cast ~= cycle and phase >= 1.12 then
			cast = cycle
			if not quiet and not Ui.reduced() then
				Effects.ripple(target, color, 3.3, 0.65)
				Effects.splash(target, color, 8)
			end
		end
	end)
	session.stop = function()
		connection:Disconnect()
		stopPose()
		folder:Destroy()
	end
	return session
end

return Practice
