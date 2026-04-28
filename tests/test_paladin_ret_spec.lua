-- tests/test_paladin_ret_spec.lua
-- Unit tests for Paladin Retribution data integrity (specID 70):
-- SpecEnhancements, APL, DecisionTree, TransitionMatrix.
-- Mirrors the structure of test_warrior_spec.lua (Round 12 baseline).
local helpers = require("tests.helpers")

describe("Paladin Retribution data (specID 70)", function()
    local RA, ns

    setup(function()
        helpers.ensureMockLoaded()
        _G.GetSpecialization = function() return 3 end
        _G.GetSpecializationInfo = function()
            return 70, "Retribution", "", 135873, "DAMAGER"
        end
        _G.UnitClass = function() return "Paladin", "PALADIN", 2 end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Data/SpecInfo.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/SpecEnhancements/Paladin.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/APL/Paladin_Retribution.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/DecisionTrees/Paladin_Ret_DT.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/TransitionMatrix/Paladin_Ret_TM.lua", "RotaAssist", ns)
    end)

    describe("SpecEnhancements [70]", function()
        local spec

        before_each(function()
            spec = RA.SpecEnhancements[70]
        end)

        it("exists", function()
            assert.is_not_nil(spec)
        end)

        it("has 4 majorCooldowns", function()
            assert.equals(4, #spec.majorCooldowns)
        end)

        it("majorCooldowns contain Avenging Wrath, Wake of Ashes, Divine Toll, Execution Sentence", function()
            local ids = {}
            for _, cd in ipairs(spec.majorCooldowns) do ids[cd.spellID] = true end
            assert.is_true(ids[31884], "Avenging Wrath")
            assert.is_true(ids[255937], "Wake of Ashes")
            assert.is_true(ids[375576], "Divine Toll")
            assert.is_true(ids[343527], "Execution Sentence")
        end)

        it("every majorCooldown has spellID, alertThreshold, name", function()
            for _, cd in ipairs(spec.majorCooldowns) do
                assert.is_number(cd.spellID)
                assert.is_number(cd.alertThreshold)
                assert.is_string(cd.name)
            end
        end)

        it("has interruptSpell as nested table per D-003", function()
            assert.is_table(spec.interruptSpell)
            assert.equals(96231, spec.interruptSpell.spellID) -- Rebuke
            assert.equals("Rebuke", spec.interruptSpell.name)
            assert.equals(15, spec.interruptSpell.cooldown)
        end)

        it("has defensives with HP thresholds", function()
            assert.is_true(#spec.defensives >= 2)
            for _, def in ipairs(spec.defensives) do
                assert.is_number(def.spellID)
                assert.is_number(def.hpThreshold)
                assert.is_true(def.hpThreshold > 0 and def.hpThreshold < 1)
                assert.is_string(def.name)
            end
        end)

        it("defensives include Divine Shield and Lay on Hands", function()
            local ids = {}
            for _, def in ipairs(spec.defensives) do ids[def.spellID] = true end
            assert.is_true(ids[642], "Divine Shield")
            assert.is_true(ids[633], "Lay on Hands")
        end)

        it("resource powerType is Holy Power (9) per D-003 (numeric powerType)", function()
            assert.is_table(spec.resource)
            assert.equals(9, spec.resource.powerType)
            assert.is_number(spec.resource.maxBase)
            assert.equals(5, spec.resource.maxBase)
        end)

        it("resource has spellCosts table (placeholder allowed)", function()
            assert.is_table(spec.resource.spellCosts)
        end)

        it("burstWindows.avengingWrath fires on spell 31884 for 20s", function()
            assert.is_table(spec.burstWindows.avengingWrath)
            assert.equals(31884, spec.burstWindows.avengingWrath.trigger)
            assert.equals(20, spec.burstWindows.avengingWrath.duration)
        end)

        it("has prePullChecks for flask, food, rune", function()
            assert.is_not_nil(spec.prePullChecks.flask)
            assert.is_not_nil(spec.prePullChecks.food)
            assert.is_not_nil(spec.prePullChecks.rune)
        end)

        it("inferenceRules has executeSpells with Hammer of Wrath (24275)", function()
            assert.is_table(spec.inferenceRules.executeSpells)
            assert.equals(24275, spec.inferenceRules.executeSpells[1])
        end)

        it("inferenceRules.burstCooldownSpell is Avenging Wrath (31884)", function()
            assert.equals(31884, spec.inferenceRules.burstCooldownSpell)
            assert.equals(20, spec.inferenceRules.burstDuration)
        end)

        it("inferenceRules has aoe, single-target, generator, and spender lists", function()
            assert.is_table(spec.inferenceRules.aoeSpells)
            assert.is_table(spec.inferenceRules.singleTargetSpells)
            assert.is_table(spec.inferenceRules.generatorSpells)
            assert.is_table(spec.inferenceRules.spenderSpells)
        end)
    end)

    describe("APLData [70]", function()
        local apl

        before_each(function()
            apl = RA.APLData[70]
        end)

        it("loads and registers under specID 70", function()
            assert.is_not_nil(apl)
            assert.equals(70, apl.specID)
        end)

        it("has class PALADIN and specName Retribution", function()
            assert.equals("PALADIN", apl.class)
            assert.equals("Retribution", apl.specName)
        end)

        it("rules table is non-empty", function()
            assert.is_table(apl.rules)
            assert.is_true(#apl.rules > 0)
        end)

        it("each rule has spellID, name, priority, condition, reason", function()
            for _, rule in ipairs(apl.rules) do
                assert.is_number(rule.spellID)
                assert.is_string(rule.name)
                assert.is_number(rule.priority)
                assert.is_string(rule.condition)
                assert.is_string(rule.reason)
            end
        end)

        it("default profile contains singleTarget priorities", function()
            assert.is_table(apl.profiles)
            assert.is_table(apl.profiles["default"])
            assert.is_true(#apl.profiles["default"].singleTarget > 0)
        end)

        it("rules cover the core Ret rotation spells", function()
            local ids = {}
            for _, rule in ipairs(apl.rules) do ids[rule.spellID] = true end
            assert.is_true(ids[31884],  "Avenging Wrath")
            assert.is_true(ids[35395],  "Crusader Strike")
            assert.is_true(ids[20271],  "Judgment")
            assert.is_true(ids[184575], "Blade of Justice")
        end)
    end)

    describe("DecisionTrees [70]", function()
        local dt

        before_each(function()
            dt = RA.DecisionTrees[70]
        end)

        it("module loads and registers under specID 70", function()
            assert.is_not_nil(dt)
            assert.equals(70, dt.specID)
        end)

        it("Evaluate function exists and is callable", function()
            assert.is_function(dt.Evaluate)
        end)

        it("Evaluate returns {spellID, confidence} for synthetic Rebuke trigger", function()
            local result = dt.Evaluate({
                blizzardRecommendation = 96231,
                secondaryResource      = 0,
                nameplateCount         = 1,
            })
            assert.is_table(result)
            assert.equals(96231, result.spellID)
            assert.is_number(result.confidence)
            assert.is_true(result.confidence > 0 and result.confidence <= 1)
        end)

        it("Evaluate falls back to Crusader Strike with low confidence", function()
            local result = dt.Evaluate({
                blizzardRecommendation = 0,
                secondaryResource      = 0,
                nameplateCount         = 0,
            })
            assert.is_table(result)
            assert.equals(35395, result.spellID) -- Crusader Strike fallback
            assert.is_number(result.confidence)
        end)

        it("Evaluate returns Divine Storm in AoE with full Holy Power", function()
            local result = dt.Evaluate({
                blizzardRecommendation = 53385,
                secondaryResource      = 5,
                nameplateCount         = 3,
            })
            assert.is_table(result)
            assert.equals(53385, result.spellID) -- Divine Storm
        end)
    end)

    describe("TransitionMatrices [70]", function()
        local tm

        before_each(function()
            tm = RA.TransitionMatrices[70]
        end)

        it("module loads and registers under specID 70", function()
            assert.is_not_nil(tm)
            assert.equals(70, tm.specID)
        end)

        it("matrix table exists with at least one row", function()
            assert.is_table(tm.matrix)
            local rowCount = 0
            for _ in pairs(tm.matrix) do rowCount = rowCount + 1 end
            assert.is_true(rowCount > 0)
        end)

        it("GetTopTransitions returns sorted top-N", function()
            assert.is_function(tm.GetTopTransitions)
            local top = tm.GetTopTransitions(35395, 3) -- Crusader Strike
            assert.is_table(top)
            assert.is_true(#top <= 3)
            for i = 1, #top - 1 do
                assert.is_true(top[i].probability >= top[i + 1].probability)
            end
        end)

        it("GetTopTransitions on unknown spell returns empty table", function()
            local top = tm.GetTopTransitions(999999, 3)
            assert.is_table(top)
            assert.equals(0, #top)
        end)
    end)

    describe("SpecData / Registry sanity", function()
        it("SpecData[70] exists with className PALADIN, specName Retribution", function()
            assert.is_not_nil(RA.SpecData[70])
            assert.equals("PALADIN", RA.SpecData[70].className)
            assert.equals("Retribution", RA.SpecData[70].specName)
            assert.equals("DAMAGER", RA.SpecData[70].role)
        end)

        it("Registry.OVERRIDE_PAIRS still loaded (not clobbered)", function()
            assert.is_table(RA.Registry.OVERRIDE_PAIRS)
        end)
    end)
end)
