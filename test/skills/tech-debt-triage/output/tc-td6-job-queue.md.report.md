## Tech Debt Triage: Homegrown job queue on a Postgres table

**Location:** `jobs` table in the primary Postgres database, plus the worker claim logic (`claim_next`). It serves 11 job types: certificate generation, email digests and video transcode callbacks.
**Nature:** Architectural/infrastructure. A single-primary design with no dead-letter handling, no metrics and no multi-region support.
**Cost of Deferral:** `+0 — inert`. There were 2 small commits in 12 months, no incidents, and no evidence that job types are being added fast enough to grow the migration scope.

### Carrying Cost: Low
The queue causes almost no day-to-day friction. It is rarely touched, has had no incidents, and runs at about 4% of its load-tested capacity (40 of 900 jobs/sec). Three of the five engineers who have worked on it are still on the team, so knowledge risk is modest. The real gaps are the missing dead-letter queue and missing metrics. Those are observability weaknesses, not reasons for a migration, and nothing so far shows they have caused harm.

### Fix Cost
- **Scope:** Cross-cutting. All 11 job types, the enqueue and worker paths, and new alerting.
- **Effort:** Weeks (3–4 engineer-weeks). On a five-person team, that is close to a full sprint of capacity.
- **Risk:** Medium. A dual-write cutover across 11 job types can lose or duplicate jobs. Duplicate certificates or digests would be visible to users.
- **Incremental?** Yes. Job types can be migrated one at a time behind the dual-write.

### Urgency Triggers
- **APAC second-region decision at Q2 2027 planning.** If the answer is yes, replacement becomes mandatory. If it is no, nothing on the roadmap requires a change. This is the only real trigger, and it has not fired yet.
- **Competing commitment:** the payments-provider migration has a contractual deadline of 2026-12-15, less than four weeks from today. Starting a 3–4 week queue migration now would compete directly with it.
- **Load:** none imminent, given about 22× headroom.
- **Team change:** watch for this. If the remaining engineers who know the queue drop below two, knowledge risk goes up.

### Recommendation

**Recommendation:** Defer and monitor

Replacing the queue now would spend 3–4 engineer-weeks on a problem that may never arrive. The only thing forcing a change is the multi-region decision, and that is still exploratory and unresolved until Q2 2027. Load, incidents and change frequency all support carrying the queue as it is. Doing the work now would also take capacity from a contractually deadlined payments migration.

The re-evaluation trigger is the **Q2 2027 go/no-go**:
- **If yes:** plan the migration as part of the region build-out. It is incremental and a few weeks long, so it is unlikely to be on the critical path of standing up a new region.
- **If no:** move this to Carry intentionally.

If the team wants to reduce risk cheaply in the meantime, two separate small items are worth considering, but they are not reasons to migrate now:
- Route new job types through a thin enqueue interface, which keeps future migration scope flat.
- Add basic failure metrics and alerting on the `failures` counter, which closes the observability gap.
