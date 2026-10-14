Commit: c67ffd62

# Security Review: feat/build-loop-u4b1, second confirming pass (Q-142 interim [1])

**Scope:** `git diff 923f7d26..c67ffd62 -- scripts skills test` and c67ffd62's message: `skills/dev-cycle/SKILL.md` (stop paragraph, step 0.2's bootstrap rule, step 0.3's removal), `scripts/health-check.sh` (`HEALTH_CHECK_LOCK_WAIT`'s cap and header). Context read: SKILL.md lines 45-100 and 222-262 (the whole stop paragraph, the Hardened-git Rule, steps 0.1-0.4), `scripts/build-loop.sh` `--main-log`'s contract (`:139-181`) and the state gate (`:597-625`), `scripts/lib/dev-cycle-read.sh` `git_harden` and `HARDEN` (`:329-366`) and check_brief's `git log -G` (`:504-508`), override rows 775-783.
**Date:** 2026-10-13
**Based on:** `docs/reviews/security-review-2026-10-13-u4b1-confirm.md` (its F1 and F2, called E1 and E2 in Q-142), `docs/reviews/code-fact-check-report-2026-10-13-u4b1-confirm.md`.
**Probes:** `secc2-probe1.sh`/`.out` and `secc2-probe2.sh`/`.out` in the session scratchpad `u4b1-c2/` (git 2.39.5, every git call through the skill's `hg` line verbatim). Each made its own `mktemp -d /tmp/u4b1-secc2-XXXX` and removed it by exact name; none left, no process left running.

## Trust Boundary Map

```
B1: loop-writable .git/config, .git/info/attributes (common dir) → hg's -c pairs and env; --state at 0.1 → orchestrator's git: worktree remove --force (changed), log -G (new)
B4: main's history and its cycle records (any commit that moves main) → step 0.2's bootstrap test (changed: tree → history) → whether --main-log gets SINCE or 40 zeros
B2: HEALTH_CHECK_LOCK_WAIT (caller env) → take_lock's digit check (changed: 1-7 digits) → flock -w
```

```
S1: .git/config, common-dir info/attributes — runtime-mutable — UNTRUSTED toward exec sinks (filters, textconv drivers)
S4: main's commit graph and records           — a direct move of main can write any of it — UNTRUSTED as the choice "bootstrap or not"
S3: HEALTH_CHECK_LOCK_WAIT                    — caller-owned env — trusted; validated anyway
```

What crosses: the range replaces step 0.3's plain removal with `--force` (closing E1), replaces the tree-based bootstrap test with a history walk, `git log -G`, which is a new git command in the orchestrator's own shell, and caps the lock wait.

## Findings

#### F1. The bootstrap's history walk follows one parent of a merge, so one merge commit on main that drops `docs/working/cycles/` makes it print nothing and reopens the bootstrap (E2 partly closed)

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:237-240` (step 0.2)
**Boundary:** B4
**Move:** 11 (bypass of the new guard), 1 (runtime-mutable source)
**Confidence:** High that the walk prints nothing (executed); Medium on impact (no effect until U4b2's record template writes `Main at:` lines; same precondition as E2)
**Legibility-target:** for-author

Evidence: "Only when main's history never held a `Main at:` line in a record (`hg -C MAIN_WT log -1 --format=%H -G'^Main at: ' MAIN0 -- docs/working/cycles/` prints nothing, MAIN0 being the default branch's commit read just before), pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap."

What closed: E2's case. Deleting every record, or every record's line, in a single-parent commit is now found, since the deleting commit's diff removes a `Main at:` line (secc2-probe1 case 1). Moving a record out of the directory is found the same way (case 2). `log.follow=true` in the repository config does not change the result (secc2-probe2).

Weakness: a path-limited `git log` without `--full-history` simplifies history. At a merge whose tree matches one parent's for the path, it follows only that parent. Executed (secc2-probe1 case 3): a merge on main whose second parent forked before the first record and whose tree takes that parent's (no `docs/working/cycles/`) makes the command print nothing, although the first parent's history added a `Main at:` line. The same command with `--full-history` printed the adding commit. `-G` also skips merges' own diffs by default, so the merge that dropped the directory is not matched either. The claim "prints nothing exactly when main's history never held such a line" is therefore false for merges. The bootstrap that follows prints no class lines and is exempt from the dispatch block, so the merge is never reported. This is the event the check exists to catch.

Related residual (read-static, not introduced): the brief's "history rewrite is --main-log's refuse" holds only when SINCE is passed. A main moved to a commit whose history holds no record (a rewrite) makes the walk print nothing, so step 0.2 passes zeros and `--main-log` has nothing to refuse. Closing that needs an anchor from outside main, for example the previous iteration's MAIN or its `chore/dev-cycle-*` branch, which "stays" after the removal.

Impact: one ungated commit on main can still switch off the report of itself. Preconditions are as for E2: a direct move of main, once records carry `Main at:` lines.

**Recommendation:** match the lib's own `log -G` (check_brief, `dev-cycle-read.sh:508`: `--first-parent --diff-merges=first-parent -s --no-textconv --no-show-signature --no-follow`). Either form closes the merge case: `--first-parent --diff-merges=first-parent` matches the merge's diff against main's previous commit (read-static), and `--full-history` finds the adding commit behind it (executed). Hand the rewrite residual to U4b2 with an override row, together with the record template.

#### F2. The new `log -G` runs a planted textconv driver; `hg` does not pass `--no-textconv`

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:238` (the command), with `:79-83` (what `hg` leaves to `--state`)
**Boundary:** B1
**Move:** 12 (sweep of the git exec primitive), 4 (prior art in the same codebase)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence: "`hg -C MAIN_WT log -1 --format=%H -G'^Main at: ' MAIN0 -- docs/working/cycles/`" and, from the lib, "--no-textconv (-G greps the diff, and a textconv driver would run)".

Weakness: `git log` turns textconv on by default, and `-G` greps the converted text. Executed (secc2-probe1 case 4): with a `diff.*.textconv` key in `.git/config` and an attributes line in the common dir's `info/attributes` (which `hg`'s `core.attributesFile=/dev/null` does not cover), the skill's command ran the driver. With `--no-textconv` it did not. `--state` at step 0.1 refuses both the `diff.*` key and a non-empty `info/attributes`, so reaching this takes a plant in the seconds between step 0.1 and step 0.2. That is the same residual window the Hardened-git Rule already names for filters. Step 0.2's other commands (`ls-tree`, `show` of a blob) run no driver.

