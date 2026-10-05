Commit: 497c8cb5

# Security Review — feat/build-loop-u0a, final confirming pass (full unit range)

**Scope:** `git diff feat/build-loop-handoff..feat/build-loop-u0a` (4ef450da, 32b9ae0e, 497c8cb5) and their commit messages; lib read whole at the tip; dev-cycle.sh's caller side (`scripts/dev-cycle.sh:79-118`)
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0a.md (Stage 1, k=3, Commit 497c8cb5); override-log rows 2026-10-05 for feat/build-loop-u0a (not re-raised)

Known from the fact-check and not re-filed: the need_root comment's "set -u fires there" wording (Claim 1, Incorrect), the header's "read nothing as plain" sentence (Claim 2: true only for an unset ROOT_REAL), and the 497c8cb5 message (Claim 3). None changes a verdict the code prints.

Executed at the tip: `bats test/scripts/dev-cycle.bats` in a detached scratch worktree, 56/56 pass. Probes: `final-sec/probe.sh`, plus one inline probe (below), each in a scratch repo under the job's scratch dir.

## Trust Boundary Map

```
B1 (moved):   [script's own path: BASH_SOURCE[0] → SCRIPT_DIR]      → [-f "$READ_LIB" test; source]                         → [lib code runs in the unscrubbed parent and in the child]
B2 (moved):   [caller env DEV_CYCLE_SCRUBBED]                       → [scrub_reexec's first test]                           → [scrub applied or skipped]
B3 (changed): [caller-set (cwd, ROOT_REAL) pair]                     → [need_root: ROOT_REAL set and == $(pwd -P)]           → [inrepo / dirok / skipped verdicts on relative paths]
B4 (moved):   [repo working tree: paths, symlinks, file types]       → [blocker → plaindir / rawfile: realpath -e == ROOT_REAL/<path>] → [file read by the digest]
B5 (moved):   [repo text and paths printed by the child]             → [scrub (perl, bytes)]                                 → [terminal / redirected digest]
```

```
S1: BASH_SOURCE[0] / SCRIPT_DIR   — deploy-time (install location)  — trusted for which code is sourced; not reachable by repo text
S2: DEV_CYCLE_SCRUBBED            — caller env                      — trusted for the skip-scrub decision (whoever sets it owns the output stream)
S3: ROOT_REAL                     — caller-set global               — trusted only after need_root; need_root checks presence and cwd equality, not that it is the top level (Finding 1)
S4: cwd                           — caller-set                      — as S3
S5: working-tree paths/symlinks   — repo text (committable)         — UNTRUSTED for path construction / file read
S6: repo text printed             — repo text                       — UNTRUSTED for terminal output (escape/bidi sink)
```

The unit moves code without changing where it is sourced from (S1, never the repo acted on) and adds one guard, need_root, which makes the file checks stop on a missing or stale root instead of reading through it. The guard checks that ROOT_REAL is the current directory, but not that this directory is the repo's top level. That is the one gap below.

## Findings

