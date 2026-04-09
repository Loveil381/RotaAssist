------------------------------------------------------------------------
-- RotaAssist - APL: Mage / Frost (specID 64)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.APLData then RA.APLData = {} end

local APL = {
    specID      = 64,
    specName    = "Frost",
    className   = "MAGE",
    version     = "12.0.2",
    lastUpdated = "2026-02-26",
    author      = "RotaAssist Team",
    profiles    = {}
}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 153595, priority = 1, condition = "cd_ready", note = "Comet Storm (Burst)" },
        { spellID = 190356, priority = 2, condition = "buff:freezing_rain", note = "Blizzard (Freezing Rain proc)" },
        { spellID = 44614,  priority = 3, condition = "proc:brain_freeze", note = "Flurry (Brain Freeze)" },
        { spellID = 84714,  priority = 4, condition = "cd_ready", note = "Frozen Orb" },
        { spellID = 199786, priority = 5, condition = "cd_ready", note = "Glacial Spike" },
        { spellID = 190356, priority = 6, condition = "not_buff:splinterstorm", note = "Blizzard (Splinterstorm missing)" },
        { spellID = 30455,  priority = 7, condition = "proc:fingers_of_frost", note = "Ice Lance (Fingers of Frost)" },
        { spellID = 30455,  priority = 8, condition = "stacks:freezing>=6", note = "Ice Lance (Freezing 6+ stacks)" },
        { spellID = 116,    priority = 9, condition = "always", note = "Frostbolt (Filler)" }
    },
    aoe = {},
    opener = {},
    majorCooldowns = {
        { spellID = 12472, note = "Icy Veins" },
        { spellID = 205021, note = "Ray of Frost" }
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

RA.APLData[64] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
