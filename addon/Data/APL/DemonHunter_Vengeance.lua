------------------------------------------------------------------------
-- RotaAssist - APL: Demon Hunter / Vengeance  (specID 581)
-- Rotation priority for Vengeance Demon Hunter (Tank) in WoW 12.0.
-- Hero-talent variants: Aldrachi Reaver (default), Fel-Scarred.
--
-- ⚠  WoW 12.0 CONSTRAINTS:
--   • We CANNOT read aura / buff / health states in combat.
--   • We CAN  read whitelisted CD states via C_Spell.GetSpellCooldown().
--   • Tank APL focuses on CD readiness and defensive reminders.
--
-- CONDITION LANGUAGE (Phase 2):
--   cd_ready / cd_soon:X / always / estimated_resource >= X
--   after:SPELLID / not_in_meta / in_meta
--
-- 12.0.1 — last updated 2026-02-25
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

if not RA.APLData then
    RA.APLData = {}
end

------------------------------------------------------------------------
-- Metadata
------------------------------------------------------------------------
local APL             = {}
APL.specID            = 581
APL.specName          = "Vengeance"
APL.className         = "DEMONHUNTER"
APL.version           = "12.0.1"
APL.lastUpdated       = "2026-02-25"
APL.author            = "RotaAssist Team"

------------------------------------------------------------------------
-- PROFILES
------------------------------------------------------------------------
APL.profiles = {}

------------------------------------------------------------------------
--  DEFAULT  /  ALDRACHI REAVER  — Single-Target
------------------------------------------------------------------------
-- Tank rotation priorities:
--   Vengeance DH is about maintaining Fiery Brand uptime for damage
--   reduction, spending Soul Fragments with Spirit Bomb, and keeping
--   short-CD abilities rolling.  Metamorphosis is an emergency button.
--
-- 坦克循环说明：
--   复仇DH 核心是维持火焰烙印减伤、用灵魂炸弹消耗灵魂碎片、
--   保持短冷却技能持续使用。变身是紧急按钮。
--
-- タンクローテーション：
--   ヴェンジャンスDHはファイアリーブランドの維持（被ダメ軽減）、
--   スピリットボムでのソウルフラグメント消費、短CDスキルの回転が基本。
--   メタモルフォーシスは緊急ボタン。
------------------------------------------------------------------------

