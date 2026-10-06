Commit: d48f4645

# Security Review — feat/build-loop-u2a1 (final confirming pass)

**Scope:** full branch diff `git diff main...HEAD` (6f624cdf, 706e0499, d48f4645), with the enclosing functions: `main_entry`, `entry_why`, `check_brief`, `check_answer`, `pathform`, `scrub` (scripts/lib/dev-cycle-read.sh); `main_file`, `read_settings`, `shared_branches`, `status_line` (scripts/build-loop.sh); `check_fix` (scripts/dev-cycle.sh); both bats setups
**Date:** 2026-10-06
**Based on:** Stage 1 fact-check k=3 at d48f4645 (docs/reviews/code-fact-check-report-build-loop-u2a1-r{1,2,3}.md); iteration-1 rubric docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md; override-log rows 204, 228, 292, 306-325

## Trust Boundary Map

```
B1: [caller-supplied path (--check-brief / --status arg; U2a2: a changed path)] → [pathform → main_entry word]       → [read of main's blob / refusal]
B2: [main_entry word + path]                                                    → [entry_why (newline fold, A2)]     → [skip line on stdout → scrub → orchestrating agent]
B3: [agent-proposed in-cycle fix path]                                          → [check_fix denylist + check_path]  → [working-tree edit of user-owned docs/constraints.md]
B4: [brief paths listed from main's tree (git grep -l)]                         → [isbrief / isclosed]               → [writable, check_brief, shared_branches decisions]
B5 (moved: now both suites): [test runner's inherited env (GIT_DIR, GIT_CONFIG_PARAMETERS, ...)] → [unset $(git rev-parse --local-env-vars)] → [git writes in the fixture repo]
```

Input-source classification:

```
S1: --check-* / --status argument path       — request-time (agent-chosen; prompt-injectable by repo text) — UNTRUSTED for read/edit sinks and stdout line framing
S2: path listed from main's tree             — runtime-mutable (anyone who lands on main; any branch author from U2a2) — UNTRUSTED for stdout line framing and gate decisions
S3: fixed names (docs/dev-cycle.md, docs/constraints.md, docs/working/questions*.md) — code-constant — trusted (all sinks)
S4: main_entry's word                        — derived; closed vocabulary except notdir's PART (a prefix of the asked path) — trusted as a closed set only while every consumer default-refuses
S5: inherited process environment            — run-time (hook context, user shell)                         — UNTRUSTED for "which repo fixture git commands write to"
```

What enters: agent-chosen paths (S1) and tree-listed paths (S2) cross B1/B4; refusal wording crosses B2 to an agent that treats any line starting `ok ` as a positive answer. Iteration 1's fixes move the newline fold into the shared mapping (B2) and extend the environment scrub to the second suite with git's own list (B5). No new boundary is introduced by d48f4645.

## Verification of iteration-1 fixes

| Row | Fix | Check (this pass) | Result |
|---|---|---|---|
| A1 / C5 | `unset $(git rev-parse --local-env-vars)` in dev-cycle.bats `setup()` and `bl_setup` | Executed: victim repo (1 commit, branch `trunk`), then `GIT_DIR=<victim>/.git GIT_CONFIG_PARAMETERS="'core.hookspath'='/nonexistent'" bats -f 'check-fix refuses files an instruction file imports' test/scripts/dev-cycle.bats`, and `GIT_DIR=<victim>/.git GIT_INDEX_FILE=<scratch>/idx bats test/scripts/build-loop-read.bats` (all 19) | Tests pass; victim still 1 commit, no new branch, 0 replace refs |
| A1 robustness | the unset relies on `git rev-parse --local-env-vars` succeeding under the hostile env it is meant to clear | Executed with `GIT_DIR=/nonexistent`, a malformed `GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT=2` with no keys, a cwd repo with a broken `.git/config`, and `GIT_DIR` at that broken repo (git 2.39.5) | Full 16-name list printed in every case: the command reads no repo or config, so the unset cannot silently become `unset` with no arguments |
| A2 | entry_why folds `\n` in `$1` and `$2` | Executed: `entry_why $'notdir a\nok b' x`, `entry_why $'odd\nok b' $'p\rok q'`; the suite's new test covers `$2` | One line each; `\r` passes entry_why but is deleted by `scrub` (`tr/\000-\010\013-\037\177//d`), which both scripts install via `scrub_reexec` |
| A3 / A4 | `$2` optional; check_brief passes `""`; main_file names `$f` in the error arm; check_answer wording | Read-static: all three call sites (lib:354, lib:573-574, build-loop.sh:133); each still returns a refusal on every word but `blob`/`absent` | No arm changed its accept/refuse decision; wording only |
| A5 / A6 | comments | Read | No security content |

