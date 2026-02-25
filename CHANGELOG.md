# Changelog

All notable changes to RotaAssist will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-02-25

### Added
- **Core**: Blizzard `C_AssistedCombat` integration via `AssistedCombatBridge` with pcall protection and throttled caching
- **Core**: `EventHandler` pub/sub system, `SavedVars` with AceDB-3.0 defaults, `CooldownTracker`
- **Engine/AIInference.lua**: Signal-based combat phase inference (Burst/AoE/Resource/Emergency/Opener + 6 more phases) using weighted voting on non-secret signals
- **Engine/NeuralPredictor.lua**: Decision tree evaluator + Markov chain predictor with personal learning (40/60 blend after 100+ transitions)
- **Engine/SmartQueueManager.lua**: Multi-source weighted recommendation fusion (Blizzard × APL × AI × Cooldowns × Defensives)
- **Engine/AccuracyTracker.lua**: Dual-track accuracy tracking (Blizzard vs SmartQueue) with phase-based stats and session history
- **Engine/InterruptAdvisor.lua**: 12.0-compliant interrupt reminders using Blizzard recommendation + enemy cast bar detection (no secret API)
- **Engine/CastHistoryRecorder.lua**: Ring buffer (200 cap) with Markov chain learning and cross-session persistence
- **Engine/PatternDetector.lua**: 12-phase combat phase detection with confidence-weighted voting
- **Data**: Havoc/Vengeance/Devourer spec enhancements, decision trees, and Markov transition matrices
- **UI**: T-shaped layout with `MainDisplay`, `AccuracyMeter`, `PhaseIndicator`, `ResourceBar`, `CooldownBar`, `DefensiveAlert`, `PrePullPanel`
- **Training**: Complete Python pipeline (`simc_apl_to_dataset.py` → `train_decision_tree.py` → `sklearn2lua.py` + `markov_builder.py`)
- **Locale**: Full enUS, zhCN, jaJP support (190+ strings each)
- **Packaging**: `.pkgmeta` for CurseForge, complete `.toc` with correct load order
