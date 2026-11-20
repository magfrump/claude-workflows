## Tech Debt Triage: statements-renderer on Quarrel 2.9 runtime

**Location:** `statements-renderer` service (single input queue → single output bucket); dependency on `q2.pdfkit`
**Nature:** Dependency / runtime EOL. The code is stable and tested. The debt is in the platform under it.
**Cost of Deferral:** `+0 per month until 2026-12-31`, then a step change. After EOL, each new Quarrel 2.x security advisory against the bundled TLS/XML libraries stays permanently unpatched, so the count of unpatched vulnerabilities grows with every disclosure. The system is also out of compliance from that date.
**Failure Cost:** `Med × High`. After 2026-12-31 an unpatched TLS/XML library sits in a service handling statement data for ~210,000 members. Probability depends on how exposed those libraries are, which the write-up doesn't say. Severity is high either way: member-data exposure plus a regulatory finding. Separately, a 2027-02 exam finding is close to certain if this isn't fixed, since the board declined a risk acceptance in 2025.

### Carrying Cost: Low
Today this debt costs almost nothing. The service has had 11 commits in three years and no functional change since 2025-02. It has no incidents and on-time monthly output, and byte-for-byte golden tests protect it. Nobody is slowed down by it. The case for fixing it comes from the calendar and the compliance requirement, not from friction.

### Fix Cost
- **Scope:** Localized. One self-contained service with one queue and one bucket, and no callers to migrate.
- **Effort:** Days. Estimated at 8–10 engineer-days, mostly rebuilding the `statement_v7` template on `quire-pdf` and re-baselining golden files.
- **Risk:** Medium. Swapping the PDF library changes every output byte, so the golden-file suite can't detect regressions during the port. Re-baselining defines a new "truth", and someone has to verify that truth by hand. Layout regressions in pagination (42 lines/page), fonts, or totals would reach members on legally significant documents.
- **Incremental?** Mostly no. The runtime and library swap is one coordinated change. Cutover can be de-risked by shadow-rendering a real statement cycle on both versions before switching.

### Urgency Triggers
- **Quarrel 2.x EOL on 2026-12-31.** That is 6 weeks from today (2026-11-20), and the window includes the holiday period and the December statement run. This is the real deadline.
- **Regulatory IT exam in 2027-02.** Last year's report requires vendor-supported runtimes for member-data systems. The usual escape hatch, board risk acceptance, was refused in 2025, so don't count on it now.
- **Team capacity.** The logging migration was planned to finish in early November. It should be done or nearly done by now, so confirm its status, because it is the only competing claim on the four engineers.

### Recommendation

**Recommendation:** Fix now

Carrying cost is low, but both conditions for an imminent trigger are met. Vendor EOL lands in six weeks, and a compliance requirement with no fallback follows in February. The fix is also small, localized, and well-scoped. Treat 2026-12-31 as the deadline, not the February exam. Running a member-data service on an unpatched runtime for two months is exactly the exposure the exam rule exists to prevent, and "we fixed it just before the exam" is a weak position.

### Suggested plan and timing
1. **This week:** confirm the logging migration has wrapped. Assign two engineers so the 8–10 days fit into about one calendar week plus slack. Everyone loses capacity over the holidays.
2. **Weeks of 11-23 to 12-07:** do the port. Before re-baselining, have a human (ideally someone from member services or ops as well as engineering) review a sample of new PDFs against old ones. Cover edge cases: multi-page statements, page-boundary splits at 42 lines, zero-activity accounts, long names and addresses. Consider adding text-extraction or field-level comparisons (balances, transaction lines) alongside the new byte-level goldens, so content correctness is tested independently of layout bytes.
3. **December statement cycle:** shadow-render on Quarrel 4 in parallel with production Quarrel 2. Diff the extracted content across the full member set, then cut over before 12-31. Keep the Quarrel 2 deployment available for one cycle as a rollback only.
4. **Before the exam:** record the migration date and the decommissioning of the Quarrel 2 runtime as evidence for the examiner.

**Contingency:** if the port can't land by 12-31, ask Halloway now whether paid extended support for 2.x exists. Treat that as a short bridge, not a plan.

Since this touches more than one file and involves a library migration, carry it out through the research-plan-implement workflow (`workflows/research-plan-implement.md`), using this triage as input to the research phase.
