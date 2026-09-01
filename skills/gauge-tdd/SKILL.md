---
name: gauge-tdd
description: >
  Use when implementing with Gauge acceptance tests under Red-Green-Refactor—
  writing Gauge specs/scenarios first, making them fail, then minimal code, then refactor.
  Do not use for pure unit-test TDD without Gauge, for alignment-only work, or for
  drive-by implementation without a failing Gauge scenario. Within story-dev, prefer the
  story-gauge-red, story-green, and story-refactor subagents for each phase instead of
  running this whole loop in one agent.
metadata:
  origin: gyokuro06-agent-skills
  tags: gauge, tdd, testing, red-green-refactor
---

# Gauge TDD

Drive change with **Gauge** specs: Red → Green → Refactor. Do not implement production behavior before a failing Gauge scenario exists for that slice.

This skill is the **canonical playbook** for `story-gauge-red` / `story-green` / `story-refactor` (each agent runs only its section). For the full story loop with phase commits, use `story-dev`.

## Process

Discover the repo’s Gauge layout first (`specs/`, `*.spec`, step implementations, how tests are run). Follow local conventions; do not invent a parallel test stack.

### 1. Red

1. Add or extend Gauge specs/scenarios for **one vertical slice** from the agreed intent.
2. Map scenarios to missing or failing steps as needed.
3. Run Gauge (or the project’s documented test command) and **confirm failure** for the new expectations.
4. **Gate:** No production implementation until failure is observed and understood.

### 2. Green

1. Write the **smallest** production change that makes the failing scenarios pass.
2. Do not expand scope, tidy unrelated code, or add extras “while here.”
3. Re-run until green.
4. **Gate:** All targeted scenarios pass before refactor.

### 3. Refactor

1. Improve structure only while keeping Gauge green.
2. No behavior or scope changes.
3. Re-run after meaningful edits.
4. **Gate:** Still green; diff is structural/clarity only.

## Done when

- Red was proven with a real failing run
- Green passes for the slice
- Refactor (if any) left tests green
- Each completed phase is ready for a phase commit when invoked from a committing workflow (e.g. `story-dev`)

## Anti-patterns

- Coding first, then writing Gauge to match
- Treating compile/type errors as “Red” without a Gauge run
- Multiple unrelated slices in one Red/Green cycle
- Refactoring or feature creep during Green
- Changing acceptance behavior during Refactor
- Skipping the failure confirmation gate
