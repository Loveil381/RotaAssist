------------------------------------------------------------------------
-- RotaAssist - APL: Demon Hunter / Devourer  (specID 1480)
-- Rotation priority for the NEW Devourer DH spec in WoW 12.0 Midnight.
-- Hero-talent variants: Annihilator (default), Void-Scarred.
--
-- ⚠  IMPORTANT — DEVOURER SPELL-ID VERIFICATION:
--   The Devourer spec was added in Midnight (12.0).  Some spellIDs in
--   this file are based on early datamining and may differ on the live
--   12.0.1 servers.  Please verify against Wowhead / the live API
--   with /dump C_Spell.GetSpellInfo(SPELLID) and update accordingly.
--
-- ⚠  WoW 12.0 CONSTRAINTS:
--   • We CANNOT read aura / buff / Void Soul count in combat.
--   • We CAN  read whitelisted CD states via C_Spell.GetSpellCooldown().
--   • Void Metamorphosis is resource-gated (50 Souls), not a timed CD.
--     We estimate entry based on time elapsed and casts made.
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
APL.specID            = 1480
APL.specName          = "Devourer"
APL.className         = "DEMONHUNTER"
APL.version           = "12.0.1"
APL.lastUpdated       = "2026-02-25"
APL.author            = "RotaAssist Team"

------------------------------------------------------------------------
-- PROFILES
------------------------------------------------------------------------
APL.profiles = {}

------------------------------------------------------------------------
--  DEFAULT  /  ANNIHILATOR
------------------------------------------------------------------------
-- Devourer operates in two distinct phases:
--
-- PHASE A — OUTSIDE Void Metamorphosis
--   Build Souls via Reap, Soul Immolation, and combat.  Once at 50
--   Souls, Void Metamorphosis becomes castable.
--
-- PHASE B — INSIDE Void Metamorphosis
--   Souls drain over time.  Void Ray becomes your main rotational,
--   Collapsing Star is a massive AoE nuke (costs 30 Souls), and
--   Devour is the filler that collects Souls to sustain the form.
--
-- 吞噬者运作分两个阶段：
--   阶段A — 虚空变身外: 积攒灵魂碎片到50，然后可以变身。
--   阶段B — 虚空变身中: 灵魂持续流失，虚空射线是主力技能，
--                       坍缩之星是大范围爆发，吞噬是填充技能。
--
-- デヴァウラーは2つのフェーズで動作:
--   フェーズA — ヴォイドメタ外: ソウルを50まで溜めて変身可能に。
--   フェーズB — ヴォイドメタ中: ソウルが減少、ヴォイドレイがメイン、
--                               コラプシングスターが大AoE、デヴァウアがフィラー。
------------------------------------------------------------------------

