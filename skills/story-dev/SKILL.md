---
name: story-dev
description: >
  Use when given a user story or “やりたいこと” and the work should follow the default
  delivery loop: align intent, create a branch, Gauge Red, implement to Green, refactor—
  committing after each phase, delegating phases to story-* subagents. Do not use for
  alignment-only sessions (use story-align or align-clash), for a single Gauge TDD step
  without the full loop (use story-gauge-red / story-green / story-refactor or gauge-tdd),
  or for drive-by edits that skip alignment and phase commits.
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, user-story, tdd, gauge, branch, commits, subagents
---

# Story Dev

Default delivery process for a user story: **align → branch → Gauge Red → Green → refactor**, with a **git commit after each completed phase**. Do not skip gates or collapse phases into one commit.

## Design (skills vs agents)

Inspired by ECC-style harness design: **skills hold the playbook; agents are scoped workers with fresh context and tool limits.**

| Surface | Job here |
| --- | --- |
| Skill `story-dev` | Orchestrate the loop, own gates, branch, and phase commits |
| Skills `align-clash`, `gauge-tdd` | Canonical phase playbooks (detail lives here, not duplicated in agents) |
| Agents `story-*` | Isolate each phase; enforce one gate; return **evidence** to the parent |

```text
story-dev (skill)
  -> story-align        + align-clash     -> Alignment brief (gate)
  -> parent             branch + commit
  -> story-gauge-red    + gauge-tdd Red   -> RED evidence  + commit
  -> story-green        + gauge-tdd Green -> GREEN evidence + commit
  -> story-refactor     + gauge-tdd Refactor -> REFACTOR evidence (+ commit or skip)
```

A phase result is a **trail of evidence** (brief / failing run / passing run / still-green), not “I think it’s done.”

**Orchestration rule:** Delegate Phases 0/2/3/4 to the matching subagent when installed. Do not inline those playbooks in the parent. Standalone use of `align-clash` / `gauge-tdd` remains valid outside this full loop.

| Phase | Subagent | Playbook skill | Responsibility |
| --- | --- | --- | --- |
| 0 Align | `story-align` | `align-clash` | Clash → confirmed alignment brief |
| 1 Branch | *(parent)* | — | `feature/<slug>` + phase commit |
| 2 Red | `story-gauge-red` | `gauge-tdd` (Red) | Failing Gauge + RED evidence |
| 3 Green | `story-green` | `gauge-tdd` (Green) | Minimal fix + GREEN evidence |
| 4 Refactor | `story-refactor` | `gauge-tdd` (Refactor) | Structure only; or skip |

## Process

Follow in order. Match the human’s language (e.g. Japanese) unless they ask otherwise.

### Phase 0 — Align (`story-align`)

1. Delegate to **`story-align`** with the user story / やりたいこと and any constraints.
2. **Gate:** Human-confirmed alignment brief with `Ready for next step: yes`.  
   If not ready, stay in alignment. Do not create a branch or write tests yet.

### Phase 1 — Branch

1. From the brief’s Intent, create `feature/<short-slug>` (or the repo’s usual prefix).
2. Optionally record the alignment brief in-repo only if the project already keeps such docs; do not invent a docs tree.
3. **Commit** this phase, e.g. `chore: start <slug> from aligned story`.
4. **Gate:** On the feature branch with a phase commit before any Gauge work.

### Phase 2 — Gauge Red (`story-gauge-red`)

1. Delegate to **`story-gauge-red`** with the confirmed brief and one vertical slice.
2. Require **RED evidence** (command + failure excerpt) in the subagent result.
3. **Commit**, e.g. `test: add failing Gauge scenarios for <slice>`.
4. **Gate:** Failing scenarios committed; no production fix in this commit.

### Phase 3 — Green (`story-green`)

1. Delegate to **`story-green`** with the brief, slice id, and RED evidence / paths.
2. Require **GREEN evidence** (command + pass excerpt).
3. **Commit**, e.g. `feat: <slice> to pass Gauge`.
4. **Gate:** Targeted scenarios green; commit contains the minimal fix.

### Phase 4 — Refactor (`story-refactor`)

1. Delegate to **`story-refactor`** with GREEN evidence for the slice.
2. If status is `skipped`, do not commit. Otherwise require still-green evidence and **Commit**, e.g. `refactor: <what improved>`.
3. **Gate:** Still green; no behavior change.

### More slices

If the brief has more in-scope slices, repeat Phases 2–4 per slice (each Red/Green/Refactor still commits separately). Do not reopen alignment unless scope or intent changes; if it does, return to Phase 0 (`story-align`).

## Commits

- One commit **per completed phase** (and per slice cycle for 2–4).
- Never combine Red+Green, or Green+Refactor, in one commit.
- Follow the repo’s existing commit style when present; otherwise conventional commits as above.
- Do not push unless the human asks.
- Subagents prepare the work and evidence; the **parent** owns the phase commits unless the human asked the subagent to commit.

## Done when

- Alignment brief was confirmed
- Feature branch exists
- At least one slice went Red → Green (Refactor optional) with phase commits and evidence
- Working tree matches the last phase commit (no silent leftover WIP from collapsed phases)

## Anti-patterns

- Implementing before alignment is confirmed
- Skipping branch creation “to go faster”
- Writing production code in the Red commit
- One big commit for the whole story
- Expanding Out of scope mid-flight without re-aligning
- Replacing Gauge with ad-hoc manual checks
- Accepting a phase without RED/GREEN/REFACTOR evidence
- Duplicating full `align-clash` / `gauge-tdd` playbooks inside the parent when `story-*` agents are installed
- Invoking this skill when the human only wanted a clash session or a single TDD step
