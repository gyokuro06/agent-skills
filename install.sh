#!/usr/bin/env bash
# install.sh — Symlink skills and commands into ~/.claude/

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

link_items() {
  local src_dir="$1"
  local dst_dir="$2"
  local kind="$3"

  mkdir -p "$dst_dir"

  local count=0
  for item in "$src_dir"/*/; do
    [[ -d "$item" ]] || continue
    local name
    name="$(basename "$item")"
    ln -sfn "$item" "$dst_dir/$name"
    echo "  linked $kind: $name"
    ((count++)) || true
  done

  for item in "$src_dir"/*.md; do
    [[ -f "$item" ]] || continue
    local name
    name="$(basename "$item")"
    ln -sfn "$item" "$dst_dir/$name"
    echo "  linked $kind: $name"
    ((count++)) || true
  done

  echo "  ($count $kind linked)"
}

echo "[install] skills → ${CLAUDE_DIR}/skills/"
link_items "$REPO_DIR/skills" "$CLAUDE_DIR/skills" "skill"

echo "[install] commands → ${CLAUDE_DIR}/commands/"
link_items "$REPO_DIR/commands" "$CLAUDE_DIR/commands" "command"

echo "[install] done."
