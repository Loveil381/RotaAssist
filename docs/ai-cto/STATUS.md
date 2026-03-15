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
## Round 10 — Edge Cases, Override Pairs, Python Tests (2026-03-14)

**Branch**: `improve/round10-edge-and-python`
**Base**: `main@2055c49`

### Changes
- Added `tests/test_edge_cases.lua` — Init.lua safe wrappers, APLEngine edge cases,
  CastHistoryRecorder/AccuracyTracker/SmartQueueManager/Registry boundary conditions
- Added `tests/test_override_pairs.lua` — Registry bidirectional mapping, SharesCooldown,
  APLEngine SimulateSpellCast CD mirroring, SQM cooldown check, passive blacklist
- Added `training/test_apl_parser.py` — Python APL parser unit tests (pytest)
- Updated `ci.yml` — added pytest step to python-training job

### Coverage
- Test files: 23 → 25
- Estimated test cases: ~287 → ~344
- Fixes: 1 (corrected GetSpellCooldownSafe test assertions)

## Round 11 — CTO Memory Files (2026-03-14)

**Branch**: `improve/round11-memory-files`
**Base**: `main@0a67b7d`

### Changes
- Created `docs/ai-cto/VISION.md` — product vision + technical vision
- Created `docs/ai-cto/ARCHITECTURE.md` — module hierarchy + data flow + init order
- Created `docs/ai-cto/DECISIONS.md` — 7 technical decision records (D-001 through D-007)
- Updated `docs/ai-cto/STATUS.md` — added Round 10 + Round 11 entries

### Active Branch State
- main@0a67b7d — stable, CI green, 25 test files, 344 cases
- No open PRs

### Pending Work Queue (Priority)
1. Warrior SpecEnhancements (Arms 71 / Fury 72) — 产品关键路径
2. Mage SpecEnhancements (Fire 63) — 产品关键路径
3. Warrior/Mage DecisionTree + TransitionMatrix generation — 产品关键路径
4. TOC registration for new SpecEnhancements files
5. Devourer spellID 验证 — 延后到 12.0 live
6. 真机冒烟测试 — 需要 WoW 12.0 客户端

## Round 12 — Warrior SpecEnhancements (2026-03-14)

**Branch**: `improve/round12-warrior-spec`
**Base**: `main@868ffa0`

### Changes
- Created `addon/Data/SpecEnhancements/Warrior.lua` — Arms (71) + Fury (72)
- Updated `addon/RotaAssist.toc` — registered Warrior.lua
- Updated `training/simc_apl_to_dataset.py` — added arms/fury to SPEC_IDS, SPEC_SPELLS, SPELL_MAP, DEFAULT_APLS
- Updated `.github/workflows/ci.yml` — added arms/fury CSV generation tests
- Added `tests/test_warrior_spec.lua` — data integrity tests for both specs
- Updated `docs/ai-cto/STATUS.md`

### Warrior Support Status
- APL: ✅ (existed: Warrior_Arms.lua, Warrior_Fury.lua)
- SpecEnhancements: ✅ (new: Warrior.lua)
- DecisionTree: ❌ (pending generation)
- TransitionMatrix: ❌ (pending generation)
- Python training: ✅ (arms/fury added to pipeline)

## Round 13 ? Warrior DecisionTree + TransitionMatrix (2026-03-14)

**Branch**: `improve/round13-warrior-dt-tm`
**Base**: `main@0d80062`

### Changes
- Generated `addon/Data/DecisionTrees/WAR_Arms_DT.lua` via training pipeline
- Generated `addon/Data/DecisionTrees/WAR_Fury_DT.lua` via training pipeline
- Generated `addon/Data/TransitionMatrix/WAR_Arms_TM.lua` via training pipeline
- Generated `addon/Data/TransitionMatrix/WAR_Fury_TM.lua` via training pipeline
- Updated `addon/RotaAssist.toc` - registered 4 new data files
- Updated `.github/workflows/ci.yml` - end-to-end DT+TM generation validation
- Updated `docs/ai-cto/STATUS.md`

### Warrior Support Status (COMPLETE)
- APL: yes
- SpecEnhancements: yes
- DecisionTree: yes (new)
- TransitionMatrix: yes (new)
- Python pipeline: yes
- TOC registration: yes

## Round 14 — CD Filter Hotfix (P0 Product Bug Fix)

**Branch**: `fix/round14-cd-filter-hotfix`
**Base**: `main@a45a7d7`

### Root Cause
User reported Havoc DH skills still recommended while on cooldown.
Three bugs identified in SQM/APLEngine CD filtering chain:
1. Sticky Blizzard fallback (lastKnownBlizzSpell) not validated against CD
2. CD safety net has no fallback for spells not tracked by CooldownOverlay
3. APLEngine PredictNext only checks real-time CD in step 1, not step 2+

### Changes
- Fixed `SmartQueueManager.lua` sticky fallback to check IsSpellOnCooldown
- Fixed `SmartQueueManager.lua` CD safety net to use API fallback for untracked spells
- Fixed `APLEngine.lua` PredictNext to cross-check real CD in steps 2+ (with sim guard)
- Added `tests/test_cd_filter.lua` — 4 regression tests

### Quality
- Score: 8.5 → 8.8/10 (P0 product fix)

## Round 15 — UI Overhaul (HekiLight-style)

**Branch**: `improve/round15-ui-overhaul`

### Changes
- Rewrote `MainDisplay.lua` from T-shaped dashboard to a clean horizontal icon strip
- Refactored `DefensiveAlert` and `InterruptAlert` into standalone floating frames
- Added range check (red pulse) and proc glow support
- Filtered out CD spells from prediction slots
- Added MainDisplay layout UI tests

### Quality
- Score remains 8.8 (Engine), UI Experience goal jumps to 7/10

