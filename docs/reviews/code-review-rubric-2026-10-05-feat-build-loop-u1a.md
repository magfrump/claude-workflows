Commit: 4aa2e98e
Loop-pass short-circuit: used at c8435580
# Code Review Rubric

**Scope:** `main...feat/build-loop-u1a` (full branch: d6426e3e, c8435580, 2da477b7, 78703f22, 722884c7, 515d7809 (docs/reviews only), 4aa2e98e; 4 code files, 322+/58- outside `docs/`). This is iteration 4 of 4, the final confirming full-panel pass (no `--loop-pass`, k=3). | **Reviewed:** 2026-10-05 | **Status: 🟡 CONDITIONAL PASS** — 4 amber item(s) awaiting resolution or justification

Reports: `code-fact-check-report-build-loop-u1a.md` is the k=3 merge of `-r1/-r2/-r3.md` (29, 40 and 32 claims). It has 49 claim sections in 39 clusters, with verdict agreement 46/49 = 93.9%. Stage 2.5's `code-fact-check-submitted-claims-build-loop-u1a.md` is appended as claims 40-56. The other reports are `security-reviewer-review-2026-10-05-build-loop-u1a.md`, `performance-reviewer-review-2026-10-05-build-loop-u1a.md`, `api-consistency-reviewer-review-2026-10-05-build-loop-u1a.md` and `architecture-review-review-2026-10-05-build-loop-u1a.md`. Every report is stamped `Commit: 4aa2e98e`.

The orchestrator ran `bats test/scripts/dev-cycle.bats` at 4aa2e98e and got 68/68, with LC_ALL=C.UTF-8 and TMPDIR unset. All three replicates and the Stage 2.5 agent re-ran it and also got 68/68. The format gate `REPORT_PATH=… bats test/skills/code-fact-check-format.bats` passes 25/25 on the merged report.

Delivery mode was inline-diff-only through a shared file (`$S/shared/preamble.md` plus a 36 KB `diff.patch`), because the enclosing files are over budget. The deviations are the same as in iterations 1-3:
- Agents read their skill files and the shared block from disk; they were not pasted into the prompts.
- A sub-agent did the mechanical k=3 merge under the skill's merge rules.
- Each agent also had its own scratch dir, so prompts differ in that path as well as in the output path.

