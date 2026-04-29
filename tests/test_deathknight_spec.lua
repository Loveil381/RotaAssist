-- tests/test_deathknight_spec.lua
-- Unit tests for Death Knight Frost (251) + Unholy (252) data integrity
-- across SpecEnhancements, APL, DecisionTrees, TransitionMatrices, and SpecData.
-- 死亡骑士 冰霜 (251) / 邪恶 (252) 数据完整性单元测试。
local helpers = require("tests.helpers")

describe("DeathKnight data integrity", function()
    local RA, ns

    setup(function()
        helpers.ensureMockLoaded()
        _G.GetSpecialization = function() return 2 end
        _G.GetSpecializationInfo = function()
            return 251, "Frost", "", 135773, "DAMAGER"
        end
        _G.UnitClass = function() return "Death Knight", "DEATHKNIGHT", 6 end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Data/SpecInfo.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/SpecEnhancements/DeathKnight.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/APL/DeathKnight_Frost.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/APL/DK_Unholy.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/DecisionTrees/DK_Frost_DT.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/DecisionTrees/DK_Unholy_DT.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/TransitionMatrix/DK_Frost_TM.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/TransitionMatrix/DK_Unholy_TM.lua", "RotaAssist", ns)
    end)

    ----------------------------------------------------------------------
    -- Frost (specID 251)
    ----------------------------------------------------------------------
    describe("[251] Frost SpecEnhancements", function()
        local spec

        before_each(function()
            spec = RA.SpecEnhancements[251]
        end)

        it("exists", function()
            assert.is_not_nil(spec)
        end)

        it("majorCooldowns include Pillar of Frost, Empower Rune Weapon, Breath, Frostwyrm", function()
            local ids = {}
            for _, cd in ipairs(spec.majorCooldowns) do ids[cd.spellID] = true end
            assert.is_true(ids[51271],  "Pillar of Frost (51271)")
            assert.is_true(ids[47568],  "Empower Rune Weapon (47568)")
            assert.is_true(ids[152279], "Breath of Sindragosa (152279)")
            assert.is_true(ids[279302], "Frostwyrm's Fury (279302)")
        end)

        it("interruptSpell is Mind Freeze with nested-table schema", function()
            assert.is_table(spec.interruptSpell)
            assert.equals(47528, spec.interruptSpell.spellID)
            assert.equals("Mind Freeze", spec.interruptSpell.name)
            assert.equals(15, spec.interruptSpell.cooldown)
        end)

        it("defensives include Icebound Fortitude with HP threshold (0..1)", function()
            assert.is_true(#spec.defensives >= 2)
            local found = false
            for _, def in ipairs(spec.defensives) do
                assert.is_number(def.spellID)
                assert.is_number(def.hpThreshold)
                assert.is_true(def.hpThreshold > 0 and def.hpThreshold <= 1)
                if def.spellID == 48792 then found = true end
            end
            assert.is_true(found, "Icebound Fortitude (48792) present")
        end)

        it("resource.powerType is numeric Runic Power (6)", function()
            assert.is_number(spec.resource.powerType)
            assert.equals(6, spec.resource.powerType)
        end)

        it("resource.maxBase is 100 (RP cap)", function()
            assert.equals(100, spec.resource.maxBase)
        end)

        it("burstWindows has Pillar of Frost trigger (12s)", function()
            assert.is_not_nil(spec.burstWindows.pillar)
            assert.equals(51271, spec.burstWindows.pillar.trigger)
            assert.equals(12, spec.burstWindows.pillar.duration)
        end)

        it("prePullChecks has flask, food, rune", function()
            assert.is_not_nil(spec.prePullChecks.flask)
            assert.is_not_nil(spec.prePullChecks.food)
            assert.is_not_nil(spec.prePullChecks.rune)
        end)

        it("inferenceRules has burst cooldown spell + duration", function()
            assert.equals(51271, spec.inferenceRules.burstCooldownSpell)
            assert.equals(12, spec.inferenceRules.burstDuration)
        end)
    end)

    describe("[251] Frost APL", function()
        it("registers under specID 251 with class DEATHKNIGHT", function()
            local apl = RA.APLData[251]
            assert.is_not_nil(apl)
            assert.equals(251, apl.specID)
            assert.equals("DEATHKNIGHT", apl.class)
            assert.equals("Frost", apl.specName)
        end)

        it("has non-empty rules", function()
            local apl = RA.APLData[251]
            assert.is_table(apl.rules)
            assert.is_true(#apl.rules > 0)
        end)

        it("default profile has singleTarget priorities", function()
            local apl = RA.APLData[251]
            assert.is_table(apl.profiles.default)
            assert.is_true(#apl.profiles.default.singleTarget > 0)
        end)
    end)

    describe("[251] Frost DecisionTree", function()
        it("registers under specID 251", function()
            assert.is_not_nil(RA.DecisionTrees[251])
            assert.equals(251, RA.DecisionTrees[251].specID)
        end)

        it("Evaluate is callable with dot syntax (engine contract)", function()
            local DT = RA.DecisionTrees[251]
            assert.is_function(DT.Evaluate)
        end)

        it("Evaluate returns {spellID, confidence} for Pillar of Frost trigger", function()
            local DT = RA.DecisionTrees[251]
            local out = DT.Evaluate({ blizzardRecommendation = 51271 })
            assert.is_table(out)
            assert.equals(51271, out.spellID)
            assert.is_number(out.confidence)
            assert.is_true(out.confidence > 0 and out.confidence <= 1)
        end)

        it("Evaluate returns Obliterate fallback for unknown features", function()
            local DT = RA.DecisionTrees[251]
            local out = DT.Evaluate({ blizzardRecommendation = 0 })
            assert.is_table(out)
            assert.equals(49020, out.spellID)
        end)
    end)

    describe("[251] Frost TransitionMatrix", function()
        it("registers under specID 251", function()
            assert.is_not_nil(RA.TransitionMatrices[251])
            assert.equals(251, RA.TransitionMatrices[251].specID)
        end)

        it("GetTopTransitions returns sorted list (probability desc)", function()
            local TM = RA.TransitionMatrices[251]
            local top = TM.GetTopTransitions(49020, 3)
            assert.is_table(top)
            assert.is_true(#top > 0)
            for i = 2, #top do
                assert.is_true(top[i - 1].probability >= top[i].probability,
                    "transitions must be sorted by probability descending")
            end
        end)

        it("GetTopTransitions returns empty for unknown spell", function()
            local TM = RA.TransitionMatrices[251]
            local top = TM.GetTopTransitions(99999, 3)
            assert.is_table(top)
            assert.equals(0, #top)
        end)
    end)

    ----------------------------------------------------------------------
    -- Unholy (specID 252)
    ----------------------------------------------------------------------
    describe("[252] Unholy SpecEnhancements", function()
        local spec

        before_each(function()
            spec = RA.SpecEnhancements[252]
        end)

        it("exists", function()
            assert.is_not_nil(spec)
        end)

        it("majorCooldowns include Army, Dark Transformation, Soul Reaper, Gargoyle", function()
            local ids = {}
            for _, cd in ipairs(spec.majorCooldowns) do ids[cd.spellID] = true end
            assert.is_true(ids[42650],  "Army of the Dead (42650)")
            assert.is_true(ids[63560],  "Dark Transformation (63560)")
            assert.is_true(ids[343294], "Soul Reaper (343294)")
            assert.is_true(ids[49206],  "Summon Gargoyle (49206)")
        end)

        it("shares Mind Freeze interrupt with Frost (D-003 nested schema)", function()
            assert.is_table(spec.interruptSpell)
            assert.equals(47528, spec.interruptSpell.spellID)
            assert.equals(15, spec.interruptSpell.cooldown)
        end)

        it("defensives include Anti-Magic Shell + Icebound Fortitude with HP thresholds", function()
            local ids = {}
            for _, def in ipairs(spec.defensives) do
                ids[def.spellID] = def.hpThreshold
                assert.is_number(def.hpThreshold)
                assert.is_true(def.hpThreshold > 0 and def.hpThreshold <= 1)
            end
            assert.is_not_nil(ids[48707], "Anti-Magic Shell (48707)")
            assert.is_not_nil(ids[48792], "Icebound Fortitude (48792)")
        end)

        it("resource.powerType is numeric Runic Power (6)", function()
            assert.is_number(spec.resource.powerType)
            assert.equals(6, spec.resource.powerType)
        end)

        it("resource.spellCosts entries are nested tables (D-003 schema)", function()
            local entry = spec.resource.spellCosts[47541]
            assert.is_table(entry, "Death Coil cost should be a table")
            assert.is_number(entry.cost)
            assert.equals(30, entry.cost)
        end)

        it("burstWindows has Army of the Dead (15s) and Gargoyle (25s)", function()
            assert.is_not_nil(spec.burstWindows.armyOfTheDead)
            assert.equals(42650, spec.burstWindows.armyOfTheDead.trigger)
            assert.equals(15, spec.burstWindows.armyOfTheDead.duration)
            assert.is_not_nil(spec.burstWindows.summonGargoyle)
            assert.equals(25, spec.burstWindows.summonGargoyle.duration)
        end)

        it("inferenceRules has executeSpells with Soul Reaper", function()
            assert.is_table(spec.inferenceRules.executeSpells)
            assert.equals(343294, spec.inferenceRules.executeSpells[1])
        end)

        it("inferenceRules has burst indicators", function()
            local indicators = spec.inferenceRules.burstIndicatorSpells
            assert.is_table(indicators)
            assert.is_true(#indicators >= 2)
        end)

        it("prePullChecks has flask, food, rune", function()
            assert.is_not_nil(spec.prePullChecks.flask)
            assert.is_not_nil(spec.prePullChecks.food)
            assert.is_not_nil(spec.prePullChecks.rune)
        end)
    end)

    describe("[252] Unholy APL", function()
        it("registers under specID 252 with class DEATHKNIGHT", function()
            local apl = RA.APLData[252]
            assert.is_not_nil(apl)
            assert.equals(252, apl.specID)
            assert.equals("DEATHKNIGHT", apl.class)
            assert.equals("Unholy", apl.specName)
        end)

        it("has non-empty rules", function()
            local apl = RA.APLData[252]
            assert.is_table(apl.rules)
            assert.is_true(#apl.rules > 0)
        end)

        it("default profile has singleTarget AND aoe priorities", function()
            local apl = RA.APLData[252]
            assert.is_true(#apl.profiles.default.singleTarget > 0)
            assert.is_true(#apl.profiles.default.aoe > 0)
        end)
    end)

    describe("[252] Unholy DecisionTree", function()
        it("registers under specID 252", function()
            assert.is_not_nil(RA.DecisionTrees[252])
            assert.equals(252, RA.DecisionTrees[252].specID)
        end)

        it("Evaluate is callable with dot syntax (engine contract)", function()
            local DT = RA.DecisionTrees[252]
            assert.is_function(DT.Evaluate)
        end)

        it("Evaluate returns Outbreak when Virulent Plague missing", function()
            local DT = RA.DecisionTrees[252]
            local out = DT.Evaluate({
                debuff_virulent_plague_active = false,
                resource = 50,
                debuff_festering_wound = 2,
                target_hp = 1.0,
                enemies_in_range = 1,
            })
            assert.is_table(out)
            assert.equals(77575, out.spellID)
        end)

        it("Evaluate prioritizes Death Coil during Gargoyle window", function()
            local DT = RA.DecisionTrees[252]
            local out = DT.Evaluate({
                buff_gargoyle_active = true,
                resource = 60,
                debuff_virulent_plague_active = true,
                debuff_festering_wound = 3,
                enemies_in_range = 1,
            })
            assert.is_table(out)
            assert.equals(47541, out.spellID)
        end)

        it("Evaluate switches to Epidemic on AoE with sudden doom proc", function()
            local DT = RA.DecisionTrees[252]
            local out = DT.Evaluate({
                debuff_virulent_plague_active = true,
                debuff_festering_scythe_active = true,
                cooldown_42650_ready = false,
                cooldown_63560_ready = false,
                cooldown_460463_ready = false,
                proc_sudden_doom = true,
                resource = 90,
                debuff_festering_wound = 2,
                target_hp = 1.0,
                enemies_in_range = 5,
            })
            assert.is_table(out)
            assert.equals(207317, out.spellID)
        end)
    end)

    describe("[252] Unholy TransitionMatrix", function()
        it("registers under specID 252", function()
            assert.is_not_nil(RA.TransitionMatrices[252])
            assert.equals(252, RA.TransitionMatrices[252].specID)
        end)

        it("GetTopTransitions exists (engine contract)", function()
            local TM = RA.TransitionMatrices[252]
            assert.is_function(TM.GetTopTransitions)
        end)

        it("GetTopTransitions returns sorted list for Outbreak", function()
            local TM = RA.TransitionMatrices[252]
            local top = TM.GetTopTransitions(77575, 3)
            assert.is_table(top)
            assert.is_true(#top > 0)
            for i = 2, #top do
                assert.is_true(top[i - 1].probability >= top[i].probability,
                    "transitions must be sorted by probability descending")
            end
        end)

        it("GetTopTransitions returns empty list for unknown spell", function()
            local TM = RA.TransitionMatrices[252]
            local top = TM.GetTopTransitions(99999, 3)
            assert.is_table(top)
            assert.equals(0, #top)
        end)
    end)

    ----------------------------------------------------------------------
    -- Cross-spec + Registry/SpecData sanity
    ----------------------------------------------------------------------
    describe("Cross-spec consistency", function()
        it("both specs share the Mind Freeze interrupt", function()
            assert.equals(
                RA.SpecEnhancements[251].interruptSpell.spellID,
                RA.SpecEnhancements[252].interruptSpell.spellID
            )
        end)

        it("both specs use Runic Power as primary powerType", function()
            assert.equals(6, RA.SpecEnhancements[251].resource.powerType)
            assert.equals(6, RA.SpecEnhancements[252].resource.powerType)
        end)

        it("both specs have Runes as secondaryPowerType", function()
            assert.equals(5, RA.SpecEnhancements[251].secondaryPowerType)
            assert.equals(5, RA.SpecEnhancements[252].secondaryPowerType)
        end)
    end)

    describe("SpecData registry sanity", function()
        it("SpecData[251] is DEATHKNIGHT / Frost / DAMAGER", function()
            local sd = RA.SpecData[251]
            assert.is_not_nil(sd)
            assert.equals("DEATHKNIGHT", sd.className)
            assert.equals("Frost", sd.specName)
            assert.equals("DAMAGER", sd.role)
        end)

        it("SpecData[252] is DEATHKNIGHT / Unholy / DAMAGER", function()
            local sd = RA.SpecData[252]
            assert.is_not_nil(sd)
            assert.equals("DEATHKNIGHT", sd.className)
            assert.equals("Unholy", sd.specName)
            assert.equals("DAMAGER", sd.role)
        end)

        it("DK class (classID=6) has Blood/Frost/Unholy in ClassSpecs", function()
            local specs = RA.ClassSpecs[6]
            assert.is_table(specs)
            local set = {}
            for _, sid in ipairs(specs) do set[sid] = true end
            assert.is_true(set[250], "Blood (250)")
            assert.is_true(set[251], "Frost (251)")
            assert.is_true(set[252], "Unholy (252)")
        end)
    end)
end)
