#!/usr/bin/env bash
# uninstall.sh — Remove symlinks created by install.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${REPO_DIR}/skills"
AGENTS_SRC="${REPO_DIR}/agents"

TARGETS=()

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [--claude] [--cursor] [--codex] [--help]

  Remove symlinks that point into this repository's skills/ and agents/.
  With no flags, uninstalls from all supported agent directories.

  --claude   ~/.claude/skills/  and  ~/.claude/agents/
  --cursor   ~/.cursor/skills/  and  ~/.cursor/agents/
  --codex    ~/.agents/skills/  and  ~/.codex/agents/
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude) TARGETS+=("claude"); shift ;;
    --cursor) TARGETS+=("cursor"); shift ;;
    --codex)  TARGETS+=("codex");  shift ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=(claude cursor codex)
fi

skills_dir() {
  case "$1" in
    claude) echo "${HOME}/.claude/skills" ;;
    cursor) echo "${HOME}/.cursor/skills" ;;
    codex)  echo "${HOME}/.agents/skills" ;;
    *)
      echo "Unknown target: $1" >&2
      return 1
      ;;
  esac
}

agents_dir() {
  case "$1" in
    claude) echo "${HOME}/.claude/agents" ;;
    cursor) echo "${HOME}/.cursor/agents" ;;
    # Codex / Cursor-compatible user agents path
    codex)  echo "${HOME}/.codex/agents" ;;
    *)
      echo "Unknown target: $1" >&2
      return 1
      ;;
  esac
}

remove_skill_links() {
  local dst_dir="$1"

  [[ -d "$dst_dir" ]] || return 0

  local count=0
  local item target
  for item in "$dst_dir"/*/; do
    [[ -L "${item%/}" ]] || continue
    target="$(readlink "${item%/}")"
    if [[ "$target" == "$SKILLS_SRC"/* ]]; then
      rm -f "${item%/}"
      echo "  removed: $(basename "${item%/}")"
      ((count++)) || true
    fi
  done

  echo "  ($count skill(s) removed)"
}

remove_agent_links() {
  local dst_dir="$1"

  [[ -d "$dst_dir" ]] || return 0

  local count=0
  local item target
  for item in "$dst_dir"/*.md; do
    [[ -L "$item" ]] || continue
    target="$(readlink "$item")"
    if [[ "$target" == "$AGENTS_SRC"/* ]]; then
      rm -f "$item"
      echo "  removed: $(basename "$item")"
      ((count++)) || true
    fi
  done

  echo "  ($count agent(s) removed)"
}

for target in "${TARGETS[@]}"; do
  skills_dst="$(skills_dir "$target")"
  agents_dst="$(agents_dir "$target")"
  echo "[uninstall] ${target} skills ← ${skills_dst}/"
  remove_skill_links "$skills_dst"
  echo "[uninstall] ${target} agents ← ${agents_dst}/"
  remove_agent_links "$agents_dst"
done

echo "[uninstall] done."
