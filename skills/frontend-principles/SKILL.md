---
name: frontend-principles
description: Use this skill when creating or modifying frontend components or CSS. Enforces single-responsibility components, clean architecture (usecase/gateway/driver), and browser-first CSS with rem/em/clamp and CSS custom properties.
metadata:
  origin: gyokuro06-agent-skills
  tags: frontend, css, architecture, react
---

# Frontend Design Principles

## Component Design

### Single Responsibility

Each component does exactly one thing. If a component manages layout, handles data fetching, and owns business logic simultaneously, split it.

- UI rendering ↔ logic separation is mandatory
- A component that "knows too much" is a signal to extract

### YAGNI — Don't Overengineer

Build only what is needed now. However, extensibility and maintainability are non-negotiable constraints — they are achieved through clean structure, not through premature abstraction.

- No generic slots, plugin systems, or configuration props unless there is an actual current consumer
- Three similar components are better than one over-parameterized component
- The right abstraction reveals itself after the third real use case, not before

## Architecture — Logic Outside Components

When logic is non-trivial enough to live outside a component, follow Clean Architecture:

```
Component
  └─ calls → Use Case
                └─ calls → Gateway interface
                              ← implemented by Driver (API client, localStorage, etc.)
```

- **Use Case**: orchestrates domain logic, framework-agnostic
- **Gateway**: interface (TypeScript type/interface) that the use case depends on
- **Driver**: concrete implementation of the gateway (fetch wrapper, SDK client, etc.)

Dependency rule: inner layers (use case) never import outer layers (driver). The driver satisfies the gateway contract.

## CSS Philosophy

### Let the Browser Do the Work

Avoid viewport breakpoints (`@media (min-width: ...)`) unless there is no alternative. The browser can handle responsiveness when given the right signals:

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

**Principle**: font sizes are expressed as multiples of `1rem`. Changing `html { font-size }` or the user's browser default rescales everything uniformly.

### CSS Custom Properties

All design tokens are defined as global CSS variables on `:root`. Components reference tokens, never raw values.

```css
:root {
  /* Typography scale (multiples of 1rem) */
  --text-xs:   0.75rem;
  --text-sm:   0.875rem;
  --text-base: 1rem;
  --text-lg:   1.25rem;
  --text-xl:   1.5rem;
  --text-2xl:  2rem;

  /* Spacing */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;

  /* Color palette */
  --color-bg:        #ffffff;
  --color-surface:   #f5f5f5;
  --color-text:      #1a1a1a;
  --color-text-muted:#6b7280;
  --color-primary:   #2563eb;
  --color-border:    #e5e7eb;
}
```

Components never hardcode colors or font sizes. All values come from `var(--token-name)`.

## Checklist

When writing or reviewing frontend code, verify:

- [ ] Component has a single, describable responsibility
- [ ] No logic added "just in case" — every abstraction has a current consumer
- [ ] Business logic extracted to use cases, gateway interfaces defined, drivers injected
- [ ] No `@media (min-width/max-width)` unless truly unavoidable — container queries or intrinsic layout used instead
- [ ] Font sizes expressed in `rem` as multiples of 1
- [ ] Spacing unit chosen based on whether it should track local font size (`em`) or stay fixed (`rem`)
- [ ] `clamp()` used for fluid values rather than duplicating rules at breakpoints
- [ ] All colors and font sizes reference CSS custom properties from `:root`
