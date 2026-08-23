#!/usr/bin/env bash
# validate.sh — Check local schema ↔ agentskills.io, then validate skills

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

usage() {
  cat <<'EOF'
Usage: ./validate.sh [--schema] [skill-dir...]

  Before adding or editing skills, run this so the local JSON Schema has not
  drifted from agentskills.io, and existing (or new) skills still validate.

  --schema       Only check schemas/skill.schema.json against the spec
  skill-dir...   Validate specific skill directories (default: all under skills/)

Examples:
  ./validate.sh
  ./validate.sh --schema
  ./validate.sh skills/frontend-principles
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
  esac
done

exec node "$REPO_DIR/scripts/validate.mjs" "$@"
