# Prompt para o Gemini — Releitura total de efeitos (VFX + SFX + animações) do Legendary Catch

> Cole tudo abaixo da linha no Gemini (modo Pro / Deep Think se tiver). Se a resposta vier cortada, mande "continue do arquivo X". Peça um módulo por vez se ele travar.

---

Você é um **Technical Artist / VFX & Game-Feel Designer sênior de Roblox** (Luau). Vou te dar o contexto de um jogo e quero que você faça uma **releitura completa de todos os efeitos visuais, sonoros e animações do jogo**, e entregue **código Luau pronto para colar no Roblox Studio**.

O objetivo é deixar o jogo **muito mais chamativo, vivo, colorido e "suculento" (juicy)**, sem pesar em celular fraco e sem incomodar crianças ou pessoas sensíveis a flashes.

## 1. O jogo

**Legendary Catch** é um jogo Roblox de **pesca fantástica e coleção**, mobile-first (também PC), público inclui crianças.

- O jogador começa com peixes comuns e escala até monstros místicos absurdos (Kraken Trovejante, Ouroboros, criaturas cósmicas, de magma, elétricas...). Raridades: **Comum (verde-água), Incomum (azul), Raro (roxo), Épico (rosa), Lendário (dourado)**.
- Paleta/estilo: aventura 3D estilizada premium, cores vivas, **cristais ciano/azul brilhantes, rosa/lilás, dourado, madeira quente, lanternas âmbar**. Nada cinza e genérico.
- **Hub (ilha principal)**: praça central com fogueira e cristais, oficina de varas (telhado azul), escadaria para o mar, **píer de pesca** de madeira, **cais de expedições** com portais para ilhas de pesca (Coral e Abismo), **santuário de treino** com 4 portais para ilhas de treino, **aquário** num deck sobre o mar, **placares flutuantes** (3 telas), **troféu** numa ilhota flutuante (mostra o melhor peixe do servidor, com o nome de quem pescou), árvore rosa gigante, cachoeira, lagoa, NPCs (Lucy vendedora de iscas, Luna, Vô Anzol / guia).
- **Ilhas de treino** (4 temas: Aprendiz, Recife, Abismo Estelar, Celestial): o jogador treina atributos (Controle / Instinto) em pontos de treino (semi-idle) e ganha "Poder de Pesca".
- **Ilhas de expedição** (Coral, Abismo): pesca em zonas com peixes mais raros, cada uma com seu troféu, placar e oficina.
- Eventos do oceano (tempestade, aurora etc.) mudam o clima/céu/água por um período.
- Ciclo dia/noite, lanternas que acendem à noite.

## 2. O loop principal (onde mais precisa de efeito)

1. **Equipar a vara** (Tool) e ficar perto da água/zona de pesca.
2. **Mirar + carregar o arremesso**: o jogador segura e uma **barra de poder** oscila; existem faixas (neutra → verde → amarela → vermelha/perfeita) e **6 skins da barra** que desbloqueiam conforme o "Poder de Pesca". Soltar = arremessar.
3. **Arremesso**: linha voa, boia cai na água (splash), ondulações.
4. **Espera**: boia balança, às vezes mergulha de leve.
5. **Fisgada (bite)**: o peixe morde. A **raridade já é conhecida pelo servidor** mas a criatura **só aparece depois de vencer** o minigame.
6. **Minigame de habilidade** (3 tipos: **Reel** [manter a zona], **Precisão** [acertar o ponto], **Ritmo** [notas]). Acerto "PERFEITO!", erros com tremida sutil.
7. **Revelação cinematográfica por raridade**: comum curta (até 2 s), lendário é evento (6–8 s, pulável depois de visto). A criatura gira com anel de HUD, nome, estrelas, selo "NOVA DESCOBERTA", peso e valor.
8. **HUD**: moedas animadas, nível/XP, "Próxima meta", "Poder de Pesca", botões (Coleção, Oficina, Config).
9. **Outros jogadores** pescando aparecem com linha + boia (+ brilho na luta).

## 3. Regras técnicas OBRIGATÓRIAS

