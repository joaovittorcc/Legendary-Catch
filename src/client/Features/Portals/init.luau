--!strict
-- Client visuals for ZonePortals:
--   - Localizes portal ProximityPrompts and sign status (PT-BR / EN)
--   - Switches each portal between unlocked (glowing, spinning ring, light particles)
--     and locked (dimmed, lock icon, "Precisa de nível N") based on PlayerLevel
--   - Respects Player attribute ReduceEffects (stops ring rotation, particles and fade)
--   - Plays a short 0.4 s glow/fade transition on teleport (PortalEffect remote)

local CollectionService = game:GetService("CollectionService")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Strings = require(Shared:WaitForChild("Strings"))
local Training = require(Shared:WaitForChild("Config"):WaitForChild("Training"))
local Zones = require(Shared:WaitForChild("Config"):WaitForChild("Zones"))

local TRAINING_ISLAND_NAMES_PT: { [number]: string } = {
	[1] = "Ilha do Aprendiz",
	[2] = "Ilha do Recife",
	[3] = "Abismo Estelar",
	[4] = "Ilha Celestial",
}

local TRAINING_ISLAND_NAMES_EN: { [number]: string } = {
	[1] = "Apprentice Island",
	[2] = "Training Reef",
	[3] = "Star Abyss",
	[4] = "Celestial Island",
}

local Portals = {}
Portals.order = 140

local PORTAL_TAG = "ZonePortal"
local ANIMATE_DISTANCE = 130
local LOCKED_CORE_COLOR = Color3.fromRGB(48, 56, 76)
local LOCKED_RING_COLOR = Color3.fromRGB(92, 98, 120)
local LOCKED_TEXT_COLOR = Color3.fromRGB(255, 196, 122)

local player = Players.LocalPlayer

local function isPortuguese(): boolean
	local ok, locale = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	local id = if ok and typeof(locale) == "string" then locale else player.LocaleId
	return string.lower(string.sub(id, 1, 2)) == "pt"
end

type PortalVisual = {
	trigger: BasePart,
	model: Model,
	zoneId: string,
	destination: string,
	primaryColor: Color3,
	accentColor: Color3,
	ring: Model?,
	ringBaseCF: CFrame?,
	core: BasePart?,
	light: PointLight?,
	emitter: ParticleEmitter?,
	statusLabel: TextLabel?,
	signStroke: UIStroke?,
	unlocked: boolean,
}

local visuals: { [BasePart]: PortalVisual } = {}

local function currentLevel(): number
	local raw = player:GetAttribute("PlayerLevel")
	return if typeof(raw) == "number" then raw else 1
end

local function isReduced(): boolean
	return player:GetAttribute("ReduceEffects") == true
end

local function localizePrompt(
	trigger: BasePart,
	destination: string,
	zoneId: string,
	unlocked: boolean,
	minLevel: number
)
	local prompt = trigger:FindFirstChild("UsePortal")
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		return
	end
	local pt = isPortuguese()
	if destination == "main" then
		prompt.ActionText = if pt then "Voltar" else "Return"
		prompt.ObjectText = if pt then "Ilha Principal" else "Main Island"
		return
	end

	local rawIsland = trigger:GetAttribute("TrainingIsland")
	if typeof(rawIsland) == "number" then
		local idx = Training.islandIndex(rawIsland)
		local islandName = (if pt then TRAINING_ISLAND_NAMES_PT else TRAINING_ISLAND_NAMES_EN)[idx]
			or destination
		local def = Training.ISLANDS[idx]
		if def and def.gate > 0 then
			local gateText = Training.formatPower(def.gate, if pt then "," else ".")
			prompt.ObjectText = if pt
				then string.format("%s (×%d · %s Poder)", islandName, def.mult, gateText)
				else string.format("%s (×%d · %s Power)", islandName, def.mult, gateText)
		elseif def then
			prompt.ObjectText = string.format("%s (×%d)", islandName, def.mult)
		else
			prompt.ObjectText = islandName
		end
		prompt.ActionText = if pt then "Entrar" else "Enter"
		return
	end

	local zName = Strings.zoneName[zoneId] or zoneId
	prompt.ObjectText = zName
	if unlocked then
		prompt.ActionText = if pt then "Entrar" else "Enter"
	else
		prompt.ActionText = string.format(Strings.zoneRequiredLevel, minLevel)
	end
