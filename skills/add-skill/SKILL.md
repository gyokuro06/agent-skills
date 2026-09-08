---
name: add-skill
description: >
  Use when adding a new harness capability from any project or repository—
  Agent Skill, always-on Rule, thin subagent, or skill-adjacent script. Routes
  to the right surface, chooses universal (agent-skills) vs project-specific
  paths, enforces focus and overlap gates, authors to shared standards,
  validates, and installs when needed. Do not use only for drive-by edits to an
  existing package unless also creating a new one.
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, harness, authoring, skills, rules, agents
---

# Add Skill (harness surface router)

Create the **right harness surface**, not always a skill. Follow the steps in order; **gates** must pass before writing files or installing.

| Surface | Universal (agent-skills) | Project | After create |
| --- | --- | --- | --- |
| **Skill** | `skills/<name>/SKILL.md` | `.cursor/skills/<name>/` and/or `.claude/skills/<name>/` | `./install.sh` (universal) |
| **Rule** | `rules/<name>.mdc` | `.cursor/rules/<name>.mdc` and/or `.claude/rules/<name>.md` | `./install.sh` (universal) |
| **Agent** | `agents/<name>.md` | usually universal only; pair with a skill | `./install.sh` |
| **Script** | `skills/<name>/scripts/…` (beside a skill) | same under project skill | skill tells **when** to run it |

Use **both** Cursor and Claude project paths when the team uses both harnesses in the same repo.

## 1. Resolve context

Run from the **project where the artifact should live** (for project scope) or any directory (for universal).

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

## 2. Surface check (gate) — route, then create

Decide the **harness surface** first. Do **not** force a skill-shaped document for a rule, agent, or script need.

| Need | Surface | Create where |
| --- | --- | --- |
| Always-on (or path-scoped) constraints | **Rule** | Universal `rules/<name>.mdc` or project `.cursor/rules/` / `.claude/rules/` — then follow **§ Rule path** |
| On-demand playbook | **Skill** | Universal `skills/<name>/` or project skills dirs — then follow **§ Skill path** |
| Phase isolation + evidence return | **Thin agent** (+ skill playbook) | `agents/<name>.md` + canonical `SKILL.md` — then follow **§ Agent path** |
| Deterministic one-shot execution | **Script** | `scripts/` beside the skill; skill says **when** to run it |

**Multi-phase workflows:** even when the primary artifact is a skill, **always** consider whether a thin agent should own a phase (fresh context, tool limits, evidence format).

**Gate:** Surface chosen. Continue on that path — do **not** stop at a verbal recommendation when the user asked you to add the capability and the destination is clear.

Confirm with the user only when surface or scope is ambiguous.

## 3. Choose destination (all surfaces)

Pick **one** scope before writing files. If unclear, ask.

**Universal → agent-skills** when the artifact:

- Applies across multiple repos or stacks
- Has no dependency on one codebase’s layout, services, or team-only conventions
- Should be symlinked globally via `./install.sh`

**Project** when the artifact:

- Encodes this repo’s architecture, naming, tools, or domain rules
- References paths, APIs, or workflows unique to this repository
- Would be noise or wrong if installed for every project

Do **not** put project-only conventions into universal `skills/` or `rules/` unless they truly belong in the shared library.

---

# Rule path

## R1. Focus and overlap

- One rule = **one concern**. Prefer ≤ ~50 lines; hard stop around 500.
- Scan existing rules before creating:

```bash
ls "$AGENT_SKILLS_DIR/rules/" 2>/dev/null
ls "$PROJECT_ROOT/.cursor/rules/" 2>/dev/null
ls "$PROJECT_ROOT/.claude/rules/" 2>/dev/null
```

- If a near-duplicate exists, extend it or narrow scope — do not ship a second rule that differs only in wording.
- Check skills for the same topic: if the need is always-on, **prefer rule** and avoid a parallel skill unless a deep on-demand playbook is still useful.

## R2. Author the rule file

`<name>` is kebab-case. Canonical universal file:

```text
$AGENT_SKILLS_DIR/rules/<name>.mdc
```

Project:

```text
$PROJECT_ROOT/.cursor/rules/<name>.mdc
$PROJECT_ROOT/.claude/rules/<name>.md
```

When both harnesses are in use for a **project** rule, keep one canonical body; symlink or duplicate with harness-appropriate extension/frontmatter.

### Frontmatter

**Always-on** (default for cross-cutting style constraints):

```yaml
---
description: <one line — what the rule enforces>
alwaysApply: true
---
```

**Path-scoped** (load when matching files are in play):

```yaml
---
description: <one line>
alwaysApply: false
globs: "**/*.ts,**/*.tsx"
paths: "**/*.ts,**/*.tsx"
---
```

- `globs` — Cursor
- `paths` — Claude Code (prefer a single CSV line; avoid YAML arrays if the harness is picky)
- Omit `paths`/`globs` when `alwaysApply: true`

### Body

Actionable constraints + short PASS/FAIL examples. No discovery essay — rules are injected, not selected by description matching like skills.

## R3. Install (universal only)

```bash
cd "$AGENT_SKILLS_DIR" && ./install.sh
```

