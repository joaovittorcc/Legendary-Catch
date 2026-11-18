--!strict
-- Fishing controller (client): rod input, cast visuals, minigame and reveal. The server
-- decides everything that matters (spot, bite, creature, result); this side only plays it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Net = require(Shared:WaitForChild("Net"))
local Products = require(Shared:WaitForChild("Config"):WaitForChild("Products"))
local Strings = require(Shared:WaitForChild("Strings"))
local StringsUi = require(Shared:WaitForChild("StringsUi"))

local FishingCamera = require(script:WaitForChild("Camera"))
local Line = require(script:WaitForChild("Line"))
local Omen = require(script:WaitForChild("Omen"))
local PressInput = require(script:WaitForChild("PressInput"))
local Reveal = require(script:WaitForChild("Reveal"))
local Ui = require(script:WaitForChild("Ui"))
local Minigames = script:WaitForChild("Minigames")

type Minigame = { run: (Frame, number, Color3, (boolean) -> ()) -> () -> () }

local MINIGAMES: { [string]: Minigame } = {
	reel = require(Minigames:WaitForChild("Reel")) :: Minigame,
	precision = require(Minigames:WaitForChild("Precision")) :: Minigame,
	rhythm = require(Minigames:WaitForChild("Rhythm")) :: Minigame,
}

local ROD_NAME = "Rod"

local Fishing = {}
-- Starts before Training: it creates the shared HUD (Ui.init).
Fishing.order = 20

local player = Players.LocalPlayer
local remotes: Folder
local castRemote: RemoteEvent
local cancelRemote: RemoteEvent
local submitRemote: RemoteEvent
local perfectRemote: RemoteEvent
local pendingPerfect = false

local state: string = "idle" -- "idle" | "casting" | "waiting" | "fighting" | "resolving" | "revealing"
local castId = 0
local line: Line.Line? = nil
local stopMinigame: (() -> ())? = nil
local savedWalk: number? = nil
local savedJump: number? = nil

local function currentState(): string
	return state
end

local function humanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function rootPart(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function equippedRod(): Tool?
	local character = player.Character
	local tool = character and character:FindFirstChild(ROD_NAME)
	return if tool and tool:IsA("Tool") then tool else nil
end

-- Keeps the player still during the fight so presses don't walk or jump.
local function freeze(on: boolean)
	local h = humanoid()
	if not h then
		return
	end
	if on then
		savedWalk, savedJump = h.WalkSpeed, h.JumpHeight
		h.WalkSpeed, h.JumpHeight = 0, 0
	elseif savedWalk then
		h.WalkSpeed, h.JumpHeight = savedWalk, savedJump or 7.2
		savedWalk, savedJump = nil, nil
	end
end

local function zoomCamera(fov: number)
	local camera = Workspace.CurrentCamera
	if camera then
		TweenService
			:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { FieldOfView = fov })
			:Play()
	end
end

local function cleanup()
	local stop = stopMinigame
	stopMinigame = nil
	if stop then
		stop()
	end
	PressInput.disable()
	Ui.hidePanel()
	freeze(false)
	FishingCamera.stop()
	Omen.stop()
	zoomCamera(70)
	local l = line
	line = nil
	if l then
		Line.destroy(l)
	end
	state = "idle"
end

local function playCastSwing(tool: Tool)
	-- The default Animate script plays the tool slash when it sees this value.
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
end

local function onActivated()
	if player:GetAttribute(Products.AUTO_FISH_ACTIVE_ATTRIBUTE) == true then
		return
	end
	local tool = equippedRod()
	local root = rootPart()
	if state ~= "idle" or not tool or not root then
		return
	end
	state = "casting"
	playCastSwing(tool)
	castRemote:FireServer()
end

