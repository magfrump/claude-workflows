I recommend a **Postgres-backed queue in the orders database, using `SELECT … FOR UPDATE SKIP LOCKED`**. If your language has a mature job library built on it, use that rather than writing your own (about 90% confident).

The other two new options are ruled out by your own constraints. Redis and SQS each need a new vendor, which takes two quarters to approve. They also can't take a job in the same transaction as the order unless you first write it to a Postgres table anyway, and that is the Postgres queue with an extra system added. Keeping the cron leaves the five-minute delay.

I couldn't open the installed copy of the decision workflow (`~/.claude/workflows/divergent-design.md`) because file access is limited to this directory. I followed the copy in this repo, `workflows/divergent-design.md`. I've assumed this repo is claude-workflows, but I can't confirm that. There is no `docs/decisions/` folder, so there were no earlier decisions to build on. I can't write files, so the scratch notes and the decision record are printed below.

```
◇ step 1 diverge    12 candidates → docs/working/dd-background-jobs.md
                      1 cron 5-min (as is)  2 cron 1-min + in-txn work table  3 hand-rolled PG SKIP LOCKED
                      4 PG queue + LISTEN/NOTIFY  5 existing PG job library  6 Redis + Sidekiq-style
                      7 SQS + Lambda  8 PG outbox → managed broker  9 run inline after commit
                      10 self-host Redis on app servers  11 queue in a separate DB  12 reframe: keep cron, gate emails
◇ step 2 diagnose    9 constraints (5 hard · 4 soft) → docs/working/dd-background-jobs.md
◇ step 3 match       3 of 12 survived → [5] [3] [4]
```

---

### `docs/working/dd-background-jobs.md` (printed instead of written)

**Step 1.0:** Searched past decisions for "background jobs, queue, cron, outbox, Redis, SQS": nothing found, because `docs/decisions/` doesn't exist. There is no prior choice to start from.

**Step 1.1 candidates**
1. Keep the five-minute cron as it is (do nothing).
2. Cron every minute, scanning a work table that is written in the order's transaction (minimal change).
3. A jobs table you write yourself in the orders database. Workers on all three app servers claim jobs with `FOR UPDATE SKIP LOCKED`.
4. Option 3, plus a `NOTIFY` on insert so idle workers wake up immediately.
5. An existing Postgres-backed job library for your language (Oban, GoodJob or Solid Queue, River, pg-boss, Procrastinate), with its tables in the orders database.
6. Redis with a Sidekiq-style worker library.
7. Amazon SQS with a Lambda consumer.
8. Write jobs to a Postgres table in the order's transaction, then forward them to SQS or Redis (would be ideal if effort and procurement were free).
9. Naive: skip the queue and do the work in the request, right after commit.
10. Unconventional: run Redis or RabbitMQ yourselves on the existing app servers to avoid procurement.
11. Unconventional: put the queue in a separate database on the same Postgres server.
12. Reframe: keep the cron, and only send email once the order reaches a "settled" status.

Health check: options 3, 4, 5 and 8 cluster around Postgres. Options 9, 10, 11 and 12 were added to break the assumption that "a queue is the answer". The ideas cover technical, time-shifted, organizational (10) and reframe angles.

**Step 2 constraints**
- **H1 – Same transaction.** A job exists if and only if its order transaction commits.
  - success: an integration test inserts an order and its job, rolls back, and finds 0 job rows and 0 email calls. In production, 0 confirmation emails go to an `order_id` missing from `orders` over 30 days.
- **H2 – No new vendor or infrastructure** for two quarters.
  - success: the setup uses only the Postgres 16 instance and the three app servers, and the hosting invoice has no new line.
- **H3 – Latency.**
  - success: 95% of jobs start within 30 s of being created at peak (40 per minute), measured as `started_at - created_at` over one week.
- **H4 – One part-time operator can run it.**
  - success: no new stateful service to patch or back up, a runbook of one page or less, and queue depth, oldest-job age and failed count all from a single SQL query.
- **H5 – Survives losing an app server.**
  - success: in staging, killing a worker mid-job means another server retries it within the lease timeout.
- S1: handles 10× headroom (400 per minute) without a redesign.
- S2: takes days to build, not weeks.
- S3: jobs may run more than once (at-least-once), but handlers make repeats harmless (idempotent), so customers don't get duplicate emails in normal operation.
- S4: doesn't slow down the orders database (table bloat, long-held locks).

