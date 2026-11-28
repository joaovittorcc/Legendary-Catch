--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Training)
local Fishing = require(Shared.Config.Fishing)
local Rods = require(Shared.Config.Rods)
local Net = require(Shared.Net)
local Strings = require(Shared.Strings)
local Text = require(Shared.StringsUi).fishingPower
local Theme = require(Shared.UiTheme)
local Data = require(script.Parent.Parent.Parent.Data)
local Hud = require(script.Parent.Parent.Hud)
local Panel = require(script.Parent.Parent.Hud.Panel)
local Art = require(script.Parent.Parent.Hud.Art)
local Ui = require(script.Parent.Parent.Fishing.Ui)
local Audio = require(script.Parent.Parent.Audio)

local Power = {}
local player = Players.LocalPlayer
local FIELD_PANEL = "TrainingField"
local REQUEST_TIMEOUT = 5
local BAND_COLORS: { [string]: Color3 } = {
	neutral = Color3.fromRGB(115, 126, 151),
	red = Color3.fromRGB(232, 74, 102),
	yellow = Color3.fromRGB(248, 192, 56),
	green = Color3.fromRGB(52, 205, 131),
	purple = Color3.fromRGB(183, 98, 255),
}

type PowerHud = {
	frame: Frame,
	stat: string,
	value: TextButton,
	gain: TextLabel,
}
local hud: PowerHud? = nil
local sequence = 0
local request: number? = nil
local confirmedField: number? = nil
local response: string? = nil
local refreshField: (() -> ())? = nil

local function numberText(value: number): string
	return Config.formatPower(value, Strings.decimalSep)
end

local function multiplierText(value: number): string
	return (
		string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", ""):gsub("%.", Strings.decimalSep)
	)
end

local function powerOf(stat: string): number
	local attribute = player:GetAttribute(Config.powerAttribute(stat))
	local data = Data.get()
	local values = data and data.training[stat]
	return Config.clampPower(attribute or (values and values.power))
end

local function totalPower(): number
	return powerOf("Control") + powerOf("Instinct")
end

local function fieldLevel(): number
	local data = Data.get()
	local actual = Config.fieldLevel(
		player:GetAttribute(Config.FIELD_ATTRIBUTE) or (data and data.trainingField)
	)
	return math.max(actual, confirmedField or 1)
end

local function fitText(object: TextButton, maxSize: number)
	object.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 10
	limit.MaxTextSize = maxSize
	limit.Parent = object
end

local function celebrate(parent: Frame, color: Color3)
	if Ui.reduced() then
		return
	end
	for index = 1, 7 do
		local angle = (index - 1) * 2 * math.pi / 7
		local spark = Ui.frame(
			parent,
			"PowerSpark",
			UDim2.fromOffset(6, 6),
			UDim2.new(0.5, 0, 0, 25),
			if index % 2 == 0 then Theme.gold else color
		)
		spark.AnchorPoint = Vector2.new(0.5, 0.5)
		spark.ZIndex = 6
		local fade = TweenService:Create(
			spark,
			TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = spark.Position
					+ UDim2.fromOffset(math.cos(angle) * 90, math.sin(angle) * 26),
				BackgroundTransparency = 1,
				Rotation = 135,
			}
		)
		fade.Completed:Once(function()
			spark:Destroy()
		end)
		fade:Play()
	end
end

function Power.fieldButton(parent: Frame, position: UDim2, width: number): TextButton
	local button = Panel.button(parent, Text.fieldTitle, Theme.crystal)
	button.Name = "OpenTrainingField"
	button.Position = position
	button.Size = UDim2.new(width, 0, 0, 44)
	fitText(button, 16)
	button.Activated:Connect(function()
		response = nil
		Hud.showPanel(FIELD_PANEL)
	end)
	return button
end

