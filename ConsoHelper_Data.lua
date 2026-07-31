-- Conso Helper - Data
-- Static database of tracked buffs, consumables and weapon enchants.
-- Item-based entries resolve their icon at runtime via GetItemInfo (see ConsoHelper_Core.lua),
-- so only itemID is required for those - no hand-typed icon paths to keep in sync.

ConsoHelper_Data = {}

ConsoHelper_Data.categoryOrder = {
  "class", "flask", "battle", "guardian", "protection", "special",
  "juju", "food", "alcohol", "combat", "enchant",
}

ConsoHelper_Data.categoryLabels = {
  class      = "Class Buffs",
  flask      = "Flasks",
  battle     = "Battle Elixirs",
  guardian   = "Guardian Elixirs",
  protection = "Protection Potions",
  special    = "Special Potions & Consumables",
  juju       = "Juju & Tribal",
  food       = "Food & Drinks",
  alcohol    = "Alcoholic Beverages",
  combat     = "Combat Potions",
  enchant    = "Weapon Enchants",
}

-- kind: "spell" (class buff, detected by aura texture), "item" (consumable, detected by
-- resolved item texture as aura, tracked via bag count), "enchant" (weapon oil/stone).
ConsoHelper_Data.buffs = {

  -- ===================== CLASS BUFFS =====================
  { cat = "class", kind = "spell", name = "Power Word: Fortitude", spellID = 1243,
    icon = "Interface\\Icons\\Spell_Holy_WordFortitude", buffIcon = "Interface\\Icons\\Spell_Holy_WordFortitude",
    raidbuffIcon = "Interface\\Icons\\Spell_Holy_PrayerOfFortitude" },
  { cat = "class", kind = "spell", name = "Divine Spirit", spellID = 14752,
    icon = "Interface\\Icons\\Spell_Holy_DivineSpirit", buffIcon = "Interface\\Icons\\Spell_Holy_DivineSpirit",
    raidbuffIcon = "Interface\\Icons\\Spell_Holy_PrayerofSpirit" },
  { cat = "class", kind = "spell", name = "Arcane Intellect", spellID = 1459,
    icon = "Interface\\Icons\\Spell_Holy_MagicalSentry", buffIcon = "Interface\\Icons\\Spell_Holy_MagicalSentry",
    raidbuffIcon = "Interface\\Icons\\Spell_Holy_ArcaneIntellect" },
  { cat = "class", kind = "spell", name = "Mark of the Wild", spellID = 1126,
    icon = "Interface\\Icons\\Spell_Nature_Regeneration", buffIcon = "Interface\\Icons\\Spell_Nature_Regeneration" },
  { cat = "class", kind = "spell", name = "Blessing of Salvation", spellID = 1038,
    icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation", buffIcon = "Interface\\Icons\\Spell_Holy_SealOfSalvation",
    raidbuffIcon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation" },
  { cat = "class", kind = "spell", name = "Blessing of Might", spellID = 19740,
    icon = "Interface\\Icons\\Spell_Holy_FistOfJustice", buffIcon = "Interface\\Icons\\Spell_Holy_FistOfJustice",
    raidbuffIcon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings" },
  { cat = "class", kind = "spell", name = "Blessing of Wisdom", spellID = 19742,
    icon = "Interface\\Icons\\Spell_Holy_SealOfWisdom", buffIcon = "Interface\\Icons\\Spell_Holy_SealOfWisdom",
    raidbuffIcon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom" },
  { cat = "class", kind = "spell", name = "Blessing of Kings", spellID = 20217,
    icon = "Interface\\Icons\\Spell_Magic_MageArmor", buffIcon = "Interface\\Icons\\Spell_Magic_MageArmor",
    raidbuffIcon = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings" },
  { cat = "class", kind = "spell", name = "Blessing of Light", spellID = 19977,
    icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02", buffIcon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02",
    raidbuffIcon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight" },

  -- ===================== FLASKS (2h) =====================
  { cat = "flask", kind = "item", name = "Flask of the Titans",        itemID = 13510, duration = 7200 },
  { cat = "flask", kind = "item", name = "Flask of Supreme Power",     itemID = 13512, duration = 7200 },
  { cat = "flask", kind = "item", name = "Flask of Distilled Wisdom",  itemID = 13511, duration = 7200 },
  { cat = "flask", kind = "item", name = "Flask of Chromatic Resistance", itemID = 13513, duration = 7200 },

  -- ===================== BATTLE ELIXIRS (offense) =====================
  { cat = "battle", kind = "item", name = "Elixir of the Mongoose",         itemID = 13452, duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Giants",               itemID = 9206,  duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Shadow Power",         itemID = 9264,  duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Greater Firepower",    itemID = 21546, duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Greater Nature Power", itemID = 50237, duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Frost Power",          itemID = 17708, duration = 1800, buffIcon = "Interface\\Icons\\INV_Potion_03" },
  { cat = "battle", kind = "item", name = "Elixir of Greater Intellect",    itemID = 9179,  duration = 1200, buffIcon = "Interface\\Icons\\INV_Potion_10" },
  { cat = "battle", kind = "item", name = "Greater Arcane Elixir",          itemID = 13454, duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Agility",              itemID = 8949,  duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Greater Agility",      itemID = 9187,  duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Brute Force",          itemID = 13453, duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Greater Frost Power",  itemID = 55046, duration = 3600 },
  { cat = "battle", kind = "item", name = "Elixir of Greater Arcane Power", itemID = 55048, duration = 3600 },
  { cat = "battle", kind = "item", name = "Dreamshard Elixir",              itemID = 61224, duration = 3600 },

  -- ===================== GUARDIAN ELIXIRS (defense) =====================
  { cat = "guardian", kind = "item", name = "Elixir of Superior Defense",   itemID = 13445, duration = 3600, buffIcon = "Interface\\Icons\\INV_Potion_86" },
  { cat = "guardian", kind = "item", name = "Elixir of Greater Defense",    itemID = 8951,  duration = 3600 },
  { cat = "guardian", kind = "item", name = "Bloodkelp Elixir of Resistance", itemID = 22193, duration = 1800 },
  { cat = "guardian", kind = "item", name = "Bloodkelp Elixir of Dodging",  itemID = 22192, duration = 1800 },

  -- ===================== PROTECTION POTIONS (school resist, 1h) =====================
  { cat = "protection", kind = "item", name = "Fire Protection Potion",           itemID = 6049,  duration = 3600 },
  { cat = "protection", kind = "item", name = "Greater Fire Protection Potion",   itemID = 13457, duration = 3600 },
  { cat = "protection", kind = "item", name = "Frost Protection Potion",          itemID = 6050,  duration = 3600 },
  { cat = "protection", kind = "item", name = "Greater Frost Protection Potion",  itemID = 13456, duration = 3600 },
  { cat = "protection", kind = "item", name = "Shadow Protection Potion",         itemID = 6048,  duration = 3600 },
  { cat = "protection", kind = "item", name = "Greater Shadow Protection Potion", itemID = 13459, duration = 3600 },
  { cat = "protection", kind = "item", name = "Holy Protection Potion",           itemID = 6051,  duration = 3600 },
  { cat = "protection", kind = "item", name = "Greater Holy Protection Potion",   itemID = 13460, duration = 3600 },
  { cat = "protection", kind = "item", name = "Nature Protection Potion",         itemID = 6052,  duration = 3600 },
  { cat = "protection", kind = "item", name = "Greater Nature Protection Potion", itemID = 13458, duration = 3600 },
  { cat = "protection", kind = "item", name = "Greater Arcane Protection Potion", itemID = 13461, duration = 3600 },

  -- ===================== SPECIAL POTIONS & CONSUMABLES =====================
  { cat = "special", kind = "item", name = "Mageblood Potion",           itemID = 20007, duration = 3600 },
  { cat = "special", kind = "item", name = "Gift of Arthas",             itemID = 9088,  duration = 1800, buffIcon = "Interface\\Icons\\Spell_Shadow_FingerOfDeath" },
  { cat = "special", kind = "item", name = "Winterfall Firewater",       itemID = 12820, duration = 1200 },
  { cat = "special", kind = "item", name = "Spirit of Zanza",            itemID = 20079, duration = 7200 },
  { cat = "special", kind = "item", name = "Ground Scorpok Assay",       itemID = 8412,  duration = 3600, buffIcon = "Interface\\Icons\\Spell_Nature_ForceOfNature", buffName = "Salt of the Scorpok" },
  { cat = "special", kind = "item", name = "R.O.I.D.S.",                 itemID = 8410,  duration = 3600, buffIcon = "Interface\\Icons\\Spell_Nature_Strength", buffName = "Rage of Ages" },
  { cat = "special", kind = "item", name = "Cerebral Cortex Compound",   itemID = 8423,  duration = 3600, buffIcon = "Interface\\Icons\\Spell_Nature_Purge", buffName = "Infallible Mind" },
  { cat = "special", kind = "item", name = "Dreamtonic",                 itemID = 61423, duration = 1200, buffIcon = "Interface\\Icons\\INV_Potion_30" },

  -- ===================== JUJU & TRIBAL =====================
  { cat = "juju", kind = "item", name = "Juju Might",  itemID = 12460, duration = 1800 },
  { cat = "juju", kind = "item", name = "Juju Power",  itemID = 12451, duration = 1800 },
  { cat = "juju", kind = "item", name = "Juju Flurry", itemID = 12450, duration = 20 },
  { cat = "juju", kind = "item", name = "Juju Escape", itemID = 12459, duration = 600 },
  { cat = "juju", kind = "item", name = "Juju Chill",  itemID = 12457, duration = 600 },
  { cat = "juju", kind = "item", name = "Juju Ember",  itemID = 12455, duration = 600 },
  { cat = "juju", kind = "item", name = "Juju Guile",  itemID = 12458, duration = 1800 },

  -- ===================== FOOD & DRINKS =====================
  { cat = "food", kind = "item", name = "Smoked Desert Dumplings",         itemID = 20452, duration = 900, buffIcon = "Interface\\Icons\\Spell_Misc_Food" },
  { cat = "food", kind = "item", name = "Grilled Squid",                   itemID = 13928, duration = 900, buffIcon = "Interface\\Icons\\INV_Gauntlets_19" },
  { cat = "food", kind = "item", name = "Nightfin Soup",                   itemID = 13931, duration = 900, buffIcon = "Interface\\Icons\\Spell_Nature_ManaRegenTotem" },
  { cat = "food", kind = "item", name = "Runn Tum Tuber Surprise",         itemID = 18254, duration = 900, buffIcon = "Interface\\Icons\\INV_Misc_Organ_03" },
  { cat = "food", kind = "item", name = "Dirge's Kickin' Chimaerok Chops", itemID = 21023, duration = 900, buffIcon = "Interface\\Icons\\INV_Boots_Plate_03" },
  { cat = "food", kind = "item", name = "Hardened Mushroom",               itemID = 51717, duration = 900, buffIcon = "Interface\\Icons\\INV_Boots_Plate_03" },
  { cat = "food", kind = "item", name = "Power Mushroom",                  itemID = 51720, duration = 900, buffIcon = "Interface\\Icons\\Spell_Misc_Food" },
  { cat = "food", kind = "item", name = "Le Fishe Au Chocolat",            itemID = 84040, duration = 900, buffIcon = "Interface\\Icons\\Spell_Misc_Food" },
  { cat = "food", kind = "item", name = "Sweet Mountain Berry",            itemID = 51714, duration = 600, buffIcon = "Interface\\Icons\\INV_Boots_Plate_03" },
  { cat = "food", kind = "item", name = "Danonzo's Tel'Abim Medley",       itemID = 60978, duration = 900, buffIcon = "Interface\\Icons\\Spell_Misc_Food" },
  { cat = "food", kind = "item", name = "Danonzo's Tel'Abim Surprise",     itemID = 60976, duration = 900, buffIcon = "Interface\\Icons\\Spell_Misc_Food" },
  { cat = "food", kind = "item", name = "Danonzo's Tel'Abim Delight",      itemID = 60977, duration = 900, buffIcon = "Interface\\Icons\\Spell_Misc_Food" },
  { cat = "food", kind = "item", name = "Gurubashi Gumbo",                 itemID = 53015, duration = 900, buffIcon = "Interface\\Icons\\INV_Misc_Food_73" },
  { cat = "food", kind = "item", name = "Dragonbreath Chili",              itemID = 12217, duration = 600, buffIcon = "Interface\\Icons\\Spell_Fire_Incinerate" },
  { cat = "food", kind = "item", name = "Blessed Sunfruit",                itemID = 13810, duration = 600 },
  { cat = "food", kind = "item", name = "Blessed Sunfruit Juice",          itemID = 13813, duration = 600 },
  { cat = "food", kind = "item", name = "Crunchy Sandwept Carrots",        itemID = 42161, duration = 600 },
  { cat = "food", kind = "item", name = "Spicy Sandswept Carrots",         itemID = 42162, duration = 600 },
  { cat = "food", kind = "item", name = "Sweet Northwind Grapes",          itemID = 34729, duration = 600 },
  { cat = "food", kind = "item", name = "Sweet Wildhammer Yam",            itemID = 42159, duration = 600 },
  { cat = "food", kind = "item", name = "Mealy Wildhammer Yam",            itemID = 42160, duration = 600 },
  { cat = "food", kind = "item", name = "Buttermilk Delight",              itemID = 22236, duration = 3600 },

  -- ===================== ALCOHOLIC BEVERAGES =====================
  { cat = "alcohol", kind = "item", name = "Rumsey Rum Black Label",  itemID = 21151, duration = 900 },
  { cat = "alcohol", kind = "item", name = "Medivh's Merlot",         itemID = 61174, duration = 900, buffIcon = "Interface\\Icons\\INV_Drink_04" },
  { cat = "alcohol", kind = "item", name = "Medivh's Merlot Blue",    itemID = 61175, duration = 900, buffIcon = "Interface\\Icons\\INV_Drink_19" },
  { cat = "alcohol", kind = "item", name = "Rumsey Rum Light",        itemID = 20709, duration = 900 },
  { cat = "alcohol", kind = "item", name = "Rumsey Rum Dark",         itemID = 21114, duration = 900 },
  { cat = "alcohol", kind = "item", name = "Kreeg's Stout Beatdown",  itemID = 18284, duration = 900 },

  -- ===================== COMBAT POTIONS (instant / on-demand) =====================
  { cat = "combat", kind = "item", name = "Nordanaar Herbal Tea", itemID = 61675 },
  { cat = "combat", kind = "item", name = "Potion of Quickness",  itemID = 61181, duration = 30, buffIcon = "Interface\\Icons\\Spell_Nature_Invisibilty" },
  { cat = "combat", kind = "item", name = "Mighty Rage Potion",   itemID = 13442 },
  { cat = "combat", kind = "item", name = "Rage Potion",          itemID = 5631 },
  { cat = "combat", kind = "item", name = "Great Rage Potion",    itemID = 5633 },
  { cat = "combat", kind = "item", name = "Free Action Potion",   itemID = 5634 },

  -- ===================== WEAPON ENCHANTS =====================
  { cat = "enchant", kind = "enchant", name = "Dense Sharpening Stone",     itemID = 12404, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Dense Sharpening Stone",     itemID = 12404, slot = "offhand" },
  { cat = "enchant", kind = "enchant", name = "Elemental Sharpening Stone", itemID = 18262, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Elemental Sharpening Stone", itemID = 18262, slot = "offhand" },
  { cat = "enchant", kind = "enchant", name = "Consecrated Sharpening Stone", itemID = 23122, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Consecrated Sharpening Stone", itemID = 23122, slot = "offhand" },
  { cat = "enchant", kind = "enchant", name = "Wizard Oil", itemID = 20750, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Blessed Wizard Oil", itemID = 23123, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Shadow Oil", itemID = 3824, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Shadow Oil", itemID = 3824, slot = "offhand" },
  { cat = "enchant", kind = "enchant", name = "Frost Oil", itemID = 3829, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Frost Oil", itemID = 3829, slot = "offhand" },
  { cat = "enchant", kind = "enchant", name = "Deadly Poison",  itemID = 2892, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Deadly Poison",  itemID = 2892, slot = "offhand" },
  { cat = "enchant", kind = "enchant", name = "Deadly Poison V", itemID = 20844, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Deadly Poison V", itemID = 20844, slot = "offhand" },
  { cat = "enchant", kind = "enchant", name = "Instant Poison", itemID = 6947, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Instant Poison", itemID = 6947, slot = "offhand" },
  { cat = "enchant", kind = "enchant", name = "Instant Poison VI", itemID = 8928, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Instant Poison VI", itemID = 8928, slot = "offhand" },
  { cat = "enchant", kind = "enchant", name = "Wound Poison IV", itemID = 10922, slot = "mainhand" },
  { cat = "enchant", kind = "enchant", name = "Wound Poison IV", itemID = 10922, slot = "offhand" },
}
