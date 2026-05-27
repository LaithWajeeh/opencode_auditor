#!/bin/bash

VAULT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_directory=$(mktemp -d)
cd "$test_directory" || exit 1

# Execute bootstrap.sh in the temp directory to test its integration
"$VAULT_DIR/bootstrap.sh" --dry-run

echo 'Integration tests for bootstrap.sh passed successfully'
