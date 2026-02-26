------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Rogue
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Subtlety (specID 261)
------------------------------------------------------------------------
RA.SpecEnhancements[261] = {
    majorCooldowns = {
        { spellID = 121471, alertThreshold = 10, name = "Shadow Blades" },
        { spellID = 185313, alertThreshold = 5,  name = "Shadow Dance" },
        { spellID = 212283, alertThreshold = 5,  name = "Symbols of Death" },
        { spellID = 280719, alertThreshold = 5,  name = "Secret Technique" },
    },

    interruptSpell = { spellID = 1766, name = "Kick", cooldown = 15 },

    defensives = {
        { spellID = 5277, hpThreshold = 0.40, name = "Evasion" },
        { spellID = 31224, hpThreshold = 0.50, name = "Cloak of Shadows" },
        { spellID = 185311, hpThreshold = 0.35, name = "Crimson Vial" },
    },

    resource = {
        type      = 3, -- Enum.PowerType.Energy
        maxBase   = 100,
        spellCosts = {
            [185438] = { cost = 40 },  -- Shadowstrike
            [53]     = { cost = 35 },  -- Backstab
            [196819] = { cost = 35 },  -- Eviscerate
            [319175] = { cost = 35 },  -- Black Powder
            [1943]   = { cost = 25 },  -- Rupture
        },
    },

    burstWindows = {
        meta = { trigger = 185313, duration = 9, label = "Shadow Dance" }
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
        weapon = { type = "aura", spellID = 315584, name = "Instant Poison" }
    },

    inferenceRules = {
        aoeSpells = { 319175, 122281 },
        singleTargetSpells = { 53, 185438, 196819 },
        generatorSpells = { 53, 185438 },
        spenderSpells = { 196819, 319175, 1943, 280719 },
        burstIndicatorSpells = { 185438, 196819 },
        burstCooldownSpell = 185313,
        burstDuration = 9,
        executeSpells = {},
    },

    secondaryPowerType = 4, -- Enum.PowerType.ComboPoints
}
