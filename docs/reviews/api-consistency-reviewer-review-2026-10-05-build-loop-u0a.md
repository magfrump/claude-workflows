Commit: e97eefce

# API Consistency Review — feat/build-loop-u0a, iteration 2 (fix e97eefce)

> ⚠️ **No code fact-check report provided for iteration 2.** The fix commit's comment and header claims were checked against the code here, by reading and by running it. The iteration-1 report (docs/reviews/code-fact-check-report-build-loop-u0a.md) covers the move commit, whose content is unchanged.

**Scope:** `git diff feat/build-loop-u0a~1 feat/build-loop-u0a` (fix e97eefce), plus `git range-diff b5209cbc^! d7ea20b9^!` (message-only). Consumers: dev-cycle.sh now, the planned scripts/build-loop.sh later.
**Date:** 2026-10-05
**Based on:** docs/reviews/api-consistency-reviewer-review-2026-10-04-build-loop-u0a.md (iteration 1), docs/reviews/code-review-rubric-2026-10-04-feat-build-loop-u0a.md, override-log rows 196-200

## Prior findings

| Iteration-1 item | Status | Evidence |
|---|---|---|
| API Finding 1 / rubric C5: `DEV_CYCLE_SCRUBBED` not in the caller contract | **Closed** | Header `scripts/lib/dev-cycle-read.sh:10-11`: "Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker." `scrub_reexec`'s comment (`:53-54`) now says it also returns "when the caller already set DEV_CYCLE_SCRUBBED". |
| API Finding 2 / rubric C8: header shape | **Closed (shebang) / Won't-Fix (index, guard)** | `:1` is `#!/bin/bash`, the scripts/lib convention. The index and guard are logged Won't-Fix in override-log row 198. |
| Rubric A1: build-loop.sh named as an existing sharer | Resolved | lib `:2-4` "used by scripts/dev-cycle.sh and kept apart so the planned scripts/build-loop.sh can share it"; dev-cycle.sh `:84-85` likewise. |
| Rubric A2: commit Notes vs plan :187 | Resolved | range-diff shows only the message changed: "its extraction is deferred to U2 (plan amendment in U0c's fix commit)". The amendment is in U0c's a57e5d27. |
| Rubric A3: file checks fail open without ROOT_REAL | Resolved | `need_root` at `:67`, called first in `inrepo`/`dirok`/`skipped` (`:93,96,97`). `rawfile`/`plaindir` (`:68,71`) return false on an empty ROOT_REAL. New test at `test/scripts/dev-cycle.bats` "the lib's file checks stop, not pass, when the caller has not set ROOT_REAL". |
| Rubric A4: Exit line omits the missing-lib exit | Resolved | `scripts/dev-cycle.sh:75-77`: "1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch". |

## Baseline Conventions

These are unchanged from iteration 1 (scripts/lib/*.sh and their callers). Points that bear on the new names:

- Precondition helpers that `exit 1` with a message on stderr: `require_command` (`scripts/lib/preflight.sh:6-12`, "Error: $cmd is required but not installed."), and in the dev-cycle family `need()` (`scripts/dev-cycle.sh:96`, "$1 needs a value") and the top-level "dev-cycle.sh needs perl" / "dev-cycle.sh needs $READ_LIB" (`:81,88`).
- The lib's own predicates are short, unprefixed names that return a status: `rawfile`, `plaindir`, `inrepo`, `dirok`, `isbrief`, `writable`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `need_root` | function (precondition, exits) | `need`, `require_command` | `scripts/dev-cycle.sh:96`, `scripts/lib/preflight.sh:6` | Consistent: it follows the dev-cycle family's `need` verb, and it exits 1 with a stderr message like both neighbours |
| need_root's message `dev-cycle-read.sh: ROOT_REAL is not set; the caller sets it before any file check` | error text | "dev-cycle.sh needs perl …", "Error: $cmd is required …" | `scripts/dev-cycle.sh:81,88`, `scripts/lib/preflight.sh:9` | Consistent enough. The repo has no single error-wording convention. The file-name prefix says which file raised it once two scripts source the lib, and both tests match on "ROOT_REAL is not set". |

The rest of the fix adds no other public names; T29's rename is a test title.

## Findings

No findings.

## What Looks Good

- **dev-cycle.sh's CLI is unchanged apart from the documented missing-lib exit.** I ran nine invocations at this tip and at feat/build-loop-handoff and diffed stdout, stderr and exit codes: `--help`, `--bogus`, `--check-path` (no argument), `--sample=x`, `--since` (no value), `--check-brief`, `--check-answer`, `--check-fix` and `--check-branch`. Exit codes were identical (0/1/1/1/1/0/0/0/0). The only output difference is `--help` line 75, the new Exit wording. The edit keeps the header at 3 lines, so `sed -n '2,77p'` (`:107`) still prints the whole header. In a repo with no main or master, `--check-brief` and `--check-branch` give the same message and exit 1 as the base. With the lib absent, the script prints "dev-cycle.sh needs …/lib/dev-cycle-read.sh" and exits 1. `route: code-fact-check`
- **The guard has two shapes, one per kind of caller, and the comment at `:64-66` explains why.** `need_root` stops the caller in its own shell. `rawfile`/`plaindir` fail closed, because `blocker` calls them inside `$(...)`, where an exit would end only the subshell. A consumer gets a loud stop from every entry point (`inrepo`, `dirok`, `skipped`) and never a silent "plain". That replaces the iteration-1 fail-open state. `route: code-fact-check`
- The new test runs each of the three entry points under `set -euo pipefail`, the mode a consumer runs in. It asserts exit 1, empty stdout and the stderr text, and it checks the fail-closed result for `rawfile`/`plaindir` separately. bats at this tip: 56/56 ok, run in this pass.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

The fix closes both iteration-1 API findings. Finding 2 is partly closed: the index and guard are logged Won't-Fix. All four rubric Must-Address items are resolved. The one new public name, `need_root`, follows the dev-cycle family's `need` precondition idiom. dev-cycle.sh's CLI, `--help` and exit codes match the base except for the documented Exit line. Nothing blocks the land.

## Goal-Alignment Note

The goal is a pure move that leaves dev-cycle.sh's behaviour as it was and gives build-loop.sh a shared surface it can use safely. The fix adds the one behaviour change the review asked for: the file checks stop when ROOT_REAL is missing. dev-cycle.sh always sets ROOT_REAL first (`scripts/dev-cycle.sh:115`), so this change is invisible to it, and the probes above confirm that. The fix stays within its scope, and none of the deferred rows (196, 197, 200) became worse.
