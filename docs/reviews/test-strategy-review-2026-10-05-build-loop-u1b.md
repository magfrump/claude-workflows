Commit: 1d79ffef

# Test Strategy: build-loop U1b (`scripts/build-loop.sh --settings`), iteration 3

**Scope:** `test/scripts/build-loop-read.bats`, `test/lib/build-loop-fixtures.bash` against `scripts/build-loop.sh --settings` (`feat/build-loop-u1a...feat/build-loop-u1b`, HEAD 1d79ffef)
**Reviewed:** 2026-10-05 (review-fix loop iteration 3, the final confirming pass)
**Budget:** the unit is at the 400-line cap, so each fix below gives its net line cost. All but one cost 0 lines.

## Method

Every mutant ran on a copy in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/test-strategy/` (`base/` plus one directory per mutant, made by `mut.sh`). Each copy also holds `docs/dev-cycle.md`, which test 4 reads from `$REPO_ROOT`. bats ran with `LC_ALL=C.UTF-8`. The unmodified suite passes 9/9. The proposed fixes went into `fixed.bats`, which I ran against the base and against every mutant.

| Mutant | Change (on a copy) | Suite at 1d79ffef | Suite with fixes G1–G3 (`fixed.bats`) |
|---|---|---|---|
| mA15 | `:82` `git cat-file blob "HEAD:$f"` (reads HEAD, not main) | killed: test 5 `:84`, test 7 `:140`; **test 9 passes** | adds test 9 `:177` (the worktree run) |
| mA15b | `MAIN_SHA="$(git rev-parse HEAD)"` after `:64` | killed: test 5 `:84`, test 7 `:140`; test 9 passes | adds test 9 `:177` |
| mR2wt | `:82` `cat "$f"` (reads the working tree) | killed: test 5 `:81`, test 7 `:140`, test 9 `:176` | same |
| mR2 | `:158` `pathform "${g%/}" glob` (A4 regression) | killed: test 7 `:130` | same |
| tR2a / tR2b | bogus first operand at test `:81` / `:130` | killed: test 5 / test 7 | — |
| mC13 | `:163` appends the tabs from `$v` to the malformed reason | killed: test 7 `:118` | same |
| **mDupOpen** | `:146` drops `never_ok=""` | **survives 9/9** | killed: test 7 `:122` |
| **mNoReplace** | `:63` drops `GIT_NO_REPLACE_OBJECTS=1` | **survives 9/9** | killed: test 5 `:88` |
| mErrAbsent | `:79` `error) FILE_WHY=absent` | survives 9/9 | survives (G4, deferred) |
| mReadFail | `:83` `\|\| { FILE_WHY=...; return 1; }` → `\|\| true` | survives 9/9 | survives (G4, deferred) |

I read `main_file` (`:71-88`) and `read_settings` (`:127-179`) whole, plus the lib's `main_entry` and `resolve_main`. Only `resolve_main` sets `MAIN_SHA`. `never_ok` is set only at `:128` and cleared at `:146` and `:163`. It is read only at `:170`.

## Test Conventions

- bats ≥ 1.5 (`run --separate-stderr`). Each test gets a hermetic throwaway repo from `bl_setup` (`test/lib/build-loop-fixtures.bash:7-19`).
- `settings LINE...` commits `docs/dev-cycle.md`. `settings_is` and `settings_like KEY WANT` run `--settings` and assert one line. `line KEY` greps one key's line.
- At 1d79ffef every multi-assertion line uses `;` or `[ … ] && [ … ] || { …; return 1; }`. No bare non-final `&&` is left: R2 is fixed (see below).

## Untested Paths Touched by the Change

- **G1** — `scripts/build-loop.sh:146` — when two never lines exist, `never_ok=""` must turn a `Build-loop policy: self-merge` line off. The duplicate cases at `test/scripts/build-loop-read.bats:120-127` assert only the never line. Not covered: mDupOpen passes 9/9 and prints `policy self-merge set:` with a malformed never line, which fails open.
- **G2** — `scripts/build-loop.sh:63` — `GIT_NO_REPLACE_OBJECTS=1`, the guard against a `refs/replace` ref that swaps main's settings blob (A6, escalation E4). Not covered: mNoReplace passes 9/9.
- **G3** — `test/scripts/build-loop-read.bats:170-177` — the linked-worktree run. The worktree's HEAD (`wt`) is still main's commit, so test 9 cannot tell main from the worktree's HEAD (E2). Partially covered: the working-tree half is fixed (mR2wt kills test 9). The HEAD half is open (mA15 passes test 9). T4 and T45 still kill the HEAD mutant.
- **G4** — `scripts/build-loop.sh:79` and `:82-83` — main_file's `error` arm (main_entry reports a duplicate-name tree or a failed ls-tree) and its failed-read arm (`git cat-file` fails). Not covered (E4): mErrAbsent and mReadFail both pass 9/9. Both stay fail-closed for policy. Under each mutant, a missing blob printed `policy review unset` and `never none: no line starts …` instead of `never malformed: docs/dev-cycle.md could not be read …`.
- **G5** — `scripts/build-loop.sh:101-105` and the copy list at `test/scripts/build-loop-read.bats:123-124` — a copy behind letter-bearing markup is hidden (`- [x] Self-merge never: b/`). I executed it: lines `Build-loop policy: self-merge`, `Self-merge never: a/`, blank, `- [x] Self-merge never: b/` print `policy self-merge set` and `never a/ set`. Not covered, and the code is wrong. Escalation E1 owns the code decision; this entry only records the regression pin.

## Recommended Tests

#### Duplicate never lines turn self-merge off

**Closes gaps:** G1
**Type:** integration (CLI contract)
**Priority:** high
**File:** `test/scripts/build-loop-read.bats:121` (0 net lines: append to the line)
**What it verifies:** the policy line is the fail-closed message when the never line is malformed because it has a second copy.
**Key cases:**
- `:121` → `settings_is never 'never malformed: more than one line starts "Self-merge never:" (lines 2 and 3)'; settings_like policy "policy review unset: line 1 reads self-merge"`. The base passes. mDupOpen fails test 7 at that line.
- Optional, also 0 lines: add the same `settings_like policy` assertion inside the `:125-126` copy loop.

**Setup needed:** none.

- **Location:** `scripts/build-loop.sh:146`
- **Evidence:** `elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"; never_ok=""`
- **Confidence:** high (mutant executed, and the fix executed against it)
- **Legibility-target:** whoever next edits read_settings' never branch (U1c, U2). The T45 title promises "turns self-merge off" for every malformed shape, but only the single-line shapes pin it.

