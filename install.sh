#!/usr/bin/env bash
set -euo pipefail

REPO="MelianLabs/litetracker-cli"
INSTALL_DIR="/usr/local/bin"

echo "Installing lt CLI..."

command -v curl >/dev/null 2>&1 || { echo "Error: curl is required."; exit 1; }

curl -fsSL "https://raw.githubusercontent.com/$REPO/main/lt" -o /tmp/lt
chmod +x /tmp/lt
sudo mv /tmp/lt "$INSTALL_DIR/lt"

echo "Installed lt to $INSTALL_DIR/lt"
echo ""
echo "Dependencies:"
echo "  - jq      (sudo apt install jq)        required for all commands"
echo "  - sqlite3 (sudo apt install sqlite3)   required for 'lt cache' commands"
echo "Run 'lt auth' to configure your API token."
