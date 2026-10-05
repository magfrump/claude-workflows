Commit: 497c8cb5

# API Consistency Review — feat/build-loop-u0a, final confirming pass

**Scope:** `git diff feat/build-loop-handoff..feat/build-loop-u0a` (4ef450da, 32b9ae0e, 497c8cb5) and their commit messages. Consumers: scripts/dev-cycle.sh now, the planned scripts/build-loop.sh later.
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0a.md (merged k=3, Commit 497c8cb5); override-log rows dated 2026-10-05 for feat/build-loop-u0a (196-200, 211)

Known items from the fact-check report are not re-filed here. They are the inverted "set -u fires there" comment in need_root (Claim 1), the header sentence "rawfile, plaindir and blocker then read nothing as plain" (Claim 2), and commit 497c8cb5's message (Claim 3).

## Baseline Conventions

- **scripts/lib/*.sh** (`log-format.sh`, `preflight.sh`, `md-utils.sh`, `skill-paths.sh`, `si-*.sh`) are sourced and define short functions and globals with no prefix (`red`, `green`, `bold`, `require_command`, `extract_skill_name`). They start with `#!/bin/bash`. Some have a `Functions:` index; md-utils and skill-paths do not (row 198, Won't-Fix).
- **Precondition helpers** print a message on stderr and `exit 1`: `require_command` (`scripts/lib/preflight.sh:6-12`) and, in dev-cycle.sh, `need()` and the "dev-cycle.sh needs perl" check.
- **Lib predicates** return a status and print nothing (`rawfile`, `plaindir`, `inrepo`, `dirok`, `isbrief`, `writable`). `skipped` is the exception: it sets a global and appends to another.
- **dev-cycle.sh CLI.** `--help` prints header lines 2-77. Exit codes: 0 when the digest is printed or every check argument is answered; 1 for usage errors and missing preconditions.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh` | lib file | `md-utils.sh`, `skill-paths.sh`, `si-functions.sh` | `scripts/lib/*.sh` | Consistent: a kebab-case file name with a domain prefix |
| `need_root` | function (precondition, exits) | `need`, `require_command` | `scripts/dev-cycle.sh:96` (main), `scripts/lib/preflight.sh:6` | Consistent: it uses dev-cycle's `need` verb, and it exits 1 with a message on stderr |
| need_root messages `dev-cycle-read.sh: ROOT_REAL is …` | error text | "dev-cycle.sh needs perl …", "Error: $cmd is required …" | `scripts/dev-cycle.sh`, `scripts/lib/preflight.sh:9` | Consistent: names the file that raised it, as dev-cycle.sh's messages do |
| `scrub`, `scrub_reexec`, `rawfile`, `plaindir`, `blocker`, `inrepo`, `dirok`, `skipped`, `pathform`, `isbrief`, `writable`; `SKIPPED`, `SKIP_AT`, `NAMECHARS`, `DIGIT`, `SLUG` | moved functions and globals | `red`, `bold` (functions), `READ_LIB` (global) | `scripts/lib/log-format.sh:6-14` | Consistent: moved with their names unchanged. No lib name collides with a dev-cycle.sh definition (the two definition lists share no name at this tip) |
| `ROOT_REAL` (now read by the lib) | input global | — | none — searched `scripts/lib/*.sh` for a global a caller sets as input | New category. The header documents it (`:8-12`) |

## Findings

#### 1. The header names the lib's input global but none of its output globals; `skipped` accumulates into `SKIPPED` on every call

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:8-15`, `:87`, `:106`
**Move:** #3 consumer contract (documentation)
**Confidence:** High
**Legibility-target:** for-author

Evidence (at 497c8cb5):
```
SKIPPED=(); SKIP_AT=""
```
```
skipped() { need_root; SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT"); }
```

The header documents what a caller must set: ROOT_REAL, the current directory, and `-euo pipefail`. It does not list what the lib sets. `skipped` overwrites `SKIP_AT` and appends to `SKIPPED` on every call that finds a block. No comment says so; the nearest one (`:81-86`) says only that the blocking part is "what the digest's section 8 lists". dev-cycle.sh relies on that accumulation to build section 8 (`SKIPPED` at `scripts/dev-cycle.sh` lines `records_skipped=${#SKIPPED[@]}` and `printf '%s\n' "${SKIPPED[@]}"`), so the accumulation is part of the contract. A second caller that uses `skipped` as a predicate will also fill an array it may not know exists. Row 196 deferred a test of this interface from build-loop.sh's side; this finding is about the missing documentation, not the missing test.

**Recommendation:** Add one header sentence such as: "skipped sets SKIP_AT and appends it to SKIPPED (the digest's section 8); resolve_main sets MAIN, MAIN_SHA, MAIN_BY_NAME; the walk sets IMPORTED". U1, which adds the second caller, is a good time to do it.

## What Looks Good

- **dev-cycle.sh's CLI, `--help` and exit codes match main apart from the documented missing-lib exit.** I ran 13 invocations with the main copy and this tip's copy against the same checkout, with DEV_CYCLE_TODAY pinned, and diffed stdout, stderr and exit code. The invocations were `--help`, `--bogus`, `--check-path` with no argument, `--sample=x`, `--since` with no value, every check mode with good and bad arguments, the digest, and `--since 2026-09-01 --sample 1`. All were identical except `--help` line 75, the new Exit wording ("no perl or lib/dev-cycle-read.sh"). `--help` still prints 76 lines, the whole header. In a repo on `trunk` with no main or master, the by-name modes print the same refusal and exit 1 as on main. With the lib absent, the script prints "dev-cycle.sh needs …/lib/dev-cycle-read.sh" and exits 1. `route: code-fact-check`
- **There are two guard shapes, one per kind of caller.** `need_root` stops the caller in its own shell. `rawfile` and `plaindir` fail closed inside the `$(blocker …)` substitution. So a consumer that forgets ROOT_REAL never gets a silent "plain". need_root's second test, that ROOT_REAL is the current directory, also turns a stale root into a loud stop instead of a cross-tree comparison.
- The lib is sourced from `SCRIPT_DIR` (resolved before the `cd`), so the plan's "each script sources it from its own directory" holds. The source happens before `scrub_reexec`, so the child sees the same definitions.
- bats at this tip: 56/56 ok, run in this pass.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Header documents the input global only; `skipped` accumulates into `SKIPPED` undocumented | Informational | `scripts/lib/dev-cycle-read.sh:8-15,87,106` | High |

## Overall Assessment

U0a is consistent with the scripts/lib conventions and with dev-cycle.sh's CLI. The names are unchanged by the move. The one new public function, `need_root`, follows the family's `need` idiom. Probes show the CLI unchanged except for the one documented Exit-line edit. The only new item concerns documentation for the next consumer: the header lists what goes into the lib but not what comes out. That can be fixed in place at any time, and U1 is a natural point to do it. Nothing blocks the land.

## Goal-Alignment Note

The goal is to land U0a as a behaviour-preserving extraction that build-loop.sh can share. The probes and 56/56 bats confirm dev-cycle.sh is unchanged. The lib's guards make a careless second caller stop rather than read a symlink as plain. The single finding asks that the lib's outputs be written down before that second caller arrives. It does not block U0a, and it fits U1's scope, where rows 196 and 197 are already deferred.