Impact: a command run as the orchestrator, in the window the skill already accepts for commits. It is new in this range, but costs one flag to close.

**Recommendation:** add `--no-textconv` (and, for parity with check_brief, `--no-show-signature --no-follow`) to the command in step 0.2. This is the same edit as F1's.

#### F3. Stop paragraph lists `other` lines as blocking dispatch but not the non-bootstrap `refuse main-log:` line, which step 0.2 also routes to a block

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:61-63` against `:247-251`
**Boundary:** B4
**Move:** 3 (error path consistency)
**Confidence:** Medium (read-static)
**Legibility-target:** for-author

Evidence: "(step 0's `--state` refusals and its lost `Main at:` line; `--main-log`'s `other` lines block dispatch but are no stop)" and "Any `other` line, or a `refuse main-log:` line other than the bootstrap's own (...), blocks this iteration's dispatch and gets one `you: judgment` entry".

Weakness: the two routes agree in substance. Exit 2 with refuse lines is an answer under the paragraph's own exit rule, and step 0.2 is the specific instruction. A reader of the stop paragraph alone could still take a rewrite's refuse line for a stop. Either way, nothing runs that should not.

**Recommendation:** optional. Name the refuse line in the parenthetical, for example "`--main-log`'s `other` and non-bootstrap refuse lines block dispatch but are no stop".

## Prior findings closed by this range

- **E1 (stop-path removal runs a planted clean filter): closed.** Step 0.3 now says `worktree remove --force WT`, and the stop paragraph points to it ("removes WT as step 0.3 does (with `--force` ...)"). Executed (secc2-probe1 case 5): with `filter.pl.clean` and `* filter=pl` planted, `--force` removed a WT holding a modified tracked file and an untracked file, ran no filter, and left its branch. What `--force` refuses: a locked worktree (single `--force` exits 128: "cannot remove a locked working tree"). The skill never locks WT, and a loop that locks it only makes the removal fail closed, leaving WT in place, which costs disk only. A worktree with submodules is also refused by git. This repo tracks no `.gitmodules` (`git ls-files .gitmodules` is empty), and a planted one would make the removal fail, not run anything. The trade-off the skill now states (uncommitted edits discarded) is honest, and a stop keeps no record anyway.
- **E2 (bootstrap read the current tree): partly closed.** See F1. Tree-level deletion and moves are caught, but a merge is not.
- **Confirming F3 / E5 (lock wait's range): closed.** `^[0123456789]{1,7}$` admits at most 9 999 999 s, inside flock's timer range, so the exit-71 values from the first pass are now refused with exit 1 before any flock. The header says "at most 7 digits; 0: no wait", which matches. Row 783 covers the payload-75 remainder.

## Endorsement Claims

- **Claim:** `hg -C MAIN_WT worktree remove --force WT` runs no planted clean filter and removes a modified WT, keeping its branch.
  **Location:** `skills/dev-cycle/SKILL.md:254-257`
  **Evidence:** executed (secc2-probe1 case 5)
  **Verified:** no filter marker; `git branch --list chore` still lists it.
  **Not verified:** git versions other than 2.39.5.
- **Claim:** the bootstrap walk finds single-parent deletions and moves of records.
  **Location:** `skills/dev-cycle/SKILL.md:237-240`
  **Evidence:** executed (secc2-probe1 cases 1-2, secc2-probe2)
  **Not verified:** merges (refuted, F1).

Untested bypass candidates: the `--first-parent --diff-merges=first-parent` form of the F1 fix was only read, not run (`--full-history` was executed).

## Primitive sweep

Primitive: git commands in the orchestrator's shell that can run repository-named drivers or filters (S1)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| stop path and post-land `worktree remove --force WT` (`SKILL.md:64-65`, `:254`) | S1 | `--force`: no status run | cleared (executed) |
| step 0.2 `hg ... log -G ...` (`SKILL.md:238`) | S1 | `hg`, `--state` seconds before | F2 |
| step 0.2 `ls-tree`, `show` of a record blob | S1 | `hg` | cleared: object reads, `show` of a blob applies no textconv by default |
| commits, merge of main into WT | S1 | `--state` re-run before commits | named residual (Q-103), not in range |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Bootstrap's `log -G` follows one parent at a merge; a merge dropping the records reopens the bootstrap (E2 remainder) | Medium | B4 | `skills/dev-cycle/SKILL.md:237-240` | High (exec) / Medium (impact) |
| F2 | The new `log -G` runs a planted textconv driver (no `--no-textconv`) | Low | B1 | `skills/dev-cycle/SKILL.md:238` | High |
| F3 | Stop paragraph omits the non-bootstrap refuse line among dispatch blocks | Informational | B4 | `skills/dev-cycle/SKILL.md:61-63` | Medium |

## Overall Assessment

E1 is closed. It was executed: `--force` runs no filter, and its refusals (a locked worktree, submodules) fail closed. The lock-wait cap is closed. E2 is closed for single-parent commits but not for merges. Path-limited `git log` follows only the TREESAME parent of a merge, so one merge commit on main still reopens the bootstrap (F1). The range also adds a textconv exec sink (F2) that the lib's own `log -G` already avoids. Both are fixed by one edit to the step 0.2 command, copying check_brief's flags. The single most important thing: give step 0.2's `log -G` the lib's flags (`--first-parent --diff-merges=first-parent --no-textconv`, or `--full-history --no-textconv`).

## Goal-Alignment Note

The goal is to land U4b1 on no new Must Fix or Must Address. F1 is a Medium, the remainder of E2, which Q-142 stopped the merge for. The range's own fix is what leaves it open, and it is executed. It has no effect until U4b2 writes `Main at:` lines, so an override row is a proportionate route only if it carries the exact flags into U4b2. The cheaper path is a one-line edit to step 0.2 that also closes F2 (Low, new, a recognised residual window). The history-rewrite residual noted under F1 belongs to U4b2's record design, not to this merge. F3 is optional wording.
