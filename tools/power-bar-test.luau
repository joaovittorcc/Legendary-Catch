--!strict
-- P2 checks for the power bar maths (Config/Fishing). Needs the Rojo-synced place, no Play.
-- Run in Studio (Edit) via execute_luau; returns "ALL OK ..." or the first failure.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local F =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Fishing"))

local function share(layout: { any }, band: string): number
	local total = 0
	for _, seg in layout do
		if seg.band == band then
			total += seg.to - seg.from
		end
	end
	return total
end

local function count(layout: { any }, band: string): number
	local n = 0
	for _, seg in layout do
		if seg.band == band then
			n += 1
		end
	end
	return n
end

local report = {}
local ok, err = pcall(function()
	for _, aim in { 0, 0.2, 0.35, 0.5, 0.6, 0.8, 0.95, 1 } do
		local layout = F.aimLayout(aim)
		-- covers 0..1 with no gaps
		assert(layout[1].from == 0 and layout[#layout].to == 1, "edges " .. aim)
		for i = 2, #layout do
			assert(math.abs(layout[i].from - layout[i - 1].to) < 1e-9, "gap " .. aim)
		end
		-- symmetric: band at x equals band at 1 - x
		for _, x in { 0.01, 0.1, 0.2, 0.3, 0.42 } do
			assert(F.bandAt(layout, x) == F.bandAt(layout, 1 - x), `symmetry {aim} at {x}`)
		end
		table.insert(
			report,
			string.format(
				"aim %.2f green %.2f purple %.2f",
				aim,
				share(layout, "green"),
				share(layout, "purple")
			)
		)
	end
	-- progression: green grows, negatives shrink, purple appears late, two purples at the top
	assert(share(F.aimLayout(1), "green") > share(F.aimLayout(0), "green"), "green grows")
	assert(share(F.aimLayout(1), "red") < share(F.aimLayout(0), "red"), "red shrinks")
	assert(share(F.aimLayout(0.35), "purple") == 0, "no purple early")
	assert(share(F.aimLayout(0.6), "purple") > 0.05, "purple at 0.6")
	assert(count(F.aimLayout(0.9), "purple") == 1, "one purple")
	assert(count(F.aimLayout(1), "purple") == 2, "two purples at the top")
	-- start: big neutral, single small green
	assert(share(F.aimLayout(0), "neutral") > 0.39, "big neutral at start")
	assert(count(F.aimLayout(0), "green") == 1, "one green at start")

	-- pointer ping-pong
	local sweep = F.AIM.sweepSeconds
	assert(F.aimPosition(0) == 0, "starts at 0")
	assert(math.abs(F.aimPosition(sweep) - 1) < 1e-9, "1 after a sweep")
	assert(math.abs(F.aimPosition(sweep * 2)) < 1e-9, "back to 0")
	assert(math.abs(F.aimPosition(sweep * 0.5) - 0.5) < 1e-9, "halfway")
	assert(F.aimPosition(-3) == 0 and F.aimPosition(0 / 0) == 0, "junk time")

	-- luck factors
	assert(F.powerFactor("purple", 1) == 1, "commons untouched")
	assert(math.abs(F.powerFactor("purple", 5) - 2) < 1e-9, "purple legendary x2")
	assert(math.abs(F.powerFactor("red", 5) - 0.68) < 1e-9, "red legendary x0.68")
	assert(F.powerFactor("neutral", 6) == 1, "neutral = today")
	assert(F.powerFactor("nope", 4) == 1, "unknown band neutral")

	-- aim level
	assert(F.aimLevel(0, 0) == 0 and F.aimLevel(1, 0.32) == 1, "aim ends")
	assert(math.abs(F.aimLevel(1, 0) - 0.7) < 1e-9, "training alone 0.7")
	assert(F.aimLevel(0 / 0, 0 / 0) == 0, "aim junk")
	assert(#F.LUCK_CAP == #F.RARITY_ORDER, "a cap per rarity")
end)

return if ok then "ALL OK | " .. table.concat(report, " | ") else "FAIL: " .. tostring(err)
