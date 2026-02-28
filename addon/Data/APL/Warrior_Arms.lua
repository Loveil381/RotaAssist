------------------------------------------------------------------------
-- RotaAssist - APL: Warrior / Arms (specID 71)
-- Basic rotation priority for Arms Warrior in WoW 12.0.
-- Phase 1: Simple priority based on cooldown readiness.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

if not RA.APLData then
    RA.APLData = {}
end

RA.APLData[71] = {
    specID   = 71,
    specName = "Arms",
    class    = "WARRIOR",
    version  = 1,
    author   = "RotaAssist Team",
    rules    = {
        {
            spellID   = 167105,
            name      = "Colossus Smash",
            priority  = 1,
            condition = "ready",
            reason    = "Apply Colossus Smash debuff for burst window",
        },
        {
            spellID   = 227847,
            name      = "Bladestorm",
            priority  = 2,
            condition = "ready",
            reason    = "Major AoE/ST cooldown during Colossus Smash window",
        },
        {
            spellID   = 107574,
            name      = "Avatar",
            priority  = 3,
            condition = "ready",
            reason    = "Damage amplifier — align with Colossus Smash",
        },
        {
            spellID   = 12294,
            name      = "Mortal Strike",
            priority  = 4,
            condition = "ready",
            reason    = "Core rotational ability — highest rage-per-damage",
        },
        {
            spellID   = 7384,
            name      = "Overpower",
            priority  = 5,
            condition = "always",
            reason    = "Filler — generates Overpower stacks",
        },
        {
            spellID   = 1464,
            name      = "Slam",
            priority  = 6,
            condition = "always",
            reason    = "Rage dump filler when nothing else available",
        },
    },
}
