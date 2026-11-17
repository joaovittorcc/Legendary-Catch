# Ficha de Produção — Próximo Lote de Criaturas (C25–C30)

Especificação visual e prompts prontos para `generate_mesh` das 6 criaturas de `Config.Creatures.PLANNED` (`src/shared/Config/Creatures.luau` e `src/shared/Strings.luau`).

> **Regras técnicas do lote (padrão A2 / A11):**
> - Orientação obrigatória: frente voltada para **`+Z`** (olhos/rosto visíveis no bestiário e na revelação).
> - Caixa final padronizada em `ReplicatedStorage.Creatures`: maior dimensão `<= 3.0` studs (a escala de captura/troféu é ajustada no jogo; a silhueta e proporção já comunicam o porte).
> - Orçamento para celular: `segmentation = "none"` (peça única), `maxTriangles` entre `3500` (Comum) e `7500` (Lendário), sem scripts, sem colisão, `Anchored = true`.
> - Cores das raridades (`Config.Fishing.RARITY_COLORS`): Comum verde-água `#78E6AA`, Incomum azul `#50C8FF`, Raro roxo `#BE78FF`, Épico rosa `#FF64DC`, Lendário dourado `#FFCD46`.

---

## 1. C25 — Ouriço Gelatina (`C25_Ourico_Gelatina`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.1–0.6 kg` · **Valor base:** `12 ◆` · **Reveal:** `bubbles`
- **Lore:** *"Parece espinhento, mas é molinho. Balança feito pudim quando fica feliz."*
- **Silhueta:** Cúpula redonda e fofa tipo pudim/gelatina (`dome` levemente achatada na base), cercada por 10–12 espinhos grossos de ponta bem arredondada (como gotinhas de geleia, sem pontas afiadas agressivas). Leitura imediata mesmo em silhueta escura na Coleção.
- **Paleta (Comum — Verde-Água):** Corpo principal em gelatina verde-água translúcida brilhante (`#78E6AA` → `#B8FFF0`), topo/espinhos em menta-claro com pontinhas pêssego suave e brilho branco tipo cobertura de pudim.
- **Detalhes de personalidade:** Olhos redondos grandes e brilhantes bem juntos na frente (`+Z`), bochechas rosadas, micro-sorriso em "w" e pequenas bolhinhas pintadas sob a superfície gelatinosa.
- **Tamanho relativo (box `generate_mesh`):** `1.9 × 1.7 × 1.9` studs (pequeno, compacto e saltitante) · `maxTriangles = 3500`.
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon cute squishy jelly sea urchin creature shaped like a bouncy mint-aqua pudding dome covered in thick blunt rounded jelly spines, glossy translucent seafoam-green and pastel cyan gradient with creamy shine highlights, big adorable dark eyes with crisp white catchlights, rosy cheeks and happy tiny w-mouth facing forward +Z, Roblox adventure game style, single piece
  ```

---

## 2. C26 — Peixe-Pipa (`C26_Peixe_Pipa`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.2–0.9 kg` · **Valor base:** `13 ◆` · **Reveal:** `splash`
- **Lore:** *"Abre as nadadeiras e plana sobre as ondas quando o vento sopra do mar."*
- **Silhueta:** Corpo esguio em formato de pipa/losango aerodinâmico quando visto de cima/frente: duas nadadeiras peitorais bem largas e triangulares como velas/asas de pipa, além de cauda longa em fita dupla ondulada como rabiola. Bem distinta da `C01` (redonda), `C02` (sardinha) e `C16` (asas de dragão/morcego do Voador).
- **Paleta (Comum — Verde-Água + Sol):** Dorso turquesa-menta (`#64E2B8`), asas com listras alegres em creme, coral-suave e amarelo-sol (como pipa de praia), barriga branca limpa.
- **Detalhes de personalidade:** Olhinhos animados com expressão aventureira apontando para `+Z`, sorrisinho confiante, rabiola com dois laços coloridos nas pontas para dar movimento no giro do bestiário.
- **Tamanho relativo (box `generate_mesh`):** `2.6 × 1.4 × 2.8` studs (envergadura larga e corpo leve) · `maxTriangles = 3800`.
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon joyful kite fish with sleek diamond-shaped turquoise-mint body, wide triangular sail-like pectoral fins patterned like a colorful beach kite in seafoam-green, warm cream and soft coral stripes, long double ribbon tail streamers behind, crisp big glossy dark eyes with white highlights and cheerful smile facing forward +Z, Roblox adventure game style, single piece
  ```

---

## 3. C27 — Ermitão de Cristal (`C27_Ermitao_Cristal`)
- **Raridade:** Incomum (`tier = 2`) · **Peso:** `0.5–2.2 kg` · **Valor base:** `44 ◆` · **Reveal:** `crystal`
- **Lore:** *"Troca de casa toda lua cheia. A de agora é um cristal que brilha no escuro."*
- **Silhueta:** Assimetria marcante de caranguejo-eremita: metade de trás carregando uma grande concha-espiral esculpida em **drusa de cristal** com pontas inclinadas para o alto e para trás; metade da frente com duas garras desiguais (uma garra escudo maior e outra menor) e quatro patinhas saindo da abertura.
- **Paleta (Incomum — Azul Cristal):** Concha em cristal azul-celeste e ciano luminoso (`#50C8FF` → `#A8F6FF`, combinando direto com os cristais da ilha); corpinho do eremita em pêssego-coral quentinho com pontas das garras azul-safira para alto contraste.
- **Detalhes de personalidade:** Olhos em pequenas hastes bem definidos e brilhantes olhando para `+Z`, expressão curiosa/tímida espiando de dentro do cristal, pequenas lascas de cristal azul brotando na garra maior.
- **Tamanho relativo (box `generate_mesh`):** `2.2 × 2.3 × 2.6` studs (mais alto pela drusa nas costas) · `maxTriangles = 4800`.
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon cute hermit crab living inside a glowing faceted sky-blue and cyan crystal spiral shell with crystal spires rising from the back, warm peach-coral crab body peeking out the front with one big armored sapphire-tipped claw, smaller left claw and stubby legs, big crisp shiny dark eyes on short stalks and friendly expression facing forward +Z, Roblox adventure game style, single piece
  ```

---

## 4. C28 — Náutilo Aurora (`C28_Nautilo_Aurora`)
- **Raridade:** Raro (`tier = 3`) · **Peso:** `2–10 kg` · **Valor base:** `135 ◆` · **Reveal:** `prism`
- **Lore:** *"A concha guarda as cores do céu do amanhecer. Gira devagar pra mostrar todas."*
- **Silhueta:** Grande concha em espiral vertical perfeitamente desenhada (furo central e câmaras marcadas em relevo suave), capuz superior elegante e um feixe de tentáculos curtos organizados na frente abaixo dos olhos — silhueta clássica e nobre, totalmente única entre as Raras.
- **Paleta (Raro — Roxo + Aurora):** Concha perolada em gradiente aurora: roxo-ametista (`#BE78FF`) no centro da espiral, passando por rosa-aurora e dourado-pêssego nas bordas externas; tentáculos em violeta profundo com ventosas claras.
- **Detalhes de personalidade:** Olhos grandes estilizados com íris cintilante rosa/dourada nas laterais frontais do rosto (`+Z`), pequenas faixas iridescentes na borda da concha e capuz com textura nacarada.
- **Tamanho relativo (box `generate_mesh`):** `2.0 × 2.6 × 2.7` studs (concha imponente erguida) · `maxTriangles = 5500`.
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon mystical aurora nautilus creature with large sculpted pearlescent spiral shell glowing in smooth sunrise gradients of royal violet, pastel rose and warm gold, elegant purple hood and neat bundle of curled violet-pink tentacles below, crisp large expressive starry eyes with bright highlights facing forward +Z, clean hand-painted Roblox adventure style, single piece
  ```

---

## 5. C29 — Dragão-Folha Esmeralda (`C29_Dragao_Folha`)
- **Raridade:** Épico (`tier = 4`) · **Peso:** `8–30 kg` · **Valor base:** `390 ◆` · **Reveal:** `spark`
- **Lore:** *"Se esconde entre as algas imitando uma folha. Só os mais atentos percebem."*
- **Silhueta:** Baseada em dragão-marinho folhoso: pescoço sinuoso em "S" e focinho alongado e elegante voltado para `+Z`, mas ornamentado por **grandes apêndices em forma de folhas/algas flutuantes** saindo da crista, dorso e cauda enrolada — silhueta rica e esvoaçante, imediatamente reconhecível como Épico.
- **Paleta (Épico — Rosa-Magenta + Esmeralda):** Corpo principal em verde-esmeralda luminoso e turquesa (`#24D29A`), enquanto as pontas das grandes folhas translúcidas brilham em **rosa-magenta épico (`#FF64DC`)** e dourado claro (bioluminescência mágica, unindo o tema botânico com a cor de raridade Épica).
- **Detalhes de personalidade:** Olhos grandes cor de âmbar/magenta com pupila nítida e brilho branco, coroa de folhas na cabeça, cauda em espiral na base e nervuras luminosas nas folhas dorsais.
- **Tamanho relativo (box `generate_mesh`):** `2.2 × 3.0 × 2.5` studs (esguio e alto, porte nobre) · `maxTriangles = 6500`.
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon majestic leafy sea dragon creature with graceful S-curved emerald-green and teal body, ornate sculpted leaf-shaped fins and ribbons along head crest, back and curled tail glowing with vibrant epic magenta-pink and gold tips, elongated dragon snout, crisp luminous amber eyes with sharp dark pupils and white highlights facing forward +Z, Roblox fantasy adventure style, single piece
  ```

---

## 6. C30 — Tartaruga-Ilha Ancestral (`C30_Tartaruga_Ilha`)
- **Raridade:** Lendário (`tier = 5`) · **Peso:** `3000–9000 kg` · **Valor base:** `1650 ◆` · **Reveal:** `crystal`
- **Lore:** *"Tão antiga que nasceu uma ilha nas costas dela. Alguns dizem que a nossa ilha também."*
- **Silhueta:** A peça mais monumental e detalhada do jogo. Corpo largo e maciço de tartaruga marinha ancestral com **4 nadadeiras imponentes** em postura de nado majestoso; no casco, uma **mini-ilha completa da mesma família da ilha-hub**: rochas escalonadas, gramado verde, uma mini árvore rosa florida em um lado, **grandes cristais ciano-dourados** brotando do cume e uma pequena cascata escorrendo pela borda do casco!
- **Paleta (Lendário — Dourado Ancestral + Ilha Mágica):** Tartaruga em pedra/escamas azul-profundo com **placas e detalhes em ouro antigo (`#FFCD46`)** no casco, cabeça e nadadeiras; miniatura no topo usando exatamente a paleta do hub (pedra clara, grama viva, copa rosa sakura, cristais azul-ciano luminosos e água turquesa).
- **Detalhes de personalidade:** Rosto sábio e gentil de tartaruga milenar com olhos dourados brilhantes e sobrancelhas de musgo/ouro olhando firme para `+Z`, anéis dourados gravados nas nadadeiras frontais e farolzinho/cristal central no pico do casco.
- **Tamanho relativo (box `generate_mesh`):** `2.9 × 2.6 × 3.0` studs (preenche toda a largura da caixa de 3 studs para impor respeito no pedestal e na revelação, mantendo a silhueta bem mais larga e complexa que `C15`) · `maxTriangles = 7500` (abaixo do teto de `C23 = 7978`).
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon monumental ancient giant island sea turtle, majestic deep-ocean blue and weathered gold armored body with wide sweeping flippers, wise friendly ancient turtle head with glowing golden eyes and ornate gold crest facing forward +Z; carrying an entire miniature fantasy island on its shell featuring stepped gray cliffs, lush green grass, a tiny pink cherry blossom tree, glowing cyan-gold crystal spires and a small turquoise waterfall, Roblox fantasy adventure masterpiece, single piece
  ```

---

# Ficha de Produção — Expansão do Lote (C31–C34)

## 7. C31 — Carpa Celeste (`C31_Carpa_Celeste`)
- **Raridade:** Incomum (`tier = 2`) · **Peso:** `1–4 kg` · **Valor base:** `46 ◆` · **Reveal:** `cloud`
- **Lore:** *"Nada entre as nuvens refletidas na água. Quem a vê pede um desejo."*
- **Silhueta:** Koi elegante em leve curva em "S" de nado gracioso, porém com **nadadeiras peitorais, dorsal e cauda bipartida bem volumosas e recortadas como nuvens fofas e véus de céu** — silhueta aérea e macia, distinta da sardinha (`C02`) e do baiacu (`C04`).
- **Paleta (Incomum — Azul Celeste):** Corpo koi translúcido azul-céu luminoso (`#50C8FF` → `#BEEFFF`), manchas arredondadas branco-nuvem perolado e bordas suaves em ouro-pálido nas pontas dos véus e barbilhões.
- **Detalhes de personalidade:** Olhos gentis grandes e brilhantes voltados para `+Z` com reflexo nítido, dois longos bigodinhos de carpa curvados para os lados, escamas nacaradas suaves e cauda em véu de nuvem erguida atrás.
- **Tamanho relativo (box `generate_mesh`):** `2.4 × 1.6 × 2.9` studs · `maxTriangles = 4800`.
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon serene sky koi fish with glossy translucent sky-blue and pearlescent cloud-white spotted body in a graceful S-swim pose, billowing fluffy cloud-shaped pectoral fins, ribbon dorsal fin and flowing double cloud-veil tail with subtle pale gold tips, elegant curved koi whiskers, big gentle glossy eyes with crisp highlights facing forward +Z, Roblox fantasy adventure style, single piece
  ```

---

## 8. C32 — Espadarte Relâmpago (`C32_Espadarte_Relampago`)
- **Raridade:** Raro (`tier = 3`) · **Peso:** `40–160 kg` · **Valor base:** `150 ◆` · **Reveal:** `storm`
- **Lore:** *"Corta as ondas tão rápido que deixa um risco de luz no mar."*
- **Silhueta:** Peixe-espada veloz e angular voltado para `+Z`, com **rostro/espada longo e afiado**, grande **barbatana dorsal em vela recortada em formato de relâmpago**, nadadeiras peitorais em asa delta e cauda em crescente elétrico com feixes de energia nas pontas.
- **Paleta (Raro — Roxo Tempestade + Prata & Raio Amarelo):** Corpo prateado-azulado metálico estilizado com dorso roxo-índigo (`#BE78FF` → `#44329C`), sulcos e arcos de **relâmpago amarelo-elétrico brilhante (`#FFE84A`)** nos flancos, espada e ponta da dorsal.
- **Detalhes de personalidade:** Olhos determinados brilhantes em amarelo-ouro bem visíveis em `3/4` de frente (`+Z`), espada com filete luminoso de energia e rastro de faíscas esculpidas junto à cauda.
- **Tamanho relativo (box `generate_mesh`):** `2.1 × 1.8 × 3.0` studs (frente da espada em `+Z`) · `maxTriangles = 5500`.
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon sleek lightning swordfish creature pointing forward +Z, sculpted silver-chrome and storm-purple body with sharp glowing electric-yellow sword bill, jagged lightning-bolt sail dorsal fin, swept delta pectoral fins and crescent tail trailing crisp yellow energy arcs, fierce friendly glowing golden eyes with sharp highlights facing forward +Z, Roblox adventure game style, single piece
  ```

---

## 9. C33 — Orca Aurora (`C33_Orca_Aurora`)
- **Raridade:** Épico (`tier = 4`) · **Peso:** `1500–5000 kg` · **Valor base:** `410 ◆` · **Reveal:** `frost`
- **Lore:** *"As manchas brilham com as cores da aurora. Canta pra chamar a família."*
- **Silhueta:** Orca majestosa em arco dinâmico de salto sobre as ondas, com cabeça arredondada simpática voltada para `+Z`, **barbatana dorsal alta e nobre**, grandes peitorais abertas e cauda poderosa erguida — imediatamente distinta da Baleia Nebulosa (`C21`, que tem nuvens rosas nas costas).
- **Paleta (Épico — Rosa-Aurora + Polar):** Corpo principal em azul-noite polar profundo e barriga branco-gelo, com as grandes manchas laterais, sela dorsal e bordas das nadadeiras pintadas em **gradiente bioluminescente de aurora boreal (verde-esmeralda `#3BFFB5`, rosa-magenta épico `#FF64DC` e violeta `#A66CFF`)**.
- **Detalhes de personalidade:** Olhos luminosos ciano-rosa amigáveis, brilho em degradê fluido nas manchas da aurora (complementado por detalhe `Neon` sutil se necessário) e expressão alegre/majestosa.
- **Tamanho relativo (box `generate_mesh`):** `2.4 × 2.2 × 3.0` studs · `maxTriangles = 6500`.
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon majestic aurora orca whale in a graceful leaping arch facing forward +Z, sleek deep midnight-navy upper body and crisp ice-white belly, signature eye patches, dorsal saddle and fin edges glowing in vivid northern-lights gradients of emerald green, epic magenta-pink and violet, tall curved dorsal fin and sweeping flukes, bright expressive glossy eyes and joyful expression, Roblox fantasy adventure style, single piece
  ```

---

## 10. C34 — Serpente Arco-Íris (`C34_Serpente_Arco_Iris`)
- **Raridade:** Lendário (`tier = 5`) · **Peso:** `600–2400 kg` · **Valor base:** `1750 ◆` · **Reveal:** `prism`
- **Lore:** *"Aparece depois da chuva, quando o arco-íris toca o mar. Cada escama é de uma cor."*
- **Silhueta:** Criatura mítica monumental e escultural (no nível máximo do jogo ao lado da `C30` e `C10`/`C23`/`C24`): serpente marinha longa enrolada em **duplo arco ascendente em espiral 3D**, com a cabeça dracônica majestosa erguida no topo olhando firme para `+Z`, **par de chifrinhos dourados curvos**, **crista solar dourada em leque**, barbatana dorsal em fita ondulada contínua e barbatanas laterais em leque prismático.
- **Paleta (Lendário — Dourado + Espectro Completo Arco-Íris):** Escamas individuais bem definidas ao longo de todo o corpo em transição viva por todo o arco-íris (vermelho-coral, laranja-âmbar, dourado `#FFCD46`, verde-esmeralda, azul-turquesa, índigo e violeta-magenta), combinadas com **crista, chifres e placas ventrais em ouro real (`#FFCD46`)** e brilho prismático.
- **Detalhes de personalidade:** Olhos prismáticos dourados brilhantes com pupila nítida e brilho branco, grandes bigodes celestiais dourados curvados, mandíbula amigável de dragão sábio e ponta da cauda em leque multicolorido.
- **Tamanho relativo (box `generate_mesh`):** `2.8 × 2.9 × 3.2` studs (espiral alta e imponente; ajustada conforme convenção de ~3–3.5 studs para lendários) · `maxTriangles = 7800`.
- **Prompt `generate_mesh`:**
  ```text
  Stylized cartoon legendary rainbow sea serpent coiled in a towering majestic S-spiral pose, noble friendly sea-dragon head raised at the top facing forward +Z with twin curved golden horns, ornate golden fan crest, flowing golden whiskers and bright luminous prismatic eyes; long sculpted serpentine body covered in crisp overlapping individual scales shifting vibrantly across the full rainbow spectrum (coral red, sun orange, gold, emerald, cyan, indigo, violet) with pearlescent gold belly plates and shimmering prism fin ribbons, Roblox fantasy adventure masterpiece, single piece
  ```

