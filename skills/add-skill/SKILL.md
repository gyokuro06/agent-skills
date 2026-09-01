---
name: add-skill
description: >
  Use when adding a new Agent Skill from any project or repository. Picks the
  right harness surface (skill vs agent vs rule vs script), decides universal
  (agent-skills) vs project-specific (.cursor/skills or .claude/skills),
  enforces focus and overlap gates, applies shared authoring standards,
  validates, and runs activation tests. Do not use for editing an existing
  skill unless also creating a new skill package.
metadata:
  origin: gyokuro06-agent-skills
---

# Add Skill

Create an Agent Skill with one shared authoring standard. Follow the steps in order; **gates** must pass before writing files or installing.

| Scope | Location | After create |
| --- | --- | --- |
| **Universal** | `agent-skills/skills/<name>/SKILL.md` | `./install.sh` in agent-skills |
| **Project** | `<project>/.cursor/skills/<name>/SKILL.md` and/or `.claude/skills/<name>/SKILL.md` | None (harness discovers in-repo) |

Use **both** project paths when the team uses Cursor and Claude Code in the same repo.

## 1. Resolve context

Run from the **project where the skill should live** (for project skills) or any directory (for universal skills).

**Project root:**

```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
```

**agent-skills repo** — try in order:

1. `$AGENT_SKILLS_DIR` if set and `validate.sh` exists there
2. Current directory if it contains `validate.sh` and `skills/`
3. Parent of any installed skill symlink, e.g. `readlink ~/.cursor/skills/story-dev` → `…/agent-skills/skills/story-dev` → repo is two levels up
4. Ask the user for the clone path if still unknown

```bash
AGENT_SKILLS_DIR="<resolved absolute path>"
```

## 2. Surface check (gate)

Before choosing a skill, decide the **harness surface**. If a skill is not the right fit, **stop** and propose the alternative — do not create a skill-shaped document for something else.

| Need | Surface | Where |
| --- | --- | --- |
| Always-on constraints | **Rules** | Project rules mechanism (e.g. `.cursor/rules/`, `.claude/CLAUDE.md` facts that should not be procedures) |
| On-demand playbook | **Skill** | This workflow — universal or project paths above |
| Phase isolation + evidence return | **Thin agent** + skill | `agents/<name>.md` (see README “Adding an Agent”) + canonical `SKILL.md` |
| Deterministic one-shot execution | **Script** | `scripts/` beside the skill; skill tells the agent **when** to run it |

**Multi-phase workflows:** even when the primary artifact is a skill, **always** consider whether a thin agent should own a phase (fresh context, tool limits, evidence format). Point to README “Adding an Agent”; do not duplicate agent bodies into the skill.

**Gate:** Confirmed that a **skill** is the right surface. If not, exit with a concrete recommendation (rule file, agent stub, or script).

## 3. Choose destination

Pick **one** scope before writing files. If unclear, use AskQuestion or ask conversationally.

**Universal → agent-skills** when the skill:

- Applies across multiple repos or stacks
- Has no dependency on one codebase’s layout, services, or team-only conventions
- Should be symlinked globally via `install.sh`

**Project → `.cursor/skills/` and/or `.claude/skills/`** when the skill:

- Encodes this repo’s architecture, naming, tools, or domain rules
- References paths, APIs, or workflows unique to this repository
- Would be noise or wrong if installed for every project

Do **not** create project skills inside `agent-skills/skills/` unless they truly belong in the shared library.

## 4. Focus, category, and overlap (gate)

### Focus

One skill = **one domain or one workflow**. If the name or intent is too broad, **stop** and ask the user to narrow scope before creating files.

| PASS (focused) | FAIL (too broad) |
| --- | --- |
| `react-hook-patterns` | `react` |
| `postgresql-indexing` | `databases` |
| `gauge-red-workflow` | `testing` |

### Category

Pick **one** category. Set `metadata.tags` to include it (e.g. `tags: workflow, gauge, tdd`).

| Category | Examples | Body shape | Required content |
| --- | --- | --- | --- |
| **Language** | `python-patterns`, `rust-idioms` | Principles | PASS/FAIL code pairs; copy-paste snippets |
| **Framework** | `nextjs-patterns`, `django-models` | Principles | PASS/FAIL; structure or API examples |
| **Workflow** | `code-review-workflow`, `deploy-checklist` | Procedure | Checklists; **Done when** includes evidence format (command + excerpt or artifact name) |
| **Domain** | `security-review`, `api-design` | Principles | Anti-patterns; verification checklist |
| **Tool** | `docker-patterns`, `playwright-e2e` | Procedure or Principles | Runnable commands or config snippets |

Body shape **A = Procedure / gate**, **B = Principles / reference** (see step 7).

### Overlap check

Before creating, scan existing skills in **both** libraries:

```bash
# Universal library
ls "$AGENT_SKILLS_DIR/skills/"

# Project (if destination is project)
ls "$PROJECT_ROOT/.cursor/skills/" 2>/dev/null
ls "$PROJECT_ROOT/.claude/skills/" 2>/dev/null
```

If a near-duplicate exists, **stop** and propose one of: extend the existing skill, rename/narrow scope, or explicit non-overlap in `description` (`Do not use when …`). Do not ship a second skill that differs only in wording.

**Gate:** Focus is narrow, category chosen, no unresolved overlap.

## 5. Confirm schema has not drifted

```bash
"$AGENT_SKILLS_DIR/validate.sh" --schema
```

