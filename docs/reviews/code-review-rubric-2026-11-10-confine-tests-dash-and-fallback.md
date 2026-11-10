Commit: bd312d15

# Code Review Rubric

**Scope:** `fix/confine-tests-dash-and-fallback`, 23ffb16c..bd312d15 (the whole branch at passes 1 and 2) | **Reviewed:** 2026-11-10 | **Status: 🟢 PASSES** — 0 red; every amber fixed or standing with a note, one of them (A9) an open question for the owner that no change on this branch settles

The file's name ends in the brief's stem, not the branch slug, so the build loop's gate counts it as this brief's own file; passes therefore name their range explicitly. Delivery mode: self-read (each agent read one shared scratch file holding the preamble and the diff, then the files). All agents ran on opus. Reports are in this directory, named `<kind>-2026-11-10-confine-tests-dash-and-fallback.md`.

**Pass 1** (iteration 1 of 3, `--loop-pass`, full branch at de1f4bf9): k=1 fact-check (`code-fact-check-report`): 53 claims; 45 Verified, 6 Mostly accurate, 1 Incorrect, 1 Unverifiable. Critics: security (`security-review`): 3 Informational; performance (`performance-review`): none; API consistency (`api-consistency-review`): 4 Minor, 4 Informational. No short-circuit (no behavioural red). Fixed in bd312d15; the fix-commit drift check over de1f4bf9..bd312d15 reported no findings.

**Pass 2** (iteration 2 of 3, the final confirming pass, full branch at bd312d15, no `--loop-pass`): k=3 fact-check (`code-fact-check-report-final-r1`, `-r2`, `-r3`; merged in `code-fact-check-report-final`, whose M numbers the rows below cite):

| Replicate | Claims | Verified | Mostly accurate | Stale | Incorrect | Unverifiable |
|---|---|---|---|---|---|---|
| r1 | 63 | 52 | 3 | 1 | 6 | 1 |
| r2 | 47 | 38 | 4 | 1 | 3 | 1 |
| r3 | 55 | 45 | 8 | 0 | 2 | 0 |

No replicate found anything wrong in what the script or the tests do. Each ran the 23ffb16c script against the bd312d15 one on the test file's stand-ins (1,924, 4,536 and 1,650 runs) and found every `--probe` byte-identical and the primitive unchanged. Every Incorrect and Stale is in a doc or a commit message, so by the tier rule for a fact-check red (the code is right and only a reader is misinformed) they are 🟡, not 🔴. Critics: security (`security-review-final`): 1 Medium that needs no code change here, 2 Informational; performance (`performance-review-final`): none; API consistency (`api-consistency-review-final`): 2 Minor, 4 Informational. Fixes are in the commit that follows bd312d15.

FC n is pass 1's fact-check claim n; M n a merged cluster of pass 2's; S, P, A a critic's finding, "final" for pass 2's.

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

