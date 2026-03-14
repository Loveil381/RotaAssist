# RotaAssist — 产品愿景与技术愿景

> 最后更新: Round 11 | 日期: 2026-03-14

## 产品愿景

### 最终产品形态
WoW 12.0 (Midnight) 智能战斗循环辅助插件。面向 WoW PvE 玩家（M+/Raid），
提供实时技能推荐，融合 Blizzard C_AssistedCombat API、SimC APL 预测、
决策树 + Markov 链 AI 推断三大数据源，用加权算法产生最终推荐。

### 核心功能
- **多源融合推荐**: Blizzard 官方 + APL + AI → SmartQueueManager 加权混合 ✅
- **战斗阶段检测**: Burst/AoE/Execute/Emergency 等 8+ 阶段自动识别 ✅
- **准确率追踪**: 实时对比玩家施法与最优选择 ✅
- **打断提醒**: 12.0 secret-value 兼容的打断提示 ✅
- **冷却面板**: 大招/减伤/主动减伤追踪 ✅
- **防御建议**: 基于血线阈值的减伤提醒 ✅
- **多职业支持**: 目前 DH 3 专精完整，其他职业数据部分存在 🔄
- **训练管线**: Python 离线生成决策树/Markov 矩阵 ✅
- **UI 系统**: 主显示/冷却面板/小地图按钮/配置面板 ✅

### 竞品参照
- Hekili: APL 驱动，纯确定性，无 AI 层
- MaxDPS: Blizzard API + 硬编码优先级
- RotaAssist 差异化: 三源融合 + 玩家风格学习 + 准确率反馈

### 产品关键缺口
1. 仅 DH 有完整 SpecEnhancements 数据
2. Warrior/Mage/Rogue/Shaman/Druid/Evoker 有 APL 但无 SpecEnhancements
3. Devourer specID 全为占位符
4. 无用户引导 / 首次使用体验
5. 未在真机 12.0 环境验证

## 技术愿景

### 架构评判
当前 AceAddon 模块化架构成熟稳定，MODULE_ORDER 保证初始化顺序，
EventHandler 统一事件分发。架构足以支撑 13 职业 39 专精扩展。
瓶颈不在架构，在数据（SpecEnhancements/APL/DT/TM 缺失）。

### 如果只能做三件事
1. **补全 Warrior SpecEnhancements** — 最快可上线的新职业
2. **真机冒烟测试** — 验证 secret-value / C_AssistedCombat 在 12.0 的实际行为
3. **Mage/Paladin SpecEnhancements** — 扩大用户覆盖面

### 架构演进路线
Phase 0 (已完成): 单职业 DH 完整实现 + 测试基础
Phase 1 (进行中): 多职业 SpecEnhancements 数据补全
Phase 2: UI 打磨 + 用户引导
Phase 3: CurseForge 发布 + 真机验证 + 社区反馈循环
