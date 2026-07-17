# Changelog

## 1.1.0

- Fixed active-buff detection for consumables whose in-game buff icon differs from their item icon (R.O.I.D.S., Ground Scorpok Assay, Cerebral Cortex Compound, Dreamtonic, Gift of Arthas, most food, Medivh's Merlot, Potion of Quickness, several elixirs, and more).
- Fixed weapon enchant application: now uses the character panel's weapon slot click handler instead of `EquipCursorItem`, which didn't reliably apply weapon oils.
- Added a real, currently-obtainable "Wizard Oil" (was previously tracking non-existent Brilliant Mana/Wizard Oil); corrected "Blessed Wizard Oil"'s item ID (it was mislabeled as "Blessed Weapon Coating").
- Corrected 5 further item IDs (Greater Frost Protection Potion, Blessed Sunfruit, Blessed Sunfruit Juice, Buttermilk Delight, Kreeg's Stout Beatdown) after cross-checking against a live server item scan.
- Added expiry warnings: a one-time sound + chat alert at 5 minutes remaining, plus the existing dim/red state in the final 30 seconds.
- Added a search box to the buff selection window for fast filtering.
- Added independent display toggles for background, title text and timer text.

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
