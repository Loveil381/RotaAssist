-- tests/test_cd_filter.lua
-- Round 14 CD Filter Hotfix — Regression Tests (P0 Product Bug Fix)
-- 浩劫 DH 技能进入冷却后仍被推荐的回归测试
-- Regression tests covering the three CD-filter bugs fixed in Round 14.
local helpers = require("tests.helpers")

describe("CD Filter regression (Round 14)", function()
    local RA, ns, SQM, APL

    -- ============================================================
    -- 公共测试 setup: 加载 mock、初始化 RA/NS、注册 SQM 和 APLEngine
    -- Common setup: load mock env, initialise RA/NS, register modules.
    -- ============================================================
    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Engine/APLEngine.lua",        "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/SmartQueueManager.lua","RotaAssist", ns)
        SQM = RA:GetModule("SmartQueueManager")
        APL = RA:GetModule("APLEngine")
    end)

    -- ============================================================
    -- Test 1 — Commit 1 fix (Round14-Bug1)
    -- Sticky fallback must be cleared when the cached spell is on CD.
    -- Sticky fallback 在技能进入 CD 后必须被清除。
    -- ============================================================
    it("sticky fallback clears when spell is on cooldown", function()
        assert.is_not_nil(SQM, "SmartQueueManager must be loaded")

        local CD_SPELL_ID = 162243  -- arbitrary test spell

        -- Mock CooldownOverlay returning the spell as on-CD
        -- 模拟 CooldownOverlay 返回该技能处于 CD 中
        local fakeCooldownOverlay = {
            GetCooldownStates = function(self)
                return {
                    [CD_SPELL_ID] = { ready = false, remaining = 5.0, duration = 10 }
                }
            end
        }
        RA.modules = RA.modules or {}
        local origGetModule = RA.GetModule
        RA.GetModule = function(self, name)
            if name == "CooldownOverlay" then return fakeCooldownOverlay end
            return origGetModule(self, name)
        end

        -- IsSpellOnCooldown should now return true for this spell
        -- 验证 IsSpellOnCooldown 对该技能返回 true
        local onCD = SQM._IsSpellOnCooldown(CD_SPELL_ID)
        assert.is_true(onCD, "IsSpellOnCooldown should return true for a tracked spell with remaining=5.0")

        -- With the Commit 1 fix, IsSpellCastable must return false (blocks through sticky)
        -- 修复后 IsSpellCastable 应该返回 false，技能不可施放
        local castable = SQM._IsSpellCastable(CD_SPELL_ID)
        assert.is_false(castable, "IsSpellCastable must be false when spell is on cooldown")

        -- Restore original GetModule
        RA.GetModule = origGetModule
    end)

    -- ============================================================
    -- Test 2 — Commit 2 fix (Round14-Bug2)
    -- Safety net filters untracked spells via API fallback.
    -- 安全网通过 API fallback 过滤未追踪技能。
    -- ============================================================
    it("safety net filters untracked spell via API fallback", function()
        assert.is_not_nil(SQM, "SmartQueueManager must be loaded")

        local UNTRACKED_SPELL_ID = 77777  -- not in CooldownOverlay table

        -- CooldownOverlay returns an EMPTY states table (untracked spell)
        -- CooldownOverlay 返回空表（未追踪技能）
        local fakeEmpty = {
            GetCooldownStates = function(self) return {} end
        }
        local origGetModule = RA.GetModule
        RA.GetModule = function(self, name)
            if name == "CooldownOverlay" then return fakeEmpty end
            return origGetModule(self, name)
        end

        -- Mock RA:GetSpellCooldownSafe to return remaining = 8.0 for this spell
        -- 模拟 GetSpellCooldownSafe 为该技能返回 remaining = 8.0
        local origGetCooldown = RA.GetSpellCooldownSafe
        RA.GetSpellCooldownSafe = function(self, id)
            if id == UNTRACKED_SPELL_ID then return 8.0 end
            return 0
        end

        -- With Commit 2 fix: API fallback kicks in → spell is on CD
        -- 修复后：API fallback 生效，技能被识别为 CD 中
        local onCD = SQM._IsSpellOnCooldown(UNTRACKED_SPELL_ID)
        assert.is_true(onCD, "Untracked spell with API remaining=8.0 should be detected as on CD")

        local castable = SQM._IsSpellCastable(UNTRACKED_SPELL_ID)
        assert.is_false(castable, "Untracked spell on CD must not be castable")

        -- Restore mocks
        RA.GetModule = origGetModule
        RA.GetSpellCooldownSafe = origGetCooldown
    end)

    -- ============================================================
    -- Test 3 — Commit 3 fix (Round14-Bug3): step 2 skips when BOTH real CD and sim CD > 0
    -- APL step 2 跳过技能：真实 CD 和 sim CD 均大于 0
    -- ============================================================
    it("APL step 2 skips spell when both real CD and sim CD > 0", function()
        assert.is_not_nil(APL, "APLEngine must be loaded")

        local SPELL_ON_CD   = 188499   -- Fel Rush (Havoc) — used as test subject
        local SAFE_SPELL_ID = 162243   -- a filler builder

        -- Set up a minimal APL with two rules: SPELL_ON_CD (high priority), SAFE_SPELL_ID
        -- 建立最小 APL：两条规则，SPELL_ON_CD 优先级更高
        APL:SetAPL(577, {
            profiles = {
                default = {
                    singleTarget = {
                        { spellID = SPELL_ON_CD, condition = "always", priority = 1  },
                        { spellID = SAFE_SPELL_ID, condition = "always", priority = 10 },
                    }
                }
            }
        }, 12)

        -- Mock CooldownOverlay: SPELL_ON_CD has real remaining=5.0
        -- 模拟 CooldownOverlay：SPELL_ON_CD 的真实 CD remaining=5.0
        local fakeCO = {
            GetCooldownStates = function(self)
                return {
                    [SPELL_ON_CD] = { ready = false, remaining = 5.0, duration = 10 }
                }
            end
        }
        local origGetModule = RA.GetModule
        RA.GetModule = function(self, name)
            if name == "CooldownOverlay" then return fakeCO end
            return origGetModule(self, name)
        end

        local simState = {
            resource    = 80,
            cooldowns   = { [SPELL_ON_CD] = 9.0 },  -- sim also sees CD > 0
            inMeta      = false,
            targetCount = 1,
        }

        -- Predict 2 steps; step 2 should NOT include SPELL_ON_CD
        -- 预测 2 步，第 2 步不应包含 SPELL_ON_CD
        local preds = APL:PredictNext(SPELL_ON_CD, simState, 2)

        local foundOnCD = false
        for _, p in ipairs(preds) do
            if p.spellID == SPELL_ON_CD then
                foundOnCD = true
            end
        end

        assert.is_false(foundOnCD,
            "PredictNext step 2+ must not include a spell whose real AND sim CD > 0")

        RA.GetModule = origGetModule
    end)

    -- ============================================================
    -- Test 4 — Commit 3 fix safeguard: step 2 ALLOWS spell when sim CD is 0
    -- APL step 2 允许技能：尽管实时 CD > 0，但 sim CD = 0（信任模拟）
    -- ============================================================
    it("APL step 2 allows spell when sim CD is 0 despite real CD", function()
        assert.is_not_nil(APL, "APLEngine must be loaded")

        local SPELL_ID    = 188499   -- Fel Rush
        local FILLER_ID   = 162243   -- safe filler

        -- (Re)set APL so SPELL_ID is high-priority filler
        APL:SetAPL(577, {
            profiles = {
                default = {
                    singleTarget = {
                        { spellID = SPELL_ID,  condition = "always", priority = 1  },
                        { spellID = FILLER_ID, condition = "always", priority = 10 },
                    }
                }
            }
        }, 12)

        -- Real CD: 3.0s remaining on SPELL_ID
        -- 真实 CD：SPELL_ID remaining=3.0
        local fakeCO = {
            GetCooldownStates = function(self)
                return {
                    [SPELL_ID] = { ready = false, remaining = 3.0, duration = 10 }
                }
            end
        }
        local origGetModule = RA.GetModule
        RA.GetModule = function(self, name)
            if name == "CooldownOverlay" then return fakeCO end
            return origGetModule(self, name)
        end

        -- Sim state: cooldowns[SPELL_ID] = 0 (simulation believes spell is ready at step 2)
        -- 模拟状态：simState 认为 SPELL_ID CD = 0（模拟信任该技能在第 2 步已就绪）
        local simState = {
            resource    = 80,
            cooldowns   = { [SPELL_ID] = 0 },  -- sim says ready
            inMeta      = false,
            targetCount = 1,
        }

        -- Predict 2 steps; step 2 SHOULD include SPELL_ID (sim trusts it's ready)
        -- 预测 2 步；第 2 步应包含 SPELL_ID（sim 认为其已就绪）
        local preds = APL:PredictNext(nil, simState, 2)

        local foundSpell = false
        for _, p in ipairs(preds) do
            if p.spellID == SPELL_ID then
                foundSpell = true
            end
        end

        assert.is_true(foundSpell,
            "PredictNext step 2 should include spell when sim CD=0 even if real CD > 0 (trust simulation)")

        RA.GetModule = origGetModule
    end)
end)
