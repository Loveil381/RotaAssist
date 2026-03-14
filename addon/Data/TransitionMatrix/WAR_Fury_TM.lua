--- RotaAssist Markov Transition Matrix (specID 72)
--- Auto-generated on 2026-03-15
-- 自动生成的马尔可夫矩阵 / 自動生成マルコフ行列

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 72
TM.generatedDate = "2026-03-15"

TM.matrix = {
    [1719] = {  -- Unknown
        [23881] = 0.1417,  -- -> Unknown
        [184367] = 0.1314,  -- -> Unknown
        [1719] = 0.128,  -- -> Unknown
        [107574] = 0.1257,  -- -> Unknown
        [190411] = 0.1246,  -- -> Unknown
        [228920] = 0.1234,  -- -> Unknown
        [85288] = 0.1131,  -- -> Unknown
        [5308] = 0.112,  -- -> Unknown
    },
    [5308] = {  -- Unknown
        [190411] = 0.1393,  -- -> Unknown
        [228920] = 0.1318,  -- -> Unknown
        [5308] = 0.1254,  -- -> Unknown
        [184367] = 0.1243,  -- -> Unknown
        [1719] = 0.1243,  -- -> Unknown
        [85288] = 0.1211,  -- -> Unknown
        [107574] = 0.1168,  -- -> Unknown
        [23881] = 0.1168,  -- -> Unknown
    },
    [6343] = {  -- Unknown
        [85288] = 0.1613,  -- -> Unknown
        [5308] = 0.1425,  -- -> Unknown
        [228920] = 0.1237,  -- -> Unknown
        [1719] = 0.1183,  -- -> Unknown
        [190411] = 0.1156,  -- -> Unknown
        [184367] = 0.1156,  -- -> Unknown
        [107574] = 0.1129,  -- -> Unknown
        [23881] = 0.1102,  -- -> Unknown
    },
    [23881] = {  -- Unknown
        [107574] = 0.14,  -- -> Unknown
        [228920] = 0.1378,  -- -> Unknown
        [85288] = 0.1311,  -- -> Unknown
        [23881] = 0.13,  -- -> Unknown
        [1719] = 0.1233,  -- -> Unknown
        [190411] = 0.12,  -- -> Unknown
        [184367] = 0.1156,  -- -> Unknown
        [5308] = 0.1022,  -- -> Unknown
    },
    [85288] = {  -- Unknown
        [184367] = 0.1595,  -- -> Unknown
        [5308] = 0.1358,  -- -> Unknown
        [190411] = 0.1228,  -- -> Unknown
        [228920] = 0.1228,  -- -> Unknown
        [23881] = 0.1185,  -- -> Unknown
        [107574] = 0.1185,  -- -> Unknown
        [1719] = 0.1121,  -- -> Unknown
        [85288] = 0.1099,  -- -> Unknown
    },
    [107574] = {  -- Unknown
        [5308] = 0.1425,  -- -> Unknown
        [23881] = 0.1334,  -- -> Unknown
        [1719] = 0.1323,  -- -> Unknown
        [85288] = 0.1288,  -- -> Unknown
        [107574] = 0.1254,  -- -> Unknown
        [190411] = 0.1197,  -- -> Unknown
        [184367] = 0.1152,  -- -> Unknown
        [228920] = 0.1026,  -- -> Unknown
    },
    [184367] = {  -- Unknown
        [1719] = 0.1351,  -- -> Unknown
        [190411] = 0.134,  -- -> Unknown
        [23881] = 0.1296,  -- -> Unknown
        [5308] = 0.1285,  -- -> Unknown
        [107574] = 0.1285,  -- -> Unknown
        [85288] = 0.1209,  -- -> Unknown
        [228920] = 0.1122,  -- -> Unknown
        [184367] = 0.1111,  -- -> Unknown
    },
    [190411] = {  -- Unknown
        [184367] = 0.1333,  -- -> Unknown
        [190411] = 0.1321,  -- -> Unknown
        [228920] = 0.1299,  -- -> Unknown
        [5308] = 0.1265,  -- -> Unknown
        [85288] = 0.1254,  -- -> Unknown
        [1719] = 0.1243,  -- -> Unknown
        [23881] = 0.1142,  -- -> Unknown
        [107574] = 0.1142,  -- -> Unknown
    },
    [228920] = {  -- Unknown
        [107574] = 0.1357,  -- -> Unknown
        [228920] = 0.1324,  -- -> Unknown
        [85288] = 0.1246,  -- -> Unknown
        [184367] = 0.1235,  -- -> Unknown
        [23881] = 0.1235,  -- -> Unknown
        [1719] = 0.1224,  -- -> Unknown
        [5308] = 0.1201,  -- -> Unknown
        [190411] = 0.1179,  -- -> Unknown
    },
    [315720] = {  -- Unknown
        [85288] = 0.1485,  -- -> Unknown
        [228920] = 0.1386,  -- -> Unknown
        [1719] = 0.1287,  -- -> Unknown
        [107574] = 0.1262,  -- -> Unknown
        [5308] = 0.1238,  -- -> Unknown
        [23881] = 0.1238,  -- -> Unknown
        [190411] = 0.1089,  -- -> Unknown
        [184367] = 0.1015,  -- -> Unknown
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
RA.TransitionMatrices[72] = TM
