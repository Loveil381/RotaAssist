------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Rogue
-- Per-spec configuration for major cooldowns, defensives, resources,
-- burst windows, active mitigation, and pre-pull consumable checks.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Assassination (specID 259)
------------------------------------------------------------------------
RA.SpecEnhancements[259] = {
    majorCooldowns = {
        { spellID = 79140, alertThreshold = 10, name = "Vendetta" },
    },
    interruptSpell = { spellID = 1766, name = "Kick", cooldown = 15 },
    defensives = {
        { spellID = 31224, hpThreshold = 0.35, name = "Cloak of Shadows" },
        { spellID = 5277, hpThreshold = 0.40, name = "Evasion" },
    },
    resource = {
        type      = 3, -- Energy
        maxBase   = 120,
        spellCosts = {},
    },
    burstWindows = {},
    prePullChecks = {},
    inferenceRules = {},
    secondaryPowerType = 4, -- Combo Points
}

------------------------------------------------------------------------
-- Outlaw (specID 260)
------------------------------------------------------------------------
RA.SpecEnhancements[260] = {
    majorCooldowns = {
        { spellID = 13750, alertThreshold = 10, name = "Adrenaline Rush" },
    },
    interruptSpell = { spellID = 1766, name = "Kick", cooldown = 15 },
    defensives = {
        { spellID = 31224, hpThreshold = 0.35, name = "Cloak of Shadows" },
        { spellID = 5277, hpThreshold = 0.40, name = "Evasion" },
    },
    resource = {
        type      = 3, -- Energy
        maxBase   = 120,
        spellCosts = {},
    },
    burstWindows = {},
    prePullChecks = {},
    inferenceRules = {},
    secondaryPowerType = 4, -- Combo Points
}

------------------------------------------------------------------------
-- Subtlety (specID 261)
------------------------------------------------------------------------
RA.SpecEnhancements[261] = {
    majorCooldowns = {
        { spellID = 185313, alertThreshold = 10, name = "Shadow Dance" },
        { spellID = 121471, alertThreshold = 10, name = "Shadow Blades" },
        { spellID = 212283, alertThreshold = 5,  name = "Symbols of Death" },
        { spellID = 280719, alertThreshold = 5,  name = "Secret Technique" },
    },

    interruptSpell = { spellID = 1766, name = "Kick", cooldown = 15 },

    defensives = {
        { spellID = 31224, hpThreshold = 0.35, name = "Cloak of Shadows" },
        { spellID = 5277, hpThreshold = 0.40, name = "Evasion" },
    },

    resource = {
        type      = 3, -- Energy
        maxBase   = 120,
        spellCosts = {
            [185438] = { cost = 40 }, -- Shadowstrike
            [196819] = { cost = 35 }, -- Eviscerate
            [12253]  = { cost = 30 }, -- Shuriken Storm
            [196814] = { cost = 15 }, -- Black Powder
        },
    },

    burstWindows = {
        shadowDance  = { trigger = 185313, duration = 8,  label = "Shadow Dance" },
        shadowBlades = { trigger = 121471, duration = 20, label = "Shadow Blades" },
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
        weapon = { type = "aura", spellID = 315584, name = "Instant Poison" }
    },

    inferenceRules = {
        aoeSpells          = { 12253, 196814, 280719 },
        singleTargetSpells = { 185438, 196819, 53 },
        generatorSpells    = { 185438, 12253, 53 },
        spenderSpells      = { 196819, 196814, 280719 },
        burstIndicatorSpells = { 185313, 212283 },
        burstCooldownSpell = 185313, -- Shadow Dance
        burstDuration      = 8,
        executeSpells      = {},
    },

    secondaryPowerType = 4, -- Combo Points
}
