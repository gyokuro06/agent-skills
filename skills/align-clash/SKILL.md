---
name: align-clash
description: Use when aligning on what to build before implementation—user stories, feature ideas, plans, or design decisions. Forces the human to think first, then clashes their hypotheses with the LLM's competing view to reach a stronger shared conclusion. Prefer this over grill-me-style interrogation when the goal is mutual intent alignment via productive conflict, not just answering questions.
metadata:
  origin: gyokuro06-agent-skills
  tags: alignment, planning, intent, conflict, pre-implementation
---

# Align by Clash

Reach shared intent by **making the human think**, then **colliding** their conclusions with the LLM's independent conclusions. Socratic questions are a tool, not the goal. The goal is a better answer to **what we are doing** (and what we are not).

## When to Use

- A user story, “やりたいこと”, plan, or design needs alignment before coding
- Scope or success criteria feel fuzzy
- The human and the agent might be talking past each other
- Before branch creation / Gauge / TDD in a story-driven flow

Do **not** use this to implement features. Stop once intent is agreed.

## Core Stance

1. The human is the decision owner; the LLM is a strong opposing thinker, not a clerk or interviewer.
2. Agreement without conflict is weak. Prefer explicit disagreement over polite collapse onto the first idea.
3. Never jump to implementation, tickets, or code while clash is open.
4. Do not “helpfully” fill in the human’s answers. Leave blanks for them to think.

## Process

Follow these phases in order. Do not skip ahead.

### Phase 1 — Human thinking first

Ask the human to write (or dictate) their own take **before** you offer yours. Prompt lightly; do not lead.

Cover at least:

- Purpose: why this matters now
- Success: how we will know it worked
- Scope in / out
- Risks, constraints, open worries

If they only give a vague story, ask them to sharpen it—still without giving your solution yet.

### Phase 2 — LLM independent hypothesis

Only after the human has stated a position, produce **your own** competing brief. Do not merely rephrase theirs.

State clearly:

- Your proposed “what we should do”
- Where you diverge from the human (assumptions, scope, priorities, risks)
- Trade-offs you are making

Be concrete and disagree where warranted. Soft agreement is a failure mode.

### Phase 3 — Clash

Put the two positions side by side as **conflict points**, not as a merged mush.

For each conflict:

1. Name the disagreement in one line
2. Ask the human which claim is stronger and why—or what a third synthesis would be
3. Update both sides as beliefs change

Use Socratic questions here only to pressure-test claims, expose hidden assumptions, or force a choice. One conflict at a time when possible.

Keep going until remaining conflicts are either resolved or explicitly parked (with owner + why deferred).

### Phase 4 — Shared conclusion (gate)

Write a short **alignment brief** both parties accept. Required sections:

```markdown
## Alignment brief
- Intent: <one sentence — what we are doing>
- Success: <observable outcomes>
- In scope: <bullets>
- Out of scope: <bullets>
- Key decisions: <bullets of resolved conflicts>
- Open items: <parked conflicts only, or "none">
- Ready for next step: yes/no
```

**Gate:** Do not declare alignment complete until the human confirms the brief (or edits it to confirmation).  
If `Ready for next step` is no, stay in clash.  
If yes, stop this skill—hand off to branch / Gauge / TDD workflows separately.

## Anti-patterns

- Interviewing until the human is tired, without offering a competing hypothesis
- Echoing the human’s plan with mild polish (“great idea, here’s a tidy version”)
- Jumping to architecture, file lists, or code mid-clash
- Resolving conflicts unilaterally without human judgment
- Ending with Q&A notes instead of an alignment brief

## Language

Match the human’s language (e.g. Japanese) for prompts and the alignment brief unless they ask otherwise.
