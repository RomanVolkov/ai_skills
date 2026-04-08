#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
)

for target in "${TARGETS[@]}"; do
  target_dir=$(dirname "$target")

  # Create parent directory if needed
  mkdir -p "$target_dir"

  # Remove existing symlink or directory
  if [ -L "$target" ] || [ -d "$target" ]; then
    echo "removing existing: $target"
    rm -rf "$target"
  fi

  # Copy skills folder
  cp -r "$SKILLS_DIR" "$target"
  echo "copied: $SKILLS_DIR -> $target"
done