---

# Ficha de Produção — Lote 3 (C35–C64)

> **Convenções de animação e orçamento (Agente 1 + Agente 2):**
> - **Partes separáveis:** todas as silhuetas têm cauda, barbatanas, asas, tentáculos, cabeças, garras ou conchas bem destacadas do `Body` para facilitar o `segment_mesh` (`Body`, `Head`, `Tail`, `FinL`, `FinR`, `Fins`, `Wings`, `Tentacles`, `Legs`, `Claws`, `Shell`, `Extra`).
> - **Orientação:** frente voltada para **`+Z`**.
> - **Escala:** `C35`–`C59` com maior dimensão `<= 3.00` studs; **Lendários `C60`–`C64`** maiores (`3.3`–`3.6` studs) com até `~12.000` triângulos e peças `Neon` nos destaques mágicos.

## Comuns (C35–C42)

### 11. C35 — Bagre Bigodudo (`C35_Bagre_Bigodudo`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.4–1.8 kg` · **Valor:** `12 ◆` · **Reveal:** `bubbles`
- **Lore:** *"Usa os bigodes pra contar fofoca pros vizinhos do fundo."*
- **Silhueta & Partes:** Bagre rechonchudo de bigodes bem longos e curvados nas pontas, nadadeiras laterais abertas (`FinL`, `FinR`), cauda em leque (`Tail`), cabeça grande expressiva (`Head`, `Extra` bigodes).
- **Paleta:** Verde-água e azul-ardósia claro (`#78E6AA` / `#5CA9B8`), bigodes creme-amarelados.
- **Box:** `2.4 × 1.6 × 3.0` · `maxTriangles = 3600`.
- **Prompt:** `Stylized cartoon chubby catfish swimming forward +Z, seafoam-teal and pastel slate-blue rounded fish torso, wide flat smiling head with two extra-long curling cream whiskers, distinct flared left and right pectoral fins, upright dorsal fin and broad paddle tail behind, big cheerful glossy eyes, Roblox adventure game style, single piece`

