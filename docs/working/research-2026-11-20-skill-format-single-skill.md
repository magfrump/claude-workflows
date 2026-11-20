# Research: three single-skill report mismatches (F4, F6, F7)

Brief: `docs/working/briefs/2026-11-20-skill-format-single-skill.md` (at 697e81ae).
Findings source: `docs/working/research-2026-11-19-regenerate-skill-reports.md` at
0cb729ed (branch `measure/regenerate-skill-reports`), findings F4, F6 and F7.
Branch: `fix/skill-format-single-skill`.

## What the failing cases are, and whose fault each is

The rule from the brief: a pattern that misses a report which says the right thing in
other words is the test's fault; a report that leaves out what its skill tells it to
produce is the skill's (or the model's, when the skill already says it plainly).

### F4, arithmetic-eval (tc-ae1, tc-ae2, tc-ae3): skill

Read with `mode1-equiv.py`'s own `split_mode1`/`reference` against the 0cb729ed
transcripts. In all three the model retyped the Mode 1 program and changed code, not
just comments (comments are already ignored by the AST comparison):

- tc-ae1: dropped the `if hasattr(sys, "set_int_max_str_digits")` line and shortened an
  error message.
- tc-ae2: wrote its own evaluator (no `ck()`, no `Pow`/`Mod`, a bare `except Exception`).
- tc-ae3: dropped the `set_int_max_str_digits` line.

The check is exactly as strict as the skill and its decision (log row 56: wrapper exact,
program equal by `ast.dump`, so a weaker evaluator never counts). The skill said "paste
and run" and "paste the whole block every time", but never that the program itself must
not be edited, and its one-line `if hasattr(...)` reads as optional. Call: skill.

Options (divergent design, Path A):

| Option | Outcome |
|---|---|
| [1] A sentence above the block: copy the program exactly, change only the expression; only comments may go | Chosen. Smallest change, keeps row 56's check |
| [2] Ship the evaluator as a file the block calls by path | A second code path and an install/runner change for one skill (S3, S8); breaks the self-contained design (security model point 2) |
| [3] Loosen the AST check (ignore string constants, allow dropped lines) | Contradicts row 56; still cannot pass tc-ae2's rewrite, and accepting a dropped line accepts a different evaluator |
| [4] Status quo | Leaves 3 of 4 routing cases red |

[1] dominates: [3] cannot fix the cases without accepting a different evaluator, [2]
costs a second mechanism, [4] fails the goal.

### F6, what-if-analysis format 14 (tc-wi1, tc-wi4, tc-wi6): skill, plus one test fix

At 0cb729ed five of six reports wrote each assumption as a bold title
(`**A1. Every consumer is idempotent.**`) with Source / If wrong / Tag bullets under it,
and no `**Assumption:**` field. SKILL.md listed `- **Assumption:** the claim itself` as a
field but showed no worked shape, so turning it into a title is an easy reading. Call:
skill. (tc-wi2, tc-wi3 and tc-wi5 have the same shape but their eval cases do not run
`format_check`, so only format test 20 and tc-wi1/tc-wi4 showed it.)

tc-wi6 is different: it does use the field, as a numbered list item
(`1. **Assumption:** ...`), which the format test's regex did not accept although the
Findings Summary check in the same file accepts `[0-9]+[.)]` items. Call: test.

