Commit: 923f7d26

# Security Review: feat/build-loop-u4b1, confirming pass on the final fixes

**Scope:** `git diff ea59b0c3..923f7d26 -- scripts skills test` (923f7d26; cebfd1ac is review docs only): `scripts/health-check.sh` (`HEALTH_CHECK_LOCK_WAIT` in `take_lock`), `scripts/build-loop.sh` (header's HARDEN reference), `skills/dev-cycle/SKILL.md` (stop paragraph, identity sentence, step 0.2's bootstrap rule, step 1), `test/scripts/health-check-lock.bats`. Context read: the whole of `take_lock` and its header (`health-check.sh:27-35`, `:1100-1130`), `set -euo pipefail` (`:53`), SKILL.md lines 1-100 and 215-290, `isrecord` (`scripts/lib/dev-cycle-read.sh:246`), `git_harden`'s comment (`:329-345`), override rows 775-782.
**Date:** 2026-10-13
**Based on:** `docs/reviews/security-review-2026-10-13-u4b1-final.md` (F1, F2 checked here), the rubric's "Iteration 3" section. No fact-check report for this range.
**Probes:** `secc-probe1.sh`/`.out`, `secc-probe2.sh`/`.out` in the session scratchpad `u4b1-c1/` (flock `-w` edges, prefix assignment through a function, `git worktree remove` against a planted clean filter, git 2.39.5, util-linux 2.38.1), plus `bats test/scripts/health-check-lock.bats` (3/3 ok). Each made its own `mktemp -d /tmp/u4b1-secc-XXXX`, removed by exact name; none left, no holder process left running.

> No code fact-check report for this range. Claims about security properties in comments and the skill's prose were checked here by reading and the probes above, not by a separate fact-check.

## Trust Boundary Map

```
B1: loop-writable .git/config, .git/info/attributes (common dir) → hg's -c pairs and env; --state (0.1, re-run before commits) → orchestrator's git in WT, incl. the stop's worktree remove (new)
B2: health-check.lock holder (any same-uid run) + HEALTH_CHECK_LOCK_WAIT (caller env) → take_lock's flock -w / -E 75 (new) → whether step 1's check runs or is skipped
B3: script output, exits, Bash-tool timeouts → the stop paragraph (moved: one filing route) → whether the iteration continues, files, removes WT
B4: cycle records on main (docs/working/cycles/cycle-YYYY-MM-DD.md, Main at: lines) → step 0.2's bootstrap condition (moved) → --main-log's reporting and the dispatch block
B5: harness environment / ~/.gitconfig read → identity prefix on hg commands (moved: merge of main included) → commit and merge identity
```

```
S1: .git/config, common-dir info/attributes — runtime-mutable (any same-uid loop) — UNTRUSTED for exec sinks (filters, drivers)
S2: health-check.lock                        — runtime-mutable — UNTRUSTED for availability (anyone can hold it); no exec sink
S3: HEALTH_CHECK_LOCK_WAIT                   — caller env, set by the skill's own text to 3600 — trusted (caller-owned); validated as digits anyway
S4: records on main                          — written by the chore land; a direct move of main can write them — UNTRUSTED as a choice of SINCE
S5: GIT_AUTHOR_*/GIT_COMMITTER_* values       — harness env or ~/.gitconfig — attribution only
```

What crosses: the range removes the process-group stop (setsid, `kill -- -PGID`) in favour of a bounded wait inside `take_lock`, so no PID or PGID read from the process table reaches a signal any more. It narrows the bootstrap condition from "newest record lacks the line" to "no record holds it". It adds one new git operation on the stop path (remove WT), which runs in a worktree whose repository config may be exactly what `--state` just refused.

## Findings

