--- RotaAssist Markov Transition Matrix: Druid Balance (specID 102)
local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 102
TM.generatedDate = "2026-02-27"

TM.matrix = {
    [190984] = { [190984] = 0.50, [78674] = 0.30, [8921] = 0.10, [93402] = 0.10 },
    [78674] = { [190984] = 0.60, [194153] = 0.20, [8921] = 0.10, [93402] = 0.10 },
    [8921] = { [190984] = 0.50, [93402] = 0.30, [78674] = 0.20 },
    [93402] = { [190984] = 0.50, [8921] = 0.30, [78674] = 0.20 },
    [202347] = { [190984] = 0.60, [78674] = 0.20, [8921] = 0.20 },
    [194153] = { [194153] = 0.60, [191034] = 0.20, [93402] = 0.20 },
    [191034] = { [194153] = 0.60, [190984] = 0.20, [93402] = 0.20 },
    [194223] = { [190984] = 0.40, [194153] = 0.30, [78674] = 0.30 },
    [102560] = { [190984] = 0.40, [194153] = 0.30, [78674] = 0.30 },
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
RA.TransitionMatrices[102] = TM
