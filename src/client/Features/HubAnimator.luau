--!strict
--[[
	HubAnimator.luau
	Suggested Studio path: StarterPlayer/StarterPlayerScripts/Client/Features/HubAnimator
	Rojo path: src/client/Features/HubAnimator.luau

	Integration:
	- Automatically loaded by the client Feature Loader via `order` + `start()`.
	- Animates any map instance tagged via CollectionService with ZERO Scripts inside map models:
	    * HubSpin    -> Attributes: Speed (deg/s), Axis ("X"|"Y"|"Z"), Phase (number)
	    * HubBob     -> Attributes: Amplitude (studs), Speed (rad/s), Phase (number)
	    * HubPulse   -> Attributes: Min (number), Max (number), Speed (rad/s), Target (string: "Transparency"|"Brightness"|"Size"|"Range")
	    * HubFlicker -> Attributes: Intensity (number, 0..1)
	    * HubSway    -> Attributes: Angle (degrees), Speed (rad/s), Phase (number?)
	    * HubWave    -> Attributes: Amplitude (studs), Speed (rad/s), Phase (number)
	- Stores immutable base CFrame / base property values on registration so error NEVER accumulates.
	- Combines multiple transform tags cleanly on the same BasePart or Model in a single Heartbeat.
	- Distance-culls beyond 120 studs from CurrentCamera.
	- Reacts live to Players.LocalPlayer:GetAttribute("ReduceEffects"): reduces amplitudes and stops HubFlicker.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MAX_CULL_DISTANCE = 120
local MAX_CULL_DIST_SQ = MAX_CULL_DISTANCE * MAX_CULL_DISTANCE
local REDUCED_AMPLITUDE_MULT = 0.35

local TAGS = {
	"HubSpin",
	"HubBob",
	"HubPulse",
	"HubFlicker",
	"HubSway",
	"HubWave",
}

type Entry = {
	instance: Instance,
	kind: string, -- "BasePart" | "Model" | "Light" (plain string: luau-lsp 1.70 union bug)
	baseCFrame: CFrame?,
	baseSize: Vector3?,
	baseTransparency: number?,
	baseBrightness: number?,
	baseRange: number?,
	seed: number,
	tags: { [string]: boolean },
	tagCount: number,
}

local HubAnimator = {
	order = 110,
}

local entries: { [Instance]: Entry } = {}
local entryList: { Entry } = {}
local connections: { RBXScriptConnection } = {}
local started = false
local reducedEffects = false
local elapsed = 0
local nextSeed = 1.37

local function numAttr(inst: Instance, name: string, defaultValue: number): number
	local v = inst:GetAttribute(name)
	if typeof(v) == "number" then
		return v
	end
	return defaultValue
end

local function strAttr(inst: Instance, name: string, defaultValue: string): string
	local v = inst:GetAttribute(name)
	if typeof(v) == "string" then
		return v
	end
	return defaultValue
end

local function getEntryPosition(entry: Entry): Vector3?
	if entry.baseCFrame then
		return entry.baseCFrame.Position
	end
	local parent = entry.instance.Parent
	if parent then
		if parent:IsA("BasePart") then
			return parent.Position
		elseif parent:IsA("Attachment") then
			return parent.WorldPosition
		end
	end
	return nil
end

local function restoreBaseState(entry: Entry)
	local inst = entry.instance
	if not inst.Parent then
		return
	end
	if entry.kind == "BasePart" then
		local p = inst :: BasePart
		if entry.baseCFrame then
			p.CFrame = entry.baseCFrame
		end
		if entry.baseSize then
			p.Size = entry.baseSize
		end
		if entry.baseTransparency ~= nil then
			p.Transparency = entry.baseTransparency
		end
	elseif entry.kind == "Model" then
		local m = inst :: Model
		if entry.baseCFrame then
			m:PivotTo(entry.baseCFrame)
		end
	elseif entry.kind == "Light" then
		local l = inst :: Light
		if entry.baseBrightness ~= nil then
			l.Brightness = entry.baseBrightness
		end
		if
			entry.baseRange ~= nil
			and (l:IsA("PointLight") or l:IsA("SpotLight") or l:IsA("SurfaceLight"))
		then
			(l :: PointLight).Range = entry.baseRange
		end
	end
end

local function registerTag(inst: Instance, tagName: string)
	local existing = entries[inst]
	if existing then
		if not existing.tags[tagName] then
			existing.tags[tagName] = true
			existing.tagCount += 1
		end
		return
	end

	local kind: string? = nil
	local baseCf: CFrame? = nil
	local baseSize: Vector3? = nil
	local baseTrans: number? = nil
	local baseBright: number? = nil
	local baseRange: number? = nil

	if inst:IsA("BasePart") then
		kind = "BasePart"
		baseCf = inst.CFrame
		baseSize = inst.Size
		baseTrans = inst.Transparency
	elseif inst:IsA("Model") then
		kind = "Model"
		baseCf = inst:GetPivot()
	elseif inst:IsA("Light") then
		kind = "Light"
		baseBright = inst.Brightness
		if inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
			baseRange = (inst :: PointLight).Range
		end
	else
		return
	end

	nextSeed += 3.713
	local entry: Entry = {
		instance = inst,
		kind = kind :: string,
		baseCFrame = baseCf,
		baseSize = baseSize,
		baseTransparency = baseTrans,
		baseBrightness = baseBright,
		baseRange = baseRange,
		seed = nextSeed,
		tags = { [tagName] = true },
		tagCount = 1,
	}

	entries[inst] = entry
	table.insert(entryList, entry)
end

local function unregisterTag(inst: Instance, tagName: string)
	local entry = entries[inst]
	if not entry or not entry.tags[tagName] then
		return
	end
	entry.tags[tagName] = nil
	entry.tagCount -= 1

	if entry.tagCount <= 0 then
		restoreBaseState(entry)
		entries[inst] = nil
		local idx = table.find(entryList, entry)
		if idx then
			-- O(1) swap-remove
			local last = entryList[#entryList]
			entryList[idx] = last
			entryList[#entryList] = nil
		end
	end
end

local function applyPulse(entry: Entry, t: number, ampMult: number)
	local inst = entry.instance
	local minVal = numAttr(inst, "Min", 0.2)
	local maxVal = numAttr(inst, "Max", 1.0)
	local speed = numAttr(inst, "Speed", 2.0)
	local target =
		strAttr(inst, "Target", if entry.kind == "Light" then "Brightness" else "Transparency")

	local mid = (minVal + maxVal) * 0.5
	local halfSpan = (maxVal - minVal) * 0.5 * ampMult
	local val = mid + math.sin(t * speed + entry.seed) * halfSpan

	if target == "Transparency" and entry.kind == "BasePart" then
		(inst :: BasePart).Transparency = math.clamp(val, 0, 1)
	elseif target == "Brightness" and entry.kind == "Light" then
		(inst :: Light).Brightness = math.max(0, val)
	elseif target == "Range" and entry.kind == "Light" then
		if inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
			(inst :: PointLight).Range = math.max(1, val)
		end
	elseif target == "Size" and entry.kind == "BasePart" and entry.baseSize then
		local scale = math.max(0.05, val)
		local part = inst :: BasePart
		part.Size = entry.baseSize * scale
	end
end

local function applyFlicker(entry: Entry, t: number)
	local inst = entry.instance
	if reducedEffects then
		-- Stop flicker completely in ReduceEffects mode and keep calm base value
		if entry.kind == "Light" and entry.baseBrightness ~= nil then
			(inst :: Light).Brightness = entry.baseBrightness
		elseif entry.kind == "BasePart" and entry.baseTransparency ~= nil then
			(inst :: BasePart).Transparency = entry.baseTransparency
		end
		return
	end

	local intensity = math.clamp(numAttr(inst, "Intensity", 0.25), 0, 1)
	-- Layered smooth noise feels like a cozy flame/lantern without harsh strobing
	local n1 = math.noise(t * 5.2, entry.seed, 0.15)
	local n2 = math.noise(t * 11.4, entry.seed + 4.2, 0.45) * 0.45
	local flicker = math.clamp((n1 + n2) * intensity, -0.5, 0.5)

	if entry.kind == "Light" and entry.baseBrightness ~= nil then
		(inst :: Light).Brightness = math.max(0.05, entry.baseBrightness * (1 + flicker))
	elseif entry.kind == "BasePart" and entry.baseTransparency ~= nil then
		(inst :: BasePart).Transparency =
			math.clamp(entry.baseTransparency - flicker * 0.35, 0, 0.95)
	end
end

local function step(dt: number)
	elapsed += dt

	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	local camPos = cam.CFrame.Position
	local ampMult = if reducedEffects then REDUCED_AMPLITUDE_MULT else 1.0
	local t = elapsed

	for i = #entryList, 1, -1 do
		local entry = entryList[i]
		local inst = entry.instance

		-- Clean up instances destroyed when maps regenerate
		if not inst.Parent then
			entries[inst] = nil
			local last = entryList[#entryList]
			entryList[i] = last
			entryList[#entryList] = nil
			continue
		end

		-- Distance culling (~120 studs from camera)
		local pos = getEntryPosition(entry)
		if pos then
			local diff = pos - camPos
			if diff:Dot(diff) > MAX_CULL_DIST_SQ then
				continue
			end
		end

		local tags = entry.tags

		-- Compose spatial transforms from immutable baseCFrame (never accumulates drift)
		if entry.baseCFrame and (tags.HubSpin or tags.HubBob or tags.HubSway or tags.HubWave) then
			local offsetPos = Vector3.zero
			local rotCf = CFrame.identity

			if tags.HubBob then
				local amp = numAttr(inst, "Amplitude", 0.5) * ampMult
				local spd = numAttr(inst, "Speed", 1.8)
				local phase = numAttr(inst, "Phase", 0)
				offsetPos += Vector3.new(0, math.sin(t * spd + phase) * amp, 0)
			end

			if tags.HubWave then
				local amp = numAttr(inst, "Amplitude", 0.35) * ampMult
				local spd = numAttr(inst, "Speed", 1.6)
				local phase = numAttr(inst, "Phase", 0)
				local w = math.sin(t * spd + phase)
				local wCos = math.cos(t * spd * 0.85 + phase)
				offsetPos += Vector3.new(0, w * amp, 0)
				rotCf *= CFrame.Angles(w * 0.06 * ampMult, 0, wCos * 0.05 * ampMult)
			end

			if tags.HubSpin then
				-- The hub builder writes HubSpin Speed in degrees per second (8..36).
				local spd = math.rad(numAttr(inst, "Speed", 20))
					* (if reducedEffects then 0.5 else 1.0)
				local axis = string.upper(strAttr(inst, "Axis", "Y"))
				local phase = numAttr(inst, "Phase", 0)
				local angle = t * spd + phase
				if axis == "X" then
					rotCf *= CFrame.Angles(angle, 0, 0)
				elseif axis == "Z" then
					rotCf *= CFrame.Angles(0, 0, angle)
				else
					rotCf *= CFrame.Angles(0, angle, 0)
				end
			end

			if tags.HubSway then
				local deg = numAttr(inst, "Angle", 8) * ampMult
				local spd = numAttr(inst, "Speed", 1.5)
				local phase = numAttr(inst, "Phase", entry.seed)
				local swayRad = math.rad(deg) * math.sin(t * spd + phase)
				local swaySide = math.rad(deg * 0.45) * math.cos(t * spd * 0.72 + phase)
				rotCf *= CFrame.Angles(swaySide, 0, swayRad)
			end

			local finalCf = (entry.baseCFrame + offsetPos) * rotCf
			if entry.kind == "BasePart" then
				(inst :: BasePart).CFrame = finalCf
			elseif entry.kind == "Model" then
				(inst :: Model):PivotTo(finalCf)
			end
		end

		if tags.HubPulse then
			applyPulse(entry, t, ampMult)
		end

		if tags.HubFlicker then
			applyFlicker(entry, t)
		end
	end
end

local function refreshReduceEffects()
	local lp = Players.LocalPlayer
	reducedEffects = if lp then (lp:GetAttribute("ReduceEffects") == true) else false
	if reducedEffects then
		for _, entry in ipairs(entryList) do
			if entry.tags.HubFlicker then
				applyFlicker(entry, elapsed)
			end
		end
	end
end

function HubAnimator.start()
	if started then
		return
	end
	started = true

	local lp = Players.LocalPlayer
	if lp then
		reducedEffects = lp:GetAttribute("ReduceEffects") == true
		table.insert(
			connections,
			lp:GetAttributeChangedSignal("ReduceEffects"):Connect(refreshReduceEffects)
		)
	end

	for _, tagName in ipairs(TAGS) do
		for _, inst in ipairs(CollectionService:GetTagged(tagName)) do
			registerTag(inst, tagName)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(tagName):Connect(function(inst: Instance)
				registerTag(inst, tagName)
			end)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(inst: Instance)
				unregisterTag(inst, tagName)
			end)
		)
	end

	table.insert(connections, RunService.Heartbeat:Connect(step))
end

function HubAnimator.stop()
	if not started then
		return
	end
	started = false

	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)

	for _, entry in ipairs(entryList) do
		restoreBaseState(entry)
	end
	table.clear(entries)
	table.clear(entryList)
end

function HubAnimator.getActiveCount(): number
	return #entryList
end

return HubAnimator
