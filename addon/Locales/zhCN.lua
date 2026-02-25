------------------------------------------------------------------------
-- RotaAssist - 简体中文本地化
-- Simplified Chinese locale using WoW Chinese player conventions.
-- 循环 (rotation), 技能 (skill/ability), 冷却 (cooldown), 专精 (spec)
------------------------------------------------------------------------

local L = LibStub("AceLocale-3.0"):NewLocale("RotaAssist", "zhCN")
if not L then return end

------------------------------------------------------------------------
-- 通用
------------------------------------------------------------------------
L["STARTUP_MESSAGE"]    = "RotaAssist v%s 已加载。输入 /ra 查看帮助。"
L["UNKNOWN_COMMAND"]    = "未知命令: %s — 输入 /ra help 查看帮助"

------------------------------------------------------------------------
-- 斜杠命令帮助
------------------------------------------------------------------------
L["SLASH_HELP_HEADER"]  = "RotaAssist 命令列表:"
L["SLASH_HELP_CONFIG"]  = "打开设置面板"
L["SLASH_HELP_TOGGLE"]  = "显示/隐藏循环助手"
L["SLASH_HELP_LOCK"]    = "锁定/解锁显示位置"
L["SLASH_HELP_RESET"]   = "重置所有设置为默认值"
L["SLASH_HELP_DEBUG"]   = "切换调试模式"
L["SLASH_HELP_VERSION"] = "显示版本信息"

------------------------------------------------------------------------
-- 设置 / 配置面板
------------------------------------------------------------------------
L["CONFIG_NOT_LOADED"]  = "设置面板尚未加载。"
L["SETTINGS_RESET"]     = "所有设置已重置为默认值。"
L["DEBUG_ENABLED"]      = "调试模式: 已开启"
L["DEBUG_DISABLED"]     = "调试模式: 已关闭"

L["CONFIG_HEADER_GENERAL"]    = "通用"
L["CONFIG_HEADER_DISPLAY"]    = "显示"
L["CONFIG_HEADER_COOLDOWNS"]  = "冷却追踪"
L["CONFIG_HEADER_ABOUT"]      = "关于"

L["CONFIG_ENABLED"]           = "启用 RotaAssist"
L["CONFIG_ENABLED_DESC"]      = "开启或关闭此插件。"
L["CONFIG_LANGUAGE"]          = "语言"
L["CONFIG_LANGUAGE_DESC"]     = "选择显示语言（需要 /reload 生效）。"
L["CONFIG_DEBUG"]             = "调试模式"
L["CONFIG_DEBUG_DESC"]        = "在聊天框显示调试信息。"
L["CONFIG_MINIMAP"]           = "显示小地图按钮"
L["CONFIG_MINIMAP_DESC"]      = "切换小地图图标显示。"

L["CONFIG_ICON_COUNT"]        = "图标数量"
L["CONFIG_ICON_COUNT_DESC"]   = "显示多少个预测技能图标 (1-5)。"
L["CONFIG_SCALE"]             = "缩放比例"
L["CONFIG_SCALE_DESC"]        = "整体显示缩放 (50% - 200%)。"
L["CONFIG_ALPHA"]             = "透明度"
L["CONFIG_ALPHA_DESC"]        = "显示透明度 (10% - 100%)。"
L["CONFIG_LOCK"]              = "锁定位置"
L["CONFIG_LOCK_DESC"]         = "阻止拖动显示框体。"
L["CONFIG_SHOW_OOC"]          = "脱战时显示"
L["CONFIG_SHOW_OOC_DESC"]     = "在非战斗状态下保持显示。"
L["CONFIG_FADE_OOC"]          = "脱战时淡出"
L["CONFIG_FADE_OOC_DESC"]     = "非战斗状态下降低透明度。"
L["CONFIG_KEYBINDS"]          = "显示快捷键"
L["CONFIG_KEYBINDS_DESC"]     = "在图标上显示按键绑定文字。"
L["CONFIG_COOLDOWN_SWIRL"]    = "显示冷却转圈"
L["CONFIG_COOLDOWN_SWIRL_DESC"] = "在图标上显示冷却旋转动画。"

