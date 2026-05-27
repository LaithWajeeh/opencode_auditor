#!/bin/bash

VAULT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$VAULT_DIR/setup/install.sh"

# Check if install.sh exists
if [ ! -f "$INSTALL_SCRIPT" ]; then
echo "install.sh not found at $INSTALL_SCRIPT, skipping test."
exit 0
fi

# Verify the script parses correctly
if ! bash -n "$INSTALL_SCRIPT"; then
echo "install.sh has syntax errors."
exit 1
fi

# Verify required dependencies are checked
if ! grep -q "jq is required" "$INSTALL_SCRIPT"; then
echo "install.sh missing jq dependency check."
exit 1
fi

echo "Integration tests for install.sh passed successfully"