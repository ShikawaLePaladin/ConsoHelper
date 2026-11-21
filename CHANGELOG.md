# Changelog

## 1.6.0

- Synced the tracked consumables with the guild's official list on octofan.vercel.app/conso (Supabase `conso_prices`, 46 entries). **15 new entries**: Arcane Elixir, Elixir of the Sages, Magic Resistance Potion, Lung Juice Cocktail, Gizzard Gum, Oil of Immolation, Mighty Troll's Blood Potion, Heavy Runecloth Bandage, Scroll of Protection IV, Scroll of Strength IV, Scroll of Agility III, Smoked Sagefish, Superior Mana Potion, Major Mana Potion, Major Healing Potion. All item IDs verified against pfQuest's local database (calibrated on four items already tracked) and the OctoWoW item DB (octowow.st/db). Durations match this server, not vanilla (e.g. 1-hour protection potions). Entries whose aura name is translated on the FR server carry a `buffName` with the French aura name (Parchemin de..., Potion de..., Élixir Arcane/des Sages) so detection survives the FR transition; texture matching (locale-independent) stays first.
- New **"Concoctions" category** (Arcane Giant / Dreamwater / Emerald Mongoose), placed between Special Potions and Juju. It previously sat inside the Battle Elixirs block, which split that section in two in the Select window.
- Fixed Concoction of the Arcane Giant (item 27412 -> **47412**) and Concoction of the Dreamwater (27414 -> **47414**): the wrong IDs kept their icons stuck on the "?" placeholder. Confirmed on octowow.st/db, which links Arcane Giant to spell 36931 - the same spell ID the guild site tracks.
- Fixed a possible `SetPoint` error at startup when the saved frame position is missing or corrupted: the position is now validated (table + string fields, numeric x/y) and falls back to the default CENTER/0/32.

## 1.5.0

- **Arrange your icons**: put each consumable exactly where you want it. Settings > "Arrange Icons..." (or `/conso order`) switches the tracker to arrange mode: drag an icon onto any position - a blue square shows where it will land and the others shift - then click **Done**. Clicking an icon does nothing in this mode, so you can't use an item by accident, and every icon is shown even in "only when missing" mode. The order is saved per character.
- Newly enabled consumables are added at the end; "Reset Order" (or `/conso order reset`) goes back to the default order.
- Dragging an icon outside arrange mode now moves the whole frame (like dragging its border) instead of doing nothing.

## 1.4.1

- Added **Brilliant Mana Oil** (item 20748) and **Brilliant Wizard Oil** (item 20749) to the weapon enchants. Both IDs are confirmed by the OctoWoW item database (octowow.st/db), AtlasLoot and pfQuest. (1.1.0 had removed them believing they did not exist on this server; they do.)
- Fixed Dreamtonic lighting up when you used another consumable. Its aura icon (INV_Potion_30) is the same as Spirit of Zanza's, and the icon was compared. Dreamtonic is now recognised only by its aura name ("Dreamtonic", spell 45489 in the OctoWoW database), through the new `nameOnly` flag. Use `/conso debug` while the buff is on if it ever fails to light up: it lists the exact aura names.

## 1.4.0

- Added "Show only in raid": the tracker only appears while you're in a raid group (settings checkbox).
- Added "Show only when missing/low": the tracker hides icons for consumables that are active and healthy, showing only what's missing or approaching the expiry warning threshold - a compact alert-only view instead of the full status board. Icons reflow to fill the gap when others hide.
- Fixed a stale default settings key (`hideInCombat` was never read; the actual setting is `hideFrameInCombat`) so the "Hide frame in combat" checkbox now has a proper default on first install.

## 1.3.1

- Buff and bag-count detection now reacts to `UNIT_AURA` and `BAG_UPDATE` events instead of only polling on the update interval. Using a consumable (or picking up/vendoring one) now reflects on the icon almost instantly instead of taking up to a couple of seconds.
- Fixed the countdown timer not resetting when re-consuming an item before its previous buff expired. The timer only ever started once and never refreshed, so retaking a consumable early kept counting down from the original application instead of the new one. It now resets whenever a tracked item's bag count drops (i.e., it was just used).

## 1.3.0

- Added Sagefish Delight, Hearty Country Pumpkin, Tender Wolf Steak (food) and Lesser Mana Oil (weapon enchant), all verified against the official item database.
- Inverted the glow effect: the icon now glows red when a consumable is **missing** (an actionable alert) instead of glowing gold when it's active. Expiring/critical states are unchanged.

## 1.2.1

- Fixed a false-positive detection bug: Dreamshard Elixir and Greater Arcane Elixir shared the same buff icon in the database (inherited from the original addon data), so drinking one would also light up the other. Dreamshard Elixir is now matched only by its own icon and name.

## 1.2.0

- The expiry warning threshold (sound + chat alert before a buff falls off) is now configurable in Settings ("Expiry warning (min)", 1-15 minutes, default 5) instead of a fixed 5 minutes.

## 1.1.3

- Fixed icons staying stuck on the "?" placeholder until the player manually hovered them. `GetItemInfo` alone doesn't reliably make this server send uncached item data - only rendering an actual tooltip does. A hidden tooltip now automatically "hovers" every pending item once a second in the background, so icons resolve on their own.

## 1.1.2

- **Every item ID in the database was cross-checked against OctoWoW's own public database** (octowow.st/db) - the authoritative source for this server. 39 item IDs that had been added from a third-party generic classic item list turned out to be wrong (weapon oils/poisons, protection potions, several elixirs, jujus, a few foods) and are now corrected to the IDs OctoWoW actually uses. A few of these were regressions introduced in 1.1.1 that reverted correct original values - those are back to the correct IDs.
- Fixed Ground Scorpok Assay's buff name (it's "Salt of the Scorpok", not "Strike of the Scorpok").
- Renamed two elixirs to match their real in-game names: "Elixir of Greater Frost Power" and "Elixir of Greater Arcane Power".
- Fixed a food item's real name: "Crunchy Sandwept Carrots" (not "Sandswept").

## 1.1.1

- Buffs are now also matched by **name** (via a hidden scanning tooltip), not just icon texture, since some auras on this server use a different icon than their item. Fixes remaining detection gaps such as Cerebral Cortex Compound ("Infallible Mind").
- Added Dreamshard Elixir, which had never actually been in the tracked database (this, not a detection bug, was why it never worked).
- Added `/conso debug`, which prints all currently active buff names/textures plus the live detection status of every tracked item - for diagnosing any future mismatches without guesswork.
- Removed the auto-reapply feature introduced (and reverted) between 1.1.0 patches: programmatic item use triggered from a timer was silently ignored server-side, so it never actually worked. Manual click-to-use/apply is unaffected.

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
