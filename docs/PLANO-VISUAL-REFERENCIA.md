# Plano visual: lançamento, "1 em N" e revelação no estilo do vídeo de referência

Pedido do João (23/11/2026): "bem colorido, com efeitos e animação", na pegada do vídeo que ele mandou (47 s, vertical 576x1024, um jogo de laço de animais). Estado: **só plano**. Este plano é a camada visual do que já está aprovado em `docs/PLANO-PESCA-FORCA-ODDS.md` §4–§5 e `docs/PLANO-TREINO-PODER.md` §7. O servidor já entrega os dados (`aim`, `powerBand`, `odds`, eventos do Poder); falta a arte.

**Inspiração, não cópia:** usamos a *estrutura* (medidor, contagem, palavra que muda, fundo que muda, silhueta que cresce, nome que aparece letra por letra). Textos, cores exatas, assets e marcas do jogo do vídeo **não** entram; tudo é do Legendary Catch (paleta da ilha, criaturas nossas).

## 1. O que o vídeo faz (quadro a quadro)

| Momento | O que aparece |
|---|---|
| Lançar | Medidor de força **vertical** à direita (preto, laranja, amarelo, verde, com rótulos GOOD / GREAT / PERFECT) e dica "TAP TO THROW!" em balão. O boneco gira o laço sobre a cabeça num círculo verde. |
| Voo | Câmera acompanha o laço de trás, quase no chão. Cabeçalho "2.02X LUCK" fixo. |
| Pouso | Anel de corda no chão, brilho verde. Banner **"LUCKY!"** e contador "**1 in 1**". |
| Contagem | O contador **sobe passando por todos os degraus**: 1, 4, 10, 19, 25, 84, 10.710, 279.490, 13,4 milhões, 178 milhões, 3 bilhões, 14 bilhões. A cada degrau a **palavra muda** (LUCKY, UNCOMMON, INSANE, UNREAL, GODLY, MYTHICAL, DIVINE, COSMIC). |
| Fundo | Muda de cor a cada faixa (verde, marrom, vermelho, azul, roxo, ciano, preto cósmico) e ganha **raios em leque** (sunburst) que giram. |
| Criatura | Silhueta no centro com "**GROWING...**" e uma **palavra de tamanho** que escala (NORMAL, BIG!, GIANT!, TITANIC!, PLANETARY!, UNIVERSAL!, MULTIVERSAL!, OMNIVERSAL!) cada uma de cor diferente. Ela **cresce** a cada degrau. |
| Nome | Aparece **letra por letra** (`G___`, `GO__`, `GOA_`, `GOAT`). |
| Festa | Confete colorido cada vez mais denso, estrelas, tremidinha, flashes suaves. |
| Final | A criatura em cor, nome grande, "NEW!", renda por segundo e "tap to continue". |
| Detalhes | O texto do contador "estoura" (escala + borrão) a cada tique; HUD limpo, só o essencial. Tudo pensado para **retrato** (celular). |

## 2. Tradução para o Legendary Catch

