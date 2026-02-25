#!/bin/bash

# RotaAssist Build Script
# Creates a clean release zip for CurseForge/GitHub.

ADDON_NAME="RotaAssist"
VERSION=$(grep "## Version:" addon/RotaAssist.toc | awk '{print $3}')

# Fallback if version tag is still a placeholder
if [[ "$VERSION" == "@project-version@" ]] || [[ -z "$VERSION" ]]; then
    VERSION="dev"
fi

ZIP_NAME="${ADDON_NAME}-v${VERSION}.zip"
BUILD_DIR="build_temp"

echo "Building $ADDON_NAME v$VERSION..."

# Clean previous builds
rm -f "$ZIP_NAME"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$ADDON_NAME"

# Copy addon contents to temp directory
cp -R addon/* "$BUILD_DIR/$ADDON_NAME/"

# Cleanup unwanted files
find "$BUILD_DIR" -name ".DS_Store" -type f -delete
find "$BUILD_DIR" -name "*.bak" -type f -delete
find "$BUILD_DIR" -name ".git*" -delete

# Create Zip
cd "$BUILD_DIR" || exit
zip -r "../../$ZIP_NAME" "$ADDON_NAME" > /dev/null
cd ../ || exit

# Cleanup
rm -rf "$BUILD_DIR"

if [ -f "$ZIP_NAME" ]; then
    SIZE=$(du -h "$ZIP_NAME" | cut -f1)
    echo "✅ Release created: $ZIP_NAME ($SIZE)"
else
    echo "❌ Build failed!"
    exit 1
fi
