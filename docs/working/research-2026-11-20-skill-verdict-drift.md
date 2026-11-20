# Research: verdict and severity drift in six skills' fresh reports (F5)

Brief: docs/working/briefs/2026-11-20-skill-verdict-drift.md (at 697e81ae)
Branch: fix/skill-verdict-drift
Date: 2026-11-20

Failure-pattern grep: `rg -n '^- \*\*FP-' docs/failure-patterns.md | rg -i 'fixture|expected verdict|eval|leak|noise|severity'` -> FP-035 and FP-059 (an evaluator guard and an AST evaluator; neither is about a skill fixture's expected verdict). No entry covers a fixture whose planted verdict is wrong, so nothing changes the plan.
Failure-pattern skip: the fix commits correct test fixtures, expectations and two skill rubrics whose drift was found by a measurement run; no shipped guard failed open or missed its subject, so no failure pattern earns an entry.

## What I read

- The F5 finding in `docs/working/research-2026-11-19-regenerate-skill-reports.md` at 0cb729ed, and that branch's reports for the six skills (`git checkout 0cb729ed -- test/skills/<skill>/output/`, kept out of every commit).
- Each affected `skills/<skill>/SKILL.md` (severity, verdict and tag rules), the fixtures, `expected-verdicts.bash`, `eval-criteria.md`, the eval and format suites, and `eval-helpers.bash` / `helpers.bash` (how `finding_match`, `cites_pattern`, `no_pattern` and the Recommendation count read a report).
- `docs/constraints.md` at 697e81ae. The binding ones here: H3 (the suites stay hermetic; model runs are the measurement, not the test), S3 (reuse architecture-review's Informational exemption rather than invent a second rule), S8 (ui-visual-review's SKILL.md is already 516 lines: grow it by two lines at most).

## Ledger (model runs)

Stop line about 40. Used: **33** (run 1: 10 reruns of the ten cases; run 2: 9 after the first fixes; run 3: 5 second samples; runs 3-8: 6 of tc-ts6 across three fixture rounds; runs 9-10: 3 of tc-uv1/uv2 after the Recommendation rule). Every run exited 0 and wrote no `.failed` marker.

| Case | 0cb729ed | Rerun (run 1) | After fix | Second sample | Call |
|---|---|---|---|---|---|
| code-fact-check tc-c2.5 | Incorrect | Incorrect | Unverifiable (pass) | pass | fixture wrong: fixed |
| architecture-review tc-arch6 | Structural, Coupling | Coupling x2 | Minor/Informational only (pass) | pass | fixture wrong: fixed |
| architecture-review tc-arch7 | skip note, title `: Skipped` | skip note, bold trigger labels | test fixed; both old reports pass | - | test wrong: fixed |
| test-strategy tc-ts6 (priority, unknown unit) | high x3 | high x2 | final fixture: pass, pass (runs 7-8) | - | fixture wrong: fixed in three rounds |
| test-strategy tc-ts6 (N tests, fewer "What it verifies") | fail | pass | pass in runs 2-4, 6-8; fail in run 5 | - | intermittent, 2 of 9: not fixed |
| ui-visual-review tc-uv1 / uv2 | Major / Major | Major / Major | Critical / Critical (pass) | uv1 x3, uv2 x2: pass | skill text wrong: fixed |
| ui-visual-review tc-uv6 / uv7 | Major / Critical+Major | Major / Critical+Major | Major / Major (pass) | - | expectation wrong: fixed |
| ui-visual-review format 16 (Recommendation) | uv1 lacks one (Informational) | uv6 lacks one (Informational) | run 3 uv1 lacks one on a Minor | runs 9-10: pass x2 | both sides: test exempts Informational, skill says the rest is required |
| what-if-analysis tc-wi6 (cliff) | 3 cliff tags | 1 cliff tag | no cliff tag | no cliff tag ("the gradient is flat") | skill text wrong: fixed; case stays red on F6 |
| divergent-design tc-dd1 | `recommend [5] PG job library` | `recommend [7] PG queue (library)` | both old reports pass | - | test wrong: fixed |

## Calls, case by case

### code-fact-check tc-c2.5 (fixture wrong)

The fixture's comment was `# thread-safe due to GIL` over a class that uses `queue.Queue` and an explicit `threading.Lock`. Both runs said Incorrect, and they are right by the skill's own rules: the mechanism is refuted (the locks, not the GIL, give the safety), and `process()` has a real check-then-act race (`empty()` then a blocking `get()`), so a concurrent caller can hang. SKILL.md reserves Unverifiable for claims that need "external system access, production state, or domain expertise", and this one needed none. The 0cb729ed report even noted that the fixture's header said "Unverifiable verdict" and overrode it with evidence.

Fix: a new fixture whose one concurrency claim rests on a compiled dependency (`ringbuf.SpscRing`) that is not in the repo, so neither static reading nor the runner's Read/Grep/Glob tools can confirm it. The new file also drops the header comment that named the expected verdict (the generator keeps fixture names from the model for the same reason). Run 2: two claims Unverifiable, one Verified (the comment that the module is not in the repo). Pass.

### architecture-review tc-arch6 (fixture wrong)

Meant to be clean ports and adapters. Both runs found the same two real defects: nothing ever set `sent = 1`, so every run re-sent every pending reminder, and `Reminder` had no id to mark (Structural/Coupling: a business rule living only in SQL); and `due_at` had no timezone contract while `SystemClock` returned aware UTC (Coupling). A reviewer would raise both.

Fix: `Reminder` gets an `id` and an aware-UTC check, the port becomes `ReminderStore` with `mark_sent`, the use case calls it after a send (the port's docstring states at-least-once delivery), and the SQL adapter stores UTC text with an offset. Run 2: five findings, all Minor or Informational, format suite green. Pass.

### architecture-review tc-arch7 (test wrong)

The skill takes the skip path every time; the suite failed because it did not recognise the note. The 0cb729ed report titled it `# Architecture Review: Skipped`; the rerun used the template's dash but bolded the trigger labels (`- **Module structure: no.**`). Either way the format suite read the note as a full critique and then failed the Dependency Map, Findings and other full-report sections. The content was right both times, and no script reads the skip note's exact title (the code-review orchestrator's rubric has its own Skipped section), so the format check was stricter than the contract needs.

Fix: `architecture-review-format.bats` accepts `—`, `–`, `-` or `:` before `Skipped`, and optional bold around a trigger label. Both old reports now pass `tc-arch7`.

### test-strategy tc-ts6 (fixture wrong; format part noise)

Expected: no high-priority gap, and the unknown-unit branch not listed as a gap. Both runs found real untested holes, each rated high under SKILL.md step 5 ("high blast radius, no existing coverage"): a digit run past Python's int-parsing limit raised a bare `ValueError` instead of `DurationError`; `\d` accepted non-ASCII digits; non-`str` input from a YAML/TOML loader raised `AttributeError`; leading-sign and trailing-digit typos (`-5m`, `1h30`) had no rows. The run-1 report also listed the unknown-unit branch as partly covered, because the tests matched only the message prefix. eval-criteria.md predicted this check would move on the first real run and said to decide whether the check or the reading was wrong; here the fixture was wrong, since its claim that "nothing in ts6 meets both" was false.

Fix, in three rounds, each driven by what the last run found (every high it reported was a real hole, including two the repairs themselves introduced):
1. Non-`str` input raises `DurationError`; `[0-9]` replaces `\d`; messages are asserted exactly (`re.escape`); rows pin leading and trailing junk, non-ASCII digits, any unit order, zero components, and non-adjacent and case-folded duplicates. This round capped the regex at `{1,7}` digits, which landed on `MAX_SECONDS`'s seven digits; run 2 rated that boundary high.
2. The regex cap became a length check before `int()`, with rows for the s-unit limit (`2592000s` / `2592001s`) and for which error wins when there are two. Runs 3-4 had no high but each named the length guard's precedence against the unknown-unit check (tripping the unknown-unit pattern); runs 5-6 then found that a zero-padded amount was rejected ("high").
3. The guard counts significant digits, raises its own "amount too long" message (so a 12-digit row and a 13-digit row tell it apart from "exceeds"), its precedence is pinned, and the docstring says positions refer to the stripped, lowercased text, with rows for that and for an uppercase unknown unit. Runs 7 and 8: pass, top priority medium.

A local probe runs every table row against the parser (47 rows, all as asserted). The check itself was not loosened: each time it fired, the fixture had the hole it named.

The "N recommended tests but fewer What it verifies fields" failure is not noise: it failed at 0cb729ed and in run 5, and passed in the other seven runs. It is a format slip (the model drops the field on table-row additions), not a verdict, so it is left for a follow-up and listed in the marker.

### ui-visual-review tc-uv1 / tc-uv2 (skill text wrong)

Both fixtures plant a primary action that growing content pushes out of view (an unbounded list above "Add Item"; a submit button inside the scroll container). All four runs rated it Major, reasoning that the page or the container still scrolls, so the button is "accessible but hard to discover" (Major) rather than "inaccessible or invisible at common viewport sizes" (Critical). The skill contradicts itself here: Step 2 item 2 says such controls "scroll away and become inaccessible", and its viewport checklist says every action button must be visible without scrolling at 1366x768, but the Critical tier did not say whether "reachable by scrolling" counts. The eval and Step 2 both say Critical; only the generic tier wording was read the other way. Path A: fix the skill.

Fix: two lines in the Critical tier: a primary action that growing content pushes out of view (Step 2 items 1-2) is Critical even when scrolling would reach it. Run 2: both Critical with the docked or capped fix. Pass.

### ui-visual-review tc-uv6 / tc-uv7 (expectation wrong)

Expected Minor. SKILL.md's tiers put "affordance is weak" and "hard to discover or use" at Major, and Minor at "cosmetic issues or suboptimal patterns that work". A run button that disappears for good (uv6) and a clickable `div` that looks like text (uv7) are both Major by those words, and all four runs said so (uv7 also raised the keyboard lockout as Critical, also right by the rubric). The eval's Minor is the side that disagrees with the skill's rules, and nothing in SKILL.md calls either pattern Minor.

Fix: `expected-verdicts.bash` expects Major for both (same fix patterns), the eval titles and eval-criteria.md say Major with the reason. Both old reports and run 2 pass.

### ui-visual-review format 16, Recommendation line (both sides)

The finding that lacked a `**Recommendation:**` line in the 0cb729ed uv1 report and the run-1 uv6 report was Informational (a hardening note whose remedy sits in its prose). architecture-review's format suite already exempts Informational findings for this reason, and S3 says reuse that rule, so the UV format suite now counts Recommendation lines against the non-Informational findings. But run 3's uv1 report dropped one on a Minor, and two old reports the suite does not grade did the same (uv4 run 0, a Minor; uv7 run 0, a Major). So the skill also slipped: its template showed the field but never said it was required. Fix: one sentence at the template saying every field is required and only an Informational finding may leave out Recommendation, which states the test's rule in the skill. Runs 9 and 10 of uv1: pass.

### what-if-analysis tc-wi6 (skill text wrong; the case stays red on F6)

A flag-guarded HTTP client swap with a rehearsed rollback, expected to have no `[REVERSIBILITY CLIFF]`. The runs tagged as cliffs: the rollback's own handshake burst at 100%, quotes already issued under a bug, SLOs that may later tighten, and the removal change the proposal already schedules as its own reviewed change. None of these makes undoing the change itself harder: they are the rollback's one-off cost, harm done while the change ran (a consequence chain), and a later step the proposal owns. SKILL.md defined a cliff only as "a point where reversal suddenly becomes much harder", which left all of them in.

Fix: one paragraph in move 6 of `skills/what-if-analysis/SKILL.md` saying what a cliff is (undoing needs a migration, a rewrite or another party's work) and naming the three things that are not. Run 2: no cliff tag on wi6, and tc-wi4 (overwritten bcrypt hashes, a real cliff) still tags one. Both cases stay red only on F6 (`**Assumption:**` entries missing, format 14), which is another brief's finding.

### divergent-design tc-dd1 (test wrong)

Both runs recommend the Postgres `SKIP LOCKED` queue, the only option that survives the fixture's constraints, and print the workflow's banner shape. The banner's short name was "PG job library" and "PG queue (library)", and the check's alternation knew `postgres`, `skip locked` and `database-backed` but not the standard abbreviation. Fix: add `\bpg\b` to the alternation (the word boundary keeps `pg_cron` out). Both old reports pass, and tc-dd2-dd5 still pass.

## Design choices

- **ui-visual-review SKILL.md size:** it was 516 lines and is now 519 (three added lines: two in the Critical tier, one at the template). S8 forbids growth only for `cc-isolated.sh` and `install.sh`; a skill whose rules were ambiguous needed the words.
- **tc-uv1/uv2: three options** (a skill tier clarification, an expectation change to Major, or fixtures with a clipping parent). Path A on the skill clarification: Step 2 and the viewport checklist already say Critical, so only the tier text disagreed. Changing the expectation would have encoded a reading the skill's own checklist rejects; a clipping parent would test a different bug than the one Step 2 names.
- One-line notes for the rest: fixture repair over expectation change for c2.5, arch6 and ts6, since in each the model's finding was a real defect in the fixture; test loosening for arch7 and dd1, since the reports met the contract in substance and no consumer parses the exact form; reuse of architecture-review's Informational exemption for format 16 (S3).

## Consequences for the other briefs

- uv6 and uv7 were last generated before the template sentence (run 2); their pass is on the earlier skill text. The template sentence changes no verdict, so I did not spend runs on them.
- Changing `skills/ui-visual-review/SKILL.md` and `skills/what-if-analysis/SKILL.md` changes those skills' stamps (`report_stamp` hashes the skill directory), so every report for those two skills on `measure/regenerate-skill-reports` reads as stale once this lands. The regeneration branch must regenerate both skills whole before it merges. The same holds per fixture for c2.5, arch6 and ts6.
- Most fixtures still carry a header naming their expected verdict (`# Test fixture for TC-C2.4: Incorrect verdict`, `// Expected finding: Critical`). In this set it did not decide a verdict (the c2.5 run noticed it and overrode it), but it is the same leak the generator keeps filenames out to prevent. Only the rewritten c2.5 drops it; a sweep is its own change.
