--- RotaAssist Markov Transition Matrix (specID 1473)
--- Auto-generated on 2026-02-28
-- 自动生成的马尔可夫矩阵 / 自動生成マルコフ行列

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 1473
TM.generatedDate = "2026-02-28"

TM.matrix = {
    [357208] = {  -- Unknown
        [396286] = 0.1186,  -- -> Unknown
        [395152] = 0.1074,  -- -> Unknown
        [362969] = 0.1064,  -- -> Unknown
        [404977] = 0.1036,  -- -> Unknown
        [361469] = 0.0971,  -- -> Unknown
        [357208] = 0.0962,  -- -> Unknown
        [403631] = 0.0962,  -- -> Unknown
        [409311] = 0.0934,  -- -> Unknown
        [395160] = 0.0915,  -- -> Unknown
        [370553] = 0.0896,  -- -> Unknown
    },
    [361469] = {  -- Unknown
        [404977] = 0.1147,  -- -> Unknown
        [361469] = 0.1061,  -- -> Unknown
        [370553] = 0.1033,  -- -> Unknown
        [357208] = 0.1004,  -- -> Unknown
        [403631] = 0.1004,  -- -> Unknown
        [409311] = 0.0994,  -- -> Unknown
        [395152] = 0.0956,  -- -> Unknown
        [396286] = 0.0956,  -- -> Unknown
        [395160] = 0.0927,  -- -> Unknown
        [362969] = 0.0918,  -- -> Unknown
    },
    [362969] = {  -- Unknown
        [361469] = 0.124,  -- -> Unknown
        [409311] = 0.118,  -- -> Unknown
        [357208] = 0.112,  -- -> Unknown
        [362969] = 0.108,  -- -> Unknown
        [396286] = 0.104,  -- -> Unknown
        [403631] = 0.096,  -- -> Unknown
        [395160] = 0.092,  -- -> Unknown
        [370553] = 0.088,  -- -> Unknown
        [404977] = 0.08,  -- -> Unknown
        [395152] = 0.078,  -- -> Unknown
    },
    [370553] = {  -- Unknown
        [362969] = 0.1129,  -- -> Unknown
        [404977] = 0.1045,  -- -> Unknown
        [395152] = 0.1035,  -- -> Unknown
        [396286] = 0.0998,  -- -> Unknown
        [361469] = 0.0998,  -- -> Unknown
        [403631] = 0.0998,  -- -> Unknown
        [409311] = 0.0989,  -- -> Unknown
        [357208] = 0.097,  -- -> Unknown
        [370553] = 0.0951,  -- -> Unknown
        [395160] = 0.0886,  -- -> Unknown
    },
    [395152] = {  -- Unknown
        [409311] = 0.1126,  -- -> Unknown
        [395160] = 0.1068,  -- -> Unknown
        [361469] = 0.102,  -- -> Unknown
        [357208] = 0.1011,  -- -> Unknown
        [404977] = 0.0991,  -- -> Unknown
        [362969] = 0.0982,  -- -> Unknown
        [395152] = 0.0972,  -- -> Unknown
        [403631] = 0.0972,  -- -> Unknown
        [370553] = 0.0943,  -- -> Unknown
        [396286] = 0.0914,  -- -> Unknown
    },
    [395160] = {  -- Unknown
        [370553] = 0.1211,  -- -> Unknown
        [395152] = 0.1117,  -- -> Unknown
        [395160] = 0.1061,  -- -> Unknown
        [362969] = 0.1052,  -- -> Unknown
        [403631] = 0.1023,  -- -> Unknown
        [396286] = 0.0986,  -- -> Unknown
        [409311] = 0.0977,  -- -> Unknown
        [404977] = 0.0873,  -- -> Unknown
        [361469] = 0.0864,  -- -> Unknown
        [357208] = 0.0836,  -- -> Unknown
    },
    [396286] = {  -- Unknown
        [370553] = 0.1116,  -- -> Unknown
        [403631] = 0.1116,  -- -> Unknown
        [357208] = 0.1097,  -- -> Unknown
        [362969] = 0.1041,  -- -> Unknown
        [361469] = 0.1003,  -- -> Unknown
        [409311] = 0.0984,  -- -> Unknown
        [395160] = 0.0956,  -- -> Unknown
        [396286] = 0.0946,  -- -> Unknown
        [395152] = 0.0889,  -- -> Unknown
        [404977] = 0.0851,  -- -> Unknown
    },
    [403631] = {  -- Unknown
        [409311] = 0.1137,  -- -> Unknown
        [404977] = 0.1108,  -- -> Unknown
        [395160] = 0.1059,  -- -> Unknown
        [370553] = 0.1059,  -- -> Unknown
        [395152] = 0.1059,  -- -> Unknown
        [357208] = 0.0991,  -- -> Unknown
        [361469] = 0.0962,  -- -> Unknown
        [396286] = 0.0923,  -- -> Unknown
        [362969] = 0.0904,  -- -> Unknown
        [403631] = 0.0797,  -- -> Unknown
    },
    [404977] = {  -- Unknown
        [395160] = 0.1189,  -- -> Unknown
        [403631] = 0.1104,  -- -> Unknown
        [409311] = 0.1075,  -- -> Unknown
        [404977] = 0.0999,  -- -> Unknown
        [395152] = 0.099,  -- -> Unknown
        [396286] = 0.099,  -- -> Unknown
        [361469] = 0.098,  -- -> Unknown
        [357208] = 0.0961,  -- -> Unknown
        [362969] = 0.0923,  -- -> Unknown
        [370553] = 0.079,  -- -> Unknown
    },
    [409311] = {  -- Unknown
        [357208] = 0.1113,  -- -> Unknown
        [396286] = 0.1076,  -- -> Unknown
        [370553] = 0.1057,  -- -> Unknown
        [404977] = 0.1048,  -- -> Unknown
        [403631] = 0.1038,  -- -> Unknown
        [361469] = 0.1029,  -- -> Unknown
        [395152] = 0.101,  -- -> Unknown
        [395160] = 0.0982,  -- -> Unknown
        [362969] = 0.0945,  -- -> Unknown
        [409311] = 0.0702,  -- -> Unknown
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
RA.TransitionMatrices[1473] = TM
