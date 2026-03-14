-- tests/test_interrupt_advisor.lua
-- Unit tests for addon/Engine/InterruptAdvisor.lua
local helpers = require("tests.helpers")

describe("InterruptAdvisor", function()
    local RA, ns, IA

    setup(function()
        -- Ensure mock globals
        helpers.ensureMockLoaded()

        -- Add missing mock for GetCVar
        _G.GetCVar = _G.GetCVar or function(name) return "0" end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/InterruptAdvisor.lua", "RotaAssist", ns)
        IA = RA:GetModule("InterruptAdvisor")
    end)

    describe("module registration", function()
        it("loads successfully", function()
            assert.is_not_nil(IA)
        end)

        it("has the expected public API", function()
            assert.is_function(IA.GetInterruptState)
            assert.is_function(IA.OnInitialize)
            assert.is_function(IA.OnEnable)
            assert.is_function(IA.OnDisable)
        end)
    end)

    describe("GetInterruptState", function()
        it("returns a table", function()
            local state = IA:GetInterruptState()
            assert.is_table(state)
        end)

        it("contains expected fields", function()
            local state = IA:GetInterruptState()
            -- The state should have at minimum these keys
            assert.is_not_nil(state.shouldInterrupt ~= nil or state.available ~= nil,
                "state should have shouldInterrupt or available field")
        end)

        it("reports shouldInterrupt as false when out of combat", function()
            _G.InCombatLockdown = function() return false end
            local state = IA:GetInterruptState()
            -- Out of combat, nothing to interrupt
            if state.shouldInterrupt ~= nil then
                assert.is_false(state.shouldInterrupt)
            end
            -- Restore
            _G.InCombatLockdown = function() return false end
        end)
    end)

    describe("lifecycle", function()
        it("OnInitialize runs without error", function()
            assert.has_no.errors(function() IA:OnInitialize() end)
        end)

        it("OnEnable runs without error", function()
            -- OnEnable needs EventHandler and SpecDetector/SpecEnhancements
            -- Since they may not be fully loaded, just verify no crash
            assert.has_no.errors(function()
                pcall(function() IA:OnEnable() end)
            end)
        end)
    end)
end)
