# Criaturas: análise dos modelos, chances por criatura e +100 novas

Gerado em 23/11/2026. Parte da evolução da pesca (`docs/PLANO-PESCA-FORCA-ODDS.md`). **Nada disso está no código ainda.**
O campo novo `dropWeight` (peso relativo dentro da raridade) só entra no P1 do plano, depois do seu OK nas tabelas.

## 1. Método

- **Critério do modelo:** medi no Studio cada modelo de `ReplicatedStorage.Creatures`: nº de partes (peças animáveis: `Body`, `Head`, `Tail`, `FinL/R`, `Wings`...), peças Neon e total de MeshParts. Modelo com mais partes e brilho = mais trabalhado.
- **Regra:** dentro de cada raridade, **modelo mais detalhado e mais impressionante = mais raro**. Os 15% mais ricos ganham peso 0,25; depois 0,5; 1; 2; e os mais simples 3 (mais comuns). Desempate pelo valor.
- **Fórmula do "1 em N":** `N = (soma dos pesos de raridade / peso da raridade) x (soma dos dropWeight da raridade / dropWeight da criatura)`. Sem sorte (sem vara, treino, prestígio, boost, força). O jogo mostra o N **com** a sorte do arremesso.
- Criaturas de **evento/estação** ficam fora do pool normal (peso 1, entram com 3x só enquanto o evento roda).
- Pesos de raridade mantidos: Common 55, Uncommon 27, Rare 12, Epic 5, Legendary 1, Mystic 0.02.

## 2. Análise dos modelos (106 atuais)

- **60 de 106** são **peça única** (um MeshPart): não animam por partes, só balançam inteiros.
- **Mais trabalhados** (maior nº de partes e Neon): C92_Serafim_do_Mar (15 partes, 8 Neon); C90_Tartaruga_Mundo (12 partes, 5 Neon); C88_Rei_Tritao_Colossal (11 partes, 5 Neon); C89_Dragao_de_Jade (11 partes, 5 Neon); C91_Hipocampo_Imperial (11 partes, 4 Neon); C99_Baleia_Fantasma (11 partes, 5 Neon); C60_Hidra_das_Profundezas (10 partes, 4 Neon); C61_Baleia_Celestial (10 partes, 4 Neon); C94_Mare_Primordial (9 partes, 0 Neon).
- Melhor padrão a copiar para os novos: **C92_Serafim_do_Mar** (15 partes, 8 Neon), depois **C90**, **C88**, **C89**, **C91**, **C99** (11-12 partes). Todos filhos diretos do Model, com `PrimaryPart = Body`.
- **Dívida de detalhe:** criaturas Raras ou melhores ainda em peça única (candidatas a refazer primeiro, porque aparecem nas revelações grandes):
  - Épico (16): C20 Raia Vulcanica, C21 Baleia Nebulosa, C22 Serpente Glacial, C29 Dragao Folha, C33 Orca Aurora, C56 Dragao de Coral, C57 Manta Galactica, C58 Tubarao Fantasma, C59 Narval Unicornio, C83 Golfinho Trovao, C85 Lula Galaxia, C87 Salamandra de Lava, C96 Lua Dourada, C97 Raia Tempestade, C98 Coral Ancestral Vivo, C105 Estrela do Natal
  - Raro (13): C07 Arraia Prisma, C08 Enguia Trovao, C17 Martelo Coral, C18 Lula Neon, C19 Peixe Lua Dourado, C28 Nautilo Aurora, C32 Espadarte Relampago, C51 Lanterna Abissal, C53 Moreia Voltaica, C54 Peixe Vela Solar, C78 Lagosta Armadura, C79 Mantarraia Vitral, C95 Peixe Vagalume Real
- C93 Ouroboros está em remodelagem (v2 `.glb` em `art/creatures/C93-remodel`); o peso dele pode subir quando sair.

## 3. Separação das 106 atuais (proposta de `dropWeight`)

Ordem: do mais comum para o mais raro dentro de cada raridade. `N` é "1 em N" por arremesso, sem sorte, **já com as 100 novas no pool**.

### Comum (peso da raridade 55; pool 36)

