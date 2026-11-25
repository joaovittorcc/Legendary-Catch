# Pacote para o Gemini: refazer o TERRENO da ilha-hub (lobby)

> Como usar: copie TODO este arquivo (ou anexe como arquivo) e cole no chat do Gemini. Se puder, anexe também os prints `art/preview/hub-tour/01-hub-visao-geral.jpg`, `02-praca-central.jpg`, `03-lagoa-treino.jpg`, `08-entrada-escada-aquario.jpg` e o concept `art/concept/hub-portais/gemini-v1-aprovado-com-marcacoes.webp`.
> O Gemini devolve UM arquivo `HubTerrainBuilder.luau`. Mande-o para o Claude, que coloca no jogo, testa e ajusta.

---

# 1) O pedido (leia primeiro)

Você é um artista técnico de terreno de Roblox, excelente em gerar terreno bonito por código (`Terrain:FillBall`, `FillBlock`, `FillCylinder`, `FillWedge`, `WriteVoxels`, ruído com `math.noise`).

Estou fazendo o jogo **Legendary Catch** (pesca fantástica e coleção, estilo cartoon "candy", cores vivas). A **ilha-hub** (o lobby onde o jogador nasce) tem hoje um terreno bem simples: foi feito com alguns cilindros e esferas empilhados. Quero que você **refaça SÓ o terreno do hub** (grama, rocha, areia, lagoa, falésias, praias, bacias de água), muito mais **bonito, natural e estilizado**, mas mantendo tudo que já está construído em cima dele funcionando.

**O que NÃO muda:** todas as construções (praça, oficina, escadaria, píer de pesca, plataformas, aquário, portais, lanternas, cristais, placas, NPCs) são **peças (Parts/MeshParts) que já existem** e que eu não vou refazer. O seu terreno vai por baixo e em volta delas. Você NÃO cria peças, só terreno nativo do Roblox (`workspace.Terrain`).

**O resto do mapa não pode ser tocado:** o oceano grande, as outras ilhas (a mais de 300 studs de distância) e o fundo do mar fora da caixa do hub ficam como estão. Seu código só pode mexer **dentro da caixa do hub**: X de -105 a 45, Y de -14 a 60, Z de -95 a 80.

# 2) O que entregar (formato exato)

Um único arquivo Luau chamado `HubTerrainBuilder.luau`:
- Começa com `--!strict`. `local Builder = {}` e `return Builder` no fim.
- `function Builder.build()`: **idempotente**. Primeiro limpa só a caixa do hub (Air) e devolve o mar e a sombra de areia rasa dentro dela (a superfície do mar fica em Y = 0, o fundo do mar é areia/slate em torno de Y -4 a -12 como no código atual da seção 4), e depois gera o terreno novo. Pode ser rodado várias vezes e sempre dá o mesmo resultado (use `Random.new(SEED)` e `math.noise` com seed fixa).
- `function Builder.report(): string`: devolve um texto com a altura do terreno (via `Workspace:Raycast` de cima para baixo só no `Terrain`) nos pontos de verificação da seção 2.3, para eu conferir.
- Tudo com `task.wait()` entre blocos grandes para não travar o Studio. O `build()` inteiro deve levar no máximo ~30 segundos.
- Nada de `Script`/`LocalScript`, nada de peças. Não mexa em `Lighting`.
- Código limpo: serviços no topo com `game:GetService`, tipos, sem `wait()`, comentários curtos em inglês.
- Preserve as configurações do terreno e as cores dos materiais (seção 3.3). Pode propor cores melhores para Grass/Rock/Sand/Basalt, mas diga quais mudou.

# 2) Contrato com as construções (o que não pode quebrar)

Estas construções já existem, com estas alturas. O terreno nunca pode sobressair acima delas nem bloquear caminhos; nas áreas livres ele pode ter morros, falésias e detalhes.

