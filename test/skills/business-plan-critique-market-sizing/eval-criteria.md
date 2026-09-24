# Business-Plan Market-Sizing Critique — Evaluation Criteria

Synthetic business plans for invented companies. Each of the five flawed plans
carries one market-sizing flaw aimed at one of SKILL.md's five lenses. The rest
of that plan is kept sound: numbers reconcile, a beachhead is named, the "why
now" is dated, and the comp set includes failures. Two negatives come from
SKILL.md's stub pre-flight rule.

## Fixture → Expected Finding Map

| Fixture | Lens | Planted flaw | Expected Verdict | Must Mention |
|---|---|---|---|---|
| tc-mkt1-veterinary-inventory.md | TAM Definition | TAM is the $62B global animal-health market (products sold through clinics) and not spend on inventory software. The plan's own bottom-up SAM is $52.8M. | Inflated or Speculative | drugs/pharmaceuticals, product vs software spend, adjacent category, category fit, or the orders-of-magnitude gap |
| tc-mkt2-public-records-redaction.md | SAM Realism | SAM counts federal agencies (need FedRAMP) and state agencies (often StateRAMP). Together they are $139.8M (46%) of a $302.1M SAM, but FedRAMP work starts in 2028 and StateRAMP is unscoped. | Inflated or Speculative | the certification/authorisation gate makes those segments not yet serviceable |
| tc-mkt3-accounts-payable.md | SOM Achievability | TAM and SAM are sound and reconciled ($2.43B / $851M). SOM is "1% in year one, plus a point a year, to 5% ($42.6M)". It names no beachhead, customer count, or sales capacity. | Speculative or Inflated | beachhead/wedge, customers needed, sales capacity, or the linear share curve |
| tc-mkt4-landscaping-scheduling.md | Market Timing | The "why now" is smartphones, SMB cloud adoption and younger owners. These are decade-long trends with no dated trigger. | Speculative or Inflated | persistent trend / decade / no specific trigger |
| tc-mkt5-construction-project-management.md | Comparable Benchmarks | The comps are the three best-known winners (all >$100M ARR by year 5, one boosted by the 2020–21 boom). No failures or median. The plan calls $38M "conservative" against them. | Inflated or Speculative | cherry-picking, survivorship/selection bias, outliers, missing failures or median |
| tc-mkt6-physio-insurer-billing.md | (negative) | **Sound, short, complete.** 425 words, no stub markers: reconciled TAM, behavioural SAM, 30%-of-beachhead SOM to 4.5% of SAM, April 2025 insurer API mandate, comps including a closure. | no Inflated | — (must not print the skip line) |
| tc-mkt7-pet-insurance-marketplace.md | (negative) | **Stub.** 77 words, TODO/TBD/placeholder sections. | none | `draft incomplete; market-sizing critique skipped` only |

tc-mkt1, tc-mkt5 and tc-mkt6 also run `format_check`
(business-plan-critique-market-sizing-format.bats) on the report.

## Notes

- **verdict_match is coarse.** It passes if any of the five `**Verdict:**`
  lines is failing, not specifically the target lens's. The flaw-specific
  `cites_pattern` is the real signal. A lens-scoped verdict check would need a
  helper change.
- **Inflated vs Speculative.** SKILL.md gives no definitions for the verdict
  values. Both are accepted as failing for every flawed fixture: a number
  resting on the wrong base reads as Inflated, and a claim with no supporting
  path reads as Speculative. `Not Claimed` is excluded. tc-mkt4 has no TAM
  headline by design, so allowing `Not Claimed` would make its verdict_match
  pass trivially.
- **The sound plan forbids only Inflated.** A 425-word plan cannot carry
  full evidence for every lens, so `Speculative` or `Plausible` on thin
  evidence is a fair call. The false-positive signal is a claim that its numbers
  are overstated.
- **Coupling.** tc-mkt2's revenue plan leans on the gated segments, and
  tc-mkt5's trajectory is justified by the comps, so a SOM finding on either is
  a legitimate knock-on. The planted flaw still has to be named.
- **The stub skip line contains ";"**, which KEY_CHECK uses as a separator, so
  the pattern matches it with ".".
- No fact-check report is supplied. SKILL.md then requires its no-fact-check
  warning at the top and forbids ad-hoc fact-checking. All companies, research
  firms and figures are invented, so the critique has to rest on internal
  consistency, which is what the fixtures test.
- Fixture files carry no comments naming the flaw.
