# Test Strategy: build-loop handoff

**Scope:** the changes planned in `docs/working/plan-build-loop-handoff.md`: the new `scripts/build-loop.sh` (`--policy`, `--status`, `--start`, `--check`, `--merge`), the new `scripts/lib/dev-cycle-read.sh` extracted from `scripts/dev-cycle.sh`, and the edits to the dev-cycle skill and docs. Compared against the plan's test table T1–T25.
**Reviewed:** 2026-10-02 (no code exists yet. Line references point at the plan, or at `scripts/dev-cycle.sh` for the code being extracted.)

## Test Conventions

- **Framework:** bats (≥ 1.5, `bats_require_minimum_version 1.5.0`, `run --separate-stderr`). Script suites live in `test/scripts/<script>.bats`. Shared helpers are `.bash` files next to the suite (as in `test/skills/helpers.bash`).
- **Category tag:** every `.bats` file needs `# @category fast|slow` in its header, or `scripts/run-tests.sh` refuses it (run-tests.sh:270-293). `dev-cycle.bats` is tagged `fast`, even though every test builds a git repo. The three planned files (`build-loop-read.bats`, `build-loop-check.bats`, `build-loop-merge.bats`) should copy that tag. The merge suite builds worktrees, so time it. If it runs much over about 1 s per test, tag it `slow`.
- **Hermetic setup** (dev-cycle.bats:8-34): `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, a fixed author and committer, `HOME` inside `$BATS_TEST_TMPDIR`, and a throwaway repo from `make_repo` with three `--no-ff` merges on `main`. Assertions use `[[ "$output" == *…* ]]` and `|| { echo "$output"; return 1; }` to print diagnostics. The plan adds a `git log --oneline --all` dump on failure. Put it in `build-loop-helpers.bash` as one function.
- **Hermeticity lint:** `test/fixture-hermeticity.bats` runs `scripts/hermeticity-lint` over every suite. The `--start` prompt names `claude`. If the lint reads that literal as a spawn, the new suites need a PATH stub for `claude` in `setup()` or an `# @network: allowed — <reason>` opt-out. Find out by running `run-tests.sh test/fixture-hermeticity.bats` once the script exists.
- **Prior art for scripts copied out of the repo:** dev-cycle.bats:322-331 copies `scripts/` to `$BATS_TEST_TMPDIR/tools` and runs it from a subdirectory. Reuse that pattern for the lib-location tests.

## Untested Paths Touched by the Change

These are gaps that T1–T25 do not close, plus T rows too loosely specified to catch the bug they target.

