------------------------------------------------------------------------
-- RotaAssist - Transition Matrix: Warlock / Demonology (266)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.TransitionMatrices then RA.TransitionMatrices = {} end

local TM = {
    specID = 266,
    matrixName = "Demonology_TM",
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
    [104316] = { [105174] = 0.75 }, -- Call Dreadstalkers -> Hand of Gul'dan
    [105174] = { [264178] = 0.60, [196277] = 0.35 }, -- Hand of Gul'dan -> Demonbolt / Implosion (AoE)
    [264178] = { [105174] = 0.55 }, -- Demonbolt -> Hand of Gul'dan
    [686]    = { [686] = 0.50, [105174] = 0.35 }, -- Shadow Bolt -> Shadow Bolt / Hand of Gul'dan
    [265187] = { [105174] = 0.80 }, -- Summon Demonic Tyrant -> Hand of Gul'dan
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

RA.TransitionMatrices[266] = TM
