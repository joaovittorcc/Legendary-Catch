--!strict
--[[
	MinigameFx.luau
	Suggested Studio path: StarterPlayer/StarterPlayerScripts/Client/Features/Vfx/MinigameFx
	Rojo path: src/client/Features/Vfx/MinigameFx.luau

	Integration:
	- Unified game-feel layer for all 3 fishing minigames ("Reel", "Precision", "Rhythm").
	- Optional session setup (binds UI progress bar & world bobber/rod anchor):
	    MinigameFx.beginSession({
	        minigameType = "Rhythm", -- "Reel" | "Precision" | "Rhythm"
	        progressBar = myBarFrame,
	        container = myMinigameFrame,
	        worldTarget = bobberPartOrVector3,
	    })
	- Core callbacks (work even without beginSession for instant testing):
	    MinigameFx.onHit("perfect" | "great" | "good" | number01)
	    MinigameFx.onMiss()
	    MinigameFx.onProgress(0..1)
	    MinigameFx.onWin("Legendary", worldPos?)
	    MinigameFx.onLose(worldPos?)
	- Escalates combo colors & audio pitch on streaks, clearly flags the FIRST miss,
	  intensifies progress-bar shimmer near 100%, and triggers a rarity-scaled burst on win.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local StringsUi = require(Shared:WaitForChild("StringsUi"))
local VfxFolder = Shared:WaitForChild("Vfx")
local Palette = require(VfxFolder:WaitForChild("Palette"))
local SfxKit = require(VfxFolder:WaitForChild("SfxKit"))
local VfxKit = require(VfxFolder:WaitForChild("VfxKit"))

local function isPortuguese(): boolean
	local lp = Players.LocalPlayer
	return lp ~= nil and string.lower(string.sub(lp.LocaleId, 1, 2)) == "pt"
end

local function label(key: string): string
	local pt = isPortuguese()
	if key == "perfect" then
		return StringsUi.perfect
	elseif key == "great" then
		return Strings.powerLabel.green .. "!"
	elseif key == "escaped" then
		return string.upper(Strings.escaped)
	elseif key == "epic" then
		return string.upper(Strings.rarity.Epic) .. "!"
	elseif key == "legendary" then
		return string.upper(Strings.rarity.Legendary) .. "!"
	elseif key == "careful" then
		return if pt then "CUIDADO!" else "CAREFUL!"
	elseif key == "oops" then
		return if pt then "OPS!" else "OOPS!"
	elseif key == "caught" then
		return if pt then "CAPTURADO!" else "CAUGHT!"
	elseif key == "amazing" then
		return if pt then "INCRÍVEL!" else "AMAZING!"
	end
	return key
end

export type MinigameType = "Reel" | "Precision" | "Rhythm"
export type HitQuality = "good" | "great" | "perfect" | number

export type SessionOptions = {
	minigameType: MinigameType?,
	progressBar: GuiObject?,
	container: GuiObject?,
	worldTarget: (Vector3 | BasePart)?,
}

local MinigameFx = {
	order = 128,
}

-- ============================================================================
-- STATE
-- ============================================================================

local COMBO_LADDER: { Color3 } = {
	Palette.Rarities.Common.primary,
	Palette.Rarities.Uncommon.primary,
	Palette.Rarities.Rare.primary,
	Palette.Rarities.Epic.primary,
	Palette.Rarities.Legendary.primary,
}

local started = false
local activeType: MinigameType = "Reel"
local combo = 0
local missCount = 0
local currentProgress = 0
local elapsed = 0

local boundProgressBar: GuiObject? = nil
local boundContainer: GuiObject? = nil
local containerBasePos: UDim2? = nil
local boundWorldTarget: (Vector3 | BasePart)? = nil

local progressStroke: UIStroke? = nil
local progressShimmer: UIGradient? = nil
local heartbeatConn: RBXScriptConnection? = nil
local activeTweens: { Tween } = {}

-- ============================================================================
-- HELPERS
-- ============================================================================

local function cancelTweens()
	for _, tw in ipairs(activeTweens) do
		tw:Cancel()
	end
	table.clear(activeTweens)
end

local function trackTween(tw: Tween)
	table.insert(activeTweens, tw)
	tw.Completed:Connect(function()
		local idx = table.find(activeTweens, tw)
		if idx then
			table.remove(activeTweens, idx)
		end
	end)
	tw:Play()
end

local function resolveWorldPosition(overridePos: Vector3?): Vector3
	if overridePos then
		return overridePos
	end
	if boundWorldTarget then
		if typeof(boundWorldTarget) == "Vector3" then
			return boundWorldTarget
		elseif boundWorldTarget.Parent then
			return boundWorldTarget.Position
		end
	end
	local lp = Players.LocalPlayer
	local char = if lp then lp.Character else nil
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") else nil
	if hrp and hrp:IsA("BasePart") then
		return hrp.Position + hrp.CFrame.LookVector * 8 + Vector3.new(0, 1.5, 0)
	end
	return Vector3.new(0, 10, 0)
end

local function normalizeQuality(quality: HitQuality?): "good" | "great" | "perfect"
	if typeof(quality) == "number" then
		if quality >= 0.88 then
			return "perfect"
		elseif quality >= 0.55 then
			return "great"
		end
		return "good"
	elseif typeof(quality) == "string" then
		local q = string.lower(quality)
		if q == "perfect" or q == "perfeito" then
			return "perfect"
		elseif q == "great" or q == "otimo" or q == "ótimo" then
			return "great"
		end
	end
	return "good"
end

local function comboColorFor(streak: number): Color3
	local idx = math.clamp(1 + math.floor(math.max(0, streak - 1) / 2), 1, #COMBO_LADDER)
	return COMBO_LADDER[idx]
end

local function detachProgressDecorators()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	if progressStroke and progressStroke.Parent then
		progressStroke:Destroy()
	end
	progressStroke = nil
	if progressShimmer and progressShimmer.Parent then
		progressShimmer:Destroy()
	end
	progressShimmer = nil
end

local function ensureProgressDecorators(bar: GuiObject)
	detachProgressDecorators()

	local stroke = Instance.new("UIStroke")
	stroke.Name = "MinigameProgressGlowStroke"
	stroke.Thickness = 2
	stroke.Transparency = 0.85
	stroke.Color = Palette.World.CrystalCyan
	stroke.Parent = bar
	progressStroke = stroke

	local grad = Instance.new("UIGradient")
	grad.Name = "MinigameProgressShimmer"
	grad.Rotation = 18
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(235, 245, 255)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(235, 245, 255)),
	})
	grad.Offset = Vector2.new(-1.2, 0)
	grad.Parent = bar
	progressShimmer = grad

	heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		if not boundProgressBar or not boundProgressBar.Parent then
			detachProgressDecorators()
			return
		end
		elapsed += dt
		local p = currentProgress
		local reduced = VfxKit.isReducedEffects()

		-- Shimmer sweeps faster and stroke glows warmer gold as progress nears 100%
		if progressShimmer then
			if reduced or p < 0.25 then
				progressShimmer.Offset = Vector2.new(-1.2, 0)
			else
				local sweepSpeed = 0.7 + p * 1.4
				local offset = ((elapsed * sweepSpeed) % 2.4) - 1.2
				progressShimmer.Offset = Vector2.new(offset, 0)
			end
		end

		if progressStroke then
			local highBoost = math.clamp((p - 0.55) / 0.45, 0, 1)
			local pulse = if reduced
				then 0.5
				else (0.5 + 0.5 * math.sin(elapsed * (4 + highBoost * 8)))
			progressStroke.Color = Palette.World.CrystalCyan:Lerp(Palette.World.Gold, highBoost)
			progressStroke.Thickness = 1.5 + highBoost * 2.8 + pulse * highBoost * 1.1
			progressStroke.Transparency =
				math.clamp(0.85 - p * 0.45 - highBoost * 0.35 * pulse, 0.05, 0.9)
		end
	end)