Not obvious: Postgres never shows one transaction's uncommitted rows to another. So a cron reading committed rows could not have emailed rolled-back orders. Last year's 212 refunds must have come from work being recorded or triggered **outside** the order's transaction (a second connection, autocommit, or sending before commit). Any option only meets H1 if the job insert uses the **same connection and transaction** as the order insert.

**Step 3 matrix** (✓ meets · ~ partly · ✗ fails · ⚠ makes it worse)

| # | Approach | H1 | H2 | H3 | H4 | H5 | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | Cron 5 min | ✗ (as built) | ✓ | ✗ | ✓ | ✗ | pruned |
| 2 | Cron 1 min + in-txn table | ✓ | ✓ | ~ (≤60 s+) | ✓ | ✗ (cron runs on one host) | pruned |
| 3 | Hand-rolled SKIP LOCKED | ✓ | ✓ | ✓ | ~ (your own code to maintain) | ✓ | **survives** |
| 4 | Option 3 + NOTIFY | ✓ | ✓ | ✓ | ~ | ✓ | **survives** |
| 5 | Existing PG job library | ✓ | ✓ | ✓ | ✓ | ✓ | **survives** (only if your language has one) |
| 6 | Redis + Sidekiq-style | ⚠ (two separate writes) | ✗ | ✓ | ✗ | ✓ | pruned |
| 7 | SQS + Lambda | ⚠ (two separate writes) | ✗ | ✓ | ~ | ✓ | pruned |
| 8 | PG table → broker | ✓ | ✗ | ✓ | ✗ | ✓ | pruned |
| 9 | Inline after commit | ✓ | ✓ | ✓ | ✓ | ✗ (lost on crash, no retry) | pruned |
| 10 | Self-hosted Redis | ⚠ | ~ | ✓ | ✗ | ~ | pruned |
| 11 | Separate database | ⚠ (no cross-database transaction) | ✓ | ✓ | ✓ | ✓ | pruned |
| 12 | Reframe | ~ | ✓ | ✗ | ✓ | ✗ | pruned |

Fixes for weak spots:
- Option 3's maintenance cost (H4) goes away by using option 5 where a library exists.
- Option 4: NOTIFY won't reach workers through a PgBouncer pool in transaction mode. Keep polling as a fallback.

---

```
┌─ DECISION: Background jobs: same transaction as the order, <30 s, no new vendor ─┐
│ 3 candidates survived step-3 pruning · scored on the step-4 axes                 │
└──────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                 effort       risk      coverage   key downside
  ───  ──────────────────────  ───────────  ────────  ──────────  ──────────────────────────────
   5  ★ PG job library          ● 2–4 days   ● low     ● 5/5 hard  ◐ needs a library for your stack
   3    hand-rolled SKIP LOCKED  ◐ 4–7 days   ◐ med     ◐ 5/5 hard  ◐ claim/retry code is yours (mitig.)
   4    #3 + LISTEN/NOTIFY       ○ 5–9 days   ◐ med     ◐ 5/5 hard  ○ extra complexity, little gain

  Say a # to open that option's card. Option [5]'s card is open below.
```

```
╭─ [5] PG job library   ★ recommended ──────────────────────────────────────╮
│ effort    2–4 days (schema migration, 3 handlers, cutover, runbook)      │
│ risk      low                                                            │
│ coverage  5/5 hard · 4/4 soft                                            │
│ hypothesis  "If chosen, 95% of jobs start <30 s after creation and 0     │
│             emails go to rolled-back orders within 4 weeks of cutover;   │
│             counter-evidence = any email whose order_id is not in        │
│             orders, 95th-percentile start >60 s at peak, or >1M dead     │
│             rows in the jobs table."                                     │
│ stress-tests applied                                                     │
│   · Boring alternative → cron 1-min fails H5, gives ≥60 s; still pruned  │
│   · Scale test → 400/min ≈ 7/s, easy for SKIP LOCKED; risk is bloat →    │
│     clean up finished jobs                                               │
│   · Failure-driven → slow email call while holding a lock, duplicate     │
│     send on crash → leases + idempotency keys                            │
│   · Org survival → a maintained library outlives hand-rolled code; #5>#3 │
│ key downside  if your stack has no mature library, fall back to [3] (mitig.) │
╰──────────────────────────────────────────────────────────────────────────╯
```

