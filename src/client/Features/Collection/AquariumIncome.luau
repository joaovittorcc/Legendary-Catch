--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Text = require(Shared:WaitForChild("StringsUi"))
local Theme = require(Shared:WaitForChild("UiTheme"))
local Copy = Text.aquariumPreview
local isPortuguese = Copy == Text.forLocale("pt").aquariumPreview

local Income = {}
local textColors: { [string]: Color3 } = {
	Common = Color3.fromRGB(255, 255, 255),
	Uncommon = Color3.fromRGB(148, 255, 147),
	Rare = Color3.fromRGB(141, 204, 255),
	Epic = Color3.fromRGB(217, 174, 255),
	Legendary = Color3.fromRGB(255, 222, 128),
}

function Income.rate(cents: number): string
	local amount = string.format("%.2f", cents / 100)
	if isPortuguese then
		amount = string.gsub(amount, "%.", ",")
	end
	return string.format(Copy.rate, amount)
end

function Income.signed(cents: number): string
	return (if cents < 0 then "−" elseif cents > 0 then "+" else "")
		.. Income.rate(math.abs(cents))
end

function Income.badge(cents: number, rarity: string): Frame
	local background = Instance.new("Frame")
	background.Name = "IncomeBadge"
	background.BackgroundColor3 = Theme.ink
	background.BackgroundTransparency = 0.1
	background.BorderSizePixel = 0
	background.ZIndex = 3
	Theme.corner(background, 10)
	local outline = Instance.new("UIStroke")
	outline.Color = Theme.outline
	outline.Parent = background

	local text = Instance.new("TextLabel")
	text.Name = "EffectiveRate"
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, -8, 1, 0)
	text.Position = UDim2.fromOffset(4, 0)
	text.Font = Theme.font
	text.Text = Income.signed(cents)
	text.TextSize = 14
	text.TextColor3 = textColors[rarity] or Color3.new(1, 1, 1)
	text.TextStrokeColor3 = Theme.ink
	text.TextStrokeTransparency = 0.4
	text.ZIndex = 4
	if rarity == "Mystic" then
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 152, 203)),
			ColorSequenceKeypoint.new(0.28, Color3.fromRGB(255, 224, 128)),
			ColorSequenceKeypoint.new(0.53, Color3.fromRGB(145, 255, 191)),
			ColorSequenceKeypoint.new(0.76, Color3.fromRGB(157, 222, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(224, 184, 255)),
		})
		gradient.Parent = text
	end
	text.Parent = background
	return background
end

export type WorldEntry = {
	anchor: Attachment,
	rarity: string,
	cpm: number,
}

local BADGE_WIDTH = 136
local BADGE_HEIGHT = 32

function Income.mountWorld(
	playerGui: PlayerGui,
	entries: { WorldEntry },
	maxDistance: number,
	getFocus: () -> Attachment?
): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "AquariumRates"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local labels = {}
	for _, entry in entries do
		local badge = Income.badge(entry.cpm, entry.rarity)
		badge.AnchorPoint = Vector2.new(0.5, 1)
		badge.Size = UDim2.fromOffset(BADGE_WIDTH, BADGE_HEIGHT)
		badge.Visible = false
		local text = badge:FindFirstChildWhichIsA("TextLabel")
		table.insert(labels, {
			anchor = entry.anchor,
			badge = badge,
			gradient = text and text:FindFirstChildWhichIsA("UIGradient"),
			point = Vector2.zero,
			distance = math.huge,
			focused = false,
		})
		badge.Parent = gui
	end

	local visible: { Vector2 } = {}
	local connection = RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		local focus = getFocus()
		local reduced = Players.LocalPlayer:GetAttribute("ReduceEffects") == true
		for _, label in labels do
			label.distance = math.huge
			label.focused = false
			if camera and gui.Enabled and label.anchor:IsDescendantOf(Workspace) then
				local world = label.anchor.WorldPosition
				local point, onScreen = camera:WorldToViewportPoint(world)
				local distance = (world - camera.CFrame.Position).Magnitude
				local halfWidth = BADGE_WIDTH / 2
				if
					onScreen
					and distance <= maxDistance
					and point.Y >= BADGE_HEIGHT
					and point.X >= halfWidth
					and point.X <= camera.ViewportSize.X - halfWidth
				then
					label.point = Vector2.new(point.X, point.Y)
					label.distance = distance
					label.focused = label.anchor == focus
				end
			end
		end
		table.sort(labels, function(a, b)
			if a.focused ~= b.focused then
				return a.focused
			end
			return a.distance < b.distance
		end)
		table.clear(visible)
		for _, label in labels do
			local show = label.distance < math.huge
			if show then
				for _, point in visible do
					if
						math.abs(label.point.X - point.X) < BADGE_WIDTH + 4
						and math.abs(label.point.Y - point.Y) < BADGE_HEIGHT + 4
					then
						show = false
						break
					end
				end
			end
			label.badge.Visible = show
			if show then
				table.insert(visible, label.point)
				label.badge.Position = UDim2.fromOffset(label.point.X, label.point.Y)
				local gradient = label.gradient
				if gradient then
					gradient.Offset =
						Vector2.new(if reduced then 0 else math.sin(os.clock() * 1.4) * 0.18, 0)
				end
			end
		end
	end)
	gui.Destroying:Once(function()
		connection:Disconnect()
	end)
	gui.Parent = playerGui
	return gui
end

return Income
