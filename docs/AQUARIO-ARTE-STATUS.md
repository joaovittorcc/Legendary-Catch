# Aquário — status da frente de arte (revisão do plano do Antigravity)

[Plano Antigravity](PLANO-AQUARIO-ANTIGRAVITY.md) · [Contrato](AQUARIO-CONTRATO.md)

Revisado em 2026-11-22 por Claude a pedido do João (o Antigravity parou após erros em A3). Auditoria feita **no Studio aberto** (Edit, sem Play). **Atenção:** o trabalho abaixo existe só na sessão aberta do Studio. O salvamento na nuvem falhou duas vezes (`Http Error: NetFail` / `Timedout`). Salve com Ctrl+S quando a conexão voltar, ou ele se perde ao fechar o Studio.

## Situação por lote

| Lote | Estado | Evidência / o que falta |
|---|---|---|
| **A0** tanque inicial e hub | **Concluído agora** | Berçário instalado no hub em `Workspace.Island.AquariumNursery` (deck de madeira com estacas sobre o barranco/lagoinha a sudoeste da escadaria, passarela até a praça). Ponto de interação `AquariumSpot` (tag) com prompt `OpenAquarium` criado pelo servidor. Vistas empty/filled/Gigante existem como vitrine. Faltou: Play para testar o prompt e andar até lá. |
| **A1** quatro níveis + props | **Concluído** (pelo Antigravity) | Níveis `aquarium_lv1..4` com atributos `LevelId`/`Capacity`/`LevelIndex`, 3/5/8/12 vagas (`Slot_NN`), âncoras completas (InteractPoint, InspectCamera, OverviewCamera, BoardAnchor, SwimVolume, SwimVolumeLarge, DecorAnchor_01..07), camadas por nível (`Layer_01..05`), variantes Base/Gigante/Dourada/Gigante+Dourada com placa de taxa, 8 props de decoração. Auditoria: 75–237 partes por nível, 2–5 emissores, 1–2 luzes, sem MeshPart: leve. |
| **A2** eventos | **Coberto por código** | O arco do evento é montado no cliente pelo Codex (`Events/Scenery`) no marcador `OceanEventSceneryAnchor` do píer; é cenografia, sem teletransporte (decisão em `PESCA-S3.md`). O Antigravity não entregou peças 3D próprias: não bloqueia nada, é polimento. |
| **A3** 18 cenas Lendárias | **Bloqueado em você** | Receitas por ID das 18 e pilotos C23/C24/C64 existem no cliente (Codex). Falta o que depende dos **vídeos de referência que só o João tem**: marcas de tempo, câmera e pose por cena, e validação no Studio. Sem os vídeos não dá para fechar a arte; não inventei. |
| **A4** revisão visual | **Parcial** | Contagem de peças/partículas/luzes feita (acima, leve). Falta olhar a galeria cheia em celular, Gigante em cada nível e custo de VFX em Play. |

## O que eu fiz agora

1. Instalei o Berçário no hub (clone do modelo do Antigravity, deck, passarela, estacas), `ModelStreamingMode = Persistent` (o mapa usa StreamingEnabled), tag `AquariumTank` no modelo e `AquariumSpot` no ponto de interação.
2. Criei `ReplicatedStorage.AquariumLevels` (`Levels`, `Decor`, `Variants`) para o cliente trocar de nível; a vitrine pesada saiu do mundo e está em `ServerStorage.AquariumShowcase`.
3. Servidor: prompt `OpenAquarium` nas peças `AquariumSpot` (mesmo padrão da Oficina), textos PT/EN em `Strings`.
4. Renomeei as 4 paredes de fundo sem nome da vitrine (`ShowcaseBackdrop_N`).

## Pendências reais

- **Salvar o place** (falhou por rede).
- **Codex:** abrir a visão do aquário ao disparar o prompt `OpenAquarium`, trocar o modelo por `AquariumLevels.Levels[levelId]` no upgrade (contrato §9) e traduzir o prompt em `WorldText` (nome `OpenAquarium`).
- **Cosméticos `aqdeco_*`:** mapear placa/luminária aos `DecorAnchor_01/02`; coral, fonte, moldura e troféu usam os props de `AquariumLevels.Decor` (`decor_crystal_coral`, `decor_bubble_fountain`, `decor_golden_frame`, `decor_astral_obelisk`), mas faltam âncoras próprias.
- **Play:** andar até o aquário, abrir o prompt, ver o tanque cheio no celular.
- **João:** vídeos das 18 Lendárias para fechar A3.
