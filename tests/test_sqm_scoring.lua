-- tests/test_sqm_scoring.lua
-- Unit tests for SmartQueueManager's CalculateScore function.
local helpers = require("tests.helpers")

describe("SmartQueueManager CalculateScore", function()
    local RA, ns, SQM

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        -- Load SQM (requires several dependencies to be stubbed)
        helpers.loadAddonFile("addon/Engine/SmartQueueManager.lua", "RotaAssist", ns)
        SQM = RA:GetModule("SmartQueueManager")
    end)

    local defaultWeights = {
        blizzardWeight = 1.0,
        aplWeight      = 0.6,
        aiWeight       = 0.4,
        cdWeight       = 0.5,
        defWeight      = 0.8
    }

    describe("Blizzard recommendation scoring", function()
        it("scores 1.0 * blizzardWeight when spell matches Blizzard rec", function()
            local context = {
                blizzSpell = 12345,
                aplPred = nil,
                cdReadyList = {},
                blindSpotCandidates = {},
                defSpell = nil,
                defUrgency = 0,
                aiPhase = "NORMAL",
                aiTip = nil,
            }
            local score, source = SQM._CalculateScore(12345, context, defaultWeights, {})
            assert.is_true(score >= 1.0)
            assert.equals("BLIZZARD", source)
        end)

        it("scores 0 for a spell that is NOT the Blizzard rec and has no other source", function()
            local context = {
                blizzSpell = 99999,
                aplPred = nil,
                cdReadyList = {},
                blindSpotCandidates = {},
                defSpell = nil,
                defUrgency = 0,
                aiPhase = "NORMAL",
                aiTip = nil,
            }
            local score, _ = SQM._CalculateScore(12345, context, defaultWeights, {})
            assert.equals(0, score)
        end)
    end)

    describe("APL tiered scoring", function()
        it("gives full APL weight to the first prediction", function()
            local aplPredictions = {
                { spellID = 11111, confidence = 0.9 },
                { spellID = 22222, confidence = 0.8 },
            }
            local context = {
                blizzSpell = nil,
                aplPred = aplPredictions[1],
                cdReadyList = {},
                blindSpotCandidates = {},
                defSpell = nil,
                defUrgency = 0,
                aiPhase = "NORMAL",
                aiTip = nil,
            }
            local score, source = SQM._CalculateScore(11111, context, defaultWeights, aplPredictions)
            -- Expected: 0.9 * 0.6 * 1.0 = 0.54
            assert.is_near(0.54, score, 0.01)
        end)

        it("gives half APL weight to the second prediction", function()
            local aplPredictions = {
                { spellID = 11111, confidence = 0.9 },
                { spellID = 22222, confidence = 0.8 },
            }
            local context = {
                blizzSpell = nil,
                cdReadyList = {},
                blindSpotCandidates = {},
                defSpell = nil,
                defUrgency = 0,
                aiPhase = "NORMAL",
                aiTip = nil,
            }
            local score, _ = SQM._CalculateScore(22222, context, defaultWeights, aplPredictions)
            -- Expected: 0.8 * 0.6 * 0.5 = 0.24
            assert.is_near(0.24, score, 0.01)
        end)
    end)

    describe("Blind-spot bonus", function()
        it("gives 1.2 bonus for a blind-spot candidate", function()
            local context = {
                blizzSpell = nil,
                cdReadyList = {},
                blindSpotCandidates = { [55555] = true },
                defSpell = nil,
                defUrgency = 0,
                aiPhase = "NORMAL",
                aiTip = nil,
            }
            local score, source = SQM._CalculateScore(55555, context, defaultWeights, {})
            assert.equals(1.2, score)
            assert.equals("APL_BLINDSPOT", source)
        end)
    end)

    describe("Defensive urgency", function()
        it("scores defensive spell with urgency * defWeight", function()
            local context = {
                blizzSpell = nil,
                cdReadyList = {},
                blindSpotCandidates = {},
                defSpell = 77777,
                defUrgency = 0.9,
                aiPhase = "NORMAL",
                aiTip = nil,
            }
            local score, source = SQM._CalculateScore(77777, context, defaultWeights, {})
            -- Expected: 0.9 * 0.8 = 0.72
            assert.is_near(0.72, score, 0.01)
            assert.equals("DEFENSIVE", source)
        end)
    end)

    describe("Combined scoring", function()
        it("accumulates Blizzard + APL scores for same spell", function()
            local aplPredictions = {
                { spellID = 12345, confidence = 0.9 },
            }
            local context = {
                blizzSpell = 12345,
                cdReadyList = {},
                blindSpotCandidates = {},
                defSpell = nil,
                defUrgency = 0,
                aiPhase = "NORMAL",
                aiTip = nil,
            }
            local score, _ = SQM._CalculateScore(12345, context, defaultWeights, aplPredictions)
            -- Blizzard: 1.0 * 1.0 = 1.0
            -- APL tier 1: 0.9 * 0.6 * 1.0 = 0.54
            -- Total: 1.54
            assert.is_near(1.54, score, 0.01)
        end)
    end)
end)
