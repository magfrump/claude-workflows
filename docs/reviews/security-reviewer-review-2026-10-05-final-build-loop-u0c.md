Commit: d8da1fba

# Security Review — feat/build-loop-u0c, final confirming pass (full unit range)

**Scope:** `git diff feat/build-loop-u0b..feat/build-loop-u0c` (41065ce6, 1c7373d3, d8da1fba) and their commit messages, including the plan amendment; INSTRUCTION_FILE, the import walk (`lower`, `imported_names`), ANSWER_AWK and check_answer read whole at the tip; check_fix's use of the walk (`scripts/dev-cycle.sh:166-182`)
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u0c.md (Stage 1, k=3, Commit d8da1fba); override-log rows 2026-10-05 for feat/build-loop-u0c (check_fix predicate stays, isimported, read-as-truth list, MAIN_SHA precondition, working-tree check_answer, per-process cache: not re-raised)

Known from the fact-check and not re-filed: the header's exiting-check list omits check_answer (Claim 1). The security point there is that `$(check_answer …)` without ROOT_REAL yields an empty string, not a skip line. Also known: the amendment's "worktree at MAIN_SHA" omits "with no untracked instruction files" (Claim 3; the walk lists `--others`, so untracked files in that worktree join the set, which can only over-refuse).

Executed at the tip: `bats test/scripts/dev-cycle.bats`, 59/59 pass in a detached scratch worktree. Probes: `final-sec/probe.sh`/`probe2.sh` (walk and check_brief from a subdirectory) and an argument-echo probe, all in a scratch repo.

## Trust Boundary Map

```
B1 (moved):   [instruction files + @tokens in the working tree at the cwd]   → [need_root; cache key ROOT_REAL; inrepo; realpath -ms vs ROOT_REAL; ~ / abs / .. dropped] → [IMPORTED refusal set → check_fix (later: U2 floor)]
B2 (changed): [caller-set (cwd, ROOT_REAL) pair]                              → [need_root: set, == $(pwd -P)]                                                    → [git ls-files listing scope; relative inrepo]
B3 (moved):   [questions.md / questions-archive.md in the working tree]       → [skipped (need_root, blocker); FENCE_AWK + ANSWER_AWK; ANSWERED header]          → [keep|drop|done|open|unrecognized Q-NNN]
B4 (moved):   [Q-ID argument from repo text]                                  → [^Q-[0-9]+$ check]                                                                → [awk -v id; printed skip/answer line (caller's scrub)]
```

```
S1: instruction-file content (@tokens) — repo text, tracked or untracked — UNTRUSTED for path construction and file read; trusted only to ADD refusals
S2: questions files                    — repo text in the working tree   — UNTRUSTED (row 206: U1 moves the read to main's commit)
S3: Q-ID argument                      — repo text                       — UNTRUSTED for awk -v and terminal output
S4: ROOT_REAL, cwd                     — caller-set                      — trusted after need_root, which does not establish the top level (Finding 1)
S5: IMPORTED / IMPORTED_DONE           — lib globals, process-lifetime   — trusted within one root
```

The walk is a refusal source. Over-reading only over-refuses, and under-reading opens a fix path (or, after U2, a gate path) to a file read as instructions. The fixes in this unit made it stop without a root and key its cache on the root. A root that is the cwd but not the top level still passes, and the walk then under-reads.

## Findings

