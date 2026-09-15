# BlackTek Demo Client (Godot 4.7.2)

Playable offline demo client for the BlackTek server. Runs the full gameplay
loop against a **MockDB** (JSON at `user://mock_db.json`) — no MariaDB, no TCP.
The server layer mirrors BlackTek logic (`src/game.cpp`, `data/scripts/*.lua`)
so the later switch to the real server only replaces `game/server.gd` /
`game/database.gd` with the protocol code already stubbed in
`net/protocol.gd` + `net/xtea.gd` (Tibia 10.98 framing + XTEA).

## Project layout

```
scripts/
  main.gd                 entry point: wiring, input (movement/hotkeys/push)
  world_view.gd           renderer: map, creatures, damage numbers, engine lights
  game/server.gd          BlackTekGameServer — thin facade: signals + state,
                          delegates to the modules below (callers unchanged)
  game/config.gd          BlackTekConfig — central TOML loader (vocations,
                          rates, equipment, items, gameplay, shop) + fallbacks
  game/session.gd         BlackTekSession — account auth, character list/create
  game/chat.gd            BlackTekChat — range-scoped say + talk/spell/NPC dispatch
  game/day_cycle.gd       BlackTekDayCycle — ambient day/night tick
  game/item_data.gd       BlackTekItemData — tooltip text + stat lookups
  game/player.gd          BlackTekPlayer — compat facade over player/* (API stable)
  game/player/vitals.gd     vocation math, hp/mana/food/skills/conditions
  game/player/inventory.gd  bag/equipment/gold/shop
  game/player/movement.gd   steps/stairs/floors/spawn/town
  game/player/interaction.gd push/drop/pickup/doors
  game/monsters.gd        archetypes (data/monster_definitions.toml), spawn,
                          AI, occupancy, creature pushing
  game/combat.gd          weapons/armor, targeting, melee, monster attacks, death
  game/loot.gd            loot tables (data/loot_tables.toml) + roll/grant
  game/regeneration.gd    poison + hp/mana regen ticks
  game/pathfinding.gd     Dijkstra click-routing (sqrt(2) diagonals) + walker
  game/npc.gd             Norf: temple post, local-chat hearing, dialogue, wares
  data/                   vocations.toml, rates.toml, equipment_slots.toml,
                          item_stats.toml, gameplay.toml, shop_offers.toml,
                          monster_definitions.toml, loot_tables.toml
  game/world.gd           BlackTekWorld — map data: assets.dat/OTBM/sprites,
                          walkability, sprite anchoring, light sources
  game/database.gd        BlackTekDatabase — MockDB (accounts/players/items)
  game/action_scripts.gd  BlackTekActionScripts — simulated Lua content
  game/loaders/           dat/spr/otbm binary parsers
  net/                    protocol framing + XTEA (for the real server later)
  ui/ui_kit.gd            shared theme, widget factories, free placement grid
  ui/gear_panel.gd        equipment + backpack screens (click/drag inventory)
  hud.gd                  HUD root: login, status bars, chat, stats, hotbar,
                          rail, minimap, shop + server signal wiring
verify_demo.gd            headless regression suite (133 checks)
```

## Tuning (no code changes)

Gameplay numbers live in `data/*.toml` and load via `game/config.gd`
(missing files fall back to the old hardcoded defaults, so the demo never
breaks). Examples:

- `vocations.toml` — hp/mana/cap per level, regen, attack speed
- `rates.toml` — exp/stage/skill/magic/loot multipliers
- `equipment_slots.toml` — itemtype → gear slot
- `item_stats.toml` — atk/armor/heal/mana/food (unifies combat + tooltips)
- `gameplay.toml` — push cooldown, day cycle, chat range, spawn pacing,
  walk cadence, fallback map walls
- `shop_offers.toml` — Norf's wares/prices

## Run

Open this folder in Godot 4.7.2 (`Godot_v4.7.2.exe` on the desktop) and press
F5, or:

```
Godot_v4.7.2.exe --path Client
```

Log in with the seeded account **demo / demo** → two characters
(DemoKnight lvl 8, DemoSorcerer lvl 8), or create your own. The world is the
real `forgotten.otbm` map with `assets.dat` walkability and `Tibia.spr`
sprites.

## What is simulated (mock "server")

- `scripts/mock_db.gd` — accounts, players, player_items, player_storage
  (mirrors `schema.sql`), JSON-persisted; save on exit, `/save` to force.
- `scripts/mock_scripts.gd` — action scripts mirroring the Lua content:
  - potions (health 7618 / mana 7620), food (meat/ham, well-fed regen buff)
  - quest chest (storage-gated, once per character)
  - talkactions: `/pos`, `!online` (player), `/t`, `/save` (GM-gated)
  - spells: `exura` / `exura gran` (heal), `exana pox` (cure poison),
    `utevo lux` (personal light 120s), `exori flam` (strike, needs target),
    `exori` (whirlwind: 0.8s wind-up with yellow warning squares on the 8
    tiles, then damage with a red impact flash)
  - NPC shop: buy potions/meat/ham with gold coins from the backpack
