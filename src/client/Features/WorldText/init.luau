--!strict
-- Localizes world text that the server creates once for everyone (in EN): training and
-- workshop ProximityPrompts and the trophy sign. Changes are local to this client, so each
-- player reads them in their own language (Strings picks it from the Roblox locale).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))

local WorldText = { order = 130 }

local function localizePrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	local stat = string.match(prompt.Name, "^Train(%a+)$")
	if stat and Strings.stat[stat] then
		prompt.ActionText = `{Strings.trainAction} {Strings.stat[stat]}`
		prompt.ObjectText = Strings.statHelp[stat] or Strings.trainingSpot
	elseif prompt.Name == "OpenAquarium" then
		prompt.ActionText = Strings.openAquarium
		prompt.ObjectText = Strings.aquarium
	elseif prompt.Name == "OpenWorkshop" then
		prompt.ActionText = Strings.openWorkshop
		prompt.ObjectText = Strings.workshop
	end
end

-- Map signs (Sign_<KEY> > Board > SurfaceGui > TextLabel), built by the island generator in EN.
local function localizeSign(label: Instance)
	if not label:IsA("TextLabel") then
		return
	end
	local gui = label.Parent
	local sign = gui and gui.Parent and gui.Parent.Parent
	local key = sign and string.match(sign.Name, "^Sign_(%w+)$")
	local text = key and Strings.signs[key]
	if text then
		label.Text = text
	end
end

local function localizeTrophy(pedestal: Instance)
	local creatureId = pedestal:GetAttribute("TrophyCreature")
	local display = pedestal:FindFirstChild("TrophyDisplay")
	local sign = display and display:FindFirstChild("TrophySign", true)
	local label = sign and sign:FindFirstChildOfClass("TextLabel")
	if typeof(creatureId) ~= "string" or not label then
		return
	end
	local who = pedestal:GetAttribute("TrophyPlayer")
	local weight = pedestal:GetAttribute("TrophyWeight")
	local shiny = pedestal:GetAttribute("TrophyVariant") == "Shiny"
	label.Text =
		`{if shiny then "✦ " else ""}{Strings.creatureName[creatureId] or creatureId}\n{if typeof(
				who
			) == "string"
			then who
			else ""} · {string.format("%.1f", if typeof(weight) == "number" then weight else 0)} kg`
end

local function watchPedestal(pedestal: Instance)
	localizeTrophy(pedestal)
	pedestal:GetAttributeChangedSignal("TrophyCreature"):Connect(function()
		-- The server rebuilds the display right after the attribute; wait for it.
		task.defer(localizeTrophy, pedestal)
	end)
	pedestal.ChildAdded:Connect(function()
		task.defer(localizeTrophy, pedestal)
	end)
end

function WorldText.start()
	for _, d in Workspace:GetDescendants() do
		localizePrompt(d)
		localizeSign(d)
	end
	Workspace.DescendantAdded:Connect(function(d)
		localizePrompt(d)
		localizeSign(d)
	end)
	for _, p in CollectionService:GetTagged("TrophyPedestal") do
		watchPedestal(p)
	end
	CollectionService:GetInstanceAddedSignal("TrophyPedestal"):Connect(watchPedestal)
end

return WorldText
