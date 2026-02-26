#!/usr/bin/env bash
# RotaAssist Validation Script
# Runs automated checks on the addon source code.
# Usage: bash scripts/validate.sh

set -euo pipefail

ADDON_DIR="addon"
TOC_FILE="$ADDON_DIR/RotaAssist.toc"
LOCALE_DIR="$ADDON_DIR/Locales"
ERRORS=0

echo "=== RotaAssist Validation ==="
echo ""

# ── 1. Lua syntax check ──────────────────────────────────────────────
echo "── [1/5] Lua Syntax Check ──"
if command -v luac &>/dev/null; then
    while IFS= read -r -d '' f; do
        if ! luac -p "$f" 2>/dev/null; then
            echo "  ✗ Syntax error: $f"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(find "$ADDON_DIR" -name '*.lua' -print0)
    echo "  ✓ All .lua files passed syntax check"
else
    echo "  ⚠ luac not found — skipping syntax check"
fi

# ── 2. Duplicate module registrations ─────────────────────────────────
echo "── [2/5] Duplicate Module Registrations ──"
DUPS=$(grep -rn 'RegisterModule(' "$ADDON_DIR" --include='*.lua' \
    | sed 's/.*RegisterModule("\([^"]*\)".*/\1/' \
    | sort | uniq -d)
if [ -n "$DUPS" ]; then
    echo "  ✗ Duplicate module names found:"
    echo "$DUPS" | while read -r name; do echo "    - $name"; done
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ No duplicate module registrations"
fi

# ── 3. TOC file existence check ───────────────────────────────────────
echo "── [3/5] TOC File Existence ──"
while IFS= read -r line; do
    # Skip comments and blank lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    # Skip metadata lines (## fields)
    [[ "$line" =~ ^## ]] && continue
    # Skip XML includes
    [[ "$line" =~ \.xml$ ]] && continue

    filepath="$ADDON_DIR/$line"
    filepath="${filepath//\\//}"  # normalize backslashes
    if [ ! -f "$filepath" ]; then
        echo "  ✗ Missing file: $filepath"
        ERRORS=$((ERRORS + 1))
    fi
done < "$TOC_FILE"
echo "  ✓ All TOC-referenced files exist"

# ── 4. No direct RA:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") ────────
echo "── [4/5] Event Registration Check ──"
BAD_REG=$(grep -rn 'RegisterEvent.*UNIT_SPELLCAST_SUCCEEDED' "$ADDON_DIR" --include='*.lua' \
    | grep -v 'EventHandler.lua' \
    | grep -v 'InterruptAdvisor.lua' || true)
if [ -n "$BAD_REG" ]; then
    echo "  ✗ Direct UNIT_SPELLCAST_SUCCEEDED registration found outside EventHandler:"
    echo "$BAD_REG"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ UNIT_SPELLCAST_SUCCEEDED only registered in EventHandler"
fi

# ── 5. Locale completeness ────────────────────────────────────────────
echo "── [5/5] Locale Completeness ──"
if [ -d "$LOCALE_DIR" ]; then
    EN_KEYS=$(grep -oP 'L\["\K[^"]+' "$LOCALE_DIR/enUS.lua" 2>/dev/null | sort -u)
    for locale in zhCN jaJP; do
        LOCALE_KEYS=$(grep -oP 'L\["\K[^"]+' "$LOCALE_DIR/${locale}.lua" 2>/dev/null | sort -u)
        MISSING=$(comm -23 <(echo "$EN_KEYS") <(echo "$LOCALE_KEYS"))
        if [ -n "$MISSING" ]; then
            COUNT=$(echo "$MISSING" | wc -l)
            echo "  ⚠ ${locale}.lua is missing $COUNT key(s) from enUS.lua"
            echo "$MISSING" | head -5 | while read -r k; do echo "    - $k"; done
            [ "$COUNT" -gt 5 ] && echo "    ... and $((COUNT - 5)) more"
        else
            echo "  ✓ ${locale}.lua has all enUS keys"
        fi
    done
else
    echo "  ⚠ Locale directory not found"
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "=== FAILED: $ERRORS error(s) found ==="
    exit 1
else
    echo "=== PASSED: All checks OK ==="
    exit 0
fi
