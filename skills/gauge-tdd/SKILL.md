---
name: gauge-tdd
description: >
  Use when implementing with Gauge acceptance tests under Red-Green-Refactor—
  writing Gauge specs/scenarios first, making them fail, then minimal code, then refactor.
  Covers spec layout, Step/Page Object layering, contextual steps, and Playwright E2E patterns.
  Do not use for pure unit-test TDD without Gauge, for alignment-only work, or for
  drive-by implementation without a failing Gauge scenario. Within story-dev, prefer the
  story-gauge-red and story-green subagents for Red/Green instead of running this whole
  loop in one agent; after each green the parent must run story-review / scored-review
  before returning to the human (not only at PR time).
metadata:
  origin: gyokuro06-agent-skills
  tags: workflow, gauge, tdd, testing, red-green-refactor, playwright, page-object
---

# Gauge TDD

Drive change with **Gauge** specs: Red → Green → Refactor. Do not implement production behavior before a failing Gauge scenario exists for that slice.

This skill is the **canonical playbook** for `story-gauge-red` / `story-green` (each agent runs only its Red or Green section). Standalone Red→Green→Refactor remains valid outside story-dev. For the full story loop (including scored review), use `story-dev`.

Product-specific paths, commands, and config belong in the repo’s local E2E skill or README—not here.

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
3. If this slice introduces or meaningfully changes a **pure domain helper** (parse/format/limit/validate with no UI), add or extend **unit tests** in the same Green for boundaries Gauge covers poorly (empty, max digits, reject/normalize edges). Keep them lean; do not invent a second acceptance suite.
4. Re-run Gauge (and those unit tests if added) until green.
5. **Gate:** All targeted Gauge scenarios pass; new/changed domain unit tests pass before refactor.

### 3. Refactor

1. Improve structure only while keeping Gauge green.
2. No behavior or scope changes.
3. Re-run after meaningful edits.
4. **Gate:** Still green; diff is structural/clarity only.

## Layering (Spec → Step → Page Object)

| Layer | Role | Keep it… |
|-------|------|----------|
| **Spec** (`*.spec`) | User-visible behavior in the project’s BDD language | Declarative; no implementation detail |
| **Step** (`*Step.*`) | Glue between Gauge and the browser driver | **Thin**—delegate to Page Objects |
| **Page Object** (`pages/`) | Locators, assertions, UI actions | Where Playwright/Selenium detail lives |

**Do not put locators in Step classes.** If a Step grows beyond a one-liner delegation, extract a Page Object or component.

Typical layout:

```text
e2e/
  specs/           # Gauge scenarios
  src/.../
    *Step.*        # @Step implementations
    pages/
      BasePage.*   # shared navigation helpers
      *Page.*      # one per screen/route
      components/  # shared UI (header, nav, modal)
```

## Spec authoring

### Organize by UI area, not by ticket

Group scenarios by **surface** (header, home, import flow)—not by “everything on page X.” Cross-cutting UI (header, nav) gets its own spec file instead of being buried in a page-specific spec.

### Contextual steps (shared setup)

Steps written **before** the first `##` scenario heading run automatically before **every** scenario in that spec file.

```gauge
# Header

* open "/"

## import link is visible
* header shows import link
```

Do not repeat the same setup step in each scenario when contextual steps fit.

### Scenario granularity

One scenario = one acceptance theme. Split “visible” from “click → navigate → land on screen” when they represent distinct risks.

### Prefer positive outcomes over absence-only scenarios

Acceptance should assert **what the user can still do or see**, not only that an element is gone.

| Prefer | Avoid as a standalone scenario |
| --- | --- |
| Happy path / new UX still registers or displays correctly without the removed field | Spec whose only steps assert “X がない / X is absent / count is 0” |
| Fold “field removed” into the positive scenario’s preconditions or steps when needed | A dedicated scenario that only proves UI absence |

UI removal is usually covered when the positive flow no longer requires that control. Add an absence assertion only when absence itself is the distinct product risk (rare).

## Step implementation

- Step text in code must **match** the spec line exactly.
- Use Gauge parameters (`<path>`, `<name>`) for reusable steps; prefer existing parameterized steps over new fixed ones.
- Navigation often maps to a single parameterized step (e.g. `<path>を開く` / `open "<path>"`).

### Gauge step syntax pitfalls

Paths, quotes, and slashes in step **names** are parsed specially. These often fail validation or won’t bind to implementations:

| Risky in step name | Prefer |
|--------------------|--------|
| `URLが"/import"である` | Fixed step: `import page URL is correct` |
| `URLが /import である` (spaces) | Fixed step or navigate via `<path>を開く` |
| `/` inside a custom parameter | Fixed step name, or reuse `<path>を開く` with `"/import"を開く` |

**Rule:** URL/path assertions → fixed, descriptive step names. Navigation → parameterized open step.

## Page Object Model

### Naming

- Assertions: `assertVisible()`, `assertUrl()`, `assertHeadingVisible()`
- Actions: `clickImportLink()`, `fillForm(...)`
- Keep locators **private**; expose intent methods only.

### Components

Shared chrome (header, sidebar) → `pages/components/`, composed by screen Page Objects.

### Playwright (Java/Kotlin)

- Prefer **accessibility locators**: `getByRole` + name, scoped under `BANNER`, `MAIN`, `NAVIGATION`.
- When **chaining** `getByRole` on a `Locator`, use `Locator.GetByRoleOptions`—not `Page.GetByRoleOptions`.
- URL checks: `hasURL(Pattern.compile("..."))` or equivalent.
- Fallback order: role → text → CSS (metadata like `link[rel="icon"]` only when roles don’t apply).

## Done when

- Red was proven with a real failing run (not compile-only)
- Green passes for the slice (Gauge + any new/changed domain unit tests)
- Refactor (if any) left tests green
- Steps stay thin; locators live in Page Objects
- No absence-only scenario was added when a positive outcome already covers the change
- Each completed phase is ready for a phase commit when invoked from a committing workflow (e.g. `story-dev`)

**Evidence** (return when delegating to `story-*` agents or reporting phase completion):

```markdown
## RED evidence
- Slice: <name>
- Specs/scenarios: <paths>
- Command: <exact command>
- Failure excerpt: <assertion failure — not compile-only>
- Production code changed: no

## GREEN evidence
- Slice: <name>
- Command: <exact command>
- Pass excerpt: <relevant output>
- Domain unit tests: <paths + command, or n/a>
```

## Anti-patterns

- Coding first, then writing Gauge to match
- Treating compile/type errors as “Red” without a Gauge run
- Multiple unrelated slices in one Red/Green cycle
- Refactoring or feature creep during Green
- Changing acceptance behavior during Refactor
- Skipping the failure confirmation gate
- Locators duplicated across Step classes
- Repeating contextual setup in every scenario
- Standalone scenarios whose only value is “element X is absent”
- Shipping new pure domain parse/format/limit helpers with Gauge alone and no unit coverage for cheap boundaries

## Related skills

- `story-dev` — full align → branch → Red → implement → scored review loop with phase commits
- `scored-review` — qualitative adversarial + structure review after green (`story-review`)
- `align-clash` — intent alignment before writing Gauge (via `story-align` in story-dev)
- `frontend-principles` — component/CSS implementation constraints; not E2E or Gauge layout
- Repo local E2E skill or README — project paths, test commands, and environment config

## Additional resources

- Step/Page Object examples and Red vs not-Red table: [reference.md](reference.md)