| Do vídeo | Nosso equivalente | Fonte do dado |
|---|---|---|
| Medidor vertical de força | **Barra de força** (já no servidor). Layout retrato: **vertical à direita** (polegar), horizontal só em paisagem/PC. Mesmas faixas (vermelho, amarelo, neutro, verde, roxo) e rótulos em PT. | `aimLayout`, `aimStart` |
| Laço girando | **Vara que gira/balança para trás e lança** (cutscene do plano §4), arco da linha e anel d'água na cor da faixa. | `cast.powerBand` |
| "LUCKY!" + contador | **Banner de degrau + "1 em N"** subindo. | `caught.odds` |
| Palavra por degrau | 7 palavras (tabela §3). | `oddsBucket` calculado no cliente a partir de `odds` |
| Fundo que muda + raios | **Cenário do degrau**: cor, sunburst, partículas (tabela §3). | cliente |
| Silhueta que cresce | A **criatura real em preto** (ViewportFrame), tamanho por degrau. | `creatureId` |
| Palavra de tamanho / mutação | **Variante e tamanho da pescaria**: "Gigante", "Dourada", "Gigante Dourada" (já existem em `variantId`) e a faixa de peso (comum, grande, gigante, recorde). | `variantId`, `isGiant`, `isRecord` |
| Nome letra por letra | Nome em PT (ou EN) com **espaços em branco** que vão sendo preenchidos até o fim. | `Strings.creatureName` |
| "NEW!" | Selo "NOVA DESCOBERTA" (já planejado), no card final. | `isNew` |
| Renda por segundo | **Taxa do aquário** (`potentialCpm`), "rende X moedas/min no aquário". | `potentialCpm` |
| Cabeçalho "2.02X LUCK" | **Multiplicador de sorte do arremesso** (faixa + treino + vara) como faixa fixa, ex. "SORTE x2,4". | cliente (com o `powerBand`) |

## 3. Os 7 degraus: palavra, cor e efeitos

Degraus pelo "1 em N" real (os mesmos do plano de pesca). Efeitos **acumulam** (cada degrau soma camadas; o vault fwjelaa diz que grandeza é poucas camadas escaladas, não tudo ligado). Tempo = tempo total da contagem naquele resultado, com pulo sempre disponível.

| # | Chance | Palavra (PT / EN) | Fundo | Camadas novas | Tempo |
|---|---|---|---|---|---|
| 1 | ≤ 1 em 50 | SORTE! / LUCKY! | verde-água vivo | silhueta pequena, estourinho no número | ~0,7 s |
| 2 | ≤ 1 em 150 | UAU! / WOW! | azul-cristal | raios leves girando, 8 confetes | ~1,2 s |
| 3 | ≤ 1 em 500 | INSANO! / INSANE! | roxo | confete mais denso, tremidinha no tique | ~1,8 s |
| 4 | ≤ 1 em 2.000 | IRREAL! / UNREAL! | rosa neon | câmera sob a água, silhueta sobe do fundo, flash suave | ~2,6 s |
| 5 | ≤ 1 em 10.000 | DIVINO! / DIVINE! | dourado | raios grandes, brilhos soltos, mundo escurece nas bordas | ~3,6 s |
| 6 | ≤ 1 em 50.000 | CÓSMICO! / COSMIC! | vermelho-brasa para magenta | estrelas, anel de energia, HUD some, tremor suave | ~4,8 s |
| 7 | > 1 em 50.000 (Mística) | IMPOSSÍVEL! / IMPOSSIBLE! | preto cósmico com ciano e arco-íris | silhueta colossal, aura da cor da raridade, raio que atravessa a tela, onda de choque, "o mar prende a respiração" | 6 a 10 s |

Em todos: o contador **estoura** (escala 1,0 → 1,25 → 1,0) a cada tique; a palavra do degrau "bate" quando muda; o nome em branco ganha uma letra a cada degrau e fecha na revelação.

## 4. Orçamento, celular e acessibilidade

O vídeo é muito mais agressivo em flash e confete do que podemos ser (público infantil, celular fraco):

- **Máx. 3 pulsos de luz por segundo**, sem strobe, sem tela inteira branca. `ReduceEffects` troca flash e tremor por fade, mantém contador, palavra e cores.
- **Partículas:** teto de ~60 vivas ao mesmo tempo (confete em um único emissor reaproveitado), `Debris` em tudo; sem `BlurEffect`/`Bloom` permanentes. Aparelho só-toque corta pela metade.
- **Raios (sunburst):** uma imagem de raios ≤ 1024 px num `ImageLabel` girando (UI), não 3D.
- **Um `ViewportFrame` só**, com um modelo, reaproveitado entre silhueta e revelação.
- Layout **retrato primeiro** (576x1024 como régua); `UIAspectRatioConstraint`/`UISizeConstraint`, botões ≥ 44 px, nada sob o botão de pular nem a hotbar.
- **Pular** sempre (toque), e depois da primeira vez naquele degrau a contagem vai direto ao N final.
- **Tempo total de recompensa < 10% do jogo** (vault): por isso só o degrau 7 passa de 5 s.