- `scripts/mock_server.gd` — movement with diagonal no-corner-cut, stairs
  teleport, vocation stats/regen per `data/vocations/*.toml`, rates from
  `config/rates.toml` (exp 5, skill 3, loot 2) + stage multiplier, Rat
  monsters (spawn/approach/melee AI, loot, xp), skill + magic level advance,
  death → temple respawn.

## Controls

| Key | Action |
|---|---|
| WASD/Arrows (+ QEZC / numpad) | Walk (diagonals included) |
| Space | Target nearest creature (mark lost when it leaves the screen/floor) |
| F1–F3 | Potions bar slots 1–3 |
| F4–F6 | Spells bar (heal, flame strike) + attack |
| F7–F9 | Test spells bar (magic light, cure poison, whirlwind) |
| T | Chat (`hi`, `trade`, `buy`/`sell meat 2`, `exura gran`, `utevo lux`, `/pos`) |
| G / K | Gear panel / Stats panel |
| R | Teleport to town temple |
| M | Toggle minimap |
| PgUp / PgDn | Floor up / down |
| Right rail icons | Gear / Stats / Chat / Shop / Minimap toggles; Retro pixels (crisp/smooth) and sprite upscale 32/64/128px below |
| Mouse drag on adjacent creature/object | Push it 1 SQM in the drag direction, diagonals included (per-creature cooldown); release a floor item over the open gear panel to take it instead |
| Mouse drag from yourself | Quick-step 1 SQM in the drag direction |
| Drag bag/gear item onto a floor tile | Drop it there (melee reach); drag floor loot onto the open gear panel to pick it up (auto-equips when the slot is free) |
| Left-click a tile | Walk there automatically (shortest-route pathfinding, cyan dots; diagonals pace slower; reroutes around creatures, "blocked" only when truly stuck) |
| Left-click an adjacent door | Open/close it (walkability follows the leaf) |
| Chat | Local: only listeners within 9 SQM hear you; Norf only answers at the temple |

## HUD

Login/character select → in-game: HP/Mana/XP bars with level/vocation plus
condition chips (PZ in the temple area, Fed/Hungry, Poisoned — rats poison,
Lit while `utevo lux` holds),
three action bars (Potions F1–F3, Spells F4–F6, Test Spells F7–F9) with cooldown
sweeps and assignable slots, gear panel (10 equipment slots + 20-slot
backpack, click or drag to equip/rearrange — drag & drop works only inside
the inventory), stats panel with skill progress bars, NPC shop
panel, floating damage numbers, per-creature name + overhead HP bar (green
> 50%, yellow 25–50%, red < 25%), and a minimap (M or the map rail icon).
Creatures and players never share an SQM; monsters block movement and can be
pushed by mouse-drag onto an adjacent free tile. Left-clicking a tile walks
the player there via server-side BFS pathfinding (drawing the route). The
world has a light system: ambient day/night darkness (say /night or /day to
toggle; surface floors bottom out at 45% so nights stay readable, dungeons
keep full darkness) with per-tile light sources from assets.dat (torches,
campfires) plus a personal light (`utevo lux` holds it at full for 120s), floors fade smoothly (upper floors render translucent,
stairs fade the view), and item tooltips show stats
(attack/defense/heal/food/weight). The HUD auto-hides after 10 seconds
without input and reappears on any activity.

Chat is tabbed — All / Server / Chat — switch tabs by clicking; the mouse
wheel scrolls the chat text up/down.

Every bar/panel (status, chat, hotbars, gear, stats, shop, minimap) moves
freely: drag it (status: anywhere; others: by their header) and release to
drop it on an invisible 16px grid. No edge docking, and panels always stay
fully inside the window. Panels are content-sized,
never resizable; every panel header has -/X buttons to minimize or hide it
(rail icons and hotkeys reopen). Hotkeys G/K/T/M still toggle gear, stats,
chat and the minimap.

Chat is tabbed — All / Server / Chat — switch tabs by clicking; the mouse
wheel scrolls the chat text up/down.

Gear, Stats and the shop move freely: drag a header and release to drop the
panel on the invisible 16px grid. Panels are fixed-size, never resizable;
action-bar slots accept items dragged from the backpack and persist their
bindings. Hotkeys G/K/T still toggle gear/stats/chat.

## Headless tests

```
Godot_v4.7.2.exe --headless --path Client --script res://verify_demo.gd
```

62 checks: DB session/persistence roundtrip, item names/weights, movement,
potions, spells + cooldowns, talkactions, shop purchase, combat kill/loot/xp,
food, regen, character creation. Uses a throwaway DB (`mock_db_verify.json`).

Boot smoke test (logs in, opens panels): append `-- --autotest`.
Screenshot for UI review: append `-- --shot` (saves `user://shot.png`).
