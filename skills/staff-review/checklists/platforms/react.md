# React and Next.js

Framework layer. Sits under `concerns/performance-frontend.md` and `concerns/security.md`, and on top of `platforms/javascript-typescript.md`.

## Components and rendering
- Components focused, composable, and separated by responsibility rather than by file size.
- **List keys stable and based on identity, never the array index** when the list can reorder, filter or paginate.
- Props minimal. A component taking twelve props is usually two components.
- **Derived data computed during render, not stored in state and synced with an effect.**
- Controlled and uncontrolled inputs used consistently. Switching between them mid-life is a defect.
- Error boundaries around failure-prone areas, so one broken widget does not blank the page.
- Server Component by default. `'use client'` only for interactivity, browser APIs or event handlers, pushed as far down the tree as possible.
- Hydration mismatches: `Date.now()`, `Math.random()`, `window` or `localStorage` read during render.

## Hooks and effects
- Hooks called unconditionally, at the top level, never inside a branch or a loop.
- **Dependency arrays complete and correct.** A suppressed `exhaustive-deps` needs a written reason.
- **Every effect synchronizes with an external system.** Not fetching a Server Component should do, not deriving state, not reacting to a prop change.
- Subscriptions, listeners, timers, intervals and observers cleaned up in the return function. Every one of them.
- Async requests aborted or guarded against stale responses on unmount and on input change.
- Stale closures: a callback, timer or subscription reading state from the render that created it.
- `useMemo` and `useCallback` used for a concrete measured reason, not applied everywhere by habit.
- Several related `useState` calls that always change together belong in a reducer.

## State management
- State local unless more than one component genuinely needs it.
- **Server state handled separately from client and UI state.** They have different lifetimes and different invalidation.
- The same state not duplicated in a component and a global store. That is two sources of truth.
- Cache invalidation and optimistic updates correct, including the rollback path.
- Selectors narrow enough that an unrelated store change does not rerender the tree.
- Persistence and hydration errors handled. Corrupt or outdated persisted state must not crash the app.
- Global state holds serializable values only. No class instances, no DOM nodes, no functions.

## Performance in React terms
- Expensive components rerendering because of an unstable object, array or function prop, or a context value recreated each render.
- Large lists virtualized.
- Routes and heavy dependencies lazy-loaded, with code splitting aligned to real user flows rather than to folder structure.
- Images through `next/image`, correctly sized.
- Work during render deterministic and cheap. No side effects, no random values, no fetch.
- Does the change materially increase the bundle? Check, do not assume.

## Accessibility and UX
- Semantic HTML first, ARIA only where semantics run out. Interactive elements are buttons and links, not `div`s with `onClick`.
- Every interaction completable by keyboard.
- Focus managed and restored for dialogs, drawers and route changes.
- Inputs have associated labels, errors linked with `aria-describedby`.
- **Icon-only buttons have accessible names.**
- Dynamic updates announced through a live region when the user needs to know.
- Loading, empty, error, offline, permission-denied and disabled states all covered.
- Usable with zoom to 200%, text resizing, and on small screens.

## Routing and client security
- Route params and query strings validated before use.
- **Protected routes are a UX layer only.** Backend authorization is the actual gate.
- Redirects restricted to safe destinations. An open redirect from a query param is a P0.
- User-provided HTML sanitized. `dangerouslySetInnerHTML` avoided.
- No sensitive values in URLs, `localStorage`, analytics payloads or console logs.
- Deep links, refreshes and browser back and forward all work.
- External links carry `rel="noopener noreferrer"`.

## Tests
- Tests interact with the UI the way a user does.
- Queries by role and label, not by test id or class name, unless there is no accessible handle.
- Async transitions awaited properly. No arbitrary timeout waiting for a render.
- Loading, failure, empty and success states all tested.
- Routing, permissions and forms covered.
- Mocks limited to external boundaries.
- Critical workflows covered by browser tests.

## Repo conventions
- Logger per the repo pattern: `createLogger('app/path/to/file.tsx')`.
- `pnpm lint` and `pnpm type-check` clean.
