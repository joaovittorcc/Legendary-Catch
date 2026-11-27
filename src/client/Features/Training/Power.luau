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
	milestone: TextLabel,
	lastPower: number?,
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
	return (string.format("%g", value):gsub("%.", Strings.decimalSep))
end

local function integerText(value: number): string
	local sep = Strings.thousandsSep
	local reversed = string.format("%.0f", value):reverse():gsub("(%d%d%d)", "%1" .. sep)
	if reversed:sub(-#sep) == sep then
		reversed = reversed:sub(1, -#sep - 1)
	end
	return reversed:reverse()
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
	local button = Panel.button(parent, Text.field, Theme.crystal)
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

function Power.mount(frame: Frame, activeStat: string, island: number)
	local value = Instance.new("TextButton")
	value.Name = "FishingPower"
	value.BackgroundTransparency = 1
	value.Size = UDim2.new(0.92, 0, 0, 44)
	value.Position = UDim2.fromScale(0.04, 0)
	value.Font = Theme.font
	value.TextColor3 = Theme.cream
	value.AutoButtonColor = false
	value.Parent = frame
	fitText(value, 26)
	local gain = Ui.label(
		frame,
		"PowerGain",
		UDim2.new(0.92, 0, 0, 15),
		UDim2.new(0.04, 0, 0, 41),
		"",
		Theme.ink
	)
	gain.TextStrokeTransparency = 1
	local multipliers = Ui.label(
		frame,
		"Multipliers",
		UDim2.new(0.92, 0, 0, 17),
		UDim2.new(0.04, 0, 0, 57),
		"",
		Theme.ink
	)
	multipliers.TextStrokeTransparency = 1
	local milestone = Ui.label(
		frame,
		"PowerMilestone",
		UDim2.new(0.92, 0, 0, 20),
		UDim2.new(0.04, 0, 0, 170),
		"",
		Theme.cream
	)
	milestone.Visible = false
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 99, 164)),
		ColorSequenceKeypoint.new(0.24, Color3.fromRGB(255, 213, 82)),
		ColorSequenceKeypoint.new(0.52, Color3.fromRGB(117, 252, 185)),
		ColorSequenceKeypoint.new(0.76, Color3.fromRGB(93, 212, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(218, 133, 255)),
	})
	gradient.Enabled = false
	gradient.Parent = value

	local rows: { [string]: { caption: TextLabel, fill: Frame } } = {}
	for index, stat in Config.STATS do
		local x = if index == 1 then 0.04 else 0.51
		local color = if stat == "Control" then Theme.crystal else Color3.fromRGB(199, 144, 255)
		local caption =
			Ui.label(frame, stat, UDim2.new(0.44, 0, 0, 20), UDim2.new(x, 0, 0, 77), "", Theme.ink)
		caption.TextStrokeTransparency = 1
		local track = Ui.frame(
			frame,
			stat .. "Track",
			UDim2.new(0.44, 0, 0, 8),
			UDim2.new(x, 0, 0, 99),
			Theme.outline
		)
		Theme.corner(track, 5)
		local fill = Ui.frame(track, "Fill", UDim2.fromScale(0, 1), UDim2.fromScale(0, 0), color)
		Theme.corner(fill, 5)
		rows[stat] = { caption = caption, fill = fill }
	end

	local instance: PowerHud =
		{ frame = frame, stat = activeStat, value = value, gain = gain, milestone = milestone }
	hud = instance
	local full = false
	local shown = math.log10(totalPower())
	local delta = 0
	local lastTier = 0
	local function draw(dt: number)
		local target = totalPower()
		local quiet = Ui.reduced()
		shown += (math.log10(target) - shown) * (if quiet then 1 else 1 - math.exp(-dt * 12))
		local visible = if math.abs(shown - math.log10(target)) < 0.0003 then target else 10 ^ shown
		local tier = Config.tier(target)
		local color = Config.TIER_COLORS[tier]
		value.Text = Text.title
			.. "  ·  "
			.. (if full then integerText(target) else numberText(visible))
		value.TextColor3 = Theme.ink:Lerp(color, if tier == 1 then 0 else 0.53)
		if tier ~= lastTier then
			lastTier = tier
			gradient.Color = if tier == 7
				then ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 99, 164)),
					ColorSequenceKeypoint.new(0.24, Color3.fromRGB(255, 213, 82)),
					ColorSequenceKeypoint.new(0.52, Color3.fromRGB(117, 252, 185)),
					ColorSequenceKeypoint.new(0.76, Color3.fromRGB(93, 212, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(218, 133, 255)),
				})
				else ColorSequence.new(
					Color3.new(1, 1, 1),
					if tier == 5 then Theme.rose else Theme.crystal
				)
		end
		gradient.Enabled = tier >= 4 and not quiet
		gradient.Rotation = if gradient.Enabled then (os.clock() * 52) % 360 else 0
		for stat, row in rows do
			local pp = powerOf(stat)
			row.caption.Text = (Strings.stat[stat] or stat) .. "  ·  " .. numberText(pp)
			row.fill.Size = UDim2.fromScale(Config.progress(pp), 1)
		end
		local level = fieldLevel()
		local data = Data.get()
		local prestige = if data then data.prestige else 0
		multipliers.Text = string.format(
			Text.multipliers,
			multiplierText(Config.FIELD[level].mult),
			multiplierText(Config.ISLANDS[island].mult),
			multiplierText(1 + Config.PRESTIGE_GAIN_STEP * prestige)
		)
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

function Power.start(buy: RemoteEvent)
	local _, body = Panel.create(FIELD_PANEL, Text.fieldTitle, Theme.crystal, 0.96, 530)
	Panel.stack(body)
	local current = Panel.label(body, "", 19)
	current.TextStrokeTransparency = 1
	local nextLevel = Panel.label(body, "", 18)
	nextLevel.TextStrokeTransparency = 1
	local preview = Instance.new("ViewportFrame")
	preview.Name = "NextField"
	preview.Size = UDim2.new(1, 0, 0, 135)
	preview.BackgroundColor3 = Theme.outline
	preview.Ambient = Theme.sand
	preview.LightColor = Theme.cream
	Theme.corner(preview, 12)
	preview.Parent = body
	local requirement = Panel.label(body, "", 16)
	requirement.TextStrokeTransparency = 1
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
		local allowed, reason =
			Config.canBuyField(level, totalPower(), if profile then profile.coins else 0)
		current.Text =
			string.format(Text.fieldLevel, level, multiplierText(Config.FIELD[level].mult))
		nextLevel.Text = if nextDef
			then string.format(Text.nextLevel, level + 1, multiplierText(nextDef.mult))
			else Text.max
		if shownPreview ~= (if nextDef then level + 1 else level) then
			shownPreview = if nextDef then level + 1 else level
			previewField(preview, shownPreview)
		end
		requirement.Visible = nextDef ~= nil
		requirement.Text = if nextDef
			then string.format(
				Text.requirements,
				integerText(nextDef.cost),
				numberText(nextDef.gate)
			)
			else ""
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
			frame.lastPower = mark
			frame.milestone.Text = string.format(Text.milestone, numberText(mark))
			frame.milestone.TextColor3 = Config.TIER_COLORS[Config.tier(mark)]
			frame.milestone.Visible = true
			Audio.play("level", 0.17, 1.08)
			if not Ui.reduced() then
				Ui.bounce(frame.value)
				celebrate(frame.frame, frame.milestone.TextColor3)
			end
			task.delay(1.7, function()
				if hud == frame and frame.lastPower == mark then
					frame.milestone.Visible = false
				end
			end)
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
