# Business-Plan Unit-Economics Critique — Evaluation Criteria

Synthetic business plans for invented companies. Five each plant one flaw aimed
at one of SKILL.md's five lenses, with every other number kept internally
consistent (checked with python3). Two negatives exercise the stub pre-flight:
a stub that must get only the skip line, and a short, sound plan that must get
the full critique. The skill grades nothing, so there is no verdict or
severity check; the checks are `cites_pattern`, `no_pattern` and
`format_check`.

## Fixture → Expected Finding Map

| Fixture | Lens | Planted flaw | Must mention |
|---|---|---|---|
| tc-ue1-dental-scheduling-saas.md | CAC | $1,500 CAC blends 100 practices from the founder's study clubs and alumni group ($150 referral credit each) with 40 paid practices ($195,000 / 40 = $4,875). The model holds $1,500 flat while ~80% of the next 900 practices come from paid channels | "blend", the founder/study-club/alumni network, and the $4,875 paid CAC |
| tc-ue2-fresh-pet-food-subscription.md | LTV | LTV = $62 / 6% = $1,033 on revenue, at a 38% gross margin. Margin-weighted: $23.56 / 6% ≈ $393, so LTV/CAC ≈ 2.2x not 5.7x. Payback in the same plan is correctly margin-based | margin weighting (or LTV on revenue), and ~$39x or ~2.1-2.2x |
| tc-ue3-construction-project-software.md | Contribution margin | Six CSMs at one per 25 accounts ($4,400/account/year, 24% of ACV) and a three-week implementation per new customer (~$9,333) are booked as fixed overhead; the plan claims they stay flat to 600 customers | CS/implementation as per-account (variable) cost, and a figure: $4,400, ~24%, ~57-58% contribution margin, $9,333 or 24 CSMs |
| tc-ue4-hr-compliance-platform.md | Payback | 16-month payback, yet the $3.0M ask funds only three months of acquisition on the claim that cohorts fund acquisition from month four. At 20 customers a month ($480k/month CAC) cumulative need is ~$5.3M over 18 months; with $3.6M the company runs out of cash around month 8-9, and breakeven is ~month 19, not 12 | payback, and the working-capital / self-funding gap |
| tc-ue5-bookkeeping-service.md | Gross-margin trajectory | 41% → 75% gross margin (the basis for the valuation) rests on auto-approval going from 22% to 80% in 18 months; it moved 18% → 22% last year, and categorization is only part of bookkeeper work | automation, and that the lever is unproven / undemonstrated (or the 18% → 22% track record) |
| tc-ue6-waste-hauling-marketplace.md | — (stub) | ~100 words, TODO markers, empty sections | exactly `draft incomplete; unit-economics critique skipped`, and none of the critique's headings |
| tc-ue7-veterinary-inventory-saas.md | — (short, sound) | None. ~410 words, no stub markers. CAC reported per channel with the marginal channel used for planning, margin-weighted and capped LTV, support in contribution margin, 7-month payback, a cohort cash model that fits the raise, flat margin | not the skip line; well-formed; no claim that CAC isn't broken out by channel |

`format_check` (business-plan-critique-unit-economics-format.bats) runs on
tc-ue1, tc-ue3 and tc-ue7.

## Notes

- **The skip line contains `;`**, which the KEY_CHECK list uses as its
  separator, so the stub's pattern matches it as `draft incomplete.
  unit.economics critique skipped`.
- **Recomputed figures** are checked only where the input is unambiguous:
  tc-ue1's paid CAC ($195,000 / 40) and tc-ue2's margin-weighted LTV. tc-ue4's
  cumulative shortfall depends on how the critic models ramp and churn, so only
  the concept is checked.
- **Secondary findings are expected.** A good critique of tc-ue2 may also
  question CAC at scale as paid social triples; of tc-ue5, whether the CPA
  partner channel scales. The checks only require the planted flaw.
- **tc-ue7's false-complaint check** targets the lens the plan most clearly
  gets right (per-channel CAC and a marginal-CAC planning figure). Critiques
  of its lifetime cap or the distributor-fee risk are legitimate and not
  checked.
- No fact-check report is supplied, so every report should open with SKILL.md's
  "No fact-check report provided" warning. That is not checked.
