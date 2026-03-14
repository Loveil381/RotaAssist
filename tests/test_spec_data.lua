-- tests/test_spec_data.lua
-- Validates RA.SpecData completeness and structural integrity.
local helpers = require("tests.helpers")

describe("SpecData validation", function()
    local RA, ns

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Data/SpecInfo.lua", "RotaAssist", ns)
    end)

    describe("SpecData table", function()
        it("exists and is a table", function()
            assert.is_table(RA.SpecData)
        end)

        it("contains at least 39 specs (13 classes × 3 specs + extras)", function()
            local count = 0
            for _ in pairs(RA.SpecData) do count = count + 1 end
            assert.is_true(count >= 39,
                "Expected at least 39 specs, got " .. count)
        end)
    end)

    describe("each spec entry", function()
        it("has all required fields (classID, className, specName, role, icon)", function()
            for specID, data in pairs(RA.SpecData) do
                assert.is_number(data.classID,
                    "specID " .. specID .. " missing classID")
                assert.is_string(data.className,
                    "specID " .. specID .. " missing className")
                assert.is_string(data.specName,
                    "specID " .. specID .. " missing specName")
                assert.is_string(data.role,
                    "specID " .. specID .. " missing role")
                assert.is_number(data.icon,
                    "specID " .. specID .. " missing icon")
            end
        end)

        it("has a valid role value", function()
            local validRoles = { DAMAGER = true, HEALER = true, TANK = true }
            for specID, data in pairs(RA.SpecData) do
                assert.is_true(validRoles[data.role],
                    "specID " .. specID .. " has invalid role: " .. tostring(data.role))
            end
        end)

        it("has a classColor string", function()
            for specID, data in pairs(RA.SpecData) do
                assert.is_string(data.classColor,
                    "specID " .. specID .. " missing classColor")
                assert.equals(6, #data.classColor,
                    "specID " .. specID .. " classColor should be 6 hex chars, got: " .. tostring(data.classColor))
            end
        end)
    end)

    describe("ClassSpecs reverse lookup", function()
        it("exists and is a table", function()
            assert.is_table(RA.ClassSpecs)
        end)

        it("covers all 13 class IDs", function()
            for classID = 1, 13 do
                assert.is_table(RA.ClassSpecs[classID],
                    "Missing ClassSpecs entry for classID " .. classID)
                assert.is_true(#RA.ClassSpecs[classID] >= 2,
                    "classID " .. classID .. " should have at least 2 specs")
            end
        end)
    end)

    describe("SpecCount", function()
        it("matches the number of entries in SpecData", function()
            local count = 0
            for _ in pairs(RA.SpecData) do count = count + 1 end
            assert.equals(count, RA.SpecCount)
        end)
    end)

    describe("known spec IDs", function()
        it("contains Havoc DH (577)", function()
            assert.is_not_nil(RA.SpecData[577])
            assert.equals("Havoc", RA.SpecData[577].specName)
        end)

        it("contains Devourer DH (1480)", function()
            assert.is_not_nil(RA.SpecData[1480])
            assert.equals("Devourer", RA.SpecData[1480].specName)
        end)

        it("contains Evoker Augmentation (1473)", function()
            assert.is_not_nil(RA.SpecData[1473])
            assert.equals("Augmentation", RA.SpecData[1473].specName)
        end)
    end)
end)
