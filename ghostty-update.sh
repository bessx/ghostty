#!/bin/bash

set -euo pipefail

REPO="bessx/ghostty"
APP="/Applications/Ghostty.app"
BACKUP="$HOME/Backups/Ghostty/Ghostty.app"
STATE="$HOME/.config/ghostty-update"
BASE="https://github.com/$REPO/releases/latest/download"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cd "$WORKDIR"

echo "Checking latest Ghostty release..."

curl -fLsS --retry 3 \
    "$BASE/Ghostty-Universal.zip.sha256" \
    -o Ghostty-Universal.zip.sha256

CHECKSUM=$(awk '{print $1}' Ghostty-Universal.zip.sha256)

if [[ "${1:-}" != "--force" ]] &&
   [[ -d "$APP" && -f "$STATE/checksum" ]] &&
   [[ "$(cat "$STATE/checksum")" == "$CHECKSUM" ]]; then
    echo "Ghostty is already up to date."
    exit 0
fi

echo "Downloading latest Ghostty release..."

curl -fL --retry 3 \
    "$BASE/Ghostty-Universal.zip" \
    -o Ghostty-Universal.zip

echo "Verifying checksum..."
shasum -a 256 -c Ghostty-Universal.zip.sha256

echo "Extracting Ghostty..."
ditto -x -k Ghostty-Universal.zip .

test -d Ghostty.app

echo "Removing quarantine attributes..."
xattr -dr com.apple.quarantine Ghostty.app

echo "Signing application..."
codesign --force --deep --sign - Ghostty.app

echo "Verifying signature..."
codesign --verify --deep --strict Ghostty.app

echo "Closing Ghostty..."
osascript -e 'tell application id "com.mitchellh.ghostty" to quit' \
    2>/dev/null || true

sleep 2

if pgrep -x ghostty >/dev/null; then
    echo "Please close Ghostty completely and rerun."
    exit 1
fi

mkdir -p "$(dirname "$BACKUP")" "$STATE"

echo "Backing up previous version..."

if [[ -d "$APP" ]]; then
    rm -rf "$BACKUP"
    ditto "$APP" "$BACKUP"
fi

echo "Installing Ghostty..."

sudo rm -rf "$APP"

if ! sudo ditto Ghostty.app "$APP"; then
    echo "Installation failed. Restoring backup..."
    sudo rm -rf "$APP"

    if [[ -d "$BACKUP" ]]; then
        sudo ditto "$BACKUP" "$APP"
    fi

    exit 1
fi

echo "$CHECKSUM" > "$STATE/checksum"

echo "Installed version:"
"$APP/Contents/MacOS/ghostty" +version

echo "Ghostty successfully updated!"

open -n "$APP"
