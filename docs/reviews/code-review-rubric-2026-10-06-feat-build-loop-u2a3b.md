Commit: 7ddff454
Loop-pass short-circuit: used at 1ccc8b65
# Code Review Rubric

**Scope:** iteration 2: `--range 45ad17b0..7ddff454`, the whole unit (full-scope fallback: the critics had never seen it), `--loop-pass`; iteration 1: `45ad17b0..1ccc8b65`. U2a3's commits are context only, not under review | **Reviewed:** 2026-10-06 | **Status: 🟡 CONDITIONAL PASS** — 0 red; every iteration-2 amber is fixed in the iteration-2 fix commit or carries a revisit trigger (I2-A6), pending the final confirming pass (no `--loop-pass`, k=3, full panel)

## Iteration 2 of 3 (Commit 7ddff454, range 45ad17b0..7ddff454, full unit scope, --loop-pass, k=1, full panel)

Scope: full unit, not the fix-only delta `1ccc8b65..7ddff454`, because the critics were short-circuited in iteration 1 and had never seen the unit (pr-prep 3d's fallback to a full re-review). Delivery mode: self-read. The short-circuit was already used (marker above), so Stage 2 ran in full with amber collected. Stage 2.5 skipped (loop pass): routed endorsement claims in the security and performance reports stay *pending execution verification*. Prior iteration: R1 and R2 verified fixed by fact-check i2 (each failure component executed); security F1 shows R1 held only for a name with no earlier cut mark (I2-A1).

Reports (all `Commit: 7ddff454`):
- `code-fact-check-report-build-loop-u2a3b-i2.md` (k=1, opus): 25 claims, 22 Verified, 3 Mostly accurate, 0 Incorrect; escalation to test-strategy (two unpinned controls).
- `security-reviewer-review-2026-10-06-build-loop-u2a3b.md`: 3 Medium, 1 Low (executed against Claude Code 2.1.292's extracted lexer).
- `performance-reviewer-review-2026-10-06-build-loop-u2a3b.md`: 3 Informational (walk 478 ms to 643 ms median here).
- `api-consistency-reviewer-review-2026-10-06-build-loop-u2a3b.md`: 1 Inconsistent, 3 Minor, 2 Informational.
- `architecture-review-review-2026-10-06-build-loop-u2a3b.md`: 0 Structural, 1 Coupling, 2 Minor, 2 Informational.

Tests at 7ddff454: 115/115. After the iteration-2 fix commit: 116/116 (five suites), shellcheck clean on the lib and dev-cycle.sh, 225 changed code lines against 45ad17b0. Mutants of each iteration-2 fix (first cut only, no comment pass, no newline check, instruction_names `|| true`, no sed g flag, here-string grep, no walk-failed reason) each fail a test.

### 🟡 Must Address (iteration 2)

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| I2-A1 | `${t%%cut*}` cuts only at the first cut mark, so a name holding `_` (or ( ) [ ] ! * <) followed by a code span, `<br>`, a link or emphasis is missed by both walks (``@docs/my_notes.md`code` `` regressed from 45ad17b0); R1's fix was incomplete | Security | Medium | security F1 (executed both sides) | for-author | row 358 | ✅ Fixed: each token yields its prefix before every cut mark; candidates are deduped before realpath (also performance F1). Test: my_notes + code span, s_g + `<br>`, k_l + `**b**`. Divergence note: R1 re-fired at the same site (iteration 1's fix targeted the backtick symptom; the root was first-mark-only cutting). |
| I2-A2 | In an HTML block opened by `<!--`, Claude Code deletes every comment and scans the rest, so `@docs/sec<!-- x -->ret.md` loads docs/secret.md, which no walk form yields (pre-existing) | Security | Medium | security F2 (executed) | for-author | — | ✅ Fixed: text holding `<!--` is read once more with every closed comment removed (an over-read elsewhere). Test: docs/secret.md. |
| I2-A3 | The tree walk's newline-separated `seen` list: a start under `a<NL>b/` makes `b/X.md` read as seen, so its imports pass --check-fix (pre-existing; main fails closed) | Security | Medium | security F3 (executed) | for-author | — | ✅ Fixed: a start name holding a newline fails the walk. Test in the tr test. |
| I2-A4 | A failed tree walk makes check_fix print "an instruction file imports it with @" for every path (a false reason; refusing is right); isimported's header tells only main's callers how to word a failed walk | API | Inconsistent | api-consistency 1, architecture 2 (both executed). Convergence | for-author | — | ✅ Fixed: check_fix runs imported_names under `if !` and prints "the instruction-file import walk failed"; isimported's header names both walks. Test in dev-cycle.bats. |
| I2-A5 | Comments and names: "a backslash-escaped space is known issue A5" (A5's text does not say so); the tr test name claims both walks meet a failing listing | Docs / tests | Mostly accurate | fact-check i2 | for-author | row 350 | ✅ Fixed (comment says the gap is deferred with A5's; test renamed). |
| I2-A6 | The parser copies Claude Code 2.1.292's grammar with no version or revisit trigger in the code, plan F11 or known issues; test/agents-gemini-sync.bats pins another copy | Architecture | Coupling | architecture 1 | for-author | — | ✅ Code half fixed (comment names the version, the source and the trigger, and points to the other copy); plan and known-issues half: Defer (override row; revisit trigger U5 or the first commit after rebase). |
| I2-A7 | `instruction_names returns grep's error status` in 7ddff454's message: it returns 1 | Docs (commit message) | Mostly accurate | fact-check i2 | for-author | — | Accepted-immutable (override row); the function's comment states it. |

### 🟢 Consider (iteration 2)

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| I2-C1 | Here-strings past ~64 KiB go to a temp file; a failed write reads as "no match" (import_targets' grep and loop, imported_names' loop) | security F4 (executed, ulimit -f 0) | Low | for-author | — | Fixed (pipe and process substitution; test with ulimit -f 0) |
| I2-C2 | main_imports' header omits the new lower guard, the parser, the candidate tr and the cached error | api-consistency 2 | Minor | for-author | — | Deferred: routed to U2a3 (override row) |
| I2-C3 | Three copies of the rc=0 listing check, two marker-drop styles, unstated record rules | architecture 3 | Minor | for-author | — | Deferred: routed to U2a3 (override row) |
| I2-C4 | main_imports' own here-string (`done <<<"$out"`) has I2-C1's failure | security F4 (U2a3 code) | Low | for-author | — | Deferred: routed to U2a3 (override row) |
| I2-C5 | IMPORTED starts as $'\n' (a successful empty walk), IMPORTED_MAIN as error | api-consistency 3 | Minor | for-author | — | Deferred (override row; the line abuts U2a3's edits) |
| I2-C6 | inrepo_here failing skips a path in the tree walk, fails main's | architecture 4 | Informational | for-orchestrator-synthesis | row 347 | Won't-Fix (override row) |
| I2-C7 | Two substitutions per walked file (+2 ms each) | performance F2 | Informational | for-author | rows 346, 355 | Won't-Fix (override row) |
| I2-C8 | Whole file in a variable through a 20-expression sed (5 MB: 189 ms, 28.8 MB) | performance F3 | Informational | for-author | — | Won't-Fix (override row) |
| I2-C9 | Every token paid 4 realpath forks, dedup only after the fork (200 plain tokens: 932 ms against 271 ms) | performance F1 | Informational | for-author | row 363 | Fixed with I2-A1 (dedup before the fork) |
| I2-C10 | isimported's header omits the failed-lower case; instruction_names' inverted status unstated; the lib header does not say the walks return 1 and need if or \|\| | api-consistency 4, 5, 6 | Minor / Informational | for-author | — | Fixed (comments) |
| I2-C11 | The imps helper always printed "walk: ok" for tree, so tests caught a failed tree walk only through a negative check | architecture 5 | Informational | for-author | — | Fixed (imps reports imported_names' return; the tr test asserts the tree walk fails) |
| I2-C12 | instruction_names' error status and the sed `g` flag were unpinned (mutants survive) | fact-check i2 escalation (test-strategy) | Low | for-author | — | Fixed (grep -z shim case; p/q/r NBSP case) |

### ↩️ Considered Overrides (iteration 2)

Rows 346, 347, 350, 355, 358, 359, 363 (U2a, U2a2) and this loop's two iteration-1 rows matched. Inherited: 346/355/363 (batching; performance cited them, I2-C9 was filed as broader), 347 (the walks differ on purpose; I2-C6), 350 (escaped space; I2-A5). Departed: none; 358's fix was incomplete (I2-A1) and is completed.

### ✅ Confirmed Good (iteration 2)

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The start-list check returns 1 for each component failing (corrupt index, ls-files, untracked_md, grep exit 2, an unreadable start file, a failing tr), first call and cached | ✅ Confirmed | `[[ ${#recs[@]} -gt 0 && "${recs[-1]}" == rc=0 ]] \|\| return 1`; fact-check i2 focus 1 (executed) | Fact-check | for-orchestrator-synthesis |
| No caller breaks on instruction_names' new status (only imported_names calls it) | ✅ Confirmed | `rg -n instruction_names` across scripts and tests; fact-check i2 focus 2 (enumerated) | Fact-check | for-orchestrator-synthesis |

### ⏭️ Skipped Core Critics (iteration 2)

All core critics ran; no skips applied.

### 🧩 Composition check (iteration 2)

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/dev-cycle.sh:181`, lib isimported | api-consistency 1, architecture 2 | distinct statements of one defect, each complete (I2-A4); no composed row |
| 2 | lib import_targets :500-519 | security F1, F2, F4; performance F1-F3; fact-check i2 (g flag) | distinct defects (cut position, HTML comment splice, temp-file here-string, fork count, substitution cost, memory); no composed row |
| 3 | lib imported_names start loop | security F3, architecture 3, 4; fact-check i2 focus 1 | distinct defects (newline seen list, duplicated marker check, inrepo_here asymmetry) |

## Iteration 1 of 3 (Commit 1ccc8b65, range 45ad17b0..1ccc8b65, --loop-pass, k=1)

Delivery mode: self-read (each agent read the shared block from the session scratchpad, its skill file and the diff itself). Loop-pass short-circuit: a behavioral 🔴 was confirmed at fact-check (Claim 7b), so the critics were skipped and the pass went back to the loop for the fix. No enforcement file is in the diff (hooks/live-verify-gate.sh regex), so mechanic 7 does not force security.

Reports: `code-fact-check-report-build-loop-u2a3b.md` (k=1, opus, 37 claims: 24 Verified, 8 Mostly accurate, 5 Incorrect, 0 Stale, 0 Unverifiable; probes and mutant logs in /tmp/u2a3b-factcheck-FQ0K/_logs/).

Tests at 1ccc8b65: 114/114 (five suites); shellcheck clean. After the fix: 115/115 (Patch A adds one test); shellcheck clean; 155 changed code lines against 45ad17b0 by pr-prep 1a.

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | The comment names a code span among the Markdown that ends a token sooner, but the cut set `[][()<!*_]` has no backtick. For ``Read @docs/a.md`x` first.``, `--check-fix docs/a.md` was `skip` at 45ad17b0 and is `ok` at 1ccc8b65, while Claude Code 2.1.292 imports docs/a.md. Fail-open regression (executed end to end). | Correctness (gate) | Incorrect (high), behavioral | Fact-check Claim 7b | `scripts/lib/dev-cycle-read.sh` import_targets | for-author | — (row 358's fix, now completed) | ✅ Fixed: the cut set holds a backtick (`b=$'\x60'`, quoted in the pattern); the parser test reads `@docs/j.md` followed by a closed code span. Mutant (no backtick in the cut) fails it. |
| R2 | imported_names' new header says it "returns 1 ... when a command it runs fails", but the start listing `< <({ git ls-files -z; untracked_md; } \| instruction_names)` is never checked and instruction_names ends in `\|\| true`: with ls-files failing the walk returns 0 with an empty IMPORTED and a tracked import answers "not imported". The `local -; set -o pipefail` does not reach the process substitution. Fail-open (executed). | Correctness (gate) | Incorrect (high), behavioral | Fact-check Claim 1b | `scripts/lib/dev-cycle-read.sh` imported_names | for-author | — (row 359's fix, now completed) | ✅ Fixed: the listing ends with `rc=0` only when both listings and the filter succeed (main_imports' pattern), checked before the loop; instruction_names returns grep's error status; the comment lists the failures that return 1. Test: a corrupt index gives `walk failed` and `isimported tree` answers imported. Mutant (no rc check) fails it. |

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Claude Code's regex does not end a token at `#`; it cuts the captured name at `#` afterwards (so `@x.md#@y.md` over-reads y.md, safe) | Docs | Mostly accurate | Fact-check Claims 5, 22 | for-author | row 350 (escaped space) | ✅ Fixed (comment) | |
| A2 | Test name "read what Claude Code reads ... ~x": Claude Code never loads `@~g.md` | Tests | Incorrect (test name) | Fact-check Claim 17b | for-author | — | ✅ Fixed: "~x is over-read, ~/ dropped"; the test now also checks `@~/x.md` is dropped (the bare ~/ exclusion mutant survived before) | |
| A3 | The tr test's imps loop passes through isimported's own lower guard, so neither walk's guards are exercised there; `walk: failed` is never asserted | Tests | Mostly accurate | Fact-check Claims 18, 19 | for-author | — | ✅ Fixed (partly): `walk failed` asserted for main; the direct calls check imported_names' start-file guard and its cached error (mutant fails). Residue in C1. | |
| A4 | Commit 1ccc8b65's message: `@~g.md` "names a file"; "the one way it refuses less" misses the code span; plus five Mostly accurate statements | Docs (commit message) | Incorrect / Mostly accurate | Fact-check Claims 20, 22, 23b, 29b, 30, 31, 32 | for-author | — | Accepted-immutable (override row) | The branch is not rebased; the fix commit states the corrected facts. |

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Surviving mutants: the grep status-2 guard, the ) ] and backtick strips, per-token dedup, imported_names' per-path lower guard, main_imports' lower guard (a failing tr fails main_imports earlier) | Fact-check Claim 18 | Low | for-author | — | Deferred (override row) |
| C2 | test-strategy final Patch A (U2a2): two NBSPs in a run, a target only after a NUL, a missing directory, mixed-case queries, isimported's need_root, all 19 Unicode spaces, a SKILL.md start, an untracked .MD start | Override row 362 trigger | Low | for-author | row 362 | Fixed: applied as checked; its new test runs over both walks (the report's coverage gap 3) |

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u2a2` / 2026-10-06 (row 357) | @ after a UNI_SPACES character swallowed | Fact-check Incorrect → Defer | fixed in U2a3b | Verified fixed by fact-check (space-to-blank mutant fails). |
| `feat/build-loop-u2a2` / 2026-10-06 (row 358) | Markdown ends Claude Code's token; ( ) ] in a name | 🟡 → Defer | fixed in U2a3b | Fix incomplete at 1ccc8b65 (R1, code span); completed in the fix commit. |
| `feat/build-loop-u2a2` / 2026-10-06 (row 359) | Tree walk failures hidden; grep errors swallowed; ROOT_REAL unchecked | 🟢 → Defer | fixed in U2a3b | Fix incomplete at 1ccc8b65 (R2, start listing); completed in the fix commit. |
| `feat/build-loop-u2a2` / 2026-10-06 (rows 361, 362) | `~x` dropped; test 1's NUL case; untested guards G1-G8 | Stale / 🟢 → Defer | U2a3b's review applies Patch A | `~x` now over-read; Patch A applied (C2). |
| `feat/build-loop-u2a` / 2026-10-06 (row 350) | Backslash-escaped space and other A5 gaps | 🟡 → Defer | known issue A5 | Inherited; Claim 5 notes `\ ` again, not re-flagged. |
| `feat/build-loop-u2a2` / 2026-10-06 (rows 346, 355, 363) | Per-blob reads, O(q²) queue, extra probes | 🟢 → Won't-Fix / Defer | batching rework | Inherited; not re-flagged (no critics ran). |

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| A NUL becomes a blank under GNU sed 4.9 with no "ignored null byte" warning | ✅ Confirmed | `scripts/lib/dev-cycle-read.sh` import_targets — `s=(-e 's/\x0/ /g')`; FC (executed) | Fact-check | for-orchestrator-synthesis |
| grep's no-match (1) is not a parser failure; its error status (2) returns 1 | ✅ Confirmed | `toks="$(env LC_ALL=C grep -aoE "$IMPORT_RE" <<<"$toks")" \|\| [[ $? -eq 1 ]] \|\| return 1`; FC (executed) | Fact-check | for-orchestrator-synthesis |
| `i` is local in main_imports | ✅ Confirmed | `local - rec f d p src i out ...`; FC | Fact-check | for-orchestrator-synthesis |

## ⚠️ Unverified Findings

All findings' evidence resolved.

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review | loop-pass short-circuit (behavioral red confirmed) | Fact-check Claim 7b (executed regression) |

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
