------------------------------------------------------------------------
-- RotaAssist - APL: Death Knight / Frost (specID 251)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.APLData then RA.APLData = {} end

local APL = {
    specID      = 251,
    specName    = "Frost",
    className   = "DEATHKNIGHT",
    version     = "12.0.2",
    lastUpdated = "2026-02-26",
    author      = "RotaAssist Team",
    profiles    = {}
}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 47568,  priority = 1, condition = "charges>=2", note = "Empower Rune Weapon (2 charges)" },
        { spellID = 439843, priority = 2, condition = "cd_ready", note = "Reaper's Mark" },
        { spellID = 51271,  priority = 3, condition = "cd_ready", note = "Pillar of Frost" },
        { spellID = 279302, priority = 4, condition = "cd_ready", note = "Frostwyrm's Fury" },
        { spellID = 49020,  priority = 5, condition = "proc:killing_machine>=2", note = "Obliterate (2x KM)" },
        { spellID = 49184,  priority = 6, condition = "proc:rime", note = "Howling Blast (Rime)" },
        { spellID = 49143,  priority = 7, condition = "resource>80", note = "Frost Strike (Dump RP)" },
        { spellID = 49020,  priority = 8, condition = "proc:killing_machine", note = "Obliterate (KM)" },
        { spellID = 49143,  priority = 9, condition = "always", note = "Frost Strike" },
        { spellID = 49020,  priority = 10, condition = "always", note = "Obliterate" },
        { spellID = 196770, priority = 11, condition = "cd_ready", note = "Remorseless Winter" },
        { spellID = 49184,  priority = 12, condition = "always", note = "Howling Blast (Filler)" }
    },
    aoe = {},
    opener = {},
    majorCooldowns = {
        { spellID = 51271, note = "Pillar of Frost" },
        { spellID = 47568, note = "Empower Rune Weapon" }
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

RA.APLData[251] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