end

-- Lightweight UI badge pop on the bound container (if provided)
local function spawnUiPopup(text: string, color: Color3, scaleBoost: number)
	if not boundContainer or not boundContainer.Parent then
		return
	end
	local lbl = Instance.new("TextLabel")
	lbl.Name = "MinigameFeedbackPopup"
	lbl.AnchorPoint = Vector2.new(0.5, 0.5)
	lbl.Position = UDim2.fromScale(0.5, 0.22)
	lbl.Size = UDim2.fromScale(0.55 * scaleBoost, 0.16 * scaleBoost)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = text
	lbl.TextScaled = true
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0.2
	lbl.TextStrokeColor3 = Color3.fromRGB(20, 24, 38)
	lbl.ZIndex = 40
	lbl.Parent = boundContainer

	local tw = TweenService:Create(
		lbl,
		TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Position = UDim2.fromScale(0.5, 0.08),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)
	tw.Completed:Connect(function()
		lbl:Destroy()
	end)
	trackTween(tw)
end

local function nudgeContainerHorizontal(amplitudePx: number)
	if
		VfxKit.isReducedEffects()
		or not boundContainer
		or not boundContainer.Parent
		or not containerBasePos
	then
		return
	end
	local base = containerBasePos
	local leftPos =
		UDim2.new(base.X.Scale, base.X.Offset - amplitudePx, base.Y.Scale, base.Y.Offset)
	local rightPos =
		UDim2.new(base.X.Scale, base.X.Offset + amplitudePx * 0.7, base.Y.Scale, base.Y.Offset)

	local tw1 = TweenService:Create(
		boundContainer,
		TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = leftPos }
	)
	local tw2 = TweenService:Create(
		boundContainer,
		TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ Position = rightPos }
	)
	local tw3 = TweenService:Create(
		boundContainer,
		TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = base }
	)

	tw1.Completed:Connect(function()
		if boundContainer and boundContainer.Parent then
			trackTween(tw2)
		end
	end)
	tw2.Completed:Connect(function()
		if boundContainer and boundContainer.Parent then
			trackTween(tw3)
		end
	end)
	trackTween(tw1)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function MinigameFx.start()
	if started then
		return
	end
	started = true
	VfxKit.init()
	SfxKit.init()
