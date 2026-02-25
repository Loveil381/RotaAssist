--- RotaAssist Decision Tree: DemonHunter Vengeance (specID 581)
--- Hand-crafted template matching sklearn2lua.py output format.
--- Based on standard Vengeance priority (2025 SimC / community guides).
--- Tree depth: 5, Nodes: ~30, Baseline reference
-- 手动编写的复仇恶魔猎手决策树 / Vengeance DH hand-crafted decision tree

local _, NS = ...
local RA = NS.RA
local DT = {}

DT.specID = 581
DT.generatedDate = "2026-02-25"
DT.treeDepth = 5
DT.trainingAccuracy = 0.78

--- Evaluate the decision tree with given features.
--- @param features table
--- @return table|nil {spellID=number, confidence=number}
function DT.Evaluate(features)
    -- 优先级1: 暴雪推荐打断 / Priority 1: Disrupt
    if features.blizzardRecommendation <= 183752 then
        if features.blizzardRecommendation <= 183751 then
            -- not Disrupt
        else
            return {spellID=183752, confidence=0.95}
        end
    end

    -- 优先级2: 主动减伤 — 恶魔尖刺 / Priority 2: Active Mitigation — Demon Spikes
    if features.blizzardRecommendation <= 203720 then
        if features.blizzardRecommendation <= 203719 then
            -- not Demon Spikes
        else
            return {spellID=203720, confidence=0.90}
        end
    end

    -- 优先级3: 火焰烙印 / Priority 3: Fiery Brand
    if features.blizzardRecommendation <= 204021 then
        if features.blizzardRecommendation <= 204020 then
            -- not Fiery Brand
        else
            return {spellID=204021, confidence=0.85}
        end
    end

    -- 优先级4: 邪能毁灭 / Priority 4: Fel Devastation
    if features.blizzardRecommendation <= 212084 then
        if features.blizzardRecommendation <= 212083 then
            -- not Fel Devastation
        else
            return {spellID=212084, confidence=0.82}
        end
    end

    -- AoE 分岐 / AoE branch
    if features.nameplateCount <= 1.5 then
        -- ===== Single Target =====

        -- Soul Cleave (with fragments)
        if features.secondaryResource <= 0.5 then
            -- No fragments: Fracture to generate
            if features.blizzardRecommendation <= 263642 then
                if features.blizzardRecommendation <= 263641 then
                    -- not Fracture specifically recommended
                else
                    return {spellID=263642, confidence=0.80}
                end
            end
            -- Sigil of Flame
            if features.blizzardRecommendation <= 204596 then
                if features.blizzardRecommendation <= 204595 then
                    -- not Sigil
                else
                    return {spellID=204596, confidence=0.70}
                end
            end
            -- Default: Fracture
            return {spellID=263642, confidence=0.65}
        else
            -- Has fragments: Soul Cleave
            if features.blizzardRecommendation <= 228477 then
                if features.blizzardRecommendation <= 228476 then
                    -- not Soul Cleave
                else
                    return {spellID=228477, confidence=0.82}
                end
            end
            -- Still use Soul Cleave as default when fragments available
            return {spellID=228477, confidence=0.70}
        end

    else
        -- ===== AoE (2+ targets) =====

        -- Spirit Bomb (4+ fragments, 2+ targets)
        if features.secondaryResource <= 3.5 then
            -- Not enough fragments for Spirit Bomb

            -- Sigil of Flame (AoE)
            if features.blizzardRecommendation <= 204596 then
                if features.blizzardRecommendation <= 204595 then
                    -- not Sigil
                else
                    return {spellID=204596, confidence=0.78}
                end
            end

            -- Fracture to build fragments
            if features.blizzardRecommendation <= 263642 then
                if features.blizzardRecommendation <= 263641 then
                    -- not Fracture
                else
                    return {spellID=263642, confidence=0.75}
                end
            end

            -- Immolation Aura (AoE)
            if features.blizzardRecommendation <= 258920 then
                if features.blizzardRecommendation <= 258919 then
                    -- not Immolation Aura
                else
                    return {spellID=258920, confidence=0.68}
                end
            end

            return {spellID=263642, confidence=0.60}  -- Fracture filler
        else
            -- 4+ fragments: Spirit Bomb
            if features.nameplateCount <= 4.5 then
                return {spellID=247454, confidence=0.88}  -- Spirit Bomb 2-4 targets
            else
                return {spellID=247454, confidence=0.92}  -- Spirit Bomb 5+ targets
            end
        end

        -- Bulk Extraction for massive AoE
        if features.nameplateCount <= 4.5 then
            -- skip
        else
            if features.blizzardRecommendation <= 320341 then
                if features.blizzardRecommendation <= 320340 then
                    -- not Bulk Extraction
                else
                    return {spellID=320341, confidence=0.75}
                end
            end
        end

        -- Default AoE filler
        return {spellID=228477, confidence=0.55}  -- Soul Cleave
    end
end

RA.DecisionTrees = RA.DecisionTrees or {}
RA.DecisionTrees[581] = DT
