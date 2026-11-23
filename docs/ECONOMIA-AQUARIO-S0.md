# Aquário — S0: auditoria e simulação da economia

[Plano Claude](PLANO-AQUARIO-CLAUDE.md) · [Contrato](AQUARIO-CONTRATO.md) · simulador: `node tools/aquarium-sim.js`

Escrito em 2026-11-22. Tudo aqui sai do código atual do repositório; premissas que não dá para medir no servidor estão marcadas **[premissa]**.

## 1. Resultado em uma linha

As faixas do plano (0,15 a 6,00 moedas/s por criatura) **quebram a economia**: o aquário rende 3 a 4 vezes mais que pescar já no fim do dia 1, e um tanque cheio de Gigantes Douradas Místicas rende 19 vezes a pesca ativa. Recomendação: **fator ×0,2 nas faixas, valores guardados em centésimos de moeda por minuto**, expansões de 3.000 / 12.000 / 50.000. Com isso o aquário vira cerca de metade da renda total em duas semanas, sem tornar as varas inúteis.

## 2. Auditoria: de onde vêm e para onde vão as moedas

| Fonte | Regra atual (arquivo) | Ordem de grandeza |
|---|---|---|
| Captura | `valueFor`: baseValue × 0,75..1,25 pelo peso; × Cintilante 3 × evento × passe VIP 1,25 × prestígio (1 + 0,10·P) × combo (`Fishing/init.luau` `payCatch`) | Comum 10–15, Incomum 35–48, Rara 110–170, Épica 350–440, Lendária 1.500–1.950, Mística 9.000–10.000 |
| Combo | +3% por captura seguida, teto +30% (10 passos), só pesca manual | até ×1,30 |
| Pesca automática (passe) | Mesma `payCatch`, sem combo, teto Épica, sucesso 85% −5% por tier acima de 3 | só com passe |
| Evento do oceano | `valueMultiplier` 1,15 a 2,0 por 120–180 s a cada 12–20 min | até ×2 |
| Jornada | XP por captura → nível; nível N paga 25·N moedas; baú a cada 10 capturas: 100–300 + 10·nível | dezenas a centenas por sessão |
| Presente diário | 100/150/225/350/500/750/1000 + baú no dia 7 (500–1000) | ~3.000 por semana |
| Missões diárias | 3 por dia, 150–450 cada | ~800 por dia se completar tudo |
| Marcos da coleção | 100 a 250.000, uma vez | grandes saltos tardios |
| Conquistas | 50 a 25.000, uma vez | idem |
| Códigos | BEMVINDO 500, PESCADOR 750, LENDARIO 1.500 | 2.750 uma vez |
| Treino | nível múltiplo de 5 paga 10·nível | até 250 |
| Prestígio | presente de 25.000·P ao prestigiar (exige 1 mi e 60 espécies) | 25 mil a 250 mil |
| Robux | pacotes 1.000 e 6.000 moedas (IDs ainda 0) | fora da simulação |

**Gastos hoje:** só varas (8, total 1.629.500) e o custo do prestígio (zerar). Não existe nenhum destino de moeda recorrente, por isso um aquário precisa de preços próprios.

**Fonte nova prevista pelo plano:** renda passiva do aquário. Hoje o único "ralo" é a próxima vara; sem ajustar, a renda passiva infla tudo.

**Frequência real das variantes (código atual):**
- Gigante: o código marca peso nos 15% superiores da faixa, mas o peso sorteado é `t = u^1,8`, então a chance real é **8,63%**, não 15%.
- Cintilante: 2,5% (1 em 40). Gigante + Cintilante: **0,216%** (1 em 463 capturas).
- Consequência: a variante ×1,90 sai em ~1 de 463 capturas; tanque cheio dela só acontece muito tarde.

**Não medido:** duração e taxa de vitória por minigame/tier/dispositivo. O servidor só guarda o mínimo (`MIN_FIGHT_SECONDS` 2 / 1,2 / 1,5 s). O Codex mediu só falha total no tier 1 (Reel 15,4 s, Precision 18,4 s, Rhythm 13,2 s). Os perfis abaixo usam ciclo de 11–16 s e vitória de 70–92% **[premissa]**; trocar em `PROFILES` quando a medição do Codex chegar.

