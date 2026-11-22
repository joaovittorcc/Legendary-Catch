# Frente 1 — Claude · sistemas e economia

[Plano principal](PLANO-AQUARIO-E-PESCA.md) · [Antigravity](PLANO-AQUARIO-ANTIGRAVITY.md) · [Codex](PLANO-AQUARIO-CODEX.md)

Entregar a economia que sustenta o ciclo **pescar → expor → receber moedas → comparar uma troca**. O servidor decide posse, taxa, compra, recompensa e raridade. Escopo de arquivos conforme [Coordenação](COORDENACAO.md): servidor, configuração e tipos compartilhados, contratos e controlador da pesca.

| Lote | Natureza | Dificuldade | Resultado |
|---|---|---|---|
| S0 | Auditoria, simulação e contrato | Muito alta | Tabelas do piloto e dados que o cliente pode integrar |
| S1 | Persistência e transações | Muito alta | Aquário inicial gerando renda e trocas validadas |
| S2 | Regras de progressão | Alta | Upgrades, sinergias, metas e prêmios |
| S3 | Balanceamento da pesca | Alta | Três minigames calibrados e eventos integrados |
| S4 | Telemetria e ativação | Alta | Lote verificável com recuperação e rollback |

## S0 — Entregar contrato e simulação

1. Medir duração e taxa de vitória por modo e tier. Levantar moedas por captura, varas, missões, códigos, presentes, prestígio, eventos e pesca automática. Registrar os gastos existentes e o saldo de veteranos.
2. Simular 5, 15 e 30 minutos e dias 1, 3, 7 e 14, com perfis iniciante, veterano, jogador rápido, azar e sorte alta. Cobrir tanque cheio de Gigantes Douradas e raridade alta cedo. Medir tempo até primeira expansão, produção por fonte, gasto e retorno de cada vaga.
3. Definir taxa por espécie, incluindo evento e Natal. Começar nas faixas do plano principal. Fatores iniciais de teste: Base ×1,00, Gigante ×1,30, Dourada ×1,60 e combinação ×1,90.
4. Publicar exemplos de perfil novo e migrado, captura, montagem, prévia e rejeição. O cliente precisa saber se os campos estão ausentes porque o perfil ainda carrega ou porque o recurso está desligado. Confirmar IDs de níveis e vagas com Antigravity.

## S1 — Perfil, renda e troca

- Separar histórico da Coleção de quantidades por espécie e combinação de variante. Preservar saldo, recordes e progressão. Decidir com João como mapear Cintilantes antigas. Peso recorde pode mostrar um recorde histórico, mas é insuficiente para reconstruir quantidade de Gigantes ou combinações. Marcar versão da migração e verificar que uma segunda execução resulta no mesmo estado.
- Começar com três vagas do tanque inicial e a escalação vazia. Validar ID, nível do tanque, posse, quantidade disponível, vaga e versão esperada. Permitir colocar, trocar e retirar. Manter os resultados autoritativos mesmo com cliques repetidos e respostas fora de ordem.
- Prévia contém ocupante anterior, novo ocupante, taxa de cada um, total anterior e novo, diferenças de sinergia e versão que a confirmação deve usar. Ao rejeitar por conflito, retornar o estado atual para uma nova prévia.
- Contabilizar em centésimos e preservar resto. Liquidar usando taxa anterior até o instante de troca. Agendar pagamentos online em lote. Salvar saldo, cursor e fração juntos no perfil. A primeira ativação estabelece um novo cursor. Renda offline fica desligada no piloto.
- Captura registra espécie e variante e continua enviando a recompensa imediata quando aplicável. Enviar a taxa potencial separadamente. Inicializar a taxa de renda do aquário em campo próprio. Evitar uma segunda concessão de moeda ao repetir a mesma operação.

**Aceite:** do zero, pescar, ocupar vaga, receber renda, trocar e ver o próximo pagamento usar a taxa certa. Repetir com perfil veterano, vaga cheia, variante indisponível, confirmação concorrente e reconexão.

## S2 — Crescer e completar conjuntos

- Associar nível do aquário, capacidade, custo e condição de compra aos IDs entregues pelo Antigravity. Começar com 3/5/8/12 vagas como hipótese. Preservar ocupantes ao expandir e cobrar uma vez.
- Sinergia conta espécies distintas e afeta participantes. Piloto com 2 espécies dando +5%, 3 dando +10%. Usar o maior bônus elegível por vaga com teto de +10%.
- Metas de renda registram a maior taxa confirmada e guardam resgate por ID. Priorizar recompensas cosméticas. Para metas de sessão, publicar requisito, prêmio e progresso; definir validade para reentrada.
- Entregar ao Codex progresso de metas, bônus ativos, próxima faixa de renda e situação de compra. Entregar ao Antigravity IDs dos prêmios e critérios de desbloqueio da decoração.

## S3 — Pesca, eventos e efeitos na economia

- Calibrar Reel, Precision e Rhythm com a medição do Codex. Comparar PC e toque, perfis novos e tiers extremos. Reusar Controle, bônus de vara e limites do tutorial.
- Preservar seleção de criatura no servidor. Publicar raridade verdadeira no momento autorizado do fluxo para o cliente pintar boia, água e linha. Definir o que acontece com uma captura em andamento quando o evento termina.
- Revisar evolução do combo, pesca automática, prêmio por sessão e acúmulo com prestígio/eventos. Usar os tetos existentes até o balanceamento justificar ajuste.
- Publicar estado, término e disponibilidade de cada evento. Alinhar com Antigravity/Codex se o portal é cenografia ou entrada de zona.

## S4 — Verificação e ativação

Cobrir migração repetida, saldo insuficiente, resgate duplicado, reentrada imediata, saída inesperada, versão antiga do cliente e troca de taxa entre dois ticks. Telemetria separa renda, captura e outras fontes. Preparar flags para crédito, UI e offline, com recuperação que preserve progresso. Depois da simulação, levar ao João a proposta de offline com fração e limite de tempo. Registrar parâmetros, evidências e decisões no Mural.