### 12. C36 — Peixe-Bolha Rosa (`C36_Peixe_Bolha_Rosa`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.1–0.5 kg` · **Valor:** `11 ◆` · **Reveal:** `bubbles`
- **Lore:** *"Solta bolhas em formato de coração quando está feliz."*
- **Silhueta & Partes:** Peixinho redondo rosa-chiclete translúcido com nadadeiras laterais arredondadas (`FinL`, `FinR`), cauda em coração (`Tail`) e bochechas cheias.
- **Paleta:** Rosa-pastel luminoso com brilho verde-água nos contornos.
- **Box:** `2.0 × 1.9 × 2.5` · `maxTriangles = 3500`.
- **Prompt:** `Stylized cartoon cute round pink bubblefish swimming forward +Z, glossy pastel bubblegum-pink round fish torso with aqua-mint fin tips, distinct side pectoral fins, heart-shaped tail fin behind, plump rosy cheeks, big adorable sparkling eyes and tiny o-mouth blowing a kiss, Roblox adventure game style, single piece`

### 13. C37 — Caramujo Doce (`C37_Caramujo_Doce`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.05–0.3 kg` · **Valor:** `10 ◆` · **Reveal:** `splash`
- **Lore:** *"A concha listrada parece bala, mas não tente morder."*
- **Silhueta & Partes:** Caramujo marinho simpático com grande concha espiral listrada (`Shell`), corpinho macio abaixo (`Body`), olhinhos em hastes (`Head`) e anteninhas.
- **Paleta:** Concha espiral em listras espirais menta (`#78E6AA`), creme e rosa-morango; corpo creme-azul claro.
- **Box:** `1.8 × 2.0 × 2.6` · `maxTriangles = 3600`.
- **Prompt:** `Stylized cartoon cute sea snail creature facing forward +Z, glossy round spiral shell patterned in pastel mint-green, cream and strawberry-pink candy swirls on its back, soft pastel-aqua snail foot below, cute smiling face with big glossy dark eyes on short twin eye stalks, Roblox adventure game style, single piece`

