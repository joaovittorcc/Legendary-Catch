# Revisão visual geral da pesca (24/11/2026)

Pedido do João: polir tudo o que entrou na pesca (barra, roleta, "1 em N", show da captura) olhando o que mais prende a atenção. Abaixo: o que prende, o que já foi feito nesta noite e o que falta, por dono.

## 1. O que prende a atenção (e como aparece no nosso ciclo)

| Princípio | Por que prende | Onde entra |
|---|---|---|
| **Antecipação antes do pagamento** | O cérebro gosta da espera curta antes da recompensa. Sem espera, a recompensa vale menos. | Vara puxada pra trás antes da barra; roleta freando; contador "1 em N" subindo |
| **Quase-ganhou (near miss)** | Parar "quase" no prêmio dá vontade de tentar de novo, mais do que perder longe. | Roleta parando na borda da carta boa e caindo no "Nada" |
| **Escalada por raridade** | Se tudo brilha, nada brilha. O raro só impressiona se o comum for simples. | Comum curto e limpo; Épico pra cima com flash, tremida, confete, cor |
| **Som em cada ação** | Som dobra a sensação de impacto; sem som o toque parece "morto". | Clique por gominho, por carta, por número; acerto/erro; "tchan" na revelação |
| **Números grandes subindo** | Ver um número crescer na hora é satisfatório e dá orgulho. | "1 em 14 milhões", "+44 moedas/min", Poder de Pesca |
| **Clareza no celular** | Se a pessoa não entende em meio segundo, ela larga. | Palavra gigante no centro (ÓTIMO!), cores fixas por faixa |
| **Ritmo** | A pesca comum é 80% das pescas: tem que ser rápida, ou cansa. | Show do comum sem bônus na metade do tempo; tocar acelera |
| **Momento "olha isso"** | Coisa rara e bonita vira print/vídeo e propaganda. | Revelação do Lendário/Místico, cutscene do lançamento |

## 2. Feito nesta noite (Claude)

- **Cutscene do lançamento** (`Fishing/CastCutscene.luau`): ao apertar para pescar, a câmera corta para um plano baixo e cinematográfico com barras pretas, o HUD sai, o personagem ergue a vara por cima do ombro e segura (tremendo de tensão). A barra de força aparece. No toque, a vara desce no arremesso e a câmera passa por trás do ombro seguindo a boia até a câmera de pesca assumir. Igual para todo resultado. O servidor começa a barra 0,6 s depois do toque (`Config.Fishing.AIM.windupSeconds`) e ignora toques antes disso. Vídeo: `art/preview/cutscene-lancamento-v2.mp4`.
- **Som** (nada disso tinha som):
  - Barra: clique suave a cada gominho, mais agudo conforme sobe (dá pra acertar pelo ouvido); som de acerto (verde/amarelo), de erro (vermelho/cinza) e de "subir de nível" no roxo.
  - Roleta: clique a cada carta que passa, "baú" no resultado grande, acerto no bom, erro no "Nada"/"Encolheu".
  - "1 em N": clique a cada número, cada vez mais agudo; estrondo ao entrar nas faixas INSANO! pra cima.
  - Revelação do peixe: "tchan" quando a silhueta vira peixe e moedas quando o número de moedas/min fecha.
  - Lançamento: "fuuu" lento ao puxar a vara e "vush" no arremesso.
- **Quase-ganhou na roleta**: resultado bom às vezes para na borda da carta anterior, treme e entra; "Nada" ao lado de uma carta boa às vezes passa um pouco da borda da carta boa e volta. Só o caminho muda, o resultado é sempre o do servidor. Vídeo: `art/preview/roleta-quase-som.mp4`.
- **Ritmo**: Comum/Incomum com roleta "Nada" anda a ~55% do tempo (show ~6 s em vez de ~10 s). Qualquer bônus mantém o show inteiro.
- **Treino por lagoa**: um ponto de treino pode ser só de Controle ou só de Instinto (atributo `TrainingStat`), para as lagoas do Foco e do Instinto das ilhas novas.

## 3. Falta (por dono)

### Codex (arquivos dele)
1. **Revelação 3D começando da mão** quando `info.fromShow == true` (o peixe já voou até a mão no show): hoje o `Reveal` refaz a entrada pela água. Pedido no Mural.
2. **Minigames com som e impacto**: clique por acerto, "parada" curta (hit-stop de 60 ms) no acerto perfeito, tremida pequena no erro. Os sons existem em `Audio` (`hit`, `miss`, `click`).
3. **Linha e boia**: rastro de luz da boia mais forte durante o arremesso (combina com a cutscene) e respingo maior ao cair.
4. **HUD do Poder de Pesca e painel do campo** (pendente desde o plano do treino).
5. **Coleção mostrando mutação e maior tamanho** (já está no plano da roleta, R4).

### Claude (próximos)
1. ~~Hit-stop na barra de força~~ (feito: 80 ms no verde e no roxo).
2. ~~Contador "1 em N" com câmera lenta~~ (feito: últimos 3 números mais lentos a partir de IRREAL!).
3. **Telemetria do ciclo**: tempo médio do lançamento à revelação por raridade, para calibrar o ritmo com dados reais.
4. **Servidor das ilhas novas**: o código já funciona com o contrato dos prompts do Antigravity (portais `training_1..4`, pontos `FocusSpot`/`InstinctSpot`). Conferir quando as ilhas estiverem montadas.

### Antigravity
- As 4 ilhas, igual às imagens escolhidas: `docs/prompts-antigravity/ILHA-CONSTRUIR-1..4-*.md` (um agente por ilha). O Claude não conseguiu abrir o Antigravity (o pedido de controle do computador foi negado), então os prompts estão prontos para colar.

## 4. Não testado

- Celular (toque, tamanho das barras pretas, desempenho).
- Dois jogadores ao mesmo tempo (a cutscene é só local, mas não foi visto com outro jogador perto).
- Personagem R6 (a pose foi ajustada para R15; o R6 usa outros nomes de juntas, que estão mapeados mas não foram vistos).
- Flags continuam **desligadas** no place (`FishingPower`, `FishingRoulette`, `TrainingPower`): a cutscene só aparece com `FishingPower` ligada.