end

local function applyPortalState(v: PortalVisual)
	local level = currentLevel()
	local reduced = isReduced()
	local pt = isPortuguese()
	local zone = Zones.get(v.zoneId)
	local minLevel = if zone then zone.minLevel else 1
	local unlocked = v.destination == "main" or level >= minLevel
	v.unlocked = unlocked

	localizePrompt(v.trigger, v.destination, v.zoneId, unlocked, minLevel)

	if v.core then
		v.core.Color = if unlocked then v.primaryColor else LOCKED_CORE_COLOR
		v.core.Transparency = if unlocked then 0.40 else 0.76
	end
	if v.light then
		v.light.Enabled = unlocked
		v.light.Brightness = if unlocked then 1.4 else 0
	end
	if v.emitter then
		local active = unlocked and not reduced
		v.emitter.Enabled = active
		v.emitter.Rate = if active then 8 else 0
	end
	if v.ring then
		for i, seg in v.ring:GetChildren() do
			if seg:IsA("BasePart") and seg.Name ~= "RingPivot" then
				if unlocked then
					seg.Color = if i % 2 == 0 then v.primaryColor else v.accentColor
				else
					seg.Color = LOCKED_RING_COLOR
				end
			end
		end
	end
	if v.statusLabel then
		if v.destination == "main" then
			v.statusLabel.Text = if pt then "Voltar · Portal" else "Return · Portal"
			v.statusLabel.TextColor3 = v.accentColor
		elseif unlocked then
			v.statusLabel.Text = if pt
				then string.format("Nível %d · Liberado", minLevel)
				else string.format("Level %d · Unlocked", minLevel)
			v.statusLabel.TextColor3 = v.accentColor
		else
			v.statusLabel.Text = "🔒 " .. string.format(Strings.zoneRequiredLevel, minLevel)
			v.statusLabel.TextColor3 = LOCKED_TEXT_COLOR
		end
	end
	if v.signStroke then
		v.signStroke.Color = if unlocked then v.primaryColor else LOCKED_RING_COLOR
	end
end

local function registerPortal(inst: Instance)
	if not inst:IsA("BasePart") or visuals[inst] then
		return
	end
	local model = inst.Parent
	if not (model and model:IsA("Model")) then
		return
	end

	local rawDest = inst:GetAttribute("Destination")
	local destination = if typeof(rawDest) == "string" then rawDest else ""
	local rawZone = inst:GetAttribute("ZoneId")
	local zoneId = if typeof(rawZone) == "string" then rawZone else Zones.DEFAULT_ID
	local rawPrimary = inst:GetAttribute("PrimaryColor")
	local rawAccent = inst:GetAttribute("AccentColor")
	local primaryColor = if typeof(rawPrimary) == "Color3"
		then rawPrimary
		else Color3.fromRGB(92, 224, 255)
	local accentColor = if typeof(rawAccent) == "Color3"
		then rawAccent
		else Color3.fromRGB(255, 210, 102)

	local ringObj = model:FindFirstChild("PortalRing")
	-- Avoid fighting HubAnimator if the ring is already tagged HubSpin, and avoid capturing
	-- an empty pivot before StreamingEnabled delivers the ring's parts.
	local ring = if ringObj
			and ringObj:IsA("Model")
			and not CollectionService:HasTag(ringObj, "HubSpin")
		then ringObj
		else nil
	local ringBaseCF: CFrame? = if ring and ring:FindFirstChildWhichIsA("BasePart", true)
		then ring:GetPivot()
		else nil
	local coreObj = model:FindFirstChild("PortalCore")
	local core = if coreObj and coreObj:IsA("BasePart") then coreObj else nil
	local light = core and core:FindFirstChildOfClass("PointLight") or nil
	local emitter = core and core:FindFirstChildOfClass("ParticleEmitter") or nil

	local signBoard = model:FindFirstChild("PortalSignBoard")
	local signGui = signBoard and signBoard:FindFirstChild("PortalSignGui")
	local statusObj = signGui and signGui:FindFirstChild("Status", true)
	local statusLabel = if statusObj and statusObj:IsA("TextLabel") then statusObj else nil
	local strokeObj = signGui and signGui:FindFirstChild("SignStroke", true)
	local signStroke = if strokeObj and strokeObj:IsA("UIStroke") then strokeObj else nil

	local v: PortalVisual = {
		trigger = inst,
		model = model,
		zoneId = zoneId,
		destination = destination,
		primaryColor = primaryColor,
		accentColor = accentColor,
		ring = ring,
		ringBaseCF = ringBaseCF,
		core = core,
		light = light,
		emitter = emitter,
		statusLabel = statusLabel,
		signStroke = signStroke,
		unlocked = false,
	}
	visuals[inst] = v
	applyPortalState(v)

	-- Re-localize if server adds UsePortal prompt slightly after streaming in.
	inst.ChildAdded:Connect(function(child)
		if child.Name == "UsePortal" then
			applyPortalState(v)
		end
	end)
