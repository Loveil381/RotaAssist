#!/usr/bin/env python3
"""
RotaAssist — SimulationCraft APL → Training Dataset Converter

Parses SimC APL text, maps spell names to WoW spellIDs, and generates
synthetic feature scenarios suitable for scikit-learn decision tree training.

Usage:
    python simc_apl_to_dataset.py --spec havoc --output data/havoc_dataset.csv
    python simc_apl_to_dataset.py --spec vengeance --apl-file custom.simc --output out.csv
"""

import argparse
import csv
import os
import random
import re
import sys
from typing import Dict, List, Optional, Tuple

# -----------------------------------------------------------------------
# Spell ID Mapping
# -----------------------------------------------------------------------

SPELL_MAP: Dict[str, int] = {
    "demons_bite": 162243,
    "chaos_strike": 162794,
    "eye_beam": 198013,
    "blade_dance": 188499,
    "death_sweep": 210152,
    "annihilation": 201427,
    "immolation_aura": 258920,
    "metamorphosis": 191427,
    "fel_rush": 195072,
    "vengeful_retreat": 198793,
    "throw_glaive": 185123,
    "the_hunt": 370965,
    "essence_break": 258860,
    "glaive_tempest": 342817,
    "fel_barrage": 258925,
    "soul_cleave": 228477,
    "spirit_bomb": 247454,
    "fracture": 263642,
    "sigil_of_flame": 204596,
    "fiery_brand": 204021,
    "demon_spikes": 203720,
    "infernal_strike": 189110,
    "bulk_extraction": 320341,
    "disrupt": 183752,
    "fel_devastation": 212084,
}

SPEC_IDS = {"havoc": 577, "vengeance": 581, "devourer": 1473}

SPEC_SPELLS: Dict[str, List[str]] = {
    "havoc": [
        "demons_bite", "chaos_strike", "eye_beam", "blade_dance",
        "death_sweep", "annihilation", "immolation_aura", "metamorphosis",
        "fel_rush", "the_hunt", "essence_break", "glaive_tempest",
        "throw_glaive", "vengeful_retreat",
    ],
    "vengeance": [
        "soul_cleave", "spirit_bomb", "fracture", "sigil_of_flame",
        "fiery_brand", "demon_spikes", "infernal_strike", "immolation_aura",
        "bulk_extraction", "fel_devastation",
    ],
    "devourer": [],  # placeholder
}

# -----------------------------------------------------------------------
# Built-in Default APL Strings
# -----------------------------------------------------------------------

DEFAULT_APLS: Dict[str, str] = {
    "havoc": """
actions+=/the_hunt
actions+=/metamorphosis,if=!buff.metamorphosis.up
actions+=/essence_break
actions+=/death_sweep,if=buff.metamorphosis.up&active_enemies>=3
actions+=/annihilation,if=buff.metamorphosis.up
actions+=/eye_beam,if=active_enemies>1|buff.metamorphosis.up
actions+=/blade_dance,if=active_enemies>=3
actions+=/glaive_tempest,if=active_enemies>=3
actions+=/chaos_strike,if=fury>=40
actions+=/immolation_aura
actions+=/fel_rush,if=charges=2
actions+=/throw_glaive
actions+=/demons_bite
""",
    "vengeance": """
actions+=/demon_spikes,if=charges>=1
actions+=/fiery_brand
actions+=/fel_devastation
actions+=/spirit_bomb,if=soul_fragments>=4&active_enemies>=2
actions+=/soul_cleave,if=soul_fragments>=1
actions+=/sigil_of_flame
actions+=/fracture
actions+=/immolation_aura
actions+=/bulk_extraction,if=active_enemies>=5
actions+=/throw_glaive
""",
}

# -----------------------------------------------------------------------
# APL Parser
# -----------------------------------------------------------------------

APL_LINE_RE = re.compile(r"actions\+?=/(\w+)(?:,if=(.+))?")


def parse_apl(text: str) -> List[Tuple[str, Optional[str]]]:
    """Return list of (spell_name, condition_string|None)."""
    entries: List[Tuple[str, Optional[str]]] = []
    for line in text.strip().splitlines():
        line = line.strip()
        m = APL_LINE_RE.match(line)
        if m:
            entries.append((m.group(1), m.group(2)))
    return entries


# -----------------------------------------------------------------------
# Condition Constraint Parser
# -----------------------------------------------------------------------


