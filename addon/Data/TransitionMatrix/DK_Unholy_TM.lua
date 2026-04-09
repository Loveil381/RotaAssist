------------------------------------------------------------------------
-- RotaAssist - Transition Matrix: Death Knight / Unholy (252)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.TransitionMatrices then RA.TransitionMatrices = {} end

local TM = {
    specID = 252,
    matrixName = "Unholy_TM",
    version = "12.0.2",
    author = "RotaAssist Team",
    lastUpdated = "2026-02-26",
    matrix = {}
}

-- Initialize empty matrix
TM.matrix = setmetatable({}, {
    __index = function(t, k)
        return setmetatable({}, {
            __index = function() return 0.0 end
        })
    end
})

-- Transition probabilities (spellID -> nextSpellID = probability)
local transitions = {
    [77575]  = { [85948] = 0.85 }, -- Outbreak -> Festering Strike
    [85948]  = { [460463] = 0.70 }, -- Festering Strike -> Putrefy
    [460463] = { [47541] = 0.60 }, -- Putrefy -> Death Coil
    [47541]  = { [55090] = 0.55 }, -- Death Coil -> Scourge Strike
    [55090]  = { [85948] = 0.65 }, -- Scourge Strike -> Festering Strike
    [63560]  = { [460463] = 0.80 }, -- Dark Transformation -> Putrefy
    [42650]  = { [63560] = 0.90 }, -- Army of the Dead -> Dark Transformation
}

for fromSpell, toSpells in pairs(transitions) do
    if not rawget(TM.matrix, fromSpell) then
        rawset(TM.matrix, fromSpell, setmetatable({}, { __index = function() return 0.0 end }))
    end
    for toSpell, prob in pairs(toSpells) do
        TM.matrix[fromSpell][toSpell] = prob
    end
end

function TM:GetTransitionProbability(fromSpellID, toSpellID)
    return self.matrix[fromSpellID][toSpellID] or 0.0
end

RA.TransitionMatrices[252] = TM
