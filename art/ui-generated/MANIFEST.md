# Legendary Catch — UI Generated Assets Manifest

All assets in this folder are **transparent RGBA PNGs**, `<= 512 px` (well under Roblox's `1024 px` downscale limit), with **no embedded text**, matching the glossy 3D cartoon candy style of `art/hud-v2/botao-*.png` and `art/hud-v2/painel.png` (thick dark plum outline `#2C0A4D`, vivid saturated gradients, curved white top specular highlights, golden inner moldings, and chunky 3D bottom bevels).

> **9-Slice Guarantee:** Every `Slice` asset keeps all curved corner specular highlights strictly outside its `SliceCenter` stretch band, so stretching on both mobile (`360×640`) and desktop (`1920×1080`) produces zero corner distortion or seams.

---

## Stage 1 — Base UI Kit (`A.1` – `A.3`, 47 PNGs)

### A.1 — 9-Slice Panel Frames (7 themes × 2 = 14 PNGs)

Theme mapping (used for panel frame, floating header ribbon, and primary accent):

| Theme | Screen (PT-BR) | Body File | Header File |
| :--- | :--- | :--- | :--- |
| `cyan` | Coleção | `panel_body_cyan.png` | `panel_header_cyan.png` |
| `orange` | Oficina | `panel_body_orange.png` | `panel_header_orange.png` |
| `lime` | Desafios | `panel_body_lime.png` | `panel_header_lime.png` |
| `gold` | Conquistas | `panel_body_gold.png` | `panel_header_gold.png` |
| `purple` | Maré Nova | `panel_body_purple.png` | `panel_header_purple.png` |
| `pink` | Placar | `panel_body_pink.png` | `panel_header_pink.png` |
| `steel` | Ajustes | `panel_body_steel.png` | `panel_header_steel.png` |

Exact Roblox `ImageLabel` properties:

| Pattern | Size (px) | `ScaleType` | `SliceCenter` | Recommended `SliceScale` | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `panel_body_*.png` | `512 × 512` | `Enum.ScaleType.Slice` | `Rect.new(128, 128, 384, 384)` | `0.50` – `0.60` | Plump glossy colored outer tube + shiny gold inner molding + warm cream `#FFF8E6` interior for dark-ink legibility. Content padding inset ≈ `42px` at `SliceScale = 0.55`. |
| `panel_header_*.png` | `512 × 128` | `Enum.ScaleType.Slice` | `Rect.new(96, 48, 416, 80)` | `0.50` – `0.60` | Floating pill title banner with subtle gold lower collar; sits centered along the top edge of `panel_body_*`. |

---

### A.2 — Plump 9-Slice Buttons (5 colors × 3 states = 15 PNGs)

Colors: `green` (confirm / claim / equip), `blue` (info / secondary), `orange` (buy / craft / upgrade), `pink` (event / highlight), `red` (close / cancel / destructive).
States: `normal`, `pressed` (physically shifted down `+7px` inside the same canvas so swapping images gives tactile press with zero layout shift), `disabled` (muted lavender-slate with subtle color tint).

| File | Size (px) | `ScaleType` | `SliceCenter` | Recommended `SliceScale` |
| :--- | :--- | :--- | :--- | :--- |
| `btn_green_normal.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_green_pressed.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_green_disabled.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_blue_normal.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_blue_pressed.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_blue_disabled.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_orange_normal.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_orange_pressed.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_orange_disabled.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_pink_normal.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_pink_pressed.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_pink_disabled.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_red_normal.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_red_pressed.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |
| `btn_red_disabled.png` | `256 × 128` | `Slice` | `Rect.new(72, 48, 184, 80)` | `0.50` – `0.60` |

---

### A.3 — Controls, Tabs, Cards, Progress Bars, Toggles, Sliders & Badge (18 PNGs)

| File | Size (px) | `ScaleType` | `SliceCenter` | Recommended `SliceScale` | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `btn_close_x.png` | `192 × 192` | `Fit` | — | — | Glossy red circular close button with chunky outlined white `X` (`>= 44×44 px` touch target). |
| `btn_close_x_pressed.png` | `192 × 192` | `Fit` | — | — | Pressed state for `btn_close_x.png` (shifted down `+6px`). |
| `tab_active.png` | `256 × 128` | `Slice` | `Rect.new(68, 48, 188, 80)` | `0.50` – `0.55` | Radiant sunny-gold active tab pill (high contrast on all 7 panel themes). |
| `tab_inactive.png` | `256 × 128` | `Slice` | `Rect.new(68, 48, 188, 80)` | `0.50` – `0.55` | Soft creamy-lavender unselected tab pill. |
| `card_normal.png` | `256 × 256` | `Slice` | `Rect.new(64, 64, 192, 192)` | `0.45` – `0.55` | Standard item / creature / quest card on warm ivory cream with 3D honey lip. |
| `card_selected.png` | `256 × 256` | `Slice` | `Rect.new(64, 64, 192, 192)` | `0.45` – `0.55` | Selected / equipped / highlighted card with glowing golden candy rim. |
| `card_locked.png` | `256 × 256` | `Slice` | `Rect.new(64, 64, 192, 192)` | `0.45` – `0.55` | Locked / undiscovered card in cool muted periwinkle-slate. |
| `progress_track.png` | `256 × 64` | `Slice` | `Rect.new(44, 24, 212, 40)` | `0.55` – `0.65` | Recessed dark-indigo groove framed with shiny gold bezel (matches `barra-progresso.png`). |
| `progress_fill.png` | `256 × 64` | `Slice` | `Rect.new(36, 20, 220, 44)` | `0.55` – `0.65` | Juicy glossy emerald-lime fill bar (default / challenges / quests). |
| `progress_fill_gold.png` | `256 × 64` | `Slice` | `Rect.new(36, 20, 220, 44)` | `0.55` – `0.65` | Radiant golden-amber fill bar (XP / achievements / workshop). |
| `progress_fill_cyan.png` | `256 × 64` | `Slice` | `Rect.new(36, 20, 220, 44)` | `0.55` – `0.65` | Luminous electric-cyan fill bar (collection / ocean progress). |
| `toggle_on.png` | `192 × 96` | `Slice` | `Rect.new(56, 36, 136, 60)` | `0.50` – `0.55` | Glossy emerald-lime toggle track (ON state). |
| `toggle_off.png` | `192 × 96` | `Slice` | `Rect.new(56, 36, 136, 60)` | `0.50` – `0.55` | Muted plum-slate toggle track (OFF state). |
| `toggle_thumb.png` | `96 × 96` | `Fit` | — | — | Plump glossy cream-white 3D sphere knob for toggles. |
| `slider_track.png` | `256 × 48` | `Slice` | `Rect.new(32, 18, 224, 30)` | `0.55` – `0.65` | Deep recessed indigo slider track with dark plum outline. |
| `slider_fill.png` | `256 × 48` | `Slice` | `Rect.new(28, 16, 228, 32)` | `0.55` – `0.65` | Glossy electric-cyan slider fill bar. |
| `slider_thumb.png` | `96 × 96` | `Fit` | — | — | Golden-bezel + sparkling aqua-cyan gem slider knob. |
| `badge_dot.png` | `96 × 96` | `Fit` | — | — | Plump glossy red-coral notification dot (pulses via shared animation loop). |

---

## Stage 3 — Rarity Creature Card Frames (`A.5`, 6 PNGs)

Escalating festiveness from simple Common to crowned prismatic Mythic:

| File | Size (px) | `ScaleType` | `SliceCenter` | Recommended `SliceScale` | Rarity & Visual Details |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `card_rarity_common.png` | `384 × 512` | `Slice` | `Rect.new(96, 112, 288, 400)` | `0.45` – `0.55` | Clean seafoam-teal glossy frame, simple mint trim. |
| `card_rarity_uncommon.png` | `384 × 512` | `Slice` | `Rect.new(96, 112, 288, 400)` | `0.45` – `0.55` | Sky-blue glossy frame + 2 top corner sparkles. |
| `card_rarity_rare.png` | `384 × 512` | `Slice` | `Rect.new(96, 112, 288, 400)` | `0.45` – `0.55` | Royal-purple frame + metallic gold inner trim + 4 stars. |
| `card_rarity_epic.png` | `384 × 512` | `Slice` | `Rect.new(96, 112, 288, 400)` | `0.45` – `0.55` | Hot-magenta frame + gold trim + 4 corner crystal gems + stars. |
| `card_rarity_legendary.png` | `384 × 512` | `Slice` | `Rect.new(96, 112, 288, 400)` | `0.45` – `0.55` | Liquid-gold frame + 4 corner gems + 6 stars + top golden crown crest. |
| `card_rarity_mythic.png` | `384 × 512` | `Slice` | `Rect.new(96, 112, 288, 400)` | `0.45` – `0.55` | Prismatic rainbow aurora frame + gold trim + 4 gems + 8 stars + cosmic crown crest. |

> **Note on `card_rarity_legendary.png` & `card_rarity_mythic.png`:** Because of the centered top crown crest, use `Enum.ScaleType.Fit` (or `Stretch` on fixed `3:4` aspect cards) on portrait creature cards if you want the crown centered without stretching horizontally, or `Slice` on widths near `~200–320 px` (`SliceScale = 0.5`).

---

## Stage 4 — Pictorial Cartoon 3D Icons (`A.4`, 22 PNGs)

All `256 × 256 px`, transparent RGBA, `Enum.ScaleType.Fit`, thick `#2C0A4D` cartoon outline:

| File | Size (px) | `ScaleType` | Usage |
| :--- | :--- | :--- | :--- |
| `icon_aquarium.png` | `256 × 256` | `Fit` | Aquarium header / tab |
| `icon_arrow_right.png` | `256 × 256` | `Fit` | Navigation / next / tutorial direction |
| `icon_book.png` | `256 × 256` | `Fit` | Collection / album / lore |
| `icon_check.png` | `256 × 256` | `Fit` | Claimed / unlocked / completed badge |
| `icon_chest.png` | `256 × 256` | `Fit` | Day 7 chest / fishing chest / rewards |
| `icon_clock.png` | `256 × 256` | `Fit` | Daily reset / event countdown |
| `icon_coin.png` | `256 × 256` | `Fit` | Coin rewards / prices |
| `icon_crown.png` | `256 × 256` | `Fit` | Leaderboard / top rank / VIP |
| `icon_fish.png` | `256 × 256` | `Fit` | Catches / species / missions |
| `icon_gear.png` | `256 × 256` | `Fit` | Settings / workshop |
| `icon_gem.png` | `256 × 256` | `Fit` | Robux shop / rare rewards |
| `icon_gift.png` | `256 × 256` | `Fit` | Daily gift / welcome bonus |
| `icon_lock.png` | `256 × 256` | `Fit` | Locked card / locked portal / locked rod |
| `icon_reduce_effects.png` | `256 × 256` | `Fit` | Settings ReduceEffects toggle |
| `icon_rod.png` | `256 × 256` | `Fit` | Workshop / rods / catches |
| `icon_sound_off.png` | `256 × 256` | `Fit` | Settings muted audio |
| `icon_sound_on.png` | `256 × 256` | `Fit` | Settings music / SFX volume |
| `icon_sparkle.png` | `256 × 256` | `Fit` | Shiny / discovery / prestige highlight |
| `icon_star.png` | `256 × 256` | `Fit` | Rarity stars / perfect catches |
| `icon_trophy.png` | `256 × 256` | `Fit` | Achievements / milestones |
| `icon_wheel.png` | `256 × 256` | `Fit` | Catch roulette / bonus spin |
| `icon_xp.png` | `256 × 256` | `Fit` | Training / Fishing Power / XP |

**Total generated assets:** `75 PNGs` (`14` A.1 + `15` A.2 + `18` A.3 + `6` A.5 + `22` A.4).

