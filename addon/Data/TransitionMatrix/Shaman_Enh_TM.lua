------------------------------------------------------------------------
-- RotaAssist - Transition Matrix: Shaman / Enhancement (263)
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
if not RA.TransitionMatrices then RA.TransitionMatrices = {} end

local TM = {
    specID = 263,
    matrixName = "Enhancement_TM",
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
    [384063] = { [384352] = 0.80, [114051] = 0.80 }, -- Surging Totem -> Doom Winds/Ascendance
    [17364]  = { [187874] = 0.65, [60103] = 0.45 },  -- Stormstrike -> Crash Lightning / Lava Lash
    [187874] = { [17364]  = 0.60 },                  -- Crash Lightning -> Stormstrike
    [60103]  = { [17364]  = 0.55 },                  -- Lava Lash -> Stormstrike
    [188196] = { [17364]  = 0.50 },                  -- Lightning Bolt -> Stormstrike
    [197214] = { [17364]  = 0.70 },                  -- Sundering -> Stormstrike
    [462620] = { [384063] = 0.85 },                  -- Voltaic Blaze -> Surging Totem
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

RA.TransitionMatrices[263] = TM