## Findings

#### 1. Five other bats suites still write fixture commits into an inherited GIT_DIR repo

**Severity:** Informational (out of diff scope; pre-existing)
**Location:** `test/merge-safety.bats:20-24`; also `test/cc-push.bats:35-36`, `test/scripts/archive-working-docs.bats:97,114`, `test/si-clean-state.bats:40`, `test/cc-isolated-functions.bats:1489`
**Boundary:** B5
**Move:** 12 (sweep every call site of the engaged primitive: fixture git writes under an inherited environment)
**Confidence:** High for merge-safety.bats (executed); Medium for the others (read-static: `git init` with no unset of the repo-local variables)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# test/merge-safety.bats:20-24
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  REPO=$(mktemp -d)
  cd "$REPO" || return 1
  git init -q -b main
```

This diff fixes the mechanism for its own two suites (A1, verified above), and `rg -n 'local-env-vars|unset GIT_DIR' test/` now finds only those two. Executed: with `GIT_DIR` pointing at a victim repo (1 commit), `bats -f 'merge_landed is false for a merge' test/merge-safety.bats` printed `warning: re-init: ignored --initial-branch=main` and left the victim at 3 commits with a new branch `task` checked out. Same exposure row 314 named (a run from a git hook). Not introduced by this branch and in no file it edits, so it is not a blocker for U2a1; it is recorded so the sweep is complete.

**Recommendation:** File a Defer override row (trigger: the next edit of any of these suites, or a shared test helper) to add the same `unset $(git rev-parse --local-env-vars)` line to each setup.

No findings within the diff.

## Bypass analysis (move 11)

Guardrail: entry_why's one-line fold (B2), the guard iteration 1 added.

| Candidate | Result |
|---|---|
| `\n` in the path (`$2`), e.g. `a\nok b` with badform | tested (suite test, lib): `a ok b is not an allowed path form` |
| `\n` in the word (`$1`) for notdir and the default arm | tested (executed this pass): one line; no caller can produce such a word (fact-check r3: the mutant survives) |
| `\r` in the path | tested: entry_why leaves it; `scrub` on both scripts' stdout deletes it, so no second line and no overwrite on a terminal |
| U+2028 / U+0085 line separators | read-static: `scrub` removes `\xE2\x80[\xA8-\xAE]` and `\xC2[\x80-\x9F]`; pathform's ASCII-only NAMECHARS refuses them before main_entry anyway |
| an in-process caller that does not pass through scrub (U2a2's floor if it runs without `scrub_reexec`) | listed below |

Guardrail: check_fix's `docs/constraints.md` refusal (B3): unchanged since iteration 1's six-candidate executed table (case, `//`, `./`, `..`, symlink alias, trailing dot: all refused; control `docs/notes.md` ok). Not re-run; the d48f4645 change to dev-cycle.sh is comment-only.

Guardrail: the B5 unset: candidates hostile `GIT_DIR`, malformed `GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT` without keys, broken cwd config: all executed above, list printed in full. `GIT_CONFIG_KEY_n`/`VALUE_n` are not in the list but are inert once `GIT_CONFIG_COUNT` is unset (read-static, git config docs behaviour; not executed separately).