```
▶ recommend [5] PG job library · confidence 90% · runner-up [3], axis = maintenance vs control
```

All three survivors are the same idea: a queue in the orders database. Picking between them depends on your stack, so I made a tentative pick of [5] and noted [3] as the fallback. This is a clear-winner case, so I haven't filed a question for you to answer.

---

### `docs/decisions/001-background-jobs-postgres-queue.md` (printed instead of written)

**Goal**: Choose how Larkspur Orders runs background jobs (confirmation emails, invoices, warehouse stock sync).
**Project state**: Decision only · standalone · not blocked
**Task status**: complete (decision recorded; tentative pick [5] until the stack is confirmed)

**Context.** A cron job every five minutes scans for unsent work. The delay is the top customer complaint. Last year, emails went out for orders whose transaction rolled back, and 212 customers were refunded by hand. The setup is one managed Postgres 16 instance and three app servers. There is no Redis and no AWS account, a new vendor takes about two quarters to procure, and operations is one part-time person. Peak load is about 40 jobs per minute.

**Options considered.** Postgres SKIP LOCKED queue (an existing library or written in-house, optionally with LISTEN/NOTIFY), Redis with a Sidekiq-style library, SQS with Lambda, and the current cron. Eight further variants were also scored (see the scratch doc).

**Decision and rationale.** Put a jobs table in the **orders database**, insert into it in the **same transaction and connection** as the order, and have workers on all three app servers claim jobs with `FOR UPDATE SKIP LOCKED`. Use a mature library for your language if one exists ([5]); otherwise write it yourselves ([3]). It is the only option family that meets all five hard constraints. Same-transaction enqueue comes free from Postgres, it needs no procurement, and it adds no new system to run. Implementation rules:
- Claim each job with a lease: mark it claimed with a `locked_until` time, commit, then do the work. Don't keep a transaction open during the email or warehouse call.
- Give every email a provider idempotency key such as `order_id:confirmation`, and make the warehouse sync safe to repeat.
- Retry with backoff, and mark jobs `failed` after N attempts.
- Poll every 1–2 s.
- Delete or archive finished jobs on a schedule so the table doesn't bloat.
- Ship the H1 rollback test before cutover.

See alternatives considered →

**Pruned candidates and why.**
How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future decisions in nearby areas can search this section to avoid proposing the same options again.
[1]: five-minute delay, and the current version doesn't keep work in the order's transaction. [2]: cron runs on one host, so losing it stops all jobs; delay is ≥60 s. [4]: NOTIFY saves under 2 s against 1–2 s polling and breaks behind a transaction-mode pooler. [6]: new vendor, and the job is written separately from the order. [7]: new vendor and AWS account, and the job is written separately from the order. [8]: correct, but needs a vendor and a second system. [9]: work is lost if the process dies after commit, with no retry. [10]: a stateful service for a part-time operator, and the job is still written separately. [11]: no transactions across databases. [12]: doesn't fix the delay. Prior pruning grep: no matches found for [background jobs, queue, cron, outbox, Redis, SQS].

**Stress-test mitigations.**
- How to read: *Failure-driven* mitigation. Leases, idempotency keys and failing after N attempts handle locks held during slow calls and duplicate sends after a crash. This lowered [3]'s risk from high to medium.
- How to read: *Scale test* mitigation. A cleanup job for finished rows closes off the bloat risk at 10× load.
- How to read: *Organizational survival* mitigation. A maintained library is preferred over in-house code, which ranks [5] above [3].

**Consequences.** Easier: jobs exist only if the order commits, jobs start within seconds, no new system to run, and queue health is a SQL query. Harder: queue load shares the orders database, and handlers must be safe to run twice.

**Revisit triggers.**
How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can search this section when their situation changes to see whether earlier decisions still apply.
If sustained load goes above 50 jobs per second. If dead rows in the jobs table stay above 1M after vacuum. If 95th-percentile start time at peak goes above 60 s. If a Redis or AWS contract is signed for another reason. If jobs need to reach systems outside the orders database's transaction.

---

The rule that matters most, whichever version you build: **the job insert must use the same database connection and transaction as the order insert.** Postgres never lets one transaction see another's uncommitted rows. So last year's cron couldn't have seen rolled-back orders on its own; the work must have been recorded or sent outside the order's transaction. A queue only prevents another round of refunds if it fixes that. Write the rollback test (order plus job, roll back, check for zero jobs and zero emails) before you switch over.
