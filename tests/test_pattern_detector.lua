-- tests/test_pattern_detector.lua
-- Unit tests for PatternDetector phase enum and helper functions.
local helpers = require("tests.helpers")

describe("PatternDetector", function()
    local RA, ns, PD

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Engine/EventHandler.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/CastHistoryRecorder.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/PatternDetector.lua", "RotaAssist", ns)
        PD = RA:GetModule("PatternDetector")
        PD:OnInitialize()
    end)

    describe("PHASE enum", function()
        it("defines all 12 expected phases", function()
            local expected = {
                "PREPULL", "OPENER", "NORMAL", "AOE",
                "BURST_PREPARE", "BURST_ACTIVE", "BURST_COOLDOWN",
                "RESOURCE_STARVED", "RESOURCE_CAP",
                "EXECUTE", "EMERGENCY", "UNKNOWN",
            }
            for _, phase in ipairs(expected) do
                assert.is_not_nil(PD.PHASE[phase],
                    "Missing phase: " .. phase)
                assert.equals(phase, PD.PHASE[phase])
            end
        end)

        it("has exactly 12 phases", function()
            local count = 0
            for _ in pairs(PD.PHASE) do count = count + 1 end
            assert.equals(12, count)
        end)
    end)

    describe("GetPhase", function()
        it("returns a table with phase, confidence, and signals", function()
            local result = PD:GetPhase()
            assert.is_table(result)
            assert.is_string(result.phase)
            assert.is_number(result.confidence)
        end)

        it("defaults to PREPULL when not in combat", function()
            -- InCombatLockdown() returns false in mock
            local result = PD:GetPhase()
            assert.equals("PREPULL", result.phase)
        end)
    end)

    describe("GetNameplateCount", function()
        it("returns at least 1 (clamped minimum)", function()
            local count = PD:GetNameplateCount()
            assert.is_true(count >= 1)
        end)
    end)

    describe("GetResourceTrend", function()
        it("returns 'stable' when fewer than 3 samples", function()
            assert.equals("stable", PD:GetResourceTrend())
        end)
    end)
end)
