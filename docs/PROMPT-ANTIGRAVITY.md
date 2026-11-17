# Prompt para o Antigravity — recuperar e terminar as criaturas do Legendary Catch

Cole este arquivo inteiro numa conversa do Antigravity aberta na pasta do projeto
(`C:\Users\Evojota\dev\jogo ainda sem nome`). Dá pra usar em **duas conversas em paralelo** (Agente 1 e
Agente 2), cada uma fazendo só a sua parte (seções 4 e 5).

---

## 1. Quem você é e o projeto

Você é um agente do time que faz o **Legendary Catch**, um jogo de pesca e coleção de criaturas no Roblox
(ilha mágica compacta, pesca com minigames, revelação cinematográfica da criatura, bestiário).
Quem manda é o **João**. Fale com ele em português informal e curto. Código, nomes e commits em inglês.

Antes de qualquer coisa, leia:

1. `AGENTS.md` (contexto geral e regras do time);
2. `docs/COORDENACAO.md` (donos de cada arquivo e o **Mural**, no fim: registre ali o que fizer);
3. `art/creatures/PLANNED.md` (fichas e prompts das criaturas).

Você é dono do **mapa e dos modelos 3D** (criaturas, varas, ilha). **Não edite** código de gameplay
(`src/**`), que é do Claude e do Codex. Se precisar de algo deles, escreva no Mural.

## 2. O que aconteceu (por que este pedido existe)

O PC do João reiniciou às ~14:01. O Roblox Studio reabriu na **última versão salva na nuvem (v16, 10:48)**.
Tudo que não tinha sido salvo **sumiu do place**:

- a **segmentação** das criaturas em partes (hoje **0 de 34** estão segmentadas);
- as criaturas **C35 a C46** (hoje **0 de 30** estão no place).

O que continua existindo: `C01`–`C34` (peças únicas), 16 protótipos em `ServerStorage.CreaturePrototypes`,
os prints em `art/creatures/` e as fichas em `PLANNED.md`.

### Regra nova, vale pra tudo

**Chame `save_place` depois de cada lote de 3 a 5 criaturas (ou 1 a 2 lendários).** Não espere o fim.
Anote no Mural a versão salva.

## 3. Como o Studio funciona hoje

- A **janela do Studio aparece preta** no PC do João (problema de vídeo depois do reinício), mas o **MCP funciona**:
  `execute_luau`, `generate_mesh`, `screen_capture`, `save_place`, `start_stop_play`.
- O id do Studio **muda** quando ele reabre: chame `list_roblox_studios` e use o id da instância do place
  `112666482424701`.
- Os prints saem **pequenos** porque a tela está em 640x480. Tudo bem; enquadre bem a criatura.
- **Trava:** antes de dar Play ou salvar, crie o arquivo `.studio-lock` na raiz do projeto com seu nome e a
  hora (ex.: `Antigravity-1 15:40`). Se já existir e tiver menos de 10 min, espere. Apague ao terminar.
  O Claude e o Codex também dão Play. Plays de no máximo 3 min.
- O Rojo (código) está desconectado; **não precisa dele** para modelos.

## 4. AGENTE 2 — refazer as 30 criaturas (C35–C64), lendários primeiro

Ids, raridade, nomes e lore já estão em `src/shared/Config/Creatures.luau` (tabela `PLANNED`) e em
`src/shared/Strings.luau`. **Não mexa nesses arquivos.** Quando as criaturas estiverem no place, o Claude as
libera no jogo.

### Ordem

1. **C60 a C64 (os 5 lendários).** São a prioridade.
2. C56–C59 (épicos), 3. C50–C55 (raros), 4. C43–C49 (incomuns), 5. C35–C42 (comuns).

As fichas completas (silhueta, paleta, partes, box, prompt) de todas estão em `art/creatures/PLANNED.md`,
seção "Lote 3". Os 5 lendários, resumidos:

