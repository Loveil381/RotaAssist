--- RotaAssist Decision Tree: DemonHunter Devourer (specID 1480)
--- PLACEHOLDER — Replace with trained tree once training data is available.
--- Based on early community rotation guides for Devourer DH.
--- Tree depth: 4, Nodes: ~20, Baseline reference
-- 吞噬者恶魔猎手占位决策树 / Devourer DH placeholder decision tree

local _, NS = ...
local RA = NS.RA
local DT = {}

DT.specID = 1480
DT.generatedDate = "2026-02-25"
DT.treeDepth = 4
DT.trainingAccuracy = 0.70
DT.isPlaceholder = true  -- Flag: needs real training data

--- Evaluate the decision tree with given features.
--- @param features table
--- @return table|nil {spellID=number, confidence=number}
function DT.Evaluate(features)
    -- Priority 1: Disrupt if Blizzard recommends
    if features.blizzardRecommendation <= 183752 then
        if features.blizzardRecommendation <= 183751 then
            -- not Disrupt
        else
            return {spellID=183752, confidence=0.95}
        end
    end

    -- Priority 2: Void Metamorphosis (burst) — early combat
    if features.combatDuration <= 5.0 then
        if features.blizzardRecommendation <= 442508 then
            if features.blizzardRecommendation <= 442507 then
                -- not Void Meta
            else
                return {spellID=442508, confidence=0.85}  -- Void Metamorphosis
            end
        end
    end

    -- AoE Branch
    if features.nameplateCount <= 2.5 then
        -- ===== Single Target =====

        -- Collapsing Star (high soul fragments)
        if features.secondaryResource <= 2.5 then
            -- Low fragments: generators
            if features.blizzardRecommendation <= 442501 then
                if features.blizzardRecommendation <= 442500 then
                    -- not Consume
                else
                    return {spellID=442501, confidence=0.72}  -- Consume
                end
            end
            -- Reap
            if features.blizzardRecommendation <= 442515 then
                if features.blizzardRecommendation <= 442514 then
                    -- not Reap
                else
                    return {spellID=442515, confidence=0.68}  -- Reap
                end
            end
            return {spellID=442501, confidence=0.55}  -- Consume filler
        else
            -- 3+ fragments: spenders
            if features.blizzardRecommendation <= 442510 then
                if features.blizzardRecommendation <= 442509 then
                    -- not Collapsing Star
                else
                    return {spellID=442510, confidence=0.80}  -- Collapsing Star
                end
            end
            -- Void Ray
            if features.blizzardRecommendation <= 442507 then
                if features.blizzardRecommendation <= 442506 then
                    -- not Void Ray
                else
                    return {spellID=442507, confidence=0.75}  -- Void Ray
                end
            end
            return {spellID=442510, confidence=0.65}  -- Collapsing Star default
        end
    else
        -- ===== AoE (3+ targets) =====
        -- Soul Immolation
        if features.blizzardRecommendation <= 442525 then
            if features.blizzardRecommendation <= 442524 then
                -- not Soul Immolation
            else
                return {spellID=442525, confidence=0.82}
            end
        end

        -- Immolation Aura
        if features.blizzardRecommendation <= 258920 then
            if features.blizzardRecommendation <= 258919 then
                -- not Immolation Aura
            else
                return {spellID=258920, confidence=0.75}
            end
        end

        -- Void Ray (AoE)
        if features.blizzardRecommendation <= 442507 then
            if features.blizzardRecommendation <= 442506 then
                -- not Void Ray
            else
                return {spellID=442507, confidence=0.70}
            end
        end

        return {spellID=442501, confidence=0.50}  -- Consume filler
    end
end

RA.DecisionTrees = RA.DecisionTrees or {}
RA.DecisionTrees[1480] = DT
