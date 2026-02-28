--- RotaAssist Markov Transition Matrix: Evoker Devastation (specID 1467)
--- 手动编写的湮灭龙希尔转移矩阵 / Evoker Devastation Markov matrix

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 1467
TM.generatedDate = "2026-02-28"

--- Transition probability matrix
--- TM.matrix[fromSpellID][toSpellID] = probability
TM.matrix = {
    [375087] = {  -- Dragonrage
        [357208] = 0.45,
        [370553] = 0.35,
        [359073] = 0.20,
    },
    [357208] = {  -- Fire Breath
        [356995] = 0.55,
        [359073] = 0.25,
        [436335] = 0.20,
    },
    [359073] = {  -- Eternity Surge
        [356995] = 0.50,
        [436335] = 0.30,
        [357211] = 0.20,
    },
    [356995] = {  -- Disintegrate
        [357208] = 0.30,
        [359073] = 0.25,
        [356995] = 0.20,
        [361469] = 0.15,
        [357211] = 0.10,
    },
    [361469] = {  -- Living Flame
        [357208] = 0.35,
        [359073] = 0.30,
        [356995] = 0.20,
        [361469] = 0.15,
    },
    [357211] = {  -- Pyre
        [357208] = 0.35,
        [359073] = 0.30,
        [356995] = 0.20,
        [362969] = 0.15,
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
RA.TransitionMatrices[1467] = TM
