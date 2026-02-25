------------------------------------------------------------------------
-- RotaAssist - APL: Mage / Fire (specID 63)
-- Basic rotation priority for Fire Mage in WoW 12.0.
-- Phase 1: Simple priority based on cooldown readiness.
------------------------------------------------------------------------

local _, RA = ...

if not RA.APLData then
    RA.APLData = {}
end

RA.APLData[63] = {
    specID   = 63,
    specName = "Fire",
    class    = "MAGE",
    version  = 1,
    author   = "RotaAssist Team",
    rules    = {
        {
            spellID   = 190319,
            name      = "Combustion",
            priority  = 1,
            condition = "ready",
            reason    = "Major DPS cooldown — guaranteed crits during window",
        },
        {
            spellID   = 257541,
            name      = "Phoenix Flames",
            priority  = 2,
            condition = "ready",
            reason    = "Generates Hot Streak — use during Combustion",
        },
        {
            spellID   = 11366,
            name      = "Pyroblast",
            priority  = 3,
            condition = "always",
            reason    = "Cast on Hot Streak proc (instant) or hardcast during Combustion",
        },
        {
            spellID   = 108853,
            name      = "Fire Blast",
            priority  = 4,
            condition = "ready",
            reason    = "Instant cast — converts Heating Up to Hot Streak",
        },
        {
            spellID   = 133,
            name      = "Fireball",
            priority  = 5,
            condition = "always",
            reason    = "Primary filler — chance to proc Heating Up",
        },
        {
            spellID   = 2948,
            name      = "Scorch",
            priority  = 6,
            condition = "always",
            reason    = "Movement filler — use when unable to stand still",
        },
    },
}
