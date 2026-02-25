--- RotaAssist Markov Transition Matrix: DemonHunter Vengeance (specID 581)
--- Hand-crafted default based on typical Vengeance rotation patterns.
-- 手动编写的复仇默认马尔可夫矩阵 / Vengeance default Markov matrix

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 581
TM.generatedDate = "2026-02-25"

TM.matrix = {
    [263642] = {  -- Fracture
        [228477] = 0.30,  -- -> Soul Cleave
        [247454] = 0.25,  -- -> Spirit Bomb
        [263642] = 0.12,  -- -> Fracture
        [204596] = 0.10,  -- -> Sigil of Flame
        [258920] = 0.10,  -- -> Immolation Aura
        [203720] = 0.08,  -- -> Demon Spikes
        [204021] = 0.05,  -- -> Fiery Brand
    },
    [228477] = {  -- Soul Cleave
        [263642] = 0.35,  -- -> Fracture
        [204596] = 0.15,  -- -> Sigil of Flame
        [258920] = 0.15,  -- -> Immolation Aura
        [203720] = 0.10,  -- -> Demon Spikes
        [247454] = 0.10,  -- -> Spirit Bomb
        [228477] = 0.08,  -- -> Soul Cleave
        [212084] = 0.07,  -- -> Fel Devastation
    },
    [247454] = {  -- Spirit Bomb
        [263642] = 0.35,  -- -> Fracture
        [204596] = 0.15,  -- -> Sigil of Flame
        [258920] = 0.15,  -- -> Immolation Aura
        [228477] = 0.12,  -- -> Soul Cleave
        [203720] = 0.10,  -- -> Demon Spikes
        [204021] = 0.08,  -- -> Fiery Brand
        [212084] = 0.05,  -- -> Fel Devastation
    },
    [204596] = {  -- Sigil of Flame
        [263642] = 0.35,  -- -> Fracture
        [228477] = 0.20,  -- -> Soul Cleave
        [258920] = 0.15,  -- -> Immolation Aura
        [247454] = 0.10,  -- -> Spirit Bomb
        [203720] = 0.10,  -- -> Demon Spikes
        [204021] = 0.05,  -- -> Fiery Brand
        [212084] = 0.05,  -- -> Fel Devastation
    },
    [258920] = {  -- Immolation Aura
        [263642] = 0.30,  -- -> Fracture
        [228477] = 0.25,  -- -> Soul Cleave
        [247454] = 0.15,  -- -> Spirit Bomb
        [204596] = 0.10,  -- -> Sigil of Flame
        [203720] = 0.10,  -- -> Demon Spikes
        [204021] = 0.05,  -- -> Fiery Brand
        [212084] = 0.05,  -- -> Fel Devastation
    },
    [203720] = {  -- Demon Spikes
        [263642] = 0.30,  -- -> Fracture
        [228477] = 0.20,  -- -> Soul Cleave
        [204596] = 0.15,  -- -> Sigil of Flame
        [258920] = 0.12,  -- -> Immolation Aura
        [247454] = 0.10,  -- -> Spirit Bomb
        [204021] = 0.08,  -- -> Fiery Brand
        [212084] = 0.05,  -- -> Fel Devastation
    },
    [204021] = {  -- Fiery Brand
        [263642] = 0.30,  -- -> Fracture
        [228477] = 0.25,  -- -> Soul Cleave
        [204596] = 0.12,  -- -> Sigil of Flame
        [258920] = 0.10,  -- -> Immolation Aura
        [247454] = 0.10,  -- -> Spirit Bomb
        [203720] = 0.08,  -- -> Demon Spikes
        [212084] = 0.05,  -- -> Fel Devastation
    },
    [212084] = {  -- Fel Devastation
        [263642] = 0.30,  -- -> Fracture
        [228477] = 0.25,  -- -> Soul Cleave
        [247454] = 0.15,  -- -> Spirit Bomb
        [204596] = 0.10,  -- -> Sigil of Flame
        [258920] = 0.10,  -- -> Immolation Aura
        [203720] = 0.10,  -- -> Demon Spikes
    },
    [320341] = {  -- Bulk Extraction
        [263642] = 0.30,  -- -> Fracture
        [228477] = 0.25,  -- -> Soul Cleave
        [258920] = 0.15,  -- -> Immolation Aura
        [204596] = 0.15,  -- -> Sigil of Flame
        [247454] = 0.10,  -- -> Spirit Bomb
        [203720] = 0.05,  -- -> Demon Spikes
    },
}

--- Get top N most probable next spells.
--- @param fromSpellID number
--- @param topN number
--- @return table
function TM.GetTopTransitions(fromSpellID, topN)
    topN = topN or 3
    local row = TM.matrix[fromSpellID]
    if not row then return {} end
    local result = {}
    for sid, prob in pairs(row) do
        result[#result + 1] = {spellID = sid, probability = prob}
    end
    table.sort(result, function(a, b) return a.probability > b.probability end)
    local top = {}
    for i = 1, math.min(topN, #result) do top[i] = result[i] end
    return top
end

RA.TransitionMatrices = RA.TransitionMatrices or {}
RA.TransitionMatrices[581] = TM
