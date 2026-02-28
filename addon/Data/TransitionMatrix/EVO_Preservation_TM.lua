--- RotaAssist Markov Transition Matrix (specID 1468)
--- Auto-generated on 2026-02-28
-- 自动生成的马尔可夫矩阵 / 自動生成マルコフ行列

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 1468
TM.generatedDate = "2026-02-28"

TM.matrix = {
    [355913] = {  -- Unknown
        [367226] = 0.1113,  -- -> Unknown
        [382731] = 0.1071,  -- -> Unknown
        [361469] = 0.106,  -- -> Unknown
        [364343] = 0.1029,  -- -> Unknown
        [360995] = 0.0997,  -- -> Unknown
        [382614] = 0.0997,  -- -> Unknown
        [355913] = 0.0986,  -- -> Unknown
        [357208] = 0.0933,  -- -> Unknown
        [362969] = 0.0912,  -- -> Unknown
        [366155] = 0.0901,  -- -> Unknown
    },
    [357208] = {  -- Unknown
        [364343] = 0.1167,  -- -> Unknown
        [366155] = 0.107,  -- -> Unknown
        [361469] = 0.107,  -- -> Unknown
        [355913] = 0.1041,  -- -> Unknown
        [357208] = 0.1013,  -- -> Unknown
        [382731] = 0.0955,  -- -> Unknown
        [362969] = 0.0945,  -- -> Unknown
        [367226] = 0.0945,  -- -> Unknown
        [382614] = 0.0916,  -- -> Unknown
        [360995] = 0.0878,  -- -> Unknown
    },
    [360995] = {  -- Unknown
        [382614] = 0.1113,  -- -> Unknown
        [382731] = 0.1083,  -- -> Unknown
        [357208] = 0.1073,  -- -> Unknown
        [366155] = 0.1052,  -- -> Unknown
        [360995] = 0.1021,  -- -> Unknown
        [361469] = 0.0981,  -- -> Unknown
        [364343] = 0.0981,  -- -> Unknown
        [355913] = 0.094,  -- -> Unknown
        [367226] = 0.0919,  -- -> Unknown
        [362969] = 0.0838,  -- -> Unknown
    },
    [361469] = {  -- Unknown
        [362969] = 0.1201,  -- -> Unknown
        [355913] = 0.1039,  -- -> Unknown
        [360995] = 0.1039,  -- -> Unknown
        [364343] = 0.103,  -- -> Unknown
        [382614] = 0.1001,  -- -> Unknown
        [366155] = 0.0991,  -- -> Unknown
        [357208] = 0.0972,  -- -> Unknown
        [367226] = 0.0934,  -- -> Unknown
        [382731] = 0.0925,  -- -> Unknown
        [361469] = 0.0867,  -- -> Unknown
    },
    [362969] = {  -- Unknown
        [366155] = 0.1186,  -- -> Unknown
        [382614] = 0.1117,  -- -> Unknown
        [367226] = 0.1097,  -- -> Unknown
        [364343] = 0.0998,  -- -> Unknown
        [355913] = 0.0988,  -- -> Unknown
        [382731] = 0.0978,  -- -> Unknown
        [361469] = 0.0968,  -- -> Unknown
        [362969] = 0.0949,  -- -> Unknown
        [357208] = 0.0889,  -- -> Unknown
        [360995] = 0.083,  -- -> Unknown
    },
    [364343] = {  -- Unknown
        [362969] = 0.1122,  -- -> Unknown
        [366155] = 0.1092,  -- -> Unknown
        [361469] = 0.1092,  -- -> Unknown
        [357208] = 0.1001,  -- -> Unknown
        [355913] = 0.0991,  -- -> Unknown
        [382614] = 0.0981,  -- -> Unknown
        [364343] = 0.0981,  -- -> Unknown
        [360995] = 0.095,  -- -> Unknown
        [367226] = 0.093,  -- -> Unknown
        [382731] = 0.0859,  -- -> Unknown
    },
    [366155] = {  -- Unknown
        [360995] = 0.1158,  -- -> Unknown
        [362969] = 0.1109,  -- -> Unknown
        [382731] = 0.1099,  -- -> Unknown
        [382614] = 0.1051,  -- -> Unknown
        [367226] = 0.1031,  -- -> Unknown
        [357208] = 0.1031,  -- -> Unknown
        [361469] = 0.0944,  -- -> Unknown
        [355913] = 0.0885,  -- -> Unknown
        [366155] = 0.0866,  -- -> Unknown
        [364343] = 0.0827,  -- -> Unknown
    },
    [367226] = {  -- Unknown
        [355913] = 0.1153,  -- -> Unknown
        [360995] = 0.1133,  -- -> Unknown
        [357208] = 0.102,  -- -> Unknown
        [366155] = 0.102,  -- -> Unknown
        [364343] = 0.098,  -- -> Unknown
        [382614] = 0.0969,  -- -> Unknown
        [362969] = 0.0969,  -- -> Unknown
        [367226] = 0.0969,  -- -> Unknown
        [382731] = 0.0929,  -- -> Unknown
        [361469] = 0.0857,  -- -> Unknown
    },
    [382614] = {  -- Unknown
        [361469] = 0.1063,  -- -> Unknown
        [367226] = 0.1043,  -- -> Unknown
        [362969] = 0.1023,  -- -> Unknown
        [366155] = 0.1003,  -- -> Unknown
        [360995] = 0.1003,  -- -> Unknown
        [364343] = 0.1003,  -- -> Unknown
        [355913] = 0.0983,  -- -> Unknown
        [382731] = 0.0963,  -- -> Unknown
        [382614] = 0.0963,  -- -> Unknown
        [357208] = 0.0953,  -- -> Unknown
    },
    [382731] = {  -- Unknown
        [382731] = 0.1147,  -- -> Unknown
        [357208] = 0.1117,  -- -> Unknown
        [361469] = 0.1107,  -- -> Unknown
        [367226] = 0.1025,  -- -> Unknown
        [364343] = 0.1005,  -- -> Unknown
        [360995] = 0.0995,  -- -> Unknown
        [355913] = 0.0995,  -- -> Unknown
        [362969] = 0.0904,  -- -> Unknown
        [382614] = 0.0893,  -- -> Unknown
        [366155] = 0.0812,  -- -> Unknown
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
RA.TransitionMatrices[1468] = TM