end

function MinigameFx.beginSession(options: SessionOptions?)
	MinigameFx.start()
	MinigameFx.endSession()

	local opts = options or {} :: SessionOptions
	activeType = opts.minigameType or "Reel"
	combo = 0
	missCount = 0
	currentProgress = 0
	elapsed = 0

	boundProgressBar = opts.progressBar
	boundContainer = opts.container
	containerBasePos = if opts.container then opts.container.Position else nil
	boundWorldTarget = opts.worldTarget

	if boundProgressBar then
		ensureProgressDecorators(boundProgressBar)
	end
end

function MinigameFx.endSession()
	cancelTweens()
	detachProgressDecorators()
	if boundContainer and boundContainer.Parent and containerBasePos then
		boundContainer.Position = containerBasePos
	end
	boundProgressBar = nil
	boundContainer = nil
	containerBasePos = nil
	boundWorldTarget = nil
	combo = 0
	missCount = 0
	currentProgress = 0
end

-- Hit feedback: combo escalates color & pitch; "PERFEITO!" bursts stars
function MinigameFx.onHit(quality: HitQuality?, worldOverride: Vector3?)
	MinigameFx.start()
	local q = normalizeQuality(quality)
	combo += 1

	local pos = resolveWorldPosition(worldOverride)
	local streakColor = comboColorFor(combo)
	local pitchBoost = 1.0 + math.min(combo - 1, 12) * 0.032
	local vfxTier = math.clamp(1 + math.floor(combo / 3), 1, 4)

	if q == "perfect" then
		SfxKit.play("minigame_perfect", { pitch = pitchBoost })
		local goldMix = Palette.World.WarmGold:Lerp(streakColor, 0.35)
		VfxKit.burst(pos, "stars", 0.85, vfxTier, goldMix)
		VfxKit.ring(pos, goldMix, 4.2, 0.42, 0.75, vfxTier)

		local perfectLabel = label("perfect")
		local labelText = if combo >= 3
			then string.format("%s x%d", perfectLabel, combo)
			else perfectLabel
		VfxKit.floatingText(
			pos + Vector3.new(0, 2.2, 0),
			labelText,
			Palette.World.WarmGold,
			0.95,
			1.15
		)
		spawnUiPopup(labelText, Palette.World.WarmGold, 1.15)
	elseif q == "great" then
		SfxKit.play("minigame_hit", { pitch = pitchBoost })
		VfxKit.burst(pos, "sparks", 0.6, vfxTier, streakColor)
		VfxKit.ring(pos, streakColor, 3.0, 0.35, 0.5, vfxTier)

		local greatLabel = label("great")
		local labelText = if combo >= 3
			then string.format("%s x%d", greatLabel, combo)
			else greatLabel
		VfxKit.floatingText(pos + Vector3.new(0, 1.9, 0), labelText, streakColor, 0.8, 0.95)
		spawnUiPopup(labelText, streakColor, 1.0)
	else
		SfxKit.play("minigame_hit", { volume = 0.5, pitch = pitchBoost * 0.95 })
		VfxKit.burst(pos, "sparks", 0.38, 1, streakColor)
		if activeType == "Rhythm" or combo >= 4 then
			spawnUiPopup(string.format("x%d", combo), streakColor, 0.85)
		end
	end
