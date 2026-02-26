------------------------------------------------------------------------
-- RotaAssist - APL: Rogue / Subtlety (specID 261)
------------------------------------------------------------------------

local _, RA = ...

if not RA.APLData then
    RA.APLData = {}
end

local APL             = {}
APL.specID            = 261
APL.specName          = "Subtlety"
APL.className         = "ROGUE"
APL.version           = "12.0.1"
APL.author            = "RotaAssist Team"

APL.profiles = {}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 121471, priority = 1, condition = "cd_ready", note = "Shadow Blades", displayPriority = 1, confidence = 0.9, tags = {"burst", "major"} },
        { spellID = 212283, priority = 2, condition = "cd_ready", note = "Symbols of Death", displayPriority = 2, confidence = 0.9, tags = {"burst"} },
        { spellID = 185313, priority = 3, condition = "cd_ready", note = "Shadow Dance", displayPriority = 3, confidence = 0.85, tags = {"burst"} },
        { spellID = 1943,   priority = 4, condition = "resource_above_4", note = "Rupture", displayPriority = 4, confidence = 0.85, tags = {"sustain"} },
        { spellID = 280719, priority = 5, condition = "cd_ready", note = "Secret Technique", displayPriority = 5, confidence = 0.8, tags = {"burst"} },
        { spellID = 196819, priority = 6, condition = "resource_above_4", note = "Eviscerate", displayPriority = 6, confidence = 0.75, tags = {"sustain"} },
        { spellID = 185438, priority = 7, condition = "in_meta", note = "Shadowstrike", displayPriority = 7, confidence = 0.9, tags = {"sustain"} },
        { spellID = 53,     priority = 8, condition = "always", note = "Backstab", displayPriority = 8, confidence = 0.7, tags = {"sustain"} },
    },
    aoe = {
        { spellID = 121471, priority = 1, condition = "cd_ready", targetCount = 3, note = "Shadow Blades", displayPriority = 1, confidence = 0.9, tags = {"aoe", "burst"} },
        { spellID = 212283, priority = 2, condition = "cd_ready", targetCount = 3, note = "Symbols of Death", displayPriority = 2, confidence = 0.9, tags = {"aoe", "burst"} },
        { spellID = 185313, priority = 3, condition = "cd_ready", targetCount = 3, note = "Shadow Dance", displayPriority = 3, confidence = 0.85, tags = {"aoe", "burst"} },
        { spellID = 280719, priority = 4, condition = "cd_ready", targetCount = 3, note = "Secret Technique", displayPriority = 4, confidence = 0.85, tags = {"aoe", "burst"} },
        { spellID = 319175, priority = 5, condition = "resource_above_4", targetCount = 3, note = "Black Powder", displayPriority = 5, confidence = 0.8, tags = {"aoe"} },
        { spellID = 122281, priority = 6, condition = "always", targetCount = 3, note = "Shuriken Storm", displayPriority = 6, confidence = 0.7, tags = {"aoe"} },
    },
    majorCooldowns = {
        { spellID = 121471, note = "Shadow Blades" },
        { spellID = 185313, note = "Shadow Dance" },
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

RA.APLData[261] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
