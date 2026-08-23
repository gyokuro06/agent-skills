#!/usr/bin/env bash
# install.sh — Symlink skills into agent skill directories

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${REPO_DIR}/skills"

# Repo-local meta skills — kept under skills/ for discovery in this repo only.
EXCLUDE_SKILLS=(add-skill)

TARGETS=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [--claude] [--cursor] [--codex] [--help]

  Symlink skills/* into the selected agent skill directories.
  With no flags, installs for all supported agents.
  Repo-local meta skills (e.g. add-skill) are not installed.

  --claude   ~/.claude/skills/
  --cursor   ~/.cursor/skills/
  --codex    ~/.agents/skills/  (Codex / vendor-neutral path)
EOF
}

is_excluded() {
  local name="$1"
  local excluded
  for excluded in "${EXCLUDE_SKILLS[@]}"; do
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

target_dir() {
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

for target in "${TARGETS[@]}"; do
  dst="$(target_dir "$target")"
  echo "[install] ${target} → ${dst}/"
  link_skills "$dst" "$dst"
done

echo "[install] done."
