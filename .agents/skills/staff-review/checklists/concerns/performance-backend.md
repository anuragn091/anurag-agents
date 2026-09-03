# Backend Performance (technology agnostic)

Applies to any server. Django and Python specifics live in the platform checklist.

## Data access
- Does the change introduce excessive or repeated data-store operations?
- **Operations executed inside a loop.** One query per row is the single most common real defect.
- Queries bounded, paginated and indexed for the actual filter and ordering.
- Only the required columns and rows retrieved.
- Joins, aggregations and sorting done efficiently, and in the database rather than in application memory where that is cheaper.
- Execution plan checked for anything expensive. Do not guess at the index.
- **Does it hold up at production data volume, not test-fixture volume?**

## Computation and memory
- Algorithmic complexity appropriate for the input size it will actually see.
- Large datasets not loaded entirely into memory.
- Processing streamed, batched or incremental where the volume warrants it.
- Expensive computation not repeated when it could be computed once.
- Serialization and transformation costs reasonable, especially on large collections.
- Could this exhaust memory, CPU, threads, file handles or database connections?
- Resources released reliably, including on the failure path.

## External dependencies
- External calls minimized or batched.
- **Timeouts on every external call.** A missing timeout is a P1.
- Independent calls run concurrently instead of sequentially.
- Retries bounded, backed off and safe to repeat.
- Circuit breaking or graceful degradation where the dependency is known to be flaky.
- Does one slow dependency block the whole request, or just the part that needs it?
- Dependency failures observable in logs and metrics.

## Concurrency and scalability
- Race conditions and resource contention.
- Locks necessary, correctly scoped, and held briefly.
- Transactions short, and free of external calls.
- Can a retry or a duplicate request corrupt state?
- Idempotency where it is required.
- Does this create a connection, worker or queue bottleneck?
- Predictable behavior at substantially higher traffic. What breaks first at 10x?

## Caching and background work
- Is caching actually beneficial here, and is invalidation defined?
- **Cache keys scoped by user, tenant, locale and version.** A key missing the user id is a data leak, not just a bug.
- Can the caller tolerate stale data, and for how long?
- Slow or non-critical work moved off the request path.
- Background tasks bounded, retryable and idempotent.
- Backpressure applied when consumers cannot keep up.
- Queued work safely replayable.

## Measurement and operations
- Latency, throughput, resource use and error rate measured.
- **Percentiles reviewed, not averages.** p50 hides everything that matters.
- Performance compared before and after the change, with numbers.
- Tested against production-like traffic and data volume.
- Slow operations traceable to the code path that caused them.
- A performance budget exists for this path, or one is being set here.
- Rollout gradual and rollback safe.
