--- RotaAssist Markov Transition Matrix: Paladin Retribution (specID 70)
local _, NS = ...
local RA = NS.RA
local TM = {}
TM.specID = 70
TM.generatedDate = "2026-02-26"

TM.matrix = {
    [35395] = { [20271] = 0.30, [184575] = 0.25, [53385] = 0.20, [343527] = 0.15, [24275] = 0.10 },
    [184575] = { [20271] = 0.30, [53385] = 0.25, [343527] = 0.20, [24275] = 0.15, [35395] = 0.10 },
    [20271] = { [184575] = 0.30, [53385] = 0.25, [35395] = 0.20, [343527] = 0.15, [24275] = 0.10 },
    [53385] = { [184575] = 0.30, [20271] = 0.25, [35395] = 0.20, [24275] = 0.15, [255937] = 0.10 },
    [24275] = { [53385] = 0.35, [343527] = 0.20, [184575] = 0.20, [20271] = 0.15, [35395] = 0.10 },
    [255937] = { [53385] = 0.40, [343527] = 0.25, [427453] = 0.20, [24275] = 0.15 },
    [375576] = { [53385] = 0.40, [343527] = 0.25, [255937] = 0.20, [24275] = 0.15 },
    [343527] = { [427453] = 0.30, [255937] = 0.25, [53385] = 0.20, [24275] = 0.15, [184575] = 0.10 },
    [427453] = { [53385] = 0.30, [184575] = 0.25, [20271] = 0.25, [35395] = 0.20 },
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
RA.TransitionMatrices[70] = TM
