--!strict
-- Legendary Catch / isolated, deterministic hub generator.
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Terrain = Workspace.Terrain
local Builder = {}
local SEED = 241126
local DEFAULT_ORIGIN = Vector3.new(0, 0, 700)
local BOX_MIN = Vector3.new(-105, -14, -95)
local BOX_MAX = Vector3.new(45, 60, 80)
local RES = 4
local PI = math.pi
local V = Vector3.new
local RGB = Color3.fromRGB
local M = Enum.Material
local PALETTE = {
	wood = RGB(167, 99, 53), woodLight = RGB(204, 137, 77), woodDark = RGB(102, 58, 38),
	stone = RGB(189, 186, 193), stoneDark = RGB(112, 118, 148), paving = RGB(222, 212, 197),
	gold = RGB(248, 180, 65), rope = RGB(216, 177, 111), blue = RGB(38, 111, 224),
	cyan = RGB(75, 240, 255), pink = RGB(255, 132, 199), purple = RGB(120, 68, 228),
	grass = RGB(87, 181, 103), leaf = RGB(111, 207, 89), leafDark = RGB(45, 151, 110),
	white = RGB(255, 246, 222), dark = RGB(30, 40, 67), amber = RGB(255, 173, 57),
}
local P = PALETTE
local function makeFolder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder"); f.Name = name; f.Parent = parent; return f
end
local function makeModel(parent: Instance, name: string): Model
	local m = Instance.new("Model"); m.Name = name; m.Parent = parent; return m
end
local function makePart(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material, canCollide: boolean, transparency: number?): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = V(math.max(size.X, .05), math.max(size.Y, .05), math.max(size.Z, .05)); p.CFrame = cf
	p.Color = color; p.Material = material; p.Anchored = true; p.CanCollide = canCollide; p.CanTouch = false
	p.CanQuery = canCollide; p.Transparency = transparency or 0; p.CastShadow = canCollide or size.Magnitude > 5
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent
	return p
end
local function makeWedge(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material, canCollide: boolean): WedgePart
	local p = Instance.new("WedgePart"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color; p.Material = material
	p.Anchored = true; p.CanCollide = canCollide; p.CanTouch = false; p.CanQuery = canCollide; p.CastShadow = size.Magnitude > 5; p.Parent = parent; return p
end
local function makeCylinderY(parent: Instance, name: string, cf: CFrame, diameter: number, height: number, color: Color3, material: Enum.Material, collide: boolean, alpha: number?): Part
	local p = makePart(parent, name, cf * CFrame.Angles(0, 0, PI / 2), V(height, diameter, diameter), color, material, collide, alpha)
	p.Shape = Enum.PartType.Cylinder; return p
end
local function makeEllipsoid(parent: Instance, name: string, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material, collide: boolean, alpha: number?): Part
	local p = makePart(parent, name, cf, size, color, material, collide, alpha)
	-- A spherical SpecialMesh permits nonuniform visual scaling without changing collision geometry.
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p; return p
end
local function makeSegment(parent: Instance, name: string, a: Vector3, b: Vector3, diameter: number, color: Color3, material: Enum.Material, collide: boolean?): Part
	local d = b - a; local mid = (a + b) / 2
	local up = d.Unit; local ref = if math.abs(up:Dot(Vector3.yAxis)) > .98 then Vector3.xAxis else Vector3.yAxis
	local right = ref:Cross(up).Unit; local back = right:Cross(up)
	return makeCylinderY(parent, name, CFrame.fromMatrix(mid, right, up, back), diameter, d.Magnitude, color, material, collide == true)
end
local function box(parent: Instance, name: string, pos: Vector3, size: Vector3, color: Color3, mat: Enum.Material, collide: boolean?): Part
	return makePart(parent, name, CFrame.new(pos), size, color, mat, collide == true)
end
local function tint(color: Color3, rng: Random, amount: number?): Color3
	local v = rng:NextNumber(-(amount or .08), amount or .08)
	return Color3.new(math.clamp(color.R + v, 0, 1), math.clamp(color.G + v, 0, 1), math.clamp(color.B + v, 0, 1))
end
local function light(part: BasePart, color: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight"); l.Color = color; l.Brightness = brightness; l.Range = range; l.Shadows = false; l.Parent = part
end
local function emitter(part: BasePart, name: string, color: Color3, rate: number, speed: NumberRange, life: NumberRange, size: number, texture: string?): ParticleEmitter
	local e = Instance.new("ParticleEmitter"); e.Name = name; e.Texture = texture or "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color); e.Rate = rate; e.Speed = speed; e.Lifetime = life; e.SpreadAngle = Vector2.new(35, 35)
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, size * .4), NumberSequenceKeypoint.new(.35, size), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .2), NumberSequenceKeypoint.new(.75, .4), NumberSequenceKeypoint.new(1, 1)})
	e.LightEmission = .45; e.Rotation = NumberRange.new(-180, 180); e.RotSpeed = NumberRange.new(-45, 45); e.Parent = part; return e
end
local function makeNeonRing(parent: Instance, name: string, cf: CFrame, radius: number, thickness: number, color: Color3, count: number?): Model
	local m = makeModel(parent, name); local n = count or 32
	for i = 0, n - 1 do
		local a, b = i * 2 * PI / n, (i + 1) * 2 * PI / n
		local p = cf:PointToWorldSpace(V(math.cos(a) * radius, 0, math.sin(a) * radius))
		local q = cf:PointToWorldSpace(V(math.cos(b) * radius, 0, math.sin(b) * radius))
		makeSegment(m, "Arc", p, q, thickness, color, M.Neon)
	end
	return m
end
local function textFace(part: BasePart, face: Enum.NormalId, title: string, subtitle: string?, accent: Color3?)
	local g = Instance.new("SurfaceGui"); g.Name = "SignFace"; g.Face = face; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 65; g.LightInfluence = .15; g.Parent = part
	local t = Instance.new("TextLabel"); t.Name = "Title"; t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(.94, if subtitle then .55 else .9); t.Position = UDim2.fromScale(.03, .05)
	t.Text = title; t.TextColor3 = P.white; t.TextStrokeColor3 = P.woodDark; t.TextStrokeTransparency = .35; t.Font = Enum.Font.FredokaOne; t.TextScaled = true; t.TextWrapped = true; t.Parent = g
	if subtitle then
		local s = Instance.new("TextLabel"); s.Name = "Subtitle"; s.BackgroundTransparency = 1; s.Size = UDim2.fromScale(.94, .35); s.Position = UDim2.fromScale(.03, .60)
		s.Text = subtitle; s.Font = Enum.Font.GothamBold; s.TextColor3 = accent or P.cyan; s.TextScaled = true; s.TextWrapped = true; s.Parent = g
	end
end
local function makeSign(parent: Instance, name: string, cf: CFrame, width: number, height: number, title: string, subtitle: string?, accent: Color3?, dark: boolean?): Model
	local m = makeModel(parent, name)
	makePart(m, "Frame", cf, V(width + .45, height + .45, .52), P.woodDark, M.Wood, false)
	makePart(m, "Trim", cf * CFrame.new(0, 0, .29), V(width + .15, height + .15, .10), accent or P.gold, M.SmoothPlastic, false)
	local face = makePart(m, "Board", cf * CFrame.new(0, 0, .37), V(width, height, .14), if dark then P.dark else P.wood, if dark then M.SmoothPlastic else M.WoodPlanks, false)
	textFace(face, Enum.NormalId.Back, title, subtitle, accent)
	for _, x in {-1, 1} do for _, y in {-1, 1} do
		makeEllipsoid(m, "Rivet", cf * CFrame.new(x * (width/2 - .16), y * (height/2 - .16), .49), V(.16, .16, .08), P.gold, M.Metal, false)
	end end
	return m
end
local function makeRope(parent: Instance, a: Vector3, b: Vector3, sag: number, thickness: number?)
	local previous = a
	for i = 1, 6 do
		local t = i / 6; local point = a:Lerp(b, t) - V(0, sag * 4 * t * (1 - t), 0)
		makeSegment(parent, "Rope", previous, point, thickness or .12, P.rope, M.Fabric); previous = point
	end
end
local function knot(parent: Instance, pos: Vector3, radius: number)
	for i = -1, 1 do makeCylinderY(parent, "RopeWrap", CFrame.new(pos + V(0, i * .12, 0)), radius * 2, .095, P.rope, M.Fabric, false) end
end
local function makeLantern(parent: Instance, pos: Vector3, scale: number, lit: boolean?): Model
	local m = makeModel(parent, "AmberLantern"); local cf = CFrame.new(pos); local s = scale
	makeCylinderY(m, "Foot", cf * CFrame.new(0, .12*s, 0), .98*s, .24*s, P.woodDark, M.Wood, false)
	local glow = makePart(m, "AmberGlass", cf * CFrame.new(0, .75*s, 0), V(.59,.99,.59)*s, P.amber, M.Neon, false, .12)
	for _, x in {-.37,.37} do for _, z in {-.37,.37} do
		makePart(m, "Cage", cf * CFrame.new(x*s,.75*s,z*s), V(.10,1.12,.10)*s, P.woodDark, M.Metal, false)
	end end
	makePart(m, "Cap", cf * CFrame.new(0,1.30*s,0), V(.96,.18,.96)*s, P.woodDark, M.Metal, false)
	makeCylinderY(m, "Crown", cf * CFrame.new(0,1.45*s,0), .52*s,.14*s,P.gold,M.Metal,false)
	if lit ~= false then light(glow, P.amber, .65*s, 9*s) end
	return m
end
local function rail(parent: Instance, a: Vector3, b: Vector3, spacing: number, lanterns: boolean)
	local n = math.max(1, math.ceil((b-a).Magnitude / spacing)); local previous: Vector3? = nil
	for i = 0, n do
		local p = a:Lerp(b, i/n)
		makeCylinderY(parent, "RailPost", CFrame.new(p+V(0,1.35,0)), .50, 2.7, P.woodDark,M.Wood,false)
		makeCylinderY(parent, "PostCap", CFrame.new(p+V(0,2.73,0)), .68,.22,P.woodLight,M.Wood,false)
		knot(parent, p+V(0,1.9,0), .31)
		local attach = p+V(0,1.9,0); if previous then makeRope(parent, previous, attach, .35) end; previous = attach
		if lanterns and i % 3 == 0 then makeLantern(parent,p+V(0,2.85,0),.75,true) end
	end
end
-- Triangle split into two right triangles; useful for planar crystal facets.
local function triangle(parent: Instance, a: Vector3, b: Vector3, c: Vector3, color: Color3, mat: Enum.Material)
	local ab, ac, bc = b-a,c-a,c-b
	if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then c,a = a,c
	elseif ac:Dot(ac) > bc:Dot(bc) and ac:Dot(ac) > ab:Dot(ab) then a,b = b,a end
	ab,ac,bc = b-a,c-a,c-b
	if ab:Cross(ac).Magnitude < .001 or bc.Magnitude < .001 then return end
	local right = ac:Cross(ab).Unit; local back = bc.Unit; local up = back:Cross(right).Unit
	local height = math.abs(ab:Dot(up)); local d1,d2 = math.abs(ab:Dot(back)),math.abs(ac:Dot(back))
	if d1 > .03 then makeWedge(parent,"Facet",CFrame.fromMatrix((a+b)/2,right,up,back),V(.07, height,d1),color,mat,false) end
	if d2 > .03 then makeWedge(parent,"Facet",CFrame.fromMatrix((a+c)/2,-right,up,-back),V(.07,height,d2),color,mat,false) end
