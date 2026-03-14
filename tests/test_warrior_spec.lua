-- tests/test_warrior_spec.lua
-- Unit tests for Warrior SpecEnhancements data integrity.
local helpers = require("tests.helpers")

describe("Warrior SpecEnhancements", function()
    local RA, ns

    setup(function()
        helpers.ensureMockLoaded()
        _G.GetSpecialization = function() return 1 end
        _G.GetSpecializationInfo = function()
            return 71, "Arms", "", 132355, "DAMAGER"
        end
        _G.UnitClass = function() return "Warrior", "WARRIOR", 1 end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Data/SpecInfo.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/SpecEnhancements/Warrior.lua", "RotaAssist", ns)
    end)

    describe("Arms (specID 71)", function()
        local spec

        before_each(function()
            spec = RA.SpecEnhancements[71]
        end)

        it("exists", function()
            assert.is_not_nil(spec)
        end)

        it("has majorCooldowns with 3 entries", function()
            assert.equals(3, #spec.majorCooldowns)
        end)

        it("majorCooldowns contain Colossus Smash, Bladestorm, Avatar", function()
            local ids = {}
            for _, cd in ipairs(spec.majorCooldowns) do ids[cd.spellID] = true end
            assert.is_true(ids[167105], "Colossus Smash")
            assert.is_true(ids[227847], "Bladestorm")
            assert.is_true(ids[107574], "Avatar")
        end)

        it("has interruptSpell (Pummel)", function()
            assert.is_not_nil(spec.interruptSpell)
            assert.equals(6552, spec.interruptSpell.spellID)
            assert.equals(15, spec.interruptSpell.cooldown)
        end)

        it("has defensives with HP thresholds", function()
            assert.is_true(#spec.defensives >= 2)
            for _, def in ipairs(spec.defensives) do
                assert.is_number(def.spellID)
                assert.is_number(def.hpThreshold)
                assert.is_true(def.hpThreshold > 0 and def.hpThreshold < 1)
            end
        end)

        it("resource powerType is Rage (1)", function()
            assert.equals(1, spec.resource.powerType)
        end)

        it("resource spellCosts has Mortal Strike costing 30", function()
            assert.equals(30, spec.resource.spellCosts[12294].cost)
        end)

        it("has burstWindows for Colossus Smash", function()
            assert.is_not_nil(spec.burstWindows.colossus)
            assert.equals(167105, spec.burstWindows.colossus.trigger)
        end)

        it("has inferenceRules with executeSpells", function()
            assert.is_table(spec.inferenceRules.executeSpells)
            assert.equals(163201, spec.inferenceRules.executeSpells[1])
        end)

        it("has prePullChecks", function()
            assert.is_not_nil(spec.prePullChecks.flask)
            assert.is_not_nil(spec.prePullChecks.food)
            assert.is_not_nil(spec.prePullChecks.rune)
        end)
    end)

    describe("Fury (specID 72)", function()
        local spec

        before_each(function()
            spec = RA.SpecEnhancements[72]
        end)

        it("exists", function()
            assert.is_not_nil(spec)
        end)

        it("has majorCooldowns with 3 entries", function()
            assert.equals(3, #spec.majorCooldowns)
        end)

        it("majorCooldowns contain Recklessness, Ravager, Avatar", function()
            local ids = {}
            for _, cd in ipairs(spec.majorCooldowns) do ids[cd.spellID] = true end
            assert.is_true(ids[1719], "Recklessness")
            assert.is_true(ids[228920], "Ravager")
            assert.is_true(ids[107574], "Avatar")
        end)

        it("has interruptSpell (Pummel)", function()
            assert.equals(6552, spec.interruptSpell.spellID)
        end)

        it("resource powerType is Rage (1)", function()
            assert.equals(1, spec.resource.powerType)
        end)

        it("Rampage costs 80 rage", function()
            assert.equals(80, spec.resource.spellCosts[184367].cost)
        end)

        it("Raging Blow generates 12 rage", function()
            assert.equals(12, spec.resource.spellCosts[85288].gen)
        end)

        it("burstWindows has Recklessness with 12s duration", function()
            assert.is_not_nil(spec.burstWindows.recklessness)
            assert.equals(1719, spec.burstWindows.recklessness.trigger)
            assert.equals(12, spec.burstWindows.recklessness.duration)
        end)

        it("inferenceRules has burst indicators for Recklessness overrides", function()
            local indicators = spec.inferenceRules.burstIndicatorSpells
            assert.is_table(indicators)
            assert.is_true(#indicators >= 2)
        end)

        it("has executeSpells", function()
            assert.equals(5308, spec.inferenceRules.executeSpells[1])
        end)

        it("has defensives", function()
            assert.is_true(#spec.defensives >= 2)
        end)
    end)

    describe("Cross-spec consistency", function()
        it("both specs share the same interrupt spell", function()
            assert.equals(
                RA.SpecEnhancements[71].interruptSpell.spellID,
                RA.SpecEnhancements[72].interruptSpell.spellID
            )
        end)

        it("both specs have Rage as powerType", function()
            assert.equals(
                RA.SpecEnhancements[71].resource.powerType,
                RA.SpecEnhancements[72].resource.powerType
            )
        end)

        it("SpecData has entries for both Arms and Fury", function()
            assert.is_not_nil(RA.SpecData[71])
            assert.equals("Arms", RA.SpecData[71].specName)
            assert.is_not_nil(RA.SpecData[72])
            assert.equals("Fury", RA.SpecData[72].specName)
        end)
    end)
end)
