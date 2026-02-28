------------------------------------------------------------------------
-- RotaAssist - APL: Evoker / Preservation (specID 1468)
-- DPS Rotation priority for Preservation Evoker in WoW 12.0 Midnight.
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
APL.specID            = 1468
APL.specName          = "Preservation"
APL.className         = "EVOKER"
APL.version           = "12.0.1"

------------------------------------------------------------------------
-- PROFILES
------------------------------------------------------------------------
APL.profiles = {}

------------------------------------------------------------------------
-- DEFAULT / DPS MODE
------------------------------------------------------------------------
APL.profiles["default"] = {
    singleTarget = {
        {
            spellID   = 357208, -- Fire Breath
            priority  = 1,
            condition = "cd_ready",
            note      = "Offensive Burst",
        },
        {
            spellID   = 361469, -- Living Flame
            priority  = 2,
            condition = "always",
            note      = "DPS Filler",
        },
        {
            spellID   = 362969, -- Azure Strike
            priority  = 3,
            condition = "always",
            note      = "Mobile DPS Filler",
        },
    },

    aoe = {
        {
            spellID   = 357208, -- Fire Breath
            priority  = 1,
            condition = "cd_ready",
        },
        {
            spellID   = 361469, -- Living Flame
            priority  = 2,
            condition = "always",
        },
        {
            spellID   = 362969, -- Azure Strike
            priority  = 3,
            condition = "always",
        },
    },

    -- Healing Reference (Driven by AssistedCombat / UI directly, not queued as APL actions)
    healingReference = {
        {
            spellID   = 382614, -- Dream Breath
            priority  = 1,
            condition = "cd_ready",
        },
        {
            spellID   = 382731, -- Temporal Anomaly
            priority  = 2,
            condition = "cd_ready",
        },
        {
            spellID   = 366155, -- Reversion
            priority  = 3,
            condition = "cd_ready",
        },
        {
            spellID   = 355913, -- Emerald Blossom
            priority  = 4,
            condition = "always",
        },
    }
}

-- Map singleTarget to the flat rules array (DPS mode)
APL.rules = APL.profiles["default"].singleTarget

------------------------------------------------------------------------
-- Phase 1 Opener Data (DPS)
------------------------------------------------------------------------

APL.phases = {
    {
        name = "Opener",
        condition = "combat_time < 5 and target_health_pct > 0.9",
        rules = {
            { spellID = 357208, condition = "always", note = "Fire Breath" },
            { spellID = 361469, condition = "always", note = "Living Flame" },
        }
    }
}

RA.APLData[APL.specID] = APL
