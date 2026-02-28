------------------------------------------------------------------------
-- RotaAssist - APL: Demon Hunter / Havoc  (specID 577)
-- Rotation priority for Havoc Demon Hunter in WoW 12.0 Midnight.
-- Hero-talent variants: Aldrachi Reaver (default), Fel-Scarred.
--
-- ⚠  WoW 12.0 CONSTRAINTS:
--   • We CANNOT read aura / buff states in combat.
--   • We CAN  read whitelisted CD states via C_Spell.GetSpellCooldown().
--   • We CAN  see the Blizzard Assisted Highlight spell.
--   • Our APL predictions are SUPPLEMENTARY to Blizzard's recommendation.
--
-- CONDITION LANGUAGE (Phase 2 expressions):
--   cd_ready        — spell is off cooldown
--   cd_soon:X       — ready within X sec
--   always          — always suggest (filler)
--   estimated_resource >= X — rough Fury estimate
--   after:SPELLID   — suggest after another spell was recommended
--   not_in_meta     — estimated NOT in Metamorphosis
--   in_meta         — estimated IN  Metamorphosis
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
APL.specID            = 577
APL.specName          = "Havoc"
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
-- Design notes:
--   Havoc revolves around short-CD abilities that chain together.
--   Eye Beam triggers Demonic (free Metamorphosis), so it is high
--   priority.  Blade Dance becomes Death Sweep inside Meta and
--   should be used on cooldown.  Essence Break creates a burst
--   window if talented.
--
-- 设计说明：
--   浩劫 DH 以短冷却技能链为核心。
--   眼棱触发恶魔化（免费变身），所以优先级很高。
--   刃舞在变身中变为死亡横扫，应该冷却好就用。
--
-- 設計メモ：
--   ハボックDHは短CDスキル連携が基本。
--   アイビームがデモニック（無料メタモルフォーシス）を発動するため
--   優先度が高い。ブレードダンスはメタ中にデススウィープになる。
------------------------------------------------------------------------

