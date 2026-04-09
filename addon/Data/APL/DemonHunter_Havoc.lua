------------------------------------------------------------------------
-- RotaAssist - APL: Demon Hunter / Havoc (specID 577)
-- WoW 12.0-safe predictive priority list for Havoc Demon Hunter.
--
-- Constraints:
--   * No combat aura scanning.
--   * Rotation stays anchored to C_AssistedCombat for slot 1.
--   * APL look-ahead focuses on Fury, cooldowns, target count, and
--     Demonic windows that can be inferred safely.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

if not RA.APLData then
    RA.APLData = {}
end

local APL = {
    specID = 577,
    specName = "Havoc",
    className = "DEMONHUNTER",
    version = "12.0.2",
    lastUpdated = "2026-04-09",
    author = "RotaAssist Team",
    profiles = {},
}

APL.profiles["default"] = {
    signatureTalentNames = {
        "Art of the Glaive",
        "Aldrachi Reaver",
    },
    singleTarget = {
        {
            spellID = 198013,
            cdSeconds = 30,
            priority = 1,
            condition = "cd_ready",
            note = "Start the Demonic window on cooldown",
            displayPriority = 1,
            confidence = 0.98,
            tags = { "burst", "window" },
        },
        {
            spellID = 258860,
            cdSeconds = 10,
            priority = 2,
            condition = "cd_ready AND after:198013",
            note = "Essence Break immediately after Eye Beam",
            displayPriority = 2,
            confidence = 0.96,
            tags = { "burst", "window" },
        },
        {
            spellID = 188499,
            cdSeconds = 9,
            priority = 3,
            condition = "cd_ready AND window:essence_break AND estimated_resource >= 35",
            note = "Highest-value spender during Essence Break",
            displayPriority = 3,
            confidence = 0.99,
            tags = { "window", "spender" },
        },
        {
            spellID = 188499,
            cdSeconds = 9,
            priority = 4,
            condition = "cd_ready AND window:demonic AND not_window:essence_break AND estimated_resource >= 35",
            note = "Spend the early Demonic globals on Death Sweep when Essence Break is down",
            displayPriority = 4,
            confidence = 0.94,
            tags = { "window", "spender" },
        },
        {
            spellID = 370965,
            cdSeconds = 90,
            priority = 5,
            condition = "cd_ready AND window:demonic AND combat_time >= 3",
            note = "The Hunt gains value when the Demonic burst window is already live",
            displayPriority = 5,
            confidence = 0.9,
            tags = { "burst" },
        },
        {
            spellID = 162794,
            priority = 6,
            condition = "window:demonic AND not_window:essence_break AND estimated_resource >= 70",
            note = "High-Fury dump during Demonic before we leave Meta",
            displayPriority = 6,
            confidence = 0.88,
            tags = { "spender" },
        },
        {
            spellID = 258920,
            cdSeconds = 30,
            priority = 7,
            condition = "cd_ready AND estimated_resource <= 80",
            note = "Generator before Fury overcap",
            displayPriority = 7,
            confidence = 0.9,
            tags = { "generator" },
        },
        {
            spellID = 232893,
            cdSeconds = 15,
            priority = 8,
            condition = "cd_ready AND estimated_resource <= 70",
            note = "Low-Fury recovery button",
            displayPriority = 8,
            confidence = 0.9,
            tags = { "generator" },
        },
        {
            spellID = 162794,
            priority = 9,
            condition = "window:essence_break AND estimated_resource >= 40",
            note = "Dump Fury aggressively inside Essence Break",
            displayPriority = 9,
            confidence = 0.9,
            tags = { "spender" },
        },
        {
            spellID = 342817,
            cdSeconds = 20,
            priority = 10,
            condition = "cd_ready AND target_count >= 2 AND not_window:essence_break",
            note = "Cleave burst when extra targets are present",
            displayPriority = 10,
            confidence = 0.82,
            tags = { "aoe", "burst" },
        },
        {
            spellID = 162243,
            priority = 11,
            condition = "estimated_resource <= 35",
            note = "Fallback Fury generator for non-Demon Blades setups",
            displayPriority = 11,
            confidence = 0.8,
            tags = { "generator" },
        },
        {
            spellID = 162794,
            priority = 12,
            condition = "estimated_resource >= 40",
            note = "Default spender filler outside the highest-value windows",
            displayPriority = 12,
            confidence = 0.72,
            tags = { "spender" },
        },
    },

    aoe = {
        {
            spellID = 198013,
            cdSeconds = 30,
            priority = 1,
            condition = "cd_ready",
            displayPriority = 1,
            confidence = 0.98,
            note = "Eye Beam anchors the AoE cycle",
            tags = { "aoe", "burst" },
        },
        {
            spellID = 188499,
            cdSeconds = 9,
            priority = 2,
            condition = "cd_ready AND window:essence_break AND estimated_resource >= 35",
            displayPriority = 2,
            confidence = 0.99,
            note = "Death Sweep first during Essence Break cleave",
            tags = { "aoe", "spender" },
        },
        {
            spellID = 342817,
            cdSeconds = 20,
            priority = 3,
            condition = "cd_ready AND not_window:essence_break",
            displayPriority = 3,
            confidence = 0.92,
            note = "Glaive Tempest for sustained cleave",
            tags = { "aoe" },
        },
        {
            spellID = 258920,
            cdSeconds = 30,
            priority = 4,
            condition = "cd_ready AND estimated_resource <= 80",
            displayPriority = 4,
            confidence = 0.9,
            note = "Immolation Aura before Fury overcap",
            tags = { "aoe", "generator" },
        },
        {
            spellID = 232893,
            cdSeconds = 15,
            priority = 5,
            condition = "cd_ready AND estimated_resource <= 65",
            displayPriority = 5,
            confidence = 0.88,
            note = "Felblade to refill for the next AoE spender",
            tags = { "aoe", "generator" },
        },
        {
            spellID = 162794,
            priority = 6,
            condition = "window:demonic AND estimated_resource >= 70",
            displayPriority = 6,
            confidence = 0.78,
            note = "Spend surplus Fury inside Demonic during cleave",
            tags = { "aoe", "spender" },
        },
        {
            spellID = 162243,
            priority = 7,
            condition = "estimated_resource <= 35",
            displayPriority = 7,
            confidence = 0.8,
            note = "Fallback generator in AoE",
            tags = { "generator" },
        },
    },

    opener = {
        { spellID = 370965, cdSeconds = 90, step = 1, note = "The Hunt on pull" },
        { spellID = 258920, cdSeconds = 30, step = 2, note = "Immolation Aura for immediate Fury" },
        { spellID = 198013, cdSeconds = 30, step = 3, note = "Eye Beam to trigger Demonic" },
        { spellID = 258860, cdSeconds = 10, step = 4, note = "Essence Break after Eye Beam" },
        { spellID = 188499, cdSeconds = 9, step = 5, note = "Blade Dance / Death Sweep in the burst window" },
    },

    majorCooldowns = {
        { spellID = 191427, cdSeconds = 240, note = "Metamorphosis manual reminder. Align with burst." },
    },
}

