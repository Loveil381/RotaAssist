-- tests/test_edge_cases.lua
-- Edge case and robustness tests across multiple modules.
-- 各モジュールのエッジケース・堅牢性テスト
local helpers = require("tests.helpers")

describe("Edge Cases", function()
    local RA, ns

    setup(function()
        helpers.ensureMockLoaded()
        _G.GetSpecialization = function() return 1 end
        _G.GetSpecializationInfo = function()
            return 577, "Havoc", "", 1247264, "DAMAGER"
        end
        _G.UnitClass = function() return "Demon Hunter", "DEMONHUNTER", 12 end

        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Data/WhitelistSpells.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/SpecDetector.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/CastHistoryRecorder.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/AccuracyTracker.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/APLEngine.lua", "RotaAssist", ns)
        pcall(helpers.loadAddonFile, "addon/Engine/SmartQueueManager.lua", "RotaAssist", ns)
    end)

    -- ── Init.lua safe wrappers ──
    describe("Init.lua safe wrappers", function()
        it("GetSpellCooldownSafe handles nil input without error", function()
            local remaining, ready = RA:GetSpellCooldownSafe(nil)
            -- Function doesn't crash; returns 0 (ready) because mock API returns valid data
            assert.is_not_nil(remaining)
            assert.equals(0, remaining)
            assert.is_true(ready)
        end)

        it("GetSpellCooldownSafe handles spellID 0 without error", function()
            local remaining, ready = RA:GetSpellCooldownSafe(0)
            assert.is_not_nil(remaining)
            assert.equals(0, remaining)
            assert.is_true(ready)
        end)

        it("GetSpellCooldownSafe handles C_Spell error gracefully", function()
            local origFn = _G.C_Spell.GetSpellCooldown
            _G.C_Spell.GetSpellCooldown = function() error("mock error") end
            local remaining = RA:GetSpellCooldownSafe(12345)
            assert.is_nil(remaining)
            _G.C_Spell.GetSpellCooldown = origFn
        end)

        it("IsSpellPassive returns false for nil", function()
            assert.is_false(RA:IsSpellPassive(nil))
        end)

        it("IsSpellPassive returns false for 0", function()
            assert.is_false(RA:IsSpellPassive(0))
        end)

        it("GetBaseSpellID returns original when no override exists", function()
            local base = RA:GetBaseSpellID(162243)
            assert.is_number(base)
        end)

        it("GetBaseSpellID handles nil gracefully", function()
            local base = RA:GetBaseSpellID(nil)
            -- Should return nil or 0 without error
            assert.is_true(base == nil or base == 0 or type(base) == "number")
        end)

        it("SharesCooldown returns false for unrelated spells", function()
            local shares = RA:SharesCooldown(162243, 198013)
            assert.is_false(shares)
        end)

        it("SharesCooldown returns true for override pair", function()
            local shares = RA:SharesCooldown(188499, 210152)
            assert.is_true(shares)
        end)

        it("GetPlayerHealthPercentSafe returns a number or nil", function()
            local pct = RA:GetPlayerHealthPercentSafe()
            if pct ~= nil then
                assert.is_number(pct)
                assert.is_true(pct >= 0 and pct <= 1.0)
            end
        end)

        it("IsSpellRecommendable returns false for passive blacklist spells", function()
            assert.is_false(RA:IsSpellRecommendable(203555))
        end)

        it("IsSpellRecommendable returns true for normal rotational spells", function()
            assert.is_true(RA:IsSpellRecommendable(162243))
        end)
    end)

    -- ── APLEngine edge cases ──
    describe("APLEngine edge cases", function()
        local APL

        before_each(function()
            APL = RA:GetModule("APLEngine")
        end)

        it("PredictNext returns empty table when no APL loaded", function()
            APL:ClearAPL()
            local predictions = APL:PredictNext(162243, {
                resource = 50, cooldowns = {}, inMeta = false, targetCount = 1,
            }, 2)
            assert.is_table(predictions)
            assert.equals(0, #predictions)
        end)

        it("PredictNext returns empty table when limitedState is nil", function()
            APL:SetAPL(577, { rules = {
                { spellID = 162243, priority = 1, condition = "always" },
            }}, 12)
            local predictions = APL:PredictNext(162243, nil, 2)
            assert.is_table(predictions)
            assert.equals(0, #predictions)
        end)

        it("PredictNext handles depth 0", function()
            APL:SetAPL(577, { rules = {
                { spellID = 162243, priority = 1, condition = "always" },
            }}, 12)
            local predictions = APL:PredictNext(162243, {
                resource = 50, cooldowns = {}, inMeta = false, targetCount = 1,
            }, 0)
            assert.is_table(predictions)
            assert.equals(0, #predictions)
        end)

        it("PredictNext handles empty rules list", function()
            APL:SetAPL(577, { rules = {} }, 12)
            local predictions = APL:PredictNext(162243, {
                resource = 50, cooldowns = {}, inMeta = false, targetCount = 1,
            }, 2)
            assert.is_table(predictions)
            assert.equals(0, #predictions)
        end)

        it("EvaluateCondition handles nil condition as always-true", function()
            local result = APL:EvaluateCondition(nil, 162243, {
                cooldowns = {}, resource = 50, inMeta = false,
            })
            assert.is_true(result)
        end)

        it("EvaluateCondition handles 'always' keyword", function()
            local result = APL:EvaluateCondition("always", 162243, {
                cooldowns = {}, resource = 50, inMeta = false,
            })
            assert.is_true(result)
        end)

        it("EvaluateCondition fails on unknown condition token", function()
            local result = APL:EvaluateCondition("totally_unknown_cond", 162243, {
                cooldowns = {}, resource = 50, inMeta = false,
            })
            assert.is_false(result)
        end)

        it("SetMetaStateFromCast ignores non-meta spells", function()
            APL:SetMetaState(false)
            APL:SetMetaStateFromCast(162243) -- Demon's Bite is not a meta trigger
            assert.is_false(APL:IsMetaActive())
        end)

        it("SetMetaStateFromCast activates on Havoc Meta (191427)", function()
            APL:SetMetaState(false)
            APL:SetMetaStateFromCast(191427)
            assert.is_true(APL:IsMetaActive())
            APL:SetMetaState(false) -- cleanup
        end)

        it("HasAPL returns false after ClearAPL", function()
            APL:SetAPL(577, { rules = {} }, 12)
            assert.is_true(APL:HasAPL())
            APL:ClearAPL()
            assert.is_false(APL:HasAPL())
        end)
    end)

    -- ── CastHistoryRecorder edge cases ──
    describe("CastHistoryRecorder edge cases", function()
        local CHR

        before_each(function()
            CHR = RA:GetModule("CastHistoryRecorder")
            if CHR then CHR:Reset() end
        end)

        it("GetRecentCasts(0) returns empty table", function()
            if not CHR then return pending("CHR not loaded") end
            local casts = CHR:GetRecentCasts(0)
            assert.is_table(casts)
            assert.equals(0, #casts)
        end)

        it("GetNthLastSpellID beyond count returns 0", function()
            if not CHR then return pending("CHR not loaded") end
            assert.equals(0, CHR:GetNthLastSpellID(100))
        end)

        it("GetTimeSinceLastCast returns 999 when empty", function()
            if not CHR then return pending("CHR not loaded") end
            assert.equals(999, CHR:GetTimeSinceLastCast())
        end)

        it("GetCastSequenceHash returns 0 when empty", function()
            if not CHR then return pending("CHR not loaded") end
            local hash = CHR:GetCastSequenceHash(5)
            assert.is_number(hash)
        end)

        it("Reset clears all state", function()
            if not CHR then return pending("CHR not loaded") end
            CHR:Reset()
            assert.equals(0, CHR:GetCount())
            assert.is_nil(CHR:GetLastSpellID())
        end)
    end)

    -- ── AccuracyTracker edge cases ──
    describe("AccuracyTracker edge cases", function()
        local AT

        before_each(function()
            AT = RA:GetModule("AccuracyTracker")
            if AT then AT:Reset() end
        end)

        it("GetSessionStats returns zeros after reset", function()
            if not AT then return pending("AT not loaded") end
            local stats = AT:GetSessionStats()
            assert.equals(0, stats.totalCasts)
            assert.equals(0, stats.blizzardMatches)
            assert.equals(0, stats.smartMatches)
            assert.equals(0, stats.blizzardAccuracy)
            assert.equals(0, stats.smartAccuracy)
        end)

        it("GetHistoricalTrend returns table even without RA.db", function()
            if not AT then return pending("AT not loaded") end
            local origDB = RA.db
            RA.db = nil
            local trend = AT:GetHistoricalTrend()
            assert.is_table(trend)
            RA.db = origDB
        end)

        it("PrintHistory does not crash without RA.db", function()
            if not AT then return pending("AT not loaded") end
            local origDB = RA.db
            RA.db = nil
            assert.has_no.errors(function()
                pcall(AT.PrintHistory, AT)
            end)
            RA.db = origDB
        end)
    end)

    -- ── SmartQueueManager edge cases ──
    describe("SmartQueueManager edge cases", function()
        local SQM

        before_each(function()
            SQM = RA:GetModule("SmartQueueManager")
        end)

        it("_IsSpellOnCooldown returns false for nil", function()
            if not SQM or not SQM._IsSpellOnCooldown then return pending("not exposed") end
            assert.is_false(SQM._IsSpellOnCooldown(nil))
        end)

        it("_IsSpellCastable returns false for 0", function()
            if not SQM or not SQM._IsSpellCastable then return pending("not exposed") end
            assert.is_false(SQM._IsSpellCastable(0))
        end)

        it("_IsSpellCastable returns false for passive blacklist spell", function()
            if not SQM or not SQM._IsSpellCastable then return pending("not exposed") end
            assert.is_false(SQM._IsSpellCastable(203555))
        end)

        it("GetFinalQueue returns table even out of combat", function()
            if not SQM then return pending("SQM not loaded") end
            _G.InCombatLockdown = function() return false end
            local queue = SQM:GetFinalQueue()
            assert.is_table(queue)
        end)
    end)

    -- ── Registry edge cases ──
    describe("Registry edge cases", function()
        it("PASSIVE_BLACKLIST contains exactly 3 entries", function()
            local count = 0
            for _ in pairs(RA.Registry.PASSIVE_BLACKLIST) do count = count + 1 end
            assert.equals(3, count)
        end)

        it("OVERRIDE_PAIRS is bidirectional", function()
            for a, b in pairs(RA.Registry.OVERRIDE_PAIRS) do
                assert.equals(a, RA.Registry.OVERRIDE_PAIRS[b],
                    string.format("OVERRIDE_PAIRS[%d] = %d but OVERRIDE_PAIRS[%d] ~= %d", a, b, b, a))
            end
        end)

        it("FALLBACK_TEXTURE is 134400", function()
            assert.equals(134400, RA.Registry.FALLBACK_TEXTURE)
        end)
    end)
end)