def _rand_nameplate(low: int = 1, high: int = 8) -> int:
    """Weighted random nameplate count."""
    r = random.random()
    if r < 0.40:
        return 1
    elif r < 0.75:
        return random.randint(2, 3)
    else:
        return random.randint(4, high)


def apply_constraint(cond: Optional[str]) -> Dict[str, object]:
    """Return partial feature overrides implied by a SimC condition string."""
    overrides: Dict[str, object] = {}
    if not cond:
        return overrides

    # active_enemies constraints
    m = re.search(r"active_enemies\s*>=?\s*(\d+)", cond)
    if m:
        lo = int(m.group(1))
        overrides["nameplateCount_min"] = lo

    m = re.search(r"active_enemies\s*>\s*(\d+)", cond)
    if m:
        lo = int(m.group(1)) + 1
        overrides["nameplateCount_min"] = lo

    # soul_fragments
    m = re.search(r"soul_fragments\s*>=?\s*(\d+)", cond)
    if m:
        overrides["secondaryResource_min"] = int(m.group(1))

    # metamorphosis
    if "buff.metamorphosis.up" in cond:
        overrides["meta_active"] = True

    return overrides


# -----------------------------------------------------------------------
# Dataset Generation
# -----------------------------------------------------------------------


def generate_scenarios(
    apl_entries: List[Tuple[str, Optional[str]]],
    spec: str,
    n_per_rule: int = 500,
) -> List[Dict]:
    spec_id = SPEC_IDS[spec]
    spell_pool = [
        SPELL_MAP[s] for s in SPEC_SPELLS.get(spec, []) if s in SPELL_MAP
    ]
    if not spell_pool:
        spell_pool = list(SPELL_MAP.values())

    rows: List[Dict] = []

    for spell_name, cond in apl_entries:
        if spell_name not in SPELL_MAP:
            print(f"  [skip] unknown spell: {spell_name}", file=sys.stderr)
            continue
        target_id = SPELL_MAP[spell_name]
        overrides = apply_constraint(cond)

        for _ in range(n_per_rule):
            np_min = overrides.get("nameplateCount_min", 1)
            np_count = random.randint(max(1, np_min), 8) if np_min > 1 else _rand_nameplate()

            sec_min = overrides.get("secondaryResource_min", 0)
            sec_res = random.randint(sec_min, 5)

            blizz_rec = target_id if random.random() < 0.70 else random.choice(spell_pool)

            row = {
                "lastSpellID": random.choice(spell_pool),
                "secondLastSpellID": random.choice(spell_pool),
                "thirdLastSpellID": random.choice(spell_pool),
                "timeSinceLastCast": round(random.uniform(0.5, 3.0), 2),
                "nameplateCount": np_count,
                "secondaryResource": sec_res,
                "secondaryResourceMax": 5,
                "blizzardRecommendation": blizz_rec,
                "combatDuration": round(random.uniform(0, 300), 1),
                "specID": spec_id,
                "target_spellID": target_id,
            }
            rows.append(row)

    random.shuffle(rows)
    return rows


# -----------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(description="SimC APL → training CSV")
    parser.add_argument("--spec", required=True, choices=list(SPEC_IDS.keys()))
    parser.add_argument("--output", required=True, help="Output CSV path")
    parser.add_argument("--apl-file", default=None, help="Custom .simc APL file")
    parser.add_argument("--default", action="store_true", help="Use built-in APL")
    parser.add_argument("--samples", type=int, default=500, help="Scenarios per rule")
    args = parser.parse_args()

    if args.apl_file:
        with open(args.apl_file, "r") as f:
            apl_text = f.read()
    else:
        apl_text = DEFAULT_APLS.get(args.spec, "")
        if not apl_text:
            print(f"No built-in APL for spec '{args.spec}'", file=sys.stderr)
            sys.exit(1)

    entries = parse_apl(apl_text)
    print(f"Parsed {len(entries)} APL rules for {args.spec}")

    rows = generate_scenarios(entries, args.spec, n_per_rule=args.samples)
    print(f"Generated {len(rows)} training samples")

    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    fieldnames = [
        "lastSpellID", "secondLastSpellID", "thirdLastSpellID",
        "timeSinceLastCast", "nameplateCount", "secondaryResource",
        "secondaryResourceMax", "blizzardRecommendation", "combatDuration",
        "specID", "target_spellID",
    ]
    with open(args.output, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
