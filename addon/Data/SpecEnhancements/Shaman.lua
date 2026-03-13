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
