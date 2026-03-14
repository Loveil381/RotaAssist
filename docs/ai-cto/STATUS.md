# RotaAssist — CTO AI 进度状态
> 最后更新: Round 7 | 日期: 2026-03-14

## 项目一句话
WoW 12.0 AI 战斗辅助插件，融合 Blizzard Assisted Combat + APL 预测 + 神经网络推断

## 当前质量评分: 8.5/10

## 活跃分支
| 分支 | 用途 | 状态 |
|------|------|------|
| main | 主线 | SHA 013504e, CI 待验证 |
| improve/round7-test-and-ci | 测试与 CI 升级 | 正在执行 |

## 已完成指令
- [#1.x] 数据清理去重、工程基础(CI/packaging/changelog) → 已合并
- [#2.x] 代码质量P1 (Init.lua Registry统一, SQM table reuse, package.sh) → 已合并
- [#3.x] 清理死代码Predictor.lua, schema统一(interrupt/resource), DefensiveAdvisor:OnDisable, 测试基础(busted+mock+3测试文件) → 已合并
- [#4.x] SQM CalculateScore 单元测试 → 已合并
- [#5.x] Registry, EventHandler, CastHistory, AccuracyTracker, PatternDetector, SpecData 单元测试 → 已合并
- [#6.x] InitHelpers, APLEngine, SQM Integration, InitSlash 单元测试 → 已合并

## 当前待办
- [#7.1] 修复 CI: 升级 GitHub Actions 到 Node 24 兼容版本
- [#7.2] 增加 CooldownOverlay, AssistedCombatBridge, DefensiveAdvisor, SavedVars 单元测试

## 待办队列(优先级)
1. CI绿灯 — 阻塞一切: 高/高/正在执行
2. 记忆持久化 — 防止上下文丢失: 中/高
3. RecommendationManager.lua 死代码清除: 低/中
4. Phase2 专精扩展(Warrior/Mage/Paladin/Hunter): 高/产品关键路径

## 风险登记
- CI从未绿过: 高严重度, 本轮修复 (Node 16 弃用问题)
- Devourer spellID 全为占位符: 中严重度, 延后到spec数据审计

## 关键技术决策
- 使用 busted + mock_wow_api.lua 做 Lua 单元测试
- Registry.lua 作为 PASSIVE_BLACKLIST/OVERRIDE_PAIRS 唯一真相来源
- SpecEnhancements 统一使用 nested interruptSpell 和 powerType 字段

## Round 7 – Test and CI
- Branch: improve/round7-test-and-ci
- Tests added: test_cooldown_overlay, test_assisted_combat_bridge, test_defensive_advisor, test_saved_vars
- CI status: Upgraded actions to Node 24 to fix deprecation errors.

## Round 8 — Final Test Expansion (2026-03-14)

**Branch**: `improve/round8-test-expansion`  
**Base**: `main@be12243`

### Changes
- Added `tests/test_interrupt_advisor.lua` — interrupt state, cooldown check, lifecycle
- Added `tests/test_neural_predictor.lua` — module load, Markov API, save/load matrix
- Added `tests/test_prepull_checker.lua` — consumable buff checks, RunChecks/IsReady API
- Added `tests/test_whitelist_spells.lua` — data integrity, 13-class coverage, cd >= 30
- Added `tests/test_spec_detector.lua` — spec detection, role check, spec change event
- Added `tests/test_ai_inference.lua` — InferredState structure, GetContext, default values

### Coverage
- Test files: 16 → 22
- Estimated test cases: ~190 → ~260+
- All Engine modules now covered: Init, Registry, SpecData, EventHandler, CastHistoryRecorder,
  AccuracyTracker, PatternDetector, APLEngine, SmartQueueManager, CooldownOverlay,
  AssistedCombatBridge, DefensiveAdvisor, SavedVars, InterruptAdvisor, NeuralPredictor,
  PrePullChecker, SpecDetector, AIInference
- Data modules covered: WhitelistSpells

### Notes
- RecommendationManager is marked DEPRECATED and commented out of TOC; not tested
- Mock additions: GetCVar, GetSpecialization, GetSpecializationInfo, UnitClass, C_UnitAuras

## Round 9 — End-to-End Integration Tests (2026-03-14)

**Branch**: `improve/round9-e2e-integration`
**Base**: `main@0fc95ad`

### Changes
- Added `tests/test_e2e_combat_flow.lua` — full combat lifecycle integration test
- Updated `tests/mock_wow_api.lua` — added bit library, C_AssistedCombat, C_UnitAuras,
  C_CurveUtil, CreateColor, UnitClass, GetSpecialization mocks for E2E test support

### Test Coverage
- Test files: 22 → 23
- Estimated test cases: ~264 → ~290+
- E2E scenarios validated:
  1. All 14 Engine modules load and initialize without errors
  2. OnInitialize → OnEnable chain for all modules
  3. Combat start (PLAYER_REGEN_DISABLED) activates AccuracyTracker session
  4. ROTAASSIST_SPELLCAST_SUCCEEDED records to CastHistoryRecorder ring buffer
  5. AccuracyTracker matches casts against Blizzard recommendation
  6. Non-matching casts correctly reduce accuracy percentage
  7. Multiple casts build ring buffer with correct ordering (newest first)
  8. Combat end (PLAYER_REGEN_ENABLED) triggers AccuracyTracker:SaveSession
  9. CastHistoryRecorder resets session accuracy on combat end
  10. APLEngine predicts next steps from loaded APL data
  11. APL predictions skip passive-blacklisted spells
  12. Meta state (Metamorphosis) changes APL prediction selection
  13. SmartQueueManager returns valid queue and display data structures
  14. Event propagation reaches multiple subscribers correctly
  15. CastHistoryRecorder save/load round-trip preserves data
  16. AccuracyTracker session records persist to SavedVariables
## Round 10 — Edge Cases, Override Pairs & Python Pipeline (2026-03-14)

**Branch**: `improve/round10-edge-and-python`
**Base**: `main@2055c49`

### Changes
- Added `tests/test_edge_cases.lua` — nil/zero inputs, empty APL, missing RA.db, passive blacklist
- Added `tests/test_override_pairs.lua` — bidirectional mapping, SharesCooldown, APL CD mirroring, SQM paired check, passive partner
- Added `training/test_apl_parser.py` — SPELL_MAP integrity, APL parser, constraint extraction, scenario generation, CSV round-trip
- Updated `.github/workflows/ci.yml` — added pytest step to python-training job

### Coverage
- Test files: 23 → 25 Lua + 1 Python = 26
- Estimated test cases: ~287 Lua + ~30 Python = ~317+
- New areas validated: safe wrapper nil handling, APL empty/nil states, override pair CD mirroring,
  passive blacklist partner detection, Python SPELL_MAP/SPEC_IDS integrity, APL parser correctness,
  constraint extraction, dataset generation field validation, CSV output format
