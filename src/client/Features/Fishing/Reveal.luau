--!strict
-- Catch reveal: the creature is only shown here, after the server confirms the catch.
-- Intensity scales with rarity:
--   Common/Uncommon  splash + jump + name card
--   Rare             + sparkles and a bigger jump
--   Epic             + light pillar from the bobber before the jump
--   Legendary        + world darkens, lightning strikes, white flash, slow spin, big banner

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Strings = require(Shared:WaitForChild("Strings"))

local Effects = require(script.Parent:WaitForChild("Effects"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local Reveal = {}

type Style = { size: number, apex: number, flight: number, hold: number }

local STYLES: { [string]: Style } = {
	Common = { size = 3.5, apex = 6, flight = 0.8, hold = 1.8 },
	Uncommon = { size = 4, apex = 7, flight = 0.9, hold = 2 },
	Rare = { size = 5, apex = 9, flight = 1, hold = 2.4 },
	Epic = { size = 6, apex = 11, flight = 1.1, hold = 2.8 },
	Legendary = { size = 8, apex = 14, flight = 1.4, hold = 3.6 },
}

local function rank(rarity: string): number
	for i, r in FishingConfig.RARITY_ORDER do
		if r == rarity then
			return i
		end
	end
	return 1
end

local function cloneCreature(id: string): Model
	local folder = ReplicatedStorage:FindFirstChild(Creatures.MODELS_FOLDER)
	local template = folder and folder:FindFirstChild(id)
	if template and template:IsA("Model") then
		local m = template:Clone()
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		return m
	end
	-- Missing model: show a placeholder instead of breaking the reveal.
	local m = Instance.new("Model")
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(2, 2, 2)
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.Parent = m
	m.PrimaryPart = p
	return m
end

local function sparkles(model: Model, color: Color3)
	local _, size = model:GetBoundingBox()
	local holder = Instance.new("Part")
	holder.Name = "SparkleHolder"
	holder.Size = size
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Parent = model
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Rate = 30
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = holder
end

local function nameCard(name: string, rarity: string, color: Color3, big: boolean): Frame
	local gui = Ui.screen()
	local card = Ui.frame(
		gui,
		"RevealCard",
		UDim2.fromScale(0.5, if big then 0.2 else 0.14),
		UDim2.fromScale(0.5, 0.12),
		Color3.new(0, 0, 0),
		1
	)
	card.AnchorPoint = Vector2.new(0.5, 0)
	local title = Ui.label(
		card,
		"Name",
		UDim2.fromScale(1, 0.6),
		UDim2.fromScale(0, 0),
		name,
		Color3.new(1, 1, 1)
	)
	title.TextStrokeTransparency = 0
	local rarityLabel = Ui.label(
		card,
		"Rarity",
		UDim2.fromScale(1, 0.38),
		UDim2.fromScale(0, 0.62),
		string.upper(Strings.rarity[rarity] or rarity),
		color
	)
	rarityLabel.TextStrokeTransparency = 0
	card.Position = UDim2.fromScale(0.5, -0.25)
	TweenService:Create(
		card,
		TweenInfo.new(0.45, Enum.EasingStyle.Back),
		{ Position = UDim2.fromScale(0.5, 0.1) }
	):Play()
	return card
end

local function legendaryIntro(origin: Vector3, color: Color3): () -> ()
	local restore = Effects.darken(Color3.fromRGB(140, 120, 255), 0.4)
	task.wait(0.4)
	for _ = 1, 3 do
		Effects.lightning(origin, Color3.fromRGB(200, 190, 255))
		Effects.shake(0.25, 1.2)
		task.wait(0.28)
	end
	Effects.pillar(origin, color, 60, 1.4)
	Effects.ripple(origin, color, 18, 1.2)
	task.wait(0.35)
	Effects.flash(Ui.screen(), Color3.new(1, 1, 1), 0.7)
	return restore
end

-- Yields until the reveal is over.
function Reveal.play(creatureId: string, rarity: string, origin: Vector3, root: BasePart)
	local color = FishingConfig.RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
	local style = STYLES[rarity] or STYLES.Common
	local level = rank(rarity)

	local restore: (() -> ())? = nil
	if level >= 5 then
		restore = legendaryIntro(origin, color)
	elseif level >= 4 then
		Effects.pillar(origin, color, 35, 1)
		Effects.ripple(origin, color, 10, 0.9)
		task.wait(0.45)
	end

	local model = cloneCreature(creatureId)
	local _, size = model:GetBoundingBox()
	local biggest = math.max(size.X, size.Y, size.Z, 0.1)
	model:ScaleTo(model:GetScale() * style.size / biggest)
	if level >= 3 then
		sparkles(model, color)
	end
	model.Parent = Workspace

	Effects.splash(origin, color, 10 + level * 6)
	Effects.ripple(origin, color, 4 + level * 2, 0.8)
	if level >= 5 then
		Effects.shake(0.5, 2)
	end

	-- Fly from the water to a spot in front of the player, spinning.
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local display = root.Position + look.Unit * 7 + Vector3.new(0, 3, 0)
	local from = origin - Vector3.new(0, 1, 0)
	local apex = (from + display) / 2 + Vector3.new(0, style.apex, 0)
	local facing =
		CFrame.lookAt(display, root.Position * Vector3.new(1, 0, 1) + Vector3.new(0, display.Y, 0))

	local start = os.clock()
	while true do
		local a = math.min((os.clock() - start) / style.flight, 1)
		local p = from:Lerp(apex, a):Lerp(apex:Lerp(display, a), a)
		local spin = CFrame.Angles(0, (1 - a) * math.pi * 4, (1 - a) * math.pi)
		model:PivotTo(CFrame.new(p) * facing.Rotation * spin)
		if a >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end

	local name = Strings.creatureName[creatureId] or creatureId
	local card = nameCard(name, rarity, color, level >= 5)

	-- Hover and turn slowly so the player can admire it.
	local holdStart = os.clock()
	while os.clock() - holdStart < style.hold do
		local t = os.clock() - holdStart
		model:PivotTo(
			CFrame.new(display + Vector3.new(0, math.sin(t * 2) * 0.4, 0))
				* facing.Rotation
				* CFrame.Angles(0, t * 0.9, 0)
		)
		RunService.RenderStepped:Wait()
	end

	if restore then
		restore()
	end
	TweenService:Create(card, TweenInfo.new(0.3), { Position = UDim2.fromScale(0.5, -0.25) }):Play()
	task.delay(0.35, function()
		card:Destroy()
	end)

	-- Shrink into the player.
	local outStart = os.clock()
	local baseScale = model:GetScale()
	while true do
		local a = math.min((os.clock() - outStart) / 0.35, 1)
		model:ScaleTo(math.max(baseScale * (1 - a), 0.01))
		model:PivotTo(CFrame.new(display:Lerp(root.Position, a)) * facing.Rotation)
		if a >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
	model:Destroy()
end

return Reveal
