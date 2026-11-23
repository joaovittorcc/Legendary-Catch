# Piloto SFXMint (22/11/2026)

SFXMint: biblioteca de efeitos sonoros **CC0** (domínio público, uso comercial, sem crédito), ~11.800 sons, WAV/MP3.
Os sons são gerados por IA ou sintetizados. Fonte: sfxmint.com e github.com/sfxmint/sfxmint-mcp.

## Limites do plano grátis (importante)
- Buscar e ouvir MP3: sem conta, 20 consultas por dia por rede.
- **Baixar arquivo: precisa de conta grátis + chave de API, 3 downloads por dia** (site e API somados).
  Mais que isso: pacotes pagos (US$ 4,99 por 50 sons, US$ 9,99 por 300). Eu não pago nem crio conta por você.
- Sem MCP instalado: usei só a busca REST (`/api/v1/search`), sem dados do projeto.

## Lacunas de áudio atuais (de `docs/AUDIO.md`)
Já temos: música, ondas, stingers por raridade, LevelUp, Coin, UiClick, HitGood/HitMiss, Chest, cast/bite.
Faltam sons dedicados para: riser antes do flash, impacto do flash, trovão, respingo, salto da criatura,
carretilha do Reel e brilho do acerto "PERFEITO".

## Lista de candidatos (nenhum baixado nem ouvido por mim)

| Uso no jogo | Gancho no código | Candidato | Página |
|---|---|---|---|
| Riser antes do flash lendário/místico | `Reveal.luau` `legendaryIntro` (antes de `Effects.flash`) | Synthetic Cinematic Riser 01 | sfxmint.com/sounds/transition-riser-01 |
| Impacto no flash | mesmo ponto, no `Effects.flash` | Layered Trailer Impact Boom 36 | sfxmint.com/sounds/transition-impact-hit-36 |
| Trovão do raio | `Effects.lightning` | Sharp Cracking Thunder Rumble 07 | sfxmint.com/sounds/ambience-thunder-07 |
| Respingo na água | `Effects.splash` | Small Water Splash 25 | sfxmint.com/sounds/water-splash-25 |
| Salto/chegada da criatura | `Reveal` (voo) | Fast Air Whoosh Transition 11 | sfxmint.com/sounds/transition-whoosh-11 |
| Carretilha do minigame Reel | `Minigames/Reel.luau` | Mechanical Fishing Reel Winding 01 | sfxmint.com/sounds/fishing-reel-winding-01 |
| Acerto "PERFEITO!" | `Ui.feedback` (perfect) | Bright Sparkle Success Chime 79 | sfxmint.com/sounds/ui-chime-79 |

Alternativas por item na própria busca (3 por consulta).

## Passos (João)
1. Ouvir os 7 candidatos no navegador (MP3, não conta no limite) e marcar os que servem.
2. Criar conta grátis no SFXMint e a chave (3 downloads por dia: dá pra fazer 3 sons por dia ou pagar um pacote).
3. Subir cada arquivo no Roblox (Asset Manager → Bulk Import; conta/grupo dono do jogo, para o áudio tocar no
   jogo publicado). Aguardar a moderação.
4. Me passar os asset ids: eu coloco em `ReplicatedStorage.Audio`/`Audio/init.luau` e ligo nos ganchos acima.
5. Guardar manifesto (fonte, licença CC0, URL da página, uploader, data) em `docs/AUDIO.md`, como o vault recomenda.

## Pontos de atenção
- Áudio no Roblox é privado por padrão: subir pela conta/grupo dono do experience, senão toca no Studio e fica mudo no jogo.
- Sons curtos de efeito (poucos segundos) são aceitos; confirme limites na página de áudio do Creator Hub antes de lote grande.
- Som de IA: CC0 pelo SFXMint, mas confira a política atual do Roblox sobre áudio gerado por IA antes de publicar.
- Respeitar `ReduceEffects` não vale para som; o volume vem dos grupos `Effects`/`Music` já ligados em Ajustes.

Alternativa sem ID de upload: continuar com os sons da Creator Store (Roblox/APM), que já tocam no jogo sem upload.
