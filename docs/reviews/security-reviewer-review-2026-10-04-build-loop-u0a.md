Commit: b5209cbc

# Security Review — feat/build-loop-u0a (U0a: scrub, re-exec wrapper and file rules moved into scripts/lib/dev-cycle-read.sh)

**Scope:** `git diff feat/build-loop-handoff..feat/build-loop-u0a` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/dev-cycle.bats)
**Date:** 2026-10-04
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0a.md (Claims 8, 9 and 11 build on here)

## Trust Boundary Map

```
B1 (moved): [invocation path BASH_SOURCE[0] + caller env (CDPATH)] → [SCRIPT_DIR = cd+pwd; -f "$READ_LIB"] → [source: lib code runs in the parent, before the scrub]
B2 (moved): [child stdout/stderr carrying repo text]               → [scrub_reexec → scrub (perl)]             → [terminal / LLM reader of the digest]
B3 (moved): [repo paths from repo text; working-tree entries/symlinks] → [blocker/rawfile/plaindir vs ROOT_REAL] → [file reads (inrepo/dirok/skipped)]
B4 (moved): [caller env DEV_CYCLE_SCRUBBED]                         → [scrub_reexec's first test]               → [scrub skipped]
```

```
S1: BASH_SOURCE[0] (invocation path)  — deploy-time (image /opt/claude-workflows/scripts via the ~/.claude/scripts symlink, or the repo's own scripts/) — trusted for the code-load sink at the same level as dev-cycle.sh itself
S2: CDPATH (inherited env)            — caller env — untrusted for path resolution; executed: fails closed (see Endorsements)
S3: DEV_CYCLE_SCRUBBED (env)          — caller env — trusted for the skip-scrub decision (whoever sets it already owns the output stream); not reachable by repo text
S4: repo-text paths and working-tree entries — repo-mutable (any branch author / loop) — UNTRUSTED for read/path sinks
S5: ROOT_REAL (shell variable set by the sourcing script) — code-set by the caller — trusted when set; its absence is Finding 1
```

The move makes the lib a second file whose code runs in the unscrubbed parent; it is located from S1 only, never from the repo acted on (cwd/ROOT), so repo text gains no influence over which code is sourced. The behavioural trust change is in B3: the plain-file guard's safety now rests on a prose precondition (S5) for any caller other than dev-cycle.sh, and that precondition fails open rather than closed.

## Findings

