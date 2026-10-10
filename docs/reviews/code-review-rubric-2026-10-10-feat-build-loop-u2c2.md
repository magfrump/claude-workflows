Commit: ac078bd7
Loop-pass short-circuit: used at ac078bd7
# Code Review Rubric

**Branch:** `feat/build-loop-u2c2` (U2c2: the walk side: floor's cost and reasons, a path below a start's name, live prompt links (F3), config dirs in the reader key, c1_seeds), on main 75ec873c.
**Status: 🔴 ITERATION 2 (`--loop-pass`, k=1, range 3111ee9d..ac078bd7, short-circuited at fact-check) — Must Fix B1 (the A9 fix did nothing) fixed in 2be3db37 with a test, unreviewed at this stamp (lite fix-drift: one finding, refuted). Next: iteration 3, the final confirming pass (k=3, full panel, no `--loop-pass`).**

## Iteration 2 (Commit ac078bd7, `--loop-pass`, k=1, scope `3111ee9d..ac078bd7`, partial)

Fact-check `code-fact-check-report-build-loop-u2c2-i2.md` (40 claims: 30 Verified, 6 Mostly accurate, 3 Incorrect, 1 Unverifiable; executed probes). Loop-pass short-circuit: behavioral 🔴 confirmed at fact-check (claim 12a); critics skipped (`## ⏭️ Skipped Core Critics`: security, performance, api-consistency, architecture — loop-pass short-circuit (behavioral red confirmed); no enforcement file in the diff). Rubric A1-A8 and A12-A14 verified fixed.

### 🔴 Must Fix

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| B1 | prompt_marks' below-a-root test never refused: `read` empties `p` at EOF, so `[[ "$b" == "$p"/* ]]` passed every absolute path; the A9 fix (and 07af69c0's and the rubric's claims) did nothing (executed, probe P1). Not a security regression: marking as before the fix. | Incorrect (behavioral) | fact-check 12a, 29, 36 | Fixed: a flag set inside the loop; test (out-of-root link unmarked, into-root link marked) fails on ac078bd7's lib. |

### 🟡 Must Address
None.

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| B2 | prompt_marks' doc: an out-of-root link's target text can still yield repo names (read plain). | fact-check 12b | Fixed in text. |
| B3 | A memoized import_readers refusal skipped need_root (a wrong cwd got a readers reason); the header's "checks nothing" was loose. | fact-check 2, architecture escalation | Fixed: readers_root needs a held result (non-empty roots) to skip; header says it checks only that ROOT_REAL is set. |
| B4 | floor's "forks nothing" omits walk_why's subshell after a failed walk (the fix range added it). | fact-check 21, 37 | Fixed in text (per path only when the walk failed). |
| B5 | walk_why's seeds sentence omits a newline path and a failed lower. | fact-check 9b, 38 | Fixed. |
| B6 | walk_why shows absolute host paths whose characters pass, and an unknown KIND unfiltered (all KINDs are lib-internal). | fact-check escalation | No change: the pathform-character rule is check_line's own; the host path names where to look. |
| B7 | "both walks give main's 1593 names" not re-run by the fact-check. | fact-check 33 | Re-run by the author after the fix. |

