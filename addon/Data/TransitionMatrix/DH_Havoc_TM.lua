--- RotaAssist Markov Transition Matrix (specID 577)
--- Auto-generated on 2026-02-28
-- 自动生成的马尔可夫矩阵 / 自動生成マルコフ行列

local _, NS = ...
local RA = NS.RA
local TM = {}

TM.specID = 577
TM.generatedDate = "2026-02-28"

TM.matrix = {
    [162243] = {  -- Demon's Bite
        [342817] = 0.095,  -- -> Glaive Tempest
        [185123] = 0.0877,  -- -> Throw Glaive
        [258860] = 0.0866,  -- -> Essence Break
        [195072] = 0.0846,  -- -> Fel Rush
        [162794] = 0.0825,  -- -> Chaos Strike
        [370965] = 0.0793,  -- -> The Hunt
        [210152] = 0.0752,  -- -> Death Sweep
        [258920] = 0.0741,  -- -> Immolation Aura
        [162243] = 0.0731,  -- -> Demon's Bite
        [191427] = 0.0699,  -- -> Metamorphosis
        [188499] = 0.0668,  -- -> Blade Dance
        [198013] = 0.0658,  -- -> Eye Beam
        [201427] = 0.0595,  -- -> Annihilation
    },
    [162794] = {  -- Chaos Strike
        [162243] = 0.0844,  -- -> Demon's Bite
        [191427] = 0.0844,  -- -> Metamorphosis
        [342817] = 0.0823,  -- -> Glaive Tempest
        [198013] = 0.0823,  -- -> Eye Beam
        [258860] = 0.0823,  -- -> Essence Break
        [188499] = 0.0812,  -- -> Blade Dance
        [210152] = 0.0769,  -- -> Death Sweep
        [185123] = 0.0737,  -- -> Throw Glaive
        [195072] = 0.0726,  -- -> Fel Rush
        [162794] = 0.0726,  -- -> Chaos Strike
        [201427] = 0.0705,  -- -> Annihilation
        [258920] = 0.0705,  -- -> Immolation Aura
        [370965] = 0.0662,  -- -> The Hunt
    },
    [185123] = {  -- Throw Glaive
        [162794] = 0.0889,  -- -> Chaos Strike
        [191427] = 0.0858,  -- -> Metamorphosis
        [162243] = 0.0827,  -- -> Demon's Bite
        [258860] = 0.0817,  -- -> Essence Break
        [195072] = 0.0817,  -- -> Fel Rush
        [198013] = 0.0787,  -- -> Eye Beam
        [258920] = 0.0766,  -- -> Immolation Aura
        [210152] = 0.0756,  -- -> Death Sweep
        [370965] = 0.0725,  -- -> The Hunt
        [185123] = 0.0715,  -- -> Throw Glaive
        [342817] = 0.0695,  -- -> Glaive Tempest
        [201427] = 0.0684,  -- -> Annihilation
        [188499] = 0.0664,  -- -> Blade Dance
    },
    [188499] = {  -- Blade Dance
        [191427] = 0.0923,  -- -> Metamorphosis
        [370965] = 0.0882,  -- -> The Hunt
        [201427] = 0.083,  -- -> Annihilation
        [162794] = 0.082,  -- -> Chaos Strike
        [342817] = 0.0788,  -- -> Glaive Tempest
        [210152] = 0.0768,  -- -> Death Sweep
        [258920] = 0.0757,  -- -> Immolation Aura
        [195072] = 0.0757,  -- -> Fel Rush
        [258860] = 0.0747,  -- -> Essence Break
        [185123] = 0.0705,  -- -> Throw Glaive
        [162243] = 0.0695,  -- -> Demon's Bite
        [188499] = 0.0664,  -- -> Blade Dance
        [198013] = 0.0664,  -- -> Eye Beam
    },
    [191427] = {  -- Metamorphosis
        [258920] = 0.1011,  -- -> Immolation Aura
        [370965] = 0.0915,  -- -> The Hunt
        [201427] = 0.084,  -- -> Annihilation
        [198013] = 0.084,  -- -> Eye Beam
        [210152] = 0.0819,  -- -> Death Sweep
        [258860] = 0.0777,  -- -> Essence Break
        [195072] = 0.0755,  -- -> Fel Rush
        [162243] = 0.0734,  -- -> Demon's Bite
        [191427] = 0.0713,  -- -> Metamorphosis
        [342817] = 0.0702,  -- -> Glaive Tempest
        [162794] = 0.0702,  -- -> Chaos Strike
        [185123] = 0.0649,  -- -> Throw Glaive
        [188499] = 0.0543,  -- -> Blade Dance
    },
    [195072] = {  -- Fel Rush
        [195072] = 0.096,  -- -> Fel Rush
        [188499] = 0.0858,  -- -> Blade Dance
        [191427] = 0.0787,  -- -> Metamorphosis
        [201427] = 0.0776,  -- -> Annihilation
        [342817] = 0.0766,  -- -> Glaive Tempest
        [210152] = 0.0766,  -- -> Death Sweep
        [162243] = 0.0766,  -- -> Demon's Bite
        [258920] = 0.0756,  -- -> Immolation Aura
        [198013] = 0.0735,  -- -> Eye Beam
        [185123] = 0.0715,  -- -> Throw Glaive
        [162794] = 0.0715,  -- -> Chaos Strike
        [370965] = 0.0705,  -- -> The Hunt
        [258860] = 0.0695,  -- -> Essence Break
    },
    [198013] = {  -- Eye Beam
        [162243] = 0.1053,  -- -> Demon's Bite
        [185123] = 0.0815,  -- -> Throw Glaive
        [198013] = 0.0805,  -- -> Eye Beam
        [188499] = 0.0805,  -- -> Blade Dance
        [210152] = 0.0795,  -- -> Death Sweep
        [342817] = 0.0774,  -- -> Glaive Tempest
        [191427] = 0.0764,  -- -> Metamorphosis
        [258920] = 0.0753,  -- -> Immolation Aura
        [258860] = 0.0753,  -- -> Essence Break
        [162794] = 0.0722,  -- -> Chaos Strike
        [370965] = 0.0681,  -- -> The Hunt
        [195072] = 0.065,  -- -> Fel Rush
        [201427] = 0.063,  -- -> Annihilation
    },
    [198793] = {  -- Vengeful Retreat
        [195072] = 0.1074,  -- -> Fel Rush
        [185123] = 0.0872,  -- -> Throw Glaive
        [198013] = 0.085,  -- -> Eye Beam
        [191427] = 0.0828,  -- -> Metamorphosis
        [342817] = 0.0761,  -- -> Glaive Tempest
        [188499] = 0.0761,  -- -> Blade Dance
        [370965] = 0.0761,  -- -> The Hunt
        [162794] = 0.0738,  -- -> Chaos Strike
        [258920] = 0.0716,  -- -> Immolation Aura
        [210152] = 0.0694,  -- -> Death Sweep
        [201427] = 0.0671,  -- -> Annihilation
        [258860] = 0.0649,  -- -> Essence Break
        [162243] = 0.0626,  -- -> Demon's Bite
    },
    [201427] = {  -- Annihilation
        [201427] = 0.0996,  -- -> Annihilation
        [342817] = 0.0874,  -- -> Glaive Tempest
        [210152] = 0.0813,  -- -> Death Sweep
        [185123] = 0.0813,  -- -> Throw Glaive
        [188499] = 0.0803,  -- -> Blade Dance
        [191427] = 0.0793,  -- -> Metamorphosis
        [162794] = 0.0772,  -- -> Chaos Strike
        [370965] = 0.0732,  -- -> The Hunt
        [258920] = 0.0732,  -- -> Immolation Aura
        [198013] = 0.0711,  -- -> Eye Beam
        [162243] = 0.0671,  -- -> Demon's Bite
        [258860] = 0.0661,  -- -> Essence Break
        [195072] = 0.063,  -- -> Fel Rush
    },
    [210152] = {  -- Death Sweep
        [191427] = 0.0954,  -- -> Metamorphosis
        [188499] = 0.0857,  -- -> Blade Dance
        [342817] = 0.0825,  -- -> Glaive Tempest
        [258920] = 0.0825,  -- -> Immolation Aura
        [195072] = 0.0782,  -- -> Fel Rush
        [185123] = 0.0772,  -- -> Throw Glaive
        [162243] = 0.0772,  -- -> Demon's Bite
        [370965] = 0.0729,  -- -> The Hunt
        [198013] = 0.0718,  -- -> Eye Beam
        [162794] = 0.0707,  -- -> Chaos Strike
        [210152] = 0.0707,  -- -> Death Sweep
        [258860] = 0.0697,  -- -> Essence Break
        [201427] = 0.0654,  -- -> Annihilation
    },
    [258860] = {  -- Essence Break
        [185123] = 0.0942,  -- -> Throw Glaive
        [195072] = 0.0861,  -- -> Fel Rush
        [201427] = 0.0851,  -- -> Annihilation
        [162794] = 0.08,  -- -> Chaos Strike
        [188499] = 0.078,  -- -> Blade Dance
        [191427] = 0.077,  -- -> Metamorphosis
        [258920] = 0.076,  -- -> Immolation Aura
        [162243] = 0.075,  -- -> Demon's Bite
        [342817] = 0.074,  -- -> Glaive Tempest
        [210152] = 0.0729,  -- -> Death Sweep
        [198013] = 0.0699,  -- -> Eye Beam
        [370965] = 0.0689,  -- -> The Hunt
        [258860] = 0.0628,  -- -> Essence Break
    },
    [258920] = {  -- Immolation Aura
        [188499] = 0.0938,  -- -> Blade Dance
        [198013] = 0.0877,  -- -> Eye Beam
        [201427] = 0.0866,  -- -> Annihilation
        [370965] = 0.0866,  -- -> The Hunt
        [195072] = 0.0836,  -- -> Fel Rush
        [258860] = 0.0815,  -- -> Essence Break
        [210152] = 0.0765,  -- -> Death Sweep
        [185123] = 0.0734,  -- -> Throw Glaive
        [342817] = 0.0693,  -- -> Glaive Tempest
        [258920] = 0.0683,  -- -> Immolation Aura
        [162243] = 0.0663,  -- -> Demon's Bite
        [162794] = 0.0652,  -- -> Chaos Strike
        [191427] = 0.0612,  -- -> Metamorphosis
    },
    [342817] = {  -- Glaive Tempest
        [258920] = 0.0844,  -- -> Immolation Aura
        [162794] = 0.0844,  -- -> Chaos Strike
        [198013] = 0.0824,  -- -> Eye Beam
        [210152] = 0.0824,  -- -> Death Sweep
        [258860] = 0.0824,  -- -> Essence Break
        [188499] = 0.0804,  -- -> Blade Dance
        [201427] = 0.0804,  -- -> Annihilation
        [370965] = 0.0773,  -- -> The Hunt
        [162243] = 0.0743,  -- -> Demon's Bite
        [185123] = 0.0722,  -- -> Throw Glaive
        [191427] = 0.0692,  -- -> Metamorphosis
        [195072] = 0.0661,  -- -> Fel Rush
        [342817] = 0.0641,  -- -> Glaive Tempest
    },
    [370965] = {  -- The Hunt
        [258860] = 0.0959,  -- -> Essence Break
        [370965] = 0.0855,  -- -> The Hunt
        [162794] = 0.0824,  -- -> Chaos Strike
        [162243] = 0.0824,  -- -> Demon's Bite
        [198013] = 0.0824,  -- -> Eye Beam
        [201427] = 0.0803,  -- -> Annihilation
        [188499] = 0.0803,  -- -> Blade Dance
        [210152] = 0.0772,  -- -> Death Sweep
        [185123] = 0.0751,  -- -> Throw Glaive
        [342817] = 0.074,  -- -> Glaive Tempest
        [258920] = 0.0699,  -- -> Immolation Aura
        [191427] = 0.0574,  -- -> Metamorphosis
        [195072] = 0.0574,  -- -> Fel Rush
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
