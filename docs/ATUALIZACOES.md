# Plano de Atualizações Semanais — Primeiros 2 Meses (8 Semanas)

Calendário para manter retenção após o lançamento de **Legendary Catch**, usando o sistema existente de criaturas (`ReplicatedStorage.Creatures` + `Config/Creatures.luau`), eventos (`Config/Events.luau`), varas (`Config/Rods.luau`) e códigos (`Config/Codes.luau`). Veja também [CRIATURAS-NOVAS.md](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/docs/CRIATURAS-NOVAS.md).

---

## Mês 1 — Consolidação e Primeiras Expansões

### Semana 1: Patch de Lançamento + Ajustes pelos Dados (`Analytics`)
- **Foco:** estabilidade mobile, ritmo inicial (`firstCast` → `firstCatch` → `firstRodBought`) e economia.
- **Ações:**
  - Analisar o funil `Analytics.STEPS` (índices 1–13) no Creator Hub para identificar onde novos jogadores param.
  - Ajustar preços/bônus das varas intermediárias (`Rods.luau`) ou dificuldade dos tiers 1–2 se houver queda na 1ª captura.
  - Código comemorativo de lançamento em `Codes.luau` (ex.: `LANCAMENTO` / `MAR100K`).

### Semana 2: Evento "Maré de Corais" + 4 Novas Criaturas
- **Criaturas (`C101–C104`):** 1 Comum, 1 Incomum, 1 Rara, 1 Épica exclusivas de evento (tema recife fluorescente).
- **Evento (`Events.luau`):** novo evento `coralBloom` (`+rarityBoost` para `Rare`/`Epic`, `valueMultiplier = 1.35`, partículas rosa/ciano na superfície).
- **Código semanal** + banner curto com link para `thumb-1-island`.

### Semana 3: Expansão da Oficina (2 Novas Varas) + Conquistas
- **Varas (`Rods.luau`):**
  - Vara intermediária temática da lagoa (ponte entre `crystal` e `storm` para suavizar a curva de médio jogo).
  - Vara avançada focada em **Controle** (facilita minigames de `precision` e `rhythm` de Tier 5–6).
- **Conquistas & Marcos:** adicionar 2–3 novas metas de cintilantes e sequência diária (`streak`).

### Semana 4: Mini-Área no Mapa — "Rocha do Farol"
- **Mapa:** adicionar uma pequena plataforma/rocha acessível por pontezinha ao lado do píer principal com uma nova `FishingZone` temática (águas profundas, vista para o horizonte).
- **Criaturas (`C105–C108`):** 2 Raras, 1 Épica e 1 nova **Lendária** temática de farol/abismo.
- **Visual:** lanterna giratória leve no farol respeitando `ReduceEffects`.

---

## Mês 2 — Sazonalidade, Social e Endgame

### Semana 5: Evento Sazonal — "Festival das Lanternas Marinhas"
- **Mapa / Clima:** decoração temporária de lanternas flutuantes ao redor da ilha + tom dourado suave ao entardecer (`LivingWorld`).
- **Evento (`Events.luau`):** `lanternFestival` (bônus para criaturas luminosas e maior chance de variantes **Cintilantes** durante o evento).
- **Criaturas (`C109–C111`):** 1 Incomum, 1 Rara e 1 Épica festiva.

### Semana 6: Semana dos Colecionadores (Prestígio & Bestiário)
- **Endgame (`Prestige.luau`):** revisar feedback de `firstPrestige` e ampliar recompensas visuais/títulos de `Maré Nova` (ex.: aura sutil na vara equipada por nível de Prestígio).
- **Criaturas (`C112–C114`):** 2 Épicas + **1 nova Mística (`C114`)** para reaquecer a caça dos jogadores de alto nível.

### Semana 7: Competição Amigável no Píer ("Hora do Troféu")
- **Gameplay / Eventos:** mini-evento recorrente focado em **peso recorde** (`Golden Hour` turbinado com bônus de XP na Jornada e +chance de Gigantes).
- **Social:** destaque maior nos anúncios de captura Gigante/Cintilante e inspeção rápida pelo Placar.

### Semana 8: Grande Update do Mês 2 — "Ilhota de Cristal" + Lote de 6 Criaturas
- **Mapa:** pequena ilhota secundária ligada por pedras/ponte curta atrás da árvore rosa, com cristais maiores e segunda zona de pesca.
- **Criaturas (`C115–C120`):** lote completo (1 Comum, 1 Incomum, 2 Raras, 1 Épica, 1 Lendária) fechando **120 espécies** no catálogo!
- **Evento & Código:** evento especial de fim de mês + código `MARÉ120` e atualização das thumbnails na página do Roblox para refletir a nova ilhota.

---

## Checklist padrão de cada update semanal

1. Gerar/validar criaturas conforme [CRIATURAS-NOVAS.md](file:///c:/Users/Evojota/dev/jogo%20ainda%20sem%20nome/docs/CRIATURAS-NOVAS.md) (`+Z`, partes limpas, `save_place`).
2. Testar novos pesos/preços sem inflacionar moedas iniciais.
3. Atualizar `Strings.luau` e `StringsUi.luau` (PT-BR + EN-US).
4. Rodar `stylua`, `selene` e teste rápido no `Play` (PC + mobile viewport) antes de publicar o patch.
