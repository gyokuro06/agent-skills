---
name: story-dev
description: >
  Use when given a user story or “やりたいこと” and the work should follow the default
  delivery loop: align intent, create a branch, Gauge Red, implement to Green, refactor—
  committing after each phase. Do not use for alignment-only sessions (use align-clash),
  for Gauge TDD on an already-agreed slice without the full loop (use gauge-tdd), or for
  drive-by edits that skip alignment and phase commits.
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, user-story, tdd, gauge, branch, commits
---

# Story Dev

Default delivery process for a user story: **align → branch → Gauge Red → Green → refactor**, with a **git commit after each completed phase**. Do not skip gates or collapse phases into one commit.

## Process

Follow in order. Match the human’s language (e.g. Japanese) unless they ask otherwise.

### Phase 0 — Align (`align-clash`)

1. Load and follow the **`align-clash`** skill end-to-end.
2. **Gate:** Human-confirmed alignment brief with `Ready for next step: yes`.  
   If not ready, stay in alignment. Do not create a branch or write tests yet.

### Phase 1 — Branch

1. From the brief’s Intent, create `feature/<short-slug>` (or the repo’s usual prefix).
2. Optionally record the alignment brief in-repo only if the project already keeps such docs; do not invent a docs tree.
3. **Commit** this phase, e.g. `chore: start <slug> from aligned story`.
4. **Gate:** On the feature branch with a phase commit before any Gauge work.

### Phase 2 — Gauge Red (`gauge-tdd`)

1. Follow **`gauge-tdd`** Red only for the smallest vertical slice in the brief.
2. Prove failure with a real Gauge (or project test) run.
3. **Commit**, e.g. `test: add failing Gauge scenarios for <slice>`.
4. **Gate:** Failing scenarios committed; no production fix in this commit.

### Phase 3 — Green (`gauge-tdd`)

1. Follow **`gauge-tdd`** Green for that slice only.
2. **Commit**, e.g. `feat: <slice> to pass Gauge`.
3. **Gate:** Targeted scenarios green; commit contains the minimal fix.

### Phase 4 — Refactor (`gauge-tdd`)

1. Follow **`gauge-tdd`** Refactor if structure needs improvement; if nothing to improve, say so and skip the commit.
2. Otherwise **Commit**, e.g. `refactor: <what improved>`.
3. **Gate:** Still green; no behavior change.

### More slices

If the brief has more in-scope slices, repeat Phases 2–4 per slice (each Red/Green/Refactor still commits separately). Do not reopen alignment unless scope or intent changes; if it does, return to Phase 0.

## Commits

- One commit **per completed phase** (and per slice cycle for 2–4).
- Never combine Red+Green, or Green+Refactor, in one commit.
- Follow the repo’s existing commit style when present; otherwise conventional commits as above.
- Do not push unless the human asks.

## Done when

- Alignment brief was confirmed
- Feature branch exists
- At least one slice went Red → Green (Refactor optional) with phase commits
- Working tree matches the last phase commit (no silent leftover WIP from collapsed phases)

## Anti-patterns

- Implementing before alignment is confirmed
- Skipping branch creation “to go faster”
- Writing production code in the Red commit
- One big commit for the whole story
- Expanding Out of scope mid-flight without re-aligning
- Replacing Gauge with ad-hoc manual checks
- Invoking this skill when the human only wanted a clash session or a single TDD step
