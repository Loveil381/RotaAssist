--- RotaAssist Markov Transition Matrix (specID 71)
--- Auto-generated on 2026-03-15
-- 自动生成的马尔可夫矩阵 / 自動生成マルコフ行列

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 71
TM.generatedDate = "2026-03-15"

TM.matrix = {
    [772] = {  -- Unknown
        [772] = 0.1396,  -- -> Unknown
        [163201] = 0.1374,  -- -> Unknown
        [227847] = 0.1351,  -- -> Unknown
        [107574] = 0.1216,  -- -> Unknown
        [12294] = 0.1216,  -- -> Unknown
        [7384] = 0.1194,  -- -> Unknown
        [167105] = 0.1137,  -- -> Unknown
        [1464] = 0.1115,  -- -> Unknown
    },
    [845] = {  -- Unknown
        [772] = 0.1376,  -- -> Unknown
        [1464] = 0.1376,  -- -> Unknown
        [227847] = 0.1349,  -- -> Unknown
        [107574] = 0.1296,  -- -> Unknown
        [167105] = 0.1217,  -- -> Unknown
        [7384] = 0.1217,  -- -> Unknown
        [12294] = 0.1085,  -- -> Unknown
        [163201] = 0.1085,  -- -> Unknown
    },
    [1464] = {  -- Unknown
        [7384] = 0.1495,  -- -> Unknown
        [1464] = 0.1286,  -- -> Unknown
        [227847] = 0.1286,  -- -> Unknown
        [163201] = 0.1231,  -- -> Unknown
        [772] = 0.122,  -- -> Unknown
        [167105] = 0.1209,  -- -> Unknown
        [12294] = 0.1176,  -- -> Unknown
        [107574] = 0.1099,  -- -> Unknown
    },
    [7384] = {  -- Unknown
        [1464] = 0.1367,  -- -> Unknown
        [7384] = 0.1312,  -- -> Unknown
        [167105] = 0.1291,  -- -> Unknown
        [227847] = 0.128,  -- -> Unknown
        [12294] = 0.1247,  -- -> Unknown
        [772] = 0.1247,  -- -> Unknown
        [163201] = 0.1139,  -- -> Unknown
        [107574] = 0.1117,  -- -> Unknown
    },
    [12294] = {  -- Unknown
        [7384] = 0.1357,  -- -> Unknown
        [12294] = 0.1313,  -- -> Unknown
        [167105] = 0.1279,  -- -> Unknown
        [163201] = 0.1257,  -- -> Unknown
        [772] = 0.1246,  -- -> Unknown
        [1464] = 0.119,  -- -> Unknown
        [107574] = 0.1179,  -- -> Unknown
        [227847] = 0.1179,  -- -> Unknown
    },
    [107574] = {  -- Unknown
        [107574] = 0.1465,  -- -> Unknown
        [163201] = 0.1454,  -- -> Unknown
        [1464] = 0.1278,  -- -> Unknown
        [12294] = 0.1278,  -- -> Unknown
        [227847] = 0.1244,  -- -> Unknown
        [167105] = 0.1134,  -- -> Unknown
        [772] = 0.1101,  -- -> Unknown
        [7384] = 0.1046,  -- -> Unknown
    },
    [163201] = {  -- Unknown
        [107574] = 0.1441,  -- -> Unknown
        [167105] = 0.1397,  -- -> Unknown
        [772] = 0.1286,  -- -> Unknown
        [1464] = 0.1197,  -- -> Unknown
        [7384] = 0.1186,  -- -> Unknown
        [12294] = 0.1175,  -- -> Unknown
        [163201] = 0.1164,  -- -> Unknown
        [227847] = 0.1153,  -- -> Unknown
    },
    [167105] = {  -- Unknown
        [1464] = 0.1337,  -- -> Unknown
        [7384] = 0.1337,  -- -> Unknown
        [107574] = 0.1271,  -- -> Unknown
        [163201] = 0.126,  -- -> Unknown
        [12294] = 0.1249,  -- -> Unknown
        [167105] = 0.1249,  -- -> Unknown
        [227847] = 0.1171,  -- -> Unknown
        [772] = 0.1127,  -- -> Unknown
    },
    [227847] = {  -- Unknown
        [12294] = 0.1338,  -- -> Unknown
        [227847] = 0.1327,  -- -> Unknown
        [772] = 0.1327,  -- -> Unknown
        [167105] = 0.1304,  -- -> Unknown
        [163201] = 0.1237,  -- -> Unknown
        [107574] = 0.1171,  -- -> Unknown
        [7384] = 0.1159,  -- -> Unknown
        [1464] = 0.1137,  -- -> Unknown
    },
    [260643] = {  -- Unknown
        [12294] = 0.1436,  -- -> Unknown
        [1464] = 0.1333,  -- -> Unknown
        [107574] = 0.1308,  -- -> Unknown
        [167105] = 0.1282,  -- -> Unknown
        [772] = 0.1231,  -- -> Unknown
        [227847] = 0.1179,  -- -> Unknown
        [163201] = 0.1154,  -- -> Unknown
        [7384] = 0.1077,  -- -> Unknown
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
RA.TransitionMatrices[71] = TM
