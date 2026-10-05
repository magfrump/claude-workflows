Commit: b5209cbc

# API Consistency Review — feat/build-loop-u0a (U0a: scrub, file rules, pathform, isbrief/writable into scripts/lib/dev-cycle-read.sh)

**Scope:** `git diff feat/build-loop-handoff..feat/build-loop-u0a` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats); consumer = dev-cycle.sh today and the planned scripts/build-loop.sh (plan rev 4, "Approach" and "Script interface")
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0a.md (Stage 1; its Stale Exit-list finding, its Incorrect present-tense build-loop.sh references and its Incorrect check_fix commit Note are not re-filed here)

## Baseline Conventions

Surveyed `scripts/lib/{log-format,preflight,md-utils,json-utils,skill-paths,si-functions,si-input,si-morning-summary}.sh` and the five scripts that source them (`scripts/{skill-usage-report,self-improvement,flag-removal-candidates,health-check}.sh`).

- **File naming:** kebab-case, noun-ish (`skill-paths.sh`, `md-utils.sh`, `si-functions.sh`), mode 644 (one exception, `si-morning-summary.sh`, is 755).
- **Header:** `#!/bin/bash` on all eight siblings, then a one-line purpose comment. The three caller-specific `si-*` libs add "Sourced by scripts/self-improvement.sh — do not execute directly.", a `Functions:` index and a `BASH_SOURCE[0] == $0` execution guard; the five generic libs have neither.
- **Sourcing:** `# shellcheck source=lib/X.sh` then `source "$SCRIPT_DIR/lib/X.sh"` (or `$REPO_ROOT/scripts/lib/X.sh`), unguarded. No caller checks that the lib exists.
- **Function names:** snake_case, mostly verb_noun (`require_command`, `extract_yaml_frontmatter`, `jq_update_inplace`, `classify_skill_path`); short unprefixed names exist too (`red`, `green`, `bold` in log-format.sh).
- **Failure convention:** helpers return status; the one precondition helper (`require_command`) prints to stderr and `exit 1`.
- **Environment:** no sibling lib reads an environment variable as a control marker.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh` | lib file | `skill-paths.sh`, `si-functions.sh`, `md-utils.sh` | `scripts/lib/*.sh` | Consistent: kebab-case, owner prefix like `si-` |
| `scrub_reexec` | function | `require_command`, `jq_update_inplace`, `extract_skill_name` | `scripts/lib/{preflight,json-utils,skill-paths}.sh` | Consistent: snake_case verb_noun |
| `READ_LIB` | caller variable | `SCRIPT_DIR`, `REPO_ROOT` | `scripts/skill-usage-report.sh:16-19`, `scripts/health-check.sh:57-62` | New pattern (the siblings inline the path); justified by the existence check, see What Looks Good |
| `DEV_CYCLE_SCRUBBED` (now a lib contract) | env marker | none | none — searched `scripts/lib/*.sh` for env vars read as markers | New category — see Finding 1 |
| `rawfile`, `plaindir`, `blocker`, `inrepo`, `dirok`, `skipped`, `pathform`, `isbrief`, `writable`, `SKIPPED`, `SKIP_AT`, `NAMECHARS`, `DIGIT`, `SLUG` | moved functions / globals | `red`, `green`, `bold` (short unprefixed lib names) | `scripts/lib/log-format.sh:6-14` | Consistent (moved verbatim; no collision with any dev-cycle.sh name — `comm` of the two definition lists is empty) |

## Findings

#### 1. `DEV_CYCLE_SCRUBBED` becomes part of the shared lib's contract without being named in its caller contract

**Severity:** Informational (floor: no-precedent downgrade from Minor)
**Location:** `scripts/lib/dev-cycle-read.sh:6-10`, `scripts/lib/dev-cycle-read.sh:50-58`
**Move:** #2 naming / #3 consumer contract
**Confidence:** Medium
**Legibility-target:** for-author

No existing precedent in scripts/lib/*.sh (searched for environment variables a sourced lib reads as a control marker)

Evidence (at b5209cbc):
```
# Sourced, never run: it only defines functions and variables. Each script
# sources it from its own directory (never from the repo it acts on), so a copy
# of scripts/ with its lib/ is self-contained. The caller sets -euo pipefail,
# cds to the repo root and sets ROOT_REAL (that root, symlinks resolved) before
# calling any file check.
```
```
scrub_reexec() {
  [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0
  local self="$1"; shift
  { DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub
  exit "${PIPESTATUS[0]}"
}
```

Before the move the marker was private to one script. In the lib it is the skip switch for every script that calls `scrub_reexec`, so build-loop.sh (plan: "`scrub` and its re-exec wrapper" are shared) will skip its own scrub whenever `DEV_CYCLE_SCRUBBED` is set in its environment, and the env-prefix assignment exports it to every descendant of a scrubbed child. The header's caller contract lists `-euo pipefail`, the cd and `ROOT_REAL` but not this variable, and the name says "dev cycle" while it will gate build-loop.sh too. No current behaviour changes (dev-cycle.sh is the only caller; the env semantics are verbatim), so this is a convention being set, not a break.

**Recommendation:** Add one clause to the header contract ("`scrub_reexec` returns at once when `DEV_CYCLE_SCRUBBED` is set; any script calling it shares that switch"), so U3b's build-loop.sh author knows the switch is shared. Renaming is optional and cheaper now than after build-loop.sh lands.

#### 2. Lib header departs from both sibling header shapes

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1-10`
**Move:** #1 baseline
**Confidence:** High
**Legibility-target:** for-author

Precedent: `#!/bin/bash` shebang used in scripts/lib/{json-utils,log-format,md-utils,preflight,si-functions,si-input,si-morning-summary,skill-paths}.sh; "Sourced by … — do not execute directly" + `Functions:` index + `BASH_SOURCE[0] == $0` guard used in scripts/lib/si-*.sh

Evidence: `#!/usr/bin/env bash` (`:1`) and `# Sourced, never run: it only defines functions and variables.` (`:6`) with no guard.

The lib uses its caller's shebang (`scripts/dev-cycle.sh:1` is `#!/usr/bin/env bash`) rather than the lib directory's, and it is a caller-specific multi-function lib like the `si-*` ones but carries no execution guard or function index. Running it directly is harmless (it only defines things, which T29 checks), so the guard's absence has no consumer impact; the index would help build-loop.sh's author find the ~20 names the lib will hold after U0c.

**Recommendation:** Optional: `#!/bin/bash` for the directory's convention, and a `Functions:` index once U0c settles the list. No change needed to land U0a.

## What Looks Good

- `scrub_reexec` takes the script to re-run as an argument (`scrub_reexec "${BASH_SOURCE[0]}" "$@"`, `scripts/dev-cycle.sh:89`) instead of reading `BASH_SOURCE` itself, which inside a sourced lib would name the lib. That is the right shape for a second caller. `route: code-fact-check` (FC Claim 10 verifies the exit status and completeness hold).
- The existence check plus `READ_LIB` (`scripts/dev-cycle.sh:85-88`) departs from the siblings' bare `source`, but deliberately: D6 extracts a copy of `scripts/` and the message names the missing path; T30 pins it. `# shellcheck source=lib/dev-cycle-read.sh` follows the sibling directive form.
- The lib reads no global it does not define except `ROOT_REAL` (and, from U0b, `MAIN`/`MAIN_SHA`) and `DEV_CYCLE_SCRUBBED`: a grep of every `$UPPER` reference at the U0c tip found nothing else, so it does not silently depend on dev-cycle.sh's `GIT_LITERAL_PATHSPECS`, `TODAY` or `CHECK`.
- dev-cycle.sh's CLI is unchanged: header lines 1-79 are byte-identical to feat/build-loop-handoff's, and `--help`, `--bogus`, `--check-path` (no arg), `--sample=x` and `--since` (no value) give identical output and exit codes against the base (probe run at the U0c tip, which contains this unit). The only new exit is the missing-lib exit 1, whose absence from the Exit line is FC Claim 1's. `route: code-fact-check`
- Moved names are unchanged, so dev-cycle.sh's internal call sites need no edits; no lib name shadows a dev-cycle.sh definition.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `DEV_CYCLE_SCRUBBED` is a shared skip switch not named in the lib's caller contract | Informational | `scripts/lib/dev-cycle-read.sh:6-10,50-58` | Medium |
| 2 | Lib header matches neither sibling header shape (shebang, guard/index) | Informational | `scripts/lib/dev-cycle-read.sh:1-10` | High |

## Overall Assessment

U0a is consistent with the repo's lib conventions where they are uniform (file naming, function naming, `shellcheck source=` directive, return-status helpers) and departs only where it has a reason (the existence check). dev-cycle.sh's consumer-facing CLI is unchanged. Both findings are informational notes on the contract a second caller will read: name the shared env switch in the header before build-loop.sh adopts it. Nothing blocks the land.

## Goal-Alignment Note

The unit's goal is a pure move that keeps dev-cycle.sh's behaviour and gives build-loop.sh a usable shared surface. On the first half, the CLI probes and the fact-check's executed evidence (56/56 bats at the U0c tip in this pass too; digest byte-identical per FC) agree: nothing consumer-visible changed beyond the documented missing-lib exit. On the second half, the surface is shaped correctly for a second caller (`scrub_reexec` takes `self`), and the remaining gap is documentation of the implicit contract (Finding 1), which is cheapest to close before U3b writes the first other caller. Findings stay inside this unit's diff; the check_fix plan deviation is FC Claim 22b's and is not re-filed.