### 14. C38 — Estrela Sonolenta (`C38_Estrela_Sonolenta`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.2–0.9 kg` · **Valor:** `12 ◆` · **Reveal:** `spark`
- **Lore:** *"Dorme 20 horas por dia e sonha que é uma estrela do céu."*
- **Silhueta & Partes:** Estrela-do-mar fofa de 5 pontas gordinhas bem separadas (`Body` + braços/pernas articuláveis), touquinha de dormir (`Extra`) e olhinhos sonolentos meio fechados (`Head`).
- **Paleta:** Amarelo-manteiga e verde-água pastel com touquinha azul-estrelada.
- **Box:** `2.6 × 2.6 × 1.4` · `maxTriangles = 3500`.
- **Prompt:** `Stylized cartoon sleepy plump 5-pointed starfish creature facing forward +Z, soft pastel butter-yellow and seafoam-aqua star shape with thick rounded arms, wearing a tiny cozy blue starry nightcap on top tip, half-closed drowsy cute eyes and peaceful little yawn smile, Roblox adventure game style, single piece`

### 15. C39 — Lambari Prata (`C39_Lambari_Prata`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.05–0.25 kg` · **Valor:** `11 ◆` · **Reveal:** `splash`
- **Lore:** *"Nada em cardumes tão rápidos que parecem um raio de luz."*
- **Silhueta & Partes:** Peixinho esguio prateado-ciano aerodinâmico, nadadeiras peitorais finas (`FinL`, `FinR`), cauda bifurcada (`Tail`) e faixa lateral iridescente.
- **Paleta:** Prata brilhante com dorso verde-água (`#78E6AA`) e brilho azul claro.
- **Box:** `1.5 × 1.5 × 3.0` · `maxTriangles = 3500`.
- **Prompt:** `Stylized cartoon sleek silver minnow fish swimming forward +Z, streamlined shiny silver-chrome fish torso with pastel aqua-green back and iridescent cyan side stripe, crisp small side pectoral fins, dorsal fin and sharp forked tail behind, bright alert glossy eyes, Roblox adventure game style, single piece`

### 16. C40 — Caranguejo Bolacha (`C40_Caranguejo_Bolacha`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.3–1.2 kg` · **Valor:** `13 ◆` · **Reveal:** `splash`
- **Lore:** *"Tem cheirinho de biscoito e anda de lado dançando."*
- **Silhueta & Partes:** Caranguejo com carapaça em formato de bolacha/biscoito com gotas de chocolate (`Shell`/`Body`), duas garras grandes arredondadas erguidas (`Claws`) e 6 patinhas destacadas (`Legs`).
- **Paleta:** Biscoito dourado-caramelo quente com detalhes turquesa-menta nos olhinhos e pontas das patas.
- **Box:** `2.7 × 1.7 × 2.2` · `maxTriangles = 3800`.
- **Prompt:** `Stylized cartoon cute cookie crab creature facing forward +Z, round golden-tan biscuit shell speckled with dark chocolate chips on top, two cheerful raised crab claws, six distinct articulated legs on the sides, happy dancing smile and bright glossy dark eyes on stalks, Roblox adventure game style, single piece`

### 17. C41 — Palhaço Neon (`C41_Palhaco_Neon`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.1–0.4 kg` · **Valor:** `14 ◆` · **Reveal:** `spark`
- **Lore:** *"As listras brilham no escuro pra animar a festa no recife."*
- **Silhueta & Partes:** Peixe-palhaço vibrante com nadadeiras grandes onduladas (`FinL`, `FinR`, `Tail`) e listras luminosas (`Neon` opcional nas listras/pontas).
- **Paleta:** Laranja-coral vivo com listras branco-ciano brilhantes e contorno menta-escuro.
- **Box:** `1.8 × 1.8 × 2.8` · `maxTriangles = 3600`.
- **Prompt:** `Stylized cartoon cheerful neon clownfish swimming forward +Z, bright tangerine-orange rounded fish torso with glowing ice-cyan and white clownfish stripes, prominent rounded side fins, scalloped dorsal fin and round fan tail behind, big joyful glossy eyes and wide smile, Roblox adventure game style, single piece`

### 18. C42 — Lulinha Gota (`C42_Lulinha_Gota`)
- **Raridade:** Comum (`tier = 1`) · **Peso:** `0.1–0.6 kg` · **Valor:** `12 ◆` · **Reveal:** `bubbles`
- **Lore:** *"Do tamanho de uma gota de chuva e corajosa como um tubarão."*
- **Silhueta & Partes:** Lulinha compacta em formato de gota d'água invertida com pequenas orelhinhas-barbatana no topo (`Fins`), rosto corajoso (`Head`) e feixe de tentáculos curtos bem definidos embaixo (`Tentacles`).
- **Paleta:** Azul-gota translúcido e verde-água (`#78E6AA`) com bochechas rosadas.
- **Box:** `1.8 × 2.6 × 1.8` · `maxTriangles = 3600`.
- **Prompt:** `Stylized cartoon cute water-droplet baby squid facing forward +Z, smooth raindrop-shaped aqua-blue and seafoam-mint mantle with two tiny ear fins at the top, bundle of short splayed tentacles neatly separated underneath, big brave glossy eyes with determined cute eyebrows and tiny smile, Roblox adventure game style, single piece`

