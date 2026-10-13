Commit: ea59b0c3

# Architecture Review — feat/build-loop-u4b1 (final confirming pass)

**Scope:** `git diff main...HEAD` at ea59b0c3 (458dc170, 0cd86cc0, 4c911717, ea59b0c3): `skills/dev-cycle/SKILL.md`, `scripts/lib/dev-cycle-read.sh`, `test/lib/d6-snippet.bash`, `scripts/build-loop.sh` (header), `test/scripts/build-loop-orchestrator.bats`, `workflows/pr-prep.md`, `docs/working/plan-build-loop-handoff.md`, `docs/reviews/override-log.md`
**Date:** 2026-10-13
**Based on:** docs/reviews/code-fact-check-report-2026-10-13-u4b1-final-r{1,2,3}.md (k=3 at 4c911717; fixes in ea59b0c3); shared brief u4b1-i3
**Trust boundaries:** docs/reviews/security-review-2026-10-13-u4b1-i2.md (Commit: 0cd86cc0; security review predates this diff, so its boundaries may be stale). The final security review (Commit: ea59b0c3) has no Trust Boundary Map section.

Scope check: in scope. The diff changes a cross-cutting concern (the HARDEN list, now in four places) and the contract between the orchestrator (SKILL.md) and the gate scripts.

## Dependency Map

- `scripts/lib/dev-cycle-read.sh` `HARDEN` is the source of truth. `build-loop.sh` reads it at runtime: `git_harden` at line 598, and `caller_gate` derives its keys from `"${HARDEN[@]}"` at line 668. dev-cycle.sh reads it through `git_harden`.
- Three more copies exist because their hosts cannot source the lib. One is `test/lib/d6-snippet.bash`'s `G=(env …)`, which runs before anything is checked. Another is SKILL.md's `hg() { env … }`, which is the orchestrator's own git (rows 704, 736). The last is `build-loop.sh`'s header prose for `--state`, lines 135-138. The git_harden bats test pins the lib, G and hg to one literal pair list `H` and one environment list `E`. It also pins exactly one `hg` definition line. It does not pin the header prose.
- SKILL.md (the orchestrator) depends on `build-loop.sh`'s mode contracts (`--state`, `--main-log`, `--settings`, `--check-fix` vs `--cycle-diff`). It depends on `health-check.sh`'s lock and process structure, and on the D6 snippet (pending, Q-140). It also cites the plan (`D1`-`D14`), override-log rows and Q-IDs.
- `workflows/pr-prep.md` depends on SKILL.md's D14 (a one-word citation).
- The scripts do not depend on SKILL.md. The direction stays skill → scripts, which is correct: the volatile instructions depend on the gated, tested code.

## Findings

#### 1. SKILL.md's health-check bound depends on take_lock's process tree

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:265-275` (step 1). Coupled to `scripts/health-check.sh:1104-1119` (take_lock).
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** High
**Legibility-target:** whoever next edits `health-check.sh`'s take_lock, or the orchestrator reading step 1

Evidence (SKILL.md):
> in the background as its own process group (`setsid scripts/health-check.sh > LOG 2>&1`), … A wait past an hour is recorded, the run's whole process group is stopped (`kill -- -PGID`, PGID from `ps -o pgid= -p PID`: stopping its PID alone leaves the waiting `flock` child, which would take the lock later and run the check)

Evidence (health-check.sh take_lock):
> `flock -n -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?` … `rc=0; flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?`

The ea59b0c3 fix is correct for today's take_lock: the process-group stop also reaches the flock child that all three fact-check replicates found. But the instructions now encode the gate script's fork structure, which is content coupling. If take_lock ever puts the wait in its own session, the prose's guarantee ("whole process group is stopped") goes silently false. The same happens if it re-execs under `timeout` or moves the lock into the re-exec'd child. Nothing pins the two together. The bound itself (an hour) is policy for the lock's owner, yet it lives in a skill that cannot test it. Row 750 left "how the orchestrator bounds or reads a waiting gate" to U4, so this is the U4 answer under review, not a settled row.

**Recommendation:** Move the bound to where the lock lives. Add a bounded wait to take_lock, for example `HEALTH_CHECK_LOCK_WAIT=SECONDS` passed to `flock -w`, with its own exit code and a bats case. Step 1 then reads "the health check exited N: waited past the bound" and needs no process-group knowledge. If that waits for U4b2, add a revisit row naming take_lock as the coupled code.

#### 2. The fourth HARDEN copy, in build-loop.sh's header prose, is unpinned

**Severity:** Minor
**Location:** `scripts/build-loop.sh:135-138`
**Move:** 7 (coupling surface)
**Confidence:** High (executed)
**Legibility-target:** a reader of `--state`'s contract in the header

Evidence:
> `#             (the lib's HARDEN list: core.useReplaceRefs, core.hooksPath,` … `#             core.multiPackIndex, log.date, log.showSignature, commit.gpgSign; a git -c pair`

