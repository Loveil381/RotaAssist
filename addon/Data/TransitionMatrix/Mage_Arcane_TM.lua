------------------------------------------------------------------------
-- RotaAssist - Transition Matrix: Mage / Arcane (62)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.TransitionMatrices then RA.TransitionMatrices = {} end

local TM = {
    specID = 62,
    matrixName = "Arcane_TM",
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
    [365362] = { [321507] = 0.90 }, -- Arcane Surge -> Touch of the Magi
    [321507] = { [44425]  = 0.75 }, -- Touch of the Magi -> Arcane Barrage
    [30451]  = { [30451]  = 0.55, [44425] = 0.30 }, -- Arcane Blast -> Arcane Blast / Arcane Barrage
    [44425]  = { [30451]  = 0.80 }, -- Arcane Barrage -> Arcane Blast
    [5143]   = { [30451]  = 0.70 }, -- Arcane Missiles -> Arcane Blast
    [153626] = { [30451]  = 0.65 }, -- Arcane Orb -> Arcane Blast
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

RA.TransitionMatrices[62] = TM
