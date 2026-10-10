Merge branch 'feat/build-loop-u2c1': --check applies the S rules to a self-merge brief: Paths:, own files, the floor, Self-merge never:

## What this does

U2c1 of the build-loop handoff (plan step 5, the U2c split note). For a brief --status reads as self-merge, `build-loop.sh --check` now judges each changed path the N rules pass (the brief's own file aside, which they alone judge) by plan D5's S rules, first match winning: the lib's floor (instruction and prompt files and their @-imports, dot paths, gate code, records, other briefs' working docs and reviews; only over a checkout checkout_gate passed), a `Self-merge never:` glob, then the allowlist (the brief's `Paths:` line, or one of its own files). A refusal is a `deny` line, counted into the K of N verdict. Under review nothing changes.

**Workflow provenance:** RPI (plan revision 4, step 5) → U2c split before code (U2c1 here, U2c2 the walk side) → pr-prep.
← carried from RPI: D5's allowlist over the narrow floor, the floor's caller contract (items 1, 4, 5), rev 2's `Paths:` grammar, settings read from main's commit only, U2b2's checkout refusal before the floor.

**Failures prevented:**
- A self-merge landing a path its brief never listed, or a floor path (CLAUDE.md, an @-imported doc, gate code, .envrc, docs/decisions/) it did list, or a path the repo's `Self-merge never:` line names.
- A branch creating a directory at a cycle file's or the constraints doc's name, or `docs/working/{briefs,cycles}` as a file (row 523, an N rule under both policies).
- Found in review: own files matched lower-cased, so an upper-case spelling of an own working doc or review landed unlisted (a review could then take an existing review's name on a case-insensitive clone); a failed brief re-read hid its failure.

## Reviewer's path — start here

1. `scripts/build-loop.sh` --help, the --check S-rules paragraph, then `srules`.
2. `list_entries` (shared by read_settings' never line and `read_paths`), `never_res`.
3. `check_line`: the parent-shell call, LC_ALL=C, the brief re-read, the per-path loop; `nrules`' prefix loop.
4. `test/scripts/build-loop-check.bats`, the six tests naming U2c1.

## How it works

- **list_entries LINE KEY WORD FORM**: "KEY: none" or "KEY: E ..." with single spaces, each entry passing FORM (globform, pathform) with any trailing / dropped, listed once; sets LIST, LIST_WHY and LIST_BAD (form, entry). `Paths: none` or no line lists none; bare `Paths:` is malformed; a malformed Paths: line lands only own files.
- **never_res**: each never glob as a regex for the lower-cased path: `*` and `?` within one part, matching the path or any directory above it.
- **srules**: floor (when no verdict refusal), never glob (deny names the glob), then Paths: (exact; a trailing / is a directory at a part boundary) or an own file, which counts only when the whole path is lower case.
- **check_line** runs in the parent shell under `local -x LC_ALL=C` (contract item 1), so need_root's exit ends the run and its import_reset keeps one decision's walk from the next (a test counts one worktree listing per self-merge decision). A failed brief re-read refuses the verdict like a checkout refusal; path lines still print.

## How to test

- The six U2c1 tests: T9 (listed paths, own docs and reviews, the Status line), T10 (floor refusals though listed; a symlink at a listed path; exact Paths: boundaries; malformed lines; upper-case own files), T45 (never globs by part and case; review ignores them), row 523, and the walk-count and C.utf8 test (red without check_line's import_reset or its LC_ALL).
- Suites, run serially: build-loop-check 138, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2.

## Areas of uncertainty

- **Cost**: the floor costs about 6.5 ms per changed path (two lower-casing forks and four need_root calls per floor call): on a 3,000-file fixture, main 0.24/0.28/0.33 s against this branch 0.47-0.58/1.4-1.6/3.0-3.3 s for 1/150/400 paths (performance and fact-check, same fixture). Routed to U2c2 with rows.
- **Routed to U2c2**: a directory at an instruction-file name or import target (availability only); floor's per-path cost; the walk-side rows (security F3, IMPORTED_MAIN_WHY, config dirs in the reader key, the outside_seeds split).
- **Deferred to U3/U4 (rows)**: the per-path malformed-Paths reason, the verdict chain, a loop's advisory run skipping the floor (help says so), an exact upper-case review in Paths:, a test for the re-read branch, the lib's reader_settings copy of the list grammar.
- **Commit messages overtaken** (Accepted-immutable row): eddfd5f9's bare "Paths:" lists none, d435100e's B1 and B5. As built: above.
- **Not panel-reviewed**: the final-pass fixes (0f9b6a46, 069ddfa9) were checked by a k=1 fact-check and the security critic instead (no Incorrect, no new fail-open).

Review converged in 3 iterations (plus a confirming pass); 0 Must Fix; Must Address: A1 (Coupling, fixed in part with a row) and D1 (Medium, fixed). Rubric: `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c1.md`. 321 changed code lines.

Confidence: high
Notes: the U2c split was an interim /away call (plan step 5); merged on the recommendation per the standing instruction (Q-137 [1]).

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018X78L3ajw3rXEbwmifV4wc