- **Luau `--!strict`** em todo arquivo. Serviços no topo com `game:GetService`. Use `task.wait/spawn/delay/defer` (nunca `wait()`). **Parent por último**. Toda conexão tem dono e é desconectada. Sem `while true` solto: use `RunService` com um único loop central.
- **Tudo roda no CLIENTE** (LocalScript/ModuleScript do cliente). **O cliente nunca decide** moeda, item, captura ou raridade: você só **mostra** o que o servidor mandou. Não crie RemoteEvents novos nem toque em lógica de servidor.
- **Nada de Script/LocalScript dentro de modelos do mapa.** O mapa é gerado por código e é apagado/recriado; efeitos que dependem do mapa se ligam por **tags do `CollectionService`** + **atributos**.
- **Respeite `ReduceEffects`**: se `Players.LocalPlayer:GetAttribute("ReduceEffects") == true`, desligue/atenue tremidas, flashes, partículas pesadas, luzes dinâmicas e deixe só o essencial. Escute `GetAttributeChangedSignal("ReduceEffects")` e reaja ao vivo.
- **Performance mobile (celular fraco é o alvo)**:
  - máx. **~120 partículas vivas** no total em cena normal; **~250 no pico** (revelação lendária), por poucos segundos;
  - máx. **4 `PointLight`/`SpotLight` dinâmicas ativas** ao mesmo tempo perto do jogador; prefira `Neon` + `Bloom` fake (billboard glow) a luz real;
  - **reaproveite instâncias (pooling)**; nada de criar/destruir centenas de Parts por frame; use `Debris`/pool;
  - **sem pós-processamento permanente** novo (`Bloom`, `ColorCorrection`, `DepthOfField`, `Blur` só durante eventos e sempre desfeitos com `TweenService` ao terminar);
  - culling por distância: efeitos ambientais só rodam a < ~120 studs da câmera; use `Heartbeat` com um único registro central (cada tag não cria seu próprio loop).
- **Acessibilidade / crianças**: sem flash branco de tela cheia mais de **3 vezes por segundo**; flashes de tela cheia sempre com **opacidade máx. ~0,6** e curtos (< 0,15 s); tremida de câmera sutil (< 0,6 stud) e desligável. Nada assustador.
- **Texturas**: não invente `rbxassetid` de imagem. Use texturas nativas (`rbxasset://textures/particles/sparkles_main.dng`, `rbxasset://textures/particles/smoke_main.dng`, `rbxasset://textures/particles/fire_main.dng` etc.) e formas simples (`Ball`, `Cylinder`, `Neon`, `Beam`, `Trail`, `ParticleEmitter`, `UIGradient`, `UIStroke`, `Frame` animado). Se uma textura custom ajudar muito, deixe um campo `TEXTURES.nome = "rbxassetid://0 -- TROCAR"` e **funcione bem sem ela** (fallback).
- **Sons**: não invente IDs de som. Crie uma tabela central `SOUND_IDS` com `"rbxassetid://0 -- TROCAR: <descrição do som ideal>"` e o código deve **não tocar nada (sem erro, sem warn em loop)** quando o ID for `0`. Use variação de `PlaybackSpeed` (±8%), `Volume` por categoria (SFX / Música / UI) via `SoundGroup`, `RollOffMaxDistance` para sons 3D e um **cooldown por som** para não encher o áudio.
- **Idioma**: comentários e nomes de código em **inglês**; textos para o jogador (se houver) em **português do Brasil**, curtos.
- **Não use dependências externas** (Wally, Packages).

## 4. O que quero que você ENTREGUE

Um **kit modular** com a estrutura abaixo. Para cada arquivo: caminho sugerido no Studio (ex.: `ReplicatedStorage/Shared/Vfx/VfxKit` ou `StarterPlayerScripts/Features/...`), o **código completo**, e logo acima um comentário com **como integrar** (qual evento/atributo/tag chama o quê).

### 4.1 Núcleo (ModuleScripts)
1. **`VfxKit`**: pooling de partículas/Parts/Beams/Attachments, e helpers prontos: `burst(position|attachment, preset, intensity)`, `ring(position, color, radius, duration)`, `pillarOfLight`, `sparkTrail`, `shockwave`, `confettiBurst`, `glowPulse(part)`, `floatingText(position, text, color)`, `screenFlash(color, alpha, time)` (respeitando acessibilidade), `cameraShake(amount, time)` (respeitando `ReduceEffects`). Tudo com `intensity 0..1` e `tier 1..5`.
2. **`SfxKit`**: registro de sons com categorias, cooldown, variação de pitch, 2D/3D, `play(name, options)`, `playAt(name, position)`, música ambiente por região com crossfade (hub / píer / treino / aquário / expedição / evento) usando `SoundGroup`.
3. **`Palette`**: cores por raridade (Comum 0,200,170 • Incomum azul • Raro roxo • Épico rosa • Lendário dourado) e por faixa de poder, mais função `colorForCharge(charge, tier)`.
4. **`HubAnimator`** — **este é obrigatório**: um único módulo que anima o mapa por tags. Tags e atributos **exatamente** assim (o gerador do mapa já os cria):
   - `HubSpin` — atributos `Speed` (rad/s), `Axis` ("X"|"Y"|"Z"), `Phase`
   - `HubBob` — `Amplitude` (studs), `Speed`, `Phase` (sobe e desce)
   - `HubPulse` — `Min`, `Max`, `Speed`, `Target` (nome da propriedade: ex. "Transparency", "Brightness", "Size")
   - `HubFlicker` — `Intensity` (cintilar de chama/lanterna, ruído)
   - `HubSway` — `Angle` (graus), `Speed` (balançar de bandeirolas/folhas)
   - `HubWave` — `Amplitude`, `Speed`, `Phase` (ondular)
   Regras: guarde o CFrame/valor base de cada instância; use **um** `RunService.Heartbeat`; só anime o que está perto da câmera; escute `GetInstanceAddedSignal`/`RemovedSignal`; com `ReduceEffects` reduza a amplitude e pare o flicker; **nunca acumule erro** (sempre calcule a partir da base).

