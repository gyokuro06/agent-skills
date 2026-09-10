# agent-skills

Personal harness library: [Agent Skills](https://agentskills.io), always-on **rules**, and Claude/Cursor-compatible **subagents**. Packages are portable; install only chooses where they are symlinked.

## Design

Inspired by [everything-claude-code (ECC)](https://github.com/affaan-m/everything-claude-code)-style harness design: keep surfaces separated so capability grows without dumping every playbook into every session.

| Surface | What it does | Context behavior |
| --- | --- | --- |
| **Rules** | Always-on or path-scoped constraints (e.g. `minimal-comments`) | Injected when applicable — **not** discovery-selected |
| **Skills** | Reusable workflows (`align-clash`, `gauge-tdd`, `scored-review`, `story-dev`) | Loaded when the task needs them — **canonical playbooks** |
| **Agents** | Scoped workers (`story-align`, `story-gauge-red`, …) with tool limits | Fresh context per phase; return **evidence**, not chat noise |
| **Parent / orchestrator** | `story-dev` skill | Gates, branch, commits, implement↔review until pass (no human pause after bare GREEN); human return includes 実装→レビュー trail; does not inline phase playbooks |

```text
story-dev skill
  -> story-align     (+ align-clash)      -> Alignment brief
  -> parent          branch + commit
  -> story-gauge-red (+ gauge-tdd Red)    -> RED evidence  + commit
  -> [no human return until Review pass or escalate]
       story-green   (+ gauge-tdd Green)  -> GREEN evidence + commit
       story-review  (+ scored-review)    -> REVIEW evidence
             |-- pass -> done (human return + loop trail)
             |-- redelegate -> story-green -> commit -> review
             |-- escalate -> human + loop trail
```

Agents stay thin: role, gates, evidence format, and a pointer to the skill. Detail lives in `skills/*/SKILL.md`. Claude Code may preload playbooks via agent frontmatter `skills:`; other harnesses should still load/follow the named skill.

## Structure

```
agent-skills/
├── agents/                 # Scoped subagents (story-dev phases)
│   ├── story-align.md
│   ├── story-gauge-red.md
│   ├── story-green.md
│   └── story-review.md
├── rules/                  # Always-on / path-scoped constraints (.mdc)
│   └── <name>.mdc
├── schemas/
│   └── skill.schema.json
├── scripts/
│   └── validate.mjs
├── skills/
│   └── <skill-name>/
│       └── SKILL.md
├── install.sh
├── uninstall.sh
└── validate.sh
```

## Install (local symlinks)

```bash
./install.sh           # Claude + Cursor + Codex (skills + agents; rules for Claude/Cursor)
./install.sh --claude  # ~/.claude/skills/, agents/, rules/
./install.sh --cursor  # ~/.cursor/skills/, agents/, rules/
./install.sh --codex   # ~/.agents/skills/  and  ~/.codex/agents/
```

Editing files in this repo takes effect immediately — no reinstall needed.  
`add-skill` is installed like other skills so you can add skills, rules, or agents from any project.

If you previously installed from the old Claude-only layout, run `./uninstall.sh` then `./install.sh`.

## Story-dev pairing

| Skill (playbook) | Agent (scoped worker) | Phase |
| --- | --- | --- |
| `align-clash` | `story-align` | Align |
| `gauge-tdd` (Red) | `story-gauge-red` | Red |
| `gauge-tdd` (Green) | `story-green` | Implement |
| `scored-review` | `story-review` | Review |
| `story-dev` | *(orchestrates the above)* | Full loop |

Standalone skills remain valid outside the full loop (alignment-only, a single TDD step, or scored review after green).

Agent frontmatter uses shared fields (`name`, `description`, `model`) plus harness-specific extras where useful (`tools` / `skills` for Claude Code, `readonly` for Cursor).

## Uninstall

```bash
./uninstall.sh           # all targets (skills + agents + rules)
./uninstall.sh --cursor  # one target
```

## Adding a Skill, Rule, or Agent

Prefer asking the agent to use **`add-skill`** (installed globally via `./install.sh`). It is a **surface router**: it picks rule vs skill vs thin agent vs script, then routes **universal** packages into this repo and **project-specific** ones into the current repo’s `.cursor/` / `.claude/` trees.

### Skill (manual shortcut)

```bash
./validate.sh --schema
# create skills/<name>/SKILL.md (portable frontmatter only; see skills/add-skill/SKILL.md)
./validate.sh skills/<name>
./install.sh
```

`./validate.sh` checks (1) `schemas/skill.schema.json` ↔ agentskills.io field set, (2) official [`skills-reference`](https://www.npmjs.com/package/skills-reference) rules, (3) the local JSON Schema.

### Rule (manual shortcut)

1. Create `rules/<name>.mdc` with Cursor-oriented frontmatter (`description`, `alwaysApply`, optional `globs` / `paths` for path-scoped).
2. Keep the body short and actionable (prefer ≤ ~50 lines).
3. Run `./install.sh` — links to `~/.cursor/rules/<name>.mdc` and `~/.claude/rules/<name>.md`.

### Agent (manual shortcut)

1. Create `agents/<name>.md` with YAML frontmatter (`name`, `description`, preferably `model: inherit`) and a **thin** system prompt: role, gates, evidence format, pointer to the canonical skill.
2. Prefer `tools:` allowlists (least privilege) and `skills:` preload of the playbook when targeting Claude Code.
3. Keep `name` kebab-case and unique; filename should match.
4. Run `./install.sh` so `~/.claude/agents/` and `~/.cursor/agents/` pick it up.
5. Wire orchestration (e.g. `story-dev`) to delegate by that `name`; do not duplicate the full skill body into the agent.

## References

- [Agent Skills specification](https://agentskills.io)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Claude Code memory / rules](https://code.claude.com/docs/en/memory)
- [Claude Code subagents](https://code.claude.com/docs/en/sub-agents)
- [Cursor skills](https://cursor.com/docs/skills)
- [Cursor rules](https://cursor.com/docs/context/rules)
- [Cursor subagents](https://cursor.com/docs/subagents)
- [Codex skills](https://developers.openai.com/codex/skills)
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (design reference: skills vs agents, evidence-gated TDD)
