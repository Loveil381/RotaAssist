------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements Template
-- Template file for adding new classes to SpecEnhancements.
-- Do NOT add this file to the .toc; duplicate it to Name_Spec.lua and edit.
--
-- 【中】为新职业添加扩展数据的参照模板。不应被加载入插件。
-- 【英】Reference template for adding spec extension data. Should not be loaded.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

RA.SpecEnhancements = RA.SpecEnhancements or {}

------------------------------------------------------------------------
-- [ClassName] - [SpecName] (specID [123])
------------------------------------------------------------------------
-- Example: RA.SpecEnhancements[123] = { ... }
RA.SpecEnhancements[0] = {
    
    --- 【中】大招冷却追踪：在 CooldownBar 中显示。alertThreshold 控制边框转红的时机。
    --- 【英】Major Cooldowns: displayed in CooldownBar. alertThreshold triggers the red pulse border.
    majorCooldowns = {
        { spellID = 12345, alertThreshold = 10, name = "Example Big Cooldown" },
    },

    --- 【中】坦克主动减伤：与大招不同，这些技能即使在冷却中也始终在 CooldownBar 显示（充能类）。
    --- 【英】Active Mitigation (Tanks): Spells like Demon Spikes that show on the bar continuously.
    activeMitigation = {
        { spellID = 54321, name = "Example Shield", alwaysTrack = true, maxCharges = 2 }
    },

    --- 【中】防御技能与血线警告：血量低于 hpThreshold 时，在 DefensiveAlert 触发闪烁提示。
    --- 【英】Defensives: Triggers DefensiveAlert popup when player HP drops below hpThreshold (0.0-1.0).
    defensives = {
        { spellID = 98765, hpThreshold = 0.35, name = "Example Survival Instincts" },
    },

    --- 【中】资源类型和魔法消耗：用于 APLEngine 在预测模拟步数时推算剩余资源。
    --- 【英】Resource type and costs: Used by APLEngine to simulate resource availability steps ahead.
    resource = {
        -- Enum.PowerType (e.g. 0=Mana, 1=Rage, 3=Energy, 17=Fury)
        type      = 0,
        maxBase   = 100,
        spellCosts = {
            [11111] = { cost = 40  },  -- Cast consumes 40
            [22222] = { cost = 0   },  -- Free
            [33333] = { gen  = 15  },  -- Generates 15
        },
    },

    --- 【中】爆发期窗口：用于条件判定，如"如果在 Meta 爆发期中持续时间"。
    --- 【英】Burst Windows: For APL conditions relying on burst phase tracking.
    burstWindows = {
        burst1 = { trigger = 12345, duration = 20, label = "Example Burst Phase" }
    },

    --- 【中】开怪前消耗品检查：仅在战斗外检查并在 PrePullPanel 显示。
    --- 【英】Pre-Pull Checks: Out-of-combat consumable readiness, shown in PrePullPanel.
    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
        -- Optional weapon buff (e.g. Rogue poison or Shaman imbue)
        -- weapon = { type = "weapon", name = "Flametongue Weapon" }
    }
}