function Power.mount(frame: Frame, activeStat: string, color: Color3, field: TextButton)
	local value = Instance.new("TextButton")
	value.Name = "FishingPower"
	value.BackgroundTransparency = 1
	value.Size = UDim2.new(0.68, -4, 0, 24)
	value.Font = Theme.font
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextColor3 = color
	value.AutoButtonColor = false
	fitText(value, 17)
	value.Parent = frame
	local gain = Ui.label(
		frame,
		"PowerGain",
		UDim2.new(0.32, 0, 0, 22),
		UDim2.fromScale(0.68, 0),
		"",
		Theme.sand
	)
	gain.TextXAlignment = Enum.TextXAlignment.Right
	gain.TextStrokeTransparency = 1
	local gainLimit = Instance.new("UITextSizeConstraint")
	gainLimit.MaxTextSize = 15
	gainLimit.Parent = gain

	local instance: PowerHud = { frame = frame, stat = activeStat, value = value, gain = gain }
	hud = instance
	local full = false
	local shown = math.log10(powerOf(activeStat))
	local delta = 0
	local statName = Strings.stat[activeStat] or activeStat
	local function draw(dt: number)
		local target = powerOf(activeStat)
		local logTarget = math.log10(target)
		shown += (logTarget - shown) * (if Ui.reduced() then 1 else 1 - math.exp(-dt * 12))
		local visible = if math.abs(shown - logTarget) < 0.0003 then target else 10 ^ shown
		local text = if full then Theme.formatInt(target) else numberText(visible)
		value.Text = statName .. "  ·  " .. text
		value.TextColor3 = color:Lerp(Config.TIER_COLORS[Config.tier(target)], 0.38)
		field.Text = Text.field .. "  ×" .. multiplierText(Config.FIELD[fieldLevel()].mult)
	end
	value.Activated:Connect(function()
		full = not full
		draw(0)
	end)
	draw(0)
	local tick = RunService.Heartbeat:Connect(function(dt)
		delta += dt
		if delta >= 0.1 then
			draw(delta)
			delta = 0
		end
	end)
	frame.Destroying:Once(function()
		tick:Disconnect()
		if hud == instance then
			hud = nil
		end
	end)
end

local function previewField(viewport: ViewportFrame, level: number)
	viewport:ClearAllChildren()
	local kit = ReplicatedStorage:FindFirstChild("TrainingLevels")
	local models = kit and kit:FindFirstChild("Levels")
	local template = models and models:FindFirstChild(string.format("training_lv%02d", level))
	viewport.Visible = template ~= nil and template:IsA("Model")
	if not template or not template:IsA("Model") then
		return
	end
	local model = template:Clone()
	local box, extents = model:GetBoundingBox()
	local distance = math.max(extents.X, extents.Y, extents.Z, 1)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 38
	camera.CFrame =
		CFrame.lookAt(box.Position + Vector3.new(0.86, 0.64, 0.86) * distance, box.Position)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local world = Instance.new("WorldModel")
	model.Parent = world
	world.Parent = viewport
end

local function requirement(parent: Frame, x: number, variant: string): (TextLabel, Frame)
	local cell =
		Ui.frame(parent, variant, UDim2.fromScale(0.48, 1), UDim2.fromScale(x, 0), Theme.ink, 1)
	local label = Art.caption(cell, "Progress", "", 15, Theme.ink)
	label.TextStrokeTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 22)
	local track, fill = Panel.progressBar(cell, variant, 12)
	track.Position = UDim2.fromOffset(0, 25)
	return label, fill
end

