---
name: scored-review
description: >
  Use when qualitatively reviewing an implementation after tests are green—
  adversarial critique plus structure/clarity, with per-criterion scores and a
  pass threshold (shift-left: in the implement loop, not only at PR time). Do not
  use to write production code, run Gauge Red, or replace human product decisions.
  Within story-dev, prefer the story-review subagent immediately after each green.
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, review, adversarial, quality, scoring, feedback
---

# Scored Review

Qualitative review **after** targeted tests are green. Produce a **scored verdict** the orchestrator can use to re-delegate implementation or stop. Do not edit production or test code in this skill’s agent role.

This skill is the **canonical playbook** for `story-review`. Tune rubrics here as feedback arrives; keep the agent thin.

## Tunables (edit freely)

| Knob | Default | Notes |
| --- | --- | --- |
| Pass threshold | **70** / 100 | Total ≥ threshold → pass |
| Max re-delegate rounds | **3** | Orchestrator-owned; stated here for shared defaults |
| Scoring | Integer points per criterion; sum = total | Higher is better |

When changing defaults, bump the **Rubric version** below so evidence trails stay comparable.

**Rubric version:** `2026-09-02.1`

## Rubric (100 points)

Score each criterion from 0 to its max. Partial credit is allowed. Cite concrete file/behavior evidence for any deduction.

| Id | Criterion | Max | Adversarial / structural focus |
| --- | --- | --- | --- |
| `brief-fit` | Matches alignment brief (Intent, Success, In scope) | 25 | Missed acceptance, silent scope creep |
| `adversarial` | Edge cases, misuse, failure modes the slice should handle | 25 | What a hostile user / empty / concurrent / stale state does |
| `structure` | Clarity, layering, naming, duplication, Coupling | 25 | Hard to change safely; god objects; leaky steps/POM |
| `test-gaps` | Gauge/tests cover the risky behavior (not just happy path) | 15 | Green but blind spots remain |
| `scope-discipline` | No drive-by features; Out of scope respected | 10 | Extra surface area |

**Pass:** `total >= 70`  
**Fail (re-delegate):** `total < 70`

Findings that block a high score should be **actionable** for the implement agent (what to change, where, why)—not vague taste notes.

## Process

1. Inputs: alignment brief bounds, slice id, GREEN evidence (command + pass excerpt), production/test paths, prior review rounds if any.
2. If green evidence is missing or stale, stop and tell the parent to obtain fresh GREEN evidence first.
3. Read the diff / relevant files. Attack the slice (adversarial) and judge structure.
4. Score every rubric row; sum to `total`.
5. List findings ordered by impact. Each finding: severity (`blocker` \| `major` \| `minor`), criterion id, location, problem, suggested fix direction.
6. Verdict: `pass` if total ≥ threshold, else `redelegate`.
7. **Do not** edit code. Return evidence only.

## Evidence format

```markdown
## REVIEW evidence
- Rubric version: <version>
- Slice: <name>
- Round: <1-based>
- Total: <n>/100
- Threshold: 70
- Verdict: pass | redelegate
- Scores:
  - brief-fit: <n>/25 — <one line>
  - adversarial: <n>/25 — <one line>
  - structure: <n>/25 — <one line>
  - test-gaps: <n>/15 — <one line>
  - scope-discipline: <n>/10 — <one line>
- Findings:
  1. [<severity>] [<criterion-id>] <location> — <problem> → <fix direction>
  - (or none)
- Re-delegate brief: <concrete instructions for story-green, or n/a if pass>
```

## Done when

- Every rubric row has a score and one-line rationale
- Verdict matches threshold rule
- Evidence block is complete; no code edits by the reviewer
- On `redelegate`, `Re-delegate brief` is specific enough for `story-green` without re-discovering the complaint

## Anti-patterns

- Editing code “while reviewing”
- Passing because tests are green without qualitative scoring
- Vague findings (“clean this up”) with no location or fix direction
- Punishing style prefs unrelated to brief, adversarial risk, or changeability
- Inventing new requirements outside the alignment brief
- Collapsing all deductions into one opaque total without per-criterion scores

## Related skills

- `story-dev` — orchestrates implement ↔ review loop and phase commits
- `gauge-tdd` — Red/Green playbook; green evidence is a prerequisite here
- `align-clash` — brief bounds the review; do not re-open clash inside review
