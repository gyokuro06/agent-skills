#!/usr/bin/env bash
# install.sh — Symlink skills and agents into agent directories

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${REPO_DIR}/skills"
AGENTS_SRC="${REPO_DIR}/agents"

# Skills excluded from global install (none by default).
EXCLUDE_SKILLS=()

TARGETS=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [--claude] [--cursor] [--codex] [--help]

  Symlink skills/* and agents/* into the selected agent directories.
  With no flags, installs for all supported agents.
  All skills under skills/ are installed unless listed in EXCLUDE_SKILLS.

  --claude   ~/.claude/skills/  and  ~/.claude/agents/
  --cursor   ~/.cursor/skills/  and  ~/.cursor/agents/
  --codex    ~/.agents/skills/  and  ~/.codex/agents/
EOF
}

is_excluded() {
  local name="$1"
  local excluded
  for excluded in "${EXCLUDE_SKILLS[@]+${EXCLUDE_SKILLS[@]}}"; do
    [[ "$name" == "$excluded" ]] && return 0
  done
  return 1
}

remove_excluded_link() {
  local dst_dir="$1"
  local name="$2"
  local link="${dst_dir}/${name}"

  [[ -L "$link" ]] || return 0
  local target
  target="$(readlink "$link")"
  if [[ "$target" == "$SKILLS_SRC"/* ]]; then
    rm -f "$link"
    echo "  unlinked (excluded): $name"
  fi
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
    codex)  echo "${HOME}/.codex/agents" ;;
    *)
      echo "Unknown target: $1" >&2
      return 1
      ;;
  esac
}

link_skills() {
  local dst_dir="$1"
  local label="$2"

  mkdir -p "$dst_dir"

  local count=0
  local item name
  for item in "$SKILLS_SRC"/*/; do
    [[ -d "$item" ]] || continue
    [[ -f "${item}SKILL.md" ]] || continue
    name="$(basename "$item")"
    if is_excluded "$name"; then
      remove_excluded_link "$dst_dir" "$name"
      echo "  skipped (excluded): $name"
      continue
    fi
    ln -sfn "$item" "$dst_dir/$name"
    echo "  linked: $name"
    ((count++)) || true
  done

  echo "  ($count skill(s) → ${label})"
}

link_agents() {
  local dst_dir="$1"
  local label="$2"

  [[ -d "$AGENTS_SRC" ]] || {
    echo "  (no agents/ directory — skip)"
    return 0
  }

  mkdir -p "$dst_dir"

  local count=0
  local item name
  for item in "$AGENTS_SRC"/*.md; do
    [[ -f "$item" ]] || continue
    name="$(basename "$item")"
    ln -sfn "$item" "$dst_dir/$name"
    echo "  linked: $name"
    ((count++)) || true
  done

  echo "  ($count agent(s) → ${label})"
}

for target in "${TARGETS[@]}"; do
  skills_dst="$(skills_dir "$target")"
  agents_dst="$(agents_dir "$target")"
  echo "[install] ${target} skills → ${skills_dst}/"
  link_skills "$skills_dst" "$skills_dst"
  echo "[install] ${target} agents → ${agents_dst}/"
  link_agents "$agents_dst" "$agents_dst"
done

echo "[install] done."
