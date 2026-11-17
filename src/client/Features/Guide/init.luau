--!strict
-- Grandpa Hook (Vô Anzol), the guide NPC near the pier (Model tagged GuideNPC with an
-- Attachment named SpeechPoint). When the player is close, a speech bubble follows the
-- tutorial step; after the tutorial it rotates tips, and during an ocean event it hints
-- at rare catches. Client only.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Events = require(Shared:WaitForChild("Config"):WaitForChild("Events"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("UiTheme"))

local Data = require(script.Parent.Parent:WaitForChild("Data"))

local Guide = { order = 140 }

local TALK_DISTANCE = 26
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

local function buildBubble(anchor: Attachment): (BillboardGui, TextLabel)
	local gui = Instance.new("BillboardGui")
	gui.Name = "GuideBubble"
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(240, 92)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	gui.MaxDistance = TALK_DISTANCE + 6
	gui.Enabled = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.ink
	frame.BackgroundTransparency = 0.1
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.gold
	stroke.Thickness = 2
	stroke.Parent = frame

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -16, 0, 20)
	name.Position = UDim2.fromOffset(8, 4)
	name.BackgroundTransparency = 1
	name.Text = Strings.guideName
	name.Font = Theme.font
	name.TextSize = 16
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Theme.gold
	name.Parent = frame

	local line = Instance.new("TextLabel")
	line.Size = UDim2.new(1, -16, 1, -30)
	line.Position = UDim2.fromOffset(8, 26)
	line.BackgroundTransparency = 1
	line.TextWrapped = true
	line.TextScaled = true
	line.Font = Theme.font
	line.TextColor3 = Theme.sand
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.TextYAlignment = Enum.TextYAlignment.Top
	line.Parent = frame
	local maxSize = Instance.new("UITextSizeConstraint")
	maxSize.MaxTextSize = 18
	maxSize.Parent = line

	gui.Parent = player:WaitForChild("PlayerGui")
	return gui, line
end

local function attach(npc: Instance)
	local anchor = npc:FindFirstChild("SpeechPoint", true)
	if not (anchor and anchor:IsA("Attachment")) then
		return
	end
	local gui, line = buildBubble(anchor)
	local tipIndex = 0
	local lastSwap = 0
	task.spawn(function()
		while gui.Parent and npc.Parent do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local near = root
				and root:IsA("BasePart")
				and (root.Position - anchor.WorldPosition).Magnitude <= TALK_DISTANCE
			if near then
				if not gui.Enabled then
					-- Just walked up: say the current line with a little pop.
					line.Text = currentLine(tipIndex)
					lastSwap = os.clock()
					gui.Enabled = true
					gui.Size = UDim2.fromOffset(200, 76)
					TweenService:Create(gui, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
						Size = UDim2.fromOffset(240, 92),
					}):Play()
				elseif os.clock() - lastSwap >= TIP_SECONDS then
					tipIndex += 1
					line.Text = currentLine(tipIndex)
					lastSwap = os.clock()
				else
					-- Tutorial lines follow the step right away (no waiting for the timer).
					local text = currentLine(tipIndex)
					local snapshot = Data.get()
					if
						snapshot
						and snapshot.tutorial
						and not snapshot.tutorial.done
						and line.Text ~= text
					then
						line.Text = text
					end
				end
			else
				gui.Enabled = false
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
