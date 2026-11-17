--!strict
-- Builds the starter fishing rod Tool from parts (style of the reference video: slim dark
-- blank, gold guides, small reel, glowing tip). The client finds "Tip.LineAttachment" to
-- hang the line from.

local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")

local ROD_NAME = "Rod"

local Rod = {}

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

local function build(): Tool
	local tool = Instance.new("Tool")
	tool.Name = ROD_NAME
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Vara de pesca"
	-- Rod points forward and up out of the right hand.
	tool.Grip = CFrame.new(0, 0, 0.6) * CFrame.Angles(math.rad(-35), 0, 0)

	local black = Color3.fromRGB(28, 26, 40)
	local gold = Color3.fromRGB(255, 196, 92)

	local handle = piece(
		"Handle",
		Vector3.new(0.32, 0.32, 1.7),
		Color3.fromRGB(176, 128, 82),
		Enum.Material.Wood
	)
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	attach(
		handle,
		piece("ButtCap", Vector3.new(0.38, 0.38, 0.25), black, Enum.Material.Metal),
		CFrame.new(0, 0, 0.95)
	)
	attach(
		handle,
		piece("Ferrule", Vector3.new(0.36, 0.36, 0.18), gold, Enum.Material.Metal),
		CFrame.new(0, 0, -0.9)
	)

	-- Reel under the grip.
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
			piece("Blank" .. i, Vector3.new(thick, thick, len), black, Enum.Material.SmoothPlastic),
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
		Color3.fromRGB(150, 230, 255),
		Enum.Material.Neon,
		Enum.PartType.Ball
	)
	attach(handle, tip, CFrame.new(0, 0, z - 0.05))
	local lineAttachment = Instance.new("Attachment")
	lineAttachment.Name = "LineAttachment"
	lineAttachment.Parent = tip
	local glow = Instance.new("PointLight")
	glow.Name = "TipGlow"
	glow.Color = tip.Color
	glow.Brightness = 1.2
	glow.Range = 6
	glow.Parent = tip

	return tool
end

local function give(player: Player, template: Tool)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and not backpack:FindFirstChild(ROD_NAME) then
		local character = player.Character
		if not (character and character:FindFirstChild(ROD_NAME)) then
			template:Clone().Parent = backpack
		end
	end
end

function Rod.start()
	local template = build()
	local old = StarterPack:FindFirstChild(ROD_NAME)
	if old then
		old:Destroy()
	end
	template.Parent = StarterPack
	-- Players already in game when the server starts (Studio) don't get StarterPack again.
	for _, player in Players:GetPlayers() do
		give(player, template)
	end
end

return Rod
