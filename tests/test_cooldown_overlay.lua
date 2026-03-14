-- tests/test_cooldown_overlay.lua
-- Unit tests for CooldownOverlay module.
local helpers = require("tests.helpers")

describe("CooldownOverlay", function()
    local RA, ns, CO

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/CooldownOverlay.lua", "RotaAssist", ns)
        CO = RA:GetModule("CooldownOverlay")
        CO:OnInitialize()
    end)

    describe("module loading", function()
        it("registers correctly", function()
            assert.is_not_nil(CO)
        end)
    end)

    describe("GetCooldownStates", function()
        it("returns a table", function()
            assert.is_table(CO:GetCooldownStates())
        end)

        it("returns empty table before LoadForSpec", function()
            local states = CO:GetCooldownStates()
            local count = 0
            for _ in pairs(states) do count = count + 1 end
            assert.equals(0, count)
        end)
    end)

    describe("GetReadyCooldowns", function()
        it("returns an empty array when nothing is tracked", function()
            local ready = CO:GetReadyCooldowns()
            assert.is_table(ready)
            assert.equals(0, #ready)
        end)
    end)

    describe("RefreshSpellCooldown", function()
        it("does not crash with nil", function()
            assert.has_no.errors(function()
                CO:RefreshSpellCooldown(nil)
            end)
        end)

        it("creates a state entry for a new spell", function()
            CO:RefreshSpellCooldown(99999)
            local states = CO:GetCooldownStates()
            assert.is_not_nil(states[99999])
            assert.is_true(states[99999].ready)
            assert.equals(0, states[99999].remaining)
        end)

        it("mirrors state to override pair", function()
            -- Refresh Blade Dance (188499) — should also update Death Sweep (210152) if tracked
            -- First create state for both
            CO:RefreshSpellCooldown(188499)
            CO:RefreshSpellCooldown(210152)
            -- Now refresh 188499 — 210152 should mirror
            CO:RefreshSpellCooldown(188499)
            local states = CO:GetCooldownStates()
            assert.equals(states[188499].ready, states[210152].ready)
            assert.equals(states[188499].remaining, states[210152].remaining)
        end)

        it("marks spell on-CD when API returns long cooldown", function()
            local orig = C_Spell.GetSpellCooldown
            C_Spell.GetSpellCooldown = function(id)
                if id == 77777 then
                    return { startTime = 980, duration = 120, isEnabled = true }
                end
                return { startTime = 0, duration = 0, isEnabled = true }
            end
            CO:RefreshSpellCooldown(77777)
            local states = CO:GetCooldownStates()
            assert.is_false(states[77777].ready)
            assert.is_true(states[77777].remaining > 0)
            C_Spell.GetSpellCooldown = orig
        end)
    end)

    describe("LoadForSpec", function()
        it("does not crash with nil specID", function()
            assert.has_no.errors(function()
                CO:LoadForSpec(nil)
            end)
        end)

        it("does not crash when SpecEnhancements is nil", function()
            local saved = RA.SpecEnhancements
            RA.SpecEnhancements = nil
            assert.has_no.errors(function()
                CO:LoadForSpec(577)
            end)
            RA.SpecEnhancements = saved
        end)

        it("clears tracked CDs on load with empty config", function()
            CO:LoadForSpec(nil)
            local states = CO:GetCooldownStates()
            local count = 0
            for _ in pairs(states) do count = count + 1 end
            assert.equals(0, count)
        end)
    end)
end)
