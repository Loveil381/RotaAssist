# RotaAssist Roadmap

## Phase 1 — Core Addon (✅ DONE)
- WoW addon skeleton with Ace3 libraries
- Demon Hunter: Havoc, Vengeance, Devourer (3 specs)
- C_AssistedCombat bridge as primary data source
- APL prediction engine with look-ahead
- T-shaped MainDisplay with drag/scale/lock
- CooldownOverlay + DefensiveAdvisor + PrePullChecker
- NeuralPredictor (Decision Tree + Markov chain)
- PatternDetector (combat phase inference)
- SmartQueueManager (unified fusion layer)
- Locale support: enUS, zhCN, jaJP
- SavedVariables persistence

## Phase 2 — Bug Fixes + Spec Expansion (🔧 CURRENT)
- **Bug fixes**: SpecDetector init, UNIT_SPELLCAST_SUCCEEDED dispatch, CooldownOverlay API, DefensiveAdvisor API, C_Timer cancel, cast history filter, RecommendationManager removal
- **15 new specs**: Warrior (Arms, Fury, Protection), Mage (Fire, Frost, Arcane), Paladin (Retribution, Holy, Protection), Rogue (Outlaw, Subtlety, Assassination), Hunter (BM, MM, Survival)
- Per-spec: SpecEnhancements, APL, DecisionTree, TransitionMatrix, WhitelistSpells, Locales

## Phase 3 — Full 39-Spec Coverage
- All DPS specs (complete)
- All Tank specs (Protection Warrior, Guardian Druid, Blood DK, Brewmaster Monk, Vengeance DH)
- All Healer specs (Holy Priest, Disc Priest, Resto Druid, Resto Shaman, Mistweaver Monk, Holy Paladin, Preservation Evoker)
- Augmentation Evoker support
- Community-contributed APL definitions via `_Template.lua`
- Automated spec data validation

## Phase 4 — Companion Desktop App
- **Backend**: Python 3.11+ with FastAPI
- **Frontend**: Tauri 2.x with Svelte
- **AI Engine**: ONNX Runtime for local ML inference
- Combat log parser (WoWCombatLog.txt streaming)
- Post-combat analysis: rotation efficiency, CD usage, death replay
- SavedVariables ↔ Companion data exchange
- Localized UI (enUS, zhCN, jaJP)

## Phase 5 — Cloud Model Updates
- OTA model updates for DecisionTrees and TransitionMatrices
- Community-aggregated Markov data (anonymized)
- SimulationCraft integration for auto-generated APL validation
- Patch-day rapid model retraining pipeline

## Phase 6 — CurseForge / Wago Launch
- CurseForge packaging with `.pkgmeta`
- Wago integration (Wago ID assignment)
- GitHub Actions release automation
- SEO-optimized README ("Hekili alternative for WoW Midnight 12.0")
- Promotional material: screenshots, demo video, comparison table
- Community Discord setup
