# RotaAssist — 项目路线图 / Project Roadmap

> 最后更新 / Last updated: 2026-02-26
> 维护说明：每完成一个步骤后，将其状态从 `[ ]` 改为 `[x]` 并注明完成日期。

---

## 项目定位

RotaAssist 是 WoW 12.0 Midnight 时代的智能循环助手，定位为 Hekili 替代品。由三层组成：

1. **WoW 插件**（Lua）— 免费开源，游戏内实时循环建议
2. **桌面伴侣**（Tauri v2 + Rust + Svelte）— 读取 WoWCombatLog.txt 的实时 AI 分析悬浮窗
3. **云端进化**（远期）— 匿名数据收集 + 全球模型训练

---

## 三层 AI 架构

### 层级 1：插件内伪 AI（Pure Lua）

| 模块 | 功能 | 状态 |
|---|---|---|
| `Engine/NeuralPredictor.lua` | 离线训练的决策树（sklearn→Lua）+ 马尔可夫链（个人学习 + 默认矩阵混合） | ✅ 已实现 |
| `Engine/PatternDetector.lua` | 12 阶段战斗模式识别（多信号加权投票） | ✅ 已实现 |
| `Engine/CastHistoryRecorder.lua` | 施法历史环形缓冲（200 cap）+ SavedVars 持久化 | ✅ 已实现 |
| `Engine/SmartQueueManager.lua` | 多源加权融合：Blizzard×1.0 + APL×0.6 + AI×0.4 + CD×0.5 + Def×0.8 | ✅ 已实现 |
| `Engine/AccuracyTracker.lua` | 双轨准确率（Blizzard vs SmartQueue）+ 阶段统计 + 历史趋势 | ✅ 已实现 |
| `Engine/AIInference.lua` | 信号推理引擎（AoE/Burst/Resource/Emergency 等） | ✅ 已实现 |
| `Engine/InterruptAdvisor.lua` | 12.0 合规打断提醒 | ✅ 已实现 |
| `Engine/CDMHook.lua` | EssentialCooldownViewer Hook（可选增强，默认禁用） | ⬜ 设计完成，未实现 |

### 层级 2：桌面伴侣（Tauri v2）

| 组件 | 功能 | 状态 |
|---|---|---|
| `combat_log_watcher.rs` | OS 级文件监听 WoWCombatLog.txt | ⬜ 未开始 |
| `log_parser.rs` | 解析战斗日志事件 | ⬜ 未开始 |
| `ai_engine.rs` | ONNX Runtime 推理（rotation_scorer + phase_detector） | ⬜ 未开始 |
| `OverlayView.svelte` | 透明悬浮窗（DPS、评分、建议） | ⬜ 未开始 |
| LLM 战后复盘 | Ollama 本地 / Gemini-Cloud 自然语言分析 | ⬜ 未开始 |

### 层级 3：云端持续进化

| 功能 | 状态 |
|---|---|
| 匿名施法序列收集（opt-in） | ⬜ 远期 |
| 基于 Warcraft Logs Top 100 训练全球模型 | ⬜ 远期 |
| 自动推送更新后的决策树 Lua（via GitHub Releases） | ⬜ 远期 |

---

## 12.0 Secret Values 关键规则

| 数据 | 状态 | 备注 |
|---|---|---|
| `C_AssistedCombat.GetNextCastSpell()` | ✅ 完全开放 | 主数据源 |
| `C_AssistedCombat.GetRotationSpells()` | ✅ 完全开放 | 技能池 |
| 玩家 `UNIT_SPELLCAST_*` 事件 | ✅ 非秘密 | 战斗中可用 |
| 次要资源（Soul Fragments, Combo Points 等） | ✅ 非秘密 | 随时 |
| `UnitHealthMax` / `UnitPowerMax`（玩家） | ✅ 非秘密 | 随时 |
| 白名单法术 CD 和 Aura | ✅ 非秘密 | 特定法术 |
| 铭牌 `UnitExists("nameplateN")` | ✅ 可用 | GUID 秘密 |
| `UnitHealth("player")` 精确值 | ❌ 秘密值 | 不可做算术运算 |
| 主资源精确值（Fury/Mana/Rage） | ❌ 秘密 | 不可逻辑判断 |
| 大多数技能 CD / Buff 详情 | ❌ 秘密（战斗中） | 不可逻辑判断 |
| `COMBAT_LOG_EVENT_UNFILTERED` | ❌ 完全封锁 | 插件内不可用 |
| `WoWCombatLog.txt` 磁盘文件 | ✅ 正常写入 | 外部程序可 tail |