APL.profiles["default"] = {

    ------------------------------------
    -- SINGLE TARGET
    ------------------------------------
    singleTarget = {
        -- ① Metamorphosis — manual-only big CD reminder
        -- 变身 — 仅提醒，手动激活
        -- メタモルフォーシス — 手動リマインダー
        { spellID = 191427, cdSeconds = 240,
            cdSeconds = 240,
            priority  = 1,
            condition = "cd_ready AND not_in_meta",
            note      = "Major CD. Manual activation — press when ready for burst",
            displayPriority = 1,
            confidence = 0.6,
            tags = {"burst", "major"},
        },

        -- ② The Hunt — use on cooldown
        -- 猎杀 — 冷却好就用
        -- ザ・ハント — CDごとに使用
        { spellID = 370965, cdSeconds = 90,
            cdSeconds = 90,
            priority  = 2,
            condition = "cd_ready",
            note      = "High-damage charge. Use on cooldown for burst",
            displayPriority = 2,
            confidence = 0.9,
            tags = {"burst"},
        },

        -- ③ Vengeful Retreat — triggers Initiative talent
        -- 复仇回退 — 触发先手天赋
        -- ヴェンジフルリトリート — イニシアチブ発動
        { spellID = 198793, cdSeconds = 25,
            cdSeconds = 25,
            priority  = 3,
            condition = "cd_ready",
            note      = "Triggers Initiative (Mastery window). Use before builders",
            displayPriority = 3,
            confidence = 0.85,
            tags = {"movement", "burst"},
        },

        -- ④ Eye Beam — core rotational, triggers Demonic
        -- 眼棱 — 核心循环技能，触发恶魔形态
        -- アイビーム — コアローテーション、デモニック発動
        { spellID = 198013, cdSeconds = 30,
            cdSeconds = 30,
            priority  = 4,
            condition = "cd_ready",
            note      = "Use on cooldown to trigger Demonic form",
            displayPriority = 4,
            confidence = 0.95,
            tags = {"sustain"},
        },

        -- ⑤ Essence Break — burst window after Eye Beam
        -- 精华爆裂 — 眼棱后使用，爆发窗口
        -- エッセンスブレイク — アイビーム後のバーストウィンドウ
        { spellID = 258860, cdSeconds = 10,
            cdSeconds = 10,
            priority  = 5,
            condition = "cd_ready AND after:198013",
            note      = "Use after Eye Beam for burst window (if talented)",
            displayPriority = 5,
            confidence = 0.85,
            tags = {"burst"},
        },

        -- ⑥ Blade Dance / Death Sweep — on cooldown (higher value in Meta)
        -- 刃舞/死亡横扫 — 冷却好就用（变身中优先）
        -- ブレードダンス / デススウィープ — CDごとに使用（メタ中優先）
        { spellID = 188499, cdSeconds = 9,
            cdSeconds = 9,
            priority  = 6,
            condition = "cd_ready",
            note      = "Core rotational. Becomes Death Sweep in Metamorphosis",
            displayPriority = 6,
            confidence = 0.95,
            tags = {"sustain"},
        },

        -- ⑦ Glaive Tempest — AoE burst if talented
        -- 飞刃风暴 — 如果有天赋，冷却好就用
        -- グレイヴテンペスト — タレントあればCDごと
        { spellID = 342817, cdSeconds = 20,
            cdSeconds = 20,
            priority  = 7,
            condition = "cd_ready",
            note      = "AoE burst if talented. Good even in ST",
            displayPriority = 7,
            confidence = 0.8,
            tags = {"burst", "aoe"},
        },

        -- ⑧ Immolation Aura — Fury generation
        -- 献祭光环 — 怒气生成
        -- イモレーション・オーラ — フューリー生成
        { spellID = 258920, cdSeconds = 30,
            cdSeconds = 30,
            priority  = 8,
            condition = "cd_ready",
            note      = "Fury generation. Use on cooldown",
            displayPriority = 8,
            confidence = 0.9,
            tags = {"sustain"},
        },

        -- ⑨ Felblade — Fury gen / gap closer
        -- 邪刃 — 怒气生成/突进
        -- フェルブレード — フューリー生成＆ギャップクローズ
        { spellID = 232893, cdSeconds = 15,
            cdSeconds = 15,
            priority  = 9,
            condition = "cd_ready",
            note      = "Fury generator and gap closer",
            displayPriority = 9,
            confidence = 0.85,
            tags = {"sustain"},
        },

        -- ⑩ Fel Rush — movement + Unbound Chaos damage
        -- 邪能冲刺 — 移动 + 解缚混沌伤害
        -- フェルラッシュ — 移動＆ダメージ
        { spellID = 195072, cdSeconds = 10,
            cdSeconds = 10,
            priority  = 10,
            condition = "cd_ready",
            note      = "Movement/damage. 2 charges. Use for Unbound Chaos procs",
            displayPriority = 10,
            confidence = 0.7,
            tags = {"movement"},
        },

        -- ⑪ Chaos Strike / Annihilation — Fury dump filler
        -- 混沌打击/歼灭 — 消耗怒气的填充技能
        -- ケイオスストライク/アナイアレーション — フューリーダンプ
        {
            spellID   = 162794,
            priority  = 11,
            condition = "always",
            note      = "Fury spender filler. Becomes Annihilation in Meta",
            displayPriority = 11,
            confidence = 0.7,
            tags = {"sustain"},
        },
    },

    ------------------------------------
    -- AOE (3+ targets)
    ------------------------------------
    -- AoE 优先级（3+目标）
    -- AoE優先度（3体以上）
    aoe = {
        { spellID = 198013, cdSeconds = 30, priority = 1, condition = "cd_ready",  targetCount = 3, note = "Eye Beam — AoE king",          displayPriority = 1, confidence = 0.95, tags = {"aoe"} },
        { spellID = 188499, cdSeconds = 9, priority = 2, condition = "cd_ready",  targetCount = 3, note = "Blade Dance — immediate AoE",  displayPriority = 2, confidence = 0.95, tags = {"aoe"} },
        { spellID = 342817, cdSeconds = 20, priority = 3, condition = "cd_ready",  targetCount = 3, note = "Glaive Tempest — sustained AoE", displayPriority = 3, confidence = 0.9, tags = {"aoe"} },
        { spellID = 258920, cdSeconds = 30, priority = 4, condition = "cd_ready",  targetCount = 3, note = "Immolation Aura — Fury gen",   displayPriority = 4, confidence = 0.9, tags = {"aoe"} },
        { spellID = 195072, cdSeconds = 10, priority = 5, condition = "cd_ready",  targetCount = 3, note = "Fel Rush — Unbound Chaos",     displayPriority = 5, confidence = 0.75, tags = {"aoe", "movement"} },
        { spellID = 162794, priority = 6, condition = "always",    targetCount = 3, note = "Chaos Strike — Fury dump",     displayPriority = 6, confidence = 0.65, tags = {"aoe"} },
    },

    ------------------------------------
    -- OPENER
    ------------------------------------
    -- 起手循环
    -- オープナーローテーション
    opener = {
        { spellID = 370965, cdSeconds = 90, step = 1, note = "The Hunt — on pull charge" },
        { spellID = 258920, cdSeconds = 30, step = 2, note = "Immolation Aura — immediate Fury" },
        { spellID = 198013, cdSeconds = 30, step = 3, note = "Eye Beam — trigger Demonic" },
        { spellID = 258860, cdSeconds = 10, step = 4, note = "Essence Break — burst window (if talented)" },
        { spellID = 188499, cdSeconds = 9, step = 5, note = "Blade Dance / Death Sweep" },
    },

    ------------------------------------
    -- MAJOR COOLDOWNS (manual reminders)
    ------------------------------------
    majorCooldowns = {
        { spellID = 191427, cdSeconds = 240, note = "Metamorphosis — manual activation. Align with burst" },
    },
}