## 2.1 Mapa do que existe em cima do terreno (limites X, Y, Z em studs)
- **Praça central** (piso de pedra clara, círculo grande, fogueira e cristal no centro): piso plano em **Y = 10,3**, X de -30 a 18, Z de -22 a 24. **Spawn do jogador** em (-6, 10,4, 11,5). O terreno embaixo da praça deve ficar em Y ≤ 9 (hoje está em 8).
- **Oficina de Varas** (casa de telhado azul no fundo da praça, no norte): terraço de madeira em **Y = 14,3**, X de -26 a 14, Z de -48 a -22. O terreno atrás dela forma uma colina rochosa com grama no topo (hoje até Y 34 em X -8 a 4, Z -76 a -52). Dentro da casa (X -23 a 11, Z -48 a -24, Y acima de 14) o terreno **tem que estar vazio** (Air).
- **Escadaria de entrada** (sul): desce da praça (Y 10,3) até a água. X de -23 a 9, Z de 24 a 66. O terreno **abre uma vala** ali: hoje o corte é X -14..2, Z 26..52. Dos dois lados da escada há rochas e pedras submersas (recife raso turquesa).
- **Píer de pesca** (leste): piso de madeira em **Y = 10,1**, X de 17 a 85, Z de 1 a 15, sobre estacas. O terreno só encosta no início (X de 12 a 17). Depois dele é mar aberto. **A ponta do píer não muda.**
- **Lagoa de treino** (oeste, com cachoeira): bacia redonda de raio 15 centrada em (X -44, Z 2), água em **Y = 8**, fundo de areia em Y ≈ 4. A falésia da cachoeira fica atrás dela, ao norte e a oeste (esferas de rocha em torno de (-50, 12, -18)), com grama em cima. No lado leste da lagoa está sendo construída (em andamento, pode mudar um pouco) uma ponte de madeira com um portal em X -52 a -26, Z -15 a 3, piso em Y = 10,3 (o terreno ali pode ter água/areia e rocha, só não pode passar de Y 10).
- **Aquário e deck** (sudoeste): X de -50 a -25, Z de 33 a 62, plataforma de madeira sobre estacas, ao nível do mar a 8. O terreno ao redor dela pode ser praia/rocha.
- **Praça dos portais** (sudeste, em plataformas flutuantes, sobre o mar): X de 9 a 72, Z de 13 a 79. Fora do hub-terreno, só mar. Deixe o mar aberto ali.
- **Placares flutuantes** no mar a oeste (X -96 a -44, Z 20 a 34, Y 23 a 48): só mar embaixo.
- **Troféu flutuante** a leste (X 66 a 90, Z -38 a -14, Y 6 a 23): é uma ilha pequena que já existe, não mexa.
- **Decorações** (palmeiras, cristais grandes de malha, arbustos) estão em Y entre -15 e 36 dentro de X -76..65, Z -69..70. Eles ficam em cima do terreno; evite criar paredes de rocha exatamente onde estão (veja a lista de posições na seção 2.2).

## 2.2 Cristais e palmeiras que ficam sobre o terreno (posição X, Y, Z)
Cristais: (-22, 19, -57), (-15, 14, -60), (12, 11, -59), (-36, 18, -46), (22, 18, -41), (-72, 14, 14), (-71, 14, 23), (-67, 7, -26), (11, 9, 37), (-18, 6, 35), (32, 7, 21), (55, 6, 22), (29, 5, -19), (-75, 3, 34).
Palmeiras: (-26, 32, -46), (16, 26, -40), (-70, 15, 4).
Árvore de flores rosa: tronco em (-58, 19, -14) (na falésia da cachoeira).
Rocha da cachoeira (peça de malha): centro em (-47, 12, -11).
O terreno deve ter **chão sólido (grama ou rocha) sob cada um desses pontos**, com topo próximo à altura Y indicada menos 2 ou 3 studs, para eles não flutuarem nem ficarem enterrados.

