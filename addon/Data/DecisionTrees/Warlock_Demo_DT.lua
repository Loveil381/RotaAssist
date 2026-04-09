------------------------------------------------------------------------
-- RotaAssist - Decision Tree: Warlock / Demonology (266)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.DecisionTrees then RA.DecisionTrees = {} end

local DT = {
    specID = 266,
    treeName = "Demonology_DT",
    version = "12.0.2",
    author = "RotaAssist Team",
    lastUpdated = "2026-02-26"
}

function DT:Evaluate(features)
    local bestSpell = 686 -- Fallback: Shadow Bolt
    local confidence = 0.80

    if features.cooldown_265187_remains < 10 then -- Summon Demonic Tyrant available soon
        if features.resource < 3 then
            bestSpell = 686 -- Pool resources: Shadow Bolt
            confidence = 0.85
        elseif features.buff_demonic_core_stacks < 2 then
            bestSpell = 686 -- Pool demonic core stacks
            confidence = 0.82
        else
            bestSpell = 104316 -- Call Dreadstalkers if ready
            confidence = 0.88
        end
    else
        if features.cooldown_104316_ready and features.resource >= 2 then
            bestSpell = 104316 -- Call Dreadstalkers
            confidence = 0.92
        elseif features.cooldown_265187_ready then
            bestSpell = 265187 -- Summon Demonic Tyrant
            confidence = 0.95
        elseif features.resource >= 3 then
            bestSpell = 105174 -- Hand of Gul'dan
            confidence = 0.90
        elseif features.buff_demonic_core_active then
            bestSpell = 264178 -- Demonbolt
            confidence = 0.88
        elseif features.wild_imps >= 6 and features.enemies_in_range >= 2 then
            bestSpell = 196277 -- Implosion
            confidence = 0.90
        else
            bestSpell = 686 -- Shadow Bolt
            confidence = 0.80
        end
    end

    if features.enemies_in_range >= 3 then
        if features.cooldown_104316_ready and features.resource >= 2 then
            bestSpell = 104316 -- Call Dreadstalkers
            confidence = 0.92
        elseif features.resource >= 3 then
            bestSpell = 105174 -- Hand of Gul'dan
            confidence = 0.90
        elseif features.prev_gcd == 105174 then
            bestSpell = 196277 -- Implosion
            confidence = 0.95
        elseif features.cooldown_265187_ready then
            bestSpell = 265187 -- Summon Demonic Tyrant
            confidence = 0.90
        elseif features.buff_demonic_core_active then
            bestSpell = 264178 -- Demonbolt
            confidence = 0.88
        else
            bestSpell = 686 -- Shadow Bolt
            confidence = 0.80
        end
    end

    return { spellID = bestSpell, confidence = confidence }
end

RA.DecisionTrees[266] = DT
