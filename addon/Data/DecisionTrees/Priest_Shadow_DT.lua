------------------------------------------------------------------------
-- RotaAssist - Decision Tree: Priest / Shadow (258)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.DecisionTrees then RA.DecisionTrees = {} end

local DT = {
    specID = 258,
    treeName = "Shadow_DT",
    version = "12.0.2",
    author = "RotaAssist Team",
    lastUpdated = "2026-02-26"
}

function DT:Evaluate(features)
    local bestSpell = 15407 -- Fallback: Mind Flay
    local confidence = 0.80

    if features.buff_voidform_active then
        if features.cooldown_451843_ready then
            bestSpell = 451843 -- Void Volley
            confidence = 0.95
        elseif features.cooldown_228266_ready then
            bestSpell = 228266 -- Void Bolt
            confidence = 0.92
        elseif features.debuff_remains_shadow_word_madness < 1.0 or features.resource_deficit < 35 then
            bestSpell = 451840 -- Shadow Word: Madness
            confidence = 0.90
        elseif features.charges_mind_blast >= 2 then
            bestSpell = 8092 -- Mind Blast
            confidence = 0.85
        elseif features.buff_mind_flay_insanity_active then
            bestSpell = 391403 -- Mind Flay: Insanity
            confidence = 0.85
        else
            bestSpell = 15407 -- Mind Flay
            confidence = 0.80
        end
    else
        if not features.debuff_vampiric_touch_active and not features.cooldown_451329_ready then
            bestSpell = 34914 -- Vampiric Touch
            confidence = 0.95
        elseif features.cooldown_451329_ready then
            bestSpell = 451329 -- Tentacle Slam
            confidence = 0.92
        elseif not features.debuff_shadow_word_pain_active then
            bestSpell = 589 -- Shadow Word: Pain
            confidence = 0.92
        elseif features.cooldown_228260_ready then
            bestSpell = 228260 -- Voidform
            confidence = 0.95
        elseif features.cooldown_120644_ready then
            bestSpell = 120644 -- Halo
            confidence = 0.90
        elseif features.cooldown_263346_ready and features.debuff_shadow_word_madness_active then
            bestSpell = 263346 -- Void Torrent
            confidence = 0.88
        elseif features.charges_mind_blast >= 2 then
            bestSpell = 8092 -- Mind Blast
            confidence = 0.85
        elseif features.debuff_remains_shadow_word_madness < 1.0 or features.resource_deficit < 35 then
            bestSpell = 451840 -- Shadow Word: Madness
            confidence = 0.85
        elseif features.buff_mind_flay_insanity_active then
            bestSpell = 391403 -- Mind Flay: Insanity
            confidence = 0.82
        end
    end

    if features.enemies_in_range >= 3 then
        if features.cooldown_228260_ready then
            bestSpell = 228260 -- Voidform
            confidence = 0.95
        elseif features.cooldown_451329_ready then
            bestSpell = 451329 -- Tentacle Slam
            confidence = 0.92
        elseif not features.debuff_vampiric_touch_active and features.enemies_in_range <= 12 then
            bestSpell = 34914 -- Vampiric Touch (spread)
            confidence = 0.90
        elseif features.resource >= 50 then
            bestSpell = 451840 -- Shadow Word: Madness (AoE spread/funnel)
            confidence = 0.88
        elseif features.buff_voidform_active and features.cooldown_451843_ready then
            bestSpell = 451843 -- Void Volley
            confidence = 0.90
        elseif features.charges_mind_blast >= 2 then
            bestSpell = 8092 -- Mind Blast
            confidence = 0.85
        elseif features.cooldown_120644_ready then
            bestSpell = 120644 -- Halo
            confidence = 0.88
        elseif features.cooldown_263346_ready then
            bestSpell = 263346 -- Void Torrent
            confidence = 0.85
        end
    end

    return { spellID = bestSpell, confidence = confidence }
end

RA.DecisionTrees[258] = DT
