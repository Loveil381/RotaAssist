-- tests/test_defensive_advisor.lua
-- Unit tests for DefensiveAdvisor module.
local helpers = require("tests.helpers")

describe("DefensiveAdvisor", function()
    local RA, ns, DA

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)

        _G.Enum = { LuaCurveType = { Step = 1 } }
        local origCreateFrame = _G.CreateFrame
        _G.CreateFrame = function(...)
            local f = origCreateFrame(...)
            f.SetParent = function() end
            return f
        end
        _G.C_CurveUtil = {
            CreateColorCurve = function()
                return {
                    SetType = function() end,
                    AddPoint = function() end,
                }
            end,
        }
        _G.CreateColor = function(r, g, b, a) return { GetRGBA = function() return r, g, b, a end } end
        _G.UnitHealthPercent = function() return nil end

        helpers.loadAddonFile("addon/Engine/DefensiveAdvisor.lua", "RotaAssist", ns)
        DA = RA:GetModule("DefensiveAdvisor")
        DA:OnInitialize()
    end)

    describe("module loading", function()
        it("registers correctly", function()
            assert.is_not_nil(DA)
        end)
    end)

    describe("GetActiveRecommendation", function()
        it("returns nil when no alert is active", function()
            assert.is_nil(DA:GetActiveRecommendation())
        end)
    end)

    describe("GetDefensives", function()
        it("returns nil before LoadForSpec", function()
            assert.is_nil(DA:GetDefensives())
        end)
    end)

    describe("GetHealthPercent", function()
        it("returns a number", function()
            local hp = DA:GetHealthPercent()
            assert.is_number(hp)
        end)

        it("returns 0.8 with default mock (80000/100000)", function()
            local hp = DA:GetHealthPercent()
            assert.equals(0.8, hp)
        end)

        it("returns cached value when HP is secret", function()
            -- First call caches 0.8
            DA:GetHealthPercent()
            -- Mock HP as secret
            local origHP = _G.UnitHealth
            local origSec = _G.issecretvalue
            _G.UnitHealth = function() return "SECRET" end
            _G.issecretvalue = function(v) return v == "SECRET" end

            local hp = DA:GetHealthPercent()
            assert.equals(0.8, hp) -- cached value

            _G.UnitHealth = origHP
            _G.issecretvalue = origSec
        end)
    end)

    describe("LoadForSpec", function()
        it("does not crash with nil specID", function()
            assert.has_no.errors(function()
                DA:LoadForSpec(nil)
            end)
        end)

        it("does not crash when SpecEnhancements is nil", function()
            local saved = RA.SpecEnhancements
            RA.SpecEnhancements = nil
            assert.has_no.errors(function()
                DA:LoadForSpec(577)
            end)
            RA.SpecEnhancements = saved
        end)

        it("loads defensives from SpecEnhancements", function()
            RA.SpecEnhancements = {
                [577] = {
                    defensives = {
                        { spellID = 198589, hpThreshold = 0.35 }, -- Blur
                    },
                },
            }
            DA:LoadForSpec(577)
            local defs = DA:GetDefensives()
            assert.is_not_nil(defs)
            assert.equals(1, #defs)
            assert.equals(198589, defs[1].spellID)
            RA.SpecEnhancements = nil
        end)

        it("clears state when loading spec with no defensives", function()
            RA.SpecEnhancements = {
                [577] = {
                    defensives = {
                        { spellID = 198589, hpThreshold = 0.35 },
                    },
                },
            }
            DA:LoadForSpec(577)
            assert.is_not_nil(DA:GetDefensives())

            DA:LoadForSpec(nil)
            assert.is_nil(DA:GetDefensives())
            assert.is_nil(DA:GetActiveRecommendation())
            RA.SpecEnhancements = nil
        end)
    end)

    describe("OnDisable", function()
        it("cleans up state without error", function()
            assert.has_no.errors(function()
                DA:OnDisable()
            end)
            assert.is_nil(DA:GetDefensives())
            assert.is_nil(DA:GetActiveRecommendation())
        end)
    end)
end)