APL.profiles["aldrachi_reaver"] = APL.profiles["default"]

APL.profiles["fel_scarred"] = {
    signatureTalentNames = {
        "Demonsurge",
        "Student of Suffering",
        "Fel-Scarred",
    },
    singleTarget = {
        {
            spellID = 198013,
            cdSeconds = 30,
            priority = 1,
            condition = "cd_ready",
            note = "Eye Beam. Respect the longer channel",
            displayPriority = 1,
            confidence = 0.98,
            tags = { "burst", "window" },
        },
        {
            spellID = 258860,
            cdSeconds = 10,
            priority = 2,
            condition = "cd_ready AND after:198013",
            note = "Essence Break after Eye Beam",
            displayPriority = 2,
            confidence = 0.96,
            tags = { "burst", "window" },
        },
        {
            spellID = 188499,
            cdSeconds = 9,
            priority = 3,
            condition = "cd_ready AND window:essence_break AND estimated_resource >= 35",
            note = "Death Sweep window spender",
            displayPriority = 3,
            confidence = 0.99,
            tags = { "window", "spender" },
        },
        {
            spellID = 162794,
            priority = 4,
            condition = "window:demonic AND not_window:essence_break AND estimated_resource >= 70",
            note = "Fel-Scarred leans harder into spender pressure during Demonic",
            displayPriority = 4,
            confidence = 0.92,
            tags = { "window", "spender" },
        },
        {
            spellID = 370965,
            cdSeconds = 90,
            priority = 5,
            condition = "cd_ready AND window:demonic AND combat_time >= 3",
            note = "The Hunt during stable burst windows",
            displayPriority = 5,
            confidence = 0.9,
            tags = { "burst" },
        },
        {
            spellID = 258920,
            cdSeconds = 30,
            priority = 6,
            condition = "cd_ready AND estimated_resource <= 80",
            note = "Immolation Aura before overcap",
            displayPriority = 6,
            confidence = 0.9,
            tags = { "generator" },
        },
        {
            spellID = 232893,
            cdSeconds = 15,
            priority = 7,
            condition = "cd_ready AND estimated_resource <= 70",
            note = "Felblade low-Fury recovery",
            displayPriority = 7,
            confidence = 0.9,
            tags = { "generator" },
        },
        {
            spellID = 162794,
            priority = 8,
            condition = "window:essence_break AND estimated_resource >= 40",
            note = "High-Fury spender inside the burst cycle",
            displayPriority = 8,
            confidence = 0.9,
            tags = { "spender" },
        },
        {
            spellID = 342817,
            cdSeconds = 20,
            priority = 9,
            condition = "cd_ready AND target_count >= 2 AND not_window:essence_break",
            note = "Cleave burst when extra targets exist",
            displayPriority = 9,
            confidence = 0.82,
            tags = { "aoe", "burst" },
        },
        {
            spellID = 162243,
            priority = 10,
            condition = "estimated_resource <= 35",
            note = "Fallback Fury generator",
            displayPriority = 10,
            confidence = 0.8,
            tags = { "generator" },
        },
        {
            spellID = 162794,
            priority = 11,
            condition = "estimated_resource >= 40",
            note = "Default spender filler",
            displayPriority = 11,
            confidence = 0.72,
            tags = { "spender" },
        },
    },
    aoe = APL.profiles["default"].aoe,
    opener = APL.profiles["default"].opener,
    majorCooldowns = APL.profiles["default"].majorCooldowns,
}

local defaultProfile = APL.profiles["default"]
local rules = {}
if defaultProfile and defaultProfile.singleTarget then
    for _, entry in ipairs(defaultProfile.singleTarget) do
        rules[#rules + 1] = {
            spellID = entry.spellID,
            name = entry.note or ("Spell#" .. entry.spellID),
            priority = entry.priority,
            condition = entry.condition or "always",
            reason = entry.note or "",
        }
    end
end

RA.APLData[577] = {
    specID = APL.specID,
    specName = APL.specName,
    class = APL.className,
    version = APL.version,
    author = APL.author,
    rules = rules,
    profiles = APL.profiles,
}
