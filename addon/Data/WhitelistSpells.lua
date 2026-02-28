------------------------------------------------------------------------
-- RotaAssist - Whitelist Spells
-- Major cooldown abilities that are safe to query via
-- C_Spell.GetSpellCooldown() on Blizzard 12.0.
--
-- Format: [spellID] = { name, class, specID, cdSeconds }
--
-- NOTE: This table must be updated each major patch.
-- spellIDs sourced from Wowhead / SimulationCraft / WoW API data.
-- Only include abilities with significant cooldowns (>= 30 seconds).
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

---@type table<number, { name: string, class: string, specID: number|nil, cdSeconds: number }>
RA.WhitelistSpells = {

    ---------- Warrior ----------
    [227847] = { name = "Bladestorm",          class = "WARRIOR",      specID = 71,   cdSeconds = 90  },
    [167105] = { name = "Colossus Smash",      class = "WARRIOR",      specID = 71,   cdSeconds = 45  },
    [107574] = { name = "Avatar",              class = "WARRIOR",      specID = nil,  cdSeconds = 90  },
    [1719]   = { name = "Recklessness",        class = "WARRIOR",      specID = 72,   cdSeconds = 90  },
    [228920] = { name = "Ravager",             class = "WARRIOR",      specID = 73,   cdSeconds = 45  },
    [12975]  = { name = "Last Stand",          class = "WARRIOR",      specID = 73,   cdSeconds = 180 },
    [871]    = { name = "Shield Wall",         class = "WARRIOR",      specID = 73,   cdSeconds = 240 },

    ---------- Paladin ----------
    [31884]  = { name = "Avenging Wrath",      class = "PALADIN",      specID = nil,  cdSeconds = 120 },
    [31850]  = { name = "Ardent Defender",      class = "PALADIN",      specID = 66,   cdSeconds = 120 },
    [86659]  = { name = "Guardian of Ancient Kings", class = "PALADIN", specID = 66,   cdSeconds = 300 },
    [642]    = { name = "Divine Shield",        class = "PALADIN",      specID = nil,  cdSeconds = 300 },

    ---------- Hunter ----------
    [193530] = { name = "Aspect of the Wild",   class = "HUNTER",       specID = 253,  cdSeconds = 120 },
    [288613] = { name = "Trueshot",             class = "HUNTER",       specID = 254,  cdSeconds = 120 },
    [266779] = { name = "Coordinated Assault",  class = "HUNTER",       specID = 255,  cdSeconds = 120 },
    [186265] = { name = "Aspect of the Turtle", class = "HUNTER",       specID = nil,  cdSeconds = 180 },

    ---------- Rogue ----------
    [13750]  = { name = "Adrenaline Rush",      class = "ROGUE",        specID = 260,  cdSeconds = 180 },
    [121471] = { name = "Shadow Blades",        class = "ROGUE",        specID = 261,  cdSeconds = 180 },
    [185313] = { name = "Shadow Dance",         class = "ROGUE",        specID = 261,  cdSeconds = 60  },
    [212283] = { name = "Symbols of Death",     class = "ROGUE",        specID = 261,  cdSeconds = 30  },
    [280719] = { name = "Secret Technique",     class = "ROGUE",        specID = 261,  cdSeconds = 60  },
    [79140]  = { name = "Vendetta",             class = "ROGUE",        specID = 259,  cdSeconds = 120 },
    [31224]  = { name = "Cloak of Shadows",     class = "ROGUE",        specID = nil,  cdSeconds = 120 },

    ---------- Priest ----------
    [47536]  = { name = "Rapture",              class = "PRIEST",       specID = 256,  cdSeconds = 90  },
    [64843]  = { name = "Divine Hymn",          class = "PRIEST",       specID = 257,  cdSeconds = 180 },
    [228260] = { name = "Void Eruption",        class = "PRIEST",       specID = 258,  cdSeconds = 90  },
    [47585]  = { name = "Dispersion",           class = "PRIEST",       specID = 258,  cdSeconds = 120 },

    ---------- Death Knight ----------
    [49028]  = { name = "Dancing Rune Weapon",  class = "DEATHKNIGHT",  specID = 250,  cdSeconds = 120 },
    [55233]  = { name = "Vampiric Blood",       class = "DEATHKNIGHT",  specID = 250,  cdSeconds = 90  },
    [152279] = { name = "Breath of Sindragosa", class = "DEATHKNIGHT",  specID = 251,  cdSeconds = 120 },
    [51271]  = { name = "Pillar of Frost",      class = "DEATHKNIGHT",  specID = 251,  cdSeconds = 60  },
    [275699] = { name = "Apocalypse",           class = "DEATHKNIGHT",  specID = 252,  cdSeconds = 75  },
    [42650]  = { name = "Army of the Dead",     class = "DEATHKNIGHT",  specID = 252,  cdSeconds = 480 },

    ---------- Shaman ----------
    [198067] = { name = "Fire Elemental",       class = "SHAMAN",       specID = 262,  cdSeconds = 150 },
    [191634] = { name = "Stormkeeper",          class = "SHAMAN",       specID = 262,  cdSeconds = 60  },
    [51533]  = { name = "Feral Spirit",         class = "SHAMAN",       specID = 263,  cdSeconds = 90  },
    [108280] = { name = "Healing Tide Totem",   class = "SHAMAN",       specID = 264,  cdSeconds = 180 },
    [98008]  = { name = "Spirit Link Totem",    class = "SHAMAN",       specID = 264,  cdSeconds = 180 },

    ---------- Mage ----------
    [12042]  = { name = "Arcane Power",         class = "MAGE",         specID = 62,   cdSeconds = 120 },
    [190319] = { name = "Combustion",           class = "MAGE",         specID = 63,   cdSeconds = 120 },
    [12472]  = { name = "Icy Veins",            class = "MAGE",         specID = 64,   cdSeconds = 180 },
    [45438]  = { name = "Ice Block",            class = "MAGE",         specID = nil,  cdSeconds = 240 },

    ---------- Warlock ----------
    [1122]   = { name = "Summon Infernal",      class = "WARLOCK",      specID = 267,  cdSeconds = 180 },
    [265187] = { name = "Summon Demonic Tyrant", class = "WARLOCK",     specID = 266,  cdSeconds = 90  },
    [205180] = { name = "Summon Darkglare",     class = "WARLOCK",      specID = 265,  cdSeconds = 120 },
    [104773] = { name = "Unending Resolve",     class = "WARLOCK",      specID = nil,  cdSeconds = 180 },

    ---------- Monk ----------
    [137639] = { name = "Storm, Earth, and Fire", class = "MONK",       specID = 269,  cdSeconds = 90  },
    [123904] = { name = "Invoke Xuen",          class = "MONK",         specID = 269,  cdSeconds = 120 },
    [115203] = { name = "Fortifying Brew",      class = "MONK",         specID = 268,  cdSeconds = 360 },
    [322118] = { name = "Invoke Yu'lon",        class = "MONK",         specID = 270,  cdSeconds = 180 },

    ---------- Druid ----------
    [194223] = { name = "Celestial Alignment",  class = "DRUID",        specID = 102,  cdSeconds = 180 },
    [102560] = { name = "Incarnation: Chosen of Elune", class = "DRUID", specID = 102,  cdSeconds = 180 },
    [106951] = { name = "Berserk",              class = "DRUID",        specID = 103,  cdSeconds = 180 },
    [50334]  = { name = "Berserk (Guardian)",   class = "DRUID",        specID = 104,  cdSeconds = 180 },
    [740]    = { name = "Tranquility",          class = "DRUID",        specID = 105,  cdSeconds = 180 },
    [22812]  = { name = "Barkskin",             class = "DRUID",        specID = nil,  cdSeconds = 60  },

    ---------- Demon Hunter ----------
    -- HAVOC (specID 577)
    [198013] = { name = "Eye Beam",           class = "DEMONHUNTER", specID = 577,  cdSeconds = 40  },
    [188499] = { name = "Blade Dance",        class = "DEMONHUNTER", specID = 577,  cdSeconds = 9   },
    [210152] = { name = "Death Sweep",       class = "DEMONHUNTER", specID = 577,  cdSeconds = 9,  note = "Blade Dance during Metamorphosis" },
    [201427] = { name = "Annihilation",      class = "DEMONHUNTER", specID = 577,  cdSeconds = 0,  note = "Chaos Strike during Metamorphosis - no CD, filler" },
    [191427] = { name = "Metamorphosis",      class = "DEMONHUNTER", specID = 577,  cdSeconds = 240 },
    [370965] = { name = "The Hunt",           class = "DEMONHUNTER", specID = nil,  cdSeconds = 90  }, -- shared Havoc+Vengeance+Devourer
    [258860] = { name = "Essence Break",      class = "DEMONHUNTER", specID = 577,  cdSeconds = 40  },
    [198793] = { name = "Vengeful Retreat",   class = "DEMONHUNTER", specID = nil,  cdSeconds = 25  }, -- shared Havoc+Devourer
    [258920] = { name = "Immolation Aura",    class = "DEMONHUNTER", specID = nil,  cdSeconds = 30  }, -- shared Havoc+Vengeance
    [232893] = { name = "Felblade",           class = "DEMONHUNTER", specID = nil,  cdSeconds = 15  }, -- shared Havoc+Vengeance
    [195072] = { name = "Fel Rush",           class = "DEMONHUNTER", specID = 577,  cdSeconds = 10, charges = 2 },
    [342817] = { name = "Glaive Tempest",     class = "DEMONHUNTER", specID = 577,  cdSeconds = 25  },

    -- VENGEANCE (specID 581)
    [212084] = { name = "Fel Devastation",    class = "DEMONHUNTER", specID = 581,  cdSeconds = 40  },
    [204021] = { name = "Fiery Brand",        class = "DEMONHUNTER", specID = 581,  cdSeconds = 60  },
    [187827] = { name = "Metamorphosis (Vengeance)", class = "DEMONHUNTER", specID = 581, cdSeconds = 180 },
    [204596] = { name = "Sigil of Flame",     class = "DEMONHUNTER", specID = 581,  cdSeconds = 30  },
    [207407] = { name = "Soul Carver",        class = "DEMONHUNTER", specID = 581,  cdSeconds = 30  },
    [263642] = { name = "Fracture",           class = "DEMONHUNTER", specID = 581,  cdSeconds = 5,  charges = 2 },
    [247454] = { name = "Spirit Bomb",        class = "DEMONHUNTER", specID = 581,  cdSeconds = 0   }, -- spender; track for UI display

    -- DEVOURER (specID 1480)
    -- ⚠  All Devourer spellIDs below are from Midnight alpha/datamining.
    --    Verify each with: /dump C_Spell.GetSpellInfo(SPELLID)
    [442508] = { name = "Void Metamorphosis", class = "DEMONHUNTER", specID = 1480, cdSeconds = 0,  note = "VERIFY spellID on 12.0.1 — resource-gated, not time-gated" },
    [442507] = { name = "Void Ray",           class = "DEMONHUNTER", specID = 1480, cdSeconds = 16, note = "VERIFY spellID on 12.0.1" },
    [442510] = { name = "Collapsing Star",    class = "DEMONHUNTER", specID = 1480, cdSeconds = 0,  note = "VERIFY spellID on 12.0.1 — cast during Void Meta only" },
    [442515] = { name = "Reap",              class = "DEMONHUNTER", specID = 1480, cdSeconds = 8,  note = "VERIFY spellID on 12.0.1" },
    [442501] = { name = "Consume",           class = "DEMONHUNTER", specID = 1480, cdSeconds = 0,  note = "VERIFY spellID on 12.0.1 — no CD, instant filler" },
    [442520] = { name = "Voidblade",         class = "DEMONHUNTER", specID = 1480, cdSeconds = 30, note = "VERIFY spellID on 12.0.1" },
    [442525] = { name = "Soul Immolation",   class = "DEMONHUNTER", specID = 1480, cdSeconds = 60, note = "VERIFY spellID on 12.0.1" },
    [442530] = { name = "Shift",             class = "DEMONHUNTER", specID = 1480, cdSeconds = 20, charges = 3, note = "VERIFY spellID on 12.0.1" },

    -- shared class defensive (specID nil = applies to all DH specs)
    [196718] = { name = "Darkness",          class = "DEMONHUNTER", specID = nil,  cdSeconds = 300 },

    ---------- Evoker ----------
    [375087] = { name = "Dragonrage",           class = "EVOKER",       specID = 1467, cdSeconds = 120 },
    [363534] = { name = "Rewind",               class = "EVOKER",       specID = 1468, cdSeconds = 240 },
    [395152] = { name = "Ebon Might",           class = "EVOKER",       specID = 1473, cdSeconds = 30  },
    [370452] = { name = "Shattering Star",      class = "EVOKER",       specID = 1467, cdSeconds = 20  },

    -- DEVASTATION (specID 1467)
    [357208] = { name = "Fire Breath",      class = "EVOKER", specID = 1467, cdSeconds = 30, charges = 2, note = "Flameshaper has 2 charges" },
    [359073] = { name = "Eternity Surge",   class = "EVOKER", specID = 1467, cdSeconds = 30 },
    [356995] = { name = "Disintegrate",     class = "EVOKER", specID = 1467, cdSeconds = 0, note = "Channel, no CD, Essence cost" },
    [357210] = { name = "Deep Breath",      class = "EVOKER", specID = nil,  cdSeconds = 120, note = "Scalecommander; shared" },
    [370553] = { name = "Tip the Scales",   class = "EVOKER", specID = nil,  cdSeconds = 120 },
    [436335] = { name = "Mass Disintegrate", class = "EVOKER", specID = 1467, cdSeconds = 0, note = "Granted after Empower cast" },
    [357211] = { name = "Pyre",             class = "EVOKER", specID = 1467, cdSeconds = 0 },
    [363916] = { name = "Obsidian Scales",  class = "EVOKER", specID = nil,  cdSeconds = 90 },
    [374227] = { name = "Zephyr",           class = "EVOKER", specID = nil,  cdSeconds = 120 },
    [351338] = { name = "Quell",            class = "EVOKER", specID = nil,  cdSeconds = 40 },

    -- AUGMENTATION (specID 1473)
    [395160] = { name = "Eruption",          class = "EVOKER", specID = 1473, cdSeconds = 0 },
    [396286] = { name = "Upheaval",          class = "EVOKER", specID = 1473, cdSeconds = 40 },
    [409311] = { name = "Prescience",        class = "EVOKER", specID = 1473, cdSeconds = 12 },
    [403631] = { name = "Breath of Eons",    class = "EVOKER", specID = 1473, cdSeconds = 120 },
    [404977] = { name = "Time Skip",         class = "EVOKER", specID = 1473, cdSeconds = 180 },
    [360827] = { name = "Blistering Scales", class = "EVOKER", specID = 1473, cdSeconds = 30 },

    -- PRESERVATION (specID 1468)
    [355913] = { name = "Emerald Blossom",   class = "EVOKER", specID = 1468, cdSeconds = 0 },
    [366155] = { name = "Reversion",         class = "EVOKER", specID = 1468, cdSeconds = 9 },
    [382614] = { name = "Dream Breath",      class = "EVOKER", specID = 1468, cdSeconds = 25 },
    [382731] = { name = "Temporal Anomaly",  class = "EVOKER", specID = 1468, cdSeconds = 15 },
}

