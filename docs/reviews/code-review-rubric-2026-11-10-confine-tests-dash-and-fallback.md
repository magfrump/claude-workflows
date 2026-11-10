Commit: de1f4bf9

# Code Review Rubric

**Scope:** `fix/confine-tests-dash-and-fallback`, 23ffb16c..de1f4bf9 (the whole branch; pass 1 of the review-fix loop, `--loop-pass`) | **Reviewed:** 2026-11-10 | **Status: 🟢 PASSES this pass** — 0 red; 8 amber, all fixed or carrying a note; the final confirming pass is still to run

Pass 1 (iteration 1 of 3), full scope: one fact-check (k=1, decision 031), then security, performance and API-consistency critics in parallel. No short-circuit: the fact-check found no behavioural red. Stage 2.5 (endorsement-claim verification) is skipped on a loop pass; three routed claims are pending the final pass. Fixes are in the commit that adds this file.

Reports: `code-fact-check-report-`, `security-review-`, `performance-review-`, `api-consistency-review-`, each ending `2026-11-10-confine-tests-dash-and-fallback.md`, in this directory. FC n is the fact-check's claim n; S n, P, A n are the security, performance and API critics' findings.

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
| A1 | The shared warning re-wrapped the `--no-loopback` text, so `--no-loopback --probe` with a working bwrap printed the same words with different line breaks on stderr lines 5-7; the brief forbids any change to `--probe`, and commit 6465a156 and the research doc's invariant said there was none. Location: `scripts/confine-tests.sh:126-135`, `:166-168` at de1f4bf9; research doc `:47` | API / Docs | Mostly accurate; Minor | FC 22, FC 35; API 2 | for-author | — | 🟢 Fixed in code: the old line breaks are back (the way back's first words are their own argument), and a test compares the whole warning; it passes against the 23ffb16c script too | The API critic advised keeping the re-wrap and correcting the claim. The brief's line is about behaviour, so the bytes were restored. |
| A2 | The header (`--help`) said `--no-loopback` warns "on a run and on a --probe"; with bwrap missing or unusable a `--no-loopback --probe` prints nothing. Location: `scripts/confine-tests.sh:45-46` | Docs | Mostly accurate; Minor | FC 3; API 1 | for-author | — | 🟢 Fixed: "Where bwrap works, ..." and a sentence for where it does not | — |
| A3 | The research doc said the repo rules file and decision 018 both cite `scripts/confine-tests.sh:220`; only decision 018 does. Location: research doc `:22`, `:265` | Docs | Incorrect (doc only) | FC 33b; API 7 | for-author | — | 🟢 Fixed in both places | — |
| A4 | Commit d03a3078 says its 7 failing tests fail "each for the reason it names"; the fallback-warning test fails earlier there, on `exec: sh: not found`. | Docs (commit message) | Mostly accurate | FC 18 | for-author | — | 🟡 Stands: a commit message cannot be edited (the branch may only add commits) | Recorded in the research doc's "Review" section, which is where a reader of this branch's history is sent. Revisit trigger: none can arise; the sentence describes one past commit. |
| A5 | Commit 6465a156 says "--probe is unchanged for every input"; at that commit the `--no-loopback --probe` stderr was re-wrapped (A1). | Docs (commit message) | Mostly accurate | FC 22 | for-author | — | 🟡 Stands (immutable); true of the branch from the fix commit on | As A4; the research doc's "Review" section says which commit the sentence is true of. |
| A6 | DD-1's match table said "`a=b z` ran `z`"; env set the variable and only tried to run `z`. Location: research doc `:122` | Docs | Mostly accurate | FC 39 | for-author | — | 🟢 Fixed | — |
| A7 | "238 code lines" (pre-mortem, and commit de1f4bf9's message) includes the guide's 11 lines; script and test come to 227. Location: pre-mortem `:12` | Docs | Mostly accurate | FC 45 | for-author | — | 🟢 Fixed in the pre-mortem; the commit message stands (immutable) | — |
| A8 | Contested confirmation. Certified: "no change ... to exit statuses other than D1's" (FC 25, Verified over 264 old-against-new runs). Inconsistent observation: on a host where `sh` is dash, an empty command name exited 126 at 23ffb16c and exits 127 now (API 5: `exec -- "$@"' confine-tests "${cmd[@]}"`, `scripts/confine-tests.sh:273`; the fact-check's argument sets held no empty name). | API | Contested | Confirmed-Good cross-check | for-author | — | 🟢 Resolved by narrowing the claim: the research doc's "Exit statuses" table states the fourth case and why it is counted as D1's consequence | It goes in the marker for the cycle. Revisit trigger: a caller that tells 126 from 127 for a command it could not run. |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | With `--no-loopback` and bwrap missing or unusable, the fallback's way back ("Install bwrap ...", "Run where bwrap works ...") is not enough while the flag stays. `scripts/confine-tests.sh:208-212` | S 2 | Informational | for-author | — | Fixed: the way back adds "and drop --no-loopback"; a test and a mutant pin it |
| C2 | "bwrap was refused here": the script's word for a primitive that does not work is "unusable"; "refuse" is its word for its own refusals. `scripts/confine-tests.sh:210` | A 3 | Minor | for-author | — | Fixed: "bwrap is installed but unusable here"; header and guide follow |
| C3 | Errors from the body read `confine-tests: line 6: ...`, where 6 is a line of the body, not of the file. `scripts/confine-tests.sh:268-273` | A 4 | Minor | for-author | — | Fixed: the body's `$0` is `confine-tests: unshare body` |
| C4 | The guide says the probe names the primitive "on its first line"; with `2>&1` a `--no-loopback` probe's first line is the warning. `guides/test-hermeticity.md:62` | A 6 | Informational | for-author | — | Fixed: "the first line of its stdout" |
| C5 | Decision 018 cites `:220`, which is no longer the pattern's line; the record is outside the branch's reach. | FC escalation; A (escalation) | Informational | for-author | — | Fixed within reach: the comment opens "Decision 018's reference pattern"; the citation itself is a follow-up in the research doc |
| C6 | `"$BASH" -c` sources `BASH_ENV` and imports exported functions (one named `ip` or `exec` would act in the body); the `sh` it replaces did not. `scripts/confine-tests.sh:268-273` | S 1 | Informational, out of the threat model (S1) | for-author | — | Won't-Fix: only a caller who poisons its own environment reaches it, and the outer script is bash already. Revisit trigger in the pre-mortem (narrative 3). No override-log row: that file is outside this brief's Paths |
| C7 | A fallback `--probe` exits 0 and names only the primitive; constraint H2 may be read to cover it. `scripts/confine-tests.sh:190-194` | S 3 | Informational | for-orchestrator-synthesis | — | Deferred: the brief keeps `--probe` unchanged; recorded under "Observations for the cycle" in the research doc and in the marker |
| C8 | That `"$BASH"` starts inside a real `unshare -rn` cannot be shown here. Research doc `:264` | FC 44 | Unverifiable | for-orchestrator-synthesis | — | Deferred: a follow-up for the first live run (research doc) |
| C9 | Real bwrap may exit 1, not 126 or 127, when the command cannot be run; the stand-ins hide it. `scripts/confine-tests.sh:240-251` | A 8 | Informational, low confidence | for-orchestrator-synthesis | — | Open: predates the branch; noted under "What a stub cannot show" |
| C10 | The test file's `# @category slow` tag is generous for a 1.4 s file. | P (out-of-scope note) | Informational | for-orchestrator-synthesis | — | Won't-Fix here: predates the branch |

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
| At de1f4bf9, a command named `-record` runs with its arguments and `-a x CMD one` exits 127 with nothing run, with `sh` linked to bash and to dash (stand-ins; not a real namespace) | ✅ Confirmed | `scripts/confine-tests.sh:273` — `exec -- "$@"' confine-tests "${cmd[@]}"`; FC 7 and FC 14 (executed: tests 17 and 18, and the three shells run directly) | code-fact-check | for-orchestrator-synthesis |
| The test with a command named `eval` fails when the body ends `"$@"` or `command -- "$@"` | ✅ Confirmed | `test/scripts/confine-tests.bats` test 19 — `confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- eval 'touch pwned'`; FC 12 (executed: both mutants) | code-fact-check | for-orchestrator-synthesis |
| At de1f4bf9 each of the author's 19 mutants fails at least one test, and the earlier survivor passes the test file of 7ecf6ee3 | ✅ Confirmed | FC 24 (executed: the mutation script re-run into the reviewer's scratch directory, 20 runs listed) | code-fact-check | for-orchestrator-synthesis |
| On the inputs compared (11 stand-in setups, 12 argument sets, `sh` as dash and as bash), the primitive chosen is the same at 23ffb16c and de1f4bf9 | ✅ Confirmed | FC 25 (executed; scope: those inputs, which held no empty command name, see A8) | code-fact-check | for-orchestrator-synthesis |

Pending execution verification (routed by critics; stage 2.5 runs on the final pass): that the body is the same text for any command and each word is its own argv element (security); that the caller's environment cannot set `$BASH` (security); that the added test time scales with the added tests (performance).

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

(Contextual critics: none selected. `tech-debt-triage`'s 500-line trigger is met only by counting the working docs; 238 lines change outside `docs/` across three files.)

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/confine-tests.sh:45-46` | FC 3, A 1 | distinct defects: one finding stated in full by both sources; nothing only the pair implies |
| 2 | `scripts/confine-tests.sh:126-168`, research doc `:47` | FC 22, FC 35, A 2 | distinct defects: the same re-wrap seen from the code, the commit message and the doc; each fragment states the mechanism |
| 3 | `scripts/confine-tests.sh:268-273` | FC 25 (via A8), A 5, S 1, A 4 | distinct defects: the status change (A8), the environment exposure (C6) and the error prefix (C3) share a line and have separate mechanisms and fixes |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

Tokens (agents' reported totals): fact-check 210k, security 126k, performance 101k, API consistency 138k; about 575k for the pass.
