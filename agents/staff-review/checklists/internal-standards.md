# Internal Standards Checklist

The rules this codebase already agreed to. A violation here is a finding even when the code works.

## 1. Do not write what already exists
- **Search before adding.** Grep the function name, the util, the constant, the type. Most duplication here happens because nobody looked.
- One canonical place per concept: one date formatter, one API client, one logger factory, one error hierarchy, one validation schema per model.
- A util that does 80% of the job gets extended, not forked into `formatDateV2`.
- Rule of three: two copies is tolerable, three is a refactor.
- Before adding a dependency, check what is already installed. No second date library, no second HTTP client.
- One `Application` type, derived with `Pick` / `Omit` or generated from the API, not hand-copied into five files.
- Backend `choices` and frontend union types come from one source. Two lists always drift.
- **Red flag in a diff:** a new file whose name is a near-synonym of an existing one, for example `utils/api.ts` beside `lib/apiClient.ts`.

## 2. Separation of concerns

**Backend (Django)**
- Views are thin: parse, authorize, call the service, serialize, return. No business logic, no ORM chains.
- Business logic lives in service classes. A service never sees `request`, `Response`, or an HTTP status code.
- Serializers validate and shape. They do not save side effects or send email.
- Models hold data, invariants and simple derived properties. Not workflow.
- Non-trivial data access goes in a manager, queryset method or repository function, not scattered across services.
- Anything talking to the outside world (S3, LinkedIn, OpenAI, email) sits behind its own client module with its own error type.

**Frontend (Next.js)**
- Server Components fetch, Client Components interact. Do not add `'use client'` just to fetch.
- Components render. Fetching in a hook or server function, business rules in a plain TS module testable without React.
- No inline `fetch` in a component. It goes through the API layer.
- No date, currency or formatting logic inside JSX.
- State at the lowest level that works. Context for genuinely cross-cutting state, not to dodge two props.

**The test:** open a file and say in one sentence what it is responsible for. If the sentence needs an "and", split the file.

## 3. Clean architecture: change the API without touching business logic
- **Dependencies point inward.** Business logic depends on nothing. Views, serializers, HTTP, ORM and vendor SDKs depend on it, never the reverse.
- **The API shape is not the business shape.** The request body is translated into domain input at the boundary. If a service signature changes because a JSON field was renamed, the layering is wrong.
- **The DB schema is not the business shape either.** Renaming a column touches the model and a mapping, not thirty call sites.
- Never let a Django `Request`, a DRF `Response`, or a raw serializer leak past the view. Never let a queryset leak into a component's expectations.
- Vendor types stay at the edge. An OpenAI or LinkedIn payload is mapped to our own type in the client module, so their breaking change hits one file.
- Business rules do not import framework modules. A `services/` file importing `rest_framework` is a blocking comment.
- Every external integration has an interface (Protocol on the backend, a typed interface on the frontend) so it can be swapped and faked.

**The check to run on every PR:** if we versioned this endpoint to v2 tomorrow with a different request and response shape, how many files change? Correct answer: the serializer, the view, and the frontend API layer. If it reaches the service, the model and half the app, the layering failed.

## 4. Error handling contract
- One error taxonomy used everywhere. Not `ValueError` here, a `{"error": ...}` dict there, and a DRF `Http404` somewhere else.
- Errors carry a stable machine-readable code plus a human message. The frontend switches on the code, never on the message string.
- Domain errors are raised in services and translated to HTTP status codes in the view layer.
- Never swallow. Handle it meaningfully or rethrow with context.
- Frontend: no `catch {}` that hides a failure behind a spinner that never resolves. Every failure has a visible state.

## 5. Naming and types
- Verbose over ambiguous: `durationInMs` not `duration`, `useBrowserLayoutEffect` not `useIsoEffect`.
- No `any`, no blanket `# type: ignore`, no `as unknown as X` without a comment explaining why it is unavoidable.
- snake_case in API JSON, camelCase in frontend code, transformed once at the boundary. Never mixed shapes floating through the app.
- Booleans read as assertions: `isEligible`, `hasResume`, `shouldRetry`.
- A function name with "and" in it is two functions.
- File placement follows the existing feature-based structure. A new top-level directory needs a reason.

## 6. Reuse and composition
- Composition over inheritance and over flags. A function with four boolean parameters is four functions.
- No `utils.py` or `helpers.ts` dumping ground. If it has no home, it needs a named module.
- Shared UI comes from the component library with a variant prop, not a copy-paste with a tweak.
- Do not build an abstraction for one caller. Build it on the third, when the shape of the variation is known.

## 7. Blocking every time
- A view with an ORM query in it.
- Business logic importing a framework module.
- A second copy of an existing util, type or constant.
- A new endpoint with no object-level permission check.
- A migration bundled into a feature PR.
- A `useEffect` fetching data a Server Component should have fetched.
- Tests asserting mock calls instead of behavior.
- A shared type changed without propagating to every consumer.
- Hardcoded config, URLs, secrets or magic numbers.
- `any` on a public function signature.
- An em dash in code, comments, docs or commit messages.
