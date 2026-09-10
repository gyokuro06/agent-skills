---
name: story-dev
description: >
  Use when given a user story or “やりたいこと” and the work should follow the default
  delivery loop: align intent, create a branch, Gauge Red, then implement↔scored-review
  until pass (re-delegate on fail)—committing after each implement green, delegating
  phases to story-* subagents, and only returning to the human after review pass or
  escalation with a concise 実装→レビュー→…→リファクタリング trail. Do not use for
  alignment-only sessions (use story-align or align-clash), for a single Gauge TDD
  step without the full loop (use story-gauge-red / story-green / story-review or
  gauge-tdd / scored-review), or for drive-by edits that skip alignment and phase
  commits.
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, user-story, tdd, gauge, branch, commits, subagents, review
---

# Story Dev

Default delivery process for a user story: **align → branch → Gauge Red → implement↔scored review until pass**, with a **git commit each time implementation reaches green**. Do not skip gates or collapse phases into one commit.

**Orchestrator only:** This skill gates, branches, commits, and delegates. It does **not** inline phase playbooks, invent review scores, or implement/fix code itself.

## Design (skills vs agents)

Inspired by ECC-style harness design: **skills hold the playbook; agents are scoped workers with fresh context and tool limits.**

| Surface | Job here |
| --- | --- |
| Skill `story-dev` | Orchestrate the loop, own gates, branch, and implement commits |
| Skills `align-clash`, `gauge-tdd`, `scored-review` | Canonical phase playbooks (detail lives here, not duplicated in agents) |
| Agents `story-*` | Isolate each phase; enforce one gate; return **evidence** to the parent |

```text
story-dev (skill)
  -> story-align        + align-clash      -> Alignment brief (gate)
  -> parent             branch + commit
  -> story-gauge-red    + gauge-tdd Red    -> RED evidence  + commit
  -> [no human return until Review pass or escalate]
       story-green      + gauge-tdd Green  -> GREEN evidence + commit
       story-review     + scored-review    -> REVIEW evidence
             |-- pass (>= threshold) -> slice done; human return + loop trail
             |-- redelegate (< threshold, rounds left) -> story-green again -> commit -> review
             |-- still failing after max rounds -> escalate to human + loop trail
```

A phase result is a **trail of evidence** (brief / failing run / passing run / scored review), not “I think it’s done.”

**Orchestration rule:** Delegate Phases 0/2/3/4 to the matching subagent when installed. Do not inline those playbooks in the parent. Standalone use of `align-clash` / `gauge-tdd` / `scored-review` remains valid outside this full loop.

**Shift-left / human handoff:** After Red is committed, run **Implement → Review → (re-Implement → Review)…** as one continuous parent loop. **Do not** return control to the human after GREEN, after optional refactor, or “ready for PR.” Scored review belongs **in** this loop—not at PR-create time. Human-facing pause only when Review `pass` (slice/story complete enough to report) or max-rounds **escalate**.

| Phase | Subagent | Playbook skill | Responsibility |
| --- | --- | --- | --- |
| 0 Align | `story-align` | `align-clash` | Clash → confirmed alignment brief |
| 1 Branch | *(parent)* | — | `feature/<slug>` + phase commit |
| 2 Red | `story-gauge-red` | `gauge-tdd` (Red) | Failing Gauge + RED evidence |
| 3 Implement | `story-green` | `gauge-tdd` (Green) | Minimal fix + GREEN evidence |
| 4 Review | `story-review` | `scored-review` | Scored verdict; no code edits |

Phases 3–4 are one **delivery unit** toward the human: evidence still returns to the parent between subagents; the **human** is not a checkpoint between them.

**Loop trail (parent-owned):** While Phases 3–4 (and any optional refactor) run, append one short line per step to an in-memory trail. On the **first** human-facing return after the loop (Review `pass` or escalate), include that trail so the human can see **実装 → レビュー → 実装 → … → リファクタリング** at a glance. Do not wait until PR time to reconstruct it.

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

### Phase 3 — Implement (`story-green`)

