# Research: put the failure-pattern steps where build loops run, and check them at the gate

- **Goal**: Every build loop runs both failure-pattern steps (RPI's lookup, recorded as the research doc's `Failure-pattern grep:` line, and pr-prep's Step 0 advisory), and `build-loop.sh --check` / `--merge` refuse a branch that skipped either.
- **Problem framing**: The loops skip the steps because nothing checks them, and the prompt never sends them to pr-prep Step 0. Considered and discarded: "a stronger prompt is enough" (the RPI text already demands the grep line, and 0 of 11 recent research docs carry it: the motive in the brief, Q-226 [5]).
- **Project state**: feat/failure-pattern-loop-wiring, dispatched at 4b2f000a, policy review (cite: docs/working/briefs/2026-10-29-failure-pattern-loop-wiring.md)
- **Task status**: complete (design decided; implementation on the same branch)

## What exists

- `scripts/build-loop.sh` (2197 lines): `check_line` is the one verdict path for `--check` and `--merge` (all authorities). It computes TIP, the merge TREE (merge-tree in a config-free gate repository, `gate_git`), the changed paths, then prints one verdict line and a `path`/`deny` line per changed path. `--merge` lands only when `VERDICT[tree]` is set, which only `verdict_ok` sets. A self-merge brief's checkout refusal (`co`) replaces the verdict line but keeps the path lines, so a loop's advisory run from its own branch still sees them.
- `loop_prompt` prints the loop's prompt; its line "Run research-plan-implement with no plan-approval gate, then pr-prep's review-fix loop." never reaches pr-prep Step 0, where the advisory lives (`workflows/pr-prep.md:51-77`).
- The RPI lookup (`workflows/research-plan-implement.md:119-150`) requires a literal `Failure-pattern grep:` line, placed under Gotchas "as a standalone bullet or sentence". Existing docs that carry it write it as a bullet (`- Failure-pattern grep: ...`).
- The library's entry form (`docs/thoughts/failure-patterns.md` Schema) is `- **FP-NNN** YYYY-MM-DD ...`; pr-prep's advisory counts additions with `^\+- \*\*FP-[0-9]+\*\*`. Main holds 167 entries, no duplicate number.
- The orchestrator runs the gate only through the D6 block (`skills/dev-cycle/SKILL.md`), which ownership-checks exactly four image files: build-loop.sh, dev-cycle.sh, questions.sh, lib/dev-cycle-read.sh. Its Collect step treats a self-merge `--merge` refusal other than paths or a conflict as the environment's (retried next iteration), and a review `--check` refusal as `stopped`.
- Test fixtures (`test/lib/build-loop-fixtures.bash`): `brief` commits a brief on main, `work` branches from main with one commit. About 50 tests assert exact `--check`/`--merge` output for such branches.

## Invariants

- `--check` prints exactly one verdict line per brief first; `--merge` replaces only that line (`tail -n +2`) and lands only on `VERDICT[tree]`.
- Every gate read goes through `gate_git` (no repo config, no checkout attributes) and refuses on any stderr (R6).
- The self-merge floor refuses `docs/thoughts/`, so a new FP entry turns a self-merge brief into a review merge (a falls-through-to-review path the orchestrator already handles). The skip line is the self-merge-compatible route.
- D6's four-file list: a new sourced lib file would run unchecked by D6 unless the canonical block changed too.

## Design (divergent design, seeded with docs/constraints.md and the brief)

### D1: where the skip reason lives

| Option | Correctable by adding a commit | Reader | Verdict |
|---|---|---|---|
| A. A trailer on each `fix(...)` commit | No: a missed trailer on an earlier commit needs a rewrite, which the loop's rules forbid | rev-list per commit | fails the loop's "only add commits" rule |
| B. A `Failure-pattern skip: REASON` line in the research doc | Yes | the research doc the check already reads | **chosen** |
| C. A trailer on any branch commit | Yes | a second reader over every message | works, but splits the two records across two places (S3) |
| D. A line in the marker commit | Yes | marker body, which `--marker` rules constrain | only ready markers matter, and their body is unchecked text; adds grammar to the marker |

B dominates (Path A): one file, one reader, next to the grep line, fixable with a later commit. The check is branch-level, as pr-prep's advisory is: a branch with any `fix(...)` commit needs at least one new FP entry or a skip line; matching entries to commits one by one is a quality judgment (out of scope, H4).

### D2: where the check code lives

- Inline in `build-loop.sh` (a helper `fp_gaps` called from `check_line`): one `git revert`, no D6 change. **Chosen.**
- A new `scripts/lib/` file: smaller unit (S8), but D6 would source an unchecked fifth file unless the canonical D6 block changed (H1, S3).
- In `scripts/lib/dev-cycle-read.sh`: shared with dev-cycle.sh, which never uses it; grows a 2211-line file the same as inline does.

S8's no-growth list names `cc-isolated.sh` and `install.sh`; build-loop.sh grows by about 60 lines. Recorded as the cost.

### D3: how the gaps are reported

- One verdict line only: a self-merge brief's advisory run from the loop's own branch always gets the checkout refusal, so the loop would never see an FP gap.
- Deny lines on the research doc or library path: a missing research doc has no changed path to hang a line on, and the "K of N changed paths" verdict would route a self-merge brief to an owner review that `--approved` refuses again.
- **Chosen**: a `gap BRIEF: WHY` line per gap after the verdict line and before the path lines, printed under every verdict that reaches them; when nothing earlier refuses (conflict, objects, checkout), the verdict is `refuse BRIEF: N failure-pattern gaps on BRANCH (gap lines follow)`. Precedence checkout > gaps > denied paths, so the owner is never asked to review a branch that cannot land. The dev-cycle skill's Collect step gets one clause: a gap refusal is the loop's, filed as `stopped`.

### D4: what each read is

- Research doc: `docs/working/research-STEM.md` in TIP's tree (the branch's committed content). Absent, not a regular file (mode other than 100644/100755), or unreadable: a gap naming it.
- Grep line / skip line: a line that, after leading blanks and an optional `- ` or `* `, starts `Failure-pattern grep:` (or `Failure-pattern skip:`) and has a non-blank character after the colon; a trailing CR dropped. Fences are not skipped: presence only (H4).
- Fix commits: `rev-list ^MAIN TIP` (main's commits and those merged in from main are excluded; that is "beyond the dispatch commit", since that commit is on main). Subject (first line) matches `^fix[(:!]`, any case. A failed listing is a gap ("could not be listed"), never zero commits (FP-070, FP-024).
- Who fixes a gap: one from a failed read says "could not be read", "listed" or "compared" and is the environment's (the dev-cycle skill retries it); every other gap (absent, not a regular file, no line, no entry, a duplicate) is the loop's and is filed `stopped` (review i1: a single "the loop's" rule would have filed an environment failure against every in-flight loop).
- New entries and duplicates: entry numbers (`^- \*\*FP-([0-9]+)\*\*`, compared as digit strings without leading zeros, so no length loses precision) in TREE's library against main's. New: a number TREE has that main lacks. Duplicate: a number TREE holds more often than main does and at least twice (blames only what the merge adds; a duplicate already on main is main's to fix). A library that exists but cannot be read is a gap.

### Collision (brief's FP-173/174 criterion)

Two branches appending at the end of the library conflict in merge-tree (already a refusal). Two that both picked FP-175 at different places merge clean; the second to land sees FP-175 twice in TREE and is refused. Collisions between branches not yet merged are out of reach (no gate sees both); the second merge catches them.

## Prior art

- pr-prep's Step 0 advisory: same counts (fix commits vs new `- **FP-` lines), printed not enforced; the gate reuses its entry pattern.
- `check_line`'s checkout refusal: a refusal that replaces the verdict but keeps per-path lines, the model for printing gap lines under any verdict.

## Gotchas

- Failure-pattern grep: FP-024, FP-070 (`grep -inE 'advisory|unenforced|presence|collid|duplicate|renumber|fail-open|vacuous'`; other hits are unrelated categories).
- FP-070 (a gate failed open on a missing sentinel and recorded a skip): an unreadable commit list or library must be a gap, not "no fix commits" or "no entries".
- FP-024 (a lint was green having scanned zero files): the test for "no fix commits passes" must sit beside one where a fix commit refuses, in the same fixture.
- Existing tests: the fixture's `brief` helper commits the brief's research doc (with a grep line) on main, so `work` branches carry it unchanged and no path line is added; the new tests remove or change it on the branch.
- Failure-pattern skip: this branch's fix commits are review-iteration fixes to code first written here; none has a root cause outside this unit.

## Files read

Last verified: 2026-10-29

docs/working/briefs/2026-10-29-failure-pattern-loop-wiring.md
docs/working/research-2026-10-28-failure-pattern-use-review.md
docs/thoughts/failure-patterns.md
scripts/build-loop.sh
scripts/lib/dev-cycle-read.sh
skills/dev-cycle/SKILL.md
workflows/pr-prep.md
workflows/research-plan-implement.md
test/lib/build-loop-fixtures.bash
test/scripts/build-loop-check.bats
test/scripts/build-loop-merge.bats
test/scripts/build-loop-orchestrator.bats