**Não medido:** saldo e coleção reais de veteranos (não há acesso a dados de produção daqui). A simulação de veterano usa 200 mil moedas, vara Storm e 60 espécies **[premissa]**.

## 3. Taxas por espécie (proposta)

- Faixa do plano × **0,2**, espécies ordenadas por `baseValue` dentro da raridade e distribuídas linearmente na faixa.
- **Unidade:** centésimos de moeda por minuto (`cpm`, inteiro, múltiplo de 10). Múltiplo de 10 garante que ×1,30 / ×1,60 / ×1,90 continuam inteiros. A liquidação fica exata: `ganho_cent = (cpm × ms + resto) // 60000`, sem ponto flutuante.
- Mostrar na UI em **moedas/min** (ex.: `+1,8/min`). Em moedas/s o Comum seria 0,03/s, ilegível.

| Raridade | Plano (moedas/s) | Proposta (moedas/min) | Equivalente em moedas/s |
|---|---|---:|---:|
| Comum | 0,15–0,30 | 1,8–3,6 | 0,03–0,06 |
| Incomum | 0,35–0,65 | 4,2–7,8 | 0,07–0,13 |
| Rara | 0,70–1,20 | 8,4–14,4 | 0,14–0,24 |
| Épica | 1,30–2,20 | 15,6–26,4 | 0,26–0,44 |
| Lendária | 2,40–4,00 | 28,8–48,0 | 0,48–0,80 |
| Mística | 4,20–6,00 | 50,4–72,0 | 0,84–1,20 |

Fatores de variante (testados): Base ×1,00, Gigante ×1,30, Dourada ×1,60, ambas ×1,90. Evento e Natal recebem taxa pela mesma regra (106 espécies, ver apêndice).

## 4. Resultados da simulação

Configuração recomendada: ×0,2, vagas 3/5/8/12, preços de expansão **3.000 / 12.000 / 50.000**. Mediana de 200 execuções por perfil, renda offline desligada, sem sinergia (as famílias ainda não existem no catálogo). Compra: o simulador compra a expansão ou a vara mais barata assim que tem saldo.

| Perfil | 1ª vaga ocupada | 1ª expansão | 2ª expansão | Taxa do tanque (moedas/s) 5 min · 15 min · 30 min | d1 · d3 · d7 · d14 | Passivo no total |
|---|---|---|---|---|---|---:|
| Iniciante (20 min/dia) | 0,3 min | 15,2 min | 58,1 min | 0,62 · 1,35 · 1,93 | 1,64 · 3,46 · 4,61 · 7,72 | 53% |
| Regular (45 min/dia) | 0,2 min | 10,0 min | 40,1 min | 0,82 · 1,76 · 2,26 | 3,67 · 5,53 · 8,70 · 9,97 | 50% |
| Rápido (90 min/dia) | 0,2 min | 7,9 min | 30,8 min | 0,87 · 1,89 · 2,65 | 4,87 · 8,83 · 10,31 · 11,68 | 44% |
| Azar (sorte ×0,5 em Rara+) | 0,2 min | 14,3 min | 55,0 min | 0,62 · 1,36 · 1,80 | 2,18 · 4,38 · 7,69 · 9,09 | 57% |
| Sorte alta (×2 em Rara+) | 0,2 min | 6,9 min | 28,8 min | 1,03 · 2,09 · 3,70 | 4,21 · 7,97 · 9,49 · 10,67 | 42% |

Alvo do plano: 1ª ampliação em 10–20 min e 2ª em 30–60. Regular e Iniciante batem; Rápido e Sorte alta ficam um pouco abaixo (aceitável, é quem joga mais ou tem sorte).

**Referência de pesca ativa** (regular, vara inicial): ~326 moedas/min = 5,4/s; com Astral ~479/min = 8,0/s. Vara: Coral paga em 1,4 min, Crystal 7,7 min, Storm 35 min, Astral 125 min, Mística 27 h.

### Por que não as faixas do plano

Com as faixas do plano (×1,0) e preços 1.500/9.000/45.000:

| | Faixas do plano ×1,0 | Recomendado ×0,2 |
|---|---:|---:|
| 1ª expansão (regular) | 5,0 min | 10,0 min |
| Taxa do tanque no fim do d1 (regular) | 18,4/s | 3,7/s |
| Passivo no total de moedas | 83–86% | 42–57% |
| Tanque cheio de Lendárias base (12 vagas, +10%) | 42,2/s = 5,3× a pesca ativa | 8,4/s = 1,1× |
| Tanque cheio de Lendárias Gigante+Dourada | 80,3/s = 10,1× | 16,1/s = 2,0× |
| Tanque cheio de Místicas Gigante+Dourada | 150,5/s = 18,8× | 30,1/s = 3,8× |

A pesca ativa ficaria irrelevante e todo o preço de vara viraria questão de segundos. Mesmo no recomendado, o teto absoluto (Místicas Gigante+Dourada) é 3,8× a pesca: aceitável como prêmio de fim de jogo, e é raríssimo (2 espécies Místicas × 1 em 463 por variante).

### Veterano

A simulação com 200 mil moedas e 60 espécies compra as quatro expansões nos primeiros segundos e o tanque já roda ~8,8 moedas/s (equivalente à pesca com Astral). Sem trava, o veterano pula os níveis 2–4 no primeiro minuto. **Recomendação:** exigir requisito de etapa além de preço, por exemplo nível 2 = 15 espécies descobertas, nível 3 = 40, nível 4 = 70 (a decidir com o João), e liberar o nível 1 já com migração. Medir o saldo real antes de fixar.

## 5. Decisões abertas (João)

1. **Unidade exibida:** moedas/min (proposta) em vez de moedas/s. Muda os exemplos do plano ("+0,44/s" vira "+26,4/min") e os fixtures do Codex.
2. **Fator ×0,2:** aceitar a escala e os preços 3.000/12.000/50.000, ou preferir aquário menos central (ainda menor) ou mais central.
3. **Cintilantes antigas:** as Cintilantes viram Douradas (×1,6) e Gigante é variante nova, ou Dourada é variante nova e as Cintilantes antigas ficam como estão. O código marca Gigante hoje só pelo peso e não guarda contagem; o plano de migração depende disso.
4. **Requisito de etapa para veteranos** nos níveis do tanque (ver acima).
5. **Offline:** só depois de decidir o item 2. Hipótese do plano: 25% da taxa, até 2 h. Com ×0,2, 2 h offline em tanque de 2/s rendem 2 × 7.200 × 25% = 3.600 moedas, perto de 7,5 min de pesca com Astral. Parece seguro, mas só decidir depois do item 2.

## 6. Pendências do S0

- Medição de duração e vitória por minigame (Codex) e saldo de veteranos reais: entram como constantes em `tools/aquarium-sim.js`.
- Famílias de sinergia: não existem no catálogo. A simulação trata sinergia como +10% fixo no teto. Definir famílias com o João em S2.
- Recompensa de sessão e prêmios de metas em moedas: não simulados (priorizar cosméticos, como o plano manda).

## Apêndice A — taxa por espécie (`cpm` = centésimos de moeda por minuto, Base ×1,00)

Gerado por `RATE_SCALE=0.2 TANK_PRICES="[0,3000,12000,50000]" node tools/aquarium-sim.js --rates`.