| Criatura | Partes/Neon | dropWeight | 1 em N |
|---|---|---|---|
| C01_Bolhinha_Azul | 1/0 | 3 | 28 |
| C37_Caramujo_Doce | 1/0 | 3 | 28 |
| C39_Lambari_Prata | 1/0 | 3 | 28 |
| C68_Peixe_Biscoito | 1/0 | 3 | 28 |
| C42_Lulinha_Gota | 1/0 | 3 | 28 |
| C02_Sardinha_Solar | 1/0 | 2 | 42 |
| C25_Ourico_Gelatina | 1/0 | 2 | 42 |
| C35_Bagre_Bigodudo | 1/0 | 2 | 42 |
| C38_Estrela_Sonolenta | 1/0 | 2 | 42 |
| C11_Pingo_Lanterna | 1/0 | 2 | 42 |
| C26_Peixe_Pipa | 1/0 | 2 | 42 |
| C40_Caranguejo_Bolacha | 1/0 | 2 | 42 |
| C67_Lesma_do_Mar_Arco_iris | 1/0 | 2 | 42 |
| C66_Ourico_Pompom | 2/0 | 1 | 84 |
| C03_Siri_Pipoca | 1/0 | 1 | 84 |
| C41_Palhaco_Neon | 1/0 | 1 | 84 |
| C13_Linguado_Sonolento | 1/0 | 1 | 84 |
| C65_Tilapia_Moranguinho | 4/0 | 0.5 | 168 |
| C12_Camarao_Confete | 5/0 | 0.25 | 336 |
| C36_Peixe_Bolha_Rosa | 5/0 | 0.25 | 336 |
| C69_Ermitao_Xicara | 5/0 | 0.25 | 336 |
| C101_Rena_do_Mar (xmas) | 5/0 | 1 (evento, 3x) | só no evento |

### Incomum (peso da raridade 27; pool 35)

| Criatura | Partes/Neon | dropWeight | 1 em N |
|---|---|---|---|
| C04_Baiacu_Nuvem | 1/0 | 3 | 55 |
| C16_Voador_Brisa | 1/0 | 3 | 55 |
| C46_Peixe_Leque | 1/0 | 3 | 55 |
| C05_Medusinha_Estelar | 1/0 | 3 | 55 |
| C73_Polvo_Origami | 1/0 | 3 | 55 |
| C14_Polvinho_Aquarela | 1/0 | 2 | 83 |
| C45_Tartaruguinha_Coral | 1/0 | 2 | 83 |
| C72_Tartaruga_Pergaminho | 1/0 | 2 | 83 |
| C44_Arraia_Pintada | 1/0 | 2 | 83 |
| C06_Cavalo_Marinho_Coral | 1/0 | 2 | 83 |
| C49_Polvo_Bolinhas | 1/0 | 2 | 83 |
| C71_Peixe_Espada_Neon | 1/0 | 2 | 83 |
| C70_Agua_viva_Lanterna | 3/0 | 1 | 166 |
| C31_Carpa_Celeste | 1/0 | 1 | 166 |
| C47_Medusa_Lanterna | 1/0 | 1 | 166 |
| C48_Peixe_Anjo_Real | 1/0 | 1 | 166 |
| C74_Baiacu_Balao_de_Festa | 4/0 | 0.5 | 332 |
| C43_Baiacu_Algodao_Doce | 4/0 | 0.5 | 332 |
| C27_Ermitao_Cristal | 5/0 | 0.25 | 663 |
| C15_Tartaruga_Musgo | 6/0 | 0.25 | 663 |
| C102_Peixe_Arvore_de_Natal (xmas) | 4/0 | 1 (evento, 3x) | só no evento |

### Raro (peso da raridade 12; pool 40)

