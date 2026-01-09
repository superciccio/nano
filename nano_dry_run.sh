#!/bin/bash

# Nano Migration Dry-Run Tool
# This script applies the Nano migration fixes and shows the diff, then reverts the changes.
# Usage: ./nano_dry_run.sh [directory]

TARGET_DIR=${1:-"."}

echo "🪐 Nano Migration Dry-Run"
echo "Target: $TARGET_DIR"

# Ensure we are in a git repo to easily revert
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "Error: This script must be run inside a git repository."
  exit 1
fi

# Check for pending changes
if ! git diff --quiet; then
  echo "Error: You have uncommitted changes. Please commit or stash them before running the dry-run."
  exit 1
fi

# Run custom_lint --fix
echo "Applying fixes..."
dart run custom_lint --fix

# Show diff
echo -e "\n--- MIGRATION PREVIEW ---\n"
git diff

# Restore changes
echo -e "\n--- FINISHED ---\n"
echo "Reverting changes..."
git checkout .

echo "Dry-run complete. If you are happy with the changes, run: dart run custom_lint --fix"
