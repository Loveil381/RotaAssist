-- tests/test_spec_detector.lua
-- Unit tests for addon/Engine/SpecDetector.lua
local helpers = require("tests.helpers")

describe("SpecDetector", function()
    local RA, ns, SD

    setup(function()
        helpers.ensureMockLoaded()

        -- SpecDetector needs GetSpecialization, GetSpecializationInfo, UnitClass
        _G.GetSpecialization = function() return 1 end
        _G.GetSpecializationInfo = function(index)
            -- Returns: specID, specName, description, icon, role
            return 577, "Havoc", "A leather-wearing demon hunter.", 1247264, "DAMAGER"
        end
        _G.UnitClass = function(unit)
            -- Returns: localizedName, englishName, classID
            return "Demon Hunter", "DEMONHUNTER", 12
        end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/SpecDetector.lua", "RotaAssist", ns)
        SD = RA:GetModule("SpecDetector")
    end)

    describe("module registration", function()
        it("loads successfully", function()
            assert.is_not_nil(SD)
        end)

        it("has expected public API", function()
            assert.is_function(SD.GetCurrentSpec)
            assert.is_function(SD.IsRole)
            assert.is_function(SD.GetSpecID)
            assert.is_function(SD.GetPrimaryPowerType)
        end)
    end)

    describe("GetCurrentSpec", function()
        it("returns a table with spec information", function()
            local spec = SD:GetCurrentSpec()
            assert.is_table(spec)
        end)

        it("returns correct specID from mock", function()
            local spec = SD:GetCurrentSpec()
            assert.equals(577, spec.specID)
        end)

        it("returns correct classID from mock", function()
            local spec = SD:GetCurrentSpec()
            assert.equals(12, spec.classID)
        end)

        it("returns correct className", function()
            local spec = SD:GetCurrentSpec()
            assert.equals("DEMONHUNTER", spec.className)
        end)

        it("returns correct specName", function()
            local spec = SD:GetCurrentSpec()
            assert.equals("Havoc", spec.specName)
        end)

        it("returns correct role", function()
            local spec = SD:GetCurrentSpec()
            assert.equals("DAMAGER", spec.role)
        end)

        it("returns icon texture ID", function()
            local spec = SD:GetCurrentSpec()
            assert.is_number(spec.icon)
            assert.equals(1247264, spec.icon)
        end)
    end)

    describe("IsRole", function()
        it("returns true for DAMAGER (mocked spec)", function()
            assert.is_true(SD:IsRole("DAMAGER"))
        end)

        it("returns false for TANK", function()
            assert.is_false(SD:IsRole("TANK"))
        end)

        it("returns false for HEALER", function()
            assert.is_false(SD:IsRole("HEALER"))
        end)
    end)

    describe("GetSpecID", function()
        it("returns 577 for mocked Havoc DH", function()
            assert.equals(577, SD:GetSpecID())
        end)
    end)

    describe("GetPrimaryPowerType", function()
        it("returns nil when SpecEnhancements is not loaded", function()
            local pt = SD:GetPrimaryPowerType()
            -- Without SpecEnhancements data, should return nil
            if not RA.SpecEnhancements then
                assert.is_nil(pt)
            end
        end)

        it("returns the power type when SpecEnhancements is configured", function()
            -- Setup mock SpecEnhancements
            RA.SpecEnhancements = RA.SpecEnhancements or {}
            RA.SpecEnhancements[577] = RA.SpecEnhancements[577] or {}
            RA.SpecEnhancements[577].resource = { type = 17 } -- Fury

            local pt = SD:GetPrimaryPowerType()
            assert.equals(17, pt)

            -- Cleanup
            RA.SpecEnhancements[577].resource = nil
        end)
    end)

    describe("spec change simulation", function()
        it("detects spec change when mock values change", function()
            -- Switch to Vengeance
            _G.GetSpecializationInfo = function(index)
                return 581, "Vengeance", "", 1247265, "TANK"
            end
            _G.UnitClass = function(unit)
                return "Demon Hunter", "DEMONHUNTER", 12
            end

            -- Force a re-detection by calling GetCurrentSpec with cleared cache
            -- SpecDetector uses local currentSpec; calling the public method triggers refreshSpec
            -- We need to simulate the PLAYER_SPECIALIZATION_CHANGED event
            local eh = RA:GetModule("EventHandler")
            if eh then
                eh:Fire("PLAYER_SPECIALIZATION_CHANGED")
            end

            local spec = SD:GetCurrentSpec()
            assert.equals(581, spec.specID)
            assert.equals("Vengeance", spec.specName)
            assert.equals("TANK", spec.role)

            -- Restore for other tests
            _G.GetSpecializationInfo = function(index)
                return 577, "Havoc", "", 1247264, "DAMAGER"
            end
        end)
    end)

    describe("lifecycle", function()
        it("OnInitialize runs without error", function()
            assert.has_no.errors(function() SD:OnInitialize() end)
        end)
    end)
end)
