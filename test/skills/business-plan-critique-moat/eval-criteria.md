# Business-Plan Moat Critique — Evaluation Criteria

Synthetic business plans for invented companies. Five each plant one flaw aimed
at one of SKILL.md's five lenses; the rest of each plan is kept reasonable so the
flaw is the obvious finding. Two negatives test the stub pre-flight: a stub that
must be skipped, and a short but complete (and sound) plan that must not be.

## Fixture → Expected Finding Map

| Fixture | Lens | Planted flaw | Expected Verdict | Must Mention |
|---|---|---|---|---|
| tc-moat1-veterinary-booking.md | Moat Type | The stated moat is "we got here first": an 18-month head start and a land-grab, with no structural mechanism behind it | Weak or Absent | first-mover / head start / speed is not a durable moat |
| tc-moat2-meal-planning-app.md | Distribution Channel | 71% of installs from Apple App Store search and editorial placement, 17% from TikTok organic; acquisition cost modelled flat for three years and the round funds more of the same | Weak or Absent | the platform owns or controls the demand surface / concentration, or CAC will not stay flat |
| tc-moat3-field-inspection-forms.md | Switching Cost | "High switching costs" claimed, but archive exports in one click to CSV/PDF, contracts are month-to-month, training takes ten minutes, and the integrations that would create lock-in are on the v3 roadmap | Weak or Absent | the one-click export, month-to-month terms, or lock-in that exists only on the roadmap |
| tc-moat4-household-budgeting.md | Network Effect | "Strong network effects" in an app where users never interact; the three named effects are word of mouth, volume pricing and A/B-tested defaults | Weak or Absent | single-player usage / no interaction, or that brand, scale economies and word of mouth are not network effects |
| tc-moat5-sales-call-notes.md | Competitive Response | 94% of recorded calls run on Convene; the plan assumes Convene is "a video company" too slow to build notes and budgets for no incumbent response | Weak or Absent | Convene bundling or shipping the feature natively / free |
| tc-moat6-cold-chain-sensors.md | (pre-flight) | **Stub.** 90 words, TODO / TBD / placeholder markers, empty sections | none | exactly `draft incomplete; moat critique skipped`, and no lens headings or Verdict/Confidence lines |
| tc-moat7-lab-compliance-software.md | (pre-flight) | **Short complete, sound.** 433 words, no stub markers. Regulation-backed switching cost (method re-validation), field sales matched to a $48K ACV, no network effect claimed, incumbent bundling addressed head-on | none | no skip line, no `Absent` verdict |

tc-moat1, tc-moat3 and tc-moat7 also run `format_check`
(business-plan-critique-moat-format.bats) on the report.

## Notes

- **verdict_match is any-lens.** It passes if any `**Verdict:**` line is Weak or
  Absent, so a report that grades the wrong lens down still passes it. The
  flaw-specific `cites_pattern` is what shows the right lens found the flaw.
- **Weak vs Absent.** SKILL.md gives no rule for choosing between them, so the
  flaw fixtures accept both. tc-moat4 is the likeliest to come back Absent
  (no strong-form network effect exists) and tc-moat2 the likeliest to come back
  Weak (the channel works today).
- **The sound plan forbids only Absent.** Its weakest point is growth into labs
  already on a competitor's system, which the plan itself names; a critic can
  fairly grade Distribution or Competitive Response Weak for that. Network Effect
  must be `Not Claimed` (the plan disclaims one), which `no_verdict:Absent` also
  guards: a report that says Absent there manufactured a lens the plan never
  claimed.
- **Title position.** SKILL.md asks for the no-fact-check warning "at the top of
  your output before the critique begins", and the format suite requires the
  `# ...Moat` title within the first 5 lines. The warning as written is 4 lines;
  a report that puts it, plus a blank line, above the title fails format_check.
  That is a SKILL.md/format-suite tension, not a fixture defect.
- **Tools.** None (`FIXTURE_TOOLS="none"`). SKILL.md says not to fact-check ad
  hoc, and every company here is invented.
- Planted figures were checked: 71 + 17 + 12 = 100 (tc-moat2); 20 seats × $29 ×
  12 ≈ $7,000 (tc-moat3); 31,000 seats × $45 × 12 ≈ $16.7M (tc-moat5).
- Fixture files carry no comments naming the flaw.