Probe: in a throwaway clone at ea59b0c3 I deleted `, commit.gpgSign` from this header. The git_harden test still passed (`ok 1 git_harden exports …`). The same test caught two other mutants: commit.gpgSign deleted from SKILL.md's hg line (failed at bats line 369), and a second `hg()` line (failed at line 367). The header is the one copy a reader of `--state` sees, and this branch had to edit it by hand. It is the copy most likely to drift when U4c or U5 adds a fifth pair. The lib's comment above HARDEN is a fifth description in prose, but it explains each pair's reason, which is worth keeping.

**Recommendation:** Name the list in the header instead of enumerating it ("every key in the lib's HARDEN list"), as caller_gate's code already does. Alternatively, add one loop to the git_harden test that checks each HARDEN key appears in the header.

#### 3. The by-hand fallback overrides the Rules from outside them, and no unit owns removing it

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:19-28` (intro), against `:47-62` (Rules: D6), `:132-133` (paths rule), `:219`, `:241` (step 0); `docs/working/plan-build-loop-handoff.md:344` (U4c)
**Move:** 2 (responsibility), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** the orchestrator session following SKILL.md before Q-140 is answered; whoever writes U4c

Evidence (intro):
> every `dev-cycle.sh` call (the digest and every check mode) as `~/.claude/scripts/dev-cycle.sh` … no `build-loop.sh` call and no step that needs one

Evidence (Rules):
> Every `build-loop.sh` and `dev-cycle.sh` call runs from WT … as `cd WT && bash -s -- SCRIPT ARG... <<'D6'` … never `~/.claude/scripts/`, a working-tree copy, or a `source`.

Evidence (plan, U4c):
> **U4c, the D6 block** once Q-140 is answered: the block in SKILL.md, one canonical copy, T33's byte-equality assertion (rows 735, 738, 739, 741, 742).

Today's default mode is the by-hand fallback, but it is written as a delta over a rule set that it contradicts. The reader has to compute the rule set that actually applies: which of steps 0.1, 0.2, the pre-commit `--state` re-run, `--settings` and the `--check-fix`/`--cycle-diff` pair "need" build-loop.sh. The Rules bullet that it overrides has no back-pointer to it. Keeping the interim mode in one paragraph is the right shape, because deleting that paragraph retires it. But U4c's checklist does not include that deletion. If U4c lands the block and leaves the paragraph, SKILL.md carries two live modes, and the fallback's `~/.claude/scripts` route (the symlink of row Q-103 class) stays callable. The skill would have no signal for which mode applies.

**Recommendation:** Add "remove the by-hand fallback paragraph" to U4c's plan entry, or a row naming it. In the Rules' D6 bullet, add one clause, "(until the D6 block is written: the by-hand fallback above)", so a reader who starts at the Rules finds the override.

#### 4. The shipped skill now depends on claude-workflows' working docs and override-row numbers

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:16` (`D1-D14: docs/working/plan-build-loop-handoff.md`), `:63` (`rows 704, 736`), `:85` (`row 702`), `:232-236` (`row 727`; `rows 720, 726`), `:275` (`row 750`), `:149` (`rows 764, 769, 771`)
**Move:** 1 (dependency direction)
**Confidence:** Medium
**Legibility-target:** an orchestrator session running this skill in another project (the skill is installed from `/opt/claude-workflows/skills/dev-cycle`)

Evidence:
> autonomous build loops, collects their results and lands what `scripts/build-loop.sh` (the gate) allows (D1-D14: `docs/working/plan-build-loop-handoff.md`).

On main, SKILL.md cites one review artifact, `row 62`, and only as a record-template example. At ea59b0c3 it cites the plan's D-numbers 23 times, override-log rows 7 times and Q-IDs 5 times. The skill is the stable, installed product. The plan is a working doc under `docs/working/`, and the override log is a review ledger, both specific to claude-workflows. In any other repository these citations dangle. The Rules' paths rule would also have the orchestrator `--check-path` a plan that does not exist there. The dependency runs from stable to volatile. It is harmless as rationale, but it makes the instructions harder to read where they run.

**Recommendation:** Keep the row, D and Q citations in commit messages and the plan's as-built notes, not in the skill. Alternatively, qualify them once ("D-numbers and rows refer to claude-workflows' build-loop plan and override log") and let U5's `docs/dev-cycle.md` become the stable target the skill points to.

