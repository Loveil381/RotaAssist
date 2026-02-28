------------------------------------------------------------------------
-- RotaAssist - APL Template
-- This file serves as a template for community contributors to add
-- new specialization APL (Action Priority List) definitions.
--
-- HOW TO ADD A NEW SPEC:
--   1. Copy this file and rename it to <Class>_<Spec>.lua
--      Example: Paladin_Retribution.lua
--   2. Fill in the specID (see Data/SpecInfo.lua for all specIDs)
--   3. Define your priority rules in the `rules` table
--   4. Add the filename to RotaAssist.toc (in the Data/APL section)
--   5. Test with /reload and /ra debug
--
-- RULE FORMAT:
--   {
--       spellID   = 12345,          -- WoW spellID (required)
--       name      = "Ability Name", -- Human-readable name (required)
--       priority  = 1,              -- Lower number = higher priority (required)
--       condition = "ready",        -- Phase 1: "ready" or "always" (required)
--                                   -- Phase 2 will add expression parsing
--       reason    = "Why this",     -- Explanation for tooltip (optional)
--   }
--
-- CONDITION VALUES (Phase 1):
--   "ready"  → fires only when the spell is off cooldown
--   "always" → always recommends this spell at its priority level
--
-- TIPS:
--   - Put your most important rotational ability at priority 1
--   - Major cooldowns should be lower priority (higher number)
--   - Only include spells from WhitelistSpells.lua + basic rotational spells
--   - Test each rule individually before combining
--
-- EXAMPLE (Fury Warrior):
--   { spellID = 1719, name = "Recklessness", priority = 1, condition = "ready", reason = "Major DPS cooldown" },
--   { spellID = 85288, name = "Raging Blow", priority = 2, condition = "ready", reason = "Core filler" },
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

-- Initialize the APL data registry if it doesn't exist
if not RA.APLData then
    RA.APLData = {}
end

-- Template: Uncomment and modify for your spec
--[[
local SPEC_ID = 0  -- Replace with actual specID from SpecInfo.lua

RA.APLData[SPEC_ID] = {
    specID   = SPEC_ID,
    specName = "SpecName",      -- e.g. "Retribution"
    class    = "CLASSNAME",     -- e.g. "PALADIN"
    version  = 1,               -- bump when modifying rules
    author   = "YourName",
    rules    = {
        {
            spellID   = 0,
            name      = "Ability Name",
            priority  = 1,
            condition = "ready",
            reason    = "Reason for this priority",
        },
        -- Add more rules here...
    },
}
]]--