---

## Incomuns (C43–C49)

### 19. C43 — Baiacu Algodão-Doce (`C43_Baiacu_Algodao_Doce`)
- **Raridade:** Incomum (`tier = 2`) · **Peso:** `0.6–2.5 kg` · **Valor:** `40 ◆` · **Reveal:** `cloud`
- **Lore:** *"Quando se assusta, vira uma nuvem rosa e fofinha."*
- **Silhueta & Partes:** Baiacu bem fofo e macio com tufos fofos tipo nuvem/algodão-doce ao redor (`Body`), pequenas asas/nadadeiras laterais (`FinL`, `FinR`) e caudinha (`Tail`).
- **Paleta:** Algodão-doce rosa e azul-celeste pastel (`#50C8FF` + `#FFB5E8`).
- **Box:** `2.6 × 2.4 × 2.6` · `maxTriangles = 4500`.
- **Prompt:** `Stylized cartoon puffy cotton-candy pufferfish facing forward +Z, round fluffy cloud-textured fish sphere swirling in pastel sky-blue and cotton-candy pink, small distinct aqua pectoral fins on left and right, cute small tail behind, surprised round cute eyes and tiny o-mouth, Roblox adventure game style, single piece`

### 20. C44 — Arraia Pintada (`C44_Arraia_Pintada`)
- **Raridade:** Incomum (`tier = 2`) · **Peso:** `2–9 kg` · **Valor:** `44 ◆` · **Reveal:** `prism`
- **Lore:** *"Cada bolinha das costas é de uma cor diferente."*
- **Silhueta & Partes:** Arraia de asas largas e curvas graciosas (`FinL`, `FinR`/`Wings`), corpo central (`Body`), cauda longa em chicote (`Tail`) e rosto amigável na borda frontal (`Head`).
- **Paleta:** Azul-oceano claro (`#50C8FF`) coberto por bolinhas coloridas (amarelo, coral, violeta, verde-menta).
- **Box:** `3.0 × 1.1 × 2.9` · `maxTriangles = 4600`.
- **Prompt:** `Stylized cartoon cheerful spotted stingray gliding forward +Z, wide graceful ocean-blue wings decorated with vivid multicolor polka dots in yellow, coral, violet and mint, distinct long slender whip tail behind, cute wide smiling face with bright glossy eyes at the front edge, Roblox adventure game style, single piece`

### 21. C45 — Tartaruguinha Coral (`C45_Tartaruguinha_Coral`)
- **Raridade:** Incomum (`tier = 2`) · **Peso:** `0.5–2 kg` · **Valor:** `42 ◆` · **Reveal:** `bubbles`
- **Lore:** *"Carrega um coralzinho no casco como se fosse um chapéu."*
- **Silhueta & Partes:** Tartaruguinha bebê com casco arredondado (`Shell`), 4 nadadeiras destacadas (`FinL`, `FinR`, `Legs`), cabeça fofa (`Head`) e um ramo de coral colorido no topo do casco (`Extra`).
- **Paleta:** Corpo verde-turquesa, casco azul-marinho claro (`#50C8FF`), coral rosa-pêssego e amarelo no topo.
- **Box:** `2.4 × 2.1 × 2.8` · `maxTriangles = 4700`.
- **Prompt:** `Stylized cartoon adorable baby sea turtle swimming forward +Z, smooth turquoise turtle head and four distinct flipper fins, rounded sky-blue shell carrying a colorful miniature pink-and-orange branching reef coral on top like a hat, huge sparkling cute eyes and happy smile, Roblox adventure game style, single piece`

### 22. C46 — Peixe-Leque (`C46_Peixe_Leque`)
- **Raridade:** Incomum (`tier = 2`) · **Peso:** `0.4–1.5 kg` · **Valor:** `38 ◆` · **Reveal:** `splash`
- **Lore:** *"Abre a barbatana como um leque pra se refrescar."*
- **Silhueta & Partes:** Peixe tropical esbelto com **enormes nadadeiras em forma de leque plissado** em cima, embaixo e atrás (`Fins`, `Tail`) + peitorais laterais (`FinL`, `FinR`).
- **Paleta:** Azul-cobalto e turquesa (`#50C8FF`) com pregas do leque em degradê creme-ouro e água-marinha.
- **Box:** `2.0 × 2.9 × 2.8` · `maxTriangles = 4600`.
- **Prompt:** `Stylized cartoon elegant fanfish swimming forward +Z, compact cobalt-and-sky-blue fish torso with huge pleated ornamental paper-fan dorsal and ventral fins and wide pleated fan tail in turquoise, cream and gold gradients, distinct side pectoral fins, bright expressive eyes facing forward +Z, Roblox adventure game style, single piece`

### 23. C47 — Medusa Lanterna (`C47_Medusa_Lanterna`)
- **Raridade:** Incomum (`tier = 2`) · **Peso:** `0.3–1.4 kg` · **Valor:** `46 ◆` · **Reveal:** `spark`
- **Lore:** *"Ilumina o caminho dos peixinhos perdidos à noite."*
- **Silhueta & Partes:** Sino de água-viva em formato de lanterna japonesa arredondada com armação dourada (`Body`/`Head`), núcleo luminoso interno (`Extra` `Neon`) e tentáculos longos ondulados (`Tentacles`).
- **Paleta:** Ciano-azul (`#50C8FF`) com brilho âmbar-dourado quente no centro da lanterna.
- **Box:** `2.1 × 3.0 × 2.1` · `maxTriangles = 4800`.
- **Prompt:** `Stylized cartoon magical lantern jellyfish floating upright facing forward +Z, rounded glowing sky-blue and warm amber glass-lantern bell with delicate golden frame ribs, cute big glowing eyes on the front of the bell, flowing separated ribbon tentacles hanging below with glowing golden tips, Roblox adventure game style, single piece`

### 24. C48 — Peixe-Anjo Real (`C48_Peixe_Anjo_Real`)
- **Raridade:** Incomum (`tier = 2`) · **Peso:** `0.5–2.2 kg` · **Valor:** `48 ◆` · **Reveal:** `prism`
- **Lore:** *"Usa uma coroa de escamas douradas e se acha da realeza."*
- **Silhueta & Partes:** Peixe-anjo alto e majestoso com listras reais, longas pontas verticais na dorsal/ventral (`Fins`), cauda em lira (`Tail`), nadadeiras laterais (`FinL`, `FinR`) e pequena coroa dourada (`Extra`).
- **Paleta:** Azul-royal e turquesa (`#50C8FF`) com listras douradas e coroa ouro-brilhante.
- **Box:** `1.6 × 3.0 × 2.7` · `maxTriangles = 4800`.
- **Prompt:** `Stylized cartoon regal royal angelfish swimming forward +Z, tall diamond-shaped royal-blue and sky-cyan fish torso striped with metallic gold bands, wearing a sculpted tiny gold crown on its forehead, sweeping pointed dorsal and ventral fins, distinct side fins and lyre tail behind, proud cute expression and bright eyes, Roblox adventure game style, single piece`