### 4.2 Pesca (o mais importante — capriche)
5. **`FishingChargeFx`** — *carregando o arremesso*: enquanto o jogador segura, aparecem **partículas na mão/ponta da vara** que **crescem com a força**. Parametrize por `charge (0..1)` e `tier (1..6, vem das skins da barra)`:
   - 0–25%: poucas faíscas pequenas da cor da faixa;
   - 25–60%: anel girando ao redor da mão + partículas em espiral subindo, cor mudando de acordo com a faixa;
   - 60–90%: mais partículas, rastro de luz na vara, leve brilho na luz, som de "carga" subindo de pitch;
   - **faixa vermelha/perfeita**: explosão de cor arco-íris/dourada na mão, aura, partículas "estourando" e um **ding** de acerto;
   - tiers mais altos = formas/cores mais ricas (estrelas, cristais, penas, runas simples), nunca mais partículas do que o orçamento permite.
   Ao soltar: **burst de lançamento** proporcional ao poder + **whoosh** + rastro na linha.
6. **`CastFlightFx`** — linha/boia no ar: `Trail` colorido pela força, faíscas caindo, **splash** na água (anéis + gotas) com tamanho proporcional ao poder; ondulações que se expandem e somem.
7. **`BobberFx`** — boia esperando: balanço suave, **anéis sutis** periódicos na água, **brilho que aumenta** quando a fisgada está próxima, e na **fisgada (bite)**: mergulho brusco, esguicho, "!" flutuante, som de alerta (cor pela raridade, mas **sem entregar qual criatura**).
8. **`MinigameFx`** — para os 3 minigames (Reel, Precisão, Ritmo): partículas no acerto, **"PERFEITO!"** com estrelas, combo crescendo (cor sobe a cada acerto), tremida suave no erro, **primeira falha bem sinalizada**, **barra de progresso com brilho** que vai ficando mais intensa perto de vencer, e na vitória um **estouro** na cor da raridade. Dê funções `onHit(quality)`, `onMiss()`, `onProgress(p)`, `onWin(rarity)`, `onLose()`.
9. **`CatchRevealFx`** — camadas de ambiente para a **revelação** por raridade (a UI da revelação já existe; você cuida do **mundo e da tela**): 
   - Comum: pulinho de luz + faíscas verde-água, ≤ 2 s;
   - Incomum: coluna de luz azul + anéis;
   - Raro: raios roxos zigue-zague na água, ondas de choque;
   - Épico: tela escurece, partículas rosa em espiral, onda de choque forte;
   - **Lendário**: evento de 6–8 s: céu escurece, coluna de luz dourada gigante, raios, onda de choque, flash curto (com limite de acessibilidade), chuva de estrelas/confete dourado, aura no jogador, **pulável** (função `skip()`).
   - Variações por `revealStyle` (string): `"electric"`, `"cosmic"`, `"magma"`, `"abyss"`, `"celestial"`, `"default"` — cada uma troca paleta, textura de partícula e som.
   - Selo "NOVA DESCOBERTA": brilho + confete extra.
10. **`CharacterPoseFx`** — gancho para as animações procedurais do personagem na pesca (arremesso: puxa a vara pra trás e lança; luta: corpo inclinado e vara tensionada; comemoração). Entregue **funções que recebem o `Character`** e mexem nos `Motor6D`/`AnimationConstraint` via `Transform` em `PreSimulation` (atenção: em avatar novo o ombro é `AnimationConstraint`, não `Motor6D`) e **documente os ganchos** para eu trocar depois por `Animation` do Studio.
11. **`OtherPlayersFishingFx`** — para os outros jogadores pescando (linha + boia + brilho durante a luta, cor da raridade), com **LOD**: a mais de 80 studs só mostra a boia.