| Criatura | Partes/Neon | dropWeight | 1 em N |
|---|---|---|---|
| C07_Arraia_Prisma | 1/0 | 3 | 143 |
| C18_Lula_Neon | 1/0 | 3 | 143 |
| C08_Enguia_Trovao | 1/0 | 3 | 143 |
| C51_Lanterna_Abissal | 1/0 | 3 | 143 |
| C28_Nautilo_Aurora | 1/0 | 3 | 143 |
| C78_Lagosta_Armadura | 1/0 | 3 | 143 |
| C76_Raia_Aurora | 4/0 | 2 | 215 |
| C17_Martelo_Coral | 1/0 | 2 | 215 |
| C53_Moreia_Voltaica | 1/0 | 2 | 215 |
| C32_Espadarte_Relampago | 1/0 | 2 | 215 |
| C54_Peixe_Vela_Solar | 1/0 | 2 | 215 |
| C19_Peixe_Lua_Dourado | 1/0 | 2 | 215 |
| C79_Mantarraia_Vitral | 1/0 | 2 | 215 |
| C52_Cavalo_Marinho_Real | 5/0 | 1 | 429 |
| C77_Cavalo_Marinho_Relogio | 5/0 | 1 | 429 |
| C81_Enguia_Fita_de_Seda | 5/0 | 1 | 429 |
| C80_Peixe_Pavao_Eletrico | 6/0 | 1 | 429 |
| C75_Leao_Marinho_Dourado | 6/0 | 1 | 429 |
| C50_Tubarao_Baleia_Estrelado | 6/0 | 1 | 429 |
| C55_Caranguejo_Rei_Gelo | 7/0 | 0.5 | 859 |
| C95_Peixe_Vagalume_Real (shimmerShoal) | 1/0 | 1 (evento, 3x) | só no evento |
| C103_Boneco_de_Gelo_Marinho (xmas) | 6/0 | 1 (evento, 3x) | só no evento |

### Épico (peso da raridade 5; pool 36)

| Criatura | Partes/Neon | dropWeight | 1 em N |
|---|---|---|---|
| C87_Salamandra_de_Lava | 1/0 | 3 | 308 |
| C20_Raia_Vulcanica | 1/0 | 3 | 308 |
| C85_Lula_Galaxia | 1/0 | 3 | 308 |
| C29_Dragao_Folha | 1/0 | 3 | 308 |
| C83_Golfinho_Trovao | 1/0 | 3 | 308 |
| C86_Cervo_Coral | 6/0 | 2 | 463 |
| C22_Serpente_Glacial | 1/0 | 2 | 463 |
| C56_Dragao_de_Coral | 1/0 | 2 | 463 |
| C33_Orca_Aurora | 1/0 | 2 | 463 |
| C58_Tubarao_Fantasma | 1/0 | 2 | 463 |
| C21_Baleia_Nebulosa | 1/0 | 2 | 463 |
| C59_Narval_Unicornio | 1/0 | 2 | 463 |
| C57_Manta_Galactica | 1/0 | 2 | 463 |
| C09_Guardiao_Cristal | 8/0 | 1 | 925 |
| C84_Tubarao_Martelo_de_Cristal | 8/0 | 1 | 925 |
| C82_Kitsune_Aquatica | 6/0 | 1 | 925 |
| C96_Lua_Dourada (starTide) | 1/0 | 1 (evento, 3x) | só no evento |
| C97_Raia_Tempestade (thunderStorm) | 1/0 | 1 (evento, 3x) | só no evento |
| C98_Coral_Ancestral_Vivo (goldenHour) | 1/0 | 1 (evento, 3x) | só no evento |
| C104_Polvo_Presente (xmas) | 4/0 | 1 (evento, 3x) | só no evento |
| C105_Estrela_do_Natal (xmas) | 1/0 | 1 (evento, 3x) | só no evento |

### Lendário (peso da raridade 1; pool 39)