## 2.3 Pontos de verificação (o `report()` deve mostrar o Y do terreno aqui)
- Praça: (-6, 11,5), (-6, 0), (-20, 4), (6, 4), (-6, -16). Esperado: topo do terreno ≤ 9.
- Terraço da oficina: (-6, -35), (-20, -30), (8, -30). Esperado: topo do terreno ≤ 13,5.
- Escadaria: (-6, 30), (-6, 45). Esperado: sem terreno acima de Y 0 (fica a vala com água/areia rasa).
- Início do píer: (14, 8). Esperado: terreno ≤ 9, ou nada (mar) a partir de X 18.
- Lagoa: (-44, 2) areia em Y ≈ 4 e água até Y 8.
- Colina atrás da oficina: (-6, -62). Esperado: terreno bem alto (≥ 25).

## 2.4 Caminhabilidade
O jogador anda por todo o lobby. Entre a praça, a escada, o terraço da oficina, o caminho para a lagoa (oeste) e o início do píer (leste) **não pode ter degrau maior que ~3 studs nem paredes**. As partes altas (colina atrás da oficina, falésias da lagoa) podem ser íngremes, mas não devem bloquear nenhum acesso. A área jogável total é, em XZ, de -80 a 32 em X e de -76 a 48 em Z (veja os mapas abaixo).

# 3) Estado atual do terreno (amostrado do jogo real)

### 3.1 Altura do topo do terreno (Y em studs), amostrada a cada 4 studs
Cada linha é um valor de Z; cada coluna um valor de X. "-4" significa fundo do mar raso (areia submersa), ou seja, sem terra ali. A superfície do mar fica em Y = 0.
Os valores já são o topo do terreno sólido (grama, rocha ou areia), sem contar a água.

