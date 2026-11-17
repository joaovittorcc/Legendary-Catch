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

local Players = game:GetService("Players")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))

type CatchInfo = { weight: number?, value: number?, isNew: boolean?, variant: string? }
local seen: { [string]: boolean } = {}
local CreatureMotion = require(script.Parent.Parent:WaitForChild("CreatureMotion"))
local stylesModule = script.Parent.Parent:WaitForChild("RevealStyles")
local RevealStyles = require(stylesModule)
local Legendary = require(stylesModule:WaitForChild("Legendary"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local PhotoMode = require(script.Parent:WaitForChild("PhotoMode"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local Art = require(script.Parent.Parent:WaitForChild("Hud"):WaitForChild("Art"))

local Reveal = {}

type Style = { size: number, apex: number, flight: number, hold: number }

local STYLES: { [string]: Style } = {
	Common = { size = 3.5, apex = 6, flight = 0.65, hold = 1 },
	Uncommon = { size = 4, apex = 7, flight = 0.9, hold = 2 },
	Rare = { size = 5, apex = 9, flight = 1, hold = 2.4 },
	Epic = { size = 6, apex = 11, flight = 1.1, hold = 2.8 },
	Legendary = { size = 8, apex = 14, flight = 1.4, hold = 3.6 },
}

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

local function sparkles(model: Model, color: Color3, shiny: boolean)
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
	e.Color = if shiny
		then ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.rose),
			ColorSequenceKeypoint.new(0.33, Theme.gold),
			ColorSequenceKeypoint.new(0.66, Theme.crystal),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 139, 255)),
		})
		else ColorSequence.new(color)
	e.LightEmission = 1
	e.Size =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Rate = 10
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = holder
end

