#!/usr/bin/env python3
"""
Unit tests for simc_apl_to_dataset.py

Run with: python -m pytest training/test_apl_parser.py -v
Or:       python training/test_apl_parser.py
"""

import csv
import os
import sys
import tempfile
import unittest

# Ensure the training directory is importable
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))

from simc_apl_to_dataset import (
    SPELL_MAP,
    SPEC_IDS,
    SPEC_SPELLS,
    DEFAULT_APLS,
    parse_apl,
    apply_constraint,
    generate_scenarios,
)


class TestSpellMap(unittest.TestCase):
    """Validate the SPELL_MAP constant."""

    def test_spell_map_not_empty(self):
        self.assertGreater(len(SPELL_MAP), 20)

    def test_all_values_are_positive_integers(self):
        for name, sid in SPELL_MAP.items():
            self.assertIsInstance(sid, int, f"{name} has non-int spell ID")
            self.assertGreater(sid, 0, f"{name} has non-positive spell ID")

    def test_no_duplicate_spell_ids(self):
        ids = list(SPELL_MAP.values())
        self.assertEqual(len(ids), len(set(ids)), "Duplicate spell IDs found")

    def test_known_havoc_spells_present(self):
        self.assertEqual(SPELL_MAP["demons_bite"], 162243)
        self.assertEqual(SPELL_MAP["eye_beam"], 198013)
        self.assertEqual(SPELL_MAP["blade_dance"], 188499)
        self.assertEqual(SPELL_MAP["death_sweep"], 210152)
        self.assertEqual(SPELL_MAP["metamorphosis"], 191427)

    def test_known_evoker_spells_present(self):
        self.assertEqual(SPELL_MAP["dragonrage"], 375087)
        self.assertEqual(SPELL_MAP["fire_breath"], 357208)
        self.assertEqual(SPELL_MAP["disintegrate"], 356995)


class TestSpecIDs(unittest.TestCase):
    """Validate SPEC_IDS mapping."""

    def test_havoc(self):
        self.assertEqual(SPEC_IDS["havoc"], 577)

    def test_vengeance(self):
        self.assertEqual(SPEC_IDS["vengeance"], 581)

    def test_devourer(self):
        self.assertEqual(SPEC_IDS["devourer"], 1480)

    def test_devastation(self):
        self.assertEqual(SPEC_IDS["devastation"], 1467)

    def test_augmentation(self):
        self.assertEqual(SPEC_IDS["augmentation"], 1473)

    def test_preservation(self):
        self.assertEqual(SPEC_IDS["preservation"], 1468)

    def test_all_specs_have_spell_pool(self):
        for spec_name in SPEC_IDS:
            self.assertIn(spec_name, SPEC_SPELLS,
                          f"No spell pool defined for {spec_name}")


class TestAPLParser(unittest.TestCase):
    """Validate the APL text parser."""

    def test_parse_simple_action(self):
        entries = parse_apl("actions+=/demons_bite")
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0][0], "demons_bite")
        self.assertIsNone(entries[0][1])

    def test_parse_action_with_condition(self):
        entries = parse_apl("actions+=/eye_beam,if=active_enemies>1")
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0][0], "eye_beam")
        self.assertEqual(entries[0][1], "active_enemies>1")

    def test_parse_multiline(self):
        text = """
actions+=/the_hunt
actions+=/metamorphosis,if=!buff.metamorphosis.up
actions+=/demons_bite
"""
        entries = parse_apl(text)
        self.assertEqual(len(entries), 3)
        self.assertEqual(entries[0][0], "the_hunt")
        self.assertEqual(entries[1][0], "metamorphosis")
        self.assertEqual(entries[2][0], "demons_bite")

    def test_parse_empty_string(self):
        entries = parse_apl("")
        self.assertEqual(len(entries), 0)

    def test_parse_ignores_comments(self):
        text = """
# This is a comment
actions+=/demons_bite
"""
        entries = parse_apl(text)
        self.assertEqual(len(entries), 1)

    def test_all_default_apls_parse_without_error(self):
        for spec_name, apl_text in DEFAULT_APLS.items():
            entries = parse_apl(apl_text)
            self.assertGreater(len(entries), 0,
                               f"Default APL for {spec_name} produced 0 entries")