| Criatura | Partes/Neon | dropWeight | 1 em N |
|---|---|---|---|
| C10_Leviata_Astral | 4/0 | 3 | 1,7 mil |
| C24_Fenix_das_Mares | 4/0 | 3 | 1,7 mil |
| C30_Tartaruga_Ilha | 6/2 | 3 | 1,7 mil |
| C23_Kraken_Trovejante | 6/2 | 3 | 1,7 mil |
| C34_Serpente_Arco_Iris | 4/0 | 3 | 1,7 mil |
| C63_Grifo_Marinho | 8/2 | 3 | 1,7 mil |
| C62_Dragao_Dourado | 9/3 | 2 | 2,5 mil |
| C64_Guardiao_Abissal | 9/3 | 2 | 2,5 mil |
| C60_Hidra_das_Profundezas | 10/4 | 1 | 5,1 mil |
| C61_Baleia_Celestial | 10/4 | 1 | 5,1 mil |
| C91_Hipocampo_Imperial | 11/4 | 0.5 | 10 mil |
| C89_Dragao_de_Jade | 11/5 | 0.25 | 20 mil |
| C88_Rei_Tritao_Colossal | 11/5 | 0.25 | 20 mil |
| C92_Serafim_do_Mar | 15/8 | 0.25 | 20 mil |
| C90_Tartaruga_Mundo | 12/5 | 0.25 | 20 mil |
| C99_Baleia_Fantasma (fogBank) | 11/5 | 1 (evento, 3x) | só no evento |
| C100_Aurora_Boreal_Viva (aurora) | 7/2 | 1 (evento, 3x) | só no evento |
| C106_Rei_do_Gelo_Natalino (xmas) | 6/0 | 1 (evento, 3x) | só no evento |

### Mística (peso da raridade 0.02; pool 8)

| Criatura | Partes/Neon | dropWeight | 1 em N |
|---|---|---|---|
| C93_Ouroboros_Cosmico | 3/0 | 0.275 | 18 mil |
| C94_Mare_Primordial | 9/0 | 0.22 | 23 mil |

## 4. As 100 criaturas novas (só a lista, para o gerador de modelos)

IDs `C107` a `C206`. Cada uma vai com: **família do aquário** (para sinergia), **estilo de revelação**, **valor base**, **faixa de peso (kg)**, **dropWeight** e **1 em N** (sem sorte).

Distribuição: 6 Místicas, 24 Lendárias, 20 Épicas, 20 Raras, 15 Incomuns, 15 Comuns.

### Brief de modelo (vale para todas)
- Siga `docs/CRIATURAS-NOVAS.md` (hierarquia, escala, orientação +Z, `Extra` para detalhes) e os prompts detalhados em `docs/prompts-antigravity/` (4 lotes).
- Partes por raridade: **Comum 1-3, Incomum 3-5, Raro 5-7, Épico 7-10, Lendário 9-12 (3+ Neon), Mística 12-15 (6+ Neon)**. Régua de qualidade: C92 Serafim (15 partes, 8 Neon).
- Partes nomeadas, filhas diretas do Model: `Body` (PrimaryPart), `Head`, `Tail`, `FinL`, `FinR`, `Fins`, `Wings`, `Tentacles`, `Legs`, `Claws`, `Shell`, `Extra`. Pivô no centro do `Body`; `Anchored = true`, `CanCollide = false`, sem scripts.
- Silhueta forte e legível de longe (vai virar sombra crescente na revelação). Paleta viva (cristal, rosa, dourado, âmbar). Sem texturas acima de 1024 px.
- Máx. ~8.000 faces por modelo (padrão do projeto: C23 era o maior com 7.978).

### Mística (6)

| ID | Conceito | Família | Revelação | Valor | kg | dropWeight | 1 em N |
|---|---|---|---|---|---|---|---|
| C107_Relogio_do_Abismo_Eterno | baleia-relógio, ponteiros de luz orbitando o corpo | Celestial | cosmic | 14610 | 20000-96130 | 0.04 | 125 mil |
| C108_Yggdrasil_Marinha | árvore-mundo nadando, raízes feitas de peixinhos de luz | Recife | crystal | 14100 | 20000-90970 | 0.06 | 83 mil |
| C109_Fenix_do_Vazio | fênix de buraco negro e estrelas, asas de nebulosa | Celestial | cosmic | 12550 | 20000-75480 | 0.12 | 42 mil |
| C110_Rei_Dragao_do_Oceano | dragão oriental de água viva, coroa de relâmpago | Tempestade | storm | 13580 | 20000-85810 | 0.08 | 63 mil |
| C111_Deusa_da_Lua_Submersa | serpente-lua prateada, véu de marés | Celestial | frost | 11000 | 20000-60000 | 0.18 | 28 mil |
| C112_Singularidade_Estelar | esfera viva com anéis e luas, olho central | Abissal | cosmic | 15000 | 20000-100000 | 0.025 | 200 mil |

### Lendário (24)

