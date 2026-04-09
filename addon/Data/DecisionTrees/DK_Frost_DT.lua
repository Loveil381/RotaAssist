--- RotaAssist Decision Tree: Death Knight Frost (specID 251)
local _, NS = ...
local RA = NS.RA
local DT = {}
DT.specID = 251
DT.generatedDate = "2026-02-26"
DT.treeDepth = 6
DT.trainingAccuracy = 0.80

function DT.Evaluate(features)
    if features.blizzardRecommendation == 47528 then return {spellID=47528, confidence=0.95} end -- Mind Freeze
    if features.blizzardRecommendation == 51271 then return {spellID=51271, confidence=0.90} end -- Pillar of Frost
    if features.blizzardRecommendation == 49020 then return {spellID=49020, confidence=0.88} end -- Obliterate (KM)
    if features.blizzardRecommendation == 49184 then return {spellID=49184, confidence=0.82} end -- Howling Blast (Rime)
    if features.blizzardRecommendation == 49143 then return {spellID=49143, confidence=0.80} end -- Frost Strike
    if features.blizzardRecommendation == 196770 then return {spellID=196770, confidence=0.85} end -- Remorseless Winter
    if features.blizzardRecommendation == 279302 then return {spellID=279302, confidence=0.86} end -- Frostwyrm's Fury
    return {spellID=49020, confidence=0.55} -- Obliterate (Filler)
end

RA.DecisionTrees = RA.DecisionTrees or {}
RA.DecisionTrees[251] = DT
