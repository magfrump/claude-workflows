# Research: skill reports put prose after field values and text before the title

Brief: docs/working/briefs/2026-11-20-skill-format-fields-preambles.md (at 697e81ae)
Branch: fix/skill-format-fields-preambles
Date: 2026-11-20

## What I read

- Findings F2 and F3 in `docs/working/research-2026-11-19-regenerate-skill-reports.md` at 0cb729ed, and the reports they fail on (`git checkout 0cb729ed -- test/skills/<skill>/output/` for the seven skills below; restored before every commit).
- The `SKILL.md` output sections of pre-mortem, ai-personas-critique, business-plan-critique-moat, business-plan-critique-market-sizing, security-reviewer, dependency-upgrade and matrix-analysis, and their `-format.bats` / `-eval.bats` suites and `expected-verdicts.bash`.
- Shared helpers: `assert_field_values` and `assert_title_matches` (`test/skills/helpers.bash`), `field_values` / `assert_field` / `assert_no_field` / `run_format_check` (`test/skills/eval-helpers.bash`), `resolve_skill_report` (a stale stamp fails a report, so test-side changes were checked on the 0cb729ed reports before any skill text changed).
- `docs/constraints.md` at 697e81ae.

## Gotchas

Failure-pattern grep: FP-169, FP-175

- FP-169 (prose appended to a parsed date field makes it unparseable; cause delimiter-handling): the same shape as F2. The fix here keeps the value-leads rule structural (an explicit delimiter set) instead of accepting any trailing text.
- FP-175 (`echo | grep -q` SIGPIPE under pipefail): the new checks use here-strings into `awk`/`grep` rather than adding pipes into `grep -q`.

Failure-pattern skip: the fixes are a test delimiter set and skill-text wording, each a one-off spec mismatch covered by FP-169's existing delimiter-handling category; a new entry would restate it.

## Baseline on the 0cb729ed reports

pre-mortem 5 failing (eval tc-pm1, tc-pm4, tc-pm6; format 15, 16), ai-personas-critique 4 (tc-per1, tc-per3, tc-per7; format 19), moat 2 (tc-moat1 is F7, out of scope; tc-moat7), market-sizing 2 (tc-mkt5, tc-mkt6), security-reviewer 3 (tc-sec4, tc-sec8, format title), dependency-upgrade 2 (tc-dep2, tc-dep3), matrix-analysis 5 (tc-ma1..4, format title). Every eval failure here is its `format_check` (the skill's format suite run on that report), except tc-dep2 and tc-dep3, which also fail `field_match:Recommendation`.

## Design choice: tighten the skills or loosen the shared helpers (divergent design)

Candidates:
1. Tighten every affected skill to "value alone on its line", leave the tests.
2. Loosen the shared helpers everywhere, including the exact-match suites (ai-personas, business-plan), to the annotation rule.
3. Split by what each suite's own spec says: where the spec already allows an annotation (`assert_field_values`' documented rule, pre-mortem's glossed labels), fix the test's delimiter set; where the spec is an exact value ("valued one of", `^(...)$` suites), tighten the skill; fix tests that reject a reasonable value (bold-wrapped, singular "hour") and a test that grades the wrong position (matrix-analysis).
4. Status quo (leave 43 cases red): ruled out by Q-328 [3], the owner's "fix first" answer (the regenerated reports land only once the health check is green on them).

Prune against the constraints: 2 fails the motive (S5, value in real use): it would accept "Point to consider for the pilot itself. Significant weakness for the continuation decision" and "Plausible for the beachhead; the national expansion path is unsupported", two values in one field, which defeats the vocabulary for any reader. 1 contradicts pre-mortem's own SKILL.md (it defines the labels with glosses, "Likely (>50%)", and its suite says both forms are spec), costs 15 more regeneration runs (pre-mortem, matrix-analysis) under a memory-limited machine, and cannot fix matrix-analysis at all (the runner prints the chat synthesis first, so no skill text puts the document's title in the first five lines). It also keeps a rule split in two (S3): `assert_field` already reads "Plausible." as Plausible while `assert_field_values` rejected it.

Decision (Path A, candidate 3 dominates): one shared annotation rule, `field_values_off_vocab` in `helpers.bash`, now used by `assert_field_values` and pre-mortem's suite, with `.` added to its delimiter set; exact-value skills tightened.
Falsifier: if the regenerated reports for the tightened skills still carry trailing prose in those fields, the skill text is not enough and candidate 1's premise (text steers the model) is refuted for this field shape.

