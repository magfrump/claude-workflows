# Design-Space Situating — Evaluation Criteria

Synthetic decision briefs for invented organisations: a team about to choose
among three options. Five each frame the decision wrongly on ONE of SKILL.md's
eight dimensions; the rest of each brief is kept plain so that misframing is
the obvious tension. One negative is a brief whose options, criteria and
constraints already line up.

The skill grades nothing. There is no `**Verdict:**`, `**Severity:**` or other
field line, so every check is a `cites_pattern` / `no_pattern` plus
`format_check`. Every report names all eight dimensions and uses the placement
vocabulary, so no pattern keys on those words alone: each needs a tension word
within ~200 characters of a fact from that brief.

## Fixture → Expected Finding Map

| Fixture | Dimension | Planted misframing | Must Mention |
|---|---|---|---|
| tc-dss1-partner-webhook-payloads.md | 5 Reversibility | Framed as a cheap formatting choice to "revisit after launch" because switching is a day of serializer work, but 312 partners write their own parsers and the partner agreement keeps every field unchanged for 24 months | the decision is one-way / hard to reverse / locked in for partners, the 24-month agreement, or that the cost is only cheap on Ledgerline's side |
| tc-dss2-ward-shift-swaps.md | 1 Authority + 7 Social structure | One principal architect picks and specifies swap rules for 1,100 nurses on 14 wards with their own swap arrangements; the union agreement makes working-time changes negotiable; nurses first see the rules at go-live training | nurse / union participation, consultation, legitimacy or buy-in, or that local ward arrangements are overridden |
| tc-dss3-card-fraud-rules.md | 2 Orientation in time | "Pick what fits the fraud we see today", then hand finished rules to operations to run unchanged with no re-tuning budget, while the attack mix turned over three times in a year and BNPL/gift cards launch next quarter | a static snapshot against changing attacks, the need for an ongoing process, or rules going stale |
| tc-dss4-roast-profile-automation.md | 6 Formality | A head roaster who adjusts by smell, colour and the sound of first crack, and trains assistants by apprenticeship, is to "write down her rules" into a controller-executed formal spec in six weeks, with manual adjustment switched off | tacit / craft / apprenticeship knowledge being forced into a formal spec, or the formality budget |
| tc-dss5-pumping-station-dashboard.md | 8 Legibility | The control-room screen is scored only on board readability, the regulator return and demo appeal; night-shift operators judge incidents by single-pump pressure drift, which a network health score rolls up | the dashboard is illegible to or hides drift from the operators, or needs a translation layer |
| tc-dss6-build-cache-hosting.md | (negative) | **Well framed.** The operating team decides after asking the product teams, switching is one URL and was rehearsed, the data is regenerable, criteria are measured in a two-week trial, the record is readable by any engineer | no misframing or re-frame language, no Double Diamond hand-off |

tc-dss1, tc-dss4 and tc-dss6 also run `format_check`
(design-space-situating-format.bats) on the report.

## Notes

- **Placement vocabulary is not the signal.** "Expensive", "Snapshot",
  "Tacit", "Expert-led", "Stakeholder" all appear in table cells of reports
  that say nothing about the planted problem. The patterns pair a tension word
  with the brief's specific fact (partners, nurses, attack waves, the roaster,
  the operators) instead.
- **tc-dss2 targets two dimensions.** SKILL.md calls the
  authority/social-structure pair a named tension ("Centralized authority" +
  "user-participatory"). The brief is centralized and expert-led on paper while
  the population it governs already runs its own practice; either reading
  passes.
- **The negative forbids assertions, not vocabulary.** `no_pattern` matches
  wording that says the decision *is* misframed or sends it back (return to
  Diamond 1, "corrected problem statement", "should be reframed", "wearing the
  costume of"). The bare words are allowed, because "no misframing found; no
  re-frame needed" is the right answer for a coherent decision. SKILL.md's
  "None — placements are coherent." line is the expected wording. A minor
  tension bullet (vendor dependency vs. on-call load, say) is allowed.
- **Tools.** None. SKILL.md needs only the stated decision, and the prompt says
  there is no repository access, so the `docs/working/` save is replaced by
  stdout.
- **Title window.** The Output template puts `# Situating Record:` first, so
  the format suite's 5-line title window is left as is. A report that prints a
  long preamble before the title fails `format_check`; that is a genuine format
  miss, not a fixture defect.
- Planted figures: tc-dss5 option scores 17/13/8 out of 20; tc-dss6 18 TB is
  2 × 9 TB. No other arithmetic.
- Fixture files carry no comments naming the misframing.