#### 1. The import walk run from a subdirectory with ROOT_REAL="$(pwd -P)" returns and caches an empty import set (the refusal fails open)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:347-362` (need_root `:80-83`)
**Boundary:** B1, B2
**Move:** 11 (bypass of need_root), 3 (failure state is "fewer refusals")
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim, unit tip):**
```
  need_root
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"; IMPORTED=$'\n'
  while IFS= read -r -d '' f; do
…
  done < <({ git ls-files -z
             GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; } \
```
Executed (`probe2.sh` against this tip's lib, with a top-level `AGENTS.md` containing `@docs/secret.md`): at the root `IMPORTED=$'\ndocs/secret.md\n'`. After `cd sub; ROOT_REAL="$(pwd -P)"` it is `IMPORTED=$'\n'`. The same run's check_brief prints `ok … new` for a done brief (U0b Finding 1).

need_root passes because ROOT_REAL equals the cwd (U0a Finding 1). `git ls-files` lists only the cwd's subtree, so the top-level instruction files are never seen, and the empty set is cached under that key. Any denylist built on IMPORTED, such as check_fix's `[[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]` or U2's floor, then admits an @-imported file. dev-cycle.sh cannot reach this, because it runs `cd "$ROOT"` (`scripts/dev-cycle.sh:114`) before ROOT_REAL. It matters because the amendment in this unit sends the gate into "a worktree at `MAIN_SHA`", which means a caller that changes directory and sets the root by hand. 1c7373d3 is the fix that made a wrong root stop the walk, and this case slips past it. Low, not Medium: no caller that can reach it exists yet.

**Recommendation:** Fix it in need_root (U0a Finding 1). Separately, the walk could check `git rev-parse --show-prefix` is empty once per uncached walk (one fork per process, not per check). Add a bats case: walk from a subdirectory → exit 1.

## Untested bypass candidates

- B1: a token reaching `.git/…` (`@.git/config`). Traced: the path passes `[[ "$p" != ..* ]]` and inrepo (a plain regular file), so grep reads it for more tokens. That can only add refusals, and nothing from the file is printed. Not executed.
- B1: an instruction file edited after the first walk in a long-running caller. The cache is keyed on the root, not the content (carried from iteration 2; no long-running caller yet). Not executed.
- B3: a questions file swapped for a symlink between `skipped` and the awk read (TOCTOU). It needs a same-uid concurrent writer in the checkout, which below the floor bar means the attacker already controls the host. Not executed.

## Endorsement Claims

- **Claim:** The import walk exits 1 without ROOT_REAL before touching IMPORTED_DONE, and recomputes when ROOT_REAL changes to another repo root after a matching cd.
  **Location:** `scripts/lib/dev-cycle-read.sh:349-350`
  **Evidence:** executed
  **Verified:** bats case 59 passes at d8da1fba. The fact-check Verified cluster shows it fails when need_root is dropped or the unkeyed cache is restored.
  **Not verified:** a root that is the cwd but not the top level (Finding 1).
  **route: code-fact-check**
- **Claim:** @tokens starting `~` or `/`, and tokens that resolve to `..*` relative to ROOT_REAL, are not followed. Followed paths are read only after inrepo.
  **Location:** `scripts/lib/dev-cycle-read.sh:369-373`
  **Evidence:** read-static
  **Verified:** `[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue`, `realpath -ms --relative-to="$ROOT_REAL" …`, `[[ "$p" != ..* ]] || continue`, `inrepo "$p"` before queueing.
  **Not verified:** the grep read at `:374` of a queued file that changes between inrepo and grep (TOCTOU, untested candidate).
  **route: code-fact-check**
- **Claim:** check_answer's ID reaches awk only via `-v id=` after `^Q-[0123456789]+$`, and the questions files are read only after `skipped` (need_root and blocker).
  **Location:** `scripts/lib/dev-cycle-read.sh:459-463`
  **Evidence:** read-static
  **Verified:** the regex test is the function's first line, the loop's `skipped "$f"` comes before `[[ -f "$f" ]]` and the awk call, and the fact-check verified the move as verbatim.
  **Not verified:** the working-tree source itself (row 206, U1 moves it to main's commit).

## Primitive sweep

Primitive: path construction / file read from repo text
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:352` `inrepo "$f"` | S1, S4 | INSTRUCTION_FILE name, need_root, blocker | Finding 1 (subdirectory root) |
| `:370` `realpath -ms --relative-to="$ROOT_REAL"` | S1, S4 | `~`/`/` dropped, `..*` dropped | cleared (escape from the root refused); Finding 1 for scope |
| `:373` `inrepo "$p"` | S1, S4 | as `:352` | cleared; `.git/` reach listed (over-refuse only) |
| `:374` `grep -oE "$IMPORT_RE" -- "$f"` | S1 | inrepo before queueing, `--` | cleared; TOCTOU listed |
| `:461` `skipped "$f"` | S2, S4 | need_root, blocker | cleared (exits without root, fact-check Claim 1 on the `$(...)` case) |
| `:463` `awk … "$f"` | S2, S3 | skipped, `-f`, FENCE_AWK | cleared |

Primitive: process exec (git/awk argv)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:360-361` `git ls-files` (two) | S4 | none needed (no repo-text args) | Finding 1 (cwd-scoped listing) |
| `:463` `awk -v id="$a"` | S3 | `^Q-[0123456789]+$` | cleared: `-v` escapes cannot occur in digits |

Primitive: terminal output of repo text
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:459` `echo "skip ${a//$'\n'/ }: not a question ID …"` | S3 | newline only, plus the caller's scrub | same as U0b Finding 2 (executed: `check_answer $'Q\e[2J'` prints the raw ESC) — not filed again |
| `:461-475` other echoes | S2, S3 | `$a` validated; `$SKIP_AT` newline-replaced; awk result from fixed words | cleared |
| check_fix (`scripts/dev-cycle.sh:166-182`) | S1 via IMPORTED | output names the argument only | cleared (no file content printed) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Import walk from a subdirectory with ROOT_REAL=$(pwd -P) caches an empty set (refusal fails open) | Low | B1, B2 | `scripts/lib/dev-cycle-read.sh:347-362` | High |

## Overall Assessment

The walk and check_answer moved verbatim. This unit's fixes, need_root at the walk's top and a cache keyed on the root, close both earlier walk findings, and the tests catch their mutations (59/59). The plan amendment records the walk's working-tree precondition for U2 and keeps check_fix's predicate where its allowlist semantics live. The one remaining gap is need_root's subdirectory case shared with U0a and U0b. For the walk it fails open, so it is worth one line in need_root before U2's gate starts changing directories. Unreachable through dev-cycle.sh. No findings within dev-cycle.sh's code paths; endorsement claims pending execution verification by code-fact-check.

## Goal-Alignment Note
- Success criterion (restated verbatim): one markdown report per unit at OUTPUT_PATTERN (unit = u0a, u0b, u0c), structured per your skill, first line `Commit: <unit tip short SHA>`, ending with the Goal-Alignment Note.
- Answered: yes. Full range reviewed fresh: the walk's trust boundary and cache, check_answer's input path, the plan amendment's precondition, and second-caller misuse (a subdirectory root was executed against this tip).
- Out of scope: override-log rows 202-207 and 210 (settled), the fact-check's header and amendment wording clusters.
- Escalate: for-orchestrator-synthesis. Finding 1 is fixed in U0a's need_root, and U2's gate review should confirm it cds to the worktree's top level.
- Decisions I made: rated Finding 1 Low (no reachable caller until U2), and folded check_answer's raw-argument echo into U0b Finding 2 instead of filing it twice.
