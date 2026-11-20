# Auditoria das Lendárias

Inventário de Config e Strings. As notas visuais e a decisão por modelo vêm da inspeção em Studio.

| ID | Nome | Portal | Pool | Lore |
| --- | --- | --- | --- | --- |
| `C10_Leviata_Astral` | Leviatã Astral | cosmic | Normal | Desceu do céu numa noite sem lua. O oceano ainda não se acostumou. |
| `C23_Kraken_Trovejante` | Kraken Trovejante | storm | Normal | Cada tentáculo chama um raio. Ninguém que viu esquece o barulho. |
| `C24_Fenix_das_Mares` | Fênix das Marés | magma | Normal | Renasce das ondas em chamas azuis. Dizem que só aparece pra quem não desiste. |
| `C30_Tartaruga_Ilha` | Tartaruga-Ilha Ancestral | crystal | Normal | Tão antiga que nasceu uma ilha nas costas dela. Alguns dizem que a nossa ilha também. |
| `C34_Serpente_Arco_Iris` | Serpente Arco-Íris | prism | Normal | Aparece depois da chuva, quando o arco-íris toca o mar. Cada escama é de uma cor. |
| `C60_Hidra_das_Profundezas` | Hidra das Profundezas | storm | Normal | Três cabeças, três vozes, e todas querem a sua isca. |
| `C61_Baleia_Celestial` | Baleia Celestial | cosmic | Normal | Carrega uma galáxia inteira dentro do corpo e canta com as estrelas. |
| `C62_Dragao_Dourado` | Dragão Dourado da Tempestade | storm | Normal | Quando ruge, o céu responde com relâmpagos dourados. |
| `C63_Grifo_Marinho` | Grifo-Marinho Real | cloud | Normal | Metade águia, metade peixe, rei dos ventos e das ondas. |
| `C64_Guardiao_Abissal` | Guardião Abissal | magma | Normal | Protege a entrada do fundo do mar há mil anos com sua lanterna antiga. |
| `C88_Rei_Tritao_Colossal` | Rei Tritão Colossal | storm | Normal | Governa os sete mares com um tridente de tempestade. |
| `C89_Dragao_de_Jade` | Dragão de Jade | cloud | Normal | Antigo guardião das nuvens e das marés. |
| `C90_Tartaruga_Mundo` | Tartaruga-Mundo | crystal | Normal | Carrega uma ilha inteira nas costas, com florestas e tudo. |
| `C91_Hipocampo_Imperial` | Hipocampo Imperial | prism | Normal | Cavalga as ondas vestindo armadura dourada. |
| `C92_Serafim_do_Mar` | Serafim do Mar | cosmic | Normal | Seis asas de luz que acalmam qualquer tempestade. |
| `C99_Baleia_Fantasma` | Baleia Fantasma | cloud | fogBank | Navega a tempestade com lanternas de névoa; poucos a viram duas vezes. |
| `C100_Aurora_Boreal_Viva` | Aurora Boreal Viva | frost | aurora | Uma serpente de aurora que só nada nas marés estreladas. |
| `C106_Rei_do_Gelo_Natalino` | Rei do Gelo Natalino | frost | xmas | Majestoso guardião do inverno; sua coroa cristalina reflete todas as luzes da festa. |

## Inspeção em Edit

As seis vistas de cada ficha seguem a ordem frente, 3/4, lado, costas, 3/4 oposto e topo. A frente segue +Z local do pivô atual. As notas de 0 a 5 avaliam silhueta, rosto e detalhe nas capturas. A cor de cada BasePart e os IDs de textura em uso estão no [inventário do Studio](creatures-audit-lendarias.json). As cores nas imagens incluem as texturas, além do tint da peça.

