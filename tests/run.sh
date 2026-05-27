#!/usr/bin/env bash
# Test runner — discovers and runs all tests in this directory
set -euo pipefail

VAULT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

for test in "$VAULT_DIR"/tests/test_*.sh; do
  name=$(basename "$test")
  echo "=== $name ==="
  if bash "$test"; then
    echo "  PASS"
    PASS=$((PASS + 1))
  else
    echo "  FAIL"
    FAIL=$((FAIL + 1))
  fi
  echo ""
done

echo "=== Results ==="
echo "Passed: $PASS  Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo "SOME TESTS FAILED"
  exit 1
fi

echo "ALL TESTS PASSED"
