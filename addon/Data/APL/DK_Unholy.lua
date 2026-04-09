------------------------------------------------------------------------
-- RotaAssist - APL: Death Knight / Unholy (specID 252)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.APLData then RA.APLData = {} end

local APL = {
    specID      = 252,
    specName    = "Unholy",
    className   = "DEATHKNIGHT",
    version     = "12.0.2",
    lastUpdated = "2026-02-26",
    author      = "RotaAssist Team",
    profiles    = {}
}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 77575,  priority = 1, condition = "debuff_missing:virulent_plague", note = "Outbreak" },
        { spellID = 42650,  priority = 2, condition = "cd_ready", note = "Army of the Dead / Raise Abomination" },
        { spellID = 63560,  priority = 3, condition = "cd_ready", note = "Dark Transformation" },
        { spellID = 49206,  priority = 4, condition = "cd_ready", note = "Summon Gargoyle" },
        { spellID = 460463, priority = 5, condition = "cd_ready", note = "Putrefy" },
        { spellID = 343294, priority = 6, condition = "cd_ready OR target_hp<0.35", note = "Soul Reaper" },
        { spellID = 460461, priority = 7, condition = "debuff_missing:festering_scythe", note = "Festering Scythe" },
        { spellID = 47541,  priority = 8, condition = "proc:sudden_doom OR resource>=80 OR buff:gargoyle", note = "Death Coil (Sudden Doom/Dump/Gargoyle)" },
        { spellID = 55090,  priority = 9, condition = "debuff:festering_wound>=4", note = "Scourge Strike (Consume)" },
        { spellID = 85948,  priority = 10, condition = "debuff:festering_wound<4", note = "Festering Strike (Apply)" },
        { spellID = 47541,  priority = 11, condition = "resource>40", note = "Death Coil (Dump RP)" },
        { spellID = 55090,  priority = 12, condition = "always", note = "Scourge Strike (Filler)" },
    },
    aoe = {
        { spellID = 77575,  priority = 1, condition = "debuff_missing:virulent_plague", note = "Outbreak" },
        { spellID = 42650,  priority = 2, condition = "cd_ready", note = "Army of the Dead" },
        { spellID = 63560,  priority = 3, condition = "cd_ready", note = "Dark Transformation" },
        { spellID = 460463, priority = 4, condition = "cd_ready", note = "Putrefy" },
        { spellID = 460461, priority = 5, condition = "debuff_missing:festering_scythe", note = "Festering Scythe" },
        { spellID = 207317, priority = 6, condition = "proc:sudden_doom OR resource>=80", note = "Epidemic (AoE RP Dump)" },
        { spellID = 55090,  priority = 7, condition = "debuff:festering_wound>=4", note = "Scourge Strike (Consume)" },
        { spellID = 85948,  priority = 8, condition = "debuff:festering_wound<2", note = "Festering Strike (Apply)" },
        { spellID = 207317, priority = 9, condition = "resource>40", note = "Epidemic (Dump RP)" },
    },
    opener = {},
    majorCooldowns = {
        { spellID = 42650, note = "Army of the Dead" },
        { spellID = 63560, note = "Dark Transformation" },
        { spellID = 49206, note = "Summon Gargoyle" },
    }
}

local defaultProfile = APL.profiles["default"]
local rules = {}
for _, entry in ipairs(defaultProfile.singleTarget) do
    rules[#rules + 1] = {
        spellID   = entry.spellID,
        name      = entry.note,
        priority  = entry.priority,
        condition = (entry.condition == "cd_ready" or entry.condition:find("cd_ready")) and "ready" or "always",
        reason    = entry.note,
    }
end

RA.APLData[252] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
