--!strict
-- Server trophy: the best catch on this server (rarity, then shiny, then weight) is shown
-- on the plaza pedestal (part tagged TrophyPedestal) with a sign naming who caught it.
-- The pedestal part also carries attributes (TrophyCreature, TrophyPlayer, TrophyWeight,
-- TrophyVariant) so the client can restyle or localize the display.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Creatures = require(Shared:WaitForChild("Config"):WaitForChild("Creatures"))
local FishingConfig = require(Shared:WaitForChild("Config"):WaitForChild("Fishing"))
local Strings = require(Shared:WaitForChild("Strings"))

local TAG = "TrophyPedestal"
local DISPLAY_SIZE = 5

local Trophy = {}
Trophy.order = 65

type Best = { creature: Creatures.Creature, weight: number, shiny: boolean, playerName: string }

local best: Best? = nil

local function score(creature: Creatures.Creature, weight: number, shiny: boolean): number
	local rank = table.find(FishingConfig.RARITY_ORDER, creature.rarity) or 1
	-- Rarity dominates, shiny breaks ties, weight (relative to the species range) last.
	local span = math.max(creature.weightMax - creature.weightMin, 0.001)
	local relative = math.clamp((weight - creature.weightMin) / span, 0, 1)
	return rank * 10 + (if shiny then 5 else 0) + relative
end

local function render(pedestal: BasePart)
	local old = pedestal:FindFirstChild("TrophyDisplay")
	if old then
		old:Destroy()
	end
	local b = best
	if not b then
		return
	end
	local library = ReplicatedStorage:FindFirstChild(Creatures.MODELS_FOLDER)
	local template = library and library:FindFirstChild(b.creature.id)
	local holder = Instance.new("Model")
	holder.Name = "TrophyDisplay"
	if template and template:IsA("Model") then
		local model = template:Clone()
		local _, size = model:GetBoundingBox()
		model:ScaleTo(model:GetScale() * DISPLAY_SIZE / math.max(size.X, size.Y, size.Z, 0.1))
		local _, scaled = model:GetBoundingBox()
		model:PivotTo(pedestal.CFrame * CFrame.new(0, pedestal.Size.Y / 2 + scaled.Y / 2 + 0.3, 0))
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		model.Parent = holder
	end

	local sign = Instance.new("BillboardGui")
	sign.Name = "TrophySign"
	sign.Size = UDim2.fromOffset(260, 70)
	sign.StudsOffsetWorldSpace = Vector3.new(0, pedestal.Size.Y / 2 + DISPLAY_SIZE + 1.5, 0)
	sign.MaxDistance = 80
	sign.Adornee = pedestal
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = FishingConfig.RARITY_COLORS[b.creature.rarity] or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	local name = Strings.creatureName[b.creature.id] or b.creature.id
	label.Text = `{if b.shiny then "✦ " else ""}{name}\n{b.playerName} · {string.format(
		"%.1f",
		b.weight
	)} kg`
	label.Parent = sign
	sign.Parent = holder

	holder.Parent = pedestal
	pedestal:SetAttribute("TrophyCreature", b.creature.id)
	pedestal:SetAttribute("TrophyPlayer", b.playerName)
	pedestal:SetAttribute("TrophyWeight", b.weight)
	pedestal:SetAttribute("TrophyVariant", if b.shiny then "Shiny" else "")
end

local function renderAll()
	for _, p in CollectionService:GetTagged(TAG) do
		if p:IsA("BasePart") then
			render(p)
		end
	end
end

-- Called by Fishing after every paid catch.
function Trophy.onCatch(
	player: Player,
	creature: Creatures.Creature,
	weight: number,
	shiny: boolean
)
	local current = best
	if
		current
		and score(creature, weight, shiny)
			<= score(current.creature, current.weight, current.shiny)
	then
		return
	end
	best = { creature = creature, weight = weight, shiny = shiny, playerName = player.DisplayName }
	renderAll()
end

function Trophy.start()
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(p)
		if p:IsA("BasePart") then
			render(p)
		end
	end)
end

return Trophy
