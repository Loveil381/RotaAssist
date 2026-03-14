-- tests/test_ai_inference.lua
-- Unit tests for addon/Engine/AIInference.lua
local helpers = require("tests.helpers")

describe("AIInference", function()
    local RA, ns, AI

    setup(function()
        helpers.ensureMockLoaded()

        -- AIInference uses CreateFrame, GetTime, InCombatLockdown, C_Spell, UnitExists, etc.
        -- Most are already in mock_wow_api.lua
        _G.GetSpecialization = _G.GetSpecialization or function() return 1 end
        _G.GetSpecializationInfo = _G.GetSpecializationInfo or function()
            return 577, "Havoc", "", 0, "DAMAGER"
        end
        _G.UnitClass = _G.UnitClass or function() return "Demon Hunter", "DEMONHUNTER", 12 end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)

        -- Load dependencies that AIInference may reference
        pcall(helpers.loadAddonFile, "addon/Engine/SpecDetector.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/AssistedCombatBridge.lua", "RotaAssist", ns)

        helpers.loadAddonFile("addon/Engine/AIInference.lua", "RotaAssist", ns)
        AI = RA:GetModule("AIInference")
    end)

    describe("module registration", function()
        it("loads successfully", function()
            assert.is_not_nil(AI)
        end)

        it("has GetContext method", function()
            assert.is_function(AI.GetContext)
        end)
    end)

    describe("InferredState structure", function()
        it("has an InferredState table", function()
            assert.is_table(AI.InferredState)
        end)

        it("contains targetCount", function()
            assert.is_number(AI.InferredState.targetCount)
        end)

        it("contains timeSincePull", function()
            assert.is_number(AI.InferredState.timeSincePull)
        end)

        it("contains blizzardRecommendation", function()
            assert.is_number(AI.InferredState.blizzardRecommendation)
        end)

        it("contains inferred sub-table", function()
            assert.is_table(AI.InferredState.inferred)
        end)

        it("inferred has combatPhase", function()
            assert.is_string(AI.InferredState.inferred.combatPhase)
        end)

        it("inferred has phaseConfidence", function()
            assert.is_number(AI.InferredState.inferred.phaseConfidence)
        end)

        it("inferred has resourceState", function()
            assert.is_string(AI.InferredState.inferred.resourceState)
        end)

        it("inferred has burstActive", function()
            assert.is_boolean(AI.InferredState.inferred.burstActive)
        end)

        it("inferred has aoeActive", function()
            assert.is_boolean(AI.InferredState.inferred.aoeActive)
        end)
    end)

    describe("GetContext", function()
        it("returns the InferredState table", function()
            local ctx = AI:GetContext()
            assert.is_table(ctx)
            assert.equals(AI.InferredState, ctx)
        end)

        it("context defaults to NORMAL phase out of combat", function()
            _G.InCombatLockdown = function() return false end
            local ctx = AI:GetContext()
            assert.equals("NORMAL", ctx.inferred.combatPhase)
        end)

        it("context defaults to targetCount 1", function()
            local ctx = AI:GetContext()
            assert.is_true(ctx.targetCount >= 1)
        end)
    end)

    describe("default state values", function()
        it("burstActive defaults to false", function()
            assert.is_false(AI.InferredState.inferred.burstActive)
        end)

        it("aoeActive defaults to false", function()
            assert.is_false(AI.InferredState.inferred.aoeActive)
        end)

        it("resourceState defaults to UNKNOWN", function()
            assert.equals("UNKNOWN", AI.InferredState.inferred.resourceState)
        end)

        it("tip defaults to nil", function()
            assert.is_nil(AI.InferredState.inferred.tip)
        end)
    end)

    describe("lifecycle", function()
        it("OnInitialize runs without error", function()
            assert.has_no.errors(function() AI:OnInitialize() end)
        end)

        it("OnEnable runs without error", function()
            assert.has_no.errors(function()
                pcall(function() AI:OnEnable() end)
            end)
        end)

        it("OnDisable runs without error", function()
            assert.has_no.errors(function()
                pcall(function() AI:OnDisable() end)
            end)
        end)
    end)
end)
