#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

# ~/.claude/skills is shared by Claude CLI and Claude Desktop app (both use Claude Code engine)
# ~/.config/opencode/skills is used by OpenCode
TARGETS=(
  "$HOME/.claude/skills|Claude CLI + Claude Desktop app"
  "$HOME/.config/opencode/skills|OpenCode"
)

for entry in "${TARGETS[@]}"; do
  target="${entry%%|*}"
  label="${entry##*|}"
  target_dir=$(dirname "$target")

  # Create parent directory if needed
  mkdir -p "$target_dir"

  # Remove existing symlink or directory
  if [ -L "$target" ] || [ -d "$target" ]; then
    rm -rf "$target"
  fi

  # Copy skills folder
  cp -r "$SKILLS_DIR" "$target"
  echo "installed -> $target ($label)"
done

echo ""
echo "done. installed $(ls -1 "$SKILLS_DIR" | wc -l | tr -d ' ') skills."
