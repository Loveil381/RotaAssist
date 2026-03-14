# RotaAssist — 技术决策记录

> 最后更新: Round 11 | 日期: 2026-03-14

## D-001: 测试框架选择 — busted + mock_wow_api.lua
- 日期: Round 4
- 决策: 使用 busted (Lua BDD 框架) + 手写 mock_wow_api.lua
- 理由: WoW 插件无法在真实环境外运行；busted 是 Lua 生态最成熟的测试框架
- 结果: 25 个测试文件、344 用例、0 失败

## D-002: Registry 作为单一真相源
- 日期: Round 2
- 决策: PASSIVE_BLACKLIST, OVERRIDE_PAIRS, FALLBACK_TEXTURE 统一在 Registry.lua
- 理由: 消除 Init.lua / SQM / APLEngine 之间的数据重复
- 影响: 所有模块通过 RA.Registry 读取，Init.lua 通过 RA.KNOWN_OVERRIDE_PAIRS 别名引用

## D-003: SpecEnhancements schema 统一
- 日期: Round 3
- 决策: interruptSpell 改为 { spellID, name, cooldown } 嵌套表；resource.powerType 统一为数字
- 理由: DefensiveAdvisor 和 InterruptAdvisor 需要结构化数据
- 影响: DemonHunter.lua 已迁移；其他职业需遵循同一 schema

## D-004: RecommendationManager 废弃
- 日期: Round 1
- 决策: RecommendationManager.lua 标记为 DEPRECATED，从 TOC 注释掉
- 理由: SmartQueueManager 完全取代其功能，合并了三源融合逻辑
- 影响: 不需要测试覆盖；文件保留仅供参考

## D-005: SendMessage mock 双表分发
- 日期: Round 9
- 决策: mock_wow_api.lua 的 SendMessage 同时检查 _messageCallbacks 和 _eventCallbacks
- 理由: AceEvent:RegisterMessage 和 AceEvent:RegisterEvent 使用不同回调表；
        E2E 测试中 EventHandler:Fire 通过 SendMessage 分发事件需要两表都触发
- 影响: 修复了 E2E 集成测试中事件传播不到 AccuracyTracker/CastHistoryRecorder 的问题

## D-006: CI 三 job 策略
- 日期: Round 4
- 决策: lua-check (静态分析) + python-training (管线验证) + lua-tests (单元/集成测试)
- 理由: 三者独立并行，覆盖 Lua 质量、Python 管线、运行时正确性
- Round 10 补充: 在 python-training 中增加了 pytest 步骤

## D-007: 多职业扩展策略
- 日期: Round 11
- 决策: 按 "APL → SpecEnhancements → DT/TM → TOC 注册" 顺序逐职业扩展
- 理由: APL 是最轻量级的数据（纯优先级规则），SpecEnhancements 需要准确的 spellID/cost 数据
- 当前状态: Warrior Arms/Fury 已有 APL 但缺 SpecEnhancements