---

## 竞品对比

| 功能 | SACI | JAC | MaxDPS | RotationAnalyzer | **RotaAssist** |
|---|---|---|---|---|---|
| Blizzard 推荐显示 | 1 图标 | 队列 | 高亮条 | ✗ | T 形队列 |
| AI 预测下 N 步 | ✗ | ✗ | ✗ | ✗ | ✅ 决策树+马尔可夫 |
| 冷却追踪 | ✗ | ✓ | ✗ | ✗ | ✅ CD Bar |
| 资源条 | ✗ | ✗ | ✗ | ✗ | ✅ 动态 |
| 防御提醒 | ✗ | 基础 | ✗ | ✗ | ✅ 脉冲警报 |
| 打断提醒 | ✗ | ✓ | ✗ | ✗ | ✅ |
| 准确率评分 | ✗ | ✗ | ✗ | ✓ | ✅ + 历史趋势 |
| 战斗阶段识别 | ✗ | ✗ | ✗ | ✗ | ✅ 12 种阶段 |
| 自学习个人模式 | ✗ | ✗ | ✗ | ✗ | ✅ 马尔可夫链 |
| 开战前检查 | ✗ | ✗ | ✗ | ✗ | ✅ |
| 战后 AI 复盘 | ✗ | ✗ | ✗ | ✗ | ✅ Companion |
| 多语言 | ✗ | 英 | 英 | 英 | 英/中/日 |
| 桌面悬浮分析 | ✗ | ✗ | ✗ | ✗ | ✅ Tauri |

---

## 支持的专精

| 专精 | specID | 决策树 | 马尔可夫矩阵 | APL | 状态 |
|---|---|---|---|---|---|
| DH Havoc | 577 | ✅ 训练完成 | ✅ 默认矩阵 | ✅ | 完整支持 |
| DH Vengeance | 581 | ✅ 训练完成 | ✅ 默认矩阵 | ✅ | 完整支持 |
| DH Devourer | 1480 | ⬜ 占位符 | ⬜ 默认 8 技能 | ✅ | 框架就绪，待 APL 发布后训练 |
| Warrior Arms | — | ⬜ | ⬜ | ✅ APL 数据 | 待训练 |
| Warrior Fury | — | ⬜ | ⬜ | ✅ APL 数据 | 待训练 |
| Mage Fire | — | ⬜ | ⬜ | ✅ APL 数据 | 待训练 |

---

## 执行计划与进度

### Phase 1 — v1.0.0 插件核心 ✅ 完成

| 步骤 | 内容 | 模型 | 状态 |
|---|---|---|---|
| A | NeuralPredictor + PatternDetector + CastHistoryRecorder | Claude Opus 4.6 | ✅ 2026-02-25 |
| B | SmartQueueManager + AccuracyTracker + InterruptAdvisor | Gemini 3.1 Pro | ✅ 2026-02-25 |
| C | UI Widgets (AccuracyMeter, PhaseIndicator) + MainDisplay 集成 | Gemini 3.1 Pro | ✅ 2026-02-25 |
| D | training/ pipeline + DH 决策树/矩阵 Lua 生成 | Claude Opus 4.6 | ✅ 2026-02-25 |
| E | 全面代码审查（12.0 合规 + 性能 + nil safety），28 项中 27 PASS / 1 FAIL 已修 | Claude Sonnet 4.6 | ✅ 2026-02-25 |
| F | Release 打包（README, CHANGELOG, .pkgmeta, TOC, TEST_CHECKLIST） | Gemini 3 Flash | ✅ 2026-02-25 |
| specID 修复 | 全局 1473→1480 替换（11 文件） | — | ✅ 2026-02-25 |
| GitHub 同步 | 初始 commit + tag v1.0.0 | — | ✅ 2026-02-25 |
| 代码审核修复 | 9 项致命/严重/中等问题修复（CooldownPanel 语法、Libs 缺失、方法不存在、Secret Value、回调签名、TOC 注释等） | Claude Opus 4.6 审核 → Gemini 3.1 Pro High 执行 | ✅ 2026-02-26 |

### Phase 2 — v1.1.0 CDM Hook + 实测 ⬜ 当前