## 5. Arte e áudio necessários

| Item | Quem | Observação |
|---|---|---|
| Textura de raios (sunburst) 1024 px, branca, para tingir | Antigravity ou gerada | uma só, tingida por degrau |
| Textura de confete (retângulos/estrelas) + estrela de brilho | Antigravity | sprite sheet 4x4, 1024 px |
| Anel d'água (ondas concêntricas) e anel de corda/luz do pouso | Codex (UI/Beam) | cor por faixa |
| Fonte e contorno grossos para a palavra do degrau | Codex (`UiTheme`) | FredokaOne já é a fonte do projeto |
| Sons: tique do contador (sobe de tom), "bum" por degrau, riser da Mística, chime do "PERFEITO!" | João / piloto SFXMint (`docs/SFX-PILOTO.md`) | sem asset de áudio a interface fica muda mas funciona |
| Silhuetas | as 106 criaturas atuais já servem (modelos em `ReplicatedStorage.Creatures`) | as 100 novas entram quando chegarem |

## 6. Fases

| Fase | Quem | Entrega | Depende de |
|---|---|---|---|
| V0 | João | Aprovar este plano (palavras, cores, tempos) | |
| V1 | Codex | Barra de força vertical/horizontal colorida, "PERFEITO!", rótulos e brilhos | contrato pronto |
| V2 | Codex | Cutscene do arremesso (vara, câmera, arco, anel d'água por faixa) | V1 |
| V3 | Codex | **Momento das chances**: contador que estoura, palavra do degrau, fundo e raios, confete, silhueta que cresce, nome letra por letra | `caught.odds` |
| V4 | Codex | Revelação final: nome colorido, variante/tamanho, "NOVA DESCOBERTA", taxa do aquário, "toque para continuar" | V3 |
| V5 | Codex + Claude | Degraus 6 e 7 (HUD some, raio, onda de choque), `ReduceEffects`, skip, orçamento de partículas | V3 |
| V6 | Codex | HUD do Poder de Pesca com contador que estoura e cores por patamar (já planejado) | contrato do treino |
| V7 | Todos | Play, celular, medir (MicroProfiler) e ajustar; liga as flags | V1 a V6 |

Claude entrega só ganchos de dados se o Codex pedir no Mural (por exemplo `oddsBucket` pronto no payload, ou `bestVariant`). Nada de servidor novo é necessário para V1 a V6.

## 7. Riscos

- **Flash e fadiga:** a referência é intensa; nossa versão é mais contida e desligável.
- **Tempo do ciclo:** pesca + barra + minigame + contagem + revelação. Só o degrau 7 passa de 5 s e é pulável.
- **Desempenho no celular fraco:** um emissor de confete, um viewport, uma imagem de raios; medir antes de liberar.
- **Cópia:** manter nome das palavras, paleta e layout nossos; nada de textura nem fonte do vídeo.
- **Dar a sensação de "caixa-surpresa":** sem compra nem re-roll ligados a esse momento; boost pago continua só em Rare+ e com número declarado.

## 8. Para o João decidir

1. As 7 palavras (SORTE, UAU, INSANO, IRREAL, DIVINO, CÓSMICO, IMPOSSÍVEL) e o **degrau 7 chegar a 10 s** (pulável).
2. Barra de força **vertical à direita** no celular (como no vídeo) e horizontal só no PC.
3. Nome **letra por letra** (revela a criatura aos poucos) ou só a silhueta até o fim?
4. Mostrar o "**SORTE x2,4**" fixo durante o arremesso?

Não testado: nada (planejamento). Referência analisada por 16 quadros do vídeo (sem áudio).
