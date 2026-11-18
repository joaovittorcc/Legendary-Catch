# Como Criar Novas Criaturas (Legendary Catch)

Guia curto do fluxo padrão para adicionar novas criaturas em `ReplicatedStorage.Creatures` sem quebrar a revelação, o bestiário (`Collection`) ou a animação procedural (`CreatureMotion`).

---

## 1. Geração do modelo (`generate_mesh` ou montagem manual)

- Use `generate_mesh` no Studio com segmentação explícita (`partNames`):
  - **Obrigatórias / comuns:** `Body`, `Head`, `Tail`
  - **Opcionais por anatomia:** `FinL`, `FinR`, `Fins`, `Wings`, `Tentacles`, `Legs`, `Claws`, `Shell`, `Extra`
- **`Extra`:** qualquer detalhe fora dos nomes acima (olhos, gemas, coroas, fitas, partículas sólidas) deve se chamar `Extra`. O `CreatureMotion` anexa automaticamente `Extra` próximos de um membro (`Head`, `Wings`, `Tail`, `Shell`, etc.) ao mesmo pivô daquele membro para não descolar durante a revelação.

## 2. Hierarquia e propriedades obrigatórias

Todo `Model` deve ficar diretamente em `ReplicatedStorage.Creatures` com o **ID exato como nome** (ex.: `C101_Nome_da_Criatura`):

- `PrimaryPart`: `Body`
- **Filhos diretos:** apenas `BasePart`/`MeshPart` (sem sub-modelos aninhados, sem `Humanoid`, `AnimationController`, `Motor6D`, `WeldConstraint`, `RootPart`, `InitialPoses` ou `Script`).
- **Propriedades em todas as partes:**
  - `Anchored = true`
  - `CanCollide = false`
  - `CanQuery = false`
  - `CanTouch = false`
- **Escala (`GetBoundingBox` maior lado):**
  - `Common` / `Uncommon` / `Rare`: até `2.95` studs
  - `Epic`: `~3.0` – `3.2` studs
  - `Legendary` / `Mystic`: `~3.2` – `3.55` studs

## 3. Orientação padrão (`+Z` para frente)

A câmera de revelação, o `ViewportFrame` da Coleção e o `CreatureMotion` assumem:
- **Frente:** `+Z` (`Head.Position.Z - Tail.Position.Z > 0`)
- **Esquerda:** `+X` (`FinL.Position.X > FinR.Position.X`)
- **Topo:** `+Y`

Sempre valide via `execute_luau` em `Edit` antes de finalizar:
1. Gire se o modelo nascer olhando para `-Z` ou `+X`.
2. Ajuste `Body.PivotOffset` para alinhar o pivô no centro geométrico sem deslocar a pose.
3. Confira visualmente com `screen_capture` posicionando a câmera no eixo `+Z` olhando para a origem do modelo (salve print em `art/creatures/<ID>.png`).

## 4. Animação procedural (`CreatureMotion`)

- `src/client/Features/CreatureMotion/init.luau` anima automaticamente `Head`, `Tail`, `FinL`, `FinR`, `Fins`, `Wings`, `Tentacles`, `Legs`, `Claws`, `Shell` e `Extra`.
- Em `Play`, dispare uma revelação (ou chame `CreatureMotion.bind/pose`) para confirmar que nenhuma parte gira no eixo errado nem descola do `Body`/`Head`.

## 5. Registro e persistência na nuvem

1. **Dados do jogo** (coordenador / sistemas): cadastrar o ID em `src/shared/Config/Creatures.luau` (raridade, `revealStyle`, peso/valor) e nomes/lore em `src/shared/Strings.luau`.
2. **Place do Studio (Edit):** como os modelos em `ReplicatedStorage.Creatures` não vêm do Rojo, rode `save_place` logo após concluir o lote e confirme `persistedToCloud == true`.
