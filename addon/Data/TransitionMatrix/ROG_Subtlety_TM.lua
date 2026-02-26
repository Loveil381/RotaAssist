--- RotaAssist Markov Transition Matrix: Rogue Subtlety (specID 261)
local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 261
TM.generatedDate = "2026-02-27"

TM.matrix = {
    [53] = { [53] = 0.50, [196819] = 0.30, [1943] = 0.10, [185313] = 0.10 },
    [185438] = { [185438] = 0.40, [196819] = 0.40, [1943] = 0.10, [280719] = 0.10 },
    [196819] = { [53] = 0.40, [185438] = 0.40, [212283] = 0.10, [185313] = 0.10 },
    [1943] = { [53] = 0.50, [185438] = 0.40, [121471] = 0.10 },
    [280719] = { [185438] = 0.50, [53] = 0.30, [185313] = 0.20 },
    [122281] = { [122281] = 0.40, [319175] = 0.40, [185313] = 0.20 },
    [319175] = { [122281] = 0.60, [185438] = 0.30, [280719] = 0.10 },
}

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
RA.TransitionMatrices[261] = TM