```
  z\x -80 -76 -72 -68 -64 -60 -56 -52 -48 -44 -40 -36 -32 -28 -24 -20 -16 -12  -8  -4   0   4   8  12  16  20  24  28  32
  -76  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  17  21  21  21  17  -4  -4  -4  -4  -4  -4  -4  -4
  -72  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  21  25  26  28  26  25  21  -4  -4  -4  -4  -4  -4  -4
  -68  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  12  17  17  17  17  25  28  31  32  31  28  25  17  -4  -4  -4  -4  -4  -4
  -64  -4  -4  -4  -4  -4  -4  -4  -4  -4  12  18  21  21  21  21  26  30  33  34  33  30  26  21   8  12   8  -4  -4  -4
  -60  -4  -4  -4  -4  -4  -4  -4   0   2  17  21  23  24  24  22  27  30  33  34  33  30  27  22  17  18  17  13  -4  -4
  -56  -4  -4  -4  -4  -4  -4   0   4   5  17  21  23  24  24  22  27  30  31  32  31  30  27  22  19  20  19  17   8  -4
  -52  -4  -4  -4  -4  -4   2   5   5   6  17  21  23  23  23  19  26  27  30  31  30  27  26  18  20  21  20  18  12  -4
  -48  -4  -4  -4  -4   1   5   7   7   5  12  18  21  21  21  12  12  12  12  12  12  12  12  12  19  20  19  17   8  -4
  -44  -4  -4  -4  -4   4   7   7   6   4   2  12  17  17  17  12  12  12  12  12  12  12  12  12  17  18  17  13  -4  -4
  -40  -4  -4  -4   1   4   6   6   5   1   6   8   8   9  12  12  12  12  12  12  12  12  12  12  12  12   8   4  -4  -4
  -36  -4  -4   2   5   5   2   2   4   7   8   8   8   9  12  12  12  12  12  12  12  12  12  12  12   9   8   7   4  -4
  -32  -4   0   5   6   6   2  -4   7   8   9   9   8   9  12  12  12  12  12  12  12  12  12  12  12   9   9   8   5  -4
  -28  -4   4   7   8   7  13  21  21  17  16  16  13   9  12  12  12  12  12  12  12  12  12  12  12   9   8   7   4  -4
  -24  -4   2   7   8  13  21  25  25  21  18  18  15   9  10  10  10  10  10  10  10  10  10  10  10   9   5   5   2  -4
  -20   1   5   7   9  15  21  25  25  21  18  17  14   8   8   8   8   8   8   8   8   8   8   6  -4   1   4   4   2  -4
  -16   1   6   7   9   8   8  21  21  21   8   8   8   8   8   8   8   8   8   8   8   8   8   6  -4  -4   2   4   3   0
  -12   1   5   6   8   8   8   8   5  17   5   5   8   8   8   8   8   8   8   8   8   8   8   8   7  -4   1   3   5   2
   -8   5   7   7   8   8   8   5   4   4   4   4   5   8   8   8   8   8   8   8   8   8   8   8   8   5   3   4   5   4
   -4   5   7   7   8   8   7   4   4   4   4   4   4   7   8   8   8   8   8   8   8   8   8   8   8   7   3   4   2   1
    0   2   5   7   8   8   6   4   4   4   4   4   4   6   8   8   8   8   8   8   8   8   8   8   8   7   0   1  -4  -4
    4   3   5   5   8   8   7   4   4   4   4   4   4   7   8   8   8   8   8   8   8   8   8   8   8   7  -4  -4  -4  -4
    8   1   3   6   7   8   8   6   4   4   4   4   6   8   8   8   8   8   8   8   8   8   8   8   8   5  -4  -4  -4  -4
   12  -4   2   5   5   7   8   8   6   5   4   5   8   8   8   8   8   8   8   8   8   8   8   8   7   4   4   1  -4  -4
   16  -4   5   6   6   6   5   7   7   7   8   8   8   8   8   8   8   8   8   8   8   8   8   8   8   5   5   2  -4  -4
   20  -4   2   5   5   6   6   6   4  -4   6   8   8   8   8   8   8   8   8   7   8   8   8   8   8   5   4   1  -4  -4
   24  -4  -4   1   1   5   7   7   5   0  -4   7   8   8   8   8  10   9   6   6   6   9  10   8   8   4   1  -4  -4  -4
   28  -4  -4  -4  -4   4   6   7   6   5   4   5   8   8   8   8  10   9  -1  -1  -1   9  10   8   6   2  -4  -4  -4  -4
   32  -4  -4  -4  -4   0   5   7   7   7   6   3   6   8   8   8   8   6  -1  -4  -4   6   8   7   6   2  -4  -4  -4  -4
   36  -4  -4  -4  -4  -4   4   6   6   7   6   3   5   7   7   7   7   6  -4  -4  -4   6   7   5   5   0  -4  -4  -4  -4
   40  -4  -4  -4  -4  -4   0   2   4   5   4   3   6   7   6   6   6   4  -4  -4  -4   5   6   1  -4  -4  -4  -4  -4  -4
   44  -4  -4  -4  -4  -4  -4  -4  -4   0  -4   1   4   5   5   6   6   2  -4  -4  -4   2   3   0  -4  -4  -4  -4  -4  -4
   48  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4  -4   0  -4   1   2   1  -4  -4  -4   1   2  -4  -4  -4  -4  -4  -4  -4
```