`install.sh` links `rules/*.mdc` into `~/.cursor/rules/` (`.mdc`) and `~/.claude/rules/` (as `.md`). Codex has no rules target.

---

# Skill path

## S1. Focus, category, and overlap (gate)

### Focus

One skill = **one domain or one workflow**. If the name or intent is too broad, **stop** and ask to narrow scope.

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

Body shape **A = Procedure / gate**, **B = Principles / reference** (see S4).

### Overlap check

```bash
ls "$AGENT_SKILLS_DIR/skills/"
ls "$AGENT_SKILLS_DIR/rules/" 2>/dev/null
ls "$PROJECT_ROOT/.cursor/skills/" 2>/dev/null
ls "$PROJECT_ROOT/.claude/skills/" 2>/dev/null
```

If a **rule** already covers always-on constraints for the same topic, do not duplicate as a skill unless you need a deep on-demand playbook — and say so in `description` (`Do not use when …`).

If a near-duplicate skill exists, extend it, rename/narrow, or add explicit non-overlap. Do not ship a second skill that differs only in wording.

**Gate:** Focus is narrow, category chosen, no unresolved overlap.

## S2. Confirm schema has not drifted

```bash
"$AGENT_SKILLS_DIR/validate.sh" --schema
```

If this fails, update `schemas/skill.schema.json` (and `scripts/validate.mjs` `SPEC_FIELDS` if the upstream field set changed) before authoring. Source of truth: https://agentskills.io/specification

## S3. Create the skill directory

`<name>` must be kebab-case and match frontmatter `name`.

**Universal:**

```text
$AGENT_SKILLS_DIR/skills/<name>/SKILL.md
```

**Project:**

```text
$PROJECT_ROOT/.cursor/skills/<name>/SKILL.md
$PROJECT_ROOT/.claude/skills/<name>/SKILL.md
```

When both harnesses are in use, keep **one** canonical `SKILL.md` and symlink the other path to it, or duplicate only if the repo policy requires separate trees.

## S4. Write frontmatter (discovery) then body (playbook)

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

Choose **one** primary shape from S1. Add category **required content** from the table. Do not cargo-cult empty sections.

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

## S5. Self-check before validate

- [ ] Surface is skill (step 2)
- [ ] Destination matches scope (universal vs project)
- [ ] Focus narrow; category set in `metadata.tags`
- [ ] Overlap resolved (including rules/)
- [ ] `description` alone is enough to know when to load this skill
- [ ] Body matches procedure **or** principles; category required content present
- [ ] `SKILL.md` ≤ 500 lines (overflow in `references/`)
- [ ] No tool-specific frontmatter
- [ ] `metadata.origin` reflects the owning repo
- [ ] Multi-phase workflow: thin agent considered (step 2)

## S6. Validate the new skill

```bash
"$AGENT_SKILLS_DIR/validate.sh" /absolute/path/to/skills/<name>
# project example:
"$AGENT_SKILLS_DIR/validate.sh" "$PROJECT_ROOT/.cursor/skills/<name>"
```

Fix any errors before continuing.

## S7. Activation test

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

## S8. Install (universal only)

```bash
cd "$AGENT_SKILLS_DIR" && ./install.sh
```

Project skills need no install step.

---

# Agent path

Thin agents own a **phase**: fresh context, tool limits, evidence return. Detail lives in a **canonical skill**.

1. Ensure the playbook skill exists (or create it via **Skill path** first).
2. Create `$AGENT_SKILLS_DIR/agents/<name>.md` with frontmatter (`name`, `description`, preferably `model: inherit`) and a thin body: role, gates, evidence format, pointer to the skill.
3. Prefer `tools:` allowlists and `skills:` preload when targeting Claude Code; `readonly` when appropriate for Cursor.
4. Keep `name` kebab-case; filename matches.
5. Wire orchestration (e.g. `story-dev`) to delegate by that `name`; do not duplicate the full skill body into the agent.
6. `./install.sh`

See README “Adding an Agent” for the short checklist; this skill is the router entry point.

---

# Notes

- `./validate.sh` checks skills (schema ↔ agentskills.io, skills-reference, local JSON Schema). Rules are not schema-validated the same way — keep them short and review frontmatter by harness.
- Authoritative authoring guidance for skills/rules/agents lives in **this** skill; keep README sections as short pointers.
- Name remains `add-skill` for discovery continuity; behavior is **surface routing**, not “skills only.”

### Promoting a project skill to universal

When copying into `agent-skills/skills/<name>/`:

- [ ] Strip repo-specific paths, service names, and team-only conventions — or gate them behind “if this repo …”
- [ ] Set `metadata.origin: gyokuro06-agent-skills`
- [ ] Re-run overlap check against `agent-skills/skills/` and `rules/`
- [ ] Generalize examples; no secrets or environment-specific URLs
- [ ] `validate.sh` + activation test (S7, required)
- [ ] `./install.sh`

### Promoting a project rule to universal

When copying into `agent-skills/rules/<name>.mdc`:

- [ ] Strip repo-only paths and team jargon (or gate behind “if this repo …”)
- [ ] Prefer `alwaysApply: true` only if it should hit every session globally
- [ ] Re-run overlap check against `rules/` and related skills
- [ ] `./install.sh`
