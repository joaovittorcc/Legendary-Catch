--!strict
-- Full-screen timing targets. Pointer hits must land on the current circle.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Text = require(Shared:WaitForChild("StringsUi")).minigames
local Theme = require(Shared:WaitForChild("UiTheme"))
local Control = require(script.Parent.Parent:WaitForChild("Control"))
local Ui = require(script.Parent.Parent:WaitForChild("Ui"))
local Input = require(script.Parent:WaitForChild("Input"))
local Hud = require(script.Parent.Parent.Parent:WaitForChild("Hud"))
local Audio = require(script.Parent.Parent.Parent:WaitForChild("Audio"))

local Rhythm = {}
type Target = { disc: Frame, ring: Frame, center: Vector2, diameter: number, time: number }

function Rhythm.run(
	area: Frame,
	tier: number,
	color: Color3,
	done: (boolean, boolean?) -> (),
	ringCount: number?
): () -> ()
	local cfg = Config.RHYTHM
	local total = ringCount or math.floor(Config.tierValue(cfg.rings, tier))
	local shrink = Config.tierValue(cfg.shrinkSeconds, tier)
	local window = math.min(shrink * cfg.window * Control.ease(), shrink * 0.46)
	local interval = Config.tierValue(cfg.gapByTier, tier)
	local player = Players.LocalPlayer
	local panel = area.Parent :: GuiObject
	local hidden: { [GuiObject]: boolean } = {}
	for _, child in panel:GetChildren() do
		if child:IsA("GuiObject") then
			hidden[child] = child.Visible
			child.Visible = false
		end
	end
	local hiddenLayers: { [ScreenGui]: boolean } = {}
	for _, name in { "TutorialGuide", "LegendaryOmen" } do
		local layer = player.PlayerGui:FindFirstChild(name)
		if layer and layer:IsA("ScreenGui") then
			hiddenLayers[layer] = layer.Enabled
			layer.Enabled = false
		end
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "RhythmGame"
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 7
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player.PlayerGui

	local counter = Ui.label(
		gui,
		"Counter",
		UDim2.fromOffset(160, 28),
		UDim2.new(0.5, -80, 0, Hud.navBottom() + 5),
		string.format(Text.rings, 0, total),
		Theme.sand
	)
	local rng = Random.new()
	local hits, misses = 0, 0
	local finished = false
	local current: Target? = nil
	local gap = 0.4
	local previous: Vector2? = nil
	local pending: thread? = nil
	local step: RBXScriptConnection? = nil
	local controls: { stop: () -> () }? = nil
	local function reduced(): boolean
		return player:GetAttribute("ReduceEffects") == true
	end
	local function cleanup()
		if step then
			step:Disconnect()
			step = nil
		end
		if controls then
			controls.stop()
		end
		gui:Destroy()
		for child, visible in hidden do
			if child.Parent then
				child.Visible = visible
			end
		end
		for layer, enabled in hiddenLayers do
			if layer.Parent then
				layer.Enabled = enabled
			end
		end
	end
	local function finish(success: boolean)
		if finished then
			return
		end
		finished = true
		if step then
			step:Disconnect()
			step = nil
		end
		if controls then
			controls.stop()
		end
		pending = task.delay(0.34, function()
			cleanup()
			done(success, success and misses == 0)
		end)
	end
	local function feedback(target: Target, success: boolean, perfect: boolean)
		Audio.play(if success then "hit" else "miss", 0.2, if perfect then 1.28 else 1)
		local width = math.min(160, target.diameter * 1.8)
		local lifetime = math.min(0.35, interval * 0.85)
		local label = Ui.label(
			gui,
			"TimingFeedback",
			UDim2.fromOffset(width, 26),
			UDim2.fromOffset(
				target.center.X - width / 2,
				target.center.Y - target.diameter / 2 - 30
			),
			if perfect then Text.perfect elseif success then Text.good else Text.miss,
			if success then Theme.gold else Color3.fromRGB(255, 125, 148)
		)
		if not reduced() then
			TweenService:Create(
				label,
				TweenInfo.new(lifetime),
				{ TextTransparency = 1, TextStrokeTransparency = 1 }
			):Play()
		end
		task.delay(lifetime, function()
			label:Destroy()
		end)
	end
	local function resolve(success: boolean, perfect: boolean)
		local target = current
		if not target or finished then
			return
		end
		current = nil
		feedback(target, success, perfect)
		target.disc:Destroy()
		target.ring:Destroy()
		if success then
			hits += 1
		else
			misses += 1
		end
		counter.Text = string.format(Text.rings, hits, total) .. string.rep("  ×", misses)
		if misses >= cfg.missesAllowed or hits >= total then
			finish(hits >= total)
		else
			gap = interval
		end
	end
	controls = Input.bind(function(point)
		local target = current
		if not target or finished then
			return
		end
		local inside = point == nil or (point - target.center).Magnitude <= target.diameter * 0.6
		local error = math.abs(target.time - shrink)
		resolve(inside and error <= window, inside and error <= window * 0.3)
	end)
	local function bounds(): (Vector2, Vector2, number)
		local size = gui.AbsoluteSize
		local diameter = math.clamp(math.min(size.X, size.Y) * 0.19, 60, 106)
		local margin = diameter * 0.86
		local top = Hud.navBottom() + 48
		local bottom = size.Y - (if size.Y < 430 then 80 else 105)
		local low = Vector2.new(math.max(size.X * 0.10, margin + 12), top + margin)
		local high = Vector2.new(size.X - low.X, math.max(low.Y, bottom - margin))
		return low, high, diameter
	end
	local function spawnTarget()
		local low, high, diameter = bounds()
		local center = low
		for _ = 1, 8 do
			center = Vector2.new(rng:NextNumber(low.X, high.X), rng:NextNumber(low.Y, high.Y))
			if not previous or (center - previous).Magnitude >= diameter * 1.3 then
				break
			end
		end
		previous = center
		local disc = Ui.frame(
			gui,
			"Target",
			UDim2.fromOffset(diameter, diameter),
			UDim2.fromOffset(center.X, center.Y),
			color
		)
		disc.AnchorPoint = Vector2.new(0.5, 0.5)
		Theme.surface(disc, color, diameter / 2)
		local gleam = Ui.frame(
			disc,
			"Gleam",
			UDim2.fromScale(0.55, 0.10),
			UDim2.fromScale(0.225, 0.13),
			Color3.new(1, 1, 1),
			0.65
		)
		Ui.corner(gleam, 0.5)
		local number = Ui.label(
			disc,
			"Order",
			UDim2.fromScale(0.8, 0.8),
			UDim2.fromScale(0.1, 0.1),
			tostring(hits + 1),
			Theme.sand
		)
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = 46
		limit.Parent = number
		local ring = Ui.frame(
			gui,
			"Approach",
			UDim2.fromOffset(diameter * 1.65, diameter * 1.65),
			disc.Position,
			color,
			1
		)
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		Ui.corner(ring, 0.5)
		Ui.stroke(ring, color, 4)
		current = { disc = disc, ring = ring, center = center, diameter = diameter, time = 0 }
	end
	step = RunService.RenderStepped:Connect(function(dt)
		if finished then
			return
		end
		counter.Position = UDim2.new(0.5, -80, 0, Hud.navBottom() + 5)
		local target = current
		if not target then
			gap -= dt
			if gap <= 0 then
				spawnTarget()
			end
			return
		end
		target.time += dt
		local low, high, diameter = bounds()
		if target.diameter ~= diameter then
			target.diameter = diameter
			target.disc.Size = UDim2.fromOffset(diameter, diameter)
		end
		target.center = Vector2.new(
			math.clamp(target.center.X, low.X, high.X),
			math.clamp(target.center.Y, low.Y, high.Y)
		)
		target.disc.Position = UDim2.fromOffset(target.center.X, target.center.Y)
		target.ring.Position = target.disc.Position
		local scale = 1.65 - 0.65 * math.clamp(target.time / shrink, 0, 1)
		target.ring.Size = UDim2.fromOffset(target.diameter * scale, target.diameter * scale)
		local stroke = target.ring:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = if math.abs(target.time - shrink) <= window then Theme.gold else color
		end
		if target.time > shrink + window then
			resolve(false, false)
		end
	end)
	return function()
		if pending then
			task.cancel(pending)
			pending = nil
		end
		finished = true
		cleanup()
	end
end

return Rhythm