end
local function makeCrystal(parent: Instance, cf: CFrame, height: number, radius: number, color: Color3, glowing: boolean): Model
	local m = makeModel(parent,"HexCrystal"); local shoulder = height*.70
	for i=0,5 do
		local a,b = i*PI/3,(i+1)*PI/3; local p,q = V(math.cos(a)*radius,0,math.sin(a)*radius),V(math.cos(b)*radius,0,math.sin(b)*radius)
		local tone = color:Lerp(if i%2==0 then Color3.new(1,1,1) else P.purple,if i%2==0 then .22 else .16)
		local center = (p+q)/2 + V(0,shoulder/2,0); local direction = (q-p).Unit
		local facetCF = cf * CFrame.fromMatrix(center,direction,Vector3.yAxis,direction:Cross(Vector3.yAxis))
		makePart(m,"PrismFacet",facetCF,V((q-p).Magnitude+.035,shoulder,.085),tone,M.SmoothPlastic,false,.08)
		triangle(m,cf:PointToWorldSpace(p+V(0,shoulder,0)),cf:PointToWorldSpace(q+V(0,shoulder,0)),cf:PointToWorldSpace(V(0,height,0)),tone,M.SmoothPlastic)
	end
	local core = makeCylinderY(m,"InnerGlow",cf*CFrame.new(0,shoulder*.47,0),radius*1.32,shoulder*.92,color,if glowing then M.Neon else M.SmoothPlastic,false,.27)
	if glowing then light(core,color,.36,math.min(11,height*2)) end
	return m
end
local function cluster(parent: Instance, pos: Vector3, rng: Random, scale: number, color: Color3, glowing: boolean?)
	local m=makeModel(parent,"CrystalCluster")
	makeEllipsoid(m,"SocketRock",CFrame.new(pos+V(0,.1*scale,0)),V(3.7,.85,3.1)*scale,P.stoneDark,M.Slate,false)
	makeCrystal(m,CFrame.new(pos)*CFrame.Angles(0,rng:NextNumber(0,PI),-.10),4.3*scale,.78*scale,color,glowing==true)
	for i=0,2 do
		local a=i*2*PI/3+rng:NextNumber(-.25,.25)
		makeCrystal(m,CFrame.new(pos+V(math.cos(a),0,math.sin(a))*scale)*CFrame.Angles(0,-a,.28),rng:NextNumber(2,3.3)*scale,.48*scale,color:Lerp(P.pink,i==1 and .40 or .1),false)
	end
end
local function makePalm(parent: Instance, pos: Vector3, rng: Random, scale: number)
	local m=makeModel(parent,"Palm"); local prev=pos; local crown=pos+V(1.3,10,0)*scale
	for i=1,9 do
		local t=i/9; local nextP=pos+V(1.3*t*t,10*t,0)*scale
		makeSegment(m,"Trunk",prev,nextP,(1.15-.34*t)*scale,tint(P.woodLight,rng,.04),M.Wood,false)
		makeCylinderY(m,"TrunkBand",CFrame.new(nextP),(.99-.24*t)*scale,.13*scale,P.wood,M.Wood,false); prev=nextP
	end
	for i=0,7 do
		local a=i*PI/4+rng:NextNumber(-.12,.12); local dir=V(math.cos(a),0,math.sin(a))
		for j=1,4 do
			local t=j/4; local center=crown+dir*(t*5.1*scale)+V(0,(1.5*math.sin(t*PI)-.9*t)*scale,0)
			makeEllipsoid(m,"Frond",CFrame.lookAt(center,center+dir)*CFrame.Angles(math.rad(-15+35*t),0,0),V((1.85-.55*t)*scale,.70*scale,2.6*scale),tint(P.leaf,rng,.09),M.SmoothPlastic,false)
		end
	end
	for i=0,2 do makeEllipsoid(m,"Coconut",CFrame.new(crown+V(math.cos(i*2.1),-.5,math.sin(i*2.1))*.75*scale),V(.78,.88,.78)*scale,P.woodDark,M.Wood,false) end
end
local function plant(parent: Instance, pos: Vector3, rng: Random, s: number, color: Color3?)
	local m=makeModel(parent,"CoastalPlant")
	for i=0,5 do
		local a=i*PI/3; local d=V(math.cos(a),0,math.sin(a)); local tip=pos+d*s*.83+V(0,s*rng:NextNumber(.7,1.45),0)
		local cf=CFrame.lookAt((pos+tip)/2,tip)*CFrame.Angles(PI/2,0,0)
		makeEllipsoid(m,"Leaf",cf,V(.47*s,(tip-pos).Magnitude,.25*s),tint(color or P.leafDark,rng,.07),M.SmoothPlastic,false)
	end
end
local function blossom(parent: Instance, pos: Vector3, rng: Random, size: number)
	local c=P.pink:Lerp(P.white,rng:NextNumber(0,.25))
	for i=0,4 do local a=i*2*PI/5; makeEllipsoid(parent,"Petal",CFrame.new(pos+V(math.cos(a)*size*.35,0,math.sin(a)*size*.35)),V(size*.65,.23*size,size*.65),c,M.SmoothPlastic,false) end
	makeEllipsoid(parent,"Pollen",CFrame.new(pos+V(0,.13*size,0)),V(.4,.27,.4)*size,P.gold,M.SmoothPlastic,false)
