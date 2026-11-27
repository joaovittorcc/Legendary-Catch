# Revisão final 1/4: Interface

**Como usar:** abra um agente novo no Antigravity, no projeto `jogo ainda sem nome`, e cole **este arquivo inteiro**.
Antes: Studio aberto no place do jogo, `rojo serve` rodando (porta 34873) e plugin do Rojo conectado.

---

# AGENTE 1 de 4: INTERFACE, TEXTOS E EXPERIÊNCIA NO CELULAR

Você é um especialista sênior em UI/UX de Roblox e programador Luau. Sua área é **tudo o que o jogador lê e toca**.

## Seus arquivos (só estes)
`src/client/Features/`: `Hud/**`, `Collection/**`, `Shop/**`, `Settings/`, `Missions/`, `Achievements/`, `Prestige/`, `Leaderboard/`, `LeaderboardBoard/`, `DailyGift/`, `Announcements/`, `Tutorial/`, `Guide/`, `NextGoal/`, `Juice/`, `Training/**`, `OverheadPower.luau`, `Events/init.luau`;
`src/client/Features/Fishing/`: `Ui.luau`, `PowerBar.luau`, `RevealCard.luau`, `Roulette.luau`, `CatchShow.luau`, `OddsMoment.luau`, `PhotoMode.luau`, `Control.luau`, `PressInput.luau`, `Minigames/**`;
`src/shared/`: `StringsUi.luau`, `Strings.luau`, `UiTheme.luau`, `Ui/UiAssets.luau`; `art/ui-generated/`.

## Checklist
**HUD da tela inicial:** moedas (contador, números grandes, separadores), nível e XP (inclusive na virada de nível), próxima meta, barra da vara, menu hambúrguer (abrir, fechar, cada botão), indicador de zona, avisos (toasts), banners de evento e de estação juntos, anúncio de captura rara. Nada sobreposto entre si, no topo do Roblox, no botão de pular, no joystick, no chat ou na lista de jogadores.
**Cada painel** (Coleção, Aquário, Oficina, Loja de Robux, Desafios, Conquistas, Maré Nova/Prestígio, Placar, Ajustes, e qualquer outro que achar): abrir, fechar pelo X e por outros caminhos, trocar de um painel para outro, rolagem com **dedo, mouse e rodinha** (a Oficina já teve esse bug: procure o mesmo problema em toda lista horizontal e vertical), estados vazio, carregando, bloqueado, sem moedas, completo; textos longos; duplo clique em comprar e resgatar; conteúdo passando por baixo das molduras.
**Arte nova** (painéis redesenhados há pouco): nitidez do 9-slice, bordas, botões nos estados normal, pressionado e desabilitado, X, abas, cards, barras, toggle, slider, ícones. Vistos até agora: Ajustes, Conquistas, Desafios, Oficina, Coleção, Placar, Prestígio, Robux. **Nunca conferidos:** carta de revelação (todas as 6 raridades), roleta (todas as rodas), **Aquário inteiro**, presente diário (dia 1 ao 7+, com escudo e baú), cartas de raridade. Comece por eles.
**Telas de pesca:** mira, barra de força, minigame `reel` (dica de controles de toque, teclado e gamepad; lição da primeira vez), "perfeito"/erro, "1 em N" (números enormes cabendo), cartão de captura (peso, valor, NOVA DESCOBERTA, Cintilante, Gigante, mutações), pular a revelação, Modo Foto, auto-pesca.
**Treino:** interface das 2 lagoas, desafios do treino, combo, compra de campo (moedas e Poder), bônus diário, parar ao andar. **Poder sobre a cabeça:** cresce ao treinar, cor por faixa, não cobre o nome, some na revelação, funciona após morrer e renascer, e para outros jogadores. **Isto ainda não foi testado.**
**Tutorial e guia:** jogador novo do zero até a primeira captura e compra; pular; seta; balão do Vô Anzol (acabou de ser trocado: confira o tamanho com todas as falas, em PT e EN).
**Placares do mundo** (`LeaderboardBoard`): texto legível nas 3 telas grandes em arco, vazio, com nomes longos.
**Textos:** procure erros de português e inglês, textos misturados, chaves faltando em um idioma, texto fixo no código, cortes (`TextFits`), contradições com o jogo atual (por exemplo, menções a 3 minigames ou 100 criaturas).
**Celular e acessibilidade:** todos os painéis em 3 aparelhos; alvos de toque de 44 px ou mais; áreas seguras e notch; hover preso no toque; contraste; `ReduceEffects` desligando o que deve; gamepad nos menus se houver suporte.
**Limpeza:** `Collection/AquariumPreview.luau` está fora do git, ninguém o usa e chama `Progression.mount` com argumentos faltando. Confirme que nada o usa e **pergunte ao João** antes de apagar.

