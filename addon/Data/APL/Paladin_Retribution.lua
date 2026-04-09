------------------------------------------------------------------------
-- RotaAssist - APL: Paladin / Retribution (specID 70)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.APLData then RA.APLData = {} end

local APL = {
    specID      = 70,
    specName    = "Retribution",
    className   = "PALADIN",
    version     = "12.0.2",
    lastUpdated = "2026-02-26",
    author      = "RotaAssist Team",
    profiles    = {}
}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 31884,  priority = 1, condition = "cd_ready", note = "Avenging Wrath" },
        { spellID = 343527, priority = 2, condition = "cd_ready", note = "Execution Sentence" },
        { spellID = 427453, priority = 3, condition = "cd_ready", note = "Hammer of Light" },
        { spellID = 53385,  priority = 4, condition = "resource>=5", note = "Divine Storm (5 HP)" },
        { spellID = 255937, priority = 5, condition = "cd_ready", note = "Wake of Ashes" },
        { spellID = 375576, priority = 6, condition = "cd_ready", note = "Divine Toll" },
        { spellID = 184575, priority = 7, condition = "cd_ready", note = "Blade of Justice" },
        { spellID = 24275,  priority = 8, condition = "target_hp<0.20 OR proc", note = "Hammer of Wrath" },
        { spellID = 35395,  priority = 9, condition = "always", note = "Crusader Strike (Filler)" },
        { spellID = 20271,  priority = 10, condition = "cd_ready", note = "Judgment" }
    },
    aoe = {},
    opener = {},
    majorCooldowns = {
        { spellID = 31884, note = "Avenging Wrath" },
        { spellID = 255937, note = "Wake of Ashes" }
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

RA.APLData[70] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
