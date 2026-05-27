#!/usr/bin/env bash
# Audit Vault install script
# Merges vault permissions into ~/.config/opencode/opencode.json
# and installs skills into ~/.config/opencode/skills/
# Safe to re-run — will not clobber existing config keys.

set -euo pipefail

VAULT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBAL_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
GLOBAL_CONFIG="$GLOBAL_CONFIG_DIR/opencode.json"
SKILLS_DIR="$GLOBAL_CONFIG_DIR/skills"

echo "=== Audit Vault Installer ==="
echo "Vault:  $VAULT_DIR"
echo "Config: $GLOBAL_CONFIG"
echo ""

# --- Require jq ---
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed."
  echo "  Ubuntu/Debian: sudo apt install jq"
  echo "  Arch:          sudo pacman -S jq"
  echo "  Fedora:        sudo dnf install jq"
  echo "  macOS:         brew install jq"
  exit 1
fi

# --- Create global config dir if needed ---
mkdir -p "$GLOBAL_CONFIG_DIR"

# --- Create empty global config if it doesn't exist ---
if [[ ! -f "$GLOBAL_CONFIG" ]]; then
  # shellcheck disable=SC2016
  echo '{ "$schema": "https://opencode.ai/config.json" }' > "$GLOBAL_CONFIG"
  echo "Created $GLOBAL_CONFIG"
fi

# --- Validate existing config is parseable ---
if ! jq empty "$GLOBAL_CONFIG" 2>/dev/null; then
  echo "ERROR: $GLOBAL_CONFIG exists but is not valid JSON."
  echo "Fix it manually or back it up and delete it, then re-run."
  exit 1
fi

# --- Show what will be merged ---
echo "Merging into $GLOBAL_CONFIG:"
echo '  permission.bash  = "ask"'
echo '  permission.edit  = "ask"'
echo '  permission.write = "ask"'
echo ""

# --- Backup existing config ---
BACKUP="$GLOBAL_CONFIG.bak.$(date +%Y%m%d_%H%M%S)"
cp "$GLOBAL_CONFIG" "$BACKUP"
echo "Backup saved: $BACKUP"

