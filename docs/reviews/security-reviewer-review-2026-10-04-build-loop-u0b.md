Commit: 7cbbe8d2

# Security Review — feat/build-loop-u0b (U0b: FENCE_AWK, check_brief, check_branch and resolve_main moved into the lib)

**Scope:** `git diff feat/build-loop-u0a..feat/build-loop-u0b` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats)
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0b.md (Claims 5 and 7 are the documentation side of Finding 1; E5 is reused)

## Trust Boundary Map

```
B1 (moved): [origin/HEAD (remote-set), local refs/heads/*, current HEAD] → [resolve_main: -* skip, show-ref --verify, ^{commit}] → [MAIN / MAIN_SHA / MAIN_BY_NAME]
B2 (moved): [brief blob at MAIN_SHA — whichever branch B1 chose]          → [check_brief: pathform, isbrief, ls-tree mode, FENCE_AWK] → [brief-state verdict "ok X open|done|dropped|new"]
B3 (moved): [branch name from repo text (a brief's Branch: line)]         → [check_branch: NAMECHARS, -*, check-ref-format, show-ref --verify] → [git rev-list / log args]
B4 (moved): [precondition: "found by name"]                              → [dev-cycle.sh:332 MAIN_BY_NAME test — not in the lib]  → [check_brief / check_branch]
```

```
S1: origin/HEAD symbolic ref       — remote-mutable   — UNTRUSTED for git-argument sinks (guarded: -* skipped, only a hash reaches git)
S2: current branch / HEAD commit   — runtime-mutable (any session or loop with a worktree checks out and commits to it) — UNTRUSTED as a source of brief state
S3: brief path / branch name from repo text — repo-mutable — UNTRUSTED for git-argument and path sinks
S4: MAIN_BY_NAME                   — code-set by resolve_main — trusted; it is the only signal that MAIN_SHA came from S1/main/master rather than S2
S5: ROOT_REAL                      — caller-set — see U0a Finding 1
```

The moved checks are verbatim; the trust change is that the "default branch found by name" requirement (B4) stayed in dev-cycle.sh while the readers it protects moved into a library whose stated contract omits it.

## Findings

#### 1. check_brief and check_branch read state from whatever branch resolve_main fell back to; the by-name guard is not part of the lib or its contract

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:215-271` (contract `:10-12`; resolve_main `:278-299`)
**Boundary:** B2, B4
**Move:** #5 (invert the access model), #1
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (u0b tip):
```
# calling any file check, and runs resolve_main before check_brief or
# check_branch.
```
```
  case "$(git ls-tree "$MAIN_SHA" -- "$a" | cut -c1-6)" in
