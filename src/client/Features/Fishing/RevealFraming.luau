--!strict
local Framing = {}

local THREE_QUARTER = math.rad(24)
local MIN_AXIS_ALIGNMENT = 0.42
local FACE_YAW: { [string]: number } = {
	-- The visible face differs from the axis between the mesh parts.
	C12_Camarao_Confete = math.rad(-45),
}

export type Bounds = { center: Vector3, corners: { Vector3 }, forward: Vector3 }

local function partPosition(model: Model, name: string): Vector3?
	local part = model:FindFirstChild(name, true)
	return if part and part:IsA("BasePart") then part.Position else nil
end

function Framing.measure(model: Model): Bounds
	local pivot = model:GetPivot()
	local box, size = model:GetBoundingBox()
	local relative = pivot:ToObjectSpace(box)
	local half = size / 2
	local corners = {}
	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				table.insert(
					corners,
					relative:VectorToWorldSpace(Vector3.new(x * half.X, y * half.Y, z * half.Z))
				)
			end
		end
	end

	local head, tail = partPosition(model, "Head"), partPosition(model, "Tail")
	local body = model.PrimaryPart
	local center = if body then body.Position else box.Position
	local axis = if head
		then head - (tail or center)
		elseif tail then center - tail
		else Vector3.zero
	axis = pivot:VectorToObjectSpace(axis)
	local flat = Vector3.new(axis.X, 0, axis.Z)
	-- Upright creatures often have a tail below the head. The projected axis is
	-- only useful if it spans a meaningful part of the creature's length.
	local minLength = if head and tail then 0.1 else math.max(size.X, size.Y, size.Z) * 0.22
	local reliable = flat.Magnitude >= math.max(axis.Magnitude * MIN_AXIS_ALIGNMENT, minLength)
	local yaw = FACE_YAW[model.Name]
	return {
		center = relative.Position,
		corners = corners,
		forward = if yaw
			then Vector3.new(math.sin(yaw), 0, math.cos(yaw))
			elseif reliable then flat.Unit
			else Vector3.zAxis,
	}
end

function Framing.pose(bounds: Bounds, center: Vector3, towardViewer: Vector3, turn: number?): CFrame
	local yaw = math.atan2(towardViewer.X, towardViewer.Z)
	local localYaw = math.atan2(bounds.forward.X, bounds.forward.Z)
	local rotation = CFrame.Angles(0, yaw - localYaw + THREE_QUARTER + (turn or 0), 0)
	return CFrame.new(center) * rotation * CFrame.new(-bounds.center)
end

-- Fit the corners in the available screen rectangle, accounting for depth and
-- an off-center composition. cameraAxes looks from the viewer toward the fish.
function Framing.camera(
	bounds: Bounds,
	pose: CFrame,
	cameraAxes: CFrame,
	center: Vector3,
	viewport: Vector2,
	fov: number,
	region: Rect,
	padding: number
): CFrame
	local tanY = math.tan(math.rad(fov) / 2)
	local tanX = tanY * viewport.X / math.max(viewport.Y, 1)
	local target = (region.Min + region.Max) / 2
	local x = (2 * target.X - 1) * tanX
	local y = (1 - 2 * target.Y) * tanY
	local width = region.Width * tanX
	local height = region.Height * tanY
	local distance = 0.5
	for _, corner in bounds.corners do
		local point = cameraAxes:VectorToObjectSpace(pose:VectorToWorldSpace(corner)) * padding
		distance = math.max(
			distance,
			point.Z + math.abs(point.X + x * point.Z) / width,
			point.Z + math.abs(point.Y + y * point.Z) / height
		)
	end
	local eye = center + cameraAxes:VectorToWorldSpace(Vector3.new(-x, -y, 1) * distance)
	return CFrame.new(eye) * cameraAxes.Rotation
end

return Framing
