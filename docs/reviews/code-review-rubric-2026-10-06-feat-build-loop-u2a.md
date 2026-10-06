Commit: 36b79f72
Loop-pass short-circuit: used at b9ffe7a8
# Code Review Rubric

**Scope:** full branch `main...feat/build-loop-u2a` at b9ffe7a8 (iteration 1, `--loop-pass`, delivery mode self-read); 393 changed code lines by pr-prep 1a | **Reviewed:** 2026-10-06 | **Status: 🔴 BLOCKED** — iteration 2: a behavioral fact-check Incorrect (R1 reopened), fixed in the iteration-2 fix commit

## Iteration 1 of 3 (Commit b9ffe7a8, full branch, k=1, short-circuited at fact-check)

Reports: `code-fact-check-report-build-loop-u2a.md` (k=1, 36 claims: 1 Incorrect, 7 Mostly accurate, 28 Verified; 0 Stale, 0 Unverifiable).

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| R1 | `main_imports` does not start at every regular-file instruction file on main, so floor fails open: a start path holding a newline splits at `tr '\0' '\n'` and is dropped (probe P4: `we\nird/CLAUDE.md` imports `docs/d.md`, floor prints `docs/d.md: -`), and a tree listing `CLAUDE.md` twice reads only the first copy (P2: `docs/b.md: -`). `scripts/lib/dev-cycle-read.sh:443-445`, `:502-510` | Incorrect (behavioral) | FC Claim 11a | 🔴 Fixed in 36b79f72; reopened in iteration 2 | |
| A1 | The header says floor exits through need_root; it reaches need_root only in the import arm (P1: `floor CLAUDE.md` with ROOT_REAL unset returns its refusal). `lib:15-17` | Mostly accurate | FC Claim 5 | 🟡 Fixed in 36b79f72 | |
| A2 | `ls-tree -r` "never lists what lies under a symlinked directory": a tree naming `x` as both a symlink and a directory lists `x/CLAUDE.md` (P3; the walk still fails closed at the read). `lib:502-503` | Mostly accurate | FC Claim 16 | 🟡 Fixed in 36b79f72 | |
| A3 | `docs/constraints.md` refuses as "one of the dev cycle's own files"; plan D2 and dev-cycle.sh:169 call it the user's. `lib:576` | Mostly accurate | FC Claim 21 | 🟡 Fixed in 36b79f72 | |
| A4 | `FLOOR_WHY="" # read by build-loop.sh`: no script reads it until U2c. `lib:565` | Mostly accurate | FC Claim 22 | 🟡 Fixed in 36b79f72 | |
| C1 | Row 319's short header lines `lib:13` and `lib:25` remain. | Mostly accurate | FC Claim 26 | 🟢 Won't-Fix (override row) | |

Immutable history: FC Claims 28 and 29 (Mostly accurate) are commit-message claims in cfbf34d2; see the `Accepted-immutable` override rows.

## ⏭️ Skipped Core Critics

security-reviewer, performance-reviewer, api-consistency-reviewer and architecture-review: loop-pass short-circuit (behavioral red confirmed at fact-check, Claim 11a). No enforcement file is in the diff (hooks/live-verify-gate.sh regex), so mechanic 7 does not apply. Fact-check's escalation (Claim 11a → security-reviewer) is routed to the next pass, which runs the full panel (once-per-loop bound).

Considered overrides: rows 203-320 (the U2 triggers this unit closes) were read; none settles R1 or A1-A4.

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).

## Iteration 2 of 3 (Commit 36b79f72; fact-check k=1 on `b9ffe7a8..36b79f72`, critics on the full branch)

The short-circuit was spent in iteration 1, so the full panel ran. No critic had seen the code, so the critics reviewed the whole branch rather than the fix range; the fact-check covered the fix range, and the critics read iteration 1's fact-check report (the two stages ran in parallel; a deviation from Stage 1 → Stage 2 order, recorded here).

