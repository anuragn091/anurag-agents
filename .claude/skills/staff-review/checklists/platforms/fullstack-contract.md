# Full-stack Lens

Load when the PR touches both sides, or changes a contract one side depends on. These are the failures that neither a frontend review nor a backend review catches alone.

## Contract agreement
- Do the request and response types on the frontend match the actual API schema, field by field?
- Are those types generated or derived from one source, or hand-written twice and already drifting?
- **Runtime validation of API responses on the frontend, not blind trust in the declared type.**
- snake_case to camelCase translation happens once, at the boundary, and covers nested objects and arrays.
- Both sides agree on nullability, defaults, enum values and error format. Backend `choices` and frontend unions come from the same list.
- Error codes are the contract. The frontend switches on the code, never on the message string.

## Data fidelity across the wire
- Dates in unambiguous ISO 8601 with timezone information. UTC on the wire, local in the UI.
- **Decimal and currency values transferred without precision loss.** A Python `Decimal` serialized to a JS number loses money. Send a string.
- Identifiers, pagination cursors and null handling consistent on both sides.

## Validation
- Rules consistent across the two sides, with the backend authoritative. Client validation is a convenience, never the gate.
- An input the backend rejects produces a usable message on the frontend, mapped by error code.

## Auth in the deployed environment
- Authentication, CSRF tokens, cookie flags and CORS actually work against the deployed API origin, not just on localhost.
- 401 and 403 handled end to end: refresh, redirect to login, or a permission-denied state. Never a blank screen.
- Token refresh and rotation behave correctly when two requests race the same expiry.

## Deployment ordering
- Backward compatible during a rolling deploy: old frontend against new backend, and new frontend against old backend, both work.
- API and schema changes ship before the client that needs them, additive first.
- **Can the two layers be deployed and rolled back independently?** If they must ship together, say so explicitly and coordinate it.
- Breaking contract changes are versioned or released in a safe sequence, never dropped in at once.

## End-to-end failure behavior
- Timeout, partial success and retry behavior coherent across both layers. A backend retry plus a frontend retry is four attempts.
- Loading and optimistic states reconcile correctly when the server disagrees.

## Coverage
- Contract or end-to-end tests for the critical paths this PR touches.
- If the contract changed and no test would have caught a mismatch, that is a finding.