| ID | Conceito | Família | Revelação | Valor | kg | dropWeight | 1 em N |
|---|---|---|---|---|---|---|---|
| C113_Pegaso_das_Ondas | cavalo alado de espuma, crina de nuvem | Celestial | cloud | 1910 | 1500-7770 | 1 | 5,1 mil |
| C114_Quimera_Marinha | leão, cobra e águia em um corpo só | Abissal | magma | 1970 | 1500-8840 | 0.5 | 10 mil |
| C115_Leviata_de_Cristal | serpente gigante de vitral, luz por dentro | Celestial | crystal | 1970 | 1500-8840 | 0.5 | 10 mil |
| C116_Fenix_Glacial | fênix de gelo, penas de cristal azul | Tempestade | frost | 1910 | 1500-7770 | 1 | 5,1 mil |
| C117_Basilisco_de_Coral | lagarto-rei de coral, coroa de pólipos | Recife | prism | 1910 | 1500-7770 | 1 | 5,1 mil |
| C118_Rainha_Sereia_Imperial | sereia com cauda de arco-íris e tridente | Celestial | prism | 2000 | 1500-9380 | 0.25 | 20 mil |
| C119_Wyvern_do_Relampago | dragão de duas patas, asas de nuvem negra | Tempestade | storm | 1970 | 1500-8840 | 0.5 | 10 mil |
| C120_Colosso_Tentaculado | cabeça de polvo gigante, olhos de galáxia | Abissal | cosmic | 2000 | 1500-9380 | 0.25 | 20 mil |
| C121_Esfinge_das_Mares | esfinge de pedra e coral, olhos de safira | Abissal | crystal | 1910 | 1500-7770 | 1 | 5,1 mil |
| C122_Golem_de_Coral_Ancestral | gigante de coral vivo, jardim nas costas | Recife | crystal | 1910 | 1500-7770 | 1 | 5,1 mil |
| C123_Medusa_Imperatriz | medusa com coroa de espinhos e véus de luz | Abissal | spark | 1970 | 1500-8840 | 0.5 | 10 mil |
| C124_Lobo_do_Mar_Lunar | lobo prateado de água, cauda de maré | Celestial | frost | 1800 | 1500-5630 | 2 | 2,5 mil |
| C125_Tigre_das_Correntes | tigre listrado de correntezas, olhos elétricos | Tempestade | storm | 1910 | 1500-7770 | 1 | 5,1 mil |
| C126_Elefante_Titan_das_Mares | elefante-baleia gigante, presas de pérola | Recife | cloud | 1910 | 1500-7770 | 1 | 5,1 mil |
| C127_Caranguejo_Colosso | caranguejo-ilha, vulcão nas costas | Abissal | magma | 1800 | 1500-5630 | 2 | 2,5 mil |
| C128_Garca_Estelar | garça de constelações, pescoço de aurora | Celestial | cosmic | 1970 | 1500-8840 | 0.5 | 10 mil |
| C129_Mamute_de_Gelo_Marinho | mamute-narval de gelo, aurora nas presas | Tempestade | frost | 1800 | 1500-5630 | 2 | 2,5 mil |
| C130_Megalodonte_Real | tubarão colossal com coroa de dentes dourados | Abissal | storm | 1910 | 1500-7770 | 1 | 5,1 mil |
| C131_Naga_das_Profundezas | cobra de sete cabeças, escamas opalinas | Abissal | prism | 1800 | 1500-5630 | 2 | 2,5 mil |
| C132_Oraculo_do_Mar | peixe-olho gigante, halo de runas | Celestial | cosmic | 1970 | 1500-8840 | 0.5 | 10 mil |
| C133_Sol_Vivo_das_Mares | peixe-sol dourado, raios como barbatanas | Celestial | magma | 1910 | 1500-7770 | 1 | 5,1 mil |
| C134_Vulcao_Nadador | ilha vulcânica que nada, lava em rios | Tempestade | magma | 1800 | 1500-5630 | 2 | 2,5 mil |
| C135_Imperador_Orca_Sombria | orca preta com manto de aurora | Abissal | frost | 1800 | 1500-5630 | 2 | 2,5 mil |
| C136_Polvo_Alquimista | polvo com oito frascos mágicos nos braços | Recife | prism | 1970 | 1500-8840 | 0.5 | 10 mil |

