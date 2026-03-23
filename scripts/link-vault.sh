#!/usr/bin/env bash
#
# Link an existing project to an Obsidian vault checkpoint folder.
#
# Usage:
#   ./link-vault.sh <vault-path> <project-name> [project-dir]
#
# Example:
#   ./link-vault.sh ~/GoogleDrive/.../MyVault/Org/ClaudeCode MyProject ~/vibecode/MyProject
#
set -euo pipefail

VAULT_BASE="${1:?Usage: link-vault.sh <vault-base-path> <project-name> [project-dir]}"
PROJECT_NAME="${2:?Usage: link-vault.sh <vault-base-path> <project-name> [project-dir]}"
PROJECT_DIR="${3:-$(pwd)}"

CHECKPOINT_DIR="$VAULT_BASE/$PROJECT_NAME"
SYMLINK_PATH="$PROJECT_DIR/.checkpoints"

# Create checkpoint folder if needed
mkdir -p "$CHECKPOINT_DIR/sessions"

# Create symlink
if [ -L "$SYMLINK_PATH" ]; then
  rm "$SYMLINK_PATH"
fi

ln -s "$CHECKPOINT_DIR" "$SYMLINK_PATH"
echo "✓ Linked: $SYMLINK_PATH → $CHECKPOINT_DIR"
