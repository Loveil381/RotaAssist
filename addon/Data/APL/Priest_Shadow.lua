------------------------------------------------------------------------
-- RotaAssist - APL: Priest / Shadow (specID 258)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.APLData then RA.APLData = {} end

local APL = {
    specID      = 258,
    specName    = "Shadow",
    className   = "PRIEST",
    version     = "12.0.2",
    lastUpdated = "2026-02-26",
    author      = "RotaAssist Team",
    profiles    = {}
}

APL.profiles["default"] = {
    singleTarget = {
        { spellID = 34914,  priority = 1, condition = "debuff_missing:vampiric_touch AND cd_not_ready:451329", note = "Vampiric Touch (Apply manually if Slam CD)" },
        { spellID = 451329, priority = 2, condition = "cd_ready", note = "Tentacle Slam" },
        { spellID = 589,    priority = 3, condition = "debuff_missing:shadow_word_pain", note = "Shadow Word: Pain" },
        { spellID = 228260, priority = 4, condition = "cd_ready", note = "Voidform" },
        { spellID = 10060,  priority = 5, condition = "cd_ready", note = "Power Infusion" },
        { spellID = 120644, priority = 6, condition = "cd_ready", note = "Halo" },
        { spellID = 263346, priority = 7, condition = "cd_ready AND debuff:shadow_word_madness", note = "Void Torrent" },
        { spellID = 451843, priority = 8, condition = "buff:voidform", note = "Void Volley" },
        { spellID = 8092,   priority = 9, condition = "charges:mind_blast>=2", note = "Mind Blast (Prevent capping)" },
        { spellID = 451840, priority = 10, condition = "debuff_remains:shadow_word_madness<1.0 OR resource_deficit<35", note = "Shadow Word: Madness" },
        { spellID = 391403, priority = 11, condition = "buff:mind_flay_insanity", note = "Mind Flay: Insanity" },
        { spellID = 15407,  priority = 12, condition = "always", note = "Mind Flay (Filler)" },
    },
    aoe = {
        { spellID = 228260, priority = 1, condition = "cd_ready", note = "Voidform" },
        { spellID = 10060,  priority = 2, condition = "cd_ready", note = "Power Infusion" },
        { spellID = 451329, priority = 3, condition = "cd_ready", note = "Tentacle Slam (Applies VT to 6)" },
        { spellID = 34914,  priority = 4, condition = "target_count<=12 AND debuff_missing:vampiric_touch", note = "Vampiric Touch (Manual spread)" },
        { spellID = 451840, priority = 5, condition = "resource>=50", note = "Shadow Word: Madness" },
        { spellID = 451843, priority = 6, condition = "buff:voidform", note = "Void Volley" },
        { spellID = 8092,   priority = 7, condition = "charges:mind_blast>=2", note = "Mind Blast" },
        { spellID = 120644, priority = 8, condition = "cd_ready", note = "Halo" },
        { spellID = 263346, priority = 9, condition = "cd_ready", note = "Void Torrent" },
        { spellID = 15407,  priority = 10, condition = "always", note = "Mind Flay (Filler)" },
    },
    opener = {},
    majorCooldowns = {
        { spellID = 228260, note = "Voidform" },
        { spellID = 10060, note = "Power Infusion" },
        { spellID = 120644, note = "Halo" },
        { spellID = 263346, note = "Void Torrent" },
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

RA.APLData[258] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
