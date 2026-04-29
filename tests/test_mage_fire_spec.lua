-- tests/test_mage_fire_spec.lua
-- Unit tests for Mage Fire (specID 63) data integrity.
-- Covers SpecEnhancements, DecisionTree, TransitionMatrix, and APLData entries.
local helpers = require("tests.helpers")

describe("Mage Fire", function()
    local RA, ns

    setup(function()
        helpers.ensureMockLoaded()
        _G.GetSpecialization = function() return 2 end
        _G.GetSpecializationInfo = function()
            return 63, "Fire", "", 135810, "DAMAGER"
        end
        _G.UnitClass = function() return "Mage", "MAGE", 8 end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Data/SpecInfo.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/SpecEnhancements/Mage.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/APL/Mage_Fire.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/DecisionTrees/Mage_Fire_DT.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/TransitionMatrix/Mage_Fire_TM.lua", "RotaAssist", ns)
    end)

    describe("SpecEnhancements (specID 63)", function()
        local spec

        before_each(function()
            spec = RA.SpecEnhancements[63]
        end)

        it("exists", function()
            assert.is_not_nil(spec)
        end)

        it("has majorCooldowns with at least 1 entry (Combustion)", function()
            assert.is_table(spec.majorCooldowns)
            assert.is_true(#spec.majorCooldowns >= 1)
            local ids = {}
            for _, cd in ipairs(spec.majorCooldowns) do ids[cd.spellID] = true end
            assert.is_true(ids[190319], "Combustion (190319) must be a major cooldown")
        end)

        it("has interruptSpell (Counterspell, nested per D-003)", function()
            assert.is_not_nil(spec.interruptSpell)
            assert.equals(2139, spec.interruptSpell.spellID)
            assert.equals("Counterspell", spec.interruptSpell.name)
            assert.equals(24, spec.interruptSpell.cooldown)
        end)

        it("has defensives with valid HP thresholds", function()
            assert.is_true(#spec.defensives >= 2)
            for _, def in ipairs(spec.defensives) do
                assert.is_number(def.spellID)
                assert.is_number(def.hpThreshold)
                assert.is_true(def.hpThreshold > 0 and def.hpThreshold < 1)
            end
        end)

        it("defensives contain Ice Block", function()
            local ids = {}
            for _, def in ipairs(spec.defensives) do ids[def.spellID] = true end
            assert.is_true(ids[45438], "Ice Block (45438) must be defensive")
        end)

        it("resource is Mana (type 0)", function()
            assert.equals(0, spec.resource.type)
        end)

        it("has burstWindows for Combustion", function()
            assert.is_not_nil(spec.burstWindows.combustion)
            assert.equals(190319, spec.burstWindows.combustion.trigger)
            assert.equals(12, spec.burstWindows.combustion.duration)
        end)

        it("has prePullChecks for flask, food, rune", function()
            assert.is_not_nil(spec.prePullChecks.flask)
            assert.is_not_nil(spec.prePullChecks.food)
            assert.is_not_nil(spec.prePullChecks.rune)
        end)

        it("has inferenceRules with non-empty spell tables", function()
            assert.is_table(spec.inferenceRules)
            assert.is_table(spec.inferenceRules.aoeSpells)
            assert.is_table(spec.inferenceRules.singleTargetSpells)
            assert.is_table(spec.inferenceRules.spenderSpells)
            assert.is_table(spec.inferenceRules.executeSpells)
            assert.equals(190319, spec.inferenceRules.burstCooldownSpell)
        end)
    end)

    describe("APLData[63]", function()
        local apl

        before_each(function()
            apl = RA.APLData[63]
        end)

        it("loads", function()
            assert.is_not_nil(apl)
        end)

        it("has matching specID and class", function()
            assert.equals(63, apl.specID)
            assert.equals("MAGE", apl.class)
        end)

        it("has non-empty rules with required fields", function()
            assert.is_table(apl.rules)
            assert.is_true(#apl.rules >= 1)
            for _, rule in ipairs(apl.rules) do
                assert.is_number(rule.spellID)
                assert.is_string(rule.name)
                assert.is_number(rule.priority)
            end
        end)

        it("rules include Combustion (190319) and Pyroblast (11366)", function()
            local ids = {}
            for _, rule in ipairs(apl.rules) do ids[rule.spellID] = true end
            assert.is_true(ids[190319], "Combustion must appear in rules")
            assert.is_true(ids[11366], "Pyroblast must appear in rules")
        end)
    end)

    describe("DecisionTrees[63]", function()
        local dt

        before_each(function()
            dt = RA.DecisionTrees[63]
        end)

        it("loads", function()
            assert.is_not_nil(dt)
        end)

        it("has correct specID", function()
            assert.equals(63, dt.specID)
        end)

        it("exposes Evaluate function", function()
            assert.is_function(dt.Evaluate)
        end)

        it("Evaluate returns table or nil with given features", function()
            local features = {
                lastSpellID = 133,
                secondLastSpellID = 11366,
                thirdLastSpellID = 108853,
                timeSinceLastCast = 1.5,
                nameplateCount = 1,
                secondaryResource = 0,
                secondaryResourceMax = 5,
                blizzardRecommendation = 11366,
                combatDuration = 30,
                specID = 63,
            }
            local result = dt.Evaluate(features)
            -- Either nil (low confidence) or a {spellID, confidence} table
            if result ~= nil then
                assert.is_number(result.spellID)
                assert.is_number(result.confidence)
            end
        end)
    end)

    describe("TransitionMatrices[63]", function()
        local tm

        before_each(function()
            tm = RA.TransitionMatrices[63]
        end)

        it("loads", function()
            assert.is_not_nil(tm)
        end)

        it("has correct specID", function()
            assert.equals(63, tm.specID)
        end)

        it("has non-empty transition matrix", function()
            assert.is_table(tm.matrix)
            local rowCount = 0
            for _ in pairs(tm.matrix) do rowCount = rowCount + 1 end
            assert.is_true(rowCount > 0, "matrix must have at least one row")
        end)

        it("exposes GetTopTransitions", function()
            assert.is_function(tm.GetTopTransitions)
        end)

        it("GetTopTransitions returns top-N for known spell", function()
            -- Pick the first spell present in the matrix.
            local fromSpell
            for sid in pairs(tm.matrix) do fromSpell = sid; break end
            assert.is_not_nil(fromSpell)
            local top = tm.GetTopTransitions(fromSpell, 3)
            assert.is_table(top)
            assert.is_true(#top >= 1)
            for _, entry in ipairs(top) do
                assert.is_number(entry.spellID)
                assert.is_number(entry.probability)
            end
        end)
    end)
end)