Reports (all `Commit: 36b79f72`): `code-fact-check-report-build-loop-u2a.md` (25 claims: 16 Verified, 5 Mostly accurate, 3 Incorrect, 1 Unverifiable), `security-reviewer-review-2026-10-06-build-loop-u2a.md` (3 Medium, 1 Informational), `performance-reviewer-review-2026-10-06-build-loop-u2a.md` (1 Low, 1 Informational), `api-consistency-reviewer-review-2026-10-06-build-loop-u2a.md` (1 Inconsistent, 4 Minor, 3 Informational), `architecture-review-review-2026-10-06-build-loop-u2a.md` (5 Minor, 2 Informational; no Structural or Coupling).

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| R1 | Reopened: a directory name holding a newline can be shaped so both halves pass the record regex (a forged `120000` half), so the real start file is skipped and floor fails open (probes P8, P8b). | Incorrect (behavioral) | FC Claims 11, 15b, 16a | 🔴 Fixed in the iteration-2 fix commit | The listing stays NUL-separated (`mapfile -d ''`, with ls-tree's exit status after the last NUL); every name goes into one map, a doubled name of any kind fails the walk. Test 4: plain and forged newline names are read and their imports refused. |
| A5 | Imports reached only through a target main_entry would not read (badform such as `.github/`, `a+b.md`; untracked chains) are never followed; the tree walk refuses one of them. | Medium | security F1 (executed D1, D2, C11) | 🟡 Fixed | Targets are followed by main's map, whatever their name; a target main lacks is read from the checkout when plain. Test 5. |
| A6 | A token runs on through a non-breaking space after it (`@docs/nb.md<NBSP>for`), so the import is lost. | Medium | security F2 (executed C6) | 🟡 Fixed | import_targets ends a token at 18 UTF-8 space sequences (both walks). Test 5. |
| A7 | A2/A3 carried into the gate: symlinked start file, symlinked target, `.claude/rules/`, symlinked directory, absolute import; test 4 pinned the symlinked start as passing. | Medium | security F3 (executed) | 🟡 Partly fixed; rest acknowledged | Fixed: symlinked start files and targets are followed, `.claude/rules/**.md` start, the pinning test now expects refusal. Acknowledged: symlinked directories, case-insensitive names, absolute imports (known issue A5, override row, Q-103). |
| A8 | isimported picks its walk by string and any value but `main` runs the tree walk; floor read the IMPORTED_MAIN cache value to word a failure (row 203). | Minor / Inconsistent | architecture 1, api 2 | 🟡 Fixed | Explicit `tree`/`main` arms; 2 for a failed walk or an unknown name; floor reads the code. |
| A9 | entry_why's catch-all words any unknown main_entry word as "could not be read" (row 306's misreport). | Minor | architecture 4 | 🟡 Fixed | Explicit `error)` arm; the default names the word. |
| A10 | `plainfile` reads like plaindir's file twin; it is inrepo without need_root. | Inconsistent | api 1 | 🟡 Fixed | Renamed `inrepo_here`, with its own comment. |
| A11 | badform's comment says "a dotfile such as .gitattributes"; only `.git*` parts are refused. | Minor | api 3 | 🟡 Fixed | |
| A12 | The lib's inventory test omits the new functions and globals. | Minor | api 5 | 🟡 Fixed | |
| A13 | The lib header's opening list omits the floor; plan F10/F11 and known issues lag the code. | Minor / Informational | architecture 5, 7 | 🟡 Fixed | Header line 6; F10, F11 rows; known issue A4. |
| A14 | main_imports caches on MAIN_SHA only, though its untracked starts come from ROOT_REAL. | Informational | api 8, architecture 2 | Fixed | Keyed on "MAIN_SHA ROOT_REAL". |
| A15 | Comment wording: the symlink-and-directory tree "whose read then fails" holds for git-ordered trees only; "a name listed twice" covered instruction names only. | Mostly accurate | FC 9b, 12, 16c, 16f | Fixed (comment and code rewritten) | |
| C2-C11 | api 4, 6, 7; performance F1, F2; architecture 2, 3, 6; security F3 residue, F4; FC 5b | Consider / Informational | as listed | Override rows dated 2026-10-06 (`feat/build-loop-u2a`) | |

