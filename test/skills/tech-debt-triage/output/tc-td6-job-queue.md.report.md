## Tech Debt Triage: Homegrown job queue on a Postgres table

**Location:** `jobs` table in the primary Postgres database; worker claim path (`claim_next`); 11 job types (certificate generation, email digests, video transcode callbacks, others)
**Nature:** Structural and architectural. A single-primary design with no dead-letter handling, no built-in metrics and no multi-region support.
**Cost of Deferral:** `+0 — inert; cost is flat`. With 2 small commits in 12 months, the code is not spreading or accreting changes. 3 of the 5 engineers who have worked on it are still on the team. Load sits far below the tested ceiling. The fix cost (11 job types, 3–4 engineer-weeks) grows only if new job types are added, and the write-up gives no sign that is happening at a meaningful rate.
**Failure Cost:** *(left blank)* There have been no incidents. The workloads are certificates, digests and transcode callbacks, not payments or auth. The absence of dead-letter handling and metrics is real, but nothing in the write-up suggests a plausible high-severity incident. Assigning a probability or severity would be guesswork.

### Carrying Cost: Low
The queue is rarely touched, has never caused an incident, and runs at about 40 jobs/sec against a load-tested 900 jobs/sec, which is roughly 22× headroom. The missing dead-letter queue and metrics are genuine gaps, but today they add little friction because the system is stable and rarely changes. Knowledge risk is also low: 3 engineers who know the code remain on a 5-person team.

### Fix Cost
- **Scope:** Cross-cutting. All 11 job types, the worker infrastructure, a dual-write cutover and new alerting.
- **Effort:** Weeks (estimated 3–4 engineer-weeks).
- **Risk:** Medium. A dual-write cutover across 11 job types can drop or duplicate jobs, such as double-sent digests or missing certificates. Choosing a managed queue now, before the multi-region requirements are known, risks picking a service that would need to change again.
- **Incremental?** Yes. Job types can be migrated one at a time behind dual-write, though the alerting and cutover tooling is up-front work.

### Urgency Triggers
- **APAC second-region go/no-go at Q2 2027 planning.** This is the only real trigger. If the answer is yes, the queue *must* be replaced, because a single-primary table cannot serve two regions. If the answer is no, nothing in the current load or roadmap requires a change. The decision is about 4–6 months out and still exploratory.
- **Scaling threshold.** Not imminent. Load would need to grow about 20× to reach the tested ceiling.
- **Team change.** Not imminent. 3 of the 5 people with context remain.
- **Competing work, which argues against fixing now.** The payments-provider migration has a contractual deadline of 2026-12-15, about 3.5 weeks from today (2026-11-20). Spending 3–4 engineer-weeks of a 5-person team's capacity on the queue now would put a contractual commitment at risk to address a requirement that may never materialize.

### Recommendation

**Recommendation:** Defer and monitor

Don't replace the queue now. Carrying cost is low and flat, there is no incident history or capacity pressure, and the only trigger depends on a region decision that is still exploratory. Migrating now would compete directly with the contractual payments deadline. It would also lock in a managed queue before the multi-region requirements (latency, data residency, cross-region ordering) that should drive that choice are known. Set a concrete re-evaluation trigger: **revisit at the Q2 2027 planning cycle, when the APAC go/no-go is made.** If the answer is yes, schedule the queue migration as an explicit early dependency of the region launch, handled as a non-trivial remediation through the research-plan-implement workflow.

Two cheap steps reduce the risk of waiting:

1. **Before Q2 2027, confirm that 3–4 engineer-weeks fits inside a plausible region-launch timeline**, so the queue doesn't end up on the critical path. If leadership expects a fast launch after a "yes", start a short, time-boxed vendor evaluation shortly before the decision. Don't start migration work.
2. **Treat the dead-letter and metrics gaps as separate, smaller items.** Adding basic queue-depth and failure-count alerting is far cheaper than a full migration and helps whichever way the region decision goes. It is optional, since nothing in the write-up shows these gaps are causing harm today.
