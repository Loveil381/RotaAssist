#!/bin/bash
VERSION=${1:?"Usage: ./build_release.sh <version>"}
ADDON_NAME="RotaAssist"
BUILD_DIR="build"
ZIP_FILE="${ADDON_NAME}-v${VERSION}.zip"

echo "Building ${ADDON_NAME} v${VERSION}..."

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$ADDON_NAME"

# Copy addon files
cp -r addon/* "$BUILD_DIR/$ADDON_NAME/"

# Remove unnecessary files
find "$BUILD_DIR" -name ".DS_Store" -delete
find "$BUILD_DIR" -name "*.bak" -delete
find "$BUILD_DIR" -name ".git*" -delete
rm -f "$BUILD_DIR/$ADDON_NAME/Engine/Predictor.lua"  # Obsolete file found during audit

# Package
cd "$BUILD_DIR"
zip -r "../$ZIP_FILE" "$ADDON_NAME/"
cd ..

echo "✅ Built: $ZIP_FILE"
ls -lh "$ZIP_FILE"
echo "📁 Contents:"
unzip -l "$ZIP_FILE" | tail -n +4 | head -n -2
