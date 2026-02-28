------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Evoker
-- Per-spec configuration for major cooldowns, defensives, resources,
-- burst windows, active mitigation, and pre-pull consumable checks.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Devastation (specID 1467)
------------------------------------------------------------------------
RA.SpecEnhancements[1467] = {
    majorCooldowns = {
        { spellID = 375087, alertThreshold = 10, name = "Dragonrage"   },
        { spellID = 357210, alertThreshold = 5,  name = "Deep Breath"  }, -- Scalecommander
    },

    interruptSpell = { spellID = 351338, name = "Quell", cooldown = 40 },

    defensives = {
        { spellID = 363916, hpThreshold = 0.40, name = "Obsidian Scales" },
        { spellID = 374227, hpThreshold = 0.50, name = "Zephyr" },
    },

    resource = {
        powerType = 19, -- Enum.PowerType.Essence
        maxBase   = 5,
        spellCosts = {
            [356995] = { cost = 3 },  -- Disintegrate
            [357211] = { cost = 2 },  -- Pyre
            [361469] = { gen  = 1 },  -- Living Flame
            [362969] = { gen  = 1 },  -- Azure Strike
        },
    },

    burstWindows = {
        meta = { trigger = 375087, duration = 18, label = "Dragonrage" }
    },

    inferenceRules = {
        aoeSpells = { 357211, 357210, 436335, 362969 },
        singleTargetSpells = { 356995, 361469 },
        generatorSpells = { 361469, 362969 },
        spenderSpells = { 356995, 357211 },
        burstIndicatorSpells = { 436335 },
        burstCooldownSpell = 375087,  -- Dragonrage
        burstDuration = 22,           -- Account for Animosity extension
        executeSpells = {},
    },

    secondaryPowerType = nil,
}

------------------------------------------------------------------------
-- Augmentation (specID 1473)
------------------------------------------------------------------------
RA.SpecEnhancements[1473] = {
    majorCooldowns = {
        { spellID = 395152, alertThreshold = 5,  name = "Ebon Might" },
        { spellID = 403631, alertThreshold = 10, name = "Breath of Eons" },
    },

    interruptSpell = { spellID = 351338, name = "Quell", cooldown = 40 },

    defensives = {
        { spellID = 363916, hpThreshold = 0.40, name = "Obsidian Scales" },
        { spellID = 374227, hpThreshold = 0.50, name = "Zephyr" },
    },

    resource = {
        powerType = 19,
        maxBase   = 5,
        spellCosts = {
            [395160] = { cost = 3 },  -- Eruption
            [361469] = { gen  = 1 },  -- Living Flame
            [396286] = { cost = 0 },  -- Upheaval
        },
    },

    burstWindows = {
        meta = { trigger = 403631, duration = 10, label = "Breath of Eons" }
    },

    inferenceRules = {
        aoeSpells = { 396286, 395160 },
        singleTargetSpells = { 395160, 361469 },
        generatorSpells = { 361469 },
        spenderSpells = { 395160 },
        burstIndicatorSpells = {},
        burstCooldownSpell = 403631,
        burstDuration = 10,
        executeSpells = {},
    },

    secondaryPowerType = nil,
}

------------------------------------------------------------------------
-- Preservation (specID 1468)
------------------------------------------------------------------------
RA.SpecEnhancements[1468] = {
    majorCooldowns = {
        { spellID = 363534, alertThreshold = 10, name = "Rewind" },
        { spellID = 370960, alertThreshold = 5,  name = "Emerald Communion" },
    },

    interruptSpell = { spellID = 351338, name = "Quell", cooldown = 40 },

    defensives = {
        { spellID = 363916, hpThreshold = 0.40, name = "Obsidian Scales" },
        { spellID = 374227, hpThreshold = 0.50, name = "Zephyr" },
    },

    resource = {
        powerType = 19,
        maxBase   = 5,
        spellCosts = {},
    },

    burstWindows = {},

    inferenceRules = {
        aoeSpells = {},
        singleTargetSpells = { 361469 },
        generatorSpells = { 361469 },
        spenderSpells = {},
        executeSpells = {},
    },

    secondaryPowerType = nil,
}
