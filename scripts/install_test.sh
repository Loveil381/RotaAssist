#!/bin/bash

# RotaAssist Install Test Script (macOS/Linux)
# Creates a symlink of the addon directory to the WoW AddOns folder.

ADDON_NAME="RotaAssist"
SOURCE_DIR="$(pwd)/addon"

# Default WoW path for macOS
DEFAULT_WOW_PATH="/Applications/World of Warcraft/_retail_/Interface/AddOns"

TARGET_PATH="${1:-$DEFAULT_WOW_PATH}"

echo "Checking for WoW AddOns folder at: $TARGET_PATH"

if [ ! -d "$TARGET_PATH" ]; then
    echo "❌ Error: WoW AddOns directory not found!"
    echo "Please provide the path as an argument, e.g.:"
    echo "./scripts/install_test.sh \"/Path/To/World of Warcraft/_retail_/Interface/AddOns\""
    exit 1
fi

DEST_PATH="$TARGET_PATH/$ADDON_NAME"

# Remove existing symlink or directory
if [ -L "$DEST_PATH" ] || [ -d "$DEST_PATH" ]; then
    echo "Removing existing installation at $DEST_PATH..."
    rm -rf "$DEST_PATH"
fi

# Create symlink
echo "Creating symlink: $SOURCE_DIR -> $DEST_PATH"
ln -s "$SOURCE_DIR" "$DEST_PATH"

if [ $? -eq 0 ]; then
    echo "✅ RotaAssist installed! /reload in game to activate."
    echo "✅ RotaAssist 已安装！在游戏中输入 /reload 激活。"
else
    echo "❌ Failed to create symlink. Try running with sudo or check permissions."
fi
