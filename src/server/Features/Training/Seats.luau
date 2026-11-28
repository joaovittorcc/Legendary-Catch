--!strict
local CollectionService = game:GetService("CollectionService")

local Seats = {}
Seats.TAG = "TrainingSeat"
Seats.ENTER_RADIUS = 3.4
Seats.EXIT_RADIUS = 5

export type Station = { seat: Seat, stat: string }

local STOOL_TOPS: { [string]: boolean } = { StoolTop = true, SeatTop = true, StoolSeat = true }
local WOOD = Color3.fromRGB(127, 78, 46)

local function top(part: BasePart): number
	local cf, size = part.CFrame, part.Size
	return part.Position.Y
		+ (
				math.abs(cf.RightVector.Y) * size.X
				+ math.abs(cf.UpVector.Y) * size.Y
				+ math.abs(cf.LookVector.Y) * size.Z
			)
			* 0.5
end

local function waterPosition(spot: BasePart, container: Instance): Vector3
	local marker = spot:FindFirstChild("PracticeTarget")
	if marker and marker:IsA("Attachment") then
		return marker.WorldPosition
	end
	for _, name in { "WaterSurface", "Water", "PoolWater" } do
		local water = container:FindFirstChild(name, true)
		if water and water:IsA("BasePart") then
			return Vector3.new(water.Position.X, top(water) + 0.1, water.Position.Z)
		end
	end
	return spot.Position + spot.CFrame.LookVector * 8 - Vector3.yAxis * 2
end

local function mountSeat(
	folder: Folder,
	stat: string,
	position: Vector3,
	target: Vector3,
	visible: boolean
): Station
	local seat = Instance.new("Seat")
	seat.Name = "TrainingSeat"
	seat.Anchored = true
	seat.CanTouch = false
	seat.CanCollide = visible
	seat.CanQuery = visible
	seat.CastShadow = visible
	seat.Material = Enum.Material.Wood
	seat.Color = WOOD
	seat.Transparency = if visible then 0 else 1
	seat.Size = Vector3.new(1.6, 0.22, 1.6)
	local facing = Vector3.new(target.X, position.Y, target.Z)
	seat.CFrame = if (facing - position).Magnitude > 0.01
		then CFrame.lookAt(position, facing)
		else CFrame.new(position)
	seat:SetAttribute("TrainingStat", stat)
	local marker = Instance.new("Attachment")
	marker.Name = "PracticeTarget"
	marker.Position = seat.CFrame:PointToObjectSpace(target)
	marker.Parent = seat
	if visible then
		for _, offset in
			{
				Vector3.new(-0.52, -0.53, -0.52),
				Vector3.new(0.52, -0.53, -0.52),
				Vector3.new(-0.52, -0.53, 0.52),
				Vector3.new(0.52, -0.53, 0.52),
			}
		do
			local leg = Instance.new("Part")
			leg.Name = "Leg"
			leg.Anchored = true
			leg.CanTouch = false
			leg.Material = Enum.Material.Wood
			leg.Color = WOOD
			leg.Size = Vector3.new(0.18, 0.88, 0.18)
			leg.CFrame = seat.CFrame * CFrame.new(offset)
			leg.Parent = seat
		end
	end
	CollectionService:AddTag(seat, Seats.TAG)
	seat.Parent = folder
	return { seat = seat, stat = stat }
end

function Seats.build(spot: BasePart, stats: { string }): (Folder, { Station })
	local parent =
		assert(spot.Parent, "Training spot must be parented before seating is configured")
	local folder = Instance.new("Folder")
	folder.Name = "TrainingSeats"
	local stations: { Station } = {}
	local only = spot:GetAttribute("TrainingStat")
	local stat = if only == "Control" or only == "Instinct" then only else nil
	local pond = if stat
		then parent:FindFirstChild(if stat == "Control" then "FocusPond" else "InstinctPond")
		else nil
	local target = waterPosition(spot, pond or parent)

	if stat and pond then
		for _, candidate in pond:GetDescendants() do
			if candidate:IsA("BasePart") and STOOL_TOPS[candidate.Name] then
				local position =
					Vector3.new(candidate.Position.X, top(candidate) - 0.11, candidate.Position.Z)
				table.insert(stations, mountSeat(folder, stat, position, target, false))
			end
		end
	end
	if #stations == 0 then
		local deck = parent:FindFirstChild("TrainingDeck")
		local center = if deck and deck:IsA("BasePart")
			then Vector3.new(deck.Position.X, top(deck) + 1, deck.Position.Z)
			else spot.Position - Vector3.yAxis * 0.5
		local side = if deck and deck:IsA("BasePart")
			then deck.CFrame.RightVector
			else spot.CFrame.RightVector
		for index, name in stats do
			if stat and name ~= stat then
				continue
			end
			local offset = if stat then 0 else (index - (#stats + 1) / 2) * 4
			table.insert(stations, mountSeat(folder, name, center + side * offset, target, true))
		end
	end
	folder.Parent = spot
	return folder, stations
end

function Seats.distanceSquared(a: Vector3, b: Vector3): number
	local x, z = a.X - b.X, a.Z - b.Z
	return x * x + z * z
end

return Seats
