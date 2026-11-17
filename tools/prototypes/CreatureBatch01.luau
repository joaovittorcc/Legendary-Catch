--!nocheck
-- FISH CLICKER / NOVO JOGO DE CRIATURAS - LOTE 01
-- Gerador EDITAVEL de 10 modelos 3D estilizados no Roblox Studio
-- Execucao unica: colar TODO o codigo na Command Bar (modo Edicao, nao Play)
-- Os modelos ficam em ReplicatedStorage > FishClicker_Criaturas_V1
-- Um showroom separado aparece em Workspace > FishClicker_Criaturas_Showroom_V1
-- Feito com Part, WedgePart e materiais nativos (sem assets externos).
-- IMPORTANTE: modelos sao prototipos visuais ancorados; nao sao rigs animados.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SHOW_SHOWROOM = false
local SHOWROOM_ORIGIN = Vector3.new(0, 85, -450)
local PREFABS_FOLDER_NAME = "Creatures"
local SHOWROOM_FOLDER_NAME = "FishClicker_Criaturas_Showroom_V1"

-- Protecao: nunca apaga trabalho anterior sem o usuario decidir.
if ReplicatedStorage:FindFirstChild(PREFABS_FOLDER_NAME) then
	error(
		"Ja existe ReplicatedStorage/"
			.. PREFABS_FOLDER_NAME
			.. ". Salve uma copia ou renomeie a pasta anterior antes de executar novamente."
	)
end
if SHOW_SHOWROOM and Workspace:FindFirstChild(SHOWROOM_FOLDER_NAME) then
	error(
		"Ja existe Workspace/"
			.. SHOWROOM_FOLDER_NAME
			.. ". Renomeie ou mova antes de executar novamente."
	)
end