### Épico (20)

| ID | Conceito | Família | Revelação | Valor | kg | dropWeight | 1 em N |
|---|---|---|---|---|---|---|---|
| C137_Arraia_Cometa | arraia com cauda de cometa | Celestial | cosmic | 440 | 30-190 | 0.25 | 3,7 mil |
| C138_Tubarao_Tigre_Neon | tubarão listrado fluorescente | Recife | spark | 413 | 30-160 | 0.5 | 1,9 mil |
| C139_Dragao_Filhote_das_Mares | dragãozinho de água, asas curtas | Tempestade | storm | 413 | 30-160 | 0.5 | 1,9 mil |
| C140_Lontra_Estelar | lontra com barriga de estrelas | Celestial | spark | 413 | 30-160 | 0.5 | 1,9 mil |
| C141_Naja_de_Coral | cobra de coral rosa com capuz | Recife | prism | 413 | 30-160 | 0.5 | 1,9 mil |
| C142_Golfinho_de_Cristal | golfinho de vidro, arco-íris dentro | Celestial | crystal | 440 | 30-190 | 0.25 | 3,7 mil |
| C143_Jubarte_Tempestade | baleia de nuvem, raios nas nadadeiras | Tempestade | storm | 440 | 30-190 | 0.25 | 3,7 mil |
| C144_Lula_Colossal_Neon | lula gigante de luz azul | Abissal | spark | 413 | 30-160 | 0.5 | 1,9 mil |
| C145_Peixe_Espada_Carmesim | peixe-espada em brasa | Abissal | magma | 413 | 30-160 | 0.5 | 1,9 mil |
| C146_Crocodilo_de_Jade | crocodilo de jade polido | Recife | crystal | 360 | 30-110 | 1 | 925 |
| C147_Caranguejo_Cometa | caranguejo com casco de meteoro | Celestial | cosmic | 360 | 30-110 | 1 | 925 |
| C148_Cavalo_Marinho_Dragao | hipocampo com cabeça de dragão | Recife | prism | 440 | 30-190 | 0.25 | 3,7 mil |
| C149_Foca_de_Gelo_Mistico | foca de gelo com runas | Tempestade | frost | 360 | 30-110 | 1 | 925 |
| C150_Tartaruga_Relampago | tartaruga de casco elétrico | Tempestade | storm | 360 | 30-110 | 1 | 925 |
| C151_Pinguim_Imperador_Cristal | pinguim de cristal e gelo | Tempestade | frost | 413 | 30-160 | 0.5 | 1,9 mil |
| C152_Manta_Solar | manta dourada, asas de luz | Celestial | magma | 440 | 30-190 | 0.25 | 3,7 mil |
| C153_Peixe_Boi_Encantado | peixe-boi com flores nas costas | Recife | bubbles | 360 | 30-110 | 1 | 925 |
| C154_Mamba_das_Mares | cobra-do-mar de escamas negras e verde-neon | Abissal | spark | 413 | 30-160 | 0.5 | 1,9 mil |
| C155_Siri_Samurai | caranguejo com armadura e katana | Recife | prism | 360 | 30-110 | 1 | 925 |
| C156_Albatroz_das_Nuvens | ave marinha de nuvem e vento | Celestial | cloud | 360 | 30-110 | 1 | 925 |

### Raro (20)

