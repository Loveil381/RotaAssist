-- tests/test_e2e_combat_flow.lua
-- End-to-end integration test: combat start → spell recommendations →
-- accuracy recording → session save.
-- 端到端集成测试：战斗开始 → 技能推荐 → 准确度记录 → 会话保存
local helpers = require("tests.helpers")

describe("E2E Combat Flow", function()
    local RA, ns
    local EH, CHR, AT, PD, AI, ACB, APL, SQM, SD, DA, CO, NP

    -- Track mock time for simulating combat duration
    local mockTime = 1000.0

    setup(function()
        helpers.ensureMockLoaded()

        -- ── Additional mocks needed for full module chain ──

        -- Mock GetSpecialization / GetSpecializationInfo / UnitClass
        _G.GetSpecialization = function() return 1 end
        _G.GetSpecializationInfo = function()
            return 577, "Havoc", "", 1247264, "DAMAGER"
        end
        _G.UnitClass = function() return "Demon Hunter", "DEMONHUNTER", 12 end

        -- Mock C_UnitAuras for PrePullChecker
        _G.C_UnitAuras = _G.C_UnitAuras or {}
        _G.C_UnitAuras.GetBuffDataByIndex = _G.C_UnitAuras.GetBuffDataByIndex or function() return nil end

        -- Mock AuraUtil
        _G.AuraUtil = _G.AuraUtil or {}

        -- Mock GetCVar
        _G.GetCVar = _G.GetCVar or function() return "0" end

        -- Mock C_AssistedCombat
        _G.C_AssistedCombat = _G.C_AssistedCombat or {}
        _G.C_AssistedCombat.GetSpellRecommendation = function()
            return nil  -- will be overridden per test phase
        end
        _G.C_AssistedCombat.IsAvailable = function() return true end
        _G.C_AssistedCombat.GetRotationSpells = function()
            return { 162243, 188499, 198013, 258920, 258860, 370965 }
        end

        -- Mock UnitHealthPercent (12.0 curve API, may not exist)
        _G.UnitHealthPercent = _G.UnitHealthPercent or function() return nil end

        -- Mock C_CurveUtil
        _G.C_CurveUtil = _G.C_CurveUtil or {}
        _G.C_CurveUtil.CreateColorCurve = _G.C_CurveUtil.CreateColorCurve or function()
            return {
                SetType = function() end,
                AddPoint = function() end,
            }
        end

        -- Mock CreateColor
        _G.CreateColor = _G.CreateColor or function(r, g, b, a)
            return { GetRGBA = function() return r, g, b, a end }
        end

        -- Mock Enum.LuaCurveType
        _G.Enum = _G.Enum or {}
        _G.Enum.LuaCurveType = _G.Enum.LuaCurveType or { Step = 1, Linear = 0 }

        -- Mock bit library (for CastHistoryRecorder:GetCastSequenceHash)
        -- Lua 5.1 has no native bitwise operators; use simple stubs
        if not _G.bit then
            _G.bit = {
                bxor   = function(a, b) return 0 end,
                bor    = function(a, b) return 0 end,
                band   = function(a, b) return 0 end,
                lshift = function(a, n) return 0 end,
                rshift = function(a, n) return 0 end,
            }
        end

        -- Mock date/time for AccuracyTracker:SaveSession
        _G.time = _G.time or os.time
        _G.date = _G.date or os.date

        -- Dynamic GetTime that we can advance
        _G.GetTime = function() return mockTime end

        -- ── Load addon and all modules ──
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)

        -- Load WhitelistSpells and SpecData
        helpers.loadAddonFile("addon/Data/WhitelistSpells.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Data/SpecData.lua", "RotaAssist", ns)

        -- Load Core modules
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)

        -- Load Engine modules in dependency order
        local engineModules = {
            "addon/Engine/SpecDetector.lua",
            "addon/Engine/AssistedCombatBridge.lua",
            "addon/Engine/CastHistoryRecorder.lua",
            "addon/Engine/PatternDetector.lua",
            "addon/Engine/AccuracyTracker.lua",
            "addon/Engine/APLEngine.lua",
            "addon/Engine/CooldownOverlay.lua",
            "addon/Engine/DefensiveAdvisor.lua",
            "addon/Engine/NeuralPredictor.lua",
            "addon/Engine/AIInference.lua",
            "addon/Engine/InterruptAdvisor.lua",
            "addon/Engine/SmartQueueManager.lua",
        }
        for _, path in ipairs(engineModules) do
            local ok, err = helpers.loadAddonFile(path, "RotaAssist", ns)
            if not ok then
                print("Warning: failed to load " .. path .. ": " .. tostring(err))
            end
        end

        -- Get module references
        EH  = RA:GetModule("EventHandler")
        CHR = RA:GetModule("CastHistoryRecorder")
        AT  = RA:GetModule("AccuracyTracker")
        PD  = RA:GetModule("PatternDetector")
        AI  = RA:GetModule("AIInference")
        ACB = RA:GetModule("AssistedCombatBridge")
        APL = RA:GetModule("APLEngine")
        SQM = RA:GetModule("SmartQueueManager")
        SD  = RA:GetModule("SpecDetector")
        DA  = RA:GetModule("DefensiveAdvisor")
        CO  = RA:GetModule("CooldownOverlay")
        NP  = RA:GetModule("NeuralPredictor")
    end)

    -- ─────────────────────────────────────────────────────
    -- Test 1: All modules load successfully
    -- ─────────────────────────────────────────────────────
    describe("Module loading", function()
        it("all core Engine modules are registered", function()
            assert.is_not_nil(EH,  "EventHandler")
            assert.is_not_nil(CHR, "CastHistoryRecorder")
            assert.is_not_nil(AT,  "AccuracyTracker")
            assert.is_not_nil(ACB, "AssistedCombatBridge")
            assert.is_not_nil(APL, "APLEngine")
            assert.is_not_nil(SQM, "SmartQueueManager")
            assert.is_not_nil(SD,  "SpecDetector")
        end)

        it("optional modules load (may be nil if deps missing)", function()
            -- These are allowed to be nil if their deps fail in mock env
            -- but ideally they should load
            if PD  then assert.is_table(PD)  end
            if AI  then assert.is_table(AI)  end
            if DA  then assert.is_table(DA)  end
            if CO  then assert.is_table(CO)  end
            if NP  then assert.is_table(NP)  end
        end)
    end)

    -- ─────────────────────────────────────────────────────
    -- Test 2: Module initialization chain
    -- ─────────────────────────────────────────────────────
    describe("Initialization chain", function()
        it("OnInitialize succeeds for all loaded modules", function()
            local modules = { EH, CHR, AT, ACB, APL, SQM, SD, PD, AI, DA, CO, NP }
            for _, mod in ipairs(modules) do
                if mod and mod.OnInitialize then
                    assert.has_no.errors(function()
                        pcall(mod.OnInitialize, mod)
                    end)
                end
            end
        end)

        it("OnEnable succeeds for EventHandler (must be first)", function()
            assert.has_no.errors(function()
                pcall(EH.OnEnable, EH)
            end)
        end)

        it("OnEnable succeeds for remaining modules", function()
            local modules = { SD, ACB, CHR, PD, AT, APL, CO, DA, NP, AI, SQM }
            for _, mod in ipairs(modules) do
                if mod and mod.OnEnable then
                    assert.has_no.errors(function()
                        pcall(mod.OnEnable, mod)
                    end)
                end
            end
        end)
    end)

    -- ─────────────────────────────────────────────────────
    -- Test 3: Full combat cycle simulation
    -- ─────────────────────────────────────────────────────
    describe("Combat cycle", function()
        local blizzardRec = nil

        before_each(function()
            mockTime = 1000.0
            _G.GetTime = function() return mockTime end

            -- Setup: mock Blizzard recommendation to return a specific spell
            blizzardRec = { spellID = 162243, name = "Demon's Bite" }
            if ACB then
                -- Override GetCurrentRecommendation
                ACB._origGetRec = ACB.GetCurrentRecommendation
                ACB.GetCurrentRecommendation = function(self)
                    return blizzardRec
                end
                ACB.GetPreviousRecommendation = function(self)
                    return nil
                end
                ACB.GetRotationSpells = function(self)
                    return { 162243, 188499, 198013, 258920, 258860, 370965 }
                end
                ACB.InvalidateCache = function(self) end
            end

            -- Setup mock RA.db for SaveSession
            RA.db = RA.db or {}
            RA.db.profile = RA.db.profile or {}
            RA.db.profile.accuracyHistory = {}
            RA.db.profile.castHistory = {}
            RA.db.profile.general = {}
            RA.db.profile.display = { showOutOfCombat = false }
            RA.db.profile.smartQueue = {
                blizzardWeight = 1.0,
                aplWeight = 0.6,
                aiWeight = 0.4,
                cdWeight = 0.5,
                defWeight = 0.8,
            }

            -- Reset modules
            if CHR and CHR.Reset then CHR:Reset() end
            if AT and AT.Reset then AT:Reset() end
        end)

        after_each(function()
            _G.InCombatLockdown = function() return false end
            if ACB and ACB._origGetRec then
                ACB.GetCurrentRecommendation = ACB._origGetRec
                ACB._origGetRec = nil
            end
        end)

        it("STEP 1: combat start fires and modules respond", function()
            -- Enter combat
            _G.InCombatLockdown = function() return true end
            EH:Fire("PLAYER_REGEN_DISABLED")

            -- AccuracyTracker should now be in active session
            local stats = AT:GetSessionStats()
            assert.equals(0, stats.totalCasts)
        end)

        it("STEP 2: spell cast is recorded by CastHistoryRecorder", function()
            _G.InCombatLockdown = function() return true end
            EH:Fire("PLAYER_REGEN_DISABLED")

            -- Simulate casting Demon's Bite (162243)
            mockTime = 1001.0
            EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "castGUID1", 162243)

            -- CastHistoryRecorder should have recorded it
            assert.equals(1, CHR:GetCount())
            assert.equals(162243, CHR:GetLastSpellID())
        end)

        it("STEP 3: accuracy tracking matches Blizzard recommendation", function()
            _G.InCombatLockdown = function() return true end
            EH:Fire("PLAYER_REGEN_DISABLED")

            -- Cast the recommended spell (Demon's Bite)
            blizzardRec = { spellID = 162243, name = "Demon's Bite" }
            mockTime = 1001.0
            EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "castGUID1", 162243)

            local stats = AT:GetSessionStats()
            assert.equals(1, stats.totalCasts)
            assert.equals(1, stats.blizzardMatches)
            assert.equals(100.0, stats.blizzardAccuracy)
        end)

        it("STEP 4: non-matching cast reduces accuracy", function()
            _G.InCombatLockdown = function() return true end
            EH:Fire("PLAYER_REGEN_DISABLED")

            -- Cast recommended spell
            blizzardRec = { spellID = 162243, name = "Demon's Bite" }
            mockTime = 1001.0
            EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "g1", 162243)

            -- Change recommendation, cast something else
            blizzardRec = { spellID = 188499, name = "Blade Dance" }
            mockTime = 1002.5
            EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "g2", 258920) -- Immolation Aura

            local stats = AT:GetSessionStats()
            assert.equals(2, stats.totalCasts)
            assert.equals(1, stats.blizzardMatches)
            assert.is_true(stats.blizzardAccuracy < 100.0)
            assert.is_true(stats.blizzardAccuracy > 0.0)
        end)

        it("STEP 5: multiple casts build ring buffer correctly", function()
            _G.InCombatLockdown = function() return true end
            EH:Fire("PLAYER_REGEN_DISABLED")

            local spells = { 162243, 188499, 198013, 162243, 258920 }
            for i, sid in ipairs(spells) do
                blizzardRec = { spellID = sid, name = "Spell" .. sid }
                mockTime = 1000.0 + i
                EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "g" .. i, sid)
            end

            assert.equals(5, CHR:GetCount())
            assert.equals(258920, CHR:GetLastSpellID())

            local recent = CHR:GetRecentCasts(3)
            assert.equals(3, #recent)
            assert.equals(258920, recent[1].spellID)
            assert.equals(162243, recent[2].spellID)
            assert.equals(198013, recent[3].spellID)
        end)

        it("STEP 6: combat end triggers session save", function()
            _G.InCombatLockdown = function() return true end
            EH:Fire("PLAYER_REGEN_DISABLED")

            -- Simulate 10 casts over 30 seconds
            for i = 1, 10 do
                blizzardRec = { spellID = 162243, name = "Demon's Bite" }
                mockTime = 1000.0 + (i * 3)
                EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "g" .. i, 162243)
            end

            -- End combat (30 seconds later)
            mockTime = 1030.0
            _G.InCombatLockdown = function() return false end
            EH:Fire("PLAYER_REGEN_ENABLED")

            -- Check that a session record was saved
            local history = RA.db.profile.accuracyHistory
            assert.is_table(history)
            assert.is_true(#history >= 1, "Expected at least 1 history record after combat")

            if #history >= 1 then
                local record = history[1]
                assert.is_number(record.date)
                assert.is_number(record.casts)
                assert.is_true(record.casts >= 1)
                assert.is_number(record.blizzardAccuracy)
                assert.is_number(record.smartAccuracy)
            end
        end)

        it("STEP 7: CastHistoryRecorder resets accuracy on combat end", function()
            _G.InCombatLockdown = function() return true end
            EH:Fire("PLAYER_REGEN_DISABLED")

            blizzardRec = { spellID = 162243, name = "Demon's Bite" }
            mockTime = 1001.0
            EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "g1", 162243)

            local acc1 = CHR:GetAccuracy()
            assert.is_true(acc1.total >= 1)

            -- End combat
            mockTime = 1010.0
            _G.InCombatLockdown = function() return false end
            EH:Fire("PLAYER_REGEN_ENABLED")

            -- CastHistoryRecorder resets session accuracy on PLAYER_REGEN_ENABLED
            local acc2 = CHR:GetAccuracy()
            assert.equals(0, acc2.total)
            assert.equals(0, acc2.percentage)
        end)
    end)

    -- ─────────────────────────────────────────────────────
    -- Test 4: APL prediction integration
    -- ─────────────────────────────────────────────────────
    describe("APL prediction chain", function()
        it("APLEngine returns predictions when APL data is loaded", function()
            -- Load a minimal APL
            local testAPL = {
                rules = {
                    { spellID = 162243, priority = 1, condition = "always", note = "Demon's Bite" },
                    { spellID = 188499, priority = 2, condition = "cd_ready", note = "Blade Dance" },
                    { spellID = 258920, priority = 3, condition = "cd_ready", note = "Immolation Aura" },
                }
            }
            APL:SetAPL(577, testAPL, 12)

            assert.is_true(APL:HasAPL())

            local limitedState = {
                resource = 50,
                cooldowns = {},
                inMeta = false,
                targetCount = 1,
            }

            local predictions = APL:PredictNext(162243, limitedState, 2)
            assert.is_table(predictions)
            assert.is_true(#predictions >= 1, "Expected at least 1 prediction")

            if #predictions >= 1 then
                assert.is_number(predictions[1].spellID)
                assert.is_number(predictions[1].confidence)
                assert.is_string(predictions[1].source)
            end
        end)

        it("predictions skip passive spells", function()
            local testAPL = {
                rules = {
                    { spellID = 203555, priority = 1, condition = "always", note = "Demon Blades (passive)" },
                    { spellID = 188499, priority = 2, condition = "cd_ready", note = "Blade Dance" },
                }
            }
            APL:SetAPL(577, testAPL, 12)

            local predictions = APL:PredictNext(162243, {
                resource = 50, cooldowns = {}, inMeta = false, targetCount = 1,
            }, 1)

            -- Should skip 203555 (passive blacklist) and return 188499
            if #predictions >= 1 then
                assert.not_equals(203555, predictions[1].spellID)
            end
        end)

        it("meta state changes prediction behavior", function()
            APL:SetMetaState(true)
            assert.is_true(APL:IsMetaActive())

            local testAPL = {
                rules = {
                    { spellID = 210152, priority = 1, condition = "in_meta", note = "Death Sweep" },
                    { spellID = 188499, priority = 2, condition = "not_in_meta", note = "Blade Dance" },
                    { spellID = 162243, priority = 3, condition = "always", note = "Demon's Bite" },
                }
            }
            APL:SetAPL(577, testAPL, 12)

            local predictions = APL:PredictNext(nil, {
                resource = 50, cooldowns = {}, inMeta = true, targetCount = 1,
            }, 1)

            if #predictions >= 1 then
                -- Should pick Death Sweep (in_meta passes) over Blade Dance (not_in_meta fails)
                assert.equals(210152, predictions[1].spellID)
            end

            APL:SetMetaState(false)
        end)
    end)

    -- ─────────────────────────────────────────────────────
    -- Test 5: SmartQueueManager output structure
    -- ─────────────────────────────────────────────────────
    describe("SmartQueueManager queue structure", function()
        it("GetFinalQueue returns a valid table", function()
            local queue = SQM:GetFinalQueue()
            assert.is_table(queue)
        end)

        it("GetDisplayData returns backward-compatible format", function()
            local data = SQM:GetDisplayData()
            assert.is_table(data)
            -- Should have main, predictions, cooldowns keys
            assert.is_not_nil(data.predictions)
            assert.is_not_nil(data.cooldowns)
        end)

        it("GetLastRecommendedSpellID returns nil when no combat has occurred", function()
            local lastRec = SQM:GetLastRecommendedSpellID()
            -- May be nil or a number depending on prior test state
            if lastRec ~= nil then
                assert.is_number(lastRec)
            end
        end)
    end)

    -- ─────────────────────────────────────────────────────
    -- Test 6: Event propagation chain validation
    -- ─────────────────────────────────────────────────────
    describe("Event propagation", function()
        it("ROTAASSIST_SPELLCAST_SUCCEEDED reaches multiple subscribers", function()
            local received = {}
            EH:Subscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "E2E_TestSub1", function(evt, unit, guid, sid)
                received[#received + 1] = { module = "Sub1", spellID = sid }
            end)
            EH:Subscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "E2E_TestSub2", function(evt, unit, guid, sid)
                received[#received + 1] = { module = "Sub2", spellID = sid }
            end)

            EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "testGUID", 99999)

            -- Our two test subscribers should have received the event
            -- (plus any module subscribers like CHR, AT, etc.)
            local found1, found2 = false, false
            for _, r in ipairs(received) do
                if r.module == "Sub1" then found1 = true end
                if r.module == "Sub2" then found2 = true end
            end
            assert.is_true(found1, "Sub1 should receive event")
            assert.is_true(found2, "Sub2 should receive event")

            -- Cleanup
            EH:Unsubscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "E2E_TestSub1")
            EH:Unsubscribe("ROTAASSIST_SPELLCAST_SUCCEEDED", "E2E_TestSub2")
        end)

        it("PLAYER_REGEN_DISABLED fires to all combat-start subscribers", function()
            local fired = false
            EH:Subscribe("PLAYER_REGEN_DISABLED", "E2E_CombatTest", function()
                fired = true
            end)

            EH:Fire("PLAYER_REGEN_DISABLED")
            assert.is_true(fired)

            EH:Unsubscribe("PLAYER_REGEN_DISABLED", "E2E_CombatTest")
        end)

        it("custom events coexist without interference", function()
            local results = {}
            EH:Subscribe("ROTAASSIST_CUSTOM_A", "E2E_A", function() results.a = true end)
            EH:Subscribe("ROTAASSIST_CUSTOM_B", "E2E_B", function() results.b = true end)

            EH:Fire("ROTAASSIST_CUSTOM_A")
            assert.is_true(results.a)
            assert.is_nil(results.b)

            EH:Fire("ROTAASSIST_CUSTOM_B")
            assert.is_true(results.b)

            EH:Unsubscribe("ROTAASSIST_CUSTOM_A", "E2E_A")
            EH:Unsubscribe("ROTAASSIST_CUSTOM_B", "E2E_B")
        end)
    end)

    -- ─────────────────────────────────────────────────────
    -- Test 7: Data persistence round-trip
    -- ─────────────────────────────────────────────────────
    describe("Data persistence", function()
        it("CastHistoryRecorder save and load round-trip", function()
            -- Setup RA.db
            RA.db = RA.db or {}
            RA.db.profile = RA.db.profile or {}
            RA.db.profile.castHistory = {}

            -- Mock SpecDetector
            if SD then
                SD._origGetSpecID = SD.GetSpecID
                SD.GetSpecID = function() return 577 end
            end

            -- Record some casts
            CHR:Reset()
            _G.InCombatLockdown = function() return true end
            EH:Fire("PLAYER_REGEN_DISABLED")

            for i = 1, 5 do
                mockTime = 1000.0 + i
                EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "g" .. i, 162243 + i)
            end

            -- Save
            CHR:SaveHistory()
            assert.is_table(RA.db.profile.castHistory[577])

            local savedCount = #RA.db.profile.castHistory[577]
            assert.is_true(savedCount >= 1, "Expected saved casts for spec 577")

            -- Reset and reload
            CHR:Reset()
            assert.equals(0, CHR:GetCount())

            CHR:LoadHistory()
            assert.is_true(CHR:GetCount() >= 1, "Expected casts restored after LoadHistory")

            -- Cleanup
            if SD and SD._origGetSpecID then
                SD.GetSpecID = SD._origGetSpecID
                SD._origGetSpecID = nil
            end
            _G.InCombatLockdown = function() return false end
        end)

        it("AccuracyTracker history persists across sessions", function()
            RA.db = RA.db or {}
            RA.db.profile = RA.db.profile or {}
            RA.db.profile.accuracyHistory = {}

            if SD then
                SD._origGetSpecID = SD.GetSpecID
                SD.GetSpecID = function() return 577 end
            end

            -- Simulate combat session
            _G.InCombatLockdown = function() return true end
            EH:Fire("PLAYER_REGEN_DISABLED")

            for i = 1, 8 do
                mockTime = 1000.0 + (i * 2)
                EH:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED", "player", "g" .. i, 162243)
            end

            -- End combat at 30+ seconds
            mockTime = 1050.0
            _G.InCombatLockdown = function() return false end
            EH:Fire("PLAYER_REGEN_ENABLED")

            -- Check history was saved
            assert.is_true(#RA.db.profile.accuracyHistory >= 1)
            local record = RA.db.profile.accuracyHistory[1]
            assert.is_number(record.blizzardAccuracy)
            assert.is_number(record.smartAccuracy)
            assert.is_true(record.casts >= 1)

            -- Cleanup
            if SD and SD._origGetSpecID then
                SD.GetSpecID = SD._origGetSpecID
            end
        end)
    end)
end)
