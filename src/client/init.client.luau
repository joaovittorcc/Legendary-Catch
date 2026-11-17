--!strict
-- Starts every feature module under Features that exposes start(), lowest `order` first
-- (default 100). Each start() runs in its own thread so one feature waiting on data
-- can't block the rest. New features don't need to touch this file.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Version"))

type Feature = { start: (() -> ())?, order: number? }

local Data = require(script:WaitForChild("Data"))
Data.start()

local features: { { name: string, module: Feature } } = {}
for _, child in script:WaitForChild("Features"):GetChildren() do
	if child:IsA("ModuleScript") then
		local ok, module = pcall(require :: any, child)
		if ok and type(module) == "table" and module.start then
			table.insert(features, { name = child.Name, module = module :: Feature })
		elseif not ok then
			warn(`[Client] feature {child.Name} failed to load: {module}`)
		end
	end
end
table.sort(features, function(a, b)
	return (a.module.order or 100) < (b.module.order or 100)
end)

for _, f in features do
	task.spawn(function()
		local start = f.module.start :: () -> ()
		local ok, err = (pcall :: any)(start)
		if not ok then
			warn(`[Client] feature {f.name} failed to start: {err}`)
		end
	end)
end

print(`[Client] booted, build {Version.BUILD}`)
