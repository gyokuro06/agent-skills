# claude-code-plugins

Personal skill and command library for Claude Code.

## Structure

```
claude-code-plugins/
├── plugin.json          # manifest
├── schemas/
│   ├── plugin.schema.json
│   └── skill.schema.json
├── skills/
│   └── <skill-name>/
│       └── SKILL.md     # frontmatter + markdown body
├── commands/
│   └── <command>.md     # slash command definition
├── install.sh
└── uninstall.sh
```

## Install (local symlinks)

```bash
./install.sh
```

Symlinks `skills/*` → `~/.claude/skills/` and `commands/*.md` → `~/.claude/commands/`.  
Editing files in this repo immediately takes effect — no reinstall needed.

## Uninstall

```bash
./uninstall.sh
```

## Adding a Skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter:

```markdown
---
name: <name>
description: One-line summary
metadata:
  origin: gyokuro06-claude-code-plugins
  tags: [tag1, tag2]
---

# Skill Title

## When to Use
...
```

2. Add the name to `plugin.json` → `skills[]`.
3. Re-run `./install.sh` (idempotent).

## Adding a Command

1. Create `commands/<name>.md` with YAML frontmatter:

```markdown
---
description: What this command does
argument-hint: [optional args]
---

Command body...
```

2. Add the name to `plugin.json` → `commands[]`.
3. Re-run `./install.sh` (idempotent).

## References

- Design inspired by [ECC](https://github.com/affaan-m/ECC)
- [Claude Code skills docs](https://docs.anthropic.com/en/docs/claude-code/skills)