| ID | Conceito | Família | Revelação | Valor | kg | dropWeight | 1 em N |
|---|---|---|---|---|---|---|---|
| C157_Peixe_Sabre_Prata | peixe-fita prateado | Abissal | spark | 146 | 4-24.9 | 1 | 429 |
| C158_Moreia_Esmeralda | moreia de brilho verde | Recife | prism | 162 | 4-28.3 | 0.5 | 859 |
| C159_Polvo_Mimico | polvo que imita outros peixes | Recife | prism | 170 | 4-30 | 0.25 | 1,7 mil |
| C160_Peixe_Lanterna_Dourado | lanterna dourada na testa | Abissal | spark | 170 | 4-30 | 0.25 | 1,7 mil |
| C161_Lagosta_Rubi | lagosta de casca de rubi | Recife | crystal | 170 | 4-30 | 0.25 | 1,7 mil |
| C162_Esponja_Guerreira | esponja com elmo e escudo | Recife | bubbles | 162 | 4-28.3 | 0.5 | 859 |
| C163_Tubarao_Duende | tubarão-duende rosa, mandíbula esticável | Abissal | frost | 146 | 4-24.9 | 1 | 429 |
| C164_Peixe_Pedra_Vulcanico | peixe-pedra com lava nas fendas | Tempestade | magma | 170 | 4-30 | 0.25 | 1,7 mil |
| C165_Camarao_Mantis_Arcoiris | camarão-mantis, 12 cores | Recife | prism | 170 | 4-30 | 0.25 | 1,7 mil |
| C166_Arraia_Jaguar | arraia pintada como onça | Recife | spark | 146 | 4-24.9 | 1 | 429 |
| C167_Peixe_Gato_Eletrico | bagre com bigodes de faísca | Tempestade | storm | 162 | 4-28.3 | 0.5 | 859 |
| C168_Cavala_Relampago | cavala listrada de raios | Tempestade | storm | 162 | 4-28.3 | 0.5 | 859 |
| C169_Caramujo_Cone_Dourado | caramujo com concha de ouro | Recife | crystal | 162 | 4-28.3 | 0.5 | 859 |
| C170_Estrela_do_Mar_Gigante | estrela de nove braços | Recife | spark | 146 | 4-24.9 | 1 | 429 |
| C171_Cobra_do_Mar_Listrada | cobra anelada preta e branca | Abissal | spark | 115 | 4-18 | 2 | 215 |
| C172_Raia_Veludo | raia de veludo roxo | Celestial | cloud | 146 | 4-24.9 | 1 | 429 |
| C173_Peixe_Remo_Prata | peixe-remo fita comprida | Abissal | frost | 146 | 4-24.9 | 1 | 429 |
| C174_Baiacu_Espinho_de_Cristal | baiacu com espinhos de cristal | Recife | crystal | 162 | 4-28.3 | 0.5 | 859 |
| C175_Siri_Joia | siri com casco de pedras preciosas | Recife | prism | 162 | 4-28.3 | 0.5 | 859 |
| C176_Salmao_Real_Ouro | salmão de escamas douradas | Celestial | magma | 170 | 4-30 | 0.25 | 1,7 mil |

### Incomum (15)

| ID | Conceito | Família | Revelação | Valor | kg | dropWeight | 1 em N |
|---|---|---|---|---|---|---|---|
| C177_Peixe_Cirurgiao_Azul | azul-royal, cauda amarela | Recife | bubbles | 35 | 0.3-2.3 | 1 | 166 |
| C178_Peixe_Borboleta | listras e olho falso | Recife | prism | 35 | 0.3-2.3 | 1 | 166 |
| C179_Camarao_Pistola | garra gigante que estala | Recife | splash | 44 | 0.3-3.3 | 0.5 | 332 |
| C180_Lesma_Marinha_Pavao | lesma com penas de pavão | Recife | prism | 48 | 0.3-3.8 | 0.25 | 663 |
| C181_Tartaruga_Jovem_Verde | filhote curioso | Recife | bubbles | 44 | 0.3-3.3 | 0.5 | 332 |
| C182_Peixe_Pedra_Camuflado | parece rocha com olhos | Abissal | splash | 44 | 0.3-3.3 | 0.5 | 332 |
| C183_Estrela_Quebradica | braços finos e brilhantes | Abissal | spark | 44 | 0.3-3.3 | 0.5 | 332 |
| C184_Pepino_Marinho_Sorridente | pepino do mar com carinha | Recife | bubbles | 35 | 0.3-2.3 | 1 | 166 |
| C185_Cavalinha_Brilhante | cardume de prata | Celestial | spark | 35 | 0.3-2.3 | 1 | 166 |
| C186_Peixe_Lua_Prata | disco prateado calmo | Celestial | cloud | 35 | 0.3-2.3 | 1 | 166 |
| C187_Caranguejo_Violinista | uma garra enorme que toca | Recife | splash | 35 | 0.3-2.3 | 1 | 166 |
| C188_Peixe_Sapo_Rosa | peixe-sapo rosa fofo | Abissal | bubbles | 48 | 0.3-3.8 | 0.25 | 663 |
| C189_Caracol_Cone | concha estampada | Recife | prism | 35 | 0.3-2.3 | 1 | 166 |
| C190_Anemona_Dancarina | anêmona que balança | Recife | spark | 44 | 0.3-3.3 | 0.5 | 332 |
| C191_Peixe_Mandarim | azul e laranja psicodélico | Recife | prism | 48 | 0.3-3.8 | 0.25 | 663 |