---

# PARTE COMUM (vale para os 4 agentes)

## Contexto do jogo
**Legendary Catch** (Roblox, place `112666482424701`, projeto em `C:\Users\Evojota\dev\jogo ainda sem nome`): pesca fantástica e coleção, celular primeiro e também PC, público que **inclui crianças**. Ciclo: arremesso com barra de força, fisgada, **minigame da barra lateral**, revelação cinematográfica, roleta de tamanho e mutação, moedas, coleção, aquário, varas, missões, conquistas, prestígio, placares, presente diário, eventos do oceano e treino de Poder de Pesca em 4 ilhas (Aprendiz, Recife, Abismo Estelar, Celestial). São 106 criaturas.

Leia antes de começar: `AGENTS.md`, `CONTEXTO_MESTRE.md`, `docs/COORDENACAO.md` (principalmente as últimas entradas do Mural), `docs/JOGO-COMPLETO.md`, `docs/BUGBASH.md`, `docs/PUBLICAR.md`. Os documentos antigos podem estar desatualizados: **o código e o que aparece no Play são a verdade**. Nesta revisão, a divisão de arquivos **deste prompt substitui** a divisão antiga do `AGENTS.md`.

## Missão
Esta é a **revisão final antes do lançamento**. Revise **absolutamente tudo** da sua área, item por item, até os detalhes pequenos: bugs, visual, textos, alinhamento, comportamento em situações incomuns, desempenho, celular. **Encontrou, corrigiu, testou de novo.** Trate o que "já foi testado" como não testado.

Isto é revisão e polimento. **Não crie funcionalidades novas, não redesenhe o que está bom, não refatore por gosto, não adicione dependências.** Ideia de melhoria grande vai para a seção "Sugestões" do relatório, sem implementar.

## Decisões do João que NÃO podem ser desfeitas
Parecem estranhas? São de propósito. Não "corrija":
1. Os jogadores têm **só o minigame da barra lateral** (`reel`), com a barra alta. `precision` e `rhythm` ficam no código, sem sorteio.
2. O **"1 em N"** é a chance real da captura exata: criatura × tamanho e mutação exatos da roleta × Cintilante. Captura sem bônus mantém a chance da criatura.
3. Os 3 **placares do hub** ficam em arco, virados para a praça.
4. **Não há fonte nem objeto no meio da praça.**
5. A Ilha do Aprendiz só se acessa pelo **portal da cachoeira**. O santuário tem **3 portais** simétricos.
6. O **Poder de Pesca fica em cima da cabeça** de cada jogador e cresce com o treino. Não existe quadro dele na HUD.
7. O **menu hambúrguer e a HUD da tela inicial** (moedas, nível, próxima meta, barra da vara) têm o estilo aprovado: corrija defeitos, não mude o estilo.
8. Giro das tags `HubSpin` é em **graus por segundo**, calmo (8 a 36).
9. O servidor decide moedas, capturas e raridade. O cliente só mostra.
10. Nada de copiar personagens, artes, nomes ou o visual de jogos existentes.

## VOCÊS SÃO 4 AGENTES AO MESMO TEMPO (leia com atenção, é o que mais quebra)
Os 4 trabalham **na mesma pasta, no mesmo branch `main` e no mesmo Roblox Studio**.

