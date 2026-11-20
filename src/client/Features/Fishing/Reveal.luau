--!strict
-- Catch reveal: the creature is only shown here, after the server confirms the catch.
-- Intensity scales with rarity:
--   Common/Uncommon  splash + jump + name card
--   Rare             + sparkles and a bigger jump
--   Epic             + light pillar from the bobber before the jump
--   Legendary        + world darkens, lightning strikes, white flash, slow spin, big banner

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Strings = require(Shared:WaitForChild("Strings"))

local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local seen: { [string]: boolean } = {}
local CreatureMotion = require(script.Parent.Parent:WaitForChild("CreatureMotion"))
local stylesModule = script.Parent.Parent:WaitForChild("RevealStyles")
local RevealStyles = require(stylesModule)
local Legendary = require(stylesModule:WaitForChild("Legendary"))
local Audio = require(script.Parent.Parent:WaitForChild("Audio"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local PhotoMode = require(script.Parent:WaitForChild("PhotoMode"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local Framing = require(script.Parent:WaitForChild("RevealFraming"))
local RevealCard = require(script.Parent:WaitForChild("RevealCard"))
local Cinematics = require(script.Parent:WaitForChild("Cinematics"))

type CatchInfo = RevealCard.CatchInfo

local Reveal = {}

type Style = { size: number, apex: number, flight: number, hold: number }

local STYLES: { [string]: Style } = {
	Common = { size = 3.5, apex = 6, flight = 0.65, hold = 2.2 },
	Uncommon = { size = 4, apex = 7, flight = 0.9, hold = 3.2 },
	Rare = { size = 5, apex = 9, flight = 1, hold = 3.8 },
	Epic = { size = 6, apex = 11, flight = 1.1, hold = 4.5 },
	Legendary = { size = 8, apex = 14, flight = 1.4, hold = 5.5 },
	Mystic = { size = 9, apex = 16, flight = 1.7, hold = 6.6 },
}

local SHOT_FOV = 42
local SHOT_BLEND = 0.22
local EXIT_SECONDS = 0.30
local REDUCED_FLIGHT_MAX = 0.85
local REDUCED_MYSTIC_HOLD = 4.4
local SHOT_BINDING = "CatchRevealCamera"

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
	local box, size = model:GetBoundingBox()
	local holder = Instance.new("Part")
	holder.Name = "SparkleHolder"
	holder.Size = size
	holder.CFrame = box
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

local function clearForeground(root: BasePart): () -> ()
	local character = root.Parent
	local hidden: { [BasePart]: number } = {}
	if character then
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				hidden[part] = part.LocalTransparencyModifier
				part.LocalTransparencyModifier = 1
			end
		end
	end
	return function()
		for part, transparency in hidden do
			part.LocalTransparencyModifier = transparency
		end
	end
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

local function mysticIntro(origin: Vector3, color: Color3, cancelled: () -> boolean): () -> ()
	local restore = Effects.darken(Color3.fromRGB(113, 108, 221), 0.55)
	local palette = { Theme.crystal, Color3.fromRGB(167, 125, 255), Theme.rose, color }
	for index, tint in palette do
		if cancelled() then
			break
		end
		Effects.ripple(origin, tint, 6 + index * 3, 1.12)
		if index == 2 then
			tunnel(Theme.crystal)
		elseif index == 4 then
			Effects.pillar(origin, color, 55, 1.6)
			tunnel(Theme.rose)
		end
		task.wait(0.5)
	end
	return restore
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
	local recipe = Cinematics.recipes[creatureId]
	if recipe then
		local repeatView = seen[creatureId] == true or (info ~= nil and info.isNew == false)
		if
			Cinematics.play(
				recipe,
				creatureId,
				Strings.creatureName[creatureId] or creatureId,
				rarity,
				color,
				motif,
				origin,
				root,
				info,
				repeatView,
				cloneCreature
			)
		then
			seen[creatureId] = true
		end
		return
	end
	local accent = if level == 6 then Theme.crystal else RevealStyles.tint(motif)
	local skipped = false
	local skipButton: TextButton? = nil
	if level >= 5 and (seen[creatureId] or (info and info.isNew == false)) then
		local button = RevealCard.action(Ui.screen(), "SkipReveal", Text.skip, color)
		button.Activated:Connect(function()
			skipped = true
			button:Destroy()
		end)
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
	if level == 6 and not reduced then
		restore = mysticIntro(origin, color, cancelled)
	elseif level == 5 and not reduced then
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
	local bounds = Framing.measure(model)
	local motion = CreatureMotion.bind(model, motif)
	local preview = cloneCreature(creatureId)
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
	Effects.splash(origin, accent, if reduced then 8 else 10 + level * 6)
	Effects.ripple(origin, color, 4 + level * 2, 0.8)
	if level >= 5 and not reduced then
		Effects.shake(0.27, if level == 6 then 1.55 else 1.15)
	end

	-- The flight can turn. The final pose stays within a small sway of the viewer.
	local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local forward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local display = root.Position + forward * 10 + Vector3.new(0, 3.2, 0)
	local from = origin - Vector3.new(0, 1, 0)
	local apex = (from + display) / 2 + Vector3.new(0, style.apex, 0)
	local viewer = -forward + forward:Cross(Vector3.yAxis) * 0.32 + Vector3.new(0, 0.08, 0)
	local start = os.clock()
	local flight = if reduced then math.min(REDUCED_FLIGHT_MAX, style.flight) else style.flight
	while not cancelled() do
		local a = math.min((os.clock() - start) / flight, 1)
		if level >= 5 and not reduced then
			a = TweenService:GetValue(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		end
		local p = from:Lerp(apex, a):Lerp(apex:Lerp(display, a), a)
		local turn = if reduced then 0 else (1 - a) ^ 2 * math.pi * 2
		model:PivotTo(Framing.pose(bounds, p, viewer, turn))
		if a >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end

	local name = Strings.creatureName[creatureId] or creatureId
	local card: RevealCard.Card? = nil
	local takePhoto = false
	local photoButton: TextButton? = nil
	local holdStart = os.clock()
	local base = Framing.pose(bounds, display, viewer)
	local camera = Workspace.CurrentCamera
	local restoreCamera: (() -> ())? = nil
	local restoreForeground: (() -> ())? = nil
	local touchControls = GuiService.TouchControlsEnabled

	if not cancelled() then
		if restore then
			restore()
			restore = nil
		end
		Audio.capture(rarity, shiny)
		if info and (info.isRecord or info.isGiant) then
			Audio.play("level", 0.23, if info.isGiant then 0.9 else 1.12)
		end
		local activeCard =
			RevealCard.open(Ui.screen(), preview, creatureId, name, rarity, color, info, reduced)
		card = activeCard
		restoreForeground = clearForeground(root)
		GuiService.TouchControlsEnabled = false
		Players.LocalPlayer:SetAttribute("CatchRevealActive", true)
		if level >= 4 then
			local button = RevealCard.action(Ui.screen(), "TakePhoto", Text.photo, Theme.crystal)
			photoButton = button
			button.Activated:Connect(function()
				takePhoto = true
			end)
		end
		if camera then
			local oldType, oldCFrame, oldFocus, oldFov =
				camera.CameraType, camera.CFrame, camera.Focus, camera.FieldOfView
			local axes = CFrame.lookAt(Vector3.zero, -viewer)
			camera.CameraType = Enum.CameraType.Scriptable
			local lastViewport = Vector2.zero
			local shot = oldCFrame
			RunService:BindToRenderStep(SHOT_BINDING, Enum.RenderPriority.Last.Value, function()
				local viewport = camera.ViewportSize
				if viewport ~= lastViewport and viewport.X > 0 and viewport.Y > 0 then
					lastViewport = viewport
					local region = RevealCard.subjectRegion(viewport)
					shot = Framing.camera(
						bounds,
						base,
						axes,
						display,
						viewport,
						SHOT_FOV,
						region,
						1.25
					)
					base = Framing.pose(bounds, display, shot.Position - display)
					shot = Framing.camera(
						bounds,
						base,
						axes,
						display,
						viewport,
						SHOT_FOV,
						region,
						1.25
					)
				end
				local elapsed = os.clock() - holdStart
				local blend = if reduced then 1 else math.min(elapsed / SHOT_BLEND, 1)
				local eased =
					TweenService:GetValue(blend, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				camera.CFrame = oldCFrame:Lerp(shot, eased)
				camera.FieldOfView = oldFov + (SHOT_FOV - oldFov) * eased
				camera.Focus = CFrame.new(display)
				if not reduced then
					CreatureMotion.pose(motion, base, elapsed, false)
					activeCard.preview(elapsed)
				else
					model:PivotTo(base)
				end
			end)
			restoreCamera = function()
				RunService:UnbindFromRenderStep(SHOT_BINDING)
				camera.FieldOfView = oldFov
				camera.CFrame = oldCFrame
				camera.Focus = oldFocus
				camera.CameraType = oldType
			end
		end
	else
		preview:Destroy()
	end

	local hold = if reduced and level == 6 then REDUCED_MYSTIC_HOLD else style.hold
	while card and not cancelled() and not takePhoto and os.clock() - holdStart < hold do
		RunService.RenderStepped:Wait()
	end
	if restoreCamera then
		restoreCamera()
	end
	if skipButton then
		skipButton:Destroy()
	end
	if photoButton then
		photoButton:Destroy()
	end
	CreatureMotion.reset(motion, base)
	if signature then
		signature:Destroy()
	end
	if restore then
		restore()
	end
	if card then
		card.close(takePhoto or cancelled())
	end
	if not cancelled() then
		seen[creatureId] = true
	end
	if takePhoto and not cancelled() then
		PhotoMode.show(model, root, name, rarity, color, base:VectorToWorldSpace(bounds.forward))
	elseif not reduced and not cancelled() then
		local outStart = os.clock()
		local baseScale = model:GetScale()
		while not cancelled() do
			local a = math.min((os.clock() - outStart) / EXIT_SECONDS, 1)
			model:ScaleTo(math.max(baseScale * (1 - a), 0.01))
			model:PivotTo(CFrame.new((root.Position - display) * a) * base)
			if a >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
	end
	model:Destroy()
	if restoreForeground then
		restoreForeground()
	end
	if card then
		GuiService.TouchControlsEnabled = touchControls
		Players.LocalPlayer:SetAttribute("CatchRevealActive", false)
	end
end

return Reveal
