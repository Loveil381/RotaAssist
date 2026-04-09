------------------------------------------------------------------------
-- RotaAssist - Decision Tree: Shaman / Enhancement (263)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.DecisionTrees then RA.DecisionTrees = {} end

local DT = {
    specID = 263,
    treeName = "Enhancement_DT",
    version = "12.0.2",
    author = "RotaAssist Team",
    lastUpdated = "2026-02-26"
}

function DT:Evaluate(features)
    local bestSpell = 60103 -- Fallback: Lava Lash
    local confidence = 0.80

    if features.buff_ascendance_active or features.buff_doom_winds_active then
        if features.cooldown_17364_ready then
            bestSpell = 17364 -- Stormstrike / Windstrike
            confidence = 0.95
        elseif features.cooldown_187874_ready then
            bestSpell = 187874 -- Crash Lightning (Thorim's Invocation trigger)
            confidence = 0.90
        elseif features.secondary_resource >= 5 then
            bestSpell = 188196 -- Lightning Bolt
            confidence = 0.85
        else
            bestSpell = 60103 -- Lava Lash
            confidence = 0.80
        end
    else
        if not features.debuff_flame_shock_active and features.cooldown_462620_ready then
            bestSpell = 462620 -- Voltaic Blaze
            confidence = 0.95
        elseif features.cooldown_384063_ready then
            bestSpell = 384063 -- Surging Totem
            confidence = 0.92
        elseif features.buff_hot_hand_active and features.cooldown_60103_ready then
            bestSpell = 60103 -- Lava Lash
            confidence = 0.90
        elseif features.cooldown_197214_ready then
            bestSpell = 197214 -- Sundering
            confidence = 0.88
        elseif features.cooldown_187874_ready then
            bestSpell = 187874 -- Crash Lightning
            confidence = 0.86
        elseif features.cooldown_17364_ready then
            bestSpell = 17364 -- Stormstrike
            confidence = 0.85
        elseif features.secondary_resource >= 10 and features.cooldown_462856_ready then
            bestSpell = 462856 -- Primordial Wave/Storm
            confidence = 0.92
        elseif features.secondary_resource >= 8 then
            bestSpell = 188196 -- Lightning Bolt (prevent capping)
            confidence = 0.88
        elseif features.cooldown_60103_ready then
            bestSpell = 60103 -- Lava Lash (filler)
            confidence = 0.80
        elseif features.secondary_resource >= 5 then
            bestSpell = 188196 -- Lightning Bolt
            confidence = 0.82
        end
    end

    if features.enemies_in_range >= 2 then
        if not features.debuff_flame_shock_active and features.cooldown_462620_ready then
            bestSpell = 462620 -- Voltaic Blaze
            confidence = 0.95
        elseif features.cooldown_384063_ready then
            bestSpell = 384063 -- Surging Totem
            confidence = 0.92
        elseif features.cooldown_187874_ready then
            bestSpell = 187874 -- Crash Lightning (Priority in AoE)
            confidence = 0.95
        elseif features.cooldown_197214_ready then
            bestSpell = 197214 -- Sundering
            confidence = 0.90
        elseif features.secondary_resource >= 5 then
            bestSpell = 188443 -- Chain Lightning
            confidence = 0.88
        elseif features.cooldown_17364_ready then
            bestSpell = 17364 -- Stormstrike
            confidence = 0.85
        elseif features.buff_hot_hand_active and features.cooldown_60103_ready then
            bestSpell = 60103 -- Lava Lash
            confidence = 0.82
        else
            bestSpell = 187874 -- Crash Lightning
            confidence = 0.80
        end
    end

    return { spellID = bestSpell, confidence = confidence }
end

RA.DecisionTrees[263] = DT
