# agent-skills

Personal [Agent Skills](https://agentskills.io) library, plus Claude/Cursor-compatible **subagents** for the story-dev delivery loop. Skills and agents are portable packages; install only chooses where they are symlinked.

## Design

Inspired by [everything-claude-code (ECC)](https://github.com/affaan-m/everything-claude-code)-style harness design: keep surfaces separated so capability grows without dumping every playbook into every session.

| Surface | What it does | Context behavior |
| --- | --- | --- |
| **Skills** | Reusable workflows (`align-clash`, `gauge-tdd`, `story-dev`) | Loaded when the task needs them — **canonical playbooks** |
| **Agents** | Scoped workers (`story-align`, `story-gauge-red`, …) with tool limits | Fresh context per phase; return **evidence**, not chat noise |
| **Parent / orchestrator** | `story-dev` skill | Gates, branch, phase commits; does not inline phase playbooks |

```text
story-dev skill
  -> story-align     (+ align-clash)     -> Alignment brief
  -> parent          branch + commit
  -> story-gauge-red (+ gauge-tdd Red)   -> RED evidence  + commit
  -> story-green     (+ gauge-tdd Green) -> GREEN evidence + commit
  -> story-refactor  (+ gauge-tdd Refactor) -> still-green / skip
```

Agents stay thin: role, gates, evidence format, and a pointer to the skill. Detail lives in `skills/*/SKILL.md`. Claude Code may preload playbooks via agent frontmatter `skills:`; other harnesses should still load/follow the named skill.

## Structure

```
agent-skills/
├── agents/                 # Scoped subagents (story-dev phases)
│   ├── story-align.md
│   ├── story-gauge-red.md
│   ├── story-green.md
│   └── story-refactor.md
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
./install.sh           # Claude + Cursor + Codex (skills + agents)
./install.sh --claude  # ~/.claude/skills/  and  ~/.claude/agents/
./install.sh --cursor  # ~/.cursor/skills/  and  ~/.cursor/agents/
./install.sh --codex   # ~/.agents/skills/  and  ~/.codex/agents/
```

Editing files in this repo takes effect immediately — no reinstall needed.  
`add-skill` is installed like other skills so you can add skills from any project.

If you previously installed from the old Claude-only layout, run `./uninstall.sh` then `./install.sh`.

## Story-dev pairing

| Skill (playbook) | Agent (scoped worker) | Phase |
| --- | --- | --- |
| `align-clash` | `story-align` | Align |
| `gauge-tdd` (Red) | `story-gauge-red` | Red |
| `gauge-tdd` (Green) | `story-green` | Green |
| `gauge-tdd` (Refactor) | `story-refactor` | Refactor |
| `story-dev` | *(orchestrates the above)* | Full loop |

Standalone skills remain valid outside the full loop (alignment-only or a single TDD step).

Agent frontmatter uses shared fields (`name`, `description`, `model`) plus harness-specific extras where useful (`tools` / `skills` for Claude Code, `readonly` for Cursor).

## Uninstall

```bash
./uninstall.sh           # all targets (skills + agents)
./uninstall.sh --cursor  # one target
```

## Adding a Skill

Prefer asking the agent to use the **`add-skill`** skill (installed globally via `./install.sh`). It routes **universal** skills into this repo’s `skills/` and **project-specific** skills into the current repo’s `.cursor/skills/`, using the same frontmatter, `description`, and body rules.

Manual shortcut once you know the conventions:

```bash
./validate.sh --schema
# create skills/<name>/SKILL.md (portable frontmatter only; see skills/add-skill/SKILL.md)
./validate.sh skills/<name>
./install.sh
```

`./validate.sh` checks (1) `schemas/skill.schema.json` ↔ agentskills.io field set, (2) official [`skills-reference`](https://www.npmjs.com/package/skills-reference) rules, (3) the local JSON Schema.

## Adding an Agent

1. Create `agents/<name>.md` with YAML frontmatter (`name`, `description`, preferably `model: inherit`) and a **thin** system prompt: role, gates, evidence format, pointer to the canonical skill.
2. Prefer `tools:` allowlists (least privilege) and `skills:` preload of the playbook when targeting Claude Code.
3. Keep `name` kebab-case and unique; filename should match.
4. Run `./install.sh` so `~/.claude/agents/` and `~/.cursor/agents/` pick it up.
5. Wire orchestration (e.g. `story-dev`) to delegate by that `name`; do not duplicate the full skill body into the agent.

## References

- [Agent Skills specification](https://agentskills.io)
- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Claude Code subagents](https://code.claude.com/docs/en/sub-agents)
- [Cursor skills](https://cursor.com/docs/skills)
- [Cursor subagents](https://cursor.com/docs/subagents)
- [Codex skills](https://developers.openai.com/codex/skills)
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (design reference: skills vs agents, evidence-gated TDD)