APL.profiles["default"] = {

    ------------------------------------
    -- SINGLE TARGET
    ------------------------------------
    singleTarget = {
        -- ① Fiery Brand — maintain for damage reduction
        -- 火焰烙印 — 保持减伤
        -- ファイアリーブランド — 被ダメ軽減を維持
        { spellID = 204021, cdSeconds = 60,
            priority  = 1,
            condition = "cd_ready",
            note      = "Maintain Fiery Brand for damage reduction uptime",
            displayPriority = 1,
            confidence = 0.9,
            tags = {"defensive", "sustain"},
        },

        -- ② Fel Devastation — healing + AoE damage
        -- 邪能毁灭 — 治疗 + 范围伤害
        -- フェルデヴァステーション — 回復＋AoEダメージ
        { spellID = 212084, cdSeconds = 60,
            priority  = 2,
            condition = "cd_ready",
            note      = "Core ability. Use on cooldown for healing and damage",
            displayPriority = 2,
            confidence = 0.95,
            tags = {"sustain", "defensive"},
        },

        -- ③ Spirit Bomb — with 4+ Soul Fragments (resource-gated)
        -- 灵魂炸弹 — 4+灵魂碎片时使用
        -- スピリットボム — ソウルフラグメント4つ以上で使用
        {
            spellID   = 247454,
            priority  = 3,
            condition = "estimated_resource >= 4",
            note      = "Spend with 4+ Soul Fragments for Frailty debuff",
            displayPriority = 3,
            confidence = 0.8,
            tags = {"sustain"},
        },

        -- ④ Soul Carver — Soul Fragment generation
        -- 灵魂雕刻 — 生成灵魂碎片
        -- ソウルカーバー — ソウルフラグメント生成
        { spellID = 207407, cdSeconds = 60,
            priority  = 4,
            condition = "cd_ready",
            note      = "Soul Fragment generator. Use on cooldown",
            displayPriority = 4,
            confidence = 0.9,
            tags = {"sustain"},
        },

        -- ⑤ Sigil of Flame — core AoE/DoT
        -- 火焰咒符 — 核心范围/持续伤害
        -- シジル・オブ・フレイム — コアAoE/DoT
        { spellID = 204596, cdSeconds = 30,
            priority  = 5,
            condition = "cd_ready",
            note      = "Core AoE/DoT. Use on cooldown",
            displayPriority = 5,
            confidence = 0.9,
            tags = {"sustain"},
        },

        -- ⑥ Immolation Aura — sustained damage + Fury
        -- 献祭光环 — 持续伤害 + 怒气
        -- イモレーション・オーラ — 持続ダメージ＋フューリー
        { spellID = 258920, cdSeconds = 30,
            priority  = 6,
            condition = "cd_ready",
            note      = "Sustained damage and Fury generation",
            displayPriority = 6,
            confidence = 0.9,
            tags = {"sustain"},
        },

        -- ⑦ Fracture — primary builder, 2 charges
        -- 碎裂 — 主要构建技能，2充能
        -- フラクチャー — メインビルダー、2チャージ
        { spellID = 263642, cdSeconds = 4.5,
            priority  = 7,
            condition = "cd_ready",
            note      = "Primary builder. 2 charges, generates Soul Fragments",
            displayPriority = 7,
            confidence = 0.85,
            tags = {"sustain", "builder"},
        },

        -- ⑧ The Hunt — damage + healing
        -- 猎杀 — 伤害 + 治疗
        -- ザ・ハント — ダメージ＋回復
        { spellID = 370965, cdSeconds = 90,
            priority  = 8,
            condition = "cd_ready",
            note      = "High-damage charge with healing component",
            displayPriority = 8,
            confidence = 0.85,
            tags = {"burst"},
        },

        -- ⑨ Felblade — gap closer + Soul gen
        -- 邪刃 — 突进 + 灵魂碎片
        -- フェルブレード — ギャップクローズ＋ソウル生成
        { spellID = 232893, cdSeconds = 15,
            priority  = 9,
            condition = "cd_ready",
            note      = "Gap closer and Soul Fragment generator",
            displayPriority = 9,
            confidence = 0.8,
            tags = {"sustain"},
        },

        -- ⑩ Shear — filler when Fracture is unavailable
        -- 裂伤 — 碎裂不可用时的填充
        -- シアー — フラクチャー不可時のフィラー
        {
            spellID   = 203782,
            priority  = 10,
            condition = "always",
            note      = "Filler when Fracture is on cooldown",
            displayPriority = 10,
            confidence = 0.6,
            tags = {"sustain", "builder"},
        },
    },

    ------------------------------------
    -- AOE (3+ targets)
    ------------------------------------
    -- AoE: Spirit Bomb is king, Sigil + Fel Dev for sustained damage
    -- AoE: 灵魂炸弹最优先，咒符+邪能毁灭持续
    -- AoE: スピリットボム最優先、シジル＋フェルデヴァ継続
    aoe = {
        { spellID = 247454, priority = 1, condition = "estimated_resource >= 4", targetCount = 3, note = "Spirit Bomb — always top in AoE",   displayPriority = 1, confidence = 0.9, tags = {"aoe"} },
        { spellID = 204596, cdSeconds = 30, priority = 2, condition = "cd_ready",                targetCount = 3, note = "Sigil of Flame",                    displayPriority = 2, confidence = 0.9, tags = {"aoe"} },
        { spellID = 212084, cdSeconds = 60, priority = 3, condition = "cd_ready",                targetCount = 3, note = "Fel Devastation",                   displayPriority = 3, confidence = 0.9, tags = {"aoe", "defensive"} },
        { spellID = 207407, cdSeconds = 60, priority = 4, condition = "cd_ready",                targetCount = 3, note = "Soul Carver — fragment gen",        displayPriority = 4, confidence = 0.85, tags = {"aoe"} },
        { spellID = 258920, cdSeconds = 30, priority = 5, condition = "cd_ready",                targetCount = 3, note = "Immolation Aura",                   displayPriority = 5, confidence = 0.85, tags = {"aoe"} },
        { spellID = 263642, cdSeconds = 4.5, priority = 6, condition = "cd_ready",                targetCount = 3, note = "Fracture — fragments",              displayPriority = 6, confidence = 0.8,  tags = {"aoe", "builder"} },
        { spellID = 203782, priority = 7, condition = "always",                  targetCount = 3, note = "Shear — filler",                    displayPriority = 7, confidence = 0.5,  tags = {"aoe", "builder"} },
    },

    ------------------------------------
    -- OPENER (pull sequence)
    ------------------------------------
    opener = {
        { spellID = 204596, cdSeconds = 30, step = 1, note = "Sigil of Flame — pre-place on boss" },
        { spellID = 258920, cdSeconds = 30, step = 2, note = "Immolation Aura — immediate aggro" },
        { spellID = 212084, cdSeconds = 60, step = 3, note = "Fel Devastation — opening burst + heal" },
        { spellID = 204021, cdSeconds = 60, step = 4, note = "Fiery Brand — establish mitigation" },
        { spellID = 263642, cdSeconds = 4.5, step = 5, note = "Fracture — start Soul gen" },
    },

    ------------------------------------
    -- MAJOR COOLDOWNS / DEFENSIVE REMINDERS
    ------------------------------------
    -- We cannot read health, but we CAN track CD readiness.
    -- The UI will show these as "available" reminders.
    -- 我们无法读取血量，但可以追踪CD状态
    -- 体力は読めないが、CD状態は追跡可能
    majorCooldowns = {
        { spellID = 187827, cdSeconds = 180, note = "Metamorphosis — emergency defensive. Manual only" },
        { spellID = 204021, cdSeconds = 60, note = "Fiery Brand — track uptime for mitigation" },
    },
}

