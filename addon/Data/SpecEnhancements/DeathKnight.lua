------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Death Knight
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Frost (specID 251)
------------------------------------------------------------------------
RA.SpecEnhancements[251] = {
    majorCooldowns = {
        { spellID = 51271, alertThreshold = 10, name = "Pillar of Frost" },
        { spellID = 47568, alertThreshold = 10, name = "Empower Rune Weapon" },
        { spellID = 152279, alertThreshold = 10, name = "Breath of Sindragosa" },
        { spellID = 279302, alertThreshold = 5,  name = "Frostwyrm's Fury" },
    },
    interruptSpell = { spellID = 47528, name = "Mind Freeze", cooldown = 15 },
    defensives = {
        { spellID = 48792, hpThreshold = 0.30, name = "Icebound Fortitude" },
        { spellID = 49998, hpThreshold = 0.40, name = "Death Strike" },
        { spellID = 48707, hpThreshold = 0.60, name = "Anti-Magic Shell" },
    },
    resource = { type = 6, maxBase = 100, spellCosts = {} },  -- Runic Power
    burstWindows = {
        pillar = { trigger = 51271, duration = 12, label = "Pillar of Frost" }
    },
    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },
    inferenceRules = {
        aoeSpells = { 196770, 49184, 279302 },
        singleTargetSpells = { 49020, 49143, 49184 },
        generatorSpells = { 49020, 49184 },
        spenderSpells = { 49143, 279302 },
        burstIndicatorSpells = {},
        burstCooldownSpell = 51271,
        burstDuration = 12,
    executeSpells = {},
    },
    secondaryPowerType = 5, -- Runes (Optional)
}

------------------------------------------------------------------------
-- Unholy (specID 252)
------------------------------------------------------------------------
RA.SpecEnhancements[252] = {
    majorCooldowns = {
        { spellID = 42650,  name = "Army of the Dead",    alertThreshold = 10 },
        { spellID = 63560,  name = "Dark Transformation", alertThreshold = 5  },
        { spellID = 343294, name = "Soul Reaper",         alertThreshold = 5  },
        { spellID = 455397, name = "Raise Abomination",   alertThreshold = 10 },
        { spellID = 49206,  name = "Summon Gargoyle",     alertThreshold = 10 },
    },
    interruptSpell = { spellID = 47528, name = "Mind Freeze", cooldown = 15 },
    defensives = {
        { spellID = 48707,  name = "Anti-Magic Shell",    hpThreshold = 0.60 },
        { spellID = 48792,  name = "Icebound Fortitude",  hpThreshold = 0.35 },
        { spellID = 49039,  name = "Lichborne",           hpThreshold = 0.40 },
    },
    resource = {
        type = 6,   -- Runic Power
        maxBase  = 100,
        runes = { max = 6, simultaneous_recharge = 3 },
        spellCosts = {
            [47541] = 30,
            [207317] = 30,
            [85948] = "2 Runes",
            [460461] = "1 Rune",
            [55090] = "1 Rune",
            [460463] = "1 Rune",
        },
    },
    burstWindows = {
        armyOfTheDead = { trigger = 42650,  duration = 15, label = "Army of the Dead"  },
        darkTransformation = { trigger = 63560,  duration = 15, label = "Dark Transformation" },
        summonGargoyle = { trigger = 49206,  duration = 25, label = "Summon Gargoyle" },
    },
    prePullChecks = {
        flask = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food  = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune  = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },
    inferenceRules = {
        aoeSpells            = { 207317, 460461, 77575, 343294 },
        singleTargetSpells   = { 47541, 55090, 85948, 460463 },
        generatorSpells     = { 85948, 460461, 55090, 460463 },
        spenderSpells       = { 47541, 207317, 343294 },
        burstIndicatorSpells = { 42650, 63560, 49206 },
        burstCooldownSpell  = 42650,
        burstDuration  = 15,
        executeSpells = { 343294 },
    },
    secondaryPowerType = 5, -- Runes
}