#### 1. The plain-file (symlink) guard fails open when a caller has not set ROOT_REAL, even under `set -euo pipefail`

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:63-92` (contract at `:7-10`)
**Boundary:** B3
**Move:** #3 (error path), #1 (trust boundary moved)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (u0a tip):
```
rawfile() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
inrepo() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }
dirok() { [[ -z "$(blocker "$1" dir)" && -d "$1" ]]; }
skipped() { SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT"); }
```
and the header: `# cds to the repo root and sets ROOT_REAL (that root, symlinks resolved) before` / `# calling any file check.`

`blocker` runs inside `$(...)`. When ROOT_REAL is unset, the unbound-variable error under `set -u` kills only that subshell, which prints nothing; `inrepo`/`dirok` read empty output as "no blocking part" and `skipped` as "not skipped". Probe (`probe2.sh` in this unit's scratch dir: lib sourced under `set -euo pipefail`, cwd at a repo holding `docs/link.md -> outside/target.md` and `linkdir -> outside`):
```
with-root: inrepo docs/link.md -> refused
no-root: inrepo docs/link.md -> READ (symlink accepted)
no-root: inrepo linkdir/target.md -> READ
no-root: dirok linkdir -> OK
no-root: skipped -> no
no-root: reached end, status 0
```
So a sourcing script that misses the precondition reads committed symlinks to anything outside the checkout — the exact property the comment at `:60-62` exists to guarantee — and continues with status 0. Before the move, ROOT_REAL was set at the same file's top level (`scripts/dev-cycle.sh:113`) before any check could run, so the failure mode was unreachable; the move turns it into an API contract enforced only by a comment, and the comment's "The caller sets -euo pipefail" implies `-u` would catch the omission, which the probe refutes. Not reachable today (dev-cycle.sh is the only caller and sets it first); it becomes reachable when build-loop.sh (U1) sources the lib, at which point the floor rule puts it at Medium. U0c's `imported_names` inherits the same failure (see the U0c report).

**Recommendation:** Enforce the precondition outside any command substitution, e.g. a `need_root() { [[ "${ROOT_REAL:-}" == /* ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not set" >&2; exit 1; }; }` called first in `inrepo`, `dirok`, `skipped` (and later `check_brief`, `imported_names`), or have `blocker` emit a non-empty sentinel on failure so empty output cannot mean both "plain" and "crashed". Add a bats case: source the lib without ROOT_REAL, call `inrepo` on a symlink, expect refusal or exit 1. Correct the header so it does not imply `set -u` covers this.

## Untested bypass candidates

- B3 guard with ROOT_REAL set to a non-root but existing directory by a future caller (e.g., a worktree path while cwd is the main checkout): would refuse everything or accept a different tree's files; not tested because no such caller exists yet.

(The other candidates for the B1 lib lookup — CDPATH redirect, relative invocation path, PATH lookup by `source` — were tested or traced; see Endorsements.)

## Endorsement Claims

- **Claim:** An inherited CDPATH pointing at a directory that holds `scripts/lib/dev-cycle-read.sh` does not get that file sourced; dev-cycle.sh exits 1 before `source`.
  **Location:** `scripts/dev-cycle.sh:82-88`
  **Evidence:** executed
  **Verified:** `probe.sh` (scratch): `CDPATH=<evil>` run printed `dev-cycle.sh needs <evil>/scripts` / `<evil>/scripts/lib/dev-cycle-read.sh` (cd's CDPATH echo makes SCRIPT_DIR two lines, so `-f` fails), exit 1, no `EVIL-LIB-SOURCED`; `CDPATH=:<evil>` resolved the real dir and sourced the real lib.
  **Not verified:** invocation through a symlinked script path other than the image's `~/.claude/scripts` directory symlink (lib is looked up beside the link, not its target).
  **route: code-fact-check**
- **Claim:** `source` receives an absolute path, so it performs no `PATH` search for the lib.
  **Location:** `scripts/dev-cycle.sh:82,85,88`
  **Evidence:** read-static
  **Verified:** `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` with `SCRIPT_DIR` from `pwd` output; a name containing `/` is not searched in PATH by bash's `source`.
  **Not verified:** `pwd` output under an exported shell function named `pwd` (BASH_FUNC import; pre-existing, caller-env trust).
  **route: code-fact-check**
- **Claim:** `scrub_reexec` re-runs the caller-supplied script path, not the lib, and the env marker is set only on the child.
  **Location:** `scripts/lib/dev-cycle-read.sh:54-59`, `scripts/dev-cycle.sh:89`
  **Evidence:** read-static
  **Verified:** `local self="$1"; shift` / `{ DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub`; caller passes `"${BASH_SOURCE[0]}"` from dev-cycle.sh's top level.
  **Not verified:** descendants of the child (git, awk, perl) inherit `DEV_CYCLE_SCRUBBED=1` — pre-existing, unchanged by the move.

The pre-scrub `echo "dev-cycle.sh needs $READ_LIB" >&2` (`scripts/dev-cycle.sh:86`) is unscrubbed (fact-check Claim 9); it interpolates only S1-derived text, never repo text — no finding.

## Primitive sweep

Primitive: code load / exec
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:88` `source "$READ_LIB"` | S1, S2 | `-f` on an absolute path from the script's own dir | cleared — executed CDPATH probe fails closed |
| `scripts/lib/dev-cycle-read.sh:57` `bash "$self" "$@"` | S1 | caller passes its own BASH_SOURCE[0] | cleared — verbatim move, `$self` replaces BASH_SOURCE[0] correctly |
| `scripts/lib/dev-cycle-read.sh:30` `perl -C0 -ne '…'` | code constant | env -u PERL_UNICODE/PERL5OPT/PERLIO | cleared — moved verbatim |

Primitive: path resolution / file read guard
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:63` rawfile `realpath -e` | S4, S5 | compare to `$ROOT_REAL/$1` | Finding 1 (fails open when S5 unset) |
| `scripts/lib/dev-cycle-read.sh:66` plaindir `realpath -e` | S4, S5 | compare to `$ROOT_REAL/$1` | Finding 1 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Symlink guard fails open without ROOT_REAL; `set -u` does not catch it | Low | B3 | `scripts/lib/dev-cycle-read.sh:63-92` | High |

## Overall Assessment

The move itself is faithful: the lib is located from the script's own directory, an inherited CDPATH fails closed, and no repo text can now pick the code that is sourced. The one move-induced weakness is that the symlink guard (B3) used to be safe because the same file set ROOT_REAL first; as a shared API it fails open, silently and with status 0, for a caller that misses the precondition, and `set -u` does not help because the check runs in a subshell. Fix it in the lib before build-loop.sh becomes its second caller. No findings within dev-cycle.sh's own code paths; endorsement claims pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-reviewer-review-2026-10-04-build-loop-u0a.md, structured per the skill, with `Commit: <reviewed tip short SHA>` as its first line.
- Answered: yes — move-specific trust effects (lib lookup, source-before-scrub, DEV_CYCLE_SCRUBBED, ROOT_REAL contract) reviewed with executed probes.
- Out of scope: verbatim-moved scrub semantics (settled 2026-09-29..10-02); build-loop.sh (does not exist yet).
- Escalate: for-orchestrator-synthesis — plan D6 hash-checks extracted files "immediately before running"; the lib is now loaded by dev-cycle.sh after it starts, so the gate's check-to-source window covers two files in a uid-writable mktemp dir. Worth stating in U-gate design.
- Decisions I made: rated Finding 1 Low (not Medium) because no caller in scope can reach it; it re-rates to the Medium floor once build-loop.sh sources the lib.
