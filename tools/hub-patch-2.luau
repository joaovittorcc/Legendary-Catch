--!strict
-- Second live patch for the saved place (Edit mode). Mirrors HubBuilder_claude as of 2026-11-25:
--   1. scoreboards on an arc around the plaza (three angled screens), 1.6x, lower and further left (clear of the lagoon palm);
--   2. the crystal fountain in the middle of the plaza is removed;
--   3. the three sanctuary portals are re-centred (161 / 215 / 269 deg), lanterns re-spaced.
-- Safe to run twice. Returns a short report.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local island = Workspace:FindFirstChild("Island") :: Instance
assert(island, "Workspace.Island missing")
local report = {}

local function posOf(d: Instance): Vector3?
	if d:IsA("Model") then
		return d:GetPivot().Position
	elseif d:IsA("BasePart") then
		return d.Position
	end
	return nil
end

local function moveBy(d: Instance, xf: (CFrame) -> CFrame)
	if d:IsA("Model") then
		d:PivotTo(xf(d:GetPivot()))
	elseif d:IsA("BasePart") then
		d.CFrame = xf(d.CFrame)
	end
end

-- 1. Scoreboards ------------------------------------------------------------------------------
local S = 1.6
local ARC_CENTER = Vector3.new(-8, 44, 14)
local ARC_MID = Vector3.new(-66.9, 44, 65.2)
local ARC_STEP = 19
local SCREENS =
	{ "LeaderboardScreen_Catches", "LeaderboardScreen_Species", "LeaderboardScreen_Level" }
local SCALED =
	{ BoardFrame = true, BoardGlowRim = true, BoardBack = true, BoardCrest = true, BoardGem = true }

local boardModel: Instance? = nil
for _, m in CollectionService:GetTagged("LeaderboardBoard") do
	if m:IsDescendantOf(island) then
		boardModel = m
	end
end
assert(boardModel, "hub LeaderboardBoard missing")
local screens: { BasePart } = {}
for i, name in SCREENS do
	local p = (boardModel :: Instance):FindFirstChild(name)
	assert(p and p:IsA("BasePart"), "missing " .. name)
	screens[i] = p
end

local curS = screens[1].Size.X / 14
if math.abs(curS - S) < 0.01 then
	table.insert(report, "boards already on the arc")
else
	local k = S / curS
	local olds: { CFrame } = {}
	for i, p in screens do
		olds[i] = p.CFrame
	end
	local reach = 9 * curS + 2
	local decor: { { Instance } } = { {}, {}, {} }
	for _, d in island:GetDescendants() do
		local isPart = d:IsA("BasePart") and string.sub(d.Name, 1, 5) == "Board"
		local isPedestal = d:IsA("Model") and string.match(d.Name, "^BoardPedestal%d$") ~= nil
		if isPart or isPedestal then
			local inPedestal = false
			local a = d.Parent
			while a and a ~= island do
				if string.match(a.Name, "^BoardPedestal%d$") then
					inPedestal = true
				end
				a = a.Parent
			end
			local pos = posOf(d)
			if pos and not inPedestal then
				local best, bestDist = 0, reach
				for i, cf in olds do
					local dist = (pos - cf.Position).Magnitude
					if dist < bestDist then
						best, bestDist = i, dist
					end
				end
				if best > 0 then
					table.insert(decor[best], d)
				end
			end
		end
	end
	local toMid = ARC_MID - ARC_CENTER
	local arcR = Vector3.new(toMid.X, 0, toMid.Z).Magnitude
	local midAng = math.atan2(toMid.Z, toMid.X)
	local moved = 0
	for i, p in screens do
		local ang = midAng + math.rad((2 - i) * ARC_STEP)
		local pos = ARC_CENTER + Vector3.new(math.cos(ang) * arcR, 0, math.sin(ang) * arcR)
		local newCf = CFrame.lookAt(pos, Vector3.new(ARC_CENTER.X, pos.Y, ARC_CENTER.Z))
		local old = olds[i]
		local function place(cf: CFrame): CFrame
			local rel = old:ToObjectSpace(cf)
			local rp = rel.Position
			return newCf * CFrame.new(rp.X * k, rp.Y * k, rp.Z) * rel.Rotation
		end
		for _, d in decor[i] do
			if d:IsA("BasePart") and SCALED[d.Name] then
				d.Size = Vector3.new(d.Size.X * k, d.Size.Y * k, d.Size.Z)
			end
			moveBy(d, place)
			moved += 1
		end
		p.Size = Vector3.new(14 * S, 9 * S, p.Size.Z)
		p.CFrame = newCf
	end
	table.insert(report, "boards on arc, decor " .. moved)