end

-- Miss feedback: resets combo, soft shake, FIRST miss clearly flagged so player reacts fast
function MinigameFx.onMiss(worldOverride: Vector3?)
	MinigameFx.start()
	combo = 0
	missCount += 1

	local pos = resolveWorldPosition(worldOverride)
	local warnColor = Color3.fromRGB(255, 112, 92)
	local isFirstMiss = missCount == 1

	SfxKit.play("minigame_miss", {
		volume = if isFirstMiss then 0.65 else 0.5,
		pitch = if isFirstMiss then 1.0 else 0.92,
	})

	VfxKit.cameraShake(if isFirstMiss then 0.22 else 0.14, 0.16)
	nudgeContainerHorizontal(if isFirstMiss then 10 else 6)
	VfxKit.burst(pos, "smoke", 0.35, 1, warnColor)

	if isFirstMiss then
		-- Clear, friendly signal on first slip
		local warnText = label("careful")
		VfxKit.ring(pos, warnColor, 4.5, 0.45, 0.65, 2)
		VfxKit.floatingText(pos + Vector3.new(0, 2.1, 0), warnText, warnColor, 0.95, 1.08)
		spawnUiPopup(warnText, warnColor, 1.1)
		if progressStroke and progressStroke.Parent then
			progressStroke.Color = warnColor
			progressStroke.Transparency = 0.15
		end
	else
		local oopsText = label("oops")
		VfxKit.floatingText(pos + Vector3.new(0, 1.8, 0), oopsText, warnColor, 0.7, 0.9)
		spawnUiPopup(oopsText, warnColor, 0.9)
	end
end

-- Progress update (0..1): ramps progress-bar glow & shimmer as player approaches victory
function MinigameFx.onProgress(p: number)
	MinigameFx.start()
	currentProgress = math.clamp(p, 0, 1)
end

