--- RotaAssist Decision Tree: Druid Balance (specID 102)
local _, NS = ...
local RA = NS.RA
local DT = {}

DT.specID = 102
DT.generatedDate = "2026-02-27"
DT.treeDepth = 5
DT.trainingAccuracy = 0.80

function DT.Evaluate(features)
    if features.blizzardRecommendation <= 106839 then
        if features.blizzardRecommendation <= 106838 then
        else
            return {spellID=106839, confidence=0.95}
        end
    end

    if features.nameplateCount <= 2.5 then
        if features.blizzardRecommendation <= 194223 then
            if features.blizzardRecommendation <= 194222 then
            else
                return {spellID=194223, confidence=0.85}
            end
        end
        if features.blizzardRecommendation <= 102560 then
            if features.blizzardRecommendation <= 102559 then
            else
                return {spellID=102560, confidence=0.85}
            end
        end
        if features.blizzardRecommendation <= 8921 then
            if features.blizzardRecommendation <= 8920 then
            else
                return {spellID=8921, confidence=0.80}
            end
        end
        if features.blizzardRecommendation <= 93402 then
            if features.blizzardRecommendation <= 93401 then
            else
                return {spellID=93402, confidence=0.80}
            end
        end
        
        if features.blizzardRecommendation <= 78674 then
            if features.blizzardRecommendation <= 78673 then
            else
                return {spellID=78674, confidence=0.80}
            end
        end

        if features.blizzardRecommendation <= 202347 then
            if features.blizzardRecommendation <= 202346 then
            else
                return {spellID=202347, confidence=0.75}
            end
        end
        return {spellID=190984, confidence=0.60}
    else
        -- AoE
        if features.blizzardRecommendation <= 191034 then
            if features.blizzardRecommendation <= 191033 then
            else
                return {spellID=191034, confidence=0.85}
            end
        end
        if features.blizzardRecommendation <= 194153 then
            if features.blizzardRecommendation <= 194152 then
            else
                return {spellID=194153, confidence=0.80}
            end
        end
        return {spellID=194153, confidence=0.50}
    end
end

RA.DecisionTrees = RA.DecisionTrees or {}
RA.DecisionTrees[102] = DT
