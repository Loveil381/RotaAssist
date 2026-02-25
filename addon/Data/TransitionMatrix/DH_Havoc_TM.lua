--- RotaAssist Markov Transition Matrix: DemonHunter Havoc (specID 577)
--- Hand-crafted default based on typical Havoc rotation patterns.
-- 手动编写的浩劫默认马尔可夫矩阵 / Havoc default Markov matrix

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 577
TM.generatedDate = "2026-02-25"

--- Transition probability matrix
--- TM.matrix[fromSpellID][toSpellID] = probability
TM.matrix = {
    [162243] = {  -- Demon's Bite
        [162794] = 0.35,  -- -> Chaos Strike
        [198013] = 0.15,  -- -> Eye Beam
        [258920] = 0.15,  -- -> Immolation Aura
        [188499] = 0.12,  -- -> Blade Dance
        [162243] = 0.08,  -- -> Demon's Bite
        [370965] = 0.05,  -- -> The Hunt
        [258860] = 0.05,  -- -> Essence Break
        [195072] = 0.05,  -- -> Fel Rush
    },
    [162794] = {  -- Chaos Strike
        [162243] = 0.40,  -- -> Demon's Bite
        [198013] = 0.15,  -- -> Eye Beam
        [188499] = 0.12,  -- -> Blade Dance
        [258920] = 0.10,  -- -> Immolation Aura
        [162794] = 0.08,  -- -> Chaos Strike
        [195072] = 0.08,  -- -> Fel Rush
        [258860] = 0.07,  -- -> Essence Break
    },
    [198013] = {  -- Eye Beam
        [162794] = 0.30,  -- -> Chaos Strike
        [201427] = 0.20,  -- -> Annihilation (if meta proc)
        [162243] = 0.15,  -- -> Demon's Bite
        [188499] = 0.12,  -- -> Blade Dance
        [258920] = 0.10,  -- -> Immolation Aura
        [210152] = 0.08,  -- -> Death Sweep (if meta proc)
        [195072] = 0.05,  -- -> Fel Rush
    },
    [188499] = {  -- Blade Dance
        [162243] = 0.35,  -- -> Demon's Bite
        [162794] = 0.25,  -- -> Chaos Strike
        [198013] = 0.12,  -- -> Eye Beam
        [258920] = 0.10,  -- -> Immolation Aura
        [195072] = 0.08,  -- -> Fel Rush
        [185123] = 0.05,  -- -> Throw Glaive
        [258860] = 0.05,  -- -> Essence Break
    },
    [210152] = {  -- Death Sweep
        [201427] = 0.35,  -- -> Annihilation
        [162794] = 0.20,  -- -> Chaos Strike
        [198013] = 0.15,  -- -> Eye Beam
        [162243] = 0.10,  -- -> Demon's Bite
        [258920] = 0.10,  -- -> Immolation Aura
        [195072] = 0.10,  -- -> Fel Rush
    },
    [201427] = {  -- Annihilation
        [201427] = 0.25,  -- -> Annihilation
        [210152] = 0.20,  -- -> Death Sweep
        [162243] = 0.20,  -- -> Demon's Bite
        [198013] = 0.15,  -- -> Eye Beam
        [162794] = 0.10,  -- -> Chaos Strike
        [258920] = 0.10,  -- -> Immolation Aura
    },
    [258920] = {  -- Immolation Aura
        [162243] = 0.30,  -- -> Demon's Bite
        [162794] = 0.25,  -- -> Chaos Strike
        [198013] = 0.15,  -- -> Eye Beam
        [188499] = 0.12,  -- -> Blade Dance
        [195072] = 0.08,  -- -> Fel Rush
        [258860] = 0.05,  -- -> Essence Break
        [370965] = 0.05,  -- -> The Hunt
    },
    [191427] = {  -- Metamorphosis
        [198013] = 0.30,  -- -> Eye Beam
        [210152] = 0.25,  -- -> Death Sweep
        [201427] = 0.20,  -- -> Annihilation
        [258860] = 0.15,  -- -> Essence Break
        [258920] = 0.10,  -- -> Immolation Aura
    },
    [370965] = {  -- The Hunt
        [258860] = 0.25,  -- -> Essence Break
        [198013] = 0.20,  -- -> Eye Beam
        [162794] = 0.20,  -- -> Chaos Strike
        [188499] = 0.15,  -- -> Blade Dance
        [162243] = 0.10,  -- -> Demon's Bite
        [258920] = 0.10,  -- -> Immolation Aura
    },
    [258860] = {  -- Essence Break
        [162794] = 0.35,  -- -> Chaos Strike
        [198013] = 0.20,  -- -> Eye Beam
        [201427] = 0.15,  -- -> Annihilation
        [188499] = 0.12,  -- -> Blade Dance
        [162243] = 0.10,  -- -> Demon's Bite
        [258920] = 0.08,  -- -> Immolation Aura
    },
    [195072] = {  -- Fel Rush
        [162243] = 0.35,  -- -> Demon's Bite
        [162794] = 0.25,  -- -> Chaos Strike
        [198013] = 0.15,  -- -> Eye Beam
        [258920] = 0.10,  -- -> Immolation Aura
        [188499] = 0.10,  -- -> Blade Dance
        [185123] = 0.05,  -- -> Throw Glaive
    },
    [185123] = {  -- Throw Glaive
        [162243] = 0.40,  -- -> Demon's Bite
        [162794] = 0.25,  -- -> Chaos Strike
        [198013] = 0.15,  -- -> Eye Beam
        [258920] = 0.10,  -- -> Immolation Aura
        [188499] = 0.10,  -- -> Blade Dance
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
RA.TransitionMatrices[577] = TM