-- Aldrachi Reaver is the default — alias it
APL.profiles["aldrachi_reaver"] = APL.profiles["default"]

------------------------------------------------------------------------
--  FEL-SCARRED VARIANT
------------------------------------------------------------------------
-- Differences from Aldrachi Reaver:
--   • Slightly more emphasis on Demonic synergy abilities
--   • Otherwise identical tank priority
--
-- 邪痕变体 — 与阿尔德拉奇收割者基本相同
-- フェルスカード — アルドラキ・リーバーとほぼ同一
------------------------------------------------------------------------

APL.profiles["fel_scarred"] = {
    singleTarget   = APL.profiles["default"].singleTarget,
    aoe            = APL.profiles["default"].aoe,
    opener         = APL.profiles["default"].opener,
    majorCooldowns = APL.profiles["default"].majorCooldowns,
}

------------------------------------------------------------------------
-- Phase 1 backward-compat: flatten singleTarget into flat `rules`
------------------------------------------------------------------------
local defaultProfile = APL.profiles["default"]
local rules = {}
if defaultProfile and defaultProfile.singleTarget then
    for _, entry in ipairs(defaultProfile.singleTarget) do
        rules[#rules + 1] = {
            spellID   = entry.spellID,
            name      = entry.note or ("Spell#" .. entry.spellID),
            priority  = entry.priority,
            condition = (entry.condition == "always") and "always" or "ready",
            reason    = entry.note or "",
        }
    end
end

------------------------------------------------------------------------
-- Register with the global APL data table
------------------------------------------------------------------------
RA.APLData[581] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
