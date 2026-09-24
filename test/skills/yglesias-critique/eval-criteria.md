# Yglesias Critique — Evaluation Criteria

Synthetic drafts from invented organisations. Five each plant one mechanism
flaw that a specific cognitive move in SKILL.md should catch. The draft states
a goal the critic should accept and never names the flaw. Two negatives test
the stub pre-flight: one short draft with stub markers, which must be skipped,
and one short complete draft, which must not be.

yglesias-critique does not grade, so there is no verdict or severity check.
Every critique is told to use "scale", "money", "org chart", "cost disease" and
so on in its fixed sections, so a pattern built on those words would pass on
any report. Each `cites_pattern` keys on the draft's own failure instead.

## Fixture → Expected Finding Map

| Fixture | Planted flaw | Move | Must mention |
|---|---|---|---|
| tc-ygl1-class-size-cap.md | Goal: close the east-side reading gap. Mechanism: an 18-student K-3 cap in all 41 schools at once needs ~157 new teachers on top of ~60 routine vacancies, and seniority transfers let experienced teachers take the new west-side posts. The east side ends up with novices or emergency hires, which undermines the goal. | 1 (goal vs mechanism) | teacher quality/supply, seniority, inexperienced or emergency-permit hires |
| tc-ygl2-down-payment-grants.md | $30,000 grants (4,000/yr, $120M) handed to buyers in a market with <1% vacancy, 3,100 permits/yr and multiple offers under $600k. The draft calls the grant "cash to compete", but the subsidy is bid into prices and sellers capture it. | 3 (follow the money) | capitalization, bidding up prices, sellers capture, supply constraint |
| tc-ygl3-rail-extension.md | Eastline: $7.8B for 9.2 miles (~$848M/mile) against Westline's ~$3.2B for 11 miles (~$291M/mile) in today's dollars, nearly triple per mile. The memo explains away the growth and asks for more money through the same consultant and design-bid-build model. | 5 (cost disease) | cost per mile, near-tripling, peer/international cost comparisons |
| tc-ygl4-apprenticeship-guarantee.md | A 320-student pilot (74 employers, one-in-three selective admission) becomes a guarantee for 45,000 graduates/yr at the pilot's unit cost. At the pilot's ratio that needs ~10,400 host employers, and the pilot's selected students are not the universal pool. | 6 (10 million people) | employer capacity/slots, ~10,000 employers, self-selection or selective admission |
| tc-ygl5-regional-housing-portal.md | A single intake portal for 23 municipalities and 4 counties, run by a voluntary stakeholder steering committee with pooled funding and "data sharing". No lead agency, operator, staff, legal authority or data-sharing agreement is named. | 7 (org chart) | lead agency, owner/operator, who runs it, governance, joint powers, legal authority |
| tc-ygl6-parking-minimums.md | **Stub.** 66 words, TODO/TBD/placeholder markers, empty Proposal and Costs sections. | pre-flight | exactly `draft incomplete; persona pass skipped`, and none of the critique headings, title, no-fact-check warning or load-bearing line |
| tc-ygl7-library-fines.md | **Short complete.** 386 words, no stub markers, a full memo on ending library fines. | pre-flight | no skip line, a full critique that passes format_check |

tc-ygl1, tc-ygl4 and tc-ygl7 also run `format_check`
(yglesias-critique-format.bats).

## Notes

- **Moves not covered.** The boring lever (2), the adoption cycle (4) and the
  popular version (8) have no dedicated fixture. Every draft above has room for
  a boring lever (zoning in tc-ygl2, for example), so it is hard to plant
  cleanly. The adoption-cycle and popular-version moves would suit a later
  fixture on a visible-pain policy such as congestion pricing.
- **Moves overlap.** tc-ygl2 can also read as goal-vs-mechanism, and tc-ygl3 as
  follow-the-money. The patterns check what the report says about the mechanism,
  not which section it appears in.
- **format_check vs. SKILL.md's omission rule.** SKILL.md allows omitting a
  section "if you have nothing substantive to say". yglesias-critique-format.bats
  requires eight sections (all but The Cost Disease Check). A short draft like
  tc-ygl7 is the likeliest place for a model to drop one, such as The Scale
  Test, and fail format_check even though it followed the skill. If that
  happens on a real run, the conflict is between the skill and the format
  suite, not the fixture.
- **No fact-check report is supplied**, so critiqued drafts should open with
  the ⚠️ warning. The stub must not: the pre-flight runs first and outputs a
  single line.
- **WebSearch.** SKILL.md tells the critic not to fact-check on its own. The
  runner lists WebSearch only because generate-reports.bash rejects an empty
  tool list.
- Drafts carry no comments or hints naming the flaw. Arithmetic in each draft
  was checked with python3.
