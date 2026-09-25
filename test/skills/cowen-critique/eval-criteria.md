# Cowen Critique — Evaluation Criteria

Synthetic drafts about invented towns and companies. Five of them each plant one
flaw that a single cognitive move from SKILL.md should catch. The other two are
negatives for the pre-flight stub rule: one stub that must be skipped, and one
short complete draft that must not be.

cowen-critique grades nothing (no `**Verdict:**` or `**Severity:**` lines), so
every check is a pattern check or `format_check`. A full critique has to use
the words "boring", "revealed", "contingent", "market", "inversion" and
"sub-claim" whatever the draft says, so no pattern keys on those words. Each
pattern names the specific fact in the draft that the flaw turns on.

## Fixture → Expected Finding Map

| Fixture | Words | Planted flaw | Move | Must mention |
|---|---|---|---|---|
| tc-cow1-library-visits.md | 719 | In-person visits fell 42% (1.9M → 1.1M) and the draft blames a collapse in attention. In passing it says the 2021 budget cut branch hours from 60 to 36 a week, a 40% cut. | #1 boring explanation | the cut in opening hours |
| tc-cow2-office-return.md | 666 | Proposes four office days because 78% of surveyed staff say they value in-person collaboration. The optional office it wants to fill runs at 14% desk occupancy. | #3 revealed vs. stated | occupancy / empty desks / staff not coming in |
| tc-cow3-school-calendar.md | 707 | Opposes a shorter summer break because the long summer is "the natural rhythm of childhood" and "how children have always lived". | #8 contingent assumptions | the calendar's history (agrarian, 19th-century) or other countries' calendars |
| tc-cow4-open-plan.md | 696 | Treats a 56% rise in chat messages after an open-plan move as proof of collaboration. Inverted, the same data says people stopped talking out loud (headphones, booths booked 87% of core hours). | #2 inversion | chat as a substitute for, or escape from, face-to-face talk |
| tc-cow5-office-conversions.md | 678 | Models a ~25% margin on converting $95/sqft office towers ($305 all-in against $380 value) and never asks why no developer has done it. | #6 market signal | why developers/investors haven't taken the margin |
| tc-cow6-transit-fares.md | 92 | **Stub.** TODOs, `[X]` placeholders, an empty evidence section. | pre-flight | only `draft incomplete; persona pass skipped` |
| tc-cow7-farmers-market.md | 414 | **Short complete draft.** Under 500 words with no stub markers. | pre-flight | a full critique (not skipped) |

tc-cow1, tc-cow2 and tc-cow7 also run `format_check` (cowen-critique-format.bats).

## Notes

- **The stub checks are strict.** SKILL.md says to "output the single line ... and
  stop", and the pre-flight comes before the no-fact-check warning. So tc-cow6
  also forbids the warning and the `Load-bearing objection` line. If the first
  real run prints the warning above the skip line, that is a real deviation from
  SKILL.md. It is not a sign the pattern is too tight.
- **No fact-check report is supplied.** Full critiques should open with the
  warning. No check requires it, because the fixtures test the moves.
- **tc-cow4 is the loosest pattern.** A critique can make the inversion point
  in many ways ("substitute", "retreat", "instead of talking"). The first real
  run will probably widen this pattern.
- **tc-cow3's pattern accepts either history or geography.** SKILL.md's move #8
  gives both ("50 years ago", "Seoul or Lagos"), and either one shows the
  summer break is contingent.
- The drafts never point at their own flaw. The fact each flaw turns on (hours
  cut, 14% occupancy, booth bookings, the margin) appears as a supporting detail
  or in passing.
- No tools (`FIXTURE_TOOLS="none"`): SKILL.md tells the critic not to
  fact-check.
