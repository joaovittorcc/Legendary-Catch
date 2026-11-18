--!strict
-- Grandpa Hook (Vô Anzol), the guide NPC near the pier (Model tagged GuideNPC with an
-- Attachment named SpeechPoint). When the player is close, a speech bubble follows the
-- tutorial step; after the tutorial it rotates tips, and during an ocean event it hints
-- at rare catches. Client only.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = require(Shared:WaitForChild("Config"):WaitForChild("Events"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local Data = require(script.Parent.Parent:WaitForChild("Data"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local Art = require(script.Parent.Hud:WaitForChild("Art"))
local Panel = require(script.Parent.Hud:WaitForChild("Panel"))

local Guide = { order = 140 }

local TALK_DISTANCE = 26
local WELCOME_DISTANCE = 68
local WELCOME_LINE_SECONDS = 2.6
local TIP_SECONDS = 8

local player = Players.LocalPlayer

local function currentLine(tipIndex: number): string
	local snapshot = Data.get()
	local tutorial = snapshot and snapshot.tutorial
	if tutorial and not tutorial.done and Strings.guideStep[tutorial.step] then
		return Strings.guideStep[tutorial.step]
	end
	local event = ReplicatedStorage:GetAttribute(Events.ACTIVE_ATTRIBUTE)
	if typeof(event) == "string" and event ~= "" and tipIndex % 2 == 0 then
		return Strings.guideEvent
	end
	local tips = Strings.guideTips
	return tips[(tipIndex % #tips) + 1]
end

local function buildBubble(anchor: Attachment): (BillboardGui, TextLabel, Frame)
	local gui = Instance.new("BillboardGui")
	gui.Name = "GuideBubble"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(260, 108)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	gui.MaxDistance = TALK_DISTANCE + 6
	-- Draw over map props (the pier flag post used to cut the bubble in half).
	gui.AlwaysOnTop = true
	gui.Enabled = false

	local frame = Instance.new("Frame")
	frame.Visible = false
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.crystal
	frame.BorderSizePixel = 0
	Art.panel(frame, Theme.crystal)
	frame.Parent = gui

	local icon = Instance.new("Frame")
	icon.Name = "GuideIcon"
	icon.Position = UDim2.fromOffset(10, 9)
	icon.Size = UDim2.fromOffset(38, 38)
	icon.BackgroundColor3 = Theme.cream
	icon.BorderSizePixel = 0
	icon.ZIndex = 2
	Theme.corner(icon, 19)
	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Theme.outline
	iconStroke.Thickness = 2
	iconStroke.Parent = icon
	local glyph = Panel.label(icon, "🎣", 24, Theme.ink)
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.TextScaled = true
	glyph.TextStrokeTransparency = 1
	glyph.ZIndex = 3
	icon.Parent = frame

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -66, 0, 22)
	name.Position = UDim2.fromOffset(56, 8)
	name.BackgroundTransparency = 1
	name.Text = Strings.guideName
	name.Font = Theme.font
	name.TextSize = 16
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Theme.ink
	name.TextStrokeTransparency = 1
	name.ZIndex = 2
	name.Parent = frame

	local line = Instance.new("TextLabel")
	line.Size = UDim2.new(1, -24, 1, -52)
	line.Position = UDim2.fromOffset(12, 48)
	line.BackgroundTransparency = 1
	line.TextWrapped = true
	line.TextScaled = true
	line.Font = Theme.font
	line.TextColor3 = Theme.ink
	line.TextStrokeTransparency = 1
	line.TextXAlignment = Enum.TextXAlignment.Center
	line.TextYAlignment = Enum.TextYAlignment.Center
	line.ZIndex = 2
	line.Parent = frame
	local maxSize = Instance.new("UITextSizeConstraint")
	maxSize.MaxTextSize = 18
	maxSize.Parent = line

	gui.Parent = player:WaitForChild("PlayerGui")
	return gui, line, frame
end

local function attach(npc: Instance)
	local anchor = npc:FindFirstChild("SpeechPoint", true)
	if not (anchor and anchor:IsA("Attachment")) then
		return
	end
	local gui, line, frame = buildBubble(anchor)
	local setBubbleVisible = Hud.bindFishingVisibility(frame, false)
	local playerGui = player:WaitForChild("PlayerGui")
	local tipIndex = 0
	local lastSwap = 0
	local bubbleOpen = false
	local welcomeDone = false
	local welcomeIndex = 0
	local welcomeSwap = 0

	task.spawn(function()
		while gui.Parent and npc.Parent do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local snapshot = Data.get()
			local tutorial = snapshot and snapshot.tutorial
			local tutorialActive = tutorial ~= nil and not tutorial.done
			local arrival = playerGui:FindFirstChild("IslandArrival")
			local busy = arrival ~= nil
				or Hud.panel() ~= ""
				or Hud.isFishingActive()
				or player:GetAttribute("CatchRevealActive") == true

			if tutorialActive and not welcomeDone and #Strings.guideWelcome > 0 then
				if tutorial and tutorial.step ~= "goToPier" then
					welcomeDone = true
				elseif not busy and root and root:IsA("BasePart") then
					local dist = (root.Position - anchor.WorldPosition).Magnitude
					if dist <= WELCOME_DISTANCE then
						if welcomeIndex == 0 then
							welcomeIndex = 1
							welcomeSwap = os.clock()
							line.Text = Strings.guideWelcome[1]
							bubbleOpen = true
							gui.MaxDistance = WELCOME_DISTANCE + 8
							gui.Size = UDim2.fromOffset(260, 108)
							setBubbleVisible(true)
							gui.Enabled = true
						elseif os.clock() - welcomeSwap >= WELCOME_LINE_SECONDS then
							welcomeIndex += 1
							if welcomeIndex <= #Strings.guideWelcome then
								welcomeSwap = os.clock()
								line.Text = Strings.guideWelcome[welcomeIndex]
							else
								welcomeDone = true
								gui.MaxDistance = TALK_DISTANCE + 6
								bubbleOpen = false
								setBubbleVisible(false)
								gui.Enabled = false
							end
						end
						task.wait(0.35)
						continue
					end
				end
			end

			local near = not busy
				and not tutorialActive
				and root
				and root:IsA("BasePart")
				and (root.Position - anchor.WorldPosition).Magnitude <= TALK_DISTANCE
			if near then
				gui.MaxDistance = TALK_DISTANCE + 6
				if not bubbleOpen then
					-- Just walked up: say the current line with a little pop.
					line.Text = currentLine(tipIndex)
					lastSwap = os.clock()
					bubbleOpen = true
					setBubbleVisible(true)
					gui.Enabled = true
					gui.Size = UDim2.fromOffset(260, 108)
				elseif os.clock() - lastSwap >= TIP_SECONDS then
					tipIndex += 1
					line.Text = currentLine(tipIndex)
					lastSwap = os.clock()
				end
			elseif bubbleOpen then
				bubbleOpen = false
				setBubbleVisible(false)
				task.delay(0.2, function()
					if not bubbleOpen and gui.Parent then
						gui.Enabled = false
					end
				end)
			end
			task.wait(0.5)
		end
		gui:Destroy()
	end)
end

function Guide.start()
	for _, npc in CollectionService:GetTagged("GuideNPC") do
		attach(npc)
	end
	CollectionService:GetInstanceAddedSignal("GuideNPC"):Connect(function(npc)
		-- The SpeechPoint can stream in a moment after the model.
		task.wait(1)
		attach(npc)
	end)
end

return Guide
