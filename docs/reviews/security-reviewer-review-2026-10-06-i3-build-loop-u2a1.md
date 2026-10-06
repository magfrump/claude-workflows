Commit: d07cc89c

# Security Review — feat/build-loop-u2a1 (iteration 3, final confirming pass)

**Scope:** full branch diff `git diff main...HEAD` (6f624cdf, 706e0499, d48f4645, 91469367, d07cc89c), with the enclosing functions `main_entry`, `entry_why`, `isclosed`, `writable`, `check_brief`, `check_answer` (scripts/lib/dev-cycle-read.sh), `main_file`, `shared_branches` (scripts/build-loop.sh), `check_fix` (scripts/dev-cycle.sh), both suites' setup, and the new test/scripts/fixture-git-env.bats
**Date:** 2026-10-06
**Based on:** Stage 1 fact-check k=3 at d07cc89c (docs/reviews/code-fact-check-report-build-loop-u2a1-r{1,2,3}.md); rubric docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md (iterations 1-2); override-log 2026-10-06 rows

## Trust Boundary Map

```
B1: [caller-supplied path (--check-brief / --status arg)]        → [main_by_name → pathform → main_entry word] → [read of main's blob / refusal]
B2: [main_entry word + path]                                     → [entry_why (newline fold; ${2-})]          → [skip line on stdout → scrub → orchestrating agent]
B3: [agent-proposed in-cycle fix path]                           → [check_fix denylist + check_path]          → [working-tree edit (docs/constraints.md now refused)]
B4: [brief path (argument, or listed from main's tree)]          → [isbrief / isclosed]                       → [writable (write gate), check_brief, shared_branches]
B5: [test runner's inherited env (GIT_DIR, GIT_INDEX_FILE, ...)] → [unset $(git rev-parse --local-env-vars)]  → [fixture git writes in the throwaway repo]
B6 (new, 91469367): [test runner's inherited env]                → [fixture-git-env.bats setup: no unset]     → [victim/fixture repo writes in its own setup]
```

Input-source classification:

```
S1: --check-* / --status argument path    — request-time (agent-chosen; prompt-injectable by repo text) — UNTRUSTED for read/edit/write-gate sinks and stdout line framing
S2: path listed from main's tree          — runtime-mutable (anyone who lands on main)                   — UNTRUSTED for stdout framing and gate decisions
S3: fixed names (docs/working/questions*.md, docs/constraints.md, the settings file) — code-constant  — trusted (all sinks)
S4: main_entry's word                     — derived; closed vocabulary except notdir's PART (a prefix of the asked path) — trusted as a closed set only while every consumer default-refuses
S5: inherited process environment         — run-time (git hook, user shell)                              — UNTRUSTED for "which repo a fixture git command writes to"
```

What enters: agent-chosen and tree-listed paths (S1, S2) cross B1/B4 and come back as refusal wording across B2. Iteration 2 (91469367) changes no accept/refuse decision in production code: `${2-}`, check_answer's ending and a comment are wording. It adds one boundary in test code (B6): the new suite that pins B5 has no B5 guard of its own.

## Verification of iteration-2 fixes (91469367)

| Row | Fix | Check (this pass) | Result |
|---|---|---|---|
| A7 / A9 | check_answer ends every main_entry refusal "so no entry in $f is read" | read-static: `scripts/lib/dev-cycle-read.sh:571-577`; `$f` iterates two code constants (S3), `$a` already matched `^Q-[0123456789]+$` at :569 | wording only; still `return` on every word but absent/blob |
| A8 | entry_why reads `${2-}` | executed (probe.sh): `entry_why badform` and `entry_why error` under `set -euo pipefail` with one argument | rc=0, `[not an allowed path form]`, `[the tree of the default branch could not be read]` |
| A11 | test for isclosed's prefix guard | executed: 11 isclosed/writable candidates (bypass table below) | only the canonical closed/ path is closed or writable |
| A12 | main_entry's guard order stated and pinned | read-static: `:265-266` (main_by_name, then pathform), header `:256-260` | matches; error before badform |
| A10 | new suite fixture-git-env.bats pins the B5 unset | executed with and without an inherited GIT_DIR | pins B5 as intended (control: 2/2 ok); but see Finding 1 |

## Findings

#### 1. The new fixture-git-env.bats writes into an inherited GIT_DIR in its own setup