### 3.2 Material do topo (mesma grade, X de -80 a 32, Z de -76 a 48; G=grama, R=rocha, S=areia, .=nenhum)
```
 -76 SSSSSSSSSSSSSSSSRRRRRSSSSSSSS
 -72 SSSSSSSSSSSSSSSRRRGRRRSSSSSSS
 -68 SSSSSSSSSSRRRRRRGGGGGRRSSSSSS
 -64 SSSSSSSSSRRRRGRRGGGGGRRRRRSSS
 -60 SSSSSSSRRRRRGGRRRGGGRRRRRRRSS
 -56 SSSSSSRRRRRRGGRRRRGRRRRRRRRRS
 -52 SSSSSRRRRRRRRRRRRRRRRRRRRRRRS
 -48 SSSSRRRRRRRRRRRRRRRRRRRRRRRRS
 -44 SSSSRRRRRRRRRRRRRRRRRRRRRRRSS
 -40 SSSRRRRRRGGGRRRRRRRRRRRRRRRSS
 -36 SSRRRRRGGGGGRRRRRRRRRRRRRRRRS
 -32 SRRRRRSGGRRGRRRRRRRRRRRRRRRRS
 -28 SRRRRRGGRRRRRRRRRRRRRRRRRRRRS
 -24 SRRRRGGGGRRRRRRRRRRRRRRRRRRRS
 -20 RRRRRGGGGRRRGGGGGGGGGGGSRRRRS
 -16 RRRRGRGGRGGGGGGGGGGGGGGSSRRRR
 -12 RRRGGGGGRRGGGGGGGGGGGGGGSRRRR
  -8 RRRGGGGSSSSGGGGGGGGGGGGGGRRRR
  -4 RRRGGGSSSSSSGGGGGGGGGGGGGRRRR
   0 RRGGGGSSSSSSGGGGGGGGGGGGGRRSS
   4 RRGGGGSSSSSSGGGGGGGGGGGGGSSSS
   8 RRRGGGRSSSSRGGGGGGGGGGGGGSSSS
  12 SRRRGGGRRRGGGGGGGGGGGGGGRRRSS
  16 SRRRRGGGGGGGGGGGGGGGGGGGRRRSS
  20 SRRRRRRRSGGGGGGGGGGGGGGGGRRSS
  24 SSRRRRRRRSGGGGGRRGGGRRGGGRSSS
  28 SSSSRRRRRRGGGGGRRRRRRRGRRSSSS
  32 SSSSRRRRRRRGGGGRRRSSRRRRRSSSS
  36 SSSSSRRRRRRRRGGRRSSSRRRRRSSSS
  40 SSSSSRRRRRRRRRRRRSSSRRRSSSSSS
  44 SSSSSSSSRSRRRRRRRSSSRRRSSSSSS
  48 SSSSSSSSSSSSRSRRRSSSRRSSSSSSS
```
(O S no centro da lagoa, X -40 a -28, Z -8 a 8, é o fundo de areia da lagoa; ela tem água até Y = 8.)

### 3.3 Água e cores atuais do terreno
- Mar: superfície em Y = 0. `Terrain.WaterColor` (10,96,168), `WaterTransparency` 0.52, `WaterReflectance` 0.55, `WaterWaveSize` 0.14, `WaterWaveSpeed` 9, `Decoration = false`.
- Lagoa: bacia redonda de raio 15 centrada em (X -44, Z 2), água até Y = 8, fundo de areia em Y ≈ 4.
- Piscina rasa da frente (entre as escadas): água em torno de Y = 0 a 3 na área X -14..2, Z 24..52.
- Cores dos materiais do terreno: Rock (112,118,148), Grass (74,164,92), Sand (232,214,172), Basalt (78,84,116), Slate/fundo do mar (12,40,84).


# 4) Código atual que gera o terreno

É o trecho do gerador antigo (`tools/IslandGenerator.luau`). Use como referência de materiais, tamanhos e do que existe; **reescreva do seu jeito**. O oceano grande (`buildOcean`) é feito uma vez para o mundo inteiro: você NÃO deve refazer o mundo, só a caixa do hub.

