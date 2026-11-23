--!strict
-- Z-fighting finder/fixer for Studio (Edit mode, run via execute_luau or the command bar).
-- Two box parts z-fight (flicker) when they have coplanar, same-facing, overlapping faces. This
-- finds those pairs and pushes the smaller part out along that face normal, with a growing push
-- per pass so rows of equal parts (steps, planks) separate instead of trading places.
-- Rule from the fwjelaa vault ("Level of Detail and Model Streaming"): separate coplanar faces.
-- Used on 2026-11-22: 121 overlaps in the west hub, 77+ inside the aquarium kit -> 0.

local Z = {}

type Face = { n: Vector3, c: Vector3, u: Vector3, v: Vector3, hu: number, hv: number }

local function faces(p: BasePart): { Face }
	local list: { Face } = {}
	if not p:IsA("Part") or (p :: Part).Shape ~= Enum.PartType.Block then
		return list
	end
	local cf, s = p.CFrame, p.Size
	local axes = {
		{ cf.RightVector, cf.UpVector, cf.LookVector, s.X, s.Y, s.Z },
		{ cf.UpVector, cf.RightVector, cf.LookVector, s.Y, s.X, s.Z },
		{ cf.LookVector, cf.RightVector, cf.UpVector, s.Z, s.X, s.Y },
	}
	for _, a in axes do
		for _, sign in { 1, -1 } do
			local n = (a[1] :: Vector3) * sign
			table.insert(list, {
				n = n,
				c = cf.Position + n * (a[4] :: number) / 2,
				u = a[2] :: Vector3,
				v = a[3] :: Vector3,
				hu = (a[5] :: number) / 2,
				hv = (a[6] :: number) / 2,
			})
		end
	end
	return list
end

local function overlap(f1: Face, f2: Face): boolean
	local minU, maxU, minV, maxV = math.huge, -math.huge, math.huge, -math.huge
	for _, su in { -1, 1 } do
		for _, sv in { -1, 1 } do
			local d = f2.c + f2.u * f2.hu * su + f2.v * f2.hv * sv - f1.c
			local u, v = d:Dot(f1.u), d:Dot(f1.v)
			minU, maxU = math.min(minU, u), math.max(maxU, u)
			minV, maxV = math.min(minV, v), math.max(maxV, v)
		end
	end
	local ou = math.min(maxU, f1.hu) - math.max(minU, -f1.hu)
	local ov = math.min(maxV, f1.hv) - math.max(minV, -f1.hv)
	return ou > 0.05 and ov > 0.05
end

-- Returns { {partA, partB, normal} } for every z-fighting pair in `parts`.
function Z.scan(parts: { BasePart }): { { any } }
	local F, grid, cell = {}, {}, 16
	for i, p in parts do
		F[i] = faces(p)
		local k = math.floor(p.Position.X / cell) .. "," .. math.floor(p.Position.Z / cell)
		grid[k] = grid[k] or {}
		table.insert(grid[k], i)
	end
	local found = {}
	for i, p in parts do
		if #F[i] > 0 then
			local cx, cz = math.floor(p.Position.X / cell), math.floor(p.Position.Z / cell)
			local reach = math.ceil(math.max(p.Size.X, p.Size.Y, p.Size.Z) / cell) + 1
			for gx = cx - reach, cx + reach do
				for gz = cz - reach, cz + reach do
					for _, j in grid[gx .. "," .. gz] or {} do
						if j > i and #F[j] > 0 then
							local normal: Vector3? = nil
							for _, f1 in F[i] do
								for _, f2 in F[j] do
									if
										f1.n:Dot(f2.n) > 0.9995
										and math.abs((f2.c - f1.c):Dot(f1.n)) < 0.015
										and overlap(f1, f2)
									then
										normal = f1.n
										break
									end
								end
								if normal then
									break
								end
							end
							if normal then
								table.insert(found, { parts[i], parts[j], normal })
							end
						end
					end
				end
			end
		end
	end
	return found
end

-- Fixes in place; returns how many pairs are left (0 = clean).
function Z.fix(parts: { BasePart }, maxPasses: number?): number
	local count: { [BasePart]: number } = {}
	for _ = 1, maxPasses or 8 do
		local found = Z.scan(parts)
		if #found == 0 then
			return 0
		end
		for _, pr in found do
			local a, b, n = pr[1] :: BasePart, pr[2] :: BasePart, pr[3] :: Vector3
			local small = if a.Size.X * a.Size.Y * a.Size.Z
					<= b.Size.X * b.Size.Y * b.Size.Z
				then a
				else b
			count[small] = (count[small] or 0) + 1
			small.CFrame = small.CFrame + n * (0.02 + 0.017 * count[small])
		end
	end
	return #Z.scan(parts)
end

-- Visible parts under `root`, optionally limited to a world box.
function Z.collect(root: Instance, bmin: Vector3?, bmax: Vector3?): { BasePart }
	local list = {}
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.95 then
			local q = p.Position
			if
				not bmin
				or not bmax
				or (
					q.X > bmin.X
					and q.X < bmax.X
					and q.Y > bmin.Y
					and q.Y < bmax.Y
					and q.Z > bmin.Z
					and q.Z < bmax.Z
				)
			then
				table.insert(list, p)
			end
		end
	end
	return list
end

return Z