local function C(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local M = Enum.Material
local function geometry(model, name, primitive, x, y, z, sx, sy, sz, color, material, rz, rx, ry)
	local className = primitive == "Wedge" and "WedgePart" or "Part"
	local p = Instance.new(className)
	p.Name = name
	if primitive == "Ball" then
		p.Shape = Enum.PartType.Ball
	elseif primitive == "Cylinder" then
		p.Shape = Enum.PartType.Cylinder
	else
		if primitive ~= "Wedge" then
			p.Shape = Enum.PartType.Block
		end
	end
	p.Size = Vector3.new(sx, sy, sz)
	p.Color = color
	p.Material = material or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = true
	p.CFrame = CFrame.new(x, y, z)
		* CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
	p.Parent = model
	return p
end
local function o(m, n, x, y, z, sx, sy, sz, c, mat, rz, rx, ry)
	return geometry(m, n, "Ball", x, y, z, sx, sy, sz, c, mat, rz, rx, ry)
end
local function b(m, n, x, y, z, sx, sy, sz, c, mat, rz, rx, ry)
	return geometry(m, n, "Block", x, y, z, sx, sy, sz, c, mat, rz, rx, ry)
end
local function w(m, n, x, y, z, sx, sy, sz, c, mat, rz, rx, ry)
	return geometry(m, n, "Wedge", x, y, z, sx, sy, sz, c, mat, rz, rx, ry)
end
local function eye(m, tag, x, y, z, side, scale, bright)
	local d = side == -1 and -1 or 1
	local s = scale or 1
	o(m, tag .. "_Contorno", x, y, z * d, 0.42 * s, 0.43 * s, 0.15 * s, C(23, 28, 55))
	o(
		m,
		tag .. "_Branco",
		x - 0.015 * s,
		y + 0.012 * s,
		(z + 0.092 * s) * d,
		0.34 * s,
		0.35 * s,
		0.15 * s,
		C(252, 250, 255)
	)
	o(
		m,
		tag .. "_Pupila",
		x - 0.07 * s,
		y + 0.005 * s,
		(z + 0.183 * s) * d,
		0.19 * s,
		0.23 * s,
		0.105 * s,
		bright or C(22, 38, 65)
	)
	o(
		m,
		tag .. "_Brilho",
		x - 0.11 * s,
		y + 0.095 * s,
		(z + 0.24 * s) * d,
		0.080 * s,
		0.095 * s,
		0.045 * s,
		C(255, 255, 255),
		M.Neon
	)
end
local function leaf(m, tag, x, y, z, sx, sy, sz, col, angle)
	o(m, tag, x, y, z, sx, sy, sz, col, M.SmoothPlastic, angle or 0)
end
local function tail(m, x, y, z, col, factor)
	local s = factor or 1
	leaf(m, "Cauda_Superior", x + 0.20 * s, y + 0.37 * s, z, 0.95 * s, 0.54 * s, 0.25 * s, col, 35)
	leaf(m, "Cauda_Inferior", x + 0.20 * s, y - 0.37 * s, z, 0.95 * s, 0.54 * s, 0.25 * s, col, -35)
	o(m, "Cauda_Juncao", x - 0.18 * s, y, z, 0.52 * s, 0.38 * s, 0.32 * s, col)
end
local function glow(m, name, x, y, z, sx, sy, sz, color)
	return o(m, name, x, y, z, sx, sy, sz, color, M.Neon)
end
local function newModel(id, label, rarity, tier, summary, scale)
	local m = Instance.new("Model")
	m.Name = id
	local pivot = b(m, "_PIVOT", 0, 0, 0, 0.15, 0.15, 0.15, C(255, 255, 255))
	pivot.Transparency = 1
	pivot.CastShadow = false
	m.PrimaryPart = pivot
	m:SetAttribute("CreatureID", id)
	m:SetAttribute("DisplayName", label)
	m:SetAttribute("Rarity", rarity)
	m:SetAttribute("ChallengeTier", tier)
	m:SetAttribute("Origin", "Oceano inicial - proposta")
	m:SetAttribute("VisualSummary", summary)
	m:SetAttribute("PreviewScale", scale or 1)
	m:SetAttribute("HiddenUntilCaught", true)
	return m
end

local rar = {
	["Comum"] = C(111, 228, 164),
	["Incomum"] = C(71, 201, 255),
	["Raro"] = C(191, 124, 255),
	["Epico"] = C(255, 106, 222),
	["Lendario"] = C(255, 204, 69),
}

local rarityLabel = {
	Comum = "COMUM",
	Incomum = "INCOMUM",
	Raro = "RARO",
	Epico = "ÉPICO",
	Lendario = "LENDÁRIO",
}

local function make01()
	local m = newModel(
		"C01_Bolhinha_Azul",
		"Bolhinha Azul",
		"Comum",
		1,
		"Peixinho redondo turquesa e sorridente",
		1.0
	)
	o(m, "Corpo_Turquesa", 0, 0, 0, 3.2, 1.95, 1.7, C(47, 204, 239))
	o(m, "Barriguinha_Clara", -0.22, -0.40, 0.09, 2.57, 1.02, 1.63, C(117, 244, 248))
	tail(m, 1.75, 0.0, 0, C(20, 139, 232), 1.0)
	leaf(m, "Barbatana_Dorsal", 0.18, 1.08, 0, 0.84, 0.79, 0.32, C(38, 156, 244), 65)
	leaf(m, "Barbatana_Lateral", -0.10, -0.22, 0.84, 0.73, 0.51, 0.19, C(19, 157, 213), -30)
	leaf(m, "Barbatana_Oposta", -0.10, -0.22, -0.84, 0.73, 0.51, 0.19, C(19, 157, 213), -30)
	eye(m, "Olho_Direito", -0.94, 0.27, 0.73, 1, 0.90)
	eye(m, "Olho_Esquerdo", -0.94, 0.27, 0.73, -1, 0.90)
	o(m, "Boquinha", -1.60, -0.35, 0, 0.25, 0.22, 0.40, C(243, 111, 149))
	o(m, "Bochecha", -1.07, -0.27, 0.80, 0.32, 0.17, 0.07, C(255, 158, 187))
	glow(m, "Bolha_Magica_01", 1.18, 0.71, 0.44, 0.15, 0.15, 0.15, C(220, 255, 255))
	glow(m, "Bolha_Magica_02", 0.83, 0.95, 0.22, 0.11, 0.11, 0.11, C(220, 255, 255))
	return m
end
local function make02()
	local m = newModel(
		"C02_Sardinha_Solar",
		"Sardinha Solar",
		"Comum",
		1,
		"Peixe veloz com faixas quentes e ventre dourado",
		1.0
	)
	o(m, "Corpo_Azul", 0, 0, 0, 4.2, 1.35, 1.32, C(65, 153, 226))
	o(m, "Flanco_Claro", -0.18, -0.30, 0.02, 3.65, 0.80, 1.30, C(175, 228, 244))
	tail(m, 2.24, 0.0, 0, C(255, 168, 59), 1.0)
	leaf(m, "Dorsal_Dourada", 0.12, 0.81, 0, 1.00, 0.66, 0.21, C(255, 198, 70), 51)
	leaf(m, "Peitoral", -0.10, -0.29, 0.66, 0.93, 0.39, 0.15, C(255, 193, 84), -28)
	for i = 1, 4 do
		o(
			m,
			"Marca_Solar_" .. i,
			-1.03 + i * 0.58,
			0.25,
			0.62,
			0.21,
			0.35,
			0.09,
			C(255, 227, 91),
			M.Neon,
			24
		)
	end
	eye(m, "Olho_Direito", -1.42, 0.18, 0.52, 1, 0.73)
	eye(m, "Olho_Esquerdo", -1.42, 0.18, 0.52, -1, 0.73)
	o(m, "Labio", -2.13, -0.14, 0, 0.22, 0.13, 0.29, C(246, 185, 120))
	return m
end
local function make03()
	local m = newModel(
		"C03_Siri_Pipoca",
		"Siri Pipoca",
		"Comum",
		1,
		"Siri coral pequeno com garras de confeiteiro",
		1.0
	)
	o(m, "Casco_Coral", 0, 0.22, 0, 2.7, 1.35, 2.10, C(255, 124, 112))
	o(m, "Topo_Casco", 0, 0.49, 0, 2.46, 0.79, 1.97, C(255, 170, 126))
	o(m, "Barriga", -0.06, -0.32, 0, 2.12, 0.67, 1.69, C(255, 226, 171))
	for side = -1, 1, 2 do
		for i = 1, 3 do
			local z = side * (0.75 + i * 0.38)
			leaf(
				m,
				"Pata_" .. side .. "_" .. i,
				0.46 - (i * 0.37),
				-0.38,
				z,
				0.28,
				1.10,
				0.32,
				C(255, 113, 106),
				side * 30
			)
			o(
				m,
				"Patinha_" .. side .. "_" .. i,
				0.48 - (i * 0.40),
				-0.87,
				z + side * 0.16,
				0.38,
				0.25,
				0.37,
				C(255, 199, 117)
			)
		end
		o(
			m,
			"Braco_Garra_" .. side,
			-1.02,
			-0.03,
			side * 1.46,
			0.52,
			0.49,
			1.03,
			C(245, 106, 93),
			nil,
			side * 20
		)
		o(m, "Garra_" .. side, -1.54, 0.11, side * 1.78, 0.86, 0.73, 0.77, C(255, 155, 121))
		o(
			m,
			"Pinca_Alta_" .. side,
			-1.95,
			0.28,
			side * 1.95,
			0.44,
			0.23,
			0.29,
			C(255, 215, 147),
			nil,
			34
		)
		o(
			m,
			"Pinca_Baixa_" .. side,
			-1.93,
			-0.02,
			side * 1.95,
			0.43,
			0.23,
			0.29,
			C(255, 215, 147),
			nil,
			-34
		)
	end
	o(m, "Haste_Olho_A", -0.82, 0.93, 0.58, 0.16, 0.68, 0.16, C(211, 76, 89))
	o(m, "Haste_Olho_B", -0.82, 0.93, -0.58, 0.16, 0.68, 0.16, C(211, 76, 89))
	eye(m, "Olho_A", -0.82, 1.26, 0.58, 1, 0.74)
	eye(m, "Olho_B", -0.82, 1.26, 0.58, -1, 0.74)
	o(m, "Sorriso", -1.37, 0.03, 0, 0.12, 0.13, 0.41, C(94, 46, 62))
	return m
end
local function make04()
	local m = newModel(
		"C04_Baiacu_Nuvem",
		"Baiacu Nuvem",
		"Incomum",
		2,
		"Baiacu lavanda com espinhos macios e brilho perolado",
		1.0
	)
	o(m, "Corpo_Lavanda", 0, 0, 0, 2.98, 2.70, 2.85, C(206, 166, 255))
	o(m, "Rosto_Perola", -0.47, -0.28, 0.03, 2.30, 1.80, 2.60, C(255, 222, 247))
	tail(m, 1.45, -0.08, 0, C(155, 116, 235), 0.62)
	for i = 0, 9 do
		local a = (i / 10) * math.pi * 2
		local x = 1.16 * math.cos(a)
		local z = 1.12 * math.sin(a)
		o(
			m,
			"Espinho_Macio_" .. i,
			x,
			0.96,
			z,
			0.24,
			0.50,
			0.24,
			C(255, 240, 252),
			M.SmoothPlastic,
			math.deg(a) * 0.12
		)
	end
	for i = 1, 5 do
		o(
			m,
			"Pintinha_Celeste_" .. i,
			0.54 + (i % 3) * 0.25,
			0.24 + (i % 2) * 0.38,
			1.17,
			0.15,
			0.15,
			0.08,
			C(156, 100, 245)
		)
	end
	eye(m, "Olho_A", -1.04, 0.35, 1.00, 1, 1.05)
	eye(m, "Olho_B", -1.04, 0.35, 1.00, -1, 1.05)
	o(m, "Beijinho", -1.55, -0.42, 0, 0.23, 0.22, 0.46, C(255, 132, 183))
	o(m, "Rubor", -1.14, -0.32, 1.24, 0.40, 0.19, 0.07, C(255, 159, 188))
	return m
end
local function make05()
	local m = newModel(
		"C05_Medusinha_Estelar",
		"Medusinha Estelar",
		"Incomum",
		2,
		"Agua-viva transparente estilizada com tentaculos de estrelas",
		1.0
	)
	local dome = o(m, "Campanula", 0, 0.70, 0, 3.20, 2.12, 3.15, C(110, 190, 255), M.Glass)
	dome.Transparency = 0.22
	o(m, "Borda_Campanula", 0, 0.00, 0, 3.35, 0.36, 3.28, C(172, 118, 254))
	o(m, "Centro_Rosa", 0, 0.37, 0, 2.36, 1.12, 2.35, C(252, 160, 250))
	for i = 1, 7 do
		local a = (i / 7) * 2 * math.pi
		local x = math.cos(a) * 0.96
		local z = math.sin(a) * 0.96
		for j = 1, 5 do
			local offset = 0.14 * math.sin(j * 0.85 + i)
			local orbSize = 0.23 - j * 0.018
			glow(
				m,
				"Tentaculo_" .. i .. "_" .. j,
				x + offset,
				-0.28 - j * 0.41,
				z + offset,
				orbSize,
				orbSize * 1.8,
				orbSize,
				C(100 + i * 12, 205, 255 - i * 10)
			)
		end
	end
	eye(m, "Olho_A", -1.12, 0.61, 1.17, 1, 0.70)
	eye(m, "Olho_B", -1.12, 0.61, 1.17, -1, 0.70)
	glow(m, "Estrela_Ponta", 0.35, 1.80, 0.61, 0.23, 0.23, 0.23, C(255, 252, 185))
	return m
end
local function make06()
	local m = newModel(
		"C06_Cavalo_Marinho_Coral",
		"Cavalo-Marinho Coral",
		"Incomum",
		2,
		"Cavalo-marinho rosa coral com cauda enrolada",
		1.0
	)
	local segments = {
		{ 0.32, 1.15, 0.72 },
		{ 0.48, 0.68, 0.77 },
		{ 0.66, 0.16, 0.65 },
		{ 0.70, -0.39, 0.53 },
		{ 0.49, -0.85, 0.42 },
		{ 0.18, -1.20, 0.34 },
		{ -0.10, -1.40, 0.30 },
		{ -0.40, -1.37, 0.25 },
		{ -0.59, -1.16, 0.20 },
		{ -0.55, -0.91, 0.16 },
	}
	for i, s in ipairs(segments) do
		o(
			m,
			"Segmento_" .. i,
			s[1],
			s[2],
			0,
			s[3] * 1.55,
			s[3] * 1.65,
			s[3] * 1.27,
			i < 5 and C(255, 144, 168) or C(236, 107, 155)
		)
	end
	o(m, "Cabeca", -0.20, 1.77, 0, 1.58, 0.98, 1.10, C(255, 168, 166), nil, -16)
	o(m, "Focinho", -1.02, 1.49, 0, 1.15, 0.35, 0.42, C(255, 181, 155), nil, -11)
	o(m, "Boca", -1.61, 1.43, 0, 0.18, 0.24, 0.46, C(255, 111, 165))
	eye(m, "Olho_A", -0.47, 1.91, 0.49, 1, 0.70)
	eye(m, "Olho_B", -0.47, 1.91, 0.49, -1, 0.70)
	for i = 1, 4 do
		leaf(
			m,
			"Crista_Coral_" .. i,
			0.55,
			1.47 - (i - 1) * 0.54,
			0,
			0.53,
			0.43,
			0.30,
			C(255, 196, 77),
			35
		)
	end
	leaf(m, "Barbatana_Dorsal", 1.13, 0.29, 0, 0.83, 1.15, 0.15, C(255, 215, 96), -29)
	glow(m, "Perola_Testa", -0.52, 2.34, 0, 0.20, 0.27, 0.20, C(255, 245, 162))
	return m
end
local function make07()
	local m = newModel(
		"C07_Arraia_Prisma",
		"Arraia Prisma",
		"Raro",
		3,
		"Arraia marinha com asas de cristal roxo e azul",
		0.88
	)
	o(m, "Corpo_Azul", 0, 0, 0, 3.65, 0.66, 2.75, C(58, 112, 207))
	o(m, "Barriga_Brilhante", -0.42, -0.13, 0, 2.45, 0.57, 1.93, C(123, 222, 250))
	for side = -1, 1, 2 do
		local z = side * 1.94
		leaf(m, "Asa_Cristal_" .. side, 0.31, 0.16, z, 3.38, 0.40, 2.20, C(123, 94, 242), side * 12)
		leaf(
			m,
			"Aresta_Ciano_" .. side,
			0.37,
			0.33,
			side * 2.14,
			2.59,
			0.17,
			1.34,
			C(45, 237, 250),
			side * 5
		)
		for i = 1, 3 do
			glow(
				m,
				"Pinta_Estrela_" .. side .. "_" .. i,
				-0.40 + i * 0.50,
				0.47,
				side * (1.06 + i * 0.52),
				0.17,
				0.13,
				0.17,
				C(233, 248, 255)
			)
		end
	end
	for i = 1, 6 do
		o(
			m,
			"Rabo_Fino_" .. i,
			1.85 + i * 0.51,
			-0.08,
			0,
			0.70 - i * 0.045,
			0.14,
			0.17,
			C(77, 186, 225)
		)
	end
	eye(m, "Olho_A", -1.00, 0.32, 0.77, 1, 0.70)
	eye(m, "Olho_B", -1.00, 0.32, 0.77, -1, 0.70)
	glow(m, "Cristal_Central", 0.30, 0.42, 0, 0.55, 0.28, 0.51, C(184, 239, 255))
	return m
end
local function make08()
	local m = newModel(
		"C08_Enguia_Trovao",
		"Enguia Trovão",
		"Raro",
		3,
		"Enguia sinuosa azul-escura envolta em faíscas ciano",
		0.79
	)
	local path = {
		{ -3.20, 0.16, 0.15, 1.20 },
		{ -2.30, 0.06, -0.12, 1.10 },
		{ -1.37, -0.17, -0.24, 0.96 },
		{ -0.47, -0.37, 0.03, 0.89 },
		{ 0.48, -0.14, 0.30, 0.79 },
		{ 1.40, 0.16, 0.29, 0.68 },
		{ 2.26, 0.31, 0.06, 0.55 },
		{ 3.00, 0.03, -0.26, 0.42 },
		{ 3.60, -0.26, -0.30, 0.29 },
	}
	for i, p in ipairs(path) do
		o(
			m,
			"Corpo_Segmento_" .. i,
			p[1],
			p[2],
			p[3],
			1.54,
			p[4],
			p[4],
			i % 2 == 0 and C(35, 91, 198) or C(34, 66, 160)
		)
		if i > 1 and i < 9 then
			glow(
				m,
				"Risco_Eletrico_" .. i,
				p[1],
				p[2] + p[4] * 0.47,
				p[3],
				0.21,
				0.19,
				0.21,
				C(73, 238, 255)
			)
		end
	end
	o(m, "Cabeca", -3.73, 0.17, 0.15, 1.80, 1.02, 1.10, C(45, 102, 207))
	o(m, "Queixo", -4.35, -0.13, 0.15, 0.84, 0.34, 0.76, C(98, 198, 241))
	eye(m, "Olho_A", -4.02, 0.34, 0.65, 1, 0.80, C(10, 46, 83))
	eye(m, "Olho_B", -4.02, 0.34, 0.65, -1, 0.80, C(10, 46, 83))
	for i = 1, 6 do
		local p = path[i + 1]
		w(
			m,
			"Raio_Dorsal_" .. i,
			p[1],
			p[2] + 0.49,
			p[3],
			0.40,
			0.82,
			0.34,
			C(75, 231, 255),
			M.Neon,
			15
		)
	end
	glow(m, "Descarga_A", -2.00, 1.14, 0.67, 0.28, 0.28, 0.28, C(245, 253, 255))
	glow(m, "Descarga_B", 0.48, 0.89, 0.68, 0.23, 0.23, 0.23, C(245, 253, 255))
	glow(m, "Descarga_C", 2.49, -0.55, -0.46, 0.19, 0.19, 0.19, C(245, 253, 255))
	return m
end
local function make09()
	local m = newModel(
		"C09_Guardiao_Cristal",
		"Guardião de Cristal",
		"Epico",
		4,
		"Peixe blindado de pedra abissal com cristais brilhantes",
		0.84
	)
	o(m, "Corpo_Abissal", 0, 0, 0, 4.6, 2.77, 2.48, C(31, 48, 95))
	o(m, "Placa_Facial", -1.40, 0.12, 0, 1.44, 2.13, 2.40, C(74, 93, 161))
	o(m, "Armadura_Central", 0.13, 0.32, 0, 2.60, 1.92, 2.66, C(50, 80, 145))
	o(m, "Mandibula", -1.50, -0.81, 0.03, 1.34, 0.62, 1.64, C(79, 142, 172))
	tail(m, 2.39, -0.03, 0, C(62, 94, 184), 1.37)
	for i = 1, 5 do
		local px = -1.25 + i * 0.71
		w(
			m,
			"Cristal_Costas_" .. i,
			px,
			1.25 + (i % 2) * 0.30,
			0,
			0.54,
			1.20 + (i % 3) * 0.40,
			0.51,
			i % 2 == 0 and C(130, 95, 255) or C(71, 241, 255),
			M.Neon,
			12
		)
	end
	for side = -1, 1, 2 do
		for i = 1, 3 do
			w(
				m,
				"Cristal_Flanco_" .. side .. "_" .. i,
				0.35 + (i - 2) * 0.70,
				0.20,
				side * 1.27,
				0.44,
				0.93,
				0.44,
				C(82, 204, 250),
				M.Neon,
				36,
				side * 34
			)
		end
	end
	eye(m, "Olho_Guardiao_A", -1.52, 0.41, 1.19, 1, 1.19, C(8, 53, 84))
	eye(m, "Olho_Guardiao_B", -1.52, 0.41, 1.19, -1, 1.19, C(8, 53, 84))
	glow(m, "Nucleo_Frontal", -2.20, 0.06, 0.01, 0.34, 0.61, 0.49, C(255, 235, 143))
	glow(m, "Cristal_Energia", 0.25, 1.22, 0.18, 0.65, 0.60, 0.60, C(180, 253, 255))
	local light = Instance.new("PointLight")
	light.Name = "Luz_Suave_Do_Nucleo"
	light.Brightness = 0.65
	light.Range = 8
	light.Color = C(74, 211, 255)
	light.Parent = m:FindFirstChild("Cristal_Energia")
	return m
end
local function make10()
	local m = newModel(
		"C10_Leviata_Astral",
		"Leviatã Astral",
		"Lendario",
		5,
		"Leviatao dragao do mar com escamas cosmicas, chifres dourados e estrelas",
		0.69
	)
	local wave = {
		{ -4.20, 0.20, 0.18, 1.85 },
		{ -3.23, 0.17, -0.20, 1.67 },
		{ -2.20, -0.12, -0.42, 1.50 },
		{ -1.17, -0.49, -0.22, 1.33 },
		{ -0.08, -0.62, 0.24, 1.21 },
		{ 1.01, -0.32, 0.47, 1.08 },
		{ 2.10, 0.14, 0.20, 0.92 },
		{ 3.18, 0.42, -0.28, 0.79 },
		{ 4.20, 0.13, -0.49, 0.67 },
		{ 5.08, -0.24, -0.23, 0.52 },
		{ 5.82, -0.41, 0.11, 0.37 },
	}
	for i, p in ipairs(wave) do
		o(
			m,
			"Escama_Corpo_" .. i,
			p[1],
			p[2],
			p[3],
			1.72,
			p[4],
			p[4],
			i % 3 == 0 and C(81, 55, 162) or C(64, 43, 131)
		)
		if i > 2 and i < 10 then
			o(
				m,
				"Escama_Luminosa_" .. i,
				p[1],
				p[2] + p[4] * 0.37,
				p[3] + p[4] * 0.38,
				0.45,
				0.26,
				0.16,
				C(255, 198, 86),
				M.Neon,
				-25
			)
		end
	end
	o(m, "Cabeca_Real", -4.88, 0.33, 0.18, 2.41, 1.89, 1.83, C(71, 46, 146))
	o(m, "Focinho_Real", -5.88, -0.15, 0.18, 1.37, 0.73, 1.25, C(103, 69, 176))
	o(m, "Queixo_Dourado", -5.66, -0.49, 0.19, 1.12, 0.24, 1.14, C(255, 205, 114))
	for side = -1, 1, 2 do
		o(m, "Chifre_Base_" .. side, -4.42, 1.20, side * 0.65, 0.40, 0.55, 0.40, C(255, 195, 66))
		w(
			m,
			"Chifre_Dourado_" .. side,
			-4.31,
			1.84,
			side * 0.69,
			0.43,
			1.28,
			0.43,
			C(255, 225, 109),
			M.Metal,
			side * -28
		)
		eye(m, "Olho_Astral_" .. side, -5.14, 0.62, 0.84, side, 1.10, C(49, 24, 110))
		o(
			m,
			"Bigode_Dourado_" .. side,
			-5.79,
			-0.33,
			side * 1.04,
			1.36,
			0.12,
			0.14,
			C(255, 216, 103),
			M.Neon,
			side * 17
		)
		o(
			m,
			"Barbatana_Lateral_" .. side,
			-3.58,
			-0.40,
			side * 1.10,
			1.48,
			0.34,
			0.83,
			C(175, 90, 246),
			M.SmoothPlastic,
			side * 21
		)
	end
	for i = 2, 10, 2 do
		local p = wave[i]
		w(
			m,
			"Crista_Estelar_" .. i,
			p[1],
			p[2] + p[4] * 0.49,
			p[3],
			0.62,
			1.13,
			0.56,
			C(119, 214, 255),
			M.Neon,
			17
		)
		glow(
			m,
			"Estrela_Dorsal_" .. i,
			p[1],
			p[2] + p[4] * 0.94,
			p[3],
			0.17,
			0.17,
			0.17,
			C(255, 247, 169)
		)
	end
	leaf(m, "Cauda_Leque_A", 6.37, -0.12, 0.17, 1.77, 1.07, 0.34, C(142, 102, 255), 35)
	leaf(m, "Cauda_Leque_B", 6.37, -0.81, 0.17, 1.77, 1.07, 0.34, C(88, 212, 255), -35)
	glow(m, "Joia_Testa", -5.06, 1.27, 0.20, 0.31, 0.31, 0.32, C(255, 230, 114))
	local light = Instance.new("PointLight")
	light.Name = "Luz_Astral_Leve"
	light.Brightness = 0.75
	light.Range = 11
	light.Color = C(165, 118, 255)
	light.Parent = m:FindFirstChild("Joia_Testa")
	return m
end

local catalog = {
	make01(),
	make02(),
	make03(),
	make04(),
	make05(),
	make06(),
	make07(),
	make08(),
	make09(),
	make10(),
}
local folder = Instance.new("Folder")
folder.Name = PREFABS_FOLDER_NAME
folder.Parent = ReplicatedStorage

for _, model in ipairs(catalog) do
	model.Parent = folder
end

local function displayGeometry(m, name, primitive, position, size, color, material, rotZ)
	return geometry(
		m,
		name,
		primitive,
		position.X,
		position.Y,
		position.Z,
		size.X,
		size.Y,
		size.Z,
		color,
		material,
		rotZ
	)
end

if SHOW_SHOWROOM then
	local worldFolder = Instance.new("Folder")
	worldFolder.Name = SHOWROOM_FOLDER_NAME
	worldFolder.Parent = Workspace
	local stage = Instance.new("Model")
	stage.Name = "Palco_de_previsualizacao_PODE_EXCLUIR"
	stage.Parent = worldFolder
	local origin = SHOWROOM_ORIGIN
	local base = displayGeometry(
		stage,
		"Base_Flutuante",
		"Block",
		origin + Vector3.new(0, -2, 0),
		Vector3.new(110, 3, 59),
		C(34, 55, 104),
		M.SmoothPlastic
	)
	base.CanCollide = true
	base.CanQuery = true
	local floor = displayGeometry(
		stage,
		"Piso_Azul",
		"Block",
		origin + Vector3.new(0, -0.37, 0),
		Vector3.new(108, 1, 57),
		C(31, 103, 154),
		M.SmoothPlastic
	)
	floor.CanCollide = true
	floor.CanQuery = true
	displayGeometry(
		stage,
		"Faixa_Frontal_Dourada",
		"Block",
		origin + Vector3.new(0, -0.48, 29),
		Vector3.new(109, 0.35, 0.38),
		C(255, 200, 99),
		M.Neon
	)
	for i, original in ipairs(catalog) do
		local col = (i - 1) % 5
		local row = math.floor((i - 1) / 5)
		local dx = (col - 2) * 21.3
		local dz = (row - 0.5) * 27
		local center = origin + Vector3.new(dx, 0, dz)
		local rarity = original:GetAttribute("Rarity")
		local tint = rar[rarity] or C(255, 255, 255)
		local pedestal = displayGeometry(
			stage,
			"Pedestal_" .. i,
			"Cylinder",
			center + Vector3.new(0, 0.65, 0),
			Vector3.new(1.2, 15.1, 15.1),
			C(41, 58, 112),
			M.SmoothPlastic,
			nil
		)
		-- Cilindros do Roblox possuem eixo local X: rotacionar para ficar com eixo vertical.
		pedestal.CFrame = pedestal.CFrame * CFrame.Angles(0, 0, math.rad(90))
		pedestal.CanCollide = true
		pedestal.CanQuery = true
		local halo = displayGeometry(
			stage,
			"Aro_" .. i,
			"Cylinder",
			center + Vector3.new(0, 1.32, 0),
			Vector3.new(0.28, 14.0, 14.0),
			tint,
			M.Neon,
			nil
		)
		halo.CFrame = halo.CFrame * CFrame.Angles(0, 0, math.rad(90))
		local display = original:Clone()
		display.Name = original.Name .. "__VITRINE"
		display.Parent = worldFolder
		display:ScaleTo(original:GetAttribute("PreviewScale") or 1)
		display:PivotTo(CFrame.new(center + Vector3.new(0, 5.05, 0)))
		local labelGui = Instance.new("BillboardGui")
		labelGui.Name = "Etiqueta_Da_Criatura"
		labelGui.Adornee = pedestal
		labelGui.Size = UDim2.fromOffset(300, 74)
		labelGui.StudsOffsetWorldSpace = Vector3.new(0, 8.0, 0)
		labelGui.AlwaysOnTop = true
		labelGui.MaxDistance = 180
		labelGui.Parent = pedestal
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Nome_e_Raridade"
		textLabel.BackgroundTransparency = 1
		textLabel.Size = UDim2.fromScale(1, 1)
		textLabel.Text = string.format(
			"%s\n%s",
			original:GetAttribute("DisplayName"),
			rarityLabel[rarity] or rarity
		)
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextSize = 24
		textLabel.TextScaled = false
		textLabel.TextWrapped = true
		textLabel.TextColor3 = tint
		textLabel.TextStrokeColor3 = C(14, 21, 52)
		textLabel.TextStrokeTransparency = 0.08
		textLabel.Parent = labelGui
	end
end

print("[FishClicker] 10 criaturas criadas com sucesso!")
print("Prefabs: ReplicatedStorage > " .. PREFABS_FOLDER_NAME)
if SHOW_SHOWROOM then
	print(
		"Vitrine: Workspace > " .. SHOWROOM_FOLDER_NAME .. " | Centro " .. tostring(SHOWROOM_ORIGIN)
	)
end
print("AVISO: modelos de aparencia, ancorados e sem rig; integre a captura e animacoes depois.")

return true