#### A replace ref cannot change main's settings

**Closes gaps:** G2
**Type:** integration
**Priority:** medium
**File:** `test/scripts/build-loop-read.bats`, after `:87` (+1 line, or 0 net if appended to `:87`, which makes a long line)
**What it verifies:** `--settings` reads main's own blob even when `refs/replace` names a substitute.
**Key cases:**
- `git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(printf 'Build-loop slots: 9\n' | git hash-object -w --stdin)"; settings_like slots "slots 7 set:"`. The base passes 9/9. mNoReplace fails test 5 at this line.
- Do not put the replace ahead of the test's checkout or merge. I tried it at `:79`, and git then saw the replaced blob as local changes, so `git merge -q loop` aborted.

**Setup needed:** none. This line comes last in T4, after main holds `slots 7`.

- **Location:** `scripts/build-loop.sh:62-63`
- **Evidence:** `# Read main's own objects: a replace ref could swap in any settings blob.` / `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1`. Executed in a scratch repo: with a replace ref pointing at `Build-loop policy: self-merge\nBuild-loop slots: 9`, mNoReplace printed `policy self-merge set` and `slots 9 set`. The base printed main's real lines.
- **Confidence:** high
- **Legibility-target:** U3b and the gate authors, who must keep the same guard. A loop shares the repo's refs, so it can plant a replace ref.

#### The linked worktree's own HEAD differs from main

**Closes gaps:** G3
**Type:** integration
**Priority:** low
**File:** `test/scripts/build-loop-read.bats:172` (0 net lines: append to the line)
**What it verifies:** from a linked worktree whose branch has committed a different policy, `--settings` still reads main.
**Key cases:**
- `:172` → `…; done; git -C "$BATS_TEST_TMPDIR/wt" commit -qam lower`. The base passes. mA15 and mA15b now also fail test 9 at `:177`.

**Setup needed:** none.

- **Location:** `test/scripts/build-loop-read.bats:171-172`
- **Evidence:** `git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub` / `for d in . "$BATS_TEST_TMPDIR/wt"; do printf 'Build-loop policy: review\n' > "$d/docs/dev-cycle.md"; done`. Test 9 passes under mA15.
- **Confidence:** high
- **Legibility-target:** the reader of test 9's comment "it reads the same main". **Answer to E2:** this is a low test gap, not amber. The behaviour it would catch (reading HEAD) is already killed by T4 (`:84`) and T45 (`:140`), so what is left is that test 9's comment promises more than test 9 alone checks. The fix costs 0 lines.

