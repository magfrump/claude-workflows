# Research: `si_commit_child_work` turns literal pathspecs off itself

Brief: docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md (dispatched at 10c42a29)

Failure-pattern grep: `rg -i 'pathspec|LITERAL' docs/failure-patterns.md` found no entry on literal pathspecs (only FP-051 and FP-082, unrelated literal-string checks)
Failure-pattern skip: no new cause; this moves an existing guard (5eab5704's call-site prefix, the `ensure_worktree_dir`/`wt_base` pattern) into the lib it protects, so the miss was one call site the earlier fix could not reach, already recorded in docs/working/research-2026-11-20-self-improvement-env-followups.md

Reproduction: `GIT_LITERAL_PATHSPECS=1 bats test/si-commit-child-work.bats` on 10c42a29: 8 of 15 cases fail (1-5, 7, 11, 14), each at `git add failed`.

## Findings

- `scripts/lib/si-commit.sh:94` stages with `git add -A -- . ":(exclude).si-commit-msg"`. Under `GIT_LITERAL_PATHSPECS=1` the exclude is a literal file name matching nothing, so `git add` fails ("pathspec did not match"). No other git call in the lib takes a pathspec (`rev-parse`, `diff --cached --quiet`, `commit -F`).
- 5eab5704 guarded the one caller (`scripts/self-improvement.sh` Gate 1a) with a `GIT_LITERAL_PATHSPECS=0` prefix on the function call. The unit suite calls the lib directly and had no guard, hence the 8 failures.
- The pattern to reuse (S3): a `GIT_LITERAL_PATHSPECS=0` prefix on the one git command that needs magic, as `ensure_worktree_dir` (self-improvement.sh ~217), `wt_base`, `scripts/build-loop.sh` and `scripts/dev-cycle.sh` do.

## Decisions

- Guard placement: a prefix on the `git add` call only (`GIT_LITERAL_PATHSPECS=0 "${g[@]}" add ...`; `g` starts with `env`, which passes the assignment to git). Not added to the shared `g` array, since only the add uses magic (brief criterion 2: scoped to those calls, never exported). Two options at most, so no divergent design.
- Call-site guard in `scripts/self-improvement.sh`: removed (one source, S3). The lib now owns the rule; the prefix at the call site would be a second statement of it that could drift. `test/scripts/self-improvement-clean-state.bats`'s case "an inherited GIT_LITERAL_PATHSPECS=1 still commits and merges the implementer's work" keeps the end-to-end wiring pinned without it. H2: the failure mode was already loud (every task rejected with "git add failed"), and still is if the guard regresses.

## Guard list (criterion 4)

- `scripts/lib/si-commit.sh`, `si_commit_child_work`: `GIT_LITERAL_PATHSPECS=0` on its `git add -A -- . ":(exclude)$SI_COMMIT_MSG_FILE"`; the header comment's H1 list names it.

## Tests

- New case in `test/si-commit-child-work.bats`: exports `GIT_LITERAL_PATHSPECS=1`, commits with a message file, checks the message, that the file is not in the tree, and that the caller's variable is still 1 (scoped, not exported; called without `run`, whose subshell would hide a function-wide export). Fails on the 10c42a29 lib, passes now.
- `test/si-commit-child-work.bats`: 16/16 with the variable exported and unset.
- `test/scripts/self-improvement-clean-state.bats`: 29/29 with the variable exported and unset.
- `scripts/hermeticity-lint --root .`: passes (150 files).
- `scripts/confine-tests.sh --probe`: exit 3, first line "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.", so the confined run is replaced by `scripts/run-tests.sh` plus the lint (brief criterion 3).
- `scripts/health-check.sh` on the branch (at 94bbae87, before the docs-only rubric commits): exit 0, no failing case.

## Review

- Round 1 (fresh reviewer on 064e2a38): nothing at medium. Fixed: (low) the new case's closing `[ "$GIT_LITERAL_PATHSPECS" = 1 ]` could not fail under `run`'s subshell; the case now calls the function directly. Declined: (nit) also unsetting GIT_GLOB/NOGLOB/ICASE_PATHSPECS on the add: each alone leaves the exclude working, nothing in the harness exports them, and the brief scopes the change to literal pathspecs. Left for the cycle (outside the brief's doc scope): (nit) `guides/validation-gates.md:33` lists this function's hardening but not the literal-pathspec guard.
