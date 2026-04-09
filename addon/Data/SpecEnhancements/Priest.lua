------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Priest
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Shadow (specID 258)
------------------------------------------------------------------------
RA.SpecEnhancements[258] = {
    majorCooldowns = {
        { spellID = 228260, name = "Voidform",      alertThreshold = 10 },
        { spellID = 10060,  name = "Power Infusion", alertThreshold = 10 },
        { spellID = 263346, name = "Void Torrent",  alertThreshold = 5  },
        { spellID = 120644, name = "Halo",          alertThreshold = 5  },
        { spellID = 451329, name = "Tentacle Slam", alertThreshold = 5  },
    },
    interruptSpell = { spellID = 15487, name = "Silence", cooldown = 45 },
    defensives = {
        { spellID = 47585, name = "Dispersion",       hpThreshold = 0.25 },
        { spellID = 586,   name = "Fade",             hpThreshold = 0.80 },
        { spellID = 19236, name = "Desperate Prayer", hpThreshold = 0.40 },
    },
    resource = {
        type = 13, -- Insanity
        maxBase = 100,
        spellCosts = {
            [451840] = 50,
            [8092]   = 0,
            [228266] = 0,
            [451843] = 0,
            [263346] = 0,
            [15407]  = 0,
            [391403] = 0,
        },
    },
    dots = {
        { spellID = 34914,  name = "Vampiric Touch",     duration = 21 },
        { spellID = 589,    name = "Shadow Word: Pain",   duration = 16 },
        { spellID = 451840, name = "Shadow Word: Madness", duration = 12, rollover = true },
    },
    burstWindows = {
        voidform = { trigger = 228260, name = "Voidform", duration = 15 },
        powerInfusion = { trigger = 10060, name = "Power Infusion", duration = 20 },
    },
    prePullChecks = {
        flask = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food  = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune  = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },
    inferenceRules = {
        aoeSpells            = { 451843, 120644, 451329, 207317 },
        singleTargetSpells   = { 451840, 8092, 228266, 263346, 15407 },
        generatorSpells     = { 8092, 228266, 451843, 263346, 15407 },
        spenderSpells       = { 451840 },
        burstIndicatorSpells = { 228260, 10060 },
        burstCooldownSpell  = 228260,
        burstDuration  = 15,
        executeSpells = {},
    },
    secondaryPowerType = nil,
}