### 4.3 Mundo e UI
12. **`PortalFx`** — **todos os portais** (tag `ZonePortal`, atributos `PrimaryColor`/`AccentColor`, às vezes `nil`: use cor padrão): vórtice girando, partículas sugadas para o centro, runas em volta, pulso quando o jogador chega perto, **efeito de teletransporte** (clarão curto na cor do portal + redemoinho de partículas + som) na ida e na chegada.
13. **`AquariumFx`** — aquário (tanque tag `AquariumTank`): bolhas subindo, raios de luz na água (god rays falsos com `Beam`), peixes com **brilho/cauda de partículas** por raridade, **moedas que saltam** quando o aquário gera renda, brilho dourado em "gigante/gold", efeito ao **subir de nível do tanque** (troca de nível com onda de luz), e cintilar suave no vidro.
14. **`TrainingFx`** — pontos de treino (tag `TrainingSpot`, atributos `TrainingStat` = "Control" | "Instinct"): aura de energia diferente por atributo, **anéis de ritmo**, números flutuantes de ganho, **efeito ao subir de nível** (coluna de luz + estrelas + som crescente) e feedback do "Poder de Pesca".
15. **`HudJuiceFx`** — UI: contador de moedas com **pulo e brilho** ao ganhar, moedas voando da captura até o contador, barra de XP com brilho passando, "Próxima meta" que pisca ao ficar disponível, botões com **hover/press** (ignorar hover em toque), toasts com entrada elástica. Use `TweenService`, `UIStroke`, `UIGradient`.
16. **`WorldAmbientFx`** — vida do mundo: vaga-lumes e pólen no hub à noite, folhas caindo da árvore rosa, **cristais** pulsando e soltando faíscas, gotas e névoa na cachoeira, **peixinhos saltando** no mar perto do píer (pequenos arcos com splash), gaivotas/ondas simples, brilho nas lanternas ao anoitecer, fogueira com faíscas, **troféu** com halo girando e brilho que muda com a raridade do peixe exibido, **placares** com leve brilho/rotação suave.
17. **`OceanEventFx`** — eventos do oceano (leia atributos de `ReplicatedStorage`: `OceanEvent` e `OceanEventEndsAt`): tinta de céu/água, partículas de clima (chuva, aurora, bruma), relâmpagos suaves, banner com contagem regressiva animada. Tudo com fade-in/fade-out e desfeito no fim.
18. **`CollectionFx`** — coleção/bestiário e loja: brilho nas criaturas descobertas, silhueta que "revela" ao descobrir, carrossel de varas com partícula do bônus (Controle/Sorte), efeito de **compra** (confete + som de caixa registradora).

## 5. Mapa de intensidade (escada do extraordinário)

> **Se tudo brilhar, nada brilha.** Comum é simples e rápido; lendário é espetáculo.

| Momento | Comum | Incomum | Raro | Épico | Lendário |
|---|---|---|---|---|---|
| Fisgada | gota + "!" verde | + anel azul | + raio leve | + coluna rosa | + coluna dourada + tremor |
| Minigame (vitória) | burst pequeno | burst + anel | burst + estrelas | burst + onda | evento dourado |
| Revelação | ≤ 2 s | ~3 s | ~4 s | ~5 s | 6–8 s, pulável |
| Partículas pico | ~30 | ~60 | ~100 | ~160 | ~250 (poucos segundos) |

## 6. Como quero a resposta

1. **Primeiro** (curto): um **plano de integração** — lista dos arquivos, onde cada um vai, e a **ordem** de implementação (do que mais impacta para o que menos).
2. **Depois**, um bloco de código **completo e funcional** por arquivo (sem "...", sem pseudo-código, sem `-- TODO` no que é essencial). Se não couber tudo, entregue **primeiro o núcleo + HubAnimator + FishingChargeFx + CastFlightFx + BobberFx + MinigameFx** e avise que o resto vem na próxima mensagem.
3. **No fim**: uma **lista de testes** (como forçar cada efeito no Studio, ex.: chamar `FishingChargeFx.update(0.9, 4)` num loop) e uma **tabela de custos** (quantas partículas/luzes/instâncias cada efeito usa).
4. **Não faça perguntas** — se faltar informação, assuma o mais razoável, **escreva a suposição num comentário** e siga.
5. Aponte **o que você NÃO tem certeza** de que existe na API do Roblox em vez de inventar. Prefira APIs estáveis e conhecidas.

## 7. Proibido

- Criar RemoteEvents, mexer em dados do jogador, moedas, captura, raridade ou servidor.
- Scripts dentro de modelos do mapa.
- IDs de asset inventados (use `0 -- TROCAR`).
- Flashes agressivos, tremida forte, efeitos que não podem ser desligados.
- Loops `while true do wait()`, `wait()`, criar centenas de instâncias por frame.
- Deixar efeitos vivos depois que terminam (vazamento de memória/conexões).

Comece pelo plano de integração e já entregue o núcleo (`VfxKit`, `SfxKit`, `Palette`, `HubAnimator`) na mesma resposta.