There was no Fact-Check Gate pause, because no claim was a high-confidence Incorrect.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | (iteration 1) brief_fields captured awk's output through `$(...)`, which drops NUL bytes | Correctness / input handling | Incorrect (high), behavioral, executed | Fact-check | `scripts/lib/dev-cycle-read.sh` FENCE_AWK | for-author | — | ✅ Resolved at 2da477b7 |
| R2 | (iteration 2) A failed `git cat-file` was swallowed by both main readers | Security / error handling | security Medium · architecture Coupling · api Minor (escalated, executed) | security F2 + architecture F1 + api F1 | `scripts/lib/dev-cycle-read.sh:559-560`, `:295-302` | for-author | Rows 215, 216 | ✅ Resolved at 78703f22. Its pipefail residue was A17, resolved at 4aa2e98e. |
| R3 | (iteration 3) `--help` stopped at `2,80p`, one line short of the header's end at :81 | Correctness / CLI contract | Incorrect (high), behavioral, executed · api Minor | Fact-check claim 6 + api F1 | `scripts/dev-cycle.sh:112` | for-author | — | ✅ **Resolved at 4aa2e98e.** The fix is `sed -n '2,/^[^#]/{/^#/p}'`. Orchestrator check: `diff <(sed -n '2,81p' scripts/dev-cycle.sh \| sed 's/^# \{0,1\}//') <(bash scripts/dev-cycle.sh --help)` gives no diff. The new test 68 ("--help prints the whole header, through its last line") fails on mutants with `2,80p` and `2,77p` (FC r1, r2 and r3, executed; Stage 2.5 claims 45 and 55). The comment's precision residue is A21. Its BSD-sed portability is C18. |

No new red items this pass.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1–A13 | (iterations 1–2) see iteration-3 rubric at 515d7809 | — | — | — | for-author | Rows 197, 208, 215, 217, 220–223 | ✅ Resolved (unchanged; re-confirmed by the k=3 claims at 4aa2e98e) | — |
| A14 | (iteration 3) SKILL.md "(it reads `open`, or no such entry)" was incomplete | Docs | Mostly accurate | Fact-check claim 28 (iteration 3) | for-author | — | ✅ **Resolved at 4aa2e98e.** The text now reads "it reads what main's copy says, usually `open` or no such entry" (`skills/dev-cycle/SKILL.md:293-295`). FC claim 38a, k=3: Verified. | — |
| A15 | (iteration 3) The `--check-answer` help's outcome set left out `unrecognized` and main's old answer | Docs | Mostly accurate | Fact-check claim 2 (iteration 3) | for-author | Row 222 | ✅ **Resolved at 4aa2e98e** for the outcome set ("it reads what main's copy says"; FC claim 2a Verified). The residue in the same sentence, "until committed", is new row A20. | — |
| A16 | (iteration 3) The skip list left out "not a question ID" and named "both files" loosely | Docs | Mostly accurate | Fact-check claim 3 (iteration 3) | for-author | — | ✅ **Resolved at 4aa2e98e.** Stage 2.5 claim 47 (executed, enumeration) found 12 skip echo lines and 7 refusal reasons in check_answer. All 18 skips reachable through dev-cycle.sh map to a help phrase. The one skip left out, "no default branch found by name", cannot be reached through the CLI, which exits 1 first (`scripts/dev-cycle.sh:193-194`). | — |
| A17 | (iteration 3) The read checks in check_answer and brief_fields fired only under the caller's `pipefail` | Security / architecture | security Informational · architecture Minor (escalated, executed) | security F1 + architecture F1 (iteration 3) | for-author | Rows 215, 216 | ✅ **Resolved at 4aa2e98e** (bash 5.2.15). The fix is `local - …; set -o pipefail` at `scripts/lib/dev-cycle-read.sh:292` and `:548`. Executed by FC r1, r2 and r3, by security, and by Stage 2.5 claims 40, 41 and 48: with the caller's options set to none, `-eu`, `-euo pipefail` or `+e +u`, a missing blob gives a skip or `BRIEF_ODD=error`, and an awk failure on its own does too. The caller's options are restored after a normal return and after an early `return 1`. Mutants without `local -` or without pipefail in either function fail test 67. Without the fix, check_answer reads `keep Q-1` from the archive. Residue: the bash-version floor, C17. | — |
| A18 | (iteration 3) 78703f22's R2 bullet overstates where the fall-through happened (history only) | Docs (commit message) | Mostly accurate | Fact-check claims 44, 45 (iteration 3) | for-author | **Row 232** | ✅ Covered by override row 232 (Won't-Fix). FC claim 39 (Verified): rows 232-238 exist as 4aa2e98e says. | Row 232 |
| A19 | **New.** The test title "--check-brief and --check-branch need a default branch found by name; the others do not" is stale. This branch made `--check-answer` need one too (`scripts/dev-cycle.sh:193`; tested at `test/scripts/dev-cycle.bats:1153`). The body still holds, because it checks only `--check-path` for "the others". Fix: "--check-brief, --check-branch and --check-answer need …; --check-path does not", or add `--check-answer` to the loop at `:770` (`test/scripts/dev-cycle.bats:767`). **Convergence:** fact-check + api-consistency F5 + architecture F4 | Tests / docs | Stale (r2, single-replicate detection, executed) · api Informational · architecture Informational | Fact-check claim 22 + api-consistency F5 + architecture-review F4 | for-author | — (not in the log) | 🟡 Open | — |
| A20 | **New (residue of A15's fix).** The `--check-answer` help says a working-tree answer is not seen "until committed". It has to land on the default branch: T34 shows an answer committed only on another branch still reads `open`. SKILL.md:294's "until it lands" is right. Fix: "until it lands on the default branch" (`scripts/dev-cycle.sh:59`). **Convergence:** fact-check (r1, r2 and r3) + api-consistency F1 | Docs / CLI contract | Mostly accurate (k=3) · api Minor | Fact-check claim 2b + api-consistency F1 | for-author | Row 222 covers c8435580's Notes, not this text | 🟡 Open | — |
| A21 | **New.** The comment "The header, up to the first line that is not a comment" is imprecise. `2,/^[^#]/` ends at the first *non-empty* line that does not start with `#`. An empty line inside the header is skipped silently, so a comment block after it would print as help. An indented `#` line also ends the range. Today's header has none of these, so the output is exact (claim 45). Fix: reword the comment ("…the first non-empty line not starting with #"), or have test 68 also assert that the first non-help line is excluded (`scripts/dev-cycle.sh:111`) | Docs | Mostly accurate (r1, r2 and r3 on 6a; executed sed probes) | Fact-check claim 6a | for-author | — | 🟡 Open | — |
| A22 | **New.** main_entry's comment "The caller has checked main_by_name and the path's form" is half stale. main_entry checks main_by_name itself (`:261`), and brief_fields calls it without checking first. Only pathform is the caller's job. Fix: name only the pathform precondition (`scripts/lib/dev-cycle-read.sh:256-257`). **Convergence:** fact-check (k=3) + api-consistency F4 + architecture F1 (its comment half; the code half is C16) | Docs | Mostly accurate (k=3) · api Informational · architecture Minor | Fact-check claim 13 + api-consistency F4 + architecture-review F1 | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | --check-answer help omitted the unreadable-tree skip | api (iteration 2) | Minor | for-author | — | Fixed at 78703f22 |
| C2–C8, C10 | See iteration-3 rubric | various | Minor / Informational | — | Rows 224–231 | Won't-Fix / Deferred per rows |
| C9 | cat-file's `fatal:` reaches stderr unscrubbed in the lib | Fact-check (iteration 2) | Informational | for-author | **Row 238** | ✅ Covered by row 238 |
| C11 | check_brief runs ls-tree twice per brief | performance (iteration 3) | Informational | for-orchestrator-synthesis | **Row 233** | ✅ Covered by row 233. Re-measured: unchanged at 4aa2e98e (Stage 2.5 claim 43) |
| C12 | brief_fields reports every refusal as one `error` | architecture (iteration 3) | Informational | for-author | **Row 234** | ✅ Covered by row 234 |
| C13 | The readers follow `refs/replace` | security (iteration 3) | Informational | for-author | **Row 235** | ✅ Covered by row 235 (not re-raised by security) |
| C14 | A tree entry named with a slash reads `absent` | Stage 2.5 (iteration 3) | Informational | for-author | **Row 236** | ✅ Covered by row 236 |
| C15 | Two commit-Notes claims cannot be checked from the repo | Fact-check (iteration 3) | Unverifiable | for-orchestrator-synthesis | **Row 237** | ✅ Covered by row 237 |
| C16 | **New (mechanism floor).** main_entry relies on its callers to run `pathform`. A path that skips it and holds a character ls-tree quotes (`a"b.md`, `d"x/q.md`, probed) gets `absent`, which is the permissive answer: check_brief prints `ok … new`, and check_answer moves on to the other file. No current caller skips pathform: check_brief checks it first, and check_answer uses constant paths. U1c's `main_file` and U2's floor function will call main_entry directly. Fix: `pathform "$1" \|\| { echo error; return; }` beside `:261` (`scripts/lib/dev-cycle-read.sh:256-263`) | architecture-review F1 | Minor | for-author | Row 230 (test coverage, not where the check lives) | 🟢 Open |
| C17 | **New (convergence).** No minimum bash version is stated. `local -` needs bash 4.4 or later. On 4.4–5.0 it may not restore pipefail on return; 5.1's CHANGES altered that restore. This is unverified (FC claim 15b is Unverifiable, and only bash 5.2 is in the sandbox). Either way the read check stays safe: below 4.4 a `set -e` caller stops before any read, and on 4.4–5.0 pipefail could only leak to a caller that already sets it. Fix: "Needs bash 4.4 or later" in the lib header (`scripts/lib/dev-cycle-read.sh:292`, `:548`) | FC claim 15b (r2) + escalation E2 + security F1 + api F3 + architecture F3 | Unverifiable · Informational ×3 | for-author | — | 🟢 Open |
| C18 | **New.** BSD/macOS sed may reject `{/^#/p}` without a `;` before `}`. This is untested (no BSD sed here). `scripts/run-tests.sh:153` uses the same form, and `scripts/health-check.sh:136,175` use `p;}`. `{/^#/p;}` gives identical output on GNU sed (`scripts/dev-cycle.sh:112`) | FC escalation E1 + api-consistency F2 | Informational (Low confidence) | for-author | — | 🟢 Open |
| C19 | **New.** The lib header still says "The caller sets -euo pipefail" and does not mention that brief_fields and check_answer now set it themselves. This does not contradict the contract (`scripts/lib/dev-cycle-read.sh:12-13`) | architecture-review F2 | Informational | for-author | — | 🟢 Open |
| C20 | **New.** The list of modes that need a default branch found by name is written out at several sites (help, Exit line, `:193`, the test title). A19 is one copy that has already drifted (`scripts/dev-cycle.sh:193`) | architecture-review F4 | Informational | for-author | — | 🟢 Open |
| C21 | **New (narrowed endorsement).** Architecture's G4, "dev-cycle.sh → lib → git and awk", is Mostly accurate. The lib also runs perl, grep, tr and realpath; only the new functions are limited to git and awk | Stage 2.5 claim 54 | Mostly accurate (submitted claim) | for-orchestrator-synthesis | — | 🟢 Open (no ✅ row made from it) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u0b`, `-u0c` / 2026-10-05 (rows 201, 206, 208, 213, 215–217) | check_brief walk; check_answer from the working tree; main_by_name; need_root; guard channels; print-only; SKIPPED | various | see rows | Inherited. Rows 206 and 217 are discharged (Stage 2.5 claims 42 and 51). C16 is a different failure from row 208. |
| `feat/build-loop-u0a` / 2026-10-05 (rows 196, 197) | Lib from build-loop.sh's side | 🟢 → Defer to U1 | U1's test unit | 197 is discharged; 196 is still U1b's. |
| `feat/build-loop-u1a` / 2026-10-05 (rows 220–231) | iteration 1–2 items | 🟡/🟢 → Won't-Fix / Defer | see rows | Inherited, not re-raised. Performance cited 220, 228 and 229. C16 touches row 230's subject (test coverage) but is about where the check lives. |
| `feat/build-loop-u1a` / 2026-10-05 (row 232) | 78703f22 R2 bullet (A18) | 🟡 → Won't-Fix | History only | Inherited. A18 is closed. |
| `feat/build-loop-u1a` / 2026-10-05 (rows 233–238) | iteration 3 C11–C15, C9 residue | 🟢 → Won't-Fix / Defer | see rows | Inherited. These close C9 and C11–C15. Security, architecture and performance cited them and did not re-raise them. |

No override row covers A19–A22 or C16–C21.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| check_answer prints a skip when main's questions.md blob cannot be read, whatever options the caller set (none, `-eu`, `-euo pipefail`, `+e +u`, `-e -o pipefail -o noglob`), and leaves the caller's options unchanged | ✅ Confirmed (bash 5.2.15 only; see C17) | `scripts/lib/dev-cycle-read.sh:548`: `local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields`. FC claims 40, 48 (executed); mutants fail test 67 | Fact-check (submitted by security, api) | for-orchestrator-synthesis |
| brief_fields returns 1 with `BRIEF_ODD=error` and no keys when cat-file fails or awk fails on its own, under `-eu` | ✅ Confirmed (bash 5.2.15) | `scripts/lib/dev-cycle-read.sh:292`: `local - out l; set -o pipefail`. FC claim 41 (executed, PATH-shim awk) | Fact-check (submitted by security) | for-orchestrator-synthesis |
| `--help` prints exactly header lines 2–81, and test 68 fails when the range is cut short | ✅ Confirmed (current header, GNU sed 4.9; see A21, C18) | `scripts/dev-cycle.sh:112`: `-h\|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" \| sed 's/^# \{0,1\}//'; exit 0 ;;`. FC claims 45, 55 (executed); orchestrator diff vs `2,81p` empty | Fact-check (submitted by api, architecture) | for-orchestrator-synthesis |
| The `--check-answer` help's skip list names every skip check_answer can print through dev-cycle.sh | ✅ Confirmed (enumeration: 12 echo lines / 7 reasons, 18 reachable skips produced) | `scripts/dev-cycle.sh:63`: `#             <reason>" when it cannot be read (not a question ID, no such`. FC claim 47 (executed) | Fact-check (submitted by api) | for-orchestrator-synthesis |
| check_answer reads only main_entry's ls-tree and `git cat-file blob "$MAIN_SHA:$f"` for the two fixed files. A broken working tree changes no answer | ✅ Confirmed (git-call level, via a logging shim; refs/replace is row 235) | `scripts/lib/dev-cycle-read.sh:561`: `r="$(git cat-file blob "$MAIN_SHA:$f" \| env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \`. FC claims 42, 51 (executed) | Fact-check (submitted by security, architecture) | for-orchestrator-synthesis |
| Iteration 4 adds no git calls and changes no output: the same call counts and byte-identical output as 722884c7 | ✅ Confirmed (fixture shape measured) | FC claim 43 (executed; 30 alternating runs, medians within 1%) | Fact-check (submitted by performance) | for-orchestrator-synthesis |

(The cross-check narrowed or dropped these: G4 (claim 54, Mostly accurate) is C21, not a ✅ row. G2's "one parser" holds for the status value only, since check_brief's `git log -G` is a separate fence-blind lookup, so it is not a ✅ row. Each row above was checked against the merged report and the r1–r3 replicates, and no observation contradicts any of them. Claim 6a's empty-line behaviour is consistent with the `--help` row, because that row is scoped to the current header.)

---

## ⚠️ Unverified Findings

All findings' evidence resolved: every cited line was re-read at 4aa2e98e, including `scripts/dev-cycle.sh:59,111-112,193`, `scripts/lib/dev-cycle-read.sh:12-13,256-263,292,548` and `test/scripts/dev-cycle.bats:767`.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. architecture-review was auto-selected and ran. No other contextual critic was selected: the diff has test changes, ≤10 code files, ≤500 code lines, and no manifests or UI.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/lib/dev-cycle-read.sh:254-263` | FC claim 13, api F4, architecture F1 | Distinct defects. The stale comment (A22) and the unenforced pathform (C16) each state their own mechanism and fix. The three sources converge on A22. |
| 2 | `scripts/lib/dev-cycle-read.sh:292`, `:548` | FC 15b + E2, security F1, api F3, architecture F3, Stage 2.5 claims 40/41/48 residues | Distinct defects. All sources state the same bash-floor gap, which converges on C17. No unstated root. |
| 3 | `scripts/dev-cycle.sh:111-112` | FC 6a + E1, api F2 | Distinct defects: the comment's precision (A21) and BSD sed grammar (C18). |
| 4 | `scripts/dev-cycle.sh:56-75`, `:193`; `test/scripts/dev-cycle.bats:767` | FC 2b, FC 22, api F1, api F5, architecture F4 | Distinct defects. "Until committed" (A20) and the stale title (A19) are separate texts. C20 names the duplication behind A19 and states it in full. |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

---

## Iterations (4 completed; bound 4 of 4, granted by Q-111 [1])
1. `--loop-pass`, short-circuited at the fact-check: 1 red (NUL bytes dropped by `$(...)`). Fixed in 2da477b7.
2. Full panel at 2da477b7: 1 red (a failed `cat-file` ignored) and ambers A4–A13. Fixed in 78703f22 and 722884c7.
3. Full panel at 722884c7: 1 red (R3, a regression from iteration 2's help fix) and ambers A14–A18. The gate escalated and became Q-111.
4. Final confirming full panel at 4aa2e98e: R3 and A14–A17 resolved by execution, and A18 covered by row 232. 0 new red. 4 new ambers (A19–A22), all comment, help or test-title wording. Each is a one-line text edit, and none changes behaviour.

No `Loop closed at` marker: this pass is not clean (4 open ambers).

## Remaining Must Address
- A19 `test/scripts/dev-cycle.bats:767`: stale test title (add `--check-answer`).
- A20 `scripts/dev-cycle.sh:59`: "until committed" should read "until it lands on the default branch".
- A21 `scripts/dev-cycle.sh:111`: the comment should say "first non-empty line not starting with #".
- A22 `scripts/lib/dev-cycle-read.sh:256-257`: drop "main_by_name" from the caller's preconditions.
