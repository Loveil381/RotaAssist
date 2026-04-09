--- RotaAssist Markov Transition Matrix: Mage Frost (specID 64)
local _, NS = ...
local RA = NS.RA
local TM = {}
TM.specID = 64
TM.generatedDate = "2026-02-26"

TM.matrix = {
    [116] = { [30455] = 0.30, [44614] = 0.25, [116] = 0.20, [199786] = 0.15, [84714] = 0.10 },
    [30455] = { [116] = 0.40, [30455] = 0.30, [44614] = 0.20, [199786] = 0.10 },
    [44614] = { [30455] = 0.60, [116] = 0.30, [199786] = 0.10 },
    [199786] = { [44614] = 0.50, [116] = 0.30, [30455] = 0.20 },
    [84714] = { [30455] = 0.50, [190356] = 0.30, [153595] = 0.20 },
    [190356] = { [30455] = 0.40, [84714] = 0.30, [153595] = 0.20, [116] = 0.10 },
    [153595] = { [30455] = 0.40, [190356] = 0.30, [84714] = 0.20, [116] = 0.10 },
    [205021] = { [30455] = 0.50, [116] = 0.30, [44614] = 0.20 },
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
RA.TransitionMatrices[64] = TM
