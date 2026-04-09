------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Warlock
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Demonology (specID 266)
------------------------------------------------------------------------
RA.SpecEnhancements[266] = {
    majorCooldowns = {
        { spellID = 265187, name = "Summon Demonic Tyrant", alertThreshold = 10 },
        { spellID = 104316, name = "Call Dreadstalkers",    alertThreshold = 5  },
        { spellID = 111898, name = "Grimoire: Felguard",    alertThreshold = 5  },
    },
    interruptSpell = { spellID = 89766, name = "Axe Toss (Felguard)", cooldown = 30 },
    defensives = {
        { spellID = 104773, name = "Unending Resolve",  hpThreshold = 0.35 },
        { spellID = 108416, name = "Dark Pact",         hpThreshold = 0.50 },
        { spellID = 6789,   name = "Mortal Coil",       hpThreshold = 0.40 },
    },
    resource = {
        type = 7,   -- Soul Shards
        maxBase  = 5,
        spellCosts = {
            [105174] = 3,
            [104316] = 2,
            [264178] = 0,
            [686] = 0,
        },
    },
    burstWindows = {
        demonicTyrant = { trigger = 265187, duration = 20, label = "Demonic Tyrant" },
    },
    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },
    inferenceRules = {
        aoeSpells            = { 196277, 105174, 104316 },
        singleTargetSpells   = { 264178, 686, 104316, 105174 },
        generatorSpells     = { 686, 264178 },
        spenderSpells       = { 105174, 104316, 196277 },
        burstIndicatorSpells = { 265187 },
        burstCooldownSpell  = 265187,
        burstDuration  = 20,
        executeSpells = {},
    },
    secondaryPowerType = nil,
}
