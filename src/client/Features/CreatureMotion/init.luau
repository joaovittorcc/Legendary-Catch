--!strict

export type Motion = {
	model: Model,
	center: Vector3,
	amplitude: number,
	tempo: number,
	neon: { { part: BasePart, color: Color3 } },
}

local TEMPO: { [string]: number } = {
	bubbles = 0.92,
	splash = 1.15,
	spark = 1.2,
	prism = 0.9,
	storm = 1.35,
	crystal = 0.77,
	cosmic = 0.62,
	magma = 0.83,
	cloud = 0.57,
	frost = 0.72,
}

local CreatureMotion = {}

function CreatureMotion.bind(model: Model, style: string?): Motion
	local box, size = model:GetBoundingBox()
	local neon = {}
	for _, item in model:GetDescendants() do
		if #neon >= 8 then
			break
		end
		if
			item:IsA("BasePart")
			and item.Material == Enum.Material.Neon
			and item.Transparency < 0.95
		then
			table.insert(neon, { part = item, color = item.Color })
		end
	end
	return {
		model = model,
		center = model:GetPivot():PointToObjectSpace(box.Position),
		amplitude = math.clamp(math.max(size.X, size.Y, size.Z) * 0.075, 0.12, 0.55),
		tempo = TEMPO[style or ""] or 1,
		neon = neon,
	}
end

function CreatureMotion.reset(motion: Motion, base: CFrame)
	motion.model:PivotTo(base)
	for _, item in motion.neon do
		item.part.Color = item.color
	end
end

function CreatureMotion.pose(motion: Motion, base: CFrame, elapsed: number, showTurn: boolean)
	local phase = elapsed * math.pi * 2 * motion.tempo
	local sway = math.sin(phase * 0.55)
	local wave = math.sin(phase)
	local offset = Vector3.new(sway * motion.amplitude * 0.35, wave * motion.amplitude, 0)
	local turn = if showTurn then elapsed * 0.66 else sway * 0.15
	local rotation = CFrame.Angles(wave * 0.065, turn, sway * 0.09)
	local center = CFrame.new(motion.center)
	motion.model:PivotTo(CFrame.new(offset) * base * center * rotation * center:Inverse())
	local glow = 0.15 + math.sin(phase * 0.42) * 0.11
	for _, item in motion.neon do
		item.part.Color = item.color:Lerp(Color3.new(1, 1, 1), glow)
	end
end

return CreatureMotion
