# Python and Django

Framework layer. Sits under `concerns/security.md` and `concerns/performance-backend.md`, which own the questions this file shows how to answer in Django terms.

## Python quality
- Idiomatic and consistent with the file it lives in. PEP 8.
- **No mutable default arguments.** `def f(items=[])` is a defect, not a style preference.
- Exceptions caught narrowly. A bare `except:` or a broad `except Exception` that swallows is a finding.
- Type hints accurate and useful. Protocol classes where Django's dynamic attributes defeat the type checker. A wrong hint is worse than none.
- **Timezone-aware datetimes everywhere.** `datetime.now()` without a timezone is a defect, use `django.utils.timezone`.
- `Decimal` for money and anywhere float rounding is unsafe.
- Generators, `iterator()` or streaming for large datasets instead of loading everything into memory.
- Context managers for files, connections and locks, so cleanup happens on the failure path too.

## Business logic and invariants
- Logic in a service class, not in the view, the serializer, or the model's `save()`.
- **Invariants enforced in the database where possible**: `CheckConstraint`, `UniqueConstraint`, `unique_together`, `NOT NULL`. Python-only validation loses the race.
- State machines actually prevent illegal transitions, rather than relying on no caller attempting one.

## Models and queries
- Does each query return exactly the intended rows? Read the filter, do not trust the method name.
- `select_related` and `prefetch_related` where a serializer touches a relation. **The serializer is where N+1 hides.**
- Count the queries with `assertNumQueries` or the debug toolbar. Do not estimate.
- No query inside a loop. `bulk_create`, `bulk_update`, or one `filter(id__in=...)`.
- Indexes matching the real filter and ordering.
- `.only()` / `.defer()` on wide rows, `values_list` where model instances are not needed.
- Explicit `db_table` as `{app}_{model}`. Never rename a table mid-project.

## Transactions and concurrency
- `transaction.atomic` around multi-step state changes, kept short.
- **No external API call inside an open transaction.** It holds a connection for the length of someone else's outage.
- Check-then-act races resolved with `select_for_update`, `get_or_create`, or a unique constraint.
- Duplicate requests do not double-charge, double-send or double-create.

## Migrations
- Reviewed independently of the feature, ideally in their own PR.
- Sequence respected: add nullable column, backfill, dual-write, switch reads, drop old. Not in one deploy.
- **Schema migrations and destructive data migrations separated**, each with its own deploy.
- Reversible, or the irreversibility stated with the recovery plan.
- `ALTER TABLE` locking checked against the real row count.
- Backfill batched, resumable and throttled.

## APIs and validation
- All external input validated server side. Serializers, forms or schemas are the single source of validation, not an `if` block in the view.
- URL shape consistent with the rest of the API. A deviation is a recorded exception in the project's own docs, never a silent one.
- snake_case JSON, always.
- Status codes correct: 400 vs 401 vs 403 vs 404 vs 409 vs 422.
- **PATCH is a partial update, PUT is a full replacement.** A PATCH that nulls unsent fields is a data-loss bug.
- Error format consistent, with a stable machine-readable code plus a human message.
- Pagination, filtering and ordering bounded. No unbounded queryset, no client-controlled `limit` without a cap.
- Backward compatible for existing clients, or versioned, or behind a flag until the client ships.
- **Mass assignment:** serializer `fields` explicit, sensitive fields read-only. `fields = '__all__'` on a model with a `role` or `is_staff` column is a P0.

## Authorization, in Django terms
- Permission class present and checking the object, not just authentication.
- **Queryset filtered by the requesting user at the source.** `get_object()` on an unfiltered queryset is a data leak.
- Tenant isolation held across every join.
- Permissions enforced in the query or the service, never only in the UI.
- CSRF, CORS, cookie flags and session settings correct for the deployed environment.
- Uploads validated by size, declared type and actual content.

## Tasks, caching and integrations
- Background tasks idempotent, because they will be delivered twice.
- Retries bounded and backed off, with a dead-letter path.
- Task arguments serializable and stable. Pass an id, not a model instance.
- **Tasks queued inside a transaction use `transaction.on_commit`**, or the worker picks up a row that does not exist yet.
- Timeouts on every outbound HTTP call.
- Cache keys scoped by user, tenant, locale and version. Invalidation defined.

## Observability
- Structured logs with request id and user id, no PII, no tokens.
- `logger.error(msg, exc_info=True)`. Never `logger.error(str(e))`.
- Metrics or an alert for the new failure mode.
- Audit records for anything that changes money, permissions or user data.

## Tests
- Model invariants and permissions tested, including the denied case.
- **Database constraints tested, not just application validation.** Different code paths.
- Query counts asserted on performance-sensitive endpoints.
- Transaction and concurrency behavior covered where correctness depends on it.
- API contract tested for success and every documented failure.
- Tasks tested for retry, duplicate delivery and partial failure.
- External services mocked at the boundary.

## Project conventions
- Dependency lockfile regenerated and committed after any dependency change, including any generated export the build reads.
- The project's CI suite passes locally before the review is requested.
