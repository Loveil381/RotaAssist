------------------------------------------------------------------------
-- RotaAssist - APL: Warrior / Fury (specID 72)
-- Basic rotation priority for Fury Warrior in WoW 12.0.
-- Phase 1: Simple priority based on cooldown readiness.
------------------------------------------------------------------------

local _, RA = ...

if not RA.APLData then
    RA.APLData = {}
end

RA.APLData[72] = {
    specID   = 72,
    specName = "Fury",
    class    = "WARRIOR",
    version  = 1,
    author   = "RotaAssist Team",
    rules    = {
        {
            spellID   = 1719,
            name      = "Recklessness",
            priority  = 1,
            condition = "ready",
            reason    = "Major DPS cooldown — use on pull and on CD",
        },
        {
            spellID   = 107574,
            name      = "Avatar",
            priority  = 2,
            condition = "ready",
            reason    = "Damage amplifier — align with Recklessness",
        },
        {
            spellID   = 228920,
            name      = "Ravager",
            priority  = 3,
            condition = "ready",
            reason    = "Strong AoE/ST damage during burst window",
        },
        {
            spellID   = 85288,
            name      = "Raging Blow",
            priority  = 4,
            condition = "ready",
            reason    = "Core filler — generates rage and Raging Blow stacks",
        },
        {
            spellID   = 23881,
            name      = "Bloodthirst",
            priority  = 5,
            condition = "ready",
            reason    = "Core rotational — generates rage, chance to Enrage",
        },
        {
            spellID   = 184367,
            name      = "Rampage",
            priority  = 6,
            condition = "always",
            reason    = "Rage spender — triggers Enrage",
        },
        {
            spellID   = 190411,
            name      = "Whirlwind",
            priority  = 7,
            condition = "always",
            reason    = "AoE filler / makes next 2 abilities hit all targets",
        },
    },
}