## What NOT to Test

- **G4 (main_file's error and failed-read arms), deferred.** Both mutants keep `POLICY=review` and change only the never line's word (`none` instead of `malformed`) and its reason. Pinning the failed-read arm would cost +1 line: delete the blob's loose object after `settings`, then `settings_is never "never malformed: docs/dev-cycle.md could not be read from the default branch"`. I executed that repro by hand. Pinning the `error` arm needs a hand-built tree with a duplicate name, which costs more than the arm's risk. Revisit when U2's gate first reads `NEVER_LINE`'s word: at that point `none` would let a gate skip the refusals. Suggested override-log row: Defer, trigger U2.
- The `POLICY=review; NEVER=()` reset at `:130` (C3) and the `NEVER` array's contents (A8). No mode at this commit reads either in-process, so neither can be observed through the CLI. Test them with U1c's `--status`.
- C14–C17 (reason strings for "not an allowed glob form" and "twice", review policy with a malformed never line, slots for an absent or unread file, `-h`) are settled as Defer, so they are not re-raised here.

## Iteration-2 items in my domain

| Item | Status at 1d79ffef | Evidence (mutant executed) |
|---|---|---|
| R2 (dead `&&` operands at old `:80`, `:126`) | ✅ Resolved | Now `;` at `:81` and `:130`. tR2a (bogus first operand at `:81`) kills test 5. tR2b (`:130`) kills test 7. mR2 (the A4 regression) kills test 7 at `:130`. |
| A15 (no test told main from HEAD) | ✅ Resolved | mA15 (`HEAD:$f`) and mA15b (`MAIN_SHA` = HEAD) kill test 5 at `:84` (HEAD on `loop`) and test 7 at `:140`. |
| A14 (subdir/worktree test could not tell what it read) | 🟡 Half resolved | Working-tree half: mR2wt kills test 9 at `:176`. Worktree-HEAD half: mA15 passes test 9 (G3, low, 0-line fix). |
| C13 (no-echo check missed tabs) | ✅ Resolved | `:117` now checks `*$'\t'*`. mC13 (echo the tabs in the reason) kills test 7 at `:118`. |

## Coverage Gaps Beyond Current Scope

**1.** E1 (security-reviewer or orchestrator): letter-bearing markup in front of a key hides a second copy. When the code is fixed, add `'- [x] Self-merge never: b/'` to the `:123-124` list and `'- [x] Build-loop policy: review'` to `:33-34` (0 lines). Both fail at 1d79ffef.

**2.** Fact-check caveat on Claim 39: a prose line in the real `docs/dev-cycle.md` that starts "Self-merge never …" or "Build-loop slots …" is caught only for the policy key by test 4. This is U5's concern, when that file is rewritten.

## Summary

At 1d79ffef the iteration-2 test defects R2, A15 and C13 are fixed, and mutants confirm each fix. A14 is half fixed. The highest-value addition is G1: a 0-line assertion that a second never line turns self-merge off. Removing `never_ok=""` at `:146` passes the whole suite and leaves self-merge on, the one fail-open regression the suite cannot see. G2, the replace-ref guard (E4), costs one line and pins a defence a loop could otherwise silently lose. G3 answers E2 as a low, 0-line gap, because T4 and T45 already catch a HEAD reader. G4 (main_file's error arms) stays fail-closed for policy and is best deferred to U2. If the cap allows only 0-net fixes, take G1 and G3 now, and take G2 by appending it to `:87`.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/test-strategy-review-2026-10-05-build-loop-u1b.md, structured per the test-strategy skill.
- Answered: yes. Gaps G1–G5 come with executed mutants, and the fixes for G1–G3 were verified against the base and against their mutants. E2 is answered (G3, low, 0 lines) and so is E4 (G2 medium; G4 low, deferred). R2, A14, A15 and C13 are re-checked by mutant.
- Out of scope: E1's code fix (security reviewer or orchestrator; only its 0-line test pin is noted). Settled C14–C17. U1c's modes.
- Escalate: G1. A fail-open regression (self-merge stays on when there are two never lines) is invisible to the suite, and the fix costs 0 lines; it is for the author before merge. G4 needs a Defer row (trigger U2) if it is not fixed.
- Decisions I made: I rated G1 high, not medium. The code is correct today, but the mutant is a one-token fail-open on the unit's central safety property, and the fix is free. I placed G2's replace ref at the end of T4, because placing it earlier broke the test's merge.
