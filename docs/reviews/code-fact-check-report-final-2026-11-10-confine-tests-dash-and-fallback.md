Commit: bd312d15

# Code Fact-Check Report (merged, final confirming pass)

**Repository:** claude-workflows (worktree of `fix/confine-tests-dash-and-fallback`)
**Scope:** 23ffb16c..bd312d15, the whole branch
**Commit:** bd312d15
**Replication:** k=3
**Checked:** 2026-11-10

This file is the orchestrator's collation of three replicate reports, most severe verdict wins, annotations by union. It adds no verdict or evidence of its own. It is a condensed merge: the replicates numbered 47, 55 and 63 claims differently, so the full per-claim sections stay in their reports (`code-fact-check-report-final-r1-`, `-r2-`, `-r3-2026-11-10-confine-tests-dash-and-fallback.md`) and this file carries every cluster on which any replicate's verdict was other than a clean Verified, every annotation that names a risk, the escalations, and the stability count. Clusters not listed here were Verified by every replicate that surfaced them, with no caveat.

## Clusters requiring attention

| # | Claim (location) | Merged verdict | Replicate verdicts | Evidence carried from the winning replicate | Replicate annotations |
|---|---|---|---|---|---|
| M1 | "One status does move outside the dash-named cases" and "Every other input the review compared ... exits as before" (research doc `:47`, `:299`; bd312d15's Notes) | Incorrect (doc) | r1=Incorrect · r2=Verified · r3=Mostly accurate | r1, executed (1,924 old-against-new runs): where `sh` is dash, a bare name that matches a directory found through PATH exited 126 (`sh: 6: exec: adir: Permission denied`) and exits 127 now (`confine-tests: unshare body: line 6: exec: adir: not found`); bash's PATH search skips directories. Recorded nowhere on the branch. | r2: "with `sh` as bash, two more dash-named inputs change status and are not in the Exit-statuses table: `-- -- CMD` 0 (CMD ran) becomes 127; `-- -p CMD` 2 becomes 127. Both are D1's class." · r3: "A non-executable file stays at 126 under both"; the sentence at `:299` is true as worded because pass 1's probe passed its directory as a path. · r1: a directory given as a path stays 126. |
| M2 | The prior-art grep "returns decision 017, the two earlier confine-tests research docs and this unit's own" (pre-mortem `:14`) | Incorrect (doc) | r1=Incorrect · r2=Incorrect · r3=Incorrect | executed: the quoted grep returns 17 files at de1f4bf9, among them decision 019, both confine-tests briefs and five cycle logs | r2: "'the others are new' rests on a result the grep does not give" |
| M3 | "Prior pruning grep: no matches found for [exec, argv, dash, unshare, confine]" (research doc `:89`, `:185`) | Incorrect (doc) | r1=Incorrect · r2=— · r3=— · single-replicate detection | r1: decision 017's Pruned candidates section matches "confine" (`[4 bwrap confine-tests as an in-session gate]`) | r1: "The conclusion, that nothing there is about how a body execs its arguments, still holds" |
| M4 | Commit 6465a156: "--probe is unchanged for every input" | Incorrect (commit message) | r1=Incorrect · r2=Incorrect · r3=Incorrect | executed: bd312d15's test 11 fails against the 6465a156 script; `--no-loopback --probe` stderr lines 5-7 were re-wrapped there | all: already on record (rubric A5, research doc "Review", bd312d15's body); true from bd312d15 on |
| M5 | Commit d03a3078: "7 of the 21 fail at this commit, each for the reason it names" | Incorrect (commit message) | r1=Incorrect · r2=Incorrect · r3=Mostly accurate | executed: test 20 fails there on status 127 from `exec: sh: not found`, before any warning assertion | all: already on record (rubric A4); the count of 7 is right |
| M6 | G4: the unshare call's argv is "`-rn -- <the script's bash> -c BODY confine-tests CMD...`" (research doc `:245`) | Stale | r1=Stale · r2=— · r3=— · single-replicate detection | since bd312d15 the body's `$0` is `confine-tests: unshare body` | none |
| M7 | Commit ca6cf3be: "Each route's way back ... must now start on the sixth line" | Stale (commit message) | r1=— · r2=Stale · r3=— · single-replicate detection | true at ca6cf3be; since bd312d15 the way back starts partway through line 5 | r2: the research doc's "Mutation run" records the change |
| M8 | "the selection tests are untouched" (research doc `:47`) | Mostly accurate | r1=Mostly accurate · r2=— · r3=Mostly accurate | tests 11 and 14 were edited to add stderr checks; their status, verdict and call-count assertions are unchanged | none |
| M9 | "`scripts/run-tests.sh` ... exit 0: 2012 of 2012 pass" (research doc `:343`) | Mostly accurate | r1=Mostly accurate · r2=Mostly accurate · r3=Verified | `suite-1.txt`: 2012 `ok` lines of which 2 are skips (`ok 1190`, `ok 1191`), and 50 report-dependent suites listed NOT RUN | r1: "'Serial' is not recorded in the files" |
| M10 | The mutant labelled "the `--no-loopback` warning re-wrapped (the first version's line breaks)" (research doc `:326`) | Mostly accurate | r1=Verified (loosely named: m13, m16) · r2=Mostly accurate · r3=Mostly accurate | m20 rebuilds only the break after "filesystem."; the de1f4bf9 version also wrapped the later lines differently | r2, r3: the first mutation run's survivor was not saved as code; its logged name is "the shared text differs on the fallback route", not "extra line" |
| M11 | The test-number key: "11 and 12 are the `--no-loopback` tests" (research doc `:329`) | Mostly accurate | r1=— · r2=— · r3=Mostly accurate · single-replicate detection | test 13 (the `--no-loopback` refusal) is one too | none |
| M12 | D2 reproduction: "by this unit's new test failing at 23ffb16c" (research doc `:43`) | Mostly accurate | r1=— · r2=— · r3=Mostly accurate · single-replicate detection | at 23ffb16c test 20 fails on status 127 (no `sh` on the built PATH); test 15 is the one that fails on the missing warning | none |
| M13 | "126 for a directory" (research doc `:67`) | Mostly accurate | r1=Mostly accurate · r2=— · r3=— · single-replicate detection | true for a directory given as a path; one found through PATH exits 127 | none |
| M14 | "`grep -rn confine-tests` over code finds none" (pre-mortem `:35`) | Mostly accurate | r1=— · r2=Mostly accurate · r3=— · single-replicate detection | no caller exists; the grep does find a comment at `test/fixture-hermeticity.bats:15` | none |
| M15 | "H2 ...: a degraded primitive names what went unenforced" (commit 6465a156; the brief `:13`; the research doc; test 20's "(H2)") | Mostly accurate | r1=— · r2=— · r3=Mostly accurate · single-replicate detection | `docs/constraints.md:6` says a degraded primitive "refuses and names what went unenforced"; the paraphrase drops "refuses", which this fallback by design does not do | none |
| M16 | "238 code lines" (commit de1f4bf9), "270 code lines" (bd312d15) | Mostly accurate | r1=Verified · r2=Mostly accurate · r3=Mostly accurate | the totals include the guide's 11 markdown lines | r1: "By pr-prep's own count (`workflows/pr-prep.md:86-91`) the figure is right" (all changed lines outside `docs/`) |
| M17 | "the four tests ... that begin `[ "$(id -u)" -ne 0 ] || skip`"; "four tests fewer" (research doc `:370`; pre-mortem `:22`) | Unverifiable | r1=Unverifiable · r2=Verified · r3=Verified | r1: a fifth test probably also skips under the uid mapping (`test/scripts/build-loop-orchestrator.bats:394`; inferred, not run); confirming needs a real `unshare -rn` | r2: "`test/install-host.bats:680` does not *begin* with the uid guard: `need_script;` comes first" |
| M18 | That `"$BASH"` starts under a real `unshare -rn` (research doc `:264`, `:365`) | Unverifiable | r1=Unverifiable · r2=Unverifiable · r3=Verified (as "remains unobserved") | needs one confined run on a host where unshare works; the probe exits 3 here | r3: that `unshare -r` makes the tests uid 0 is likewise unobserved |

## Verified by execution in all three replicates (the claims that carry the most weight)

| Claim | Replicate verdicts | Scope |
|---|---|---|
| The `--no-loopback` warning is byte for byte what it was; no `--probe` prints anything it did not print before (`scripts/confine-tests.sh`, the `warn_unshare_only` comment) | r1=Verified · r2=Verified · r3=Verified | executed: 1,924, 4,536 and 1,650 old-against-new runs on the test file's stand-ins, `sh` as dash, as bash and absent; every probe byte-identical in stdout, stderr and status. Does not establish behaviour under a real bwrap or unshare. |
| Every run that does not fall back to unshare is identical, and the primitive chosen never changes | r1=Verified · r2=Verified · r3=Verified | executed, same runs |
| Every cell of the research doc's Exit-statuses table | r1=Verified · r2=Verified · r3=Verified | executed; the table omits the cases in M1 |
| Test 11 passes against the 23ffb16c script | r1=Verified · r2=Verified · r3=Verified | executed |
| 22 of 22 mutants fail at least one test, each row's failing tests as the table lists; the control passes 21 of 21 | r1=Verified · r2=Verified · r3=Verified | executed (the mutation script re-run by each); labels loose for m13, m16, m20 (M10) |
| The eval test fails for a body ending `"$@"` or `command -- "$@"`; `same_process` cannot see that exec | r1=Verified · r2=Verified · r3=Verified | executed; r3: "shown only on bash 5.2.15. It depends on bash running the last command of a `-c` string in place" |
| "bash's exec takes options and needs the `--`, dash's takes none and would run `--` as the command" | r1=Verified · r2=Verified · r3=Verified | executed in the three shells |
| Bash's errors from the body read `confine-tests: unshare body: line 6: ...` | r1=Verified · r2=Verified · r3=Verified | executed |
| `bash -c` sources `BASH_ENV`; dash and bash started as `sh` do not | r1=Verified · r2=Verified · r3=Verified | executed; r3: out of scope under S1 (a caller who poisons its own environment) |
| Gates: the probe exits 3; the test file passes 21 of 21; the hermeticity lint checks 143 files and exits 0; shellcheck exits 0 | r1=Verified · r2=Verified · r3=Verified | executed |
| Per-commit counts: d03a3078 fails 7; bd657ce8 passes 19 of 21; 6465a156, 7ecf6ee3, ca6cf3be, de1f4bf9 pass 21 of 21 | r1=Verified · r2=Verified · r3=Verified | executed (each commit's test file against its own script) |

## Escalations

| # | Escalation | Raised by | Addressee | Routed |
|---|---|---|---|---|
| E1 | The directory-through-PATH change from 126 to 127 on hosts where `sh` is dash is a second exit-status change outside the dash-named cases and should be recorded beside the empty-name one (`scripts/confine-tests.sh`, the body's `exec -- "$@"`) | r1, r3 | api-consistency | yes: in the critic brief |
| E2 | `-- -- CMD` (0 to 127) and `-- -p CMD` (2 to 127) on hosts where `sh` is bash are not in the Exit-statuses table | r2 | api-consistency | yes: in the critic brief |
| E3 | The pre-mortem's prior-art sentence is a new Incorrect | r2 | orchestrator | yes: rubric |
| E4 | A possible fifth skip under the uid mapping, for the first live run's follow-up | r1 | orchestrator | yes: rubric and research doc follow-ups |

## Verdict stability

18 clusters carried a verdict other than a clean Verified from at least one replicate:

- all three replicates agreed on 2 (M2, M4);
- the two replicates that surfaced it agreed on 1 (M8);
- verdicts differed on 7 (M1, M5, M9, M10, M16, M17, M18);
- 8 were single-replicate detections (M3, M6, M7, M11, M12, M13, M14, M15).

The 11 executed claims in the table above were Verified by all three. No disagreement touches behaviour: every differing verdict is about how exactly a doc sentence or a commit message is worded, or (M17, M18) about what cannot be run here.

Replicate totals: r1 63 claims (52 Verified, 3 Mostly accurate, 1 Stale, 6 Incorrect, 1 Unverifiable); r2 47 (38, 4, 1, 3, 1); r3 55 (45, 8, 0, 2, 0).
