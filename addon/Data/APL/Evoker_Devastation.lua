------------------------------------------------------------------------
-- RotaAssist - APL: Evoker / Devastation  (specID 1467)
-- Rotation priority for Devastation Evoker in WoW 12.0 Midnight.
-- Hero-talent variants: Flameshaper (default), Scalecommander.
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
APL.specID            = 1467
APL.specName          = "Devastation"
APL.className         = "EVOKER"
APL.version           = "12.0.1"

------------------------------------------------------------------------
-- PROFILES
------------------------------------------------------------------------
APL.profiles = {}

------------------------------------------------------------------------
-- FLAMESHAPER — Single-Target
------------------------------------------------------------------------
APL.profiles["flameshaper"] = {
    singleTarget = {
        {
            spellID   = 375087, -- Dragonrage
            condition = "cd_ready",
            note      = "Burst CD",
        },
        {
            spellID   = 357208, -- Fire Breath
            condition = "cd_ready",
            note      = "Rank 1 fast release, prevent capping 2 charges",
        },
        {
            spellID   = 359073, -- Eternity Surge
            condition = "cd_ready",
            note      = "Rank 1",
        },
        {
            spellID   = 370452, -- Shattering Star
            condition = "cd_ready",
        },
        {
            spellID   = 356995, -- Disintegrate
            condition = "always",
            note      = "Spend Essence, chain channel",
        },
        {
            spellID   = 357208, -- Fire Breath
            condition = "always",
            note      = "Manage Flameshaper 2nd charge",
        },
        {
            spellID   = 361469, -- Living Flame
            condition = "always",
            note      = "Filler",
        },
    },

    aoe = {
        {
            spellID   = 375087, -- Dragonrage
            condition = "cd_ready",
        },
        {
            spellID   = 357208, -- Fire Breath
            condition = "cd_ready",
            note      = "Rank 1",
        },
        {
            spellID   = 359073, -- Eternity Surge
            condition = "cd_ready",
        },
        {
            spellID   = 357210, -- Deep Breath
            condition = "cd_ready",
        },
        {
            spellID   = 357211, -- Pyre
            condition = "always",
            note      = "Spend Essence on AoE",
        },
        {
            spellID   = 361469, -- Living Flame
            condition = "always",
        },
        {
            spellID   = 362969, -- Azure Strike
            condition = "always",
        },
    }
}

------------------------------------------------------------------------
-- SCALECOMMANDER — Single-Target
------------------------------------------------------------------------
APL.profiles["scalecommander"] = {
    singleTarget = {
        {
            spellID   = 375087, -- Dragonrage
            condition = "cd_ready",
        },
        {
            spellID   = 370553, -- Tip the Scales
            condition = "cd_ready",
            note      = "Use with Fire Breath",
        },
        {
            spellID   = 357208, -- Fire Breath
            condition = "cd_ready",
            note      = "Rank 1",
        },
        {
            spellID   = 359073, -- Eternity Surge
            condition = "cd_ready",
            note      = "Rank 1",
        },
        {
            spellID   = 357210, -- Deep Breath
            condition = "cd_ready",
        },
        {
            spellID   = 436335, -- Mass Disintegrate
            condition = "always",
            note      = "Use if granted by Empower",
        },
        {
            spellID   = 356995, -- Disintegrate
            condition = "always",
            note      = "Chain channel",
        },
        {
            spellID   = 361469, -- Living Flame
            condition = "always",
            note      = "Filler",
        },
    },

    aoe = {
        {
            spellID   = 359073, -- Eternity Surge
            condition = "cd_ready",
        },
        {
            spellID   = 370452, -- Shattering Star
            condition = "cd_ready",
        },
        {
            spellID   = 436335, -- Mass Disintegrate
            condition = "always",
        },
        {
            spellID   = 357210, -- Deep Breath
            condition = "cd_ready",
            note      = "Scalecommander uses 2 charges",
        },
        {
            spellID   = 375087, -- Dragonrage
            condition = "cd_ready",
        },
        {
            spellID   = 357208, -- Fire Breath
            condition = "cd_ready",
        },
        {
            spellID   = 357211, -- Pyre
            condition = "always",
        },
        {
            spellID   = 362969, -- Azure Strike
            condition = "always",
        },
    }
}

-- Default fallback (Flameshaper is default in 12.0)
APL.profiles["default"] = APL.profiles["flameshaper"]

-- Optional flat rule array matching the Flameshaper ST priority
APL.rules = APL.profiles["flameshaper"].singleTarget

------------------------------------------------------------------------
-- Phase 1 Opener Data (Backward-compat / basic logic)
------------------------------------------------------------------------

APL.phases = {
    -- Flameshaper Opener
    {
        name = "Opener (Flameshaper)",
        condition = "combat_time < 5 and target_health_pct > 0.9",
        rules = {
            { spellID = 361469, condition = "always", note = "Pre-cast Living Flame" },
            { spellID = 375087, condition = "always", note = "Dragonrage" },
            { spellID = 357208, condition = "always", note = "Fire Breath Rank 1" },
            { spellID = 370553, condition = "always", note = "Tip the Scales" },
            { spellID = 359073, condition = "always", note = "Eternity Surge" },
            { spellID = 356995, condition = "always", note = "Disintegrate Chain" },
        }
    },
    -- Scalecommander Opener
    {
        name = "Opener (Scalecommander)",
        condition = "combat_time < 5 and target_health_pct > 0.9",
        rules = {
            { spellID = 361469, condition = "always", note = "Pre-cast Living Flame" },
            { spellID = 375087, condition = "always", note = "Dragonrage" },
            { spellID = 370553, condition = "always", note = "Tip the Scales" },
            { spellID = 357208, condition = "always", note = "Fire Breath" },
            { spellID = 359073, condition = "always", note = "Eternity Surge" },
            { spellID = 357210, condition = "cd_ready", note = "Deep Breath" },
            { spellID = 436335, condition = "always", note = "Mass Disintegrate" },
        }
    }
}

-- Backward compat rules (Pre-phase2)
for _, entry in ipairs(APL.rules) do
    entry.priority = entry.priority or 1
    entry.condition = entry.condition or "always"
end

RA.APLData[APL.specID] = APL
