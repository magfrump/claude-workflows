# What-If Analysis — Evaluation Criteria

Synthetic design docs, RFCs and change proposals for invented companies. Five
each plant one flaw aimed at one of SKILL.md's cognitive moves; the rest of
each proposal is kept reasonable so the flaw is the obvious finding. One
negative is a small, genuinely reversible change that must not be tagged a
reversibility cliff.

## Fixture → Expected Finding Map

| Fixture | Move | Planted flaw | Graded check | Must Mention |
|---|---|---|---|---|
| tc-wi1-order-events-queue.md | 1 Load-bearing assumptions (and 4 Invert the confidence) | Moving order events to an at-least-once log with no dedup, justified by "every consumer is idempotent" stated as fact. `loyalty-accrual` adds points and `invoice-mailer` sends email, so a replay double-credits or double-sends | an `**If wrong:** redesign` or `full retreat` line (cites_pattern) | duplicate / double points, receipts or pick tickets, or that idempotency is asserted without evidence |
| tc-wi2-ticket-auto-close.md | 2 Second-order effects | Auto-close for pending tickets cut from 7 days to 48 hours. 39% of customer replies arrive on day 3-7; the model says auto-close counts don't change and never traces those customers coming back | none (no graded field fits) | late repliers open new / duplicate tickets, reopen or re-contact, or that the metric gain moves work rather than removing it |
| tc-wi3-settlement-batch-schedule.md | 3 Hidden coupling | Settlement batch moves from 01:00 to 03:00 UTC. The Environment table lists `warehouse-sync` at 02:15 copying `merchant_settlement` into the finance warehouse; the proposal never connects them, so the copy now runs before settlement and ships stale or partial data | none | `warehouse-sync` / 02:15 now runs before settlement completes, or the finance warehouse gets the previous day's or incomplete data |
| tc-wi4-password-hash-upgrade.md | 6 Reversibility gradient | Upgrade-on-login writes Argon2id over the bcrypt value in the same column. "Rollback is instant and complete", including redeploying the release that predates the work, which cannot verify Argon2id, so every upgraded account is locked out; the gradient steepens with every login | a `[REVERSIBILITY CLIFF]` line naming the hash, rollback or login | bcrypt hashes overwritten / lost, or the previous release cannot verify the new hashes (lock-out) |
| tc-wi5-free-tier-launch.md | 7 Cost of success | Free tier targeting 40,000 accounts, with the same in-app Contact us button. Support is 4 agents handling ~900 conversations/month from 2,100 paying accounts (~0.43 each). The model costs hosting but never support | none | support / ticket volume at 40,000 Solo accounts, or a `[SUCCESS COST]` about support |
| tc-wi6-http-client-swap.md | (negative) | **Sound.** Per-request flag between two HTTP clients with the same API, both kept for a quarter, no data, schema or contract change, flag-off rehearsed in staging and production at 1% | no list item or table row tagged `[REVERSIBILITY CLIFF]` | nothing specific |

tc-wi1, tc-wi4 and tc-wi6 also run `format_check` (what-if-analysis-format.bats)
on the report.

## Notes

- **The graded vocabulary is thin.** SKILL.md grades only `**If wrong:**`
  (tweak / redesign / full retreat) and the Findings Summary tags. The skill
  lays the assumption fields out as a bullet list (`- **If wrong:** redesign`),
  and `field_match` only reads lines that start with the field, so the grade is
  a `cites_pattern` that allows a list prefix. It passes if ANY assumption is
  graded redesign or retreat, so on tc-wi1 it shows
  only that the report graded something load-bearing; the `cites_pattern` is
  what ties it to the idempotency claim. The tag-anchored pattern on tc-wi4 needs
  a hash/rollback/login word within 300 characters on the same line as the tag.
- **One move per fixture, but moves overlap.** A report may file tc-wi1 under
  Confidence Inversions rather than Assumptions Examined, tc-wi3's coupling under
  Consequence Chains, or tc-wi4's lock-out under Adversarial Scenarios. The
  patterns do not care which section carries the finding. Only tc-wi4 insists
  on the tag, because SKILL.md makes "cliff edges" the whole output of move 6.
- **The negative forbids the tag, not the words.** A flat gradient is exactly
  what SKILL.md asks the analyst to say honestly ("the reversibility gradient is
  flat"), so tc-wi6 forbids a `[REVERSIBILITY CLIFF]` at the head of a list item
  or in a table row. Prose such as "No [REVERSIBILITY CLIFF] findings" passes.
  It does not forbid other tags: a report may fairly raise a small second-order
  effect (e.g. the pooled connections' long lifetimes) or a success cost (two
  clients to maintain for a quarter).
- **Prior Art Check.** SKILL.md greps `docs/decisions/` and `docs/working/`;
  no repository is available in inline mode. The runner says so, and SKILL.md
  allows noting it and proceeding. No fixture expects a `[PRIOR CONSIDERATION]`.
- **Title position.** The no-upstream-critique note (3 lines) and the prior-art
  note both come before the title, so the format suite's title window is 12.
- Planted figures were checked: 1,600 × $39 = $62,400 and 40,000 × $0.35 =
  $14,000 (4.5× cover); 800 × $39 = $31,200 (2.2×); 25 × 2,100 = 52,500 ≥ 42,000
  (tc-wi5). 03:00 + 95 min = 04:35, 85 min before the 06:00 cutoff (tc-wi3).
- Fixture files carry no comments naming the flaw.
