------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Paladin
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Retribution (specID 70)
------------------------------------------------------------------------
RA.SpecEnhancements[70] = {
    majorCooldowns = {
        { spellID = 31884, alertThreshold = 10, name = "Avenging Wrath" },
        { spellID = 255937, alertThreshold = 5,  name = "Wake of Ashes" },
        { spellID = 375576, alertThreshold = 5,  name = "Divine Toll" },
        { spellID = 343527, alertThreshold = 5,  name = "Execution Sentence" },
    },
    interruptSpell = { spellID = 96231, name = "Rebuke", cooldown = 15 },
    defensives = {
        { spellID = 642, hpThreshold = 0.15, name = "Divine Shield" },
        { spellID = 633, hpThreshold = 0.20, name = "Lay on Hands" },
        { spellID = 85673, hpThreshold = 0.40, name = "Word of Glory" },
        { spellID = 184662, hpThreshold = 0.50, name = "Shield of Vengeance" },
    },
    resource = { powerType = 9, maxBase = 5, spellCosts = {} },  -- Holy Power
    burstWindows = {
        avengingWrath = { trigger = 31884, duration = 20, label = "Avenging Wrath" }
    },
    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },
    inferenceRules = {
        aoeSpells = { 53385, 375576 },
        singleTargetSpells = { 184575, 35395, 20271, 24275 },
        generatorSpells = { 184575, 35395, 255937 },
        spenderSpells = { 53385, 343527, 427453 },
        burstIndicatorSpells = {},
        burstCooldownSpell = 31884,
        burstDuration = 20,
        executeSpells = { 24275 },
    },
    secondaryPowerType = nil,
}