#### F1. "A stop after step 0.3 removes WT" runs `git worktree remove`, whose cleanliness check runs a planted clean filter, including on the stop `--state` raised for that filter

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:64` (stop paragraph) with `:249` (the remove command it implies) and `:77-79` (the `--state` re-run whose refusal is a stop)
**Boundary:** B1, B3
**Move:** 3 (error path), 12 (sweep of the git exec primitive)
**Confidence:** High that the filter runs (executed); Medium on reach (needs a filter key planted after step 0.1, the window the skill already names)
**Legibility-target:** for-author

Evidence: "A stop after step 0.3 removes WT." and "WT is removed (`hg -C MAIN_WT worktree remove WT`) once the iteration's land is verified" and "`--state` refuses those, but only when it runs, so run it again (through the D6 block, from WT) right before the iteration's commits, and treat a refusal there as step 0 does."

Weakness: the stop paragraph names no command, so the orchestrator uses the one step 0.3 gives, `hg -C MAIN_WT worktree remove WT` without `--force`. Without `--force`, git checks the worktree is clean by running a status in it, and that status re-hashes any stat-dirty or racily-clean tracked file through the clean filter that `.git/config` and an attributes file name. `hg` cannot switch filters off, and it points `core.attributesFile` at /dev/null but not the common directory's `info/attributes`, which a linked worktree reads. Executed (secc-probe1, cases A and C): with `filter.pl.clean` in `.git/config` and `* filter=pl` in `.git/info/attributes`, the plain remove ran the filter both on an untouched fresh worktree (racy index) and after a touch. On a worktree with edits it ran nothing and refused ("contains modified or untracked files, use --force"), so a mid-iteration stop also leaves WT in place, and the instruction does not say what to do then. With `--force` (secc-probe2) the filter did not run and the worktree went.

Impact: the stop most likely to carry a planted filter is the one the `--state` re-run raises for it: the skill turns a detected exec primitive into a stop, and the new sentence then runs it. It runs as the orchestrator, which is what `--state`'s filter refusal exists to prevent. Preconditions: a same-uid loop writes a `filter.*` key and an attributes entry after step 0.1's check (the window the Hardened-git Rule already names as a residual). This range adds the path; it did not exist before.

**Recommendation:** say which removal a stop uses. `hg -C MAIN_WT worktree remove --force WT` ran no filter in the probe and also removes a dirty WT. That fits a stop, which keeps no record, but it discards the iteration's uncommitted edits, so say so. Or, when `--state` refused, leave WT and name its path in the judgment entry. The normal post-land removal at `:249` is a sibling: it runs with no fresh `--state` before it, so `--force` there costs nothing once the land is verified.

#### F2. Step 0.2's bootstrap still opens when every record's `Main at:` line, or the records directory, is gone (final F1, partly closed)

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:232-238`
**Boundary:** B4
**Move:** 11 (bypasses of the new guard), 1 (runtime-mutable source)
**Confidence:** Medium (read-static; no effect until U4b2's template writes `Main at:` lines; not introduced by this range, the remainder of the finding it fixes)
**Legibility-target:** for-author

Evidence: "Only when no record there holds a `Main at:` line, pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap. A newest record without one while an older record has one is a stop, with one `you: judgment` entry".

What closed: the final pass's two cases are stops now. A newer-named record with no line, or the line deleted from the newest record, both leave an older record holding one. "Newest record" is well defined: `isrecord` admits only `docs/working/cycles/cycle-YYYY-MM-DD.md` (`dev-cycle-read.sh:246`), one per date, so the newest is the latest name. A newer name carrying a `Main at:` for an older commit re-lists commits, and one off main's history refuses, so both fail closed (the final pass's analysis, unchanged).

Bypass candidates for the new guard: (1) a newer record with no line, now a stop (traced); (2) the line deleted from the newest record only, now a stop (traced); (3) the line deleted from every record, or every record deleted, in one commit that moves main directly: "no record there holds a `Main at:` line" is true again, so SINCE is the bootstrap. That bootstrap prints no class lines and is exempt from the block, so the commit that did it is never listed (traced). The guard reads the current tree, but the final pass's recommendation was "no record on main has ever held" the line, which is a property of history.

Impact: the same as the final F1, with one more edit needed. One ungated commit on main can still switch off the check that would report it. The precondition is the event the check exists to catch, a direct move of main.

**Recommendation:** tie the bootstrap to history, not the tree. Bootstrap only when no commit on main has ever touched `docs/working/cycles/` (an `hg -C MAIN_WT log -1 MAIN -- docs/working/cycles/` that prints nothing), else a missing line anywhere is the stop. The final pass's structural alternative also works: the newest `chore` merge's record. One sentence, or an override row handing it to U4b2's record template with the rule stated.

#### F3. Exit 75 from the payload reads as "nothing was checked"; out-of-range waits exit 71

**Severity:** Informational
**Location:** `scripts/health-check.sh:1104-1129`, `:53`; `skills/dev-cycle/SKILL.md:281-283`
**Boundary:** B2
**Move:** 3 (error path)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: "-E 75 marks \"held elsewhere\" (its own exits are 0 or 1)", "# -E 75 also names a -w timeout: the run never started, so 75 is safe to report as such." and `set -euo pipefail`.

Weakness: under `set -e`, the payload exits with any unguarded command's status, so "0 or 1" is a convention, not a property. A payload exit of 75 would print "gave up waiting … nothing was checked", and the skill would skip the check rather than triage a failure. Reaching it needs committed health-check code on the checked commit that ends in 75. That is gated code, so this is not an attacker-reachable fail-open. Separately (secc-probe1/2), values past flock's timer range (`9223372036854775807`, `2^64`) pass the digit check and exit 71 ("cannot set up timer") with nothing run. `99999999999` waits, and `0`/`00` give up at once with 75. Leading zeros are decimal (`010` waited the full hold). The skill's `3600` is in range.

**Recommendation:** optional. Check the run's own end marker (the "Repo Health Check" banner) before treating 75 as "nothing ran", or cap the value's length. No merge impact.

## Prior findings (final pass) closed by this range

- **Final F2 (setsid fork, unguarded PGID): closed.** Step 1 no longer uses `setsid` or `kill -- -PGID` (grep: no `setsid` or `PGID` left in SKILL.md or pr-prep.md). The bound is now `flock -w` inside `take_lock`. Past it, the second flock returns 75 without starting the payload. Executed: bats test 3 asserts status 75, the message and no payload log, and the probe shows `-w` timeouts exit 75 in ~0 s for 0 and wait for in-range values. No process-table read reaches a signal, so the PID-reuse case is gone. Unset keeps the unbounded wait (`w=()` expands to nothing). A non-digit value exits 1 before any flock (test 3).
- **Final F1 (bootstrap fail-open): partly closed.** See F2 above.
- **Final F3 (merge identity): closed.** "The same goes for every command that writes a commit, the merge of main into WT included, written as `GIT_AUTHOR_NAME="$N" … hg …`". Executed (secc-probe2): a prefix assignment before a bash function call is in the environment of the commands it runs and does not persist after it (non-POSIX bash, which `bash -s` is). `env … hg` would resolve `hg` to `/usr/bin/hg` (Mercurial, present here), which fails closed.

## Endorsement Claims

- **Claim:** with `HEALTH_CHECK_LOCK_WAIT` set to digits and the lock held past it, `take_lock` exits 75 without running the payload.
  **Location:** `scripts/health-check.sh:1117-1128`
  **Evidence:** executed
  **Verified:** bats `health-check-lock.bats` test 3 (no payload log line, status 75), and flock `-w 0`/`-w 1` returning 75 under a holder in secc-probe1.
  **Not verified:** the full suite's payload exits (F3's set -e case).
- **Claim:** the stop paragraph makes a timed-out call and `refuse d6:` stops for both scripts, filed once.
  **Location:** `skills/dev-cycle/SKILL.md:56-66`
  **Evidence:** read-static
  **Verified:** the paragraph's text against the Exit contract summarised in the final pass.
  **Not verified:** the by-hand fallback, which "replaces this Rule" until Q-140 and states no timeout rule of its own.
- **Claim:** build-loop.sh's header now names the HARDEN list by reference, and the list it points at includes `commit.gpgSign`.
  **Location:** `scripts/build-loop.sh:133-138`, `scripts/lib/dev-cycle-read.sh:329-345`
  **Evidence:** read-static
  **Verified:** the header text and git_harden's comment.
  **Not verified:** caller_gate's key set against HARDEN (pinned by the orchestrator suite, not run here).

Untested bypass candidates: none for `HEALTH_CHECK_LOCK_WAIT`'s validation (digits only, executed: `1s` refused, `0`, `00`, `010`, large values probed). For F2's guard, all three candidates were traced.

## Primitive sweep

Primitive: git commands in WT that can run repository-named filters (exec via `.git/config`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| stop path: remove WT (`SKILL.md:64`, command from `:249`) | S1 | `hg` only; may follow a `--state` refusal | F1 |
| post-land `hg -C MAIN_WT worktree remove WT` (`SKILL.md:249`) | S1 | `hg`; land verified, no fresh `--state` | F1 sibling (same fix) |
| commits and the merge of main into WT (`SKILL.md:63-89`) | S1 | `hg`; `--state` re-run before commits | named residual (Q-103), not in range |
| `hg -C MAIN_WT ls-tree` / `show` (step 0.2) | S1 | `hg`, `--state` | cleared: object reads, no worktree content conversion |
| health check run from WT (`SKILL.md:276-283`) | S1 | `--state` at 0.1, health-check's own code | not in range (row 776's class) |

Primitive: signal delivery to a process group: none left in scope (the final F2 site was removed).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | The stop's WT removal runs a planted clean filter, including after `--state` refused it (introduced) | Medium | B1, B3 | `skills/dev-cycle/SKILL.md:64`, `:249` | High (exec) / Medium (reach) |
| F2 | Bootstrap still opens when every record's `Main at:` is removed (final F1 remainder, not introduced) | Medium | B4 | `skills/dev-cycle/SKILL.md:232-238` | Medium |
| F3 | Payload exit 75 reads as "nothing checked"; out-of-range waits exit 71 | Informational | B2 | `scripts/health-check.sh:1104-1129` | Medium |

## Overall Assessment

The range does what it set out to do for the final F2 and F3. The process-group stop is gone, replaced by a bounded `flock -w` that exits 75 having run nothing (executed). Identity now covers the merge, and the prefix form works through `hg` (executed). Step 0.2's guard closes the two bootstrap cases the final pass named but not a third: stripping every record's line. That third case is the remainder of an existing finding, not something this range adds. The range does introduce one new Medium (F1). "A stop after step 0.3 removes WT" adds a git command whose cleanliness check runs repository-named clean filters, on the very stop `--state` raises for a planted filter. It is fixable in one clause (`--force`, or leave WT on a `--state` refusal). Nothing is architectural. The single most important thing: name the removal command on the stop path.

## Goal-Alignment Note

The goal is landing U4b1 after a clean review-fix loop, merging on no new security High/Medium introduced by the range. F1 is that kind of finding: it is introduced here, executed, and Medium. It is also a one-clause wording fix in SKILL.md, with no code or test change, so a short fix round should not reopen the loop. F2 is a remainder of the final pass's F1, not introduced here, and has no effect until U4b2 writes `Main at:` lines. An override row carrying the history-based bootstrap rule into U4b2's record template is a proportionate route if the author prefers not to edit step 0.2 again. F3 is optional and should not hold anything.
