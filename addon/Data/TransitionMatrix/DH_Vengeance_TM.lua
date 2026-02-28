--- RotaAssist Markov Transition Matrix (specID 581)
--- Auto-generated on 2026-02-28
-- 自动生成的马尔可夫矩阵 / 自動生成マルコフ行列

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 581
TM.generatedDate = "2026-02-28"

TM.matrix = {
    [185123] = {  -- Throw Glaive
        [263642] = 0.116,  -- -> Fracture
        [228477] = 0.11,  -- -> Soul Cleave
        [204596] = 0.108,  -- -> Sigil of Flame
        [258920] = 0.102,  -- -> Immolation Aura
        [204021] = 0.1,  -- -> Fiery Brand
        [185123] = 0.1,  -- -> Throw Glaive
        [320341] = 0.098,  -- -> Bulk Extraction
        [203720] = 0.096,  -- -> Demon Spikes
        [212084] = 0.086,  -- -> Fel Devastation
        [247454] = 0.084,  -- -> Spirit Bomb
    },
    [189110] = {  -- Infernal Strike
        [258920] = 0.1161,  -- -> Immolation Aura
        [247454] = 0.1161,  -- -> Spirit Bomb
        [185123] = 0.1032,  -- -> Throw Glaive
        [212084] = 0.1011,  -- -> Fel Devastation
        [263642] = 0.1011,  -- -> Fracture
        [228477] = 0.0968,  -- -> Soul Cleave
        [203720] = 0.0968,  -- -> Demon Spikes
        [204021] = 0.0946,  -- -> Fiery Brand
        [320341] = 0.0925,  -- -> Bulk Extraction
        [204596] = 0.0817,  -- -> Sigil of Flame
    },
    [203720] = {  -- Demon Spikes
        [212084] = 0.1146,  -- -> Fel Devastation
        [258920] = 0.1095,  -- -> Immolation Aura
        [204596] = 0.1085,  -- -> Sigil of Flame
        [228477] = 0.1045,  -- -> Soul Cleave
        [320341] = 0.1024,  -- -> Bulk Extraction
        [263642] = 0.1024,  -- -> Fracture
        [204021] = 0.0974,  -- -> Fiery Brand
        [247454] = 0.0933,  -- -> Spirit Bomb
        [185123] = 0.0882,  -- -> Throw Glaive
        [203720] = 0.0791,  -- -> Demon Spikes
    },
    [204021] = {  -- Fiery Brand
        [320341] = 0.1101,  -- -> Bulk Extraction
        [204021] = 0.1091,  -- -> Fiery Brand
        [203720] = 0.104,  -- -> Demon Spikes
        [185123] = 0.103,  -- -> Throw Glaive
        [263642] = 0.103,  -- -> Fracture
        [212084] = 0.101,  -- -> Fel Devastation
        [247454] = 0.096,  -- -> Spirit Bomb
        [228477] = 0.096,  -- -> Soul Cleave
        [204596] = 0.0919,  -- -> Sigil of Flame
        [258920] = 0.0859,  -- -> Immolation Aura
    },
    [204596] = {  -- Sigil of Flame
        [204596] = 0.1112,  -- -> Sigil of Flame
        [185123] = 0.1073,  -- -> Throw Glaive
        [320341] = 0.1073,  -- -> Bulk Extraction
        [212084] = 0.1024,  -- -> Fel Devastation
        [258920] = 0.1015,  -- -> Immolation Aura
        [263642] = 0.0995,  -- -> Fracture
        [228477] = 0.0966,  -- -> Soul Cleave
        [204021] = 0.0966,  -- -> Fiery Brand
        [203720] = 0.0907,  -- -> Demon Spikes
        [247454] = 0.0868,  -- -> Spirit Bomb
    },
    [212084] = {  -- Fel Devastation
        [247454] = 0.1111,  -- -> Spirit Bomb
        [185123] = 0.1072,  -- -> Throw Glaive
        [258920] = 0.1032,  -- -> Immolation Aura
        [263642] = 0.1023,  -- -> Fracture
        [204596] = 0.1023,  -- -> Sigil of Flame
        [204021] = 0.0983,  -- -> Fiery Brand
        [203720] = 0.0973,  -- -> Demon Spikes
        [212084] = 0.0964,  -- -> Fel Devastation
        [228477] = 0.0914,  -- -> Soul Cleave
        [320341] = 0.0905,  -- -> Bulk Extraction
    },
    [228477] = {  -- Soul Cleave
        [228477] = 0.1204,  -- -> Soul Cleave
        [203720] = 0.1045,  -- -> Demon Spikes
        [212084] = 0.1005,  -- -> Fel Devastation
        [247454] = 0.1005,  -- -> Spirit Bomb
        [204596] = 0.1005,  -- -> Sigil of Flame
        [320341] = 0.0995,  -- -> Bulk Extraction
        [185123] = 0.0995,  -- -> Throw Glaive
        [204021] = 0.0935,  -- -> Fiery Brand
        [258920] = 0.0915,  -- -> Immolation Aura
        [263642] = 0.0896,  -- -> Fracture
    },
    [247454] = {  -- Spirit Bomb
        [263642] = 0.1115,  -- -> Fracture
        [228477] = 0.1094,  -- -> Soul Cleave
        [203720] = 0.1084,  -- -> Demon Spikes
        [247454] = 0.1074,  -- -> Spirit Bomb
        [185123] = 0.1002,  -- -> Throw Glaive
        [204596] = 0.0992,  -- -> Sigil of Flame
        [258920] = 0.0941,  -- -> Immolation Aura
        [320341] = 0.093,  -- -> Bulk Extraction
        [204021] = 0.093,  -- -> Fiery Brand
        [212084] = 0.0838,  -- -> Fel Devastation
    },
    [258920] = {  -- Immolation Aura
        [247454] = 0.1115,  -- -> Spirit Bomb
        [212084] = 0.1076,  -- -> Fel Devastation
        [258920] = 0.1057,  -- -> Immolation Aura
        [203720] = 0.1018,  -- -> Demon Spikes
        [185123] = 0.1008,  -- -> Throw Glaive
        [320341] = 0.0988,  -- -> Bulk Extraction
        [204021] = 0.0978,  -- -> Fiery Brand
        [228477] = 0.0949,  -- -> Soul Cleave
        [204596] = 0.092,  -- -> Sigil of Flame
        [263642] = 0.089,  -- -> Fracture
    },
    [263642] = {  -- Fracture
        [204596] = 0.1104,  -- -> Sigil of Flame
        [204021] = 0.1094,  -- -> Fiery Brand
        [320341] = 0.1074,  -- -> Bulk Extraction
        [263642] = 0.1014,  -- -> Fracture
        [212084] = 0.0994,  -- -> Fel Devastation
        [247454] = 0.0984,  -- -> Spirit Bomb
        [203720] = 0.0984,  -- -> Demon Spikes
        [258920] = 0.0944,  -- -> Immolation Aura
        [185123] = 0.0924,  -- -> Throw Glaive
        [228477] = 0.0884,  -- -> Soul Cleave
    },
    [320341] = {  -- Bulk Extraction
        [203720] = 0.1192,  -- -> Demon Spikes
        [204021] = 0.1074,  -- -> Fiery Brand
        [258920] = 0.1044,  -- -> Immolation Aura
        [212084] = 0.1005,  -- -> Fel Devastation
        [185123] = 0.0995,  -- -> Throw Glaive
        [320341] = 0.0956,  -- -> Bulk Extraction
        [228477] = 0.0956,  -- -> Soul Cleave
        [247454] = 0.0956,  -- -> Spirit Bomb
        [263642] = 0.0936,  -- -> Fracture
        [204596] = 0.0887,  -- -> Sigil of Flame
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