#### 5. A prose hg line instead of a script mode: the cost to watch in U4b2

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:63-86` (Hardened git)
**Move:** 2, 4 (layer)
**Confidence:** Medium
**Legibility-target:** U4b2's author (step 9's chore commit)

Evidence:
> `--state` refuses those, but only when it runs, so run it again (through the D6 block, from WT) right before the iteration's commits … A loop that plants one between that check and the commit is a residual for Q-103's list (U5).

> or else from `N="$(git config --global --get user.name)"` and `E=…user.email…` read in the same script (a read, the one plain `git` here; either empty: stop)

Rows 704 and 736 settled the choice between a third pinned copy and a script mode, and this is not a re-flag. The pinned line works: the definition cannot drift, as mutants 1 and 3 above show. What the choice moves into instruction text is sequencing and policy that the gate scripts already own elsewhere. The state check happens, then the commit, with a race between the two. Identity resolution is a second implementation beside build-loop.sh's `merge_ident`, lines 591-593. `--land-cycle` already does check-then-commit-tree inside one gated process for the merge. U4b2 will write step 9's chore commit, and it is the natural point to decide whether that commit also goes through a gated mode. That would remove the named residual and the second identity recipe, and leave `hg` for worktree housekeeping and reads.

**Recommendation:** No change in U4b1. When U4b2 writes step 9, record the choice (prose commit with hg vs a gated commit mode) as a row either way. That keeps the residual's owner visible.

## What Looks Good

- **One source, transitively pinned.** `build-loop.sh` reads `HARDEN` at runtime (git_harden, and caller_gate's key derivation), so adding commit.gpgSign took one edit for every gated path. caller_gate now refuses a caller pair for the new key with no code change. The copies that cannot source the lib (G, hg) are held to the same literal `H` and `E` by one test, which also requires exactly one `hg` definition. The mutants confirm it.
- **The dependency direction is right.** Every edge points from SKILL.md to the scripts. No script reads the skill, and the skill's trust in script output is narrowed to a first line plus a documented exit (the D6 Rule's stop routing, one route since ea59b0c3).
- **The split boundary is clean.** U4b1 is the frame (Rules, steps 0-1, 4/4b) and U4b2 the loop's steps (6-10). The plan's split note and one override row list exactly what U4b1 leaves contradictory. The pending D6 section names its canonical copy and the test that will hold them equal.
- **The interim mode is one paragraph.** The fallback is localized and states its own gap rather than spreading conditionals through each step (finding 3 is about its retirement, not its shape).
- **pr-prep's quiesce line now cites D14** and the stop-by-PID rule instead of restating a looser one, so the two workflows share one rule.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | SKILL.md's health-check bound depends on take_lock's process tree | Coupling | `skills/dev-cycle/SKILL.md:265-275`; `scripts/health-check.sh:1104-1119` | High |
| 2 | The fourth HARDEN copy (build-loop.sh header) is unpinned; the mutant survives | Minor | `scripts/build-loop.sh:135-138` | High |
| 3 | The by-hand fallback overrides the Rules from outside them; U4c's entry does not remove it | Minor | `skills/dev-cycle/SKILL.md:19-28`; plan `:344` | Medium |
| 4 | The shipped skill cites claude-workflows' plan, override rows and Q-IDs | Minor | `skills/dev-cycle/SKILL.md:16` and others | Medium |
| 5 | The prose hg/commit path leaves the --state-to-commit race and a second identity recipe; decide in U4b2 | Informational | `skills/dev-cycle/SKILL.md:63-86` | Medium |

## Overall Assessment

The branch keeps the system's structure intact. The cross-cutting hardening list has one runtime source, and every copy that cannot source it is pinned by an executed test. The orchestrator depends on the scripts and never the reverse, and the U4b1/U4b2/U4c boundaries are explicit in the plan and the override log. The most important structural concern is finding 1. The ea59b0c3 fix makes step 1 correct by encoding `health-check.sh`'s fork structure in the skill, so a change to take_lock can silently break the orchestrator's bound. The fix belongs in take_lock, as a bounded `flock -w`. The other findings can be fixed where they are: pin or de-enumerate the header copy, give the fallback's removal an owner in U4c, and trim claude-workflows-specific citations from the installed skill. None of them calls for restructuring.

## Goal-Alignment Note

The goal is to land U4b1 on main after a clean review-fix loop. No finding here is Structural (🔴), so none blocks the merge on architecture grounds. Finding 1 (Coupling, 🟡 Must Address) needs either a fix or a deferral row with a revisit trigger before landing. The smallest fix is a bounded `flock -w` in take_lock with one bats case. The smallest deferral is a row naming take_lock as coupled to step 1, triggered by U4b2 or any take_lock edit. Findings 2-4 are 🟢 Consider and cheap: a one-line header change, one line in the plan's U4c entry, and one qualifying sentence. Finding 5 is input for U4b2's design, not U4b1's merge. The review stayed within the scope the brief named and did not re-flag the settled override rows: the symlink, the health check after `other`, U4b2's checklist, `hg` naming, quiesce terms, and rows 704/736's choice itself.
