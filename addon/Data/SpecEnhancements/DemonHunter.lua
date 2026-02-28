------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: Demon Hunter
-- Per-spec configuration for major cooldowns, defensives, resources,
-- burst windows, active mitigation, and pre-pull consumable checks.
-- デーモンハンター拡張データ (CD, 防御, リソース, バースト)
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- Havoc (specID 577)
------------------------------------------------------------------------
RA.SpecEnhancements[577] = {
    --- Major cooldowns to track and alert on
    majorCooldowns = {
        { spellID = 191427, alertThreshold = 10, name = "Metamorphosis"   },
        { spellID = 370965, alertThreshold = 5,  name = "The Hunt"        },
        { spellID = 258860, alertThreshold = 5,  name = "Essence Break"   },
    },

    interruptSpell = { spellID = 183752, name = "Disrupt", cooldown = 15 },

    --- Defensive spells with HP% thresholds
    defensives = {
        { spellID = 196718, hpThreshold = 0.35, name = "Darkness" },
        { spellID = 198589, hpThreshold = 0.50, name = "Blur" },
    },

    --- Resource info for simulation and UI
    resource = {
        powerType = 17, -- Enum.PowerType.Fury
        maxBase   = 120,
        spellCosts = {
            [162794] = { cost = 40  },  -- Chaos Strike / Annihilation
            [162243] = { gen  = 40  },  -- Demon's Bite (Only if NOT using Demon Blades)
            [370965] = { cost = 0   },  -- The Hunt
            [188499] = { cost = 35  },  -- Blade Dance
            [198013] = { cost = 30  },  -- Eye Beam
            [258920] = { gen  = 20  },  -- Immolation Aura
            [232893] = { gen  = 40  },  -- Felblade
            [195072] = { cost = 0   },  -- Fel Rush
            [198793] = { cost = 0, gen = 0 },  -- Vengeful Retreat
        },
    },

    burstWindows = {
        meta = { trigger = 191427, duration = 24, label = "Metamorphosis" }
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
        weapon = nil -- Havoc doesn't strictly require weapon buffs pre-pull usually
    },

    inferenceRules = {
        aoeSpells = { 188499, 198013, 342817, 258920 },
        singleTargetSpells = { 162794, 232893 }, -- [162243] Demon's Bite (当天赋 Demon Blades 时此技能不存在)
        generatorSpells = { 232893 },           -- [162243] Demon's Bite (当天赋 Demon Blades 时此技能不存在)
        spenderSpells = { 162794, 188499, 258860 },
        burstIndicatorSpells = { 210152, 201427 },
        burstCooldownSpell = 191427,  -- Meta
        burstDuration = 24,
        executeSpells = {},  -- Havoc has no explicit execute spells
    },

    --- Secondary power type (non-secret).
    --- Havoc Fury is PRIMARY (secret in combat). No true secondary.
    --- Soul Fragments tracked via aura whitelist, not UnitPower.
    secondaryPowerType = nil,
}

------------------------------------------------------------------------
-- Vengeance (specID 581)
------------------------------------------------------------------------
RA.SpecEnhancements[581] = {
    majorCooldowns = {
        { spellID = 187827, alertThreshold = 10, name = "Metamorphosis (Vengeance)" },
        { spellID = 212084, alertThreshold = 5,  name = "Fel Devastation"           },
        { spellID = 204021, alertThreshold = 5,  name = "Fiery Brand"               },
    },

    interruptSpell = { spellID = 183752, name = "Disrupt", cooldown = 15 },

    activeMitigation = {
        { spellID = 203720, name = "Demon Spikes", alwaysTrack = true, maxCharges = 2 }
    },

    defensives = {
        { spellID = 187827, hpThreshold = 0.30, name = "Metamorphosis"     },
        { spellID = 196718, hpThreshold = 0.40, name = "Darkness"          },
        { spellID = 204021, hpThreshold = 0.50, name = "Fiery Brand"       },
    },

    resource = {
        powerType = 17, -- Fury
        maxBase   = 100,
        spellCosts = {
            [247454] = { cost = 40  },  -- Spirit Bomb
            [263642] = { cost = 0   },  -- Fracture
            [204596] = { cost = 0   },  -- Sigil of Flame
            [212084] = { cost = 50  },  -- Fel Devastation
        },
    },

    burstWindows = {
        meta = { trigger = 187827, duration = 15, label = "Metamorphosis" }
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },

    inferenceRules = {
        aoeSpells = { 247454, 258920, 204596, 320341 },
        singleTargetSpells = { 228477, 263642 },
        generatorSpells = { 263642, 203782 },
        spenderSpells = { 228477, 247454, 212084 },
        burstIndicatorSpells = {},
        burstCooldownSpell = 212084,  -- Fel Devastation
        burstDuration = 2,
        mitigationSpells = { 203720 },  -- Demon Spikes
        soulFragmentSpender = 247454,  -- Spirit Bomb
        executeSpells = {},  -- Vengeance has no explicit execute spells
    },

    secondaryPowerType = nil,
}

------------------------------------------------------------------------
-- Devourer (specID 1480)
-- ⚠ VERIFY: specID 1480 and the spellIDs below are placeholders
-- based on datamining. Needs to be verified on 12.0 live servers.
------------------------------------------------------------------------
RA.SpecEnhancements[1480] = {
    majorCooldowns = {
        -- VERIFY: Placeholder spellID, needs live server verification
        { spellID = 442508, alertThreshold = 5,  name = "Void Metamorphosis" },
        { spellID = 442525, alertThreshold = 10, name = "Soul Immolation"    },
        { spellID = 442520, alertThreshold = 5,  name = "Voidblade"          },
    },

    interruptSpell = { spellID = 183752, name = "Disrupt", cooldown = 15 },

    defensives = {
        { spellID = 196718, hpThreshold = 0.35, name = "Darkness" },
        { spellID = 198589, hpThreshold = 0.50, name = "Blur" },
    },

    resource = {
        powerType = 17,  -- Enum.PowerType.Fury (Assuming Devourer uses Fury)
        maxBase   = 100,
        spellCosts = {
            -- VERIFY: Placeholder spellID, needs live server verification
            [442507] = { cost = 30 },   -- Void Ray
            [442501] = { cost = 0  },   -- Consume
            [442515] = { cost = 0  },   -- Reap
            [442510] = { cost = 0  },   -- Collapsing Star
        },
    },

    burstWindows = {
        -- VERIFY: Placeholder spellID, needs live server verification
        meta = { trigger = 442508, duration = 20, label = "Void Phase" }
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },

    inferenceRules = {
        aoeSpells = { 442507, 258920 },
        singleTargetSpells = { 442501, 442515 },
        generatorSpells = { 442501, 442515 },
        spenderSpells = { 442507, 442510 },
        burstIndicatorSpells = {},
        burstCooldownSpell = 442508,  -- Void Metamorphosis
        burstDuration = 20,
        executeSpells = {},
    },

    secondaryPowerType = nil,
}
