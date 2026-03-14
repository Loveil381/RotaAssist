# RotaAssist — CTO AI 进度状态
> 最后更新: Round 4 | 日期: 2026-03-14

## 项目一句话
WoW 12.0 AI 战斗辅助插件，融合 Blizzard Assisted Combat + APL 预测 + 神经网络推断

## 当前质量评分: 8.2/10

## 活跃分支
| 分支 | 用途 | 状态 |
|------|------|------|
| main | 主线 | SHA 3672157, CI 红灯待修 |
| improve/fix-ci-and-memory | CI修复+记忆持久化 | 本轮执行中 |

## 已完成指令
- [#1.x] 数据清理去重、工程基础(CI/packaging/changelog) → 已合并
- [#2.x] 代码质量P1 (Init.lua Registry统一, SQM table reuse, package.sh) → 已合并
- [#3.x] 清理死代码Predictor.lua, schema统一(interrupt/resource), DefensiveAdvisor:OnDisable, 测试基础(busted+mock+3测试文件) → 已合并
- [#4.x-partial] SQM CalculateScore 单元测试 → 已合并(直推main)

## 当前待办
- [#4.1] 修复CI: .luacheckrc缺少全局声明, ci.yml Lua版本问题, helpers.lua别名同步, AccuracyTracker变量遮蔽

## 待办队列(优先级)
1. CI绿灯 — 阻塞一切: 高/高/正在执行
2. 记忆持久化 — 防止上下文丢失: 中/高
3. RecommendationManager.lua 死代码清除: 低/中
4. Phase2 专精扩展(Warrior/Mage/Paladin/Hunter): 高/产品关键路径
5. NeuralPredictor 内联黑名单审计: 低/中

## 风险登记
- CI从未绿过: 高严重度, 本轮修复
- Devourer spellID 全为占位符: 中严重度, 延后到spec数据审计
- RecommendationManager.lua 死代码: 低, 计划R5清除
- docs/ai-cto/ 不存在: 中, 本轮创建

## 关键技术决策
- 使用 busted + mock_wow_api.lua 做 Lua 单元测试
- Registry.lua 作为 PASSIVE_BLACKLIST/OVERRIDE_PAIRS 唯一真相来源
- SpecEnhancements 统一使用 nested interruptSpell 和 powerType 字段

## Round 5 – Unit Test Expansion
- Branch: improve/unit-test-expansion
- Tests added: test_registry, test_event_handler, test_cast_history,
  test_accuracy_tracker, test_pattern_detector, test_spec_data
- Coverage target: >25% (from ~8%)

## Round 6 – Test Expansion
- Branch: improve/round6-test-expansion
- Tests added: test_init_helpers, test_apl_engine, test_sqm_integration, test_init_slash
- Coverage target: further expansion on core engine and command parsing