```
id	raridade	cpm	moedas/min
C01_Bolhinha_Azul	Common	180	1.8
C02_Sardinha_Solar	Common	230	2.3
C03_Siri_Pipoca	Common	320	3.2
C04_Baiacu_Nuvem	Uncommon	420	4.2
C05_Medusinha_Estelar	Uncommon	510	5.1
C06_Cavalo_Marinho_Coral	Uncommon	670	6.7
C07_Arraia_Prisma	Rare	840	8.4
C08_Enguia_Trovao	Rare	950	9.5
C09_Guardiao_Cristal	Epic	1560	15.6
C10_Leviata_Astral	Legendary	2880	28.8
C11_Pingo_Lanterna	Common	280	2.8
C12_Camarao_Confete	Common	200	2.0
C13_Linguado_Sonolento	Common	350	3.5
C14_Polvinho_Aquarela	Uncommon	560	5.6
C15_Tartaruga_Musgo	Uncommon	760	7.6
C16_Voador_Brisa	Uncommon	460	4.6
C17_Martelo_Coral	Rare	1180	11.8
C18_Lula_Neon	Rare	870	8.7
C19_Peixe_Lua_Dourado	Rare	1350	13.5
C20_Raia_Vulcanica	Epic	1670	16.7
C21_Baleia_Nebulosa	Epic	2260	22.6
C22_Serpente_Glacial	Epic	1880	18.8
C23_Kraken_Trovejante	Legendary	3220	32.2
C24_Fenix_das_Mares	Legendary	2990	29.9
C25_Ourico_Gelatina	Common	240	2.4
C26_Peixe_Pipa	Common	290	2.9
C27_Ermitao_Cristal	Uncommon	640	6.4
C28_Nautilo_Aurora	Rare	1100	11.0
C29_Dragao_Folha	Epic	1780	17.8
C30_Tartaruga_Ilha	Legendary	3110	31.1
C31_Carpa_Celeste	Uncommon	730	7.3
C32_Espadarte_Relampago	Rare	1270	12.7
C33_Orca_Aurora	Epic	2100	21.0
C34_Serpente_Arco_Iris	Legendary	3330	33.3
C60_Hidra_das_Profundezas	Legendary	3560	35.6
C61_Baleia_Celestial	Legendary	3780	37.8
C62_Dragao_Dourado	Legendary	4010	40.1
C63_Grifo_Marinho	Legendary	3440	34.4
C64_Guardiao_Abissal	Legendary	4690	46.9
C50_Tubarao_Baleia_Estrelado	Rare	1410	14.1
C51_Lanterna_Abissal	Rare	1040	10.4
C52_Cavalo_Marinho_Real	Rare	900	9.0
C53_Moreia_Voltaica	Rare	1210	12.1
C54_Peixe_Vela_Solar	Rare	1300	13.0
C55_Caranguejo_Rei_Gelo	Rare	1130	11.3
C56_Dragao_de_Coral	Epic	1940	19.4
C57_Manta_Galactica	Epic	2480	24.8
C58_Tubarao_Fantasma	Epic	2150	21.5
C59_Narval_Unicornio	Epic	2320	23.2
C35_Bagre_Bigodudo	Common	250	2.5
C36_Peixe_Bolha_Rosa	Common	210	2.1
C37_Caramujo_Doce	Common	190	1.9
C38_Estrela_Sonolenta	Common	260	2.6
C39_Lambari_Prata	Common	210	2.1
C40_Caranguejo_Bolacha	Common	300	3.0
C41_Palhaco_Neon	Common	330	3.3
C42_Lulinha_Gota	Common	270	2.7
C43_Baiacu_Algodao_Doce	Uncommon	530	5.3
C44_Arraia_Pintada	Uncommon	650	6.5
C45_Tartaruguinha_Coral	Uncommon	580	5.8
C46_Peixe_Leque	Uncommon	470	4.7
C47_Medusa_Lanterna	Uncommon	740	7.4
C48_Peixe_Anjo_Real	Uncommon	780	7.8
C49_Polvo_Bolinhas	Uncommon	690	6.9
C75_Leao_Marinho_Dourado	Rare	1240	12.4
C76_Raia_Aurora	Rare	980	9.8
C77_Cavalo_Marinho_Relogio	Rare	930	9.3
C78_Lagosta_Armadura	Rare	1150	11.5
C79_Mantarraia_Vitral	Rare	1380	13.8
C80_Peixe_Pavao_Eletrico	Rare	1070	10.7
C81_Enguia_Fita_de_Seda	Rare	1010	10.1
C93_Ouroboros_Cosmico	Mystic	5040	50.4
C94_Mare_Primordial	Mystic	7200	72.0
C65_Tilapia_Moranguinho	Common	270	2.7
C66_Ourico_Pompom	Common	310	3.1
C67_Lesma_do_Mar_Arco_iris	Common	340	3.4
C68_Peixe_Biscoito	Common	220	2.2
C69_Ermitao_Xicara	Common	360	3.6
C70_Agua_viva_Lanterna	Uncommon	490	4.9
C71_Peixe_Espada_Neon	Uncommon	710	7.1
C72_Tartaruga_Pergaminho	Uncommon	600	6.0
C73_Polvo_Origami	Uncommon	550	5.5
C74_Baiacu_Balao_de_Festa	Uncommon	440	4.4
C82_Kitsune_Aquatica	Epic	2370	23.7
C83_Golfinho_Trovao	Epic	1990	19.9
C84_Tubarao_Martelo_de_Cristal	Epic	2210	22.1
C85_Lula_Galaxia	Epic	1720	17.2
C86_Cervo_Coral	Epic	1830	18.3
C87_Salamandra_de_Lava	Epic	1610	16.1
C88_Rei_Tritao_Colossal	Legendary	4120	41.2
C89_Dragao_de_Jade	Legendary	3900	39.0
C90_Tartaruga_Mundo	Legendary	4800	48.0
C91_Hipocampo_Imperial	Legendary	3670	36.7
C92_Serafim_do_Mar	Legendary	4240	42.4
C95_Peixe_Vagalume_Real	Rare	1440	14.4
C96_Lua_Dourada	Epic	2530	25.3
C97_Raia_Tempestade	Epic	2420	24.2
C98_Coral_Ancestral_Vivo	Epic	2640	26.4
C99_Baleia_Fantasma	Legendary	4350	43.5
C100_Aurora_Boreal_Viva	Legendary	4570	45.7
C101_Rena_do_Mar	Common	330	3.3
C102_Peixe_Arvore_de_Natal	Uncommon	620	6.2
C103_Boneco_de_Gelo_Marinho	Rare	1330	13.3
C104_Polvo_Presente	Epic	2050	20.5
C105_Estrela_do_Natal	Epic	2590	25.9
C106_Rei_do_Gelo_Natalino	Legendary	4460	44.6
```

