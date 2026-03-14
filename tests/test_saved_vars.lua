-- tests/test_saved_vars.lua
-- Unit tests for SavedVars defaults and DeepCopy.
local helpers = require("tests.helpers")

describe("SavedVars", function()
    local RA, ns, SV

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/SavedVars.lua", "RotaAssist", ns)
        SV = RA:GetModule("SavedVars")
    end)

    describe("module loading", function()
        it("registers correctly", function()
            assert.is_not_nil(SV)
        end)
    end)

    describe("GetDefaults", function()
        it("returns a table", function()
            local defs = SV:GetDefaults()
            assert.is_table(defs)
        end)

        it("returns a deep copy (not the same reference)", function()
            local d1 = SV:GetDefaults()
            local d2 = SV:GetDefaults()
            assert.is_not.equals(d1, d2)
            assert.is_not.equals(d1.profile, d2.profile)
        end)

        it("contains profile.general with expected keys", function()
            local defs = SV:GetDefaults()
            assert.is_table(defs.profile)
            assert.is_table(defs.profile.general)
            assert.equals(true, defs.profile.general.enabled)
            assert.equals("auto", defs.profile.general.language)
            assert.equals(false, defs.profile.general.debugMode)
        end)

        it("contains profile.display with expected defaults", function()
            local defs = SV:GetDefaults()
            assert.is_table(defs.profile.display)
            assert.equals(3, defs.profile.display.iconCount)
            assert.equals(48, defs.profile.display.iconSize)
            assert.equals(1.0, defs.profile.display.scale)
            assert.equals(-200, defs.profile.display.anchorY)
        end)

        it("contains profile.smartQueue with weight defaults", function()
            local defs = SV:GetDefaults()
            assert.is_table(defs.profile.smartQueue)
            assert.equals(1.0, defs.profile.smartQueue.blizzardWeight)
            assert.equals(0.6, defs.profile.smartQueue.aplWeight)
            assert.equals(0.4, defs.profile.smartQueue.aiWeight)
            assert.equals(0.5, defs.profile.smartQueue.cdWeight)
            assert.equals(0.8, defs.profile.smartQueue.defWeight)
        end)

        it("contains profile.cooldowns section", function()
            local defs = SV:GetDefaults()
            assert.is_table(defs.profile.cooldowns)
            assert.equals(true, defs.profile.cooldowns.enabled)
            assert.equals(0.8, defs.profile.cooldowns.panelScale)
        end)

        it("contains profile.interrupt section", function()
            local defs = SV:GetDefaults()
            assert.is_table(defs.profile.interrupt)
            assert.equals(true, defs.profile.interrupt.enabled)
            assert.equals(true, defs.profile.interrupt.soundAlert)
        end)
    end)

    describe("RA.DeepCopy", function()
        it("copies a simple table", function()
            local src = { a = 1, b = "hello" }
            local copy = RA.DeepCopy(src)
            assert.equals(1, copy.a)
            assert.equals("hello", copy.b)
            assert.is_not.equals(src, copy)
        end)

        it("deep copies nested tables", function()
            local src = { inner = { x = 10 } }
            local copy = RA.DeepCopy(src)
            assert.equals(10, copy.inner.x)
            assert.is_not.equals(src.inner, copy.inner)
        end)

        it("modifying copy does not affect original", function()
            local src = { inner = { x = 10 } }
            local copy = RA.DeepCopy(src)
            copy.inner.x = 999
            assert.equals(10, src.inner.x)
        end)

        it("handles empty tables", function()
            local copy = RA.DeepCopy({})
            assert.is_table(copy)
            local count = 0
            for _ in pairs(copy) do count = count + 1 end
            assert.equals(0, count)
        end)
    end)
end)