**Severity:** Medium
**Location:** `test/scripts/fixture-git-env.bats:9-15`
**Boundary:** B6 (B5's mechanism)
**Move:** 12 (sweep every call site of the engaged primitive: fixture git writes under an inherited environment)
**Confidence:** High (executed)
**Legibility-target:** for-author-fix

**Evidence:**
```
setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    V="$BATS_TEST_TMPDIR/victim"
    git init -q -b main "$V"
    git -C "$V" -c user.name=v -c user.email=v@example.invalid commit -q --allow-empty -m only
}
```

This is iteration 1's A1 mechanism (Medium) in a file the branch adds: setup runs `git init` and `git commit` with no `unset $(git rev-parse --local-env-vars)`, so under an inherited `GIT_DIR` (a run from a git hook, row 314's scenario) both go to the inherited repo. Executed: victim repo with 1 commit on `trunk`, then `GIT_DIR=<victim>/.git bats test/scripts/fixture-git-env.bats` (TMPDIR under `/tmp/u2a1i3x-*`): both tests fail, git prints `warning: re-init: ignored --initial-branch=main`, and the victim goes to 3 commits with `refs/heads/trunk` moved to the second injected commit. Control without the inherited variable: 2/2 ok. Fact-check r3 reports the same (1→3 commits). The C7 Defer row does not cover it: its reason is "Outside this unit's files; predates it", and this file is in the unit and new; the row's own revisit trigger names this file as the place future pins go, so it should not itself be an instance. Mitigation: unlike the five C7 suites, this one fails loudly, so the write is noticed — after it has happened.

**Recommendation:** Add the same two lines as dev-cycle.bats:11-13 (comment-carrying `# shellcheck disable=SC2046` and `unset $(git rev-parse --local-env-vars)`) at the top of this setup. The inner runs set GIT_DIR/GIT_INDEX_FILE explicitly on `env`, so the unset does not weaken them.

#### 2. fixture-git-env.bats claims to cover GIT_INDEX_FILE but checks only commits and refs

**Severity:** Informational
**Location:** `test/scripts/fixture-git-env.bats:3-6, 17-21`
**Boundary:** B5
**Move:** 11 (bypass candidates for the guard the test pins)
**Confidence:** High (fact-check r2 executed the mutant; not re-run here)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# The dev-cycle and build-loop suites must keep their fixtures out of a repo
# named by an inherited GIT_DIR or GIT_INDEX_FILE (a run from a git hook, say):
...
    [ "$(git -C "$V" rev-list --all --count)" = 1 ] && [ "$(git -C "$V" for-each-ref --format=x | wc -l)" = 1 ] \
```

The production guard (the unset of git's full list) does clear `GIT_INDEX_FILE`; the gap is in the pin. Fact-check r2: a mutant unsetting only `GIT_DIR` passes both tests while the victim's index is rewritten. No current exposure; a future narrowing of the unset to `unset GIT_DIR` would go unnoticed for the index half of the claim.

**Recommendation:** Either assert the victim's index is unchanged (e.g. its hash or absence before and after), or drop GIT_INDEX_FILE from the header's claim.

## Bypass analysis (move 11)

Guardrail: isclosed in the write gate (B4), `scripts/lib/dev-cycle-read.sh:158`. Executed (probe.sh, `isclosed` and `writable` on each):

| Candidate | isclosed | writable |
|---|---|---|
| `docs/working/briefs/closed/2026-01-01-x.md` (control) | y | y |
| `closed/../2026-01-01-x.md` | n | n |
| `closed//2026-01-01-x.md` | n | n |
| `closed/closed/2026-01-01-x.md` | n | n |
| `closed/sub/2026-01-01-x.md` | n | n |
| `closed/2026-01-01-x.md\nok` (newline suffix) | n | n |
| `Closed/` (case) | n | n |
| uppercase slug `2026-01-01-X.md` | n | n |
| trailing `/` | n | n |
| leading `./` | n | n |
| short date `2026-1-01` | n | n |

The new suite test (A11) covers the no-prefix and `closedx/` cases.

Guardrail: entry_why's one-line fold (B2): unchanged since iteration 2's executed table (word and path newlines, `\r` removed by scrub). `${2-}` changes only the one-argument case, executed above.

Guardrail: the B5 unset: code unchanged since iteration 2's five hostile-environment executions; the new suite pins it (control run 2/2 ok).

Guardrail: check_fix's constraints.md refusal (B3): code unchanged since iteration 1's executed six-candidate table; not re-run.

