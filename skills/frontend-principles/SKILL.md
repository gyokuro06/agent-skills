---
name: frontend-principles
description: >
  Use when creating or modifying frontend components or CSS. Enforces
  self-contained single-responsibility components, browser-first CSS with
  rem/em/clamp, global design tokens, and scoped component stylesheets.
  Do not use for backend-only work, API/schema changes without UI, or
  alignment/planning sessions without implementation.
metadata:
  origin: gyokuro06-agent-skills
  tags: frontend, css, architecture, components
---

# Frontend Design Principles

Constraints for UI and CSS work. Not a full delivery workflow — for branch/Gauge/commits use `story-dev`.

**Non-goals:** Do not impose a specific CSS framework. Follow the project's existing stack. Do not refactor unrelated code.

## Component Design

### Single Responsibility

Each component does exactly one thing — UI and the behavior that belongs to that unit. If a component manages unrelated layout, unrelated state, and unrelated side effects simultaneously, split it.

- Keep UI and its behavior inside the component boundary (or a colocated hook in the same file)
- A component that "knows too much" is a signal to extract a child component or hook

**Split signals** (prose, not a refactor mandate):

- Responsibility cannot be described in one sentence
- Two or more independent UI regions exist
- A child is reused elsewhere — extract it as its own component
- Shared logic across components → extract a hook or small util; duplicate until the third real use case (YAGNI)

### YAGNI — Don't Overengineer

Build only what is needed now. Extensibility comes from clear component boundaries, not premature abstraction.

- No generic slots, plugin systems, or configuration props unless there is an actual current consumer
- Three similar components are better than one over-parameterized component
- The right abstraction reveals itself after the third real use case, not before

## Existing Stack Priority

Follow the project's established styling and component patterns first:

- Tailwind, CSS Modules, styled-components, MUI/Chakra, Vue `<style scoped>`, Svelte styles, etc.
- If a global theme or token file already exists, extend it — do not introduce a parallel token system
- Introduce a new styling approach only when the user explicitly asks

This skill enforces **intent** (tokens, scoping, component boundaries), not a specific CSS toolchain.

## CSS Philosophy

### Let the Browser Do the Work

Prefer container queries, intrinsic layout, and fluid values over viewport breakpoints. Use `@media (min-width: …)` / `(max-width: …)` only when layout truly depends on the viewport.

**Allowed `@media` features** (use freely):

- `prefers-reduced-motion`
- `prefers-color-scheme`
- `print`
- `hover` / `pointer` (e.g. fine-pointer hover affordances)
- Viewport-dependent layout when unavoidable (e.g. navigation drawer toggle)

Signals to prefer first:

- `rem` / `em` for sizing
- Container queries (`@container`) for component-level responsiveness
- Intrinsic layout with `flex`, `grid`, `min-content`, `max-content`, `fit-content`
- `clamp()`, `min()`, `max()` for fluid values

### Unit Decisions

| What | Unit | Reason |
|---|---|---|
| Base font size | `1rem` | Inherits user preference from browser |
| Scaled font size | `Xrem` or `calc(1rem * X)` | Easy global rescaling |
| Spacing tied to local font | `em` | Scales with component font size |
| Spacing independent of font | `rem` | Consistent across contexts |
| Fluid ranges | `clamp(min, preferred, max)` | Avoids breakpoints |
| Minimum viable size | `min-width` / `min-height` | Prevents collapse without a breakpoint |

**Principle**: font sizes are simple multiples of `1rem` — e.g. `0.75rem`, `1rem`, `1.25rem`. Do not pick values by px conversion (`0.875rem` because "14px"). Respect the user's browser font-size setting; avoid overriding `html { font-size }` for layout scaling.

### CSS Custom Properties