L["CONFIG_CD_ENABLED"]        = "启用冷却面板"
L["CONFIG_CD_ENABLED_DESC"]   = "显示大招冷却追踪条。"
L["CONFIG_CD_SCALE"]          = "冷却面板缩放"
L["CONFIG_CD_SCALE_DESC"]     = "调整冷却追踪条的大小 (50% - 200%)。"
L["CONFIG_CD_LOCK"]           = "锁定冷却面板"
L["CONFIG_CD_LOCK_DESC"]      = "阻止拖动冷却面板。"

------------------------------------------------------------------------
-- 显示 / 界面
------------------------------------------------------------------------
L["DISPLAY_LOCKED"]           = "显示已锁定。"
L["DISPLAY_UNLOCKED"]         = "显示已解锁。拖动以调整位置。"
L["DISPLAY_ENABLED"]          = "循环助手已显示。"
L["DISPLAY_DISABLED"]         = "循环助手已隐藏。"

-- 右键菜单 (MainDisplay)
L["LOCK_POSITION"]            = "锁定位置"
L["UNLOCK_POSITION"]          = "解锁位置"
L["COMBAT_ONLY_TOOLTIP"]      = "仅战斗中显示"
L["OPTIONS"]                  = "选项"

-- 战斗前面板 (PrePullPanel 组件)
L["PREPULL_CHECKLIST"]        = "战斗前清单"
L["MISSING_ITEMS"]            = "缺少 %d 项"

------------------------------------------------------------------------
-- 冷却追踪
------------------------------------------------------------------------
L["CD_READY"]                 = "就绪"
L["CD_SECONDS"]               = "%d秒"
L["CD_MINUTES"]               = "%d:%02d"

------------------------------------------------------------------------
-- 提示信息
------------------------------------------------------------------------
L["TOOLTIP_SOURCE_BLIZZARD"]  = "来源: 暴雪推荐"
L["TOOLTIP_SOURCE_APL"]       = "来源: APL 预测"
L["TOOLTIP_SOURCE_COOLDOWN"]  = "来源: 冷却就绪"
L["TOOLTIP_CONFIDENCE"]       = "置信度: %d%%"
L["TOOLTIP_KEYBIND"]          = "快捷键: %s"
L["TOOLTIP_COOLDOWN"]         = "冷却时间: %s"
L["TOOLTIP_DRAG_HINT"]        = "左键拖动，右键打开选项。"
L["TOOLTIP_MINIMAP_LEFT"]     = "左键: 打开设置"
L["TOOLTIP_MINIMAP_RIGHT"]    = "右键: 切换显示"

------------------------------------------------------------------------
-- 关于
------------------------------------------------------------------------
L["ABOUT_DESCRIPTION"]        = "RotaAssist 是一款为 WoW 午夜 (12.0) 设计的智能战斗循环助手，是 Hekili 的替代品，支持多语言。"
L["ABOUT_VERSION"]            = "版本: %s"
L["ABOUT_AUTHOR"]             = "作者: RotaAssist 团队"
L["ABOUT_LICENSE"]            = "许可证: MIT"
L["ABOUT_WEBSITE"]            = "网站: github.com/yourname/rotaassist"

------------------------------------------------------------------------
-- 专精检测
------------------------------------------------------------------------
L["SPEC_DETECTED"]            = "检测到: %s %s (%s)"
L["SPEC_NO_APL"]              = "未找到当前专精的 APL 数据。"
L["SPEC_APL_LOADED"]          = "%s 的 APL 已加载。"

------------------------------------------------------------------------
-- 恶魔猎手 (Demon Hunter)
------------------------------------------------------------------------
-- 专精 (Specs)
L["spec_havoc"]               = "浩劫"
L["spec_vengeance"]           = "复仇"
L["spec_devourer"]            = "吞噬者"