Lite fix-drift check over 2be3db37: one finding (readers_root's "a memoized refusal checks the root too" said to describe a DONE != KEY path), refuted: import_readers sets IMPORT_READERS_DONE before any refusal (a refusal is memoized as an empty IMPORT_ROOTS), so a memoized refusal has DONE == KEY and reaches the `-n "$IMPORT_ROOTS"` test.

## Iteration 1 (Commit 3111ee9d, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: inline-diff-only (the lib is ~2,000 lines, over the shared-block budget; each agent read the saved diff and a shared brief). Fact-check: `code-fact-check-report-build-loop-u2c2.md` (36 claims: 22 Verified, 9 Mostly accurate, 2 Stale, 2 Incorrect, 1 Unverifiable; three executed probes). Critics (opus, parallel): security, performance, api-consistency, architecture (`*-2026-10-10-u2c2.md`). Stage 2.5 skipped (loop pass): the critics' routed endorsements stay pending execution verification. No short-circuit: both Incorrects are text (a header sentence, a commit-message count).

Considered overrides: rows 376, 467, 470, 581, 582, 585, 589, 602, 603, 608, 610, 611, 618 (the items this unit takes up; all Defer, none Won't-Fix, so none filters a finding). No Won't-Fix or Accepted-immutable row matched a finding.

### 🔴 Must Fix
None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| A1 | main_imports now runs import_readers before need_root: with ROOT_REAL unset the walk returns a `readers` refusal (wrong cause) instead of exiting as the header promises, an import_readers miss runs `git worktree list` from an unchecked directory, and the two walks order the root check differently. Fails closed. | Coupling (High) / Inconsistent / fact-check Incorrect (doc) | fact-check 2; architecture 1; api-consistency 1; security 2 (Informational) | Fixed: `readers_root` runs need_root unless import_readers' memo answers for ROOT_REAL's key; both walks call it first and need_root again below their cache check (the tree walk's cached call forks nothing too: performance 4). |
| A2 | floor's link/start/admit/read reasons print an untrusted path verbatim into every deny row (prompt-injection and host-path channel into `--check` output; executed). No fail-open. | Medium | security 1 | Fixed: walk_why shows the path only when every character is one pathform allows, else `?` (check_line's rule); a `//` entry shows as its absolute path. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| A3 | An IMPORT_OUT_MAX overrun usually trips the parser's own bound and reports `read PATH` worded as "work budget"; `budget` covers only what the parser did not bound. | fact-check 9b, 23; api-consistency 3 | Fixed: the read wording names both budgets; the doc says which trips first. |
| A4 | Stale: both walk-cache descriptions omit IMPORT_CONFIGS; contract item 9 omits it from "never set these yourself"; the dev-cycle.bats surface inventory lacks c1_seeds, config_seeds, walk_why, walk_has, readers_root, IMPORT_CONFIGS, IMPORTED_MAIN_WHY. | fact-check 5, 6, 7; api-consistency 4; architecture 7 | Fixed. |
| A5 | Floor's wording is an 11-arm case inside floor; the lib's convention is a word-to-sentence function (entry_why, oddwhy); an unknown KIND silently lost its where. | architecture 3; api-consistency 6 | Fixed: walk_why (unknown KIND worded generically). |
| A6 | truthwalk copies isimported's walk dispatch and membership test; its doc's "as isimported does" differs on case. | architecture 5; api-consistency 2 | Fixed: walk_has shared by both; truthwalk's doc says upper case answers imported (both callers run truthrule's case word first). |
| A7 | outside_seeds' split is partial: no wrapper (config seeds still fused with it); two comments still say "outside_seeds' C1 part"; row 582's repeated admission untouched. | architecture 2 | Fixed: config_seeds plus a three-call outside_seeds wrapper; comments name c1_seeds. Repeated admission: override row. |
| A8 | Row 608's import-name half: a narrower rule closes it (an ancestor in the walk list that ends in .md); the comment cites an override row not yet written. | security 3; fact-check 27 | Fixed: floor refuses a path below an imported .md name too; the row records the rest. |
| A9 | Live prompt marks are almost all over-read here: ~/.claude/skills links into /opt, outside every root, so each walk re-reads 109 names from 6 skills (0.15-0.2 s per main walk). | performance 1, 5 | Fixed: prompt_marks marks a live entry only when its real path lies below a reader root. |
| A10 | The walk-list glob is now floor's main per-path cost (4.2 ms at a 1 MB list, 18.5 ms at 4 MB). | performance 2 | Defer (row): rows 470/611 re-keyed to a list past ~500 KB. |
| A11 | floor's cached call still forks when import_readers' memo misses (a HOME change mid-decision); doc overstated. | fact-check 20; performance 3 | Fixed in text. |
| A12 | IMPORTED_MAIN_WHY's attribution is implicit (a new return 1 reports the current stage); floor reads main_imports' global rather than through truthwalk. | architecture 4 | Doc fixed (the inherit rule); TRUTH_WHERE through truthwalk deferred to U3 with row 472 (row). |
| A13 | floor's $4 replaces $1 when given. | architecture 6 | Fixed in text ($4 must be $1 lower-cased). |
| A14 | build-loop.sh's --check help omits the below-a-start refusal and the walk-failure detail. | api-consistency 5 | Fixed. |
| A15 | Wording nits: readers (empty root, newline, `/`), link (.claude itself), list/seeds (a newline name, a short lower_all). | fact-check 21, 24, 25 | Fixed in walk_why's text. |
| A16 | c1_seeds' and config_seeds' unprefixed locals widen the names outside_seeds' caller must avoid. | api-consistency 7; architecture 2 | Defer (row): documented; no caller collides. |
| A17 | Commit 3111ee9d: "5 new" tests is 4 new and 1 reworked; "266 changed code lines" counts tests and comments (the gate's count). | fact-check 30a, 30c | Accepted-immutable (row); the next commit states it. |

### 🧩 Composition check

- main_imports :1650-1657, need_root order (fact-check 2, architecture 1, api-consistency 1, security 2): one defect, each states mechanism and fix completely (A1); distinct statements of one root, no composed row.
- floor :1886-1904, wording (security 1, fact-check 21-25, architecture 3, api 3/6): distinct defects (path echo, wording accuracy, structure), each stated (A2, A3, A5, A15).
- prompt_marks :1352-1363 (fact-check 8, performance 1/5): distinct (doc verified; over-read cost) (A9).

No other multi-source co-located clusters qualified.

### ✅ Confirmed Good
Routed endorsements (security, performance) are pending execution verification (Stage 2.5 skipped on a loop pass). Fact-check executed: the five changed tests fail on main's lib and pass here; truthwalk's nameref leaves IMPORTED/IMPORTED_MAIN intact; every `return 1` in main_imports reports its stated KIND.

Tokens: fc 1×216k, critics 165k + 178k + 156k + 155k ≈ 870k.
