#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
)

for target in "${TARGETS[@]}"; do
  if [ -L "$target" ]; then
    current="$(readlink "$target")"
    if [ "$current" = "$SKILLS_DIR" ]; then
      echo "already linked: $target"
      continue
    fi
    echo "relinking: $target (was -> $current)"
    rm "$target"
  elif [ -d "$target" ]; then
    echo "replacing directory: $target"
    rm -rf "$target"
  fi

  ln -s "$SKILLS_DIR" "$target"
  echo "linked: $target -> $SKILLS_DIR"
done