-- Victory burst scaled by rarity per Intensity Map
function MinigameFx.onWin(rarity: string?, worldOverride: Vector3?)
	MinigameFx.start()
	local pos = resolveWorldPosition(worldOverride)
	local theme = Palette.getRarity(rarity)
	local tier = theme.tier

	SfxKit.play("minigame_win", {
		volume = 0.65 + tier * 0.06,
		pitch = 0.96 + tier * 0.04,
	})

	local caughtText = label("caught")
	if tier == 1 then
		-- Common: small clean burst
		VfxKit.burst(pos, "sparks", 0.65, 1, theme.primary)
		VfxKit.floatingText(pos + Vector3.new(0, 2.2, 0), caughtText, theme.text, 0.95, 1.0)
	elseif tier == 2 then
		-- Uncommon: burst + ring
		VfxKit.burst(pos, "sparks", 0.8, 2, theme.primary)
		VfxKit.ring(pos, theme.primary, 6.0, 0.55, 0.8, 2)
		VfxKit.floatingText(pos + Vector3.new(0, 2.4, 0), caughtText, theme.text, 1.0, 1.08)
	elseif tier == 3 then
		-- Rare: burst + stars + ring
		VfxKit.burst(pos, "stars", 0.85, 3, theme.primary)
		VfxKit.ring(pos, theme.primary, 8.0, 0.62, 0.9, 3)
		VfxKit.fakeGlow(pos + Vector3.new(0, 0.8, 0), theme.primary, 7.0, 0.7)
		VfxKit.floatingText(pos + Vector3.new(0, 2.6, 0), label("amazing"), theme.text, 1.1, 1.15)
	elseif tier == 4 then
		-- Epic: burst + stars + shockwave
		VfxKit.burst(pos, "stars", 0.95, 4, theme.primary)
		VfxKit.shockwave(pos, theme.primary, 11.0, 0.65, 0.9, 4)
		VfxKit.confettiBurst(
			pos,
			{ theme.primary, theme.secondary, Palette.World.WarmGold },
			0.75,
			4
		)
		VfxKit.cameraShake(0.24, 0.2)
		VfxKit.floatingText(pos + Vector3.new(0, 2.8, 0), label("epic"), theme.text, 1.15, 1.25)
	else
		-- Legendary / Mystic: golden event burst
		VfxKit.burst(pos, "stars", 1.0, 5, theme.primary)
		VfxKit.shockwave(pos, theme.primary, 15.0, 0.75, 1.0, 5)
		VfxKit.pillarOfLight(pos, theme.primary, 32, 3.2, 1.4, 1.0, 5)
		VfxKit.confettiBurst(
			pos,
			{ theme.primary, theme.secondary, Palette.World.CrystalCyan, Palette.World.BlossomPink },
			1.0,
			5
		)
		VfxKit.cameraShake(0.38, 0.28)
		VfxKit.screenFlash(theme.glow, 0.35, 0.12)
		VfxKit.floatingText(
			pos + Vector3.new(0, 3.0, 0),
			label("legendary"),
			theme.text,
			1.25,
			1.35
		)
	end

	spawnUiPopup(caughtText, theme.primary, 1.2)
	MinigameFx.endSession()
end

-- Lose feedback: soft splash + escaping bubbles, encouraging & gentle
function MinigameFx.onLose(worldOverride: Vector3?)
	MinigameFx.start()
	local pos = resolveWorldPosition(worldOverride)
	local escapedText = label("escaped")

	SfxKit.play("minigame_lose", { volume = 0.6 })
	VfxKit.burst(pos, "bubbles", 0.55, 1)
	VfxKit.ring(pos, Color3.fromRGB(168, 214, 232), 4.2, 0.6, 0.45, 1)
	VfxKit.floatingText(
		pos + Vector3.new(0, 2.0, 0),
		escapedText,
		Color3.fromRGB(210, 226, 242),
		1.0,
		0.95
	)
	spawnUiPopup(escapedText, Color3.fromRGB(210, 226, 242), 1.0)
	MinigameFx.endSession()
end

function MinigameFx.getCombo(): number
	return combo
end

function MinigameFx.destroy()
	MinigameFx.endSession()
	started = false
end

return MinigameFx
