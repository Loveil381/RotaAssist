------------------------------------------------------------------------
-- RotaAssist - APL: Evoker / Augmentation (specID 1473)
-- Rotation priority for Augmentation Evoker in WoW 12.0 Midnight.
--
-- 12.0.1
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

if not RA.APLData then
    RA.APLData = {}
end

------------------------------------------------------------------------
-- Metadata
------------------------------------------------------------------------
local APL             = {}
APL.specID            = 1473
APL.specName          = "Augmentation"
APL.className         = "EVOKER"
APL.version           = "12.0.1"

------------------------------------------------------------------------
-- PROFILES
------------------------------------------------------------------------
APL.profiles = {}

------------------------------------------------------------------------
-- DEFAULT / CHRONOWARDEN
------------------------------------------------------------------------
APL.profiles["default"] = {
    singleTarget = {
        {
            spellID   = 409311, -- Prescience
            priority  = 1,
            condition = "cd_ready",
            note      = "Maintain buff on allies",
        },
        {
            spellID   = 395152, -- Ebon Might
            priority  = 2,
            condition = "cd_ready",
            note      = "Core buff",
        },
        {
            spellID   = 403631, -- Breath of Eons
            priority  = 3,
            condition = "cd_ready",
            note      = "Major burst CD",
        },
        {
            spellID   = 370553, -- Tip the Scales
            priority  = 4,
            condition = "cd_ready and after:395152",
        },
        {
            spellID   = 357208, -- Fire Breath
            priority  = 5,
            condition = "cd_ready",
            note      = "Rank 1",
        },
        {
            spellID   = 396286, -- Upheaval
            priority  = 6,
            condition = "cd_ready",
            note      = "Empowered spell",
        },
        {
            spellID   = 404977, -- Time Skip
            priority  = 7,
            condition = "cd_ready",
        },
        {
            spellID   = 395160, -- Eruption
            priority  = 8,
            condition = "always",
            note      = "Spend Essence / Extend Ebon Might",
        },
        {
            spellID   = 361469, -- Living Flame
            priority  = 9,
            condition = "always",
            note      = "Filler",
        },
    },

    aoe = {
        {
            spellID   = 409311, -- Prescience
            priority  = 1,
            condition = "cd_ready",
        },
        {
            spellID   = 395152, -- Ebon Might
            priority  = 2,
            condition = "cd_ready",
        },
        {
            spellID   = 403631, -- Breath of Eons
            priority  = 3,
            condition = "cd_ready",
        },
        {
            spellID   = 370553, -- Tip the Scales
            priority  = 4,
            condition = "cd_ready and after:395152",
        },
        {
            spellID   = 357208, -- Fire Breath
            priority  = 5,
            condition = "cd_ready",
        },
        {
            spellID   = 396286, -- Upheaval
            priority  = 6,
            condition = "cd_ready",
        },
        {
            spellID   = 404977, -- Time Skip
            priority  = 7,
            condition = "cd_ready",
        },
        {
            spellID   = 395160, -- Eruption
            priority  = 8,
            condition = "always",
        },
        {
            spellID   = 361469, -- Living Flame
            priority  = 9,
            condition = "always",
        },
    }
}

-- Map singleTarget to the flat rules array
APL.rules = APL.profiles["default"].singleTarget

------------------------------------------------------------------------
-- Phase 1 Opener Data
------------------------------------------------------------------------

APL.phases = {
    {
        name = "Opener",
        condition = "combat_time < 5 and target_health_pct > 0.9",
        rules = {
            { spellID = 360827, condition = "always", note = "Blistering Scales (Pre-pull)" },
            { spellID = 361469, condition = "always", note = "Living Flame (Pre-cast)" },
            { spellID = 409311, condition = "always", note = "Prescience x2" },
            { spellID = 395152, condition = "always", note = "Ebon Might" },
            { spellID = 403631, condition = "always", note = "Breath of Eons" },
            { spellID = 370553, condition = "always", note = "Tip the Scales" },
            { spellID = 357208, condition = "always", note = "Fire Breath" },
            { spellID = 396286, condition = "always", note = "Upheaval" },
            { spellID = 395160, condition = "always", note = "Eruption Chain" },
        }
    }
}

RA.APLData[APL.specID] = APL
