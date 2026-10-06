Commit: 1ccc8b65
Loop-pass short-circuit: used at 1ccc8b65
# Code Review Rubric

**Scope:** `--range 45ad17b0..1ccc8b65` (one commit; U2a3's commits are context only, not under review), `--loop-pass` | **Reviewed:** 2026-10-06 | **Status: 🔴 DOES NOT PASS** — 2 red item(s) found at 1ccc8b65, both fixed in the iteration-1 fix commit, pending re-review

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
