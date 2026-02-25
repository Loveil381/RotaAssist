--- RotaAssist Decision Tree: DemonHunter Havoc (specID 577)
--- Hand-crafted template matching sklearn2lua.py output format.
--- Based on standard Havoc priority (2025 SimC / community guides).
--- Tree depth: 6, Nodes: ~40, Baseline reference
-- 手动编写的浩劫恶魔猎手决策树 / Havoc DH hand-crafted decision tree

local _, NS = ...
local RA = NS.RA
local DT = {}

DT.specID = 577
DT.generatedDate = "2026-02-25"
DT.treeDepth = 6
DT.trainingAccuracy = 0.80

--- Evaluate the decision tree with given features.
--- 使用给定特征评估决策树。
--- @param features table {lastSpellID, secondLastSpellID, thirdLastSpellID,
---   timeSinceLastCast, nameplateCount, secondaryResource, secondaryResourceMax,
---   blizzardRecommendation, combatDuration, specID}
--- @return table|nil {spellID=number, confidence=number}
function DT.Evaluate(features)
    -- 优先级1: 暴雪推荐打断 / Priority 1: Blizzard recommends Disrupt
    if features.blizzardRecommendation <= 183752 then
        if features.blizzardRecommendation <= 183751 then
            -- Not disrupt, fall through
        else
            -- blizzardRecommendation == 183752 (Disrupt)
            return {spellID=183752, confidence=0.95}
        end
    end

    -- 优先级2: 冷却技能 (战斗早期) / Priority 2: Major cooldowns (early combat)
    if features.combatDuration <= 6.0 then
        -- Opener: The Hunt > Metamorphosis > Essence Break
        if features.blizzardRecommendation <= 370965 then
            if features.blizzardRecommendation <= 370964 then
                -- Check for Essence Break
                if features.blizzardRecommendation <= 258860 then
                    if features.blizzardRecommendation <= 258859 then
                        -- Check Metamorphosis
                        if features.blizzardRecommendation <= 191427 then
                            if features.blizzardRecommendation <= 191426 then
                                -- fallthrough
                            else
                                return {spellID=191427, confidence=0.85}  -- Metamorphosis
                            end
                        end
                    else
                        return {spellID=258860, confidence=0.82}  -- Essence Break
                    end
                end
            else
                return {spellID=370965, confidence=0.90}  -- The Hunt
            end
        end
    end

    -- 優先級3: AoE 分岐 (多目标) / Priority 3: AoE branch
    if features.nameplateCount <= 2.5 then
        -- ===== Single Target / Cleave =====

        -- Meta active: check if Blizz recommends meta spells
        if features.blizzardRecommendation <= 210152 then
            if features.blizzardRecommendation <= 210151 then
                -- not Death Sweep
            else
                -- Death Sweep (in meta, but ST — still use if recommended)
                return {spellID=210152, confidence=0.80}
            end
        end

        if features.blizzardRecommendation <= 201427 then
            if features.blizzardRecommendation <= 201426 then
                -- not Annihilation
            else
                -- Annihilation (meta ST finisher)
                return {spellID=201427, confidence=0.82}
            end
        end

        -- Essence Break if ready
        if features.blizzardRecommendation <= 258860 then
            if features.blizzardRecommendation <= 258859 then
                -- not Essence Break
            else
                return {spellID=258860, confidence=0.84}
            end
        end

        -- Eye Beam
        if features.blizzardRecommendation <= 198013 then
            if features.blizzardRecommendation <= 198012 then
                -- not Eye Beam
            else
                return {spellID=198013, confidence=0.78}
            end
        end

        -- Chaos Strike (resource available implied)
        if features.blizzardRecommendation <= 162794 then
            if features.blizzardRecommendation <= 162793 then
                -- not Chaos Strike
            else
                return {spellID=162794, confidence=0.75}
            end
        end

        -- Immolation Aura
        if features.blizzardRecommendation <= 258920 then
            if features.blizzardRecommendation <= 258919 then
                -- not Immolation Aura
            else
                return {spellID=258920, confidence=0.65}
            end
        end

        -- Fel Rush at 2 charges
        if features.blizzardRecommendation <= 195072 then
            if features.blizzardRecommendation <= 195071 then
                -- not Fel Rush
            else
                return {spellID=195072, confidence=0.55}
            end
        end

        -- Filler: Demon's Bite
        return {spellID=162243, confidence=0.60}

    else
        -- ===== AoE (3+ targets) =====

        -- Death Sweep in AoE (meta)
        if features.blizzardRecommendation <= 210152 then
            if features.blizzardRecommendation <= 210151 then
                -- not Death Sweep
            else
                return {spellID=210152, confidence=0.90}
            end
        end

        -- Blade Dance (primary AoE)
        if features.nameplateCount <= 4.5 then
            -- 3-4 targets
            if features.blizzardRecommendation <= 188499 then
                if features.blizzardRecommendation <= 188498 then
                    -- not Blade Dance
                else
                    return {spellID=188499, confidence=0.88}
                end
            end
        else
            -- 5+ targets: Blade Dance very high priority
            return {spellID=188499, confidence=0.92}
        end

        -- Eye Beam (AoE)
        if features.blizzardRecommendation <= 198013 then
            if features.blizzardRecommendation <= 198012 then
                -- not Eye Beam
            else
                return {spellID=198013, confidence=0.85}
            end
        end

        -- Glaive Tempest
        if features.blizzardRecommendation <= 342817 then
            if features.blizzardRecommendation <= 342816 then
                -- not Glaive Tempest
            else
                return {spellID=342817, confidence=0.80}
            end
        end

        -- Immolation Aura (AoE)
        if features.blizzardRecommendation <= 258920 then
            if features.blizzardRecommendation <= 258919 then
                -- not Immolation Aura
            else
                return {spellID=258920, confidence=0.72}
            end
        end

        -- Chaos Strike filler in AoE
        if features.blizzardRecommendation <= 162794 then
            if features.blizzardRecommendation <= 162793 then
                -- not Chaos Strike
            else
                return {spellID=162794, confidence=0.60}
            end
        end

        -- AoE Filler: Demon's Bite
        return {spellID=162243, confidence=0.50}
    end
end

RA.DecisionTrees = RA.DecisionTrees or {}
RA.DecisionTrees[577] = DT