Options (Path A): [1] add a four-line example under Assumptions Examined (a neutral locale-delivery assumption; review round 1 found the first draft quoted tc-wi1's planted assumption and graded value, which would leak the answer) and accept
numbered items in the test (chosen); [2] make the test also read a bold title as an
assumption (a second grammar for one field, against S3's one source per grammar);
[3] status quo. [1] dominates.

tc-wi6 also fails F5 (it tags a `[REVERSIBILITY CLIFF]` where none is expected); that is
another brief's, and it stays red here.

### F7, pattern misses

- **business-plan-critique-moat tc-moat1: test.** The report says it plainly in other
  words: `"We got here first" / 18-month head start | None. First-mover is a claim, not
  a mechanism` and `There is no moat yet ... than claiming speed is the moat`. The
  pattern only knew `not a ... moat` and `no (durable|structural) moat`. Widened to
  `not a (durable |real |structural )?(moat|mechanism)` after a head start, and
  `no (durable |structural |real )?moat` before one.
- **tech-debt-triage tc-td2: test.** The report names the runway, but counted from the
  run's own date (2026-11-19: "end of life on 2026-12-31. That is about 6 weeks from
  today"), not the write-up's 2026-10-05, from which the pattern's 87 days / 12 weeks
  come. Added: an EOL anchor (`end of life`, `EOL`, `2026-12-31`, `out of support`)
  followed within 150 characters by an approximate runway under about three months
  (1-13 weeks, under 100 days, 1-3 months; bounded after review round 1). Checked against all six 0cb729ed td reports: matches td2 only.
- **tech-debt-triage tc-td4: skill.** Not a wording miss: the heading is
  `### Carrying Cost: Low`, where the fixture plants Medium (three drifted copies, one
  same-day bug), and the report then recommends Fix opportunistically, which SKILL.md
  reserves for Medium. The report also rated Cost of Deferral `+0 — inert`, and
  SKILL.md's Low definition is "ugly but inert": one word for two axes (growth and
  level). Added two lines after the rating scale: the rating is today's level, a `+0`
  rate can still be Medium, and debt that has already caused a defect, or keeps
  diverging, is at least Medium (made general in review round 1, so it does not name
  the fixture's drifted copies). Options:
  [1] that clarification (chosen); [2] test accepts Low or Medium (drops the planted
  signal); [3] status quo. [1] dominates.
- **yglesias-critique tc-ygl4: skill (model slip on an explicit rule), clarified.** The
  Boring Lever section names four levers (ratio caps, registration, CTE hours, WIOA
  dollars) without the word; SKILL.md says "Use the word "lever" in the section body",
  and the other five graded reports comply. So the test enforces what the skill says.
  Options: [1] one sentence in the section intro that the named word goes in the body
  and the heading does not count (chosen: the likely misreading, since the heading
  holds every keyword); [2] count the heading in the test (makes every keyword check
  vacuous, since each heading contains its keyword); [3] drop the body-keyword rules
  from skill and test (wider than this brief); [4] status quo. [1] dominates [4] at the
  cost of one line, and [2]/[3] remove a check rather than fix a case.

## Other choices (one line each)

- Regenerate a whole skill after a skill edit, not only the failing fixtures: an edit
  changes the skill hash in every stamp, so unregenerated reports fail as stale.
- Fixtures unchanged: changing tc-td2's date would invalidate stamps and is not needed.

## Verification

Results are under "Results" below. Reports were regenerated with
`test/skills/generate-reports.bash <skill> <fixture-prefix>`, one fixture at a time;
none are committed (brief item 4).

## Results

Fresh reports, Opus 5.5, generated in this worktree one fixture at a time and not
committed (saved under the session scratchpad only).

| Skill | Change | Suites run | Result |
|---|---|---|---|
| arithmetic-eval | skill | eval + format | 34/34. tc-ae1..ae4 each made one Mode 1 call equal to SKILL.md's |
| what-if-analysis | skill + test | eval + format | 27/28. Format 14 passes on all six. tc-wi6 still fails on F5 (cliff tag) |
| business-plan-critique-moat | test | eval on 0cb729ed reports | tc-moat1 passes; tc-moat7 still fails on F2 (Confidence trailing prose) |
| tech-debt-triage | skill + test | eval + format | 22/22, after review and one more pattern round (below) |
| yglesias-critique | skill | eval + format + dimensions | ygl4's Boring Lever now has "lever", but see below |

- tech-debt-triage, second round: on the regenerated reports td4 rated Carrying Cost
  Medium (the skill fix took), but its FUL-1187 tie was worded "fold the fix into it" /
  "the natural vehicle is that migration", and td5's stability "none since 2024-03" /
  "The last change was 2024-03-14"; both patterns missed. Same call as F7 (test), each
  new alternative matches only its own report among the six regenerated ones and no
  fixture.
- yglesias-critique, still failing: tc-ygl4's Adoption Survival section now leaves out
  "adoption" (it says "easier to pass"), so format 6 fails on a different keyword; and
  `dimensions.bats` (which reads tc-ygl7) fails because the new tc-ygl7 report omits the
  Cost Disease Check, a section SKILL.md marks "If relevant". Two runs, one slip each in
  ygl4: the body-keyword rule is the fragile part, not the one keyword. Not fixed here:
  see the question below.
- Review round 1 (one general-purpose reviewer): a blocker (the first what-if example
  quoted tc-wi1's planted assumption, source section and graded value), two should-fix
  (unbounded td2 runway; a td rule worded to fit tc-td4) and three nits; all fixed but the
  arithmetic-eval wrapper-wording nit, which would stale the five verified reports for a
  wording gain (the wrapper is matched exactly already, and no run changed it).

## Question for the cycle (tentative pick, Path C)

yglesias-critique asks for a named word in each section body ("lever", "adoption",
"cost disease"...) "so downstream tooling can identify the move"; the only tooling is
its own tests, and the fixed `## ` headings already identify each move. One report in
seven slips on one word per run, so the suite stays red by chance.

| Option | What changes | Cost | If wrong |
|---|---|---|---|
| [1] Keep the rule (pick) | Nothing more; reruns pass or fail by chance | Red health check on some regenerations | Keeps flaking |
| [2] Drop the body-keyword rules | SKILL.md loses 7 "Use the word" lines; format 6 and dimensions checks go; regenerate 7 reports | One brief | Lose a weak sign the move was done |
| [3] Keyword anywhere in the section or a synonym list | Test-only | Small | Check gets close to vacuous |

Tiebreaker for [1]: the brief named only the lever case, which the clarification fixed;
[2] changes the skill's output contract and is a separate decision. Also for the cycle:
`yglesias-critique/dimensions.bats` requires "cost disease" in tc-ygl7 although SKILL.md
lets that section be omitted.

## Gotchas

Failure-pattern grep: no matches found
Failure-pattern skip: the misses are model-output drift against skill wording and fixture-specific eval patterns, not a root-caused code bug with a reusable fix shape.

- A skill text edit makes all of that skill's committed reports stale on
  `measure/regenerate-skill-reports`: arithmetic-eval, what-if-analysis,
  tech-debt-triage and yglesias-critique must be regenerated there before those reports
  land.