class TestApplyConstraint(unittest.TestCase):
    """Validate condition constraint extraction."""

    def test_no_condition(self):
        overrides = apply_constraint(None)
        self.assertEqual(len(overrides), 0)

    def test_active_enemies_gte(self):
        overrides = apply_constraint("active_enemies>=3")
        self.assertEqual(overrides.get("nameplateCount_min"), 3)

    def test_active_enemies_gt(self):
        overrides = apply_constraint("active_enemies>1")
        self.assertEqual(overrides.get("nameplateCount_min"), 2)

    def test_metamorphosis_buff(self):
        overrides = apply_constraint("buff.metamorphosis.up")
        self.assertTrue(overrides.get("meta_active"))

    def test_soul_fragments(self):
        overrides = apply_constraint("soul_fragments>=4&active_enemies>=2")
        self.assertEqual(overrides.get("secondaryResource_min"), 4)
        self.assertEqual(overrides.get("nameplateCount_min"), 2)

    def test_dragonrage_buff(self):
        overrides = apply_constraint("!buff.dragonrage.up")
        self.assertTrue(overrides.get("meta_active"))


class TestGenerateScenarios(unittest.TestCase):
    """Validate dataset generation."""

    def test_generates_correct_number_of_rows(self):
        entries = [("demons_bite", None), ("eye_beam", "active_enemies>1")]
        rows = generate_scenarios(entries, "havoc", n_per_rule=10)
        self.assertEqual(len(rows), 20)

    def test_row_has_all_required_fields(self):
        entries = [("demons_bite", None)]
        rows = generate_scenarios(entries, "havoc", n_per_rule=5)
        required_fields = [
            "lastSpellID", "secondLastSpellID", "thirdLastSpellID",
            "timeSinceLastCast", "nameplateCount", "secondaryResource",
            "secondaryResourceMax", "blizzardRecommendation", "combatDuration",
            "specID", "target_spellID",
        ]
        for row in rows:
            for field in required_fields:
                self.assertIn(field, row, f"Missing field: {field}")

    def test_target_spell_id_is_correct(self):
        entries = [("demons_bite", None)]
        rows = generate_scenarios(entries, "havoc", n_per_rule=5)
        for row in rows:
            self.assertEqual(row["target_spellID"], 162243)

    def test_spec_id_is_correct(self):
        entries = [("demons_bite", None)]
        rows = generate_scenarios(entries, "havoc", n_per_rule=5)
        for row in rows:
            self.assertEqual(row["specID"], 577)

    def test_unknown_spell_is_skipped(self):
        entries = [("nonexistent_spell", None), ("demons_bite", None)]
        rows = generate_scenarios(entries, "havoc", n_per_rule=5)
        self.assertEqual(len(rows), 5)  # only demons_bite rows

    def test_nameplate_constraint_respected(self):
        entries = [("blade_dance", "active_enemies>=3")]
        rows = generate_scenarios(entries, "havoc", n_per_rule=100)
        for row in rows:
            self.assertGreaterEqual(row["nameplateCount"], 3)

    def test_all_specs_generate_without_error(self):
        for spec_name in SPEC_IDS:
            if spec_name == "devourer":
                continue  # empty spell pool, uses fallback
            apl_text = DEFAULT_APLS.get(spec_name, "")
            if not apl_text:
                continue
            entries = parse_apl(apl_text)
            rows = generate_scenarios(entries, spec_name, n_per_rule=2)
            self.assertGreater(len(rows), 0,
                               f"No rows generated for {spec_name}")


class TestCSVOutput(unittest.TestCase):
    """Validate CSV file output."""

    def test_csv_round_trip(self):
        entries = [("demons_bite", None), ("eye_beam", None)]
        rows = generate_scenarios(entries, "havoc", n_per_rule=5)

        with tempfile.NamedTemporaryFile(mode="w", suffix=".csv",
                                         delete=False, newline="") as f:
            fieldnames = list(rows[0].keys())
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
            tmp_path = f.name

        try:
            with open(tmp_path, "r") as f:
                reader = csv.DictReader(f)
                read_rows = list(reader)
            self.assertEqual(len(read_rows), 10)
            self.assertEqual(set(read_rows[0].keys()), set(fieldnames))
        finally:
            os.unlink(tmp_path)


if __name__ == "__main__":
    unittest.main()
