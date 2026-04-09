------------------------------------------------------------------------
-- RotaAssist - Decision Tree: Death Knight / Unholy (252)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.DecisionTrees then RA.DecisionTrees = {} end

local DT = {
    specID = 252,
    treeName = "Unholy_DT",
    version = "12.0.2",
    author = "RotaAssist Team",
    lastUpdated = "2026-02-26"
}

function DT:Evaluate(features)
    local bestSpell = 55090 -- Fallback: Scourge Strike
    local confidence = 0.80

    if features.buff_gargoyle_active then
        if features.resource >= 30 then
            bestSpell = 47541 -- Death Coil (prioritize RP spending)
            confidence = 0.95
        elseif features.debuff_festering_wound >= 1 then
            bestSpell = 55090 -- Scourge Strike
            confidence = 0.85
        else
            bestSpell = 85948 -- Festering Strike
            confidence = 0.85
        end
    elseif not features.debuff_virulent_plague_active then
        bestSpell = 77575 -- Outbreak
        confidence = 0.95
    elseif features.cooldown_42650_ready then
        bestSpell = 42650 -- Army of the Dead
        confidence = 0.95
    elseif features.cooldown_63560_ready then
        bestSpell = 63560 -- Dark Transformation
        confidence = 0.92
    elseif features.cooldown_460463_ready then
        bestSpell = 460463 -- Putrefy
        confidence = 0.90
    elseif features.cooldown_343294_ready or features.target_hp < 0.35 then
        bestSpell = 343294 -- Soul Reaper
        confidence = 0.88
    elseif not features.debuff_festering_scythe_active then
        bestSpell = 460461 -- Festering Scythe
        confidence = 0.88
    elseif features.proc_sudden_doom or features.resource >= 80 then
        bestSpell = 47541 -- Death Coil
        confidence = 0.90
    elseif features.debuff_festering_wound >= 4 then
        bestSpell = 55090 -- Scourge Strike
        confidence = 0.88
    elseif features.debuff_festering_wound < 4 then
        bestSpell = 85948 -- Festering Strike
        confidence = 0.85
    else
        bestSpell = 55090 -- Scourge Strike
        confidence = 0.80
    end

    if features.enemies_in_range >= 4 then
        if not features.debuff_virulent_plague_active then
            bestSpell = 77575 -- Outbreak
            confidence = 0.95
        elseif features.cooldown_42650_ready then
            bestSpell = 42650 -- Army of the Dead
            confidence = 0.92
        elseif features.cooldown_63560_ready then
            bestSpell = 63560 -- Dark Transformation
            confidence = 0.90
        elseif features.cooldown_460463_ready then
            bestSpell = 460463 -- Putrefy
            confidence = 0.88
        elseif not features.debuff_festering_scythe_active then
            bestSpell = 460461 -- Festering Scythe
            confidence = 0.88
        elseif features.proc_sudden_doom or features.resource >= 80 then
            bestSpell = 207317 -- Epidemic
            confidence = 0.92
        elseif features.debuff_festering_wound >= 4 then
            bestSpell = 55090 -- Scourge Strike
            confidence = 0.88
        elseif features.debuff_festering_wound < 2 then
            bestSpell = 85948 -- Festering Strike
            confidence = 0.85
        else
            bestSpell = 207317 -- Epidemic
            confidence = 0.85
        end
    end

    return { spellID = bestSpell, confidence = confidence }
end

RA.DecisionTrees[252] = DT
