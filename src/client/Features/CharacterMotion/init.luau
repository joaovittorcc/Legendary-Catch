--!strict
-- Procedural character motion driven in PreSimulation (supporting both AnimationConstraint and Motor6D)
-- reacting to Character attribute `FishingState` ("waiting" / "fighting") and Player attributes
-- `CatchRevealActive` and `ReduceEffects`. Runs cleanly alongside Fishing/Line's Pose.play.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CharacterMotion = {}

type Joint = { Transform: CFrame, Parent: Instance? }

type JointEntry = {
	joint: Joint,
	base: CFrame,
	applied: CFrame?,
	weight: number,
	targetOffset: CFrame,
}

local TRACKED_JOINTS: { [string]: boolean } = {
	Root = true,
	Waist = true,
	Neck = true,
	RightShoulder = true,
	["Right Shoulder"] = true,
	LeftShoulder = true,
	["Left Shoulder"] = true,
	RightElbow = true,
	LeftElbow = true,
}

local function addOffset(offsets: { [string]: CFrame }, name: string, cf: CFrame)
	local prev = offsets[name]
	offsets[name] = if prev then prev * cf else cf
end

-- Computes target joint offsets and whether RightShoulder/Waist should yield
-- to Fishing/Line's short Pose.play windows (cast 0..0.68s, fight, reelIn 0..0.95s).
local function samplePose(
	mode: string,
	t: number,
	reduced: boolean,
	holdingTool: boolean
): ({ [string]: CFrame }, boolean)
	local offsets: { [string]: CFrame } = {}
	if mode == "waiting" then
		-- First 0.72s: Line.castTo drives RightShoulder/Waist; we drive body twist, left arm, elbows & neck.
		local yieldRightAndWaist = t < 0.72
		if t < 0.72 then
			local amp = if reduced then 0.45 else 1
			if t < 0.2 then
				local p = math.sin((t / 0.2) * (math.pi * 0.5))
				addOffset(offsets, "Root", CFrame.Angles(0.07 * p * amp, -0.16 * p * amp, 0))
				addOffset(
					offsets,
					"LeftShoulder",
					CFrame.Angles(-0.32 * p * amp, 0, -0.16 * p * amp)
				)
				addOffset(offsets, "RightElbow", CFrame.Angles(0.45 * p * amp, 0, 0))
				addOffset(offsets, "LeftElbow", CFrame.Angles(0.35 * p * amp, 0, 0))
				addOffset(offsets, "Neck", CFrame.Angles(0.1 * p * amp, 0.1 * p * amp, 0))
			else
				local u = math.clamp((t - 0.2) / 0.52, 0, 1)
				local swing = math.sin(u * math.pi)
				local settle = 1 - u
				addOffset(
					offsets,
					"Root",
					CFrame.Angles((-0.1 * swing + 0.04 * settle) * amp, 0.16 * swing * amp, 0)
				)
				addOffset(
					offsets,
					"LeftShoulder",
					CFrame.Angles(0.38 * swing * amp, 0, -0.14 * swing * amp)
				)
				addOffset(offsets, "RightElbow", CFrame.Angles(0.15 * settle * amp, 0, 0))
				addOffset(offsets, "LeftElbow", CFrame.Angles(0.28 * amp, 0, 0))
				addOffset(
					offsets,
					"Neck",
					CFrame.Angles(-0.08 * swing * amp, -0.06 * swing * amp, 0)
				)
			end
			return offsets, yieldRightAndWaist
		end

		-- Settled wait: gentle breathing & relaxed rod hold.
		local wt = t - 0.72
		local breath = math.sin(wt * 1.55)
		local drift = math.sin(wt * 0.85)
		local amp = if reduced then 0.35 else 1
		addOffset(offsets, "Waist", CFrame.Angles(breath * 0.03 * amp, drift * 0.04 * amp, 0))
		addOffset(
			offsets,
			"RightShoulder",
			CFrame.Angles(math.sin(wt * 1.55 + 0.45) * 0.055 * amp, 0.04 * amp, 0)
		)
		addOffset(
			offsets,
			"Right Shoulder",
			CFrame.Angles(math.sin(wt * 1.55 + 0.45) * 0.055 * amp, 0, 0)
		)
		addOffset(
			offsets,
			"LeftShoulder",
			CFrame.Angles((0.2 + math.sin(wt * 1.55 - 0.5) * 0.04) * amp, 0.1 * amp, -0.06 * amp)
		)
		addOffset(
			offsets,
			"Left Shoulder",
			CFrame.Angles((0.2 + math.sin(wt * 1.55 - 0.5) * 0.04) * amp, 0, -0.06 * amp)
		)
		addOffset(offsets, "RightElbow", CFrame.Angles((0.18 + breath * 0.035) * amp, 0, 0))
		addOffset(offsets, "LeftElbow", CFrame.Angles((0.28 + breath * 0.035) * amp, 0, 0))
		addOffset(
			offsets,
			"Neck",
			CFrame.Angles(
				(-0.04 + math.sin(wt * 1.1) * 0.03) * amp,
				math.sin(wt * 0.65) * 0.045 * amp,
				0
			)
		)
		return offsets, false
	elseif mode == "fighting" then
		-- Line.bite drives RightShoulder/Waist jitter; we drive leaning stance, left bracing arm,
		-- flexed elbows, and focused neck tilt without conflicting with Pose.play.
		local amp = if reduced then 0.3 else 1
		local pull = math.sin(t * 3.1)
		local tremor = if reduced then 0 else math.sin(t * 23) * 0.025
		addOffset(
			offsets,
			"Root",
			CFrame.Angles(
				0.16 * amp + tremor * 0.5,
				pull * 0.07 * amp,
				math.sin(t * 6.2) * 0.03 * amp
			)
		)
		addOffset(
			offsets,
			"LeftShoulder",
			CFrame.Angles((1.05 + pull * 0.14) * amp + tremor, 0, 0.34 * amp)
		)
		addOffset(
			offsets,
			"Left Shoulder",
			CFrame.Angles((1.05 + pull * 0.14) * amp + tremor, 0, 0.34 * amp)
		)
		addOffset(
			offsets,
			"RightElbow",
			CFrame.Angles((0.44 + math.sin(t * 7.4) * 0.13) * amp + tremor, 0, 0)
		)
		addOffset(
			offsets,
			"LeftElbow",
			CFrame.Angles((0.76 + math.sin(t * 5.2) * 0.15) * amp + tremor, 0, 0)
		)
		addOffset(
			offsets,
			"Neck",
			CFrame.Angles((0.06 + pull * 0.04) * amp, math.sin(t * 2.2) * 0.06 * amp, 0)
		)
		return offsets, true
	elseif mode == "celebrate" then
		-- Line.reelIn ends at 0.95s; RightShoulder & Waist join the two-handed victory V cleanly right after.
		-- While holding a Tool, ToolNoneAnim already raises RightShoulder ~1.38 rad, so add ~0.9 rad
		-- instead of 2.2 so both hands mirror high overhead rather than bending behind the back.
		local yieldRightAndWaist = t < 0.96
		local amp = if reduced then 0.5 else 1
		local wave = math.sin(t * 5.2)
		local sway = math.sin(t * 3.6)
		local hopY = if not reduced and t < 0.55 then math.sin((t / 0.55) * math.pi) * 1.1 else 0
		addOffset(
			offsets,
			"Root",
			CFrame.new(0, hopY, 0) * CFrame.Angles(0.06 * amp, sway * 0.06 * amp, sway * 0.04 * amp)
		)
		addOffset(offsets, "LeftShoulder", CFrame.Angles((2.2 + wave * 0.1) * amp, 0, -0.4 * amp))
		addOffset(offsets, "Left Shoulder", CFrame.Angles((2.2 + wave * 0.1) * amp, 0, -0.4 * amp))
		addOffset(offsets, "LeftElbow", CFrame.Angles(0.24 * amp, 0, 0))
		addOffset(offsets, "RightElbow", CFrame.Angles(0.24 * amp, 0, 0))
		addOffset(offsets, "Neck", CFrame.Angles(0.14 * amp, sway * 0.06 * amp, 0))
		if not yieldRightAndWaist then
			local blend = math.clamp((t - 0.96) / 0.28, 0, 1)
			local rightBaseX = if holdingTool then 0.9 else 2.2
			addOffset(
				offsets,
				"RightShoulder",
				CFrame.Angles((rightBaseX - wave * 0.1) * amp * blend, 0, 0.35 * amp * blend)
			)
			addOffset(
				offsets,
				"Right Shoulder",
				CFrame.Angles((rightBaseX - wave * 0.1) * amp * blend, 0, 0.35 * amp * blend)
			)
			addOffset(
				offsets,
				"Waist",
				CFrame.Angles(0.1 * amp * blend, 0, sway * 0.05 * amp * blend)
			)
		end
		return offsets, yieldRightAndWaist
	end

	return offsets, false
