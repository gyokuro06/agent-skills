---
name: align-clash
description: >
  Use when aligning on what to build before implementation—user stories, feature ideas,
  plans, or design decisions. Forces shared intent via one-question-at-a-time clash:
  each turn is a single multiple-choice question with a competing recommendation, then a
  confirmed alignment brief. Prefer this over open-ended grilling or polite agreement.
  Within story-dev, prefer the story-align subagent for the same Phase 0 work.
  Do not use when implementing, writing Gauge, or for post-hoc code review.
metadata:
  origin: gyokuro06-agent-skills
  tags: alignment, planning, intent, conflict, pre-implementation, q-and-a
---

# Align by Clash (一問一答)

Reach shared intent by **colliding** the human’s choices with the LLM’s competing recommendations—**one question at a time**. Socratic wandering is not the goal. The goal is a better answer to **what we are doing** (and what we are not).

This skill is the **canonical playbook** for the `story-align` subagent (and for alignment-only sessions without story-dev).

## Core Stance

1. The human is the decision owner; the LLM is a strong opposing thinker, not a clerk.
2. Agreement without conflict is weak. The **推奨** on each question is your competing claim—not mild polish of theirs.
3. Never jump to implementation, tickets, or code while clash is open.
4. Ask **one** decision at a time. Do not batch questions. Do not fill in their choice for them.
5. Do **not** use `AskQuestion` / `AskUserQuestion` (or equivalent UI question tools). Always use the format below in chat.

## Process

Follow in order. Match the human’s language (e.g. Japanese) unless they ask otherwise.

### Phase 1 — Seed the design tree

From the user story / やりたいこと / plan, treat the work as a **design tree**: each decision unlocks dependent decisions.

- If the human has not stated a position, ask once (still one question) for a short take: purpose, success, rough in/out—or start from what they already wrote.
- Environment facts you can verify yourself: look them up; do not ask the human.
- Prefer **depth over breadth**: dig one branch until new insight stops, then move on.

Do not offer your full competing brief up front. Compete **inside** each question’s options and 推奨.

### Phase 2 — One question at a time (clash)

While unresolved decisions remain, ask **exactly one** question per turn.

Use this format every time:

```markdown
### ❓ Q[番号]: [質問文]

[なぜこの質問が重要か — 1〜3文。対立している前提やトレードオフを明示]

- **A** — [選択肢]
- **B** — [選択肢]
- **C** — [選択肢]  ← 必要なら増減可。自由記述が妥当なら最後に「その他（記述）」を置く

**推奨: [A/B/...]** — [あなたの独立した主張と理由。人間案の言い換え禁止]
```

Rules for each question:

| Do | Don't |
| --- | --- |
| Force a real trade-off (scope, success metric, risk, priority) | Yes/no trivia or facts you could look up |
| Make **推奨** genuinely disagree when warranted | Soft “いずれも可” or echoing their last answer |
| Update the design tree after their reply | Ask the next question before acknowledging the choice |
| Park deferred conflicts with owner + why | Resolve unilaterally and move on silently |

After each answer: record the decision, revise open branches, pick the next highest-leverage undecided node.

### Phase 3 — Shared conclusion (gate)

When no material undecided nodes remain (or only explicitly parked items), stop questioning and write the brief:

```markdown
## Alignment brief
- Intent: <one sentence — what we are doing>
- Success: <observable outcomes>
- In scope: <bullets>
- Out of scope: <bullets>
- Key decisions: <bullets — resolved Qs / conflicts>
- Open items: <parked only, or "none">
- Ready for next step: yes/no
```

**Gate:** Alignment is incomplete until the human confirms the brief (or edits it to confirmation).  
If `Ready for next step` is no—or they want to continue digging—update the tree and return to Phase 2.  
If yes, **stop** this skill; hand off to branch / Gauge / TDD separately.

## Done when

- Human-confirmed **Alignment brief** with `Ready for next step: yes`
- Evidence: the brief block above (not a chat summary of Q&A alone)

## Anti-patterns

- Multiple questions in one message
- Interviewing without a competing **推奨**
- Echoing the human’s plan with mild polish
- Jumping to architecture, file lists, or code mid-clash
- Ending with Q&A notes instead of an alignment brief
- Using harness question UI tools instead of the markdown format

## Related skills

- `story-dev` — full loop; Phase 0 delegates here via `story-align`
- `gauge-tdd` — after brief is confirmed; not during clash
- `scored-review` — after green; do not reopen clash inside review