end

local function unregisterPortal(inst: Instance)
	if inst:IsA("BasePart") then
		visuals[inst] = nil
	end
end

local function refreshAll()
	for _, v in visuals do
		applyPortalState(v)
	end
end

local function buildFadeOverlay(): Frame
	local playerGui = player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("PortalTransitionGui")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "PortalTransitionGui"
	gui.DisplayOrder = 40
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local veil = Instance.new("Frame")
	veil.Name = "Veil"
	veil.Size = UDim2.fromScale(1, 1)
	veil.BackgroundColor3 = Color3.fromRGB(24, 34, 64)
	veil.BackgroundTransparency = 1
	veil.BorderSizePixel = 0
	veil.Visible = false
	veil.Parent = gui

	gui.Parent = playerGui
	return veil
end

function Portals.start()
	for _, inst in CollectionService:GetTagged(PORTAL_TAG) do
		registerPortal(inst)
	end
	CollectionService:GetInstanceAddedSignal(PORTAL_TAG):Connect(registerPortal)
	CollectionService:GetInstanceRemovedSignal(PORTAL_TAG):Connect(unregisterPortal)

	player:GetAttributeChangedSignal("PlayerLevel"):Connect(refreshAll)
	player:GetAttributeChangedSignal("ReduceEffects"):Connect(refreshAll)

	-- Smooth lightweight ring rotation (only unlocked portals within 130 studs, off if ReduceEffects).
	local spinAngle = 0
	RunService.Heartbeat:Connect(function(dt: number)
		if isReduced() then
			return
		end
		spinAngle += dt * 0.9
		local cam = Workspace.CurrentCamera
		local camPos = if cam then cam.CFrame.Position else nil
		for _, v in visuals do
			if v.unlocked and v.ring and v.ringBaseCF then
				if not camPos or (camPos - v.trigger.Position).Magnitude <= ANIMATE_DISTANCE then
					v.ring:PivotTo(v.ringBaseCF * CFrame.Angles(0, 0, spinAngle))
				end
			end
		end
	end)

	-- Teleport flash/fade effect (0.4 s total; skipped completely if ReduceEffects = true).
	local veil = buildFadeOverlay()
	local activeTween: Tween? = nil
	local remotes = ReplicatedStorage:WaitForChild(Net.FOLDER)
	local effectRemote = remotes:WaitForChild("PortalEffect") :: RemoteEvent

	effectRemote.OnClientEvent:Connect(function(payload: any)
		if typeof(payload) ~= "table" or isReduced() then
			return
		end
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
		if payload.phase == "start" then
			local tint = if typeof(payload.color) == "Color3"
				then payload.color:Lerp(Color3.fromRGB(16, 22, 42), 0.55)
				else Color3.fromRGB(24, 42, 74)
			veil.BackgroundColor3 = tint
			veil.BackgroundTransparency = 1
			veil.Visible = true
			local tw = TweenService:Create(
				veil,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 0.12 }
			)
			activeTween = tw
			tw:Play()
		elseif payload.phase == "done" then
			if not veil.Visible then
				return
			end
			local tw = TweenService:Create(
				veil,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }
			)
			activeTween = tw
			tw.Completed:Once(function()
				if activeTween == tw then
					veil.Visible = false
				end
			end)
			tw:Play()
		end
	end)
end

return Portals
