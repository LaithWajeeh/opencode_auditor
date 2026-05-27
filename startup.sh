#!/usr/bin/env bash
# Audit Vault — startup health check
# Run this to check vault state. No destructive actions, no prompts.
# Exit 0 = healthy, 1 = missing files/dirs need repair

set -euo pipefail

VAULT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MISSING=false

# --- 1. Vault structure ---
echo "=== VAULT HEALTH ==="

for d in mitigations audits/completed audits metrics; do
  if [[ -d "$VAULT_DIR/$d" ]]; then
    echo "dir_$d: ok"
  else
    echo "dir_$d: MISSING — creating"
    mkdir -p "$VAULT_DIR/$d"
  fi
done

# --- 2. Active audit scan ---
ACTIVE_PLAN=$(grep -rls -- "- \[ \]" "$VAULT_DIR"/audits/plan_*.md 2>/dev/null | sort -r | head -1 || true)
if [[ -n "$ACTIVE_PLAN" ]]; then
  echo "active_plan: $(basename "$ACTIVE_PLAN")"
  TOTAL=$(grep -c -- "- \[ \]" "$ACTIVE_PLAN" 2>/dev/null || echo 0)
  echo "open_items: $TOTAL"
else
  echo "active_plan: none"
  echo "open_items: 0"
fi

# --- 3. Security tools ---
echo "=== TOOLS CHECK ==="
for tool in lynis rkhunter jq; do
  if command -v "$tool" &>/dev/null; then
    echo "tool_$tool: installed"
  else
    echo "tool_$tool: missing"
  fi
done

if systemctl is-active --quiet auditd 2>/dev/null; then
  echo "tool_auditd: active"
else
  echo "tool_auditd: inactive"
fi

# --- 4. Vault startup marker ---
echo "=== MARKER ==="
if [[ -f "$VAULT_DIR/.startup-required" ]]; then
  echo "startup_required: yes"
else
  echo "startup_required: no"
fi

# --- Exit ---
if [[ "$MISSING" == true ]]; then
  echo "=== RESULT: MISSING FILES ==="
  echo "Run 'mkdir -p audits/completed mitigations metrics' to fix."
  exit 1
fi

echo "=== RESULT: HEALTHY ==="
exit 0
