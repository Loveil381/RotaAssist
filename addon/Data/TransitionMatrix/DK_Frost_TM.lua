--- RotaAssist Markov Transition Matrix: Death Knight Frost (specID 251)
local _, NS = ...
local RA = NS.RA
local TM = {}
TM.specID = 251
TM.generatedDate = "2026-02-26"

TM.matrix = {
    [49020] = { [49143] = 0.35, [49020] = 0.25, [49184] = 0.20, [196770] = 0.15, [279302] = 0.05 },
    [49143] = { [49020] = 0.40, [49184] = 0.20, [49143] = 0.20, [196770] = 0.15, [279302] = 0.05 },
    [49184] = { [49020] = 0.40, [49143] = 0.30, [196770] = 0.15, [49184] = 0.10, [279302] = 0.05 },
    [196770] = { [49020] = 0.40, [49143] = 0.30, [49184] = 0.20, [279302] = 0.10 },
    [279302] = { [49020] = 0.40, [49143] = 0.30, [49184] = 0.20, [196770] = 0.10 },
    [47568] = { [51271] = 0.40, [196770] = 0.30, [49020] = 0.20, [49184] = 0.10 },
}

function TM.GetTopTransitions(fromSpellID, topN)
    topN = topN or 3
    local row = TM.matrix[fromSpellID]
    if not row then return {} end
    local result = {}
    for sid, prob in pairs(row) do result[#result + 1] = {spellID = sid, probability = prob} end
    table.sort(result, function(a, b) return a.probability > b.probability end)
    local top = {}
    for i = 1, math.min(topN, #result) do top[i] = result[i] end
    return top
end

RA.TransitionMatrices = RA.TransitionMatrices or {}
RA.TransitionMatrices[251] = TM