None.

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note**. A qualifying note
does not just explain the finding — it records where the deferred work will be found
again, so a yellow finding cannot get lost in the codebase: either (a) a **discoverable
TODO** — a `TODO` comment in code at the finding's site, or a tracked follow-up entry
(issue, `docs/working/questions.md` entry, or similar) the note links to — or (b) a
**concrete revisit trigger** — a named, observable condition under which the finding must
be reopened (e.g. "if this handler starts accepting user uploads", "if p99 > 200ms"). A
note with neither ("known, acceptable for now") is not qualifying; the row stays open for
[next-action derivation](chat-synthesis.md#next-action-derivation).

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The shared warning re-wrapped the `--no-loopback` text, so `--no-loopback --probe` with a working bwrap printed the same words with different line breaks on stderr lines 5-7; the brief forbids any change to `--probe`, and commit 6465a156 and the research doc's invariant said there was none. Location: `scripts/confine-tests.sh:126-135`, `:166-168` at de1f4bf9; research doc `:47` | API / Docs | Mostly accurate; Minor | pass 1: FC 22, FC 35; A 2 | for-author | — | 🟢 Fixed in bd312d15: the old line breaks are back (the way back's first words are their own argument), and a test compares the whole warning; pass 2's three replicates found every probe byte-identical to 23ffb16c | The API critic advised keeping the re-wrap and correcting the claim. The brief's line is about behaviour, so the bytes were restored. |
| A2 | The header (`--help`) said `--no-loopback` warns "on a run and on a --probe"; with bwrap missing or unusable a `--no-loopback --probe` prints nothing. Location: `scripts/confine-tests.sh:45-46` at de1f4bf9 | Docs | Mostly accurate; Minor | pass 1: FC 3; A 1 | for-author | — | 🟢 Fixed in bd312d15 | — |
| A3 | The research doc said the repo rules file and decision 018 both cite `scripts/confine-tests.sh:220`; only decision 018 does. | Docs | Incorrect (doc only) | pass 1: FC 33b; A 7 | for-author | — | 🟢 Fixed in bd312d15 | — |
| A4 | Commit d03a3078 says its 7 failing tests fail "each for the reason it names"; the fallback-warning test fails earlier there, on `exec: sh: not found`. | Docs (commit message) | Incorrect (commit message) | pass 1: FC 18; pass 2: M5 | for-author | — | 🟡 Stands: a commit message cannot be edited (the branch may only add commits) | Recorded in the research doc's "Review" section. Revisit trigger: none can arise; the sentence describes one past commit. |
| A5 | Commit 6465a156 says "--probe is unchanged for every input"; at that commit the `--no-loopback --probe` stderr was re-wrapped (A1). | Docs (commit message) | Incorrect (commit message) | pass 1: FC 22; pass 2: M4 | for-author | — | 🟡 Stands (immutable); true of the branch from bd312d15 on | As A4. |
| A6 | DD-1's match table said "`a=b z` ran `z`"; env set the variable and only tried to run `z`. | Docs | Mostly accurate | pass 1: FC 39 | for-author | — | 🟢 Fixed in bd312d15 | — |
| A7 | "238 code lines" (pre-mortem, and commit de1f4bf9's message) includes the guide's 11 lines. | Docs | Mostly accurate | pass 1: FC 45; pass 2: M16 | for-author | — | 🟢 Fixed in the pre-mortem (it now gives both parts); the commit messages stand | Pass 2's r1 notes that by pr-prep's own count (all changed lines outside `docs/`) 238 and 270 are right. |
| A8 | Contested confirmation (pass 1). Certified: "no change ... to exit statuses other than D1's" (FC 25, Verified over 264 runs). Inconsistent observation: on a host where `sh` is dash, an empty command name exited 126 at 23ffb16c and exits 127 now (A 5). | API | Contested | Confirmed-Good cross-check | for-author | — | 🟢 Resolved by narrowing the claim; see A10, which completes it | Revisit trigger: a caller that tells 126 from 127 for a command it could not run. |
| A9 | Constraint H2 (`docs/constraints.md:6`) says a degraded primitive "refuses and names what went unenforced; ... degradation only ever narrows access". When bwrap is unusable the script falls back to unshare, which leaves the real filesystem writable as uid 0, and runs; this branch adds the naming and writes "A weaker primitive is a warning, on every run" into the header. Location: `scripts/confine-tests.sh:29-35`, `:216-232` at bd312d15 | Security | Medium | pass 2: S final 1 (and its pass-1 finding 3, the fallback probe) | for-orchestrator-synthesis | — | 🟡 Open, with a note: no code change on this branch | The behaviour predates the branch, and the brief keeps the run ("this unit adds the warning, it does not turn the fallback into a refusal") and lists a refusal as out of scope. Tracked follow-up: the question to the owner in this branch's ready marker, which the dev cycle files in `docs/working/questions.md` (refuse on fallback, refuse unless asked, or record an exception for the unshare tier; the silent fallback probe goes with it). Revisit trigger: the first session whose `scripts/confine-tests.sh --probe` names a primitive. |
| A10 | The research doc's record of exit statuses was short. Beyond the empty name (A8): where `sh` is dash, a bare name that matches a directory found through PATH went from 126 to 127; where `sh` is bash, `-- CMD` (0, CMD ran) and `-p CMD` (2) go to 127; on a host with no `sh`, every loopback run went from 127 to running. "One status does move" and bd312d15's Notes named only the first. Location: research doc `:47`, `:288-299` at bd312d15 | API / Docs | Incorrect (doc only); Minor | pass 2: M1 (r1 Incorrect, r3 Mostly accurate, r2 as a caveat); A final 1 | for-author | — | 🟢 Fixed: the "Exit statuses" table lists every case and says which are D1 and which its consequences; the invariant line says three statuses move. bd312d15's Notes stand (immutable) | The API critic judged recording the right remedy: keeping dash's 126s would mean resolving the name outside the body, which the design pruned. One split between the two unshare forms remains and is recorded there (C15). |
| A11 | The pre-mortem said its prior-art grep returns four files; it returns 17. Location: pre-mortem `:14` | Docs | Incorrect (doc only) | pass 2: M2 (all three replicates) | for-author | — | 🟢 Fixed: the sentence gives the 17 and says which were read | — |
| A12 | "Prior pruning grep: no matches found" for keywords of which one matches decision 017's pruned-candidates section (`[4 bwrap confine-tests as an in-session gate]`). Location: research doc `:89`, `:185` | Docs | Incorrect (doc only) | pass 2: M3 (r1) | for-author | — | 🟢 Fixed: the matches are named and that candidate is carried forward | — |
| A13 | The test-plan row G4 still named the body's `$0` as `confine-tests`. Location: research doc `:245` | Docs | Stale | pass 2: M6 (r1); A final 6 | for-author | — | 🟢 Fixed | — |
| A14 | Seven loose sentences: "the selection tests are untouched" (M8); "2012 of 2012 pass" without its two skips and the 50 suites not run (M9); a mutant's label and the first survivor's name (M10); the test-number key (M11); the D2 reproduction naming the wrong failing test (M12); "126 for a directory" (M13); "`grep -rn confine-tests` over code finds none" (M14). Locations: research doc `:43`, `:47`, `:67`, `:326`, `:329`, `:343`; pre-mortem `:35` | Docs | Mostly accurate | pass 2: M8-M14 | for-author | — | 🟢 Fixed, each in place | — |
| A15 | H2 paraphrased as "a degraded primitive names what went unenforced", dropping "refuses": commit 6465a156, the brief `:13`, the research doc, and "(H2)" in test 20's name. Location: `test/scripts/confine-tests.bats:476` at bd312d15 | Docs / Test | Mostly accurate; Minor | pass 2: M15 (r3); A final 2 | for-author | — | 🟢 Fixed where this branch may write: the test's name drops "(H2)" and a comment above it quotes H2 and says the run is kept by the brief; the research doc quotes H2 word for word. The commit message and the brief's sentence stand (the brief is the dev cycle's file) | See A9 for the substance. |
| A16 | Commit ca6cf3be says the way back "must now start on the sixth line"; since bd312d15 it starts partway through line 5. | Docs (commit message) | Stale | pass 2: M7 (r2) | for-author | — | 🟡 Stands (immutable) | The research doc's "Mutation run" history says how the comparison changed. Revisit trigger: none can arise. |
| A17 | "the four tests ... that begin `[ "$(id -u)" -ne 0 ] || skip`" and "four tests fewer": one of the four has a statement before the guard, and a fifth test probably skips too under the uid mapping (`test/scripts/build-loop-orchestrator.bats:394`; inferred, not run). | Docs | Unverifiable (stated failure mode: none; coverage only) | pass 2: M17 (r1; r2's annotation) | for-author | — | 🟢 Fixed: "at least four ... a fifth probably"; the count is a follow-up for the first live run | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | With `--no-loopback` and bwrap missing or unusable, the fallback's way back is not enough while the flag stays. | pass 1: S 2 | Informational | for-author | — | Fixed in bd312d15: the way back adds "and drop --no-loopback" (see C11) |
| C2 | "bwrap was refused here": the script's word for a primitive that does not work is "unusable". | pass 1: A 3 | Minor | for-author | — | Fixed in bd312d15 |
| C3 | Errors from the body read `confine-tests: line 6: ...`, where 6 is a line of the body, not of the file. | pass 1: A 4 | Minor | for-author | — | Fixed in bd312d15: the body's `$0` is `confine-tests: unshare body`; pass 2's API critic found it clear |
| C4 | The guide says the probe names the primitive "on its first line". | pass 1: A 6 | Informational | for-author | — | Fixed in bd312d15 |
| C5 | Decision 018 cites `:220`, which is no longer the pattern's line. | pass 1: FC and A escalations | Informational | for-author | — | Fixed within reach: the comment opens "Decision 018's reference pattern"; the citation is a follow-up in the research doc |
| C6 | `"$BASH" -c` sources `BASH_ENV` and imports exported functions; the `sh` it replaces did not. | pass 1: S 1; pass 2: S final 3 | Informational, out of the threat model (S1) | for-author | — | Won't-Fix: only a caller who poisons its own environment reaches it; the outer script is bash already (pass 2 adds that an exported `exec` already replaced the outer script's own at 23ffb16c). Revisit trigger in the pre-mortem (narrative 3). No override-log row: that file is outside this brief's Paths |
| C7 | A fallback `--probe` exits 0 and names only the primitive. | pass 1: S 3 | Informational | for-orchestrator-synthesis | — | Deferred: part of A9's question |
| C8 | That `"$BASH"` starts inside a real `unshare -rn` cannot be shown here. | pass 1: FC 44; pass 2: M18 | Unverifiable | for-orchestrator-synthesis | — | Deferred: a follow-up for the first live run (research doc) |
| C9 | Real bwrap may exit 1, not 126 or 127, when the command cannot be run; the stand-ins hide it. | pass 1: A 8; pass 2: A final 3 (modelled) | Informational | for-orchestrator-synthesis | — | Open: predates the branch; noted under "What a stub cannot show" |
| C10 | The test file's `# @category slow` tag is generous for a 1.4 s file. | pass 1: P | Informational | for-orchestrator-synthesis | — | Won't-Fix here: predates the branch |
| C11 | Only the not-installed route of "and drop --no-loopback" is tested; a copy of the script without `$and_flag` on the unusable route passes 21 of 21. Location: `scripts/confine-tests.sh:224` at bd312d15 | pass 2: S final 2 | Informational | for-author | — | Fixed: test 20 runs that route; two mutants, one per route, each fail a test |
| C12 | The unusable-bwrap warning sends a reader on a CI runner "where bwrap works (a CI runner or a dev host)", and its headline is 101 characters where the script's other lines wrap near 75. Location: `scripts/confine-tests.sh:221-224` at bd312d15 | pass 2: A final 4 | Informational | for-author | — | Fixed: "bwrap is unusable here; falling back to the unshare primitive." and "Run on a host where bwrap works ..." |
| C13 | Test 14's name still says "refused"; the guide's Known-gaps bullet leaves out the `--no-loopback` route to unshare. Location: `test/scripts/confine-tests.bats:367`, `guides/test-hermeticity.md:183-184` at bd312d15 | pass 2: A final 5 | Informational | for-author | — | Fixed |
| C15 | For a bare name that matches a directory on PATH, the loopback form now exits 127 where a real unshare on the `--no-loopback` form would exit 126 (modelled). Location: `scripts/confine-tests.sh:290` at bd312d15 | pass 2: A final 3 | Informational | for-author | — | Won't-Fix: closing it means resolving the name outside the body, which the design pruned; recorded under "Exit statuses" in the research doc |

