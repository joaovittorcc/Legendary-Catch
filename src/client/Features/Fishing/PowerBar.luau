--!strict
-- Power bar on the cast (flag FishingPower). FUNCTIONAL PLACEHOLDER: the visuals belong to the
-- Codex (P3 of docs/PLANO-PESCA-FORCA-ODDS.md), who may restyle or replace this file as long
-- as show/result/hide keep their signatures. The pointer follows SERVER time
-- (workspace:GetServerTimeNow() - aimStart), exactly like the server computes the band.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local PowerBar = {}

local BAND_COLORS: { [string]: Color3 } = {
	red = Color3.fromRGB(235, 80, 90),
	yellow = Color3.fromRGB(255, 205, 80),
	neutral = Color3.fromRGB(70, 82, 110),
	green = Color3.fromRGB(110, 230, 140),
	purple = Color3.fromRGB(190, 110, 255),
}

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local pointer: Frame? = nil
local beat: RBXScriptConnection? = nil
local label: TextLabel? = nil

function PowerBar.hide()
	if beat then
		beat:Disconnect()
		beat = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
	pointer, label = nil, nil
end

-- Shows the bar and starts the pointer at server time `aimStart`.
function PowerBar.show(layout: { FishingConfig.AimSegment }, aimStart: number)
	PowerBar.hide()
	local screen = Instance.new("ScreenGui")
	screen.Name = "PowerBar"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 6
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local holder = Instance.new("Frame")
	holder.Name = "Bar"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.7)
	holder.Size = UDim2.fromScale(0.6, 0.05)
	holder.BackgroundColor3 = Theme.ink
	holder.BorderSizePixel = 0
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(520, 44)
	limit.MinSize = Vector2.new(220, 26)
	limit.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = holder
	local clip = Instance.new("Frame")
	clip.Name = "Clip"
	clip.Size = UDim2.fromScale(1, 1)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Parent = holder
	for _, seg in layout do
		local f = Instance.new("Frame")
		f.Name = seg.band
		f.BorderSizePixel = 0
		f.Position = UDim2.fromScale(seg.from, 0)
		f.Size = UDim2.fromScale(seg.to - seg.from, 1)
		f.BackgroundColor3 = BAND_COLORS[seg.band] or Color3.new(1, 1, 1)
		f.Parent = clip
	end
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Theme.ink
	stroke.Parent = holder

	local p = Instance.new("Frame")
	p.Name = "Pointer"
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.Position = UDim2.fromScale(0, 0.5)
	p.Size = UDim2.new(0, 6, 1.6, 0)
	p.BackgroundColor3 = Color3.new(1, 1, 1)
	p.BorderSizePixel = 0
	p.ZIndex = 3
	p.Parent = holder
	pointer = p

	local text = Instance.new("TextLabel")
	text.Name = "Hint"
	text.AnchorPoint = Vector2.new(0.5, 1)
	text.Position = UDim2.new(0.5, 0, 0, -6)
	text.Size = UDim2.fromScale(1, 1.2)
	text.BackgroundTransparency = 1
	text.Font = Theme.font
	text.TextScaled = true
	text.Text = Strings.powerTap
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeColor3 = Theme.ink
	text.TextStrokeTransparency = 0.2
	text.Parent = holder
	label = text

	holder.Parent = screen
	screen.Parent = player:WaitForChild("PlayerGui")
	gui = screen

	beat = RunService.RenderStepped:Connect(function()
		local ptr = pointer
		if ptr then
			ptr.Position = UDim2.fromScale(
				FishingConfig.aimPosition(Workspace:GetServerTimeNow() - aimStart),
				0.5
			)
		end
	end)
end

-- Freezes the pointer and shows the band word; the bar fades out by itself.
function PowerBar.result(band: string)
	if beat then
		beat:Disconnect()
		beat = nil
	end
	local text = label
	if text then
		text.Text = Strings.powerBand[band] or ""
		text.TextColor3 = BAND_COLORS[band] or Color3.new(1, 1, 1)
	end
	local screen = gui
	task.delay(0.7, function()
		if gui == screen and screen then
			for _, d in screen:GetDescendants() do
				if d:IsA("Frame") then
					TweenService:Create(d, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
						:Play()
				end
			end
			task.delay(0.3, function()
				if gui == screen then
					PowerBar.hide()
				end
			end)
		end
	end)
end

return PowerBar
