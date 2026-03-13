--- RotaAssist Markov Transition Matrix: DemonHunter Devourer (specID 1480)
--- Hand-crafted default based on early Devourer rotation guides.
-- 吞噬者默认马尔可夫矩阵 / Devourer default Markov matrix

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 1480
TM.generatedDate = "2026-02-25"

TM.matrix = {
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
    [442501] = {  -- Consume
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442515] = 0.30,  -- -> Reap
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442507] = 0.20,  -- -> Void Ray
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442510] = 0.18,  -- -> Collapsing Star
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [258920] = 0.12,  -- -> Immolation Aura
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442501] = 0.10,  -- -> Consume
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442525] = 0.10,  -- -> Soul Immolation
    },
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
    [442515] = {  -- Reap
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442501] = 0.30,  -- -> Consume
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442507] = 0.25,  -- -> Void Ray
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442510] = 0.15,  -- -> Collapsing Star
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [258920] = 0.12,  -- -> Immolation Aura
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442525] = 0.10,  -- -> Soul Immolation
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442515] = 0.08,  -- -> Reap
    },
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
    [442507] = {  -- Void Ray
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442501] = 0.30,  -- -> Consume
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442515] = 0.25,  -- -> Reap
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442510] = 0.15,  -- -> Collapsing Star
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [258920] = 0.12,  -- -> Immolation Aura
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442507] = 0.10,  -- -> Void Ray
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442525] = 0.08,  -- -> Soul Immolation
    },
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
    [442510] = {  -- Collapsing Star
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442501] = 0.35,  -- -> Consume
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442515] = 0.20,  -- -> Reap
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442507] = 0.15,  -- -> Void Ray
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [258920] = 0.12,  -- -> Immolation Aura
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442525] = 0.10,  -- -> Soul Immolation
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442510] = 0.08,  -- -> Collapsing Star
    },
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
    [258920] = {  -- Immolation Aura
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442501] = 0.30,  -- -> Consume
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442515] = 0.25,  -- -> Reap
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442507] = 0.15,  -- -> Void Ray
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442510] = 0.12,  -- -> Collapsing Star
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442525] = 0.10,  -- -> Soul Immolation
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [258920] = 0.08,  -- -> Immolation Aura
    },
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
    [442508] = {  -- Void Metamorphosis
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442507] = 0.30,  -- -> Void Ray
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442510] = 0.25,  -- -> Collapsing Star
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442525] = 0.20,  -- -> Soul Immolation
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442501] = 0.15,  -- -> Consume
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [258920] = 0.10,  -- -> Immolation Aura
    },
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
    [442525] = {  -- Soul Immolation
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442501] = 0.30,  -- -> Consume
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442515] = 0.25,  -- -> Reap
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442507] = 0.15,  -- -> Void Ray
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442510] = 0.12,  -- -> Collapsing Star
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [258920] = 0.10,  -- -> Immolation Aura
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442525] = 0.08,  -- -> Soul Immolation
    },
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
    [442520] = {  -- Voidblade
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442501] = 0.30,  -- -> Consume
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442507] = 0.25,  -- -> Void Ray
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442515] = 0.15,  -- -> Reap
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442510] = 0.12,  -- -> Collapsing Star
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [258920] = 0.10,  -- -> Immolation Aura
-- ⚠ UNVERIFIED: Placeholder spellID, needs 12.0 live verification
        [442525] = 0.08,  -- -> Soul Immolation
    },
}

--- Get top N most probable next spells.
--- @param fromSpellID number
--- @param topN number
--- @return table
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
RA.TransitionMatrices[1480] = TM