APL.profiles["default"] = {

    ------------------------------------
    -- SINGLE TARGET — OUTSIDE Void Meta (Phase A)
    ------------------------------------
    -- 虚空变身外 — 积攒灵魂
    -- ヴォイドメタ外 — ソウル蓄積
    singleTarget = {
        -- ① Soul Immolation — resource generation on cooldown
        -- 灵魂献祭 — 冷却好就用，资源生成
        -- ソウルイモレーション — CDごとに使用、リソース生成
        { spellID = 442525, cdSeconds = 15,
            priority  = 1,
            condition = "cd_ready AND not_in_meta",
            note      = "Soul Immolation — resource gen, self-damage. Use on CD",
            displayPriority = 1,
            confidence = 0.85,
            tags = {"sustain"},
        },

        -- ② Voidblade — melee leap combo initiator
        -- 虚空之刃 — 近战跳跃，连击起手
        -- ヴォイドブレード — 近接リープ、コンボ開始
        { spellID = 442520, cdSeconds = 15,
            priority  = 2,
            condition = "cd_ready AND not_in_meta",
            note      = "Melee leap. Use to initiate combos",
            displayPriority = 2,
            confidence = 0.85,
            tags = {"movement", "burst"},
        },

        -- ③ The Hunt — high-damage charge
        -- 猎杀 — 高伤害冲锋
        -- ザ・ハント — 高ダメージチャージ
        { spellID = 370965, cdSeconds = 90,
            priority  = 3,
            condition = "cd_ready",
            note      = "The Hunt — high damage. Use on cooldown",
            displayPriority = 3,
            confidence = 0.9,
            tags = {"burst"},
        },

        -- ④ Reap — consume Voidfall stacks (estimated at 3)
        -- 收割 — 消耗虚空坠落层数（估计3层时使用）
        -- リープ — ヴォイドフォールスタック消費（推定3スタック時）
        { spellID = 442515, cdSeconds = 10,
            priority  = 4,
            condition = "cd_ready",
            note      = "Reap — Soul consumer. Best at 3 Voidfall stacks (estimated)",
            displayPriority = 4,
            confidence = 0.75,
            tags = {"sustain"},
        },

        -- ⑤ Void Ray — at 100 Fury (resource-gated outside Meta)
        -- 虚空射线 — 100怒气时使用（变身外资源消耗）
        -- ヴォイドレイ — フューリー100で使用（メタ外リソース消費）
        { spellID = 442507, cdSeconds = 16,
            priority  = 5,
            condition = "estimated_resource >= 100 AND not_in_meta",
            note      = "Void Ray — costs 100 Fury outside Void Meta",
            displayPriority = 5,
            confidence = 0.7,
            tags = {"sustain"},
        },

        -- ⑥ Vengeful Retreat — movement / utility
        -- 复仇回退 — 移动/实用
        -- ヴェンジフルリトリート — 移動/ユーティリティ
        { spellID = 198793, cdSeconds = 25,
            priority  = 6,
            condition = "cd_ready AND not_in_meta",
            note      = "Vengeful Retreat — movement utility",
            displayPriority = 6,
            confidence = 0.7,
            tags = {"movement"},
        },

        -- ⑦ Shift — dash, 2-3 charges
        -- 位移 — 冲刺，2-3充能
        -- シフト — ダッシュ、2-3チャージ
        { spellID = 442530, cdSeconds = 10,
            priority  = 7,
            condition = "cd_ready",
            note      = "Shift — dash with 2-3 charges. Use for repositioning",
            displayPriority = 7,
            confidence = 0.6,
            tags = {"movement"},
        },

        -- ⑧ Consume — filler, always castable
        -- 吞噬 — 填充技能，随时可用
        -- コンシューム — フィラー、常に使用可能
        {
            spellID   = 442501,
            priority  = 8,
            condition = "always",
            note      = "Consume — filler. Always castable, mobile, instant",
            displayPriority = 8,
            confidence = 0.6,
            tags = {"sustain"},
        },
    },

    ------------------------------------
    -- SINGLE TARGET — INSIDE Void Meta (Phase B)
    ------------------------------------
    -- These rules apply when we estimate the player is inside
    -- Void Metamorphosis. The APLEngine Phase 2 will select the
    -- correct sub-table based on estimated state.
    --
    -- 虚空变身中的优先级
    -- ヴォイドメタ中の優先度
    voidMeta = {
        -- ① Collapsing Star — massive nuke, costs 30 Souls
        -- 坍缩之星 — 巨大爆发，消耗30灵魂
        -- コラプシングスター — 大ダメージ、30ソウル消費
        {
            spellID   = 442510,
            priority  = 1,
            condition = "in_meta AND estimated_resource >= 30",
            note      = "Collapsing Star — 30 Soul cost. Massive AoE nuke",
            displayPriority = 1,
            confidence = 0.8,
            tags = {"burst", "aoe"},
        },

        -- ② Void Ray — on cooldown (16s hasted CD in Meta)
        -- 虚空射线 — 冷却好就用（变身中16秒CD）
        -- ヴォイドレイ — CDごとに使用（メタ中16秒CD）
        { spellID = 442507, cdSeconds = 16,
            priority  = 2,
            condition = "cd_ready AND in_meta",
            note      = "Void Ray — 16s hasted CD inside Void Meta. Core rotational",
            displayPriority = 2,
            confidence = 0.9,
            tags = {"sustain"},
        },

        -- ③ Reap — after 2-3 Devour casts (Soul collection)
        -- 收割 — 2-3次吞噬后使用（收集灵魂）
        -- リープ — デヴァウア2-3回後に使用（ソウル収集）
        { spellID = 442515, cdSeconds = 10,
            priority  = 3,
            condition = "cd_ready AND in_meta",
            note      = "Reap/Cull — use after 2-3 Devour casts for Soul burst",
            displayPriority = 3,
            confidence = 0.75,
            tags = {"sustain"},
        },

        -- ④ Voidblade — if Voidrush talented (pauses Soul drain)
        -- 虚空之刃 — 如有虚空冲能天赋（暂停灵魂流失）
        -- ヴォイドブレード — ヴォイドラッシュタレント時（ソウル減少停止）
        { spellID = 442520, cdSeconds = 15,
            priority  = 4,
            condition = "cd_ready AND in_meta",
            note      = "Voidblade — if Voidrush talented, pauses Soul drain",
            displayPriority = 4,
            confidence = 0.7,
            tags = {"burst", "movement"},
        },

        -- ⑤ Consume / Devour — filler between cooldowns
        -- 吞噬 — 冷却间的填充
        -- デヴァウア — CDの合間のフィラー
        {
            spellID   = 442501,
            priority  = 5,
            condition = "always",
            note      = "Consume/Devour — filler between cooldowns. Collects Souls",
            displayPriority = 5,
            confidence = 0.6,
            tags = {"sustain"},
        },
    },

    ------------------------------------
    -- AOE (3+ targets)
    ------------------------------------
    -- AoE: Collapsing Star becomes top priority (massive AoE)
    -- AoE: 坍缩之星成为最高优先（大范围伤害）
    -- AoE: コラプシングスターが最優先（大AoE）
    aoe = {
        { spellID = 442510, priority = 1, condition = "in_meta AND estimated_resource >= 30", targetCount = 3, note = "Collapsing Star — AoE nuke",         displayPriority = 1, confidence = 0.85, tags = {"aoe", "burst"} },
        { spellID = 442507, cdSeconds = 16, priority = 2, condition = "cd_ready",                             targetCount = 3, note = "Void Ray — aggressive use in AoE",   displayPriority = 2, confidence = 0.85, tags = {"aoe"} },
        { spellID = 442525, cdSeconds = 15, priority = 3, condition = "cd_ready",                             targetCount = 3, note = "Soul Immolation — resource gen",     displayPriority = 3, confidence = 0.8,  tags = {"aoe"} },
        { spellID = 442515, cdSeconds = 10, priority = 4, condition = "cd_ready",                             targetCount = 3, note = "Reap — Soul burst AoE",              displayPriority = 4, confidence = 0.75, tags = {"aoe"} },
        { spellID = 442520, cdSeconds = 15, priority = 5, condition = "cd_ready",                             targetCount = 3, note = "Voidblade — leap AoE",               displayPriority = 5, confidence = 0.7,  tags = {"aoe", "movement"} },
        { spellID = 442501, priority = 6, condition = "always",                               targetCount = 3, note = "Consume — filler",                   displayPriority = 6, confidence = 0.5,  tags = {"aoe"} },
    },

    ------------------------------------
    -- OPENER
    ------------------------------------
    -- 起手循环
    -- オープナーローテーション
    opener = {
        { spellID = 442525, cdSeconds = 15, step = 1, note = "Soul Immolation — pre-pull resource gen" },
        { spellID = 370965, cdSeconds = 90, step = 2, note = "The Hunt — on-pull charge" },
        { spellID = 442520, cdSeconds = 15, step = 3, note = "Voidblade — melee leap" },
        { spellID = 442515, cdSeconds = 10, step = 4, note = "Reap — early Soul burst" },
        { spellID = 442507, cdSeconds = 16, step = 5, note = "Void Ray — first Fury dump" },
    },

    ------------------------------------
    -- MAJOR COOLDOWNS (manual reminders)
    ------------------------------------
    majorCooldowns = {
        { spellID = 442508, note = "Void Metamorphosis — resource-gated (50 Souls), NOT a timed CD. Manual activation" },
    },
}