| 步骤 | 内容 | 模型建议 | 状态 |
|---|---|---|---|
| ROADMAP | 创建本文件，路线图持久化 | — | ⬜ 进行中 |
| TEST | 游戏内实测 `docs/TEST_CHECKLIST.md` | 人工 | ⬜ 未开始 |
| CDM | `Engine/CDMHook.lua` 实现（设置项可开关，默认禁用） | Gemini 3.1 Pro High | ⬜ 设计完成 |
| CDM-INT | CDMHook 集成到 InterruptAdvisor + SmartQueueManager | Gemini 3.1 Pro High | ⬜ 未开始 |
| v1.1-TAG | 合并、测试、tag v1.1.0 | — | ⬜ 未开始 |

### Phase 3 — v2.0 Companion 桌面应用 ⬜ 计划中

| 步骤 | 内容 | 模型建议 | 状态 |
|---|---|---|---|
| G | Tauri v2 项目初始化 + `combat_log_watcher.rs` + `log_parser.rs` | Claude Opus 4.6 Thinking | ⬜ 未开始 |
| H | Python 训练 `rotation_scorer.onnx` 模型（SimC APL 数据） | Claude Opus 4.6 | ⬜ 未开始 |
| I | Svelte 透明悬浮窗 `OverlayView.svelte` + Rust↔JS IPC | Gemini 3.1 Pro High | ⬜ 未开始 |
| J | LLM 战后复盘（Ollama 本地 + Cloud API 可选） | Claude Opus 4.6 Thinking | ⬜ 未开始 |

### Phase 4 — 扩展 + 上架 ⬜ 计划中

| 步骤 | 内容 | 状态 |
|---|---|---|
| K | 扩展专精支持：Warrior Arms/Fury, Mage Fire, DK Frost/Unholy, Paladin Ret | ⬜ |
| L | CurseForge / Wago 正式上架 + 首版宣传 | ⬜ |

### Phase 5 — 云端持续进化 ⬜ 远期

| 步骤 | 内容 | 状态 |
|---|---|---|
| M | 匿名数据收集 opt-in 系统 | ⬜ |
| N | 基于 WCL Top 100 parse 训练全球最优循环模型 | ⬜ |
| O | 每大版本 48h 内自动更新 APL + 决策树（via GitHub Actions） | ⬜ |

---

## CDM Hook 技术方案（Phase 2 参考）

```lua
-- EssentialCooldownViewer Hook 方案
for _, cd in pairs({EssentialCooldownViewer:GetChildren()}) do
  if cd.GetSpellID and cd:GetSpellID() then
    hooksecurefunc(cd, "TriggerAlertEvent", function(self, ev)
      if ev == Enum.CooldownViewerAlertEventType.Available then
        -- 技能就绪
      elseif ev == Enum.CooldownViewerAlertEventType.OnCooldown then
        -- 技能进入 CD
      end
    end)
  end
end

模块设计：Engine/CDMHook.lua（~150 行），AceAddon 模块，默认禁用，配置项 enabled、trackInterrupt、trackMajorCD、watchedSpells。通过 pcall 安全执行，错误时自动禁用。集成点：InterruptAdvisor 用真实 CD 替代 15s 估算值；SmartQueueManager 新增 cdmWeight（默认 0.7）。

训练管线参考
training/
├── requirements.txt          # scikit-learn, pandas, numpy
├── README.md                 # 使用说明
├── simc_apl_to_dataset.py    # SimC APL → CSV 训练数据
├── train_decision_tree.py    # CSV → sklearn DecisionTree → joblib
├── sklearn2lua.py            # joblib → 纯 Lua if-elseif 决策树
└── markov_builder.py         # 施法日志 → 转移概率矩阵 Lua
流程：simc_apl_to_dataset.py → train_decision_tree.py → sklearn2lua.py → addon/Data/DecisionTrees/DH_Havoc_DT.lua

关键设计决策记录
specID 1480：Devourer DH 专精 ID 确认为 1480（Warcraft Wiki），非 1473（Evoker Augmentation）。已全局修复。
UnitHealth 禁用：12.0 中 UnitHealth("player") 返回 secret value，不可做算术运算。DefensiveAdvisor 改为基于 Blizzard 推荐防御技能的启发式检测。
AceEvent 回调签名：RA:RegisterEvent(event, localFunc) 传入 (self, event, ...) — 所有 local function 回调必须在前两个参数接收 self e event。
TOC 注释：WoW TOC 只识别 ## 开头的注释，单 # 会被当作文件路径。
embeds.xml vs TOC：Ace3 库通过 embeds.xml 加载（XML 先于 TOC 中的 Lua 文件执行），所有库路径必须与 addon/Libs/ 实际目录结构一致。
