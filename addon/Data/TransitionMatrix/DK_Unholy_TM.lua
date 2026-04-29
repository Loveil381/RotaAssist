------------------------------------------------------------------------
-- RotaAssist - Transition Matrix: Death Knight / Unholy (252)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.TransitionMatrices then RA.TransitionMatrices = {} end

local TM = {
    specID      = 252,
    matrixName  = "Unholy_TM",
    version     = "12.0.2",
    author      = "RotaAssist Team",
    lastUpdated = "2026-02-26",
}

-- Transition probabilities (fromSpellID -> { toSpellID = probability })
TM.matrix = {
    [77575]  = { [85948]  = 0.85 }, -- Outbreak -> Festering Strike
    [85948]  = { [460463] = 0.70 }, -- Festering Strike -> Putrefy
    [460463] = { [47541]  = 0.60 }, -- Putrefy -> Death Coil
    [47541]  = { [55090]  = 0.55 }, -- Death Coil -> Scourge Strike
    [55090]  = { [85948]  = 0.65 }, -- Scourge Strike -> Festering Strike
    [63560]  = { [460463] = 0.80 }, -- Dark Transformation -> Putrefy
    [42650]  = { [63560]  = 0.90 }, -- Army of the Dead -> Dark Transformation
}

--- Return the top-N most likely transitions from a given spell, sorted by probability desc.
--- Mirrors the dot-syntax engine contract used by NeuralPredictor.
---@param fromSpellID number
---@param topN number|nil  defaults to 3
---@return table[] list of { spellID, probability }
function TM.GetTopTransitions(fromSpellID, topN)
    topN = topN or 3
    local row = TM.matrix[fromSpellID]
    if not row then return {} end
    local result = {}
    for sid, prob in pairs(row) do
        result[#result + 1] = { spellID = sid, probability = prob }
    end
    table.sort(result, function(a, b) return a.probability > b.probability end)
    local top = {}
    for i = 1, math.min(topN, #result) do top[i] = result[i] end
    return top
end

--- Optional helper kept for legacy callers (not part of the engine contract).
---@param fromSpellID number
---@param toSpellID number
---@return number probability  defaults to 0.0 when unknown
function TM.GetTransitionProbability(fromSpellID, toSpellID)
    local row = TM.matrix[fromSpellID]
    if not row then return 0.0 end
    return row[toSpellID] or 0.0
end

RA.TransitionMatrices[252] = TM
