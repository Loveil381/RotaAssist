# RotaAssist v1.0.0 测试清单 / Test Checklist

## 基础加载 / Basic Loading
- [ ] `/reload` 无 Lua 错误
- [ ] `/ra` 显示/隐藏主窗口
- [ ] `/ra config` 打开设置面板
- [ ] `/ra accuracy` 输出准确率历史

## Havoc DH (specID 577)
- [ ] 显示 Blizzard 推荐技能 (主图标)
- [ ] AI 阶段检测正常 (BURST_ACTIVE / AOE / NORMAL)
- [ ] 预判队列 (2 个图标) 正确更新
- [ ] 准确率计数器工作并显示百分比
- [ ] Metamorphosis 触发后 PhaseIndicator 变橙色
- [ ] 右键菜单全部选项可用

## Vengeance DH (specID 581)
- [ ] Demon Spikes 在冷却栏正确显示
- [ ] 防御技能推荐在紧急时显示
- [ ] Spirit Bomb 优先于 Soul Cleave (4+ 灵魂碎片)
- [ ] 资源条显示正确

## Devourer DH (specID 1480)
- [ ] Void Metamorphosis 阶段检测
- [ ] Collapsing Star 推荐时机 (3+ 碎片)
- [ ] 决策树正确加载 (占位符)
- [ ] 转移矩阵正确加载

## UI
- [ ] 拖拽 & 锁定 (右键菜单)
- [ ] AccuracyMeter 颜色变化 (红/黄/绿)
- [ ] PhaseIndicator 阶段图标切换
- [ ] 缩放功能 (75% / 100% / 125% / 150%)
- [ ] 战斗结束后 fade out (combatOnly 模式)
- [ ] 打断警报音效 + 红色闪光 (urgency ≥ 0.8)
- [ ] 多分辨率: 1920×1080, 2560×1440

## 性能
- [ ] 5 分钟副本测试无卡顿
- [ ] 内存增长 < 1MB/小时
- [ ] `/dump GetAddOnMemoryUsage("RotaAssist")` < 2MB 初始

## 本地化
- [ ] 切换客户端语言至 zhCN → 所有 UI 文字中文
- [ ] 切换客户端语言至 jaJP → 所有 UI 文字日文
- [ ] enUS 默认完整

## 专精切换
- [ ] Havoc → Vengeance: 决策树/矩阵重新加载
- [ ] Vengeance → Devourer: 占位符树加载无报错
- [ ] 个人 Markov 矩阵在切换后保持独立