| Criatura | X × Y × Z em studs | Partes diretas | S/R/D | Decisão | Motivo |
| --- | --- | --- | --- | --- | --- |
| [C10](../art/creatures/C10_Leviata_Astral/antes/studio-six-views.jpg) | 3.00 × 2.88 × 2.51 | Body, Head, Wings, Tail | 4/3/3 | Manter | Asas e chifres recortam bem. Paleta violeta e ouro dá identidade ao portal cósmico. |
| [C23](../art/creatures/C23_Kraken_Trovejante/antes/studio-six-views.jpg) | 3.00 × 2.66 × 2.74 | Body, Head, Tentacles | 3/1/3 | Refazer · piloto | Tentáculos dão largura. A frente mistura armadura, olhos e púrpura num bloco escuro. |
| [C24](../art/creatures/C24_Fenix_das_Mares/antes/studio-six-views.jpg) | 2.93 × 3.00 × 1.17 | Body, Head, Wings, Tail | 4/3/4 | Manter | Asas e cauda de chamas azuis leem bem. O perfil mantém a identidade do lore. |
| [C30](../art/creatures/C30_Tartaruga_Ilha/antes/studio-six-views.jpg) | 2.77 × 2.60 × 2.81 | Body, Head, Shell, Fins, Extra ×2 | 5/4/4 | Manter | Árvore rosa, cristais e casco de ilha fazem uma silhueta única. Rosto claro. |
| [C34](../art/creatures/C34_Serpente_Arco_Iris/antes/studio-six-views.jpg) | 2.49 × 3.00 × 2.53 | Body, Head, Tail, Fins | 4/2/3 | Refazer | A pose serpentina funciona. A distribuição de cores compete com olhos e focinho. |
| [C60](../art/creatures/C60_Hidra_das_Profundezas/antes/studio-six-views.jpg) | 3.55 × 3.33 × 2.24 | Body, Head, Tail, FinL, FinR, Extra ×5 | 5/3/4 | Manter | Três cabeças recortadas, anel e asas largas. A silhueta comunica a Hidra. |
| [C61](../art/creatures/C61_Baleia_Celestial/antes/studio-six-views.jpg) | 2.71 × 2.55 × 3.55 | Body, Head, Tail, FinL, FinR, Extra ×5 | 4/3/4 | Manter | Cauda de baleia, galáxia e anéis distinguem a peça. Vale preservar as formas. |
| [C62](../art/creatures/C62_Dragao_Dourado/antes/studio-six-views.jpg) | 3.55 × 3.33 × 2.30 | Body, Head, Wings, Claws, Tail, Extra ×4 | 0/0/0 | Refazer se o recarregamento falhar | A captura mostrou só os pontos Neon. Zero significa que a malha não apareceu nesta sessão. |
| [C63](../art/creatures/C63_Grifo_Marinho/antes/studio-six-views.jpg) | 3.17 × 3.50 × 1.67 | Body, Head, Wings, Claws, Tail, Fins, Extra ×2 | 5/4/4 | Manter | Bico, asas abertas e nadadeira anotam a mistura de águia e peixe. |
| [C64](../art/creatures/C64_Guardiao_Abissal/antes/studio-six-views.jpg) | 2.97 × 3.55 × 2.28 | Body, Extra ×6, Claws, Tentacles, Shell | 3/1/3 | Refazer · piloto | A lanterna aparece, mas o visor é pequeno e não há peça Head. O rosto fica enterrado entre as ombreiras. |
| [C88](../art/creatures/C88_Rei_Tritao_Colossal/antes/studio-six-views.jpg) | 2.18 × 3.55 × 1.68 | Body, Head, Claws, Tail, Fins, Extra ×6 | 4/3/4 | Manter | Tridente, coroa e cauda formam uma boa silhueta. Preservar a assinatura. |
| [C89](../art/creatures/C89_Dragao_de_Jade/antes/studio-six-views.jpg) | 2.71 × 3.32 × 3.44 | Body, Head, Wings, Claws, Tail, Extra ×6 | 4/3/4 | Manter | Jade, chifres e asas claras se distinguem. A pose compacta favorece o 3/4. |
| [C90](../art/creatures/C90_Tartaruga_Mundo/antes/studio-six-views.jpg) | 2.11 × 3.30 × 3.34 | Body, Head, Shell, FinL, FinR, Tail, Extra ×6 | 5/3/4 | Manter | Montanha e templo continuam legíveis. O casco resolve bem o tema do portal. |
| [C91](../art/creatures/C91_Hipocampo_Imperial/antes/studio-six-views.jpg) | 2.13 × 3.29 × 3.44 | Body, Head, FinL, FinR, Fins, Tail, Extra ×5 | 3/2/3 | Refazer | A armadura é reconhecível, mas pesada. A forma equina e o rosto ficam pouco claros de frente. |
| [C92](../art/creatures/C92_Serafim_do_Mar/antes/studio-six-views.jpg) | 3.21 × 3.20 × 1.00 | Body, Head, Wings, FinL, FinR, Tail, Extra ×9 | 4/2/3 | Refazer | A frente é clara demais para ler o rosto. Os três pares de asas precisam de separação maior. |
| [C99](../art/creatures/C99_Baleia_Fantasma/antes/studio-six-views.jpg) | 2.40 × 2.24 × 3.39 | Body, Head, FinR, FinL, Tail, Extra ×6 | 4/3/4 | Manter | Rastro de névoa sugerido pela pintura azul e pelas lanternas. Mantém proporção de baleia. |
| [C100](../art/creatures/C100_Aurora_Boreal_Viva/antes/studio-six-views.jpg) | 3.20 × 3.11 × 2.34 | Body, Head, Fins, Wings, Tail, Extra ×6 | 2/1/2 | Refazer · piloto | Cabeça ciano uniforme e membranas rosas genéricas. A forma da aurora e os olhos somem. |
| [C106](../art/creatures/C106_Rei_do_Gelo_Natalino/antes/studio-six-views.jpg) | 3.31 × 3.43 × 2.15 | Body, Head, Tail, Wings, Fins, Extra | 4/2/3 | Refazer | Asas e coroa funcionam de perfil. Falta contraste entre rosto, escamas e cristais. |

Todos têm Body como PrimaryPart. A C64 está sem Head e Tail. C23 e C30 estão sem Tail. A pose do Kraken ganha um Tail discreto no manto traseiro. No Guardião, Head é o elmo móvel e Tail é o pano traseiro. As demais peças do Kraken e do Guardião mantêm os nomes que o jogo usa.

A cena temporária de inspeção foi removida em Edit. O lote de revisão usa Blender em segundo plano.