Design tokens live globally (`:root`, or the project's theme entry). Components reference tokens via `var(--token-name)`, never raw design values.

**Naming** (align with existing project tokens when present):

- Typography: `--text-*`
- Spacing: `--space-*`
- Colors: `--color-*`

**Colors**: use `oklch()` for new token definitions. If the project already uses hex/hsl, match existing tokens; prefer `oklch` when adding new colors.

**Borders**: `1px` hairlines are fine; the no-raw-values rule applies to colors, type scale, and spacing decisions.

### Stylesheet Layering — Tokens vs Component Styles

Split styling into two layers. Do not mix responsibilities.

| Layer | Scope | File pattern | Contains |
|---|---|---|---|
| **Design tokens** | Global (app-wide) | Global stylesheet or theme entry (e.g. `globals.css`, `tokens.css`, `:root`) | Colors, typography scale, spacing scale, theme variables |
| **Component styles** | Local (per component) | Scoped stylesheet colocated with the component (e.g. `Button.module.css`) | Layout, structure, component-specific rules |

**Rules**

1. **Tokens stay global.** Never duplicate token values inside component stylesheets.
2. **Component styles stay scoped.** Use the project's scoped-CSS mechanism. Do not add global class names for component internals.
3. **Component styles consume tokens.** Reference `var(--token-name)` for colors, font sizes, and spacing.
4. **One scoped file per component** (or per small group that always ship together). Name it after the component: `ComponentName.module.css`.

**Class naming inside scoped files**

- Use short, local names (`header`, `title`, `icon`) — scoping adds uniqueness.
- BEM-style suffixes (`__`, `--`) are optional; avoid repeating the component name as a global prefix.
- Descendant selectors are fine for fixed internal structure (e.g. `.icon img`).

Side-effect global imports (`import "./Component.css"`) are for **tokens/themes only**, not for component layout.

## Accessibility

Minimum bar for every UI change:

- **Semantic HTML** — use `button`, `a`, `nav`, `main`, `label` appropriately; no clickable `div`/`span` without role + keyboard support
- **Keyboard** — interactive elements are reachable via Tab and operable via Enter/Space
- **Focus** — never remove focus indication (`outline: none` alone is forbidden); use `:focus-visible`
- **Contrast** — text colors meet WCAG AA; watch muted/token colors on surface backgrounds
- **Images** — meaningful `alt` text; decorative images use `alt=""`

Honor `prefers-reduced-motion` when adding motion (see allowed `@media` above).

## Done when

- Component responsibility is describable in one sentence; behavior is closed within the component (or colocated hook)
- Styles use the project's stack; tokens are global, component rules are scoped and consume `var(--*)`
- A11y minimum (semantic, keyboard, focus, contrast, alt) is met
- No drive-by refactors outside the requested UI/CSS scope

## Anti-patterns

- Splitting a component into usecase/gateway/driver layers on the frontend
- Introducing Tailwind/MUI/a new token file when the project already has a styling system
- Viewport breakpoint ladders where container queries or `clamp()` would suffice
- Global classes for component internals (`app-header__title` in a global file)
- Hardcoded colors or font sizes in scoped stylesheets instead of `var(--*)`
- Defining design tokens inside a component scoped file
- Clickable non-interactive elements without keyboard support
- `outline: none` without a visible `:focus-visible` alternative
- px-derived `rem` values (`0.8125rem`) or complex font-size math when a simple scale step works

## Checklist

When writing or reviewing frontend code, verify:

- [ ] Component has a single, describable responsibility; behavior is closed within it (or a colocated hook)
- [ ] No logic added "just in case" — shared code extracted to hook/util only after the third use case
- [ ] Project's existing styling stack and tokens are followed; no parallel system introduced
- [ ] Tokens global and scoped styles consume `var(--*)`; new colors use `oklch` where applicable
- [ ] Font sizes are simple `rem` multiples; spacing uses `em`/`rem` per local-vs-global rule; `clamp()` for fluid ranges
- [ ] Viewport `@media` avoided unless on the allowed list or truly viewport-dependent
- [ ] Semantic HTML, keyboard access, visible focus, contrast, and image `alt` are correct
