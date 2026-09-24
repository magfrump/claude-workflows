# Debt item: homegrown job queue on a Postgres table

**Team:** Core Services (Wrenfield Learning, online course platform) · **Written:** 2026-10-05 · **Raised by:** Sam T., staff engineer

## What it is

Background jobs (certificate generation, email digests, video transcode callbacks)
run on a queue we built ourselves. It is a `jobs` table in the primary Postgres
database, polled with `SELECT ... FOR UPDATE SKIP LOCKED`.

```python
def claim_next(conn, worker_id):
    return conn.execute("""
        UPDATE jobs SET claimed_by = %s, claimed_at = now()
        WHERE id = (
            SELECT id FROM jobs
            WHERE claimed_by IS NULL AND run_after <= now()
            ORDER BY priority, run_after
            FOR UPDATE SKIP LOCKED LIMIT 1)
        RETURNING *""", (worker_id,)).fetchone()
```

It has no dead-letter handling beyond a `failures` counter, no built-in metrics,
and no support for running in more than one database region. The design relies on
a single primary.

## History

- 2 commits in the last 12 months, both small.
- No incidents. Throughput peaks at about 40 jobs per second. The same table has
  been load-tested to 900 jobs per second on the current database.
- Five engineers have worked on it at some point, and three of them are still on
  the team.

## Possible future change

Leadership is exploring a second hosting region for customers in Asia-Pacific. It
is an early-stage conversation. The go/no-go decision is expected at the Q2 2027
planning cycle. If the answer is yes, the queue would have to be replaced with a
managed multi-region queue, because a single-primary table cannot serve two regions.
If the answer is no, nothing about the current load or roadmap requires a change.

## Proposed fix

Migrate every job type to a managed queue service now. Estimated at 3 to 4
engineer-weeks: 11 job types, a dual-write cutover and new alerting.

## Team context

The core services team has five engineers. Their Q4 commitment is a
payments-provider migration with a contractual deadline of 2026-12-15.

Should we replace the queue now?
