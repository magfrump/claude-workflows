Commit: 698348ac

# Security Review — feat/build-loop-u0b, final confirming pass (full unit range)

**Scope:** `git diff feat/build-loop-u0a..feat/build-loop-u0b` (0b53fe50, fbe3a219, 698348ac) and their commit messages; FENCE_AWK, oddwhy, main_by_name, check_brief, check_branch and resolve_main read whole at the tip; dev-cycle.sh's dispatch (`scripts/dev-cycle.sh:328-345`)
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0b.md (Stage 1, k=3, Commit 698348ac); override-log rows 2026-10-05 for feat/build-loop-u0b (rows 208 foreign-repo MAIN_SHA and 209 origin/HEAD naming a loop branch: not re-raised)

Known from the fact-check and not re-filed: the header's "read nothing as plain" sentence (Claim 1), the 0b53fe50 "returns 1" wording (Claim 2), and build-loop.sh's future reporting (Claim 3, Unverifiable).

Executed at the tip: `bats test/scripts/dev-cycle.bats`, 58/58 pass in a detached scratch worktree. Probes: `final-sec/probe2.sh` and an argument-echo probe, both in a scratch repo.

## Trust Boundary Map

```
B1 (moved):   [origin/HEAD (remote-set), refs/heads/*, HEAD]        → [resolve_main: -* skip, show-ref --verify, ^{commit}]       → [MAIN / MAIN_SHA / MAIN_BY_NAME]
B2 (new):     [MAIN_SHA + MAIN_BY_NAME globals]                      → [main_by_name at the top of check_brief / check_branch]       → [git reads of the default branch]
B3 (changed): [caller-set (cwd, ROOT_REAL) pair]                     → [need_root (now also in check_brief)]                         → [relative pathspecs for git ls-tree / git log; blocker]
B4 (moved):   [brief path / branch name from repo text (roadmap)]    → [pathform + isbrief / NAMECHARS + check-ref-format]           → [git argv; printed "skip …" line]
B5 (moved):   [brief blob on the default branch]                     → [FENCE_AWK refusals; exact Status regex]                      → [ok <path> open|done|dropped <sha>]
B6 (moved):   [lib check output incl. unvalidated argument bytes]   → [caller's scrub (dev-cycle.sh: scrub_reexec)]                 → [terminal / digest / caller's parser]
```

```
S1: origin/HEAD                 — remote-set at clone/fetch   — UNTRUSTED as a name; trusted only after show-ref --verify on refs/heads/<c>
S2: brief path, branch name     — repo text (roadmap lines)   — UNTRUSTED for git argv and terminal output
S3: brief blob content          — repo text (default branch)  — UNTRUSTED; read only through FENCE_AWK and the Status regex
S4: ROOT_REAL, cwd              — caller-set                  — trusted after need_root, which does not establish the top level (Finding 1)
S5: MAIN/MAIN_SHA/MAIN_BY_NAME  — code-set by resolve_main; initialised empty at source time — trusted within one repository (row 208)
```

The unit moves the brief and branch readers into the lib and adds two guards: main_by_name, so they never answer from a fallback branch, and need_root in check_brief. Repo text reaches git only after the form checks, and default-branch names reach git only as hashes. Both new findings concern what a second caller could get wrong with these checks.

## Findings

#### 1. check_brief run from a subdirectory with ROOT_REAL="$(pwd -P)" reports a landed `Status: done` brief as `ok … new`

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:236-247` (need_root `:77-80`)
**Boundary:** B3
**Move:** 11 (bypass of need_root), 3 (failure state of the git read)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim, unit tip):**
```
  need_root
…
  case "$(git ls-tree "$MAIN_SHA" -- "$a" | cut -c1-6)" in
    '') echo "ok $a new"; return ;;
