Commit: 458dc170
Loop-pass short-circuit: used at 458dc170

# Code Review Rubric: feat/build-loop-u4b1

**Scope:** full branch, `git diff main...HEAD` (main 596966f0; first pass of the loop). Delivery mode: self-read (shared brief on disk).
**Iteration 1** (`--loop-pass`, k=1 fact-check). Behavioral red at fact-check (SKILL.md is the orchestrator's instructions, so a wrong safety claim there is behavioural): first-red short-circuit, critics skipped this pass. No enforcement file in the diff (mechanic 7 not triggered). Stage 2.5 skipped (loop pass).
**Reports:** `docs/reviews/code-fact-check-report-2026-10-13-u4b1-i1.md` (33 claims: 24 Verified, 4 Mostly accurate, 1 Stale, 4 Incorrect).

## 🔴 Must Fix

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| R1 | The hardened-git Rule says neither `.git/config` nor `~/.gitconfig` "runs anything here: no ... filter or signature program"; under hg's exact line a filter in `.git/config` plus info/attributes ran, and commit.gpgSign ran gpg.program. Only `--state` refuses these, at the moment it runs. | fact-check 9b (executed) | Incorrect (high) | `SKILL.md:62-63` "so neither runs anything here: no hook, fsmonitor, filter or signature program" | Fixed: the Rule names what hg covers and what only `--state` refuses, runs `--state` again before the iteration's commits, and names the residual (Q-103) |
| R2 | "Never export these settings: `--state` refuses a caller that sets one": with hg's seven environment variables exported, `--state` printed ok; only config pairs are refused. | fact-check 11b (executed) | Incorrect (high) | `SKILL.md:66-67` | Fixed: "set them per command ... `--state` refuses a caller's config pair for a HARDEN key" |

## 🟡 Must Address

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A1 | An undocumented exit or a timed-out call "means nothing ran"; the script's header says nothing decided (a writing mode may stop part way). | fact-check 5b | Incorrect (doc-level wording of a stop rule) | `SKILL.md:48-49` | Fixed |
| A2 | "step 9" / "step 10's dispatch" name steps the file does not have yet (U4b2 writes them). | fact-check 24 | Incorrect | `SKILL.md:129, 213` | Fixed: named by mode (`--cycle-diff`) and "this iteration's dispatch" |
| A3 | A `refuse main-log:` line has three causes, and the bootstrap's own refusal was not exempted: the first iteration would file a judgment entry and block dispatch. | fact-check 18 | Mostly accurate (behavioural consequence) | `SKILL.md:212-214` | Fixed |
| A4 | Identity read with bare `git config` is an unstated exception to "never bare git", and a loop-writable user.name pasted as `-c user.name=NAME` into script text has no quoting rule. | fact-check 7, escalation to security | Mostly accurate | `SKILL.md:53-56, 215-217` | Fixed: read into variables inside the committing script, never pasted |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| C1 | Cycle rules do not admit "any .md under docs/"; the three row cases plus docs/working and docs/reviews do pass. | fact-check 14 | Fixed |
| C2 | The pending D6 section's refusal list is partial. | fact-check 15 | Fixed (points to the header) |
| C3 | Step 7 still lands through pr-prep and its record has no `Main at:`/`Branch:` line, so SINCE always bootstraps until U4b2. | fact-check 25 (Stale) | Defer to U4b2 (plan split note) |
| C4 | The pin test checks only `-c` and `GIT_*=` tokens of the hg line. | fact-check residue | Won't-Fix: the line's other tokens are `env`, `git` and `"$@"`; the one-line count pins its shape |

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer | loop-pass short-circuit (behavioral red confirmed) |

## Considered overrides

Rows 702, 704, 720, 726, 727, 735, 736, 742, 744, 750, 764, 769, 771 (the hand-offs this unit answers); none re-flagged.

**Status:** 2 red, 4 amber, all fixed in the next commit (unreviewed). Next: iteration 2, full panel over the fix range.
