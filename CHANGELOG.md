# Changelog

All notable changes to RotaAssist will be documented in this file.

## [1.0.0] - 2026-03-13

### Added
- Core engine: Blizzard C_AssistedCombat bridge with throttling and passive filtering
- APL Engine: SimC-based priority simulation with opener sequences and multi-profile support
- Neural Predictor: Decision tree + Markov chain prediction with personal learning (SavedVariables)
- Smart Queue Manager: 5-source weighted fusion (Blizzard, APL, AI, CD, Defensive) with anti-flicker
- Pattern Detector: 12-phase combat detection using non-secret signals only
- Cast History Recorder: Ring buffer with per-spec SavedVariables persistence
- Accuracy Tracker: Real-time and historical accuracy with per-phase breakdown
- Cooldown Overlay: Whitelisted CD tracking with override pair support
- Defensive Advisor: HP-threshold based defensive reminders
- Interrupt Advisor: 12.0-compliant interrupt alerts with sound and visual flash
- Pre-Pull Checker: Flask, food, rune verification before combat
- T-shaped UI layout with keybind display, drag/lock, context menu, scaling
- Resource bar (Secret Value safe)
- Phase indicator with 12 combat phases
- Accuracy meter widget
- Multi-language support: English, Chinese (Simplified), Japanese
- Training pipeline: Python scripts for decision tree and Markov matrix generation
- Full Demon Hunter support: Havoc, Vengeance, Devourer (⚠ Devourer spellIDs unverified)
- Partial support: Evoker (3 specs), Rogue Subtlety, Shaman Elemental, Druid Balance
- APL data for: Warrior Arms/Fury, Mage Fire

### Known Issues
- Devourer (specID 1480) spell IDs are placeholders pending live server verification
- Evoker/Rogue/Shaman/Druid missing SpecEnhancements data (degraded prediction quality)
- No automated tests
