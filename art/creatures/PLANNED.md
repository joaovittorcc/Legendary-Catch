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
