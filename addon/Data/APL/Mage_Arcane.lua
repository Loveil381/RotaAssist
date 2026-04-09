------------------------------------------------------------------------
-- RotaAssist - APL: Mage / Arcane (specID 62)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.APLData then RA.APLData = {} end

local APL = {
    specID      = 62,
    specName    = "Arcane",
    className   = "MAGE",
    version     = "12.0.2",
    lastUpdated = "2026-02-26",
    author      = "RotaAssist Team",
    profiles    = {}
}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 321507, priority = 1, condition = "cd_ready", note = "Touch of the Magi" },
        { spellID = 365362, priority = 2, condition = "cd_ready", note = "Arcane Surge" },
        { spellID = 44425,  priority = 3, condition = "secondary_resource>=4 AND stacks:salvo_max", note = "Arcane Barrage (4 Charges + Max Salvo)" },
        { spellID = 5143,   priority = 4, condition = "buff:clearcasting", note = "Arcane Missiles (Clearcasting)" },
        { spellID = 153626, priority = 5, condition = "cd_ready", note = "Arcane Orb" },
        { spellID = 44425,  priority = 6, condition = "resource_pct<0.15", note = "Arcane Barrage (Mana < 15%)" },
        { spellID = 30451,  priority = 7, condition = "secondary_resource>=4", note = "Arcane Blast (4 Charges filler)" },
        { spellID = 44425,  priority = 8, condition = "resource_pct<0.05", note = "Arcane Barrage (OOM dump)" },
        { spellID = 30451,  priority = 9, condition = "always", note = "Arcane Blast (Building)" },
    },
    aoe = {
        { spellID = 321507, priority = 1, condition = "cd_ready", note = "Touch of the Magi" },
        { spellID = 365362, priority = 2, condition = "cd_ready", note = "Arcane Surge" },
        { spellID = 153626, priority = 3, condition = "cd_ready", note = "Arcane Orb" },
        { spellID = 44425,  priority = 4, condition = "secondary_resource>=4 AND stacks:salvo_max", note = "Arcane Barrage (4 Charges + Max Salvo)" },
        { spellID = 1449,   priority = 5, condition = "in_melee", note = "Arcane Explosion (Building in melee)" },
        { spellID = 44425,  priority = 6, condition = "resource_pct<0.15", note = "Arcane Barrage (Mana dump)" },
        { spellID = 30451,  priority = 7, condition = "always", note = "Arcane Blast (Ranged building)" },
    },
    opener = {},
    majorCooldowns = {
        { spellID = 365362, note = "Arcane Surge" },
        { spellID = 321507, note = "Touch of the Magi" }
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

RA.APLData[62] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
