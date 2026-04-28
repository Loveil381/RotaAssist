--- RotaAssist Markov Transition Matrix (specID 63)
--- Auto-generated on 2026-04-28
-- 自动生成的马尔可夫矩阵 / 自動生成マルコフ行列

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 63
TM.generatedDate = "2026-04-28"

TM.matrix = {
    [133] = {  -- Unknown
        [2948] = 0.1947,  -- -> Unknown
        [11366] = 0.181,  -- -> Unknown
        [257541] = 0.0969,  -- -> Unknown
        [2120] = 0.093,  -- -> Unknown
        [190319] = 0.089,  -- -> Unknown
        [108853] = 0.0881,  -- -> Unknown
        [153561] = 0.0871,  -- -> Unknown
        [133] = 0.0871,  -- -> Unknown
        [382440] = 0.0832,  -- -> Unknown
    },
    [2120] = {  -- Unknown
        [2948] = 0.1894,  -- -> Unknown
        [11366] = 0.1884,  -- -> Unknown
        [133] = 0.1089,  -- -> Unknown
        [257541] = 0.0928,  -- -> Unknown
        [382440] = 0.09,  -- -> Unknown
        [2120] = 0.089,  -- -> Unknown
        [153561] = 0.0824,  -- -> Unknown
        [108853] = 0.0805,  -- -> Unknown
        [190319] = 0.0786,  -- -> Unknown
    },
    [2948] = {  -- Unknown
        [11366] = 0.1985,  -- -> Unknown
        [2948] = 0.171,  -- -> Unknown
        [257541] = 0.097,  -- -> Unknown
        [2120] = 0.0944,  -- -> Unknown
        [108853] = 0.0925,  -- -> Unknown
        [190319] = 0.0925,  -- -> Unknown
        [153561] = 0.0862,  -- -> Unknown
        [382440] = 0.0862,  -- -> Unknown
        [133] = 0.0817,  -- -> Unknown
    },
    [11366] = {  -- Unknown
        [2948] = 0.1963,  -- -> Unknown
        [11366] = 0.172,  -- -> Unknown
        [190319] = 0.0972,  -- -> Unknown
        [133] = 0.0927,  -- -> Unknown
        [382440] = 0.0914,  -- -> Unknown
        [108853] = 0.0914,  -- -> Unknown
        [153561] = 0.0908,  -- -> Unknown
        [2120] = 0.0876,  -- -> Unknown
        [257541] = 0.0806,  -- -> Unknown
    },
    [44457] = {  -- Unknown
        [2948] = 0.1862,  -- -> Unknown
        [11366] = 0.1727,  -- -> Unknown
        [108853] = 0.1094,  -- -> Unknown
        [190319] = 0.1056,  -- -> Unknown
        [133] = 0.094,  -- -> Unknown
        [382440] = 0.0883,  -- -> Unknown
        [257541] = 0.0825,  -- -> Unknown
        [153561] = 0.0825,  -- -> Unknown
        [2120] = 0.0787,  -- -> Unknown
    },
    [108853] = {  -- Unknown
        [2948] = 0.1974,  -- -> Unknown
        [11366] = 0.1756,  -- -> Unknown
        [2120] = 0.1001,  -- -> Unknown
        [133] = 0.0935,  -- -> Unknown
        [382440] = 0.0925,  -- -> Unknown
        [153561] = 0.0897,  -- -> Unknown
        [108853] = 0.0869,  -- -> Unknown
        [257541] = 0.0831,  -- -> Unknown
        [190319] = 0.0812,  -- -> Unknown
    },
    [153561] = {  -- Unknown
        [2948] = 0.1775,  -- -> Unknown
        [11366] = 0.1727,  -- -> Unknown
        [133] = 0.1059,  -- -> Unknown
        [153561] = 0.1031,  -- -> Unknown
        [2120] = 0.0992,  -- -> Unknown
        [382440] = 0.0964,  -- -> Unknown
        [257541] = 0.0945,  -- -> Unknown
        [190319] = 0.0782,  -- -> Unknown
        [108853] = 0.0725,  -- -> Unknown
    },
    [190319] = {  -- Unknown
        [2948] = 0.1771,  -- -> Unknown
        [11366] = 0.1715,  -- -> Unknown
        [382440] = 0.1016,  -- -> Unknown
        [108853] = 0.1016,  -- -> Unknown
        [257541] = 0.0988,  -- -> Unknown
        [190319] = 0.0951,  -- -> Unknown
        [153561] = 0.0904,  -- -> Unknown
        [133] = 0.0839,  -- -> Unknown
        [2120] = 0.0801,  -- -> Unknown
    },
    [257541] = {  -- Unknown
        [11366] = 0.2012,  -- -> Unknown
        [2948] = 0.167,  -- -> Unknown
        [108853] = 0.0977,  -- -> Unknown
        [257541] = 0.0928,  -- -> Unknown
        [153561] = 0.0928,  -- -> Unknown
        [2120] = 0.0908,  -- -> Unknown
        [190319] = 0.0869,  -- -> Unknown
        [382440] = 0.0859,  -- -> Unknown
        [133] = 0.085,  -- -> Unknown
    },
    [382440] = {  -- Unknown
        [11366] = 0.1775,  -- -> Unknown
        [2948] = 0.1624,  -- -> Unknown
        [190319] = 0.108,  -- -> Unknown
        [153561] = 0.1023,  -- -> Unknown
        [108853] = 0.0967,  -- -> Unknown
        [382440] = 0.0939,  -- -> Unknown
        [2120] = 0.0901,  -- -> Unknown
        [257541] = 0.0873,  -- -> Unknown
        [133] = 0.0817,  -- -> Unknown
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
RA.TransitionMatrices[63] = TM
