------------------------------------------------------------------------
-- RotaAssist - APL: Shaman / Enhancement (specID 263)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.APLData then RA.APLData = {} end

local APL = {
    specID      = 263,
    specName    = "Enhancement",
    className   = "SHAMAN",
    version     = "12.0.2",
    lastUpdated = "2026-02-26",
    author      = "RotaAssist Team",
    profiles    = {}
}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 462620, priority = 1, condition = "debuff_missing:flame_shock", note = "Voltaic Blaze (Flame Shock)" },
        { spellID = 384063, priority = 2, condition = "cd_ready", note = "Surging Totem" },
        { spellID = 384352, priority = 3, condition = "cd_ready", note = "Doom Winds / Ascendance" },
        { spellID = 60103,  priority = 4, condition = "buff:hot_hand OR buff:whirling_fire", note = "Lava Lash (Hot Hand / Whirling Fire)" },
        { spellID = 197214, priority = 5, condition = "cd_ready", note = "Sundering" },
        { spellID = 187874, priority = 6, condition = "cd_ready", note = "Crash Lightning (Buff maintenance)" },
        { spellID = 17364,  priority = 7, condition = "cd_ready", note = "Stormstrike / Windstrike" },
        { spellID = 188196, priority = 8, condition = "secondary_resource>=5", note = "Lightning Bolt (5+ MW)" },
        { spellID = 462856, priority = 9, condition = "secondary_resource>=10", note = "Primordial Wave / Storm (10 MW)" },
        { spellID = 60103,  priority = 10, condition = "cd_ready", note = "Lava Lash (Filler)" },
        { spellID = 188196, priority = 11, condition = "secondary_resource>=5", note = "Lightning Bolt (Dump remaining MW)" },
    },
    aoe = {
        { spellID = 462620, priority = 1, condition = "debuff_missing:flame_shock", note = "Voltaic Blaze (Flame Shock)" },
        { spellID = 384063, priority = 2, condition = "cd_ready", note = "Surging Totem" },
        { spellID = 384352, priority = 3, condition = "cd_ready", note = "Doom Winds / Ascendance" },
        { spellID = 187874, priority = 4, condition = "cd_ready", note = "Crash Lightning" },
        { spellID = 197214, priority = 5, condition = "cd_ready", note = "Sundering" },
        { spellID = 188443, priority = 6, condition = "secondary_resource>=5", note = "Chain Lightning (5+ MW)" },
        { spellID = 17364,  priority = 7, condition = "cd_ready", note = "Stormstrike / Windstrike" },
        { spellID = 60103,  priority = 8, condition = "buff:hot_hand OR buff:whirling_fire", note = "Lava Lash (Hot Hand / Whirling Fire)" },
    },
    opener = {},
    majorCooldowns = {
        { spellID = 114051, note = "Ascendance" },
        { spellID = 384352, note = "Doom Winds" },
        { spellID = 197214, note = "Sundering" },
        { spellID = 375982, note = "Primordial Wave" },
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

RA.APLData[263] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
