--!strict
-- One-shot live patch for the saved place (Edit mode, via execute_luau or the command bar).
-- Mirrors the HubBuilder_claude change of 2026-11-25 without rebuilding the whole hub:
--   1. the three scoreboards stand side by side in one row facing the plaza, 1.3x bigger;
--   2. the sanctuary "Ilha do Aprendiz" portal is removed (the lagoon gate stays).
-- Safe to run twice: it checks the current layout first. Returns a short report.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local island = Workspace:FindFirstChild("Island")
assert(island, "Workspace.Island missing")

local report = {}

-- 1. Scoreboards ---------------------------------------------------------------------------
local S = 1.3
local GAP = 22
local CENTER = Vector3.new(-78, 40, 31)
local FACE = Vector3.new(-10, 40, 36)
local SCREENS =
	{ "LeaderboardScreen_Catches", "LeaderboardScreen_Species", "LeaderboardScreen_Level" }
local SCALED = {
	BoardFrame = true,
	BoardGlowRim = true,
	BoardBack = true,
	BoardCrest = true,
	BoardGem = true,
}

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

if screens[1].Size.X > 14.5 then
	table.insert(report, "boards already patched")
else
	local rowCf = CFrame.lookAt(CENTER, Vector3.new(FACE.X, CENTER.Y, FACE.Z))
	local olds: { CFrame } = {}
	for i, p in screens do
		olds[i] = p.CFrame
	end
	-- Decor that belongs to each board: Board* parts and BoardPedestal<i> models near it.
	local decor: { { Instance } } = { {}, {}, {} }
	for _, d in island:GetDescendants() do
		local isPart = d:IsA("BasePart") and string.sub(d.Name, 1, 5) == "Board"
		local isPedestal = d:IsA("Model") and string.match(d.Name, "^BoardPedestal%d$") ~= nil
		if isPart or isPedestal then
			local pos = if d:IsA("Model") then d:GetPivot().Position else (d :: BasePart).Position
			local best, bestDist = 0, 13
			for i, cf in olds do
				local dist = (pos - cf.Position).Magnitude
				if dist < bestDist then
					best, bestDist = i, dist
				end
			end
			-- Pieces inside a pedestal model move with the model, never on their own.
			local inPedestal = false
			local a = d.Parent
			while a and a ~= island do
				if string.match(a.Name, "^BoardPedestal%d$") then
					inPedestal = true
				end
				a = a.Parent
			end
			if best > 0 and not inPedestal then
				table.insert(decor[best], d)
			end
		end
	end
	local moved = 0
	for i, p in screens do
		local newCf = rowCf * CFrame.new((i - 2) * GAP, 0, 0)
		local old = olds[i]
		local function place(cf: CFrame): CFrame
			local rel = old:ToObjectSpace(cf)
			local pos = rel.Position
			return newCf * CFrame.new(pos.X * S, pos.Y * S, pos.Z) * rel.Rotation
		end
		for _, d in decor[i] do
			if d:IsA("Model") then
				d:PivotTo(place(d:GetPivot()))
			elseif d:IsA("BasePart") then
				local cf = place(d.CFrame)
				if SCALED[d.Name] then
					d.Size = Vector3.new(d.Size.X * S, d.Size.Y * S, d.Size.Z)
				end
				d.CFrame = cf
			end
			moved += 1
		end
		p.Size = Vector3.new(14 * S, 9 * S, p.Size.Z)
		p.CFrame = newCf
	end
	table.insert(report, "boards moved, decor pieces " .. moved)
end

-- 2. Sanctuary Aprendiz portal --------------------------------------------------------------
local sanctuary = island:FindFirstChild("TrainingSanctuary")
local portal = sanctuary and sanctuary:FindFirstChild("TrainingPortal1")
if not portal then
	table.insert(report, "sanctuary Aprendiz portal already gone")
else
	local base = (portal :: Model):GetPivot()
	local removed = 0
	for _, t in CollectionService:GetTagged("ZonePortal") do
		if t:IsDescendantOf(island) and t:GetAttribute("PortalId") == "main_to_training_1" then
			t:Destroy()
			removed += 1
		end
	end
	-- Its sign (high above) and progress star (on the base front) were built next to it.
	for _, d in (sanctuary :: Instance):GetChildren() do
		if d:IsA("BasePart") or d:IsA("Model") then
			local pos = if d:IsA("Model") then d:GetPivot().Position else (d :: BasePart).Position
			local flat = Vector3.new(pos.X - base.Position.X, 0, pos.Z - base.Position.Z).Magnitude
			if (d.Name == "TrainingSign" or d.Name == "ProgressStar") and flat < 7 then
				d:Destroy()
				removed += 1
			end
		end
	end
	portal:Destroy()
	table.insert(report, "Aprendiz sanctuary portal removed (+" .. removed .. " trigger/sign/star)")
end

return table.concat(report, " | ")
