--- RotaAssist Decision Tree: Evoker Devastation (specID 1467)
--- 手动编写的湮灭龙希尔决策树 / Evoker Devastation hand-crafted decision tree

local _, NS = ...
local RA = NS.RA
local DT = {}

DT.specID = 1467
DT.generatedDate = "2026-02-28"
DT.treeDepth = 3

--- Evaluate the decision tree with given features.
--- 使用给定特征评估决策树。
--- @param features table {lastSpellID, secondLastSpellID, thirdLastSpellID,
---   timeSinceLastCast, nameplateCount, secondaryResource, secondaryResourceMax,
---   blizzardRecommendation, combatDuration, specID}
--- @return table|nil {spellID=number, confidence=number}
function DT.Evaluate(features)
    -- 1. if lastSpellID == 357208 (Fire Breath) then return 356995 (Disintegrate), confidence 0.90
    if features.lastSpellID == 357208 then
        return {spellID = 356995, confidence = 0.90}
    end

    -- 2. if lastSpellID == 359073 (Eternity Surge) then return 356995 (Disintegrate), confidence 0.88
    if features.lastSpellID == 359073 then
        return {spellID = 356995, confidence = 0.88}
    end

    -- 3. if lastSpellID == 356995 (Disintegrate)
    if features.lastSpellID == 356995 then
        -- AND nameplateCount >= 4 then return 357211 (Pyre), confidence 0.85
        if (features.nameplateCount or 0) >= 4 then
            return {spellID = 357211, confidence = 0.85}
        end
        -- else return 361469 (Living Flame), confidence 0.75
        return {spellID = 361469, confidence = 0.75}
    end

    -- 4. if timeSinceLastCast > 2.0 then return 357208 (Fire Breath), confidence 0.80
    if (features.timeSinceLastCast or 0) > 2.0 then
        return {spellID = 357208, confidence = 0.80}
    end

    -- default: return 361469 (Living Flame), confidence 0.60
    return {spellID = 361469, confidence = 0.60}
end

RA.DecisionTrees = RA.DecisionTrees or {}
RA.DecisionTrees[1467] = DT
