-- tests/test_apl_engine.lua
-- Unit tests for APLEngine: EvaluateCondition, SimulateSpellCast, PredictNext, lifecycle.
local helpers = require("tests.helpers")

describe("APLEngine", function()
    local RA, ns, APL

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Engine/APLEngine.lua", "RotaAssist", ns)
        APL = RA:GetModule("APLEngine")
    end)

    -- ================================================================
    -- Lifecycle
    -- ================================================================
    describe("lifecycle", function()
        it("loads and registers correctly", function()
            assert.is_not_nil(APL)
        end)

        it("HasAPL returns false before SetAPL", function()
            APL:ClearAPL()
            assert.is_false(APL:HasAPL())
        end)

        it("HasAPL returns true after SetAPL", function()
            APL:SetAPL(577, { rules = {} }, 12)
            assert.is_true(APL:HasAPL())
        end)

        it("ClearAPL resets state", function()
            APL:SetAPL(577, { rules = {} }, 12)
            APL:ClearAPL()
            assert.is_false(APL:HasAPL())
            assert.is_nil(APL:GetCurrentAPL())
        end)

        it("GetProfileName defaults to 'default'", function()
            assert.equals("default", APL:GetProfileName())
        end)

        it("SetProfile changes the active profile", function()
            APL:SetProfile("fel_scarred")
            assert.equals("fel_scarred", APL:GetProfileName())
            APL:SetProfile("default")
        end)

        it("auto-selects profile from active talents", function()
            _G._testTalentConfigID = 1
            _G._testTalentConfigInfo = { [1] = { treeIDs = { 101 } } }
            _G._testTalentTreeNodes = { [101] = { 201 } }
            _G._testTalentNodeInfo = {
                ["1:201"] = {
                    activeRank = 1,
                    activeEntry = { entryID = 301 },
                    entryIDs = { 301 },
                },
            }
            _G._testTalentEntryInfo = {
                ["1:301"] = { definitionID = 401 },
            }
            _G._testTalentDefinitionInfo = {
                [401] = { overrideName = "Demonsurge" },
            }

            APL:SetAPL(577, {
                profiles = {
                    ["default"] = { signatureTalentNames = { "Art of the Glaive" } },
                    ["fel_scarred"] = { signatureTalentNames = { "Demonsurge" } },
                },
            }, 12)

            assert.equals("fel_scarred", APL:GetProfileName())

            _G._testTalentConfigID = nil
            _G._testTalentConfigInfo = nil
            _G._testTalentTreeNodes = nil
            _G._testTalentNodeInfo = nil
            _G._testTalentEntryInfo = nil
            _G._testTalentDefinitionInfo = nil
        end)
    end)

    -- ================================================================
    -- Meta state
    -- ================================================================
    describe("Meta state", function()
        it("starts inactive", function()
            APL:SetMetaState(false)
            assert.is_false(APL:IsMetaActive())
        end)

        it("SetMetaState(true) activates", function()
            APL:SetMetaState(true)
            assert.is_true(APL:IsMetaActive())
            APL:SetMetaState(false)
        end)

        it("SetMetaStateFromCast activates for known meta spells", function()
            APL:SetMetaState(false)
            APL:SetMetaStateFromCast(191427) -- Havoc Meta
            assert.is_true(APL:IsMetaActive())
            APL:SetMetaState(false)
        end)

        it("SetMetaStateFromCast ignores unknown spells", function()
            APL:SetMetaState(false)
            APL:SetMetaStateFromCast(99999)
            assert.is_false(APL:IsMetaActive())
        end)
    end)

    -- ================================================================
    -- EvaluateCondition
    -- ================================================================
    describe("EvaluateCondition", function()
        it("returns true for nil condition", function()
            assert.is_true(APL:EvaluateCondition(nil, 100, {}))
        end)

        it("returns true for 'always'", function()
            assert.is_true(APL:EvaluateCondition("always", 100, {}))
        end)

        it("cd_ready passes when no CD recorded", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false }
            assert.is_true(APL:EvaluateCondition("cd_ready", 100, sim))
        end)

        it("cd_ready fails when spell is on CD", function()
            local sim = { cooldowns = { [100] = 10 }, resource = 50, inMeta = false }
            assert.is_false(APL:EvaluateCondition("cd_ready", 100, sim))
        end)

        it("not_in_meta passes when not in meta", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false }
            assert.is_true(APL:EvaluateCondition("not_in_meta", 100, sim))
        end)

        it("not_in_meta fails when in meta", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = true }
            assert.is_false(APL:EvaluateCondition("not_in_meta", 100, sim))
        end)

        it("in_meta passes when in meta", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = true }
            assert.is_true(APL:EvaluateCondition("in_meta", 100, sim))
        end)

        it("compound 'cd_ready AND not_in_meta' passes when both true", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false }
            assert.is_true(APL:EvaluateCondition("cd_ready AND not_in_meta", 100, sim))
        end)

        it("compound 'cd_ready AND not_in_meta' fails when one is false", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = true }
            assert.is_false(APL:EvaluateCondition("cd_ready AND not_in_meta", 100, sim))
        end)

        it("after:SPELLID passes when lastCast matches", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false, lastCast = 200 }
            assert.is_true(APL:EvaluateCondition("after:200", 100, sim))
        end)

        it("after:SPELLID fails when lastCast differs", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false, lastCast = 300 }
            assert.is_false(APL:EvaluateCondition("after:200", 100, sim))
        end)

        it("estimated_resource >= X supports spaced operators", function()
            local sim = { cooldowns = {}, resource = 80, inMeta = false }
            assert.is_true(APL:EvaluateCondition("estimated_resource >= 70", 100, sim))
            assert.is_false(APL:EvaluateCondition("estimated_resource >= 90", 100, sim))
        end)

        it("estimated_resource <= X supports compact operators", function()
            local sim = { cooldowns = {}, resource = 35, inMeta = false }
            assert.is_true(APL:EvaluateCondition("estimated_resource<=40", 100, sim))
            assert.is_false(APL:EvaluateCondition("estimated_resource<=20", 100, sim))
        end)

        it("target_count comparisons work", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false, targetCount = 3 }
            assert.is_true(APL:EvaluateCondition("target_count >= 2", 100, sim))
            assert.is_false(APL:EvaluateCondition("target_count < 3", 100, sim))
        end)

        it("combat_time comparisons work", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false, combatDuration = 4 }
            assert.is_true(APL:EvaluateCondition("combat_time >= 3", 100, sim))
            assert.is_false(APL:EvaluateCondition("combat_time < 2", 100, sim))
        end)

        it("window conditions work", function()
            local sim = {
                cooldowns = {},
                resource = 50,
                inMeta = false,
                windows = { essence_break = true },
            }
            assert.is_true(APL:EvaluateCondition("window:essence_break", 100, sim))
            assert.is_false(APL:EvaluateCondition("not_window:essence_break", 100, sim))
        end)

        it("charges comparisons work", function()
            local sim = {
                cooldowns = {},
                resource = 50,
                inMeta = false,
                charges = { [100] = 2 },
            }
            assert.is_true(APL:EvaluateCondition("charges >= 2", 100, sim))
            assert.is_false(APL:EvaluateCondition("charges < 2", 100, sim))
        end)
    end)

    -- ================================================================
    -- SimulateSpellCast
    -- ================================================================
    describe("SimulateSpellCast", function()
        it("sets lastCast to the spell ID", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false }
            APL:SimulateSpellCast(sim, 12345)
            assert.equals(12345, sim.lastCast)
        end)

        it("sets cooldown for WhitelistSpells entries", function()
            -- Setup a fake WhitelistSpells entry
            RA.WhitelistSpells = RA.WhitelistSpells or {}
            RA.WhitelistSpells[99001] = { name = "TestCD", cdSeconds = 30 }

            local sim = { cooldowns = {}, resource = 50, inMeta = false }
            APL:SimulateSpellCast(sim, 99001)
            assert.equals(30, sim.cooldowns[99001])

            RA.WhitelistSpells[99001] = nil
        end)

        it("mirrors CD to override pair", function()
            RA.WhitelistSpells = RA.WhitelistSpells or {}
            RA.WhitelistSpells[188499] = { name = "Blade Dance", cdSeconds = 10 }

            local sim = { cooldowns = {}, resource = 50, inMeta = false }
            APL:SimulateSpellCast(sim, 188499)
            assert.equals(10, sim.cooldowns[188499])
            assert.equals(10, sim.cooldowns[210152]) -- Death Sweep (override pair)

            RA.WhitelistSpells[188499] = nil
        end)

        it("activates simulated meta state for Demonic triggers", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false }
            APL:SimulateSpellCast(sim, 198013)
            assert.is_true(sim.inMeta)
        end)

        it("activates simulated essence break window", function()
            local sim = { cooldowns = {}, resource = 50, inMeta = false, windows = {} }
            APL:SimulateSpellCast(sim, 258860)
            assert.is_true(sim.windows.essence_break)
        end)

        it("expires simulated essence break window after two future casts", function()
            local sim = {
                cooldowns = {},
                resource = 80,
                inMeta = false,
                windows = {},
                windowSteps = {},
            }

            APL:SimulateSpellCast(sim, 258860)
            assert.is_true(sim.windows.essence_break)

            APL:SimulateSpellCast(sim, 162794)
            assert.is_true(sim.windows.essence_break)

            APL:SimulateSpellCast(sim, 162794)
            assert.is_false(sim.windows.essence_break)
        end)
    end)

    -- ================================================================
    -- PredictNext
    -- ================================================================
    describe("PredictNext", function()
        before_each(function()
            APL:ClearAPL()
            APL:SetMetaState(false)
        end)

        it("returns empty when no APL loaded", function()
            local result = APL:PredictNext(100, { resource = 50, cooldowns = {} }, 2)
            assert.equals(0, #result)
        end)

        it("returns empty when limitedState is nil", function()
            APL:SetAPL(577, { rules = {
                { spellID = 100, priority = 1, condition = "always" },
            }}, 12)
            local result = APL:PredictNext(100, nil, 2)
            assert.equals(0, #result)
        end)

        it("predicts from a simple rule list", function()
            APL:SetAPL(577, { rules = {
                { spellID = 100, priority = 1, condition = "always" },
                { spellID = 200, priority = 2, condition = "always" },
                { spellID = 300, priority = 3, condition = "always" },
            }}, 12)

            local state = { resource = 50, cooldowns = {}, inMeta = false, targetCount = 1 }
            local result = APL:PredictNext(nil, state, 2)

            assert.is_true(#result >= 1)
            assert.equals(100, result[1].spellID)
            assert.equals("apl_predict", result[1].source)
        end)

        it("skips passive spells in prediction", function()
            APL:SetAPL(577, { rules = {
                { spellID = 203555, priority = 1, condition = "always" }, -- passive
                { spellID = 200, priority = 2, condition = "always" },
            }}, 12)

            local state = { resource = 50, cooldowns = {}, inMeta = false, targetCount = 1 }
            local result = APL:PredictNext(nil, state, 1)

            assert.is_true(#result >= 1)
            assert.equals(200, result[1].spellID)
        end)

        it("respects cd_ready condition", function()
            APL:SetAPL(577, { rules = {
                { spellID = 100, priority = 1, condition = "cd_ready" },
                { spellID = 200, priority = 2, condition = "always" },
            }}, 12)

            local state = {
                resource = 50,
                cooldowns = { [100] = 15 }, -- spell 100 on CD
                inMeta = false,
                targetCount = 1,
            }
            local result = APL:PredictNext(nil, state, 1)

            assert.is_true(#result >= 1)
            assert.equals(200, result[1].spellID)
        end)

        it("confidence degrades with depth", function()
            APL:SetAPL(577, { rules = {
                { spellID = 100, priority = 1, condition = "always" },
                { spellID = 200, priority = 2, condition = "always" },
                { spellID = 300, priority = 3, condition = "always" },
            }}, 12)

            local state = { resource = 50, cooldowns = {}, inMeta = false, targetCount = 1 }
            local result = APL:PredictNext(nil, state, 3)

            if #result >= 2 then
                assert.is_true(result[1].confidence >= result[2].confidence)
            end
        end)

        it("predicts Demonic follow-up after Eye Beam", function()
            APL:SetAPL(577, {
                profiles = {
                    ["default"] = {
                        singleTarget = {
                            { spellID = 210152, priority = 1, condition = "in_meta" },
                            { spellID = 162794, priority = 2, condition = "always" },
                        },
                    },
                },
            }, 12)

            local state = {
                resource = 60,
                cooldowns = {},
                inMeta = false,
                targetCount = 1,
                combatDuration = 4,
            }
            local result = APL:PredictNext(198013, state, 1)

            assert.is_true(#result >= 1)
            assert.equals(210152, result[1].spellID)
        end)
    end)
end)
