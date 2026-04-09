------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Mage
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Frost (specID 64)
------------------------------------------------------------------------
RA.SpecEnhancements[64] = {
    majorCooldowns = {
        { spellID = 12472, alertThreshold = 10, name = "Icy Veins" },
        { spellID = 205021, alertThreshold = 5,  name = "Ray of Frost" },
        { spellID = 84714, alertThreshold = 5,  name = "Frozen Orb" },
    },
    interruptSpell = { spellID = 2139, name = "Counterspell", cooldown = 24 },
    defensives = {
        { spellID = 45438, hpThreshold = 0.20, name = "Ice Block" },
        { spellID = 55342, hpThreshold = 0.40, name = "Mirror Image" },
        { spellID = 11426, hpThreshold = 0.60, name = "Ice Barrier" },
    },
    resource = { type = 0, maxBase = 100000, spellCosts = {} },  -- Mana
    burstWindows = {
        icyVeins = { trigger = 12472, duration = 25, label = "Icy Veins" }
    },
    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },
    inferenceRules = {
        aoeSpells = { 190356, 153595, 84714 },
        singleTargetSpells = { 116, 30455, 44614, 199786 },
        generatorSpells = { 116 },
        spenderSpells = { 30455, 44614, 199786 },
        burstIndicatorSpells = {},
        burstCooldownSpell = 12472,
        burstDuration = 25,
        executeSpells = {},
    },
    secondaryPowerType = nil,
}

------------------------------------------------------------------------
-- Fire (specID 63)
------------------------------------------------------------------------
RA.SpecEnhancements[63] = {
    majorCooldowns = {
        { spellID = 190319, alertThreshold = 10, name = "Combustion" },
    },
    interruptSpell = { spellID = 2139, name = "Counterspell", cooldown = 24 },
    defensives = {
        { spellID = 45438, hpThreshold = 0.20, name = "Ice Block" },
        { spellID = 55342, hpThreshold = 0.40, name = "Mirror Image" },
        { spellID = 235313, hpThreshold = 0.60, name = "Blazing Barrier" },
    },
    resource = { type = 0, maxBase = 100000, spellCosts = {} },  -- Mana
    burstWindows = {
        combustion = { trigger = 190319, duration = 12, label = "Combustion" }
    },
    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },
    inferenceRules = {
        aoeSpells = { 257541, 153561 },
        singleTargetSpells = { 133, 11366, 108853, 2948 },
        generatorSpells = { 133 },
        spenderSpells = { 11366, 108853 },
        burstIndicatorSpells = {},
        burstCooldownSpell = 190319,
        burstDuration = 12,
        executeSpells = { 2948 },
    },
    secondaryPowerType = nil,
}

------------------------------------------------------------------------
-- Arcane (specID 62)
------------------------------------------------------------------------
RA.SpecEnhancements[62] = {
    majorCooldowns = {
        { spellID = 365362, name = "Arcane Surge",       alertThreshold = 10 },
        { spellID = 321507, name = "Touch of the Magi",  alertThreshold = 5  },
        { spellID = 12042,  name = "Arcane Power",       alertThreshold = 5  },
    },
    interruptSpell = { spellID = 2139, name = "Counterspell", cooldown = 24 },
    defensives = {
        { spellID = 45438,  name = "Ice Block",           hpThreshold = 0.20 },
        { spellID = 235450, name = "Prismatic Barrier",   hpThreshold = 0.50 },
        { spellID = 342245, name = "Alter Time",          hpThreshold = 0.35 },
    },
    resource = {
        type   = 0,    -- Mana
        maxBase    = 250000,
        spellCosts = {
            [30451] = "variable (scales with Arcane Charges)",
            [44425] = 0,
            [5143]  = 0,
            [153626] = 0,
        },
    },
    secondaryResource = {
        name = "Arcane Charges",
        max  = 4,
        buildWith   = { 30451, 153626, 44425 },  -- Blast, Orb, Barrage resets
        salvoMax    = { Spellslinger = 20, Sunfury = 25 },
    },
    burstWindows = {
        arcaneSurge = { trigger = 365362, duration = 15, label = "Arcane Surge" },
        touchOfTheMagi = { trigger = 321507, duration = 12, label = "Touch of the Magi" },
    },
    prePullChecks = {
        flask = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food  = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune  = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },
    inferenceRules = {
        aoeSpells            = { 44425, 153626, 1449, 321507 },
        singleTargetSpells   = { 30451, 5143, 44425 },
        generatorSpells     = { 30451, 153626, 1449 },
        spenderSpells       = { 44425, 5143, 365362 },
        burstIndicatorSpells = { 365362, 321507 },
        burstCooldownSpell  = 365362,
        burstDuration  = 15,
        executeSpells = {},
    },
    secondaryPowerType = 16, -- Arcane Charges
}