-- Aldrachi Reaver is the default — alias it
APL.profiles["aldrachi_reaver"] = APL.profiles["default"]

------------------------------------------------------------------------
--  FEL-SCARRED VARIANT
------------------------------------------------------------------------
-- Differences from Aldrachi Reaver:
--   • Student of Suffering: Mastery window after Metamorphosis matters
--     more, so Meta timing is slightly more important.
--   • Demonic Intensity: Eye Beam channels longer, so don't clip it.
--   • Everything else is similar in priority.
--
-- 邪痕变体说明：
--   痛苦学徒: 变身后的精通窗口更重要。
--   恶魔强度: 眼棱引导时间更长，注意不要打断。
--
-- フェルスカード変種メモ：
--   苦痛の修練: メタモル後のマスタリーウィンドウが重要。
--   デモニック・インテンシティ: アイビーム詠唱延長、中断しないこと。
------------------------------------------------------------------------

APL.profiles["fel_scarred"] = {

    singleTarget = {
        -- Meta moves up slightly in importance for Student of Suffering
        { spellID = 191427, cdSeconds = 240, priority = 1, condition = "cd_ready AND not_in_meta", note = "Metamorphosis — Student of Suffering Mastery window", displayPriority = 1, confidence = 0.7, tags = {"burst", "major"} },
        { spellID = 370965, cdSeconds = 90, priority = 2, condition = "cd_ready",                 note = "The Hunt",                                           displayPriority = 2, confidence = 0.9, tags = {"burst"} },
        { spellID = 198793, cdSeconds = 25, priority = 3, condition = "cd_ready",                 note = "Vengeful Retreat — Initiative",                      displayPriority = 3, confidence = 0.85, tags = {"movement", "burst"} },
        -- Eye Beam: longer channel with Demonic Intensity — respect the cast
        { spellID = 198013, cdSeconds = 30, priority = 4, condition = "cd_ready",                 note = "Eye Beam — DO NOT CLIP (Demonic Intensity)",         displayPriority = 4, confidence = 0.95, tags = {"sustain"} },
        { spellID = 258860, cdSeconds = 10, priority = 5, condition = "cd_ready AND after:198013", note = "Essence Break after Eye Beam",                      displayPriority = 5, confidence = 0.85, tags = {"burst"} },
        { spellID = 188499, cdSeconds = 9, priority = 6, condition = "cd_ready",                 note = "Blade Dance / Death Sweep",                          displayPriority = 6, confidence = 0.95, tags = {"sustain"} },
        { spellID = 342817, cdSeconds = 20, priority = 7, condition = "cd_ready",                 note = "Glaive Tempest",                                     displayPriority = 7, confidence = 0.8,  tags = {"burst", "aoe"} },
        { spellID = 258920, cdSeconds = 30, priority = 8, condition = "cd_ready",                 note = "Immolation Aura",                                    displayPriority = 8, confidence = 0.9,  tags = {"sustain"} },
        { spellID = 232893, cdSeconds = 15, priority = 9, condition = "cd_ready",                 note = "Felblade",                                           displayPriority = 9, confidence = 0.85, tags = {"sustain"} },
        { spellID = 195072, cdSeconds = 10, priority = 10, condition = "cd_ready",                note = "Fel Rush",                                           displayPriority = 10, confidence = 0.7, tags = {"movement"} },
        { spellID = 162794, priority = 11, condition = "always",                  note = "Chaos Strike / Annihilation — filler",               displayPriority = 11, confidence = 0.7, tags = {"sustain"} },
    },

    aoe     = APL.profiles["default"] and APL.profiles["default"].aoe or {},
    opener  = APL.profiles["default"] and APL.profiles["default"].opener or {},
    majorCooldowns = APL.profiles["default"] and APL.profiles["default"].majorCooldowns or {},
}

------------------------------------------------------------------------
-- Phase 1 backward-compat: flatten singleTarget into a flat `rules` array
-- so the current APLEngine can consume it as-is.
------------------------------------------------------------------------
local defaultProfile = APL.profiles["default"]
local rules = {}
if defaultProfile and defaultProfile.singleTarget then
    for _, entry in ipairs(defaultProfile.singleTarget) do
        rules[#rules + 1] = {
            spellID   = entry.spellID,
            name      = entry.note or ("Spell#" .. entry.spellID),
            priority  = entry.priority,
            condition = entry.condition or "always",
            reason    = entry.note or "",
        }
    end
end

------------------------------------------------------------------------
-- Register with the global APL data table
------------------------------------------------------------------------
RA.APLData[577] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,          -- Phase 1 flat list
    profiles = APL.profiles,   -- Phase 2 rich profiles
}
