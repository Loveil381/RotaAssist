------------------------------------------------------------------------
-- RotaAssist - APL: Warlock / Demonology (specID 266)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.APLData then RA.APLData = {} end

local APL = {
    specID      = 266,
    specName    = "Demonology",
    className   = "WARLOCK",
    version     = "12.0.2",
    lastUpdated = "2026-02-26",
    author      = "RotaAssist Team",
    profiles    = {}
}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 104316, priority = 1, condition = "cd_ready AND resource>=2", note = "Call Dreadstalkers" },
        { spellID = 265187, priority = 2, condition = "cd_ready", note = "Summon Demonic Tyrant" },
        { spellID = 105174, priority = 3, condition = "resource>=3", note = "Hand of Gul'dan (3+ Shards)" },
        { spellID = 264178, priority = 4, condition = "buff:demonic_core", note = "Demonbolt (Demonic Core)" },
        { spellID = 111898, priority = 5, condition = "cd_ready", note = "Grimoire: Felguard" },
        { spellID = 196277, priority = 6, condition = "wild_imps>=6 AND targets>=2", note = "Implosion (6+ imps, 2+ targets)" },
        { spellID = 686,    priority = 7, condition = "always", note = "Shadow Bolt (Filler)" },
    },
    aoe = {
        { spellID = 104316, priority = 1, condition = "cd_ready AND resource>=2", note = "Call Dreadstalkers" },
        { spellID = 105174, priority = 2, condition = "resource>=3", note = "Hand of Gul'dan (3 Shards)" },
        { spellID = 196277, priority = 3, condition = "prev_gcd:hand_of_guldan", note = "Implosion (After HoG)" },
        { spellID = 265187, priority = 4, condition = "cd_ready", note = "Summon Demonic Tyrant" },
        { spellID = 264178, priority = 5, condition = "buff:demonic_core", note = "Demonbolt (Demonic Core)" },
        { spellID = 686,    priority = 6, condition = "always", note = "Shadow Bolt (Filler)" },
    },
    opener = {},
    majorCooldowns = {
        { spellID = 265187, note = "Summon Demonic Tyrant" },
        { spellID = 111898, note = "Grimoire: Felguard" },
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

RA.APLData[266] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
