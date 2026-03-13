#!/bin/bash
# RotaAssist Release Packager
# Usage: ./scripts/package.sh [version]
# Example: ./scripts/package.sh 1.0.1

set -euo pipefail

VERSION="${1:-$(grep "## Version:" addon/RotaAssist.toc | sed 's/## Version: //')}"
ADDON_NAME="RotaAssist"
BUILD_DIR="build"
PACKAGE_DIR="${BUILD_DIR}/${ADDON_NAME}"

echo "📦 Packaging ${ADDON_NAME} v${VERSION}..."

rm -rf "${BUILD_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Copy addon files (exclude dev-only content)
cp -r addon/* "${PACKAGE_DIR}/"

# Remove any __pycache__ or .pyc that somehow got in
find "${PACKAGE_DIR}" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "${PACKAGE_DIR}" -name "*.pyc" -delete 2>/dev/null || true

# Create zip
cd "${BUILD_DIR}"
zip -r "../${ADDON_NAME}-${VERSION}.zip" "${ADDON_NAME}/"
cd ..

echo "✅ Created ${ADDON_NAME}-${VERSION}.zip"
echo "📏 Size: $(du -h "${ADDON_NAME}-${VERSION}.zip" | cut -f1)"
