## Tech Debt Triage: statements-renderer still on the Quarrel 2.9 runtime

**Location:** `statements-renderer` service (render path using `q2.pdfkit.{Document, Page, FontCache}`, template `statement_v7`)
**Nature:** Dependency / runtime lifecycle. The service is pinned to an end-of-life runtime by a module (`q2.pdfkit`) that was removed in Quarrel 3.
**Cost of Deferral:** `+0 until 2026-12-31, then +1 unpatched runtime vulnerability (bundled TLS/XML) per Halloway security advisory`. A compliance cliff also lands at the 2027-02 exam.
**Failure Cost:** `Low × High` now, rising to `Med × High` after 2026-12-31. The service handles statement data for about 210,000 members, and from January its bundled TLS and XML libraries stop receiving patches. A regulator finding is close to certain if the service is still on 2.x at the 2027-02 exam, because the board declined a risk acceptance in 2025.

### Carrying Cost: Low
Day to day, this debt costs almost nothing. The code is stable: 11 commits in three years, and the last functional change was in 2025-02. It has had no incidents, member complaints are at their normal level, and byte-for-byte golden-file tests protect it. Nobody is being slowed down by it. The case for fixing it comes entirely from the external deadlines below. Developer friction plays no part.

### Fix Cost
- **Scope:** Localized. The service is self-contained, with one input queue and one output bucket, so no callers have to change.
- **Effort:** Days. The write-up estimates 8–10 engineer-days, mostly rebuilding the `statement_v7` template on `quire-pdf` and re-baselining golden files. This estimate comes from the write-up. I have not checked it against the code.
- **Risk:** Medium. A new PDF library will change every output byte, so all golden files fail at once. Re-baselining them removes the regression safety net exactly when it is most needed. Layout, pagination (the 42-line page split) and font differences then have to be caught by human or semantic review, which byte comparison can no longer provide.
- **Incremental?** Mostly no. The port is one change. However, the new renderer can be built and shadow-run next to the old one, rendering both and comparing them, before cutover. That breaks the risk into stages even though the code change is a single piece.

### Urgency Triggers
- **Quarrel 2.x end of life on 2026-12-31.** That is about 6 weeks from today (2026-11-19), and the holiday period falls inside it. After that date there are no security patches for a service that holds member data.
- **Regulator IT examination in 2027-02.** Last year's report requires a vendor-supported runtime for every system handling member data. The board refused a risk acceptance in 2025, so the usual exception path is not available.
- **Team capacity.** The logging migration was planned to finish in early November. The write-up is from 2026-10-05, so I can't tell whether it has finished or slipped. About six weeks of the original runway have already passed since the item was raised.

### Recommendation

**Recommendation:** Fix now

The carrying cost is low, but two imminent triggers override it. The runtime goes out of support on 2026-12-31, and the 2027-02 exam has no realistic risk-acceptance fallback. Together they turn a debt that was inert into a hard deadline with severe failure cost. The fix is small and contained (8–10 engineer-days on one self-contained service), so this item should start this week. If the logging migration has slipped, this should take priority over it, because the logging work has no external deadline and this does.

Suggested approach:
1. **Start immediately.** Put one or two engineers on the work so it fits within the ~6 weeks, with buffer for the holidays and for estimate overrun.
2. **Plan around the monthly statement cycle.** Cut over between statement runs. Shadow-render at least one real cycle (November's, if timing allows) on `quire-pdf`, and compare the output by text extraction, page count and visual diff before switching.
3. **Re-baseline the golden files only after the shadow comparison has been reviewed and signed off.** Have someone outside the porting work review a sample of statements, so that "matches the new golden file" never ends up meaning "matches whatever we generated."
4. **Contingency.** Ask Halloway now whether extended or paid support for 2.x is available, as insurance in case the cutover slips past 12-31. Treat it only as a bridge. It probably doesn't satisfy the exam requirement without board sign-off.

**Handoff:** This fix touches multiple files and involves a dependency migration, so it should go through the research-plan-implement workflow (`workflows/research-plan-implement.md`), using this triage as input to the research phase. Research should concentrate on how `q2.pdfkit` APIs map to `quire-pdf` (the `FontCache` and `Page.fromTemplate` equivalents), what the template rebuild involves, and the cutover date relative to the statement schedule.

**Uncertainties to resolve first:** whether the logging migration is done, the exact statement-run dates for December and January, and whether the 8–10 day estimate holds once someone has actually looked at what `quire-pdf` supports in templates.
