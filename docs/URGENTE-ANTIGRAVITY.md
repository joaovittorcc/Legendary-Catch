# URGENTE — Antigravity (agentes 1 e 2), depois do reinício do PC (~15:40)

**O que aconteceu:** o PC reiniciou às ~14:01 e o Studio reabriu a **última versão salva na nuvem (v16, 10:48)**.
Tudo que vocês fizeram depois **sumiu do place**:

- **Segmentação das criaturas (agente 1):** hoje 0 de 34 estão segmentadas. Só `C25`–`C34` e 16 protótipos existem.
- **Criaturas C35–C46 (agente 2):** hoje 0 de 30 estão no place.

Os prints em `art/creatures/` e as fichas em `art/creatures/PLANNED.md` continuam no disco.

**Regra nova: chame `save_place` depois de cada lote (3–5 criaturas), sem esperar o fim.** Anote a versão no Mural.

## Agente 2: refazer as 30 criaturas (C35–C64), lendários primeiro

- Ordem: **C60, C61, C62, C63, C64 (lendários)**, depois C56–C59 (épicos), C50–C55 (raros),
  C43–C49 (incomuns), C35–C42 (comuns). Fichas e prompts prontos em `art/creatures/PLANNED.md` (Lote 3).
- **Dica (Claude, testando `generate_mesh`):** com `segmentation = "explicit"` e `partNames`
  (ex.: `Body, Head, Tail, FinL, FinR, Extra`) a ferramenta **já devolve o modelo em partes**, sem
  precisar do `segment_mesh`. O resultado vem como `Body_geom`, `Head_geom`... (MeshParts) mais
  `InitialPoses`, `AnimationController` e `RootPart`.
- **Adapte à convenção do jogo:**
  - renomeie cada parte tirando o `_geom` (`Body`, `Head`, `Tail`...);
  - apague `InitialPoses`, `AnimationController`, `RootPart` e qualquer `Motor6D`;
  - deixe as partes **filhas diretas do Model**, com `PrimaryPart = Body`;
  - `Anchored = true` e `CanCollide/CanQuery/CanTouch = false`;
  - tamanho máximo ~3 studs (lendários até ~3.6), frente voltada para **+Z**;
  - `maxTriangles` até 12000 nos lendários.
- **Atenção à orientação:** nos testes, os modelos saíram com a frente em outra direção e achatados em
  Z (dragão e grifo com 1.3–1.4 de profundidade). Gire/ajuste e faça mais de uma tentativa.
- Nomes de parte aceitos: `Body`, `Head`, `Tail`, `FinL`, `FinR`, `Fins`, `Wings`, `Tentacles`, `Legs`,
  `Claws`, `Shell`, `Extra` (só os que existirem). O Claude já anima por esses nomes (`CreatureMotion`).
- Os 5 lendários têm que ser **extremamente épicos e detalhados**, os melhores do jogo.
  Salve o place a cada 1–2 lendários.

## Agente 1: segmentar as 34 criaturas atuais (C01–C34)

- Use `segment_mesh` (até 5 nomes) nas que existem como peça única, **ou** regenere com `generate_mesh`
  explícito se o corte ficar ruim. Mesma convenção de nomes, estrutura e orientação.
- Guarde o original como `<id>_static` em `ServerStorage.CreaturePrototypes`.
- Comece pelos lendários e épicos (`C09`, `C10`, `C20`–`C24`, `C29`, `C30`, `C33`, `C34`), depois o resto.
  `save_place` a cada lote.
