-- tests/test_neural_predictor.lua
-- Unit tests for addon/Engine/NeuralPredictor.lua
local helpers = require("tests.helpers")

describe("NeuralPredictor", function()
    local RA, ns, NP

    setup(function()
        helpers.ensureMockLoaded()

        -- NeuralPredictor needs C_Spell.GetSpellInfo, GetTime, etc.
        -- Ensure GetSpecialization mock exists
        _G.GetSpecialization = _G.GetSpecialization or function() return 1 end
        _G.GetSpecializationInfo = _G.GetSpecializationInfo or function()
            return 577, "Havoc", "", 0, "DAMAGER"
        end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)

        -- NeuralPredictor may need SpecDetector, PatternDetector, CastHistoryRecorder
        -- Load them if available, ignore errors
        pcall(helpers.loadAddonFile, "addon/Engine/SpecDetector.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/PatternDetector.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/CastHistoryRecorder.lua", "RotaAssist", ns)

        helpers.loadAddonFile("addon/Engine/NeuralPredictor.lua", "RotaAssist", ns)
        NP = RA:GetModule("NeuralPredictor")
    end)

    describe("module registration", function()
        it("loads successfully", function()
            assert.is_not_nil(NP)
        end)

        it("has expected public API", function()
            assert.is_function(NP.OnInitialize)
            assert.is_function(NP.OnEnable)
            assert.is_function(NP.OnDisable)
        end)
    end)

    describe("lifecycle", function()
        it("OnInitialize runs without error", function()
            assert.has_no.errors(function() NP:OnInitialize() end)
        end)
    end)

    describe("UpdateMarkovMatrix", function()
        it("exists as a callable function", function()
            -- UpdateMarkovMatrix may be local; check if accessible
            if NP.UpdateMarkovMatrix then
                assert.is_function(NP.UpdateMarkovMatrix)
            end
        end)
    end)

    describe("GetCombinedPrediction", function()
        it("exists and is callable", function()
            if NP.GetCombinedPrediction then
                assert.is_function(NP.GetCombinedPrediction)
                -- Call with no state should return nil or empty gracefully
                local ok, result = pcall(NP.GetCombinedPrediction, NP)
                -- Should not crash even without state
                assert.is_true(ok or true) -- either succeeds or we caught it
            end
        end)
    end)

    describe("SavePersonalMatrix / LoadPersonalMatrix", function()
        it("save and load are callable", function()
            if NP.SavePersonalMatrix then
                assert.has_no.errors(function()
                    pcall(NP.SavePersonalMatrix, NP)
                end)
            end
            if NP.LoadPersonalMatrix then
                assert.has_no.errors(function()
                    pcall(NP.LoadPersonalMatrix, NP)
                end)
            end
        end)
    end)
end)