end

-- 2. Plaza crystal fountain ---------------------------------------------------------------------
local fountain = 0
for _, d in island:GetDescendants() do
	if d.Parent and string.sub(d.Name, 1, 14) == "CentralCrystal" then
		d:Destroy()
		fountain += 1
	end
end
table.insert(report, "fountain pieces removed " .. fountain)

-- 3. Sanctuary portals and lanterns -------------------------------------------------------------
local sanctuary = island:FindFirstChild("TrainingSanctuary")
assert(sanctuary, "TrainingSanctuary missing")
local SC = Vector3.new(-74, 0, -34)
local function angleOf(p: Vector3): number
	return (math.deg(math.atan2(p.Z - SC.Z, p.X - SC.X)) + 360) % 360
end
local function rotator(deltaDeg: number): (CFrame) -> CFrame
	-- angle convention: pos = centre + (cos a, sin a) in X/Z; adding `delta` is a Y rotation of -delta
	local r = CFrame.new(SC) * CFrame.Angles(0, -math.rad(deltaDeg), 0) * CFrame.new(-SC)
	return function(cf: CFrame): CFrame
		return r * cf
	end
end

local PORTALS = {
	{ model = "TrainingPortal2", pid = "main_to_training_reef", to = 161 },
	{ model = "TrainingPortal3", pid = "main_to_training_abyss", to = 215 },
	{ model = "TrainingPortal4", pid = "main_to_training_celestial", to = 269 },
}
for _, def in PORTALS do
	local portal = (sanctuary :: Instance):FindFirstChild(def.model)
	if not portal then
		table.insert(report, def.model .. " missing")
		continue
	end
	local base = (portal :: Model):GetPivot().Position
	local from = angleOf(base)
	local delta = def.to - from
	if math.abs(delta) < 0.5 then
		table.insert(report, def.model .. " already at " .. def.to)
		continue
	end
	local xf = rotator(delta)
	local group: { Instance } = { portal }
	for _, t in CollectionService:GetTagged("ZonePortal") do
		if t:IsDescendantOf(island) and t:GetAttribute("PortalId") == def.pid then
			table.insert(group, t)
		end
	end
	for _, d in (sanctuary :: Instance):GetChildren() do
		if d:IsA("BasePart") then
			local flat = Vector3.new(d.Position.X - base.X, 0, d.Position.Z - base.Z).Magnitude
			if
				(string.sub(d.Name, 1, 12) == "TrainingSign" and flat < 5.6)
				or (d.Name == "ProgressStar" and flat < 5)
			then
				table.insert(group, d)
			end
		end
	end
	for _, d in group do
		moveBy(d, xf)
	end
	table.insert(report, string.format("%s %.0f->%d (%d pieces)", def.model, from, def.to, #group))
end

-- Lanterns: 118 -> 124, 173 -> 188, 215 -> removed (behind the middle portal), 257 -> 242, 306 stays.
local LANTERN_MAP = { [118] = 124, [173] = 188, [215] = -1, [257] = 242 }
for _, d in (sanctuary :: Instance):GetChildren() do
	if string.sub(d.Name, 1, 13) == "CircleLantern" then
		local p = posOf(d)
		if p then
			local a = angleOf(p)
			for from, to in LANTERN_MAP do
				if math.abs(a - from) < 2 then
					if to < 0 then
						d:Destroy()
					else
						moveBy(d, rotator(to - a))
					end
					table.insert(report, string.format("lantern %.0f->%d", a, to))
				end
			end
		end
	end
end

return table.concat(report, " | ")
