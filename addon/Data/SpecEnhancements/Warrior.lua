------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Warrior
-- Per-spec configuration for major cooldowns, defensives, resources,
-- burst windows, active mitigation, and pre-pull consumable checks.
-- ウォリアー拡張データ (CD, 防御, リソース, バースト)
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Arms (specID 71)
------------------------------------------------------------------------
RA.SpecEnhancements[71] = {
    majorCooldowns = {
        { spellID = 167105, alertThreshold = 10, name = "Colossus Smash"  },
        { spellID = 227847, alertThreshold = 10, name = "Bladestorm"      },
        { spellID = 107574, alertThreshold = 10, name = "Avatar"          },
    },

    interruptSpell = { spellID = 6552, name = "Pummel", cooldown = 15 },

    defensives = {
        { spellID = 118038, hpThreshold = 0.30, name = "Die by the Sword" },
        { spellID = 97462,  hpThreshold = 0.40, name = "Rallying Cry"     },
    },

    resource = {
        powerType = 1, -- Enum.PowerType.Rage
        maxBase   = 100,
        spellCosts = {
            [12294]  = { cost = 30  },  -- Mortal Strike
            [1464]   = { cost = 20  },  -- Slam
            [163201] = { cost = 20  },  -- Execute
            [845]    = { cost = 20  },  -- Cleave
            [167105] = { cost = 0   },  -- Colossus Smash (no rage cost)
            [227847] = { cost = 0   },  -- Bladestorm (no rage cost)
            [107574] = { cost = 0   },  -- Avatar (no rage cost)
            [7384]   = { cost = 0, gen = 0 },  -- Overpower (free, may generate via talents)
            [260643] = { gen  = 20  },  -- Skullsplitter (rage generator)
            [772]    = { cost = 30  },  -- Rend
        },
    },

    burstWindows = {
        colossus = { trigger = 167105, duration = 10, label = "Colossus Smash" },
        avatar   = { trigger = 107574, duration = 20, label = "Avatar" },
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },

    inferenceRules = {
        aoeSpells = { 227847, 845, 6343 },           -- Bladestorm, Cleave, Thunder Clap
        singleTargetSpells = { 12294, 7384, 1464 },   -- Mortal Strike, Overpower, Slam
        generatorSpells = { 7384, 260643 },            -- Overpower, Skullsplitter
        spenderSpells = { 12294, 163201, 1464, 845 },  -- MS, Execute, Slam, Cleave
        burstIndicatorSpells = {},
        burstCooldownSpell = 167105,  -- Colossus Smash
        burstDuration = 10,
        executeSpells = { 163201 },   -- Execute (below 20% HP or Sudden Death proc)
    },

    secondaryPowerType = nil,
}

------------------------------------------------------------------------
-- Fury (specID 72)
------------------------------------------------------------------------
RA.SpecEnhancements[72] = {
    majorCooldowns = {
        { spellID = 1719,   alertThreshold = 10, name = "Recklessness" },
        { spellID = 228920, alertThreshold = 10, name = "Ravager"      },
        { spellID = 107574, alertThreshold = 10, name = "Avatar"       },
    },

    interruptSpell = { spellID = 6552, name = "Pummel", cooldown = 15 },

    defensives = {
        { spellID = 184364, hpThreshold = 0.30, name = "Enraged Regeneration" },
        { spellID = 97462,  hpThreshold = 0.40, name = "Rallying Cry"         },
    },

    resource = {
        powerType = 1, -- Enum.PowerType.Rage
        maxBase   = 100,
        spellCosts = {
            [184367] = { cost = 80  },  -- Rampage (main spender)
            [85288]  = { gen  = 12  },  -- Raging Blow (generates rage)
            [23881]  = { gen  = 8   },  -- Bloodthirst (generates rage)
            [190411] = { cost = 0   },  -- Whirlwind (free)
            [5308]   = { cost = 20  },  -- Execute
            [228920] = { cost = 0   },  -- Ravager (no cost)
            [1719]   = { cost = 0   },  -- Recklessness (no cost)
            [107574] = { cost = 0   },  -- Avatar (no cost)
            [315720] = { cost = 30  },  -- Onslaught
            [6343]   = { cost = 0, gen = 5 },  -- Thunder Clap
        },
    },

    burstWindows = {
        recklessness = { trigger = 1719, duration = 12, label = "Recklessness" },
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },

    inferenceRules = {
        aoeSpells = { 190411, 228920, 6343 },             -- Whirlwind, Ravager, Thunder Clap
        singleTargetSpells = { 85288, 23881, 184367 },     -- Raging Blow, Bloodthirst, Rampage
        generatorSpells = { 85288, 23881 },                -- Raging Blow, Bloodthirst
        spenderSpells = { 184367, 315720, 5308 },          -- Rampage, Onslaught, Execute
        burstIndicatorSpells = { 335097, 335096 },         -- Crushing Blow, Bloodbath (Recklessness overrides)
        burstCooldownSpell = 1719,  -- Recklessness
        burstDuration = 12,
        executeSpells = { 5308 },    -- Execute (below 20% HP)
    },

    secondaryPowerType = nil,
}
