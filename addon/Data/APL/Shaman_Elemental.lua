------------------------------------------------------------------------
-- RotaAssist - APL: Shaman / Elemental (specID 262)
------------------------------------------------------------------------

local _, RA = ...

if not RA.APLData then
    RA.APLData = {}
end

local APL             = {}
APL.specID            = 262
APL.specName          = "Elemental"
APL.className         = "SHAMAN"
APL.version           = "12.0.1"
APL.author            = "RotaAssist Team"

APL.profiles = {}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 198067, priority = 1, condition = "cd_ready", note = "Fire Elemental", displayPriority = 1, confidence = 0.9, tags = {"burst", "major"} },
        { spellID = 191634, priority = 2, condition = "cd_ready", note = "Stormkeeper", displayPriority = 2, confidence = 0.85, tags = {"burst"} },
        { spellID = 188389, priority = 3, condition = "always",   note = "Flame Shock (Refresh)", displayPriority = 3, confidence = 0.85, tags = {"sustain"} },
        { spellID = 8042,   priority = 4, condition = "resource_above_60", note = "Earth Shock", displayPriority = 4, confidence = 0.8, tags = {"sustain"} },
        { spellID = 51505,  priority = 5, condition = "cd_ready", note = "Lava Burst", displayPriority = 5, confidence = 0.8, tags = {"sustain"} },
        { spellID = 210714, priority = 6, condition = "cd_ready", note = "Icefury", displayPriority = 6, confidence = 0.75, tags = {"sustain"} },
        { spellID = 188196, priority = 7, condition = "always",   note = "Lightning Bolt", displayPriority = 7, confidence = 0.7, tags = {"sustain"} },
    },
    aoe = {
        { spellID = 198067, priority = 1, condition = "cd_ready", targetCount = 3, note = "Fire Elemental", displayPriority = 1, confidence = 0.9, tags = {"aoe", "burst"} },
        { spellID = 191634, priority = 2, condition = "cd_ready", targetCount = 3, note = "Stormkeeper", displayPriority = 2, confidence = 0.9, tags = {"aoe", "burst"} },
        { spellID = 61882,  priority = 3, condition = "resource_above_60", targetCount = 3, note = "Earthquake", displayPriority = 3, confidence = 0.85, tags = {"aoe"} },
        { spellID = 188389, priority = 4, condition = "always",   targetCount = 3, note = "Flame Shock", displayPriority = 4, confidence = 0.8, tags = {"aoe"} },
        { spellID = 51505,  priority = 5, condition = "cd_ready", targetCount = 3, note = "Lava Burst", displayPriority = 5, confidence = 0.75, tags = {"aoe"} },
        { spellID = 188443, priority = 6, condition = "always",   targetCount = 3, note = "Chain Lightning", displayPriority = 6, confidence = 0.7, tags = {"aoe"} },
    },
    majorCooldowns = {
        { spellID = 198067, note = "Fire Elemental" },
        { spellID = 191634, note = "Stormkeeper" },
    },
}

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

RA.APLData[262] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
