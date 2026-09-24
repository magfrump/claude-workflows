# AI Personas Critique — Evaluation Criteria

Synthetic proposals, each planting one flaw that a specific catalog persona is
positioned to catch. The flaws sit in different domains (municipal policy,
organizational pay, fintech security, marketplace operations, healthcare
analytics) so the skill has to select different personas to find them. Two
negatives test the stub pre-flight. All organisations are invented.

## Fixture → Expected Finding Map

| Fixture | Planted flaw | Aimed at | Expected Severity | Must Mention |
|---|---|---|---|---|
| tc-per1-red-light-cameras.md | Cameras went to the 12 worst intersections of 2023; the 39% drop has no comparison sites (regression to the mean), and is then extrapolated to lower-crash sites | Empiricist | Fatal flaw or Significant weakness | regression to the mean, a control/comparison group, or selection on a high year |
| tc-per2-support-bonus-plan.md | Bonuses and PIPs ride on a single agent-set "Resolved" count per hour; CSAT and quality are explicitly out of pay (Goodhart) | Incentive Analyst | Fatal flaw or Significant weakness | Goodhart, gaming, premature closes / reopens, cherry-picking easy tickets |
| tc-per3-account-recovery-redesign.md | Recovery by SMS code alone; agents move the phone number after name, DOB and card last-4; balance usable immediately | Security Analyst | Fatal flaw or Significant weakness | SIM swap / port-out, social engineering, account takeover |
| tc-per4-marketplace-dispute-desk.md | 40 disputes/week × 50 growth ≈ 2,000/week at ~40 min ≈ 1,300+ hours/week, against three specialists (~120 hours) | Scaling Skeptic | Fatal flaw or Significant weakness | the volume or hours at scale, a bottleneck/backlog, "does not scale" |
| tc-per5-clinic-overbooking-model.md | No-show model's top inputs include insurance category and distance, so publicly insured, self-pay and distant patients get the double-booked slots and bear the waits and bumped visits | Ethicist | Fatal flaw or Significant weakness | proxy / disparate or inequitable burden / fairness / low-income or publicly insured patients |
| tc-per6-transit-fare-memo.md | **Stub.** 106 words, TODO markers, empty sections | pre-flight | — | exactly `draft incomplete; persona pass skipped`; no critique headings or Severity lines |
| tc-per7-library-sunday-pilot.md | **Short complete.** 437 words, no stub markers: small, funded, reversible pilot with stated stop criteria | pre-flight | no Fatal flaw | not the skip line; full, well-formed critique |

tc-per1, tc-per3 and tc-per7 also run `format_check`
(ai-personas-critique-format.bats) on the report.

## Notes

- **Catalog delivery.** SKILL.md Step 1 reads `personas.md` from the skill
  directory. Inline mode runs claude in the real repo, so granting Read would
  also expose `expected-verdicts.bash`. `runner.bash` instead prints the
  catalog into the prompt (resolved relative to its own location) and fails
  if the file is missing, rather than letting the skill fall back to its
  six-persona minimal set.
- **Patterns name the flaw, not the persona.** A persona other than the one
  aimed at may catch the flaw (the Systems Thinker on tc-per5's feedback loop,
  the Implementation Engineer on tc-per4); that still passes.
- **severity_match is loose.** It passes if any persona assigns Fatal flaw or
  Significant weakness, not necessarily the persona that names the planted
  flaw. The cites_pattern check carries the specificity.
- **tc-per7's no_severity:Fatal flaw is a calibration check.** A critique always
  finds something, but a twelve-week, $4,260 pilot with a decision date and
  stop criteria has nothing that should rank as fatal. A persona that calls
  it fatal is miscalibrated.
- **Stub skip line.** Patterns may not contain `;`, so the skip line is matched
  as `draft incomplete. persona pass skipped`.
- **No fact-check report is supplied**, so every full report should carry the
  Step 4 warning. It is not checked.