## 7. Decisões fechadas (2026-11-22)

O João confirmou a 3 e delegou o resto ao Claude.

| # | Decisão | Por quê |
|---|---|---|
| 1 | Unidade exibida: moedas/min; faixas ×0,2; preços 3.000 / 12.000 / 50.000 | Aprovado no S1. |
| 2 | Escala ×0,2 mantida | Passivo em 42–57% da renda em 2 semanas, teto 3,8× a pesca. |
| 3 | **Cintilante vira Dourada** (confirmado pelo João) | Já é o que a migração faz: `count − shiny` vira base, `shiny` vira gold. |
| 4 | Requisito de espécies 15 / 40 / 70 para os níveis 2 / 3 / 4 | Estimativa pela tabela de raridade: um jogador regular tem ~27 espécies aos 10 min e ~58 aos 40 min, então 15 e 40 não seguram quem joga normalmente; 70 vira meta de médio prazo e impede o veterano de comprar tudo no primeiro minuto. |
| 5 | Renda offline: continua **desligada** no lançamento; quando ligar, 25% da taxa de saída, até 2 h e **no máximo 5.000 moedas por ausência** (`OFFLINE_MAX_COINS`) | Sem teto, um tanque de fim de jogo ganharia ~54 mil em 2 h fora. 5.000 ≈ 10 min de pesca com a Astral. |
| 6 | Prêmios de sessão 40 / 60 / 100 moedas, teto 600/dia | São só um aceno (menos de 1 min de pesca); o valor da meta está em ser anunciada. Mexer só com dados. |
| 7 | Famílias: Recife, Tempestade, Abissal, Celestial, Festival (EN: Reef, Storm, Abyssal, Celestial, Festival) em `Strings.aquariumFamily` | Nomes do plano; os ids internos não mudam. |
| 8 | `LIVE_ENABLED` só vira `true` depois de: UI do Codex ligada aos dados reais, um Play com 2 jogadores e um teste em celular | Sem isso, o jogador publicado veria tanque sem interface. |
| 9 | Prestígio mantém o aquário (tanque, nível, criaturas, metas) | O prestígio já mantém a coleção; zera moedas e varas. Placar, conquistas e recibos não tocam no aquário. |

