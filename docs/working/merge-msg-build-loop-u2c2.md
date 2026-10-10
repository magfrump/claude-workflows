Merge branch 'feat/build-loop-u2c2': the walk side: floor's cost and reasons, live prompt links, config dirs in the reader key, the seed split

## What this does

U2c2 of the build-loop handoff (plan step 5, the U2c split note's walk side), all in `scripts/lib/dev-cycle-read.sh`:
- **Floor's per-path cost** (U2c1's measurement, rows 470/610/611/618): floor takes the lowered path as `$4` (build-loop.sh passes check_line's batch-lowered spelling), truthwalk and isimported share one fork-free membership test (`walk_has`), and both walks check the root only below their caches (`readers_root` before the reader set, `need_root` on a cache miss). A cached floor call: ~6.5 → ~0.6-1 ms per path (about 8-11x); `--check` over a 400-path fixture: 2.8 → 0.7 s.
- **Where a walk failed** (rows 376, 467): main_imports records `IMPORTED_MAIN_WHY` (readers, main, tree, link PATH, list, start/admit PATH, seeds, copies, read PATH, budget), and `walk_why` words it after "could not be walked for @ imports: ". A path whose characters pathform does not allow prints as `?`.
- **A path below a start file's name or an imported .md name** (U2c1 i1 security 1, row 608) is refused: a directory there keeps the file from being created.
- **Security F3** (U2b3b2c final, row 602): a live prompt link in another worktree whose real path lies below a reader root marks its projected names as prompts, so this checkout's bytes are read with the session's bases (both walks).
- **Config dirs in the reader key** (row 581): import_readers computes `IMPORT_CONFIGS` (each home's .claude, CLAUDE_CONFIG_DIR, IMPORT_MANAGED_DIR), refuses a relative or newline-holding CLAUDE_CONFIG_DIR, and both walks key on it, so contract item 4 loses that reset duty.
- **The seed split** (rows 582, 585, 589, 603): outside_seeds is a wrapper over config_seeds (items 1-2) and c1_seeds (item 3), each with its own keep-rule.

**Workflow provenance:** RPI (plan revision 4, step 5) → U2c split before code (U2c1 merged at b0b616ac; U2c2 here) → pr-prep.
← carried from RPI: D5's narrow floor read as truth, the gate caller contract (items 1-9), fail-closed walks (a failed walk refuses every path), the reader model's roots and homes.

**Failures prevented:**
- A self-merge decision taking ~3 s for 400 paths (now ~0.7 s).
- A refusal that says only "could not be walked" when one checkout file, link or setting is the cause; a crafted file name echoed into every deny row (found in review, fixed).
- A branch planting `src/CLAUDE.md/x` or `docs/imported.md/x` to keep an instruction file or import from being created.
- A live prompt link in an older worktree hiding the imports main's copy of its target makes.
- A config dir changed within a decision answered from a stale walk.

## Reviewer's path — start here

1. `floor` and `walk_why` (the lib, near the end and after the IMPORTED globals), then `walk_has`, `truthwalk`, `isimported`.
2. `readers_root`, then the first lines of `imported_names` and `main_imports` (root check order, cache keys, the `IMPORTED_MAIN_WHY=` stage markers).
3. `import_readers` (IMPORT_CONFIGS), `outside_seeds` / `config_seeds` / `c1_seeds`, `prompt_marks`.
4. `test/scripts/build-loop-check.bats`: the tests naming U2c2, rows 376/467/581/602, U2c1 i1 security 1 and final performance 1.

## How to test

- Suites, run serially: build-loop-check 143, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2. The new and reworked tests fail on main's lib (fact-check executed); the prompt_marks test fails on ac078bd7's lib.
- Both walks over this repository give main's 1593 names.
- `scripts/health-check.sh` passed at 39f71c03.

## Areas of uncertainty

- **Not panel-reviewed**: the final-pass fixes (8a64e392: walk_has answers 0 on an error list, text, the wrapper empties the seed array) were checked by the lite fix-drift check only (no findings).
- **Deferred or declined (override rows dated 2026-10-10)**: the non-.md import-name half of row 608 (Won't-Fix: the parser's prefixes make every directory an import name); row 582's repeated seed admission; unprefixed seed locals; the walk-list glob cost (now floor's main per-path cost, linear in the list: 0.33 ms at 80 KB, 18.5 ms near IMPORT_OUT_MAX); TRUTH_WHERE for both walks and one reader-settings sentence (U3, with row 472); prompt_marks' extra realpath; readers_root's name and its repeat of import_readers' memo test (cross-referenced).
- **Behaviour change**: floor's early rules (instruction files, dot paths, gate code, records, working docs) refuse without a root check, so an unset ROOT_REAL exits only for a path that reaches the walk; no caller relies on that exit (fact-checked).
- **Commit messages overtaken** (Accepted-immutable row): 3111ee9d's "5 new" tests (4 new, 1 reworked); 07af69c0's A9 claim (the fix did nothing until 2be3db37, B1); 07af69c0's "three-call wrapper" (two calls and a newline check).
- **Pre-mortem fallback**: not fired (no `auth|crypto|migration` path; LOC below 500 code lines).

Review converged in 3 iterations (iteration 2 short-circuited at fact-check on B1); 1 Must Fix (B1, fixed with a test); Must Address A1 (root check order) and A2 (crafted names in deny rows, Medium), both fixed. Rubric: `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (loop closed at 8786f8fc). 374 changed code lines.

Confidence: high
Notes: merged on the recommendation per the standing instruction (Q-137 [1]); no Q entry.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018X78L3ajw3rXEbwmifV4wc
