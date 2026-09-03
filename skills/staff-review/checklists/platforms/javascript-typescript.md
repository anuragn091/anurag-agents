# JavaScript and TypeScript

Language-level checks. Sits under `concerns/security.md` and `concerns/performance-frontend.md`, which own the questions this file only shows how to answer.

## Type safety
- Strict mode on. No `any`, no `as` cast, no `!` non-null assertion without a comment saying why it is unavoidable.
- **Types make invalid states unrepresentable.** A discriminated union beats four optional booleans that can contradict each other.
- `null`, `undefined`, empty string, empty array and optional fields handled at the point they can occur.
- Props and function signatures minimal and accurately typed. A prop typed `object` or `Record<string, unknown>` is untyped.
- **External data validated at runtime, not just declared.** An API response typed as `User` is a lie until something checks it.
- Types generated or derived from the API contract, never hand-copied into a second file.
- No blanket `@ts-ignore` or `@ts-expect-error` without a reason on the line above.

## Async correctness
- Rejected promises handled. No floating promise, no `async` function whose rejection nobody catches.
- **Out-of-order responses:** the second request resolving before the first must not overwrite the newer result.
- Requests aborted when the caller no longer cares, through `AbortController` or an equivalent guard.
- `Promise.all` where calls are independent, sequential `await` only where there is a real dependency.
- `Promise.allSettled` where one failure should not discard the other results.

## Data handling
- Object and array mutation is intentional. Accidental mutation of props, state or a shared constant is a defect.
- Dates: ISO 8601 with timezone across the wire, rendered in local time. No string slicing of dates.
- Numbers and currency: no float arithmetic on money, no `toFixed` used as rounding policy.
- Falsy traps: `0` and `''` are falsy, and that has caused real bugs here. Use `??` and explicit checks, not `||`.
- Equality and coercion explicit.

## Testing
- Timers, randomness and network faked so runs are deterministic.
- Mocks limited to external boundaries, not to the module under test.