local function startCast(id: number)
	local tool = equippedRod()
	local root = rootPart()
	local tip = tool and tool:FindFirstChild("Tip")
	local attachment = tip and tip:FindFirstChild("LineAttachment")
	if not (root and attachment and attachment:IsA("Attachment")) then
		cancelRemote:FireServer()
		cleanup()
		return
	end
	castId = id
	state = "waiting"
	local l = Line.create(attachment)
	line = l
	FishingCamera.start(root, l.bobber)
	local flat = (root.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
	Line.castTo(l, root.Position + flat * FishingConfig.CAST_DISTANCE)
	Ui.toast(Strings.waiting)
end

local function startFight(update: Net.FishingUpdate)
	local l = line
	if state ~= "waiting" or not l then
		return
	end
	local rarity = update.rarity or "Common"
	local kind = update.kind or "reel"
	local tier = update.tier or 1
	local color = FishingConfig.RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
	local minigame = MINIGAMES[kind] or MINIGAMES.reel

	state = "fighting"
	Line.bite(l, color)
	FishingCamera.fight()
	if rarity == "Legendary" or rarity == "Mystic" then
		Omen.start()
	end
	freeze(true)
	zoomCamera(70) -- no zoom-in: the fight shots already sit closer to the action
	PressInput.enable()
	local area = Ui.showPanel(Strings.hint[rarity] or "", color, Strings.instructions[kind] or "")
	local id = castId
	-- Minigames call done(success, perfect?); perfect = finished without a single mistake.
	local done: any = function(success: boolean, perfect: boolean?)
		-- Read through a function: the checker keeps the narrowed "waiting" type in closures.
		if currentState() ~= "fighting" or castId ~= id then
			return
		end
		state = "resolving"
		stopMinigame = nil
		pendingPerfect = success and perfect == true
		PressInput.disable()
		Ui.hidePanel()
		submitRemote:FireServer(id, success)
	end
	stopMinigame = minigame.run(area, tier, color, done)
end

local function onCaught(update: Net.FishingUpdate)
	local l = line
	local root = rootPart()
	local creatureId = update.creatureId
	if not (l and root and creatureId) then
		cleanup()
		return
	end
	state = "revealing"
	if pendingPerfect then
		pendingPerfect = false
		perfectRemote:FireServer(update.castId)
	end
	-- The server's word wins: close any minigame still on screen before the reveal.
	local stop = stopMinigame
	stopMinigame = nil
	if stop then
		stop()
	end
	PressInput.disable()
	Ui.hidePanel()
	Omen.stop()
	local creature = Creatures.get(creatureId)
	local rarity = if creature then creature.rarity else "Common"
	local origin = l.rest
	-- Legendaries run their own cinematic; the rest watch the fish fly in over the shoulder.
	if rarity == "Legendary" or rarity == "Mystic" then
		FishingCamera.stop()
	else
		FishingCamera.catch(origin)
	end
	Line.reelIn(l, 0.3)
	-- 5th arg: the whole "caught" payload (weight, value, isNew, count) for the reveal card.
	local play: any = Reveal.play
	play(creatureId, rarity, origin, root, update)
	cleanup()
end

local function onEscaped()
	local l = line
	if l then
		Line.snap(l)
	end
	Ui.toast(Strings.escaped, Color3.fromRGB(255, 120, 120))
	task.wait(0.6)
	cleanup()
end

local function onUpdate(update: Net.FishingUpdate)
	if update.auto then
		if update.event == "caught" then
			Ui.toast(
				string.format(StringsUi.autoFish.caughtCoins, update.value or 0),
				Color3.fromRGB(130, 245, 170)
			)
		elseif update.event == "escaped" then
			Ui.toast(StringsUi.autoFish.escaped, Color3.fromRGB(255, 195, 120))
		elseif update.event == "rejected" then
			local message = if update.reason == "training"
				then StringsUi.autoFish.trainingStop
				elseif update.reason == "moved" then StringsUi.autoFish.movedStop
				elseif update.reason == "notInZone" then Strings.notInZone
				else Strings.loading
			Ui.toast(message, Color3.fromRGB(255, 220, 120))
		end
		return
	end
	if update.event == "rejected" then
		state = "idle"
		local message = if update.reason == "loading" then Strings.loading else Strings.notInZone
		Ui.toast(message, Color3.fromRGB(255, 220, 120))
	elseif update.event == "cast" and state == "casting" then
		startCast(update.castId or 0)
	elseif update.castId ~= castId then
		return
	elseif update.event == "bite" then
		startFight(update)
	elseif update.event == "caught" then
		onCaught(update)
	elseif update.event == "escaped" then
		onEscaped()
	elseif update.event == "cancelled" then
		cleanup()
	end
end

-- Equipping moves the Tool into the character again, so connect once per Tool instance.
local function watchTool(tool: Instance)
	if not tool:IsA("Tool") or tool.Name ~= ROD_NAME or tool:GetAttribute("FishingHooked") then
		return
	end
	tool:SetAttribute("FishingHooked", true)
	tool.Activated:Connect(onActivated)
	tool.Unequipped:Connect(function()
		if state ~= "idle" and state ~= "revealing" then
			cancelRemote:FireServer()
			cleanup()
		end
	end)
end

local function onCharacter(character: Model)
	cleanup()
	for _, child in character:GetChildren() do
		watchTool(child)
	end
	character.ChildAdded:Connect(watchTool)
end

function Fishing.start()
	remotes = ReplicatedStorage:WaitForChild(Net.FOLDER) :: Folder
	castRemote = remotes:WaitForChild(Net.CAST_LINE) :: RemoteEvent
	cancelRemote = remotes:WaitForChild(Net.CANCEL_FISHING) :: RemoteEvent
	submitRemote = remotes:WaitForChild(Net.SUBMIT_CATCH) :: RemoteEvent
	perfectRemote = remotes:WaitForChild(Net.REPORT_PERFECT) :: RemoteEvent
	local updateRemote = remotes:WaitForChild(Net.FISHING_UPDATE) :: RemoteEvent

	Ui.init()
	updateRemote.OnClientEvent:Connect(function(update: Net.FishingUpdate)
		task.spawn(onUpdate, update)
	end)
	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end

return Fishing