Other choices, one line each:
- Bold-wrapped values: strip leading emphasis in `field_values` (eval-helpers.bash), so `field_match`, `no_field`, `assert_verdict` and `assert_severity` all read `**Upgrade now.**` as Upgrade now; it also makes the absence checks catch a bold forbidden value, which is stricter, not looser.
- Singular effort: `minutes?|hours?|days?` in dependency-upgrade's format suite; "About an hour" is the template's "hours" in English.
- matrix-analysis: the suite grades Deliverable 2, the matrix document; its title check now finds a `# ...Matrix Analysis` line with the document's `**Items:**` line within four lines after it, wherever the document sits. The Stage 2 banner is SKILL.md's own between-stage chat line, so it is not a defect to remove.
- security-reviewer: the skill had three things placed "at the top" (User goal and Commit, the fact-check warning, the HALT block) and a title rule; the text now orders them under the title. HALT stays before the Trust Boundary Map, which is where its own section put it.
- security-reviewer Confidence "Low. This only matters if...": covered by the shared rule (value-dot-sentence), no skill change.

## Per-case decisions

| Case | What the report did | Wrong side | Change |
|---|---|---|---|
| pre-mortem format 15/16, tc-pm1/4/6 | `**Severity:** Medium. It is recoverable...` | test | `.` in the shared delimiter set |
| ai-personas format 19, tc-per1/3/7 | `**Severity:** Significant weakness. It is fixable...`, split values | skill | Severity line holds one value only |
| moat tc-moat7 | `**Confidence:** Medium-High (...)` | skill | single value, no hedge or parenthetical |
| market-sizing tc-mkt5/6 | `High (on X); Low (on Y)`, `Plausible for the beachhead; ...` | skill | same |
| security tc-sec8 | `**Confidence:** Low. This only matters if...` | test | shared delimiter set |
| security tc-sec4, format title | "Here's the report..." then User goal, Commit, warning before the title | skill | title first, the rest below the header |
| dependency tc-dep2 | `**Upgrade now.**` bold; `About an hour` | test | strip emphasis; singular units |
| dependency tc-dep3 | `**Recommendation:** Don't merge this PR this week.` | skill | Recommendation holds a listed value alone |
| matrix tc-ma1..4, format title | banner and chat synthesis before `# Matrix Analysis` | test | locate the document's title |

## Results

Test-side, on the 0cb729ed reports (before any skill text changed): pre-mortem 23/23, matrix-analysis 22/22, security-reviewer tc-sec8 passes, dependency-upgrade tc-dep2 passes. New hermetic suite `test/skills/field-value-rules.bats` (13 cases); 12 of them fail on the pre-change helpers.

Skill-side, after regenerating each changed skill's fixtures with `test/skills/generate-reports.bash` (one skill at a time, one fixture per call), then its format and eval suites, on the branch with main merged in (2026-11-20, dispatch 2):

| Skill | Cases fixed | Still failing | Notes |
|---|---|---|---|
| pre-mortem | 5 of 5 (test side; reports unchanged from 0cb729ed) | none | 23/23 |
| ai-personas-critique | 4 of 4 | none | 29/29; every Severity line holds one value; tc-per6 is the expected pre-flight stub |
| business-plan-critique-moat | tc-moat7 | none | 25/25; tc-moat1 (F7, out of scope) also passes after main's merge |
| business-plan-critique-market-sizing | 2 of 2 | none | 25/25; Verdict and Confidence hold one value; tc-mkt7 is the expected stub |
| security-reviewer | 3 of 3 | none | 26/26; regenerated again after 5306b42a (the round-1 reports were stale); all 8 reports open with `# Security Review` |
| dependency-upgrade | 2 of 2 | none | 23/23; Recommendation holds a listed value alone in all 6 |
| matrix-analysis | 5 of 5 (test side; reports unchanged) | none | 22/22 |

Falsifier (above) did not fire: no regenerated report of a tightened skill carries prose after a Severity, Verdict, Confidence or Recommendation value. One security-reviewer Confidence line ("Medium. This depends on...", tc-sec7) uses the value-dot-sentence form the shared rule accepts by design.

Reports under `test/skills/*/output/` stay uncommitted (criterion 4); the regeneration branch regenerates these skills after this merges.
