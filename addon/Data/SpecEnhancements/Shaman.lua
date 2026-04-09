------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Shaman
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Elemental (specID 262)
------------------------------------------------------------------------
RA.SpecEnhancements[262] = {
    majorCooldowns = {
        { spellID = 191634, alertThreshold = 5,  name = "Stormkeeper" },
        { spellID = 198067, alertThreshold = 10, name = "Fire Elemental" },
    },

    interruptSpell = { spellID = 57994, name = "Wind Shear", cooldown = 12 },

    defensives = {
        { spellID = 108271, hpThreshold = 0.40, name = "Astral Shift" },
        { spellID = 108281, hpThreshold = 0.50, name = "Ancestral Guidance" },
    },

    resource = {
        powerType = 11, -- Enum.PowerType.Maelstrom
        maxBase   = 100,
        spellCosts = {
            [8042]   = { cost = 60 },  -- Earth Shock
            [61882]  = { cost = 60 },  -- Earthquake
            [188196] = { gen = 8 },    -- Lightning Bolt
            [51505]  = { gen = 10 },   -- Lava Burst
            [188443] = { gen = 4 },    -- Chain Lightning (per target)
        },
    },

    burstWindows = {
        meta = { trigger = 198067, duration = 30, label = "Fire Elemental" }
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
        weapon = { type = "aura", spellID = 33757,  name = "Flametongue Weapon" }
    },

    inferenceRules = {
        aoeSpells = { 188443, 61882, 191634 },
        singleTargetSpells = { 188196, 51505, 8042 },
        generatorSpells = { 188196, 51505, 188443 },
        spenderSpells = { 8042, 61882 },
        burstIndicatorSpells = { 198067 },
        burstCooldownSpell = 198067,
        burstDuration = 30,
        executeSpells = {},
    },

    secondaryPowerType = nil,
}

------------------------------------------------------------------------
-- Enhancement (specID 263)
------------------------------------------------------------------------
RA.SpecEnhancements[263] = {
    majorCooldowns = {
        { spellID = 114051, alertThreshold = 10, name = "Ascendance" },
        { spellID = 384352, alertThreshold = 5,  name = "Doom Winds" },
        { spellID = 197214, alertThreshold = 5,  name = "Sundering" },
        { spellID = 375982, alertThreshold = 5,  name = "Primordial Wave" },
    },

    interruptSpell = { spellID = 57994, name = "Wind Shear", cooldown = 12 },

    defensives = {
        { spellID = 108271, hpThreshold = 0.40, name = "Astral Shift" },
        { spellID = 198103, hpThreshold = 0.25, name = "Earth Elemental" },
        { spellID = 108281, hpThreshold = 0.50, name = "Ancestral Guidance" },
    },

    resource = {
        powerType = 11, -- Enum.PowerType.Maelstrom / Enhancement stack proxy
        maxBase   = 10,
        spellCosts = {
            [17364]  = { gen = 2 },   -- Stormstrike / Windstrike
            [60103]  = { gen = 1 },   -- Lava Lash
            [187874] = { gen = 2 },   -- Crash Lightning
            [188196] = { cost = 5 },  -- Lightning Bolt (MW spender)
            [188443] = { cost = 5 },  -- Chain Lightning (MW spender)
            [462856] = { cost = 10 }, -- Primordial Wave / Storm
            [384063] = { cost = 0 },  -- Surging Totem
        },
    },

    burstWindows = {
        ascendance = { trigger = 114051, duration = 15, label = "Ascendance" },
        doomWinds  = { trigger = 384352, duration = 8,  label = "Doom Winds" },
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
        weapon = { type = "aura", spellID = 33757,  name = "Flametongue Weapon" },
    },

    inferenceRules = {
        aoeSpells = { 187874, 188443, 197214, 384063 },
        singleTargetSpells = { 17364, 60103, 188196, 462620 },
        generatorSpells = { 17364, 60103, 187874 },
        spenderSpells = { 188196, 188443, 462856 },
        burstIndicatorSpells = { 114051, 384352 },
        burstCooldownSpell = 114051,
        burstDuration = 15,
        executeSpells = {},
    },

    secondaryPowerType = 11,
}
