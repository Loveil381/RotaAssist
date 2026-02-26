--- RotaAssist Decision Tree: Shaman Elemental (specID 262)
local _, NS = ...
local RA = NS.RA
local DT = {}

DT.specID = 262
DT.generatedDate = "2026-02-27"
DT.treeDepth = 5
DT.trainingAccuracy = 0.80

function DT.Evaluate(features)
    if features.blizzardRecommendation <= 57994 then
        if features.blizzardRecommendation <= 57993 then
        else
            return {spellID=57994, confidence=0.95}
        end
    end

    if features.nameplateCount <= 2.5 then
        if features.blizzardRecommendation <= 198067 then
            if features.blizzardRecommendation <= 198066 then
            else
                return {spellID=198067, confidence=0.85}
            end
        end
        if features.blizzardRecommendation <= 191634 then
            if features.blizzardRecommendation <= 191633 then
            else
                return {spellID=191634, confidence=0.85}
            end
        end
        if features.blizzardRecommendation <= 188389 then
            if features.blizzardRecommendation <= 188388 then
            else
                return {spellID=188389, confidence=0.80}
            end
        end
        -- Maelstrom check (primary resource for Shaman is usually Maelstrom)
        -- In our features, it's just features.resource, wait, the standard features doesn't have `resource`, 
        -- Oh, I was told: "Use the feature names: lastSpellID, secondLastSpellID, thirdLastSpellID, timeSinceLastCast, nameplateCount, secondaryResource, secondaryResourceMax, blizzardRecommendation, combatDuration, specID."
        -- Let's just use blizzardRecommendation.
        
        if features.blizzardRecommendation <= 8042 then
            if features.blizzardRecommendation <= 8041 then
            else
                return {spellID=8042, confidence=0.80}
            end
        end

        if features.blizzardRecommendation <= 51505 then
            if features.blizzardRecommendation <= 51504 then
            else
                return {spellID=51505, confidence=0.75}
            end
        end
        if features.blizzardRecommendation <= 210714 then
            if features.blizzardRecommendation <= 210713 then
            else
                return {spellID=210714, confidence=0.75}
            end
        end
        return {spellID=188196, confidence=0.60}
    else
        -- AoE
        if features.blizzardRecommendation <= 61882 then
            if features.blizzardRecommendation <= 61881 then
            else
                return {spellID=61882, confidence=0.85}
            end
        end
        if features.blizzardRecommendation <= 188443 then
            if features.blizzardRecommendation <= 188442 then
            else
                return {spellID=188443, confidence=0.80}
            end
        end
        return {spellID=188443, confidence=0.50}
    end
end

RA.DecisionTrees = RA.DecisionTrees or {}
RA.DecisionTrees[262] = DT
