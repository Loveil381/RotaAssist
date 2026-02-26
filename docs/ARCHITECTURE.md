# RotaAssist Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        WoW Client (12.0)                            │
│  ┌──────────────────┐  ┌─────────────────┐  ┌──────────────────┐   │
│  │ C_AssistedCombat │  │  C_Spell.*      │  │  UnitHealth/     │   │
│  │ GetNextCastSpell │  │  GetSpellCooldown│  │  UnitPower       │   │
│  │ GetRotationSpells│  │  GetSpellInfo   │  │  (combat-safe)   │   │
│  └────────┬─────────┘  └───────┬─────────┘  └───────┬──────────┘   │
│           │                    │                     │              │
│  ┌────────▼────────────────────▼─────────────────────▼──────────┐   │
│  │                    RotaAssist Addon                           │   │
│  │                                                               │   │
│  │  ┌─────────────────────── CORE ──────────────────────────┐   │   │
│  │  │ Init → SavedVars → EventHandler → CooldownTracker     │   │   │
│  │  │                     AssistCapture (glow fallback)      │   │   │
│  │  └──────────────────────────┬─────────────────────────────┘   │   │
│  │                             │                                 │   │
│  │  ┌────────────────── DATA LAYER ─────────────────────────┐   │   │
│  │  │ SpecInfo · WhitelistSpells · APL/* · SpecEnhancements  │   │   │
│  │  │ DecisionTrees/* · TransitionMatrix/*                   │   │   │
│  │  └──────────────────────────┬─────────────────────────────┘   │   │
│  │                             │                                 │   │
│  │  ┌─────────────────── ENGINE ────────────────────────────┐   │   │
│  │  │                                                        │   │   │
│  │  │  SpecDetector ─────────────────────────┐               │   │   │
│  │  │       │                                │               │   │   │
│  │  │  AssistedCombatBridge    APLEngine      │               │   │   │
│  │  │       │                    │            │               │   │   │
│  │  │  CastHistoryRecorder ► NeuralPredictor │               │   │   │
│  │  │       │                    │            │               │   │   │
│  │  │  AccuracyTracker    PatternDetector     │               │   │   │
│  │  │       │                    │            │               │   │   │
│  │  │  CooldownOverlay  DefensiveAdvisor     │               │   │   │
│  │  │       │              InterruptAdvisor   │               │   │   │
│  │  │       │              PrePullChecker     │               │   │   │
│  │  │       ▼                    ▼            │               │   │   │
│  │  │  ┌─────────────────────────────────┐   │               │   │   │
│  │  │  │       SmartQueueManager         │◄──┘               │   │   │
│  │  │  │  (final fusion / priority layer)│                    │   │   │
│  │  │  └───────────────┬─────────────────┘                    │   │   │
│  │  └──────────────────┼──────────────────────────────────────┘   │   │
│  │                     │                                         │   │
│  │  ┌───────── UI ─────▼────────────────────────────────────┐   │   │
│  │  │ MainDisplay · CooldownPanel · ConfigPanel             │   │   │
│  │  │ MinimapButton · Widgets/*                             │   │   │
│  │  └────────────────────────────────────────────────────────┘   │   │
│  └───────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Primary: C_AssistedCombat → Display

```
C_AssistedCombat.GetNextCastSpell()
  → AssistedCombatBridge:GetCurrentRecommendation()
    → SmartQueueManager (slot 1, weight 1.0)
      → MainDisplay (main icon)
```

### Prediction: APL Look-Ahead

```
AssistedCombatBridge (current spell)
  → APLEngine:PredictNext(currentSpell, state, 2)
    → SmartQueueManager (slots 2-3, weight 0.6)
      → MainDisplay (prediction icons)
```

### Learning: Cast History → Neural Predictor

```
UNIT_SPELLCAST_SUCCEEDED
  → EventHandler:Fire("ROTAASSIST_SPELLCAST_SUCCEEDED")
    → CastHistoryRecorder (ring buffer)
      → NeuralPredictor:UpdateMarkovMatrix()
        → SmartQueueManager (alternative scoring)
```

### Combat Phase Detection

```
PatternDetector (nameplates, resource, Blizzard rec)
  → AIInference (AoE/burst/resource voting)
    → SmartQueueManager.aiContext
      → MainDisplay (phase indicator + tips)
```

## Module Lifecycle

```
ADDON_LOADED
  → Init:OnInitialize()
    → SavedVars:OnInitialize() (AceDB setup)
    → All modules: OnInitialize() (in MODULE_ORDER)

PLAYER_LOGIN
  → Init:OnEnable()
    → EventHandler:OnEnable() (central UNIT_SPELLCAST_SUCCEEDED dispatch)
    → All modules: OnEnable() (in MODULE_ORDER)

PLAYER_ENTERING_WORLD
  → SpecDetector: refreshSpec() with 0.5s delay
    → Fires ROTAASSIST_SPEC_CHANGED
      → All spec-aware modules reload config

PLAYER_SPECIALIZATION_CHANGED
  → SpecDetector: refreshSpec()
    → Same cascade as above
```

## WoW 12.0 API Constraints

| API | Status | Notes |
|-----|--------|-------|
| `C_AssistedCombat.*` | ✅ Primary | Main data source for rotation suggestions |
| `C_Spell.GetSpellCooldown()` | ✅ Safe | Player's own spells only |
| `C_Spell.GetSpellInfo()` | ✅ Safe | Basic metadata (name, icon) |
| `UnitHealth/UnitPower` | ✅ Safe | "player" unit in combat |
| `GetSpecialization()` | ✅ Safe | Spec detection |
| `C_UnitAuras.*` | ⚠️ OOC only | SECRET during combat |
| `COMBAT_LOG_EVENT_UNFILTERED` | ⚠️ Restricted | Fires but limited for decisions |

## Event Architecture

All WoW native events and custom `ROTAASSIST_*` events flow through `EventHandler`. Modules subscribe via `eh:Subscribe(eventName, moduleName, callback)` which supports multi-subscriber dispatch, deduplication, and throttling.

### Custom Events

| Event | Payload | Fired By |
|-------|---------|----------|
| `ROTAASSIST_SPEC_CHANGED` | `specInfo` | SpecDetector |
| `ROTAASSIST_SPELLCAST_SUCCEEDED` | `unit, castGUID, spellID` | EventHandler |
| `ROTAASSIST_BRIDGE_UPDATED` | `spellID` | AssistedCombatBridge |
| `ROTAASSIST_QUEUE_UPDATED` | `mainEntry` | SmartQueueManager |
| `ROTAASSIST_DEFENSIVE_ALERT` | `spellID, hpPct, threshold` | DefensiveAdvisor |
| `ROTAASSIST_INTERRUPT_ALERT` | `active, data` | InterruptAdvisor |
| `ROTAASSIST_CD_ALERT` | `spellID, remaining` | CooldownOverlay |
| `ROTAASSIST_SETTINGS_RESET` | *(none)* | SavedVars |
