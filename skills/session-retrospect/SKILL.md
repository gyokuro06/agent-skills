---
name: session-retrospect
description: >
  Use when the user explicitly asks to retrospect a Cursor session, harvest
  harness improvements, or audit chat friction for new or better skills/rules
  (振り返り, retrospect, session harvest, コンテキスト化). Mines the session—
  including user corrections and pushback—then proposes skill/rule/context
  changes and routes approved items through add-skill. Manual invocation only.
  Do not use after every task, for scored code review, alignment-only clash,
  or drive-by edits to an existing skill unless the user asked for a retrospect.
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, retrospect, harness, skills, rules, cursor, feedback
---

# Session Retrospect (harness harvest)

After a Cursor development session, **audit** what should become durable harness
context—and what should not. Output proposals; create or edit only after the
user approves (or they already said to apply). Hand creation/routing to
`add-skill`.

**Non-goals:** automatic end-of-task runs; product/code review (`scored-review`);
intent alignment (`align-clash`); inventing packages from one-off taste.

## Process

### 1. Scope the retrospect

Confirm with the user if ambiguous:

| Scope | Default source |
| --- | --- |
| **This chat** | Current conversation (preferred) |
| **Named prior chats** | Search/read local conversation index or agent transcripts when available |
| **Topic window** | User-named theme across recent sessions |

If scope is “this chat,” do not require external search. Prefer concrete
excerpts over vague memory.

### 2. Mine signals (evidence first)

Collect short, citeable moments. **User pushback and corrections are first-class**—
not optional color.

| Signal | Examples |
| --- | --- |
| **Correction / ツッコミ** | “違う”, “それはやらない”, naming/process rejections, scope cuts |
| **Repeated friction** | Same rediscovery, same wrong assumption, same missing command |
| **Missing playbook** | Multi-step workflow the agent improvised poorly |
| **Always-on need** | Constraint that should apply without being asked |
| **Wrong surface** | Skill loaded when a rule fit; skill too broad; overlap confusion |
| **Stale / weak package** | Existing skill/rule caused miss or fight; gaps in Done when / Anti-patterns |
| **One-off** | Single preference unlikely to recur → usually **no package** |

Record each finding as: *quote or paraphrase* → *what went wrong* → *durable?*

### 3. Classify candidates (gate)

For each durable finding, pick **one** outcome:

| Outcome | When |
| --- | --- |
| **New skill** | On-demand playbook; focused domain/workflow |
| **New rule** | Always-on or path-scoped constraint; short, injectable |
| **Improve existing** | Near-duplicate or same topic already exists—extend, narrow, or add Anti-patterns / Do not use when |
| **Project context** | Repo-only paths, APIs, conventions → project skill/rule (not universal) |
| **Thin agent** | Multi-phase isolation needed; pair with a canonical skill via `add-skill` Agent path |
| **No change** | One-off, already covered, or not worth context cost |

**Gate:** Prefer **improve existing** over a second near-duplicate. Prefer **rule**
for always-on constraints. Prefer **no change** over low-signal packages.

Scan before proposing:

```bash
ls "$AGENT_SKILLS_DIR/skills/"
ls "$AGENT_SKILLS_DIR/rules/" 2>/dev/null
ls "$AGENT_SKILLS_DIR/agents/" 2>/dev/null
ls "$PROJECT_ROOT/.cursor/skills/" "$PROJECT_ROOT/.claude/skills/" 2>/dev/null
ls "$PROJECT_ROOT/.cursor/rules/" "$PROJECT_ROOT/.claude/rules/" 2>/dev/null
```

Resolve `AGENT_SKILLS_DIR` / `PROJECT_ROOT` the same way as `add-skill`.

### 4. Present proposals (do not silently create)

Use this template. Sort by impact; drop weak candidates.

```markdown
## RETROSPECT evidence
- Scope: <this chat | named chats | topic>
- Findings mined: <n> (corrections/pushback: <n>)
- Proposals:

### P1 — <title>
- Outcome: new-skill | new-rule | improve | project-context | thin-agent | no-change
- Target: <path or existing name, or n/a>
- Why (durable): <1–2 sentences>
- Evidence: <user quote / moment>
- Overlap: <none | conflicts with X → improve X>
- Suggested next: add-skill | edit <name> | skip

- (or: No harness changes recommended — <why>)
```

Ask which proposals to apply unless the user already authorized apply-all.

### 5. Apply via `add-skill`

For each **approved** proposal:

1. Load and follow **`add-skill`** (surface → scope → author → validate → install).
2. Improving an existing package: edit in place; still run overlap/focus checks;
   re-validate skills with `validate.sh`; run `./install.sh` only if universal
   install state must refresh (new files/symlinks).
3. Do not invent a parallel “create skill” path—**`add-skill` owns authoring**.

## Done when

- Evidence block lists scope, correction/pushback count, and every serious candidate
- Each proposal has Outcome + Overlap + Suggested next (or explicit **no change**)
- No new/edited harness files without user approval (or prior apply instruction)
- Approved items completed through `add-skill` (or concrete edit + validate)
- Evidence: the `## RETROSPECT evidence` block above, plus links/paths for anything created

## Anti-patterns

- Auto-running at session end without an explicit user ask
- Creating a skill that restates a one-line user preference
- Ignoring ツッコミ/corrections while harvesting “nice to have” tips
- Shipping a new skill when an existing one should gain `Do not use when` / Anti-patterns
- Writing production app code under the guise of retrospect
- Skipping overlap scan against `skills/` and `rules/`
- Authoring packages without going through `add-skill` gates

## Related skills

- `add-skill` — **required** next step for approved create/route work
- `scored-review` — qualitative code review after green; not harness harvest
- `align-clash` — intent alignment before build; not post-session harvest
- `story-dev` — delivery loop; retrospect is optional and outside that loop
