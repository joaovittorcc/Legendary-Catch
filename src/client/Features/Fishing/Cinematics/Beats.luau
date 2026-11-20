--!strict
local Recipes = require(script.Parent.Recipes)
local Water = require(script.Parent.Water)
local Beats = {}
local TAU = 2 * math.pi

export type Beat = { draw: (number) -> (), close: () -> () }
export type CameraMotion = { push: number, roll: number, speed: number }

local function tile(parent: Instance, name: string, tint: Color3): Frame
	local part = Instance.new("Frame")
	part.Name = name
	part.AnchorPoint = Vector2.new(0.5, 0.5)
	part.Position = UDim2.fromScale(0.5, 0.5)
	part.BorderSizePixel = 0
	part.BackgroundColor3 = tint
	part.Parent = parent
	return part
end

local function round(part: Frame)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = part
end

local function rim(part: Frame, tint: Color3, width: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = tint
	stroke.Thickness = width
	stroke.Parent = part
	return stroke
end

local function gradient(part: Frame, dark: Color3, light: Color3)
	local fade = Instance.new("UIGradient")
	fade.Color = ColorSequence.new(dark, light)
	fade.Rotation = 62
	fade.Parent = part
end

function Beats.halo(parent: Frame, recipe: Recipes.Recipe): (number, number) -> ()
	local glow = Instance.new("ImageLabel")
	glow.Name = "Corona"
	glow.BackgroundTransparency = 1
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(1.65, 1.65)
	glow.Image = "rbxasset://textures/particles/smoke_main.dds"
	glow.ImageColor3 = recipe.accent
	glow.Parent = parent
	local stars = {}
	for i = 1, 18 do
		local angle = i * 2.39996
		local radius = 0.5 + (i % 7) * 0.072
		local star = tile(parent, "Satellite", if i % 2 == 0 then recipe.accent else recipe.light)
		star.Position =
			UDim2.fromScale(0.5 + math.cos(angle) * radius, 0.5 + math.sin(angle) * radius)
		local size = if i % 4 == 0 then 0.012 else 0.005
		star.Size = UDim2.fromScale(size, size)
		star.Rotation = 45
		stars[i] = star
	end
	local ring = tile(parent, "Astrolabe", recipe.accent)
	ring.BackgroundTransparency = 1
	ring.Size = UDim2.fromScale(0.86, 0.86)
	round(ring)
	local outline = rim(ring, recipe.light, 1.4)
	local ticks = {}
	for i = 1, 24 do
		local a = i * TAU / 24
		local tick = tile(ring, "Index", if i % 3 == 0 then recipe.light else recipe.accent)
		tick.Size = UDim2.fromScale(if i % 3 == 0 then 0.038 else 0.013, 0.005)
		tick.Position = UDim2.fromScale(0.5 + 0.48 * math.cos(a), 0.5 + 0.48 * math.sin(a))
		tick.Rotation = math.deg(a)
		ticks[i] = tick
	end
	return function(t, opacity)
		glow.Rotation = t * 2
		glow.ImageTransparency = 1 - opacity * 0.52
		for i, star in stars do
			star.BackgroundTransparency = 1 - opacity * (0.6 + 0.18 * math.sin(t + i))
		end
		ring.Rotation = t * 2
		outline.Transparency = 1 - opacity * 0.53
		for _, tick in ticks do
			tick.BackgroundTransparency = 1 - opacity * 0.72
		end
	end
end

function Beats.start(
	cue: Recipes.Cue,
	recipe: Recipes.Recipe,
	canvas: Frame,
	stage: Frame,
	folder: Folder,
	origin: Vector3,
	motion: CameraMotion
): Beat
	local kind, n = cue.kind, cue.count
	if kind == "zoom" or kind == "shake" or kind == "slowMotion" then
		local function draw(t: number)
			local wave = math.sin(t * math.pi) ^ 2
			if kind == "zoom" then
				motion.push = wave * cue.strength
			elseif kind == "shake" then
				motion.roll = math.sin(t * TAU * 2) * wave * math.rad(cue.strength)
				stage.Rotation = math.deg(motion.roll)
			else
				motion.speed = 1 - wave * cue.strength
			end
		end
		return {
			draw = draw,
			close = function()
				draw(0)
			end,
		}
	end
	local group = Instance.new("Folder")
	group.Name = cue.kind
	group.Parent = folder
	local water = Water.create(group, origin, cue, recipe)
	if water then
		return {
			draw = water,
			close = function()
				group:Destroy()
			end,
		}
	end
	group:Destroy()
	local layer = tile(if kind == "flash" then canvas else stage, kind, recipe.light)
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	local function result(draw: (number) -> ()): Beat
		return {
			draw = draw,
			close = function()
				layer:Destroy()
			end,
		}
	end
	if kind == "flash" then
		return result(function(t)
			layer.BackgroundTransparency = 1 - math.sin(math.pi * t) ^ 2 * cue.strength
		end)
	elseif kind == "mist" then
		local wisps = {}
		for i = 1, n do
			local wisp = Instance.new("ImageLabel")
			wisp.Name = "SeaMist"
			wisp.BackgroundTransparency = 1
			wisp.AnchorPoint = Vector2.new(0.5, 0.5)
			wisp.Size = UDim2.fromScale(0.85, 0.4)
			wisp.Image = "rbxasset://textures/particles/smoke_main.dds"
			wisp.ImageColor3 = if i % 2 == 0 then recipe.accent else recipe.light
			wisp.Parent = layer
			wisps[i] = wisp
		end
		return result(function(t)
			for i, wisp in wisps do
				wisp.Position = UDim2.fromScale(
					(i - 0.5) / n + 0.07 * math.sin(i + t * 3),
					0.96 - t * 0.42 + 0.08 * math.cos(i)
				)
				wisp.ImageTransparency = 1 - math.sin(t * math.pi) * 0.55
			end
		end)
	elseif kind == "portal" then
		local disk = tile(layer, "EventHorizon", Color3.new(1, 1, 1))
		round(disk)
		gradient(disk, Color3.fromRGB(10, 12, 36), recipe.accent)
		local edge = rim(disk, recipe.light, 3)
		local orbits = {}
		for i = 1, 3 do
			local arc = tile(disk, "Orbit", recipe.light)
			round(arc)
			arc.BackgroundTransparency = 1
			arc.Size = UDim2.fromScale(1 - i * 0.095, 0.98 - i * 0.065)
			local line = rim(arc, if i % 2 == 0 then recipe.light else recipe.accent, 1.5)
			orbits[i] = { arc = arc, line = line }
		end
		return result(function(t)
			local open = 1 - (1 - math.min(1, t * 3)) ^ 3
			local opacity = open * math.min(1, (1 - t) * 4)
			disk.Size = UDim2.fromScale(0.03 + open * 0.81, 0.02 + open * 0.81)
			disk.BackgroundTransparency = 1 - 0.92 * opacity
			edge.Transparency = 1 - opacity
			for i, pair in orbits do
				pair.arc.Rotation = t * 95 + i * 64
				pair.line.Transparency = 1 - opacity * 0.8
			end
		end)
	elseif kind == "tear" then
		local edges = {}
		for side = -1, 1, 2 do
			for i = 1, n do
				local y = (i - 1) / n
				local a = Vector2.new(math.sin(i * 7.9) * 0.058, y * 0.88)
				local b = Vector2.new(math.sin((i + 1) * 7.9) * 0.058, (y + 1 / n) * 0.88)
				local delta = b - a
				local part =
					tile(layer, "Fracture", if side < 0 then recipe.light else recipe.accent)
				part.Rotation = math.deg(math.atan2(delta.Y, delta.X))
				part.Size = UDim2.fromScale(delta.Magnitude + 0.006, 0.012)
				table.insert(edges, { part = part, side = side, mid = (a + b) / 2 })
			end
		end
		return result(function(t)
			for _, edge in edges do
				local p = math.clamp(t * 3 - edge.mid.Y, 0, 1)
				edge.part.Position = UDim2.fromScale(
					0.5 + edge.mid.X + edge.side * math.sin(edge.mid.Y / 0.88 * math.pi) * 0.25 * t,
					0.06 + edge.mid.Y
				)
				edge.part.BackgroundTransparency = 1 - p * math.min(1, (1 - t) * 3)
			end
		end)
	end

	local parts, strokes = {}, {}
	for i = 1, n do
		local part = tile(layer, kind, if i % 3 == 0 then recipe.light else recipe.accent)
		if kind == "bubbles" or kind == "tunnel" then
			if kind == "bubbles" then
				round(part)
			end
			part.BackgroundTransparency = 1
			strokes[i] = rim(part, part.BackgroundColor3, 1.8)
		elseif kind == "aurora" or kind == "wings" then
			round(part)
			gradient(part, recipe.accent, recipe.light)
			local band = part:FindFirstChildOfClass("UIGradient")
			if band then
				band.Rotation = if kind == "wings" then 90 else 0
				band.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.44, 0.02),
					NumberSequenceKeypoint.new(1, 0.95),
				})
			end
		end
		parts[i] = part
	end
	return result(function(t)
		local fade = math.min(1, t * 6, (1 - t) * 4)
		for i, part in parts do
			local f = i / n
			local phase = (t + f) % 1
			local x, y, w, h, angle = 0.5, 0.5, 0.01, 0.01, 0
			local alpha = fade
			if kind == "wings" then
				local side = if i % 2 == 0 then -1 else 1
				local fan = math.ceil(i / 2) / math.ceil(n / 2)
				x += side * (0.08 + fan * 0.39) * math.min(1, t * 3)
				y += 0.15 - 0.34 * fan - 0.18 * t
				w, h, angle = 0.071, 0.23 + 0.14 * fan, -side * (16 + fan * 33)
			elseif kind == "meteors" then
				x, y = (i * 0.618) % 1 - 0.35 + t * 0.85, (i * 0.38) % 0.65 - 0.55 + t * 0.82
				w, h, angle = 0.14, 0.008, 43
			elseif kind == "orbit" then
				local a = f * TAU + t * 2.4
				x, y = 0.5 + math.cos(a) * 0.49, 0.5 + math.sin(a) * 0.32 + math.cos(a) * 0.12
				w, h, angle = 0.016 + f * 0.014, 0.016 + f * 0.014, 45
			elseif kind == "bubbles" then
				x, y = 0.07 + ((i * 0.618) % 0.86) + 0.04 * math.sin(t * 5 + i), 1.2 - phase * 1.35
				w, h = 0.025 + f * 0.06, 0.025 + f * 0.06
				alpha *= math.sin(phase * math.pi)
			elseif kind == "tunnel" then
				w, h, angle = 0.06 + phase ^ 2 * 1.45, 0.06 + phase ^ 2 * 1.45, 32 + i * 5 + t * 18
				alpha *= math.sin(phase * math.pi)
			elseif kind == "aurora" then
				x, y = 0.3 + f * 0.38, 0.31 + 0.065 * math.sin(t * 4 + i)
				w, h, angle = 1.4, 0.018 + f * 0.028, -33 + f * 17
				alpha *= 0.4
			end
			part.Position = UDim2.fromScale(x, y)
			part.Size = UDim2.fromScale(w, h)
			part.Rotation = angle
			if strokes[i] then
				strokes[i].Transparency = 1 - alpha
			else
				part.BackgroundTransparency = 1 - alpha
			end
		end
	end)
end
return Beats
