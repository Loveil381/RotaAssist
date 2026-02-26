--- RotaAssist Markov Transition Matrix: Shaman Elemental (specID 262)
local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 262
TM.generatedDate = "2026-02-27"

TM.matrix = {
    [188196] = { [188196] = 0.50, [51505] = 0.30, [8042] = 0.15, [188389] = 0.05 },
    [51505] = { [51505] = 0.40, [188196] = 0.40, [8042] = 0.15, [188389] = 0.05 },
    [8042] = { [188196] = 0.50, [51505] = 0.40, [188389] = 0.10 },
    [188389] = { [51505] = 0.50, [188196] = 0.40, [198067] = 0.10 },
    [191634] = { [188196] = 0.80, [188443] = 0.20 },
    [188443] = { [188443] = 0.60, [61882] = 0.30, [51505] = 0.10 },
    [61882] = { [188443] = 0.70, [51505] = 0.20, [188389] = 0.10 },
    [210714] = { [188196] = 0.60, [8042] = 0.20, [51505] = 0.20 },
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
RA.TransitionMatrices[262] = TM