Composition check: one cluster, `scripts/lib/dev-cycle-read.sh` main_imports (FC 11, security F1/F3, architecture 2, api 8). Disposition: distinct defects (record parsing, target following, symlink coverage, cache key), each stated with its own mechanism and fix.

## Iteration 3 of 3 (Commit db9cc040, full branch, final confirming pass: fact-check k=3)

Replicates (all `Commit: db9cc040`): `code-fact-check-report-build-loop-u2a-r1.md` (45 claims: 2 Incorrect, 1 Stale, 10 Mostly accurate), `-r2.md` (56: 4 Incorrect, 8 Mostly accurate), `-r3.md` (43: 4 Incorrect, 9 Mostly accurate). All three replicates independently found new fail-open shapes in `main_imports`, so the pass cannot be clean: the critic panel was not dispatched and the replicates were not merged.

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| R2 | The walk's `seen` set is newline-joined: a stored or untracked name holding a newline (`q\ndocs/b.md\nr/CLAUDE.md`, `.claude/rules/zz\ndocs/a.md`) marks a real target as seen, so its imports pass floor. | Incorrect (behavioral) | r2 26a, 26d; r3 19b | 🔴 Open → U2a2 |
| R3 | Symlink text is read through `$(...)`, which drops trailing newlines: a link whose text is `notes.md\n` is followed to `notes.md`, and the real target's import passes; absolute link text is skipped silently. | Incorrect (behavioral) | r1 10; r3 19c | 🔴 Open → U2a2 |
| R4 | A stored name starting `..` (`..x.md`) is never followed (`[[ "$p" != ..* ]]`). | Incorrect (behavioral) | r3 19b | 🔴 Open → U2a2 |
| A16 | isimported's "a caller that tests it with `if` refuses" is false: `if` reads 2 as not imported. | Incorrect (comment; behavioral for a future caller) | r1 18b, r2 31b | 🟡 Open → U2a2 |
| A17 | An instruction blob holding a NUL byte loses its imports (grep reads it as binary); both walks. | r1 note, not a claim | r1 | 🟡 Open → U2a2 |
| A18 | Docs lag: lib Inputs paragraph, "Not covered (A2/A3)" cites the wrong row, known issue A4's ID collides with the preamble's fixed A4, plan step-5 note and F11, rubric R1's "of any kind", the "C2-C11" label. | Mostly accurate / Stale | r1, r2, r3 | 🟡 Open → U2a1/U2a2 |

### Iteration-4 gate decision: `split`

Iteration 3 ended with Must Fix items, so the loop is at the cap. Decision: **split** (the /away default when the unit has separable parts; review-fix-loop.md § Iteration 4).

- Convergence diagnosis: every red in three iterations is in one function, `main_imports`, and each is a name or link shape the bash string handling did not model (iteration 1: NUL turned to newline; iteration 2: forged record halves; iteration 3: the newline-joined seen set, link-text newlines, `..` names). Patching each shape does not converge.
- **U2a1** (`feat/build-loop-u2a1`, from main, fresh loop): the parts no review flagged red: main_entry's `badform` and `entry_why`, `isclosed`, `check_fix` refusing `docs/constraints.md`, U1d's carried wording and fixture rows, and the plan's U2 split note.
- **U2a2** (`feat/build-loop-u2a2`, stacked on U2a1, fresh loop): `floor`, `ownfile`, `GATE_CODE`, `isimported` and `main_imports`, redesigned to refuse what it does not model, as FENCE_AWK does: a name in main's tree or the checkout's untracked list holding a newline, symlink text that is absolute or holds a newline, and a `..`-prefixed name fail the walk (floor then refuses every path) instead of being modelled one by one. This branch's review artifacts carry over to U2a2.
- This branch (`feat/build-loop-u2a`) is not merged; it stays as the record of the three iterations.
