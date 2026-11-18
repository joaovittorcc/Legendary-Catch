--!strict
-- Rods: builds the fishing rod Tool from the equipped rod's config (slim blank, gold
-- guides, small reel, glowing tip in the style of the reference video) and runs the
-- workshop shop (buy / equip). The client finds "Tip.LineAttachment" to hang the line.
-- Any part tagged WorkshopSpot gets the "OpenWorkshop" prompt; the shop UI listens to it.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Rods = require(Shared:WaitForChild("Config"):WaitForChild("Rods"))
local Strings = require(Shared:WaitForChild("Strings"))

local Analytics = require(script.Parent:WaitForChild("Analytics"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Progress = require(script.Parent:WaitForChild("Progress"))
local Remotes = require(script.Parent.Parent:WaitForChild("Remotes"))

local ROD_NAME = "Rod"
local WORKSHOP_TAG = "WorkshopSpot"

local Rod = {}
Rod.order = 30

local shopResult: RemoteEvent

local function piece(
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

-- Parts are laid out along the Handle's -Z axis (rod length), then welded to the Handle.
local function attach(handle: BasePart, p: BasePart, offset: CFrame)
	p.CFrame = handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	p.Parent = handle.Parent
end

local function build(rod: Rods.Rod): Tool
	local tool = Instance.new("Tool")
	tool.Name = ROD_NAME
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = Strings.rodName[rod.id] or rod.id
	tool:SetAttribute("RodId", rod.id)
	-- Rod points forward and up out of the right hand.
	tool.Grip = CFrame.new(0, 0, 0.6) * CFrame.Angles(math.rad(-35), 0, 0)

	local gold = Color3.fromRGB(255, 196, 92)

	local handle = piece(
		"Handle",
		Vector3.new(0.32, 0.32, 1.7),
		Color3.fromRGB(176, 128, 82),
		Enum.Material.Wood
	)
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	-- 3D model from ServerStorage.RodModels[rod.id] when it exists (Antigravity, A5).
	-- Convention: model pivot = grip point, rod length along -Z, a BasePart named "Tip"
	-- at the very end. The part-built rod below is the fallback.
	local library = ServerStorage:FindFirstChild("RodModels")
	local template = library and library:FindFirstChild(rod.id)
	if template and template:IsA("Model") then
		local model = template:Clone()
		model:PivotTo(handle.CFrame)
		handle.Transparency = 1
		local tipPart: BasePart? = nil
		for _, d in model:GetDescendants() do
			if d:IsA("LuaSourceContainer") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = false
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.Massless = true
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = d
				weld.Parent = d
				if d.Name == "Tip" then
					tipPart = d
				end
			end
		end
		model.Parent = tool
		if not tipPart then
			-- No marked tip: put one at the far -Z end of the model.
			local cf, size = model:GetBoundingBox()
			local far = handle.CFrame:PointToObjectSpace(cf.Position).Z - size.Z / 2
			local t = piece(
				"Tip",
				Vector3.new(0.15, 0.15, 0.15),
				rod.tipColor,
				Enum.Material.Neon,
				Enum.PartType.Ball
			)
			attach(handle, t, CFrame.new(0, 0, far))
			tipPart = t
		end
		local finalTip = tipPart :: BasePart
		finalTip.Name = "Tip"
		finalTip.Parent = tool
		local lineAttachment = Instance.new("Attachment")
		lineAttachment.Name = "LineAttachment"
		lineAttachment.Parent = finalTip
		local glow = Instance.new("PointLight")
		glow.Name = "TipGlow"
		glow.Color = rod.tipColor
		glow.Brightness = 1.2
		glow.Range = 6
		glow.Parent = finalTip
		return tool
	end

	attach(
		handle,
		piece("ButtCap", Vector3.new(0.38, 0.38, 0.25), rod.color, Enum.Material.Metal),
		CFrame.new(0, 0, 0.95)
	)
	attach(
		handle,
		piece("Ferrule", Vector3.new(0.36, 0.36, 0.18), gold, Enum.Material.Metal),
		CFrame.new(0, 0, -0.9)
	)

	local reel = piece(
		"Reel",
		Vector3.new(0.5, 0.55, 0.55),
		Color3.fromRGB(70, 66, 90),
		Enum.Material.Metal,
		Enum.PartType.Cylinder
	)
	attach(handle, reel, CFrame.new(0, -0.38, -0.2))
	attach(
		handle,
		piece("ReelHandle", Vector3.new(0.08, 0.08, 0.35), gold, Enum.Material.Metal),
		CFrame.new(0.32, -0.38, -0.2)
	)

	-- Tapered blank in three sections.
	local sections = { { 0.24, 2.4 }, { 0.18, 2.4 }, { 0.12, 2.2 } }
	local z = -1
	for i, s in sections do
		local thick, len = s[1], s[2]
		attach(
			handle,
			piece(
				"Blank" .. i,
				Vector3.new(thick, thick, len),
				rod.color,
				Enum.Material.SmoothPlastic
			),
			CFrame.new(0, 0, z - len / 2)
		)
		z -= len
		attach(
			handle,
			piece("Guide" .. i, Vector3.new(0.05, 0.22, 0.05), gold, Enum.Material.Metal),
			CFrame.new(0, 0.16, z + 0.3)
		)
	end

	local tip = piece(
		"Tip",
		Vector3.new(0.2, 0.2, 0.2),
		rod.tipColor,
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	attach(handle, tip, CFrame.new(0, 0, z - 0.05))
	local lineAttachment = Instance.new("Attachment")
	lineAttachment.Name = "LineAttachment"
	lineAttachment.Parent = tip
	local glow = Instance.new("PointLight")
	glow.Name = "TipGlow"
	glow.Color = rod.tipColor
	glow.Brightness = 1.2
	glow.Range = 6
	glow.Parent = tip

	return tool
end

local function currentRod(player: Player): Rods.Rod
	local profile = PlayerData.get(player)
	return (profile and Rods.get(profile.equippedRod)) or (Rods.get(Rods.STARTER) :: Rods.Rod)
end

-- Replaces whatever rod the player carries with the equipped one (keeps it in hand if
-- it was equipped). StarterPack only holds the starter for the very first spawn frame.
local function giveRod(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local character = player.Character
	local wasHeld = false
	local containers: { Instance } = { backpack }
	if character then
		table.insert(containers, character)
	end
	for _, container in containers do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child.Name == ROD_NAME then
					wasHeld = wasHeld or child.Parent == character
					child:Destroy()
				end
			end
		end
	end
	local tool = build(currentRod(player))
	tool.Parent = backpack
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if wasHeld and humanoid then
		humanoid:EquipTool(tool)
	end
end

function Rod.refresh(player: Player)
	giveRod(player)
end

local function reply(player: Player, result: Net.ShopResult)
	shopResult:FireClient(player, result)
end

local function onBuy(player: Player, rodId: unknown)
	if typeof(rodId) ~= "string" then
		return
	end
	local rod = Rods.get(rodId)
	local profile = PlayerData.get(player)
	if not rod or not profile then
		reply(player, { ok = false, action = "buy", rodId = rodId, reason = "unknown" })
		return
	end
	if table.find(profile.rodsOwned, rod.id) then
		reply(player, { ok = false, action = "buy", rodId = rod.id, reason = "owned" })
		return
	end
	if not PlayerData.trySpend(player, rod.price) then
		reply(player, { ok = false, action = "buy", rodId = rod.id, reason = "noCoins" })
		return
	end
	PlayerData.update(player, function(p)
		table.insert(p.rodsOwned, rod.id)
		p.equippedRod = rod.id
	end)
	giveRod(player)
	Analytics.coins(player, false, rod.price, "Rod", rod.id)
	Analytics.step(player, "firstRodBought")
	Progress.onRodBought(player)
	reply(player, { ok = true, action = "buy", rodId = rod.id })
end

local function onEquip(player: Player, rodId: unknown)
	if typeof(rodId) ~= "string" then
		return
	end
	local profile = PlayerData.get(player)
	if not profile or not Rods.get(rodId) then
		reply(player, { ok = false, action = "equip", rodId = tostring(rodId), reason = "unknown" })
		return
	end
	if not table.find(profile.rodsOwned, rodId) then
		reply(player, { ok = false, action = "equip", rodId = rodId, reason = "notOwned" })
		return
	end
	PlayerData.update(player, function(p)
		p.equippedRod = rodId
	end)
	giveRod(player)
	reply(player, { ok = true, action = "equip", rodId = rodId })
end

local function addWorkshopPrompt(spot: Instance)
	if not spot:IsA("BasePart") or spot:FindFirstChild("OpenWorkshop") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenWorkshop"
	prompt.ActionText = Strings.openWorkshop
	prompt.ObjectText = Strings.workshop
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = spot
end

function Rod.start()
	shopResult = Remotes.event(Net.SHOP_RESULT)
	Remotes.onServerEvent(Net.BUY_ROD, 2, 4, onBuy)
	Remotes.onServerEvent(Net.EQUIP_ROD, 2, 4, onEquip)

	-- Every spawn gets the equipped rod (StarterPack stays empty so there's never a duplicate).
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			PlayerData.wait(player)
			giveRod(player)
		end)
		if player.Character then
			task.spawn(function()
				PlayerData.wait(player)
				giveRod(player)
			end)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

	-- The workshop preview (client) reads rod models from ReplicatedStorage.RodPreviews.
	local library = ServerStorage:FindFirstChild("RodModels")
	if library then
		local previews = ReplicatedStorage:FindFirstChild("RodPreviews") or Instance.new("Folder")
		previews.Name = "RodPreviews"
		for _, model in library:GetChildren() do
			if model:IsA("Model") and not previews:FindFirstChild(model.Name) then
				local copy = model:Clone()
				for _, d in copy:GetDescendants() do
					if d:IsA("LuaSourceContainer") then
						d:Destroy()
					elseif d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = false
						d.CanQuery = false
						d.CanTouch = false
					end
				end
				copy.Parent = previews
			end
		end
		previews.Parent = ReplicatedStorage
	end

	for _, spot in CollectionService:GetTagged(WORKSHOP_TAG) do
		addWorkshopPrompt(spot)
	end
	CollectionService:GetInstanceAddedSignal(WORKSHOP_TAG):Connect(addWorkshopPrompt)
end

return Rod