Untested bypass candidates:
- `\r` reaching an in-process caller that prints entry_why's reason without `scrub` — not tested: no such caller exists at d48f4645; U2a2's floor is the first possible one.
- `GIT_TEMPLATE_DIR` / `GIT_EXEC_PATH` (not repo-local, so not in git's list) installing hooks or binaries into fixture runs — not tested: setting them needs control of the runner's environment beyond a hook's inherited variables, i.e. host control.

## Endorsement Claims

- **Claim:** every current consumer of main_entry (check_brief, check_answer, main_file, brief_fields) still refuses on every word other than `blob` and `absent` after d48f4645.
  **Location:** `scripts/lib/dev-cycle-read.sh:312, 350-355, 568-575`; `scripts/build-loop.sh:129-134`
  **Evidence:** read-static (Stage 1 executed the same property at d48f4645)
  **Verified:** read each case/compare; `grep -n main_entry scripts/*.sh scripts/lib/*.sh` lists no other caller.
  **Not verified:** U2a2's floor, the next caller (override row 324).
  **route: code-fact-check**
- **Claim:** with `GIT_DIR` (and `GIT_INDEX_FILE` / `GIT_CONFIG_PARAMETERS`) pointing at another repo, dev-cycle.bats' check-fix test and all 19 build-loop-read.bats tests leave that repo unchanged.
  **Location:** `test/scripts/dev-cycle.bats:11-13`; `test/lib/build-loop-fixtures.bash:11-15`
  **Evidence:** executed
  **Verified:** victim repo commit count 1 before and after, no new branch, 0 replace refs.
  **Not verified:** the other 73 dev-cycle.bats tests under a victim GIT_DIR in this pass (Stage 1 ran the whole suite).
  **route: code-fact-check**
- **Claim:** `git rev-parse --local-env-vars` prints its full list under a nonexistent `GIT_DIR`, a malformed `GIT_CONFIG_PARAMETERS` and a broken repo config, so the unset line does not degrade to a no-op.
  **Location:** `test/scripts/dev-cycle.bats:13`; `test/lib/build-loop-fixtures.bash:15`
  **Evidence:** executed (git 2.39.5)
  **Verified:** five hostile-environment invocations, 16 names each.
  **Not verified:** other git versions on the host that runs the suites.
- **Claim:** entry_why's output is one line for a newline in either argument.
  **Location:** `scripts/lib/dev-cycle-read.sh:283-292`
  **Evidence:** executed
  **Verified:** the suite's entry_why test plus two direct probes (word and path).
  **Not verified:** callers that print the reason without `scrub` (none at d48f4645).
  **route: code-fact-check**

## Primitive sweep

Primitive: stdout skip-line interpolation of a path (line-framing injection)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:286` (entry_why notdir) | S4 (PART, a prefix of an S1/S3 path) | fold + pathform upstream | cleared — one line (executed) |
| `scripts/lib/dev-cycle-read.sh:287-288` (notfile, badform) | S1/S3 via callers | fold (A2) | cleared — one line (executed) |
| `scripts/lib/dev-cycle-read.sh:289-290` (error, default) | S4 + path | fold | cleared |
| `scripts/lib/dev-cycle-read.sh:354` (check_brief) | S1 | pathform before, `""` passed | cleared |
| `scripts/lib/dev-cycle-read.sh:573-574` (check_answer) | S3 (`$a` matched `^Q-[0-9]+$`) | fixed names | cleared |
| `scripts/build-loop.sh:133` (main_file) | S3 | fixed names | cleared |

Primitive: fixture git writes under an inherited environment
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/lib/build-loop-fixtures.bash:15` | S5 | `unset $(git rev-parse --local-env-vars)` | cleared — executed |
| `test/scripts/dev-cycle.bats:13` | S5 | same | cleared — executed |
| `test/merge-safety.bats:24` | S5 | none | Finding 1 (executed) |
| `test/cc-push.bats:35-36`, `test/scripts/archive-working-docs.bats:97,114`, `test/si-clean-state.bats:40`, `test/cc-isolated-functions.bats:1489` | S5 | none seen | Finding 1 (read-static; outside the diff) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Five other suites still write into an inherited GIT_DIR repo (outside the diff) | Informational | B5 | `test/merge-safety.bats:20-24` (+4 files) | High (merge-safety), Medium (others) |

## Overall Assessment

The iteration-1 fixes are correct and introduce nothing new: A1/C5's unset holds against a hostile GIT_DIR, index and GIT_CONFIG_PARAMETERS in both suites, and git's variable list prints even under a broken environment, so the fix cannot quietly do nothing; A2's fold keeps every entry_why reason on one line, and `scrub` covers the `\r` it leaves. A3/A4 change wording only; every main_entry consumer still refuses on any word but blob/absent. No findings within the diff; the one Informational item is the same GIT_DIR exposure in five suites this branch does not touch, worth a Defer row. No findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-final-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d48f4645` as its first line.
- **Answered:** security review of the full branch diff at d48f4645; iteration-1 fixes A1-A6 and C5 checked (A1, A2 executed); no new in-diff finding; one out-of-diff Informational (Finding 1).
- **Out of scope:** U2a2's floor (rows 308, 324); re-running the constraints.md bypass table (code unchanged since iteration 1); the other 73 dev-cycle.bats tests under a victim GIT_DIR (Stage 1 ran them).
- **Escalate:** none.
- **Decisions:** Finding 1 rated Informational rather than filed against this unit: it is in no file the branch edits.