```lua
-- Constants used below (from the same generator):
local OCEAN_SIZE = 2048     -- whole world water/seabed tiles (not for you to rebuild)
local OCEAN_DEPTH = 14      -- sea level is Y = 0, deep seabed (Slate) at about Y -14 to -18; the sand shelf (3 stacked cylinders) rises to about Y -4.5 near the island
local COLORS = { rock = Color3.fromRGB(112,118,148), rockDark = Color3.fromRGB(78,84,116), grass = Color3.fromRGB(74,164,92), sand = Color3.fromRGB(232,214,172), seabed = Color3.fromRGB(12,40,84) }

-- Terrain -----------------------------------------------------------------------------

local function buildOcean()
	Terrain:Clear()
	Terrain.Decoration = false
	Terrain.WaterColor = Color3.fromRGB(10, 96, 168)
	Terrain.WaterTransparency = 0.52
	Terrain.WaterReflectance = 0.55
	Terrain.WaterWaveSize = 0.14
	Terrain.WaterWaveSpeed = 9
	Terrain:SetMaterialColor(Enum.Material.Rock, COLORS.rock)
	Terrain:SetMaterialColor(Enum.Material.Grass, COLORS.grass)
	Terrain:SetMaterialColor(Enum.Material.Sand, COLORS.sand)
	Terrain:SetMaterialColor(Enum.Material.Slate, COLORS.seabed)
	Terrain:SetMaterialColor(Enum.Material.Basalt, COLORS.rockDark)

	local tile = 512
	local half = OCEAN_SIZE / 2
	for x = -half + tile / 2, half - tile / 2, tile do
		for z = -half + tile / 2, half - tile / 2, tile do
			Terrain:FillBlock(
				CFrame.new(x, -OCEAN_DEPTH / 2, z),
				Vector3.new(tile, OCEAN_DEPTH, tile),
				Enum.Material.Water
			)
			Terrain:FillBlock(
				CFrame.new(x, -OCEAN_DEPTH - 2, z),
				Vector3.new(tile, 4, tile),
				Enum.Material.Slate
			)
			task.wait()
		end
	end

	-- Shallow sand shelf around the island so coastal water glows turquoise.
	local up = CFrame.new(-16, 0, -2)
	Terrain:FillCylinder(up * CFrame.new(0, -12, 0), 4, 155, Enum.Material.Sand)
	Terrain:FillCylinder(up * CFrame.new(0, -9, 0), 4, 120, Enum.Material.Sand)
	Terrain:FillCylinder(up * CFrame.new(0, -6.5, 0), 4, 92, Enum.Material.Sand)
end

local ISLAND_CORE = {
	{ -24, -8, 40 },
	{ -50, -2, 26 },
	{ 0, 2, 24 },
	{ -22, 22, 22 },
	{ -10, -36, 26 },
	{ 6, 22, 16 },
}

local function nearStairs(x: number, z: number): boolean
	return x > -17 and x < 5 and z > 22
end

local function nearPier(x: number, z: number): boolean
	return x > 12 and z > -2 and z < 18
end

local function buildIsland()
	for _, c in ISLAND_CORE do
		Terrain:FillCylinder(CFrame.new(c[1], -10, c[2]), 20, c[3], Enum.Material.Rock)
	end
	for _, c in ISLAND_CORE do
		Terrain:FillCylinder(CFrame.new(c[1], 3, c[2]), 6, c[3] - 3, Enum.Material.Grass)
	end
	task.wait()

	-- Boulder rim along the shore.
	local cx, cz, rx, rz = -22, -6, 50, 47
	for i = 1, 64 do
		local a = (i - 1) / 64 * math.pi * 2
		local x = cx + math.cos(a) * rx + rng:NextNumber(-3, 3)
		local z = cz + math.sin(a) * rz + rng:NextNumber(-3, 3)
		if not nearStairs(x, z) and not nearPier(x, z) then
			local r = rng:NextNumber(6, 9)
			Terrain:FillBall(Vector3.new(x, rng:NextNumber(-3, 0), z), r, Enum.Material.Rock)
			if i % 3 == 0 then
				Terrain:FillBall(Vector3.new(x * 1.02, -2, z * 1.02), r * 0.8, Enum.Material.Basalt)
			end
		end
	end
	task.wait()

	-- Workshop terrace and rocky hill behind it.
	Terrain:FillBlock(CFrame.new(-6, 4, -37), Vector3.new(46, 16, 30), Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-6, 14, -57), 18, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-30, 11, -54), 13, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(18, 10, -50), 11, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-6, 24, -60), 10, Enum.Material.Grass)
	Terrain:FillBall(Vector3.new(-28, 19, -56), 6, Enum.Material.Grass)
	-- Keep the workshop interior clear of the rear rocky hill (extends below TERRACE_Y=14.3 and clears corner voxels).
	Terrain:FillBlock(CFrame.new(-6, 22, -36), Vector3.new(34, 19, 24), Enum.Material.Air)

	-- Waterfall cliff behind the lagoon.
	Terrain:FillBall(Vector3.new(-50, 12, -18), 10, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-40, 10, -21), 8, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-58, 10, -16), 7, Enum.Material.Rock)
	Terrain:FillBall(Vector3.new(-52, 20, -20), 6, Enum.Material.Grass)
	task.wait()

	-- Lagoon basin: carve, sand floor, then water.
	local lagoon = CFrame.new(-44, 0, 2)
	Terrain:FillCylinder(lagoon * CFrame.new(0, 6, 0), 8, 16, Enum.Material.Air)
	Terrain:FillCylinder(lagoon * CFrame.new(0, 0, 0), 4, 17, Enum.Material.Sand)
	Terrain:FillCylinder(lagoon * CFrame.new(0, 4, 0), 4, 15, Enum.Material.Water)

	-- Cut for the front stairs.
	Terrain:FillBlock(CFrame.new(-6, 7, 39), Vector3.new(16, 16, 26), Enum.Material.Air)
	Terrain:FillBlock(CFrame.new(-6, -6, 39), Vector3.new(16, 10, 26), Enum.Material.Water)
end

-- Plaza, paths, spawn ----------------------------------------------------------------

```

