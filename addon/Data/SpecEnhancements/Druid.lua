------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Druid
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Balance (specID 102)
------------------------------------------------------------------------
RA.SpecEnhancements[102] = {
    majorCooldowns = {
        { spellID = 194223, alertThreshold = 10, name = "Celestial Alignment" },
        { spellID = 102560, alertThreshold = 10, name = "Incarnation: Chosen of Elune" },
    },

    interruptSpell = { spellID = 106839, name = "Skull Bash", cooldown = 15 },

    defensives = {
        { spellID = 22812, hpThreshold = 0.50, name = "Barkskin" },
        { spellID = 108238, hpThreshold = 0.40, name = "Renewal" },
    },

    resource = {
        powerType = 8, -- Enum.PowerType.LunarPower
        maxBase   = 100,
        spellCosts = {
            [78674]  = { cost = 40 },  -- Starsurge
            [191034] = { cost = 50 },  -- Starfall
            [190984] = { gen = 8 },    -- Wrath
            [194153] = { gen = 10 },   -- Starfire
            [8921]   = { gen = 2 },    -- Moonfire
            [93402]  = { gen = 2 },    -- Sunfire
            [202347] = { gen = 8 },    -- Stellar Flare
        },
    },

    burstWindows = {
        meta = { trigger = 194223, duration = 20, label = "Celestial Alignment" }
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },

    inferenceRules = {
        aoeSpells = { 191034, 194153, 93402 },
        singleTargetSpells = { 78674, 190984, 8921, 202347 },
        generatorSpells = { 190984, 194153, 8921, 93402, 202347 },
        spenderSpells = { 78674, 191034 },
        burstIndicatorSpells = { 78674 },
        burstCooldownSpell = 194223,
        burstDuration = 20,
        executeSpells = {},
    },

    secondaryPowerType = nil,
}