```
Executed (`probe2.sh` against this tip's lib, with the brief committed on main as `Status: done`): at the root it prints `ok docs/working/briefs/2026-01-01-x.md done fb4290f…`. After `cd sub; ROOT_REAL="$(pwd -P)"` it prints `ok docs/working/briefs/2026-01-01-x.md new`.

need_root passes because ROOT_REAL equals the cwd (U0a Finding 1). `git ls-tree <tree> -- <path>` and `git log -- <path>` resolve the path relative to the cwd, so from a subdirectory the brief is not found. The empty mode then falls into the `''` arm, which is the legitimate "not landed" answer. A caller that dispatches by brief state would see a done or dropped brief as new and eligible again. That is a fail-open on the brief-state gate, and the commit's own fix (698348ac: "check_brief runs need_root") was meant to make this kind of caller mistake stop the run. dev-cycle.sh cannot reach it, because it runs `cd "$ROOT"` (`scripts/dev-cycle.sh:113`) before ROOT_REAL. Low, not Medium: no caller that can reach it exists yet (U1's build-loop.sh will be the first).

**Recommendation:** Close it in need_root (U0a Finding 1: require the top level, e.g. `[[ -e .git ]]`, or a lib `enter_root`). Alternatively, use `git ls-tree --full-tree` here as defence in depth. Add a bats case that runs check_brief from a subdirectory and expects exit 1.

#### 2. The lib's check functions echo unvalidated argument bytes (ESC, OSC, bidi) before validation; safety relies on a caller scrub the header does not require

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:239-240,285-286` (header `:8-19`)
**Boundary:** B6
**Move:** 2 (assumed sanitisation elsewhere)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim, unit tip):**
```
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
…
  if [[ ! "$a" =~ ^[$NAMECHARS]+$ || "$a" == -* ]]; then echo "skip ${a//$'\n'/ }: not an allowed branch name"
```
Executed (lib sourced without scrub_reexec): `check_branch $'x\e[31mRED\u202e'` prints `skip x 033 [31mRED 342 200 256: not an allowed branch name` (od -c), and `check_brief $'a\e]0;t\a'` prints the raw OSC sequence.

Only the newline is replaced. Under dev-cycle.sh every byte goes through scrub_reexec (`scripts/dev-cycle.sh:90`), so nothing changes today. The arguments are repo text (brief paths and branch names from roadmap lines, S2), though. A second caller that sources the lib and prints or stores these lines without scrub_reexec, for example into a marker, a log or an agent prompt, would carry terminal escapes and bidi controls from the repo. The header names the DEV_CYCLE_SCRUBBED marker but never says that callers must scrub check output. The plan does share the scrub with build-loop.sh (plan :185) and has D11 scrub marker bodies, so this records a contract to state, not a reachable flaw.

**Recommendation:** Add one header clause: "check output echoes rejected arguments as given (newlines replaced); print or store it only through scrub". Alternatively, replace non-NAMECHARS bytes in the echoed argument (e.g. `${a//[^$NAMECHARS]/?}`) so the lines are inert on their own.

## Untested bypass candidates

- resolve_main when origin/HEAD names a branch a loop created locally (row 209, deferred to the U2/U3 gate tests). Listed, not re-raised.

Tested (cleared): check_branch with `refs/heads/alias` as a symbolic ref to main. Executed: it prints `ok alias fb4290f… 0 2026-10-05`, which is main's commit with a count of 0, the same as a fresh or merged branch, so no state gate opens. Only a local actor can create a symref branch (git does not transfer symrefs under refs/heads/ on fetch). Noted for U1's branch tests.

Traced through the code (not open): main_by_name with MAIN_SHA pre-set in the environment is reset at source time (`:227`). A brief path with `:`, `*`, `?` or `[` fails pathform, so GIT_LITERAL_PATHSPECS (which dev-cycle.sh exports and a second caller may not) does not change check_brief's pathspec. A branch name starting `-` or `refs/` or equal to `HEAD` is skipped before any git call that takes it.

## Endorsement Claims

- **Claim:** check_brief and check_branch print a `skip` line and make no git read of the default branch unless main_by_name holds. MAIN, MAIN_SHA and MAIN_BY_NAME are emptied when the lib is sourced.
  **Location:** `scripts/lib/dev-cycle-read.sh:227-228,239,285`
  **Evidence:** executed
  **Verified:** bats case 58 (four skips, no ok line) passes at 698348ac. The fact-check Verified cluster covers the guard mutations.
  **Not verified:** a MAIN_SHA from another repository (row 208, settled).
  **route: code-fact-check**
