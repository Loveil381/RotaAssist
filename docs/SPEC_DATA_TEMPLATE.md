# Spec Data Template

Copy-paste template for adding a new spec. Replace all `<PLACEHOLDERS>` with actual values.

## Validation Checklist

- [ ] All spellIDs verified with `/dump C_Spell.GetSpellInfo(SPELLID)` on 12.0
- [ ] SpecEnhancements registered under correct `specID`
- [ ] APL actions list has correct priorities and conditions
- [ ] DecisionTree `Evaluate()` returns `{spellID, confidence}`
- [ ] TransitionMatrix probabilities sum to ≤ 1.0 per row
- [ ] WhitelistSpells entries added for CDs ≥ 30s
- [ ] Locale keys added to enUS, zhCN, jaJP
- [ ] Files added to RotaAssist.toc in correct order
- [ ] `luac -p` passes on all new files

---

## SpecEnhancements Template

```lua
------------------------------------------------------------------------
-- RotaAssist - Spec Enhancements: <CLASS_NAME>
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
RA.SpecEnhancements = RA.SpecEnhancements or {}

RA.SpecEnhancements[<SPEC_ID>] = {
    majorCooldowns = {
        { spellID = <SPELL_ID>, alertThreshold = 10, name = "<SPELL_NAME>" },
        { spellID = <SPELL_ID>, alertThreshold = 5,  name = "<SPELL_NAME>" },
    },

    interruptSpell = { spellID = <SPELL_ID>, name = "<INTERRUPT_NAME>", cooldown = 15 },

    defensives = {
        { spellID = <SPELL_ID>, hpThreshold = 0.35, name = "<DEF_NAME>" },
        { spellID = <SPELL_ID>, hpThreshold = 0.50, name = "<DEF_NAME>" },
    },

    resource = {
        type      = <POWER_TYPE_ENUM>,  -- e.g., 0=Mana, 1=Rage, 3=Energy, 17=Fury
        maxBase   = <MAX_RESOURCE>,
        spellCosts = {
            [<SPELL_ID>] = { cost = <AMOUNT> },   -- spender
            [<SPELL_ID>] = { gen  = <AMOUNT> },    -- generator
        },
    },

    burstWindows = {
        meta = { trigger = <CD_SPELL_ID>, duration = <SECONDS>, label = "<LABEL>" }
    },

    prePullChecks = {
        flask  = { type = "aura", spellID = 428484, name = "Flask of Tempered Mastery" },
        food   = { type = "aura", spellID = 104273, name = "Well Fed" },
        rune   = { type = "aura", spellID = 270058, name = "Crystallized Augment Rune" },
    },

    inferenceRules = {
        aoeSpells          = { <AOE_SPELL_IDS> },
        singleTargetSpells = { <ST_SPELL_IDS> },
        generatorSpells    = { <GEN_SPELL_IDS> },
        spenderSpells      = { <SPENDER_SPELL_IDS> },
        burstIndicatorSpells = { <BURST_INDICATOR_IDS> },
        burstCooldownSpell = <BURST_CD_SPELL_ID>,
        burstDuration      = <SECONDS>,
        executeSpells      = {},
    },
}
```

## APL Template

```lua
------------------------------------------------------------------------
-- RotaAssist - APL: <Class>_<Spec>
------------------------------------------------------------------------
local _, NS = ...
local RA = NS.RA
RA.APLData = RA.APLData or {}

RA.APLData[<SPEC_ID>] = {
    class   = "<CLASS_TOKEN>",   -- e.g., "WARRIOR"
    specID  = <SPEC_ID>,

    profiles = {
        default = {
            { spellID = <ID>, condition = "cd_ready",       priority = 1, note = "Major CD" },
            { spellID = <ID>, condition = "cd_ready",       priority = 2, note = "Burst ability" },
            { spellID = <ID>, condition = "resource_above_40", priority = 3, note = "Spender" },
            { spellID = <ID>, condition = "always",         priority = 10, note = "Filler" },
        },
    },
}
```

## WhitelistSpells Entry

```lua
[<SPELL_ID>] = { name = "<SPELL_NAME>", class = "<CLASS_TOKEN>", specID = <SPEC_ID>, cdSeconds = <CD> },
```

## Locale Entry (add to all 3 files)

```lua
-- enUS.lua
L["<KEY>"] = "<English text>"

-- zhCN.lua
L["<KEY>"] = "<简体中文>"

-- jaJP.lua
L["<KEY>"] = "<日本語>"
```
