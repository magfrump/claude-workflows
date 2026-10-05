Commit: 698348ac

# API Consistency Review — feat/build-loop-u0b, final confirming pass

**Scope:** `git diff feat/build-loop-u0a..feat/build-loop-u0b` (0b53fe50, fbe3a219, 698348ac) and their commit messages. Consumers: scripts/dev-cycle.sh now, scripts/build-loop.sh (plan "Script interface", "Approach") later.
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0b.md (merged k=3, Commit 698348ac); override-log rows dated 2026-10-05 for feat/build-loop-u0b (201, 208, 209)

Known items from the fact-check report are not re-filed: the header sentence (Claim 1, carried from U0a), commit 0b53fe50's "returns 1" (Claim 2), and the future build-loop.sh claim (Claim 3).

## Baseline Conventions

- The baseline from U0a still holds. Lib functions are unprefixed, predicates return a status, and precondition failures exit 1 on stderr. Lib-owned globals are UPPER_SNAKE and are initialised when the lib is sourced (`SKIPPED=(); SKIP_AT=""`).
- **Check output** has one line per argument. In dev-cycle.sh's check modes, `ok …`, `skip X: why` and `absent X` are answers, and the mode exits 0. The plan's "Approach" makes this vocabulary load-bearing for build-loop.sh: "`skip X: why` means unreadable; `refuse X: why` is a verdict" (plan `:196`).
- **Plan, "Approach":** default-branch resolution "returns instead of exiting", and build-loop.sh "resolves `MAIN_SHA` once and calls the lib directly".

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_by_name` | function (predicate) | `inrepo`, `dirok`, `isbrief` | `scripts/lib/dev-cycle-read.sh:106,109,142` | Consistent: an unprefixed status-only predicate named after the global it reads (`MAIN_BY_NAME`) |
| `MAIN`, `MAIN_SHA`, `MAIN_BY_NAME` (now lib-owned, initialised at `:227`) | globals | `SKIPPED`, `SKIP_AT` | `scripts/lib/dev-cycle-read.sh:91` | Consistent: UPPER_SNAKE, initialised when the lib is sourced |
| `resolve_main` (moved; returns 1 instead of exiting) | function | `need_root` (exits), `skipped` (sets globals, returns status) | `scripts/lib/dev-cycle-read.sh:77,110` | Consistent with the plan's "returns instead of exiting". dev-cycle.sh keeps its exit at the call site |
| `FENCE_AWK`, `oddwhy`, `check_brief`, `check_branch` | moved | `ANSWER_AWK` (main), `check_path`, `check_write` | `scripts/dev-cycle.sh` (main) | Consistent: names unchanged by the move |
| skip text `no default branch found by name (origin/HEAD, main or master), or resolve_main has not run` | message | "--check-brief needs a default branch (origin/HEAD, main or master); found none" | `scripts/dev-cycle.sh` (the CLI refusal) | Consistent: the same parenthetical list. It now also names the caller-side cause (iteration 2's Finding 1 is closed) |

## Findings

#### 1. A lib comment calls a `skip` answer "refused", in the vocabulary the plan reserves for verdicts

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:281-282`
**Move:** #4 error consistency (terminology)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `skip X: why` means unreadable; `refuse X: why` is a verdict, used in `docs/working/plan-build-loop-handoff.md:196`

Evidence (at 698348ac):
```
# The default branch is refused, and so is every name when there is no default
# branch found by name (main_by_name).
```
The code under it prints `skip $a: the default branch` and `skip …: no default branch found by name …`. The main version already said "The default branch is refused". fbe3a219 extends the word to every name. Within dev-cycle.sh, "refused" was loose but harmless. In the shared lib, build-loop.sh's author will read this comment next to a plan where `refuse` is an output word with its own exit code (writing modes exit 2 on any refusal, plan `:198`). Someone who takes the comment at its word could map these lines to a refusal.

**Recommendation:** Say "skipped" (or "answered with a skip line") in this comment. This is a two-word edit and can wait for U1.

## What Looks Good

- **dev-cycle.sh's CLI, `--help` and exit codes match main apart from U0a's documented Exit line.** These are the same 13 invocations as for U0a, run with this tip's copy against the same checkout. In a repo on `trunk`, `--check-brief` and `--check-branch` print main's refusal "… needs a default branch (origin/HEAD, main or master); found none" and exit 1. So the lib's new skip lines cannot be reached from the CLI, and its output is unchanged. `route: code-fact-check`
- **The resolve_main contract is now single-valued for a consumer.** Forgetting resolve_main, ignoring its 1, and the current-branch fallback all give the same `skip … no default branch found by name …, or resolve_main has not run` line, never `ok`. The header's rewrite (`:16-18`, "The caller runs resolve_main once per process (a second call re-reads main); … unless it returned 0 with main found by name") closes iteration 2's Finding 2 on the unclear subject.
- `check_brief` gets `need_root` (698348ac) because it calls `blocker`, which reads the working tree. `check_branch` reads only refs and does not call it. The header's exiting list (`:12`) matches that split.
- The new skip lines sanitise the echoed argument (`${a//$'\n'/ }`), as the existing pre-validation skips do.
- bats at this tip: 58/58 ok, run in this pass.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Comment calls a `skip` answer "refused" | Informational | `scripts/lib/dev-cycle-read.sh:281-282` | Medium |

## Overall Assessment

U0b is consistent. The moved names are unchanged. `main_by_name` and the initialised `MAIN*` globals follow the lib's own patterns. `resolve_main` now returns instead of exiting, as the plan asks, while dev-cycle.sh keeps its exit at the call site. The CLI is byte-identical to main apart from U0a's Exit line. Both iteration-2 findings are closed. The one new note concerns a single word in a comment, and it matters only because the plan gives `refuse` a defined meaning for the next consumer. Nothing blocks the land.

## Goal-Alignment Note

The goal is to move the brief and branch checks and the default branch into the lib, with dev-cycle.sh's output unchanged, so that build-loop.sh can resolve main once and call them directly. The probes and 58/58 bats show dev-cycle.sh unchanged. The by-name rule now lives in the lib, so build-loop.sh inherits it and does not have to copy it. Rows 201, 208 and 209 are unaffected by anything found here.
