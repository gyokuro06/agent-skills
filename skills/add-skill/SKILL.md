---
name: add-skill
description: Use when adding a new Agent Skill to this repository. Runs schema/spec sync checks before creating skills/<name>/SKILL.md, then validates and installs. Do not use for editing an existing skill's behavior unless also creating a new skill package.
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

3. **Write frontmatter (discovery) then body (playbook)**

### Frontmatter — recommended minimum

Portable fields only. Required by spec: `name`, `description`.  
In this repo always set `metadata.origin`.

```yaml
---
name: example-skill
description: >
  Use when <concrete triggers / user intents>. <What the skill does in one sentence>.
  Do not use when <adjacent cases that would over-trigger>.
metadata:
  origin: gyokuro06-agent-skills
---
```

Optional (use only when needed): `license`, `compatibility`, `allowed-tools` (space-separated), extra `metadata` string keys (e.g. `tags` as one comma-separated string).

Do **not** add tool-specific fields (`disable-model-invocation`, `paths`, `hooks`, `argument-hint`, etc.).

### `description` rules (this is what triggers the skill)

Agents load only `name` + `description` until the skill is selected. The body does **not** participate in discovery.

- Lead with `Use when …` (imperative / third person)
- Include trigger keywords the user might say
- State what the skill does in one clear sentence
- Add `Do not use when …` when near-miss skills or tasks exist
- Keep under 1024 characters; prefer a short paragraph over a vague one-liner

Do **not** rely on a body `## When to Use` section for triggering. That heading is optional prose after load; omit it unless a short boundary note still helps once the skill is already active.

### Body — pick a shape

Choose **one** primary shape. Do not cargo-cult unused sections.

**A. Procedure / gate** (workflows, multi-phase processes) — example skeleton:

```markdown
# <Action-oriented title>

<1–2 sentences: goal and non-goals>

## Process
1. …
2. … (gates / order matter)

## Done when
- …

## Anti-patterns
- …
```

**B. Principles / reference** (constraints while editing code) — example skeleton:

```markdown
# <Domain> Principles

## <Principle area>
…

## Anti-patterns
- …
```

Write only what the agent would get wrong without this skill. Prefer procedures, gates, output templates, and gotchas over generic advice.

Long material: put under `references/` and tell the agent **when** to read each file (not a vague “see references/”).

4. **Self-check before validate**

- [ ] `description` alone is enough to know when to load this skill
- [ ] Body matches procedure **or** principles (not a hollow “When to Use” stub)
- [ ] Each body section would change agent behavior if removed
- [ ] No tool-specific frontmatter

5. **Validate the new skill**

```bash
./validate.sh skills/<name>
```

Fix any errors before continuing.

6. **Install symlinks**

```bash
./install.sh
```

## Notes

- `./validate.sh` checks (a) local schema ↔ agentskills.io field set, (b) `skills-reference` official rules, (c) local JSON Schema (including string-only `metadata`).
- Keep `SKILL.md` focused; progressive disclosure via `references/` when needed.
- Authoritative skill-authoring guidance for this repo lives in **this** skill; keep README’s “Adding a Skill” section as a short pointer, not a second template.
