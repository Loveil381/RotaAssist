--- RotaAssist Decision Tree: Mage Frost (specID 64)
local _, NS = ...
local RA = NS.RA
local DT = {}
DT.specID = 64
DT.generatedDate = "2026-02-26"
DT.treeDepth = 6
DT.trainingAccuracy = 0.80

function DT.Evaluate(features)
    if features.blizzardRecommendation <= 2139 then
        if features.blizzardRecommendation == 2139 then return {spellID=2139, confidence=0.95} end -- Counterspell
    end
    if features.combatDuration <= 5.0 and features.blizzardRecommendation == 12472 then
        return {spellID=12472, confidence=0.90} -- Icy Veins
    end
    if features.nameplateCount >= 3.0 then
        if features.blizzardRecommendation == 190356 then return {spellID=190356, confidence=0.85} end -- Blizzard
        if features.blizzardRecommendation == 84714 then return {spellID=84714, confidence=0.88} end -- Frozen Orb
        if features.blizzardRecommendation == 153595 then return {spellID=153595, confidence=0.90} end -- Comet Storm
    else
        if features.blizzardRecommendation == 44614 then return {spellID=44614, confidence=0.85} end -- Flurry
        if features.blizzardRecommendation == 30455 then return {spellID=30455, confidence=0.80} end -- Ice Lance
        if features.blizzardRecommendation == 199786 then return {spellID=199786, confidence=0.82} end -- Glacial Spike
    end
    return {spellID=116, confidence=0.55} -- Frostbolt
end

RA.DecisionTrees = RA.DecisionTrees or {}
RA.DecisionTrees[64] = DT
