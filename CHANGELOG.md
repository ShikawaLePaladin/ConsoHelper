# Changelog

## 1.0.0

Initial release.

- Compact icon-grid buff/consumable status tracker with glow-on-active and dim-on-expiring visual states.
- ~150 tracked entries across Class Buffs, Flasks, Battle Elixirs, Guardian Elixirs, Protection Potions, Special Potions, Juju & Tribal, Food & Drinks, Alcoholic Beverages, Combat Potions and Weapon Enchants.
- Item data cross-checked against a live server item-database scan; several incorrect item IDs inherited from prior data sources were corrected.
- Dynamic icon resolution via `GetItemInfo` instead of hardcoded icon paths.
- One-click weapon enchant application (sharpening stones, oils, poisons) directly onto the correct weapon slot.
- Searchable, category-grouped icon-grid selection window replacing a single-column checklist.
- Shopping list with configurable restock threshold.
- Draggable minimap button, combat-aware update pausing/hiding, and a compact two-column settings panel.
