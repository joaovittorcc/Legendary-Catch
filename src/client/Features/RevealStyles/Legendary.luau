--!strict
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Effects = require(script.Parent.Parent:WaitForChild("Fishing"):WaitForChild("Effects"))

local Legendary = {}
local blue = Color3.fromRGB(76, 178, 255)
local ice = Color3.fromRGB(188, 246, 255)
local violet = Color3.fromRGB(178, 117, 255)
local gold = Color3.fromRGB(255, 207, 123)
local shadow = Color3.fromRGB(24, 19, 52)

local function part(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	shape: Enum.PartType,
	neon: boolean
): Part
	local result = Instance.new("Part")
	result.Name = name
	result.CFrame = cf
	result.Size = size
	result.Color = color
	result.Shape = shape
	result.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	result.Anchored = true
	result.CanCollide = false
	result.CanQuery = false
	result.CanTouch = false
	result.CastShadow = false
	result.Parent = parent
	return result
end

local function beam(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	width: number,
	color: Color3,
	neon: boolean
): Part
	return part(
		parent,
		name,
		CFrame.lookAt((a + b) * 0.5, b),
		Vector3.new(width, width, (b - a).Magnitude),
		color,
		Enum.PartType.Block,
		neon
	)
end

local function fade(item: Part, delaySeconds: number, duration: number)
	TweenService:Create(
		item,
		TweenInfo.new(
			duration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			0,
			false,
			delaySeconds
		),
		{ Transparency = 1 }
	):Play()
end

function Legendary.play(id: string, origin: Vector3, viewer: Vector3): Folder?
	local root = Instance.new("Folder")
	local toward = (viewer - origin) * Vector3.new(1, 0, 1)
	local view = if toward.Magnitude > 0.5 then toward.Unit else Vector3.zAxis
	local right = Vector3.new(view.Z, 0, -view.X)

	if id == "C10_Leviata_Astral" then
		root.Name = "LeviathanConstellation"
		local stars =
			{ { -10, 7 }, { -6, 11 }, { -2, 10 }, { 2, 14 }, { 5, 12 }, { 8, 9 }, { 11, 11 }, {
				7,
				15,
			} }
		local last: Vector3? = nil
		for index, point in stars do
			local at = origin + right * point[1] + Vector3.yAxis * point[2] - view * 3
			if last then
				local link = beam(root, "StarLink", last, at, 0.13, violet, true)
				fade(link, 0.8, 0.8)
			end
			local star = part(
				root,
				"AstralStar",
				CFrame.new(at),
				Vector3.one * 0.55,
				if index % 3 == 0 then gold else ice,
				Enum.PartType.Ball,
				true
			)
			TweenService:Create(
				star,
				TweenInfo.new(
					0.36,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut,
					2,
					true,
					index * 0.055
				),
				{ Size = Vector3.one * 0.97 }
			):Play()
			fade(star, 1.04, 0.68)
			last = at
		end
	elseif id == "C23_Kraken_Trovejante" then
		root.Name = "KrakenSilhouette"
		for i = 1, 4 do
			local sign = if i % 2 == 0 then -1 else 1
			local start = origin + right * (i - 2.5) * 3 - view * 3
			local curve = {
				start,
				start + right * sign * 1.0 + Vector3.yAxis * 4.2,
				start + right * sign * 2.5 + Vector3.yAxis * (7.8 + i * 0.4),
				start - right * sign * 0.5 + Vector3.yAxis * (8.2 + i * 0.7),
				start - right * sign * 2 + Vector3.yAxis * (6.5 + i * 0.5),
			}
			for j = 2, #curve do
				local segment =
					beam(root, "Tentacle", curve[j - 1], curve[j], 1.35 - j * 0.19, shadow, false)
				local goal = segment.CFrame
				segment.CFrame = goal - Vector3.yAxis * 8
				TweenService:Create(
					segment,
					TweenInfo.new(
						0.38,
						Enum.EasingStyle.Back,
						Enum.EasingDirection.Out,
						0,
						false,
						i * 0.06
					),
					{ CFrame = goal }
				):Play()
				fade(segment, 0.75, 0.48)
			end
		end
		for strike = 1, 3 do
			task.delay(strike * 0.24, function()
				if root.Parent then
					Effects.lightning(
						origin + right * (strike - 2) * 8,
						if strike == 2 then ice else violet
					)
				end
			end)
		end
	elseif id == "C24_Fenix_das_Mares" then
		root.Name = "PhoenixBlueRebirth"
		for i = 1, 12 do
			local angle = i / 12 * 2 * math.pi
			local ray = right * math.cos(angle) + view * math.sin(angle)
			local height = 5 + 7 * math.abs(math.cos(angle))
			local from = origin + ray * 2
			local to = origin + ray * (4 + height * 0.35) + Vector3.yAxis * height
			local flame = part(
				root,
				"BlueFlame",
				CFrame.new(from),
				Vector3.new(0.9, 2.4, 0.9),
				if i % 3 == 0 then ice else blue,
				Enum.PartType.Ball,
				true
			)
			TweenService:Create(
				flame,
				TweenInfo.new(
					0.60,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out,
					0,
					false,
					(i % 4) * 0.09
				),
				{
					CFrame = CFrame.lookAt(to, to + ray)
						* CFrame.Angles(0, 0, math.cos(angle) * 0.5),
					Size = Vector3.new(0.24, 3.7, 0.24),
					Transparency = 1,
				}
			):Play()
		end
		task.delay(0.42, function()
			if root.Parent then
				Effects.pillar(origin, blue, 33, 1.05)
				Effects.ripple(origin, ice, 23, 1.06)
			end
		end)
	else
		root:Destroy()
		return nil
	end

	root.Parent = workspace
	Debris:AddItem(root, 1.9)
	return root
end

return Legendary
