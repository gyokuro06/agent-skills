#!/usr/bin/env bash
# uninstall.sh — Remove symlinks created by install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

remove_links() {
  local src_dir="$1"
  local dst_dir="$2"
  local kind="$3"

  [[ -d "$dst_dir" ]] || return 0

  local count=0
  for item in "$dst_dir"/*/; do
    [[ -L "${item%/}" ]] || continue
    local target
    target="$(readlink "${item%/}")"
    if [[ "$target" == "$src_dir"/* ]]; then
      rm -f "${item%/}"
      echo "  removed $kind: $(basename "${item%/}")"
      ((count++)) || true
    fi
  done

  for item in "$dst_dir"/*.md; do
    [[ -L "$item" ]] || continue
    local target
    target="$(readlink "$item")"
    if [[ "$target" == "$src_dir"/* ]]; then
      rm -f "$item"
      echo "  removed $kind: $(basename "$item")"
      ((count++)) || true
    fi
  done

  echo "  ($count $kind removed)"
}

echo "[uninstall] skills ← ${CLAUDE_DIR}/skills/"
remove_links "$REPO_DIR/skills" "$CLAUDE_DIR/skills" "skill"

echo "[uninstall] commands ← ${CLAUDE_DIR}/commands/"
remove_links "$REPO_DIR/commands" "$CLAUDE_DIR/commands" "command"

echo "[uninstall] done."
