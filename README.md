# agent-skills

Personal [Agent Skills](https://agentskills.io) library. Skills are tool-agnostic `SKILL.md` packages; install only chooses where they are symlinked (Claude Code, Cursor, Codex).

## Structure

```
agent-skills/
├── manifest.json
├── schemas/
│   ├── manifest.schema.json
│   └── skill.schema.json
├── skills/
│   └── <skill-name>/
│       └── SKILL.md
├── install.sh
└── uninstall.sh
```

## Install (local symlinks)

```bash
./install.sh           # Claude + Cursor + Codex
./install.sh --claude  # ~/.claude/skills/
./install.sh --cursor  # ~/.cursor/skills/
./install.sh --codex   # ~/.agents/skills/
```

Editing files in this repo takes effect immediately — no reinstall needed.

If you previously installed from the old Claude-only layout, run `./uninstall.sh` then `./install.sh`.

## Uninstall

```bash
./uninstall.sh           # all targets
./uninstall.sh --cursor  # one target
```

## Adding a Skill

1. Create `skills/<name>/SKILL.md` with agentskills.io frontmatter:

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

2. Add the name to `manifest.json` → `skills[]`.
3. Re-run `./install.sh` (idempotent).

## References

- [Agent Skills specification](https://agentskills.io)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Cursor skills](https://cursor.com/docs/skills)
- [Codex skills](https://developers.openai.com/codex/skills)
