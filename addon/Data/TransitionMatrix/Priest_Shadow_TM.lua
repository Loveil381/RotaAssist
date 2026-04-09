------------------------------------------------------------------------
-- RotaAssist - Transition Matrix: Priest / Shadow (258)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.TransitionMatrices then RA.TransitionMatrices = {} end

local TM = {
    specID = 258,
    matrixName = "Shadow_TM",
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
    [228260] = { [263346] = 0.80 }, -- Voidform -> Void Torrent
    [263346] = { [451843] = 0.70 }, -- Void Torrent -> Void Volley
    [451843] = { [8092]   = 0.60 }, -- Void Volley -> Mind Blast
    [8092]   = { [451840] = 0.55 }, -- Mind Blast -> Shadow Word: Madness
    [451840] = { [8092]   = 0.50 }, -- Shadow Word: Madness -> Mind Blast
    [15407]  = { [8092]   = 0.45 }, -- Mind Flay -> Mind Blast
    [451329] = { [34914]  = 0.85 }, -- Tentacle Slam -> Vampiric Touch
    [120644] = { [228260] = 0.75 }, -- Halo -> Voidform
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

RA.TransitionMatrices[258] = TM