| Id | Criatura | Pontos-chave | Box (studs) | Partes |
|---|---|---|---|---|
| `C60_Hidra_das_Profundezas` | Hidra das Profundezas | 3 cabeças de dragão-serpente em pescoços longos abertos em leque, torso azul-abissal com armadura dourada, barbatanas em leque, cauda com tridente, runas ciano `Neon` | 3.4 × 3.2 × 3.5 | `Body, Head, Tail, FinL, FinR, Extra` |
| `C61_Baleia_Celestial` | Baleia Celestial | corpo azul-estelar/violeta com galáxia espiral visível no tronco, anéis dourados orbitando, nadadeiras aladas, cauda de cometa, estrelas `Neon` | 3.5 × 2.8 × 3.6 | `Body, Head, Tail, FinL, FinR, Extra` |
| `C62_Dragao_Dourado` | Dragão Dourado da Tempestade | placas em ouro puro e cobalto, chifres ramificados, juba de tempestade, asas abertas com raios dourados esculpidos, garras, cauda em lança de raio | 3.6 × 3.3 × 3.4 | `Body, Head, Wings, Claws, Tail, Extra` |
| `C63_Grifo_Marinho` | Grifo-Marinho Real | metade águia dourada e branca com coroa solar e asas enormes, metade peixe turquesa com cauda em leque real | 3.5 × 3.2 × 3.4 | `Body, Head, Wings, Claws, Tail, Fins` |
| `C64_Guardiao_Abissal` | Guardião Abissal | titã de armadura de basalto, corais e bronze, capacete com visor rúnico, braços enormes, lanterna ancestral `Neon` âmbar-ciano, manto de raízes-tentáculo | 3.3 × 3.6 × 3.2 | `Body, Head, Claws, Tentacles, Shell, Extra` |

**Os 5 têm que ser EXTREMAMENTE épicos e detalhados, os melhores do jogo** (acima do Leviatã, do Kraken e da
Fênix). Faça **pelo menos 2 tentativas** de cada e fique com a melhor. Orçamento: até ~12.000 triângulos e
várias peças `Neon` nos destaques mágicos.

### Como gerar (descoberta importante)

O `generate_mesh` com `segmentation = "explicit"` e `partNames` **já devolve o modelo cortado em partes**.
Não precisa do `segment_mesh`. Exemplo para a hidra:

```
generate_mesh(
  textPrompt = "<prompt da ficha>",
  size = {x=3.4, y=3.2, z=3.5},
  maxTriangles = 11500,
  segmentation = "explicit",
  partNames = "Body, Head, Tail, FinL, FinR, Extra"
)
```

O resultado vem como um Model com `Body_geom`, `Head_geom`... (MeshParts), mais `InitialPoses`,
`AnimationController` e `RootPart`. Você **precisa adaptar à convenção do jogo** (próxima seção).
Se uma parte sair ruim, gere de novo com outra lista de partes ou com `segmentation = "none"` e use
`segment_mesh` depois.

### Prompts dos 5 lendários (use como base; melhore se achar)

- **C60:** `Stylized cartoon monumental three-headed abyssal sea hydra boss monster facing forward +Z, massive armored deep-ocean navy and royal-gold serpent torso with three distinct long curved necks rising to three majestic crowned dragon heads roaring side by side toward +Z, glowing golden eyes, flared thorny teal-and-gold fin wings, long coiled trident tail behind, ornate gold armor plates and electric cyan runes, Roblox fantasy adventure masterpiece`
- **C61:** `Stylized cartoon colossal celestial galaxy whale swimming forward +Z, majestic deep-space cosmic-blue and violet whale torso featuring a glowing swirling spiral galaxy nebula window inside its chest and flank, adorned with ornate golden celestial rings encircling its waist, sweeping wing-like starlit pectoral fins, glowing golden star runes and forked comet tail behind, serene wise glowing golden eyes facing +Z, Roblox fantasy adventure masterpiece`
- **C62:** `Stylized cartoon supreme golden storm sea dragon boss facing forward +Z, armored radiant pure-gold and cobalt-indigo dragon torso with noble fierce-friendly head, giant branching golden antlers, flowing storm-cloud mane, massive spread wings crackling with sculpted golden lightning bolts, sharp clawed forelimbs and long sweeping lightning-spear tail, glowing golden-white eyes, Roblox fantasy adventure masterpiece`
- **C63:** `Stylized cartoon majestic royal sea griffin hybrid facing forward +Z, regal white-and-gold armored eagle upper torso with noble hooked golden beak, golden sun crown crest, huge spread feathered wings tipped in sky-cyan and sharp golden eagle talons, seamlessly transitioning into an armored turquoise-and-gold scaled fish lower torso with sweeping ornate fan fish tail behind, fierce proud golden eyes, Roblox fantasy adventure masterpiece`
- **C64:** `Stylized cartoon ancient abyssal titan guardian of the deep sea facing forward +Z, colossal armor of dark oceanic basalt stone, ancient coral and worn bronze-gold with turquoise barnacles, helmet with glowing runic visor, enormous armored arms, holding a huge ancient glowing amber-and-cyan lantern, flowing abyssal root-tentacle cloak behind, glowing rune lines on the armor, Roblox fantasy adventure masterpiece`