### Comum (15)

| ID | Conceito | Família | Revelação | Valor | kg | dropWeight | 1 em N |
|---|---|---|---|---|---|---|---|
| C192_Sardinha_Bebe | sardinha minúscula, olhos enormes | Recife | splash | 10 | 0.1-0.7 | 1 | 84 |
| C193_Tainha_Alegre | tainha saltitante | Recife | splash | 10 | 0.1-0.7 | 1 | 84 |
| C194_Anchova_Esperta | anchova com óculos | Recife | splash | 13 | 0.1-1 | 0.5 | 168 |
| C195_Cascudinho_Azul | limpador do aquário | Recife | bubbles | 13 | 0.1-1 | 0.5 | 168 |
| C196_Mexilhao_Sorridente | mexilhão com sorriso | Recife | bubbles | 10 | 0.1-0.7 | 1 | 84 |
| C197_Ostra_Pequena | ostra com pérola de brinquedo | Recife | bubbles | 15 | 0.1-1.1 | 0.25 | 336 |
| C198_Peixe_Lapis | peixe-lápis amarelo | Recife | splash | 13 | 0.1-1 | 0.5 | 168 |
| C199_Camarao_Bebe | camarãozinho rosa | Recife | splash | 10 | 0.1-0.7 | 1 | 84 |
| C200_Concha_Espiral | caracol de espiral perfeita | Recife | bubbles | 10 | 0.1-0.7 | 1 | 84 |
| C201_Alga_Viva | alga com olhinhos | Recife | bubbles | 13 | 0.1-1 | 0.5 | 168 |
| C202_Peixe_Bola_Amarelo | bola de borracha com nadadeiras | Recife | splash | 13 | 0.1-1 | 0.5 | 168 |
| C203_Caranguejinho_Areia | caranguejo cor de areia | Recife | splash | 10 | 0.1-0.7 | 1 | 84 |
| C204_Mini_Polvo_Verde | polvinho verde tímido | Recife | bubbles | 13 | 0.1-1 | 0.5 | 168 |
| C205_Estrelinha_Rosa | estrela rosa de cinco pontas | Recife | spark | 15 | 0.1-1.1 | 0.25 | 336 |
| C206_Lambari_Dourado | lambari de escamas de ouro | Recife | splash | 13 | 0.1-1 | 0.5 | 168 |

## 5. O que cada nova criatura exige no código quando o modelo chegar

1. Entrada em `Config/Creatures.luau` (`rarity`, `tier`, `baseValue`, `weightMin/Max`, `revealStyle`, `dropWeight`).
2. `Config/Aquarium.luau`: `RATES_CPM` (múltiplo de 10; mesma banda da raridade) e `FAMILY`. O teste `tools/aquarium-test.luau` falha se faltar.
3. `Strings.luau`: nome PT/EN e lore curto.
4. Modelo em `ReplicatedStorage.Creatures` com o nome exato do ID.
5. Ver `docs/AQUARIO-CONTRATO.md` para metas de renda: 100 criaturas novas mudam o total de espécies (portão de expansão 15/40/70 espécies e metas de coleção).

Resumo de chances (sem sorte), pelas 206 criaturas:

- Comum: pool 36, de 1 em 28 a 1 em 336.
- Incomum: pool 35, de 1 em 55 a 1 em 663.
- Raro: pool 40, de 1 em 143 a 1 em 1,7 mil.
- Épico: pool 36, de 1 em 308 a 1 em 3,7 mil.
- Lendário: pool 39, de 1 em 1,7 mil a 1 em 20 mil.
- Mística: pool 8, de 1 em 18 mil a 1 em 200 mil.