function Power.start(buy: RemoteEvent)
	local _, body = Panel.create(FIELD_PANEL, Text.fieldTitle, Theme.crystal, 0.96, 530)
	Panel.stack(body)
	local current = Panel.label(body, "", 19, Theme.ink)
	current.TextStrokeTransparency = 1
	local nextLevel = Art.caption(body, "UpgradeMultiplier", "", 18, Theme.ink)
	nextLevel.Size = UDim2.new(1, 0, 0, 36)
	nextLevel.TextStrokeTransparency = 1
	local preview = Instance.new("ViewportFrame")
	preview.Name = "NextField"
	preview.Size = UDim2.new(1, 0, 0, 135)
	preview.BackgroundColor3 = Theme.outline
	preview.Ambient = Theme.sand
	preview.LightColor = Theme.cream
	Theme.corner(preview, 12)
	preview.Parent = body
	local gates =
		Ui.frame(body, "UpgradeRequirements", UDim2.new(1, 0, 0, 40), UDim2.new(), Theme.ink, 1)
	local coinLabel, coinFill = requirement(gates, 0, "gold")
	local powerLabel, powerFill = requirement(gates, 0.52, "cyan")
	local button = Panel.button(body, Text.upgrade, Theme.crystal)
	button.Name = "BuyTrainingField"
	local status = Panel.label(body, "", 15)
	status.TextStrokeTransparency = 1
	local aim = Panel.label(body, "", 15)
	aim.TextStrokeTransparency = 1
	local gauge = Ui.frame(body, "AimPreview", UDim2.new(1, 0, 0, 12), UDim2.new(), Theme.outline)
	local cells = {}
	for index = 1, Fishing.AIM.segments do
		table.insert(
			cells,
			Ui.frame(
				gauge,
				"Cell",
				UDim2.new(1 / Fishing.AIM.segments, -2, 1, 0),
				UDim2.fromScale((index - 1) / Fishing.AIM.segments, 0),
				Theme.muted
			)
		)
	end
	local shownPreview = 0
	local function refresh()
		if Hud.panel() ~= FIELD_PANEL then
			return
		end
		local level = fieldLevel()
		local nextDef = Config.FIELD[level + 1]
		local profile = Data.get()
		local coins = if profile then profile.coins else 0
		local power = totalPower()
		local allowed, reason = Config.canBuyField(level, power, coins)
		current.Text =
			string.format(Text.fieldLevel, level, multiplierText(Config.FIELD[level].mult))
		nextLevel.Text = if nextDef
			then string.format(Text.nextLevel, level + 1, multiplierText(nextDef.mult))
				.. "  ·  "
				.. string.format(
					Text.upgradeMultiplier,
					multiplierText(nextDef.mult / Config.FIELD[level].mult)
				)
			else Text.max
		if shownPreview ~= (if nextDef then level + 1 else level) then
			shownPreview = if nextDef then level + 1 else level
			previewField(preview, shownPreview)
		end
		gates.Visible = nextDef ~= nil
		if nextDef then
			coinLabel.Text = string.format(
				Text.coinProgress,
				Theme.formatInt(math.min(coins, nextDef.cost)),
				Theme.formatInt(nextDef.cost)
			)
			powerLabel.Text = string.format(
				Text.powerProgress,
				numberText(math.min(power, nextDef.gate)),
				numberText(nextDef.gate)
			)
			coinFill.Size = UDim2.fromScale(math.clamp(coins / math.max(nextDef.cost, 1), 0, 1), 1)
			powerFill.Size = UDim2.fromScale(math.clamp(power / math.max(nextDef.gate, 1), 0, 1), 1)
		end
		button.Visible = nextDef ~= nil
		button.Active = allowed and request == nil and Config.powerEnabled()
		button.Interactable = button.Active
		button.Selectable = button.Active
		button.Text = if request then Text.pending else Text.upgrade
		Panel.tintButton(button, if button.Active then Theme.crystal else Theme.muted)
		status.Text = response
			or (
				if reason == "power" then Text.power elseif reason == "coins" then Text.coins else ""
			)
		status.Visible = status.Text ~= ""
		local rod = profile and Rods.get(profile.equippedRod)
		local accuracy = Fishing.aimLevel(
			Config.progress(powerOf("Control")),
			if rod then rod.controlBonus else 0
		)
		aim.Text = string.format(Text.aim, math.round(accuracy * 100))
		for index, band in Fishing.aimLayout(accuracy) do
			cells[index].BackgroundColor3 = BAND_COLORS[band.band] or Theme.muted
		end
	end
	refreshField = refresh
	Hud.panelChanged:Connect(refresh)
	Data.changed:Connect(refresh)
	for _, stat in Config.STATS do
		player:GetAttributeChangedSignal(Config.powerAttribute(stat)):Connect(refresh)
	end
	player:GetAttributeChangedSignal(Config.FIELD_ATTRIBUTE):Connect(refresh)
	button.Activated:Connect(function()
		if not button.Active or request then
			return
		end
		sequence += 1
		local id = sequence
		request = id
		response = nil
		refresh()
		buy:FireServer(id)
		task.delay(REQUEST_TIMEOUT, function()
			if request == id then
				request = nil
				response = Text.changed
				refresh()
			end
		end)
	end)
end

function Power.onUpdate(update: Net.TrainingUpdate)
	local event = update.event
	local frame = hud
	if event == "fieldResult" and request ~= nil and update.requestId == request then
		request = nil
		if update.ok then
			confirmedField = update.field
			response = Text.upgraded
			Audio.play("level", 0.2, 1.1)
			Hud.toast(Text.upgraded, Theme.gold)
			if frame and not Ui.reduced() then
				Ui.bounce(frame.value)
				celebrate(frame.frame, Theme.gold)
			end
		else
			local reason = update.reason
			response = if reason == "power"
				then Text.power
				elseif reason == "coins" then Text.coins
				elseif reason == "max" then Text.max
				else Text.changed
		end
		if refreshField then
			refreshField()
		end
	elseif event == "islandLocked" and update.gate then
		Hud.toast(string.format(Text.locked, numberText(update.gate)), Theme.rose)
	elseif frame and update.stat == frame.stat then
		if event == "power" and update.gain then
			frame.gain.Text = string.format(Text.powerGain, numberText(update.gain))
		elseif event == "powerMilestone" and update.milestone then
			local mark = update.milestone
			local color = Config.TIER_COLORS[Config.tier(mark)]
			Hud.toast(string.format(Text.milestone, numberText(mark)), color)
			Audio.play("level", 0.17, 1.08)
			if not Ui.reduced() then
				Ui.bounce(frame.value)
				celebrate(frame.frame, color)
			end
		elseif
			(event == "dailyBonus" or event == "ringResult")
			and update.gain
			and update.gain > 0
		then
			Hud.toast(string.format(Text.gain, numberText(update.gain)), Theme.crystal)
		end
	end
end

return Power