# --- Merge permissions (existing keys win for everything except permission block) ---
# Strategy: deep-merge permission block; all other existing keys are preserved
TMP_MERGE=$(mktemp)
jq --argjson perms '{
  "bash":  "ask",
  "edit":  "ask",
  "write": "ask"
}' '
  .permission = (.permission // {} | . + $perms)
' "$GLOBAL_CONFIG" > "$TMP_MERGE"

mv "$TMP_MERGE" "$GLOBAL_CONFIG"
echo "✓ Permissions merged"

# --- Register vault AGENTS.md as instruction (relative path in vault-local opencode.json) ---
echo ""
echo "Registering vault AGENTS.md as instruction..."
LOCAL_CONFIG="$VAULT_DIR/opencode.json"
if [[ -f "$LOCAL_CONFIG" ]]; then
  TMP_INSTRUCT=$(mktemp)
  jq --arg agents "AGENTS.md" '
    .instructions = (.instructions // [] | if index($agents) then . else . + [$agents] end)
  ' "$LOCAL_CONFIG" > "$TMP_INSTRUCT" && \
  mv "$TMP_INSTRUCT" "$LOCAL_CONFIG"
  echo "  ✓ AGENTS.md registered in $LOCAL_CONFIG"
else
  echo "  SKIP — no opencode.json at vault root. Create one manually."
fi

# --- Setup OpenCode Zen provider with Big Pickle as default ---
echo ""
echo "Setting up OpenCode Zen provider (big-pickle default)..."

TMP_ZEN=$(mktemp)
jq --argjson opencode '{
  "npm": "@ai-sdk/openai-compatible",
  "name": "OpenCode Zen",
  "options": {
    "baseURL": "https://opencode.ai/zen/v1",
    "apiKey": "{env:OPENCODE_API_KEY}"
  },
  "models": {
    "big-pickle": {
      "name": "Big Pickle",
      "tools": true,
      "limit": {
        "context": 200000,
        "output": 8192
      }
    }
  }
}' '
  .model = (.model // "opencode/big-pickle") |
  .provider.opencode = (.provider.opencode // $opencode)
' "$GLOBAL_CONFIG" > "$TMP_ZEN"

mv "$TMP_ZEN" "$GLOBAL_CONFIG"

if jq -e '.model == "opencode/big-pickle"' "$GLOBAL_CONFIG" >/dev/null 2>&1; then
  echo "  ✓ Default model: opencode/big-pickle"
else
  echo "  ✓ Default model already set to: $(jq -r '.model // "unset"' "$GLOBAL_CONFIG") (preserved)"
fi

if jq -e '.provider.opencode' "$GLOBAL_CONFIG" >/dev/null 2>&1; then
  echo "  ✓ OpenCode Zen provider configured"
else
  echo "  ✗ Failed to add OpenCode Zen provider"
fi

# --- Install skills globally ---
echo ""
echo "Installing skills to $SKILLS_DIR ..."

for skill in templates tools; do
  SRC="$VAULT_DIR/setup/skills/$skill/SKILL.md"
  DST="$SKILLS_DIR/$skill"

  # If source not in vault, try to copy from existing global install (idempotent)
  if [[ ! -f "$SRC" ]]; then
    if [[ -f "$DST/SKILL.md" ]]; then
      echo "  SKIP $skill — already installed at $DST/SKILL.md"
    else
      echo "  SKIP $skill — source not found: $SRC"
    fi
    continue
  fi

  mkdir -p "$DST"

  if [[ -f "$DST/SKILL.md" ]]; then
    cp "$DST/SKILL.md" "$DST/SKILL.md.bak.$(date +%Y%m%d_%H%M%S)"
    echo "  Backed up existing $skill skill"
  fi

  cp "$SRC" "$DST/SKILL.md"
  echo "  ✓ Installed skill: $skill → $DST/SKILL.md"
done

# --- Create vault scaffold ---
echo ""
echo "Creating vault scaffold in $VAULT_DIR ..."

# Create directory structure (mitigations/ existence = install-complete marker)
mkdir -p "$VAULT_DIR/audits/completed" "$VAULT_DIR/mitigations" "$VAULT_DIR/metrics"
mkdir -p "$VAULT_DIR/docs"
mkdir -p "$VAULT_DIR/.obsidian/plugins"

echo "✓ audits/completed/ mitigations/ metrics/ created"
echo "✓ docs/ created"

# Copy startup.sh and make executable
if [[ -f "$VAULT_DIR/startup.sh" ]]; then
  chmod +x "$VAULT_DIR/startup.sh"
  echo "✓ startup.sh made executable"
fi

# Create .startup-required marker
touch "$VAULT_DIR/.startup-required"
echo "✓ .startup-required marker created"

# --- Hand off to Opencode ---
echo ""
hash -r 2>/dev/null
if command -v opencode &>/dev/null; then
  echo "Handing off remaining setup to Opencode..."
  opencode "Load the install skill from setup/skills/install/SKILL.md and complete the Audit Vault setup for this OS (install security tools, configure Obsidian, scaffold directories)"
else
  echo "Opencode not found — skipping automated setup."
  echo "Install Opencode and run: opencode"
fi

# --- Done ---
echo ""
echo "=== Install complete ==="
echo ""
echo "To verify merged config:"
echo "  cat $GLOBAL_CONFIG | jq .permission"
echo ""
echo "To undo permissions later:"
# shellcheck disable=SC2016
echo '  TMP_UNDO=$(mktemp) && jq '\''del(.permission)'\'' "$GLOBAL_CONFIG" > "$TMP_UNDO" && mv "$TMP_UNDO" "$GLOBAL_CONFIG"'