### 25. C49 — Polvo de Bolinhas (`C49_Polvo_Bolinhas`)
- **Raridade:** Incomum (`tier = 2`) · **Peso:** `1–4 kg` · **Valor:** `45 ◆` · **Reveal:** `bubbles`
- **Lore:** *"Muda as bolinhas de cor conforme o humor."*
- **Silhueta & Partes:** Polvo fofo com cabeça arredondada cheia de bolinhas coloridas (`Head`/`Body`) e 8 tentáculos curvos bem separados ao redor da base (`Tentacles`).
- **Paleta:** Azul-lavanda (`#50C8FF`) com bolinhas vibrantes em rosa, amarelo, menta e laranja.
- **Box:** `2.9 × 2.3 × 2.9` · `maxTriangles = 4800`.
- **Prompt:** `Stylized cartoon cheerful polka-dot octopus facing forward +Z, smooth plump sky-blue and periwinkle head covered in crisp bright polka dots of yellow, pink, mint and coral, eight neatly separated curled tentacles splayed around the bottom, big cheerful glossy eyes and happy smile, Roblox adventure game style, single piece`

---

## Raros (C50–C55)

### 26. C50 — Tubarão-Baleia Estrelado (`C50_Tubarao_Baleia_Estrelado`)
- **Raridade:** Raro (`tier = 3`) · **Peso:** `200–900 kg` · **Valor:** `165 ◆` · **Reveal:** `cosmic`
- **Lore:** *"As pintas formam constelações que só aparecem de noite."*
- **Silhueta & Partes:** Tubarão-baleia gentil e imponente de boca larga sorridente (`Head`/`Body`), grandes nadadeiras peitorais (`FinL`, `FinR`), dorsal destacada (`Fins`) e cauda robusta (`Tail`), com pintas em forma de estrelas e linhas de constelação brilhantes.
- **Paleta:** Índigo/roxo noturno (`#BE78FF` / `#2A2E7A`) com constelações douradas e branco-ciano.
- **Box:** `2.7 × 1.8 × 3.0` · `maxTriangles = 5600`.
- **Prompt:** `Stylized cartoon gentle starry whale shark swimming forward +Z, broad flat friendly head with wide gentle smile and bright starry eyes, deep cosmic-indigo and royal-purple back patterned with glowing golden star-shaped spots connected by constellation lines, large separated side pectoral fins, tall dorsal fin and sturdy tail behind, Roblox adventure game style, single piece`

### 27. C51 — Lanterna Abissal (`C51_Lanterna_Abissal`)
- **Raridade:** Raro (`tier = 3`) · **Peso:** `2–8 kg` · **Valor:** `130 ◆` · **Reveal:** `spark`
- **Lore:** *"Vive tão fundo que a lanterna é a única luz que já viu."*
- **Silhueta & Partes:** Peixe-pescador abissal estilizado (fofo, não assustador!) com antena arqueada sobre a cabeça segurando uma lanterna luminosa (`Extra` + `Neon`), nadadeiras laterais (`FinL`, `FinR`) e cauda em leque (`Tail`).
- **Paleta:** Roxo-abissal profundo (`#BE78FF` / `#3D1C6E`) com lanterna dourado-turquesa brilhante e dentinhos redondos simpáticos.
- **Box:** `2.3 × 2.6 × 2.9` · `maxTriangles = 5600`.
- **Prompt:** `Stylized cartoon cute friendly abyssal anglerfish swimming forward +Z, plump deep-violet and royal-purple round torso with big curious luminous eyes and tiny goofy round teeth in a wide grin, long curved glowing fishing antenna arching over the forehead dangling a bright cyan-gold orb lantern, distinct side fins and fan tail behind, Roblox adventure game style, single piece`

### 28. C52 — Cavalo-Marinho Real (`C52_Cavalo_Marinho_Real`)
- **Raridade:** Raro (`tier = 3`) · **Peso:** `0.4–1.6 kg` · **Valor:** `120 ◆` · **Reveal:** `crystal`
- **Lore:** *"Puxa a carruagem das sereias nos dias de festa."*
- **Silhueta & Partes:** Cavalo-marinho aristocrático com armadura leve perolada e coroa de cristais roxos (`Extra`), cabeça nobre (`Head`), nadadeira dorsal em asa cristalina (`Fins`) e cauda longa enrolada (`Tail`).
- **Paleta:** Roxo-ametista (`#BE78FF`), perolado e ouro-champanhe.
- **Box:** `1.6 × 3.0 × 2.1` · `maxTriangles = 5800`.
- **Prompt:** `Stylized cartoon noble royal seahorse creature facing forward +Z, upright sculpted pearlescent-violet and lavender seahorse torso wearing ornate golden royal bridle trim and a glittering amethyst crystal crown on its head, fluttering translucent wing-like dorsal fin, neatly curled ornate tail below and proud sparkling eyes, Roblox adventure game style, single piece`

### 29. C53 — Moreia Voltaica (`C53_Moreia_Voltaica`)
- **Raridade:** Raro (`tier = 3`) · **Peso:** `6–25 kg` · **Valor:** `140 ◆` · **Reveal:** `storm`
- **Lore:** *"Dá choquinhos em quem chega perto da toca dela."*
- **Silhueta & Partes:** Moreia longa em curva energética em "S" (`Body`), cabeça expressiva (`Head`), crista dorsal em forma de raios elétricos ao longo do dorso (`Fins`/`Extra`) e ponta da cauda em faísca (`Tail`).
- **Paleta:** Roxo-elétrico (`#BE78FF`) e azul-marinho com raios amarelo-neon e ciano.
- **Box:** `2.1 × 2.7 × 2.9` · `maxTriangles = 5700`.
- **Prompt:** `Stylized cartoon electric volt moray eel coiled in a dynamic S-curve facing forward +Z, sleek royal-purple and dark-indigo serpentine torso with jagged glowing electric-yellow dorsal fin crest running down its spine, expressive fierce-cute head with bright glowing yellow eyes and spark-tipped tail behind, Roblox fantasy adventure style, single piece`

### 30. C54 — Peixe-Vela Solar (`C54_Peixe_Vela_Solar`)
- **Raridade:** Raro (`tier = 3`) · **Peso:** `30–110 kg` · **Valor:** `150 ◆` · **Reveal:** `magma`
- **Lore:** *"A vela das costas guarda o calor do sol do meio-dia."*
- **Silhueta & Partes:** Peixe-vela hidrodinâmico com bico longo e **enorme vela dorsal em leque solar** (`Fins`), nadadeiras peitorais em asa (`FinL`, `FinR`) e cauda bifurcada (`Tail`).
- **Paleta:** Roxo-crepúsculo (`#BE78FF`) e azul-safira no corpo com enorme vela em gradiente laranja-sol e ouro incandescente.
- **Box:** `1.8 × 2.9 × 3.0` · `maxTriangles = 5800`.
- **Prompt:** `Stylized cartoon majestic solar sailfish swimming forward +Z, streamlined sunset-violet and sapphire-blue fish torso with pointed bill, huge radiant fan-shaped sail dorsal fin glowing in fiery sun-orange and molten-gold gradients, crisp side pectoral fins and sharp forked tail behind, bright golden eyes facing forward +Z, Roblox adventure game style, single piece`

