# agent-skills

Personal [Agent Skills](https://agentskills.io) library. Skills are tool-agnostic `SKILL.md` packages; install only chooses where they are symlinked (Claude Code, Cursor, Codex).

## Structure

```
agent-skills/
├── schemas/
│   └── skill.schema.json
├── scripts/
│   └── validate.mjs
├── skills/
│   └── <skill-name>/
│       └── SKILL.md
├── install.sh
├── uninstall.sh
└── validate.sh
```

## Install (local symlinks)

```bash
./install.sh           # Claude + Cursor + Codex
./install.sh --claude  # ~/.claude/skills/
./install.sh --cursor  # ~/.cursor/skills/
./install.sh --codex   # ~/.agents/skills/
```

Editing files in this repo takes effect immediately — no reinstall needed.  
`add-skill` is excluded from install (repo-local meta skill only).

If you previously installed from the old Claude-only layout, run `./uninstall.sh` then `./install.sh`.

## Uninstall

```bash
./uninstall.sh           # all targets
./uninstall.sh --cursor  # one target
```

## Adding a Skill

Prefer asking the agent to use the `add-skill` skill (available when this repo is open; not installed globally by `./install.sh`), or follow this manually:

1. Confirm the local schema still matches agentskills.io:

```bash
./validate.sh --schema
```

2. Create `skills/<name>/SKILL.md` with agentskills.io frontmatter:

```markdown
---
name: <name>
description: What it does and when to use it.
metadata:
  origin: gyokuro06-agent-skills
---

# Skill Title

## When to Use
...
```

Use only portable fields: `name`, `description`, and optionally `license`, `compatibility`, `metadata` (string values), `allowed-tools` (space-separated). Do not add tool-specific fields (`disable-model-invocation`, `paths`, etc.).

3. Validate, then install:

```bash
./validate.sh skills/<name>
./install.sh
```

`./validate.sh` checks (1) `schemas/skill.schema.json` ↔ agentskills.io field set, (2) official [`skills-reference`](https://www.npmjs.com/package/skills-reference) rules, (3) the local JSON Schema.

## References

- [Agent Skills specification](https://agentskills.io)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Cursor skills](https://cursor.com/docs/skills)
- [Codex skills](https://developers.openai.com/codex/skills)