If this fails, update `schemas/skill.schema.json` (and `scripts/validate.mjs` `SPEC_FIELDS` if the upstream field set changed) in agent-skills before authoring. Source of truth: https://agentskills.io/specification

## 6. Create the skill directory

`<name>` must be kebab-case and match frontmatter `name`.

**Universal:**

```text
$AGENT_SKILLS_DIR/skills/<name>/SKILL.md
```

**Project** (create the path(s) your harness uses):

```text
$PROJECT_ROOT/.cursor/skills/<name>/SKILL.md
$PROJECT_ROOT/.claude/skills/<name>/SKILL.md
```

When both harnesses are in use, keep **one** canonical `SKILL.md` and symlink the other path to it, or duplicate only if the repo policy requires separate trees.

## 7. Write frontmatter (discovery) then body (playbook)

### Length budget

| `SKILL.md` size | Action |
| --- | --- |
| ≤ ~200 lines | Ideal |
| 200–500 lines | Acceptable; prefer moving detail out |
| > 500 lines | **Stop** — move overflow to `references/` or `reference.md`; body keeps only triggers **when** to read each file |

### Frontmatter — recommended minimum

Portable fields only. Required by spec: `name`, `description`. Always set `metadata.origin` and `metadata.tags` (include category):

| Scope | `metadata.origin` |
| --- | --- |
| Universal | `gyokuro06-agent-skills` |
| Project | `<owner>/<repo>` from `git remote get-url origin`, or the directory name if no remote |

```yaml
---
name: example-skill
description: >
  Use when <concrete triggers / user intents>. <What the skill does in one sentence>.
  Do not use when <adjacent cases that would over-trigger>.
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, example
---
```

Optional (use only when needed): `license`, `compatibility`, `allowed-tools` (space-separated).

Do **not** add tool-specific fields (`disable-model-invocation`, `paths`, `hooks`, `argument-hint`, etc.).

### `description` rules (discovery)

Agents load only `name` + `description` until the skill is selected. The body does **not** participate in discovery.

- Lead with `Use when …` (imperative / third person)
- Include trigger keywords the user might say
- State what the skill does in one clear sentence
- Add `Do not use when …` when near-miss skills or tasks exist
- Keep under 1024 characters; prefer a short paragraph over a vague one-liner

Do **not** rely on a body `## When to Use` section for triggering. Optional after load for boundary notes; link **Related skills** when overlap risk exists.

### Body — shape and category extras

Choose **one** primary shape from step 4. Add category **required content** from the table. Do not cargo-cult empty sections.

**A. Procedure / gate** — skeleton:

```markdown
# <Action-oriented title>

<1–2 sentences: goal and non-goals>

## Process
1. …
2. … (gates / order matter)

## Done when
- …
- (Workflow category) Evidence: `<command>` + pass/fail excerpt or named artifact

## Anti-patterns
- …

## Related skills
- `nearby-skill` — use when …
```

**B. Principles / reference** — skeleton:

```markdown
# <Domain> Principles

## <Principle area>
…

## Anti-patterns
### FAIL: …
### PASS: …

## Related skills
- `nearby-skill` — use when …
```

Write only what the agent would get wrong without this skill. Prefer procedures, gates, output templates, PASS/FAIL pairs, and gotchas over generic advice.

## 8. Self-check before validate

- [ ] Surface is skill (step 2 passed)
- [ ] Destination matches scope (universal vs project)
- [ ] Focus narrow; category set in `metadata.tags`
- [ ] Overlap resolved (step 4)
- [ ] `description` alone is enough to know when to load this skill
- [ ] Body matches procedure **or** principles; category required content present
- [ ] `SKILL.md` ≤ 500 lines (overflow in `references/`)
- [ ] No tool-specific frontmatter
- [ ] `metadata.origin` reflects the owning repo
- [ ] Multi-phase workflow: thin agent considered (step 2)

## 9. Validate the new skill

```bash
"$AGENT_SKILLS_DIR/validate.sh" /absolute/path/to/skills/<name>
# project example:
"$AGENT_SKILLS_DIR/validate.sh" "$PROJECT_ROOT/.cursor/skills/<name>"
```

Fix any errors before continuing.

## 10. Activation test

In the **same session**, self-test discovery behavior before install.

Draft and run:

- **2–3 positive prompts** — should load this skill (or match its domain)
- **2–3 negative prompts** — adjacent intents that should **not** load this skill

Record prompts and observed behavior in the PR description or a short comment to the user.

| Scope | Required? |
| --- | --- |
| Universal | **Yes** — do not run `./install.sh` until activation looks right |
| Project | Optional but recommended |

If positives fail or negatives fire the skill, revise `description` (and Related skills / Do not use when) and re-test.

## 11. Install (universal only)

```bash
cd "$AGENT_SKILLS_DIR" && ./install.sh
```

Project skills need no install step.

## Notes

- `./validate.sh` checks (a) local schema ↔ agentskills.io field set, (b) `skills-reference` official rules, (c) local JSON Schema (including string-only `metadata`).
- Authoritative skill-authoring guidance lives in **this** skill; keep README’s “Adding a Skill” section as a short pointer, not a second template.

### Promoting a project skill to universal

When copying into `agent-skills/skills/<name>/`:

- [ ] Strip repo-specific paths, service names, and team-only conventions — or gate them behind “if this repo …”
- [ ] Set `metadata.origin: gyokuro06-agent-skills`
- [ ] Re-run overlap check against `agent-skills/skills/`
- [ ] Generalize examples; no secrets or environment-specific URLs
- [ ] `validate.sh` + activation test (step 10, required)
- [ ] `./install.sh`