-- Annihilator is the default — alias it
APL.profiles["annihilator"] = APL.profiles["default"]

------------------------------------------------------------------------
--  VOID-SCARRED VARIANT
------------------------------------------------------------------------
-- Differences from Annihilator:
--   • Skips Collapsing Star in pure ST (save Souls for Meta duration)
--   • More emphasis on Devour spam for Eradicate procs
--   • Voidblade + Hungering Slash combo more important
--   • Eradicate proc usage after Void Ray
--
-- 虚空疤痕变体说明：
--   纯单体跳过坍缩之星（保留灵魂延长变身）。
--   更注重吞噬连击触发根除效果。
--   虚空之刃+饥渴斩击组合更重要。
--
-- ヴォイドスカード変種メモ：
--   純STではコラプシングスターをスキップ（ソウル温存）。
--   デヴァウア連打でエラディケートプロック重視。
--   ヴォイドブレード＋ハンガリングスラッシュコンボがより重要。
------------------------------------------------------------------------

APL.profiles["void_scarred"] = {

    singleTarget = {
        -- Outside Meta: same general priority, emphasize Voidblade
        { spellID = 442520, cdSeconds = 15, priority = 1, condition = "cd_ready AND not_in_meta",                note = "Voidblade — Hungering Slash combo initiator",   displayPriority = 1, confidence = 0.85, tags = {"burst", "movement"} },
        { spellID = 442525, cdSeconds = 15, priority = 2, condition = "cd_ready AND not_in_meta",                note = "Soul Immolation — resource gen",                displayPriority = 2, confidence = 0.85, tags = {"sustain"} },
        { spellID = 370965, cdSeconds = 90, priority = 3, condition = "cd_ready",                                note = "The Hunt",                                      displayPriority = 3, confidence = 0.9,  tags = {"burst"} },
        { spellID = 442515, cdSeconds = 10, priority = 4, condition = "cd_ready",                                note = "Reap — Soul consumer",                          displayPriority = 4, confidence = 0.75, tags = {"sustain"} },
        { spellID = 442507, cdSeconds = 16, priority = 5, condition = "estimated_resource >= 100 AND not_in_meta", note = "Void Ray — Fury dump + Eradicate proc",       displayPriority = 5, confidence = 0.7,  tags = {"sustain"} },
        { spellID = 198793, cdSeconds = 25, priority = 6, condition = "cd_ready AND not_in_meta",                note = "Vengeful Retreat",                               displayPriority = 6, confidence = 0.7,  tags = {"movement"} },
        { spellID = 442530, cdSeconds = 10, priority = 7, condition = "cd_ready",                                note = "Shift — dash",                                  displayPriority = 7, confidence = 0.6,  tags = {"movement"} },
        { spellID = 442501, priority = 8, condition = "always",                                  note = "Consume — filler, Eradicate proc fishing",      displayPriority = 8, confidence = 0.6,  tags = {"sustain"} },
    },

    -- Void Meta phase: skip Collapsing Star in pure ST, more Devour spam
    voidMeta = {
        -- No Collapsing Star in ST for Void-Scarred (save Souls)
        { spellID = 442507, cdSeconds = 16, priority = 1, condition = "cd_ready AND in_meta",      note = "Void Ray — core + Eradicate proc",       displayPriority = 1, confidence = 0.9,  tags = {"sustain"} },
        { spellID = 442520, cdSeconds = 15, priority = 2, condition = "cd_ready AND in_meta",      note = "Voidblade — Voidrush pauses drain",       displayPriority = 2, confidence = 0.8,  tags = {"burst", "movement"} },
        { spellID = 442515, cdSeconds = 10, priority = 3, condition = "cd_ready AND in_meta",      note = "Reap — Soul burst",                       displayPriority = 3, confidence = 0.75, tags = {"sustain"} },
        { spellID = 442501, priority = 4, condition = "always",                    note = "Consume/Devour — spam for Eradicate procs", displayPriority = 4, confidence = 0.65, tags = {"sustain"} },
    },

    -- AoE: Collapsing Star DOES get used in AoE even for Void-Scarred
    -- 范围战斗中，即使虚空疤痕也使用坍缩之星
    -- AoEではヴォイドスカードでもコラプシングスターを使用
    aoe = {
        { spellID = 442510, priority = 1, condition = "in_meta AND estimated_resource >= 30", targetCount = 3, note = "Collapsing Star — AoE even for VS",  displayPriority = 1, confidence = 0.85, tags = {"aoe", "burst"} },
        { spellID = 442507, cdSeconds = 16, priority = 2, condition = "cd_ready",                             targetCount = 3, note = "Void Ray — aggressive AoE",          displayPriority = 2, confidence = 0.85, tags = {"aoe"} },
        { spellID = 442525, cdSeconds = 15, priority = 3, condition = "cd_ready",                             targetCount = 3, note = "Soul Immolation",                    displayPriority = 3, confidence = 0.8,  tags = {"aoe"} },
        { spellID = 442515, cdSeconds = 10, priority = 4, condition = "cd_ready",                             targetCount = 3, note = "Reap",                               displayPriority = 4, confidence = 0.75, tags = {"aoe"} },
        { spellID = 442520, cdSeconds = 15, priority = 5, condition = "cd_ready",                             targetCount = 3, note = "Voidblade",                          displayPriority = 5, confidence = 0.7,  tags = {"aoe", "movement"} },
        { spellID = 442501, priority = 6, condition = "always",                               targetCount = 3, note = "Consume — filler",                   displayPriority = 6, confidence = 0.5,  tags = {"aoe"} },
    },

    opener         = APL.profiles["default"] and APL.profiles["default"].opener or {},
    majorCooldowns = APL.profiles["default"] and APL.profiles["default"].majorCooldowns or {},
}

------------------------------------------------------------------------
-- Phase 1 backward-compat: flatten singleTarget into flat `rules`
-- Uses the default (Annihilator) single-target list.
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
-- specID 1480 is unique to Devourer DH (no conflict with Evoker 1473).
------------------------------------------------------------------------
RA.APLData[1480] = {
    specID   = APL.specID,
    specName = APL.specName,
    class    = APL.className,
    version  = APL.version,
    author   = APL.author,
    rules    = rules,
    profiles = APL.profiles,
}