(There is no C14.)

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.
Every row carries `Evidence` and has passed the Confirmed-Good cross-check — see
[Confirmed Good is a claim, not an output](#confirmed-good-is-a-claim-not-an-output).

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| On the inputs the three replicates built (every bwrap/unshare/ip stand-in setup, each probe form in both flag orders, `sh` as dash, as bash and absent), every `--probe` at bd312d15 is byte-identical to 23ffb16c in stdout, stderr and status. Stand-ins only: nothing ran under a real bwrap or unshare | ✅ Confirmed | `scripts/confine-tests.sh` — `echo "  with EROFS will succeed against the real filesystem. $2" >&2`; merged report, executed table row 1 (r1, r2, r3 executed; scope: those inputs) | code-fact-check ×3 | for-orchestrator-synthesis |
| Test 11 (the whole `--no-loopback` warning) passes against the 23ffb16c script | ✅ Confirmed | `test/scripts/confine-tests.bats` — `[ "$stderr" = "$LO_WARNING_TEXT" ]`; merged report, executed table row 4 | code-fact-check ×3 | for-orchestrator-synthesis |
| At bd312d15 a command named `-record` runs with its arguments, and `-a x CMD one` exits 127 with nothing run, with `sh` linked to bash and to dash (stand-ins) | ✅ Confirmed | `scripts/confine-tests.sh` — `exec -- "$@"' "confine-tests: unshare body" "${cmd[@]}"`; tests 17 and 18 (executed by each replicate), and the three shells run directly | code-fact-check ×3 | for-orchestrator-synthesis |
| The test with a command named `eval` fails when the body ends `"$@"` or `command -- "$@"` (shown on bash 5.2.15) | ✅ Confirmed | `test/scripts/confine-tests.bats` test 19 — `confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- eval 'touch pwned'`; merged report, executed table row 6 | code-fact-check ×3 | for-orchestrator-synthesis |
| At bd312d15 each of the author's 22 mutants fails at least one test, as the research doc's table then listed, and the unchanged script passes 21 of 21 | ✅ Confirmed | merged report, executed table row 5 (the mutation script re-run by each replicate) | code-fact-check ×3 | for-orchestrator-synthesis |
| Each cell of the research doc's Exit-statuses table as it stood at bd312d15 (four commands) | ✅ Confirmed | merged report, executed table row 3; the table was short, see A10 | code-fact-check ×3 | for-orchestrator-synthesis |

Routed by critics and pending a verdict (submitted to the fact-check of pass 3): no word of the command is spliced into the body; a dash-named first word is never read as an option of `exec`, whichever shell `sh` is; every route to unshare warns, and a failed warning stops the run; the stand-ins accept only the exact calls the script makes (security); the test command runs as the script's own pid on the loopback form; the test file's extra time is in proportion to its added tests (performance); the warning comes before the banner on every route (API consistency). Not submitted, because nothing here can run it: the real tools' exit statuses when a command cannot be run (API consistency; see C9).

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

(Contextual critics: none selected on either pass. `tech-debt-triage`'s 500-line trigger is met only by counting the working docs; under 300 lines change outside `docs/`, in three files.)

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/confine-tests.sh:45-46` (pass 1) | FC 3, A 1 | distinct defects: one finding stated in full by both sources |
| 2 | `scripts/confine-tests.sh:126-168`, research doc `:47` (pass 1) | FC 22, FC 35, A 2 | distinct defects: the same re-wrap seen from the code, the commit message and the doc; each fragment states the mechanism |
| 3 | `scripts/confine-tests.sh:268-273` (pass 1) | FC 25 (via A8), A 5, S 1, A 4 | distinct defects: the status change, the environment exposure and the error prefix share a line and have separate mechanisms and fixes |
| 4 | research doc `:47`, `:288-299`; `scripts/confine-tests.sh:290` (pass 2) | M1, A final 1, A final 3 | distinct defects: each fragment states the interpreter swap as the cause; A10 and C15 are its two faces (what the doc omitted; the split that remains) |
| 5 | `scripts/confine-tests.sh:29-35`, `:216-232`; `test/scripts/confine-tests.bats:476` (pass 2) | S final 1, M15, A final 2 | distinct defects: the security finding states the root in full (H2 says "refuses"; the fallback runs; the texts paraphrase); the other two are its wording half |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

Tokens (agents' reported totals): pass 1: fact-check 210k, security 126k, performance 101k, API consistency 138k, about 575k. Pass 2: fact-check 257k, 251k and 254k, security 141k, performance 102k, API consistency 169k, about 1,174k.
