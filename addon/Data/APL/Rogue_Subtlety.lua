------------------------------------------------------------------------
-- RotaAssist - APL: Rogue / Subtlety  (specID 261)
-- Rotation priority for Subtlety Rogue in WoW 12.0 Midnight.
------------------------------------------------------------------------

local _, RA = ...

if not RA.APLData then
    RA.APLData = {}
end

------------------------------------------------------------------------
-- Metadata
------------------------------------------------------------------------
local APL             = {}
APL.specID            = 261
APL.specName          = "Subtlety"
APL.className         = "ROGUE"
APL.version           = "12.0.1"
APL.lastUpdated       = "2026-02-27"
APL.author            = "RotaAssist Team"

------------------------------------------------------------------------
-- PROFILES
------------------------------------------------------------------------
APL.profiles = {}

APL.profiles["default"] = {

    ------------------------------------
    -- SINGLE TARGET
    ------------------------------------
    singleTarget = {
        -- ① Shadow Dance (185313)
        {
            spellID   = 185313,
            priority  = 1,
            condition = "cd_ready AND not_in_dance",
            note      = "Shadow Dance — manual activation. Align with burst",
            displayPriority = 1,
            confidence = 0.8,
            tags = {"burst", "major"},
        },
        -- ② Symbols of Death (212283)
        {
            spellID   = 212283,
            priority  = 2,
            condition = "cd_ready",
            note      = "Symbols of Death — use on cooldown",
            displayPriority = 2,
            confidence = 0.9,
            tags = {"burst"},
        },
        -- ③ Secret Technique (280719)
        {
            spellID   = 280719,
            priority  = 3,
            condition = "cd_ready AND cp >= 5",
            note      = "Secret Technique — burst finisher",
            displayPriority = 3,
            confidence = 0.9,
            tags = {"burst"},
        },
        -- ④ Shadowstrike (185438)
        {
            spellID   = 185438,
            priority  = 4,
            condition = "in_dance",
            note      = "Shadowstrike — main generator during Dance",
            displayPriority = 4,
            confidence = 0.85,
            tags = {"sustain"},
        },
        -- ⑤ Eviscerate (196819)
        {
            spellID   = 196819,
            priority  = 5,
            condition = "cp >= 5",
            note      = "Eviscerate — single target spender",
            displayPriority = 5,
            confidence = 0.85,
            tags = {"sustain"},
        },
        -- ⑥ Backstab (53)
        {
            spellID   = 53,
            priority  = 6,
            condition = "always",
            note      = "Backstab — filler generator",
            displayPriority = 6,
            confidence = 0.7,
            tags = {"sustain"},
        },
    },

    ------------------------------------
    -- AOE (3+ targets)
    ------------------------------------
    aoe = {
        { spellID = 185313, priority = 1, condition = "cd_ready AND not_in_dance", targetCount = 3, note = "Shadow Dance", displayPriority = 1, confidence = 0.8, tags = {"burst", "aoe"} },
        { spellID = 212283, priority = 2, condition = "cd_ready",  targetCount = 3, note = "Symbols of Death", displayPriority = 2, confidence = 0.9, tags = {"burst", "aoe"} },
        { spellID = 280719, priority = 3, condition = "cd_ready AND cp >= 5", targetCount = 3, note = "Secret Technique", displayPriority = 3, confidence = 0.9, tags = {"burst", "aoe"} },
        { spellID = 196814, priority = 4, condition = "cp >= 5", targetCount = 3, note = "Black Powder — AoE spender", displayPriority = 4, confidence = 0.85, tags = {"aoe"} },
        { spellID = 12253,  priority = 5, condition = "always", targetCount = 3, note = "Shuriken Storm — AoE builder", displayPriority = 5, confidence = 0.8, tags = {"aoe"} },
    },

    ------------------------------------
    -- OPENER
    ------------------------------------
    opener = {
        { spellID = 121471, step = 1, note = "Shadow Blades" },
        { spellID = 185438, step = 2, note = "Shadowstrike" },
        { spellID = 185313, step = 3, note = "Shadow Dance" },
        { spellID = 212283, step = 4, note = "Symbols of Death" },
        { spellID = 280719, step = 5, note = "Secret Technique" },
        { spellID = 196819, step = 6, note = "Eviscerate" },
    },

    ------------------------------------
    -- MAJOR COOLDOWNS (manual reminders)
    ------------------------------------
    majorCooldowns = {
        { spellID = 121471, note = "Shadow Blades — major CD" },
        { spellID = 185313, note = "Shadow Dance — manual activation" },
    },
}

------------------------------------------------------------------------
-- Phase 1 backward-compat: flatten singleTarget into a flat `rules` array
-- so the current APLEngine can consume it as-is.
------------------------------------------------------------------------
local defaultProfile = APL.profiles["default"]
local rules = {}
if defaultProfile and defaultProfile.singleTarget then
    for _, entry in ipairs(defaultProfile.singleTarget) do
        rules[#rules + 1] = {
            spellID   = entry.spellID,
            name      = entry.note or ("Spell#" .. entry.spellID),
            priority  = entry.priority,
            condition = (entry.condition == "cd_ready" or entry.condition:find("cd_ready")) and "ready" or "always",
            reason    = entry.note or "",
        }
    end
end

------------------------------------------------------------------------
-- Register with the global APL data table
------------------------------------------------------------------------
RA.APLData[261] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,          -- Phase 1 flat list
    profiles = APL.profiles,   -- Phase 2 rich profiles
}