Nos testes do Claude, a geração saiu **achatada em Z** (dragão com ~1.3 e grifo com ~1.4 de profundidade) e com a
frente possivelmente para outro lado. Confira, gire e escale; se continuar achatado, mude o `size` ou o prompt
e gere de novo.

## 5. AGENTE 1 — segmentar as 34 criaturas atuais (C01–C34)

Hoje elas são peças únicas. O Claude já escreveu a animação por partes (cauda abana, barbatanas batem, asas,
tentáculos, cabeça, pernas, garras); falta as criaturas terem as partes.

- Para cada criatura, use `segment_mesh` (até 5 nomes por chamada) **ou**, se o corte ficar ruim, regenere com
  `generate_mesh` explícito mantendo a aparência. Faça um **piloto de 3 ou 4 criaturas, confira no print e só
  então vá em lote**.
- **Guarde o original** como `<id>_static` em `ServerStorage.CreaturePrototypes`.
- **Ordem:** lendários e épicos primeiro (`C09`, `C10`, `C20`–`C24`, `C29`, `C30`, `C33`, `C34`), depois o resto.
- Se o `segment_mesh` encolher o modelo (já aconteceu com a `C26`: Z de 2.05 para 0.79), reverta para o
  original e tente outra lista de nomes. Se não der, deixe só `Body` e anote no Mural.

## 6. Convenção obrigatória dos modelos (vale pros dois agentes)

Cada criatura é um `Model` em `ReplicatedStorage.Creatures`, **nome igual ao id** (ex.: `C60_Hidra_das_Profundezas`):

- partes **filhas diretas do Model** (não dentro de subpasta) com **exatamente** estes nomes, só os que existirem:
  `Body` (obrigatório), `Head`, `Tail`, `FinL`, `FinR`, `Fins` (quando não dá pra separar esquerda e direita),
  `Wings`, `Tentacles`, `Legs`, `Claws`, `Shell`, `Extra` (enfeites: coroa, lanterna, runas, anéis...);
- `PrimaryPart = Body`, **pivô no centro do `Body`**;
- todas as peças com `Anchored = true` e `CanCollide = false`, `CanQuery = false`, `CanTouch = false`;
- **sem soldas, `Motor6D`, scripts, tags, `AnimationController`, `InitialPoses` nem `RootPart`**;
- **frente voltada para `+Z`**;
- tamanho: maior dimensão **até ~3 studs** (os 5 lendários podem ir até ~3.6);
- `Neon` só onde brilha (olhos, runas, lanterna, estrelas).

Confira cada modelo no `screen_capture` (3/4 de frente, fundo limpo) e rode uma checagem rápida:
`PrimaryPart` definido, todas as partes ancoradas, nenhuma parte com tamanho zero.

## 7. Entregáveis e como registrar

- Um print por criatura em `art/creatures/Cxx-nome.jpg` (mesmo enquadramento do catálogo) e o
  `art/creatures/README.md` atualizado.
- Fichas das criaturas novas em `art/creatures/PLANNED.md`.
- **`save_place` a cada lote** e uma linha no Mural (`docs/COORDENACAO.md`) dizendo quais criaturas ficaram
  prontas e a versão salva. **Escreva no Mural ao começar e a cada lote.**
- Commit só dos **seus** arquivos (`git add` arquivo por arquivo, sem `git add .`), mensagem em inglês
  (ex.: `art(creatures): ...`). **Não faça push.**

## 8. Regras do time

- Não edite `src/**`, `src/shared/Config/**`, `src/shared/Strings*.luau` nem `docs/NOITE.md`.
- Não mova nada para `Creatures.LIST`: quem libera no jogo é o Claude, depois de conferir.
- Não mexa na ilha, nas varas nem no mapa nesta tarefa.
- Se travar, escreva no Mural o que tentou e o erro exato, e siga para a próxima criatura.
- Seja honesto sobre o que **não** testou.

Pronto. Comece pelo **Agente 2: C60 a C64**, salvando o place a cada 1 ou 2 lendários.