local function nameCard(name: string, rarity: string, color: Color3, info: CatchInfo?): Frame
	local gui = Ui.screen()
	local card = Ui.frame(
		gui,
		"RevealCard",
		UDim2.fromScale(0.76, 0.24),
		UDim2.fromScale(0.5, 0.12),
		Theme.ink,
		0.08
	)
	Art.panel(card, if rarity == "Common" then Theme.crystal else color)
	card.AnchorPoint = Vector2.new(0.5, 1)
	local bounds = Instance.new("UISizeConstraint")
	bounds.MinSize = Vector2.new(0, 96)
	bounds.MaxSize = Vector2.new(560, 132)
	bounds.Parent = card
	local title = Ui.label(
		card,
		"Name",
		UDim2.fromScale(0.9, 0.25),
		UDim2.fromScale(0.05, 0.27),
		name,
		Color3.new(1, 1, 1)
	)
	title.TextStrokeTransparency = 0
	local badge, rarityLabel = Art.rarity(card)
	badge.AnchorPoint = Vector2.new(0.5, 0)
	badge.Position = UDim2.fromScale(0.5, 0.54)
	badge.Size = UDim2.fromScale(0.44, 0.19)
	Art.setRarity(badge, rarityLabel, rarity)
	if info and (info.isNew or info.variant == "Shiny") then
		Ui.label(
			card,
			"Discovery",
			UDim2.fromScale(0.88, 0.15),
			UDim2.fromScale(0.06, 0.1),
			if info.variant == "Shiny"
				then (if info.isNew then Text.shiny .. "  ·  " .. Text.discovery else Text.shiny)
				else Text.discovery,
			Theme.gold
		)
	end
	if info and info.weight and info.value then
		local reward = string.format(Text.captureReward, info.weight, info.value)
		-- Epic and Legendary also show how rare this exact creature is ("1 in 300").
		if Theme.rarityRank(rarity) >= 4 then
			local odds = FishingConfig.baseOdds(rarity, #Creatures.ofRarity(rarity))
			if odds > 0 then
				local digits = tostring(odds):reverse():gsub("(%d%d%d)", "%1."):reverse()
				reward ..= "   ·   " .. string.format(Strings.odds, (digits:gsub("^%.", "")))
			end
		end
		Ui.label(
			card,
			"Reward",
			UDim2.fromScale(0.88, 0.16),
			UDim2.fromScale(0.06, 0.755),
			reward,
			if Theme.rarityRank(rarity) >= 5 then Theme.gold else Theme.sand
		)
	end
	if Players.LocalPlayer:GetAttribute("ReduceEffects") == true then
		card.Position = UDim2.new(0.5, 0, 1, -16)
	else
		card.Position = UDim2.fromScale(0.5, 1.34)
		TweenService:Create(
			card,
			TweenInfo.new(0.45, Enum.EasingStyle.Back),
			{ Position = UDim2.new(0.5, 0, 1, -16) }
		):Play()
	end
	return card
end

local function tunnel(color: Color3)
	local gui = Ui.screen()
	for index = 1, 6 do
		local square = Ui.frame(
			gui,
			"AstralGate",
			UDim2.fromScale(0.04, 0.04),
			UDim2.fromScale(0.5, 0.48),
			color,
			1
		)
		square.AnchorPoint = Vector2.new(0.5, 0.5)
		square.SizeConstraint = Enum.SizeConstraint.RelativeYY
		square.Rotation = 28 + index * 7
		square.ZIndex = 12
		local border = Instance.new("UIStroke")
		border.Color = color
		border.Transparency = 0.32
		border.Thickness = 2
		border.Parent = square
		local tween = TweenInfo.new(
			0.55,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			0,
			false,
			index * 0.075
		)
		TweenService:Create(
			square,
			tween,
			{ Size = UDim2.fromScale(1.36, 1.36), Rotation = square.Rotation + 36 }
		):Play()
		TweenService:Create(border, tween, { Transparency = 1 }):Play()
		task.delay(0.56 + index * 0.075, function()
			square:Destroy()
		end)
	end
end

local function legendaryIntro(
	id: string,
	origin: Vector3,
	viewer: Vector3,
	color: Color3,
	cancelled: () -> boolean
): (() -> (), Folder?)
	local restore = Effects.darken(Color3.fromRGB(140, 120, 255), 0.4)
	task.wait(0.4)
	for pulse = 1, 3 do
		if cancelled() then
			return restore, nil
		end
		Effects.ripple(origin, color, 7 + pulse * 3, 0.68)
		Effects.shake(0.25, 1.2)
		task.wait(0.28)
	end
	Effects.pillar(origin, color, 60, 1.4)
	Effects.ripple(origin, color, 18, 1.2)
	task.wait(0.35)
	if not cancelled() then
		Effects.flash(Ui.screen(), Color3.new(1, 1, 1), 0.7)
		if id == "C10_Leviata_Astral" then
			tunnel(color)
		end
		return restore, Legendary.play(id, origin, viewer)
	end
	return restore, nil
end

-- Yields until the reveal is over.
function Reveal.play(
	creatureId: string,
	rarity: string,
	origin: Vector3,
	root: BasePart,
	info: CatchInfo?
)
	local color = FishingConfig.RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
	local style = STYLES[rarity] or STYLES.Common
	local level = math.max(1, Theme.rarityRank(rarity))

	local reduced = Players.LocalPlayer:GetAttribute("ReduceEffects") == true
	local shiny = info ~= nil and info.variant == "Shiny"
	local creature = Creatures.get(creatureId)
	local motif = if creature then creature.revealStyle else "splash"
	local accent = RevealStyles.tint(motif)
	local skipped = false
	local skipButton: TextButton? = nil
	if level == 5 and (seen[creatureId] or (info and info.isNew == false)) then
		local button = Instance.new("TextButton")
		button.Name = "SkipReveal"
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.fromScale(0.5, 0.72)
		button.Size = UDim2.fromOffset(116, 48)
		button.Text = Text.skip
		button.TextColor3 = Theme.sand
		button.Font = Theme.font
		button.TextSize = 19
		Theme.surface(button, color, 12)
		button.Activated:Connect(function()
			skipped = true
			button:Destroy()
		end)
		button.Parent = Ui.screen()
		skipButton = button
	end
	local function cancelled(): boolean
		return skipped or not root:IsDescendantOf(Workspace)
	end
	if level >= 5 then
		Audio.play("legendary", 0.24, 0.74)
	end
	local restore: (() -> ())? = nil
	local signature: Folder? = nil
	if level >= 5 and not reduced then
		restore, signature = legendaryIntro(creatureId, origin, root.Position, accent, cancelled)
	elseif level >= 4 and not reduced then
		Effects.pillar(origin, color, 35, 1)
		Effects.ripple(origin, color, 10, 0.9)
		task.wait(0.45)
	end

	if cancelled() then
		if signature then
			signature:Destroy()
		end
		if restore then
			restore()
		end
		if skipButton then
			skipButton:Destroy()
		end
		return
	end
	local model = cloneCreature(creatureId)
	local _, size = model:GetBoundingBox()
	local biggest = math.max(size.X, size.Y, size.Z, 0.1)
	model:ScaleTo(model:GetScale() * style.size / biggest)
	local motion = CreatureMotion.bind(model, motif)
	if (level >= 3 or shiny) and not reduced then
		sparkles(model, color, shiny)
	end
	if shiny then
		local gleam = Instance.new("Highlight")
		gleam.FillTransparency = 0.85
		gleam.OutlineTransparency = 0.28
		gleam.FillColor = Theme.rose
		gleam.OutlineColor = Theme.crystal
		gleam.DepthMode = Enum.HighlightDepthMode.Occluded
		gleam.Parent = model
		if not reduced then
			TweenService:Create(
				gleam,
				TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 4, true),
				{
					OutlineColor = Theme.gold,
					FillColor = Theme.crystal,
				}
			):Play()
			Effects.ripple(origin, Theme.rose, 9, 0.65)
			Effects.ripple(origin, Theme.gold, 12, 0.9)
		end
	end
	model.Parent = Workspace

	RevealStyles.play(motif, origin, level, reduced)
	Effects.splash(origin, accent, 10 + level * 6)
	Effects.ripple(origin, color, 4 + level * 2, 0.8)
	if level >= 5 and not reduced then
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
	while not cancelled() do
		local a = math.min((os.clock() - start) / style.flight, 1)
		local p = from:Lerp(apex, a):Lerp(apex:Lerp(display, a), a)
		local spin = CFrame.Angles(0, (1 - a) * math.pi * 4, (1 - a) * math.pi)
		model:PivotTo(CFrame.new(p) * facing.Rotation * spin)
		if a >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end

	if not cancelled() then
		Audio.capture(rarity, shiny)
	end
	if skipButton then
		skipButton:Destroy()
	end
	local name = Strings.creatureName[creatureId] or creatureId
	local card = if cancelled() then nil else nameCard(name, rarity, color, info)
	if card then
		Players.LocalPlayer:SetAttribute("CatchRevealActive", true)
	end

	local takePhoto = false
	local photoButton: TextButton? = nil
	if card and level >= 4 then
		local button = Instance.new("TextButton")
		button.Name = "TakePhoto"
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.new(0.5, 0, 0, -8)
		button.Size = UDim2.fromOffset(106, 44)
		button.Font = Theme.font
		button.TextSize = 19
		button.Text = Text.photo
		button.TextColor3 = Theme.sand
		Theme.surface(button, Theme.crystal, 20)
		button.TextStrokeTransparency = 0.15
		button.TextStrokeColor3 = Theme.ink
		button.Activated:Connect(function()
			takePhoto = true
		end)
		button.Parent = card
		photoButton = button
	end

	local holdStart = os.clock()
	local base = CFrame.new(display) * facing.Rotation
	while not cancelled() and not takePhoto and os.clock() - holdStart < style.hold do
		if not reduced then
			CreatureMotion.pose(motion, base, os.clock() - holdStart, true)
		end
		RunService.RenderStepped:Wait()
	end
	if photoButton then
		photoButton:Destroy()
	end
	if not takePhoto then
		CreatureMotion.reset(motion, base)
	end
	if signature then
		signature:Destroy()
	end

	if restore then
		restore()
	end
	if card and takePhoto then
		card:Destroy()
	elseif card then
		TweenService:Create(card, TweenInfo.new(0.3), { Position = UDim2.fromScale(0.5, -0.25) })
			:Play()
		task.delay(0.35, function()
			card:Destroy()
		end)
	end
	if not cancelled() then
		seen[creatureId] = true
	end

	if takePhoto and not cancelled() then
		PhotoMode.show(model, root, name, rarity, color)
		Players.LocalPlayer:SetAttribute("CatchRevealActive", false)
		model:Destroy()
		return
	end

	-- Shrink into the player.
	local outStart = os.clock()
	local baseScale = model:GetScale()
	while not cancelled() do
		local a = math.min((os.clock() - outStart) / 0.35, 1)
		model:ScaleTo(math.max(baseScale * (1 - a), 0.01))
		model:PivotTo(CFrame.new(display:Lerp(root.Position, a)) * facing.Rotation)
		if a >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
	model:Destroy()
	if card then
		Players.LocalPlayer:SetAttribute("CatchRevealActive", false)
	end
end

return Reveal