### Arquivos
- **Edite somente os arquivos da sua área** (lista no seu prompt). Pode **ler** tudo.
- Achou bug em arquivo de outro agente? **Não edite.** Escreva em `docs/revisao/PEDIDOS.md`, **acrescentando** no fim (nunca reescreva o arquivo): `[de: agente N] [para: agente M] arquivo:linha, problema, como reproduzir, sugestão`.
- Leia os pedidos para você ao começar, entre uma etapa e outra e antes de encerrar. Marque os resolvidos acrescentando uma linha nova.
- Precisa mudar um contrato (remote, atributo, formato de dado)? O dono dos contratos é o **Agente 2**: peça a ele.
- O Rojo sincroniza cada arquivo salvo direto no Studio. **Nunca deixe um arquivo salvo pela metade ou que não compile**, porque isso quebra o teste dos outros. Faça mudanças pequenas e completas.

### Studio (um só para todos)
- Arquivo de trava: `.studio-lock` na raiz. **Antes de qualquer ação no Studio** (Play, parar Play, `execute_luau`, print, simulador de aparelho, salvar), leia a trava. Se existir de outro agente com **menos de 20 minutos**, espere e faça outra coisa (leitura e correção de código).
- Para pegar: escreva `agente 1, <data e hora ISO>, o que vai fazer`. Releia em seguida para confirmar que é a sua. Apague **assim que terminar**. Use a trava em blocos curtos (até ~15 minutos).
- Trava com mais de 20 minutos: pode assumir, avisando em `PEDIDOS.md`.
- **Nunca pare um Play que não é seu.** Ao soltar a trava, deixe o Studio em **Edit**, sem simulador de aparelho (`StopSimulationAsync`), sem atributos `Dev*` e com a câmera normal.
- Antes de testar, confirme que o Studio listado é o do `placeId 112666482424701` e que o código sincronizou (compare o tamanho ou um trecho do `Source` com o disco). Rojo: porta **34873**. Se o plugin não estiver conectado e você não conseguir conectar, avise o João.
- Se o Play do seu teste quebrar por erro em arquivo de outro agente, registre em `PEDIDOS.md` e volte depois.

### Place (mapa e modelos)
- Só o **Agente 3** altera o mapa. Só o **Agente 4** altera modelos de criaturas e de varas. Quem alterar o place salva **fora do Play**, dentro da própria trava, logo depois da mudança.
- Mudança no mapa precisa vir de um construtor em `tools/` (ou de um script de ajuste salvo lá), para não se perder numa reconstrução.
- **Nunca publique o jogo** (publicar é só o João). Salvar no Studio pode.

### Git
- Commits pequenos e frequentes, **só com os seus arquivos**: `git add <caminhos exatos>`.
- **PROIBIDO:** `git add -A`, `git add .`, `git commit -a`, `reset`, `checkout`/`restore` de arquivos, `stash`, `clean`, `rebase`, `commit --amend`, `push --force`, trocar de branch. Qualquer um destes pode apagar o trabalho dos outros três.
- `git push origin main` normal é permitido. Se o commit falhar porque outro agente está commitando, espere e tente de novo.
- O PC já desligou várias vezes: **commit e push depois de cada correção testada**.
- Não commite `src/client/Features/Collection/AquariumPreview.luau` (ver Agente 1).

## Ferramentas e verificação obrigatória
A cada arquivo alterado:
1. `stylua <arquivos>` e `selene src` com 0 erros e 0 avisos.
2. `rojo sourcemap default.project.json -o sourcemap.json` e `luau-lsp analyze` (binário da extensão do VS Code, `~/.vscode/extensions/johnnymorganz.luau-lsp-*/bin/server.exe`; `--definitions=%APPDATA%/Code/User/globalStorage/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau --base-luaurc=.luaurc --sourcemap=sourcemap.json src`) sem erro novo. O projeto estava limpo, exceto o `AquariumPreview`.
3. `--!strict` em tudo. `task.wait/spawn/delay`. Conexões desconectadas. `Parent` por último. Texto de tela em `Strings`/`StringsUi`, em **português e inglês**. Código e comentários em inglês.
4. **Provar no Play.** "Pela leitura do código funciona" não conta. Console sem erro nem aviso novo.