end
local function bunting(parent: Instance, a: Vector3, b: Vector3, sag: number)
	makeRope(parent,a,b,sag,.07); local colors={P.pink,P.gold,P.cyan,P.leaf,P.purple}; local n=math.max(2,math.floor((b-a).Magnitude/2.1))
	local dir=(b-a).Unit
	for i=1,n do local t=(i-.5)/n; local p=a:Lerp(b,t)-V(0,sag*4*t*(1-t),0)
		triangle(parent,p-dir*.72,p+dir*.72,p-V(0,1.12,0),colors[(i-1)%#colors+1],M.Fabric)
	end
end
local function makeStairs(parent: Instance, from: Vector3, to: Vector3, width: number, rng: Random, runes: boolean?): Model
	local m=makeModel(parent,"Stairs"); local flat=V(to.X-from.X,0,to.Z-from.Z); local len=flat.Magnitude; local d=flat.Unit
	local n=math.max(1,math.ceil(math.abs(to.Y-from.Y)/.55),math.ceil(len/2.2)); local depth=len/n
	for i=1,n do
		local t=(i-.5)/n; local y=from.Y+(to.Y-from.Y)*i/n; local p=from+flat*t
		local cf=CFrame.lookAt(V(p.X,y-.5,p.Z),V(p.X,y-.5,p.Z)+d)
		makePart(m,"Step",cf,V(width,1,depth+.04),tint(P.stone,rng,.045),M.Slate,true)
		makePart(m,"StepNosing",cf*CFrame.new(0,.46,depth/2-.11),V(width,.09,.21),P.paving,M.SmoothPlastic,false)
		if runes then
			local r=cf*CFrame.new(0,.53,0); local c=r.Position
			makeSegment(m,"Rune",c+r.RightVector*.55,c-r.RightVector*.55,.10,P.cyan,M.Neon)
			makeSegment(m,"Rune",c+r.LookVector*.32,c-r.LookVector*.32,.10,P.cyan,M.Neon)
		end
	end
	return m
end
local function makeBridge(parent: Instance, a: Vector3, b: Vector3, width: number, rng: Random, rails: boolean?): Model
	local m=makeModel(parent,"Boardwalk"); local flat=V(b.X-a.X,0,b.Z-a.Z); local len=flat.Magnitude; local d=flat.Unit; local side=V(-d.Z,0,d.X)
	local slope=math.abs(b.Y-a.Y); assert(slope<.01,"Boardwalk endpoints must be level; use stairs for elevation")
	local n=math.max(1,math.ceil(len/1.05)); local step=len/n
	-- One continuous collision surface, wood planks slightly above it.
	local mid=(a+b)/2; local cf=CFrame.lookAt(mid-V(0,.38,0),mid-V(0,.38,0)+d)
	makePart(m,"WalkSurface",cf,V(width,.76,len),P.woodDark,M.Wood,true)
	for i=1,n do
		local p=a+flat*((i-.5)/n)
		makePart(m,"Plank",CFrame.lookAt(p-V(0,.10,0),p-V(0,.10,0)+d),V(width-.04,.22,step-.035),tint(P.woodLight,rng,.09),M.WoodPlanks,false)
		if i%4==1 then for _,s in {-1,1} do makeCylinderY(m,"BrassPin",CFrame.new(p+side*(width*.43*s)+V(0,.035,0)),.14,.045,P.gold,M.Metal,false) end end
	end
	for _,s in {-1,1} do
		local aa=a+side*(width/2-.25)*s; local bb=b+side*(width/2-.25)*s
		makePart(m,"EdgeBeam",CFrame.lookAt((aa+bb)/2-V(0,.68,0),(aa+bb)/2-V(0,.68,0)+d),V(.44,.5,len),P.woodDark,M.Wood,false)
		local supports=math.max(1,math.ceil(len/8))
		for i=0,supports do local p=aa:Lerp(bb,i/supports); makeCylinderY(m,"Piling",CFrame.new(V(p.X,(p.Y-10)/2,p.Z)),.83,p.Y+10,P.woodDark,M.Wood,false) end
		if rails then rail(m,aa,bb,5.5,true) end
	end
	return m
end

-- Surveyed terrain, sampled every four studs. Modified procedurally below.
local SURVEY: {{number}} = {
	{-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,17,21,21,21,17,-4,-4,-4,-4,-4,-4,-4,-4},
	{-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,21,25,26,28,26,25,21,-4,-4,-4,-4,-4,-4,-4},
	{-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,12,17,17,17,17,25,28,31,32,31,28,25,17,-4,-4,-4,-4,-4,-4},
	{-4,-4,-4,-4,-4,-4,-4,-4,-4,12,18,21,21,21,21,26,30,33,34,33,30,26,21,8,12,8,-4,-4,-4},
	{-4,-4,-4,-4,-4,-4,-4,0,2,17,21,23,24,24,22,27,30,33,34,33,30,27,22,17,18,17,13,-4,-4},
	{-4,-4,-4,-4,-4,-4,0,4,5,17,21,23,24,24,22,27,30,31,32,31,30,27,22,19,20,19,17,8,-4},
	{-4,-4,-4,-4,-4,2,5,5,6,17,21,23,23,23,19,26,27,30,31,30,27,26,18,20,21,20,18,12,-4},
	{-4,-4,-4,-4,1,5,7,7,5,12,18,21,21,21,12,12,12,12,12,12,12,12,12,19,20,19,17,8,-4},
	{-4,-4,-4,-4,4,7,7,6,4,2,12,17,17,17,12,12,12,12,12,12,12,12,12,17,18,17,13,-4,-4},
	{-4,-4,-4,1,4,6,6,5,1,6,8,8,9,12,12,12,12,12,12,12,12,12,12,12,12,8,4,-4,-4},
	{-4,-4,2,5,5,2,2,4,7,8,8,8,9,12,12,12,12,12,12,12,12,12,12,12,9,8,7,4,-4},
	{-4,0,5,6,6,2,-4,7,8,9,9,8,9,12,12,12,12,12,12,12,12,12,12,12,9,9,8,5,-4},
	{-4,4,7,8,7,13,21,21,17,16,16,13,9,12,12,12,12,12,12,12,12,12,12,12,9,8,7,4,-4},
	{-4,2,7,8,13,21,25,25,21,18,18,15,9,10,10,10,10,10,10,10,10,10,10,10,9,5,5,2,-4},
	{1,5,7,9,15,21,25,25,21,18,17,14,8,8,8,8,8,8,8,8,8,8,6,-4,1,4,4,2,-4},
	{1,6,7,9,8,8,21,21,21,8,8,8,8,8,8,8,8,8,8,8,8,8,6,-4,-4,2,4,3,0},
	{1,5,6,8,8,8,8,5,17,5,5,8,8,8,8,8,8,8,8,8,8,8,8,7,-4,1,3,5,2},
	{5,7,7,8,8,8,5,4,4,4,4,5,8,8,8,8,8,8,8,8,8,8,8,8,5,3,4,5,4},
	{5,7,7,8,8,7,4,4,4,4,4,4,7,8,8,8,8,8,8,8,8,8,8,8,7,3,4,2,1},
	{2,5,7,8,8,6,4,4,4,4,4,4,6,8,8,8,8,8,8,8,8,8,8,8,7,0,1,-4,-4},
	{3,5,5,8,8,7,4,4,4,4,4,4,7,8,8,8,8,8,8,8,8,8,8,8,7,-4,-4,-4,-4},
	{1,3,6,7,8,8,6,4,4,4,4,6,8,8,8,8,8,8,8,8,8,8,8,8,5,-4,-4,-4,-4},
	{-4,2,5,5,7,8,8,6,5,4,5,8,8,8,8,8,8,8,8,8,8,8,8,7,4,4,1,-4,-4},
	{-4,5,6,6,6,5,7,7,7,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,5,5,2,-4,-4},
	{-4,2,5,5,6,6,6,4,-4,6,8,8,8,8,8,8,8,8,7,8,8,8,8,8,5,4,1,-4,-4},
	{-4,-4,1,1,5,7,7,5,0,-4,7,8,8,8,8,10,9,6,6,6,9,10,8,8,4,1,-4,-4,-4},
	{-4,-4,-4,-4,4,6,7,6,5,4,5,8,8,8,8,10,9,-1,-1,-1,9,10,8,6,2,-4,-4,-4,-4},
	{-4,-4,-4,-4,0,5,7,7,7,6,3,6,8,8,8,8,6,-1,-4,-4,6,8,7,6,2,-4,-4,-4,-4},
	{-4,-4,-4,-4,-4,4,6,6,7,6,3,5,7,7,7,7,6,-4,-4,-4,6,7,5,5,0,-4,-4,-4,-4},
	{-4,-4,-4,-4,-4,0,2,4,5,4,3,6,7,6,6,6,4,-4,-4,-4,5,6,1,-4,-4,-4,-4,-4,-4},
	{-4,-4,-4,-4,-4,-4,-4,-4,0,-4,1,4,5,5,6,6,2,-4,-4,-4,2,3,0,-4,-4,-4,-4,-4,-4},
	{-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,0,-4,1,2,1,-4,-4,-4,1,2,-4,-4,-4,-4,-4,-4,-4},
}
local function smooth(t: number): number
	t=math.clamp(t,0,1); return t*t*(3-2*t)
end
local function mix(a: number,b: number,t: number): number return a+(b-a)*t end
local function rect(x: number,z: number,x0: number,x1: number,z0: number,z1: number): boolean
	return x>=x0 and x<=x1 and z>=z0 and z<=z1
end
local function survey(x: number,z: number): number
	if x < -80 or x > 32 or z < -76 or z > 48 then
		local dx=math.max(-80-x,x-32,0); local dz=math.max(-76-z,z-48,0)
		local clx,clz=math.clamp(x,-80,32),math.clamp(z,-76,48)
		return mix(SURVEY[math.clamp(math.floor((clz+76)/4)+1,1,#SURVEY)][math.clamp(math.floor((clx+80)/4)+1,1,#SURVEY[1])],-12,smooth(math.max(dx,dz)/14))
	end
	local fx,fz=(x+80)/4,(z+76)/4; local ix,iz=math.min(28,math.floor(fx)+1),math.min(31,math.floor(fz)+1)
	local tx,tz=fx-(ix-1),fz-(iz-1)
	return mix(mix(SURVEY[iz][ix],SURVEY[iz][ix+1],tx),mix(SURVEY[iz+1][ix],SURVEY[iz+1][ix+1],tx),tz)
end
local function lagoonRadius(x: number,z: number): number
	local dx,dz=x+44,z-2; local angle=math.atan2(dz,dx)
	return math.sqrt(dx*dx+dz*dz)-(15+.85*math.sin(angle*3)+.45*math.sin(angle*5+1))
end
local function terrainHeight(x: number,z: number): number
	local raw=survey(x,z)
	local noise=math.noise(x/17,z/17,SEED%997)*3.5+math.noise(x/7,z/7,9.24)*1.4
	local h=raw+noise*smooth((raw+9)/7)
	-- Northern cliff, west training terrace and the waterfall buttress.
	local north=math.sqrt(((x+7)/22)^2+((z+61)/16)^2)
	if north<1 then h=math.max(h,9+25*(1-north^1.65)+noise) end
	local west=math.sqrt(((x+55)/28)^2+((z+36)/19)^2)
	if west<1.15 then h=math.max(h,mix(-2,20.2,smooth((1.15-west)/.36))) end
	-- Structural footprints are kept safely below their finished walking surfaces.
	if rect(x,z,-32,20,-24,26) then h=math.min(h,8); h=math.max(h,7.1) end
	if rect(x,z,-28,16,-50,-22) then h=12 end
	if rect(x,z,-81,-29,-50,-24) then h=18.7 end
	if rect(x,z,-54,-27,-22,-12) then
		local stairY=10.3+10.7*math.clamp((-x-27)/24,0,1)
		h=math.min(h,stairY-2.3)
	end
	if rect(x,z,-58,-44,-28,-16) then h=math.min(h,18.4) end
	if rect(x,z,-32,20,-24,26) then h=math.min(h,8) end
	if rect(x,z,-56,-29,-11,0) then h=math.min(h,8.0) end
	-- Contained basin; water is separate from solid occupancy.
	local lr=lagoonRadius(x,z)
	if lr<0 then h=4 elseif lr<4 and x < -30 then h=math.min(h,mix(8.4,11,smooth(lr/4))) end
	-- Keep the sea open under the eastern docks, aquariums and floating boards.
	if x>=18 and z>=-2 then h=math.min(h,-4) end
	if x>=9 and z>=25 then h=math.min(h,-4) end
	if rect(x,z,-52,-24,33,66) or rect(x,z,-97,-45,19,34) then h=math.min(h,-4) end
	if rect(x,z,-16,4,26,54) then h=math.min(h,-4) end
	if z>54 then h=math.min(h,-4) end
	-- Two freestanding sea stacks, with a shallow submerged base.
	local stack=math.sqrt(((x+91)/5)^2+((z+10)/7)^2)
	if stack<1.5 then h=math.max(h,mix(-5,12,smooth((1.5-stack)/1.5))) end
	local stack2=math.sqrt(((x+87)/5)^2+((z+53)/6)^2)
	if stack2<1.5 then h=math.max(h,mix(-7,15,smooth((1.5-stack2)/1.5))) end
	return math.clamp(h,-12,36)
end
local function terrainRegion(origin: Vector3): Region3
	-- Inward rounding, not ExpandToGrid: no voxel straddles the legal box.
	local a,b=origin+BOX_MIN,origin+BOX_MAX
	return Region3.new(V(math.ceil(a.X/RES)*RES,math.ceil(a.Y/RES)*RES,math.ceil(a.Z/RES)*RES),V(math.floor(b.X/RES)*RES,math.floor(b.Y/RES)*RES,math.floor(b.Z/RES)*RES))
end
local function buildTerrain(origin: Vector3)
	local region=terrainRegion(origin); local lo=region.CFrame.Position-region.Size/2; local hi=lo+region.Size
	local nx,ny,nz=math.round(region.Size.X/RES),math.round(region.Size.Y/RES),math.round(region.Size.Z/RES)
	-- One replacement pass atomically clears/rebuilds each slab, preserving all outside cells.
	for start=1,nx,8 do
		local count=math.min(8,nx-start+1)
		local mats: {{{Enum.Material}}}={}; local occ: {{{number}}}={}
		for i=1,count do
			local mt: {{Enum.Material}}={}; local ot: {{number}}={}; mats[i]=mt; occ[i]=ot
			local x=lo.X+(start+i-2)*RES+RES/2-origin.X
			for j=1,ny do mt[j]={}; ot[j]={} end
			for k=1,nz do
				local z=lo.Z+(k-1)*RES+RES/2-origin.Z
				local h=terrainHeight(x,z); local lr=lagoonRadius(x,z)
				local sea=if lr<0 then 8 else 0
				local slope=math.max(math.abs(terrainHeight(x+2,z)-terrainHeight(x-2,z)),math.abs(terrainHeight(x,z+2)-terrainHeight(x,z-2)))
				for j=1,ny do
					local bottom=lo.Y+(j-1)*RES-origin.Y; local center=bottom+RES/2
					local solid=math.clamp((h-bottom)/RES,0,1)
					-- A native terrain arch: two rounded legs and a curved crown, with an open tunnel.
					local ax,az=x+90,z+34; local ring=math.sqrt(ax*ax+(center-3)^2)
					local arch=math.abs(az)<3.5 and ((center>=3 and ring>=5 and ring<=10.5) or (center<3 and center>=-4 and math.abs(ax)>=5 and math.abs(ax)<=10))
					if arch then solid=math.max(solid,.92) end
					local material= M.Air; local occupancy=0
					if solid>.001 then
						occupancy=solid
						if arch then material=M.Rock
						elseif h<=2 or (lr<0 and center>=h-5) then material=if center<-10 and h<-8 then M.Slate else M.Sand
						elseif center>=h-3.4 and slope<4.5 and h>5 then material=M.Grass
						elseif center<0 or (math.floor((center+2)/5)%3==1 and h-center>3) then material=M.Basalt
						else material=M.Rock end
					elseif bottom<sea then material=M.Water; occupancy=math.clamp((sea-bottom)/RES,0,1) end
					mt[j][k]=material; ot[j][k]=occupancy
				end
			end
		end
		local a=V(lo.X+(start-1)*RES,lo.Y,lo.Z); local b=V(a.X+count*RES,hi.Y,hi.Z)
		Terrain:WriteVoxels(Region3.new(a,b),RES,mats,occ); task.wait()
	end
end
local function floorRay(origin: Vector3,x: number,z: number): number?
	local p=RaycastParams.new(); p.FilterType=Enum.RaycastFilterType.Include; p.FilterDescendantsInstances={Terrain}; p.IgnoreWater=true
	local r=Workspace:Raycast(origin+V(x,65,z),V(0,-95,0),p); if r then return r.Position.Y-origin.Y end; return nil
end
local function onGround(origin: Vector3,x: number,z: number): Vector3
	return origin+V(x,(floorRay(origin,x,z) or terrainHeight(x,z))-.10,z)
end
local function pavedFloor(parent: Instance, center: Vector3, width: number, depth: number, rng: Random, foundationDepth: number?)
	local thickness=foundationDepth or .70
	box(parent,"PavedFoundation",center-V(0,thickness/2,0),V(width,thickness,depth),P.stoneDark,M.Slate,true)
	local nx,nz=math.ceil(width/3.2),math.ceil(depth/2.0); local sx,sz=width/nx,depth/nz
	for i=1,nx do for j=1,nz do
		local x=(i-.5)*sx-width/2; local z=(j-.5)*sz-depth/2
		box(parent,"PavingTile",center+V(x,.027,z),V(sx-.045,.055,sz-.045),tint(P.paving,rng,.055),M.Cobblestone,false)
	end end
end
local function stonePost(parent: Instance, pos: Vector3, height: number, rng: Random)
	local n=math.ceil(height/1.35); local step=height/n
	for i=1,n do box(parent,"Ashlar",pos+V(0,(i-.5)*step,0),V(if i%2==0 then 1.9 else 2.05,step-.035,1.95),tint(P.stone,rng,.06),M.Slate,true) end
	box(parent,"Capital",pos+V(0,height+.18,0),V(2.35,.36,2.35),P.paving,M.Slate,false)
end
local function gate(parent: Instance, cf: CFrame, width: number, title: string, rng: Random, stone: boolean, flags: boolean?): Model
	local m=makeModel(parent,"EntryGate"); local half=width/2+1; local h=7.6
	for _,s in {-1,1} do
		local base=cf:PointToWorldSpace(V(half*s,0,0))
		if stone then stonePost(m,base,h,rng) else
			makeCylinderY(m,"Mast",CFrame.new(base+V(0,h/2,0)),1.18,h,P.woodDark,M.Wood,true)
			knot(m,base+V(0,h-1,0),.66); knot(m,base+V(0,1.2,0),.66)
		end
		local lamp=cf:PointToWorldSpace(V(half*s,4.7,1.22)); makeLantern(m,lamp,.85,true)
		makePart(m,"LanternBracket",cf*CFrame.new(half*s,4.6,.92),V(.38,.24,1.05),P.woodDark,M.Wood,false)
	end
	makePart(m,"Lintel",cf*CFrame.new(0,h+.40,0),V(width+4.1,1.2,1.65),P.wood,M.WoodPlanks,true)
	makeSign(m,"GateSign",cf*CFrame.new(0,h+.29,1.01),math.min(width+1.4,15),2.6,title,nil,P.gold,false)
	if flags then bunting(m,cf:PointToWorldSpace(V(-half,h-1.0,.95)),cf:PointToWorldSpace(V(half,h-1.0,.95)),.45) end
	return m
end
local function directionSign(parent: Instance, cf: CFrame, title: string, subtitle: string?, arrow: string?)
	makePart(parent,"SignPost",cf*CFrame.new(0,1.7,0),V(.48,3.4,.48),P.woodDark,M.Wood,false)
	makeSign(parent,"Direction",cf*CFrame.new(0,3.3,0),7.9,1.65,(arrow or "")..title,subtitle,P.gold,false)
end
local function bench(parent: Instance, cf: CFrame)
	for _,s in {-1,1} do
		makePart(parent,"BenchLeg",cf*CFrame.new(s*1.75,.58,0),V(.38,1.16,1.30),P.woodDark,M.Wood,false)
		makePart(parent,"BackPost",cf*CFrame.new(s*1.75,1.62,-.60),V(.25,2.15,.26),P.woodDark,M.Wood,false)
	end
	for i=0,2 do makePart(parent,"SeatSlat",cf*CFrame.new(0,1.17,-.48+i*.48),V(4.4,.22,.44),P.woodLight,M.WoodPlanks,false) end
	for i=0,1 do makePart(parent,"BackSlat",cf*CFrame.new(0,1.76+i*.40,-.62),V(4.4,.33,.20),P.wood,M.WoodPlanks,false) end
end
local function crate(parent: Instance, cf: CFrame, size: number)
	makePart(parent,"Crate",cf*CFrame.new(0,size/2,0),V(size,size,size),P.wood,M.WoodPlanks,false)
	for _,s in {-1,1} do for _,t in {-1,1} do
		makePart(parent,"CrateCorner",cf*CFrame.new(s*size*.43,size/2,t*size*.43),V(.15,size+.05,.15),P.woodDark,M.Wood,false)
	end end
	for _,s in {-1,1} do
		makePart(parent,"CrateBrace",cf*CFrame.new(0,size/2,s*(size/2+.035))*CFrame.Angles(0,0,PI/4),V(.20,size*1.25,.10),P.woodLight,M.Wood,false)
	end
end
local function barrel(parent: Instance, cf: CFrame, size: number)
	local r=size*.55
	for i=0,11 do local a=i*PI/6; makePart(parent,"BarrelStave",cf*CFrame.new(math.cos(a)*r,size*.65,math.sin(a)*r)*CFrame.Angles(0,-a,0),V(.15,size*1.3,r*.54),P.wood,M.WoodPlanks,false) end
	for _,y in {.18,.49,1.09,1.27} do makeCylinderY(parent,"BarrelHoop",cf*CFrame.new(0,size*y,0),size*1.18,.12*size,P.woodDark,M.Metal,false) end
	makeCylinderY(parent,"BarrelLid",cf*CFrame.new(0,size*1.30,0),size*1.03,.12*size,P.woodLight,M.Wood,false)
end
local function lifeRing(parent: Instance, cf: CFrame, r: number)
	for i=0,19 do local a,b=i*PI/10,(i+1)*PI/10
		makeSegment(parent,"LifeRing",cf:PointToWorldSpace(V(math.cos(a)*r,math.sin(a)*r,0)),cf:PointToWorldSpace(V(math.cos(b)*r,math.sin(b)*r,0)),r*.35,if math.floor(i/3)%2==0 then P.white else RGB(241,91,77),M.SmoothPlastic)
	end
end
local function net(parent: Instance, cf: CFrame, w: number, h: number)
	local n=math.floor(w/.5); local m=math.floor(h/.5)
	for i=0,n do local x=-w/2+i*w/n; makeSegment(parent,"NetWarp",cf:PointToWorldSpace(V(x,0,0)),cf:PointToWorldSpace(V(x,-h,.25)),.055,P.rope,M.Fabric) end
	for j=0,m do local y=-j*h/m; makeSegment(parent,"NetWeft",cf:PointToWorldSpace(V(-w/2,y,.25*j/m)),cf:PointToWorldSpace(V(w/2,y,.25*j/m)),.055,P.rope,M.Fabric) end
end
local function campfire(parent: Instance, pos: Vector3, rng: Random)
	local m=makeModel(parent,"CampfireRest"); makeCylinderY(m,"Hearth",CFrame.new(pos+V(0,.10,0)),5.6,.20,P.stoneDark,M.Slate,false)
	for i=0,11 do local a=i*PI/6; makeEllipsoid(m,"FireStone",CFrame.new(pos+V(math.cos(a)*2.35,.38,math.sin(a)*2.35)),V(1.22,.85,1.05),tint(P.gold,rng,.10),M.Slate,false) end
	for i=0,5 do local a=i*PI/3; makeSegment(m,"Log",pos+V(math.cos(a)*1.55,.30,math.sin(a)*1.55),pos+V(0,2.25,0),.58,P.woodDark,M.Wood) end
	local flame=makeEllipsoid(m,"FlameCore",CFrame.new(pos+V(0,1.65,0)),V(1.42,2.7,1.42),P.amber,M.Neon,false,.15)
	for i=0,3 do makeEllipsoid(m,"FlameTongue",CFrame.new(pos+V(math.cos(i*PI/2)*.48,1.0,math.sin(i*PI/2)*.48))*CFrame.Angles(0,i,-.22),V(.65,1.65,.62),RGB(255,104,38),M.Neon,false,.20) end
	light(flame,P.amber,1.3,15); local sparks=emitter(flame,"Embers",P.gold,9,NumberRange.new(1,3),NumberRange.new(.6,1.2),.22); sparks.Acceleration=V(0,1,0)
	for _,a in {0,PI/2,PI,PI*1.5} do local p=pos+V(math.cos(a)*4.5,0,math.sin(a)*4.5); bench(m,CFrame.lookAt(p,pos)*CFrame.Angles(0,PI,0)) end
end
-- Portal specifications are the server contract, not a new progression system.
type PortalSpec = {id: string, zone: string, dest: string, training: number?, title: string, subtitle: string, primary: Color3, accent: Color3, style: string}
local PORTALS: {PortalSpec} = {
	{id="main_to_coral",zone="coral",dest="coral",title="ILHA DO RECIFE",subtitle="Nível 5",primary=RGB(255,130,145),accent=RGB(255,218,171),style="coral"},
	{id="main_to_abyss",zone="abyss",dest="abyss",title="ABISMO ESTELAR",subtitle="Nível 15",primary=RGB(90,86,235),accent=RGB(195,118,255),style="abyss"},
	{id="main_to_training_1",zone="lagoon",dest="training_1",training=1,title="ILHA DO APRENDIZ",subtitle="Treino x1 · Grátis",primary=RGB(113,144,170),accent=P.cyan,style="stone"},
	{id="main_to_training_reef",zone="lagoon",dest="training_reef",training=2,title="ILHA DO RECIFE",subtitle="Treino x3 · 100K Poder",primary=RGB(63,173,160),accent=P.cyan,style="reef"},
	{id="main_to_training_abyss",zone="lagoon",dest="training_abyss",training=3,title="ABISMO ESTELAR",subtitle="Treino x12 · 100M Poder",primary=RGB(91,53,181),accent=P.pink,style="abyss"},
	{id="main_to_training_celestial",zone="lagoon",dest="training_celestial",training=4,title="ILHA CELESTIAL",subtitle="Treino x50 · 1T Poder",primary=RGB(245,177,56),accent=RGB(255,240,145),style="gold"},
	{id="lagoon_to_training_1",zone="lagoon",dest="training_1",training=1,title="ILHA DO APRENDIZ",subtitle="Treino x1 · Grátis",primary=RGB(113,144,170),accent=P.cyan,style="stone"},
}
local function contractPart(parent: Instance, name: string, cf: CFrame, size: Vector3, tag: string): Part
	local p=makePart(parent,name,cf,size,P.dark,M.SmoothPlastic,false,1); p.CastShadow=false; CollectionService:AddTag(p,tag); return p
end
local function coralBranch(parent: Instance, cf: CFrame, color: Color3, scale: number)
	local p=cf.Position; local top=cf:PointToWorldSpace(V(0,2.4*scale,0)); makeSegment(parent,"CoralBranch",p,top,.36*scale,color,M.SmoothPlastic)
	for _,s in {-1,1} do local mid=cf:PointToWorldSpace(V(0,1.0*scale,0)); local tip=cf:PointToWorldSpace(V(s*.90*scale,1.85*scale,.15*scale)); makeSegment(parent,"CoralArm",mid,tip,.28*scale,color,M.SmoothPlastic); makeEllipsoid(parent,"CoralTip",CFrame.new(tip),V(.32,.42,.32)*scale,color,M.SmoothPlastic,false) end
end
local function makePortal(parent: Instance, contracts: Instance, cf: CFrame, spec: PortalSpec, rng: Random)
	local m=makeModel(parent,spec.id); local c=spec.primary; local accent=spec.accent
	-- The platform is already level; portal pedestal rises in two short steps.
	makeCylinderY(m,"Pedestal",cf*CFrame.new(0,-.12,0),10.4,.24,P.stoneDark,M.Slate,true)
	makeNeonRing(m,"PedestalInlay",cf*CFrame.new(0,.055,0),4.8,.11,accent,28)
	local inner=3.35; local outer=4.48; local cy=4.50
	if spec.style=="stone" then
		for _,s in {-1,1} do
			for i=0,3 do makePart(m,"PortalAshlar",cf*CFrame.new(s*4.0,.67+i*1.35,0),V(1.65,1.30,2.0),tint(c,rng,.06),M.Slate,true) end
			makePart(m,"PortalFoot",cf*CFrame.new(s*4,.26,0),V(2.1,.52,2.3),P.stoneDark,M.Slate,true)
		end
		makePart(m,"WoodLintel",cf*CFrame.new(0,6.0,0),V(10.2,1.15,2.1),P.wood,M.WoodPlanks,true)
		makePart(m,"Keystone",cf*CFrame.new(0,6.15,1.15),V(2.15,2.0,.65),c,M.Slate,false)
		makeNeonRing(m,"Glyph",cf*CFrame.new(0,6.25,1.53)*CFrame.Angles(PI/2,0,0),.58,.10,accent,18)
	else
		for i=0,12 do
			local a=i*PI/12; local pos=V(math.cos(a)*(inner+outer)/2,cy+math.sin(a)*(inner+outer)/2,0)
			local f=cf*CFrame.new(pos)*CFrame.Angles(0,0,a-PI/2)
			makePart(m,"ArchBlock",f,V(1.04,outer-inner,1.85),tint(c,rng,.06),if spec.style=="gold" then M.SmoothPlastic else M.Slate,true)
			makePart(m,"ArchBevel",f*CFrame.new(0,0,.97),V(.89,.46,.13),c:Lerp(P.white,.29),M.SmoothPlastic,false)
		end
		for _,s in {-1,1} do
			makePart(m,"Column",cf*CFrame.new(s*3.92,2.25,0),V(1.3,4.5,1.85),c,M.Slate,true)
			makePart(m,"Foot",cf*CFrame.new(s*3.92,.35,0),V(2.0,.70,2.25),c:Lerp(P.white,.2),M.SmoothPlastic,true)
			if spec.style=="coral" or spec.style=="reef" then coralBranch(m,cf*CFrame.new(s*4.85,.10,.45)*CFrame.Angles(0,s*.6,-s*.23),P.pink,.85)
			elseif spec.style=="abyss" then makeCrystal(m,cf*CFrame.new(s*4.65,.12,.35)*CFrame.Angles(0,0,-s*.35),4.5,.70,accent,false)
			else makePart(m,"GoldTrim",cf*CFrame.new(s*3.92,2.5,1.0),V(.35,3.3,.18),accent,M.Neon,false) end
		end
		if spec.style=="gold" or spec.style=="abyss" then makeCrystal(m,cf*CFrame.new(0,8.1,.1),1.9,.73,accent,false) end
	end
	local apertureY=if spec.style=="stone" then 3.13 else 4.30
	local apertureR=if spec.style=="stone" then 2.58 else 3.17
	local diskCF=cf*CFrame.new(0,apertureY,.12)*CFrame.Angles(0,PI/2,0)
	local disk=makePart(m,"PortalSurface",diskCF,V(.22,apertureR*2,apertureR*2),accent,M.Neon,false,.32); disk.Shape=Enum.PartType.Cylinder
	local halo=cf*CFrame.new(0,apertureY,.30)*CFrame.Angles(PI/2,0,0)
	makeNeonRing(m,"ApertureRim",halo,apertureR,.15,accent,32)
	for arm=0,2 do
		local prev: Vector3?=nil
		for i=0,17 do local t=i/17; local a=arm*2*PI/3+t*PI*1.15; local r=apertureR*(.12+.84*t)
			local p=cf:PointToWorldSpace(V(math.cos(a)*r,apertureY+math.sin(a)*r,.40))
			if prev then makeSegment(m,"Swirl",prev,p,.10+.065*(1-t),accent:Lerp(P.white,.57),M.Neon) end; prev=p
		end
	end
	light(disk,accent,.85,13); emitter(disk,"PortalMotes",accent,6,NumberRange.new(.2,1.3),NumberRange.new(.7,1.5),.23)
	local signY=if spec.style=="stone" then 8.45 else 10.1
	makeSign(m,"PortalLabel",cf*CFrame.new(0,signY,.5),9.8,1.75,spec.title,spec.subtitle,accent,true)
	-- Static markers make the entrance readable without flashing or runtime scripts.
	for _,s in {-1,1} do
		makeCylinderY(m,"BeaconSocket",cf*CFrame.new(s*5.05,.26,-.55),1.18,.52,P.stoneDark,M.Slate,false)
		local beam=makeCylinderY(m,"SoftBeacon",cf*CFrame.new(s*5.05,5.0,-.55),.28,9.45,accent,M.Neon,false,.70)
		beam.CastShadow=false
	end
	local t=contractPart(contracts,"PortalTrigger",cf*CFrame.new(0,4.70,0),V(7.2,9.4,4.8),"ZonePortal")
	t.CanTouch=true; t:SetAttribute("PortalId",spec.id); t:SetAttribute("ZoneId",spec.zone); t:SetAttribute("Destination",spec.dest)
	t:SetAttribute("PrimaryColor",c); t:SetAttribute("AccentColor",accent)
	if spec.training then t:SetAttribute("TrainingIsland",spec.training) end
	if spec.id=="lagoon_to_training_1" then CollectionService:AddTag(t,"TrainingPortalGuide") end
end
local function buildPlaza(root: Model, o: Vector3, rng: Random)
	local m=makeModel(root,"Plaza")
	pavedFloor(m,o+V(-6,10.3,1),48,46,rng,3.1)
	for _,z in {-14,-2,10,20} do makeCylinderY(m,"WestFoundationPier",CFrame.new(o+V(-28.6,5.5,z)),2.6,6,P.stoneDark,M.Slate,false) end
	-- Inlaid compass motif is flush and leaves the spawn-to-workshop lane open.
	local center=o+V(2.8,10.36,-2.5)
	makeNeonRing(m,"CompassInlay",CFrame.new(center),4.7,.09,P.cyan,40)
	for i=0,7 do local a=i*PI/4; local d=V(math.cos(a),0,math.sin(a)); makeSegment(m,"CompassRay",center+d*3.9,center+d*4.6,.13,P.gold,M.Metal) end
	makeCylinderY(m,"CrystalPlinth",CFrame.new(center+V(0,.27,0)),3.4,.52,P.stoneDark,M.Slate,false)
	cluster(m,center+V(0,.52,0),rng,.72,P.cyan,true)
	makeBridge(m,o+V(-21.5,10.42,11),o+V(-10.5,10.42,11),11,rng,false)
	campfire(m,o+V(-16,10.49,11),rng)
	for _,p in {V(-23,10.4,16),V(13,10.4,-17),V(12,10.4,20),V(-25,10.4,-5)} do
		makeCylinderY(m,"Planter",CFrame.new(o+p+V(0,.4,0)),2.0,.8,P.gold,M.Slate,false); plant(m,o+p+V(0,.78,0),rng,1.3)
	end
	directionSign(m,CFrame.new(o+V(-25,10.35,2))*CFrame.Angles(0,PI/2,0),"APRENDIZ","Grátis · Treino x1","← ")
	directionSign(m,CFrame.new(o+V(-22,10.35,-11)),"SANTUÁRIO",nil,"← ")
	directionSign(m,CFrame.new(o+V(12,10.35,17)),"EXPEDIÇÕES",nil,"→ ")
	for _,p in {V(-29,10.3,22),V(16,10.3,23),V(16,10.3,-20),V(-29,10.3,-22)} do makeLantern(m,o+p,1.1,true) end
end
local function buildWorkshop(root: Model, o: Vector3, rng: Random)
	local m=makeModel(root,"Workshop")
	makeBridge(m,o+V(-26,14.3,-35),o+V(14,14.3,-35),26,rng,false)
	makeStairs(m,o+V(-6,10.3,-15),o+V(-6,14.3,-22),16,rng,false)
	local base=o+V(-6,14.3,-38); local cf=CFrame.new(base)
	-- Open storefront with traversable aisle and a counter at the server spot.
	for _,x in {-13,13} do for _,z in {-8,8} do
		makeCylinderY(m,"TimberColumn",cf*CFrame.new(x,4.8,z),1.35,9.6,P.woodDark,M.Wood,true)
		makeCylinderY(m,"ColumnFoot",cf*CFrame.new(x,.45,z),1.85,.90,P.stoneDark,M.Slate,false)
		makeCylinderY(m,"ColumnCapital",cf*CFrame.new(x,9.3,z),1.85,.65,P.woodLight,M.Wood,false)
	end end
	for i=0,9 do
		makePart(m,"BackWall",cf*CFrame.new(0,.46+i*.91,-8),V(26,.89,.68),tint(P.woodLight,rng,.055),M.WoodPlanks,true)
		for _,s in {-1,1} do makePart(m,"SideWall",cf*CFrame.new(s*13,.46+i*.91,-2.4),V(.66,.89,11.2),tint(P.woodLight,rng,.04),M.WoodPlanks,true) end
	end
	for _,s in {-1,1} do
		local angle=s*math.rad(-29); local roofCF=cf*CFrame.new(s*7,12.9,0)*CFrame.Angles(0,0,angle)
		makePart(m,"RoofSlope",roofCF,V(16,.6,19.8),P.blue,M.SmoothPlastic,false)
		for i=0,7 do for j=0,10 do
			local shift=if i%2==0 then 0 else .20
			makePart(m,"BlueRoofTile",roofCF*CFrame.new(-7.0+i*2,.38,-8.9+j*1.78+shift),V(1.96,.24,1.73),tint(P.blue,rng,.075),M.SmoothPlastic,false)
		end end
		makePart(m,"Fascia",roofCF*CFrame.new(0,-.03,10.0),V(16,.72,.65),P.woodDark,M.Wood,false)
	end
	makeSegment(m,"Ridge",base+V(0,16.9,-10.2),base+V(0,16.9,10.2),.91,P.woodDark,M.Wood)
	makeCrystal(m,cf*CFrame.new(0,17.3,0),2.2,.60,P.gold,true)
	for _,s in {-1,1} do
		makePart(m,"CrossBrace",cf*CFrame.new(s*9.5,8.1,8.05)*CFrame.Angles(0,0,s*.6),V(.55,4.2,.60),P.woodDark,M.Wood,false)
		makeCrystal(m,cf*CFrame.new(s*12.9,5.4,8.75),1.95,.53,P.cyan,true)
	end
	makeSign(m,"WorkshopSign",cf*CFrame.new(0,8.3,9.0),14.2,2.6,"OFICINA DE VARAS",nil,P.gold,false)
	makePart(m,"Counter",cf*CFrame.new(0,1.0,-1.35),V(12,2.0,2.1),P.wood,M.WoodPlanks,true)
	makePart(m,"CounterTop",cf*CFrame.new(0,2.15,-1.35),V(12.7,.30,2.55),P.woodDark,M.Wood,true)
	for _,y in {2.1,4.0,6.0} do
		makePart(m,"DisplayShelf",cf*CFrame.new(0,y,-6.7),V(19,.35,2.0),P.woodDark,M.Wood,false)
		for i=0,5 do
			local x=-8+i*3.2; local col=({P.cyan,P.gold,P.pink,P.purple,P.leaf,P.blue})[i+1]
			makeCylinderY(m,"DisplayJar",cf*CFrame.new(x,y+.52,-6.7),.64,.79,col,M.SmoothPlastic,false,.16)
			makeCylinderY(m,"Cork",cf*CFrame.new(x,y+.99,-6.7),.71,.15,P.wood,M.Wood,false)
		end
	end
	for i=0,5 do local a=base+V(-11+i*1.1,.6,-4.5); local b=a+V(.3,5.8,.6); makeSegment(m,"FishingRod",a,b,.18,if i%2==0 then P.blue else P.woodDark,M.Wood); makeCylinderY(m,"RodReel",CFrame.new(a+V(.15,1.2,0))*CFrame.Angles(0,0,PI/2),.53,.19,P.gold,M.Metal,false) end
	for _,s in {-1,1} do
		makeLantern(m,base+V(s*11.7,.07,9.2),1,true); plant(m,base+V(s*16,.05,9),rng,1.4,P.leafDark)
	end
	bunting(m,base+V(-13,7.8,8.7),base+V(-19,3.4,13.5),.55)
	bunting(m,base+V(13,7.8,8.7),base+V(19,3.4,13.5),.55)
end
local function buildEntrance(root: Model,o: Vector3,rng: Random)
	local m=makeModel(root,"EntranceStairs")
	makeStairs(m,o+V(-6,10.3,24),o+V(-6,.25,52),16,rng,false)
	gate(m,CFrame.new(o+V(-6,10.3,23.3)),14,"Legendary Catch",rng,true,false)
	for _,s in {-1,1} do
		for i=0,6 do local t=i/6; local p=o+V(-6+s*8.8,10.3-10.05*t,24+28*t); stonePost(m,p,1.25,rng)
			if i%2==0 then makeLantern(m,p+V(0,1.65,0),.72,true) end
		end
	end
	pavedFloor(m,o+V(-6,.25,54.5),16,5,rng)
end
local function buildFishing(root: Model,o: Vector3,rng: Random)
	local m=makeModel(root,"FishingPier")
	-- Exact rectangular casting pier; the curve is an additional southern branch.
	makeBridge(m,o+V(17,10.1,8),o+V(85,10.1,8),14,rng,false)
	rail(m,o+V(18,10.1,1.3),o+V(73,10.1,1.3),5.5,true)
	rail(m,o+V(18,10.1,14.7),o+V(71,10.1,14.7),5.5,true)
	gate(m,CFrame.new(o+V(25,10.1,8))*CFrame.Angles(0,-PI/2,0),10.5,"PÍER DE PESCA",rng,false,true)
	makeNeonRing(m,"CastingRing",CFrame.new(o+V(81,10.14,8)),4.65,.12,P.cyan,40)
	-- No railing or props in the server's casting circle at the eastern tip.
	for _,x in {38,54,68} do lifeRing(m,CFrame.new(o+V(x,11.65,1.05)),.79) end
	crate(m,CFrame.new(o+V(31,10.1,2.1)),1.25); barrel(m,CFrame.new(o+V(33,10.1,2.2)),1.15)
	-- A polygonal annular quay, with radial planks and continuous collision plates.
	local center=o+V(59,10.1,25); local radius=22; local width=8.8; local n=18
	for i=0,n-1 do
		local a=(i/n)*PI*.83; local b=((i+1)/n)*PI*.83; local t=(a+b)/2
		local pos=center+V(math.cos(t)*radius,0,math.sin(t)*radius)
		local radial=V(math.cos(t),0,math.sin(t)); local tangent=V(-math.sin(t),0,math.cos(t))
		local cf=CFrame.fromMatrix(pos-V(0,.33,0),radial,Vector3.yAxis,radial:Cross(Vector3.yAxis))
		local long=2*(radius+width/2)*math.tan((b-a)/2)+.08
		makePart(m,"CurvedWalkSurface",cf,V(width,.66,long),P.woodDark,M.Wood,true)
		for j=0,3 do local offset=(j-1.5)*long/4; makePart(m,"RadialPlank",CFrame.new(pos+tangent*offset-V(0,.07-i*.001,0))*CFrame.Angles(0,-t,0),V(width-.06,.16,long/4-.04),tint(P.woodLight,rng,.08),M.WoodPlanks,false) end
		if i%3==0 then local p=center+radial*(radius+width/2-.30); makeCylinderY(m,"CurvedPile",CFrame.new(p-V(0,9,0)),.86,18,P.woodDark,M.Wood,false); makeCylinderY(m,"CurvePost",CFrame.new(p+V(0,1.3,0)),.48,2.6,P.woodDark,M.Wood,false); knot(m,p+V(0,1.9,0),.31); makeLantern(m,p+V(0,2.6,0),.65,i%6==0) end
	end
	-- The arc begins at (81,25), connected to the main pier without narrowing it.
	makeBridge(m,o+V(81,10.1,14.5),o+V(81,10.1,25.8),8.8,rng,false)
	local last: Vector3?=nil
	for i=0,6 do local a=i/6*PI*.83; local p=center+V(math.cos(a)*(radius+width/2-.3),1.9,math.sin(a)*(radius+width/2-.3)); if last then makeRope(m,last,p,.35) end; last=p end
	local arcEnd=center+V(math.cos(PI*.83)*radius,0,math.sin(PI*.83)*radius)
	makeBridge(m,arcEnd,o+V(46,10.1,31.7),8.8,rng,false)
	barrel(m,CFrame.new(o+V(61,10.1,47)),1.3); crate(m,CFrame.new(o+V(64,10.1,46)),1.6)
	local mast=o+V(73,10.1,42); makeCylinderY(m,"NetMast",CFrame.new(mast+V(0,3,0)),.66,6,P.woodDark,M.Wood,false); knot(m,mast+V(0,5.5,0),.39)
	makeSegment(m,"NetYard",mast+V(-2.3,5.5,0),mast+V(2.3,5.5,0),.30,P.wood,M.Wood)
	net(m,CFrame.new(mast+V(0,5.4,0)),3.8,3.1)
end
local function buildExpeditions(root: Model, contracts: Instance,o: Vector3,rng: Random)
	local m=makeModel(root,"ExpeditionWharf")
	makeBridge(m,o+V(14,10.3,22),o+V(24,10.3,22),10,rng,false)
	-- Stone platform over water, with four bays (two active, two future).
	pavedFloor(m,o+V(45,10.3,25),44,14,rng)
	for _,x in {24,36,50,61} do for _,z in {19,31} do makeCylinderY(m,"StonePiling",CFrame.new(o+V(x,3.8,z)),2.0,12.0,P.stoneDark,M.Slate,false) end end
	gate(m,CFrame.new(o+V(24,10.3,25))*CFrame.Angles(0,-PI/2,0),9.5,"CAIS DAS EXPEDIÇÕES",rng,false,true)
	for i=1,2 do local x=32+(i-1)*11; makePortal(m,contracts,CFrame.new(o+V(x,10.3,28))*CFrame.Angles(0,PI,0),PORTALS[i],rng) end
	for i=0,1 do
		local x=54+i*7.0; local pos=o+V(x,10.34,28.4)
		makeCylinderY(m,"FuturePortalBase",CFrame.new(pos+V(0,.17,0)),6.2,.34,P.stone,M.Slate,false)
		makeNeonRing(m,"FutureSocket",CFrame.new(pos+V(0,.38,0)),2.5,.10,P.stoneDark,20)
		cluster(m,pos+V(0,.40,0),rng,.45,P.stoneDark,false)
		makeSign(m,"FutureBay",CFrame.new(pos+V(0,2.8,-.7))*CFrame.Angles(0,PI,0),5.6,1.0,"EM BREVE",nil,P.stoneDark,true)
	end
	rail(m,o+V(24,10.3,31.8),o+V(63,10.3,31.8),5.0,true)
	for _,x in {25,48,61} do makeLantern(m,o+V(x,10.3,18.4),.82,true) end
	crate(m,CFrame.new(o+V(26,10.3,19.1)),1.2); barrel(m,CFrame.new(o+V(28,10.3,19.2)),1.05)
	lifeRing(m,CFrame.new(o+V(58,11.2,31.6)),.75)
	net(m,CFrame.new(o+V(49,10.2,32.0)),4.6,3.4)
end
local function buildSanctuary(root: Model,contracts: Instance,o: Vector3,rng: Random)
	local m=makeModel(root,"TrainingSanctuary")
	-- A wide stair climbs west from the plaza, then turns north onto the upper terrace.
	makeStairs(m,o+V(-27,10.3,-17),o+V(-51,21,-17),9.4,rng,true)
	gate(m,CFrame.new(o+V(-29,11.2,-17))*CFrame.Angles(0,PI/2,0),9.0,"SANTUÁRIO DO TREINO",rng,true,true)
	pavedFloor(m,o+V(-54,21,-17),6,10,rng,3.0)
	makeBridge(m,o+V(-53,21,-22),o+V(-53,21,-25),9.4,rng,true)
	pavedFloor(m,o+V(-55,21,-37),48,24,rng,3.5)
	for _,z in {-47.9,-26.2} do for _,x in {-77,-65,-43,-33} do makeLantern(m,o+V(x,21,z),.85,true) end end
	for _,s in {-1,1} do
		for i=0,4 do local t=i/4; local p=o+V(-29-20*t,11.2+9.0*t,-17+s*5.1); stonePost(m,p,1.2,rng); if i%2==0 then makeLantern(m,p+V(0,1.6,0),.7,true) end end
	end
	local runeCenter=o+V(-55,21.09,-30.5)
	makeNeonRing(m,"RuneCircleOuter",CFrame.new(runeCenter),4.3,.13,P.cyan,40)
	makeNeonRing(m,"RuneCircleInner",CFrame.new(runeCenter),3.15,.08,P.cyan,32)
	for i=0,11 do local a=i*PI/6; local r=V(math.cos(a),0,math.sin(a)); local t=V(-r.Z,0,r.X); local p=runeCenter+r*3.74
		makeSegment(m,"RuneStroke",p-t*.25,p+t*.25,.09,P.cyan,M.Neon); makeSegment(m,"RuneStroke",p,p+r*.32,.09,P.cyan,M.Neon)
	end
	for i=0,3 do makePortal(m,contracts,CFrame.new(o+V(-72+11.4*i,21,-41.3)),PORTALS[i+3],rng) end
	for _,x in {-77.6,-32.4} do cluster(m,o+V(x,21,-28),rng,.72,P.cyan,true) end
end
local function buildLagoon(root: Model,contracts: Instance,o: Vector3,rng: Random)
	local m=makeModel(root,"LagoonGate")
	makeBridge(m,o+V(-29,10.3,-5.5),o+V(-52,10.3,-5.5),10.5,rng,false)
	-- Lanterns and rope are split at the portal so nothing crosses its entrance.
	for _,z in {-10.2,-.8} do rail(m,o+V(-29,10.3,z),o+V(-52,10.3,z),5.0,true) end
	makePortal(m,contracts,CFrame.new(o+V(-46,10.3,-5.5))*CFrame.Angles(0,PI/2,0),PORTALS[7],rng)
	-- Decorative waterfall flows beside the bridge, not across its walkable floor.
	local cliffY=math.max(15.0, (floorRay(o,-56.5,-15) or 17)+.55)
	local waterOrigin=o+V(-56.5,cliffY,-15); local foot=o+V(-56.5,8.1,0.5)
	local rock=makeEllipsoid(m,"WaterfallLedge",CFrame.new(waterOrigin+V(0,-.75,-.6)),V(10,2.4,5),P.stoneDark,M.Slate,false)
	rock.CastShadow=true
	local streamStart=waterOrigin+V(0,.28,0); local lip=o+V(-56.5,cliffY-.7,-12.2); local middle=o+V(-56.5,12.0,-6.0)
	-- Layered sheets approximate a stylized flowing ribbon. The basin itself is native Water.
	local nodes={streamStart,lip,middle,foot}
	for i=1,#nodes-1 do
		local a,b=nodes[i],nodes[i+1]; local d=b-a; local up=d.Unit; local right=Vector3.xAxis; local back=right:Cross(up)
		local cf=CFrame.fromMatrix((a+b)/2,right,up,back)
		makePart(m,"WaterRibbon",cf,V(5.6,d.Magnitude+.16,.34),RGB(102,210,251),M.Glass,false,.25)
		for j=0,4 do makePart(m,"WaterStreak",cf*CFrame.new(-2.2+j*1.1,0,.23),V(.40+rng:NextNumber(0,.17),d.Magnitude,.11),P.white,M.SmoothPlastic,false,.36) end
	end
	local foam=makeEllipsoid(m,"Foam",CFrame.new(foot),V(6.6,.65,4.4),P.white,M.SmoothPlastic,false,.22)
	local mist=emitter(foam,"WaterMist",P.white,14,NumberRange.new(.45,1.9),NumberRange.new(.6,1.4),1.2,"rbxasset://textures/particles/smoke_main.dds"); mist.Acceleration=V(0,.5,0); mist.LightEmission=.18
	for i=0,7 do local a=i*PI/4; makeEllipsoid(m,"FoamBubble",CFrame.new(foot+V(math.cos(a)*2.7,.18,math.sin(a)*1.6)),V(.75,.33,.66),P.white,M.SmoothPlastic,false,.18) end
	for _,v in {V(-48,8.06,5),V(-43,8.06,8),V(-38,8.06,4),V(-51,8.06,9),V(-45,8.06,13),V(-34,8.06,7),V(-55,8.06,4)} do
		local p=o+v; local s=rng:NextNumber(1.5,2.5); makeCylinderY(m,"LilyPad",CFrame.new(p),s,.10,P.leaf,M.SmoothPlastic,false)
		if rng:NextNumber()<.65 then blossom(m,p+V(.2,.11,.12),rng,.8) end
	end
	-- Cherry blossom tree, grounded by raycast on the western cliff.
	local tree=makeModel(m,"BlossomTree"); local base=onGround(o,-58,-14); local trunkTop=base+V(1,8.5,-.5)
	makeSegment(tree,"Trunk",base,trunkTop,1.65,P.woodDark,M.Wood,false)
	for i=0,5 do local a=i*PI/3; local endP=trunkTop+V(math.cos(a)*3.6,2.4+math.sin(a)*.6,math.sin(a)*3.6); makeSegment(tree,"Branch",base+V(.7,5.7,-.3),endP,.72,P.wood,M.Wood,false)
		for j=0,6 do local angle=j*PI*2/7; local p=endP+V(math.cos(angle)*1.5,rng:NextNumber(-.6,1.4),math.sin(angle)*1.5); makeEllipsoid(tree,"BlossomCanopy",CFrame.new(p),V(3.2,2.8,3.5)*rng:NextNumber(.75,1.2),tint(P.pink,rng,.09),M.SmoothPlastic,false) end
	end
	local canopy=makeEllipsoid(tree,"Crown",CFrame.new(trunkTop+V(0,3.4,0)),V(7,4.0,7),P.pink,M.SmoothPlastic,false)
	local petals=emitter(canopy,"FallingPetals",P.pink,4,NumberRange.new(.1,.5),NumberRange.new(2,4),.4); petals.Acceleration=V(.25,-1.8,.1); petals.LightEmission=0
	for i=1,9 do local a=rng:NextNumber(0,PI*2); local p=base+V(math.cos(a)*2.0,.12,math.sin(a)*2.0); blossom(tree,p,rng,.55) end
end
local function buildAquarium(root: Model,o: Vector3,rng: Random)
	local m=makeModel(root,"Aquarium")
	-- Deck is at Y=8 as contracted, with a walkable stair from the plaza.
	makeStairs(m,o+V(-24,10.3,23),o+V(-24,8,35),6.5,rng,false)
	makeBridge(m,o+V(-22,8,38),o+V(-25,8,38),10,rng,false)
	makeBridge(m,o+V(-37.5,8,33),o+V(-37.5,8,62),25,rng,false)
	for _,x in {-49.6,-25.4} do rail(m,o+V(x,8,44),o+V(x,8,61.6),5.0,true) end
	rail(m,o+V(-49.6,8,61.6),o+V(-25.4,8,61.6),5.0,true)
	local cf=CFrame.new(o+V(-39,8,50)); local width,depth,height=14,7,5
	makePart(m,"DisplayBase",cf*CFrame.new(0,.37,0),V(width+.6,.74,depth+.6),P.woodDark,M.Wood,true)
	makePart(m,"DisplaySand",cf*CFrame.new(0,.79,0),V(width-.2,.18,depth-.2),RGB(235,218,178),M.Sand,false)
	makePart(m,"DisplayWater",cf*CFrame.new(0,2.7,0),V(width-.22,3.62,depth-.22),RGB(85,211,241),M.Glass,false,.77)
	for _,s in {-1,1} do
		makePart(m,"DisplayGlass",cf*CFrame.new(s*width/2,3.1,0),V(.15,height,depth),RGB(177,239,252),M.Glass,true,.80)
		makePart(m,"DisplayGlass",cf*CFrame.new(0,3.1,s*depth/2),V(width,height,.15),RGB(177,239,252),M.Glass,true,.80)
		makePart(m,"TopFrame",cf*CFrame.new(0,5.62,s*depth/2),V(width+.30,.20,.26),P.woodDark,M.Wood,false)
		makePart(m,"TopFrame",cf*CFrame.new(s*width/2,5.62,0),V(.26,.20,depth+.30),P.woodDark,M.Wood,false)
		for _,z in {-1,1} do makePart(m,"CornerFrame",cf*CFrame.new(s*width/2,3.1,z*depth/2),V(.26,height,.26),P.gold,M.Metal,false) end
	end
	for i=0,3 do local p=cf:PointToWorldSpace(V(-5+i*3.2,.9,if i%2==0 then -1.8 else 1.5)); plant(m,p,rng,.85,P.leafDark) end
	makeSign(m,"AquariumSign",cf*CFrame.new(0,6.5,3.7),9.5,1.6,"AQUÁRIO",nil,P.gold,false)
end
local function buildDecor(root: Model,o: Vector3,rng: Random)
	local m=makeModel(root,"Decor")
	for _,p in {V(-22,0,-57),V(-15,0,-60),V(12,0,-59),V(-36,0,-52),V(22,0,-41),V(-72,0,14),V(-71,0,18),V(-67,0,-20),V(-18,0,35),V(29,0,-19),V(-75,0,9),V(-32,0,29),V(-80,0,-13),V(-60,0,17)} do
		local at=onGround(o,p.X,p.Z); if at.Y>o.Y-3 then cluster(m,at,rng,rng:NextNumber(.8,1.5),if rng:NextNumber()<.3 then P.pink else P.cyan,rng:NextNumber()<.38) end
	end
	for _,p in {V(-26,0,-53),V(16,0,-47),V(-70,0,4)} do makePalm(m,onGround(o,p.X,p.Z),rng,1.0) end
	for i=1,40 do
		local x,z=rng:NextNumber(-76,26),rng:NextNumber(-70,43)
		local h=terrainHeight(x,z)
		local protected=rect(x,z,-34,21,-51,26) or rect(x,z,-81,-29,-50,-11) or rect(x,z,-57,-24,-12,1) or rect(x,z,-25,11,23,57) or lagoonRadius(x,z)<2
		if not protected and h>2 and h<26 then local pos=onGround(o,x,z); plant(m,pos,rng,rng:NextNumber(.65,1.5)); if i%3==0 then blossom(m,pos+V(.7,.15,.2),rng,.62) end end
	end
	-- Shallow reef stones are noncolliding decorations outside the stair channel.
	for _,s in {-1,1} do for i=1,8 do
		local z=28+i*3.4; local x=-6+s*(10+rng:NextNumber(0,3)); local p=onGround(o,x,z)
		makeEllipsoid(m,"ReefPebble",CFrame.new(p+V(0,.22,0))*CFrame.Angles(0,rng:NextNumber(0,PI),0),V(2.2,1.6,2.6)*rng:NextNumber(.6,1.2),P.stoneDark,M.Slate,false)
	end end
end
local function buildContract(root: Model,contracts: Folder,o: Vector3)
	contractPart(contracts,"PlayerSpawn",CFrame.lookAt(o+V(-6,10.4,11.5),o+V(-6,10.4,10.5)),V(8,.2,8),"PlayerSpawn")
	local fish=contractPart(contracts,"FishingZone",CFrame.new(o+V(63,14.1,8)),V(46,10,14),"FishingZone"); fish:SetAttribute("ZoneId","lagoon")
	contractPart(contracts,"WorkshopSpot",CFrame.new(o+V(-6,15.5,-38)),V(1,1,1),"WorkshopSpot")
	local boards=makeModel(root,"LeaderboardFrames")
	for i=0,2 do
		-- Three separate faces over the western sea, angled toward the plaza.
		local cf=CFrame.new(o+V(-87+i*17,36,27))*CFrame.Angles(0,-math.rad(32),0)
		local board=contractPart(contracts,"LeaderboardBoard",cf,V(14,9,.6),"LeaderboardBoard"); board.Transparency=0; board.Color=P.dark
		makePart(boards,"LeaderboardBacking",cf*CFrame.new(0,0,.47),V(14.8,9.8,.34),P.woodDark,M.Wood,false)
		for _,s in {-1,1} do
			makePart(boards,"BoardTrim",cf*CFrame.new(s*7.18,0,-.06),V(.29,9.55,.36),P.gold,M.Metal,false)
			makePart(boards,"BoardTrim",cf*CFrame.new(0,s*4.68,-.06),V(14.65,.26,.36),P.gold,M.Metal,false)
		end
	end
end
function Builder.build(origin: Vector3?): Model
	local o=origin or DEFAULT_ORIGIN
	assert(o.Y%RES==0,"Origin.Y must be on the four-stud terrain grid")
	local rng=Random.new(SEED)
	local existing=Workspace:FindFirstChild("HubNew")
	if existing then
		assert(existing:IsA("Model") and existing:GetAttribute("HubBuilderOwned")==true,"HubNew exists and is not owned by this builder")
		assert(existing:GetAttribute("Origin")==o,"HubNew is at a different origin; use a separate place copy or remove the previous model and terrain explicitly")
		existing:Destroy()
	end
	buildTerrain(o)
	-- Publish only after construction; use an isolated edit-mode copy for comparisons.
	local root=Instance.new("Model"); root.Name="HubNew"; root:SetAttribute("HubBuilderOwned",true); root:SetAttribute("Origin",o); root:SetAttribute("Seed",SEED)
	local contracts=makeFolder(root,"Contract")
	buildPlaza(root,o,rng); task.wait()
	buildWorkshop(root,o,rng); task.wait()
	buildEntrance(root,o,rng); buildFishing(root,o,rng); task.wait()
	buildExpeditions(root,contracts,o,rng); task.wait()
	buildSanctuary(root,contracts,o,rng); task.wait()
	buildLagoon(root,contracts,o,rng); task.wait()
	buildAquarium(root,o,rng); buildDecor(root,o,rng); task.wait()
	buildContract(root,contracts,o)
	local parts,lights,emitters=0,0,0
	for _,d in root:GetDescendants() do
		if d:IsA("BasePart") then parts+=1 elseif d:IsA("PointLight") then lights+=1 elseif d:IsA("ParticleEmitter") then emitters+=1 end
	end
	root:SetAttribute("PartCount",parts); root:SetAttribute("LightCount",lights); root:SetAttribute("EmitterCount",emitters)
	root.Parent=Workspace
	return root
end
local function sameVector(a: Vector3,b: Vector3): boolean return (a-b).Magnitude<.08 end
local function validatePart(fail: {string},p: Instance?,label: string,pos: Vector3,size: Vector3,tag: string)
	if not p or not p:IsA("BasePart") then table.insert(fail,label.." missing"); return end
	if not sameVector(p.Position,pos) then table.insert(fail,label.." position mismatch") end
	if not sameVector(p.Size,size) then table.insert(fail,label.." size mismatch") end
	if not p.Anchored or p.CanCollide or p.CanQuery or p.Transparency~=1 then table.insert(fail,label.." physics/visibility mismatch") end
	if not CollectionService:HasTag(p,tag) then table.insert(fail,label.." tag missing: "..tag) end
end
local function checkRoute(fail: {string},root: Model,o: Vector3,label: string,points: {Vector3})
	local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include; params.FilterDescendantsInstances={root}; params.IgnoreWater=true; params.RespectCanCollide=true
	local previous: number?=nil
	for i=1,#points-1 do
		local a,b=points[i],points[i+1]; local n=math.max(1,math.ceil((b-a).Magnitude/.65))
		for j=0,n do
			local p=a:Lerp(b,j/n); local hit=Workspace:Raycast(o+p+V(0,1.65,0),V(0,-3.4,0),params)
			if not hit or not hit.Instance:IsA("BasePart") or not hit.Instance.CanCollide then table.insert(fail,string.format("%s: missing floor at %.1f %.1f %.1f",label,p.X,p.Y,p.Z)); return end
			if previous and math.abs(hit.Position.Y-previous)>3 then table.insert(fail,label..": floor height jump > 3 studs"); return end
			previous=hit.Position.Y
			local head=Workspace:Raycast(o+p+V(0,.8,0),V(0,4.0,0),params)
			if head then table.insert(fail,string.format("%s: overhead collision at %.1f %.1f",label,p.X,p.Z)); return end
		end
	end
end
function Builder.report(origin: Vector3?): string
	local o=origin or DEFAULT_ORIGIN; local lines={"Hub terrain (solid height, relative to origin)"}
	for _,p in {V(-6,0,11.5),V(-6,0,0),V(-20,0,4),V(6,0,4),V(-6,0,-16),V(-6,0,-35),V(-20,0,-30),V(8,0,-30),V(-6,0,30),V(-6,0,45),V(14,0,8),V(-44,0,2),V(-6,0,-62)} do
		local h=floorRay(o,p.X,p.Z); table.insert(lines,string.format("X %.1f Z %.1f: %s",p.X,p.Z,if h then string.format("%.2f",h) else "no solid hit"))
	end
	return table.concat(lines,"\n")
end
function Builder.selfTest(origin: Vector3?): {string}
	local o=origin or DEFAULT_ORIGIN; local fail: {string}={}
	local root=Workspace:FindFirstChild("HubNew")
	if not root or not root:IsA("Model") then return {"HubNew model missing"} end
	if root:GetAttribute("Origin")~=o then return {"HubNew origin does not match selfTest origin"} end
	local c=root:FindFirstChild("Contract"); if not c then return {"Contract folder missing"} end
	validatePart(fail,c:FindFirstChild("PlayerSpawn"),"PlayerSpawn",o+V(-6,10.4,11.5),V(8,.2,8),"PlayerSpawn")
	validatePart(fail,c:FindFirstChild("FishingZone"),"FishingZone",o+V(63,14.1,8),V(46,10,14),"FishingZone")
	validatePart(fail,c:FindFirstChild("WorkshopSpot"),"WorkshopSpot",o+V(-6,15.5,-38),V(1,1,1),"WorkshopSpot")
	local sp=c:FindFirstChild("PlayerSpawn"); if sp and sp:IsA("BasePart") and sp.CFrame.LookVector:Dot(V(0,0,-1))<.999 then table.insert(fail,"PlayerSpawn direction") end
	local fish=c:FindFirstChild("FishingZone")
	if fish and fish:IsA("BasePart") then
		if fish:GetAttribute("ZoneId")~="lagoon" then table.insert(fail,"FishingZone ZoneId") end
		local tip=fish.CFrame:PointToObjectSpace(o+V(81,10.1,8)); local half=fish.Size/2
		if math.abs(tip.X)>half.X or math.abs(tip.Y)>half.Y or math.abs(tip.Z)>half.Z then table.insert(fail,"FishingZone excludes casting point") end
	end
	local portalCount,guideCount,boardCount=0,0,0; local found: {[string]: BasePart}={}
	for _,p in c:GetChildren() do
		if p:IsA("BasePart") and CollectionService:HasTag(p,"ZonePortal") then
			portalCount+=1; local id=p:GetAttribute("PortalId")
			if typeof(id)~="string" then table.insert(fail,"PortalId missing") elseif found[id] then table.insert(fail,"Duplicate PortalId "..id) else found[id]=p end
			if CollectionService:HasTag(p,"TrainingPortalGuide") then guideCount+=1 end
		elseif p:IsA("BasePart") and CollectionService:HasTag(p,"LeaderboardBoard") then
			boardCount+=1; if p.Name~="LeaderboardBoard" or p.Transparency~=0 or p.CanCollide or p.CanQuery or not p.Anchored or not sameVector(p.Size,V(14,9,.6)) then table.insert(fail,"Leaderboard contract mismatch") end
		end
	end
	if portalCount~=7 or guideCount~=1 or boardCount~=3 then table.insert(fail,"Expected 7 portals, 1 tutorial guide, 3 boards") end
	for _,spec in PORTALS do
		local p=found[spec.id]
		if not p then table.insert(fail,"Missing portal "..spec.id) else
			if p.Name~="PortalTrigger" or not sameVector(p.Size,V(7.2,9.4,4.8)) or p.CanCollide or p.CanQuery or not p.CanTouch or p.Transparency~=1 or not p.Anchored then table.insert(fail,"Trigger physics: "..spec.id) end
			if p:GetAttribute("ZoneId")~=spec.zone or p:GetAttribute("Destination")~=spec.dest or p:GetAttribute("TrainingIsland")~=spec.training or p:GetAttribute("PrimaryColor")~=spec.primary or p:GetAttribute("AccentColor")~=spec.accent then table.insert(fail,"Trigger attributes: "..spec.id) end
			if CollectionService:HasTag(p,"TrainingPortalGuide")~=(spec.id=="lagoon_to_training_1") then table.insert(fail,"Guide tag: "..spec.id) end
		end
	end
	local guide=found.lagoon_to_training_1; if guide and not sameVector(guide.Position,o+V(-46,15,-5.5)) then table.insert(fail,"Tutorial portal position") end
	for _,name in {"Plaza","Workshop","EntranceStairs","FishingPier","ExpeditionWharf","TrainingSanctuary","LagoonGate","Aquarium","Decor"} do if not root:FindFirstChild(name) then table.insert(fail,"Missing region "..name) end end
	for _,d in root:GetDescendants() do if d:IsA("LuaSourceContainer") then table.insert(fail,"Unexpected script "..d:GetFullName()) end end
	for x=-30,18,4 do for z=-22,24,4 do local h=floorRay(o,x,z); if not h or h>9.2 then table.insert(fail,string.format("Plaza terrain at %d,%d: %s",x,z,tostring(h))) end end end
	for x=-23,11,4 do for z=-48,-24,4 do local h=floorRay(o,x,z); if not h or h>13.5 then table.insert(fail,string.format("Workshop terrain at %d,%d: %s",x,z,tostring(h))) end end end
	for _,z in {30,45} do local h=floorRay(o,-6,z); if h and h>0.5 then table.insert(fail,"Stair channel obstructed at Z="..z) end end
	local lagoon=floorRay(o,-44,2); if not lagoon or math.abs(lagoon-4)>1.4 then table.insert(fail,"Lagoon sand height: "..tostring(lagoon)) end
	local waterParams=RaycastParams.new(); waterParams.FilterType=Enum.RaycastFilterType.Include; waterParams.FilterDescendantsInstances={Terrain}; waterParams.IgnoreWater=false
	local water=Workspace:Raycast(o+V(-44,40,2),V(0,-50,0),waterParams)
	if not water or water.Material~=M.Water or math.abs(water.Position.Y-o.Y-8)>1.4 then table.insert(fail,"Lagoon water surface not at Y=8") end
	local hill=floorRay(o,-6,-62); if not hill or hill<25 then table.insert(fail,"Workshop hill below Y=25") end
	checkRoute(fail,root,o,"Spawn to workshop",{V(-6,10.3,11.5),V(-6,10.3,-15),V(-6,14.3,-22),V(-6,14.3,-34)})
	checkRoute(fail,root,o,"Spawn to entrance",{V(-6,10.3,11.5),V(-6,10.3,24),V(-6,.25,51.7)})
	checkRoute(fail,root,o,"Spawn to fishing tip",{V(-6,10.3,11.5),V(8,10.3,8),V(17.1,10.1,8),V(81,10.1,8)})
	checkRoute(fail,root,o,"Spawn to expeditions",{V(-6,10.3,11.5),V(13,10.3,22),V(24,10.3,22),V(32,10.3,22),V(32,10.3,28)})
	checkRoute(fail,root,o,"Expedition abyss portal",{V(43,10.3,22),V(43,10.3,28)})
	checkRoute(fail,root,o,"Spawn to training",{V(-6,10.3,11.5),V(-15,10.3,-13),V(-27,10.3,-17),V(-51,21,-17),V(-51,21,-28),V(-55,21,-31),V(-55,21,-36)})
	checkRoute(fail,root,o,"Spawn to apprentice",{V(-6,10.3,11.5),V(-13,10.3,-5.5),V(-29,10.3,-5.5),V(-46,10.3,-5.5)})
	checkRoute(fail,root,o,"Aquarium access",{V(-24,10.3,23),V(-24,8,35),V(-25,8,38),V(-37,8,40)})
	for i=0,3 do local x=-72+11.4*i; checkRoute(fail,root,o,"Training portal "..(i+1),{V(x,21,-34),V(x,21,-41.3)}) end
	return fail
end
return Builder
