------------------------------------------------------------------------
-- RotaAssist - Spec Info Data
-- All 13 classes and their specializations with WoW 12.0 specIDs.
-- Format: RA.SpecData[specID] = { classID, className, specName, role, icon, classColor }
--
-- NOTE: Devourer DH uses specID 1480 (confirmed via Warcraft Wiki
--   API_GetSpecializationInfo, 2026/01/03). No conflict with Evoker
--   Augmentation (specID 1473).
--
--   Verify with: /dump GetSpecializationInfo(GetSpecialization())
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

---@type table<number, table>
RA.SpecData = {
    ---------- Warrior (classID 1) ----------
    [71]  = { classID = 1, className = "WARRIOR",      specName = "Arms",         role = "DAMAGER", icon = 132355, classColor = "C69B6D" },
    [72]  = { classID = 1, className = "WARRIOR",      specName = "Fury",         role = "DAMAGER", icon = 132347, classColor = "C69B6D" },
    [73]  = { classID = 1, className = "WARRIOR",      specName = "Protection",   role = "TANK",    icon = 132341, classColor = "C69B6D" },

    ---------- Paladin (classID 2) ----------
    [65]  = { classID = 2, className = "PALADIN",      specName = "Holy",         role = "HEALER",  icon = 135920, classColor = "F48CBA" },
    [66]  = { classID = 2, className = "PALADIN",      specName = "Protection",   role = "TANK",    icon = 236264, classColor = "F48CBA" },
    [70]  = { classID = 2, className = "PALADIN",      specName = "Retribution",  role = "DAMAGER", icon = 135873, classColor = "F48CBA" },

    ---------- Hunter (classID 3) ----------
    [253] = { classID = 3, className = "HUNTER",       specName = "Beast Mastery", role = "DAMAGER", icon = 461112, classColor = "AAD372" },
    [254] = { classID = 3, className = "HUNTER",       specName = "Marksmanship",  role = "DAMAGER", icon = 236179, classColor = "AAD372" },
    [255] = { classID = 3, className = "HUNTER",       specName = "Survival",      role = "DAMAGER", icon = 461113, classColor = "AAD372" },

    ---------- Rogue (classID 4) ----------
    [259] = { classID = 4, className = "ROGUE",        specName = "Assassination", role = "DAMAGER", icon = 236270, classColor = "FFF468" },
    [260] = { classID = 4, className = "ROGUE",        specName = "Outlaw",        role = "DAMAGER", icon = 236286, classColor = "FFF468" },
    [261] = { classID = 4, className = "ROGUE",        specName = "Subtlety",      role = "DAMAGER", icon = 132320, classColor = "FFF468" },

    ---------- Priest (classID 5) ----------
    [256] = { classID = 5, className = "PRIEST",       specName = "Discipline",    role = "HEALER",  icon = 135940, classColor = "FFFFFF" },
    [257] = { classID = 5, className = "PRIEST",       specName = "Holy",          role = "HEALER",  icon = 237542, classColor = "FFFFFF" },
    [258] = { classID = 5, className = "PRIEST",       specName = "Shadow",        role = "DAMAGER", icon = 136207, classColor = "FFFFFF" },

    ---------- Death Knight (classID 6) ----------
    [250] = { classID = 6, className = "DEATHKNIGHT",  specName = "Blood",         role = "TANK",    icon = 135770, classColor = "C41E3A" },
    [251] = { classID = 6, className = "DEATHKNIGHT",  specName = "Frost",         role = "DAMAGER", icon = 135773, classColor = "C41E3A" },
    [252] = { classID = 6, className = "DEATHKNIGHT",  specName = "Unholy",        role = "DAMAGER", icon = 135775, classColor = "C41E3A" },

    ---------- Shaman (classID 7) ----------
    [262] = { classID = 7, className = "SHAMAN",       specName = "Elemental",     role = "DAMAGER", icon = 136048, classColor = "0070DD" },
    [263] = { classID = 7, className = "SHAMAN",       specName = "Enhancement",   role = "DAMAGER", icon = 237581, classColor = "0070DD" },
    [264] = { classID = 7, className = "SHAMAN",       specName = "Restoration",   role = "HEALER",  icon = 136052, classColor = "0070DD" },

    ---------- Mage (classID 8) ----------
    [62]  = { classID = 8, className = "MAGE",         specName = "Arcane",        role = "DAMAGER", icon = 135932, classColor = "3FC7EB" },
    [63]  = { classID = 8, className = "MAGE",         specName = "Fire",          role = "DAMAGER", icon = 135810, classColor = "3FC7EB" },
    [64]  = { classID = 8, className = "MAGE",         specName = "Frost",         role = "DAMAGER", icon = 135846, classColor = "3FC7EB" },

    ---------- Warlock (classID 9) ----------
    [265] = { classID = 9, className = "WARLOCK",      specName = "Affliction",    role = "DAMAGER", icon = 136145, classColor = "8788EE" },
    [266] = { classID = 9, className = "WARLOCK",      specName = "Demonology",    role = "DAMAGER", icon = 136172, classColor = "8788EE" },
    [267] = { classID = 9, className = "WARLOCK",      specName = "Destruction",   role = "DAMAGER", icon = 136186, classColor = "8788EE" },

    ---------- Monk (classID 10) ----------
    [268] = { classID = 10, className = "MONK",        specName = "Brewmaster",    role = "TANK",    icon = 608951, classColor = "00FF98" },
    [270] = { classID = 10, className = "MONK",        specName = "Mistweaver",    role = "HEALER",  icon = 608952, classColor = "00FF98" },
    [269] = { classID = 10, className = "MONK",        specName = "Windwalker",    role = "DAMAGER", icon = 608953, classColor = "00FF98" },

    ---------- Druid (classID 11) ----------
    [102] = { classID = 11, className = "DRUID",       specName = "Balance",       role = "DAMAGER", icon = 136096, classColor = "FF7C0A" },
    [103] = { classID = 11, className = "DRUID",       specName = "Feral",         role = "DAMAGER", icon = 132115, classColor = "FF7C0A" },
    [104] = { classID = 11, className = "DRUID",       specName = "Guardian",      role = "TANK",    icon = 132276, classColor = "FF7C0A" },
    [105] = { classID = 11, className = "DRUID",       specName = "Restoration",   role = "HEALER",  icon = 136041, classColor = "FF7C0A" },

    ---------- Demon Hunter (classID 12) ----------
    [577]  = { classID = 12, className = "DEMONHUNTER", specName = "Havoc",      role = "DAMAGER", icon = 1247264, classColor = "A330C9", primaryResource = 17 },
    [581]  = { classID = 12, className = "DEMONHUNTER", specName = "Vengeance",  role = "TANK",    icon = 1247265, classColor = "A330C9", primaryResource = 17 },
    
    -- Devourer (specID 1480, confirmed 2026/01/03)
    [1480] = { classID = 12, className = "DEMONHUNTER", specName = "Devourer",
               role = "DAMAGER",
               icon = 0,  -- placeholder until confirmed texture ID
               primaryResource = 17,
               classColor = "A330C9" },

    ---------- Evoker (classID 13) ----------
    [1467] = { classID = 13, className = "EVOKER", specName = "Devastation",  role = "DAMAGER", icon = 4511811, classColor = "33937F" },
    [1468] = { classID = 13, className = "EVOKER", specName = "Preservation", role = "HEALER",  icon = 4511812, classColor = "33937F" },
    -- Evoker Augmentation retains the true 1473 key
    [1473] = { classID = 13, className = "EVOKER", specName = "Augmentation", role = "DAMAGER", icon = 5198700, classColor = "33937F" },
}

------------------------------------------------------------------------
-- Convenience Lookups
------------------------------------------------------------------------

--- Reverse lookup: classID → list of specIDs
---@type table<number, number[]>
RA.ClassSpecs = {}
for specID, data in pairs(RA.SpecData) do
    if not RA.ClassSpecs[data.classID] then
        RA.ClassSpecs[data.classID] = {}
    end
    RA.ClassSpecs[data.classID][#RA.ClassSpecs[data.classID] + 1] = specID
end

--- Total spec count (for debug/validation)
RA.SpecCount = 0
for _ in pairs(RA.SpecData) do
    RA.SpecCount = RA.SpecCount + 1
end
