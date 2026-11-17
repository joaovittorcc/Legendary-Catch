--!strict
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Fishing = script.Parent:WaitForChild("Fishing")
local Effects = require(Fishing:WaitForChild("Effects"))
local Audio = require(script.Parent:WaitForChild("Audio"))

type Style = {
	tint: Color3,
	glow: Color3,
	pieces: number,
	size: number,
	lift: number,
	spread: number,
	duration: number,
	cue: string,
	pitch: number,
	shape: Enum.PartType,
}
local rgb = Color3.fromRGB
local ball, block = Enum.PartType.Ball, Enum.PartType.Block
local styles: { [string]: Style } = {
	splash = {
		tint = rgb(63, 186, 248),
		glow = rgb(206, 247, 255),
		pieces = 5,
		size = 0.23,
		lift = 2.5,
		spread = 5,
		duration = 0.38,
		cue = "cast",
		pitch = 1.4,
		shape = ball,
	},
	bubbles = {
		tint = rgb(93, 238, 210),
		glow = rgb(196, 255, 246),
		pieces = 7,
		size = 0.42,
		lift = 7,
		spread = 2.5,
		duration = 0.96,
		cue = "hit",
		pitch = 1.65,
		shape = ball,
	},
	spark = {
		tint = rgb(255, 210, 84),
		glow = rgb(255, 247, 172),
		pieces = 8,
		size = 0.32,
		lift = 4,
		spread = 7,
		duration = 0.38,
		cue = "click",
		pitch = 1.35,
		shape = block,
	},
	prism = {
		tint = rgb(238, 127, 255),
		glow = rgb(93, 225, 255),
		pieces = 7,
		size = 0.62,
		lift = 5.5,
		spread = 6,
		duration = 0.84,
		cue = "panel",
		pitch = 1.45,
		shape = block,
	},
	storm = {
		tint = rgb(92, 122, 255),
		glow = rgb(235, 234, 255),
		pieces = 8,
		size = 0.42,
		lift = 8,
		spread = 4,
		duration = 0.47,
		cue = "bite",
		pitch = 0.76,
		shape = block,
	},
	crystal = {
		tint = rgb(33, 225, 224),
		glow = rgb(154, 255, 237),
		pieces = 6,
		size = 0.92,
		lift = 3.5,
		spread = 4,
		duration = 1.15,
		cue = "hit",
		pitch = 1.18,
		shape = block,
	},
	cosmic = {
		tint = rgb(171, 86, 255),
		glow = rgb(255, 176, 225),
		pieces = 10,
		size = 0.61,
		lift = 10,
		spread = 8,
		duration = 1,
		cue = "legendary",
		pitch = 0.87,
		shape = ball,
	},
	magma = {
		tint = rgb(255, 72, 21),
		glow = rgb(255, 185, 44),
		pieces = 12,
		size = 0.47,
		lift = 9,
		spread = 7,
		duration = 0.71,
		cue = "bite",
		pitch = 0.55,
		shape = ball,
	},
	cloud = {
		tint = rgb(196, 184, 255),
		glow = rgb(227, 245, 255),
		pieces = 6,
		size = 1.7,
		lift = 6,
		spread = 6,
		duration = 1.35,
		cue = "cast",
		pitch = 0.64,
		shape = ball,
	},
	frost = {
		tint = rgb(80, 213, 255),
		glow = rgb(224, 252, 255),
		pieces = 9,
		size = 0.75,
		lift = 5,
		spread = 6,
		duration = 0.92,
		cue = "hit",
		pitch = 1.92,
		shape = block,
	},
}

local Styles = {}

function Styles.tint(name: string): Color3
	return (styles[name] or styles.splash).tint
end

function Styles.play(name: string, origin: Vector3, rank: number, reduced: boolean)
	local style = styles[name] or styles.splash
	Audio.play(style.cue, math.min(0.25, 0.11 + rank * 0.022), style.pitch)
	Effects.ripple(origin, style.tint, 3 + rank, 0.65)
	if reduced then
		return
	end
	if name == "storm" then
		Effects.lightning(origin, style.glow)
	elseif name == "magma" or name == "frost" or name == "cosmic" then
		Effects.ripple(origin, style.glow, 7 + rank, style.duration)
	end

	local folder = Instance.new("Folder")
	folder.Name = "RevealStyle_" .. name
	local count = math.min(style.pieces, 4 + rank * 2)
	for index = 1, count do
		local angle = index / count * math.pi * 2
		local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local from = origin + radial * (if name == "cosmic" then 4 else 0.8)
		local lift = if name == "frost" then 0.85 else style.lift * (0.62 + (index % 4) * 0.13)
		local to = origin + radial * style.spread + Vector3.new(0, lift, 0)
		local part = Instance.new("Part")
		part.Name = "Motif"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Shape = style.shape
		part.Size = if name == "crystal" or name == "frost"
			then Vector3.new(style.size * 0.55, style.size * 2.3, style.size * 0.55)
			else Vector3.one * style.size
		part.Material = if name == "cloud" then Enum.Material.SmoothPlastic else Enum.Material.Neon
		part.Color = if index % 2 == 0 then style.tint else style.glow
		part.Transparency = if name == "cloud" then 0.58 elseif name == "bubbles" then 0.3 else 0.14
		part.CFrame = CFrame.new(from)
			* CFrame.Angles(0.25, angle, if style.shape == block then math.pi * 0.25 else 0)
		part.Parent = folder
		local targetSize = if name == "cloud" or name == "bubbles"
			then part.Size * 2.1
			else part.Size * 0.45
		local twist = if name == "prism" or name == "cosmic" then math.pi * 0.85 else 0
		TweenService:Create(
			part,
			TweenInfo.new(style.duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				CFrame = CFrame.new(to) * CFrame.Angles(twist, angle, angle * 0.25),
				Transparency = 1,
				Size = targetSize,
			}
		):Play()
	end
	folder.Parent = workspace
	Debris:AddItem(folder, style.duration + 0.15)
end

return Styles
