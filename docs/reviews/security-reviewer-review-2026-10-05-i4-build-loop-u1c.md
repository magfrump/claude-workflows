Commit: 13380172

# Security Review — feat/build-loop-u1c, iteration 4 (fix commit 13380172)

**Scope:** 32bef87b..13380172 (scripts/build-loop.sh, test/scripts/build-loop-read.bats, docs/reviews/override-log.md); context: scripts/lib/dev-cycle-read.sh check_brief/brief_fields/isbrief
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1c.md (Stage 1, k=1)

Focus: whether 13380172 closes R1, the bug where colour config or a failing `git grep` emptied F31's set of shared branches, so F31's skip turned off without any error. Also whether the new `SHARED_BRANCHES=error` state opens a new way to fail open.

## Trust Boundary Map

```
B1: [repo/global git config (color.*, grep.*, core.*, submodule.*)] → [git grep --no-color -l -E ... (:307), rc check (:308)] → [SHARED_BRANCHES set]
B2: [main's committed brief blobs + .gitattributes]                 → [git grep match, then isbrief + brief_fields (:311-313)] → [SHARED_BRANCHES set]
B3: [SHARED_BRANCHES (process-global, :300)]                         → [status_line gates (:320, :335, :336)] → [ok/skip line consumed by dispatcher]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | repo-local `.git/config` | runtime-mutable (any git command, other sessions) | UNTRUSTED toward the F31 skip decision (it must not be able to turn the skip off); trusted for availability (a broken config may stop dispatch) |
| S2 | global config (`$GIT_CONFIG_GLOBAL`/`~/.gitconfig`) | runtime-mutable | as S1 |
| S3 | brief blobs on main's commit | runtime-mutable (merges to main) | UNTRUSTED for parsing; brief_fields reads them |
| S4 | caller env (GIT_*, PATH, LC_ALL) | request-time | trusted, settled by override rows 276/280/281 |
| S5 | `SHARED_BRANCHES` | code-set at :300 (overwrites any env value), then :308/:315 | internal |

The diff does not move any boundary. It hardens B1: the colour config is neutralised, and an exit status above 1 now sends B3 to a closed state, so every open brief skips. B2 and B3 are unchanged, apart from the closed/ prefix anchor (C30) and a local BRIEF (C29).

## R1 closure: probes executed

Hermetic repo in my scratch dir, using the fixture env (GIT_CONFIG_NOSYSTEM=1, a private GIT_CONFIG_GLOBAL file, HOME and LC_ALL=C). The repo holds open briefs a (`feat/x`) and b (`Feat/X`), a done brief c, and a new path n. Each run was `--status a c n` under `timeout 20`. I set each key in repo config and then in global config, and unset it before the next run.

| Config | Result (a / c / n) | git grep outcome |
|---|---|---|
| baseline | skip-shared / ok done / ok new | 0 |
| color.ui=always, color.grep=always, color.grep.filename=red (local and global) | skip-shared / ok / ok | 0, `--no-color` wins |
| grep.patternType=perl, fixed, basic; grep.extendedRegexp=false | skip-shared / ok / ok | the command line's `-E` overrides the config |
| grep.fullName=true, core.quotePath=true, grep.column=true, grep.lineNumber=true, grep.threads=0, core.ignoreCase=true, grep.fallbackToNoIndex=true, submodule.recurse=true, core.bigFileThreshold=1 | skip-shared / ok / ok | no change to the `-l` output |
| `.gitattributes` `* binary`; `*.md -text diff=foo` with textconv=false | skip-shared / ok / ok | `-l` still lists binary matches; no textconv without `--textconv` |
| grep.patternType=bogus, grep.threads=-1, grep.column=notabool (local and global) | **skip-error** / ok done / ok new | 128, fails closed |
| a `git` PATH shim that SIGKILLs itself on `grep` | skip-error | 137, fails closed |
| a's blob deleted from the object store | a: skip "could not be read"; b: ok | 0 with `error:` lines (partial result); covered by override row 293 (an unreadable brief is not counted) |

Test suite: `bats test/scripts/build-loop-read.bats` (LC_ALL=C.UTF-8) gave 0 `not ok`, and T28 passes.

**R1 is closed.** No repo or global config I tried makes the `-l` output change format. None makes the pattern match nothing while exiting 0 or 1. Every config failure I produced exited 128, which leads to `SHARED_BRANCHES=error`.

## Fail-open sweep of the new error state

- **Paths before :335:** in status_line (:318-355), every return before :335 either prints a `skip` (:322, :325, :326, :327, :331) or prints `ok … new` (:324). A `new` result is never `open`, so no open brief reaches `ok` before the :335 gate. Done and dropped briefs go past :335/:336, because both gates are conditioned on `"$st" == open`. Verified by execution: c prints `ok … done` and n prints `ok … new` while SHARED_BRANCHES=error.
- **Is SHARED_BRANCHES read before it is set?** It is read only in status_line, and :320 computes it first. Assignment :300 overwrites any value from the environment. The normal path (:315) always starts the value with `\n`, so it can never equal the literal `error`, even when a branch is named `error`.
- **Exit status under `set -euo pipefail`:** shared_branches runs on the right of `||` (:320), so errexit is suspended inside it. In the error arm, `return` returns 0 (the status of the assignment). The script exits 0 with the error expressed per brief as a skip line. That is fail-closed for dispatch.
- **Partial failure with exit 0** (missing blob): settled by row 293. Its premise is unchanged.

## Findings

No findings.

## Untested bypass candidates

- `git grep` built without PCRE combined with `grep.patternType=perl`: not tested on such a build. Reading of git's option precedence: the command line's `-E` replaces the config's pattern type before PCRE is needed.
- Repo config that runs code in other git commands (core.fsmonitor, a textconv driver run by `git log -G` in check_brief): this is outside the F31 path. Repo config already has code-exec power over the user's own git, so it is not a new boundary.

## Endorsement Claims

- **Claim:** With color.ui and color.grep set to `always` in repo or global config, F31 still skips both briefs of a shared pair.
  **Location:** `scripts/build-loop.sh:307`
  **Evidence:** executed
  **Verified:** probe runs (local and global) printed `skip a: another open brief … same branch`; T28 has a local-config arm.
  **Not verified:** system config (`GIT_CONFIG_NOSYSTEM=1` in the probe).
  **route: code-fact-check**
- **Claim:** Any `git grep` exit status above 1 (128 from a bad config value, 137 from a signal) makes every open brief skip, and leaves done and new lines unchanged.
  **Location:** `scripts/build-loop.sh:307-308, 335`
  **Evidence:** executed
  **Verified:** grep.patternType=bogus, grep.threads=-1, grep.column=notabool (local and global), and a SIGKILL shim; each printed `skip a: … could not be listed`, `ok c done`, `ok n new`.
  **Not verified:** a dropped brief in the same run, and a closed/ open brief in the error state (both reach :335 by reading the code).
  **route: code-fact-check**
- **Claim:** In status_line, no return before :335 prints `ok` for a brief whose status is open.
  **Location:** `scripts/build-loop.sh:318-338`
  **Evidence:** read-static
  **Verified:** read the whole of status_line; only :324 prints `ok` before :335, and only for `st == new`.
  **Not verified:** check_brief's `st` for a closed/ path (lib :321-359, read but not run in the error state).
  **route: code-fact-check**

## Primitive sweep

Primitive: external process whose output feeds a security-relevant decision (`git grep`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:307` | S1, S2, S3 | `--no-color`, `-E`, rc>1 → error | cleared by execution (table above) |

No other `git grep` call in scope (`rg -n 'git grep' scripts/`).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

13380172 closes R1. I tested 18 config keys in both repo and global scope, plus attributes and a signal. None changed the `-l` output or emptied the set while exiting 0 or 1. Every failure exited 128 or 137 and failed closed. The new error state skips only open briefs, and no earlier return path lets an open brief print ok. The one partial-failure case that remains (a missing blob, exit 0) is override row 293's settled premise, unchanged. Within the paths read and executed I found nothing; the claims I routed to code-fact-check are still pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved at the path named in your tail, structured per your skill, with a `Commit: 13380172` first line.
- **Answered:** Yes. R1 is closed, checked by execution across colour, grep, core, submodule and attribute config and across exit statuses 0, 1, 128 and 137. No new way to fail open was found in the error state.
- **Out of scope:** Rows 276/280/281 (the caller's environment is trusted) and row 293 (an unreadable brief is not counted). The test gaps for the C29 and C30 mutants (fact-check Claim 9) are not security findings.
- **Escalate:** None.
