# Pre-Mortem — Evaluation Criteria

Synthetic launch, migration and rollout proposals for invented companies, each
written as ready to ship. Five plant ONE concrete failure path a competent
pre-mortem should narrate; the rest of each proposal is kept reasonable so that
path is the obvious story. Two negatives are sound proposals that must not draw
the worst grade.

## Fixture → Expected Finding Map

| Fixture | Failure class | Planted path | Expected Severity | Must Mention |
|---|---|---|---|---|
| tc-pm1-billing-ledger-migration.md | data / rollback | Change capture stops at cutover and Postgres goes read-only; the rollback flips `LEDGER_DSN` back during a two-week soak, so every write made on Keel since cutover is missing from Postgres (no dual-write or reverse sync) | High or Catastrophic | dual-write / reverse sync, or rollback losing or stranding post-cutover writes |
| tc-pm2-checkout-redesign-rollout.md | timing | 100% and old code path deleted on 25 Nov, the day before the change freeze and three days before a Black Friday weekend at ~4x peak; load tested to 1.5x only; the flag has nothing to fall back to | High or Catastrophic | the 1.5x vs 4x gap, the freeze with no fallback, or launching days before the peak |
| tc-pm3-search-index-rebuild.md | human / operational | Marguerite wrote and is porting the indexer, reviews her own runbook, is the cutover on-call, and starts four months' leave on 16 March, days before the old cluster stops being fed (20 March) and is decommissioned (23 March) | Medium, High or Catastrophic | bus factor / single point of failure / no backup, or the leave against the 20-23 March dates |
| tc-pm4-payment-processor-switch.md | external dependency | Tessellate's agreement ends 30 June (non-renewal already served) while the ramp is at 25% until 7 July; rollback "through August" and refunds on Tessellate-taken bookings (up to 11 months ahead) assume a processor that is gone | High or Catastrophic | 30 June against the ramp percentage, or rollback / refunds to an ended contract |
| tc-pm5-self-serve-returns.md | downstream coupling | Requests expected to triple from ~35/day to ~105/day, all still approved by hand by a 3-person Refunds desk that clears ~45/day | Medium, High or Catastrophic | backlog / bottleneck / ~105 a day / ~60 a day shortfall |
| tc-pm6-docs-typeface-change.md | (negative) | **Sound, low stakes.** Internal docs CSS change, cookie-gated preview, static site, five-minute revert | none | no Catastrophic narrative, and an explicit statement that nothing rises to "must address" |
| tc-pm7-orders-column-rename.md | (negative) | **Sound.** Expand-and-contract rename, dual writes through a 30-day soak, per-step flags, daily equality check, snapshot before the drop | none | no Catastrophic narrative, and no claim that the plan lacks dual writes |

tc-pm1, tc-pm4, tc-pm6 and tc-pm7 also run `format_check`
(pre-mortem-format.bats) on the report.

## Notes

- **severity_match is any-narrative.** It passes if any `**Severity:**` line
  matches, so a report that grades an unrelated narrative High still passes it.
  The flaw-specific `cites_pattern` is what shows the planted path was narrated.
  pm3 and pm5 accept Medium because SKILL.md's Medium ("real cost,
  recoverable") honestly fits a degraded search or a slow refund queue.
- **Field lines.** SKILL.md's template lists the fields as bullets
  (`- **Severity:** High`), and the committed `docs/reviews/pre-mortem.md`
  writes them bare. The field reader in eval-helpers.bash accepts both, so the
  runner leaves the format to the skill.
- **No Plausibility checks.** SKILL.md's labels are probability bands, and any
  of them can honestly fit a narrative about these proposals, including
  "Likely" for a small failure on the sound ones. `no_field:Plausibility=Likely`
  is not justified by the spec, so the negatives are checked on Severity only.
- **pm6's "nothing must be addressed" check** comes from SKILL.md's
  Recommendations rule: "If no narratives rise to 'must address' severity, say
  so explicitly."
- **Prior Art Check.** SKILL.md greps docs/decisions/ and docs/working/. The
  harness has no repository for the model, so the prompt says so. The report
  may note that at the top; with the no-upstream note, the title can land around
  line 8, inside the format suite's 10-line title window.
- Planted figures were checked: 35 × 3 = 105 against 45 cleared, a 60/day
  shortfall (pm5); $610K / 0.5% / (18,000 × 12) ≈ $565 average payment (pm4).
- Fixture files carry no comments naming the flaw, and no cites_pattern
  matches its own fixture's text.
