# RotaAssist — 架构文档

> 最后更新: Round 11 | 日期: 2026-03-14

## 模块层次

### Core 层 (基础设施)
- Init.lua — AceAddon 引导、模块注册、slash 命令、安全 API 包装
- SavedVars.lua — AceDB 配置、defaults、DeepCopy
- EventHandler.lua — 统一事件分发 (Subscribe/Fire/Throttle)
- AssistCapture.lua — C_AssistedCombat 事件捕获
- CooldownTracker.lua — 冷却状态缓存

### Data 层 (静态数据)
- Registry.lua — PASSIVE_BLACKLIST / OVERRIDE_PAIRS / FALLBACK_TEXTURE (单一真相源)
- SpecInfo.lua — 13 职业 39 专精的 specID/classID/role 映射
- WhitelistSpells.lua — 大招冷却 (cdSeconds >= 30) 全职业数据
- SpecEnhancements/ — 每职业的 majorCooldowns/defensives/resource/inferenceRules
- APL/ — 每专精的优先级规则
- DecisionTrees/ — Python 生成的决策树 Lua 表
- TransitionMatrix/ — Python 生成的 Markov 转移矩阵

### Engine 层 (业务逻辑)
- SpecDetector — 专精检测 + APL 加载
- AssistedCombatBridge — Blizzard 推荐获取
- APLEngine — APL 条件评估 + 多步预测 + meta state
- SmartQueueManager — 三源加权融合 + 防抖 + soft-block
- AIInference — 战斗阶段/资源/AoE/burst 推断
- NeuralPredictor — Markov 链预测
- PatternDetector — 施法模式识别
- CastHistoryRecorder — 环形缓冲施法记录
- AccuracyTracker — 准确率统计 + 历史存档
- CooldownOverlay — 冷却追踪 UI 数据源
- DefensiveAdvisor — 血线阈值防御建议
- InterruptAdvisor — 打断状态 + 提醒
- PrePullChecker — 战斗前消耗品检查

### UI 层
- Widgets/ — 7 个可复用组件 (Glow/Icon/ResourceBar/PhaseIndicator/AccuracyMeter/PrePullPanel/DefensiveAlert/CooldownBar)
- MainDisplay — 主推荐面板
- CooldownPanel — 冷却追踪面板
- MinimapButton — 小地图图标
- ConfigPanel — AceConfigDialog 设置

### 训练管线 (Python)
- simc_apl_to_dataset.py — SimC APL → CSV
- train_decision_tree.py — CSV → 决策树 + Markov 矩阵 → Lua 文件

## 关键数据流
SpecDetector(专精检测) → APLEngine(加载APL) → SmartQueueManager(融合推荐)
AssistedCombatBridge(Blizzard推荐) → SmartQueueManager
AIInference(战斗推断) → SmartQueueManager
CastHistoryRecorder(施法记录) → AccuracyTracker(准确率) → SavedVars(存档)
NeuralPredictor(Markov预测) → SmartQueueManager(降级回退)

## 初始化顺序
MODULE_ORDER 定义在 Init.lua，严格按依赖关系：
SavedVars → EventHandler → AssistCapture → CooldownTracker →
SpecDetector → ACB → AccuracyTracker → AIInference →
CastHistoryRecorder → PatternDetector → NeuralPredictor →
APLEngine → SmartQueueManager → CooldownOverlay →
DefensiveAdvisor → PrePullChecker → UI modules
