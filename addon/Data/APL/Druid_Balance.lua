------------------------------------------------------------------------
-- RotaAssist - APL: Druid / Balance (specID 102)
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

if not RA.APLData then
    RA.APLData = {}
end

local APL             = {}
APL.specID            = 102
APL.specName          = "Balance"
APL.className         = "DRUID"
APL.version           = "12.0.1"
APL.author            = "RotaAssist Team"

APL.profiles = {}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 102560, priority = 1, condition = "cd_ready", note = "Incarnation: Chosen of Elune", displayPriority = 1, confidence = 0.9, tags = {"burst", "major"} },
        { spellID = 194223, priority = 2, condition = "cd_ready", note = "Celestial Alignment", displayPriority = 2, confidence = 0.9, tags = {"burst", "major"} },
        { spellID = 8921,   priority = 3, condition = "always",   note = "Moonfire", displayPriority = 3, confidence = 0.85, tags = {"sustain"} },
        { spellID = 93402,  priority = 4, condition = "always",   note = "Sunfire", displayPriority = 4, confidence = 0.85, tags = {"sustain"} },
        { spellID = 202347, priority = 5, condition = "always",   note = "Stellar Flare", displayPriority = 5, confidence = 0.8, tags = {"sustain"} },
        { spellID = 78674,  priority = 6, condition = "resource_above_40", note = "Starsurge", displayPriority = 6, confidence = 0.8, tags = {"sustain"} },
        { spellID = 190984, priority = 7, condition = "always",   note = "Wrath", displayPriority = 7, confidence = 0.7, tags = {"sustain"} },
    },
    aoe = {
        { spellID = 102560, priority = 1, condition = "cd_ready", targetCount = 3, note = "Incarnation", displayPriority = 1, confidence = 0.9, tags = {"aoe", "burst"} },
        { spellID = 194223, priority = 2, condition = "cd_ready", targetCount = 3, note = "Celestial Alignment", displayPriority = 2, confidence = 0.9, tags = {"aoe", "burst"} },
        { spellID = 93402,  priority = 3, condition = "always",   targetCount = 3, note = "Sunfire", displayPriority = 3, confidence = 0.85, tags = {"aoe"} },
        { spellID = 8921,   priority = 4, condition = "always",   targetCount = 3, note = "Moonfire", displayPriority = 4, confidence = 0.8, tags = {"aoe"} },
        { spellID = 191034, priority = 5, condition = "resource_above_50", targetCount = 3, note = "Starfall", displayPriority = 5, confidence = 0.85, tags = {"aoe"} },
        { spellID = 194153, priority = 6, condition = "always",   targetCount = 3, note = "Starfire", displayPriority = 6, confidence = 0.75, tags = {"aoe"} },
    },
    majorCooldowns = {
        { spellID = 194223, note = "Celestial Alignment" },
        { spellID = 102560, note = "Incarnation" },
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

RA.APLData[102] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
