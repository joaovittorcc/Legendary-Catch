--!strict
local Recipes = require(script.Parent.Recipes)
type Draw = (number) -> ()
local TAU = 2 * math.pi
local Water = {}

local function segment(parent: Folder, tint: Color3): Part
	local part = Instance.new("Part")
	part.Name = "Light"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = tint
	part.Transparency = 1
	part.Parent = parent
	return part
end

local function beam(part: Part, a: Vector3, b: Vector3, width: number)
	part.Size = Vector3.new(width, width, (b - a).Magnitude)
	part.CFrame = CFrame.lookAt((a + b) / 2, b)
end

local function offset(angle: number, radius: number, height: number): Vector3
	return Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
end

function Water.create(
	group: Folder,
	origin: Vector3,
	cue: Recipes.Cue,
	recipe: Recipes.Recipe
): Draw?
	local kind, n = cue.kind, cue.count
	if kind == "waves" or kind == "shockwave" then
		-- A real annulus stays open in the middle and follows the plane of the sea.
		local bands = {}
		for i = 1, n do
			local pieces = {}
			for j = 1, 16 do
				pieces[j] = segment(group, if i % 2 == 0 then recipe.light else recipe.accent)
			end
			bands[i] = pieces
		end
		return function(t)
			for i, pieces in bands do
				local p = math.clamp(t * 1.6 - (i - 1) / n * 0.6, 0, 1)
				local r = 1 + p * (if kind == "shockwave" then 22 else 12)
				for j, part in pieces do
					beam(
						part,
						origin + offset(j * TAU / 16, r, 0.2),
						origin + offset((j + 1) * TAU / 16, r, 0.2),
						0.09 + 0.16 * (1 - p)
					)
					part.Transparency = 1 - 0.8 * math.sin(p * math.pi)
				end
			end
		end
	elseif kind == "freeze" then
		local branches = {}
		for i = 1, n do
			local angle = i * TAU / n
			local fork = origin + offset(angle, 3.8, 0.22)
			for j = -1, 1 do
				local part = segment(group, if j == 0 then recipe.light else recipe.accent)
				local main = j == 0
				local tip = fork + offset(angle + j * 0.70, if main then 5.2 else 2.8, 0)
				beam(part, if main then origin else fork, tip, if main then 0.18 else 0.11)
				table.insert(branches, { part = part, delay = if main then 0 else 0.18 })
			end
		end
		return function(t)
			for _, branch in branches do
				local growth = math.clamp((t - branch.delay) * 4, 0, 1)
				branch.part.Transparency = 1 - growth * math.min(1, (1 - t) * 3) * 0.9
			end
		end
	elseif kind == "lightning" then
		local bolts = {}
		for i = 1, n do
			local foot = origin + offset(i * 2.4, 2 + i, 0.15)
			local previous = foot
			local pieces = {}
			for j = 1, 7 do
				local tip = foot
					+ Vector3.new(
						math.sin(i + j * 4) * 2 + j * 0.45,
						j * 3.4,
						math.cos(i * j) * 1.2
					)
				local part = segment(group, if j % 2 == 1 then recipe.light else recipe.accent)
				beam(part, previous, tip, 0.23)
				previous = tip
				pieces[j] = part
			end
			bolts[i] = pieces
		end
		return function(t)
			for i, pieces in bolts do
				local p = math.clamp((t - (i - 1) * 0.65 / n) / 0.45, 0, 1)
				for _, part in pieces do
					part.Transparency = 1 - math.sin(math.pi * p) ^ 0.7
				end
			end
		end
	elseif kind == "vortex" or kind == "eruption" or kind == "pillar" then
		local pieces = {}
		for i = 1, n do
			pieces[i] = segment(group, if i % 3 == 0 then recipe.light else recipe.accent)
		end
		return function(t)
			local envelope = math.sin(t * math.pi)
			for i, part in pieces do
				local a = i * TAU / n
				if kind == "vortex" then
					a += t * 4
					local r = 2 + (1 - t) * 11 + 2 * math.sin(a * 2)
					beam(
						part,
						origin + offset(a, r, 0.3),
						origin + offset(a + 0.34, r * 0.84, 0.6 + 2 * t),
						0.42
					)
				elseif kind == "eruption" then
					local p = math.clamp(t * 1.45 - (i % 4) * 0.13, 0, 1)
					local b = origin + offset(a, 1 + 9 * p, 0.4 + 17 * math.sin(p * math.pi))
					beam(part, b, b + offset(a, 0.45, 1.6), 0.37)
				else
					beam(
						part,
						origin,
						origin + Vector3.yAxis * (0.4 + 26 * envelope),
						1.75 * envelope + 0.1
					)
				end
				part.Transparency = 1 - envelope * (if kind == "pillar" then 0.48 else 0.9)
			end
		end
	end
	return nil
end
return Water