Mais: dos dois lados da escadaria (X -17 e X 5, Z 28 a 49) o código antigo coloca esferas de rocha pequenas para formar as laterais:
```lua
for _, x in { -17, 5 } do
	for i = 0, 5 do
		local z = 28 + i * 4.2
		local y = PLAZA_Y - 4 - i * 1.6   -- PLAZA_Y = 10.3
		Terrain:FillBall(Vector3.new(x, y, z), rng:NextNumber(3.6, 4.4), Enum.Material.Rock)
	end
end
```

# 5) Direção de arte do terreno (o que eu quero ver)

- **Estilo:** cartoon "candy" estilizado e premium (Roblox), nada realista nem sombrio. Formas arredondadas, grandes e legíveis; paleta viva.
- **Contorno da ilha orgânico**: não um círculo perfeito. Baías pequenas, enseadas, pontas de rocha, praias de areia clara onde faz sentido (sul, oeste e leste), com transição suave grama → areia → água rasa turquesa.
- **Falésias de rocha em camadas** (estratos horizontais com variação de tom Rock/Basalt) na parte norte (colina atrás da oficina) e na cachoeira da lagoa. Alguns **arcos de pedra** e **pilares de rocha** isolados (sea stacks) ao redor da costa, sem bloquear a visão do mar.
- **Relevo suave na grama**: morrinhos baixos, desníveis leves, caminhos de terra/areia e pequenos platôs, tudo até ~3 studs de desnível para não atrapalhar a caminhada.
- **Lagoa de treino**: bacia mais bonita (margens irregulares, pedras e praia pequena, uma enseada que leva a cachoeira). Água até Y 8. Boa profundidade visual: fundo de areia clara que brilha turquesa.
- **Entrada pela escada**: o recife raso dos dois lados da escada fica turquesa claro (areia sob água rasa) com pedras redondas; a água em frente à escada deve ser rasa e convidativa.
- **Rocha abaixo da ilha**: a ilha parece flutuar/emergir do mar: rocha afinando para baixo em camadas, com reentrâncias e pedras soltas. Dá para ver isso da água no print `01-hub-visao-geral.jpg`.
- Variação de material: grama principal, grama-clara nas bordas, algumas faixas de areia e de basalto escuro nas rochas.
- Pode usar `Terrain:ReplaceMaterial` para mudar o tom em áreas, e cores de material ajustadas, desde que as cores de `Terrain:SetMaterialColor` sejam as mesmas ou documentadas no seu código.

# 6) Regras finais
- Respeite a caixa do hub (X -105..45, Y -14..60, Z -95..80). Nada fora dela.
- Nunca deixe terreno sólido (Rock/Grass/Sand/Basalt) acima de Y 10 dentro da área da praça nem dentro da casa da Oficina.
- Sem peças, sem scripts, sem Lighting. Só `workspace.Terrain`.
- Se algo no contrato estiver contraditório, escolha a opção que não bloqueia a caminhada e diga em uma linha qual escolheu.
- Entregue o arquivo completo em um único bloco de código e, depois, 5 linhas de resumo: o que mudou, tempo estimado do `build()`, riscos, pontos que ficaram diferentes do contrato e como rodar (`require(game.ServerStorage.DevTools.HubTerrainBuilder:Clone()).build()`).