- **Claim:** A default-branch name from origin/HEAD, main or master reaches git only as `refs/heads/<c>` through `show-ref --verify`, and names starting with `-` are skipped.
  **Location:** `scripts/lib/dev-cycle-read.sh:302-324`
  **Evidence:** read-static
  **Verified:** `[[ "$c" == -* ]] && continue`, then `git show-ref --verify --hash "refs/heads/$c"`, then `rev-parse --verify --quiet "$sha^{commit}"`. Later calls use `$MAIN_SHA` only.
  **Not verified:** origin/HEAD naming a loop-created local branch (row 209).
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec (git argv from repo text)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:247` `git ls-tree "$MAIN_SHA" -- "$a"` | S2, S4, S5 | main_by_name, need_root, pathform, isbrief, blocker, `--` | Finding 1 (cwd-relative pathspec) |
| `:255` `git cat-file blob "$MAIN_SHA:$a"` | S2, S5 | as above + mode 100644/100755 | cleared: `<rev>:<path>` is root-relative, and it is reached only after ls-tree returns a mode |
| `:270-271` `git log … -- "$a"` | S2, S4, S5 | as ls-tree | Finding 1 (same cwd-relative pathspec; unreachable once ls-tree returns `''`) |
| `:287-288` `git check-ref-format` | S2 | NAMECHARS, no leading `-` | cleared |
| `:291-293` show-ref / rev-parse / rev-list / log | S2, S5 | main_by_name, check-ref-format, `== $MAIN`, show-ref --verify | cleared (symref to main tested: count 0) |
| `:305-321` resolve_main's git calls | S1 | `-*` skip, show-ref --verify | cleared (row 209 settled) |

Primitive: terminal output of repo text
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:239,240,285,286` `echo "skip ${a//$'\n'/ }: …"` | S2 | newline only, plus the caller's scrub | Finding 2 |
| `:242-268` later echoes of `$a` | S2 | pathform/isbrief already passed | cleared, because the form allows only `[a-z0-9-./]` |
| `:261` `echo "skip $a: line $n $(oddwhy "$why") …"` | S3 | `$n` numeric from awk; `$why` mapped to fixed text | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | check_brief from a subdirectory with ROOT_REAL=$(pwd -P) prints `ok … new` for a landed brief | Low | B3 | `scripts/lib/dev-cycle-read.sh:236-247` | High |
| 2 | Rejected arguments are echoed raw (only `\n` replaced); the header does not require callers to scrub | Informational | B6 | `scripts/lib/dev-cycle-read.sh:239-240,285-286` | High |

## Overall Assessment

The moved readers keep their input discipline: form checks before git, hashes rather than names for the default branch, and FENCE_AWK before any Status line is believed. The review fixes in this unit, main_by_name and need_root in check_brief, close the earlier fallback-branch and missing-root gaps (tests 58/58, mutations verified by the fact-check). Both remaining items concern a second caller. A subdirectory cwd defeats need_root and turns a done brief into `new` (Low, closed by U0a's need_root fix), and the check output carries raw escapes until a caller scrubs it (Informational, a header sentence). Neither is reachable through dev-cycle.sh. No findings within dev-cycle.sh's code paths; endorsement claims pending execution verification by code-fact-check.

## Goal-Alignment Note
- Success criterion (restated verbatim): one markdown report per unit at OUTPUT_PATTERN (unit = u0a, u0b, u0c), structured per your skill, first line `Commit: <unit tip short SHA>`, ending with the Goal-Alignment Note.
- Answered: yes. Full range reviewed fresh: main_by_name and need_root guards, the git argv paths, and second-caller misuse (a subdirectory cwd and an unscrubbed caller were both executed against this tip).
- Out of scope: rows 201, 208 and 209 (settled), FENCE_AWK's modelling limits (decision log 69).
- Escalate: for-orchestrator-synthesis. Finding 1 shares its fix with U0a Finding 1 and U0c Finding 1.
- Decisions I made: rated Finding 1 Low, not Medium, because no reachable caller exists until U1 (the same rule as the earlier iterations' Lows on this guard). It meets the Medium floor once build-loop.sh calls check_brief without cd-ing to the top level.
