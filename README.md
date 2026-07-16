# Conso Helper

A compact buff, consumable and weapon-enchant tracker for World of Warcraft 1.12 (Turtle WoW / OctoWoW).

Conso Helper watches your active buffs and consumables, tells you at a glance what's missing before a pull, and lets you use items or apply weapon enchants directly from its icon grid — all through a UI designed to stay small on screen instead of taking over half your interface.

## Features

- **Compact icon-grid buff tracker** — configurable scale, icons per row, icon spacing and update interval. Active buffs glow gently; buffs about to expire dim and switch to a red countdown; missing buffs turn red.
- **~150 tracked buffs and consumables** across Class Buffs, Flasks, Battle Elixirs, Guardian Elixirs, Protection Potions, Special Potions, Juju & Tribal, Food & Drinks, Alcoholic Beverages, Combat Potions and Weapon Enchants — cross-checked against a live server item-database scan rather than hand-typed guesses.
- **One-click weapon enchant application** — click a sharpening stone, oil or poison and it's applied straight to the correct weapon slot, no manual character-panel click required.
- **Dynamic icon resolution** — item icons are fetched live via `GetItemInfo`, so they always match what the server actually has (no stale or hardcoded icon paths to maintain).
- **Compact selection window** — a searchable icon grid (with live text filtering) instead of a giant single-column checklist, grouped by category.
- **Shopping list** — see at a glance which tracked consumables you're low on, with a configurable restock threshold.
- **Minimap button** — left-click to open buff selection, right-click for settings, draggable around the minimap.
- **Combat-aware** — optionally pause updates or hide the frame entirely while in combat.

## Installation

1. Download or clone this repository.
2. Copy the `ConsoHelper` folder into your `Interface/AddOns/` directory.
3. Restart the game or reload your UI (`/reload`).

## Commands

| Command | Action |
|---|---|
| `/conso` | Open the buff & consumable selection window |
| `/conso config` | Open the settings panel |
| `/conso shop` | Open the shopping list |
| `/conso reset` | Reset all settings and selections to default |

The minimap button gives the same access: left-click opens selection, right-click opens settings.

## Settings

- **Layout**: scale, update interval, icons per row, icon size, icon spacing.
- **Display**: show/hide background, show/hide the "Conso Helper" title text, show/hide timer text, tooltips on/off, hover-to-show, lock frame (prevents dragging).
- **Combat**: pause updates in combat, hide frame in combat.

## Credits

Conso Helper was built from scratch, taking inspiration from **[Akkio's Consume Helper](https://github.com/prodigystudios/Akkio_Consume_Helper)** (MIT licensed) — particularly its weapon-enchant tracking concept. The buff/consumable database and UI were rewritten to prioritize a compact interface and to cross-check item data against a live server scan.

## License

MIT — see [LICENSE](LICENSE).
