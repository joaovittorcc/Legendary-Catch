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