-- 英雄天赋 (Hero Talents)
L["hero_aldrachi_reaver"]     = "阿尔德拉奇收割者"
L["hero_fel_scarred"]         = "邪痕"
L["hero_annihilator"]         = "湮灭者"
L["hero_void_scarred"]        = "虚空疤痕"

-- 技能 (Abilities)
L["EYE_BEAM"]                 = "眼棱"
L["BLADE_DANCE"]              = "刃舞"
L["DEATH_SWEEP"]              = "死亡横扫"
L["METAMORPHOSIS"]            = "恶魔变身"
L["THE_HUNT"]                 = "猎杀"
L["VENGEFUL_RETREAT"]         = "复仇回退"
L["ESSENCE_BREAK"]            = "精华爆裂"
L["GLAIVE_TEMPEST"]           = "飞刃风暴"
L["IMMOLATION_AURA"]          = "献祭光环"
L["FELBLADE"]                 = "邪刃"
L["FEL_RUSH"]                 = "邪能冲刺"
L["CHAOS_STRIKE"]             = "混沌打击"
L["ANNIHILATION"]             = "歼灭"
L["FIERY_BRAND"]              = "火焰烙印"
L["FEL_DEVASTATION"]          = "邪能毁灭"
L["SPIRIT_BOMB"]              = "灵魂炸弹"
L["SOUL_CARVER"]              = "灵魂雕刻"
L["SIGIL_OF_FLAME"]           = "火焰咒符"
L["FRACTURE"]                 = "碎裂"
L["SHEAR"]                    = "裂伤"
L["VOID_METAMORPHOSIS"]       = "虚空变身"
L["VOID_RAY"]                 = "虚空射线"
L["COLLAPSING_STAR"]          = "坍缩之星"
L["CONSUME"]                  = "吞噬"
L["DEVOUR"]                   = "吞噬"
L["REAP"]                     = "收割"
L["CULL"]                     = "杀戮"
L["VOIDBLADE"]                = "虚空之刃"
L["SOUL_IMMOLATION"]          = "灵魂献祭"
L["SHIFT"]                    = "位移"

-- 提示 (Hints)
L["HINT_EYE_BEAM_DEMONIC"]    = "使用眼棱进入恶魔形态"
L["HINT_VOID_RAY_FURY"]       = "100怒气时释放虚空射线"
L["HINT_COLLAPSING_STAR"]     = "30魂以上时释放坍缩之星"
L["HINT_REAP_STACKS"]         = "虚空坠落3层时收割"

------------------------------------------------------------------------
-- 智能推断引擎提示 (Smart AI Inference Tips)
------------------------------------------------------------------------
L["BURST_SOON_POOL_RESOURCE"] = "即将爆发 %d 秒 — 请预留能量！"
L["BURST_READY"]              = "爆发就绪！"
L["AOE_DETECTED"]             = "%d 目标被检测到 — 进行AoE阶段"
L["DEATH_SWEEP_NOTE"]         = "提示: Death Sweep 取代 Blade Dance"
L["RESOURCE_CAPPING"]         = "资源即将溢出！快用掉！"

-- Combat Phases
L["PREPULL"]                  = "开战准备"
L["OPENER"]                   = "起手"
L["NORMAL"]                   = "常规"
L["AOE"]                      = "群体"
L["BURST_PREPARE"]            = "即将爆发"
L["BURST_ACTIVE"]             = "爆发中!"
L["BURST_COOLDOWN"]           = "冷却中"
L["RESOURCE_STARVED"]         = "资源不足"
L["RESOURCE_CAP"]             = "资源溢出!"
L["EXECUTE"]                  = "斩杀"
L["EMERGENCY"]                = "危险!"

-- UI Toggles & Metrics
L["SHOW_ACCURACY_METER"]      = "显示准确率"
L["SHOW_PHASE_INDICATOR"]     = "显示阶段指示器"
L["ACCURACY"]                 = "准确率"
L["BLIZZARD_ACCURACY"]        = "暴雪推荐准确率"
L["SMART_ACCURACY"]           = "智能融合准确率"