### 31. C55 — Caranguejo-Rei do Gelo (`C55_Caranguejo_Rei_Gelo`)
- **Raridade:** Raro (`tier = 3`) · **Peso:** `5–20 kg` · **Valor:** `135 ◆` · **Reveal:** `frost`
- **Lore:** *"Suas garras de gelo nunca derretem, nem no verão."*
- **Silhueta & Partes:** Caranguejo-rei robusto com carapaça facetada de gelo e coroa de estalactites (`Shell`/`Extra`), duas garras gigantes de cristal de gelo (`Claws`) e 6 pernas longas articuladas (`Legs`).
- **Paleta:** Gelo ciano-branco, azul glacial e detalhes roxo-ametista (`#BE78FF`) na coroa.
- **Box:** `3.0 × 2.2 × 2.6` · `maxTriangles = 5900`.
- **Prompt:** `Stylized cartoon majestic ice king crab creature facing forward +Z, faceted frost-crystal and violet-trimmed armored carapace topped with an icicle crown, two massive translucent glacial-blue ice claws held forward, six distinct long jointed ice-armored legs on the sides, glowing frost-cyan eyes with friendly noble expression, Roblox fantasy adventure style, single piece`

---

## Épicos (C56–C59)

### 32. C56 — Dragão de Coral (`C56_Dragao_de_Coral`)
- **Raridade:** Épico (`tier = 4`) · **Peso:** `60–200 kg` · **Valor:** `400 ◆` · **Reveal:** `prism`
- **Lore:** *"O corpo é um recife vivo; peixinhos moram nas escamas."*
- **Silhueta & Partes:** Dragão marinho elegante coberto de galhos de coral vivo nos ombros, cabeça e costas (`Extra`), grandes asas em leque de coral (`Wings`), 4 patas/nadadeiras (`Legs`/`FinL`/`FinR`) e cauda longa (`Tail`).
- **Paleta:** Rosa-magenta épico (`#FF64DC`), coral-salmão, turquesa de recife e detalhes dourados.
- **Box:** `2.8 × 2.7 × 3.0` · `maxTriangles = 6800`.
- **Prompt:** `Stylized cartoon majestic coral sea dragon creature facing forward +Z, sculpted turquoise and epic magenta-pink dragon torso covered in living branching reef coral plates and glowing anemones, sweeping coral-fan wings, proud horned dragon head with luminous golden eyes, four distinct flipper limbs and long reef-spined tail behind, Roblox fantasy adventure style, single piece`

### 33. C57 — Manta Galáctica (`C57_Manta_Galactica`)
- **Raridade:** Épico (`tier = 4`) · **Peso:** `300–1200 kg` · **Valor:** `430 ◆` · **Reveal:** `cosmic`
- **Lore:** *"Voa pelo mar como se fosse o céu estrelado."*
- **Silhueta & Partes:** Jamanta gigante com grandes asas curvadas (`Wings`/`FinL`/`FinR`), cornos cefálicos na frente (`Head`), corpo central (`Body`) e longa cauda de cometa (`Tail`) + detalhes estelares `Neon`.
- **Paleta:** Azul-cósmico escuro e rosa-nebulosa épico (`#FF64DC`) com estrelas e trilhas de luz ciano/violeta.
- **Box:** `3.0 × 1.4 × 2.9` · `maxTriangles = 6600`.
- **Prompt:** `Stylized cartoon majestic galactic manta ray gliding forward +Z, massive sweeping cosmic-navy wings painted with glowing epic magenta-pink nebula swirls, starry dust and cyan energy veins, twin curled head lobes framing luminous starlight eyes at the front, long comet-tail ribbon trailing behind, Roblox fantasy adventure style, single piece`

### 34. C58 — Tubarão Fantasma (`C58_Tubarao_Fantasma`)
- **Raridade:** Épico (`tier = 4`) · **Peso:** `150–600 kg` · **Valor:** `410 ◆` · **Reveal:** `frost`
- **Lore:** *"Atravessa navios afundados sem fazer barulho."*
- **Silhueta & Partes:** Tubarão espectral esguio de aparência mística amigável, com marcas etéreas brilhantes em costelas estilizadas, grandes peitorais em véu (`FinL`, `FinR`), dorsal alta rasgada (`Fins`), cauda em foice etérea (`Tail`) e cabeça expressiva (`Head`).
- **Paleta:** Ciano-fantasma e lilás-magenta épico (`#FF64DC`) translúcido com olhos brilhantes.
- **Box:** `2.3 × 2.1 × 3.0` · `maxTriangles = 6700`.
- **Prompt:** `Stylized cartoon mystical phantom shark swimming forward +Z, sleek ethereal ice-cyan and glowing magenta-violet spectral shark torso with tattered ghostly veil pectoral fins, tall curved dorsal fin and sweeping crescent phantom tail, glowing neon-cyan eyes and friendly confident toothy grin facing forward +Z, Roblox fantasy adventure style, single piece`

### 35. C59 — Narval Unicórnio (`C59_Narval_Unicornio`)
- **Raridade:** Épico (`tier = 4`) · **Peso:** `400–1500 kg` · **Valor:** `420 ◆` · **Reveal:** `crystal`
- **Lore:** *"O chifre de cristal realiza um pedido por ano."*
- **Silhueta & Partes:** Narval fofo e majestoso com **longo chifre espiralado de cristal prismático apontado para `+Z`** (`Extra`), crina/barbatanas em arco-íris pastel (`FinL`, `FinR`), cauda em coração (`Tail`) e corpo perolado (`Body`).
- **Paleta:** Branco-perolado e rosa-magenta épico (`#FF64DC`) com chifre de cristal ciano-arco-íris e estrelas douradas.
- **Box:** `2.2 × 2.0 × 3.0` · `maxTriangles = 6800`.
- **Prompt:** `Stylized cartoon enchanting unicorn narwhal whale swimming forward +Z, plump pearlescent white and epic pastel-magenta whale torso speckled with tiny gold stars, long sculpted translucent rainbow-crystal spiral horn projecting straight ahead from its forehead, ruffled pastel fins, heart-shaped tail behind and huge sparkling starry eyes facing +Z, Roblox fantasy adventure style, single piece`

---

## Lendários (C60–C64) — Os 5 Mais Épicos do Jogo (múltiplas tentativas, até ~12k triângulos, peças Neon)

### 36. C60 — Hidra das Profundezas (`C60_Hidra_das_Profundezas`)
- **Raridade:** Lendário (`tier = 5`) · **Peso:** `3000–9000 kg` · **Valor:** `1800 ◆` · **Reveal:** `storm`
- **Lore:** *"Três cabeças, três vozes, e todas querem a sua isca."*
- **Silhueta & Partes:** Monstro marinho colossal com **três cabeças de dragão-serpente em pescoços longos e sinuosos abertos em leque para `+Z`** (`Head` / 3 pescoços distintos), torso blindado com cristas dorsais elétricas (`Body`), barbatanas laterais em leque espinhoso (`FinL`, `FinR`), cauda serpentina com tridente luminoso (`Tail`) e gemas/olhos/relâmpagos `Neon` (`Extra`).
- **Paleta:** Azul-abissal escuro, escamas em ouro-real (`#FFCD46`), barbatanas translúcidas roxo-elétrico e núcleos/olhos `Neon` turquesa-dourado.
- **Box:** `3.4 × 3.2 × 3.5` · `maxTriangles = 11500` · **Mínimo 2 tentativas** ficando com a mais impressionante + acabamento `Neon`.
- **Prompt:** `Stylized cartoon monumental three-headed abyssal sea hydra boss monster facing forward +Z, massive armored deep-ocean navy and royal-gold serpent torso with three distinct long curved necks rising to three majestic crowned dragon heads roaring side by side toward +Z, glowing golden eyes, flared thorny teal-and-gold fin wings, long coiled trident tail behind, ornate gold armor plates and electric cyan runes, Roblox fantasy adventure masterpiece, single piece`

