--- RotaAssist Decision Tree: Rogue Subtlety (specID 261)
local _, NS = ...
local RA = NS.RA
local DT = {}

DT.specID = 261
DT.generatedDate = "2026-02-27"
DT.treeDepth = 5
DT.trainingAccuracy = 0.80

function DT.Evaluate(features)
    if features.blizzardRecommendation <= 1766 then
        if features.blizzardRecommendation <= 1765 then
        else
            return {spellID=1766, confidence=0.95}
        end
    end

    if features.nameplateCount <= 2.5 then
        if features.blizzardRecommendation <= 185313 then
            if features.blizzardRecommendation <= 185312 then
            else
                return {spellID=185313, confidence=0.85}
            end
        end
        if features.blizzardRecommendation <= 212283 then
            if features.blizzardRecommendation <= 212282 then
            else
                return {spellID=212283, confidence=0.85}
            end
        end
        if features.blizzardRecommendation <= 280719 then
            if features.blizzardRecommendation <= 280718 then
            else
                return {spellID=280719, confidence=0.80}
            end
        end
        if features.secondaryResource >= 4.5 then
            if features.blizzardRecommendation <= 1943 then
                if features.blizzardRecommendation <= 1942 then
                else
                    return {spellID=1943, confidence=0.75}
                end
            end
            if features.blizzardRecommendation <= 196819 then
                if features.blizzardRecommendation <= 196818 then
                else
                    return {spellID=196819, confidence=0.75}
                end
            end
        end
        if features.blizzardRecommendation <= 185438 then
            if features.blizzardRecommendation <= 185437 then
            else
                return {spellID=185438, confidence=0.70}
            end
        end
        return {spellID=53, confidence=0.60}
    else
        if features.secondaryResource >= 4.5 then
            if features.blizzardRecommendation <= 319175 then
                if features.blizzardRecommendation <= 319174 then
                else
                    return {spellID=319175, confidence=0.85}
                end
            end
            return {spellID=319175, confidence=0.75}
        end
        if features.blizzardRecommendation <= 122281 then
            if features.blizzardRecommendation <= 122280 then
            else
                return {spellID=122281, confidence=0.80}
            end
        end
        return {spellID=122281, confidence=0.50}
    end
end

RA.DecisionTrees = RA.DecisionTrees or {}
RA.DecisionTrees[261] = DT