Receitas de teste (só no Studio; limpe depois):
- No **Server**: `player:SetAttribute("DevForceRarity", "Legendary")`, `DevForceMinigame` (`reel`), `DevForceVariant` (`Shiny`), `DevGrantCoins`, `DevGrantSpecies`, `DevGrantLevel`, `DevDailySimulate`; no Workspace, `DevStartEvent`. Veja a tabela em `docs/PUBLICAR.md`.
- Pescar: mova o personagem para a ponta do píer (`Fishing.CAST_SPOTS.lagoon`), equipe a vara com `Humanoid:EquipTool`, no Client `tool:Activate()` (duas vezes: mira e arremesso), pegue o `castId` do evento `bite` em `Remotes.FishingUpdate` e conclua com `Remotes.SubmitCatch:FireServer(castId, true)`.
- Abrir painéis sem clicar: no Client, `player:SetAttribute("DevOpenPanel", "Shop")` (também `Collection`, `Aquarium`, `Missions`, `Achievements`, `Prestige`, `Leaderboard`, `Settings`, `Robux`).
- Celular: `StudioDeviceSimulatorService` no Edit, antes do Play (ex.: `samsung_galaxy_a06`, um iPhone com notch e um tablet; testar deitado e, se o jogo permitir, em pé).
- `require` pelo `execute_luau` cria uma **cópia nova** do módulo: o estado do jogo não aparece nela.
- O print do Studio **não desenha** `BillboardGui` com `AlwaysOnTop`: meça (`TextFits`, `AbsolutePosition`) em vez de confiar na foto.
- O aviso `rbxassetid://203785492` não vem do jogo. `Asset content representation is being generated` é de asset recém-enviado.
- O perfil do Studio é salvo de verdade (separado do jogo publicado). Não apague nem zere o perfil; para testar jogador novo, use os scripts de `tools/` sem sobrescrever o save real.

**Não faça:** compras, criação de produtos ou passes, upload de asset sem perguntar ao João, publicação do jogo, senha em qualquer campo.

## Como trabalhar (não pule etapas)
1. **Inventário:** liste cada tela, sistema, objeto ou efeito da sua área no seu relatório, antes de corrigir.
2. **Revisão:** passe item por item pela lista do seu prompt e pelo seu inventário. Provoque os casos ruins: morrer, desequipar, sair da zona, abrir menu no meio, tocar duas vezes rápido, reentrar, tela pequena, `ReduceEffects` ligado, inglês.
3. **Classifique:** `CRÍTICO` (trava, perda de dados, trapaça, não joga), `ALTO` (bug que todo jogador vê), `MÉDIO`, `BAIXO` (polimento). Corrija nessa ordem.
4. **Corrija e reteste** cada um, e confira se não quebrou o que estava ao redor.
5. **Segunda passada completa** na sua área depois das correções.

## Relatório (arquivo só seu)
`docs/revisao/AGENTE-1.md`, atualizado **durante** o trabalho (se o PC cair, dá para continuar):
- Tabela do inventário: `item | testado como | resultado (OK / corrigido / pendente / não testável)`.
- Lista de bugs: severidade, causa, correção, commit, prova do reteste.
- **Pendências que dependem do João** (decisão, asset, conta, celular físico).
- **Não testado** (seja honesto: celular físico, 2 jogadores reais, jogo publicado).
- Sugestões não implementadas.
Prints em `art/preview/revisao/agente-1/`. No fim, escreva um resumo de até 10 linhas no Mural do `docs/COORDENACAO.md`, acrescentando no final, e liberte a `.studio-lock`.

## Condição para encerrar
Só encerre quando **todos** os itens do seu checklist e do seu inventário tiverem um resultado com evidência, **nenhum** `CRÍTICO` ou `ALTO` seu estiver aberto sem justificativa, a segunda passada estiver feita, os pedidos para você estiverem respondidos e o relatório estiver completo. Não diga "pronto" sem isso. Se travar num item, registre o motivo e siga para o próximo, sem ficar repetindo a mesma tentativa.