### 37. C61 — Baleia Celestial (`C61_Baleia_Celestial`)
- **Raridade:** Lendário (`tier = 5`) · **Peso:** `8000–20000 kg` · **Valor:** `1850 ◆` · **Reveal:** `cosmic`
- **Lore:** *"Carrega uma galáxia inteira dentro do corpo e canta com as estrelas."*
- **Silhueta & Partes:** Baleia colossal majestosa em pose ascendente (`Body`), **núcleo galáctico visível no torso** com estrelas e nebulosas, **anéis planetários dourados e cósmicos orbitando em volta do corpo** (modelados + peças `Neon` orbitais em `Extra`), enormes nadadeiras peitorais aladas (`FinL`, `FinR`) e cauda cósmica dupla (`Tail`).
- **Paleta:** Azul-estelar profundo, púrpura cósmica, nebulosa ciano-rosa e **ouro celestial (`#FFCD46`)** nos anéis, coroa e estrelas `Neon`.
- **Box:** `3.5 × 2.8 × 3.6` · `maxTriangles = 11500` · **Mínimo 2 tentativas** + anéis/estrelas `Neon` orbitais.
- **Prompt:** `Stylized cartoon colossal celestial galaxy whale swimming forward +Z, majestic deep-space cosmic-blue and violet whale torso featuring a glowing swirling spiral galaxy nebula window inside its chest and flank, adorned with ornate golden celestial rings encircling its waist, sweeping wing-like starlit pectoral fins, glowing golden star runes and forked comet tail behind, serene wise glowing golden eyes facing +Z, Roblox fantasy adventure masterpiece, single piece`

### 38. C62 — Dragão Dourado da Tempestade (`C62_Dragao_Dourado`)
- **Raridade:** Lendário (`tier = 5`) · **Peso:** `1500–5000 kg` · **Valor:** `1900 ◆` · **Reveal:** `storm`
- **Lore:** *"Quando ruge, o céu responde com relâmpagos dourados."*
- **Silhueta & Partes:** Dragão marinho-celeste imperial coberto de placas em **ouro puro esculpido**, grandes chifres ramificados, juba de tempestade (`Head`, `Extra`), **enormes asas abertas entrelaçadas com raios dourados** (`Wings`), garras dianteiras (`Claws`) e longa cauda serpenteante em ponta de relâmpago (`Tail`) + arcos elétricos `Neon`.
- **Paleta:** Ouro-real brilhante (`#FFCD46`), nuvens de tempestade azul-cobalto/violeta e raios `Neon` amarelo-sol e ciano.
- **Box:** `3.6 × 3.3 × 3.4` · `maxTriangles = 12000` · **Mínimo 2 tentativas** + arcos de relâmpago `Neon`.
- **Prompt:** `Stylized cartoon supreme golden storm sea dragon boss facing forward +Z, armored radiant pure-gold and cobalt-indigo dragon torso with noble fierce-friendly head, giant branching golden antlers, flowing storm-cloud mane, massive spread wings crackling with sculpted golden lightning bolts, sharp clawed forelimbs and long sweeping lightning-spear tail, glowing golden-white eyes, Roblox fantasy adventure masterpiece, single piece`

### 39. C63 — Grifo-Marinho Real (`C63_Grifo_Marinho`)
- **Raridade:** Lendário (`tier = 5`) · **Peso:** `400–1500 kg` · **Valor:** `1750 ◆` · **Reveal:** `cloud`
- **Lore:** *"Metade águia, metade peixe, rei dos ventos e das ondas."*
- **Silhueta & Partes:** Híbrido nobre e imponente: metade dianteira de **águia real dourada e branco-celeste** com bico curvo, coroa solar, garras de águia (`Claws`) e **enormes asas emplumadas abertas** (`Wings`); metade traseira de **peixe/tritão escamado turquesa-dourado** com barbatanas em véu (`FinL`, `FinR`) e **cauda de peixe em leque real** (`Tail`).
- **Paleta:** Ouro imperial (`#FFCD46`), branco-nuvem perolado, turquesa-real e detalhes ciano `Neon`.
- **Box:** `3.5 × 3.2 × 3.4` · `maxTriangles = 11500` · **Mínimo 2 tentativas** + coroa/runas `Neon`.
- **Prompt:** `Stylized cartoon majestic royal sea griffin hybrid facing forward +Z, regal white-and-gold armored eagle upper torso with noble hooked golden beak, golden sun crown crest, huge spread feathered wings tipped in sky-cyan and sharp golden eagle talons, seamlessly transitioning into an armored turquoise-and-gold scaled fish lower torso with sweeping ornate fan fish tail behind, fierce proud golden eyes, Roblox fantasy adventure masterpiece, single piece`

### 40. C64 — Guardião Abissal (`C64_Guardiao_Abissal`)
- **Raridade:** Lendário (`tier = 5`) · **Peso:** `5000–15000 kg` · **Valor:** `1950 ◆` · **Reveal:** `magma`
- **Lore:** *"Protege a entrada do fundo do mar há mil anos com sua lanterna antiga."*
- **Silhueta & Partes:** Titã marinho antigo de armadura colossal de pedra oceânica, corais antigos e ouro desgastado (`Body`, `Shell`), capacete/cabeça com visor rúnico brilhante (`Head`), braços enormes blindados (`Claws`/`FinL`/`FinR`), **lanterna ancestral pendurada ou empunhada brilhando intensamente** (`Extra` com núcleo `Neon` âmbar-turquesa) e cauda/manto abissal de tentáculos-raiz (`Tail`/`Tentacles`).
- **Paleta:** Basalto abissal escuro, bronze/ouro antigo (`#FFCD46`), cracas turquesa e fogo/luz âmbar-magma + ciano `Neon`.
- **Box:** `3.3 × 3.6 × 3.2` · `maxTriangles = 12000` · **Mínimo 2 tentativas** + núcleo `Neon` da lanterna antiga e runas da armadura.
- **Prompt:** `Stylized cartoon colossal ancient abyssal sea guardian titan standing heroically facing forward +Z, massive weathered deep-sea stone and tarnished gold armored golem torso encrusted with glowing cyan barnacles and coral, horned ancient diving-knight helm with glowing amber visor eyes, wide armored shoulder pauldrons, holding a grand ornate ancient golden-cage lantern glowing bright amber-gold in its right hand, lower body tapering into armored sea-serpent tail and tentacles, Roblox fantasy adventure masterpiece, single piece`
