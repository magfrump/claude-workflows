# Tech Debt Triage — Evaluation Criteria

Synthetic debt items at invented companies. Each fixture is one debt item,
written up with the code excerpt, history, incident notes, change frequency
and team context the model would otherwise read from a repo. Each item's
correct call follows from one rule in SKILL.md's fix-or-carry decision, and
the rest of the write-up is kept consistent with that call. Four planted items
call for action; two negatives are carry-type items that must not be pushed to
Fix now.

## Fixture → Expected Finding Map

| Fixture | SKILL.md rule | Driver | Expected Recommendation | Must Mention |
|---|---|---|---|---|
| tc-td1-discount-rules.md | Fix now: high carrying cost, manageable fix, no competing work | Hot-path discount function touched in 49 of 52 weeks. Four incidents (INC-2231, -2270, -2298, -2340), each blaming hand-ordered branch precedence. 4-5 day fix, no deadline this month | Fix now; `### Carrying Cost: High` | the incident count (four), or that it changes weekly |
| tc-td2-statement-renderer.md | Fix now: urgency trigger imminent (dependency EOL) | Stable and incident-free, but Quarrel 2.x reaches EOL on 2026-12-31, 87 days after the write-up date. The regulator's 2027-02 exam requires supported runtimes, and the board has refused a risk acceptance before | Fix now | the runway to EOL (~12 weeks / 87 days / under 3 months), or finishing before the February exam |
| tc-td3-nightly-reconciliation.md | Fix now: urgency trigger imminent (scaling threshold) | Peak memory 12.4 → 14.2 GB over June-September, i.e. +0.6 GB/month, against a 16 GB hard limit: about 3 months (December) until OOM. Carrying cost is low today | Fix now | the growth rate, the ~3-month runway or December, or the 1.8 GB of headroom |
| tc-td4-postcode-validation.md | Fix opportunistically: medium carrying cost, cheap fix, no urgency, someone is already working there | Three drifted copies of a postcode check, one same-day bug. 2-3 hour fix, and FUL-1187 rewrites every line of the three blocks next sprint | Fix opportunistically; `### Carrying Cost: Medium` | doing the fix as part of / alongside FUL-1187 (or the pydantic migration) |
| tc-td5-vat-rate-tables.md | Carry intentionally: low carrying cost relative to fix cost | **Negative, false-urgency trap.** 780 ugly lines and a new hire calling for a rewrite, but last changed 2024-03-14, no incidents ever, 412 finance-checked tests, one caller, 6-8 day fix | Carry intentionally, and not Fix now; Carrying Cost neither High nor Medium | that it has been unchanged for over two years |
| tc-td6-job-queue.md | Defer and monitor: uncertain whether it becomes urgent, set a trigger | **Negative.** Homegrown queue running at 40 of a load-tested 900 jobs/s, no incidents. It would only need replacing if a second region is approved, with go/no-go at Q2 2027 planning. 3-4 week fix, and the team has a contractual Q4 deadline | Defer and monitor (Carry intentionally also accepted), and not Fix now | re-evaluating when the second-region decision is made |

tc-td1, tc-td3, tc-td5 and tc-td6 also run `format_check`
(tech-debt-triage-format.bats) on the report.

## Notes

- **field_match is any-line.** A single-item triage has one
  `**Recommendation:**` line, but a report that emits more than one still
  passes if any of them matches. The driver-specific `cites_pattern` is what
  shows the call was made for the right reason.
- **Patterns key on derived facts.** The fixtures list incidents one by one
  but never state the count, give monthly memory figures but not the growth
  rate, and give the EOL and last-commit dates but not the time remaining or
  elapsed. Every `cites_pattern` was checked not to match its own fixture.
- **tc-td2 and tc-td3 test the urgency path, not carrying cost.** Both items
  are cheap to carry today. SKILL.md's Fix now rule includes "an urgency
  trigger is imminent" on its own, so a report that grades carrying cost Low
  and still says Fix now is correct. Carrying cost is not checked on either.
- **tc-td4 vs the planned-feature trigger.** SKILL.md lists "a planned feature
  much harder to build on top of this debt" as an urgency trigger. FUL-1187 is
  a request-parsing migration that doesn't change the postcode rules, and the
  fixture says so, so it is the "someone already working in this area" case
  and not that trigger. Most likely to move on a real run: the model may call
  it Fix now because the planned work is only two weeks away, or grade
  carrying cost Low.
- **tc-td6 accepts two values.** SKILL.md's Defer and monitor ("uncertain
  whether it will become urgent") fits best, but Carry intentionally with a
  stated revisit condition is a defensible reading, so both pass. The check
  that matters is `no_field:Recommendation=Fix now`.
- **Unavailable steps.** SKILL.md's scoping says to read the code, its callers
  and `git log`. The harness runs with no tools, so the runner prompt says
  the repository is unavailable and the write-up is complete.
- **Title window.** The report title (`## Tech Debt Triage: ...`) is the first
  thing SKILL.md's template prints, so the format suite's default 5-line
  title window is left as it is.
- Planted figures were checked: 2026-10-05 → 2026-12-31 is 87 days
  (tc-td2); (14.2 − 12.4) / 3 = 0.6 GB/month, and (16 − 14.2) / 0.6 = 3
  months (tc-td3).
- Fixture files carry no comments naming the driver or the expected call.
