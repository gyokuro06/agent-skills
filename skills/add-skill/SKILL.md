---
name: add-skill
description: Use when adding a new Agent Skill to this repository. Runs schema/spec sync checks before creating skills/<name>/SKILL.md, then validates and installs.
metadata:
  origin: gyokuro06-agent-skills
---

# Add Skill

Create a portable Agent Skill in this repository. Follow the steps in order; do not skip validation.

## Steps

1. **Confirm schema has not drifted from agentskills.io**

```bash
./validate.sh --schema
```

If this fails, update `schemas/skill.schema.json` (and `scripts/validate.mjs` `SPEC_FIELDS` if the upstream field set changed) before authoring a new skill. Source of truth: https://agentskills.io/specification

2. **Create the skill directory**

```text
skills/<name>/SKILL.md
```

`<name>` must be kebab-case and match the frontmatter `name`.

3. **Write portable frontmatter only**

Required: `name`, `description`  
Optional: `license`, `compatibility`, `metadata` (string values only), `allowed-tools` (space-separated)

Do **not** add tool-specific fields (`disable-model-invocation`, `paths`, `hooks`, `argument-hint`, etc.).

```markdown
---
name: example-skill
description: What it does and when to use it. Include trigger keywords.
metadata:
  origin: gyokuro06-agent-skills
---

# Example Skill

## When to Use
...
```

4. **Validate the new skill**

```bash
./validate.sh skills/<name>
```

Fix any errors before continuing.

5. **Install symlinks**

```bash
./install.sh
```

## Notes

- `./validate.sh` checks (a) local schema ↔ agentskills.io field set, (b) `skills-reference` official rules, (c) local JSON Schema (including string-only `metadata`).
- Keep `SKILL.md` focused; put long references under `references/` if needed.
