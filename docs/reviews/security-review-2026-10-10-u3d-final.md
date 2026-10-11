Commit: 4b863735

# Security Review — feat/build-loop-u3d (U3d dispatch), final confirming pass

**Scope:** `git diff main...HEAD -- scripts test` in /workspace/.claude/wt-build-loop-u3d (scripts/build-loop.sh +188/-10, test/scripts/build-loop-dispatch.bats +111), plus the unchanged helpers it calls (state_gate, harden, gate_start, status_fields, marker_kind, readerform)
**Date:** 2026-10-10
**Based on:** Stage 1 fact-check k=3 at 4b863735 (docs/reviews/code-fact-check-report-u3d-final-r{1,2,3}.md, summarised in the shared brief u3d-fin/shared.md); my iteration-2 report docs/reviews/security-review-2026-10-10-u3d-i2.md
**Suite:** `bats test/scripts/build-loop-dispatch.bats` 4/4 ok at 4b863735 (once, serially, private TMPDIR). Probes p1-p8 are in the session scratchpad (`u3d-fin/secrev/`). Each ran in its own `/tmp/claude-1000/u3d-rev-secrevfin-*` repo under git 2.39.5.

## Trust Boundary Map

```
B1: [caller argv: BRIEF, --dir, --steal]          → [arg parser, readerform, check_brief]                  → [dispatch]
B2: [main's committed brief + constraints.md]    → [store_check, status_fields, check_branch, read_settings] → [update-ref / worktree add args, prompt text]
B3: [repo-local git state: worktree registry paths and lock reasons, common dir files] → [state_gate + harden; wt_of; readerform on WT (i2 fix)] → [worktree add/lock/unlock, printed lines, prompt]
B4: [branch tip: loop-authored commits, tree, marker subject] → [hardened checkout in worktree add; marker_kind; steal's committer time] → [new worktree's files; steal / marker-relock decision]
B5: [script stdout]                               → [orchestrator parses "ok BRIEF BRANCH DIR", passes the prompt] → [loop's shell ("cd $DIR &&")]
B6 (new): [git common dir: build-loop-dispatch.lock] → [exec 9>> + flock -n] → [one dispatch at a time]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | BRIEF argument | request-time (orchestrator) | Trusted after pathform and isbrief for ref, arg and prompt sinks |
| S2 | `--dir` argument | request-time | Trusted after readerform for git-arg and prompt sinks |
| S3 | Brief fields on main (Branch:, Status:, Dispatched:, Policy:) | runtime-mutable (main commits) | Branch: trusted for ref and arg sinks after check_branch. The rest are reduced to fixed words or integers. |
| S4 | docs/constraints.md at MAIN_SHA | runtime-mutable, cycle-owned | Trusted as prompt content, quoted per line |
| S5 | `git worktree list --porcelain -z`: paths (WT, MAINWT), lock reasons, branch lines (incl. unborn HEAD) | runtime-mutable by any same-uid git user | UNTRUSTED for printed-line and shell-text sinks. WT passes readerform only after two arms that print it. |
| S6 | Branch tip commit: subject (marker kind), committer time, tree | loop-authored | UNTRUSTED for the exec sink (checkout, hardened). For the lock-replacement decision it is trusted as "the loop has ended", which Finding 1 contests. |
| S7 | Repo config incl. `submodule.*`, and submodule git dirs' configs | runtime-mutable | UNTRUSTED for exec sinks. state_gate reads only the common config and config.worktree. |
| S8 | `build-loop-dispatch.lock` in the common dir | runtime-mutable (any .git writer) | Untrusted for open() semantics (file type) |
| S9 | Clock | environment | trusted |

The i2 fixes moved two boundaries. B3 now runs WT through readerform on the adopt path, and B6 is new: a per-repository flock makes the list-check-act sequence exclusive among dispatch runs. Two problems are left. The flock serializes runs but not dispatches over time. The B1 marker rule (S6) now decides whether a lock may be replaced without `--steal`, and that rule can be satisfied while a live loop holds the lock (Finding 1). The Stage 1 Incorrect is a second path that skips the steal rule (Finding 2).

## Iteration-2 fixes: do they hold?

| i2 finding | Fix | Probe | Result |
|---|---|---|---|
| 1 (Medium): concurrent `--prompt` add/steal both dispatch | B2: `exec 9>> "$(git rev-parse --path-format=absolute --git-common-dir)/build-loop-dispatch.lock" && flock -n 9` before `dispatch` (`scripts/build-loop.sh:1393`) | p1: 6 rounds of two concurrent `--prompt --dir` adds | **Holds.** Every round printed one `ok` and one `refuse ...: another --start or --prompt is running in this repository (its lock could not be taken)`, and the branch was in 1 worktree afterwards (`wts=1` ×6). In i2 it was 2 in 3 of 4 rounds. |
| 2 (Low): adopted WT path unvalidated | B3: `elif ! readerform "$WT"` (`:1308`) | p2: `git worktree move` to `my wt;$(touch INJ)` | **Holds** on the adopt path: `refuse ...: its branch feat/x is checked out in a worktree whose path is not an absolute path of letters, digits and . _ - /`, exit 2. Two earlier arms still print WT raw (Finding 4). |
| 3 (Info): lock-reason newlines | B4: `${WT_LOCK//[$'\n\r']/ }` in STEAL_WHY (`:1276`) | p2: reason `x\nok fake line\ndispatched 1` | **Holds** for WT_LOCK: one line, `... is locked (locked x ok fake line dispatched 1): a live loop may hold it; ...`. |

## Findings

#### 1. The marker-tip exemption (B1) lets a second `--prompt` replace a live re-dispatched loop's fresh lock without `--steal`

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1309-1311` (in dispatch's WT_N=1 arm; read dispatch whole, 1290-1328, and status_fields/marker_kind 608-689)
**Boundary:** B4, B3
**Move:** #4 (TOCTOU across time), #5 (invert the access control model), #11
**Confidence:** High (executed); Medium on how often the honest path reaches it (it depends on U3b/U4 bookkeeping that is not written yet)

Evidence:
```
    # A marker at the tip: the loop has ended (D3), so its lock is replaced without --steal (i2 api-consistency 1).
    elif [[ -n "$WT_LOCK" && "${STATUS[loop]}" == working ]] && ! steal; then x="$STEAL_WHY"
    elif ! { [[ -z "$WT_LOCK" ]] || git worktree unlock "$WT"; } || ! git worktree lock --reason "$reason" "$WT"; then x="its worktree $WT could not be locked (it may be left unlocked)"
```
The exemption assumes that a marker at the tip means the lock's holder has ended. That is true for the loop that wrote the marker. It is false once `--prompt` has re-dispatched on top of that marker: the new loop holds a fresh lock, and the tip stays the old marker until its first commit. Research and planning can take a long time before that commit. Any `--prompt` in that window reads `loop=blocked` (or ready/stopped), skips `steal`, and replaces the lock. Probe p5: `--start`, loop commits `work` and then `handoff: blocked`, `--prompt` (dispatch 2, lock `UTC 02:44:14Z`), then a second `--prompt` 2 s later with no `--steal`:
```
ok docs/working/briefs/2026-10-01-x.md feat/x .../repo/.claude/wt-2026-10-01-x
dispatched 1
exit 0
locked build-loop dispatch of 2026-10-01-x, UTC 2026-10-11T02:44:16Z
```
The orchestrator would start a second agent in the worktree a live loop occupies. That is F44, which the plan marks "covered" by "`--prompt` refuses a locked worktree without `--steal` (T40)". The new flock does not help, because the two runs are sequential. `dispatched 1` both times shows that the Dispatched: cap does not help either until the caller commits N to main. The honest path reaches this in two ways. The first is two orchestrator sessions in one repo (F37; this repository runs several sessions on /workspace). The second is one orchestrator whose re-dispatch rule ("once every Asked ID is answered ... re-dispatched with `--prompt`", plan line 63) fires again on a later iteration, because the tip still reads blocked with its questions answered. The exemption also replaces a hand lock (`lock --reason "by hand"`) whenever the tip is a marker. The pre-B1 code required `--steal` and 2 hours for both cases. B1 traded that safety for the api-consistency fix without a test of the window.

**Recommendation:** Exempt a marker tip only when the lock was taken before the marker existed. Write the dispatched tip into the lock reason (`build-loop dispatch of STEM at TIP, UTC TIME`) and skip `steal` only when the reason parses and its TIP is not the current tip, that is, the marker was committed after this dispatch. Otherwise, including for an unparseable or hand-written reason, apply `steal`'s rules. A weaker alternative compares the reason's time with the marker's committer time. Add the p5 sequence to test 4 as a refusal.

#### 2. `--start` relocks a worktree holding the absent branch unborn, with no `--steal` and no age check (Stage 1 Incorrect, judged)

**Severity:** Low
**Location:** `scripts/build-loop.sh:1299, 1302-1312` (the start mode passes `loop=absent`, then enters the WT_N=1 arm; `:1310` calls `steal` only when `loop == working`)
**Boundary:** B3
**Move:** #5, #3
**Confidence:** High (executed) on the mechanism; Low on honest-path reach

wt_of counts a worktree whose `branch refs/heads/feat/x` line has no ref behind it (`HEAD 0000…`). Because `STATUS[loop]` is `absent`, not `working`, `--start` skips `steal` and replaces whatever lock is there. Probe p4: `--start`, then `git update-ref -d refs/heads/feat/x` (lock seconds old), then `--start` again:
```
ok docs/working/briefs/2026-10-01-x.md feat/x .../repo/.claude/wt-2026-10-01-x
dispatched 1
exit 0
locked build-loop dispatch of 2026-10-01-x, UTC 2026-10-11T02:43:44Z
no ref created
```
Does the honest path reach it? Probe p3 tried every porcelain way to lose the ref while it is checked out, and each one refused: `git branch -D` ("Cannot delete branch 'feat/x' checked out at ..."), `git push . :refs/heads/feat/x` ("refusing to update checked out branch"), and `checkout --orphan feat/x` while the ref exists ("a branch named 'feat/x' already exists"). Only plumbing (`update-ref -d`, ref-file removal) or an orphan checkout made before the brief's first dispatch produces the state. Each of those is a deliberate same-uid act, most plausibly by the live loop itself, which makes it a Q-103 residual by the brief's rule. I rate it Low rather than Medium for that reason: reaching it takes host-level control (the floor-rule exception). The consequence is still F44 (two agents, lock taken in seconds), and the prompt states a tip (`MAIN_SHA`) the worktree does not have. The author's planned fix, `--start` refuses when `WT_N > 0`, closes it. With that fix `--start` never relocks, and `--prompt` already refuses an absent branch (p4: `refuse ...: its branch feat/x does not exist; --start creates it`).

**Recommendation:** Land the planned fix (`[[ "$MODE" == start && "$WT_N" -gt 0 ]]` refuses, naming the worktree) and add p4's sequence as a test.

#### 3. A FIFO at the dispatch-lock path hangs `--start`/`--prompt` instead of refusing; a dangling symlink there creates a file at its target

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1393`
**Boundary:** B6
**Move:** #3 (error path), #11
**Confidence:** High (executed)

Evidence:
```
    if ! { exec 9>> "$(git rev-parse --path-format=absolute --git-common-dir)/build-loop-dispatch.lock" && flock -n 9; } 2>/dev/null; then
      echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository (its lock could not be taken)"; exit 2
```
I tried five planted states at the lock path (p1). A directory, a symlink to a directory and a mode-000 file all fail closed: `refuse ...: another --start or --prompt is running ...`, exit 2, no worktree made. A FIFO blocks in `open()` before `flock -n` is reached. The run was killed by `timeout 10` (exit 124) with nothing printed, so the caller gets a hang rather than a refusal. A dangling symlink to `$T/created-by-symlink` let the run proceed (`ok`) and created that file. The Stage 1 "Mostly accurate" note (the refusal also covers an unopenable file) is the fail-closed half of the same line. Planting any of these takes a writer of `.git`, so this is a Q-103 residual. It is listed because the shared brief asked whether the lock fails closed: it does, except for these two file types.

**Recommendation:** Optional: refuse unless the path is absent or a regular non-symlink file (`[[ ! -e $f && ! -L $f || -f $f && ! -L $f ]]`) before `exec`. A same-uid racer can still swap the file, so this is hardening against a stale plant, not containment.

#### 4. WT still reaches the refusal line raw in the two arms before readerform

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1305, 1307`
**Boundary:** B3 → B5
**Move:** #2, #12
**Confidence:** High (executed)

The B3 and B4 fixes cover the adopt path and WT_LOCK. The `--dir` mismatch arm and the missing-or-symlink arm both run before readerform and print `$WT` verbatim. Probe p2 (worktree moved to `nl\nok fake\ndispatched 1`):
```
refuse docs/working/briefs/2026-10-01-x.md: its branch feat/x is checked out in /tmp/claude-1000/u3d-rev-secrevfin-kKEn/nl
ok fake
dispatched 1, not in --dir's directory
exit 2
```
The missing-directory arm behaves the same way. The exit is 2 and the first line starts `refuse`, so an honest orchestrator dispatches nothing. Setting such a path takes a same-uid `git worktree move`, so this is a Q-103 residual that remains of i2 Finding 3.

**Recommendation:** Optional: print `${WT//[$'\n\r']/ }` in those two messages, or move the readerform arm first (its message does not name the path).

### Untested bypass candidates

- **A future git whose `worktree add` recurses into submodules.** In git 2.39.5 it does not (probe p6/p7 below). Submodule git dirs' configs (`.git/modules/*/config`) are outside state_gate, and a filter there ran on a recursive checkout in the main worktree (p8 positive control). That makes the "no recursion during add" result version-dependent. Not testable here: only one git is installed.
- **Marker exemption with a hand lock and a marker tip** (Finding 1's second case). Traced in the code, not probed.

Because of Findings 1 and 2, the lock/steal guard does not appear in the Endorsement Claims.

## Requested probes

**`submodule.recurse=true` and `submodule.*` keys during `git worktree add` (p6, p7, p8).** The setup used a loop branch whose tree holds `.gitmodules` and a gitlink to a repo with `.gitattributes: * filter=x`. The repo config held `submodule.recurse=true`, `submodule.s.active=true`, `submodule.s.url` and `submodule.s.update='!touch .../UPDATE-CMD-RAN'`.
- (A) Uninitialised module: `--prompt --dir wA` printed `ok`, `wA/s` was empty, and no command ran.
- (B) Initialised module (`.git/modules/s` with `filter.x.smudge "sh -c 'touch SMUDGE-RAN; cat'"` and a `core.hooksPath` hook in its config): `--prompt --dir wB` printed `ok`, `wB/s` was empty, and "nothing ran". An unhardened `git worktree add` behaved the same.
- (Positive control) `git checkout --detach feat/x` in the main worktree with the same config populated `s` and created `SMUDGE-RAN`.

git 2.39.5's worktree add does not recurse (the binary carries `--no-recurse-submodules` for its internal reset), and `submodule.<name>.update` runs only under `git submodule update`. The candidate is cleared for this git version. The residual is under Untested bypass candidates.

**The Stage 1 Incorrect on the honest path.** See Finding 2. The porcelain does not reach it (three refusals in p3). Plumbing or a pre-dispatch orphan checkout does. It is a Q-103 residual with a real F44 consequence, and the planned fix is right.

**The flock file in the common dir.** See Finding 3. A planted directory, a symlink to a directory and an unwritable file fail closed. A FIFO hangs, and a dangling symlink writes through. Both need a `.git` writer.

## Endorsement Claims

- **Claim:** Two concurrent `--prompt` runs that would each add a worktree for the same branch produce exactly one `ok` and one refusal, and leave the branch in one worktree.
  **Location:** `scripts/build-loop.sh:1390-1398`
  **Evidence:** executed
  **Verified:** p1, 6 rounds with different `--dir` values: one `ok` and one `refuse ...: another --start or --prompt is running ...` each round, `wts=1` each round. Suite test 3's held-lock refusal passed.
  **Not verified:** the steal-race variant (two `--steal` runs on an old lock). It sits under the same lock but I did not re-run it. Also not verified: two runs from different linked worktrees of one repo, where `--git-common-dir` should resolve to the same file.
  **route: code-fact-check**
- **Claim:** `--prompt` refuses an existing worktree whose path fails readerform before it locks it or prints its path.
  **Location:** `scripts/build-loop.sh:1308`
  **Evidence:** executed
  **Verified:** p2, a path holding a space, `;` and `$(...)`, and a path holding newlines with the directory present: both refused with the fixed message, exit 2.
  **Not verified:** the two earlier arms (`:1305`, `:1307`), which print WT before this check (Finding 4).
  **route: code-fact-check**
- **Claim:** With `submodule.recurse=true`, an active submodule, a `submodule.s.update=!cmd` key and an initialised module git dir carrying a smudge filter, `--prompt`'s `worktree add` of a loop-authored tree ran no command, under git 2.39.5.
  **Location:** `scripts/build-loop.sh:1319`
  **Evidence:** executed
  **Verified:** p6 and p7 (no marker file, empty `s/`), against a positive control (p8) in which the same filter ran on a recursive checkout.
  **Not verified:** other git versions, and `--start`'s add (main's tree; same code line).
  **route: code-fact-check**
- **Claim:** A newline in a lock reason is printed as a blank inside the single refuse line.
  **Location:** `scripts/build-loop.sh:1276`
  **Evidence:** executed
  **Verified:** p2, with and without `--steal`.
  **Not verified:** a CR-only reason (in the same character class; not run).

## Primitive sweep

Primitive: process exec with externally derived arguments, files opened at derived paths, and shell text sent to the loop

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:1258` `git worktree list --porcelain -z` | — | none needed | cleared — no input |
| `build-loop.sh:1279-1281` `date -u -d`, `git cat-file commit` + awk | S5 lock reason, S6 tip | regex digits; object id | cleared |
| `build-loop.sh:1301` `git cat-file blob "$MAIN_SHA:docs/constraints.md"` | S4 | store_check, read_settings | cleared |
| `build-loop.sh:1305, 1307` refuse text with `$WT` | S5 | none | Finding 4 |
| `build-loop.sh:1308` readerform on WT | S5 | readerform | cleared (i2 F2 fix holds) |
| `build-loop.sh:1310` marker exemption → `:1311` `git worktree unlock/lock "$WT"` | S6 marker, S5 | marker_kind only | Finding 1 |
| `build-loop.sh:1299 + 1311` start relock of an unborn checkout | S5 | none (`loop=absent` skips steal) | Finding 2 |
| `build-loop.sh:1318` `git update-ref "refs/heads/$br" "$MAIN_SHA" ""` | S3 | check_branch, create-only | cleared |
| `build-loop.sh:1319` `git worktree add -q --lock --reason "$reason" "$DIR" "$br"` | S2/default DIR, S3, S6 tree, S7 | readerform, check_branch, harden, state_gate; serialized by B6 | cleared (submodule.recurse probed: no recursion in 2.39.5) |
| `build-loop.sh:1320` `head -n 1 "$GATE_TMP/add"` into refuse text | git stderr (may quote DIR, validated) | DIR readerform | cleared |
| `build-loop.sh:1321` `git update-ref -d "refs/heads/$br" "$MAIN_SHA"` | S3 | old-value guard | cleared |
| `build-loop.sh:1326` printed `ok … DIR` | S2/S5 | readerform on all three DIR sources | cleared |
| loop_prompt `"cd $DIR &&"` | S2/S5 | readerform | cleared |
| loop_prompt `printf '%s\n' "$3" \| sed 's/\r$//; s/^/> /'` | S4 | per-line quote | cleared |
| `build-loop.sh:1393` `exec 9>> "$(git rev-parse … --git-common-dir)/build-loop-dispatch.lock"` | S8 | `flock -n`, stderr hidden | Finding 3 (FIFO hang, symlink write-through); directory, symlink-to-directory and mode 000 fail closed |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Marker-tip exemption replaces a live re-dispatched loop's fresh lock without `--steal` (F44) | Medium | B4, B3 | `scripts/build-loop.sh:1309-1311` | High (executed) / Medium (honest reach) |
| 2 | `--start` relocks an unborn checkout of the absent branch, skipping steal (Stage 1 Incorrect) | Low | B3 | `scripts/build-loop.sh:1299, 1302-1312` | High (mechanism) / Low (honest reach) |
| 3 | FIFO at the dispatch-lock path hangs; dangling symlink writes through | Informational | B6 | `scripts/build-loop.sh:1393` | High |
| 4 | WT printed raw in the two arms before readerform | Informational | B3→B5 | `scripts/build-loop.sh:1305, 1307` | High |

## Overall Assessment

The iteration-2 fixes hold. The flock turned the concurrent add race from 3-of-4 double dispatches into 0 of 6. readerform now guards all three DIR sources on the adopt path. Lock-reason newlines are flattened. `submodule.recurse` and the other `submodule.*` keys do not make git 2.39.5's `worktree add` recurse or run a command, even with an initialised module whose config holds a filter. The lock file fails closed for a planted directory, a symlink to a directory and an unwritable file. One new problem comes from the iteration-2 work itself. B1's marker-tip exemption assumes the lock belongs to the loop that wrote the marker. After a re-dispatch it belongs to a live loop that has not committed yet, so a second `--prompt` replaces it without `--steal` (Finding 1, executed). That puts F44's "covered" back in question on a path two orchestrators, or one orchestrator repeating its re-dispatch step, can reach. The fix is small and in place: tie the exemption to the lock having been taken before the marker, for example by recording the dispatched tip in the lock reason. Finding 2 is the Stage 1 Incorrect, judged a Q-103 residual on reach but worth the author's planned one-line fix, since its consequence is the same F44. Findings 3 and 4 are optional same-uid hardening. The single most important item is Finding 1. No other findings within the code paths read. The endorsement claims are executed and scoped, and those marked `route: code-fact-check` are pending verification there.

**Goal-Alignment Note:** The goal is to land U3d after a clean review-fix loop. Finding 1 bears directly on U3d's success criterion: the F44 "covered" row rests on the lock refusing a second dispatch, and the B1 fix opened a window where it does not. It needs a fix (or an override row moving `--prompt`'s F44 coverage to "partly") before merge. Finding 2's planned fix should land with it. Findings 3 and 4 do not block.
