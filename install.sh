#!/usr/bin/env bash
# install.sh — Symlink skills, agents, and rules into agent directories

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${REPO_DIR}/skills"
AGENTS_SRC="${REPO_DIR}/agents"
RULES_SRC="${REPO_DIR}/rules"

# Skills excluded from global install (none by default).
EXCLUDE_SKILLS=()

TARGETS=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [--claude] [--cursor] [--codex] [--help]

  Symlink skills/*, agents/*, and rules/* into the selected agent directories.
  With no flags, installs for all supported agents.
  All skills under skills/ are installed unless listed in EXCLUDE_SKILLS.
  Rules install for Claude and Cursor only (Codex has no rules target).

  --claude   ~/.claude/skills/, ~/.claude/agents/, ~/.claude/rules/
  --cursor   ~/.cursor/skills/, ~/.cursor/agents/, ~/.cursor/rules/
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

rules_dir() {
  case "$1" in
    claude) echo "${HOME}/.claude/rules" ;;
    cursor) echo "${HOME}/.cursor/rules" ;;
    codex)  echo "" ;;
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

  # Drop stale symlinks that pointed at removed skills in this repo.
  local existing target
  for existing in "$dst_dir"/*; do
    [[ -L "$existing" ]] || continue
    target="$(readlink "$existing")"
    if [[ "$target" == "$SKILLS_SRC"/* && ! -e "$target" ]]; then
      rm -f "$existing"
      echo "  unlinked (removed upstream): $(basename "$existing")"
    fi
  done

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

  # Drop stale symlinks that pointed at removed agents in this repo.
  local existing target
  for existing in "$dst_dir"/*.md; do
    [[ -L "$existing" ]] || continue
    target="$(readlink "$existing")"
    if [[ "$target" == "$AGENTS_SRC"/* && ! -f "$target" ]]; then
      rm -f "$existing"
      echo "  unlinked (removed upstream): $(basename "$existing")"
    fi
  done

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

link_rules() {
  local target="$1"
  local dst_dir="$2"
  local label="$3"

  [[ -n "$dst_dir" ]] || {
    echo "  (no rules target for ${target} — skip)"
    return 0
  }

  [[ -d "$RULES_SRC" ]] || {
    echo "  (no rules/ directory — skip)"
    return 0
  }

  mkdir -p "$dst_dir"

  # Drop stale symlinks that pointed at removed rules in this repo.
  local existing target_path
  for existing in "$dst_dir"/*; do
    [[ -e "$existing" || -L "$existing" ]] || continue
    [[ -L "$existing" ]] || continue
    target_path="$(readlink "$existing")"
    if [[ "$target_path" == "$RULES_SRC"/* && ! -e "$target_path" ]]; then
      rm -f "$existing"
      echo "  unlinked (removed upstream): $(basename "$existing")"
    fi
  done

  local count=0
  local item name dst_name
  for item in "$RULES_SRC"/*; do
    [[ -f "$item" ]] || continue
    case "$item" in
      *.mdc|*.md) ;;
      *) continue ;;
    esac
    name="$(basename "$item")"
    base="${name%.*}"
    # Cursor keeps .mdc; Claude discovers .md — same canonical file, harness-specific link name.
    if [[ "$target" == "claude" ]]; then
      dst_name="${base}.md"
    else
      dst_name="$name"
    fi
    ln -sfn "$item" "$dst_dir/$dst_name"
    echo "  linked: $dst_name → $(basename "$item")"
    ((count++)) || true
  done

  echo "  ($count rule(s) → ${label})"
}

for target in "${TARGETS[@]}"; do
  skills_dst="$(skills_dir "$target")"
  agents_dst="$(agents_dir "$target")"
  rules_dst="$(rules_dir "$target")"
  echo "[install] ${target} skills → ${skills_dst}/"
  link_skills "$skills_dst" "$skills_dst"
  echo "[install] ${target} agents → ${agents_dst}/"
  link_agents "$agents_dst" "$agents_dst"
  echo "[install] ${target} rules → ${rules_dst:-"(none)"}/"
  link_rules "$target" "$rules_dst" "${rules_dst:-none}"
done

echo "[install] done."