```
and the guard that stayed behind, `scripts/dev-cycle.sh:332`:
```
if [[ ( "$CHECK" == --check-brief || "$CHECK" == --check-branch ) && -z "$MAIN_BY_NAME" ]]; then
```

The lib's contract tells a new caller only to run `resolve_main` first. `resolve_main` succeeds (returns 0) on the current-branch fallback with `MAIN_BY_NAME` empty, and `check_brief` then reads the brief's `Status:` from that branch's commit — S2, content any loop or session working on that branch authored. Probe (repo whose only branch is `feature-x`, brief committed there with `Status: done`; lib sourced under `set -euo pipefail`):
```
MAIN=feature-x by-name=no
ok docs/working/briefs/2026-10-02-a-b.md done <sha>
```
The same repo through dev-cycle.sh: `--check-brief needs a default branch (origin/HEAD, main or master); found none`, exit 1. With an empty MAIN_SHA (resolve_main returned 1 and a caller proceeds), fact-check E5 shows `ok … new` for a landed brief and a commit count taken against HEAD. The plan's whole reason for these readers in build-loop.sh is that state comes from main's commit, never from a loop-writable source (plan F21/T21, D8); a caller that follows the lib's written contract gets that property only when origin/HEAD, main or master exists. Unreachable today (dev-cycle.sh enforces B4 itself); reachable once build-loop.sh calls the lib directly as planned ("resolves MAIN_SHA once and calls the lib directly"), at which point the floor rule makes it Medium. Fact-check Claims 5 and 7 record the contract gap as a documentation inaccuracy; this finding is its security consequence.

**Recommendation:** Put the guard where the read happens: `check_brief` and `check_branch` print `skip X: no default branch found by name` (or return a distinct status) when `MAIN_BY_NAME` is empty, which also covers the empty-MAIN_SHA case. Keep dev-cycle.sh's early exit for its message, and add a lib-level bats case mirroring the probe above. At minimum, amend the contract to "calls them only when resolve_main returned 0 with MAIN_BY_NAME=1".

## Untested bypass candidates

- B1 with origin/HEAD pointing at a remote-chosen name that also exists as a local branch the loop controls (e.g., origin/HEAD → `trunk`, local `trunk` created by a loop): resolve_main sets MAIN_BY_NAME=1 for it. Pre-existing, moved verbatim, and out of scope per the settled-decisions rule; listed because the by-name flag is what Finding 1's fix would rely on.

## Endorsement Claims

- **Claim:** Converting the top-level resolution into `resolve_main` called in a `||` list does not lose an abort: every command inside that could fail is already followed by `|| true` or is a test.
  **Location:** `scripts/lib/dev-cycle-read.sh:278-299`, `scripts/dev-cycle.sh:328`
  **Evidence:** read-static
  **Verified:** read the whole function: `origin_head="$(git symbolic-ref … || true)"`, `sha="$(git show-ref … || true)"`, `sha="$(git rev-parse … || true)"`, `cur="$(git symbolic-ref … || true)"`, `MAIN_SHA="$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)"`, final `[[ -n "$MAIN_SHA" ]]`.
  **Not verified:** `candidates+=(...)` under a caller that has `set -u` off and a pre-set `candidates` global (now `local`, so not inherited).
  **route: code-fact-check**
- **Claim:** Making `c sha cur origin_head candidates` local removes globals no other code in dev-cycle.sh reads.
  **Location:** `scripts/lib/dev-cycle-read.sh:279`
  **Evidence:** read-static (and fact-check Claim 2's grep)
  **Verified:** grep of dev-cycle.sh at u0b for those names returns no reads.
  **Not verified:** future build-loop.sh.
- **Claim:** git option injection through S1/S3 is unchanged by the move: names starting `-` are skipped and only hashes or `refs/heads/<validated>` reach git.
  **Location:** `scripts/lib/dev-cycle-read.sh:261-268, 285-296`
  **Evidence:** read-static
  **Verified:** `[[ ! "$a" =~ ^[$NAMECHARS]+$ || "$a" == -* ]]`, `[[ "$c" == -* ]] && continue`, `[[ -n "$cur" && "$cur" != -* ]]`, `--` before pathspecs at `:224, 247, 248`.
  **Not verified:** git's handling of `$MAIN_SHA:$a` in `cat-file blob` (`:232`) when `$a` passed pathform but contains `..`-free sub-paths — pathform forbids `.`/`..` components; not executed here.
  **route: code-fact-check**

## Primitive sweep

Primitive: git invocation with untrusted-derived arguments
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:224` ls-tree | S3 path, MAIN_SHA | pathform + isbrief, `--` | Finding 1 (which commit is read), arg-safe |
| `:232` cat-file blob `$MAIN_SHA:$a` | S3, MAIN_SHA | as above + ls-tree mode 100644/100755 | Finding 1 (which commit), arg-safe |
| `:247`, `:248` git log | S3, MAIN_SHA | `--` | Finding 1 (which commit), arg-safe |
| `:262` check-ref-format | S3 | NAMECHARS, `-*` | cleared — verbatim |
| `:266-268` show-ref / rev-parse / rev-list / log | S3, MAIN_SHA | show-ref --verify on refs/heads/<name> | cleared for args; rev-list base is Finding 1 when MAIN_SHA empty |
| `:281`, `:288-289`, `:294-296` resolve_main | S1, S2 | `-*` skip, show-ref --verify | cleared — verbatim; selection consequence is Finding 1 |

Primitive: awk program
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:232` `awk "$FENCE_AWK"'…'` | code constant over S3 blob as data | no `-v` from input | cleared — verbatim |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Brief/branch readers trust a fallback (non-default) branch; by-name guard left in the caller | Low | B2, B4 | `scripts/lib/dev-cycle-read.sh:215-271` | High |

## Overall Assessment

The code moved verbatim and dev-cycle.sh's behaviour is unchanged (its own by-name guard still fires). The security-relevant effect of the move is that the guard which makes `check_brief`/`check_branch` read only the default branch's committed state did not move with them, and the lib's contract does not mention it; a second caller that follows the contract can read brief state from a loop-authored branch. Fixable in place by moving the MAIN_BY_NAME check into the two functions. No findings within dev-cycle.sh's code paths; endorsement claims pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-reviewer-review-2026-10-04-build-loop-u0b.md, structured per the skill, with `Commit: <reviewed tip short SHA>` as its first line.
- Answered: yes — resolve_main conversion (errexit, locals) and the precondition split reviewed; current-branch fallback probed.
- Out of scope: FENCE_AWK parsing semantics and branch-name validation (moved verbatim, settled 2026-09-29..10-02).
- Escalate: for-orchestrator-synthesis — Finding 1 overlaps fact-check Claims 5/7; one fix (guard in the lib) closes all three.
- Decisions I made: rated Low because no reachable caller skips the guard today; re-rates to Medium when build-loop.sh calls the lib.