#### 1. need_root accepts any directory as the root: a caller that sets ROOT_REAL="$(pwd -P)" in a subdirectory gets plain-file verdicts on that subdirectory's files

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:73-76` (header contract `:8-10`)
**Boundary:** B3
**Move:** 11 (bypass enumeration for need_root), 5 (what the guard does not cover)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim, unit tip):**
```
need_root() {
  [[ -n "${ROOT_REAL:-}" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not set; the caller sets it before any file check" >&2; exit 1; }
  [[ "$ROOT_REAL" == "$(pwd -P)" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not the current directory; the caller cds to the root it names" >&2; exit 1; }
}
```
Executed: a repo with a tracked `docs/working/questions.md` ("real") and `sub/docs/working/questions.md` ("decoy"); `cd sub; ROOT_REAL=$(pwd -P); inrepo docs/working/questions.md` → `inrepo ok: decoy`, while `git rev-parse --show-toplevel` names the parent.

The header says the caller "cds to the repo root and sets ROOT_REAL (that root...)", and 497c8cb5 made need_root enforce half of it. But `ROOT_REAL="$(pwd -P)"` is the obvious line to write, and it satisfies need_root wherever the process happens to be. In this unit the result is reading the wrong in-repo file, which is still a plain tracked file, so no read leaves the checkout and no symlink is followed. Under dev-cycle.sh it cannot happen, because the script runs `cd "$ROOT"` (`scripts/dev-cycle.sh:112`) before setting ROOT_REAL (`:113`). It matters because U0b and U0c build git-reading checks on the same guard, and there the consequences are wrong verdicts (U0b Finding 1, U0c Finding 1).

**Recommendation:** Make need_root also require the top level. A no-fork `[[ -e .git ]]` works (a worktree's `.git` file counts, and a subdirectory has none), or the lib can own an `enter_root` (show-toplevel, cd, pwd -P) that both scripts call. Add a bats case for `ROOT_REAL=$(pwd -P)` in a subdirectory → exit 1.

## Untested bypass candidates

- rawfile/plaindir on a case-insensitive filesystem (`DOCS/x.md` for `docs/x.md`): GNU realpath keeps the given case, so the comparison should still hold. Not run, because the host filesystem is case-sensitive.
- A hard link inside the checkout to a file outside it: cannot come from git content (checkout writes fresh files), so only a same-uid local actor could make one, and that actor already controls the host. Not run.

Traced through the code (not open): `./x` and `x//y` both fail closed (blocker prints the `./` or `docs//` prefix because realpath ≠ ROOT_REAL/<p>). A trailing `/` fails `-f` or the equality. A ROOT_REAL with a trailing slash, or spelled through a symlink, fails need_root's equality and exits.

## Endorsement Claims

- **Claim:** The lib is sourced from the script's own directory (S1), never from the repo being acted on. The source happens before `cd "$ROOT"`, so cwd and ROOT play no part in which lib file is chosen.
  **Location:** `scripts/dev-cycle.sh:82-89`
  **Evidence:** read-static
  **Verified:** `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`, `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"`, `source "$READ_LIB"` all come before line 112's cd. T30 (copy without lib → exit 1, names the path) passes.
  **Not verified:** the D6 extract-to-temp path that U3b ships (override-log row, deferred to U3b's T33).
  **route: code-fact-check**
- **Claim:** At the tip, inrepo, dirok and skipped exit 1 when ROOT_REAL is unset or differs from `pwd -P`, and rawfile and plaindir return false when it is unset, including under `set -u`.
  **Location:** `scripts/lib/dev-cycle-read.sh:73-80,102-106`
  **Evidence:** executed
  **Verified:** bats case 56 passes at 497c8cb5. Fact-check Verified cluster: mutations of need_root (unset, wrong root) and of the `${ROOT_REAL:-}` clauses each fail it.
  **Not verified:** a ROOT_REAL that is the cwd but not the top level (Finding 1).
  **route: code-fact-check**
- **Claim:** scrub_reexec re-runs the caller-supplied script, not the lib, and sets DEV_CYCLE_SCRUBBED only on that child. Its exit status is the child's.
  **Location:** `scripts/lib/dev-cycle-read.sh:59-64`
  **Evidence:** read-static
  **Verified:** `local self="$1"; shift` / `{ DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" … } 3>&1 | scrub` / `exit "${PIPESTATUS[0]}"`. The fact-check verified that digest and check output are byte-identical to main.
  **Not verified:** a second script that calls dev-cycle.sh as a subprocess from inside its own scrubbed child inherits the marker and gets unscrubbed output. The plan says build-loop.sh calls the lib directly, with no subprocess (plan :194).

## Primitive sweep

Primitive: path resolution / file-type test (symlink-follow guard)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:77` rawfile `realpath -e` | S3, S5 | `${ROOT_REAL:-}` non-empty, equality with ROOT_REAL/<path> | cleared for unset/stale root; Finding 1 for a non-top-level root |
| `:80` plaindir `realpath -e` | S3, S5 | as rawfile | as rawfile |
| `:88-98` blocker `-e`/`-L` walk | S5 | top-down plaindir per component | cleared, since absent means "not blocked", and the callers re-test `-f`/`-d` |
| `:102,105,106` inrepo/dirok/skipped | S3, S4, S5 | need_root | Finding 1 |

Primitive: process exec / source
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:88` `source "$READ_LIB"` | S1 | `-f` test | cleared, since S1 is the install location (deploy-time) |
| `scripts/lib/dev-cycle-read.sh:62` `bash "$self" "$@"` | S1, caller args | none needed | cleared, since args go to the same script, not to a shell string |

Primitive: terminal output of repo text
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:62` both streams through `scrub` | S6 | scrub (moved verbatim; documented exclusions unchanged) | cleared, because the fact-check verified the move as verbatim |
| `scripts/dev-cycle.sh:86` pre-scrub `echo "dev-cycle.sh needs $READ_LIB"` | S1 | none | cleared, because no repo text is involved |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | need_root accepts a ROOT_REAL that is the cwd but not the repo top level | Informational | B3 | `scripts/lib/dev-cycle-read.sh:73-76` | High |

## Overall Assessment

The move keeps the trust story intact. The lib is located from the install path, the scrub is verbatim, and the guards added in review fail closed for the unset and stale-root cases, with mutation-checked tests (56/56 at the tip). The remaining gap is that need_root compares ROOT_REAL with the cwd, not with the repo top level. In this unit that only changes which in-repo plain file gets read, and dev-cycle.sh cannot reach it. It is cheapest to close here, where need_root lives, before U0b and U0c's git-reading checks rely on it. No findings within the code paths read beyond that note; endorsement claims pending execution verification by code-fact-check.

## Goal-Alignment Note
- Success criterion (restated verbatim): one markdown report per unit at OUTPUT_PATTERN (unit = u0a, u0b, u0c), structured per your skill, first line `Commit: <unit tip short SHA>`, ending with the Goal-Alignment Note.
- Answered: yes. Full range reviewed fresh: lib location and sourcing, scrub and marker, need_root/rawfile/plaindir fail-closed behaviour (tests executed, a new bypass probed and confirmed).
- Out of scope: the fact-check's comment and header wording clusters (known), override-log rows for u0a (D6 hash-check, header index, perf).
- Escalate: for-orchestrator-synthesis. Finding 1's fix belongs in this unit's need_root, and it closes U0b F1 and U0c F1 too.
- Decisions I made: rated Finding 1 Informational here (no wrong verdict in this unit's code), and Low in U0b and U0c where it produces one.
