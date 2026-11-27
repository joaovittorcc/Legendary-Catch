--!strict
-- Starts every feature module under Features that exposes start(), lowest `order` first
-- (default 100). New features don't need to touch this file.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Version = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Version"))

type Feature = { start: (() -> ())?, order: number? }

local features: { { name: string, module: Feature } } = {}
for _, child in script:WaitForChild("Features"):GetChildren() do
	if child:IsA("ModuleScript") then
		local ok, module = pcall(require :: any, child)
		if ok and type(module) == "table" and (module :: Feature).start then
			table.insert(features, { name = child.Name, module = module :: Feature })
		elseif not ok then
			warn(`[Server] feature {child.Name} failed to load: {module}`)
		end
	end
end
table.sort(features, function(a, b)
	local oa, ob = a.module.order or 100, b.module.order or 100
	if oa ~= ob then
		return oa < ob
	end
	return a.name < b.name
end)

for _, f in features do
	local start = f.module.start :: () -> ()
	local ok, err = (pcall :: any)(start)
	if not ok then
		warn(`[Server] feature {f.name} failed to start: {err}`)
	end
end

print(`[Server] booted, build {Version.BUILD}`)
