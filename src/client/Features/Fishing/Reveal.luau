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
local FishingCamera = require(script.Parent:WaitForChild("Camera"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local PhotoMode = require(script.Parent:WaitForChild("PhotoMode"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local Framing = require(script.Parent:WaitForChild("RevealFraming"))
local Mutation = require(script.Parent.RevealMutation)
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

local function safeRevealCamera(
	camCf: CFrame,
	target: Vector3,
	character: Instance?,
	creatureModel: Model
): CFrame
	local wanted = camCf.Position
	local clamped = if wanted.Y < 1.2 then Vector3.new(wanted.X, 1.2, wanted.Z) else wanted
	local baseFilter: { Instance } = { creatureModel }
	if character then
		table.insert(baseFilter, character)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = baseFilter
	params.IgnoreWater = true
	params.RespectCanCollide = true

	local origin = target
	local safePos = clamped
	local skipped: { Instance }? = nil
	for _ = 1, 6 do
		local delta = clamped - origin
		if delta.Magnitude < 0.05 then
			break
		end
		local hit = Workspace:Raycast(origin, delta, params)
		if not hit then
			break
		end
		local inst = hit.Instance
		if inst:IsA("BasePart") and inst.Transparency >= 0.8 then
			if not skipped then
				skipped = table.clone(baseFilter)
			end
			table.insert(skipped :: { Instance }, inst)
			params.FilterDescendantsInstances = skipped :: { Instance }
			origin = hit.Position + delta.Unit * 0.05
		else
			local pulled = hit.Position + (target - hit.Position).Unit * 0.8
			safePos = if pulled.Y < 1.2 then Vector3.new(pulled.X, 1.2, pulled.Z) else pulled
			break
		end
	end
	if safePos == wanted then
		return camCf
	end
	return CFrame.new(safePos) * camCf.Rotation
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
	local fromShow = info ~= nil and info.fromShow == true
	local shiny = info ~= nil and info.variant == "Shiny"
	local creature = Creatures.get(creatureId)
	local motif = if creature then creature.revealStyle else "splash"
	local recipe = Cinematics.recipes[creatureId]
	if recipe then
		FishingCamera.stop()
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
	local hum = if root.Parent then root.Parent:FindFirstChildOfClass("Humanoid") else nil
	local startPos = root.Position
	local function cancelled(): boolean
		return skipped
			or not root:IsDescendantOf(Workspace)
			or (hum ~= nil and hum.Health <= 0)
			or (root.Position - startPos).Magnitude > 25
	end
	if level >= 5 then
		Audio.play("legendary", 0.24, 0.74)
	end
	local restore: (() -> ())? = nil
	local signature: Folder? = nil
	if not fromShow and not reduced then
		if level == 6 then
			restore = mysticIntro(origin, color, cancelled)
		elseif level == 5 then
			restore, signature =
				legendaryIntro(creatureId, origin, root.Position, accent, cancelled)
		elseif level >= 4 then
			Effects.pillar(origin, color, 35, 1)
			Effects.ripple(origin, color, 10, 0.9)
			task.wait(0.45)
		end
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
	local visualScale = Mutation.scale(info and info.sizeMult)
	local mutation = info and info.mutation
	model:ScaleTo(model:GetScale() * style.size / biggest * visualScale)
	local bounds = Framing.measure(model)
	local paintMutation = Mutation.paint(model, mutation)
	local mutationSparks = Mutation.particles(model, mutation)
	local motion = CreatureMotion.bind(model, motif)
	local preview = cloneCreature(creatureId)
	if not mutationSparks and (level >= 3 or shiny) and not reduced then
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
			if not fromShow then
				Effects.ripple(origin, Theme.rose, 9, 0.65)
				Effects.ripple(origin, Theme.gold, 12, 0.9)
			end
		end
	end
	model.Parent = Workspace

	if not fromShow then
		RevealStyles.play(motif, origin, level, reduced)
		Effects.splash(origin, accent, if reduced then 8 else 10 + level * 6)
		Effects.ripple(origin, color, 4 + level * 2, 0.8)
		if level >= 5 and not reduced then
			Effects.shake(0.27, if level == 6 then 1.55 else 1.15)
		end
	end

	-- The flight can turn. The final pose stays within a small sway of the viewer.
	local flat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local forward = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
	local clearance = if visualScale > 1 then math.max(0, (model:GetExtentsSize().Y - 4) / 2) else 0
	local display = root.Position + forward * (10 + clearance) + Vector3.yAxis * (3.2 + clearance)
	local shotPadding = if visualScale < 1 then 1.48 else 1.25
	local character = root.Parent
	local hand = character
		and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	local handPoint = if hand and hand:IsA("BasePart")
		then hand.Position
		else root.CFrame:PointToWorldSpace(Vector3.new(1, 0.4, -0.7))
	local from = if fromShow then handPoint else origin - Vector3.yAxis
	local apex = (from + display) / 2 + Vector3.yAxis * (if fromShow then 1.1 else style.apex)
	local viewer = -forward + forward:Cross(Vector3.yAxis) * 0.32 + Vector3.new(0, 0.08, 0)
	local axes = CFrame.lookAt(Vector3.zero, -viewer)
	local camera = Workspace.CurrentCamera
	local flightCamera = if not fromShow and visualScale ~= 1 and not reduced then camera else nil
	local restoreFlightCamera: (() -> ())? = nil
	local restoreCamera: (() -> ())? = nil
	local restoreForeground: (() -> ())? = nil
	local card: RevealCard.Card? = nil
	local photoButton: TextButton? = nil
	local touchControls = GuiService.TouchControlsEnabled
	local previewUsed = false
	local revealActiveSet = false

	local ok, err = pcall(function()
		if flightCamera then
			FishingCamera.stop()
			if restore then
				restore()
				restore = nil
			end
			local oldType = if flightCamera.CameraType == Enum.CameraType.Scriptable
				then Enum.CameraType.Custom
				else flightCamera.CameraType
			local oldFov = if flightCamera.CameraType == Enum.CameraType.Scriptable
				then 70
				else flightCamera.FieldOfView
			local oldCF, oldFocus = flightCamera.CFrame, flightCamera.Focus
			flightCamera.CameraType = Enum.CameraType.Scriptable
			flightCamera.FieldOfView = SHOT_FOV
			restoreFlightCamera = function()
				flightCamera.CFrame = oldCF
				flightCamera.Focus = oldFocus
				flightCamera.FieldOfView = oldFov
				flightCamera.CameraType = oldType
			end
		end
		local start = os.clock()
		local flight = if fromShow
			then 0.43
			elseif reduced then math.min(REDUCED_FLIGHT_MAX, style.flight)
			else style.flight
		local finalScale = model:GetScale()
		while not cancelled() do
			local elapsed = os.clock() - start
			local a = if reduced and (visualScale ~= 1 or fromShow)
				then 1
				else math.min(elapsed / flight, 1)
			if level >= 5 and not reduced then
				a = TweenService:GetValue(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			end
			local p = from:Lerp(apex, a):Lerp(apex:Lerp(display, a), a)
			if fromShow then
				model:ScaleTo(finalScale * (0.12 + 0.88 * a))
			end
			local turn = if reduced
				then 0
				else (1 - a) ^ 2 * math.pi * (if fromShow then 0.5 else 2)
			local pose = Framing.pose(bounds, p, viewer, turn)
			model:PivotTo(
				if fromShow
					then pose + pose:VectorToWorldSpace(bounds.center) * (0.88 * (1 - a))
					else pose
			)
			if flightCamera then
				local viewport = flightCamera.ViewportSize
				if viewport.X > 0 and viewport.Y > 0 then
					local region = RevealCard.subjectRegion(viewport)
					local wantedCf = Framing.camera(
						bounds,
						pose,
						axes,
						p,
						viewport,
						SHOT_FOV,
						region,
						shotPadding
					)
					flightCamera.CFrame = safeRevealCamera(wantedCf, p, character, model)
					flightCamera.Focus = CFrame.new(p)
				end
			end
			if paintMutation then
				paintMutation(elapsed, reduced)
			end
			if mutationSparks then
				mutationSparks.Enabled = not reduced
			end
			if a >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end

		local name = Strings.creatureName[creatureId] or creatureId
		local takePhoto = false
		local holdStart = os.clock()
		local base = Framing.pose(bounds, display, viewer)

		if not cancelled() then
			FishingCamera.stop()
			if restore then
				restore()
				restore = nil
			end
			Audio.capture(rarity, shiny)
			if info and (info.isRecord or info.isGiant) then
				Audio.play("level", 0.23, if info.isGiant then 0.9 else 1.12)
			end
			previewUsed = true
			local activeCard = RevealCard.open(
				Ui.screen(),
				preview,
				creatureId,
				name,
				rarity,
				color,
				info,
				reduced
			)
			card = activeCard
			restoreForeground = clearForeground(root)
			GuiService.TouchControlsEnabled = false
			revealActiveSet = true
			Players.LocalPlayer:SetAttribute("CatchRevealActive", true)
			if level >= 4 then
				local button =
					RevealCard.action(Ui.screen(), "TakePhoto", Text.photo, Theme.crystal)
				photoButton = button
				button.Activated:Connect(function()
					takePhoto = true
				end)
			end
			if camera then
				local oldType = if camera.CameraType == Enum.CameraType.Scriptable
					then Enum.CameraType.Custom
					else camera.CameraType
				local oldFov = if camera.CameraType == Enum.CameraType.Scriptable
					then 70
					else camera.FieldOfView
				local oldCFrame, oldFocus = camera.CFrame, camera.Focus
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
							shotPadding
						)
						base = Framing.pose(bounds, display, shot.Position - display)
						shot = safeRevealCamera(
							Framing.camera(
								bounds,
								base,
								axes,
								display,
								viewport,
								SHOT_FOV,
								region,
								shotPadding
							),
							display,
							character,
							model
						)
					end
					local elapsed = os.clock() - holdStart
					local quiet = reduced
						or Players.LocalPlayer:GetAttribute("ReduceEffects") == true
					local blend = if quiet or flightCamera
						then 1
						else math.min(elapsed / SHOT_BLEND, 1)
					local eased = TweenService:GetValue(
						blend,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.Out
					)
					camera.CFrame = oldCFrame:Lerp(shot, eased)
					camera.FieldOfView = oldFov + (SHOT_FOV - oldFov) * eased
					camera.Focus = CFrame.new(display)
					if not quiet then
						CreatureMotion.pose(motion, base, elapsed, false)
						activeCard.preview(elapsed)
					else
						model:PivotTo(base)
					end
					if paintMutation then
						paintMutation(flight + elapsed, quiet)
					end
					if mutationSparks then
						if quiet and mutationSparks.Enabled then
							mutationSparks:Clear()
						end
						mutationSparks.Enabled = not quiet
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
		end

		local hold = if reduced and level == 6 then REDUCED_MYSTIC_HOLD else style.hold
		while card and not cancelled() and not takePhoto and os.clock() - holdStart < hold do
			RunService.RenderStepped:Wait()
		end
		if restoreCamera then
			restoreCamera()
			restoreCamera = nil
		end
		if restoreFlightCamera then
			restoreFlightCamera()
			restoreFlightCamera = nil
		end
		if skipButton then
			skipButton:Destroy()
			skipButton = nil
		end
		if photoButton then
			photoButton:Destroy()
			photoButton = nil
		end
		CreatureMotion.reset(motion, base)
		if signature then
			signature:Destroy()
			signature = nil
		end
		if restore then
			restore()
			restore = nil
		end
		if card then
			card.close(takePhoto or cancelled())
			card = nil
		end
		if not cancelled() then
			seen[creatureId] = true
		end
		if takePhoto and not cancelled() then
			PhotoMode.show(
				model,
				root,
				name,
				rarity,
				color,
				base:VectorToWorldSpace(bounds.forward)
			)
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
	end)

	-- Guaranteed restoration even if an error or abrupt interruption occurs.
	if restoreCamera then
		restoreCamera()
	end
	if restoreFlightCamera then
		restoreFlightCamera()
	end
	if skipButton then
		skipButton:Destroy()
	end
	if photoButton then
		photoButton:Destroy()
	end
	if signature then
		signature:Destroy()
	end
	if restore then
		restore()
	end
	if card then
		card.close(true)
	end
	if not previewUsed and preview.Parent == nil then
		preview:Destroy()
	end
	if model.Parent then
		model:Destroy()
	end
	if restoreForeground then
		restoreForeground()
	end
	if revealActiveSet then
		GuiService.TouchControlsEnabled = touchControls
		Players.LocalPlayer:SetAttribute("CatchRevealActive", false)
	end
	if not ok then
		warn("[Reveal] error during reveal:", err)
	end
end

return Reveal
