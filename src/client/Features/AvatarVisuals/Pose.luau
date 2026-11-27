--!strict
local RunService = game:GetService("RunService")

local Pose = {}
type Joint = { Transform: CFrame, Parent: Instance? }

local function adaptOffset(name: string, offset: CFrame): CFrame
	if name == "Right Shoulder" then
		local rx, ry, rz = offset:ToEulerAnglesXYZ()
		return CFrame.Angles(-rz, ry, rx)
	end
	return offset
end

function Pose.play(character: Model, sample: (number) -> CFrame?): () -> ()
	local joints: { { joint: Joint, name: string, strength: number, base: CFrame, applied: CFrame? } } =
		{}
	for _, child in character:GetDescendants() do
		if
			child.Name == "RightShoulder"
			or child.Name == "Right Shoulder"
			or child.Name == "Waist"
		then
			if child:IsA("Motor6D") or child.ClassName == "AnimationConstraint" then
				-- The bundled Roblox definitions predate AnimationConstraint.
				local joint = (child :: any) :: Joint
				table.insert(joints, {
					joint = joint,
					name = child.Name,
					strength = if child.Name == "Waist" then 0.22 else 1,
					base = joint.Transform,
				})
			end
		end
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	local start = os.clock()
	local connection: RBXScriptConnection? = nil
	local function stop()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		for _, entry in joints do
			if entry.joint.Parent and entry.joint.Transform == entry.applied then
				entry.joint.Transform = entry.base
			end
		end
	end
	connection = RunService.PreSimulation:Connect(function()
		local offset = sample(os.clock() - start)
		if not offset or not character.Parent or (hum ~= nil and hum.Health <= 0) then
			stop()
			return
		end
		for _, entry in joints do
			local joint = entry.joint
			if joint.Parent then
				if joint.Transform ~= entry.applied then
					entry.base = joint.Transform
				end
				local adapted = adaptOffset(entry.name, offset)
				joint.Transform = entry.base * CFrame.new():Lerp(adapted, entry.strength)
				entry.applied = joint.Transform
			end
		end
	end)
	return stop
end

return Pose