end

local function attachCharacter(player: Player, character: Model)
	local joints: { [string]: JointEntry } = {}
	for _, child in character:GetDescendants() do
		if
			TRACKED_JOINTS[child.Name]
			and (child:IsA("Motor6D") or child.ClassName == "AnimationConstraint")
		then
			local joint = (child :: any) :: Joint
			joints[child.Name] = {
				joint = joint,
				base = joint.Transform,
				applied = nil,
				weight = 0,
				targetOffset = CFrame.new(),
			}
		end
	end

	local mode = "idle"
	local modeStart = os.clock()

	local function refreshMode()
		local revealActive = player:GetAttribute("CatchRevealActive") == true
		local fishingState = character:GetAttribute("FishingState")
		local nextMode = if revealActive
			then "celebrate"
			elseif fishingState == "waiting" or fishingState == "fighting" then fishingState
			else "idle"

		if nextMode ~= mode then
			mode = nextMode
			modeStart = os.clock()
		end
	end

	local attrConn = character:GetAttributeChangedSignal("FishingState"):Connect(refreshMode)
	local revealConn = player:GetAttributeChangedSignal("CatchRevealActive"):Connect(refreshMode)
	refreshMode()

	local lastTime = os.clock()
	local stepConn: RBXScriptConnection? = nil

	local function cleanup()
		attrConn:Disconnect()
		revealConn:Disconnect()
		if stepConn then
			stepConn:Disconnect()
			stepConn = nil
		end
		for _, entry in joints do
			if entry.joint.Parent and entry.applied and entry.joint.Transform == entry.applied then
				entry.joint.Transform = entry.base
			end
		end
	end

	local ancestryConn: RBXScriptConnection
	ancestryConn = character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			ancestryConn:Disconnect()
			cleanup()
		end
	end)

	stepConn = RunService.PreSimulation:Connect(function()
		if not character.Parent then
			ancestryConn:Disconnect()
			cleanup()
			return
		end
		local now = os.clock()
		local dt = math.min(now - lastTime, 0.1)
		lastTime = now

		local reduced = player:GetAttribute("ReduceEffects") == true
		local holdingTool = character:FindFirstChildOfClass("Tool") ~= nil
		local offsets, yieldRightAndWaist = samplePose(mode, now - modeStart, reduced, holdingTool)
		local fadeIn = 1 - math.exp(-12 * dt)
		local fadeOut = 1 - math.exp(-10 * dt)

		for name, entry in joints do
			local joint = entry.joint
			if joint.Parent then
				local offset: CFrame? = offsets[name]
				local yielding = yieldRightAndWaist
					and (name == "RightShoulder" or name == "Right Shoulder" or name == "Waist")

				if offset and not yielding then
					entry.targetOffset = offset
					entry.weight = entry.weight + (1 - entry.weight) * fadeIn
				else
					entry.weight = entry.weight * (1 - fadeOut)
				end

				if entry.weight > 0.002 then
					if joint.Transform ~= entry.applied then
						entry.base = joint.Transform
					end
					joint.Transform = entry.base
						* CFrame.new():Lerp(entry.targetOffset, entry.weight)
					entry.applied = joint.Transform
				elseif entry.applied then
					if joint.Transform == entry.applied then
						joint.Transform = entry.base
					end
					entry.applied = nil
					entry.weight = 0
				end
			end
		end
	end)
end

function CharacterMotion.start()
	local player = Players.LocalPlayer
	if not player then
		return
	end
	if player.Character then
		attachCharacter(player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		attachCharacter(player, character)
	end)
end

return CharacterMotion
