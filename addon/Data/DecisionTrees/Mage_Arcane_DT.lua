------------------------------------------------------------------------
-- RotaAssist - Decision Tree: Mage / Arcane (62)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.DecisionTrees then RA.DecisionTrees = {} end

local DT = {
    specID = 62,
    treeName = "Arcane_DT",
    version = "12.0.2",
    author = "RotaAssist Team",
    lastUpdated = "2026-02-26"
}

function DT:Evaluate(features)
    local bestSpell = 30451 -- Fallback: Arcane Blast
    local confidence = 0.85

    if features.cooldown_365362_ready then -- Arcane Surge available
        if features.cooldown_321507_remains > 5 then
            bestSpell = 365362 -- Arcane Surge
            confidence = 0.95
        else
            bestSpell = 321507 -- Touch of the Magi
            confidence = 0.95
        end
    elseif features.cooldown_321507_ready then
        bestSpell = 321507 -- Touch of the Magi
        confidence = 0.92
    elseif features.secondary_resource >= 4 and features.salvo_stacks_max then
        bestSpell = 44425 -- Arcane Barrage
        confidence = 0.90
    elseif features.buff_clearcasting_active then
        bestSpell = 5143 -- Arcane Missiles
        confidence = 0.88
    elseif features.cooldown_153626_ready then
        bestSpell = 153626 -- Arcane Orb
        confidence = 0.88
    elseif features.resource_pct < 0.15 then
        bestSpell = 44425 -- Arcane Barrage (Mana < 15%)
        confidence = 0.90
    else
        bestSpell = 30451 -- Arcane Blast
        confidence = 0.85
    end

    if features.enemies_in_range >= 3 then
        if features.cooldown_321507_ready then
            bestSpell = 321507 -- Touch of the Magi
            confidence = 0.95
        elseif features.cooldown_365362_ready then
            bestSpell = 365362 -- Arcane Surge
            confidence = 0.95
        elseif features.cooldown_153626_ready then
            bestSpell = 153626 -- Arcane Orb
            confidence = 0.90
        elseif features.secondary_resource >= 4 and features.salvo_stacks_max then
            bestSpell = 44425 -- Arcane Barrage
            confidence = 0.92
        elseif features.in_melee then
            bestSpell = 1449 -- Arcane Explosion
            confidence = 0.88
        else
            bestSpell = 30451 -- Arcane Blast
            confidence = 0.85
        end
    end

    return { spellID = bestSpell, confidence = confidence }
end

RA.DecisionTrees[62] = DT
