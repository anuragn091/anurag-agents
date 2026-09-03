# Foundation Checklist

Applies to every PR, frontend or backend. The lens files change the emphasis, not this standard.

## 1. Intent and scope
- Does the PR solve the stated problem, or something adjacent to it?
- Is the scope focused, or does it carry unrelated changes along?
- Are assumptions, trade-offs and expected behavior written down?
- Is there a linked issue, ADR or spec, and does the change agree with it?

## 2. Correctness
- Normal, boundary and failure cases: empty, null, zero, negative, single element, duplicate, max size, unicode, timezone edges.
- Off-by-one, inclusive vs exclusive ranges, pagination boundaries.
- Concurrency, ordering, retries, and partial failure: if step 3 of 5 fails, what state is left behind and is it recoverable?
- Error paths: what happens when the thing it calls fails? No swallowed exceptions, no bare `except`, no `catch {}` without a rethrow.
- Could existing behavior regress? Which callers depend on the old behavior?

## 3. Architecture
- Does the change fit the existing system design, or quietly add a second way of doing the same thing?
- Are responsibilities in the right module and layer?
- Unnecessary coupling: does module A now know something it should not about module B?
- Unnecessary abstraction: generalizing for one caller is as bad as copy-paste for the fifth.
- Blast radius: which teams, services or screens break if this is wrong?
- Reversibility: a one-way door (schema drop, public API shape, data migration) gets far more scrutiny.
- Was there a simpler option? The best review comment is often "you can delete half of this".

## 4. API and data contracts
- Are the interfaces clear, consistent and hard to misuse?
- Backward compatible, or versioned, or additive only?
- Validation, serialization, status codes and error semantics correct.
- Field naming consistent with the rest of the API (snake_case in JSON here).
- Pagination, filtering and sorting on anything returning a list.
- Idempotency on POST/PUT where retries are expected.
- Migrations safe and reversible: see the backend checklist for the full sequence.

## 5. Security and privacy
Full list in `concerns/security.md`. On every PR, at minimum:
- AuthN and AuthZ enforced at the trusted boundary, with object-level and tenant-level checks. Not just "is logged in".
- All untrusted input validated server side.
- No secrets, PII or internal detail leaking through responses, logs, URLs or analytics.
- New dependency justified, maintained and pinned.
- Failure defaults to a secure state.

## 6. Reliability
- What happens when a dependency times out or fails?
- Retries bounded and idempotent, with backoff. Not infinite, not thundering.
- Resource cleanup, transaction boundaries, rollback and recovery.
- Race conditions, deadlocks, inconsistent state between two stores.

## 7. Performance and scalability
Full lists in `concerns/performance-frontend.md` and `concerns/performance-backend.md`. On every PR, at minimum:
- Operations inside a loop, and N+1 query patterns.
- Anything unbounded: queries without a limit, retries without a cap, lists without pagination.
- Timeouts on every external call.
- What breaks first at 10x traffic or data volume?
- Complexity moved onto a path that used to be cheap.

## 8. Maintainability
- Can the next person understand and change this?
- Names and control flow clear. Nesting kept shallow.
- Comments explain why, not what, and describe the present, never the history.
- Complexity justified and localized, not spread thin across ten files.
- Dead code, commented-out code, leftover debug logging, TODOs with no owner or ticket.

## 9. Testing
- Do tests validate behavior, or assert that mocks were called?
- Would a broken implementation actually turn these tests red? Break it mentally and check.
- Failure modes and edge cases covered, not just the happy path.
- Deterministic: no real sleeps, no real network, no dependence on ordering or wall-clock time.
- Scoped correctly: unit where logic lives, integration where the seams are, end-to-end only for critical paths.

## 10. Observability and operations
- Can this be diagnosed at 3am from logs alone, without reproducing it locally?
- Structured logs with request id and user id, at the right level, free of PII.
- Errors logged with stack traces (`exc_info=True`), not `logger.error(str(e))`.
- Metrics or alerts for the new failure mode this introduces.
- Dashboards or runbooks affected by this change.

## 11. Deployment and rollout
- Safe with old and new versions running together during a rolling deploy.
- Feature flag, staged rollout or kill switch where the risk warrants it.
- Rollback plan that does not require a code deploy.
- Config and infrastructure changes coordinated with the code change.

## 12. Product and user experience
- Does the resulting behavior make sense to a user?
- Error, loading, empty, permission-denied and offline states covered.
- Behavior consistent with related flows elsewhere in the product.
- Accessibility not treated as optional.

## 13. Team and organizational impact
- Does this cross an ownership boundary, or affect another team or service?
- Were the right people consulted?
- Does it set a precedent, or create a long-term operational burden someone will inherit?
- Should the decision be recorded in an ADR rather than living in a PR thread?

## 14. PR quality
- Is the description enough to review efficiently?
- Screenshots, test evidence, migration steps and rollout notes where relevant.
- Generated files, dependency additions and lockfile changes intentional.
- CI green, and if not, is the failure understood?

## The closing question
If this change fails in production six months from now, will the system, tests, telemetry and documentation make the cause and the recovery path obvious?
