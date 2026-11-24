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
	local N = F.AIM.segments
	assert(N == 10, "ten cells")
	for _, aim in { 0, 0.2, 0.35, 0.5, 0.6, 0.8, 0.95, 1 } do
		local layout = F.aimLayout(aim)
		assert(#layout == N, "cell count " .. aim)
		local counts = F.aimCounts(aim)
		local total = 0
		for _, c in counts do
			total += c
		end
		assert(total == N, "counts sum " .. aim)
		-- cells go bottom to top, contiguous, in the fixed order
		local order = { neutral = 1, red = 2, yellow = 3, green = 4, purple = 5 }
		for i = 1, #layout do
			assert(math.abs(layout[i].from - (i - 1) / N) < 1e-9, "from " .. i)
			assert(math.abs(layout[i].to - i / N) < 1e-9, "to " .. i)
			if i > 1 then
				assert(order[layout[i].band] >= order[layout[i - 1].band], "order " .. aim)
			end
		end
		table.insert(
			report,
			string.format(
				"aim %.2f: grey %d red %d yellow %d green %d purple %d",
				aim,
				counts.neutral,
				counts.red,
				counts.yellow,
				counts.green,
				counts.purple
			)
		)
	end
	-- progression: green grows, red shrinks, purple appears late and grows
	assert(F.aimCounts(1).green > F.aimCounts(0).green, "green grows")
	assert(F.aimCounts(1).red < F.aimCounts(0).red, "red shrinks")
	assert(F.aimCounts(0).purple == 0 and F.aimCounts(0.35).purple == 0, "no purple early")
	assert(F.aimCounts(1).purple >= 2, "purple at the top level")
	assert(F.aimCounts(0).green >= 1, "always a green cell")
	-- start: grey is the biggest group
	local c0 = F.aimCounts(0)
	assert(
		c0.neutral >= c0.red and c0.neutral >= c0.yellow and c0.neutral >= c0.green,
		"grey biggest"
	)

	-- gauge fill: rises, holds full, snaps back
	local fill, hold = F.AIM.fillSeconds, F.AIM.holdSeconds
	assert(F.aimPosition(0) == 0, "starts empty")
	assert(math.abs(F.aimPosition(fill * 0.5) - 0.5) < 1e-9, "halfway")
	assert(F.aimPosition(fill) == 1 and F.aimPosition(fill + hold * 0.5) == 1, "holds full")
	assert(F.aimPosition(fill + hold + 0.0001) < 0.01, "snaps back to empty")
	assert(F.aimPosition(fill + hold + fill * 0.5) > 0.49, "second cycle rises again")
	assert(F.aimPosition(-3) == 0 and F.aimPosition(0 / 0) == 0, "junk time")
	-- bandAt: bottom cell grey, top cell purple at the top level, edges safe
	local top = F.aimLayout(1)
	assert(F.bandAt(top, 0) == "neutral", "bottom is grey")
	assert(F.bandAt(top, 1) == "purple", "full is purple at max aim")
	assert(F.bandAt(top, 0.999) == "purple", "top cell")
	assert(F.bandAt({}, 0.5) == "red", "empty layout is red")
	local early = F.aimLayout(0)
	assert(F.bandAt(early, 1) == early[#early].band, "top cell of the early layout")

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