- **G1** — plan:46,62 (F22) — `--merge` when main **is** checked out in some worktree, clean and on main (for example `/workspace`). The plan says only that such a worktree "must be clean and on main". It does not say what happens next. A compare-and-swap (CAS) `update-ref` would leave that checkout's index and tree at the old main, so the merge shows up there as staged reverts. T22 tests "not checked out anywhere" and T23 tests "dirty / left main". The clean-and-on-main arm is not covered, and its contract is undecided.
- **G2** — plan:16,62 — which copy of the gate runs. Under self-merge, the loop runs `--merge` itself, presumably from its own worktree. Its branch can edit `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, or the sibling `dev-cycle.sh` that the gate calls. S rules refuse `scripts/` in the diff, but the edited script is the one deciding that. No T row covers this, and the contract is undecided: refuse unless the running script, the lib and `dev-cycle.sh` match MAIN_SHA's blobs? Or require running from a checkout of main? Confirm the contract before writing the test.
- **G3** — plan:54,74; dev-cycle.sh:79-125 — output scrub. The extraction list (step 1) leaves out `scrub` and the re-exec. `build-loop.sh` still prints text taken from the repo: `Branch:`, `Paths:` entries in refuse lines, marker reasons, the policy reason, and output passed through from `dev-cycle.sh`. Nothing asserts that this output is free of control and bidi characters. T13 covers only changed path names.
- **G4** — plan:59-62; dev-cycle.sh:397 — a brief with `Branch: main` (the default branch), `Branch: master`, or `Branch: HEAD`. `--check-branch` prints `skip …: the default branch`, but `--status`, `--start`, `--check` and `--merge` each have to turn that into a skip or a refuse. On `Branch: main`, the ancestry check (MAIN ancestor of TIP) passes trivially and the diff is empty, so `--check` could print `ok`. T8 tests "a bad name", which does not include a valid name that is the default branch.
- **G5** — plan:59,67 — a marker that is not the branch's own commit. A branch fresh from `--start` has TIP = MAIN_SHA (0 commits ahead). If main's tip is itself an empty `handoff: ready` commit (from an earlier fast-forward), a loop that has done nothing reads as `ready`. The same applies to a marker on a parentless (orphan) root commit. T6 and T7 cover neither case, and the LOOP value for a branch 0 commits ahead is unspecified.
- **G6** — plan:59,68,158 — `--status` with several arguments. The output needs one line per argument in argument order, with ok and skip lines mixed and exit 0. The plan batches `dev-cycle.sh` calls into one per mode. Mapping the batched output back to arguments is where an off-by-one would put one brief's state on another brief. Not covered.
- **G7** — plan:58,68 — `--policy` input edge cases: `docs/dev-cycle.md` absent from main, a symlink (mode 120000) or a non-blob on main, or present only in the working tree. Also the case where no default branch is found by name, which should exit 1. T2's "none" case covers only a file with no matching line.
- **G8** — plan:60 — `--start --dir` and the default directory. Cases: DIR exists and is non-empty; DIR starts with `-`; DIR is outside the repo or under `.git`; the slug for `.claude/wt-<slug>` derived from the brief's file name; and a failed `worktree add` that leaves a branch behind. T24 covers only refusals based on brief or branch state.
- **G9** — plan:61-62 — the passing path under the **review** policy. A change under `scripts/`, `hooks/` or `skills/` must pass `--check` (S rules not applied) and must merge with `--merge`. No T row has a passing case under review; T14 tests only refusals. If S rules leaked into review mode, every review-mode merge would be refused.
- **G10** — plan:66 — how `Paths:` is parsed and matched. Cases: the entry `docs/foo/` must not admit `docs/foobar.md` (match on component boundaries); an entry without a trailing `/` matches exactly one file, not a prefix; an empty `Paths:` line; two `Paths:` lines (the first unfenced one wins); a malformed entry (`..`, leading `/`, `*`, non-ASCII). For the malformed case, the plan does not say whether the entry is ignored or the whole brief is refused. T10 tests only entries that the denylist refuses.
- **G11** — plan:47-48 (F23, F24) — the negative side of the own-files allowlist: another loop's `plan-<other-slug>.md`, `plan-<slug>.md` in a subdirectory, an unlisted prefix such as `notes-<slug>.md`, and a modified (not added) own working doc. Also: when `Paths:` lists `docs/reviews/`, which rule wins, the listing or "only added files under `docs/reviews/`"? T9 has only the passing case.
- **G12** — plan:61,68 — exit codes and output with several violations. `--check` with violations should exit 0, print one `refuse` line per violation, and print no `ok` line. `--merge` with a violation should exit 2 and leave main unchanged. Usage errors (no mode, two modes, an unknown flag, a missing BRIEF, `--expect` without a value) should exit 1. Only T17 asserts a usage error.
- **G13** — plan:62 — repeated or empty merges: a second `--merge` after a successful one, a tip already reachable from main, and a branch whose only commit is the marker (empty diff). After a successful merge, the ancestry check fails with the misleading "merge main in first".
- **G14** — plan:46,62 — side effects of the temporary worktree. After a success, a refusal, or a CAS failure, `git worktree list` must show no temporary entry, and no temporary directory or stray ref may remain. Also open: whether `.git/hooks/post-merge` or `pre-merge-commit`, or a `core.hooksPath` set in the repo, run in the temporary worktree during the merge.
- **G15** — plan:63-66 (F2, F13); T5 and T21 under-specified — `--check` and `--merge` must read `Branch:`, `Policy:` and `Paths:` from main's commit, not from the tip's copy of the brief or the working tree. T21 pins this only for `--start` and `--status`. T5 does not say where the brief's `Policy:` is read from. A loop that widens `Paths:` or raises `Policy:` on its own branch is exactly family F2. T15 refuses the blob change, but only if that check itself reads the right version.
- **G16** — plan:74; dev-cycle.sh:147 — where the lib is sourced from. `dev-cycle.sh` and `build-loop.sh` must source `$SCRIPT_DIR/lib/dev-cycle-read.sh`, never the target repo's `scripts/lib/`: the installed copy serves any project, and a project may ship its own `scripts/lib/dev-cycle-read.sh`. A missing lib must produce a clear error on stderr and exit 1, not a partial digest. T25 pins behaviour, not where the lib comes from.
- **G17** — T22 under-specified — "a concurrent main move between check and update" needs a deterministic way to inject the move. A race is not reproducible. Without a named seam (an env hook in the script, or a wrapper `git` on PATH that moves main on the first `update-ref`), this case will be written as a sleep, or not at all.
- **G18** — T6, T7 and T19 under-specified. T6 asserts only LOOP, not the SHA, DATE, POLICY and BRANCH fields of the `ok` line. T7 has no boundary case for the reason (120 characters vs 121, an empty `handoff: stopped: `, a subject with a trailing space). T19 does not assert that the prompt names the policy in effect, or that it leaves out the brief's body text, which is the F21 injection channel.
- **G19** — plan:82-83 — a contract between the script and the real settings file. The real `docs/dev-cycle.md` has `Build-loop policy: review (interim; Q-103)` on line 7, and line 18 quotes the exact lines inside backticks in mid-line text. U4 rewrites this file. No test runs `--policy` on the real file, so a doc edit that silently flips the parse result would go unnoticed.
- **G20** — plan:60-61 — running from inside a linked worktree (the loop's own) or from a subdirectory. Cases: MAIN resolution; the root that the default `--dir` is relative to (a worktree nested inside the loop's worktree); and `--check` and `--merge` behaving the same as from the main checkout.

## Recommended Tests

The test names below are the case titles. Files follow the plan's split.

#### Merge when main is checked out clean

**Closes gaps:** G1
**Type:** integration
**Priority:** high
**File:** `test/scripts/build-loop-merge.bats`
**What it verifies:** a clean checkout of main in another worktree ends either updated or refused. It is never left with a stale index.
**Key cases:**
- In the throwaway repo, the primary worktree is on `main` and clean. A loop branch has one allowed change. Run `--merge --expect <tip>`. Expect either (a) main merged and `git -C <primary> status --porcelain` empty with HEAD at the new merge, or (b) a refuse naming the checked-out worktree, with main unchanged. Assert whichever contract the plan settles on.
- The same with main checked out in a *secondary* linked worktree rather than the primary one.

**Setup needed:** a contract decision for the clean-and-on-main arm (add it to the plan's F22 row first).

#### The gate refuses to run as a branch-modified copy

**Closes gaps:** G2
**Type:** integration
**Priority:** high
**File:** `test/scripts/build-loop-merge.bats`
**What it verifies:** a self-merge cannot be approved by a `build-loop.sh`, lib or `dev-cycle.sh` that differs from main's.
**Key cases:**
- Copy the scripts into the throwaway repo's `scripts/` and commit them on main. On the loop branch, edit `scripts/build-loop.sh` to always print `ok`. From the loop's worktree, run `bash scripts/build-loop.sh --merge … --expect <tip>`. Expect a refuse (or whatever the chosen contract is), with main unchanged.
- The same with only `scripts/lib/dev-cycle-read.sh` edited.

**Setup needed:** the contract decision. If the contract is "the user always runs `--merge` from a checkout of main", record it in Q-103 next to F19 and mark this test as a documentation check instead.

#### Output carries no control or bidi bytes

**Closes gaps:** G3
**Type:** property (a table over a fixed set of hostile byte strings)
**Priority:** medium
**File:** `test/scripts/build-loop-read.bats`
**What it verifies:** no repo-derived byte outside the allowed charsets reaches stdout or stderr.
**Key cases:**
- A brief on main with `Branch: x\033]52;…`, `Paths: docs/a\u202e.md`, and `Policy: self-merge\r\x1b[2J`. Run `--status` and `--check`, and assert that the output has no `$'\033'`, `\xe2\x80\xae` or `\r`.
- A marker commit with subject `handoff: stopped: ok\u2066x`. Expect the reason printed as `unreadable` and no bidi bytes.
- A `dev-cycle.sh` skip line passed through for a brief path with a newline. Expect one output line.

**Setup needed:** none beyond the shared helper. Mirrors dev-cycle.bats:94 ("the scrub strips…").

#### The default branch as a brief's branch

**Closes gaps:** G4
**Type:** integration
**Priority:** high
**File:** `test/scripts/build-loop-read.bats` (`--status`, `--start`) and `test/scripts/build-loop-check.bats` (`--check`, `--merge`)
**What it verifies:** `Branch: main|master|HEAD` never yields `ok`, a worktree, or a merge.
**Key cases:**
- `Branch: main`. Expect `--status` → `skip … default branch`, `--start` → refuse with no worktree created, and `--check` and `--merge --expect $(git rev-parse main)` → refuse, with main unchanged.
- `Branch: HEAD` and `Branch: refs/heads/x` → skip in every mode.

#### LOOP state for a branch with no commits of its own

**Closes gaps:** G5, G18
**Type:** unit
**Priority:** medium
**File:** `test/scripts/build-loop-read.bats`
**What it verifies:** a marker counts only if it is a commit on the branch that main does not already contain.
**Key cases:**
- Main's tip is an empty `handoff: ready` commit, and the branch was just created at main. Expect LOOP `working` (or `absent`/`started`, once the plan names the state for 0 commits ahead), not `ready`.
- An orphan branch whose single root commit is empty with subject `handoff: ready`. Expect not `ready`.
- For the T6 cases, also assert the SHA field equals `git rev-parse refs/heads/<b>`, the DATE field equals `%cs` of the tip, and the POLICY field matches the stricter-of result.
- Reason boundaries: 120 allowed characters → printed; 121 → `unreadable`; `handoff: stopped: ` (empty reason) → `unreadable`; `handoff: ready ` (trailing space) → `working`.

#### Several briefs in one `--status` call

**Closes gaps:** G6
**Type:** integration
**Priority:** medium
**File:** `test/scripts/build-loop-read.bats`
**What it verifies:** each output line belongs to its argument, in order.
**Key cases:**
- Pass four briefs in this order: A open with `Branch: a` at `ready`, B not a brief path (skip), C fenced (skip), and D open with `Branch: d` absent. Expect four lines, in that order, each naming its own brief and branch, and exit 0.
- The same brief twice → two identical lines.

#### `--policy` file-shape edge cases

**Closes gaps:** G7
**Type:** unit
**Priority:** medium
**File:** `test/scripts/build-loop-read.bats`
**Key cases:**
- No `docs/dev-cycle.md` on main, but one in the working tree with `self-merge` → `policy review` and a reason starting `unset:`.
- `docs/dev-cycle.md` committed as a symlink to a file that says self-merge → review.
- `docs/dev-cycle.md` as a directory on main → review.
- A repo whose only branch is `trunk` (no origin/HEAD, main or master) → exit 1 with a message on stderr. Same shape as dev-cycle.bats:766.

#### `--start` directory handling

**Closes gaps:** G8, G20
**Type:** integration
**Priority:** medium
**File:** `test/scripts/build-loop-merge.bats` (the U3 suite, where `--start` lands)
**Key cases:**
- Default DIR: brief `2026-01-01-foo-bar.md` → worktree at `<root>/.claude/wt-foo-bar`, on branch `Branch:`, with HEAD equal to MAIN_SHA.
- `--dir` naming an existing non-empty directory → refuse, with `git show-ref refs/heads/<b>` empty afterwards (no branch left behind).
- `--dir -x`, `--dir ../outside`, `--dir .git/x` → refuse (or a usage error), with no branch and no worktree.
- Run `--start` for brief B from inside brief A's linked worktree. Expect the default DIR to resolve against the main checkout's root, not against A's worktree (or a refuse; assert the chosen contract).

#### The review policy passes what self-merge would refuse

**Closes gaps:** G9
**Type:** integration
**Priority:** high
**File:** `test/scripts/build-loop-check.bats`
**What it verifies:** S rules apply only under self-merge, and N rules still apply under review.
**Key cases:**
- Policy review. The branch changes `scripts/x.sh`, `hooks/y`, `skills/z/SKILL.md`, and a path not in `Paths:`. Expect `--check` → `ok BRIEF SHA review`, and `--merge --expect` → main merged with parents (MAIN, SHA).
- The same branch with the policy at self-merge → one refuse per path.
- Policy review with `docs/roadmap.md` also changed → refuse. This is the T14 cross-check in the same fixture, to show both arms come from one switch.

#### `Paths:` matching semantics

**Closes gaps:** G10
**Type:** unit (a table of entry → changed path → verdict)
**Priority:** high
**File:** `test/scripts/build-loop-check.bats`
**Key cases:**
- `Paths: docs/foo/` with change `docs/foobar.md` → refuse; with `docs/foo/a.md` → ok.
- `Paths: docs/foo.md` with change `docs/foo.md/x`. This is impossible as a file, so use `docs/foo.md.bak` → refuse.
- `Paths:` empty → only own files are allowed.
- Two `Paths:` lines, the second wider → the first is used.
- `Paths: docs/../hooks/x`, `Paths: /docs/x`, `Paths: docs/*.md`, `Paths: dоcs/x` (Cyrillic о) → that entry admits nothing (or the brief is refused; assert the chosen contract), and the output does not echo the raw bytes.

#### The own-files allowlist refuses lookalikes

**Closes gaps:** G11
**Type:** integration
**Priority:** medium
**File:** `test/scripts/build-loop-check.bats`
**Key cases:**
- Self-merge with slug `foo`. Each of these → refuse: added `docs/working/plan-bar.md`, `docs/working/sub/plan-foo.md`, `docs/working/notes-foo.md`, and `docs/working/plan-foo.md.orig`.
- `docs/working/plan-foo.md` already on main and modified by the branch → assert the contract (allowed, or added-only like reviews).
- `Paths: docs/reviews/` plus a *modified* existing `docs/reviews/r.md` → refuse (the added-only rule wins), or ok if the plan decides the listing wins. Write the decision into F23.

#### Exit codes and multiple violations

**Closes gaps:** G12
**Type:** integration
**Priority:** medium
**File:** `test/scripts/build-loop-check.bats`
**Key cases:**
- Three denied paths under self-merge. `--check` exits 0 and prints exactly three `refuse` lines and no `ok` line. `--merge --expect <tip>` exits 2, `git rev-parse main` is unchanged, and no new worktree exists.
- `build-loop.sh` with no arguments, `--status --check b`, `--frob`, `--merge` with no BRIEF, and `--merge b --expect` with no value. Each exits 1 with a message on stderr.

#### Repeated and empty merges

**Closes gaps:** G13
**Type:** integration
**Priority:** medium
**File:** `test/scripts/build-loop-merge.bats`
**Key cases:**
- `--merge` succeeds. Run the same command again → a refuse or skip that says "already merged" (not "merge main in first"), and main is unchanged.
- A branch whose only commit is a `handoff: ready` marker → assert the contract (refuse "nothing to merge", or merge an empty `--no-ff`).

#### The temporary worktree leaves nothing behind

**Closes gaps:** G14, G17
**Type:** integration
**Priority:** medium
**File:** `test/scripts/build-loop-merge.bats`
**Key cases:**
- After a successful `--merge`, after a refused one, and after a CAS failure: `git worktree list --porcelain` shows the same entries as before, `git for-each-ref` shows no new refs, and the temp parent directory is empty.
- CAS failure, made deterministic: a wrapper `git` on PATH moves `refs/heads/main` to a new commit just before passing through the first `update-ref`, or the script offers a documented test seam. Expect a refuse, with main at the wrapper's commit rather than a merge built on the stale base. The wrapper approach needs no seam in the product code, so prefer it.
- A `.git/hooks/post-merge` that touches `$BATS_TEST_TMPDIR/hook-ran`, and `core.hooksPath` set to a tracked `.githooks/` directory. Assert whether the hook ran, matching the plan's decision (recommendation: merge with `-c core.hooksPath=/dev/null` or through `merge-tree`/`commit-tree`, and assert the marker file is absent).

#### Machine lines are read from main in `--check` and `--merge`

**Closes gaps:** G15
**Type:** integration
**Priority:** high
**File:** `test/scripts/build-loop-check.bats`
**Key cases:**
- Main's brief has `Paths: docs/a.md` and `Policy: review`. On the loop branch, the brief says `Paths: docs/ hooks/` and `Policy: self-merge`, and the working tree has a third variant. With the policy setting at self-merge and a change to `docs/b.md`, expect a refuse for `docs/b.md` (main's `Paths:` was used). The POLICY field should also read `review` (main's brief, stricter-of).
- The loop branch changes `Branch:` in its brief → the gate still evaluates the branch named on main.

#### The lib comes from the script's own directory

**Closes gaps:** G16
**Type:** integration
**Priority:** medium
**File:** `test/scripts/dev-cycle.bats` (next to the subdirectory test at line 322)
**Key cases:**
- Copy `scripts/` to `$BATS_TEST_TMPDIR/tools`. In the throwaway repo, commit a `scripts/lib/dev-cycle-read.sh` that creates `$BATS_TEST_TMPDIR/pwned`. Run `tools/dev-cycle.sh --check-brief …` and `tools/build-loop.sh --policy` → normal output and no `pwned` file.
- Delete `tools/lib/dev-cycle-read.sh` → exit 1, stderr names the missing lib, and stdout is empty (no partial digest).

#### Contract with the real settings file

**Closes gaps:** G19
**Type:** contract
**Priority:** low
**File:** `test/scripts/build-loop-read.bats`
**What it verifies:** the repo's own `docs/dev-cycle.md` parses to the policy its prose claims.
**Key cases:**
- Copy `$REPO_ROOT/docs/dev-cycle.md` into the throwaway repo and commit it. Expect `--policy` → `review` with an `unset:` reason while the interim suffix is present. When Q-103 is answered, the expectation changes in the same commit, which is the point.

## What NOT to Test

- **F19 and F11 mechanically:** a loop running plain `git merge`/`git push`, and files that instruction files pull in with `@` imports. The plan leaves both uncovered on purpose and lists them in Q-103. T20 (a static check for `push`) is the cheap check, and more would be theatre. The same applies to the loop running `--merge` itself under the review policy: no test can tell whether the user or the loop ran it.
- **macOS case-insensitive behaviour on a real filesystem:** the plan accepts this risk (plan:160). The lower-cased comparisons in T10 and T14 cover the logic.
- **Skill and doc prose (U4):** checked by code-fact-check in U4's review loop, as the plan says. A grep test that "SKILL.md mentions every mode" would be brittle and low-value.
- **Re-testing the lib's functions through `build-loop.sh`:** `FENCE_AWK`, `pathform` and `INSTRUCTION_FILE` already have about 30 tests in dev-cycle.bats. T1–T3 and T8 need one fixture per refusal *class* to prove the wiring, not the full matrix again.
- **Performance of the batched `dev-cycle.sh` calls:** the plan names the cost (plan:158), and briefs are capped at 3 slots.

## Coverage Gaps Beyond Current Scope

**1.** `dev-cycle.sh --help` prints the header by fixed line range (`sed -n '2,77p'`, dev-cycle.sh:141), and no test covers it. If step 1 changes the header length, the help text truncates silently. One assertion that `--help` output ends with the exit-status paragraph would catch it. `build-loop.sh` should not copy the fixed-range pattern.
**2.** No test exercises `dev-cycle.sh --check-brief` and `--check-branch` from inside a linked worktree, which is where the loop will call them. Shared refs make it likely to work, but nothing pins it.

## Summary

The highest-value additions are the review-policy passing case (G9), the `Paths:` matching table (G10), and reading machine lines from main in `--check`/`--merge` (G15). T1–T25 test almost only refusals and policy text. They never show that the review arm lets ordinary work through, or that the allowlist matches at component boundaries.

Two gaps are contract questions to settle before any test can be written:

- **G1:** what `--merge` does when main is checked out clean somewhere.
- **G2:** whether a self-merge may be run by a branch-modified copy of the gate.

G2 is effectively a third uncovered bypass family next to F11 and F19. If the answer is "not mechanically covered", it belongs in Q-103.

G3 matters because the extraction leaves out the scrub. Either move `scrub` into the lib or add the byte-filter test. G17 should be closed with a PATH-wrapper `git`, not a product-code seam.