1. Delegate to **`story-green`** with the brief, slice id, and RED evidence / paths (or REVIEW re-delegate brief on later rounds).
2. Require **GREEN evidence** (command + pass excerpt).
3. **Commit**, e.g. `feat: <slice> to pass Gauge` (or `fix:` on re-delegate rounds).
4. Append a **実装** trail line (see [Human return — loop trail](#human-return--loop-trail)).
5. **Gate:** Targeted scenarios green; commit contains the implementer’s changes only.
6. **Immediately** continue to Phase 4. Do not ask the human whether to review, refactor further, or open a PR.

### Phase 4 — Review (`story-review`)

1. Delegate to **`story-review`** with the brief, slice id, GREEN evidence, and round number. Do not score or rewrite the review in the parent.
2. Require **REVIEW evidence** (rubric version, per-criterion scores, total, verdict).
3. Append a **レビュー** trail line (see [Human return — loop trail](#human-return--loop-trail)).
4. **No commit** for review-only (reviewer does not edit). Then branch on verdict:

| Verdict | Parent action |
| --- | --- |
| `pass` (total ≥ threshold from `scored-review`) | Slice complete; next slice (Phases 2–4 again, still without mid-loop human pause) or **return to human** with the loop trail |
| `redelegate` and rounds used < max (default **3**, from `scored-review`) | Re-enter Phase 3 with the re-delegate brief; then Phase 4 again—**still no human pause** |
| `redelegate` and max rounds exhausted | **Escalate to human** with latest GREEN + REVIEW evidence **and** the loop trail; do not silently continue |

5. **Gate:** Pass, re-delegate, or human escalation—never parent-invented scores. Never treat “green + commit” as done for the human.

### Optional refactor (after Review `pass`, before human return)

If a structural cleanup runs while keeping Gauge green (gauge-tdd Refactor, or a brief tidy after pass):

1. Keep behavior/scope unchanged; re-run targeted scenarios if edits were meaningful.
2. **Commit** only if the parent would otherwise leave uncommitted WIP (`refactor:` …).
3. Append a **リファクタリング** trail line.
4. Do **not** pause for human approval mid-refactor; the trail is how the human sees it on return.

### More slices

If the brief has more in-scope slices, repeat Phases 2–4 per slice (each Red / Implement green still commits separately). Do not reopen alignment unless scope or intent changes; if it does, return to Phase 0 (`story-align`). Between slices, a short status line is fine; do not stop for PR/review rituals until the in-scope work finished or escalated.

## Commits

- Commit when **implementation is green** (Phase 3), including each re-delegate round that reaches green again.
- Commit optional refactor separately when it leaves a real diff (`refactor:` …).
- Never combine Red+Implement, or invent a commit for review-only output.
- Follow the repo’s existing commit style when present; otherwise conventional commits as above.
- Do not push unless the human asks.
- Subagents prepare the work and evidence; the **parent** owns the commits unless the human asked the subagent to commit.

## Human return — loop trail

When returning to the human after Review `pass` or escalate (per slice or story), include a **簡潔な経緯** before or beside the outcome. Parent synthesizes from GREEN/REVIEW evidence—do not dump full evidence blocks as the trail.

**Shape** (match the human’s language; Japanese example):

```markdown
## 経緯
1. 実装 — <one line: what changed / which files or behavior>
2. レビュー — <total>/100 · <pass|redelegate> — <one-line finding or “指摘なし”>
3. 実装 — <one line: what the re-delegate fixed>
4. レビュー — <total>/100 · pass — <one line>
5. リファクタリング — <one line: structural cleanup, or omit this step if none>
```

Rules:

- One numbered step per Implement / Review / Refactor that actually ran, in order
- Prefer **one short sentence** per step; no score tables or file dumps inside the trail
- Multi-slice: one `## 経緯` per slice (or a clear slice heading), then the story outcome
- Escalate: same trail shape, then latest REVIEW findings / re-delegate brief for the human

## Done when

- Alignment brief was confirmed
- Feature branch exists
- At least one slice went Red → Implement (green + commit) → Review `pass` (or human accepted escalation)
- Working tree matches the last implement (or refactor) commit (no silent leftover WIP from collapsed phases)
- The human was only brought back for Review `pass` / escalation / alignment—not after bare GREEN
- That human-facing return included the **loop trail** (実装 → レビュー → … → リファクタリング as applicable)

## Anti-patterns

- Parent implementing, reviewing, or scoring instead of delegating
- Implementing before alignment is confirmed
- Skipping branch creation “to go faster”
- Writing production code in the Red commit
- One big commit for the whole story
- Expanding Out of scope mid-flight without re-aligning
- Replacing Gauge with ad-hoc manual checks
- Accepting a phase without RED/GREEN/REVIEW evidence
- Letting `story-review` edit code, or skipping re-delegation when verdict is `redelegate` and rounds remain
- Returning to the human after GREEN or refactor “to decide next,” then doing adversarial review at PR time
- Asking whether to run scored review—Phase 4 is mandatory after every green commit in this loop
- Returning “done” / escalate **without** the chronological 実装→レビュー→… trail
- Pasting full REVIEW evidence as the only summary instead of one-line trail steps
- Duplicating full playbooks inside the parent when `story-*` agents are installed
- Invoking this skill when the human only wanted a clash session or a single TDD/review step