Untested bypass candidates:
- `\r` in a reason reaching an in-process caller that does not pass stdout through `scrub` — not tested: no such caller at d07cc89c; U2a2's floor is the first possible one (row 308/324).
- `GIT_TEMPLATE_DIR` / `GIT_EXEC_PATH` (not in git's repo-local list) steering fixture runs — not tested: needs control of the runner's environment beyond a hook's inherited variables, i.e. host control.

## Endorsement Claims

- **Claim:** every current consumer of main_entry (check_brief, check_answer, main_file) refuses on every word other than `blob` and `absent` at d07cc89c, including `badform`.
  **Location:** `scripts/lib/dev-cycle-read.sh:354-359, 573-577`; `scripts/build-loop.sh:129-134`
  **Evidence:** read-static
  **Verified:** read each `case "$e"`: `blob` falls through to the read, `absent` returns ok/continue/absent, `*` returns a refusal.
  **Not verified:** brief_fields' own use of main_entry in this pass (iteration 2 read it), and U2a2's floor, the next caller.
  **route: code-fact-check**
- **Claim:** of the 11 path candidates in the bypass table, isclosed and writable accept only `docs/working/briefs/closed/2026-01-01-x.md`.
  **Location:** `scripts/lib/dev-cycle-read.sh:157-162`
  **Evidence:** executed
  **Verified:** probe.sh output, sourcing the lib at d07cc89c.
  **Not verified:** writable's callers (check_write) re-running pathform/blocker on these inputs in this pass.
  **route: code-fact-check**
- **Claim:** entry_why called with one argument under `set -u` prints a subjectless reason and returns 0.
  **Location:** `scripts/lib/dev-cycle-read.sh:286-296`
  **Evidence:** executed
  **Verified:** `entry_why badform`, `entry_why error`.
  **Not verified:** the notdir/notfile/default arms with one argument.
- **Claim:** with no inherited GIT_DIR, both fixture-git-env.bats tests pass, and with GIT_DIR at a victim they fail.
  **Location:** `test/scripts/fixture-git-env.bats:23-32`
  **Evidence:** executed
  **Verified:** two runs (above, Finding 1).
  **Not verified:** the mutant (unset replaced by `:`) failing this suite — the commit message reports it; not re-run here.

## Primitive sweep

Primitive: stdout skip-line interpolation of a path (line-framing injection)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:290` (entry_why notdir) | S4 (PART of an S1/S3 path) | fold + pathform upstream | cleared — unchanged since iteration 2 (executed there) |
| `scripts/lib/dev-cycle-read.sh:291-292` (notfile, badform) | S1/S3 via callers | fold | cleared |
| `scripts/lib/dev-cycle-read.sh:293-294` (error, default) | S4 + path | fold | cleared |
| `scripts/lib/dev-cycle-read.sh:358` (check_brief) | S1 | pathform at :347 before; `""` passed | cleared |
| `scripts/lib/dev-cycle-read.sh:576` (check_answer) | S3 | fixed names; `$a` matched `^Q-[0-9]+$` | cleared |
| `scripts/build-loop.sh:133` (main_file) | S3 | fixed names | cleared |

Primitive: fixture git writes under an inherited environment
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/lib/build-loop-fixtures.bash:15` | S5 | `unset $(git rev-parse --local-env-vars)` | cleared — iteration 2 executed; pinned by fixture-git-env.bats test 2 |
| `test/scripts/dev-cycle.bats:13` | S5 | same | cleared — pinned by fixture-git-env.bats test 1 |
| `test/scripts/fixture-git-env.bats:13-14` | S5 | none | Finding 1 (executed) |
| `test/merge-safety.bats:20-24` and four other suites | S5 | none | settled: C7 Defer row (outside the unit) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | New fixture-git-env.bats setup writes 2 commits into an inherited GIT_DIR repo | Medium | B6 | `test/scripts/fixture-git-env.bats:9-15` | High |
| 2 | fixture-git-env.bats' GIT_INDEX_FILE claim is not checked | Informational | B5 | `test/scripts/fixture-git-env.bats:3-6, 17-21` | High |

## Overall Assessment

Iteration 2's production changes are wording-only and correct: `${2-}` works with one argument, check_answer still refuses on every word but blob/absent, and isclosed holds against eleven bypass candidates. The one new item is in test code: the suite added to pin iteration 1's GIT_DIR fix repeats that fix's bug in its own setup (Medium by the floor rule, same mechanism and rating as A1; executed). It is a two-line fix in place, not an architectural issue, and is the most important thing to address before merge. No other findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-i3-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: d07cc89c` as its first line.
- **Answered:** security review of the full branch at d07cc89c; iteration-2 fixes A7-A12 checked (A8, A10, A11 executed); one new Medium (Finding 1, test code, executed) and one Informational (Finding 2, from fact-check r2).
- **Out of scope:** U2a2's floor (rows 308, 324); the C7 suites (settled Defer); re-running the constraints.md bypass table (code unchanged since iteration 1).
- **Escalate:** none (no HALT pattern). Finding 1 needs an orchestrator decision: fix in place (two lines) or a Defer row arguing an exception to C7's "outside the unit" rationale.
- **Decisions:** Finding 1 rated Medium, not Informational, for consistency with A1 and the floor rule; it is in a file this branch adds, so C7's rationale does not apply.
